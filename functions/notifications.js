const {onDocumentUpdated} = require("firebase-functions/v2/firestore");
const admin = require("firebase-admin");

// 1. Notify users when an Event is published
exports.notifyNewEvent = onDocumentUpdated("events/{eventId}", async (event) => {
  const before = event.data.before.data();
  const after = event.data.after.data();

  // Check if status changed to 'published'
  if (before.status !== "published" && after.status === "published") {
    const title = after.title || "Novo Evento!";
    const prize = after.prizePool ? `Valendo R$ ${after.prizePool}!` : "Participe agora!";

    const message = {
      notification: {
        title: "🔥 A Caçada Começou!",
        body: `O evento "${title}" acabou de ser liberado. ${prize}`,
      },
      topic: "all_players",
      data: {
        click_action: "FLUTTER_NOTIFICATION_CLICK",
        eventId: event.params.eventId,
        type: "new_event",
      },
    };

    try {
      await admin.messaging().send(message);
      console.log(`Push notification sent for event: ${event.params.eventId}`);
    } catch (error) {
      console.error("Error sending push notification:", error);
    }
  }
});

// 2. Notify a specific user when their Pix withdrawal is approved
exports.notifyWithdrawalApproved = onDocumentUpdated("withdrawals/{withdrawalId}", async (event) => {
  const before = event.data.before.data();
  const after = event.data.after.data();

  if (before.status === "pending" && after.status === "completed") {
    const uid = after.uid;
    const amount = after.amount;

    // Get user's FCM tokens
    const userDoc = await admin.firestore().collection("players").doc(uid).get();
    if (!userDoc.exists) return;

    const tokens = userDoc.data().fcmTokens;
    if (!tokens || tokens.length === 0) return;

    const message = {
      notification: {
        title: "💸 Dinheiro na Conta!",
        body: `Seu saque de R$ ${amount} foi aprovado e o Pix já foi enviado.`,
      },
      tokens: tokens,
      data: {
        click_action: "FLUTTER_NOTIFICATION_CLICK",
        type: "withdrawal_approved",
      },
    };

    try {
      // Using sendEachForMulticast to handle multiple devices for the same user
      const response = await admin.messaging().sendEachForMulticast(message);
      console.log(`Withdrawal notification sent to ${uid}.\nSuccess: ${response.successCount}`);

      // Optional: Cleanup invalid tokens
      if (response.failureCount > 0) {
        const failedTokens = [];
        response.responses.forEach((resp, idx) => {
          if (!resp.success) {
            failedTokens.push(tokens[idx]);
          }
        });
        if (failedTokens.length > 0) {
          await admin.firestore().collection("players").doc(uid).update({
            fcmTokens: admin.firestore.FieldValue.arrayRemove(...failedTokens),
          });
        }
      }
    } catch (error) {
      console.error("Error sending withdrawal push notification:", error);
    }
  }
});

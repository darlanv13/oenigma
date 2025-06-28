const { HttpsError, onCall } = require("firebase-functions/v2/https");
const admin = require("firebase-admin");

const db = admin.firestore();

// =================================================================== //
// FUNÇÃO: handleEnigmaAction (v2)                                     //
// DESCRIÇÃO: Processa ações do enigma (status, dica e validação).     //
// =================================================================== //
exports.handleEnigmaAction = onCall({ enforceAppCheck: false }, async (request) => { // AppCheck pode ser ativado depois
    // A verificação de autenticação é automática em funções v2 `onCall`.
    // Se o usuário não estiver autenticado, a função lançará um erro 'unauthenticated'.
    // `context.auth` se torna `request.auth`.
    const playerId = request.auth.uid;

    const { action, eventId, phaseOrder, enigmaId, code } = request.data;
    const playerRef = db.collection("players").doc(playerId);
    const eventRef = db.collection("events").doc(eventId);

    // --- Ação: getStatus ---
    if (action === "getStatus") {
        const playerDoc = await playerRef.get();
        const playerData = playerDoc.data() || {};
        const eventProgress = { currentPhase: 1, currentEnigma: 1, ...(playerData.events || {})[eventId] };
        const hintsPurchased = eventProgress.hintsPurchased || [];
        const attemptRef = playerRef.collection("eventAttempts").doc(enigmaId);
        const attemptDoc = await attemptRef.get();
        let cooldownUntil = null;
        let isBlocked = false;
        if (attemptDoc.exists && attemptDoc.data().cooldownUntil?.toDate() > new Date()) {
            cooldownUntil = attemptDoc.data().cooldownUntil.toDate().toISOString();
            isBlocked = true;
        }
        return {
            isHintVisible: hintsPurchased.includes(phaseOrder),
            canBuyHint: phaseOrder < 4 && !hintsPurchased.includes(phaseOrder),
            isBlocked: isBlocked,
            cooldownUntil: cooldownUntil,
        };
    }

    // --- Ação: purchaseHint ---
    if (action === "purchaseHint") {
        const hintCosts = { 1: 5, 2: 10, 3: 15 };
        const hintCost = hintCosts[phaseOrder];

        if (!hintCost) {
            throw new HttpsError("failed-precondition", "Dicas não estão disponíveis para esta fase.");
        }

        try {
            await db.runTransaction(async (transaction) => {
                const playerDoc = await transaction.get(playerRef);
                if (!playerDoc.exists) {
                    throw new HttpsError("not-found", "Jogador não encontrado.");
                }

                const playerData = playerDoc.data();
                const currentBalance = playerData.balance || 0;

                if (currentBalance < hintCost) {
                    throw new HttpsError("failed-precondition", "Saldo insuficiente para comprar a dica.");
                }

                const playerEvents = playerData.events || {};
                const eventProgress = { currentPhase: 1, currentEnigma: 1, ...playerEvents[eventId] };
                const hintsPurchased = eventProgress.hintsPurchased || [];

                if (hintsPurchased.includes(phaseOrder)) {
                    throw new HttpsError("already-exists", "Você já comprou a dica para esta fase.");
                }

                const enigmaDoc = await transaction.get(eventRef.collection("phases").doc(`fase_${phaseOrder}`).collection("enigmas").doc(enigmaId));
                const enigmaData = enigmaDoc.data();
                if (!enigmaData || !enigmaData.hintType || !enigmaData.hintData) {
                    throw new HttpsError("not-found", "Nenhuma dica disponível para este enigma.");
                }

                const newBalance = currentBalance - hintCost;
                const newProgress = {
                    ...eventProgress,
                    hintsPurchased: admin.firestore.FieldValue.arrayUnion(phaseOrder),
                };
                const newPlayerEvents = { ...playerEvents, [eventId]: newProgress };

                transaction.update(playerRef, {
                    balance: newBalance,
                    events: newPlayerEvents
                });
            });

            const enigmaDoc = await eventRef.collection("phases").doc(`fase_${phaseOrder}`).collection("enigmas").doc(enigmaId).get();
            const enigmaData = enigmaDoc.data();

            return {
                success: true,
                message: "Dica comprada com sucesso!",
                hint: { type: enigmaData.hintType, data: enigmaData.hintData },
            };

        } catch (error) {
            if (error instanceof HttpsError) {
                throw error;
            }
            console.error("Erro na transação de compra de dica:", error);
            throw new HttpsError("internal", "Ocorreu um erro ao processar a sua compra.");
        }
    }

    // ... (o restante da função 'handleEnigmaAction' continua o mesmo, apenas usando `HttpsError` diretamente) ...
    // --- Ação: validateCode ---
    if (action === "validateCode") {
        const eventDoc = await eventRef.get();
        if (!eventDoc.exists || eventDoc.data().status !== "open") {
            throw new HttpsError("failed-precondition", "Este evento não está mais ativo.");
        }
        if (!code) {
            throw new HttpsError("invalid-argument", "O código é obrigatório.");
        }

        const attemptRef = playerRef.collection("eventAttempts").doc(enigmaId);
        const attemptDoc = await attemptRef.get();
        if (attemptDoc.exists && attemptDoc.data().cooldownUntil?.toDate() > new Date()) {
            return {
                success: false,
                message: "Aguarde o fim do tempo de espera.",
                cooldownUntil: attemptDoc.data().cooldownUntil.toDate().toISOString(),
            };
        }

        const phaseDocRef = eventRef.collection("phases").doc(`fase_${phaseOrder}`);
        const enigmaDocRef = phaseDocRef.collection("enigmas").doc(enigmaId);
        const enigmaDoc = await enigmaDocRef.get();
        if (!enigmaDoc.exists) {
            throw new HttpsError("not-found", "Enigma não encontrado.");
        }

        if (enigmaDoc.data().code.toUpperCase() !== code.toUpperCase()) {
            const attempts = (attemptDoc.data()?.attempts || 0) + 1;
            if (attempts >= 3) {
                const cooldownTime = new Date(Date.now() + 10 * 60 * 1000);
                await attemptRef.set({ attempts, cooldownUntil: admin.firestore.Timestamp.fromDate(cooldownTime) });
                return {
                    success: false,
                    message: "Tentativas esgotadas. Aguarde 10 minutos.",
                    cooldownUntil: cooldownTime.toISOString(),
                };
            } else {
                await attemptRef.set({ attempts }, { merge: true });
                return { success: false, message: `Código incorreto. Você tem mais ${3 - attempts} tentativa(s).` };
            }
        }

        await attemptRef.delete().catch(() => { });

        let nextStepForClient = null;
        let isEventFinishedByThisPlayer = false;

        try {
            await db.runTransaction(async (transaction) => {
                const playerDoc = await transaction.get(playerRef);
                const playerData = playerDoc.data();
                const playerEvents = playerData.events || {};
                const eventProgress = { currentPhase: 1, currentEnigma: 1, ...playerEvents[eventId] };

                if (phaseOrder !== eventProgress.currentPhase) {
                    throw new HttpsError("failed-precondition", "Você está tentando resolver um enigma de uma fase que não é a sua fase atual.");
                }

                const phasesSnapshot = await transaction.get(eventRef.collection("phases"));
                const totalPhases = phasesSnapshot.size;
                const enigmasInPhaseSnapshot = await transaction.get(phaseDocRef.collection("enigmas").orderBy(admin.firestore.FieldPath.documentId()));
                const enigmasInCurrentPhase = enigmasInPhaseSnapshot.size;
                const isLastEnigma = eventProgress.currentEnigma >= enigmasInCurrentPhase;
                const isLastPhase = eventProgress.currentPhase >= totalPhases;

                if (isLastEnigma && isLastPhase) {
                    isEventFinishedByThisPlayer = true;
                    transaction.update(eventRef, {
                        status: "closed",
                        winnerId: playerId,
                        winnerName: playerData.name || "Anônimo",
                        finishedAt: admin.firestore.FieldValue.serverTimestamp(),
                    });
                    nextStepForClient = { type: "event_complete" };
                } else if (isLastEnigma) {
                    eventProgress.currentPhase += 1;
                    eventProgress.currentEnigma = 1;
                    nextStepForClient = { type: "phase_complete" };
                } else {
                    eventProgress.currentEnigma += 1;
                    const enigmaDocs = enigmasInPhaseSnapshot.docs;
                    const nextEnigmaDoc = enigmaDocs[eventProgress.currentEnigma - 1];
                    nextStepForClient = { type: "next_enigma", enigmaData: { id: nextEnigmaDoc.id, ...nextEnigmaDoc.data() } };
                }

                const newPlayerEvents = { ...playerEvents, [eventId]: eventProgress };
                transaction.update(playerRef, { events: newPlayerEvents });
            });
        } catch (error) {
            if (error instanceof HttpsError) throw error;
            throw new HttpsError("internal", "Erro ao processar sua resposta.", error.message);
        }

        if (isEventFinishedByThisPlayer) {
            const eventData = (await eventRef.get()).data();
            const playerData = (await playerRef.get()).data();
            await sendCompletionNotifications(eventId, eventData.name, playerId, playerData.name);
        }

        return { success: true, message: "Parabéns!", nextStep: nextStepForClient };
    }

    throw new HttpsError("invalid-argument", "Ação não suportada.");
});

// ... (A função sendCompletionNotifications não precisa de alterações) ...
async function sendCompletionNotifications(eventId, eventName, winnerId, winnerName) {
    const allPlayersSnap = await db.collection("players").get();
    const tokens = [];
    allPlayersSnap.forEach((doc) => {
        const player = doc.data();
        if (doc.id !== winnerId && player.events?.[eventId] && player.fcmToken) {
            tokens.push(player.fcmToken);
        }
    });

    if (tokens.length > 0) {
        const payload = {
            notification: {
                title: `O evento "${eventName}" foi finalizado!`,
                body: `${winnerName} é o grande vencedor! Confira o ranking.`,
                sound: "default",
            },
            data: {
                type: "event_finished",
                eventId: eventId,
            },
        };
        await admin.messaging().sendToDevice(tokens, payload);
    }
}
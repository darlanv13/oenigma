const {onCall, HttpsError} = require("firebase-functions/v2/https");
const admin = require("firebase-admin");
const db = admin.firestore();

// Middleware exportado para reuso em outros módulos admin
const requireAdmin = (request) => {
  if (!request.auth) {
    throw new HttpsError("unauthenticated", "User must be logged in.");
  }
  const isAdmin = request.auth.token.super_admin === true || request.auth.token.editor === true;
  if (!isAdmin) {
    throw new HttpsError("permission-denied", "User does not have admin privileges.");
  }
};
exports.requireAdmin = requireAdmin;

// Helper para deletar coleções
async function deleteCollection(collectionPath, batchSize) {
  const collectionRef = db.collection(collectionPath);
  const query = collectionRef.orderBy("__name__").limit(batchSize);
  return new Promise((resolve, reject) => {
    deleteQueryBatch(query, resolve).catch(reject);
  });
}
async function deleteQueryBatch(query, resolve) {
  const snapshot = await query.get();
  if (snapshot.size === 0) return resolve();
  const batch = db.batch();
  snapshot.docs.forEach((doc) => batch.delete(doc.ref));
  await batch.commit();
  process.nextTick(() => deleteQueryBatch(query, resolve));
}

// ---------------------------------------------------------------------------
// ADMIN EVENT CRUD OPERATIONS
// ---------------------------------------------------------------------------

exports.toggleEventStatus = onCall(async (request) => {
  requireAdmin(request);
  const {eventId, newStatus} = request.data;
  if (!eventId || !newStatus) throw new HttpsError("invalid-argument", "Missing eventId or newStatus.");
  await db.collection("events").doc(eventId).update({status: newStatus});
  return {success: true, message: `Status do evento atualizado para ${newStatus}.`};
});

exports.createOrUpdateEvent = onCall(async (request) => {
  requireAdmin(request);
  const {eventId, data} = request.data;
  let currentEventId = eventId;
  try {
    if (currentEventId) {
      await db.collection("events").doc(currentEventId).set(data, {merge: true});
    } else {
      const newEventRef = await db.collection("events").add(data);
      currentEventId = newEventRef.id;

      // --- AUTO-GENERATE 5 PHASES x 3 ENIGMAS ---
      const batch = db.batch();
      for (let p = 1; p <= 5; p++) {
        const phaseRef = newEventRef.collection("phases").doc(`phase_${p}`);
        batch.set(phaseRef, {
          order: p,
          isBlocked: p > 1, // Only first phase is unblocked by default
          createdAt: admin.firestore.FieldValue.serverTimestamp()
        });

        for (let e = 1; e <= 3; e++) {
          const enigmaRef = phaseRef.collection("enigmas").doc(`enigma_${e}`);
          batch.set(enigmaRef, {
            title: `Enigma ${e} (Fase ${p})`,
            order: e,
            type: "qr_code_gps",
            status: "open",
            correctCode: "EDIT_ME",
            allowHints: true,
            allowTools: true,
            linkedHints: [], // Array of Hint IDs from the hints_pool
            createdAt: admin.firestore.FieldValue.serverTimestamp()
          });
        }
      }
      await batch.commit();
      // ------------------------------------------
    }
    return {success: true, message: "Evento salvo com sucesso!", id: currentEventId};
  } catch (error) {
    throw new HttpsError("internal", "Erro ao salvar o evento.");
  }
});

exports.deleteEvent = onCall(async (request) => {
  requireAdmin(request);
  const {eventId} = request.data;
  if (!eventId) throw new HttpsError("invalid-argument", "ID do evento é obrigatório.");
  const phasesRef = db.collection("events").doc(eventId).collection("phases");
  const phasesSnapshot = await phasesRef.get();
  for (const doc of phasesSnapshot.docs) {
    await deleteCollection(`events/${eventId}/phases/${doc.id}/enigmas`, 100);
  }
  await deleteCollection(`events/${eventId}/phases`, 100);
  await db.collection("events").doc(eventId).delete();
  return {success: true, message: "Evento e todas as suas subcoleções foram excluídos com sucesso."};
});

// ---------------------------------------------------------------------------
// ADMIN USER MANAGEMENT
// ---------------------------------------------------------------------------

exports.listAllUsers = onCall(async (request) => {
  requireAdmin(request);
  const users = [];
  let pageToken;
  do {
    const listUsersResult = await admin.auth().listUsers(1000, pageToken);
    listUsersResult.users.forEach((userRecord) => {
      users.push({
        uid: userRecord.uid,
        email: userRecord.email,
        name: userRecord.displayName,
        isAdmin: userRecord.customClaims?.["super_admin"] === true,
      });
    });
    pageToken = listUsersResult.pageToken;
  } while (pageToken);
  return users;
});

exports.grantAdminRole = onCall(async (request) => {
  requireAdmin(request);
  const {uid} = request.data;
  await admin.auth().setCustomUserClaims(uid, {super_admin: true});
  return {success: true, message: "Permissão de administrador concedida."};
});

exports.revokeAdminRole = onCall(async (request) => {
  requireAdmin(request);
  const {uid} = request.data;
  await admin.auth().setCustomUserClaims(uid, {super_admin: false, editor: false});
  return {success: true, message: "Permissão de administrador revogada."};
});

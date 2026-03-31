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
// ENIGMAS & PHASES CRUD OPERATIONS
// ---------------------------------------------------------------------------

exports.createOrUpdateEnigma = onCall(async (request) => {
  requireAdmin(request);
  const { eventId, phaseId, enigmaId, data } = request.data;

  const eventRef = db.collection("events").doc(eventId);
  const eventDoc = await eventRef.get();
  if (!eventDoc.exists) throw new HttpsError("not-found", "O evento pai não foi encontrado.");

  const eventType = eventDoc.data().eventType;

  if (data.location && typeof data.location === "object" && data.location.latitude != null && data.location.longitude != null) {
    data.location = new admin.firestore.GeoPoint(data.location.latitude, data.location.longitude);
  }

  const collectionRef = phaseId ?
    eventRef.collection("phases").doc(phaseId).collection("enigmas") :
    eventRef.collection("enigmas");

  try {
    if (enigmaId) {
      await collectionRef.doc(enigmaId).update(data);
      return { success: true, message: "Enigma atualizado.", id: enigmaId };
    } else {
      data.status = "open";
      data.createdAt = admin.firestore.FieldValue.serverTimestamp();
      const newEnigmaRef = await collectionRef.add(data);
      if (eventType === "find_and_win" && !eventDoc.data().currentEnigmaId) {
        await eventRef.update({ currentEnigmaId: newEnigmaRef.id });
      }
      return { success: true, message: "Enigma criado com sucesso.", id: newEnigmaRef.id };
    }
  } catch (error) {
    console.error("Erro ao salvar enigma:", error);
    throw new HttpsError("internal", "Erro ao salvar o enigma.");
  }
});

exports.deleteEnigma = onCall(async (request) => {
  requireAdmin(request);
  const { eventId, phaseId, enigmaId } = request.data;
  if (!eventId || !enigmaId) throw new HttpsError("invalid-argument", "IDs são obrigatórios.");

  const eventRef = db.collection("events").doc(eventId);
  const eventDoc = await eventRef.get();

  const collectionRef = phaseId ?
    eventRef.collection("phases").doc(phaseId).collection("enigmas") :
    eventRef.collection("enigmas");

  await collectionRef.doc(enigmaId).delete();

  if (eventDoc.data().eventType === "find_and_win" && eventDoc.data().currentEnigmaId === enigmaId) {
    const remaining = await collectionRef.where("status", "==", "open").get();
    let nextEnigmaId = null;
    if (!remaining.empty) {
      nextEnigmaId = remaining.docs[Math.floor(Math.random() * remaining.docs.length)].id;
    }
    await eventRef.update({ currentEnigmaId: nextEnigmaId });
  }
  return { success: true, message: "Enigma excluído." };
});

exports.deletePhase = onCall(async (request) => {
  requireAdmin(request);
  const { eventId, phaseId } = request.data;
  if (!eventId || !phaseId) throw new HttpsError("invalid-argument", "IDs são obrigatórios.");
  await deleteCollection(`events/${eventId}/phases/${phaseId}/enigmas`, 100);
  await db.collection("events").doc(eventId).collection("phases").doc(phaseId).delete();
  return { success: true, message: "Fase excluída." };
});

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
      data.updatedAt = admin.firestore.FieldValue.serverTimestamp();
      await db.collection("events").doc(currentEventId).set(data, {merge: true});
    } else {
      data.createdAt = admin.firestore.FieldValue.serverTimestamp();
      data.updatedAt = admin.firestore.FieldValue.serverTimestamp();
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
// ADMIN HINTS & BANNERS CRUD OPERATIONS
// ---------------------------------------------------------------------------

exports.createOrUpdateHint = onCall(async (request) => {
  requireAdmin(request);
  const { hintId, data } = request.data;
  try {
    if (hintId) {
      data.updatedAt = admin.firestore.FieldValue.serverTimestamp();
      await db.collection("hints_pool").doc(hintId).update(data);
      return { success: true, message: "Dica atualizada." };
    } else {
      data.createdAt = admin.firestore.FieldValue.serverTimestamp();
      data.updatedAt = admin.firestore.FieldValue.serverTimestamp();
      const newRef = await db.collection("hints_pool").add(data);
      return { success: true, message: "Dica criada com sucesso.", id: newRef.id };
    }
  } catch (error) {
    throw new HttpsError("internal", "Erro ao salvar dica: " + error.message);
  }
});

exports.deleteHint = onCall(async (request) => {
  requireAdmin(request);
  const { hintId } = request.data;
  if (!hintId) throw new HttpsError("invalid-argument", "hintId is required.");
  await db.collection("hints_pool").doc(hintId).delete();
  return { success: true, message: "Dica excluída." };
});

exports.createOrUpdateBanner = onCall(async (request) => {
  requireAdmin(request);
  const { bannerId, data } = request.data;
  try {
    if (bannerId) {
      data.updatedAt = admin.firestore.FieldValue.serverTimestamp();
      await db.collection("banners").doc(bannerId).update(data);
      return { success: true, message: "Banner atualizado." };
    } else {
      data.createdAt = admin.firestore.FieldValue.serverTimestamp();
      data.updatedAt = admin.firestore.FieldValue.serverTimestamp();
      const newRef = await db.collection("banners").add(data);
      return { success: true, message: "Banner criado com sucesso.", id: newRef.id };
    }
  } catch (error) {
    throw new HttpsError("internal", "Erro ao salvar banner: " + error.message);
  }
});

exports.deleteBanner = onCall(async (request) => {
  requireAdmin(request);
  const { bannerId } = request.data;
  if (!bannerId) throw new HttpsError("invalid-argument", "bannerId is required.");
  await db.collection("banners").doc(bannerId).delete();
  return { success: true, message: "Banner excluído." };
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
    for (const userRecord of listUsersResult.users) {
      let firestoreName = null;
      try {
        const playerDoc = await db.collection("players").doc(userRecord.uid).get();
        if (playerDoc.exists) {
          firestoreName = playerDoc.data().name || playerDoc.data().displayName;
        }
      } catch (e) {
        console.warn("Could not fetch user name from firestore for", userRecord.uid);
      }

      users.push({
        uid: userRecord.uid,
        email: userRecord.email,
        name: firestoreName || userRecord.displayName || "Sem Nome",
        isAdmin: userRecord.customClaims?.["super_admin"] === true,
      });
    }
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

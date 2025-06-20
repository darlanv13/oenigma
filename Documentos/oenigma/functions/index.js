const functions = require("firebase-functions");
const admin = require("firebase-admin");

admin.initializeApp();
const db = admin.firestore();
const regionalFunctions = functions.region("southamerica-east1");

// =================================================================== //
// FUNÇÃO: getEventData                                                //
// DESCRIÇÃO: Busca dados de um evento específico ou de todos os eventos.//
// =================================================================== //
exports.getEventData = regionalFunctions.https.onCall(async (data, context) => {
  const eventId = data ? data.eventId : null;

  if (!eventId) {
    const eventsSnapshot = await db.collection("events").get();
    return eventsSnapshot.docs.map((doc) => ({ id: doc.id, ...doc.data() }));
  } else {
    const eventDoc = await db.collection("events").doc(eventId).get();
    if (!eventDoc.exists) {
      throw new functions.https.HttpsError("not-found", "Evento não encontrado.");
    }

    const eventData = { id: eventDoc.id, ...eventDoc.data() };
    const phasesSnapshot = await eventDoc.ref.collection("phases").orderBy("order").get();

    const phasesList = [];
    for (const phaseDoc of phasesSnapshot.docs) {
      const phaseId = phaseDoc.id;
      const phaseData = phaseDoc.data();
      const enigmasSnapshot = await phaseDoc.ref.collection("enigmas").orderBy(admin.firestore.FieldPath.documentId()).get();
      const enigmas = enigmasSnapshot.docs.map((enigmaDoc) => ({
        id: enigmaDoc.id,
        ...enigmaDoc.data(),
      }));
      phasesList.push({ id: phaseId, ...phaseData, enigmas: enigmas });
    }

    eventData.phases = phasesList;
    return eventData;
  }
});
// FIM DA FUNÇÃO getEventData


// =================================================================== //
// FUNÇÃO: getEventRanking                                             //
// DESCRIÇÃO: Calcula e retorna o ranking dos jogadores para um evento.//
// =================================================================== //
exports.getEventRanking = regionalFunctions.https.onCall(async (data, context) => {
  const { eventId } = data;
  if (!eventId) {
    throw new functions.https.HttpsError("invalid-argument", "O ID do evento é obrigatório.");
  }
  const phasesSnapshot = await db.collection("events").doc(eventId).collection("phases").get();
  const totalPhases = phasesSnapshot.docs.length;
  if (totalPhases === 0) return [];
  const playersSnapshot = await db.collection("players").get();
  let rankedPlayers = [];
  for (const playerDoc of playersSnapshot.docs) {
    const playerData = playerDoc.data();
    const progress = playerData.events?.[eventId];
    const phasesCompleted = progress ? (progress.currentPhase - 1) : 0;
    rankedPlayers.push({
      uid: playerDoc.id,
      name: playerData.name || 'Anônimo',
      photoURL: playerData.photoURL || null,
      phasesCompleted: phasesCompleted,
      totalPhases: totalPhases,
    });
  }
  rankedPlayers.sort((a, b) => b.phasesCompleted - a.phasesCompleted);
  return rankedPlayers.map((player, index) => ({ ...player, position: index + 1 }));
});
// FIM DA FUNÇÃO getEventRanking


// =================================================================== //
// FUNÇÃO: handleEnigmaAction                                          //
// DESCRIÇÃO: Processa ações do enigma (status, dica e validação).     //
// =================================================================== //
exports.handleEnigmaAction = regionalFunctions.https.onCall(async (data, context) => {
  if (!context.auth) {
    throw new functions.https.HttpsError("unauthenticated", "Requer autenticação.");
  }

  const { action, eventId, phaseOrder, enigmaId, code } = data;
  const playerId = context.auth.uid;
  const playerRef = db.collection("players").doc(playerId);
  const eventRef = db.collection("events").doc(eventId);

  if (action === "getStatus") {
    const playerDoc = await playerRef.get();
    const eventProgress = { currentPhase: 1, currentEnigma: 1, ...(playerDoc.data()?.events || {})[eventId] };
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

  if (action === "purchaseHint") {
    if (phaseOrder >= 4) {
      throw new functions.https.HttpsError("failed-precondition", "Dicas não estão disponíveis para esta fase.");
    }
    const playerDoc = await playerRef.get();
    const playerData = playerDoc.data() || {};
    const playerEvents = playerData.events || {};
    const eventProgress = { currentPhase: 1, currentEnigma: 1, ...playerEvents[eventId] };
    const hintsPurchased = eventProgress.hintsPurchased || [];
    if (hintsPurchased.includes(phaseOrder)) {
      throw new functions.https.HttpsError("already-exists", "Você já comprou a dica para esta fase.");
    }
    const enigmaDoc = await eventRef.collection("phases").doc(`fase_${phaseOrder}`).collection("enigmas").doc(enigmaId).get();
    const enigmaData = enigmaDoc.data();
    if (!enigmaData || !enigmaData.hintType || !enigmaData.hintData) {
      throw new functions.https.HttpsError("not-found", "Nenhuma dica disponível para este enigma.");
    }
    const newProgress = {
      ...eventProgress,
      hintsPurchased: admin.firestore.FieldValue.arrayUnion(phaseOrder),
    };
    const newPlayerEvents = { ...playerEvents, [eventId]: newProgress };
    await playerRef.update({ events: newPlayerEvents });
    return {
      success: true,
      message: "Dica comprada!",
      hint: { type: enigmaData.hintType, data: enigmaData.hintData },
    };
  }

  if (action === "validateCode") {
    const eventDoc = await eventRef.get();
    if (!eventDoc.exists || eventDoc.data().status !== "open") {
      throw new functions.https.HttpsError("failed-precondition", "Este evento não está mais ativo.");
    }
    if (!code) {
      throw new functions.https.HttpsError("invalid-argument", "O código é obrigatório.");
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
      throw new functions.https.HttpsError("not-found", "Enigma não encontrado.");
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
        return { success: false, message: `Você tem mais ${3 - attempts} tentativa.` };
      }
    }

    await attemptRef.delete().catch(() => { });
    let nextStepForClient = null;

    try {
      await db.runTransaction(async (transaction) => {
        const playerDoc = await transaction.get(playerRef);
        const playerData = playerDoc.data();
        const playerEvents = playerData.events || {};
        const eventProgress = { currentPhase: 1, currentEnigma: 1, ...playerEvents[eventId] };

        if (phaseOrder !== eventProgress.currentPhase) {
          throw new functions.https.HttpsError("failed-precondition", "Você está tentando resolver um enigma de uma fase que não é a sua fase atual.");
        }

        const phasesSnapshot = await transaction.get(eventRef.collection("phases"));
        const totalPhases = phasesSnapshot.size;
        const enigmasInPhaseSnapshot = await transaction.get(phaseDocRef.collection("enigmas").orderBy(admin.firestore.FieldPath.documentId()));
        const enigmasInCurrentPhase = enigmasInPhaseSnapshot.size;
        const isLastEnigma = eventProgress.currentEnigma >= enigmasInCurrentPhase;
        const isLastPhase = eventProgress.currentPhase >= totalPhases;

        if (isLastEnigma && isLastPhase) {
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
      if (error instanceof functions.https.HttpsError) throw error;
      throw new functions.https.HttpsError("internal", "Erro ao processar sua resposta.", error.message);
    }

    return { success: true, message: "Parabéns!", nextStep: nextStepForClient };
  }

  throw new functions.https.HttpsError("invalid-argument", "Ação não suportada.");
});
// FIM DA FUNÇÃO handleEnigmaAction
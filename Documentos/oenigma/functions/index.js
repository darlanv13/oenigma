const functions = require("firebase-functions");
const admin = require("firebase-admin");

admin.initializeApp();
const db = admin.firestore();

const regionalFunctions = functions.region("southamerica-east1");

// --- Função para buscar dados de eventos ---
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
        eventData.phases = await Promise.all(phasesSnapshot.docs.map(async (phaseDoc) => {
            const enigmasSnapshot = await phaseDoc.ref.collection("enigmas").orderBy("id").get();
            const enigmas = enigmasSnapshot.docs.map((enigmaDoc) => ({ id: enigmaDoc.id, ...enigmaDoc.data() }));
            return { id: phaseDoc.id, ...phaseDoc.data(), enigmas: enigmas };
        }));
        return eventData;
    }
});

// --- Função para ações do enigma (COM A LÓGICA CORRIGIDA) ---
exports.handleEnigmaAction = regionalFunctions.https.onCall(async (data, context) => {
    if (!context.auth) {
        throw new functions.https.HttpsError("unauthenticated", "Requer autenticação.");
    }
    const { eventId, phaseOrder, enigmaId, action, code } = data;
    const userId = context.auth.uid;
    const playerRef = db.collection("players").doc(userId);
    const attemptRef = playerRef.collection("eventAttempts").doc(enigmaId);

    if (action === "getStatus") {
        const playerDoc = await playerRef.get();
        const progress = playerDoc.data()?.events?.[eventId] || {};
        const hintsPurchased = progress.hintsPurchased || [];
        const attemptDoc = await attemptRef.get();
        let cooldownUntil = null;
        if (attemptDoc.exists && attemptDoc.data().cooldownUntil?.toDate() > new Date()) {
            cooldownUntil = attemptDoc.data().cooldownUntil.toDate().toISOString();
        }
        return {
            isHintVisible: hintsPurchased.includes(phaseOrder),
            canBuyHint: phaseOrder <= 5 && !hintsPurchased.includes(phaseOrder),
            isBlocked: cooldownUntil != null,
            cooldownUntil: cooldownUntil,
        };
    }

    if (action === "purchaseHint") {
        if (phaseOrder > 5) {
            throw new functions.https.HttpsError("failed-precondition", "Dicas não estão disponíveis após a fase 5.");
        }
        // CORREÇÃO: Usa 'update' com notação de ponto para adicionar a dica sem apagar outros dados.
        const hintFieldPath = `events.${eventId}.hintsPurchased`;
        await playerRef.update({
            [hintFieldPath]: admin.firestore.FieldValue.arrayUnion(phaseOrder)
        }).catch(async (error) => {
            // Se o campo 'events' ou 'eventId' não existir, cria-o de forma segura.
            if (error.code === 'not-found') {
                await playerRef.set({ events: { [eventId]: { hintsPurchased: [phaseOrder] } } }, { merge: true });
            } else {
                throw error;
            }
        });
        return { success: true, message: "Dica comprada!" };
    }

    if (action === "validateCode") {
        if (!code) { throw new functions.https.HttpsError("invalid-argument", "Código obrigatório."); }
        const attemptDoc = await attemptRef.get();
        if (attemptDoc.exists && attemptDoc.data().cooldownUntil?.toDate() > new Date()) {
            return { success: false, message: "Aguarde o fim do tempo de espera." };
        }
        const phaseSnapshot = await db.collection("events").doc(eventId).collection("phases").where("order", "==", phaseOrder).limit(1).get();
        if (phaseSnapshot.empty) { throw new functions.https.HttpsError("not-found", "Fase não encontrada."); }
        const phaseDoc = phaseSnapshot.docs[0];
        const enigmaDoc = await phaseDoc.ref.collection("enigmas").doc(enigmaId).get();
        if (!enigmaDoc.exists) { throw new functions.https.HttpsError("not-found", "Enigma não encontrado."); }

        const isCorrect = enigmaDoc.data().code.toUpperCase() === code.toUpperCase();
        if (isCorrect) {
            await attemptRef.delete().catch(() => {});
            const enigmasSnapshot = await phaseDoc.ref.collection("enigmas").orderBy("id").get();
            const enigmas = enigmasSnapshot.docs.map(doc => ({ id: doc.id, ...doc.data() }));
            const currentIndex = enigmas.findIndex(e => e.id === enigmaId);

            let nextStep = { type: "phase_complete" };
            let nextEnigmaIndex = 1;
            let nextPhaseOrder = phaseOrder + 1;

            if (currentIndex < enigmas.length - 1) {
                const nextEnigma = enigmas[currentIndex + 1];
                nextStep = { type: "next_enigma", enigmaData: nextEnigma };
                nextEnigmaIndex = currentIndex + 2;
                nextPhaseOrder = phaseOrder;
            }

            // CORREÇÃO: Usa 'update' com notação de ponto para atualizar o progresso.
            const progressUpdate = {};
            progressUpdate[`events.${eventId}.currentPhase`] = nextPhaseOrder;
            progressUpdate[`events.${eventId}.currentEnigma`] = nextEnigmaIndex;
            await playerRef.update(progressUpdate).catch(async (error) => {
                 if (error.code === 'not-found') {
                    await playerRef.set({ events: { [eventId]: { currentPhase: nextPhaseOrder, currentEnigma: nextEnigmaIndex } } }, { merge: true });
                 } else {
                     throw error;
                 }
            });

            return { success: true, message: "Parabéns! Código correto.", nextStep: nextStep };
        } else {
            const attempts = (attemptDoc.data()?.attempts || 0) + 1;
            if (attempts >= 3) {
                const cooldownTime = new Date(Date.now() + 10 * 60 * 1000);
                await attemptRef.set({ attempts, cooldownUntil: admin.firestore.Timestamp.fromDate(cooldownTime) });
                return { success: false, message: "Tentativas esgotadas. Aguarde 10 minutos." };
            } else {
                await attemptRef.set({ attempts }, { merge: true });
                return { success: false, message: `Código incorreto. Você tem mais ${3 - attempts} tentativa(s).` };
            }
        }
    }
    throw new functions.https.HttpsError("unknown", "Ação desconhecida.");
});

// --- Função para buscar o ranking ---
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
        const phasesCompleted = progress ? (progress.currentPhase || 1) - 1 : 0;
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
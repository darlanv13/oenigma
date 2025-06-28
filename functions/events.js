const { HttpsError, onCall } = require("firebase-functions/v2/https");
const admin = require("firebase-admin");

const db = admin.firestore();

// =================================================================== //
// FUNÇÃO: getEventData (v2)                                           //
// DESCRIÇÃO: Busca dados de um evento específico ou de todos os eventos.//
// =================================================================== //
exports.getEventData = onCall(async (request) => {
    const eventId = request.data ? request.data.eventId : null;

    if (!eventId) {
        const eventsSnapshot = await db.collection("events").get();
        return eventsSnapshot.docs.map((doc) => ({ id: doc.id, ...doc.data() }));
    } else {
        const eventDoc = await db.collection("events").doc(eventId).get();
        if (!eventDoc.exists) {
            throw new HttpsError("not-found", "Evento não encontrado.");
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

// =================================================================== //
// FUNÇÃO: getEventRanking (v2)                                        //
// DESCRIÇÃO: Calcula e retorna o ranking dos jogadores para um evento.//
// =================================================================== //
exports.getEventRanking = onCall(async (request) => {
    const { eventId } = request.data;
    if (!eventId) {
        throw new HttpsError("invalid-argument", "O ID do evento é obrigatório.");
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
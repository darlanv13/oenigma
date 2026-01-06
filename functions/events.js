const { HttpsError, onCall } = require("firebase-functions/v2/https");
const admin = require("firebase-admin");

const db = admin.firestore();

// =================================================================== //
// FUNÇÃO: getEventData (CORRIGIDA PARA AMBOS OS MODOS DE JOGO)
// =================================================================== //
exports.getEventData = onCall(async (request) => {
    const eventId = request.data ? request.data.eventId : null;

    if (!eventId) {
        // Se nenhum ID for fornecido, retorna a lista de todos os eventos (comportamento inalterado)
        const eventsSnapshot = await db.collection("events").get();
        return eventsSnapshot.docs.map((doc) => ({ id: doc.id, ...doc.data() }));
    } else {
        // Se um ID for fornecido, busca os detalhes completos
        const eventDoc = await db.collection("events").doc(eventId).get();
        if (!eventDoc.exists) {
            throw new HttpsError("not-found", "Evento não encontrado.");
        }

        const eventData = { id: eventDoc.id, ...eventDoc.data() };
        const eventType = eventData.eventType || 'classic';

        // --- LÓGICA DINÂMICA BASEADA NO TIPO DE EVENTO ---
        if (eventType === 'find_and_win') {
            // Busca a subcoleção de 'enigmas' diretamente
            const enigmasSnapshot = await eventDoc.ref.collection("enigmas").orderBy("order").get();
            eventData.enigmas = enigmasSnapshot.docs.map((doc) => ({ id: doc.id, ...doc.data() }));
            eventData.phases = []; // Garante que a lista de fases esteja vazia
        } else {
            // Lógica existente para o modo clássico
            const phasesSnapshot = await eventDoc.ref.collection("phases").orderBy("order").get();
            const phasesList = [];
            for (const phaseDoc of phasesSnapshot.docs) {
                const enigmasSnapshot = await phaseDoc.ref.collection("enigmas").get();
                const enigmas = enigmasSnapshot.docs.map((enigmaDoc) => ({ id: enigmaDoc.id, ...enigmaDoc.data() }));
                phasesList.push({ id: phaseDoc.id, ...phaseDoc.data(), enigmas: enigmas });
            }
            eventData.phases = phasesList;
            eventData.enigmas = []; // Garante que a lista de enigmas principal esteja vazia
        }

        return eventData;
    }
});

// =================================================================== //
// NOVA FUNÇÃO: getFindAndWinStats
// DESCRIÇÃO: Busca o total de enigmas e quantos foram resolvidos
//            para um evento do tipo "Find & Win".
// =================================================================== //
exports.getFindAndWinStats = onCall(async (request) => {
    const { eventId } = request.data;
    if (!eventId) {
        throw new HttpsError("invalid-argument", "O ID do evento é obrigatório.");
    }

    try {
        const enigmasRef = db.collection("events").doc(eventId).collection("enigmas");

        // Busca o total de enigmas e os resolvidos em paralelo
        const [allEnigmasSnapshot, solvedEnigmasSnapshot] = await Promise.all([
            enigmasRef.get(),
            enigmasRef.where("status", "==", "closed").get()
        ]);

        return {
            totalEnigmas: allEnigmasSnapshot.size,
            solvedEnigmas: solvedEnigmasSnapshot.size,
        };
    } catch (error) {
        console.error("Erro ao buscar estatísticas do evento:", error);
        throw new HttpsError("internal", "Não foi possível buscar as estatísticas.");
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
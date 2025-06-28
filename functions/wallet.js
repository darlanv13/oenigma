const { HttpsError, onCall } = require("firebase-functions/v2/https");
const admin = require("firebase-admin");

const db = admin.firestore();

exports.getUserWalletData = onCall(async (request) => {
    // Verificação de autenticação é automática e `context.auth` vira `request.auth`.
    const userId = request.auth.uid;
    const playerDoc = await db.collection("players").doc(userId).get();

    if (!playerDoc.exists) {
        throw new HttpsError("not-found", "Dados do jogador não encontrados.");
    }

    const playerData = playerDoc.data();

    // --- LÓGICA DE RANKING E ÚLTIMO EVENTO CORRIGIDA ---
    let lastEventRank = null;
    let lastEventName = null;

    // 1. Obter todos os eventos primeiro
    const allEventsSnapshot = await db.collection("events").get();
    const allEvents = allEventsSnapshot.docs.map(doc => ({ id: doc.id, ...doc.data() }));

    // 2. Filtrar os eventos em que o jogador participou
    const playerEventIds = Object.keys(playerData.events || {});
    const participatedEvents = allEvents.filter(event => playerEventIds.includes(event.id));

    // 3. Encontrar, dentre os eventos participados, o último que ainda está ativo
    const lastActiveEvent = participatedEvents
        .filter(event => event.status !== 'closed')
        .pop(); // Pega o último da lista filtrada

    if (lastActiveEvent) {
        lastEventName = lastActiveEvent.name;
        const eventId = lastActiveEvent.id;

        // Calcular o ranking para esse evento específico
        const allPlayersSnapshot = await db.collection("players").get();
        const phasesSnapshot = await db.collection("events").doc(eventId).collection("phases").get();
        const totalPhases = phasesSnapshot.size > 0 ? phasesSnapshot.size : 1;

        let eventRanking = [];
        allPlayersSnapshot.forEach(doc => {
            const pData = doc.data();
            if (pData.events && pData.events[eventId]) {
                const progress = pData.events[eventId];
                const phasesCompleted = progress.currentPhase ? progress.currentPhase - 1 : 0;
                eventRanking.push({
                    uid: doc.id,
                    progress: phasesCompleted / totalPhases,
                });
            }
        });

        eventRanking.sort((a, b) => b.progress - a.progress);
        const userRankIndex = eventRanking.findIndex(p => p.uid === userId);
        if (userRankIndex !== -1) {
            lastEventRank = userRankIndex + 1;
        }
    }

    // Lógica de último prémio (inalterada)
    let lastWonEventName = null;
    const wonEventsSnapshot = await db.collection("events")
        .where("winnerId", "==", userId)
        .orderBy("finishedAt", "desc")
        .limit(1)
        .get();

    if (!wonEventsSnapshot.empty) {
        lastWonEventName = wonEventsSnapshot.docs[0].data().name;
    }

    return {
        uid: userId,
        name: playerData.name || 'Utilizador',
        email: playerData.email,
        photoURL: playerData.photoURL || null,
        balance: playerData.balance || 0,
        lastWonEventName: lastWonEventName,
        lastEventRank: lastEventRank,
        lastEventName: lastEventName,
    };
});
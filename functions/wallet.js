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
        // Ranking removido por performance
        lastEventRank = null;
    }

    // Lógica de último prémio (inalterada)
    let lastWonEventName = null;
    const wonEventsSnapshot = await db.collection("events")
        .where("winnerId", "==", userId)
        .get();

    if (!wonEventsSnapshot.empty) {
        const wonEvents = wonEventsSnapshot.docs.map(doc => doc.data());
        // Ordenação em memória para evitar índice composto
        wonEvents.sort((a, b) => {
            const timeA = a.finishedAt && a.finishedAt.toMillis ? a.finishedAt.toMillis() : 0;
            const timeB = b.finishedAt && b.finishedAt.toMillis ? b.finishedAt.toMillis() : 0;
            return timeB - timeA;
        });
        lastWonEventName = wonEvents[0].name;
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
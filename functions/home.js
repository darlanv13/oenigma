// functions/home.js

const { HttpsError, onCall } = require("firebase-functions/v2/https");
const admin = require("firebase-admin");

const db = admin.firestore();

// =================================================================== //
// FUNÇÃO OTIMIZADA: getHomeScreenData
// DESCRIÇÃO: Busca todos os dados necessários para a Home Screen
// em uma única chamada.
// =================================================================== //
exports.getHomeScreenData = onCall(async (request) => {
    const userId = request.auth.uid;
    if (!userId) {
        throw new HttpsError("unauthenticated", "Usuário não autenticado.");
    }

    try {
        // 1. Executa todas as leituras necessárias em paralelo
        const [
            eventsSnapshot,
            allPlayersSnapshot,
            playerDoc,
            wonEventsSnapshot,
        ] = await Promise.all([
            db.collection("events").get(),
            db.collection("players").get(),
            db.collection("players").doc(userId).get(),
            db.collection("events").where("winnerId", "==", userId).orderBy("finishedAt", "desc").limit(1).get()
        ]);

        if (!playerDoc.exists) {
            throw new HttpsError("not-found", "Dados do jogador não encontrados.");
        }

        // 2. Processa os dados
        const allEvents = eventsSnapshot.docs.map(doc => ({ id: doc.id, ...doc.data() }));
        const allPlayers = allPlayersSnapshot.docs.map(doc => ({ id: doc.id, ...doc.data() }));
        const playerData = playerDoc.data();

        // 3. Lógica para o Ranking e Saldo (similar ao que estava em wallet.js)
        let lastEventRank = null;
        let lastEventName = null;
        const playerEventIds = Object.keys(playerData.events || {});
        const lastActiveEvent = allEvents
            .filter(event => playerEventIds.includes(event.id) && event.status !== 'closed')
            .pop();

        if (lastActiveEvent) {
            lastEventName = lastActiveEvent.name;
            const ranking = allPlayers
                .filter(p => p.events && p.events[lastActiveEvent.id])
                .map(p => ({ uid: p.id, progress: (p.events[lastActiveEvent.id].currentPhase - 1) }))
                .sort((a, b) => b.progress - a.progress);

            const userRankIndex = ranking.findIndex(p => p.uid === userId);
            if (userRankIndex !== -1) {
                lastEventRank = userRankIndex + 1;
            }
        }

        let lastWonEventName = null;
        if (!wonEventsSnapshot.empty) {
            lastWonEventName = wonEventsSnapshot.docs[0].data().name;
        }

        // 4. Retorna um único objeto consolidado
        return {
            events: allEvents,
            allPlayers: allPlayers,
            playerData: playerData, // Incluímos todos os jogadores para passar para a tela de Ranking
            walletData: {
                uid: userId,
                name: playerData.name,
                email: playerData.email,
                photoURL: playerData.photoURL,
                balance: playerData.balance || 0,
                lastWonEventName: lastWonEventName,
                lastEventRank: lastEventRank,
                lastEventName: lastEventName,
            }
        };

    } catch (error) {
        console.error("Erro em getHomeScreenData:", error);
        throw new HttpsError("internal", "Não foi possível carregar os dados da tela inicial.");
    }
});
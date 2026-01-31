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
            playerDoc,
            wonEventsSnapshot,
        ] = await Promise.all([
            db.collection("events").get(),
            db.collection("players").doc(userId).get(),
            db.collection("events").where("winnerId", "==", userId).get()
        ]);

        if (!playerDoc.exists) {
            throw new HttpsError("not-found", "Dados do jogador não encontrados.");
        }

        // 2. Processa os dados
        const allEvents = eventsSnapshot.docs.map(doc => ({ id: doc.id, ...doc.data() }));
        const playerData = playerDoc.data();

        // 3. Lógica para o Ranking e Saldo (similar ao que estava em wallet.js)
        // OBS: Ranking desativado para evitar leitura de toda a coleção de players
        let lastEventRank = null;
        let lastEventName = null;
        const playerEventIds = Object.keys(playerData.events || {});
        const lastActiveEvent = allEvents
            .filter(event => playerEventIds.includes(event.id) && event.status !== 'closed')
            .pop();

        if (lastActiveEvent) {
            lastEventName = lastActiveEvent.name;
            // Ranking removido por performance
            lastEventRank = null;
        }

        let lastWonEventName = null;
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

        // 4. Retorna um único objeto consolidado
        return {
            events: allEvents,
            // allPlayers removido para otimizar payload
            player: playerData, // Renomeado para 'player' para bater com o cliente
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
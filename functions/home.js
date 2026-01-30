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
    // 1. Verificação de Segurança (Correção de Crash)
    if (!request.auth) {
        throw new HttpsError("unauthenticated", "Usuário não autenticado.");
    }

    const userId = request.auth.uid;

    try {
        // 2. Executa leituras em paralelo
        // REMOVIDO: A query específica para wonEvents que exigia índice composto
        const [
            eventsSnapshot,
            allPlayersSnapshot,
            playerDoc
        ] = await Promise.all([
            db.collection("events").get(),
            db.collection("players").get(),
            db.collection("players").doc(userId).get()
        ]);

        if (!playerDoc.exists) {
            throw new HttpsError("not-found", "Dados do jogador não encontrados.");
        }

        // 3. Processa os dados
        const allEvents = eventsSnapshot.docs.map(doc => ({ id: doc.id, ...doc.data() }));
        const allPlayers = allPlayersSnapshot.docs.map(doc => ({ id: doc.id, ...doc.data() }));
        const playerData = playerDoc.data();

        // 4. Lógica para o Ranking e Saldo
        let lastEventRank = null;
        let lastEventName = null;
        const playerEventIds = Object.keys(playerData.events || {});

        // Encontra o último evento ativo que o usuário participa
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

        // 5. Lógica para Última Vitória (Em Memória - Sem Custo Adicional de Leitura)
        // Filtra os eventos onde o usuário é o vencedor
        const wonEvents = allEvents.filter(e => e.winnerId === userId);

        // Ordena por data de finalização (mais recente primeiro)
        wonEvents.sort((a, b) => {
            const timeA = a.finishedAt && a.finishedAt.toMillis ? a.finishedAt.toMillis() : 0;
            const timeB = b.finishedAt && b.finishedAt.toMillis ? b.finishedAt.toMillis() : 0;
            return timeB - timeA;
        });

        let lastWonEventName = null;
        if (wonEvents.length > 0) {
            lastWonEventName = wonEvents[0].name;
        }

        // 6. Retorna objeto consolidado
        return {
            events: allEvents,
            allPlayers: allPlayers,
            playerData: playerData,
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
        // Retorna a mensagem original se for uma HttpsError conhecida, senão genérica
        if (error instanceof HttpsError) {
            throw error;
        }
        throw new HttpsError("internal", "Não foi possível carregar os dados da tela inicial: " + error.message);
    }
});

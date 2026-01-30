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
    // 1. Verificação de Segurança
    if (!request.auth) {
        throw new HttpsError("unauthenticated", "Usuário não autenticado.");
    }

    const userId = request.auth.uid;
    const userEmail = request.auth.token.email || "";
    const userName = request.auth.token.name || "Novo Usuário";
    const userPhoto = request.auth.token.picture || null;

    try {
        // 2. Executa leituras em paralelo
        const [
            eventsSnapshot,
            allPlayersSnapshot,
            playerDoc
        ] = await Promise.all([
            db.collection("events").get(),
            db.collection("players").get(),
            db.collection("players").doc(userId).get()
        ]);

        let playerData;

        // 3. AUTO-REPARO: Se o doc do jogador não existir, cria um padrão.
        if (!playerDoc.exists) {
            console.warn(`Jogador ${userId} não encontrado. Criando perfil padrão.`);

            const newPlayerData = {
                name: userName,
                email: userEmail,
                photoURL: userPhoto,
                balance: 0,
                createdAt: admin.firestore.FieldValue.serverTimestamp(),
                role: 'user',
                events: {}
            };

            // Salva no banco (Fire-and-forget ou await se for crucial)
            await db.collection("players").doc(userId).set(newPlayerData);

            playerData = newPlayerData;
        } else {
            playerData = playerDoc.data();
        }

        // 4. Processa os dados
        const allEvents = eventsSnapshot.docs.map(doc => ({ id: doc.id, ...doc.data() }));
        const allPlayers = allPlayersSnapshot.docs.map(doc => ({ id: doc.id, ...doc.data() }));

        // 5. Lógica para o Ranking e Saldo
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

        // 6. Lógica para Última Vitória (Em Memória)
        const wonEvents = allEvents.filter(e => e.winnerId === userId);

        wonEvents.sort((a, b) => {
            const timeA = a.finishedAt && a.finishedAt.toMillis ? a.finishedAt.toMillis() : 0;
            const timeB = b.finishedAt && b.finishedAt.toMillis ? b.finishedAt.toMillis() : 0;
            return timeB - timeA;
        });

        let lastWonEventName = null;
        if (wonEvents.length > 0) {
            lastWonEventName = wonEvents[0].name;
        }

        // 7. Retorna objeto consolidado
        return {
            events: allEvents,
            allPlayers: allPlayers,
            playerData: playerData,
            walletData: {
                uid: userId,
                name: playerData.name || userName,
                email: playerData.email || userEmail,
                photoURL: playerData.photoURL,
                balance: playerData.balance || 0,
                lastWonEventName: lastWonEventName,
                lastEventRank: lastEventRank,
                lastEventName: lastEventName,
            }
        };

    } catch (error) {
        console.error("Erro em getHomeScreenData:", error);
        if (error instanceof HttpsError) {
            throw error;
        }
        throw new HttpsError("internal", "Falha crítica na tela inicial: " + error.message);
    }
});

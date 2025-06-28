const { HttpsError, onCall } = require("firebase-functions/v2/https");
const admin = require("firebase-admin");

const db = admin.firestore();

// =================================================================== //
// FUNÇÃO: getAdminDashboardData (v2)                                  //
// DESCRIÇÃO: Busca todos os dados para o painel de admin em uma chamada.//
// =================================================================== //
exports.getAdminDashboardData = onCall(async (request) => {
    /*
    // Para reativar a autenticação, use a verificação automática da v2.
    // O código da função só será executado se o usuário estiver autenticado.
    // Opcionalmente, verifique permissões de admin:
    if (request.auth.token.role !== 'admin') {
        throw new HttpsError("permission-denied", "Requer permissão de administrador.");
    }
    */

    const eventsSnapshot = await db.collection("events").get();
    const playersSnapshot = await db.collection("players").get();

    const playersData = playersSnapshot.docs.map(doc => ({ id: doc.id, ...doc.data() }));

    const dashboardData = [];

    for (const eventDoc of eventsSnapshot.docs) {
        const eventData = { id: eventDoc.id, ...eventDoc.data() };
        const eventId = eventDoc.id;

        const phasesSnapshot = await db.collection("events").doc(eventId).collection("phases").get();
        eventData.totalPhases = phasesSnapshot.size;

        eventData.playerCount = playersData.filter(p => p.events && p.events[eventId]).length;

        let rankedPlayers = [];
        for (const player of playersData) {
            if (player.events && player.events[eventId]) {
                const progress = player.events[eventId];
                const phasesCompleted = progress.currentPhase ? (progress.currentPhase - 1) : 0;

                rankedPlayers.push({
                    uid: player.id,
                    name: player.name || 'Anônimo',
                    progress: eventData.totalPhases > 0 ? phasesCompleted / eventData.totalPhases : 0,
                });
            }
        }

        rankedPlayers.sort((a, b) => b.progress - a.progress);
        eventData.ranking = rankedPlayers.slice(0, 5).map((player, index) => ({ ...player, position: index + 1 }));

        dashboardData.push(eventData);
    }

    return dashboardData;
});

// =================================================================== //
// NOVA FUNÇÃO: toggleEventStatus (v2)                                 //
// DESCRIÇÃO: Altera o status de um evento (open, closed, dev).        //
// =================================================================== //
exports.toggleEventStatus = onCall(async (request) => {
    /*
    // Verificação de permissão de admin:
    if (!request.auth || request.auth.token.role !== 'admin') {
        throw new HttpsError("permission-denied", "Requer permissão de administrador.");
    }
    */

    const { eventId, newStatus } = request.data;

    if (!eventId || !newStatus) {
        throw new HttpsError("invalid-argument", "É necessário fornecer o ID do evento e o novo status.");
    }

    try {
        await db.collection("events").doc(eventId).update({ status: newStatus });
        return { success: true, message: `Status do evento ${eventId} atualizado para ${newStatus}.` };
    } catch (error) {
        console.error("Erro ao atualizar status do evento:", error);
        throw new HttpsError("internal", "Não foi possível atualizar o status do evento.");
    }
});
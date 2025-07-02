const { HttpsError, onCall } = require("firebase-functions/v2/https");
const admin = require("firebase-admin");

const db = admin.firestore();

// =================================================================== //
// FUNÇÃO: getAdminDashboardData (ATUALIZADA)
// DESCRIÇÃO: Busca todos os dados para o painel de admin em uma chamada.
// =================================================================== //
exports.getAdminDashboardData = onCall(async (request) => {
    if (!request.auth || request.auth.token.role !== 'admin') {
        throw new HttpsError("permission-denied", "Requer permissão de administrador.");
    }


    // Busca os dados em paralelo para mais eficiência
    const [eventsSnapshot, playersSnapshot] = await Promise.all([
        db.collection("events").get(),
        db.collection("players").get()
    ]);

    const totalPlayers = playersSnapshot.size;

    // Mapeia os eventos e calcula a contagem de jogadores para cada um
    const eventsData = eventsSnapshot.docs.map((doc) => {
        const event = { id: doc.id, ...doc.data() };
        // Conta quantos jogadores têm este eventId em seu submapa 'events'
        event.playerCount = playersSnapshot.docs.filter(p => p.data().events && p.data().events[event.id]).length;
        return event;
    });

    // Retorna um único objeto (mapa) com todos os dados necessários
    return {
        events: eventsData,
        playerCount: totalPlayers,
        // No futuro, você pode adicionar dados para o feed de atividades aqui
    };
});

// =================================================================== //
// NOVA FUNÇÃO: toggleEventStatus
// DESCRIÇÃO: Altera o status de um evento (open, closed, dev).
// =================================================================== //
exports.toggleEventStatus = onCall(async (request) => {

    if (!request.auth || request.auth.token.role !== 'admin') {
        throw new HttpsError("permission-denied", "Requer permissão de administrador.");
    }


    const { eventId, newStatus } = request.data;

    if (!eventId || !newStatus) {
        throw new HttpsError("invalid-argument", "É necessário fornecer o ID do evento e o novo status.");
    }

    try {
        await db.collection("events").doc(eventId).update({ status: newStatus });
        return { success: true, message: `Status do evento atualizado para ${newStatus}.` };
    } catch (error) {
        console.error("Erro ao atualizar status do evento:", error);
        throw new HttpsError("internal", "Não foi possível atualizar o status do evento.");
    }
});
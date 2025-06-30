const { HttpsError, onCall } = require("firebase-functions/v2/https");
const admin = require("firebase-admin");

const db = admin.firestore();

// =================================================================== //
// FUNÇÃO: getAdminDashboardData (CORRIGIDA)
// DESCRIÇÃO: Busca todos os dados para o painel de admin em uma chamada.
// =================================================================== //
exports.getAdminDashboardData = onCall(async (request) => {
    /*
    // Para reativar a autenticação, use a verificação automática da v2.
    if (request.auth.token.role !== 'admin') {
        throw new HttpsError("permission-denied", "Requer permissão de administrador.");
    }
    */

    // Busca os dados em paralelo para mais eficiência
    const [eventsSnapshot, playersSnapshot] = await Promise.all([
        db.collection("events").get(),
        db.collection("players").get()
    ]);

    const playersData = playersSnapshot.docs.map(doc => ({ id: doc.id, ...doc.data() }));
    const totalPlayers = playersSnapshot.size;

    // Mapeia os eventos e calcula a contagem de jogadores para cada um
    const eventsData = await Promise.all(eventsSnapshot.docs.map(async (eventDoc) => {
        const eventData = { id: eventDoc.id, ...eventDoc.data() };

        const phasesSnapshot = await db.collection("events").doc(eventDoc.id).collection("phases").get();
        eventData.totalPhases = phasesSnapshot.size;

        // Calcula a contagem de jogadores inscritos neste evento
        eventData.playerCount = playersData.filter(p => p.events && p.events[eventDoc.id]).length;

        return eventData;
    }));

    // --- CORREÇÃO PRINCIPAL AQUI ---
    // Retorna um único objeto (mapa) em vez de uma lista
    return {
        events: eventsData,
        playerCount: totalPlayers,
    };
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
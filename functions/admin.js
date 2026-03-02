const { HttpsError, onCall } = require("firebase-functions/v2/https");
const admin = require("firebase-admin");

const db = admin.firestore();

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
// Middleware function pattern to check admin claims
exports.requireAdmin = (request) => {
    if (!request.auth) {
        throw new HttpsError("unauthenticated", "User must be logged in.");
    }
    const isAdmin = request.auth.token.super_admin === true || request.auth.token.editor === true;
    if (!isAdmin) {
        throw new HttpsError("permission-denied", "User does not have admin privileges.");
    }
};

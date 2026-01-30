const { HttpsError, onCall } = require("firebase-functions/v2/https");
const admin = require("firebase-admin");
const { logAdminAction } = require("./utils");

const db = admin.firestore();

// Helper to check permissions
const hasRole = (request, roles) => {
    if (!request.auth) return false;
    const userRole = request.auth.token.role;
    // 'admin' is for legacy compatibility, treated as 'super_admin'
    if (userRole === 'admin') return true;
    return roles.includes(userRole);
};

// =================================================================== //
// NOVA FUNÇÃO: toggleEventStatus
// DESCRIÇÃO: Altera o status de um evento (open, closed, dev).
// =================================================================== //
exports.toggleEventStatus = onCall(async (request) => {

    // Allow super_admin (admin) and editor
    if (!hasRole(request, ['super_admin', 'editor'])) {
        throw new HttpsError("permission-denied", "Requer permissão de administrador ou editor.");
    }


    const { eventId, newStatus } = request.data;

    if (!eventId || !newStatus) {
        throw new HttpsError("invalid-argument", "É necessário fornecer o ID do evento e o novo status.");
    }

    try {
        await db.collection("events").doc(eventId).update({ status: newStatus });

        await logAdminAction(request.auth.uid, 'toggle_event_status', eventId, { newStatus });

        return { success: true, message: `Status do evento atualizado para ${newStatus}.` };
    } catch (error) {
        console.error("Erro ao atualizar status do evento:", error);
        throw new HttpsError("internal", "Não foi possível atualizar o status do evento.");
    }
});

// =================================================================== //
// NOVA FUNÇÃO: setUserRole
// DESCRIÇÃO: Define o papel de um usuário (apenas super_admin pode chamar).
// =================================================================== //
exports.setUserRole = onCall(async (request) => {
    // Only super_admin (or legacy admin) can assign roles
    if (!hasRole(request, ['super_admin'])) {
        throw new HttpsError("permission-denied", "Apenas super administradores podem gerenciar papéis.");
    }

    const { email, role } = request.data;
    const validRoles = ['super_admin', 'editor', 'auditor', 'admin']; // 'admin' kept for legacy/compatibility

    if (!email || !role || !validRoles.includes(role)) {
        throw new HttpsError("invalid-argument", "Email e um papel válido (super_admin, editor, auditor) são obrigatórios.");
    }

    try {
        const userRecord = await admin.auth().getUserByEmail(email);

        // Set custom claims
        await admin.auth().setCustomUserClaims(userRecord.uid, { role });

        await logAdminAction(request.auth.uid, 'set_user_role', userRecord.uid, { email, role });

        return { success: true, message: `Papel de ${role} atribuído ao usuário ${email}.` };
    } catch (error) {
        console.error("Erro ao definir papel do usuário:", error);
        throw new HttpsError("internal", "Não foi possível definir o papel do usuário. Verifique se o email está correto.");
    }
});

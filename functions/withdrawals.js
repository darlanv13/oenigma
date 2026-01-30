const { onCall, HttpsError } = require("firebase-functions/v2/https");
const admin = require("firebase-admin");

const db = admin.firestore();

// Helper para verificar admin
const ensureIsAdmin = (request) => {
    if (!request.auth || request.auth.token.role !== 'admin') {
        throw new HttpsError("permission-denied", "Acesso negado. Requer permissão de administrador.");
    }
};

exports.approveWithdrawal = onCall(async (request) => {
    ensureIsAdmin(request);
    const { withdrawalId } = request.data;

    if (!withdrawalId) {
        throw new HttpsError("invalid-argument", "ID do saque é obrigatório.");
    }

    const withdrawalRef = db.collection("withdrawals").doc(withdrawalId);

    try {
        await db.runTransaction(async (transaction) => {
            const withdrawalDoc = await transaction.get(withdrawalRef);

            if (!withdrawalDoc.exists) {
                throw new HttpsError("not-found", "Saque não encontrado.");
            }

            const data = withdrawalDoc.data();
            if (data.status !== 'pending') {
                throw new HttpsError("failed-precondition", "Este saque já foi processado.");
            }

            // Atualiza status para aprovado
            transaction.update(withdrawalRef, {
                status: 'approved',
                processedAt: admin.firestore.FieldValue.serverTimestamp(),
                processedBy: request.auth.uid
            });
        });

        return { success: true, message: "Saque aprovado com sucesso." };
    } catch (error) {
        console.error("Erro ao aprovar saque:", error);
        throw error instanceof HttpsError ? error : new HttpsError("internal", "Erro ao processar aprovação.");
    }
});

exports.rejectWithdrawal = onCall(async (request) => {
    ensureIsAdmin(request);
    const { withdrawalId, reason } = request.data;

    if (!withdrawalId) {
        throw new HttpsError("invalid-argument", "ID do saque é obrigatório.");
    }

    const withdrawalRef = db.collection("withdrawals").doc(withdrawalId);

    try {
        await db.runTransaction(async (transaction) => {
            const withdrawalDoc = await transaction.get(withdrawalRef);

            if (!withdrawalDoc.exists) {
                throw new HttpsError("not-found", "Saque não encontrado.");
            }

            const data = withdrawalDoc.data();
            if (data.status !== 'pending') {
                throw new HttpsError("failed-precondition", "Este saque já foi processado.");
            }

            const userId = data.userId;
            const amount = data.amount;

            if (!userId || !amount) {
                throw new HttpsError("data-loss", "Dados do saque inválidos (usuário ou valor faltando).");
            }

            const userRef = db.collection("players").doc(userId);

            // Verifica se o usuário existe
            const userDoc = await transaction.get(userRef);
            if (!userDoc.exists) {
                 throw new HttpsError("not-found", "Usuário do saque não encontrado.");
            }

            // Reembolsa o valor ao usuário
            transaction.update(userRef, {
                balance: admin.firestore.FieldValue.increment(amount)
            });

            // Atualiza status para rejeitado
            transaction.update(withdrawalRef, {
                status: 'rejected',
                rejectionReason: reason || "Rejeitado pelo administrador",
                processedAt: admin.firestore.FieldValue.serverTimestamp(),
                processedBy: request.auth.uid
            });
        });

        return { success: true, message: "Saque rejeitado e valor reembolsado." };
    } catch (error) {
        console.error("Erro ao rejeitar saque:", error);
        throw error instanceof HttpsError ? error : new HttpsError("internal", "Erro ao processar rejeição.");
    }
});

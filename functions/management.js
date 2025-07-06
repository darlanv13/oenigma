const { HttpsError, onCall } = require("firebase-functions/v2/https");
const admin = require("firebase-admin");

// Esta linha é essencial para que o arquivo se comunique com o banco de dados.
const db = admin.firestore();

// Função de verificação de permissão de administrador
const ensureIsAdmin = (context) => {

    if (!context.auth || context.auth.token.role !== 'admin') {
        throw new HttpsError("permission-denied", "Acesso negado. Requer permissão de administrador.");
    }
    // Mantemos o aviso para lembrar que a segurança está desativada para testes.
    //console.warn("AVISO: Verificação de admin desativada para fins de teste.");
};
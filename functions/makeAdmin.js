const admin = require("firebase-admin");

// 1. Aponte para o arquivo JSON que você acabou de baixar
const serviceAccount = require("./serviceAccountKey.json");

// 2. Inicialize o SDK com as credenciais da Service Account
admin.initializeApp({
    credential: admin.credential.cert(serviceAccount)
});

// 3. Coloque o UID do usuário que você criou no app
const uid = "lSyYqvDznrfZvqO87UUTVB5DGJC3";

async function setAdmin() {
    try {
        // 4. Concede os poderes de Super Admin
        await admin.auth().setCustomUserClaims(uid, { super_admin: true });
        console.log(`Sucesso Absoluto! O usuário ${uid} agora é um Super Admin.`);
        console.log("Faça logout e login no aplicativo para testar o acesso ao Painel Admin.");
    } catch (error) {
        console.error("Erro fatal ao tentar setar admin:", error);
    } finally {
        process.exit();
    }
}

setAdmin();
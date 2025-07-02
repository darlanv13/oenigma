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
    console.warn("AVISO: Verificação de admin desativada para fins de teste.");
};

// =================================================================== //
// FUNÇÃO: createOrUpdateEvent (ATUALIZADA)
// =================================================================== //
exports.createOrUpdateEvent = onCall(async (request) => {
    ensureIsAdmin(request);
    const { eventId, data } = request.data;

    if (!data || !data.name || !data.prize || data.price == null) {
        throw new HttpsError("invalid-argument", "Dados do evento incompletos.");
    }

    // Adiciona o eventType se não for fornecido (para eventos antigos)
    if (!data.eventType) {
        data.eventType = 'classic';
    }

    try {
        if (eventId) {
            await db.collection("events").doc(eventId).set(data, { merge: true });
            return { success: true, eventId: eventId, message: "Evento atualizado." };
        } else {
            const newEventRef = await db.collection("events").add(data);
            return { success: true, eventId: newEventRef.id, message: "Evento criado." };
        }
    } catch (error) {
        console.error("Erro em createOrUpdateEvent:", error);
        throw new HttpsError("internal", "Não foi possível salvar o evento.");
    }
});

// =================================================================== //
// FUNÇÃO: createOrUpdateEnigma (ATUALIZADA)
// =================================================================== //
exports.createOrUpdateEnigma = onCall(async (request) => {
    ensureIsAdmin(request);
    const { eventId, phaseId, enigmaId, data } = request.data;

    if (!eventId || !data || !data.type || !data.code || !data.instruction) {
        throw new HttpsError("invalid-argument", "Dados do enigma incompletos.");
    }

    // Validação condicional para imageUrl
    if ((data.type === 'photo_location' || data.type === 'qr_code_gps') && !data.imageUrl) {
        throw new HttpsError("invalid-argument", "A URL da imagem é obrigatória para este tipo de enigma.");
    }

    // Garante que o prêmio seja um número
    data.prize = Number(data.prize) || 0;

    try {
        // Para "Find & Win", não teremos phaseId, então salvamos na coleção de enigmas do evento
        const collectionPath = phaseId
            ? db.collection("events").doc(eventId).collection("phases").doc(phaseId).collection("enigmas")
            : db.collection("events").doc(eventId).collection("enigmas");

        const enigmaRef = enigmaId ? collectionPath.doc(enigmaId) : collectionPath.doc();

        await enigmaRef.set(data, { merge: true });
        return { success: true, enigmaId: enigmaRef.id, message: "Enigma salvo." };
    } catch (error) {
        console.error("Erro em createOrUpdateEnigma:", error);
        throw new HttpsError("internal", "Não foi possível salvar o enigma.");
    }
});


// =================================================================== //
// FUNÇÃO: createOrUpdatePhase
// DESCRIÇÃO: Cria ou atualiza uma fase dentro de um evento.
// =================================================================== //
exports.createOrUpdatePhase = onCall(async (request) => {
    ensureIsAdmin(request);
    const { eventId, phaseId, data } = request.data;

    if (!eventId || !data || data.order == null) {
        throw new HttpsError("invalid-argument", "Dados da fase incompletos (eventId e order são obrigatórios).");
    }

    try {
        const phaseRef = phaseId
            ? db.collection("events").doc(eventId).collection("phases").doc(phaseId)
            : db.collection("events").doc(eventId).collection("phases").doc(); // Gera um novo ID se não existir

        await phaseRef.set(data, { merge: true });
        return { success: true, phaseId: phaseRef.id, message: "Fase salva com sucesso." };
    } catch (error) {
        console.error("Erro em createOrUpdatePhase:", error);
        throw new HttpsError("internal", "Não foi possível salvar a fase.");
    }
});

// =================================================================== //
// FUNÇÕES DE EXCLUSÃO (Exemplos)
// =================================================================== //
exports.deleteEvent = onCall(async (request) => {
    ensureIsAdmin(request);
    const { eventId } = request.data;
    if (!eventId) throw new HttpsError("invalid-argument", "ID do evento é obrigatório.");

    // ATENÇÃO: Uma exclusão em produção exigiria apagar as subcoleções (fases, enigmas)
    // de forma recursiva, o que é uma operação mais complexa.
    // Para o painel, esta exclusão simples é suficiente por enquanto.
    await db.collection("events").doc(eventId).delete();
    return { success: true, message: "Evento excluído." };
});


// =================================================================== //
// FUNÇÃO: listAllUsers
// DESCRIÇÃO: Retorna uma lista de todos os usuários registrados.
// =================================================================== //
exports.listAllUsers = onCall(async (request) => {
    ensureIsAdmin(request); // Apenas admins podem listar usuários

    try {
        const userRecords = await admin.auth().listUsers();
        const users = userRecords.users.map((user) => ({
            uid: user.uid,
            email: user.email,
            displayName: user.displayName || 'Sem nome',
            photoURL: user.photoURL,
            disabled: user.disabled,
            // Retorna as permissões customizadas (claims)
            isAdmin: user.customClaims?.role === 'admin',
        }));
        return users;
    } catch (error) {
        console.error("Erro ao listar usuários:", error);
        throw new HttpsError("internal", "Não foi possível listar os usuários.");
    }
});

// =================================================================== //
// FUNÇÃO: grantAdminRole
// DESCRIÇÃO: Atribui a permissão de administrador a um usuário.
// =================================================================== //
exports.grantAdminRole = onCall(async (request) => {
    ensureIsAdmin(request); // Apenas admins podem promover outros admins

    const { uid } = request.data;
    if (!uid) {
        throw new HttpsError("invalid-argument", "O UID do usuário é obrigatório.");
    }

    try {
        // Define o custom claim 'role' como 'admin'
        await admin.auth().setCustomUserClaims(uid, { role: 'admin' });
        return { success: true, message: "Permissão de administrador concedida." };
    } catch (error) {
        console.error("Erro ao conceder permissão:", error);
        throw new HttpsError("internal", "Não foi possível conceder a permissão.");
    }
});

// =================================================================== //
// FUNÇÃO: revokeAdminRole
// DESCRIÇÃO: Remove a permissão de administrador de um usuário.
// =================================================================== //
exports.revokeAdminRole = onCall(async (request) => {
    ensureIsAdmin(request);

    const { uid } = request.data;
    if (!uid) {
        throw new HttpsError("invalid-argument", "O UID do usuário é obrigatório.");
    }

    try {
        // Remove os custom claims, revertendo o usuário ao padrão
        await admin.auth().setCustomUserClaims(uid, null);
        return { success: true, message: "Permissão de administrador revogada." };
    } catch (error) {
        console.error("Erro ao revogar permissão:", error);
        throw new HttpsError("internal", "Não foi possível revogar a permissão.");
    }
});
// Você pode adicionar funções como deletePhase e deleteEnigma aqui no futuro.
const { HttpsError, onCall } = require("firebase-functions/v2/https");
const admin = require("firebase-admin");

// Esta linha é essencial para que o arquivo se comunique com o banco de dados.
const db = admin.firestore();

// Função de verificação de permissão de administrador
const ensureIsAdmin = (context) => {
    // Para produção, descomente esta verificação!
    /*
    if (!context.auth || context.auth.token.role !== 'admin') {
        throw new HttpsError("permission-denied", "Acesso negado. Requer permissão de administrador.");
    }
    */
    // Mantemos o aviso para lembrar que a segurança está desativada para testes.
    console.warn("AVISO: Verificação de admin desativada para fins de teste.");
};

// =================================================================== //
// FUNÇÃO: createOrUpdateEvent
// DESCRIÇÃO: Cria um novo evento ou atualiza um existente.
// =================================================================== //
exports.createOrUpdateEvent = onCall(async (request) => {
    ensureIsAdmin(request);

    const { eventId, data } = request.data;

    // Validação básica dos dados recebidos
    if (!data || !data.name || !data.prize || data.price == null) {
        throw new HttpsError("invalid-argument", "Dados do evento incompletos (nome, prêmio e preço são obrigatórios).");
    }

    try {
        if (eventId) {
            // Atualiza um evento existente
            await db.collection("events").doc(eventId).set(data, { merge: true });
            return { success: true, eventId: eventId, message: "Evento atualizado com sucesso." };
        } else {
            // Cria um novo evento
            const newEventRef = await db.collection("events").add(data);
            return { success: true, eventId: newEventRef.id, message: "Evento criado com sucesso." };
        }
    } catch (error) {
        console.error("Erro em createOrUpdateEvent:", error);
        throw new HttpsError("internal", "Não foi possível salvar o evento.");
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

//=================================================================== / /
// FUNÇÃO: createOrUpdateEnigma (ATUALIZADA)
// =================================================================== //
exports.createOrUpdateEnigma = onCall(async (request) => {
    ensureIsAdmin(request);
    const { eventId, phaseId, enigmaId, data } = request.data;

    if (!eventId || !phaseId || !data || !data.type || !data.code || !data.instruction) {
        throw new HttpsError("invalid-argument", "Dados do enigma incompletos.");
    }

    // Validação condicional para imageUrl
    if ((data.type === 'photo_location' || data.type === 'qr_code_gps') && !data.imageUrl) {
        throw new HttpsError("invalid-argument", "A URL da imagem é obrigatória para este tipo de enigma.");
    }

    // Validação para formato de GPS na dica
    if (data.hintType === 'gps' && data.hintData) {
        const coords = data.hintData.split(',');
        if (coords.length !== 2 || isNaN(parseFloat(coords[0])) || isNaN(parseFloat(coords[1]))) {
            throw new HttpsError("invalid-argument", 'O formato da dica de GPS deve ser "latitude,longitude".');
        }
    }

    try {
        const enigmaRef = enigmaId
            ? db.collection("events").doc(eventId).collection("phases").doc(phaseId).collection("enigmas").doc(enigmaId)
            : db.collection("events").doc(eventId).collection("phases").doc(phaseId).collection("enigmas").doc();

        await enigmaRef.set(data, { merge: true });
        return { success: true, enigmaId: enigmaRef.id, message: "Enigma salvo com sucesso." };
    } catch (error) {
        console.error("Erro em createOrUpdateEnigma:", error);
        throw new HttpsError("internal", "Não foi possível salvar o enigma.");
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

// Você pode adicionar funções como deletePhase e deleteEnigma aqui no futuro.
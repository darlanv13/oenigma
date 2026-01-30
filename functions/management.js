// functions/management.js

const { HttpsError, onCall } = require("firebase-functions/v2/https");
const admin = require("firebase-admin");
// const functions = require("firebase-functions"); // Removido pois não é usado e pode causar conflitos

const db = admin.firestore();

// Função de verificação de permissão de administrador
const ensureIsAdmin = (context) => {
    if (!context.auth || context.auth.token.role !== 'admin') {
        throw new HttpsError("permission-denied", "Acesso negado. Requer permissão de administrador.");
    }
};

/**
 * Função recursiva para deletar uma coleção e todas as suas subcoleções.
 * Esta é a abordagem robusta para produção.
 * @param {string} collectionPath O caminho para a coleção a ser deletada.
 * @param {number} batchSize O número de documentos a serem deletados por vez.
 */
async function deleteCollection(collectionPath, batchSize) {
    const collectionRef = db.collection(collectionPath);
    const query = collectionRef.orderBy('__name__').limit(batchSize);

    return new Promise((resolve, reject) => {
        deleteQueryBatch(query, resolve).catch(reject);
    });
}

async function deleteQueryBatch(query, resolve) {
    const snapshot = await query.get();

    if (snapshot.size === 0) {
        return resolve();
    }

    const batch = db.batch();
    snapshot.docs.forEach((doc) => {
        batch.delete(doc.ref);
    });

    await batch.commit();

    process.nextTick(() => {
        deleteQueryBatch(query, resolve);
    });
}


// --- GERENCIAMENTO DE EVENTOS ---

exports.createOrUpdateEvent = onCall(async (request) => {
    ensureIsAdmin(request);
    const { eventId, data } = request.data;
    let currentEventId = eventId;

    try {
        if (currentEventId) {
            await db.collection("events").doc(currentEventId).set(data, { merge: true });
        } else {
            const newEventRef = await db.collection("events").add(data);
            currentEventId = newEventRef.id;
        }

        if (data.eventType === 'find_and_win') {
            const eventRef = db.collection("events").doc(currentEventId);

            // LÓGICA DE SELEÇÃO ALEATÓRIA PARA O PRIMEIRO ENIGMA
            const openEnigmasQuery = await eventRef.collection("enigmas")
                .where("status", "==", "open")
                .get();

            let firstEnigmaId = null;
            if (!openEnigmasQuery.empty) {
                const openEnigmas = openEnigmasQuery.docs;
                const randomIndex = Math.floor(Math.random() * openEnigmas.length);
                firstEnigmaId = openEnigmas[randomIndex].id;
            }

            await eventRef.update({ currentEnigmaId: firstEnigmaId });
        }

        return { success: true, message: "Evento salvo com sucesso!", id: currentEventId };

    } catch (error) {
        console.error("Erro detalhado ao salvar evento:", error);
        throw new HttpsError("internal", "Erro ao salvar o evento.");
    }
});

// ✅ FUNÇÃO ATUALIZADA COM A SOLUÇÃO ROBUSTA
exports.deleteEvent = onCall(async (request) => {
    ensureIsAdmin(request);
    const { eventId } = request.data;
    if (!eventId) throw new HttpsError("invalid-argument", "ID do evento é obrigatório.");

    // Deleta as subcoleções de enigmas do modo "Find and Win"
    await deleteCollection(`events/${eventId}/enigmas`, 100);

    // Deleta as fases e suas subcoleções de enigmas do modo "Classic"
    const phasesRef = db.collection('events').doc(eventId).collection('phases');
    const phasesSnapshot = await phasesRef.get();
    for (const doc of phasesSnapshot.docs) {
        // Deleta os enigmas dentro de cada fase
        await deleteCollection(`events/${eventId}/phases/${doc.id}/enigmas`, 100);
    }
    // Deleta a coleção de fases em si
    await deleteCollection(`events/${eventId}/phases`, 100);

    // Finalmente, deleta o documento principal do evento
    await db.collection('events').doc(eventId).delete();

    return { success: true, message: 'Evento e todas as suas subcoleções foram excluídos com sucesso.' };
});



// CRIA ENIGMAS //
exports.createOrUpdateEnigma = onCall(async (request) => {
    ensureIsAdmin(request);
    const { eventId, phaseId, enigmaId, data } = request.data;

    const eventRef = db.collection("events").doc(eventId);
    const eventDoc = await eventRef.get();
    if (!eventDoc.exists) {
        throw new HttpsError("not-found", "O evento pai não foi encontrado.");
    }
    const eventType = eventDoc.data().eventType;

    // --- CORREÇÃO APLICADA AQUI ---
    // Verifica se recebemos um mapa de localização do frontend.
    if (data.location && typeof data.location === 'object' && data.location.latitude != null && data.location.longitude != null) {
        // Converte o mapa simples para um objeto GeoPoint do Firestore.
        data.location = new admin.firestore.GeoPoint(data.location.latitude, data.location.longitude);
    }
    // -----------------------------

    let collectionRef = phaseId
        ? eventRef.collection("phases").doc(phaseId).collection("enigmas")
        : eventRef.collection("enigmas");

    try {
        if (enigmaId) {
            await collectionRef.doc(enigmaId).update(data);
            return { success: true, message: "Enigma atualizado.", id: enigmaId };
        } else {
            data.status = 'open';
            const newEnigmaRef = await collectionRef.add(data);
            const currentEventData = (await eventRef.get()).data();
            if (eventType === 'find_and_win' && !currentEventData.currentEnigmaId) {
                await eventRef.update({ currentEnigmaId: newEnigmaRef.id });
            }
            return { success: true, message: "Enigma criado com sucesso.", id: newEnigmaRef.id };
        }
    } catch (error) {
        console.error("Erro ao salvar enigma:", error);
        throw new HttpsError("internal", "Erro ao salvar o enigma.");
    }
});

//DELETAR ENIGMA//

exports.deleteEnigma = onCall(async (request) => {
    ensureIsAdmin(request);
    const { eventId, phaseId, enigmaId } = request.data;
    if (!eventId || !enigmaId) throw new HttpsError("invalid-argument", "IDs são obrigatórios.");

    const eventRef = db.collection('events').doc(eventId);
    const eventDoc = await eventRef.get();
    const eventData = eventDoc.data();

    let collectionRef = phaseId
        ? eventRef.collection('phases').doc(phaseId).collection('enigmas')
        : eventRef.collection('enigmas');

    // Deleta o enigma solicitado
    await collectionRef.doc(enigmaId).delete();

    // --- LÓGICA DE AUTO-CORREÇÃO ADICIONADA ---
    // Se o enigma deletado era o enigma atual do evento "Find & Win"...
    if (eventData.eventType === 'find_and_win' && eventData.currentEnigmaId === enigmaId) {
        // ...procuramos por qualquer outro enigma aberto para colocar no lugar.
        const remainingEnigmasQuery = await collectionRef.where("status", "==", "open").get();

        let nextEnigmaId = null;
        if (!remainingEnigmasQuery.empty) {
            // Sorteia um novo enigma aleatório para continuar o jogo
            const remainingEnigmas = remainingEnigmasQuery.docs;
            const randomIndex = Math.floor(Math.random() * remainingEnigmas.length);
            nextEnigmaId = remainingEnigmas[randomIndex].id;
        }

        // Atualiza o evento com o novo enigma atual (ou nulo, se não houver mais)
        await eventRef.update({ currentEnigmaId: nextEnigmaId });
    }
    // ------------------------------------

    return { success: true, message: 'Enigma excluído.' };
});

exports.deletePhase = onCall(async (request) => {
    ensureIsAdmin(request);
    const { eventId, phaseId } = request.data;
    if (!eventId || !phaseId) throw new HttpsError("invalid-argument", "IDs são obrigatórios.");

    await deleteCollection(`events/${eventId}/phases/${phaseId}/enigmas`, 100);
    await db.collection('events').doc(eventId).collection('phases').doc(phaseId).delete();

    return { success: true, message: 'Fase e seus enigmas foram excluídos.' };
});

// --- GERENCIAMENTO DE USUÁRIOS/ADMINS ---

exports.listAllUsers = onCall(async (request) => {
    ensureIsAdmin(request);
    const users = [];
    let pageToken;
    do {
        const listUsersResult = await admin.auth().listUsers(1000, pageToken);
        listUsersResult.users.forEach((userRecord) => {
            users.push({
                uid: userRecord.uid,
                email: userRecord.email,
                name: userRecord.displayName,
                isAdmin: userRecord.customClaims?.['role'] === 'admin'
            });
        });
        pageToken = listUsersResult.pageToken;
    } while (pageToken);
    return users;
});

exports.grantAdminRole = onCall(async (request) => {
    ensureIsAdmin(request);
    const { uid } = request.data;
    await admin.auth().setCustomUserClaims(uid, { role: 'admin' });
    return { success: true, message: 'Permissão de administrador concedida.' };
});

exports.revokeAdminRole = onCall(async (request) => {
    ensureIsAdmin(request);
    const { uid } = request.data;
    await admin.auth().setCustomUserClaims(uid, { role: null });
    return { success: true, message: 'Permissão de administrador revogada.' };
});
// functions/management.js

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

const ensureCanManageEvents = (request) => {
    if (!hasRole(request, ['super_admin', 'editor'])) {
        throw new HttpsError("permission-denied", "Acesso negado. Requer permissão de administrador ou editor.");
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
    ensureCanManageEvents(request);
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

        await logAdminAction(request.auth.uid, 'create_or_update_event', currentEventId, { eventType: data.eventType });

        return { success: true, message: "Evento salvo com sucesso!", id: currentEventId };

    } catch (error) {
        console.error("Erro detalhado ao salvar evento:", error);
        throw new HttpsError("internal", "Erro ao salvar o evento.");
    }
});

// ✅ FUNÇÃO ATUALIZADA COM A SOLUÇÃO ROBUSTA
exports.deleteEvent = onCall(async (request) => {
    ensureCanManageEvents(request);
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

    await logAdminAction(request.auth.uid, 'delete_event', eventId, {});

    return { success: true, message: 'Evento e todas as suas subcoleções foram excluídos com sucesso.' };
});



// CRIA ENIGMAS //
exports.createOrUpdateEnigma = onCall(async (request) => {
    ensureCanManageEvents(request);
    const { eventId, phaseId, enigmaId, data } = request.data;

    const eventRef = db.collection("events").doc(eventId);
    const eventDoc = await eventRef.get();
    if (!eventDoc.exists) {
        throw new HttpsError("not-found", "O evento pai não foi encontrado.");
    }
    // Correctly accessing eventType from eventDoc.data()
    const eventData = eventDoc.data();
    const eventType = eventData ? eventData.eventType : 'classic';

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
        let resultId;
        if (enigmaId) {
            await collectionRef.doc(enigmaId).update(data);
            resultId = enigmaId;
        } else {
            data.status = 'open';
            const newEnigmaRef = await collectionRef.add(data);
            resultId = newEnigmaRef.id;
            const currentEventData = (await eventRef.get()).data();
            if (eventType === 'find_and_win' && !currentEventData.currentEnigmaId) {
                await eventRef.update({ currentEnigmaId: newEnigmaRef.id });
            }
        }

        await logAdminAction(request.auth.uid, 'create_or_update_enigma', resultId, { eventId, phaseId });
        return { success: true, message: enigmaId ? "Enigma atualizado." : "Enigma criado com sucesso.", id: resultId };

    } catch (error) {
        console.error("Erro ao salvar enigma:", error);
        throw new HttpsError("internal", "Erro ao salvar o enigma.");
    }
});

//DELETAR ENIGMA//

exports.deleteEnigma = onCall(async (request) => {
    ensureCanManageEvents(request);
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

    await logAdminAction(request.auth.uid, 'delete_enigma', enigmaId, { eventId, phaseId });

    return { success: true, message: 'Enigma excluído.' };
});

exports.deletePhase = onCall(async (request) => {
    ensureCanManageEvents(request);
    const { eventId, phaseId } = request.data;
    if (!eventId || !phaseId) throw new HttpsError("invalid-argument", "IDs são obrigatórios.");

    await deleteCollection(`events/${eventId}/phases/${phaseId}/enigmas`, 100);
    await db.collection('events').doc(eventId).collection('phases').doc(phaseId).delete();

    await logAdminAction(request.auth.uid, 'delete_phase', phaseId, { eventId });

    return { success: true, message: 'Fase e seus enigmas foram excluídos.' };
});

exports.createOrUpdatePhase = onCall(async (request) => {
    ensureCanManageEvents(request);
    const { eventId, phaseId, data } = request.data;
    if (!eventId || !data) throw new HttpsError("invalid-argument", "EventID e Data são obrigatórios.");

    try {
        let resultId;
        const phasesRef = db.collection('events').doc(eventId).collection('phases');

        if (phaseId) {
            await phasesRef.doc(phaseId).update(data);
            resultId = phaseId;
        } else {
            const newPhase = await phasesRef.add(data);
            resultId = newPhase.id;
        }

        await logAdminAction(request.auth.uid, 'create_or_update_phase', resultId, { eventId });
        return { success: true, message: 'Fase salva com sucesso.', id: resultId };
    } catch (error) {
        console.error("Erro ao salvar fase:", error);
        throw new HttpsError("internal", "Erro ao salvar a fase.");
    }
});


// --- GERENCIAMENTO DE USUÁRIOS/ADMINS ---

exports.listAllUsers = onCall(async (request) => {
    // Only super_admin (or admin legacy) can list users
    if (!hasRole(request, ['super_admin'])) {
        throw new HttpsError("permission-denied", "Acesso negado.");
    }

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
    if (!hasRole(request, ['super_admin'])) throw new HttpsError("permission-denied", "Acesso negado.");
    const { uid } = request.data;
    await admin.auth().setCustomUserClaims(uid, { role: 'admin' });
    await logAdminAction(request.auth.uid, 'grant_admin_role', uid, {});
    return { success: true, message: 'Permissão de administrador concedida.' };
});

exports.revokeAdminRole = onCall(async (request) => {
    if (!hasRole(request, ['super_admin'])) throw new HttpsError("permission-denied", "Acesso negado.");
    const { uid } = request.data;
    await admin.auth().setCustomUserClaims(uid, { role: null });
    await logAdminAction(request.auth.uid, 'revoke_admin_role', uid, {});
    return { success: true, message: 'Permissão de administrador revogada.' };
});
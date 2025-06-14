const functions = require("firebase-functions");
const admin = require("firebase-admin");

admin.initializeApp();
const db = admin.firestore();

// Define a região para todas as funções, garantindo consistência.
const regionalFunctions = functions.region("southamerica-east1");

/**
 * Busca dados de eventos. Se um eventId for fornecido, busca detalhes
 * completos do evento, incluindo fases e enigmas.
 *
 * CORREÇÃO: A busca de enigmas foi corrigida removendo .orderBy("id"),
 * que causava uma falha silenciosa e retornava uma lista vazia.
 */
exports.getEventData = regionalFunctions.https.onCall(async (data, context) => {
  const eventId = data ? data.eventId : null;

  if (!eventId) {
    const eventsSnapshot = await db.collection("events").get();
    return eventsSnapshot.docs.map((doc) => ({ id: doc.id, ...doc.data() }));
  } else {
    console.log(`INICIANDO busca para o evento ID: ${eventId}`);
    const eventDoc = await db.collection("events").doc(eventId).get();

    if (!eventDoc.exists) {
      console.error(`ERRO: Evento com ID: ${eventId} não foi encontrado.`);
      throw new functions.https.HttpsError("not-found", "Evento não encontrado.");
    }

    const eventData = { id: eventDoc.id, ...eventDoc.data() };
    console.log(`Dados do evento "${eventData.name}" carregados.`);

    const phasesSnapshot = await eventDoc.ref.collection("phases").orderBy("order").get();
    console.log(`Query para fases retornou ${phasesSnapshot.size} documentos.`);

    const phasesList = [];
    for (const phaseDoc of phasesSnapshot.docs) {
      try {
        const phaseId = phaseDoc.id;
        const phaseData = phaseDoc.data();
        console.log(`>> Processando Fase ID: ${phaseId}, Ordem: ${phaseData.order}`);

        // CORREÇÃO: A consulta agora é direta, sem .orderBy("id"), para funcionar corretamente.
        const enigmasSnapshot = await phaseDoc.ref.collection("enigmas").get();
        console.log(` -> Para a fase ${phaseId}, encontrados ${enigmasSnapshot.size} enigmas.`);

        const enigmas = enigmasSnapshot.docs.map((enigmaDoc) => ({
          id: enigmaDoc.id,
          ...enigmaDoc.data(),
        }));

        phasesList.push({ id: phaseId, ...phaseData, enigmas: enigmas });
      } catch (error) {
        console.error(`!!! ERRO CRÍTICO ao processar a fase ${phaseDoc.id}:`, error);
      }
    }

    eventData.phases = phasesList;
    console.log(`Processamento de fases concluído. Retornando ${phasesList.length} fases para o cliente.`);
    return eventData;
  }
});


/**
 * Lida com todas as ações do jogador relacionadas a um enigma.
 *
 * CORREÇÃO: A lógica de escrita foi refatorada para usar um padrão de
 * "ler-modificar-escrever", garantindo que o progresso do jogador
 * (dicas, fase, outros eventos) não seja apagado acidentalmente.
 */
exports.handleEnigmaAction = regionalFunctions.https.onCall(async (data, context) => {
  if (!context.auth) {
    throw new functions.https.HttpsError("unauthenticated", "Requer autenticação.");
  }
  const { eventId, phaseOrder, enigmaId, action, code } = data;
  const userId = context.auth.uid;
  const playerRef = db.collection("players").doc(userId);

  // Lê os dados atuais do jogador uma única vez para evitar múltiplas leituras.
  const playerDoc = await playerRef.get();
  const playerData = playerDoc.data() || {};
  const allEventsProgress = playerData.events || {};
  const currentEventProgress = allEventsProgress[eventId] || {};

  // --- AÇÃO: Obter Status (dicas, bloqueio) ---
  if (action === "getStatus") {
    const attemptRef = playerRef.collection("eventAttempts").doc(enigmaId);
    const attemptDoc = await attemptRef.get();
    let cooldownUntil = null;
    if (attemptDoc.exists && attemptDoc.data().cooldownUntil?.toDate() > new Date()) {
      cooldownUntil = attemptDoc.data().cooldownUntil.toDate().toISOString();
    }
    return {
      isHintVisible: (currentEventProgress.hintsPurchased || []).includes(phaseOrder),
      canBuyHint: phaseOrder <= 5 && !(currentEventProgress.hintsPurchased || []).includes(phaseOrder),
      isBlocked: cooldownUntil != null,
      cooldownUntil: cooldownUntil,
    };
  }

  // --- AÇÃO: Comprar Dica ---
  if (action === "purchaseHint") {
    if (phaseOrder > 5) {
      throw new functions.https.HttpsError("failed-precondition", "Dicas não disponíveis para esta fase.");
    }
    const newProgress = {
      ...currentEventProgress,
      hintsPurchased: admin.firestore.FieldValue.arrayUnion(phaseOrder),
    };
    await playerRef.set({ events: { ...allEventsProgress, [eventId]: newProgress } }, { merge: true });
    return { success: true, message: "Dica comprada com sucesso!" };
  }

  // --- AÇÃO: Validar Código ---
  if (action === "validateCode") {
    if (!code) throw new functions.https.HttpsError("invalid-argument", "Código obrigatório.");

    const phaseSnapshot = await db.collection("events").doc(eventId).collection("phases").where("order", "==", phaseOrder).limit(1).get();
    if (phaseSnapshot.empty) { throw new functions.https.HttpsError("not-found", "Fase não encontrada."); }
    const phaseDoc = phaseSnapshot.docs[0];
    const enigmaDoc = await phaseDoc.ref.collection("enigmas").doc(enigmaId).get();
    if (!enigmaDoc.exists) { throw new functions.https.HttpsError("not-found", "Enigma não encontrado."); }

    if (enigmaDoc.data().code.toUpperCase() === code.toUpperCase()) {
      // Código correto: calcula a progressão
      const enigmasSnapshot = await phaseDoc.ref.collection("enigmas").get();
      const enigmas = enigmasSnapshot.docs.map((doc) => ({ id: doc.id, ...doc.data() }));
      const currentIndex = enigmas.findIndex((e) => e.id === enigmaId);

      let nextStep = { type: "phase_complete" };
      let nextEnigmaIndex = 1;
      let nextPhaseOrder = phaseOrder + 1;

      if (currentIndex < enigmas.length - 1) {
        nextStep = { type: "next_enigma", enigmaData: enigmas[currentIndex + 1] };
        nextEnigmaIndex = currentIndex + 2;
        nextPhaseOrder = phaseOrder;
      }

      const newProgress = {
        ...currentEventProgress,
        currentPhase: nextPhaseOrder,
        currentEnigma: nextEnigmaIndex,
      };
      await playerRef.set({ events: { ...allEventsProgress, [eventId]: newProgress } }, { merge: true });
      return { success: true, message: "Parabéns! Código correto.", nextStep };
    } else {
      // Código incorreto: lida com tentativas e bloqueio
      const attemptRef = playerRef.collection("eventAttempts").doc(enigmaId);
      const attemptDoc = await attemptRef.get();
      if (attemptDoc.exists && attemptDoc.data().cooldownUntil?.toDate() > new Date()) {
        return { success: false, message: "Aguarde o fim do tempo de espera." };
      }
      const attempts = (attemptDoc.data()?.attempts || 0) + 1;
      if (attempts >= 3) {
        const cooldownTime = new Date(Date.now() + 10 * 60 * 1000);
        await attemptRef.set({ attempts, cooldownUntil: admin.firestore.Timestamp.fromDate(cooldownTime) });
        return { success: false, message: "Tentativas esgotadas. Aguarde 10 minutos." };
      } else {
        await attemptRef.set({ attempts }, { merge: true });
        return { success: false, message: `Código incorreto. Você tem mais ${3 - attempts} tentativa(s).` };
      }
    }
  }

  throw new functions.https.HttpsError("unknown", "Ação desconhecida ou não implementada.");
});


/**
 * Busca o ranking de um evento específico.
 */
exports.getEventRanking = regionalFunctions.https.onCall(async (data, context) => {
    const { eventId } = data;
    if (!eventId) {
        throw new functions.https.HttpsError("invalid-argument", "O ID do evento é obrigatório.");
    }

    const phasesSnapshot = await db.collection("events").doc(eventId).collection("phases").get();
    const totalPhases = phasesSnapshot.docs.length;
    if (totalPhases === 0) return [];

    const playersSnapshot = await db.collection("players").get();
    let rankedPlayers = [];

    for (const playerDoc of playersSnapshot.docs) {
        const playerData = playerDoc.data();
        const progress = playerData.events?.[eventId];
        const phasesCompleted = progress ? (progress.currentPhase || 1) - 1 : 0;

        rankedPlayers.push({
            uid: playerDoc.id,
            name: playerData.name || 'Anônimo',
            photoURL: playerData.photoURL || null,
            phasesCompleted: phasesCompleted,
            totalPhases: totalPhases,
        });
    }

    rankedPlayers.sort((a, b) => b.phasesCompleted - a.phasesCompleted);
    return rankedPlayers.map((player, index) => ({ ...player, position: index + 1 }));
});
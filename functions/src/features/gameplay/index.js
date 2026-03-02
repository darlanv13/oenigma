const {HttpsError, onCall} = require("firebase-functions/v2/https");
const admin = require("firebase-admin");

// Esta linha é essencial e deve estar no topo do arquivo.
const db = admin.firestore();

// =================================================================== //
// FUNÇÃO: handleEnigmaAction (CORRIGIDA)
// DESCRIÇÃO: Processa ações do enigma com a lógica de busca de fase corrigida.
// =================================================================== //
// =================================================================== //
// FUNÇÃO UNIFICADA: handleEnigmaAction
// DESCRIÇÃO: Processa ações para AMBOS os modos de jogo, 'classic' e 'find_and_win'.
// =================================================================== //
exports.handleEnigmaAction = onCall({enforceAppCheck: false}, async (request) => {
  const playerId = request.auth.uid;
  const {eventId, enigmaId, code, action, phaseOrder} = request.data;
  const playerRef = db.collection("players").doc(playerId);
  const eventRef = db.collection("events").doc(eventId);

  const eventDoc = await eventRef.get();
  if (!eventDoc.exists) throw new HttpsError("not-found", "Evento não encontrado.");
  const eventType = eventDoc.data().eventType || "classic";

  // ==========================================================
  // --- LÓGICA ATUALIZADA PARA O MODO: FIND & WIN ---
  // ==========================================================
  if (eventType === "find_and_win") {
    if (!enigmaId || !code) {
      throw new HttpsError("invalid-argument", "Dados insuficientes para este modo de jogo.");
    }

    const enigmaRef = eventRef.collection("enigmas").doc(enigmaId);
    const currentEnigmaDoc = await enigmaRef.get();
    if (!currentEnigmaDoc.exists) throw new HttpsError("not-found", "Enigma não encontrado.");
    if (currentEnigmaDoc.data().status === "closed") throw new HttpsError("failed-precondition", "Este enigma já foi resolvido!");

    const attemptRef = playerRef.collection("eventAttempts").doc(enigmaId);
    const attemptDoc = await attemptRef.get();
    if (attemptDoc.exists && attemptDoc.data().cooldownUntil?.toDate() > new Date()) {
      return {success: false, message: "Aguarde o fim do tempo de espera.", cooldownUntil: attemptDoc.data().cooldownUntil.toDate().toISOString()};
    }

    if (currentEnigmaDoc.data().code.toUpperCase() !== code.toUpperCase()) {
      const attempts = (attemptDoc.data()?.attempts || 0) + 1;
      if (attempts >= 3) {
        const cooldownTime = new Date(Date.now() + 10 * 60 * 1000);
        await attemptRef.set({attempts, cooldownUntil: admin.firestore.Timestamp.fromDate(cooldownTime)});
        return {success: false, message: "Tentativas esgotadas. Aguarde 10 minutos.", cooldownUntil: cooldownTime.toISOString()};
      } else {
        await attemptRef.set({attempts}, {merge: true});
        return {success: false, message: `Código incorreto. Você tem mais ${3 - attempts} tentativa(s).`};
      }
    }

    await attemptRef.delete().catch(() => { });

    try {
      await db.runTransaction(async (transaction) => {
        const playerDoc = await transaction.get(playerRef);
        const enigmaToSolve = await transaction.get(enigmaRef);
        if (enigmaToSolve.data().status === "closed") throw new HttpsError("aborted", "Outro jogador resolveu este enigma primeiro.");

        const prize = enigmaToSolve.data().prize || 0;
        const newBalance = (playerDoc.data().balance || 0) + prize;

        transaction.update(playerRef, {balance: newBalance});
        transaction.update(enigmaRef, {status: "closed", winnerId: playerId, winnerName: playerDoc.data().name, winnerPhotoURL: playerDoc.data().photoURL});
      });

      // --- LÓGICA DE SELEÇÃO ALEATÓRIA ---
      // Busca TODOS os enigmas que ainda estão abertos.
      const remainingEnigmasQuery = await eventRef.collection("enigmas").where("status", "==", "open").get();

      let nextEnigmaId = null;
      if (!remainingEnigmasQuery.empty) {
        // Se houver enigmas restantes, escolhe um aleatoriamente.
        const remainingEnigmas = remainingEnigmasQuery.docs;
        const randomIndex = Math.floor(Math.random() * remainingEnigmas.length);
        nextEnigmaId = remainingEnigmas[randomIndex].id;
      }

      // Atualiza o evento com o próximo enigma (ou nulo se não houver mais).
      await eventRef.update({currentEnigmaId: nextEnigmaId});

      const prizeValue = currentEnigmaDoc.data().prize || 0;
      return {success: true, message: `Parabéns! Você ganhou R$ ${prizeValue.toFixed(2)}!`};
    } catch (error) {
      console.error("Erro na transação Find & Win:", error);
      if (error instanceof HttpsError) throw error;
      throw new HttpsError("internal", "Não foi possível processar sua resposta.");
    }
  } else {
    // --- CORREÇÃO PRINCIPAL: BUSCA A FASE PELO CAMPO 'order' ---
    const getPhaseDocRefByOrder = async (order) => {
      const phasesQuery = await eventRef.collection("phases").where("order", "==", order).limit(1).get();
      if (phasesQuery.empty) {
        throw new HttpsError("not-found", `A fase de ordem ${order} não foi encontrada para este evento.`);
      }
      return phasesQuery.docs[0].ref;
    };

    if (action === "getStatus") {
      const playerDoc = await playerRef.get();
      const playerData = playerDoc.data() || {};
      const eventProgress = {currentPhase: 1, currentEnigma: 1, ...(playerData.events || {})[eventId]};
      const hintsPurchased = eventProgress.hintsPurchased || [];
      const attemptRef = playerRef.collection("eventAttempts").doc(enigmaId);
      const attemptDoc = await attemptRef.get();
      let cooldownUntil = null;
      let isBlocked = false;
      if (attemptDoc.exists && attemptDoc.data().cooldownUntil?.toDate() > new Date()) {
        cooldownUntil = attemptDoc.data().cooldownUntil.toDate().toISOString();
        isBlocked = true;
      }
      return {
        isHintVisible: hintsPurchased.includes(phaseOrder),
        canBuyHint: phaseOrder < 4 && !hintsPurchased.includes(phaseOrder),
        isBlocked: isBlocked,
        cooldownUntil: cooldownUntil,
      };
    }

    // --- Ação: purchaseHint ---
    if (action === "purchaseHint") {
      const hintCosts = {1: 5, 2: 10, 3: 15};
      const hintCost = hintCosts[phaseOrder] || 5;

      try {
        const phaseDocRef = await getPhaseDocRefByOrder(phaseOrder);
        const enigmaDocRef = phaseDocRef.collection("enigmas").doc(enigmaId);

        return await db.runTransaction(async (transaction) => {
          const playerDoc = await transaction.get(playerRef);
          const enigmaDoc = await transaction.get(enigmaDocRef);

          if (!playerDoc.exists) throw new HttpsError("not-found", "Jogador não encontrado.");
          if (!enigmaDoc.exists) throw new HttpsError("not-found", "Enigma não encontrado.");

          const playerData = playerDoc.data();
          const enigmaData = enigmaDoc.data();

          if (enigmaData.allowHints === false) {
            throw new HttpsError("failed-precondition", "Dicas estão desativadas para este enigma.");
          }

          // Fetch linked hints instead of the hardcoded old ones
          let randomHintData = null;
          const linkedHints = enigmaData.linkedHints || [];

          if (linkedHints.length > 0) {
            const randomHintId = linkedHints[Math.floor(Math.random() * linkedHints.length)];
            const hintDoc = await transaction.get(db.collection("hints_pool").doc(randomHintId));
            if (hintDoc.exists) {
              randomHintData = hintDoc.data();
            }
          }

          // Se a caixa de dicas estiver vazia, tenta cair na dica hardcoded se existir (para retrocompatibilidade)
          const legacyHintType = enigmaData.hintType;
          const legacyHintData = enigmaData.hintData;

          if (!randomHintData && (!legacyHintType || !legacyHintData)) {
            throw new HttpsError("not-found", "Nenhuma dica disponível ou caixa de dicas vazia.");
          }

          const currentBalance = playerData.balance || 0;
          if (currentBalance < hintCost) throw new HttpsError("failed-precondition", "Saldo insuficiente.");

          // Check if already purchased
          const hintsPurchased = (playerData.events?.[eventId]?.hintsPurchased) || [];
          if (hintsPurchased.includes(phaseOrder)) {
            throw new HttpsError("already-exists", "Você já comprou a dica para esta fase.");
          }

          const finalHintType = randomHintData ? randomHintData.type : legacyHintType;
          const finalHintContent = randomHintData ? randomHintData.content : legacyHintData;

          const newBalance = currentBalance - hintCost;
          const newProgress = {
            ...playerData.events?.[eventId],
            hintsPurchased: admin.firestore.FieldValue.arrayUnion(phaseOrder),
            // Salvamos a dica sorteada para o jogador não perder se fechar o app
            [`hint_${phaseOrder}`]: { type: finalHintType, data: finalHintContent }
          };

          transaction.update(playerRef, {
            balance: newBalance,
            [`events.${eventId}`]: newProgress,
          });

          return {
            success: true,
            message: "Dica comprada com sucesso!",
            hint: { type: finalHintType, data: finalHintContent },
          };
        });
      } catch (error) {
        if (error instanceof HttpsError) throw error;
        console.error("Erro na transação de compra de dica:", error);
        throw new HttpsError("internal", "Ocorreu um erro ao processar a sua compra.");
      }
    }

    if (action === "validateCode") {
      const eventDoc = await eventRef.get();
      if (!eventDoc.exists || eventDoc.data().status !== "open") {
        throw new HttpsError("failed-precondition", "Este evento não está mais ativo.");
      }
      if (!code) {
        throw new HttpsError("invalid-argument", "O código é obrigatório.");
      }

      // Usa a busca correta pela fase
      const phaseDocRef = await getPhaseDocRefByOrder(phaseOrder);
      const enigmaDocRef = phaseDocRef.collection("enigmas").doc(enigmaId);

      const attemptRef = playerRef.collection("eventAttempts").doc(enigmaId);
      const attemptDoc = await attemptRef.get();
      if (attemptDoc.exists && attemptDoc.data().cooldownUntil?.toDate() > new Date()) {
        return {success: false, message: "Aguarde o fim do tempo de espera.", cooldownUntil: attemptDoc.data().cooldownUntil.toDate().toISOString()};
      }

      const enigmaDoc = await enigmaDocRef.get();
      if (!enigmaDoc.exists) {
        // Este é o erro que você estava recebendo. Agora será resolvido.
        throw new HttpsError("not-found", "Enigma não encontrado.");
      }

      if (enigmaDoc.data().code.toUpperCase() !== code.toUpperCase()) {
        const attempts = (attemptDoc.data()?.attempts || 0) + 1;
        if (attempts >= 3) {
          const cooldownTime = new Date(Date.now() + 10 * 60 * 1000);
          await attemptRef.set({attempts, cooldownUntil: admin.firestore.Timestamp.fromDate(cooldownTime)});
          return {success: false, message: "Tentativas esgotadas. Aguarde 10 minutos.", cooldownUntil: cooldownTime.toISOString()};
        } else {
          await attemptRef.set({attempts}, {merge: true});
          return {success: false, message: `Código incorreto. Você tem mais ${3 - attempts} tentativa(s).`};
        }
      }

      await attemptRef.delete().catch(() => { });

      let nextStepForClient = null;
      let isEventFinishedByThisPlayer = false;

      // Função auxiliar para converter o prêmio de string para número
      const parsePrizeValue = (prizeString) => {
        if (!prizeString || typeof prizeString !== "string") return 0;
        const numberString = prizeString.replace(/[^0-9,.]/g, "").replace(",", ".");
        return parseFloat(numberString) || 0;
      };

      try {
        await db.runTransaction(async (transaction) => {
          const playerDoc = await transaction.get(playerRef);
          const playerData = playerDoc.data();
          const eventDoc = await transaction.get(eventRef);
          const eventData = eventDoc.data(); // <- E os dados do evento aqui
          const playerEvents = playerData.events || {};
          const eventProgress = {currentPhase: 1, currentEnigma: 1, ...playerEvents[eventId]};

          if (phaseOrder !== eventProgress.currentPhase) {
            throw new HttpsError("failed-precondition", "Você está tentando resolver um enigma de uma fase que não é a sua fase atual.");
          }

          const phasesSnapshot = await transaction.get(eventRef.collection("phases"));
          const totalPhases = phasesSnapshot.size;
          const enigmasInPhaseSnapshot = await transaction.get(phaseDocRef.collection("enigmas").orderBy(admin.firestore.FieldPath.documentId()));
          const enigmasInCurrentPhase = enigmasInPhaseSnapshot.size;
          const isLastEnigma = eventProgress.currentEnigma >= enigmasInCurrentPhase;
          const isLastPhase = eventProgress.currentPhase >= totalPhases;
          if (isLastEnigma && isLastPhase) {
            isEventFinishedByThisPlayer = true;

            // --- MUDANÇA 1: Adicionar prêmio ao saldo ---
            const prizeValue = parsePrizeValue(eventData.prize);
            const currentBalance = playerData.balance || 0;
            const newBalance = currentBalance + prizeValue;

            transaction.update(playerRef, {balance: newBalance}); // Atualiza o saldo

            transaction.update(eventRef, {
              status: "closed",
              winnerId: playerId,
              winnerName: playerData.name || "Anônimo",
              winnerPhotoURL: playerData.photoURL || null, // <- Adicionamos a foto
              finishedAt: admin.firestore.FieldValue.serverTimestamp(),
            });

            // --- MUDANÇA 2: Enviar dados do prêmio para o cliente ---
            nextStepForClient = {
              type: "event_complete",
              prizeWon: prizeValue, // <- Enviamos o valor do prêmio
            };
          } else if (isLastEnigma) {
            eventProgress.currentPhase += 1;
            eventProgress.currentEnigma = 1;
            nextStepForClient = {type: "phase_complete"};
          } else {
            eventProgress.currentEnigma += 1;
            const enigmaDocs = enigmasInPhaseSnapshot.docs;
            const nextEnigmaDoc = enigmaDocs[eventProgress.currentEnigma - 1];
            nextStepForClient = {type: "next_enigma", enigmaData: {id: nextEnigmaDoc.id, ...nextEnigmaDoc.data()}};
          }

          const newPlayerEvents = {...playerEvents, [eventId]: eventProgress};
          transaction.update(playerRef, {events: newPlayerEvents});
        });
      } catch (error) {
        if (error instanceof HttpsError) throw error;
        throw new HttpsError("internal", "Erro ao processar sua resposta.", error.message);
      }

      if (isEventFinishedByThisPlayer) {
        const eventData = (await eventRef.get()).data();
        const playerData = (await playerRef.get()).data();
        await sendCompletionNotifications(eventId, eventData.name, playerId, playerData.name);
      }

      return {success: true, message: "Parabéns!", nextStep: nextStepForClient};
    }

    throw new HttpsError("invalid-argument", "Ação não suportada.");
  }
});

async function sendCompletionNotifications(eventId, eventName, winnerId, winnerName) {
  const allPlayersSnap = await db.collection("players").get();
  const tokens = [];
  allPlayersSnap.forEach((doc) => {
    const player = doc.data();
    if (doc.id !== winnerId && player.events?.[eventId] && player.fcmToken) {
      tokens.push(player.fcmToken);
    }
  });

  if (tokens.length > 0) {
    const payload = {
      notification: {
        title: `O evento "${eventName}" foi finalizado!`,
        body: `${winnerName} é o grande vencedor! Confira o ranking.`,
        sound: "default",
      },
      data: {
        type: "event_finished",
        eventId: eventId,
      },
    };
    await admin.messaging().sendToDevice(tokens, payload);
  }
}


// =================================================================== //
// NOVA FUNÇÃO: subscribeToEvent
// =================================================================== //
exports.subscribeToEvent = onCall(async (request) => {
  const userId = request.auth.uid;
  if (!userId) {
    throw new HttpsError("unauthenticated", "Usuário não autenticado.");
  }
  const {eventId} = request.data;
  if (!eventId) {
    throw new HttpsError("invalid-argument", "O ID do evento é obrigatório.");
  }

  const playerRef = db.collection("players").doc(userId);
  const eventRef = db.collection("events").doc(eventId);

  try {
    await db.runTransaction(async (transaction) => {
      const playerDoc = await transaction.get(playerRef);
      const eventDoc = await transaction.get(eventRef);

      if (!playerDoc.exists) {
        throw new HttpsError("not-found", "Jogador não encontrado.");
      }
      if (!eventDoc.exists) {
        throw new HttpsError("not-found", "Evento não encontrado.");
      }

      const playerData = playerDoc.data();
      const eventData = eventDoc.data();
      const price = eventData.price || 0;
      const balance = playerData.balance || 0;

      if (playerData.events && playerData.events[eventId]) {
        throw new HttpsError("already-exists", "Você já está inscrito neste evento.");
      }

      if (balance < price) {
        throw new HttpsError("failed-precondition", "Saldo insuficiente.");
      }

      const newBalance = balance - price;
      const newPlayerEvents = {
        ...playerData.events,
        [eventId]: {
          currentPhase: 1,
          currentEnigma: 1,
          hintsPurchased: [],
        },
      };

      transaction.update(playerRef, {
        balance: newBalance,
        events: newPlayerEvents,
      });
    });

    return {success: true, message: "Inscrição realizada com sucesso!"};
  } catch (error) {
    if (error instanceof HttpsError) {
      throw error;
    }
    console.error("Erro na transação de inscrição:", error);
    throw new HttpsError("internal", "Não foi possível concluir a inscrição.");
  }
});

// =================================================================== //
// NOVA FUNÇÃO: purchaseTool
// DESCRIÇÃO: Permite ao jogador comprar Mapa ou Bússola.
// =================================================================== //
exports.purchaseTool = onCall(async (request) => {
  const userId = request.auth?.uid;
  if (!userId) throw new HttpsError("unauthenticated", "Usuário não autenticado.");

  const { eventId, enigmaId, toolType } = request.data;
  if (!eventId || !enigmaId || !toolType) {
    throw new HttpsError("invalid-argument", "Dados incompletos.");
  }

  const toolCosts = { compass: 15, map: 20 };
  const cost = toolCosts[toolType];
  if (!cost) throw new HttpsError("invalid-argument", "Tipo de ferramenta inválido.");

  const playerRef = db.collection("players").doc(userId);
  const eventRef = db.collection("events").doc(eventId);

  return await db.runTransaction(async (t) => {
    const playerDoc = await t.get(playerRef);
    if (!playerDoc.exists) throw new HttpsError("not-found", "Jogador não encontrado.");

    const balance = playerDoc.data().balance || 0;
    if (balance < cost) throw new HttpsError("failed-precondition", "Saldo insuficiente.");

    const eventDoc = await t.get(eventRef);
    if (!eventDoc.exists) throw new HttpsError("not-found", "Evento não encontrado.");

    // Localizar o enigma (para eventos clássicos ou find_and_win)
    // Para simplificar, consideramos find_and_win (sem fase) ou clássico com pesquisa ampla
    let destinationLocation = null;
    if (eventDoc.data().eventType === "find_and_win") {
      const enigmaDoc = await t.get(eventRef.collection("enigmas").doc(enigmaId));
      if (enigmaDoc.exists) destinationLocation = enigmaDoc.data().location;
    } else {
      // Busca simplificada (em produção, o phaseId deveria ser passado)
      // Aqui assumimos que o client fará o merge se necessário
    }

    t.update(playerRef, {
      balance: admin.firestore.FieldValue.increment(-cost),
      [`events.${eventId}.tools.${toolType}`]: true
    });

    return {
      success: true,
      message: `${toolType} comprada com sucesso!`,
      destinationLocation: destinationLocation
    };
  });
});

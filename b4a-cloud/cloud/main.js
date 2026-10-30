// Parse Cloud Code for Back4App
// Write your cloud functions here.

require('./admin.js');

// -----------------------------------------------------------------------------
// App / Home Functions
// -----------------------------------------------------------------------------
Parse.Cloud.define("getHomeScreenData", async (request) => {
  try {
    const user = request.user;

    const Banner = Parse.Object.extend("Banner");
    const bannerQuery = new Parse.Query(Banner);
    const banners = await bannerQuery.find({ useMasterKey: true });

    const Event = Parse.Object.extend("Event");
    const eventQuery = new Parse.Query(Event);
    eventQuery.equalTo("status", "open");
    const events = await eventQuery.find({ useMasterKey: true });

    const formattedEvents = events.map(e => {
      const json = e.toJSON();
      json.id = e.id;
      if (json.startDate && json.startDate.iso) {
        json.startDate = json.startDate.iso;
      }
      return json;
    });

    let walletData = {};
    let playerData = {};

    if (user) {
      walletData = {
        objectId: user.id,
        name: user.get("name") || user.get("username") || "Jogador",
        email: user.get("email") || "",
        balance: user.get("balance") || 0.0,
        photoURL: user.get("photoURL") || null,
        lastWonEventName: user.get("lastWonEventName"),
        lastEventRank: user.get("lastEventRank"),
        lastEventName: user.get("lastEventName")
      };
      playerData = {
        events: user.get("events") || {},
        winnerEvents: user.get("winnerEvents") || [],
        name: user.get("name") || user.get("username") || "Jogador",
        email: user.get("email") || "",
        cpf: user.get("cpf") || "",
        phone: user.get("phone") || "",
        birthDate: user.get("birthDate") || "",
        photoURL: user.get("photoURL") || null
      };
    } else {
      walletData = {
        objectId: "visitante",
        name: "Visitante",
        email: "sem_email@teste.com",
        balance: 0.0,
        photoURL: null
      };
    }

    const userQuery = new Parse.Query(Parse.User);
    userQuery.descending("balance");
    userQuery.limit(5);
    const topPlayers = await userQuery.find({ useMasterKey: true });

    const allPlayers = topPlayers.map(p => ({
      objectId: p.id,
      name: p.get("name") || p.get("username") || "Jogador",
      balance: p.get("balance") || 0.0
    }));

    return {
      banners: banners.map(b => b.toJSON()),
      events: formattedEvents,
      walletData: walletData,
      playerData: playerData,
      allPlayers: allPlayers
    };

  } catch (error) {
    throw new Parse.Error(Parse.Error.INTERNAL_SERVER_ERROR, "Erro ao buscar dados da home: " + error.message);
  }
});

Parse.Cloud.define("createPixCharge", async (request) => {
  const { amount } = request.params;
  const user = request.user;

  if (!amount || typeof amount !== 'number') {
    throw new Parse.Error(Parse.Error.INVALID_QUERY, "amount is required and must be a number.");
  }
  
  if (!user) {
    throw new Parse.Error(209, "Acesso negado.");
  }

  try {
    // Obtém gateway ativo configurado no painel admin
    const qGateway = new Parse.Query("GatewayConfig");
    qGateway.equalTo("isActive", true);
    qGateway.equalTo("isDefault", true);
    const activeGateway = await qGateway.first({ useMasterKey: true });
    const gatewayId = activeGateway ? activeGateway.get("gatewayId") : "mercadopago";

    const Transaction = Parse.Object.extend("Transaction");
    const transaction = new Transaction();
    transaction.set("type", "deposit");
    transaction.set("amount", amount);
    transaction.set("status", "pending");
    transaction.set("user", user);
    transaction.set("gateway", gatewayId);

    const acl = new Parse.ACL();
    acl.setReadAccess(user.id, true);
    acl.setWriteAccess(user.id, false);
    acl.setPublicReadAccess(false);
    acl.setPublicWriteAccess(false);
    transaction.setACL(acl);

    await transaction.save(null, { useMasterKey: true });

    return {
      success: true,
      qrCode: "00020101021243650016COM.MERCADOLIBRE0114...",
      qrCodeBase64: "iVBORw0KGgoAAAANSUhEUgAAA...",
      transactionId: transaction.id
    };
  } catch (error) {
    throw new Parse.Error(Parse.Error.INTERNAL_SERVER_ERROR, "Error creating Pix charge: " + error.message);
  }
});

// -----------------------------------------------------------------------------
// Missing Frontend Functions
// -----------------------------------------------------------------------------

Parse.Cloud.define("getUserWalletData", async (request) => {
  const user = request.user;
  if (!user) {
    throw new Parse.Error(Parse.Error.INVALID_SESSION_TOKEN, "User not authenticated.");
  }
  return {
    objectId: user.id,
    name: user.get("name") || user.get("username") || "Jogador",
    email: user.get("email") || "",
    balance: user.get("balance") || 0.0,
    photoURL: user.get("photoURL") || null,
    lastWonEventName: user.get("lastWonEventName"),
    lastEventRank: user.get("lastEventRank"),
    lastEventName: user.get("lastEventName")
  };
});

Parse.Cloud.define("subscribeToEvent", async (request) => {
  const { eventId } = request.params;
  const user = request.user;
  if (!user) throw new Parse.Error(Parse.Error.INVALID_SESSION_TOKEN, "User not authenticated.");
  if (!eventId) throw new Parse.Error(Parse.Error.INVALID_QUERY, "eventId is required.");

  try {
    const Event = Parse.Object.extend("Event");
    const query = new Parse.Query(Event);
    const event = await query.get(eventId, { useMasterKey: true });

    let userEvents = user.get("events") || {};
    userEvents[eventId] = { currentPhase: 1, currentEnigma: 1, hintsPurchased: [] };
    user.set("events", userEvents);

    await user.save(null, { useMasterKey: true });

    event.increment("playerCount");
    await event.save(null, { useMasterKey: true });

    return { success: true };
  } catch (error) {
    throw new Parse.Error(Parse.Error.INTERNAL_SERVER_ERROR, error.message);
  }
});

Parse.Cloud.define("getEventData", async (request) => {
  const { eventId } = request.params;
  if (!eventId) throw new Parse.Error(Parse.Error.INVALID_QUERY, "eventId is required.");

  try {
    const Event = Parse.Object.extend("Event");
    const query = new Parse.Query(Event);
    const event = await query.get(eventId, { useMasterKey: true });

    const eventJson = event.toJSON();
    eventJson.id = event.id;
    if (eventJson.startDate && eventJson.startDate.iso) {
      eventJson.startDate = eventJson.startDate.iso;
    }

    const eventType = event.get("eventType") || 'classic';

    // Fetch phases for event
    const Phase = Parse.Object.extend("Phase");
    const phaseQuery = new Parse.Query(Phase);
    const eventPointer = new Event();
    eventPointer.id = eventId;
    phaseQuery.equalTo("event", eventPointer);
    phaseQuery.ascending("order");
    const phases = await phaseQuery.find({ useMasterKey: true });

    // Fetch enigmas for event
    const Enigma = Parse.Object.extend("Enigma");
    const enigmaQuery = new Parse.Query(Enigma);
    enigmaQuery.equalTo("event", eventPointer);
    enigmaQuery.ascending("order");
    const enigmas = await enigmaQuery.find({ useMasterKey: true });

    // Map enigmas to phases (if any) or to event level list
    let enigmasJson = enigmas.map(e => {
      const json = e.toJSON();
      json.id = e.id;
      
      // Blindagem de Payload
      delete json.code; 
      delete json.compassCoords; 
      delete json.createdAt;
      delete json.updatedAt;

      if (eventType === 'classic') {
        json.prize = 0.0;
      }

      return json;
    });

    let phasesJson = phases.map(p => {
      const json = p.toJSON();
      json.id = p.id;
      json.enigmas = enigmasJson.filter(e => {
        return e.phaseId === p.id || (e.phase && (e.phase.objectId === p.id || e.phase.id === p.id));
      });
      return json;
    });

    eventJson.phases = phasesJson;
    eventJson.enigmas = enigmasJson;

    return eventJson;
  } catch (error) {
    throw new Parse.Error(Parse.Error.INTERNAL_SERVER_ERROR, error.message);
  }
});

Parse.Cloud.define("getSafeEnigmaData", async (request) => {
  const { enigmaId } = request.params;
  const user = request.user;

  if (!user) throw new Parse.Error(209, "Acesso negado.");
  if (!enigmaId) throw new Parse.Error(Parse.Error.INVALID_QUERY, "enigmaId is required.");

  try {
    const query = new Parse.Query("Enigma");
    const enigma = await query.get(enigmaId, { useMasterKey: true });

    const safePayload = enigma.toJSON();
    safePayload.id = enigma.id;

    delete safePayload.code; 
    delete safePayload.compassCoords; 
    delete safePayload.createdAt;
    delete safePayload.updatedAt;

    return safePayload;
  } catch (error) {
    throw new Parse.Error(Parse.Error.INTERNAL_SERVER_ERROR, "Erro ao buscar enigma seguro: " + error.message);
  }
});

function getLeagueByXP(xp) {
  if (xp >= 6001) return 'Lenda';
  if (xp >= 3001) return 'Diamante';
  if (xp >= 1501) return 'Ouro';
  if (xp >= 501) return 'Prata';
  return 'Bronze';
}

Parse.Cloud.define("handleEnigmaAction", async (request) => {
  const { action, eventId, phaseOrder, enigmaId, answer, code, toolType } = request.params;
  const user = request.user;
  if (!user) throw new Parse.Error(Parse.Error.INVALID_SESSION_TOKEN, "User not authenticated.");
  if (!action) throw new Parse.Error(Parse.Error.INVALID_QUERY, "action is required.");

  try {
    let userEvents = user.get("events") || {};
    let eventProgress = userEvents[eventId] || {};
    let hintsPurchased = eventProgress.hintsPurchased || [];
    let toolsPurchased = eventProgress.toolsPurchased || [];
    let balance = user.get("balance") || 0.0;

    const now = new Date().getTime();
    if (eventProgress.cooldownUntil && eventProgress.cooldownUntil > now && action !== 'getStatus') {
      return { success: false, message: "Aguarde o Cooldown", cooldownUntil: eventProgress.cooldownUntil };
    }

    if (action === 'getStatus') {
      let isHintVisible = false;
      let hintData = null;
      let canBuyHint = false;
      let isBlocked = false;
      let hasCompass = false;
      let hasMap = false;
      let hasRadar = false;
      let destinationLocation = null;

      const Enigma = Parse.Object.extend("Enigma");
      const query = new Parse.Query(Enigma);
      const enigma = await query.get(enigmaId, { useMasterKey: true });

      if (enigma) {
        let linkedHints = enigma.get("linkedHints") || [];
        canBuyHint = linkedHints.length > 0 && !hintsPurchased.includes(enigmaId);

        if (hintsPurchased.includes(enigmaId) && linkedHints.length > 0) {
          isHintVisible = true;
          const Hint = Parse.Object.extend("Hint");
          const hintQuery = new Parse.Query(Hint);
          const hintObj = await hintQuery.get(linkedHints[0], { useMasterKey: true });
          if (hintObj) {
            hintData = {
              type: hintObj.get("type"),
              data: hintObj.get("data")
            };
          }
        }

        hasCompass = toolsPurchased.includes("compass");
        hasMap = toolsPurchased.includes("map");
        hasRadar = toolsPurchased.includes("radar");

        let compassStr = enigma.get("compassCoords");
        if (compassStr) {
          let parts = compassStr.split(",");
          if (parts.length === 2) {
            destinationLocation = {
              latitude: parseFloat(parts[0].trim()),
              longitude: parseFloat(parts[1].trim())
            };
          }
        } else {
          let loc = enigma.get("location");
          if (loc && loc.latitude && loc.longitude) {
            destinationLocation = {
              latitude: loc.latitude,
              longitude: loc.longitude
            };
          }
        }

        if (eventProgress.cooldownUntil && eventProgress.cooldownUntil > now) {
          isBlocked = true;
        }
      }

      return {
        success: true,
        currentPhase: eventProgress.currentPhase || 1,
        currentEnigma: eventProgress.currentEnigma || 1,
        hintsPurchased: hintsPurchased,
        toolsPurchased: toolsPurchased,
        cooldownUntil: eventProgress.cooldownUntil || null,
        isHintVisible: isHintVisible,
        hintData: hintData,
        canBuyHint: canBuyHint,
        isBlocked: isBlocked,
        hasCompass: hasCompass,
        hasMap: hasMap,
        hasRadar: hasRadar,
        destinationLocation: destinationLocation,
        compassDuration: enigma ? (enigma.get("compassDuration") || 0) : 0,
        compassPrice: enigma ? (enigma.get("compassPrice") || 15.0) : 15.0,
        radarPrice: enigma ? (enigma.get("radarPrice") || 10.0) : 10.0
      };
    } else if (action === 'purchaseHint') {
      const pOrder = phaseOrder || eventProgress.currentPhase || 1;
      const cost = pOrder * 5.0; 

      if (balance < cost) {
        throw new Parse.Error(Parse.Error.SCRIPT_FAILED, "Saldo insuficiente para comprar a dica.");
      }

      const Enigma = Parse.Object.extend("Enigma");
      const query = new Parse.Query(Enigma);
      const enigma = await query.get(enigmaId, { useMasterKey: true });

      let linkedHints = enigma ? (enigma.get("linkedHints") || []) : [];
      if (linkedHints.length === 0) {
        throw new Parse.Error(Parse.Error.SCRIPT_FAILED, "Não há dicas disponíveis para este enigma.");
      }

      const Hint = Parse.Object.extend("Hint");
      const hintQuery = new Parse.Query(Hint);
      const randomIndex = Math.floor(Math.random() * linkedHints.length);
      const randomHintId = linkedHints[randomIndex];
      const hintObj = await hintQuery.get(randomHintId, { useMasterKey: true });

      if (!hintObj) {
        throw new Parse.Error(Parse.Error.SCRIPT_FAILED, "Dica não encontrada.");
      }

      user.set("balance", balance - cost);

      const hint = {
        type: hintObj.get("type"),
        data: hintObj.get("data")
      };

      hintsPurchased.push(enigmaId);
      eventProgress.hintsPurchased = hintsPurchased;
      userEvents[eventId] = eventProgress;
      user.set("events", userEvents);
      await user.save(null, { useMasterKey: true });

      return { success: true, hint: hint, message: "Dica comprada com sucesso." };

    } else if (action === 'consumeTool') {
      if (!toolType) throw new Parse.Error(Parse.Error.INVALID_QUERY, "toolType is required.");

      const index = toolsPurchased.indexOf(toolType);
      if (index > -1) {
        toolsPurchased.splice(index, 1);
        eventProgress.toolsPurchased = toolsPurchased;
        userEvents[eventId] = eventProgress;
        user.set("events", userEvents);
        await user.save(null, { useMasterKey: true });
      }

      return { success: true, message: "Ferramenta consumida." };

    } else if (action === 'purchaseTool') {
      let enigma = null;
      if (enigmaId) {
        const Enigma = Parse.Object.extend("Enigma");
        const query = new Parse.Query(Enigma);
        enigma = await query.get(enigmaId, { useMasterKey: true });
      }

      let cost = 0;
      if (toolType === 'map') cost = enigma ? (enigma.get("mapPrice") || 20.0) : 20.0;
      else if (toolType === 'compass') {
         cost = enigma ? (enigma.get("compassPrice") || 15.0) : 15.0;
      } else if (toolType === 'radar') {
         cost = enigma ? (enigma.get("radarPrice") || 10.0) : 10.0;
      }
      else throw new Parse.Error(Parse.Error.INVALID_QUERY, "Invalid tool type.");

      if (balance < cost) {
        throw new Parse.Error(Parse.Error.SCRIPT_FAILED, "Saldo insuficiente para comprar a ferramenta.");
      }

      user.set("balance", balance - cost);

      toolsPurchased.push(toolType);
      eventProgress.toolsPurchased = toolsPurchased;
      userEvents[eventId] = eventProgress;
      user.set("events", userEvents);
      await user.save(null, { useMasterKey: true });

      return { success: true, message: "Ferramenta comprada com sucesso." };

    } else if (action === 'validateCode' || action === 'verify_code' || action === 'scan_enigma') {
      const { latitude, longitude } = request.params;
      const guess = code || answer;
      
      const Enigma = Parse.Object.extend("Enigma");
      const query = new Parse.Query(Enigma);
      const enigma = await query.get(enigmaId, { useMasterKey: true });

      if (latitude !== undefined && longitude !== undefined) {
        const userGeoPoint = new Parse.GeoPoint({ latitude: parseFloat(latitude), longitude: parseFloat(longitude) });
        const enigmaGeoPoint = enigma.get("location");
        
        if (enigmaGeoPoint) {
          const distanceToEnigma = userGeoPoint.kilometersTo(enigmaGeoPoint);
          if (distanceToEnigma > 0.15) {
            throw new Parse.Error(Parse.Error.SCRIPT_FAILED, "Você não está próximo o suficiente do alvo para validar este código.");
          }
        }

        const lastLoc = user.get("lastLocation");
        const lastTime = user.get("lastLocationTime");
        const now = new Date();

        if (lastLoc && lastTime) {
          const distanceKm = lastLoc.kilometersTo(userGeoPoint);
          const timeDiffHours = (now.getTime() - lastTime.getTime()) / (1000 * 60 * 60);
          
          if (timeDiffHours > 0) {
            const speedKmH = distanceKm / timeDiffHours;
            if (speedKmH > 120) {
              const FraudLog = Parse.Object.extend("FraudLog");
              const fraud = new FraudLog();
              fraud.set("user", user);
              fraud.set("eventId", eventId);
              fraud.set("enigmaId", enigmaId);
              fraud.set("reason", "Impossible Travel Detectado");
              fraud.set("speedKmH", speedKmH);
              await fraud.save(null, { useMasterKey: true });

              throw new Parse.Error(Parse.Error.SCRIPT_FAILED, "Movimentação irreal detectada. Sua ação foi bloqueada pelo sistema Anti-Fraude.");
            }
          }
        }

        user.set("lastLocation", userGeoPoint);
        user.set("lastLocationTime", now);
        await user.save(null, { useMasterKey: true });
      }

      const rawEnigmaCode = enigma.get("code");
      const enigmaCode = String(rawEnigmaCode !== undefined && rawEnigmaCode !== null ? rawEnigmaCode : "").trim().toUpperCase();
      const userGuess = String(guess !== undefined && guess !== null ? guess : "").trim().toUpperCase();

      if (enigmaCode.length > 0 && enigmaCode === userGuess) {
        if (typeof rawEnigmaCode !== 'string') {
          enigma.set("code", enigmaCode);
          await enigma.save(null, { useMasterKey: true });
        }
        const Event = Parse.Object.extend("Event");
        const eventQuery = new Parse.Query(Event);
        const eventObj = await eventQuery.get(eventId, { useMasterKey: true });

        const eventType = eventObj.get("eventType") || 'classic';

        if (eventType === 'find_and_win') {
          const enigmaPrize = enigma.get("prize") || 0.0;
          user.set("balance", balance + enigmaPrize);

          let currentXP = user.get("xp") || 0;
          currentXP += 50; 
          user.set("xp", currentXP);
          user.set("league", getLeagueByXP(currentXP));

          enigma.set("status", "closed");
          enigma.set("closedAt", new Date());
          await enigma.save(null, { useMasterKey: true });

          let solvedEnigmas = eventProgress.solvedEnigmas || [];
          solvedEnigmas.push(enigmaId);
          eventProgress.solvedEnigmas = solvedEnigmas;
          userEvents[eventId] = eventProgress;
          user.set("events", userEvents);
          await user.save(null, { useMasterKey: true });

          return {
            success: true,
            message: "Resposta Correta! Recompensa instantânea creditada.",
            nextStep: {
              type: 'next_enigma', 
              prizeWon: enigmaPrize,
              enigmaData: {}
            }
          };
        } else {
          // ===================================================================
          // MODALIDADE CLASSIC
          // ===================================================================
          const Phase = Parse.Object.extend("Phase");
          const phaseQuery = new Parse.Query(Phase);
          phaseQuery.equalTo("event", eventObj);
          phaseQuery.ascending("order");
          const phases = await phaseQuery.find({ useMasterKey: true });

          const currentPhaseOrder = eventProgress.currentPhase || 1;
          const currentEnigmaOrder = eventProgress.currentEnigma || 1;

          let currentPhaseObj = phases.find(p => p.get("order") === currentPhaseOrder);
          if (!currentPhaseObj && phases.length > 0) {
            currentPhaseObj = phases[0];
          }

          const enigmaQuery = new Parse.Query(Enigma);
          enigmaQuery.equalTo("event", eventObj);
          enigmaQuery.ascending("order");
          const allEventEnigmas = await enigmaQuery.find({ useMasterKey: true });

          const currentPhaseId = currentPhaseObj ? currentPhaseObj.id : null;
          const phaseEnigmas = allEventEnigmas.filter(e => {
            const pId = e.get("phaseId") || (e.get("phase") ? e.get("phase").id : null);
            return pId === currentPhaseId;
          });

          let currentEnigmaIndex = phaseEnigmas.findIndex(e => e.id === enigmaId);
          if (currentEnigmaIndex === -1) {
            currentEnigmaIndex = currentEnigmaOrder - 1;
          }

          const hasMoreEnigmasInPhase = currentEnigmaIndex !== -1 && currentEnigmaIndex < phaseEnigmas.length - 1;

          if (hasMoreEnigmasInPhase) {
            const nextEnigmaObj = phaseEnigmas[currentEnigmaIndex + 1];
            const nextEnigmaSafe = nextEnigmaObj.toJSON();
            nextEnigmaSafe.id = nextEnigmaObj.id;
            delete nextEnigmaSafe.code;
            delete nextEnigmaSafe.compassCoords;
            delete nextEnigmaSafe.createdAt;
            delete nextEnigmaSafe.updatedAt;
            nextEnigmaSafe.prize = 0.0;

            eventProgress.currentPhase = currentPhaseOrder;
            eventProgress.currentEnigma = currentEnigmaIndex + 2;
            userEvents[eventId] = eventProgress;
            user.set("events", userEvents);

            let currentXP = user.get("xp") || 0;
            currentXP += 50;
            user.set("xp", currentXP);
            user.set("league", getLeagueByXP(currentXP));

            await user.save(null, { useMasterKey: true });

            return {
              success: true,
              message: "Enigma resolvido! Prepare-se para o próximo desafio.",
              nextStep: {
                type: 'next_enigma',
                enigmaData: nextEnigmaSafe
              }
            };
          } else {
            const currentPhaseIndex = phases.findIndex(p => p.id === currentPhaseId);
            const hasMorePhases = currentPhaseIndex !== -1 && currentPhaseIndex < phases.length - 1;

            if (hasMorePhases) {
              const nextPhaseObj = phases[currentPhaseIndex + 1];
              const nextPhaseOrder = nextPhaseObj.get("order");

              eventProgress.currentPhase = nextPhaseOrder;
              eventProgress.currentEnigma = 1;
              userEvents[eventId] = eventProgress;
              user.set("events", userEvents);

              let currentXP = user.get("xp") || 0;
              currentXP += 100;
              user.set("xp", currentXP);
              user.set("league", getLeagueByXP(currentXP));

              await user.save(null, { useMasterKey: true });

              return {
                success: true,
                message: `Fase ${currentPhaseOrder} concluída com sucesso! A Fase ${nextPhaseOrder} foi desbloqueada.`,
                nextStep: {
                  type: 'phase_complete',
                  phaseOrder: currentPhaseOrder,
                  nextPhaseOrder: nextPhaseOrder
                }
              };
            } else {
              // ===============================================================
              // ÚLTIMA FASE CONCLUÍDA - REGRA DE PREMIAÇÃO EXCLUSIVA DO PRIMEIRO
              // ===============================================================
              const existingWinnerId = eventObj.get("winnerId");
              const isEventClosed = eventObj.get("status") === "closed";

              let rawPrize = eventObj.get("prizePool") || eventObj.get("prize") || "0";
              if (typeof rawPrize === 'string') {
                rawPrize = rawPrize.replace('R$', '').replace(',', '.').trim();
              }
              const prizePool = parseFloat(rawPrize) || 0.0;

              eventProgress.isCompleted = true;
              eventProgress.completedAt = new Date();
              userEvents[eventId] = eventProgress;
              user.set("events", userEvents);

              if (!existingWinnerId && !isEventClosed) {
                // 1º LUGAR VENCEDOR
                eventObj.set("winnerId", user.id);
                eventObj.set("winnerName", user.get("name") || user.get("username") || "Explorador");
                eventObj.set("winnerPhotoURL", user.get("photoURL") || null);
                eventObj.set("status", "closed");
                eventObj.set("completedAt", new Date());
                await eventObj.save(null, { useMasterKey: true });

                user.set("balance", balance + prizePool);
                user.set("lastWonEventName", eventObj.get("name") || eventObj.get("title") || "Evento Classic");

                let currentXP = user.get("xp") || 0;
                currentXP += 500;
                user.set("xp", currentXP);
                user.set("league", getLeagueByXP(currentXP));

                let winnerEvents = user.get("winnerEvents") || [];
                winnerEvents.push(eventId);
                user.set("winnerEvents", winnerEvents);

                try {
                  const Transaction = Parse.Object.extend("Transaction");
                  const tx = new Transaction();
                  tx.set("type", "prize");
                  tx.set("amount", prizePool);
                  tx.set("description", "Prêmio 1º Lugar - " + (eventObj.get("name") || eventObj.get("title") || "Classic"));
                  tx.set("status", "completed");
                  tx.set("user", user);
                  await tx.save(null, { useMasterKey: true });
                } catch (txErr) {
                  console.error("Erro ao registrar transação de prêmio:", txErr);
                }

                await user.save(null, { useMasterKey: true });

                return {
                  success: true,
                  message: "PARABÉNS! Você foi o PRIMEIRO a finalizar todas as etapas e conquistou o prêmio total!",
                  nextStep: {
                    type: 'event_complete',
                    isWinner: true,
                    prizeWon: prizePool,
                    winnerName: user.get("name") || user.get("username") || "Explorador"
                  }
                };
              } else {
                // Concluiu após o primeiro colocado
                let currentXP = user.get("xp") || 0;
                currentXP += 250;
                user.set("xp", currentXP);
                user.set("league", getLeagueByXP(currentXP));
                await user.save(null, { useMasterKey: true });

                const winnerName = eventObj.get("winnerName") || "Outro explorador";

                return {
                  success: true,
                  message: `Você completou todas as fases do evento! O prêmio principal já foi conquistado pelo 1º colocado (${winnerName}), mas você completou a jornada com honra!`,
                  nextStep: {
                    type: 'event_complete',
                    isWinner: false,
                    prizeWon: 0.0,
                    winnerName: winnerName
                  }
                };
              }
            }
          }
        }
      } else {
        const cooldownTime = now + (3 * 60 * 1000); 
        eventProgress.cooldownUntil = cooldownTime;
        userEvents[eventId] = eventProgress;
        user.set("events", userEvents);
        await user.save(null, { useMasterKey: true });

        return {
          success: false,
          message: "Código Incorreto. Você recebeu uma penalidade.",
          cooldownUntil: cooldownTime,
          cooldownUntilIso: new Date(cooldownTime).toISOString()
        };
      }
    }
    return { success: true, message: "Action handled." };
  } catch (error) {
    throw new Parse.Error(Parse.Error.INTERNAL_SERVER_ERROR, error.message);
  }
});

Parse.Cloud.afterFind("Enigma", (request) => {
  const user = request.user;
  const isAdmin = user && (user.get("isAdmin") === true || user.get("role") === "admin" || user.get("role") === "creator");

  if (!request.master && !isAdmin && request.objects) {
    request.objects.forEach((enigma) => {
      enigma.unset("code");
      enigma.unset("compassCoords");
    });
  }
  return request.objects;
});

// -----------------------------------------------------------------------------
// GATEWAYS DE PAGAMENTO & WEBHOOKS (Mercado Pago, Stripe, Asaas, Efi, Pagar.me)
// -----------------------------------------------------------------------------

Parse.Cloud.define("getActiveGatewayConfig", async (request) => {
  const query = new Parse.Query("GatewayConfig");
  query.equalTo("isDefault", true);
  query.equalTo("isActive", true);
  const config = await query.first({ useMasterKey: true });

  if (!config) {
    return {
      success: true,
      gateway: "mercadopago",
      environment: "production",
      publicKey: ""
    };
  }

  const keys = config.get("keys") || {};
  return {
    success: true,
    gateway: config.get("gatewayId"),
    name: config.get("name"),
    environment: config.get("environment") || "production",
    publicKey: keys.public_key || keys.publishable_key || keys.api_key || ""
  };
});

Parse.Cloud.define("paymentWebhook", async (request) => {
  const { gateway } = request.params;
  const payload = request.params;

  console.log(`[Payment Webhook] Recebida notificação do gateway: ${gateway}`, JSON.stringify(payload));

  // Tenta localizar a transação pelo ID ou dados do payload
  let transactionId = payload.transactionId || payload.id || (payload.data ? payload.data.id : null);
  
  if (transactionId) {
    const qTx = new Parse.Query("Transaction");
    qTx.equalTo("objectId", transactionId);
    let tx = await qTx.first({ useMasterKey: true });

    if (!tx && payload.external_reference) {
      const qRef = new Parse.Query("Transaction");
      qRef.equalTo("objectId", payload.external_reference);
      tx = await qRef.first({ useMasterKey: true });
    }

    if (tx && tx.get("status") !== "approved") {
      tx.set("status", "approved");
      tx.set("gateway", gateway || "mercadopago");
      tx.set("approvedAt", new Date());
      await tx.save(null, { useMasterKey: true });

      // Credita o saldo na carteira do usuário
      const user = tx.get("user");
      if (user) {
        await user.fetch({ useMasterKey: true });
        const currentBalance = user.get("balance") || 0;
        const amount = tx.get("amount") || 0;
        user.set("balance", currentBalance + amount);
        await user.save(null, { useMasterKey: true });
      }

      return { success: true, message: "Transaction approved and wallet credited." };
    }
  }

  return { success: true, message: "Webhook acknowledged." };
});

Parse.Cloud.define("requestWithdrawal", async (request) => {
  const user = request.user;
  if (!user) throw new Parse.Error(Parse.Error.INVALID_SESSION_TOKEN, "Usuário não autenticado.");
  const { amount, pixKey, pixKeyType } = request.params;

  if (!amount || typeof amount !== 'number' || amount <= 0) {
    throw new Parse.Error(Parse.Error.INVALID_QUERY, "Valor de saque inválido.");
  }
  if (!pixKey || typeof pixKey !== 'string' || pixKey.trim().length === 0) {
    throw new Parse.Error(Parse.Error.INVALID_QUERY, "Chave Pix é obrigatória.");
  }

  try {
    await user.fetch({ useMasterKey: true });
    const currentBalance = user.get("balance") || 0.0;
    if (currentBalance < amount) {
      throw new Parse.Error(Parse.Error.VALIDATION_ERROR, "Saldo insuficiente para o saque solicitado.");
    }

    // Debita o saldo imediatamente para evitar saques simultâneos
    user.set("balance", currentBalance - amount);
    await user.save(null, { useMasterKey: true });

    const userName = user.get("name") || user.get("username") || "Jogador";
    const userEmail = user.get("email") || "";

    // Cria registro na classe Withdrawal
    const Withdrawal = Parse.Object.extend("Withdrawal");
    const withdrawal = new Withdrawal();
    withdrawal.set("amount", amount);
    withdrawal.set("status", "pending");
    withdrawal.set("pixKey", pixKey.trim());
    withdrawal.set("pixKeyType", pixKeyType || "CHAVE_ALEATORIA");
    withdrawal.set("user", user);
    withdrawal.set("userName", userName);
    withdrawal.set("userEmail", userEmail);

    const acl = new Parse.ACL();
    acl.setReadAccess(user.id, true);
    acl.setWriteAccess(user.id, false);
    acl.setPublicReadAccess(false);
    acl.setPublicWriteAccess(false);
    withdrawal.setACL(acl);

    await withdrawal.save(null, { useMasterKey: true });

    // Registra na Transaction para extrato unificado
    const Transaction = Parse.Object.extend("Transaction");
    const tx = new Transaction();
    tx.set("type", "withdrawal");
    tx.set("amount", amount);
    tx.set("status", "pending");
    tx.set("user", user);
    tx.set("withdrawalId", withdrawal.id);
    tx.set("pixKey", pixKey.trim());
    tx.set("pixKeyType", pixKeyType || "CHAVE_ALEATORIA");
    tx.set("description", `Saque Pix para ${pixKey.trim()}`);
    await tx.save(null, { useMasterKey: true });

    return {
      success: true,
      message: "Solicitação de saque enviada com sucesso!",
      withdrawalId: withdrawal.id,
      newBalance: user.get("balance")
    };
  } catch (error) {
    throw new Parse.Error(Parse.Error.INTERNAL_SERVER_ERROR, "Erro ao solicitar saque: " + error.message);
  }
});

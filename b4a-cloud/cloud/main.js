// Parse Cloud Code for Back4App
// Write your cloud functions here.
const financialService = require('./financial_service.js');

function parseMoney(value) {
  if (value === undefined || value === null) return 0.0;
  if (typeof value === 'number') return isNaN(value) ? 0.0 : value;
  let clean = String(value).replace('R$', '').replace(/\s/g, '').trim();
  if (clean.includes(',') && clean.includes('.')) {
    clean = clean.replace(/\./g, '').replace(',', '.');
  } else if (clean.includes(',')) {
    clean = clean.replace(',', '.');
  }
  const parsed = parseFloat(clean);
  return isNaN(parsed) ? 0.0 : parsed;
}

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
        balance: parseMoney(user.get("balance")),
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
      balance: parseMoney(p.get("balance"))
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

  const numAmount = parseMoney(amount);
  if (!numAmount || numAmount <= 0) {
    throw new Parse.Error(Parse.Error.INVALID_QUERY, "Valor de depósito inválido.");
  }
  
  if (!user) {
    throw new Parse.Error(209, "Acesso negado. Usuário não autenticado.");
  }

  try {
    const Transaction = Parse.Object.extend("Transaction");
    const transaction = new Transaction();
    transaction.set("type", "deposit");
    transaction.set("amount", numAmount);
    transaction.set("status", "pending");
    transaction.set("user", user);
    transaction.set("description", `Depósito Pix R$ ${numAmount.toFixed(2)}`);

    const acl = new Parse.ACL();
    acl.setReadAccess(user.id, true);
    acl.setWriteAccess(user.id, false);
    acl.setPublicReadAccess(false);
    acl.setPublicWriteAccess(false);
    transaction.setACL(acl);

    await transaction.save(null, { useMasterKey: true });

    // Gera cobrança no Gateway Ativo ou Pix BRCode Oficial Bacen
    const chargeData = await financialService.createPixChargeService({
      amount: numAmount,
      user: user,
      transactionId: transaction.id
    });

    transaction.set("gateway", chargeData.gateway || "mercadopago");
    if (chargeData.gatewayPaymentId) {
      transaction.set("gatewayPaymentId", chargeData.gatewayPaymentId);
    }
    if (chargeData.copiaCola) {
      transaction.set("copiaCola", chargeData.copiaCola);
    }
    if (chargeData.qrCodeBase64) {
      transaction.set("qrCodeBase64", chargeData.qrCodeBase64);
    }
    await transaction.save(null, { useMasterKey: true });

    return {
      success: true,
      gateway: chargeData.gateway,
      qrCode: chargeData.copiaCola,
      copiaCola: chargeData.copiaCola,
      qrCodeBase64: chargeData.qrCodeBase64,
      transactionId: transaction.id
    };
  } catch (error) {
    console.error("[createPixCharge Error]", error);
    throw new Parse.Error(Parse.Error.INTERNAL_SERVER_ERROR, "Erro ao gerar cobrança Pix: " + error.message);
  }
});

Parse.Cloud.define("checkPixPaymentStatus", async (request) => {
  const { transactionId } = request.params;
  const user = request.user;
  if (!transactionId) {
    throw new Parse.Error(Parse.Error.INVALID_QUERY, "transactionId is required.");
  }

  try {
    const qTx = new Parse.Query("Transaction");
    qTx.include("user");
    const tx = await qTx.get(transactionId, { useMasterKey: true });

    if (!tx) {
      throw new Error("Transação não encontrada.");
    }

    const currentStatus = tx.get("status") || "pending";
    if (currentStatus === "approved" || currentStatus === "completed") {
      const txUser = tx.get("user") || user;
      let balance = 0;
      if (txUser) {
        await txUser.fetch({ useMasterKey: true });
        balance = parseMoney(txUser.get("balance"));
      }
      return {
        success: true,
        status: "approved",
        balance: balance,
        message: "Depósito já aprovado e creditado!"
      };
    }

    // Se estiver pendente e possuir gatewayPaymentId, consulta o status no gateway
    const gateway = tx.get("gateway");
    const gatewayPaymentId = tx.get("gatewayPaymentId");
    const gatewayConfig = await financialService.getActiveGateway();
    const keys = gatewayConfig ? (gatewayConfig.get("keys") || {}) : {};
    const environment = gatewayConfig ? (gatewayConfig.get("environment") || "production") : "production";

    let approvedNow = false;

    if (gateway === "mercadopago" && gatewayPaymentId && keys.access_token) {
      try {
        const mpRes = await financialService.httpRequest(`https://api.mercadopago.com/v1/payments/${gatewayPaymentId}`, {
          method: "GET",
          headers: { "Authorization": `Bearer ${keys.access_token.trim()}` }
        });
        if (mpRes.ok && mpRes.data && mpRes.data.status === "approved") {
          approvedNow = true;
        }
      } catch (e) {
        console.warn("[checkPixPaymentStatus] MP check error:", e.message);
      }
    } else if (gateway === "asaas" && gatewayPaymentId && keys.api_key) {
      try {
        const baseUrl = environment === "sandbox" ? "https://sandbox.asaas.com/api/v3" : "https://api.asaas.com/api/v3";
        const asaasRes = await financialService.httpRequest(`${baseUrl}/payments/${gatewayPaymentId}`, {
          method: "GET",
          headers: { "access_token": keys.api_key.trim() }
        });
        if (asaasRes.ok && asaasRes.data && (asaasRes.data.status === "RECEIVED" || asaasRes.data.status === "CONFIRMED")) {
          approvedNow = true;
        }
      } catch (e) {
        console.warn("[checkPixPaymentStatus] Asaas check error:", e.message);
      }
    } else if (gateway === "stripe" && gatewayPaymentId && (keys.secret_key || keys.api_key)) {
      try {
        const stripeKey = (keys.secret_key || keys.api_key || "").trim();
        const stripeRes = await financialService.httpRequest(`https://api.stripe.com/v1/payment_intents/${gatewayPaymentId}`, {
          method: "GET",
          headers: { "Authorization": `Bearer ${stripeKey}` }
        });
        if (stripeRes.ok && stripeRes.data && stripeRes.data.status === "succeeded") {
          approvedNow = true;
        }
      } catch (e) {
        console.warn("[checkPixPaymentStatus] Stripe check error:", e.message);
      }
    }

    if (approvedNow) {
      tx.set("status", "approved");
      tx.set("approvedAt", new Date());
      await tx.save(null, { useMasterKey: true });

      const targetUser = tx.get("user");
      let newBalance = 0;
      if (targetUser) {
        await targetUser.fetch({ useMasterKey: true });
        const curBal = parseMoney(targetUser.get("balance"));
        const amt = parseMoney(tx.get("amount"));
        newBalance = Number((curBal + amt).toFixed(2));
        targetUser.set("balance", newBalance);
        await targetUser.save(null, { useMasterKey: true });
      }

      return {
        success: true,
        status: "approved",
        balance: newBalance,
        message: "Pagamento confirmado com sucesso e creditado na carteira!"
      };
    }

    return {
      success: true,
      status: currentStatus,
      message: "Aguardando confirmação do pagamento..."
    };
  } catch (error) {
    throw new Parse.Error(Parse.Error.INTERNAL_SERVER_ERROR, "Erro ao checar status do pagamento: " + error.message);
  }
});

// -----------------------------------------------------------------------------
// Missing Frontend Functions
// -----------------------------------------------------------------------------

Parse.Cloud.define("getUserTransactions", async (request) => {
  const user = request.user;
  if (!user) {
    throw new Parse.Error(Parse.Error.INVALID_SESSION_TOKEN, "User not authenticated.");
  }
  try {
    const Transaction = Parse.Object.extend("Transaction");
    const query = new Parse.Query(Transaction);
    query.equalTo("user", user);
    query.descending("createdAt");
    query.limit(30);
    const results = await query.find({ useMasterKey: true });
    return results.map(t => {
      const json = t.toJSON();
      json.id = t.id;
      json.objectId = t.id;
      if (t.createdAt) {
        json.createdAt = t.createdAt instanceof Date ? t.createdAt.toISOString() : t.createdAt;
      }
      return json;
    });
  } catch (error) {
    throw new Parse.Error(Parse.Error.INTERNAL_SERVER_ERROR, error.message);
  }
});

Parse.Cloud.define("getSafeEventEnigmas", async (request) => {
  const { eventId } = request.params;
  const user = request.user;
  if (!user) throw new Parse.Error(Parse.Error.INVALID_SESSION_TOKEN, "User not authenticated.");
  if (!eventId) throw new Parse.Error(Parse.Error.INVALID_QUERY, "eventId is required.");

  try {
    const Enigma = Parse.Object.extend("Enigma");
    const query = new Parse.Query(Enigma);
    query.equalTo("eventId", eventId);
    query.ascending("order");
    const results = await query.find({ useMasterKey: true });

    return results.map(e => {
      const json = e.toJSON();
      json.id = e.id;
      json.objectId = e.id;
      // Blindagem de Payload SecOps: NUNCA envia resposta nem coordenadas exatas
      delete json.code;
      delete json.compassCoords;
      return json;
    });
  } catch (error) {
    throw new Parse.Error(Parse.Error.INTERNAL_SERVER_ERROR, error.message);
  }
});

Parse.Cloud.define("getEnigmaHints", async (request) => {
  const { enigmaId, eventId } = request.params;
  const user = request.user;
  if (!user) throw new Parse.Error(Parse.Error.INVALID_SESSION_TOKEN, "User not authenticated.");
  if (!enigmaId) throw new Parse.Error(Parse.Error.INVALID_QUERY, "enigmaId is required.");

  try {
    const userEvents = user.get("events") || {};
    const eventProgress = userEvents[eventId] || {};
    const hintsPurchased = eventProgress.hintsPurchased || [];

    const Hint = Parse.Object.extend("Hint");
    const query = new Parse.Query(Hint);
    query.equalTo("linkedEnigmaId", enigmaId);
    const results = await query.find({ useMasterKey: true });

    return results.map(h => {
      const json = h.toJSON();
      json.id = h.id;
      json.objectId = h.id;
      const isPurchased = hintsPurchased.includes(h.id);
      const price = h.get("price") || 0;
      // SecOps Zero Trust: se nao foi comprada e tem custo, oculta o segredo
      if (!isPurchased && price > 0) {
        json.data = null;
        json.text = null;
        json.description = "Pista bloqueada. Adquira para desvendar este segredo.";
      }
      return json;
    });
  } catch (error) {
    throw new Parse.Error(Parse.Error.INTERNAL_SERVER_ERROR, error.message);
  }
});

Parse.Cloud.define("reportFraud", async (request) => {
  const { eventId, enigmaId, reason } = request.params;
  const user = request.user;
  if (!user) return { success: false };

  try {
    const FraudLog = Parse.Object.extend("FraudLog");
    const fraud = new FraudLog();
    fraud.set("user", user);
    fraud.set("eventId", eventId || "");
    fraud.set("enigmaId", enigmaId || "");
    fraud.set("reason", reason || "Suspeita de Fraude");
    await fraud.save(null, { useMasterKey: true });
    return { success: true };
  } catch (e) {
    return { success: false };
  }
});

Parse.Cloud.define("getUserWalletData", async (request) => {
  const user = request.user;
  if (!user) {
    throw new Parse.Error(Parse.Error.INVALID_SESSION_TOKEN, "User not authenticated.");
  }
  return {
    objectId: user.id,
    name: user.get("name") || user.get("username") || "Jogador",
    email: user.get("email") || "",
    balance: parseMoney(user.get("balance")),
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
    let balance = parseMoney(user.get("balance"));

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

        let toolTimes = eventProgress.toolTimes || {};
        toolsPurchased.forEach(t => {
          if (toolTimes[t] === undefined) toolTimes[t] = 900;
        });

        // Remove ferramentas expiradas
        const initialToolsCount = toolsPurchased.length;
        toolsPurchased = toolsPurchased.filter(t => (toolTimes[t] || 0) > 0);
        if (toolsPurchased.length !== initialToolsCount) {
          eventProgress.toolsPurchased = toolsPurchased;
          eventProgress.toolTimes = toolTimes;
          userEvents[eventId] = eventProgress;
          user.set("events", userEvents);
          await user.save(null, { useMasterKey: true });
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
        enableToolTimer: enigma ? (enigma.get("enableToolTimer") !== false) : true,
        enableFakeTargets: enigma ? (enigma.get("enableFakeTargets") !== false) : true,
        compassDuration: 900,
        compassRemainingSeconds: hasCompass ? (eventProgress.toolTimes?.['compass'] || 900) : 0,
        radarRemainingSeconds: hasRadar ? (eventProgress.toolTimes?.['radar'] || 900) : 0,
        mapRemainingSeconds: hasMap ? (eventProgress.toolTimes?.['map'] || 900) : 0,
        toolTimes: eventProgress.toolTimes || {},
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

      user.set("balance", Number((balance - cost).toFixed(2)));

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
      }
      let toolTimes = eventProgress.toolTimes || {};
      toolTimes[toolType] = 0;
      eventProgress.toolTimes = toolTimes;
      userEvents[eventId] = eventProgress;
      user.set("events", userEvents);
      await user.save(null, { useMasterKey: true });

      return { success: true, message: "Ferramenta consumida e finalizada." };

    } else if (action === 'syncToolUsage') {
      if (!toolType) throw new Parse.Error(Parse.Error.INVALID_QUERY, "toolType is required.");

      const isTimerEnabled = enigma ? (enigma.get("enableToolTimer") !== false) : true;
      if (!isTimerEnabled) {
        return {
          success: true,
          toolType: toolType,
          remainingSeconds: 900,
          expired: false
        };
      }

      const secs = Math.max(0, parseInt(request.params.usedSeconds) || 0);

      let toolTimes = eventProgress.toolTimes || {};
      let currentRemaining = toolTimes[toolType] !== undefined ? toolTimes[toolType] : 900;
      let newRemaining = Math.max(0, currentRemaining - secs);
      toolTimes[toolType] = newRemaining;
      eventProgress.toolTimes = toolTimes;

      let expired = false;
      if (newRemaining <= 0) {
        expired = true;
        const idx = toolsPurchased.indexOf(toolType);
        if (idx > -1) {
          toolsPurchased.splice(idx, 1);
          eventProgress.toolsPurchased = toolsPurchased;
        }
      }

      userEvents[eventId] = eventProgress;
      user.set("events", userEvents);
      await user.save(null, { useMasterKey: true });

      return {
        success: true,
        toolType: toolType,
        remainingSeconds: newRemaining,
        expired: expired
      };

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

      user.set("balance", Number((balance - cost).toFixed(2)));

      if (!toolsPurchased.includes(toolType)) {
        toolsPurchased.push(toolType);
      }
      eventProgress.toolsPurchased = toolsPurchased;

      // Cada ferramenta ganha 15 minutos (900 segundos) de uso ativo ao ser comprada
      let toolTimes = eventProgress.toolTimes || {};
      toolTimes[toolType] = 900;
      eventProgress.toolTimes = toolTimes;

      userEvents[eventId] = eventProgress;
      user.set("events", userEvents);
      await user.save(null, { useMasterKey: true });

      return {
        success: true,
        message: "Ferramenta comprada com sucesso. Disponível por 15 minutos de uso ativo.",
        remainingSeconds: 900
      };

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
          const enigmaPrize = parseMoney(enigma.get("prize"));
          const currentBalance = parseMoney(user.get("balance"));
          const newBalance = Number((currentBalance + enigmaPrize).toFixed(2));
          user.set("balance", newBalance);

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

          if (enigmaPrize > 0) {
            try {
              const Transaction = Parse.Object.extend("Transaction");
              const tx = new Transaction();
              tx.set("type", "prize");
              tx.set("amount", enigmaPrize);
              tx.set("description", "Recompensa Baú - " + (enigma.get("instruction") || enigma.get("title") || "Find & Win"));
              tx.set("status", "completed");
              tx.set("user", user);
              await tx.save(null, { useMasterKey: true });
            } catch (txErr) {
              console.error("Erro ao registrar transação de prêmio Find & Win:", txErr);
            }
          }

          await user.save(null, { useMasterKey: true });

          return {
            success: true,
            message: "Resposta Correta! Recompensa instantânea creditada.",
            nextStep: {
              type: 'find_and_win_complete', 
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
              const prizePool = parseMoney(rawPrize);

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

                const currentBalance = parseMoney(user.get("balance"));
                const newBalance = Number((currentBalance + prizePool).toFixed(2));
                user.set("balance", newBalance);
                user.set("lastWonEventName", eventObj.get("name") || eventObj.get("title") || "Evento Classic");

                let currentXP = user.get("xp") || 0;
                currentXP += 500;
                user.set("xp", currentXP);
                user.set("league", getLeagueByXP(currentXP));

                let winnerEvents = user.get("winnerEvents") || [];
                winnerEvents.push(eventId);
                user.set("winnerEvents", winnerEvents);

                if (prizePool > 0) {
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
                    console.error("Erro ao registrar transação de prêmio Classic:", txErr);
                  }
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

  // Tenta localizar a transação por IDs em múltiplos formatos de payload
  let transactionId = payload.transactionId || payload.id || (payload.data ? payload.data.id : null) || (payload.payment ? payload.payment.id : null);
  let extRef = payload.external_reference || (payload.payment ? payload.payment.externalReference : null) || (payload.data ? payload.data.external_reference : null);

  // Suporte especial para payloads de webhook do Stripe (payment_intent.succeeded)
  if (payload.type === "payment_intent.succeeded" && payload.data && payload.data.object) {
    const pi = payload.data.object;
    transactionId = (pi.metadata && pi.metadata.transactionId) ? pi.metadata.transactionId : pi.id;
    if (!extRef && pi.metadata && pi.metadata.transactionId) {
      extRef = pi.metadata.transactionId;
    }
  }

  let tx = null;
  if (transactionId) {
    const qTx = new Parse.Query("Transaction");
    qTx.equalTo("objectId", transactionId);
    tx = await qTx.first({ useMasterKey: true });

    if (!tx) {
      const qGatewayId = new Parse.Query("Transaction");
      qGatewayId.equalTo("gatewayPaymentId", String(transactionId));
      tx = await qGatewayId.first({ useMasterKey: true });
    }
  }

  if (!tx && extRef) {
    const qRef = new Parse.Query("Transaction");
    qRef.equalTo("objectId", extRef);
    tx = await qRef.first({ useMasterKey: true });
  }

  if (tx && tx.get("status") !== "approved" && tx.get("status") !== "completed") {
    tx.set("status", "approved");
    tx.set("gateway", gateway || tx.get("gateway") || "mercadopago");
    tx.set("approvedAt", new Date());
    await tx.save(null, { useMasterKey: true });

    // Credita o saldo atomicamente na carteira do usuário
    const user = tx.get("user");
    if (user) {
      await user.fetch({ useMasterKey: true });
      const currentBalance = parseMoney(user.get("balance"));
      const amount = parseMoney(tx.get("amount"));
      const newBalance = Number((currentBalance + amount).toFixed(2));
      user.set("balance", newBalance);
      await user.save(null, { useMasterKey: true });
      console.log(`[Payment Webhook] Saldo creditado: R$ ${amount} para usuário ${user.id}. Novo saldo: R$ ${newBalance}`);
    }

    return { success: true, message: "Transaction approved and wallet credited." };
  }

  return { success: true, message: "Webhook acknowledged." };
});

Parse.Cloud.define("requestWithdrawal", async (request) => {
  const user = request.user;
  if (!user) throw new Parse.Error(Parse.Error.INVALID_SESSION_TOKEN, "Usuário não autenticado.");
  const { amount, pixKey, pixKeyType } = request.params;
  const numAmount = parseMoney(amount);

  if (!numAmount || numAmount <= 0) {
    throw new Parse.Error(Parse.Error.INVALID_QUERY, "Valor de saque inválido.");
  }
  if (!pixKey || typeof pixKey !== 'string' || pixKey.trim().length === 0) {
    throw new Parse.Error(Parse.Error.INVALID_QUERY, "Chave Pix é obrigatória.");
  }

  try {
    await user.fetch({ useMasterKey: true });
    const currentBalance = parseMoney(user.get("balance"));
    if (currentBalance < numAmount) {
      throw new Parse.Error(Parse.Error.VALIDATION_ERROR, "Saldo insuficiente para o saque solicitado.");
    }

    // Debita o saldo imediatamente para evitar saques simultâneos
    const newBalance = Number((currentBalance - numAmount).toFixed(2));
    user.set("balance", newBalance);
    await user.save(null, { useMasterKey: true });

    const userName = user.get("name") || user.get("username") || "Jogador";
    const userEmail = user.get("email") || "";

    // Cria registro na classe Withdrawal com leitura pública (para o painel admin carregar sem bloqueio de ACL)
    const Withdrawal = Parse.Object.extend("Withdrawal");
    const withdrawal = new Withdrawal();
    withdrawal.set("amount", numAmount);
    withdrawal.set("status", "pending");
    withdrawal.set("pixKey", pixKey.trim());
    withdrawal.set("pixKeyType", pixKeyType || "CHAVE_ALEATORIA");
    withdrawal.set("user", user);
    withdrawal.set("userName", userName);
    withdrawal.set("userEmail", userEmail);

    // Define ACL estritamente privada: apenas o próprio usuário e Master Key têm acesso
    const acl = new Parse.ACL();
    acl.setPublicReadAccess(false);
    acl.setPublicWriteAccess(false);
    acl.setReadAccess(user.id, true);
    acl.setWriteAccess(user.id, false);
    withdrawal.setACL(acl);

    await withdrawal.save(null, { useMasterKey: true });

    // Registra na Transaction para extrato unificado
    const Transaction = Parse.Object.extend("Transaction");
    const tx = new Transaction();
    tx.set("type", "withdrawal");
    tx.set("amount", numAmount);
    tx.set("status", "pending");
    tx.set("user", user);
    tx.set("withdrawalId", withdrawal.id);
    tx.set("pixKey", pixKey.trim());
    tx.set("pixKeyType", pixKeyType || "CHAVE_ALEATORIA");
    tx.set("description", `Saque Pix para ${pixKey.trim()}`);

    const txAcl = new Parse.ACL();
    txAcl.setPublicReadAccess(false);
    txAcl.setPublicWriteAccess(false);
    txAcl.setReadAccess(user.id, true);
    txAcl.setWriteAccess(user.id, false);
    tx.setACL(txAcl);

    await tx.save(null, { useMasterKey: true });

    console.log(`[requestWithdrawal] Saque solicitado: R$ ${numAmount} por ${userName} (${user.id}). Novo saldo: R$ ${newBalance}`);

    return {
      success: true,
      message: "Solicitação de saque enviada com sucesso!",
      withdrawalId: withdrawal.id,
      newBalance: newBalance
    };
  } catch (error) {
    console.error("[requestWithdrawal Error]", error);
    throw new Parse.Error(Parse.Error.INTERNAL_SERVER_ERROR, "Erro ao solicitar saque: " + error.message);
  }
});

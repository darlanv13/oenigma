// Parse Cloud Code for Back4App
// Write your cloud functions here.

require('./admin.js');

// -----------------------------------------------------------------------------
// App / Home Functions
// -----------------------------------------------------------------------------
Parse.Cloud.define("getHomeScreenData", async (request) => {
  try {
    // 1. Pegar o usuário logado que fez a requisição
    const user = request.user;

    // 2. Buscar Banners
    const Banner = Parse.Object.extend("Banner");
    const bannerQuery = new Parse.Query(Banner);
    const banners = await bannerQuery.find({ useMasterKey: true });

    // 3. Buscar Eventos abertos
    const Event = Parse.Object.extend("Event");
    const eventQuery = new Parse.Query(Event);
    eventQuery.equalTo("status", "open");
    const events = await eventQuery.find({ useMasterKey: true });

    // FORMATAR OS EVENTOS PARA O FLUTTER NÃO DAR ERRO DE TIPO
    const formattedEvents = events.map(e => {
      const json = e.toJSON();

      // Corrige o campo ID (O Flutter espera 'id', mas o Parse envia 'objectId' por padrão)
      json.id = e.id;

      // Corrige a Data (Converte o Objeto/Map de data do Parse numa String simples)
      if (json.startDate && json.startDate.iso) {
        json.startDate = json.startDate.iso;
      }

      return json;
    });

    // 4. Montar a Carteira (Wallet) e Dados do Jogador
    let walletData = {};
    let playerData = {};

    if (user) {
      // Se houver usuário logado, envia os dados reais
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
      // Valores padrão de segurança (Caso seja um Visitante)
      walletData = {
        objectId: "visitante",
        name: "Visitante",
        email: "sem_email@teste.com",
        balance: 0.0,
        photoURL: null
      };
    }

    // 5. Buscar o Ranking para a tela inicial (allPlayers)
    const userQuery = new Parse.Query(Parse.User);
    userQuery.descending("balance"); // Ordena pelos mais ricos, por exemplo
    userQuery.limit(5); // Pega apenas os 5 primeiros
    const topPlayers = await userQuery.find({ useMasterKey: true });

    const allPlayers = topPlayers.map(p => ({
      objectId: p.id,
      name: p.get("name") || p.get("username") || "Jogador",
      balance: p.get("balance") || 0.0
    }));

    // 6. Retornar TUDO que o ficheiro home_screen.dart do Flutter pede
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
  if (!amount || typeof amount !== 'number') {
    throw new Parse.Error(Parse.Error.INVALID_QUERY, "amount is required and must be a number.");
  }

  try {
    // In a real implementation, you would call Mercado Pago API here.
    // For now, we mock a successful Pix charge.

    const Transaction = Parse.Object.extend("Transaction");
    const transaction = new Transaction();
    transaction.set("type", "deposit");
    transaction.set("amount", amount);
    transaction.set("status", "pending");
    if (request.user) {
      transaction.set("user", request.user);
    }
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

    const price = event.get("price") || 0.0;
    const balance = user.get("balance") || 0.0;

    if (balance < price) {
      throw new Parse.Error(Parse.Error.SCRIPT_FAILED, "saldo insuficiente");
    }

    // Deduct price
    user.set("balance", balance - price);

    // Update events map
    let userEvents = user.get("events") || {};
    userEvents[eventId] = { currentPhase: 1, currentEnigma: 1, hintsPurchased: [] };
    user.set("events", userEvents);

    await user.save(null, { useMasterKey: true });

    // Increment player count on Event
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
      // SECURITY: Remove the code so it's not exposed to the client!
      delete json.code;
      return json;
    });

    let phasesJson = phases.map(p => {
      const json = p.toJSON();
      json.id = p.id;
      json.enigmas = enigmasJson.filter(e => e.phaseId === p.id || (e.phase && e.phase.objectId === p.id));
      return json;
    });

    eventJson.phases = phasesJson;
    eventJson.enigmas = enigmasJson;

    return eventJson;
  } catch (error) {
    throw new Parse.Error(Parse.Error.INTERNAL_SERVER_ERROR, error.message);
  }
});





Parse.Cloud.define("handleEnigmaAction", async (request) => {
  const { action, eventId, enigmaId, answer } = request.params;
  const user = request.user;
  if (!user) throw new Parse.Error(Parse.Error.INVALID_SESSION_TOKEN, "User not authenticated.");
  if (!action) throw new Parse.Error(Parse.Error.INVALID_QUERY, "action is required.");

  try {
    if (action === 'getStatus') {
      // get user progress
      const userEvents = user.get("events") || {};
      const eventProgress = userEvents[eventId] || {};
      return {
        currentPhase: eventProgress.currentPhase || 1,
        currentEnigma: eventProgress.currentEnigma || 1,
        hintsPurchased: eventProgress.hintsPurchased || []
      };
    } else if (action === 'verify_code' || action === 'scan_enigma') {
      // Assuming basic code verification
      const Enigma = Parse.Object.extend("Enigma");
      const query = new Parse.Query(Enigma);
      const enigma = await query.get(enigmaId, { useMasterKey: true });

      if (enigma.get("code") === answer) {
        return { success: true, message: "Correct answer" };
      } else {
        return { success: false, message: "Incorrect answer" };
      }
    }
    return { success: true, message: "Action handled." };
  } catch (error) {
    throw new Parse.Error(Parse.Error.INTERNAL_SERVER_ERROR, error.message);
  }
});

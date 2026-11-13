// Parse Cloud Code for Back4App - Admin Functions
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

function isAdminUser(user, request) {
  if (request && request.master) return true;
  if (!user && request && request.user) user = request.user;
  if (!user) return false;
  const isAdmin = user.get("isAdmin");
  const role = (user.get("role") || "").toLowerCase();
  return isAdmin === true || role === "admin" || role === "creator" || role === "administrador";
}

async function resolveAdminUser(request) {
  if (request && request.master) return request.user || true;

  let user = request.user;
  const sessionToken = (request.params && request.params.sessionToken) ||
                       (request.headers && (request.headers['x-parse-session-token'] || request.headers['X-Parse-Session-Token']));

  if (!user && sessionToken) {
    try {
      const q = new Parse.Query(Parse.User);
      q.equalTo("sessionToken", sessionToken);
      user = await q.first({ useMasterKey: true });
    } catch (_) {}
  }

  if (!user) return null;

  try {
    await user.fetch({ useMasterKey: true });
  } catch (_) {}

  // 1. Verifica atributos diretos
  const isAdmin = user.get("isAdmin");
  const role = (user.get("role") || "").toLowerCase();
  if (isAdmin === true || role === "admin" || role === "creator" || role === "administrador") {
    return user;
  }

  // 2. Verifica vínculo com Parse Roles no Back4App
  try {
    const roleQuery = new Parse.Query(Parse.Role);
    roleQuery.equalTo("users", user);
    const roles = await roleQuery.find({ useMasterKey: true });
    for (const r of roles) {
      const name = (r.get("name") || "").toLowerCase();
      if (name === "admin" || name === "creator" || name === "administrador") {
        return user;
      }
    }
  } catch (_) {}

  return null;
}


Parse.Cloud.define("getAdminDashboardData", async (request) => {
  const user = request.user;
  if (!isAdminUser(user, request)) throw new Parse.Error(Parse.Error.INVALID_SESSION_TOKEN, "Admin required.");
  try {
    const usersQuery = new Parse.Query(Parse.User);
    const usersCount = await usersQuery.count({ useMasterKey: true });

    const eventsQuery = new Parse.Query("Event");
    eventsQuery.equalTo("status", "open");
    const activeEventsCount = await eventsQuery.count({ useMasterKey: true });

    const depositsQuery = new Parse.Query("Transaction");
    depositsQuery.equalTo("type", "deposit");
    const totalDepositsCount = await depositsQuery.count({ useMasterKey: true });

    const withdrawalsQuery = new Parse.Query("Withdrawal");
    withdrawalsQuery.equalTo("status", "pending");
    const pendingWithdrawalsCount = await withdrawalsQuery.count({ useMasterKey: true });

    const totalEventsQuery = new Parse.Query('Event');
    const totalEventsCount = await totalEventsQuery.count({ useMasterKey: true }).catch(() => activeEventsCount);

    const enigmasQuery = new Parse.Query('Enigma');
    const totalEnigmasCount = await enigmasQuery.count({ useMasterKey: true }).catch(() => 0);

    const bannersQuery = new Parse.Query('Banner');
    const totalBannersCount = await bannersQuery.count({ useMasterKey: true }).catch(() => 0);

    const hintsQuery = new Parse.Query('Hint');
    const totalHintsCount = await hintsQuery.count({ useMasterKey: true }).catch(() => 0);

    return {
      users: usersCount,
      activeEvents: activeEventsCount,
      totalEvents: totalEventsCount,
      totalEnigmas: totalEnigmasCount,
      totalBanners: totalBannersCount,
      totalHints: totalHintsCount,
      totalDeposits: totalDepositsCount,
      pendingWithdrawals: pendingWithdrawalsCount
    };
  } catch (error) {
    throw new Parse.Error(Parse.Error.INTERNAL_SERVER_ERROR, "Error fetching dashboard data: " + error.message);
  }
});

Parse.Cloud.define("listAllUsers", async (request) => {
  const user = request.user;
  if (!isAdminUser(user, request)) throw new Parse.Error(Parse.Error.INVALID_SESSION_TOKEN, "Admin required.");
  try {
    const query = new Parse.Query(Parse.User);
    query.limit(1000);
    const users = await query.find({ useMasterKey: true });

    return users.map(user => {
      return {
        objectId: user.id,
        email: user.get("email") || "",
        name: user.get("name") || "",
        isAdmin: user.get("isAdmin") || false,
        isBanned: user.get("isBanned") || false,
        photoURL: user.get("photoURL") || null,
        cpf: user.get("cpf") || "",
        phone: user.get("phone") || "",
        walletBalance: user.get("balance") || 0,
        referralsCount: user.get("referralsCount") || 0,
        referredBy: user.get("referredBy") || "",
        xp: user.get("xp") || 0,
        league: user.get("league") || "Bronze",
        createdAt: user.createdAt
      };
    });
  } catch (error) {
    throw new Parse.Error(Parse.Error.INTERNAL_SERVER_ERROR, "Error fetching users: " + error.message);
  }
});

Parse.Cloud.define("grantAdminRole", async (request) => {
  const admin = request.user;
  if (!isAdminUser(admin, request)) throw new Parse.Error(Parse.Error.INVALID_SESSION_TOKEN, "Admin required.");
  const { objectId } = request.params;
  if (!objectId) throw new Parse.Error(Parse.Error.INVALID_QUERY, "objectId is required.");

  try {
    const query = new Parse.Query(Parse.User);
    const user = await query.get(objectId, { useMasterKey: true });
    user.set("isAdmin", true);
    await user.save(null, { useMasterKey: true });
    return { success: true, message: "Admin role granted." };
  } catch (error) {
    throw new Parse.Error(Parse.Error.INTERNAL_SERVER_ERROR, "Error granting admin role: " + error.message);
  }
});

Parse.Cloud.define("getFraudLogs", async (request) => {
  const admin = request.user;
  if (!isAdminUser(admin, request)) throw new Parse.Error(Parse.Error.INVALID_SESSION_TOKEN, "Admin required.");

  try {
    const FraudLog = Parse.Object.extend("FraudLog");
    const query = new Parse.Query(FraudLog);
    query.include("user");
    query.descending("createdAt");
    query.limit(100);
    const logs = await query.find({ useMasterKey: true });

    return logs.map(log => {
      const u = log.get("user");
      return {
        objectId: log.id,
        reason: log.get("reason") || "Atividade Suspeita",
        speedKmH: log.get("speedKmH") || null,
        eventId: log.get("eventId") || null,
        enigmaId: log.get("enigmaId") || null,
        createdAt: log.createdAt,
        user: u ? {
          objectId: u.id,
          name: u.get("name") || u.get("username") || "Explorador",
          email: u.get("email") || "",
          cpf: u.get("cpf") || "",
          isBanned: u.get("isBanned") || false
        } : null
      };
    });
  } catch (error) {
    throw new Parse.Error(Parse.Error.INTERNAL_SERVER_ERROR, "Erro ao buscar logs de fraude: " + error.message);
  }
});

Parse.Cloud.define("toggleBanUser", async (request) => {
  const admin = request.user;
  if (!isAdminUser(admin, request)) throw new Parse.Error(Parse.Error.INVALID_SESSION_TOKEN, "Admin required.");
  const { userId, isBanned } = request.params;
  if (!userId) throw new Parse.Error(Parse.Error.INVALID_QUERY, "userId is required.");

  try {
    const query = new Parse.Query(Parse.User);
    const user = await query.get(userId, { useMasterKey: true });
    user.set("isBanned", isBanned === true);
    await user.save(null, { useMasterKey: true });
    return { success: true, isBanned: isBanned === true, message: isBanned ? "Usuário banido com sucesso." : "Banimento removido." };
  } catch (error) {
    throw new Parse.Error(Parse.Error.INTERNAL_SERVER_ERROR, "Erro ao alterar banimento: " + error.message);
  }
});

Parse.Cloud.define("revokeAdminRole", async (request) => {
  const admin = request.user;
  if (!isAdminUser(admin, request)) throw new Parse.Error(Parse.Error.INVALID_SESSION_TOKEN, "Admin required.");
  const { objectId } = request.params;
  if (!objectId) throw new Parse.Error(Parse.Error.INVALID_QUERY, "objectId is required.");

  try {
    const query = new Parse.Query(Parse.User);
    const user = await query.get(objectId, { useMasterKey: true });
    user.set("isAdmin", false);
    await user.save(null, { useMasterKey: true });
    return { success: true, message: "Admin role revoked." };
  } catch (error) {
    throw new Parse.Error(Parse.Error.INTERNAL_SERVER_ERROR, "Error revoking admin role: " + error.message);
  }
});

Parse.Cloud.define("toggleUserBan", async (request) => {
  const admin = request.user;
  if (!isAdminUser(admin, request)) throw new Parse.Error(Parse.Error.INVALID_SESSION_TOKEN, "Admin required.");
  const { objectId } = request.params;
  if (!objectId) throw new Parse.Error(Parse.Error.INVALID_QUERY, "objectId is required.");

  try {
    const query = new Parse.Query(Parse.User);
    const user = await query.get(objectId, { useMasterKey: true });
    const currentBanStatus = user.get("isBanned") || false;
    user.set("isBanned", !currentBanStatus);
    await user.save(null, { useMasterKey: true });
    return { success: true, isBanned: !currentBanStatus };
  } catch (error) {
    throw new Parse.Error(Parse.Error.INTERNAL_SERVER_ERROR, "Error toggling user ban status: " + error.message);
  }
});

Parse.Cloud.define("createOrUpdateEvent", async (request) => {
  const user = request.user;
  if (!isAdminUser(user, request)) throw new Parse.Error(Parse.Error.INVALID_SESSION_TOKEN, "Admin required.");
  const { eventId, data } = request.params;

  try {
    const Event = Parse.Object.extend("Event");
    let event;

    if (eventId) {
      const query = new Parse.Query(Event);
      event = await query.get(eventId, { useMasterKey: true });
    } else {
      event = new Event();
    }

    if (data) {
      for (const key in data) {
        event.set(key, data[key]);
      }
    }

    await event.save(null, { useMasterKey: true });

    return { success: true, eventId: event.id };
  } catch (error) {
    throw new Parse.Error(Parse.Error.INTERNAL_SERVER_ERROR, "Error saving event: " + error.message);
  }
});

Parse.Cloud.define("deleteEvent", async (request) => {
  const user = request.user;
  if (!isAdminUser(user, request)) throw new Parse.Error(Parse.Error.INVALID_SESSION_TOKEN, "Admin required.");
  const { eventId } = request.params;
  if (!eventId) throw new Parse.Error(Parse.Error.INVALID_QUERY, "eventId is required.");

  try {
    const Event = Parse.Object.extend("Event");
    const query = new Parse.Query(Event);
    const event = await query.get(eventId, { useMasterKey: true });

    // Excluir fases e enigmas vinculados
    const Phase = Parse.Object.extend("Phase");
    const phaseQuery = new Parse.Query(Phase);
    phaseQuery.equalTo("event", event);
    const phases = await phaseQuery.find({ useMasterKey: true });
    for (const p of phases) {
      await p.destroy({ useMasterKey: true });
    }

    const Enigma = Parse.Object.extend("Enigma");
    const enigmaQuery = new Parse.Query(Enigma);
    enigmaQuery.equalTo("event", event);
    const enigmas = await enigmaQuery.find({ useMasterKey: true });
    for (const e of enigmas) {
      await e.destroy({ useMasterKey: true });
    }

    await event.destroy({ useMasterKey: true });
    return { success: true, message: "Event and associated records deleted." };
  } catch (error) {
    throw new Parse.Error(Parse.Error.INTERNAL_SERVER_ERROR, "Error deleting event: " + error.message);
  }
});

Parse.Cloud.define("createOrUpdateEnigma", async (request) => {
  const user = request.user;
  if (!isAdminUser(user, request)) throw new Parse.Error(Parse.Error.INVALID_SESSION_TOKEN, "Admin required.");
  const { enigmaId, eventId, phaseId, data } = request.params;

  try {
    const Enigma = Parse.Object.extend("Enigma");
    let enigma;

    if (enigmaId) {
      const query = new Parse.Query(Enigma);
      enigma = await query.get(enigmaId, { useMasterKey: true });
    } else {
      enigma = new Enigma();
    }

    if (eventId) {
      const Event = Parse.Object.extend("Event");
      const eventPointer = new Event();
      eventPointer.id = eventId;
      enigma.set("event", eventPointer);
      enigma.set("eventId", eventId);
    }

    if (phaseId) {
      const Phase = Parse.Object.extend("Phase");
      const phasePointer = new Phase();
      phasePointer.id = phaseId;
      enigma.set("phase", phasePointer);
      enigma.set("phaseId", phaseId);
    } else if (phaseId === null || phaseId === '') {
      enigma.unset("phase");
      enigma.unset("phaseId");
    }

    if (data) {
      for (const key in data) {
        if (key === "prize") {
          enigma.set("prize", String(data[key] !== undefined && data[key] !== null ? data[key] : "0"));
        } else if (key === "code") {
          enigma.set("code", String(data[key] !== undefined && data[key] !== null ? data[key] : "").trim());
        } else {
          enigma.set(key, data[key]);
        }
      }
    }

    // Se o evento for Classic, enigmas não possuem prêmio individual
    if (eventId) {
      const Event = Parse.Object.extend("Event");
      const evQuery = new Parse.Query(Event);
      const evObj = await evQuery.get(eventId, { useMasterKey: true });
      if (evObj && (evObj.get("eventType") === "classic" || evObj.get("eventType") === "Classic")) {
        enigma.set("prize", "0");
      }
    }

    await enigma.save(null, { useMasterKey: true });
    return { success: true, enigmaId: enigma.id };
  } catch (error) {
    throw new Parse.Error(Parse.Error.INTERNAL_SERVER_ERROR, "Error saving enigma: " + error.message);
  }
});

Parse.Cloud.define("deleteEnigma", async (request) => {
  const user = request.user;
  if (!isAdminUser(user, request)) throw new Parse.Error(Parse.Error.INVALID_SESSION_TOKEN, "Admin required.");
  const { enigmaId } = request.params;
  if (!enigmaId) throw new Parse.Error(Parse.Error.INVALID_QUERY, "enigmaId is required.");

  try {
    const Enigma = Parse.Object.extend("Enigma");
    const query = new Parse.Query(Enigma);
    const enigma = await query.get(enigmaId, { useMasterKey: true });
    await enigma.destroy({ useMasterKey: true });
    return { success: true, message: "Enigma deleted." };
  } catch (error) {
    throw new Parse.Error(Parse.Error.INTERNAL_SERVER_ERROR, "Error deleting enigma: " + error.message);
  }
});

Parse.Cloud.define("createOrUpdateHint", async (request) => {
  const user = request.user;
  if (!isAdminUser(user, request)) throw new Parse.Error(Parse.Error.INVALID_SESSION_TOKEN, "Admin required.");
  const { hintId, data } = request.params;

  try {
    const Hint = Parse.Object.extend("Hint");
    let hint;

    if (hintId) {
      const query = new Parse.Query(Hint);
      hint = await query.get(hintId, { useMasterKey: true });
    } else {
      hint = new Hint();
    }

    if (data) {
      for (const key in data) {
        hint.set(key, data[key]);
      }
    }

    await hint.save(null, { useMasterKey: true });
    return { success: true, hintId: hint.id };
  } catch (error) {
    throw new Parse.Error(Parse.Error.INTERNAL_SERVER_ERROR, "Error saving hint: " + error.message);
  }
});

Parse.Cloud.define("deleteHint", async (request) => {
  const user = request.user;
  if (!isAdminUser(user, request)) throw new Parse.Error(Parse.Error.INVALID_SESSION_TOKEN, "Admin required.");
  const { hintId } = request.params;
  if (!hintId) throw new Parse.Error(Parse.Error.INVALID_QUERY, "hintId is required.");

  try {
    const Hint = Parse.Object.extend("Hint");
    const query = new Parse.Query(Hint);
    const hint = await query.get(hintId, { useMasterKey: true });
    await hint.destroy({ useMasterKey: true });
    return { success: true, message: "Hint deleted." };
  } catch (error) {
    throw new Parse.Error(Parse.Error.INTERNAL_SERVER_ERROR, "Error deleting hint: " + error.message);
  }
});

Parse.Cloud.define("createOrUpdateBanner", async (request) => {
  const user = request.user;
  if (!isAdminUser(user, request)) throw new Parse.Error(Parse.Error.INVALID_SESSION_TOKEN, "Admin required.");
  const { bannerId, data } = request.params;

  try {
    const Banner = Parse.Object.extend("Banner");
    let banner;

    if (bannerId) {
      const query = new Parse.Query(Banner);
      banner = await query.get(bannerId, { useMasterKey: true });
    } else {
      banner = new Banner();
    }

    if (data) {
      for (const key in data) {
        banner.set(key, data[key]);
      }
    }

    await banner.save(null, { useMasterKey: true });
    return { success: true, bannerId: banner.id };
  } catch (error) {
    throw new Parse.Error(Parse.Error.INTERNAL_SERVER_ERROR, "Error saving banner: " + error.message);
  }
});

Parse.Cloud.define("deleteBanner", async (request) => {
  const user = request.user;
  if (!isAdminUser(user, request)) throw new Parse.Error(Parse.Error.INVALID_SESSION_TOKEN, "Admin required.");
  const { bannerId } = request.params;
  if (!bannerId) throw new Parse.Error(Parse.Error.INVALID_QUERY, "bannerId is required.");

  try {
    const Banner = Parse.Object.extend("Banner");
    const query = new Parse.Query(Banner);
    const banner = await query.get(bannerId, { useMasterKey: true });
    await banner.destroy({ useMasterKey: true });
    return { success: true, message: "Banner deleted." };
  } catch (error) {
    throw new Parse.Error(Parse.Error.INTERNAL_SERVER_ERROR, "Error deleting banner: " + error.message);
  }
});

Parse.Cloud.define("processWithdrawal", async (request) => {
  const adminUser = await resolveAdminUser(request);
  if (!adminUser) throw new Parse.Error(Parse.Error.INVALID_SESSION_TOKEN, "Acesso restrito a administradores.");
  const user = adminUser instanceof Parse.User ? adminUser : (request.user || adminUser);
  const { withdrawalId, objectId, action, receipt, rejectionReason } = request.params;
  if (!withdrawalId) throw new Parse.Error(Parse.Error.INVALID_QUERY, "withdrawalId is required.");

  try {
    const Withdrawal = Parse.Object.extend("Withdrawal");
    const query = new Parse.Query(Withdrawal);
    query.include("user");
    const withdrawal = await query.get(withdrawalId, { useMasterKey: true });

    const targetUserId = objectId || (withdrawal.get("user") ? withdrawal.get("user").id : null);
    let targetUser = null;
    if (targetUserId) {
      const userQuery = new Parse.Query(Parse.User);
      targetUser = await userQuery.get(targetUserId, { useMasterKey: true });
    }

    if (action === 'reject') {
      withdrawal.set("status", "rejected");
      withdrawal.set("rejectionReason", rejectionReason || "Solicitação rejeitada pelo administrador.");
      withdrawal.set("processedAt", new Date());
      withdrawal.set("processedByAdmin", user.id);
      await withdrawal.save(null, { useMasterKey: true });

      // Estorna o valor do saque imediatamente de volta para a carteira do usuário
      if (targetUser) {
        const currentBalance = parseMoney(targetUser.get("balance"));
        const amount = parseMoney(withdrawal.get("amount"));
        const newBalance = Number((currentBalance + amount).toFixed(2));
        targetUser.set("balance", newBalance);
        await targetUser.save(null, { useMasterKey: true });
      }

      // Atualiza transação correspondente se existir
      const qTx = new Parse.Query("Transaction");
      qTx.equalTo("withdrawalId", withdrawalId);
      const tx = await qTx.first({ useMasterKey: true });
      if (tx) {
        tx.set("status", "rejected");
        tx.set("rejectionReason", rejectionReason || "Rejeitado e estornado");
        await tx.save(null, { useMasterKey: true });
      }

      return {
        success: true,
        message: "Saque rejeitado e valor estornado para a carteira com sucesso!",
        status: "rejected"
      };
    } else if (action === 'auto_payout') {
      // PAGAMENTO AUTOMÁTICO VIA API (Asaas, Mercado Pago, Efi Bank)
      const payoutResult = await financialService.executeAutomaticPayout({
        withdrawal,
        targetUser,
        adminUser: user
      });

      const finalReceipt = payoutResult.receipt || `AUTOPAYOUT-${Date.now()}`;
      withdrawal.set("status", "completed");
      withdrawal.set("receipt", finalReceipt);
      withdrawal.set("payoutGateway", payoutResult.gateway || "api");
      withdrawal.set("payoutMethod", "auto_api");
      withdrawal.set("processedAt", new Date());
      withdrawal.set("processedByAdmin", user.id);
      await withdrawal.save(null, { useMasterKey: true });

      // Atualiza transação correspondente para 'completed'
      const qTx = new Parse.Query("Transaction");
      qTx.equalTo("withdrawalId", withdrawalId);
      const tx = await qTx.first({ useMasterKey: true });
      if (tx) {
        tx.set("status", "completed");
        tx.set("receipt", finalReceipt);
        tx.set("gateway", payoutResult.gateway || "api");
        await tx.save(null, { useMasterKey: true });
      }

      return {
        success: true,
        message: payoutResult.message || "Pagamento automático Pix realizado com sucesso!",
        receipt: finalReceipt,
        gateway: payoutResult.gateway,
        isSimulated: !!payoutResult.isSimulated,
        status: "completed"
      };
    } else {
      // APROVAÇÃO MANUAL (Comprovante informado ou padrão)
      const manualReceipt = receipt && receipt.trim().length > 0 ? receipt.trim() : "Transferência Pix manual confirmada pelo administrador";
      withdrawal.set("status", "completed");
      withdrawal.set("receipt", manualReceipt);
      withdrawal.set("payoutMethod", "manual");
      withdrawal.set("processedAt", new Date());
      withdrawal.set("processedByAdmin", user.id);
      await withdrawal.save(null, { useMasterKey: true });

      // Atualiza transação correspondente se existir
      const qTx = new Parse.Query("Transaction");
      qTx.equalTo("withdrawalId", withdrawalId);
      const tx = await qTx.first({ useMasterKey: true });
      if (tx) {
        tx.set("status", "completed");
        tx.set("receipt", manualReceipt);
        await tx.save(null, { useMasterKey: true });
      }

      return {
        success: true,
        message: "Saque aprovado manualmente com sucesso!",
        receipt: manualReceipt,
        status: "completed"
      };
    }
  } catch (error) {
    console.error("[processWithdrawal Error]", error);
    throw new Parse.Error(Parse.Error.INTERNAL_SERVER_ERROR, "Erro ao processar saque: " + error.message);
  }
});

Parse.Cloud.define("approveDepositManual", async (request) => {
  const adminUser = await resolveAdminUser(request);
  if (!adminUser) throw new Parse.Error(Parse.Error.INVALID_SESSION_TOKEN, "Acesso restrito a administradores.");
  const user = adminUser instanceof Parse.User ? adminUser : (request.user || adminUser);
  const { transactionId } = request.params;
  if (!transactionId) throw new Parse.Error(Parse.Error.INVALID_QUERY, "transactionId is required.");

  try {
    const Transaction = Parse.Object.extend("Transaction");
    const query = new Parse.Query(Transaction);
    const tx = await query.get(transactionId, { useMasterKey: true });

    if (tx.get("status") === "approved") {
      return { success: true, message: "Transação já estava aprovada." };
    }

    tx.set("status", "approved");
    tx.set("approvedAt", new Date());
    tx.set("manualApprovalBy", user.id);
    await tx.save(null, { useMasterKey: true });

    const targetUser = tx.get("user");
    if (targetUser) {
      await targetUser.fetch({ useMasterKey: true });
      const currentBalance = parseMoney(targetUser.get("balance"));
      const amount = parseMoney(tx.get("amount"));
      targetUser.set("balance", Number((currentBalance + amount).toFixed(2)));
      await targetUser.save(null, { useMasterKey: true });
    }

    return { success: true, message: "Depósito aprovado com sucesso e saldo creditado." };
  } catch (error) {
    throw new Parse.Error(Parse.Error.INTERNAL_SERVER_ERROR, "Erro ao aprovar depósito: " + error.message);
  }
});

Parse.Cloud.define("cancelDeposit", async (request) => {
  const adminUser = await resolveAdminUser(request);
  if (!adminUser) throw new Parse.Error(Parse.Error.INVALID_SESSION_TOKEN, "Acesso restrito a administradores.");
  const user = adminUser instanceof Parse.User ? adminUser : (request.user || adminUser);
  const { transactionId, reason } = request.params;
  if (!transactionId) throw new Parse.Error(Parse.Error.INVALID_QUERY, "transactionId is required.");

  try {
    const Transaction = Parse.Object.extend("Transaction");
    const query = new Parse.Query(Transaction);
    const tx = await query.get(transactionId, { useMasterKey: true });

    if (tx.get("status") === "approved" || tx.get("status") === "completed") {
      throw new Error("Não é possível cancelar uma transação já aprovada e creditada.");
    }

    tx.set("status", "cancelled");
    tx.set("cancellationReason", reason || "Cancelado pelo administrador.");
    tx.set("cancelledAt", new Date());
    tx.set("cancelledByAdmin", user.id);
    await tx.save(null, { useMasterKey: true });

    return { success: true, message: "Depósito pendente cancelado com sucesso." };
  } catch (error) {
    throw new Parse.Error(Parse.Error.INTERNAL_SERVER_ERROR, "Erro ao cancelar depósito: " + error.message);
  }
});

Parse.Cloud.define("getAdminFinancialData", async (request) => {
  const adminUser = await resolveAdminUser(request);
  if (!adminUser) {
    throw new Parse.Error(Parse.Error.INVALID_SESSION_TOKEN, "Acesso restrito a administradores.");
  }

  try {
    const wQuery = new Parse.Query("Withdrawal");
    wQuery.include("user");
    wQuery.descending("createdAt");
    wQuery.limit(500);
    const withdrawals = await wQuery.find({ useMasterKey: true });

    const tQuery = new Parse.Query("Transaction");
    tQuery.include("user");
    tQuery.descending("createdAt");
    tQuery.limit(1000);
    const transactions = await tQuery.find({ useMasterKey: true });

    const serializedWithdrawals = withdrawals.map(w => {
      const json = w.toJSON();
      const u = w.get("user");
      const userName = w.get("userName") || (u ? (u.get("name") || u.get("username")) : "") || "Jogador";
      const userEmail = w.get("userEmail") || (u ? u.get("email") : "") || "";
      const userId = u ? u.id : (w.get("userId") || "");

      return {
        ...json,
        objectId: w.id,
        amount: parseMoney(w.get("amount")),
        status: w.get("status") || "pending",
        pixKey: w.get("pixKey") || "",
        pixKeyType: w.get("pixKeyType") || "CHAVE_ALEATORIA",
        userName: userName,
        userEmail: userEmail,
        userId: userId,
        approvedBy: w.get("approvedBy") || "",
        rejectionReason: w.get("rejectionReason") || "",
        receipt: w.get("receipt") || null,
        payoutGateway: w.get("payoutGateway") || w.get("gateway") || "",
        payoutMethod: w.get("payoutMethod") || "",
        processedAt: w.get("processedAt") ? w.get("processedAt").toISOString() : null,
        createdAt: w.createdAt ? w.createdAt.toISOString() : (json.createdAt || null),
        updatedAt: w.updatedAt ? w.updatedAt.toISOString() : (json.updatedAt || null),
      };
    });

    const serializedTransactions = transactions.map(t => {
      const json = t.toJSON();
      const u = t.get("user");
      const userName = (u ? (u.get("name") || u.get("username")) : "") || "Jogador";
      const userEmail = (u ? u.get("email") : "") || "";
      const userId = u ? u.id : "";

      return {
        ...json,
        objectId: t.id,
        amount: parseMoney(t.get("amount")),
        type: t.get("type") || "other",
        status: t.get("status") || "pending",
        description: t.get("description") || "",
        gateway: t.get("gateway") || "",
        pixKey: t.get("pixKey") || "",
        pixKeyType: t.get("pixKeyType") || "",
        withdrawalId: t.get("withdrawalId") || "",
        receipt: t.get("receipt") || null,
        rejectionReason: t.get("rejectionReason") || "",
        userName: userName,
        userEmail: userEmail,
        userId: userId,
        createdAt: t.createdAt ? t.createdAt.toISOString() : (json.createdAt || null),
        updatedAt: t.updatedAt ? t.updatedAt.toISOString() : (json.updatedAt || null),
      };
    });

    return {
      success: true,
      withdrawals: serializedWithdrawals,
      transactions: serializedTransactions,
    };
  } catch (error) {
    console.error("[getAdminFinancialData Error]", error);
    throw new Parse.Error(Parse.Error.INTERNAL_SERVER_ERROR, "Erro ao processar dados financeiros: " + error.message);
  }
});

Parse.Cloud.define("toggleEventStatus", async (request) => {
  const { eventId, newStatus } = request.params;
  const user = request.user;
  if (!isAdminUser(user, request)) throw new Parse.Error(Parse.Error.INVALID_SESSION_TOKEN, "Admin required.");
  if (!eventId || !newStatus) throw new Parse.Error(Parse.Error.INVALID_QUERY, "eventId and newStatus are required.");

  try {
    const Event = Parse.Object.extend("Event");
    const query = new Parse.Query(Event);
    const event = await query.get(eventId, { useMasterKey: true });
    event.set("status", newStatus);
    await event.save(null, { useMasterKey: true });
    return { success: true };
  } catch (error) {
    throw new Parse.Error(Parse.Error.INTERNAL_SERVER_ERROR, error.message);
  }
});

Parse.Cloud.define("getFindAndWinStats", async (request) => {
  const { eventId } = request.params;
  const user = request.user;
  if (!isAdminUser(user, request)) throw new Parse.Error(Parse.Error.INVALID_SESSION_TOKEN, "Admin required.");
  if (!eventId) throw new Parse.Error(Parse.Error.INVALID_QUERY, "eventId is required.");

  try {
    const userQuery = new Parse.Query(Parse.User);
    const totalSubscribed = await userQuery.count({ useMasterKey: true });
    return { totalPlayers: totalSubscribed, completionRate: 0 };
  } catch (error) {
    throw new Parse.Error(Parse.Error.INTERNAL_SERVER_ERROR, error.message);
  }
});

Parse.Cloud.define("createOrUpdatePhase", async (request) => {
  const { eventId, phaseId, data } = request.params;
  const user = request.user;
  if (!isAdminUser(user, request)) throw new Parse.Error(Parse.Error.INVALID_SESSION_TOKEN, "Admin required.");
  if (!eventId) throw new Parse.Error(Parse.Error.INVALID_QUERY, "eventId is required.");

  try {
    const Phase = Parse.Object.extend("Phase");
    let phase;

    if (phaseId) {
      const query = new Parse.Query(Phase);
      phase = await query.get(phaseId, { useMasterKey: true });
    } else {
      phase = new Phase();
      const Event = Parse.Object.extend("Event");
      const eventPointer = new Event();
      eventPointer.id = eventId;
      phase.set("event", eventPointer);
      phase.set("eventId", eventId);
    }

    if (data) {
      for (const key in data) {
        phase.set(key, data[key]);
      }
    }

    await phase.save(null, { useMasterKey: true });
    return { success: true, phaseId: phase.id };
  } catch (error) {
    throw new Parse.Error(Parse.Error.INTERNAL_SERVER_ERROR, "Error saving phase: " + error.message);
  }
});

Parse.Cloud.define("deletePhase", async (request) => {
  const { eventId, phaseId } = request.params;
  const user = request.user;
  if (!isAdminUser(user, request)) throw new Parse.Error(Parse.Error.INVALID_SESSION_TOKEN, "Admin required.");
  if (!phaseId) throw new Parse.Error(Parse.Error.INVALID_QUERY, "phaseId is required.");

  try {
    const Phase = Parse.Object.extend("Phase");
    const query = new Parse.Query(Phase);
    const phase = await query.get(phaseId, { useMasterKey: true });

    // Excluir enigmas pertencentes a esta fase
    const Enigma = Parse.Object.extend("Enigma");
    const enigmaQuery = new Parse.Query(Enigma);
    enigmaQuery.equalTo("phase", phase);
    const phaseEnigmas = await enigmaQuery.find({ useMasterKey: true });
    for (const e of phaseEnigmas) {
      await e.destroy({ useMasterKey: true });
    }

    await phase.destroy({ useMasterKey: true });
    return { success: true, message: "Fase e enigmas excluídos." };
  } catch (error) {
    throw new Parse.Error(Parse.Error.INTERNAL_SERVER_ERROR, "Error deleting phase: " + error.message);
  }
});

Parse.Cloud.define("assignHintToEnigma", async (request) => {
  const user = request.user;
  if (!isAdminUser(user, request)) throw new Parse.Error(Parse.Error.INVALID_SESSION_TOKEN, "Admin required.");

  const { hintId, enigmaId, eventId, eventName } = request.params;

  if (!hintId) throw new Parse.Error(400, "hintId is required.");

  const Hint = Parse.Object.extend("Hint");
  const hintQuery = new Parse.Query(Hint);
  const hint = await hintQuery.get(hintId, { useMasterKey: true });

  const Enigma = Parse.Object.extend("Enigma");

  if (!enigmaId) {
    const currentEnigmaId = hint.get("linkedEnigmaId");
    if (currentEnigmaId) {
      const enigmaQuery = new Parse.Query(Enigma);
      try {
        const oldEnigma = await enigmaQuery.get(currentEnigmaId, { useMasterKey: true });
        oldEnigma.remove("linkedHints", hintId);
        await oldEnigma.save(null, { useMasterKey: true });
      } catch (e) {
        // Enigma might have been deleted, ignore
      }
    }
    hint.unset("linkedEnigmaId");
    hint.unset("linkedEventName");
    hint.unset("linkedEventId");
    await hint.save(null, { useMasterKey: true });
    return { success: true };
  }

  if (hint.get("linkedEnigmaId")) {
    throw new Parse.Error(400, "Dica já está vinculada a outro enigma. Desvincule primeiro.");
  }

  const enigmaQuery = new Parse.Query(Enigma);
  const enigma = await enigmaQuery.get(enigmaId, { useMasterKey: true });

  enigma.addUnique("linkedHints", hintId);
  await enigma.save(null, { useMasterKey: true });

  hint.set("linkedEnigmaId", enigmaId);
  hint.set("linkedEventId", eventId);
  hint.set("linkedEventName", eventName || "Evento");
  await hint.save(null, { useMasterKey: true });

  return { success: true };
});

Parse.Cloud.define("updateUserRole", async (request) => {
  const admin = request.user;
  if (!isAdminUser(admin, request)) throw new Parse.Error(Parse.Error.INVALID_SESSION_TOKEN, "Admin required.");

  const { objectId, role } = request.params;
  if (!objectId) throw new Parse.Error(Parse.Error.INVALID_QUERY, "objectId is required.");
  if (!role) throw new Parse.Error(Parse.Error.INVALID_QUERY, "role is required.");

  try {
    const query = new Parse.Query(Parse.User);
    const user = await query.get(objectId, { useMasterKey: true });
    user.set("role", role);
    await user.save(null, { useMasterKey: true });
    return { success: true, message: "User role updated successfully." };
  } catch (error) {
    throw new Parse.Error(Parse.Error.INTERNAL_SERVER_ERROR, "Error updating user role: " + error.message);
  }
});

// Parse Cloud Code for Back4App - Admin Functions

Parse.Cloud.define("getAdminDashboardData", async (request) => {
  const user = request.user;
  if (!user || !user.get("isAdmin")) throw new Parse.Error(Parse.Error.INVALID_SESSION_TOKEN, "Admin required.");
  try {
    const usersQuery = new Parse.Query(Parse.User);
    const usersCount = await usersQuery.count({ useMasterKey: true });

    const eventsQuery = new Parse.Query("Event");
    eventsQuery.equalTo("status", "published");
    const activeEventsCount = await eventsQuery.count({ useMasterKey: true });

    const depositsQuery = new Parse.Query("Transaction");
    depositsQuery.equalTo("type", "deposit");
    const totalDepositsCount = await depositsQuery.count({ useMasterKey: true });

    const withdrawalsQuery = new Parse.Query("Withdrawal");
    withdrawalsQuery.equalTo("status", "pending");
    const pendingWithdrawalsCount = await withdrawalsQuery.count({ useMasterKey: true });

    return {
      users: usersCount,
      activeEvents: activeEventsCount,
      totalDeposits: totalDepositsCount,
      pendingWithdrawals: pendingWithdrawalsCount
    };
  } catch (error) {
    throw new Parse.Error(Parse.Error.INTERNAL_SERVER_ERROR, "Error fetching dashboard data: " + error.message);
  }
});

Parse.Cloud.define("listAllUsers", async (request) => {
  const user = request.user;
  if (!user || !user.get("isAdmin")) throw new Parse.Error(Parse.Error.INVALID_SESSION_TOKEN, "Admin required.");
  try {
    const query = new Parse.Query(Parse.User);
    query.limit(1000); // Set appropriate limit
    const users = await query.find({ useMasterKey: true });

    return users.map(user => {
      return {
        objectId: user.id, // using objectId, frontend should expect this or we return it as objectId
        email: user.get("email") || "",
        name: user.get("name") || "",
        isAdmin: user.get("isAdmin") || false,
        isBanned: user.get("isBanned") || false,
        photoURL: user.get("photoURL") || null,
        walletBalance: user.get("balance") || 0,
        createdAt: user.createdAt
      };
    });
  } catch (error) {
    throw new Parse.Error(Parse.Error.INTERNAL_SERVER_ERROR, "Error fetching users: " + error.message);
  }
});

Parse.Cloud.define("grantAdminRole", async (request) => {
  const admin = request.user;
  if (!admin || !admin.get("isAdmin")) throw new Parse.Error(Parse.Error.INVALID_SESSION_TOKEN, "Admin required.");
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

Parse.Cloud.define("revokeAdminRole", async (request) => {
  const admin = request.user;
  if (!admin || !admin.get("isAdmin")) throw new Parse.Error(Parse.Error.INVALID_SESSION_TOKEN, "Admin required.");
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
  if (!admin || !admin.get("isAdmin")) throw new Parse.Error(Parse.Error.INVALID_SESSION_TOKEN, "Admin required.");
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
  if (!user || !user.get("isAdmin")) throw new Parse.Error(Parse.Error.INVALID_SESSION_TOKEN, "Admin required.");
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
  if (!user || !user.get("isAdmin")) throw new Parse.Error(Parse.Error.INVALID_SESSION_TOKEN, "Admin required.");
  const { eventId } = request.params;
  if (!eventId) throw new Parse.Error(Parse.Error.INVALID_QUERY, "eventId is required.");

  try {
    const Event = Parse.Object.extend("Event");
    const query = new Parse.Query(Event);
    const event = await query.get(eventId, { useMasterKey: true });
    await event.destroy({ useMasterKey: true });
    return { success: true, message: "Event deleted." };
  } catch (error) {
    throw new Parse.Error(Parse.Error.INTERNAL_SERVER_ERROR, "Error deleting event: " + error.message);
  }
});

Parse.Cloud.define("createOrUpdateEnigma", async (request) => {
  const user = request.user;
  if (!user || !user.get("isAdmin")) throw new Parse.Error(Parse.Error.INVALID_SESSION_TOKEN, "Admin required.");
  const { enigmaId, eventId, phaseId, data } = request.params;

  try {
    const Enigma = Parse.Object.extend("Enigma");
    let enigma;

    if (enigmaId) {
      const query = new Parse.Query(Enigma);
      enigma = await query.get(enigmaId, { useMasterKey: true });
    } else {
      enigma = new Enigma();
      if (eventId) {
        const Event = Parse.Object.extend("Event");
        const eventPointer = new Event();
        eventPointer.id = eventId;
        enigma.set("event", eventPointer);
        // also store id string to match frontend logic
        enigma.set("eventId", eventId);
      }
      if (phaseId) {
        const Phase = Parse.Object.extend("Phase");
        const phasePointer = new Phase();
        phasePointer.id = phaseId;
        enigma.set("phase", phasePointer);
        enigma.set("phaseId", phaseId);
      }
    }

    if (data) {
      for (const key in data) {
        enigma.set(key, data[key]);
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
  if (!user || !user.get("isAdmin")) throw new Parse.Error(Parse.Error.INVALID_SESSION_TOKEN, "Admin required.");
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
  if (!user || !user.get("isAdmin")) throw new Parse.Error(Parse.Error.INVALID_SESSION_TOKEN, "Admin required.");
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
  if (!user || !user.get("isAdmin")) throw new Parse.Error(Parse.Error.INVALID_SESSION_TOKEN, "Admin required.");
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
  if (!user || !user.get("isAdmin")) throw new Parse.Error(Parse.Error.INVALID_SESSION_TOKEN, "Admin required.");
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
  if (!user || !user.get("isAdmin")) throw new Parse.Error(Parse.Error.INVALID_SESSION_TOKEN, "Admin required.");
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
  const user = request.user;
  if (!user || !user.get("isAdmin")) throw new Parse.Error(Parse.Error.INVALID_SESSION_TOKEN, "Admin required.");
  const { withdrawalId, objectId, action } = request.params;
  if (!withdrawalId) throw new Parse.Error(Parse.Error.INVALID_QUERY, "withdrawalId is required.");

  try {
    const Withdrawal = Parse.Object.extend("Withdrawal");
    const query = new Parse.Query(Withdrawal);
    const withdrawal = await query.get(withdrawalId, { useMasterKey: true });

    if (action === 'reject') {
      withdrawal.set("status", "rejected");
      await withdrawal.save(null, { useMasterKey: true });

      if (objectId) {
        const userQuery = new Parse.Query(Parse.User);
        const targetUser = await userQuery.get(objectId, { useMasterKey: true });
        const currentBalance = targetUser.get("balance") || 0.0;
        const amount = withdrawal.get("amount") || 0.0;
        targetUser.set("balance", currentBalance + amount);
        await targetUser.save(null, { useMasterKey: true });
      }
      return { success: true, message: "Withdrawal rejected and refunded." };
    } else {
      withdrawal.set("status", "completed");
      await withdrawal.save(null, { useMasterKey: true });
      return { success: true, message: "Withdrawal approved and processed." };
    }
  } catch (error) {
    throw new Parse.Error(Parse.Error.INTERNAL_SERVER_ERROR, "Error processing withdrawal: " + error.message);
  }
});

Parse.Cloud.define("toggleEventStatus", async (request) => {
  const { eventId, newStatus } = request.params;
  const user = request.user;
  if (!user || !user.get("isAdmin")) throw new Parse.Error(Parse.Error.INVALID_SESSION_TOKEN, "Admin required.");
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
  if (!user || !user.get("isAdmin")) throw new Parse.Error(Parse.Error.INVALID_SESSION_TOKEN, "Admin required.");
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
  if (!user || !user.get("isAdmin")) throw new Parse.Error(Parse.Error.INVALID_SESSION_TOKEN, "Admin required.");
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
  if (!user || !user.get("isAdmin")) throw new Parse.Error(Parse.Error.INVALID_SESSION_TOKEN, "Admin required.");
  if (!phaseId) throw new Parse.Error(Parse.Error.INVALID_QUERY, "phaseId is required.");

  try {
    const Phase = Parse.Object.extend("Phase");
    const query = new Parse.Query(Phase);
    const phase = await query.get(phaseId, { useMasterKey: true });
    await phase.destroy({ useMasterKey: true });
    return { success: true };
  } catch (error) {
    throw new Parse.Error(Parse.Error.INTERNAL_SERVER_ERROR, "Error deleting phase: " + error.message);
  }
});

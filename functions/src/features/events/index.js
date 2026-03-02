const {onCall, HttpsError} = require("firebase-functions/v2/https");
const admin = require("firebase-admin");
const db = admin.firestore();

// =================================================================== //
// PUBLIC EVENT FUNCTIONS
// =================================================================== //

exports.getEventData = onCall(async (request) => {
  const eventId = request.data ? request.data.eventId : null;

  if (!eventId) {
    const eventsSnapshot = await db.collection("events").get();
    return eventsSnapshot.docs.map((doc) => ({id: doc.id, ...doc.data()}));
  } else {
    const eventDoc = await db.collection("events").doc(eventId).get();
    if (!eventDoc.exists) throw new HttpsError("not-found", "Evento não encontrado.");

    const eventData = {id: eventDoc.id, ...eventDoc.data()};
    const eventType = eventData.eventType || "classic";

    if (eventType === "find_and_win") {
      const enigmasSnapshot = await eventDoc.ref.collection("enigmas").orderBy("order").get();
      eventData.enigmas = enigmasSnapshot.docs.map((doc) => ({id: doc.id, ...doc.data()}));
      eventData.phases = [];
    } else {
      const phasesSnapshot = await eventDoc.ref.collection("phases").orderBy("order").get();
      const phasesList = [];
      for (const phaseDoc of phasesSnapshot.docs) {
        const enigmasSnapshot = await phaseDoc.ref.collection("enigmas").get();
        const enigmas = enigmasSnapshot.docs.map((eDoc) => ({id: eDoc.id, ...eDoc.data()}));
        phasesList.push({id: phaseDoc.id, ...phaseDoc.data(), enigmas});
      }
      eventData.phases = phasesList;
      eventData.enigmas = [];
    }
    return eventData;
  }
});

exports.getEventRanking = onCall(async (request) => {
  const {eventId} = request.data;
  if (!eventId) throw new HttpsError("invalid-argument", "O ID do evento é obrigatório.");

  const phasesSnapshot = await db.collection("events").doc(eventId).collection("phases").get();
  const totalPhases = phasesSnapshot.docs.length;
  if (totalPhases === 0) return [];

  const playersSnapshot = await db.collection("players").get();
  const rankedPlayers = [];
  for (const playerDoc of playersSnapshot.docs) {
    const playerData = playerDoc.data();
    const progress = playerData.events?.[eventId];
    const phasesCompleted = progress ? (progress.currentPhase - 1) : 0;
    rankedPlayers.push({
      uid: playerDoc.id,
      name: playerData.name || "Anônimo",
      photoURL: playerData.photoURL || null,
      phasesCompleted: phasesCompleted,
      totalPhases: totalPhases,
    });
  }
  rankedPlayers.sort((a, b) => b.phasesCompleted - a.phasesCompleted);
  return rankedPlayers.map((player, index) => ({...player, position: index + 1}));
});

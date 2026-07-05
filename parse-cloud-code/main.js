
Parse.Cloud.define("requestWithdrawal", async (request) => {
  const { amount, pixKey } = request.params;
  // Stub for logic migrated to Parse
  return { success: true, message: "Saque solicitado." };
});

Parse.Cloud.define("calculateRanking", async (request) => {
  const { eventId } = request.params;
  // Stub for logic migrated to Parse
  return { success: true, message: "Ranking calculado." };
});

Parse.Cloud.define("createPixCharge", async (request) => {
  const { amount } = request.params;
  // Stub for logic migrated to Parse
  return { qrCodeImage: "mockBase64", copiaCola: "mockCode", txid: "123" };
});

Parse.Cloud.define("scan_enigma", async (request) => {
  // Stub for logic migrated to Parse
  return { success: true, message: "Enigma escaneado com sucesso." };
});

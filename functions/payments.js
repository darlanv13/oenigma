const { onCall, onRequest, HttpsError } = require("firebase-functions/v2/https");
const admin = require("firebase-admin");
const { MercadoPagoConfig, Payment } = require('mercadopago');
const { v4: uuidv4 } = require('uuid');

const db = admin.firestore();

// Substitua pelo seu Access Token real do Mercado Pago (Preferencialmente use secret manager em PRD)
const MP_ACCESS_TOKEN = "TEST-86000000000000-000000-0000000000000000000000000000-000000";
const client = new MercadoPagoConfig({ accessToken: MP_ACCESS_TOKEN });

exports.createPixCharge = onCall(async (request) => {
    if (!request.auth) {
        throw new HttpsError("unauthenticated", "O usuário precisa estar logado.");
    }

    const userId = request.auth.uid;
    const amount = request.data.amount;

    if (!amount || amount < 1) {
        throw new HttpsError("invalid-argument", "Valor inválido para recarga (Mínimo R$ 1,00).");
    }

    try {
        const userDoc = await db.collection("players").doc(userId).get();
        if (!userDoc.exists) {
            throw new HttpsError("not-found", "Cadastro do usuário não encontrado.");
        }

        const userData = userDoc.data();
        const storedCpf = userData.cpf;
        const userName = userData.name || "Usuario Oenigma";
        const email = userData.email || "email@sandbox.com";

        if (!storedCpf) {
            throw new HttpsError("failed-precondition", "CPF não encontrado no cadastro.");
        }

        const cpfClean = storedCpf.replace(/\D/g, '');

        const payment = new Payment(client);
        const idempotencyKey = uuidv4();

        const body = {
            transaction_amount: Number(amount),
            description: "Créditos no App O Enigma",
            payment_method_id: "pix",
            payer: {
                email: email,
                first_name: userName,
                identification: {
                    type: "CPF",
                    number: cpfClean
                }
            }
        };

        const mpResponse = await payment.create({
            body,
            requestOptions: { idempotencyKey }
        });

        const txid = mpResponse.id.toString();
        const qrCodeText = mpResponse.point_of_interaction.transaction_data.qr_code;
        const qrCodeImage = mpResponse.point_of_interaction.transaction_data.qr_code_base64;

        await db.collection("transactions").doc(txid).set({
            userId: userId,
            amount: parseFloat(amount),
            status: "pending",
            createdAt: admin.firestore.FieldValue.serverTimestamp(),
            txid: txid,
            qrCodeText: qrCodeText,
            paymentMethod: "pix_mercadopago"
        });

        return {
            success: true,
            txid: txid,
            qrCodeImage: `data:image/png;base64,${qrCodeImage}`,
            copiaCola: qrCodeText
        };

    } catch (error) {
        console.error("Erro ao criar Pix via Mercado Pago:", error);
        throw new HttpsError("internal", "Falha ao gerar Pix: " + error.message);
    }
});

// Admin-Only Function
exports.processWithdrawal = onCall(async (request) => {
    if (!request.auth) {
        throw new HttpsError("unauthenticated", "User must be logged in.");
    }
    const isAdmin = request.auth.token.super_admin === true || request.auth.token.editor === true;
    if (!isAdmin) {
        throw new HttpsError("permission-denied", "User does not have admin privileges.");
    }

    const { withdrawalId, uid, action } = request.data;
    if (!withdrawalId || !uid || !action) {
        throw new HttpsError("invalid-argument", "Missing arguments.");
    }

    const withdrawalRef = db.collection("withdrawals").doc(withdrawalId);
    const userRef = db.collection("players").doc(uid);

    return await db.runTransaction(async (t) => {
        const withdrawalDoc = await t.get(withdrawalRef);
        if (!withdrawalDoc.exists || withdrawalDoc.data().status !== "pending") {
            throw new HttpsError("failed-precondition", "Withdrawal not found or already processed.");
        }

        const amount = withdrawalDoc.data().amount;

        if (action === "approve") {
            // Em Produção: Aqui você chamaria a API de Transferência Pix (Payout) do seu Gateway/Banco.
            // Ex: MercadoPago Payout API ou Gateway manual.

            t.update(withdrawalRef, {
                status: "completed",
                processedAt: admin.firestore.FieldValue.serverTimestamp(),
                processedBy: request.auth.uid
            });

            return { success: true, message: "Saque aprovado e Pix disparado (Simulado)." };

        } else if (action === "reject") {
            // Devolve o saldo pro usuário
            t.update(userRef, {
                balance: admin.firestore.FieldValue.increment(amount)
            });

            t.update(withdrawalRef, {
                status: "rejected",
                processedAt: admin.firestore.FieldValue.serverTimestamp(),
                processedBy: request.auth.uid
            });

            return { success: true, message: "Saque rejeitado. Saldo devolvido." };
        } else {
            throw new HttpsError("invalid-argument", "Invalid action.");
        }
    });
});

exports.pixWebhook = onRequest({ cors: true }, async (req, res) => {
    // Tratamento de Webhook do Mercado Pago
    const topic = req.query.topic || req.body.type;
    const id = req.query.id || req.body.data?.id;

    if (!id) {
        return res.status(200).send("No ID provided");
    }

    if (topic === "payment") {
        try {
            const payment = new Payment(client);
            const paymentInfo = await payment.get({ id });

            if (paymentInfo.status === "approved") {
                const txid = paymentInfo.id.toString();

                const transactionRef = db.collection("transactions").doc(txid);

                await db.runTransaction(async (t) => {
                    const doc = await t.get(transactionRef);
                    if (!doc.exists || doc.data().status === 'approved') return;

                    const userId = doc.data().userId;
                    const amount = Number(doc.data().amount);
                    const playerRef = db.collection("players").doc(userId);

                    t.update(transactionRef, {
                        status: "approved",
                        paidAt: admin.firestore.FieldValue.serverTimestamp()
                    });

                    t.update(playerRef, {
                        balance: admin.firestore.FieldValue.increment(amount)
                    });
                });
            }
        } catch (error) {
            console.error("Webhook Error:", error);
            return res.status(500).send("Error");
        }
    }

    res.status(200).send("OK");
});

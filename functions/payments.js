const { onCall, onRequest, HttpsError } = require("firebase-functions/v2/https");
const admin = require("firebase-admin");
const EfiPay = require("sdk-node-apis-efi");
const path = require("path");

const db = admin.firestore();

// Configure suas credenciais aqui ou use variáveis de ambiente (Recomendado)
const options = {
    // SE MUDAR PARA TRUE, USE O CERTIFICADO E CREDENCIAIS DE HOMOLOGAÇÃO
    sandbox: false,
    client_id: "Client_Id_4b4ab1903a7db8fef763f5e9fd42cde6cc568a1d",
    client_secret: "Client_Secret_a19e15526954e679c0e0e2ee0cb8209dc524bf52",
    // O certificado deve estar na pasta functions/certs
    certificate: path.resolve(__dirname, "certs/producao-644069-producaoenigma.p12"),
    cert_base64: false
};

// functions/payments.js

exports.createPixCharge = onCall(async (request) => {
    // 1. Verificação de Autenticação
    if (!request.auth) {
        throw new HttpsError("unauthenticated", "O usuário precisa estar logado.");
    }

    const userId = request.auth.uid;
    const amount = request.data.amount; // Valor vindo do App

    if (!amount || amount < 1) {
        throw new HttpsError("invalid-argument", "Valor inválido para recarga (Mínimo R$ 1,00).");
    }

    try {
        // 2. BUSCAR DADOS DO USUÁRIO NO FIRESTORE (CPF e NOME)
        const userDoc = await db.collection("players").doc(userId).get();

        if (!userDoc.exists) {
            throw new HttpsError("not-found", "Cadastro do usuário não encontrado.");
        }

        const userData = userDoc.data();

        // Variável que pega o CPF do banco de dados
        // Importante: Certifique-se que no cadastro o campo chama 'cpf'
        const storedCpf = userData.cpf;
        const userName = userData.name || "Usuario Oenigma";

        if (!storedCpf) {
            throw new HttpsError("failed-precondition", "CPF não encontrado no cadastro. Por favor, atualize seu perfil.");
        }

        // Limpa o CPF (deixa apenas números) para evitar erros na API
        const cpfClean = storedCpf.replace(/\D/g, '');

        // 3. Preparar a cobrança Pix
        const efipay = new EfiPay(options);

        const body = {
            calendario: {
                expiracao: 3600 // 1 hora
            },
            devedor: {
                nome: userName, // Obrigatório ser 'nome'
                cpf: cpfClean   // CPF vindo do banco de dados
            },
            valor: {
                original: amount.toFixed(2)
            },
            chave: "9d65f7ad-d202-4323-8645-a07be6076ec3", // <--- CONFIRA SUA CHAVE AQUI
            solicitacaoPagador: "Creditos no App Oenigma"
        };

        // 4. Criar a cobrança na EfiPay
        const charge = await efipay.pixCreateImmediateCharge([], body);

        // 5. Gerar o QR Code
        const params = {
            id: charge.loc.id
        };
        const qrcode = await efipay.pixGenerateQRCode(params);

        // 6. Salvar a transação no Firestore
        await db.collection("transactions").doc(charge.txid).set({
            userId: userId,
            amount: parseFloat(amount),
            status: "pending",
            createdAt: admin.firestore.FieldValue.serverTimestamp(),
            txid: charge.txid,
            qrCodeImage: qrcode.imagemQrcode,
            qrCodeText: qrcode.qrcode,
            paymentMethod: "pix_efi"
        });

        // 7. Retornar ao App
        return {
            success: true,
            txid: charge.txid,
            qrCodeImage: qrcode.imagemQrcode,
            copiaCola: qrcode.qrcode
        };

    } catch (error) {
        console.error("Erro ao criar Pix:", error);
        // Retorna o erro detalhado para facilitar o debug no app
        const detalhes = error.error_description || error.message || JSON.stringify(error);
        throw new HttpsError("internal", "Falha ao gerar Pix: " + detalhes);
    }
});

// ==========================================================
// 1. FUNÇÃO WEBHOOK (Recebe a notificação da EfiPay)
// ==========================================================
exports.pixWebhook = onRequest({ cors: true }, async (req, res) => {
    // A EfiPay envia um POST com os dados do pagamento
    const body = req.body;

    // Validação básica para ver se é uma requisição da EfiPay
    if (!body || !body.pix) {
        // A EfiPay faz uma chamada de teste ao configurar o webhook sem o campo 'pix'.
        // Devemos retornar 200 OK para validar o cadastro.
        return res.status(200).send("Webhook Validade");
    }

    try {
        const pixList = body.pix; // Lista de pagamentos atualizados

        for (const pix of pixList) {
            const txid = pix.txid;
            const status = pix.status; // "CONCLUIDA", "ATIVA", etc.

            if (status === "CONCLUIDA") {
                // 1. Buscar a transação no banco de dados
                const transactionRef = db.collection("transactions").doc(txid);
                const transactionDoc = await transactionRef.get();

                if (!transactionDoc.exists) {
                    console.log(`Transação ${txid} não encontrada.`);
                    continue;
                }

                const transactionData = transactionDoc.data();

                // Verificar se já não foi processada para evitar saldo duplo
                if (transactionData.status === "approved") {
                    console.log(`Transação ${txid} já processada.`);
                    continue;
                }

                // 2. Atualizar saldo do usuário e status da transação atomicamente
                await db.runTransaction(async (t) => {
                    const playerRef = db.collection("players").doc(transactionData.userId);

                    // Atualiza transação para aprovada e salva o json completo do pix por segurança
                    t.update(transactionRef, {
                        status: "approved",
                        paidAt: admin.firestore.FieldValue.serverTimestamp(),
                        paymentDetails: pix
                    });

                    // Incrementa o saldo do usuário
                    t.update(playerRef, {
                        balance: admin.firestore.FieldValue.increment(transactionData.amount)
                    });
                });

                console.log(`Saldo adicionado para o usuário ${transactionData.userId} (TxId: ${txid})`);
            }
        }

        // Retornar 200 OK para a EfiPay saber que recebemos
        res.status(200).send("OK");

    } catch (error) {
        console.error("Erro no Webhook:", error);
        // Em caso de erro, a EfiPay tentará reenviar depois, então retornamos 500
        res.status(500).send("Erro interno");
    }
});

// ==========================================================
// 2. FUNÇÃO AUXILIAR PARA REGISTRAR O WEBHOOK (Executar 1 vez)
// ==========================================================
exports.configPixWebhook = onCall(async (request) => {
    // Apenas admins deveriam poder chamar isso, ou execute via shell

    // URL da sua função webhook (Você pega isso no terminal após o deploy)
    // Exemplo: https://pixwebhook-j3k4j5k-uc.a.run.app
    const webhookUrl = request.data.url;

    if (!webhookUrl) {
        throw new HttpsError("invalid-argument", "https://pixwebhook-6anj5ioxoa-rj.a.run.app");
    }

    const efipay = new EfiPay(options);

    const params = {
        chave: "9d65f7ad-d202-4323-8645-a07be6076ec3" // A mesma chave usada no createPixCharge
    };

    const body = {
        webhookUrl: webhookUrl
    };

    try {
        const response = await efipay.pixConfigWebhook(params, body);
        return { success: true, response };
    } catch (error) {
        console.error("Erro ao configurar webhook:", error);
        throw new HttpsError("internal", "Erro na EfiPay: " + error.message);
    }
});
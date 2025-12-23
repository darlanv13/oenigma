import 'dart:convert';

import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/user_wallet_model.dart';
import '../utils/app_colors.dart';

// 1. Transformado de StatefulWidget para StatelessWidget
class WalletScreen extends StatelessWidget {
  // 2. Recebe o modelo de dados já carregado
  final UserWalletModel wallet;

  const WalletScreen({super.key, required this.wallet});

  // Importante: Adicione os imports necessários no topo do arquivo
  // import 'package:cloud_functions/cloud_functions.dart';
  // import 'dart:convert'; // Para decodificar a imagem Base64

  // Adicione os imports necessários no topo do arquivo, se não houver:
  // import 'package:cloud_functions/cloud_functions.dart';
  // import 'dart:convert';

  void _buyCredits(BuildContext context, double amount) async {
    // 1. Mostra o Loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final result =
          await FirebaseFunctions.instanceFor(
            region: 'southamerica-east1',
          ).httpsCallable('createPixCharge').call({
            'amount': amount,
            'cpf': '', // O backend busca o CPF
          });

      if (!context.mounted) return;
      Navigator.of(context).pop(); // Fecha Loading

      final data = result.data as Map<dynamic, dynamic>;

      if (data['qrCodeImage'] == null) {
        throw "Imagem QR Code não retornada.";
      }

      // Tratamento da imagem Base64
      String base64String = data['qrCodeImage'];
      if (base64String.contains(',')) {
        base64String = base64String.split(',').last;
      }

      final imageBytes = base64Decode(base64String);
      final String? copiaCola = data['copiaCola'];

      // 3. Mostra o Dialog com o PIX
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          backgroundColor: cardColor,
          title: const Center(
            child: Text(
              'Pagamento via Pix',
              style: TextStyle(
                color: primaryAmber,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // === NOVO: MOSTRANDO O VALOR ===
              const Text(
                "Valor a pagar:",
                style: TextStyle(color: Colors.white70, fontSize: 14),
              ),
              const SizedBox(height: 4),
              Text(
                'R\$ ${amount.toStringAsFixed(2).replaceAll('.', ',')}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),

              // ==============================
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                ),
                padding: const EdgeInsets.all(8.0),
                child: Image.memory(imageBytes, height: 200, width: 200),
              ),
              const SizedBox(height: 16),
              const Text(
                'Escaneie o QR Code ou use o botão abaixo para copiar:',
                style: TextStyle(color: Colors.white70),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () async {
                if (copiaCola != null) {
                  await Clipboard.setData(ClipboardData(text: copiaCola));
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Código Pix copiado com sucesso!'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  }
                }
              },
              child: const Text(
                'COPIAR CÓDIGO',
                style: TextStyle(
                  color: primaryAmber,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('FECHAR', style: TextStyle(color: Colors.grey)),
            ),
          ],
        ),
      );
    } catch (e) {
      if (!e.toString().contains("Invalid character") &&
          Navigator.canPop(context)) {
        try {
          Navigator.of(context).pop();
        } catch (_) {}
      }

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  void _showWithdrawDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: cardColor,
        title: const Text(
          'Solicitar Saque',
          style: TextStyle(color: primaryAmber),
        ),
        content: const Text(
          'Aqui, o utilizador informaria os seus dados de pagamento (ex: Chave PIX) e a sua solicitação seria enviada para aprovação do administrador.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text(
              'ENTENDIDO',
              style: TextStyle(color: primaryAmber),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Minha Carteira'), centerTitle: true),
      // 3. O FutureBuilder e o RefreshIndicator foram removidos.
      // A tela agora é construída instantaneamente com os dados recebidos.
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildProfileHeader(wallet),
          const SizedBox(height: 24),
          _buildBalanceCard(context, wallet.balance),
          const SizedBox(height: 24),
          _buildSectionTitle('ADICIONAR SALDO'),
          const SizedBox(height: 12),
          _buildCreditOptions(context),
          const SizedBox(height: 24),
          _buildSectionTitle('ÚLTIMO PRÉMIO'),
          const SizedBox(height: 12),
          _buildPrizesCard(wallet.lastWonEventName),
          const SizedBox(height: 24),
          _buildSectionTitle('ESTATÍSTICAS'),
          const SizedBox(height: 12),
          _buildStatsCard(wallet.lastEventRank, wallet.lastEventName),
        ],
      ),
    );
  }

  // Os widgets de construção permanecem os mesmos, recebendo os dados diretamente do objeto 'wallet'.
  Widget _buildProfileHeader(UserWalletModel wallet) {
    return Row(
      children: [
        CircleAvatar(
          radius: 35,
          backgroundColor: cardColor,
          backgroundImage: wallet.photoURL != null
              ? NetworkImage(wallet.photoURL!)
              : null,
          child: wallet.photoURL == null
              ? const Icon(Icons.person, size: 35, color: secondaryTextColor)
              : null,
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                wallet.name,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: textColor,
                ),
                overflow: TextOverflow.ellipsis,
              ),
              Text(
                wallet.email,
                style: const TextStyle(fontSize: 14, color: secondaryTextColor),
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildBalanceCard(BuildContext context, double balance) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Saldo Atual',
                style: TextStyle(color: secondaryTextColor, fontSize: 16),
              ),
              const SizedBox(height: 8),
              Text(
                'R\$ ${balance.toStringAsFixed(2).replaceAll('.', ',')}',
                style: const TextStyle(
                  color: textColor,
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          ElevatedButton.icon(
            onPressed: () => _showWithdrawDialog(context),
            icon: const Icon(Icons.arrow_circle_up_rounded),
            label: const Text('Sacar'),
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryAmber.withOpacity(0.2),
              foregroundColor: primaryAmber,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title.toUpperCase(),
      style: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.bold,
        color: secondaryTextColor,
        letterSpacing: 1.5,
      ),
    );
  }

  Widget _buildCreditOptions(BuildContext context) {
    final options = [5, 10, 15, 20];
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: options.length,
      itemBuilder: (context, index) {
        final amount = options[index];
        return Material(
          color: cardColor,
          borderRadius: BorderRadius.circular(15),
          child: InkWell(
            onTap: () => _buyCredits(context, amount.toDouble()),
            borderRadius: BorderRadius.circular(15),
            child: Center(
              child: Text(
                'R\$ $amount',
                style: const TextStyle(
                  color: textColor,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildPrizesCard(String? lastWonEventName) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 25),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: (lastWonEventName == null)
          ? const Center(
              child: Text(
                'Você ainda não venceu nenhum evento.',
                style: TextStyle(color: secondaryTextColor),
              ),
            )
          : Row(
              children: [
                const Icon(
                  Icons.emoji_events_outlined,
                  color: primaryAmber,
                  size: 40,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "Parabéns pela sua última vitória!",
                        style: TextStyle(
                          color: secondaryTextColor,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        lastWonEventName,
                        style: const TextStyle(
                          color: textColor,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildStatsCard(int? rank, String? eventName) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: (rank == null || eventName == null)
          ? const Center(
              child: Text(
                "Nenhum ranking de evento ativo para exibir.",
                style: TextStyle(color: secondaryTextColor),
              ),
            )
          : Column(
              children: [
                const Text(
                  "SUA POSIÇÃO NO ÚLTIMO EVENTO ATIVO",
                  style: TextStyle(
                    color: secondaryTextColor,
                    fontSize: 12,
                    letterSpacing: 1.0,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  eventName,
                  style: const TextStyle(
                    color: primaryAmber,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 4),
                Text(
                  '#$rank',
                  style: const TextStyle(
                    color: textColor,
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
    );
  }
}

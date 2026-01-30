import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/material.dart';
import 'package:oenigma/admin/services/admin_service.dart';
import 'package:oenigma/admin/widgets/admin_scaffold.dart';
import 'package:oenigma/models/withdrawal_model.dart';
import 'package:oenigma/utils/app_colors.dart';

class FinancialScreen extends StatefulWidget {
  const FinancialScreen({super.key});

  @override
  State<FinancialScreen> createState() => _FinancialScreenState();
}

class _FinancialScreenState extends State<FinancialScreen> {
  final AdminService _adminService = AdminService();
  bool _isProcessing = false;

  void _configureWebhook() {
    final TextEditingController urlController = TextEditingController(
      text: "https://pixwebhook-6anj5ioxoa-rj.a.run.app", // Sugestão Padrão
    );

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: cardColor,
        title: const Text(
          "Configurar Webhook Pix",
          style: TextStyle(color: textColor),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              "Insira a URL da Cloud Function 'pixWebhook' para registrar na EfiPay.",
              style: TextStyle(color: Colors.white70),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: urlController,
              style: const TextStyle(color: textColor),
              decoration: const InputDecoration(
                labelText: "Webhook URL",
                labelStyle: TextStyle(color: secondaryTextColor),
                enabledBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.white24),
                ),
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: primaryAmber),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancelar", style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: primaryAmber),
            onPressed: () {
              Navigator.pop(context); // Fecha diálogo
              _executeWebhookConfig(urlController.text.trim());
            },
            child: const Text(
              "Configurar",
              style: TextStyle(color: Colors.black),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _executeWebhookConfig(String url) async {
    if (url.isEmpty) return;
    setState(() => _isProcessing = true);

    try {
      final result = await FirebaseFunctions.instanceFor(
        region: 'southamerica-east1',
      ).httpsCallable('configPixWebhook').call({'url': url});

      if (!mounted) return;

      final data = result.data as Map<dynamic, dynamic>;
      print("Resultado Webhook: $data");

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Webhook Configurado com Sucesso! ✅'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro ao configurar: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  Future<void> _confirmAction(WithdrawalModel req, String status) async {
    final isApproval = status == 'approved';
    final actionText = isApproval ? "Aprovar" : "Rejeitar";

    // Diálogo de confirmação
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: cardColor,
        title: Text(
          isApproval ? "Confirmar Pagamento?" : "Rejeitar Solicitação?",
          style: const TextStyle(color: textColor),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              isApproval
                  ? "Confirma que transferiu manualmente o valor abaixo?"
                  : "O valor será estornado para a carteira do jogador.",
              style: const TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 10),
            Text(
              "Valor: R\$ ${req.amount.toStringAsFixed(2)}",
              style: const TextStyle(
                color: textColor,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            Text(
              "Chave Pix: ${req.pixKey}",
              style: const TextStyle(color: textColor),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text("Cancelar", style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: isApproval ? Colors.green : Colors.red,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(actionText),
          ),
        ],
      ),
    );

    if (confirm == true) {
      setState(() => _isProcessing = true);

      try {
        // Chama o método do AdminService que vai disparar a Cloud Function
        await _adminService.updateWithdrawalStatus(req.id, status);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                "Solicitação ${isApproval ? 'aprovada' : 'rejeitada'} com sucesso!",
              ),
              backgroundColor: isApproval ? Colors.green : Colors.orange,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text("Erro ao processar: $e"),
              backgroundColor: Colors.red,
            ),
          );
        }
      } finally {
        if (mounted) setState(() => _isProcessing = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AdminScaffold(
      title: 'Financeiro & Saques',
      selectedIndex: 3,
      // Botão Extra na AppBar para Webhook
      actions: [
        IconButton(
          icon: const Icon(Icons.settings_ethernet, color: primaryAmber),
          tooltip: "Configurar Webhook Pix",
          onPressed: _isProcessing ? null : _configureWebhook,
        ),
      ],
      body: Stack(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    "Solicitações Pendentes",
                    style: TextStyle(
                      fontSize: 22,
                      color: primaryAmber,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (_isProcessing)
                    const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        color: primaryAmber,
                        strokeWidth: 2,
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 20),

              Expanded(
                child: StreamBuilder<List<WithdrawalModel>>(
                  // O Stream continua ouvindo o Firestore para atualizações em tempo real
                  stream: _adminService.getPendingWithdrawals(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(
                        child: CircularProgressIndicator(color: primaryAmber),
                      );
                    }

                    final requests = snapshot.data ?? [];

                    if (requests.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.check_circle_outline,
                              size: 80,
                              color: Colors.green,
                            ),
                            const SizedBox(height: 16),
                            const Text(
                              "Tudo pago! Nenhuma solicitação pendente.",
                              style: TextStyle(
                                color: Colors.grey,
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              "Bom trabalho, Admin.",
                              style: TextStyle(
                                color: Colors.grey.withOpacity(0.5),
                              ),
                            ),
                          ],
                        ),
                      );
                    }

                    return ListView.builder(
                      itemCount: requests.length,
                      itemBuilder: (context, index) {
                        final req = requests[index];
                        return Card(
                          color: cardColor,
                          margin: const EdgeInsets.only(bottom: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: BorderSide(
                              color: Colors.white.withOpacity(0.05),
                            ),
                          ),
                          child: ListTile(
                            contentPadding: const EdgeInsets.all(16),
                            leading: CircleAvatar(
                              radius: 25,
                              backgroundColor: Colors.blueGrey.withOpacity(0.3),
                              child: const Icon(
                                Icons.person,
                                color: Colors.white,
                              ),
                            ),
                            title: Text(
                              req.userName,
                              style: const TextStyle(
                                color: textColor,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            subtitle: Padding(
                              padding: const EdgeInsets.only(top: 8.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      const Icon(
                                        Icons.pix,
                                        size: 16,
                                        color: primaryAmber,
                                      ),
                                      const SizedBox(width: 4),
                                      SelectableText(
                                        req.pixKey,
                                        style: const TextStyle(
                                          color: Colors.white70,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    "Data: ${req.requestedAt}",
                                    style: const TextStyle(
                                      color: Colors.grey,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            trailing: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  "R\$ ${req.amount.toStringAsFixed(2)}",
                                  style: const TextStyle(
                                    color: Colors.greenAccent,
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      icon: const Icon(
                                        Icons.check_circle,
                                        color: Colors.green,
                                      ),
                                      tooltip: "Aprovar (Pago)",
                                      onPressed: _isProcessing
                                          ? null
                                          : () =>
                                                _confirmAction(req, 'approved'),
                                    ),
                                    IconButton(
                                      icon: const Icon(
                                        Icons.cancel,
                                        color: Colors.red,
                                      ),
                                      tooltip: "Rejeitar (Estornar)",
                                      onPressed: _isProcessing
                                          ? null
                                          : () =>
                                                _confirmAction(req, 'rejected'),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),

          // Bloqueio de tela extra durante processamento
          if (_isProcessing)
            Container(color: Colors.black12, child: const Center()),
        ],
      ),
    );
  }
}

import 'package:parse_server_sdk_flutter/parse_server_sdk_flutter.dart';
import 'package:flutter/material.dart';
import 'package:oenigma/core/utils/app_colors.dart';

class AdminFinanceScreen extends StatelessWidget {
  const AdminFinanceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Gestão Financeira e Saques (Pix)',
          style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white),
        ),
        const SizedBox(height: 24),
        Expanded(
          child: FutureBuilder<ParseResponse>(
            future: (QueryBuilder<ParseObject>(ParseObject('withdrawals'))..whereEqualTo('status', 'pending')..orderByAscending('createdAt')).query(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (!snapshot.hasData || snapshot.data!.results == null || snapshot.data!.results!.isEmpty) {
                return const Center(
                  child: Text('Não há solicitações de saque pendentes.', style: TextStyle(color: secondaryTextColor)),
                );
              }

              final requests = snapshot.data!.results! as List<ParseObject>;

              return ListView.builder(
                itemCount: requests.length,
                itemBuilder: (context, index) {
                  final request = requests[index];
                  final requestId = request.objectId!;
                  final uid = request.get<String>('uid') ?? 'Desconhecido';
                  final amount = request.get<num>('amount') ?? 0;
                  final pixKey = request.get<String>('pixKey') ?? 'Chave não informada';
                  final pixKeyType = request.get<String>('pixKeyType') ?? 'Desconhecido';
                  final createdAt = request.createdAt;
                  final dateStr = createdAt != null
                      ? '${createdAt.day}/${createdAt.month}/${createdAt.year} ${createdAt.hour}:${createdAt.minute.toString().padLeft(2, '0')}'
                      : 'Data desconhecida';

                  return Card(
                    color: cardColor,
                    margin: const EdgeInsets.only(bottom: 12),
                    child: ListTile(
                      leading: const CircleAvatar(
                        backgroundColor: Colors.green,
                        child: Icon(Icons.pix, color: Colors.white),
                      ),
                      title: Text('Valor: R\$ $amount - Chave: $pixKey ($pixKeyType)', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      subtitle: Text('UID: $uid\nData da Solicitação: $dateStr', style: const TextStyle(color: secondaryTextColor)),
                      isThreeLine: true,
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          TextButton.icon(
                            icon: const Icon(Icons.check_circle, color: Colors.green),
                            label: const Text('Aprovar & Pagar', style: TextStyle(color: Colors.green)),
                            onPressed: () => _handleWithdrawal(context, requestId, uid, 'approve'),
                          ),
                          const SizedBox(width: 8),
                          TextButton.icon(
                            icon: const Icon(Icons.cancel, color: Colors.redAccent),
                            label: const Text('Rejeitar & Estornar', style: TextStyle(color: Colors.redAccent)),
                            onPressed: () => _handleWithdrawal(context, requestId, uid, 'reject'),
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
    );
  }

  Future<void> _handleWithdrawal(BuildContext context, String withdrawalId, String uid, String action) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => const Center(child: CircularProgressIndicator()),
    );

    try {
      await ParseCloudFunction('processWithdrawal').execute(parameters: {
        'withdrawalId': withdrawalId,
        'uid': uid,
        'action': action,
      });

      if (context.mounted) {
        Navigator.pop(context); // close loader
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Saque processado com sucesso: $action')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        Navigator.pop(context); // close loader
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao processar saque: $e'), backgroundColor: Colors.redAccent),
        );
      }
    }
  }
}

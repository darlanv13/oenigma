import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
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
          child: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('withdrawals')
                .where('status', isEqualTo: 'pending')
                .orderBy('createdAt', descending: false)
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return const Center(
                  child: Text('Não há solicitações de saque pendentes.', style: TextStyle(color: secondaryTextColor)),
                );
              }

              final requests = snapshot.data!.docs;

              return ListView.builder(
                itemCount: requests.length,
                itemBuilder: (context, index) {
                  final request = requests[index].data() as Map<String, dynamic>;
                  final requestId = requests[index].id;
                  final uid = request['uid'] ?? 'Desconhecido';
                  final amount = request['amount'] ?? 0;
                  final pixKey = request['pixKey'] ?? 'Chave não informada';
                  final pixKeyType = request['pixKeyType'] ?? 'Desconhecido';
                  final createdAt = request['createdAt'] as Timestamp?;
                  final dateStr = createdAt != null
                      ? '${createdAt.toDate().day}/${createdAt.toDate().month}/${createdAt.toDate().year} ${createdAt.toDate().hour}:${createdAt.toDate().minute.toString().padLeft(2, '0')}'
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
    // action should be 'approve' or 'reject'
    // This assumes we have an admin function that wraps the process, or we do it securely.
    // For now, let's call a hypothetical cloud function 'admin-processWithdrawal'
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => const Center(child: CircularProgressIndicator()),
    );

    try {
      await FirebaseFunctions.instance.httpsCallable('processWithdrawal').call({
        'withdrawalId': withdrawalId,
        'uid': uid,
        'action': action, // 'approve' fires Pix API, 'reject' refunds wallet
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

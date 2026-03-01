import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:oenigma/core/utils/app_colors.dart';

class AdminFraudScreen extends StatelessWidget {
  const AdminFraudScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Monitor de Fraudes (Logs do Sistema)',
          style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white),
        ),
        const SizedBox(height: 24),
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('fraud_logs')
                .orderBy('timestamp', descending: true)
                .limit(50)
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return const Center(
                  child: Text('Nenhum log de fraude encontrado. Tudo tranquilo!', style: TextStyle(color: secondaryTextColor)),
                );
              }

              final logs = snapshot.data!.docs;

              return ListView.builder(
                itemCount: logs.length,
                itemBuilder: (context, index) {
                  final log = logs[index].data() as Map<String, dynamic>;
                  final uid = log['uid'] ?? 'Desconhecido';
                  final reason = log['reason'] ?? 'Motivo desconhecido';
                  final eventId = log['eventId'] ?? '';
                  final timestamp = log['timestamp'] as Timestamp?;
                  final dateStr = timestamp != null
                      ? '${timestamp.toDate().day}/${timestamp.toDate().month}/${timestamp.toDate().year} ${timestamp.toDate().hour}:${timestamp.toDate().minute.toString().padLeft(2, '0')}'
                      : 'Data desconhecida';

                  return Card(
                    color: cardColor,
                    margin: const EdgeInsets.only(bottom: 12),
                    child: ListTile(
                      leading: const Icon(Icons.warning_amber_rounded, color: Colors.redAccent, size: 40),
                      title: Text('Usuário: $uid', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 4),
                          Text('Alerta: $reason', style: const TextStyle(color: Colors.redAccent)),
                          Text('Evento ID: $eventId', style: const TextStyle(color: secondaryTextColor)),
                          Text('Data: $dateStr', style: const TextStyle(color: secondaryTextColor, fontSize: 12)),
                        ],
                      ),
                      isThreeLine: true,
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          TextButton.icon(
                            icon: const Icon(Icons.block, color: Colors.red),
                            label: const Text('Banir', style: TextStyle(color: Colors.red)),
                            onPressed: () {
                               // Implement Ban logic (update user custom claims or user doc)
                            },
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
}

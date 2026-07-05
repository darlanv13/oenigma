import 'package:parse_server_sdk_flutter/parse_server_sdk_flutter.dart';
import 'package:flutter/material.dart';
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
          child: FutureBuilder<ParseResponse>(
            future: (QueryBuilder<ParseObject>(ParseObject('fraud_logs'))..orderByDescending('timestamp')..setLimit(50)).query(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (!snapshot.hasData || snapshot.data!.results == null || snapshot.data!.results!.isEmpty) {
                return const Center(
                  child: Text('Nenhum log de fraude encontrado. Tudo tranquilo!', style: TextStyle(color: secondaryTextColor)),
                );
              }

              final logs = snapshot.data!.results! as List<ParseObject>;

              return ListView.builder(
                itemCount: logs.length,
                itemBuilder: (context, index) {
                  final log = logs[index];
                  final uid = log.get<String>('uid') ?? 'Desconhecido';
                  final reason = log.get<String>('reason') ?? 'Motivo desconhecido';
                  final eventId = log.get<String>('eventId') ?? '';
                  final timestamp = log.createdAt;
                  final dateStr = timestamp != null
                      ? '${timestamp.day}/${timestamp.month}/${timestamp.year} ${timestamp.hour}:${timestamp.minute.toString().padLeft(2, '0')}'
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
                               // Implement Ban logic
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

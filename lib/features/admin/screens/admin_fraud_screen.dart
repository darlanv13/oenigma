import 'package:flutter/material.dart';
import 'package:parse_server_sdk_flutter/parse_server_sdk_flutter.dart';
import 'package:oenigma/core/utils/app_colors.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class AdminFraudScreen extends StatefulWidget {
  const AdminFraudScreen({super.key});

  @override
  State<AdminFraudScreen> createState() => _AdminFraudScreenState();
}

class _AdminFraudScreenState extends State<AdminFraudScreen> {
  late Future<ParseResponse> _fraudLogsFuture;

  @override
  void initState() {
    super.initState();
    _loadFraudLogs();
  }

  void _loadFraudLogs() {
    setState(() {
      _fraudLogsFuture = (QueryBuilder<ParseObject>(ParseObject('FraudLog'))
            ..orderByDescending('createdAt')
            ..setLimit(50))
          .query();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Monitor de Fraudes (Logs do Sistema)',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 24),
        Expanded(
          child: FutureBuilder<ParseResponse>(
            future: _fraudLogsFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError) {
                return Center(
                  child: Text(
                    'Erro: ${snapshot.error}',
                    style: const TextStyle(color: Colors.redAccent),
                  ),
                );
              }
              if (!snapshot.hasData || !snapshot.data!.success || snapshot.data!.results == null || snapshot.data!.results!.isEmpty) {
                return const Center(
                  child: Text(
                    'Nenhum log de fraude encontrado. Tudo tranquilo!',
                    style: TextStyle(color: secondaryTextColor),
                  ),
                );
              }

              final logs = snapshot.data!.results as List<ParseObject>;

              return ListView.builder(
                itemCount: logs.length,
                itemBuilder: (context, index) {
                  final log = logs[index];
                  final objectId = log.get<String>('objectId') ?? 'Desconhecido';
                  final reason = log.get<String>('reason') ?? 'Motivo desconhecido';
                  final eventId = log.get<String>('eventId') ?? '';
                  final createdAt = log.createdAt;
                  final dateStr = (createdAt != null
                      ? '${createdAt.day}/${createdAt.month}/${createdAt.year} ${createdAt.hour}:${createdAt.minute.toString().padLeft(2, '0')}'
                      : 'Data desconhecida');

                  return Card(
                    color: cardColor,
                    margin: const EdgeInsets.only(bottom: 12),
                    child: ListTile(
                      leading: const FaIcon(FontAwesomeIcons.triangleExclamation,
                        color: Colors.redAccent,
                        size: 40,
                      ),
                      title: Text(
                        'Usuário: $objectId',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 4),
                          Text(
                            'Alerta: $reason',
                            style: const TextStyle(color: Colors.redAccent),
                          ),
                          Text(
                            'Evento ID: $eventId',
                            style: const TextStyle(color: secondaryTextColor),
                          ),
                          Text(
                            'Data: $dateStr',
                            style: const TextStyle(
                              color: secondaryTextColor,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                      isThreeLine: true,
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          TextButton.icon(
                            icon: const FaIcon(FontAwesomeIcons.ban,
                              color: Colors.red,
                            ),
                            label: const Text(
                              'Banir',
                              style: TextStyle(color: Colors.red),
                            ),
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

import 'package:firebase_auth/firebase_auth.dart'; // Import necessário
import 'package:flutter/material.dart';
import 'package:oenigma/admin/screens/event_editor_screen.dart';
import 'package:oenigma/admin/screens/event_structure_screen.dart';
import 'package:oenigma/admin/services/admin_service.dart';
import 'package:oenigma/admin/widgets/admin_scaffold.dart';
import 'package:oenigma/models/event_model.dart';
import 'package:oenigma/utils/app_colors.dart';

class EventsManagerScreen extends StatefulWidget {
  const EventsManagerScreen({super.key});

  @override
  State<EventsManagerScreen> createState() => _EventsManagerScreenState();
}

class _EventsManagerScreenState extends State<EventsManagerScreen> {
  final AdminService _adminService = AdminService();
  bool _isProcessing = false;

  // Controle de Permissões Locais
  bool _canDelete = false;
  bool _canCreate = false;

  @override
  void initState() {
    super.initState();
    _checkPermissions();
  }

  // Verifica o token para saber o que pode mostrar
  Future<void> _checkPermissions() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final token = await user.getIdTokenResult();
      final perms = token.claims?['permissions'] as Map?;

      if (mounted) {
        setState(() {
          // Se for null, assume falso
          _canDelete = perms?['delete_events'] == true;
          _canCreate = perms?['create_events'] == true;
        });
      }
    }
  }

  Future<void> _deleteEvent(EventModel event) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: cardColor,
        title: Text(
          "Excluir '${event.name}'?",
          style: const TextStyle(color: textColor),
        ),
        content: const Text(
          "Esta ação apagará o evento, todas as fases e todos os enigmas vinculados. Não pode ser desfeita.",
          style: TextStyle(color: Colors.grey),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text("Cancelar", style: TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text(
              "Excluir Tudo",
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );

    if (confirm == true) {
      setState(() => _isProcessing = true);
      try {
        // Chama a função deleteEvent do management.js
        await _adminService.deleteEvent(event.id);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Evento excluído com sucesso!"),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text("Erro ao excluir: $e"),
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
      title: 'Gerenciar Eventos',
      selectedIndex: 1,
      body: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Indicador de carregamento discreto se estiver processando algo
              if (_isProcessing)
                const CircularProgressIndicator(color: primaryAmber)
              else
                const SizedBox(),

              // Botão Novo Evento (Opcional: Esconder se não puder criar)
              if (_canCreate)
                ElevatedButton.icon(
                  icon: const Icon(Icons.add),
                  label: const Text("Novo Evento"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryAmber,
                    foregroundColor: darkBackground,
                  ),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const EventEditorScreen(),
                      ),
                    );
                  },
                ),
            ],
          ),
          const SizedBox(height: 20),

          Expanded(
            child: StreamBuilder<List<EventModel>>(
              stream: _adminService.getEvents(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(color: primaryAmber),
                  );
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Text(
                      "Erro: ${snapshot.error}",
                      style: const TextStyle(color: Colors.red),
                    ),
                  );
                }

                final events = snapshot.data ?? [];

                if (events.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.event_busy,
                          size: 60,
                          color: Colors.grey,
                        ),
                        const SizedBox(height: 10),
                        const Text(
                          "Nenhum evento cadastrado.",
                          style: TextStyle(color: Colors.grey),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  itemCount: events.length,
                  itemBuilder: (context, index) {
                    final event = events[index];
                    final isFindAndWin = event.eventType == 'find_and_win';
                    final isOpen = event.status == 'open';

                    return Card(
                      color: cardColor,
                      margin: const EdgeInsets.only(bottom: 12),
                      shape: RoundedRectangleBorder(
                        side: BorderSide(
                          color: isOpen
                              ? Colors.green.withOpacity(0.3)
                              : Colors.transparent,
                        ),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        leading: CircleAvatar(
                          backgroundColor: Colors.blueGrey.withOpacity(0.3),
                          child: Icon(
                            isFindAndWin ? Icons.search : Icons.flag,
                            color: isFindAndWin
                                ? Colors.cyanAccent
                                : Colors.orangeAccent,
                          ),
                        ),
                        title: Text(
                          event.name,
                          style: const TextStyle(
                            color: textColor,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              isFindAndWin
                                  ? "Modo: Find & Win"
                                  : "Modo: Clássico (Fases)",
                              style: TextStyle(
                                color: isFindAndWin
                                    ? Colors.cyan
                                    : Colors.orange,
                                fontSize: 12,
                              ),
                            ),
                            Text(
                              "Status: ${isOpen ? 'Aberto' : 'Fechado/Em Breve'} • R\$ ${event.price.toStringAsFixed(2)}",
                              style: TextStyle(
                                color: isOpen ? Colors.green : Colors.grey,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Botão Estrutura (Fases/Enigmas)
                            IconButton(
                              icon: const Icon(
                                Icons.extension,
                                color: primaryAmber,
                              ),
                              tooltip: "Gerenciar Estrutura (Enigmas)",
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => EventStructureScreen(
                                      eventId: event.id,
                                      eventType: event.eventType,
                                    ),
                                  ),
                                );
                              },
                            ),
                            // Botão Editar Detalhes
                            IconButton(
                              icon: const Icon(Icons.edit, color: Colors.blue),
                              tooltip: "Editar Configurações",
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) =>
                                        EventEditorScreen(event: event),
                                  ),
                                );
                              },
                            ),
                            // Botão Excluir
                            IconButton(
                              icon: const Icon(
                                Icons.delete,
                                color: Colors.redAccent,
                              ),
                              tooltip: "Excluir Evento",
                              onPressed: () => _deleteEvent(event),
                            ),

                            if (_canDelete)
                              IconButton(
                                icon: const Icon(
                                  Icons.delete,
                                  color: Colors.redAccent,
                                ),
                                tooltip: "Excluir Evento",
                                onPressed: () => _deleteEvent(event),
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
    );
  }
}

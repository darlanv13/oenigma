import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:oenigma/admin/screens/enigma_editor_dialog.dart';
import 'package:oenigma/admin/services/admin_service.dart';
import 'package:oenigma/models/enigma_model.dart';
import 'package:oenigma/models/event_model.dart';
import 'package:oenigma/models/phase_model.dart';
import 'package:oenigma/utils/app_colors.dart';

class EventStructureScreen extends StatefulWidget {
  // ... construtor igual
  final String eventId;
  final String eventType;

  const EventStructureScreen({
    super.key,
    required this.eventId,
    required this.eventType,
  });

  @override
  State<EventStructureScreen> createState() => _EventStructureScreenState();
}

class _EventStructureScreenState extends State<EventStructureScreen> {
  final AdminService _adminService = AdminService();
  bool _isProcessing = false;

  // Controle de permissão
  bool _canDelete = false;

  @override
  void initState() {
    super.initState();
    _checkPermissions();
  }

  Future<void> _checkPermissions() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final token = await user.getIdTokenResult();
      final perms = token.claims?['permissions'] as Map?;
      if (mounted) {
        setState(() {
          _canDelete = perms?['delete_events'] == true;
        });
      }
    }
  }

  // 1. Adicionar ou Editar Enigma
  void _addOrEditEnigma(String? phaseId, EnigmaModel? existingEnigma) async {
    // Abre o formulário (Dialog)
    final result = await showDialog<EnigmaModel>(
      context: context,
      builder: (ctx) => EnigmaEditorDialog(enigma: existingEnigma),
    );

    if (result != null) {
      setState(() => _isProcessing = true);
      try {
        await _adminService.saveEnigma(
          eventId: widget.eventId,
          phaseId: widget.eventType == 'classic' ? phaseId : null,
          enigma: result,
        );
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Enigma salvo com sucesso!"),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Erro: $e"), backgroundColor: Colors.red),
          );
        }
      } finally {
        if (mounted) setState(() => _isProcessing = false);
      }
    }
  }

  // 2. Excluir Enigma
  void _deleteEnigma(String? phaseId, String enigmaId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: cardColor,
        title: const Text(
          "Excluir Enigma?",
          style: TextStyle(color: textColor),
        ),
        content: const Text(
          "Essa ação não pode ser desfeita.",
          style: TextStyle(color: Colors.grey),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text("Cancelar", style: TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text("Excluir", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      setState(() => _isProcessing = true);
      try {
        await _adminService.deleteEnigma(
          eventId: widget.eventId,
          phaseId: widget.eventType == 'classic' ? phaseId : null,
          enigmaId: enigmaId,
        );
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

  // 3. Adicionar Nova Fase (Apenas container)
  void _addNewPhase(int nextOrder) async {
    setState(() => _isProcessing = true);
    try {
      await _adminService.savePhase(
        eventId: widget.eventId,
        phaseId: null, // Null cria nova
        order: nextOrder,
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Erro ao criar fase: $e"),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  // 4. Excluir Fase
  void _deletePhase(String phaseId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: cardColor,
        title: const Text(
          "Excluir Fase inteira?",
          style: TextStyle(color: textColor),
        ),
        content: const Text(
          "Isso apagará todos os enigmas dentro desta fase.",
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
        await _adminService.deletePhase(
          eventId: widget.eventId,
          phaseId: phaseId,
        );
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text("Erro ao excluir fase: $e"),
              backgroundColor: Colors.red,
            ),
          );
        }
      } finally {
        if (mounted) setState(() => _isProcessing = false);
      }
    }
  }

  // --- UI BUILDER ---

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<EventModel>>(
      // Idealmente use getEventById, mas getEvents funciona como espelho
      stream: _adminService.getEvents(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            backgroundColor: darkBackground,
            body: Center(child: CircularProgressIndicator(color: primaryAmber)),
          );
        }

        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Scaffold(
            body: Center(child: Text("Evento não encontrado")),
          );
        }

        // Filtra o evento atual da lista
        EventModel? event;
        try {
          event = snapshot.data!.firstWhere((e) => e.id == widget.eventId);
        } catch (e) {
          return const Scaffold(
            body: Center(child: Text("Evento foi excluído.")),
          );
        }

        return Scaffold(
          backgroundColor: darkBackground,
          appBar: AppBar(
            title: Text(
              "Estrutura: ${event.name}",
              style: const TextStyle(color: textColor),
            ),
            backgroundColor: cardColor,
            iconTheme: const IconThemeData(color: primaryAmber),
            actions: [
              if (_isProcessing)
                const Padding(
                  padding: EdgeInsets.all(12.0),
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      color: primaryAmber,
                      strokeWidth: 2,
                    ),
                  ),
                ),
            ],
          ),
          body: widget.eventType == 'find_and_win'
              ? _buildFindAndWinList(event)
              : _buildClassicPhasesList(event),
        );
      },
    );
  }

  // --- MODO FIND & WIN (Lista Simples) ---
  Widget _buildFindAndWinList(EventModel event) {
    if (event.enigmas.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.extension_off, size: 60, color: Colors.grey),
            const SizedBox(height: 20),
            const Text(
              "Nenhum enigma criado ainda.",
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              icon: const Icon(Icons.add),
              label: const Text("Criar Primeiro Enigma"),
              onPressed: () => _addOrEditEnigma(null, null),
            ),
          ],
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.blueGrey.withOpacity(0.2),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Row(
            children: [
              Icon(Icons.info_outline, color: Colors.blueAccent),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  "Modo Find & Win: Os jogadores buscam qualquer enigma em qualquer ordem.",
                  style: TextStyle(color: Colors.grey),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        ...event.enigmas.map((e) => _buildEnigmaTile(null, e)),
        const SizedBox(height: 20),
        ElevatedButton.icon(
          icon: const Icon(Icons.add),
          label: const Text("Adicionar Novo Enigma"),
          style: ElevatedButton.styleFrom(
            backgroundColor: cardColor,
            foregroundColor: primaryAmber,
          ),
          onPressed: () => _addOrEditEnigma(null, null),
        ),
      ],
    );
  }

  // --- MODO CLASSIC (Fases -> Enigmas) ---

  // ATUALIZE: _buildClassicPhasesList
  Widget _buildClassicPhasesList(EventModel event) {
    final phases = event.phases..sort((a, b) => a.order.compareTo(b.order));

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: phases.length + 1,
      itemBuilder: (ctx, index) {
        if (index == phases.length) {
          // ... Botão adicionar nova fase ...
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 20),
            child: ElevatedButton.icon(
              icon: const Icon(Icons.add),
              label: const Text("Nova Fase"),
              onPressed: () => _addNewPhase(phases.length + 1),
            ),
          );
        }

        final phase = phases[index];
        return Card(
          color: cardColor,
          margin: const EdgeInsets.only(bottom: 16),
          child: ExpansionTile(
            title: Text(
              "Fase ${phase.order}",
              style: const TextStyle(color: primaryAmber),
            ),

            // SÓ MOSTRA O ÍCONE DE DELETAR FASE SE TIVER PERMISSÃO
            trailing: _canDelete
                ? IconButton(
                    icon: const Icon(
                      Icons.delete_forever,
                      color: Colors.redAccent,
                    ),
                    tooltip: "Excluir Fase",
                    onPressed: () => _deletePhase(phase.id),
                  )
                : null, // Se não tiver permissão, não mostra nada

            children: [
              ...phase.enigmas.map((e) => _buildEnigmaTile(phase.id, e)),
              // ...
            ],
          ),
        );
      },
    );
  }

  //buildEnigmaTile
  Widget _buildEnigmaTile(String? phaseId, EnigmaModel enigma) {
    return Container(
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Colors.white10)),
      ),
      child: ListTile(
        leading: const Icon(Icons.extension, size: 18, color: Colors.white),
        title: Text(
          enigma.instruction,
          style: const TextStyle(color: textColor),
        ),
        subtitle: Text(
          "Code: ${enigma.code}",
          style: const TextStyle(color: Colors.grey, fontSize: 12),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.edit, color: Colors.blue),
              tooltip: "Editar",
              onPressed: () => _addOrEditEnigma(phaseId, enigma),
            ),

            // SÓ MOSTRA O ÍCONE DE DELETAR ENIGMA SE TIVER PERMISSÃO
            if (_canDelete)
              IconButton(
                icon: const Icon(Icons.delete, color: Colors.redAccent),
                tooltip: "Remover",
                onPressed: () => _deleteEnigma(phaseId, enigma.id),
              ),
          ],
        ),
      ),
    );
  }
}

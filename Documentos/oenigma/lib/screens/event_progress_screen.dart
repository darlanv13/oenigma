import 'package:flutter/material.dart';
import '../models/event_model.dart';
import '../models/phase_model.dart';
import '../services/auth_service.dart';
import '../services/firebase_service.dart';
import '../utils/app_colors.dart';
import '../widgets/PhaseCard.dart';

class EventProgressScreen extends StatefulWidget {
  final EventModel event;
  const EventProgressScreen({super.key, required this.event});
  @override
  State<EventProgressScreen> createState() => _EventProgressScreenState();
}

class _EventProgressScreenState extends State<EventProgressScreen> {
  final FirebaseService _firebaseService = FirebaseService();
  final AuthService _authService = AuthService();
  late Future<void> _dataFuture;

  List<PhaseModel> _phases = [];
  int _currentPhase = 1;
  int _currentEnigma = 1;

  @override
  void initState() {
    super.initState();
    _dataFuture = _loadEventDataWithDebug();
  }

  // NOVA FUNÇÃO COM BLOCO TRY-CATCH PARA CAPTURAR O ERRO
  Future<void> _loadEventDataWithDebug() async {
    try {
      print("--- INICIANDO DEPURAÇÃO ---");

      final userId = _authService.currentUser?.uid;
      if (userId == null) throw Exception("Usuário não autenticado.");
      print("DEBUG: UserID obtido com sucesso: $userId");
      
      print("DEBUG: Passo 1 - Chamando getPhasesForEvent...");
      final phases = await _firebaseService.getPhasesForEvent(widget.event.id);
      print("DEBUG: Passo 1 - getPhasesForEvent CONCLUÍDO com sucesso.");

      if (!mounted) return;

      print("DEBUG: Passo 2 - Chamando getPlayerProgress...");
      final progress = await _firebaseService.getPlayerProgress(userId, widget.event.id);
      print("DEBUG: Passo 2 - getPlayerProgress CONCLUÍDO com sucesso.");
      
      if (!mounted) return;

      print("DEBUG: Passo 3 - Executando setState...");
      setState(() {
        _phases = phases;
        _currentPhase = progress['currentPhase'];
        _currentEnigma = progress['currentEnigma'];
      });
      print("DEBUG: Passo 3 - setState CONCLUÍDO com sucesso.");
      print("--- DEPURAÇÃO CONCLUÍDA SEM ERROS ---");

    } catch (e, stackTrace) {
      print("\n\n\n!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!");
      print("!!!!!!!!!! ERRO CAPTURADO AQUI !!!!!!!!!!");
      print("!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!");
      print("TIPO DO ERRO: ${e.runtimeType}");
      print("MENSAGEM DE ERRO: $e");
      print("\n--- STACK TRACE (RASTRO DO ERRO) ---");
      print(stackTrace);
      print("!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!");
      print("!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!\n\n\n");
      // Relança o erro para que ele ainda apareça na tela.
      rethrow;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.event.name)),
      body: FutureBuilder<void>(
        future: _dataFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: primaryAmber),
            );
          }
          // A tela de erro padrão do FutureBuilder será exibida aqui.
          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  'Erro ao carregar dados: ${snapshot.error}',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.red),
                ),
              ),
            );
          }
          return RefreshIndicator(
            onRefresh: () async {
              setState(() {
                _dataFuture = _loadEventDataWithDebug();
              });
            },
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: _buildPhasesGrid(),
            ),
          );
        },
      ),
    );
  }

  Widget _buildPhasesGrid() {
    // O restante do código não precisa de alterações.
    // Apenas colei aqui para garantir que o arquivo fique completo.
    return GridView.builder(
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 0.8,
      ),
      itemCount: _phases.length,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemBuilder: (context, index) {
        final phase = _phases[index];
        final bool isCompleted = phase.order < _currentPhase;
        final bool isLocked = phase.order > _currentPhase;
        final bool isActive = !isLocked && !isCompleted;

        return PhaseCard(
          event: widget.event,
          phase: phase,
          isLocked: isLocked,
          isCompleted: isCompleted,
          currentEnigma: isActive ? _currentEnigma : 1,
          onPhaseCompleted: () {
            setState(() {
              _dataFuture = _loadEventDataWithDebug();
            });
          },
        );
      },
    );
  }
}
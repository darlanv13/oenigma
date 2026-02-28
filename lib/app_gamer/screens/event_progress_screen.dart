import 'package:flutter/material.dart';
import '../../models/event_model.dart';
import '../../models/phase_model.dart';
import '../../services/auth_service.dart';
import '../../services/firebase_service.dart';
import '../utils/app_colors.dart';
import '../widgets/PhaseCard.dart';
import '../widgets/progress_header.dart';

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
    _dataFuture = _loadEventData();
  }

  Future<void> _loadEventData() async {
    final phases = await _firebaseService.getPhasesForEvent(widget.event.id);
    if (!mounted) return;

    final userId = _authService.currentUser?.uid;
    if (userId == null) throw Exception("Usuário não autenticado.");

    final progress = await _firebaseService.getPlayerProgress(
      userId,
      widget.event.id,
    );
    if (!mounted) return;

    setState(() {
      _phases = phases;
      _currentPhase = progress['currentPhase'];
      _currentEnigma = progress['currentEnigma'];
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.event.name),
        backgroundColor: darkBackground,
        elevation: 0,
      ),
      backgroundColor: darkBackground,
      body: FutureBuilder<void>(
        future: _dataFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: primaryAmber),
            );
          }
          if (snapshot.hasError) {
            return Center(child: Text('Erro: ${snapshot.error}'));
          }
          return RefreshIndicator(
            onRefresh: _loadEventData,
            color: primaryAmber,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ProgressHeader(
                    totalPhases: _phases.length,
                    completedPhases: _currentPhase - 1,
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'FASES DO EVENTO',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: secondaryTextColor,
                      letterSpacing: 1.5,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildPhasesList(), // Alterado de Grid para List
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // MODIFICADO: De GridView para ListView
  Widget _buildPhasesList() {
    return ListView.separated(
      itemCount: _phases.length,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      separatorBuilder: (context, index) => const SizedBox(height: 12),
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
          isActive: isActive,
          currentEnigma: isActive ? _currentEnigma : 1,
          onPhaseCompleted: () {
            setState(() {
              _dataFuture = _loadEventData();
            });
          },
        );
      },
    );
  }
}

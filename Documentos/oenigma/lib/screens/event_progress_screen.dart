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
      _currentPhase = progress['currentPhase'] ?? 1;
    });
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
          if (snapshot.hasError) {
            return Center(child: Text('Erro: ${snapshot.error}'));
          }
          return RefreshIndicator(
            onRefresh: _loadEventData,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  const Center(
                    child: Text(
                      'FASES',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 2,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildPhasesGrid(),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildPhasesGrid() {
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
        bool isCompleted = phase.order < _currentPhase;
        bool isLocked = phase.order > _currentPhase;
        return PhaseCard(
          event: widget.event,
          phase: phase,
          isLocked: isLocked,
          isCompleted: isCompleted,
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

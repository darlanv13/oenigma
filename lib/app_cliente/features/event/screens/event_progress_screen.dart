import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:oenigma/app_cliente/features/event/providers/event_repository_provider.dart';
import 'package:oenigma/app_cliente/features/auth/providers/auth_provider.dart';
import 'package:oenigma/core/models/event_model.dart';
import 'package:oenigma/core/models/phase_model.dart';
import 'package:oenigma/core/services/sound_service.dart';
import 'package:oenigma/core/utils/app_colors.dart';
import 'package:oenigma/app_cliente/features/event/widgets/phase_card.dart';
import '../widgets/progress_header.dart';

class EventProgressScreen extends ConsumerStatefulWidget {
  final EventModel event;

  const EventProgressScreen({super.key, required this.event});

  @override
  ConsumerState<EventProgressScreen> createState() =>
      _EventProgressScreenState();
}

class _EventProgressScreenState extends ConsumerState<EventProgressScreen> {
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
    final phases = await ref
        .read(eventRepositoryProvider)
        .getPhasesForEvent(widget.event.id);

    if (!mounted) return;

    final userId = ref.read(authRepositoryProvider).currentUser?.objectId;
    if (userId == null) throw Exception("Usuário não autenticado.");

    final progress = await ref
        .read(eventRepositoryProvider)
        .getPlayerProgress(userId, widget.event.id);

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
      backgroundColor: const Color(0xFF0B1115),
      body: Stack(
        children: [
          // Luzes ambientais suaves e discretas de fundo (Padrão Enigma)
          Positioned(
            top: -50,
            right: -50,
            child: Container(
              width: 240,
              height: 240,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.verdeVale.withValues(alpha: 0.10),
              ),
            ),
          ),
          Positioned(
            bottom: 80,
            left: -50,
            child: Container(
              width: 240,
              height: 240,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.amareloVale.withValues(alpha: 0.08),
              ),
            ),
          ),

          SafeArea(
            child: Column(
              children: [
                // Header Bar Estilo Enigma
                ClipRRect(
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0B1115).withValues(alpha: 0.90),
                        border: Border(
                          bottom: BorderSide(
                            color: Colors.white.withValues(alpha: 0.08),
                            width: 1.0,
                          ),
                        ),
                      ),
                      child: Row(
                        children: [
                          GestureDetector(
                            onTap: () {
                              HapticFeedback.lightImpact();
                              SoundService.playClick();
                              Navigator.of(context).pop();
                            },
                            child: Container(
                              width: 38,
                              height: 38,
                              decoration: BoxDecoration(
                                color: const Color(0xFF131D24),
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: Colors.white.withValues(alpha: 0.12),
                                  width: 1.2,
                                ),
                              ),
                              child: const Center(
                                child: FaIcon(
                                  FontAwesomeIcons.chevronLeft,
                                  color: Colors.white,
                                  size: 13,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 2.5),
                                  decoration: BoxDecoration(
                                    color: AppColors.verdeVale.withValues(alpha: 0.14),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: AppColors.verdeVale.withValues(alpha: 0.40),
                                      width: 1,
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const FaIcon(
                                        FontAwesomeIcons.route,
                                        size: 9,
                                        color: AppColors.verdeVale,
                                      ),
                                      const SizedBox(width: 5),
                                      Text(
                                        'EXPEDIÇÃO CLÁSSICA',
                                        style: GoogleFonts.cinzel(
                                          color: AppColors.verdeVale,
                                          fontSize: 9,
                                          fontWeight: FontWeight.w800,
                                          letterSpacing: 0.8,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  widget.event.name,
                                  textAlign: TextAlign.center,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: GoogleFonts.cinzel(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w800,
                                    color: Colors.white,
                                    letterSpacing: 0.6,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          Container(
                            width: 38,
                            height: 38,
                            decoration: BoxDecoration(
                              color: const Color(0xFF131D24),
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: AppColors.amareloVale.withValues(alpha: 0.5),
                                width: 1.2,
                              ),
                            ),
                            child: const Center(
                              child: FaIcon(
                                FontAwesomeIcons.compass,
                                color: AppColors.amareloVale,
                                size: 14,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                Expanded(
                  child: FutureBuilder<void>(
                    future: _dataFuture,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(
                          child: CircularProgressIndicator(color: AppColors.amareloVale),
                        );
                      }

                      if (snapshot.hasError) {
                        return Center(
                          child: Container(
                            margin: const EdgeInsets.symmetric(horizontal: 24),
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: const Color(0xFF131D24),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: const Color(0xFF1E3A45), width: 1.2),
                            ),
                            child: Text(
                              'Erro ao carregar fases: ${snapshot.error}',
                              style: GoogleFonts.inter(color: AppColors.cinzaMedio),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        );
                      }

                      return RefreshIndicator(
                        onRefresh: _loadEventData,
                        color: AppColors.amareloVale,
                        backgroundColor: const Color(0xFF131D24),
                        child: SingleChildScrollView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16.0,
                            vertical: 16.0,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              ProgressHeader(
                                totalPhases: _phases.length,
                                completedPhases: _currentPhase - 1,
                              ),
                              const SizedBox(height: 24),
                              Padding(
                                padding: const EdgeInsets.only(left: 4.0),
                                child: Text(
                                  'CÂMARAS & ENIGMAS',
                                  style: GoogleFonts.cinzel(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w900,
                                    color: AppColors.amareloVale,
                                    letterSpacing: 1.2,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 14),
                              _buildPhasesList(),
                              const SizedBox(height: 40),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

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

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:oenigma/app_cliente/features/event/providers/event_repository_provider.dart';
import 'package:oenigma/app_cliente/features/auth/providers/auth_provider.dart';
import 'package:oenigma/core/models/event_model.dart';
import 'package:oenigma/core/models/phase_model.dart';
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
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: Column(
          children: [
            // Header Bar
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(
                    color: Colors.white.withValues(alpha: 0.08),
                    width: 1,
                  ),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  GestureDetector(
                    onTap: () => Navigator.of(context).pop(),
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.06),
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
                      ),
                      child: const Center(
                        child: FaIcon(
                          FontAwesomeIcons.chevronLeft,
                          color: Colors.white,
                          size: 14,
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      widget.event.name,
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.poppins(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                  const SizedBox(width: 40),
                ],
              ),
            ),
            Expanded(
              child: FutureBuilder<void>(
                future: _dataFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(
                      child: CircularProgressIndicator(color: AppColors.verdeVale),
                    );
                  }

                  if (snapshot.hasError) {
                    return Center(
                      child: Text(
                        'Erro ao carregar fases: ${snapshot.error}',
                        style: GoogleFonts.inter(color: AppColors.cinzaMedio),
                      ),
                    );
                  }

                  return RefreshIndicator(
                    onRefresh: _loadEventData,
                    color: AppColors.verdeVale,
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
                          const SizedBox(height: 28),
                          Padding(
                            padding: const EdgeInsets.only(left: 4.0),
                            child: Text(
                              'FASES DO EVENTO',
                              style: GoogleFonts.poppins(
                                fontSize: 13,
                                fontWeight: FontWeight.w800,
                                color: AppColors.cinzaMedio,
                                letterSpacing: 1.5,
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

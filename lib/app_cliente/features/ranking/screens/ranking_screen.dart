import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:oenigma/core/models/ranking_player_model.dart';
import 'package:oenigma/core/models/event_model.dart';
import 'package:oenigma/core/utils/app_colors.dart';
import 'package:oenigma/app_cliente/features/ranking/widgets/ranking_event_selector.dart';
import 'package:oenigma/app_cliente/features/ranking/widgets/ranking_list.dart';
import 'package:oenigma/app_cliente/features/ranking/widgets/ranking_podium.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_fonts/google_fonts.dart';

class RankingScreen extends ConsumerStatefulWidget {
  final List<EventModel> availableEvents;
  final List<dynamic> allPlayers;

  const RankingScreen({
    super.key,
    required this.availableEvents,
    required this.allPlayers,
  });

  @override
  ConsumerState<RankingScreen> createState() => _RankingScreenState();
}

class _RankingScreenState extends ConsumerState<RankingScreen> {
  String? _selectedEventId;
  String _selectedTimeFilter = 'all_time'; // 'all_time' or 'monthly'
  List<RankingPlayerModel> _currentRanking = [];

  @override
  void initState() {
    super.initState();
    if (widget.availableEvents.isNotEmpty) {
      _selectedEventId = widget.availableEvents.first.id;
      _calculateRankingForSelectedEvent();
    }
  }

  void _calculateRankingForSelectedEvent() {
    if (_selectedEventId == null) return;

    List<RankingPlayerModel> ranking = [];
    final now = DateTime.now();

    for (var playerMap in widget.allPlayers) {
      if (playerMap is Map<String, dynamic>) {
        final events = playerMap['events'];
        int phasesCompleted = 0;
        int latestCompletionTime = 0;

        if (events is Map && events.containsKey(_selectedEventId)) {
          final eventProgress =
              events[_selectedEventId] as Map<String, dynamic>;

          phasesCompleted =
              (eventProgress['currentPhase'] as num?)?.toInt() ?? 0;
          latestCompletionTime =
              (eventProgress['lastUpdateTime'] as num?)?.toInt() ?? 0;

          // Apply Time Filter
          if (_selectedTimeFilter == 'monthly' && latestCompletionTime > 0) {
            final completionDate = DateTime.fromMillisecondsSinceEpoch(
              latestCompletionTime,
            );
            if (completionDate.year != now.year ||
                completionDate.month != now.month) {
              phasesCompleted = 0; // Does not count for this month
            }
          }
        }

        if (phasesCompleted > 0) {
          ranking.add(
            RankingPlayerModel(
              objectId: playerMap['objectId'] ?? '',
              name: playerMap['name'] ?? 'Jogador',
              photoURL: playerMap['photoURL'],
              phasesCompleted: phasesCompleted,
              totalPhases: 10,
              position: 0,
            ),
          );
        }
      }
    }

    ranking.sort((a, b) => b.phasesCompleted.compareTo(a.phasesCompleted));

    int currentPosition = 1;
    for (int i = 0; i < ranking.length; i++) {
      if (i > 0 &&
          ranking[i].phasesCompleted == ranking[i - 1].phasesCompleted) {
        ranking[i].position = ranking[i - 1].position;
      } else {
        ranking[i].position = currentPosition;
      }
      currentPosition++;
    }

    setState(() {
      _currentRanking = ranking;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (widget.availableEvents.isEmpty) {
      return Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: Text(
            'Ranking',
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.w700,
              color: Colors.white,
              fontSize: 20,
            ),
          ),
          backgroundColor: Colors.transparent,
          elevation: 0,
        ),
        body: Center(
          child: Text(
            'Nenhum evento disponível.',
            style: GoogleFonts.inter(color: AppColors.cinzaMedio),
          ),
        ),
      );
    }

    List<RankingPlayerModel> top3 = [];
    List<RankingPlayerModel> others = [];

    if (_currentRanking.isNotEmpty) {
      top3 = _currentRanking.take(3).toList();
      if (_currentRanking.length > 3) {
        others = _currentRanking.skip(3).toList();
      }
    }

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Text(
          'Ranking',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w700,
            color: Colors.white,
            fontSize: 20,
            letterSpacing: 0.5,
          ),
        ),
        centerTitle: false,
        backgroundColor: Colors.transparent,
        elevation: 0,
        titleSpacing: 20,
      ),
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Time Filter Segmented Control
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: AppColors.darkCardColor,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.25),
                          blurRadius: 10,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: GestureDetector(
                            onTap: () {
                              setState(() {
                                _selectedTimeFilter = 'all_time';
                                _calculateRankingForSelectedEvent();
                              });
                            },
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              decoration: BoxDecoration(
                                gradient: _selectedTimeFilter == 'all_time'
                                    ? AppColors.gradienteVerdeVale
                                    : null,
                                color: _selectedTimeFilter == 'all_time'
                                    ? null
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                'Global',
                                textAlign: TextAlign.center,
                                style: GoogleFonts.inter(
                                  fontWeight: FontWeight.w700,
                                  color: _selectedTimeFilter == 'all_time'
                                      ? Colors.white
                                      : AppColors.cinzaMedio,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          ),
                        ),
                        Expanded(
                          child: GestureDetector(
                            onTap: () {
                              setState(() {
                                _selectedTimeFilter = 'monthly';
                                _calculateRankingForSelectedEvent();
                              });
                            },
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              decoration: BoxDecoration(
                                gradient: _selectedTimeFilter == 'monthly'
                                    ? AppColors.gradienteVerdeVale
                                    : null,
                                color: _selectedTimeFilter == 'monthly'
                                    ? null
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                'Mensal',
                                textAlign: TextAlign.center,
                                style: GoogleFonts.inter(
                                  fontWeight: FontWeight.w700,
                                  color: _selectedTimeFilter == 'monthly'
                                      ? Colors.white
                                      : AppColors.cinzaMedio,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  Text(
                    'SELECIONE O EVENTO',
                    style: GoogleFonts.inter(
                      color: AppColors.cinzaMedio,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.0,
                    ),
                  ),
                  const SizedBox(height: 8),
                  RankingEventSelector(
                    selectedEventId: _selectedEventId,
                    availableEvents: widget.availableEvents,
                    onChanged: (String? newValue) {
                      if (newValue != null && newValue != _selectedEventId) {
                        setState(() {
                          _selectedEventId = newValue;
                          _calculateRankingForSelectedEvent();
                        });
                      }
                    },
                  ),
                  const SizedBox(height: 28),

                  if (_currentRanking.isEmpty)
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 40.0),
                        child: Column(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: AppColors.verdeVale.withValues(alpha: 0.12),
                                border: Border.all(color: AppColors.verdeVale.withValues(alpha: 0.25)),
                              ),
                              child: const FaIcon(
                                FontAwesomeIcons.trophy,
                                size: 40,
                                color: AppColors.verdeVale,
                              ),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Nenhum jogador pontuou neste período.',
                              style: GoogleFonts.inter(color: AppColors.cinzaMedio),
                            ),
                          ],
                        ),
                      ),
                    )
                  else ...[
                    RankingPodium(top3: top3),
                    const SizedBox(height: 36),
                    if (others.isNotEmpty) ...[
                      Text(
                        'DEMAIS COLOCAÇÕES',
                        style: GoogleFonts.inter(
                          color: AppColors.cinzaMedio,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.0,
                        ),
                      ),
                      const SizedBox(height: 14),
                      RankingList(players: others),
                    ],
                  ],
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

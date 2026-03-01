import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:oenigma/core/models/ranking_player_model.dart';
import 'package:oenigma/core/models/event_model.dart';
import 'package:oenigma/core/utils/app_colors.dart';
import 'package:oenigma/features/ranking/widgets/ranking_event_selector.dart';
import 'package:oenigma/features/ranking/widgets/ranking_list.dart';
import 'package:oenigma/features/ranking/widgets/ranking_podium.dart';

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

    for (var playerMap in widget.allPlayers) {
      if (playerMap is Map<String, dynamic>) {
        final events = playerMap['events'];
        int phasesCompleted = 0;
          // Se quiser desempatar por tempo no futuro

        if (events is Map && events.containsKey(_selectedEventId)) {
          final eventProgress = events[_selectedEventId] as Map<String, dynamic>;
          // A lógica atual conta currentPhase como fases completadas
          phasesCompleted = (eventProgress['currentPhase'] as num?)?.toInt() ?? 0;
          // latestCompletionTime =
              (eventProgress['lastUpdateTime'] as num?)?.toInt() ?? 0;
        }

        if (phasesCompleted > 0) {
          ranking.add(
            RankingPlayerModel(
              uid: playerMap['uid'] ?? '',
              name: playerMap['name'] ?? 'Jogador',
              photoURL: playerMap['photoURL'],
              phasesCompleted: phasesCompleted,
              totalPhases: 10, // Default mock value if not available
              position: 0,
            ),
          );
        }
      }
    }

    // Ordenação simples por fases concluídas
    ranking.sort((a, b) => b.phasesCompleted.compareTo(a.phasesCompleted));

    // Atribuir posições considerando empates simples
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
        backgroundColor: darkBackground,
        appBar: AppBar(
          title: const Text('Ranking Global'),
          backgroundColor: Colors.transparent,
          elevation: 0,
        ),
        body: const Center(
          child: Text(
            'Nenhum evento disponível.',
            style: TextStyle(color: secondaryTextColor),
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
      backgroundColor: darkBackground,
      appBar: AppBar(
        title: const Text(
          'Ranking Global',
          style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Selecione o Evento',
                    style: TextStyle(
                      color: secondaryTextColor,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.5,
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
                  const SizedBox(height: 40),

                  if (_currentRanking.isEmpty)
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 40.0),
                        child: Column(
                          children: [
                            Icon(
                              Icons.emoji_events_outlined,
                              size: 64,
                              color: secondaryTextColor.withValues(alpha: 0.5),
                            ),
                            const SizedBox(height: 16),
                            const Text(
                              'Nenhum jogador pontuou neste evento ainda.',
                              style: TextStyle(color: secondaryTextColor),
                            ),
                          ],
                        ),
                      ),
                    )
                  else ...[
                    RankingPodium(top3: top3),
                    const SizedBox(height: 40),
                    if (others.isNotEmpty) ...[
                      const Text(
                        'DEMAIS COLOCAÇÕES',
                        style: TextStyle(
                          color: secondaryTextColor,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.5,
                        ),
                      ),
                      const SizedBox(height: 16),
                      RankingList(players: others),
                    ],
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

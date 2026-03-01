import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lottie/lottie.dart';
import 'package:oenigma/core/models/ranking_player_model.dart';
import 'package:oenigma/core/models/event_model.dart';
import 'package:oenigma/features/auth/providers/auth_provider.dart';

import 'package:oenigma/core/utils/app_colors.dart';

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
                  _buildEventSelector(),
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
                    _buildPodium(top3),
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
                      _buildRankingList(others),
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

  Widget _buildEventSelector() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: DropdownButton<String>(
        value: _selectedEventId,
        isExpanded: true,
        dropdownColor: cardColor,
        icon: const Icon(Icons.keyboard_arrow_down, color: primaryAmber),
        underline: const SizedBox(),
        onChanged: (String? newValue) {
          if (newValue != null && newValue != _selectedEventId) {
            setState(() {
              _selectedEventId = newValue;
              _calculateRankingForSelectedEvent();
            });
          }
        },
        items: widget.availableEvents.map<DropdownMenuItem<String>>((
          EventModel event,
        ) {
          return DropdownMenuItem<String>(
            value: event.id,
            child: Text(
              event.name,
              style: const TextStyle(
                color: textColor,
                fontWeight: FontWeight.bold,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildPodium(List<RankingPlayerModel> top3) {
    // Definindo cores e estilos para os lugares
    final podiumConfig = {
      1: {'color': const Color(0xFFFFC107), 'height': 160.0}, // Ouro
      2: {'color': const Color(0xFFE0E0E0), 'height': 120.0}, // Prata
      3: {'color': const Color(0xFFA1887F), 'height': 90.0}, // Bronze
    };

    final List<Widget> podiumPlaces = [];

    // Ordem visual: 2º, 1º, 3º
    if (top3.length > 1) {
      podiumPlaces.add(
        _buildPodiumPlace(
          top3[1],
          podiumConfig[2]!['height'] as double,
          podiumConfig[2]!['color'] as Color,
          place: 2,
        ),
      );
    }
    if (top3.isNotEmpty) {
      podiumPlaces.add(
        _buildPodiumPlace(
          top3[0],
          podiumConfig[1]!['height'] as double,
          podiumConfig[1]!['color'] as Color,
          isFirstPlace: true,
          place: 1,
        ),
      );
    }
    if (top3.length > 2) {
      podiumPlaces.add(
        _buildPodiumPlace(
          top3[2],
          podiumConfig[3]!['height'] as double,
          podiumConfig[3]!['color'] as Color,
          place: 3,
        ),
      );
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      mainAxisAlignment: MainAxisAlignment.center,
      children: podiumPlaces,
    );
  }

  Widget _buildPodiumPlace(
    RankingPlayerModel player,
    double height,
    Color color, {
    bool isFirstPlace = false,
    required int place,
  }) {
    return Expanded(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.center,
            children: [
              Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: color, width: 3),
                  boxShadow: isFirstPlace
                      ? [
                          BoxShadow(
                            color: color.withValues(alpha: 0.5),
                            blurRadius: 20,
                            spreadRadius: 2,
                          ),
                        ]
                      : [],
                ),
                child: CircleAvatar(
                  radius: isFirstPlace ? 40 : 30,
                  backgroundColor: darkBackground,
                  backgroundImage: player.photoURL != null
                      ? NetworkImage(player.photoURL!)
                      : null,
                  child: player.photoURL == null
                      ? Icon(
                          Icons.person,
                          size: isFirstPlace ? 30 : 20,
                          color: secondaryTextColor,
                        )
                      : null,
                ),
              ),
              if (isFirstPlace)
                Positioned(
                  top: -55,
                  child: Lottie.asset(
                    'assets/animations/trofel.json',
                    width: 70,
                    height: 70,
                    fit: BoxFit.contain,
                  ),
                ),
              Positioned(
                bottom: -12,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    "$placeº",
                    style: const TextStyle(
                      color: Colors.black,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Text(
            player.name.split(' ').first,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: textColor,
              fontSize: 14,
            ),
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Container(
            width: double.infinity,
            margin: const EdgeInsets.symmetric(horizontal: 4),
            height: height,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [color.withValues(alpha: 0.8), color.withValues(alpha: 0.3)],
              ),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(16),
              ),
              border: Border(
                top: BorderSide(color: color.withValues(alpha: 0.5), width: 1),
                left: BorderSide(color: color.withValues(alpha: 0.2), width: 1),
                right: BorderSide(color: color.withValues(alpha: 0.2), width: 1),
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '${player.phasesCompleted}',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const Text(
                  'Fases',
                  style: TextStyle(fontSize: 10, color: Colors.white70),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRankingList(List<RankingPlayerModel> players) {
    final currentUserId = ref.read(authRepositoryProvider).currentUser?.uid;

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: players.length,
      separatorBuilder: (context, index) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final player = players[index];
        final isCurrentUser = player.uid == currentUserId;

        return Container(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(20),
            border: isCurrentUser
                ? Border.all(color: primaryAmber, width: 1.5)
                : Border.all(color: Colors.white.withValues(alpha: 0.05)),
            boxShadow: isCurrentUser
                ? [
                    BoxShadow(
                      color: primaryAmber.withValues(alpha: 0.15),
                      blurRadius: 10,
                    ),
                  ]
                : [],
          ),
          child: Row(
            children: [
              SizedBox(
                width: 30,
                child: Text(
                  player.position.toString(),
                  style: const TextStyle(
                    color: secondaryTextColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isCurrentUser ? primaryAmber : Colors.transparent,
                    width: 2,
                  ),
                ),
                child: CircleAvatar(
                  radius: 20,
                  backgroundImage: player.photoURL != null
                      ? NetworkImage(player.photoURL!)
                      : null,
                  child: player.photoURL == null
                      ? const Icon(
                          Icons.person,
                          size: 20,
                          color: secondaryTextColor,
                        )
                      : null,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      player.name,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: textColor,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${player.phasesCompleted}',
                    style: const TextStyle(
                      color: primaryAmber,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const Text(
                    'Fases',
                    style: TextStyle(color: secondaryTextColor, fontSize: 10),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

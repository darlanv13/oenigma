import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:lottie/lottie.dart';
import 'package:oenigma/models/event_model.dart';
import '../../models/ranking_player_model.dart';
import '../../services/auth_service.dart';
import '../../utils/app_colors.dart';
import '../stores/ranking_store.dart';

class RankingScreen extends StatefulWidget {
  final List<EventModel> availableEvents;
  final List<dynamic> allPlayers;

  const RankingScreen({
    super.key,
    required this.availableEvents,
    required this.allPlayers,
  });

  @override
  State<RankingScreen> createState() => _RankingScreenState();
}

class _RankingScreenState extends State<RankingScreen> {
  final AuthService _authService = AuthService();
  final RankingStore _store = RankingStore();

  @override
  void initState() {
    super.initState();
    _store.init(widget.availableEvents, widget.allPlayers);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: darkBackground,
      appBar: AppBar(
        title: const Text(
          'Ranking Global',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: darkBackground,
        elevation: 0,
      ),
      body: Column(
        children: [
          _buildEventSelector(),
          Expanded(
            child: Observer(
              builder: (_) {
                if (_store.currentRanking.isEmpty) {
                  return const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.leaderboard_outlined,
                          size: 60,
                          color: secondaryTextColor,
                        ),
                        SizedBox(height: 16),
                        Text(
                          'Nenhum jogador classificado ainda.',
                          style: TextStyle(color: secondaryTextColor),
                        ),
                      ],
                    ),
                  );
                }
                return ListView(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
                  children: [
                    if (_store.currentRanking.isNotEmpty)
                      _buildPodium(_store.currentRanking.take(3).toList()),
                    const SizedBox(height: 40),
                    if (_store.currentRanking.length > 3)
                      _buildRankingList(_store.currentRanking.skip(3).toList()),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEventSelector() {
    if (widget.availableEvents.isEmpty) {
      return Container(
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Text(
          "Nenhum evento ativo para exibir.",
          textAlign: TextAlign.center,
          style: TextStyle(color: secondaryTextColor),
        ),
      );
    }
    return Observer(
      builder: (_) => Container(
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        child: DropdownButtonFormField<String>(
          value: _store.selectedEventId,
          decoration: InputDecoration(
            filled: true,
            fillColor: cardColor,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 20,
              vertical: 16,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide.none,
            ),
          ),
          dropdownColor: cardColor,
          icon: const Icon(
            Icons.keyboard_arrow_down_rounded,
            color: primaryAmber,
          ),
          onChanged: (String? newValue) {
            _store.setSelectedEventId(newValue);
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
                            color: color.withOpacity(0.5),
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
                colors: [color.withOpacity(0.8), color.withOpacity(0.3)],
              ),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(16),
              ),
              border: Border(
                top: BorderSide(color: color.withOpacity(0.5), width: 1),
                left: BorderSide(color: color.withOpacity(0.2), width: 1),
                right: BorderSide(color: color.withOpacity(0.2), width: 1),
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
    final currentUserId = _authService.currentUser?.uid;

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
                : Border.all(color: Colors.white.withOpacity(0.05)),
            boxShadow: isCurrentUser
                ? [
                    BoxShadow(
                      color: primaryAmber.withOpacity(0.15),
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

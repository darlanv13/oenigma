import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:oenigma/models/event_model.dart';
import '../models/ranking_player_model.dart';
import '../services/auth_service.dart';
import '../utils/app_colors.dart';

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

  late String _selectedEventId;
  late List<RankingPlayerModel> _currentRanking;

  @override
  void initState() {
    super.initState();
    _selectedEventId = widget.availableEvents.isNotEmpty
        ? widget.availableEvents.first.id
        : '';
    _calculateRankingForSelectedEvent();
  }

  void _calculateRankingForSelectedEvent() {
    if (_selectedEventId.isEmpty) {
      setState(() => _currentRanking = []);
      return;
    }

    final selectedEvent = widget.availableEvents.firstWhere(
      (e) => e.id == _selectedEventId,
    );
    // AQUI ESTÁ A CORREÇÃO: agora 'phases' existe no modelo
    final totalPhases = selectedEvent.phases.length;

    var rankedPlayers = widget.allPlayers
        .where(
          (p) => p['events'] != null && p['events'][_selectedEventId] != null,
        )
        .map((p) {
          final progress = p['events'][_selectedEventId];
          return RankingPlayerModel(
            uid: p['id'],
            name: p['name'] ?? 'Anônimo',
            photoURL: p['photoURL'],
            phasesCompleted: progress['currentPhase'] != null
                ? progress['currentPhase'] - 1
                : 0,
            totalPhases: totalPhases,
          );
        })
        .toList();

    rankedPlayers.sort(
      (a, b) => b.phasesCompleted.compareTo(a.phasesCompleted),
    );

    setState(() {
      _currentRanking = rankedPlayers.asMap().entries.map((entry) {
        entry.value.position = entry.key + 1;
        return entry.value;
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Ranking Global',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          _buildEventSelector(),
          Expanded(
            child: _currentRanking.isEmpty
                ? const Center(
                    child: Text('Nenhum jogador no ranking para este evento.'),
                  )
                : ListView(
                    padding: const EdgeInsets.all(16.0),
                    children: [
                      if (_currentRanking.isNotEmpty)
                        _buildPodium(_currentRanking.take(3).toList()),
                      const SizedBox(height: 32),
                      if (_currentRanking.length > 3)
                        _buildRankingList(_currentRanking.skip(3).toList()),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildEventSelector() {
    if (widget.availableEvents.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(16.0),
        child: Text(
          "Nenhum evento ativo para exibir o ranking.",
          textAlign: TextAlign.center,
        ),
      );
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: DropdownButtonFormField<String>(
        value: _selectedEventId,
        decoration: InputDecoration(
          filled: true,
          fillColor: cardColor,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 8,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15),
            borderSide: BorderSide.none,
          ),
        ),
        dropdownColor: cardColor,
        icon: const Icon(Icons.arrow_drop_down, color: primaryAmber),
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
              style: const TextStyle(color: textColor),
              overflow: TextOverflow.ellipsis,
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildPodium(List<RankingPlayerModel> top3) {
    final podiumColors = {
      1: Colors.amber[600],
      2: Colors.grey[400],
      3: Colors.brown[400],
    };

    final podiumHeights = {1: 150.0, 2: 110.0, 3: 80.0};
    final List<Widget> podiumPlaces = [];

    if (top3.length > 1) {
      podiumPlaces.add(
        _buildPodiumPlace(top3[1], podiumHeights[2]!, podiumColors[2]!),
      );
    }
    if (top3.isNotEmpty) {
      podiumPlaces.add(
        _buildPodiumPlace(
          top3[0],
          podiumHeights[1]!,
          podiumColors[1]!,
          isFirstPlace: true,
        ),
      );
    }
    if (top3.length > 2) {
      podiumPlaces.add(
        _buildPodiumPlace(top3[2], podiumHeights[3]!, podiumColors[3]!),
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
  }) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.center,
          children: [
            CircleAvatar(
              radius: isFirstPlace ? 45 : 35,
              backgroundColor: color,
              child: CircleAvatar(
                radius: isFirstPlace ? 42 : 32,
                backgroundImage: player.photoURL != null
                    ? NetworkImage(player.photoURL!)
                    : null,
                child: player.photoURL == null
                    ? const Icon(Icons.person, size: 30)
                    : null,
              ),
            ),
            if (isFirstPlace)
              Positioned(
                top: -60,
                child: Lottie.asset(
                  'assets/animations/trofel.json',
                  width: 80,
                  height: 80,
                ),
              ),
            Positioned(
              bottom: -10,
              child: Icon(Icons.military_tech, color: color, size: 30),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Text(
          player.name.split(' ').first,
          style: const TextStyle(fontWeight: FontWeight.bold, color: textColor),
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 4),
        Container(
          width: 90,
          height: height,
          decoration: BoxDecoration(
            color: color.withOpacity(0.8),
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(10),
              topRight: Radius.circular(10),
            ),
            boxShadow: [
              BoxShadow(
                color: color.withOpacity(0.5),
                blurRadius: 15,
                spreadRadius: 2,
              ),
            ],
          ),
          child: Center(
            child: Text(
              '${player.position}º',
              style: const TextStyle(
                fontSize: 36,
                fontWeight: FontWeight.bold,
                color: darkBackground,
              ),
            ),
          ),
        ),
      ],
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
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(15),
            border: isCurrentUser
                ? Border.all(color: primaryAmber, width: 1.5)
                : null,
            boxShadow: isCurrentUser
                ? [
                    BoxShadow(
                      color: primaryAmber.withOpacity(0.3),
                      blurRadius: 8,
                    ),
                  ]
                : null,
          ),
          child: Row(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: isCurrentUser
                    ? primaryAmber
                    : secondaryTextColor,
                child: Text(
                  player.position.toString(),
                  style: TextStyle(
                    color: isCurrentUser ? darkBackground : textColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              CircleAvatar(
                radius: 20,
                backgroundImage: player.photoURL != null
                    ? NetworkImage(player.photoURL!)
                    : null,
                child: player.photoURL == null
                    ? const Icon(Icons.person, size: 20)
                    : null,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  player.name,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                '${player.phasesCompleted} / ${player.totalPhases}',
                style: const TextStyle(
                  color: secondaryTextColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

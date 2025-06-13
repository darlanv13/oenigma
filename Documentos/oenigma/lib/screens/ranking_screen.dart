import 'package:flutter/material.dart';
import '../models/ranking_player_model.dart';
import '../services/firebase_service.dart';
import '../utils/app_colors.dart';

class RankingScreen extends StatefulWidget {
  final String eventId; // ID do evento para mostrar o ranking
  final String eventName;

  const RankingScreen({
    super.key,
    required this.eventId,
    required this.eventName,
  });

  @override
  State<RankingScreen> createState() => _RankingScreenState();
}

class _RankingScreenState extends State<RankingScreen> {
  final FirebaseService _firebaseService = FirebaseService();
  late Future<List<RankingPlayerModel>> _rankingFuture;

  @override
  void initState() {
    super.initState();
    _rankingFuture = _firebaseService.getRankingForEvent(widget.eventId);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          children: [
            const Text(
              'Ranking',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            Text(
              widget.eventName,
              style: const TextStyle(fontSize: 14, color: secondaryTextColor),
            ),
          ],
        ),
        centerTitle: true,
      ),
      body: FutureBuilder<List<RankingPlayerModel>>(
        future: _rankingFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: primaryAmber),
            );
          }
          if (snapshot.hasError) {
            return Center(
              child: Text('Erro ao carregar o ranking: ${snapshot.error}'),
            );
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(
              child: Text('Nenhum jogador no ranking para este evento.'),
            );
          }

          final players = snapshot.data!;
          final top3 = players.take(3).toList();
          final others = players.skip(3).toList();

          return RefreshIndicator(
            onRefresh: () async {
              setState(() {
                _rankingFuture = _firebaseService.getRankingForEvent(
                  widget.eventId,
                );
              });
            },
            child: ListView(
              padding: const EdgeInsets.all(16.0),
              children: [
                if (top3.isNotEmpty) _buildPodium(top3),
                const SizedBox(height: 32),
                if (others.isNotEmpty) _buildRankingList(others),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildPodium(List<RankingPlayerModel> top3) {
    return SizedBox(
      height: 250,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (top3.length > 1) _buildPodiumPlace(top3[1], 150, '2º'),
          if (top3.isNotEmpty)
            _buildPodiumPlace(top3[0], 200, '1º', isFirstPlace: true),
          if (top3.length > 2) _buildPodiumPlace(top3[2], 120, '3º'),
        ],
      ),
    );
  }

  Widget _buildPodiumPlace(
    RankingPlayerModel player,
    double height,
    String place, {
    bool isFirstPlace = false,
  }) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        CircleAvatar(
          radius: 35,
          backgroundColor: isFirstPlace ? primaryAmber : secondaryTextColor,
          backgroundImage: player.photoURL != null
              ? NetworkImage(player.photoURL!)
              : null,
          child: player.photoURL == null
              ? const Icon(Icons.person, size: 30)
              : null,
        ),
        const SizedBox(height: 8),
        Text(
          player.name.split(' ').first,
          style: const TextStyle(fontWeight: FontWeight.bold, color: textColor),
        ),
        Text(
          '${player.phasesCompleted}/${player.totalPhases}',
          style: const TextStyle(color: secondaryTextColor, fontSize: 12),
        ),
        const SizedBox(height: 8),
        Container(
          width: 80,
          height: height,
          decoration: BoxDecoration(
            color: isFirstPlace ? primaryAmber.withOpacity(0.8) : cardColor,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(10),
              topRight: Radius.circular(10),
            ),
          ),
          child: Center(
            child: Text(
              place,
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: isFirstPlace ? darkBackground : textColor,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRankingList(List<RankingPlayerModel> players) {
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: players.length,
      separatorBuilder: (context, index) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final player = players[index];
        return Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(15),
          ),
          child: Row(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: secondaryTextColor,
                child: Text(
                  player.position.toString(),
                  style: const TextStyle(
                    color: darkBackground,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      player.name,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Fases Concluídas: ${player.phasesCompleted}/${player.totalPhases}',
                      style: const TextStyle(
                        color: secondaryTextColor,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: primaryAmber.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${(player.progress * 100).toStringAsFixed(0)}%',
                  style: const TextStyle(
                    color: primaryAmber,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

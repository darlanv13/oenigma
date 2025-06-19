import 'package:flutter/material.dart';
import '../models/event_model.dart';
import '../services/auth_service.dart';
import '../services/firebase_service.dart';
import '../utils/app_colors.dart';
import '../widgets/event_card.dart';
import 'profile_screen.dart';
import 'ranking_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final FirebaseService _firebaseService = FirebaseService();
  final AuthService _authService = AuthService();
  late Future<List<dynamic>> _dataFuture;

  @override
  void initState() {
    super.initState();
    _dataFuture = _loadData();
  }

  // A função de carregamento permanece simples
  Future<List<dynamic>> _loadData() async {
    final userId = _authService.currentUser!.uid;
    return await Future.wait([
      _firebaseService.getEvents(),
      _firebaseService.getPlayerDetails(userId),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: darkBackground,
      body: SafeArea(
        child: FutureBuilder<List<dynamic>>(
          future: _dataFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: CircularProgressIndicator(color: primaryAmber),
              );
            }
            if (snapshot.hasError ||
                !snapshot.hasData ||
                snapshot.data!.length < 2) {
              return Center(
                child: Text(
                  'Erro ao carregar dados: ${snapshot.error}',
                  style: const TextStyle(color: Colors.red),
                ),
              );
            }

            final List<EventModel> events = snapshot.data![0];
            final Map<String, dynamic>? playerData = snapshot.data![1];

            return RefreshIndicator(
              onRefresh: () async {
                setState(() {
                  _dataFuture = _loadData();
                });
                await _dataFuture;
              },
              color: primaryAmber,
              backgroundColor: cardColor,
              child: CustomScrollView(
                slivers: [
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: _buildFinalProfileCard(
                        context,
                        playerData,
                        events,
                      ),
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 0),
                      child: _buildEventsSectionHeader(),
                    ),
                  ),
                  _buildEventsGrid(events),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  // CARD DE PERFIL FINAL, COMPACTO E ESTILIZADO
  Widget _buildFinalProfileCard(
    BuildContext context,
    Map<String, dynamic>? playerData,
    List<EventModel> events,
  ) {
    final authService = AuthService();
    final String fullName = playerData?['name'] ?? 'Jogador';
    final String firstName = fullName.split(' ').first;
    final String? photoUrl = playerData?['photoURL'];
    final String cpf = playerData?['cpf'] ?? '0000';

    // Usando "Fases Concluídas" como a métrica por enquanto
    int totalPhasesCompleted = 0;
    if (playerData != null && playerData['events'] is Map) {
      (playerData['events'] as Map).forEach((key, value) {
        if (value is Map && value.containsKey('currentPhase')) {
          totalPhasesCompleted += (value['currentPhase'] as int) - 1;
        }
      });
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min, // Para manter o card compacto
        children: [
          // --- Linha Superior: Avatar, Saudação e Menu ---
          Row(
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: primaryAmber, width: 1.0),
                ),
                child: CircleAvatar(
                  radius: 28,
                  backgroundColor: darkBackground,
                  backgroundImage: (photoUrl != null && photoUrl.isNotEmpty)
                      ? NetworkImage(photoUrl)
                      : null,
                  child: (photoUrl == null || photoUrl.isEmpty)
                      ? const Icon(
                          Icons.person,
                          color: secondaryTextColor,
                          size: 28,
                        )
                      : null,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Olá, $firstName!',
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: textColor,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              PopupMenuButton<String>(
                onSelected: (value) {
                  if (value == 'profile') {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const ProfileScreen()),
                    );
                  } else if (value == 'logout') {
                    authService.signOut();
                  }
                },
                icon: const Icon(
                  Icons.settings_outlined,
                  color: secondaryTextColor,
                ),
                color: cardColor,
                itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
                  const PopupMenuItem<String>(
                    value: 'profile',
                    child: Text('Editar Perfil'),
                  ),
                  const PopupMenuItem<String>(
                    value: 'logout',
                    child: Text('Sair'),
                  ),
                ],
              ),
            ],
          ),
          const Divider(height: 24, thickness: 0.5, color: secondaryTextColor),
          // --- Linha Inferior: Stats e Botões ---
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Coluna de Stats à esquerda
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Estatísticas',
                    style: TextStyle(
                      fontSize: 12,
                      color: secondaryTextColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      // Stat 1: Pontuação (Fases com estrela)
                      const Icon(Icons.star, color: primaryAmber, size: 18),
                      const SizedBox(width: 4),
                      Text(
                        totalPhasesCompleted.toString(),
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(width: 16),
                      // Stat 2: ID do Jogador
                      const Icon(
                        Icons.badge_outlined,
                        color: secondaryTextColor,
                        size: 16,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'ID: ${cpf.substring(cpf.length - 11)}',
                        style: const TextStyle(
                          fontSize: 14,
                          color: secondaryTextColor,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              // Botão de Ranking à direita
              TextButton.icon(
                onPressed: () {
                  if (events.isNotEmpty) {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => RankingScreen(
                          eventId: events.first.id,
                          eventName: events.first.name,
                        ),
                      ),
                    );
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Não há eventos para ver o ranking.'),
                      ),
                    );
                  }
                },
                icon: const Icon(Icons.leaderboard_outlined, size: 20),
                label: const Text('Ranking'),
                style: TextButton.styleFrom(
                  foregroundColor: textColor,
                  backgroundColor: Colors.white.withOpacity(0.08),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Demais widgets da tela (sem alteração)
  Widget _buildEventsSectionHeader() {
    return const Text(
      "EVENTOS DISPONÍVEIS",
      style: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.bold,
        color: secondaryTextColor,
        letterSpacing: 1.5,
      ),
    );
  }

  Widget _buildEventsGrid(List<EventModel> events) {
    if (events.isEmpty) {
      return const SliverToBoxAdapter(
        child: Center(
          child: Padding(
            padding: EdgeInsets.all(40.0),
            child: Text(
              'Nenhum evento encontrado no momento.',
              style: TextStyle(color: secondaryTextColor),
            ),
          ),
        ),
      );
    }
    return SliverPadding(
      padding: const EdgeInsets.all(16.0),
      sliver: SliverGrid(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: 0.7,
        ),
        delegate: SliverChildBuilderDelegate(
          (context, index) => EventCard(event: events[index]),
          childCount: events.length,
        ),
      ),
    );
  }
}

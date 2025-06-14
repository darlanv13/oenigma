import 'package:flutter/material.dart';
import '../models/event_model.dart';
import '../services/auth_service.dart';
import '../services/firebase_service.dart';
import '../utils/app_colors.dart';
import '../widgets/event_card.dart';
import '../widgets/nav_button.dart';
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

  Future<List<dynamic>> _loadData() async {
    final userId = _authService.currentUser!.uid;
    // Busca os eventos e os dados do jogador em paralelo
    return await Future.wait([
      _firebaseService.getEvents(),
      _firebaseService.getPlayerDetails(userId),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar(),
      body: FutureBuilder<List<dynamic>>(
        future: _dataFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: primaryAmber),
            );
          }
          if (snapshot.hasError) {
            return Center(
              child: Text(
                'Erro ao carregar dados: ${snapshot.error}',
                style: const TextStyle(color: Colors.red),
              ),
            );
          }
          if (!snapshot.hasData || snapshot.data == null) {
            return const Center(
              child: Text('Não foi possível carregar os dados.'),
            );
          }

          final List<EventModel> events = snapshot.data![0];
          final Map<String, dynamic>? playerData = snapshot.data![1];

          return RefreshIndicator(
             onRefresh: () async {
              // 1. Atualiza o estado para que o FutureBuilder comece a ouvir a nova operação de carregamento.
              setState(() {
                _dataFuture = _loadData();
              });
              // 2. Aguarda a conclusão da operação. Isso garante que o ícone de "refresh"
              //    permaneça visível até que os dados sejam carregados, sem retornar um valor inválido.
              await _dataFuture;
            },
            color: primaryAmber,
            backgroundColor: cardColor,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Column(
                children: [
                  const SizedBox(height: 16),
                  _buildProfileCard(playerData),
                  const SizedBox(height: 24),
                  _buildNavButtons(events),
                  const SizedBox(height: 32),
                  _buildEventsSection(events),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildProfileCard(Map<String, dynamic>? playerData) {
    final String fullName = playerData?['name'] ?? 'Jogador';
    final String firstName = fullName.split(' ').first;
    final String cpf = playerData?['cpf'] ?? 'CPF não informado';
    final String? photoUrl = playerData?['photoURL'];

    final int activeEventsCount = (playerData?['events'] as Map?)?.length ?? 0;
    String getPlayerTitle(int count) {
      if (count >= 3) return 'Mestre dos Enigmas';
      if (count >= 1) return 'Detetive Astuto';
      return 'Noviço Explorador';
    }

    final String playerTitle = getPlayerTitle(activeEventsCount);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: primaryAmber, width: 2),
            ),
            child: CircleAvatar(
              radius: 30,
              backgroundColor: darkBackground,
              backgroundImage: (photoUrl != null && photoUrl.isNotEmpty)
                  ? NetworkImage(photoUrl)
                  : null,
              child: (photoUrl == null || photoUrl.isEmpty)
                  ? Text(
                      firstName.isNotEmpty ? firstName[0].toUpperCase() : 'J',
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: textColor,
                      ),
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
                  'Olá, $firstName!',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: textColor,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  'ID: $cpf',
                  style: const TextStyle(
                    fontSize: 10,
                    color: secondaryTextColor,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              _buildProfileStat('Status', playerTitle),
              const SizedBox(height: 8),
              _buildProfileStat('Eventos Ativos', activeEventsCount.toString()),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildProfileStat(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: secondaryTextColor,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.bold,
            color: primaryAmber,
          ),
        ),
      ],
    );
  }

  Widget _buildEventsSection(List<EventModel> events) {
    return Column(
      children: [
        const Text(
          "Eventos",
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: textColor,
          ),
        ),
        const SizedBox(height: 20),
        if (events.isEmpty)
          const Center(
            child: Padding(
              padding: EdgeInsets.all(20.0),
              child: Text(
                'Nenhum evento encontrado.',
                style: TextStyle(color: secondaryTextColor),
              ),
            ),
          )
        else
          GridView.builder(
            itemCount: events.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 14,
              mainAxisSpacing: 14,
              childAspectRatio: 0.65,
            ),
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemBuilder: (context, index) => EventCard(event: events[index]),
          ),
      ],
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      automaticallyImplyLeading: false,
      title: const Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            "ENIGMA",
            style: TextStyle(
              color: textColor,
              fontWeight: FontWeight.bold,
              fontSize: 18,
              letterSpacing: 2,
            ),
          ),
          Text(
            "CITY",
            style: TextStyle(
              color: primaryAmber,
              fontWeight: FontWeight.w300,
              fontSize: 14,
              letterSpacing: 3,
            ),
          ),
        ],
      ),
      centerTitle: true,
    );
  }

  Widget _buildNavButtons(List<EventModel> events) {
    final AuthService authService = AuthService();
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        GestureDetector(
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(builder: (context) => const ProfileScreen()),
            );
          },
          child: const NavButton(icon: Icons.person_outline, label: "Perfil"),
        ),
        GestureDetector(
          onTap: () {
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
          child: const NavButton(
            icon: Icons.bar_chart,
            label: "Ranking",
            isActive: true,
          ),
        ),
        const NavButton(icon: Icons.rule, label: "Regras"),
        GestureDetector(
          onTap: () async {
            await authService.signOut();
          },
          child: const NavButton(icon: Icons.logout, label: "Sair"),
        ),
      ],
    );
  }
}

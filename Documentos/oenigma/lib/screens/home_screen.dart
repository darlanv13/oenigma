import 'package:flutter/material.dart';
import '../models/event_model.dart';
import '../services/auth_service.dart';
import '../services/firebase_service.dart';
import '../utils/app_colors.dart';
import '../widgets/event_card.dart';
import '../widgets/profile_action_button.dart';
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

          // A lista de eventos já está disponível aqui!
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
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Column(
                children: [
                  const SizedBox(height: 16),
                  // --- CORREÇÃO AQUI: Passe 'events' como parâmetro ---
                  _buildProfileCard(playerData, events),
                  const SizedBox(height: 16),
                  _buildEventsSection(events),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // Substitua o seu método _buildProfileStat por este:
  Widget _buildProfileStat(String label, String value) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: textColor,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(
            fontSize: 9,
            color: secondaryTextColor,
          ),
        ),
      ],
    );
  }

  Widget _buildProfileCard(Map<String, dynamic>? playerData, List<EventModel> events) {
    // A linha abaixo foi REMOVIDA, pois não é mais necessária.
    // final List<EventModel> events = ...

    final String fullName = playerData?['name'] ?? 'Jogador';
    final String firstName = fullName.split(' ').first;
    final String cpf = playerData?['cpf'] ?? 'Não informado';
    final String? photoUrl = playerData?['photoURL'];

    final int activeEventsCount = (playerData?['events'] as Map?)?.length ?? 0;
    String getPlayerTitle(int count) {
      if (count >= 3) return 'Mestre dos Enigmas';
      if (count >= 1) return 'Detetive Astuto';
      return 'Noviço Explorador';
    }

    final String playerTitle = getPlayerTitle(activeEventsCount);
    final AuthService authService = AuthService();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [cardColor, const Color(0xFF2a2a2a)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(25),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(3.0),
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [primaryAmber, Colors.orangeAccent],
                  ),
                ),
                child: CircleAvatar(
                  radius: 26,
                  backgroundColor: darkBackground,
                  backgroundImage: (photoUrl != null && photoUrl.isNotEmpty)
                      ? NetworkImage(photoUrl)
                      : null,
                  child: (photoUrl == null || photoUrl.isEmpty)
                      ? Text(
                          firstName.isNotEmpty ? firstName[0].toUpperCase() : 'J',
                          style: const TextStyle(
                            fontSize: 28,
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
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: textColor,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding:
                          const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                          color: primaryAmber.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                          border:
                              Border.all(color: primaryAmber.withOpacity(0.5))),
                      child: Text(
                        playerTitle.toUpperCase(),
                        style: const TextStyle(
                          color: primaryAmber,
                          fontWeight: FontWeight.bold,
                          fontSize: 7,
                          letterSpacing: 0.8,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              ProfileActionButton(
                icon: Icons.logout_outlined,
                tooltip: 'Sair',
                onTap: () async => await authService.signOut(),
              ),
            ],
            
          ),
          SizedBox(height: 9.0,),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildProfileStat('Eventos Ativos', activeEventsCount.toString()),
              Flexible(
                  child: _buildProfileStat('ID de Jogador',
                      cpf.substring(cpf.length - 11))),
            ],
          ),
          const Divider(
            height: 32,
            thickness: 0.5,
            color: secondaryTextColor,
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              ProfileActionButton(
                icon: Icons.person_outline,
                tooltip: 'Perfil',
                onTap: () => Navigator.of(context)
                    .push(MaterialPageRoute(builder: (context) => const ProfileScreen())),
              ),
              ProfileActionButton(
                icon: Icons.bar_chart_outlined,
                tooltip: 'Ranking',
                onTap: () {
                  // A variável 'events' agora está disponível diretamente aqui!
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
              ),
              ProfileActionButton(
                icon: Icons.rule_folder_outlined,
                tooltip: 'Regras',
                onTap: () {},
              ),
              ProfileActionButton(
                icon: Icons.support_agent_outlined,
                tooltip: 'Suporte',
                onTap: () {},
              ),
              ProfileActionButton(
                icon: Icons.info_outline,
                tooltip: 'Sobre',
                onTap: () {},
              ),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildEventsSection(List<EventModel> events) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const Text(
          "EVENTOS DISPONÍVEIS",
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: secondaryTextColor,
            letterSpacing: 1.5,
          ),
        ),
        const SizedBox(height: 20),
        if (events.isEmpty)
          const Center(
            child: Padding(
              padding: EdgeInsets.all(20.0),
              child: Text(
                'Nenhum evento encontrado no momento.',
                style: TextStyle(color: secondaryTextColor),
              ),
            ),
          )
        else
          GridView.builder(
            itemCount: events.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              // Ajuste na proporção para o novo design do card
              childAspectRatio: 0.7,
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
      automaticallyImplyLeading: true,
      title: const Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            "ENIGMA",
            style: TextStyle(
              color: textColor,
              fontWeight: FontWeight.bold,
              fontSize: 16,
              letterSpacing: 2,
            ),
          ),
          Text(
            "CITY",
            style: TextStyle(
              color: primaryAmber,
              fontWeight: FontWeight.w300,
              fontSize: 12,
              letterSpacing: 3,
            ),
          ),
        ],
      ),
      centerTitle: true,
    );
  }
}

import 'dart:async';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:oenigma/app_gamer/screens/profile_screen.dart';
import 'package:oenigma/app_gamer/screens/wallet_screen.dart';
import 'package:oenigma/app_gamer/widgets/event_card.dart';
import 'package:oenigma/models/event_model.dart';
import 'package:oenigma/models/user_wallet_model.dart';
import 'package:oenigma/services/auth_service.dart';
import 'package:oenigma/services/firebase_service.dart';
import 'package:oenigma/utils/app_colors.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  final FirebaseService _firebaseService = FirebaseService();
  final AuthService _authService = AuthService();

  // Estado
  bool _isLoading = true;
  String? _errorMessage;

  List<EventModel> _events = [];
  Map<String, dynamic> _playerData = {};
  UserWalletModel? _walletData;
  String _selectedFilter = 'Todos';

  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;
  final PageController _bannerController = PageController();
  Timer? _bannerTimer;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    // Inicia carregamento após build para evitar travamento da UI
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initData();
      _startBannerAutoScroll();
    });
  }

  void _setupAnimations() {
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOut,
    );
  }

  @override
  void dispose() {
    _bannerTimer?.cancel();
    _bannerController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  void _startBannerAutoScroll() {
    _bannerTimer = Timer.periodic(const Duration(seconds: 6), (Timer timer) {
      if (_bannerController.hasClients) {
        final nextPage = (_bannerController.page?.toInt() ?? 0) + 1;
        _bannerController.animateToPage(
          nextPage % 3,
          duration: const Duration(milliseconds: 600),
          curve: Curves.easeInOut,
        );
      }
    });
  }

  Future<void> _initData() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // 1. Carrega Eventos (Prioridade)
      final homeData = await _firebaseService.getHomeScreenData().timeout(
        const Duration(seconds: 15),
        onTimeout: () => throw TimeoutException("Timeout"),
      );

      final List<dynamic> eventsData = homeData['events'] ?? [];
      final loadedEvents = eventsData
          .map((e) => EventModel.fromMap(Map<String, dynamic>.from(e)))
          .toList();

      if (mounted) {
        setState(() {
          _events = loadedEvents;
          _playerData = Map<String, dynamic>.from(homeData['player'] ?? {});
          _isLoading = false; // Libera UI aqui
        });
        _fadeController.forward();
      }

      // 2. Carrega Carteira (Segundo Plano - não trava se falhar)
      _fetchWalletBackground();
    } catch (e) {
      print("Erro Home: $e");
      if (mounted)
        setState(() {
          _isLoading = false;
          _errorMessage = "Erro ao conectar.";
        });
    }
  }

  Future<void> _fetchWalletBackground() async {
    try {
      final wallet = await _firebaseService.getUserWalletData();
      if (mounted) setState(() => _walletData = wallet);
    } catch (_) {
      // Falha silenciosa na carteira (ProfileScreen buscará se necessário)
    }
  }

  // --- UI ---

  @override
  Widget build(BuildContext context) {
    if (_errorMessage != null) return _buildErrorState();
    if (_isLoading && _events.isEmpty)
      return const Scaffold(
        backgroundColor: darkBackground,
        body: Center(child: CircularProgressIndicator(color: primaryAmber)),
      );

    return Scaffold(
      backgroundColor: darkBackground,
      body: RefreshIndicator(
        color: primaryAmber,
        backgroundColor: cardColor,
        onRefresh: _initData,
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            _buildSlimAppBar(),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: _buildBannerSection(),
                ),
              ),
            ),
            SliverToBoxAdapter(child: _buildFilters()),
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              sliver: SliverToBoxAdapter(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "MISSÕES",
                      style: GoogleFonts.orbitron(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      "${_filteredEvents.length}",
                      style: GoogleFonts.orbitron(color: primaryAmber),
                    ),
                  ],
                ),
              ),
            ),
            _buildEventsGrid(),
            const SliverPadding(padding: EdgeInsets.only(bottom: 80)),
          ],
        ),
      ),
    );
  }

  Widget _buildSlimAppBar() {
    final photoUrl = _playerData['photoURL'];
    final name = _playerData['name']?.toString().split(' ').first ?? 'Agente';
    final balanceText = _walletData != null
        ? "R\$ ${_walletData!.balance.toStringAsFixed(2)}"
        : "...";

    return SliverAppBar(
      backgroundColor: darkBackground.withOpacity(0.95),
      floating: true,
      pinned: true,
      elevation: 0,
      automaticallyImplyLeading: false,
      toolbarHeight: 70,
      flexibleSpace: SafeArea(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            border: Border(bottom: BorderSide(color: Colors.white10)),
          ),
          child: Row(
            children: [
              GestureDetector(
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ProfileScreen(
                      playerData: _playerData,
                      walletData: _walletData, // Agora é opcional, sem erro!
                    ),
                  ),
                ),
                child: Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: primaryAmber),
                  ),
                  child: CircleAvatar(
                    radius: 20,
                    backgroundColor: cardColor,
                    backgroundImage:
                        (photoUrl != null && photoUrl.startsWith('http'))
                        ? CachedNetworkImageProvider(photoUrl)
                        : null,
                    child: (photoUrl == null)
                        ? const Icon(Icons.person, color: Colors.white54)
                        : null,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Olá, $name",
                      style: GoogleFonts.inter(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const Text(
                      "Online",
                      style: TextStyle(color: Colors.greenAccent, fontSize: 10),
                    ),
                  ],
                ),
              ),
              GestureDetector(
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const WalletScreen()),
                ),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: cardColor,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: primaryAmber.withOpacity(0.3)),
                  ),
                  child: Row(
                    children: [
                      const FaIcon(
                        FontAwesomeIcons.wallet,
                        color: primaryAmber,
                        size: 14,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        balanceText,
                        style: GoogleFonts.orbitron(
                          color: Colors.white,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBannerSection() {
    return SizedBox(
      height: 150,
      child: PageView(
        controller: _bannerController,
        children: [
          _buildBannerCard(
            "NOVO",
            "O Tesouro Perdido",
            Colors.deepPurple,
            Icons.map,
          ),
          _buildBannerCard(
            "PROMO",
            "Pacote de Dicas",
            Colors.blueAccent,
            Icons.lightbulb,
          ),
          _buildBannerCard(
            "TOP",
            "Ranking Global",
            Colors.orangeAccent,
            Icons.emoji_events,
          ),
        ],
      ),
    );
  }

  Widget _buildBannerCard(
    String tag,
    String title,
    Color color,
    IconData icon,
  ) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color.withOpacity(0.8), Colors.black87],
          begin: Alignment.topLeft,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Stack(
        children: [
          Positioned(
            right: -10,
            bottom: -10,
            child: Icon(icon, size: 100, color: Colors.white10),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black26,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    tag,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  title,
                  style: GoogleFonts.orbitron(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilters() {
    final filters = ['Todos', 'Ao Vivo', 'Em Breve', 'Finalizados'];
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: Row(
        children: filters
            .map(
              (f) => Padding(
                padding: const EdgeInsets.only(right: 8),
                child: ChoiceChip(
                  label: Text(f),
                  selected: _selectedFilter == f,
                  onSelected: (b) => setState(() => _selectedFilter = f),
                  backgroundColor: cardColor,
                  selectedColor: primaryAmber,
                  labelStyle: TextStyle(
                    color: _selectedFilter == f ? Colors.black : Colors.white70,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                    side: BorderSide.none,
                  ),
                  showCheckmark: false,
                ),
              ),
            )
            .toList(),
      ),
    );
  }

  Widget _buildEventsGrid() {
    if (_filteredEvents.isEmpty) {
      return const SliverToBoxAdapter(
        child: Padding(
          padding: EdgeInsets.all(40),
          child: Center(
            child: Text(
              "Nenhum evento encontrado.",
              style: TextStyle(color: Colors.white54),
            ),
          ),
        ),
      );
    }
    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, index) => Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: EventCard(
              event: _filteredEvents[index],
              playerData: _playerData,
              onReturn: _initData,
            ),
          ),
          childCount: _filteredEvents.length,
        ),
      ),
    );
  }

  List<EventModel> get _filteredEvents {
    if (_selectedFilter == 'Todos') return _events;
    if (_selectedFilter == 'Ao Vivo')
      return _events.where((e) => e.status == 'open').toList();
    if (_selectedFilter == 'Em Breve')
      return _events
          .where((e) => e.status == 'dev' || e.status == 'upcoming')
          .toList();
    if (_selectedFilter == 'Finalizados')
      return _events.where((e) => e.status == 'closed').toList();
    return _events;
  }

  Widget _buildErrorState() {
    return Scaffold(
      backgroundColor: darkBackground,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.cloud_off, size: 50, color: Colors.redAccent),
            const SizedBox(height: 16),
            Text(_errorMessage!, style: const TextStyle(color: Colors.white)),
            TextButton(
              onPressed: _initData,
              child: const Text("Tentar Novamente"),
            ),
          ],
        ),
      ),
    );
  }
}

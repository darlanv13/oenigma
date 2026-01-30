import 'dart:async';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
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

class _HomeScreenState extends State<HomeScreen> {
  final FirebaseService _firebaseService = FirebaseService();

  // Estado
  bool _isLoading = true;
  String? _errorMessage; // Para mostrar na tela se der erro

  List<EventModel> _events = [];
  Map<String, dynamic> _playerData = {};
  UserWalletModel? _walletData;
  String _selectedFilter = 'Todos';

  // Banner Control
  final PageController _bannerController = PageController();
  int _currentBannerPage = 0;
  Timer? _bannerTimer;

  @override
  void initState() {
    super.initState();
    _initData();
    // Timer só inicia se não houver erro de build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _startBannerTimer();
    });
  }

  @override
  void dispose() {
    _bannerTimer?.cancel();
    if (_bannerController.hasClients) _bannerController.dispose();
    super.dispose();
  }

  void _startBannerTimer() {
    _bannerTimer = Timer.periodic(const Duration(seconds: 5), (Timer timer) {
      if (mounted && _bannerController.hasClients) {
        setState(() {
          _currentBannerPage = (_currentBannerPage + 1) % 3;
        });
        _bannerController.animateToPage(
          _currentBannerPage,
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeIn,
        );
      }
    });
  }

  Future<void> _initData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Carregamento Seguro
      final results = await Future.wait([
        _firebaseService.getHomeScreenData(),
        _firebaseService.getUserWalletData().catchError(
          (e) => UserWalletModel(
            balance: 0,
            history: [],
            uid: '',
            name: '',
            email: '',
          ),
        ), // Fallback
      ]);

      final homeData = results[0] as Map<String, dynamic>;
      final walletData = results[1] as UserWalletModel;

      final List<dynamic> eventsData = homeData['events'] ?? [];
      final List<EventModel> loadedEvents = eventsData
          .map((e) => EventModel.fromMap(Map<String, dynamic>.from(e)))
          .toList();

      if (mounted) {
        setState(() {
          _events = loadedEvents;
          _playerData = Map<String, dynamic>.from(homeData['player'] ?? {});
          _walletData = walletData;
          _isLoading = false;
        });
      }
    } catch (e) {
      print("CRITICAL ERROR HOME: $e");
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = e.toString();
        });
      }
    }
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

  @override
  Widget build(BuildContext context) {
    // 1. Tratamento de Erro Visual
    if (_errorMessage != null) {
      return Scaffold(
        backgroundColor: darkBackground,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, color: Colors.red, size: 50),
              const SizedBox(height: 16),
              const Text(
                "Erro ao carregar dados",
                style: TextStyle(color: Colors.white),
              ),
              Text(
                _errorMessage!,
                style: const TextStyle(color: Colors.grey, fontSize: 12),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _initData,
                child: const Text("Tentar Novamente"),
              ),
            ],
          ),
        ),
      );
    }

    // 2. Loading Simples (Sem Shimmer para evitar bugs de layout)
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: darkBackground,
        body: Center(child: CircularProgressIndicator(color: primaryAmber)),
      );
    }

    // 3. Tela Principal
    return Scaffold(
      backgroundColor: darkBackground,
      body: RefreshIndicator(
        color: primaryAmber,
        backgroundColor: cardColor,
        onRefresh: _initData,
        child: CustomScrollView(
          slivers: [
            _buildSliverAppBar(),

            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.only(top: 16, bottom: 24),
                child: _buildBannerSection(),
              ),
            ),

            SliverToBoxAdapter(child: _buildFilterChips()),

            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 16,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "MISSÕES DISPONÍVEIS",
                      style: GoogleFonts.orbitron(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.5,
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

            _filteredEvents.isEmpty
                ? SliverToBoxAdapter(child: _buildEmptyState())
                : SliverList(
                    delegate: SliverChildBuilderDelegate((context, index) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        child: EventCard(
                          event: _filteredEvents[index],
                          playerData: _playerData,
                          onReturn: _initData,
                        ),
                      );
                    }, childCount: _filteredEvents.length),
                  ),

            const SliverPadding(padding: EdgeInsets.only(bottom: 80)),
          ],
        ),
      ),
    );
  }

  Widget _buildSliverAppBar() {
    final photoUrl = _playerData['photoURL'];
    final name = _playerData['name']?.toString().split(' ').first ?? 'Agente';

    // Proteção contra Null no saldo
    double balanceVal = 0.0;
    if (_walletData != null) {
      balanceVal = _walletData!.balance;
    } else if (_playerData['balance'] != null) {
      balanceVal = double.tryParse(_playerData['balance'].toString()) ?? 0.0;
    }
    final balance = balanceVal.toStringAsFixed(2);

    return SliverAppBar(
      backgroundColor: darkBackground,
      floating: true,
      pinned: true,
      elevation: 0,
      automaticallyImplyLeading: false,
      expandedHeight: 80, // Aumentei um pouco para evitar overflow
      flexibleSpace: SafeArea(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              GestureDetector(
                onTap: () {
                  // Navegação Segura
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ProfileScreen(
                        playerData: _playerData,
                        walletData:
                            _walletData ??
                            UserWalletModel(
                              balance: 0,
                              history: [],
                              uid: '',
                              name: '',
                              email: '',
                            ),
                      ),
                    ),
                  );
                },
                child: Container(
                  padding: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: primaryAmber, width: 2),
                  ),
                  child: CircleAvatar(
                    radius: 20,
                    backgroundColor: cardColor,
                    // Validação de URL segura
                    backgroundImage:
                        (photoUrl != null &&
                            photoUrl.toString().startsWith('http'))
                        ? CachedNetworkImageProvider(photoUrl)
                        : null,
                    child:
                        (photoUrl == null ||
                            !photoUrl.toString().startsWith('http'))
                        ? const Icon(Icons.person, color: secondaryTextColor)
                        : null,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      "Olá, $name",
                      style: GoogleFonts.inter(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      "Pronto para a caçada?",
                      style: GoogleFonts.inter(
                        color: secondaryTextColor,
                        fontSize: 12,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              GestureDetector(
                onTap: () {
                  if (_walletData != null) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => WalletScreen(wallet: _walletData!),
                      ),
                    );
                  }
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: cardColor,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: primaryAmber.withOpacity(0.3)),
                  ),
                  child: Row(
                    mainAxisSize:
                        MainAxisSize.min, // Importante para não quebrar layout
                    children: [
                      const Icon(
                        Icons.account_balance_wallet_outlined,
                        color: primaryAmber,
                        size: 16,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        "R\$ $balance",
                        style: GoogleFonts.orbitron(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
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
      height: 160,
      child: PageView(
        controller: _bannerController,
        onPageChanged: (index) => setState(() => _currentBannerPage = index),
        children: [
          _buildBannerCard(
            "NOVA TEMPORADA",
            "O Tesouro Perdido",
            "Jogue Agora",
            Colors.purpleAccent,
            Icons.explore,
          ),
          _buildBannerCard(
            "CÓDIGO SECRETO",
            "Use o cupom 'ENIGMA20'",
            "Resgatar",
            Colors.blueAccent,
            Icons.qr_code,
          ),
          _buildBannerCard(
            "RANKING SEMANAL",
            "Veja os top caçadores",
            "Ver Líderes",
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
    String buttonText,
    Color color,
    IconData icon,
  ) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
          colors: [color.withOpacity(0.8), Colors.black],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            right: -20,
            bottom: -20,
            child: Icon(icon, size: 120, color: Colors.white.withOpacity(0.1)),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.3),
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
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    buttonText,
                    style: TextStyle(
                      color: color,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChips() {
    final filters = ['Todos', 'Ao Vivo', 'Em Breve', 'Finalizados'];
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: filters.map((filter) {
          final isSelected = _selectedFilter == filter;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilterChip(
              selected: isSelected,
              label: Text(filter),
              onSelected: (_) => setState(() => _selectedFilter = filter),
              backgroundColor: cardColor,
              selectedColor: primaryAmber,
              checkmarkColor: darkBackground,
              labelStyle: TextStyle(
                color: isSelected ? darkBackground : secondaryTextColor,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: BorderSide(
                  color: isSelected
                      ? primaryAmber
                      : Colors.white.withOpacity(0.1),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40.0),
        child: Column(
          children: [
            Icon(
              Icons.search_off_rounded,
              size: 60,
              color: secondaryTextColor.withOpacity(0.5),
            ),
            const SizedBox(height: 16),
            const Text(
              "Nenhum evento encontrado.",
              style: TextStyle(color: secondaryTextColor),
            ),
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:oenigma/core/models/user_wallet_model.dart';
import 'package:oenigma/core/models/event_model.dart';
import 'package:oenigma/core/utils/app_colors.dart';
import 'package:oenigma/features/event/widgets/event_card.dart';
import 'package:oenigma/features/home/providers/home_events_provider.dart';
import '../widgets/home_profile_card.dart';
import '../widgets/events_section_header.dart';
import 'package:oenigma/features/home/widgets/home_banner_carousel.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:carousel_slider/carousel_slider.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});
  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeIn,
    );
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  Future<void> _reloadData() async {
    return await ref.refresh(homeEventsProvider.future);
  }

  @override
  Widget build(BuildContext context) {
    final homeDataAsync = ref.watch(homeEventsProvider);

    return Scaffold(
      backgroundColor: darkBackground,
      body: SafeArea(
        child: homeDataAsync.when(
          loading: () => const Center(
            child: CircularProgressIndicator(color: primaryAmber),
          ),
          error: (error, stack) => Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const FaIcon(
                  FontAwesomeIcons.circleExclamation,
                  size: 48,
                  color: Colors.redAccent,
                ),
                const SizedBox(height: 16),
                const Text(
                  'Erro ao carregar dados.',
                  style: TextStyle(color: Colors.white, fontSize: 16),
                ),
                const SizedBox(height: 8),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32.0),
                  child: Text(
                    '$error',
                    style: const TextStyle(color: Colors.grey),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: _reloadData,
                  icon: const FaIcon(FontAwesomeIcons.rotateRight),
                  label: const Text("Tentar Novamente"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryAmber,
                    foregroundColor: Colors.black,
                  ),
                ),
              ],
            ),
          ),
          data: (data) {
            final List<EventModel> events = (data['events'] as List)
                .map((e) => EventModel.fromMap(Map<String, dynamic>.from(e)))
                .toList();
            final UserWalletModel walletData = UserWalletModel.fromMap(
              Map<String, dynamic>.from(data['walletData']),
            );
            final Map<String, dynamic> playerData = data['playerData'] != null
                ? Map<String, dynamic>.from(data['playerData'])
                : {};
            final List<dynamic> allPlayers = data['allPlayers'] ?? [];

            _fadeController.forward();

            return RefreshIndicator(
              onRefresh: _reloadData,
              color: primaryAmber,
              backgroundColor: cardColor,
              child: CustomScrollView(
                physics: const BouncingScrollPhysics(),
                slivers: [
                  SliverToBoxAdapter(
                    child: FadeTransition(
                      opacity: _fadeAnimation,
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(
                          16.0,
                          16.0,
                          16.0,
                          8.0,
                        ),
                        child: HomeProfileCard(
                          playerData: playerData,
                          wallet: walletData,
                          events: events,
                          allPlayers: allPlayers,
                        ),
                      ),
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: FadeTransition(
                      opacity: _fadeAnimation,
                      child: const HomeBannerCarousel(),
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: FadeTransition(
                      opacity: _fadeAnimation,
                      child: const Padding(
                        padding: EdgeInsets.fromLTRB(20.0, 16.0, 20.0, 8.0),
                        child: EventsSectionHeader(),
                      ),
                    ),
                  ),
                  _buildEventsCarousel(events, playerData, context),
                  const SliverToBoxAdapter(child: SizedBox(height: 40)),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildEventsCarousel(
    List<EventModel> events,
    Map<String, dynamic> playerData,
    BuildContext context,
  ) {
    if (events.isEmpty) {
      return const SliverToBoxAdapter(
        child: Center(
          child: Padding(
            padding: EdgeInsets.all(40.0),
            child: Column(
              children: [
                FaIcon(
                  FontAwesomeIcons.calendarXmark,
                  size: 40,
                  color: secondaryTextColor,
                ),
                SizedBox(height: 16),
                Text(
                  'Nenhum evento ativo no momento.',
                  style: TextStyle(color: secondaryTextColor),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return SliverToBoxAdapter(
      child: CarouselSlider(
        options: CarouselOptions(
          height: MediaQuery.of(context).size.height * 0.55,
          viewportFraction: 0.85,
          enlargeCenterPage: true,
          enableInfiniteScroll: false,
        ),
        items: events.map((e) {
          return Builder(
            builder: (BuildContext context) {
              return FadeTransition(
                opacity: _fadeAnimation,
                child: EventCard(
                  event: e,
                  playerData: playerData,
                  onReturn: _reloadData,
                ),
              );
            },
          );
        }).toList(),
      ),
    );
  }
}

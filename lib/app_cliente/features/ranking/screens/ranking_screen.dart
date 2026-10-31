import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:oenigma/app_cliente/features/auth/providers/auth_provider.dart';
import 'package:oenigma/app_cliente/features/home/providers/home_events_provider.dart';
import 'package:oenigma/app_cliente/features/ranking/widgets/event_ranking_stats_card.dart';
import 'package:oenigma/app_cliente/features/ranking/widgets/player_detail_modal.dart';
import 'package:oenigma/app_cliente/features/ranking/widgets/ranking_event_selector.dart';
import 'package:oenigma/app_cliente/features/ranking/widgets/ranking_list.dart';
import 'package:oenigma/app_cliente/features/ranking/widgets/ranking_podium.dart';
import 'package:oenigma/app_cliente/features/ranking/widgets/user_rank_highlight_card.dart';
import 'package:oenigma/core/models/event_model.dart';
import 'package:oenigma/core/models/ranking_player_model.dart';
import 'package:oenigma/core/services/sound_service.dart';
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
  String _selectedTimeFilter = 'all_time'; // 'all_time', 'monthly', 'weekly'
  String _selectedScopeFilter = 'all'; // 'all', 'top10', 'podium'
  final TextEditingController _searchController = TextEditingController();
  final GlobalKey _userItemKey = GlobalKey();
  late ConfettiController _confettiController;
  List<RankingPlayerModel> _currentRanking = [];

  @override
  void initState() {
    super.initState();
    _confettiController = ConfettiController(duration: const Duration(seconds: 3));
    SoundService.playBadge();
    if (widget.availableEvents.isNotEmpty) {
      _selectedEventId = widget.availableEvents.first.id;
      _calculateRankingForSelectedEvent();
    }
  }

  @override
  void didUpdateWidget(covariant RankingScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.allPlayers != widget.allPlayers ||
        oldWidget.availableEvents != widget.availableEvents) {
      _calculateRankingForSelectedEvent();
    }
  }

  @override
  void dispose() {
    _confettiController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  EventModel? get _currentEvent {
    if (widget.availableEvents.isEmpty) return null;
    return widget.availableEvents.firstWhere(
      (e) => e.id == _selectedEventId,
      orElse: () => widget.availableEvents.first,
    );
  }

  int get _currentEventTotalPhases {
    final event = _currentEvent;
    if (event != null && event.phases.isNotEmpty) {
      return event.phases.length;
    }
    return 10;
  }

  void _calculateRankingForSelectedEvent() {
    if (_selectedEventId == null) return;

    List<RankingPlayerModel> ranking = [];
    final now = DateTime.now();
    final totalPhases = _currentEventTotalPhases;

    for (var playerMap in widget.allPlayers) {
      if (playerMap is Map<String, dynamic>) {
        final events = playerMap['events'];
        int phasesCompleted = 0;
        int latestCompletionTime = 0;

        if (events is Map && events.containsKey(_selectedEventId)) {
          final eventProgress = events[_selectedEventId] as Map<String, dynamic>;

          phasesCompleted = (eventProgress['currentPhase'] as num?)?.toInt() ?? 0;
          latestCompletionTime = (eventProgress['lastUpdateTime'] as num?)?.toInt() ?? 0;

          // Time Filters
          if (latestCompletionTime > 0) {
            final completionDate = DateTime.fromMillisecondsSinceEpoch(latestCompletionTime);

            if (_selectedTimeFilter == 'monthly') {
              if (completionDate.year != now.year || completionDate.month != now.month) {
                phasesCompleted = 0;
              }
            } else if (_selectedTimeFilter == 'weekly') {
              if (now.difference(completionDate).inDays > 7) {
                phasesCompleted = 0;
              }
            }
          } else if (_selectedTimeFilter != 'all_time') {
            phasesCompleted = 0;
          }
        }

        if (phasesCompleted > 0) {
          ranking.add(
            RankingPlayerModel(
              objectId: playerMap['objectId'] ?? '',
              name: playerMap['name'] ?? 'Jogador',
              photoURL: playerMap['photoURL'],
              phasesCompleted: phasesCompleted,
              totalPhases: totalPhases,
              position: 0,
              latestCompletionTime: latestCompletionTime,
            ),
          );
        }
      }
    }

    // Sort with fair tie-breaker:
    // 1. Most phases completed
    // 2. Completed earlier (lower timestamp)
    ranking.sort((a, b) {
      final phaseCompare = b.phasesCompleted.compareTo(a.phasesCompleted);
      if (phaseCompare != 0) return phaseCompare;

      if (a.latestCompletionTime > 0 && b.latestCompletionTime > 0) {
        return a.latestCompletionTime.compareTo(b.latestCompletionTime);
      } else if (a.latestCompletionTime > 0) {
        return -1;
      } else if (b.latestCompletionTime > 0) {
        return 1;
      }
      return 0;
    });

    int currentPosition = 1;
    for (int i = 0; i < ranking.length; i++) {
      if (i > 0 &&
          ranking[i].phasesCompleted == ranking[i - 1].phasesCompleted &&
          ranking[i].latestCompletionTime == ranking[i - 1].latestCompletionTime) {
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

  void _scrollToUser() {
    if (_userItemKey.currentContext != null) {
      Scrollable.ensureVisible(
        _userItemKey.currentContext!,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Você está no topo ou sua posição já está visível!',
            style: GoogleFonts.inter(color: Colors.white),
          ),
          backgroundColor: AppColors.verdeVale,
          duration: const Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _openPlayerDetails(RankingPlayerModel player) {
    final eventName = _currentEvent?.name ?? 'Evento';
    final leader = _currentRanking.isNotEmpty ? _currentRanking.first : null;
    PlayerDetailModal.show(
      context,
      player: player,
      leaderPlayer: leader,
      eventName: eventName,
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.availableEvents.isEmpty) {
      return Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: Text(
            'Ranking',
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.w700,
              color: Colors.white,
              fontSize: 20,
            ),
          ),
          backgroundColor: Colors.transparent,
          elevation: 0,
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.verdeVale.withValues(alpha: 0.12),
                ),
                child: const FaIcon(
                  FontAwesomeIcons.trophy,
                  size: 40,
                  color: AppColors.verdeVale,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Nenhum evento disponível no momento.',
                style: GoogleFonts.inter(color: AppColors.cinzaMedio),
              ),
            ],
          ),
        ),
      );
    }

    final currentEvent = _currentEvent!;
    final currentUserId = ref.read(authRepositoryProvider).currentUser?.objectId;
    final isGuest = currentUserId == null || currentUserId == 'visitante';

    RankingPlayerModel? currentUserPlayer;
    if (!isGuest) {
      try {
        currentUserPlayer = _currentRanking.firstWhere(
          (p) => p.objectId == currentUserId,
        );
      } catch (_) {
        currentUserPlayer = null;
      }
    }

    // Filter by Search Query
    final searchQuery = _searchController.text.trim().toLowerCase();
    List<RankingPlayerModel> filteredRanking = _currentRanking;
    if (searchQuery.isNotEmpty) {
      filteredRanking = filteredRanking
          .where((p) => p.name.toLowerCase().contains(searchQuery))
          .toList();
    }

    // Filter by Scope
    if (_selectedScopeFilter == 'top10') {
      filteredRanking = filteredRanking.where((p) => p.position <= 10).toList();
    } else if (_selectedScopeFilter == 'podium') {
      filteredRanking = filteredRanking.where((p) => p.position <= 3).toList();
    }

    // Divide into Podium (top 3) and Others (rest)
    List<RankingPlayerModel> top3 = [];
    List<RankingPlayerModel> others = [];

    if (searchQuery.isEmpty && _selectedScopeFilter != 'podium') {
      if (_currentRanking.isNotEmpty) {
        top3 = _currentRanking.take(3).toList();
        if (_currentRanking.length > 3) {
          others = filteredRanking.where((p) => p.position > 3).toList();
        }
      }
    } else if (_selectedScopeFilter == 'podium') {
      top3 = filteredRanking.take(3).toList();
    } else {
      // Search is active
      others = filteredRanking;
    }

    final podiumThresholdPhases = _currentRanking.length >= 3
        ? _currentRanking[2].phasesCompleted
        : (_currentRanking.isNotEmpty ? _currentRanking.first.phasesCompleted : null);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          // Refresh indicator for pulling to reload ranking data
          RefreshIndicator(
            color: AppColors.verdeVale,
            backgroundColor: AppColors.darkCardColor,
            onRefresh: () async {
              SoundService.playScan();
              ref.invalidate(homeEventsProvider);
              await ref.read(homeEventsProvider.future);
              _calculateRankingForSelectedEvent();
            },
            child: CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(
                parent: BouncingScrollPhysics(),
              ),
              slivers: [
                // Modern App Bar
                SliverAppBar(
                  automaticallyImplyLeading: false,
                  backgroundColor: AppColors.darkBackground.withValues(alpha: 0.85),
                  elevation: 0,
                  pinned: true,
                  title: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(7),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.amareloVale.withValues(alpha: 0.15),
                        ),
                        child: const FaIcon(
                          FontAwesomeIcons.trophy,
                          size: 15,
                          color: AppColors.amareloVale,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        'Ranking dos Exploradores',
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                          fontSize: 18,
                          letterSpacing: 0.3,
                        ),
                      ),
                    ],
                  ),
                  actions: [
                    IconButton(
                      tooltip: 'Comemorar Pódio',
                      icon: const FaIcon(
                        FontAwesomeIcons.champagneGlasses,
                        color: AppColors.amareloVale,
                        size: 16,
                      ),
                      onPressed: () {
                        SoundService.playVictory();
                        _confettiController.play();
                      },
                    ),
                    const SizedBox(width: 8),
                  ],
                ),

                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 8.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Event Selector
                        Text(
                          'SELECIONE O EVENTO',
                          style: GoogleFonts.inter(
                            color: AppColors.cinzaMedio,
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1.0,
                          ),
                        ),
                        const SizedBox(height: 8),
                        RankingEventSelector(
                          selectedEventId: _selectedEventId,
                          availableEvents: widget.availableEvents,
                          onChanged: (String? newValue) {
                            if (newValue != null && newValue != _selectedEventId) {
                              SoundService.playClick();
                              setState(() {
                                _selectedEventId = newValue;
                                _calculateRankingForSelectedEvent();
                              });
                            }
                          },
                        ),
                        const SizedBox(height: 16),

                        // Event Stats Banner
                        EventRankingStatsCard(
                          event: currentEvent,
                          totalCompetitors: _currentRanking.length,
                          totalPhases: _currentEventTotalPhases,
                        ),
                        const SizedBox(height: 16),

                        // User Highlight Card (Meu Desempenho)
                        UserRankHighlightCard(
                          userPlayer: currentUserPlayer,
                          isGuest: isGuest,
                          podiumThresholdPhases: podiumThresholdPhases,
                          onScrollToUser: _scrollToUser,
                          onViewDetails: currentUserPlayer != null
                              ? () => _openPlayerDetails(currentUserPlayer!)
                              : null,
                        ),
                        const SizedBox(height: 20),

                        // Time Filters (Geral / Mensal / Semanal)
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: AppColors.darkCardColor,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.25),
                                blurRadius: 10,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Row(
                            children: [
                              _buildTimeTab('all_time', 'Geral', FontAwesomeIcons.globe),
                              _buildTimeTab('monthly', 'Mensal', FontAwesomeIcons.calendarCheck),
                              _buildTimeTab('weekly', 'Semanal', FontAwesomeIcons.bolt),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Search Bar & Scope Filters
                        Row(
                          children: [
                            Expanded(
                              child: Container(
                                height: 44,
                                decoration: BoxDecoration(
                                  color: AppColors.darkCardColor,
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(
                                    color: Colors.white.withValues(alpha: 0.08),
                                  ),
                                ),
                                child: TextField(
                                  controller: _searchController,
                                  onChanged: (value) => setState(() {}),
                                  style: GoogleFonts.inter(
                                    color: Colors.white,
                                    fontSize: 13,
                                  ),
                                  decoration: InputDecoration(
                                    hintText: 'Buscar explorador...',
                                    hintStyle: GoogleFonts.inter(
                                      color: AppColors.cinzaMedio,
                                      fontSize: 13,
                                    ),
                                    prefixIcon: const Padding(
                                      padding: EdgeInsets.symmetric(horizontal: 12),
                                      child: FaIcon(
                                        FontAwesomeIcons.magnifyingGlass,
                                        size: 13,
                                        color: AppColors.cinzaMedio,
                                      ),
                                    ),
                                    prefixIconConstraints: const BoxConstraints(
                                      minWidth: 36,
                                      minHeight: 36,
                                    ),
                                    suffixIcon: _searchController.text.isNotEmpty
                                        ? IconButton(
                                            icon: const FaIcon(
                                              FontAwesomeIcons.xmark,
                                              size: 12,
                                              color: AppColors.cinzaMedio,
                                            ),
                                            onPressed: () {
                                              _searchController.clear();
                                              setState(() {});
                                            },
                                          )
                                        : null,
                                    border: InputBorder.none,
                                    contentPadding: const EdgeInsets.symmetric(vertical: 12),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            // Scope filter popup/chip
                            Container(
                              height: 44,
                              padding: const EdgeInsets.symmetric(horizontal: 10),
                              decoration: BoxDecoration(
                                color: AppColors.darkCardColor,
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                  color: _selectedScopeFilter != 'all'
                                      ? AppColors.verdeVale
                                      : Colors.white.withValues(alpha: 0.08),
                                ),
                              ),
                              child: DropdownButtonHideUnderline(
                                child: DropdownButton<String>(
                                  value: _selectedScopeFilter,
                                  dropdownColor: AppColors.darkBackground,
                                  borderRadius: BorderRadius.circular(16),
                                  icon: const FaIcon(
                                    FontAwesomeIcons.filter,
                                    size: 11,
                                    color: AppColors.verdeVale,
                                  ),
                                  onChanged: (value) {
                                    if (value != null) {
                                      SoundService.playClick();
                                      setState(() {
                                        _selectedScopeFilter = value;
                                      });
                                    }
                                  },
                                  items: [
                                    DropdownMenuItem(
                                      value: 'all',
                                      child: Text(
                                        'Todos',
                                        style: GoogleFonts.inter(
                                          color: Colors.white,
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                    DropdownMenuItem(
                                      value: 'top10',
                                      child: Text(
                                        'Top 10',
                                        style: GoogleFonts.inter(
                                          color: Colors.white,
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                    DropdownMenuItem(
                                      value: 'podium',
                                      child: Text(
                                        'Pódio',
                                        style: GoogleFonts.inter(
                                          color: Colors.white,
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),

                        // Empty State Check
                        if (_currentRanking.isEmpty)
                          Center(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 40.0),
                              child: Column(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(22),
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: AppColors.verdeVale.withValues(alpha: 0.12),
                                      border: Border.all(
                                        color: AppColors.verdeVale.withValues(alpha: 0.25),
                                      ),
                                    ),
                                    child: const FaIcon(
                                      FontAwesomeIcons.trophy,
                                      size: 44,
                                      color: AppColors.verdeVale,
                                    ),
                                  ),
                                  const SizedBox(height: 18),
                                  Text(
                                    'Nenhum jogador pontuou neste período.',
                                    style: GoogleFonts.poppins(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 15,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    'Seja o primeiro a resolver um enigma e liderar o ranking!',
                                    style: GoogleFonts.inter(
                                      color: AppColors.cinzaMedio,
                                      fontSize: 12,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ],
                              ),
                            ),
                          )
                        else if (filteredRanking.isEmpty)
                          Center(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 40.0),
                              child: Column(
                                children: [
                                  const FaIcon(
                                    FontAwesomeIcons.userXmark,
                                    size: 38,
                                    color: AppColors.cinzaMedio,
                                  ),
                                  const SizedBox(height: 14),
                                  Text(
                                    'Nenhum explorador encontrado.',
                                    style: GoogleFonts.poppins(
                                      color: Colors.white,
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Tente buscar por outro nome ou limpe os filtros.',
                                    style: GoogleFonts.inter(
                                      color: AppColors.cinzaMedio,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          )
                        else ...[
                          // Podium Section (shown when no text search active or when podium is populated)
                          if (top3.isNotEmpty) ...[
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'PÓDIO DOS LÍDERES',
                                  style: GoogleFonts.inter(
                                    color: AppColors.amareloVale,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 1.0,
                                  ),
                                ),
                                Text(
                                  'Toque para celebrar 🎉',
                                  style: GoogleFonts.inter(
                                    color: AppColors.cinzaMedio,
                                    fontSize: 11,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 14),
                            RankingPodium(
                              top3: top3,
                              onPlayerTap: _openPlayerDetails,
                              onCelebrateFirstPlace: () {
                                _confettiController.play();
                              },
                            ),
                            const SizedBox(height: 32),
                          ],

                          // Others / Search Results Section
                          if (others.isNotEmpty) ...[
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  searchQuery.isNotEmpty
                                      ? 'RESULTADOS DA BUSCA (${others.length})'
                                      : 'DEMAIS COLOCAÇÕES',
                                  style: GoogleFonts.inter(
                                    color: AppColors.cinzaMedio,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 1.0,
                                  ),
                                ),
                                Text(
                                  '${_currentRanking.length} total',
                                  style: GoogleFonts.inter(
                                    color: AppColors.verdeVale,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 14),
                            RankingList(
                              players: others,
                              onPlayerTap: _openPlayerDetails,
                              userItemKey: _userItemKey,
                            ),
                          ],
                        ],
                        const SizedBox(height: 48),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Confetti Animation Overlay
          Align(
            alignment: Alignment.topCenter,
            child: ConfettiWidget(
              confettiController: _confettiController,
              blastDirectionality: BlastDirectionality.explosive,
              shouldLoop: false,
              numberOfParticles: 35,
              gravity: 0.15,
              emissionFrequency: 0.05,
              colors: const [
                AppColors.amareloVale,
                AppColors.verdeVale,
                Color(0xFFFFD700),
                Color(0xFF00E5FF),
                Colors.white,
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimeTab(String key, String title, FaIconData icon) {
    final isSelected = _selectedTimeFilter == key;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          if (!isSelected) {
            SoundService.playClick();
          }
          setState(() {
            _selectedTimeFilter = key;
            _calculateRankingForSelectedEvent();
          });
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            gradient: isSelected ? AppColors.gradienteVerdeVale : null,
            color: isSelected ? null : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              FaIcon(
                icon,
                size: 11,
                color: isSelected ? Colors.white : AppColors.cinzaMedio,
              ),
              const SizedBox(width: 6),
              Text(
                title,
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  fontWeight: FontWeight.w700,
                  color: isSelected ? Colors.white : AppColors.cinzaMedio,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

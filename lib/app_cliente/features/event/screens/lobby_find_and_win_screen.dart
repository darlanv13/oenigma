import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:parse_server_sdk_flutter/parse_server_sdk_flutter.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:oenigma/core/models/event_model.dart';
import 'package:oenigma/core/models/enigma_model.dart';
import 'package:oenigma/core/utils/app_colors.dart';
import 'package:oenigma/core/widgets/hunter_arsenal_sheet.dart';

import '../widgets/card_enigma.dart';

// ---------------------------------------------------------------------------
// LOBBY FIND & WIN — Redesign imersivo "Mapa do Tesouro"
// ---------------------------------------------------------------------------

class LobbyFindEndWinScreen extends ConsumerStatefulWidget {
  final EventModel event;
  const LobbyFindEndWinScreen({super.key, required this.event});

  @override
  ConsumerState<LobbyFindEndWinScreen> createState() =>
      _LobbyFindEndWinScreenState();
}

class _LobbyFindEndWinScreenState extends ConsumerState<LobbyFindEndWinScreen>
    with TickerProviderStateMixin {
  late final Stream<List<EnigmaModel>> _enigmasStream;
  late final AnimationController _pulseController;
  late final AnimationController _radarController;
  late final AnimationController _shimmerController;

  @override
  void initState() {
    super.initState();

    // Pulse suave nos cards
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    // Radar sweep contínuo
    _radarController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat();

    // Shimmer na barra de progresso
    _shimmerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat();

    _enigmasStream = Stream.periodic(const Duration(seconds: 5)).asyncMap((
      _,
    ) async {
      final response = await ParseCloudFunction('getSafeEventEnigmas').execute(
        parameters: {'eventId': widget.event.id},
      );
      if (response.success && response.result is List) {
        final list = response.result as List;
        return list.map((item) {
          final map = Map<String, dynamic>.from(item as Map);
          return EnigmaModel.fromMap({
            'id': map['id'] ?? map['objectId'],
            'title': map['title'] ?? map['name'] ?? '',
            'instruction': map['instruction'] ?? '',
            'prize': map['prize'] ?? 0,
            'imageUrl': map['imageUrl'],
            'audioUrl': map['audioUrl'],
            'type': map['type'] ?? 'text',
            'characteristics': map['characteristics'] ?? [],
            'status': map['status'],
            'closedAt': map['closedAt'] != null
                ? DateTime.tryParse(map['closedAt'].toString())
                : null,
            'code': '', // SecOps Blindagem: resposta correta mantida oculta no servidor
            'icon': map['icon'] ?? 'skull',
            'difficulty': map['difficulty'] ?? 'MÉDIA',
            'hasCompass': map['hasCompass'] == true,
            'hasMap': map['hasMap'] == true,
            'hasRadar': map['hasRadar'] == true,
            'compassPrice': map['compassPrice'],
            'mapPrice': map['mapPrice'],
            'radarPrice': map['radarPrice'],
            'compassDuration': map['compassDuration'],
            'compassCoords': null, // SecOps Blindagem: coordenadas mantidas ocultas no servidor
          });
        }).toList();
      }
      return [];
    });
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _radarController.dispose();
    _shimmerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: StreamBuilder<List<EnigmaModel>>(
        stream: _enigmasStream,
        builder: (context, snapshot) {
          final enigmas = snapshot.data ?? [];
          final visibleEnigmas = enigmas.where((e) {
            if (e.status != 'closed') return true;
            if (e.closedAt != null &&
                DateTime.now().difference(e.closedAt!).inMinutes < 15) {
              return true;
            }
            return false;
          }).toList();

          final totalEnigmas = enigmas.length;
          final closedCount =
              enigmas.where((e) => e.status == 'closed').length;
          final progress =
              totalEnigmas > 0 ? closedCount / totalEnigmas : 0.0;

          return CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              // ── HERO HEADER ──────────────────────────────────────────
              SliverToBoxAdapter(
                child: SafeArea(
                  bottom: false,
                  child: Column(
                    children: [
                      // Top navigation
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                        child: Row(
                          children: [
                            _BackButton(onTap: () => Navigator.pop(context)),
                            const Spacer(),
                            // Badge de modo
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.amareloVale.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(24),
                                border: Border.all(
                                  color: AppColors.amareloVale.withValues(alpha: 0.3),
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const FaIcon(
                                    FontAwesomeIcons.mapLocationDot,
                                    color: AppColors.amareloVale,
                                    size: 12,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    'ACHE & GANHE',
                                    style: GoogleFonts.poppins(
                                      color: AppColors.amareloVale,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: 1.2,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const Spacer(),
                            GestureDetector(
                              onTap: () {
                                HunterArsenalSheet.show(
                                  context,
                                  eventId: widget.event.id,
                                  onToolsUpdated: () => setState(() {}),
                                );
                              },
                              child: Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  color: const Color(0xFF131D24),
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: AppColors.amareloVale.withValues(alpha: 0.6),
                                    width: 1.2,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: AppColors.amareloVale.withValues(alpha: 0.2),
                                      blurRadius: 8,
                                    ),
                                  ],
                                ),
                                child: const Center(
                                  child: FaIcon(
                                    FontAwesomeIcons.toolbox,
                                    color: AppColors.amareloVale,
                                    size: 14,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 20),

                      // Radar visual + título
                      _RadarHero(
                        radarController: _radarController,
                        closedCount: closedCount,
                        totalCount: totalEnigmas,
                      ),

                      const SizedBox(height: 24),

                      // Barra de progresso estilizada
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 28),
                        child: _ProgressBar(
                          progress: progress,
                          shimmerController: _shimmerController,
                          closedCount: closedCount,
                          totalCount: totalEnigmas,
                        ),
                      ),

                      const SizedBox(height: 20),

                      // Stats row
                      _StatsRow(
                        enigmas: enigmas,
                        visibleEnigmas: visibleEnigmas,
                      ),

                      const SizedBox(height: 8),

                      // Divider elegante
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 32),
                        child: Row(
                          children: [
                            Expanded(
                              child: Container(
                                height: 1,
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      Colors.transparent,
                                      AppColors.verdeVale.withValues(alpha: 0.3),
                                      Colors.transparent,
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 12),
                              child: FaIcon(
                                FontAwesomeIcons.diamond,
                                color: AppColors.verdeVale.withValues(alpha: 0.4),
                                size: 8,
                              ),
                            ),
                            Expanded(
                              child: Container(
                                height: 1,
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      Colors.transparent,
                                      AppColors.verdeVale.withValues(alpha: 0.3),
                                      Colors.transparent,
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 16),

                      // Section title
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Row(
                          children: [
                            Container(
                              width: 3,
                              height: 18,
                              decoration: BoxDecoration(
                                gradient: AppColors.gradienteVerdeVale,
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Text(
                              'ENIGMAS DISPONÍVEIS',
                              style: GoogleFonts.poppins(
                                color: Colors.white.withValues(alpha: 0.9),
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 1.5,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Container(
                                height: 1,
                                color: Colors.white.withValues(alpha: 0.06),
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 4),
                    ],
                  ),
                ),
              ),

              // ── LOADING ──────────────────────────────────────────────
              if (snapshot.connectionState == ConnectionState.waiting &&
                  !snapshot.hasData)
                SliverFillRemaining(
                  child: Center(
                    child: AnimatedBuilder(
                      animation: _radarController,
                      builder: (context, child) {
                        return Opacity(
                          opacity:
                              0.4 + 0.6 * (0.5 + 0.5 * sin(_radarController.value * 2 * pi)),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const FaIcon(
                                FontAwesomeIcons.satelliteDish,
                                color: AppColors.verdeVale,
                                size: 40,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'Rastreando enigmas...',
                                style: GoogleFonts.poppins(
                                  color: AppColors.cinzaMedio,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                )

              // ── ESTADO VAZIO (Encerrado) ─────────────────────────────
              else if (visibleEnigmas.isEmpty)
                SliverFillRemaining(
                  child: Padding(
                    padding: const EdgeInsets.all(32.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Troféu animado
                        AnimatedBuilder(
                          animation: _pulseController,
                          builder: (context, child) {
                            final scale =
                                1.0 + 0.05 * _pulseController.value;
                            return Transform.scale(
                              scale: scale,
                              child: Container(
                                width: 100,
                                height: 100,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  gradient: RadialGradient(
                                    colors: [
                                      AppColors.amareloVale.withValues(alpha: 0.2),
                                      AppColors.amareloVale.withValues(alpha: 0.05),
                                      Colors.transparent,
                                    ],
                                    stops: const [0.0, 0.6, 1.0],
                                  ),
                                ),
                                child: Center(
                                  child: Container(
                                    width: 64,
                                    height: 64,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: AppColors.amareloVale.withValues(alpha: 0.15),
                                      border: Border.all(
                                        color: AppColors.amareloVale.withValues(alpha: 0.4),
                                        width: 2,
                                      ),
                                    ),
                                    child: const Center(
                                      child: FaIcon(
                                        FontAwesomeIcons.trophy,
                                        size: 28,
                                        color: AppColors.amareloVale,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                        const SizedBox(height: 28),
                        ShaderMask(
                          shaderCallback: (rect) =>
                              AppColors.gradienteAmareloVale
                                  .createShader(rect),
                          child: Text(
                            'CAÇADA ENCERRADA!',
                            style: GoogleFonts.poppins(
                              fontSize: 22,
                              fontWeight: FontWeight.w900,
                              color: Colors.white,
                              letterSpacing: 2,
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Todos os tesouros e enigmas deste evento\njá foram encontrados.',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.inter(
                            color: AppColors.cinzaMedio,
                            fontSize: 15,
                            height: 1.6,
                          ),
                        ),
                        const SizedBox(height: 24),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 20, vertical: 10),
                          decoration: BoxDecoration(
                            color: AppColors.verdeVale.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(30),
                            border: Border.all(
                              color: AppColors.verdeVale.withValues(alpha: 0.25),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const FaIcon(
                                FontAwesomeIcons.flagCheckered,
                                size: 14,
                                color: AppColors.verdeVale,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                '$closedCount de $totalEnigmas concluídos',
                                style: GoogleFonts.poppins(
                                  color: AppColors.verdeVale,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                )

              // ── LISTA DE ENIGMAS ─────────────────────────────────────
              else
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 40),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate((context, index) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 14.0),
                        child: CardEnigma(
                          enigma: visibleEnigmas[index],
                          event: widget.event,
                          animation: _pulseController,
                        ),
                      );
                    }, childCount: visibleEnigmas.length),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

// ===========================================================================
// COMPONENTES PRIVADOS
// ===========================================================================

/// Botão de voltar estilizado com glow suave
class _BackButton extends StatelessWidget {
  final VoidCallback onTap;
  const _BackButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white.withValues(alpha: 0.05),
          border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
          boxShadow: [
            BoxShadow(
              color: AppColors.verdeVale.withValues(alpha: 0.08),
              blurRadius: 12,
            ),
          ],
        ),
        child: const Center(
          child: FaIcon(
            FontAwesomeIcons.chevronLeft,
            color: Colors.white,
            size: 14,
          ),
        ),
      ),
    );
  }
}

/// Radar visual com sweep animado — peça central do hero header
class _RadarHero extends StatelessWidget {
  final AnimationController radarController;
  final int closedCount;
  final int totalCount;

  const _RadarHero({
    required this.radarController,
    required this.closedCount,
    required this.totalCount,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 160,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Anéis concêntricos
          ...List.generate(3, (i) {
            final size = 80.0 + i * 40.0;
            return Container(
              width: size,
              height: size,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: AppColors.verdeVale
                      .withValues(alpha: 0.08 + (2 - i) * 0.04),
                  width: 1,
                ),
              ),
            );
          }),

          // Sweep do radar
          AnimatedBuilder(
            animation: radarController,
            builder: (context, child) {
              return Transform.rotate(
                angle: radarController.value * 2 * pi,
                child: Container(
                  width: 160,
                  height: 160,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: SweepGradient(
                      startAngle: 0,
                      endAngle: pi / 2,
                      colors: [
                        AppColors.verdeVale.withValues(alpha: 0.25),
                        AppColors.verdeVale.withValues(alpha: 0.0),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),

          // Centro — Contador
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.darkCardColor,
              border: Border.all(
                color: AppColors.verdeVale.withValues(alpha: 0.4),
                width: 2,
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.verdeVale.withValues(alpha: 0.2),
                  blurRadius: 20,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '$closedCount',
                  style: GoogleFonts.poppins(
                    color: AppColors.verdeVale,
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                    height: 1,
                  ),
                ),
                Container(
                  width: 24,
                  height: 1,
                  margin: const EdgeInsets.symmetric(vertical: 3),
                  color: AppColors.verdeVale.withValues(alpha: 0.3),
                ),
                Text(
                  '$totalCount',
                  style: GoogleFonts.poppins(
                    color: Colors.white.withValues(alpha: 0.6),
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    height: 1,
                  ),
                ),
              ],
            ),
          ),

          // Título abaixo
          Positioned(
            bottom: 0,
            child: Column(
              children: [
                Text(
                  'ENIGMAS',
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 4,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Rastreie e desvende',
                  style: GoogleFonts.inter(
                    color: AppColors.cinzaMedio,
                    fontSize: 12,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Barra de progresso com shimmer + labels
class _ProgressBar extends StatelessWidget {
  final double progress;
  final AnimationController shimmerController;
  final int closedCount;
  final int totalCount;

  const _ProgressBar({
    required this.progress,
    required this.shimmerController,
    required this.closedCount,
    required this.totalCount,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Labels
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Progresso da Caçada',
              style: GoogleFonts.inter(
                color: Colors.white.withValues(alpha: 0.5),
                fontSize: 11,
                fontWeight: FontWeight.w500,
              ),
            ),
            Text(
              '${(progress * 100).toInt()}%',
              style: GoogleFonts.poppins(
                color: AppColors.verdeVale,
                fontSize: 12,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        // Barra
        ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: SizedBox(
            height: 8,
            child: Stack(
              children: [
                // Track
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.06),
                  ),
                ),
                // Fill
                FractionallySizedBox(
                  widthFactor: progress.clamp(0.0, 1.0),
                  child: AnimatedBuilder(
                    animation: shimmerController,
                    builder: (context, _) {
                      return Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              AppColors.verdeVale,
                              AppColors.verdeVale.withValues(alpha: 0.7),
                              AppColors.verdeVale,
                            ],
                            stops: [
                              (shimmerController.value - 0.3)
                                  .clamp(0.0, 1.0),
                              shimmerController.value.clamp(0.0, 1.0),
                              (shimmerController.value + 0.3)
                                  .clamp(0.0, 1.0),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
                // Glow no final da barra
                if (progress > 0)
                  Positioned(
                    left: (MediaQuery.of(context).size.width - 56) *
                            progress.clamp(0.0, 1.0) -
                        4,
                    top: 0,
                    bottom: 0,
                    child: Container(
                      width: 8,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white,
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.verdeVale.withValues(alpha: 0.6),
                            blurRadius: 8,
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

/// Linha de estatísticas rápidas
class _StatsRow extends StatelessWidget {
  final List<EnigmaModel> enigmas;
  final List<EnigmaModel> visibleEnigmas;

  const _StatsRow({
    required this.enigmas,
    required this.visibleEnigmas,
  });

  @override
  Widget build(BuildContext context) {
    final availableCount =
        visibleEnigmas.where((e) => e.status != 'closed').length;
    final totalPrize = enigmas.fold<double>(0, (sum, e) => sum + e.prize);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Row(
        children: [
          _StatChip(
            icon: FontAwesomeIcons.locationCrosshairs,
            label: '$availableCount ativos',
            iconColor: AppColors.verdeVale,
          ),
          const SizedBox(width: 10),
          _StatChip(
            icon: FontAwesomeIcons.coins,
            label: 'R\$ ${totalPrize.toStringAsFixed(0)} em jogo',
            iconColor: AppColors.amareloVale,
          ),
          const SizedBox(width: 10),
          _StatChip(
            icon: FontAwesomeIcons.puzzlePiece,
            label: '${enigmas.length} total',
            iconColor: AppColors.cinzaMedio,
          ),
        ],
      ),
    );
  }
}

/// Chip individual de estatística
class _StatChip extends StatelessWidget {
  final FaIconData? icon;
  final String label;
  final Color iconColor;

  const _StatChip({
    required this.icon,
    required this.label,
    required this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: AppColors.darkCardColor.withValues(alpha: 0.7),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: iconColor.withValues(alpha: 0.12),
          ),
        ),
        child: Column(
          children: [
            FaIcon(icon, size: 14, color: iconColor),
            const SizedBox(height: 6),
            Text(
              label,
              style: GoogleFonts.inter(
                color: Colors.white.withValues(alpha: 0.7),
                fontSize: 10,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:parse_server_sdk_flutter/parse_server_sdk_flutter.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:oenigma/core/models/event_model.dart';
import 'package:oenigma/core/models/enigma_model.dart';
import 'package:oenigma/core/utils/app_colors.dart';

import '../widgets/card_enigma.dart';

class LobbyFindEndWinScreen extends ConsumerStatefulWidget {
  final EventModel event;
  const LobbyFindEndWinScreen({super.key, required this.event});

  @override
  ConsumerState<LobbyFindEndWinScreen> createState() =>
      _FindAndWinProgressScreenState();
}

class _FindAndWinProgressScreenState
    extends ConsumerState<LobbyFindEndWinScreen>
    with SingleTickerProviderStateMixin {
  late final Stream<List<EnigmaModel>> _enigmasStream;
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    _enigmasStream = Stream.periodic(const Duration(seconds: 5)).asyncMap((
      _,
    ) async {
      final query = QueryBuilder<ParseObject>(ParseObject('Enigma'))
        ..whereEqualTo('eventId', widget.event.id)
        ..orderByAscending('order');

      final response = await query.query();
      if (response.success && response.results != null) {
        return response.results!.map((e) {
          final doc = e as ParseObject;
          return EnigmaModel.fromMap({
            'id': doc.objectId,
            'title': doc.get<dynamic>('title')?.toString() ?? doc.get<dynamic>('name')?.toString() ?? '',
            'instruction': doc.get<dynamic>('instruction')?.toString() ?? '',
            'prize': doc.get<dynamic>('prize') ?? 0,
            'imageUrl': doc.get<dynamic>('imageUrl')?.toString(),
            'audioUrl': doc.get<dynamic>('audioUrl')?.toString(),
            'type': doc.get<dynamic>('type')?.toString() ?? 'text',
            'characteristics': doc.get<List<dynamic>>('characteristics') ?? [],
            'status': doc.get<dynamic>('status')?.toString(),
            'closedAt': doc.get<DateTime>('closedAt'),
            'code': doc.get<dynamic>('code')?.toString() ?? '',
            'icon': doc.get<dynamic>('icon')?.toString() ?? 'skull',
            'difficulty': doc.get<dynamic>('difficulty')?.toString() ?? 'MÉDIA',
            'hasCompass': doc.get<dynamic>('hasCompass') == true,
            'hasMap': doc.get<dynamic>('hasMap') == true,
            'hasRadar': doc.get<dynamic>('hasRadar') == true,
            'compassPrice': doc.get<dynamic>('compassPrice'),
            'mapPrice': doc.get<dynamic>('mapPrice'),
            'radarPrice': doc.get<dynamic>('radarPrice'),
            'compassDuration': doc.get<dynamic>('compassDuration'),
            'compassCoords': doc.get<dynamic>('compassCoords')?.toString(),
          });
        }).toList();
      }
      return [];
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
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

          return CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              SliverToBoxAdapter(
                child: SafeArea(
                  bottom: false,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16.0, 12.0, 16.0, 16.0),
                    child: Column(
                      children: [
                        // Header
                        Row(
                          children: [
                            GestureDetector(
                              onTap: () => Navigator.pop(context),
                              child: Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.06),
                                  shape: BoxShape.circle,
                                  border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
                                ),
                                child: const Center(
                                  child: FaIcon(
                                    FontAwesomeIcons.chevronLeft,
                                    color: Colors.white,
                                    size: 14,
                                  ),
                                ),
                              ),
                            ),
                            Expanded(
                              child: Text(
                                'Enigmas',
                                textAlign: TextAlign.center,
                                style: GoogleFonts.poppins(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ),
                            const SizedBox(width: 40),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Divider(color: Colors.white.withValues(alpha: 0.08), height: 1),
                        const SizedBox(height: 16),
                        // Hunt Info
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.darkCardColor,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.25),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  const FaIcon(
                                    FontAwesomeIcons.mapPin,
                                    color: AppColors.verdeVale,
                                    size: 14,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Ache & Ganhe',
                                    style: GoogleFonts.poppins(
                                      color: Colors.white,
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.amareloVale.withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: AppColors.amareloVale.withValues(alpha: 0.35),
                                  ),
                                ),
                                child: RichText(
                                  text: TextSpan(
                                    style: GoogleFonts.inter(
                                      fontSize: 12,
                                      color: AppColors.cinzaMedio,
                                    ),
                                    children: [
                                      TextSpan(
                                        text:
                                            '${enigmas.where((e) => e.status == 'closed').length}',
                                        style: const TextStyle(
                                          color: AppColors.amareloVale,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      TextSpan(
                                        text: ' / ${enigmas.length}',
                                        style: TextStyle(
                                          color: Colors.white.withValues(alpha: 0.7),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // Indicador de Carregamento Inicial
              if (snapshot.connectionState == ConnectionState.waiting &&
                  !snapshot.hasData)
                const SliverFillRemaining(
                  child: Center(
                    child: CircularProgressIndicator(color: AppColors.verdeVale),
                  ),
                )
              // Estado Vazio (Finalizado)
              else if (visibleEnigmas.isEmpty)
                SliverFillRemaining(
                  child: Padding(
                    padding: const EdgeInsets.all(32.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppColors.verdeVale.withValues(alpha: 0.12),
                            border: Border.all(color: AppColors.verdeVale.withValues(alpha: 0.25)),
                          ),
                          child: const FaIcon(
                            FontAwesomeIcons.flagCheckered,
                            size: 48,
                            color: AppColors.verdeVale,
                          ),
                        ),
                        const SizedBox(height: 24),
                        Text(
                          "CAÇADA ENCERRADA!",
                          style: GoogleFonts.poppins(
                            fontSize: 20,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                            letterSpacing: 1.5,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          "Todos os tesouros e enigmas deste evento já foram encontrados.",
                          textAlign: TextAlign.center,
                          style: GoogleFonts.inter(
                            color: AppColors.cinzaMedio,
                            fontSize: 15,
                            height: 1.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              // Lista de Enigmas
              else
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 40),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate((context, index) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12.0),
                        child: CardEnigma(
                          enigma: visibleEnigmas[index],
                          event: widget.event,
                          animation: _animationController,
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

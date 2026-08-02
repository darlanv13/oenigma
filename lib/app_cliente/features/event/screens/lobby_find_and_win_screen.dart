import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:parse_server_sdk_flutter/parse_server_sdk_flutter.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:oenigma/app_cliente/core/models/event_model.dart';
import 'package:oenigma/app_cliente/core/models/enigma_model.dart';

import '../widgets/card_enigma.dart';

class FindAndWinProgressScreen extends ConsumerStatefulWidget {
  final EventModel event;
  const FindAndWinProgressScreen({super.key, required this.event});

  @override
  ConsumerState<FindAndWinProgressScreen> createState() =>
      _FindAndWinProgressScreenState();
}

class _FindAndWinProgressScreenState
    extends ConsumerState<FindAndWinProgressScreen>
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
            'title': doc.get<String>('title') ?? '',
            'instruction': doc.get<String>('instruction') ?? '',
            'prize': doc.get<dynamic>('prize') ?? 0,
            'imageUrl': doc.get<String>('imageUrl'),
            'audioUrl': doc.get<String>('audioUrl'),
            'type': doc.get<String>('type') ?? 'text',
            'characteristics': doc.get<List<dynamic>>('characteristics') ?? [],
            'status': doc.get<String>('status'),
            'closedAt': doc.get<DateTime>('closedAt'),
            'code': doc.get<String>('code') ?? '',
            'icon': doc.get<String>('icon') ?? 'skull',
            'difficulty': doc.get<String>('difficulty') ?? 'MÉDIA',
            'hasCompass': doc.get<bool>('hasCompass') ?? false,
            'hasMap': doc.get<bool>('hasMap') ?? false,
            'hasRadar': doc.get<bool>('hasRadar') ?? false,
            'compassPrice': doc.get<num>('compassPrice')?.toDouble() ?? 15.0,
            'mapPrice': doc.get<num>('mapPrice')?.toDouble() ?? 4.99,
            'radarPrice': doc.get<num>('radarPrice')?.toDouble() ?? 2.99,
            'compassDuration': doc.get<num>('compassDuration')?.toInt() ?? 0,
            'compassCoords': doc.get<String>('compassCoords'),
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
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16.0, 48.0, 16.0, 16.0),
                  child: Column(
                    children: [
                      // Header
                      Row(
                        children: [
                          Container(
                            decoration: BoxDecoration(
                              color: const Color(
                                0xFFC0A060,
                              ).withValues(alpha: 0.06),
                              shape: BoxShape.circle,
                            ),
                            child: IconButton(
                              icon: const FaIcon(
                                FontAwesomeIcons.chevronLeft,
                                color: Color(0xFFC0A060),
                                size: 16,
                              ),
                              onPressed: () => Navigator.pop(context),
                            ),
                          ),
                          Expanded(
                            child: Text(
                              'Enigmas',
                              textAlign: TextAlign.center,
                              style: GoogleFonts.orbitron(
                                color: const Color(0xFFF0E6C5),
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                          SizedBox(
                            width: 48,
                            child: Align(
                              alignment: Alignment.centerRight,
                              child: FaIcon(
                                FontAwesomeIcons.ellipsisVertical,
                                color: const Color(0xFFC0A060),
                                size: 18,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      const Divider(color: Colors.white12, height: 1),
                      const SizedBox(height: 16),
                      // Hunt Info
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFF16181C).withValues(alpha: 0.4),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                const FaIcon(
                                  FontAwesomeIcons.mapPin,
                                  color: Color(0xFFC0A060),
                                  size: 14,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Ache & Ganhe',
                                  style: GoogleFonts.inter(
                                    color: const Color(0xFFF0E6C5),
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
                                color: const Color(
                                  0xFFC0A060,
                                ).withValues(alpha: 0.08),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: const Color(
                                    0xFFC0A060,
                                  ).withValues(alpha: 0.1),
                                ),
                              ),
                              child: RichText(
                                text: TextSpan(
                                  style: GoogleFonts.inter(
                                    fontSize: 12,
                                    color: const Color(0xFFB0A07A),
                                  ),
                                  children: [
                                    TextSpan(
                                      text:
                                          '${enigmas.where((e) => e.status == 'closed').length}',
                                      style: const TextStyle(
                                        color: Color(0xFFC0A060),
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    TextSpan(text: ' / ${enigmas.length}'),
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

              // Indicador de Carregamento Inicial
              if (snapshot.connectionState == ConnectionState.waiting &&
                  !snapshot.hasData)
                const SliverFillRemaining(
                  child: Center(
                    child: CircularProgressIndicator(color: Color(0xFFFFD54F)),
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
                            color: Colors.white.withValues(alpha: 0.05),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.1),
                            ),
                          ),
                          child: const FaIcon(
                            FontAwesomeIcons.flagCheckered,
                            size: 50,
                            color: Color(0xFFFFD54F),
                          ),
                        ),
                        const SizedBox(height: 24),
                        const Text(
                          "CAÇADA ENCERRADA!",
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                            letterSpacing: 2,
                          ),
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          "Todos os tesouros e enigmas deste evento já foram encontrados.",
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.grey,
                            fontSize: 16,
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
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
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

              // Rodapé Simples
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 24.0, top: 12.0),
                  child: Container(
                    decoration: BoxDecoration(
                      border: Border(
                        top: BorderSide(
                          color: const Color(
                            0xFFC0A060,
                          ).withValues(alpha: 0.06),
                        ),
                      ),
                    ),
                    padding: const EdgeInsets.only(top: 12.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const FaIcon(
                          FontAwesomeIcons.shieldHalved,
                          color: Color(0xFFC0A060),
                          size: 10,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Caçada segura',
                          style: GoogleFonts.inter(
                            fontSize: 10,
                            color: const Color(0xFF4A4A4A),
                            letterSpacing: 1.0,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:parse_server_sdk_flutter/parse_server_sdk_flutter.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:oenigma/app_cliente/core/models/event_model.dart';
import 'package:oenigma/app_cliente/core/models/enigma_model.dart';
import 'dart:ui';

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
        ..whereEqualTo(
          'event',
          (ParseObject('Event')..objectId = widget.event.id).toPointer(),
        )
        ..orderByAscending('order');

      final response = await query.query();
      if (response.success && response.results != null) {
        return response.results!.map((e) {
          final doc = e as ParseObject;
          return EnigmaModel.fromMap({
            'id': doc.objectId,
            'title': doc.get<String>('title') ?? '',
            'instruction': doc.get<String>('instruction') ?? '',
            'prize': doc.get<num>('prize') ?? 0,
            'imageUrl': doc.get<String>('imageUrl'),
            'type': doc.get<String>('type') ?? 'text',
            'characteristics': doc.get<List<dynamic>>('characteristics') ?? [],
            'status': doc.get<String>('status'),
            'closedAt': doc.get<DateTime>('closedAt'),
            'code': doc.get<String>('code') ?? '',
            'icon': doc.get<String>('icon') ?? 'skull',
            'difficulty': doc.get<String>('difficulty') ?? 'MÉDIA',
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
                  child: Row(
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.05),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.1),
                          ),
                        ),
                        child: IconButton(
                          icon: const FaIcon(
                            FontAwesomeIcons.angleLeft,
                            color: Color(0xFFD6B570),
                            size: 18,
                          ),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Text(
                        'Enigmas',
                        style: GoogleFonts.orbitron(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
                  child: Column(
                    children: [
                      const Divider(color: Colors.white12, height: 1),
                      const SizedBox(height: 24),
                      Text(
                        'DESVENDE OS MISTÉRIOS',
                        style: GoogleFonts.orbitron(
                          color: const Color(0xFFD6B570),
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.5,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Escolha um enigma e comece a caçada',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.5),
                          fontSize: 12,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
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
              // Grade de Enigmas
              else
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
                  sliver: SliverGrid(
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                      childAspectRatio: 0.9,
                    ),
                    delegate: SliverChildBuilderDelegate((context, index) {
                      return CardEnigma(
                        enigma: visibleEnigmas[index],
                        event: widget.event,
                        animation: _animationController,
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

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:parse_server_sdk_flutter/parse_server_sdk_flutter.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

import 'package:oenigma/core/models/event_model.dart';
import 'package:oenigma/core/models/enigma_model.dart';
import 'package:oenigma/core/utils/app_colors.dart';
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
              // Header Transparente para valorizar o mapa
              SliverAppBar(
                expandedHeight: 120.0,
                backgroundColor: Colors.transparent,
                pinned: true,
                elevation: 0,
                leading: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: CircleAvatar(
                    backgroundColor: Colors.black.withValues(alpha: 0.5),
                    child: IconButton(
                      icon: const FaIcon(
                        FontAwesomeIcons.chevronLeft,
                        color: Colors.white,
                        size: 18,
                      ),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ),
                ),
                flexibleSpace: FlexibleSpaceBar(
                  centerTitle: true,
                  title: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.6),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: const Color(0xFFFFD54F).withValues(alpha: 0.3),
                      ),
                    ),
                    child: Text(
                      widget.event.name,
                      style: const TextStyle(
                        color: Color(0xFFFFD54F),
                        fontWeight: FontWeight.w900,
                        fontSize: 16,
                        letterSpacing: 0.5,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  background: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          const Color(0xFF121212).withValues(alpha: 0.9),
                          Colors.transparent,
                        ],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                  ),
                ),
              ),

              // Header elegante

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
                      crossAxisCount: 3,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 16,
                      childAspectRatio:
                          0.65, // Proporção mais alta para acomodar os badges
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

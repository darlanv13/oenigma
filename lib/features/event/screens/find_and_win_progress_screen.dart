import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:parse_server_sdk_flutter/parse_server_sdk_flutter.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

import 'package:oenigma/core/models/event_model.dart';
import 'package:oenigma/core/models/enigma_model.dart';
import 'package:oenigma/core/utils/app_colors.dart';

import '../widgets/card_enigma.dart';

class FindAndWinProgressScreen extends ConsumerStatefulWidget {
  final EventModel event;
  const FindAndWinProgressScreen({super.key, required this.event});

  @override
  ConsumerState<FindAndWinProgressScreen> createState() => _FindAndWinProgressScreenState();
}

class _FindAndWinProgressScreenState extends ConsumerState<FindAndWinProgressScreen> with SingleTickerProviderStateMixin {
  late final Stream<List<EnigmaModel>> _enigmasStream;
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    _enigmasStream = Stream.periodic(const Duration(seconds: 5)).asyncMap((_) async {
      final query = QueryBuilder<ParseObject>(ParseObject('Enigma'))
        ..whereEqualTo('event', (ParseObject('Event')..objectId = widget.event.id).toPointer())
        ..orderByAscending('order');

      final response = await query.query();
      if (response.success && response.results != null) {
        return response.results!.map((e) {
          final doc = e as ParseObject;
          return EnigmaModel.fromMap({
            'id': doc.objectId,
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
      appBar: AppBar(title: Text(widget.event.name)),
      body: StreamBuilder<List<EnigmaModel>>(
        stream: _enigmasStream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) {
            return const Center(child: CircularProgressIndicator(color: primaryAmber));
          }

          final enigmas = snapshot.data ?? [];
          final visibleEnigmas = enigmas.where((e) {
            if (e.status != 'closed') return true;
            if (e.closedAt != null && DateTime.now().difference(e.closedAt!).inMinutes < 15) return true;
            return false;
          }).toList();

          if (visibleEnigmas.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  FaIcon(FontAwesomeIcons.flag, size: 60, color: primaryAmber),
                  SizedBox(height: 16),
                  Text("Evento Finalizado!", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                  Text("Todos os enigmas foram resolvidos.", style: TextStyle(color: secondaryTextColor)),
                ],
              ),
            );
          }

          return GridView.builder(
            padding: const EdgeInsets.all(16),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: 1.0,
            ),
            itemCount: visibleEnigmas.length,
            itemBuilder: (context, index) {
              return CardEnigma(
                enigma: visibleEnigmas[index],
                event: widget.event,
                animation: _animationController,
              );
            },
          );
        },
      ),
    );
  }
}

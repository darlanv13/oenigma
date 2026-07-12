import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:parse_server_sdk_flutter/parse_server_sdk_flutter.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:intl/intl.dart';

import 'package:oenigma/core/models/event_model.dart';
import 'package:oenigma/core/models/enigma_model.dart';
import 'package:oenigma/core/utils/app_colors.dart';
import 'package:oenigma/features/enigma/providers/enigma_repository_provider.dart';
import 'package:oenigma/core/widgets/dialogs/cooldown_dialog.dart';
import 'package:oenigma/core/widgets/dialogs/enigma_success_dialog.dart';
import 'package:oenigma/core/widgets/dialogs/error_dialog.dart';
import 'package:oenigma/features/enigma/screens/enigma_screen.dart';

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

  dynamic _getIconForCharacteristic(String key) {
    switch (key) {
      case 'nado': return FontAwesomeIcons.personSwimming;
      case 'corrida': return FontAwesomeIcons.personRunning;
      case 'camera': return FontAwesomeIcons.camera;
      case 'noite': return FontAwesomeIcons.moon;
      case 'dia': return FontAwesomeIcons.sun;
      case 'exploracao': return FontAwesomeIcons.compass;
      case 'escalada': return FontAwesomeIcons.mountain;
      default: return FontAwesomeIcons.circle;
    }
  }

  Widget _buildEnigmaCard(EnigmaModel enigma) {
    bool isClosed = enigma.status == 'closed';
    bool isTemporarilyBlocked = false;

    if (isClosed && enigma.closedAt != null) {
      final difference = DateTime.now().difference(enigma.closedAt!);
      if (difference.inMinutes < 15) {
        isTemporarilyBlocked = true;
      } else {
        return const SizedBox.shrink(); // Hide completely if more than 15 mins
      }
    }

    final currencyFormat = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');

    return GestureDetector(
      onTap: () {
        if (isTemporarilyBlocked) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Este enigma já foi resolvido por outro jogador e desaparecerá em breve.'), backgroundColor: Colors.red),
          );
          return;
        }

        // Use standard Enigma validation dialog logic reusing what we have or push to a detail
        _showValidationDialog(enigma);
      },
      child: AnimatedBuilder(
        animation: _animationController,
        builder: (context, child) {
          return Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              gradient: LinearGradient(
                colors: isTemporarilyBlocked
                  ? [Colors.grey.shade800, Colors.grey.shade600]
                  : [
                      Color.lerp(primaryAmber, Colors.orangeAccent, _animationController.value)!,
                      Color.lerp(Colors.orangeAccent, primaryAmber, _animationController.value)!,
                    ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              boxShadow: [
                BoxShadow(
                  color: isTemporarilyBlocked ? Colors.transparent : primaryAmber.withValues(alpha: 0.5 * _animationController.value),
                  blurRadius: 10,
                  spreadRadius: 2,
                )
              ],
            ),
            child: Stack(
              children: [
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        enigma.instruction,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.black87),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const Spacer(),
                      Text(
                        currencyFormat.format(enigma.prize),
                        style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18, color: Colors.black),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: enigma.characteristics.map((char) {
                          return Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 4.0),
                            child: FaIcon(_getIconForCharacteristic(char), size: 14, color: Colors.black54),
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                ),
                if (isTemporarilyBlocked)
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      color: Colors.black.withValues(alpha: 0.6),
                    ),
                    child: const Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          FaIcon(FontAwesomeIcons.lock, color: Colors.white, size: 30),
                          SizedBox(height: 8),
                          Text('RESOLVIDO', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  void _showValidationDialog(EnigmaModel enigma) {
    showDialog(
      context: context,
      builder: (context) {
        final codeController = TextEditingController();
        bool isLoading = false;
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              backgroundColor: darkBackground,
              title: const Text('Resolver Enigma', style: TextStyle(color: primaryAmber)),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(enigma.instruction, style: const TextStyle(color: Colors.white)),
                  const SizedBox(height: 16),
                  if (enigma.type == 'qrcode' || enigma.type == 'foto')
                    ElevatedButton.icon(
                      onPressed: () {
                         Navigator.pop(context);
                         Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ScannerScreen(
                              onScan: (scannedCode) {
                                  Navigator.pop(context);
                                  _validateCode(enigma.id, scannedCode);
                              }
                            ),
                          ),
                        );
                      },
                      icon: const FaIcon(FontAwesomeIcons.qrcode, size: 16),
                      label: const Text('Escanear QR Code'),
                      style: ElevatedButton.styleFrom(backgroundColor: primaryAmber, foregroundColor: Colors.black),
                    )
                  else
                    TextField(
                      controller: codeController,
                      style: const TextStyle(color: Colors.white),
                      decoration: const InputDecoration(
                        hintText: "Sua resposta",
                        hintStyle: TextStyle(color: Colors.grey),
                      ),
                    ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancelar', style: TextStyle(color: Colors.grey)),
                ),
                if (enigma.type != 'qrcode' && enigma.type != 'foto')
                  ElevatedButton(
                    onPressed: isLoading ? null : () async {
                      if (codeController.text.isEmpty) return;
                      setStateDialog(() => isLoading = true);
                      final code = codeController.text.trim();
                      if (context.mounted) {
                        Navigator.pop(context);
                      }
                      await _validateCode(enigma.id, code);
                    },
                    style: ElevatedButton.styleFrom(backgroundColor: primaryAmber, foregroundColor: Colors.black),
                    child: isLoading ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.black)) : const Text('Validar'),
                  ),
              ],
            );
          }
        );
      },
    );
  }

  Future<void> _validateCode(String enigmaId, String code) async {
    try {
      final result = await ref.read(enigmaRepositoryProvider).callEnigmaFunction('scan_enigma', {
        'eventId': widget.event.id,
        'enigmaId': enigmaId,
        'code': code,
      });

      final data = Map<String, dynamic>.from(result.result);
      if (mounted && !(data['success'] as bool)) {
        final message = data['message'] ?? "Código incorreto.";
        if (data['cooldownUntil'] != null) {
          final cooldownUntil = DateTime.parse(data['cooldownUntil'].toString());
          if (cooldownUntil.isAfter(DateTime.now())) {
            showDialog(
              context: context,
              barrierDismissible: false,
              builder: (_) => CooldownDialog(
                cooldownUntil: cooldownUntil,
                onCooldownFinished: () {},
              ),
            );
          }
        } else {
          showErrorDialog(context, message: message);
        }
      } else if (mounted) {
        showEnigmaSuccessDialog(
          context,
          onContinue: () {
            Navigator.of(context).pop();
          },
        );
      }
    } catch (e) {
      if (mounted) {
        showErrorDialog(context, message: "Ocorreu um erro: ${e.toString()}");
      }
    }
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
              return _buildEnigmaCard(visibleEnigmas[index]);
            },
          );
        },
      ),
    );
  }
}

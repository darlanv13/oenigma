import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:intl/intl.dart';

import 'package:oenigma/core/models/event_model.dart';
import 'package:oenigma/core/models/enigma_model.dart';
import 'package:oenigma/core/models/phase_model.dart';
import 'package:oenigma/core/utils/app_colors.dart';
import 'package:oenigma/features/enigma/screens/enigma_screen.dart';

class CardEnigma extends StatefulWidget {
  final EnigmaModel enigma;
  final EventModel event;
  final Animation<double> animation;

  const CardEnigma({
    super.key,
    required this.enigma,
    required this.event,
    required this.animation,
  });

  @override
  State<CardEnigma> createState() => _CardEnigmaState();
}

class _CardEnigmaState extends State<CardEnigma> {
  double _scale = 1.0;

  dynamic _getIconForCharacteristic(String key) {
    switch (key) {
      case 'nado':
        return FontAwesomeIcons.personSwimming;
      case 'corrida':
        return FontAwesomeIcons.personRunning;
      case 'camera':
        return FontAwesomeIcons.camera;
      case 'noite':
        return FontAwesomeIcons.moon;
      case 'dia':
        return FontAwesomeIcons.sun;
      case 'exploracao':
        return FontAwesomeIcons.compass;
      case 'escalada':
        return FontAwesomeIcons.mountain;
      default:
        return FontAwesomeIcons.circle;
    }
  }

  void _handleTap(bool isTemporarilyBlocked) {
    if (isTemporarilyBlocked) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Este enigma já foi resolvido e desaparecerá em breve.',
          ),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    final mockPhase = PhaseModel(
      id: 'find_and_win',
      order: 1,
      enigmas: [widget.enigma],
    );

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EnigmaScreen(
          event: widget.event,
          phase: mockPhase,
          initialEnigma: widget.enigma,
          onEnigmaSolved: () {},
        ),
      ),
    );
  }

  Stream<String> _countdownStream(DateTime closedAt) async* {
    final endTime = closedAt.add(const Duration(minutes: 15));
    while (true) {
      final now = DateTime.now();
      if (now.isAfter(endTime)) {
        yield "00:00";
        break;
      }
      final diff = endTime.difference(now);
      final m = diff.inMinutes.toString().padLeft(2, '0');
      final s = (diff.inSeconds % 60).toString().padLeft(2, '0');
      yield "$m:$s";
      await Future.delayed(const Duration(seconds: 1));
    }
  }

  @override
  Widget build(BuildContext context) {
    bool isClosed = widget.enigma.status == 'closed';
    bool isTemporarilyBlocked = false;

    if (isClosed && widget.enigma.closedAt != null) {
      final difference = DateTime.now().difference(widget.enigma.closedAt!);
      if (difference.inMinutes < 15) {
        isTemporarilyBlocked = true;
      } else {
        return const SizedBox.shrink();
      }
    }

    final currencyFormat = NumberFormat.currency(
      locale: 'pt_BR',
      symbol: r'R$',
    );

    return GestureDetector(
      onTapDown: (_) => setState(() => _scale = 0.92),
      onTapUp: (_) {
        setState(() => _scale = 1.0);
        _handleTap(isTemporarilyBlocked);
      },
      onTapCancel: () => setState(() => _scale = 1.0),
      child: AnimatedScale(
        scale: _scale,
        duration: const Duration(milliseconds: 150),
        curve: Curves.easeInOut,
        child: AnimatedBuilder(
          animation: widget.animation,
          builder: (context, child) {
            // Brilho pulsante
            final double glowOpacity = 0.2 + (0.6 * widget.animation.value);
            final double glowSpread = 1.0 + (3.0 * widget.animation.value);

            return Container(
              decoration: BoxDecoration(
                color: const Color(0xFF1E1E1E),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isTemporarilyBlocked
                      ? Colors.white.withValues(alpha: 0.1)
                      : primaryAmber.withValues(alpha: glowOpacity),
                  width: 1.5,
                ),
                boxShadow: [
                  if (!isTemporarilyBlocked)
                    BoxShadow(
                      color: primaryAmber.withValues(alpha: glowOpacity * 0.5),
                      blurRadius: 12,
                      spreadRadius: glowSpread,
                      offset: const Offset(0, 3),
                    ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 12,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            widget.enigma.title,
                            style: const TextStyle(
                              fontWeight: FontWeight.w900,
                              fontSize: 11,
                              color: Colors.white,
                              letterSpacing: 0.5,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.center,
                          ),
                          const Spacer(),

                          // Badge Centralizado do Prêmio
                          Center(
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [
                                    Color(0xFFFFD54F),
                                    Color(0xFFF57F17),
                                  ],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                borderRadius: BorderRadius.circular(10),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.4),
                                    blurRadius: 5,
                                    offset: const Offset(0, 3),
                                  ),
                                ],
                              ),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const FaIcon(
                                    FontAwesomeIcons.sackDollar,
                                    size: 20,
                                    color: Colors.black,
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    currencyFormat.format(widget.enigma.prize),
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w900,
                                      fontSize: 11,
                                      color: Colors.black,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const Spacer(),

                          // Características
                          if (widget.enigma.characteristics.isNotEmpty)
                            Container(
                              padding: const EdgeInsets.symmetric(vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.black.withValues(alpha: 0.3),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: widget.enigma.characteristics.map((
                                  char,
                                ) {
                                  return Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 3.0,
                                    ),
                                    child: FaIcon(
                                      _getIconForCharacteristic(char),
                                      size: 10,
                                      color: Colors.grey,
                                    ),
                                  );
                                }).toList(),
                              ),
                            ),
                        ],
                      ),
                    ),

                    // Overlay de Bloqueio com Glassmorphism e Temporizador
                    if (isTemporarilyBlocked)
                      Positioned.fill(
                        child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.75),
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const FaIcon(
                                  FontAwesomeIcons.lock,
                                  color: Colors.redAccent,
                                  size: 24,
                                ),
                                const SizedBox(height: 6),
                                StreamBuilder<String>(
                                  stream: _countdownStream(
                                    widget.enigma.closedAt!,
                                  ),
                                  builder: (context, snapshot) {
                                    return Text(
                                      snapshot.data ?? "--:--",
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w900,
                                        fontSize: 14,
                                        letterSpacing: 1.5,
                                      ),
                                    );
                                  },
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

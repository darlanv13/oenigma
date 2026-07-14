import 'dart:async';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:intl/intl.dart';
import 'package:flutter_svg/flutter_svg.dart';

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

  void _handleTap(bool isTemporarilyBlocked) {
    if (isTemporarilyBlocked) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Este baú já foi saqueado e desaparecerá em breve.'),
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
      onTapDown: (_) => setState(() => _scale = 0.90),
      onTapUp: (_) {
        setState(() => _scale = 1.0);
        _handleTap(isTemporarilyBlocked);
      },
      onTapCancel: () => setState(() => _scale = 1.0),
      child: AnimatedScale(
        scale: _scale,
        duration: const Duration(milliseconds: 150),
        curve: Curves.easeOutBack,
        child: AnimatedBuilder(
          animation: widget.animation,
          builder: (context, child) {
            // Efeito de brilho pulsante e flutuação (respiração)
            final double glowOpacity = 0.2 + (0.6 * widget.animation.value);
            final double floatOffset = 6.0 * widget.animation.value;

            return Container(
              color: Colors.transparent,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  // Título do Enigma Flutuante
                  Text(
                    widget.enigma.title,
                    style: const TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 12,
                      color: Colors.white,
                      letterSpacing: 0.5,
                      shadows: [
                        Shadow(
                          color: Colors.black,
                          blurRadius: 6,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),

                  // O Baú com Sombras e Efeitos
                  Expanded(
                    child: Stack(
                      alignment: Alignment.center,
                      clipBehavior: Clip.none,
                      children: [
                        // Sombra Oval no chão (Aumenta/Diminui com a flutuação)
                        Positioned(
                          bottom: 0,
                          child: Container(
                            width: 50 + (10 * widget.animation.value),
                            height: 12,
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.6),
                              borderRadius: BorderRadius.circular(50),
                              boxShadow: [
                                if (!isTemporarilyBlocked)
                                  BoxShadow(
                                    color: const Color(
                                      0xFFFFD54F,
                                    ).withValues(alpha: glowOpacity * 0.5),
                                    blurRadius: 15,
                                    spreadRadius: 5,
                                  ),
                              ],
                            ),
                          ),
                        ),

                        // O SVG do Baú (Flutuando)
                        Positioned(
                          bottom: isTemporarilyBlocked ? 5 : 5 + floatOffset,
                          child: Opacity(
                            opacity: isTemporarilyBlocked ? 0.4 : 1.0,
                            child: SvgPicture.asset(
                              'assets/icon/chest.svg',
                              width: 70, // Ajuste o tamanho conforme seu SVG
                              height: 70,
                            ),
                          ),
                        ),

                        // Ícone de Cadeado se estiver bloqueado
                        if (isTemporarilyBlocked)
                          Positioned(
                            bottom: 25,
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.black.withValues(alpha: 0.7),
                                shape: BoxShape.circle,
                              ),
                              child: const FaIcon(
                                FontAwesomeIcons.lock,
                                color: Colors.redAccent,
                                size: 24,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 8),

                  // Badge Inferior: Temporizador ou Prêmio
                  if (isTemporarilyBlocked)
                    StreamBuilder<String>(
                      stream: _countdownStream(widget.enigma.closedAt!),
                      builder: (context, snapshot) {
                        return Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.8),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: Colors.redAccent.withValues(alpha: 0.5),
                              width: 1.5,
                            ),
                          ),
                          child: Text(
                            snapshot.data ?? "--:--",
                            style: const TextStyle(
                              color: Colors.redAccent,
                              fontWeight: FontWeight.w900,
                              fontSize: 12,
                              letterSpacing: 1.0,
                            ),
                          ),
                        );
                      },
                    )
                  else
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFFFFD54F), Color(0xFFF57F17)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.6),
                            blurRadius: 5,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const FaIcon(
                            FontAwesomeIcons.sackDollar,
                            size: 12,
                            color: Colors.black,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            currencyFormat.format(widget.enigma.prize),
                            style: const TextStyle(
                              fontWeight: FontWeight.w900,
                              fontSize: 12,
                              color: Colors.black,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

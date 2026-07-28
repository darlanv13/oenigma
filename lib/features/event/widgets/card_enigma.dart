import 'dart:async';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
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

  dynamic _getIconData(String iconName) {
    switch (iconName) {
      case 'map':
        return FontAwesomeIcons.map;
      case 'robot':
        return FontAwesomeIcons.robot;
      case 'ghost':
        return FontAwesomeIcons.ghost;
      case 'crown':
        return FontAwesomeIcons.crown;
      case 'skull':
      default:
        return FontAwesomeIcons.skull;
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
      symbol: r'',
    );

    return GestureDetector(
      onTapDown: (_) => setState(() => _scale = 0.95),
      onTapUp: (_) {
        setState(() => _scale = 1.0);
        _handleTap(isTemporarilyBlocked);
      },
      onTapCancel: () => setState(() => _scale = 1.0),
      child: AnimatedScale(
        scale: _scale,
        duration: const Duration(milliseconds: 100),
        child: Container(
          decoration: BoxDecoration(
            color: const Color(0xFF1E1E1E),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isTemporarilyBlocked
                  ? Colors.redAccent.withValues(alpha: 0.3)
                  : const Color(0xFFD6B570).withValues(alpha: 0.3),
              width: 1,
            ),
            boxShadow: [
              if (!isTemporarilyBlocked)
                BoxShadow(
                  color: const Color(0xFFD6B570).withValues(alpha: 0.05),
                  blurRadius: 10,
                  spreadRadius: 2,
                ),
            ],
          ),
          child: Stack(
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    FaIcon(
                      _getIconData(widget.enigma.icon),
                      size: 48,
                      color: const Color(0xFFD6B570),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      widget.enigma.title,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${widget.enigma.difficulty} • 0 ETAPAS',
                      style: const TextStyle(
                        color: Colors.grey,
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 1.0,
                      ),
                    ),
                    const Spacer(),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const FaIcon(
                          FontAwesomeIcons.coins,
                          size: 14,
                          color: Color(0xFFD6B570),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'R\$ ${currencyFormat.format(widget.enigma.prize).trim()}',
                          style: GoogleFonts.orbitron(
                            color: Color(0xFFD6B570),
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              if (isTemporarilyBlocked)
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.7),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const FaIcon(
                            FontAwesomeIcons.lock,
                            color: Colors.redAccent,
                            size: 32,
                          ),
                          const SizedBox(height: 12),
                          StreamBuilder<String>(
                            stream: _countdownStream(widget.enigma.closedAt!),
                            builder: (context, snapshot) {
                              return Text(
                                snapshot.data ?? "--:--",
                                style: const TextStyle(
                                  color: Colors.redAccent,
                                  fontWeight: FontWeight.w900,
                                  fontSize: 16,
                                  letterSpacing: 1.0,
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
      ),
    );
  }
}

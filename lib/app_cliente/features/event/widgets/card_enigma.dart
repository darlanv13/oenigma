import 'dart:async';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import 'package:oenigma/core/models/event_model.dart';
import 'package:oenigma/core/models/enigma_model.dart';
import 'package:oenigma/core/models/phase_model.dart';
import 'package:oenigma/app_cliente/features/enigma/screens/enigma_screen.dart';
import 'map_dots_painter.dart';

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

    Color statusColor;
    if (isTemporarilyBlocked) {
      statusColor = const Color(0xFFC0A060); // Gold for completed
    } else if (!isClosed) {
      statusColor = const Color(0xFF4CAF50); // Green for available
    } else {
      statusColor = const Color(0xFF555555); // Grey for blocked (if used)
    }

    return GestureDetector(
      onTapDown: (_) => setState(() => _scale = 0.97),
      onTapUp: (_) {
        setState(() => _scale = 1.0);
        _handleTap(isTemporarilyBlocked);
      },
      onTapCancel: () => setState(() => _scale = 1.0),
      child: AnimatedScale(
        scale: _scale,
        duration: const Duration(milliseconds: 150),
        child: Container(
          decoration: BoxDecoration(
            color: const Color(0xFF16181C).withValues(alpha: 0.6),
            borderRadius: BorderRadius.circular(20),
            border: Border(
              left: BorderSide(color: statusColor, width: 3),
            ),
          ),
          clipBehavior: Clip.antiAlias,
          child: Stack(
            children: [
              Positioned.fill(
                child: CustomPaint(
                  painter: MapDotsPainter(
                    dotColor: const Color(0xFFC0A060).withValues(alpha: 0.04),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 18.0, vertical: 16.0),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Icon Container
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: const Color(0xFFC0A060).withValues(alpha: 0.08),
                        border: Border.all(
                          color: const Color(0xFFC0A060).withValues(alpha: 0.1),
                        ),
                      ),
                      child: Center(
                        child: FaIcon(
                          isTemporarilyBlocked ? FontAwesomeIcons.circleCheck : _getIconData(widget.enigma.icon),
                          size: 16,
                          color: statusColor,
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    // Main Content
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Title & Badge
                          Row(
                            children: [
                              Flexible(
                                child: Text(
                                  widget.enigma.title,
                                  style: GoogleFonts.inter(
                                    color: const Color(0xFFF0E6C5),
                                    fontWeight: FontWeight.w600,
                                    fontSize: 13,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 1),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFC0A060).withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: const Color(0xFFC0A060).withValues(alpha: 0.1),
                                  ),
                                ),
                                child: Text(
                                  isTemporarilyBlocked ? 'CONCLUÍDO' : 'DISPONÍVEL',
                                  style: GoogleFonts.inter(
                                    color: const Color(0xFFC0A060),
                                    fontSize: 8,
                                    fontWeight: FontWeight.w600,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 2),
                          // Desc & Difficulty
                          Row(
                            children: [
                              Flexible(
                                child: Text(
                                  widget.enigma.instruction.isNotEmpty ? widget.enigma.instruction : 'Encontre a resposta',
                                  style: GoogleFonts.inter(
                                    color: const Color(0xFF8A7A5A),
                                    fontSize: 10,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  FaIcon(
                                    FontAwesomeIcons.star,
                                    size: 8,
                                    color: const Color(0xFFC0A060),
                                  ),
                                  const SizedBox(width: 2),
                                  Text(
                                    widget.enigma.difficulty,
                                    style: GoogleFonts.inter(
                                      color: const Color(0xFFB0A07A),
                                      fontSize: 10,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          // Prize
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFFC0A060).withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: const Color(0xFFC0A060).withValues(alpha: 0.15),
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const FaIcon(
                                  FontAwesomeIcons.coins,
                                  size: 10,
                                  color: Color(0xFFC0A060),
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  'R\$ ${currencyFormat.format(widget.enigma.prize).trim()}',
                                  style: GoogleFonts.orbitron(
                                    color: const Color(0xFFF0E6C5),
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 14),
                    // Action / Status
                    Column(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        if (isTemporarilyBlocked)
                          StreamBuilder<String>(
                            stream: _countdownStream(widget.enigma.closedAt!),
                            builder: (context, snapshot) {
                              return Text(
                                snapshot.data ?? "--:--",
                                style: GoogleFonts.inter(
                                  color: statusColor,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 11,
                                  letterSpacing: 0.5,
                                ),
                              );
                            },
                          )
                        else
                          Text(
                            'ABRIR',
                            style: GoogleFonts.inter(
                              color: statusColor,
                              fontWeight: FontWeight.w600,
                              fontSize: 11,
                              letterSpacing: 0.5,
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

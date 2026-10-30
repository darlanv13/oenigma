import 'dart:async';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import 'package:oenigma/core/models/event_model.dart';
import 'package:oenigma/core/models/enigma_model.dart';
import 'package:oenigma/core/models/phase_model.dart';
import 'package:oenigma/core/utils/app_colors.dart';
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
        SnackBar(
          content: const Text('Este baú já foi saqueado e desaparecerá em breve.'),
          backgroundColor: AppColors.danger,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
      statusColor = AppColors.amareloVale;
    } else if (!isClosed) {
      statusColor = AppColors.verdeVale;
    } else {
      statusColor = AppColors.cinzaMedio;
    }

    return GestureDetector(
      onTapDown: (_) => setState(() => _scale = 0.98),
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
            color: AppColors.darkCardColor,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: statusColor.withValues(alpha: 0.35),
              width: 1.2,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.35),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          clipBehavior: Clip.antiAlias,
          child: Stack(
            children: [
              Positioned.fill(
                child: CustomPaint(
                  painter: MapDotsPainter(
                    dotColor: AppColors.verdeVale.withValues(alpha: 0.08),
                  ),
                ),
              ),
              Container(
                decoration: BoxDecoration(
                  border: Border(
                    left: BorderSide(color: statusColor, width: 4),
                  ),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 14.0),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Icon Container
                    Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: statusColor.withValues(alpha: 0.1),
                        border: Border.all(
                          color: statusColor.withValues(alpha: 0.2),
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
                                  style: GoogleFonts.poppins(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 14,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: statusColor.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: statusColor.withValues(alpha: 0.3),
                                  ),
                                ),
                                child: Text(
                                  isTemporarilyBlocked ? 'CONCLUÍDO' : 'DISPONÍVEL',
                                  style: GoogleFonts.inter(
                                    color: statusColor,
                                    fontSize: 9,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 3),
                          // Desc & Difficulty
                          Row(
                            children: [
                              Flexible(
                                child: Text(
                                  widget.enigma.instruction.isNotEmpty ? widget.enigma.instruction : 'Encontre a resposta',
                                  style: GoogleFonts.inter(
                                    color: AppColors.cinzaMedio,
                                    fontSize: 12,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const FaIcon(
                                    FontAwesomeIcons.star,
                                    size: 9,
                                    color: AppColors.amareloVale,
                                  ),
                                  const SizedBox(width: 3),
                                  Text(
                                    widget.enigma.difficulty,
                                    style: GoogleFonts.inter(
                                      color: AppColors.cinzaMedio,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          // Prize
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                            decoration: BoxDecoration(
                              color: AppColors.amareloValeLight,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: AppColors.amareloVale.withValues(alpha: 0.25),
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const FaIcon(
                                  FontAwesomeIcons.coins,
                                  size: 10,
                                  color: AppColors.amareloVale,
                                ),
                                const SizedBox(width: 5),
                                Text(
                                  'R\$ ${currencyFormat.format(widget.enigma.prize).trim()}',
                                  style: GoogleFonts.poppins(
                                    color: AppColors.amareloVale,
                                    fontWeight: FontWeight.w800,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Action / Status
                    Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (isTemporarilyBlocked)
                          StreamBuilder<String>(
                            stream: _countdownStream(widget.enigma.closedAt!),
                            builder: (context, snapshot) {
                              return Text(
                                snapshot.data ?? "--:--",
                                style: GoogleFonts.poppins(
                                  color: statusColor,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 12,
                                  letterSpacing: 0.5,
                                ),
                              );
                            },
                          )
                        else
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                            decoration: BoxDecoration(
                              gradient: AppColors.gradienteVerdeVale,
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.verdeVale.withValues(alpha: 0.35),
                                  blurRadius: 6,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Text(
                              'ABRIR',
                              style: GoogleFonts.poppins(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                                fontSize: 11,
                                letterSpacing: 0.5,
                              ),
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

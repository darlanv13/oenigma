import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'package:lottie/lottie.dart';
import 'package:oenigma/app_cliente/core/models/event_model.dart';
import '../screens/event_details_screen.dart';
import 'package:oenigma/app_cliente/core/utils/app_colors.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_fonts/google_fonts.dart';

class EventCard extends StatefulWidget {
  final EventModel event;
  final Map<String, dynamic> playerData;
  final VoidCallback onReturn;

  const EventCard({
    super.key,
    required this.event,
    required this.playerData,
    required this.onReturn,
  });

  @override
  State<EventCard> createState() => _EventCardState();
}

class _EventCardState extends State<EventCard> {
  double _scale = 1.0;

  String _formatDate(String dateStr) {
    try {
      final date = DateFormat('dd/MM/yyyy').parse(dateStr);
      return DateFormat("d 'de' MMM", 'pt_BR').format(date);
    } catch (e) {
      return dateStr;
    }
  }

  Future<void> _handleTap() async {
    setState(() => _scale = 1.0);
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EventDetailsScreen(
          event: widget.event,
          playerData: widget.playerData,
        ),
      ),
    );
    widget.onReturn();
  }

  @override
  Widget build(BuildContext context) {
    // Determina o tipo de evento para o título estilizado
    final isFindAndWin = widget.event.eventType == 'find_and_win';
    final eventTitle = isFindAndWin ? "Ache & Ganhe" : "Modo Clássico";

    return GestureDetector(
      onTapDown: (_) => setState(() => _scale = 0.97),
      onTapUp: (_) => _handleTap(),
      onTapCancel: () => setState(() => _scale = 1.0),
      child: AnimatedScale(
        scale: _scale,
        duration: const Duration(milliseconds: 150),
        curve: Curves.easeOut,
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: const Color.fromRGBO(22, 24, 28, 0.85),
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.5),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: Stack(
              fit: StackFit.expand,
              children: [
                // Fundo com Mapa (.map-bg and .map-svg)
                Positioned.fill(
                  child: CustomPaint(
                    painter: _MapBackgroundPainter(),
                  ),
                ),

                // PAINEL (Textos e Botão)
                Positioned.fill(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Prêmio e Status (.prize-row)
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.baseline,
                              textBaseline: TextBaseline.alphabetic,
                              children: [
                                const FaIcon(
                                  FontAwesomeIcons.coins,
                                  color: Color(0xFFC0A060),
                                  size: 19.2, // 1.2rem
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  widget.event.prize.replaceAll(
                                    'R\$ ',
                                    'R\$ ', // Add space as per CSS
                                  ),
                                  style: GoogleFonts.orbitron(
                                    fontSize: 28.8, // 1.8rem
                                    fontWeight: FontWeight.w800,
                                    color: const Color(0xFFF0E6C5),
                                    letterSpacing: -0.5,
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
                                color: const Color(0xFFC0A060).withValues(alpha: 0.18),
                                borderRadius: BorderRadius.circular(30),
                                border: Border.all(
                                  color: const Color(0xFFC0A060).withValues(alpha: 0.25),
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  FaIcon(
                                    widget.event.status == 'dev' ? FontAwesomeIcons.clock : FontAwesomeIcons.mapPin,
                                    color: const Color(0xFFC0A060),
                                    size: 10,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    widget.event.status == 'dev' ? 'NOVO' : 'ATIVO',
                                    style: const TextStyle(
                                      color: Color(0xFFC0A060),
                                      fontSize: 10.4, // 0.65rem
                                      fontWeight: FontWeight.w600,
                                      letterSpacing: 0.5,
                                      fontFamily: 'Inter',
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),

                        // Título do Evento (.hunt-name)
                        Text(
                          eventTitle,
                          style: const TextStyle(
                            fontSize: 16, // 1rem
                            fontWeight: FontWeight.w600,
                            color: Color(0xFFF0E6C5),
                            fontFamily: 'Inter',
                          ),
                        ),
                        const SizedBox(height: 6),

                        // Localização (.hunt-location)
                        Row(
                          children: [
                            const FaIcon(
                              FontAwesomeIcons.locationDot,
                              color: Color(0xFFC0A060),
                              size: 11.2, // 0.7rem
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                widget.event.location.isNotEmpty &&
                                        widget.event.location !=
                                            'Local não definido'
                                    ? widget.event.location
                                    : _formatDate(widget.event.startDate),
                                style: const TextStyle(
                                  color: Color(0xFFB0A07A),
                                  fontSize: 12.8, // 0.8rem
                                  fontFamily: 'Inter',
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),

                        // Dificuldade (.difficulty)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.04),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: const Color(0xFFC0A060).withValues(alpha: 0.10),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: const [
                              FaIcon(
                                FontAwesomeIcons.star,
                                color: Color(0xFFC0A060),
                                size: 10,
                              ),
                              SizedBox(width: 8),
                              Text(
                                'Dificuldade: Média',
                                style: TextStyle(
                                  color: Color(0xFF8A7A5A),
                                  fontSize: 11.2, // 0.7rem
                                  fontFamily: 'Inter',
                                ),
                              ),
                            ],
                          ),
                        ),

                        const Spacer(),

                        // BOTÃO (.free-entry .btn-free)
                        Container(
                          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                          decoration: BoxDecoration(
                            color: Colors.transparent,
                            borderRadius: BorderRadius.circular(40),
                            border: Border.all(
                              color: const Color(0xFFC0A060),
                              width: 1.5,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFFC0A060).withValues(alpha: 0.15),
                                blurRadius: 12,
                              ),
                            ]
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const FaIcon(
                                FontAwesomeIcons.ticket,
                                color: Color(0xFFC0A060),
                                size: 14,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                widget.event.price == 0
                                    ? "ENTRADA GRÁTIS"
                                    : "INSCRIÇÃO: R\$ ${widget.event.price.toStringAsFixed(2).replaceAll('.', ',')}",
                                style: GoogleFonts.orbitron(
                                  color: const Color(0xFFF0E6C5),
                                  fontSize: 12.8, // 0.8rem
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: 1.0,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Overlays de Status (Finalizado/Em Breve) mantidos inalterados
                if (widget.event.status == 'closed')
                  _buildFinishedOverlay(context, widget.event),
                if (widget.event.status == 'dev') _buildComingSoonOverlay(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFinishedOverlay(BuildContext context, EventModel event) {
    final String winnerFirstName = event.winnerName?.split(' ').first ?? '';
    return Positioned.fill(
      child: Container(
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.75),
          borderRadius: BorderRadius.circular(24),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Lottie.asset('assets/animations/trofel.json', height: 90),
            const SizedBox(height: 12),
            const Text(
              'FINALIZADO',
              style: TextStyle(
                color: primaryAmber,
                fontWeight: FontWeight.w900,
                fontSize: 22,
                letterSpacing: 3,
              ),
            ),
            const SizedBox(height: 16),
            if (winnerFirstName.isNotEmpty)
              Column(
                children: [
                  const Text(
                    "Vencedor",
                    style: TextStyle(
                      color: secondaryTextColor,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircleAvatar(
                        radius: 18,
                        backgroundColor: darkBackground,
                        backgroundImage: event.winnerPhotoURL != null
                            ? NetworkImage(event.winnerPhotoURL!)
                            : null,
                        child: event.winnerPhotoURL == null
                            ? const FaIcon(
                                FontAwesomeIcons.solidUser,
                                size: 18,
                                color: secondaryTextColor,
                              )
                            : null,
                      ),
                      const SizedBox(width: 10),
                      Text(
                        winnerFirstName,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildComingSoonOverlay() {
    return Positioned.fill(
      child: Container(
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.8),
          borderRadius: BorderRadius.circular(24),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.08),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.1),
                  ),
                ),
                child: const FaIcon(
                  FontAwesomeIcons.hourglassHalf,
                  color: primaryAmber,
                  size: 40,
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'EM BREVE',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                  fontSize: 24,
                  letterSpacing: 6,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MapBackgroundPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFC0A060).withValues(alpha: 0.12)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.8;

    // First dashed path
    final path1 = Path();
    path1.moveTo(size.width * 0.05, size.height * 0.9);
    path1.quadraticBezierTo(size.width * 0.2, size.height * 0.7, size.width * 0.35, size.height * 0.85);
    path1.quadraticBezierTo(size.width * 0.6, size.height * 0.6, size.width * 0.6, size.height * 0.6);
    path1.quadraticBezierTo(size.width * 0.85, size.height * 0.75, size.width * 0.85, size.height * 0.75);
    path1.quadraticBezierTo(size.width * 0.95, size.height * 0.5, size.width * 0.95, size.height * 0.5);

    // Second dashed path
    final path2 = Path();
    path2.moveTo(size.width * 0.1, size.height * 0.1);
    path2.quadraticBezierTo(size.width * 0.3, size.height * 0.25, size.width * 0.45, size.height * 0.15);
    path2.quadraticBezierTo(size.width * 0.7, size.height * 0.35, size.width * 0.7, size.height * 0.35);
    path2.quadraticBezierTo(size.width * 0.9, size.height * 0.2, size.width * 0.9, size.height * 0.2);

    _drawDashedPath(canvas, path1, paint);
    _drawDashedPath(canvas, path2, paint..color = const Color(0xFFC0A060).withValues(alpha: 0.10));

    final circlePaint = Paint()
      ..color = const Color(0xFFC0A060).withValues(alpha: 0.10)
      ..style = PaintingStyle.fill;

    // Draw points
    final points = [
      Offset(size.width * 0.25, size.height * 0.75),
      Offset(size.width * 0.5, size.height * 0.5),
      Offset(size.width * 0.8, size.height * 0.65),
      Offset(size.width * 0.9, size.height * 0.3),
      Offset(size.width * 0.1, size.height * 0.2),
    ];

    for (var point in points) {
      canvas.drawCircle(point, 1.5, circlePaint);
    }
  }

  void _drawDashedPath(Canvas canvas, Path path, Paint paint) {

    // Simplification of dashed path logic since dart:ui PathMetrics isn't imported here by default and we want a simple approach
    // In a real app we'd use path_drawing package or extract path metrics, for now just drawing the continuous path.
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

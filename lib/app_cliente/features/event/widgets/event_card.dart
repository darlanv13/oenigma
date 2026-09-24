import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'package:lottie/lottie.dart';
import 'package:oenigma/core/models/event_model.dart';
import '../screens/event_details_screen.dart';
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
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(32),
            boxShadow: [
              const BoxShadow(
                color: Color(0xFFFFFFFF),
                blurRadius: 12,
                offset: Offset(-4, -4),
              ),
              BoxShadow(
                color: const Color(0xFFCBD5E1).withValues(alpha: 0.8),
                blurRadius: 12,
                offset: const Offset(6, 6),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(32),
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
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
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
                                  color: Color(0xFFF59E0B),
                                  size: 20, // 1.25rem
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  widget.event.prize.replaceAll(
                                    'R\$ ',
                                    'R\$ ', // Add space as per CSS
                                  ),
                                  style: GoogleFonts.poppins(
                                    fontSize: 28, // 1.75rem
                                    fontWeight: FontWeight.w800,
                                    color: const Color(0xFF1E293B),
                                    letterSpacing: -0.5,
                                  ),
                                ),
                              ],
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: widget.event.status == 'dev' ? const Color(0xFFFDE047) : const Color(0xFF86EFAC),
                                borderRadius: BorderRadius.circular(30),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  FaIcon(
                                    widget.event.status == 'dev' ? FontAwesomeIcons.clock : FontAwesomeIcons.mapPin,
                                    color: widget.event.status == 'dev' ? const Color(0xFFA16207) : const Color(0xFF166534),
                                    size: 10,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    widget.event.status == 'dev' ? 'NOVO' : 'ATIVO',
                                    style: TextStyle(
                                      color: widget.event.status == 'dev' ? const Color(0xFFA16207) : const Color(0xFF166534),
                                      fontSize: 10,
                                      fontWeight: FontWeight.w700,
                                      letterSpacing: 0.5,
                                      fontFamily: 'Inter',
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),

                        // Título do Evento (.hunt-name)
                        Text(
                          eventTitle,
                          style: GoogleFonts.poppins(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF334155),
                          ),
                        ),
                        const SizedBox(height: 4),

                        // Localização (.hunt-location)
                        Row(
                          children: [
                            const FaIcon(
                              FontAwesomeIcons.locationDot,
                              color: Color(0xFF3B82F6),
                              size: 12,
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                widget.event.location.isNotEmpty &&
                                        widget.event.location !=
                                            'Local não definido'
                                    ? widget.event.location
                                    : _formatDate(widget.event.startDate),
                                style: const TextStyle(
                                  color: Color(0xFF64748B),
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                  fontFamily: 'Inter',
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),

                        // Dificuldade (.difficulty)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: const [
                              FaIcon(
                                FontAwesomeIcons.star,
                                color: Color(0xFFF59E0B),
                                size: 10,
                              ),
                              SizedBox(width: 8),
                              Text(
                                'Dificuldade: Média',
                                style: TextStyle(
                                  color: Color(0xFF475569),
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  fontFamily: 'Inter',
                                ),
                              ),
                            ],
                          ),
                        ),

                        const Spacer(),

                        // BOTÃO (.free-entry .btn-free)
                        Container(
                          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                          decoration: BoxDecoration(
                            color: const Color(0xFF3B82F6),
                            borderRadius: BorderRadius.circular(40),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF3B82F6).withValues(alpha: 0.3),
                                blurRadius: 12,
                                offset: const Offset(0, 4),
                              ),
                            ]
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const FaIcon(
                                FontAwesomeIcons.ticket,
                                color: Colors.white,
                                size: 14,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                widget.event.price == 0
                                    ? "ENTRADA GRÁTIS"
                                    : "INSCRIÇÃO: R\$ ${widget.event.price.toStringAsFixed(2).replaceAll('.', ',')}",
                                style: GoogleFonts.poppins(
                                  color: Colors.white,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
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
          color: Colors.white.withValues(alpha: 0.85),
          borderRadius: BorderRadius.circular(32),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Lottie.asset('assets/animations/trofel.json', height: 90),
            const SizedBox(height: 12),
            Text(
              'FINALIZADO',
              style: GoogleFonts.poppins(
                color: const Color(0xFF1E293B),
                fontWeight: FontWeight.w900,
                fontSize: 24,
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
                      color: Color(0xFF64748B),
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircleAvatar(
                        radius: 18,
                        backgroundColor: const Color(0xFFF1F5F9),
                        backgroundImage: event.winnerPhotoURL != null
                            ? NetworkImage(event.winnerPhotoURL!)
                            : null,
                        child: event.winnerPhotoURL == null
                            ? const FaIcon(
                                FontAwesomeIcons.solidUser,
                                size: 18,
                                color: Color(0xFF94A3B8),
                              )
                            : null,
                      ),
                      const SizedBox(width: 10),
                      Text(
                        winnerFirstName,
                        style: GoogleFonts.poppins(
                          color: const Color(0xFF334155),
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
          color: Colors.white.withValues(alpha: 0.85),
          borderRadius: BorderRadius.circular(32),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFFFDE047).withValues(alpha: 0.2),
                ),
                child: const FaIcon(
                  FontAwesomeIcons.hourglassHalf,
                  color: Color(0xFFEAB308),
                  size: 40,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'EM BREVE',
                style: GoogleFonts.poppins(
                  color: const Color(0xFF1E293B),
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
    // Pastel blob 1
    final blobPaint1 = Paint()
      ..color = const Color(0xFFFEF3C7).withValues(alpha: 0.6) // soft pastel yellow
      ..style = PaintingStyle.fill;

    final path1 = Path();
    path1.moveTo(size.width * 0.1, size.height * 0.2);
    path1.quadraticBezierTo(size.width * 0.4, size.height * 0.1, size.width * 0.3, size.height * 0.4);
    path1.quadraticBezierTo(size.width * 0.2, size.height * 0.7, size.width * -0.1, size.height * 0.5);
    path1.close();
    canvas.drawPath(path1, blobPaint1);

    // Pastel blob 2
    final blobPaint2 = Paint()
      ..color = const Color(0xFFE0E7FF).withValues(alpha: 0.6) // soft pastel blue
      ..style = PaintingStyle.fill;

    final path2 = Path();
    path2.moveTo(size.width * 0.8, size.height * 0.6);
    path2.quadraticBezierTo(size.width * 1.0, size.height * 0.5, size.width * 1.1, size.height * 0.8);
    path2.quadraticBezierTo(size.width * 1.0, size.height * 1.1, size.width * 0.7, size.height * 0.9);
    path2.close();
    canvas.drawPath(path2, blobPaint2);

    // Small pastel dots (Memphis style)
    final dotPaint = Paint()
      ..color = const Color(0xFFFBCFE8) // soft pastel pink
      ..style = PaintingStyle.fill;

    canvas.drawCircle(Offset(size.width * 0.8, size.height * 0.2), 6, dotPaint);
    canvas.drawCircle(Offset(size.width * 0.4, size.height * 0.8), 4, dotPaint);

    final crossPaint = Paint()
      ..color = const Color(0xFFC7D2FE) // soft indigo
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    final cx = size.width * 0.2;
    final cy = size.height * 0.85;
    canvas.drawLine(Offset(cx - 5, cy), Offset(cx + 5, cy), crossPaint);
    canvas.drawLine(Offset(cx, cy - 5), Offset(cx, cy + 5), crossPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

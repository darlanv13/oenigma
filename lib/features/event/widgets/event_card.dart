import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'package:lottie/lottie.dart';
import 'package:oenigma/core/models/event_model.dart';
import '../screens/event_details_screen.dart';
import 'package:oenigma/core/utils/app_colors.dart';
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
      onTapDown: (_) => setState(() => _scale = 0.96),
      onTapUp: (_) => _handleTap(),
      onTapCancel: () => setState(() => _scale = 1.0),
      child: AnimatedScale(
        scale: _scale,
        duration: const Duration(milliseconds: 150),
        curve: Curves.easeInOut,
        child: Container(
          decoration: BoxDecoration(
            color: const Color(
              0xFF1E1E1E,
            ), // Fundo escuro base (igual ao HomeProfileCard)
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: const Color(0xFFD6B570).withValues(alpha: 0.3),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.3),
                blurRadius: 15,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: Stack(
              fit: StackFit.expand,
              children: [
                // PAINEL (Textos e Botão)
                Positioned.fill(
                  child: Container(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Prêmio e Status
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                const FaIcon(
                                  FontAwesomeIcons.coins,
                                  color: Color(0xFFD6B570),
                                  size: 24,
                                ),
                                const SizedBox(width: 12),
                                Text(
                                  widget.event.prize.replaceAll(
                                    'R\$ ',
                                    'R\$',
                                  ), // Remove space if any
                                  style: GoogleFonts.orbitron(
                                    fontSize: 32,
                                    fontWeight: FontWeight.w900,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(
                                  0xFFD6B570,
                                ).withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: const Color(
                                    0xFFD6B570,
                                  ).withValues(alpha: 0.3),
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: const [
                                  FaIcon(
                                    FontAwesomeIcons.mapPin,
                                    color: Color(0xFFD6B570),
                                    size: 12,
                                  ),
                                  SizedBox(width: 6),
                                  Text(
                                    'ATIVO',
                                    style: TextStyle(
                                      color: Color(0xFFD6B570),
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 1.0,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),

                        // Título do Evento
                        Text(
                          eventTitle,
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 8),

                        // Localização
                        Row(
                          children: [
                            const FaIcon(
                              FontAwesomeIcons.locationDot,
                              color: Color(0xFFD6B570),
                              size: 14,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                widget.event.location.isNotEmpty &&
                                        widget.event.location !=
                                            'Local não definido'
                                    ? widget.event.location
                                    : _formatDate(widget.event.startDate),
                                style: const TextStyle(
                                  color: Color(0xFFD6B570),
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),

                        // Dificuldade
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.05),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.1),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: const [
                              FaIcon(
                                FontAwesomeIcons.star,
                                color: Color(0xFFD6B570),
                                size: 14,
                              ),
                              SizedBox(width: 8),
                              Text(
                                'Dificuldade: Média',
                                style: TextStyle(
                                  color: Colors.grey,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),

                        const Spacer(),

                        // BOTÃO
                        Container(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          decoration: BoxDecoration(
                            color: Colors.transparent,
                            borderRadius: BorderRadius.circular(30),
                            border: Border.all(
                              color: const Color(0xFFD6B570),
                              width: 1.5,
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const FaIcon(
                                FontAwesomeIcons.ticket,
                                color: Color(0xFFD6B570),
                                size: 18,
                              ),
                              const SizedBox(width: 12),
                              Text(
                                widget.event.price == 0
                                    ? "ENTRADA GRÁTIS"
                                    : "INSCRIÇÃO: R\$ ${widget.event.price.toStringAsFixed(2).replaceAll('.', ',')}",
                                style: GoogleFonts.orbitron(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 1.5,
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

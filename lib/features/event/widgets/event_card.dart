import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'dart:ui';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:lottie/lottie.dart'; // Mantido caso o lottie do overlay em baixo use
import 'package:oenigma/core/models/event_model.dart';
import '../screens/event_details_screen.dart';
import 'package:oenigma/core/utils/app_colors.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

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
  String _formatDate(String dateStr) {
    try {
      final date = DateFormat('dd/MM/yyyy').parse(dateStr);
      return DateFormat("d 'de' MMM", 'pt_BR').format(date);
    } catch (e) {
      return dateStr;
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () async {
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
      },
      child: Container(
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.3),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Imagem de Fundo
              Positioned.fill(
                child: Container(
                  color: darkBackground,
                  child: widget.event.icon.isNotEmpty
                      ? CachedNetworkImage(
                          imageUrl: widget.event.icon,
                          fit: BoxFit.cover,
                          placeholder: (context, url) => const Center(
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: primaryAmber,
                            ),
                          ),
                          errorWidget: (context, url, error) => const Center(
                            child: FaIcon(
                              FontAwesomeIcons.image,
                              color: secondaryTextColor,
                              size: 40,
                            ),
                          ),
                        )
                      : const Center(
                          child: FaIcon(
                            FontAwesomeIcons.image,
                            color: secondaryTextColor,
                            size: 40,
                          ),
                        ),
                ),
              ),

              // Gradiente escurecedor para leitura
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.black.withValues(alpha: 0.9),
                        Colors.black.withValues(alpha: 0.1),
                        Colors.black.withValues(
                          alpha: 0.3,
                        ), // Topo ligeiramente escuro para o badge
                      ],
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                      stops: const [0.0, 0.5, 1.0],
                    ),
                  ),
                ),
              ),

              // DESTAQUE DO PRÊMIO (O que brilha na tela)
              Positioned(
                top: 12,
                left: 12,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [primaryAmber, Color(0xFFFFD54F)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: primaryAmber.withValues(alpha: 0.5),
                        blurRadius: 12,
                        offset: const Offset(0, 2),
                      ),
                    ],
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const FaIcon(
                        FontAwesomeIcons.gift,
                        color: darkBackground,
                        size: 14,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        widget.event.prize,
                        style: const TextStyle(
                          color: darkBackground,
                          fontWeight: FontWeight.w900,
                          fontSize: 16,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Informações do Evento (Bottom)
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(20),
                  ),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.5),
                        border: Border(
                          top: BorderSide(
                            color: Colors.white.withValues(alpha: 0.1),
                          ),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.event.name,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w900,
                              color: Colors.white,
                              letterSpacing: 0.5,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              const FaIcon(
                                FontAwesomeIcons.locationDot,
                                color: secondaryTextColor,
                                size: 10,
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
                                    color: secondaryTextColor,
                                    fontSize: 12,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          // Botão virtual / Status de Inscrição
                          Container(
                            padding: const EdgeInsets.symmetric(vertical: 6),
                            decoration: BoxDecoration(
                              color: widget.event.price == 0
                                  ? Colors.green.withValues(alpha: 0.2)
                                  : primaryAmber.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: widget.event.price == 0
                                    ? Colors.green.withValues(alpha: 0.5)
                                    : primaryAmber.withValues(alpha: 0.3),
                              ),
                            ),
                            child: Center(
                              child: Text(
                                widget.event.price == 0
                                    ? "ENTRADA GRÁTIS"
                                    : "INSCRIÇÃO: R\$ ${widget.event.price.toStringAsFixed(2).replaceAll('.', ',')}",
                                style: TextStyle(
                                  color: widget.event.price == 0
                                      ? Colors.greenAccent
                                      : primaryAmber,
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 1.0,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              // Overlays de Status (Finalizado/Em Breve)
              if (widget.event.status == 'closed')
                _buildFinishedOverlay(context, widget.event),
              if (widget.event.status == 'dev') _buildComingSoonOverlay(),
            ],
          ),
        ),
      ),
    );
  }

  // Mantidos iguais os métodos _buildFinishedOverlay e _buildComingSoonOverlay...
  Widget _buildFinishedOverlay(BuildContext context, EventModel event) {
    final String winnerFirstName = event.winnerName?.split(' ').first ?? '';
    return Positioned.fill(
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 4, sigmaY: 4),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.6),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Lottie.asset('assets/animations/trofel.json', height: 80),
                const SizedBox(height: 8),
                const Text(
                  'FINALIZADO',
                  style: TextStyle(
                    color: primaryAmber,
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                    letterSpacing: 2,
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
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          CircleAvatar(
                            radius: 16,
                            backgroundColor: darkBackground,
                            backgroundImage: event.winnerPhotoURL != null
                                ? NetworkImage(event.winnerPhotoURL!)
                                : null,
                            child: event.winnerPhotoURL == null
                                ? const FaIcon(
                                    FontAwesomeIcons.solidUser,
                                    size: 16,
                                  )
                                : null,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            winnerFirstName,
                            style: const TextStyle(
                              color: textColor,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildComingSoonOverlay() {
    return Positioned.fill(
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.7),
            ),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withValues(alpha: 0.05),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.white.withValues(alpha: 0.05),
                          blurRadius: 15,
                        ),
                      ],
                    ),
                    child: const FaIcon(
                      FontAwesomeIcons.hourglassHalf,
                      color: Colors.white70,
                      size: 40,
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'EM BREVE',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                      fontSize: 22,
                      letterSpacing: 4,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:lottie/lottie.dart';
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
            color: const Color(0xFF121212), // Fundo escuro base
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.1),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.5),
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
                // 1. IMAGEM DE FUNDO
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  bottom: 120, // Deixa espaço para o painel inferior
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
                      : Container(color: Colors.grey.shade900),
                ),

                // Gradiente escurecedor para mesclar a imagem com o fundo
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          const Color(0xFF1A1A1A).withValues(alpha: 0.9),
                          Colors.transparent,
                        ],
                        begin: Alignment.bottomCenter,
                        end: Alignment.center,
                      ),
                    ),
                  ),
                ),

                // 3. BADGE SUPERIOR ESQUERDO (Prêmio Secundário/Fixo)
                Positioned(
                  top: 16,
                  left: 16,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFFFFD54F), Color(0xFFF57F17)],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.3),
                          blurRadius: 5,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const FaIcon(
                          FontAwesomeIcons.gift,
                          color: Colors.black,
                          size: 14,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          widget.event.prize,
                          style: const TextStyle(
                            color: Colors.black,
                            fontWeight: FontWeight.w900,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // 4. BADGE SUPERIOR DIREITO (Prêmio Principal - Medalha)
                Positioned(
                  top: 0,
                  right: 20,
                  child: SizedBox(
                    width: 80,
                    height: 100,
                    // Se você tiver o asset da medalha vermelha, use Stack com Image.asset
                    child: Stack(
                      alignment: Alignment.topCenter,
                      children: [
                        // Representação visual da fita/medalha
                        Container(
                          width: 60,
                          height: 90,
                          decoration: const BoxDecoration(
                            color: Color(0xFF6B1A2C), // Vermelho vinho da fita
                            borderRadius: BorderRadius.vertical(
                              bottom: Radius.circular(8),
                            ),
                          ),
                        ),
                        Positioned(
                          top: 10,
                          child: Container(
                            width: 70,
                            height: 70,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: const RadialGradient(
                                colors: [Color(0xFF8B233C), Color(0xFF4A101C)],
                              ),
                              border: Border.all(
                                color: const Color(0xFFFFD54F),
                                width: 3,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.5),
                                  blurRadius: 5,
                                  offset: const Offset(0, 3),
                                ),
                              ],
                            ),
                            child: Center(
                              child: Text(
                                widget.event.prize.replaceAll('R\$', 'R\$\n'),
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  color: Color(0xFFFFD54F),
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                  height: 1.1,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // 5. PAINEL INFERIOR (Textos e Botão)
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: Container(
                    padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
                    decoration: const BoxDecoration(
                      color: Color(0xFF1E1E1E), // Cor sólida idêntica à imagem
                      borderRadius: BorderRadius.vertical(
                        top: Radius.circular(24),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Título Dourado (Modo)
                        Text(
                          eventTitle,
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w900,
                            color: Color(0xFFFFD54F), // Dourado
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(height: 2),
                        // Subtítulo (Nome do Evento)
                        Text(
                          widget.event.name,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            color: Colors.white,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 6),
                        // Localização
                        Row(
                          children: [
                            const FaIcon(
                              FontAwesomeIcons.locationDot,
                              color: Colors.grey,
                              size: 14,
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
                                  color: Colors.grey,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        // Dificuldade
                        RichText(
                          text: const TextSpan(
                            style: TextStyle(fontSize: 14, color: Colors.grey),
                            children: [
                              TextSpan(text: 'Dificuldade: '),
                              TextSpan(
                                text:
                                    'Média', // Pode ser dinamizado futuramente
                                style: TextStyle(
                                  color: Color(0xFFFFD54F),
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),

                        // 6. BOTÃO NEON VERDE
                        Container(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: widget.event.price == 0
                                  ? [
                                      const Color(0xFF4CAF50),
                                      const Color(0xFF2E7D32),
                                    ]
                                  : [
                                      const Color(0xFFFFD54F),
                                      const Color(0xFFF57F17),
                                    ],
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                            ),
                            borderRadius: BorderRadius.circular(30),
                            border: Border.all(
                              color: widget.event.price == 0
                                  ? Colors.greenAccent.withValues(alpha: 0.5)
                                  : Colors.orangeAccent.withValues(alpha: 0.5),
                              width: 2,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: widget.event.price == 0
                                    ? Colors.green.withValues(alpha: 0.4)
                                    : primaryAmber.withValues(alpha: 0.4),
                                blurRadius: 15,
                                spreadRadius: 1,
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                widget.event.price == 0
                                    ? "ENTRADA GRÁTIS"
                                    : "INSCRIÇÃO: R\$ ${widget.event.price.toStringAsFixed(2).replaceAll('.', ',')}",
                                style: const TextStyle(
                                  color: Colors
                                      .black, // Texto escuro para contraste
                                  fontSize: 14,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 1.0,
                                ),
                              ),
                              if (widget.event.price == 0) ...[
                                const SizedBox(width: 8),
                                const FaIcon(
                                  FontAwesomeIcons.lockOpen,
                                  color: Colors.black,
                                  size: 14,
                                ),
                              ],
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

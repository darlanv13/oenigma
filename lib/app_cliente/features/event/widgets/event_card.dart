import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lottie/lottie.dart';

import 'package:oenigma/core/models/event_model.dart';
import 'package:oenigma/core/utils/app_colors.dart';
import '../screens/event_details_screen.dart';

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
    final event = widget.event;
    final isClassic = event.eventType == 'classic';
    final isObjeto = event.prizeType == 'objeto';

    // Título do Evento: se for Objeto, assume a modalidade conforme a imagem de referência
    final String displayTitle = isObjeto
        ? (isClassic ? 'Modo Clássico' : 'Ache & Ganhe')
        : (event.name.isNotEmpty ? event.name : (isClassic ? 'Modo Clássico' : 'Ache & Ganhe'));

    // Localização
    final String displayLocation = event.location.isNotEmpty && event.location != 'Local não definido'
        ? event.location
        : 'Canaã Dos Carajás';

    // Dificuldade
    final String displayDifficulty = event.difficulty.isNotEmpty ? event.difficulty : 'Média';

    return GestureDetector(
      onTapDown: (_) => setState(() => _scale = 0.98),
      onTapUp: (_) => _handleTap(),
      onTapCancel: () => setState(() => _scale = 1.0),
      child: AnimatedScale(
        scale: _scale,
        duration: const Duration(milliseconds: 150),
        curve: Curves.easeOut,
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          decoration: BoxDecoration(
            color: const Color(0xFF131D24), // Fundo grafite/ciano escuro idêntico à referência
            borderRadius: BorderRadius.circular(28),
            border: Border.all(
              color: const Color(0xFF1E3A45),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.5),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(28),
            child: Stack(
              children: [
                // CONTEÚDO PRINCIPAL DO CARD
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 1. LINHA DO TOPO: Moedas + Prêmio + Badge de Modalidade (Sem a tag Ativo)
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          // Ícone de moedas empilhadas
                          const FaIcon(
                            FontAwesomeIcons.coins,
                            color: Color(0xFFF3A522),
                            size: 20,
                          ),
                          const SizedBox(width: 8),

                          // Nome do Prêmio (Objeto) ou Valor em Dinheiro
                          Expanded(
                            child: Text(
                              event.prize,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.poppins(
                                fontSize: 21,
                                fontWeight: FontWeight.w900,
                                color: const Color(0xFFF3A522),
                                letterSpacing: -0.3,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),

                          // Pill da Modalidade (CLASSIC / FIND & WIN)
                          _buildHeaderBadge(
                            icon: isClassic ? FontAwesomeIcons.trophy : FontAwesomeIcons.boxOpen,
                            label: isClassic ? 'CLASSIC' : 'FIND & WIN',
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),

                      // 2. MEIO DO CARD: Lado Esquerdo (Informações) e Lado Direito (Showcase do Prêmio)
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          // LADO ESQUERDO: Título, Localização e Dificuldade
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Título do Evento
                                Text(
                                  displayTitle,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: GoogleFonts.poppins(
                                    fontSize: 20,
                                    fontWeight: FontWeight.w800,
                                    color: Colors.white,
                                    height: 1.15,
                                  ),
                                ),
                                const SizedBox(height: 6),

                                // Localização com Pin ciano
                                Row(
                                  children: [
                                    const FaIcon(
                                      FontAwesomeIcons.locationDot,
                                      color: Color(0xFF00A4B4),
                                      size: 13,
                                    ),
                                    const SizedBox(width: 6),
                                    Expanded(
                                      child: Text(
                                        displayLocation,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: GoogleFonts.inter(
                                          color: const Color(0xFF919191),
                                          fontSize: 13,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 10),

                                // Badge de Dificuldade
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 5,
                                  ),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF0C171F),
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(
                                      color: const Color(0xFF1B303A),
                                      width: 1.2,
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const FaIcon(
                                        FontAwesomeIcons.star,
                                        color: Color(0xFFF3A522),
                                        size: 11,
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        'Dificuldade: $displayDifficulty',
                                        style: GoogleFonts.inter(
                                          color: const Color(0xFFD6D6D6),
                                          fontSize: 11.5,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 10),

                          // LADO DIREITO: Showcase do Prêmio (Foto PNG ou Saco de Dinheiro + 1º Lugar + Brilhos)
                          _buildPrizeShowcase(isObjeto, event),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // 3. BASE DO CARD: Botão Cápsula Total
                      Container(
                        width: double.infinity,
                        height: 46,
                        decoration: BoxDecoration(
                          color: AppColors.verdeVale,
                          borderRadius: BorderRadius.circular(28),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.verdeVale.withValues(alpha: 0.35),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
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
                              event.price == 0
                                  ? 'ENTRADA GRÁTIS'
                                  : 'INSCRIÇÃO: R\$ ${event.price.toStringAsFixed(2).replaceAll('.', ',')}',
                              style: GoogleFonts.poppins(
                                color: Colors.white,
                                fontSize: 13,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.8,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // Overlays de Status (Finalizado ou Em Breve)
                if (event.status == 'closed')
                  Positioned.fill(child: _buildFinishedOverlay(context, event)),
                if (event.status == 'dev')
                  Positioned.fill(child: _buildComingSoonOverlay()),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Pílulas superiores (CLASSIC / ATIVO)
  Widget _buildHeaderBadge({required dynamic icon, required String label}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFF0C242C),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFF00A4B4).withValues(alpha: 0.45),
          width: 1.2,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          FaIcon(
            icon,
            size: 9.5,
            color: const Color(0xFF00A4B4),
          ),
          const SizedBox(width: 5),
          Text(
            label,
            style: GoogleFonts.poppins(
              color: const Color(0xFF00A4B4),
              fontSize: 10,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.7,
            ),
          ),
        ],
      ),
    );
  }

  // Showcase do Prêmio com estrelinhas brilhantes e badge de 1º Lugar
  Widget _buildPrizeShowcase(bool isObjeto, EventModel event) {
    return SizedBox(
      width: 125,
      height: 106,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.center,
        children: [
          // 1. Estrela de 4 pontas decorativa amarela (topo direito)
          const Positioned(
            top: 2,
            right: 4,
            child: _SparkleWidget(
              color: Color(0xFFF3A522),
              size: 13,
            ),
          ),

          // 2. Estrela de 4 pontas decorativa ciano (canto inferior esquerdo)
          const Positioned(
            bottom: 18,
            left: 2,
            child: _SparkleWidget(
              color: Color(0xFF00A4B4),
              size: 9,
            ),
          ),

          // 3. Sombra de piso suave abaixo do produto
          Positioned(
            bottom: 10,
            child: Container(
              width: 65,
              height: 8,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.55),
                    blurRadius: 8,
                    spreadRadius: 1,
                  ),
                ],
              ),
            ),
          ),

          // 4. Imagem do Prêmio (Objeto com PNG transparente) ou Saco de Dinheiro
          Positioned(
            top: 0,
            bottom: 12,
            left: 8,
            right: 8,
            child: isObjeto && event.prizeImageUrl != null && event.prizeImageUrl!.isNotEmpty
                ? CachedNetworkImage(
                    imageUrl: (event.prizeImageUrl!.contains('iphone17_PNG39') && event.prizeImageUrl!.contains('back4app.com'))
                        ? 'https://pngimg.com/uploads/iphone17/iphone17_PNG39.png'
                        : event.prizeImageUrl!,
                    fit: BoxFit.contain,
                    placeholder: (context, url) => const Center(
                      child: SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppColors.verdeVale,
                        ),
                      ),
                    ),
                    errorWidget: (context, url, error) => const Center(
                      child: FaIcon(
                        FontAwesomeIcons.gift,
                        color: Color(0xFFF3A522),
                        size: 38,
                      ),
                    ),
                  )
                : const Center(
                    child: FaIcon(
                      FontAwesomeIcons.sackDollar,
                      color: Color(0xFFF3A522),
                      size: 54,
                    ),
                  ),
          ),

          // 5. Badge Dourada "1º LUGAR"
          Positioned(
            bottom: 0,
            right: 2,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [
                    Color(0xFFFFA726),
                    Color(0xFFF57C00),
                  ],
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.4),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Text(
                '1º LUGAR',
                style: GoogleFonts.poppins(
                  color: Colors.black,
                  fontWeight: FontWeight.w900,
                  fontSize: 10,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Overlay para evento finalizado
  Widget _buildFinishedOverlay(BuildContext context, EventModel event) {
    final String winnerFirstName = event.winnerName?.split(' ').first ?? '';
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF131D24).withValues(alpha: 0.94),
        borderRadius: BorderRadius.circular(28),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Lottie.asset('assets/animations/trofel.json', height: 80),
          const SizedBox(height: 6),
          Text(
            'FINALIZADO',
            style: GoogleFonts.poppins(
              color: Colors.white,
              fontWeight: FontWeight.w900,
              fontSize: 20,
              letterSpacing: 3,
            ),
          ),
          if (winnerFirstName.isNotEmpty) ...[
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircleAvatar(
                  radius: 14,
                  backgroundColor: AppColors.verdeValeLight,
                  backgroundImage: event.winnerPhotoURL != null
                      ? NetworkImage(event.winnerPhotoURL!)
                      : null,
                  child: event.winnerPhotoURL == null
                      ? const FaIcon(
                          FontAwesomeIcons.solidUser,
                          size: 12,
                          color: AppColors.verdeVale,
                        )
                      : null,
                ),
                const SizedBox(width: 8),
                Text(
                  'Vencedor: $winnerFirstName',
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  // Overlay para evento em breve
  Widget _buildComingSoonOverlay() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF131D24).withValues(alpha: 0.94),
        borderRadius: BorderRadius.circular(28),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.amareloVale.withValues(alpha: 0.2),
              ),
              child: const FaIcon(
                FontAwesomeIcons.hourglassHalf,
                color: AppColors.amareloVale,
                size: 32,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'EM BREVE',
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontWeight: FontWeight.w900,
                fontSize: 20,
                letterSpacing: 4,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Widget de estrelas decorativas de 4 pontas afiadas
class _SparkleWidget extends StatelessWidget {
  final Color color;
  final double size;

  const _SparkleWidget({required this.color, required this.size});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(size, size),
      painter: _SparklePainter(color: color),
    );
  }
}

class _SparklePainter extends CustomPainter {
  final Color color;
  _SparklePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    final path = Path();
    final cx = size.width / 2;
    final cy = size.height / 2;
    final w = size.width;
    final h = size.height;
    const waist = 0.16; // afunilamento central preciso

    path.moveTo(cx, 0);
    path.quadraticBezierTo(cx, cy * (1 - waist), cx + (w / 2) * waist, cy);
    path.quadraticBezierTo(cx + (w / 2) * (1 - waist), cy, w, cy);
    path.quadraticBezierTo(cx + (w / 2) * waist, cy, cx, cy + (h / 2) * waist);
    path.quadraticBezierTo(cx, cy + (h / 2) * (1 - waist), cx, h);
    path.quadraticBezierTo(cx, cy + (h / 2) * waist, cx - (w / 2) * waist, cy);
    path.quadraticBezierTo(cx - (w / 2) * (1 - waist), cy, 0, cy);
    path.quadraticBezierTo(cx - (w / 2) * waist, cy, cx, cy * (1 - waist));
    path.close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

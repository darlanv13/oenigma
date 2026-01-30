import 'package:cached_network_image/cached_network_image.dart'; // NOVO IMPORT
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'dart:ui';
import 'package:lottie/lottie.dart';
import 'package:shimmer/shimmer.dart'; // NOVO IMPORT
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:oenigma/models/event_model.dart';
import 'package:oenigma/utils/app_colors.dart';
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
  // LottieComposition não é mais tão crítico para cache se usarmos o próprio Lottie.asset com frameBuilder
  // mas mantive a lógica original, apenas otimizando a UI.
  late final Future<LottieComposition> _composition;

  @override
  void initState() {
    super.initState();
    if (widget.event.icon.isNotEmpty &&
        Uri.tryParse(widget.event.icon)?.isAbsolute == true) {
      _composition = NetworkLottie(widget.event.icon).load();
    } else {
      _composition = AssetLottie('assets/animations/no_enigma.json').load();
    }
  }

  String _formatDate(String dateStr) {
    try {
      final date = DateFormat('dd/MM/yyyy').parse(dateStr);
      return DateFormat("d 'de' MMMM", 'pt_BR').format(date);
    } catch (e) {
      return dateStr;
    }
  }

  // Widget para Skeleton Loading
  Widget _buildShimmerLoading() {
    return Shimmer.fromColors(
      baseColor: Colors.grey[800]!,
      highlightColor: Colors.grey[600]!,
      child: Container(color: Colors.black),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 260, // Altura fixa para evitar erro de layout em listas (SliverList)
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(24),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
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
          splashColor: primaryAmber.withOpacity(0.2),
          highlightColor: primaryAmber.withOpacity(0.1),
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Design base do card
              Positioned.fill(
                child: Container(
                  color: darkBackground,
                  child: widget.event.icon.isNotEmpty
                      ? FutureBuilder<LottieComposition>(
                          future: _composition,
                          builder: (context, snapshot) {
                            if (snapshot.hasData) {
                              return Lottie(
                                composition: snapshot.data!,
                                fit: BoxFit.scaleDown,
                              );
                            }
                            // Usando Shimmer enquanto carrega
                            return _buildShimmerLoading();
                          },
                        )
                      : const SizedBox(),
                ),
              ),
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.black.withOpacity(0.8),
                        Colors.black.withOpacity(0.2),
                        Colors.transparent,
                      ],
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                      stops: const [0.0, 0.6, 1.0],
                    ),
                  ),
                ),
              ),
              // ... (Preço e labels mantidos igual) ...
              Positioned(
                top: 12,
                left: 12,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: primaryAmber,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.3),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Text(
                    widget.event.prize,
                    style: const TextStyle(
                      color: darkBackground,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Column(
                  children: [
                    ClipRRect(
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(15),
                      ),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.25),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                widget.event.name,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: textColor,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  const FaIcon(
                                    FontAwesomeIcons.calendarDay,
                                    color: secondaryTextColor,
                                    size: 12,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    _formatDate(widget.event.startDate),
                                    style: const TextStyle(
                                      color: secondaryTextColor,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    Container(
                      color: cardColor,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Inscrição:',
                            style: TextStyle(
                              color: secondaryTextColor,
                              fontSize: 13,
                            ),
                          ),
                          Text(
                            "R\$ ${widget.event.price.toStringAsFixed(2).replaceAll('.', ',')}",
                            style: const TextStyle(
                              color: textColor,
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              if (widget.event.status == 'closed')
                _buildFinishedOverlay(context, widget.event),

              if (widget.event.status == 'dev') _buildComingSoonOverlay(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFinishedOverlay(BuildContext context, EventModel event) {
    final String winnerFirstName = event.winnerName?.split(' ').first ?? '';

    return Positioned.fill(
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 4, sigmaY: 4),
          child: Container(
            decoration: BoxDecoration(color: Colors.black.withOpacity(0.6)),
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
                          // USANDO CACHED IMAGE AQUI
                          CircleAvatar(
                            radius: 16,
                            backgroundColor: darkBackground,
                            backgroundImage: event.winnerPhotoURL != null
                                ? CachedNetworkImageProvider(
                                    event.winnerPhotoURL!,
                                  )
                                : null,
                            child: event.winnerPhotoURL == null
                                ? const Icon(Icons.person, size: 16)
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
      child: Container(
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.75),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.hourglass_top_rounded,
                color: secondaryTextColor,
                size: 50,
              ),
              const SizedBox(height: 12),
              const Text(
                'EM BREVE',
                style: TextStyle(
                  color: secondaryTextColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                  letterSpacing: 2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

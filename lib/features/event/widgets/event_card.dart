import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'dart:ui';
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
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
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
                            return const Center(
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: primaryAmber,
                              ),
                            );
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
                        Colors.black.withValues(alpha: 0.8),
                        Colors.black.withValues(alpha: 0.2),
                        Colors.transparent,
                      ],
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                      stops: const [0.0, 0.6, 1.0],
                    ),
                  ),
                ),
              ),
              Positioned(
                top: 12,
                left: 12,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [primaryAmber, Color(0xFFFFD54F)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: primaryAmber.withValues(alpha: 0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    widget.event.prize,
                    style: const TextStyle(
                      color: darkBackground,
                      fontWeight: FontWeight.w900,
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
                        filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.4),
                            border: Border(
                              top: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
                            ),
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
                                    FontAwesomeIcons.locationDot,
                                    color: secondaryTextColor,
                                    size: 12,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    widget.event.location.isNotEmpty &&
                                            widget.event.location !=
                                                'Local não definido'
                                        ? widget.event.location
                                        : _formatDate(widget.event.startDate),
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
                            widget.event.price == 0
                                ? "Grátis"
                                : "R\$ ${widget.event.price.toStringAsFixed(2).replaceAll('.', ',')}",
                            style: TextStyle(
                              color: widget.event.price == 0
                                  ? Colors.green
                                  : textColor,
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

              // --- OVERLAYS DE STATUS ---
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
    // CORREÇÃO APLICADA AQUI
    final String winnerFirstName = event.winnerName?.split(' ').first ?? '';

    return Positioned.fill(
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
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
                            winnerFirstName, // Exibe apenas o primeiro nome
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
        borderRadius: BorderRadius.circular(20),
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

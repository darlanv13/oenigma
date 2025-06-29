import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'dart:ui';
import 'package:lottie/lottie.dart';
import '../models/event_model.dart';
import '../screens/event_details_screen.dart';
import '../utils/app_colors.dart';

class EventCard extends StatefulWidget {
  final Map<String, dynamic> playerData;
  final EventModel event;
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
    // --- LÓGICA ATUALIZADA ---
    // Verifica se o 'icon' é uma URL válida.
    if (widget.event.icon.isNotEmpty &&
        Uri.tryParse(widget.event.icon)?.isAbsolute == true) {
      // Se for, carrega da rede.
      _composition = NetworkLottie(widget.event.icon).load();
    } else {
      // Se não, carrega a animação padrão dos assets locais.
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
      onTap: () {
        // Permite o clique mesmo se o evento estiver em dev ou fechado,
        // pois a tela de detalhes tratará o estado.
        Navigator.push(
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
          border: Border.all(color: Colors.white.withOpacity(0.1)),
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
                            } else if (snapshot.hasError) {
                              return Lottie.asset(
                                'assets/animations/no_enigma.json',
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
                                  const Icon(
                                    Icons.calendar_today,
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

              // Overlay para evento FINALIZADO
              if (widget.event.status == 'closed')
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.75),
                    ),
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.flag, color: primaryAmber, size: 50),
                          const SizedBox(height: 12),
                          const Text(
                            'FINALIZADO',
                            style: TextStyle(
                              color: primaryAmber,
                              fontWeight: FontWeight.bold,
                              fontSize: 20,
                              letterSpacing: 2,
                            ),
                          ),
                          if (widget.event.winnerName != null &&
                              widget.event.winnerName!.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(top: 8.0),
                              child: Text(
                                'Vencedor: ${widget.event.winnerName}',
                                style: const TextStyle(
                                  color: textColor,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),

              // Overlay para evento EM BREVE
              if (widget.event.status == 'dev')
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.75),
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
                ),
            ],
          ),
        ),
      ),
    );
  }
}

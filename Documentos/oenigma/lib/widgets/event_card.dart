import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; // Importa para formatação de data
import '../models/event_model.dart';
import '../screens/event_details_screen.dart';
import '../utils/app_colors.dart';

class EventCard extends StatelessWidget {
  final EventModel event;
  const EventCard({super.key, required this.event});

  // Função para formatar a data
  String _formatDate(String dateStr) {
    try {
      // Tenta analisar a data no formato "dd/MM/yyyy"
      final date = DateFormat('dd/MM/yyyy').parse(dateStr);
      // Formata para "d 'de' MMMM" (ex: 7 de junho)
      return DateFormat("d 'de' MMMM", 'pt_BR').format(date);
    } catch (e) {
      // Se der erro, retorna a string original
      return dateStr;
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => EventDetailsScreen(event: event),
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.grey[800]!.withOpacity(0.5)),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Imagem e Prêmio
              Stack(
                alignment: Alignment.bottomLeft,
                children: [
                  Container(
                    height: 160, // Altura fixa para a imagem
                    color: darkBackground,
                    child: Center(
                      child: Icon(
                        event.icon,
                        size: 50,
                        color: primaryAmber.withOpacity(0.7),
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: const BoxDecoration(
                      color: primaryAmber,
                      borderRadius: BorderRadius.only(
                        topRight: Radius.circular(20),
                      ),
                    ),
                    child: Text(
                      event.prize,
                      style: const TextStyle(
                        color: darkBackground,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ),
              // Informações do evento
              Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      event.name,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: textColor,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    _buildInfoRow(
                      Icons.calendar_today,
                      _formatDate(event.startDate),
                    ),
                    const SizedBox(height: 4),
                    _buildInfoRow(
                      Icons.monetization_on,
                      "Taxa: R\$ ${event.price.toStringAsFixed(2)}",
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

  Widget _buildInfoRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, color: secondaryTextColor, size: 14),
        const SizedBox(width: 8),
        Text(
          text,
          style: const TextStyle(color: secondaryTextColor, fontSize: 12),
        ),
      ],
    );
  }
}

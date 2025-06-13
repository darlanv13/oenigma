import 'package:flutter/material.dart';
import '../models/event_model.dart';
import '../screens/event_progress_screen.dart';
import '../services/firebase_service.dart';
import '../utils/app_colors.dart';

class EventDetailsScreen extends StatefulWidget {
  final EventModel event;
  const EventDetailsScreen({super.key, required this.event});

  @override
  State<EventDetailsScreen> createState() => _EventDetailsScreenState();
}

class _EventDetailsScreenState extends State<EventDetailsScreen> {
  final FirebaseService _firebaseService = FirebaseService();
  late Future<int> _challengeCountFuture;

  @override
  void initState() {
    super.initState();
    _challengeCountFuture = _firebaseService.getChallengeCountForEvent(
      widget.event.id,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: textColor),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          widget.event.name,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: textColor,
            fontSize: 22,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            _buildPrizeCard(),
            const SizedBox(height: 16),
            _buildInfoCard(),
            const SizedBox(height: 16),
            _buildDescriptionCard(),
            const SizedBox(height: 24),
            _buildStartButton(context),
          ],
        ),
      ),
    );
  }

  Widget _buildStartButton(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryAmber,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
        ),
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => EventProgressScreen(event: widget.event),
            ),
          );
        },
        child: const Text(
          'Iniciar Evento',
          style: TextStyle(
            color: darkBackground,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildPrizeCard() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey[800]!),
      ),
      child: Column(
        children: [
          const Icon(Icons.emoji_events, color: primaryAmber, size: 40),
          const SizedBox(height: 8),
          const Text(
            'Prêmio',
            style: TextStyle(color: secondaryTextColor, fontSize: 16),
          ),
          const SizedBox(height: 4),
          Text(
            widget.event.prize,
            style: const TextStyle(
              color: textColor,
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey[800]!),
      ),
      child: Column(
        children: [
          _buildInfoRow(Icons.location_on, 'Local:', widget.event.location),
          const Divider(color: secondaryTextColor),
          _buildInfoRow(
            Icons.calendar_today,
            'Data de Início:',
            widget.event.startDate,
          ),
          const Divider(color: secondaryTextColor),
          FutureBuilder<int>(
            future: _challengeCountFuture,
            builder: (context, snapshot) {
              final count = snapshot.hasData ? snapshot.data.toString() : '...';
              return _buildInfoRow(Icons.filter_9_plus, 'Fases:', count);
            },
          ),
          const Divider(color: secondaryTextColor),
          _buildInfoRow(
            Icons.monetization_on,
            'Inscrição:',
            'R\$ ${widget.event.price.toStringAsFixed(2)}',
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(icon, color: secondaryTextColor, size: 20),
              const SizedBox(width: 12),
              Text(
                label,
                style: const TextStyle(color: secondaryTextColor, fontSize: 16),
              ),
            ],
          ),
          Text(
            value,
            style: const TextStyle(
              color: textColor,
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDescriptionCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey[800]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.event.name,
            style: const TextStyle(
              color: textColor,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          // A descrição não existe no novo modelo, então foi removida.
          // Pode ser adicionada de volta ao modelo e ao banco de dados se necessário.
        ],
      ),
    );
  }
}

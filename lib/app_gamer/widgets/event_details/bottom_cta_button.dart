import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:oenigma/models/event_model.dart';
import 'package:oenigma/utils/app_colors.dart';
import '../../stores/event_store.dart';

class BottomCtaButton extends StatelessWidget {
  final EventModel event;
  final EventStore store;
  final VoidCallback onSubscribe;
  final VoidCallback onPlay;

  const BottomCtaButton({
    super.key,
    required this.event,
    required this.store,
    required this.onSubscribe,
    required this.onPlay,
  });

  @override
  Widget build(BuildContext context) {
    if (event.status == 'closed') {
      return _buildDisabledButton(
        icon: Icons.flag_outlined,
        label: 'Evento Finalizado',
      );
    }
    if (event.status == 'dev') {
      return _buildDisabledButton(
        icon: Icons.hourglass_top_rounded,
        label: 'Em Breve',
      );
    }

    return Observer(
      builder: (_) => Positioned(
        bottom: 0,
        left: 0,
        right: 0,
        child: Container(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [darkBackground, darkBackground.withOpacity(0.0)],
              begin: Alignment.bottomCenter,
              end: Alignment.topCenter,
            ),
          ),
          child: ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: store.isSubscribed ? Colors.green : primaryAmber,
              foregroundColor: darkBackground,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
            ),
            onPressed: store.isLoading
                ? null
                : () {
                    if (store.isSubscribed) {
                      onPlay();
                    } else {
                      onSubscribe();
                    }
                  },
            icon: store.isLoading
                ? Container(
                    width: 24,
                    height: 24,
                    child: const CircularProgressIndicator(
                      color: darkBackground,
                      strokeWidth: 2,
                    ),
                  )
                : Icon(
                    store.isSubscribed
                        ? Icons.play_arrow_rounded
                        : Icons.login_rounded,
                    size: 28,
                  ),
            label: Text(
              store.isSubscribed
                  ? 'Jogar'
                  : 'Inscreva-se (R\$ ${event.price.toStringAsFixed(2)})',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDisabledButton({required IconData icon, required String label}) {
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: Container(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [darkBackground, darkBackground.withOpacity(0.0)],
            begin: Alignment.bottomCenter,
            end: Alignment.topCenter,
          ),
        ),
        child: ElevatedButton.icon(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.grey.shade800,
            foregroundColor: Colors.grey.shade500,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15),
            ),
          ),
          onPressed: null,
          icon: Icon(icon, size: 28),
          label: Text(
            label,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ),
      ),
    );
  }
}

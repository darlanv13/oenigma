import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:oenigma/utils/app_colors.dart';
import '../../stores/enigma_store.dart';

class HintSection extends StatelessWidget {
  final EnigmaStore store;
  final int phaseOrder;
  final String eventId;
  final Function(String) onSaveImage;
  final Function(String) onLaunchMaps;
  final Function(int) onShowPurchaseDialog;

  const HintSection({
    super.key,
    required this.store,
    required this.phaseOrder,
    required this.eventId,
    required this.onSaveImage,
    required this.onLaunchMaps,
    required this.onShowPurchaseDialog,
  });

  @override
  Widget build(BuildContext context) {
    return Observer(
      builder: (_) {
        if (store.isHintVisible) {
          if (store.hintData != null) {
            return _buildCard(context, title: 'PISTA', child: _buildHintContent(context));
          }
          return const SizedBox.shrink();
        }

        if (store.canBuyHint) {
          final hintCosts = {1: 5, 2: 10, 3: 15};
          final cost = hintCosts[phaseOrder];

          return AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            child: TextButton.icon(
              onPressed: store.isLoading
                  ? null
                  : () {
                      if (cost != null) {
                        onShowPurchaseDialog(cost);
                      }
                    },
              icon: const Icon(Icons.lightbulb, color: primaryAmber),
              label: RichText(
                text: TextSpan(
                  children: [
                    const TextSpan(
                      text: 'Precisa de ajuda? ',
                      style: TextStyle(color: Colors.white70),
                    ),
                    TextSpan(
                      text: 'Ver Dica (R\$ ${cost?.toStringAsFixed(2)})',
                      style: const TextStyle(
                        color: primaryAmber,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                backgroundColor: primaryAmber.withOpacity(0.08),
              ),
            ),
          );
        }
        return const SizedBox.shrink();
      },
    );
  }

  Widget _buildCard(BuildContext context, {required String title, required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 4,
                height: 16,
                decoration: BoxDecoration(
                  color: primaryAmber,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  color: secondaryTextColor,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }

  Widget _buildHintContent(BuildContext context) {
    final String type = store.hintData!['type'];
    final String data = store.hintData!['data'];
    Widget hintContent;
    Widget actionButton;

    if (type == 'photo') {
      hintContent = ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Image.network(data),
      );
      actionButton = ElevatedButton.icon(
        onPressed: store.isLoading ? null : () => onSaveImage(data),
        icon: const Icon(Icons.download_rounded),
        label: const Text('Salvar Imagem'),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.white10,
          foregroundColor: Colors.white,
        ),
      );
    } else if (type == 'gps') {
      final coords = data.split(',');
      final lat = double.tryParse(coords[0]) ?? 0.0;
      final lng = double.tryParse(coords[1]) ?? 0.0;
      hintContent = SizedBox(
        height: 200,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: GoogleMap(
            initialCameraPosition: CameraPosition(
              target: LatLng(lat, lng),
              zoom: 15,
            ),
            markers: {
              Marker(
                markerId: const MarkerId('hintLocation'),
                position: LatLng(lat, lng),
              ),
            },
            scrollGesturesEnabled: false,
            zoomGesturesEnabled: false,
          ),
        ),
      );
      actionButton = ElevatedButton.icon(
        onPressed: () => onLaunchMaps(data),
        icon: const Icon(Icons.map_rounded),
        label: const Text('Abrir no Maps'),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.white10,
          foregroundColor: Colors.white,
        ),
      );
    } else {
      hintContent = Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: darkBackground,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          data,
          style: const TextStyle(color: textColor, fontSize: 16, height: 1.5),
        ),
      );
      actionButton = ElevatedButton.icon(
        onPressed: () {
          Clipboard.setData(ClipboardData(text: data));
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Copiado para a área de transferência!'),
              backgroundColor: Colors.green,
            ),
          );
        },
        icon: const Icon(Icons.copy_rounded),
        label: const Text('Copiar Texto'),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.white10,
          foregroundColor: Colors.white,
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [hintContent, const SizedBox(height: 16), actionButton],
    );
  }
}

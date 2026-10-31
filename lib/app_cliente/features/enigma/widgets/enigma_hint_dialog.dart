import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:parse_server_sdk_flutter/parse_server_sdk_flutter.dart';

import 'package:oenigma/app_cliente/features/enigma/widgets/relic_corner_painter.dart';
import 'package:oenigma/core/utils/app_colors.dart';

/// Diálogo para visualização de uma pista / segredo ancestral revelado.
/// Estilo Indiana Jones / Tomb Raider com cores Vale.
class EnigmaHintDialog extends StatelessWidget {
  final ParseObject hint;

  const EnigmaHintDialog({super.key, required this.hint});

  static void show(BuildContext context, ParseObject hint) {
    showDialog(
      context: context,
      builder: (context) => EnigmaHintDialog(hint: hint),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: BorderSide(
          color: AppColors.amareloVale.withValues(alpha: 0.5),
          width: 1.4,
        ),
      ),
      backgroundColor: AppColors.darkCardColor,
      child: Stack(
        children: [
          Positioned.fill(
            child: CustomPaint(
              painter: RelicCornerPainter(
                color: AppColors.amareloVale.withValues(alpha: 0.35),
                cornerLength: 18,
                strokeWidth: 2,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(22.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 34,
                          height: 34,
                          decoration: BoxDecoration(
                            color: AppColors.amareloVale.withValues(alpha: 0.16),
                            shape: BoxShape.circle,
                            border: Border.all(color: AppColors.amareloVale.withValues(alpha: 0.5)),
                          ),
                          child: const Center(
                            child: FaIcon(
                              FontAwesomeIcons.key,
                              color: AppColors.amareloVale,
                              size: 14,
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Text(
                          'SEGREDO ANCESTRAL',
                          style: GoogleFonts.cinzel(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.2,
                          ),
                        ),
                      ],
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: AppColors.cinzaMedio),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _buildContent(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    final String type = hint.get<String>('type') ?? 'text';
    final String data = hint.get<String>('data') ?? '';
    final String description = hint.get<String>('description') ?? '';

    if (type == 'photo') {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (data.isNotEmpty)
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Image.network(data),
            ),
          if (description.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              description,
              style: GoogleFonts.poppins(color: Colors.white, fontSize: 14),
            ),
          ],
        ],
      );
    } else if (type == 'audio') {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (data.isNotEmpty)
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.amareloVale.withValues(alpha: 0.18),
                foregroundColor: AppColors.amareloVale,
                side: const BorderSide(color: AppColors.amareloVale),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              onPressed: () async {
                final player = AudioPlayer();
                await player.play(UrlSource(data));
              },
              icon: const FaIcon(FontAwesomeIcons.play, size: 14),
              label: Text(
                'OUVIR ECO ANCESTRAL',
                style: GoogleFonts.cinzel(fontWeight: FontWeight.bold, letterSpacing: 0.8),
              ),
            ),
          if (description.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              description,
              style: GoogleFonts.poppins(color: Colors.white, fontSize: 14),
            ),
          ],
        ],
      );
    } else if (type == 'gps') {
      final coords = data.split(',');
      final lat = double.tryParse(coords.isNotEmpty ? coords[0] : '') ?? 0.0;
      final lng = double.tryParse(coords.length > 1 ? coords[1] : '') ?? 0.0;
      return SizedBox(
        height: 240,
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
    } else {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.35),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.amareloVale.withValues(alpha: 0.2)),
        ),
        child: Text(
          description.isNotEmpty ? description : data,
          style: GoogleFonts.poppins(
            color: Colors.white.withValues(alpha: 0.95),
            fontSize: 14,
            height: 1.5,
          ),
        ),
      );
    }
  }
}

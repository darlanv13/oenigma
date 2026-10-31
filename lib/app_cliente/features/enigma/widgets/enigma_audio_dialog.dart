import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:oenigma/app_cliente/features/enigma/widgets/relic_corner_painter.dart';
import 'package:oenigma/core/utils/app_colors.dart';

/// Modal reprodutor de áudio com temática Indiana Jones / Eco Ancestral e cores Vale.
class EnigmaAudioDialog extends StatefulWidget {
  final String url;
  const EnigmaAudioDialog({super.key, required this.url});

  @override
  State<EnigmaAudioDialog> createState() => _EnigmaAudioDialogState();
}

class _EnigmaAudioDialogState extends State<EnigmaAudioDialog> {
  final AudioPlayer _audioPlayer = AudioPlayer();
  bool _isPlaying = false;
  Duration _duration = Duration.zero;
  Duration _position = Duration.zero;

  @override
  void initState() {
    super.initState();
    _audioPlayer.onPlayerStateChanged.listen((state) {
      if (mounted) setState(() => _isPlaying = state == PlayerState.playing);
    });
    _audioPlayer.onDurationChanged.listen((newDuration) {
      if (mounted) setState(() => _duration = newDuration);
    });
    _audioPlayer.onPositionChanged.listen((newPosition) {
      if (mounted) setState(() => _position = newPosition);
    });
    _initAudio();
  }

  Future<void> _initAudio() async {
    await _audioPlayer.setSourceUrl(widget.url);
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

  String _formatDuration(Duration d) {
    String minutes = d.inMinutes.toString().padLeft(2, '0');
    String seconds = (d.inSeconds % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: AppColors.darkCardColor,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: AppColors.amareloVale.withValues(alpha: 0.5),
          width: 1.5,
        ),
      ),
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
          Column(
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
                          border: Border.all(color: AppColors.amareloVale.withValues(alpha: 0.6)),
                        ),
                        child: const Center(
                          child: FaIcon(FontAwesomeIcons.headphones, color: AppColors.amareloVale, size: 14),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        'ECO ANCESTRAL',
                        style: GoogleFonts.cinzel(
                          color: Colors.white,
                          fontSize: 15,
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
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.black,
                  border: Border.all(color: AppColors.amareloVale.withValues(alpha: 0.4), width: 1.5),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.amareloVale.withValues(alpha: 0.2),
                      blurRadius: 14,
                    ),
                  ],
                ),
                child: IconButton(
                  iconSize: 42,
                  color: AppColors.amareloVale,
                  icon: FaIcon(
                    _isPlaying ? FontAwesomeIcons.pause : FontAwesomeIcons.play,
                  ),
                  onPressed: () async {
                    if (_isPlaying) {
                      await _audioPlayer.pause();
                    } else {
                      await _audioPlayer.play(UrlSource(widget.url));
                    }
                  },
                ),
              ),
              const SizedBox(height: 20),
              SliderTheme(
                data: SliderTheme.of(context).copyWith(
                  activeTrackColor: AppColors.amareloVale,
                  inactiveTrackColor: Colors.white24,
                  thumbColor: AppColors.amareloVale,
                  overlayColor: AppColors.amareloVale.withValues(alpha: 0.2),
                  trackHeight: 4.0,
                ),
                child: Slider(
                  min: 0,
                  max: _duration.inSeconds.toDouble() > 0
                      ? _duration.inSeconds.toDouble()
                      : 1.0,
                  value: _position.inSeconds.toDouble().clamp(
                        0.0,
                        _duration.inSeconds.toDouble() > 0
                            ? _duration.inSeconds.toDouble()
                            : 1.0,
                      ),
                  onChanged: (value) async {
                    final position = Duration(seconds: value.toInt());
                    await _audioPlayer.seek(position);
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      _formatDuration(_position),
                      style: GoogleFonts.poppins(color: AppColors.cinzaMedio, fontSize: 12),
                    ),
                    Text(
                      _formatDuration(_duration),
                      style: GoogleFonts.poppins(color: AppColors.cinzaMedio, fontSize: 12),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

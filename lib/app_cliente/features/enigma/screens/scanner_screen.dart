import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import 'package:oenigma/app_cliente/features/enigma/widgets/relic_corner_painter.dart';
import 'package:oenigma/core/services/sound_service.dart';
import 'package:oenigma/core/utils/app_colors.dart';

/// Lente do Explorador: Câmera limpa com moldura sutil de relíquia e cores Vale.
class ScannerScreen extends StatefulWidget {
  final Function(String) onScan;
  const ScannerScreen({super.key, required this.onScan});

  @override
  State<ScannerScreen> createState() => _ScannerScreenState();
}

class _ScannerScreenState extends State<ScannerScreen>
    with SingleTickerProviderStateMixin {
  final MobileScannerController _scannerController = MobileScannerController();
  late AnimationController _laserController;
  String? _detectedQRCode;
  bool _isTorchOn = false;

  @override
  void initState() {
    super.initState();
    SoundService.playScan();
    _laserController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _laserController.dispose();
    _scannerController.dispose();
    super.dispose();
  }

  Future<void> _toggleTorch() async {
    try {
      await _scannerController.toggleTorch();
      SoundService.playClick();
      if (mounted) setState(() => _isTorchOn = !_isTorchOn);
      HapticFeedback.selectionClick();
    } catch (_) {}
  }

  Future<void> _switchCamera() async {
    try {
      await _scannerController.switchCamera();
      SoundService.playClick();
      HapticFeedback.selectionClick();
    } catch (_) {}
  }

  void _openManualCodeSheet() {
    SoundService.playOpen();
    final textController = TextEditingController();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF131D24),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetCtx) {
        return SingleChildScrollView(
          physics: const ClampingScrollPhysics(),
          child: Padding(
            padding: EdgeInsets.only(
              left: 20,
              right: 20,
              top: 20,
              bottom: MediaQuery.of(sheetCtx).viewInsets.bottom + 20,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const FaIcon(
                          FontAwesomeIcons.keyboard,
                          color: AppColors.amareloVale,
                          size: 16,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'INSCREVER CÓDIGO',
                          style: GoogleFonts.cinzel(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                            letterSpacing: 1.0,
                          ),
                        ),
                      ],
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: AppColors.cinzaMedio, size: 20),
                      onPressed: () => Navigator.of(sheetCtx).pop(),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  'Digite o código do enigma gravado na placa ou relíquia física:',
                  style: GoogleFonts.poppins(
                    color: AppColors.cinzaMedio,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: textController,
                  autofocus: true,
                  textCapitalization: TextCapitalization.characters,
                  style: GoogleFonts.cinzel(
                    color: AppColors.amareloVale,
                    fontSize: 17,
                    letterSpacing: 2,
                    fontWeight: FontWeight.bold,
                  ),
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: const Color(0xFF0F171B),
                    hintText: 'EX: RELIQUIA-01',
                    hintStyle: GoogleFonts.cinzel(
                      color: Colors.white24,
                      fontSize: 12.5,
                    ),
                    prefixIcon: const Icon(
                      Icons.qr_code,
                      color: AppColors.amareloVale,
                      size: 20,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.12)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.12)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(color: AppColors.amareloVale, width: 1.5),
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                ElevatedButton(
                  onPressed: () {
                    final code = textController.text.trim();
                    if (code.isNotEmpty) {
                      Navigator.of(sheetCtx).pop();
                      widget.onScan(code);
                      Navigator.of(context).pop();
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.amareloVale,
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: Text(
                    'VALIDAR E AVANÇAR',
                    style: GoogleFonts.cinzel(
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.0,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final double reticleSize = (screenSize.width * 0.65).clamp(200.0, 260.0);

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        alignment: Alignment.center,
        children: [
          // Visualização da Câmera
          MobileScanner(
            controller: _scannerController,
            onDetect: (capture) {
              if (_detectedQRCode == null) {
                final List<Barcode> barcodes = capture.barcodes;
                if (barcodes.isNotEmpty && barcodes.first.rawValue != null) {
                  HapticFeedback.heavyImpact();
                  SoundService.playScan();
                  setState(() {
                    _detectedQRCode = barcodes.first.rawValue;
                  });
                  _scannerController.stop();
                }
              }
            },
          ),

          // Máscara Escurecida ao redor da Lente
          Positioned.fill(
            child: ColorFiltered(
              colorFilter: ColorFilter.mode(
                Colors.black.withValues(alpha: 0.65),
                BlendMode.srcOut,
              ),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Container(
                    decoration: const BoxDecoration(
                      color: Colors.black,
                      backgroundBlendMode: BlendMode.dstOut,
                    ),
                  ),
                  Center(
                    child: Container(
                      width: reticleSize,
                      height: reticleSize,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Moldura Limpa da Relíquia
          Center(
            child: SizedBox(
              width: reticleSize,
              height: reticleSize,
              child: Stack(
                children: [
                  CustomPaint(
                    size: Size(reticleSize, reticleSize),
                    painter: RelicCornerPainter(
                      color: AppColors.amareloVale,
                      cornerLength: 22,
                      strokeWidth: 2.2,
                      showStuds: false,
                    ),
                  ),

                  // Linha de Varredura
                  AnimatedBuilder(
                    animation: _laserController,
                    builder: (context, child) {
                      return Positioned(
                        top: _laserController.value * (reticleSize - 10),
                        left: 8,
                        right: 8,
                        child: Container(
                          height: 2.5,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(2),
                            gradient: const LinearGradient(
                              colors: [
                                Colors.transparent,
                                AppColors.amareloVale,
                                AppColors.verdeVale,
                                AppColors.amareloVale,
                                Colors.transparent,
                              ],
                              stops: [0.0, 0.25, 0.5, 0.75, 1.0],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),

          // Barra Superior com Título da Lente, Tocha e Troca de Câmera
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              bottom: false,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: const Color(0xFF0B1115).withValues(alpha: 0.90),
                  border: Border(
                    bottom: BorderSide(
                      color: Colors.white.withValues(alpha: 0.08),
                      width: 1.0,
                    ),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Botão Voltar Redondo
                    GestureDetector(
                      onTap: () => Navigator.of(context).pop(),
                      child: Container(
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(
                          color: const Color(0xFF131D24),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.12),
                            width: 1.2,
                          ),
                        ),
                        child: const Center(
                          child: FaIcon(
                            FontAwesomeIcons.chevronLeft,
                            color: Colors.white,
                            size: 13,
                          ),
                        ),
                      ),
                    ),

                    // Título da Lente
                    Expanded(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'LENTE DA RELÍQUIA',
                            style: GoogleFonts.cinzel(
                              fontSize: 13.5,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                              letterSpacing: 1.0,
                            ),
                          ),
                          Text(
                            'ENQUADRE O QR CODE SAGRADO',
                            style: GoogleFonts.cinzel(
                              fontSize: 9,
                              fontWeight: FontWeight.w700,
                              color: AppColors.amareloVale,
                              letterSpacing: 0.8,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Ações: Tocha e Trocar Câmera
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        GestureDetector(
                          onTap: _toggleTorch,
                          child: Container(
                            width: 38,
                            height: 38,
                            decoration: BoxDecoration(
                              color: _isTorchOn ? AppColors.amareloVale : const Color(0xFF131D24),
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: _isTorchOn
                                    ? AppColors.amareloVale
                                    : Colors.white.withValues(alpha: 0.12),
                              ),
                            ),
                            child: Center(
                              child: FaIcon(
                                FontAwesomeIcons.fire,
                                color: _isTorchOn ? Colors.black : Colors.white,
                                size: 14,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        GestureDetector(
                          onTap: _switchCamera,
                          child: Container(
                            width: 38,
                            height: 38,
                            decoration: BoxDecoration(
                              color: const Color(0xFF131D24),
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.12),
                              ),
                            ),
                            child: const Center(
                              child: FaIcon(
                                FontAwesomeIcons.arrowsRotate,
                                color: Colors.white,
                                size: 13,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Barra Inferior com Atalho de Inscrição Manual
          Positioned(
            bottom: 28,
            left: 24,
            right: 24,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ElevatedButton.icon(
                  onPressed: _openManualCodeSheet,
                  icon: const FaIcon(FontAwesomeIcons.keyboard, size: 13),
                  label: Text(
                    'INSCREVER CÓDIGO MANUAL',
                    style: GoogleFonts.cinzel(
                      fontWeight: FontWeight.w800,
                      fontSize: 11,
                      letterSpacing: 0.8,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF131D24),
                    foregroundColor: AppColors.amareloVale,
                    side: BorderSide(color: AppColors.amareloVale.withValues(alpha: 0.5), width: 1.0),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                  ),
                ),
              ],
            ),
          ),

          // Overlay de Revelação quando a relíquia é detectada
          if (_detectedQRCode != null) _buildConfirmationOverlay(),
        ],
      ),
    );
  }

  Widget _buildConfirmationOverlay() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          padding: const EdgeInsets.all(20),
          width: MediaQuery.of(context).size.width * 0.85,
          decoration: BoxDecoration(
            color: const Color(0xFF131D24).withValues(alpha: 0.98),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: AppColors.verdeVale,
              width: 1.4,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.verdeVale.withValues(alpha: 0.15),
                  border: Border.all(
                    color: AppColors.verdeVale,
                    width: 1.5,
                  ),
                ),
                child: const Center(
                  child: FaIcon(
                    FontAwesomeIcons.check,
                    color: AppColors.verdeVale,
                    size: 22,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'RELÍQUIA ENCONTRADA!',
                style: GoogleFonts.cinzel(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.0,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4),
              Text(
                'Inscrição identificada pela lente sagrada:',
                style: GoogleFonts.poppins(
                  color: AppColors.cinzaMedio,
                  fontSize: 11.5,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 10),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: const Color(0xFF0F171B),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.1),
                  ),
                ),
                child: Text(
                  _detectedQRCode!,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.cinzel(
                    color: AppColors.amareloVale,
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    widget.onScan(_detectedQRCode!);
                    Navigator.of(context).pop();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.verdeVale,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: Text(
                    'DECIFRAR RELÍQUIA',
                    style: GoogleFonts.cinzel(
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.0,
                      fontSize: 13,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 6),
              TextButton(
                onPressed: () {
                  setState(() => _detectedQRCode = null);
                  _scannerController.start();
                },
                child: Text(
                  'Escanear Novamente',
                  style: GoogleFonts.poppins(
                    color: AppColors.cinzaMedio,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
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

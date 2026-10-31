import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import 'package:oenigma/app_cliente/features/enigma/widgets/relic_corner_painter.dart';
import 'package:oenigma/core/services/sound_service.dart';
import 'package:oenigma/core/utils/app_colors.dart';

/// Lente do Explorador: Câmera com moldura de relíquia antiga (Indiana Jones / Tomb Raider / Cores Vale).
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
      backgroundColor: AppColors.darkCardColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        side: BorderSide(color: AppColors.amareloVale, width: 1.3),
      ),
      builder: (sheetCtx) {
        return SingleChildScrollView(
          physics: const ClampingScrollPhysics(),
          child: Padding(
            padding: EdgeInsets.only(
              left: 24,
              right: 24,
              top: 24,
              bottom: MediaQuery.of(sheetCtx).viewInsets.bottom + 24,
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
                          size: 18,
                        ),
                        const SizedBox(width: 10),
                        Text(
                          'INSCREVER CÓDIGO',
                          style: GoogleFonts.cinzel(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            letterSpacing: 1.2,
                          ),
                        ),
                      ],
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: AppColors.cinzaMedio),
                      onPressed: () => Navigator.of(sheetCtx).pop(),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Digite o código do enigma gravado na placa ou relíquia física:',
                  style: GoogleFonts.poppins(
                    color: AppColors.cinzaMedio,
                    fontSize: 12.5,
                  ),
                ),
                const SizedBox(height: 18),
                TextField(
                  controller: textController,
                  autofocus: true,
                  textCapitalization: TextCapitalization.characters,
                  style: GoogleFonts.cinzel(
                    color: AppColors.amareloVale,
                    fontSize: 18,
                    letterSpacing: 2,
                    fontWeight: FontWeight.bold,
                  ),
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: Colors.black.withValues(alpha: 0.6),
                    hintText: 'EX: RELIQUIA-01',
                    hintStyle: GoogleFonts.cinzel(
                      color: Colors.white24,
                      fontSize: 13,
                    ),
                    prefixIcon: const Icon(
                      Icons.qr_code,
                      color: AppColors.amareloVale,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: const BorderSide(color: AppColors.amareloVale),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide(
                        color: AppColors.amareloVale.withValues(alpha: 0.4),
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: const BorderSide(
                        color: AppColors.amareloVale,
                        width: 2,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
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
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: Text(
                    'VALIDAR E AVANÇAR',
                    style: GoogleFonts.cinzel(
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.2,
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
    final double reticleSize = (screenSize.width * 0.68).clamp(210.0, 280.0);

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
                Colors.black.withValues(alpha: 0.68),
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
                        borderRadius: BorderRadius.circular(22),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Moldura Ornamental da Relíquia com Cantoneiras Antigas & Feixe Dourado
          Center(
            child: SizedBox(
              width: reticleSize,
              height: reticleSize,
              child: Stack(
                children: [
                  // Cantoneiras Ornamentais em Ouro Asteca
                  CustomPaint(
                    size: Size(reticleSize, reticleSize),
                    painter: RelicCornerPainter(
                      color: AppColors.amareloVale,
                      cornerLength: 28,
                      strokeWidth: 3.0,
                      showStuds: true,
                    ),
                  ),

                  // Selo central sutil
                  Center(
                    child: FaIcon(
                      FontAwesomeIcons.gem,
                      color: AppColors.verdeVale.withValues(alpha: 0.35),
                      size: 20,
                    ),
                  ),

                  // Feixe de Revelação da Relíquia (Dourado & Esmeralda)
                  AnimatedBuilder(
                    animation: _laserController,
                    builder: (context, child) {
                      return Positioned(
                        top: _laserController.value * (reticleSize - 10),
                        left: 8,
                        right: 8,
                        child: Container(
                          height: 3.5,
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
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.amareloVale.withValues(alpha: 0.75),
                                blurRadius: 10,
                                spreadRadius: 1.5,
                              ),
                            ],
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
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: AppColors.darkBackground.withValues(alpha: 0.90),
                  border: Border(
                    bottom: BorderSide(
                      color: AppColors.amareloVale.withValues(alpha: 0.35),
                      width: 1.2,
                    ),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Botão Voltar
                    GestureDetector(
                      onTap: () => Navigator.of(context).pop(),
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: AppColors.darkCardColor,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: AppColors.amareloVale.withValues(alpha: 0.5),
                          ),
                        ),
                        child: const Center(
                          child: FaIcon(
                            FontAwesomeIcons.chevronLeft,
                            color: AppColors.amareloVale,
                            size: 14,
                          ),
                        ),
                      ),
                    ),

                    // Título da Lente
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Text(
                                'LENTE DA RELÍQUIA',
                                style: GoogleFonts.cinzel(
                                  fontSize: 14.5,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.white,
                                  letterSpacing: 1.5,
                                ),
                              ),
                            ),
                            const SizedBox(height: 2),
                            FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Text(
                                'ENQUADRE A INSCRIÇÃO SAGRADA',
                                style: GoogleFonts.cinzel(
                                  fontSize: 9.5,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.amareloVale,
                                  letterSpacing: 1,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    // Ações: Tocha e Trocar Câmera
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        GestureDetector(
                          onTap: _toggleTorch,
                          child: Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: _isTorchOn
                                  ? AppColors.amareloVale
                                  : AppColors.darkCardColor,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: AppColors.amareloVale.withValues(alpha: 0.6),
                              ),
                            ),
                            child: Center(
                              child: FaIcon(
                                FontAwesomeIcons.fire,
                                color: _isTorchOn ? Colors.black : AppColors.amareloVale,
                                size: 15,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        GestureDetector(
                          onTap: _switchCamera,
                          child: Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: AppColors.darkCardColor,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: AppColors.verdeVale.withValues(alpha: 0.5),
                              ),
                            ),
                            child: const Center(
                              child: FaIcon(
                                FontAwesomeIcons.arrowsRotate,
                                color: Colors.white,
                                size: 14,
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

          // Barra Inferior com Instrução e Atalho de Inscrição Manual
          Positioned(
            bottom: 28,
            left: 20,
            right: 20,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.8),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: AppColors.amareloVale.withValues(alpha: 0.35),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const FaIcon(
                        FontAwesomeIcons.circleInfo,
                        color: AppColors.amareloVale,
                        size: 12,
                      ),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          'Aponte para o selo ou inscrição física no local',
                          style: GoogleFonts.poppins(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w400,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                ElevatedButton.icon(
                  onPressed: _openManualCodeSheet,
                  icon: const FaIcon(FontAwesomeIcons.keyboard, size: 14),
                  label: Text(
                    'INSCREVER CÓDIGO MANUAL',
                    style: GoogleFonts.cinzel(
                      fontWeight: FontWeight.w800,
                      fontSize: 11.5,
                      letterSpacing: 1,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.darkCardColor.withValues(alpha: 0.95),
                    foregroundColor: AppColors.amareloVale,
                    side: const BorderSide(color: AppColors.amareloVale, width: 1.3),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
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
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          padding: const EdgeInsets.all(24),
          width: MediaQuery.of(context).size.width * 0.88,
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.85,
          ),
          decoration: BoxDecoration(
            color: AppColors.darkCardColor.withValues(alpha: 0.96),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: AppColors.verdeVale,
              width: 1.8,
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.verdeVale.withValues(alpha: 0.35),
                blurRadius: 25,
                spreadRadius: 2,
              ),
            ],
          ),
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.verdeVale.withValues(alpha: 0.18),
                    border: Border.all(
                      color: AppColors.verdeVale,
                      width: 2,
                    ),
                  ),
                  child: const Center(
                    child: FaIcon(
                      FontAwesomeIcons.check,
                      color: AppColors.verdeVale,
                      size: 26,
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  'RELÍQUIA ENCONTRADA!',
                  style: GoogleFonts.cinzel(
                    color: Colors.white,
                    fontSize: 17,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.5,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 6),
                Text(
                  'Inscrição identificada pela lente sagrada:',
                  style: GoogleFonts.poppins(
                    color: AppColors.cinzaMedio,
                    fontSize: 12,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.black,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: AppColors.verdeVale.withValues(alpha: 0.4),
                    ),
                  ),
                  child: Text(
                    _detectedQRCode!,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.cinzel(
                      color: AppColors.amareloVale,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.5,
                    ),
                  ),
                ),
                const SizedBox(height: 20),
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
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: Text(
                      'DECIFRAR RELÍQUIA',
                      style: GoogleFonts.cinzel(
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.2,
                        fontSize: 13.5,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
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
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

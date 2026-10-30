import 'dart:async';
import 'dart:convert';
import 'dart:ui';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:parse_server_sdk_flutter/parse_server_sdk_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:oenigma/app_cliente/features/certificate/screens/winner_certificate_screen.dart';
import 'package:oenigma/app_cliente/features/enigma/repositories/enigma_repository.dart';
import 'package:oenigma/app_cliente/features/enigma/widgets/compass_widget.dart';
import 'package:oenigma/app_cliente/features/enigma/widgets/map_radius_widget.dart';
import 'package:oenigma/app_cliente/features/event/repositories/event_repository.dart';
import 'package:oenigma/app_cliente/features/wallet/screens/wallet_screen.dart';
import 'package:oenigma/core/models/enigma_model.dart';
import 'package:oenigma/core/models/event_model.dart';
import 'package:oenigma/core/models/phase_model.dart';
import 'package:oenigma/core/utils/app_colors.dart';
import 'package:oenigma/core/widgets/dialogs/completion_dialog.dart';
import 'package:oenigma/core/widgets/dialogs/cooldown_dialog.dart';

// ============================================================================
// 1. SCANNER SCREEN HOLOGRÁFICO (CÂMERA, MIRA TÁTICA & PALETA VALE)
// ============================================================================
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
      if (mounted) setState(() => _isTorchOn = !_isTorchOn);
      HapticFeedback.selectionClick();
    } catch (_) {}
  }

  Future<void> _switchCamera() async {
    try {
      await _scannerController.switchCamera();
      HapticFeedback.selectionClick();
    } catch (_) {}
  }

  void _openManualCodeSheet() {
    final textController = TextEditingController();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.darkCardColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        side: BorderSide(color: AppColors.verdeVale, width: 1.2),
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
                          'CÓDIGO MANUAL',
                          style: GoogleFonts.orbitron(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
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
                  'Digite o código do enigma físico gravado na placa ou etiqueta:',
                  style: GoogleFonts.inter(
                    color: AppColors.cinzaMedio,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 18),
                TextField(
                  controller: textController,
                  autofocus: true,
                  textCapitalization: TextCapitalization.characters,
                  style: GoogleFonts.orbitron(
                    color: AppColors.verdeVale,
                    fontSize: 18,
                    letterSpacing: 2,
                    fontWeight: FontWeight.bold,
                  ),
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: Colors.black.withValues(alpha: 0.6),
                    hintText: 'EX: ENIGMA-01',
                    hintStyle: GoogleFonts.orbitron(
                      color: Colors.white24,
                      fontSize: 13,
                    ),
                    prefixIcon: const Icon(
                      Icons.qr_code,
                      color: AppColors.verdeVale,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: const BorderSide(color: AppColors.verdeVale),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide(
                        color: AppColors.verdeVale.withValues(alpha: 0.35),
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: const BorderSide(
                        color: AppColors.verdeVale,
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
                    backgroundColor: AppColors.verdeVale,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: Text(
                    'CONFIRMAR E VALIDAR',
                    style: GoogleFonts.orbitron(
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
    final double reticleSize = (screenSize.width * 0.65).clamp(200.0, 270.0);

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
                  setState(() {
                    _detectedQRCode = barcodes.first.rawValue;
                  });
                  _scannerController.stop();
                }
              }
            },
          ),

          // Máscara Escurecida ao redor do Retículo
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

          // Retículo Holográfico com Cantos Tecnológicos & Laser Vale
          Center(
            child: SizedBox(
              width: reticleSize,
              height: reticleSize,
              child: Stack(
                children: [
                  // Cantoneiras Cibernéticas em Verde-Vale
                  CustomPaint(
                    size: Size(reticleSize, reticleSize),
                    painter: ScannerCornersPainter(
                      color: AppColors.verdeVale,
                      cornerLength: 26,
                      strokeWidth: 3.5,
                    ),
                  ),

                  // Cruzeta central sutil
                  Center(
                    child: FaIcon(
                      FontAwesomeIcons.plus,
                      color: AppColors.verdeVale.withValues(alpha: 0.35),
                      size: 16,
                    ),
                  ),

                  // Linha Laser de Varredura Animada (Verde-Vale <-> Amarelo-Vale)
                  AnimatedBuilder(
                    animation: _laserController,
                    builder: (context, child) {
                      return Positioned(
                        top: _laserController.value * (reticleSize - 10),
                        left: 8,
                        right: 8,
                        child: Container(
                          height: 3,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(2),
                            gradient: const LinearGradient(
                              colors: [
                                Colors.transparent,
                                AppColors.verdeVale,
                                AppColors.amareloVale,
                                AppColors.verdeVale,
                                Colors.transparent,
                              ],
                              stops: [0.0, 0.25, 0.5, 0.75, 1.0],
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.verdeVale.withValues(alpha: 0.75),
                                blurRadius: 8,
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

          // Barra Superior com Título, Lanterna e Troca de Câmera
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              bottom: false,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: AppColors.darkBackground.withValues(alpha: 0.85),
                  border: Border(
                    bottom: BorderSide(
                      color: AppColors.verdeVale.withValues(alpha: 0.25),
                      width: 1,
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
                          color: AppColors.darkCardColor.withValues(alpha: 0.8),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: AppColors.verdeVale.withValues(alpha: 0.35),
                          ),
                        ),
                        child: const Center(
                          child: FaIcon(
                            FontAwesomeIcons.chevronLeft,
                            color: Colors.white,
                            size: 14,
                          ),
                        ),
                      ),
                    ),

                    // Título Holográfico com proteção contra overflow
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Text(
                                'MIRA HOLOGRÁFICA',
                                style: GoogleFonts.orbitron(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                  letterSpacing: 1.5,
                                ),
                              ),
                            ),
                            const SizedBox(height: 2),
                            FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Text(
                                'ALINHE O CÓDIGO AO CENTRO',
                                style: GoogleFonts.orbitron(
                                  fontSize: 9,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.amareloVale,
                                  letterSpacing: 1,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    // Ações: Lanterna e Trocar Câmera
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
                                  : AppColors.darkCardColor.withValues(alpha: 0.8),
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: _isTorchOn
                                    ? AppColors.amareloVale
                                    : AppColors.verdeVale.withValues(alpha: 0.35),
                              ),
                            ),
                            child: Center(
                              child: FaIcon(
                                _isTorchOn
                                    ? FontAwesomeIcons.solidLightbulb
                                    : FontAwesomeIcons.lightbulb,
                                color: _isTorchOn ? Colors.black : Colors.white,
                                size: 16,
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
                              color: AppColors.darkCardColor.withValues(alpha: 0.8),
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: AppColors.verdeVale.withValues(alpha: 0.35),
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

          // Barra Inferior com Dica e Atalho de Código Manual
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
                    color: Colors.black.withValues(alpha: 0.75),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: AppColors.cinzaMedio.withValues(alpha: 0.3),
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
                          'Aponte para o QR Code físico no local',
                          style: GoogleFonts.inter(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
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
                    'DIGITAR CÓDIGO MANUAL',
                    style: GoogleFonts.orbitron(
                      fontWeight: FontWeight.w800,
                      fontSize: 12,
                      letterSpacing: 1,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.darkCardColor.withValues(alpha: 0.9),
                    foregroundColor: AppColors.amareloVale,
                    side: const BorderSide(color: AppColors.amareloVale, width: 1.2),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  ),
                ),
              ],
            ),
          ),

          // Overlay de Confirmação quando o código é detectado
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
            color: AppColors.darkCardColor.withValues(alpha: 0.95),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: AppColors.verdeVale,
              width: 1.8,
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.verdeVale.withValues(alpha: 0.3),
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
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.verdeVale.withValues(alpha: 0.15),
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
                  'ALVO IDENTIFICADO!',
                  style: GoogleFonts.orbitron(
                    color: Colors.white,
                    fontSize: 17,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.5,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 6),
                Text(
                  'Código detectado pelos sensores:',
                  style: GoogleFonts.inter(
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
                      color: AppColors.verdeVale.withValues(alpha: 0.35),
                    ),
                  ),
                  child: Text(
                    _detectedQRCode!,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.orbitron(
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
                      'VALIDAR E AVANÇAR',
                      style: GoogleFonts.orbitron(
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.2,
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
                    style: GoogleFonts.inter(
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

// ----------------------------------------------------------------------------
// CUSTOM PAINTER - Cantoneiras Cibernéticas do Scanner
// ----------------------------------------------------------------------------
class ScannerCornersPainter extends CustomPainter {
  final Color color;
  final double cornerLength;
  final double strokeWidth;

  ScannerCornersPainter({
    required this.color,
    this.cornerLength = 24.0,
    this.strokeWidth = 3.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final w = size.width;
    final h = size.height;

    // Canto Superior Esquerdo
    canvas.drawLine(const Offset(0, 0), Offset(cornerLength, 0), paint);
    canvas.drawLine(const Offset(0, 0), Offset(0, cornerLength), paint);

    // Canto Superior Direito
    canvas.drawLine(Offset(w, 0), Offset(w - cornerLength, 0), paint);
    canvas.drawLine(Offset(w, 0), Offset(w, cornerLength), paint);

    // Canto Inferior Esquerdo
    canvas.drawLine(Offset(0, h), Offset(cornerLength, h), paint);
    canvas.drawLine(Offset(0, h), Offset(0, h - cornerLength), paint);

    // Canto Inferior Direito
    canvas.drawLine(Offset(w, h), Offset(w - cornerLength, h), paint);
    canvas.drawLine(Offset(w, h), Offset(w, h - cornerLength), paint);
  }

  @override
  bool shouldRepaint(covariant ScannerCornersPainter oldDelegate) {
    return oldDelegate.color != color ||
        oldDelegate.cornerLength != cornerLength ||
        oldDelegate.strokeWidth != strokeWidth;
  }
}

// ============================================================================
// 2. ENIGMA SCREEN PRINCIPAL (REDESIGN COMPLETO, PALETA VALE & ZERO OVERFLOW)
// ============================================================================
class EnigmaScreen extends StatefulWidget {
  final EventModel event;
  final PhaseModel phase;
  final EnigmaModel initialEnigma;
  final VoidCallback onEnigmaSolved;

  const EnigmaScreen({
    super.key,
    required this.event,
    required this.phase,
    required this.initialEnigma,
    required this.onEnigmaSolved,
  });

  @override
  State<EnigmaScreen> createState() => _EnigmaScreenState();
}

class _EnigmaScreenState extends State<EnigmaScreen>
    with SingleTickerProviderStateMixin {
  // Repositórios
  final EnigmaRepository _enigmaRepository = EnigmaRepository();
  final EventRepository _eventService = EventRepository();

  bool _isLoading = false;
  StreamSubscription<Position>? _locationSubscription;
  bool _isNear = false;
  double? _distance;
  bool _isBlocked = false;
  Timer? _statusPollTimer;
  late EnigmaModel _currentEnigma;

  // Ferramentas e Dicas
  bool _hasCompass = false;
  bool _hasMap = false;
  bool _hasRadar = false;
  int _selectedTacticalTab = 0;
  Map<String, double>? _destinationLocation;
  int _compassDuration = 0;
  double _compassPrice = 15.0;
  int? _compassRemainingSeconds;

  List<ParseObject> _hintsList = [];
  List<String> _hintsPurchased = [];
  bool _isLoadingHints = true;

  late AnimationController _shakeController;

  @override
  void initState() {
    super.initState();
    _currentEnigma = widget.initialEnigma;

    _shakeController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );

    _shakeController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _shakeController.reset();
      }
    });

    _resetEnigmaState();
  }

  @override
  void dispose() {
    _locationSubscription?.cancel();
    _statusPollTimer?.cancel();
    _shakeController.dispose();
    super.dispose();
  }

  void _triggerShake() {
    _shakeController.forward();
  }

  // ==========================================================================
  // ESTADO & LÓGICA DO ENIGMA
  // ==========================================================================
  Future<void> _resetEnigmaState() async {
    _locationSubscription?.cancel();
    _statusPollTimer?.cancel();
    setState(() {
      _distance = null;
      _isNear = false;
      _isBlocked = false;
      _isLoading = true;
      _hasCompass = false;
      _hasMap = false;
      _hasRadar = false;
      _destinationLocation = null;
      _compassRemainingSeconds = null;
      _isLoadingHints = true;
    });

    try {
      if (_currentEnigma.location != null) {
        await _initializeGpsListener();
      }
      if (mounted) {
        await _loadHints();
        await _fetchInitialStatus();
      }
    } catch (e) {
      debugPrint("Erro na inicialização do enigma: $e");
      _loadOfflineCache();
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _loadOfflineCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cached = prefs.getString('enigma_cache_${_currentEnigma.id}');
      if (cached != null && mounted) {
        final statusData = Map<String, dynamic>.from(jsonDecode(cached));
        setState(() {
          _hintsPurchased = List<String>.from(statusData['hintsPurchased'] ?? []);
          _isBlocked = statusData['isBlocked'] ?? false;
          _hasCompass = statusData['hasCompass'] ?? _currentEnigma.hasCompass;
          _hasMap = statusData['hasMap'] ?? _currentEnigma.hasMap;
          _hasRadar = statusData['hasRadar'] ?? _currentEnigma.hasRadar;
          _compassDuration = statusData['compassDuration'] ?? _currentEnigma.compassDuration;
          _compassPrice = (statusData['compassPrice'] as num?)?.toDouble() ?? _currentEnigma.compassPrice;
          if (_compassPrice == 0.0) _compassPrice = 15.0;
          if (statusData['destinationLocation'] != null) {
            _destinationLocation = {
              'latitude': (statusData['destinationLocation']['latitude'] as num).toDouble(),
              'longitude': (statusData['destinationLocation']['longitude'] as num).toDouble(),
            };
          }
          if (_compassRemainingSeconds == null) {
            _compassRemainingSeconds = _compassDuration;
          }
        });
        if (_isBlocked && statusData['cooldownUntil'] != null) {
          _handleCooldown(statusData['cooldownUntil']);
        }
      }
    } catch (_) {}
  }

  Future<void> _loadHints() async {
    try {
      final query = QueryBuilder<ParseObject>(ParseObject('Hint'))
        ..whereEqualTo('linkedEnigmaId', _currentEnigma.id);

      final response = await query.query();

      if (response.success && response.results != null) {
        if (mounted) {
          setState(() {
            _hintsList = response.results as List<ParseObject>;
            _isLoadingHints = false;
          });
        }
      } else {
        if (mounted) setState(() => _isLoadingHints = false);
      }
    } catch (e) {
      if (mounted) setState(() => _isLoadingHints = false);
    }
  }

  Future<void> _fetchInitialStatus() async {
    try {
      final result = await _enigmaRepository.callEnigmaFunction('getStatus', {
        'eventId': widget.event.id,
        'phaseOrder': widget.phase.order,
        'enigmaId': _currentEnigma.id,
      });

      if (result.success && result.result != null) {
        try {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString(
            'enigma_cache_${_currentEnigma.id}',
            jsonEncode(result.result),
          );
        } catch (_) {}
      }

      if (mounted) {
        if (!result.success || result.result == null) throw Exception('API Call failed');
        final statusData = Map<String, dynamic>.from(result.result);

        setState(() {
          _hintsPurchased = List<String>.from(statusData['hintsPurchased'] ?? []);
          _isBlocked = statusData['isBlocked'] ?? false;
          _hasCompass = statusData['hasCompass'] ?? _currentEnigma.hasCompass;
          _hasMap = statusData['hasMap'] ?? _currentEnigma.hasMap;
          _hasRadar = statusData['hasRadar'] ?? _currentEnigma.hasRadar;
          _compassDuration = statusData['compassDuration'] ?? _currentEnigma.compassDuration;
          _compassPrice = (statusData['compassPrice'] as num?)?.toDouble() ?? _currentEnigma.compassPrice;

          if (_compassPrice == 0.0) _compassPrice = 15.0;
          if (statusData['destinationLocation'] != null) {
            _destinationLocation = {
              'latitude': (statusData['destinationLocation']['latitude'] as num).toDouble(),
              'longitude': (statusData['destinationLocation']['longitude'] as num).toDouble(),
            };
          }
          if (_compassRemainingSeconds == null) {
            _compassRemainingSeconds = _compassDuration;
          }
        });

        if (_isBlocked && statusData['cooldownUntil'] != null) {
          _handleCooldown(statusData['cooldownUntil']);
        }
      }
    } catch (e) {
      debugPrint("Erro ao buscar status: $e");
    }
  }

  void _handleCooldown(dynamic rawCooldown) {
    if (rawCooldown == null) return;
    DateTime? cooldownUntil;
    if (rawCooldown is num) {
      cooldownUntil = DateTime.fromMillisecondsSinceEpoch(rawCooldown.toInt());
    } else if (rawCooldown is String) {
      final asNum = num.tryParse(rawCooldown);
      if (asNum != null) {
        cooldownUntil = DateTime.fromMillisecondsSinceEpoch(asNum.toInt());
      } else {
        cooldownUntil = DateTime.tryParse(rawCooldown);
      }
    } else if (rawCooldown is DateTime) {
      cooldownUntil = rawCooldown;
    }

    if (cooldownUntil != null && cooldownUntil.isAfter(DateTime.now())) {
      final targetCooldown = cooldownUntil;
      setState(() => _isBlocked = true);
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => CooldownDialog(
          cooldownUntil: targetCooldown,
          onCooldownFinished: () {
            if (mounted) setState(() => _isBlocked = false);
          },
        ),
      );
    }
  }

  Future<void> _initializeGpsListener() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      await Geolocator.openLocationSettings();
      return;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return;
    }
    if (permission == LocationPermission.deniedForever) return;

    _locationSubscription = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 1,
      ),
    ).listen((Position currentLocation) {
      if (!mounted || _currentEnigma.location == null) return;

      if (currentLocation.isMocked) {
        setState(() {
          _distance = null;
          _isNear = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('⚠️ Fake GPS detectado!'),
            backgroundColor: AppColors.danger,
          ),
        );
        ParseUser.currentUser().then((user) {
          if (user != null && user is ParseUser) {
            ParseObject('FraudLog')
              ..set('objectId', user.objectId)
              ..set('eventId', widget.event.id)
              ..set('enigmaId', _currentEnigma.id)
              ..set('reason', 'Fake GPS Detectado')
              ..save();
          }
        });
        return;
      }

      final distanceInMeters = Geolocator.distanceBetween(
        currentLocation.latitude,
        currentLocation.longitude,
        _currentEnigma.location!.latitude,
        _currentEnigma.location!.longitude,
      );

      setState(() {
        _distance = distanceInMeters;
        _isNear = distanceInMeters <= 100;
      });
    });
  }

  Future<void> _handleToolPurchase(String toolType) async {
    setState(() => _isLoading = true);
    try {
      final result = await _enigmaRepository.callEnigmaFunction(
        'purchaseTool',
        {'eventId': widget.event.id, 'toolType': toolType},
      );

      if (!mounted) return;
      final data = Map<String, dynamic>.from(result.result);

      if (data['success'] ?? false) {
        await _fetchInitialStatus();
        if (!mounted) return;

        showDialog(
          context: context,
          builder: (dialogContext) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
              side: BorderSide(
                color: toolType == 'compass'
                    ? AppColors.amareloVale.withValues(alpha: 0.5)
                    : AppColors.verdeVale.withValues(alpha: 0.5),
                width: 1.5,
              ),
            ),
            backgroundColor: AppColors.darkCardColor,
            title: Text(
              toolType == 'compass' ? 'Bússola Ativada!' : 'Mapa Ativado!',
              style: GoogleFonts.poppins(
                color: toolType == 'compass' ? AppColors.amareloVale : AppColors.verdeVale,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                FaIcon(
                  toolType == 'compass'
                      ? FontAwesomeIcons.compass
                      : FontAwesomeIcons.mapLocationDot,
                  size: 54,
                  color: toolType == 'compass' ? AppColors.amareloVale : AppColors.verdeVale,
                ),
                const SizedBox(height: 18),
                Text(
                  toolType == 'compass'
                      ? '1. O triângulo é a sua posição.\n2. O ponto brilhante é o alvo.\n3. Gire o celular para alinhar a mira.\n4. O contador digital indicará a distância.'
                      : '1. Um círculo tático foi desenhado no mapa.\n2. O enigma está dentro deste raio perimétrico.\n3. Desloque-se até o local e procure a pista física.',
                  style: GoogleFonts.inter(
                    color: AppColors.cinzaMedio,
                    fontSize: 13,
                    height: 1.5,
                  ),
                ),
              ],
            ),
            actions: [
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: toolType == 'compass'
                        ? AppColors.amareloVale
                        : AppColors.verdeVale,
                    foregroundColor: toolType == 'compass' ? Colors.black : Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  child: const Text(
                    'ENTENDI',
                    style: TextStyle(fontWeight: FontWeight.w900),
                  ),
                ),
              ),
            ],
          ),
        );
      }
    } on ParseError catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.message), backgroundColor: AppColors.danger),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _handleAction(
    String action, {
    String? code,
    String? toolType,
    String? hintId,
  }) async {
    setState(() => _isLoading = true);
    try {
      double? currentLat;
      double? currentLng;

      // Validação Geográfica para o Anti-Fraude
      if (action == 'validateCode' || action == 'verify_code' || action == 'scan_enigma') {
        try {
          Position position = await Geolocator.getCurrentPosition(
            desiredAccuracy: LocationAccuracy.high,
          );
          currentLat = position.latitude;
          currentLng = position.longitude;
        } catch (e) {
          throw 'É necessário ativar o GPS para validar o enigma.';
        }
      }

      final result = await _enigmaRepository.callEnigmaFunction(action, {
        'eventId': widget.event.id,
        'phaseOrder': widget.phase.order,
        'enigmaId': _currentEnigma.id,
        if (code != null) 'code': code,
        if (toolType != null) 'toolType': toolType,
        if (hintId != null) 'hintId': hintId,
        if (currentLat != null) 'latitude': currentLat,
        if (currentLng != null) 'longitude': currentLng,
      });

      if (!mounted) return;

      final data = Map<String, dynamic>.from(result.result);
      final success = data['success'] ?? false;

      if (success) {
        if (action == 'consumeTool') {
          return;
        } else if (action == 'purchaseHint') {
          await _fetchInitialStatus();
        } else if (action == 'validateCode') {
          final nextStep = data['nextStep'] != null
              ? Map<String, dynamic>.from(data['nextStep'])
              : null;
          if (nextStep == null) return;

          switch (nextStep['type']) {
            case 'event_complete':
              final double prizeWon =
                  (nextStep['prizeWon'] as num?)?.toDouble() ?? 0.0;
              final bool isWinner = nextStep['isWinner'] == true;
              final String winnerName = (nextStep['winnerName'] ??
                      widget.event.winnerName ??
                      'Outro explorador')
                  .toString();
              final List<PhaseModel> allPhases =
                  await _eventService.getPhasesForEvent(widget.event.id);
              if (mounted) {
                if (isWinner) {
                  Navigator.of(context).pushReplacement(
                    MaterialPageRoute(
                      builder: (context) => WinnerCertificateScreen(
                        event: widget.event,
                        prizeWon: prizeWon,
                        allPhases: allPhases,
                      ),
                    ),
                  );
                } else {
                  await showDialog(
                    context: context,
                    barrierDismissible: false,
                    builder: (dialogCtx) => AlertDialog(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                        side: const BorderSide(color: AppColors.amareloVale),
                      ),
                      backgroundColor: AppColors.darkCardColor,
                      title: Row(
                        children: [
                          const FaIcon(
                            FontAwesomeIcons.trophy,
                            color: AppColors.amareloVale,
                            size: 20,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'Jornada Concluída!',
                              style: GoogleFonts.poppins(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      content: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Parabéns! Você resolveu todos os enigmas de todas as fases da caçada.',
                            style: GoogleFonts.inter(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'O prêmio total de ${widget.event.prize} foi conquistado exclusivamente pelo 1º colocado ($winnerName), mas você concluiu todas as etapas com honra e acumulou pontos de experiência!',
                            style: GoogleFonts.inter(
                              color: AppColors.cinzaMedio,
                              fontSize: 13,
                              height: 1.5,
                            ),
                          ),
                        ],
                      ),
                      actions: [
                        ElevatedButton(
                          onPressed: () {
                            Navigator.of(dialogCtx).pop();
                            Navigator.of(context).pop();
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.verdeVale,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text('VOLTAR AO INÍCIO'),
                        ),
                      ],
                    ),
                  );
                }
              }
              break;

            case 'next_enigma':
              if (nextStep['enigmaData'] != null &&
                  nextStep['enigmaData'] is Map &&
                  (nextStep['enigmaData'] as Map).isNotEmpty) {
                final nextEnigma = EnigmaModel.fromMap(
                  Map<String, dynamic>.from(nextStep['enigmaData']),
                );
                await showDialog(
                  context: context,
                  barrierDismissible: false,
                  builder: (dialogContext) => Dialog(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(24),
                      side: BorderSide(
                        color: AppColors.verdeVale.withValues(alpha: 0.5),
                        width: 1.5,
                      ),
                    ),
                    backgroundColor: AppColors.darkCardColor,
                    child: Padding(
                      padding: const EdgeInsets.all(28.0),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 60,
                            height: 60,
                            decoration: BoxDecoration(
                              color: AppColors.verdeVale.withValues(alpha: 0.15),
                              shape: BoxShape.circle,
                              border: Border.all(color: AppColors.verdeVale, width: 2),
                            ),
                            child: const Center(
                              child: FaIcon(
                                FontAwesomeIcons.check,
                                color: AppColors.verdeVale,
                                size: 26,
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Enigma Resolvido!',
                            style: GoogleFonts.poppins(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Excelente trabalho! Prepare-se para o próximo desafio desta fase.',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              color: AppColors.cinzaMedio,
                            ),
                          ),
                          const SizedBox(height: 24),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.verdeVale,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                              ),
                              onPressed: () => Navigator.of(dialogContext).pop(),
                              child: const Text(
                                'PRÓXIMO ENIGMA',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 1,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
                setState(() => _currentEnigma = nextEnigma);
                await _resetEnigmaState();
              }
              break;

            case 'phase_complete':
              showCompletionDialog(
                context,
                isPhaseComplete: true,
                onOkPressed: () {
                  Navigator.of(context).pop();
                  widget.onEnigmaSolved();
                  Navigator.of(context).pop();
                },
              );
              break;
          }
        }
      } else {
        final message = data['message'] ?? 'Ação falhou.';
        if (action == 'validateCode') _triggerShake();

        if (data['cooldownUntil'] != null) {
          _handleCooldown(data['cooldownUntil']);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(message), backgroundColor: AppColors.danger),
          );
        }
      }
    } on ParseError catch (e) {
      if (e.message.contains('saldo') == true ||
          e.message.contains('Saldo insuficiente') == true) {
        _showInsufficientFundsDialog();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.message), backgroundColor: AppColors.danger),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString()), backgroundColor: AppColors.danger),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // ==========================================================================
  // DIÁLOGOS DE CONFIRMAÇÃO & SALDO
  // ==========================================================================
  void _showInsufficientFundsDialog() {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(
            color: AppColors.amareloVale.withValues(alpha: 0.5),
            width: 1,
          ),
        ),
        backgroundColor: AppColors.darkCardColor,
        title: const Row(
          children: [
            FaIcon(FontAwesomeIcons.wallet, color: AppColors.amareloVale, size: 20),
            SizedBox(width: 10),
            Text(
              'Saldo Insuficiente',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        content: const Text(
          'Você não tem saldo suficiente para comprar este item. Deseja adicionar créditos?',
          style: TextStyle(color: AppColors.cinzaMedio),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('AGORA NÃO', style: TextStyle(color: AppColors.cinzaMedio)),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(dialogContext).pop();
              setState(() => _isLoading = true);
              try {
                if (!mounted) return;
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (context) => const WalletScreen()),
                );
              } finally {
                if (mounted) setState(() => _isLoading = false);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.amareloVale,
              foregroundColor: Colors.black,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text(
              'RECARREGAR',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  Future<bool?> _showPurchaseConfirmationDialog(
    double cost, {
    String type = 'Dica',
  }) {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(
            color: AppColors.amareloVale.withValues(alpha: 0.5),
            width: 1,
          ),
        ),
        backgroundColor: AppColors.darkCardColor,
        title: const Row(
          children: [
            FaIcon(FontAwesomeIcons.store, color: AppColors.amareloVale, size: 18),
            SizedBox(width: 10),
            Text(
              'Confirmar Compra',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        content: Text(
          'Comprar $type por R\$ ${cost.toStringAsFixed(2)}?\n\nEste valor será deduzido do saldo da sua carteira.',
          style: const TextStyle(color: AppColors.cinzaMedio, height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('CANCELAR', style: TextStyle(color: AppColors.cinzaMedio)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.amareloVale,
              foregroundColor: Colors.black,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text(
              'SIM, COMPRAR',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================================================
  // DIÁLOGOS DE MÍDIA, PISTAS, MAPA & BÚSSOLA
  // ==========================================================================
  void _showMediaDialog(
    BuildContext context, {
    required String type,
    required String url,
  }) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.all(16),
          child: type == 'image'
              ? _buildImageDialog(url)
              : _AudioDialog(url: url),
        );
      },
    );
  }

  Widget _buildImageDialog(String url) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: Stack(
        alignment: Alignment.topRight,
        children: [
          Image.network(url, fit: BoxFit.contain),
          Padding(
            padding: const EdgeInsets.all(10.0),
            child: CircleAvatar(
              backgroundColor: Colors.black.withValues(alpha: 0.6),
              radius: 18,
              child: IconButton(
                padding: EdgeInsets.zero,
                icon: const Icon(Icons.close, color: Colors.white, size: 20),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _openHintDialog(ParseObject hint) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: BorderSide(
            color: AppColors.amareloVale.withValues(alpha: 0.4),
            width: 1.2,
          ),
        ),
        backgroundColor: AppColors.darkCardColor,
        child: Padding(
          padding: const EdgeInsets.all(22.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const FaIcon(
                        FontAwesomeIcons.lightbulb,
                        color: AppColors.amareloVale,
                        size: 18,
                      ),
                      const SizedBox(width: 10),
                      Text(
                        'Pista Revelada',
                        style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
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
              _buildHintDialogContent(hint),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHintDialogContent(ParseObject hint) {
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
              style: const TextStyle(color: Colors.white, fontSize: 14),
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
                backgroundColor: AppColors.amareloVale.withValues(alpha: 0.15),
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
              label: const Text('Ouvir Pista de Áudio', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          if (description.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              description,
              style: const TextStyle(color: Colors.white, fontSize: 14),
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
          color: Colors.black.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white10),
        ),
        child: Text(
          description.isNotEmpty ? description : data,
          textAlign: TextAlign.center,
          style: GoogleFonts.inter(
            color: Colors.white,
            fontSize: 15,
            height: 1.5,
            fontWeight: FontWeight.w500,
          ),
        ),
      );
    }
  }

  void _openRadarDialog() {
    _openCompassDialog();
  }

  void _openMapDialog() {
    if (_destinationLocation == null && _currentEnigma.location != null) {
      _destinationLocation = {
        'latitude': _currentEnigma.location!.latitude,
        'longitude': _currentEnigma.location!.longitude,
      };
    }
    if (_destinationLocation == null) return;

    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: BorderSide(
            color: AppColors.verdeVale.withValues(alpha: 0.5),
            width: 1.5,
          ),
        ),
        backgroundColor: AppColors.darkCardColor,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const FaIcon(
                        FontAwesomeIcons.mapLocationDot,
                        color: AppColors.verdeVale,
                        size: 16,
                      ),
                      const SizedBox(width: 10),
                      Text(
                        'MAPA TÁTICO EXPANDIDO',
                        style: GoogleFonts.orbitron(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1,
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
              const SizedBox(height: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: MapRadiusWidget(
                  destinationLatitude: _destinationLocation!['latitude']!,
                  destinationLongitude: _destinationLocation!['longitude']!,
                  isCompact: false,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _openCompassDialog() {
    if (_destinationLocation == null && _currentEnigma.location != null) {
      _destinationLocation = {
        'latitude': _currentEnigma.location!.latitude,
        'longitude': _currentEnigma.location!.longitude,
      };
    }
    if (_destinationLocation == null) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: BorderSide(
            color: AppColors.amareloVale.withValues(alpha: 0.5),
            width: 1.5,
          ),
        ),
        backgroundColor: AppColors.darkCardColor,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const FaIcon(
                        FontAwesomeIcons.compass,
                        color: AppColors.amareloVale,
                        size: 16,
                      ),
                      const SizedBox(width: 10),
                      Text(
                        'RADAR & BÚSSOLA 360°',
                        style: GoogleFonts.orbitron(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1,
                        ),
                      ),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: AppColors.cinzaMedio),
                    onPressed: () => Navigator.of(dialogContext).pop(),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              CompassWidget(
                targetLatitude: _destinationLocation!['latitude']!,
                targetLongitude: _destinationLocation!['longitude']!,
                destinationLongitude: _destinationLocation!['longitude']!,
                destinationLatitude: _destinationLocation!['latitude']!,
                durationSeconds: _compassRemainingSeconds ?? _compassDuration,
                isCompact: false,
                onTick: (int remaining) {
                  _compassRemainingSeconds = remaining;
                },
                onTimeUp: () {
                  if (Navigator.canPop(dialogContext)) {
                    Navigator.of(dialogContext).pop();
                    setState(() {
                      _hasCompass = false;
                      _compassRemainingSeconds = null;
                    });
                    _handleAction('consumeTool', toolType: 'compass');
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('O tempo da bússola acabou!'),
                        backgroundColor: AppColors.amareloVale,
                      ),
                    );
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ==========================================================================
  // CONSTRUÇÃO PRINCIPAL DA TELA (BUILD)
  // ==========================================================================
  @override
  Widget build(BuildContext context) {
    final bool isClassic = widget.event.eventType == 'classic';

    return Scaffold(
      backgroundColor: AppColors.darkBackground,
      body: Stack(
        children: [
          // Iluminação Ambiente Tática Suave (Atmosfera Vale)
          Positioned(
            top: -60,
            right: -60,
            child: Container(
              width: 250,
              height: 250,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.verdeVale.withValues(alpha: 0.12),
              ),
            ),
          ),
          Positioned(
            bottom: 120,
            left: -80,
            child: Container(
              width: 260,
              height: 260,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.amareloVale.withValues(alpha: 0.08),
              ),
            ),
          ),

          // ScrollView com Header e Conteúdo
          CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              // 1. BARRA SUPERIOR CUSTOMIZADA COM TAG DE MODALIDADE E ZERO OVERFLOW
              SliverToBoxAdapter(
                child: SafeArea(
                  bottom: false,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      border: Border(
                        bottom: BorderSide(
                          color: AppColors.verdeVale.withValues(alpha: 0.15),
                          width: 1,
                        ),
                      ),
                    ),
                    child: Row(
                      children: [
                        // Botão Voltar (Área de toque otimizada)
                        GestureDetector(
                          onTap: () => Navigator.of(context).pop(),
                          behavior: HitTestBehavior.opaque,
                          child: Container(
                            width: 42,
                            height: 42,
                            decoration: BoxDecoration(
                              color: AppColors.darkCardColor,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: AppColors.verdeVale.withValues(alpha: 0.35),
                              ),
                            ),
                            child: const Center(
                              child: FaIcon(
                                FontAwesomeIcons.chevronLeft,
                                color: Colors.white,
                                size: 14,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),

                        // Título Central com Tag de Modalidade
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  FaIcon(
                                    isClassic ? FontAwesomeIcons.trophy : FontAwesomeIcons.boxOpen,
                                    size: 10,
                                    color: isClassic ? AppColors.verdeVale : AppColors.amareloVale,
                                  ),
                                  const SizedBox(width: 5),
                                  Text(
                                    isClassic ? 'CLASSIC' : 'FIND & WIN',
                                    style: GoogleFonts.poppins(
                                      color: isClassic ? AppColors.verdeVale : AppColors.amareloVale,
                                      fontSize: 10,
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: 0.8,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 2),
                              FittedBox(
                                fit: BoxFit.scaleDown,
                                child: Text(
                                  _currentEnigma.type == 'qrcode'
                                      ? "QR Code"
                                      : widget.phase.id == 'find_and_win'
                                          ? (_currentEnigma.title.isNotEmpty ? _currentEnigma.title : "Baú do Enigma")
                                          : "Fase ${widget.phase.order} • Enigma ${widget.phase.enigmas.indexOf(_currentEnigma) + 1}",
                                  textAlign: TextAlign.center,
                                  style: GoogleFonts.poppins(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),

                        // Status Pill (Ativo / Bloqueado)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: _isBlocked
                                ? AppColors.danger.withValues(alpha: 0.15)
                                : AppColors.verdeVale.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: _isBlocked ? AppColors.danger : AppColors.verdeVale,
                              width: 1,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 6,
                                height: 6,
                                decoration: BoxDecoration(
                                  color: _isBlocked ? AppColors.danger : AppColors.verdeVale,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 5),
                              Text(
                                _isBlocked ? 'Pausa' : 'Ativo',
                                style: TextStyle(
                                  color: _isBlocked ? AppColors.danger : AppColors.verdeVale,
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // 2. CONTEÚDO PRINCIPAL (CARDS, FERRAMENTAS & CENTRAL TÁTICA)
              SliverToBoxAdapter(
                child: _isLoading && _hintsList.isEmpty
                    ? const Padding(
                        padding: EdgeInsets.only(top: 100),
                        child: Center(
                          child: CircularProgressIndicator(color: AppColors.verdeVale),
                        ),
                      )
                    : Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            _buildEnigmaCard(),
                            const SizedBox(height: 18),
                            _buildHintSection(),
                            const SizedBox(height: 18),
                            _buildActionArea(),
                            const SizedBox(height: 40),
                          ],
                        ),
                      ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // --- CARD PADRÃO COM DESIGN SYSTEM VALE & GLASSMORPHISM ---
  Widget _buildCard({
    required String title,
    required Widget child,
    dynamic icon,
    Color? accentColor,
  }) {
    final effectiveAccent = accentColor ?? AppColors.verdeVale;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.darkCardColor,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: effectiveAccent.withValues(alpha: 0.25),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.4),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (icon != null) ...[
                FaIcon(icon, color: effectiveAccent, size: 15),
                const SizedBox(width: 10),
              ],
              Expanded(
                child: Text(
                  title.toUpperCase(),
                  style: GoogleFonts.inter(
                    color: AppColors.cinzaMedio,
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.2,
                  ),
                  overflow: TextOverflow.ellipsis,
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

  // --- CARD DO ENIGMA (INSTRUÇÃO MARKDOWN + MÍDIAS SEM OVERFLOW) ---
  Widget _buildEnigmaCard() {
    final hasImage = _currentEnigma.imageUrl != null && _currentEnigma.imageUrl!.isNotEmpty;
    final hasAudio = _currentEnigma.audioUrl != null && _currentEnigma.audioUrl!.isNotEmpty;

    return _buildCard(
      title: 'Desafio Atual',
      icon: FontAwesomeIcons.scroll,
      accentColor: AppColors.amareloVale,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          MarkdownBody(
            data: _currentEnigma.instruction,
            styleSheet: MarkdownStyleSheet(
              p: GoogleFonts.inter(
                color: Colors.white,
                fontSize: 15,
                height: 1.6,
                fontWeight: FontWeight.w500,
              ),
              strong: GoogleFonts.inter(
                color: AppColors.amareloVale,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          if (hasImage || hasAudio) ...[
            const SizedBox(height: 20),
            // Wrap flexível para garantir zero overflow em telas pequenas
            Wrap(
              alignment: WrapAlignment.center,
              spacing: 12,
              runSpacing: 10,
              children: [
                if (hasImage)
                  _buildMediaButton(
                    icon: FontAwesomeIcons.image,
                    label: 'Ver Imagem',
                    color: AppColors.verdeVale,
                    onPressed: () => _showMediaDialog(
                      context,
                      type: 'image',
                      url: _currentEnigma.imageUrl!,
                    ),
                  ),
                if (hasAudio)
                  _buildMediaButton(
                    icon: FontAwesomeIcons.play,
                    label: 'Ouvir Áudio',
                    color: AppColors.amareloVale,
                    onPressed: () => _showMediaDialog(
                      context,
                      type: 'audio',
                      url: _currentEnigma.audioUrl!,
                    ),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMediaButton({
    required dynamic icon,
    required String label,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return ElevatedButton.icon(
      style: ElevatedButton.styleFrom(
        backgroundColor: color.withValues(alpha: 0.12),
        foregroundColor: color,
        side: BorderSide(color: color, width: 1.5),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 11),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
      ),
      onPressed: onPressed,
      icon: FaIcon(icon, size: 14),
      label: Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
    );
  }

  // --- SEÇÃO DE DICAS & EQUIPAMENTOS ---
  Widget _buildHintSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (_isLoadingHints)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Center(
              child: CircularProgressIndicator(color: AppColors.verdeVale),
            ),
          ),

        if (!_isLoadingHints && _hintsList.isNotEmpty)
          ..._hintsList.map((hint) {
            final isPurchased = _hintsPurchased.contains(hint.objectId);
            final price = hint.get<num>('price')?.toDouble() ?? 0.0;

            if (isPurchased || price <= 0.0) {
              return Container(
                margin: const EdgeInsets.only(bottom: 14),
                child: _buildCard(
                  title: 'Pista Revelada',
                  icon: FontAwesomeIcons.magnifyingGlass,
                  accentColor: AppColors.verdeVale,
                  child: Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      gradient: AppColors.gradienteVerdeVale,
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.verdeVale.withValues(alpha: 0.35),
                          blurRadius: 12,
                        ),
                      ],
                    ),
                    child: ElevatedButton.icon(
                      onPressed: () => _openHintDialog(hint),
                      icon: const FaIcon(
                        FontAwesomeIcons.eye,
                        color: Colors.white,
                        size: 16,
                      ),
                      label: Text(
                        'ABRIR PISTA',
                        style: GoogleFonts.orbitron(
                          color: Colors.white,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.2,
                          fontSize: 13,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        padding: const EdgeInsets.symmetric(vertical: 15),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                    ),
                  ),
                ),
              );
            }

            return Container(
              margin: const EdgeInsets.only(bottom: 14),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: AppColors.amareloVale.withValues(alpha: 0.35),
                ),
                color: AppColors.darkCardColor,
              ),
              child: TextButton.icon(
                onPressed: _isLoading
                    ? null
                    : () async {
                        final bool? confirmed = await _showPurchaseConfirmationDialog(
                          price,
                          type: 'Pista',
                        );
                        if (confirmed == true) {
                          _handleAction('purchaseHint', hintId: hint.objectId);
                        }
                      },
                icon: const FaIcon(
                  FontAwesomeIcons.lightbulb,
                  color: AppColors.amareloVale,
                  size: 16,
                ),
                label: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    'COMPRAR PISTA (R\$ ${price.toStringAsFixed(2)})',
                    style: GoogleFonts.orbitron(
                      color: AppColors.amareloVale,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.0,
                      fontSize: 12,
                    ),
                  ),
                ),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
              ),
            );
          }),

        _buildToolsPurchaseButtons(),
      ],
    );
  }

  // --- EQUIPAMENTOS DE EXPLORAÇÃO COM ZERO OVERFLOW ---
  Widget _buildToolsPurchaseButtons() {
    if (!_currentEnigma.hasMap && !_currentEnigma.hasCompass && !_currentEnigma.hasRadar) {
      return const SizedBox.shrink();
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                const FaIcon(FontAwesomeIcons.toolbox, color: AppColors.cinzaMedio, size: 13),
                const SizedBox(width: 8),
                Text(
                  'EQUIPAMENTOS DE EXPLORAÇÃO',
                  style: GoogleFonts.inter(
                    color: AppColors.cinzaMedio,
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.2,
                  ),
                ),
              ],
            ),
            Text(
              'Toque para alternar',
              style: GoogleFonts.inter(
                color: Colors.white38,
                fontSize: 10,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            if (_currentEnigma.hasMap)
              Expanded(
                child: _buildToolQuickChip(
                  title: 'MAPA',
                  icon: FontAwesomeIcons.mapLocationDot,
                  color: AppColors.verdeVale,
                  isPurchased: _hasMap,
                  price: _currentEnigma.mapPrice,
                  tabIndex: 2,
                  toolKey: 'map',
                ),
              ),
            if (_currentEnigma.hasMap && (_currentEnigma.hasCompass || _currentEnigma.hasRadar))
              const SizedBox(width: 8),
            if (_currentEnigma.hasCompass)
              Expanded(
                child: _buildToolQuickChip(
                  title: 'BÚSSOLA',
                  icon: FontAwesomeIcons.compass,
                  color: AppColors.amareloVale,
                  isPurchased: _hasCompass,
                  price: _compassPrice,
                  tabIndex: 1,
                  toolKey: 'compass',
                ),
              ),
            if ((_currentEnigma.hasMap || _currentEnigma.hasCompass) && _currentEnigma.hasRadar)
              const SizedBox(width: 8),
            if (_currentEnigma.hasRadar)
              Expanded(
                child: _buildToolQuickChip(
                  title: 'RADAR',
                  icon: FontAwesomeIcons.satelliteDish,
                  color: AppColors.verdeValeAlt,
                  isPurchased: _hasRadar,
                  price: _currentEnigma.radarPrice,
                  tabIndex: 1,
                  toolKey: 'radar',
                ),
              ),
          ],
        ),
      ],
    );
  }

  Widget _buildToolQuickChip({
    required String title,
    required dynamic icon,
    required Color color,
    required bool isPurchased,
    required double price,
    required int tabIndex,
    required String toolKey,
  }) {
    return GestureDetector(
      onTap: () async {
        HapticFeedback.selectionClick();
        if (isPurchased) {
          setState(() => _selectedTacticalTab = tabIndex);
          if (toolKey == 'radar') {
            _openRadarDialog();
          }
        } else {
          final bool? confirmed = await _showPurchaseConfirmationDialog(
            price,
            type: title,
          );
          if (confirmed == true) {
            await _handleToolPurchase(toolKey);
            if (mounted) setState(() => _selectedTacticalTab = tabIndex);
          }
        }
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 9, horizontal: 6),
        decoration: BoxDecoration(
          color: isPurchased
              ? color.withValues(alpha: 0.16)
              : AppColors.darkCardColor,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isPurchased ? color : color.withValues(alpha: 0.3),
            width: isPurchased ? 1.4 : 1,
          ),
          boxShadow: isPurchased
              ? [
                  BoxShadow(
                    color: color.withValues(alpha: 0.2),
                    blurRadius: 8,
                  ),
                ]
              : null,
        ),
        // FittedBox evita qualquer overflow dos 3 chips em telas estreitas
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              FaIcon(icon, color: color, size: 12),
              const SizedBox(width: 5),
              Text(
                title,
                style: GoogleFonts.orbitron(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 10.5,
                ),
              ),
              const SizedBox(width: 5),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                decoration: BoxDecoration(
                  color: isPurchased
                      ? AppColors.verdeVale.withValues(alpha: 0.25)
                      : Colors.black.withValues(alpha: 0.6),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  isPurchased ? 'ATIVO' : 'R\$${price.toInt()}',
                  style: GoogleFonts.inter(
                    color: isPurchased ? AppColors.verdeVale : AppColors.cinzaMedio,
                    fontSize: 8.5,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ==========================================================================
  // CENTRAL TÁTICA DE EXPLORAÇÃO & VALIDAÇÃO (QR, MAPA, BÚSSOLA)
  // ==========================================================================
  Widget _buildActionArea() {
    final bool isGpsEnigma = _currentEnigma.type == 'gps';
    final bool isActionReady = (!isGpsEnigma || _isNear) && !_isBlocked;

    return _buildCard(
      title: 'Central Tática de Exploração',
      icon: FontAwesomeIcons.satelliteDish,
      accentColor: AppColors.verdeVale,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 1. Sensor Térmico e Telemetria (Zero Overflow)
          _buildThermalProximityBar(isGpsEnigma),

          const SizedBox(height: 16),

          // 2. Seletor de Modo Tático
          _buildTacticalTabSelector(isActionReady),

          const SizedBox(height: 18),

          // 3. Conteúdo Dinâmico por Aba
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            child: _buildCurrentTacticalContent(isActionReady, isGpsEnigma),
          ),
        ],
      ),
    );
  }

  // --- SENSOR TÉRMICO DE PROXIMIDADE (HOT & COLD COM CORES VALE) ---
  Widget _buildThermalProximityBar(bool isGpsEnigma) {
    if (!isGpsEnigma && _distance == null) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.4),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.verdeVale.withValues(alpha: 0.25)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.verdeVale.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: const FaIcon(
                FontAwesomeIcons.qrcode,
                color: AppColors.verdeVale,
                size: 15,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'ENIGMA DE VALIDAÇÃO FÍSICA',
                    style: GoogleFonts.orbitron(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.8,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Aponte a câmera ou digite o código manual do enigma.',
                    style: GoogleFonts.inter(
                      color: AppColors.cinzaMedio,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    int signalBars = 1;
    String thermalLabel = 'RASTREAMENTO';
    String thermalDetail = 'Calibrando satélites e sensores de precisão...';
    Color thermalColor = AppColors.cinzaMedio;
    dynamic thermalIcon = FontAwesomeIcons.satelliteDish;

    if (_distance != null) {
      if (_distance! <= 25) {
        signalBars = 5;
        thermalLabel = 'ZONA DO ALVO ALCANÇADA!';
        thermalDetail = 'ALVO LOCALIZADO! O QR Code está ao seu redor.';
        thermalColor = AppColors.verdeVale;
        thermalIcon = FontAwesomeIcons.bullseye;
      } else if (_distance! <= 75) {
        signalBars = 4;
        thermalLabel = 'QUENTE! MUITO PRÓXIMO';
        thermalDetail = 'Faltam ${_distance!.toInt()}m. Fique muito atento aos detalhes!';
        thermalColor = AppColors.amareloVale;
        thermalIcon = FontAwesomeIcons.fire;
      } else if (_distance! <= 150) {
        signalBars = 3;
        thermalLabel = 'MORNO • APROXIMANDO-SE';
        thermalDetail = 'Distância estimada: ${_distance!.toInt()} metros';
        thermalColor = AppColors.amareloValeAlt;
        thermalIcon = FontAwesomeIcons.personWalking;
      } else if (_distance! <= 300) {
        signalBars = 2;
        thermalLabel = 'FRIO • MANTENHA A DIREÇÃO';
        thermalDetail = 'Distância aproximada: ${_distance!.toInt()} metros';
        thermalColor = AppColors.cinzaMedio;
        thermalIcon = FontAwesomeIcons.route;
      } else {
        signalBars = 1;
        thermalLabel = 'CONGELANDO • SINAL DISTANTE';
        thermalDetail = 'Distância: ${_distance!.toInt()}m. Desloque-se até o perímetro.';
        thermalColor = AppColors.cinzaMedio.withValues(alpha: 0.7);
        thermalIcon = FontAwesomeIcons.snowflake;
      }
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: thermalColor.withValues(alpha: 0.4), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: thermalColor.withValues(alpha: 0.1),
            blurRadius: 10,
          ),
        ],
      ),
      child: Column(
        children: [
          // Linha de Telemetria com 100% de proteção contra overflow
          Row(
            children: [
              Expanded(
                child: Row(
                  children: [
                    FaIcon(thermalIcon, color: thermalColor, size: 14),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        thermalLabel,
                        style: GoogleFonts.orbitron(
                          color: thermalColor,
                          fontSize: 10.5,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.6,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              // Medidor de Sinal Cibernético (5 barras reativas)
              Row(
                mainAxisSize: MainAxisSize.min,
                children: List.generate(5, (index) {
                  final active = index < signalBars;
                  return Container(
                    margin: const EdgeInsets.symmetric(horizontal: 1.5),
                    width: 4.5,
                    height: 7.0 + (index * 2.5),
                    decoration: BoxDecoration(
                      color: active ? thermalColor : Colors.white12,
                      borderRadius: BorderRadius.circular(2),
                      boxShadow: active
                          ? [
                              BoxShadow(
                                color: thermalColor.withValues(alpha: 0.6),
                                blurRadius: 4,
                              ),
                            ]
                          : null,
                    ),
                  );
                }),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: Text(
                  thermalDetail,
                  style: GoogleFonts.inter(
                    color: Colors.white70,
                    fontSize: 11.5,
                  ),
                ),
              ),
              if (_distance != null) ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
                  decoration: BoxDecoration(
                    color: Colors.black,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: thermalColor.withValues(alpha: 0.5)),
                  ),
                  child: Text(
                    '${_distance!.toStringAsFixed(0)}M',
                    style: GoogleFonts.orbitron(
                      color: thermalColor,
                      fontSize: 11.5,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.8,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  // --- SELETOR DE MODO TÁTICO COM PROTEÇÃO DE LARGURA ---
  Widget _buildTacticalTabSelector(bool isActionReady) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.verdeVale.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          _buildTacticalTabButton(
            index: 0,
            title: 'SCANNER QR',
            icon: FontAwesomeIcons.qrcode,
            badgeColor: isActionReady ? AppColors.verdeVale : AppColors.cinzaMedio,
          ),
          const SizedBox(width: 4),
          _buildTacticalTabButton(
            index: 1,
            title: 'BÚSSOLA',
            icon: FontAwesomeIcons.compass,
            badgeColor: _hasCompass ? AppColors.verdeVale : AppColors.amareloVale,
            isLocked: !_hasCompass && !_hasRadar,
          ),
          const SizedBox(width: 4),
          _buildTacticalTabButton(
            index: 2,
            title: 'MAPA',
            icon: FontAwesomeIcons.mapLocationDot,
            badgeColor: _hasMap ? AppColors.verdeVale : AppColors.amareloVale,
            isLocked: !_hasMap,
          ),
        ],
      ),
    );
  }

  Widget _buildTacticalTabButton({
    required int index,
    required String title,
    required dynamic icon,
    required Color badgeColor,
    bool isLocked = false,
  }) {
    final bool isSelected = _selectedTacticalTab == index;

    return Expanded(
      child: GestureDetector(
        onTap: () {
          HapticFeedback.selectionClick();
          setState(() => _selectedTacticalTab = index);
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 9, horizontal: 4),
          decoration: BoxDecoration(
            color: isSelected
                ? AppColors.verdeVale.withValues(alpha: 0.25)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected ? AppColors.verdeVale : Colors.transparent,
              width: 1.2,
            ),
          ),
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                FaIcon(
                  icon,
                  color: isSelected ? Colors.white : AppColors.cinzaMedio,
                  size: 12,
                ),
                const SizedBox(width: 5),
                Text(
                  title,
                  style: GoogleFonts.orbitron(
                    color: isSelected ? Colors.white : AppColors.cinzaMedio,
                    fontSize: 9.5,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                    letterSpacing: 0.6,
                  ),
                ),
                const SizedBox(width: 4),
                if (isLocked)
                  const FaIcon(
                    FontAwesomeIcons.lock,
                    color: AppColors.amareloVale,
                    size: 8.5,
                  )
                else
                  Container(
                    width: 5.5,
                    height: 5.5,
                    decoration: BoxDecoration(
                      color: badgeColor,
                      shape: BoxShape.circle,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // --- CONTEÚDO DA ABA ATIVA ---
  Widget _buildCurrentTacticalContent(bool isActionReady, bool isGpsEnigma) {
    switch (_selectedTacticalTab) {
      case 1:
        return _buildCompassTab();
      case 2:
        return _buildMapTab();
      case 0:
      default:
        return _buildQrScannerTab(isActionReady, isGpsEnigma);
    }
  }

  // --- ABA 0: SCANNER QR HOLOGRÁFICO ---
  Widget _buildQrScannerTab(bool isActionReady, bool isGpsEnigma) {
    return Column(
      key: const ValueKey('qr_scanner_tab'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Viewfinder Holográfico Simulado
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.45),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isActionReady
                  ? AppColors.verdeVale.withValues(alpha: 0.4)
                  : Colors.white12,
              width: 1.4,
            ),
          ),
          child: Column(
            children: [
              // Retículo central com pulso e cantoneiras
              Container(
                width: 105,
                height: 105,
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.6),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isActionReady ? AppColors.verdeVale : Colors.white24,
                    width: 1.4,
                  ),
                ),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    CustomPaint(
                      size: const Size(105, 105),
                      painter: ScannerCornersPainter(
                        color: isActionReady ? AppColors.verdeVale : Colors.white30,
                        cornerLength: 15,
                        strokeWidth: 2.2,
                      ),
                    ),
                    FaIcon(
                      isActionReady
                          ? FontAwesomeIcons.qrcode
                          : FontAwesomeIcons.locationCrosshairs,
                      color: isActionReady ? AppColors.verdeVale : AppColors.amareloVale,
                      size: 34,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 14),

              // Alerta de Alcance ou Status Pronto
              if (isGpsEnigma && !_isNear) ...[
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppColors.amareloVale.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.amareloVale.withValues(alpha: 0.4)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const FaIcon(
                        FontAwesomeIcons.triangleExclamation,
                        color: AppColors.amareloVale,
                        size: 13,
                      ),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          _distance != null
                              ? 'Aproxime-se a menos de 100m (Faltam ${_distance!.toInt()}m)'
                              : 'Buscando sinal GPS para autorizar escaneamento',
                          style: GoogleFonts.orbitron(
                            color: AppColors.amareloVale,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                TextButton.icon(
                  onPressed: () {
                    HapticFeedback.selectionClick();
                    setState(() => _selectedTacticalTab = 1);
                  },
                  icon: const FaIcon(FontAwesomeIcons.compass, size: 13),
                  label: Text(
                    'ABRIR BÚSSOLA PARA TE GUIAR',
                    style: GoogleFonts.orbitron(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1,
                    ),
                  ),
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.amareloVale,
                  ),
                ),
              ] else ...[
                Text(
                  'SISTEMA DE MIRA PRONTO',
                  style: GoogleFonts.orbitron(
                    color: AppColors.verdeVale,
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Aponte a câmera para o QR Code físico para validar.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                    color: AppColors.cinzaMedio,
                    fontSize: 12,
                  ),
                ),
              ],
            ],
          ),
        ),

        const SizedBox(height: 14),

        // Botão Principal de Escaneamento (Gradiente Verde-Vale)
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            gradient: isActionReady
                ? AppColors.gradienteVerdeVale
                : const LinearGradient(
                    colors: [Color(0xFF384346), Color(0xFF1E282A)],
                  ),
            boxShadow: isActionReady
                ? [
                    BoxShadow(
                      color: AppColors.verdeVale.withValues(alpha: 0.35),
                      blurRadius: 16,
                      spreadRadius: 1,
                    ),
                  ]
                : null,
          ),
          child: ElevatedButton.icon(
            onPressed: isActionReady
                ? () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => ScannerScreen(
                          onScan: (scannedCode) => _handleAction(
                            'validateCode',
                            code: scannedCode,
                          ),
                        ),
                      ),
                    );
                  }
                : null,
            icon: FaIcon(
              _isBlocked ? FontAwesomeIcons.clock : FontAwesomeIcons.camera,
              color: isActionReady ? Colors.white : Colors.grey,
              size: 16,
            ),
            label: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                _isBlocked
                    ? 'COOLDOWN ATIVO'
                    : (isActionReady ? 'ESCANEAR QR CODE AGORA' : 'APROXIME-SE DO ALVO'),
                style: GoogleFonts.orbitron(
                  fontSize: 13,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.2,
                  color: isActionReady ? Colors.white : Colors.grey,
                ),
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.transparent,
              shadowColor: Colors.transparent,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
              minimumSize: const Size(double.infinity, 50),
            ),
          ),
        ),

        const SizedBox(height: 8),

        // Ação Secundária: Entrada Manual de Código
        Center(
          child: TextButton.icon(
            onPressed: () => _openManualCodeSheet(context),
            icon: const FaIcon(
              FontAwesomeIcons.keyboard,
              color: AppColors.amareloVale,
              size: 13,
            ),
            label: Text(
              'DIGITAR CÓDIGO MANUALMENTE',
              style: GoogleFonts.orbitron(
                color: AppColors.amareloVale,
                fontSize: 11,
                fontWeight: FontWeight.w800,
                letterSpacing: 1,
              ),
            ),
          ),
        ),
      ],
    );
  }

  // --- ABA 1: BÚSSOLA & RADAR 360° ---
  Widget _buildCompassTab() {
    final bool isUnlocked = _hasCompass || _hasRadar;
    final targetLat = _destinationLocation?['latitude'] ?? _currentEnigma.location?.latitude;
    final targetLng = _destinationLocation?['longitude'] ?? _currentEnigma.location?.longitude;

    if (targetLat == null || targetLng == null) {
      return Container(
        key: const ValueKey('compass_tab_no_coords'),
        padding: const EdgeInsets.all(22),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.4),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white12),
        ),
        child: Column(
          children: [
            const FaIcon(FontAwesomeIcons.compass, color: AppColors.cinzaMedio, size: 34),
            const SizedBox(height: 10),
            Text(
              'Coordenadas Não Requeridas',
              style: GoogleFonts.orbitron(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Este enigma não necessita de sensor direcional. Utilize a aba Scanner QR para validar.',
              style: GoogleFonts.inter(color: AppColors.cinzaMedio, fontSize: 12),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    if (!isUnlocked) {
      return _buildLockedToolCard(
        key: const ValueKey('compass_tab_locked'),
        title: 'BÚSSOLA DIRECIONAL 360°',
        icon: FontAwesomeIcons.compass,
        accentColor: AppColors.amareloVale,
        description:
            'Ativa o radar 360° em tempo real com travamento de mira (Lock-on) e odômetro digital que te guia até o ponto exato.',
        price: _compassPrice,
        toolKey: 'compass',
      );
    }

    return Container(
      key: const ValueKey('compass_tab_unlocked'),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppColors.amareloVale.withValues(alpha: 0.4),
          width: 1.4,
        ),
      ),
      child: Column(
        children: [
          CompassWidget(
            targetLatitude: targetLat,
            targetLongitude: targetLng,
            destinationLongitude: targetLng,
            destinationLatitude: targetLat,
            durationSeconds: _compassRemainingSeconds ?? _compassDuration,
            isCompact: true,
            onTick: (int remaining) {
              _compassRemainingSeconds = remaining;
            },
            onTimeUp: () {
              setState(() {
                _hasCompass = false;
                _compassRemainingSeconds = null;
              });
              _handleAction('consumeTool', toolType: 'compass');
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('O tempo da bússola acabou!'),
                  backgroundColor: AppColors.amareloVale,
                ),
              );
            },
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: _openCompassDialog,
            icon: const FaIcon(FontAwesomeIcons.upRightAndDownLeftFromCenter, size: 12),
            label: Text(
              'EXPANDIR RADAR EM TELA CHEIA',
              style: GoogleFonts.orbitron(
                fontSize: 10.5,
                fontWeight: FontWeight.bold,
                letterSpacing: 1,
              ),
            ),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.amareloVale,
              side: const BorderSide(color: AppColors.amareloVale, width: 1.2),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            ),
          ),
        ],
      ),
    );
  }

  // --- ABA 2: MAPA TÁTICO ---
  Widget _buildMapTab() {
    final bool isUnlocked = _hasMap;
    final targetLat = _destinationLocation?['latitude'] ?? _currentEnigma.location?.latitude;
    final targetLng = _destinationLocation?['longitude'] ?? _currentEnigma.location?.longitude;

    if (targetLat == null || targetLng == null) {
      return Container(
        key: const ValueKey('map_tab_no_coords'),
        padding: const EdgeInsets.all(22),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.4),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white12),
        ),
        child: Column(
          children: [
            const FaIcon(FontAwesomeIcons.mapLocationDot, color: AppColors.cinzaMedio, size: 34),
            const SizedBox(height: 10),
            Text(
              'Mapa Não Requerido',
              style: GoogleFonts.orbitron(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Este enigma não necessita de mapa perimétrico. Utilize a aba Scanner QR para validar.',
              style: GoogleFonts.inter(color: AppColors.cinzaMedio, fontSize: 12),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    if (!isUnlocked) {
      return _buildLockedToolCard(
        key: const ValueKey('map_tab_locked'),
        title: 'MAPA TOPOGRÁFICO DE SATÉLITE',
        icon: FontAwesomeIcons.mapLocationDot,
        accentColor: AppColors.verdeVale,
        description:
            'Revela o perímetro geográfico com raio aproximado no mapa interativo com suporte a visão satélite e noturna.',
        price: _currentEnigma.mapPrice,
        toolKey: 'map',
      );
    }

    return Container(
      key: const ValueKey('map_tab_unlocked'),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppColors.verdeVale.withValues(alpha: 0.4),
          width: 1.4,
        ),
      ),
      child: MapRadiusWidget(
        destinationLatitude: targetLat,
        destinationLongitude: targetLng,
        isCompact: true,
        onExpand: _openMapDialog,
      ),
    );
  }

  // --- CARD DE EQUIPAMENTO BLOQUEADO ---
  Widget _buildLockedToolCard({
    Key? key,
    required String title,
    required dynamic icon,
    required Color accentColor,
    required String description,
    required double price,
    required String toolKey,
  }) {
    return Container(
      key: key,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: accentColor.withValues(alpha: 0.35),
          width: 1.4,
        ),
      ),
      child: Column(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: accentColor.withValues(alpha: 0.15),
              border: Border.all(color: accentColor.withValues(alpha: 0.6), width: 1.5),
            ),
            child: Center(
              child: FaIcon(icon, color: accentColor, size: 22),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            title,
            style: GoogleFonts.orbitron(
              color: Colors.white,
              fontSize: 12.5,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.2,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 6),
          Text(
            description,
            style: GoogleFonts.inter(
              color: AppColors.cinzaMedio,
              fontSize: 12,
              height: 1.4,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              gradient: LinearGradient(
                colors: [accentColor, accentColor.withValues(alpha: 0.8)],
              ),
              boxShadow: [
                BoxShadow(
                  color: accentColor.withValues(alpha: 0.35),
                  blurRadius: 12,
                ),
              ],
            ),
            child: ElevatedButton.icon(
              onPressed: _isLoading
                  ? null
                  : () async {
                      final bool? confirmed = await _showPurchaseConfirmationDialog(
                        price,
                        type: title,
                      );
                      if (confirmed == true) _handleToolPurchase(toolKey);
                    },
              icon: const FaIcon(FontAwesomeIcons.lockOpen, size: 13, color: Colors.black),
              label: Text(
                'DESBLOQUEAR (R\$ ${price.toInt()})',
                style: GoogleFonts.orbitron(
                  color: Colors.black,
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                shadowColor: Colors.transparent,
                padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- MODAL DE ENTRADA MANUAL DE CÓDIGO (PROTEGIDO CONTRA TECLADO) ---
  void _openManualCodeSheet(BuildContext context) {
    final textController = TextEditingController();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.darkCardColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        side: BorderSide(color: AppColors.verdeVale, width: 1.2),
      ),
      builder: (modalCtx) {
        return SingleChildScrollView(
          physics: const ClampingScrollPhysics(),
          child: Padding(
            padding: EdgeInsets.only(
              left: 24,
              right: 24,
              top: 24,
              bottom: MediaQuery.of(modalCtx).viewInsets.bottom + 24,
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
                          'VALIDAÇÃO MANUAL',
                          style: GoogleFonts.orbitron(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 14.5,
                            letterSpacing: 1.2,
                          ),
                        ),
                      ],
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: AppColors.cinzaMedio),
                      onPressed: () => Navigator.of(modalCtx).pop(),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Digite o código gravado no enigma físico encontrado no local:',
                  style: GoogleFonts.inter(color: AppColors.cinzaMedio, fontSize: 13),
                ),
                const SizedBox(height: 18),
                TextField(
                  controller: textController,
                  autofocus: true,
                  textCapitalization: TextCapitalization.characters,
                  style: GoogleFonts.orbitron(
                    color: AppColors.verdeVale,
                    fontSize: 18,
                    letterSpacing: 2,
                    fontWeight: FontWeight.bold,
                  ),
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: Colors.black.withValues(alpha: 0.6),
                    hintText: 'EX: ENIGMA-01',
                    hintStyle: GoogleFonts.orbitron(color: Colors.white24, fontSize: 13),
                    prefixIcon: const Icon(Icons.tag, color: AppColors.verdeVale),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: const BorderSide(color: AppColors.verdeVale),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide(
                        color: AppColors.verdeVale.withValues(alpha: 0.35),
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: const BorderSide(color: AppColors.verdeVale, width: 2),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () {
                    final code = textController.text.trim();
                    if (code.isNotEmpty) {
                      Navigator.of(modalCtx).pop();
                      _handleAction('validateCode', code: code);
                    }
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
                    'CONFIRMAR E VALIDAR',
                    style: GoogleFonts.orbitron(
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
}

// ============================================================================
// 3. AUDIO DIALOG (REPRODUTOR MODERNO COM PALETA VALE)
// ============================================================================
class _AudioDialog extends StatefulWidget {
  final String url;
  const _AudioDialog({required this.url});

  @override
  State<_AudioDialog> createState() => _AudioDialogState();
}

class _AudioDialogState extends State<_AudioDialog> {
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
          color: AppColors.amareloVale.withValues(alpha: 0.4),
          width: 1.5,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  FaIcon(FontAwesomeIcons.music, color: AppColors.amareloVale, size: 16),
                  SizedBox(width: 10),
                  Text(
                    'Pista em Áudio',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
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
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.black,
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
                  style: const TextStyle(color: AppColors.cinzaMedio, fontSize: 12),
                ),
                Text(
                  _formatDuration(_duration),
                  style: const TextStyle(color: AppColors.cinzaMedio, fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// 4. DASHED RECT PAINTER
// ============================================================================
class DashedRectPainter extends CustomPainter {
  final Color color;
  final double strokeWidth;
  final double gap;

  DashedRectPainter({
    this.color = Colors.white,
    this.strokeWidth = 1.0,
    this.gap = 5.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;

    final path = Path()
      ..addRRect(RRect.fromRectAndRadius(
          Rect.fromLTWH(0, 0, size.width, size.height),
          const Radius.circular(16)));

    final dashPath = Path();
    for (final metric in path.computeMetrics()) {
      double distance = 0;
      while (distance < metric.length) {
        dashPath.addPath(
            metric.extractPath(distance, distance + gap), Offset.zero);
        distance += gap * 2;
      }
    }
    canvas.drawPath(dashPath, paint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}

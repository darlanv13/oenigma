import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:async';
import 'dart:math' show cos, sqrt, asin, pi, sin;
import 'package:parse_server_sdk_flutter/parse_server_sdk_flutter.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:lottie/lottie.dart' hide Marker;
import 'package:mobile_scanner/mobile_scanner.dart';

import 'package:oenigma/features/certificate/screens/winner_certificate_screen.dart';
import 'package:oenigma/core/widgets/dialogs/completion_dialog.dart';
import 'package:oenigma/core/widgets/dialogs/cooldown_dialog.dart';
import 'package:oenigma/core/models/enigma_model.dart';
import 'package:oenigma/core/models/event_model.dart';
import 'package:oenigma/core/models/phase_model.dart';
import 'package:oenigma/features/enigma/widgets/compass_widget.dart';
import 'package:oenigma/features/enigma/widgets/map_radius_widget.dart';
import 'package:oenigma/features/enigma/repositories/enigma_repository.dart';

import 'package:oenigma/features/event/repositories/event_repository.dart';
import 'package:oenigma/core/utils/app_colors.dart';

import 'package:oenigma/features/wallet/screens/wallet_screen.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

// --- TELA DE SCANNER ---
class ScannerScreen extends StatefulWidget {
  final Function(String) onScan;
  const ScannerScreen({super.key, required this.onScan});

  @override
  State<ScannerScreen> createState() => _ScannerScreenState();
}

class _ScannerScreenState extends State<ScannerScreen> {
  final MobileScannerController _scannerController = MobileScannerController();
  String? _detectedQRCode;

  @override
  void dispose() {
    _scannerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        title: const Text(
          'Aponte para o QR Code',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color(0xFF1E1E1E),
        elevation: 0,
      ),
      body: Stack(
        alignment: Alignment.center,
        children: [
          MobileScanner(
            controller: _scannerController,
            onDetect: (capture) {
              if (_detectedQRCode == null) {
                final List<Barcode> barcodes = capture.barcodes;
                if (barcodes.isNotEmpty && barcodes.first.rawValue != null) {
                  setState(() {
                    _detectedQRCode = barcodes.first.rawValue;
                  });
                  _scannerController.stop();
                }
              }
            },
          ),
          if (_detectedQRCode != null) _buildConfirmationOverlay(),
        ],
      ),
    );
  }

  Widget _buildConfirmationOverlay() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.all(32),
          width: MediaQuery.of(context).size.width * 0.85,
          decoration: BoxDecoration(
            color: const Color(0xFF1E1E1E).withValues(alpha: 0.9),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: const Color(0xFFFFD54F).withValues(alpha: 0.5),
              width: 2,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.6),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const FaIcon(
                FontAwesomeIcons.qrcode,
                color: Color(0xFFFFD54F),
                size: 40,
              ),
              const SizedBox(height: 16),
              const Text(
                'Código Detectado',
                style: TextStyle(
                  color: Color(0xFFFFD54F),
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.0,
                ),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF121212),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  _detectedQRCode!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    widget.onScan(_detectedQRCode!);
                    Navigator.of(context).pop();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: const Text(
                    'CONFIRMAR',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: () {
                  setState(() => _detectedQRCode = null);
                  _scannerController.start();
                },
                child: const Text(
                  'Escanear Novamente',
                  style: TextStyle(
                    color: Colors.grey,
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
}

// --- TELA DE ENIGMA PRINCIPAL ---
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
  final TextEditingController _codeController = TextEditingController();
  final EnigmaRepository _enigmaRepository = EnigmaRepository();
  final EventRepository _eventService = EventRepository();

  bool _isLoading = false;
  bool _canBuyHint = false;
  StreamSubscription<Position>? _locationSubscription;
  bool _isNear = false;
  double? _distance;
  bool _isHintVisible = false;
  Map<String, dynamic>? _hintData;
  bool _isBlocked = false;
  Timer? _statusPollTimer;
  late EnigmaModel _currentEnigma;
  bool _hasCompass = false;
  bool _hasMap = false;
  Map<String, double>? _destinationLocation;

  // Animation Controller for Shake Effect
  late AnimationController _shakeController;
  late Animation<double> _shakeAnimation;

  @override
  void initState() {
    super.initState();
    _currentEnigma = widget.initialEnigma;

    _shakeController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );

    _shakeAnimation = Tween<double>(begin: 0.0, end: 10.0).animate(
      CurvedAnimation(parent: _shakeController, curve: Curves.elasticIn),
    );

    _shakeController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _shakeController.reset();
      }
    });

    _resetEnigmaState();
  }

  Future<void> _resetEnigmaState() async {
    _locationSubscription?.cancel();
    _statusPollTimer?.cancel();
    setState(() {
      _codeController.clear();
      _isHintVisible = false;
      _canBuyHint = false;
      _hintData = null;
      _distance = null;
      _isNear = false;
      _isBlocked = false;
      _isLoading = true;
      _hasCompass = false;
      _hasMap = false;
      _destinationLocation = null;
    });

    try {
      if (_currentEnigma.type == 'foto' || _currentEnigma.type == 'gps') {
        await _initializeGpsListener();
      }
      if (mounted) {
        await _fetchInitialStatus();
      }
    } catch (e) {
      debugPrint("Erro na inicialização do enigma: $e");
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  void dispose() {
    _codeController.dispose();
    _locationSubscription?.cancel();
    _statusPollTimer?.cancel();
    _shakeController.dispose();
    super.dispose();
  }

  void _triggerShake() {
    _shakeController.forward();
  }

  void _handleCooldown(String cooldownUntilStr) {
    final cooldownUntil = DateTime.parse(cooldownUntilStr);
    if (cooldownUntil.isAfter(DateTime.now())) {
      setState(() => _isBlocked = true);
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => CooldownDialog(
          cooldownUntil: cooldownUntil,
          onCooldownFinished: () {
            if (mounted) setState(() => _isBlocked = false);
          },
        ),
      );
    }
  }

  Future<void> _fetchInitialStatus() async {
    try {
      final result = await _enigmaRepository.callEnigmaFunction('getStatus', {
        'eventId': widget.event.id,
        'phaseOrder': widget.phase.order,
        'enigmaId': _currentEnigma.id,
      });
      if (mounted) {
        final statusData = Map<String, dynamic>.from(result.result);
        setState(() {
          _isHintVisible = statusData['isHintVisible'] ?? false;
          _hintData = statusData['hintData'] != null
              ? Map<String, dynamic>.from(statusData['hintData'])
              : null;
          _canBuyHint = statusData['canBuyHint'] ?? false;
          _isBlocked = statusData['isBlocked'] ?? false;
          _hasCompass = statusData['hasCompass'] ?? false;
          _hasMap = statusData['hasMap'] ?? false;
          if (statusData['destinationLocation'] != null) {
            _destinationLocation = {
              'latitude': (statusData['destinationLocation']['latitude'] as num)
                  .toDouble(),
              'longitude':
                  (statusData['destinationLocation']['longitude'] as num)
                      .toDouble(),
            };
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

  void _showInsufficientFundsDialog() {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E1E),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            FaIcon(FontAwesomeIcons.wallet, color: Color(0xFFFFD54F), size: 20),
            SizedBox(width: 10),
            Text(
              'Saldo Insuficiente',
              style: TextStyle(
                color: Color(0xFFFFD54F),
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        content: const Text(
          'Você não tem saldo suficiente para comprar este item. Deseja adicionar créditos?',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text(
              'AGORA NÃO',
              style: TextStyle(color: Colors.grey),
            ),
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
              backgroundColor: const Color(0xFFFFD54F),
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
        backgroundColor: const Color(0xFF1E1E1E),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            FaIcon(FontAwesomeIcons.store, color: Color(0xFFFFD54F), size: 20),
            SizedBox(width: 10),
            Text(
              'Confirmar Compra',
              style: TextStyle(
                color: Color(0xFFFFD54F),
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        content: Text(
          'Comprar $type por R\$ ${cost.toStringAsFixed(2)}?\n\nEste valor será deduzido do seu saldo atual.',
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('CANCELAR', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFFD54F),
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
            backgroundColor: const Color(0xFF1E1E1E),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
            ),
            title: Text(
              toolType == 'compass' ? 'Bússola Ativada!' : 'Mapa Ativado!',
              style: TextStyle(
                color: toolType == 'compass'
                    ? Colors.greenAccent
                    : Colors.blueAccent,
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
                  size: 60,
                  color: toolType == 'compass'
                      ? Colors.greenAccent
                      : Colors.blueAccent,
                ),
                const SizedBox(height: 20),
                Text(
                  toolType == 'compass'
                      ? '1. O triângulo vermelho é você.\n2. O ponto brilhante é o alvo.\n3. Gire o celular para alinhar a direção.\n4. A distância digital mostrará quantos metros faltam.'
                      : '1. Você verá um círculo azul desenhado no mapa.\n2. O seu alvo está em algum lugar dentro deste raio.\n3. Dirija-se até a área e procure atentamente.',
                  style: const TextStyle(color: Colors.white70, height: 1.5),
                ),
              ],
            ),
            actions: [
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFFD54F),
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 16),
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
          SnackBar(
            content: Text(e.message ?? "Ocorreu um erro."),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _handleAction(String action, {String? code}) async {
    setState(() => _isLoading = true);
    try {
      final result = await _enigmaRepository.callEnigmaFunction(action, {
        'eventId': widget.event.id,
        'phaseOrder': widget.phase.order,
        'enigmaId': _currentEnigma.id,
        if (code != null) 'code': code,
      });

      if (!mounted) return;

      final data = Map<String, dynamic>.from(result.result);
      final success = data['success'] ?? false;

      if (success) {
        if (action == 'purchaseHint') {
          setState(() {
            _isHintVisible = true;
            _hintData = Map<String, dynamic>.from(data['hint']);
          });
        } else if (action == 'validateCode') {
          final nextStep = data['nextStep'] != null
              ? Map<String, dynamic>.from(data['nextStep'])
              : null;
          if (nextStep == null) return;

          switch (nextStep['type']) {
            case 'event_complete':
              final double prizeWon =
                  (nextStep['prizeWon'] as num?)?.toDouble() ?? 0.0;
              final List<PhaseModel> allPhases = await _eventService
                  .getPhasesForEvent(widget.event.id);
              if (mounted) {
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(
                    builder: (context) => WinnerCertificateScreen(
                      event: widget.event,
                      prizeWon: prizeWon,
                      allPhases: allPhases,
                    ),
                  ),
                );
              }
              break;

            case 'next_enigma':
              final nextEnigma = EnigmaModel.fromMap(
                Map<String, dynamic>.from(nextStep['enigmaData']),
              );
              await showDialog(
                context: context,
                barrierDismissible: false,
                builder: (dialogContext) => Dialog(
                  backgroundColor: const Color(0xFF1E1E1E),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(32.0),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Lottie.asset(
                          'assets/animations/check.json',
                          height: 130,
                          repeat: false,
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'Enigma Resolvido!',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w900,
                            color: Colors.greenAccent,
                          ),
                        ),
                        const SizedBox(height: 24),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                            onPressed: () => Navigator.of(dialogContext).pop(),
                            child: const Text(
                              'PRÓXIMO DESAFIO',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.white,
                                fontWeight: FontWeight.w900,
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
            SnackBar(content: Text(message), backgroundColor: Colors.redAccent),
          );
        }
      }
    } on ParseError catch (e) {
      if (e.message?.contains('saldo') == true ||
          e.message?.contains('Saldo insuficiente') == true) {
        _showInsufficientFundsDialog();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.message ?? 'Erro desconhecido.'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
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

    _locationSubscription =
        Geolocator.getPositionStream(
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
                backgroundColor: Colors.redAccent,
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        title: Text(
          widget.phase.id == 'find_and_win'
              ? "Enigma Rápido"
              : "Fase ${widget.phase.order} - Enigma ${widget.phase.enigmas.indexOf(_currentEnigma) + 1}",
          style: const TextStyle(
            fontWeight: FontWeight.w900,
            color: Color(0xFFFFD54F),
          ),
        ),
        centerTitle: true,
        backgroundColor: const Color(0xFF1E1E1E),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: _isLoading && !_isHintVisible
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFFFFD54F)),
            )
          : SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildEnigmaCard(),
                  const SizedBox(height: 16),
                  _buildHintSection(),
                  const SizedBox(height: 16),
                  _buildActionArea(),
                  const SizedBox(height: 40),
                ],
              ),
            ),
    );
  }

  Widget _buildCard({
    required String title,
    required Widget child,
    dynamic icon,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.4),
            blurRadius: 15,
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
                FaIcon(icon, color: const Color(0xFFFFD54F), size: 16),
                const SizedBox(width: 10),
              ],
              Text(
                title.toUpperCase(),
                style: const TextStyle(
                  color: Colors.grey,
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
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

  Widget _buildEnigmaCard() {
    return _buildCard(
      title: 'Desafio Atual',
      icon: FontAwesomeIcons.scroll,
      child: _buildEnigmaContent(),
    );
  }

  Widget _buildEnigmaContent() {
    switch (_currentEnigma.type) {
      case 'photo_location':
      case 'text':
        return Column(
          children: [
            if (_currentEnigma.imageUrl != null &&
                _currentEnigma.imageUrl!.isNotEmpty)
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Image.network(
                  _currentEnigma.imageUrl!,
                  fit: BoxFit.cover,
                ),
              )
            else if (_currentEnigma.type != 'text')
              Lottie.asset('assets/animations/no_enigma.json', height: 80),

            if (_currentEnigma.imageUrl != null) const SizedBox(height: 16),

            Text(
              _currentEnigma.instruction,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 16,
                color: Colors.white,
                fontWeight: FontWeight.w500,
                height: 1.5,
              ),
            ),
          ],
        );
      case 'foto':
      case 'gps':
      case 'qrcode':
        return const SizedBox.shrink();
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildActionArea() {
    if (_currentEnigma.type == 'foto' ||
        _currentEnigma.type == 'gps' ||
        _currentEnigma.type == 'qrcode') {
      return _buildQrCodeGpsCard();
    }
    return _buildCodeInputSection();
  }

  Widget _buildQrCodeGpsCard() {
    final bool isActionReady =
        (_currentEnigma.type == 'qrcode' || _isNear) && !_isBlocked;

    return _buildCard(
      title: 'Missão de Campo',
      icon: FontAwesomeIcons.mapLocationDot,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          if (_currentEnigma.imageUrl != null &&
              _currentEnigma.imageUrl!.isNotEmpty)
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Image.network(_currentEnigma.imageUrl!, fit: BoxFit.cover),
            )
          else
            Lottie.asset('assets/animations/no_enigma.json', height: 80),

          const SizedBox(height: 16),

          Text(
            _currentEnigma.instruction,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 16,
              color: Colors.white,
              height: 1.5,
              fontWeight: FontWeight.w500,
            ),
          ),

          const SizedBox(height: 20),

          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            decoration: BoxDecoration(
              color: const Color(0xFF121212),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
            ),
            child: _distance == null
                ? const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.grey,
                        ),
                      ),
                      SizedBox(width: 12),
                      Text(
                        "Buscando satélites...",
                        style: TextStyle(
                          color: Colors.grey,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      FaIcon(
                        _isNear
                            ? FontAwesomeIcons.locationCrosshairs
                            : FontAwesomeIcons.route,
                        color: _isNear
                            ? Colors.greenAccent
                            : const Color(0xFFFFD54F),
                        size: 16,
                      ),
                      const SizedBox(width: 10),
                      Text(
                        _isNear
                            ? "VOCÊ CHEGOU!"
                            : "Distância: ${_distance!.toStringAsFixed(0)} metros",
                        style: TextStyle(
                          fontSize: 16,
                          color: _isNear
                              ? Colors.greenAccent
                              : const Color(0xFFFFD54F),
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ],
                  ),
          ),

          const SizedBox(height: 24),

          if (_currentEnigma.type == 'qrcode' ||
              _currentEnigma.type == 'foto' ||
              _currentEnigma.type == 'gps')
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(30),
                gradient: isActionReady
                    ? const LinearGradient(
                        colors: [Color(0xFF4CAF50), Color(0xFF2E7D32)],
                      )
                    : const LinearGradient(
                        colors: [Color(0xFF424242), Color(0xFF212121)],
                      ),
                boxShadow: [
                  if (isActionReady)
                    BoxShadow(
                      color: Colors.green.withValues(alpha: 0.4),
                      blurRadius: 15,
                      spreadRadius: 2,
                    ),
                ],
              ),
              child: ElevatedButton.icon(
                onPressed: isActionReady
                    ? () {
                        if (_currentEnigma.type == 'gps') {
                          _handleAction('validateCode', code: 'gps');
                        } else {
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
                      }
                    : null,
                icon: FaIcon(
                  _isBlocked
                      ? FontAwesomeIcons.clock
                      : (_currentEnigma.type == 'gps'
                            ? FontAwesomeIcons.locationDot
                            : FontAwesomeIcons.qrcode),
                  color: isActionReady ? Colors.white : Colors.grey,
                  size: 20,
                ),
                label: Text(
                  _isBlocked
                      ? 'COOLDOWN ATIVO'
                      : (isActionReady
                            ? (_currentEnigma.type == 'gps'
                                  ? 'CONFIRMAR LOCAL'
                                  : 'ESCANEAR CÓDIGO')
                            : 'APROXIME-SE DO ALVO'),
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.0,
                    color: isActionReady ? Colors.white : Colors.grey,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                  minimumSize: const Size(double.infinity, 50),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildHintSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (_isHintVisible && _hintData != null)
          _buildCard(
            title: 'Pista Encontrada',
            icon: FontAwesomeIcons.magnifyingGlass,
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(30),
                gradient: const LinearGradient(
                  colors: [Color(0xFFFFD54F), Color(0xFFF57F17)],
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFFFD54F).withValues(alpha: 0.3),
                    blurRadius: 15,
                  ),
                ],
              ),
              child: ElevatedButton.icon(
                onPressed: _openHintDialog,
                icon: const FaIcon(
                  FontAwesomeIcons.eye,
                  color: Colors.black,
                  size: 18,
                ),
                label: const Text(
                  'ABRIR PISTA',
                  style: TextStyle(
                    color: Colors.black,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.2,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
              ),
            ),
          ),

        if (!_isHintVisible && _canBuyHint) _buildHintPurchaseButton(),
        if (_currentEnigma.type == 'foto' || _currentEnigma.type == 'gps')
          _buildToolsPurchaseButtons(),
      ],
    );
  }

  void _openHintDialog() {
    if (_hintData == null) return;
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: const Color(0xFF1E1E1E),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Row(
                    children: [
                      FaIcon(
                        FontAwesomeIcons.lightbulb,
                        color: Color(0xFFFFD54F),
                      ),
                      SizedBox(width: 12),
                      Text(
                        'Pista',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.grey),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              _buildHintDialogContent(),
            ],
          ),
        ),
      ),
    );
  }

  void _openMapDialog() {
    if (_destinationLocation == null) return;
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: const Color(0xFF1E1E1E),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: BorderSide(
            color: Colors.blueAccent.withValues(alpha: 0.5),
            width: 2,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Row(
                    children: [
                      FaIcon(
                        FontAwesomeIcons.mapLocationDot,
                        color: Colors.blueAccent,
                      ),
                      SizedBox(width: 12),
                      Text(
                        'Mapa Interativo',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.grey),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: MapRadiusWidget(
                  destinationLatitude: _destinationLocation!['latitude']!,
                  destinationLongitude: _destinationLocation!['longitude']!,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _openCompassDialog() {
    if (_destinationLocation == null) return;
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: const Color(0xFF1E1E1E),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: BorderSide(
            color: Colors.greenAccent.withValues(alpha: 0.5),
            width: 2,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Row(
                    children: [
                      FaIcon(
                        FontAwesomeIcons.compass,
                        color: Colors.greenAccent,
                      ),
                      SizedBox(width: 12),
                      Text(
                        'Bússola Digital',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.grey),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              CompassWidget(
                targetLatitude: _destinationLocation!['latitude']!,
                targetLongitude: _destinationLocation!['longitude']!,
                destinationLongitude: _destinationLocation!['longitude']!,
                destinationLatitude: _destinationLocation!['latitude']!,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHintPurchaseButton() {
    final hintCosts = {1: 5, 2: 10, 3: 15};
    final cost = hintCosts[widget.phase.order] ?? 5; // Default fallback

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: const Color(0xFFFFD54F).withValues(alpha: 0.3),
        ),
        color: const Color(0xFFFFD54F).withValues(alpha: 0.05),
      ),
      child: TextButton.icon(
        onPressed: _isLoading
            ? null
            : () async {
                final bool? confirmed = await _showPurchaseConfirmationDialog(
                  cost.toDouble(),
                  type: 'Dica',
                );
                if (confirmed == true) _handleAction('purchaseHint');
              },
        icon: const FaIcon(
          FontAwesomeIcons.lightbulb,
          color: Color(0xFFFFD54F),
          size: 18,
        ),
        label: Text(
          'COMPRAR PISTA (R\$ ${cost.toStringAsFixed(2)})',
          style: const TextStyle(
            color: Color(0xFFFFD54F),
            fontWeight: FontWeight.w900,
            letterSpacing: 1.0,
          ),
        ),
        style: TextButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 20),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
        ),
      ),
    );
  }

  Widget _buildToolsPurchaseButtons() {
    if (_currentEnigma.type != 'foto' && _currentEnigma.type != 'gps')
      return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Row(
          children: [
            FaIcon(FontAwesomeIcons.toolbox, color: Colors.grey, size: 16),
            SizedBox(width: 10),
            Text(
              'FERRAMENTAS',
              style: TextStyle(
                color: Colors.grey,
                fontSize: 12,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.5,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildToolPurchaseCard(
                title: 'MAPA',
                price: 20.0,
                type: 'Mapa',
                toolKey: 'map',
                icon: FontAwesomeIcons.mapLocationDot,
                color: Colors.blueAccent,
                isPurchased: _hasMap,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildToolPurchaseCard(
                title: 'BÚSSOLA',
                price: 15.0,
                type: 'Bússola',
                toolKey: 'compass',
                icon: FontAwesomeIcons.compass,
                color: Colors.greenAccent,
                isPurchased: _hasCompass,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildToolPurchaseCard({
    required String title,
    required double price,
    required String type,
    required String toolKey,
    required dynamic icon,
    required Color color,
    required bool isPurchased,
  }) {
    if (isPurchased) {
      return Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.3),
              blurRadius: 15,
              spreadRadius: 1,
            ),
          ],
        ),
        child: ElevatedButton.icon(
          onPressed: _isLoading
              ? null
              : () =>
                    toolKey == 'map' ? _openMapDialog() : _openCompassDialog(),
          icon: FaIcon(icon, size: 14, color: Colors.white),
          label: Text(
            'ABRIR $title',
            style: const TextStyle(
              fontWeight: FontWeight.w900,
              fontSize: 12,
              letterSpacing: 1.0,
            ),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: color,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            padding: const EdgeInsets.symmetric(vertical: 16),
            elevation: 0,
          ),
        ),
      );
    }

    return GestureDetector(
      onTap: _isLoading
          ? null
          : () async {
              final bool? confirmed = await _showPurchaseConfirmationDialog(
                price,
                type: type,
              );
              if (confirmed == true) _handleToolPurchase(toolKey);
            },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
        decoration: BoxDecoration(
          color: const Color(0xFF1E1E1E),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withValues(alpha: 0.3), width: 1.5),
        ),
        child: Column(
          children: [
            FaIcon(icon, color: color, size: 28),
            const SizedBox(height: 12),
            Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 13,
                letterSpacing: 1.0,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFF121212),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                'R\$ ${price.toInt()}',
                style: const TextStyle(
                  color: Colors.grey,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHintDialogContent() {
    final String type = _hintData!['type']?.toString() ?? 'text';
    final String data = _hintData!['data']?.toString() ?? '';

    if (type == 'photo') {
      return ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Image.network(data),
      );
    } else if (type == 'gps') {
      final coords = data.split(',');
      final lat = double.tryParse(coords[0]) ?? 0.0;
      final lng = double.tryParse(coords[1]) ?? 0.0;
      return SizedBox(
        height: 250,
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
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: const Color(0xFF121212),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
        ),
        child: Text(
          data,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            height: 1.5,
            fontWeight: FontWeight.w500,
          ),
        ),
      );
    }
  }

  Widget _buildCodeInputSection() {
    return _buildCard(
      title: 'Solução',
      icon: FontAwesomeIcons.key,
      child: Column(
        children: [
          AnimatedBuilder(
            animation: _shakeAnimation,
            builder: (context, child) {
              return Transform.translate(
                offset: Offset(sin(_shakeAnimation.value * pi) * 10, 0),
                child: child,
              );
            },
            child: TextField(
              controller: _codeController,
              enabled: !_isBlocked,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 22,
                letterSpacing: 4,
                fontWeight: FontWeight.w900,
                color: _isBlocked ? Colors.grey : Colors.white,
              ),
              decoration: InputDecoration(
                hintText: 'DIGITE A SENHA',
                hintStyle: TextStyle(
                  color: Colors.grey.withValues(alpha: 0.5),
                  letterSpacing: 2,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
                filled: true,
                fillColor: const Color(0xFF121212),
                contentPadding: const EdgeInsets.symmetric(vertical: 20),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20),
                  borderSide: const BorderSide(
                    color: Color(0xFFFFD54F),
                    width: 2,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(30),
              gradient: _isBlocked
                  ? const LinearGradient(
                      colors: [Color(0xFF424242), Color(0xFF212121)],
                    )
                  : const LinearGradient(
                      colors: [Color(0xFFFFD54F), Color(0xFFF57F17)],
                    ),
              boxShadow: [
                if (!_isBlocked)
                  BoxShadow(
                    color: const Color(0xFFFFD54F).withValues(alpha: 0.4),
                    blurRadius: 15,
                    spreadRadius: 2,
                  ),
              ],
            ),
            child: ElevatedButton(
              onPressed: _isLoading || _isBlocked
                  ? null
                  : () => _handleAction(
                      'validateCode',
                      code: _codeController.text.trim(),
                    ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                shadowColor: Colors.transparent,
                padding: const EdgeInsets.symmetric(vertical: 18),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
                minimumSize: const Size(double.infinity, 50),
              ),
              child: _isLoading
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        color: Colors.black,
                        strokeWidth: 3,
                      ),
                    )
                  : Text(
                      _isBlocked ? 'COOLDOWN ATIVO' : 'ENVIAR RESPOSTA',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.5,
                        color: _isBlocked ? Colors.grey : Colors.black,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

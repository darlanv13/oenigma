import 'dart:async';
import 'dart:math' show pi, sin;
import 'dart:ui';

import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:lottie/lottie.dart' hide Marker;
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:audioplayers/audioplayers.dart';

import 'package:oenigma/app_cliente/features/certificate/screens/winner_certificate_screen.dart';
import 'package:oenigma/core/widgets/dialogs/completion_dialog.dart';
import 'package:oenigma/core/widgets/dialogs/cooldown_dialog.dart';
import 'package:oenigma/core/models/enigma_model.dart';
import 'package:oenigma/core/models/event_model.dart';
import 'package:oenigma/core/models/phase_model.dart';
import 'package:oenigma/app_cliente/features/enigma/repositories/enigma_repository.dart';
import 'package:oenigma/app_cliente/features/enigma/widgets/compass_widget.dart';
import 'package:oenigma/app_cliente/features/enigma/widgets/map_radius_widget.dart';
import 'package:oenigma/app_cliente/features/event/repositories/event_repository.dart';
import 'package:oenigma/app_cliente/features/wallet/screens/wallet_screen.dart';
import 'package:parse_server_sdk_flutter/parse_server_sdk_flutter.dart';

import 'package:oenigma/core/utils/app_colors.dart';

// ================================================================
//  SCANNER SCREEN
// ================================================================
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
      backgroundColor: Colors.black,
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
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              bottom: false,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.8),
                  border: Border(
                    bottom: BorderSide(
                      color: primaryAmber.withOpacity(0.2),
                      width: 1,
                    ),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    GestureDetector(
                      onTap: () => Navigator.of(context).pop(),
                      child: Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: primaryAmber.withOpacity(0.06),
                          shape: BoxShape.circle,
                        ),
                        child: const Center(
                          child: FaIcon(
                            FontAwesomeIcons.chevronLeft,
                            color: primaryAmber,
                            size: 14,
                          ),
                        ),
                      ),
                    ),
                    Text(
                      'LENDO ALVO...',
                      style: GoogleFonts.orbitron(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: primaryAmberLight,
                        letterSpacing: 1.5,
                      ),
                    ),
                    const SizedBox(width: 36),
                  ],
                ),
              ),
            ),
          ),
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
            color: const Color(0xFF1E1E1E).withOpacity(0.9),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: primaryAmber.withOpacity(0.5),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.6),
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
                color: primaryAmber,
                size: 40,
              ),
              const SizedBox(height: 16),
              const Text(
                'Código Detectado',
                style: TextStyle(
                  color: primaryAmber,
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.0,
                ),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.black,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: primaryAmber.withOpacity(0.2)),
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
                    backgroundColor: primaryAmber,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: const Text(
                    'VALIDAR ALVO',
                    style: TextStyle(
                      color: Colors.black,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.0,
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

// ================================================================
//  ENIGMA SCREEN COM DESIGN ALINHADO
// ================================================================
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
  // ================================================================
  //  VARIÁVEIS
  // ================================================================
  final EnigmaRepository _enigmaRepository = EnigmaRepository();
  final EventRepository _eventService = EventRepository();

  bool _isLoading = false;
  StreamSubscription<Position>? _locationSubscription;
  bool _isNear = false;
  double? _distance;
  bool _isBlocked = false;
  Timer? _statusPollTimer;
  late EnigmaModel _currentEnigma;
  
  // Variáveis para Ferramentas e Dicas
  bool _hasCompass = false;
  bool _hasMap = false;
  bool _hasRadar = false;
  Map<String, double>? _destinationLocation;
  int _compassDuration = 0;
  double _compassPrice = 15.0;
  int? _compassRemainingSeconds;

  List<ParseObject> _hintsList = [];
  List<String> _hintsPurchased = [];
  bool _isLoadingHints = true;

  late AnimationController _shakeController;
  late Animation<double> _shakeAnimation;

  // ================================================================
  //  CICLO DE VIDA
  // ================================================================
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

  // ================================================================
  //  LÓGICA
  // ================================================================

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
              'enigma_cache_${_currentEnigma.id}', jsonEncode(result.result));
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
            backgroundColor: dangerColor,
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
                color: primaryAmber.withOpacity(0.3),
                width: 1,
              ),
            ),
            backgroundColor: const Color(0xFF1E1E1E),
            title: Text(
              toolType == 'compass' ? 'Bússola Ativada!' : 'Mapa Ativado!',
              style: TextStyle(
                color: toolType == 'compass' ? primaryAmber : Colors.blueAccent,
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
                  color: toolType == 'compass' ? primaryAmber : Colors.blueAccent,
                ),
                const SizedBox(height: 20),
                Text(
                  toolType == 'compass'
                      ? '1. O triângulo vermelho é você.\n2. O ponto brilhante é o alvo.\n3. Gire o celular para alinhar a direção.\n4. A distância digital mostrará quantos metros faltam.'
                      : '1. Você verá um círculo azul desenhado no mapa.\n2. O seu alvo está em algum lugar dentro deste raio.\n3. Dirija-se até a área e procure atentamente.',
                  style: const TextStyle(color: secondaryTextColor, height: 1.5),
                ),
              ],
            ),
            actions: [
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryAmber,
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
          SnackBar(content: Text(e.message), backgroundColor: dangerColor),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _handleAction(String action, {String? code, String? toolType, String? hintId}) async {
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
              final List<PhaseModel> allPhases =
                  await _eventService.getPhasesForEvent(widget.event.id);
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
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(24),
                    side: BorderSide(
                      color: primaryAmber.withOpacity(0.3),
                      width: 1,
                    ),
                  ),
                  backgroundColor: const Color(0xFF1E1E1E),
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
                            color: primaryAmber,
                          ),
                        ),
                        const SizedBox(height: 24),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: primaryAmber,
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
                                color: Colors.black,
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
            SnackBar(content: Text(message), backgroundColor: dangerColor),
          );
        }
      }
    } on ParseError catch (e) {
      if (e.message.contains('saldo') == true ||
          e.message.contains('Saldo insuficiente') == true) {
        _showInsufficientFundsDialog();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.message), backgroundColor: dangerColor),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString()), backgroundColor: dangerColor),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showInsufficientFundsDialog() {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(
            color: primaryAmber.withOpacity(0.3),
            width: 1,
          ),
        ),
        backgroundColor: const Color(0xFF1E1E1E),
        title: const Row(
          children: [
            FaIcon(FontAwesomeIcons.wallet, color: primaryAmber, size: 20),
            SizedBox(width: 10),
            Text(
              'Saldo Insuficiente',
              style: TextStyle(
                color: primaryAmber,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        content: const Text(
          'Você não tem saldo suficiente para comprar este item. Deseja adicionar créditos?',
          style: TextStyle(color: secondaryTextColor),
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
              backgroundColor: primaryAmber,
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
            color: primaryAmber.withOpacity(0.3),
            width: 1,
          ),
        ),
        backgroundColor: const Color(0xFF1E1E1E),
        title: const Row(
          children: [
            FaIcon(FontAwesomeIcons.store, color: primaryAmber, size: 20),
            SizedBox(width: 10),
            Text(
              'Confirmar Compra',
              style: TextStyle(
                color: primaryAmber,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        content: Text(
          'Comprar $type por R\$ ${cost.toStringAsFixed(2)}?\n\nEste valor será deduzido do seu saldo atual.',
          style: const TextStyle(color: secondaryTextColor),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('CANCELAR', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryAmber,
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

  // ================================================================
  //  DIÁLOGOS DE MÍDIA E FERRAMENTAS
  // ================================================================

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
      borderRadius: BorderRadius.circular(16),
      child: Stack(
        alignment: Alignment.topRight,
        children: [
          Image.network(url, fit: BoxFit.contain),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: IconButton(
              icon: const Icon(Icons.close, color: Colors.white, size: 30),
              onPressed: () => Navigator.of(context).pop(),
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
            color: primaryAmber.withOpacity(0.3),
            width: 1,
          ),
        ),
        backgroundColor: const Color(0xFF1E1E1E),
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
                        color: primaryAmber,
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
        children: [
          if (data.isNotEmpty)
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Image.network(data),
            ),
          const SizedBox(height: 12),
          Text(
            description,
            style: const TextStyle(color: Colors.white, fontSize: 16),
          ),
        ],
      );
    } else if (type == 'audio') {
      return Column(
        children: [
          if (data.isNotEmpty)
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryAmber.withOpacity(0.1),
                foregroundColor: primaryAmber,
              ),
              onPressed: () async {
                final player = AudioPlayer();
                await player.play(UrlSource(data));
              },
              icon: const FaIcon(FontAwesomeIcons.play, size: 16),
              label: const Text('Tocar Áudio'),
            ),
          const SizedBox(height: 12),
          Text(
            description,
            style: const TextStyle(color: Colors.white, fontSize: 16),
          ),
        ],
      );
    } else if (type == 'gps') {
      final coords = data.split(',');
      final lat = double.tryParse(coords.isNotEmpty ? coords[0] : '') ?? 0.0;
      final lng = double.tryParse(coords.length > 1 ? coords[1] : '') ?? 0.0;
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
          color: Colors.black,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withOpacity(0.05)),
        ),
        child: Text(
          description.isNotEmpty ? description : data,
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

  void _openRadarDialog() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Radar ativado! Em breve no jogo.'),
        backgroundColor: primaryAmber,
      ),
    );
  }

  void _openMapDialog() {
    if (_destinationLocation == null) return;
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: BorderSide(
            color: Colors.blueAccent.withOpacity(0.5),
            width: 1,
          ),
        ),
        backgroundColor: const Color(0xFF1E1E1E),
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
      barrierDismissible: false,
      builder: (dialogContext) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: BorderSide(
            color: primaryAmber.withOpacity(0.5),
            width: 1,
          ),
        ),
        backgroundColor: const Color(0xFF1E1E1E),
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
                        color: primaryAmber,
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
                    onPressed: () => Navigator.of(dialogContext).pop(),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              CompassWidget(
                targetLatitude: _destinationLocation!['latitude']!,
                targetLongitude: _destinationLocation!['longitude']!,
                destinationLongitude: _destinationLocation!['longitude']!,
                destinationLatitude: _destinationLocation!['latitude']!,
                durationSeconds: _compassRemainingSeconds ?? _compassDuration,
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
                        backgroundColor: primaryAmber,
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

  // ================================================================
  //  CONSTRUÇÃO DA UI (PADRÃO ESCURO E MAPA)
  // ================================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black, // Fundo base escuro
      body: Stack(
        children: [
          // Fundo imersivo do mapa
          Positioned.fill(
            child: Image.asset(
              'assets/images/background.png',
              fit: BoxFit.cover,
            ),
          ),
          Positioned.fill(
            child: Container(
              color: Colors.black.withOpacity(0.6),
            ),
          ),

          CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              SliverToBoxAdapter(
                child: SafeArea(
                  bottom: false,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      border: Border(
                        bottom: BorderSide(
                          color: primaryAmber.withOpacity(0.10),
                          width: 1,
                        ),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        GestureDetector(
                          onTap: () => Navigator.of(context).pop(),
                          child: Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: primaryAmber.withOpacity(0.06),
                              shape: BoxShape.circle,
                            ),
                            child: const Center(
                              child: FaIcon(
                                FontAwesomeIcons.chevronLeft,
                                color: primaryAmber,
                                size: 14,
                              ),
                            ),
                          ),
                        ),
                        Expanded(
                          child: Text(
                            _currentEnigma.type == 'qrcode'
                                ? "QR Code"
                                : widget.phase.id == 'find_and_win'
                                    ? "Enigma Rápido"
                                    : "Fase ${widget.phase.order} - Enigma ${widget.phase.enigmas.indexOf(_currentEnigma) + 1}",
                            textAlign: TextAlign.center,
                            style: GoogleFonts.orbitron(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: primaryAmber,
                              letterSpacing: 1.5,
                            ),
                          ),
                        ),
                        _currentEnigma.type == 'qrcode'
                            ? Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.green.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: Colors.green.withOpacity(0.5),
                                    width: 1,
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Container(
                                      width: 6,
                                      height: 6,
                                      decoration: const BoxDecoration(
                                        color: Colors.green,
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    const Text(
                                      'Ativo',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              )
                            : const SizedBox(width: 36),
                      ],
                    ),
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: _isLoading && _hintsList.isEmpty
                    ? const Padding(
                        padding: EdgeInsets.only(top: 100),
                        child: Center(
                          child: CircularProgressIndicator(color: primaryAmber),
                        ),
                      )
                    : Container(
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
              ),
            ],
          ),
        ],
      ),
    );
  }

  // --- CARD PADRÃO ---
  Widget _buildCard({
    required String title,
    required Widget child,
    dynamic icon,
  }) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: const Color(0xFF1E1E1E).withOpacity(0.8), // Fundo translucido premium
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: primaryAmber.withOpacity(0.3),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.4),
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
                    FaIcon(icon, color: primaryAmber, size: 16),
                    const SizedBox(width: 10),
                  ],
                  Text(
                    title.toUpperCase(),
                    style: GoogleFonts.inter(
                      color: secondaryTextColor,
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
        ),
      ),
    );
  }

  // --- CARD DO ENIGMA ---
  Widget _buildEnigmaCard() {
    return _buildCard(
      title: 'Desafio Atual',
      icon: FontAwesomeIcons.scroll,
      child: Column(
        children: [
          MarkdownBody(
            data: _currentEnigma.instruction,
            styleSheet: MarkdownStyleSheet(
              p: GoogleFonts.inter(
                color: Colors.white,
                fontSize: 16,
                height: 1.5,
                fontWeight: FontWeight.w500,
              ),
              strong: GoogleFonts.inter(
                color: primaryAmber,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          if ((_currentEnigma.imageUrl != null && _currentEnigma.imageUrl!.isNotEmpty) ||
              (_currentEnigma.audioUrl != null && _currentEnigma.audioUrl!.isNotEmpty)) ...[
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (_currentEnigma.imageUrl != null && _currentEnigma.imageUrl!.isNotEmpty)
                  _buildMediaButton(
                    icon: FontAwesomeIcons.image,
                    label: 'Ver Imagem',
                    color: Colors.blueAccent,
                    onPressed: () => _showMediaDialog(
                      context,
                      type: 'image',
                      url: _currentEnigma.imageUrl!,
                    ),
                  ),
                if ((_currentEnigma.imageUrl != null && _currentEnigma.imageUrl!.isNotEmpty) &&
                    (_currentEnigma.audioUrl != null && _currentEnigma.audioUrl!.isNotEmpty))
                  const SizedBox(width: 16),
                if (_currentEnigma.audioUrl != null && _currentEnigma.audioUrl!.isNotEmpty)
                  _buildMediaButton(
                    icon: FontAwesomeIcons.play,
                    label: 'Ouvir Áudio',
                    color: primaryAmber,
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
        backgroundColor: color.withOpacity(0.1),
        foregroundColor: color,
        side: BorderSide(color: color, width: 1.5),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
      ),
      onPressed: onPressed,
      icon: FaIcon(icon, size: 16),
      label: Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
    );
  }

  // --- SEÇÃO DE DICAS E FERRAMENTAS ---
  Widget _buildHintSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (_isLoadingHints)
           const Center(child: CircularProgressIndicator(color: primaryAmber)),

        if (!_isLoadingHints && _hintsList.isNotEmpty)
          ..._hintsList.map((hint) {
            final isPurchased = _hintsPurchased.contains(hint.objectId);
            final price = hint.get<num>('price')?.toDouble() ?? 0.0;

            if (isPurchased || price <= 0.0) {
              return _buildCard(
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
                        color: primaryAmber.withOpacity(0.3),
                        blurRadius: 15,
                      ),
                    ],
                  ),
                  child: ElevatedButton.icon(
                    onPressed: () => _openHintDialog(hint),
                    icon: const FaIcon(
                      FontAwesomeIcons.eye,
                      color: Colors.black,
                      size: 18,
                    ),
                    label: Text(
                      'ABRIR PISTA',
                      style: GoogleFonts.orbitron(
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
              );
            }

            return Container(
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: primaryAmber.withOpacity(0.3),
                ),
                color: const Color(0xFF1E1E1E).withOpacity(0.8),
              ),
              child: TextButton.icon(
                onPressed: _isLoading
                    ? null
                    : () async {
                        final bool? confirmed = await _showPurchaseConfirmationDialog(
                          price,
                          type: 'Dica',
                        );
                        if (confirmed == true) {
                          _handleAction('purchaseHint', hintId: hint.objectId);
                        }
                      },
                icon: const FaIcon(
                  FontAwesomeIcons.lightbulb,
                  color: primaryAmber,
                  size: 18,
                ),
                label: Text(
                  'COMPRAR PISTA (R\$ ${price.toStringAsFixed(2)})',
                  style: GoogleFonts.orbitron(
                    color: primaryAmber,
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
          }),

        _buildToolsPurchaseButtons(),
      ],
    );
  }

  Widget _buildToolsPurchaseButtons() {
    if (!_currentEnigma.hasMap && !_currentEnigma.hasCompass && !_currentEnigma.hasRadar) {
      return const SizedBox.shrink();
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            const FaIcon(FontAwesomeIcons.toolbox, color: secondaryTextColor, size: 16),
            const SizedBox(width: 10),
            Text(
              'FERRAMENTAS',
              style: GoogleFonts.inter(
                color: secondaryTextColor,
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
            if (_currentEnigma.hasMap)
              Expanded(
                child: _buildToolPurchaseCard(
                  title: 'MAPA',
                  price: _currentEnigma.mapPrice,
                  type: 'Mapa',
                  toolKey: 'map',
                  icon: FontAwesomeIcons.mapLocationDot,
                  color: Colors.blueAccent,
                  isPurchased: _hasMap,
                ),
              ),
            if (_currentEnigma.hasMap && _currentEnigma.hasCompass) const SizedBox(width: 12),
            if (_currentEnigma.hasCompass)
              Expanded(
                child: _buildToolPurchaseCard(
                  title: 'BÚSSOLA',
                  price: _compassPrice,
                  type: 'Bússola',
                  toolKey: 'compass',
                  icon: FontAwesomeIcons.compass,
                  color: primaryAmber,
                  isPurchased: _hasCompass,
                ),
              ),
            if ((_currentEnigma.hasMap || _currentEnigma.hasCompass) && _currentEnigma.hasRadar) const SizedBox(width: 12),
            if (_currentEnigma.hasRadar)
              Expanded(
                child: _buildToolPurchaseCard(
                  title: 'RADAR',
                  price: _currentEnigma.radarPrice,
                  type: 'Radar',
                  toolKey: 'radar',
                  icon: FontAwesomeIcons.satelliteDish,
                  color: Colors.deepPurpleAccent,
                  isPurchased: _hasRadar,
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
              color: color.withOpacity(0.3),
              blurRadius: 15,
              spreadRadius: 1,
            ),
          ],
        ),
        child: ElevatedButton.icon(
          onPressed: _isLoading
              ? null
              : () => toolKey == 'map'
                  ? _openMapDialog()
                  : (toolKey == 'radar' ? _openRadarDialog() : _openCompassDialog()),
          icon: FaIcon(icon, size: 14, color: Colors.white),
          label: Text(
            'ABRIR $title',
            style: GoogleFonts.orbitron(
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
          color: const Color(0xFF1E1E1E).withOpacity(0.8),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withOpacity(0.3), width: 1.5),
        ),
        child: Column(
          children: [
            FaIcon(icon, color: color, size: 28),
            const SizedBox(height: 12),
            Text(
              title,
              style: GoogleFonts.orbitron(
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
                color: Colors.black,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                'R\$ ${price.toInt()}',
                style: GoogleFonts.inter(
                  color: secondaryTextColor,
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

  // --- ÁREA DE AÇÃO (SOMENTE GPS E QR CODE) ---
  Widget _buildActionArea() {
    if (_currentEnigma.type == 'gps') {
      return _buildGpsCard();
    }
    return _buildQrScannerCard();
  }

  Widget _buildGpsCard() {
    final bool isActionReady = _isNear && !_isBlocked;

    return _buildCard(
      title: 'Missão de Campo',
      icon: FontAwesomeIcons.mapLocationDot,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.black,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: primaryAmber.withOpacity(0.3),
              ),
            ),
            child: _distance == null
                ? Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: secondaryTextColor,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        "Buscando satélites...",
                        style: GoogleFonts.inter(
                          color: secondaryTextColor,
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
                        color: primaryAmber,
                        size: 16,
                      ),
                      const SizedBox(width: 10),
                      Text(
                        _isNear
                            ? "VOCÊ CHEGOU!"
                            : "Distância: ${_distance!.toStringAsFixed(0)} metros",
                        style: GoogleFonts.orbitron(
                          fontSize: 16,
                          color: primaryAmber,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ],
                  ),
          ),
          const SizedBox(height: 24),

          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(30),
              gradient: isActionReady
                  ? const LinearGradient(
                      colors: [Color(0xFF00FFFF), Color(0xFF0088FF)],
                    )
                  : const LinearGradient(
                      colors: [Color(0xFF424242), Color(0xFF212121)],
                    ),
              boxShadow: [
                if (isActionReady)
                  BoxShadow(
                    color: const Color(0xFF00FFFF).withOpacity(0.4),
                    blurRadius: 15,
                    spreadRadius: 2,
                  ),
              ],
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
                _isBlocked ? FontAwesomeIcons.clock : FontAwesomeIcons.qrcode,
                color: isActionReady ? Colors.white : Colors.grey,
                size: 20,
              ),
              label: Text(
                _isBlocked
                    ? 'COOLDOWN ATIVO'
                    : (isActionReady
                        ? 'ESCANEAR ALVO'
                        : 'APROXIME-SE DO ALVO'),
                style: GoogleFonts.orbitron(
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

  Widget _buildQrScannerCard() {
    return _buildCard(
      title: 'Validação',
      icon: FontAwesomeIcons.qrcode,
      child: Column(
        children: [
          Text(
            'Encontrou a resposta física?',
            style: GoogleFonts.inter(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Aponte a câmera para o QR Code escondido no local para validar o enigma e resgatar seu prêmio.',
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              color: secondaryTextColor,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 24),
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
                    color: primaryAmber.withOpacity(0.4),
                    blurRadius: 15,
                    spreadRadius: 2,
                  ),
              ],
            ),
            child: ElevatedButton.icon(
              onPressed: _isBlocked
                  ? null
                  : () {
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
                    },
              icon: FaIcon(
                _isBlocked ? FontAwesomeIcons.clock : FontAwesomeIcons.camera,
                color: _isBlocked ? Colors.grey : Colors.black,
                size: 20,
              ),
              label: Text(
                _isBlocked ? 'COOLDOWN ATIVO' : 'ESCANEAR QR CODE',
                style: GoogleFonts.orbitron(
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.0,
                  color: _isBlocked ? Colors.grey : Colors.black,
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
}

// ================================================================
//  AUDIO DIALOG
// ================================================================
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
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E).withOpacity(0.95),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: primaryAmber.withOpacity(0.3),
          width: 2,
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
                  FaIcon(FontAwesomeIcons.music, color: primaryAmber),
                  SizedBox(width: 12),
                  Text(
                    'Pista em Áudio',
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
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.black,
            ),
            child: IconButton(
              iconSize: 48,
              color: primaryAmber,
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
          const SizedBox(height: 24),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: primaryAmber,
              inactiveTrackColor: Colors.white24,
              thumbColor: primaryAmber,
              overlayColor: primaryAmber.withOpacity(0.2),
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
                  style: const TextStyle(color: Colors.grey, fontSize: 12),
                ),
                Text(
                  _formatDuration(_duration),
                  style: const TextStyle(color: Colors.grey, fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ================================================================
//  DASHED RECT PAINTER
// ================================================================
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
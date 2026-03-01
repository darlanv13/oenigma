import 'dart:ui';

import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:math' show cos, sqrt, asin, pi, sin;
import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/services.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:lottie/lottie.dart' hide Marker;
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:location/location.dart';

import 'package:oenigma/features/certificate/screens/winner_certificate_screen.dart';
import 'package:oenigma/core/widgets/dialogs/completion_dialog.dart';
import 'package:oenigma/core/widgets/dialogs/cooldown_dialog.dart';
import 'package:permission_handler/permission_handler.dart'
    hide PermissionStatus;
import 'package:saver_gallery/saver_gallery.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:oenigma/core/models/enigma_model.dart';
import 'package:oenigma/core/models/event_model.dart';
import 'package:oenigma/core/models/phase_model.dart';
import 'package:oenigma/features/enigma/repositories/enigma_repository.dart';

import 'package:oenigma/features/event/repositories/event_repository.dart';
import 'package:oenigma/core/utils/app_colors.dart';

import 'package:oenigma/features/wallet/screens/wallet_screen.dart';

// --- TELA DE SCANNER (sem alterações) ---
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
      appBar: AppBar(title: const Text('Aponte para o QR Code')),
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
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
        child: Container(
          padding: const EdgeInsets.all(24),
          width: MediaQuery.of(context).size.width * 0.8,
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: primaryAmber),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Código Detectado',
                style: TextStyle(
                  color: primaryAmber,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                _detectedQRCode!,
                textAlign: TextAlign.center,
                style: const TextStyle(color: textColor, fontSize: 16),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () {
                  widget.onScan(_detectedQRCode!);
                  Navigator.of(context).pop();
                },
                style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                child: const Text('Confirmar'),
              ),
              TextButton(
                onPressed: () {
                  setState(() {
                    _detectedQRCode = null;
                  });
                  _scannerController.start();
                },
                child: const Text(
                  'Escanear Novamente',
                  style: TextStyle(color: textColor),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

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
  final EventRepository _firebaseService = EventRepository();

  bool _isLoading = false;
  bool _canBuyHint = false;
  final Location _location = Location();
  StreamSubscription<LocationData>? _locationSubscription;
  bool _isNear = false;
  double? _distance;
  bool _isHintVisible = false;
  Map<String, dynamic>? _hintData;
  bool _isBlocked = false;
  Timer? _statusPollTimer;
  late EnigmaModel _currentEnigma;

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
    });
    await _fetchInitialStatus();
    if (mounted && _currentEnigma.type == 'qr_code_gps') {
      await _initializeGpsListener();
    }
    if (mounted) {
      setState(() {
        _isLoading = false;
      });
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
            if (mounted) {
              setState(() => _isBlocked = false);
            }
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
        final statusData = Map<String, dynamic>.from(result.data);
        setState(() {
          _isHintVisible = statusData['isHintVisible'] ?? false;
          _canBuyHint = statusData['canBuyHint'] ?? false;
          _isBlocked = statusData['isBlocked'] ?? false;
        });
        if (_isBlocked && statusData['cooldownUntil'] != null) {
          _handleCooldown(statusData['cooldownUntil']);
        }
      }
    } catch (e) {
      print("Erro ao buscar status: $e");
    }
  }

  void _showInsufficientFundsDialog() {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: cardColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'Saldo Insuficiente',
          style: TextStyle(color: primaryAmber, fontWeight: FontWeight.bold),
        ),
        content: const Text(
          'Você não tem saldo suficiente para comprar esta dica. Deseja adicionar créditos?',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text(
              'Agora Não',
              style: TextStyle(color: secondaryTextColor),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(dialogContext).pop();
              setState(() => _isLoading = true);
              try {
                if (!mounted) return;
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const WalletScreen(),
                  ),
                );
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text("Erro ao carregar dados da carteira."),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              } finally {
                if (mounted) {
                  setState(() => _isLoading = false);
                }
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: primaryAmber),
            child: const Text(
              'Recarregar',
              style: TextStyle(
                color: darkBackground,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<bool?> _showPurchaseConfirmationDialog(double cost, {String type = 'Dica'}) {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: cardColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'Confirmar Compra',
          style: TextStyle(color: primaryAmber),
        ),
        content: Text(
          'Comprar $type por R\$ ${cost.toStringAsFixed(2)}?\n\nEste valor será deduzido do seu saldo.',
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text(
              'CANCELAR',
              style: TextStyle(color: secondaryTextColor),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(backgroundColor: primaryAmber),
            child: const Text(
              'SIM, COMPRAR',
              style: TextStyle(color: darkBackground),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _handleToolPurchase(String toolType) async {
    setState(() => _isLoading = true);
    try {
      final result = await _enigmaRepository.callEnigmaFunction('purchaseTool', {
        'eventId': widget.event.id,
        'toolType': toolType,
      });

      if (!mounted) return;

      final data = Map<String, dynamic>.from(result.data);
      final success = data['success'] ?? false;

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(data['message'] ?? "Ferramenta comprada com sucesso!"),
            backgroundColor: Colors.green,
          ),
        );
      }
    } on FirebaseFunctionsException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.message ?? "Ocorreu um erro."),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Ocorreu um erro ao processar: $e"),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
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

      final data = Map<String, dynamic>.from(result.data);
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

          // Sucesso!
          switch (nextStep['type']) {
            case 'event_complete':
              final double prizeWon =
                  (nextStep['prizeWon'] as num?)?.toDouble() ?? 0.0;
              final List<PhaseModel> allPhases = await _firebaseService
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

              // Mostra animação de sucesso
              await showDialog(
                context: context,
                barrierDismissible: false,
                builder: (dialogContext) => Dialog(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  backgroundColor: cardColor,
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
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
                            fontWeight: FontWeight.bold,
                            color: Colors.green,
                          ),
                        ),
                        const SizedBox(height: 24),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                            onPressed: () => Navigator.of(dialogContext).pop(),
                            child: const Text(
                              'Próximo Desafio',
                              style: TextStyle(fontSize: 18, color: textColor),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
              setState(() {
                _currentEnigma = nextEnigma;
              });
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
        // Falha (Código Incorreto, etc)
        final message = data['message'] ?? 'Ação falhou.';
        if (action == 'validateCode') {
          _triggerShake(); // Balança o campo se errou
        }

        if (data['cooldownUntil'] != null) {
          _handleCooldown(data['cooldownUntil']);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(message),
              backgroundColor: Colors.redAccent,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    } on FirebaseFunctionsException catch (e) {
      if (e.code == 'failed-precondition' &&
          e.message != null &&
          e.message!.contains('Saldo insuficiente')) {
        _showInsufficientFundsDialog();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.message ?? 'Erro desconhecido.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Erro inesperado no aplicativo.'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _initializeGpsListener() async {
    bool serviceEnabled = await _location.serviceEnabled();
    if (!serviceEnabled) {
      serviceEnabled = await _location.requestService();
      if (!serviceEnabled) return;
    }
    PermissionStatus permissionGranted = await _location.hasPermission();
    if (permissionGranted == PermissionStatus.denied) {
      permissionGranted = await _location.requestPermission();
      if (permissionGranted != PermissionStatus.granted) return;
    }
    _locationSubscription = _location.onLocationChanged.listen((
      currentLocation,
    ) {
      if (!mounted || _currentEnigma.location == null) return;
      final distanceInMeters = _calculateDistance(
        currentLocation.latitude!,
        currentLocation.longitude!,
        _currentEnigma.location!.latitude,
        _currentEnigma.location!.longitude,
      );
      setState(() {
        _distance = distanceInMeters;
        _isNear = distanceInMeters <= 100;
      });
    });
  }

  double _calculateDistance(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    var p = 0.017453292519943295;
    var a =
        0.5 -
        cos((lat2 - lat1) * p) / 2 +
        cos(lat1 * p) * cos(lat2 * p) * (1 - cos((lon2 - lon1) * p)) / 2;
    return 12742 * asin(sqrt(a)) * 1000;
  }

  Future<void> _saveImageFromUrl(String url) async {
    var status = await Permission.storage.request();
    if (status.isGranted) {
      setState(() => _isLoading = true);
      try {
        final response = await http.get(Uri.parse(url));
        final Uint8List imageBytes = response.bodyBytes;
        final result = await SaverGallery.saveImage(
          imageBytes,
          quality: 80,
          fileName: 'enigma_dica_${DateTime.now().millisecondsSinceEpoch}.jpg',
          skipIfExists: false,
        );
        if (result.isSuccess) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Imagem salva na galeria!'),
              backgroundColor: Colors.green,
            ),
          );
        } else {
          throw Exception('Falha ao salvar a imagem: ${result.errorMessage}');
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Erro ao salvar imagem.'),
            backgroundColor: Colors.red,
          ),
        );
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Permissão para salvar imagem foi negada.'),
          backgroundColor: Colors.orange,
        ),
      );
    }
  }

  Future<void> _launchMapsUrl(String coordinates) async {
    final Uri googleMapsUrl = Uri.parse(
      'https://www.google.com/maps/search/?api=1&query=$coordinates',
    );
    try {
      if (await canLaunchUrl(googleMapsUrl)) {
        await launchUrl(googleMapsUrl, mode: LaunchMode.externalApplication);
      } else {
        throw 'Não foi possível abrir o mapa.';
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro ao abrir o mapa: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Fase ${widget.phase.order} - Enigma ${widget.phase.enigmas.indexOf(_currentEnigma) + 1}",
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: darkBackground,
        elevation: 0,
      ),
      backgroundColor: darkBackground,
      body: _isLoading && !_isHintVisible
          ? const Center(child: CircularProgressIndicator(color: primaryAmber))
          : SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 40),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildEnigmaCard(),
                  const SizedBox(height: 24),
                  _buildHintSection(),
                  const SizedBox(height: 24),
                  _buildActionArea(),
                ],
              ),
            ),
    );
  }

  Widget _buildCard({required String title, required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
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

  Widget _buildEnigmaCard() {
    return _buildCard(title: 'DESAFIO ATUAL', child: _buildEnigmaContent());
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
                child: Image.network(_currentEnigma.imageUrl!),
              )
            else if (_currentEnigma.type != 'text')
              Lottie.asset('assets/animations/no_enigma.json', height: 150),
            if (_currentEnigma.imageUrl != null) const SizedBox(height: 20),
            Text(
              _currentEnigma.instruction,
              style: const TextStyle(
                fontSize: 16,
                color: textColor,
                height: 1.6,
              ),
            ),
          ],
        );
      case 'qr_code_gps':
        return const SizedBox.shrink(); // Tratado na área de ação
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildActionArea() {
    if (_currentEnigma.type == 'qr_code_gps') {
      return _buildQrCodeGpsCard();
    }
    return _buildCodeInputSection();
  }

  Widget _buildQrCodeGpsCard() {
    return _buildCard(
      title: 'MISSÃO DE CAMPO',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          if (_currentEnigma.imageUrl != null &&
              _currentEnigma.imageUrl!.isNotEmpty)
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Image.network(_currentEnigma.imageUrl!),
            )
          else
            Lottie.asset('assets/animations/no_enigma.json', height: 150),
          const SizedBox(height: 16),
          Text(
            _currentEnigma.instruction,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 16, color: textColor, height: 1.5),
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: darkBackground,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white10),
            ),
            child: _distance == null
                ? const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(
                        width: 12,
                        height: 12,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: secondaryTextColor,
                        ),
                      ),
                      SizedBox(width: 8),
                      Text(
                        "Localizando alvo...",
                        style: TextStyle(
                          fontSize: 14,
                          color: secondaryTextColor,
                        ),
                      ),
                    ],
                  )
                : Text(
                    "Distância: ${_distance!.toStringAsFixed(0)} metros",
                    style: const TextStyle(
                      fontSize: 14,
                      color: primaryAmber,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _isNear && !_isBlocked
                  ? () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => ScannerScreen(
                            onScan: (scannedCode) {
                              _handleAction('validateCode', code: scannedCode);
                            },
                          ),
                        ),
                      );
                    }
                  : null,
              icon: Icon(
                _isBlocked ? Icons.timer_off_outlined : Icons.qr_code_scanner,
              ),
              label: Text(
                _isBlocked
                    ? 'Aguarde o Cooldown'
                    : (_isNear ? 'ESCANEAR CÓDIGO' : 'APROXIME-SE DO LOCAL'),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: _isNear && !_isBlocked
                    ? Colors.green
                    : cardColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                textStyle: const TextStyle(fontWeight: FontWeight.bold),
                elevation: 0,
                side: BorderSide(
                  color: _isNear && !_isBlocked
                      ? Colors.transparent
                      : Colors.white10,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHintSection() {
    if (_isHintVisible) {
      if (_hintData != null) {
        return _buildCard(title: 'PISTA', child: _buildHintContent());
      }
      return const SizedBox.shrink();
    }

    if (_canBuyHint) {
      final hintCosts = {1: 5, 2: 10, 3: 15};
      final cost = hintCosts[widget.phase.order];

      return AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        child: TextButton.icon(
          onPressed: _isLoading
              ? null
              : () async {
                  if (cost == null) return;
                  final bool? confirmed = await _showPurchaseConfirmationDialog(cost.toDouble(), type: 'Dica');
                  if (confirmed == true) {
                    _handleAction('purchaseHint');
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
            backgroundColor: primaryAmber.withValues(alpha: 0.08),
          ),
        ),
      );
    }
    return const SizedBox.shrink();
  }

  Widget _buildHintContent() {
    final String type = _hintData!['type'];
    final String data = _hintData!['data'];
    Widget hintContent;
    Widget actionButton;

    if (type == 'photo') {
      hintContent = ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Image.network(data),
      );
      actionButton = ElevatedButton.icon(
        onPressed: _isLoading ? null : () => _saveImageFromUrl(data),
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
        onPressed: () => _launchMapsUrl(data),
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

  Widget _buildCodeInputSection() {
    return _buildCard(
      title: 'SUA RESPOSTA',
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
                fontSize: 28,
                letterSpacing: 8,
                fontWeight: FontWeight.bold,
                fontFamily: 'monospace',
                color: _isBlocked ? secondaryTextColor : textColor,
              ),
              decoration: InputDecoration(
                hintText: 'CÓDIGO',
                hintStyle: TextStyle(
                  color: secondaryTextColor.withValues(alpha: 0.3),
                  letterSpacing: 2,
                  fontFamily: 'Poppins',
                  fontSize: 24,
                ),
                filled: true,
                fillColor: darkBackground,
                contentPadding: const EdgeInsets.symmetric(vertical: 20),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(color: primaryAmber, width: 2),
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isLoading || _isBlocked
                  ? null
                  : () => _handleAction(
                      'validateCode',
                      code: _codeController.text.trim(),
                    ),
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryAmber,
                foregroundColor: darkBackground,
                padding: const EdgeInsets.symmetric(vertical: 18),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 5,
                shadowColor: primaryAmber.withValues(alpha: 0.4),
              ),
              child: _isLoading
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        color: darkBackground,
                        strokeWidth: 3,
                      ),
                    )
                  : Text(
                      _isBlocked ? 'Aguarde...' : 'ENVIAR RESPOSTA',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

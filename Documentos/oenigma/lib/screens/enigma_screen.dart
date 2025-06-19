import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:math' show cos, sqrt, asin;
import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/services.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:lottie/lottie.dart' hide Marker;
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:location/location.dart';
import 'package:permission_handler/permission_handler.dart'
    hide PermissionStatus;
import 'package:saver_gallery/saver_gallery.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/enigma_model.dart';
import '../models/event_model.dart';
import '../models/phase_model.dart';
import '../services/firebase_service.dart';
import '../utils/app_colors.dart';
import '../widgets/completion_dialog.dart';
import '../widgets/cooldown_dialog.dart';
import '../widgets/error_dialog.dart';

// Tela do Scanner
class ScannerScreen extends StatelessWidget {
  final Function(String) onScan;
  const ScannerScreen({super.key, required this.onScan});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Aponte para o QR Code')),
      body: MobileScanner(
        onDetect: (capture) {
          final List<Barcode> barcodes = capture.barcodes;
          if (barcodes.isNotEmpty && barcodes.first.rawValue != null) {
            onScan(barcodes.first.rawValue!);
            Navigator.of(context).pop();
          }
        },
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

class _EnigmaScreenState extends State<EnigmaScreen> {
  final TextEditingController _codeController = TextEditingController();
  final FirebaseService _firebaseService = FirebaseService();
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

  @override
  void initState() {
    super.initState();
    _currentEnigma = widget.initialEnigma;
    _resetEnigmaState();
  }

  void _resetEnigmaState() {
    _codeController.clear();
    _isHintVisible = false;
    _canBuyHint = false;
    _hintData = null;
    _distance = null;
    _isNear = false;
    _isBlocked = false;
    _locationSubscription?.cancel();
    _statusPollTimer?.cancel();
    _fetchInitialStatus();
    if (_currentEnigma.type == 'qr_code_gps') {
      _initializeGpsListener();
    }
  }

  @override
  void dispose() {
    _codeController.dispose();
    _locationSubscription?.cancel();
    _statusPollTimer?.cancel();
    super.dispose();
  }

  void _handleCooldown(String cooldownUntilStr) {
    final cooldownUntil = DateTime.parse(cooldownUntilStr);
    if (cooldownUntil.isAfter(DateTime.now())) {
      setState(() {
        _isBlocked = true;
      });
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => CooldownDialog(
          cooldownUntil: cooldownUntil,
          onCooldownFinished: () {
            setState(() {
              _isBlocked = false;
            });
          },
        ),
      );
    }
  }

  Future<void> _fetchInitialStatus() async {
    setState(() {
      _isLoading = true;
    });
    try {
      final result = await _firebaseService.callEnigmaFunction('getStatus', {
        'eventId': widget.event.id,
        'phaseOrder': widget.phase.order,
        'enigmaId': _currentEnigma.id,
      });
      final statusData = Map<String, dynamic>.from(result.data);
      if (mounted) {
        setState(() {
          _isHintVisible = statusData['isHintVisible'] ?? false;
          _canBuyHint = statusData['canBuyHint'] ?? false;
          _isBlocked = statusData['isBlocked'] ?? false;
        });
        if (_isBlocked && statusData['cooldownUntil'] != null) {
          _handleCooldown(statusData['cooldownUntil']);
        }
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _handleAction(String action, {String? code}) async {
    setState(() => _isLoading = true);
    try {
      final result = await _firebaseService.callEnigmaFunction(action, {
        'eventId': widget.event.id,
        'phaseOrder': widget.phase.order,
        'enigmaId': _currentEnigma.id,
        if (code != null) 'code': code,
      });

      if (!mounted) return;

      final data = Map<String, dynamic>.from(result.data);
      final success = data['success'] ?? false;

      if (success) {
        // ================================================================
        // CORREÇÃO: Usar 'if / else if' para separar as ações de sucesso.
        // Isso garante que a lógica de comprar dica não execute a lógica de validar código.
        // ================================================================

        if (action == 'purchaseHint') {
          // Ação de comprar dica: apenas atualiza a UI para mostrar a dica
          setState(() {
            _isHintVisible = true;
            _hintData = Map<String, dynamic>.from(data['hint']);
          });
        } else if (action == 'validateCode') {
          // Ação de validar código: avança para o próximo enigma ou finaliza a fase
          final nextStep = data['nextStep'];
          if (nextStep != null && nextStep['type'] == 'next_enigma') {
            final nextEnigma = EnigmaModel.fromMap(
              Map<String, dynamic>.from(nextStep['enigmaData']),
            );
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
              _resetEnigmaState();
            });
          } else {
            showCompletionDialog(
              context,
              onOkPressed: () {
                Navigator.of(context).pop();
                widget.onEnigmaSolved();
                Navigator.of(context).pop();
              },
            );
          }
        }
      } else {
        final message = data['message'] ?? 'Ação falhou.';
        if (data['cooldownUntil'] != null) {
          _handleCooldown(data['cooldownUntil']);
        } else {
          showErrorDialog(context, message: message);
        }
      }
    } on FirebaseFunctionsException catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.message ?? 'Erro desconhecido.'),
          backgroundColor: Colors.red,
        ),
      );
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

  // Métodos auxiliares (_saveImageFromUrl, _initializeGpsListener, etc.)
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
      LocationData currentLocation,
    ) {
      if (_currentEnigma.location == null) return;
      final distanceInMeters = _calculateDistance(
        currentLocation.latitude!,
        currentLocation.longitude!,
        _currentEnigma.location!.latitude,
        _currentEnigma.location!.longitude,
      );
      if (mounted) {
        setState(() {
          _distance = distanceInMeters;
          _isNear = distanceInMeters <= 100;
        });
      }
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
      appBar: AppBar(title: Text("Fase ${widget.phase.order}")),
      body: _isLoading && _hintData == null
          ? const Center(child: CircularProgressIndicator(color: primaryAmber))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  _buildEnigmaContent(),
                  const SizedBox(height: 24),
                  _buildHintSection(),
                  const SizedBox(height: 24),
                  if (_currentEnigma.type != 'qr_code_gps')
                    _buildCodeInputSection(),
                ],
              ),
            ),
    );
  }

  // Métodos de construção da UI (_buildEnigmaContent, _buildHintSection, etc.)
  Widget _buildEnigmaContent() {
    switch (_currentEnigma.type) {
      case 'photo_location':
        return _buildPhotoLocationUI();
      case 'qr_code_gps':
        return _buildQrCodeGpsUI();
      case 'text':
      default:
        return _buildTextEnigmaUI();
    }
  }

  Widget _buildTextEnigmaUI() =>
      Text(_currentEnigma.instruction, style: const TextStyle(fontSize: 18));

  Widget _buildPhotoLocationUI() {
    return Column(
      children: [
        SizedBox(
          height: 200,
          width: double.infinity,
          child:
              (_currentEnigma.imageUrl != null &&
                  _currentEnigma.imageUrl!.isNotEmpty)
              ? Image.network(_currentEnigma.imageUrl!)
              : Lottie.asset('assets/animations/no_enigma.json'),
        ),
        const SizedBox(height: 16),
        Text(_currentEnigma.instruction, style: const TextStyle(fontSize: 18)),
      ],
    );
  }

  Widget _buildQrCodeGpsUI() {
    return Column(
      children: [
        if (_currentEnigma.imageUrl != null &&
            _currentEnigma.imageUrl!.isNotEmpty)
          SizedBox(
            height: 200,
            width: double.infinity,
            child: Image.network(_currentEnigma.imageUrl!),
          )
        else
          SizedBox(
            height: 200,
            width: double.infinity,
            child: Lottie.asset('assets/animations/no_enigma.json'),
          ),
        const SizedBox(height: 16),
        Text(
          _currentEnigma.instruction,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 18),
        ),
        const SizedBox(height: 24),
        if (_distance != null)
          Text(
            "Distância do alvo: ${_distance!.toStringAsFixed(0)} metros",
            style: const TextStyle(fontSize: 16, color: secondaryTextColor),
          ),
        const SizedBox(height: 20),
        ElevatedButton.icon(
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
                ? 'Aguarde'
                : (_isNear ? 'Escanear QR Code' : 'Aproxime-se do local'),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: _isNear && !_isBlocked
                ? Colors.green
                : Colors.grey.shade800,
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
          ),
        ),
      ],
    );
  }

  Widget _buildHintSection() {
    if (!_isHintVisible && _canBuyHint) {
      return TextButton.icon(
        onPressed: _isLoading ? null : () => _handleAction('purchaseHint'),
        icon: const Icon(Icons.lightbulb, color: primaryAmber),
        label: const Text(
          'Comprar Dica',
          style: TextStyle(color: primaryAmber),
        ),
      );
    }
    if (_isHintVisible && _hintData != null) {
      final String type = _hintData!['type'];
      final String data = _hintData!['data'];
      Widget hintContent;
      Widget actionButton;
      if (type == 'photo') {
        hintContent = ClipRRect(
          borderRadius: BorderRadius.circular(15),
          child: Image.network(data),
        );
        actionButton = ElevatedButton.icon(
          onPressed: _isLoading ? null : () => _saveImageFromUrl(data),
          icon: const Icon(Icons.save_alt_rounded),
          label: const Text('Salvar na Galeria'),
        );
      } else if (type == 'gps') {
        final coords = data.split(',');
        final lat = double.tryParse(coords[0]) ?? 0.0;
        final lng = double.tryParse(coords[1]) ?? 0.0;
        hintContent = SizedBox(
          height: 200,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(15),
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
          label: const Text('Ver no Google Maps'),
        );
      } else {
        hintContent = Text(
          data,
          style: const TextStyle(color: textColor, fontSize: 16),
        );
        actionButton = ElevatedButton.icon(
          onPressed: () {
            Clipboard.setData(ClipboardData(text: data));
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Dica copiada!'),
                backgroundColor: Colors.green,
              ),
            );
          },
          icon: const Icon(Icons.copy_rounded),
          label: const Text('Copiar Dica'),
        );
      }
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: primaryAmber.withOpacity(0.15),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: primaryAmber),
        ),
        child: Column(
          children: [
            hintContent,
            if (actionButton is! SizedBox) const SizedBox(height: 16),
            actionButton,
          ],
        ),
      );
    }
    return const SizedBox.shrink();
  }

  Widget _buildCodeInputSection() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          TextField(
            controller: _codeController,
            enabled: !_isBlocked,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 24,
              letterSpacing: 8,
              color: _isBlocked ? secondaryTextColor : textColor,
            ),
            decoration: InputDecoration(
              hintText: 'XXX-XXX-XXX',
              hintStyle: TextStyle(color: secondaryTextColor.withOpacity(0.5)),
              filled: true,
              fillColor: _isBlocked ? Colors.grey.shade800 : darkBackground,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _isLoading || _isBlocked
                  ? null
                  : () => _handleAction(
                      'validateCode',
                      code: _codeController.text.trim(),
                    ),
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryAmber,
                foregroundColor: darkBackground,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              icon: _isLoading
                  ? Container()
                  : Icon(
                      _isBlocked ? Icons.timer_off_outlined : Icons.send,
                      color: darkBackground,
                    ),
              label: _isLoading
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(color: darkBackground),
                    )
                  : Text(
                      _isBlocked ? 'Aguarde' : 'Verificar Código',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

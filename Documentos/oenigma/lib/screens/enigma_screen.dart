import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:math' show cos, sqrt, asin; // Para cálculo de distância
import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/services.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:lottie/lottie.dart' hide Marker;
import 'package:mobile_scanner/mobile_scanner.dart'; // Para scanner de QR Code
import 'package:location/location.dart'; // Para GPS
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
import '../widgets/enigma_success_dialog.dart';

// --- MUDANÇA: Tela separada para o Scanner ---
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
  final EnigmaModel enigma;
  final VoidCallback onEnigmaSolved;

  const EnigmaScreen({
    super.key,
    required this.event,
    required this.phase,
    required this.enigma,
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

  // --- MUDANÇA: Variáveis de estado para as novas funcionalidades ---
  final Location _location = Location();
  StreamSubscription<LocationData>? _locationSubscription;
  bool _isNear = false;
  double? _distance;
  bool _isHintVisible = false;
  Map<String, dynamic>? _hintData; // Para guardar a dica (foto ou GPS)
  Timer? _cooldownTimer;
  final String _cooldownTimeLeft = '';

  //  método  para salvar a imagem
  // --- MÉTODO CORRIGIDO COM OS PARÂMETROS ATUALIZADOS ---
  Future<void> _saveImageFromUrl(String url) async {
    var status = await Permission.storage.request();
    if (status.isGranted) {
      setState(() => _isLoading = true);
      try {
        final response = await http.get(Uri.parse(url));
        final Uint8List imageBytes = response.bodyBytes;

        // CORREÇÃO: Usando os parâmetros corretos 'fileName' e 'skipIfExists'
        final result = await SaverGallery.saveImage(
          imageBytes,
          quality: 80,
          fileName: 'enigma_dica_${DateTime.now().millisecondsSinceEpoch}.jpg',
          skipIfExists: false, // Parâmetro corrigido
          //androidExistNotSave: true, skipIfExists: false, // Parâmetro renomeado/adicionado para Android
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
        print('Erro ao salvar imagem: $e');
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

  @override
  void initState() {
    super.initState();
    _fetchInitialStatus();
    // Inicia o listener de GPS apenas se o enigma for do tipo correto
    if (widget.enigma.type == 'qr_code_gps') {
      _initializeGpsListener();
    }
  }

  @override
  void dispose() {
    _codeController.dispose();
    _locationSubscription
        ?.cancel(); // Cancela o listener para economizar bateria
    _cooldownTimer?.cancel();
    super.dispose();
  }

  // --- MUDANÇA: Lógica de GPS ---
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
      if (widget.enigma.location == null) return;

      final distanceInMeters = _calculateDistance(
        currentLocation.latitude!,
        currentLocation.longitude!,
        widget.enigma.location!.latitude,
        widget.enigma.location!.longitude,
      );

      if (mounted) {
        setState(() {
          _distance = distanceInMeters;
          _isNear = distanceInMeters <= 100; // Raio de 100 metros
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
    var p = 0.017453292519943295; // Math.PI / 180
    var a =
        0.5 -
        cos((lat2 - lat1) * p) / 2 +
        cos(lat1 * p) * cos(lat2 * p) * (1 - cos((lon2 - lon1) * p)) / 2;
    return 12742 *
        asin(sqrt(a)) *
        1000; // 2 * R; R = 6371 km. Resultado em metros
  }

  Future<void> _fetchInitialStatus() async {
    final result = await _firebaseService.callEnigmaFunction('getStatus', {
      'eventId': widget.event.id,
      'phaseOrder': widget.phase.order,
      'enigmaId': widget.enigma.id,
    });
    final statusData = Map<String, dynamic>.from(result.data);
    if (mounted) {
      setState(() {
        _isHintVisible = statusData['isHintVisible'] ?? false;
        _canBuyHint = statusData['canBuyHint'] ?? false;
      });
    }
  }

  // --- MUDANÇA: Lógica para comprar dica e validar código ---
  Future<void> _handleAction(String action, {String? code}) async {
    setState(() => _isLoading = true);
    try {
      final result = await _firebaseService.callEnigmaFunction(action, {
        'eventId': widget.event.id,
        'phaseOrder': widget.phase.order,
        'enigmaId': widget.enigma.id,
        if (code != null) 'code': code,
      });

      final data = Map<String, dynamic>.from(result.data);
      final success = data['success'] ?? false;
      if (!mounted) return;

      if (success) {
        if (action == 'validateCode') {
          // Lógica de navegação após acertar o código
          final nextStep = data['nextStep'] != null
              ? Map<String, dynamic>.from(data['nextStep'])
              : null;
          if (nextStep != null && nextStep['type'] == 'next_enigma') {
            final nextEnigma = EnigmaModel.fromMap(
              Map<String, dynamic>.from(nextStep['enigmaData']),
            );
            showEnigmaSuccessDialog(
              context,
              onContinue: () {
                Navigator.of(context).pop();
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (context) => EnigmaScreen(
                      event: widget.event,
                      phase: widget.phase,
                      enigma: nextEnigma,
                      onEnigmaSolved: widget.onEnigmaSolved,
                    ),
                  ),
                );
              },
            );
          } else {
            showCompletionDialog(
              context,
              onOkPressed: () {
                Navigator.of(context).popUntil((route) => route.isFirst);
                widget.onEnigmaSolved();
              },
            );
          }
        } else if (action == 'purchaseHint') {
          // Mostra a dica recebida da Cloud Function
          setState(() {
            _isHintVisible = true;
            _hintData = Map<String, dynamic>.from(data['hint']);
          });
        }
      } else {
        final message = data['message'] ?? 'Ação falhou.';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(message), backgroundColor: Colors.red),
        );
      }
    } on FirebaseFunctionsException catch (e) {
      // --- INÍCIO DA CORREÇÃO ---
      // Adicione estas linhas para imprimir o erro detalhado no console
      print('==== ERRO DETALHADO DA CLOUD FUNCTION ====');
      print('Código do Erro: ${e.code}');
      print('Mensagem do Erro: ${e.message}');
      print('Detalhes: ${e.details}');
      print('========================================');
      // --- FIM DA CORREÇÃO ---

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.message ?? 'Ocorreu um erro desconhecido.'),
          backgroundColor: Colors.red,
        ),
      );
    } catch (e) {
      // --- INÍCIO DA CORREÇÃO ---
      // Adicione estas linhas para capturar outros tipos de erro
      print('==== ERRO INESPERADO NO FLUTTER ====');
      print('Erro: $e');
      print('====================================');
      // --- FIM DA CORREÇÃO ---

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Ocorreu um erro inesperado no aplicativo.'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    // A lógica de `isBlocked` precisa ser definida aqui para ser passada aos widgets
    final bool isBlocked = _cooldownTimeLeft.isNotEmpty;
    return Scaffold(
      appBar: AppBar(title: Text("Fase ${widget.phase.order}")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            _buildEnigmaContent(),
            const SizedBox(height: 24),
            _buildHintSection(),
            const SizedBox(height: 24),
            // O campo de inserir código só aparece para enigmas que não são de QR Code
            if (widget.enigma.type != 'qr_code_gps')
              _buildCodeInputSection(isBlocked),
          ],
        ),
      ),
    );
  }

  // --- MUDANÇA: Construtor de UI dinâmico ---
  Widget _buildEnigmaContent() {
    switch (widget.enigma.type) {
      case 'photo_location':
        return _buildPhotoLocationUI();
      case 'qr_code_gps':
        return _buildQrCodeGpsUI();
      case 'text':
      default:
        return _buildTextEnigmaUI();
    }
  }

  // --- MUDANÇA: Widgets de UI para cada tipo de enigma ---
  Widget _buildTextEnigmaUI() {
    return Text(
      widget.enigma.instruction,
      style: const TextStyle(fontSize: 18),
    );
  }

  Widget _buildPhotoLocationUI() {
    return Column(
      children: [
        // --- LÓGICA ATUALIZADA ---
        SizedBox(
          height: 200,
          width: double.infinity,
          child:
              (widget.enigma.imageUrl != null &&
                  widget.enigma.imageUrl!.isNotEmpty)
              ? Image.network(
                  widget.enigma.imageUrl!,
                ) // Mostra a imagem do enigma
              : Lottie.asset(
                  'assets/animations/no_enigma.json',
                ), // Mostra a animação padrão
        ),
        const SizedBox(height: 16),
        Text(widget.enigma.instruction, style: const TextStyle(fontSize: 18)),
      ],
    );
  }

  Widget _buildQrCodeGpsUI() {
    return Column(
      children: [
        // --- LÓGICA ATUALIZADA ---
        if (widget.enigma.imageUrl != null &&
            widget.enigma.imageUrl!.isNotEmpty)
          SizedBox(
            height: 200,
            width: double.infinity,
            child: Image.network(widget.enigma.imageUrl!),
          )
        else
          SizedBox(
            height: 200,
            width: double.infinity,
            child: Lottie.asset('assets/animations/no_enigma.json'),
          ),
        const SizedBox(height: 16),
        Text(
          widget.enigma.instruction,
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
          onPressed: _isNear
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
          icon: const Icon(Icons.qr_code_scanner),
          label: Text(_isNear ? 'Escanear QR Code' : 'Aproxime-se do local'),
          style: ElevatedButton.styleFrom(
            backgroundColor: _isNear ? Colors.green : Colors.grey.shade800,
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
          ),
        ),
      ],
    );
  }

  // --- NOVO MÉTODO AUXILIAR PARA ABRIR O MAPS ---
  Future<void> _launchMapsUrl(String coordinates) async {
    // Constrói a URL universal do Google Maps
    final Uri googleMapsUrl = Uri.parse(
      'https://www.google.com/maps/search/?api=1&query=$coordinates',
    );

    try {
      // Tenta abrir a URL
      if (await canLaunchUrl(googleMapsUrl)) {
        await launchUrl(googleMapsUrl);
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

  // --- MÉTODO _buildHintSection ATUALIZADO ---
  Widget _buildHintSection() {
    // Se a dica ainda não foi comprada, mostra o botão para comprar
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

    // Se a dica já foi comprada e os dados estão disponíveis
    if (_isHintVisible && _hintData != null) {
      final String type = _hintData!['type'];
      final String data = _hintData!['data'];

      Widget hintContent;
      Widget actionButton;

      // Define o conteúdo da dica e o botão de ação com base no tipo
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
        final lat = double.parse(coords[0]);
        final lng = double.parse(coords[1]);
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
        // --- BOTÃO ATUALIZADO AQUI ---
        // Agora, para dicas de GPS, o botão abre o Google Maps
        actionButton = ElevatedButton.icon(
          onPressed: () => _launchMapsUrl(data), // Chama o novo método
          icon: const Icon(Icons.map_rounded),
          label: const Text('Ver no Google Maps'),
        );
      } else {
        // 'text'
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

  Widget _buildCodeInputSection(bool isBlocked) {
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
            enabled: !isBlocked,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 24,
              letterSpacing: 8,
              color: isBlocked ? secondaryTextColor : textColor,
            ),
            decoration: InputDecoration(
              hintText: 'XXX-XXX-XXX',
              hintStyle: TextStyle(color: secondaryTextColor.withOpacity(0.5)),
              filled: true,
              fillColor: isBlocked ? Colors.grey.shade800 : darkBackground,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: 24),
          if (isBlocked)
            Text(
              "Tente novamente em: $_cooldownTimeLeft",
              style: const TextStyle(
                color: Colors.red,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            )
          else
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _isLoading
                    ? null
                    : () => _handleAction(
                        'validateCode',
                        code: _codeController.text.trim(),
                      ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryAmber,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                icon: _isLoading
                    ? Container()
                    : const Icon(Icons.send, color: darkBackground),
                label: _isLoading
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(color: darkBackground),
                      )
                    : const Text(
                        'Verificar Código',
                        style: TextStyle(
                          color: darkBackground,
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

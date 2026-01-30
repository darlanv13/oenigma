import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:screenshot/screenshot.dart';
import 'package:saver_gallery/saver_gallery.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:oenigma/models/enigma_model.dart';
import 'package:oenigma/services/firebase_service.dart';
import 'package:oenigma/utils/app_colors.dart';
import 'package:oenigma/widgets/lottie_dialog.dart';

class EnigmaFormScreen extends StatefulWidget {
  final String eventId;
  final String? phaseId;
  final String eventType;
  final EnigmaModel? enigma;

  const EnigmaFormScreen({
    super.key,
    required this.eventId,
    required this.eventType,
    this.phaseId,
    this.enigma,
  });

  @override
  _EnigmaFormScreenState createState() => _EnigmaFormScreenState();
}

class _EnigmaFormScreenState extends State<EnigmaFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final FirebaseService _firebaseService = FirebaseService();
  final ScreenshotController _screenshotController = ScreenshotController();
  bool _isLoading = false;
  bool _isUploading = false;

  late TextEditingController _instructionController;
  late TextEditingController _codeController;
  late TextEditingController _imageUrlController;
  late TextEditingController _hintDataController;
  late TextEditingController _hintPriceController;
  late TextEditingController _prizeController;
  late TextEditingController _orderController;
  late TextEditingController _latitudeController;
  late TextEditingController _longitudeController;

  String _selectedEnigmaType = 'text';
  String? _selectedHintType;

  LatLng? _selectedLocation;
  Set<Marker> _markers = {};

  @override
  void initState() {
    super.initState();
    final enigma = widget.enigma;

    _instructionController = TextEditingController(text: enigma?.instruction);
    _codeController = TextEditingController(text: enigma?.code);
    _imageUrlController = TextEditingController(text: enigma?.imageUrl);
    _hintDataController = TextEditingController(text: enigma?.hintData);
    _hintPriceController = TextEditingController(
      text: enigma?.hintPrice.toString() ?? '0.0',
    );
    _prizeController = TextEditingController(
      text: enigma?.prize.toString() ?? '0.0',
    );
    _orderController = TextEditingController(
      text: enigma?.order.toString() ?? '1',
    );
    _latitudeController = TextEditingController(
      text: enigma?.location?.latitude.toString(),
    );
    _longitudeController = TextEditingController(
      text: enigma?.location?.longitude.toString(),
    );

    if (enigma != null) {
      _selectedEnigmaType = enigma.type;
      _selectedHintType = enigma.hintType;

      if (enigma.location != null) {
        _selectedLocation = LatLng(enigma.location!.latitude, enigma.location!.longitude);
        _markers = {
          Marker(markerId: const MarkerId('selected'), position: _selectedLocation!),
        };
      }
    }

    _imageUrlController.addListener(() {
      setState(() {});
    });
  }

  @override
  void dispose() {
    _instructionController.dispose();
    _codeController.dispose();
    _imageUrlController.dispose();
    _hintDataController.dispose();
    _hintPriceController.dispose();
    _prizeController.dispose();
    _orderController.dispose();
    _latitudeController.dispose();
    _longitudeController.dispose();
    super.dispose();
  }

  void _showQRCodeDialog() {
    if (widget.enigma == null) return;

    final data = widget.enigma!.id;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        title: const Text("QR Code do Enigma", style: TextStyle(color: Colors.black)),
        content: SizedBox(
          width: 250,
          height: 250,
          child: Column(
             mainAxisSize: MainAxisSize.min,
             children: [
               Expanded(
                 child: Center(
                    child: Screenshot(
                      controller: _screenshotController,
                      child: Container(
                        color: Colors.white,
                        padding: const EdgeInsets.all(8),
                        child: QrImageView(
                          data: data,
                          version: QrVersions.auto,
                          size: 200.0,
                        ),
                      ),
                    ),
                 ),
               ),
               const SizedBox(height: 8),
               Text(data, style: const TextStyle(color: Colors.black54, fontSize: 10)),
             ],
          ),
        ),
        actions: [
          TextButton.icon(
             icon: const Icon(Icons.download, color: primaryAmber),
             label: const Text("Salvar na Galeria", style: TextStyle(color: primaryAmber)),
             onPressed: () async {
                final image = await _screenshotController.capture();
                if (image == null) return;

                if (!kIsWeb && (defaultTargetPlatform == TargetPlatform.android || defaultTargetPlatform == TargetPlatform.iOS)) {
                   var status = await Permission.storage.status;
                   if (!status.isGranted) {
                     status = await Permission.storage.request();
                   }
                   if (!status.isGranted && !await Permission.photos.request().isGranted) return;
                }

                try {
                  final result = await SaverGallery.saveImage(
                     Uint8List.fromList(image),
                     quality: 100,
                     name: "qr_code_${widget.enigma!.id}",
                     androidExistNotSave: false,
                  );
                  if (context.mounted) {
                     ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Salvo na galeria: $result")));
                  }
                } catch (e) {
                   if (context.mounted) {
                     ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Erro ao salvar: $e")));
                   }
                }
             },
          ),
          TextButton(
            child: const Text("Fechar"),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }

  Future<void> _pickAndUploadImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      setState(() => _isUploading = true);

      try {
        final ref = FirebaseStorage.instance
            .ref()
            .child('enigma_images')
            .child('${DateTime.now().millisecondsSinceEpoch}.jpg');

        await ref.putData(await pickedFile.readAsBytes());

        final url = await ref.getDownloadURL();

        setState(() {
          _imageUrlController.text = url;
          _isUploading = false;
        });
      } catch (e) {
        setState(() => _isUploading = false);
        if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Erro ao enviar imagem: $e")));
        }
      }
    }
  }

  Future<void> _saveEnigma() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);

      Map<String, double>? locationData;
      if (_selectedEnigmaType == 'qr_code_gps') {
        final lat = double.tryParse(_latitudeController.text);
        final lon = double.tryParse(_longitudeController.text);
        if (lat != null && lon != null) {
          locationData = {'_latitude': lat, '_longitude': lon};
        }
      }

      final data = {
        'instruction': _instructionController.text,
        'code': _codeController.text,
        'type': _selectedEnigmaType,
        'order': int.tryParse(_orderController.text) ?? 1,
        'prize': double.tryParse(_prizeController.text) ?? 0.0,
        'imageUrl': _imageUrlController.text.isNotEmpty
            ? _imageUrlController.text
            : null,
        'hintType': _selectedHintType,
        'hintData': _hintDataController.text.isNotEmpty
            ? _hintDataController.text
            : null,
        'hintPrice': double.tryParse(_hintPriceController.text) ?? 0.0,
        'location': locationData,
      };

      try {
        await _firebaseService.createOrUpdateEnigma(
          eventId: widget.eventId,
          phaseId: widget.phaseId,
          enigmaId: widget.enigma?.id,
          data: data,
        );

        if (mounted) {
          await LottieDialog.show(
            context,
            assetPath: 'assets/animations/check.json',
            message: 'Enigma Salvo!'
          );
          Navigator.of(context).pop(true);
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Erro ao salvar enigma: $e'),
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
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.enigma == null ? 'Criar Enigma' : 'Editar Enigma'),
        actions: [
          if (widget.enigma != null)
            IconButton(
              icon: const Icon(Icons.qr_code, color: primaryAmber),
              onPressed: _showQRCodeDialog,
              tooltip: "Gerar QR Code",
            ),
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 800),
          child: Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.all(16.0),
              children: [
                _buildCardSection("Pergunta & Resposta", [
                  _buildTextField(
                    controller: _instructionController,
                    label: 'Instrução / Pergunta',
                    maxLines: 3,
                  ),
                  const SizedBox(height: 10),
                  _buildTextField(
                    controller: _codeController,
                    label: 'Código / Resposta Correta',
                  ),
                  const SizedBox(height: 10),
                  _buildTextField(
                    controller: _orderController,
                    label: 'Ordem',
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 10),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                       Expanded(
                         child: _buildTextField(
                           controller: _imageUrlController,
                           label: 'URL da Imagem (Opcional)',
                         ),
                       ),
                       const SizedBox(width: 8),
                       Container(
                         decoration: BoxDecoration(
                           color: darkBackground,
                           borderRadius: BorderRadius.circular(8),
                           border: Border.all(color: Colors.grey.withOpacity(0.3)),
                         ),
                         child: IconButton(
                           icon: _isUploading
                              ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: primaryAmber))
                              : const Icon(Icons.cloud_upload, color: primaryAmber),
                           onPressed: _isUploading ? null : _pickAndUploadImage,
                           tooltip: "Enviar Imagem",
                         ),
                       ),
                    ],
                  ),
                  if (_imageUrlController.text.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 10.0),
                      child: Center(
                        child: Container(
                          height: 150,
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.network(
                              _imageUrlController.text,
                              fit: BoxFit.contain,
                              errorBuilder: (context, error, stackTrace) =>
                                  const Center(
                                    child: Icon(
                                      Icons.broken_image,
                                      color: Colors.red,
                                    ),
                                  ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  if (widget.eventType == 'find_and_win')
                    Padding(
                      padding: const EdgeInsets.only(top: 10.0),
                      child: _buildTextField(
                        controller: _prizeController,
                        label: 'Prêmio deste Enigma',
                        keyboardType: TextInputType.number,
                      ),
                    ),
                ]),
                const SizedBox(height: 16),

                _buildCardSection("Configuração do Enigma", [
                  _buildDropdown(
                    label: 'Tipo de Enigma',
                    value: _selectedEnigmaType,
                    items: const [
                      DropdownMenuItem(value: 'text', child: Text('Texto')),
                      DropdownMenuItem(
                        value: 'photo_location',
                        child: Text('Localização por Foto'),
                      ),
                      DropdownMenuItem(
                        value: 'qr_code_gps',
                        child: Text('QR Code com GPS'),
                      ),
                    ],
                    onChanged: (value) =>
                        setState(() => _selectedEnigmaType = value!),
                  ),
                  if (_selectedEnigmaType == 'qr_code_gps') ...[
                    const SizedBox(height: 16),
                    const Text(
                      "Localização (Toque no mapa ou edite abaixo)",
                      style: TextStyle(
                        color: primaryAmber,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      height: 300,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: GoogleMap(
                          initialCameraPosition: CameraPosition(
                            target: _selectedLocation ?? const LatLng(-23.5505, -46.6333), // Default SP
                            zoom: 15,
                          ),
                          gestureRecognizers: {
                            Factory<OneSequenceGestureRecognizer>(
                              () => EagerGestureRecognizer(),
                            ),
                          },
                          onTap: (pos) {
                            setState(() {
                              _selectedLocation = pos;
                              _latitudeController.text = pos.latitude.toString();
                              _longitudeController.text = pos.longitude.toString();
                              _markers = {
                                Marker(markerId: const MarkerId('selected'), position: pos),
                              };
                            });
                          },
                          markers: _markers,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: _buildTextField(
                            controller: _latitudeController,
                            label: 'Latitude',
                            keyboardType: TextInputType.number,
                            validator: (v) {
                              if (v == null || v.isEmpty) return 'Obrigatório';
                              final n = double.tryParse(v);
                              if (n == null || n < -90 || n > 90)
                                return '-90 a 90';
                              return null;
                            },
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _buildTextField(
                            controller: _longitudeController,
                            label: 'Longitude',
                            keyboardType: TextInputType.number,
                            validator: (v) {
                              if (v == null || v.isEmpty) return 'Obrigatório';
                              final n = double.tryParse(v);
                              if (n == null || n < -180 || n > 180)
                                return '-180 a 180';
                              return null;
                            },
                          ),
                        ),
                      ],
                    ),
                  ],
                ]),
                const SizedBox(height: 16),

                _buildCardSection("Sistema de Dicas", [
                  _buildDropdown(
                    label: 'Tipo de Dica',
                    value: _selectedHintType,
                    items: const [
                      DropdownMenuItem(value: null, child: Text('Nenhuma')),
                      DropdownMenuItem(value: 'text', child: Text('Texto')),
                      DropdownMenuItem(
                        value: 'photo',
                        child: Text('Foto (URL)'),
                      ),
                      DropdownMenuItem(
                        value: 'gps',
                        child: Text('Coordenadas GPS'),
                      ),
                    ],
                    onChanged: (value) =>
                        setState(() => _selectedHintType = value),
                  ),
                  if (_selectedHintType != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 10.0),
                      child: Column(
                        children: [
                          _buildTextField(
                            controller: _hintDataController,
                            label: 'Conteúdo da Dica',
                            maxLines: 3,
                          ),
                          const SizedBox(height: 10),
                          _buildTextField(
                            controller: _hintPriceController,
                            label: 'Custo da Dica (Moedas)',
                            keyboardType: TextInputType.number,
                          ),
                          if (_selectedHintType == 'photo' &&
                              _hintDataController.text.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(top: 10.0),
                              child: Center(
                                child: Container(
                                  height: 100,
                                  decoration: BoxDecoration(
                                    border: Border.all(color: Colors.grey),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: Image.network(
                                      _hintDataController.text,
                                      fit: BoxFit.contain,
                                      errorBuilder:
                                          (context, error, stackTrace) =>
                                              const Center(
                                                child: Icon(
                                                  Icons.broken_image,
                                                  color: Colors.red,
                                                ),
                                              ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                ]),

                const SizedBox(height: 32),
                _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.all(16),
                          backgroundColor: primaryAmber,
                          foregroundColor: darkBackground,
                        ),
                        onPressed: _saveEnigma,
                        icon: const Icon(Icons.save),
                        label: const Text(
                          'Salvar Enigma',
                          style: TextStyle(
                            fontSize: 16,
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

  Widget _buildCardSection(String title, List<Widget> children) {
    return Card(
      color: cardColor,
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: primaryAmber,
              ),
            ),
            Divider(color: Colors.grey.withOpacity(0.3)),
            const SizedBox(height: 16),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    int maxLines = 1,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: secondaryTextColor),
        filled: true,
        fillColor: darkBackground,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: primaryAmber),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.grey.withOpacity(0.3)),
        ),
        alignLabelWithHint: true,
      ),
      maxLines: maxLines,
      keyboardType: keyboardType,
      validator:
          validator ??
          (v) {
            if (label.contains('Instrução') || label.contains('Código')) {
              if (v == null || v.isEmpty) return 'Este campo é obrigatório';
            }
            return null;
          },
      onChanged: (value) {
        if (label.contains('URL') || label.contains('Dica')) {
          setState(() {}); // Trigger rebuild for preview
        }
      },
    );
  }

  Widget _buildDropdown({
    required String label,
    required String? value,
    required List<DropdownMenuItem<String?>> items,
    required ValueChanged<String?> onChanged,
  }) {
    return DropdownButtonFormField<String?>(
      value: value,
      dropdownColor: cardColor,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: secondaryTextColor),
        filled: true,
        fillColor: darkBackground,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: primaryAmber),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.grey.withOpacity(0.3)),
        ),
      ),
      items: items,
      onChanged: onChanged,
    );
  }
}

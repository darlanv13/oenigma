// lib/admin/screens/enigma_studio_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:oenigma/admin/stores/enigma_store.dart'; // Importe sua store
import 'package:oenigma/models/enigma_model.dart';
import 'package:oenigma/utils/app_colors.dart';
import 'package:oenigma/widgets/lottie_dialog.dart';

class EnigmaStudioScreen extends StatefulWidget {
  final String eventId;
  final String? phaseId;
  final String eventType;
  final EnigmaModel? enigma;

  const EnigmaStudioScreen({
    super.key,
    required this.eventId,
    required this.eventType,
    this.phaseId,
    this.enigma,
  });

  @override
  State<EnigmaStudioScreen> createState() => _EnigmaStudioScreenState();
}

class _EnigmaStudioScreenState extends State<EnigmaStudioScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final EnigmaStore _store = EnigmaStore();

  // Controllers de texto apenas para inputs, sincronizados com a store
  late TextEditingController _instructionCtrl;
  late TextEditingController _codeCtrl;
  late TextEditingController _imageUrlCtrl;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);

    // Carregar dados se for edição
    if (widget.enigma != null) {
      _store.loadFromModel(widget.enigma!);
    }

    // Inicializar controllers com valores iniciais da store
    _instructionCtrl = TextEditingController(text: _store.instruction);
    _codeCtrl = TextEditingController(text: _store.code);
    _imageUrlCtrl = TextEditingController(text: _store.imageUrl);

    // Sync Reverso: TextField -> Store
    _instructionCtrl.addListener(
      () => _store.setInstruction(_instructionCtrl.text),
    );
    _codeCtrl.addListener(() => _store.setCode(_codeCtrl.text));
    _imageUrlCtrl.addListener(() => _store.setImageUrl(_imageUrlCtrl.text));
  }

  @override
  void dispose() {
    _tabController.dispose();
    _instructionCtrl.dispose();
    _codeCtrl.dispose();
    _imageUrlCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: darkBackground,
      appBar: AppBar(
        title: Text(
          "ESTÚDIO DE CRIAÇÃO",
          style: GoogleFonts.orbitron(
            letterSpacing: 1,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: cardColor,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: primaryAmber,
          labelColor: primaryAmber,
          unselectedLabelColor: Colors.grey,
          indicatorWeight: 3,
          tabs: const [
            Tab(icon: Icon(Icons.tune), text: "CONFIGURAÇÃO"),
            Tab(icon: Icon(Icons.remove_red_eye), text: "PREVIEW AO VIVO"),
          ],
        ),
        actions: [
          Observer(
            builder: (_) {
              return IconButton(
                icon: _store.isSaving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          color: primaryAmber,
                          strokeWidth: 2,
                        ),
                      )
                    : const Icon(Icons.save, color: primaryAmber),
                onPressed: _store.isSaving ? null : _handleSave,
              );
            },
          ),
        ],
      ),
      body: TabBarView(
        controller: _tabController,
        children: [_buildConfigTab(), _buildPreviewTab()],
      ),
    );
  }

  // --- ABA 1: CONFIGURAÇÃO ---
  Widget _buildConfigTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader("DADOS PRINCIPAIS"),
          _buildInput(
            _instructionCtrl,
            "Instrução / Pergunta",
            icon: Icons.description,
            maxLines: 3,
          ),
          const SizedBox(height: 16),
          _buildInput(_codeCtrl, "Resposta (Código)", icon: Icons.vpn_key),

          const SizedBox(height: 24),
          _buildSectionHeader("MECÂNICA"),
          _buildTypeSelector(),

          // Renderização Condicional com Observer
          Observer(
            builder: (_) {
              if (_store.type == 'qr_code_gps') {
                return Padding(
                  padding: const EdgeInsets.only(top: 16),
                  child: _buildGpsPicker(),
                );
              }
              return const SizedBox.shrink();
            },
          ),

          const SizedBox(height: 24),
          _buildSectionHeader("VISUAL & DICAS"),
          Row(
            children: [
              Expanded(
                child: _buildInput(
                  _imageUrlCtrl,
                  "URL da Imagem",
                  icon: Icons.image,
                ),
              ),
              const SizedBox(width: 8),
              _buildUploadButton(),
            ],
          ),
          const SizedBox(height: 16),
          // Exemplo de campo numérico
          Row(
            children: [
              Expanded(
                child: _buildInput(
                  TextEditingController(text: _store.order.toString()),
                  "Ordem",
                  icon: Icons.sort,
                  onChanged: _store.setOrder,
                  isNumber: true,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildInput(
                  TextEditingController(text: _store.prize.toString()),
                  "Prêmio",
                  icon: Icons.emoji_events,
                  onChanged: _store.setPrize,
                  isNumber: true,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // --- ABA 2: PREVIEW ---
  Widget _buildPreviewTab() {
    return Container(
      color: Colors.black,
      alignment: Alignment.center,
      child: Container(
        width: 380, // Largura fixa simulando celular
        height: 750,
        margin: const EdgeInsets.symmetric(vertical: 20),
        decoration: BoxDecoration(
          color: darkBackground,
          borderRadius: BorderRadius.circular(30),
          border: Border.all(color: const Color(0xFF333333), width: 8),
          boxShadow: [
            BoxShadow(color: primaryAmber.withOpacity(0.1), blurRadius: 40),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(22),
          child: Scaffold(
            backgroundColor: darkBackground,
            appBar: AppBar(
              title: Text(
                "Fase ${_store.order}",
                style: GoogleFonts.orbitron(fontSize: 16, color: primaryAmber),
              ),
              centerTitle: true,
              backgroundColor: Colors.transparent,
              elevation: 0,
              automaticallyImplyLeading: false,
            ),
            body: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Card do Enigma Reativo
                  Observer(
                    builder: (_) {
                      return Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: cardColor,
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(color: Colors.white10),
                        ),
                        child: Column(
                          children: [
                            if (_store.imageUrl.isNotEmpty)
                              ClipRRect(
                                borderRadius: BorderRadius.circular(16),
                                child: Image.network(
                                  _store.imageUrl,
                                  height: 180,
                                  width: double.infinity,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) => Container(
                                    height: 150,
                                    color: Colors.white10,
                                    child: const Icon(
                                      Icons.broken_image,
                                      color: Colors.white24,
                                    ),
                                  ),
                                ),
                              )
                            else
                              const Icon(
                                Icons.help_outline,
                                size: 80,
                                color: Colors.white10,
                              ),

                            const SizedBox(height: 24),

                            Text(
                              _store.instruction.isEmpty
                                  ? "Digite uma instrução..."
                                  : _store.instruction,
                              style: const TextStyle(
                                fontSize: 18,
                                color: textColor,
                                height: 1.5,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      );
                    },
                  ),

                  const SizedBox(height: 32),

                  // Campo de Código Simulado
                  TextField(
                    enabled: false,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.orbitron(
                      fontSize: 24,
                      color: primaryAmber,
                      letterSpacing: 4,
                    ),
                    decoration: InputDecoration(
                      hintText: "CÓDIGO",
                      hintStyle: const TextStyle(color: Colors.white12),
                      filled: true,
                      fillColor: cardColor,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  ElevatedButton(
                    onPressed: null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryAmber,
                      padding: const EdgeInsets.symmetric(vertical: 20),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      disabledBackgroundColor: primaryAmber.withOpacity(0.5),
                    ),
                    child: Text(
                      "DECODIFICAR",
                      style: GoogleFonts.orbitron(
                        color: Colors.black,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),

                  // Debug Info no Preview (Opcional)
                  const SizedBox(height: 40),
                  Observer(
                    builder: (_) => Text(
                      "Tipo: ${_store.type.toUpperCase()}\nGPS: ${_store.location != null ? 'ATIVO' : 'INATIVO'}",
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.grey, fontSize: 10),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // --- HELPERS DE UI ---

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        title,
        style: GoogleFonts.orbitron(
          color: primaryAmber,
          fontSize: 12,
          letterSpacing: 2,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildInput(
    TextEditingController ctrl,
    String label, {
    IconData? icon,
    int maxLines = 1,
    bool isNumber = false,
    Function(String)? onChanged,
  }) {
    return TextField(
      controller: ctrl,
      maxLines: maxLines,
      keyboardType: isNumber ? TextInputType.number : TextInputType.text,
      onChanged:
          onChanged, // Usado para campos que não têm listener direto no init
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: secondaryTextColor),
        prefixIcon: icon != null ? Icon(icon, color: primaryAmber) : null,
        filled: true,
        fillColor: cardColor,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: primaryAmber),
        ),
      ),
    );
  }

  Widget _buildTypeSelector() {
    return SizedBox(
      height: 90,
      child: Observer(
        builder: (_) {
          return ListView(
            scrollDirection: Axis.horizontal,
            children: [
              _buildTypeOption('text', Icons.text_fields, "Texto"),
              _buildTypeOption(
                'photo_location',
                Icons.camera_alt,
                "Foto Local",
              ),
              _buildTypeOption('qr_code_gps', Icons.qr_code_2, "QR + GPS"),
            ],
          );
        },
      ),
    );
  }

  Widget _buildTypeOption(String typeKey, IconData icon, String label) {
    final isSelected = _store.type == typeKey;
    return GestureDetector(
      onTap: () => _store.setType(typeKey),
      child: Container(
        width: 100,
        margin: const EdgeInsets.only(right: 12),
        decoration: BoxDecoration(
          color: isSelected ? primaryAmber.withOpacity(0.15) : cardColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? primaryAmber : Colors.transparent,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: isSelected ? primaryAmber : secondaryTextColor,
              size: 28,
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : secondaryTextColor,
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGpsPicker() {
    return Container(
      height: 200,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: primaryAmber.withOpacity(0.5)),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Stack(
          children: [
            GoogleMap(
              initialCameraPosition: CameraPosition(
                target: _store.location ?? const LatLng(-23.55, -46.63),
                zoom: 15,
              ),
              onTap: (pos) => _store.setLocation(pos),
              markers: _store.location != null
                  ? {
                      Marker(
                        markerId: const MarkerId('1'),
                        position: _store.location!,
                      ),
                    }
                  : {},
              liteModeEnabled: true,
              myLocationButtonEnabled: false,
            ),
            if (_store.location == null)
              Container(
                color: Colors.black54,
                child: const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.touch_app, color: Colors.white, size: 40),
                      SizedBox(height: 8),
                      Text(
                        "Toque para definir o local",
                        style: TextStyle(color: Colors.white),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildUploadButton() {
    return Container(
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: IconButton(
        icon: const Icon(Icons.cloud_upload, color: primaryAmber),
        onPressed: () {
          // Implemente sua lógica de upload aqui chamando a Store se necessário
          // Ex: _store.uploadImage();
        },
      ),
    );
  }

  Future<void> _handleSave() async {
    final success = await _store.saveEnigma(
      widget.eventId,
      widget.phaseId,
      widget.enigma?.id,
    );
    if (success && mounted) {
      await LottieDialog.show(
        context,
        assetPath: 'assets/animations/check.json',
        message: 'Salvo com sucesso!',
      );
      Navigator.pop(context);
    } else if (mounted && _store.errorMessage != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_store.errorMessage!),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}

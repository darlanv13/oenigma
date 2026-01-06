import 'package:cloud_firestore/cloud_firestore.dart'; // Necessário para GeoPoint
import 'package:flutter/material.dart';
import 'package:oenigma/models/enigma_model.dart';
import 'package:oenigma/utils/app_colors.dart';

class EnigmaEditorDialog extends StatefulWidget {
  final EnigmaModel? enigma;

  const EnigmaEditorDialog({super.key, this.enigma});

  @override
  State<EnigmaEditorDialog> createState() => _EnigmaEditorDialogState();
}

class _EnigmaEditorDialogState extends State<EnigmaEditorDialog> {
  final _formKey = GlobalKey<FormState>();

  // Controllers de Texto
  final _instructionCtrl = TextEditingController();
  final _codeCtrl = TextEditingController();
  final _imageUrlCtrl = TextEditingController();
  final _hintDataCtrl = TextEditingController();
  final _hintPriceCtrl = TextEditingController();
  final _prizeCtrl = TextEditingController(); // Novo: Prêmio do Enigma

  // Controllers para Geolocalização
  final _latCtrl = TextEditingController();
  final _lngCtrl = TextEditingController();

  String _type = 'text';

  @override
  void initState() {
    super.initState();
    if (widget.enigma != null) {
      _instructionCtrl.text = widget.enigma!.instruction;
      _codeCtrl.text = widget.enigma!.code;
      _imageUrlCtrl.text = widget.enigma!.imageUrl ?? '';
      _hintDataCtrl.text = widget.enigma!.hintData ?? '';
      _hintPriceCtrl.text = widget.enigma!.hintPrice.toString();
      _prizeCtrl.text = widget.enigma!.prize.toString();
      _type = widget.enigma!.type;

      // Preenche Lat/Lng se existir
      if (widget.enigma!.location != null) {
        _latCtrl.text = widget.enigma!.location!.latitude.toString();
        _lngCtrl.text = widget.enigma!.location!.longitude.toString();
      }
    } else {
      _hintPriceCtrl.text = "0.0";
      _prizeCtrl.text = "0.0";
    }
  }

  @override
  void dispose() {
    _instructionCtrl.dispose();
    _codeCtrl.dispose();
    _imageUrlCtrl.dispose();
    _hintDataCtrl.dispose();
    _hintPriceCtrl.dispose();
    _prizeCtrl.dispose();
    _latCtrl.dispose();
    _lngCtrl.dispose();
    super.dispose();
  }

  void _save() {
    if (_formKey.currentState!.validate()) {
      // Lógica de Geolocalização
      GeoPoint? location;
      if (_type == 'geo') {
        final double? lat = double.tryParse(_latCtrl.text);
        final double? lng = double.tryParse(_lngCtrl.text);
        if (lat != null && lng != null) {
          location = GeoPoint(lat, lng);
        }
      }

      final newEnigma = EnigmaModel(
        id:
            widget.enigma?.id ??
            '', // ID vazio indica novo (gerado no backend ou service)
        type: _type,
        instruction: _instructionCtrl.text,
        code: _codeCtrl.text.trim().toUpperCase(),
        imageUrl: _imageUrlCtrl.text.isEmpty ? null : _imageUrlCtrl.text,
        location: location, // Envia o GeoPoint
        // Monetização e Prêmios
        hintType: 'text',
        hintData: _hintDataCtrl.text,
        hintPrice: double.tryParse(_hintPriceCtrl.text) ?? 0.0,
        prize: double.tryParse(_prizeCtrl.text) ?? 0.0,

        order: widget.enigma?.order ?? 0, // A ordem é gerenciada pela lista pai
      );

      // Retorna o objeto para quem chamou (EventStructureScreen)
      // Lá o AdminService chamará a Cloud Function 'createOrUpdateEnigma'
      Navigator.pop(context, newEnigma);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: cardColor,
      insetPadding: const EdgeInsets.all(20),
      child: Container(
        width: 600,
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      widget.enigma == null ? "Novo Enigma" : "Editar Enigma",
                      style: const TextStyle(
                        fontSize: 22,
                        color: textColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close, color: Colors.grey),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // --- TIPO DE ENIGMA ---
                DropdownButtonFormField<String>(
                  value: _type,
                  dropdownColor: cardColor,
                  style: const TextStyle(color: textColor),
                  decoration: _inputDec("Tipo de Desafio"),
                  items: const [
                    DropdownMenuItem(
                      value: 'text',
                      child: Text("Texto / Pergunta Simples"),
                    ),
                    DropdownMenuItem(
                      value: 'image',
                      child: Text("Imagem + Código"),
                    ),
                    DropdownMenuItem(
                      value: 'geo',
                      child: Text("Geolocalização (GPS)"),
                    ),
                  ],
                  onChanged: (v) => setState(() => _type = v!),
                ),
                const SizedBox(height: 16),

                // --- CAMPOS DINÂMICOS ---
                if (_type == 'image')
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: _buildTextField(
                      "URL da Imagem",
                      _imageUrlCtrl,
                      icon: Icons.image,
                    ),
                  ),

                if (_type == 'geo')
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: Row(
                      children: [
                        Expanded(
                          child: _buildTextField(
                            "Latitude",
                            _latCtrl,
                            isNumber: true,
                            icon: Icons.map,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _buildTextField(
                            "Longitude",
                            _lngCtrl,
                            isNumber: true,
                          ),
                        ),
                      ],
                    ),
                  ),

                // --- DADOS BÁSICOS ---
                _buildTextField(
                  "Instrução / Pergunta",
                  _instructionCtrl,
                  maxLines: 2,
                ),
                const SizedBox(height: 16),
                _buildTextField(
                  "Resposta Certa (Código)",
                  _codeCtrl,
                  icon: Icons.vpn_key,
                ),
                const SizedBox(height: 24),

                // --- ECONOMIA (Dicas e Prêmios) ---
                const Divider(color: Colors.grey),
                const Text(
                  "Economia do Enigma",
                  style: TextStyle(
                    color: primaryAmber,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 10),

                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: 2,
                      child: _buildTextField("Dica (Texto)", _hintDataCtrl),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      flex: 1,
                      child: _buildTextField(
                        "Custo Dica (R\$)",
                        _hintPriceCtrl,
                        isNumber: true,
                        icon: Icons.monetization_on,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      flex: 1,
                      child: _buildTextField(
                        "Prêmio ao Resolver (R\$)",
                        _prizeCtrl,
                        isNumber: true,
                        icon: Icons.emoji_events,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 30),

                // --- AÇÕES ---
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text(
                        "Cancelar",
                        style: TextStyle(color: Colors.grey),
                      ),
                    ),
                    const SizedBox(width: 16),
                    ElevatedButton.icon(
                      icon: const Icon(Icons.check),
                      label: const Text("Concluir Edição"),
                      onPressed: _save,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  InputDecoration _inputDec(String label, {IconData? icon}) {
    return InputDecoration(
      labelText: label,
      suffixIcon: icon != null
          ? Icon(icon, color: Colors.grey, size: 20)
          : null,
      labelStyle: const TextStyle(color: Colors.grey),
      filled: true,
      fillColor: Colors.black26,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide.none,
      ),
    );
  }

  Widget _buildTextField(
    String label,
    TextEditingController ctrl, {
    bool isNumber = false,
    int maxLines = 1,
    IconData? icon,
  }) {
    return TextFormField(
      controller: ctrl,
      keyboardType: isNumber
          ? const TextInputType.numberWithOptions(decimal: true, signed: true)
          : TextInputType.text,
      maxLines: maxLines,
      style: const TextStyle(color: textColor),
      decoration: _inputDec(label, icon: icon),
      validator: (v) {
        if (_type == 'geo' && (label == 'Latitude' || label == 'Longitude')) {
          return v!.isEmpty ? "Obrigatório" : null;
        }
        if (label == 'URL da Imagem' && _type == 'image') {
          return v!.isEmpty ? "Obrigatório" : null;
        }
        return v!.isEmpty ? "Campo obrigatório" : null;
      },
    );
  }
}

import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:oenigma/core/services/ai_enigma_generator_service.dart';
import 'package:oenigma/core/utils/app_colors.dart';

class AiEnigmaGeneratorModal extends StatefulWidget {
  final Function(GeneratedEnigmaResult result) onApply;

  const AiEnigmaGeneratorModal({
    super.key,
    required this.onApply,
  });

  static Future<void> show(
    BuildContext context, {
    required Function(GeneratedEnigmaResult result) onApply,
  }) {
    return showDialog(
      context: context,
      barrierColor: Colors.black.withAlpha(200),
      builder: (context) => AiEnigmaGeneratorModal(onApply: onApply),
    );
  }

  @override
  State<AiEnigmaGeneratorModal> createState() => _AiEnigmaGeneratorModalState();
}

class _AiEnigmaGeneratorModalState extends State<AiEnigmaGeneratorModal> {
  final _locationController = TextEditingController();
  final _customKeyController = TextEditingController();
  bool _isLoading = false;
  bool _showApiKeyInput = false;
  GeneratedEnigmaResult? _generatedResult;

  final List<String> _themes = [
    '🏴‍☠️ Piratas & Tesouros',
    '🕵️‍♂️ Detetive Noir',
    '⚡ Cyberpunk & Hacker',
    '🏛️ Histórico & Mitologia',
    '👻 Sobrenatural & Arcano',
  ];
  late String _selectedTheme;

  final List<String> _difficulties = ['Fácil', 'Médio', 'Difícil', 'Lendário'];
  String _selectedDifficulty = 'Médio';

  @override
  void initState() {
    super.initState();
    _selectedTheme = _themes.first;
    _loadCustomKey();
  }

  Future<void> _loadCustomKey() async {
    final key = await AiEnigmaGeneratorService.getActiveApiKey();
    if (mounted && key.isNotEmpty) {
      _customKeyController.text = key;
    }
  }

  @override
  void dispose() {
    _locationController.dispose();
    _customKeyController.dispose();
    super.dispose();
  }

  Future<void> _generate() async {
    final loc = _locationController.text.trim();
    if (loc.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Informe o nome do ponto ou local de referência.'),
          backgroundColor: AppColors.danger,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      if (_customKeyController.text.trim().isNotEmpty) {
        await AiEnigmaGeneratorService.saveCustomApiKey(_customKeyController.text.trim());
      }

      final result = await AiEnigmaGeneratorService.generateEnigma(
        locationName: loc,
        theme: _selectedTheme,
        difficulty: _selectedDifficulty,
        customApiKey: _customKeyController.text.trim().isNotEmpty
            ? _customKeyController.text.trim()
            : null,
      );

      if (mounted) {
        setState(() {
          _generatedResult = result;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao gerar enigma: $e'),
            backgroundColor: AppColors.danger,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 680, maxHeight: 780),
        decoration: BoxDecoration(
          color: const Color(0xFF0F171D),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.amareloVale.withAlpha(120), width: 1.5),
          boxShadow: [
            BoxShadow(
              color: AppColors.amareloVale.withAlpha(35),
              blurRadius: 30,
              spreadRadius: 2,
            ),
          ],
        ),
        child: Column(
          children: [
            // Header Tático
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
              decoration: BoxDecoration(
                color: const Color(0xFF142028),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                border: const Border(
                  bottom: BorderSide(color: Color(0xFF1E3A45)),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.amareloVale.withAlpha(40),
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.amareloVale.withAlpha(150)),
                    ),
                    child: const FaIcon(
                      FontAwesomeIcons.wandMagicSparkles,
                      color: AppColors.amareloVale,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'CO-PILOTO IA • GERADOR TÁTICO',
                          style: GoogleFonts.rajdhani(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.2,
                            color: Colors.white,
                          ),
                        ),
                        Text(
                          'Crie charadas poéticas e pistas progressivas com Google Gemini',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            color: AppColors.cinzaMedio,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close, color: Colors.white70),
                  ),
                ],
              ),
            ),

            // Corpo Scrollável
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Input: Local de Referência
                    Text(
                      'PONTO OU MONUMENTO DE REFERÊNCIA',
                      style: GoogleFonts.rajdhani(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.0,
                        color: AppColors.amareloVale,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _locationController,
                      style: GoogleFonts.inter(color: Colors.white, fontSize: 14),
                      decoration: InputDecoration(
                        hintText: 'Ex: Catedral Metropolitana, Relógio da Praça Central...',
                        hintStyle: GoogleFonts.inter(color: Colors.white38, fontSize: 13),
                        filled: true,
                        fillColor: const Color(0xFF16232C),
                        prefixIcon: const Center(
                          widthFactor: 1,
                          child: FaIcon(FontAwesomeIcons.locationDot, color: AppColors.amareloVale, size: 16),
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: Color(0xFF1E3A45)),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: Color(0xFF1E3A45)),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: AppColors.amareloVale),
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Seletor de Tema
                    Text(
                      'ATMOSFERA DO ENIGMA',
                      style: GoogleFonts.rajdhani(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.0,
                        color: AppColors.amareloVale,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _themes.map((theme) {
                        final isSelected = _selectedTheme == theme;
                        return ChoiceChip(
                          label: Text(
                            theme,
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                              color: isSelected ? Colors.black : Colors.white70,
                            ),
                          ),
                          selected: isSelected,
                          selectedColor: AppColors.amareloVale,
                          backgroundColor: const Color(0xFF16232C),
                          side: BorderSide(
                            color: isSelected ? AppColors.amareloVale : const Color(0xFF1E3A45),
                          ),
                          onSelected: (val) {
                            if (val) setState(() => _selectedTheme = theme);
                          },
                        );
                      }).toList(),
                    ),

                    const SizedBox(height: 20),

                    // Seletor de Dificuldade
                    Text(
                      'DIFICULDADE',
                      style: GoogleFonts.rajdhani(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.0,
                        color: AppColors.amareloVale,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      children: _difficulties.map((diff) {
                        final isSelected = _selectedDifficulty == diff;
                        return ChoiceChip(
                          label: Text(
                            diff,
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                              color: isSelected ? Colors.black : Colors.white70,
                            ),
                          ),
                          selected: isSelected,
                          selectedColor: AppColors.verdeVale,
                          backgroundColor: const Color(0xFF16232C),
                          side: BorderSide(
                            color: isSelected ? AppColors.verdeVale : const Color(0xFF1E3A45),
                          ),
                          onSelected: (val) {
                            if (val) setState(() => _selectedDifficulty = diff);
                          },
                        );
                      }).toList(),
                    ),

                    const SizedBox(height: 16),

                    // Opção de configurar Chave de API
                    InkWell(
                      onTap: () => setState(() => _showApiKeyInput = !_showApiKeyInput),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Row(
                          children: [
                            Icon(
                              _showApiKeyInput ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                              color: AppColors.cinzaMedio,
                              size: 18,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'Configurar Chave Própria Gemini (Opcional)',
                              style: GoogleFonts.inter(fontSize: 12, color: AppColors.cinzaMedio),
                            ),
                          ],
                        ),
                      ),
                    ),
                    if (_showApiKeyInput) ...[
                      const SizedBox(height: 8),
                      TextField(
                        controller: _customKeyController,
                        obscureText: true,
                        style: GoogleFonts.inter(color: Colors.white, fontSize: 13),
                        decoration: InputDecoration(
                          hintText: 'Cole sua Gemini API Key aqui...',
                          hintStyle: GoogleFonts.inter(color: Colors.white38, fontSize: 12),
                          filled: true,
                          fillColor: const Color(0xFF16232C),
                          prefixIcon: const Center(
                            widthFactor: 1,
                            child: FaIcon(FontAwesomeIcons.key, color: AppColors.cinzaMedio, size: 14),
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: const BorderSide(color: Color(0xFF1E3A45)),
                          ),
                        ),
                      ),
                    ],

                    const SizedBox(height: 20),

                    // Botão de Gerar
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton.icon(
                        onPressed: _isLoading ? null : _generate,
                        icon: _isLoading
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black),
                              )
                            : const FaIcon(FontAwesomeIcons.bolt, size: 16, color: Colors.black),
                        label: Text(
                          _isLoading ? 'CRIANDO MISTÉRIO COM IA...' : 'GERAR ENIGMA & DICAS',
                          style: GoogleFonts.rajdhani(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.2,
                            color: Colors.black,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.amareloVale,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ),

                    // Resultado Gerado
                    if (_generatedResult != null) ...[
                      const SizedBox(height: 24),
                      Container(
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          color: const Color(0xFF142028),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: AppColors.amareloVale.withAlpha(100)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const FaIcon(FontAwesomeIcons.scroll, color: AppColors.amareloVale, size: 16),
                                const SizedBox(width: 8),
                                Text(
                                  'CHARADA GERADA:',
                                  style: GoogleFonts.rajdhani(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 1.0,
                                    color: AppColors.amareloVale,
                                  ),
                                ),
                                const Spacer(),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: AppColors.verdeVale.withAlpha(40),
                                    borderRadius: BorderRadius.circular(6),
                                    border: Border.all(color: AppColors.verdeVale),
                                  ),
                                  child: Text(
                                    'Raio: ${_generatedResult!.suggestedRadius}m',
                                    style: GoogleFonts.inter(fontSize: 11, color: Colors.white),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            Text(
                              _generatedResult!.instruction,
                              style: GoogleFonts.inter(
                                fontSize: 14,
                                height: 1.5,
                                color: Colors.white.withAlpha(230),
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                            const SizedBox(height: 16),
                            const Divider(color: Color(0xFF1E3A45)),
                            const SizedBox(height: 8),
                            Text(
                              'DICAS PROGRESSIVAS:',
                              style: GoogleFonts.rajdhani(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1.0,
                                color: AppColors.verdeVale,
                              ),
                            ),
                            const SizedBox(height: 8),
                            ..._generatedResult!.hints.asMap().entries.map((entry) {
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 6),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      '• Dica ${entry.key + 1}: ',
                                      style: GoogleFonts.inter(
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.amareloVale,
                                      ),
                                    ),
                                    Expanded(
                                      child: Text(
                                        entry.value,
                                        style: GoogleFonts.inter(fontSize: 12, color: Colors.white70),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }),
                            const SizedBox(height: 16),
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton.icon(
                                onPressed: () {
                                  widget.onApply(_generatedResult!);
                                  Navigator.of(context).pop();
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Enigma e dicas preenchidos com sucesso!'),
                                      backgroundColor: AppColors.verdeVale,
                                    ),
                                  );
                                },
                                icon: const Icon(Icons.check_circle, size: 18),
                                label: Text(
                                  'APLICAR AO ENIGMA',
                                  style: GoogleFonts.rajdhani(
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 1.1,
                                  ),
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.verdeVale,
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

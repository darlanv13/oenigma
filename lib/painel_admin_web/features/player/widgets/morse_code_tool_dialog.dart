import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:oenigma/core/utils/app_colors.dart';

class MorseCodeToolDialog extends StatefulWidget {
  const MorseCodeToolDialog({super.key});

  @override
  State<MorseCodeToolDialog> createState() => _MorseCodeToolDialogState();
}

class _MorseCodeToolDialogState extends State<MorseCodeToolDialog> {
  final _inputController = TextEditingController();
  String _decodedText = '';

  static const Map<String, String> _morseMap = {
    '.-': 'A', '-...': 'B', '-.-.': 'C', '-..': 'D', '.': 'E',
    '..-.': 'F', '--.': 'G', '....': 'H', '..': 'I', '.---': 'J',
    '-.-': 'K', '.-..': 'L', '--': 'M', '-.': 'N', '---': 'O',
    '.--.': 'P', '--.-': 'Q', '.-.': 'R', '...': 'S', '-': 'T',
    '..-': 'U', '...-': 'V', '.--': 'W', '-..-': 'X', '-.--': 'Y',
    '--..': 'Z', '-----': '0', '.----': '1', '..---': '2', '...--': '3',
    '....-': '4', '.....': '5', '-....': '6', '--...': '7', '---..': '8',
    '----.': '9',
  };

  @override
  void dispose() {
    _inputController.dispose();
    super.dispose();
  }

  void _decodeMorse() {
    final text = _inputController.text.trim();
    if (text.isEmpty) {
      setState(() => _decodedText = '');
      return;
    }

    final words = text.split(RegExp(r'\s{2,}|\s*/\s*'));
    final resultWords = <String>[];

    for (final word in words) {
      final letters = word.trim().split(RegExp(r'\s+'));
      final wordBuffer = StringBuffer();
      for (final letter in letters) {
        wordBuffer.write(_morseMap[letter] ?? '?');
      }
      resultWords.add(wordBuffer.toString());
    }

    setState(() => _decodedText = resultWords.join(' '));
  }

  void _addSymbol(String s) {
    _inputController.text = _inputController.text + s;
    _decodeMorse();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppColors.darkCardColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: const BorderSide(color: AppColors.verdeVale),
      ),
      child: Container(
        width: 460,
        padding: const EdgeInsets.all(22),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const FaIcon(FontAwesomeIcons.signal, color: AppColors.amareloVale, size: 16),
                    const SizedBox(width: 10),
                    Text(
                      'Tradutor de Código Morse',
                      style: GoogleFonts.poppins(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                IconButton(
                  icon: const FaIcon(FontAwesomeIcons.xmark, color: AppColors.cinzaMedio, size: 16),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 12),

            Text(
              'Separe cada letra com um espaço (ex: "... --- ..."):',
              style: GoogleFonts.poppins(color: AppColors.cinzaMedio, fontSize: 12),
            ),
            const SizedBox(height: 10),

            TextField(
              controller: _inputController,
              onChanged: (_) => _decodeMorse(),
              style: const TextStyle(color: Colors.white, fontSize: 14),
              decoration: InputDecoration(
                hintText: 'Digite pontos (.) e traços (-)...',
                hintStyle: GoogleFonts.poppins(color: AppColors.cinzaMedio, fontSize: 12),
                filled: true,
                fillColor: AppColors.darkBackground,
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
            const SizedBox(height: 10),

            // Teclado rápido de Morse
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: AppColors.darkBackground),
                    onPressed: () => _addSymbol('.'),
                    child: const Text('• Ponto (.)', style: TextStyle(color: AppColors.amareloVale, fontWeight: FontWeight.bold)),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: AppColors.darkBackground),
                    onPressed: () => _addSymbol('-'),
                    child: const Text('— Traço (-)', style: TextStyle(color: AppColors.amareloVale, fontWeight: FontWeight.bold)),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.darkBackground),
                  onPressed: () => _addSymbol(' '),
                  child: const Text('Espaço', style: TextStyle(color: Colors.white)),
                ),
              ],
            ),
            const SizedBox(height: 14),

            Text('Texto Traduzido:', style: GoogleFonts.poppins(color: AppColors.cinzaMedio, fontSize: 11, fontWeight: FontWeight.bold)),
            const SizedBox(height: 6),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.darkBackground,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.verdeVale.withValues(alpha: 0.3)),
              ),
              child: SelectableText(
                _decodedText.isEmpty ? 'A tradução aparecerá aqui...' : _decodedText,
                style: GoogleFonts.poppins(
                  color: _decodedText.isEmpty ? AppColors.cinzaMedio : Colors.greenAccent,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

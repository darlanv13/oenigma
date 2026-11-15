import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:oenigma/core/utils/app_colors.dart';

class CesarCipherToolDialog extends StatefulWidget {
  const CesarCipherToolDialog({super.key});

  @override
  State<CesarCipherToolDialog> createState() => _CesarCipherToolDialogState();
}

class _CesarCipherToolDialogState extends State<CesarCipherToolDialog> {
  final _inputController = TextEditingController();
  int _shift = 3;
  String _decodedText = '';

  @override
  void dispose() {
    _inputController.dispose();
    super.dispose();
  }

  void _decode() {
    final text = _inputController.text;
    final buffer = StringBuffer();

    for (int i = 0; i < text.length; i++) {
      final charCode = text.codeUnitAt(i);
      // Maiúsculas (A-Z)
      if (charCode >= 65 && charCode <= 90) {
        final shifted = (charCode - 65 - _shift) % 26;
        buffer.writeCharCode(shifted < 0 ? shifted + 26 + 65 : shifted + 65);
      }
      // Minúsculas (a-z)
      else if (charCode >= 97 && charCode <= 122) {
        final shifted = (charCode - 97 - _shift) % 26;
        buffer.writeCharCode(shifted < 0 ? shifted + 26 + 97 : shifted + 97);
      } else {
        buffer.writeCharCode(charCode);
      }
    }

    setState(() => _decodedText = buffer.toString());
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
                    const FaIcon(FontAwesomeIcons.lockOpen, color: AppColors.amareloVale, size: 16),
                    const SizedBox(width: 10),
                    Text(
                      'Decodificador Cifra de César',
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
            const SizedBox(height: 14),

            Text(
              'Cole o texto cifrado e ajuste o deslocamento para revelar a mensagem:',
              style: GoogleFonts.poppins(color: AppColors.cinzaMedio, fontSize: 12),
            ),
            const SizedBox(height: 10),

            TextField(
              controller: _inputController,
              onChanged: (_) => _decode(),
              style: const TextStyle(color: Colors.white, fontSize: 13),
              decoration: InputDecoration(
                hintText: 'Digite ou cole o texto cifrado aqui...',
                hintStyle: GoogleFonts.poppins(color: AppColors.cinzaMedio, fontSize: 12),
                filled: true,
                fillColor: AppColors.darkBackground,
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
            const SizedBox(height: 14),

            Row(
              children: [
                Text('Deslocamento (Chave): $_shift', style: GoogleFonts.poppins(color: AppColors.amareloVale, fontWeight: FontWeight.bold, fontSize: 12)),
                Expanded(
                  child: Slider(
                    value: _shift.toDouble(),
                    min: 1,
                    max: 25,
                    divisions: 24,
                    activeColor: AppColors.amareloVale,
                    inactiveColor: AppColors.darkCardBorder,
                    onChanged: (val) {
                      setState(() => _shift = val.toInt());
                      _decode();
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),

            Text('Resultado Decodificado:', style: GoogleFonts.poppins(color: AppColors.cinzaMedio, fontSize: 11, fontWeight: FontWeight.bold)),
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
                _decodedText.isEmpty ? 'O resultado decodificado aparecerá aqui...' : _decodedText,
                style: GoogleFonts.poppins(
                  color: _decodedText.isEmpty ? AppColors.cinzaMedio : Colors.greenAccent,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

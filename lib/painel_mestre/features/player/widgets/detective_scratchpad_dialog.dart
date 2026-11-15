import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:oenigma/core/utils/app_colors.dart';

/// Bloco de Anotações Tático & Ferramentas Rápidas do Detetive / Jogador
class DetectiveScratchpadDialog extends StatefulWidget {
  final String initialNotes;
  final ValueChanged<String> onNotesChanged;

  const DetectiveScratchpadDialog({
    super.key,
    required this.initialNotes,
    required this.onNotesChanged,
  });

  @override
  State<DetectiveScratchpadDialog> createState() =>
      _DetectiveScratchpadDialogState();
}

class _DetectiveScratchpadDialogState extends State<DetectiveScratchpadDialog> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialNotes);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _reverseText() {
    final text = _controller.text;
    final reversed = text.split('').reversed.join('');
    _controller.text = reversed;
    widget.onNotesChanged(reversed);
    setState(() {});
  }

  void _uppercaseText() {
    final text = _controller.text.toUpperCase();
    _controller.text = text;
    widget.onNotesChanged(text);
    setState(() {});
  }

  void _copyNotes() {
    Clipboard.setData(ClipboardData(text: _controller.text));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Anotações copiadas para a área de transferência!'),
        backgroundColor: AppColors.verdeVale,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _clearNotes() {
    _controller.clear();
    widget.onNotesChanged('');
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppColors.darkCardColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: const BorderSide(color: AppColors.amareloVale, width: 1.2),
      ),
      child: Container(
        width: 480,
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const FaIcon(
                      FontAwesomeIcons.penToSquare,
                      color: AppColors.amareloVale,
                      size: 16,
                    ),
                    const SizedBox(width: 10),
                    Text(
                      'Bloco de Anotações do Detetive',
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                IconButton(
                  icon: const FaIcon(
                    FontAwesomeIcons.xmark,
                    color: AppColors.cinzaMedio,
                    size: 16,
                  ),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              'Rascunhe hipóteses, combine letras ou teste anagramas livremente:',
              style: GoogleFonts.poppins(
                color: AppColors.cinzaMedio,
                fontSize: 11.5,
              ),
            ),
            const SizedBox(height: 12),

            // Textarea
            TextField(
              controller: _controller,
              maxLines: 7,
              onChanged: widget.onNotesChanged,
              style: GoogleFonts.firaCode(
                color: Colors.white,
                fontSize: 13,
                height: 1.4,
              ),
              decoration: InputDecoration(
                hintText: 'Escreva suas anotações e pistas aqui...',
                hintStyle: GoogleFonts.poppins(
                  color: AppColors.cinzaMedio.withValues(alpha: 0.6),
                  fontSize: 12,
                ),
                filled: true,
                fillColor: const Color(0xFF0C1013),
                contentPadding: const EdgeInsets.all(14),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.darkCardBorder),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.amareloVale),
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Ferramentas Rápidas
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: [
                ActionChip(
                  avatar: const Icon(Icons.swap_horiz_rounded, size: 14, color: AppColors.amareloVale),
                  label: Text('Inverter', style: GoogleFonts.poppins(fontSize: 11, color: Colors.white)),
                  backgroundColor: const Color(0xFF141E24),
                  side: const BorderSide(color: AppColors.darkCardBorder),
                  onPressed: _reverseText,
                ),
                ActionChip(
                  avatar: const Icon(Icons.text_fields_rounded, size: 14, color: AppColors.amareloVale),
                  label: Text('MAIÚSCULAS', style: GoogleFonts.poppins(fontSize: 11, color: Colors.white)),
                  backgroundColor: const Color(0xFF141E24),
                  side: const BorderSide(color: AppColors.darkCardBorder),
                  onPressed: _uppercaseText,
                ),
                ActionChip(
                  avatar: const Icon(Icons.copy_rounded, size: 14, color: AppColors.verdeVale),
                  label: Text('Copiar', style: GoogleFonts.poppins(fontSize: 11, color: Colors.white)),
                  backgroundColor: const Color(0xFF141E24),
                  side: const BorderSide(color: AppColors.darkCardBorder),
                  onPressed: _copyNotes,
                ),
                ActionChip(
                  avatar: const Icon(Icons.delete_outline_rounded, size: 14, color: Colors.redAccent),
                  label: Text('Limpar', style: GoogleFonts.poppins(fontSize: 11, color: Colors.white)),
                  backgroundColor: const Color(0xFF141E24),
                  side: const BorderSide(color: AppColors.darkCardBorder),
                  onPressed: _clearNotes,
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Botão Fechar
            Align(
              alignment: Alignment.centerRight,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.amareloVale,
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                onPressed: () => Navigator.pop(context),
                child: Text(
                  'Salvar & Voltar',
                  style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:oenigma/core/utils/app_colors.dart';

class ProgressiveHintsDialog extends StatefulWidget {
  final String enigmaTitle;
  final String freeClue;
  final String? revealedPaidHint;
  final VoidCallback onBuyLevel2;
  final VoidCallback onBuyLevel3;

  const ProgressiveHintsDialog({
    super.key,
    required this.enigmaTitle,
    required this.freeClue,
    this.revealedPaidHint,
    required this.onBuyLevel2,
    required this.onBuyLevel3,
  });

  @override
  State<ProgressiveHintsDialog> createState() => _ProgressiveHintsDialogState();
}

class _ProgressiveHintsDialogState extends State<ProgressiveHintsDialog> {
  bool _level1Expanded = true;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 520),
        padding: const EdgeInsets.all(22),
        decoration: BoxDecoration(
          color: const Color(0xFF0F171D),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: const Color(0xFF1E3A45),
            width: 1.2,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.7),
              blurRadius: 30,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: SingleChildScrollView(
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
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.amareloVale.withValues(alpha: 0.15),
                          shape: BoxShape.circle,
                        ),
                        child: const FaIcon(
                          FontAwesomeIcons.lightbulb,
                          color: AppColors.amareloVale,
                          size: 16,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        'CENTRAL DE PISTAS',
                        style: GoogleFonts.cinzel(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.0,
                        ),
                      ),
                    ],
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close, color: AppColors.cinzaMedio, size: 20),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                'Não trave na jornada! Utilize as pistas graduais do detetive:',
                style: GoogleFonts.inter(
                  color: AppColors.cinzaMedio,
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 18),

              // Nível 1: Pista Direcional Grátis
              _buildHintTierCard(
                tier: 1,
                title: 'Nível 1 • Pista Direcional',
                subtitle: 'Orientação tática para iniciar o raciocínio',
                badgeText: 'GRÁTIS',
                badgeColor: Colors.greenAccent,
                icon: FontAwesomeIcons.compass,
                isUnlocked: true,
                content: widget.freeClue.isNotEmpty
                    ? widget.freeClue
                    : 'Dica Direcional: Analise com calma os caracteres repetidos e tente correlacionar com o histórico do influenciador.',
                actionWidget: null,
              ),

              const SizedBox(height: 12),

              // Nível 2: Pista Reveladora (R$ 1,99)
              _buildHintTierCard(
                tier: 2,
                title: 'Nível 2 • Pista Reveladora',
                subtitle: 'Explicação detalhada do padrão ou cifra secreta',
                badgeText: widget.revealedPaidHint != null ? 'DESBLOQUEADO' : 'R\$ 1,99',
                badgeColor: AppColors.amareloVale,
                icon: FontAwesomeIcons.key,
                isUnlocked: widget.revealedPaidHint != null,
                content: widget.revealedPaidHint ?? 'Desbloqueie a pista que revela a técnica exata para quebrar a mensagem.',
                actionWidget: widget.revealedPaidHint != null
                    ? null
                    : ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.amareloVale,
                          foregroundColor: Colors.black,
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        icon: const FaIcon(FontAwesomeIcons.bolt, size: 12),
                        label: Text(
                          'Liberar por R\$ 1,99',
                          style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 11.5),
                        ),
                        onPressed: () {
                          Navigator.pop(context);
                          widget.onBuyLevel2();
                        },
                      ),
              ),

              const SizedBox(height: 12),

              // Nível 3: Super Dica Arsenal VIP (R$ 3,90)
              _buildHintTierCard(
                tier: 3,
                title: 'Nível 3 • Super Arsenal VIP',
                subtitle: 'Revelação assistida das primeiras letras e padrão final',
                badgeText: 'R\$ 3,90',
                badgeColor: const Color(0xFF00C9A7),
                icon: FontAwesomeIcons.shieldHalved,
                isUnlocked: false,
                content: 'Acesso total ao radar da charada para não perder o prêmio Pix!',
                actionWidget: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF00C9A7),
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  icon: const FaIcon(FontAwesomeIcons.lockOpen, size: 12),
                  label: Text(
                    'Super Arsenal R\$ 3,90',
                    style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 11.5),
                  ),
                  onPressed: () {
                    Navigator.pop(context);
                    widget.onBuyLevel3();
                  },
                ),
              ),

              const SizedBox(height: 16),
              Center(
                child: Text(
                  '⚡ Pagamento via Pix com liberação instantânea automática',
                  style: GoogleFonts.inter(
                    color: AppColors.cinzaMedio.withValues(alpha: 0.7),
                    fontSize: 10.5,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHintTierCard({
    required int tier,
    required String title,
    required String subtitle,
    required String badgeText,
    required Color badgeColor,
    required IconData icon,
    required bool isUnlocked,
    required String content,
    Widget? actionWidget,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF131D24),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isUnlocked ? badgeColor.withValues(alpha: 0.4) : const Color(0xFF1E3A45),
          width: isUnlocked ? 1.2 : 1.0,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              FaIcon(icon, color: badgeColor, size: 14),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.inter(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      subtitle,
                      style: GoogleFonts.inter(
                        color: AppColors.cinzaMedio,
                        fontSize: 10.5,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                decoration: BoxDecoration(
                  color: badgeColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: badgeColor.withValues(alpha: 0.4), width: 0.8),
                ),
                child: Text(
                  badgeText,
                  style: GoogleFonts.orbitron(
                    color: badgeColor,
                    fontSize: 9,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFF0C1318),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              content,
              style: GoogleFonts.inter(
                color: isUnlocked ? Colors.white.withValues(alpha: 0.9) : AppColors.cinzaMedio,
                fontSize: 12,
                height: 1.4,
                fontStyle: isUnlocked ? FontStyle.normal : FontStyle.italic,
              ),
            ),
          ),
          if (actionWidget != null) ...[
            const SizedBox(height: 10),
            Align(
              alignment: Alignment.centerRight,
              child: actionWidget,
            ),
          ],
        ],
      ),
    );
  }
}

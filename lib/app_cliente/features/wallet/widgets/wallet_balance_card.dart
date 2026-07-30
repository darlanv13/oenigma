import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:oenigma/app_cliente/core/models/user_wallet_model.dart';

class WalletBalanceCard extends StatelessWidget {
  final UserWalletModel wallet;
  final VoidCallback onDeposit;
  final VoidCallback onWithdraw;

  const WalletBalanceCard({
    super.key,
    required this.wallet,
    required this.onDeposit,
    required this.onWithdraw,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E), // Fundo painel escuro
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.05),
          width: 1.0,
        ),
      ),
      child: Column(
        children: [
          const Text(
            'SALDO DISPONÍVEL',
            style: TextStyle(
              color: Colors.grey,
              fontSize: 12,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'R\$ ${wallet.balance.toStringAsFixed(2).replaceAll('.', ',')}',
            style: GoogleFonts.orbitron(
              color: const Color(0xFFDCD6CC),
              fontSize: 40,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 32),
          Row(
            children: [
              // BOTÃO DE DEPÓSITO
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(24),
                    color: const Color(0xFFC7A55C),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFC7A55C).withValues(alpha: 0.2),
                        blurRadius: 15,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: ElevatedButton.icon(
                    onPressed: onDeposit,
                    icon: const FaIcon(
                      FontAwesomeIcons.arrowDown,
                      color: Colors.black,
                      size: 14,
                    ),
                    label: const Text(
                      'DEPOSITAR',
                      style: TextStyle(
                        color: Colors.black,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                        letterSpacing: 1.0,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(24),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              // BOTÃO DE SAQUE
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(24),
                    color: Colors.transparent,
                    border: Border.all(
                      color: const Color(0xFFC76F7A), // Cor rosada/vermelha
                      width: 1.5,
                    ),
                  ),
                  child: ElevatedButton.icon(
                    onPressed: onWithdraw,
                    icon: const FaIcon(
                      FontAwesomeIcons.arrowUp,
                      color: Color(0xFFC76F7A),
                      size: 14,
                    ),
                    label: const Text(
                      'SACAR',
                      style: TextStyle(
                        color: Color(0xFFC76F7A),
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                        letterSpacing: 1.0,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(24),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

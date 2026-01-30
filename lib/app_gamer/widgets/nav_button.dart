import 'package:flutter/material.dart';
import '../../utils/app_colors.dart';

class NavButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const NavButton({
    super.key,
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(
          12.0,
        ), // Raio para o efeito de ondulação
        child: Padding(
          // Espaçamento interno para aumentar a área de toque
          padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                color: primaryAmber, // Ícone sempre em âmbar
                size: 28,
              ),
              const SizedBox(height: 6),
              Text(
                label,
                style: const TextStyle(
                  // Texto em cinza para um visual mais suave
                  color: secondaryTextColor,
                  fontWeight: FontWeight.w500,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

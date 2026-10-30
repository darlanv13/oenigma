import 'package:flutter/material.dart';

/// Paleta Oficial Vale & Identidade Visual Moderna:
/// • Verde-Vale: #007D8A (ou #007E7A para aplicações digitais/impressão)
/// • Amarelo-Vale: #F3A522 (ou #EEA722 para variações de tela)
/// • Cinza Escuro (Tipografia / Ícones): #444444
/// • Cinza Médio (Subtítulos / Bordas / Inativos): #919191
class AppColors {
  // --- Verde-Vale (Cor Primária de Marca) ---
  static const Color verdeVale = Color(0xFF007D8A);
  static const Color verdeValeAlt = Color(0xFF007E7A);
  static const Color verdeValeLight = Color(0xFFE6F3F4);
  static const Color verdeValeSurface = Color(0xFFF0F8F9);
  static const Color verdeValeDark = Color(0xFF005861);
  static const Color verdeValeHover = Color(0xFF006B75);

  // --- Amarelo-Vale (Cor Secundária / Acentos / Prêmios / Moedas) ---
  static const Color amareloVale = Color(0xFFF3A522);
  static const Color amareloValeAlt = Color(0xFFEEA722);
  static const Color amareloValeLight = Color(0xFFFEF4E4);
  static const Color amareloValeDark = Color(0xFFD48B10);

  // --- Neutros, Tipografia & Ícones ---
  static const Color cinzaEscuro = Color(0xFF444444); // Tipografia principal & ícones
  static const Color cinzaPreto = Color(0xFF222222);   // Títulos de alto destaque
  static const Color cinzaMedio = Color(0xFF919191);   // Subtítulos e elementos secundários
  static const Color cinzaClaro = Color(0xFFF4F6F8);   // Superfícies suaves
  static const Color cinzaBorda = Color(0xFFE2E8F0);   // Bordas e divisores
  static const Color branco = Color(0xFFFFFFFF);

  // --- Superfícies da Aplicação ---
  static const Color scaffoldBackground = Color(0xFFF4F7F8);
  static const Color cardBackground = Color(0xFFFFFFFF);

  // --- Dark Mode / Painel Administrativo ---
  static const Color darkBackground = Color(0xFF0D1416);
  static const Color sidebarBackground = Color(0xFF080D0E);
  static const Color darkCardColor = Color(0xFF142023);

  // --- Feedback & Status ---
  static const Color danger = Color(0xFFE53935);
  static const Color success = Color(0xFF007D8A);
  static const Color warning = Color(0xFFF3A522);
  static const Color info = Color(0xFF0284C7);

  // --- Gradientes Modernos ---
  static const LinearGradient gradienteVerdeVale = LinearGradient(
    colors: [Color(0xFF007D8A), Color(0xFF009AA8)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient gradienteAmareloVale = LinearGradient(
    colors: [Color(0xFFF3A522), Color(0xFFFFB84D)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient gradienteHero = LinearGradient(
    colors: [Color(0xFF005861), Color(0xFF007D8A)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}

// ============================================================================
// ALIASES GLOBAIS (Garantem retrocompatibilidade total com as telas existentes)
// ============================================================================
const Color primaryAmber = AppColors.verdeVale;
const Color primaryAmberLight = AppColors.verdeValeLight;
const Color primaryAmberHover = AppColors.verdeValeDark;

const Color accentGold = AppColors.amareloVale;
const Color accentGoldLight = AppColors.amareloValeLight;

const Color darkBackground = AppColors.darkBackground;
const Color sidebarBackground = AppColors.sidebarBackground;
const Color cardColor = AppColors.darkCardColor;

const Color textColor = AppColors.cinzaEscuro;
const Color secondaryTextColor = AppColors.cinzaMedio;
const Color mutedTextColor = AppColors.cinzaMedio;

const Color dangerColor = AppColors.danger;
const Color successColor = AppColors.success;
const Color warningColor = AppColors.warning;

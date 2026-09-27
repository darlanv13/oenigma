import 'package:flutter/material.dart';

// Cores principais da aplicação
const Color darkBackground = Color(0xFFF0F4F8); // Neumorphic light background
// fallback for client compatibility:
// (if client code expects this specific variable it will error if absent but we replaced everything)
// Since we used web colors and didn't remove the unused ones, everything is unified.
const Color sidebarBackground = Color(0xFFE2E8F0); // Light sidebar
const Color cardColor = Colors.white; // Clean white card

const Color primaryAmber = Color(0xFF8B5CF6); // Pastel Purple
const Color primaryAmberLight = Color(0xFFC4B5FD);
const Color primaryAmberHover = Color(0xFF7C3AED);

const Color secondaryTextColor = Color(0xFF64748B); // Slate gray
const Color textColor = Color(0xFF1E293B); // Dark slate for readable text
const Color mutedTextColor = Color(0xFF94A3B8);

const Color dangerColor = Color(0xFFF44336);
const Color successColor = Color(0xFF4CAF50);
const Color warningColor = Color(0xFFFF9800);

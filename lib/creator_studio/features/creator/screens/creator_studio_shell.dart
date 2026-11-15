import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'creator_studio_web_shell.dart';
import 'creator_studio_mobile_shell.dart';

/// Ponto de entrada responsivo do Creator Studio.
/// Redireciona automaticamente entre a experiência Web/Desktop (>= 900px)
/// e a experiência Mobile/Tablet (< 900px).
class CreatorStudioShell extends ConsumerWidget {
  const CreatorStudioShell({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth >= 900) {
          return const CreatorStudioWebShell();
        } else {
          return const CreatorStudioMobileShell();
        }
      },
    );
  }
}

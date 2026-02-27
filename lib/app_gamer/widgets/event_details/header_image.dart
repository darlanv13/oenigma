import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:oenigma/utils/app_colors.dart';

class HeaderImage extends StatelessWidget {
  final String iconUrl;
  final Future<LottieComposition> composition;

  const HeaderImage({
    super.key,
    required this.iconUrl,
    required this.composition,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: Container(
        height: 320,
        decoration: const BoxDecoration(color: cardColor),
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (iconUrl.isNotEmpty)
              FutureBuilder<LottieComposition>(
                future: composition,
                builder: (context, snapshot) {
                  if (snapshot.hasData) {
                    return Lottie(
                      composition: snapshot.data!,
                      fit: BoxFit.scaleDown,
                    );
                  } else if (snapshot.hasError) {
                    return Lottie.asset('assets/animations/no_enigma.json');
                  }

                  return const Center(
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: primaryAmber,
                    ),
                  );
                },
              )
            else
              const Icon(Icons.help_outline, size: 150, color: primaryAmber),
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    darkBackground.withOpacity(0.8),
                    darkBackground.withOpacity(0.4),
                    Colors.transparent,
                  ],
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  stops: const [0.0, 0.5, 1.0],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

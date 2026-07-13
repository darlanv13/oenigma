import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class SvgNavIcon extends StatelessWidget {
  final String assetPath;
  final Color? color;
  final double size;

  const SvgNavIcon({
    super.key,
    required this.assetPath,
    this.color,
    this.size = 24.0,
  });

  @override
  Widget build(BuildContext context) {
    return SvgPicture.asset(
      assetPath,
      width: size,
      height: size,
      colorFilter: color != null ? ColorFilter.mode(color!, BlendMode.srcIn) : null,
    );
  }
}

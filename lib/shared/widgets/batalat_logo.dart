/// Batalat — Brand logo image
import 'package:flutter/material.dart';

class BatalatLogo extends StatelessWidget {
  const BatalatLogo({
    super.key,
    this.size = 96,
    this.fit = BoxFit.contain,
  });

  final double size;
  final BoxFit fit;

  static const assetPath = 'assets/images/logo.png';

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: Image.asset(
        assetPath,
        fit: fit,
        filterQuality: FilterQuality.high,
        gaplessPlayback: true,
      ),
    );
  }
}

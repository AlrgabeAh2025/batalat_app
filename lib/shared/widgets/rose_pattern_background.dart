/// Batalat — خط زخرفي مستوحى من ورود الشعار (برعم + جذع + أوراق)
import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'package:batalat_app/core/theme/app_colors.dart';

enum RoseDecorDensity {
  /// قليلة ومتناثرة
  soft,

  /// أكثر قليلاً دون ملء الخلفية
  rich,
}

/// زخارف ورود بجذوع بأسلوب خطّي كالشعار — متناثرة عشوائياً.
class RosePatternBackground extends StatelessWidget {
  const RosePatternBackground({
    super.key,
    this.density = RoseDecorDensity.soft,
  });

  final RoseDecorDensity density;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: CustomPaint(
        painter: _StemmedRosePainter(
          color: AppColors.primary,
          density: density,
        ),
        child: const SizedBox.expand(),
      ),
    );
  }
}

/// يغلف المحتوى بخلفية التطبيق + زخارف الورود.
class RoseDecorScaffold extends StatelessWidget {
  const RoseDecorScaffold({
    super.key,
    required this.body,
    this.appBar,
    this.floatingActionButton,
    this.bottomNavigationBar,
    this.bottomSheet,
    this.extendBodyBehindAppBar = false,
    this.density = RoseDecorDensity.soft,
    this.resizeToAvoidBottomInset,
  });

  final Widget body;
  final PreferredSizeWidget? appBar;
  final Widget? floatingActionButton;
  final Widget? bottomNavigationBar;
  final Widget? bottomSheet;
  final bool extendBodyBehindAppBar;
  final RoseDecorDensity density;
  final bool? resizeToAvoidBottomInset;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      extendBodyBehindAppBar: extendBodyBehindAppBar,
      resizeToAvoidBottomInset: resizeToAvoidBottomInset,
      appBar: appBar,
      floatingActionButton: floatingActionButton,
      bottomNavigationBar: bottomNavigationBar,
      bottomSheet: bottomSheet,
      body: Stack(
        fit: StackFit.expand,
        children: [
          RosePatternBackground(density: density),
          body,
        ],
      ),
    );
  }
}

class _StemmedRosePainter extends CustomPainter {
  _StemmedRosePainter({
    required this.color,
    required this.density,
  });

  final Color color;
  final RoseDecorDensity density;

  @override
  void paint(Canvas canvas, Size size) {
    final motifs =
        density == RoseDecorDensity.rich ? _richMotifs : _softMotifs;

    for (final m in motifs) {
      // موضع الزهرة = مركز البرعم؛ الجذع يمتد للأسفل
      final bloom = Offset(size.width * m.x, size.height * m.y);
      canvas.save();
      canvas.translate(bloom.dx, bloom.dy);
      canvas.rotate(m.tilt);
      canvas.scale(m.scale);
      _drawStemmedRose(canvas, opacity: m.opacity, mirror: m.mirror);
      canvas.restore();
    }
  }

  /// وردة خطّية كالشعار: طبقات بتلات حلزونية + جذع منحني + أوراق مدبّبة
  void _drawStemmedRose(
    Canvas canvas, {
    required double opacity,
    required bool mirror,
  }) {
    if (mirror) {
      canvas.scale(-1, 1);
    }

    final stroke = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.35
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..color = color.withValues(alpha: opacity);

    final softStroke = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.05
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..color = color.withValues(alpha: opacity * 0.9);

    // —— البرعم (رأس الوردة) بأسلوب الطبقات الحلزونية ——
    _drawLogoStyleBloom(canvas, stroke, softStroke);

    // —— الجذع المنحني ——
    final stem = Path()
      ..moveTo(0, 10)
      ..cubicTo(-2, 28, 6, 48, -1, 72)
      ..cubicTo(-4, 88, 3, 102, 0, 118);
    canvas.drawPath(stem, stroke);

    // —— أوراق مدبّبة على الجذع (كأوراق الشعار) ——
    _drawPointedLeaf(
      canvas,
      origin: const Offset(-2, 42),
      angle: -0.95,
      length: 22,
      width: 9,
      paint: softStroke,
    );
    _drawPointedLeaf(
      canvas,
      origin: const Offset(1, 58),
      angle: 1.05,
      length: 20,
      width: 8,
      paint: softStroke,
    );
    _drawPointedLeaf(
      canvas,
      origin: const Offset(-1, 78),
      angle: -1.15,
      length: 16,
      width: 7,
      paint: softStroke,
    );
  }

  void _drawLogoStyleBloom(Canvas canvas, Paint stroke, Paint softStroke) {
    // طبقات خارجية → داخلية: بتلات مقوّسة متداخلة كالشعار
    const layers = <({double r, int count, double phase})>[
      (r: 14.0, count: 7, phase: 0.12),
      (r: 10.5, count: 6, phase: 0.35),
      (r: 7.0, count: 5, phase: 0.58),
      (r: 4.0, count: 4, phase: 0.2),
    ];

    for (final layer in layers) {
      for (var i = 0; i < layer.count; i++) {
        final a = layer.phase + (math.pi * 2 / layer.count) * i;
        _drawPetalArc(
          canvas,
          radius: layer.r,
          angle: a,
          paint: layer.r > 9 ? stroke : softStroke,
        );
      }
    }

    // مركز حلزوني صغير
    final core = Path()
      ..moveTo(1.2, 0)
      ..cubicTo(1.2, -2.8, -2.2, -2.8, -2.2, 0)
      ..cubicTo(-2.2, 2.2, 0.6, 2.4, 0.8, 0.4);
    canvas.drawPath(core, softStroke);
  }

  void _drawPetalArc(
    Canvas canvas, {
    required double radius,
    required double angle,
    required Paint paint,
  }) {
    canvas.save();
    canvas.rotate(angle);

    // بتلة مقوّسة من المركز نحو الخارج (شكل وردة كلاسيكي)
    final path = Path()
      ..moveTo(radius * 0.15, 0)
      ..cubicTo(
        radius * 0.45,
        -radius * 0.42,
        radius * 0.85,
        -radius * 0.38,
        radius * 1.02,
        -radius * 0.08,
      )
      ..cubicTo(
        radius * 0.9,
        radius * 0.12,
        radius * 0.5,
        radius * 0.38,
        radius * 0.15,
        0,
      );
    canvas.drawPath(path, paint);
    canvas.restore();
  }

  void _drawPointedLeaf(
    Canvas canvas, {
    required Offset origin,
    required double angle,
    required double length,
    required double width,
    required Paint paint,
  }) {
    canvas.save();
    canvas.translate(origin.dx, origin.dy);
    canvas.rotate(angle);

    final leaf = Path()
      ..moveTo(0, 0)
      ..quadraticBezierTo(length * 0.35, -width, length, 0)
      ..quadraticBezierTo(length * 0.35, width, 0, 0);
    canvas.drawPath(leaf, paint);

    // عرق الورقة
    final vein = Path()
      ..moveTo(length * 0.08, 0)
      ..quadraticBezierTo(length * 0.5, -width * 0.15, length * 0.92, 0);
    canvas.drawPath(vein, paint);

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _StemmedRosePainter oldDelegate) {
    return oldDelegate.color != color || oldDelegate.density != density;
  }
}

class _Motif {
  const _Motif({
    required this.x,
    required this.y,
    required this.scale,
    required this.opacity,
    required this.tilt,
    this.mirror = false,
  });

  /// موضع البرعم نسبياً (الجذع يمتد للأسفل منه)
  final double x;
  final double y;
  final double scale;
  final double opacity;
  final double tilt;
  final bool mirror;
}

/// مواضع قليلة وعشوائية — زوايا وهوامش فقط، لا ملء للوسط
const _softMotifs = <_Motif>[
  _Motif(x: 0.07, y: 0.14, scale: 0.85, opacity: 0.11, tilt: -0.35),
  _Motif(x: 0.93, y: 0.22, scale: 0.72, opacity: 0.09, tilt: 0.28, mirror: true),
  _Motif(x: 0.88, y: 0.78, scale: 0.9, opacity: 0.1, tilt: 0.15),
  _Motif(x: 0.1, y: 0.82, scale: 0.7, opacity: 0.09, tilt: -0.45, mirror: true),
];

const _richMotifs = <_Motif>[
  ..._softMotifs,
  _Motif(x: 0.94, y: 0.48, scale: 0.62, opacity: 0.085, tilt: 0.5),
  _Motif(x: 0.06, y: 0.48, scale: 0.58, opacity: 0.08, tilt: -0.55, mirror: true),
];

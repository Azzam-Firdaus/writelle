import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

enum AmbientVariant {
  home,
  explore,
  editor,
  profile,
  auth,
  keepsakes,
  reader,
}

/// Atmospheric, layered organic paper background for Writtle.
/// Renders ambient color fields, organic flowing curves, and subtle paper warmth
/// with zero tap-blocking overhead.
class WrittleAmbientBackground extends StatelessWidget {
  final AmbientVariant variant;
  final Widget child;

  const WrittleAmbientBackground({
    super.key,
    this.variant = AmbientVariant.home,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Stack(
      children: [
        // 1. Base Canvas Painter with Ambient Color Fields & Organic Shapes
        Positioned.fill(
          child: IgnorePointer(
            child: RepaintBoundary(
              child: CustomPaint(
                painter: _WrittleAmbientPainter(
                  variant: variant,
                  isDark: isDark,
                ),
              ),
            ),
          ),
        ),

        // 2. Interactive Child Tree
        Positioned.fill(
          child: child,
        ),
      ],
    );
  }
}

class _WrittleAmbientPainter extends CustomPainter {
  final AmbientVariant variant;
  final bool isDark;

  const _WrittleAmbientPainter({
    required this.variant,
    required this.isDark,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width <= 0 || size.height <= 0) return;

    final rect = Offset.zero & size;

    // 1. BASE PAPER GRADIENT
    final baseGradient = isDark
        ? const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF1B1410),
              Color(0xFF221A14),
              Color(0xFF19120E),
            ],
          )
        : LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: _getBaseGradientColors(),
          );

    final basePaint = Paint()..shader = baseGradient.createShader(rect);
    canvas.drawRect(rect, basePaint);

    // If editor variant, keep it clean and minimal for maximum focus
    if (variant == AmbientVariant.editor) {
      _paintEditorAtmosphere(canvas, size);
      return;
    }

    // 2. AMBIENT RADIAL COLOR FIELDS
    _paintAmbientFields(canvas, size);

    // 3. ORGANIC SHAPES & FLOWING BEZIER CONTOURS
    _paintOrganicCurves(canvas, size);

    // 4. LITERARY / INK ACCENT MOTIFS
    _paintLiteraryMotifs(canvas, size);
  }

  List<Color> _getBaseGradientColors() {
    switch (variant) {
      case AmbientVariant.home:
        return const [
          AppColors.warmIvory,
          Color(0xFFF6F0E6),
          AppColors.softParchment,
        ];
      case AmbientVariant.explore:
        return const [
          Color(0xFFF9F6EE),
          AppColors.warmIvory,
          Color(0xFFF2EADC),
        ];
      case AmbientVariant.editor:
        return const [
          Color(0xFFFCFAF4),
          AppColors.warmIvory,
          Color(0xFFF8F4EC),
        ];
      case AmbientVariant.profile:
        return const [
          Color(0xFFF6EFE5),
          AppColors.warmIvory,
          Color(0xFFEFE6D7),
        ];
      case AmbientVariant.auth:
        return const [
          AppColors.warmIvory,
          Color(0xFFF3ECE0),
          Color(0xFFEADFCF),
        ];
      case AmbientVariant.keepsakes:
        return const [
          Color(0xFFF7F2E8),
          AppColors.warmIvory,
          Color(0xFFEFE6D8),
        ];
      case AmbientVariant.reader:
        return const [
          Color(0xFFFAF7F0),
          Color(0xFFF8F4EB),
        ];
    }
  }

  void _paintAmbientFields(Canvas canvas, Size size) {
    // Field A: Warm Sand Glow (Top-Right)
    final sandColor = isDark
        ? const Color(0xFFD49B6A).withValues(alpha: 0.04)
        : AppColors.warmSand.withValues(alpha: variant == AmbientVariant.auth ? 0.35 : 0.24);

    final sandPaint = Paint()
      ..shader = RadialGradient(
        center: const Alignment(0.85, -0.65),
        radius: 1.1,
        colors: [
          sandColor,
          sandColor.withValues(alpha: 0.0),
        ],
      ).createShader(Offset.zero & size);
    canvas.drawRect(Offset.zero & size, sandPaint);

    // Field B: Burnt Sienna / Terracotta Field (Bottom-Left)
    final siennaColor = isDark
        ? const Color(0xFF99572D).withValues(alpha: 0.05)
        : AppColors.burntSienna.withValues(alpha: variant == AmbientVariant.auth ? 0.08 : 0.05);

    final siennaPaint = Paint()
      ..shader = RadialGradient(
        center: const Alignment(-0.8, 0.65),
        radius: 1.2,
        colors: [
          siennaColor,
          siennaColor.withValues(alpha: 0.0),
        ],
      ).createShader(Offset.zero & size);
    canvas.drawRect(Offset.zero & size, siennaPaint);

    // Field C: Deep Olive Accent Field (Mid-Left or Top-Left)
    final oliveColor = isDark
        ? const Color(0xFF72745B).withValues(alpha: 0.035)
        : AppColors.deepOlive.withValues(alpha: 0.04);

    final olivePaint = Paint()
      ..shader = RadialGradient(
        center: const Alignment(-0.9, -0.2),
        radius: 0.9,
        colors: [
          oliveColor,
          oliveColor.withValues(alpha: 0.0),
        ],
      ).createShader(Offset.zero & size);
    canvas.drawRect(Offset.zero & size, olivePaint);
  }

  void _paintOrganicCurves(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // Top flowing curve
    final topCurveColor = isDark
        ? Colors.white.withValues(alpha: 0.015)
        : AppColors.warmSand.withValues(alpha: 0.12);

    final topPaint = Paint()
      ..color = topCurveColor
      ..style = PaintingStyle.fill;

    final topPath = Path();
    topPath.moveTo(0, 0);
    topPath.lineTo(w, 0);
    topPath.lineTo(w, h * 0.18);
    topPath.quadraticBezierTo(w * 0.65, h * 0.22, w * 0.35, h * 0.14);
    topPath.quadraticBezierTo(w * 0.15, h * 0.09, 0, h * 0.15);
    topPath.close();
    canvas.drawPath(topPath, topPaint);

    // Cropped circular form near bottom-right
    if (variant == AmbientVariant.home || variant == AmbientVariant.auth) {
      final circleColor = isDark
          ? const Color(0xFFD49B6A).withValues(alpha: 0.02)
          : AppColors.burntSienna.withValues(alpha: 0.03);

      final circlePaint = Paint()
        ..color = circleColor
        ..style = PaintingStyle.fill;

      canvas.drawCircle(Offset(w * 0.92, h * 0.78), w * 0.38, circlePaint);
    }

    // Secondary flowing wave in lower third
    if (variant == AmbientVariant.explore || variant == AmbientVariant.profile) {
      final waveColor = isDark
          ? Colors.white.withValues(alpha: 0.01)
          : AppColors.softParchment.withValues(alpha: 0.45);

      final wavePaint = Paint()
        ..color = waveColor
        ..style = PaintingStyle.fill;

      final wavePath = Path();
      wavePath.moveTo(0, h * 0.72);
      wavePath.cubicTo(w * 0.25, h * 0.68, w * 0.75, h * 0.76, w, h * 0.70);
      wavePath.lineTo(w, h);
      wavePath.lineTo(0, h);
      wavePath.close();
      canvas.drawPath(wavePath, wavePaint);
    }
  }

  void _paintLiteraryMotifs(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // Elegant contour contour lines
    final contourColor = isDark
        ? const Color(0xFFE5D4BE).withValues(alpha: 0.03)
        : AppColors.mutedCocoa.withValues(alpha: 0.045);

    final linePaint = Paint()
      ..color = contourColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    // Subtle curved contour line 1
    final linePath1 = Path();
    linePath1.moveTo(0, h * 0.32);
    linePath1.cubicTo(w * 0.35, h * 0.28, w * 0.65, h * 0.36, w, h * 0.30);
    canvas.drawPath(linePath1, linePaint);

    // Subtle curved contour line 2 (offset)
    final linePath2 = Path();
    linePath2.moveTo(0, h * 0.34);
    linePath2.cubicTo(w * 0.38, h * 0.30, w * 0.68, h * 0.38, w, h * 0.32);
    canvas.drawPath(linePath2, linePaint);

    // Subtle botanical leaf / quill motif contour near edge for Auth or Home
    if (variant == AmbientVariant.auth || variant == AmbientVariant.home) {
      final quillPaint = Paint()
        ..color = isDark
            ? const Color(0xFFD49B6A).withValues(alpha: 0.04)
            : AppColors.burntSienna.withValues(alpha: 0.04)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2;

      final quillPath = Path();
      final originX = w * 0.88;
      final originY = h * 0.12;
      quillPath.moveTo(originX, originY);
      quillPath.quadraticBezierTo(originX + 25, originY + 50, originX + 10, originY + 90);
      quillPath.quadraticBezierTo(originX - 15, originY + 45, originX, originY);
      canvas.drawPath(quillPath, quillPaint);
    }
  }

  void _paintEditorAtmosphere(Canvas canvas, Size size) {
    final h = size.height;

    // Soft warm margin guideline on the left (literary notebook feel)
    final marginColor = isDark
        ? const Color(0xFF332720).withValues(alpha: 0.4)
        : const Color(0xFFE8DFC8).withValues(alpha: 0.3);

    final linePaint = Paint()
      ..color = marginColor
      ..strokeWidth = 1.0;

    canvas.drawLine(const Offset(22, 0), Offset(22, h), linePaint);

    // Gentle top ambient glow (fixed top bounds prevents shader distortion during keyboard animations)
    final glowColor = isDark
        ? const Color(0xFF99572D).withValues(alpha: 0.02)
        : AppColors.warmSand.withValues(alpha: 0.15);

    const glowHeight = 220.0;
    final glowRect = Rect.fromLTWH(0, 0, size.width, glowHeight);
    final glowPaint = Paint()
      ..shader = RadialGradient(
        center: const Alignment(0.7, -0.8),
        radius: 0.8,
        colors: [glowColor, glowColor.withValues(alpha: 0)],
      ).createShader(glowRect);
    canvas.drawRect(glowRect, glowPaint);
  }

  @override
  bool shouldRepaint(covariant _WrittleAmbientPainter oldDelegate) {
    return oldDelegate.variant != variant || oldDelegate.isDark != isDark;
  }
}

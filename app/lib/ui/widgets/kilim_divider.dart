import 'package:flutter/material.dart';

import '../theme/bir_omur_theme.dart';

/// Ölçülü nostaljik detay: ince, özgün bir kilim şeridi.
///
/// Süsleme okunurluğu bozmayacak ölçüde kalır (`docs/PROTOTYPE_UI.md` §2).
class KilimDivider extends StatelessWidget {
  const KilimDivider({super.key, this.height = 10, this.onDark = false});

  final double height;

  /// Koyu bir zeminin üzerinde mi duruyor? Üst karakter başlığı gibi
  /// degrade zeminlerde tema renkleri okunmuyor; açık tonlar kullanılır.
  final bool onDark;

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    return SizedBox(
      height: height,
      width: double.infinity,
      child: CustomPaint(
        painter: _KilimPainter(
          color: onDark
              ? Colors.white.withValues(alpha: 0.28)
              : scheme.primary.withValues(alpha: 0.35),
          accent: onDark
              ? BirOmurColors.pirincAcik.withValues(alpha: 0.85)
              : scheme.tertiary.withValues(alpha: 0.75),
        ),
      ),
    );
  }
}

class _KilimPainter extends CustomPainter {
  _KilimPainter({required this.color, required this.accent});

  final Color color;
  final Color accent;

  @override
  void paint(Canvas canvas, Size size) {
    final Paint stroke = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4;
    final Paint dot = Paint()..color = accent;

    const double step = 14;
    final Path path = Path()..moveTo(0, size.height);
    bool up = true;
    for (double x = 0; x <= size.width + step; x += step / 2) {
      path.lineTo(x, up ? 1 : size.height - 1);
      up = !up;
    }
    canvas.drawPath(path, stroke);

    for (double x = step / 2; x < size.width; x += step * 2) {
      canvas.drawCircle(Offset(x, size.height / 2), 1.6, dot);
    }
  }

  @override
  bool shouldRepaint(_KilimPainter oldDelegate) =>
      oldDelegate.color != color || oldDelegate.accent != accent;
}

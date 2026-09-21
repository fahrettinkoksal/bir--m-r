import 'package:flutter/material.dart';

import '../theme/bir_omur_theme.dart';

/// Elle çizilmiş gibi duran ayırıcı.
///
/// Düz bir çizgi yerine hafifçe dalgalanan, kalın bir mürekkep şeridi:
/// cetvelle çizilmemiş hissi verir (Paket 19).
class KilimDivider extends StatelessWidget {
  const KilimDivider({super.key, this.height = 10, this.onDark = false});

  final double height;

  /// Koyu bir zeminin üzerinde mi duruyor?
  final bool onDark;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      width: double.infinity,
      child: CustomPaint(
        painter: _InkLinePainter(
          color: onDark
              ? BirOmurColors.krem.withValues(alpha: 0.85)
              : Comic.konturOf(context),
        ),
      ),
    );
  }
}

class _InkLinePainter extends CustomPainter {
  _InkLinePainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final Paint kalem = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.6
      ..strokeCap = StrokeCap.round;

    // Elle çekilmiş bir çizgi tam düz olmaz; kontrol noktaları hafifçe
    // yukarı-aşağı kayar.
    final double y = size.height / 2;
    final Path yol = Path()..moveTo(2, y);
    const double adim = 46;
    bool yukari = true;
    for (double x = adim; x < size.width; x += adim) {
      yol.quadraticBezierTo(
        x - adim / 2,
        yukari ? y - 2.2 : y + 2.2,
        x,
        y,
      );
      yukari = !yukari;
    }
    yol.lineTo(size.width - 2, y);
    canvas.drawPath(yol, kalem);
  }

  @override
  bool shouldRepaint(_InkLinePainter oldDelegate) =>
      oldDelegate.color != color;
}

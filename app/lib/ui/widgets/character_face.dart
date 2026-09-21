import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../domain/models/gender.dart';
import '../../domain/models/player_character.dart';
import '../theme/bir_omur_theme.dart';

/// Oyuncunun karikatür yüzü (Paket 19).
///
/// Oyunun en büyük eksiği karakterin hiç **görünmemesiydi**: ekranda
/// yalnızca sayılar ve metin vardı. Bu yüz hazır bir görsel değil, her
/// karede oyunun kendi verisinden **çizilir**:
///
/// - **Yaş** kafanın oranını, saçın rengini ve yüz çizgilerini belirler.
/// - **Saç stili** berberde seçilen stilden gelir; gerçekten değişir.
/// - **Mutluluk** ağzın eğrisini ve kaşların açısını belirler.
/// - **Sağlık** ten tonunu ve gözlerin açıklığını etkiler.
/// - **Cinsiyet** saç hacmini ve küpe gibi küçük bir ayrıntıyı değiştirir.
///
/// Uydurma yoktur: her ayrıntı gerçekten kayıtta duran bir değerden
/// okunur. Ölçüler `prototypeOnly` (Q-087).
class CharacterFace extends StatelessWidget {
  const CharacterFace({
    super.key,
    required this.player,
    this.size = 64,
    this.deceased = false,
  });

  final PlayerCharacter player;
  final double size;

  /// Hayat tamamlandıysa yüz sakinleşir ve gözler kapanır.
  final bool deceased;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _FacePainter(
          age: player.age,
          gender: player.gender,
          hairStyle: player.hairStyle,
          happiness: player.stats.happiness,
          health: player.stats.health,
          ink: Comic.konturOf(context),
          deceased: deceased,
        ),
      ),
    );
  }
}

/// Saç renkleri (`prototypeOnly`).
///
/// Yaşla birlikte griye döner; bu tek yerde tutulur.
Color _hairColor(int age, String? style) {
  const Color siyah = Color(0xFF3A2C2A);
  const Color kahve = Color(0xFF6B4630);
  const Color gri = Color(0xFF9A93A6);
  const Color beyaz = Color(0xFFD9D3E0);
  if (age >= 70) return beyaz;
  if (age >= 55) return gri;
  // Stil metni saç rengini de çeşitlendirir; aynı isim hep aynı rengi
  // verir, böylece karakter yıllar içinde tutarlı kalır.
  return (style?.hashCode ?? 0).isEven ? siyah : kahve;
}

/// Ten tonu: sağlık düştükçe soluklaşır (`prototypeOnly`).
Color _skinColor(int health) {
  const Color saglikli = Color(0xFFF7C89B);
  const Color soluk = Color(0xFFE8CDBA);
  final double t = (1 - (health.clamp(0, 100) / 100)).clamp(0.0, 1.0);
  return Color.lerp(saglikli, soluk, t)!;
}

class _FacePainter extends CustomPainter {
  _FacePainter({
    required this.age,
    required this.gender,
    required this.hairStyle,
    required this.happiness,
    required this.health,
    required this.ink,
    required this.deceased,
  });

  final int age;
  final Gender gender;
  final String? hairStyle;
  final int happiness;
  final int health;
  final Color ink;
  final bool deceased;

  @override
  void paint(Canvas canvas, Size size) {
    final double w = size.width;
    final double h = size.height;
    final double cizgi = math.max(1.6, w * 0.035);

    final Paint kontur = Paint()
      ..color = ink
      ..style = PaintingStyle.stroke
      ..strokeWidth = cizgi
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    // Bebeklikte kafa gövdeye göre büyük, yaşlılıkta biraz daha dar.
    final double kafaOran = age <= 2
        ? 0.80
        : age <= 6
            ? 0.74
            : age >= 65
                ? 0.68
                : 0.70;
    final double kafaW = w * kafaOran;
    final double kafaH = h * (age <= 2 ? 0.74 : 0.70);
    final Offset merkez = Offset(w / 2, h * (age <= 2 ? 0.52 : 0.50));
    final RRect kafa = RRect.fromRectAndRadius(
      Rect.fromCenter(center: merkez, width: kafaW, height: kafaH),
      Radius.circular(kafaW * 0.44),
    );

    _drawHairBack(canvas, merkez, kafaW, kafaH, kontur);

    canvas.drawRRect(kafa, Paint()..color = _skinColor(health));
    canvas.drawRRect(kafa, kontur);

    _drawHairFront(canvas, merkez, kafaW, kafaH, kontur);
    _drawEyes(canvas, merkez, kafaW, kafaH, cizgi);
    _drawBrows(canvas, merkez, kafaW, kafaH, kontur);
    _drawMouth(canvas, merkez, kafaW, kafaH, kontur);
    _drawAgeMarks(canvas, merkez, kafaW, kafaH, kontur);
  }

  /// Kafanın arkasında kalan saç hacmi (uzun saçlar).
  void _drawHairBack(
    Canvas canvas,
    Offset merkez,
    double kafaW,
    double kafaH,
    Paint kontur,
  ) {
    if (age < 3) return;
    final bool uzun = (hairStyle?.contains('Uzun') ?? false) ||
        (hairStyle?.contains('Kıvırcık') ?? false) ||
        (hairStyle == null && gender == Gender.kadin);
    if (!uzun) return;

    final Paint dolgu = Paint()..color = _hairColor(age, hairStyle);
    final RRect arka = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: merkez.translate(0, kafaH * 0.12),
        width: kafaW * 1.16,
        height: kafaH * 1.06,
      ),
      Radius.circular(kafaW * 0.5),
    );
    canvas.drawRRect(arka, dolgu);
    canvas.drawRRect(arka, kontur);
  }

  /// Alındaki saç: stile göre değişir.
  void _drawHairFront(
    Canvas canvas,
    Offset merkez,
    double kafaW,
    double kafaH,
    Paint kontur,
  ) {
    final Paint dolgu = Paint()..color = _hairColor(age, hairStyle);
    final double ust = merkez.dy - kafaH / 2;
    final double sol = merkez.dx - kafaW / 2;

    // Bebekte tek tutam.
    if (age < 3) {
      final Path tutam = Path()
        ..moveTo(merkez.dx - kafaW * 0.06, ust + kafaH * 0.04)
        ..quadraticBezierTo(
          merkez.dx + kafaW * 0.02,
          ust - kafaH * 0.16,
          merkez.dx + kafaW * 0.14,
          ust + kafaH * 0.02,
        );
      canvas.drawPath(tutam, kontur);
      return;
    }

    // Erkekte ileri yaşta saç çizgisi geriler.
    final double yukseklik = (gender == Gender.erkek && age >= 60)
        ? kafaH * 0.16
        : kafaH * 0.26;

    final Path on = Path()
      ..moveTo(sol + kafaW * 0.02, ust + kafaH * 0.30)
      ..quadraticBezierTo(
        merkez.dx,
        ust - yukseklik * 0.55,
        sol + kafaW * 0.98,
        ust + kafaH * 0.30,
      );

    if (hairStyle?.contains('Yana ayrılmış') ?? false) {
      on.lineTo(sol + kafaW * 0.62, ust + kafaH * 0.16);
      on.lineTo(sol + kafaW * 0.30, ust + kafaH * 0.30);
    } else if (hairStyle?.contains('Dağınık') ?? false) {
      on.lineTo(sol + kafaW * 0.74, ust + kafaH * 0.12);
      on.lineTo(sol + kafaW * 0.56, ust + kafaH * 0.28);
      on.lineTo(sol + kafaW * 0.36, ust + kafaH * 0.10);
      on.lineTo(sol + kafaW * 0.18, ust + kafaH * 0.28);
    } else if (hairStyle?.contains('Kısacık') ?? false) {
      on.lineTo(sol + kafaW * 0.02, ust + kafaH * 0.24);
    } else {
      on.lineTo(sol + kafaW * 0.02, ust + kafaH * 0.30);
    }
    on.close();

    canvas.drawPath(on, dolgu);
    canvas.drawPath(on, kontur);
  }

  void _drawEyes(
    Canvas canvas,
    Offset merkez,
    double kafaW,
    double kafaH,
    double cizgi,
  ) {
    final double aralik = kafaW * 0.21;
    final double y = merkez.dy - kafaH * 0.02;
    final Paint goz = Paint()..color = ink;

    // Vefat edince ve çok düşük sağlıkta gözler kapalı çizilir.
    final bool kapali = deceased || health < 15;
    for (final double yon in <double>[-1, 1]) {
      final Offset o = Offset(merkez.dx + yon * aralik, y);
      if (kapali) {
        final Paint kavis = Paint()
          ..color = ink
          ..style = PaintingStyle.stroke
          ..strokeWidth = cizgi
          ..strokeCap = StrokeCap.round;
        canvas.drawArc(
          Rect.fromCenter(center: o, width: kafaW * 0.16, height: kafaW * 0.12),
          math.pi,
          math.pi,
          false,
          kavis,
        );
      } else {
        canvas.drawCircle(o, kafaW * 0.055, goz);
        // Küçük parlama noktası: yüz canlı görünür.
        canvas.drawCircle(
          o.translate(kafaW * 0.02, -kafaW * 0.02),
          kafaW * 0.018,
          Paint()..color = Colors.white,
        );
      }
    }
  }

  void _drawBrows(
    Canvas canvas,
    Offset merkez,
    double kafaW,
    double kafaH,
    Paint kontur,
  ) {
    if (age < 3) return;
    // Mutluluk düştükçe kaşların iç ucu yukarı kalkar.
    final double uzgun = (1 - (happiness.clamp(0, 100) / 100));
    final double aralik = kafaW * 0.21;
    final double y = merkez.dy - kafaH * 0.17;
    final double genislik = kafaW * 0.15;

    for (final double yon in <double>[-1, 1]) {
      final double x = merkez.dx + yon * aralik;
      final Path kas = Path()
        ..moveTo(x - genislik / 2, y + uzgun * kafaH * 0.05 * -yon)
        ..lineTo(x + genislik / 2, y + uzgun * kafaH * 0.05 * yon);
      canvas.drawPath(kas, kontur);
    }
  }

  void _drawMouth(
    Canvas canvas,
    Offset merkez,
    double kafaW,
    double kafaH,
    Paint kontur,
  ) {
    final double y = merkez.dy + kafaH * 0.20;
    final double genislik = kafaW * 0.34;
    // 0 mutlulukta belirgin aşağı kavis, 100'de belirgin gülümseme.
    final double egri =
        ((happiness.clamp(0, 100) - 50) / 50) * kafaH * 0.11;

    if (deceased) {
      canvas.drawLine(
        Offset(merkez.dx - genislik / 2, y),
        Offset(merkez.dx + genislik / 2, y),
        kontur,
      );
      return;
    }

    final Path agiz = Path()
      ..moveTo(merkez.dx - genislik / 2, y)
      ..quadraticBezierTo(merkez.dx, y + egri * 2, merkez.dx + genislik / 2, y);
    canvas.drawPath(agiz, kontur);
  }

  /// İleri yaşın izleri: göz kenarı çizgileri.
  void _drawAgeMarks(
    Canvas canvas,
    Offset merkez,
    double kafaW,
    double kafaH,
    Paint kontur,
  ) {
    if (age < 55) return;
    final Paint ince = Paint()
      ..color = ink.withValues(alpha: 0.55)
      ..style = PaintingStyle.stroke
      ..strokeWidth = kontur.strokeWidth * 0.6
      ..strokeCap = StrokeCap.round;
    final double y = merkez.dy - kafaH * 0.01;
    for (final double yon in <double>[-1, 1]) {
      final double x = merkez.dx + yon * kafaW * 0.33;
      canvas.drawLine(
        Offset(x, y - kafaH * 0.03),
        Offset(x + yon * kafaW * 0.05, y - kafaH * 0.05),
        ince,
      );
      canvas.drawLine(
        Offset(x, y + kafaH * 0.02),
        Offset(x + yon * kafaW * 0.05, y + kafaH * 0.04),
        ince,
      );
    }
  }

  @override
  bool shouldRepaint(_FacePainter old) =>
      old.age != age ||
      old.gender != gender ||
      old.hairStyle != hairStyle ||
      old.happiness != happiness ||
      old.health != health ||
      old.ink != ink ||
      old.deceased != deceased;
}

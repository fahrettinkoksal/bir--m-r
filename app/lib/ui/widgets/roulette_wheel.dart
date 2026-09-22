import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../domain/casino/roulette.dart';
import '../theme/bir_omur_theme.dart';

/// Dönen rulet çarkı (Paket 30).
///
/// **Animasyon sonucu belirlemez.** Sayı alanda (`Roulette.spin`) zaten
/// çekilmiştir; çark yalnızca o sayının üzerinde durur. Bu yüzden
/// [landOn] verilir ve çark her zaman oraya iner.
class RouletteWheel extends StatefulWidget {
  const RouletteWheel({
    super.key,
    required this.landOn,
    required this.spinId,
    required this.onFinished,
    this.size = 220,
  });

  /// Çarkın duracağı sayı (0-36). `null` ise çark hareketsiz durur.
  final int? landOn;

  /// Her yeni çevirmede değişen kimlik; aynı sayı arka arkaya gelse de
  /// animasyon yeniden başlasın diye.
  final int spinId;

  /// Animasyon bitince çağrılır: sonuç metni ancak o zaman gösterilir.
  final VoidCallback onFinished;

  final double size;

  @override
  State<RouletteWheel> createState() => _RouletteWheelState();
}

class _RouletteWheelState extends State<RouletteWheel>
    with SingleTickerProviderStateMixin {
  late final AnimationController _kontrol = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2600),
  );

  /// Çarkın başladığı ve bittiği açı.
  double _baslangic = 0;
  double _bitis = 0;

  @override
  void initState() {
    super.initState();
    _kontrol.addStatusListener((AnimationStatus durum) {
      if (durum == AnimationStatus.completed) widget.onFinished();
    });
    if (widget.landOn != null) _basla();
  }

  @override
  void didUpdateWidget(RouletteWheel eski) {
    super.didUpdateWidget(eski);
    if (widget.spinId != eski.spinId && widget.landOn != null) _basla();
  }

  void _basla() {
    final int sayi = widget.landOn!;
    final int dilim = kRouletteOrder.indexOf(sayi);
    // Hedef açı: seçilen dilim yukarıdaki işaretin altına gelsin.
    final double dilimAcisi = 2 * math.pi / Roulette.pockets;
    final double hedef = -dilim * dilimAcisi;
    _baslangic = _bitis % (2 * math.pi);
    // Birkaç tam tur atıp hedefte dursun.
    _bitis = _baslangic + 2 * math.pi * 5 + (hedef - _baslangic);
    _kontrol
      ..reset()
      ..forward();
  }

  @override
  void dispose() {
    _kontrol.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _kontrol,
      builder: (BuildContext context, Widget? child) {
        final double t = Curves.easeOutQuart.transform(_kontrol.value);
        final double aci = _baslangic + (_bitis - _baslangic) * t;
        return SizedBox(
          width: widget.size,
          height: widget.size,
          child: CustomPaint(
            painter: _WheelPainter(
              angle: aci,
              kontur: Comic.konturOf(context),
              // Top, çark yavaşladıkça içeri düşer.
              ballInset: 0.10 + 0.10 * t,
              // Topun kendi turu: çarkın tersine döner.
              ballAngle: -aci * 2.4,
              highlight: _kontrol.isCompleted ? widget.landOn : null,
            ),
          ),
        );
      },
    );
  }
}

/// Avrupa ruletinde sayıların çark üzerindeki **gerçek** sırası.
///
/// Sayılar çarkta artan sırada dizilmez; kırmızı ile siyah dönüşümlü
/// gider. Doğru sıra kullanılır ki çark gerçek bir ruleti andırsın.
const List<int> kRouletteOrder = <int>[
  0, 32, 15, 19, 4, 21, 2, 25, 17, 34, 6, 27, 13, 36, 11, 30, 8, 23, 10,
  5, 24, 16, 33, 1, 20, 14, 31, 9, 22, 18, 29, 7, 28, 12, 35, 3, 26,
];

class _WheelPainter extends CustomPainter {
  const _WheelPainter({
    required this.angle,
    required this.kontur,
    required this.ballInset,
    required this.ballAngle,
    required this.highlight,
  });

  final double angle;
  final Color kontur;
  final double ballInset;
  final double ballAngle;

  /// Animasyon bitince kazanan dilimi belirginleştirir.
  final int? highlight;

  @override
  void paint(Canvas canvas, Size size) {
    final Offset merkez = Offset(size.width / 2, size.height / 2);
    final double yaricap = size.width / 2;
    final double dilimAcisi = 2 * math.pi / Roulette.pockets;

    // Dış çerçeve.
    canvas.drawCircle(
      merkez,
      yaricap - 1,
      Paint()
        ..color = BirOmurColors.kagitKoyu
        ..style = PaintingStyle.fill,
    );
    canvas.drawCircle(
      merkez,
      yaricap - 1,
      Paint()
        ..color = kontur
        ..style = PaintingStyle.stroke
        ..strokeWidth = Comic.kontur,
    );

    final double icYaricap = yaricap - 14;
    for (int i = 0; i < kRouletteOrder.length; i++) {
      final int sayi = kRouletteOrder[i];
      final double bas = angle + i * dilimAcisi - math.pi / 2 - dilimAcisi / 2;
      final Color renk = sayi == 0
          ? BirOmurColors.yesil
          : (kRouletteRedNumbers.contains(sayi)
              ? BirOmurColors.kirmizi
              : BirOmurColors.murekkep);
      canvas.drawArc(
        Rect.fromCircle(center: merkez, radius: icYaricap),
        bas,
        dilimAcisi,
        true,
        Paint()..color = renk,
      );
      if (highlight != null && sayi == highlight) {
        canvas.drawArc(
          Rect.fromCircle(center: merkez, radius: icYaricap),
          bas,
          dilimAcisi,
          true,
          Paint()
            ..color = BirOmurColors.sari
            ..style = PaintingStyle.stroke
            ..strokeWidth = 4,
        );
      }
    }

    // Göbek.
    canvas.drawCircle(
      merkez,
      yaricap * 0.34,
      Paint()..color = BirOmurColors.kagitKoyu,
    );
    canvas.drawCircle(
      merkez,
      yaricap * 0.34,
      Paint()
        ..color = kontur
        ..style = PaintingStyle.stroke
        ..strokeWidth = Comic.inceKontur,
    );

    // Top.
    final double topYaricap = yaricap * (1 - ballInset) - 6;
    final Offset top = merkez +
        Offset(
          math.cos(ballAngle - math.pi / 2) * topYaricap,
          math.sin(ballAngle - math.pi / 2) * topYaricap,
        );
    canvas.drawCircle(top, 6, Paint()..color = BirOmurColors.kart);
    canvas.drawCircle(
      top,
      6,
      Paint()
        ..color = kontur
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.6,
    );

    // Üstteki işaret: çarkın durduğu yeri gösterir.
    final Path ibre = Path()
      ..moveTo(merkez.dx, merkez.dy - yaricap + 2)
      ..lineTo(merkez.dx - 8, merkez.dy - yaricap + 16)
      ..lineTo(merkez.dx + 8, merkez.dy - yaricap + 16)
      ..close();
    canvas.drawPath(ibre, Paint()..color = BirOmurColors.sari);
    canvas.drawPath(
      ibre,
      Paint()
        ..color = kontur
        ..style = PaintingStyle.stroke
        ..strokeWidth = Comic.inceKontur,
    );
  }

  @override
  bool shouldRepaint(_WheelPainter eski) =>
      eski.angle != angle ||
      eski.ballInset != ballInset ||
      eski.highlight != highlight;
}

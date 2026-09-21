import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../sound/sound_scope.dart';
import '../sound/sound_service.dart';
import '../theme/bir_omur_theme.dart';

/// Çizgi roman arayüzünün temel parçaları (Paket 19).
///
/// Bütün ekranlar bu dört parçadan kurulur: [ComicCard] (çizilmiş kart),
/// [StickerButton] (basınca çöken düğme), [ComicTag] (çıkartma rozet) ve
/// [ComicIconTile] (renkli ikon kutusu). Amaç, her ekranın aynı elden
/// çıkmış gibi durması.

/// Kaydırılmış, **bulanık olmayan** gölge.
///
/// Çizgi roman hissinin yarısı buradan gelir: yumuşak gölge her yerde
/// görülen genel bir arayüz işaretidir, keskin gölge ise kâğıda
/// yapıştırılmış bir çıkartmayı andırır.
List<BoxShadow> comicShadow(
  BuildContext context, {
  double offset = Comic.golge,
}) =>
    <BoxShadow>[
      BoxShadow(
        color: Comic.konturOf(context),
        offset: Offset(0, offset),
        blurRadius: 0,
      ),
    ];

/// Çizilmiş kart: düz dolgu, kalın kontur, keskin gölge.
class ComicCard extends StatelessWidget {
  const ComicCard({
    super.key,
    required this.child,
    this.color,
    this.padding = const EdgeInsets.all(16),
    this.radius = Comic.yaricapBuyuk,
    this.shadow = true,
    this.shadowOffset = Comic.golge,
    this.borderWidth = Comic.kontur,
    this.tilt = 0,
  });

  final Widget child;

  /// Dolgu rengi; verilmezse kart rengi kullanılır.
  final Color? color;
  final EdgeInsetsGeometry padding;
  final double radius;
  final bool shadow;
  final double shadowOffset;
  final double borderWidth;

  /// Hafif eğim (derece). Izgarayı kırmak için birkaç yerde kullanılır;
  /// okunurluğu bozacak kadar büyük verilmez.
  final double tilt;

  @override
  Widget build(BuildContext context) {
    final Widget kart = Container(
      padding: padding,
      decoration: BoxDecoration(
        color: color ?? Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: Comic.konturOf(context), width: borderWidth),
        boxShadow: shadow ? comicShadow(context, offset: shadowOffset) : null,
      ),
      child: child,
    );
    if (tilt == 0) return kart;
    return Transform.rotate(angle: tilt * math.pi / 180, child: kart);
  }
}

/// Basınca gerçekten çöken düğme.
///
/// Gölge kadar aşağı iner ve gölgesini kaybeder; parmağın altında bir
/// şeyin ezildiği hissi verir. Kapalıyken soluklaşır ve hiç hareket
/// etmez.
class StickerButton extends StatefulWidget {
  const StickerButton({
    super.key,
    required this.child,
    required this.onPressed,
    this.color,
    this.padding = const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
    this.radius = Comic.yaricap,
    this.expand = false,
    this.sound = GameSound.tap,
    this.shadowOffset = Comic.golge,
  });

  final Widget child;
  final VoidCallback? onPressed;
  final Color? color;
  final EdgeInsetsGeometry padding;
  final double radius;

  /// Genişliği doldursun mu?
  final bool expand;

  /// Dokunma sesi; `null` verilirse ses çalınmaz.
  final GameSound? sound;
  final double shadowOffset;

  @override
  State<StickerButton> createState() => _StickerButtonState();
}

class _StickerButtonState extends State<StickerButton> {
  bool _basili = false;

  bool get _acik => widget.onPressed != null;

  void _bas(bool deger) {
    if (!_acik) return;
    setState(() => _basili = deger);
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final Color kontur = Comic.konturOf(context);
    final Color dolgu =
        widget.color ?? theme.colorScheme.surfaceContainerHighest;

    final Widget govde = AnimatedContainer(
      duration: const Duration(milliseconds: 70),
      curve: Curves.easeOut,
      transform: Matrix4.translationValues(
        0,
        _basili ? widget.shadowOffset : 0,
        0,
      ),
      padding: widget.padding,
      decoration: BoxDecoration(
        color: _acik ? dolgu : Color.alphaBlend(
          theme.colorScheme.surface.withValues(alpha: 0.55),
          dolgu,
        ),
        borderRadius: BorderRadius.circular(widget.radius),
        border: Border.all(
          color: _acik ? kontur : kontur.withValues(alpha: 0.35),
          width: Comic.kontur,
        ),
        boxShadow: _basili || !_acik
            ? null
            : comicShadow(context, offset: widget.shadowOffset),
      ),
      child: DefaultTextStyle.merge(
        textAlign: TextAlign.center,
        style: TextStyle(
          color: _acik ? null : theme.colorScheme.onSurfaceVariant,
        ),
        child: widget.child,
      ),
    );

    return Semantics(
      button: true,
      enabled: _acik,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: (_) => _bas(true),
        onTapCancel: () => _bas(false),
        onTapUp: (_) => _bas(false),
        onTap: _acik
            ? () {
                if (widget.sound != null) {
                  SoundScope.play(context, widget.sound!);
                }
                widget.onPressed!();
              }
            : null,
        child: SizedBox(
          width: widget.expand ? double.infinity : null,
          // Gölge kadar yer ayrılır ki düğme çökerken düzen zıplamasın.
          child: Padding(
            padding: EdgeInsets.only(bottom: widget.shadowOffset),
            child: govde,
          ),
        ),
      ),
    );
  }
}

/// Çıkartma rozet: küçük, konturlu, istenirse eğik.
class ComicTag extends StatelessWidget {
  const ComicTag({
    super.key,
    required this.text,
    this.color,
    this.textColor,
    this.tilt = 0,
    this.handwritten = false,
    this.fontSize = 12.5,
  });

  final String text;
  final Color? color;
  final Color? textColor;
  final double tilt;

  /// El yazısıyla mı yazılsın? Yaş etiketleri ve günlük başlıkları için.
  final bool handwritten;
  final double fontSize;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final Color dolgu = color ?? theme.colorScheme.surfaceContainer;
    final Widget rozet = Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
      decoration: BoxDecoration(
        color: dolgu,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: Comic.konturOf(context),
          width: Comic.inceKontur,
        ),
        boxShadow: comicShadow(context, offset: 2),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontFamily:
              handwritten ? BirOmurTheme.elYazisi : BirOmurTheme.yaziTipi,
          fontSize: handwritten ? fontSize + 2 : fontSize,
          fontWeight: handwritten ? FontWeight.w400 : FontWeight.w700,
          height: 1.25,
          color: textColor ??
              (dolgu.computeLuminance() > 0.5
                  ? BirOmurColors.murekkep
                  : BirOmurColors.krem),
        ),
      ),
    );
    if (tilt == 0) return rozet;
    return Transform.rotate(angle: tilt * math.pi / 180, child: rozet);
  }
}

/// Menü satırlarının renkli ikon kutusu.
///
/// Düz dolgu, kalın kontur, içinde beyaz simge. Degrade yok.
class ComicIconTile extends StatelessWidget {
  const ComicIconTile({
    super.key,
    required this.icon,
    required this.accent,
    this.size = 46,
    this.tilt = 0,
  });

  final IconData icon;
  final BirOmurAccent accent;
  final double size;
  final double tilt;

  @override
  Widget build(BuildContext context) {
    final Widget kutu = Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: accent.color,
        borderRadius: BorderRadius.circular(size * 0.3),
        border: Border.all(
          color: Comic.konturOf(context),
          width: Comic.inceKontur,
        ),
        boxShadow: comicShadow(context, offset: Comic.kucukGolge),
      ),
      child: Icon(icon, size: size * 0.52, color: accent.onColor),
    );
    if (tilt == 0) return kutu;
    return Transform.rotate(angle: tilt * math.pi / 180, child: kutu);
  }
}

/// Kâğıt dokusu: zemine çizilen soluk noktalar.
///
/// Düz renk zemin "boş ekran" gibi duruyordu; bu doku kâğıt hissini
/// verir ama okunurluğa hiç dokunmaz.
class PaperBackground extends StatelessWidget {
  const PaperBackground({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return DecoratedBox(
      decoration: BoxDecoration(color: theme.colorScheme.surface),
      child: CustomPaint(
        painter: _PaperPainter(
          color: theme.colorScheme.onSurface.withValues(
            alpha: theme.brightness == Brightness.dark ? 0.05 : 0.055,
          ),
        ),
        child: child,
      ),
    );
  }
}

class _PaperPainter extends CustomPainter {
  _PaperPainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final Paint boya = Paint()..color = color;
    const double adim = 22;
    // Şaşırtmalı nokta düzeni: düz ızgaradan daha az makine işi durur.
    for (double y = 0; y < size.height + adim; y += adim) {
      final bool tek = ((y / adim).floor()).isOdd;
      for (double x = tek ? adim / 2 : 0; x < size.width + adim; x += adim) {
        canvas.drawCircle(Offset(x, y), 1.5, boya);
      }
    }
  }

  @override
  bool shouldRepaint(_PaperPainter oldDelegate) => oldDelegate.color != color;
}

/// El yazısıyla yazılan başlık.
class HandwrittenText extends StatelessWidget {
  const HandwrittenText(
    this.text, {
    super.key,
    this.size = 20,
    this.color,
    this.tilt = 0,
    this.textAlign,
    this.maxLines,
  });

  final String text;
  final double size;
  final Color? color;
  final double tilt;
  final TextAlign? textAlign;

  /// En fazla kaç satır? Verilirse taşan kısım "…" ile kısaltılır.
  final int? maxLines;

  @override
  Widget build(BuildContext context) {
    final Widget yazi = Text(
      text,
      textAlign: textAlign,
      maxLines: maxLines,
      overflow: maxLines == null ? null : TextOverflow.ellipsis,
      style: TextStyle(
        fontFamily: BirOmurTheme.elYazisi,
        fontSize: size,
        height: 1.2,
        color: color ?? Theme.of(context).colorScheme.onSurface,
      ),
    );
    if (tilt == 0) return yazi;
    return Transform.rotate(angle: tilt * math.pi / 180, child: yazi);
  }
}

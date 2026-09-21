import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../sound/sound_service.dart';
import '../theme/bir_omur_theme.dart';
import 'comic.dart';

/// Ana menülerin iç ekranları için ortak çerçeve.
///
/// Üstte geri çıkartması, altında bölümün başlığı (renkli ikon + fosforlu
/// kalemle çizilmiş gibi duran başlık), en altta içerik (Paket 19).
class SectionScaffold extends StatelessWidget {
  const SectionScaffold({
    super.key,
    required this.title,
    required this.children,
    this.subtitle,
    this.onBack,
    this.backLabel = 'Hayat',
    this.accent = BirOmurAccents.nar,
    this.icon,
  });

  final String title;
  final String? subtitle;
  final List<Widget> children;

  /// Geri dönüş eylemi; `null` ise geri satırı gösterilmez.
  final VoidCallback? onBack;
  final String backLabel;

  /// Bölümün rengi.
  final BirOmurAccent accent;

  /// Başlığın yanındaki simge.
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 28),
      children: <Widget>[
        if (onBack != null) ...<Widget>[
          Align(
            alignment: Alignment.centerLeft,
            child: StickerButton(
              key: const Key('section_back'),
              onPressed: onBack,
              sound: GameSound.back,
              color: theme.colorScheme.surfaceContainerHighest,
              radius: 999,
              shadowOffset: Comic.kucukGolge,
              padding: const EdgeInsets.fromLTRB(11, 7, 15, 7),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Icon(
                    Icons.arrow_back_rounded,
                    size: 17,
                    color: theme.colorScheme.onSurface,
                  ),
                  const SizedBox(width: 6),
                  Text(backLabel, style: theme.textTheme.labelMedium),
                ],
              ),
            ),
          ),
          const SizedBox(height: 4),
        ],
        SectionTitle(title: title, subtitle: subtitle, accent: accent, icon: icon),
        const SizedBox(height: 14),
        ...children,
      ],
    );
  }
}

/// Bölüm başlığı: renkli ikon çıkartması ve fosforlu kalem izi.
class SectionTitle extends StatelessWidget {
  const SectionTitle({
    super.key,
    required this.title,
    required this.accent,
    this.subtitle,
    this.icon,
  });

  final String title;
  final String? subtitle;
  final BirOmurAccent accent;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: <Widget>[
            if (icon != null) ...<Widget>[
              ComicIconTile(icon: icon!, accent: accent, size: 44, tilt: -5),
              const SizedBox(width: 12),
            ],
            Expanded(
              child: MarkerHighlight(
                color: accent.color,
                child: Text(title, style: theme.textTheme.headlineSmall),
              ),
            ),
          ],
        ),
        if (subtitle != null) ...<Widget>[
          const SizedBox(height: 8),
          Text(
            subtitle!,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ],
    );
  }
}

/// Yazının arkasına fosforlu kalemle çekilmiş gibi duran iz.
///
/// Düz bir dikdörtgen değil: uçları eğik, kenarları hafif dalgalı. Başlığı
/// cetvelle değil elle işaretlenmiş gösterir.
class MarkerHighlight extends StatelessWidget {
  const MarkerHighlight({super.key, required this.child, required this.color});

  final Widget child;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _MarkerPainter(color: color),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(4, 2, 8, 2),
        child: child,
      ),
    );
  }
}

class _MarkerPainter extends CustomPainter {
  _MarkerPainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    // İz yazının alt yarısını kaplar; üstteki harfler açıkta kalır.
    final double ust = size.height * 0.48;
    final double alt = size.height * 0.94;
    final Path iz = Path()
      ..moveTo(0, ust + 3)
      ..quadraticBezierTo(size.width * 0.3, ust - 2, size.width * 0.66, ust)
      ..quadraticBezierTo(size.width * 0.9, ust + 2, size.width, ust - 1)
      ..lineTo(size.width - 2, alt - 2)
      ..quadraticBezierTo(size.width * 0.6, alt + 3, size.width * 0.24, alt)
      ..quadraticBezierTo(size.width * 0.1, alt - 1, 1, alt + 1)
      ..close();
    canvas.drawPath(iz, Paint()..color = color.withValues(alpha: 0.55));
  }

  @override
  bool shouldRepaint(_MarkerPainter oldDelegate) => oldDelegate.color != color;
}

/// İç içe menülerde kullanılan, sayacı olan yönlendirme satırı.
///
/// Kâğıda yapıştırılmış bir çıkartmadır: kalın kontur, keskin gölge ve
/// basınca gerçekten çöken bir gövde.
class MenuRow extends StatelessWidget {
  const MenuRow({
    super.key,
    required this.title,
    required this.icon,
    required this.onTap,
    this.subtitle,
    this.trailingText,
    this.accent = BirOmurAccents.cini,
  });

  final String title;
  final String? subtitle;
  final IconData icon;
  final String? trailingText;
  final VoidCallback onTap;

  /// Satırın rengi.
  final BirOmurAccent accent;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return StickerButton(
      onPressed: onTap,
      expand: true,
      radius: Comic.yaricapBuyuk,
      padding: const EdgeInsets.fromLTRB(12, 11, 14, 11),
      child: Row(
        children: <Widget>[
          ComicIconTile(icon: icon, accent: accent, size: 46),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  title,
                  textAlign: TextAlign.left,
                  style: theme.textTheme.titleMedium,
                ),
                if (subtitle != null) ...<Widget>[
                  const SizedBox(height: 1),
                  Text(
                    subtitle!,
                    textAlign: TextAlign.left,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (trailingText != null) ...<Widget>[
            const SizedBox(width: 8),
            ComicTag(text: trailingText!, color: accent.color, tilt: 3),
          ],
          const SizedBox(width: 6),
          Icon(
            Icons.arrow_forward_ios_rounded,
            size: 15,
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ],
      ),
    );
  }
}

/// Menü satırlarının ve panel başlıklarının renkli ikon kutusu.
///
/// Eski adıyla korunur; gövdesi [ComicIconTile]'dır.
class AccentIconTile extends StatelessWidget {
  const AccentIconTile({
    super.key,
    required this.icon,
    required this.accent,
    this.size = 46,
  });

  final IconData icon;
  final BirOmurAccent accent;
  final double size;

  @override
  Widget build(BuildContext context) =>
      ComicIconTile(icon: icon, accent: accent, size: size);
}

/// Satır sonundaki sayaç rozeti.
class CountBadge extends StatelessWidget {
  const CountBadge({super.key, required this.text, required this.accent});

  final String text;
  final BirOmurAccent accent;

  @override
  Widget build(BuildContext context) =>
      ComicTag(text: text, color: accent.color, tilt: 3);
}

/// Henüz işlevi olmayan alanlar için **tıklanamaz** bilgi kutusu.
///
/// Deftere iliştirilmiş bir not gibi: hafif eğik, gölgesiz, kâğıt tonunda.
class InfoPanel extends StatelessWidget {
  const InfoPanel({super.key, required this.text, this.icon});

  final String text;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Transform.rotate(
      angle: -0.4 * math.pi / 180,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(14, 13, 14, 13),
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainer,
          borderRadius: BorderRadius.circular(Comic.yaricap),
          border: Border.all(
            color: Comic.konturOf(context).withValues(alpha: 0.5),
            width: Comic.inceKontur,
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            if (icon != null) ...<Widget>[
              Icon(icon, size: 18, color: theme.colorScheme.onSurfaceVariant),
              const SizedBox(width: 10),
            ],
            Expanded(
              child: Text(
                text,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Bilgi kartlarının ortak kabuğu.
///
/// Çizgi roman dilinde: düz dolgu, kalın kontur, keskin gölge.
BoxDecoration panelDecoration(
  BuildContext context, {
  double radius = Comic.yaricapBuyuk,
  bool raised = true,
}) {
  final ThemeData theme = Theme.of(context);
  return BoxDecoration(
    color: theme.colorScheme.surfaceContainerHighest,
    borderRadius: BorderRadius.circular(radius),
    border: Border.all(color: Comic.konturOf(context), width: Comic.kontur),
    boxShadow: raised ? comicShadow(context) : null,
  );
}

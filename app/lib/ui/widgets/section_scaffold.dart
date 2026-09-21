import 'package:flutter/material.dart';

import '../sound/sound_scope.dart';
import '../sound/sound_service.dart';
import '../theme/bir_omur_theme.dart';

/// Ana menülerin iç ekranları için ortak çerçeve.
///
/// Üstte geri dönüş satırı, altında bölümün **renkli başlık kartı**, en
/// altta içerik. Başlık kartı bölümün rengini taşır: hangi menüde
/// olunduğu yazıyı okumadan da bellidir (Paket 16).
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

  /// Bölümün rengi: başlık kartı ve geri düğmesi bu rengi alır.
  final BirOmurAccent accent;

  /// Başlık kartının sağında duran büyük, yarı saydam simge.
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
      children: <Widget>[
        if (onBack != null) ...<Widget>[
          Align(
            alignment: Alignment.centerLeft,
            child: _BackPill(
              key: const Key('section_back'),
              label: backLabel,
              onTap: onBack!,
              accent: accent,
            ),
          ),
          const SizedBox(height: 10),
        ],
        SectionHeroCard(
          title: title,
          subtitle: subtitle,
          accent: accent,
          icon: icon,
        ),
        const SizedBox(height: 14),
        ...children,
      ],
    );
  }
}

/// Bölümün üstündeki renkli başlık kartı.
///
/// Degrade zemin, beyaz başlık ve sağ kenarda taşan yarı saydam bir simge.
/// Menülerin birbirine karışmaması için her bölüm kendi rengiyle açılır.
class SectionHeroCard extends StatelessWidget {
  const SectionHeroCard({
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

    return Container(
      decoration: BoxDecoration(
        gradient: accent.heroGradient,
        borderRadius: BorderRadius.circular(26),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: accent.heroShadow.withValues(alpha: 0.28),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(26),
        child: Stack(
          children: <Widget>[
            // Sağ kenarda duran büyük simge: kartı dolduran sessiz bir
            // doku. Metnin okunmasını engellemeyecek kadar soluktur.
            if (icon != null)
              Positioned(
                right: 14,
                top: 0,
                bottom: 0,
                child: Center(
                  child: Icon(
                    icon,
                    size: 62,
                    color: Colors.white.withValues(alpha: 0.24),
                  ),
                ),
              ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 92, 17),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    title,
                    style: theme.textTheme.headlineSmall?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -0.8,
                    ),
                  ),
                  if (subtitle != null) ...<Widget>[
                    const SizedBox(height: 7),
                    Text(
                      subtitle!,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: Colors.white.withValues(alpha: 0.88),
                        height: 1.45,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Geri dönüş satırı: yuvarlak, renkli ve dokunması kolay.
class _BackPill extends StatelessWidget {
  const _BackPill({
    super.key,
    required this.label,
    required this.onTap,
    required this.accent,
  });

  final String label;
  final VoidCallback onTap;
  final BirOmurAccent accent;

  @override
  Widget build(BuildContext context) {
    final Color renk = accent.of(context);
    return Material(
      color: accent.softOf(context),
      borderRadius: BorderRadius.circular(999),
      child: InkWell(
        onTap: () {
          SoundScope.play(context, GameSound.back);
          onTap();
        },
        borderRadius: BorderRadius.circular(999),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(9, 8, 15, 8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Icon(Icons.arrow_back_rounded, size: 17, color: renk),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  color: renk,
                  fontWeight: FontWeight.w800,
                  fontSize: 13.5,
                  letterSpacing: -0.1,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// İç içe menülerde kullanılan, sayacı olan yönlendirme satırı.
///
/// Kartın kendisi **renksizdir**: renk yalnızca ikon kutusunda, sayaç
/// rozetinde ve dokunma dalgasında görünür. Eskiden her satır kendi
/// pastel tonuyla boyanıyordu; yan yana geldiklerinde ekran soluk ve
/// karaktersiz duruyordu (Paket 16).
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
    final bool gece = theme.brightness == Brightness.dark;
    final Color renk = accent.of(context);

    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: gece
                ? Colors.black.withValues(alpha: 0.45)
                : const Color(0xFF1B1A2E).withValues(alpha: 0.07),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Material(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          onTap: () {
            SoundScope.play(context, GameSound.tap);
            onTap();
          },
          splashColor: renk.withValues(alpha: 0.12),
          highlightColor: renk.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(20),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: gece
                    ? theme.colorScheme.outlineVariant
                    : const Color(0xFFECECF3),
              ),
            ),
            padding: const EdgeInsets.fromLTRB(12, 12, 14, 12),
            child: Row(
              children: <Widget>[
                AccentIconTile(icon: icon, accent: accent),
                const SizedBox(width: 13),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        title,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                          fontSize: 15.5,
                        ),
                      ),
                      if (subtitle != null) ...<Widget>[
                        const SizedBox(height: 2),
                        Text(
                          subtitle!,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                            height: 1.3,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                if (trailingText != null) ...<Widget>[
                  const SizedBox(width: 8),
                  CountBadge(text: trailingText!, accent: accent),
                ],
                const SizedBox(width: 6),
                Icon(
                  Icons.chevron_right_rounded,
                  size: 22,
                  color: theme.colorScheme.onSurfaceVariant
                      .withValues(alpha: 0.55),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Menü satırlarının ve panel başlıklarının renkli ikon kutusu.
///
/// Kartlar renksiz olduğu için bütün canlılık buradadır: doygun bir
/// degrade ve altında kendi renginden bir ışık.
class AccentIconTile extends StatelessWidget {
  const AccentIconTile({
    super.key,
    required this.icon,
    required this.accent,
    this.size = 44,
  });

  final IconData icon;
  final BirOmurAccent accent;

  /// Kutunun kenar uzunluğu.
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: accent.gradientOf(context),
        borderRadius: BorderRadius.circular(size * 0.32),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: accent.of(context).withValues(alpha: 0.42),
            blurRadius: 12,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Icon(icon, size: size * 0.5, color: Colors.white),
    );
  }
}

/// Satır sonundaki sayaç rozeti.
class CountBadge extends StatelessWidget {
  const CountBadge({super.key, required this.text, required this.accent});

  final String text;
  final BirOmurAccent accent;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: accent.softOf(context),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: accent.of(context),
          fontWeight: FontWeight.w900,
          fontSize: 13,
        ),
      ),
    );
  }
}

/// Henüz işlevi olmayan alanlar için **tıklanamaz** bilgi kutusu.
class InfoPanel extends StatelessWidget {
  const InfoPanel({super.key, required this.text, this.icon});

  final String text;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          if (icon != null) ...<Widget>[
            Icon(
              icon,
              size: 18,
              color: theme.colorScheme.onSurfaceVariant,
            ),
            const SizedBox(width: 11),
          ],
          Expanded(
            child: Text(
              text,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                height: 1.45,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Bilgi kartlarının ortak kabuğu.
///
/// Menü satırlarıyla aynı dili konuşur: **renksiz** zemin, ince çizgi ve
/// yumuşak bir gölge. Renk kartın içindeki ikon kutusundan ve rozetlerden
/// gelir. Eskiden her panel kendi renginin %10'u kadar boyanıyordu;
/// yan yana geldiklerinde ekran soluk duruyordu (Paket 16).
BoxDecoration panelDecoration(
  BuildContext context, {
  double radius = 20,
  bool raised = true,
}) {
  final ThemeData theme = Theme.of(context);
  final bool gece = theme.brightness == Brightness.dark;
  return BoxDecoration(
    color: theme.colorScheme.surfaceContainerHighest,
    borderRadius: BorderRadius.circular(radius),
    border: Border.all(
      color: gece
          ? theme.colorScheme.outlineVariant
          : const Color(0xFFECECF3),
    ),
    boxShadow: raised
        ? <BoxShadow>[
            BoxShadow(
              color: gece
                  ? Colors.black.withValues(alpha: 0.45)
                  : const Color(0xFF1B1A2E).withValues(alpha: 0.07),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ]
        : const <BoxShadow>[],
  );
}

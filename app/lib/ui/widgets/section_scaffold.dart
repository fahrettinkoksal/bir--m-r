import 'package:flutter/material.dart';

import '../theme/bir_omur_theme.dart';

/// Ana menülerin iç ekranları için ortak çerçeve.
///
/// Üstte geri dönüş satırı ve başlık, altında içerik. İç içe menülerde aynı
/// çerçeve kullanılır; böylece derinlik arttıkça düzen bozulmaz.
class SectionScaffold extends StatelessWidget {
  const SectionScaffold({
    super.key,
    required this.title,
    required this.children,
    this.subtitle,
    this.onBack,
    this.backLabel = 'Hayat',
    this.accent = BirOmurAccents.nar,
  });

  final String title;
  final String? subtitle;
  final List<Widget> children;

  /// Geri dönüş eylemi; `null` ise geri satırı gösterilmez.
  final VoidCallback? onBack;
  final String backLabel;

  /// Bölümün rengi: başlık altındaki şerit ve geri düğmesi bu rengi alır.
  final BirOmurAccent accent;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final Color renk = accent.of(context);

    return ListView(
      padding: const EdgeInsets.fromLTRB(18, 8, 18, 26),
      children: <Widget>[
        if (onBack != null)
          Align(
            alignment: Alignment.centerLeft,
            child: _BackPill(label: backLabel, onTap: onBack!, color: renk),
          ),
        const SizedBox(height: 8),
        Text(
          title,
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w800,
            letterSpacing: -0.6,
          ),
        ),
        const SizedBox(height: 7),
        // Başlığın altındaki kısa renk şeridi: hangi bölümde olduğunu
        // yazıyı okumadan da belli eder. Liste öğeleri tam genişliğe
        // yayıldığı için hizalama açıkça verilir.
        Align(
          alignment: Alignment.centerLeft,
          child: Container(
            height: 4,
            width: 48,
            decoration: BoxDecoration(
              gradient: accent.gradientOf(context),
              borderRadius: BorderRadius.circular(999),
            ),
          ),
        ),
        if (subtitle != null) ...<Widget>[
          const SizedBox(height: 10),
          Text(
            subtitle!,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              height: 1.45,
            ),
          ),
        ],
        const SizedBox(height: 14),
        ...children,
      ],
    );
  }
}

/// Geri dönüş satırı: yuvarlak, renkli ve dokunması kolay.
class _BackPill extends StatelessWidget {
  const _BackPill({
    required this.label,
    required this.onTap,
    required this.color,
  });

  final String label;
  final VoidCallback onTap;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color.withValues(alpha: 0.10),
      borderRadius: BorderRadius.circular(999),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(8, 7, 14, 7),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Icon(Icons.chevron_left, size: 19, color: color),
              const SizedBox(width: 2),
              Text(
                label,
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.w700,
                  fontSize: 13.5,
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
/// Her satır kendi rengini taşır: renkli ikon kutusu, sayaç rozeti ve
/// yumuşak bir zemin. Amaç uzun listelerde aranan satırı hızlı bulmak.
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
        borderRadius: BorderRadius.circular(22),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: gece
                ? Colors.black.withValues(alpha: 0.35)
                : renk.withValues(alpha: 0.13),
            blurRadius: 14,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Material(
        color: gece
            ? theme.colorScheme.surfaceContainerHigh
            : Color.alphaBlend(
                renk.withValues(alpha: 0.05),
                theme.colorScheme.surfaceContainerHighest,
              ),
        borderRadius: BorderRadius.circular(22),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(22),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: renk.withValues(alpha: 0.24)),
            ),
            padding: const EdgeInsets.fromLTRB(13, 12, 13, 12),
            child: Row(
              children: <Widget>[
                AccentIconTile(icon: icon, accent: accent),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        title,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      if (subtitle != null) ...<Widget>[
                        const SizedBox(height: 3),
                        Text(
                          subtitle!,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                            height: 1.35,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                if (trailingText != null) ...<Widget>[
                  const SizedBox(width: 8),
                  _CountBadge(text: trailingText!, color: renk),
                ],
                const SizedBox(width: 8),
                Icon(Icons.chevron_right, size: 22, color: renk),
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
/// Menüler ile bilgi panelleri aynı görsel dili konuşsun diye ortak
/// kullanılır.
class AccentIconTile extends StatelessWidget {
  const AccentIconTile({
    super.key,
    required this.icon,
    required this.accent,
    this.size = 42,
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
        borderRadius: BorderRadius.circular(size * 0.33),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: accent.deepOf(context).withValues(alpha: 0.32),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Icon(icon, size: size * 0.5, color: BirOmurColors.krem),
    );
  }
}

/// Satır sonundaki sayaç rozeti.
class _CountBadge extends StatelessWidget {
  const _CountBadge({required this.text, required this.color});

  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w800,
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
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.8),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          if (icon != null) ...<Widget>[
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(9),
              ),
              child: Icon(
                icon,
                size: 16,
                color: theme.colorScheme.onSurfaceVariant,
              ),
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

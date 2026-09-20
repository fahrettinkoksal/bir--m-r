import 'package:flutter/material.dart';

/// Karakter değerinin **seviyesine göre** rengi.
///
/// Sayıya bakmadan da durum anlaşılsın diye: düşük değer uyarı rengine,
/// yüksek değer çini yeşiline yaklaşır. Eşikler `prototypeOnly`'dir.
Color statColor(ThemeData theme, int value) {
  if (value < 30) return theme.colorScheme.error;
  if (value < 55) return theme.colorScheme.tertiary;
  return theme.colorScheme.secondary;
}

/// Değeri **yumuşak geçişle** gösteren ince çubuk.
///
/// Olaydan sonra değişen değer ekranda birden zıplamaz; küçük bir
/// hareketle yeni yerine gider.
class AnimatedStatBar extends StatelessWidget {
  const AnimatedStatBar({
    super.key,
    required this.value,
    required this.color,
    this.minHeight = 5,
    this.radius = 6,
  });

  final int value;
  final Color color;
  final double minHeight;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: TweenAnimationBuilder<double>(
        tween: Tween<double>(begin: 0, end: (value / 100).clamp(0.0, 1.0)),
        duration: const Duration(milliseconds: 450),
        curve: Curves.easeOutCubic,
        builder: (BuildContext context, double oran, _) =>
            LinearProgressIndicator(
          value: oran,
          minHeight: minHeight,
          backgroundColor:
              theme.colorScheme.outlineVariant.withValues(alpha: 0.4),
          valueColor: AlwaysStoppedAnimation<Color>(color),
        ),
      ),
    );
  }
}

/// Tek bir karakter değerini gösteren çubuk.
class StatBar extends StatelessWidget {
  const StatBar({
    super.key,
    required this.label,
    required this.value,
    this.color,
  });

  final String label;
  final int value;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final Color barColor = color ?? statColor(theme, value);

    return Semantics(
      label: '$label $value',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              Text(label, style: theme.textTheme.labelLarge),
              Text(
                '$value',
                style: theme.textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: barColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          AnimatedStatBar(
            value: value,
            color: barColor,
            minHeight: 8,
            radius: 8,
          ),
        ],
      ),
    );
  }
}

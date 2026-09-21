import 'package:flutter/material.dart';

import '../theme/bir_omur_theme.dart';

/// Karakter değerinin **seviyesine göre** rengi.
///
/// Sayıya bakmadan da durum anlaşılsın diye: düşük değer kırmızıya,
/// yüksek değer yeşile yaklaşır. Eşikler `prototypeOnly`'dir.
Color statColor(ThemeData theme, int value) => statColorOnDark(value);

/// Değerin koyu zemin üzerindeki rengi.
///
/// Afiş renkleri hem kâğıtta hem koyu zeminde okunduğu için iki tema
/// aynı tonu kullanır; ayrı bir gece paleti gerekmiyor.
Color statColorOnDark(int value) {
  if (value < 30) return BirOmurColors.degerDusuk;
  if (value < 55) return BirOmurColors.degerOrta;
  return BirOmurColors.degerYuksek;
}

/// Değeri **yumuşak geçişle** gösteren çizilmiş çubuk.
///
/// Çizgi roman diline uyar: kalın kontur, düz dolgu, keskin uçlar.
/// Olaydan sonra değişen değer ekranda birden zıplamaz.
class AnimatedStatBar extends StatelessWidget {
  const AnimatedStatBar({
    super.key,
    required this.value,
    required this.color,
    this.minHeight = 12,
    this.radius = 999,
    this.trackColor,
  });

  final int value;
  final Color color;
  final double minHeight;
  final double radius;

  /// Çubuğun boş kısmının rengi; verilmezse temadan alınır.
  final Color? trackColor;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final Color kontur = Comic.konturOf(context);
    return Container(
      height: minHeight,
      decoration: BoxDecoration(
        color: trackColor ?? theme.colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: kontur, width: 1.8),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(radius),
        child: Align(
          alignment: Alignment.centerLeft,
          child: TweenAnimationBuilder<double>(
            tween: Tween<double>(
              begin: 0,
              end: (value / 100).clamp(0.0, 1.0),
            ),
            duration: const Duration(milliseconds: 450),
            curve: Curves.easeOutCubic,
            builder: (BuildContext context, double oran, _) =>
                FractionallySizedBox(
              widthFactor: oran,
              child: Container(color: color),
            ),
          ),
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
              Text(label, style: theme.textTheme.titleSmall),
              Text(
                '$value',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          AnimatedStatBar(value: value, color: barColor, minHeight: 14),
        ],
      ),
    );
  }
}

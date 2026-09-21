import 'package:flutter/material.dart';

import '../theme/bir_omur_theme.dart';

/// Karakter değerinin **seviyesine göre** rengi.
///
/// Sayıya bakmadan da durum anlaşılsın diye: düşük değer uyarı rengine,
/// yüksek değer çini yeşiline yaklaşır. Eşikler `prototypeOnly`'dir.
Color statColor(ThemeData theme, int value) {
  // Koyu temada çini turkuazı ile pirinç sarısı birbirine yaklaşıp ayırt
  // edilemiyordu; koyu zemin için daha açık karşılıkları kullanılır.
  final bool koyu = theme.brightness == Brightness.dark;
  if (koyu) return statColorOnDark(value);
  if (value < 30) return BirOmurColors.nar;
  if (value < 55) return BirOmurColors.pirincKoyu;
  return BirOmurColors.ciniKoyu;
}

/// Değerin **koyu zemin** üzerindeki rengi.
///
/// Üst karakter başlığı her temada koyu degrade taşır; oradaki çubuklar
/// tema açık olsa bile bu renkleri kullanır.
Color statColorOnDark(int value) {
  if (value < 30) return BirOmurColors.geceUyari;
  if (value < 55) return BirOmurColors.gecePirinc;
  return BirOmurColors.geceCini;
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
    this.minHeight = 6,
    this.radius = 6,
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
          backgroundColor: trackColor ?? theme.colorScheme.outlineVariant,
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

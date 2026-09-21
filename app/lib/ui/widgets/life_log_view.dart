import 'package:flutter/material.dart';

import '../../domain/models/life_log.dart';
import '../theme/bir_omur_theme.dart';

/// Hayat günlüğünün **bir yaşa ait** bloğu.
///
/// Günlük artık satır satır değil, yaşa göre kümelenmiş anlatılır: bir
/// yılda olan her şey tek başlığın altında toplanır. Eskiden her satırda
/// yaş tekrar yazıldığı için aynı sayı arka arkaya onlarca kez
/// görünebiliyordu.
class LifeLogBlock {
  const LifeLogBlock({required this.age, required this.entries});

  final int age;
  final List<LifeLogEntry> entries;
}

/// Günlük satırlarını yaşa göre **en yeniden eskiye** kümeler.
List<LifeLogBlock> groupLogByAge(List<LifeLogEntry> entries) {
  final List<LifeLogBlock> bloklar = <LifeLogBlock>[];
  for (int i = entries.length - 1; i >= 0; i--) {
    final LifeLogEntry e = entries[i];
    if (bloklar.isEmpty || bloklar.last.age != e.age) {
      bloklar.add(LifeLogBlock(age: e.age, entries: <LifeLogEntry>[e]));
    } else {
      bloklar.last.entries.add(e);
    }
  }
  return bloklar;
}

/// Hayat günlüğü — hatıra defteri hissi veren, en yeni yaş üstte liste.
class LifeLogView extends StatelessWidget {
  const LifeLogView({super.key, required this.entries});

  final List<LifeLogEntry> entries;

  @override
  Widget build(BuildContext context) {
    final List<LifeLogBlock> bloklar = groupLogByAge(entries);
    return Column(
      children: <Widget>[
        for (int i = 0; i < bloklar.length; i++) ...<Widget>[
          LifeLogAgeBlock(block: bloklar[i], isCurrentAge: i == 0),
          if (i != bloklar.length - 1) const SizedBox(height: 10),
        ],
      ],
    );
  }
}

/// Tek bir yaşın günlük kartı.
class LifeLogAgeBlock extends StatelessWidget {
  const LifeLogAgeBlock({
    super.key,
    required this.block,
    this.isCurrentAge = false,
  });

  final LifeLogBlock block;

  /// Oyuncunun **içinde bulunduğu** yaş mı? Bu blok biraz öne çıkar.
  final bool isCurrentAge;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final bool gece = theme.brightness == Brightness.dark;

    return Container(
      key: Key('log_age_${block.age}'),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isCurrentAge
              ? BirOmurColors.nar.withValues(alpha: gece ? 0.55 : 0.35)
              : theme.colorScheme.outlineVariant,
          width: isCurrentAge ? 1.5 : 1,
        ),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: gece
                ? Colors.black.withValues(alpha: 0.4)
                : const Color(0xFF1B1A2E)
                    .withValues(alpha: isCurrentAge ? 0.09 : 0.05),
            blurRadius: isCurrentAge ? 18 : 12,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      padding: const EdgeInsets.fromLTRB(14, 13, 14, 13),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              // Yaş rozeti: bu yıl dolu nar kırmızısı, geçmiş yıllar
              // sakin bir gri. Günlükte "şimdi" hemen bulunur.
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 11,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  gradient: isCurrentAge
                      ? const LinearGradient(
                          colors: <Color>[
                            BirOmurColors.narAcik,
                            BirOmurColors.nar,
                          ],
                        )
                      : null,
                  color: isCurrentAge
                      ? null
                      : theme.colorScheme.surfaceContainer,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  '${block.age} yaş',
                  style: theme.textTheme.labelSmall?.copyWith(
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.2,
                    color: isCurrentAge
                        ? Colors.white
                        : theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Container(
                  height: 1,
                  color: theme.colorScheme.outlineVariant,
                ),
              ),
              if (isCurrentAge) ...<Widget>[
                const SizedBox(width: 10),
                Text(
                  'BU YIL',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: BirOmurColors.nar,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.1,
                    fontSize: 10,
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 10),
          for (final LifeLogEntry e in block.entries)
            Padding(
              padding: const EdgeInsets.only(bottom: 7),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  // Kategori simgesi kendi renginden yumuşak bir kutunun
                  // içinde durur; satırlar arasında göz kayması azalır.
                  Container(
                    margin: const EdgeInsets.only(top: 1, right: 10),
                    padding: const EdgeInsets.all(5),
                    decoration: BoxDecoration(
                      color: _renk(theme, e.category).withValues(alpha: 0.13),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      _icon(e.category),
                      size: 13,
                      color: _renk(theme, e.category),
                    ),
                  ),
                  Expanded(
                    child: Text(e.text, style: theme.textTheme.bodyMedium),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  static IconData _icon(LogCategory category) {
    switch (category) {
      case LogCategory.dogum:
        return Icons.auto_awesome_outlined;
      case LogCategory.aile:
        return Icons.people_outline;
      case LogCategory.kisisel:
        return Icons.person_outline;
      case LogCategory.yasDegisimi:
        return Icons.cake_outlined;
    }
  }

  static Color _renk(ThemeData theme, LogCategory category) {
    final bool gece = theme.brightness == Brightness.dark;
    switch (category) {
      case LogCategory.dogum:
      case LogCategory.yasDegisimi:
        return gece ? BirOmurColors.pirincAcik : BirOmurColors.pirincKoyu;
      case LogCategory.aile:
        return gece ? BirOmurColors.ciniAcik : BirOmurColors.cini;
      case LogCategory.kisisel:
        return gece
            ? const Color(0xFFA98BFF)
            : const Color(0xFF6C4BD8);
    }
  }
}

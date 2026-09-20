import 'package:flutter/material.dart';

import '../../domain/models/life_log.dart';

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
    final Color vurgu = isCurrentAge
        ? theme.colorScheme.primary
        : theme.colorScheme.outlineVariant;

    return Container(
      key: Key('log_age_${block.age}'),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isCurrentAge
              ? theme.colorScheme.primary.withValues(alpha: 0.45)
              : theme.colorScheme.outlineVariant.withValues(alpha: 0.7),
          width: isCurrentAge ? 1.4 : 1,
        ),
      ),
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 3,
                ),
                decoration: BoxDecoration(
                  color: isCurrentAge
                      ? theme.colorScheme.primary.withValues(alpha: 0.12)
                      : theme.colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  '${block.age} yaş',
                  style: theme.textTheme.labelSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: isCurrentAge
                        ? theme.colorScheme.primary
                        : theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Container(
                  height: 1,
                  color: vurgu.withValues(alpha: 0.5),
                ),
              ),
              if (isCurrentAge) ...<Widget>[
                const SizedBox(width: 8),
                Text(
                  'bu yıl',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 8),
          for (final LifeLogEntry e in block.entries)
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Padding(
                    padding: const EdgeInsets.only(top: 2, right: 8),
                    child: Icon(
                      _icon(e.category),
                      size: 15,
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
    switch (category) {
      case LogCategory.dogum:
      case LogCategory.yasDegisimi:
        return theme.colorScheme.tertiary;
      case LogCategory.aile:
        return theme.colorScheme.secondary;
      case LogCategory.kisisel:
        return theme.colorScheme.onSurfaceVariant;
    }
  }
}

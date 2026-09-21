import 'package:flutter/material.dart';

import '../../domain/models/life_log.dart';
import '../theme/bir_omur_theme.dart';
import 'comic.dart';
import 'kilim_divider.dart';

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

    // Günlük bir deftere yapıştırılmış sayfa gibi durur: yaş etiketi el
    // yazısıyla yazılmış eğik bir çıkartma, satırlar renkli birer işaret
    // (Paket 19).
    return Container(
      key: Key('log_age_${block.age}'),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(Comic.yaricapBuyuk),
        border: Border.all(
          color: Comic.konturOf(context),
          width: isCurrentAge ? Comic.kontur + 1 : Comic.kontur,
        ),
        boxShadow: comicShadow(
          context,
          offset: isCurrentAge ? Comic.golge + 1 : Comic.golge,
        ),
      ),
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              ComicTag(
                text: '${block.age} yaş',
                handwritten: true,
                fontSize: 13,
                tilt: -3,
                color: isCurrentAge
                    ? BirOmurColors.sari
                    : theme.colorScheme.surfaceContainer,
              ),
              const SizedBox(width: 10),
              Expanded(child: KilimDivider(height: 8)),
              if (isCurrentAge) ...<Widget>[
                const SizedBox(width: 8),
                const ComicTag(
                  text: 'BU YIL',
                  color: BirOmurColors.kirmizi,
                  textColor: BirOmurColors.krem,
                  tilt: 3,
                  fontSize: 10.5,
                ),
              ],
            ],
          ),
          const SizedBox(height: 10),
          for (final LifeLogEntry e in block.entries)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  // Satır başındaki renkli işaret: kategorisi bir bakışta
                  // belli olur.
                  Container(
                    margin: const EdgeInsets.only(top: 3, right: 10),
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      color: _renk(theme, e.category),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: Comic.konturOf(context),
                        width: 1.8,
                      ),
                    ),
                    child: Icon(
                      _icon(e.category),
                      size: 13,
                      color: BirOmurColors.murekkep,
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
        return Icons.auto_awesome_rounded;
      case LogCategory.aile:
        return Icons.people_rounded;
      case LogCategory.kisisel:
        return Icons.person_rounded;
      case LogCategory.yasDegisimi:
        return Icons.cake_rounded;
    }
  }

  static Color _renk(ThemeData theme, LogCategory category) {
    switch (category) {
      case LogCategory.dogum:
      case LogCategory.yasDegisimi:
        return BirOmurColors.sari;
      case LogCategory.aile:
        return BirOmurColors.turkuaz;
      case LogCategory.kisisel:
        return BirOmurColors.mor;
    }
  }
}

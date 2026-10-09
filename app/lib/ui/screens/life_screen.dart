import 'package:flutter/material.dart';

import '../../domain/life/year_review.dart';
import '../../domain/models/game_state.dart';
import '../../state/game_scope.dart';
import '../widgets/effect_chips.dart';
import '../widgets/life_log_view.dart';
import '../widgets/pregnancy_notice.dart';
import '../widgets/section_header.dart';

/// Ana ekranın gövdesi: hayat günlüğü / olay akışı.
///
/// Karakter özeti üstte sabit başlıkta, **Yaş Al** altta ortadaki ana eylem
/// düğmesindedir; bu ekran yalnızca yaşananların akışını gösterir.
class LifeScreen extends StatelessWidget {
  const LifeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final GameState state = GameScope.of(context).state!;
    final ThemeData theme = Theme.of(context);

    // Uzun hayatlarda günlük yüzlerce satır olabiliyor; bloklar tembel
    // kurulur, böylece 90 yaşındaki bir hayatın ekranı da akıcı kalır.
    final List<LifeLogBlock> bloklar = groupLogByAge(state.log);

    // Biten yılın özeti günlüğün üstünde durur (D-096): oyuncu satırları
    // taramadan yılın nasıl geçtiğini görür.
    final YearSummary? ozet = state.lastYearSummary;

    // Günlüğün üstündeki sabit bloklar. Eskiden indeks aritmetiğiyle
    // sayılıyordu; bekleyen doğum kartı üçüncü blok olunca aritmetik
    // okunmaz hâle geliyordu, bu yüzden liste hâline getirildi. Günlük
    // blokları hâlâ tembel kurulur: burada yalnızca üç küçük widget var.
    final List<Widget> ustBloklar = <Widget>[
      // Bekleyen doğum en üstte (Paket BK/1): bir yıl süren, sonunda
      // haneyi büyüten bir durum tek bir günlük satırına sığmıyor
      // (Q-202).
      if (state.isExpecting)
        Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: PregnancyCard(
            key: const Key('life_pregnancy_card'),
            state: state,
          ),
        ),
      if (ozet != null)
        Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: _YearSummaryCard(summary: ozet),
        ),
      const Padding(
        padding: EdgeInsets.only(bottom: 10),
        child: SectionHeader(
          title: 'Hayat günlüğü',
          subtitle: 'Başından geçenlerin kaydı',
        ),
      ),
    ];
    final int basliklar = ustBloklar.length;

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(18, 14, 18, 20),
      itemCount: bloklar.length + basliklar + 1,
      itemBuilder: (BuildContext context, int index) {
        if (index < basliklar) return ustBloklar[index];
        if (index == bloklar.length + basliklar) {
          return Padding(
            padding: const EdgeInsets.only(top: 14),
            child: Text(
              'Hazır olduğunda alttaki Yaş Al düğmesine bas; bir yaşın her '
              'şeyini bitirmek zorunda değilsin.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          );
        }
        final int i = index - basliklar;
        return Padding(
          padding: EdgeInsets.only(bottom: i == bloklar.length - 1 ? 0 : 10),
          child: LifeLogAgeBlock(block: bloklar[i], isCurrentAge: i == 0),
        );
      },
    );
  }
}

/// Biten yılın özeti kartı (D-096).
///
/// Buradaki satırlar **gerçekten uygulanmış** değişimlerdir: yılın
/// başındaki değerlerle bugünkü değerler karşılaştırılarak üretilir, bu
/// yüzden gerçekleşmemiş bir kazanç yazamaz.
class _YearSummaryCard extends StatelessWidget {
  const _YearSummaryCard({required this.summary});

  final YearSummary summary;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Card(
      key: const Key('year_summary_card'),
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                Icon(
                  Icons.summarize_outlined,
                  size: 18,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '${summary.age} yaşın böyle geçti',
                    key: const Key('year_summary_title'),
                    style: theme.textTheme.titleSmall,
                  ),
                ),
              ],
            ),
            if (summary.effects.isNotEmpty) ...<Widget>[
              const SizedBox(height: 10),
              EffectChips(
                key: const Key('year_summary_effects'),
                effects: summary.effects,
              ),
            ],
            // --- Çocukların yılı (Paket BK/5) ---------------------
            //
            // Ebeveynliğin karşılığı burada görünür: ödev, harçlık,
            // kurs ve kural çocuğun kaydını değiştirdiyse farkı bu
            // satırlarda yazar. Değişen bir şey yoksa satır da yok.
            for (final ChildYearSummary cocuk in summary.children)
              Padding(
                key: Key('year_summary_child_${cocuk.childId}'),
                padding: const EdgeInsets.only(top: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      '${cocuk.name} · ${cocuk.age} yaşında',
                      style: theme.textTheme.labelLarge,
                    ),
                    for (final String an in cocuk.milestones)
                      Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: Text(
                          an,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                    if (cocuk.effects.isNotEmpty) ...<Widget>[
                      const SizedBox(height: 6),
                      EffectChips(effects: cocuk.effects),
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

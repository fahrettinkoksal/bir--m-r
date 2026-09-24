import 'package:flutter/material.dart';

import '../../domain/life/year_review.dart';
import '../../domain/models/game_state.dart';
import '../../state/game_scope.dart';
import '../widgets/effect_chips.dart';
import '../widgets/life_log_view.dart';
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
    final int basliklar = ozet == null ? 1 : 2;

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(18, 14, 18, 20),
      itemCount: bloklar.length + basliklar + 1,
      itemBuilder: (BuildContext context, int index) {
        if (ozet != null && index == 0) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _YearSummaryCard(summary: ozet),
          );
        }
        if (index == basliklar - 1) {
          return const Padding(
            padding: EdgeInsets.only(bottom: 10),
            child: SectionHeader(
              title: 'Hayat günlüğü',
              subtitle: 'Başından geçenlerin kaydı',
            ),
          );
        }
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
            const SizedBox(height: 10),
            EffectChips(
              key: const Key('year_summary_effects'),
              effects: summary.effects,
            ),
          ],
        ),
      ),
    );
  }
}

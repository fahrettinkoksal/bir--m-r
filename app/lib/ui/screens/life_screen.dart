import 'package:flutter/material.dart';

import '../../domain/models/game_state.dart';
import '../../state/game_scope.dart';
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

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(18, 14, 18, 20),
      itemCount: bloklar.length + 2,
      itemBuilder: (BuildContext context, int index) {
        if (index == 0) {
          return const Padding(
            padding: EdgeInsets.only(bottom: 10),
            child: SectionHeader(
              title: 'Hayat günlüğü',
              subtitle: 'Başından geçenlerin kaydı',
            ),
          );
        }
        if (index == bloklar.length + 1) {
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
        final int i = index - 1;
        return Padding(
          padding: EdgeInsets.only(bottom: i == bloklar.length - 1 ? 0 : 10),
          child: LifeLogAgeBlock(block: bloklar[i], isCurrentAge: i == 0),
        );
      },
    );
  }
}

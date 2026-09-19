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

    return ListView(
      padding: const EdgeInsets.fromLTRB(18, 14, 18, 20),
      children: <Widget>[
        const SectionHeader(
          title: 'Hayat günlüğü',
          subtitle: 'Başından geçenlerin kaydı',
        ),
        const SizedBox(height: 10),
        LifeLogView(entries: state.log),
        const SizedBox(height: 14),
        Text(
          'Hazır olduğunda alttaki Yaş Al düğmesine bas; bir yaşın her '
          'şeyini bitirmek zorunda değilsin.',
          textAlign: TextAlign.center,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

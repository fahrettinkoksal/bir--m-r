import 'package:flutter/material.dart';

import '../../../domain/models/game_state.dart';
import '../../../domain/models/person.dart';
import '../../../state/game_scope.dart';
import '../../widgets/person_card.dart';
import '../../widgets/person_detail_sheet.dart';
import '../../widgets/section_scaffold.dart';

/// Aktiviteler ana menüsü (NAV-001).
///
/// İç içe menü mantığıyla kurulmuştur: ana ekranda kategoriler, kategorinin
/// içinde gerçek eylemler. **Yalnızca gerçekten çalışan şeyler gösterilir**;
/// spor salonu, berber ve seyahat gibi henüz yazılmamış alanlar sahte
/// düğme olarak konmaz.
class ActivitiesScreen extends StatefulWidget {
  const ActivitiesScreen({super.key, required this.onBack});

  final VoidCallback onBack;

  @override
  State<ActivitiesScreen> createState() => _ActivitiesScreenState();
}

class _ActivitiesScreenState extends State<ActivitiesScreen> {
  bool _sosyalAcik = false;

  /// Şu an gündelik hayatta gerçekten erişilebilen ve etkileşim kurulabilen
  /// kişiler.
  ///
  /// Yıllar önce tanışılmış bir ilkokul öğretmeni kayıtta kalır ama her gün
  /// görüşülen biri değildir; bu liste [GameState.isReachable] koşullarını
  /// kullanır. Yeniden karşılaşma ileride özel bir olayla gelecek.
  List<Person> _uygunKisiler(BuildContext context, GameState state) {
    return state.reachablePeople
        .where((Person p) =>
            GameScope.of(context).availableKindsFor(p).isNotEmpty)
        .toList(growable: false);
  }

  @override
  Widget build(BuildContext context) {
    final GameState state = GameScope.of(context).state!;
    final List<Person> kisiler = _uygunKisiler(context, state);

    if (_sosyalAcik) {
      return SectionScaffold(
        title: 'Birlikte vakit geçir',
        subtitle: 'Hayatında şu an gerçekten görüştüğün kişiler. '
            'Herkesle aynı etkileşimler açık değildir.',
        backLabel: 'Aktiviteler',
        onBack: () => setState(() => _sosyalAcik = false),
        children: <Widget>[
          for (final Person person in kisiler) ...<Widget>[
            PersonCard(
              person: person,
              playerAge: state.player.age,
              onTap: () =>
                  PersonDetailSheet.show(context, personId: person.id),
            ),
            const SizedBox(height: 10),
          ],
        ],
      );
    }

    return SectionScaffold(
      title: 'Aktiviteler',
      onBack: widget.onBack,
      children: <Widget>[
        if (kisiler.isNotEmpty)
          MenuRow(
            title: 'Birlikte vakit geçir',
            subtitle: 'Ailen ve arkadaşlarınla',
            icon: Icons.groups_2_outlined,
            trailingText: '${kisiler.length}',
            onTap: () => setState(() => _sosyalAcik = true),
          )
        else
          const InfoPanel(
            icon: Icons.groups_2_outlined,
            text: 'Şu an birlikte vakit geçirebileceğin kimse yok. '
                'Bu yaşta etkileşimler henüz açılmamış olabilir.',
          ),
        const SizedBox(height: 12),
        const InfoPanel(
          icon: Icons.construction_outlined,
          text: 'Spor salonu, berber ve seyahat gibi alanlar bu bölüme '
              'eklenecek. Henüz yazılmadıkları için düğme olarak '
              'gösterilmiyorlar.',
        ),
      ],
    );
  }
}

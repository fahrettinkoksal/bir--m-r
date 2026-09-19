import 'package:flutter/material.dart';

import '../../domain/models/game_state.dart';
import '../../domain/models/person.dart';
import '../../domain/models/relation.dart';
import '../../state/game_scope.dart';
import '../widgets/person_card.dart';
import '../widgets/person_detail_sheet.dart';
import '../widgets/section_header.dart';

/// Aile ekranı.
///
/// Kişiler bağ türüne göre gruplanır; **aynı evde yaşama** ise ayrı bir
/// rozetle gösterilir (D-014). Gruplamanın nihai hâli henüz kararlaştırılmadı
/// (`docs/PROTOTYPE_UI.md` §4).
class FamilyScreen extends StatelessWidget {
  const FamilyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final GameState state = GameScope.of(context).state!;
    final int playerAge = state.player.age;

    final List<Widget> children = <Widget>[];

    for (final RelationGroup group in RelationGroup.values) {
      final List<Person> people = state.byGroup(group)
        ..sort((Person a, Person b) => b.age.compareTo(a.age));
      // Hiç kişisi olmayan grup için boş bölüm gösterilmez.
      if (people.isEmpty) continue;

      children.addAll(<Widget>[
        SectionHeader(
          title: group.title,
          subtitle: _subtitleFor(group),
        ),
        const SizedBox(height: 10),
        for (final Person person in people) ...<Widget>[
          PersonCard(
            person: person,
            playerAge: playerAge,
            onTap: () => PersonDetailSheet.show(context, personId: person.id),
          ),
          const SizedBox(height: 10),
        ],
        const SizedBox(height: 12),
      ]);
    }

    if (state.pets.isNotEmpty) {
      children.addAll(<Widget>[
        const SectionHeader(title: 'Evcil hayvanlar'),
        const SizedBox(height: 10),
        for (final Pet pet in state.pets) ...<Widget>[
          _PetCard(pet: pet),
          const SizedBox(height: 10),
        ],
      ]);
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
      children: children,
    );
  }

  static String? _subtitleFor(RelationGroup group) {
    switch (group) {
      case RelationGroup.cekirdek:
        return null;
      case RelationGroup.genis:
        return 'Akraba olmak aynı evde yaşamayı gerektirmez.';
      case RelationGroup.arkadaslar:
        return 'Okulda ve hayatta tanıştığın kişiler; akraba değildir.';
      case RelationGroup.romantik:
        return 'İlişki geçmişi; akrabalık değildir.';
    }
  }
}

class _PetCard extends StatelessWidget {
  const _PetCard({required this.pet});

  final Pet pet;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: <Widget>[
            Icon(Icons.pets_outlined, color: theme.colorScheme.secondary),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(pet.name, style: theme.textTheme.titleMedium),
                  const SizedBox(height: 2),
                  Text(
                    pet.species,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

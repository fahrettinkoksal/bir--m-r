import 'package:flutter/material.dart';

import '../../../domain/models/education.dart';
import '../../../domain/models/game_state.dart';
import '../../../domain/models/person.dart';
import '../../../domain/models/relation.dart';
import '../../../state/game_scope.dart';
import '../../widgets/person_card.dart';
import '../../widgets/person_detail_sheet.dart';
import '../../widgets/section_scaffold.dart';

/// Okul / Meslek ana menüsü (NAV-001).
///
/// Aynı menü duruma göre iki yüz gösterir: oyuncu okuldayken **Okul**,
/// okulda değilken **Meslek**. İçerik küçük panellerle verilir; olmayan
/// sistem için sahte düğme konmaz.
class SchoolCareerScreen extends StatelessWidget {
  const SchoolCareerScreen({super.key, required this.onBack});

  final VoidCallback onBack;

  /// Menünün o anki başlığı; alt gezinme de bu adı kullanır.
  static String labelFor(GameState state) =>
      state.education.isStudent ? 'Okul' : 'Meslek';

  @override
  Widget build(BuildContext context) {
    final GameState state = GameScope.of(context).state!;
    final EducationState egitim = state.education;

    if (egitim.isStudent) {
      return _SchoolView(state: state, onBack: onBack);
    }
    return _CareerView(state: state, onBack: onBack);
  }
}

class _SchoolView extends StatelessWidget {
  const _SchoolView({required this.state, required this.onBack});

  final GameState state;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    final EducationState egitim = state.education;
    final List<Person> okulArkadaslari = state.people
        .where((Person p) => p.isAlive && p.relation == RelationType.arkadas)
        .toList(growable: false);

    return SectionScaffold(
      title: 'Okul',
      subtitle: egitim.label,
      onBack: onBack,
      children: <Widget>[
        _PanelCard(
          icon: Icons.school_outlined,
          title: egitim.level?.label ?? 'Okul',
          rows: <({String label, String value})>[
            (label: 'Sınıf', value: '${egitim.grade}. sınıf'),
            if (egitim.startedAtAge != null)
              (label: 'Başlangıç', value: '${egitim.startedAtAge} yaşında'),
            (
              label: 'Son sınıfa kalan',
              value: '${12 - (egitim.grade ?? 12)} yıl',
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (okulArkadaslari.isNotEmpty) ...<Widget>[
          const _PanelTitle('Okul arkadaşların'),
          const SizedBox(height: 8),
          for (final Person person in okulArkadaslari) ...<Widget>[
            PersonCard(
              person: person,
              playerAge: state.player.age,
              onTap: () =>
                  PersonDetailSheet.show(context, personId: person.id),
            ),
            const SizedBox(height: 10),
          ],
          const SizedBox(height: 4),
        ],
        const InfoPanel(
          icon: Icons.menu_book_outlined,
          text: 'Okul olayları yaş aldıkça ve gün içinde ilerledikçe '
              'karşına çıkar. Sınav, not ve diploma sistemi henüz yazılmadı.',
        ),
      ],
    );
  }
}

class _CareerView extends StatelessWidget {
  const _CareerView({required this.state, required this.onBack});

  final GameState state;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    final EducationState egitim = state.education;
    final bool okulOncesi = !egitim.finished && state.player.age < 6;

    return SectionScaffold(
      title: 'Meslek',
      subtitle: egitim.stageLabel(state.player.age),
      onBack: onBack,
      children: <Widget>[
        if (egitim.finished)
          _PanelCard(
            icon: Icons.workspace_premium_outlined,
            title: 'Eğitim geçmişi',
            rows: <({String label, String value})>[
              (label: 'Durum', value: 'Lise bitti'),
              if (egitim.startedAtAge != null)
                (label: 'Okula başlangıç', value: '${egitim.startedAtAge} yaşında'),
            ],
          )
        else
          _PanelCard(
            icon: Icons.child_care_outlined,
            title: okulOncesi ? 'Okul öncesi' : 'Okul dışı',
            rows: <({String label, String value})>[
              (label: 'Yaş', value: '${state.player.age}'),
              (label: 'Eğitim', value: egitim.label),
            ],
          ),
        const SizedBox(height: 12),
        InfoPanel(
          icon: Icons.work_outline,
          text: okulOncesi
              ? 'Okul çağına gelince bu bölüm okul bilgilerini gösterecek.'
              : 'İş arama, meslek ve kariyer sistemi henüz yazılmadı; '
                  'yazılmamış eylemler burada düğme olarak gösterilmiyor.',
        ),
      ],
    );
  }
}

class _PanelTitle extends StatelessWidget {
  const _PanelTitle(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Text(
      text,
      style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
    );
  }
}

/// Küçük bilgi paneli: başlık ve etiket/değer satırları.
class _PanelCard extends StatelessWidget {
  const _PanelCard({
    required this.icon,
    required this.title,
    required this.rows,
  });

  final IconData icon;
  final String title;
  final List<({String label, String value})> rows;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                Icon(icon, size: 20, color: theme.colorScheme.primary),
                const SizedBox(width: 10),
                Text(title, style: theme.textTheme.titleMedium),
              ],
            ),
            const SizedBox(height: 12),
            for (final ({String label, String value}) row in rows)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: <Widget>[
                    Expanded(
                      child: Text(
                        row.label,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                    Text(
                      row.value,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w700,
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

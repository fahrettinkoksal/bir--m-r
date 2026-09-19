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

/// Okul alt menüleri. Kişiler ayrı sayfalarda listelenir.
enum _SchoolPage { kok, sinifArkadaslari, ogretmenler, yakinArkadaslar }

class _SchoolView extends StatefulWidget {
  const _SchoolView({required this.state, required this.onBack});

  final GameState state;
  final VoidCallback onBack;

  @override
  State<_SchoolView> createState() => _SchoolViewState();
}

class _SchoolViewState extends State<_SchoolView> {
  _SchoolPage _page = _SchoolPage.kok;

  void _go(_SchoolPage page) => setState(() => _page = page);

  @override
  Widget build(BuildContext context) {
    final GameState state = widget.state;
    final EducationState egitim = state.education;

    final List<Person> sinifArkadaslari = state.currentClassmates;
    final List<Person> ogretmenler = state.currentTeachers;
    final List<Person> yakinArkadaslar = state.people
        .where((Person p) => p.isAlive && p.relation == RelationType.arkadas)
        .toList(growable: false);

    switch (_page) {
      case _SchoolPage.sinifArkadaslari:
        return _PeoplePage(
          title: 'Sınıf Arkadaşları',
          subtitle: egitim.level?.label,
          people: sinifArkadaslari,
          // Eski kademelerin sınıf arkadaşları silinmez; güncel sınıf
          // listesinde değil, ayrı başlık altında görünürler.
          past: state.pastSchoolPeople
              .where((Person p) => p.relation == RelationType.sinifArkadasi)
              .toList(growable: false),
          emptyText: 'Şu an kayıtlı bir sınıf arkadaşın yok.',
          playerAge: state.player.age,
          onBack: () => _go(_SchoolPage.kok),
        );
      case _SchoolPage.ogretmenler:
        return _PeoplePage(
          title: 'Öğretmenler',
          subtitle: egitim.level?.label,
          people: ogretmenler,
          past: state.pastSchoolPeople
              .where((Person p) => p.relation == RelationType.ogretmen)
              .toList(growable: false),
          emptyText: 'Bu kademede kayıtlı öğretmenin yok.',
          playerAge: state.player.age,
          onBack: () => _go(_SchoolPage.kok),
        );
      case _SchoolPage.yakinArkadaslar:
        return _PeoplePage(
          title: 'Yakın Arkadaşların',
          subtitle: 'Okulda tanışıp yakınlaştığın kişiler',
          people: yakinArkadaslar,
          past: const <Person>[],
          emptyText: 'Henüz yakın arkadaşlık kurmadın. Sınıf arkadaşı olmak '
              'tek başına yakın arkadaşlık sayılmaz.',
          playerAge: state.player.age,
          onBack: () => _go(_SchoolPage.kok),
        );
      case _SchoolPage.kok:
        break;
    }

    return SectionScaffold(
      title: 'Okul',
      subtitle: egitim.label,
      onBack: widget.onBack,
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
        MenuRow(
          title: 'Sınıf Arkadaşları',
          subtitle: 'Bu kademede tanıdığın kişiler',
          icon: Icons.groups_outlined,
          trailingText: '${sinifArkadaslari.length}',
          onTap: () => _go(_SchoolPage.sinifArkadaslari),
        ),
        const SizedBox(height: 10),
        MenuRow(
          title: 'Öğretmenler',
          subtitle: 'Dersine girenler',
          icon: Icons.record_voice_over_outlined,
          trailingText: '${ogretmenler.length}',
          onTap: () => _go(_SchoolPage.ogretmenler),
        ),
        const SizedBox(height: 10),
        MenuRow(
          title: 'Yakın Arkadaşların',
          subtitle: 'Tanışıklıktan öteye geçenler',
          icon: Icons.favorite_outline,
          trailingText: '${yakinArkadaslar.length}',
          onTap: () => _go(_SchoolPage.yakinArkadaslar),
        ),
        const SizedBox(height: 12),
        const InfoPanel(
          icon: Icons.menu_book_outlined,
          text: 'Okul olayları yaş aldıkça ve gün içinde ilerledikçe '
              'karşına çıkar. Sınav, not ve diploma sistemi henüz yazılmadı.',
        ),
      ],
    );
  }
}

/// Kişi listesi sayfası: güncel kişiler ve geçmiş kademelerden tanıdıklar.
class _PeoplePage extends StatelessWidget {
  const _PeoplePage({
    required this.title,
    required this.subtitle,
    required this.people,
    required this.past,
    required this.emptyText,
    required this.playerAge,
    required this.onBack,
  });

  final String title;
  final String? subtitle;
  final List<Person> people;
  final List<Person> past;
  final String emptyText;
  final int playerAge;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return SectionScaffold(
      title: title,
      subtitle: subtitle,
      onBack: onBack,
      backLabel: 'Okul',
      children: <Widget>[
        if (people.isEmpty)
          InfoPanel(icon: Icons.info_outline, text: emptyText)
        else
          for (final Person person in people) ...<Widget>[
            PersonCard(
              person: person,
              playerAge: playerAge,
              onTap: () => PersonDetailSheet.show(context, personId: person.id),
            ),
            const SizedBox(height: 10),
          ],
        if (past.isNotEmpty) ...<Widget>[
          const SizedBox(height: 10),
          const _PanelTitle('Geçmiş yıllardan tanıdıkların'),
          const SizedBox(height: 4),
          const InfoPanel(
            icon: Icons.history,
            text: 'Kademe değişse de tanıdığın kişiler kaybolmaz; '
                'güncel sınıfında olmadıkları için ayrı listelenirler.',
          ),
          const SizedBox(height: 10),
          for (final Person person in past) ...<Widget>[
            PersonCard(
              person: person,
              playerAge: playerAge,
              onTap: () => PersonDetailSheet.show(context, personId: person.id),
            ),
            const SizedBox(height: 10),
          ],
        ],
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

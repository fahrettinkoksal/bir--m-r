import 'package:flutter/material.dart';

import '../../../domain/career/retirement.dart';
import '../../../domain/models/education.dart';
import '../../../domain/models/interaction.dart';
import '../../../domain/models/game_state.dart';
import '../../../domain/models/person.dart';
import '../../../state/game_controller.dart';
import '../../../state/game_scope.dart';
import '../../theme/bir_omur_theme.dart';
import '../../widgets/person_card.dart';
import '../../widgets/person_detail_sheet.dart';
import '../../widgets/interview_sheet.dart';
import '../../widgets/section_scaffold.dart';
import 'education_career_pages.dart';
import '../../../text/turkish_text.dart';

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
/// Okul ekranının alt sayfaları.
///
/// Burada yalnızca **okulla ilgili** gruplar bulunur. Arkadaşlık düzeyi ve
/// özel ilişkiler İlişkiler menüsünden yönetilir.
enum _SchoolPage { kok, sinifArkadaslari, ogretmenler, liseTercihi }

class _SchoolView extends StatefulWidget {
  const _SchoolView({required this.state, required this.onBack});

  final GameState state;
  final VoidCallback onBack;

  @override
  State<_SchoolView> createState() => _SchoolViewState();
}

class _SchoolViewState extends State<_SchoolView> {
  _SchoolPage _page = _SchoolPage.kok;

  /// Son eylemin ekranda gösterilen sonucu (ders çalışma gibi).
  String? _sonuc;

  void _go(_SchoolPage page) => setState(() {
        _page = page;
        _sonuc = null;
      });

  @override
  Widget build(BuildContext context) {
    final GameState state = widget.state;
    final EducationState egitim = state.education;

    final List<Person> sinifArkadaslari = state.currentClassmates;
    final List<Person> ogretmenler = state.currentTeachers;
    switch (_page) {
      case _SchoolPage.sinifArkadaslari:
        return _PeoplePage(
          title: 'Sınıf Arkadaşları',
          subtitle: egitim.level?.label,
          people: sinifArkadaslari,
          // Eski kademelerin sınıf arkadaşları silinmez; güncel sınıf
          // listesinde değil, ayrı başlık altında görünürler. Filtre okul
          // bağına bakar: yakın arkadaş olmuş biri de burada kalır.
          past: state.pastSchoolPeople
              .where((Person p) => p.schoolTie == SchoolTie.sinifArkadasi)
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
              .where((Person p) => p.schoolTie == SchoolTie.ogretmen)
              .toList(growable: false),
          emptyText: 'Bu kademede kayıtlı öğretmenin yok.',
          playerAge: state.player.age,
          onBack: () => _go(_SchoolPage.kok),
        );
      case _SchoolPage.liseTercihi:
        return TrackChoicePage(onBack: () => _go(_SchoolPage.kok));
      case _SchoolPage.kok:
        break;
    }

    return SectionScaffold(
      icon: Icons.school_rounded,
      title: 'Okul',
      accent: BirOmurAccents.mavi,
      subtitle: egitim.label,
      onBack: widget.onBack,
      children: <Widget>[
        _PanelCard(
          icon: Icons.school_outlined,
          title: egitim.level?.label ?? 'Okul',
          rows: <({String label, String value})>[
            (label: 'Sınıf', value: '${egitim.grade}. sınıf'),
            // Not ortalaması yalnızca gerçekten oluştuysa gösterilir
            // (Paket 13); uydurma not yazılmaz.
            if (egitim.gradeAverage != null)
              (label: 'Not ortalaman', value: '${egitim.gradeAverage}'),
            if (egitim.repeatedYears > 0)
              (
                label: 'Sınıf tekrarı',
                value: '${egitim.repeatedYears} kez',
              ),
            if (egitim.scholarshipSinceAge != null)
              (
                label: 'Burs',
                value: '${egitim.scholarshipSinceAge} yaşından beri',
              ),
            if (egitim.trackInfo != null)
              (label: 'Alan', value: egitim.trackInfo!.label),
            if (egitim.placementScore != null)
              (label: 'Yerleştirme puanı', value: '${egitim.placementScore}'),
            if (egitim.startedAtAge != null)
              (label: 'Başlangıç', value: '${egitim.startedAtAge} yaşında'),
            (
              label: 'Son sınıfa kalan',
              value: '${12 - (egitim.grade ?? 12)} yıl',
            ),
          ],
        ),
        const SizedBox(height: 12),
        // Ders çalışmak gerçek bir eylem: not ortalamasını ve zekâyı
        // değiştirir, biraz da yorar (Paket 13).
        Builder(
          builder: (BuildContext context) {
            final GameController controller = GameScope.of(context);
            final InteractionAvailability uygunluk =
                controller.studyAvailability();
            if (!uygunluk.isAllowed) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: InfoPanel(
                  icon: Icons.menu_book_outlined,
                  text: 'Ders çalışamazsın: ${uygunluk.reason}',
                ),
              );
            }
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: MenuRow(
                key: const Key('school_study_row'),
                title: 'Ders çalış',
                subtitle: 'Not ortalamanı yükseltir, biraz yorar',
                icon: Icons.menu_book_outlined,
                accent: BirOmurAccents.yesil,
                onTap: () {
                  final String? metin = controller.study();
                  setState(() => _sonuc = metin);
                },
              ),
            );
          },
        ),
        // Lise alanı seçimi bekliyorsa en üstte durur.
        if (egitim.awaitingTrackChoice) ...<Widget>[
          MenuRow(
            title: 'Lise alanını seç',
            subtitle: 'Yerleştirme puanın: ${egitim.placementScore ?? 0}',
            icon: Icons.alt_route_outlined,
            accent: BirOmurAccents.mor,
            onTap: () => _go(_SchoolPage.liseTercihi),
          ),
          const SizedBox(height: 10),
        ],
        MenuRow(
          title: 'Sınıf Arkadaşları',
          subtitle: 'Şu an aynı sınıfta olduğun kişiler',
          icon: Icons.groups_outlined,
          accent: BirOmurAccents.cini,
          trailingText: '${sinifArkadaslari.length}',
          onTap: () => _go(_SchoolPage.sinifArkadaslari),
        ),
        const SizedBox(height: 10),
        MenuRow(
          title: 'Öğretmenler',
          subtitle: 'Dersine girenler',
          icon: Icons.record_voice_over_outlined,
          accent: BirOmurAccents.pirinc,
          trailingText: '${ogretmenler.length}',
          onTap: () => _go(_SchoolPage.ogretmenler),
        ),
        if (_sonuc != null) ...<Widget>[
          InfoPanel(icon: Icons.info_outline, text: _sonuc!),
          const SizedBox(height: 10),
        ],
        const SizedBox(height: 12),
        const InfoPanel(
          icon: Icons.menu_book_outlined,
          text: 'Okul olayları yaş aldıkça ve gün içinde ilerledikçe '
              'karşına çıkar. Arkadaşlık düzeyini İlişkiler bölümünden '
              'takip edebilirsin. Sınav, not ve diploma sistemi henüz '
              'yazılmadı.',
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
      icon: Icons.groups_rounded,
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

/// Meslek ekranının alt sayfaları.
enum _CareerPage { kok, mezuniyetSonrasi, isArama, kariyerGecmisi }

class _CareerView extends StatefulWidget {
  const _CareerView({required this.state, required this.onBack});

  final GameState state;
  final VoidCallback onBack;

  @override
  State<_CareerView> createState() => _CareerViewState();
}

class _CareerViewState extends State<_CareerView> {
  _CareerPage _page = _CareerPage.kok;
  String? _sonuc;

  void _go(_CareerPage page) => setState(() {
        _page = page;
        _sonuc = null;
      });

  @override
  Widget build(BuildContext context) {
    final GameState state = widget.state;
    final EducationState egitim = state.education;
    final bool okulOncesi = !egitim.finished && state.player.age < 6;

    switch (_page) {
      case _CareerPage.mezuniyetSonrasi:
        return AfterSchoolPage(onBack: () => _go(_CareerPage.kok));
      case _CareerPage.isArama:
        return JobSearchPage(onBack: () => _go(_CareerPage.kok));
      case _CareerPage.kariyerGecmisi:
        return CareerHistoryPage(onBack: () => _go(_CareerPage.kok));
      case _CareerPage.kok:
        break;
    }

    final bool isAranabilir = egitim.finished || egitim.universityFinished;

    return SectionScaffold(
      icon: Icons.work_rounded,
      accent: BirOmurAccents.mor,
      title: 'Meslek',
      subtitle: egitim.stageLabel(state.player.age),
      onBack: widget.onBack,
      children: <Widget>[
        // Emekliyse çalışma paneli yerine emeklilik paneli gösterilir.
        if (state.career.isRetired)
          _PanelCard(
            icon: Icons.self_improvement_outlined,
            accent: BirOmurAccents.cini,
            title: 'Emeklilik',
            rows: <({String label, String value})>[
              (
                label: 'Emekli olduğun yaş',
                value: '${state.career.retiredAtAge}',
              ),
              (
                label: 'Yıllık aylığın',
                value: trMoney(state.career.pension ?? 0),
              ),
              (
                label: 'Toplam çalışma',
                value: '${state.career.totalWorkYears(state.player.age)} yıl',
              ),
              (label: 'Cüzdan', value: state.player.walletLabel),
            ],
          )
        else if (state.career.isEmployed)
          _PanelCard(
            icon: Icons.badge_outlined,
            accent: BirOmurAccents.mor,
            // Görev adı seviyeye göre değişir: terfi eden oyuncu
            // ekranda da kıdemli görünür (Paket 9).
            title: state.career.title,
            rows: <({String label, String value})>[
              if (state.career.title != state.career.label)
                (label: 'Meslek', value: state.career.label),
              (
                label: 'Yıllık maaş',
                value: trMoney(state.career.yearlySalary),
              ),
              if (state.career.startedAtAge != null)
                (
                  label: 'Başlangıç',
                  value: '${state.career.startedAtAge} yaşında',
                ),
              if (state.career.startedAtAge != null)
                (
                  label: 'Bu işteki süren',
                  value: '${state.career.yearsInJob(state.player.age)} yıl',
                ),
              // İşin şehri yalnızca gerçekten biliniyorsa yazılır; şehir
              // değişince işe kendiliğinden son verilmez (Q-065).
              if (state.career.jobCity != null)
                (
                  label: 'İşin şehri',
                  value: state.career.isInAnotherCity(state.player.currentCity)
                      ? '${state.career.jobCity} (başka şehirde)'
                      : state.career.jobCity!,
                ),
              (label: 'Cüzdan', value: state.player.walletLabel),
            ],
          )
        else if (egitim.finished || egitim.universityFinished)
          _PanelCard(
            icon: Icons.workspace_premium_outlined,
            accent: BirOmurAccents.pirinc,
            title: 'Eğitim geçmişi',
            rows: <({String label, String value})>[
              (label: 'Durum', value: egitim.label),
              if (egitim.trackInfo != null)
                (label: 'Lise alanı', value: egitim.trackInfo!.label),
              if (egitim.placementScore != null)
                (
                  label: 'Lise yerleştirme puanı',
                  value: '${egitim.placementScore}',
                ),
              if (egitim.universityExamScore != null)
                (
                  label: 'Üniversite sınav puanı',
                  value: '${egitim.universityExamScore}',
                ),
              if (egitim.program != null)
                (
                  label: egitim.universityFinished
                      ? 'Mezun olduğu bölüm'
                      : 'Okuduğu bölüm',
                  value: egitim.program!.name,
                ),
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
        if (egitim.awaitingAfterSchoolChoice) ...<Widget>[
          MenuRow(
            title: 'Mezuniyet sonrası',
            subtitle: 'Üniversiteye başvur veya iş hayatına gir',
            icon: Icons.alt_route_outlined,
            accent: BirOmurAccents.mavi,
            onTap: () => _go(_CareerPage.mezuniyetSonrasi),
          ),
          const SizedBox(height: 10),
        ],
        // Cevap bekleyen mülakat varsa en üstte.
        if (state.hasPendingInterview) ...<Widget>[
          MenuRow(
            title: 'Mülakata devam et',
            subtitle: state.pendingInterview?.job?.name ?? '',
            icon: Icons.record_voice_over_outlined,
            accent: BirOmurAccents.pirinc,
            onTap: () => InterviewSheet.show(context),
          ),
          const SizedBox(height: 10),
        ],
        if (isAranabilir && !state.career.isRetired) ...<Widget>[
          MenuRow(
            title: state.career.isEmployed ? 'İş değiştir' : 'İş ara',
            subtitle: state.career.isEmployed
                ? 'Önce mevcut işinden ayrılman gerekir'
                : 'Koşullarını sağladığın işler',
            icon: Icons.work_outline,
            accent: BirOmurAccents.mor,
            onTap: () => _go(_CareerPage.isArama),
          ),
          const SizedBox(height: 10),
        ],
        // Zam ve terfi gerçek birer etkileşimdir; koşulu sağlanmıyorsa
        // düğme yerine gerekçe gösterilir (sahte düğme yok).
        if (state.career.isEmployed && !state.career.isRetired) ...<Widget>[
          Builder(
            builder: (BuildContext context) {
              final InteractionAvailability zam =
                  GameScope.of(context).raiseAvailability();
              if (!zam.isAllowed) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: InfoPanel(
                    icon: Icons.trending_up_outlined,
                    text: 'Zam isteyemezsin: ${zam.reason}',
                  ),
                );
              }
              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: MenuRow(
                  key: const Key('career_raise_row'),
                  title: 'Zam iste',
                  subtitle: 'Yöneticinle maaşını konuş',
                  icon: Icons.trending_up_outlined,
                  accent: BirOmurAccents.yesil,
                  onTap: () {
                    final String? metin = GameScope.of(context).askForRaise();
                    setState(() => _sonuc = metin);
                  },
                ),
              );
            },
          ),
          Builder(
            builder: (BuildContext context) {
              final InteractionAvailability terfi =
                  GameScope.of(context).promotionAvailability();
              if (!terfi.isAllowed) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: InfoPanel(
                    icon: Icons.military_tech_outlined,
                    text: 'Terfi isteyemezsin: ${terfi.reason}',
                  ),
                );
              }
              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: MenuRow(
                  key: const Key('career_promotion_row'),
                  title: 'Terfi iste',
                  subtitle: 'Bir üst göreve geçmeyi konuş',
                  icon: Icons.military_tech_outlined,
                  accent: BirOmurAccents.pirinc,
                  onTap: () {
                    final String? metin =
                        GameScope.of(context).askForPromotion();
                    setState(() => _sonuc = metin);
                  },
                ),
              );
            },
          ),
        ],
        // Emeklilik (Paket 12): koşul dolmadıysa satır yerine gerekçe
        // gösterilmez — menü gereksiz uyarıyla dolmasın diye yalnızca
        // uygun yaşta görünür.
        if (!state.career.isRetired &&
            state.player.age >= Retirement.prototypeOnlyEarlyAge) ...<Widget>[
          Builder(
            builder: (BuildContext context) {
              final GameController controller = GameScope.of(context);
              final int aylik = controller.pensionPreview();
              final bool erken =
                  state.player.age < Retirement.prototypeOnlyFullAge;
              return MenuRow(
                key: const Key('career_retire_row'),
                title: erken ? 'Erken emekli ol' : 'Emekli ol',
                subtitle: 'Yıllık aylığın ${trMoney(aylik)} olur'
                    '${erken ? ' (erken ayrılış kesintisiyle)' : ''}',
                icon: Icons.self_improvement_outlined,
                accent: BirOmurAccents.cini,
                onTap: () {
                  final String? metin = controller.retire();
                  setState(() => _sonuc = metin);
                },
              );
            },
          ),
          const SizedBox(height: 10),
        ],
        // Kariyer geçmişi: eski işler silinmez.
        if (state.career.allEntries().isNotEmpty) ...<Widget>[
          MenuRow(
            key: const Key('career_history_row'),
            title: 'Kariyer geçmişi',
            subtitle: '${state.career.allEntries().length} çalışma kaydı',
            icon: Icons.history_outlined,
            accent: BirOmurAccents.cini,
            onTap: () => _go(_CareerPage.kariyerGecmisi),
          ),
          const SizedBox(height: 10),
        ],
        if (state.career.isEmployed && !state.career.isRetired) ...<Widget>[
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () {
                final String? metin = GameScope.of(context).quitJob()?.text;
                setState(() => _sonuc = metin);
              },
              child: const Text('İşten ayrıl'),
            ),
          ),
          const SizedBox(height: 10),
        ],
        if (_sonuc != null) ...<Widget>[
          InfoPanel(icon: Icons.info_outline, text: _sonuc!),
          const SizedBox(height: 10),
        ],
        if (!isAranabilir)
          InfoPanel(
            icon: Icons.work_outline,
            text: okulOncesi
                ? 'Okul çağına gelince bu bölüm okul bilgilerini gösterecek.'
                : 'İş arama liseyi bitirdikten sonra açılır.',
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
    this.accent = BirOmurAccents.mavi,
  });

  final IconData icon;
  final String title;
  final List<({String label, String value})> rows;

  /// Panelin rengi; bulunduğu bölümün rengiyle aynı olur.
  final BirOmurAccent accent;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    // Bilgi panelleri de menü satırlarıyla aynı görsel dili konuşur.
    return Container(
      decoration: panelDecoration(context, radius: 22),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                AccentIconTile(icon: icon, accent: accent, size: 38),
                const SizedBox(width: 12),
                // Unvan uzun olabilir (ör. "Kıdemli mağaza çalışanı");
                // satır taşmasın diye sarılır.
                Expanded(
                  child: Text(title, style: theme.textTheme.titleMedium),
                ),
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
                    const SizedBox(width: 12),
                    Flexible(
                      child: Text(
                        row.value,
                        textAlign: TextAlign.right,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
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

import 'package:flutter/material.dart';

import '../../../data/tour_catalog.dart';
import '../../../domain/life/life_end_choice.dart';
import '../../widgets/kilim_divider.dart';
import '../../../domain/economy/housing.dart';

import '../../../data/activity_catalog.dart';
import '../../../domain/activities/activity_engine.dart';
import '../../../domain/models/book_progress.dart';
import '../../../domain/models/game_state.dart';
import '../../../domain/models/interaction.dart';
import '../../../state/game_controller.dart';
import '../../../domain/activities/travel.dart';
import '../../../domain/models/trip.dart';
import '../../../state/game_scope.dart';
import '../../theme/bir_omur_theme.dart';
import '../../../domain/interaction/adoption.dart';
import '../../../domain/interaction/marriage_engine.dart';
import '../../../domain/models/person.dart';
import '../../widgets/effect_chips.dart';
import '../../widgets/person_card.dart';
import '../../widgets/person_detail_sheet.dart';
import '../../widgets/section_scaffold.dart';
import '../../../text/turkish_text.dart';

/// Eylem listesi olan bir mekân sayfası (berber, spor salonu, sağlık
/// merkezi, eğlence, kurslar).
///
/// Yalnızca gerçekten yapılabilen eylemler düğme olur; kapalı olanlar
/// gerekçesiyle gösterilir.
class VenuePage extends StatefulWidget {
  const VenuePage({
    super.key,
    required this.venue,
    required this.onBack,
    this.extraRows = const <Widget>[],
    this.customActions = const <String, VoidCallback>{},
  });

  final ActivityVenue venue;
  final VoidCallback onBack;

  /// Kendi ekranı olan eylemler: kimlik → o ekrana götüren geri çağrı.
  ///
  /// Göz muayenesi böyle çalışır (D-076): düğme eylemi doğrudan
  /// uygulamak yerine mini oyunu açar. Mekân sayfası genel kalır.
  final Map<String, VoidCallback> customActions;

  /// Mekânın kendi eylemlerinin **üstünde** gösterilen ek satırlar.
  ///
  /// Spor salonunda dövüş sanatları bölümüne geçiş böyle konur (Paket 32);
  /// mekân sayfası genel kalır.
  final List<Widget> extraRows;

  @override
  State<VenuePage> createState() => _VenuePageState();
}

class _VenuePageState extends State<VenuePage> {
  ActivityOutcome? _sonuc;

  /// Eylem kimliği → birlikte gidilecek kişinin kimliği.
  ///
  /// Boşsa yalnız gidilir. Seçim yalnızca ekranda tutulur; kayda girmez.
  final Map<String, String> _kiminle = <String, String>{};

  @override
  Widget build(BuildContext context) {
    final GameController controller = GameScope.of(context);
    final GameState state = controller.state!;
    final List<ActivityAction> tumEylemler = actionsAt(widget.venue);

    return SectionScaffold(
      icon: widget.venue.icon,
      accent: accentForVenue(widget.venue),
      title: widget.venue.label,
      subtitle: 'Cüzdanında ${state.player.walletLabel} var.',
      backLabel: 'Aktiviteler',
      onBack: widget.onBack,
      children: <Widget>[
        for (final Widget row in widget.extraRows) ...<Widget>[
          row,
          const SizedBox(height: 10),
        ],
        for (final ActivityAction eylem in tumEylemler) ...<Widget>[
          Builder(
            builder: (BuildContext context) {
              // Birlikte gidilebilecek kişiler gerçek kayıttan okunur;
              // kimse uydurulmaz (Paket 41).
              final List<Person> kisiler =
                  controller.outingCompanions(eylem);
              final String? secili = _kiminle[eylem.id];
              final Person? yoldas = kisiler
                  .where((Person p) => p.id == secili)
                  .firstOrNull;
              return _ActionCard(
                action: eylem,
                availability: controller.activityAvailability(eylem),
                companions: kisiler,
                selected: yoldas,
                playerAge: state.player.age,
                onSelect: (Person? p) => setState(() {
                  if (p == null) {
                    _kiminle.remove(eylem.id);
                  } else {
                    _kiminle[eylem.id] = p.id;
                  }
                }),
                onTap: () {
                  final VoidCallback? ozel =
                      widget.customActions[eylem.id];
                  if (ozel != null) {
                    ozel();
                    return;
                  }
                  final ActivityOutcome? outcome =
                      controller.performActivity(eylem, companion: yoldas);
                  setState(() => _sonuc = outcome);
                },
              );
            },
          ),
          const SizedBox(height: 10),
        ],
        if (_sonuc != null) ...<Widget>[
          const SizedBox(height: 4),
          OutcomeCard(outcome: _sonuc!),
        ],
      ],
    );
  }
}

/// Mekânın rengi. Menüdeki satır ile sayfanın başlığı aynı rengi taşır.
BirOmurAccent accentForVenue(ActivityVenue venue) {
  switch (venue) {
    case ActivityVenue.berber:
      return BirOmurAccents.mor;
    case ActivityVenue.sporSalonu:
      return BirOmurAccents.yesil;
    case ActivityVenue.kutuphane:
      return BirOmurAccents.mavi;
    case ActivityVenue.saglikMerkezi:
      return BirOmurAccents.nar;
    case ActivityVenue.eglence:
      return BirOmurAccents.turuncu;
    case ActivityVenue.kurs:
      return BirOmurAccents.mor;
    case ActivityVenue.falTarot:
      return BirOmurAccents.gul;
    case ActivityVenue.estetik:
      return BirOmurAccents.gul;
    case ActivityVenue.cezaevi:
      return BirOmurAccents.nar;
  }
}

class _ActionCard extends StatelessWidget {
  const _ActionCard({
    required this.action,
    required this.availability,
    required this.onTap,
    this.companions = const <Person>[],
    this.selected,
    this.playerAge = 0,
    this.onSelect,
  });

  final ActivityAction action;
  final InteractionAvailability availability;
  final VoidCallback onTap;

  /// Birlikte gidilebilecek gerçek kişiler; boşsa seçim hiç gösterilmez.
  final List<Person> companions;
  final Person? selected;
  final int playerAge;
  final void Function(Person?)? onSelect;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final bool acik = availability.isAllowed;
    final BirOmurAccent renk = accentForVenue(action.venue);
    return Container(
      decoration: panelDecoration(context, radius: 20),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                AccentIconTile(icon: action.icon, accent: renk, size: 38),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(action.label, style: theme.textTheme.titleMedium),
                ),
                Text(
                  action.cost == 0 ? 'Ücretsiz' : trMoney(action.cost),
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              action.description,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            // Kiminle gidileceği (Paket 41). Yalnızca gerçekten
            // katılabilecek kişiler listelenir; kimse yoksa bölüm hiç
            // görünmez, sahte düğme olmaz.
            if (companions.isNotEmpty && onSelect != null) ...<Widget>[
              const SizedBox(height: 10),
              Text(
                'Kiminle?',
                style: theme.textTheme.labelMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 6),
              Wrap(
                spacing: 8,
                runSpacing: 6,
                children: <Widget>[
                  ChoiceChip(
                    key: Key('birlikte_${action.id}_yalniz'),
                    label: const Text('Yalnız'),
                    selected: selected == null,
                    onSelected: (_) => onSelect!(null),
                  ),
                  for (final Person kisi in companions)
                    ChoiceChip(
                      key: Key('birlikte_${action.id}_${kisi.id}'),
                      label: Text(
                        '${kisi.firstName} · '
                        '${trLower(kisi.labelFor(playerAge))}',
                      ),
                      selected: selected?.id == kisi.id,
                      onSelected: (_) => onSelect!(kisi),
                    ),
                ],
              ),
            ],
            const SizedBox(height: 10),
            // Dar ekranda gerekçe ile düğme yan yana sıkışmasın diye
            // gerekçe kendi satırında durur.
            if (!acik)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(
                  availability.reason ?? '',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            Align(
              alignment: Alignment.centerRight,
              child: FilledButton.tonal(
                key: Key('aktivite_${action.id}_yap'),
                onPressed: acik ? onTap : null,
                child: Text(acik ? 'Yap' : 'Şu an kapalı'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Kütüphane: yaşa uygun kitaplar ve okuma ilerlemesi.
class LibraryPage extends StatefulWidget {
  const LibraryPage({super.key, required this.onBack});

  final VoidCallback onBack;

  @override
  State<LibraryPage> createState() => _LibraryPageState();
}

class _LibraryPageState extends State<LibraryPage> {
  BookInfo? _acikKitap;
  ActivityOutcome? _sonuc;

  @override
  Widget build(BuildContext context) {
    final GameController controller = GameScope.of(context);
    final GameState state = controller.state!;

    final BookInfo? acik = _acikKitap;
    if (acik != null) {
      return _ReaderView(
        book: acik,
        progress: state.bookProgress(acik.id),
        outcome: _sonuc,
        onTurnPage: () {
          final ActivityOutcome? outcome = controller.turnBookPage(acik);
          setState(() => _sonuc = outcome);
        },
        onBack: () => setState(() {
          _acikKitap = null;
          _sonuc = null;
        }),
      );
    }

    final List<BookInfo> kitaplar = controller.availableBooks();

    return SectionScaffold(
      icon: Icons.local_library_rounded,
      accent: BirOmurAccents.mavi,
      title: 'Kütüphane',
      subtitle: 'Yaşına uygun ${kitaplar.length} kitap var.',
      backLabel: 'Aktiviteler',
      onBack: widget.onBack,
      children: <Widget>[
        if (kitaplar.isEmpty)
          const InfoPanel(
            icon: Icons.menu_book_outlined,
            text: 'Bu yaşta okuyabileceğin bir kitap yok.',
          ),
        for (final BookInfo kitap in kitaplar) ...<Widget>[
          _BookCard(
            book: kitap,
            progress: state.bookProgress(kitap.id),
            onOpen: () {
              controller.openBook(kitap);
              setState(() {
                _acikKitap = kitap;
                _sonuc = null;
              });
            },
          ),
          const SizedBox(height: 10),
        ],
      ],
    );
  }
}

class _BookCard extends StatelessWidget {
  const _BookCard({
    required this.book,
    required this.progress,
    required this.onOpen,
  });

  final BookInfo book;
  final BookProgress? progress;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final bool bitti = progress?.finished ?? false;
    return Card(
      child: InkWell(
        onTap: onOpen,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Row(
                children: <Widget>[
                  Icon(
                    bitti ? Icons.task_alt_outlined : Icons.menu_book_outlined,
                    color: theme.colorScheme.secondary,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(book.title, style: theme.textTheme.titleMedium),
                        const SizedBox(height: 2),
                        Text(
                          '${book.author} · ${book.kind.label} · '
                          '${book.pages} sayfa',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              if (progress != null) ...<Widget>[
                const SizedBox(height: 10),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    value: progress!.ratio,
                    minHeight: 6,
                    backgroundColor:
                        theme.colorScheme.outlineVariant.withValues(alpha: 0.4),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  bitti
                      ? 'Bitirdin.'
                      : '${progress!.pagesRead} / ${book.pages} sayfa',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Kitap okuma ekranı.
///
/// Sayfalarda gerçek metin yoktur: telifli içerik kullanılmaz, sayfa soyut
/// satır çizgileriyle gösterilir.
class _ReaderView extends StatelessWidget {
  const _ReaderView({
    required this.book,
    required this.progress,
    required this.outcome,
    required this.onTurnPage,
    required this.onBack,
  });

  final BookInfo book;
  final BookProgress? progress;
  final ActivityOutcome? outcome;
  final VoidCallback onTurnPage;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final int okunan = progress?.pagesRead ?? 0;
    final bool bitti = progress?.finished ?? false;

    return SectionScaffold(
      icon: Icons.menu_book_rounded,
      accent: BirOmurAccents.mavi,
      title: book.title,
      subtitle: '${book.author} · ${book.kind.label}',
      backLabel: 'Kütüphane',
      onBack: onBack,
      children: <Widget>[
        GestureDetector(
          key: const Key('book_page'),
          onTap: bitti ? null : onTurnPage,
          child: Container(
            height: 320,
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: theme.colorScheme.outlineVariant.withValues(alpha: 0.7),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  bitti ? 'Son sayfa' : 'Sayfa ${okunan + 1}',
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 14),
                Expanded(child: _PageLines(seed: okunan)),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: LinearProgressIndicator(
            value: progress?.ratio ?? 0,
            minHeight: 8,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          bitti
              ? 'Kitabı bitirdin. Yeniden okumak yeni bir kazanç vermez.'
              : 'Sayfaya dokunarak ilerle. $okunan / ${book.pages}',
          textAlign: TextAlign.center,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        if (outcome != null && outcome!.effects.isNotEmpty) ...<Widget>[
          const SizedBox(height: 14),
          EffectChips(effects: outcome!.effects),
        ],
      ],
    );
  }
}

/// Sayfanın soyut satırları. Telifli metin yerine çizgi kullanılır.
class _PageLines extends StatelessWidget {
  const _PageLines({required this.seed});

  final int seed;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final Color renk = theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.35);
    // Satır uzunlukları sayfadan sayfaya değişsin diye basit bir dizi.
    const List<double> oranlar = <double>[
      1, 0.95, 0.98, 0.9, 1, 0.93, 0.85, 0.97, 0.92, 0.6,
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        for (int i = 0; i < oranlar.length; i++) ...<Widget>[
          FractionallySizedBox(
            widthFactor: oranlar[(i + seed) % oranlar.length],
            child: Container(
              height: 7,
              decoration: BoxDecoration(
                color: renk,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
          const SizedBox(height: 12),
        ],
      ],
    );
  }
}

class OutcomeCard extends StatelessWidget {
  const OutcomeCard({super.key, required this.outcome});

  final ActivityOutcome outcome;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final Color accent = outcome.applied
        ? theme.colorScheme.secondary
        : theme.colorScheme.error;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: accent.withValues(alpha: 0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(outcome.text, style: theme.textTheme.bodyMedium),
          if (outcome.effects.isNotEmpty) ...<Widget>[
            const SizedBox(height: 12),
            EffectChips(effects: outcome.effects),
          ],
        ],
      ),
    );
  }
}

/// **Evlat Edinme** sayfası (D-049).
///
/// Başvuru koşulları açıkça yazılır; koşul sağlanmıyorsa gerekçe gösterilir
/// ve çalışmayan düğme konmaz (D-038). Başvurunun sonucu — olumlu ya da
/// olumsuz — gerçek bir sonuçtur ve kayda girer.
class AdoptionPage extends StatefulWidget {
  const AdoptionPage({super.key, required this.onBack});

  final VoidCallback onBack;

  @override
  State<AdoptionPage> createState() => _AdoptionPageState();
}

class _AdoptionPageState extends State<AdoptionPage> {
  String? _sonuc;
  bool _olumlu = false;

  Future<void> _basvur() async {
    final bool? onay = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        title: const Text('Evlat edinme başvurusu'),
        content: Text(
          'Başvuru ve hazırlık masrafı ${trMoney(Adoption.prototypeOnlyCost)}. '
          'Bu masraf yalnızca başvurun kabul edilirse düşer. Sonuç olumlu '
          'olmayabilir.',
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Vazgeç'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Başvur'),
          ),
        ],
      ),
    );
    if (onay != true || !mounted) return;

    final ({FamilyOutcome outcome, bool adopted})? sonuc =
        GameScope.of(context).adopt();
    if (sonuc == null || !mounted) return;
    setState(() {
      _sonuc = sonuc.outcome.text;
      _olumlu = sonuc.adopted;
    });
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final GameState state = GameScope.of(context).state!;
    final InteractionAvailability durum =
        GameScope.of(context).adoptionAvailability();
    final List<Person> cocuklar = state.children;

    return SectionScaffold(
      icon: Icons.volunteer_activism_rounded,
      accent: BirOmurAccents.gul,
      title: 'Evlat Edinme',
      subtitle: 'Bir çocuğa aile olmak',
      backLabel: 'Aktiviteler',
      onBack: widget.onBack,
      children: <Widget>[
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  'Başvuru koşulları',
                  style: theme.textTheme.titleMedium,
                ),
                const SizedBox(height: 10),
                Text(
                  '• En az ${Adoption.prototypeOnlyMinAge} yaşında olmak\n'
                  '• Başvuru masrafını karşılayabilmek '
                  '(${trMoney(Adoption.prototypeOnlyCost)})\n'
                  '• Çocuğun bakımını sağlayabilecek düzenli gelir ya da '
                  'birikim\n'
                  '• Evli olmak şart değildir',
                  style: theme.textTheme.bodyMedium,
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        if (durum.isAllowed)
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              key: const Key('adoption_apply_button'),
              onPressed: _basvur,
              icon: const Icon(Icons.volunteer_activism_outlined),
              label: const Text('Başvur'),
            ),
          )
        else
          InfoPanel(
            icon: Icons.info_outline,
            text: 'Şu an başvuramazsın: ${durum.reason}',
          ),
        if (_sonuc != null) ...<Widget>[
          const SizedBox(height: 12),
          Container(
            key: const Key('adoption_result'),
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: (_olumlu
                      ? theme.colorScheme.secondary
                      : theme.colorScheme.tertiary)
                  .withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: (_olumlu
                        ? theme.colorScheme.secondary
                        : theme.colorScheme.tertiary)
                    .withValues(alpha: 0.4),
              ),
            ),
            child: Text(_sonuc!, style: theme.textTheme.bodyMedium),
          ),
        ],
        if (cocuklar.isNotEmpty) ...<Widget>[
          const SizedBox(height: 16),
          Text('Çocukların', style: theme.textTheme.titleMedium),
          const SizedBox(height: 8),
          for (final Person cocuk in cocuklar) ...<Widget>[
            PersonCard(
              person: cocuk,
              playerAge: state.player.age,
              onTap: () => PersonDetailSheet.show(context, personId: cocuk.id),
            ),
            const SizedBox(height: 10),
          ],
        ],
      ],
    );
  }
}

/// **Vasiyet** sayfası (D-052).
///
/// Oyuncu hayattaki çocuklarından birini mirasçı seçebilir. Seçim isteğe
/// bağlıdır, değiştirilebilir ve kaldırılabilir; hiç seçim yapılmazsa
/// miras çocuklar arasında eşit bölünür. Çocuğu olmayan oyuncuya
/// çalışmayan düğme gösterilmez (D-038).
class WillPage extends StatefulWidget {
  const WillPage({super.key, required this.onBack});

  final VoidCallback onBack;

  @override
  State<WillPage> createState() => _WillPageState();
}

class _WillPageState extends State<WillPage> {
  String? _notice;

  void _sec(String childId) {
    final String? metin = GameScope.of(context).chooseHeir(childId);
    setState(() => _notice = metin);
  }

  void _kaldir() {
    final String? metin = GameScope.of(context).clearHeir();
    setState(() => _notice = metin);
  }

  /// Hayata son verme onayı (D-084).
  ///
  /// Kaza eseri seçilemesin diye ayrı bir onay istenir ve onay ekranında
  /// **gerçek yardım hatları** yazar. Hiçbir yerde yöntem geçmez.
  Future<void> _hayataSonVer() async {
    final bool? onay = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        title: const Text('Emin misin?'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            const Text(kLifeEndConfirmText),
            const SizedBox(height: 12),
            Text(
              kLifeEndSupportText,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
        actions: <Widget>[
          TextButton(
            key: const Key('life_end_cancel'),
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Vazgeç'),
          ),
          TextButton(
            key: const Key('life_end_confirm'),
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Devam et'),
          ),
        ],
      ),
    );
    if (onay != true || !mounted) return;
    final String engel = GameScope.of(context).endLifeByChoice();
    if (!mounted) return;
    setState(() => _notice = engel.isEmpty ? null : engel);
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final GameState state = GameScope.of(context).state!;
    final InteractionAvailability durum =
        GameScope.of(context).willAvailability();
    final Person? mirasci = GameScope.of(context).heirChild;
    final List<Person> cocuklar = state.livingChildren;

    return SectionScaffold(
      icon: Icons.history_edu_rounded,
      accent: BirOmurAccents.pirinc,
      title: 'Son Kararlar',
      subtitle: 'Mirasçı seçimi ve hayatının sonuna dair kararlar',
      backLabel: 'Aktiviteler',
      onBack: widget.onBack,
      children: <Widget>[
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text('Nasıl işler?', style: theme.textTheme.titleMedium),
                const SizedBox(height: 10),
                Text(
                  '• Seçim isteğe bağlıdır; yapmazsan miras çocukların '
                  'arasında eşit bölünür.\n'
                  '• Mirasçı seçtiğinde çocuklara kalan paranın büyük '
                  'bölümü ona geçer, eşya paylaşımında ilk sırada olur; '
                  'diğer çocuklar mirastan tamamen çıkarılmaz.\n'
                  '• Eşinin payı bundan etkilenmez.\n'
                  '• Seçimi istediğin zaman değiştirebilir ya da '
                  'kaldırabilirsin.\n'
                  '• Mirasçı seçmek, ölümünden sonra hangi çocuğunla devam '
                  'edeceğini belirlemez; o seçim sana kalır.',
                  style: theme.textTheme.bodyMedium,
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        if (!durum.isAllowed)
          InfoPanel(icon: Icons.info_outline, text: durum.reason!)
        else ...<Widget>[
          Container(
            key: const Key('will_current'),
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: theme.colorScheme.secondary.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: theme.colorScheme.secondary.withValues(alpha: 0.35),
              ),
            ),
            child: Text(
              mirasci == null
                  ? 'Şu an mirasçı seçilmedi; miras eşit bölünecek.'
                  : 'Mirasçın: ${mirasci.fullName}',
              style: theme.textTheme.bodyMedium,
            ),
          ),
          const SizedBox(height: 14),
          Text('Çocukların', style: theme.textTheme.titleMedium),
          const SizedBox(height: 8),
          for (final Person cocuk in cocuklar) ...<Widget>[
            Card(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
                child: Row(
                  children: <Widget>[
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(
                            cocuk.fullName,
                            style: theme.textTheme.titleMedium,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${cocuk.labelFor(state.player.age)} · '
                            '${cocuk.age} yaşında',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (mirasci?.id == cocuk.id)
                      Chip(
                        key: Key('will_badge_${cocuk.id}'),
                        label: const Text('Mirasçı'),
                        visualDensity: VisualDensity.compact,
                      )
                    else
                      FilledButton.tonal(
                        key: Key('will_choose_${cocuk.id}'),
                        onPressed: () => _sec(cocuk.id),
                        child: const Text('Mirasçı yap'),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 10),
          ],
          if (mirasci != null)
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                key: const Key('will_clear'),
                onPressed: _kaldir,
                child: const Text('Mirasçı seçimini kaldır'),
              ),
            ),
        ],
        if (_notice != null) ...<Widget>[
          const SizedBox(height: 12),
          InfoPanel(icon: Icons.history_edu_outlined, text: _notice!),
        ],
        // --- Hayatın sonu (D-084) ------------------------------------
        //
        // Ayrı ve en altta durur; yanlışlıkla basılmasın diye kendi
        // onayı vardır ve onay ekranında gerçek yardım hatları yazar.
        // Hiçbir yerde yöntem geçmez, hiçbir ödül verilmez.
        if (GameScope.of(context).lifeEndBlockReason == null) ...<Widget>[
          const SizedBox(height: 26),
          const KilimDivider(),
          const SizedBox(height: 14),
          Text('Hayatının sonu', style: theme.textTheme.titleMedium),
          const SizedBox(height: 6),
          Text(
            'Karakterinin hayatına kendi kararıyla son verebilirsin. '
            'Bu geri alınamaz ve hiçbir avantaj sağlamaz. Hayatta bir '
            'çocuğun varsa onun hayatından devam edebilirsin.',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              key: const Key('life_end_open'),
              style: OutlinedButton.styleFrom(
                foregroundColor: theme.colorScheme.error,
              ),
              onPressed: _hayataSonVer,
              child: const Text('Hayatına son ver'),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            kLifeEndSupportText,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ],
    );
  }
}

/// Aktiviteler → Tatil yap (Paket 11, D-083).
///
/// Kısa gezi planlanır: şehir, yolculuk türü ve istenirse bir yakın
/// seçilir. Ücret **önceden görünür**, cüzdan yetmiyorsa düğme yerine
/// gerekçe yazılır. Gezi kalıcı taşınma değildir; yaşanan şehir değişmez.
class TravelPage extends StatefulWidget {
  const TravelPage({super.key, required this.onBack});

  final VoidCallback onBack;

  @override
  State<TravelPage> createState() => _TravelPageState();
}

class _TravelPageState extends State<TravelPage> {
  String? _sehir;
  TravelMode _tur = TravelMode.otobus;
  String? _yoldasId;
  String? _sonuc;

  @override
  Widget build(BuildContext context) {
    final GameController controller = GameScope.of(context);
    final GameState state = controller.state!;
    final List<String> sehirler = controller.travelDestinations();
    final List<TravelMode> turler = controller.travelModes();
    final List<Person> yoldaslar = controller.travelCompanions();

    // Seçili tür artık açık değilse (araba satıldı gibi) otobüse döner.
    final TravelMode tur = turler.contains(_tur) ? _tur : TravelMode.otobus;
    final int ucret = Travel.costOf(tur, withCompanion: _yoldasId != null);
    final InteractionAvailability uygunluk = _sehir == null
        ? const InteractionAvailability.blocked('Önce bir şehir seç.')
        : controller.travelAvailability(
            mode: tur,
            city: _sehir!,
            companionId: _yoldasId,
          );

    return SectionScaffold(
      icon: Icons.luggage_rounded,
      accent: BirOmurAccents.mavi,
      title: 'Tatil yap',
      subtitle: 'Tatil, taşınma değildir: yaşadığın şehir değişmez. '
          'Cüzdanında ${state.player.walletLabel} var.',
      backLabel: 'Aktiviteler',
      onBack: widget.onBack,
      children: <Widget>[
        // Hazır paketler (D-083): tek şehre gidip gelmek yerine program.
        const _TravelSectionTitle('Hazır tur paketleri'),
        const SizedBox(height: 8),
        for (final TourPackage tur in kTourPackages) ...<Widget>[
          _TourCard(
            tour: tur,
            companionId: _yoldasId,
            onTake: () => setState(
              () => _sonuc = controller
                  .takeTour(tour: tur, companionId: _yoldasId)
                  ?.text,
            ),
          ),
          const SizedBox(height: 8),
        ],
        const SizedBox(height: 14),
        const _TravelSectionTitle('Ya da kendin bir şehir seç'),
        const SizedBox(height: 8),
        const _TravelSectionTitle('Nereye?'),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: <Widget>[
            for (final String sehir in sehirler)
              ChoiceChip(
                key: Key('trip_city_$sehir'),
                label: Text(sehir),
                selected: _sehir == sehir,
                onSelected: (_) => setState(() {
                  _sehir = sehir;
                  _sonuc = null;
                }),
              ),
          ],
        ),
        const SizedBox(height: 18),
        const _TravelSectionTitle('Nasıl?'),
        const SizedBox(height: 8),
        for (final TravelMode secenek in turler) ...<Widget>[
          _TravelModeCard(
            mode: secenek,
            selected: secenek == tur,
            cost: Travel.costOf(secenek, withCompanion: _yoldasId != null),
            onTap: () => setState(() {
              _tur = secenek;
              _sonuc = null;
            }),
          ),
          const SizedBox(height: 8),
        ],
        const SizedBox(height: 10),
        const _TravelSectionTitle('Kiminle?'),
        const SizedBox(height: 8),
        if (yoldaslar.isEmpty)
          const InfoPanel(
            icon: Icons.person_outline,
            text: 'Şu an birlikte yola çıkabileceğin kimse yok. Vefat '
                'edenler, çok küçük çocuklar ve başka şehirdeki tanıdıklar '
                'bu listede görünmez.',
          )
        else
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: <Widget>[
              ChoiceChip(
                key: const Key('trip_alone'),
                label: const Text('Yalnız'),
                selected: _yoldasId == null,
                onSelected: (_) => setState(() {
                  _yoldasId = null;
                  _sonuc = null;
                }),
              ),
              for (final Person kisi in yoldaslar)
                ChoiceChip(
                  key: Key('trip_companion_${kisi.id}'),
                  label: Text(
                    '${kisi.firstName} · '
                    '${trLower(kisi.labelFor(state.player.age))}',
                  ),
                  selected: _yoldasId == kisi.id,
                  onSelected: (_) => setState(() {
                    _yoldasId = kisi.id;
                    _sonuc = null;
                  }),
                ),
            ],
          ),
        const SizedBox(height: 18),
        // Ücret her zaman önceden görünür.
        InfoPanel(
          icon: Icons.payments_outlined,
          text: 'Bu yolculuk ${trMoney(ucret)} tutuyor'
              '${_yoldasId == null ? '' : ' (iki kişilik)'}. '
              'Ücret yalnızca bir kez düşer.',
        ),
        const SizedBox(height: 12),
        if (uygunluk.isAllowed)
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              key: const Key('trip_go'),
              onPressed: () {
                final TripOutcome? sonuc = controller.takeTrip(
                  mode: tur,
                  city: _sehir!,
                  companionId: _yoldasId,
                );
                setState(() => _sonuc = sonuc?.text);
              },
              child: const Text('Yola çık'),
            ),
          )
        else
          InfoPanel(
            icon: Icons.info_outline,
            text: uygunluk.reason ?? 'Şu an yola çıkamazsın.',
          ),
        if (_sonuc != null) ...<Widget>[
          const SizedBox(height: 12),
          InfoPanel(icon: Icons.luggage_outlined, text: _sonuc!),
        ],
        if (state.trips.isNotEmpty) ...<Widget>[
          const SizedBox(height: 18),
          const _TravelSectionTitle('Gezi anıların'),
          const SizedBox(height: 8),
          for (final TripRecord gezi in state.trips.reversed.take(6))
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: InfoPanel(
                icon: Icons.photo_album_outlined,
                text: '${gezi.age} yaş · ${gezi.city} · '
                    '${gezi.companionId == null ? 'yalnız' : (state.personById(gezi.companionId!)?.firstName ?? 'biriyle')} · '
                    '${trMoney(gezi.cost)}'
                    '${gezi.note == null ? '' : '\n${gezi.note}'}',
              ),
            ),
        ],
      ],
    );
  }
}

class _TravelSectionTitle extends StatelessWidget {
  const _TravelSectionTitle(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Text(
      text,
      style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
    );
  }
}

class _TravelModeCard extends StatelessWidget {
  const _TravelModeCard({
    required this.mode,
    required this.selected,
    required this.cost,
    required this.onTap,
  });

  final TravelMode mode;
  final bool selected;
  final int cost;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    const BirOmurAccent renk = BirOmurAccents.mavi;

    return Material(
      color: selected
          ? Color.alphaBlend(
              renk.softOf(context),
              theme.colorScheme.surfaceContainerHighest,
            )
          : theme.colorScheme.surfaceContainerHighest,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        key: Key('trip_mode_${mode.name}'),
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: renk.of(context).withValues(alpha: selected ? 0.45 : 0.18),
              width: selected ? 1.8 : 1,
            ),
          ),
          padding: const EdgeInsets.all(14),
          child: Row(
            children: <Widget>[
              Icon(
                selected
                    ? Icons.radio_button_checked
                    : Icons.radio_button_unchecked,
                size: 20,
                color: renk.of(context),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(mode.label, style: theme.textTheme.titleMedium),
                    Text(
                      mode.description,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Text(
                trMoney(cost),
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: renk.deepOf(context),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Hazır tur paketi kartı (D-083).
class _TourCard extends StatelessWidget {
  const _TourCard({
    required this.tour,
    required this.companionId,
    required this.onTake,
  });

  final TourPackage tour;
  final String? companionId;
  final VoidCallback onTake;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final GameController controller = GameScope.of(context);
    final InteractionAvailability izin = controller.tourAvailability(
      tour: tour,
      companionId: companionId,
    );
    final int ucret =
        Travel.tourCostOf(tour, withCompanion: companionId != null);

    return Container(
      decoration: panelDecoration(context, radius: 16),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Icon(tour.icon, color: theme.colorScheme.primary),
              const SizedBox(width: 8),
              Expanded(
                child: Text(tour.label, style: theme.textTheme.titleSmall),
              ),
              Text(trMoney(ucret), style: theme.textTheme.labelLarge),
            ],
          ),
          const SizedBox(height: 6),
          Text(tour.description, style: theme.textTheme.bodySmall),
          const SizedBox(height: 4),
          Text(
            '${tour.nights} gece · ${tour.cities.join(', ')}',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          if (!izin.isAllowed)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text(
                izin.reason!,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: FilledButton.tonal(
              key: Key('tour_${tour.id}'),
              onPressed: izin.isAllowed ? onTake : null,
              child: const Text('Bu tura çık'),
            ),
          ),
        ],
      ),
    );
  }
}

/// "Taşın" sayfası (D-083).
///
/// Faho'nun isteği: "taşınmada yaşadığım ilin yakınındaki iller olsun;
/// her taşındığımda yakınındaki iller çıksın". Ülkenin tamamı yerine
/// yaşanan ilin komşuları listelenir.
class RelocationPage extends StatefulWidget {
  const RelocationPage({super.key, required this.onBack});

  final VoidCallback onBack;

  @override
  State<RelocationPage> createState() => _RelocationPageState();
}

class _RelocationPageState extends State<RelocationPage> {
  String? _sonuc;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final GameController controller = GameScope.of(context);
    final GameState state = controller.state!;
    final List<String> hedefler = controller.relocationTargets();

    return SectionScaffold(
      icon: Icons.local_shipping_rounded,
      accent: BirOmurAccents.mavi,
      title: 'Taşın',
      subtitle: '${state.player.currentCity} şehrinde yaşıyorsun. '
          'Cüzdanında ${state.player.walletLabel} var.',
      backLabel: 'Aktiviteler',
      onBack: widget.onBack,
      children: <Widget>[
        InfoPanel(
          icon: Icons.map_outlined,
          text: 'Yalnızca yaşadığın ilin yakınındaki illere taşınabilirsin. '
              'Uzak bir şehre gitmek için aradaki illerden geçmen gerekir. '
              'Taşınma masrafı '
              '${trMoney(Housing.prototypeOnlyMoveCost + Housing.prototypeOnlyIntercityExtraCost)}; '
              'aynı ilde kiralık eve geçmek daha ucuzdur.',
        ),
        const SizedBox(height: 14),
        if (hedefler.isEmpty)
          const InfoPanel(
            icon: Icons.info_outline,
            text: 'Bu şehir için yakın il kaydı yok.',
          )
        else
          for (final String sehir in hedefler) ...<Widget>[
            MenuRow(
              key: Key('relocate_$sehir'),
              title: sehir,
              subtitle: 'Kiralık bir eve taşın',
              icon: Icons.location_city_outlined,
              accent: BirOmurAccents.mavi,
              onTap: () => setState(
                () => _sonuc = controller.relocate(city: sehir),
              ),
            ),
            const SizedBox(height: 8),
          ],
        const SizedBox(height: 14),
        MenuRow(
          key: const Key('relocate_same_city'),
          title: 'Aynı ilde kiralık eve taşın',
          subtitle: trMoney(Housing.prototypeOnlyMoveCost),
          icon: Icons.home_work_outlined,
          accent: BirOmurAccents.yesil,
          onTap: () => setState(() => _sonuc = controller.relocate()),
        ),
        if (_sonuc != null) ...<Widget>[
          const SizedBox(height: 14),
          InfoPanel(icon: Icons.info_outline, text: _sonuc!),
        ],
        const SizedBox(height: 10),
        Text(
          'Ev sahibi olduğun bir eve taşınmak için Varlıklar bölümünden '
          'o eve gir.',
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

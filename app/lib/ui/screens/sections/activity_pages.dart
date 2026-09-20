import 'package:flutter/material.dart';

import '../../../data/activity_catalog.dart';
import '../../../domain/activities/activity_engine.dart';
import '../../../domain/models/book_progress.dart';
import '../../../domain/models/game_state.dart';
import '../../../domain/models/interaction.dart';
import '../../../state/game_controller.dart';
import '../../../state/game_scope.dart';
import '../../widgets/effect_chips.dart';
import '../../widgets/section_scaffold.dart';

/// Berber veya spor salonu sayfası.
///
/// Yalnızca gerçekten yapılabilen eylemler düğme olur; kapalı olanlar
/// gerekçesiyle gösterilir.
class VenuePage extends StatefulWidget {
  const VenuePage({super.key, required this.venue, required this.onBack});

  final ActivityVenue venue;
  final VoidCallback onBack;

  @override
  State<VenuePage> createState() => _VenuePageState();
}

class _VenuePageState extends State<VenuePage> {
  ActivityOutcome? _sonuc;

  @override
  Widget build(BuildContext context) {
    final GameController controller = GameScope.of(context);
    final GameState state = controller.state!;
    final List<ActivityAction> tumEylemler = actionsAt(widget.venue);

    return SectionScaffold(
      title: widget.venue.label,
      subtitle: 'Cüzdanında ${state.player.walletLabel} var.',
      backLabel: 'Aktiviteler',
      onBack: widget.onBack,
      children: <Widget>[
        for (final ActivityAction eylem in tumEylemler) ...<Widget>[
          _ActionCard(
            action: eylem,
            availability: controller.activityAvailability(eylem),
            onTap: () {
              final ActivityOutcome? outcome =
                  controller.performActivity(eylem);
              setState(() => _sonuc = outcome);
            },
          ),
          const SizedBox(height: 10),
        ],
        if (_sonuc != null) ...<Widget>[
          const SizedBox(height: 4),
          _OutcomeCard(outcome: _sonuc!),
        ],
      ],
    );
  }
}

class _ActionCard extends StatelessWidget {
  const _ActionCard({
    required this.action,
    required this.availability,
    required this.onTap,
  });

  final ActivityAction action;
  final InteractionAvailability availability;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final bool acik = availability.isAllowed;
    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                Icon(action.icon, color: theme.colorScheme.secondary),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(action.label, style: theme.textTheme.titleMedium),
                ),
                Text(
                  action.cost == 0 ? 'Ücretsiz' : '${action.cost} ₺',
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
            const SizedBox(height: 10),
            Row(
              children: <Widget>[
                Expanded(
                  child: Text(
                    acik ? '' : (availability.reason ?? ''),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
                FilledButton.tonal(
                  onPressed: acik ? onTap : null,
                  child: Text(acik ? 'Yap' : 'Şu an kapalı'),
                ),
              ],
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

class _OutcomeCard extends StatelessWidget {
  const _OutcomeCard({required this.outcome});

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

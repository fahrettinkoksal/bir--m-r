import 'dart:math';

import '../../data/activity_catalog.dart';
import '../effects/effect_diff.dart';
import '../models/applied_effect.dart';
import '../models/book_progress.dart';
import '../models/game_state.dart';
import '../models/interaction.dart';
import '../models/life_log.dart';
import '../models/player_character.dart';
import '../models/stats.dart';
import '../../text/turkish_text.dart';

/// Bir aktivitenin sonucu.
class ActivityOutcome {
  const ActivityOutcome({
    required this.applied,
    required this.text,
    this.effects = const <AppliedEffect>[],
    this.noNewBenefit = false,
  });

  /// İşlem gerçekten uygulandı mı? `false` ise durum değişmemiştir.
  final bool applied;
  final String text;

  /// Durumun öncesi/sonrası farkından okunan **gerçek** değişimler.
  final List<AppliedEffect> effects;

  /// Bu yaş için bu eylemden kazanılacak kalmadı.
  final bool noNewBenefit;
}

class ActivityResult {
  const ActivityResult({required this.state, required this.outcome});

  final GameState state;
  final ActivityOutcome outcome;
}

/// Berber, spor salonu ve kütüphane.
///
/// Ortak kurallar:
/// - Parası yetmeyen işlem **gerçekleşmez**; cüzdan ve değerler değişmez.
/// - Aynı yaşta tekrar eden eylemin getirisi azalır ve sınıra gelince
///   eylem kapanır; sınırsız stat kasma yoktur.
/// - Sonuçlar hayat günlüğüne yazılır.
///
/// Sayısal değerler `prototypeOnly`'dir (`docs/DESIGN_REVIEW_QUEUE.md`,
/// Q-049).
class ActivityEngine {
  const ActivityEngine();

  /// prototypeOnly: aynı yaşta tekrar edildikçe azalan kazanç eğrisi.
  static const List<double> prototypeOnlyRewardCurve = <double>[1.0, 0.6, 0.3];

  /// Bir eylemin bu yaşta kaç kez yapıldığı.
  int timesDone(GameState state, ActivityAction action) =>
      state.interactionCount('aktivite', action.id);

  /// Eylem şu an yapılabilir mi?
  InteractionAvailability availability(GameState state, ActivityAction action) {
    if (state.player.age < action.minAge) {
      return InteractionAvailability.blocked(
        '${action.minAge} yaşından itibaren yapabilirsin.',
      );
    }
    if (timesDone(state, action) >= action.maxPerAge) {
      return const InteractionAvailability.blocked(
        'Bu yıl için yeterince yaptın; seneye yeniden açılır.',
      );
    }
    if (state.player.wallet < action.cost) {
      return InteractionAvailability.blocked(
        '${trMoney(action.cost)} gerekiyor; cüzdanında yeterli para yok.',
      );
    }
    return const InteractionAvailability.allowed();
  }

  /// Bu mekânda şu an gerçekten yapılabilen eylemler.
  List<ActivityAction> availableActions(GameState state, ActivityVenue venue) =>
      actionsAt(venue)
          .where((ActivityAction a) => availability(state, a).isAllowed)
          .toList(growable: false);

  /// Berber veya spor salonu eylemini uygular.
  ActivityResult perform({
    required GameState state,
    required ActivityAction action,
    required Random rng,
  }) {
    final InteractionAvailability check = availability(state, action);
    if (!check.isAllowed) return _blocked(state, check.reason!);

    final int done = timesDone(state, action);
    final double factor =
        prototypeOnlyRewardCurve[min(done, prototypeOnlyRewardCurve.length - 1)];

    final Stats stats = state.player.stats.copyWith(
      appearance: state.player.stats.appearance + _scaled(action.appearance, factor),
      charisma: state.player.stats.charisma + _scaled(action.charisma, factor),
      happiness: state.player.stats.happiness + _scaled(action.happiness, factor),
      health: state.player.stats.health + _scaled(action.health, factor),
    );

    // Saç stili değişiyorsa mevcut stilden farklı biri seçilir.
    String? yeniStil = state.player.hairStyle;
    if (action.changesHairStyle) {
      final List<String> secenekler = kHairStyles
          .where((String s) => s != state.player.hairStyle)
          .toList(growable: false);
      yeniStil = secenekler[rng.nextInt(secenekler.length)];
    }

    final PlayerCharacter player = state.player.copyWith(
      stats: stats,
      wallet: state.player.wallet - action.cost,
      hairStyle: yeniStil,
    );

    final GameState next = state.copyWith(
      player: player,
      interactionCounts: Map<String, int>.unmodifiable(<String, int>{
        ...state.interactionCounts,
        GameState.interactionKey('aktivite', action.id): done + 1,
      }),
    );

    final String metin = action.changesHairStyle
        ? '${action.label}: artık saçın "$yeniStil". '
            '${trMoney(action.cost)} ödedin.'
        : '${action.label} tamamlandı.'
            '${action.cost > 0 ? ' ${trMoney(action.cost)} ödedin.' : ''}';

    return ActivityResult(
      state: _log(next, metin),
      outcome: ActivityOutcome(
        applied: true,
        text: metin,
        effects: diffAppliedEffects(state, next),
        noNewBenefit: factor == 0,
      ),
    );
  }

  // =====================================================================
  // Kütüphane
  // =====================================================================

  /// Yaşa uygun kitaplar.
  List<BookInfo> availableBooks(GameState state) => booksFor(state.player.age);

  /// Kitabı açar (ilerleme kaydı yoksa oluşturur).
  ActivityResult openBook(GameState state, BookInfo book) {
    if (!book.fitsAge(state.player.age)) {
      return _blocked(state, 'Bu kitap şu an sana uygun değil.');
    }
    if (state.bookProgress(book.id) != null) {
      // Zaten açılmış; durum değişmez.
      return ActivityResult(
        state: state,
        outcome: ActivityOutcome(
          applied: true,
          text: '${book.title} kaldığın yerden açıldı.',
        ),
      );
    }

    final GameState next = state.copyWith(
      books: List<BookProgress>.unmodifiable(<BookProgress>[
        ...state.books,
        BookProgress(
          bookId: book.id,
          pagesRead: 0,
          startedAtAge: state.player.age,
        ),
      ]),
    );
    final String metin = '${book.title} kitabını açtın.';
    return ActivityResult(
      state: _log(next, metin),
      outcome: ActivityOutcome(applied: true, text: metin),
    );
  }

  /// Bir sayfa çevirir; son sayfada kitap biter ve kazanç **bir kez**
  /// uygulanır.
  ///
  /// Bitmiş kitabın sayfalarına tekrar tıklamak yeni kazanç vermez.
  ActivityResult turnPage(GameState state, BookInfo book) {
    final BookProgress? mevcut = state.bookProgress(book.id);
    if (mevcut == null) {
      return _blocked(state, 'Önce kitabı açman gerekiyor.');
    }
    if (mevcut.finished) {
      return _blocked(
        state,
        '${book.title} zaten bitti. Yeniden okumak yeni bir kazanç vermez.',
      );
    }

    final int okunan = mevcut.pagesRead + 1;
    final bool bitti = okunan >= book.pages;

    List<BookProgress> books = state.books
        .map((BookProgress b) => b.bookId == book.id
            ? b.copyWith(pagesRead: okunan, finished: bitti)
            : b)
        .toList(growable: false);
    books = List<BookProgress>.unmodifiable(books);

    GameState next = state.copyWith(books: books);
    if (bitti) {
      next = next.copyWith(
        player: next.player.copyWith(
          stats: next.player.stats.copyWith(
            intelligence:
                next.player.stats.intelligence + book.intelligenceGain,
            happiness: next.player.stats.happiness + book.happinessGain,
            charisma: next.player.stats.charisma + book.charismaGain,
          ),
        ),
      );
    }

    final String metin = bitti
        ? '${book.title} bitti. Son sayfayı kapattığında bir süre '
            'öylece kaldın.'
        : '${book.title}: $okunan / ${book.pages} sayfa.';

    return ActivityResult(
      state: bitti ? _log(next, metin) : next,
      outcome: ActivityOutcome(
        applied: true,
        text: metin,
        effects: diffAppliedEffects(state, next),
      ),
    );
  }

  ActivityResult _blocked(GameState state, String reason) => ActivityResult(
        state: state,
        outcome: ActivityOutcome(applied: false, text: reason),
      );

  GameState _log(GameState state, String text) => state.copyWith(
        log: List<LifeLogEntry>.unmodifiable(<LifeLogEntry>[
          ...state.log,
          LifeLogEntry(
            age: state.player.age,
            text: text,
            category: LogCategory.kisisel,
          ),
        ]),
      );

  static int _scaled(int base, double factor) => (base * factor).round();
}

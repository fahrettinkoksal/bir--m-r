import 'dart:math';

import '../../data/activity_catalog.dart';
import '../effects/effect_diff.dart';
import '../models/applied_effect.dart';
import '../models/book_progress.dart';
import '../models/game_state.dart';
import '../models/zodiac.dart';
import '../life/astrology.dart';
import '../../data/fortune_catalog.dart';
import '../../data/hobby_catalog.dart';
import '../hobby/hobby_tracker.dart';
import '../models/interaction.dart';
import '../models/life_log.dart';
import '../models/player_character.dart';
import '../models/stats.dart';
import '../../text/turkish_text.dart';
import 'outing.dart';
import '../models/person.dart';

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

  /// Bir aktivite eylemini uygular.
  ///
  /// [companion] verilirse eylem **birlikte** yapılır (Paket 41). Ücret,
  /// yaş sınırı ve yıllık kota aynı yerde kaldığı için birlikte gitmek
  /// ikinci kez para götürmez ve ikinci bir kayıt açmaz; yalnızca sonuç
  /// metni, bağ ve ortak geçmiş değişir.
  ActivityResult perform({
    required GameState state,
    required ActivityAction action,
    required Random rng,
    Person? companion,
  }) {
    final InteractionAvailability check = availability(state, action);
    if (!check.isAllowed) return _blocked(state, check.reason!);
    if (companion != null) {
      final InteractionAvailability birlikte =
          Outing.companionAvailability(state, action, companion);
      if (!birlikte.isAllowed) return _blocked(state, birlikte.reason!);
    }

    final int done = timesDone(state, action);
    final double factor =
        prototypeOnlyRewardCurve[min(done, prototypeOnlyRewardCurve.length - 1)];

    final Stats stats = state.player.stats.copyWith(
      appearance: state.player.stats.appearance + _scaled(action.appearance, factor),
      charisma: state.player.stats.charisma + _scaled(action.charisma, factor),
      happiness: state.player.stats.happiness + _scaled(action.happiness, factor),
      health: state.player.stats.health + _scaled(action.health, factor),
      intelligence:
          state.player.stats.intelligence + _scaled(action.intelligence, factor),
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

    GameState next = state.copyWith(
      player: player,
      interactionCounts: Map<String, int>.unmodifiable(<String, int>{
        ...state.interactionCounts,
        GameState.interactionKey('aktivite', action.id): done + 1,
      }),
    );

    // Kalıcı hobi geçmişi (Paket 39). Eylemin kendisi değişmez; yalnızca
    // beslediği bir hobi varsa geçmişe iz düşer.
    next = HobbyTracker.creditActivity(next, action.id);

    // Birlikte gidildiyse sahne, bağ ve ortak geçmiş burada işlenir
    // (Paket 41). Tek çıkış noktası: çifte kayıt oluşamaz.
    if (companion != null) {
      next = _applyCompanion(state, next, action, companion, rng);
      final String sahne = next.log.last.text;
      return ActivityResult(
        state: next,
        outcome: ActivityOutcome(
          applied: true,
          text: sahne,
          effects: diffAppliedEffects(state, next),
          noNewBenefit: factor == 0,
        ),
      );
    }

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

  /// Birlikte gidilen eylemin kişiye bağlı sonuçları.
  ///
  /// Bağ ve fazladan mutluluk aynı yıl aynı kişiyle tekrar çıkıldıkça
  /// azalır: aynı kişiyle üst üste sinemaya giderek bağ kasılamaz.
  /// Ortak geçmişe **tek** bir satır düşer.
  GameState _applyCompanion(
    GameState before,
    GameState after,
    ActivityAction action,
    Person companion,
    Random rng,
  ) {
    final int birlikte = Outing.timesWith(before, action, companion);
    final double oran = Outing.prototypeOnlyRepeatCurve[
        min(birlikte, Outing.prototypeOnlyRepeatCurve.length - 1)];
    final int bagArtisi =
        max(1, (Outing.prototypeOnlyCompanionBond * oran).round());
    final int mutlulukArtisi =
        (Outing.prototypeOnlyCompanionHappiness * oran).round();

    final String sahne = Outing.sceneFor(action, companion, rng);

    GameState next = after.copyWith(
      player: after.player.copyWith(
        stats: after.player.stats.copyWith(
          happiness: after.player.stats.happiness + mutlulukArtisi,
        ),
      ),
      people: after.people
          .map((Person p) => p.id == companion.id
              ? p.copyWith(bond: (p.bond + bagArtisi).clamp(0, 100))
              : p)
          .toList(growable: false),
      interactionCounts: Map<String, int>.unmodifiable(<String, int>{
        ...after.interactionCounts,
        GameState.interactionKey('birlikte-${companion.id}', action.id):
            birlikte + 1,
      }),
      // Anlamlı temas: birlikte çıkmak da görüşmektir, bağ sönümlenmesi
      // bunu görmeli (D-024).
      lastInteractionAge: Map<String, int>.unmodifiable(<String, int>{
        ...after.lastInteractionAge,
        companion.id: after.player.age,
      }),
    );

    // Ortak geçmişe düşen tek satır; kişiye bağlıdır.
    next = next.copyWith(
      log: List<LifeLogEntry>.unmodifiable(<LifeLogEntry>[
        ...next.log,
        LifeLogEntry(
          age: next.player.age,
          text: sahne,
          category: LogCategory.kisisel,
          personId: companion.id,
        ),
      ]),
    );
    return next;
  }

  // =====================================================================
  // Fal ve Tarot (Paket 27)
  // =====================================================================

  /// Bu eylem bir fal mı? Sonuç metni rastgele seçilir.
  static bool isFortune(ActivityAction action) =>
      action.venue == ActivityVenue.falTarot;

  /// Fala baktırır.
  ///
  /// **Sonuç rastgeledir ve iyi de kötü de çıkabilir.** Oyunun olaylarını
  /// yönlendirmez, kesin bir gelecek söylemez; yalnızca biraz keyif ya da
  /// biraz hayal kırıklığı getirir. Tekrar edildikçe kazanç azalır
  /// (D-019 ile aynı ilke), ama **kötü sonuç sönümlenmez**: hoşuna
  /// gitmeyen falı tekrar tekrar baktırıp etkisiz hâle getiremezsin.
  ActivityResult tellFortune({
    required GameState state,
    required ActivityAction action,
    required Random rng,
  }) {
    final InteractionAvailability check = availability(state, action);
    if (!check.isAllowed) return _blocked(state, check.reason!);

    final int done = timesDone(state, action);
    final double factor =
        prototypeOnlyRewardCurve[min(done, prototypeOnlyRewardCurve.length - 1)];

    final ({String text, int happiness}) okuma =
        _readingFor(state, action, rng);
    // Olumlu etki tekrar edildikçe azalır; olumsuz etki **tam** uygulanır.
    final int delta = okuma.happiness >= 0
        ? _scaled(okuma.happiness, factor)
        : okuma.happiness;

    final GameState next = state.copyWith(
      player: state.player.copyWith(
        wallet: state.player.wallet - action.cost,
        stats: state.player.stats.copyWith(
          happiness: state.player.stats.happiness + delta,
        ),
      ),
      interactionCounts: Map<String, int>.unmodifiable(<String, int>{
        ...state.interactionCounts,
        GameState.interactionKey('aktivite', action.id): done + 1,
      }),
    );

    return ActivityResult(
      state: _log(next, okuma.text),
      outcome: ActivityOutcome(
        applied: true,
        text: okuma.text,
        effects: diffAppliedEffects(state, next),
        // Olumsuz fal "kazanç kalmadı" sayılmaz; sonuç gerçek.
        noNewBenefit: factor == 0 && okuma.happiness >= 0,
      ),
    );
  }

  ({String text, int happiness}) _readingFor(
    GameState state,
    ActivityAction action,
    Random rng,
  ) {
    switch (action.id) {
      case 'kahve_fali':
        final FortuneReading r =
            kCoffeeReadings[rng.nextInt(kCoffeeReadings.length)];
        return (text: r.text, happiness: r.prototypeOnlyHappiness);
      case 'tarot_actir':
        final TarotCard k = kTarotCards[rng.nextInt(kTarotCards.length)];
        return (
          text: '${k.name} kartı çıktı. ${k.text}',
          happiness: k.prototypeOnlyHappiness,
        );
      case 'burc_yorumu':
        final Zodiac burc = Astrology.zodiacOf(state);
        final List<FortuneReading> liste =
            kHoroscopes[burc] ?? const <FortuneReading>[];
        if (liste.isEmpty) {
          return (
            text: '${burc.display} için bu dönem bir şey yazmamışlar.',
            happiness: 0,
          );
        }
        final FortuneReading r = liste[rng.nextInt(liste.length)];
        return (
          text: '${burc.display} yorumu: ${r.text}',
          happiness: r.prototypeOnlyHappiness,
        );
      default:
        return (text: '${action.label} tamamlandı.', happiness: 0);
    }
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

    // Bitirilen her kitap "okumak" hobisini besler (Paket 39).
    if (bitti) next = HobbyTracker.credit(next, HobbyKind.okuma);

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

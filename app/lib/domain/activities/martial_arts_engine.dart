import '../../data/martial_arts_catalog.dart';
import '../../data/hobby_catalog.dart';
import '../hobby/hobby_tracker.dart';
import '../../text/turkish_text.dart';
import '../effects/effect_diff.dart';
import '../models/game_state.dart';
import '../models/interaction.dart';
import '../models/life_log.dart';
import '../models/martial_progress.dart';
import '../models/player_character.dart';
import '../models/stats.dart';
import 'activity_engine.dart';
import '../life/upkeep_tracker.dart';

/// Karate, kung fu ve yağlı güreş dersleri (Paket 32).
///
/// Ortak kurallar:
/// - Ders **ucuzdur**; ustalık parayla değil **yılla** gelir. Bir yaşta
///   alınabilecek ders sayısı sınırlıdır ([kMaxMartialLessonsPerAge]),
///   bu yüzden siyah kuşak ya da başpehlivanlık yıllar sürer.
/// - Basamak atlamak ders sayısına bağlıdır; rastgelelik yoktur.
/// - En üst basamaklara çıkanlar eğitmenlik işine başvurabilir.
///
/// Sayısal değerler `prototypeOnly`'dir
/// (`docs/DESIGN_REVIEW_QUEUE.md`, Q-100).
class MartialArtsEngine {
  const MartialArtsEngine();

  /// prototypeOnly: her dersin sağlığa katkısı.
  static const int prototypeOnlyHealthPerLesson = 2;

  /// prototypeOnly: her dersin mutluluğa katkısı.
  static const int prototypeOnlyHappinessPerLesson = 1;

  /// prototypeOnly: basamak atlayınca gelen ek kazanç.
  static const int prototypeOnlyRankHealth = 3;
  static const int prototypeOnlyRankHappiness = 6;
  static const int prototypeOnlyRankCharisma = 2;

  /// Bir sanattaki ilerleme (hiç başlanmadıysa sıfır ilerleme döner).
  MartialProgress progressOf(GameState state, MartialArt art) {
    for (final MartialProgress p in state.martialArts) {
      if (p.artId == art.id) return p;
    }
    return MartialProgress(artId: art.id, lessons: 0);
  }

  /// Bu yaşta bu sanattan kaç ders alındı?
  int lessonsThisAge(GameState state, MartialArt art) =>
      state.interactionCount('dovus', art.id);

  /// Ders alınabilir mi?
  InteractionAvailability availability(GameState state, MartialArt art) {
    if (state.player.age < art.minAge) {
      return InteractionAvailability.blocked(
        '${art.minAge} yaşından itibaren ders alabilirsin.',
      );
    }
    final MartialProgress p = progressOf(state, art);
    if (p.isTopRank) {
      return InteractionAvailability.blocked(
        'En üst basamaktasın: ${p.rankName}. Öğrenecek ders kalmadı.',
      );
    }
    if (lessonsThisAge(state, art) >= kMaxMartialLessonsPerAge) {
      return const InteractionAvailability.blocked(
        'Bu yıl için yeterince çalıştın; seneye devam edersin.',
      );
    }
    if (state.player.wallet < art.lessonCost) {
      return InteractionAvailability.blocked(
        '${trMoney(art.lessonCost)} gerekiyor; cüzdanında yeterli para yok.',
      );
    }
    return const InteractionAvailability.allowed();
  }

  /// Bu yıl daha kaç ders alınabilir?
  ///
  /// Hem yıllık sınır hem cüzdan hesaba katılır; en üst basamaktaysa 0.
  int plannedSeasonLessons(GameState state, MartialArt art) {
    if (progressOf(state, art).isTopRank) return 0;
    if (state.player.age < art.minAge) return 0;
    final int kalanHak = (kMaxMartialLessonsPerAge - lessonsThisAge(state, art))
        .clamp(0, kMaxMartialLessonsPerAge);
    if (kalanHak == 0) return 0;
    final int paraylaAlinabilir = art.lessonCost <= 0
        ? kalanHak
        : state.player.wallet ~/ art.lessonCost;
    // Basamak atlanacaksa fazlası boşa gitmesin diye sınır konmaz:
    // en üst basamağa kalan ders de üst sınırdır.
    final MartialProgress p = progressOf(state, art);
    final int zirveyeKalan = art.totalLessons - p.lessons;
    return <int>[kalanHak, paraylaAlinabilir, zirveyeKalan]
        .reduce((int a, int b) => a < b ? a : b)
        .clamp(0, kMaxMartialLessonsPerAge);
  }

  /// Bu yılın derslerini tek seferde alır.
  ///
  /// Tek tek [takeLesson] çağırmakla **birebir aynı** sonucu verir: aynı
  /// ücret, aynı yıllık sınır ([kMaxMartialLessonsPerAge]), aynı basamak
  /// eşikleri, aynı spor hobisi katkısı. Değişen yalnızca kaç kez
  /// dokunulduğu.
  ///
  /// Neden gerekti: siyah kuşak 110, başpehlivanlık 120 ders istiyor ve
  /// bir yaşta en fazla [kMaxMartialLessonsPerAge] ders alınabiliyor.
  /// Oyuncu aynı düğmeye yüzden fazla kez basmak zorunda kalıyordu.
  /// Sayısal denge bilerek **değiştirilmedi**; o karar Q-100'de duruyor.
  ActivityResult takeSeason({
    required GameState state,
    required MartialArt art,
  }) {
    final InteractionAvailability check = availability(state, art);
    if (!check.isAllowed) {
      return ActivityResult(
        state: state,
        outcome: ActivityOutcome(applied: false, text: check.reason!),
      );
    }

    final MartialProgress basla = progressOf(state, art);
    final int oncekiSeviye = basla.level;

    GameState next = state;
    int alinan = 0;
    // Üst sınır bir güvenlik kemeri: availability zaten yıllık sınırda,
    // parada ve en üst basamakta kapanır.
    while (alinan < kMaxMartialLessonsPerAge &&
        availability(next, art).isAllowed) {
      next = takeLesson(state: next, art: art).state;
      alinan++;
    }

    if (alinan == 0) {
      return ActivityResult(
        state: state,
        outcome: ActivityOutcome(applied: false, text: check.reason ?? ''),
      );
    }

    final MartialProgress bitis = progressOf(next, art);
    final int odenen = alinan * art.lessonCost;
    final StringBuffer metin = StringBuffer(
      '${art.label}: bu yıl $alinan ders aldın, ${trMoney(odenen)} ödedin.',
    );
    if (bitis.level > oncekiSeviye) {
      final int atlanan = bitis.level - oncekiSeviye;
      metin.write(
        atlanan == 1
            ? ' Yeni basamak: ${bitis.rankName}.'
            : ' $atlanan basamak birden çıktın: ${bitis.rankName}.',
      );
      if (bitis.isTopRank) {
        metin.write(' Öğrenecek ders kalmadı.');
      } else if (bitis.canTeach) {
        metin.write(
          ' Artık ${trLower(art.label)} eğitmenliğine başvurabilirsin.',
        );
      }
    } else {
      final int? kalan = bitis.lessonsToNextRank;
      if (kalan != null) {
        metin.write(' Sonraki basamağa $kalan ders kaldı.');
      }
    }

    // Neden durduğu söylenir: sessizce yarıda kesilmez.
    final InteractionAvailability sonrasi = availability(next, art);
    if (!sonrasi.isAllowed &&
        !bitis.isTopRank &&
        next.player.wallet < art.lessonCost) {
      metin.write(' Paran bittiği için yılın kalanını çalışamadın.');
    }

    return ActivityResult(
      state: next,
      outcome: ActivityOutcome(
        applied: true,
        text: metin.toString(),
        effects: diffAppliedEffects(state, next),
      ),
    );
  }

  /// Bir ders alır.
  ///
  /// Basamak atlanırsa sonuç metni bunu söyler ve ek kazanç uygulanır.
  ActivityResult takeLesson({
    required GameState state,
    required MartialArt art,
  }) {
    final InteractionAvailability check = availability(state, art);
    if (!check.isAllowed) {
      return ActivityResult(
        state: state,
        outcome: ActivityOutcome(applied: false, text: check.reason!),
      );
    }

    final MartialProgress onceki = progressOf(state, art);
    final int oncekiSeviye = onceki.level;
    final MartialProgress sonraki = onceki.copyWith(
      lessons: onceki.lessons + 1,
    );
    final int yeniSeviye = sonraki.level;
    final bool atladi = yeniSeviye > oncekiSeviye;
    final bool zirve = atladi && yeniSeviye >= art.topLevel;

    final MartialProgress kayit = MartialProgress(
      artId: art.id,
      lessons: sonraki.lessons,
      startedAtAge: onceki.startedAtAge ?? state.player.age,
      topRankAtAge: zirve ? state.player.age : onceki.topRankAtAge,
    );

    final List<MartialProgress> liste = <MartialProgress>[
      for (final MartialProgress p in state.martialArts)
        if (p.artId != art.id) p,
      kayit,
    ];

    final Stats stats = state.player.stats.gain(
      health: prototypeOnlyHealthPerLesson + (atladi ? prototypeOnlyRankHealth : 0),
      happiness: prototypeOnlyHappinessPerLesson + (atladi ? prototypeOnlyRankHappiness : 0),
      charisma: (atladi ? prototypeOnlyRankCharisma : 0),
    );

    final PlayerCharacter player = state.player.copyWith(
      stats: stats,
      wallet: state.player.wallet - art.lessonCost,
    );

    GameState next = state.copyWith(
      player: player,
      martialArts: List<MartialProgress>.unmodifiable(liste),
      interactionCounts: Map<String, int>.unmodifiable(<String, int>{
        ...state.interactionCounts,
        GameState.interactionKey('dovus', art.id):
            lessonsThisAge(state, art) + 1,
      }),
    );

    // Dövüş dersi de spor hobisini besler (Paket 39): salona gitmek
    // hangi kapıdan olursa olsun spordur.
    next = HobbyTracker.credit(next, HobbyKind.spor);

    // Faho'nun Q-116 kararı: dövüş sanatı **spor sayılır**. Bakım
    // geçmişine de yazılır; yoksa her hafta çalışan biri yıllık
    // yıpranmada "hiç spor yapmamış" sayılıyordu (D-072).
    next = UpkeepTracker.recordSport(next);

    final String metin = _metin(art, kayit, atladi: atladi, zirve: zirve);
    if (atladi) next = _log(next, metin);

    return ActivityResult(
      state: next,
      outcome: ActivityOutcome(
        applied: true,
        text: metin,
        effects: diffAppliedEffects(state, next),
      ),
    );
  }

  String _metin(
    MartialArt art,
    MartialProgress p, {
    required bool atladi,
    required bool zirve,
  }) {
    if (zirve) {
      return '${art.label}: en üst basamağa çıktın — ${p.rankName}. '
          '${art.ranks[p.level].note}';
    }
    if (atladi) {
      final String ek = p.canTeach
          ? ' Artık ${trLower(art.label)} eğitmenliğine başvurabilirsin.'
          : '';
      return '${art.label}: yeni basamak — ${p.rankName}. '
          '${art.ranks[p.level].note}$ek';
    }
    final int? kalan = p.lessonsToNextRank;
    final String kalanMetni = kalan == null
        ? ''
        : ' Sonraki basamağa $kalan ders kaldı.';
    return '${art.label} dersi tamamlandı. ${trMoney(art.lessonCost)} ödedin.'
        '$kalanMetni';
  }

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
}

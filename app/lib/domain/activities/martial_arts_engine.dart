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

    final Stats stats = state.player.stats.copyWith(
      health: state.player.stats.health +
          prototypeOnlyHealthPerLesson +
          (atladi ? prototypeOnlyRankHealth : 0),
      happiness: state.player.stats.happiness +
          prototypeOnlyHappinessPerLesson +
          (atladi ? prototypeOnlyRankHappiness : 0),
      charisma: state.player.stats.charisma +
          (atladi ? prototypeOnlyRankCharisma : 0),
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
          ? ' Artık ${art.label.toLowerCase()} eğitmenliğine başvurabilirsin.'
          : '';
      return '${art.label}: yeni basamak — ${p.rankName}. '
          '${art.ranks[p.level].note}$ek';
    }
    final int? kalan = p.lessonsToNextRank;
    final String kalanMetni =
        kalan == null ? '' : ' Sonraki basamağa $kalan ders kaldı.';
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

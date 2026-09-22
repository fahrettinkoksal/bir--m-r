import 'dart:math';

import '../../data/event_pool.dart';
import '../../data/finger_catalog.dart';
import '../../data/name_pool.dart';
import '../generation/random_util.dart';
import '../models/finger_profile.dart';
import '../models/game_state.dart';
import '../models/gender.dart';
import '../models/interaction.dart';
import '../models/life_log.dart';
import '../models/person.dart';
import '../models/relation.dart';
import '../models/wealth.dart';
import 'intimacy.dart';
import 'romance.dart';

/// Bir kaydırmanın sonucu.
class FingerOutcome {
  const FingerOutcome({
    required this.applied,
    required this.text,
    this.matched = false,
    this.person,
  });

  final bool applied;
  final String text;

  /// Beğeni karşılık buldu mu?
  final bool matched;

  /// Tanışma sonucunda hayatına giren kişi.
  final Person? person;
}

class FingerResult {
  const FingerResult({required this.state, required this.outcome});

  final GameState state;
  final FingerOutcome outcome;
}

/// "Finger" tanışma uygulaması (Paket 34).
///
/// Kurallar:
/// - Bir yılda bakılabilecek profil sayısı sınırlıdır; sonsuz kaydırma yok.
/// - Beğeni her zaman karşılık bulmaz; ihtimal görünüş ve karizmaya bağlıdır.
/// - Eşleşmek tanışmak değildir. **Tanışıldığında** kişi oyunun kişi
///   listesine kalıcı kimlikle girer ve oradan sonra normal ilişki
///   kurallarıyla işler.
/// - Sevgilisi ya da eşi olan biri eşleşmeyle yeni sevgili edinemez;
///   tanışan kişi arkadaş olur.
///
/// Sayısal değerler `prototypeOnly`'dir
/// (`docs/DESIGN_REVIEW_QUEUE.md`, Q-102).
abstract final class Finger {
  /// Bu yıl kaç profile bakıldı?
  static int swipesThisAge(GameState state) =>
      state.interactionCount('finger', 'kaydirma');

  /// Uygulama açılabilir mi?
  static InteractionAvailability availability(GameState state) {
    if (state.player.age < kFingerMinAge) {
      return const InteractionAvailability.blocked(
        '$kFingerMinAge yaşından itibaren kullanılabilir.',
      );
    }
    return const InteractionAvailability.allowed();
  }

  /// Kaydırma yapılabilir mi?
  static InteractionAvailability swipeAvailability(GameState state) {
    final InteractionAvailability temel = availability(state);
    if (!temel.isAllowed) return temel;
    if (swipesThisAge(state) >= kFingerMaxSwipesPerAge) {
      return const InteractionAvailability.blocked(
        'Bu yıl yeterince baktın; seneye yeni profiller gelir.',
      );
    }
    return const InteractionAvailability.allowed();
  }

  /// Desteyi gerekirse doldurur.
  ///
  /// Zaten profil varsa dokunmaz: ekran her açılışta yeniden karılmaz.
  static GameState ensureDeck(GameState state, Random rng) {
    if (state.player.age < kFingerMinAge) return state;
    if (state.fingerDeck.length >= kFingerDeckSize) return state;

    final List<FingerProfile> deste = <FingerProfile>[...state.fingerDeck];
    int sayac = _nextIndex(state);
    while (deste.length < kFingerDeckSize) {
      deste.add(_uret(state, rng, sayac++));
    }
    return state.copyWith(
      fingerDeck: List<FingerProfile>.unmodifiable(deste),
    );
  }

  /// Profili geçer: deste yenilenir, eşleşme olmaz.
  static FingerResult pass(GameState state, String profileId, Random rng) {
    final InteractionAvailability check = swipeAvailability(state);
    if (!check.isAllowed) {
      return FingerResult(
        state: state,
        outcome: FingerOutcome(applied: false, text: check.reason!),
      );
    }
    GameState next = _consume(state, profileId);
    next = ensureDeck(next, rng);
    return FingerResult(
      state: next,
      outcome: const FingerOutcome(
        applied: true,
        text: 'Geçtin. Sıradaki profil geldi.',
      ),
    );
  }

  /// Profili beğenir. Karşılık gelirse eşleşme listesine düşer.
  static FingerResult like(GameState state, String profileId, Random rng) {
    final InteractionAvailability check = swipeAvailability(state);
    if (!check.isAllowed) {
      return FingerResult(
        state: state,
        outcome: FingerOutcome(applied: false, text: check.reason!),
      );
    }
    final FingerProfile? profil = _fromDeck(state, profileId);
    if (profil == null) {
      return FingerResult(
        state: state,
        outcome: const FingerOutcome(
          applied: false,
          text: 'Bu profil destede değil.',
        ),
      );
    }

    final bool eslesti = rng.nextDouble() < matchChance(state);
    GameState next = _consume(state, profileId);

    if (eslesti) {
      next = next.copyWith(
        fingerMatches: List<FingerProfile>.unmodifiable(<FingerProfile>[
          ...next.fingerMatches,
          profil.copyWith(matchedAtAge: state.player.age),
        ]),
      );
    }
    next = ensureDeck(next, rng);

    return FingerResult(
      state: next,
      outcome: FingerOutcome(
        applied: true,
        matched: eslesti,
        text: eslesti ? rng.pick(kFingerMatchLines) : rng.pick(kFingerNoMatchLines),
      ),
    );
  }

  /// prototypeOnly: beğeninin karşılık bulma ihtimali.
  ///
  /// Görünüş ve karizma yükseldikçe artar; kimse sıfır ihtimalle kalmaz.
  static double matchChance(GameState state) {
    final double cazibe =
        (state.player.stats.appearance + state.player.stats.charisma) / 200;
    return (kFingerBaseMatchChance + cazibe * kFingerCharmBonus)
        .clamp(0.05, 0.9);
  }

  /// Eşleşilen kişiyle tanışır: kişi artık oyunun kişi listesindedir.
  ///
  /// Sevgilisi ya da eşi olmayan biri için **sevgili** olur; olan biri için
  /// **arkadaş**. Uygulama var olan ilişkiyi kendiliğinden bitirmez.
  static FingerResult meet(GameState state, String profileId, Random rng) {
    final FingerProfile? profil = _fromMatches(state, profileId);
    if (profil == null) {
      return FingerResult(
        state: state,
        outcome: const FingerOutcome(
          applied: false,
          text: 'Böyle bir eşleşmen yok.',
        ),
      );
    }
    if (profil.isMet) {
      return FingerResult(
        state: state,
        outcome: FingerOutcome(
          applied: false,
          text: '${profil.firstName} ile zaten tanıştın.',
        ),
      );
    }

    const Romance romance = Romance();
    final bool bosta = !romance.hasPartner(state) && state.marriage == null;
    final RelationType iliski =
        bosta ? RelationType.sevgili : RelationType.arkadas;

    final String kimlik = _nextPersonId(state);
    final Person kisi = Person(
      id: kimlik,
      firstName: profil.firstName,
      lastName: profil.lastName,
      gender: profil.gender,
      relation: iliski,
      age: profil.age,
      isAlive: true,
      inPlayerHousehold: false,
      employment: profil.occupation == null
          ? EmploymentStatus.ogrenci
          : EmploymentStatus.calisiyor,
      occupation: profil.occupation,
      wealth: profil.age >= 18 ? WealthTier.ortaHalli : null,
      city: profil.city,
      bond: rng.between(45, 62), // prototypeOnly
      infertile: iliski == RelationType.sevgili
          ? Intimacy.rollPartnerInfertility(rng)
          : false,
    );

    final List<FingerProfile> eslesmeler = state.fingerMatches
        .map((FingerProfile p) =>
            p.id == profileId ? p.copyWith(metPersonId: kimlik) : p)
        .toList(growable: false);

    final String metin = bosta
        ? '${profil.firstName} ile buluştunuz. Artık sevgilisiniz.'
        : '${profil.firstName} ile buluştunuz. Arkadaş oldunuz.';

    GameState next = state.copyWith(
      people: List<Person>.unmodifiable(<Person>[...state.people, kisi]),
      fingerMatches: List<FingerProfile>.unmodifiable(eslesmeler),
      storyFlags: bosta
          ? <String>{...state.storyFlags, StoryFlags.romantikIliskide}
          : state.storyFlags,
      log: List<LifeLogEntry>.unmodifiable(<LifeLogEntry>[
        ...state.log,
        LifeLogEntry(
          age: state.player.age,
          text: 'Finger: $metin',
          category: LogCategory.aile,
        ),
      ]),
    );

    return FingerResult(
      state: next,
      outcome: FingerOutcome(applied: true, text: metin, person: kisi),
    );
  }

  // --- İç işler ---------------------------------------------------------

  static FingerProfile? _fromDeck(GameState state, String id) {
    for (final FingerProfile p in state.fingerDeck) {
      if (p.id == id) return p;
    }
    return null;
  }

  static FingerProfile? _fromMatches(GameState state, String id) {
    for (final FingerProfile p in state.fingerMatches) {
      if (p.id == id) return p;
    }
    return null;
  }

  /// Profili desteden çıkarır ve yıllık sayacı işler.
  static GameState _consume(GameState state, String profileId) =>
      state.copyWith(
        fingerDeck: List<FingerProfile>.unmodifiable(
          state.fingerDeck
              .where((FingerProfile p) => p.id != profileId)
              .toList(growable: false),
        ),
        interactionCounts: Map<String, int>.unmodifiable(<String, int>{
          ...state.interactionCounts,
          GameState.interactionKey('finger', 'kaydirma'):
              swipesThisAge(state) + 1,
        }),
      );

  static int _nextIndex(GameState state) {
    int enBuyuk = 0;
    for (final FingerProfile p in <FingerProfile>[
      ...state.fingerDeck,
      ...state.fingerMatches,
    ]) {
      final int? n = int.tryParse(p.id.split('-').last);
      if (n != null && n > enBuyuk) enBuyuk = n;
    }
    return enBuyuk + 1;
  }

  static String _nextPersonId(GameState state) {
    final Set<String> mevcut = <String>{
      for (final Person p in state.people) p.id,
    };
    int n = 1;
    while (mevcut.contains('finger-$n')) {
      n++;
    }
    return 'finger-$n';
  }

  /// prototypeOnly: profil üretimi.
  ///
  /// Karşı cinsten profil gösterilir. **Bu bir oyun tasarımı kararı
  /// değildir**; yönelim ve eşleşme kuralları Faho ile kararlaştırılacak
  /// (`Romance.start` ile aynı geçici varsayım).
  static FingerProfile _uret(GameState state, Random rng, int index) {
    final Gender gender =
        state.player.gender == Gender.kadin ? Gender.erkek : Gender.kadin;
    final int age = (state.player.age + rng.between(-5, 6)).clamp(18, 75);
    final bool calisiyor = age > 23 || rng.nextDouble() < 0.4;

    final Set<String> ilgiler = <String>{};
    final int kacIlgi = rng.between(2, 4);
    while (ilgiler.length < kacIlgi) {
      ilgiler.add(rng.pick(kFingerInterests));
    }

    return FingerProfile(
      id: 'finger-profil-$index',
      firstName:
          rng.pick(gender == Gender.kadin ? kadinIsimleri : erkekIsimleri),
      lastName: rng.pick(soyisimler),
      gender: gender,
      age: age,
      city: state.player.currentCity,
      bio: rng.pick(kFingerBios),
      interests: List<String>.unmodifiable(ilgiler),
      occupation: calisiyor ? rng.pick(meslekler) : null,
    );
  }
}

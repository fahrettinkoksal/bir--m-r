import 'dart:math';

import '../../data/interaction_texts.dart';
import '../generation/random_util.dart';
import '../models/game_state.dart';
import '../models/interaction.dart';
import '../models/life_log.dart';
import '../models/person.dart';
import '../models/player_character.dart';
import '../models/stats.dart';

/// Etkileşimin hem yeni durumu hem de oyuncuya gösterilecek sonucu.
class InteractionResult {
  const InteractionResult({required this.state, required this.outcome});

  final GameState state;
  final InteractionOutcome outcome;
}

/// Aile etkileşimleri motoru (D-016, D-017, D-019, D-020, D-026).
///
/// Kurallar:
/// - **Genel etkileşim kotası yoktur.** Sayaçlar kişi + etkileşim türü
///   bazındadır; bir sayacın dolması başka kişileri veya başka faaliyetleri
///   kilitlemez.
/// - Aynı yaşta aynı kişiyle aynı etkinliğin olumlu getirisi tekrarlarla
///   azalır ve o yaş için **sıfır ek kazanca** iner.
/// - Yakın tekrarda kişi **bazen** doğal gerekçeyle reddedebilir; ret
///   durumunda küçük bir mutluluk kaybı **olabilir**, zorunlu değildir.
///
/// Aşağıdaki sayısal değerler `prototypeOnly`'dir: demo içindir, onaylanmış
/// oyun dengesi değildir ve kalıcı tasarım kararı sayılmaz.
class FamilyInteractions {
  const FamilyInteractions();

  /// Aynı yaş içinde kaçıncı tekrarda kazancın ne kadarının verileceği.
  /// Son değer 0: o yaş için ek fayda biter.
  static const List<double> prototypeOnlyRewardCurve = <double>[1.0, 0.55, 0.25, 0.0];

  /// Aynı yaş içindeki başarılı tekrar sayısına göre ret olasılığı.
  /// İlk istekte ret yoktur; sonrasında da ret **zorunlu değildir**.
  static const List<double> prototypeOnlyRefusalChance = <double>[0.0, 0.30, 0.45, 0.55];

  /// Ret gerçekleştiğinde mutluluk kaybının **yaşanma** olasılığı.
  static const double prototypeOnlyRefusalPenaltyChance = 0.5;

  /// Oyuncunun kendi isteğiyle etkileşim kurabilmesi için asgari yaş.
  /// (`docs/FAMILY_SYSTEM.md`: oyuncunun yaşı ve koşulları dikkate alınır.)
  static const int prototypeOnlyMinPlayerAge = 4;

  static const Map<InteractionKind, _Reward> _rewards = <InteractionKind, _Reward>{
    InteractionKind.vakitGecir: _Reward(bond: 7, happiness: 4),
    InteractionKind.sohbet: _Reward(bond: 4, happiness: 2, charisma: 2),
  };

  /// Etkileşimin şu an mümkün olup olmadığı.
  ///
  /// Olmayan veya vefat etmiş kişiyle etkileşim hiçbir zaman açılmaz.
  InteractionAvailability availability(GameState state, Person person) {
    if (!person.isAlive) {
      return const InteractionAvailability.blocked(
        'Bu kişi hayatta değil; etkileşim kurulamaz.',
      );
    }
    if (state.player.age < prototypeOnlyMinPlayerAge) {
      return InteractionAvailability.blocked(
        'Bu etkileşimler $prototypeOnlyMinPlayerAge yaşından itibaren açılır.',
      );
    }
    return const InteractionAvailability.allowed();
  }

  /// Etkileşimi uygular ve yeni durumu döndürür.
  ///
  /// Uygun olmayan bir kişi için çağrılırsa durum değişmez.
  InteractionResult perform({
    required GameState state,
    required String personId,
    required InteractionKind kind,
    required Random rng,
  }) {
    final Person? person = state.personById(personId);
    if (person == null) {
      return InteractionResult(
        state: state,
        outcome: InteractionOutcome(
          kind: kind,
          personId: personId,
          accepted: false,
          text: 'Bu kişi artık hayatında değil.',
        ),
      );
    }

    final InteractionAvailability check = availability(state, person);
    if (!check.isAllowed) {
      return InteractionResult(
        state: state,
        outcome: InteractionOutcome(
          kind: kind,
          personId: personId,
          accepted: false,
          text: check.reason!,
        ),
      );
    }

    final int done = state.interactionCount(personId, kind.name);
    final double refusalChance =
        prototypeOnlyRefusalChance[min(done, prototypeOnlyRefusalChance.length - 1)];

    if (rng.chance(refusalChance)) {
      return _refuse(state: state, person: person, kind: kind, rng: rng);
    }
    return _accept(state: state, person: person, kind: kind, rng: rng, done: done);
  }

  InteractionResult _refuse({
    required GameState state,
    required Person person,
    required InteractionKind kind,
    required Random rng,
  }) {
    // Ret her seferinde ceza değildir (D-020).
    final int happinessDelta =
        rng.chance(prototypeOnlyRefusalPenaltyChance) ? -rng.between(1, 2) : 0;

    final InteractionOutcome outcome = InteractionOutcome(
      kind: kind,
      personId: person.id,
      accepted: false,
      text: interactionText(
        rng: rng,
        person: person,
        kind: kind,
        accepted: false,
        noNewBenefit: false,
        playerAge: state.player.age,
      ),
      happinessDelta: happinessDelta,
    );

    // Ret sayacı artırmaz: gerçekleşen bir etkinlik yoktur.
    return InteractionResult(
      state: _apply(state, person, outcome),
      outcome: outcome,
    );
  }

  InteractionResult _accept({
    required GameState state,
    required Person person,
    required InteractionKind kind,
    required Random rng,
    required int done,
  }) {
    final double factor =
        prototypeOnlyRewardCurve[min(done, prototypeOnlyRewardCurve.length - 1)];
    final _Reward reward = _rewards[kind]!;

    final int bondDelta = _scaled(reward.bond, factor);
    final int happinessDelta = _scaled(reward.happiness, factor);
    final int charismaDelta = _scaled(reward.charisma, factor);
    final bool noNewBenefit =
        bondDelta == 0 && happinessDelta == 0 && charismaDelta == 0;

    final InteractionOutcome outcome = InteractionOutcome(
      kind: kind,
      personId: person.id,
      accepted: true,
      text: interactionText(
        rng: rng,
        person: person,
        kind: kind,
        accepted: true,
        noNewBenefit: noNewBenefit,
        playerAge: state.player.age,
      ),
      bondDelta: bondDelta,
      happinessDelta: happinessDelta,
      charismaDelta: charismaDelta,
      noNewBenefit: noNewBenefit,
    );

    final Map<String, int> counts = Map<String, int>.from(state.interactionCounts)
      ..[GameState.interactionKey(person.id, kind.name)] = done + 1;

    return InteractionResult(
      state: _apply(state, person, outcome).copyWith(
        interactionCounts: Map<String, int>.unmodifiable(counts),
      ),
      outcome: outcome,
    );
  }

  /// Sonucu kişiye, ana karaktere ve gerekiyorsa hayat günlüğüne işler.
  GameState _apply(GameState state, Person person, InteractionOutcome outcome) {
    final List<Person> people = state.people
        .map(
          (Person p) => p.id == person.id
              ? p.copyWith(bond: (p.bond + outcome.bondDelta).clamp(0, 100))
              : p,
        )
        .toList(growable: false);

    final Stats stats = state.player.stats.copyWith(
      happiness: state.player.stats.happiness + outcome.happinessDelta,
      charisma: state.player.stats.charisma + outcome.charismaDelta,
    );
    final PlayerCharacter player = state.player.copyWith(stats: stats);

    // Günlüğe yalnızca anlamlı sonuçlar yazılır; sıfır kazançlı tekrar
    // günlüğü şişirmez.
    final List<LifeLogEntry> log = outcome.worthLogging
        ? <LifeLogEntry>[
            ...state.log,
            LifeLogEntry(
              age: state.player.age,
              text: outcome.text,
              category: LogCategory.aile,
            ),
          ]
        : state.log;

    return state.copyWith(
      player: player,
      people: List<Person>.unmodifiable(people),
      log: List<LifeLogEntry>.unmodifiable(log),
    );
  }

  static int _scaled(int base, double factor) => (base * factor).round();
}

class _Reward {
  const _Reward({required this.bond, required this.happiness, this.charisma = 0});

  final int bond;
  final int happiness;
  final int charisma;
}

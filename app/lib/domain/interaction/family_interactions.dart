import 'dart:math';

import '../../data/interaction_texts.dart';
import '../effects/effect_diff.dart';
import '../generation/random_util.dart';
import '../models/game_state.dart';
import '../models/interaction.dart';
import '../models/life_log.dart';
import '../models/person.dart';
import '../models/player_character.dart';
import '../models/relation.dart';
import '../models/stats.dart';
import '../models/wealth.dart';

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
    InteractionKind.hediyeVer: _Reward(bond: 10, happiness: 3),
    InteractionKind.hediyeIste: _Reward(bond: 2, happiness: 5),
    InteractionKind.paraIste: _Reward(bond: 1, happiness: 2),
  };

  /// prototypeOnly: oyuncunun **kendi cüzdanından** çıkan hediye bedeli.
  /// Kapsamlı bir mağaza ve fiyat listesi henüz tasarlanmadı.
  static const int prototypeOnlyGiftCost = 50;

  /// prototypeOnly: karşı tarafın verebileceği harçlık, kendi ekonomik
  /// durumuna göre. Bu, kişinin servetinin oyuncuya geçmesi **değildir**;
  /// yalnızca verebileceği küçük miktarı belirler.
  static const Map<WealthTier, int> prototypeOnlyAllowanceByWealth =
      <WealthTier, int>{
    WealthTier.cokYoksul: 10,
    WealthTier.yoksul: 25,
    WealthTier.ortaHalli: 60,
    WealthTier.varlikli: 150,
    WealthTier.cokVarlikli: 400,
  };

  /// prototypeOnly: hediye/para istenebilmesi için gereken asgari yakınlık.
  static const int prototypeOnlyAskMinBond = 25;

  /// prototypeOnly: hediye/para isteme reddi, istismarı engellemek için
  /// normal etkileşimlerden daha hızlı artar.
  static const List<double> prototypeOnlyAskRefusalChance =
      <double>[0.15, 0.45, 0.70, 0.85];

  /// prototypeOnly: hediye olarak verilebilecek küçük eşyalar.
  /// Kapsamlı hediye kataloğu değildir.
  static const List<String> prototypeOnlyGiftItems = <String>[
    'defter',
    'bilye',
    'kol_saati',
  ];

  /// Bir kişi için ekranda gösterilecek etkileşimler.
  ///
  /// Koşulu sağlanmayan tür listelenmez; böylece hiçbir zaman
  /// gerçekleşemeyecek bir eylem tıklanabilir görünmez.
  List<InteractionKind> availableKinds(GameState state, Person person) =>
      InteractionKind.values
          .where((InteractionKind k) => availability(state, person, k).isAllowed)
          .toList(growable: false);

  /// Etkileşimin şu an mümkün olup olmadığı.
  ///
  /// Olmayan veya vefat etmiş kişiyle etkileşim hiçbir zaman açılmaz.
  InteractionAvailability availability(
    GameState state,
    Person person, [
    InteractionKind? kind,
  ]) {
    if (!person.isAlive) {
      return const InteractionAvailability.blocked(
        'Bu kişi hayatta değil; etkileşim kurulamaz.',
      );
    }
    if (person.relation == RelationType.eskiSevgili) {
      // Ayrılık sonrası sevgiliye özel eylemler koşulsuz açılmaz
      // (`docs/CLAUDE_PROTOTYPE_TASK.md` Aşama 4). Eski sevgiliyle hangi
      // etkileşimlerin açık kalacağı henüz kararlaştırılmadı.
      return const InteractionAvailability.blocked(
        'Ayrıldınız. Eski sevgiliyle hangi etkileşimlerin açık kalacağı '
        'henüz tasarlanmadı.',
      );
    }
    if (state.player.age < prototypeOnlyMinPlayerAge) {
      return InteractionAvailability.blocked(
        'Bu etkileşimler $prototypeOnlyMinPlayerAge yaşından itibaren açılır.',
      );
    }
    if (kind == null) return const InteractionAvailability.allowed();
    return _resourceAvailability(state, person, kind);
  }

  /// Para veya eşya taşıyan türlerin ek koşulları.
  ///
  /// Para yoksa hediye verilemez; kendi parası olmayan birinden para
  /// istenemez. Bu koşullar sağlanmadan eylem **hiç** sunulmaz.
  InteractionAvailability _resourceAvailability(
    GameState state,
    Person person,
    InteractionKind kind,
  ) {
    switch (kind) {
      case InteractionKind.vakitGecir:
      case InteractionKind.sohbet:
        return const InteractionAvailability.allowed();

      case InteractionKind.hediyeVer:
        if (state.player.wallet < prototypeOnlyGiftCost) {
          return InteractionAvailability.blocked(
            'Cüzdanında yeterli para yok. Hediye için '
            '$prototypeOnlyGiftCost ₺ gerekiyor.',
          );
        }
        return const InteractionAvailability.allowed();

      case InteractionKind.hediyeIste:
      case InteractionKind.paraIste:
        if (!_canBeAsked(person)) {
          return const InteractionAvailability.blocked(
            'Bunu isteyebileceğin biri değil.',
          );
        }
        if (person.bond < prototypeOnlyAskMinBond) {
          return const InteractionAvailability.blocked(
            'Aranız bunu isteyecek kadar yakın değil.',
          );
        }
        if (kind == InteractionKind.paraIste && person.wealth == null) {
          return InteractionAvailability.blocked(
            '${person.firstName} henüz kendi parasını kazanmıyor.',
          );
        }
        if (kind == InteractionKind.hediyeIste &&
            _remainingGifts(state).isEmpty) {
          return const InteractionAvailability.blocked(
            'İstenecek bir şey kalmadı; eşya sistemi henüz genişletilmedi.',
          );
        }
        return const InteractionAvailability.allowed();
    }
  }

  /// Hediye/para istenebilecek kişiler: **yetişkin** yakınlar.
  ///
  /// Kardeşten veya akrandan para istemek ayrı bir tasarım konusudur;
  /// karar verilene kadar kapsam dışıdır.
  static bool _canBeAsked(Person person) {
    if (person.age < 18) return false;
    return person.relation == RelationType.anne ||
        person.relation == RelationType.baba ||
        person.relation.group == RelationGroup.genis;
  }

  /// Oyuncunun henüz sahip olmadığı hediyelik eşyalar.
  static List<String> _remainingGifts(GameState state) => prototypeOnlyGiftItems
      .where((String id) => !state.possessions.contains(id))
      .toList(growable: false);

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

    final InteractionAvailability check = availability(state, person, kind);
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

    // Para/eşya taşıyan türlerde fayda bittiyse alışveriş hiç yapılmaz:
    // boşuna para harcanmaz, olmayan bir kazanç gösterilmez.
    final double factor =
        prototypeOnlyRewardCurve[min(done, prototypeOnlyRewardCurve.length - 1)];
    if (kind.transfersResource && factor == 0) {
      return _refuse(
        state: state,
        person: person,
        kind: kind,
        rng: rng,
        noNewBenefit: true,
      );
    }

    final List<double> refusalTable = kind.transfersResource
        ? prototypeOnlyAskRefusalChance
        : prototypeOnlyRefusalChance;
    final double refusalChance =
        refusalTable[min(done, refusalTable.length - 1)];

    if (kind != InteractionKind.hediyeVer && rng.chance(refusalChance)) {
      return _refuse(state: state, person: person, kind: kind, rng: rng);
    }
    return _accept(state: state, person: person, kind: kind, rng: rng, done: done);
  }

  InteractionResult _refuse({
    required GameState state,
    required Person person,
    required InteractionKind kind,
    required Random rng,
    bool noNewBenefit = false,
  }) {
    // Ret her seferinde ceza değildir (D-020). Fayda bitmişse ceza da yoktur.
    final int happinessDelta = noNewBenefit
        ? 0
        : (rng.chance(prototypeOnlyRefusalPenaltyChance)
            ? -rng.between(1, 2)
            : 0);

    final InteractionOutcome outcome = InteractionOutcome(
      kind: kind,
      personId: person.id,
      accepted: false,
      text: interactionText(
        rng: rng,
        person: person,
        kind: kind,
        accepted: noNewBenefit,
        noNewBenefit: noNewBenefit,
        playerAge: state.player.age,
      ),
      happinessDelta: happinessDelta,
      noNewBenefit: noNewBenefit,
    );

    // Ret sayacı artırmaz: gerçekleşen bir etkinlik yoktur.
    final GameState next = _apply(state, person, outcome);
    return InteractionResult(
      state: next,
      outcome: outcome.withEffects(diffAppliedEffects(state, next)),
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

    // Para ve eşya devri: yalnızca gerçekten mümkünse yapılır.
    int moneyDelta = 0;
    String? gainedItem;
    switch (kind) {
      case InteractionKind.hediyeVer:
        // Para oyuncunun kendi cüzdanından çıkar.
        moneyDelta = -prototypeOnlyGiftCost;
      case InteractionKind.paraIste:
        final int base =
            prototypeOnlyAllowanceByWealth[person.wealth] ?? 0;
        moneyDelta = _scaled(base, factor);
        if (moneyDelta == 0) {
          // Verilecek para çıkmadıysa eylem olmuş gibi gösterilmez.
          return _refuse(
            state: state,
            person: person,
            kind: kind,
            rng: rng,
          );
        }
      case InteractionKind.hediyeIste:
        final List<String> kalanlar = _remainingGifts(state);
        if (kalanlar.isEmpty) {
          // Verilecek bir şey yoksa sahte kazanç üretilmez.
          return _noGiftLeft(state: state, person: person, rng: rng);
        }
        gainedItem = kalanlar[rng.nextInt(kalanlar.length)];
      case InteractionKind.vakitGecir:
      case InteractionKind.sohbet:
        break;
    }

    final bool noNewBenefit = bondDelta == 0 &&
        happinessDelta == 0 &&
        charismaDelta == 0 &&
        moneyDelta == 0 &&
        gainedItem == null;

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
      moneyDelta: moneyDelta,
      gainedPossession: gainedItem,
      noNewBenefit: noNewBenefit,
    );

    final Map<String, int> counts = Map<String, int>.from(state.interactionCounts)
      ..[GameState.interactionKey(person.id, kind.name)] = done + 1;

    // Anlamlı temas kaydı: sitem olayı gerçek dünya dakikasına değil, oyun
    // içi ilerlemeye bakar (D-024, D-025).
    final Map<String, int> lastSeen =
        Map<String, int>.from(state.lastInteractionAge)
          ..[person.id] = state.player.age;

    final GameState next = _apply(state, person, outcome).copyWith(
      interactionCounts: Map<String, int>.unmodifiable(counts),
      lastInteractionAge: Map<String, int>.unmodifiable(lastSeen),
      // Yalnızca gerçekten kazanç sağlayan etkileşim ilerleme sayılır;
      // boş tekrar ek olay tetiklemez.
      progressSinceLastEvent: outcome.hasAnyEffect
          ? state.progressSinceLastEvent + 1
          : state.progressSinceLastEvent,
    );
    return InteractionResult(
      state: next,
      outcome: outcome.withEffects(diffAppliedEffects(state, next)),
    );
  }

  /// İstenecek hediye kalmadığında: durum değişmez, sahte kazanç üretilmez.
  InteractionResult _noGiftLeft({
    required GameState state,
    required Person person,
    required Random rng,
  }) {
    final InteractionOutcome outcome = InteractionOutcome(
      kind: InteractionKind.hediyeIste,
      personId: person.id,
      accepted: false,
      text: noGiftLeftText(
        rng: rng,
        person: person,
        playerAge: state.player.age,
      ),
    );
    return InteractionResult(state: state, outcome: outcome);
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
    // Cüzdan eksiye düşmez; borç kuralları kararlaştırılmadı. Hediye
    // verebilmek için yeterli para zaten `availability` ile denetlenir.
    final PlayerCharacter player = state.player.copyWith(
      stats: stats,
      wallet: (state.player.wallet + outcome.moneyDelta).clamp(0, 1 << 31),
    );

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

    final String? kazanilan = outcome.gainedPossession;
    return state.copyWith(
      player: player,
      people: List<Person>.unmodifiable(people),
      log: List<LifeLogEntry>.unmodifiable(log),
      possessions: kazanilan == null
          ? state.possessions
          : <String>{...state.possessions, kazanilan},
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

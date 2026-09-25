import 'dart:math';

import '../../data/gift_catalog.dart';
import '../../data/interaction_texts.dart';
import '../effects/effect_diff.dart';
import '../generation/random_util.dart';
import '../models/game_state.dart';
import '../models/gift_record.dart';
import '../models/interaction.dart';
import '../models/life_log.dart';
import '../models/owned_item.dart';
import '../models/person.dart';
import '../models/player_character.dart';
import '../models/relation.dart';
import '../models/stats.dart';
import '../models/wealth.dart';
import 'interaction_policy.dart';
import '../../text/turkish_text.dart';

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

  /// prototypeOnly: oyuncunun hediye için ayırabileceği en düşük bütçe.
  ///
  /// Hediyenin gerçek bedeli katalogdan gelir; bu yalnızca "hiç para yokken
  /// hediye düğmesi açılmasın" eşiğidir.
  static const int prototypeOnlyMinGiftBudget = 120;

  /// prototypeOnly: karşı tarafın verebileceği harçlık, kendi ekonomik
  /// durumuna göre. Bu, kişinin servetinin oyuncuya geçmesi **değildir**;
  /// yalnızca verebileceği küçük miktarı belirler.
  static const Map<WealthTier, int> prototypeOnlyAllowanceByWealth =
      <WealthTier, int>{
    WealthTier.cokYoksul: 10,
    WealthTier.yoksul: 25,
    WealthTier.ortaHalli: 60,
    WealthTier.varlikli: 500,
    WealthTier.cokVarlikli: 1400,
  };

  /// prototypeOnly: hediye/para istenebilmesi için gereken asgari yakınlık.
  static const int prototypeOnlyAskMinBond = 25;

  /// prototypeOnly: hediye/para isteme reddi, istismarı engellemek için
  /// normal etkileşimlerden daha hızlı artar.
  static const List<double> prototypeOnlyAskRefusalChance =
      <double>[0.15, 0.45, 0.70, 0.85];


  /// Bir kişi için ekranda gösterilecek etkileşimler.
  ///
  /// Koşulu sağlanmayan tür listelenmez; böylece hiçbir zaman
  /// gerçekleşemeyecek bir eylem tıklanabilir görünmez.
  List<InteractionKind> availableKinds(GameState state, Person person) {
    final Set<InteractionKind> anlamli = meaningfulKindsFor(person.relation);
    return InteractionKind.values
        .where((InteractionKind k) =>
            anlamli.contains(k) && availability(state, person, k).isAllowed)
        .toList(growable: false);
  }

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
    // Küs olan kişiyle gündelik etkileşim kurulmaz (D-130). Kayıt
    // silinmez; yalnızca kapı kapanır, barış yolu açık kalır.
    if (person.isEstranged) {
      return const InteractionAvailability.blocked(
        'Aranız bozuk. Barışmadan görüşmüyorsunuz.',
      );
    }
    if (person.relation == RelationType.eskiEs) {
      // Boşanma sonrası hangi etkileşimlerin açık kalacağı henüz
      // kararlaştırılmadı (Q-063); uydurma bir kural uygulanmaz.
      return const InteractionAvailability.blocked(
        'Boşandınız. Eski eşle hangi etkileşimlerin açık kalacağı henüz '
        'tasarlanmadı.',
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
    // Tür bu ilişkide hiç anlamlı değilse listelenmez.
    if (!meaningfulKindsFor(person.relation).contains(kind)) {
      return const InteractionAvailability.blocked(
        'Bu kişiyle yapılabilecek bir etkileşim değil.',
      );
    }

    switch (kind) {
      case InteractionKind.vakitGecir:
      case InteractionKind.sohbet:
        return const InteractionAvailability.allowed();

      case InteractionKind.hediyeVer:
        if (state.player.wallet < prototypeOnlyMinGiftBudget) {
          return const InteractionAvailability.blocked(
            'Hediye alacak paran yok.',
          );
        }
        if (_giftsPlayerCanBuy(state, person).isEmpty) {
          return const InteractionAvailability.blocked(
            'Cüzdanındaki parayla ona uygun bir hediye bulunmuyor.',
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
            _giftsPersonCanGive(state, person).isEmpty) {
          return const InteractionAvailability.blocked(
            'Şu an sana uygun, alabileceği bir hediye yok.',
          );
        }
        return const InteractionAvailability.allowed();
    }
  }

  /// Karşı tarafın oyuncuya alabileceği, henüz sahip olunmayan hediyeler.
  ///
  /// Yaş, verenin ekonomik durumu ve eldeki eşyalar birlikte değerlendirilir.
  List<GiftItem> _giftsPersonCanGive(GameState state, Person person) => giftsFor(
        receiverAge: state.player.age,
        giverWealth: person.wealth,
        excluded: state.possessions,
      );

  /// Oyuncunun kendi cüzdanıyla o kişiye alabileceği hediyeler.
  List<GiftItem> _giftsPlayerCanBuy(GameState state, Person person) => giftsFor(
        receiverAge: person.age,
        maxValue: state.player.wallet,
      );

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
    GiftItem? alinanHediye;
    GiftItem? verilenHediye;
    switch (kind) {
      case InteractionKind.hediyeVer:
        // Hediye oyuncunun **kendi cüzdanından** alınır; bedeli katalogdan.
        final List<GiftItem> uygun = _giftsPlayerCanBuy(state, person);
        if (uygun.isEmpty) {
          // Alınabilecek hediye yoksa para harcanmaz, işlem olmuş gibi
          // gösterilmez.
          return _noGiftAvailable(state: state, person: person, rng: rng);
        }
        verilenHediye = uygun[rng.nextInt(uygun.length)];
        moneyDelta = -verilenHediye.value;
      case InteractionKind.paraIste:
        final int base = prototypeOnlyAllowanceByWealth[person.wealth] ?? 0;
        moneyDelta = _scaled(base, factor);
        if (moneyDelta == 0) {
          // Verilecek para çıkmadıysa eylem olmuş gibi gösterilmez.
          return _refuse(state: state, person: person, kind: kind, rng: rng);
        }
      case InteractionKind.hediyeIste:
        final List<GiftItem> uygun = _giftsPersonCanGive(state, person);
        if (uygun.isEmpty) {
          // Verilecek bir şey yoksa sahte kazanç üretilmez.
          return _noGiftAvailable(state: state, person: person, rng: rng);
        }
        alinanHediye = uygun[rng.nextInt(uygun.length)];
      case InteractionKind.vakitGecir:
      case InteractionKind.sohbet:
        break;
    }

    final bool noNewBenefit = bondDelta == 0 &&
        happinessDelta == 0 &&
        charismaDelta == 0 &&
        moneyDelta == 0 &&
        alinanHediye == null &&
        verilenHediye == null;

    // Harçlık isteyen oyuncu **ne kadar aldığını** okumak için cüzdanına
    // bakmak zorunda kalmaz (D-108): tutar sonucun içinde yazar.
    final String sahne = interactionText(
      rng: rng,
      person: person,
      kind: kind,
      accepted: true,
      noNewBenefit: noNewBenefit,
      playerAge: state.player.age,
      giftName: (alinanHediye ?? verilenHediye)?.name,
    );
    final String metin = kind == InteractionKind.paraIste && moneyDelta > 0
        ? '$sahne Cüzdanına ${trMoney(moneyDelta)} girdi.'
        : sahne;

    final InteractionOutcome outcome = InteractionOutcome(
      kind: kind,
      personId: person.id,
      accepted: true,
      text: metin,
      bondDelta: bondDelta,
      happinessDelta: happinessDelta,
      charismaDelta: charismaDelta,
      moneyDelta: moneyDelta,
      gainedPossession: alinanHediye?.id,
      givenPossession: verilenHediye?.id,
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

  /// Uygun hediye bulunamadığında: durum değişmez, sahte kazanç üretilmez.
  InteractionResult _noGiftAvailable({
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

    final Stats stats = state.player.stats.gain(
      happiness: outcome.happinessDelta,
      charisma: outcome.charismaDelta,
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
              personId: person.id,
            ),
          ]
        : state.log;

    // Gerçekten el değiştiren hediyeler kaydedilir: kim, kime, ne verdi.
    final String? kazanilan = outcome.gainedPossession;
    final String? verilen = outcome.givenPossession;
    final List<GiftRecord> gifts = kazanilan == null && verilen == null
        ? state.gifts
        : <GiftRecord>[
            ...state.gifts,
            if (kazanilan != null)
              GiftRecord(
                itemId: kazanilan,
                fromId: person.id,
                toId: GiftRecord.playerId,
                age: state.player.age,
              ),
            if (verilen != null)
              GiftRecord(
                itemId: verilen,
                fromId: GiftRecord.playerId,
                toId: person.id,
                age: state.player.age,
              ),
          ];

    final GameState next = state.copyWith(
      player: player,
      people: List<Person>.unmodifiable(people),
      log: List<LifeLogEntry>.unmodifiable(log),
      gifts: List<GiftRecord>.unmodifiable(gifts),
    );

    // Yalnızca oyuncunun **aldığı** hediye envantere girer; verilen hediye
    // karşı tarafa geçer ve oyuncunun eşyası olmaz.
    if (kazanilan == null) return next;
    return next.grantItems(
      <String>[kazanilan],
      source: ItemSource.hediye,
      fromPersonId: person.id,
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

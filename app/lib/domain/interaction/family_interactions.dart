import 'dart:math';

import '../../data/gift_catalog.dart';
import '../../data/interaction_texts.dart';
import '../effects/effect_diff.dart';
import '../family/child_rules.dart';
import '../family/child_stage.dart';
import '../generation/child_progression.dart';
import '../generation/random_util.dart';
import '../features/feature_catalog.dart';
import '../models/game_state.dart';
import '../models/gift_record.dart';
import '../models/interaction.dart';
import '../models/life_log.dart';
import '../models/owned_item.dart';
import '../models/person.dart';
import '../models/person_development.dart';
import '../models/education.dart';
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
    // Paket AO §25: ortak çocuğu konuşmak. Boşanmış iki insanın
    // yakınlığını **büyütmez** — mesele çocuk, ilişkiyi onarmak değil.
    // Küçük bir yakınlık ve oyuncuya küçük bir iç rahatlığı.
    InteractionKind.cocukKonus: _Reward(bond: 2, happiness: 2),
    // Paket BK/3 — çocuğa özel eylemler. Buradaki sayılar **oyuncunun**
    // tarafı: yakınlık ve kendi keyfi. Çocuğun kendi kaydındaki etki
    // `_childEffect` içinde ve ayrı yazılı.
    InteractionKind.odevYardim: _Reward(bond: 5, happiness: 3),
    InteractionKind.harclikVer: _Reward(bond: 4, happiness: 2),
    InteractionKind.hobiyeYazdir: _Reward(bond: 5, happiness: 3),
    // Kural sevilmez: yakınlık **geri gider**.
    InteractionKind.kuralKoy: _Reward(bond: -2, happiness: -1),
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

  // --- Paket BK/3: çocuğa özel eylemlerin sayıları ------------------
  //
  // Hepsi `prototypeOnly` (Q-203). Çocuğun statlarına `Stats.gain` ile
  // işlenir: yükselen değerde her yeni puan pahalılaşır, yani aynı
  // eylemi ömür boyu tekrarlamak çocuğu 100'e yapıştırmaz. Aynı yıl
  // tekrarlanan denemede ise `prototypeOnlyRewardCurve` eriyor.

  /// prototypeOnly: ödeve birlikte oturmanın çocuğun zekâsına etkisi.
  static const int prototypeOnlyHomeworkIntelligence = 3;

  /// prototypeOnly: ödevin çocuğun kendi keyfine etkisi.
  static const int prototypeOnlyHomeworkHappiness = 2;

  /// prototypeOnly: harçlığın anlam kazandığı en küçük yaş.
  static const int prototypeOnlyAllowanceMinAge = 7;

  /// prototypeOnly: hobiye yazdırmanın yaş aralığı.
  static const int prototypeOnlyHobbyMinAge = 6;
  static const int prototypeOnlyHobbyMaxAge = 17;

  /// prototypeOnly: okul kademesine göre yıllık harçlık (₺).
  ///
  /// Çocuğun birikimi (`PersonDevelopment.money`) gerçek bir kayıt:
  /// 18'inden sonra ekonomik durumunu, yetişkinlikte "eli darda mı"
  /// sorusunu ve taşınma gücünü belirliyor.
  static const Map<SchoolLevel, int> prototypeOnlyAllowanceBySchool =
      <SchoolLevel, int>{
    SchoolLevel.ilkokul: 1200,
    SchoolLevel.ortaokul: 3000,
    SchoolLevel.lise: 6000,
  };

  /// prototypeOnly: okul kaydı olmayan çocuk için harçlık.
  static const int prototypeOnlyAllowanceDefault = 2400;

  /// prototypeOnly: harçlığın çocuğun keyfine etkisi.
  static const int prototypeOnlyAllowanceHappiness = 3;

  /// prototypeOnly: bir hobiye yazdırmanın yıllık bedeli (₺).
  static const int prototypeOnlyHobbyCost = 9000;

  /// prototypeOnly: hobinin çocuğun keyfine etkisi.
  static const int prototypeOnlyHobbyHappiness = 5;

  /// prototypeOnly: hobinin çocuğun karizmasına etkisi.
  ///
  /// Hobi bir uğraş **ve** bir çevre: kurs, takım, atölye. Etki
  /// küçüktür ve `Stats.gain` eğrisiyle daha da küçülür.
  static const int prototypeOnlyHobbyCharisma = 2;

  /// prototypeOnly: kuralın çocuğun keyfine etkisi (düşer).
  static const int prototypeOnlyRuleHappiness = -4;

  /// prototypeOnly: hediye/para isteme reddi, istismarı engellemek için
  /// normal etkileşimlerden daha hızlı artar.
  static const List<double> prototypeOnlyAskRefusalChance =
      <double>[0.15, 0.45, 0.70, 0.85];


  /// Bir kişi için ekranda gösterilecek etkileşimler.
  ///
  /// Koşulu sağlanmayan tür listelenmez; böylece hiçbir zaman
  /// gerçekleşemeyecek bir eylem tıklanabilir görünmez.
  List<InteractionKind> availableKinds(GameState state, Person person) {
    // Çocukta liste **kademeye** göre daralır (Paket BK/4): bebeğin
    // kartında ödev ya da kural satırı hiç çıkmaz. Kademe eşikleri
    // D-180'den gelir.
    final Set<InteractionKind> anlamli =
        person.relation == RelationType.cocuk
            ? meaningfulKindsForChildStage(ChildStage.of(person.age))
            : meaningfulKindsFor(person.relation);
    return InteractionKind.values
        .where((InteractionKind k) =>
            anlamli.contains(k) && availability(state, person, k).isAllowed)
        .toList(growable: false);
  }

  /// [exSpouse] ile oyuncunun **ortak** çocukları (§25).
  ///
  /// Ad üzerinden değil kayıt üzerinden: çocuğun diğer biyolojik ebeveyni
  /// olarak bu kişinin kimliği yazılmışsa ortaktır. Eski kayıtlarda bu
  /// alan boş olduğu için liste boş döner ve eski davranış (kapalı kapı)
  /// aynen korunur.
  List<Person> _sharedChildrenWith(GameState state, Person exSpouse) =>
      state.people
          .where((Person p) =>
              (p.relation == RelationType.cocuk ||
                  p.relation == RelationType.uveyCocuk) &&
              (p.motherId == exSpouse.id ||
                  p.fatherId == exSpouse.id ||
                  p.development?.otherParentId == exSpouse.id))
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
    // Küs olan kişiyle gündelik etkileşim kurulmaz (D-130). Kayıt
    // silinmez; yalnızca kapı kapanır, barış yolu açık kalır.
    if (person.isEstranged) {
      return const InteractionAvailability.blocked(
        'Aranız bozuk. Barışmadan görüşmüyorsunuz.',
      );
    }
    if (person.relation == RelationType.eskiEs) {
      // Paket AO §25 — burası eskiden **her şeyi** kapatıyordu ve
      // gerekçesi "henüz tasarlanmadı"ydı. Artık tasarlandı:
      //
      // * Ortak çocuk **yoksa** gündelik iletişim kapalı kalır. Boşandınız;
      //   sizi bağlayan bir şey kalmadı.
      // * Ortak çocuk **varsa** iletişim tamamen bitmez. İki insan aynı
      //   çocuğun annesi ve babası olmaya devam eder.
      //
      // Açılan tek kapı `cocukKonus`: dev bir velayet/mahkeme sistemi
      // kurulmadı (§25, V1 sınırı).
      if (_sharedChildrenWith(state, person).isEmpty) {
        return const InteractionAvailability.blocked(
          'Boşandınız. Sizi bağlayan bir şey kalmadı.',
        );
      }
      if (kind != null && kind != InteractionKind.cocukKonus) {
        return const InteractionAvailability.blocked(
          'Boşandınız. Konuşacağınız tek şey çocuğunuz.',
        );
      }
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

      // §25: yalnızca ortak çocuğu olan eski eşle konuşulur. Kapı
      // yukarıda da denetlendi; burası türün kendi koşulu.
      case InteractionKind.cocukKonus:
        if (person.relation != RelationType.eskiEs) {
          return const InteractionAvailability.blocked(
            'Bu etkileşim yalnızca eski eşle yapılır.',
          );
        }
        if (_sharedChildrenWith(state, person).isEmpty) {
          return const InteractionAvailability.blocked(
            'Ortak çocuğunuz yok.',
          );
        }
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

      // --- Paket BK/3: çocuğa özel eylemler -------------------------
      //
      // Hepsi yalnızca oyuncunun **kendi** çocuğu için ve kapı
      // gerekçesiyle kapanır (D-095): "neden yapamıyorum" ekranda
      // yazar.
      case InteractionKind.odevYardim:
      case InteractionKind.harclikVer:
      case InteractionKind.hobiyeYazdir:
      case InteractionKind.kuralKoy:
        // Modül anahtarı (Paket BL). Kapalı modülün satırı listelenmez:
        // [availableKinds] yalnızca izin verilenleri döndürür, [perform]
        // da aynı kapıdan geçer. Kural koyma ayrı anahtardır çünkü
        // tek başına bir mekanik (okul sorununu azaltır) getirir.
        final FeatureId modul = kind == InteractionKind.kuralKoy
            ? FeatureId.cocukKurallari
            : FeatureId.ebeveynlikEylemleri;
        final String? modulEngeli = state.featureBlockReason(modul);
        if (modulEngeli != null) {
          return InteractionAvailability.blocked(modulEngeli);
        }
        if (person.relation != RelationType.cocuk) {
          return const InteractionAvailability.blocked(
            'Bu yalnızca kendi çocuğun için.',
          );
        }
        final PersonDevelopment? gelisim = person.development;
        if (gelisim == null) {
          return InteractionAvailability.blocked(
            '${person.firstName} hakkında yeterli kayıt yok.',
          );
        }
        // Kademe dışındaysa gerekçe **kademeyi** söyler (Paket BK/4):
        // "henüz çok küçük" ile "artık kendi kararını veriyor" ayrı
        // şeylerdir.
        final ChildStage kademe = ChildStage.of(person.age);
        if (!meaningfulKindsForChildStage(kademe).contains(kind)) {
          return InteractionAvailability.blocked(
            kademe == ChildStage.bebek
                ? '${person.firstName} bunun için henüz çok küçük.'
                : '${person.firstName} artık kendi kararlarını veriyor.',
          );
        }
        return switch (kind) {
          InteractionKind.odevYardim => _odevUygun(person, gelisim),
          InteractionKind.harclikVer => _harclikUygun(state, person),
          InteractionKind.hobiyeYazdir => _hobiUygun(state, person, gelisim),
          // Kuralın koşulu kendi dosyasında yazılı (ChildRules).
          _ => () {
            final String? engel = ChildRules.blockReason(state, person);
            return engel == null
                ? const InteractionAvailability.allowed()
                : InteractionAvailability.blocked(engel);
          }(),
        };

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

  // --- Paket BK/3: çocuğa özel eylemin çocuktaki karşılığı ----------

  /// Eylemin çocuğun **kendi** kaydında yaptığı değişim.
  ///
  /// Oyuncunun tarafı (`_rewards`) ayrıdır. Burası çocuğun zekâsı,
  /// keyfi, birikimi ve ilgi alanları: yani ebeveynliğin gerçekten bir
  /// yere yazıldığı yer. `null` dönerse çocuk tarafında bir şey
  /// olmamıştır.
  _ChildEffect? _childEffect({
    required GameState state,
    required Person child,
    required InteractionKind kind,
    required double factor,
    required Random rng,
    required int moneySpent,
  }) {
    final PersonDevelopment? dev = child.development;
    if (dev == null || !kind.childOnly) return null;

    switch (kind) {
      case InteractionKind.odevYardim:
        // Zekâ `Stats.gain` ile artar: yükseldikçe her puan pahalılaşır.
        final Stats yeni = dev.stats.gain(
          intelligence: _scaled(prototypeOnlyHomeworkIntelligence, factor),
          happiness: _scaled(prototypeOnlyHomeworkHappiness, factor),
        );
        return _ChildEffect(
          development: dev.copyWith(stats: yeni),
          happinessDelta: _scaled(prototypeOnlyHomeworkHappiness, factor),
        );

      case InteractionKind.harclikVer:
        // Harçlık çocuğun **birikimine** girer: 18'inden sonra ekonomik
        // durumunu, eli darda olup olmadığını ve taşınma gücünü bu kayıt
        // belirliyor.
        return _ChildEffect(
          development: dev.copyWith(
            money: (dev.money + moneySpent).clamp(0, 1 << 40),
          ),
          happinessDelta: _scaled(prototypeOnlyAllowanceHappiness, factor),
        );

      case InteractionKind.hobiyeYazdir:
        final List<String> bos = _bosHobiler(dev);
        if (bos.isEmpty) return null;
        final String yeni = bos[rng.nextInt(bos.length)];
        return _ChildEffect(
          development: dev.copyWith(
            interests: List<String>.unmodifiable(<String>[
              ...dev.interests,
              yeni,
            ]),
            stats: dev.stats.gain(
              charisma: _scaled(prototypeOnlyHobbyCharisma, factor),
              happiness: _scaled(prototypeOnlyHobbyHappiness, factor),
            ),
          ),
          happinessDelta: _scaled(prototypeOnlyHobbyHappiness, factor),
          newInterest: yeni,
        );

      case InteractionKind.kuralKoy:
        // Kuralın bedeli çocuğun keyfi; karşılığı okul sorununun
        // ihtimalinin bir süre düşmesi (`ChildRules`). Kayıt
        // `lastInteractionAge` içinde tutulur; yeni alan açılmadı.
        return _ChildEffect(
          development: dev,
          happinessDelta: prototypeOnlyRuleHappiness,
          marks: <String, int>{
            ChildRules.ruleKey(child.id): state.player.age,
          },
        );

      case InteractionKind.vakitGecir:
      case InteractionKind.sohbet:
      case InteractionKind.hediyeVer:
      case InteractionKind.hediyeIste:
      case InteractionKind.paraIste:
      case InteractionKind.cocukKonus:
        return null;
    }
  }

  // --- Paket BK/3: çocuğa özel eylemlerin koşulları ------------------

  /// Ödeve birlikte oturulabilir mi?
  ///
  /// Okula gitmeyen çocuğun ödevi yoktur: kapı gerekçesiyle kapanır.
  InteractionAvailability _odevUygun(Person child, PersonDevelopment dev) {
    if (!dev.isStudent) {
      return InteractionAvailability.blocked(
        '${child.firstName} şu an okula gitmiyor.',
      );
    }
    if (dev.university != null) {
      return InteractionAvailability.blocked(
        '${child.firstName} üniversitede; derslerini kendi çalışıyor.',
      );
    }
    return const InteractionAvailability.allowed();
  }

  /// Harçlık verilebilir mi?
  ///
  /// Para gerçekten el değiştirmeyecekse düğme açılmaz (ECO-001):
  /// cüzdanda o kadar yoksa gerekçesi yazılır.
  InteractionAvailability _harclikUygun(GameState state, Person child) {
    if (child.age < prototypeOnlyAllowanceMinAge) {
      return InteractionAvailability.blocked(
        '${child.firstName} harçlık harcayacak yaşta değil.',
      );
    }
    final int tutar = _harclikTutari(child);
    if (state.player.wallet < tutar) {
      return InteractionAvailability.blocked(
        'Harçlık için ${trMoney(tutar)} gerekiyor.',
      );
    }
    return const InteractionAvailability.allowed();
  }

  /// Hobiye yazdırılabilir mi?
  InteractionAvailability _hobiUygun(
    GameState state,
    Person child,
    PersonDevelopment dev,
  ) {
    if (child.age < prototypeOnlyHobbyMinAge) {
      return InteractionAvailability.blocked(
        '${child.firstName} bir kursa yazılacak yaşta değil.',
      );
    }
    if (child.age > prototypeOnlyHobbyMaxAge) {
      return InteractionAvailability.blocked(
        '${child.firstName} kendi uğraşını kendisi seçiyor.',
      );
    }
    if (_bosHobiler(dev).isEmpty) {
      return InteractionAvailability.blocked(
        '${child.firstName} zaten uğraşabileceği kadar işin içinde.',
      );
    }
    if (state.player.wallet < prototypeOnlyHobbyCost) {
      return InteractionAvailability.blocked(
        'Kurs ücreti ${trMoney(prototypeOnlyHobbyCost)}; cüzdanında bu '
        'kadar yok.',
      );
    }
    return const InteractionAvailability.allowed();
  }

  /// Çocuğun henüz edinmediği ilgi alanları.
  ///
  /// Katalog **çocuğun kendi ilerleme dosyasından** okunur
  /// (`ChildProgression.prototypeOnlyInterests`); ikinci bir liste
  /// uydurulmadı.
  List<String> _bosHobiler(PersonDevelopment dev) {
    if (dev.interests.length >= ChildProgression.prototypeOnlyMaxInterests) {
      return const <String>[];
    }
    return ChildProgression.prototypeOnlyInterests
        .where((String i) => !dev.interests.contains(i))
        .toList(growable: false);
  }

  /// Bu çocuğa verilecek yıllık harçlık.
  int _harclikTutari(Person child) {
    final SchoolLevel? kademe = child.development?.schoolLevel;
    return prototypeOnlyAllowanceBySchool[kademe] ??
        prototypeOnlyAllowanceDefault;
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
  /// Oyuncunun bu kişiye alabileceği hediyeler (D-134).
  ///
  /// Arayüz bu listeyi gösterir; listede olmayan hediye seçilemez.
  List<GiftItem> giftOptions(GameState state, Person person) =>
      _giftsPlayerCanBuy(state, person);

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
  /// [giftId] verilirse hediye **oyuncunun seçtiği** olur (D-134).
  ///
  /// Verilmezse eskisi gibi uygun hediyelerden biri rastgele seçilir;
  /// eski çağrı yolları bozulmaz.
  InteractionResult perform({
    required GameState state,
    required String personId,
    required InteractionKind kind,
    required Random rng,
    String? giftId,
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

    // Hızlı artan ret tablosu **isteme** içindir (istismar koruması);
    // veren taraf için geçerli değil (Paket BK/3-BK/5 düzeltmesi:
    // harçlık ve kurs `transfersResource` olduğu için yanlış tabloya
    // düşüyordu ve zar tutarsa reddedilebiliyordu — çocuk harçlığı
    // "reddetmez").
    final List<double> refusalTable =
        kind.transfersResource && !kind.playerGives
            ? prototypeOnlyAskRefusalChance
            : prototypeOnlyRefusalChance;
    final double refusalChance =
        refusalTable[min(done, refusalTable.length - 1)];

    // Oyuncunun verdiği türler reddedilmez (D-020 reddi isteme için
    // yazdı). Reddedilebilen çocuk eylemleri ödev ve kuraldır.
    if (!kind.playerGives && rng.chance(refusalChance)) {
      return _refuse(state: state, person: person, kind: kind, rng: rng);
    }
    return _accept(
      state: state,
      person: person,
      kind: kind,
      rng: rng,
      done: done,
      giftId: giftId,
    );
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
    String? giftId,
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
        // Oyuncu bir hediye seçtiyse o alınır (D-134). Seçim listede
        // yoksa (parası yetmiyor, yaşa uygun değil) sahte bir hediye
        // uydurulmaz: uygunlardan biri seçilir.
        verilenHediye = giftId == null
            ? uygun[rng.nextInt(uygun.length)]
            : uygun.firstWhere(
                (GiftItem g) => g.id == giftId,
                orElse: () => uygun[rng.nextInt(uygun.length)],
              );
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
      // --- Paket BK/3: çocuğa özel eylemler -------------------------
      //
      // Harçlık ve kurs ücreti oyuncunun **kendi cüzdanından** çıkar
      // (ECO-001). Tutar aynı yıl tekrarında eriyor: `factor`, dördüncü
      // harçlığın hem faydasını hem tutarını küçültür — "her yıl değil,
      // her tıklamada para" olmasın.
      case InteractionKind.harclikVer:
        moneyDelta = -_scaled(_harclikTutari(person), factor);
        if (moneyDelta == 0) {
          return _refuse(
            state: state,
            person: person,
            kind: kind,
            rng: rng,
            noNewBenefit: true,
          );
        }
      case InteractionKind.hobiyeYazdir:
        moneyDelta = -prototypeOnlyHobbyCost;
      case InteractionKind.odevYardim:
      case InteractionKind.kuralKoy:
      case InteractionKind.vakitGecir:
      case InteractionKind.sohbet:
      // Çocuğu konuşmak para ya da eşya devretmez (§25): co-parenting
      // bir gelir kapısı değil.
      case InteractionKind.cocukKonus:
        break;
    }

    // Paket BK/3: çocuğa özel eylemin **çocuğun kendi kaydındaki**
    // etkisi. Oyuncunun statları ayrı; buradaki değişim çocuğun zekâsı,
    // keyfi, birikimi ve ilgi alanlarıdır. Metinden **önce** hesaplanır:
    // hangi hobiye yazıldığı sonuç cümlesinde geçiyor.
    final _ChildEffect? cocukEtkisi = _childEffect(
      state: state,
      child: person,
      kind: kind,
      factor: factor,
      rng: rng,
      moneySpent: -moneyDelta,
    );

    // Hediye beğenisi (D-134). Faho'nun isteği: "tavla hediye edersem
    // beğenmesin". Yanlış hediye para götürür, yakınlık getirmez.
    GiftReaction? tepki;
    int hediyeBonu = 0;
    if (verilenHediye != null) {
      tepki = giftReactionFor(
        gift: verilenHediye,
        relation: person.relation,
        receiverAge: person.age,
      );
      switch (tepki) {
        case GiftReaction.sevindi:
          // prototypeOnly: doğru hediye yakınlığı belirgin biçimde artırır.
          hediyeBonu = 6;
        case GiftReaction.idare:
          hediyeBonu = 0;
        case GiftReaction.begenmedi:
          // Yakınlık kazancı silinir ve bir miktar da geri gider; para
          // yine harcanmıştır.
          hediyeBonu = -(bondDelta + 2);
      }
    }
    final int hediyeliBond = bondDelta + hediyeBonu;
    final int hediyeliHappiness = tepki == GiftReaction.begenmedi
        ? happinessDelta - 2
        : happinessDelta;

    final bool noNewBenefit = hediyeliBond == 0 &&
        hediyeliHappiness == 0 &&
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
      hobbyName: cocukEtkisi?.newInterest,
    );
    String metin = kind == InteractionKind.paraIste && moneyDelta > 0
        ? '$sahne Cüzdanına ${trMoney(moneyDelta)} girdi.'
        : sahne;
    // Çocuğa özel eylemlerde **ne kadar** para çıktığı cümlede yazar
    // (D-108): oyuncu cüzdanına bakmak zorunda kalmasın.
    if (moneyDelta < 0 && kind.childOnly) {
      metin = '$metin ${trMoney(-moneyDelta)} cüzdanından çıktı.';
    }
    // Tepki anlatının içine değil, **arkasına** yazılır: oyuncu ne
    // olduğunu görsün (D-127 §3, anlatı ile sonuç ayrı).
    if (tepki != null && verilenHediye != null) {
      metin = '$metin\n\n${giftReactionText(
        reaction: tepki,
        person: person,
        gift: verilenHediye,
      )}';
    }

    final InteractionOutcome outcome = InteractionOutcome(
      kind: kind,
      personId: person.id,
      accepted: true,
      text: metin,
      bondDelta: hediyeliBond,
      happinessDelta: hediyeliHappiness,
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
          ..[person.id] = state.player.age
          // Kuralın konulduğu yıl gibi işaretler (Paket BK/3).
          ..addAll(cocukEtkisi?.marks ?? const <String, int>{});

    final GameState next = _apply(
      state,
      person,
      outcome,
      childEffect: cocukEtkisi,
    ).copyWith(
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
  GameState _apply(
    GameState state,
    Person person,
    InteractionOutcome outcome, {
    _ChildEffect? childEffect,
  }) {
    final List<Person> people = state.people
        .map(
          (Person p) => p.id == person.id
              ? childEffect == null
                  ? p.copyWith(bond: (p.bond + outcome.bondDelta).clamp(0, 100))
                  : childEffect
                      .applyTo(p)
                      .copyWith(bond: (p.bond + outcome.bondDelta).clamp(0, 100))
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

/// Çocuğa özel bir eylemin çocuğun kaydındaki karşılığı (Paket BK/3).
///
/// Ayrı bir sınıf olmasının sebebi: etki **tek yerde** uygulanmalı
/// (`_apply`), ama hesabı türüne göre değişiyor. Böylece çocuğun kaydını
/// iki ayrı yerden değiştiren bir kod yolu oluşmuyor.
class _ChildEffect {
  const _ChildEffect({
    required this.development,
    this.happinessDelta = 0,
    this.newInterest,
    this.marks = const <String, int>{},
  });

  /// Çocuğun güncellenmiş gelişim kaydı.
  final PersonDevelopment development;

  /// Çocuğun **kendi** keyfindeki değişim (`Person.happiness`, D-074).
  final int happinessDelta;

  /// Bu eylemle edinilen yeni ilgi alanı; yoksa `null`.
  final String? newInterest;

  /// `lastInteractionAge` içine yazılacak işaretler (ör. kural yılı).
  final Map<String, int> marks;

  Person applyTo(Person child) => child.copyWith(
        development: development,
        happiness: (child.happiness + happinessDelta).clamp(0, 100),
      );
}

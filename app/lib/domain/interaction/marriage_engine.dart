import 'dart:math';

import '../effects/effect_diff.dart';
import 'divorce_settlement.dart';
import '../life/notices.dart';
import '../models/game_state.dart';
import '../models/owned_item.dart';
import '../models/pending_notice.dart';
import '../models/pending_wedding.dart';
import '../../data/wedding_catalog.dart';
import '../models/life_log.dart';
import '../models/marriage.dart';
import '../models/person.dart';
import '../models/relation.dart';
import '../../data/event_pool.dart';
import '../../text/turkish_text.dart';

/// Aile eylemlerinin (evlilik, boşanma, çocuk) ortak sonucu.
class FamilyOutcome {
  const FamilyOutcome({required this.applied, required this.text});

  /// Eylem gerçekten uygulandı mı? `false` ise [text] gerekçedir.
  final bool applied;
  final String text;
}

class FamilyResult {
  const FamilyResult({required this.state, required this.outcome});

  final GameState state;
  final FamilyOutcome outcome;
}

/// Evlilik ve boşanma (Paket E1, `docs/GENERATION_PROPOSAL.md`).
///
/// Temel kurallar:
/// - **Kişi kimliği değişmez.** Sevgili evlenince aynı kimlikle `es` olur,
///   boşanınca aynı kimlikle `eskiEs` olur; kayıt hiçbir aşamada silinmez
///   ve ikinci kez üretilmez (D-029, D-038).
/// - Evlilik **gerçek bir kayıttır**: [GameState.marriage]. Miras kuralının
///   beklediği "gerçek birliktelik kaydı" budur (D-037); sevgili hiçbir
///   durumda eş sayılmaz.
/// - Evlenmek **kendi haneni kurmaktır**: eş haneye katılır, oyuncu artık
///   ailesinin yanında sayılmaz (D-043 ile uyumlu).
///
/// Bütün yaş, yakınlık ve tutar değerleri `prototypeOnly`'dir; onaylanmış
/// oyun kuralı değildir (`docs/DESIGN_REVIEW_QUEUE.md`, Q-063).
class MarriageEngine {
  const MarriageEngine();

  /// prototypeOnly: evlenmek için asgari yaş (iki taraf için de).
  static const int prototypeOnlyMinAge = 18;

  /// prototypeOnly: **teklif edebilmek** için gereken asgari yakınlık.
  ///
  /// Eşik teklif için düşüktür: kötü giden bir ilişkide de teklif
  /// edilebilir, ama kabul edilme ihtimali düşüktür (D-048).
  static const int prototypeOnlyMinBond = 45;

  /// prototypeOnly: teklifin kesin kabul edildiği yakınlık.
  static const int prototypeOnlyCertainBond = 95;

  /// prototypeOnly: aynı kişiye yeniden teklif için beklenecek yıl.
  static const int prototypeOnlyProposalCooldown = 2;

  /// prototypeOnly: reddedilen teklifin yakınlık ve mutluluk etkisi.
  static const int prototypeOnlyRejectBondLoss = 6;
  static const int prototypeOnlyRejectHappiness = -8;

  /// prototypeOnly: daha önce reddedilmiş olmanın kabul ihtimaline etkisi.
  static const double prototypeOnlyPreviousRejectionPenalty = 0.15;

  /// prototypeOnly: kabul ihtimalinin alt ve üst sınırı.
  static const double prototypeOnlyMinAcceptChance = 0.08;
  static const double prototypeOnlyMaxAcceptChance = 0.95;

  /// prototypeOnly: **artık kullanılmıyor** (Paket 25).
  ///
  /// Tek ve sabit bir nikâh masrafı vardı; sevgilisi olan hayatların
  /// çoğu bu duvara takılıp hiç evlenemiyordu (ölçüm: 44 hayattan 25'i
  /// teklif verebilecek duruma geliyordu, engel neredeyse hep paraydı).
  /// Yerine cüzdana göre seçilen düğün geldi (`kWeddingStyles`). Sabit
  /// alan, eski kayıtlarla ve testlerle uyum için duruyor.
  @Deprecated('Paket 25: yerine kWeddingStyles geldi.')
  static const int prototypeOnlyWeddingCost = 240000;

  /// prototypeOnly: boşanmada eşe kalan nakit payı.
  ///
  /// Eşya ve mülk paylaşımı artık **vardır** (D-075): evlilik içinde
  /// satın alınarak edinilen eşyalar `DivorceSettlement` ile bölünür.
  /// Nakit payı bu orandadır; nakdin ne kadarının evlilik içinde
  /// biriktiği izlenmediği için oran olduğu gibi bırakıldı (Q-118).
  static const double prototypeOnlyDivorceShare = 0.25;

  /// prototypeOnly: evlilik ve boşanmanın mutluluk etkisi.
  static const int prototypeOnlyWeddingHappiness = 12;
  static const int prototypeOnlyDivorceHappiness = -15;

  /// prototypeOnly: nikâhta yakınlığa eklenen değer.
  static const int prototypeOnlyWeddingBond = 10;

  /// Bu kişiyle evlenmeye engel; engel yoksa boş metin.
  String marryBlockReason(GameState state, Person person) {
    if (state.isMarried) return 'Zaten evlisin.';
    // İkinci evlilik açıldı (Paket 36). Eski kayıt **silinmez**:
    // düğünde `pastMarriages` listesine taşınır, böylece "kiminle, kaç
    // yaşında evlenildi, nasıl bitti" bilgisi hayat boyu durur.
    if (!person.isAlive) return 'Bu kişi hayatta değil.';
    if (person.relation != RelationType.sevgili) {
      return 'Yalnızca sevgilinle evlenebilirsin.';
    }
    if (state.player.age < prototypeOnlyMinAge) {
      return '$prototypeOnlyMinAge yaşından itibaren evlenebilirsin.';
    }
    if (person.age < prototypeOnlyMinAge) {
      return '${person.firstName} evlenmek için henüz çok genç.';
    }
    if (person.bond < prototypeOnlyMinBond) {
      return 'İlişkiniz evlilik teklifi için yeterince yakın değil '
          '(yakınlık ${person.bond}, gereken $prototypeOnlyMinBond).';
    }
    // **Para koşulu kaldırıldı (Paket 25, Faho'nun kararı).** Teklif
    // etmek bedelsizdir. Para, "evet" alındıktan sonra **düğün
    // seçiminde** devreye girer ve orada da her cüzdana uyan bir
    // seçenek vardır (`kWeddingStyles`). Böylece "paran yoksa hiç
    // evlenemezsin" duvarı kalkar.
    return '';
  }

  /// Düğünü yapar ve evliliği kurar (Paket 25).
  ///
  /// Kişi listeden çıkarılmaz, yeni kişi üretilmez: aynı kimlik `es` olur.
  /// Masraf **seçilen düğüne** göredir; bedelsiz seçenek her zaman
  /// vardır, yani "evet" almış hiçbir oyuncu evlenemeden kalmaz.
  FamilyResult holdWedding(GameState state, String styleId) {
    final PendingWedding? bekleyen = state.pendingWedding;
    if (bekleyen == null) {
      return _blocked(state, 'Bekleyen bir düğün yok.');
    }
    final WeddingStyle? stil = weddingStyleById(styleId);
    if (stil == null) return _blocked(state, 'Böyle bir düğün seçeneği yok.');
    if (stil.prototypeOnlyCost > state.player.wallet) {
      return _blocked(
        state,
        '${stil.label} için ${trMoney(stil.prototypeOnlyCost)} gerekiyor; '
        'cüzdanında yeterli para yok.',
      );
    }
    final Person? partner = state.personById(bekleyen.spouseId);
    if (partner == null) {
      return _blocked(state, 'Bu kişi kayıtlarda yok.');
    }
    if (!partner.isAlive) {
      // "Evet" almıştın ama düğünden önce vefat etti; kayıt silinmez,
      // bekleyen düğün kapanır.
      return FamilyResult(
        state: state.copyWith(pendingWedding: null),
        outcome: FamilyOutcome(
          applied: true,
          text: '${partner.firstName} ile düğün gerçekleşemedi.',
        ),
      );
    }

    // Önceki eş, aynı kimlikle **eski eş** olur (Paket 43).
    //
    // Boşanmada bu zaten yapılıyordu; eşini kaybedip yeniden evlenen
    // oyuncuda yapılmıyordu ve kayıtta iki kişi birden "Eş" diye
    // görünüyordu. Kayıt silinmez, yalnızca bağ etiketi düzelir.
    final List<Person> people = state.people.map((Person p) {
      if (p.id == partner.id) {
        return p.copyWith(
          relation: RelationType.es,
          inPlayerHousehold: true,
          bond: (p.bond + stil.prototypeOnlyBond).clamp(0, 100),
        );
      }
      if (p.relation == RelationType.es) {
        return p.copyWith(relation: RelationType.eskiEs);
      }
      return p;
    }).toList(growable: false);

    final String metin = stil.prototypeOnlyCost == 0
        ? '${partner.fullName} ile ${stil.logText}'
        : '${partner.fullName} ile ${stil.logText} '
            'Masrafı ${trMoney(stil.prototypeOnlyCost)} tuttu.';

    final GameState next = state.copyWith(
      people: List<Person>.unmodifiable(people),
      player: state.player.copyWith(
        wallet: state.player.wallet - stil.prototypeOnlyCost,
        stats: state.player.stats.copyWith(
          happiness: (state.player.stats.happiness +
                  stil.prototypeOnlyHappiness)
              .clamp(0, 100),
          charisma: (state.player.stats.charisma +
                  stil.prototypeOnlyCharisma)
              .clamp(0, 100),
        ),
        // Ün kapalıysa **açılmaz** (D-027): düğün Ün doğurmaz.
        fame: state.player.fameUnlocked && stil.prototypeOnlyFame > 0
            ? (state.player.fame! + stil.prototypeOnlyFame).clamp(0, 100)
            : null,
      ),
      marriage: Marriage(
        spouseId: partner.id,
        marriedAtAge: state.player.age,
        status: MarriageStatus.evli,
      ),
      // Sona ermiş önceki evlilik geçmişe taşınır, üzerine yazılmaz.
      pastMarriages: _archive(state),
      // Evlenmek kendi haneni kurmaktır: artık ailenin yanında sayılmazsın.
      movedOut: true,
      pendingWedding: null,
      storyFlags: <String>{...state.storyFlags, StoryFlags.evlendi},
    );

    return FamilyResult(
      state: _log(next, metin, LogCategory.aile),
      outcome: FamilyOutcome(applied: true, text: metin),
    );
  }

  /// Sona ermiş mevcut evlilik kaydını geçmişe taşır (Paket 36).
  ///
  /// Yürüyen bir evlilik **asla** arşivlenmez: oraya ancak boşanmış ya da
  /// eşini kaybetmiş biri gelir, çünkü yürüyen evlilikte ikinci evlilik
  /// zaten engellidir. Aynı kayıt iki kez eklenmez.
  static List<Marriage> _archive(GameState state) {
    final Marriage? onceki = state.marriage;
    if (onceki == null || onceki.isActive) return state.pastMarriages;
    final bool zatenVar = state.pastMarriages.any(
      (Marriage m) =>
          m.spouseId == onceki.spouseId &&
          m.marriedAtAge == onceki.marriedAtAge,
    );
    if (zatenVar) return state.pastMarriages;
    return List<Marriage>.unmodifiable(<Marriage>[
      ...state.pastMarriages,
      onceki,
    ]);
  }

  /// Sevgiliyle **doğrudan** evlenir (düğün seçimi olmadan).
  ///
  /// Yalnızca bedelsiz nikâh uygulanır. Arayüz akışı artık teklif →
  /// düğün seçimi biçimindedir; bu yol eski çağrılar ve testler için
  /// durur.
  FamilyResult marry(GameState state, String personId) {
    final Person? partner = state.personById(personId);
    if (partner == null) {
      return _blocked(state, 'Bu kişi kayıtlarda yok.');
    }
    final String engel = marryBlockReason(state, partner);
    if (engel.isNotEmpty) return _blocked(state, engel);
    return holdWedding(
      state.copyWith(
        pendingWedding: PendingWedding(
          spouseId: personId,
          acceptedAtAge: state.player.age,
        ),
      ),
      kFreeWedding.id,
    );
  }

  // ------------------------------------------------------------------
  // Evlenme teklifi (D-048)
  // ------------------------------------------------------------------

  /// Teklif etmeye engel; engel yoksa boş metin.
  ///
  /// Evlilik koşullarına ek olarak **bekleme süresi** aranır: reddedilen
  /// teklif kayda girer ve aynı kişiye hemen yeniden teklif edilemez.
  String proposeBlockReason(GameState state, Person person) {
    final String engel = marryBlockReason(state, person);
    if (engel.isNotEmpty) return engel;

    final int? sonTeklif = state.lastProposalAge(person.id);
    if (sonTeklif != null &&
        state.player.age - sonTeklif < prototypeOnlyProposalCooldown) {
      final int kalan =
          prototypeOnlyProposalCooldown - (state.player.age - sonTeklif);
      return 'Teklifin üzerinden yeterli zaman geçmedi; $kalan yıl sonra '
          'yeniden deneyebilirsin.';
    }
    return '';
  }

  /// prototypeOnly: teklifin kabul edilme ihtimali.
  ///
  /// Tek bir sayıya indirgenmez: yakınlığın yanında **ilişki geçmişi** de
  /// hesaba katılır (daha önce reddedilmiş bir teklif ihtimali düşürür).
  double prototypeOnlyAcceptChance(GameState state, Person person) {
    final double yakinlik = ((person.bond - prototypeOnlyMinBond) /
            (prototypeOnlyCertainBond - prototypeOnlyMinBond))
        .clamp(0.0, 1.0);
    double sans = prototypeOnlyMinAcceptChance +
        yakinlik * (prototypeOnlyMaxAcceptChance - prototypeOnlyMinAcceptChance);

    // Geçmişte reddedilmiş bir teklif varsa ikna etmek zorlaşır.
    if (state.lastProposalAge(person.id) != null) {
      sans -= prototypeOnlyPreviousRejectionPenalty;
    }
    // Uzun süredir görüşülmeyen sevgili "evet" demeye daha uzaktır.
    final int? sonTemas = state.lastInteractionAge[person.id];
    if (sonTemas != null && state.player.age - sonTemas >= 3) {
      sans -= 0.1;
    }
    return sans.clamp(
      prototypeOnlyMinAcceptChance,
      prototypeOnlyMaxAcceptChance,
    );
  }

  /// Evlenme teklifi eder (D-048).
  ///
  /// Kabul edilirse kişi **aynı kimlikle** eşe dönüşür. Reddedilirse
  /// ilişki **zorunlu olarak bitmez**: kısa bir yanıt ve gerçekten
  /// uygulanan bir yakınlık/mutluluk etkisi olur. Yanıt kayda girer;
  /// oyunu yeniden yükleyerek sonuç değiştirilemez.
  FamilyResult propose(
    GameState state,
    String personId,
    Random rng, {
    String styleId = 'sade',
  }) {
    final Person? partner = state.personById(personId);
    if (partner == null) return _blocked(state, 'Bu kişi kayıtlarda yok.');

    final String engel = proposeBlockReason(state, partner);
    if (engel.isNotEmpty) return _blocked(state, engel);

    final ProposalStyle? stil = proposalStyleById(styleId);
    if (stil == null) return _blocked(state, 'Böyle bir teklif seçeneği yok.');
    if (stil.prototypeOnlyCost > state.player.wallet) {
      return _blocked(
        state,
        '${stil.label} için ${trMoney(stil.prototypeOnlyCost)} gerekiyor; '
        'cüzdanında yeterli para yok.',
      );
    }

    // Hazırlık masrafı **her hâlükârda** ödenir: teklif reddedilse de
    // ayrılan masa, alınan bilet geri gelmez.
    final GameState odenmis = state.copyWith(
      player: state.player.copyWith(
        wallet: state.player.wallet - stil.prototypeOnlyCost,
      ),
    );

    final double sans =
        (prototypeOnlyAcceptChance(state, partner) + stil.prototypeOnlyAcceptBonus)
            .clamp(prototypeOnlyMinAcceptChance, prototypeOnlyMaxAcceptChance);
    final bool kabul = rng.nextDouble() < sans;
    final Map<String, int> teklifler = <String, int>{
      ...state.proposalAges,
      personId: state.player.age,
    };

    if (kabul) {
      // **Düğün ayrı bir adımdır (Paket 25).** "Evet" alındı; sıra
      // cüzdana göre düğün seçmekte. Bu bekleyen durum kayda girer,
      // yarıda kalmaz.
      final List<Person> people = odenmis.people
          .map((Person p) => p.id == personId
              ? p.copyWith(
                  bond: (p.bond + stil.prototypeOnlyBond).clamp(0, 100),
                )
              : p)
          .toList(growable: false);
      final String metin = '${partner.firstName} "evet" dedi. '
          'Sıra düğünde: bütçene göre nasıl bir düğün istediğini seç.';
      final GameState next = odenmis.copyWith(
        people: List<Person>.unmodifiable(people),
        proposalAges: Map<String, int>.unmodifiable(teklifler),
        player: odenmis.player.copyWith(
          stats: odenmis.player.stats.copyWith(
            happiness: (odenmis.player.stats.happiness +
                    stil.prototypeOnlyHappiness)
                .clamp(0, 100),
          ),
        ),
        pendingWedding: PendingWedding(
          spouseId: personId,
          acceptedAtAge: odenmis.player.age,
        ),
      );
      return FamilyResult(
        state: _log(next, metin, LogCategory.aile),
        outcome: FamilyOutcome(applied: true, text: metin),
      );
    }

    // Ret: ilişki bitmez, kayıt silinmez.
    final String metin = '${partner.firstName} hazır olmadığını söyledi. '
        'İlişkiniz bitmedi ama aranızda bir sessizlik kaldı.';
    final List<Person> people = odenmis.people
        .map((Person p) => p.id == personId
            ? p.copyWith(
                bond: (p.bond - prototypeOnlyRejectBondLoss).clamp(0, 100),
              )
            : p)
        .toList(growable: false);

    final GameState next = odenmis.copyWith(
      people: List<Person>.unmodifiable(people),
      proposalAges: Map<String, int>.unmodifiable(teklifler),
      player: odenmis.player.copyWith(
        stats: odenmis.player.stats.copyWith(
          happiness:
              odenmis.player.stats.happiness + prototypeOnlyRejectHappiness,
        ),
      ),
    );

    return FamilyResult(
      state: _log(next, metin, LogCategory.aile),
      outcome: FamilyOutcome(applied: true, text: metin),
    );
  }

  /// Boşanmaya engel; engel yoksa boş metin.
  String divorceBlockReason(GameState state) {
    if (!state.isMarried) return 'Şu anda evli değilsin.';
    return '';
  }

  /// Boşanır: eş **aynı kimlikle** eski eş olur.
  ///
  /// Nakdin bir bölümü ve evlilik içinde edinilen malların yarısına
  /// yakını eşe kalır (D-075). Sonuç yalnızca günlüğe yazılmaz, ekranda
  /// **bildirim** olarak gösterilir. Çocuklar oyuncunun hanesinde kalır;
  /// velayet kuralları karar kuyruğundadır.
  FamilyResult divorce(GameState state) {
    final String engel = divorceBlockReason(state);
    if (engel.isNotEmpty) return _blocked(state, engel);

    final Person spouse = state.spouse!;

    // Mal paylaşımı (D-075): evlilik içinde **satın alınarak** edinilen
    // eşyalar bölünür; evlilikten önceki, miras ve hediye eşya kişisel
    // maldır ve paylaşıma girmez.
    final DivorceSettlement paylasim = DivorceSettlement.compute(
      items: state.items,
      marriedAtAge: state.marriage!.marriedAtAge,
      wallet: state.player.wallet,
      cashShare: prototypeOnlyDivorceShare,
    );
    final int pay = paylasim.cashToSpouse;
    final Set<String> gidenler = <String>{
      for (final OwnedItem i in paylasim.toSpouse) i.id,
    };

    final List<Person> people = state.people
        .map((Person p) => p.id == spouse.id
            ? p.copyWith(
                relation: RelationType.eskiEs,
                inPlayerHousehold: false,
                // Eşe geçen eşyalar onun kaydında görünür; kaybolmaz.
                estate: List<String>.unmodifiable(<String>[
                  ...p.estate,
                  for (final OwnedItem i in paylasim.toSpouse) i.type.name,
                ]),
              )
            : p)
        .toList(growable: false);

    final List<String> satirlar = paylasim.summaryLines(spouse.firstName);
    final String metin = <String>[
      '${spouse.fullName} ile boşandın.',
      if (pay > 0) 'Anlaşma gereği ${trMoney(pay)} cüzdanından çıktı.',
      ...satirlar,
      'Kaydı İlişkiler bölümünde eski eş olarak kalıyor.',
    ].join(' ');

    final GameState next = state.copyWith(
      people: List<Person>.unmodifiable(people),
      items: List<OwnedItem>.unmodifiable(
        state.items.where((OwnedItem i) => !gidenler.contains(i.id)),
      ),
      player: state.player.copyWith(
        wallet: state.player.wallet - pay,
        stats: state.player.stats.copyWith(
          happiness: (state.player.stats.happiness +
                  prototypeOnlyDivorceHappiness)
              .clamp(0, 100),
        ),
      ),
      marriage: state.marriage!.copyWith(
        status: MarriageStatus.bosandi,
        endedAtAge: state.player.age,
      ),
      storyFlags: <String>{
        ...state.storyFlags.where(
          (String f) => f != StoryFlags.romantikIliskide,
        ),
        StoryFlags.bosandi,
        StoryFlags.romantikBitti,
      },
    );

    GameState sonDurum = _log(next, metin, LogCategory.aile);

    // Boşanma ekranda bildirilir (D-075): günlüğe satır atmak yetmiyordu.
    // Satırlar durumun öncesi/sonrası farkından değil, uygulanan
    // paylaşımdan gelir; yazan her kalem gerçekten el değiştirmiştir.
    sonDurum = Notices.enqueue(sonDurum, <PendingNotice>[
      PendingNotice(
        id: 'bosanma-${spouse.id}-${state.player.age}',
        kind: NoticeKind.bosanma,
        age: state.player.age,
        title: 'Boşandınız',
        text: metin,
        personId: spouse.id,
        money: pay,
        itemNames: List<String>.unmodifiable(
          paylasim.toSpouse.map((OwnedItem i) => i.type.name),
        ),
        happinessDelta: sonDurum.player.stats.happiness -
            state.player.stats.happiness,
        effects: diffAppliedEffects(state, sonDurum),
      ),
    ]);

    return FamilyResult(
      state: sonDurum,
      outcome: FamilyOutcome(applied: true, text: metin),
    );
  }

  /// Eş vefat ettiyse evlilik kaydını **dul** durumuna geçirir.
  ///
  /// Kayıt silinmez; miras hesabı hâlâ gerçek bir evliliğe bakar.
  GameState settleWidowhood(GameState state, int age) {
    final Marriage? kayit = state.marriage;
    if (kayit == null || !kayit.isActive) return state;
    final Person? es = state.personById(kayit.spouseId);
    if (es == null || es.isAlive) return state;

    return state.copyWith(
      marriage: kayit.copyWith(
        status: MarriageStatus.dul,
        endedAtAge: age,
      ),
      storyFlags: <String>{
        ...state.storyFlags.where(
          (String f) => f != StoryFlags.romantikIliskide,
        ),
      },
    );
  }

  FamilyResult _blocked(GameState state, String reason) => FamilyResult(
        state: state,
        outcome: FamilyOutcome(applied: false, text: reason),
      );

  GameState _log(GameState state, String text, LogCategory category) =>
      state.copyWith(
        log: List<LifeLogEntry>.unmodifiable(<LifeLogEntry>[
          ...state.log,
          LifeLogEntry(
            age: state.player.age,
            text: text,
            category: category,
          ),
        ]),
      );
}

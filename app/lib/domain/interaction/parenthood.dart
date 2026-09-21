import 'dart:math';

import '../../data/event_pool.dart';
import '../../data/name_pool.dart';
import '../generation/random_util.dart';
import '../models/education.dart';
import '../models/game_state.dart';
import '../models/gender.dart';
import '../models/life_log.dart';
import '../models/person.dart';
import '../models/person_development.dart';
import '../generation/trait_inheritance.dart';
import '../models/relation.dart';
import '../models/wealth.dart';
import 'marriage_engine.dart';
import '../../text/turkish_text.dart';

/// Çocuk sahibi olmak (Paket E2, `docs/GENERATION_PROPOSAL.md`).
///
/// Kurallar:
/// - Çocuk **isteğe bağlıdır**; kendiliğinden olmaz, oyuncu seçer.
/// - Çocuk kaydı diğer bütün kişilerle **aynı** yapıyı kullanır: kalıcı
///   kimlik, yaş, hane, ekonomik durum, ölüm (D-038). Paralel bir "çocuk
///   sistemi" kurulmaz.
/// - Çocuklar oyuncuyla birlikte yaşlanır, büyüyünce hanenin dışına çıkar
///   ve miras kurallarına (D-037) dâhil olur.
///
/// Yaş sınırları, çocuk sayısı ve tutarlar `prototypeOnly`'dir
/// (`docs/DESIGN_REVIEW_QUEUE.md`, Q-064).
class Parenthood {
  const Parenthood();

  /// prototypeOnly: çocuk sahibi olmak için asgari yaş.
  static const int prototypeOnlyMinAge = 18;

  /// prototypeOnly: çiftteki kadının çocuk sahibi olabileceği en ileri yaş.
  static const int prototypeOnlyMaxMotherAge = 45;

  /// prototypeOnly: çiftteki erkeğin çocuk sahibi olabileceği en ileri yaş.
  static const int prototypeOnlyMaxFatherAge = 60;

  /// prototypeOnly: bu prototipte en fazla çocuk sayısı.
  static const int prototypeOnlyMaxChildren = 4;

  /// prototypeOnly: evlilik dışı çocuk için gereken asgari yakınlık.
  ///
  /// Evlilik zorunlu değildir (D-047); ilişkinin gerçekten yürüdüğü bu
  /// eşikle aranır.
  static const int prototypeOnlyUnmarriedMinBond = 60;

  /// prototypeOnly: doğum ve hazırlık masrafı (₺).
  static const int prototypeOnlyBirthCost = 20000;

  /// prototypeOnly: yeni doğan çocuğun yakınlığı.
  static const int prototypeOnlyNewbornBond = 70;

  /// prototypeOnly: çocuk sahibi olmanın mutluluk etkisi.
  static const int prototypeOnlyBirthHappiness = 10;

  /// prototypeOnly: çocuğun hanenin dışına çıktığı yaş.
  static const int prototypeOnlyLeaveHomeAge = 25;

  /// prototypeOnly: hanedeki her çocuğun yıllık gideri için üst yaş.
  static const int prototypeOnlyDependentAge = 18;

  /// Çocuğun diğer biyolojik ebeveyni olabilecek kişi.
  ///
  /// Evlilik zorunlu değildir (D-047): eş yoksa **hayattaki sevgili**
  /// değerlendirilir. Akraba hiçbir durumda bu listeye girmez; yalnızca
  /// romantik bağlar sayılır.
  static Person? coParent(GameState state) {
    if (state.isMarried) return state.spouse;
    for (final Person p in state.people) {
      if (p.isAlive && p.relation == RelationType.sevgili) return p;
    }
    return null;
  }

  /// Çocuk sahibi olmaya engel; engel yoksa boş metin.
  String blockReason(GameState state) {
    final Person? partner = coParent(state);
    if (partner == null) {
      return 'Çocuk sahibi olmak için eşin ya da sevgilin olmalı.';
    }
    if (state.player.age < prototypeOnlyMinAge) {
      return '$prototypeOnlyMinAge yaşından itibaren çocuk sahibi '
          'olabilirsin.';
    }
    final Person spouse = partner;
    if (spouse.age < prototypeOnlyMinAge) {
      return '${spouse.firstName} bunun için henüz çok genç.';
    }
    // **Yakınlık eşiği kaldırıldı (Paket 25).** Çocuk artık "çocuk yap"
    // düğmesiyle değil, korunmadan yakınlaşmanın bir **ihtimali** olarak
    // geliyor. Böyle bir akışta yakınlık eşiği gebeliği sessizce
    // engeller; oyuncu neden olmadığını anlayamaz. Evlilik dışı çocuk
    // zaten serbesttir (D-047). Eşik sayısı `prototypeOnly`'ydi (Q-064);
    // kaldırılması Q-093'te sorulmuştur.

    // Yaş sınırı çiftteki kadına ve erkeğe ayrı uygulanır.
    final bool oyuncuKadin = state.player.gender == Gender.kadin;
    final int kadinYasi = oyuncuKadin ? state.player.age : spouse.age;
    final int erkekYasi = oyuncuKadin ? spouse.age : state.player.age;
    if (spouse.gender == state.player.gender) {
      // Aynı cinsiyetteki çiftlerde çocuk sahibi olma yolu (evlat edinme)
      // henüz tasarlanmadı; uydurma bir kural uygulanmaz (Q-064).
      return 'Bu çiftin çocuk sahibi olma yolu henüz tasarlanmadı.';
    }
    if (kadinYasi > prototypeOnlyMaxMotherAge ||
        erkekYasi > prototypeOnlyMaxFatherAge) {
      return 'Bu yaşta çocuk sahibi olma yolu prototipte kapalı; '
          'evlat edinme henüz tasarlanmadı.';
    }

    final List<Person> cocuklar = state.children;
    if (cocuklar.length >= prototypeOnlyMaxChildren) {
      return 'Bu prototipte en fazla $prototypeOnlyMaxChildren çocuk '
          'olabiliyor.';
    }
    // Aynı yıl ikinci bir bebek olmaz: bu yıl doğan çocuk henüz 0 yaşında.
    if (cocuklar.any((Person p) => p.age == 0)) {
      return 'Bu yıl bir bebeğiniz oldu; bir sonraki yaşta yeniden '
          'deneyebilirsin.';
    }
    // **Para engeli kaldırıldı (Paket 25).** "Paran yok, o yüzden
    // hamile kalmadın" diye bir şey yok. Masraf doğumda tahsil edilir ve
    // **cüzdanda ne varsa o kadarı** düşer; borç yazılmaz (Q-093).
    return '';
  }

  /// Yeni çocuk için çakışmayan kimlik.
  static String nextChildId(GameState state) {
    final Set<String> mevcut = <String>{for (final Person p in state.people) p.id};
    int n = state.children.length + 1;
    while (mevcut.contains('cocuk-$n')) {
      n++;
    }
    return 'cocuk-$n';
  }

  /// Çocuk sahibi olur: kalıcı kimlikli yeni bir kişi kaydı açılır.
  FamilyResult haveChild(GameState state, Random rng) {
    final String engel = blockReason(state);
    if (engel.isNotEmpty) {
      return FamilyResult(
        state: state,
        outcome: FamilyOutcome(applied: false, text: engel),
      );
    }

    final Gender gender =
        rng.nextBool() ? Gender.kadin : Gender.erkek;
    final Set<String> kullanilanIsimler = <String>{
      state.player.firstName,
      for (final Person p in state.people) p.firstName,
    };
    final List<String> havuz =
        gender == Gender.kadin ? kadinIsimleri : erkekIsimleri;
    String isim = rng.pick(havuz);
    final List<String> bos = havuz
        .where((String a) => !kullanilanIsimler.contains(a))
        .toList(growable: false);
    if (bos.isNotEmpty) isim = rng.pick(bos);

    // Soyadı: prototipte çocuk **babanın** soyadını alır. Evlenince eşin
    // soyadının değişip değişmeyeceği ayrı bir tasarım sorusudur (Q-063);
    // kimsenin kaydı bu yüzden değiştirilmez.
    final Person es = coParent(state)!;
    final String soyad = state.player.gender == Gender.erkek
        ? state.player.lastName
        : es.lastName;

    // Diğer biyolojik ebeveynin özellikleri bilinmiyorsa **bir kez**
    // oluşturulup kalıcı olarak saklanır; her doğumda yeniden çizilmez
    // (D-046).
    final Person esKaydi = TraitInheritance.ensureTraits(es, rng);

    final Person cocuk = Person(
      id: nextChildId(state),
      firstName: isim,
      lastName: soyad,
      gender: gender,
      relation: RelationType.cocuk,
      age: 0,
      isAlive: true,
      inPlayerHousehold: true,
      employment: EmploymentStatus.cocuk,
      // Çocuğun kendi ekonomik durumu yoktur; uydurma değer yazılmaz.
      wealth: null,
      bond: prototypeOnlyNewbornBond,
      // Çocuk, ailenin o sırada yaşadığı şehirde doğar; taşınma bu kaydı
      // değiştirmez (doğum şehri kalıcıdır, D-004 ile aynı ilke).
      city: state.player.currentCity,
      // Çocuk kendi hayatını yaşamaya doğduğu anda başlar (D-045):
      // özellikleri, eğitimi, işi ve birikimi kendi kaydında tutulur.
      development: PersonDevelopment(
        // Çocuğun hayatı arka planda gerçekten izlenir (D-045).
        tracksLife: true,
        // Başlangıç değerleri iki biyolojik ebeveynden kısmen gelir ve
        // doğumda **bir kez** çizilir (D-046).
        stats: TraitInheritance.newbornStats(
          rng: rng,
          first: state.player.stats,
          second: TraitInheritance.statsOf(esKaydi),
        ),
        milestones: <LifeMilestone>[
          LifeMilestone(age: 0, text: '$isim dünyaya geldi.'),
        ],
        // Diğer biyolojik ebeveyn: evli olunmasa da kayda geçer (D-047).
        otherParentId: esKaydi.id,
      ),
    );

    final String metin = gender == Gender.kadin
        ? '$isim adında bir kızınız oldu.'
        : '$isim adında bir oğlunuz oldu.';

    // Masraf **cüzdanda ne varsa o kadar** düşer; borç yazılmaz ve
    // bakiye eksiye inmez (Paket 25).
    final int odenen =
        prototypeOnlyBirthCost.clamp(0, state.player.wallet.clamp(0, 1 << 31));

    final GameState next = state.copyWith(
      people: List<Person>.unmodifiable(<Person>[
        for (final Person p in state.people)
          if (p.id == esKaydi.id) esKaydi else p,
        cocuk,
      ]),
      player: state.player.copyWith(
        wallet: state.player.wallet - odenen,
        stats: state.player.stats.copyWith(
          happiness:
              (state.player.stats.happiness + prototypeOnlyBirthHappiness)
                  .clamp(0, 100),
        ),
      ),
      storyFlags: <String>{
        ...state.storyFlags,
        StoryFlags.cocukSahibi,
        // Evlilik dışı doğum ayrı bir izdir; ileride olaylar buna bakabilir.
        if (!state.isMarried) StoryFlags.evlilikDisiCocuk,
      },
      log: List<LifeLogEntry>.unmodifiable(<LifeLogEntry>[
        ...state.log,
        LifeLogEntry(
          age: state.player.age,
          text: odenen >= prototypeOnlyBirthCost
              ? '$metin Doğum masrafı ${trMoney(odenen)} tuttu.'
              : '$metin Masrafı zor denkleştirdiniz; elinizdeki '
                  '${trMoney(odenen)} gitti.',
          category: LogCategory.aile,
        ),
      ]),
    );

    return FamilyResult(
      state: next,
      outcome: FamilyOutcome(applied: true, text: metin),
    );
  }

  /// Çocuğun yaşına karşılık gelen okul kademesi.
  ///
  /// Oyuncunun okul sistemi **kopyalanmaz**: çocuk için yalnızca kademe
  /// bilgisi tutulur, sınav ve tercih akışı yoktur. Yaş aralıkları
  /// `prototypeOnly`'dir (Q-064).
  static SchoolLevel? schoolLevelForAge(int age) {
    if (age >= 6 && age <= 9) return SchoolLevel.ilkokul;
    if (age >= 10 && age <= 13) return SchoolLevel.ortaokul;
    if (age >= 14 && age <= 17) return SchoolLevel.lise;
    return null;
  }

  /// Hanede bakılan (gideri oyuncuya ait) çocuklar.
  static List<Person> dependentChildren(GameState state) => state.people
      .where((Person p) =>
          p.relation == RelationType.cocuk &&
          p.isAlive &&
          p.inPlayerHousehold &&
          p.age < prototypeOnlyDependentAge)
      .toList(growable: false);
}

/// Üvey kardeş ve yarım kardeş (Paket AO, §9-§13).
///
/// İkisi **aynı şey değildir** ve oyun ikisini karıştırmaz:
///
/// * **Üvey kardeş** ([RelationType.uveyKardes]): üvey ebeveynin
///   **önceki** ilişkisinden olan çocuğu. Oyuncuyla kan bağı **yoktur**;
///   ortak biyolojik ebeveyni bulunmaz. Miras almaz (§17).
/// * **Yarım kardeş** ([RelationType.yariKardes]): anne ya da babanın
///   yeni eşinden **doğan** çocuk. Oyuncuyla **bir biyolojik ebeveyni
///   ortaktır**, yani kan bağı vardır ve ortak ebeveynin mirasına girer.
///
/// İkisi de gerçek [Person] kaydıdır: kalıcı kimlik, isim, yaş, cinsiyet,
/// şehir, hane ve yakınlık taşır. Hikâye metninde yaşayan isim değildir.
///
/// Bütün sayılar `prototypeOnly`'dir.
library;

import 'dart:math';

import '../../data/name_pool.dart';
import '../models/game_state.dart';
import '../models/gender.dart';
import '../models/life_log.dart';
import '../models/pending_notice.dart';
import '../models/person.dart';
import '../models/relation.dart';
import '../models/wealth.dart';
import 'random_util.dart';

abstract final class StepSiblings {
  /// prototypeOnly: üvey ebeveynin yanında çocuk getirme dağılımı (§10).
  ///
  /// **0 en yaygın seçenek.** Her yeni eş "yanında kesin iki çocukla"
  /// gelmez; çoğu insanın önceki ilişkisinden çocuğu yoktur.
  static const List<double> prototypeOnlyChildCountWeights = <double>[
    0.62, // 0 çocuk
    0.28, // 1 çocuk
    0.10, // 2 çocuk (nadir)
  ];

  /// prototypeOnly: üvey ebeveynin çocuk sahibi olabilmesi için en küçük
  /// yaşı. §10: "20 yaşındaki üvey ebeveyne 25 yaşında çocuk üretme."
  static const int prototypeOnlyMinParentAgeForChildren = 24;

  /// prototypeOnly: ebeveyn ile çocuğu arasındaki en küçük yaş farkı.
  static const int prototypeOnlyMinGenerationGap = 18;

  /// prototypeOnly: üvey kardeşin başlangıç yakınlığının tabanı (§11).
  ///
  /// Düşük: aynı eve gelmiş olmak insanları kardeş yapmaz, yabancı iki
  /// insan birbirini yeni tanıyor.
  static const int prototypeOnlyStartBondBase = 12;

  /// prototypeOnly: yarım kardeş doğumunun yıllık ihtimali (§12).
  static const double prototypeOnlyHalfSiblingChance = 0.10;

  /// prototypeOnly: üvey ebeveynin bu yaştan sonra çocuğu olmaz.
  static const int prototypeOnlyMaxBirthAge = 44;

  /// prototypeOnly: bir hayatta en çok kaç yarım kardeş doğar.
  static const int prototypeOnlyMaxHalfSiblings = 2;

  // =================================================================
  // §9-§11 — üvey kardeş
  // =================================================================

  /// Üvey ebeveynle birlikte gelen üvey kardeşleri üretir.
  ///
  /// [stepParent] yeni gelen üvey anne ya da üvey baba. Hiç çocuk
  /// gelmemesi **en olası** sonuçtur (§10).
  static List<Person> childrenOf({
    required GameState state,
    required Person stepParent,
    required int playerAge,
    required Random rng,
  }) {
    if (stepParent.age < prototypeOnlyMinParentAgeForChildren) {
      return const <Person>[];
    }
    final int sayi = rng.pickWeighted(
      <int>[0, 1, 2],
      prototypeOnlyChildCountWeights,
    );
    if (sayi == 0) return const <Person>[];

    // Üvey ebeveynin çocuğu olabileceği en büyük yaş: kendi yaşından
    // kuşak farkı kadar küçük (§43 — yaş tutarlılığı).
    final int enBuyukCocukYasi =
        stepParent.age - prototypeOnlyMinGenerationGap;
    if (enBuyukCocukYasi < 0) return const <Person>[];

    final Set<String> isimler = <String>{
      for (final Person p in state.people) p.firstName,
      state.player.firstName,
    };
    final Set<String> kimlikler = <String>{
      for (final Person p in state.people) p.id,
    };

    final List<Person> cocuklar = <Person>[];
    for (int i = 0; i < sayi; i++) {
      final Gender cinsiyet =
          rng.chance(0.5) ? Gender.kadin : Gender.erkek;
      final List<String> havuz =
          cinsiyet == Gender.kadin ? kadinIsimleri : erkekIsimleri;
      String ad = rng.pick(havuz);
      for (int d = 0; d < 30 && isimler.contains(ad); d++) {
        ad = rng.pick(havuz);
      }
      isimler.add(ad);

      String id = 'uveykardes-${stepParent.id}-$i';
      int ek = 0;
      while (kimlikler.contains(id)) {
        ek++;
        id = 'uveykardes-${stepParent.id}-$i-$ek';
      }
      kimlikler.add(id);

      final int yas = (rng.nextInt(enBuyukCocukYasi + 1)).clamp(0, 60);
      // DİKKAT: çalışma durumu ve meslek **tek** zardan gelir. İkisi için
      // ayrı zar atılırsa "işsiz ama mesleği var" çıkabiliyor ve
      // `Person` bunu assertion ile reddediyor.
      final bool calisiyor = yas >= 22 && rng.chance(0.7);
      // Oyunun kendi değişmezi: 6-17 yaş arası **herkes** öğrencidir
      // (`age_up_test`: "yaşa bağlı tutarlılık korunur"). Üvey kardeş de
      // bu kuralın dışında değil.
      //
      // 6 yaş altı **`cocuk`** olmalı, `issiz` değil: yıllık ilerleme
      // öğrenciliğe yalnızca `cocuk` durumundan geçiriyor
      // (`life_progression._agePerson`). `issiz` yazılırsa çocuk 6
      // yaşına gelince okula hiç başlamıyor.
      final EmploymentStatus durum = yas < 6
          ? EmploymentStatus.cocuk
          : yas < 18
              ? EmploymentStatus.ogrenci
              : calisiyor
                  ? EmploymentStatus.calisiyor
                  : EmploymentStatus.issiz;

      cocuklar.add(
        Person(
          id: id,
          firstName: ad,
          lastName: stepParent.lastName,
          gender: cinsiyet,
          relation: RelationType.uveyKardes,
          age: yas,
          isAlive: true,
          // Üvey ebeveyn nerede yaşıyorsa çocuğu da oradadır.
          inPlayerHousehold: stepParent.inPlayerHousehold,
          employment: durum,
          // İşsiz kişiye uydurma meslek yazılmaz.
          occupation:
              durum == EmploymentStatus.calisiyor ? rng.pick(meslekler) : null,
          // Kendi ekonomik durumu çocukken anlamsızdır; uydurulmaz.
          wealth: yas >= 22 ? stepParent.wealth : null,
          bond: _startBond(
            playerAge: playerAge,
            siblingAge: yas,
            sameHousehold: stepParent.inPlayerHousehold,
            stepParentBond: stepParent.bond,
            rng: rng,
          ),
          city: stepParent.city,
          // §9: üvey kardeşin biyolojik ebeveyni **üvey ebeveyndir**,
          // oyuncunun ebeveyni değil. Kan bağı buradan okunur ve
          // "kardeş mi?" sorusu tahminle değil kayıtla cevaplanır.
          motherId: stepParent.gender == Gender.kadin ? stepParent.id : null,
          fatherId: stepParent.gender == Gender.erkek ? stepParent.id : null,
        ),
      );
    }
    return cocuklar;
  }

  /// §11: üvey kardeşin başlangıç yakınlığı.
  ///
  /// Otomatik 80 değil. Yaş farkı, aynı evde olup olmamak, oyuncunun üvey
  /// ebeveyne tepkisi ve küçük bir rastgelelik belirler.
  static int _startBond({
    required int playerAge,
    required int siblingAge,
    required bool sameHousehold,
    required int stepParentBond,
    required Random rng,
  }) {
    double bag = prototypeOnlyStartBondBase.toDouble();
    // Yaşıt olmak yakınlaştırır; büyük yaş farkı uzaklaştırır.
    final int fark = (playerAge - siblingAge).abs();
    bag += switch (fark) {
      <= 3 => 10,
      <= 7 => 5,
      <= 12 => 0,
      _ => -4,
    };
    if (sameHousehold) bag += 8;
    // Oyuncu üvey ebeveyni benimsediyse çocuğuna da daha açık yaklaşır.
    bag += (stepParentBond - 20) / 5;
    bag += rng.nextInt(9) - 4;
    return bag.round().clamp(0, 45);
  }

  // =================================================================
  // §12, §13 — yarım kardeş
  // =================================================================

  /// Bu yıl bir yarım kardeş doğar mı? Doğarsa **gerçek kayıt** açar.
  ///
  /// "Üvey annenin bebeği oldu" yalnızca metin değildir (§13): yaşı 0
  /// olan yeni bir [Person] eklenir ve ortak biyolojik ebeveyn kaydı
  /// yazılır.
  static GameState maybeHalfSibling(GameState state, int newAge, Random rng) {
    if (state.deceased) return state;

    // Üvey ebeveyn var mı? Yarım kardeş **ondan** doğar.
    final Person? uvey = _firstOf(
      state,
      <RelationType>{RelationType.uveyAnne, RelationType.uveyBaba},
    );
    if (uvey == null || !uvey.isAlive) return state;
    if (uvey.age > prototypeOnlyMaxBirthAge) return state;

    // Ortak biyolojik ebeveyn: üvey **annenin** eşi oyuncunun babasıdır.
    final RelationType ortakTur = uvey.relation == RelationType.uveyAnne
        ? RelationType.baba
        : RelationType.anne;
    final Person? ortak = _firstOf(state, <RelationType>{ortakTur});
    if (ortak == null || !ortak.isAlive) return state;
    if (ortak.age > prototypeOnlyMaxBirthAge + 12) return state;

    final int mevcut = state.people
        .where((Person p) => p.relation == RelationType.yariKardes)
        .length;
    if (mevcut >= prototypeOnlyMaxHalfSiblings) return state;

    if (!rng.chance(prototypeOnlyHalfSiblingChance)) return state;

    final Gender cinsiyet = rng.chance(0.5) ? Gender.kadin : Gender.erkek;
    final List<String> havuz =
        cinsiyet == Gender.kadin ? kadinIsimleri : erkekIsimleri;
    final Set<String> isimler = <String>{
      for (final Person p in state.people) p.firstName,
      state.player.firstName,
    };
    String ad = rng.pick(havuz);
    for (int d = 0; d < 30 && isimler.contains(ad); d++) {
      ad = rng.pick(havuz);
    }
    final Set<String> kimlikler = <String>{
      for (final Person p in state.people) p.id,
    };
    String id = 'yarimkardes-${mevcut + 1}';
    int ek = 0;
    while (kimlikler.contains(id)) {
      ek++;
      id = 'yarimkardes-${mevcut + 1}-$ek';
    }

    final Person bebek = Person(
      id: id,
      firstName: ad,
      lastName: ortak.lastName,
      gender: cinsiyet,
      relation: RelationType.yariKardes,
      age: 0,
      isAlive: true,
      inPlayerHousehold: uvey.inPlayerHousehold,
      // Yeni doğan `cocuk` durumundadır; yıllık ilerleme onu 6 yaşında
      // öğrenciliğe geçirir. `issiz` yazılırsa okula hiç başlamaz.
      employment: EmploymentStatus.cocuk,
      wealth: null,
      // Yeni doğan bebekle bağ kurulmamıştır ama bebek düşmandan da
      // gelmez: küçük bir taban.
      bond: 25,
      city: ortak.city ?? state.player.currentCity,
      // §13: ortak biyolojik ebeveyn **kayda** giriyor. Hangi tarafın
      // ortak olduğu buradan kesin bilinir; miras (§17) ve akrabalık
      // (§16) bunu okur.
      motherId: uvey.gender == Gender.kadin ? uvey.id : ortak.id,
      fatherId: uvey.gender == Gender.erkek ? uvey.id : ortak.id,
    );

    final String iyelik = uvey.relation == RelationType.uveyAnne
        ? 'Üvey annenin'
        : 'Üvey babanın';
    final String metin = '$iyelik bebeği oldu: ${bebek.firstName}. '
        '${cinsiyet == Gender.kadin ? 'Yarım kız kardeşin' : 'Yarım erkek kardeşin'} '
        'dünyaya geldi.';

    GameState next = state.copyWith(
      people: List<Person>.unmodifiable(<Person>[...state.people, bebek]),
      log: List<LifeLogEntry>.unmodifiable(<LifeLogEntry>[
        ...state.log,
        LifeLogEntry(
          age: newAge,
          text: metin,
          category: LogCategory.aile,
          personId: bebek.id,
        ),
      ]),
    );
    next = next.queueNotice(
      PendingNotice(
        id: 'yarimkardes-${bebek.id}',
        kind: NoticeKind.aileDonum,
        age: newAge,
        title: 'Ailede yeni biri',
        text: '$metin\n\n'
            'Seninle bir ebeveyni ortak: kan bağınız var.',
        personId: bebek.id,
      ),
    );
    return next;
  }

  static Person? _firstOf(GameState state, Set<RelationType> turler) {
    for (final Person p in state.people) {
      if (turler.contains(p.relation)) return p;
    }
    return null;
  }
}

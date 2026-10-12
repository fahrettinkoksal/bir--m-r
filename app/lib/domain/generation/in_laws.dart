/// Eşin ailesi ve eşin önceki çocuğu (Paket AO, §18-§24).
///
/// İki ayrı şeyi kurar, ikisi de **gerçek [Person] kaydıdır**:
///
/// * **Üvey çocuk** ([RelationType.uveyCocuk], §18-§20): eşin önceki
///   ilişkisinden olan çocuğu. Her partnerin otomatik olarak geçmiş
///   çocuğu **yoktur**; yaş ve küçük bir rastgelelik belirler. Evlilik
///   kurulurken **en geç** bilinir (§19): "beş yıl sonra eşinin 12
///   yaşında çocuğu olduğunu öğrenmek" saçmalığı olmaz.
/// * **Kayınvalide / kayınpeder** ([RelationType.kayinvalide],
///   [RelationType.kayinpeder], §21-§24): eşin yaşayan ebeveynleri.
///   0, 1 ya da 2 kişi olabilir — hepsinin hayatta olması şart değil.
///
/// **Aynı kişi iki kez üretilmez** (§22, §37): kimlik eşin kimliğinden
/// türetilir, her yıl yeniden kurulmaz.
///
/// Bütün sayılar `prototypeOnly`'dir.
library;

import 'dart:math';

import '../../data/name_pool.dart';
import '../models/game_state.dart';
import '../models/gender.dart';
import '../models/life_log.dart';
import '../models/person.dart';
import '../models/relation.dart';
import '../models/wealth.dart';
import 'random_util.dart';

abstract final class InLaws {
  /// prototypeOnly: eşin önceki ilişkisinden çocuğu olma ihtimali (§18).
  ///
  /// Otomatik değil: çoğu partnerin geçmiş çocuğu yoktur.
  static const double prototypeOnlyStepChildChance = 0.18;

  /// prototypeOnly: eşin geçmiş çocuğu olabilmesi için en küçük yaşı.
  static const int prototypeOnlyMinSpouseAgeForChild = 26;

  /// prototypeOnly: eş ile çocuğu arasındaki en küçük yaş farkı (§43).
  static const int prototypeOnlyMinGenerationGap = 18;

  /// prototypeOnly: üvey çocuğun başlangıç yakınlığı (§20).
  ///
  /// Düşük: üvey çocuk "kendi çocuğun" gibi 90 yakınlıkla başlamaz, bağ
  /// zamanla kurulur.
  static const int prototypeOnlyStepChildStartBond = 15;

  /// prototypeOnly: eşin bir ebeveyninin hayatta olma ihtimali (§21).
  static const double prototypeOnlyInLawAliveChance = 0.72;

  /// prototypeOnly: eş ile ebeveyni arasındaki yaş farkı bandı (§43).
  static const int prototypeOnlyInLawMinGap = 20;
  static const int prototypeOnlyInLawMaxGap = 38;

  /// prototypeOnly: kayın ailenin başlangıç yakınlığı.
  static const int prototypeOnlyInLawStartBond = 30;

  // =================================================================
  // §21-§22 — kayınvalide / kayınpeder
  // =================================================================

  /// Eşin ailesi zaten kuruldu mu? (§22, §37 — aynı kişi iki kez
  /// üretilmesin.)
  static bool inLawsCreatedFor(GameState state, Person spouse) =>
      state.people.any((Person p) =>
          (p.relation == RelationType.kayinvalide ||
              p.relation == RelationType.kayinpeder) &&
          p.id.endsWith('-${spouse.id}'));

  /// Eşin yaşayan ebeveynlerini üretir (0-2 kişi).
  static List<Person> parentsOfSpouse({
    required GameState state,
    required Person spouse,
    required Random rng,
  }) {
    if (inLawsCreatedFor(state, spouse)) return const <Person>[];

    final Set<String> isimler = <String>{
      for (final Person p in state.people) p.firstName,
      state.player.firstName,
    };
    final List<Person> sonuc = <Person>[];

    for (final RelationType tur in <RelationType>[
      RelationType.kayinvalide,
      RelationType.kayinpeder,
    ]) {
      // §21: hepsi kesin hayatta olmak zorunda değil.
      if (!rng.chance(prototypeOnlyInLawAliveChance)) continue;

      final Gender cinsiyet =
          tur == RelationType.kayinvalide ? Gender.kadin : Gender.erkek;
      final List<String> havuz =
          cinsiyet == Gender.kadin ? kadinIsimleri : erkekIsimleri;
      String ad = rng.pick(havuz);
      for (int d = 0; d < 30 && isimler.contains(ad); d++) {
        ad = rng.pick(havuz);
      }
      isimler.add(ad);

      // §43: yaş eşin yaşıyla tutarlı. 30 yaşındaki eşin annesi 34
      // yaşında olamaz.
      final int fark = prototypeOnlyInLawMinGap +
          rng.nextInt(prototypeOnlyInLawMaxGap - prototypeOnlyInLawMinGap + 1);
      final int yas = spouse.age + fark;

      final bool calisiyor = yas < 65 && rng.chance(0.6);
      sonuc.add(
        Person(
          id: '${tur.name}-${spouse.id}',
          firstName: ad,
          // Eşin soyadını taşır: aynı aileden.
          lastName: spouse.lastName,
          gender: cinsiyet,
          relation: tur,
          age: yas,
          isAlive: true,
          // Kayın aile oyuncunun hanesinde yaşamaz.
          inPlayerHousehold: false,
          employment: calisiyor
              ? EmploymentStatus.calisiyor
              : EmploymentStatus.issiz,
          occupation: calisiyor ? rng.pick(meslekler) : null,
          wealth: rng.pick(<WealthTier>[
            WealthTier.yoksul,
            WealthTier.ortaHalli,
            WealthTier.ortaHalli,
            WealthTier.varlikli,
          ]),
          bond: prototypeOnlyInLawStartBond + rng.nextInt(15),
          city: spouse.city ?? state.player.currentCity,
        ),
      );
    }
    return sonuc;
  }

  // =================================================================
  // §18-§20 — eşin önceki çocuğu
  // =================================================================

  /// Eşin önceki ilişkisinden bir çocuğu var mı? Varsa kaydını üretir.
  ///
  /// `null` dönerse yoktur — bu **en olası** sonuçtur (§18).
  static Person? stepChildOf({
    required GameState state,
    required Person spouse,
    required Random rng,
  }) {
    // Zaten üretildiyse ikincisi üretilmez (§37).
    if (state.people.any((Person p) =>
        p.relation == RelationType.uveyCocuk &&
        p.id.endsWith('-${spouse.id}'))) {
      return null;
    }
    if (spouse.age < prototypeOnlyMinSpouseAgeForChild) return null;
    if (!rng.chance(prototypeOnlyStepChildChance)) return null;

    final int enBuyuk = spouse.age - prototypeOnlyMinGenerationGap;
    if (enBuyuk < 1) return null;

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

    final int yas = 1 + rng.nextInt(enBuyuk);
    final bool calisiyor = yas >= 22 && rng.chance(0.6);
    // Oyunun kendi değişmezi: 6-17 yaş arası herkes öğrencidir.
    // 6 yaş altı `cocuk`: yıllık ilerleme öğrenciliğe yalnızca bu
    // durumdan geçiriyor.
    final EmploymentStatus durum = yas < 6
        ? EmploymentStatus.cocuk
        : yas < 18
            ? EmploymentStatus.ogrenci
            : calisiyor
                ? EmploymentStatus.calisiyor
                : EmploymentStatus.issiz;

    return Person(
      id: 'uveycocuk-${spouse.id}',
      firstName: ad,
      lastName: spouse.lastName,
      gender: cinsiyet,
      relation: RelationType.uveyCocuk,
      age: yas,
      isAlive: true,
      // Küçükse eşle birlikte oyuncunun hanesine gelir.
      inPlayerHousehold: yas < 18,
      employment: durum,
      occupation:
          durum == EmploymentStatus.calisiyor ? rng.pick(meslekler) : null,
      wealth: yas >= 22 ? WealthTier.ortaHalli : null,
      // §20: "kendi çocuğun" gibi 90 bond ile başlamaz.
      bond: prototypeOnlyStepChildStartBond + rng.nextInt(10),
      city: spouse.city ?? state.player.currentCity,
      // §14: biyolojik ebeveyni **eştir**, oyuncu değil. Bu kayıt
      // sayesinde üvey çocuk hiçbir zaman oyuncunun biyolojik çocuğu
      // sayılmaz (§17 — miras, §41 — kuşak devamı).
      motherId: spouse.gender == Gender.kadin ? spouse.id : null,
      fatherId: spouse.gender == Gender.erkek ? spouse.id : null,
    );
  }

  // =================================================================
  // Evlilik kurulurken çağrılır
  // =================================================================

  /// Evlilik kurulduğunda eşin ailesini ve varsa önceki çocuğunu ekler.
  ///
  /// §19: bu **evlilik anında** olur, yıllar sonra değil.
  static GameState onMarriage({
    required GameState state,
    required Person spouse,
    required int age,
    required Random rng,
  }) {
    final List<Person> kayinlar = parentsOfSpouse(
      state: state,
      spouse: spouse,
      rng: rng,
    );
    final Person? uveyCocuk = stepChildOf(
      state: state,
      spouse: spouse,
      rng: rng,
    );
    if (kayinlar.isEmpty && uveyCocuk == null) return state;

    final List<LifeLogEntry> satirlar = <LifeLogEntry>[
      for (final Person k in kayinlar)
        LifeLogEntry(
          age: age,
          text: '${spouse.firstName} adlı eşinin '
              '${k.relation == RelationType.kayinvalide ? 'annesi' : 'babası'} '
              '${k.firstName} ile tanıştın.',
          category: LogCategory.aile,
          personId: k.id,
        ),
      if (uveyCocuk != null)
        LifeLogEntry(
          age: age,
          text: '${spouse.firstName} sana daha önceki ilişkisinden bir '
              'çocuğu olduğunu anlattı: ${uveyCocuk.firstName}, '
              '${uveyCocuk.age} yaşında.',
          category: LogCategory.aile,
          personId: uveyCocuk.id,
        ),
    ];

    return state.copyWith(
      people: List<Person>.unmodifiable(<Person>[
        ...state.people,
        ...kayinlar,
        ?uveyCocuk,
      ]),
      log: List<LifeLogEntry>.unmodifiable(<LifeLogEntry>[
        ...state.log,
        ...satirlar,
      ]),
    );
  }
}

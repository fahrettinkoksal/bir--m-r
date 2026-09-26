import 'dart:math';

import 'package:bir_omur/data/city_catalog.dart';
import 'package:bir_omur/data/economy.dart';
import 'package:bir_omur/data/item_catalog.dart';
import 'package:bir_omur/data/job_catalog.dart';
import 'package:bir_omur/data/save/game_state_codec.dart';
import 'package:bir_omur/domain/career/job_market.dart';
import 'package:bir_omur/domain/economy/household_budget.dart';
import 'package:bir_omur/domain/interaction/marriage_engine.dart';
import 'package:bir_omur/domain/models/career.dart';
import 'package:bir_omur/domain/models/household.dart';
import 'package:bir_omur/domain/models/marriage.dart';
import 'package:bir_omur/domain/economy/living_costs.dart';
import 'package:bir_omur/domain/economy/vehicle_inspection.dart';
import 'package:bir_omur/domain/economy/vehicle_trouble.dart';
import 'package:bir_omur/domain/generation/life_generator.dart';
import 'package:bir_omur/domain/generation/grandchildren.dart';
import 'package:bir_omur/domain/generation/life_progression.dart';
import 'package:bir_omur/domain/life/health_crisis_engine.dart';
import 'package:bir_omur/domain/models/game_state.dart';
import 'package:bir_omur/domain/models/gender.dart';
import 'package:bir_omur/domain/models/life_log.dart';
import 'package:bir_omur/domain/models/person.dart';
import 'package:bir_omur/domain/models/person_development.dart';
import 'package:bir_omur/domain/models/relation.dart';
import 'package:bir_omur/domain/models/stats.dart';
import 'package:bir_omur/domain/models/wealth.dart';
import 'package:bir_omur/domain/models/owned_item.dart';
import 'package:bir_omur/domain/models/pending_crisis.dart';
import 'package:bir_omur/domain/models/pending_notice.dart';
import 'package:flutter_test/flutter_test.dart';

/// Paket Z — C grubu: araç muayenesi ve kazada hasar (D-157).
void main() {
  /// Kataloğun ilk otomobili.
  ItemType otomobil() => kItemTypes.firstWhere(
        (ItemType t) => t.kind == ItemKind.otomobil,
      );

  GameState hayat({int age = 40, int wallet = 900000}) {
    final GameState base =
        LifeGenerator.seeded(8).generate(mode: StartMode.tamamenRastgele);
    return base.copyWith(
      pendingEvent: null,
      notices: const <PendingNotice>[],
      player: base.player.copyWith(age: age, wallet: wallet),
      movedOut: true,
    );
  }

  GameState aracli(
    GameState s, {
    int condition = 80,
    int acquiredAtAge = 38,
  }) =>
      s.copyWith(
        items: <OwnedItem>[
          OwnedItem(
            id: 'arac-1',
            typeId: otomobil().id,
            acquiredAtAge: acquiredAtAge,
            condition: condition,
          ),
        ],
      );

  group('Muayene zamanlaması (D-157)', () {
    test('yeni alınan araç o yıl muayeneye gelmez', () {
      final GameState s = aracli(hayat(age: 38), acquiredAtAge: 38);
      expect(VehicleInspection.isDue(s, s.items.single, 38), isFalse);
      expect(VehicleInspection.isDue(s, s.items.single, 39), isFalse);
    });

    test('iki yıl sonra muayene gelir', () {
      final GameState s = aracli(hayat(age: 40), acquiredAtAge: 38);
      expect(VehicleInspection.isDue(s, s.items.single, 40), isTrue);
    });

    test('bisiklet muayeneye tabi değil', () {
      final ItemType bisiklet = kItemTypes.firstWhere(
        (ItemType t) => t.kind == ItemKind.bisiklet,
      );
      final OwnedItem item = OwnedItem(
        id: 'bis-1',
        typeId: bisiklet.id,
        acquiredAtAge: 20,
      );
      expect(VehicleInspection.applies(item), isFalse);
      expect(VehicleInspection.isDue(hayat(), item, 40), isFalse);
    });

    test('motosikletin ücreti otomobilden düşük', () {
      expect(
        VehicleInspection.prototypeOnlyBikeFee,
        lessThan(VehicleInspection.prototypeOnlyCarFee),
      );
    });
  });

  group('Muayene sonucu', () {
    test('kondisyonu iyi araç geçer, ücret düşer, kayda yazılır', () {
      final GameState s = aracli(hayat(age: 40), condition: 80);
      final int once = s.player.wallet;
      final GameState sonra =
          VehicleInspection.advanceYear(state: s, newAge: 40);

      expect(
        sonra.player.wallet,
        once - VehicleInspection.feeFor(s.items.single),
      );
      expect(sonra.vehicleInspectionAt['arac-1'], 40);
      expect(
        sonra.notices.any((PendingNotice n) => n.id.startsWith('muayene-')),
        isTrue,
      );
      expect(sonra.log.last.text, contains('geçti'));
    });

    test('kondisyonu düşük araç geçemez; ücret yine ödenir', () {
      final GameState s = aracli(
        hayat(age: 40),
        condition: VehicleInspection.prototypeOnlyPassCondition - 5,
      );
      final int once = s.player.wallet;
      final GameState sonra =
          VehicleInspection.advanceYear(state: s, newAge: 40);

      expect(
        sonra.player.wallet,
        once - VehicleInspection.feeFor(s.items.single),
      );
      expect(
        sonra.vehicleInspectionAt['arac-1'],
        isNull,
        reason: 'Geçmeyen araç kayda yazılmaz',
      );
      expect(sonra.log.last.text, contains('geçemedi'));
    });

    test('parası yetmeyenin cüzdanı eksiye düşmez', () {
      final GameState s = aracli(hayat(age: 40, wallet: 10));
      final GameState sonra =
          VehicleInspection.advanceYear(state: s, newAge: 40);
      expect(sonra.player.wallet, greaterThanOrEqualTo(0));
      expect(sonra.vehicleInspectionAt['arac-1'], isNull);
    });

    test('geçen araç iki yıl boyunca tekrar muayeneye gelmez', () {
      GameState s = aracli(hayat(age: 40), condition: 80);
      s = VehicleInspection.advanceYear(state: s, newAge: 40);
      expect(VehicleInspection.isDue(s, s.items.single, 41), isFalse);
      expect(VehicleInspection.isDue(s, s.items.single, 42), isTrue);
    });
  });

  group('Gecikme bedeli', () {
    test('muayenesi geciken araç yıllık idari bedel çıkarır', () {
      // 38'de alınmış, 43'te hâlâ muayene edilmemiş: 3 yıl gecikme.
      final GameState s = aracli(hayat(age: 43, wallet: 10), acquiredAtAge: 38);
      expect(VehicleInspection.overdueYears(s, s.items.single, 43), 3);

      final GameState zengin =
          aracli(hayat(age: 43, wallet: 900000), acquiredAtAge: 38);
      final int once = zengin.player.wallet;
      final GameState sonra =
          VehicleInspection.advanceYear(state: zengin, newAge: 43);
      // Hem gecikme bedeli hem muayene ücreti çıkar.
      expect(sonra.player.wallet, lessThan(once));
      expect(
        sonra.log.any((dynamic l) => (l.text as String).contains('gecikti')),
        isTrue,
      );
    });

    test('zamanında muayene edilen araçta gecikme yok', () {
      final GameState s = aracli(hayat(age: 39), acquiredAtAge: 38);
      expect(VehicleInspection.overdueYears(s, s.items.single, 39), 0);
    });
  });

  group('Kazada araç hasarı (D-157)', () {
    test('trafik kazası aracın kondisyonunu düşürür', () {
      final GameState s = aracli(hayat(age: 40), condition: 90).copyWith(
        pendingCrisis: const PendingCrisis(crisisId: 'trafik_kazasi', age: 40),
      );
      final CrisisResult r =
          const HealthCrisisEngine().respond(s, 'hastane', Random(1));
      if (!r.outcome.survived) return;
      expect(
        r.state.items.single.condition,
        lessThan(90),
        reason: 'Kaza geçiren oyuncunun arabası tazeliğini korumamalı',
      );
    });

    test('aracı olmayanda kaza hiçbir şeyi bozmaz', () {
      final GameState s = hayat(age: 40).copyWith(
        items: const <OwnedItem>[],
        pendingCrisis: const PendingCrisis(crisisId: 'trafik_kazasi', age: 40),
      );
      final CrisisResult r =
          const HealthCrisisEngine().respond(s, 'hastane', Random(1));
      expect(r.state.items, isEmpty);
    });

    test('hasar yalnızca bir araca uygulanır', () {
      final GameState s = hayat(age: 40).copyWith(
        items: <OwnedItem>[
          OwnedItem(
            id: 'arac-1',
            typeId: otomobil().id,
            acquiredAtAge: 38,
            condition: 90,
          ),
          OwnedItem(
            id: 'arac-2',
            typeId: otomobil().id,
            acquiredAtAge: 38,
            condition: 50,
          ),
        ],
      );
      final ({List<OwnedItem> items, String? text}) r =
          VehicleTroubles.damageInAccident(s.items);
      expect(r.text, isNotNull);
      // En yüksek kondisyonlu araç hasar görür, diğeri dokunulmaz.
      expect(
        r.items.firstWhere((OwnedItem i) => i.id == 'arac-1').condition,
        lessThan(90),
      );
      expect(
        r.items.firstWhere((OwnedItem i) => i.id == 'arac-2').condition,
        50,
      );
    });

    test('kondisyon sıfırın altına inmez', () {
      final List<OwnedItem> items = <OwnedItem>[
        OwnedItem(
          id: 'arac-1',
          typeId: otomobil().id,
          acquiredAtAge: 38,
          condition: 3,
        ),
      ];
      final ({List<OwnedItem> items, String? text}) r =
          VehicleTroubles.damageInAccident(items);
      expect(r.items.single.condition, greaterThanOrEqualTo(0));
    });
  });

  group('Kayıt', () {
    test('muayene kaydı kaydedilip geri okunur', () {
      final GameState s = aracli(hayat()).copyWith(
        vehicleInspectionAt: const <String, int>{'arac-1': 40},
      );
      final GameState geri = decodeGameState(encodeGameState(s));
      expect(geri.vehicleInspectionAt['arac-1'], 40);
    });

    test('eski kayıtta alan yoksa boş okunur', () {
      final Map<String, Object?> json = encodeGameState(aracli(hayat()));
      json.remove('vehicleInspectionAt');
      expect(decodeGameState(json).vehicleInspectionAt, isEmpty);
    });
  });

  group('Yıl akışına bağlı', () {
    test('yıl ilerleyince muayene gerçekten çalışıyor', () {
      GameState s = aracli(hayat(age: 39), condition: 85, acquiredAtAge: 38);
      s = LifeProgression(Random(3)).advanceOneYear(s);
      expect(
        s.vehicleInspectionAt['arac-1'],
        40,
        reason: 'Yıl akışında muayene hiç çalışmıyorsa bağlantı kopuk',
      );
    });
  });

  group('Kardeşin kendi hayatı ve yeğenler (D-158)', () {
    Person kardes({int age = 30, String id = 'kardes-1'}) => Person(
          id: id,
          firstName: 'Melis',
          lastName: 'Yıldız',
          gender: Gender.kadin,
          relation: RelationType.kardes,
          age: age,
          isAlive: true,
          inPlayerHousehold: false,
          employment: EmploymentStatus.issiz,
          wealth: WealthTier.ortaHalli,
          bond: 65,
        );

    GameState kardesli({int playerAge = 32, int kardesYasi = 30}) {
      final GameState base = hayat(age: playerAge);
      return base.copyWith(
        people: List<Person>.unmodifiable(<Person>[
          ...base.people.where((Person p) => p.relation != RelationType.kardes),
          kardes(age: kardesYasi),
        ]),
      );
    }

    test('kardeşin hayatı ilerliyor: gelişim kaydı açılıyor', () {
      GameState s = kardesli();
      expect(s.personById('kardes-1')!.development, isNull);
      s = LifeProgression(Random(3)).advanceOneYear(s);
      final Person k = s.personById('kardes-1')!;
      expect(k.development, isNotNull);
      expect(k.development!.tracksLife, isTrue);
      expect(k.age, 31, reason: 'Kardeş de yaşlanıyor');
    });

    test('kardeşin serveti kayıt açılırken sıfırlanmıyor', () {
      GameState s = kardesli();
      s = s.copyWith(
        people: s.people
            .map((Person p) => p.relation == RelationType.kardes
                ? p.copyWith(wealth: WealthTier.cokVarlikli)
                : p)
            .toList(growable: false),
      );
      s = LifeProgression(Random(3)).advanceOneYear(s);
      expect(
        s.personById('kardes-1')!.wealth,
        WealthTier.cokVarlikli,
        reason: 'Finger hatasının aynısı burada da olmamalı',
      );
    });

    test('kardeş evlenebiliyor ve kaydı kalıcı', () {
      int evlenen = 0;
      for (int seed = 0; seed < 40 && evlenen == 0; seed++) {
        GameState s = kardesli(playerAge: 32, kardesYasi: 28);
        final LifeProgression motor = LifeProgression(Random(seed));
        for (int i = 0; i < 10 && !s.deceased; i++) {
          s = motor.advanceOneYear(s);
          s = s.copyWith(
            pendingEvent: null,
            pendingCrisis: null,
            notices: const <PendingNotice>[],
          );
        }
        final Person? k = s.personById('kardes-1');
        if (k?.development?.isMarried ?? false) {
          evlenen++;
          // Aynı kardeş iki kez evlenmez.
          final int dugun = s.log
              .where((LifeLogEntry l) =>
                  l.text.contains('Melis evleniyor') ||
                  l.text.contains('Melis evlenmiş'))
              .length;
          expect(dugun, 1);
        }
      }
      expect(evlenen, 1, reason: '40 denemede hiç evlenmediyse bağlantı kopuk');
    });

    test('kardeşin çocuğu yeğen olarak doğuyor', () {
      int yegenli = 0;
      for (int seed = 0; seed < 60 && yegenli == 0; seed++) {
        GameState s = kardesli(playerAge: 32, kardesYasi: 28);
        final LifeProgression motor = LifeProgression(Random(seed));
        for (int i = 0; i < 12 && !s.deceased; i++) {
          s = motor.advanceOneYear(s);
          s = s.copyWith(
            pendingEvent: null,
            pendingCrisis: null,
            notices: const <PendingNotice>[],
          );
        }
        final List<Person> yegenler = s.people
            .where((Person p) => p.relation == RelationType.yegen)
            .toList(growable: false);
        if (yegenler.isEmpty) continue;
        yegenli++;
        final Person y = yegenler.first;
        expect(y.development?.otherParentId, 'kardes-1');
        expect(y.id, startsWith('yegen-'));
        expect(y.inPlayerHousehold, isFalse);
        expect(
          s.log.any((LifeLogEntry l) => l.text.contains('Yeğenin oldu')),
          isTrue,
        );
      }
      expect(yegenli, 1, reason: '60 denemede hiç yeğen olmadıysa bağlantı kopuk');
    });

    test('yeğen torunla karışmıyor; ayrı kimlik öneki taşıyor', () {
      final Person k = kardes(age: 30).copyWith(
        development: const PersonDevelopment(
          tracksLife: true,
          stats: Stats(
            appearance: 50,
            happiness: 60,
            health: 60,
            intelligence: 60,
            charisma: 60,
          ),
        ),
      );
      final GameState s = hayat().copyWith(
        people: List<Person>.unmodifiable(<Person>[k]),
      );
      // Torun kuralı kardeşe uygulanmaz: parentRelation uyuşmuyor.
      expect(
        Grandchildren.maybeBorn(state: s, child: k, rng: Random(1)),
        isNull,
      );
      // Yeğen kuralı ise çalışır (şansa bağlı; birçok tohumda denenir).
      Person? yegen;
      for (int seed = 0; seed < 200 && yegen == null; seed++) {
        yegen = Grandchildren.maybeBornTo(
          state: s,
          parent: k,
          rng: Random(seed),
          parentRelation: RelationType.kardes,
          childRelation: RelationType.yegen,
          idPrefix: 'yegen',
        );
      }
      expect(yegen, isNotNull);
      expect(yegen!.relation, RelationType.yegen);
      expect(yegen.id, startsWith('yegen-'));
    });

    test('bir kardeşin yeğen sayısı üst sınırı aşmıyor', () {
      final Person k = kardes(age: 30).copyWith(
        development: const PersonDevelopment(
          tracksLife: true,
          stats: Stats(
            appearance: 50,
            happiness: 60,
            health: 60,
            intelligence: 60,
            charisma: 60,
          ),
        ),
      );
      final List<Person> yegenler = <Person>[
        for (int i = 1; i <= Grandchildren.prototypeOnlyMaxPerChild; i++)
          Person(
            id: 'yegen-$i',
            firstName: 'Yegen$i',
            lastName: 'Yıldız',
            gender: Gender.erkek,
            relation: RelationType.yegen,
            age: i,
            isAlive: true,
            inPlayerHousehold: false,
            employment: EmploymentStatus.cocuk,
            wealth: null,
            bond: 50,
            development: const PersonDevelopment(
              tracksLife: true,
              stats: Stats(
                appearance: 50,
                happiness: 60,
                health: 60,
                intelligence: 60,
                charisma: 60,
              ),
              otherParentId: 'kardes-1',
            ),
          ),
      ];
      final GameState s = hayat().copyWith(
        people: List<Person>.unmodifiable(<Person>[k, ...yegenler]),
      );
      for (int seed = 0; seed < 100; seed++) {
        expect(
          Grandchildren.maybeBornTo(
            state: s,
            parent: k,
            rng: Random(seed),
            parentRelation: RelationType.kardes,
            childRelation: RelationType.yegen,
            idPrefix: 'yegen',
          ),
          isNull,
        );
      }
    });
  });

  group('Şehrin kendi karakteri (D-159)', () {
    test('her şehrin fırsat düzeyi makul ve konutla tutarlı', () {
      for (final CityProfile c in kCityProfiles) {
        expect(c.opportunity, inInclusiveRange(0.0, 1.0), reason: c.name);
      }
      // Konutu pahalı şehir aynı zamanda geniş piyasa olur; sıralama
      // bozulmamalı.
      expect(
        cityProfile('İstanbul').opportunity,
        greaterThan(cityProfile('Sivas').opportunity),
      );
    });

    test('tanınmayan şehir uydurma katsayı almaz', () {
      final CityProfile bilinmeyen = cityProfile('Olmayanşehir');
      expect(bilinmeyen.housingFactor, 1.0);
      expect(bilinmeyen.vehicleFactor, 1.0);
    });

    test('geçim gideri şehirden etkilenmiyor (D-159 kararı)', () {
      // Bilerek böyle: gideri şehre bağlamak mevcut denge kuralını
      // kırıyordu, ikisini birlikte oynatmak ise maaşlı çalışan için
      // etkiyi sıfırlıyordu. Karar Q-162'de.
      GameState kur(String sehir) {
        final GameState base = hayat(age: 30);
        return base.copyWith(
          player: base.player.copyWith(currentCity: sehir),
          movedOut: true,
        );
      }

      expect(
        LivingCosts.yearlyCost(kur('İstanbul')),
        LivingCosts.yearlyCost(kur('Sivas')),
      );
    });

    test('en üst bant dışındaki her iş her şehirde bulunur', () {
      for (final CityProfile c in kCityProfiles) {
        for (final SalaryBand b in SalaryBand.values) {
          if (b == SalaryBand.yuksekUzmanlik) continue;
          expect(
            bandAvailableIn(c.name, b),
            isTrue,
            reason: '${c.name} / ${b.name}',
          );
        }
      }
    });

    test('hobiyle açılan yaratıcı meslekler şehre bağlı değil', () {
      // Yıllarca hobisine emek veren oyuncu, doğduğu şehir yüzünden
      // karşılığını alamamamalı.
      for (final CityProfile c in kCityProfiles) {
        expect(
          bandAvailableIn(c.name, SalaryBand.yaraticiDegisken),
          isTrue,
          reason: c.name,
        );
      }
    });

    test('yüksek uzmanlık dar piyasada bulunmaz, geniş piyasada bulunur', () {
      expect(bandAvailableIn('Sivas', SalaryBand.yuksekUzmanlik), isFalse);
      expect(bandAvailableIn('İstanbul', SalaryBand.yuksekUzmanlik), isTrue);
    });

    test('dar piyasada iş gerekçesi açıkça yazılıyor', () {
      final JobType ust = kJobCatalog.firstWhere(
        (JobType j) => j.band == SalaryBand.yuksekUzmanlik,
      );
      GameState s = hayat(age: 40);
      s = s.copyWith(
        player: s.player.copyWith(currentCity: 'Sivas'),
      );
      final String gerekce = const JobMarket().requirementReason(s, ust);
      expect(gerekce, isNotEmpty);
      expect(gerekce, contains('Sivas'));
      expect(gerekce, contains('Büyük şehirlerde'));
    });

    test('konut ve araç fiyatı şehre göre değişmeye devam ediyor', () {
      expect(
        housingPriceIn('İstanbul', 1000000),
        greaterThan(housingPriceIn('Sivas', 1000000)),
      );
      expect(
        vehiclePriceIn('İstanbul', 1000000),
        greaterThanOrEqualTo(vehiclePriceIn('Sivas', 1000000)),
      );
    });
  });

  group('Hane bütçesi, velayet ve nafaka (D-160)', () {
    Person es({
      int age = 40,
      String? jobId,
      bool alive = true,
    }) =>
        Person(
          id: 'es-1',
          firstName: 'Eren',
          lastName: 'Yıldız',
          gender: Gender.erkek,
          relation: RelationType.es,
          age: age,
          isAlive: alive,
          inPlayerHousehold: true,
          employment: jobId == null
              ? EmploymentStatus.issiz
              : EmploymentStatus.calisiyor,
          occupation: jobId == null ? null : jobById(jobId)!.name,
          wealth: WealthTier.ortaHalli,
          bond: 80,
          development: PersonDevelopment(
            tracksLife: true,
            stats: const Stats(
              appearance: 50,
              happiness: 60,
              health: 60,
              intelligence: 60,
              charisma: 60,
            ),
            finishedSchool: true,
            jobId: jobId,
            jobStartedAtAge: jobId == null ? null : 25,
          ),
        );

    Person cocuk(String id, int age, {int bond = 70}) => Person(
          id: id,
          firstName: 'Cocuk$id',
          lastName: 'Yıldız',
          gender: Gender.kadin,
          relation: RelationType.cocuk,
          age: age,
          isAlive: true,
          inPlayerHousehold: true,
          employment: EmploymentStatus.cocuk,
          wealth: null,
          bond: bond,
        );

    GameState evli({
      int playerAge = 40,
      String? esIsi,
      List<Person> cocuklar = const <Person>[],
      int wallet = 900000,
      String? oyuncuIsi,
    }) {
      final GameState base = hayat(age: playerAge, wallet: wallet);
      return base.copyWith(
        people: List<Person>.unmodifiable(<Person>[
          ...base.people,
          es(jobId: esIsi),
          ...cocuklar,
        ]),
        marriage: Marriage(
          spouseId: 'es-1',
          marriedAtAge: playerAge - 10,
          status: MarriageStatus.evli,
        ),
        career: oyuncuIsi == null
            ? const CareerState.none()
            : CareerState(jobId: oyuncuIsi, startedAtAge: playerAge - 5),
      );
    }

    test('çalışan eş haneye katkı koyuyor', () {
      final JobType is_ = kJobCatalog.first;
      final GameState s = evli(esIsi: is_.id);
      final int katki = HouseholdBudget.spouseContribution(s);
      expect(katki, greaterThan(0));
      expect(
        katki,
        (is_.yearlySalary * HouseholdBudget.prototypeOnlySpouseShare).round(),
      );

      final int once = s.player.wallet;
      final GameState sonra = HouseholdBudget.applySpouseContribution(
        state: s,
        newAge: 41,
      );
      expect(sonra.player.wallet, once + katki);
      expect(sonra.log.last.text, contains('haneye'));
    });

    test('işsiz eş katkı koymaz, uydurma gelir yazılmaz', () {
      expect(HouseholdBudget.spouseContribution(evli()), 0);
    });

    test('boşanmış kayıtta eşin katkısı kesilir', () {
      GameState s = evli(esIsi: kJobCatalog.first.id);
      s = s.copyWith(
        marriage: s.marriage!.copyWith(
          status: MarriageStatus.bosandi,
          endedAtAge: 40,
        ),
      );
      expect(HouseholdBudget.spouseContribution(s), 0);
    });

    test('velayet çocukların yakınlığından belirlenir', () {
      expect(
        HouseholdBudget.decideCustody(
          evli(cocuklar: <Person>[cocuk('cocuk-1', 8, bond: 85)]),
        ),
        Custody.oyuncuda,
      );
      expect(
        HouseholdBudget.decideCustody(
          evli(cocuklar: <Person>[cocuk('cocuk-1', 8, bond: 20)]),
        ),
        Custody.eskiEste,
      );
      expect(
        HouseholdBudget.decideCustody(
          evli(cocuklar: <Person>[cocuk('cocuk-1', 8, bond: 50)]),
        ),
        Custody.ortak,
      );
    });

    test('çocuk yoksa nafaka da yoktur', () {
      expect(
        HouseholdBudget.computeAlimony(
          state: evli(),
          custody: Custody.oyuncuda,
          exSpouseId: 'es-1',
        ),
        isNull,
      );
    });

    test('ortak velayette kimse nafaka ödemez', () {
      expect(
        HouseholdBudget.computeAlimony(
          state: evli(
            cocuklar: <Person>[cocuk('cocuk-1', 8)],
            oyuncuIsi: kJobCatalog.first.id,
          ),
          custody: Custody.ortak,
          exSpouseId: 'es-1',
        ),
        isNull,
      );
    });

    test('çocuk kendisinde kalmayan taraf öder', () {
      // Çocuk eski eşte kaldıysa oyuncu öder.
      final Alimony? oyuncuOder = HouseholdBudget.computeAlimony(
        state: evli(
          cocuklar: <Person>[cocuk('cocuk-1', 8)],
          oyuncuIsi: kJobCatalog.first.id,
        ),
        custody: Custody.eskiEste,
        exSpouseId: 'es-1',
      );
      expect(oyuncuOder, isNotNull);
      expect(oyuncuOder!.playerPays, isTrue);

      // Çocuk oyuncuda kaldıysa eski eş öder.
      final Alimony? esOder = HouseholdBudget.computeAlimony(
        state: evli(
          cocuklar: <Person>[cocuk('cocuk-1', 8)],
          esIsi: kJobCatalog.first.id,
        ),
        custody: Custody.oyuncuda,
        exSpouseId: 'es-1',
      );
      expect(esOder, isNotNull);
      expect(esOder!.playerPays, isFalse);
    });

    test('geliri olmayan taraftan nafaka çıkmaz', () {
      expect(
        HouseholdBudget.computeAlimony(
          state: evli(cocuklar: <Person>[cocuk('cocuk-1', 8)]),
          custody: Custody.eskiEste,
          exSpouseId: 'es-1',
        ),
        isNull,
        reason: 'İşsiz oyuncudan uydurma nafaka hesaplanmamalı',
      );
    });

    test('nafaka en küçük çocuk 18 olunca biter', () {
      final Alimony a = HouseholdBudget.computeAlimony(
        state: evli(
          playerAge: 40,
          cocuklar: <Person>[
            cocuk('cocuk-1', 15),
            cocuk('cocuk-2', 8),
          ],
          oyuncuIsi: kJobCatalog.first.id,
        ),
        custody: Custody.eskiEste,
        exSpouseId: 'es-1',
      )!;
      // En küçük 8; 10 yıl kalmış.
      expect(a.untilAge, 50);
      expect(a.runsAt(49), isTrue);
      expect(a.runsAt(50), isFalse);
    });

    test('nafaka oranı tavanı aşmaz', () {
      final Alimony a = HouseholdBudget.computeAlimony(
        state: evli(
          cocuklar: <Person>[
            cocuk('cocuk-1', 2),
            cocuk('cocuk-2', 4),
            cocuk('cocuk-3', 6),
            cocuk('cocuk-4', 8),
          ],
          oyuncuIsi: kJobCatalog.first.id,
        ),
        custody: Custody.eskiEste,
        exSpouseId: 'es-1',
      )!;
      final int maas = jobById(kJobCatalog.first.id)!.yearlySalary;
      expect(
        a.yearlyAmount / maas,
        lessThanOrEqualTo(HouseholdBudget.prototypeOnlyAlimonyMaxRate),
      );
    });

    test('nafaka yılda bir işler; parası yetmeyende cüzdan eksiye inmez', () {
      GameState s = evli(wallet: 100).copyWith(
        alimony: const Alimony(
          otherPersonId: 'es-1',
          yearlyAmount: 200000,
          startedAtAge: 40,
          untilAge: 50,
          playerPays: true,
        ),
      );
      s = HouseholdBudget.advanceYear(state: s, newAge: 41);
      expect(s.player.wallet, greaterThanOrEqualTo(0));
      expect(s.alimony!.paidYears, 1);
    });

    test('alan taraf için nafaka cüzdana girer', () {
      GameState s = evli(wallet: 1000).copyWith(
        alimony: const Alimony(
          otherPersonId: 'es-1',
          yearlyAmount: 50000,
          startedAtAge: 40,
          untilAge: 50,
          playerPays: false,
        ),
      );
      s = HouseholdBudget.advanceYear(state: s, newAge: 41);
      expect(s.player.wallet, 51000);
    });

    test('süresi dolan nafaka kapanır ama silinmez', () {
      GameState s = evli().copyWith(
        alimony: const Alimony(
          otherPersonId: 'es-1',
          yearlyAmount: 50000,
          startedAtAge: 40,
          untilAge: 50,
          playerPays: true,
        ),
      );
      s = HouseholdBudget.advanceYear(state: s, newAge: 50);
      expect(s.alimony, isNotNull, reason: 'Kayıt silinmez');
      expect(s.alimony!.isActive, isFalse);
      expect(s.alimony!.endedAtAge, 50);
      expect(s.log.last.text, contains('sona erdi'));
    });

    test('boşanma velayeti ve nafakayı gerçekten kuruyor', () {
      final GameState s = evli(
        cocuklar: <Person>[cocuk('cocuk-1', 8, bond: 20)],
        oyuncuIsi: kJobCatalog.first.id,
      );
      final FamilyResult r = const MarriageEngine().divorce(s);
      expect(r.outcome.applied, isTrue);
      expect(r.state.alimony, isNotNull);
      expect(r.state.alimony!.playerPays, isTrue);
      expect(r.outcome.text, contains('Velayet'));
      expect(r.outcome.text, contains('nafaka'));
      // Çocuk eski eşin hanesine geçer ama kaydı silinmez.
      final Person c = r.state.personById('cocuk-1')!;
      expect(c.inPlayerHousehold, isFalse);
      expect(c.relation, RelationType.cocuk);
    });

    test('çocuğu olmayan boşanmada nafaka kaydı açılmaz', () {
      final GameState s = evli(oyuncuIsi: kJobCatalog.first.id);
      final FamilyResult r = const MarriageEngine().divorce(s);
      expect(r.outcome.applied, isTrue);
      expect(r.state.alimony, isNull);
    });

    test('nafaka kaydı kaydedilip geri okunur; eski kayıt bozulmaz', () {
      final GameState s = evli().copyWith(
        alimony: const Alimony(
          otherPersonId: 'es-1',
          yearlyAmount: 50000,
          startedAtAge: 40,
          untilAge: 50,
          playerPays: true,
          custody: Custody.eskiEste,
          paidYears: 3,
        ),
      );
      final GameState geri = decodeGameState(encodeGameState(s));
      expect(geri.alimony!.yearlyAmount, 50000);
      expect(geri.alimony!.custody, Custody.eskiEste);
      expect(geri.alimony!.paidYears, 3);

      final Map<String, Object?> json = encodeGameState(s);
      json.remove('alimony');
      expect(decodeGameState(json).alimony, isNull);
    });
  });
}

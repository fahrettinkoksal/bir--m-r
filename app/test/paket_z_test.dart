import 'dart:math';

import 'package:bir_omur/data/item_catalog.dart';
import 'package:bir_omur/data/save/game_state_codec.dart';
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
}

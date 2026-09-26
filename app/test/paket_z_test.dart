import 'dart:math';

import 'package:bir_omur/data/item_catalog.dart';
import 'package:bir_omur/data/save/game_state_codec.dart';
import 'package:bir_omur/domain/economy/vehicle_inspection.dart';
import 'package:bir_omur/domain/economy/vehicle_trouble.dart';
import 'package:bir_omur/domain/generation/life_generator.dart';
import 'package:bir_omur/domain/generation/life_progression.dart';
import 'package:bir_omur/domain/life/health_crisis_engine.dart';
import 'package:bir_omur/domain/models/game_state.dart';
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
}

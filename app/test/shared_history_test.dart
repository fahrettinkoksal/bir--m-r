import 'dart:math';

import 'package:bir_omur/app.dart';
import 'package:bir_omur/data/save/game_state_codec.dart';
import 'package:bir_omur/domain/activities/travel.dart';
import 'package:bir_omur/domain/generation/life_generator.dart';
import 'package:bir_omur/domain/generation/life_progression.dart';
import 'package:bir_omur/domain/interaction/shared_history.dart';
import 'package:bir_omur/domain/models/game_state.dart';
import 'package:bir_omur/domain/models/gender.dart';
import 'package:bir_omur/domain/models/gift_record.dart';
import 'package:bir_omur/domain/models/life_log.dart';
import 'package:bir_omur/domain/models/person.dart';
import 'package:bir_omur/domain/models/relation.dart';
import 'package:bir_omur/domain/models/trip.dart';
import 'package:bir_omur/state/game_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/generation_fixtures.dart';

/// Anne ve bir arkadaşla kurulu hayat.
GameState hayat({int age = 30, int seed = 161}) {
  final GameState base =
      LifeGenerator.seeded(seed).generate(mode: StartMode.tamamenRastgele);
  return base.copyWith(
    pendingEvent: null,
    player: base.player.copyWith(age: age, wallet: 200000),
    people: <Person>[
      kisi(
        id: 'anne-1',
        relation: RelationType.anne,
        gender: Gender.kadin,
        age: 58,
        firstName: 'Sema',
        city: base.player.currentCity,
      ),
      kisi(
        id: 'arkadas-1',
        relation: RelationType.arkadas,
        gender: Gender.erkek,
        age: 30,
        firstName: 'Kerem',
        city: base.player.currentCity,
      ),
    ],
  );
}

void main() {
  group('Ortak geçmiş derlemesi', () {
    test('kayıt yoksa liste boştur; hiçbir şey uydurulmaz', () {
      final GameState s = hayat();
      expect(SharedHistory.of(s, s.personById('arkadas-1')!), isEmpty);
    });

    test('günlüğün kişiye bağlı satırları görünür', () {
      GameState s = hayat();
      s = s.copyWith(
        log: <LifeLogEntry>[
          ...s.log,
          const LifeLogEntry(
            age: 28,
            text: 'Sema ile uzun uzun konuştunuz.',
            category: LogCategory.aile,
            personId: 'anne-1',
          ),
          // Başka kişiye ait satır bu listede çıkmamalı.
          const LifeLogEntry(
            age: 29,
            text: 'Kerem ile maça gittiniz.',
            category: LogCategory.kisisel,
            personId: 'arkadas-1',
          ),
        ],
      );

      final List<SharedMoment> anne =
          SharedHistory.of(s, s.personById('anne-1')!);
      expect(anne, hasLength(1));
      expect(anne.single.text, contains('Sema ile uzun uzun'));
      expect(anne.single.age, 28);
      expect(anne.single.kind, SharedMomentKind.olay);
    });

    test('hediyeler iki yönlü olarak görünür', () {
      GameState s = hayat();
      s = s.copyWith(
        gifts: <GiftRecord>[
          const GiftRecord(
            itemId: 'yoyo',
            fromId: 'anne-1',
            toId: GiftRecord.playerId,
            age: 8,
          ),
          const GiftRecord(
            itemId: 'kol_saati',
            fromId: GiftRecord.playerId,
            toId: 'anne-1',
            age: 25,
          ),
        ],
      );

      final List<SharedMoment> anlar =
          SharedHistory.of(s, s.personById('anne-1')!);
      expect(anlar, hasLength(2));
      expect(anlar.first.age, 8);
      expect(anlar.first.text, contains('sana'));
      expect(anlar.last.text, contains('verdin'));
      expect(anlar.every((SharedMoment m) =>
          m.kind == SharedMomentKind.hediye), isTrue);
    });

    test('birlikte yapılan gezi görünür, yalnız gidilen görünmez', () {
      GameState s = hayat();
      s = Travel.take(
        s,
        mode: TravelMode.tren,
        city: Travel.destinations(s).first,
        companionId: 'anne-1',
        rng: Random(1),
      ).state;
      s = Travel.take(
        s,
        mode: TravelMode.otobus,
        city: Travel.destinations(s).last,
        rng: Random(2),
      ).state;

      final List<SharedMoment> anne =
          SharedHistory.of(s, s.personById('anne-1')!);
      expect(
        anne.where((SharedMoment m) => m.kind == SharedMomentKind.gezi),
        hasLength(1),
      );
      expect(
        SharedHistory.of(s, s.personById('arkadas-1')!)
            .where((SharedMoment m) => m.kind == SharedMomentKind.gezi),
        isEmpty,
      );
    });

    test('çocuğun doğumu kilometre taşı olarak görünür', () {
      GameState s = hayat(age: 40);
      s = s.copyWith(
        people: <Person>[
          ...s.people,
          kisi(
            id: 'cocuk-1',
            relation: RelationType.cocuk,
            gender: Gender.kadin,
            age: 10,
            firstName: 'Elif',
            hane: true,
          ),
        ],
      );

      final List<SharedMoment> anlar =
          SharedHistory.of(s, s.personById('cocuk-1')!);
      expect(anlar, isNotEmpty);
      final SharedMoment dogum = anlar.first;
      expect(dogum.kind, SharedMomentKind.kilometreTasi);
      expect(dogum.age, 30, reason: '40 yaşındayken 10 yaşında çocuk');
      expect(dogum.text, contains('dünyaya geldi'));
    });

    test('vefat kilometre taşı olarak görünür', () {
      GameState s = hayat();
      s = s.copyWith(
        people: s.people
            .map((Person p) =>
                p.id == 'anne-1' ? p.copyWith(isAlive: false) : p)
            .toList(growable: false),
      );
      final List<SharedMoment> anlar =
          SharedHistory.of(s, s.personById('anne-1')!);
      expect(anlar.any((SharedMoment m) => m.text.contains('vefat')), isTrue);
    });

    test('anlar eskiden yeniye sıralanır ve sayısı sınırlıdır', () {
      GameState s = hayat(age: 50);
      s = s.copyWith(
        log: <LifeLogEntry>[
          ...s.log,
          for (int yas = 10; yas < 40; yas++)
            LifeLogEntry(
              age: yas,
              text: '$yas yaşında bir şey oldu.',
              category: LogCategory.aile,
              personId: 'anne-1',
            ),
        ],
      );

      final List<SharedMoment> anlar =
          SharedHistory.of(s, s.personById('anne-1')!);
      expect(anlar, hasLength(SharedHistory.prototypeOnlyMaxMoments));
      for (int i = 1; i < anlar.length; i++) {
        expect(anlar[i].age, greaterThanOrEqualTo(anlar[i - 1].age));
      }
    });

    test('günlük kişi bağı kayıtla birlikte saklanır', () {
      GameState s = hayat();
      s = s.copyWith(
        log: <LifeLogEntry>[
          ...s.log,
          const LifeLogEntry(
            age: 28,
            text: 'Sema ile konuştunuz.',
            category: LogCategory.aile,
            personId: 'anne-1',
          ),
        ],
      );

      final GameState geri = decodeGameState(encodeGameState(s));
      expect(
        SharedHistory.of(geri, geri.personById('anne-1')!),
        hasLength(1),
      );
    });

    test('eski kayıtta kişi bağı yoktur, geriye dönük bağlanmaz', () {
      final GameState s = hayat();
      final Map<String, Object?> body =
          Map<String, Object?>.from(encodeGameState(s));
      final List<Object?> log = List<Object?>.from(body['log']! as List<Object?>);
      body['log'] = <Object?>[
        for (final Object? e in log)
          Map<String, Object?>.from(e! as Map<String, Object?>)
            ..remove('personId'),
      ];

      final GameState geri = decodeGameState(body);
      for (final LifeLogEntry e in geri.log) {
        expect(e.personId, isNull);
      }
    });
  });

  test('kişinin eşya listesinde aynı tür iki kez birikmez', () {
    // Paket 14'te bulunan hata: yıllık mal varlığı değişimi kişiye
    // zaten sahip olduğu türü yeniden ekleyebiliyordu; hem kişi
    // kartında hem de mirasta çift görünüyordu.
    GameState s = hayat(age: 20);
    for (int yil = 0; yil < 60; yil++) {
      s = LifeProgression(Random(yil)).advanceOneYear(
        s.copyWith(pendingEvent: null),
      );
      if (s.deceased) break;
      for (final Person p in s.people) {
        expect(
          p.estate.length,
          p.estate.toSet().length,
          reason: '${p.firstName} aynı eşyaya iki kez sahip görünüyor: '
              '${p.estate}',
        );
      }
    }
  });

  group('Kişi kartı arayüzü', () {
    late GameController controller;

    setUp(() => controller = GameController(random: Random(51)));
    tearDown(() => controller.dispose());

    Future<void> kisiyiAc(WidgetTester tester, GameState state) async {
      tester.view.physicalSize = const Size(1200, 5200);
      tester.view.devicePixelRatio = 3;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(BirOmurApp(controller: controller));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Rastgele bir hayat'));
      await tester.pumpAndSettle();
      controller.debugSetState(state);
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('tab_iliskiler')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Sema Yılmaz').first);
      await tester.pumpAndSettle();
    }

    testWidgets('ortak geçmiş yoksa bölüm hiç görünmez',
        (WidgetTester tester) async {
      await kisiyiAc(tester, hayat());
      expect(find.text('Ortak geçmişiniz'), findsNothing);
    });

    testWidgets('ortak geçmiş varsa yaşıyla birlikte görünür',
        (WidgetTester tester) async {
      final GameState s = hayat();
      await kisiyiAc(
        tester,
        s.copyWith(
          gifts: <GiftRecord>[
            const GiftRecord(
              itemId: 'yoyo',
              fromId: 'anne-1',
              toId: GiftRecord.playerId,
              age: 8,
            ),
          ],
          log: <LifeLogEntry>[
            ...s.log,
            const LifeLogEntry(
              age: 12,
              text: 'Sema ile pazara gittiniz.',
              category: LogCategory.aile,
              personId: 'anne-1',
            ),
          ],
        ),
      );

      expect(find.text('Ortak geçmişiniz'), findsOneWidget);
      expect(find.text('8 yaşında'), findsOneWidget);
      expect(find.textContaining('Sema ile pazara gittiniz.'), findsOneWidget);
    });
  });
}

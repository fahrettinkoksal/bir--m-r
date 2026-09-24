import 'dart:math';

import 'package:bir_omur/app.dart';
import 'package:bir_omur/data/activity_catalog.dart';
import 'package:bir_omur/domain/activities/outing.dart';
import 'package:bir_omur/domain/generation/life_generator.dart';
import 'package:bir_omur/domain/models/game_state.dart';
import 'package:bir_omur/domain/models/gender.dart';
import 'package:bir_omur/domain/models/pending_notice.dart';
import 'package:bir_omur/domain/models/person.dart';
import 'package:bir_omur/domain/models/relation.dart';
import 'package:bir_omur/domain/models/wealth.dart';
import 'package:bir_omur/state/game_controller.dart';
import 'package:bir_omur/ui/sound/sound_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/test_flow.dart';

/// Eğlence aktivitelerinin gerçek kişilerle yapılması (Paket 41).
void main() {
  late GameController controller;

  setUp(() => controller = GameController(random: Random(12)));
  tearDown(() => controller.dispose());

  Person kisi({
    required String id,
    required String ad,
    required RelationType relation,
    int age = 34,
    int bond = 70,
  }) =>
      Person(
        id: id,
        firstName: ad,
        lastName: 'Yılmaz',
        gender: Gender.kadin,
        relation: relation,
        age: age,
        isAlive: true,
        inPlayerHousehold: true,
        employment: EmploymentStatus.issiz,
        wealth: WealthTier.ortaHalli,
        bond: bond,
      );

  GameState hayat() {
    final GameState base =
        LifeGenerator.seeded(53).generate(mode: StartMode.tamamenRastgele);
    return base.copyWith(
      pendingEvent: null,
      notices: const <PendingNotice>[],
      pets: const <Pet>[],
      people: <Person>[
        kisi(id: 'es-1', ad: 'Elif', relation: RelationType.es),
        kisi(id: 'cocuk-1', ad: 'Deniz', relation: RelationType.cocuk, age: 9),
        kisi(id: 'anne-1', ad: 'Hatice', relation: RelationType.anne, age: 60),
      ],
      player: base.player.copyWith(age: 34, wallet: 300000),
    );
  }

  Future<void> eglenceyiAc(
    WidgetTester tester, {
    Size boyut = const Size(1080, 5600),
  }) async {
    tester.view.physicalSize = boyut;
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      BirOmurApp(controller: controller, sound: SoundService.silent()),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Rastgele bir hayat'));
    await tester.pumpAndSettle();
    controller.debugSetState(hayat());
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('tab_aktiviteler')));
    await tester.pumpAndSettle();
    await scrollToFinder(tester, find.byKey(const Key('activity_eglence')));
    await tester.tap(find.byKey(const Key('activity_eglence')));
    await tester.pumpAndSettle();
  }

  testWidgets('kiminle seçimi gerçek kişileri listeler',
      (WidgetTester tester) async {
    await eglenceyiAc(tester);

    await scrollToFinder(
      tester,
      find.byKey(const Key('birlikte_sinema_yalniz')),
    );
    expect(find.byKey(const Key('birlikte_sinema_es-1')), findsOneWidget);
    expect(find.byKey(const Key('birlikte_sinema_cocuk-1')), findsOneWidget);
    expect(find.byKey(const Key('birlikte_sinema_anne-1')), findsOneWidget);
    // Kayıtta olmayan biri listelenmez.
    expect(find.byKey(const Key('birlikte_sinema_yok-1')), findsNothing);
  });

  testWidgets('yaşı uymayan çocuk konser listesinde yok',
      (WidgetTester tester) async {
    await eglenceyiAc(tester);
    await scrollToFinder(
      tester,
      find.byKey(const Key('birlikte_konsere_git_yalniz')),
    );
    // Konser 13 yaşından itibaren; 9 yaşındaki çocuk çıkmaz.
    expect(
      find.byKey(const Key('birlikte_konsere_git_cocuk-1')),
      findsNothing,
    );
    expect(find.byKey(const Key('birlikte_konsere_git_es-1')), findsOneWidget);
  });

  testWidgets('birlikte gidince iki kişilik ücret düşer, bağ artar ve '
      'ortak geçmişe tek satır düşer', (WidgetTester tester) async {
    await eglenceyiAc(tester);

    final int cuzdan = controller.state!.player.wallet;
    final int bag = controller.state!.personById('cocuk-1')!.bond;
    final int gunlukUzunlugu = controller.state!.log.length;
    final int ucret = kActivityActions
        .firstWhere((ActivityAction a) => a.id == 'sinema')
        .cost;

    await scrollToFinder(
      tester,
      find.byKey(const Key('birlikte_sinema_cocuk-1')),
    );
    await tester.tap(find.byKey(const Key('birlikte_sinema_cocuk-1')));
    await tester.pumpAndSettle();
    await scrollToFinder(tester, find.byKey(const Key('aktivite_sinema_yap')));
    await tester.tap(find.byKey(const Key('aktivite_sinema_yap')));
    await tester.pumpAndSettle();

    // Faho'nun Q-108 kararı: iki kişi gidiyorsa iki kişilik bilet.
    // Cüzdandan **tek bir kez** ama iki katı tutarında para çıkar.
    expect(controller.state!.player.wallet, cuzdan - ucret * 2);
    expect(controller.state!.personById('cocuk-1')!.bond, greaterThan(bag));
    expect(controller.state!.log.length, gunlukUzunlugu + 1);
    expect(controller.state!.log.last.personId, 'cocuk-1');
    expect(controller.state!.log.last.text, contains('Deniz'));
  });

  testWidgets('yalnız gitmek hâlâ mümkün ve kimseye kayıt düşmez',
      (WidgetTester tester) async {
    await eglenceyiAc(tester);
    await scrollToFinder(
      tester,
      find.byKey(const Key('aktivite_parkta_yuruyus_yap')),
    );
    await tester.tap(find.byKey(const Key('aktivite_parkta_yuruyus_yap')));
    await tester.pumpAndSettle();
    expect(controller.state!.log.last.personId, isNull);
  });

  for (final Size boyut in <Size>[
    const Size(1080, 5600), // 360 px
    const Size(1170, 5600), // 390 px
  ]) {
    final int mantiksal = (boyut.width / 3).round();
    testWidgets('$mantiksal px genişlikte eğlence ekranı taşmaz',
        (WidgetTester tester) async {
      final List<String> hatalar = <String>[];
      final void Function(FlutterErrorDetails)? eski = FlutterError.onError;
      FlutterError.onError = (FlutterErrorDetails d) {
        final String metin = d.exceptionAsString();
        if (metin.contains('overflowed')) {
          hatalar.add(metin);
          return;
        }
        eski?.call(d);
      };
      addTearDown(() => FlutterError.onError = eski);

      await eglenceyiAc(tester, boyut: boyut);
      for (int i = 0; i < 10; i++) {
        await tester.drag(find.byType(Scrollable).first, const Offset(0, -400));
        await tester.pumpAndSettle();
      }
      // Bir seçim yapıp sonucu da göster: sonuç kartı da sınansın.
      await scrollToFinder(
        tester,
        find.byKey(const Key('birlikte_maca_git_es-1')),
      );
      await tester.tap(find.byKey(const Key('birlikte_maca_git_es-1')));
      await tester.pumpAndSettle();
      await scrollToFinder(
        tester,
        find.byKey(const Key('aktivite_maca_git_yap')),
      );
      await tester.tap(find.byKey(const Key('aktivite_maca_git_yap')));
      await tester.pumpAndSettle();

      expect(hatalar, isEmpty, reason: hatalar.join('\n'));
    });
  }

  test('sahne tablosu bütün eğlence eylemlerini kapsar', () {
    for (final ActivityAction a in actionsAt(ActivityVenue.eglence)) {
      expect(Outing.supports(a), isTrue, reason: a.id);
    }
  });
}

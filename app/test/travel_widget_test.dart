import 'dart:math';

import 'package:bir_omur/app.dart';
import 'package:bir_omur/domain/activities/travel.dart';
import 'package:bir_omur/domain/generation/life_generator.dart';
import 'package:bir_omur/domain/models/game_state.dart';
import 'package:bir_omur/domain/models/gender.dart';
import 'package:bir_omur/domain/models/person.dart';
import 'package:bir_omur/domain/models/relation.dart';
import 'package:bir_omur/domain/models/trip.dart';
import 'package:bir_omur/state/game_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/generation_fixtures.dart';
import 'support/test_flow.dart';

/// Aktiviteler → Seyahat akışı (Paket 11).
void main() {
  late GameController controller;

  setUp(() => controller = GameController(random: Random(21)));
  tearDown(() => controller.dispose());

  GameState gezgin({int age = 30, int wallet = 200000}) {
    final GameState base =
        LifeGenerator.seeded(91).generate(mode: StartMode.tamamenRastgele);
    return base.copyWith(
      pendingEvent: null,
      player: base.player.copyWith(age: age, wallet: wallet),
      people: <Person>[
        kisi(
          id: 'es-1',
          relation: RelationType.es,
          gender: Gender.kadin,
          age: 30,
          firstName: 'Elif',
          hane: true,
          city: base.player.currentCity,
        ),
      ],
    );
  }

  Future<void> pumpApp(WidgetTester tester, GameState state) async {
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
    await tester.tap(find.byKey(const Key('tab_aktiviteler')));
    await tester.pumpAndSettle();
  }

  testWidgets('Aktiviteler menüsünde Seyahat var ve gezi gerçekten yapılır',
      (WidgetTester tester) async {
    await pumpApp(tester, gezgin());
    await tapMenuRow(tester, 'Seyahat');

    // Şehir seçilmeden yola çıkılamaz.
    expect(find.byKey(const Key('trip_go')), findsNothing);
    expect(find.textContaining('Önce bir şehir seç'), findsOneWidget);

    final String sehir = controller.travelDestinations().first;
    await tester.tap(find.byKey(Key('trip_city_$sehir')));
    await tester.pumpAndSettle();

    final int cuzdan = controller.state!.player.wallet;
    await tester.tap(find.byKey(const Key('trip_go')));
    await tester.pumpAndSettle();

    expect(controller.state!.trips, hasLength(1));
    expect(controller.state!.trips.single.city, sehir);
    expect(
      controller.state!.player.wallet,
      cuzdan - TravelMode.otobus.prototypeOnlyCost,
    );
    // Gezi taşınma değildir.
    expect(controller.state!.player.currentCity, isNot(sehir));
  });

  testWidgets('yakınla gidilince ücret artar ve kayıtta kişi görünür',
      (WidgetTester tester) async {
    await pumpApp(tester, gezgin());
    await tapMenuRow(tester, 'Seyahat');

    final String sehir = controller.travelDestinations().first;
    await tester.tap(find.byKey(Key('trip_city_$sehir')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('trip_companion_es-1')));
    await tester.pumpAndSettle();

    final int cuzdan = controller.state!.player.wallet;
    await tester.tap(find.byKey(const Key('trip_go')));
    await tester.pumpAndSettle();

    final TripRecord gezi = controller.state!.trips.single;
    expect(gezi.companionId, 'es-1');
    expect(
      controller.state!.player.wallet,
      cuzdan - Travel.costOf(TravelMode.otobus, withCompanion: true),
    );
    // Gezi anısı ekranda görünür.
    expect(find.textContaining('Elif'), findsWidgets);
  });

  testWidgets('parası yetmeyene düğme yerine gerekçe gösterilir',
      (WidgetTester tester) async {
    await pumpApp(tester, gezgin(wallet: 200));
    await tapMenuRow(tester, 'Seyahat');

    final String sehir = controller.travelDestinations().first;
    await tester.tap(find.byKey(Key('trip_city_$sehir')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('trip_go')), findsNothing);
    expect(find.textContaining('yeterli para yok'), findsOneWidget);
    expect(controller.state!.trips, isEmpty);
  });

  testWidgets('arabası olmayana kendi aracı seçeneği hiç gösterilmez',
      (WidgetTester tester) async {
    await pumpApp(tester, gezgin());
    await tapMenuRow(tester, 'Seyahat');

    expect(find.byKey(const Key('trip_mode_otobus')), findsOneWidget);
    expect(find.byKey(const Key('trip_mode_kendiArabasi')), findsNothing);
  });

  testWidgets('küçük yaşta Seyahat menüde görünmez',
      (WidgetTester tester) async {
    await pumpApp(tester, gezgin(age: 12));
    expect(find.text('Seyahat'), findsNothing);
  });
}

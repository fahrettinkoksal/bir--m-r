import 'dart:math';

import 'package:bir_omur/app.dart';
import 'package:bir_omur/data/lottery_catalog.dart';
import 'package:bir_omur/domain/generation/life_generator.dart';
import 'package:bir_omur/domain/models/game_settings.dart';
import 'package:bir_omur/domain/models/game_state.dart';
import 'package:bir_omur/domain/models/pending_notice.dart';
import 'package:bir_omur/state/game_controller.dart';
import 'package:bir_omur/ui/sound/sound_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/test_flow.dart';

/// Milli Piyango ekranı (Paket 33).
void main() {
  late GameController controller;

  setUp(() => controller = GameController(random: Random(8)));
  tearDown(() => controller.dispose());

  GameState hayat({int age = 30, int wallet = 50000, bool kumar = true}) {
    final GameState base =
        LifeGenerator.seeded(97).generate(mode: StartMode.tamamenRastgele);
    return base.copyWith(
      pendingEvent: null,
      notices: const <PendingNotice>[],
      settings: GameSettings(casinoEnabled: kumar),
      player: base.player.copyWith(age: age, wallet: wallet),
    );
  }

  Future<void> aktivitelerdeAc(WidgetTester tester, GameState state) async {
    tester.view.physicalSize = const Size(1080, 5600);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      BirOmurApp(controller: controller, sound: SoundService.silent()),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Rastgele bir hayat'));
    await tester.pumpAndSettle();
    controller.debugSetState(state);
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('tab_aktiviteler')));
    await tester.pumpAndSettle();
  }

  testWidgets('bayi menüde görünür ve açılır', (WidgetTester tester) async {
    await aktivitelerdeAc(tester, hayat());

    await scrollToFinder(tester, find.byKey(const Key('activity_piyango')));
    await tester.tap(find.byKey(const Key('activity_piyango')));
    await tester.pumpAndSettle();

    expect(find.text('Milli Piyango'), findsWidgets);
    expect(find.text(LotteryDraw.yilbasi.label), findsOneWidget);
    expect(find.text('Amorti'), findsWidgets);
  });

  testWidgets('bilet alınca cüzdan düşer ve bilet listelenir',
      (WidgetTester tester) async {
    await aktivitelerdeAc(tester, hayat());
    await scrollToFinder(tester, find.byKey(const Key('activity_piyango')));
    await tester.tap(find.byKey(const Key('activity_piyango')));
    await tester.pumpAndSettle();

    final int once = controller.state!.player.wallet;
    await scrollToFinder(
      tester,
      find.byKey(const Key('piyango_aylik_ceyrek')),
    );
    await tester.tap(find.byKey(const Key('piyango_aylik_ceyrek')));
    await tester.pumpAndSettle();

    expect(
      controller.state!.player.wallet,
      once - LotteryDraw.aylik.priceFor(TicketShare.ceyrek),
    );
    expect(controller.lotteryTickets, hasLength(1));

    // Bilet listesi sayfanın başındadır; alınan bilet orada görünür.
    await tester.drag(find.byType(Scrollable).first, const Offset(0, 1200));
    await tester.pumpAndSettle();
    expect(find.text('Bekleyen biletlerin'), findsOneWidget);
    expect(
      find.text(controller.lotteryTickets.first.number),
      findsOneWidget,
    );
  });

  testWidgets('parası yetmeyince düğme kapalı olur',
      (WidgetTester tester) async {
    await aktivitelerdeAc(tester, hayat(wallet: 20));
    await scrollToFinder(tester, find.byKey(const Key('activity_piyango')));
    await tester.tap(find.byKey(const Key('activity_piyango')));
    await tester.pumpAndSettle();

    await scrollToFinder(
      tester,
      find.byKey(const Key('piyango_yilbasi_tam')),
    );
    final FilledButton dugme = tester.widget<FilledButton>(
      find.byKey(const Key('piyango_yilbasi_tam')),
    );
    expect(dugme.onPressed, isNull);
  });

  testWidgets('kumar kapalıyken bayi menüde yok',
      (WidgetTester tester) async {
    await aktivitelerdeAc(tester, hayat(kumar: false));
    expect(find.byKey(const Key('activity_piyango')), findsNothing);
  });

  testWidgets('18 yaşından küçüğe bayi gösterilmez',
      (WidgetTester tester) async {
    await aktivitelerdeAc(tester, hayat(age: 15));
    expect(find.byKey(const Key('activity_piyango')), findsNothing);
  });
}

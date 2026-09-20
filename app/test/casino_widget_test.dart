import 'dart:math';

import 'package:bir_omur/app.dart';
import 'package:bir_omur/domain/casino/casino_rules.dart';
import 'package:bir_omur/domain/generation/life_generator.dart';
import 'package:bir_omur/domain/models/game_state.dart';
import 'package:bir_omur/state/game_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Kumarhane masalarının arayüzde gerçekten çalıştığını sınar.
void main() {
  late GameController controller;

  setUp(() => controller = GameController(random: Random(21)));
  tearDown(() => controller.dispose());

  GameState yetiskin({int age = 25, int wallet = 100000}) {
    final GameState base =
        LifeGenerator.seeded(21).generate(mode: StartMode.tamamenRastgele);
    return base.copyWith(
      player: base.player.copyWith(age: age, wallet: wallet),
    );
  }

  Future<void> pumpApp(WidgetTester tester, GameState state) async {
    tester.view.physicalSize = const Size(1200, 3600);
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

  testWidgets('kumarhane 18 yaşından önce menüde görünmez',
      (WidgetTester tester) async {
    await pumpApp(tester, yetiskin(age: 16));
    expect(find.text('Kumarhane'), findsNothing);
  });

  testWidgets('blackjack eli açılır ve oynanır', (WidgetTester tester) async {
    await pumpApp(tester, yetiskin());

    await tester.tap(find.text('Kumarhane'));
    await tester.pumpAndSettle();
    expect(find.textContaining('sanal parasıyla'), findsOneWidget);

    await tester.tap(find.text('Blackjack'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Krupiye 17 ve üstünde durur'), findsOneWidget);

    final int cuzdanOnce = controller.state!.player.wallet;
    await tester.tap(find.byKey(const Key('bet_1000')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('blackjack_deal')));
    await tester.pumpAndSettle();

    expect(controller.blackjack, isNotNull);
    expect(controller.state!.player.wallet,
        cuzdanOnce - 1000 + controller.blackjack!.payout,
        reason: 'Bahis bir kez düşmeli');

    if (!controller.blackjack!.isFinished) {
      await tester.tap(find.byKey(const Key('blackjack_stand')));
      await tester.pumpAndSettle();
    }
    expect(controller.blackjack!.isFinished, isTrue);
    expect(find.byKey(const Key('blackjack_result')), findsOneWidget);

    await tester.tap(find.byKey(const Key('blackjack_close')));
    await tester.pumpAndSettle();
    expect(controller.blackjack, isNull);
  });

  testWidgets('rulet bahsi oynanır ve cüzdan bir kez değişir',
      (WidgetTester tester) async {
    await pumpApp(tester, yetiskin());

    await tester.tap(find.text('Kumarhane'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Rulet'));
    await tester.pumpAndSettle();

    final int once = controller.state!.player.wallet;
    await tester.tap(find.byKey(const Key('roulette_siyah')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('bet_1000')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('roulette_spin')));
    await tester.pumpAndSettle();

    final int sonra = controller.state!.player.wallet;
    expect(sonra == once - 1000 || sonra == once + 1000, isTrue,
        reason: 'Siyah bahsi ya 1000 kaybettirir ya 1000 kazandırır');
    expect(controller.wagerThisAge, 1000);
    expect(find.textContaining('çark'), findsOneWidget);
  });

  testWidgets('parası yetmeyen bahis düğmesi kapalıdır',
      (WidgetTester tester) async {
    await pumpApp(tester, yetiskin(wallet: 600));

    await tester.tap(find.text('Kumarhane'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Blackjack'));
    await tester.pumpAndSettle();

    // 500 ₺ oynanabilir, 1000 ₺ oynanamaz.
    expect(controller.betAvailability(CasinoRules.prototypeOnlyMinBet).isAllowed,
        isTrue);
    expect(controller.betAvailability(1000).isAllowed, isFalse);

    await tester.tap(find.byKey(const Key('bet_500')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('blackjack_deal')));
    await tester.pumpAndSettle();
    expect(controller.state!.player.wallet, greaterThanOrEqualTo(0));
  });
}

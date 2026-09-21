import 'dart:math';

import 'package:bir_omur/app.dart';
import 'package:bir_omur/domain/generation/life_generator.dart';
import 'package:bir_omur/domain/interaction/adoption.dart';
import 'package:bir_omur/domain/models/game_state.dart';
import 'package:bir_omur/state/game_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Aktiviteler → Evlat Edinme akışının gerçekten çalıştığını sınar (D-049).
void main() {
  late GameController controller;

  setUp(() => controller = GameController(random: Random(5)));
  tearDown(() => controller.dispose());

  GameState hayat({int age = 30, int wallet = 3000000}) {
    final GameState base =
        LifeGenerator.seeded(77).generate(mode: StartMode.tamamenRastgele);
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

  testWidgets('menüde Evlat Edinme var ve başvuru gerçekten işler',
      (WidgetTester tester) async {
    await pumpApp(tester, hayat());

    expect(find.text('Evlat Edinme'), findsOneWidget);
    await tester.tap(find.text('Evlat Edinme'));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('adoption_apply_button')), findsOneWidget);
    await tester.tap(find.byKey(const Key('adoption_apply_button')));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Başvur'));
    await tester.pumpAndSettle();

    // Sonuç ekranda gösterilir; olumlu ya da olumsuz olabilir.
    expect(find.byKey(const Key('adoption_result')), findsOneWidget);
    // Başvuru kayda girdi: aynı yıl ikinci başvuru açılmaz.
    expect(
      controller.state!.proposalAges[Adoption.attemptKey],
      controller.state!.player.age,
    );
  });

  testWidgets('parası yetmeyene düğme yerine gerekçe gösterilir',
      (WidgetTester tester) async {
    await pumpApp(tester, hayat(wallet: 500));

    await tester.tap(find.text('Evlat Edinme'));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('adoption_apply_button')), findsNothing);
    expect(find.textContaining('Şu an başvuramazsın'), findsOneWidget);
    expect(controller.state!.children, isEmpty);
  });

  testWidgets('küçük yaşta menüde görünmez', (WidgetTester tester) async {
    await pumpApp(tester, hayat(age: 12));
    expect(find.text('Evlat Edinme'), findsNothing);
  });
}

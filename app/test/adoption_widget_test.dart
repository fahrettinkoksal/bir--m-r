import 'dart:math';

import 'package:bir_omur/app.dart';
import 'package:bir_omur/domain/generation/life_generator.dart';
import 'package:bir_omur/domain/interaction/adoption.dart';
import 'package:bir_omur/domain/models/game_state.dart';
import 'package:bir_omur/domain/models/person.dart';
import 'package:bir_omur/state/game_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/test_flow.dart';

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
    await tapMenuRow(tester, 'Evlat Edinme');

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

    await tapMenuRow(tester, 'Evlat Edinme');

    expect(find.byKey(const Key('adoption_apply_button')), findsNothing);
    expect(find.textContaining('Şu an başvuramazsın'), findsOneWidget);
    expect(controller.state!.children, isEmpty);
  });

  testWidgets('evlat edinilen çocuğun kaydı ilişkilerde doğru anlatılır',
      (WidgetTester tester) async {
    // Gerçek bir kabul üretilir; ekran bu kayıttan okunur.
    final GameState zengin = hayat(age: 34);
    AdoptionResult? basarili;
    for (int seed = 0; seed < 40 && basarili == null; seed++) {
      final AdoptionResult r = const Adoption().apply(zengin, Random(seed));
      if (r.adopted) basarili = r;
    }
    expect(basarili, isNotNull);

    await pumpApp(tester, basarili!.state);
    await tester.tap(find.byKey(const Key('tab_iliskiler')));
    await tester.pumpAndSettle();
    // Evlat edinilen çocuk da İlişkiler → Çocuklar altında görünür.
    await tester.tap(find.text('Çocuklar').first);
    await tester.pumpAndSettle();

    final Person cocuk = controller.state!.children.single;
    await tester.tap(find.text(cocuk.fullName).first);
    await tester.pumpAndSettle();

    expect(find.text('Aileye katılışı'), findsOneWidget);
    expect(find.text('Evlat edinildi'), findsOneWidget);
  });

  testWidgets('küçük yaşta menüde görünmez', (WidgetTester tester) async {
    await pumpApp(tester, hayat(age: 12));
    expect(find.text('Evlat Edinme'), findsNothing);
  });
}

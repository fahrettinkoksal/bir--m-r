import 'dart:math';

import 'package:bir_omur/app.dart';
import 'package:bir_omur/domain/life/will.dart';
import 'package:bir_omur/domain/models/game_state.dart';
import 'package:bir_omur/domain/models/person.dart';
import 'package:bir_omur/domain/models/relation.dart';
import 'package:bir_omur/state/game_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/test_flow.dart';

import 'support/generation_fixtures.dart';

/// Aktiviteler → Vasiyet akışı (D-052).
void main() {
  late GameController controller;

  setUp(() => controller = GameController(random: Random(3)));
  tearDown(() => controller.dispose());

  GameState yasayan() => olenOyuncu(wallet: 400000).copyWith(
        deceased: false,
        player: olenOyuncu().player.copyWith(age: 60, wallet: 400000),
      );

  Future<void> pumpApp(WidgetTester tester, GameState state) async {
    tester.view.physicalSize = const Size(1200, 4000);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(BirOmurApp(controller: controller));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Rastgele bir hayat'));
    await tester.pumpAndSettle();
    controller.debugSetState(state.copyWith(pendingEvent: null));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('tab_aktiviteler')));
    await tester.pumpAndSettle();
  }

  testWidgets('menüde Vasiyet var ve mirasçı seçilebilir',
      (WidgetTester tester) async {
    await pumpApp(tester, yasayan());

    // Aktiviteler menüsü uzadı; satır önce görünür hale getirilir.
    await scrollToMenuRow(tester, 'Vasiyet');
    expect(find.text('Vasiyet'), findsOneWidget);
    expect(find.text('Mirasçı seçilmedi'), findsOneWidget);
    await tapMenuRow(tester, 'Vasiyet');

    await tester.tap(find.byKey(const Key('will_choose_cocuk-1')));
    await tester.pumpAndSettle();

    expect(controller.state!.heirChildId, 'cocuk-1');
    expect(find.byKey(const Key('will_badge_cocuk-1')), findsOneWidget);
    expect(find.textContaining('Mirasçın:'), findsWidgets);

    // Değiştirilebilir.
    await tester.tap(find.byKey(const Key('will_choose_cocuk-2')));
    await tester.pumpAndSettle();
    expect(controller.state!.heirChildId, 'cocuk-2');

    // Kaldırılabilir.
    await tester.tap(find.byKey(const Key('will_clear')));
    await tester.pumpAndSettle();
    expect(controller.state!.heirChildId, isNull);
  });

  testWidgets('çocuğu olmayan oyuncuda Vasiyet menüde görünmez',
      (WidgetTester tester) async {
    final GameState cocuksuz = yasayan().copyWith(
      people: yasayan()
          .people
          .where((Person p) => p.relation != RelationType.cocuk)
          .toList(growable: false),
    );
    await pumpApp(tester, cocuksuz);
    expect(find.text('Vasiyet'), findsNothing);
  });

  testWidgets('hayat özetinde ve devam listesinde mirasçı işaretlenir',
      (WidgetTester tester) async {
    final GameState vasiyetli = Will.choose(yasayan(), 'cocuk-1').state;
    await pumpApp(tester, vasiyetli);

    // Hayat tamamlanınca özet ekranında vasiyet görünür.
    controller.debugSetState(
      vasiyetli.copyWith(
        deceased: true,
        deathAge: vasiyetli.player.age,
        deathCause: 'yaşlılık',
      ),
    );
    await tester.pumpAndSettle();
    expect(find.textContaining('Mirasçı: Elif'), findsOneWidget);

    await tester.tap(
      find.byKey(const Key('life_summary_continue_generation')),
    );
    await tester.pumpAndSettle();
    expect(find.textContaining('vasiyetinde mirasçı'), findsOneWidget);

    // Vasiyet zorunlu değil: başka çocukla da devam edilebilir.
    await tester.tap(find.byKey(const Key('continue_child_cocuk-2')));
    await tester.pumpAndSettle();
    expect(controller.state!.player.firstName, 'Kerem');
  });
}

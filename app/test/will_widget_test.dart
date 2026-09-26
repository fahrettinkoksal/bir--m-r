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
    // Hayat özeti değerlendirme paneliyle birlikte uzadı (Paket 22);
    // `findsNothing` beklentileri anlamını korusun diye bütün ekran
    // görünür alana sığdırılır.
    tester.view.physicalSize = const Size(1200, 7000);
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

  testWidgets('menüde Son Kararlar var ve mirasçı seçilebilir',
      (WidgetTester tester) async {
    await pumpApp(tester, yasayan());

    // Aktiviteler menüsü uzadı; satır önce görünür hale getirilir.
    await scrollToMenuRow(tester, 'Son Kararlar');
    expect(find.text('Son Kararlar'), findsOneWidget);
    expect(find.text('Mirasçı ve hayatının sonu'), findsOneWidget);
    await tapMenuRow(tester, 'Son Kararlar');

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

  testWidgets(
      'çocuğu olmayan oyuncuda mirasçı seçimi kapalıdır ama menü açıktır',
      (WidgetTester tester) async {
    // D-084 ile bu menü "Son Kararlar" oldu ve mirasçı seçiminin yanında
    // hayatın sonuna dair kararı da taşıyor. O karar çocuğa bağlı
    // olmadığı için menü yetişkin oyuncuya açık; mirasçı bölümü ise
    // gerekçesini yazıyor (D-038).
    final GameState cocuksuz = yasayan().copyWith(
      people: yasayan()
          .people
          .where((Person p) => p.relation != RelationType.cocuk)
          .toList(growable: false),
    );
    await pumpApp(tester, cocuksuz);
    await scrollToMenuRow(tester, 'Son Kararlar');
    await tapMenuRow(tester, 'Son Kararlar');

    // Mirasçı yapılabilecek kimse gösterilmez.
    expect(find.textContaining('Mirasçı yap'), findsNothing);
    // Hayatın sonu bölümü ve gerçek destek bilgisi görünür.
    expect(find.byKey(const Key('life_end_open')), findsOneWidget);
    expect(find.textContaining('ALO 183'), findsWidgets);
  });

  testWidgets('hayata son verme onay ister ve vazgeçilebilir',
      (WidgetTester tester) async {
    await pumpApp(tester, yasayan());
    await scrollToMenuRow(tester, 'Son Kararlar');
    await tapMenuRow(tester, 'Son Kararlar');

    await scrollToFinder(tester, find.byKey(const Key('life_end_open')));
    await tester.tap(find.byKey(const Key('life_end_open')));
    await tester.pumpAndSettle();

    // Onay ekranında gerçek yardım bilgisi yazar.
    expect(find.textContaining('ALO 183'), findsWidgets);

    await tester.tap(find.byKey(const Key('life_end_cancel')));
    await tester.pumpAndSettle();
    expect(controller.state!.deceased, isFalse,
        reason: 'Vazgeçince hayat devam etmeli');
  });

  testWidgets('onaylanınca hayat biter ve çocuktan devam açılır',
      (WidgetTester tester) async {
    await pumpApp(tester, yasayan());
    await scrollToMenuRow(tester, 'Son Kararlar');
    await tapMenuRow(tester, 'Son Kararlar');

    await scrollToFinder(tester, find.byKey(const Key('life_end_open')));
    await tester.tap(find.byKey(const Key('life_end_open')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('life_end_confirm')));
    await tester.pumpAndSettle();

    expect(controller.state!.deceased, isTrue);
    expect(controller.state!.deathAge, isNotNull);
    // Kayıt silinmez ve çocuktan devam etme yolu açık kalır.
    expect(controller.canContinueGeneration, isTrue);
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

import 'dart:math';

import 'package:bir_omur/app.dart';
import 'package:bir_omur/data/save/save_service.dart';
import 'package:bir_omur/data/save/save_store.dart';
import 'package:bir_omur/domain/generation/life_generator.dart';
import 'package:bir_omur/state/game_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/test_flow.dart';

/// İçinde geçerli bir kayıt bulunan depo üretir.
Future<MemorySaveStore> storeWithSave({int seed = 3, int age = 9}) async {
  final MemorySaveStore store = MemorySaveStore();
  final GameController controller = GameController(
    random: Random(seed),
    saveService: SaveService(store),
  );
  controller.startNewLife(mode: StartMode.tamamenRastgele, seed: seed);
  advanceToAge(controller, age);
  await controller.flushSaves();
  controller.dispose();
  return store;
}

void main() {
  testWidgets('kayıt yokken Devam Et gösterilmez', (WidgetTester tester) async {
    final GameController controller = GameController(
      random: Random(1),
      saveService: SaveService(MemorySaveStore()),
    );
    await controller.checkForSavedLife();
    await tester.pumpWidget(BirOmurApp(controller: controller));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('continue_button')), findsNothing);
    expect(find.text('Rastgele bir hayat'), findsOneWidget);
    controller.dispose();
  });

  testWidgets('kayıt varken Devam Et aynı hayata döner',
      (WidgetTester tester) async {
    final MemorySaveStore store = await storeWithSave();
    final GameController controller = GameController(
      random: Random(77),
      saveService: SaveService(store),
    );
    await controller.checkForSavedLife();

    await tester.pumpWidget(BirOmurApp(controller: controller));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('continue_button')), findsOneWidget);
    await tester.tap(find.byKey(const Key('continue_button')));
    await tester.pumpAndSettle();

    expect(controller.hasLife, isTrue);
    expect(controller.state!.player.age, 9);
    controller.dispose();
  });

  testWidgets('yeni hayat onay ister; vazgeçilince kayıt silinmez',
      (WidgetTester tester) async {
    final MemorySaveStore store = await storeWithSave(seed: 4);
    final String kayitOnce = (await store.read())!;

    final GameController controller = GameController(
      random: Random(78),
      saveService: SaveService(store),
    );
    await controller.checkForSavedLife();
    await tester.pumpWidget(BirOmurApp(controller: controller));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Yeni hayat (rastgele)'));
    await tester.pumpAndSettle();
    expect(find.text('Kayıtlı hayatın silinsin mi?'), findsOneWidget);

    await tester.tap(find.text('Vazgeç'));
    await tester.pumpAndSettle();

    expect(controller.hasLife, isFalse, reason: 'Yeni hayat başlamamalı');
    expect(await store.read(), kayitOnce, reason: 'Kayıt korunmalı');
    expect(find.byKey(const Key('continue_button')), findsOneWidget);
    controller.dispose();
  });

  testWidgets('onaylanınca yeni hayat başlar ve kayıt yenilenir',
      (WidgetTester tester) async {
    final MemorySaveStore store = await storeWithSave(seed: 5, age: 12);
    final String kayitOnce = (await store.read())!;

    final GameController controller = GameController(
      random: Random(79),
      saveService: SaveService(store),
    );
    await controller.checkForSavedLife();
    await tester.pumpWidget(BirOmurApp(controller: controller));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Yeni hayat (rastgele)'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Sil ve yeni hayat başlat'));
    await tester.pumpAndSettle();
    await controller.flushSaves();

    expect(controller.hasLife, isTrue);
    expect(controller.state!.player.age, 0);
    expect(await store.read(), isNot(kayitOnce));
    controller.dispose();
  });

  testWidgets('bozuk kayıt ekranda bildirilir, dosyaya dokunulmaz',
      (WidgetTester tester) async {
    final MemorySaveStore store = MemorySaveStore(initial: 'bozuk içerik');
    final GameController controller = GameController(
      random: Random(80),
      saveService: SaveService(store),
    );
    await controller.checkForSavedLife();
    await controller.restoreSavedLife();

    await tester.pumpWidget(BirOmurApp(controller: controller));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('continue_button')), findsNothing,
        reason: 'Açılamayan kayıt için Devam Et sunulmaz');
    expect(find.textContaining('Kayıt dosyasına dokunulmadı'), findsOneWidget);
    expect(await store.read(), 'bozuk içerik');
    expect(store.writeCount, 0);
    controller.dispose();
  });

  testWidgets('oyun oynanınca kayıt güncellenir', (WidgetTester tester) async {
    final MemorySaveStore store = MemorySaveStore();
    final GameController controller = GameController(
      random: Random(81),
      saveService: SaveService(store),
    );
    await controller.checkForSavedLife();
    await tester.pumpWidget(BirOmurApp(controller: controller));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Rastgele bir hayat'));
    await tester.pumpAndSettle();
    await controller.flushSaves();
    final int yazmaOnce = store.writeCount;

    await answerPendingEvents(tester, controller);
    await tester.tap(find.byKey(const Key('age_up_button')));
    await tester.pumpAndSettle();
    await controller.flushSaves();

    expect(store.writeCount, greaterThan(yazmaOnce));
    final SaveLoadResult result = await SaveService(store).load();
    expect(result.isLoaded, isTrue);
    expect(result.state!.player.age, controller.state!.player.age);
    controller.dispose();
  });
}

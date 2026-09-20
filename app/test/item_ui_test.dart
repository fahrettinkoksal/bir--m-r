import 'dart:math';

import 'package:bir_omur/app.dart';
import 'package:bir_omur/domain/models/game_state.dart';
import 'package:bir_omur/domain/models/owned_item.dart';
import 'package:bir_omur/state/game_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/test_flow.dart';

/// Oyunu başlatır, belirtilen yaşa getirir ve envantere eşya koyar.
Future<GameController> startWith(
  WidgetTester tester, {
  required List<String> typeIds,
  int age = 16,
  int wallet = 3000,
  int seed = 51,
  int condition = 60,
}) async {
  final GameController controller = GameController(random: Random(seed));
  await tester.pumpWidget(BirOmurApp(controller: controller));
  await tester.pumpAndSettle();
  await tester.tap(find.text('Rastgele bir hayat'));
  await tester.pumpAndSettle();
  await answerPendingEvents(tester, controller);
  await ageTo(tester, controller, age);
  await answerPendingEvents(tester, controller);

  GameState state = controller.state!;
  state = state.copyWith(player: state.player.copyWith(wallet: wallet));
  state = state.grantItems(
    typeIds,
    source: ItemSource.hediye,
    condition: condition,
  );
  controller.debugSetState(state);
  await tester.pumpAndSettle();
  return controller;
}

Future<void> openAssets(WidgetTester tester) async {
  await tester.tap(find.byKey(const Key('tab_varliklar')));
  await tester.pumpAndSettle();
}

/// Liste uzun olduğunda hedef görünene kadar kaydırır.
///
/// `SectionScaffold` bir `ListView` kullandığı için ekran dışındaki kartlar
/// henüz oluşturulmamış olabilir.
Future<void> scrollTo(WidgetTester tester, Finder hedef) async {
  if (hedef.evaluate().isNotEmpty) return;
  await tester.dragUntilVisible(
    hedef,
    find.byType(Scrollable).first,
    const Offset(0, -120),
  );
  await tester.pumpAndSettle();
}

/// Varlıklar'ı açar ve verilen eşyanın kartına dokunur.
Future<void> openItem(WidgetTester tester, String name) async {
  await openAssets(tester);
  await scrollTo(tester, find.text(name));
  await tester.tap(find.text(name));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('eşya Varlıklar\'da listelenir ve detayı açılır',
      (WidgetTester tester) async {
    final GameController controller =
        await startWith(tester, typeIds: <String>['bisiklet']);
    await openAssets(tester);
    await scrollTo(tester, find.text('Bisiklet'));
    expect(find.text('Bisiklet'), findsOneWidget);
    await tester.tap(find.text('Bisiklet'));
    await tester.pumpAndSettle();

    // Türüne uygun eylemler görünür.
    expect(find.text('Bisiklete bin'), findsOneWidget);
    expect(find.text('Temizle'), findsOneWidget);
    expect(find.textContaining('Bakım yap ('), findsOneWidget);
    expect(find.textContaining('Sat ('), findsOneWidget);
    // Türüne uymayan eylem hiç yok.
    expect(find.text('Tak'), findsNothing);
    expect(controller.state!.items.single.typeId, 'bisiklet');
  });

  testWidgets('bisiklete binmek kondisyonu düşürür ve rozet gösterir',
      (WidgetTester tester) async {
    final GameController controller =
        await startWith(tester, typeIds: <String>['bisiklet']);
    final String id = controller.state!.items.single.id;
    final int once = controller.state!.itemById(id)!.condition;

    await openItem(tester, 'Bisiklet');
    await tester.tap(find.text('Bisiklete bin'));
    await tester.pumpAndSettle();

    expect(controller.state!.itemById(id)!.condition, lessThan(once));
    expect(find.textContaining('kondisyonu'), findsWidgets);
  });

  testWidgets('kol saatinde bisiklet eylemi gösterilmez',
      (WidgetTester tester) async {
    await startWith(tester, typeIds: <String>['kol_saati'], age: 20);
    await openItem(tester, 'Kol saati');

    expect(find.text('Tak'), findsOneWidget);
    expect(find.text('Bisiklete bin'), findsNothing);
    expect(find.text('Aksesuar tak'), findsNothing);
  });

  testWidgets('parası yetmeyen ürün satın alınamaz',
      (WidgetTester tester) async {
    final GameController controller = await startWith(
      tester,
      typeIds: <String>[],
      wallet: 5,
      age: 14,
    );
    await openAssets(tester);
    await tester.tap(find.text('Mağaza'));
    await tester.pumpAndSettle();

    await scrollTo(tester, find.text('Paran yetmiyor').first);
    expect(find.text('Paran yetmiyor'), findsWidgets);
    expect(controller.state!.player.wallet, 5);
    expect(controller.state!.items, isEmpty);
  });

  testWidgets('mağazadan alınan ürün envantere girer ve para bir kez düşer',
      (WidgetTester tester) async {
    final GameController controller = await startWith(
      tester,
      typeIds: <String>[],
      wallet: 1000,
      age: 14,
    );
    await openAssets(tester);
    await tester.tap(find.text('Mağaza'));
    await tester.pumpAndSettle();

    await scrollTo(tester, find.text('Satın al').first);
    await tester.tap(find.text('Satın al').first);
    await tester.pumpAndSettle();

    expect(controller.state!.items.length, 1);
    expect(controller.state!.player.wallet, lessThan(1000));
    await scrollTo(tester, find.textContaining('satın alındı'));
    expect(find.textContaining('satın alındı'), findsOneWidget);
  });

  testWidgets('satıştan vazgeçilince eşya ve cüzdan değişmez',
      (WidgetTester tester) async {
    final GameController controller = await startWith(
      tester,
      typeIds: <String>['bisiklet'],
      age: 20,
      wallet: 100,
    );
    final int cuzdan = controller.state!.player.wallet;

    await openItem(tester, 'Bisiklet');
    await tester.tap(find.textContaining('Sat ('));
    await tester.pumpAndSettle();

    expect(find.textContaining('satılsın mı?'), findsOneWidget);
    await tester.tap(find.text('Vazgeç'));
    await tester.pumpAndSettle();

    expect(controller.state!.items.length, 1);
    expect(controller.state!.player.wallet, cuzdan);
  });

  testWidgets('satış onaylanınca eşya çıkar, para girer ve sayfa kapanır',
      (WidgetTester tester) async {
    final GameController controller = await startWith(
      tester,
      typeIds: <String>['bisiklet'],
      age: 20,
      wallet: 100,
    );
    final int bedel =
        controller.estimatedPriceFor(controller.state!.items.single);

    await openItem(tester, 'Bisiklet');
    await tester.tap(find.textContaining('Sat ('));
    await tester.pumpAndSettle();
    await tester.tap(find.textContaining('karşılığında sat'));
    await tester.pumpAndSettle();

    expect(controller.state!.items, isEmpty);
    expect(controller.state!.player.wallet, 100 + bedel);
    // Detay sayfası kapandı: satılmış eşyanın ekranı açık kalmaz.
    expect(find.text('Bisiklete bin'), findsNothing);
  });
}

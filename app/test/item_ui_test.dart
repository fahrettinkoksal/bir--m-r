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
  // Olay havuzu büyüdükçe aynı tohumdaki hayatın gidişatı değişiyor ve
  // bazı hayatlar hedef yaştan önce bitiyor. Bu testler eşya ekranını
  // sınar, belirli bir hayatı değil: hedef yaşa **sağ** ulaşan ilk tohum
  // kullanılır. Tohumlar sırayla denendiği için sonuç yine tekrarlanabilir.
  late GameController controller;
  int deneme = 0;
  while (true) {
    controller = GameController(random: Random(seed + deneme));
    // Anahtar denemeye göre değişir: aksi hâlde Flutter aynı State'i
    // koruyor ve yeni denetleyici hiç kullanılmıyordu.
    await tester.pumpWidget(
      BirOmurApp(key: ValueKey<int>(deneme), controller: controller),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Rastgele bir hayat'));
    await tester.pumpAndSettle();
    await answerPendingEvents(tester, controller);
    await ageTo(tester, controller, age);
    await answerPendingEvents(tester, controller);
    if (!controller.state!.deceased && controller.state!.player.age >= age) {
      break;
    }
    controller.dispose();
    if (deneme++ > 20) fail('Hedef yaşa ulaşan hayat bulunamadı.');
  }

  GameState state = controller.state!;
  state = state.copyWith(
    player: state.player.copyWith(wallet: wallet),
    // Bu testler yalnızca aşağıda verilen eşyayı inceler; miras veya olayla
    // gelmiş eşyalar listeyi karıştırmasın diye envanter sıfırlanır.
    items: const <OwnedItem>[],
  );
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
    await scrollTo(tester, find.text('Mağazalar'));
    await tester.tap(find.text('Mağazalar'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Genel mağaza'));
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
    await scrollTo(tester, find.text('Mağazalar'));
    await tester.tap(find.text('Mağazalar'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Genel mağaza'));
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

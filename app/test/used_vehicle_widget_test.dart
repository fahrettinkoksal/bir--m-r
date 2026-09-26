/// 2. el araç pazarı ve mağaza öbekleri ekran testleri (D-137, D-138).
library;

import 'dart:math';

import 'package:bir_omur/app.dart';
import 'package:bir_omur/domain/economy/used_vehicle_market.dart';
import 'package:bir_omur/domain/models/game_state.dart';
import 'package:bir_omur/domain/models/owned_item.dart';
import 'package:bir_omur/state/game_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/test_flow.dart';

/// Oyunu başlatır, hedef yaşa **sağ** ulaşan ilk tohumu kullanır ve
/// cüzdanı doldurur.
Future<GameController> startAdult(
  WidgetTester tester, {
  int age = 30,
  int wallet = 30000000,
  int seed = 12,
}) async {
  late GameController controller;
  int deneme = 0;
  while (true) {
    controller = GameController(random: Random(seed + deneme));
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

  final GameState state = controller.state!;
  controller.debugSetState(
    state.copyWith(
      player: state.player.copyWith(wallet: wallet),
      items: const <OwnedItem>[],
    ),
  );
  await tester.pumpAndSettle();
  return controller;
}

Future<void> openShops(WidgetTester tester) async {
  await tester.tap(find.byKey(const Key('tab_varliklar')));
  await tester.pumpAndSettle();
  await tapMenuRow(tester, 'Mağazalar');
}

void main() {
  testWidgets('mağazalar üç öbekte listelenir', (WidgetTester tester) async {
    await startAdult(tester);
    await openShops(tester);

    // Öbek başlıkları görünür (D-138).
    expect(find.text('Gündelik alışveriş'), findsOneWidget);
    await scrollToFinder(tester, find.text('Araç ve aksesuar'));
    expect(find.text('Araç ve aksesuar'), findsOneWidget);
    await scrollToFinder(tester, find.byKey(const Key('magaza_emlakciLuks')));
    expect(find.text('Konut'), findsOneWidget);
  });

  testWidgets('2. el araç pazarı ilan detaylarıyla açılır',
      (WidgetTester tester) async {
    final GameController controller = await startAdult(tester);
    await openShops(tester);
    await tapMenuRow(tester, '2. el araç pazarı');

    expect(find.text('Araç detayları'), findsWidgets);
    // Faho'nun istediği ilan dili ekranda görünüyor.
    expect(find.textContaining('oynama yoktur'), findsWidgets);

    final UsedVehicleListing ilk =
        UsedVehicleMarket.listingsFor(controller.state!).first;
    expect(find.text(ilk.name), findsWidgets);
    expect(find.textContaining('${ilk.ageYears} yaşında'), findsWidgets);
  });

  testWidgets('pazardan alınan araç ikinci el kondisyonuyla envantere girer',
      (WidgetTester tester) async {
    final GameController controller = await startAdult(tester);
    final UsedVehicleListing ilan =
        UsedVehicleMarket.listingsFor(controller.state!).first;

    await openShops(tester);
    await tapMenuRow(tester, '2. el araç pazarı');
    await scrollToFinder(tester, find.byKey(Key('ikinci_el_${ilan.id}')));
    await tester.tap(find.byKey(Key('ikinci_el_${ilan.id}')));
    await tester.pumpAndSettle();

    final OwnedItem araba = controller.state!.items.last;
    expect(araba.typeId, ilan.typeId);
    expect(araba.condition, ilan.condition);
    expect(araba.purchasePrice, ilan.price);
  });
}

import 'dart:math';

import 'package:bir_omur/app.dart';
import 'package:bir_omur/domain/interaction/fertility_treatment.dart';
import 'package:bir_omur/domain/models/game_state.dart';
import 'package:bir_omur/state/game_controller.dart';
import 'package:bir_omur/ui/sound/sound_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fertility_treatment_test.dart' show cift;
import 'support/test_flow.dart';

/// Tüp bebek ekranı (Paket 35).
void main() {
  late GameController controller;

  setUp(() => controller = GameController(random: Random(21)));
  tearDown(() => controller.dispose());

  Future<void> saglikAc(WidgetTester tester, GameState state) async {
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
    await tapMenuRow(tester, 'Sağlık Merkezi');
  }

  testWidgets('denemiş çifte tüp bebek satırı görünür ve açılır',
      (WidgetTester tester) async {
    await saglikAc(tester, cift());

    expect(find.byKey(const Key('saglik_tup_bebek')), findsOneWidget);
    await tester.tap(find.byKey(const Key('saglik_tup_bebek')));
    await tester.pumpAndSettle();

    expect(find.text('Tüp bebek tedavisi'), findsWidgets);
    expect(find.textContaining('yaklaşık şans'), findsOneWidget);
  });

  testWidgets('hiç denememiş çifte kapı kapalı ve sebebi yazıyor',
      (WidgetTester tester) async {
    await saglikAc(tester, cift(tries: 0));

    await tester.tap(find.byKey(const Key('saglik_tup_bebek')));
    await tester.pumpAndSettle();

    final FilledButton dugme = tester.widget<FilledButton>(
      find.byKey(const Key('tup_bebek_dene')),
    );
    expect(dugme.onPressed, isNull);
    expect(find.textContaining('kendiniz'), findsOneWidget);
  });

  testWidgets('tedavi denenince ücret düşer ve sonuç yazılır',
      (WidgetTester tester) async {
    await saglikAc(tester, cift());
    await tester.tap(find.byKey(const Key('saglik_tup_bebek')));
    await tester.pumpAndSettle();

    final int once = controller.state!.player.wallet;
    await scrollToFinder(tester, find.byKey(const Key('tup_bebek_dene')));
    await tester.tap(find.byKey(const Key('tup_bebek_dene')));
    await tester.pumpAndSettle();

    expect(
      controller.state!.player.wallet,
      once - FertilityTreatment.prototypeOnlyCost,
    );
    expect(controller.fertilityAttempts, 1);
    expect(find.textContaining('ödediniz'), findsOneWidget);
  });

  testWidgets('eşi olmayan oyuncuya satır hiç gösterilmez',
      (WidgetTester tester) async {
    GameState s = cift();
    s = s.copyWith(
      people: s.people
          .where((dynamic p) => p.id != 'sevgili-1')
          .toList(growable: false)
          .cast(),
    );
    await saglikAc(tester, s);

    expect(find.byKey(const Key('saglik_tup_bebek')), findsNothing);
  });
}

import 'dart:math';

import 'package:bir_omur/app.dart';
import 'package:bir_omur/domain/generation/life_generator.dart';
import 'package:bir_omur/domain/life/notices.dart';
import 'package:bir_omur/domain/models/game_state.dart';
import 'package:bir_omur/domain/models/pending_notice.dart';
import 'package:bir_omur/state/game_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Bildirim penceresinin gerçekten çalıştığını sınar (D-050).
void main() {
  late GameController controller;

  setUp(() => controller = GameController(random: Random(9)));
  tearDown(() => controller.dispose());

  GameState hayat({int wallet = 300000}) {
    final GameState base =
        LifeGenerator.seeded(88).generate(mode: StartMode.tamamenRastgele);
    return base.copyWith(
      player: base.player.copyWith(age: 40, wallet: wallet),
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
    controller.debugSetState(state.copyWith(pendingEvent: null));
    await tester.pumpAndSettle();
  }

  testWidgets('ölüm bildirimi ekranda gösterilir ve bir kez açılır',
      (WidgetTester tester) async {
    final GameState state = Notices.enqueue(hayat(), <PendingNotice>[
      const PendingNotice(
        id: 'olum-anne-1',
        kind: NoticeKind.olum,
        age: 40,
        title: 'Bir kaybın var',
        text: 'Annen Hatice Yılmaz, 70 yaşında vefat etti.',
        happinessDelta: -12,
      ),
    ]);
    await pumpApp(tester, state);

    expect(find.byKey(const Key('notice_text')), findsOneWidget);
    expect(find.textContaining('Hatice Yılmaz'), findsOneWidget);
    expect(find.text('Mutluluk -12'), findsOneWidget);

    await tester.tap(find.byKey(const Key('notice_close')));
    await tester.pumpAndSettle();

    expect(controller.state!.hasNotice, isFalse);
    expect(find.byKey(const Key('notice_text')), findsNothing);
  });

  testWidgets('cenaze katkısı seçilir ve cüzdandan bir kez düşer',
      (WidgetTester tester) async {
    final GameState state = Notices.enqueue(hayat(), <PendingNotice>[
      PendingNotice(
        id: 'cenaze-anne-1',
        kind: NoticeKind.cenaze,
        age: 40,
        title: 'Cenaze masrafları',
        text: 'Annen Hatice için cenaze hazırlıkları yapılıyor.',
        funeralCost: Notices.prototypeOnlyFuneralCost,
      ),
    ]);
    await pumpApp(tester, state);
    final int cuzdan = controller.state!.player.wallet;

    expect(find.byKey(const Key('funeral_choice_tamKatki')), findsOneWidget);
    expect(find.byKey(const Key('funeral_choice_katkiYok')), findsOneWidget);
    await tester.tap(find.byKey(const Key('funeral_choice_tamKatki')));
    await tester.pumpAndSettle();

    expect(
      controller.state!.player.wallet,
      cuzdan - Notices.prototypeOnlyFuneralCost,
    );
    await tester.tap(find.byKey(const Key('notice_close')));
    await tester.pumpAndSettle();
    expect(controller.state!.hasNotice, isFalse);
  });

  testWidgets('parası yetmeyene tam katkı düğmesi gösterilmez',
      (WidgetTester tester) async {
    final GameState state = Notices.enqueue(hayat(wallet: 5000), <PendingNotice>[
      PendingNotice(
        id: 'cenaze-baba-1',
        kind: NoticeKind.cenaze,
        age: 40,
        title: 'Cenaze masrafları',
        text: 'Baban için cenaze hazırlıkları yapılıyor.',
        funeralCost: Notices.prototypeOnlyFuneralCost,
      ),
    ]);
    await pumpApp(tester, state);

    expect(find.byKey(const Key('funeral_choice_tamKatki')), findsNothing);
    expect(find.byKey(const Key('funeral_choice_kismiKatki')), findsOneWidget);
    await tester.tap(find.byKey(const Key('funeral_choice_kismiKatki')));
    await tester.pumpAndSettle();
    expect(controller.state!.player.wallet, greaterThanOrEqualTo(0));
  });

  testWidgets('bildirim kapanmadan olay penceresi açılmaz',
      (WidgetTester tester) async {
    final GameState state = Notices.enqueue(hayat(), <PendingNotice>[
      const PendingNotice(
        id: 'miras-anne-1',
        kind: NoticeKind.miras,
        age: 40,
        title: 'Miras',
        text: 'Annen Hatice mirasından payına 180.000 ₺ düştü.',
        money: 180000,
      ),
    ]);
    await pumpApp(tester, state);

    expect(find.byKey(const Key('notice_text')), findsOneWidget);
    expect(find.textContaining('Cüzdanına'), findsOneWidget);

    await tester.tap(find.byKey(const Key('notice_close')));
    await tester.pumpAndSettle();
    expect(controller.state!.hasNotice, isFalse);
  });
}

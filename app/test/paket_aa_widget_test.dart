import 'dart:math';

import 'package:bir_omur/app.dart';
import 'package:bir_omur/domain/generation/life_generator.dart';
import 'package:bir_omur/domain/models/game_state.dart';
import 'package:bir_omur/domain/models/investment.dart';
import 'package:bir_omur/domain/models/pending_notice.dart';
import 'package:bir_omur/state/game_controller.dart';
import 'package:bir_omur/ui/sound/sound_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/test_flow.dart';

/// Yatırımlar ekranı (D-162).
///
/// Ekranın gerçekten **çalıştığını** gösterir: satır Varlıklar altında
/// duruyor, alım cüzdanı düşürüyor, satış hızlı oranla yapılabiliyor,
/// vadeli hesabın kilidi yazıyor. Bu testler gerçek cihazda oynandığı
/// anlamına gelmez.
void main() {
  late GameController controller;

  setUp(() => controller = GameController(random: Random(31)));
  tearDown(() => controller.dispose());

  GameState hayat({
    int age = 35,
    int wallet = 300000,
    List<Holding> pozisyonlar = const <Holding>[],
    List<TermDeposit> vadeliler = const <TermDeposit>[],
  }) {
    final GameState base =
        LifeGenerator.seeded(8).generate(mode: StartMode.tamamenRastgele);
    return base.copyWith(
      pendingEvent: null,
      notices: const <PendingNotice>[],
      player: base.player.copyWith(age: age, wallet: wallet),
      movedOut: true,
      investments: pozisyonlar,
      termDeposits: vadeliler,
    );
  }

  Future<void> varliklarAc(WidgetTester tester, GameState state) async {
    tester.view.physicalSize = const Size(1080, 6400);
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
    await tester.tap(find.byKey(const Key('tab_varliklar')));
    await tester.pumpAndSettle();
  }

  Future<void> yatirimlarAc(WidgetTester tester, GameState state) async {
    await varliklarAc(tester, state);
    await tapMenuRow(tester, 'Yatırımlar');
    await tester.pumpAndSettle();
  }

  testWidgets('18 yaşından küçükte Yatırımlar satırı görünmez',
      (WidgetTester tester) async {
    await varliklarAc(tester, hayat(age: 15));
    expect(find.text('Yatırımlar'), findsNothing);
  });

  testWidgets('ekran beş türü öbekleriyle gösteriyor',
      (WidgetTester tester) async {
    await yatirimlarAc(tester, hayat());
    expect(find.byKey(const Key('portfolio_summary')), findsOneWidget);
    expect(find.byKey(const Key('market_mood')), findsOneWidget);
    expect(find.byKey(const Key('investment_vadeli')), findsOneWidget);
    expect(find.byKey(const Key('investment_altin')), findsOneWidget);
    expect(find.byKey(const Key('investment_doviz')), findsOneWidget);
    expect(find.byKey(const Key('investment_fon')), findsOneWidget);
    expect(find.byKey(const Key('investment_hisse')), findsOneWidget);
    expect(find.text('Güvenli'), findsOneWidget);
    expect(find.text('Koruyucu'), findsOneWidget);
    expect(find.text('Piyasa'), findsOneWidget);
  });

  testWidgets('alım cüzdandan düşüyor ve portföye yazıyor',
      (WidgetTester tester) async {
    await yatirimlarAc(tester, hayat(wallet: 300000));
    await tester.tap(find.byKey(const Key('investment_open_fon')));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('amount_fon')), '40000');
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('buy_fon')));
    await tester.pumpAndSettle();

    expect(controller.state!.player.wallet, 260000);
    expect(controller.state!.holdingOf('fon')!.value, 40000);
    expect(find.byKey(const Key('investment_result')), findsOneWidget);
  });

  testWidgets('tutar çok küçükse düğme kapalı ve gerekçe yazıyor',
      (WidgetTester tester) async {
    await yatirimlarAc(tester, hayat(wallet: 300000));
    await tester.tap(find.byKey(const Key('investment_open_hisse')));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('amount_hisse')), '50');
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('buy_block_hisse')), findsOneWidget);
    final FilledButton dugme = tester.widget<FilledButton>(
      find.byKey(const Key('buy_hisse')),
    );
    expect(dugme.onPressed, isNull);
  });

  testWidgets('hızlı oranla yarısı satılıyor', (WidgetTester tester) async {
    await yatirimlarAc(
      tester,
      hayat(
        wallet: 10000,
        pozisyonlar: const <Holding>[
          Holding(
            typeId: 'hisse',
            value: 80000,
            costBasis: 60000,
            totalInvested: 60000,
            realizedProfit: 0,
            firstBoughtAtAge: 30,
          ),
        ],
      ),
    );
    await tester.tap(find.byKey(const Key('investment_open_hisse')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('sell_hisse_50')));
    await tester.pumpAndSettle();

    expect(controller.state!.holdingOf('hisse')!.value, 40000);
    expect(controller.state!.player.wallet, 50000);
    // Gerçekleşen kâr: 40.000 satıldı, düşen maliyet 30.000.
    expect(controller.state!.holdingOf('hisse')!.realizedProfit, 10000);
  });

  testWidgets('vadeli hesabın kilidi ekranda yazıyor',
      (WidgetTester tester) async {
    await yatirimlarAc(
      tester,
      hayat(
        age: 40,
        vadeliler: const <TermDeposit>[
          TermDeposit(
            id: 'v1',
            amount: 50000,
            openedAtAge: 40,
            maturesAtAge: 41,
            rateBasis: 600,
          ),
        ],
      ),
    );
    await tester.tap(find.byKey(const Key('investment_open_vadeli')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('term_deposit_v1')), findsOneWidget);
    expect(find.textContaining('41 yaşında'), findsWidgets);
    expect(find.textContaining('faiz yanar'), findsOneWidget);

    await tester.tap(find.byKey(const Key('break_deposit_v1')));
    await tester.pumpAndSettle();
    expect(controller.state!.termDeposits, isEmpty);
    expect(controller.state!.player.wallet, 350000);
  });

  testWidgets('geçmiş alım satımdan sonra ekranda duruyor',
      (WidgetTester tester) async {
    await yatirimlarAc(tester, hayat(wallet: 300000));
    await tester.tap(find.byKey(const Key('investment_open_altin')));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('amount_altin')), '20000');
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('buy_altin')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('investment_history')), findsOneWidget);
    expect(find.textContaining('Alım'), findsWidgets);
  });
}

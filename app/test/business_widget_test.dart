/// Kendi İşim ekranı testleri (D-132, Paket W).
///
/// Faho bildirdi: "kendi işime para yatırmak istediğimde tutar yazmama
/// rağmen yatır seçeneği aktif olmuyor." Düğmenin açıklığı metin
/// kutusundan hesaplanıyordu ama yazı yazmak yeniden çizim tetiklemiyordu.
library;

import 'dart:math';

import 'package:bir_omur/app.dart';
import 'package:bir_omur/data/business_catalog.dart';
import 'package:bir_omur/domain/economy/business_engine.dart';
import 'package:bir_omur/domain/generation/life_generator.dart';
import 'package:bir_omur/domain/models/business.dart';
import 'package:bir_omur/domain/models/game_state.dart';
import 'package:bir_omur/state/game_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/test_flow.dart';

void main() {
  late GameController controller;

  setUp(() => controller = GameController(random: Random(5)));
  tearDown(() => controller.dispose());

  final BusinessType bufe = businessTypeById('is_buyfe')!;

  GameState isSahibi({int wallet = 3000000}) {
    final GameState base =
        LifeGenerator.seeded(19).generate(mode: StartMode.tamamenRastgele);
    // İş her zaman bol parayla kurulur; cüzdan **sonra** istenen değere
    // çekilir. Yoksa "parası yetmiyor" senaryosunda iş hiç kurulamaz ve
    // ekranda yatırım kutusu bulunmaz.
    final GameState hazir = base.copyWith(
      pendingEvent: null,
      player: base.player.copyWith(age: 30, wallet: 9000000),
      education: base.education.copyWith(enrolled: false, finished: true),
    );
    final GameState kurulu = BusinessEngine.open(state: hazir, tur: bufe).state;
    return kurulu.copyWith(
      player: kurulu.player.copyWith(wallet: wallet),
    );
  }

  Future<void> openBusinessPage(WidgetTester tester, GameState state) async {
    tester.view.physicalSize = const Size(1200, 6000);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(BirOmurApp(controller: controller));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Rastgele bir hayat'));
    await tester.pumpAndSettle();
    controller.debugSetState(state);
    await tester.pumpAndSettle();
    // İş kurmak bildirim kuyruğa koyuyor; pop-up ekranı kapatmasın.
    await answerPendingNotices(tester, controller);
    await tester.tap(find.byKey(const Key('tab_okul_meslek')));
    await tester.pumpAndSettle();
    await tapMenuRow(tester, 'Kendi İşim');
  }

  testWidgets('tutar yazılınca Yatır düğmesi açılır',
      (WidgetTester tester) async {
    await openBusinessPage(tester, isSahibi());

    final Finder dugme = find.byKey(const Key('business_invest'));
    await scrollToFinder(tester, dugme);
    // Boş kutuyla kapalı.
    expect(tester.widget<OutlinedButton>(dugme).onPressed, isNull);

    await tester.enterText(
      find.byKey(const Key('business_invest_amount')),
      '50000',
    );
    await tester.pumpAndSettle();

    // Yazı yazmak düğmeyi açmalı — bildirilen hata tam olarak buydu.
    expect(
      tester.widget<OutlinedButton>(dugme).onPressed,
      isNotNull,
      reason: 'Tutar yazıldığı hâlde Yatır kapalı kaldı',
    );
  });

  testWidgets('yatırılan para gerçekten işe girer',
      (WidgetTester tester) async {
    await openBusinessPage(tester, isSahibi());
    final int cuzdan = controller.state!.player.wallet;
    final Business once = BusinessEngine.openBusiness(controller.state!)!;

    await tester.enterText(
      find.byKey(const Key('business_invest_amount')),
      '50000',
    );
    await tester.pumpAndSettle();
    final Finder dugme = find.byKey(const Key('business_invest'));
    await scrollToFinder(tester, dugme);
    await tester.tap(dugme);
    await tester.pumpAndSettle();

    final Business sonra = BusinessEngine.openBusiness(controller.state!)!;
    expect(controller.state!.player.wallet, cuzdan - 50000);
    expect(sonra.totalInvested, once.totalInvested + 50000);
    expect(sonra.condition, greaterThan(once.condition));
  });

  testWidgets('parası yetmeyen tutarda düğme kapalı ve gerekçe yazılı',
      (WidgetTester tester) async {
    await openBusinessPage(tester, isSahibi(wallet: 1000));

    await tester.enterText(
      find.byKey(const Key('business_invest_amount')),
      '999999',
    );
    await tester.pumpAndSettle();

    final Finder dugme = find.byKey(const Key('business_invest'));
    await scrollToFinder(tester, dugme);
    expect(tester.widget<OutlinedButton>(dugme).onPressed, isNull);
    expect(find.textContaining('Cüzdanında'), findsWidgets);
  });

  testWidgets('işine bak yıllık sınıra takılır', (WidgetTester tester) async {
    await openBusinessPage(tester, isSahibi());

    final Finder dugme = find.byKey(const Key('business_tend'));
    for (int i = 0; i < BusinessEngine.prototypeOnlyTendPerAge; i++) {
      await scrollToFinder(tester, dugme);
      expect(
        tester.widget<FilledButton>(dugme).onPressed,
        isNotNull,
        reason: '${i + 1}. tıklama açık olmalı',
      );
      await tester.tap(dugme);
      await tester.pumpAndSettle();
      await answerPendingNotices(tester, controller);
    }
    await scrollToFinder(tester, dugme);
    expect(
      tester.widget<FilledButton>(dugme).onPressed,
      isNull,
      reason: 'Sınır dolduktan sonra düğme kapanmalı',
    );
    expect(find.textContaining('Bu yıl işine yeterince baktın'), findsWidgets);
  });
}

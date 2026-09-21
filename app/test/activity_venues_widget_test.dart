import 'dart:math';

import 'package:bir_omur/app.dart';
import 'package:bir_omur/data/activity_catalog.dart';
import 'package:bir_omur/domain/generation/life_generator.dart';
import 'package:bir_omur/domain/models/game_state.dart';
import 'package:bir_omur/state/game_controller.dart';
import 'package:bir_omur/ui/sound/sound_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/test_flow.dart';

/// Aktiviteler menüsündeki yeni alanlar (Paket 18).
void main() {
  late GameController controller;

  setUp(() => controller = GameController(random: Random(63)));
  tearDown(() => controller.dispose());

  GameState hayat({int age = 20, int wallet = 20000}) {
    final GameState base =
        LifeGenerator.seeded(97).generate(mode: StartMode.tamamenRastgele);
    return base.copyWith(
      pendingEvent: null,
      player: base.player.copyWith(age: age, wallet: wallet),
    );
  }

  Future<void> aktiviteleriAc(WidgetTester tester, GameState state) async {
    tester.view.physicalSize = const Size(1200, 5200);
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
  }

  testWidgets('üç yeni alan menüde görünür', (WidgetTester tester) async {
    await aktiviteleriAc(tester, hayat());

    expect(find.byKey(const Key('activity_saglik')), findsOneWidget);
    expect(find.byKey(const Key('activity_eglence')), findsOneWidget);
    expect(find.byKey(const Key('activity_kurs')), findsOneWidget);
  });

  testWidgets('yaşı tutmayan alan menüde hiç gösterilmez',
      (WidgetTester tester) async {
    // 2 yaşında: eğlencenin en küçük yaşı 4, kursunki 6.
    await aktiviteleriAc(tester, hayat(age: 2));

    expect(find.byKey(const Key('activity_eglence')), findsNothing);
    expect(find.byKey(const Key('activity_kurs')), findsNothing);
    // Sağlık merkezinde 1 yaşından itibaren aşı var.
    expect(find.byKey(const Key('activity_saglik')), findsOneWidget);
  });

  testWidgets('Sağlık Merkezi açılır ve eylemleri listeler',
      (WidgetTester tester) async {
    await aktiviteleriAc(tester, hayat());
    await tapMenuRow(tester, ActivityVenue.saglikMerkezi.label);

    expect(find.text('Genel sağlık kontrolü'), findsOneWidget);
    expect(find.text('Mevsim aşısı'), findsOneWidget);
    expect(find.text('Bir uzmanla konuş'), findsOneWidget);
  });

  testWidgets('eylem yapılınca para düşer ve değer gerçekten değişir',
      (WidgetTester tester) async {
    final GameState baslangic = hayat(wallet: 9000);
    await aktiviteleriAc(
      tester,
      baslangic.copyWith(
        player: baslangic.player.copyWith(
          stats: baslangic.player.stats.copyWith(health: 40),
        ),
      ),
    );
    await tapMenuRow(tester, ActivityVenue.saglikMerkezi.label);

    final ActivityAction a = activityActionById('genel_kontrol')!;
    await tester.tap(find.widgetWithText(FilledButton, 'Yap').first);
    await tester.pumpAndSettle();

    expect(controller.state!.player.wallet, 9000 - a.cost);
    expect(controller.state!.player.stats.health, greaterThan(40));
  });

  testWidgets('parası yetmeyen eylemin düğmesi kapalıdır',
      (WidgetTester tester) async {
    await aktiviteleriAc(tester, hayat(wallet: 0));
    await tapMenuRow(tester, ActivityVenue.kurs.label);

    // Kurslarda ücretsiz eylem yok; hepsi kapalı olmalı.
    expect(find.widgetWithText(FilledButton, 'Yap'), findsNothing);
    expect(find.textContaining('Şu an kapalı'), findsWidgets);
  });

  testWidgets('Eğlence sayfasında ücretsiz yürüyüş açık kalır',
      (WidgetTester tester) async {
    await aktiviteleriAc(tester, hayat(wallet: 0));
    await tapMenuRow(tester, ActivityVenue.eglence.label);

    expect(find.text('Parkta yürüyüş'), findsOneWidget);
    expect(find.text('Ücretsiz'), findsOneWidget);
    expect(find.widgetWithText(FilledButton, 'Yap'), findsOneWidget);
  });

  testWidgets('geri dönüş Aktiviteler listesine döner',
      (WidgetTester tester) async {
    await aktiviteleriAc(tester, hayat());
    await tapMenuRow(tester, ActivityVenue.kurs.label);
    expect(find.text('Dil kursu'), findsOneWidget);

    await tester.tap(find.byKey(const Key('section_back')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('activity_kurs')), findsOneWidget);
  });
}

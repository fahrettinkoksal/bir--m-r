import 'dart:math';

import 'package:bir_omur/app.dart';
import 'package:bir_omur/data/license_catalog.dart';
import 'package:bir_omur/data/license_questions.dart';
import 'package:bir_omur/domain/generation/life_generator.dart';
import 'package:bir_omur/domain/models/game_state.dart';
import 'package:bir_omur/state/game_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Ehliyet işlemlerinin arayüzde gerçekten çalıştığını sınar.
void main() {
  late GameController controller;

  setUp(() => controller = GameController(random: Random(31)));
  tearDown(() => controller.dispose());

  GameState hayat({int age = 20, int wallet = 200000}) {
    final GameState base =
        LifeGenerator.seeded(31).generate(mode: StartMode.tamamenRastgele);
    return base.copyWith(
      player: base.player.copyWith(age: age, wallet: wallet),
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
    controller.debugSetState(state);
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('tab_aktiviteler')));
    await tester.pumpAndSettle();
  }

  testWidgets('ehliyet menüsü küçük yaşta görünmez',
      (WidgetTester tester) async {
    await pumpApp(tester, hayat(age: 12));
    expect(find.text('Ehliyet İşlemleri'), findsNothing);
  });

  testWidgets('doğru cevap ehliyeti verir', (WidgetTester tester) async {
    await pumpApp(tester, hayat());

    await tester.tap(find.text('Ehliyet İşlemleri'));
    await tester.pumpAndSettle();
    expect(find.text('Motosiklet ehliyeti'), findsOneWidget);
    expect(find.text('Otomobil ehliyeti'), findsOneWidget);

    final int cuzdanOnce = controller.state!.player.wallet;
    await tester.tap(find.byKey(const Key('license_apply_otomobil')));
    await tester.pumpAndSettle();

    final LicenseQuestion soru = controller.pendingLicenseExam!.question!;
    expect(find.text(soru.text), findsOneWidget);
    expect(
      controller.state!.player.wallet,
      cuzdanOnce - prototypeOnlyExamFee(LicenseType.otomobil),
      reason: 'Ücret bir kez kesilmeli',
    );

    await tester.tap(find.byKey(Key('license_option_${soru.correctIndex}')));
    await tester.pumpAndSettle();

    expect(controller.hasLicense(LicenseType.otomobil), isTrue);
    expect(controller.hasLicense(LicenseType.motosiklet), isFalse);
    expect(find.byKey(const Key('license_result_title')), findsOneWidget);

    await tester.tap(find.text('Kapat'));
    await tester.pumpAndSettle();
    expect(controller.pendingLicenseExam, isNull);
  });

  testWidgets('yanlış cevapta ehliyet verilmez ve açıklama görünür',
      (WidgetTester tester) async {
    await pumpApp(tester, hayat());

    await tester.tap(find.text('Ehliyet İşlemleri'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('license_apply_motosiklet')));
    await tester.pumpAndSettle();

    final LicenseQuestion soru = controller.pendingLicenseExam!.question!;
    final int yanlis = (soru.correctIndex + 1) % soru.options.length;
    await tester.tap(find.byKey(Key('license_option_$yanlis')));
    await tester.pumpAndSettle();

    expect(controller.hasLicense(LicenseType.motosiklet), isFalse);
    expect(find.textContaining('Doğru cevap:'), findsOneWidget);
    expect(find.textContaining(soru.explanation), findsOneWidget);
  });

  testWidgets('parası yetmeyen başvuru düğmesi kapalıdır',
      (WidgetTester tester) async {
    await pumpApp(tester, hayat(wallet: 100));

    await tester.tap(find.text('Ehliyet İşlemleri'));
    await tester.pumpAndSettle();

    expect(controller.licenseAvailability(LicenseType.otomobil).isAllowed,
        isFalse);
    expect(find.textContaining('cüzdanında yeterli para yok'), findsWidgets);
    expect(controller.pendingLicenseExam, isNull);
  });
}

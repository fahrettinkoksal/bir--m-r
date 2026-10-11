import 'dart:math';

import 'package:bir_omur/app.dart';
import 'package:bir_omur/data/martial_arts_catalog.dart';
import 'package:bir_omur/domain/generation/life_generator.dart';
import 'package:bir_omur/domain/models/game_state.dart';
import 'package:bir_omur/state/game_controller.dart';
import 'package:bir_omur/ui/sound/sound_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/test_flow.dart';

/// Dövüş sanatları ekranı (Paket 32).
void main() {
  late GameController controller;

  setUp(() => controller = GameController(random: Random(11)));
  tearDown(() => controller.dispose());

  GameState hayat({int age = 20, int wallet = 20000}) {
    final GameState base =
        LifeGenerator.seeded(97).generate(mode: StartMode.tamamenRastgele);
    return base.copyWith(
      pendingEvent: null,
      player: base.player.copyWith(age: age, wallet: wallet),
    );
  }

  Future<void> dovuseGit(WidgetTester tester, GameState state) async {
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
    await tapMenuRow(tester, 'Spor salonu');
    await tester.tap(find.byKey(const Key('spor_dovus')));
    await tester.pumpAndSettle();
  }

  testWidgets('spor salonundan dövüş sanatlarına geçilir',
      (WidgetTester tester) async {
    await dovuseGit(tester, hayat());

    expect(find.text('Dövüş sanatları'), findsWidgets);
    // Ekran bir `ListView`; altta kalan dal henüz inşa edilmemiş olur.
    // Bu yüzden her dala **kaydırarak ulaşılabildiği** doğrulanır:
    // "ilk ekranda görünüyor" değil, "ulaşılabiliyor" aranan şeydir.
    for (final MartialArt art in MartialArt.values) {
      await scrollToFinder(tester, find.text(art.label));
      expect(
        find.text(art.label),
        findsOneWidget,
        reason: '${art.label} dalına ulaşılamıyor',
      );
    }
  });

  testWidgets('ders alınca basamak ve cüzdan güncellenir',
      (WidgetTester tester) async {
    await dovuseGit(tester, hayat());
    final int once = controller.state!.player.wallet;

    await scrollToFinder(
      tester,
      find.byKey(const Key('dovus_ders_karate')),
    );
    await tester.tap(find.byKey(const Key('dovus_ders_karate')));
    await tester.pumpAndSettle();

    expect(
      controller.state!.player.wallet,
      once - MartialArt.karate.lessonCost,
    );
    expect(controller.martialProgress(MartialArt.karate).lessons, 1);
    expect(find.textContaining('ders kaldı'), findsWidgets);
  });

  testWidgets('parası yetmeyen ders alamaz, düğme kapalıdır',
      (WidgetTester tester) async {
    await dovuseGit(tester, hayat(wallet: 5));

    await scrollToFinder(
      tester,
      find.byKey(const Key('dovus_ders_karate')),
    );
    final FilledButton dugme = tester.widget<FilledButton>(
      find.byKey(const Key('dovus_ders_karate')),
    );
    expect(dugme.onPressed, isNull);
  });

  testWidgets('basamak listesi açılıp gerçek adları gösterir',
      (WidgetTester tester) async {
    await dovuseGit(tester, hayat());

    await scrollToFinder(tester, find.text('Basamaklar').first);
    await tester.tap(find.text('Basamaklar').first);
    await tester.pumpAndSettle();

    expect(find.text('Siyah kuşak (1. Dan)'), findsOneWidget);
    expect(find.textContaining('eğitmenlik burada açılır'), findsWidgets);
  });

  testWidgets('yaşı tutmayan oyuncuya bölüm gösterilmez',
      (WidgetTester tester) async {
    // En küçük başlama yaşı 7 (karate); 4 yaşında bölüm çıkmamalı.
    //
    // **Paket CV'de güçlendirildi.** Eskiden bu test 4 yaşında "Spor
    // salonu" satırına basıp dövüş satırının yokluğunu denetliyordu.
    // Paket CV spor salonu satırına da yaş kapısı koydu ve test
    // kırmızıya döndü — çünkü artık 4 yaşında basılacak satır bile
    // yok. Bu **daha güçlü** bir güvence: iddia gevşetilmedi,
    // yükseltildi. İki kat denetliyor: satır yok, dolayısıyla bölüm de
    // erişilemez.
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
    controller.debugSetState(hayat(age: 4));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('tab_aktiviteler')));
    await tester.pumpAndSettle();

    // 4 yaşında spor salonuna giden satır hiç yok (Paket CV).
    expect(find.byKey(const Key('activity_spor')), findsNothing,
        reason: '4 yaşındaki oyuncuya "Spor salonu" satırı açık');
    expect(find.byKey(const Key('spor_dovus')), findsNothing);
  });

  testWidgets('dövüş yaşı gelen oyuncu spor salonuna ulaşabilir',
      (WidgetTester tester) async {
    // **Paket CV'nin kendi gerilemesinin bekçisi.** Spor salonu
    // satırına ilk konan kapı `ActivityVenue.sporSalonu.minAge` (8)
    // idi; dövüş sanatları ise **7** yaşında başlıyor. Yani 7 yaşındaki
    // oyuncu karateye ulaşamıyordu: kapı, sayfanın barındırdığı ek
    // satırı görmüyordu. Kapı artık ikisinin küçüğü.
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
    controller.debugSetState(hayat(age: 7));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('tab_aktiviteler')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('activity_spor')), findsOneWidget,
        reason: '7 yaşında dövüş başlıyor ama spor salonu satırı yok: '
            'kapı sayfanın içindeki en erken şeyi görmüyor');
    await tapMenuRow(tester, 'Spor salonu');
    expect(find.byKey(const Key('spor_dovus')), findsOneWidget,
        reason: '7 yaşındaki oyuncuya dövüş sanatları bölümü açılmıyor');
  });
}

import 'dart:math';

import 'package:bir_omur/app.dart';
import 'package:bir_omur/domain/models/game_state.dart';
import 'package:bir_omur/domain/models/pending_notice.dart';
import 'package:bir_omur/state/game_controller.dart';
import 'package:bir_omur/ui/sound/sound_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/test_flow.dart';

/// Ekranların **taşmadığını** sınar (Paket 28).
///
/// Taşan satır sessiz bir hatadır: içerik çizilmez, yalnızca hata şeridi
/// görünür. Ölçümde "Hayat günlüğü" başlığı 360 px genişlikte satırı
/// 24 px taşırıyordu ve bunu hiçbir test yakalamıyordu.
///
/// Bu test gerçek telefon genişliklerinde bütün ana sekmeleri gezer ve
/// tek bir taşma bile olursa düşer.
void main() {
  /// Gezinti boyunca toplanan düzen hataları.
  late List<String> hatalar;
  late void Function(FlutterErrorDetails)? eskiHandler;

  void yakala() {
    hatalar = <String>[];
    eskiHandler = FlutterError.onError;
    FlutterError.onError = (FlutterErrorDetails d) {
      final String metin = d.exceptionAsString();
      if (metin.contains('overflowed')) {
        hatalar.add(metin);
        return;
      }
      eskiHandler?.call(d);
    };
  }

  void birak() => FlutterError.onError = eskiHandler;

  /// Telefon genişlikleri: en dar yaygın cihazdan geniş olana.
  const List<Size> genislikler = <Size>[
    Size(1080, 2280), // 360 x 760 — yaygın Android
    Size(1170, 2532), // 390 x 844 — yaygın iPhone
  ];

  for (final Size boyut in genislikler) {
    final double mantiksal = boyut.width / 3;

    testWidgets('${mantiksal.round()} px genişlikte hiçbir sekme taşmaz', (
      WidgetTester tester,
    ) async {
      yakala();
      addTearDown(birak);

      final GameController controller = GameController(random: Random(21));
      addTearDown(controller.dispose);
      tester.view.physicalSize = boyut;
      tester.view.devicePixelRatio = 3;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        BirOmurApp(controller: controller, sound: SoundService.silent()),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Rastgele bir hayat'));
      await tester.pumpAndSettle();

      // Yetişkin bir hayatta bütün menüler açık olur.
      final GameState temel = controller.state!;
      controller.debugSetState(
        temel.copyWith(
          pendingEvent: null,
          notices: const <PendingNotice>[],
          player: temel.player.copyWith(age: 30, wallet: 250000),
          licenses: <String>{'otomobil_ehliyeti'},
        ),
      );
      await tester.pumpAndSettle();

      for (final String sekme in <String>[
        'okul_meslek',
        'varliklar',
        'iliskiler',
        'aktiviteler',
      ]) {
        await tester.tap(find.byKey(Key('tab_$sekme')));
        await tester.pumpAndSettle();
        // Listenin altına kadar kaydırılır: alttaki satırlar da kurulur.
        final Finder liste = find.byType(Scrollable).first;
        for (int i = 0; i < 12; i++) {
          await tester.drag(liste, const Offset(0, -300));
          await tester.pumpAndSettle();
        }
      }

      expect(hatalar, isEmpty, reason: 'Düzen taşması:\n${hatalar.join('\n')}');
    });
  }

  // Dövüş sanatları sayfası menüden iki adım içeride kaldığı için
  // yukarıdaki sekme gezintisine girmiyor; ayrıca sınanır (Paket 32).
  for (final Size boyut in genislikler) {
    final double mantiksal = boyut.width / 3;
    // Parası olan da olmayan da sınanır: "Şu an kapalı" düğmesi ve sebep
    // metni en uzun hâlleridir. Her biri kendi testinde, temiz bir
    // uygulamayla açılır.
    for (final int cuzdan in <int>[250000, 5]) {
      testWidgets('${mantiksal.round()} px genişlikte dövüş sanatları sayfası '
          'taşmaz (cüzdan $cuzdan)', (WidgetTester tester) async {
        yakala();
        addTearDown(birak);

        final GameController controller = GameController(random: Random(33));
        addTearDown(controller.dispose);
        tester.view.physicalSize = boyut;
        tester.view.devicePixelRatio = 3;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        await tester.pumpWidget(
          BirOmurApp(controller: controller, sound: SoundService.silent()),
        );
        await tester.pumpAndSettle();
        await tester.tap(find.text('Rastgele bir hayat'));
        await tester.pumpAndSettle();

        final GameState temel = controller.state!;
        controller.debugSetState(
          temel.copyWith(
            pendingEvent: null,
            notices: const <PendingNotice>[],
            player: temel.player.copyWith(age: 30, wallet: cuzdan),
          ),
        );
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(const Key('tab_aktiviteler')));
        await tester.pumpAndSettle();
        await tapMenuRow(tester, 'Spor salonu');
        await tester.tap(find.byKey(const Key('spor_dovus')));
        await tester.pumpAndSettle();

        // Bütün basamak listeleri açılır: en uzun içerik böyle kurulur.
        while (find.text('Basamaklar').evaluate().isNotEmpty) {
          await scrollToFinder(tester, find.text('Basamaklar').first);
          await tester.tap(find.text('Basamaklar').first);
          await tester.pumpAndSettle();
        }
        final Finder liste = find.byType(Scrollable).first;
        for (int i = 0; i < 20; i++) {
          await tester.drag(liste, const Offset(0, -300));
          await tester.pumpAndSettle();
        }

        expect(
          hatalar,
          isEmpty,
          reason: 'Düzen taşması:\n${hatalar.join('\n')}',
        );
      });
    }
  }

  // Piyango bayii de menüden içeride; ikramiye tablosu dar ekranda
  // sıkışık olduğu için ayrıca sınanır (Paket 33).
  for (final Size boyut in genislikler) {
    final double mantiksal = boyut.width / 3;

    testWidgets('${mantiksal.round()} px genişlikte piyango sayfası taşmaz',
        (WidgetTester tester) async {
      yakala();
      addTearDown(birak);

      final GameController controller = GameController(random: Random(44));
      addTearDown(controller.dispose);
      tester.view.physicalSize = boyut;
      tester.view.devicePixelRatio = 3;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        BirOmurApp(controller: controller, sound: SoundService.silent()),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Rastgele bir hayat'));
      await tester.pumpAndSettle();

      final GameState temel = controller.state!;
      controller.debugSetState(
        temel.copyWith(
          pendingEvent: null,
          notices: const <PendingNotice>[],
          player: temel.player.copyWith(age: 30, wallet: 250000),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('tab_aktiviteler')));
      await tester.pumpAndSettle();
      await scrollToFinder(tester, find.byKey(const Key('activity_piyango')));
      await tester.tap(find.byKey(const Key('activity_piyango')));
      await tester.pumpAndSettle();

      // Bir bilet alınır: bekleyen bilet satırı da kurulur.
      await scrollToFinder(
        tester,
        find.byKey(const Key('piyango_yilbasi_tam')),
      );
      await tester.tap(find.byKey(const Key('piyango_yilbasi_tam')));
      await tester.pumpAndSettle();

      final Finder liste = find.byType(Scrollable).first;
      await tester.drag(liste, const Offset(0, 1200));
      await tester.pumpAndSettle();
      for (int i = 0; i < 16; i++) {
        await tester.drag(liste, const Offset(0, -300));
        await tester.pumpAndSettle();
      }

      expect(
        hatalar,
        isEmpty,
        reason: 'Düzen taşması:\n${hatalar.join('\n')}',
      );
    });
  }

  testWidgets('uzun ad ve büyük cüzdanla başlık taşmaz', (
    WidgetTester tester,
  ) async {
    yakala();
    addTearDown(birak);

    final GameController controller = GameController(random: Random(4));
    addTearDown(controller.dispose);
    tester.view.physicalSize = const Size(1080, 2280);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      BirOmurApp(controller: controller, sound: SoundService.silent()),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Rastgele bir hayat'));
    await tester.pumpAndSettle();

    final GameState temel = controller.state!;
    controller.debugSetState(
      temel.copyWith(
        player: temel.player.copyWith(
          firstName: 'Abdülkerim',
          lastName: 'Küçükmehmetoğlu',
          age: 64,
          wallet: 987654321,
        ),
        pendingEvent: null,
        notices: const <PendingNotice>[],
      ),
    );
    await tester.pumpAndSettle();

    expect(hatalar, isEmpty, reason: 'Başlık taştı:\n${hatalar.join('\n')}');
  });
}

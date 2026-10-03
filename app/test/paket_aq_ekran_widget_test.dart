// Paket AQ — ekranda gerçekten görünüyor mu?
//
// Oyuncu "Sağlık: 0" yazısını açıklamasız görmemeli. Bu dosya kritik
// sağlık geri bildiriminin ekrana çıktığını, zorunlu çözümün gerçekten
// zorunlu olduğunu ve yeni satırların dar ekranda taşmadığını sınar.
library;

import 'dart:math';

import 'package:bir_omur/app.dart';
import 'package:bir_omur/domain/generation/life_generator.dart';
import 'package:bir_omur/domain/life/critical_health.dart';
import 'package:bir_omur/domain/models/game_state.dart';
import 'package:bir_omur/domain/models/pending_notice.dart';
import 'package:bir_omur/domain/models/stats.dart';
import 'package:bir_omur/state/game_controller.dart';
import 'package:bir_omur/ui/sound/sound_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late GameController controller;

  setUp(() => controller = GameController(random: Random(91)));
  tearDown(() => controller.dispose());

  GameState hayat({
    required int health,
    int age = 45,
    int wallet = 400000,
    int happiness = 60,
    bool kritik = false,
    CriticalHealthCause cause = CriticalHealthCause.hastalik,
  }) {
    final GameState base =
        LifeGenerator.seeded(91).generate(mode: StartMode.tamamenRastgele);
    final GameState s = base.copyWith(
      pendingEvent: null,
      notices: const <PendingNotice>[],
      player: base.player.copyWith(
        age: age,
        wallet: wallet,
        stats: Stats(
          appearance: 55,
          happiness: happiness,
          health: health,
          intelligence: 60,
          charisma: 55,
        ),
      ),
    );
    if (!kritik) return s;
    return CriticalHealth.enforce(state: s, age: age, cause: cause);
  }

  Future<void> pumpApp(
    WidgetTester tester,
    GameState state, {
    double genislik = 390,
    double olcek = 1.0,
  }) async {
    tester.view.physicalSize = Size(genislik * 3, 2600);
    tester.view.devicePixelRatio = 3;
    tester.platformDispatcher.textScaleFactorTestValue = olcek;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    await tester.pumpWidget(
      BirOmurApp(controller: controller, sound: SoundService.silent()),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Rastgele bir hayat'));
    await tester.pumpAndSettle();
    controller.debugSetState(state);
    await tester.pumpAndSettle();
  }

  testWidgets('kritik sağlık durum satırı üst şeritte görünüyor',
      (WidgetTester tester) async {
    await pumpApp(tester, hayat(health: 6));
    expect(
      find.textContaining('sağlık hayati tehlike seviyesinde'),
      findsWidgets,
      reason: 'Oyuncu durumu bir yerden okuyabilmeli.',
    );
  });

  testWidgets('sağlık iyiyken durum satırında sağlık uyarısı yok',
      (WidgetTester tester) async {
    await pumpApp(tester, hayat(health: 80));
    expect(find.textContaining('sağlık hayati tehlike'), findsNothing);
    expect(find.textContaining('sağlık kritik derecede düşük'), findsNothing);
  });

  testWidgets('değer ayrıntısında kritik sağlığın anlamı yazıyor',
      (WidgetTester tester) async {
    await pumpApp(tester, hayat(health: 15));
    // Değer şeridine dokunmak ayrıntı sayfasını açar.
    await tester.tap(find.text('Sağlık').first);
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('stat_durum_0')), findsOneWidget);
    expect(find.textContaining('ağır bir işe kalkışmak'), findsWidgets);
  });

  testWidgets('düşük mutluluğun anlamı da ayrıntı sayfasında yazıyor',
      (WidgetTester tester) async {
    await pumpApp(tester, hayat(health: 80, happiness: 4));
    await tester.tap(find.text('Mutluluk').first);
    await tester.pumpAndSettle();
    expect(find.textContaining('Mutluluğun çok düşük'), findsWidgets);
  });

  testWidgets('kritik sağlık penceresi açılıyor, kapatılamıyor ve sebebi '
      'yazıyor', (WidgetTester tester) async {
    await pumpApp(tester, hayat(health: 0, kritik: true));
    // Pencere kendiliğinden açılır.
    expect(find.byKey(const Key('kritik_saglik_sebebi')), findsOneWidget);
    expect(find.textContaining('hastalık'), findsWidgets);
    // Seçenekler görünüyor.
    expect(find.byKey(const Key('crisis_choice_acil_servis')), findsOneWidget);
    expect(find.byKey(const Key('crisis_choice_ozel_tedavi')), findsOneWidget);
    expect(find.byKey(const Key('crisis_choice_evde_bekle')), findsOneWidget);
    // Dışarıya dokunmak kapatmaz.
    await tester.tapAt(const Offset(10, 10));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('crisis_choice_acil_servis')), findsOneWidget);
    expect(CriticalHealth.isPending(controller.state!), isTrue);
  });

  testWidgets('sebep kayıtta yoksa ekranda uydurma sebep yazmaz',
      (WidgetTester tester) async {
    await pumpApp(
      tester,
      hayat(
        health: 0,
        kritik: true,
        cause: CriticalHealthCause.bilinmiyor,
      ),
    );
    expect(find.byKey(const Key('kritik_saglik_sebebi')), findsNothing);
    expect(find.byKey(const Key('crisis_choice_acil_servis')), findsOneWidget);
  });

  testWidgets('parası olmayan oyuncu pencerede kilitlenmiyor',
      (WidgetTester tester) async {
    await pumpApp(tester, hayat(health: 0, wallet: 0, kritik: true));
    // Bedelsiz yol etkin.
    final OutlinedButton acil = tester.widget<OutlinedButton>(
      find.byKey(const Key('crisis_choice_acil_servis')),
    );
    expect(acil.onPressed, isNotNull);
    // Özel tedavi görünür ama pasif (D-095: seçenek sessizce kaybolmaz).
    final OutlinedButton ozel = tester.widget<OutlinedButton>(
      find.byKey(const Key('crisis_choice_ozel_tedavi')),
    );
    expect(ozel.onPressed, isNull);

    // Bedelsiz yol gerçekten çalışıyor.
    await tester.tap(find.byKey(const Key('crisis_choice_acil_servis')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('crisis_result_title')), findsOneWidget);
    expect(controller.state!.pendingCrisis, isNull);
  });

  testWidgets('kritik durum çözülmeden Yaş Al ilerletmiyor',
      (WidgetTester tester) async {
    await pumpApp(tester, hayat(health: 0, age: 45, kritik: true));
    expect(controller.state!.player.age, 45);
    controller.ageUp();
    await tester.pumpAndSettle();
    expect(controller.state!.player.age, 45);
    expect(CriticalHealth.isPending(controller.state!), isTrue);
  });

  // =================================================================
  // Taşma: yeni satırlar dar ekranda ve büyük yazıda
  // =================================================================
  group('Taşma taraması', () {
    late List<String> hatalar;
    late void Function(FlutterErrorDetails)? eskiHandler;

    setUp(() {
      hatalar = <String>[];
      eskiHandler = FlutterError.onError;
      FlutterError.onError = (FlutterErrorDetails d) {
        final String metin = d.exceptionAsString();
        if (metin.contains('overflowed')) {
          hatalar.add(metin.split('\n').first);
          return;
        }
        eskiHandler?.call(d);
      };
    });

    tearDown(() => FlutterError.onError = eskiHandler);

    for (final double genislik in <double>[360, 390]) {
      testWidgets(
          'kritik sağlık penceresi ${genislik.toInt()} px / yazı ×1.5 taşmaz',
          (WidgetTester tester) async {
        await pumpApp(
          tester,
          hayat(health: 0, kritik: true),
          genislik: genislik,
          olcek: 1.5,
        );
        expect(find.byKey(const Key('crisis_choice_acil_servis')),
            findsOneWidget);
        expect(hatalar, isEmpty, reason: 'Taşma:\n${hatalar.join('\n')}');
      });

      testWidgets(
          'değer ayrıntısı ${genislik.toInt()} px / yazı ×1.5 taşmaz',
          (WidgetTester tester) async {
        await pumpApp(
          tester,
          hayat(health: 5, happiness: 2),
          genislik: genislik,
          olcek: 1.5,
        );
        await tester.tap(find.text('Sağlık').first);
        await tester.pumpAndSettle();
        expect(hatalar, isEmpty, reason: 'Taşma:\n${hatalar.join('\n')}');
      });

      testWidgets('üst şerit ${genislik.toInt()} px / yazı ×1.5 taşmaz',
          (WidgetTester tester) async {
        await pumpApp(
          tester,
          hayat(health: 3),
          genislik: genislik,
          olcek: 1.5,
        );
        expect(hatalar, isEmpty, reason: 'Taşma:\n${hatalar.join('\n')}');
      });
    }
  });
}

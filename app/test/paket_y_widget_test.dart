import 'dart:math';

import 'package:bir_omur/app.dart';
import 'package:bir_omur/data/chronic_catalog.dart';
import 'package:bir_omur/domain/generation/life_generator.dart';
import 'package:bir_omur/domain/models/chronic_condition.dart';
import 'package:bir_omur/domain/models/game_state.dart';
import 'package:bir_omur/domain/models/health_history.dart';
import 'package:bir_omur/domain/models/pending_notice.dart';
import 'package:bir_omur/state/game_controller.dart';
import 'package:bir_omur/ui/sound/sound_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/test_flow.dart';

/// Sağlık Geçmişi ekranı (D-153).
void main() {
  late GameController controller;

  setUp(() => controller = GameController(random: Random(31)));
  tearDown(() => controller.dispose());

  GameState hayat({
    int age = 50,
    int wallet = 900000,
    List<ChronicCondition> kronik = const <ChronicCondition>[],
    List<HealthHistoryEntry> gecmis = const <HealthHistoryEntry>[],
  }) {
    final GameState base =
        LifeGenerator.seeded(8).generate(mode: StartMode.tamamenRastgele);
    return base.copyWith(
      pendingEvent: null,
      notices: const <PendingNotice>[],
      player: base.player.copyWith(age: age, wallet: wallet),
      movedOut: true,
      chronicConditions: kronik,
      healthHistory: gecmis,
    );
  }

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

  testWidgets('geçmişi olmayana Sağlık Geçmişi satırı gösterilmez',
      (WidgetTester tester) async {
    await saglikAc(tester, hayat());
    expect(find.byKey(const Key('saglik_gecmis')), findsNothing);
  });

  testWidgets('kronik durumu olan satırı görür ve sayfayı açar',
      (WidgetTester tester) async {
    await saglikAc(
      tester,
      hayat(
        kronik: const <ChronicCondition>[
          ChronicCondition(typeId: 'kalp_takibi', startedAtAge: 45),
        ],
      ),
    );

    await scrollToFinder(tester, find.byKey(const Key('saglik_gecmis')));
    await tester.tap(find.byKey(const Key('saglik_gecmis')));
    await tester.pumpAndSettle();

    expect(find.text('Sağlık Geçmişi'), findsWidgets);
    expect(find.text('Kalp rahatsızlığı'), findsOneWidget);
    expect(find.textContaining('45 yaşından beri'), findsOneWidget);
  });

  testWidgets('takip düğmesi bedeli gerçekten düşürür',
      (WidgetTester tester) async {
    await saglikAc(
      tester,
      hayat(
        kronik: const <ChronicCondition>[
          ChronicCondition(typeId: 'kalp_takibi', startedAtAge: 45),
        ],
      ),
    );
    await scrollToFinder(tester, find.byKey(const Key('saglik_gecmis')));
    await tester.tap(find.byKey(const Key('saglik_gecmis')));
    await tester.pumpAndSettle();

    final int once = controller.state!.player.wallet;
    await scrollToFinder(
      tester,
      find.byKey(const Key('kronik_takip_kalp_takibi')),
    );
    await tester.tap(find.byKey(const Key('kronik_takip_kalp_takibi')));
    await tester.pumpAndSettle();

    expect(
      controller.state!.player.wallet,
      once - chronicTypeById('kalp_takibi')!.yearlyCareCost,
    );
    expect(controller.state!.chronicConditions.single.careYears, 1);
  });

  testWidgets('parası yetmeyende düğme kapalı ve gerekçe yazıyor',
      (WidgetTester tester) async {
    await saglikAc(
      tester,
      hayat(
        wallet: 50,
        kronik: const <ChronicCondition>[
          ChronicCondition(typeId: 'kalp_takibi', startedAtAge: 45),
        ],
      ),
    );
    await scrollToFinder(tester, find.byKey(const Key('saglik_gecmis')));
    await tester.tap(find.byKey(const Key('saglik_gecmis')));
    await tester.pumpAndSettle();

    await scrollToFinder(
      tester,
      find.byKey(const Key('kronik_takip_kalp_takibi')),
    );
    final FilledButton dugme = tester.widget<FilledButton>(
      find.byKey(const Key('kronik_takip_kalp_takibi')),
    );
    expect(dugme.onPressed, isNull);
    expect(find.textContaining('yeterli paran yok'), findsOneWidget);
  });

  testWidgets('atlatılmış kriz geçmişte görünür', (WidgetTester tester) async {
    await saglikAc(
      tester,
      hayat(
        gecmis: const <HealthHistoryEntry>[
          HealthHistoryEntry(
            crisisId: 'kalp_uyarisi',
            age: 48,
            choiceId: 'tedavi',
            chronicTypeId: 'kalp_takibi',
          ),
        ],
      ),
    );
    await scrollToFinder(tester, find.byKey(const Key('saglik_gecmis')));
    await tester.tap(find.byKey(const Key('saglik_gecmis')));
    await tester.pumpAndSettle();

    expect(find.text('Atlattığın krizler'), findsOneWidget);
    expect(find.textContaining('48 yaşında'), findsOneWidget);
    expect(
      find.textContaining('Ardından kaldı: Kalp rahatsızlığı'),
      findsOneWidget,
    );
  });
}

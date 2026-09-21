import 'dart:math';

import 'package:bir_omur/app.dart';
import 'package:bir_omur/data/job_catalog.dart';
import 'package:bir_omur/domain/career/career_progress.dart';
import 'package:bir_omur/domain/generation/life_generator.dart';
import 'package:bir_omur/domain/models/career.dart';
import 'package:bir_omur/domain/models/education.dart';
import 'package:bir_omur/domain/models/game_state.dart';
import 'package:bir_omur/state/game_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Meslek ekranındaki zam, terfi ve kariyer geçmişi akışları (Paket 9).
void main() {
  late GameController controller;

  setUp(() => controller = GameController(random: Random(9)));
  tearDown(() => controller.dispose());

  final JobType magaza = jobById('magaza_calisani')!;

  GameState calisan({
    int age = 30,
    int startedAtAge = 25,
    int level = 0,
    int? salary,
    List<JobHistoryEntry> history = const <JobHistoryEntry>[],
  }) {
    final GameState base =
        LifeGenerator.seeded(41).generate(mode: StartMode.tamamenRastgele);
    return base.copyWith(
      pendingEvent: null,
      player: base.player.copyWith(age: age, wallet: 200000),
      education: const EducationState(finished: true, startedAtAge: 6),
      career: CareerState(
        jobId: magaza.id,
        startedAtAge: startedAtAge,
        lastPaidAge: age,
        level: level,
        salary: salary ?? magaza.yearlySalary,
        jobCity: base.player.currentCity,
        history: history,
      ),
    );
  }

  Future<void> pumpApp(WidgetTester tester, GameState state) async {
    tester.view.physicalSize = const Size(1200, 4200);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(BirOmurApp(controller: controller));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Rastgele bir hayat'));
    await tester.pumpAndSettle();
    controller.debugSetState(state);
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('tab_okul_meslek')));
    await tester.pumpAndSettle();
  }

  testWidgets('çalışan oyuncuda unvan, maaş ve zam satırı görünür',
      (WidgetTester tester) async {
    await pumpApp(tester, calisan());

    expect(find.text('Mağaza çalışanı'), findsWidgets);
    expect(find.byKey(const Key('career_raise_row')), findsOneWidget);
    expect(find.byKey(const Key('career_history_row')), findsOneWidget);
  });

  testWidgets('zam istemek gerçekten sonuç üretir',
      (WidgetTester tester) async {
    await pumpApp(tester, calisan());
    final int eskiMaas = controller.state!.career.yearlySalary;

    await tester.tap(find.byKey(const Key('career_raise_row')));
    await tester.pumpAndSettle();

    // Sonuç ekranda yazılır; kabul da ret de olabilir.
    final int yeniMaas = controller.state!.career.yearlySalary;
    expect(yeniMaas, greaterThanOrEqualTo(eskiMaas));
    // Aynı yıl ikinci kez istenemez: satır yerine gerekçe gösterilir.
    expect(find.byKey(const Key('career_raise_row')), findsNothing);
    expect(find.textContaining('Zam isteyemezsin'), findsOneWidget);
  });

  testWidgets('terfi koşulu dolmadan satır yerine gerekçe gösterilir',
      (WidgetTester tester) async {
    await pumpApp(tester, calisan(age: 26, startedAtAge: 25));

    expect(find.byKey(const Key('career_promotion_row')), findsNothing);
    expect(find.textContaining('Terfi isteyemezsin'), findsOneWidget);
  });

  testWidgets('kariyer geçmişi eski işleri gösterir',
      (WidgetTester tester) async {
    await pumpApp(
      tester,
      calisan(
        history: <JobHistoryEntry>[
          const JobHistoryEntry(
            jobId: 'garson',
            startedAtAge: 18,
            endedAtAge: 24,
            endReason: JobEndReason.istifa,
            level: 1,
            salary: 200000,
            milestones: <CareerMilestone>[
              CareerMilestone(age: 21, text: 'Deneyimli garson oldun.'),
            ],
          ),
        ],
      ),
    );

    await tester.tap(find.byKey(const Key('career_history_row')));
    await tester.pumpAndSettle();

    expect(find.text('Kariyer geçmişi'), findsWidgets);
    // Eski iş, unvanı ve ayrılış nedeniyle birlikte duruyor.
    expect(find.text('Deneyimli garson'), findsOneWidget);
    expect(find.text(JobEndReason.istifa.label), findsOneWidget);
    expect(find.text('18-24 yaş · 6 yıl'), findsOneWidget);
    expect(find.textContaining('Deneyimli garson oldun.'), findsOneWidget);
  });

  testWidgets('terfi eden oyuncunun unvanı ekranda değişir',
      (WidgetTester tester) async {
    await pumpApp(tester, calisan(age: 40, startedAtAge: 25));

    expect(find.byKey(const Key('career_promotion_row')), findsOneWidget);
    // Kabul edilene kadar denemek yerine doğrudan terfi ettirip ekranı
    // tazeliyoruz: ekranın seviyeyi okuduğunu sınıyoruz.
    controller.debugSetState(
      controller.state!.copyWith(
        career: controller.state!.career.copyWith(
          level: 1,
          salary: 250000,
          lastPromotionAge: 40,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Kıdemli mağaza çalışanı'), findsWidgets);
    expect(find.text('Meslek'), findsWidgets);
  });

  testWidgets('işsiz oyuncuda zam ve terfi satırı hiç görünmez',
      (WidgetTester tester) async {
    final GameState issiz = calisan().copyWith(
      career: const CareerState.none(),
    );
    await pumpApp(tester, issiz);

    expect(find.byKey(const Key('career_raise_row')), findsNothing);
    expect(find.byKey(const Key('career_promotion_row')), findsNothing);
    expect(find.textContaining('Zam isteyemezsin'), findsNothing);
  });

  test('zam ve terfi sabitleri prototypeOnly aralığında kalır', () {
    expect(CareerProgress.prototypeOnlyRaiseRatio, greaterThan(0));
    expect(CareerProgress.prototypeOnlyPromotionRatio,
        greaterThan(CareerProgress.prototypeOnlyRaiseRatio));
    expect(CareerProgress.prototypeOnlyMaxChance, lessThan(1));
    expect(CareerProgress.prototypeOnlyMinChance, greaterThan(0));
  });
}

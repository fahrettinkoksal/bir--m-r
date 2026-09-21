import 'dart:math';

import 'package:bir_omur/app.dart';
import 'package:bir_omur/domain/education/school_performance.dart';
import 'package:bir_omur/domain/generation/life_generator.dart';
import 'package:bir_omur/domain/models/education.dart';
import 'package:bir_omur/domain/models/game_state.dart';
import 'package:bir_omur/state/game_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Okul ekranındaki not ortalaması ve ders çalışma (Paket 13).
void main() {
  late GameController controller;

  setUp(() => controller = GameController(random: Random(41)));
  tearDown(() => controller.dispose());

  GameState ogrenci({int age = 16, int grade = 10, int? average = 70}) {
    final GameState base =
        LifeGenerator.seeded(151).generate(mode: StartMode.tamamenRastgele);
    return base.copyWith(
      pendingEvent: null,
      player: base.player.copyWith(age: age),
      education: EducationState(
        enrolled: true,
        grade: grade,
        startedAtAge: 6,
        gradeAverage: average,
      ),
    );
  }

  Future<void> pumpSchool(WidgetTester tester, GameState state) async {
    tester.view.physicalSize = const Size(1200, 4600);
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

  testWidgets('not ortalaması panelde görünür', (WidgetTester tester) async {
    await pumpSchool(tester, ogrenci(average: 73));
    expect(find.text('Not ortalaman'), findsOneWidget);
    expect(find.text('73'), findsOneWidget);
  });

  testWidgets('ortalama yoksa satır hiç gösterilmez',
      (WidgetTester tester) async {
    await pumpSchool(tester, ogrenci(average: null));
    expect(find.text('Not ortalaman'), findsNothing);
  });

  testWidgets('ders çalışmak ortalamayı gerçekten yükseltir',
      (WidgetTester tester) async {
    await pumpSchool(tester, ogrenci(average: 60));
    expect(find.byKey(const Key('school_study_row')), findsOneWidget);

    await tester.tap(find.byKey(const Key('school_study_row')));
    await tester.pumpAndSettle();

    expect(controller.state!.education.gradeAverage, greaterThan(60));
    expect(find.textContaining('Not ortalaman'), findsWidgets);
  });

  testWidgets('yıllık hak dolunca satır yerine gerekçe gösterilir',
      (WidgetTester tester) async {
    await pumpSchool(tester, ogrenci(average: 60));
    for (int i = 0; i < SchoolPerformance.prototypeOnlyStudyPerYear; i++) {
      await tester.tap(find.byKey(const Key('school_study_row')));
      await tester.pumpAndSettle();
    }
    expect(find.byKey(const Key('school_study_row')), findsNothing);
    expect(find.textContaining('Ders çalışamazsın'), findsOneWidget);
  });

  testWidgets('sınıf tekrarı ve burs panelde görünür',
      (WidgetTester tester) async {
    final GameState s = ogrenci(average: 85);
    await pumpSchool(
      tester,
      s.copyWith(
        education: s.education.copyWith(
          repeatedYears: 1,
          scholarshipSinceAge: 15,
        ),
      ),
    );

    expect(find.text('Sınıf tekrarı'), findsOneWidget);
    expect(find.text('1 kez'), findsOneWidget);
    expect(find.text('Burs'), findsOneWidget);
    expect(find.text('15 yaşından beri'), findsOneWidget);
  });
}

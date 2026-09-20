import 'dart:math';

import 'package:bir_omur/app.dart';
import 'package:bir_omur/data/education_tracks.dart';
import 'package:bir_omur/data/interview_catalog.dart';
import 'package:bir_omur/domain/generation/life_generator.dart';
import 'package:bir_omur/domain/models/education.dart';
import 'package:bir_omur/domain/models/game_state.dart';
import 'package:bir_omur/domain/models/pending_interview.dart';
import 'package:bir_omur/state/game_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Puan görünürlüğü ve mülakat penceresinin gerçekten çalıştığını sınar.
void main() {
  late GameController controller;

  setUp(() => controller = GameController(random: Random(11)));
  tearDown(() => controller.dispose());

  GameState mezunDurum({
    int age = 20,
    EducationTrack? track = EducationTrack.bilisim,
    int placement = 66,
    int exam = 74,
  }) {
    final GameState base =
        LifeGenerator.seeded(11).generate(mode: StartMode.tamamenRastgele);
    return base.copyWith(
      player: base.player.copyWith(
        age: age,
        stats: base.player.stats.copyWith(intelligence: 75, charisma: 70),
      ),
      education: EducationState(
        startedAtAge: 6,
        finished: true,
        placementScore: placement,
        universityExamScore: exam,
        track: track,
      ),
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
    await tester.tap(find.byKey(const Key('tab_okul_meslek')));
    await tester.pumpAndSettle();
  }

  testWidgets('eğitim geçmişinde iki puan ayrı isimlerle görünür',
      (WidgetTester tester) async {
    await pumpApp(tester, mezunDurum());

    expect(find.text('Lise yerleştirme puanı'), findsOneWidget);
    expect(find.text('66'), findsOneWidget);
    expect(find.text('Üniversite sınav puanı'), findsOneWidget);
    expect(find.text('74'), findsOneWidget);
  });

  testWidgets('üniversite başvurusunda kendi puanın ve karşılaştırma görünür',
      (WidgetTester tester) async {
    await pumpApp(tester, mezunDurum());

    await tester.tap(find.text('Mezuniyet sonrası'));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('university_exam_score')), findsOneWidget);
    expect(find.textContaining('Üniversite sınav puanın: 74'), findsOneWidget);
    expect(find.textContaining('Lise yerleştirme puanın: 66'), findsOneWidget);
    expect(find.textContaining('Senin puanın:'), findsWidgets);
    expect(find.textContaining('Taban puan:'), findsWidgets);
  });

  testWidgets('başvuru mülakat penceresini açar ve doğru cevap işe alır',
      (WidgetTester tester) async {
    await pumpApp(tester, mezunDurum());

    await tester.tap(find.text('İş ara'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Başvur').first);
    await tester.pumpAndSettle();

    final PendingInterview? mulakat = controller.pendingInterview;
    expect(mulakat, isNotNull, reason: 'Başvuru mülakat açmalı');
    expect(controller.state!.career.isEmployed, isFalse,
        reason: 'Soru cevaplanmadan işe alınmamalı');

    final InterviewQuestion soru = mulakat!.question!;
    expect(find.text(soru.text), findsOneWidget);
    for (int i = 0; i < soru.options.length; i++) {
      expect(find.byKey(Key('interview_option_$i')), findsOneWidget);
    }

    await tester.tap(find.byKey(Key('interview_option_${soru.correctIndex}')));
    await tester.pumpAndSettle();

    expect(controller.state!.career.isEmployed, isTrue);
    expect(controller.pendingInterview, isNull);
    expect(find.textContaining('işe alındın'), findsWidgets);
  });

  testWidgets('yanlış cevap işe almaz, doğru cevabı açıklar',
      (WidgetTester tester) async {
    await pumpApp(tester, mezunDurum());

    await tester.tap(find.text('İş ara'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Başvur').first);
    await tester.pumpAndSettle();

    final InterviewQuestion soru = controller.pendingInterview!.question!;
    final int yanlis = (soru.correctIndex + 1) % soru.options.length;
    await tester.tap(find.byKey(Key('interview_option_$yanlis')));
    await tester.pumpAndSettle();

    expect(controller.state!.career.isEmployed, isFalse);
    expect(find.textContaining('Doğru cevap:'), findsOneWidget);
    expect(find.textContaining(soru.explanation), findsOneWidget);

    await tester.tap(find.text('Kapat'));
    await tester.pumpAndSettle();
    expect(controller.pendingInterview, isNull);
  });
}

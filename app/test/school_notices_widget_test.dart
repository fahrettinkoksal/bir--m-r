import 'dart:math';

import 'package:bir_omur/app.dart';
import 'package:bir_omur/data/event_pool_exam.dart';
import 'package:bir_omur/domain/generation/life_generator.dart';
import 'package:bir_omur/domain/life/notices.dart';
import 'package:bir_omur/domain/models/education.dart';
import 'package:bir_omur/domain/models/game_state.dart';
import 'package:bir_omur/domain/models/pending_notice.dart';
import 'package:bir_omur/state/game_controller.dart';
import 'package:bir_omur/ui/sound/sound_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Okul dönüm noktası bildirimleri ve sınav yılı paneli (Paket 17).
void main() {
  late GameController controller;

  setUp(() => controller = GameController(random: Random(29)));
  tearDown(() => controller.dispose());

  GameState ogrenci({
    int age = 13,
    int grade = 8,
    Set<String> flags = const <String>{},
    List<PendingNotice> notices = const <PendingNotice>[],
  }) {
    final GameState base =
        LifeGenerator.seeded(77).generate(mode: StartMode.tamamenRastgele);
    return base.copyWith(
      pendingEvent: null,
      storyFlags: flags,
      notices: notices,
      player: base.player.copyWith(age: age),
      education: EducationState(
        enrolled: true,
        grade: grade,
        startedAtAge: 6,
        gradeAverage: 70,
      ),
    );
  }

  Future<void> pumpGame(WidgetTester tester, GameState state) async {
    tester.view.physicalSize = const Size(1200, 4600);
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
  }

  Future<void> okulaGit(WidgetTester tester) async {
    await tester.tap(find.byKey(const Key('tab_okul_meslek')));
    await tester.pumpAndSettle();
  }

  testWidgets('lise bitiş bildirimi ekranda açılır ve kapanır',
      (WidgetTester tester) async {
    await pumpGame(
      tester,
      ogrenci(
        age: 18,
        grade: 12,
        notices: <PendingNotice>[
          Notices.highSchoolEnd(playerAge: 18, examScore: 72),
        ],
      ),
    );

    expect(find.byKey(const Key('notice_title')), findsOneWidget);
    expect(find.text('LİSE BİTTİ'), findsOneWidget);
    expect(find.textContaining('72'), findsWidgets);

    await tester.tap(find.byKey(const Key('notice_close')));
    await tester.pumpAndSettle();

    expect(controller.state!.hasNotice, isFalse);
    expect(find.byKey(const Key('notice_close')), findsNothing);
  });

  testWidgets('okula başlama bildirimi seçim sormaz',
      (WidgetTester tester) async {
    await pumpGame(
      tester,
      ogrenci(
        age: 6,
        grade: 1,
        notices: <PendingNotice>[Notices.schoolStart(playerAge: 6)],
      ),
    );

    expect(find.text('OKUL BAŞLIYOR'), findsOneWidget);
    // Bilgilendirme bildirimi: cenaze gibi seçenek düğmeleri olmaz.
    expect(find.byKey(const Key('funeral_attend_katildi')), findsNothing);
    expect(find.byKey(const Key('notice_close')), findsOneWidget);
  });

  testWidgets('8. sınıfta sınav yılı paneli görünür',
      (WidgetTester tester) async {
    await pumpGame(tester, ogrenci(age: 13, grade: 8));
    await okulaGit(tester);

    expect(find.text('Sınav yılı'), findsOneWidget);
    expect(find.textContaining('Lise yerleştirme sınavı'), findsOneWidget);
  });

  testWidgets('12. sınıfta panel üniversite sınavını yazar',
      (WidgetTester tester) async {
    await pumpGame(tester, ogrenci(age: 17, grade: 12));
    await okulaGit(tester);

    expect(find.textContaining('Üniversite sınavı'), findsOneWidget);
  });

  testWidgets('sınav yılı olmayan sınıfta panel çıkmaz',
      (WidgetTester tester) async {
    await pumpGame(tester, ogrenci(age: 15, grade: 10));
    await okulaGit(tester);

    expect(find.text('Sınav yılı'), findsNothing);
  });

  testWidgets('panel verilen kararın yönünü yazar',
      (WidgetTester tester) async {
    await pumpGame(
      tester,
      ogrenci(
        age: 17,
        grade: 12,
        flags: <String>{ExamFlags.liseOdaklandi},
      ),
    );
    await okulaGit(tester);

    expect(find.textContaining('iyi geldi'), findsOneWidget);

    controller.debugSetState(
      ogrenci(
        age: 17,
        grade: 12,
        flags: <String>{ExamFlags.liseSavsakladi},
      ),
    );
    await tester.pumpAndSettle();

    expect(find.textContaining('geriletti'), findsOneWidget);
  });
}

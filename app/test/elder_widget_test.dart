import 'dart:math';

import 'package:bir_omur/app.dart';
import 'package:bir_omur/data/job_catalog.dart';
import 'package:bir_omur/domain/generation/life_generator.dart';
import 'package:bir_omur/domain/models/career.dart';
import 'package:bir_omur/domain/models/education.dart';
import 'package:bir_omur/domain/models/game_state.dart';
import 'package:bir_omur/domain/models/gender.dart';
import 'package:bir_omur/domain/models/person.dart';
import 'package:bir_omur/domain/models/relation.dart';
import 'package:bir_omur/state/game_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/generation_fixtures.dart';

/// Emeklilik ve torun arayüzü (Paket 12).
void main() {
  late GameController controller;

  setUp(() => controller = GameController(random: Random(31)));
  tearDown(() => controller.dispose());

  final JobType magaza = jobById('magaza_calisani')!;

  GameState hayat({int age = 65, bool emekli = false, bool torun = false}) {
    final GameState base =
        LifeGenerator.seeded(121).generate(mode: StartMode.tamamenRastgele);
    return base.copyWith(
      pendingEvent: null,
      player: base.player.copyWith(age: age, wallet: 100000),
      education: const EducationState(finished: true, startedAtAge: 6),
      career: emekli
          ? CareerState(
              retiredAtAge: age,
              pension: 180000,
              lastPaidAge: age,
              history: <JobHistoryEntry>[
                JobHistoryEntry(
                  jobId: magaza.id,
                  startedAtAge: 25,
                  endedAtAge: age,
                  endReason: JobEndReason.emeklilik,
                  salary: 300000,
                ),
              ],
            )
          : CareerState(
              jobId: magaza.id,
              startedAtAge: 25,
              lastPaidAge: age,
              salary: 300000,
              jobCity: base.player.currentCity,
            ),
      people: <Person>[
        kisi(
          id: 'cocuk-1',
          relation: RelationType.cocuk,
          gender: Gender.kadin,
          age: 35,
          firstName: 'Elif',
          city: base.player.currentCity,
        ),
        if (torun)
          kisi(
            id: 'torun-1',
            relation: RelationType.torun,
            gender: Gender.erkek,
            age: 5,
            firstName: 'Poyraz',
            city: base.player.currentCity,
          ),
      ],
    );
  }

  Future<void> pumpTab(
    WidgetTester tester,
    GameState state,
    String tab,
  ) async {
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
    await tester.tap(find.byKey(Key('tab_$tab')));
    await tester.pumpAndSettle();
  }

  testWidgets('emeklilik satırı aylığı önceden gösterir ve çalışır',
      (WidgetTester tester) async {
    await pumpTab(tester, hayat(), 'okul_meslek');

    expect(find.byKey(const Key('career_retire_row')), findsOneWidget);
    expect(find.text('Emekli ol'), findsOneWidget);
    // Aylık tutarı düğmeye basmadan görünür.
    expect(find.textContaining('Yıllık aylığın'), findsOneWidget);

    await tester.tap(find.byKey(const Key('career_retire_row')));
    await tester.pumpAndSettle();

    expect(controller.state!.career.isRetired, isTrue);
    expect(controller.state!.career.pension, greaterThan(0));
    expect(find.text('Emeklilik'), findsWidgets);
  });

  testWidgets('erken emeklilikte satır bunu açıkça söyler',
      (WidgetTester tester) async {
    await pumpTab(tester, hayat(age: 61), 'okul_meslek');
    expect(find.text('Erken emekli ol'), findsOneWidget);
    expect(find.textContaining('erken ayrılış kesintisiyle'), findsOneWidget);
  });

  testWidgets('emeklilik yaşından küçükte satır hiç görünmez',
      (WidgetTester tester) async {
    await pumpTab(tester, hayat(age: 45), 'okul_meslek');
    expect(find.byKey(const Key('career_retire_row')), findsNothing);
    expect(find.text('Emekli ol'), findsNothing);
  });

  testWidgets('emekliye zam, terfi ve iş arama gösterilmez',
      (WidgetTester tester) async {
    await pumpTab(tester, hayat(emekli: true), 'okul_meslek');

    expect(find.byKey(const Key('career_raise_row')), findsNothing);
    expect(find.byKey(const Key('career_promotion_row')), findsNothing);
    expect(find.text('İş ara'), findsNothing);
    expect(find.text('İş değiştir'), findsNothing);
    expect(find.text('İşten ayrıl'), findsNothing);
    // Emeklilik paneli aylığı gösterir.
    expect(find.textContaining('Yıllık aylığın'), findsOneWidget);
  });

  testWidgets('torunlar İlişkiler menüsünde ayrı listelenir',
      (WidgetTester tester) async {
    await pumpTab(tester, hayat(torun: true), 'iliskiler');

    expect(
      find.byKey(const Key('relationships_grandchildren_row')),
      findsOneWidget,
    );
    await tester.tap(find.byKey(const Key('relationships_grandchildren_row')));
    await tester.pumpAndSettle();

    expect(find.text('Torunlar'), findsWidgets);
    expect(find.textContaining('Poyraz'), findsOneWidget);
  });

  testWidgets('torunu olmayanda Torunlar satırı görünmez',
      (WidgetTester tester) async {
    await pumpTab(tester, hayat(), 'iliskiler');
    expect(
      find.byKey(const Key('relationships_grandchildren_row')),
      findsNothing,
    );
  });
}

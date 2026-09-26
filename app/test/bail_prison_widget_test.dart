/// Kefalet kartı ve koğuş hayatı paneli ekran testleri (D-139, D-140).
library;

import 'dart:math';

import 'package:bir_omur/app.dart';
import 'package:bir_omur/data/crime_catalog.dart';
import 'package:bir_omur/domain/generation/life_generator.dart';
import 'package:bir_omur/domain/law/legal_engine.dart';
import 'package:bir_omur/domain/models/criminal_record.dart';
import 'package:bir_omur/domain/models/game_state.dart';
import 'package:bir_omur/domain/models/gender.dart';
import 'package:bir_omur/domain/models/person.dart';
import 'package:bir_omur/domain/models/relation.dart';
import 'package:bir_omur/domain/models/wealth.dart';
import 'package:bir_omur/state/game_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/test_flow.dart';

void main() {
  late GameController controller;

  setUp(() => controller = GameController(random: Random(17)));
  tearDown(() => controller.dispose());

  final CrimeType yaralama = crimeTypeById('yaralama')!;

  Person anne() => Person(
        id: 'anne-test',
        firstName: 'Sevim',
        lastName: 'Koç',
        gender: Gender.kadin,
        relation: RelationType.anne,
        age: 58,
        isAlive: true,
        inPlayerHousehold: false,
        employment: EmploymentStatus.calisiyor,
        occupation: 'öğretmen',
        wealth: WealthTier.cokVarlikli,
        bond: 85,
      );

  GameState tutuklu({int wallet = 5000000}) {
    final GameState base =
        LifeGenerator.seeded(23).generate(mode: StartMode.tamamenRastgele);
    return base.copyWith(
      pendingEvent: null,
      player: base.player.copyWith(age: 30, wallet: wallet),
      people: List<Person>.unmodifiable(<Person>[anne()]),
      legal: LegalState(
        cases: <CriminalCase>[
          const CriminalCase(
            id: 'dosya-1',
            crimeId: 'yaralama',
            ageAtIncident: 30,
            stage: CaseStage.sorusturma,
          ),
        ],
        caseCounter: 1,
        detainedSinceAge: 30,
        bailAmount: LegalEngine.bailFor(yaralama),
      ),
    );
  }

  GameState hukumlu() {
    final GameState base =
        LifeGenerator.seeded(23).generate(mode: StartMode.tamamenRastgele);
    return base.copyWith(
      pendingEvent: null,
      player: base.player.copyWith(age: 30, wallet: 5000),
      legal: const LegalState(
        cases: <CriminalCase>[
          CriminalCase(
            id: 'dosya-1',
            crimeId: 'yaralama',
            ageAtIncident: 30,
            stage: CaseStage.karar,
            verdict: Verdict.hapis,
            prisonYears: 5,
            decidedAtAge: 30,
          ),
        ],
        caseCounter: 1,
        imprisonedSinceAge: 30,
        releaseAtAge: 35,
      ),
    );
  }

  Future<void> pumpApp(WidgetTester tester, GameState state) async {
    tester.view.physicalSize = const Size(1200, 6400);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(BirOmurApp(controller: controller));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Rastgele bir hayat'));
    await tester.pumpAndSettle();
    controller.debugSetState(state);
    await tester.pumpAndSettle();
  }

  Future<void> openLegal(WidgetTester tester) async {
    await tester.tap(find.byKey(const Key('tab_okul_meslek')));
    await tester.pumpAndSettle();
    await tapMenuRow(tester, 'Adli Geçmiş');
  }

  testWidgets('tutukluyken kefalet kartı görünür ve kendi paranla çıkarsın',
      (WidgetTester tester) async {
    await pumpApp(tester, tutuklu());
    await openLegal(tester);

    expect(find.byKey(const Key('adli_tutuklu')), findsOneWidget);
    // Hükümlülük satırı görünmez: tutukluluk hükümlülük değildir.
    expect(find.byKey(const Key('adli_hapis')), findsNothing);
    expect(find.byKey(const Key('kefalet_kendim')), findsOneWidget);

    await scrollToFinder(tester, find.byKey(const Key('kefalet_kendim')));
    await tester.tap(find.byKey(const Key('kefalet_kendim')));
    await tester.pumpAndSettle();

    expect(controller.state!.legal.isDetained, isFalse);
    expect(
      controller.state!.legal.bailPaidBy,
      LegalState.selfPaidBail,
    );
  });

  testWidgets('parası yetmeyende düğme kapalı ve gerekçesi yazıyor',
      (WidgetTester tester) async {
    await pumpApp(tester, tutuklu(wallet: 50));
    await openLegal(tester);

    await scrollToFinder(tester, find.byKey(const Key('kefalet_kendim')));
    final FilledButton dugme = tester.widget<FilledButton>(
      find.byKey(const Key('kefalet_kendim')),
    );
    expect(dugme.onPressed, isNull);
    expect(find.textContaining('cüzdanında'), findsWidgets);
    // Aileden isteme kapısı açık kalır.
    expect(find.byKey(const Key('kefalet_aileden')), findsOneWidget);
  });

  testWidgets('aileden kefalet istenince kişi listesi açılır',
      (WidgetTester tester) async {
    await pumpApp(tester, tutuklu(wallet: 50));
    await openLegal(tester);

    await scrollToFinder(tester, find.byKey(const Key('kefalet_aileden')));
    await tester.tap(find.byKey(const Key('kefalet_aileden')));
    await tester.pumpAndSettle();

    expect(find.text('Kefaleti kimden isteyeceksin?'), findsOneWidget);
    expect(find.byKey(const Key('kefalet_iste_anne-test')), findsOneWidget);

    await tester.tap(find.byKey(const Key('kefalet_iste_anne-test')));
    await tester.pumpAndSettle();

    // İstek her hâlde kayda geçer: kabul de ret de olabilir.
    expect(controller.state!.legal.bailAskedAtAge, 30);
  });

  testWidgets('cezaevinde koğuş hayatı paneli çalışır',
      (WidgetTester tester) async {
    await pumpApp(tester, hukumlu());
    await tester.tap(find.byKey(const Key('tab_aktiviteler')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('aktivite_cezaevi')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('kogus_durum')), findsOneWidget);
    expect(find.text('Koğuş hayatı'), findsOneWidget);

    final int oncekiIyiHal = controller.state!.legal.goodBehaviour;
    await scrollToFinder(
      tester,
      find.byKey(const Key('cezaevi_iyiHalGoster')),
    );
    await tester.tap(find.byKey(const Key('cezaevi_iyiHalGoster')));
    await tester.pumpAndSettle();
    expect(
      controller.state!.legal.goodBehaviour,
      greaterThan(oncekiIyiHal),
    );

    // Koğuşta sohbet: tanışılan kişi listeye girer.
    await scrollToFinder(
      tester,
      find.byKey(const Key('cezaevi_kogustaSohbet')),
    );
    await tester.tap(find.byKey(const Key('cezaevi_kogustaSohbet')));
    await tester.pumpAndSettle();
    // Her seferinde biri çıkmaz; ama eylem uygulanmış olmalı.
    expect(controller.state!.log, isNotEmpty);
  });

  testWidgets('üvey ebeveyn ve koğuş arkadaşı İlişkiler ekranında görünür',
      (WidgetTester tester) async {
    final GameState temel = hukumlu();
    final Person uveyBaba = Person(
      id: 'uvey-1',
      firstName: 'Ruhi',
      lastName: 'Tekin',
      gender: Gender.erkek,
      relation: RelationType.uveyBaba,
      age: 56,
      isAlive: true,
      inPlayerHousehold: true,
      employment: EmploymentStatus.calisiyor,
      occupation: 'tesisatçı',
      wealth: WealthTier.ortaHalli,
      bond: 20,
    );
    final Person kogus = Person(
      id: 'kogus-1',
      firstName: 'Yavuz',
      lastName: 'Bal',
      gender: temel.player.gender,
      relation: RelationType.kogusArkadasi,
      age: 40,
      isAlive: true,
      inPlayerHousehold: false,
      employment: EmploymentStatus.issiz,
      wealth: WealthTier.yoksul,
      bond: 35,
    );
    await pumpApp(
      tester,
      temel.copyWith(
        people: List<Person>.unmodifiable(<Person>[uveyBaba, kogus]),
      ),
    );

    await tester.tap(find.byKey(const Key('tab_iliskiler')));
    await tester.pumpAndSettle();

    // Üvey baba anne/baba kartlarının yanında duruyor.
    expect(find.byKey(const Key('uvey_ebeveyn_uvey-1')), findsOneWidget);
    expect(find.textContaining('Üvey baba'), findsWidgets);

    // Koğuş arkadaşı arkadaş listesine girer: kayıt oluşup da
    // görünmeyen kişi kalmasın.
    await scrollToFinder(
      tester,
      find.byKey(const Key('relationships_friends_row')),
    );
    await tester.tap(find.byKey(const Key('relationships_friends_row')));
    await tester.pumpAndSettle();
    expect(find.textContaining('Yavuz'), findsWidgets);
  });
}

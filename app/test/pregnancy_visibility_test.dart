import 'dart:math';

import 'package:bir_omur/app.dart';
import 'package:bir_omur/domain/generation/life_generator.dart';
import 'package:bir_omur/domain/models/game_state.dart';
import 'package:bir_omur/domain/models/gender.dart';
import 'package:bir_omur/domain/models/marriage.dart';
import 'package:bir_omur/domain/models/pending_notice.dart';
import 'package:bir_omur/domain/models/person.dart';
import 'package:bir_omur/domain/models/pregnancy.dart';
import 'package:bir_omur/domain/models/relation.dart';
import 'package:bir_omur/domain/models/wealth.dart';
import 'package:bir_omur/state/game_controller.dart';
import 'package:bir_omur/ui/widgets/pregnancy_notice.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Paket BK/1 — bekleyen doğum ekranda görünür mü? (Q-202)
///
/// Gebelik kaydı Paket 26'dan beri var ama ekranda yalnızca o kişinin
/// kartında yazıyordu: Hayat ekranında ve İlişkiler ekranında izi yoktu.
/// Bu testler göstergenin **gebelik sürerken** çıktığını, doğum olunca
/// kalktığını ve diğer ebeveyn kayıttan düştüğünde olmayan bir bebeğin
/// söz verilmediğini sınar.
void main() {
  late GameController controller;

  setUp(() => controller = GameController(random: Random(404)));
  tearDown(() => controller.dispose());

  Person es(GameState s, int age) => Person(
        id: 'partner-bk1',
        firstName: 'Eren',
        lastName: 'Yıldız',
        gender: s.player.gender == Gender.kadin ? Gender.erkek : Gender.kadin,
        relation: RelationType.es,
        age: age,
        isAlive: true,
        inPlayerHousehold: true,
        employment: EmploymentStatus.calisiyor,
        wealth: WealthTier.ortaHalli,
        bond: 80,
      );

  GameState bebekBekleyen({
    ExpectingParty bekleyen = ExpectingParty.oyuncu,
    int age = 30,
    bool esHayatta = true,
  }) {
    final GameState base =
        LifeGenerator.seeded(404).generate(mode: StartMode.tamamenRastgele);
    GameState s = base.copyWith(
      pendingEvent: null,
      notices: const <PendingNotice>[],
      player: base.player.copyWith(age: age, wallet: 500000),
      movedOut: true,
    );
    final Person partner = es(s, age).copyWith(isAlive: esHayatta);
    return s.copyWith(
      people: List<Person>.unmodifiable(<Person>[...s.people, partner]),
      marriage: Marriage(
        spouseId: partner.id,
        marriedAtAge: age - 2,
        status: MarriageStatus.evli,
      ),
      pregnancy: Pregnancy(
        partnerId: partner.id,
        startedAtAge: age,
        expecting: bekleyen,
      ),
    );
  }

  Future<void> pumpApp(
    WidgetTester tester,
    GameState state, {
    double genislik = 400,
    double olcek = 1.0,
  }) async {
    tester.view.physicalSize = Size(genislik * 3, 3600);
    tester.view.devicePixelRatio = 3;
    tester.platformDispatcher.textScaleFactorTestValue = olcek;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    await tester.pumpWidget(BirOmurApp(controller: controller));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Rastgele bir hayat'));
    await tester.pumpAndSettle();
    controller.debugSetState(state);
    await tester.pumpAndSettle();
  }

  group('Metin motorun kuralıyla aynı', () {
    test('gebelik yoksa cümle de kısa etiket de yok', () {
      final GameState s = LifeGenerator.seeded(404)
          .generate(mode: StartMode.tamamenRastgele);
      expect(s.pregnancy, isNull);
      expect(PregnancyNotice.sentence(s), isNull);
      expect(PregnancyNotice.shortLabel(s), isNull);
    });

    test('oyuncu hamileyse cümle diğer ebeveyni adıyla yazar', () {
      final String? metin =
          PregnancyNotice.sentence(bebekBekleyen());
      expect(metin, isNotNull);
      expect(metin, contains('Hamilesin'));
      expect(metin, contains('Eren'));
      expect(metin, contains('bir sonraki yaşta'));
      expect(PregnancyNotice.shortLabel(bebekBekleyen()), 'hamilesin');
    });

    test('eş hamileyse cümle onun adıyla kurulur', () {
      final GameState s =
          bebekBekleyen(bekleyen: ExpectingParty.partner);
      expect(PregnancyNotice.sentence(s), contains('Eren'));
      expect(PregnancyNotice.sentence(s), contains('hamile'));
      expect(PregnancyNotice.shortLabel(s), 'bebek yolda');
    });

    test('diğer ebeveyn hayatta değilse bebek söz verilmez', () {
      // `LifeProgression._applyBirth` bu durumda doğumu
      // gerçekleştirmiyor; ekran da "doğacak" diye yazmamalı.
      final GameState s = bebekBekleyen(esHayatta: false);
      final String? metin = PregnancyNotice.sentence(s);
      expect(metin, isNotNull);
      expect(metin, contains('hayatta değil'));
      expect(metin, isNot(contains('doğacak')));
    });
  });

  group('Hayat ekranı', () {
    testWidgets('bekleyen doğum kartta ve durum satırında görünür',
        (WidgetTester tester) async {
      await pumpApp(tester, bebekBekleyen());

      expect(find.byKey(const Key('life_pregnancy_card')), findsOneWidget);
      expect(find.text('Bebek yolda'), findsOneWidget);
      expect(find.textContaining('Hamilesin'), findsOneWidget);
      // Üst künyedeki durum satırı: küçük harfli kısa ek.
      expect(find.textContaining('· hamilesin'), findsOneWidget);
    });

    testWidgets('eş hamileyken durum satırı "bebek yolda" yazar',
        (WidgetTester tester) async {
      await pumpApp(
        tester,
        bebekBekleyen(bekleyen: ExpectingParty.partner),
      );
      expect(find.byKey(const Key('life_pregnancy_card')), findsOneWidget);
      expect(find.textContaining('· bebek yolda'), findsOneWidget);
    });

    testWidgets('gebelik yokken kart hiç çizilmez',
        (WidgetTester tester) async {
      final GameState s = bebekBekleyen().copyWith(pregnancy: null);
      await pumpApp(tester, s);
      expect(find.byKey(const Key('life_pregnancy_card')), findsNothing);
      expect(find.text('Bebek yolda'), findsNothing);
    });

    testWidgets('doğum olunca kart kalkar', (WidgetTester tester) async {
      await pumpApp(tester, bebekBekleyen());
      expect(find.byKey(const Key('life_pregnancy_card')), findsOneWidget);

      // Bebek bir sonraki yaşta doğar: yaş ilerleyince gebelik kaydı
      // kapanır, gösterge de kalkar.
      controller.ageUp();
      await tester.pumpAndSettle();

      expect(controller.state!.pregnancy, isNull,
          reason: 'Motor doğumu bir yılda sonuçlandırmalı');
      expect(controller.state!.children, isNotEmpty);
      expect(find.byKey(const Key('life_pregnancy_card')), findsNothing);
    });
  });

  group('İlişkiler ekranı', () {
    testWidgets('bekleyen doğum ailenin ekranında da görünür',
        (WidgetTester tester) async {
      await pumpApp(tester, bebekBekleyen());
      await tester.tap(find.byKey(const Key('tab_iliskiler')));
      await tester.pumpAndSettle();

      expect(
        find.byKey(const Key('relationships_pregnancy_card')),
        findsOneWidget,
      );
      expect(find.textContaining('bir sonraki yaşta'), findsWidgets);
    });

    testWidgets('gebelik yokken ailenin ekranında kart yok',
        (WidgetTester tester) async {
      await pumpApp(tester, bebekBekleyen().copyWith(pregnancy: null));
      await tester.tap(find.byKey(const Key('tab_iliskiler')));
      await tester.pumpAndSettle();
      expect(
        find.byKey(const Key('relationships_pregnancy_card')),
        findsNothing,
      );
    });
  });

  group('Düzen', () {
    testWidgets('kart 360 px ve yazı ×1,5\'te taşmaz',
        (WidgetTester tester) async {
      // Taşma sessiz bir hatadır: içerik çizilmez, yalnızca hata şeridi
      // görünür. Kart iki ekranda birden durduğu için ikisi de ölçülür.
      final List<String> hatalar = <String>[];
      final void Function(FlutterErrorDetails)? eski = FlutterError.onError;
      FlutterError.onError = (FlutterErrorDetails d) {
        final String metin = d.exceptionAsString();
        if (metin.contains('overflowed')) {
          hatalar.add(metin);
          return;
        }
        eski?.call(d);
      };
      addTearDown(() => FlutterError.onError = eski);

      await pumpApp(
        tester,
        bebekBekleyen(),
        genislik: 360,
        olcek: 1.5,
      );
      expect(find.byKey(const Key('life_pregnancy_card')), findsOneWidget);
      await tester.tap(find.byKey(const Key('tab_iliskiler')));
      await tester.pumpAndSettle();
      expect(
        find.byKey(const Key('relationships_pregnancy_card')),
        findsOneWidget,
      );

      expect(hatalar, isEmpty, reason: hatalar.join('\n'));
    });
  });
}

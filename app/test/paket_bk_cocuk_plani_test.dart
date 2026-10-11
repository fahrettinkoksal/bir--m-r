// Paket BK/2 — çocuk planı: niyet artık açık bir eylem (Q-201).
//
// **Değişmeyen kural:** "çocuk yap" düğmesi yok. Faho Paket 25'te
// kaldırdı; çocuk bir **ihtimal**. Bu testler planın o kuralı
// bozmadığını sabitler: plan çocuk getirmez, gebelik yaratmaz,
// ihtimale dokunmaz. Yaptığı tek şey niyeti kaydetmek.
library;

import 'dart:math';

import 'package:bir_omur/app.dart';
import 'package:bir_omur/data/save/game_state_codec.dart';
import 'package:bir_omur/domain/generation/life_generator.dart';
import 'package:bir_omur/domain/interaction/family_planning.dart';
import 'package:bir_omur/domain/interaction/intimacy.dart';
import 'package:bir_omur/domain/interaction/marriage_engine.dart';
import 'package:bir_omur/domain/models/game_state.dart';
import 'package:bir_omur/domain/models/gender.dart';
import 'package:bir_omur/domain/models/life_log.dart';
import 'package:bir_omur/domain/models/marriage.dart';
import 'package:bir_omur/domain/models/pending_notice.dart';
import 'package:bir_omur/domain/models/person.dart';
import 'package:bir_omur/domain/models/pregnancy.dart';
import 'package:bir_omur/domain/models/relation.dart';
import 'package:bir_omur/domain/models/wealth.dart';
import 'package:bir_omur/state/game_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const FamilyPlanning plan = FamilyPlanning();

  Person yapPartner({
    required Gender cinsiyet,
    RelationType bag = RelationType.es,
    int yas = 30,
    bool kisir = false,
  }) =>
      Person(
        id: 'partner-bk2',
        firstName: 'Eren',
        lastName: 'Yıldız',
        gender: cinsiyet,
        relation: bag,
        age: yas,
        isAlive: true,
        inPlayerHousehold: true,
        employment: EmploymentStatus.calisiyor,
        wealth: WealthTier.ortaHalli,
        bond: 80,
        infertile: kisir,
      );

  GameState hayat({
    int yas = 30,
    RelationType bag = RelationType.es,
    bool oyuncuKisir = false,
    bool partnerKisir = false,
  }) {
    final GameState base =
        LifeGenerator.seeded(77).generate(mode: StartMode.tamamenRastgele);
    final GameState s = base.copyWith(
      pendingEvent: null,
      notices: const <PendingNotice>[],
      player: base.player.copyWith(
        age: yas,
        wallet: 900000,
        infertile: oyuncuKisir,
      ),
      movedOut: true,
    );
    final Person partner = yapPartner(
      cinsiyet: s.player.gender == Gender.kadin ? Gender.erkek : Gender.kadin,
      bag: bag,
      yas: yas,
      kisir: partnerKisir,
    );
    return s.copyWith(
      people: List<Person>.unmodifiable(<Person>[...s.people, partner]),
      marriage: bag == RelationType.es
          ? Marriage(
              spouseId: partner.id,
              marriedAtAge: yas - 2,
              status: MarriageStatus.evli,
            )
          : null,
    );
  }

  group('Plan kaydı', () {
    test('plan baştan konuşulmamıştır', () {
      final GameState s = hayat();
      expect(s.familyPlan, FamilyPlan.belirsiz);
      expect(s.familyPlanPartnerId, isNull);
      expect(s.familyPlanFor('partner-bk2'), FamilyPlan.belirsiz);
    });

    test('plan yazılır ve günlüğe tek satır düşer', () {
      final GameState s = hayat();
      final FamilyResult r =
          plan.setPlan(s, 'partner-bk2', FamilyPlan.istiyor);
      expect(r.outcome.applied, isTrue);
      expect(r.state.familyPlanFor('partner-bk2'), FamilyPlan.istiyor);
      final List<LifeLogEntry> yeni =
          r.state.log.sublist(s.log.length);
      expect(yeni, hasLength(1));
      expect(yeni.single.category, LogCategory.aile);
      expect(yeni.single.text, contains('Eren'));
    });

    test('aynı plan yeniden seçilince kayıt değişmez', () {
      final GameState s = hayat();
      final GameState ilk =
          plan.setPlan(s, 'partner-bk2', FamilyPlan.istiyor).state;
      final FamilyResult tekrar =
          plan.setPlan(ilk, 'partner-bk2', FamilyPlan.istiyor);
      expect(tekrar.outcome.applied, isFalse);
      expect(tekrar.state.log.length, ilk.log.length,
          reason: 'Her dokunuşta günlüğe satır düşmemeli');
    });

    test('eş ya da sevgili olmayanla plan konuşulamaz', () {
      final GameState s = hayat();
      final Person anne = s.people
          .firstWhere((Person p) => p.relation == RelationType.anne);
      final FamilyResult r = plan.setPlan(s, anne.id, FamilyPlan.istiyor);
      expect(r.outcome.applied, isFalse);
      expect(r.outcome.text, Intimacy.blockReason(s, anne));
    });

    test('plan sevgiliyle de konuşulur (D-047: evlilik şart değil)', () {
      final GameState s = hayat(bag: RelationType.sevgili);
      expect(
        plan.setPlan(s, 'partner-bk2', FamilyPlan.istiyor).outcome.applied,
        isTrue,
      );
    });

    test('plan başka bir partnere taşınmaz', () {
      // Ayrılıp başkasıyla birlikte olan oyuncunun eski niyeti yeni
      // ilişkiye geçmez: plan **çifte** aittir.
      final GameState s =
          plan.setPlan(hayat(), 'partner-bk2', FamilyPlan.istiyor).state;
      expect(s.familyPlanFor('bambaska-biri'), FamilyPlan.belirsiz);
    });
  });

  group('Plan çocuk getirmez', () {
    test('plan yazmak ne çocuk ne gebelik yaratır', () {
      final GameState s = hayat();
      for (final FamilyPlan secim in FamilyPlan.values) {
        final GameState sonra =
            plan.setPlan(s, 'partner-bk2', secim).state;
        expect(sonra.children, isEmpty, reason: secim.name);
        expect(sonra.pregnancy, isNull, reason: secim.name);
      }
    });

    test('plan gebelik ihtimalini değiştirmez', () {
      // Sayı `Intimacy` içinde kalır: plan yalnızca niyetin kaydı.
      final GameState s = hayat();
      final Person partner = s.personById('partner-bk2')!;
      final double once = Intimacy.conceptionChance(s, partner);
      for (final FamilyPlan secim in FamilyPlan.values) {
        final GameState sonra =
            plan.setPlan(s, 'partner-bk2', secim).state;
        expect(
          Intimacy.conceptionChance(sonra, partner),
          once,
          reason: '${secim.name} ihtimali kaydırdı',
        );
      }
    });

    test('kısır oyuncu planı yazsa da gebe kalmaz', () {
      GameState s = hayat(oyuncuKisir: true);
      s = plan.setPlan(s, 'partner-bk2', FamilyPlan.istiyor).state;
      // Beş deneme: aynı yıl ihtimal azalsa da hiçbiri tutmamalı.
      for (int i = 0; i < 5; i++) {
        s = const IntimacyEngine()
            .perform(s, 'partner-bk2', Protection.korunmadan, Random(i))
            .state;
      }
      expect(s.pregnancy, isNull);
      expect(s.children, isEmpty);
    });
  });

  group('Kayıt', () {
    test('plan kayda girer ve geri yüklenir', () {
      final GameState s =
          plan.setPlan(hayat(), 'partner-bk2', FamilyPlan.istemiyor).state;
      final GameState geri = decodeGameState(encodeGameState(s));
      expect(geri.familyPlan, FamilyPlan.istemiyor);
      expect(geri.familyPlanPartnerId, 'partner-bk2');
      expect(geri.familyPlanFor('partner-bk2'), FamilyPlan.istemiyor);
    });

    test('eski kayıtta plan yok: geriye dönük niyet uydurulmaz', () {
      final Map<String, Object?> json = encodeGameState(hayat());
      json.remove('familyPlan');
      json.remove('familyPlanPartnerId');
      final GameState geri = decodeGameState(json);
      expect(geri.familyPlan, FamilyPlan.belirsiz);
      expect(geri.familyPlanPartnerId, isNull);
    });
  });

  group('Ekran', () {
    late GameController controller;
    setUp(() => controller = GameController(random: Random(303)));
    tearDown(() => controller.dispose());

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
      await tester.tap(find.byKey(const Key('tab_iliskiler')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Eren Yıldız'));
      await tester.pumpAndSettle();
    }

    testWidgets('plan satırı eşin kartında görünür ve değiştirilebilir',
        (WidgetTester tester) async {
      await pumpApp(tester, hayat());

      expect(find.byKey(const Key('person_family_plan_row')), findsOneWidget);
      expect(find.text(FamilyPlan.belirsiz.label), findsOneWidget);
      // Plan konuşulmadan "deniyoruz" düğmesi yok.
      expect(find.byKey(const Key('person_try_for_child')), findsNothing);

      await tester.tap(find.byKey(const Key('person_family_plan_row')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('family_plan_istiyor')));
      await tester.pumpAndSettle();

      expect(
        controller.state!.familyPlanFor('partner-bk2'),
        FamilyPlan.istiyor,
      );
      expect(find.byKey(const Key('person_try_for_child')), findsOneWidget);
    });

    testWidgets('deneme düğmesi gebelik ihtimalini işletir',
        (WidgetTester tester) async {
      final GameState s = const FamilyPlanning()
          .setPlan(hayat(), 'partner-bk2', FamilyPlan.istiyor)
          .state;
      await pumpApp(tester, s);

      await tester.tap(find.byKey(const Key('person_try_for_child')));
      await tester.pumpAndSettle();

      // Deneme **sayıldı**: çocuk gelmese de yıl içindeki hesap işledi.
      expect(
        Intimacy.conceptionTriesThisAge(controller.state!),
        greaterThan(0),
      );
    });

    testWidgets('bebek yoldayken deneme düğmesi gösterilmez',
        (WidgetTester tester) async {
      GameState s = const FamilyPlanning()
          .setPlan(hayat(), 'partner-bk2', FamilyPlan.istiyor)
          .state;
      s = s.copyWith(
        pregnancy: const Pregnancy(
          partnerId: 'partner-bk2',
          startedAtAge: 30,
          expecting: ExpectingParty.oyuncu,
        ),
      );
      await pumpApp(tester, s);
      expect(find.byKey(const Key('person_try_for_child')), findsNothing);
      expect(find.byKey(const Key('person_pregnancy_note')), findsWidgets);
    });

    testWidgets('korunma penceresi konuşulan planı hatırlatır',
        (WidgetTester tester) async {
      final GameState s = const FamilyPlanning()
          .setPlan(hayat(), 'partner-bk2', FamilyPlan.istemiyor)
          .state;
      await pumpApp(tester, s);

      await tester.tap(find.byKey(const Key('person_intimacy_button')));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('protection_plan_note')), findsOneWidget);
      expect(
        find.byKey(const Key('protection_plan_match_korunarak')),
        findsOneWidget,
      );
      expect(
        find.byKey(const Key('protection_plan_match_korunmadan')),
        findsNothing,
      );
    });
  });
}

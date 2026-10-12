// Paket AP §56-§59 — ekranda gerçekten görünüyor mu?
//
// `paket_ap_ui_test.dart` kuralları model tarafında sınıyor. Bu dosya
// asıl soruyu soruyor: oyuncu ekranda bu kararı görüp verebiliyor mu?
//
// Paket AO'da üç motorun hiçbir ekrandan ulaşılamadığı ortaya çıkmıştı;
// bu test o hatanın tekrarını yakalar.
library;

import 'dart:math';

import 'package:bir_omur/app.dart';
import 'package:bir_omur/domain/generation/life_generator.dart';
import 'package:bir_omur/domain/models/family_issue.dart';
import 'package:bir_omur/domain/models/game_state.dart';
import 'package:bir_omur/domain/models/gender.dart';
import 'package:bir_omur/domain/models/npc_marriage.dart';
import 'package:bir_omur/domain/models/person.dart';
import 'package:bir_omur/domain/models/person_development.dart';
import 'package:bir_omur/domain/models/relation.dart';
import 'package:bir_omur/domain/models/stats.dart';
import 'package:bir_omur/domain/models/wealth.dart';
import 'package:bir_omur/state/game_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late GameController controller;

  setUp(() => controller = GameController(random: Random(77)));
  tearDown(() => controller.dispose());

  /// Okul çağında sorunlu bir çocuğu olan hayat.
  GameState okulSorunluHayat({
    int cuzdan = 2000000,
    bool evliCocuk = false,
  }) {
    final GameState base =
        LifeGenerator.seeded(77).generate(mode: StartMode.tamamenRastgele);
    final GameState state = base.copyWith(
      player: base.player.copyWith(age: 42, wallet: cuzdan),
      people: List<Person>.unmodifiable(<Person>[
        ...base.people,
        Person(
          id: 'cocuk-ekran',
          firstName: 'Deniz',
          lastName: base.player.lastName,
          gender: Gender.kadin,
          relation: RelationType.cocuk,
          age: evliCocuk ? 30 : 12,
          isAlive: true,
          inPlayerHousehold: !evliCocuk,
          employment: evliCocuk
              ? EmploymentStatus.calisiyor
              : EmploymentStatus.ogrenci,
          occupation: evliCocuk ? 'öğretmen' : null,
          wealth: evliCocuk ? WealthTier.ortaHalli : null,
          bond: 60,
          city: base.player.currentCity,
          motherId: base.player.id,
          development: PersonDevelopment(
            tracksLife: true,
            grade: evliCocuk ? null : 7,
            finishedSchool: evliCocuk,
            marriedAtAge: evliCocuk ? 27 : null,
            spouseName: evliCocuk ? 'Ahmet' : null,
            marriageStatus: evliCocuk ? NpcMarriageStatus.evli : null,
            stats: const Stats(
              appearance: 55,
              happiness: 25,
              health: 70,
              intelligence: 25,
              charisma: 55,
            ),
          ),
        ),
      ]),
    );
    return state.openFamilyIssue(
      kind: FamilyIssueKind.cocukOkul,
      personId: 'cocuk-ekran',
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
    await tester.tap(find.byKey(const Key('tab_iliskiler')));
    await tester.pumpAndSettle();
  }

  testWidgets('§56: bekleyen aile kararı ekranda görünüyor ve veriliyor',
      (WidgetTester tester) async {
    await pumpApp(tester, okulSorunluHayat());

    expect(find.byKey(const Key('aile_karari_karti')), findsOneWidget,
        reason: 'Karar ekrandan sorulmuyor: motor ulaşılamaz kalmış.');
    expect(find.textContaining('Deniz'), findsWidgets);

    // Karar gerçekten uygulanıyor.
    await tester.tap(find.byKey(const Key('aile_karari_destekOldu')));
    await tester.pumpAndSettle();

    expect(
      controller.state!.familyIssues.first.response,
      FamilyIssueResponse.destekOldu,
    );
    // Karar verildikten sonra kart kayboluyor.
    expect(find.byKey(const Key('aile_karari_karti')), findsNothing);
  });

  testWidgets('§56: parası yetmeyen seçenek görünür ama pasif',
      (WidgetTester tester) async {
    await pumpApp(tester, okulSorunluHayat(cuzdan: 500));

    expect(find.byKey(const Key('aile_karari_karti')), findsOneWidget);
    final Finder ozelDers = find.byKey(const Key('aile_karari_paraVerdi'));
    expect(ozelDers, findsOneWidget,
        reason: 'Seçenek sessizce kaybolmamalı (D-095).');
    final OutlinedButton dugme = tester.widget<OutlinedButton>(ozelDers);
    expect(dugme.onPressed, isNull, reason: 'Seçilemez olmalı.');
    // Gerekçe ekranda yazıyor.
    expect(find.textContaining('cüzdanında yok'), findsWidgets);
  });

  testWidgets('§59: çocuk kartında aile sorunu satırı görünüyor',
      (WidgetTester tester) async {
    await pumpApp(tester, okulSorunluHayat());

    await tester.tap(find.byKey(const Key('relationships_children_row')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('kisi_karti_aile_durumu')), findsWidgets);
    expect(find.textContaining('okul meselesi'), findsWidgets);
  });

  testWidgets('§57: evli çocuğun eşi kartta yazıyor',
      (WidgetTester tester) async {
    await pumpApp(tester, okulSorunluHayat(evliCocuk: true));

    await tester.tap(find.byKey(const Key('relationships_children_row')));
    await tester.pumpAndSettle();

    expect(find.textContaining('Eşi: Ahmet'), findsWidgets,
        reason: 'Gelin/damat gerçek bir kişi; kartta görünmeli.');
  });

  testWidgets('§60: küs çocukta sebep uydurulmadan süre yazıyor',
      (WidgetTester tester) async {
    GameState s = okulSorunluHayat();
    // Meseleyi kapat, küslüğü yaz.
    s = s.updateFamilyIssue(
      s.familyIssues.first.id,
      status: FamilyIssueStatus.kapandi,
      resolvedAtAge: s.player.age,
    );
    s = s.copyWith(
      people: List<Person>.unmodifiable(<Person>[
        for (final Person p in s.people)
          if (p.id == 'cocuk-ekran')
            p.copyWith(estrangedSinceAge: s.player.age - 3)
          else
            p,
      ]),
    );
    await pumpApp(tester, s);

    await tester.tap(find.byKey(const Key('relationships_children_row')));
    await tester.pumpAndSettle();

    expect(find.textContaining('3 yıldır konuşmuyorsunuz'), findsWidgets);
    expect(find.textContaining('çünkü'), findsNothing);
  });
}

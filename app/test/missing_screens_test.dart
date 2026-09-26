import 'dart:math';

import 'package:bir_omur/data/activity_catalog.dart';
import 'package:bir_omur/domain/activities/activity_engine.dart';
import 'package:bir_omur/domain/activities/outing.dart';
import 'package:bir_omur/domain/generation/life_generator.dart';
import 'package:bir_omur/domain/models/game_state.dart';
import 'package:bir_omur/domain/models/hobby_progress.dart';
import 'package:bir_omur/domain/models/marriage.dart';
import 'package:bir_omur/domain/models/gender.dart';
import 'package:bir_omur/domain/models/person.dart';
import 'package:bir_omur/domain/models/relation.dart';
import 'package:bir_omur/domain/models/wealth.dart';
import 'package:bir_omur/ui/screens/sections/hobbies_page.dart';
import 'package:bir_omur/ui/screens/sections/marriage_history_page.dart';
import 'package:bir_omur/ui/widgets/pet_detail_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:bir_omur/state/game_controller.dart';
import 'package:bir_omur/state/game_scope.dart';
import 'package:bir_omur/ui/theme/bir_omur_theme.dart';

/// Tek bir bölüm sayfasını kendi başına ekrana getirir.
///
/// Bütün uygulamayı açmaya gerek yok: sayfa yalnızca `GameScope`'tan
/// okuduğu için durum doğrudan kurulabilir.
Future<void> pumpWithState(
  WidgetTester tester,
  GameState state,
  Widget Function(VoidCallback onBack) yapici,
) async {
  tester.view.physicalSize = const Size(1200, 3200);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  final GameController controller = GameController(random: Random(7));
  addTearDown(controller.dispose);
  controller.startNewLife(mode: StartMode.tamamenRastgele, seed: 7);
  controller.debugSetState(state);
  await tester.pumpWidget(
    GameScope(
      controller: controller,
      child: MaterialApp(
        theme: BirOmurTheme.light(),
        home: Scaffold(body: yapici(() {})),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

GameState hayat(int seed, {int age = 30}) {
  final GameState s =
      LifeGenerator.seeded(seed).generate(mode: StartMode.tamamenRastgele);
  return s.copyWith(
    player: s.player.copyWith(age: age, wallet: 500000),
    pendingEvent: null,
  );
}

void main() {
  // ===================================================================
  // 1) Hobilerim ekranı
  // ===================================================================
  group('Hobilerim ekranı', () {
    testWidgets('hobi yoksa açıklama gösterir', (WidgetTester tester) async {
      await pumpWithState(
        tester,
        hayat(1).copyWith(hobbies: const <HobbyProgress>[]),
        (VoidCallback onBack) => HobbiesPage(onBack: onBack),
      );
      expect(find.byKey(const Key('hobi_yok')), findsOneWidget);
    });

    testWidgets('süren ve bırakılan hobiler ayrı gösterilir',
        (WidgetTester tester) async {
      await pumpWithState(
        tester,
        hayat(2, age: 30).copyWith(
          hobbies: const <HobbyProgress>[
            HobbyProgress(
              hobbyId: 'muzik',
              startedAtAge: 12,
              experience: 20,
              lastPracticedAge: 29,
            ),
            HobbyProgress(
              hobbyId: 'spor',
              startedAtAge: 14,
              experience: 6,
              lastPracticedAge: 18,
            ),
          ],
        ),
        (VoidCallback onBack) => HobbiesPage(onBack: onBack),
      );
      expect(find.text('Sürüyor'), findsOneWidget);
      expect(find.text('Uzun süredir uğraşılmayan'), findsOneWidget);
      // Gerçek kayıt gösterilir: başlangıç yaşı ekranda.
      expect(find.textContaining('12 yaş'), findsWidgets);
    });
  });

  // ===================================================================
  // 2) Evlilik Geçmişi ekranı
  // ===================================================================
  group('Evlilik Geçmişi ekranı', () {
    testWidgets('hiç evlenmemişse açıklama gösterir',
        (WidgetTester tester) async {
      await pumpWithState(
        tester,
        hayat(10),
        (VoidCallback onBack) => MarriageHistoryPage(onBack: onBack),
      );
      expect(find.byKey(const Key('evlilik_yok')), findsOneWidget);
    });

    testWidgets('geçmiş evlilik kaydı görünür', (WidgetTester tester) async {
      final GameState temel = hayat(11, age: 40);
      final Person eski = Person(
        id: 'es-eski',
        firstName: 'Nalan',
        lastName: 'Kaya',
        gender: Gender.kadin,
        relation: RelationType.eskiEs,
        age: 41,
        isAlive: true,
        inPlayerHousehold: false,
        employment: EmploymentStatus.calisiyor,
        wealth: null,
        bond: 20,
      );
      await pumpWithState(
        tester,
        temel.copyWith(
          people: List<Person>.unmodifiable(<Person>[...temel.people, eski]),
          pastMarriages: const <Marriage>[
            Marriage(
              spouseId: 'es-eski',
              marriedAtAge: 25,
              status: MarriageStatus.bosandi,
              endedAtAge: 33,
            ),
          ],
        ),
        (VoidCallback onBack) => MarriageHistoryPage(onBack: onBack),
      );
      expect(find.text('Geçmiş evlilikler'), findsOneWidget);
      // Eşin adı gerçek kayıttan okunur, uydurulmaz.
      expect(find.textContaining('Nalan'), findsOneWidget);
      expect(find.text('Boşandı'), findsOneWidget);
      expect(find.textContaining('25 yaşında'), findsOneWidget);
      // Süre hesaplanır: 33 − 25 = 8 yıl.
      expect(find.textContaining('8 yıl'), findsOneWidget);
    });
  });

  // ===================================================================
  // 3) Hayvan detay penceresi
  // ===================================================================
  group('hayvan detayı', () {
    testWidgets('sağlık, yakınlık ve birlikte geçen yıl görünür',
        (WidgetTester tester) async {
      final GameState s = hayat(20, age: 30).copyWith(
        pets: const <Pet>[
          Pet(
            id: 'hayvan-1',
            name: 'Zeytin',
            species: 'kedi',
            age: 4,
            adoptedAtPlayerAge: 26,
            inPlayerHousehold: true,
            health: 82,
            bond: 71,
          ),
        ],
      );
      await pumpWithState(
        tester,
        s,
        (VoidCallback onBack) => const PetDetailSheet(petId: 'hayvan-1'),
      );
      expect(find.text('Zeytin'), findsOneWidget);
      expect(find.text('82/100'), findsOneWidget);
      expect(find.text('71/100'), findsOneWidget);
      // 30 − 26 = 4 yıl.
      expect(find.text('4 yıl'), findsOneWidget);
    });

    testWidgets('kaydı olmayan hayvan uydurulmaz',
        (WidgetTester tester) async {
      await pumpWithState(
        tester,
        hayat(21),
        (VoidCallback onBack) => const PetDetailSheet(petId: 'yok-boyle'),
      );
      expect(find.textContaining('bulunamadı'), findsOneWidget);
    });
  });

  // ===================================================================
  // 4) Çoklu kişiyle aktivite
  // ===================================================================
  group('çoklu kişiyle aktivite', () {
    test('ücret kişi sayısına göre artar', () {
      final ActivityAction sinema = activityActionById('sinema')!;
      expect(Outing.costForParty(sinema, 0), sinema.cost);
      expect(Outing.costForParty(sinema, 1), sinema.cost * 2);
      expect(Outing.costForParty(sinema, 2), sinema.cost * 3);
      // Eski çağrı yolu aynı sonucu vermeye devam eder.
      expect(
        Outing.costFor(sinema, withCompanion: true),
        Outing.costForParty(sinema, 1),
      );
    });

    test('ücretsiz aktivite kalabalıkta da ücretsiz', () {
      final ActivityAction park = activityActionById('parkta_yuruyus')!;
      expect(park.cost, 0);
      expect(Outing.costForParty(park, 3), 0);
    });

    test('iki kişi götürmek ikisinin de bağını işler', () {
      const ActivityEngine motor = ActivityEngine();
      final GameState temel = hayat(30, age: 30);
      final List<Person> uygunlar = temel.people
          .where(
            (Person p) =>
                p.isAlive && Outing.companionRelations.contains(p.relation),
          )
          .toList(growable: false);
      if (uygunlar.length < 2) return; // Bu tohumda iki yoldaş yok.
      final ActivityAction park = activityActionById('parkta_yuruyus')!;
      final ActivityResult r = motor.perform(
        state: temel,
        action: park,
        rng: Random(1),
        companion: uygunlar[0],
        others: <Person>[uygunlar[1]],
      );
      expect(r.outcome.applied, isTrue);
      for (final Person once in <Person>[uygunlar[0], uygunlar[1]]) {
        final Person sonra = r.state.personById(once.id)!;
        expect(
          sonra.bond,
          greaterThanOrEqualTo(once.bond),
          reason: '${once.firstName} bağı işlenmedi.',
        );
      }
    });

    test('yoldaşlardan biri uygun değilse program kurulmaz ve para gitmez',
        () {
      const ActivityEngine motor = ActivityEngine();
      final GameState temel = hayat(31, age: 30);
      final List<Person> uygunlar = temel.people
          .where(
            (Person p) =>
                p.isAlive && Outing.companionRelations.contains(p.relation),
          )
          .toList(growable: false);
      if (uygunlar.isEmpty) return;
      // Vefat etmiş biri yoldaş olamaz.
      final Person olu = uygunlar.first.copyWith(isAlive: false);
      final GameState s = temel.copyWith(
        people: List<Person>.unmodifiable(
          temel.people
              .map((Person p) => p.id == olu.id ? olu : p)
              .toList(growable: false),
        ),
      );
      final ActivityAction sinema = activityActionById('sinema')!;
      final ActivityResult r = motor.perform(
        state: s,
        action: sinema,
        rng: Random(2),
        companion: olu,
      );
      expect(r.outcome.applied, isFalse);
      expect(r.state.player.wallet, s.player.wallet);
    });
  });
}

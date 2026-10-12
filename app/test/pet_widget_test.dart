import 'dart:math';

import 'package:bir_omur/app.dart';
import 'package:bir_omur/data/pet_catalog.dart';
import 'package:bir_omur/domain/generation/life_generator.dart';
import 'package:bir_omur/domain/models/game_state.dart';
import 'package:bir_omur/domain/models/pending_notice.dart';
import 'package:bir_omur/domain/models/person.dart';
import 'package:bir_omur/domain/pets/pet_care.dart';
import 'package:bir_omur/state/game_controller.dart';
import 'package:bir_omur/ui/sound/sound_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/test_flow.dart';

/// Evcil hayvan ekranı (Paket 40 — Issue #67, 2. kısım).
void main() {
  _d146();
  late GameController controller;

  setUp(() => controller = GameController(random: Random(8)));
  tearDown(() => controller.dispose());

  GameState hayat({
    int age = 30,
    int wallet = 200000,
    List<Pet> pets = const <Pet>[],
  }) {
    final GameState base =
        LifeGenerator.seeded(97).generate(mode: StartMode.tamamenRastgele);
    return base.copyWith(
      pendingEvent: null,
      notices: const <PendingNotice>[],
      pets: pets,
      player: base.player.copyWith(age: age, wallet: wallet),
    );
  }

  Future<void> hayvanlariAc(
    WidgetTester tester,
    GameState state, {
    Size boyut = const Size(1080, 5600),
  }) async {
    tester.view.physicalSize = boyut;
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
    // D-146: evcil hayvanlar Aktiviteler'den İlişkiler'e taşındı.
    await tester.tap(find.byKey(const Key('tab_iliskiler')));
    await tester.pumpAndSettle();
    await scrollToFinder(tester, find.byKey(const Key('relationships_pets_row')));
    await tester.tap(find.byKey(const Key('relationships_pets_row')));
    await tester.pumpAndSettle();
  }

  /// Sahiplenme menüsü D-135 ile gruplara ayrıldı; tür kartları grup
  /// açılınca görünür. Bu yardımcı istenen grubu açar.
  Future<void> grubuAc(WidgetTester tester, String grup) async {
    final Finder baslik = find.byKey(Key('pet_group_$grup'));
    await scrollToFinder(tester, baslik);
    await tester.tap(baslik);
    await tester.pumpAndSettle();
  }

  testWidgets('menüde görünür ve gruplar listelenir',
      (WidgetTester tester) async {
    await hayvanlariAc(tester, hayat());
    expect(find.text('Evcil hayvanlar'), findsWidgets);
    // Gruplar görünür (D-135).
    expect(find.text('Kediler'), findsOneWidget);
    expect(find.text('Köpekler'), findsOneWidget);
    expect(find.text('Kuşlar'), findsOneWidget);
    expect(find.text('Egzotik'), findsOneWidget);
    // Tür kartı grup açılana kadar görünmez.
    expect(find.byKey(const Key('hayvan_sahiplen_kedi')), findsNothing);
    await grubuAc(tester, 'kedi');
    expect(find.byKey(const Key('hayvan_sahiplen_kedi')), findsOneWidget);
  });

  testWidgets('sahiplenince kayıt oluşur ve ücret bir kez alınır',
      (WidgetTester tester) async {
    await hayvanlariAc(tester, hayat());
    final int once = controller.state!.player.wallet;

    await grubuAc(tester, 'kedi');
    await scrollToFinder(
      tester,
      find.byKey(const Key('hayvan_ad_kedi')),
    );
    await tester.enterText(find.byKey(const Key('hayvan_ad_kedi')), 'Zeytin');
    await tester.pumpAndSettle();
    await scrollToFinder(
      tester,
      find.byKey(const Key('hayvan_sahiplen_kedi')),
    );
    await tester.tap(find.byKey(const Key('hayvan_sahiplen_kedi')));
    await tester.pumpAndSettle();

    expect(controller.livingPets, hasLength(1));
    expect(controller.livingPets.single.name, 'Zeytin');
    expect(
      controller.state!.player.wallet,
      once - PetSpecies.kedi.adoptionCost,
    );
  });

  testWidgets('etkileşim düğmesi gerçekten çalışır',
      (WidgetTester tester) async {
    await hayvanlariAc(
      tester,
      hayat(
        pets: const <Pet>[
          Pet(
            id: 'hayvan-1',
            name: 'Boncuk',
            species: 'kedi',
            age: 3,
            adoptedAtPlayerAge: 27,
          ),
        ],
      ),
    );

    expect(find.text('Boncuk'), findsWidgets);
    final Finder dugme = find.byKey(const Key('hayvan_hayvan-1_oyun'));
    await scrollToFinder(tester, dugme);
    await tester.tap(dugme);
    await tester.pumpAndSettle();

    expect(controller.livingPets.single.bond, greaterThan(50));
  });

  testWidgets('vefat eden hayvan listede kalır ve etkileşime kapanır',
      (WidgetTester tester) async {
    await hayvanlariAc(
      tester,
      hayat(
        pets: const <Pet>[
          Pet(
            id: 'hayvan-1',
            name: 'Paşa',
            species: 'köpek',
            age: 14,
            adoptedAtPlayerAge: 16,
            diedAtAge: 14,
            diedAtPlayerAge: 30,
          ),
        ],
      ),
    );

    // D-082 ile sahiplenilebilir tür sayısı arttı; anma bölümü
    // listenin daha aşağısında kalıyor ve tembel liste onu henüz
    // kurmamış oluyor. Bölüme kaydırılır.
    await scrollToFinder(tester, find.text('Anılarda kalanlar'));
    expect(find.text('Anılarda kalanlar'), findsOneWidget);
    expect(find.text('Paşa'), findsWidgets);
    expect(find.byKey(const Key('hayvan_hayvan-1_oyun')), findsNothing);
  });

  // Dar ekranda taşma sessiz bir hatadır: içerik çizilmez, yalnızca şerit
  // görünür. Bu yüzden iki yaygın telefon genişliği de sınanır.
  for (final Size boyut in <Size>[
    const Size(1080, 5600), // 360 px
    const Size(1170, 5600), // 390 px
  ]) {
    final int mantiksal = (boyut.width / 3).round();
    testWidgets('$mantiksal px genişlikte hayvan ekranı taşmaz',
        (WidgetTester tester) async {
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

      await hayvanlariAc(
        tester,
        hayat(
          pets: const <Pet>[
            Pet(
              id: 'hayvan-1',
              name: 'Karabaş',
              species: 'köpek',
              age: 9,
              adoptedAtPlayerAge: 21,
            ),
            Pet(
              id: 'hayvan-2',
              name: 'Mırmır',
              species: 'kedi',
              age: 16,
              adoptedAtPlayerAge: 14,
              diedAtAge: 16,
              diedAtPlayerAge: 30,
            ),
          ],
        ),
        boyut: boyut,
      );

      // Sayfanın tamamı gezilir: aşağıdaki sahiplenme kartları ve anma
      // listesi de kurulsun.
      for (int i = 0; i < 8; i++) {
        await tester.drag(find.byType(Scrollable).first, const Offset(0, -400));
        await tester.pumpAndSettle();
      }
      for (final PetAction eylem in PetAction.values) {
        final Finder dugme = find.byKey(Key('hayvan_hayvan-1_${eylem.id}'));
        if (dugme.evaluate().isNotEmpty) {
          await tester.tap(dugme);
          await tester.pumpAndSettle();
        }
      }

      expect(hatalar, isEmpty, reason: hatalar.join('\n'));
    });
  }
}

// =====================================================================
// D-146: hayvan İlişkiler'de, her yaşta etkileşilebilir
//
// Faho bildirdi: "evdeki evcil hayvanımı ilişkiler kısmına taşı,
// varlıklarda değil ve evcil hayvan ile etkileşime geçebileyim;
// oynadığım bir hayatta evde evcil hayvan vardı fakat iletişim yoktu."
//
// Sebebi: menü satırı yalnızca **sahiplenme yaşından** (7) itibaren
// açılıyordu; oyuncu doğduğunda evde olan hayvanla beş yaşındaki çocuk
// hiçbir şey yapamıyordu.
// =====================================================================
void _d146() {
  late GameController controller;
  setUp(() => controller = GameController(random: Random(3)));
  tearDown(() => controller.dispose());

  Pet aileKedisi() => const Pet(
        id: 'pet-aile',
        name: 'Tekir',
        species: 'kedi',
        age: 4,
        adoptedAtPlayerAge: null,
        inPlayerHousehold: true,
        bond: 55,
      );

  GameState cocuk({int age = 5}) {
    final GameState base =
        LifeGenerator.seeded(97).generate(mode: StartMode.tamamenRastgele);
    return base.copyWith(
      pendingEvent: null,
      notices: const <PendingNotice>[],
      pets: List<Pet>.unmodifiable(<Pet>[aileKedisi()]),
      player: base.player.copyWith(age: age, wallet: 200),
    );
  }

  Future<void> ac(WidgetTester tester, GameState state) async {
    tester.view.physicalSize = const Size(1080, 5600);
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

  testWidgets('beş yaşındaki çocuk evdeki hayvanla etkileşebilir',
      (WidgetTester tester) async {
    await ac(tester, cocuk());
    // Sahiplenme yaşının altında bile satır görünür, çünkü evde hayvan var.
    expect(controller.state!.player.age,
        lessThan(PetCare.prototypeOnlyMinAge));

    await tester.tap(find.byKey(const Key('tab_iliskiler')));
    await tester.pumpAndSettle();
    final Finder satir = find.byKey(const Key('relationships_pets_row'));
    await scrollToFinder(tester, satir);
    expect(satir, findsOneWidget);
    await tester.tap(satir);
    await tester.pumpAndSettle();

    // Etkileşim düğmesi gerçekten çalışır.
    final Finder oyun =
        find.byKey(const Key('hayvan_pet-aile_vakit'));
    await scrollToFinder(tester, oyun);
    final int onceBag = controller.state!.pets.single.bond;
    await tester.tap(oyun);
    await tester.pumpAndSettle();
    expect(controller.state!.pets.single.bond, greaterThan(onceBag));
  });

  testWidgets('Varlıklar ekranında hayvan listesi yok',
      (WidgetTester tester) async {
    await ac(tester, cocuk());
    await tester.tap(find.byKey(const Key('tab_varliklar')));
    await tester.pumpAndSettle();

    // Hayvanın adı Varlıklar'da geçmez; yerine yönlendirme satırı var.
    expect(find.text('Tekir'), findsNothing);
    expect(find.textContaining('İlişkiler menüsünde'), findsWidgets);
  });
}

// Paket BT — **evini döşemek**: katalog, döşeme seviyesi, yıpranma,
// modül anahtarı ve ekran.
//
// **Neden bu paket.** Oyunda konut alınıyor, taşınılıyor, kiraya
// veriliyor; ama evin içi boştu. Katalogda ev eşyası diye üç şey vardı
// (çay takımı, seccade, bisiklet bakım seti) ve hiçbiri bir ihtiyaca
// karşılık gelmiyordu (`docs/NEXT_DEVELOPMENT_OPTIONS.md` §6).
//
// **Ölçüldü (200 hayat, iki blok, aynı tohumlarla anahtar açık/kapalı):**
// evini döşeyen hayat 175/200 ve 182/200; ortalama döşeme seviyesi 73,8
// ve 78,1; ölümde mutluluk +2,1 ve +0,2 puan. Net servet farkının yönü
// iki blok arasında **ters döndü** (-12,2 M ve +13,2 M), yani servet
// etkisi gürültü bandında (Paket BO dersi). Ayrıntı: PROJECT_STATUS.
library;

import 'dart:math';

import 'package:bir_omur/app.dart';
import 'package:bir_omur/data/item_catalog.dart';
import 'package:bir_omur/data/save/game_state_codec.dart';
import 'package:bir_omur/data/shop_catalog.dart';
import 'package:bir_omur/domain/economy/furnishing.dart';
import 'package:bir_omur/domain/economy/housing.dart';
import 'package:bir_omur/domain/features/feature_catalog.dart';
import 'package:bir_omur/domain/generation/life_generator.dart';
import 'package:bir_omur/domain/generation/life_progression.dart';
import 'package:bir_omur/domain/models/game_state.dart';
import 'package:bir_omur/domain/models/owned_item.dart';
import 'package:bir_omur/state/game_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Kendi evinde oturan, eşyası verilen bir hayat.
GameState _hayat({
  List<String> esyalar = const <String>[],
  int kondisyon = OwnedItem.defaultCondition,
  bool anahtarAcik = true,
  bool aileYaninda = false,
}) {
  final GameState taban =
      LifeGenerator.seeded(404).generate(mode: StartMode.tamamenRastgele);
  final List<OwnedItem> items = <OwnedItem>[
    const OwnedItem(
      id: 'ev-1',
      typeId: 'daire_kucuk',
      acquiredAtAge: 30,
      purchasePrice: 3000000,
    ),
    for (int i = 0; i < esyalar.length; i++)
      OwnedItem(
        id: 'esya-$i',
        typeId: esyalar[i],
        acquiredAtAge: 30,
        condition: kondisyon,
      ),
  ];
  return taban.copyWith(
    player: taban.player.copyWith(age: 32, wallet: 500000),
    items: items,
    residenceItemId: aileYaninda ? null : 'ev-1',
    movedOut: !aileYaninda,
    settings: taban.settings.copyWith(
      features: anahtarAcik
          ? FeatureSwitches.defaults
          : FeatureSwitches.defaults.toggled(FeatureId.evDosemesi, false),
    ),
  );
}

List<String> get _temelIdler => Furnishing.slots
    .where((FurnishingSlot s) => s.essential)
    .map((FurnishingSlot s) => s.typeId)
    .toList(growable: false);

List<String> get _tumIdler =>
    Furnishing.slots.map((FurnishingSlot s) => s.typeId).toList(
          growable: false,
        );

void main() {
  // ===================================================================
  // Katalog
  // ===================================================================
  group('Ev eşyası kataloğu', () {
    test('her yuvanın katalogda gerçek bir eşya türü var', () {
      for (final FurnishingSlot yuva in Furnishing.slots) {
        final ItemType tur = itemTypeOrFallback(yuva.typeId);
        expect(tur.id, yuva.typeId,
            reason: '${yuva.typeId} katalogda yok; yuva boşa düşüyor');
        expect(tur.kind, ItemKind.evEsyasi,
            reason: '${yuva.typeId} ev eşyası değil');
        expect(tur.baseValue, greaterThan(0));
      }
    });

    test('yuvalar tekrarsız ve temel/konfor dengesi var', () {
      final Set<String> idler = <String>{};
      for (final FurnishingSlot yuva in Furnishing.slots) {
        expect(idler.add(yuva.typeId), isTrue,
            reason: '${yuva.typeId} iki yuvada geçiyor');
        expect(yuva.need.trim(), isNotEmpty);
      }
      expect(Furnishing.essentialCount, greaterThanOrEqualTo(5));
      expect(Furnishing.comfortCount, greaterThanOrEqualTo(8));
    });

    test('her yuva mağazadan alınabilir', () {
      for (final FurnishingSlot yuva in Furnishing.slots) {
        final Iterable<ShopProduct> urunler = kShopCatalog.where(
          (ShopProduct p) => p.typeId == yuva.typeId,
        );
        expect(urunler, hasLength(1),
            reason: '${yuva.typeId} mağazada yok ya da iki kez var');
        expect(urunler.first.category, ShopCategory.evYasam);
        expect(urunler.first.description.trim(), isNotEmpty);
      }
    });

    test('Ev ve yaşam mağazası 18 yaşında açık, 15 yaşında kapalı', () {
      expect(shopCategoriesFor(18), contains(ShopCategory.evYasam));
      expect(shopCategoriesFor(15), isNot(contains(ShopCategory.evYasam)));
      expect(ShopCategory.evYasam.group, ShopGroup.gundelik);
    });

    test('fiyatlar 2026 ölçeğinde: hiçbiri asgari ücretin on katı değil',
        () {
      // Ölçek denetimi: ev eşyası bir ömür boyu biriktirilecek bir şey
      // değil. Net aylık asgari ücret 28.075,50 ₺ (lib/data/economy.dart).
      for (final FurnishingSlot yuva in Furnishing.slots) {
        expect(yuva.price, lessThan(280755),
            reason: '${yuva.typeId} ev eşyası için fahiş');
        expect(yuva.price, greaterThan(500),
            reason: '${yuva.typeId} bedava gibi');
      }
    });
  });

  // ===================================================================
  // Seviye
  // ===================================================================
  group('Döşeme seviyesi', () {
    test('boş evde sıfır, her şey varken yüz', () {
      expect(Furnishing.level(_hayat()), 0);
      expect(Furnishing.level(_hayat(esyalar: _tumIdler)), 100);
    });

    test('yalnızca temel ihtiyaçlar varsa seviye temel payı kadar', () {
      expect(
        Furnishing.level(_hayat(esyalar: _temelIdler)),
        Furnishing.prototypeOnlyEssentialShare,
      );
    });

    test('temel ihtiyaç konfordan ağır: buzdolabı televizyondan çok', () {
      final int buzdolabi =
          Furnishing.level(_hayat(esyalar: <String>['buzdolabi']));
      final int televizyon =
          Furnishing.level(_hayat(esyalar: <String>['televizyon']));
      expect(buzdolabi, greaterThan(televizyon));
    });

    test('iş görmeyecek kadar yıpranmış eşya yuvayı doldurmaz', () {
      final GameState bozuk = _hayat(
        esyalar: <String>['buzdolabi'],
        kondisyon: Furnishing.prototypeOnlyUsableCondition - 1,
      );
      expect(Furnishing.filled(bozuk, Furnishing.slots.first), isFalse);
      expect(Furnishing.level(bozuk), 0);
      expect(Furnishing.wornOut(bozuk), hasLength(1));
    });

    test('aynı türden iki eşyadan iyisi sayılır', () {
      final GameState taban = _hayat(esyalar: <String>['buzdolabi']);
      final GameState ikili = taban.copyWith(
        items: <OwnedItem>[
          ...taban.items.map((OwnedItem i) =>
              i.typeId == 'buzdolabi' ? i.copyWith(condition: 30) : i),
          const OwnedItem(
            id: 'esya-yeni',
            typeId: 'buzdolabi',
            acquiredAtAge: 32,
            condition: 95,
          ),
        ],
      );
      expect(Furnishing.itemFor(ikili, Furnishing.slots.first)?.condition, 95);
    });

    test('eksik listesi temel ihtiyaçları önce yazar', () {
      final List<FurnishingSlot> eksik = Furnishing.missing(_hayat());
      expect(eksik, hasLength(Furnishing.slots.length));
      expect(eksik.first.essential, isTrue);
      final GameState temelTam = _hayat(esyalar: _temelIdler);
      expect(
        Furnishing.missing(temelTam).every((FurnishingSlot s) => !s.essential),
        isTrue,
      );
    });
  });

  // ===================================================================
  // Kapı: modül anahtarı ve hane
  // ===================================================================
  group('Döşeme kapısı', () {
    test('anahtar kapalıyken seviye sıfır ve ekran istenmiyor', () {
      final GameState kapali =
          _hayat(esyalar: _tumIdler, anahtarAcik: false);
      expect(Furnishing.isOn(kapali), isFalse);
      expect(Furnishing.appliesTo(kapali), isFalse);
      expect(Furnishing.level(kapali), 0);
      expect(Furnishing.yearlyHappiness(kapali), 0);
    });

    test('ailesinin yanında yaşayan oyuncudan döşeme istenmez', () {
      final GameState evde = _hayat(esyalar: _tumIdler, aileYaninda: true);
      expect(Housing.residenceOf(evde), ResidenceKind.aileYaninda);
      expect(Furnishing.appliesTo(evde), isFalse);
      expect(Furnishing.yearlyHappiness(evde), 0);
    });

    test('iyi döşenmiş ev yılda bir puan mutluluk veriyor, cezası yok',
        () {
      final GameState tam = _hayat(esyalar: _tumIdler);
      expect(
        Furnishing.yearlyHappiness(tam),
        Furnishing.prototypeOnlyComfortHappiness,
      );
      // Eşiğin altında katkı yok; **ceza da yok**.
      final GameState az = _hayat(esyalar: <String>['buzdolabi']);
      expect(Furnishing.yearlyHappiness(az), 0);
    });
  });

  // ===================================================================
  // Yıllık işleyiş
  // ===================================================================
  group('Yıllık yıpranma', () {
    test('oturulan evdeki ev eşyası bir yılda yıpranır', () {
      final GameState once = _hayat(esyalar: <String>['buzdolabi']);
      final GameState sonra =
          LifeProgression(Random(12)).advanceOneYear(once);
      final OwnedItem? esya = sonra.items
          .where((OwnedItem i) => i.typeId == 'buzdolabi')
          .firstOrNull;
      expect(esya, isNotNull);
      expect(esya!.condition, lessThan(OwnedItem.defaultCondition));
      expect(
        OwnedItem.defaultCondition - esya.condition,
        lessThanOrEqualTo(Furnishing.prototypeOnlyMaxYearlyWear),
      );
    });

    test('anahtar kapalıyken eşya yıpranmaz', () {
      final GameState once = _hayat(
        esyalar: <String>['buzdolabi'],
        anahtarAcik: false,
      );
      final GameState sonra =
          LifeProgression(Random(12)).advanceOneYear(once);
      final OwnedItem esya =
          sonra.items.firstWhere((OwnedItem i) => i.typeId == 'buzdolabi');
      expect(esya.condition, OwnedItem.defaultCondition);
    });

    test('ev eşyası olmayan hayatta yıl aynı kalır (zar kaymaz)', () {
      // Paket BO dersi: yeni sistem, kullanılmadığı hayatta zar
      // tüketmemeli. Aynı tohum iki kez aynı sonucu vermeli.
      final GameState once = _hayat();
      final GameState a = LifeProgression(Random(5)).advanceOneYear(once);
      final GameState b = LifeProgression(Random(5)).advanceOneYear(once);
      expect(a.player.age, b.player.age);
      expect(a.player.wallet, b.player.wallet);
      expect(a.player.stats.happiness, b.player.stats.happiness);
    });

    test('döşenmiş ev kapat-aç sonrası aynı seviyede', () {
      final GameState tam = _hayat(esyalar: _tumIdler);
      final GameState geri = decodeGameState(encodeGameState(tam));
      expect(Furnishing.level(geri), Furnishing.level(tam));
      expect(geri.items.length, tam.items.length);
    });
  });

  // ===================================================================
  // Ekran
  // ===================================================================
  group('Evinin hâli ekranı', () {
    testWidgets('Varlıklar satırı açılıyor ve yuvalar listeleniyor',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1200, 6000);
      tester.view.devicePixelRatio = 3;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final GameController controller = GameController(random: Random(3));
      addTearDown(controller.dispose);
      await tester.pumpWidget(BirOmurApp(controller: controller));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Rastgele bir hayat'));
      await tester.pumpAndSettle();

      controller.debugSetState(_hayat(esyalar: _temelIdler));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('tab_varliklar')));
      await tester.pumpAndSettle();

      final Finder satir = find.byKey(const Key('assets_furnishing_row'));
      expect(satir, findsOneWidget,
          reason: 'kendi evinde oturan oyuncu Evinin hâli satırını görmeli');
      await tester.ensureVisible(satir);
      await tester.pumpAndSettle();
      await tester.tap(satir);
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('furnishing_page')), findsOneWidget);
      expect(find.byKey(const Key('furnishing_level')), findsOneWidget);
      // Dolu bir temel yuva ve boş bir konfor yuvası aynı ekranda.
      expect(
        find.byKey(const Key('furnishing_slot_buzdolabi')),
        findsOneWidget,
      );
      expect(
        find.byKey(const Key('furnishing_slot_televizyon')),
        findsOneWidget,
      );
    });

    testWidgets('anahtar kapalıyken satır hiç görünmüyor',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1200, 6000);
      tester.view.devicePixelRatio = 3;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final GameController controller = GameController(random: Random(4));
      addTearDown(controller.dispose);
      await tester.pumpWidget(BirOmurApp(controller: controller));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Rastgele bir hayat'));
      await tester.pumpAndSettle();

      controller.debugSetState(
        _hayat(esyalar: _tumIdler, anahtarAcik: false),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('tab_varliklar')));
      await tester.pumpAndSettle();

      expect(
        find.byKey(const Key('assets_furnishing_row')),
        findsNothing,
        reason: 'kapalı modül ekranda hiç görünmez (fail-closed)',
      );
    });
  });
}

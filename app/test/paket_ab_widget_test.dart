import 'dart:math';

import 'package:bir_omur/app.dart';
import 'package:bir_omur/data/shop_catalog.dart';
import 'package:bir_omur/domain/economy/rental_engine.dart';
import 'package:bir_omur/domain/generation/life_generator.dart';
import 'package:bir_omur/domain/interaction/item_actions.dart';
import 'package:bir_omur/domain/models/game_state.dart';
import 'package:bir_omur/domain/models/owned_item.dart';
import 'package:bir_omur/domain/models/pending_notice.dart';
import 'package:bir_omur/domain/models/rental.dart';
import 'package:bir_omur/state/game_controller.dart';
import 'package:bir_omur/ui/sound/sound_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/test_flow.dart';

/// Evlerim ekranı (D-163).
///
/// Ekranın gerçekten **çalıştığını** gösterir: konut listesi kullanım
/// durumunu yazıyor, kiraya verme akışı aday seçmeden geçiyor, bakım
/// kondisyonu yükseltiyor, kârlılık özeti görünüyor. Bu testler gerçek
/// cihazda oynandığı anlamına gelmez.
void main() {
  late GameController controller;

  setUp(() => controller = GameController(random: Random(17)));
  tearDown(() => controller.dispose());

  GameState hayat({int age = 35, int wallet = 12000000}) {
    final GameState base =
        LifeGenerator.seeded(8).generate(mode: StartMode.tamamenRastgele);
    return base.copyWith(
      pendingEvent: null,
      notices: const <PendingNotice>[],
      player: base.player.copyWith(age: age, wallet: wallet),
      movedOut: true,
    );
  }

  /// İki konut alır: biri oturulan, biri boş.
  GameState ikiEv(GameState state) {
    const ItemActions islem = ItemActions();
    GameState s = state;
    for (int i = 0; i < 2; i++) {
      final ItemActionResult r = islem.buy(
        state: s,
        product: shopProductByTypeId('kucuk_daire')!,
        location: 'Ankara',
      );
      expect(r.outcome.applied, isTrue, reason: r.outcome.text);
      s = r.state;
    }
    return s.copyWith(residenceItemId: s.items.first.id);
  }

  /// Tek konutlu, oturulmayan bir hayat: ev boş.
  GameState ekleBos(GameState state) {
    const ItemActions islem = ItemActions();
    final ItemActionResult r = islem.buy(
      state: state,
      product: shopProductByTypeId('kucuk_daire')!,
      location: 'Ankara',
    );
    expect(r.outcome.applied, isTrue, reason: r.outcome.text);
    return r.state;
  }

  Future<void> evlerimAc(WidgetTester tester, GameState state) async {
    tester.view.physicalSize = const Size(1080, 7200);
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
    await tester.tap(find.byKey(const Key('tab_varliklar')));
    await tester.pumpAndSettle();
    await tapMenuRow(tester, 'Evlerim');
    await tester.pumpAndSettle();
  }

  testWidgets('evi olmayana Evlerim satırı gösterilmez',
      (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 7200);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      BirOmurApp(controller: controller, sound: SoundService.silent()),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Rastgele bir hayat'));
    await tester.pumpAndSettle();
    controller.debugSetState(hayat().copyWith(items: const <OwnedItem>[]));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('tab_varliklar')));
    await tester.pumpAndSettle();
    expect(find.text('Evlerim'), findsNothing);
  });

  testWidgets('liste kullanım durumunu yazıyor', (WidgetTester tester) async {
    final GameState s = ikiEv(hayat());
    await evlerimAc(tester, s);

    expect(find.byKey(const Key('properties_summary')), findsOneWidget);
    expect(find.byKey(Key('property_row_${s.items.first.id}')), findsOneWidget);
    expect(find.byKey(Key('property_row_${s.items.last.id}')), findsOneWidget);
    expect(find.text('Burada yaşıyorsun'), findsOneWidget);
    expect(find.text('Boş'), findsOneWidget);
  });

  testWidgets('oturulan evde kiraya verme kartı çıkmıyor',
      (WidgetTester tester) async {
    final GameState s = ikiEv(hayat());
    await evlerimAc(tester, s);
    await tester.tap(find.byKey(Key('property_row_${s.items.first.id}')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('rent_out_card')), findsNothing);
    expect(find.textContaining('Burada yaşıyorsun'), findsWidgets);
  });

  testWidgets('boş ev kiraya verilir: aday seçilir, sözleşme kurulur',
      (WidgetTester tester) async {
    final GameState s = ikiEv(hayat());
    final String bosEvId = s.items.last.id;
    await evlerimAc(tester, s);
    await tester.tap(find.byKey(Key('property_row_$bosEvId')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('rent_out_card')), findsOneWidget);
    expect(find.byKey(const Key('property_ledger')), findsNothing);

    await tester.tap(find.byKey(const Key('find_tenants')));
    await tester.pumpAndSettle();

    // Piyasa kirasıyla aday gelmeli ve kiracıyı **oyuncu** seçmeli.
    final Finder adaylar = find.textContaining('Bu kiracıyla anlaş');
    expect(adaylar, findsWidgets);
    final int cuzdanOnce = controller.state!.player.wallet;

    await tester.tap(adaylar.first);
    await tester.pumpAndSettle();

    final Lease? sozlesme = controller.state!.leaseOf(bosEvId);
    expect(sozlesme, isNotNull);
    expect(sozlesme!.yearlyRent, greaterThan(0));
    // Depozito alındı: bir aylık kira kadar.
    expect(sozlesme.deposit, greaterThan(0));
    expect(controller.state!.player.wallet, cuzdanOnce + sozlesme.deposit);
    expect(controller.state!.ledgerOf(bosEvId).depositHeld, sozlesme.deposit);
    expect(find.byKey(const Key('tenant_card')), findsOneWidget);
  });

  testWidgets('aynı yıl ekran kapanıp açılınca adaylar değişmiyor',
      (WidgetTester tester) async {
    final GameState s = ikiEv(hayat());
    final String bosEvId = s.items.last.id;
    await evlerimAc(tester, s);

    List<String> adayAdlari() => controller
        .tenantCandidatesFor(
          controller.state!.itemById(bosEvId)!,
          controller.marketRent(controller.state!.itemById(bosEvId)!),
        )
        .map((TenantRecord t) => t.id)
        .toList();

    final List<String> ilk = adayAdlari();
    expect(ilk, isNotEmpty);

    // Detayı aç, geri dön, tekrar aç.
    await tester.tap(find.byKey(Key('property_row_$bosEvId')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('find_tenants')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Evlerim').first);
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(Key('property_row_$bosEvId')));
    await tester.pumpAndSettle();

    expect(adayAdlari(), ilk);
  });

  testWidgets('fahiş kira isteyince başvuru azalıyor ve uyarı çıkıyor',
      (WidgetTester tester) async {
    final GameState s = ikiEv(hayat());
    final String bosEvId = s.items.last.id;
    await evlerimAc(tester, s);
    await tester.tap(find.byKey(Key('property_row_$bosEvId')));
    await tester.pumpAndSettle();

    final OwnedItem ev = controller.state!.itemById(bosEvId)!;
    final int piyasa = controller.marketRent(ev);
    await tester.enterText(
      find.byKey(const Key('rent_amount')),
      '${(piyasa * 2.2).round()}',
    );
    await tester.pumpAndSettle();
    expect(find.textContaining('boş kalabilir'), findsOneWidget);

    // Aday sayısı Poisson çekiliyor: fahiş kirada **çoğu yıl** kimse
    // aramıyor ama tek bir yılda "kesin sıfır" demek yanlış olurdu.
    // İddia yıllar üzerinden: yüksek kirada toplam başvuru, piyasa
    // kirasındakinin belirgin biçimde altında.
    int tara(double oran) {
      int toplam = 0;
      for (int yas = 30; yas < 70; yas++) {
        controller.debugSetState(
          controller.state!.copyWith(
            player: controller.state!.player.copyWith(age: yas),
          ),
        );
        toplam += controller
            .tenantCandidatesFor(ev, (piyasa * oran).round())
            .length;
      }
      return toplam;
    }

    final int yuksek = tara(2.2);
    final int normal = tara(1.0);
    expect(yuksek, lessThan(normal ~/ 3));
    expect(controller.state!.leaseOf(bosEvId), isNull);
  });

  testWidgets('kimse aramayan yılda ekran boş liste gösteriyor',
      (WidgetTester tester) async {
    final GameState s = ekleBos(hayat());
    final String bosEvId = s.items.last.id;

    // Hiç aday gelmeyen bir yıl **aranıyor**, uydurulmuyor: adaylar
    // (mülk, yaş, kira) üçlüsünden deterministik türediği için böyle bir
    // yıl gerçekten var ve her koşuda aynı yıl.
    final int piyasa = RentalEngine.marketRent(s, s.items.last);
    int? bosYas;
    for (int yas = 25; yas < 80 && bosYas == null; yas++) {
      final bool bos = RentalEngine.candidates(
        state: s.copyWith(player: s.player.copyWith(age: yas)),
        home: s.items.last,
        askingRent: piyasa,
      ).isEmpty;
      if (bos) bosYas = yas;
    }
    expect(bosYas, isNotNull,
        reason: 'Piyasa kirasında hiç aday gelmeyen yıl olmalı: ev bazı '
            'yıllar boş kalabilmeli');

    await evlerimAc(
      tester,
      s.copyWith(player: s.player.copyWith(age: bosYas)),
    );
    await tester.tap(find.byKey(Key('property_row_$bosEvId')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('find_tenants')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('no_candidates')), findsOneWidget);
    expect(controller.state!.leaseOf(bosEvId), isNull);
  });

  testWidgets('bakım kondisyonu yükseltiyor ve deftere yazıyor',
      (WidgetTester tester) async {
    GameState s = ikiEv(hayat());
    final OwnedItem bos = s.items.last;
    s = s.updateItem(bos.copyWith(condition: 50));
    await evlerimAc(tester, s);
    await tester.tap(find.byKey(Key('property_row_${bos.id}')));
    await tester.pumpAndSettle();

    final int cuzdanOnce = controller.state!.player.wallet;
    await tester.tap(find.byKey(const Key('do_upkeep')));
    await tester.pumpAndSettle();

    expect(controller.state!.itemById(bos.id)!.condition, greaterThan(50));
    expect(controller.state!.player.wallet, lessThan(cuzdanOnce));
    expect(
      controller.state!.ledgerOf(bos.id).maintenanceSpent,
      cuzdanOnce - controller.state!.player.wallet,
    );
    expect(find.byKey(const Key('property_ledger')), findsOneWidget);
  });

  testWidgets('sözleşme sonlandırılınca kiracı kartı kalkıyor',
      (WidgetTester tester) async {
    final GameState s = ikiEv(hayat());
    final String bosEvId = s.items.last.id;
    await evlerimAc(tester, s);
    await tester.tap(find.byKey(Key('property_row_$bosEvId')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('find_tenants')));
    await tester.pumpAndSettle();
    await tester.tap(find.textContaining('Bu kiracıyla anlaş').first);
    await tester.pumpAndSettle();
    expect(controller.state!.leaseOf(bosEvId), isNotNull);

    await tester.tap(find.byKey(const Key('end_lease')));
    await tester.pumpAndSettle();

    expect(controller.state!.leaseOf(bosEvId), isNull);
    expect(controller.state!.ledgerOf(bosEvId).depositHeld, 0);
    expect(find.byKey(const Key('tenant_card')), findsNothing);
  });
}

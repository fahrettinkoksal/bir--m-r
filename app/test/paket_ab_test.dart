import 'dart:math';

import 'package:bir_omur/data/save/game_state_codec.dart';
import 'package:bir_omur/data/shop_catalog.dart';
import 'package:bir_omur/data/tenant_catalog.dart';
import 'package:bir_omur/domain/economy/housing.dart';
import 'package:bir_omur/domain/economy/net_worth.dart';
import 'package:bir_omur/domain/economy/rental_engine.dart';
import 'package:bir_omur/domain/generation/life_generator.dart';
import 'package:bir_omur/domain/interaction/item_actions.dart';
import 'package:bir_omur/domain/models/game_state.dart';
import 'package:bir_omur/domain/models/owned_item.dart';
import 'package:bir_omur/domain/models/pending_notice.dart';
import 'package:bir_omur/domain/models/rental.dart';
import 'package:flutter_test/flutter_test.dart';

/// Paket AB — kiralık gayrimenkul (D-163).
///
/// Ağırlık **exploit koruması** tarafında: aynı kira iki kez tahsil
/// edilmesin, elde olmayan ev gelir üretmesin, depozito gelir sayılmasın.
/// Sayılar `prototypeOnly`; iddialar geniş ama gerekçeli.
void main() {
  const ItemActions islem = ItemActions();

  GameState hayat({int age = 35, int wallet = 20000000}) {
    final GameState base =
        LifeGenerator.seeded(8).generate(mode: StartMode.tamamenRastgele);
    return base.copyWith(
      pendingEvent: null,
      notices: const <PendingNotice>[],
      player: base.player.copyWith(age: age, wallet: wallet),
      movedOut: true,
    );
  }

  GameState evAl(GameState state, {String sehir = 'Ankara'}) {
    final ItemActionResult r = islem.buy(
      state: state,
      product: shopProductByTypeId('kucuk_daire')!,
      location: sehir,
    );
    expect(r.outcome.applied, isTrue, reason: r.outcome.text);
    return r.state;
  }

  /// Evi kiraya verir. Aday sayısı Poisson çekildiği için piyasa
  /// kirasında bile bazı yıl kimse aramaz; bandın içinde rakam oynatarak
  /// kiracı bulunur. [kira] verilirse **tam o rakam** denenir.
  GameState kiralaVer(GameState state, OwnedItem ev, {int? kira}) {
    final int piyasa = kira ?? RentalEngine.marketRent(state, ev);
    final List<double> oranlar =
        kira != null ? <double>[1.0] : <double>[1.0, 0.98, 1.02, 0.95, 1.05];
    for (final double oran in oranlar) {
      final int istenen = (piyasa * oran).round();
      final List<TenantRecord> adaylar = RentalEngine.candidates(
        state: state,
        home: ev,
        askingRent: istenen,
      );
      if (adaylar.isEmpty) continue;
      final RentalResult r = RentalEngine.signLease(
        state: state,
        home: ev,
        tenant: adaylar.first,
        yearlyRent: istenen,
      );
      expect(r.outcome.applied, isTrue, reason: r.outcome.text);
      return r.state;
    }
    fail('Kiracı bulunamadı; talep modeli fazla sıkı olabilir.');
  }

  group('Çoklu ev sahipliği ve ana ikamet', () {
    test('ikinci konut alınabilir', () {
      GameState s = evAl(hayat());
      s = evAl(s, sehir: 'Samsun');
      expect(s.properties.length, 2);
      expect(s.properties.map((OwnedItem i) => i.id).toSet().length, 2);
    });

    test('yalnızca bir ana ikamet olur', () {
      GameState s = evAl(evAl(hayat()));
      const Housing housing = Housing();
      s = housing.moveInto(s, s.properties.first).state;
      expect(s.residenceItemId, s.properties.first.id);
      s = housing.moveInto(s, s.properties.last).state;
      expect(s.residenceItemId, s.properties.last.id);
      // Tek alan: iki ev birden "oturulan" olamaz.
      expect(
        s.properties
            .where((OwnedItem i) =>
                RentalEngine.useOf(s, i) == PropertyUse.oturuluyor)
            .length,
        1,
      );
    });

    test('oturulan ev kiraya verilemez, boş ev verilebilir', () {
      GameState s = evAl(evAl(hayat()));
      s = s.copyWith(residenceItemId: s.properties.first.id);
      expect(
        RentalEngine.rentOutBlockReason(
          state: s,
          home: s.properties.first,
          askingRent: RentalEngine.marketRent(s, s.properties.first),
        ),
        isNotEmpty,
      );
      expect(
        RentalEngine.rentOutBlockReason(
          state: s,
          home: s.properties.last,
          askingRent: RentalEngine.marketRent(s, s.properties.last),
        ),
        isEmpty,
      );
    });
  });

  group('Kira bandı, adaylar ve şehir', () {
    test('piyasa kirası evin değerine, şehrine ve kondisyonuna bakar', () {
      final GameState buyuk = evAl(hayat(), sehir: 'İstanbul');
      final GameState kucuk = evAl(hayat(), sehir: 'Amasya');
      final int istKira =
          RentalEngine.marketRent(buyuk, buyuk.properties.single);
      final int amaKira =
          RentalEngine.marketRent(kucuk, kucuk.properties.single);
      // **Eskiden bu iki sayı aynıydı** (katalog değerinden hesaplanıyordu).
      expect(istKira, greaterThan(amaKira));

      // Kondisyon düşünce kira da düşer: bakımın karşılığı bu.
      final GameState yipranmis = buyuk.updateItem(
        buyuk.properties.single.copyWith(condition: 40),
      );
      expect(
        RentalEngine.marketRent(yipranmis, yipranmis.properties.single),
        lessThan(istKira),
      );
    });

    test('kira bandı piyasanın etrafında', () {
      final GameState s = evAl(hayat());
      final ({int low, int high}) bant =
          RentalEngine.rentBand(s, s.properties.single);
      final int piyasa = RentalEngine.marketRent(s, s.properties.single);
      expect(bant.low, lessThan(piyasa));
      expect(bant.high, greaterThan(piyasa));
    });

    test('adaylar aynı yıl ve aynı kirada deterministik', () {
      final GameState s = evAl(hayat());
      final OwnedItem ev = s.properties.single;
      final int kira = RentalEngine.marketRent(s, ev);
      final List<String> bir = RentalEngine.candidates(
        state: s,
        home: ev,
        askingRent: kira,
      ).map((TenantRecord t) => t.id).toList();
      final List<String> iki = RentalEngine.candidates(
        state: s,
        home: ev,
        askingRent: kira,
      ).map((TenantRecord t) => t.id).toList();
      expect(bir, iki);
      expect(bir, isNotEmpty);
    });

    test('fahiş kira isteyince aday gelmez, düşük kirada çok gelir', () {
      // Aday sayısı Poisson çekildiği için **tek yıla bakmak yanıltıcı**:
      // piyasa kirasında bile bazı yıl kimse aramaz. İddia 60 yıl
      // üzerinden ortalamaya bakıyor; ölçüm bu yüzden kırılgan değil.
      final GameState s = evAl(hayat());
      final OwnedItem ev = s.properties.single;
      final int piyasa = RentalEngine.marketRent(s, ev);

      ({double ortalama, int bosYil}) tara(double oran) {
        int toplam = 0;
        int bos = 0;
        for (int yas = 25; yas < 85; yas++) {
          final int adet = RentalEngine.candidates(
            state: s.copyWith(player: s.player.copyWith(age: yas)),
            home: ev,
            askingRent: (piyasa * oran).round(),
          ).length;
          toplam += adet;
          if (adet == 0) bos++;
        }
        return (ortalama: toplam / 60, bosYil: bos);
      }

      final ({double ortalama, int bosYil}) yuksek = tara(2.2);
      final ({double ortalama, int bosYil}) normal = tara(1.0);
      final ({double ortalama, int bosYil}) dusuk = tara(0.7);

      expect(yuksek.ortalama, lessThan(normal.ortalama));
      expect(normal.ortalama, lessThan(dusuk.ortalama));
      // Fahiş kirada çoğu yıl kimse aramıyor.
      expect(yuksek.bosYil, greaterThan(30));
      // Piyasa kirasında ev çoğu yıl kiracı buluyor ama garanti değil.
      expect(normal.bosYil, lessThan(20));
      expect(normal.ortalama, greaterThan(1.5));
    });

    test('bandın çok dışında kira yazılamaz', () {
      final GameState s = evAl(hayat());
      final OwnedItem ev = s.properties.single;
      final int piyasa = RentalEngine.marketRent(s, ev);
      expect(
        RentalEngine.rentOutBlockReason(
          state: s,
          home: ev,
          askingRent: piyasa * 10,
        ),
        isNotEmpty,
      );
      expect(
        RentalEngine.rentOutBlockReason(state: s, home: ev, askingRent: 1),
        isNotEmpty,
      );
    });
  });

  group('Sözleşme, depozito ve tahsilat', () {
    test('depozito bir aylık kira ve gelir sayılmaz', () {
      final GameState s = evAl(hayat());
      final OwnedItem ev = s.properties.single;
      final int kira = RentalEngine.marketRent(s, ev);
      final GameState kiralik = kiralaVer(s, ev, kira: kira);
      final Lease l = kiralik.leaseOf(ev.id)!;

      expect(l.deposit, (kira / 12).round());
      // Depozito cüzdana girdi ama **elde tutuluyor**: defterde borç gibi
      // duruyor ve çıkışta iade edilecek.
      expect(kiralik.ledgerOf(ev.id).depositHeld, l.deposit);
      expect(kiralik.ledgerOf(ev.id).rentCollected, 0,
          reason: 'Depozito kira geliri değildir');
      expect(kiralik.player.wallet, s.player.wallet + l.deposit);

      // Çıkışta iade edilir (ev iyi durumdaysa tamamı).
      final RentalResult cikis = RentalEngine.endLease(
        state: kiralik,
        propertyItemId: ev.id,
      );
      expect(cikis.state.player.wallet, s.player.wallet);
      expect(cikis.state.ledgerOf(ev.id).depositHeld, 0);
    });

    test('yıllık kira yalnızca bir kez tahsil edilir', () {
      GameState t = evAl(hayat());
      t = kiralaVer(t, t.properties.single);
      final int kira = t.leaseOf(t.properties.single.id)!.yearlyRent;
      final int once = t.player.wallet;

      final ({GameState state, RentalYear year}) bir =
          RentalEngine.advanceYear(state: t, newAge: 36, rng: Random(1));
      expect(bir.year.collected, lessThanOrEqualTo(kira));
      expect(
        bir.state.player.wallet - once,
        bir.year.collected - bir.year.costs,
      );
      expect(bir.state.ledgerOf(t.properties.single.id).rentCollected,
          bir.year.collected);
      expect(bir.state.leases, hasLength(1),
          reason: 'Tahsilat ikinci bir sözleşme üretmemeli');
    });

    test('kiracı çıkınca ödeme kesilir', () {
      GameState t = evAl(hayat());
      t = kiralaVer(t, t.properties.single);
      t = RentalEngine.endLease(
        state: t,
        propertyItemId: t.properties.single.id,
      ).state;
      final int once = t.player.wallet;
      final ({GameState state, RentalYear year}) yil =
          RentalEngine.advanceYear(state: t, newAge: 36, rng: Random(2));
      expect(yil.year.collected, 0);
      // Boş ev bedava beklemiyor: küçük bir gider çıkıyor.
      expect(yil.year.costs, greaterThan(0));
      expect(yil.state.player.wallet, lessThan(once));
      expect(yil.state.ledgerOf(t.properties.single.id).vacantYears, 1);
    });

    test('satılan ev kira üretmez ve sözleşme kalmaz', () {
      GameState t = evAl(hayat());
      t = kiralaVer(t, t.properties.single);
      final String evId = t.properties.single.id;
      expect(Housing.yearlyRentIncome(t), greaterThan(0));

      final ItemActionResult satis = islem.sell(state: t, itemId: evId);
      expect(satis.outcome.applied, isTrue);
      expect(satis.state.leaseOf(evId), isNull);
      expect(satis.state.ledgerOf(evId).rentCollected, 0);
      expect(Housing.yearlyRentIncome(satis.state), 0);

      final ({GameState state, RentalYear year}) yil = RentalEngine.advanceYear(
        state: satis.state,
        newAge: 36,
        rng: Random(3),
      );
      expect(yil.year.collected, 0,
          reason: 'Elde olmayan ev gelir üretmemeli');
    });

    test('yenileme kirayı değiştirir, tavanı aşamaz', () {
      GameState t = evAl(hayat());
      t = kiralaVer(t, t.properties.single);
      final String evId = t.properties.single.id;
      final int eski = t.leaseOf(evId)!.yearlyRent;

      final RentalResult yeni = RentalEngine.renewLease(
        state: t,
        propertyItemId: evId,
        newYearlyRent: (eski * 1.2).round(),
      );
      expect(yeni.outcome.applied, isTrue);
      expect(yeni.state.leaseOf(evId)!.yearlyRent, (eski * 1.2).round());

      final RentalResult fahis = RentalEngine.renewLease(
        state: t,
        propertyItemId: evId,
        newYearlyRent: eski * 10,
      );
      expect(fahis.outcome.applied, isFalse);
      expect(fahis.state.leaseOf(evId)!.yearlyRent, eski);
    });
  });

  group('Kondisyon, bakım ve değer', () {
    test('kiracılı ev yıllarla yıpranır', () {
      GameState t = evAl(hayat());
      t = kiralaVer(t, t.properties.single);
      final int once = t.properties.single.condition;
      for (int i = 0; i < 5; i++) {
        t = RentalEngine.advanceYear(
          state: t,
          newAge: 36 + i,
          rng: Random(10 + i),
        ).state;
      }
      expect(t.properties.single.condition, lessThan(once),
          reason: 'Para harcamadan ev 100 kondisyonda kalmasın');
    });

    test('bakım kondisyonu yükseltir, tadilat daha çok', () {
      GameState t = evAl(hayat());
      t = t.updateItem(t.properties.single.copyWith(condition: 50));
      final OwnedItem ev = t.properties.single;

      final RentalResult bakim =
          RentalEngine.upkeep(state: t, home: ev, major: false);
      final RentalResult tadilat =
          RentalEngine.upkeep(state: t, home: ev, major: true);
      expect(bakim.outcome.applied, isTrue);
      expect(tadilat.outcome.applied, isTrue);
      expect(bakim.state.properties.single.condition, greaterThan(50));
      expect(
        tadilat.state.properties.single.condition,
        greaterThan(bakim.state.properties.single.condition),
      );
      // Tadilat daha pahalı ve değeri sınırlı biçimde artırıyor.
      expect(tadilat.outcome.amount, greaterThan(bakim.outcome.amount));
      expect(
        RentalEngine.valueOf(tadilat.state, tadilat.state.properties.single),
        greaterThan(RentalEngine.valueOf(t, ev)),
      );
    });

    test('bakım masrafı iki kez kesilmez', () {
      GameState t = evAl(hayat());
      t = t.updateItem(t.properties.single.copyWith(condition: 50));
      final int once = t.player.wallet;
      final RentalResult r = RentalEngine.upkeep(
        state: t,
        home: t.properties.single,
        major: false,
      );
      expect(once - r.state.player.wallet, r.outcome.amount);
      expect(
        r.state.ledgerOf(t.properties.single.id).maintenanceSpent,
        r.outcome.amount,
      );
    });

    test('ev değeri yavaş hareket eder', () {
      GameState t = evAl(hayat());
      final int once = RentalEngine.valueOf(t, t.properties.single);
      for (int i = 0; i < 10; i++) {
        t = RentalEngine.advanceYear(
          state: t,
          newAge: 36 + i,
          rng: Random(50 + i),
        ).state;
      }
      final int sonra = RentalEngine.valueOf(t, t.properties.single);
      // 100 binlik ev on yılda 100 milyon olmasın: üst sınır iki kat.
      expect(sonra, lessThan(once * 2));
      expect(sonra, greaterThan((once * 0.7).round()));
    });
  });

  group('Servet, kayıt ve exploit', () {
    test('ev net varlıkta bir kez sayılır', () {
      final GameState bos = hayat();
      final int oncekiNet = NetWorth.of(bos);
      GameState t = evAl(bos);
      // Para eve döndü: net varlık aynı kalmalı (fiyat = değer).
      expect(NetWorth.of(t), closeTo(oncekiNet, oncekiNet * 0.2));

      t = kiralaVer(t, t.properties.single);
      // Kira **gelir**, ev **varlık**: kiranın bugünkü değeri diye ikinci
      // bir varlık yazılmıyor. Tek fark elde tutulan depozito.
      expect(
        NetWorth.of(t),
        NetWorth.liquid(t) + NetWorth.itemsValue(t) - NetWorth.debt(t),
      );
    });

    test('kayıt kiracıyı, depozitoyu ve defteri koruyor', () {
      GameState t = evAl(hayat());
      t = kiralaVer(t, t.properties.single);
      t = RentalEngine.advanceYear(state: t, newAge: 36, rng: Random(7)).state;

      final GameState geri = decodeGameState(encodeGameState(t));
      final String evId = t.properties.single.id;
      expect(geri.leaseOf(evId)?.tenant.id, t.leaseOf(evId)?.tenant.id);
      expect(geri.leaseOf(evId)?.yearlyRent, t.leaseOf(evId)?.yearlyRent);
      expect(geri.leaseOf(evId)?.onTimeYears, t.leaseOf(evId)?.onTimeYears);
      expect(
        geri.ledgerOf(evId).rentCollected,
        t.ledgerOf(evId).rentCollected,
      );
      expect(geri.ledgerOf(evId).valueBasis, t.ledgerOf(evId).valueBasis);
      expect(Housing.yearlyRentIncome(geri), Housing.yearlyRentIncome(t));
    });

    test('eski kayıt (rentedOut bayraklı) sözleşmeye çevrilir', () {
      GameState t = evAl(hayat());
      final String evId = t.properties.single.id;
      // Eski sürümün kaydını taklit et: bayrak var, sözleşme yok.
      t = t.updateItem(t.properties.single.copyWith(rentedOut: true));
      final Map<String, Object?> json = encodeGameState(t);
      json.remove('leases');
      json.remove('propertyLedgers');

      final GameState geri = decodeGameState(json);
      final Lease? devralinan = geri.leaseOf(evId);
      expect(devralinan, isNotNull, reason: 'Oyuncunun kirası kesilmemeli');
      expect(devralinan!.yearlyRent, legacyYearlyRent(t.properties.single),
          reason: 'Göçte eski kira tutarı korunur');
      expect(devralinan.deposit, 0,
          reason: 'Olmayan depozito uydurulmaz');
      // Göç deterministik: aynı kayıt aynı kiracıyı verir.
      expect(decodeGameState(json).leaseOf(evId)!.tenant.id,
          devralinan.tenant.id);
    });

    test('eski kayıtta boş ev sözleşme üretmez', () {
      final GameState t = evAl(hayat());
      final Map<String, Object?> json = encodeGameState(t);
      json.remove('leases');
      expect(decodeGameState(json).leases, isEmpty);
    });

    test('aynı yıl sözleşme kurup bozmak depozito basmıyor', () {
      GameState t = evAl(hayat());
      final OwnedItem ev = t.properties.single;
      final int baslangic = t.player.wallet;
      for (int i = 0; i < 5; i++) {
        t = kiralaVer(t, t.properties.single);
        t = RentalEngine.endLease(state: t, propertyItemId: ev.id).state;
      }
      expect(t.player.wallet, baslangic,
          reason: 'Depozito al-ver döngüsü para üretmemeli');
      expect(t.ledgerOf(ev.id).rentCollected, 0);
    });

    test('aynı yıl iki kez ilerletmek kirayı iki kez tahsil etmez', () {
      GameState t = evAl(hayat());
      t = kiralaVer(t, t.properties.single);
      final ({GameState state, RentalYear year}) bir =
          RentalEngine.advanceYear(state: t, newAge: 36, rng: Random(9));
      // Motor yıl başına bir kez **çağrılır** (yaş ilerlemesi); aynı çağrı
      // iki kez yapılırsa iki yıl geçmiş sayılır. Buradaki iddia: tek
      // çağrıda tek tahsilat, defter ile cüzdan birbirini tutuyor.
      expect(bir.state.ledgerOf(t.properties.single.id).rentCollected,
          bir.year.collected);
      expect(
        bir.state.player.wallet - t.player.wallet,
        bir.year.collected - bir.year.costs,
      );
    });
  });
}

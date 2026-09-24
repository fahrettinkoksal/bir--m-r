import 'dart:math';

import 'package:bir_omur/data/item_catalog.dart';
import 'package:bir_omur/data/save/game_state_codec.dart';
import 'package:bir_omur/data/shop_catalog.dart';
import 'package:bir_omur/domain/economy/banking.dart';
import 'package:bir_omur/domain/economy/vehicle_trouble.dart';
import 'package:bir_omur/domain/generation/life_generator.dart';
import 'package:bir_omur/domain/models/game_state.dart';
import 'package:bir_omur/domain/models/loan.dart';
import 'package:bir_omur/domain/models/owned_item.dart';
import 'package:flutter_test/flutter_test.dart';

/// Mağaza ayrımı, araç masrafı ve banka (D-079, D-080).
void main() {
  GameState hayat(
    int seed, {
    int age = 35,
    int wallet = 2000000,
    int? salary,
  }) {
    final GameState base =
        LifeGenerator.seeded(seed).generate(mode: StartMode.tamamenRastgele);
    GameState s = base.copyWith(
      player: base.player.copyWith(age: age, wallet: wallet),
    );
    if (salary != null) {
      s = s.copyWith(
        career: s.career.copyWith(jobId: 'magaza_calisani', salary: salary),
      );
    }
    return s;
  }

  group('Mağaza ayrımı (D-079)', () {
    test('üç araç galerisi, iki motor galerisi ve iki emlakçı var', () {
      final List<ShopCategory> galeriler = ShopCategory.values
          .where((ShopCategory c) =>
              c == ShopCategory.galeriUcuz ||
              c == ShopCategory.galeriOrta ||
              c == ShopCategory.galeriLuks)
          .toList(growable: false);
      expect(galeriler.length, 3);

      final List<ShopCategory> motorlar = ShopCategory.values
          .where((ShopCategory c) =>
              c == ShopCategory.motorUcuz || c == ShopCategory.motorLuks)
          .toList(growable: false);
      expect(motorlar.length, 2);

      final List<ShopCategory> emlak = ShopCategory.values
          .where((ShopCategory c) => c.isHousing)
          .toList(growable: false);
      expect(emlak.length, 2);
    });

    test('aksesuarcılar ayrı ve doğru parçaları satıyor', () {
      final List<String> oto = shopProductsIn(ShopCategory.otoAksesuar, 30)
          .map((ShopProduct p) => p.typeId)
          .toList(growable: false);
      final List<String> motor =
          shopProductsIn(ShopCategory.motorAksesuar, 30)
              .map((ShopProduct p) => p.typeId)
              .toList(growable: false);

      expect(oto, contains('tavan_bagaji'));
      expect(oto, isNot(contains('kask')));
      expect(motor, contains('kask'));
      expect(motor, isNot(contains('tavan_bagaji')));
    });

    test('her galeri boş değil ve en az iki seçenek sunuyor', () {
      for (final ShopCategory c in ShopCategory.values) {
        final List<ShopProduct> urunler = shopProductsIn(c, 30);
        expect(urunler, isNotEmpty, reason: '${c.label} boş');
        if (c.isVehicle) {
          expect(urunler.length, greaterThanOrEqualTo(2),
              reason: '${c.label} tek modelli olmamalı');
        }
      }
    });

    test('galeriler fiyat kademesine göre ayrılmış', () {
      int ortalama(ShopCategory c) {
        final List<ShopProduct> u = shopProductsIn(c, 30);
        return u.fold(0, (int t, ShopProduct p) => t + p.price) ~/ u.length;
      }

      expect(
        ortalama(ShopCategory.galeriUcuz),
        lessThan(ortalama(ShopCategory.galeriOrta)),
      );
      expect(
        ortalama(ShopCategory.galeriOrta),
        lessThan(ortalama(ShopCategory.galeriLuks)),
      );
      expect(
        ortalama(ShopCategory.motorUcuz),
        lessThan(ortalama(ShopCategory.motorLuks)),
      );
      expect(
        ortalama(ShopCategory.emlakciOrta),
        lessThan(ortalama(ShopCategory.emlakciLuks)),
      );
    });

    test('aynı ürün iki galeride birden satılmaz', () {
      final Map<String, List<String>> nerede = <String, List<String>>{};
      for (final ShopProduct p in kShopCatalog) {
        if (!p.category.isVehicle) continue;
        nerede.putIfAbsent(p.typeId, () => <String>[]).add(p.category.name);
      }
      nerede.forEach((String tur, List<String> yerler) {
        expect(yerler.length, 1, reason: '$tur birden çok galeride: $yerler');
      });
    });

    test('her ürünün eşya karşılığı var', () {
      for (final ShopProduct p in kShopCatalog) {
        expect(itemTypeById(p.typeId), isNotNull, reason: p.typeId);
      }
    });
  });

  group('Araç masrafı (D-079)', () {
    OwnedItem arac(String typeId, {int condition = 40}) => OwnedItem(
          id: 'a1',
          typeId: typeId,
          acquiredAtAge: 30,
          condition: condition,
        );

    test('bisiklet arızalanmaz; motorlu araç arızalanabilir', () {
      expect(VehicleTroubles.applies(arac('bisiklet')), isFalse);
      expect(VehicleTroubles.applies(arac('otomobil_orta')), isTrue);
      expect(VehicleTroubles.applies(arac('motosiklet_ekonomik')), isTrue);
    });

    test('ucuz ve yıpranmış araç, pahalı ve bakımlı araçtan sık bozulur', () {
      expect(
        VehicleTroubles.chance(arac('otomobil_hurdaya_yakin', condition: 20)),
        greaterThan(
          VehicleTroubles.chance(arac('otomobil_luks', condition: 95)),
        ),
      );
    });

    test('bakımlı araçta ihtimal çok düşük kalır', () {
      expect(
        VehicleTroubles.chance(arac('otomobil_orta', condition: 90)),
        lessThan(0.05),
      );
    });

    test('parası yetmeyen oyuncunun cüzdanı eksiye düşmez', () {
      bool gorunen = false;
      for (int seed = 0; seed < 200 && !gorunen; seed++) {
        final VehicleTrouble? t = VehicleTroubles.roll(
          item: arac('otomobil_hurdaya_yakin', condition: 15),
          wallet: 0,
          rng: Random(seed),
        );
        if (t == null) continue;
        gorunen = true;
        expect(t.paid, isFalse);
        expect(t.conditionDelta, lessThan(0));
        expect(t.text, contains('paran yetmedi'));
      }
      expect(gorunen, isTrue);
    });

    test('ödenen tamir kondisyonu yükseltir', () {
      bool gorunen = false;
      for (int seed = 0; seed < 200 && !gorunen; seed++) {
        final VehicleTrouble? t = VehicleTroubles.roll(
          item: arac('otomobil_hurdaya_yakin', condition: 15),
          wallet: 10000000,
          rng: Random(seed),
        );
        if (t == null) continue;
        gorunen = true;
        expect(t.paid, isTrue);
        expect(t.conditionDelta, greaterThan(0));
        expect(t.cost, greaterThan(0));
      }
      expect(gorunen, isTrue);
    });
  });

  group('Banka ve kredi (D-080)', () {
    test('iki banka var ve faiz farkı gerçek', () {
      expect(Bank.values.length, 2);
      expect(Bank.fakbank.monthlyRate, lessThan(Bank.bankavrupa.monthlyRate));
      expect(Bank.fakbank.approvalEase,
          lessThan(Bank.bankavrupa.approvalEase));
    });

    test('faiz oranları 2026 piyasa bandında', () {
      // Aylık %2,89 - %5,50 bandı.
      for (final Bank b in Bank.values) {
        expect(b.monthlyRate, greaterThanOrEqualTo(0.0289), reason: b.label);
        expect(b.monthlyRate, lessThanOrEqualTo(0.055), reason: b.label);
      }
    });

    test('vade üç yılı geçmez', () {
      expect(Banking.maxTermYears, lessThanOrEqualTo(3));
    });

    test('18 yaşından küçüğe kredi verilmez', () {
      final GameState s = hayat(1, age: 17);
      final String? engel = Banking.blockReason(s, amount: 500000);
      expect(engel, isNotNull);
      expect(engel, contains('18'));
    });

    test('taksit anüite formülüyle hesaplanır ve faizi içerir', () {
      const int tutar = 300000;
      final int taksit = Banking.annualPaymentFor(
        amount: tutar,
        termYears: 3,
        bank: Bank.fakbank,
      );
      // Faizsiz olsa yılda 100.000 ₺ olurdu; faizle belirgin fazla.
      expect(taksit, greaterThan(100000));
      expect(taksit * 3, greaterThan(tutar));
    });

    test('ucuz banka aynı kredide daha az ödetir', () {
      final int ucuz = Banking.annualPaymentFor(
        amount: 500000,
        termYears: 3,
        bank: Bank.fakbank,
      );
      final int pahali = Banking.annualPaymentFor(
        amount: 500000,
        termYears: 3,
        bank: Bank.bankavrupa,
      );
      expect(ucuz, lessThan(pahali));
    });

    test('kolay onaylayan banka aynı başvuruda daha cömert', () {
      final GameState s = hayat(2, salary: 600000, wallet: 0);
      const int istenen = 900000;
      final LoanDecision f = Banking.evaluate(
        s,
        bank: Bank.fakbank,
        amount: istenen,
        termYears: 3,
      );
      final LoanDecision b = Banking.evaluate(
        s,
        bank: Bank.bankavrupa,
        amount: istenen,
        termYears: 3,
      );
      // Bankavrupa ya onaylar ya da daha büyük bir tutar teklif eder.
      expect(
        b.approved || b.offeredAmount >= f.offeredAmount,
        isTrue,
        reason: 'Fakbank ${f.offeredAmount}, Bankavrupa ${b.offeredAmount}',
      );
    });

    test('karar rastgele değil: aynı koşulda aynı cevap', () {
      final GameState s = hayat(3, salary: 500000);
      final LoanDecision ilk = Banking.evaluate(
        s,
        bank: Bank.fakbank,
        amount: 800000,
        termYears: 3,
      );
      for (int i = 0; i < 10; i++) {
        final LoanDecision tekrar = Banking.evaluate(
          s,
          bank: Bank.fakbank,
          amount: 800000,
          termYears: 3,
        );
        expect(tekrar.approved, ilk.approved);
        expect(tekrar.offeredAmount, ilk.offeredAmount);
      }
    });

    test('onaylanmayan başvuru hiçbir şeyi değiştirmez', () {
      final GameState s = hayat(4, wallet: 1000, salary: null);
      final ({GameState state, LoanDecision decision}) r = Banking.borrow(
        s,
        bank: Bank.fakbank,
        amount: 50000000,
        termYears: 3,
      );
      expect(r.decision.approved, isFalse);
      expect(r.state.player.wallet, s.player.wallet);
      expect(r.state.loans, isEmpty);
    });

    test('onaylanan kredi parayı cüzdana geçirir ve kayıt açar', () {
      final GameState s = hayat(5, salary: 1200000, wallet: 0);
      final ({GameState state, LoanDecision decision}) r = Banking.borrow(
        s,
        bank: Bank.bankavrupa,
        amount: 300000,
        termYears: 2,
      );
      expect(r.decision.approved, isTrue, reason: r.decision.reason);
      expect(r.state.player.wallet, r.decision.offeredAmount);
      expect(r.state.loans.length, 1);
      expect(r.state.loans.single.remainingPayments, 2);
    });

    test('taksitler yıl yıl ödenir ve kredi kapanır', () {
      GameState s = hayat(6, salary: 1200000, wallet: 0);
      s = Banking.borrow(
        s,
        bank: Bank.bankavrupa,
        amount: 200000,
        termYears: 2,
      ).state;
      expect(s.loans.single.isClosed, isFalse);

      // Taksitleri ödeyebilmesi için cüzdan doldurulur.
      s = s.copyWith(player: s.player.copyWith(wallet: 5000000));
      for (int i = 0; i < 2; i++) {
        s = Banking.advanceYear(s).state;
      }
      expect(s.loans.single.isClosed, isTrue);
      expect(Banking.totalDebt(s), 0);
    });

    test('ödenemeyen taksit kaçar ve borç faiziyle büyür', () {
      GameState s = hayat(7, salary: 1200000, wallet: 0);
      s = Banking.borrow(
        s,
        bank: Bank.bankavrupa,
        amount: 300000,
        termYears: 3,
      ).state;
      final int oncekiBorc = s.loans.single.outstanding;

      // Cüzdan boşaltılır: taksit ödenemez.
      s = s.copyWith(player: s.player.copyWith(wallet: 0));
      final ({GameState state, List<String> messages, List<String> missed})
          r = Banking.advanceYear(s);

      expect(r.state.loans.single.missedPayments, 1);
      expect(r.state.loans.single.outstanding, greaterThan(oncekiBorc));
      expect(r.state.player.wallet, 0, reason: 'Cüzdan eksiye düşmez');
      expect(r.messages, isNotEmpty);
      // Kaçan taksit kritik haber listesine de girer (D-097).
      expect(r.missed, isNotEmpty);
    });

    test('kaçan taksit sonraki başvuruyu zorlaştırır', () {
      GameState temiz = hayat(8, salary: 900000, wallet: 0);
      GameState kacirmis = hayat(8, salary: 900000, wallet: 0);
      kacirmis = kacirmis.copyWith(
        loans: <Loan>[
          Loan(
            id: 'eski',
            bank: Bank.bankavrupa,
            principal: 100000,
            annualPayment: 60000,
            termYears: 2,
            remainingPayments: 0,
            outstanding: 0,
            takenAtAge: 30,
            missedPayments: 2,
          ),
        ],
      );

      final LoanDecision a = Banking.evaluate(
        temiz,
        bank: Bank.fakbank,
        amount: 400000,
        termYears: 3,
      );
      final LoanDecision b = Banking.evaluate(
        kacirmis,
        bank: Bank.fakbank,
        amount: 400000,
        termYears: 3,
      );
      expect(a.offeredAmount, greaterThan(b.offeredAmount));
    });

    test('aynı anda ikiden fazla kredi olmaz', () {
      GameState s = hayat(9, salary: 4000000, wallet: 0);
      for (int i = 0; i < Banking.prototypeOnlyMaxActiveLoans; i++) {
        final ({GameState state, LoanDecision decision}) r = Banking.borrow(
          s,
          bank: Bank.bankavrupa,
          amount: 200000,
          termYears: 3,
        );
        expect(r.decision.approved, isTrue, reason: r.decision.reason);
        s = r.state;
      }
      final String? engel = Banking.blockReason(s, amount: 200000);
      expect(engel, isNotNull);
      expect(engel, contains('en fazla'));
    });

    test('erken kapatma kalan borcu siler; parası yetmezse bir şey olmaz', () {
      GameState s = hayat(10, salary: 1200000, wallet: 0);
      s = Banking.borrow(
        s,
        bank: Bank.bankavrupa,
        amount: 200000,
        termYears: 3,
      ).state;
      final String id = s.loans.single.id;

      // Parası yetmiyorken kapatma denemesi.
      final GameState fakir = s.copyWith(
        player: s.player.copyWith(wallet: 0),
      );
      final ({GameState state, String message}) basarisiz =
          Banking.payOff(fakir, id);
      expect(basarisiz.state.loans.single.isClosed, isFalse);
      expect(basarisiz.message, contains('yetmiyor'));

      final GameState zengin = s.copyWith(
        player: s.player.copyWith(wallet: 9000000),
      );
      final ({GameState state, String message}) basarili =
          Banking.payOff(zengin, id);
      expect(basarili.state.loans.single.isClosed, isTrue);
      expect(
        basarili.state.player.wallet,
        lessThan(zengin.player.wallet),
      );
    });

    test('krediler kapat-aç ile korunur', () {
      GameState s = hayat(11, salary: 1200000, wallet: 0);
      s = Banking.borrow(
        s,
        bank: Bank.fakbank,
        amount: 200000,
        termYears: 2,
      ).state;
      final GameState geri = decodeGameState(encodeGameState(s));
      expect(geri.loans.length, s.loans.length);
      expect(geri.loans.single.bank, s.loans.single.bank);
      expect(geri.loans.single.outstanding, s.loans.single.outstanding);
      expect(geri.loans.single.annualPayment, s.loans.single.annualPayment);
    });

    test('eski kayıtta kredi yoktur; boş liste okunur', () {
      final GameState s = hayat(12);
      final Map<String, Object?> json = encodeGameState(s);
      json.remove('loans');
      expect(decodeGameState(json).loans, isEmpty);
    });

    test('piyango ve miras gelir sayılmaz; banka maaşa bakar', () {
      final GameState zenginAmaIssiz = hayat(13, wallet: 50000000);
      expect(Banking.assessedIncome(zenginAmaIssiz), 0);

      final GameState maasli = hayat(13, wallet: 0, salary: 700000);
      expect(Banking.assessedIncome(maasli), 700000);
    });
  });
}

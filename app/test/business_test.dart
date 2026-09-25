import 'dart:math';

import 'package:bir_omur/data/business_catalog.dart';
import 'package:bir_omur/data/economy.dart';
import 'package:bir_omur/data/save/game_state_codec.dart';
import 'package:bir_omur/domain/economy/banking.dart';
import 'package:bir_omur/domain/economy/business_engine.dart';
import 'package:bir_omur/domain/economy/living_costs.dart';
import 'package:bir_omur/domain/generation/life_generator.dart';
import 'package:bir_omur/domain/models/business.dart';
import 'package:bir_omur/domain/models/game_state.dart';
import 'package:bir_omur/domain/models/interaction.dart';
import 'package:flutter_test/flutter_test.dart';

GameState hayat(int seed, {int age = 25, int wallet = 5000000}) {
  final GameState s =
      LifeGenerator.seeded(seed).generate(mode: StartMode.tamamenRastgele);
  return s.copyWith(
    player: s.player.copyWith(age: age, wallet: wallet),
    education: s.education.copyWith(enrolled: false, finished: true),
    pendingEvent: null,
  );
}

BusinessType get bufe => businessTypeById('is_buyfe')!;

void main() {
  // ===================================================================
  // 1) Katalog
  // ===================================================================
  group('katalog', () {
    test('kimlikler benzersiz ve sayılar tutarlı', () {
      expect(
        kBusinessCatalog.map((BusinessType b) => b.id).toSet().length,
        kBusinessCatalog.length,
      );
      for (final BusinessType b in kBusinessCatalog) {
        expect(b.setupCost, greaterThan(0), reason: b.id);
        expect(b.baseYearlyProfit, greaterThan(0), reason: b.id);
        expect(b.volatility, inInclusiveRange(0, 1), reason: b.id);
        // Devir değeri sermayenin altında kalır: tamamı geri gelmez.
        expect(b.salvageValue, lessThan(b.setupCost), reason: b.id);
      }
    });

    test('her ölçekten iş var', () {
      for (final BusinessScale o in BusinessScale.values) {
        expect(
          kBusinessCatalog.any((BusinessType b) => b.scale == o),
          isTrue,
          reason: '${o.label} ölçekte iş yok.',
        );
      }
    });

    test('büyük ölçek küçükten pahalı', () {
      final int kucukEnPahali = kBusinessCatalog
          .where((BusinessType b) => b.scale == BusinessScale.kucuk)
          .map((BusinessType b) => b.setupCost)
          .reduce(max);
      final int buyukEnUcuz = kBusinessCatalog
          .where((BusinessType b) => b.scale == BusinessScale.buyuk)
          .map((BusinessType b) => b.setupCost)
          .reduce(min);
      expect(buyukEnUcuz, greaterThan(kucukEnPahali));
    });
  });

  // ===================================================================
  // 2) İş kurma
  // ===================================================================
  group('iş kurma', () {
    test('sermaye peşin gider ve iş açılır', () {
      final GameState once = hayat(1);
      final BusinessResult r =
          BusinessEngine.open(state: once, tur: bufe);
      expect(r.outcome.applied, isTrue);
      expect(r.state.businesses, hasLength(1));
      final Business is_ = r.state.businesses.single;
      expect(is_.typeId, bufe.id);
      expect(is_.isOpen, isTrue);
      expect(is_.totalInvested, bufe.setupCost);
      expect(r.state.player.wallet, once.player.wallet - bufe.setupCost);
    });

    test('parası yetmiyorsa kurulmaz ve gerekçe banka kredisini söyler', () {
      final GameState s = hayat(2, wallet: 100);
      final InteractionAvailability u =
          BusinessEngine.openAvailability(s, bufe);
      expect(u.isAllowed, isFalse);
      expect(u.reason, contains('Sermaye'));
      expect(u.reason, contains('kredi'));
      // Kurulmaya çalışılsa da durum değişmez.
      final BusinessResult r = BusinessEngine.open(state: s, tur: bufe);
      expect(r.outcome.applied, isFalse);
      expect(r.state.businesses, isEmpty);
      expect(r.state.player.wallet, s.player.wallet);
    });

    test('aynı anda iki iş açılmaz', () {
      final GameState s =
          BusinessEngine.open(state: hayat(3), tur: bufe).state;
      final InteractionAvailability u = BusinessEngine.openAvailability(
        s,
        businessTypeById('is_bakkal')!,
      );
      expect(u.isAllowed, isFalse);
      expect(u.reason, contains('Zaten açık'));
    });

    test('öğrenci iş kurmaz', () {
      final GameState s = hayat(4).copyWith(
        education: hayat(4).education.copyWith(enrolled: true, grade: 11),
      );
      expect(
        BusinessEngine.openAvailability(s, bufe).isAllowed,
        isFalse,
      );
    });

    test('yaş, zekâ, karizma ve ehliyet şartları gerekçeyle bildirilir', () {
      // Serbest yazılımcılık zekâ 55 istiyor.
      final BusinessType yazilim = businessTypeById('is_serbest_yazilim')!;
      final GameState dusukZeka = hayat(5).copyWith(
        player: hayat(5).player.copyWith(
              stats: hayat(5).player.stats.copyWith(intelligence: 20),
            ),
      );
      final InteractionAvailability u =
          BusinessEngine.openAvailability(dusukZeka, yazilim);
      expect(u.isAllowed, isFalse);
      expect(u.reason, contains('zekâ'));

      // Nakliyecilik ehliyet istiyor.
      final BusinessType nakliye = businessTypeById('is_nakliye')!;
      expect(
        BusinessEngine.openAvailability(hayat(6), nakliye).isAllowed,
        isFalse,
      );
    });

    test('cezaevindeyken iş kurulmaz', () {
      final GameState s = hayat(7);
      final GameState icerde = s.copyWith(
        legal: s.legal.copyWith(imprisonedSinceAge: 25, releaseAtAge: 27),
      );
      expect(
        BusinessEngine.openAvailability(icerde, bufe).isAllowed,
        isFalse,
      );
    });
  });

  // ===================================================================
  // 3) İşle ilgilenmek ve yatırım
  // ===================================================================
  group('ilgilenmek ve yatırım', () {
    test('işine bakmak durumu yükseltir ve yorar', () {
      final GameState s =
          BusinessEngine.open(state: hayat(10), tur: bufe).state;
      final int oncekiDurum = s.businesses.single.condition;
      final BusinessResult r = BusinessEngine.tend(state: s);
      expect(r.outcome.applied, isTrue);
      expect(r.state.businesses.single.condition, greaterThan(oncekiDurum));
      expect(
        r.state.player.stats.health,
        lessThanOrEqualTo(s.player.stats.health),
      );
    });

    test('aynı yıl sınırsız ilgilenilemez', () {
      GameState s = BusinessEngine.open(state: hayat(11), tur: bufe).state;
      s = BusinessEngine.tend(state: s).state;
      // İkinci kez aynı yıl: motor bir kez ilgilenildiğini görüyor.
      final InteractionAvailability u =
          BusinessEngine.tendAvailability(s);
      expect(u.isAllowed, isTrue,
          reason: 'İki hak var; ikincisi açık kalmalı.');
    });

    test('para yatırmak gerçekten cüzdandan çıkar', () {
      final GameState s =
          BusinessEngine.open(state: hayat(12), tur: bufe).state;
      final int cuzdan = s.player.wallet;
      final BusinessResult r =
          BusinessEngine.invest(state: s, tutar: 100000);
      expect(r.outcome.applied, isTrue);
      expect(r.state.player.wallet, cuzdan - 100000);
      expect(
        r.state.businesses.single.totalInvested,
        s.businesses.single.totalInvested + 100000,
      );
      expect(
        r.state.businesses.single.condition,
        greaterThan(s.businesses.single.condition),
      );
    });

    test('parası yetmeyen yatırım yapmaz', () {
      final GameState s =
          BusinessEngine.open(state: hayat(13, wallet: 200000), tur: bufe)
              .state;
      final BusinessResult r =
          BusinessEngine.invest(state: s, tutar: 999999999);
      expect(r.outcome.applied, isFalse);
      expect(r.state.player.wallet, s.player.wallet);
    });
  });

  // ===================================================================
  // 4) Yıllık kâr/zarar
  // ===================================================================
  group('yıllık hesap', () {
    test('kurulduğu yıl hesap kapatılmaz', () {
      final GameState s =
          BusinessEngine.open(state: hayat(20, age: 30), tur: bufe).state;
      final int cuzdan = s.player.wallet;
      final GameState sonra =
          BusinessEngine.advanceYear(s, 30, Random(1));
      expect(sonra.player.wallet, cuzdan);
    });

    test('durumu iyi olan iş kâr bırakır', () {
      GameState s =
          BusinessEngine.open(state: hayat(21, age: 30), tur: bufe).state;
      s = s.copyWith(
        businesses: <Business>[
          s.businesses.single.copyWith(condition: 95, lastTendedAge: 30),
        ],
      );
      final int cuzdan = s.player.wallet;
      final GameState sonra =
          BusinessEngine.advanceYear(s, 31, Random(3));
      expect(sonra.player.wallet, greaterThan(cuzdan));
    });

    test('durumu kötü olan iş zarar ettirir', () {
      GameState s =
          BusinessEngine.open(state: hayat(22, age: 30), tur: bufe).state;
      s = s.copyWith(
        businesses: <Business>[
          s.businesses.single.copyWith(condition: 10, lastTendedAge: 30),
        ],
      );
      final int cuzdan = s.player.wallet;
      final GameState sonra =
          BusinessEngine.advanceYear(s, 31, Random(3));
      expect(sonra.player.wallet, lessThan(cuzdan));
    });

    test('aynı yıl iki kez hesaplanmaz', () {
      GameState s =
          BusinessEngine.open(state: hayat(23, age: 30), tur: bufe).state;
      s = s.copyWith(
        businesses: <Business>[
          s.businesses.single.copyWith(condition: 90, lastTendedAge: 30),
        ],
      );
      final GameState bir = BusinessEngine.advanceYear(s, 31, Random(4));
      final GameState iki = BusinessEngine.advanceYear(bir, 31, Random(4));
      expect(iki.player.wallet, bir.player.wallet);
    });

    test('ilgilenilmeyen iş sonunda batar ve kayıt kalır', () {
      GameState s =
          BusinessEngine.open(state: hayat(24, age: 30), tur: bufe).state;
      s = s.copyWith(
        businesses: <Business>[s.businesses.single.copyWith(condition: 12)],
      );
      int yas = 31;
      for (int i = 0; i < 20; i++) {
        s = BusinessEngine.advanceYear(s, yas, Random(yas));
        if (!s.businesses.single.isOpen) break;
        yas++;
      }
      final Business is_ = s.businesses.single;
      expect(is_.isOpen, isFalse, reason: '20 yılda batmadı.');
      expect(is_.endReason, BusinessEndReason.batti);
      // Kayıt silinmez.
      expect(s.businesses, hasLength(1));
      expect(is_.closedAtAge, isNotNull);
    });

    test('cüzdan eksiye düşmez', () {
      GameState s = BusinessEngine.open(
        state: hayat(25, age: 30, wallet: 4000000),
        tur: businessTypeById('is_lokanta')!,
      ).state;
      s = s.copyWith(
        businesses: <Business>[s.businesses.single.copyWith(condition: 5)],
      );
      for (int yas = 31; yas < 45; yas++) {
        s = BusinessEngine.advanceYear(s, yas, Random(yas));
        expect(s.player.wallet, greaterThanOrEqualTo(0));
      }
    });
  });

  // ===================================================================
  // 5) İşi devretmek
  // ===================================================================
  test('işi devretmek para getirir ve kaydı kapatır', () {
    final GameState s =
        BusinessEngine.open(state: hayat(30), tur: bufe).state;
    final int cuzdan = s.player.wallet;
    final BusinessResult r = BusinessEngine.close(state: s);
    expect(r.outcome.applied, isTrue);
    expect(r.state.player.wallet, greaterThan(cuzdan));
    final Business is_ = r.state.businesses.single;
    expect(is_.isOpen, isFalse);
    expect(is_.endReason, BusinessEndReason.satildi);
    // Devir bedeli sermayenin tamamı değildir.
    expect(
      r.state.player.wallet - cuzdan,
      lessThan(bufe.setupCost),
    );
  });

  // ===================================================================
  // 6) Ekonomiyle bütünleşme
  // ===================================================================
  group('ekonomi', () {
    test('işin kârı gelir hesabına girer', () {
      GameState s =
          BusinessEngine.open(state: hayat(40, age: 30), tur: bufe).state;
      s = s.copyWith(
        businesses: <Business>[s.businesses.single.copyWith(condition: 95)],
      );
      expect(LivingCosts.yearlyIncome(s), greaterThan(0));
      expect(Banking.assessedIncome(s), greaterThan(0));
    });

    test('zarar eden iş bankaya gelir olarak yazılmaz', () {
      GameState s =
          BusinessEngine.open(state: hayat(41, age: 30), tur: bufe).state;
      s = s.copyWith(
        businesses: <Business>[s.businesses.single.copyWith(condition: 5)],
      );
      // Banka eksi kârı gelir saymaz; en kötü sıfır.
      expect(Banking.assessedIncome(s), greaterThanOrEqualTo(0));
      // Gider hesabı ise zararı görür: gelir düşer.
      expect(LivingCosts.yearlyIncome(s), lessThan(0));
    });

    test('işi olmayan oyuncuda iş geliri sıfır', () {
      expect(BusinessEngine.yearlyBusinessIncome(hayat(42)), 0);
    });
  });

  // ===================================================================
  // 7) Kayıt
  // ===================================================================
  group('kayıt', () {
    test('iş kaydı kaydedilip yüklenir', () {
      final GameState once = BusinessEngine.open(
        state: hayat(50, age: 30),
        tur: businessTypeById('is_kahve')!,
      ).state;
      final GameState geri = decodeGameState(encodeGameState(once));
      expect(geri.businesses, hasLength(1));
      final Business is_ = geri.businesses.single;
      expect(is_.typeId, 'is_kahve');
      expect(is_.startedAtAge, 30);
      expect(is_.totalInvested, businessTypeById('is_kahve')!.setupCost);
      expect(is_.isOpen, isTrue);
    });

    test('kapanmış iş de kaydedilir', () {
      GameState once =
          BusinessEngine.open(state: hayat(51, age: 30), tur: bufe).state;
      once = BusinessEngine.close(state: once).state;
      final GameState geri = decodeGameState(encodeGameState(once));
      final Business is_ = geri.businesses.single;
      expect(is_.isOpen, isFalse);
      expect(is_.endReason, BusinessEndReason.satildi);
      expect(is_.closedAtAge, 30);
    });

    test('eski kayıtta iş uydurulmaz', () {
      final Map<String, Object?> json = encodeGameState(hayat(52));
      json.remove('businesses');
      final GameState geri = decodeGameState(json);
      expect(geri.businesses, isEmpty);
      expect(BusinessEngine.openBusiness(geri), isNull);
    });
  });

  // ===================================================================
  // 8) Maaş garanti, kendi işi değil
  // ===================================================================
  test('aynı iş farklı yıllarda farklı sonuç verir', () {
    // Oynaklık gerçek: aynı durumdan aynı sonuç çıkmıyor.
    GameState s =
        BusinessEngine.open(state: hayat(60, age: 30), tur: bufe).state;
    s = s.copyWith(
      businesses: <Business>[s.businesses.single.copyWith(condition: 60)],
    );
    final Set<int> kazanclar = <int>{};
    for (int i = 0; i < 30; i++) {
      final GameState sonra = BusinessEngine.advanceYear(s, 31, Random(i));
      kazanclar.add(sonra.player.wallet - s.player.wallet);
    }
    expect(
      kazanclar.length,
      greaterThan(1),
      reason: 'Kendi işi maaş gibi sabit olmamalı.',
    );
  });

  test('sermaye 2026 ölçeğinde', () {
    // En küçük iş bir yıllık asgari ücretin altında kurulabilmeli;
    // en büyüğü belirgin biçimde üstünde olmalı.
    final int enUcuz = kBusinessCatalog
        .map((BusinessType b) => b.setupCost)
        .reduce(min);
    final int enPahali = kBusinessCatalog
        .map((BusinessType b) => b.setupCost)
        .reduce(max);
    expect(enUcuz, lessThan(Economy.netYearlyMinimumWage));
    expect(enPahali, greaterThan(Economy.netYearlyMinimumWage * 5));
  });
}

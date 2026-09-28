/// Paket AE — işletme yönetimi: fiyat, talep, personel, bakım, reklam.
///
/// **Neden bu testler var.** AE öncesinde işletmenin tek sayısı vardı ve
/// ölçümde `girisim + yatirim` dokuz stratejiyi birden eziyordu
/// (Q-174/1). AE işletmeyi yönetilen bir sistem yaptı; bu dosya o
/// sistemin sözlerini denetler:
///
/// * fiyat kararı gerçek bir tercih (§4, §34),
/// * reklam garanti para değil (§8, §35),
/// * bakım ve personel gerçekten gerekli (§7, §10),
/// * olaylar iki kez uygulanmıyor ve yeniden çevrilemiyor (§36),
/// * kapanan işletme gelir üretmiyor (§36).
library;

import 'dart:math';

import 'package:bir_omur/data/business_catalog.dart';
import 'package:bir_omur/data/business_incident_catalog.dart';
import 'package:bir_omur/data/save/game_state_codec.dart';
import 'package:bir_omur/domain/economy/business_engine.dart';
import 'package:bir_omur/domain/economy/business_incidents.dart';
import 'package:bir_omur/domain/economy/business_market.dart';
import 'package:bir_omur/domain/generation/life_generator.dart';
import 'package:bir_omur/domain/models/business.dart';
import 'package:bir_omur/domain/models/game_state.dart';
import 'package:bir_omur/domain/models/pending_notice.dart';
import 'package:flutter_test/flutter_test.dart';

GameState hayat(int seed, {int age = 30, int wallet = 20000000}) {
  final GameState s =
      LifeGenerator.seeded(seed).generate(mode: StartMode.tamamenRastgele);
  return s.copyWith(
    player: s.player.copyWith(
      age: age,
      wallet: wallet,
      // Katalogdaki **her** işi kurabilelim: bu dosya kurulma şartlarını
      // değil, kurulduktan sonraki yönetimi ölçüyor. Şartların kendisi
      // `business_test.dart` içinde denetleniyor.
      stats: s.player.stats.copyWith(intelligence: 80, charisma: 80),
    ),
    licenses: const <String>{'otomobil_ehliyeti'},
    education: s.education.copyWith(enrolled: false, finished: true),
    pendingEvent: null,
  );
}

BusinessType tur(String id) => businessTypeById(id)!;

/// İşi kurar ve istenen hâle getirir.
GameState isle(
  int seed,
  String turId, {
  int age = 30,
  int condition = 70,
  int? price,
  BusinessAd ad = BusinessAd.yok,
  int reputation = 50,
  int upkeep = 85,
}) {
  GameState s =
      BusinessEngine.open(state: hayat(seed, age: age), tur: tur(turId)).state;
  s = s.copyWith(
    businesses: <Business>[
      s.businesses.single.copyWith(
        condition: condition,
        reputation: reputation,
        upkeep: upkeep,
        price: price ?? 0,
        ad: ad,
        lastTendedAge: age,
      ),
    ],
  );
  return s;
}

/// Bir işletmeyi [yil] yıl boyunca yürütür ve toplam net sonucu döner.
int topla(GameState s, int baslangic, int yil, {bool bak = true}) {
  int toplam = 0;
  GameState o = s;
  for (int i = 1; i <= yil; i++) {
    final int yas = baslangic + i;
    if (bak) {
      o = o.copyWith(
        businesses: <Business>[
          for (final Business b in o.businesses)
            b.isOpen ? b.copyWith(lastTendedAge: yas) : b,
        ],
      );
    }
    o = o.copyWith(player: o.player.copyWith(age: yas));
    final int once = o.player.wallet;
    o = BusinessEngine.advanceYear(o, yas, Random(7));
    toplam += o.player.wallet - once;
  }
  return toplam;
}

void main() {
  // ===================================================================
  // 1) Katalog (§1, §2, §22)
  // ===================================================================
  group('katalog', () {
    test('14 işletme var ve oto yıkama eklendi', () {
      expect(kBusinessCatalog.length, 14);
      expect(businessTypeById('is_oto_yikama'), isNotNull);
    });

    test('her işletmenin kendi fiyat başlığı ve fiyatı var', () {
      final Set<String> basliklar = <String>{};
      for (final BusinessType b in kBusinessCatalog) {
        expect(b.priceLabel, isNotEmpty, reason: b.id);
        expect(b.basePrice, greaterThan(0), reason: b.id);
        expect(b.priceElasticity, greaterThan(0), reason: b.id);
        expect(b.costShare, lessThan(1.0), reason: '${b.id} gideri ciroyu '
            'aşıyor');
        expect(b.costShare, greaterThan(0.05), reason: '${b.id} gidersiz');
        basliklar.add(b.priceLabel);
      }
      // Fiyat başlıkları birbirinin aynısı olmamalı: her işin sattığı şey
      // kendine ait (§2).
      expect(basliklar.length, greaterThanOrEqualTo(12));
    });

    test('taban ciro taban kârdan büyük', () {
      for (final BusinessType b in kBusinessCatalog) {
        expect(b.baseRevenue, greaterThan(b.baseYearlyProfit), reason: b.id);
        expect(b.baseUnits, greaterThan(0), reason: b.id);
      }
    });

    test('elastikiyet işten işe farklı (§4)', () {
      final Set<double> e =
          kBusinessCatalog.map((BusinessType b) => b.priceElasticity).toSet();
      expect(e.length, greaterThanOrEqualTo(8));
      // Halı saha fiyat hassasiyeti yüksek, oto tamir düşük olmalı.
      expect(
        tur('is_hali_saha').priceElasticity,
        greaterThan(tur('is_oto_tamir').priceElasticity),
      );
      // Oto tamirde itibar daha çok konuşur.
      expect(
        tur('is_oto_tamir').reputationWeight,
        greaterThan(tur('is_hali_saha').reputationWeight),
      );
    });
  });

  // ===================================================================
  // 2) Piyasa ortalaması (§3)
  // ===================================================================
  group('bölge ortalaması', () {
    test('gerçek yıl ya da tarihe bağlı değil (§25)', () {
      final GameState s = hayat(1);
      final int a = BusinessMarket.averagePrice(s, tur('is_kahve'), 30);
      final int b = BusinessMarket.averagePrice(s, tur('is_kahve'), 30);
      expect(a, b);
      expect(a, greaterThan(0));
    });

    test('şehirden şehre değişir', () {
      final GameState ist = hayat(2).copyWith(
        player: hayat(2).player.copyWith(currentCity: 'İstanbul'),
      );
      final GameState ama = hayat(2).copyWith(
        player: hayat(2).player.copyWith(currentCity: 'Amasya'),
      );
      expect(
        BusinessMarket.averagePrice(ist, tur('is_kahve'), 30),
        greaterThan(BusinessMarket.averagePrice(ama, tur('is_kahve'), 30)),
      );
    });

    test('fiyat belirlenmemişse ortalamadan çalışır (§4)', () {
      final GameState s = isle(3, 'is_kahve');
      final Business b = s.businesses.single;
      expect(b.price, 0);
      expect(
        BusinessMarket.effectivePrice(s, b, tur('is_kahve'), 30),
        BusinessMarket.averagePrice(s, tur('is_kahve'), 30),
      );
    });
  });

  // ===================================================================
  // 3) Fiyat kararı ve exploit (§4, §34)
  // ===================================================================
  group('fiyat', () {
    test('fiyat arttıkça müşteri azalır, azaldıkça artar', () {
      final GameState s = isle(4, 'is_kahve');
      final int ort = BusinessMarket.averagePrice(s, tur('is_kahve'), 30);
      int yogunluk(int fiyat) => BusinessMarket.demand(
            state: s,
            business: s.businesses.single.copyWith(price: fiyat),
            tur: tur('is_kahve'),
            age: 30,
            rng: Random(1),
          ).index;
      expect(yogunluk((ort * 0.7).round()), greaterThan(yogunluk(ort)));
      expect(yogunluk(ort), greaterThan(yogunluk((ort * 1.5).round())));
    });

    test('aralık dışındaki fiyat kabul edilmez', () {
      final GameState s = isle(5, 'is_kahve');
      final ({int min, int max}) a =
          BusinessEngine.priceRange(s, s.businesses.single);
      expect(BusinessEngine.setPrice(state: s, fiyat: a.min - 1)
          .outcome.applied, isFalse);
      expect(BusinessEngine.setPrice(state: s, fiyat: a.max + 1)
          .outcome.applied, isFalse);
      expect(
        BusinessEngine.setPrice(state: s, fiyat: a.max).outcome.applied,
        isTrue,
      );
    });

    test('en yüksek fiyat her zaman en kârlı DEĞİL (§34)', () {
      // Tek bir işletmede değil, bütün katalogda denetlenir: bir işte
      // pahalı doğru olabilir, hepsinde olamaz.
      int kazanan = 0;
      for (final BusinessType t in kBusinessCatalog) {
        final GameState taban = isle(11, t.id, age: 30);
        final int ort = BusinessMarket.averagePrice(taban, t, 30);
        final Map<String, int> sonuc = <String, int>{};
        for (final MapEntry<String, double> e in <String, double>{
          'ucuz': 0.72,
          'piyasa': 1.0,
          'pahali': 1.45,
        }.entries) {
          final GameState s = isle(11, t.id, age: 30,
              price: (ort * e.value).round());
          sonuc[e.key] = topla(s, 30, 12);
        }
        final String enIyi = sonuc.entries
            .reduce((MapEntry<String, int> a, MapEntry<String, int> b) =>
                a.value >= b.value ? a : b)
            .key;
        if (enIyi == 'pahali') kazanan++;
      }
      expect(
        kazanan,
        lessThan(kBusinessCatalog.length),
        reason: 'Her işte en pahalı fiyat kazanıyorsa sistem bozuk.',
      );
    });

    test('en düşük fiyat her zaman en kârlı DEĞİL (§34)', () {
      int kazanan = 0;
      for (final BusinessType t in kBusinessCatalog) {
        final GameState taban = isle(12, t.id, age: 30);
        final int ort = BusinessMarket.averagePrice(taban, t, 30);
        final Map<String, int> sonuc = <String, int>{};
        for (final MapEntry<String, double> e in <String, double>{
          'ucuz': 0.72,
          'piyasa': 1.0,
          'pahali': 1.45,
        }.entries) {
          final GameState s = isle(12, t.id, age: 30,
              price: (ort * e.value).round());
          sonuc[e.key] = topla(s, 30, 12);
        }
        final String enIyi = sonuc.entries
            .reduce((MapEntry<String, int> a, MapEntry<String, int> b) =>
                a.value >= b.value ? a : b)
            .key;
        if (enIyi == 'ucuz') kazanan++;
      }
      expect(
        kazanan,
        lessThan(kBusinessCatalog.length),
        reason: 'Her işte en ucuz fiyat kazanıyorsa sistem bozuk.',
      );
    });

    test('fiyatı yıl içinde değiştirmek gelir üretmez (§36)', () {
      GameState s = isle(6, 'is_kahve', age: 30);
      final int once = s.player.wallet;
      final int ort = BusinessMarket.averagePrice(s, tur('is_kahve'), 30);
      for (int i = 0; i < 20; i++) {
        s = BusinessEngine.setPrice(state: s, fiyat: ort + i).state;
      }
      expect(s.player.wallet, once, reason: 'Fiyat değiştirmek para vermez.');
    });
  });

  // ===================================================================
  // 4) Reklam (§8, §35)
  // ===================================================================
  group('reklam', () {
    test('kampanya kurulur ve değiştirilir', () {
      GameState s = isle(7, 'is_kahve');
      s = BusinessEngine.setAd(state: s, reklam: BusinessAd.buyuk).state;
      expect(s.businesses.single.ad, BusinessAd.buyuk);
      // Aynısı ikinci kez uygulanmaz.
      expect(
        BusinessEngine.setAd(state: s, reklam: BusinessAd.buyuk)
            .outcome.applied,
        isFalse,
      );
    });

    test('her yıl en pahalı reklam garanti para üretmez (§35)', () {
      // Aynı işletme, aynı hayat, tek fark reklam.
      int reklamli = 0;
      int reklamsiz = 0;
      int reklamliKazandi = 0;
      for (final BusinessType t in kBusinessCatalog) {
        final int a = topla(isle(21, t.id, ad: BusinessAd.buyuk), 30, 15);
        final int b = topla(isle(21, t.id), 30, 15);
        reklamli += a;
        reklamsiz += b;
        if (a > b) reklamliKazandi++;
      }
      expect(
        reklamliKazandi,
        lessThan(kBusinessCatalog.length),
        reason: 'Büyük kampanya her işte kazandırıyorsa bedeli gerçek değil. '
            'Toplam: reklamlı $reklamli, reklamsız $reklamsiz.',
      );
    });

    test('üst üste reklamda azalan marjinal etki var (§8)', () {
      final Business b = isle(8, 'is_kahve', ad: BusinessAd.sosyalMedya)
          .businesses
          .single;
      double ortalamaEtki(int streak) {
        double t = 0;
        for (int i = 0; i < 400; i++) {
          t += BusinessEngine.adLiftForTest(
            b.copyWith(adStreak: streak),
            Random(i),
          );
        }
        return t / 400;
      }

      expect(ortalamaEtki(0), greaterThan(ortalamaEtki(1)));
      expect(ortalamaEtki(1), greaterThan(ortalamaEtki(3)));
    });

    test('reklam bedeli yıl raporuna yazılır', () {
      GameState s = isle(9, 'is_kahve', age: 30, ad: BusinessAd.buyuk);
      s = s.copyWith(player: s.player.copyWith(age: 31));
      s = BusinessEngine.advanceYear(s, 31, Random(2));
      expect(s.businesses.single.lastYear!.adCost, greaterThan(0));
    });
  });

  // ===================================================================
  // 5) Bakım ve personel (§7, §10)
  // ===================================================================
  group('bakım ve personel', () {
    test('bakım parayı alır, ekipmanı toparlar, yılda bir kez', () {
      GameState s = isle(10, 'is_kahve', upkeep: 40);
      final int once = s.player.wallet;
      final BusinessResult r = BusinessEngine.doMaintenance(state: s);
      expect(r.outcome.applied, isTrue);
      expect(r.state.player.wallet, lessThan(once));
      expect(r.state.businesses.single.upkeep, greaterThan(40));
      expect(
        BusinessEngine.maintenanceAvailability(r.state).isAllowed,
        isFalse,
        reason: 'Aynı yıl ikinci bakım olmaz.',
      );
    });

    test('bakımsız ekipman yıpranır', () {
      GameState s = isle(13, 'is_hali_saha', age: 30, upkeep: 90);
      for (int yas = 31; yas <= 36; yas++) {
        s = s.copyWith(
          player: s.player.copyWith(age: yas),
          businesses: <Business>[
            s.businesses.single.copyWith(lastTendedAge: yas),
          ],
        );
        s = BusinessEngine.advanceYear(s, yas, Random(3));
      }
      expect(s.businesses.single.upkeep, lessThan(60));
    });

    test('tek kişilik işte personel hamlesi yok', () {
      final GameState s = isle(14, 'is_serbest_yazilim');
      expect(
        BusinessEngine.staffAvailability(s, StaffAction.zam).isAllowed,
        isFalse,
      );
    });

    test('zam memnuniyeti yükseltir ve gideri kalıcı artırır', () {
      final GameState s = isle(15, 'is_lokanta');
      final BusinessResult r =
          BusinessEngine.staff(state: s, hamle: StaffAction.zam);
      expect(r.outcome.applied, isTrue);
      final Business b = r.state.businesses.single;
      expect(b.staffMorale, greaterThan(s.businesses.single.staffMorale));
      expect(b.wageLevel, greaterThan(100));
      // Yılda bir kez.
      expect(
        BusinessEngine.staffAvailability(r.state, StaffAction.zam).isAllowed,
        isFalse,
      );
    });

    test('eksik kadro doldurulur ve bedeli çıkar', () {
      GameState s = isle(16, 'is_lokanta');
      s = s.copyWith(
        businesses: <Business>[s.businesses.single.copyWith(staffCount: 3)],
      );
      final int once = s.player.wallet;
      final BusinessResult r =
          BusinessEngine.staff(state: s, hamle: StaffAction.iseAl);
      expect(r.outcome.applied, isTrue);
      expect(r.state.businesses.single.effectiveStaff, 4);
      expect(r.state.player.wallet, lessThan(once));
    });
  });

  // ===================================================================
  // 6) Olaylar (§11-25, §36)
  // ===================================================================
  group('olaylar', () {
    test('katalog tutarlı ve etiketsiz olay yok', () {
      expect(kBusinessIncidents.length, greaterThanOrEqualTo(60));
      final Set<String> id = <String>{};
      for (final BusinessIncident o in kBusinessIncidents) {
        expect(id.add(o.id), isTrue, reason: 'Tekrarlı kimlik: ${o.id}');
        expect(o.tags, isNotEmpty, reason: o.id);
        expect(o.title, isNotEmpty, reason: o.id);
        expect(o.text, isNotEmpty, reason: o.id);
        expect(o.weight, greaterThan(0), reason: o.id);
      }
    });

    test('her olayın bir alıcısı var', () {
      for (final BusinessIncident o in kBusinessIncidents) {
        if (o.tags.contains('*')) continue;
        final bool alici = kBusinessCatalog.any(
          (BusinessType t) => o.tags.any(t.incidentTags.contains),
        );
        expect(alici, isTrue, reason: '${o.id} hiçbir işletmeye gitmiyor.');
      }
    });

    test('serbest yazılımcıya dükkân olayı gelmez (§21)', () {
      final GameState s = isle(17, 'is_serbest_yazilim');
      final Set<String> gorulen = <String>{};
      GameState o = s;
      for (int yas = 31; yas <= 80; yas++) {
        o = o.copyWith(
          player: o.player.copyWith(age: yas),
          businesses: <Business>[
            o.businesses.single.copyWith(lastTendedAge: yas, condition: 70),
          ],
        );
        final Business b = o.businesses.single;
        final BusinessIncidentOutcome r = BusinessIncidents.advance(
          state: o,
          business: b,
          tur: tur('is_serbest_yazilim'),
          newAge: yas,
          rng: Random(BusinessMarket.seed(o, b.id, yas)),
          lastDemandIndex: 100,
        );
        gorulen.addAll(r.business.recentIncidents);
      }
      for (final String id in gorulen) {
        final BusinessIncident o2 =
            kBusinessIncidents.firstWhere((BusinessIncident e) => e.id == id);
        expect(
          o2.tags.contains('serbest') || o2.tags.contains('*'),
          isTrue,
          reason: 'Serbest yazılımcıya $id geldi.',
        );
      }
      expect(gorulen, isNotEmpty);
    });

    test('aynı olay aynı yıl iki kez uygulanmaz (§36)', () {
      // Yıl hesabı bir kez kapanır; ikinci çağrı hiçbir şey yapmaz.
      GameState s = isle(18, 'is_hali_saha', age: 30);
      s = s.copyWith(player: s.player.copyWith(age: 31));
      final GameState bir = BusinessEngine.advanceYear(s, 31, Random(1));
      final GameState iki = BusinessEngine.advanceYear(bir, 31, Random(1));
      expect(iki.player.wallet, bir.player.wallet);
      expect(
        iki.businesses.single.recentIncidents,
        bir.businesses.single.recentIncidents,
      );
    });

    test('aynı olay arka arkaya çıkmaz', () {
      GameState s = isle(19, 'is_lokanta', age: 30);
      String? onceki;
      for (int yas = 31; yas <= 70; yas++) {
        s = s.copyWith(
          player: s.player.copyWith(age: yas),
          businesses: <Business>[
            for (final Business b in s.businesses)
              b.isOpen
                  ? b.copyWith(lastTendedAge: yas, condition: 70, upkeep: 80)
                  : b,
          ],
        );
        final Business? acik = BusinessEngine.openBusiness(s);
        if (acik == null) break;
        final int oncekiSayi = acik.recentIncidents.length;
        s = BusinessEngine.advanceYear(s, yas, Random(1));
        final Business? sonra = BusinessEngine.openBusiness(s);
        if (sonra == null) break;
        if (sonra.recentIncidents.length > oncekiSayi) {
          final String yeni = sonra.recentIncidents.last;
          expect(yeni, isNot(onceki));
          onceki = yeni;
        }
      }
    });

    test('kapanan işletme gelir üretmez (§36)', () {
      GameState s = isle(20, 'is_kahve', age: 30);
      s = BusinessEngine.close(state: s).state;
      final int once = s.player.wallet;
      for (int yas = 31; yas <= 40; yas++) {
        s = s.copyWith(player: s.player.copyWith(age: yas));
        s = BusinessEngine.advanceYear(s, yas, Random(1));
      }
      expect(s.player.wallet, once);
      expect(BusinessEngine.yearlyBusinessIncome(s), 0);
    });
  });

  // ===================================================================
  // 7) Yıl raporu ve bildirim eşiği (§25, §28, §31)
  // ===================================================================
  group('yıl raporu', () {
    test('rapor bütün gider kalemlerini yazar', () {
      GameState s = isle(22, 'is_lokanta', age: 30, ad: BusinessAd.mahalle);
      s = s.copyWith(player: s.player.copyWith(age: 31));
      s = BusinessEngine.advanceYear(s, 31, Random(1));
      final BusinessYear y = s.businesses.single.lastYear!;
      final String rapor = BusinessEngine.yearReport(tur('is_lokanta'), y);
      expect(rapor, contains('Ciro'));
      expect(rapor, contains('Personel'));
      expect(rapor, contains('Tedarik'));
      expect(rapor, contains('Net'));
      expect(y.revenue, greaterThan(0));
      expect(y.totalCost, greaterThan(0));
    });

    test('geçmiş en fazla beş yıl tutulur', () {
      GameState s = isle(23, 'is_kahve', age: 30);
      for (int yas = 31; yas <= 45; yas++) {
        s = s.copyWith(
          player: s.player.copyWith(age: yas),
          businesses: <Business>[
            for (final Business b in s.businesses)
              b.isOpen ? b.copyWith(lastTendedAge: yas, condition: 70) : b,
          ],
        );
        s = BusinessEngine.advanceYear(s, yas, Random(1));
      }
      expect(
        s.businesses.single.history.length,
        lessThanOrEqualTo(Business.prototypeOnlyHistoryYears),
      );
    });

    test('rutin yıl pencere açmaz (§25)', () {
      // Sıradan bir yılda bildirim yağmuru olmamalı: 20 yılda açılan
      // pencere sayısı yıl sayısının belirgin altında kalmalı.
      GameState s = isle(24, 'is_kahve', age: 30);
      int pencere = 0;
      for (int yas = 31; yas <= 50; yas++) {
        s = s.copyWith(
          player: s.player.copyWith(age: yas),
          businesses: <Business>[
            for (final Business b in s.businesses)
              b.isOpen ? b.copyWith(lastTendedAge: yas) : b,
          ],
        );
        final int once = s.notices.length;
        s = BusinessEngine.advanceYear(s, yas, Random(1));
        pencere += s.notices.length - once;
        s = s.copyWith(notices: const <PendingNotice>[]);
        if (BusinessEngine.openBusiness(s) == null) break;
      }
      expect(pencere, lessThan(20), reason: 'Bildirim yağmuru var.');
    });
  });

  // ===================================================================
  // 8) Kayıt (§36)
  // ===================================================================
  group('kayıt', () {
    test('fiyat, personel, reklam, bakım ve geçmiş kaydedilir', () {
      GameState s = isle(25, 'is_lokanta', age: 30);
      s = BusinessEngine.setAd(state: s, reklam: BusinessAd.sosyalMedya).state;
      s = BusinessEngine.staff(state: s, hamle: StaffAction.zam).state;
      s = s.copyWith(
        businesses: <Business>[
          s.businesses.single.copyWith(price: 900, staffCount: 4),
        ],
      );
      s = s.copyWith(player: s.player.copyWith(age: 31));
      s = BusinessEngine.advanceYear(s, 31, Random(1));

      final Business once = s.businesses.single;
      final GameState geri = decodeGameState(encodeGameState(s));
      final Business sonra = geri.businesses.single;

      expect(sonra.price, once.price);
      expect(sonra.ad, once.ad);
      expect(sonra.adStreak, once.adStreak);
      expect(sonra.reputation, once.reputation);
      expect(sonra.upkeep, once.upkeep);
      expect(sonra.staffCount, once.staffCount);
      expect(sonra.staffMorale, once.staffMorale);
      expect(sonra.staffQuality, once.staffQuality);
      expect(sonra.wageLevel, once.wageLevel);
      expect(sonra.recentIncidents, once.recentIncidents);
      expect(sonra.history.length, once.history.length);
      expect(sonra.lastYear!.net, once.lastYear!.net);
      expect(sonra.lastYear!.revenue, once.lastYear!.revenue);
    });

    test('kayıt geri yüklenince aynı yıl aynı sonucu verir (§36)', () {
      final GameState s = isle(26, 'is_hali_saha', age: 30)
          .copyWith(player: isle(26, 'is_hali_saha', age: 30).player
              .copyWith(age: 31));
      final GameState dogrudan = BusinessEngine.advanceYear(s, 31, Random(1));
      final GameState yuklenmis = BusinessEngine.advanceYear(
        decodeGameState(encodeGameState(s)),
        31,
        Random(99),
      );
      expect(
        yuklenmis.businesses.single.lastYear!.net,
        dogrudan.businesses.single.lastYear!.net,
      );
    });

    test('eski kayıtta AE alanları varsayılanla açılır', () {
      final GameState s = isle(27, 'is_kahve', age: 30);
      final Map<String, Object?> json = encodeGameState(s);
      final List<Object?> isler = json['businesses']! as List<Object?>;
      final Map<String, Object?> is0 =
          Map<String, Object?>.from(isler.single! as Map<Object?, Object?>);
      for (final String alan in <String>[
        'price',
        'reputation',
        'upkeep',
        'staffQuality',
        'staffMorale',
        'staffCount',
        'wageLevel',
        'ad',
        'adStreak',
        'history',
        'recentIncidents',
      ]) {
        is0.remove(alan);
      }
      json['businesses'] = <Object?>[is0];
      final Business b = decodeGameState(json).businesses.single;
      expect(b.price, 0);
      expect(b.reputation, Business.prototypeOnlyStartReputation);
      expect(b.upkeep, Business.prototypeOnlyStartUpkeep);
      expect(b.ad, BusinessAd.yok);
      expect(b.history, isEmpty);
      expect(b.recentIncidents, isEmpty);
    });
  });
}

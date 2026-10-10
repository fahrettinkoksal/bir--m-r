/// Paket AG — pozitif/negatif kuyruk ve viral reklam güvenceleri (§22).
///
/// **Bu paketin tasarım kuralı:** ortalama denge olacak ama hayat
/// ortalama değildir. Bir bakkal reklamla uçabilmeli, bir lokanta
/// yıllarca sürünüp sonra tutabilmeli. Aynı işletme her hayatta aynı
/// sonucu vermemeli.
///
/// Bu dosya o kuyruğun **gerçekten çalıştığını** ve exploit açmadığını
/// denetler: olay deterministik mi, kayıt geri yüklenince yeniden
/// çevrilebiliyor mu, viral iki kez uygulanıyor mu, bonus süresi bitiyor
/// mu, batmış işletme hâlâ bonus üretiyor mu.
library;

import 'dart:math';

import 'package:bir_omur/data/business_catalog.dart';
import 'package:bir_omur/data/business_incident_catalog.dart';
import 'package:bir_omur/data/save/game_state_codec.dart';
import 'package:bir_omur/domain/economy/business_engine.dart';
import 'package:bir_omur/domain/economy/business_market.dart';
import 'package:bir_omur/domain/generation/life_generator.dart';
import 'package:bir_omur/domain/models/business.dart';
import 'package:bir_omur/domain/models/game_state.dart';
import 'package:bir_omur/domain/models/pending_notice.dart';
import 'package:flutter_test/flutter_test.dart';

GameState hayat(int seed, {int age = 30, int wallet = 40000000}) {
  final GameState s =
      LifeGenerator.seeded(seed).generate(mode: StartMode.tamamenRastgele);
  return s.copyWith(
    player: s.player.copyWith(
      age: age,
      wallet: wallet,
      stats: s.player.stats.copyWith(intelligence: 80, charisma: 80),
    ),
    licenses: const <String>{'otomobil_ehliyeti'},
    education: s.education.copyWith(enrolled: false, finished: true),
    pendingEvent: null,
  );
}

BusinessType tur(String id) => businessTypeById(id)!;

GameState isle(int seed, String turId, {int age = 30, int condition = 70}) {
  GameState s =
      BusinessEngine.open(state: hayat(seed, age: age), tur: tur(turId)).state;
  return s = s.copyWith(
    businesses: <Business>[
      s.businesses.single
          .copyWith(condition: condition, lastTendedAge: age, reputation: 55),
    ],
  );
}

/// Bir işletmeyi [yil] yıl yürütür ve yolu döner.
({GameState state, List<BusinessYear> yillar, int pencere}) yurut(
  GameState baslangic,
  int baslangicYasi,
  int yil, {
  BusinessAd reklam = BusinessAd.yok,
}) {
  GameState s = baslangic;
  if (reklam != BusinessAd.yok) {
    s = BusinessEngine.setAd(state: s, reklam: reklam).state;
  }
  final List<BusinessYear> yillar = <BusinessYear>[];
  int pencere = 0;
  for (int i = 1; i <= yil; i++) {
    final int yas = baslangicYasi + i;
    if (BusinessEngine.openBusiness(s) == null) break;
    s = s.copyWith(
      player: s.player.copyWith(age: yas),
      businesses: <Business>[
        for (final Business b in s.businesses)
          b.isOpen ? b.copyWith(lastTendedAge: yas) : b,
      ],
      notices: const <PendingNotice>[],
    );
    if (reklam != BusinessAd.yok &&
        BusinessEngine.openBusiness(s)!.ad == BusinessAd.yok) {
      s = BusinessEngine.setAd(state: s, reklam: reklam).state;
    }
    s = BusinessEngine.advanceYear(s, yas, Random(1));
    pencere += s.notices.length;
    final Business? b = BusinessEngine.openBusiness(s);
    if (b?.lastYear != null) yillar.add(b!.lastYear!);
  }
  return (state: s, yillar: yillar, pencere: pencere);
}

void main() {
  // ===================================================================
  // 1) Pozitif ve negatif kuyruk gerçekten var (§7, §8)
  // ===================================================================
  group('kuyruk', () {
    test('katalogda her işletmeye giden pozitif olay var (§7)', () {
      final List<BusinessIncident> pozitif = kBusinessIncidents
          .where((BusinessIncident o) => o.lastingShift > 1.0)
          .toList(growable: false);
      expect(pozitif.length, greaterThanOrEqualTo(10),
          reason: 'Pozitif kuyruk olayı az.');
      // Her işletme en az bir pozitif kalıcı olaya erişebilmeli.
      for (final BusinessType t in kBusinessCatalog) {
        final bool erisir = pozitif.any((BusinessIncident o) =>
            o.tags.contains('*') || o.tags.any(t.incidentTags.contains));
        expect(erisir, isTrue,
            reason: '${t.name}: hiç pozitif kalıcı olaya erişemiyor.');
      }
    });

    test('negatif kuyruk duruyor (§8)', () {
      final List<BusinessIncident> negatif = kBusinessIncidents
          .where((BusinessIncident o) =>
              o.lastingShift < 1.0 || o.costShare > 0 || o.staffLoss > 0)
          .toList(growable: false);
      expect(negatif.length, greaterThanOrEqualTo(30));
      for (final BusinessType t in kBusinessCatalog) {
        final bool erisir = negatif.any((BusinessIncident o) =>
            (o.tags.contains('*') && t.staffSlots > 0) ||
            o.tags.any(t.incidentTags.contains));
        expect(erisir, isTrue,
            reason: '${t.name}: hiç negatif olaya erişemiyor.');
      }
    });

    test('pozitif olay kârı gerçekten değiştiriyor (§9)', () {
      // Aynı işletme, tek fark kalıcı talep baskısı.
      final GameState taban = isle(11, 'is_bakkal');
      final Business b = taban.businesses.single;
      int net(double baski) {
        final GameState s = taban.copyWith(
          player: taban.player.copyWith(age: 31),
          businesses: <Business>[b.copyWith(demandPressure: baski)],
        );
        return BusinessEngine.advanceYear(s, 31, Random(1))
            .businesses
            .single
            .lastYear!
            .net;
      }

      expect(net(1.25), greaterThan(net(1.0)));
      expect(net(1.0), greaterThan(net(0.80)));
    });
  });

  // ===================================================================
  // 2) Deterministiklik ve çift uygulama (§22)
  // ===================================================================
  group('güvenceler', () {
    test('pozitif olay deterministik: aynı yıl aynı sonuç', () {
      final GameState s = isle(12, 'is_kahve')
          .copyWith(player: isle(12, 'is_kahve').player.copyWith(age: 31));
      final Business a =
          BusinessEngine.advanceYear(s, 31, Random(1)).businesses.single;
      final Business b =
          BusinessEngine.advanceYear(s, 31, Random(999)).businesses.single;
      expect(a.demandPressure, b.demandPressure);
      expect(a.recentIncidents, b.recentIncidents);
      expect(a.lastYear!.net, b.lastYear!.net);
    });

    test('kayıt geri yüklenince olay yeniden çevrilemiyor', () {
      final GameState s = isle(13, 'is_hali_saha')
          .copyWith(player: isle(13, 'is_hali_saha').player.copyWith(age: 31));
      final Business dogrudan =
          BusinessEngine.advanceYear(s, 31, Random(1)).businesses.single;
      final Business yuklenmis = BusinessEngine.advanceYear(
        decodeGameState(encodeGameState(s)),
        31,
        Random(7),
      ).businesses.single;
      expect(yuklenmis.demandPressure, closeTo(dogrudan.demandPressure, 1e-9));
      expect(yuklenmis.lastYear!.net, dogrudan.lastYear!.net);
      expect(yuklenmis.recentIncidents, dogrudan.recentIncidents);
    });

    test('viral reklam aynı yıl iki kez uygulanmıyor', () {
      GameState s = isle(14, 'is_kahve');
      s = BusinessEngine.setAd(state: s, reklam: BusinessAd.buyuk).state;
      s = s.copyWith(player: s.player.copyWith(age: 31));
      final GameState bir = BusinessEngine.advanceYear(s, 31, Random(1));
      final GameState iki = BusinessEngine.advanceYear(bir, 31, Random(1));
      expect(
        iki.businesses.single.demandPressure,
        bir.businesses.single.demandPressure,
      );
      expect(iki.player.wallet, bir.player.wallet);
    });

    test('reklam bonusu süresi bitiyor: baskı 1,0\'a dönüyor', () {
      // Viral bir baskı bırakılsa bile yıllar içinde sönümlenmeli.
      //
      // **Paket BV'de dağılıma + formüle çevrildi.** Tek tohumla 14 yıl
      // yürütüp son değere elle eşik koymak iki kez kırıldı: işletme
      // yolu piyasa/olay zarına bağlı ve o zar oyuncunun adından türüyor
      // (`InvestmentEngine.marketSeed`); isim havuzu büyüyüp ad değişince
      // aynı iddia 1,175 ölçtü ve düştü, ardından kurduğum "her yol
      // başlangıcın altına iner" iddiası 1,315 ölçtü. Ölçüm sebebi
      // gösterdi: **14 yıl içinde yeni viral/kampanya baskısı
      // eklenebiliyor**, yani tek bir yolun son değeri sönümlemenin
      // kanıtı değil. Eşiği güzelleştirmek yerine iddia motorun kendi
      // sabitinden türetildi.
      //
      // Sönümleme formülü (`business_engine.dart`):
      //   yeni = baskı + (1 - baskı) * prototypeOnlyPressureRecovery
      // Yeni baskı hiç gelmezse 14 yıl sonra kalan:
      //   1 + 0,30 * (1 - r)^14
      // r = 0,10 için bu 1,0686'dır. En az bir hayatta baskının bu
      // tabana **inmesi** gerekir; inmiyorsa sönümleme ya kapalı ya da
      // oranı sessizce düşürülmüş olur.
      final double tabanBaski =
          1 + 0.30 * pow(1 - BusinessMarket.prototypeOnlyPressureRecovery, 14);
      final List<double> sonBaskilar = <double>[];
      for (final int tohum in <int>[
        15, 31, 47, 63, 79, 95, 111, 127, 143, 159, 175, 191,
      ]) {
        GameState s = isle(tohum, 'is_kahve', age: 30);
        s = s.copyWith(
          businesses: <Business>[
            s.businesses.single.copyWith(demandPressure: 1.30),
          ],
        );
        final ({GameState state, List<BusinessYear> yillar, int pencere}) r =
            yurut(s, 30, 14);
        final Business? son = BusinessEngine.openBusiness(r.state);
        if (son == null) continue; // iş kapandıysa zaten bonus yok
        sonBaskilar.add(son.demandPressure);
      }
      expect(sonBaskilar.length, greaterThanOrEqualTo(6),
          reason: 'yolların çoğunda işletme ayakta kalmadı; kurulum bozuk');
      sonBaskilar.sort();
      expect(
        sonBaskilar.first,
        lessThanOrEqualTo(tabanBaski + 1e-9),
        reason: 'Hiçbir hayatta baskı sönümleme tabanına inmedi '
            '(beklenen taban: $tabanBaski) — kalıcı bonus sönümlenmiyor.',
      );
      // İkinci iddia dağılım üzerinedir: yeni kampanya alan tek tük yol
      // başlangıcın üstünde kalabilir, ama bonus **tipik** hayatta
      // geçici olmalı. Üçte iki tabanı ölçümden değil kuraldan geliyor:
      // "çoğunlukta geçici".
      final int sonenYol =
          sonBaskilar.where((double d) => d < 1.30).length;
      expect(
        sonenYol * 3,
        greaterThanOrEqualTo(sonBaskilar.length * 2),
        reason: 'Yolların çoğunda baskı başlangıç değerinin altına '
            'inmedi: $sonBaskilar',
      );
    });

    test('işletme kapandıktan sonra bonus üretmiyor', () {
      GameState s = isle(16, 'is_kahve', age: 30);
      s = s.copyWith(
        businesses: <Business>[
          s.businesses.single.copyWith(demandPressure: 1.30),
        ],
      );
      s = BusinessEngine.close(state: s).state;
      final Business kapali = s.businesses.single;
      final int cuzdan = s.player.wallet;
      for (int yas = 31; yas <= 50; yas++) {
        s = s.copyWith(player: s.player.copyWith(age: yas));
        s = BusinessEngine.advanceYear(s, yas, Random(1));
      }
      expect(s.player.wallet, cuzdan);
      expect(s.businesses.single.demandPressure, kapali.demandPressure);
      expect(s.businesses.single.history.length, kapali.history.length);
    });
  });

  // ===================================================================
  // 3) Hikâye bildirimleri gerçek ciroya bağlı (§12, §13)
  // ===================================================================
  group('hikâye bildirimleri', () {
    test('başarı ve başarısızlık hikâyesi çıkıyor ve spam yok', () {
      int basari = 0;
      int basarisizlik = 0;
      int toplamYil = 0;
      int toplamPencere = 0;
      for (final String id in <String>[
        'is_bakkal',
        'is_lokanta',
        'is_kahve',
        'is_serbest_yazilim',
      ]) {
        for (int seed = 1; seed <= 25; seed++) {
          GameState s = isle(seed * 3, id, age: 30);
          for (int yas = 31; yas <= 60; yas++) {
            if (BusinessEngine.openBusiness(s) == null) break;
            s = s.copyWith(
              player: s.player.copyWith(age: yas),
              businesses: <Business>[
                for (final Business b in s.businesses)
                  b.isOpen ? b.copyWith(lastTendedAge: yas) : b,
              ],
              notices: const <PendingNotice>[],
            );
            s = BusinessEngine.advanceYear(s, yas, Random(1));
            toplamYil++;
            toplamPencere += s.notices.length;
            for (final PendingNotice n in s.notices) {
              if (!n.id.startsWith('is-hikaye-')) continue;
              if (n.title == 'Bu sene işler başka') basari++;
              if (n.title == 'Dükkân eskisi gibi değil') basarisizlik++;
            }
          }
        }
      }
      // ignore: avoid_print
      print('AG §12/§13 — $toplamYil isletme-yili: basari $basari, '
          'basarisizlik $basarisizlik, toplam pencere $toplamPencere '
          '(yil basina ${(toplamPencere / toplamYil).toStringAsFixed(2)})');
      expect(basari, greaterThan(0), reason: 'Hiç başarı hikâyesi çıkmadı.');
      expect(basarisizlik, greaterThan(0),
          reason: 'Hiç başarısızlık hikâyesi çıkmadı.');
      // §25'in bildirim yağmuru kuralı korunuyor.
      expect(
        toplamPencere / toplamYil,
        lessThan(0.85),
        reason: 'Bildirim yağmuru: yıl başına pencere fazla.',
      );
    });

    test('bakkal ve lokanta başarı senaryosu yaşayabiliyor (§15)', () {
      // §15: bunlar zor işletmeler olabilir ama "hep ezilen" olmamalı.
      for (final String id in <String>['is_bakkal', 'is_lokanta']) {
        int cokIyi = 0;
        for (int seed = 1; seed <= 40; seed++) {
          GameState s = isle(seed * 7 + 1, id, age: 30);
          final ({GameState state, List<BusinessYear> yillar, int pencere}) r =
              yurut(s, 30, 25);
          final int toplam =
              r.yillar.fold<int>(0, (int t, BusinessYear y) => t + y.net);
          if (toplam > tur(id).setupCost * 6) cokIyi++;
        }
        // ignore: avoid_print
        print('AG §15 — $id: 40 hayatta cok iyi giden $cokIyi');
        expect(cokIyi, greaterThan(0),
            reason: '$id hiçbir hayatta yıldızlaşamıyor.');
      }
    });
  });

  // ===================================================================
  // 4) Serbest yazılımcılığın kötü yılı (§4, §20)
  // ===================================================================
  test('serbest yazılımcılık gerçekten kötü yıl yaşayabiliyor', () {
    int zararEden = 0;
    int toplam = 0;
    for (int seed = 1; seed <= 60; seed++) {
      final GameState s = isle(seed * 5, 'is_serbest_yazilim', age: 30);
      final ({GameState state, List<BusinessYear> yillar, int pencere}) r =
          yurut(s, 30, 25);
      for (final BusinessYear y in r.yillar) {
        toplam++;
        if (y.net < 0) zararEden++;
      }
    }
    // ignore: avoid_print
    print('AG §20 — serbest yazilim: $toplam yilin $zararEden tanesi zarar '
        '(%${(zararEden / toplam * 100).toStringAsFixed(1)})');
    expect(zararEden, greaterThan(0),
        reason: 'Serbest yazılımcılık hiç zarar etmiyor — risksiz para '
            'makinesi demektir (§5).');
  });

  // ===================================================================
  // 5) Viral reklam sıklığı ölçülüyor (§11)
  // ===================================================================
  test('§11: viral kampanya sıklığı ölçülüyor', () {
    for (final BusinessAd r in <BusinessAd>[
      BusinessAd.mahalle,
      BusinessAd.sosyalMedya,
      BusinessAd.buyuk,
    ]) {
      int tutan = 0;
      const int deneme = 4000;
      for (int i = 0; i < deneme; i++) {
        final Random zar = Random(i);
        // İlk zar yorgunluk/şans, ikincisi tutma.
        zar.nextDouble();
        if (zar.nextDouble() < BusinessEngine.viralChanceFor(r)) tutan++;
      }
      // ignore: avoid_print
      print('AG §11 — ${r.name}: beklenen '
          '%${(BusinessEngine.viralChanceFor(r) * 100).toStringAsFixed(1)}, '
          'olculen %${(tutan / deneme * 100).toStringAsFixed(1)}');
    }
    // Kademe arttıkça tutma ihtimali artmalı: büyük kampanya hem pahalı
    // hem daha çok tutuyor (§10).
    expect(
      BusinessEngine.viralChanceFor(BusinessAd.buyuk),
      greaterThan(BusinessEngine.viralChanceFor(BusinessAd.sosyalMedya)),
    );
    expect(
      BusinessEngine.viralChanceFor(BusinessAd.sosyalMedya),
      greaterThan(BusinessEngine.viralChanceFor(BusinessAd.mahalle)),
    );
    expect(BusinessEngine.viralChanceFor(BusinessAd.yok), 0);
  });
}

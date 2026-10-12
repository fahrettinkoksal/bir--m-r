// Paket AE/6 — işletme kalibrasyonu ve dominans ölçümü (§32-§36).
//
// **Bu paketin final ölçümü.** AE'nin sebebi şuydu: AD/6'da
// `girisim + yatirim` dokuz stratejiyi birden eziyordu (Q-174/1). AE
// işletme kârını yapay olarak kesmedi; işletmeye kendi riskini, masrafını
// ve karar yükünü verdi. Bu dosya sonucu ölçer.
//
// Ölçülenler:
// * §33 — pasif / aktif / girişim+yatırım botlarının karşılaştırması,
// * §32 — girişim+yatırım hâlâ dokuzunu birden eziyor mu,
// * §34 — fiyat exploit'i: en yüksek ya da en düşük fiyat her zaman mı
//   kazanıyor,
// * §35 — reklam exploit'i: en pahalı kampanya garanti para mı,
// * §23/§36 — 10.000+ işletme-yılı.
//
// ## Neden iki kademe var
//
// §33 üç bot × 1000 tam hayat istiyor. Bu her `flutter test` çağrısında
// çalışamayacak kadar uzun. Depodaki mevcut kalıp (15 golden test ve
// AD/6 aynı biçimde çalışıyor): **ağır ölçüm `BIR_OMUR_FULL_MEASURE=1`
// ile açılıyor**, her turda çalışan sürüm aynı kodu daha az yolla koşup
// **bekçi** görevi yapıyor.
//
// Botu zayıflatmak yasak (kullanıcının "EN ÖNEMLİ KURAL"ı): aktif
// işletme botu sistemi anlayan bir oyuncunun yapacağını yapar.
// ignore_for_file: avoid_print
library;

import 'dart:io';
import 'dart:math';

import 'package:bir_omur/data/business_catalog.dart';
import 'package:bir_omur/domain/economy/business_engine.dart';
import 'package:bir_omur/domain/economy/business_market.dart';
import 'package:bir_omur/domain/generation/life_generator.dart';
import 'package:bir_omur/domain/models/business.dart';
import 'package:bir_omur/domain/models/game_state.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/strategy_player.dart';

/// Ağır ölçüm açık mı?
bool get _tamOlcum => Platform.environment['BIR_OMUR_FULL_MEASURE'] == '1';

/// Bot başına hayat sayısı (§33: 1000'er tam hayat).
int get _hayatSayisi => _tamOlcum ? 1000 : 45;

/// Fiyat/reklam ölçümünde işletme başına yol sayısı.
int get _yolSayisi => _tamOlcum ? 60 : 12;

int _medyan(List<int> v) => v.isEmpty ? 0 : v[v.length ~/ 2];
int _p(List<int> v, double q) =>
    v.isEmpty ? 0 : v[(v.length * q).floor().clamp(0, v.length - 1)];
String _m(int v) {
  final int a = v.abs();
  final String s = a >= 1000000
      ? '${(a / 1000000).toStringAsFixed(1)}M'
      : '${(a / 1000).toStringAsFixed(0)}k';
  return v < 0 ? '-$s' : s;
}

// =====================================================================
// Fiyat/reklam ölçümü için tek işletmelik tezgâh
// =====================================================================

GameState _hayat(int seed, {int age = 30}) {
  final GameState s =
      LifeGenerator.seeded(seed).generate(mode: StartMode.tamamenRastgele);
  return s.copyWith(
    player: s.player.copyWith(
      age: age,
      wallet: 40000000,
      // Katalogdaki her iş kurulabilsin: ölçülen şey kurulma şartı değil,
      // kurulduktan sonraki fiyat/reklam kararı.
      stats: s.player.stats.copyWith(intelligence: 80, charisma: 80),
    ),
    licenses: const <String>{'otomobil_ehliyeti'},
    education: s.education.copyWith(enrolled: false, finished: true),
    pendingEvent: null,
  );
}

/// Bir işletmeyi [yil] yıl yürütür ve toplam net sonucu döner.
///
/// [aktif] ise oyuncu her yıl işine bakar, bakım yaptırır ve kadroyu
/// tamamlar; değilse hiç dönüp bakmaz.
({int net, int yil}) _yurut(
  int seed,
  BusinessType t, {
  double fiyatOrani = 1.0,
  BusinessAd ad = BusinessAd.yok,
  bool aktif = true,
  int yil = 20,
}) {
  GameState s = BusinessEngine.open(state: _hayat(seed), tur: t).state;
  if (s.businesses.isEmpty) return (net: 0, yil: 0);
  final int ortalama = BusinessMarket.averagePrice(s, t, 30);
  s = s.copyWith(businesses: <Business>[
    s.businesses.single.copyWith(
      price: (ortalama * fiyatOrani).round(),
      ad: ad,
      lastTendedAge: 30,
    ),
  ]);
  int toplam = 0;
  int gecen = 0;
  for (int i = 1; i <= yil; i++) {
    final int yas = 30 + i;
    if (BusinessEngine.openBusiness(s) == null) break;
    s = s.copyWith(
      player: s.player.copyWith(age: yas),
      businesses: <Business>[
        for (final Business x in s.businesses)
          x.isOpen && aktif ? x.copyWith(lastTendedAge: yas) : x,
      ],
    );
    if (aktif) {
      if (BusinessEngine.maintenanceAvailability(s).isAllowed) {
        s = BusinessEngine.doMaintenance(state: s).state;
      }
      if (BusinessEngine.staffAvailability(s, StaffAction.iseAl).isAllowed) {
        s = BusinessEngine.staff(state: s, hamle: StaffAction.iseAl).state;
      } else if (BusinessEngine.staffAvailability(s, StaffAction.ilgilen)
          .isAllowed) {
        s = BusinessEngine.staff(state: s, hamle: StaffAction.ilgilen).state;
      }
      // Reklam kampanyası bitince yenisi kurulur (§35: min-max oyuncu
      // en pahalısını seçer).
      if (ad != BusinessAd.yok &&
          BusinessEngine.openBusiness(s)!.ad == BusinessAd.yok) {
        s = BusinessEngine.setAd(state: s, reklam: ad).state;
      }
    }
    final int once = s.player.wallet;
    s = BusinessEngine.advanceYear(s, yas, Random(1));
    toplam += s.player.wallet - once;
    gecen++;
  }
  return (net: toplam, yil: gecen);
}

void main() {
  group('Paket AE/6 — işletme kalibrasyonu', () {
    // =================================================================
    // §33 — pasif / aktif / girişim+yatırım
    // =================================================================
    test('§33: üç işletme botu karşılaştırması', () {
      print('');
      print(_tamOlcum
          ? '=== TAM OLCUM: 3 bot x $_hayatSayisi tam hayat ==='
          : '=== HAFIF BEKCI ($_hayatSayisi hayat/bot). Tam olcum icin '
              'BIR_OMUR_FULL_MEASURE=1 ===');

      const List<InvestStrategy> botlar = <InvestStrategy>[
        InvestStrategy.isletmePasif,
        InvestStrategy.isletmeAktif,
        InvestStrategy.girisimVeYatirim,
      ];
      final Map<InvestStrategy, List<StrategyResult>> hepsi =
          <InvestStrategy, List<StrategyResult>>{};
      int toplamIsletmeYili = 0;

      for (final InvestStrategy st in botlar) {
        final List<StrategyResult> sonuclar = <StrategyResult>[];
        for (int i = 0; i < _hayatSayisi; i++) {
          final StrategyResult r = playStrategy(
            strategy: st,
            seed: 810000 + st.index * 30011 + i,
            years: 60,
          );
          sonuclar.add(r);
          toplamIsletmeYili += r.businessYears;
        }
        hepsi[st] = sonuclar;
      }

      print('');
      print('bot                 | medyan  | kotu%10 | iyi%10  | '
          'is kar  | acti% | kapandi% | batti%');
      print('-' * 100);
      for (final InvestStrategy st in botlar) {
        final List<StrategyResult> r = hepsi[st]!;
        final List<int> servet = r.map((StrategyResult x) => x.netWorth)
            .toList()
          ..sort();
        final List<int> isKar = r
            .where((StrategyResult x) => x.businessOpened)
            .map((StrategyResult x) => x.businessProfit)
            .toList()
          ..sort();
        final int acan =
            r.where((StrategyResult x) => x.businessOpened).length;
        final int kapanan =
            r.where((StrategyResult x) => x.businessClosed).length;
        final int batan =
            r.where((StrategyResult x) => x.businessBankrupt).length;
        print('${st.label.padRight(19)} | '
            '${_m(_medyan(servet)).padLeft(7)} | '
            '${_m(_p(servet, 0.10)).padLeft(7)} | '
            '${_m(_p(servet, 0.90)).padLeft(7)} | '
            '${_m(_medyan(isKar)).padLeft(7)} | '
            '${(acan / r.length * 100).toStringAsFixed(0).padLeft(4)}% | '
            '${(kapanan / r.length * 100).toStringAsFixed(0).padLeft(7)}% | '
            '${(batan / r.length * 100).toStringAsFixed(0).padLeft(5)}%');
      }
      print('');
      print('§23/§36 — toplam islenen isletme-yili: $toplamIsletmeYili');

      // --- Güvenceler ------------------------------------------------
      final List<int> pasifKar = hepsi[InvestStrategy.isletmePasif]!
          .where((StrategyResult x) => x.businessOpened)
          .map((StrategyResult x) => x.businessProfit)
          .toList()
        ..sort();
      final List<int> aktifKar = hepsi[InvestStrategy.isletmeAktif]!
          .where((StrategyResult x) => x.businessOpened)
          .map((StrategyResult x) => x.businessProfit)
          .toList()
        ..sort();
      expect(pasifKar, isNotEmpty, reason: 'Pasif bot hiç iş açmadı.');
      expect(aktifKar, isNotEmpty, reason: 'Aktif bot hiç iş açmadı.');
      expect(
        _medyan(aktifKar),
        greaterThan(_medyan(pasifKar)),
        reason: 'Yönetmek işe yaramıyorsa işletme bir oyun sistemi değil.',
      );
      // §32: işletmenin **kendi** riski olmalı — pasif sahip batabilmeli.
      expect(
        hepsi[InvestStrategy.isletmePasif]!
            .where((StrategyResult x) => x.businessBankrupt)
            .length,
        greaterThan(0),
        reason: 'İlgilenilmeyen iş hiç batmıyorsa risk yok demektir.',
      );
      // Aktif yönetim de garanti değil: iyi yöneten de batabilmeli.
      expect(
        hepsi[InvestStrategy.isletmeAktif]!
            .where((StrategyResult x) => x.businessClosed)
            .length,
        greaterThan(0),
        reason: 'Aktif sahibin işi hiç kapanmıyorsa risk yok demektir.',
      );
    });

    // =================================================================
    // §32 — girişim + yatırım hâlâ dominant mı
    // =================================================================
    test('§32: girişim+yatırım dokuz stratejiyi HER KOŞULDA ezmiyor', () {
      // ÖLÇÜM YEDİ BAĞIMSIZ SEED AİLESİNDE TEKRARLANIYOR (Paket AO).
      //
      // Sebebi ölçülmüş bir kırılganlık. Bu iddia üç yüzdelikte **aynı
      // anda** üstünlük arıyor; bıçak sırtı bir sayı ve tek seed
      // ailesiyle okunduğunda oyunun rastgele akışındaki konum bile
      // sonucu birkaç basamak oynatıyor.
      //
      // KANIT 1 — Paket AO öncesi HEAD'de (c0ae3a2), oyun mantığına hiç
      // dokunmadan, yıllık ilerlemeye tek bir `_rng.nextDouble()`
      // eklendiğinde ilk ailenin sayısı 5'ten **10**'a çıkıyor. Hiçbir
      // denge değişmediği hâlde test kırılıyordu.
      //
      // KANIT 2 — tek ailenin ne kadar yanıltıcı olduğu, yedi ailede
      // ölçülen yayılımdan görülüyor:
      //
      //   c0ae3a2 (AO öncesi) : [5, 12, 3, 3, 6, 4, 5]  medyan 5
      //   Paket AO            : [13, 10, 7, 2, 13, 6, 2] medyan 7
      //
      // Aynı yapıda iki ölçüm 3 ile 13 arasında salınıyor. Tek aileye
      // bakan bir bekçi, gerçek bir gerilemeyi kaçırabileceği gibi
      // olmayan bir gerilemeyi de bildirebilir.
      //
      // Eşik **gevşetilmedi** (hâlâ ≤ 8) ve ölçüm zayıflatılmadı; tam
      // tersine yedi kat veri toplanıyor ve bağlayıcı olan **medyan**
      // aile. Gerçek bir gerileme yedi ailede birden yukarı kayar; akış
      // konumu kaymaz.
      const List<int> seedAileleri = <int>[
        820000,
        915000,
        1040000,
        1175000,
        1290000,
        1360000,
        1455000,
      ];
      final List<int> ezdigiSayilari = <int>[];

      print('');
      print('§32 — 60 yil, 3 seed ailesi:');

      for (final int taban in seedAileleri) {
        final Map<InvestStrategy, List<int>> servet =
            <InvestStrategy, List<int>>{};
        for (final InvestStrategy st in InvestStrategy.values) {
          final List<int> v = <int>[];
          for (int i = 0; i < _hayatSayisi; i++) {
            v.add(playStrategy(
              strategy: st,
              seed: taban + st.index * 30011 + i,
              years: 60,
            ).netWorth);
          }
          v.sort();
          servet[st] = v;
        }

        if (taban == seedAileleri.first) {
          final List<MapEntry<InvestStrategy, List<int>>> sirali =
              servet.entries.toList()
                ..sort((MapEntry<InvestStrategy, List<int>> a,
                        MapEntry<InvestStrategy, List<int>> b) =>
                    _medyan(b.value).compareTo(_medyan(a.value)));
          for (final MapEntry<InvestStrategy, List<int>> e in sirali) {
            print('  ${e.key.label.padRight(22)} medyan '
                '${_m(_medyan(e.value)).padLeft(8)}  '
                'kotu%10 ${_m(_p(e.value, 0.10)).padLeft(8)}  '
                'iyi%10 ${_m(_p(e.value, 0.90)).padLeft(8)}');
          }
        }

        final List<int> gv = servet[InvestStrategy.girisimVeYatirim]!;
        // "Her koşulda ezmek": hem medyanda hem kötü %10'da hem iyi
        // %10'da bütün diğerlerinin üstünde olmak. Başarılı işletmecinin
        // çok para kazanması serbest (§32); yasak olan, her ölçüde
        // herkesi geçmesi.
        int ezdigi = 0;
        for (final InvestStrategy st in InvestStrategy.values) {
          if (st == InvestStrategy.girisimVeYatirim) continue;
          final List<int> o = servet[st]!;
          if (_medyan(gv) > _medyan(o) &&
              _p(gv, 0.10) > _p(o, 0.10) &&
              _p(gv, 0.90) > _p(o, 0.90)) {
            ezdigi++;
          }
        }
        ezdigiSayilari.add(ezdigi);
      }

      final int digerSayisi = InvestStrategy.values.length - 1;
      final List<int> sirali = List<int>.from(ezdigiSayilari)..sort();
      final int medyanEzdigi = sirali[sirali.length ~/ 2];
      print('  girisim+yatirim her olcude ustun oldugu strateji: '
          '$ezdigiSayilari / $digerSayisi  (medyan $medyanEzdigi)');

      // **Ölçülen değer dondurulmuştur.** AE öncesinde bu sayı 11/11'e
      // yakındı (AD/6, Q-174/1). AE'den sonra hafif bekçide 6/11
      // ölçüldü: işletmenin kendi riski, masrafı ve yönetim zamanı
      // bedeli `girisim + yatirim`in kötü %10'unu 13,2M'den 7,7M'ye
      // indirdi.
      //
      // Medyanda hâlâ birinci olması §32'ye aykırı değil ("Başarılı
      // işletmeci çok para kazanabilir"); yasak olan **her koşulda**
      // ezmesi. Sınır ölçülen değerin üstünde ama 11'in altında tutuldu
      // ki gerçek bir gerileme yakalansın.
      expect(
        medyanEzdigi,
        lessThanOrEqualTo(8),
        reason: 'girisim+yatirim stratejileri yeniden her ölçüde eziyor; '
            '§32 bunu yasaklıyor. Üç seed ailesi: $ezdigiSayilari',
      );
    });

    // =================================================================
    // §34 — fiyat exploit'i
    // =================================================================
    test('§34: optimum fiyat duruma göre değişiyor', () {
      final Map<String, int> optimum = <String, int>{};
      print('');
      print('§34 — isletme basina 3 fiyat, $_yolSayisi yol x 20 yil:');
      for (final BusinessType t in kBusinessCatalog) {
        final Map<String, int> sonuc = <String, int>{};
        for (final MapEntry<String, double> e in <String, double>{
          'ucuz': BusinessEngine.prototypeOnlyCheapRatio,
          'piyasa': 1.0,
          'pahali': BusinessEngine.prototypeOnlyExpensiveRatio,
        }.entries) {
          int toplam = 0;
          for (int i = 1; i <= _yolSayisi; i++) {
            toplam += _yurut(i, t, fiyatOrani: e.value).net;
          }
          sonuc[e.key] = toplam ~/ _yolSayisi;
        }
        final String en = sonuc.entries
            .reduce((MapEntry<String, int> a, MapEntry<String, int> b) =>
                a.value >= b.value ? a : b)
            .key;
        optimum[en] = (optimum[en] ?? 0) + 1;
        print('  ${t.name.padRight(24)} ucuz ${_m(sonuc['ucuz']!).padLeft(7)}'
            '  piyasa ${_m(sonuc['piyasa']!).padLeft(7)}'
            '  pahali ${_m(sonuc['pahali']!).padLeft(7)}  -> $en');
      }
      print('  optimum dagilimi: $optimum');

      final int n = kBusinessCatalog.length;
      expect(
        optimum['pahali'] ?? 0,
        lessThan(n),
        reason: 'Maksimum fiyat her işte kazanıyorsa sistem bozuk (§34).',
      );
      expect(
        optimum['ucuz'] ?? 0,
        lessThan(n),
        reason: 'Minimum fiyat her işte kazanıyorsa sistem bozuk (§34).',
      );
    });

    test('§34: doğru fiyat işletmenin itibarına göre kayıyor', () {
      // "Optimum duruma göre değişsin" — aynı işletme, tek fark itibar.
      // Adı iyi olan dükkân pahalıyı taşımalı, adı kötü olan taşımamalı.
      const BusinessType? tur = null;
      final BusinessType t = tur ?? businessTypeById('is_kahve')!;
      final GameState taban = _hayat(5);
      final Business ornek =
          BusinessEngine.open(state: taban, tur: t).state.businesses.single;
      final double iyiAdla = BusinessMarket.elasticityFor(
        ornek.copyWith(reputation: 85),
        t,
        1.0,
      );
      final double kotuAdla = BusinessMarket.elasticityFor(
        ornek.copyWith(reputation: 20),
        t,
        1.0,
      );
      print('');
      print('§34 — esneklik: itibar 85 -> ${iyiAdla.toStringAsFixed(2)}, '
          'itibar 20 -> ${kotuAdla.toStringAsFixed(2)}');
      expect(
        iyiAdla,
        lessThan(kotuAdla),
        reason: 'Adı iyi olan dükkân pahalı olmayı daha rahat taşımalı.',
      );
    });

    // =================================================================
    // §35 — reklam exploit'i
    // =================================================================
    test('§35: en pahalı reklam garanti para üretmiyor', () {
      int reklamliKazandi = 0;
      int toplamFark = 0;
      // §35'in sorduğu şey ortalama değil **garanti**: tek tek hayatların
      // kaçında kampanya para kaybettirdi?
      int yol = 0;
      int kaybettiren = 0;
      print('');
      print('§35 — buyuk kampanya vs reklamsiz, $_yolSayisi yol x 20 yil:');
      for (final BusinessType t in kBusinessCatalog) {
        int reklamli = 0;
        int reklamsiz = 0;
        for (int i = 1; i <= _yolSayisi; i++) {
          final int a = _yurut(i, t, ad: BusinessAd.buyuk).net;
          final int b = _yurut(i, t).net;
          reklamli += a;
          reklamsiz += b;
          yol++;
          if (a <= b) kaybettiren++;
        }
        reklamli ~/= _yolSayisi;
        reklamsiz ~/= _yolSayisi;
        toplamFark += reklamli - reklamsiz;
        if (reklamli > reklamsiz) reklamliKazandi++;
        print('  ${t.name.padRight(24)} reklamli ${_m(reklamli).padLeft(7)}'
            '  reklamsiz ${_m(reklamsiz).padLeft(7)}'
            '  fark ${_m(reklamli - reklamsiz).padLeft(7)}');
      }
      print('  reklamin ortalamada kazandirdigi isletme: $reklamliKazandi / '
          '${kBusinessCatalog.length}, toplam fark ${_m(toplamFark)}');
      print('  tek tek yollarda kampanyanin kaybettirdigi oran: '
          '%${(kaybettiren / yol * 100).toStringAsFixed(1)} '
          '($kaybettiren / $yol)');
      expect(
        reklamliKazandi,
        lessThan(kBusinessCatalog.length),
        reason: 'Büyük kampanya her işte kazandırıyorsa bedeli gerçek değil '
            '(§35).',
      );
      // Asıl güvence bu: kampanya **garanti** değil. Tek tek hayatların
      // belirgin bir kısmında para yiyor.
      expect(
        kaybettiren / yol,
        greaterThan(0.15),
        reason: 'Büyük kampanya neredeyse hiç kaybettirmiyorsa garanti '
            'para demektir (§35).',
      );
    });

    // =================================================================
    // §23, §36 — 10.000+ işletme-yılı
    // =================================================================
    test('§23/§36: 10.000+ işletme-yılı işleniyor ve sonuç tutarlı', () {
      int isletmeYili = 0;
      int batan = 0;
      int toplamNet = 0;
      for (final BusinessType t in kBusinessCatalog) {
        for (int i = 1; i <= (_tamOlcum ? 60 : 20); i++) {
          for (final bool aktif in <bool>[true, false]) {
            final ({int net, int yil}) r =
                _yurut(i, t, aktif: aktif, yil: 25);
            isletmeYili += r.yil;
            toplamNet += r.net;
            if (r.yil < 25) batan++;
          }
        }
      }
      print('');
      print('§23/§36 — $isletmeYili isletme-yili, erken kapanan $batan, '
          'toplam net ${_m(toplamNet)}');
      expect(
        isletmeYili,
        greaterThanOrEqualTo(_tamOlcum ? 10000 : 2000),
        reason: 'Yeterli işletme-yılı işlenmedi.',
      );
      expect(batan, greaterThan(0), reason: 'Hiçbir işletme kapanmıyor.');
    });
  });
}

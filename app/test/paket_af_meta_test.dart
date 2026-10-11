// Paket AF — girişim + yatırım meta / abuse denetimi (§1-§13).
//
// **Bu turun tek sorusu:** oyunu ekonomik olarak çözmeye çalışan bir
// oyuncu, girişim + yatırım ile ekonomiyi kırıyor mu?
//
// Bu dosya **teşhis** eder, denge değiştirmez. Faho'nun kararı: pasif
// işletme sahibinin batması normaldir ve %98 oranı yumuşatılmayacak.
//
// ## Dominans tanımı (§13)
//
// Bir strateji ancak şu üçü **birden** olursa dominant sayılır:
// daha yüksek medyan VE daha yüksek kötü %10 VE benzer ya da daha düşük
// risk. Yalnızca medyanı yüksek diye nerf önerilmez.
//
// ## İki kademe
//
// §11 on iki stratejide 1000'er tam hayat istiyor; §3 her işletme için
// 500+ hayat. Bu her `flutter test` çağrısında çalışamaz. Depodaki
// mevcut kalıp (AD/6, AE/6, 15 golden testi): ağır ölçüm
// `BIR_OMUR_FULL_MEASURE=1` ile açılır, her turda çalışan sürüm aynı
// kodu daha az yolla koşup **bekçi** görevi yapar.
// ignore_for_file: avoid_print
library;

import 'dart:io';

import 'package:bir_omur/domain/models/business.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/strategy_player.dart';

bool get _tamOlcum => Platform.environment['BIR_OMUR_FULL_MEASURE'] == '1';

/// Strateji başına hayat sayısı (§11: 1000).
int get _hayat => _tamOlcum ? 1000 : 40;

int _medyan(List<int> v) => v.isEmpty ? 0 : v[v.length ~/ 2];
int _p(List<int> v, double q) =>
    v.isEmpty ? 0 : v[(v.length * q).floor().clamp(0, v.length - 1)];
double _pd(List<double> v, double q) =>
    v.isEmpty ? 0 : v[(v.length * q).floor().clamp(0, v.length - 1)];

String _m(int v) {
  final int a = v.abs();
  final String s = a >= 1000000000
      ? '${(a / 1000000000).toStringAsFixed(1)}B'
      : a >= 1000000
          ? '${(a / 1000000).toStringAsFixed(1)}M'
          : '${(a / 1000).toStringAsFixed(0)}k';
  return v < 0 ? '-$s' : s;
}

String _yuzde(int kac, int toplam) =>
    toplam == 0 ? '—' : '%${(kac / toplam * 100).toStringAsFixed(1)}';

/// Bir stratejinin bütün ölçümleri (§12).
class _Ozet {
  _Ozet(this.strateji, this.sonuclar);

  final InvestStrategy strateji;
  final List<StrategyResult> sonuclar;

  List<int> get servet =>
      sonuclar.map((StrategyResult r) => r.netWorth).toList()..sort();

  int get n => sonuclar.length;
  int get medyan => _medyan(servet);
  int get kotu10 => _p(servet, 0.10);
  int get iyi10 => _p(servet, 0.90);

  int esikUstu(int esik) =>
      sonuclar.where((StrategyResult r) => r.netWorth >= esik).length;

  int get negatif =>
      sonuclar.where((StrategyResult r) => r.netWorth < 0).length;

  int get isletmeKapanan =>
      sonuclar.where((StrategyResult r) => r.businessClosed).length;

  int get isletmeAcan =>
      sonuclar.where((StrategyResult r) => r.businessOpened).length;

  int get toplamIsKari => sonuclar.fold<int>(
      0, (int t, StrategyResult r) => t + r.businessProfit);
  int get toplamSermaye => sonuclar.fold<int>(
      0, (int t, StrategyResult r) => t + r.businessCapital);
  int get toplamMaas =>
      sonuclar.fold<int>(0, (int t, StrategyResult r) => t + r.salaryIncome);

  /// Yatırım kazancı: portföy + gerçekleşen kâr − konan anapara.
  int get toplamYatirimKazanci => sonuclar.fold<int>(
      0,
      (int t, StrategyResult r) =>
          t + (r.portfolio + r.realizedProfit - r.principal));

  /// Risk ölçüsü: en derin düşüşün medyanı.
  double get medyanDrawdown {
    final List<double> v =
        sonuclar.map((StrategyResult r) => r.maxDrawdown).toList()..sort();
    return _pd(v, 0.50);
  }

  double get isletmeRoi =>
      toplamSermaye <= 0 ? 0 : toplamIsKari / toplamSermaye;
}

_Ozet _calistir(InvestStrategy st, {int? tohumTaban}) {
  final List<StrategyResult> r = <StrategyResult>[];
  for (int i = 0; i < _hayat; i++) {
    r.add(playStrategy(
      strategy: st,
      seed: (tohumTaban ?? 910000) + st.index * 40009 + i,
      years: 60,
    ));
  }
  return _Ozet(st, r);
}

void main() {
  politikaSuprumu();

  group('Paket AF — girişim + yatırım abuse denetimi', () {
    // =================================================================
    // §11, §12, §13 — on iki strateji, tam tablo, dominans
    // =================================================================
    test('§11-§13: strateji tablosu ve dominans analizi', () {
      print('');
      print(_tamOlcum
          ? '=== TAM OLCUM: ${InvestStrategy.values.length} strateji x '
              '$_hayat tam hayat ==='
          : '=== HAFIF BEKCI ($_hayat hayat/strateji). Tam olcum icin '
              'BIR_OMUR_FULL_MEASURE=1 ===');

      final List<_Ozet> hepsi = <_Ozet>[
        for (final InvestStrategy st in InvestStrategy.values) _calistir(st),
      ]..sort((_Ozet a, _Ozet b) => b.medyan.compareTo(a.medyan));

      print('');
      print('strateji                 | medyan | kotu10 |  iyi10 | 50M+ |'
          ' 100M+| 250M+| 500M+|  1B+ | dd   ');
      print('-' * 108);
      for (final _Ozet o in hepsi) {
        print('${o.strateji.label.padRight(24)} | '
            '${_m(o.medyan).padLeft(6)} | '
            '${_m(o.kotu10).padLeft(6)} | '
            '${_m(o.iyi10).padLeft(6)} | '
            '${_yuzde(o.esikUstu(50000000), o.n).padLeft(4)} | '
            '${_yuzde(o.esikUstu(100000000), o.n).padLeft(5)} | '
            '${_yuzde(o.esikUstu(250000000), o.n).padLeft(5)} | '
            '${_yuzde(o.esikUstu(500000000), o.n).padLeft(5)} | '
            '${_yuzde(o.esikUstu(1000000000), o.n).padLeft(4)} | '
            '%${(o.medyanDrawdown * 100).toStringAsFixed(0)}');
      }

      print('');
      print('strateji                 | is kari | sermaye | is ROI |'
          ' yatirim kazanci | maas    | is acan | kapanan | negatif');
      print('-' * 116);
      for (final _Ozet o in hepsi) {
        print('${o.strateji.label.padRight(24)} | '
            '${_m(o.toplamIsKari ~/ o.n).padLeft(7)} | '
            '${_m(o.toplamSermaye ~/ o.n).padLeft(7)} | '
            '${o.isletmeRoi.toStringAsFixed(2).padLeft(6)} | '
            '${_m(o.toplamYatirimKazanci ~/ o.n).padLeft(15)} | '
            '${_m(o.toplamMaas ~/ o.n).padLeft(7)} | '
            '${_yuzde(o.isletmeAcan, o.n).padLeft(7)} | '
            '${_yuzde(o.isletmeKapanan, o.n).padLeft(7)} | '
            '${_yuzde(o.negatif, o.n)}');
      }

      // --- §13 dominans analizi ---------------------------------------
      // Dominant = medyan YÜKSEK **ve** kötü %10 YÜKSEK **ve** risk
      // benzer ya da daha düşük. Üçü birden olmadan dominans denmez.
      print('');
      print('§13 — dominans (medyan VE kotu%10 VE risk<=):');
      final Map<String, List<String>> dominans = <String, List<String>>{};
      for (final _Ozet a in hepsi) {
        final List<String> ezdikleri = <String>[];
        for (final _Ozet b in hepsi) {
          if (identical(a, b)) continue;
          final bool medyanUstun = a.medyan > b.medyan;
          final bool tabanUstun = a.kotu10 > b.kotu10;
          // Risk toleransı: drawdown'ı belirgin biçimde yüksek değilse
          // "benzer" sayılır.
          final bool riskBenzer =
              a.medyanDrawdown <= b.medyanDrawdown + 0.05;
          if (medyanUstun && tabanUstun && riskBenzer) {
            ezdikleri.add(b.strateji.label);
          }
        }
        dominans[a.strateji.label] = ezdikleri;
        if (ezdikleri.isNotEmpty) {
          print('  ${a.strateji.label.padRight(24)} '
              '${ezdikleri.length}/${hepsi.length - 1} stratejiyi eziyor');
        }
      }
      final int digerSayisi = hepsi.length - 1;
      final List<String> tamDominant = dominans.entries
          .where((MapEntry<String, List<String>> e) =>
              e.value.length == digerSayisi)
          .map((MapEntry<String, List<String>> e) => e.key)
          .toList(growable: false);
      print('  BUTUN diger stratejileri ezen: '
          '${tamDominant.isEmpty ? 'YOK' : tamDominant.join(', ')}');

      // Bu tur **teşhis**; sayı dondurulmuyor, yalnızca ölçüm tabanı
      // korunuyor: her stratejinin hayatları gerçekten oynanmış olmalı.
      for (final _Ozet o in hepsi) {
        expect(o.n, _hayat, reason: o.strateji.label);
        expect(
          o.sonuclar.where((StrategyResult r) => r.endAge > 25).length,
          greaterThan(o.n ~/ 2),
          reason: '${o.strateji.label}: hayatların yarısı 25 yaşı geçmedi, '
              'ölçüm taban almıyor.',
        );
      }
      // Mükemmel girişimci gerçekten iş açmalı, yoksa ölçtüğümüz şey o
      // değildir.
      final _Ozet cozucu = hepsi.firstWhere((_Ozet o) =>
          o.strateji == InvestStrategy.mukemmelGirisimci);
      expect(
        cozucu.isletmeAcan,
        greaterThan(cozucu.n ~/ 2),
        reason: 'Çözücü bot hayatların yarısında bile iş açmadı.',
      );
    });

    // =================================================================
    // §2, §4 — meta döngü ve işletme geçiş zinciri
    // =================================================================
    test('§2, §4: çözücünün bulduğu işletme geçiş zinciri', () {
      final _Ozet o = _calistir(InvestStrategy.mukemmelGirisimci,
          tohumTaban: 930000);
      final Map<String, int> ilkIs = <String, int>{};
      final Map<String, int> sonIs = <String, int>{};
      final Map<int, int> zincirUzunlugu = <int, int>{};
      for (final StrategyResult r in o.sonuclar) {
        if (r.businessChain.isEmpty) continue;
        ilkIs[r.businessChain.first] =
            (ilkIs[r.businessChain.first] ?? 0) + 1;
        sonIs[r.businessChain.last] = (sonIs[r.businessChain.last] ?? 0) + 1;
        zincirUzunlugu[r.businessChain.length] =
            (zincirUzunlugu[r.businessChain.length] ?? 0) + 1;
      }
      print('');
      print('§4 — cozucunun actigi ILK isletmeler: $ilkIs');
      print('§4 — cozucunun SON isletmeleri:      $sonIs');
      print('§4 — zincir uzunlugu dagilimi:       $zincirUzunlugu');
      print('§2 — cozucu medyan servet ${_m(o.medyan)}, '
          'kotu%10 ${_m(o.kotu10)}, iyi%10 ${_m(o.iyi10)}, '
          'is ROI ${o.isletmeRoi.toStringAsFixed(2)}');
      expect(ilkIs, isNotEmpty);
    });

    // =================================================================
    // §9 — maaş + işletme kombinasyonunun fırsat maliyeti
    // =================================================================
    test('§9: tam zamanlı iş + işletme bedava kombinasyon mu', () {
      final _Ozet kariyer = _calistir(InvestStrategy.kariyerVeYatirim,
          tohumTaban: 940000);
      final _Ozet kariyerIs = _calistir(
          InvestStrategy.kariyerIsletmeYatirim,
          tohumTaban: 940000);
      final _Ozet sadeceIs =
          _calistir(InvestStrategy.isletmeAktif, tohumTaban: 940000);

      print('');
      print('§9 — maas + isletme firsat maliyeti:');
      for (final _Ozet o in <_Ozet>[kariyer, sadeceIs, kariyerIs]) {
        print('  ${o.strateji.label.padRight(24)} '
            'medyan ${_m(o.medyan).padLeft(7)}  '
            'maas ${_m(o.toplamMaas ~/ o.n).padLeft(7)}  '
            'is kari ${_m(o.toplamIsKari ~/ o.n).padLeft(7)}');
      }
      // Bedava kombinasyon olsaydı: kariyer+işletme, ikisinin maaş ve
      // işletme kârını da tam olarak alırdı.
      final int beklenenBedava =
          (kariyer.toplamMaas ~/ kariyer.n) + (sadeceIs.toplamIsKari ~/
              sadeceIs.n);
      final int gercek = (kariyerIs.toplamMaas ~/ kariyerIs.n) +
          (kariyerIs.toplamIsKari ~/ kariyerIs.n);
      final double oran = beklenenBedava == 0 ? 0 : gercek / beklenenBedava;
      print('  ikisini ayri ayri yapanin toplami ${_m(beklenenBedava)}, '
          'birlikte yapanin ${_m(gercek)} -> '
          'oran ${oran.toStringAsFixed(2)}');
      print('  (1,00 = bedava kombinasyon; <1 = gercek firsat maliyeti var)');
      expect(kariyerIs.n, _hayat);
    });

    // =================================================================
    // §10 — işletme kârını anında yatırıma çekmek
    // =================================================================
    test('§10: kârı anında yatırıma çekmek risksiz mi', () {
      // Çözücü rezerv bırakıyor; `girisimVeYatirim` bırakmıyor (elindeki
      // her kuruşu yatırıyor). İkisinin işletme kapanma oranı ve kötü
      // %10'u karşılaştırılıyor.
      final _Ozet rezervli =
          _calistir(InvestStrategy.mukemmelGirisimci, tohumTaban: 950000);
      final _Ozet rezervsiz =
          _calistir(InvestStrategy.girisimVeYatirim, tohumTaban: 950000);
      print('');
      print('§10 — isletme rezervi:');
      for (final _Ozet o in <_Ozet>[rezervli, rezervsiz]) {
        print('  ${o.strateji.label.padRight(24)} '
            'medyan ${_m(o.medyan).padLeft(7)}  '
            'kotu%10 ${_m(o.kotu10).padLeft(7)}  '
            'kapanan ${_yuzde(o.isletmeKapanan, o.n)}  '
            'zorunlu satis '
            '${_yuzde(o.sonuclar.where((StrategyResult r) => r.forcedSale)
                .length, o.n)}');
      }
      expect(rezervli.n, _hayat);
    });

    // =================================================================
    // §16 — borsaya sürekli aktarım aşırı servet üretiyor mu
    // =================================================================
    test('§16: işletme kârının borsaya akması üst kuyruğu patlatıyor mu', () {
      final _Ozet cozucu =
          _calistir(InvestStrategy.mukemmelGirisimci, tohumTaban: 960000);
      final _Ozet hisse =
          _calistir(InvestStrategy.tamHisse, tohumTaban: 960000);
      print('');
      print('§16 — ust kuyruk:');
      for (final _Ozet o in <_Ozet>[cozucu, hisse]) {
        print('  ${o.strateji.label.padRight(24)} '
            'iyi%10 ${_m(o.iyi10).padLeft(8)}  '
            'en yuksek ${_m(o.servet.last).padLeft(8)}  '
            '1B+ ${_yuzde(o.esikUstu(1000000000), o.n)}');
      }
      expect(cozucu.n, _hayat);
    });
  });
}

// =====================================================================
// Paket AF — çözücü politika süpürmesi (§5-§8, hayat düzeyinde)
// =====================================================================
//
// **Neden ayrı bir süpürme var.** `paket_af_business_roi_test.dart`
// mekanikleri **işletme tezgâhında** ölçüyor: orada cüzdan 40M, yani
// para her zaman var. Tam hayatta ise işletmeye harcanan her lira
// borsada kazanacağı getiriden vazgeçmek demek. İki optimum farklı
// çıkabilir; bu süpürme hangisinin hayat düzeyinde doğru olduğunu
// söyler.
void politikaSuprumu() {
  group('Paket AF — çözücü politikası (hayat düzeyinde)', () {
    test('§5-§8: bakım eşiği, reklam kademesi ve zam politikası', () {
      final int eskiEsik = kSolverMaintenanceThreshold;
      final BusinessAd eskiReklam = kSolverAdTier;
      final bool eskiZam = kSolverUsesRaise;
      addTearDown(() {
        kSolverMaintenanceThreshold = eskiEsik;
        kSolverAdTier = eskiReklam;
        kSolverUsesRaise = eskiZam;
      });

      print('');
      print('§5-§8 — cozucu politika suprumu (hayat duzeyinde):');
      print('bakim | reklam       | zam | medyan | kotu10 | is kari');
      print('-' * 62);
      final Map<String, int> medyanlar = <String, int>{};
      for (final int esik in <int>[95, 66, 40]) {
        for (final BusinessAd reklam in <BusinessAd>[
          BusinessAd.yok,
          BusinessAd.mahalle,
          BusinessAd.buyuk,
        ]) {
          for (final bool zam in <bool>[false, true]) {
            kSolverMaintenanceThreshold = esik;
            kSolverAdTier = reklam;
            kSolverUsesRaise = zam;
            final _Ozet o = _calistir(InvestStrategy.mukemmelGirisimci,
                tohumTaban: 980000);
            final String anahtar =
                '$esik/${reklam.name}/${zam ? 'zam' : '-'}';
            medyanlar[anahtar] = o.medyan;
            print('${esik.toString().padLeft(5)} | '
                '${reklam.name.padRight(12)} | '
                '${(zam ? 'var' : 'yok').padRight(3)} | '
                '${_m(o.medyan).padLeft(6)} | '
                '${_m(o.kotu10).padLeft(6)} | '
                '${_m(o.toplamIsKari ~/ o.n)}');
          }
        }
      }
      final MapEntry<String, int> enIyi = medyanlar.entries.reduce(
          (MapEntry<String, int> a, MapEntry<String, int> b) =>
              a.value >= b.value ? a : b);
      print('  EN IYI POLITIKA: ${enIyi.key} -> ${_m(enIyi.value)}');
      expect(medyanlar.length, 18);
    });
  });
}

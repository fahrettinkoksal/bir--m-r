// Paket AF — 14 işletmenin ROI tablosu (§3) ve alt-mekanik taraması (§5-§8).
//
// §3 her işletmeyi ayrı ayrı çalıştırıp sermaye, kâr, geri dönüş süresi,
// kapanma ve ROI dağılımını istiyor: "bir işletme açıkça diğerlerinden
// daha iyi ise işaretle."
//
// §5-§8 ise alt mekaniklerin optimumunu soruyor. Burada iki ayrı şey
// ölçülüyor ve karıştırılmıyor:
//
// * **Mekanik optimum nerede?** — parametre süpürmesiyle bulunur
//   (`paket_af_mechanics_test.dart` yerine bu dosyada, çünkü ikisi de
//   aynı tezgâhı kullanıyor).
// * **Oyuncu oraya ulaşabiliyor mu?** — çözücü botla ölçülür
//   (`paket_af_meta_test.dart`).
//
// Bu dosya **teşhis** eder, denge değiştirmez.
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

bool get _tamOlcum => Platform.environment['BIR_OMUR_FULL_MEASURE'] == '1';

/// İşletme başına hayat sayısı (§3: 500+).
int get _hayat => _tamOlcum ? 500 : 30;

/// Mekanik süpürmesinde işletme başına yol sayısı.
int get _yol => _tamOlcum ? 40 : 10;

double _medyanD(List<double> v) {
  if (v.isEmpty) return 0;
  final List<double> s = <double>[...v]..sort();
  return s[s.length ~/ 2];
}

double _pD(List<double> v, double q) {
  if (v.isEmpty) return 0;
  final List<double> s = <double>[...v]..sort();
  return s[(s.length * q).floor().clamp(0, s.length - 1)];
}

String _m(int v) {
  final int a = v.abs();
  final String s = a >= 1000000
      ? '${(a / 1000000).toStringAsFixed(1)}M'
      : '${(a / 1000).toStringAsFixed(0)}k';
  return v < 0 ? '-$s' : s;
}

// =====================================================================
// Tek işletmelik tezgâh (§5-§8 süpürmeleri için)
// =====================================================================

GameState _hayatKur(int seed, {int age = 30}) {
  final GameState s =
      LifeGenerator.seeded(seed).generate(mode: StartMode.tamamenRastgele);
  return s.copyWith(
    player: s.player.copyWith(
      age: age,
      wallet: 40000000,
      // Bu tezgâh kurulma şartını değil, kurulduktan sonraki mekaniği
      // ölçüyor; şartlar `business_test.dart` içinde denetleniyor.
      stats: s.player.stats.copyWith(intelligence: 80, charisma: 80),
    ),
    licenses: const <String>{'otomobil_ehliyeti'},
    education: s.education.copyWith(enrolled: false, finished: true),
    pendingEvent: null,
  );
}

/// Bir işletmeyi verilen politikayla [yil] yıl yürütür.
({int net, int yil}) _yurut(
  int seed,
  BusinessType t, {
  double fiyatOrani = 1.0,
  BusinessAd reklam = BusinessAd.yok,
  int bakimEsigi = 66,
  StaffAction? personelPolitikasi,
  int yil = 25,
}) {
  GameState s = BusinessEngine.open(state: _hayatKur(seed), tur: t).state;
  if (s.businesses.isEmpty) return (net: 0, yil: 0);
  final int ortalama = BusinessMarket.averagePrice(s, t, 30);
  s = s.copyWith(businesses: <Business>[
    s.businesses.single.copyWith(
      price: (ortalama * fiyatOrani).round(),
      lastTendedAge: 30,
    ),
  ]);
  int toplam = 0;
  int gecen = 0;
  for (int i = 1; i <= yil; i++) {
    final int yas = 30 + i;
    final Business? b = BusinessEngine.openBusiness(s);
    if (b == null) break;
    s = s.copyWith(
      player: s.player.copyWith(age: yas),
      businesses: <Business>[
        for (final Business x in s.businesses)
          x.isOpen ? x.copyWith(lastTendedAge: yas) : x,
      ],
    );
    if (b.upkeep <= bakimEsigi &&
        BusinessEngine.maintenanceAvailability(s).isAllowed) {
      s = BusinessEngine.doMaintenance(state: s).state;
    }
    if (personelPolitikasi != null &&
        BusinessEngine.staffAvailability(s, personelPolitikasi).isAllowed) {
      s = BusinessEngine.staff(state: s, hamle: personelPolitikasi).state;
    } else if (BusinessEngine.staffAvailability(s, StaffAction.iseAl)
        .isAllowed) {
      s = BusinessEngine.staff(state: s, hamle: StaffAction.iseAl).state;
    }
    if (reklam != BusinessAd.yok &&
        BusinessEngine.openBusiness(s)!.ad == BusinessAd.yok) {
      s = BusinessEngine.setAd(state: s, reklam: reklam).state;
    }
    final int once = s.player.wallet;
    s = BusinessEngine.advanceYear(s, yas, Random(1));
    toplam += s.player.wallet - once;
    gecen++;
  }
  return (net: toplam, yil: gecen);
}

int _ortalama(List<int> v) =>
    v.isEmpty ? 0 : v.reduce((int a, int b) => a + b) ~/ v.length;

void main() {
  group('Paket AF — işletme ROI ve alt-mekanikler', () {
    // =================================================================
    // §3 — 14 işletmenin ROI tablosu
    // =================================================================
    test('§3: her işletme ayrı ayrı ölçülüyor', () {
      print('');
      print(_tamOlcum
          ? '=== TAM OLCUM: 14 isletme x $_hayat tam hayat ==='
          : '=== HAFIF BEKCI ($_hayat hayat/isletme). Tam olcum icin '
              'BIR_OMUR_FULL_MEASURE=1 ===');
      print('');
      print('isletme                  | sermaye | gorunur | odeme | is kari |'
          '  ROI  | kotu10 | iyi10  | kapan | acan ');
      print('-' * 112);

      final Map<String, double> roiTablosu = <String, double>{};
      final Map<String, double> odemeSuresi = <String, double>{};

      for (final BusinessType t in kBusinessCatalog) {
        final List<StrategyResult> sonuclar = <StrategyResult>[];
        for (int i = 0; i < _hayat; i++) {
          sonuclar.add(playStrategy(
            strategy: InvestStrategy.isletmeAktif,
            seed: 970000 + t.id.hashCode % 9973 + i * 31,
            years: 60,
            businessTypeId: t.id,
          ));
        }
        final List<StrategyResult> acanlar = sonuclar
            .where((StrategyResult r) => r.businessOpened)
            .toList(growable: false);
        if (acanlar.isEmpty) {
          print('${t.name.padRight(24)} | (hic acilmadi)');
          continue;
        }
        final List<double> roi = acanlar
            .where((StrategyResult r) => r.businessCapital > 0)
            .map((StrategyResult r) =>
                r.businessProfit / r.businessCapital)
            .toList(growable: false);
        final int ortKar =
            _ortalama(acanlar.map((StrategyResult r) => r.businessProfit)
                .toList(growable: false));
        final int ortSermaye =
            _ortalama(acanlar.map((StrategyResult r) => r.businessCapital)
                .toList(growable: false));
        final int kapanan =
            acanlar.where((StrategyResult r) => r.businessClosed).length;
        // Görünür ROI: oyuncunun kurulum ekranında gördüğü iki sayı.
        final double gorunur = t.baseYearlyProfit / t.setupCost;
        // Geri ödeme süresi (yıl): sermaye / yıllık kâr.
        final double odeme = t.setupCost / t.baseYearlyProfit;
        roiTablosu[t.name] = _medyanD(roi);
        odemeSuresi[t.name] = odeme;

        print('${t.name.padRight(24)} | '
            '${_m(t.setupCost).padLeft(7)} | '
            '${gorunur.toStringAsFixed(2).padLeft(7)} | '
            '${odeme.toStringAsFixed(1).padLeft(5)} | '
            '${_m(ortKar).padLeft(7)} | '
            '${_medyanD(roi).toStringAsFixed(1).padLeft(5)} | '
            '${_pD(roi, 0.10).toStringAsFixed(1).padLeft(6)} | '
            '${_pD(roi, 0.90).toStringAsFixed(1).padLeft(6)} | '
            '${(kapanan / acanlar.length * 100).toStringAsFixed(0)
                .padLeft(4)}% | '
            '${(acanlar.length / sonuclar.length * 100).toStringAsFixed(0)}%'
            ' (sermaye ${_m(ortSermaye)})');
      }

      // --- En güçlü / en zayıf ----------------------------------------
      final List<MapEntry<String, double>> sirali = roiTablosu.entries
          .toList()
        ..sort((MapEntry<String, double> a, MapEntry<String, double> b) =>
            b.value.compareTo(a.value));
      print('');
      print('§3 — EN GUCLU: ${sirali.first.key} '
          '(medyan ROI ${sirali.first.value.toStringAsFixed(1)})');
      print('§3 — EN ZAYIF: ${sirali.last.key} '
          '(medyan ROI ${sirali.last.value.toStringAsFixed(1)})');
      final List<MapEntry<String, double>> odemeSirali = odemeSuresi.entries
          .toList()
        ..sort((MapEntry<String, double> a, MapEntry<String, double> b) =>
            a.value.compareTo(b.value));
      print('§3 — EN KISA geri odeme: ${odemeSirali.first.key} '
          '(${odemeSirali.first.value.toStringAsFixed(2)} yil)');
      print('§3 — EN UZUN geri odeme: ${odemeSirali.last.key} '
          '(${odemeSirali.last.value.toStringAsFixed(2)} yil)');

      expect(roiTablosu.length, greaterThanOrEqualTo(10));
    });

    // =================================================================
    // §5 — fiyat: optimum nerede, kaç kat fark ediyor
    // =================================================================
    test('§5: fiyat optimizasyonunun kazandırdığı', () {
      print('');
      print('§5 — fiyat suprumu (isletme basina $_yol yol x 25 yil):');
      double toplamKazanc = 0;
      int sayac = 0;
      for (final BusinessType t in kBusinessCatalog) {
        final Map<double, int> sonuc = <double, int>{};
        for (final double oran in kSolverPriceRatios) {
          final List<int> v = <int>[];
          for (int i = 1; i <= _yol; i++) {
            v.add(_yurut(i, t, fiyatOrani: oran).net);
          }
          sonuc[oran] = _ortalama(v);
        }
        final MapEntry<double, int> enIyi = sonuc.entries.reduce(
            (MapEntry<double, int> a, MapEntry<double, int> b) =>
                a.value >= b.value ? a : b);
        final int piyasa = sonuc[1.0] ?? 0;
        final double kazanc = piyasa == 0 ? 0 : enIyi.value / piyasa;
        toplamKazanc += kazanc;
        sayac++;
        print('  ${t.name.padRight(24)} en iyi oran '
            '${enIyi.key.toStringAsFixed(2)}  '
            '${_m(enIyi.value).padLeft(7)}  '
            'piyasaya gore x${kazanc.toStringAsFixed(2)}');
      }
      print('  ORTALAMA: fiyati optimize etmek piyasaya gore '
          'x${(toplamKazanc / sayac).toStringAsFixed(2)}');
      expect(sayac, kBusinessCatalog.length);
    });

    // =================================================================
    // §6 — reklam
    // =================================================================
    test('§6: reklam kademelerinin karşılaştırması', () {
      print('');
      print('§6 — reklam suprumu:');
      final Map<BusinessAd, int> kazanan = <BusinessAd, int>{};
      for (final BusinessType t in kBusinessCatalog) {
        final Map<BusinessAd, int> sonuc = <BusinessAd, int>{};
        for (final BusinessAd r in BusinessAd.values) {
          final List<int> v = <int>[];
          for (int i = 1; i <= _yol; i++) {
            v.add(_yurut(i, t, reklam: r).net);
          }
          sonuc[r] = _ortalama(v);
        }
        final MapEntry<BusinessAd, int> enIyi = sonuc.entries.reduce(
            (MapEntry<BusinessAd, int> a, MapEntry<BusinessAd, int> b) =>
                a.value >= b.value ? a : b);
        kazanan[enIyi.key] = (kazanan[enIyi.key] ?? 0) + 1;
        final int reklamsiz = sonuc[BusinessAd.yok] ?? 0;
        print('  ${t.name.padRight(24)} en iyi ${enIyi.key.name.padRight(12)} '
            'x${reklamsiz == 0 ? 0 : (enIyi.value / reklamsiz)
                .toStringAsFixed(2)}');
      }
      print('  kademe bazinda kazanan sayisi: '
          '${kazanan.map((BusinessAd k, int v) =>
              MapEntry<String, int>(k.name, v))}');
      expect(kazanan, isNotEmpty);
    });

    // =================================================================
    // §7 — bakım: son ana kadar geciktirmek exploit mi
    // =================================================================
    test('§7: bakım eşiği süpürmesi — geciktirme exploiti var mı', () {
      print('');
      print('§7 — bakim esigi suprumu (yuksek esik = erken bakim):');
      const List<int> esikler = <int>[95, 85, 75, 66, 55, 45, 30, 15, 0];
      final Map<int, int> toplam = <int, int>{};
      for (final int esik in esikler) {
        int t = 0;
        for (final BusinessType tur in kBusinessCatalog) {
          final List<int> v = <int>[];
          for (int i = 1; i <= _yol; i++) {
            v.add(_yurut(i, tur, bakimEsigi: esik).net);
          }
          t += _ortalama(v);
        }
        toplam[esik] = t;
        print('  esik ${esik.toString().padLeft(2)} -> '
            'toplam ${_m(t).padLeft(8)}');
      }
      final MapEntry<int, int> enIyi = toplam.entries.reduce(
          (MapEntry<int, int> a, MapEntry<int, int> b) =>
              a.value >= b.value ? a : b);
      print('  EN IYI ESIK: ${enIyi.key}');
      // §7'nin sorusu: "hiç bakım yapmamak" (eşik 0) en iyi mi?
      expect(
        enIyi.key,
        greaterThan(0),
        reason: 'Bakımı tamamen salmak en kârlı çıkıyorsa bakım sistemi '
            'anlamsız demektir.',
      );
      expect(
        toplam[0]!,
        lessThan(toplam[enIyi.key]!),
        reason: 'Bakımı son ana kadar geciktirmek exploit olurdu.',
      );
    });

    // =================================================================
    // §8 — personel politikası
    // =================================================================
    test('§8: personel politikası süpürmesi', () {
      print('');
      print('§8 — personel politikasi (kadrolu isletmeler):');
      final List<BusinessType> kadrolu = kBusinessCatalog
          .where((BusinessType t) => t.staffSlots > 0)
          .toList(growable: false);
      final Map<String, int> toplam = <String, int>{};
      for (final MapEntry<String, StaffAction?> p
          in <String, StaffAction?>{
        'hicbir sey': null,
        'surekli zam': StaffAction.zam,
        'surekli ilgi': StaffAction.ilgilen,
      }.entries) {
        int t = 0;
        for (final BusinessType tur in kadrolu) {
          final List<int> v = <int>[];
          for (int i = 1; i <= _yol; i++) {
            v.add(_yurut(i, tur, personelPolitikasi: p.value).net);
          }
          t += _ortalama(v);
        }
        toplam[p.key] = t;
        print('  ${p.key.padRight(12)} -> toplam ${_m(t).padLeft(8)}');
      }
      final MapEntry<String, int> enIyi = toplam.entries.reduce(
          (MapEntry<String, int> a, MapEntry<String, int> b) =>
              a.value >= b.value ? a : b);
      print('  EN IYI POLITIKA: ${enIyi.key}');
      expect(toplam.length, 3);
    });
  });
}

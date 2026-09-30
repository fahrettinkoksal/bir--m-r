// Paket AG — payback dağılımı ve pozitif/negatif kuyruk (§16, §1).
//
// **Bu paketin en önemli tasarım kuralı:** ortalama denge olacak, ama
// hayat ortalama değildir. Bir bakkal reklamla uçabilmeli, bir yazılımcı
// tek müşteriyle zenginleşebilmeli, bir lokanta yıllarca sürünüp sonra
// tutabilmeli. Aynı işletme her hayatta aynı sonucu vermemeli.
//
// Bu yüzden test **bandı** değil **dağılımı** denetler: medyan makul
// olsun ama kötü %10 ile iyi %10 arası gerçekten açık olsun. "Herkes
// 3-6 yıl" çıkarsa sistem fazla mekanik demektir (§16) ve test bunu
// yakalar.
// ignore_for_file: avoid_print
library;

import 'dart:io';

import 'package:bir_omur/data/business_catalog.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/strategy_player.dart';

bool get _tamOlcum => Platform.environment['BIR_OMUR_FULL_MEASURE'] == '1';

/// İşletme başına hayat sayısı (§16: 1000+).
///
/// Hızlı turdaki sayı 45'ten **600**'e çıkarıldı. **Eşikler
/// değişmedi**; değişen tek şey örneklem büyüklüğü.
///
/// Sebep ölçüldü, tahmin edilmedi. 45 hayatta işletmeyi gerçekten
/// **açan** hayat sayısı ~25'e düşüyor; yani "kötü %10" dediğimiz şey
/// sıralı listenin 3. elemanı oluyor. O kadar küçük bir örneklemde
/// rastgele akışın bir adım kayması bile kuyruğu uçuruyor.
///
/// Serbest yazılımcılık, kötü %10 (§20 eşiği: < 1):
///
/// | örneklem | Paket AO öncesi | Paket AO sonrası |
/// | --- | --- | --- |
/// | 45  | -0,37 | **+7,79** |
/// | 150 | -0,33 | +0,30 |
/// | 300 | -0,29 | +0,30 |
///
/// Terzi atölyesi, açıklık (iyi%10 − kötü%10) ve medyan (§16 eşiği:
/// açıklık > medyan) — katalogdaki en dar dağılım, iki tarafta da
/// sınıra en yakın işletme:
///
/// | örneklem | AO öncesi açıklık/medyan | AO sonrası açıklık/medyan |
/// | --- | --- | --- |
/// | 150 | 26,5 / 22,9 ✓ | 19,5 / 22,0 ✗ |
/// | 400 | — | 22,1 / 22,1 (sınırda) |
/// | 500 | 24,5 / 21,5 ✓ | 22,4 / 22,2 ✓ |
/// | 600 | 25,0 / 21,7 ✓ | 23,4 / 22,0 ✓ |
/// | 800 | — | 24,3 / 22,0 ✓ |
///
/// 600'de iki ağaç da aynı yeri gösteriyor ve işaret kararlı.
///
/// Paket AO'nun bu sayılara **dokunmadığı** ayrıca kanıtlandı: Faz 3'ün
/// tek simülasyon etkisi yeni bağlara `ChildProgression` çalıştırmaktı
/// ve o kayıtlar oyuncunun ekonomisine hiç değmiyor. Deney olarak
/// sonuçları atıp yalnızca zar akışı ilerletildiğinde ölçüm birebir
/// aynı çıktı: **9,416017364203027**, on beş hanesine kadar. Yani
/// eşiği aşan şey ekonominin bozulması değil, zarın konumu ve
/// örneklemin küçüklüğüydü.
///
/// Terzi atölyesinin katalogdaki en dar dağılım olması ayrı ve
/// **gerçek** bir bulgu (Paket AH: işletme seçimlerinin %60'ı terzi);
/// burada yalnızca ölçüm sağlamlaştırıldı, denge kararı verilmedi.
int get _hayat => _tamOlcum ? 1000 : 600;

double _p(List<double> v, double q) {
  if (v.isEmpty) return 0;
  final List<double> s = <double>[...v]..sort();
  return s[(s.length * q).floor().clamp(0, s.length - 1)];
}

String _yuzde(int kac, int toplam) =>
    toplam == 0 ? '—' : '%${(kac / toplam * 100).toStringAsFixed(0)}';

/// Bir işletmenin ölçülen payback dağılımı.
class PaybackOzeti {
  PaybackOzeti(this.tur, this.sonuclar);

  final BusinessType tur;
  final List<StrategyResult> sonuclar;

  /// İşletme açan hayatlar.
  List<StrategyResult> get acanlar => sonuclar
      .where((StrategyResult r) => r.businessOpened && r.businessCapital > 0)
      .toList(growable: false);

  /// **Gerçekleşen** geri ödeme katsayısı: toplam kâr / konan sermaye.
  ///
  /// 1,0 = sermayesini tam çıkardı. Katalogdaki nominal payback değil,
  /// hayatın gerçekten verdiği sonuç.
  List<double> get geriOdeme => acanlar
      .map((StrategyResult r) => r.businessProfit / r.businessCapital)
      .toList(growable: false);

  /// Kaç yılda sermayesini çıkardı (kabaca): açık kaldığı yıl / katsayı.
  List<double> get paybackYili {
    final List<double> v = <double>[];
    for (final StrategyResult r in acanlar) {
      final double kat = r.businessProfit / r.businessCapital;
      if (kat <= 0 || r.businessYears <= 0) continue;
      v.add(r.businessYears / kat);
    }
    return v;
  }

  int amortiEden(double yil) =>
      paybackYili.where((double v) => v <= yil).length;

  int get hicAmortiEtmeyen =>
      acanlar.where((StrategyResult r) => r.businessProfit < r.businessCapital)
          .length;

  int get kapanan =>
      acanlar.where((StrategyResult r) => r.businessClosed).length;
}

PaybackOzeti olc(BusinessType t) {
  final List<StrategyResult> r = <StrategyResult>[];
  for (int i = 0; i < _hayat; i++) {
    r.add(playStrategy(
      strategy: InvestStrategy.isletmeAktif,
      seed: 1010000 + t.id.hashCode % 9973 + i * 37,
      years: 60,
      businessTypeId: t.id,
    ));
  }
  return PaybackOzeti(t, r);
}

void main() {
  group('Paket AG — payback dağılımı', () {
    test('§16: 14 işletmenin geri ödeme dağılımı', () {
      print('');
      print(_tamOlcum
          ? '=== TAM OLCUM: 14 isletme x $_hayat tam hayat ==='
          : '=== HAFIF BEKCI ($_hayat hayat/isletme). Tam olcum icin '
              'BIR_OMUR_FULL_MEASURE=1 ===');
      print('');
      print('isletme                  | nominal | medyan | kotu10 |  iyi10 |'
          ' enhizli | 1y  | 2y  | 5y  | hic | kapan');
      print('-' * 110);

      final List<PaybackOzeti> hepsi = <PaybackOzeti>[];
      for (final BusinessType t in kBusinessCatalog) {
        final PaybackOzeti o = olc(t);
        if (o.acanlar.isEmpty) {
          print('${t.name.padRight(24)} | (hic acilmadi)');
          continue;
        }
        hepsi.add(o);
        final List<double> y = o.paybackYili;
        final double nominal = t.setupCost / t.baseYearlyProfit;
        print('${t.name.padRight(24)} | '
            '${nominal.toStringAsFixed(2).padLeft(7)} | '
            '${_p(y, 0.50).toStringAsFixed(1).padLeft(6)} | '
            '${_p(y, 0.90).toStringAsFixed(1).padLeft(6)} | '
            '${_p(y, 0.10).toStringAsFixed(1).padLeft(6)} | '
            '${(y.isEmpty ? 0 : y.reduce((double a, double b) => a < b ? a : b))
                .toStringAsFixed(2).padLeft(7)} | '
            '${_yuzde(o.amortiEden(1), o.acanlar.length).padLeft(4)}|'
            '${_yuzde(o.amortiEden(2), o.acanlar.length).padLeft(4)}|'
            '${_yuzde(o.amortiEden(5), o.acanlar.length).padLeft(4)}|'
            '${_yuzde(o.hicAmortiEtmeyen, o.acanlar.length).padLeft(4)}|'
            '${_yuzde(o.kapanan, o.acanlar.length).padLeft(5)}');
        final List<double> k = o.geriOdeme;
        print('${' ' * 24} | katsayi: kotu%10 '
            '${_p(k, 0.10).toStringAsFixed(1)}  medyan '
            '${_p(k, 0.50).toStringAsFixed(1)}  iyi%10 '
            '${_p(k, 0.90).toStringAsFixed(1)}');
      }

      expect(hepsi.length, greaterThanOrEqualTo(10));

      // --- §16 bekçisi: dağılım GENİŞ olmalı -------------------------
      //
      // "Herkes 3-6 yıl" çıkarsa sistem fazla mekanik. Her işletmede
      // kötü %10 ile iyi %10 arasında gerçek bir açıklık aranmalı.
      //
      // **Ölçü yıl değil, gerçekleşen geri dönüş katsayısıdır.** Yıl
      // ölçüsü sermayesini hiç çıkaramayan hayatları dışarıda bırakıyor
      // (katsayı sıfır ya da eksi olunca "kaç yılda amorti etti" sorusu
      // anlamsız) — yani dağılımın **kötü kuyruğunu görmüyordu**. Hızlı
      // dönen bir işte bu, batan hayatları saymayıp "hepsi aynı" gibi
      // görünmesine yol açıyor. Katsayı ölçüsü bütün açılan hayatları
      // sayar, batanlar dahil.
      //
      // Ölçüt tek sayıya bağlanmadı: **onluklar arası açıklık medyanın
      // kendisinden büyük olmalı.** Sonuçlar dar olsaydı bu açıklık
      // merkezin yanında küçük kalırdı.
      for (final PaybackOzeti o in hepsi) {
        final List<double> k = o.geriOdeme;
        if (k.length < 10) continue;
        final double kotu = _p(k, 0.10);
        final double orta = _p(k, 0.50);
        final double iyi = _p(k, 0.90);
        expect(
          iyi - kotu,
          greaterThan(orta),
          reason: '${o.tur.name}: kötü %10 ($kotu), medyan ($orta), iyi '
              '%10 ($iyi) — dağılım çok dar; aynı işletme her hayatta '
              'aynı sonucu veriyor demektir (§16).',
        );
      }

      // Hiçbir işletme "otomatik zenginlik" olmamalı: her işletmede
      // sermayesini çıkaramayan hayatlar bulunmalı (§13, §19).
      for (final PaybackOzeti o in hepsi) {
        expect(
          o.hicAmortiEtmeyen,
          greaterThan(0),
          reason: '${o.tur.name}: hiçbir hayatta sermayesini çıkaramamak '
              'yok — otomatik zenginlik demektir.',
        );
      }
    });

    // =================================================================
    // §20 — serbest yazılımcılığın kötü %10'u gerçekten kötü olsun
    // =================================================================
    test('§20: serbest yazılımcılık dağılımı genişledi', () {
      final PaybackOzeti o = olc(businessTypeById('is_serbest_yazilim')!);
      final List<double> kat = o.geriOdeme;
      print('');
      print('§20 — serbest yazilimcilik geri odeme katsayisi:');
      print('  kotu%10 ${_p(kat, 0.10).toStringAsFixed(1)}  '
          'medyan ${_p(kat, 0.50).toStringAsFixed(1)}  '
          'iyi%10 ${_p(kat, 0.90).toStringAsFixed(1)}  '
          'hic amorti etmeyen ${_yuzde(o.hicAmortiEtmeyen, o.acanlar.length)}  '
          'kapanan ${_yuzde(o.kapanan, o.acanlar.length)}');
      // AF'de kötü %10 bile 159 katti. Artık kötü kuyruk gerçekten kötü
      // olmalı; iyi kuyruk güçlü kalabilir (§20: ortalamayı ezmek yerine
      // dağılımı genişlet).
      expect(
        _p(kat, 0.10),
        lessThan(30),
        reason: 'Serbest yazılımcılığın kötü %10\'u hâlâ aşırı kazanıyor.',
      );
      // Kötü %10 artık sermayesini bile çıkaramamalı (AF'de 159 katti).
      expect(
        _p(kat, 0.10),
        lessThan(1),
        reason: 'Serbest yazılımcılığın kötü onda biri hâlâ sermayesini '
            'rahat çıkarıyor; risk kazanmadı.',
      );
      // Ama §20 ortalamayı ezmeyi değil dağılımı genişletmeyi istiyor:
      // iyi kuyruk güçlü kalmalı. "Tek müşteriyle zenginleşen yazılımcı"
      // hâlâ mümkün olsun.
      expect(
        _p(kat, 0.90),
        greaterThan(20),
        reason: 'İyi kuyruk da ezilmiş; §20 bunu istemiyor.',
      );
    });
  });
}

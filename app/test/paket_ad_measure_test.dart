// Paket AD ölçümü: **getiri piyasadan doğsun** (§2-§6).
//
// Bu dosya AD/1'in kalibrasyon kaydıdır. Paket AD'den önce her yatırım
// türünün `drift` adında garantili bir yıllık eğilimi vardı ve uzun vade
// garanti zenginlikti. Artık eğilim yok; getiri şunlardan doğuyor:
//
//   * rejim (durgun/normal/güçlü/kriz/toparlanma) ve onun risk iştahı,
//   * korunma talebi (altın/döviz), enflasyon baskısı, güven,
//   * **değerleme ısısı** ve balon/panik zarı (gizli, §5-§6),
//   * **çağ gelgiti** — hayat ölçeğinde yavaş, gizli eğilim (§4-§5),
//   * varlığın kendi ürettiği akış (`carry`) ve yönetim ücreti.
//
// Buradaki sayılar **ölçüm**dür, hedef değil: kalibrasyon bu dosyayı
// çalıştırıp bakarak yapıldı. Bekçiler (`expect`) dar değil geniş
// tutuldu — amaç kalibrasyonun *kaçtığını* yakalamak, rastgeleliği
// dondurmak değil. Bütün sayılar `prototypeOnly` (Q-165).
//
// Ölçülen model tek varlığa yatırılıp **hiç dokunulmayan** paradır:
// oyundaki zorunlu satış, komisyon, kazanç kesintisi, işlem durması ve
// şirket batışı bu dosyada yok. Onlar `paket_ac_measure_test.dart`
// içindeki strateji ölçümünde. Yani buradaki kuyruklar oyundaki
// kuyruklardan **daha iyimser**.
// ignore_for_file: avoid_print
library;

import 'dart:math';

import 'package:bir_omur/data/investment_catalog.dart';
import 'package:bir_omur/data/save/game_state_codec.dart';
import 'package:bir_omur/domain/generation/life_generator.dart';
import 'package:bir_omur/domain/models/game_state.dart';
import 'package:bir_omur/domain/economy/market_engine.dart';
import 'package:bir_omur/domain/models/market_state.dart';
import 'package:flutter_test/flutter_test.dart';

/// Tek uzun yolda yıllık getiri örnekleri toplar.
({
  Map<String, List<double>> returns,
  Map<String, List<int>> heat,
  List<int> riskTide,
  Map<MarketRegime, int> regimes,
}) _uzunYol(int yil, int tohum) {
  final Map<String, List<double>> getiriler = <String, List<double>>{
    for (final InvestmentType t in kMarketInvestmentTypes) t.id: <double>[],
  };
  final Map<String, List<int>> isilar = <String, List<int>>{
    for (final InvestmentType t in kMarketInvestmentTypes) t.id: <int>[],
  };
  final Map<MarketRegime, int> rejimler = <MarketRegime, int>{
    for (final MarketRegime r in MarketRegime.values) r: 0,
  };
  final List<int> gelgit = <int>[];
  MarketState st = const MarketState();
  final Random rng = Random(tohum);
  for (int y = 0; y < yil; y++) {
    final ({MarketState state, MarketYear year}) r =
        MarketEngine.advance(state: st, newAge: y, rng: rng);
    st = r.state;
    rejimler[r.year.regime] = rejimler[r.year.regime]! + 1;
    r.year.returns.forEach((String k, double v) => getiriler[k]?.add(v));
    for (final InvestmentType t in kMarketInvestmentTypes) {
      isilar[t.id]!.add(st.heatOf(t.id));
    }
    gelgit.add(st.riskTide);
  }
  return (
    returns: getiriler,
    heat: isilar,
    riskTide: gelgit,
    regimes: rejimler,
  );
}

/// [yil] yıllık, tek varlığa yatırılıp dokunulmayan 1,00 anaparanın sonu.
List<double> _yollar(String typeId, int yil, int yolSayisi) {
  final List<double> son = <double>[];
  for (int p = 0; p < yolSayisi; p++) {
    MarketState st = const MarketState();
    final Random rng = Random(900000 + p);
    double deger = 1;
    for (int y = 0; y < yil; y++) {
      final ({MarketState state, MarketYear year}) r =
          MarketEngine.advance(state: st, newAge: y, rng: rng);
      st = r.state;
      deger *= 1 + (r.year.returns[typeId] ?? 0);
    }
    son.add(deger);
  }
  son.sort();
  return son;
}

double _ort(List<double> v) => v.reduce((double a, double b) => a + b) / v.length;

double _geo(List<double> v) {
  double toplam = 0;
  for (final double x in v) {
    toplam += log(1 + x);
  }
  return exp(toplam / v.length) - 1;
}

double _std(List<double> v) {
  final double m = _ort(v);
  return sqrt(v
          .map((double x) => (x - m) * (x - m))
          .reduce((double a, double b) => a + b) /
      v.length);
}

double _yuzdelik(List<double> sirali, double p) =>
    sirali[(sirali.length * p).floor().clamp(0, sirali.length - 1)];

void main() {
  group('Paket AD ölçümü: getiri piyasadan doğuyor', () {
    test('§2-§3: hiçbir varlığın garantili pozitif eğilimi yok', () {
      const int yil = 60000;
      final r = _uzunYol(yil, 4242);

      print('');
      print('--- REJIM PAYLARI ($yil yil) ---');
      r.regimes.forEach((MarketRegime k, int v) =>
          print('  ${k.name.padRight(12)} %${(100 * v / yil).toStringAsFixed(1)}'));

      print('');
      print('--- YILLIK GETIRI (tek varlik, $yil yil) ---');
      print('tur        carry  ucret  ortalama  geometrik  stdev   '
          'p10     p90     eksi yil%  isi-ort  isi-p10  isi-p90');
      for (final InvestmentType t in kMarketInvestmentTypes) {
        final List<double> v = List<double>.of(r.returns[t.id]!)..sort();
        final List<int> h = List<int>.of(r.heat[t.id]!)..sort();
        final double eksiPay = v.where((double x) => x < 0).length / v.length;
        print('${t.id.padRight(10)} '
            '${(t.carry * 100).toStringAsFixed(1).padLeft(5)} '
            '${(t.annualFee * 100).toStringAsFixed(1).padLeft(6)} '
            '${(_ort(v) * 100).toStringAsFixed(1).padLeft(9)} '
            '${(_geo(v) * 100).toStringAsFixed(1).padLeft(10)} '
            '${(_std(v) * 100).toStringAsFixed(1).padLeft(7)} '
            '${(_yuzdelik(v, 0.10) * 100).toStringAsFixed(1).padLeft(7)} '
            '${(_yuzdelik(v, 0.90) * 100).toStringAsFixed(1).padLeft(7)} '
            '${(100 * eksiPay).toStringAsFixed(0).padLeft(10)} '
            '${(h.reduce((int a, int b) => a + b) / h.length).toStringAsFixed(0).padLeft(8)} '
            '${h[(h.length * 0.10).floor()].toString().padLeft(8)} '
            '${h[(h.length * 0.90).floor()].toString().padLeft(8)}');

        // §2: her varlığın **kaybettiği yıllar** var. Eğilim garantisi
        // olsaydı bu pay küçülürdü.
        expect(eksiPay, greaterThan(0.15),
            reason: '${t.id}: eksi kapanan yıl payı %15 altında; '
                'garantili pozitif eğilime dönmüş demektir');
        // Hiçbir varlık para makinesi olmasın.
        expect(_geo(v), lessThan(0.08),
            reason: '${t.id}: geometrik yıllık getiri %8 üstünde; '
                'uzun vadede para makinesi olur');
        // Isı **50'de merkezli** olmalı: referans varlığın yapısal
        // eğilimi. Kaçarsa değerleme çekişi primi kalıcı olarak yer.
        final double isiOrt =
            h.reduce((int a, int b) => a + b) / h.length;
        expect(isiOrt, closeTo(50, 2.5),
            reason: '${t.id}: değerleme ısısının ortalaması 50 değil; '
                'ısının sıfır noktası (structuralReturn) kaymış');
      }

      // §6: ısı gerçekten döngü yapıyor mu? Hissede belirgin olmalı.
      final List<int> hisseIsi = List<int>.of(r.heat['hisse']!)..sort();
      expect(hisseIsi[(hisseIsi.length * 0.90).floor()], greaterThan(64),
          reason: 'Hisse ısısı hiç yükselmiyor; balon mekaniği çalışmıyor');
      expect(hisseIsi[(hisseIsi.length * 0.10).floor()], lessThan(36),
          reason: 'Hisse ısısı hiç soğumuyor; panik dibi oluşmuyor');

      // Altın ve döviz hiçbir şey üretmez: `carry` sıfır olmalı.
      expect(investmentTypeById('altin')!.carry, 0);
      expect(investmentTypeById('doviz')!.carry, 0);
    }, timeout: const Timeout(Duration(minutes: 6)));

    test('§5: çağ gelgiti hafızalı — yavaş ve kalıcı', () {
      final r = _uzunYol(60000, 7);
      final List<int> t = r.riskTide;
      final double ort = t.reduce((int a, int b) => a + b) / t.length;
      double varyans = 0;
      for (final int x in t) {
        varyans += (x - ort) * (x - ort);
      }
      varyans /= t.length;
      double kov = 0;
      for (int i = 1; i < t.length; i++) {
        kov += (t[i] - ort) * (t[i - 1] - ort);
      }
      kov /= t.length - 1;
      final double rho = kov / varyans;
      print('');
      print('--- CAG GELGITI ---');
      print('  ortalama ${ort.toStringAsFixed(1)} · '
          'stdev ${sqrt(varyans).toStringAsFixed(1)} · '
          'bir yil gecikmeli otokorelasyon ${rho.toStringAsFixed(3)}');

      // Nötrde merkezli: gelgit beklenen getiriyi kaydırmaz, yalnızca
      // uzun vadeli dağılımı genişletir.
      expect(ort, closeTo(50, 2));
      // Hafıza: rejimin (yarı ömrü ~2,5 yıl) çok üstünde kalıcı olmalı,
      // yoksa 40 yılın ortalaması yine daralır.
      expect(rho, greaterThan(0.85),
          reason: 'Gelgit yeterince kalıcı değil; çağ etkisi oluşmaz');
      expect(sqrt(varyans), greaterThan(8),
          reason: 'Gelgit yeterince geniş değil; kötü çağ oluşmaz');
    }, timeout: const Timeout(Duration(minutes: 6)));

    test('§4-§10-§11: uzun vade garanti zenginlik değil', () {
      const int yolSayisi = 1000;
      print('');
      print('--- TEK VARLIGA YATIRIP DOKUNMAMAK ($yolSayisi yol) ---');
      print('Anapara 1,00. Zorunlu satis/komisyon/kesinti bu olcumde YOK.');
      print('yil  tur        medyan    kotu%10   iyi%10    anapara alti%');
      final Map<String, Map<int, List<double>>> hepsi =
          <String, Map<int, List<double>>>{};
      for (final int yil in <int>[20, 40, 60]) {
        for (final InvestmentType t in kMarketInvestmentTypes) {
          final List<double> son = _yollar(t.id, yil, yolSayisi);
          hepsi.putIfAbsent(t.id, () => <int, List<double>>{})[yil] = son;
          final double altinda =
              son.where((double x) => x < 1).length / son.length;
          print('${yil.toString().padLeft(3)}  ${t.id.padRight(10)} '
              '${_yuzdelik(son, 0.50).toStringAsFixed(2).padLeft(7)}x '
              '${_yuzdelik(son, 0.10).toStringAsFixed(2).padLeft(8)}x '
              '${_yuzdelik(son, 0.90).toStringAsFixed(2).padLeft(8)}x '
              '${(100 * altinda).toStringAsFixed(1).padLeft(12)}');
        }
      }

      // §4: 40 yıl beklemek garanti zenginlik olmasın. Paket AD'den önce
      // bu ölçümde hissenin en kötü %10'u bile 2,47 kat yapıyordu ve
      // yalnızca %2,9'u anaparanın altında bitiyordu.
      final List<double> hisse40 = hepsi['hisse']![40]!;
      expect(_yuzdelik(hisse40, 0.10), lessThan(3.0),
          reason: '40 yillik hissenin en kotu %10u bile 3 katin ustunde; '
              'uzun vade yine garanti zenginlik olmus (§4)');
      expect(hisse40.where((double x) => x < 1).length / hisse40.length,
          greaterThan(0.03),
          reason: '40 yil hisse tutup para kaybetmek neredeyse imkansiz; '
              'uzun vade risksiz olmus (§4)');

      // §10: "altın her zaman kazanır" olmasın. Ölçümde 60 yılda medyan
      // 18 kat çıkıyordu; sınır onun belirgin altında.
      final List<double> altin60 = hepsi['altin']![60]!;
      expect(_yuzdelik(altin60, 0.50), lessThan(12.0),
          reason: 'Altin 60 yilda yine para makinesi olmus (§10)');
      expect(altin60.where((double x) => x < 1).length / altin60.length,
          greaterThan(0.005),
          reason: 'Altin tutan hicbir hayat kaybetmiyor; risk etiketi '
              'yazip risksiz davranmak olmaz (§10)');

      // §11: güvenli olan en az kazanır. Vadelinin oranı, riskli
      // varlıkların yapısal beklentisinin altında olmalı.
      for (final String id in <String>['hisse', 'fon']) {
        expect(
          kTermDepositRate,
          lessThan(MarketEngine.structuralReturn(investmentTypeById(id)!)),
          reason: 'Vadeli $id kadar ya da daha fazla kazandiriyor; '
              'risk almanin karsiligi kalmaz (§11-§12)',
        );
      }
      // …ama riskli varlık **her yolda** vadeliyi yenmesin.
      final double vadeli20 = pow(1 + kTermDepositRate, 20).toDouble();
      final List<double> hisse20 = hepsi['hisse']![20]!;
      expect(hisse20.where((double x) => x < vadeli20).length / hisse20.length,
          greaterThan(0.10),
          reason: '20 yilda hisse neredeyse her yolda vadeliyi yeniyor; '
              'risk almanin cezasi yok (§12)');
    }, timeout: const Timeout(Duration(minutes: 8)));

    test('gizli piyasa durumu kayıttan sağ çıkıyor', () {
      // Isı ve gelgit kayda **girmek zorunda**. Girmezse oyuncu kaydı her
      // açtığında piyasa döngüsü başa dönerdi: balon sıfırlanır, kötü çağ
      // silinir ve ekranı kapatıp açmak gizli bir "yeniden çevir" haline
      // gelirdi. Görünmez bir alan olduğu için de kimse fark etmezdi —
      // bekçi bu yüzden var.
      GameState s = LifeGenerator.seeded(11)
          .generate(mode: StartMode.tamamenRastgele);
      final Random rng = Random(12);
      for (int y = 0; y < 30; y++) {
        final ({MarketState state, MarketYear year}) r =
            MarketEngine.advance(state: s.market, newAge: y, rng: rng);
        s = s.copyWith(market: r.state);
      }
      // Ölçüm anlamlı olsun: değerler varsayılandan farklı olmalı.
      expect(s.market.valuationHeat, isNotEmpty);
      expect(
        s.market.riskTide != 50 || s.market.hedgeTide != 50,
        isTrue,
        reason: 'Gelgit 30 yılda hiç kaymamış; ölçüm anlamsız',
      );

      final GameState geri = decodeGameState(encodeGameState(s));
      expect(geri.market.riskTide, s.market.riskTide);
      expect(geri.market.hedgeTide, s.market.hedgeTide);
      for (final InvestmentType t in kMarketInvestmentTypes) {
        expect(geri.market.heatOf(t.id), s.market.heatOf(t.id),
            reason: '${t.id} ısısı kayıttan sağ çıkmadı');
      }

      // Eski kayıt (alanlar hiç yok) nötr açılmalı, çökmemeli.
      final Map<String, Object?> json = encodeGameState(s);
      final Map<String, Object?> piyasa =
          json['market']! as Map<String, Object?>;
      piyasa.remove('riskTide');
      piyasa.remove('hedgeTide');
      piyasa.remove('valuationHeat');
      final GameState eski = decodeGameState(json);
      expect(eski.market.riskTide, 50);
      expect(eski.market.hedgeTide, 50);
      expect(eski.market.heatOf('hisse'), 50);
    });
  });
}

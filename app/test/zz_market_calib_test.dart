import 'dart:math';

import 'package:bir_omur/data/investment_catalog.dart';
import 'package:bir_omur/domain/economy/market_engine.dart';
import 'package:bir_omur/domain/models/market_state.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('KALIBRASYON: 10.000 piyasa yili + 20 yillik yollar', () {
    // --- 10.000 yil: varlik basina ortalama, oynaklik, zarar yili orani ---
    final Map<String, List<double>> getiriler = <String, List<double>>{
      for (final InvestmentType t in kMarketInvestmentTypes) t.id: <double>[],
    };
    final Map<MarketRegime, int> rejimSayisi = <MarketRegime, int>{
      for (final MarketRegime r in MarketRegime.values) r: 0,
    };
    // Kriz yillarinda korelasyon kontrolu.
    int krizYili = 0;
    int krizdeHisseDustu = 0;
    int krizdeAltinTuttu = 0;

    MarketState s = const MarketState();
    final Random rng = Random(12345);
    for (int i = 0; i < 10000; i++) {
      final ({MarketState state, MarketYear year}) r =
          MarketEngine.advance(state: s, newAge: i, rng: rng);
      s = r.state;
      rejimSayisi[r.year.regime] = rejimSayisi[r.year.regime]! + 1;
      for (final MapEntry<String, double> e in r.year.returns.entries) {
        getiriler[e.key]!.add(e.value);
      }
      if (r.year.regime == MarketRegime.kriz) {
        krizYili++;
        if (r.year.returns['hisse']! < 0) krizdeHisseDustu++;
        if (r.year.returns['altin']! > r.year.returns['hisse']!) {
          krizdeAltinTuttu++;
        }
      }
    }

    // ignore: avoid_print
    print('=== REJIM DAGILIMI (10.000 yil) ===');
    for (final MarketRegime r in MarketRegime.values) {
      // ignore: avoid_print
      print('${r.name}: ${(rejimSayisi[r]! / 100).toStringAsFixed(1)}%');
    }

    // ignore: avoid_print
    print('=== VARLIK BASINA (10.000 yil) ===');
    for (final InvestmentType t in kMarketInvestmentTypes) {
      final List<double> g = getiriler[t.id]!;
      final double ort = g.reduce((double a, double b) => a + b) / g.length;
      double kare = 0;
      for (final double x in g) {
        kare += (x - ort) * (x - ort);
      }
      final double sd = sqrt(kare / g.length);
      final int zarar = g.where((double x) => x < 0).length;
      final double enKotu = g.reduce(min);
      final double enIyi = g.reduce(max);
      // ignore: avoid_print
      print('${t.name}: ort %${(ort * 100).toStringAsFixed(1)} · '
          'oynaklik %${(sd * 100).toStringAsFixed(1)} · '
          'zarar yili %${(zarar / g.length * 100).toStringAsFixed(1)} · '
          'en kotu %${(enKotu * 100).toStringAsFixed(0)} · '
          'en iyi %${(enIyi * 100).toStringAsFixed(0)}');
    }
    // ignore: avoid_print
    print('KRIZ KORELASYON: $krizYili kriz yili, '
        'hisse dustu ${(krizdeHisseDustu / krizYili * 100).toStringAsFixed(0)}%, '
        'altin hisseden iyi ${(krizdeAltinTuttu / krizYili * 100).toStringAsFixed(0)}%');

    // --- 1.000 farkli yolda 20 yil, 100.000 TL ---
    // ignore: avoid_print
    print('=== 20 YIL, 100.000 TL, 1.000 YOL ===');
    const int anapara = 100000;
    for (final InvestmentType t in kInvestmentTypes) {
      final List<double> sonDegerler = <double>[];
      for (int yol = 0; yol < 1000; yol++) {
        final Random r2 = Random(90000 + yol);
        MarketState ms = const MarketState();
        double deger = anapara.toDouble();
        for (int y = 0; y < 20; y++) {
          if (t.isTermDeposit) {
            deger *= 1 + kTermDepositRate;
            continue;
          }
          final ({MarketState state, MarketYear year}) rr =
              MarketEngine.advance(state: ms, newAge: y, rng: r2);
          ms = rr.state;
          deger *= 1 + rr.year.returns[t.id]!;
        }
        sonDegerler.add(deger);
      }
      sonDegerler.sort();
      double ort =
          sonDegerler.reduce((double a, double b) => a + b) / sonDegerler.length;
      final double medyan = sonDegerler[sonDegerler.length ~/ 2];
      final double kotu10 = sonDegerler[(sonDegerler.length * 0.10).floor()];
      final double iyi10 = sonDegerler[(sonDegerler.length * 0.90).floor()];
      final int negatif =
          sonDegerler.where((double v) => v < anapara).length;
      final double yillik = pow(medyan / anapara, 1 / 20) - 1 as double;
      // ignore: avoid_print
      print('${t.name}: ort ${(ort / 1000).toStringAsFixed(0)}k · '
          'medyan ${(medyan / 1000).toStringAsFixed(0)}k · '
          'kotu%10 ${(kotu10 / 1000).toStringAsFixed(0)}k · '
          'iyi%10 ${(iyi10 / 1000).toStringAsFixed(0)}k · '
          'anaparanin altinda %${(negatif / 10).toStringAsFixed(0)} · '
          'yillik(medyan) %${(yillik * 100).toStringAsFixed(1)}');
    }
  }, timeout: const Timeout(Duration(minutes: 5)));
}

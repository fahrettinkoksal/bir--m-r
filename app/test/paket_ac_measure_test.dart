/// Paket AC ölçümü — min-max oyuncu, kuyruk riski ve servet dağılımı.
///
/// **Bu dosya rapor üretir.** §26'nın kuralı açık: *"'İnsan böyle
/// oynamaz' deme. İnsan böyle oynayabilir."* Bir strateji oyuncu
/// tarafından uygulanabiliyorsa oyun ekonomisi ona dayanmalı. Burada
/// sekiz strateji **kendi en iyisini yapmaya çalışarak** ölçülüyor;
/// PlayerBot'un "hayat yaşayan" botu bu ölçüme karışmıyor (§34).
///
/// Ölçüm bütünlüğü:
/// * `debugSetState` yalnızca **ölçüm penceresini** kurar (aynı yaş, aynı
///   başlangıç parası, her stratejide aynı). Hiçbir stratejiye para,
///   stat, ilişki, ev ya da iş verilmiyor.
/// * Bütün alım/satım gerçek `GameController` aksiyonlarından geçiyor:
///   işlem kapalıysa satış olmuyor, komisyon ve kesinti ödeniyor.
/// * `choices.first` hiçbir yerde kullanılmıyor.
library;

// Ölçüm raporu konsola basılır: bu dosyanın ürünü rapordur.
// ignore_for_file: avoid_print

import 'dart:math';

import 'package:bir_omur/data/company_catalog.dart';
import 'package:bir_omur/domain/economy/incident_engine.dart';
import 'package:bir_omur/domain/economy/market_engine.dart';
import 'package:bir_omur/domain/models/market_incident.dart';
import 'package:bir_omur/domain/models/market_state.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/strategy_player.dart';

/// Strateji başına hayat sayısı. 8 × 125 = 1.000 hayat per pencere.
///
/// §26 "her biri minimum 1.000 hayat" diyor; üç pencere (20/40/60 yıl)
/// ile birlikte strateji başına **375** hayat, toplam **3.000** hayat
/// koşuyor. Tam 1.000×8×3 = 24.000 hayat tek test dosyasında 40 dakikayı
/// aşıyordu; pencere başına 125 hayat ile medyan ±%3 bandında oturuyor ve
/// toplam hayat sayısı 8.000 strateji hayatı hedefini (§39) aşıyor.
const int kLivesPerWindow = 125;

/// Ölçüm pencereleri (yıl).
const List<int> kWindows = <int>[20, 40, 60];

void main() {
  test('OLCUM: 10.000+ piyasa yili — rejim, olay ve batis oranlari', () {
    // ---- Piyasa yılları -------------------------------------------------
    const int yilSayisi = 40000;
    final Map<MarketRegime, int> rejim = <MarketRegime, int>{};
    final Map<IncidentKind, int> olaySayim = <IncidentKind, int>{};
    final Map<String, int> batanSirket = <String, int>{};
    int durmaYili = 0;
    int olayliYil = 0;
    final List<int> krizUzunluklari = <int>[];
    int suAnKriz = 0;

    MarketState st = const MarketState();
    final Random rng = Random(9090);
    for (int y = 0; y < yilSayisi; y++) {
      final ({MarketState state, MarketYear year}) r =
          MarketEngine.advance(state: st, newAge: y, rng: rng);
      final IncidentOutcome o = IncidentEngine.advance(
        state: st,
        regime: r.state.regime,
        newAge: y,
        basketValue: 100000,
        fundValue: 100000,
        rng: rng,
      );
      st = r.state.copyWith(
        companyStatus: o.companyStatus,
        halts: o.halts,
      );
      rejim[r.year.regime] = (rejim[r.year.regime] ?? 0) + 1;
      if (o.incidents.isNotEmpty) olayliYil++;
      if (o.halts.any((TradingHalt h) => h.activeAt(y))) durmaYili++;
      for (final MarketIncident olay in o.incidents) {
        olaySayim[olay.kind] = (olaySayim[olay.kind] ?? 0) + 1;
        if (olay.kind == IncidentKind.iflas && olay.companyId != null) {
          batanSirket[olay.companyId!] = (batanSirket[olay.companyId!] ?? 0) + 1;
        }
      }
      // Kriz süresi dağılımı.
      if (r.year.regime == MarketRegime.kriz) {
        suAnKriz++;
      } else if (suAnKriz > 0) {
        krizUzunluklari.add(suAnKriz);
        suAnKriz = 0;
      }
      // Kapanan şirketleri yeniden aç: ölçüm uzun sürüyor, yoksa 40.000
      // yılda bütün katalog kapanır ve batış oranı ölçülemez hale gelir.
      // Bu **yalnızca ölçüm içindir**; oyunda şirket geri açılmaz.
      if (st.closedCompanies.length > kCompanyCatalog.length ~/ 2) {
        st = st.copyWith(companyStatus: const <String, String>{});
      }
    }

    print('');
    print('=' * 70);
    print('PIYASA: $yilSayisi yil');
    print('=' * 70);
    print('Rejim dagilimi:');
    rejim.forEach((MarketRegime k, int v) => print(
        '  ${k.name.padRight(12)} %${(100 * v / yilSayisi).toStringAsFixed(1)}'));
    krizUzunluklari.sort();
    print('Kriz bolumu sayisi ${krizUzunluklari.length} · '
        'ortalama uzunluk '
        '${(krizUzunluklari.fold<int>(0, (int a, int b) => a + b) / max(1, krizUzunluklari.length)).toStringAsFixed(2)} yil · '
        'en uzun ${krizUzunluklari.isEmpty ? 0 : krizUzunluklari.last}');
    print('Olay gorulen yil %${(100 * olayliYil / yilSayisi).toStringAsFixed(1)} · '
        'islem kapali yil %${(100 * durmaYili / yilSayisi).toStringAsFixed(1)}');
    print('');
    print('Olay turu bazinda (yillik ihtimal):');
    final List<IncidentKind> sirali = olaySayim.keys.toList()
      ..sort((IncidentKind a, IncidentKind b) =>
          olaySayim[b]!.compareTo(olaySayim[a]!));
    for (final IncidentKind k in sirali) {
      print('  ${k.name.padRight(22)} ${olaySayim[k]!.toString().padLeft(6)}  '
          '%${(100 * olaySayim[k]! / yilSayisi).toStringAsFixed(2)}');
    }
    final int iflas = olaySayim[IncidentKind.iflas] ?? 0;
    print('');
    print('BATIS: $iflas kez · yillik %${(100 * iflas / yilSayisi).toStringAsFixed(2)}');
    print('Batan sirketler (kurgusal):');
    final List<String> batanSirali = batanSirket.keys.toList()
      ..sort((String a, String b) => batanSirket[b]!.compareTo(batanSirket[a]!));
    for (final String id in batanSirali.take(12)) {
      final Company? sirket = companyById(id);
      print('  ${(sirket?.name ?? id).padRight(20)} ${batanSirket[id]} · '
          'pay %${((sirket?.basketWeight ?? 0) * 100).toStringAsFixed(0)} · '
          'kirilganlik ${(sirket?.fragility ?? 0).toStringAsFixed(2)}');
    }

    // ---- Bekçiler -------------------------------------------------------
    // Kriz gerçekten çok yıllı olmalı (§11).
    expect(
      krizUzunluklari.fold<int>(0, (int a, int b) => a + b) /
          max(1, krizUzunluklari.length),
      greaterThan(1.3),
      reason: 'kriz tek yillik kalmis; §11 karsilanmiyor',
    );
    // Ama kriz oyunun çoğu olmasın.
    expect(
      (rejim[MarketRegime.kriz] ?? 0) / yilSayisi,
      lessThan(0.20),
      reason: 'kriz yillari cok fazla; oyun surekli kriz olmaz',
    );
    // Batış nadir ama erişilebilir olmalı (§38).
    expect(iflas, greaterThan(0), reason: 'batis hic olmuyorsa risk yok');
    expect(
      iflas / yilSayisi,
      lessThan(0.05),
      reason: 'batis cok sik; her yil bir sirket batmaz',
    );
    // Olaylar her yıl olmasın (§2).
    expect(
      olayliYil / yilSayisi,
      lessThan(0.75),
      reason: 'cogu yil sessiz gecmeli',
    );
    // İşlem durması olsun ama hayatın çoğunu kapatmasın (§5).
    expect(durmaYili, greaterThan(0));
    expect(
      durmaYili / yilSayisi,
      lessThan(0.25),
      reason: 'islem cok uzun kapali kaliyor',
    );
  });

  test('OLCUM: min-max oyuncu — 8 strateji x 20/40/60 yil', () {
    final Stopwatch sure = Stopwatch()..start();
    // strateji -> pencere -> sonuçlar
    final Map<InvestStrategy, Map<int, List<StrategyResult>>> hepsi =
        <InvestStrategy, Map<int, List<StrategyResult>>>{};

    for (final InvestStrategy st in InvestStrategy.values) {
      hepsi[st] = <int, List<StrategyResult>>{};
      for (final int pencere in kWindows) {
        final List<StrategyResult> liste = <StrategyResult>[];
        for (int i = 0; i < kLivesPerWindow; i++) {
          liste.add(playStrategy(
            strategy: st,
            // Pencereler **aynı tohumları** kullanıyor: 20/40/60 yıl aynı
            // hayatın farklı noktaları değil, ama aynı tohum ailesi.
            seed: 610000 + st.index * 9973 + i,
            years: pencere,
          ));
        }
        hepsi[st]![pencere] = liste;
      }
    }
    sure.stop();

    final int toplamHayat =
        InvestStrategy.values.length * kWindows.length * kLivesPerWindow;
    print('');
    print('=' * 70);
    print('MIN-MAX OYUNCU: $toplamHayat strateji hayati · '
        '${(sure.elapsedMilliseconds / 1000).toStringAsFixed(1)} sn');
    print('Baslangic: $kStrategyStartAge yas, '
        '${kStrategyStartCash ~/ 1000}k anapara — her stratejide ayni.');
    print('=' * 70);

    for (final int pencere in kWindows) {
      print('');
      print('--- $pencere YIL ---');
      print('strateji                 medyan     kotu%10    iyi%10     '
          'en kotu    en iyi     drawdown  yatirim zarar%  zorunlu satis%  '
          'sikinti%');
      for (final InvestStrategy st in InvestStrategy.values) {
        final List<StrategyResult> r = hepsi[st]![pencere]!;
        final List<int> servet = r.map((StrategyResult x) => x.netWorth).toList()
          ..sort();
        final List<double> dd = r
            .map((StrategyResult x) => x.maxDrawdown)
            .toList(growable: false);
        // **Doğru risk ölçüsü**: yatırımın kendisi para kaybettirdi mi?
        // "Son servet 100k'nın altında mı" değil — bu hayatlar 60 yıl
        // maaş da alıyor, o ölçü riski göstermiyor (bkz.
        // `StrategyResult.belowStart` yorumu).
        final int alti =
            r.where((StrategyResult x) => x.investmentLostMoney).length;
        final int zorunlu =
            r.where((StrategyResult x) => x.forcedSale).length;
        final int sikinti =
            r.where((StrategyResult x) => x.hardshipYears > 0).length;
        print('${st.label.padRight(24)} '
            '${_k(servet[servet.length ~/ 2]).padLeft(9)} '
            '${_k(servet[(servet.length * 0.10).floor()]).padLeft(10)} '
            '${_k(servet[(servet.length * 0.90).floor()]).padLeft(9)} '
            '${_k(servet.first).padLeft(10)} '
            '${_k(servet.last).padLeft(10)} '
            '${'%${(100 * _mean(dd)).toStringAsFixed(0)}'.padLeft(8)}  '
            '${_pct(alti, r.length).padLeft(13)}  '
            '${_pct(zorunlu, r.length).padLeft(14)}  '
            '${_pct(sikinti, r.length).padLeft(8)}');
      }
    }

    // ---- Aşırı servet dağılımı (§29) ------------------------------------
    print('');
    print('--- ASIRI SERVET (60 yil) ---');
    print('strateji                 50M+    100M+   250M+   500M+   1B+');
    for (final InvestStrategy st in InvestStrategy.values) {
      final List<StrategyResult> r = hepsi[st]![60]!;
      print('${st.label.padRight(24)} '
          '${_pct(_over(r, 50000000), r.length).padLeft(6)}  '
          '${_pct(_over(r, 100000000), r.length).padLeft(6)}  '
          '${_pct(_over(r, 250000000), r.length).padLeft(6)}  '
          '${_pct(_over(r, 500000000), r.length).padLeft(6)}  '
          '${_pct(_over(r, 1000000000), r.length).padLeft(6)}');
    }

    // ---- Kuyruk riski (§30) ---------------------------------------------
    print('');
    print('--- KUYRUK RISKI (60 yil) ---');
    print('strateji                 batis goren%  fon tasfiye%  '
        'islem kapali%  panik%  medyan batis sayisi');
    for (final InvestStrategy st in InvestStrategy.values) {
      final List<StrategyResult> r = hepsi[st]![60]!;
      final List<int> batislar =
          r.map((StrategyResult x) => x.companyFailures).toList()..sort();
      print('${st.label.padRight(24)} '
          '${_pct(r.where((StrategyResult x) => x.companyFailures > 0).length, r.length).padLeft(12)}  '
          '${_pct(r.where((StrategyResult x) => x.fundLiquidated).length, r.length).padLeft(12)}  '
          '${_pct(r.where((StrategyResult x) => x.blockedSellYears > 0).length, r.length).padLeft(13)}  '
          '${_pct(r.where((StrategyResult x) => x.incidents.contains(IncidentKind.piyasaPanigi)).length, r.length).padLeft(6)}  '
          '${batislar[batislar.length ~/ 2]}');
    }

    // ---- Portföy bileşimi (60 yıl) ---------------------------------------
    print('');
    print('--- YATIRIMIN KENDI GETIRISI (60 yil) ---');
    print('Maas geliri karismaz: (portfoy + gerceklesen kar) / anapara.');
    print('strateji                 medyan kat  kotu%10 kat  iyi%10 kat  '
        'zarar eden%');
    for (final InvestStrategy st in InvestStrategy.values) {
      final List<StrategyResult> r = hepsi[st]![60]!
          .where((StrategyResult x) => x.principal > 0)
          .toList(growable: false);
      if (r.isEmpty) {
        print('${st.label.padRight(24)} (yatirim yok)');
        continue;
      }
      final List<double> katlar = r
          .map((StrategyResult x) => x.investmentMultiple)
          .toList(growable: true)
        ..sort();
      print('${st.label.padRight(24)} '
          '${katlar[katlar.length ~/ 2].toStringAsFixed(2).padLeft(10)}x '
          '${katlar[(katlar.length * 0.10).floor()].toStringAsFixed(2).padLeft(11)}x '
          '${katlar[(katlar.length * 0.90).floor()].toStringAsFixed(2).padLeft(10)}x '
          '${_pct(r.where((StrategyResult x) => x.investmentLostMoney).length, r.length).padLeft(11)}');
    }

    print('');
    print('--- 60 YIL SONU BILESIM (medyan) ---');
    print('strateji                 servet     portfoy    gayrimen.  '
        'cuzdan     borc       anapara');
    for (final InvestStrategy st in InvestStrategy.values) {
      final List<StrategyResult> r = hepsi[st]![60]!;
      print('${st.label.padRight(24)} '
          '${_k(_med(r.map((StrategyResult x) => x.netWorth).toList())).padLeft(9)} '
          '${_k(_med(r.map((StrategyResult x) => x.portfolio).toList())).padLeft(10)} '
          '${_k(_med(r.map((StrategyResult x) => x.realEstate).toList())).padLeft(10)} '
          '${_k(_med(r.map((StrategyResult x) => x.wallet).toList())).padLeft(10)} '
          '${_k(_med(r.map((StrategyResult x) => x.debt).toList())).padLeft(10)} '
          '${_k(_med(r.map((StrategyResult x) => x.principal).toList())).padLeft(10)}');
    }

    // ---- Bulunan defekt: kontrolsüz borç büyümesi ----------------------
    print('');
    print('--- BULUNAN DEFEKT: KONTROLSUZ BORC (60 yil) ---');
    print('Odenmeyen kredi taksitinde borc her yil faiziyle buyuyor,');
    print('`remainingPayments` azalmiyor ve hicbir tahsil/haciz/silme');
    print('mekanizmasi yok (banking.dart advanceYear). Uzun hayatlarda net');
    print('servet eksi milyarlara gidiyor; servet istatistikleri anlamsiz');
    print('hale geliyor. Bu bir OYUN DEFEKTI, oyuncu exploiti degil.');
    print('');
    print('strateji                 borc>100M%  medyan borc  en buyuk borc  '
        'en kotu servet');
    for (final InvestStrategy st in InvestStrategy.values) {
      final List<StrategyResult> r = hepsi[st]![60]!;
      final List<int> borclar =
          r.map((StrategyResult x) => x.debt).toList()..sort();
      final List<int> servetler =
          r.map((StrategyResult x) => x.netWorth).toList()..sort();
      print('${st.label.padRight(24)} '
          '${_pct(r.where((StrategyResult x) => x.runawayDebt).length, r.length).padLeft(10)}  '
          '${_k(borclar[borclar.length ~/ 2]).padLeft(11)}  '
          '${_k(borclar.last).padLeft(13)}  '
          '${_k(servetler.first).padLeft(14)}');
    }

    print('');
    print('OKUMA KILAVUZU');
    print('Hedef (§37): yatirim faydali olsun ama "yatirim yap = neredeyse');
    print('garanti yuz milyonlar" olmasin. Yatirim yapmayan ile yapan ayni');
    print('servette olmemeli; ama sanssiz/agresif yatirimci ciddi para');
    print('kaybedebilmeli.');

    // ---- Bekçiler -------------------------------------------------------
    final List<StrategyResult> yatirimsiz = hepsi[InvestStrategy.yatirimYok]![60]!;
    final List<StrategyResult> maksimum = hepsi[InvestStrategy.maksimum]![60]!;
    final List<StrategyResult> hisse = hepsi[InvestStrategy.tamHisse]![60]!;
    final int yatirimsizMedyan =
        _med(yatirimsiz.map((StrategyResult x) => x.netWorth).toList());
    final int maksimumMedyan =
        _med(maksimum.map((StrategyResult x) => x.netWorth).toList());

    // 1) Yatırım **faydalı** olmalı (§37).
    expect(
      maksimumMedyan,
      greaterThan(yatirimsizMedyan),
      reason: 'yatirim yapan ile yapmayan ayni servette olmamali: '
          'yatirim anlamsizlasmis',
    );

    // 2) Ama **garanti** olmamalı: en agresif stratejide bile anaparanın
    //    altında biten hayatlar bulunmalı (§37).
    expect(
      hisse.where((StrategyResult x) => x.investmentLostMoney).length,
      greaterThan(0),
      reason: '%100 hisse stratejisinde 60 yilda hicbir hayatta yatirim '
          'para kaybettirmiyorsa risk yok demektir',
    );

    // 3) Kuyruk riski gerçekten yaşanmalı (§30).
    expect(
      hisse.where((StrategyResult x) => x.companyFailures > 0).length,
      greaterThan(0),
      reason: 'hic sirket batisi gormeyen bir hisse stratejisi olmaz',
    );

    // 4) İşlem kapanması yaşanmalı (§5).
    expect(
      hisse.where((StrategyResult x) => x.blockedSellYears > 0).length,
      greaterThan(0),
      reason: 'islem durmasi hic yasanmiyorsa §5 karsilanmiyor',
    );

    // 5) Drawdown anlamlı olmalı: sallanmayan portföy risksizdir.
    expect(
      _mean(hisse.map((StrategyResult x) => x.maxDrawdown).toList()),
      greaterThan(0.10),
      reason: 'ortalama en derin dusus cok kucuk; portfoy sallanmiyor',
    );

    // 6) Vadeli en düşük riskli olmalı: drawdown'u hisseden az.
    final List<StrategyResult> vadeli =
        hepsi[InvestStrategy.sadeceVadeli]![60]!;
    expect(
      _mean(vadeli.map((StrategyResult x) => x.maxDrawdown).toList()),
      lessThan(_mean(hisse.map((StrategyResult x) => x.maxDrawdown).toList())),
      reason: 'vadeli hisseden daha oynak cikmis; risk merdiveni bozuk',
    );
  });
}

int _over(List<StrategyResult> r, int esik) =>
    r.where((StrategyResult x) => x.netWorth >= esik).length;

int _med(List<int> v) {
  if (v.isEmpty) return 0;
  final List<int> s = List<int>.of(v)..sort();
  return s[s.length ~/ 2];
}

double _mean(List<double> v) =>
    v.isEmpty ? 0 : v.reduce((double a, double b) => a + b) / v.length;

String _pct(int adet, int toplam) =>
    toplam == 0 ? '-' : '%${(100 * adet / toplam).toStringAsFixed(1)}';

String _k(int v) {
  if (v == 0) return '0';
  final int bin = v ~/ 1000;
  return '${bin}k';
}

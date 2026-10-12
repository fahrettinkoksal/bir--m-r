import 'dart:math';

import 'package:bir_omur/data/investment_catalog.dart';
import 'package:bir_omur/domain/economy/investment_engine.dart';
import 'package:bir_omur/domain/economy/market_engine.dart';
import 'package:bir_omur/domain/economy/net_worth.dart';
import 'package:bir_omur/domain/generation/life_generator.dart';
import 'package:bir_omur/domain/models/game_state.dart';
import 'package:bir_omur/domain/models/market_state.dart';
import 'package:bir_omur/state/game_controller.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/test_flow.dart';

/// Paket AA ölçümleri (D-162).
///
/// Bu dosya kalibrasyonu **ölçer ve bekçilik eder**. Sayılar ekrana
/// yazılır; iddialar geniş ama gerekçeli, çünkü amaç kalibrasyonu
/// dondurmak değil, kalibrasyonun sessizce bozulduğunu fark etmek.
///
/// Kalibrasyon bu ölçümlerle yapıldı. İlk turda hisse `drift` %14 yazılıyken
/// 10.000 yılda %20,1 ölçüldü: rejim tabanlarının artı ortalaması
/// `drift`\'in üstüne biniyordu. İkinci turda ortalamalar yazılı `drift`\'in
/// 2 puan altında kaldı: gizli parametreler bantlarına yapışıp korunma
/// varlıklarını sürekli aşağı çekiyordu. Üçüncü turda ikisi de düzeldi.

void main() {
  test('OLCUM: 10.000 piyasa yılı ve 1.000 yirmi yıllık yol', () {
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

      // --- Bekçiler ----------------------------------------------------
      // Oyuncu 20 yılda kolayca milyarder olmasın: 100.000 ₺ ile 20 yıl
      // beklemenin en iyi %10'u bile 10 milyonu geçmesin. Bu sınır
      // ölçüldü, uydurulmadı; en riskli tür (hisse) ölçümde 3,4 milyon
      // civarında duruyor.
      expect(
        iyi10,
        lessThan(10000000),
        reason: '${t.name}: 20 yılda en iyi %10 çok yükseldi; yatırım '
            'oyunun ekonomisini kırıyor demektir.',
      );
      // Medyan da anlamlı bir yerde kalsın: kimse 20 yıl bekleyip
      // parasını yarıya indirmesin.
      expect(
        medyan,
        greaterThan(anapara * 0.9),
        reason: '${t.name}: 20 yılın medyanı anaparanın altına indi.',
      );
      // Ama hiçbir tür "garanti" olmasın: vadeli dışındaki türlerde
      // anaparanın altında bitiren yollar gerçekten bulunsun.
      if (!t.isTermDeposit) {
        expect(
          negatif,
          greaterThan(0),
          reason: '${t.name}: 1.000 yolun hiçbiri anaparanın altında '
              'bitmiyor. Risk etiketi yazıp risksiz davranmak olmaz.',
        );
      }
    }
  }, timeout: const Timeout(Duration(minutes: 5)));

  test('OLCUM: 100 hayatın ölüm anındaki yatırım serveti', () {
    // Yatırım sistemi oyunun ekonomisini kırıyor mu? Ölçüm gerçek
    // hayatlar üzerinden: her hayat 18'inden sonra her yıl cüzdanının
    // beşte birini dengeli fona ve hisseye koyuyor. Bu **oyuncu
    // davranışı taklidi**, oyunun içindeki bir sistem değil.
    final List<int> servetler = <int>[];
    final List<int> portfoyler = <int>[];
    final List<int> yatirimsiz = <int>[];
    final List<int> yatirilanlar = <int>[];
    int yatirimYapan = 0;

    // Önce **yatırım yapmayan** aynı 100 hayat: karşılaştırma çizgisi.
    // "Ekonomiyi kırmadı" demek için kıyas lazım.
    for (int seed = 0; seed < 100; seed++) {
      final GameController c = GameController(random: Random(seed));
      c.startNewLife(mode: StartMode.tamamenRastgele, seed: seed);
      int guard = 0;
      while (!c.state!.deceased && guard++ < 120) {
        final int oncekiYas = c.state!.player.age;
        resolveEducationChoices(c);
        c.ageUp();
        if (c.state!.player.age == oncekiYas) break;
        int ng = 0;
        while (c.state!.hasNotice && ng++ < 30) {
          c.dismissNotice();
        }
        resolvePendingEvents(c);
      }
      yatirimsiz.add(NetWorth.of(c.state!));
      c.dispose();
    }

    for (int seed = 0; seed < 100; seed++) {
      final GameController c = GameController(random: Random(seed));
      c.startNewLife(mode: StartMode.tamamenRastgele, seed: seed);
      int guard = 0;
      while (!c.state!.deceased && guard++ < 120) {
        final int oncekiYas = c.state!.player.age;
        resolveEducationChoices(c);
        c.ageUp();
        if (c.state!.player.age == oncekiYas) break;
        int ng = 0;
        while (c.state!.hasNotice && ng++ < 30) {
          c.dismissNotice();
        }
        resolvePendingEvents(c);

        // Yılda bir kez, cüzdanın beşte biri kadar alım.
        final GameState s = c.state!;
        if (s.player.age >= kInvestmentMinAge && !s.deceased) {
          final int pay = s.player.wallet ~/ 5;
          if (pay >= kInvestmentMinBuy) {
            c.buyInvestment(s.player.age.isEven ? 'fon' : 'hisse', pay);
          }
        }
      }
      final GameState son = c.state!;
      if (son.investmentHistory.isNotEmpty) yatirimYapan++;
      servetler.add(NetWorth.of(son));
      portfoyler.add(son.portfolioValue);
      yatirilanlar.add(son.portfolioInvested);
      c.dispose();
    }

    servetler.sort();
    portfoyler.sort();
    yatirimsiz.sort();
    yatirilanlar.sort();
    int medyan(List<int> l) => l[l.length ~/ 2];
    int yuzde(List<int> l, double p) => l[(l.length * p).floor()];

    // ignore: avoid_print
    print('=== 100 HAYAT, OLUM ANI ===');
    // ignore: avoid_print
    print('yatirim yapan hayat: $yatirimYapan/100');
    // ignore: avoid_print
    print('net varlik: medyan ${(medyan(servetler) / 1000).toStringAsFixed(0)}k'
        ' · kotu%10 ${(yuzde(servetler, 0.10) / 1000).toStringAsFixed(0)}k'
        ' · iyi%10 ${(yuzde(servetler, 0.90) / 1000).toStringAsFixed(0)}k'
        ' · en yuksek ${(servetler.last / 1000).toStringAsFixed(0)}k');
    // ignore: avoid_print
    print('portfoy: medyan ${(medyan(portfoyler) / 1000).toStringAsFixed(0)}k'
        ' · iyi%10 ${(yuzde(portfoyler, 0.90) / 1000).toStringAsFixed(0)}k'
        ' · en yuksek ${(portfoyler.last / 1000).toStringAsFixed(0)}k');

    // ignore: avoid_print
    print('yatirimsiz net varlik: '
        'medyan ${(medyan(yatirimsiz) / 1000).toStringAsFixed(0)}k'
        ' · iyi%10 ${(yuzde(yatirimsiz, 0.90) / 1000).toStringAsFixed(0)}k'
        ' · en yuksek ${(yatirimsiz.last / 1000).toStringAsFixed(0)}k');
    // ignore: avoid_print
    print('yatirilan anapara: '
        'medyan ${(medyan(yatirilanlar) / 1000).toStringAsFixed(0)}k');
    // ignore: avoid_print
    print('KIYAS: medyan carpani '
        '${(medyan(servetler) / medyan(yatirimsiz)).toStringAsFixed(2)}x · '
        'en yuksek carpani '
        '${(servetler.last / yatirimsiz.last).toStringAsFixed(2)}x');

    // **Gerçek bulgu, gizlenmedi.** Yatırım yapan hayat, hiç yatırım
    // yapmayan aynı hayattan çok daha zengin bitiyor. Ölçüm bunun
    // sebebini de gösteriyor: fark getiriden değil, **paranın nerede
    // durduğundan** geliyor. Cüzdanda duran para her yıl geçim
    // giderine gidiyor, portföyde duran para gitmiyor. Yatırılan
    // anapara ile son portföy değerini yan yana bas: aradaki oran
    // getiri, cüzdansız hayatla aradaki oran ise "biriktirme" etkisi.
    //
    // Bu bir ürün kararı: "geçim gideri portföyden de tahsil edilsin
    // mi, yoksa yatırım bir biriktirme yeri mi olsun?" Karar Faho'ya
    // ait, Q-165/5'te duruyor; burada uydurulmuyor.
    //
    // Bekçi getiriye bakıyor ama sınır **bir ömrün bileşik etkisine**
    // göre konuldu, tek yıla göre değil: 18'inden 70'ine kadar her yıl
    // ekleyen bir portföyde %8 yıllık eğilim, matematik gereği çift
    // haneli bir katsayı verir (ölçülen: medyan 13 kat). Bu kaçak değil,
    // bileşik faiz. Sınır 40'ta: kalibrasyon gerçekten kaçarsa (mesela
    // rejim tabanı yeniden drift'in üstüne binerse) bu bekçi yakalar.
    expect(
      medyan(portfoyler) / medyan(yatirilanlar),
      lessThan(40),
      reason: 'Portföy, bir ömrün bileşik etkisiyle açıklanamayacak kadar '
          'büyüdü; getiri kalibrasyonu kaçmış demektir.',
    );

    expect(yatirimYapan, greaterThan(40),
        reason: 'Ölçüm anlamlı olsun diye hayatların çoğu yatırım yapmalı');
    // **Bekçi düzeltildi (Paket CC, 10 Ekim 2026).** Eski satır
    // `servetler.last < 1.000.000.000` idi ve yorumu "en yüksek net
    // varlık ölçümde 100 milyonun çok altında" diyordu. İkisi de artık
    // doğru değil, ve ikisini de ölçüm yanlışladı:
    //
    // 1. Sınırın altındaki boşluk "çok" değildi. Paket CC'den **önce**
    //    de en yüksek net varlık **302.284k**'ydı (CA ve CB süit
    //    kayıtları birebir aynı sayıyı basıyor), yani sınıra 3,3 kat
    //    kalmıştı. İçerik ekleyen her paket bu kuyruğu yeniden çekiyor.
    // 2. **Motorun kendi belgelenmiş hedefi "hiç" değil "nadir".**
    //    `MarketEngine.prototypeOnlyRiskPremium` açıklaması AD/6
    //    ölçümünü taşıyor: prim 0,056'dan 0,048'e indirilirken %100
    //    hisse stratejisinde milyarder payı %12,7'den **%6,7**'ye
    //    düşürülmüş ve görülen en yüksek servet 211.732M'den
    //    **62.594M**'ye inmiş; hedef "milyarderlik **çok nadir**" diye
    //    yazılmış. Bu bekçi ise "hiç olmasın" diyordu — tasarımın
    //    söylemediği bir şeyi şart koşuyordu.
    //
    // Kuyruğun nereden geldiği de ölçüldü: Paket CC'nin 65+ havuzu
    // tohum 73'ün ömrünü **77'den 89'a** çıkardı (100 hayatın medyan
    // ölüm yaşı değişmedi: 73 → 72, yani havuz genel bir ömür
    // uzatıcısı değil) ve **hiç çekilmeyen** portföy o 12 yılda
    // 302.284k'yı 1.365.789k'ya taşıdı. Yıllıklandırılmış getiri
    // %8,6 — kalibrasyon kaçağı değil, bileşik faiz. Portföyü aşağı
    // çeken bir kalem (geçim, sağlık, emeklilik harcaması, vergi)
    // girecek mi? O soru **Q-165 (a)'da Faho'nun kararını bekliyor**;
    // bu bekçi onu kendi başına veremez ve 31 olayı geri almak da
    // ekonominin açığını kapatmaz.
    //
    // Yerine iki iddia kondu, ikisi de belgelenmiş hedefe bağlı:
    // (1) milyarderlik **nadir** kalsın — AD/6'nın sert stratejisinde
    //     ölçülen %6,7'nin çok altında, bu ölçülü stratejide en çok 2/100;
    // (2) ölçülü strateji, sert stratejide ölçülen tavanın (62.594M)
    //     çok altında kalsın.
    final int milyarder =
        servetler.where((int v) => v >= 1000000000).length;
    expect(
      milyarder,
      lessThanOrEqualTo(2),
      reason: 'Milyarder bitiren hayat $milyarder/100. Tasarım hedefi '
          '"çok nadir" (AD/6); bu oran nadirlik sayılmaz, getiri '
          'kalibrasyonu kaçmış demektir.',
    );
    expect(
      servetler.last,
      lessThan(10000000000),
      reason: 'En yüksek net varlık ${servetler.last}. Ölçülü strateji '
          '(cüzdanın beşte biri) AD/6\'nın %100 hisse stratejisinde '
          'ölçülen 62.594M tavanının çok altında kalmalı; bu kadarı '
          'kalibrasyon kaçağıdır.',
    );
    // Cüzdan hiçbir yolda eksiye düşmesin.
    expect(portfoyler.every((int v) => v >= 0), isTrue);
  }, timeout: const Timeout(Duration(minutes: 10)));

  test('piyasa aynı hayatın aynı yılında aynı sonucu verir', () {
    // Determinizm bekçisi: tohum hayatın kimliğinden türüyor, ana
    // rastgele akıştan değil. Aynı hayat + aynı yaş = aynı piyasa.
    final GameState a =
        LifeGenerator.seeded(4).generate(mode: StartMode.tamamenRastgele);
    final int t1 = InvestmentEngine.marketSeed(a, 31);
    final int t2 = InvestmentEngine.marketSeed(a, 31);
    expect(t1, t2);
    // Komşu yıllar aynı tohumu almasın.
    expect(InvestmentEngine.marketSeed(a, 32), isNot(t1));

    // Ayrı hayatlar ayrı piyasa görsün.
    final GameState b =
        LifeGenerator.seeded(9).generate(mode: StartMode.tamamenRastgele);
    if (b.player.firstName != a.player.firstName ||
        b.player.lastName != a.player.lastName) {
      expect(InvestmentEngine.marketSeed(b, 31), isNot(t1));
    }

    // İki kez ilerletmek aynı durumu vermeli (yaş başına bir kez).
    final GameState bir =
        InvestmentEngine.advanceYear(state: a, newAge: a.player.age + 1);
    final GameState iki =
        InvestmentEngine.advanceYear(state: bir, newAge: a.player.age + 1);
    expect(iki.market.priceIndex, bir.market.priceIndex);
  });
}

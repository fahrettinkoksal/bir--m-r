// Paket AD/3 — yatırım kararlarının derinliği (§AD/3, §6, §7).
//
// **Neden var.** Paket AC panik, balon ve şirket olaylarını getirmişti ama
// seçeneklerinin tek etkisi mutluluktu: "sat", "bekle", "al" seçmek
// portföyde hiçbir şey değiştirmiyordu. Yani karar değil, süslü metindi.
// Ayrıca panik olayı sakin bir yılda, FOMO olayı soğuk piyasada
// çıkabiliyordu — olay oyuncuya yalan söylüyordu.
//
// Bu dosya üçünü de bekliyor: olay gerçek duruma kapılı, seçim portföyde
// gerçek bir hamle, ve **hiçbir seçim her hayatta doğru değil**.
// ignore_for_file: avoid_print
library;

import 'dart:math';

import 'package:bir_omur/data/event_pool.dart';
import 'package:bir_omur/data/investment_catalog.dart';
import 'package:bir_omur/domain/economy/investment_engine.dart';
import 'package:bir_omur/domain/economy/market_engine.dart';
import 'package:bir_omur/domain/generation/life_generator.dart';
import 'package:bir_omur/domain/models/game_event.dart';
import 'package:bir_omur/domain/models/game_state.dart';
import 'package:bir_omur/domain/models/investment.dart';
import 'package:bir_omur/domain/models/market_incident.dart';
import 'package:bir_omur/domain/models/market_state.dart';
import 'package:flutter_test/flutter_test.dart';

GameState _yatirimci({int wallet = 400000, int hisse = 300000}) {
  final GameState s =
      LifeGenerator.seeded(21).generate(mode: StartMode.tamamenRastgele);
  return s.copyWith(
    player: s.player.copyWith(wallet: wallet, age: 35),
    investments: <Holding>[
      Holding.opened(typeId: 'hisse', amount: hisse, atAge: 30),
    ],
  );
}

void main() {
  group('Paket AD/3 — yatırım kararları gerçek', () {
    test('§6-§7: panik ve FOMO olayları gerçek duruma kapılı', () {
      final GameEvent panik =
          kEventPool.firstWhere((GameEvent e) => e.id == 'ac_piyasa_panigi');
      final GameEvent fomo =
          kEventPool.firstWhere((GameEvent e) => e.id == 'ac_fomo_balon');
      final GameEvent devre =
          kEventPool.firstWhere((GameEvent e) => e.id == 'ac_devre_kesici');

      expect(panik.requirement.requiresCrisis, isTrue,
          reason: 'Panik olayi sakin yilda cikabiliyor');
      expect(devre.requirement.requiresCrisis, isTrue);
      expect(fomo.requirement.requiresHotAsset, 'hisse',
          reason: 'FOMO olayi soguk piyasada cikabiliyor');
      print('Panik krize kapili: ${panik.requirement.requiresCrisis} · '
          'FOMO isiya kapili: ${fomo.requirement.requiresHotAsset} '
          '(esik ${fomo.requirement.requiresHotAssetHeat})');
    });

    test('§AD/3: seçimler portföyde gerçekten bir şey yapıyor', () {
      final GameEvent panik =
          kEventPool.firstWhere((GameEvent e) => e.id == 'ac_piyasa_panigi');
      final EventChoice sat =
          panik.choices.firstWhere((EventChoice c) => c.id == 'sat');
      final EventChoice bekle =
          panik.choices.firstWhere((EventChoice c) => c.id == 'bekle');
      final EventChoice al =
          panik.choices.firstWhere((EventChoice c) => c.id == 'al');
      expect(sat.portfolioAction, PortfolioAction.satKismi);
      expect(al.portfolioAction, PortfolioAction.alKismi);
      // "Hiçbir şey yapma" gerçekten hiçbir şey yapmalı.
      expect(bekle.portfolioAction, isNull);

      final GameState once = _yatirimci();
      final GameState satti = InvestmentEngine.applyEventAction(
        once,
        action: sat.portfolioAction!,
        typeId: sat.portfolioTypeId,
        share: sat.portfolioShare,
      );
      final GameState aldi = InvestmentEngine.applyEventAction(
        once,
        action: al.portfolioAction!,
        typeId: al.portfolioTypeId,
        share: al.portfolioShare,
      );
      print('Panikte sat: portfoy ${once.portfolioValue} -> '
          '${satti.portfolioValue} · cuzdan ${once.player.wallet} -> '
          '${satti.player.wallet}');
      print('Panikte al : portfoy ${once.portfolioValue} -> '
          '${aldi.portfolioValue} · cuzdan ${once.player.wallet} -> '
          '${aldi.player.wallet}');
      expect(satti.portfolioValue, lessThan(once.portfolioValue));
      expect(satti.player.wallet, greaterThan(once.player.wallet));
      expect(aldi.portfolioValue, greaterThan(once.portfolioValue));
      expect(aldi.player.wallet, lessThan(once.player.wallet));
    });

    test('kâr alma yalnızca kârdayken çalışıyor', () {
      // Zararda: hamle uygulanmamalı.
      final GameState zararda = _yatirimci().copyWith(
        investments: <Holding>[
          const Holding(
            typeId: 'hisse',
            value: 200000,
            costBasis: 300000,
            totalInvested: 300000,
            realizedProfit: 0,
            firstBoughtAtAge: 30,
          ),
        ],
      );
      final GameState a = InvestmentEngine.applyEventAction(
        zararda,
        action: PortfolioAction.karAl,
        typeId: 'hisse',
        share: 0.3,
      );
      expect(a.portfolioValue, zararda.portfolioValue,
          reason: 'Zararda kar alindi');

      // Kârda: uygulanmalı.
      final GameState karda = _yatirimci().copyWith(
        investments: <Holding>[
          const Holding(
            typeId: 'hisse',
            value: 400000,
            costBasis: 250000,
            totalInvested: 250000,
            realizedProfit: 0,
            firstBoughtAtAge: 30,
          ),
        ],
      );
      final GameState b = InvestmentEngine.applyEventAction(
        karda,
        action: PortfolioAction.karAl,
        typeId: 'hisse',
        share: 0.3,
      );
      print('Kar alma: kardayken ${karda.portfolioValue} -> '
          '${b.portfolioValue}');
      expect(b.portfolioValue, lessThan(karda.portfolioValue));
    });

    test('hamle imkânsızsa durum değişmiyor (işlem durması, para yok)', () {
      // İşlem durmuş: satış da alım da olmamalı.
      final GameState durmus = _yatirimci().copyWith(
        market: MarketState(
          halts: <TradingHalt>[
            const TradingHalt(
                typeId: 'hisse', untilAge: 99, reason: 'test'),
          ],
        ),
      );
      final GameState a = InvestmentEngine.applyEventAction(
        durmus,
        action: PortfolioAction.satKismi,
        typeId: 'hisse',
        share: 0.5,
      );
      expect(a.portfolioValue, durmus.portfolioValue,
          reason: 'Islem durmusken satis gecti; kapali sira delinmis');

      // Parası yok: alım olmamalı.
      final GameState parasiz = _yatirimci(wallet: 100, hisse: 0);
      final GameState b = InvestmentEngine.applyEventAction(
        parasiz,
        action: PortfolioAction.alKismi,
        typeId: 'hisse',
        share: 0.5,
      );
      expect(b.player.wallet, parasiz.player.wallet);
      expect(b.portfolioValue, 0);
    });

    test('§6: aynı seçim her hayatta doğru değil', () {
      // Panikte satan ile panikte bekleyen, 500 ayrı piyasa yolunda
      // karşılaştırılıyor. İkisi de kazanmalı ve ikisi de kaybetmeli.
      int satanKazandi = 0;
      int bekleyenKazandi = 0;
      for (int p = 0; p < 500; p++) {
        MarketState st = const MarketState();
        final Random rng = Random(70000 + p);
        // Krize girene kadar ilerlet (panik anını kur).
        int guvenlik = 0;
        while (st.regime != MarketRegime.kriz && guvenlik < 200) {
          final r = MarketEngine.advance(state: st, newAge: guvenlik, rng: rng);
          st = r.state;
          guvenlik++;
        }
        // Panik anı: biri %35 satıyor, biri duruyor.
        double satan = 0.65; // portföyde kalan
        double satanNakit = 0.35;
        double bekleyen = 1.0;
        // Sonraki on yıl.
        for (int y = 0; y < 10; y++) {
          final r =
              MarketEngine.advance(state: st, newAge: guvenlik + y, rng: rng);
          st = r.state;
          final double getiri = r.year.returns['hisse'] ?? 0;
          satan *= 1 + getiri;
          bekleyen *= 1 + getiri;
        }
        final double satanToplam = satan + satanNakit;
        if (satanToplam > bekleyen) {
          satanKazandi++;
        } else {
          bekleyenKazandi++;
        }
      }
      print('500 panik yolu, 10 yil sonra: satan kazandi $satanKazandi · '
          'bekleyen kazandi $bekleyenKazandi');
      // İkisi de kayda değer sıklıkta kazanmalı: tek doğru cevap yok.
      expect(satanKazandi, greaterThan(50),
          reason: 'Panikte satmak hicbir zaman dogru degil; karar sahte');
      expect(bekleyenKazandi, greaterThan(50),
          reason: 'Panikte beklemek hicbir zaman dogru degil; karar sahte');
    });

    test('bildirim yağmuru yok: finansal olaylar seyrek', () {
      // Portföy olaylarının hepsinin bir `minAgeGap`i olmalı, yoksa
      // oyuncu her yıl aynı pencereyi görür.
      final List<GameEvent> finansal = kEventPool
          .where((GameEvent e) =>
              e.requirement.requiresPortfolio ||
              e.requirement.requiresCrisis ||
              e.requirement.requiresHotAsset != null)
          .toList(growable: false);
      expect(finansal.length, greaterThan(5));
      for (final GameEvent e in finansal) {
        expect(e.minAgeGap, greaterThanOrEqualTo(5),
            reason: '${e.id} cok sik cikabiliyor; bildirim yagmuru');
      }
      print('Finansal olay sayisi: ${finansal.length} · '
          'en kucuk tekrar araligi: '
          '${finansal.map((GameEvent e) => e.minAgeGap).reduce(min)} yil');
    });

    test('yatırım türlerinin hepsi hamleye açık', () {
      // Hamle `hisse` dışında da çalışmalı; ileride altın/fon olayları
      // eklenirse sessizce kırılmasın.
      for (final InvestmentType t in kMarketInvestmentTypes) {
        final GameState s = _yatirimci().copyWith(
          investments: <Holding>[
            Holding.opened(typeId: t.id, amount: 200000, atAge: 30),
          ],
        );
        final GameState sonra = InvestmentEngine.applyEventAction(
          s,
          action: PortfolioAction.satKismi,
          typeId: t.id,
          share: 0.5,
        );
        expect(sonra.portfolioValue, lessThan(s.portfolioValue),
            reason: '${t.id} icin hamle calismadi');
      }
    });
  });
}

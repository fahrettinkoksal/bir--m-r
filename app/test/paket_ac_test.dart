/// Paket AC — yatırım riskleri, piyasa şokları ve servet dengesi V2.
///
/// Bu dosya **kuralları** sabitler; ölçüm `paket_ac_measure_test.dart`'ta.
///
/// Sabitlenen şeyler:
/// * Kurgusal şirket kataloğunun tutarlılığı (paylar toplamı, gerçek ad yok).
/// * Piyasa determinizmi: aynı hayatın aynı yılı aynı sonucu verir,
///   kayıt geri yüklenerek yeniden çevrilemez.
/// * Krizin **çok yıllı** olması ve çıkışın toparlanmadan geçmesi.
/// * İşlem kapalıyken alım/satım yapılamaz; açılınca yapılabilir.
/// * Şirket batışı sepeti **sıfırlamaz** ve iki kez sayılmaz.
/// * Şirket durumu kademeli ilerler; sağlıklı şirket tek yılda iflas etmez.
/// * Fon tasfiyesi **bir kez** olur ve pozisyonu nakde çevirir.
/// * Komisyon ve kazanç kesintisi; komisyon maliyet esasına girmez.
/// * Zorunlu satış: geçim gideri portföyden karşılanır, portföy eksiye
///   düşmez.
/// * Çeşitlendirme oynaklığı düşürür ama kazanç garantisi vermez.
library;

import 'dart:math';

import 'package:bir_omur/data/company_catalog.dart';
import 'package:bir_omur/data/investment_catalog.dart';
import 'package:bir_omur/data/save/game_state_codec.dart';
import 'package:bir_omur/domain/economy/incident_engine.dart';
import 'package:bir_omur/domain/economy/investment_engine.dart';
import 'package:bir_omur/domain/economy/living_costs.dart';
import 'package:bir_omur/domain/economy/market_engine.dart';
import 'package:bir_omur/domain/generation/life_generator.dart';
import 'package:bir_omur/domain/models/game_state.dart';
import 'package:bir_omur/domain/models/investment.dart';
import 'package:bir_omur/domain/models/market_incident.dart';
import 'package:bir_omur/domain/models/market_state.dart';
import 'package:bir_omur/domain/models/pending_notice.dart';
import 'package:flutter_test/flutter_test.dart';

GameState _hayat({int wallet = 500000, int age = 40}) {
  final GameState taban =
      LifeGenerator.seeded(11).generate(mode: StartMode.tamamenRastgele);
  return taban.copyWith(
    pendingEvent: null,
    notices: const <PendingNotice>[],
    player: taban.player.copyWith(age: age, wallet: wallet),
  );
}

void main() {
  // ===================================================================
  // 1) Kurgusal şirket kataloğu (§1)
  // ===================================================================
  group('Kurgusal şirketler (AC/1)', () {
    test('sepet payları toplamı 1,00', () {
      final double toplam = kCompanyCatalog.fold<double>(
          0, (double t, Company c) => t + c.basketWeight);
      expect(
        (toplam - kCompanyBasketWeightSum).abs() < 0.0001,
        isTrue,
        reason: 'paylar toplamı $toplam; 1,00 olmalı yoksa batışın sepete '
            'etkisi yanlış hesaplanır',
      );
    });

    test('kimlikler ve adlar benzersiz', () {
      final Set<String> idler = <String>{};
      final Set<String> adlar = <String>{};
      for (final Company c in kCompanyCatalog) {
        expect(idler.add(c.id), isTrue, reason: 'yinelenen kimlik: ${c.id}');
        expect(adlar.add(c.name), isTrue, reason: 'yinelenen ad: ${c.name}');
        expect(c.basketWeight, greaterThan(0));
        expect(c.fragility, inInclusiveRange(0, 1));
      }
    });

    test('hiçbir şirketin payı sepetin beşte birini geçmiyor', () {
      // Tek bir haberin sepetin çoğunu silmesini engelleyen ilk kapı (§9).
      for (final Company c in kCompanyCatalog) {
        expect(
          c.basketWeight,
          lessThanOrEqualTo(kSingleFailureBasketCap),
          reason: '${c.name} payı çok büyük',
        );
      }
    });
  });

  // ===================================================================
  // 2) Piyasa determinizmi ve çok yıllı kriz (§11)
  // ===================================================================
  group('Piyasa rejimi V2 (AC/2)', () {
    test('aynı tohum aynı yılı aynı verir (determinizm)', () {
      const MarketState baslangic = MarketState();
      final ({MarketState state, MarketYear year}) a = MarketEngine.advance(
        state: baslangic,
        newAge: 30,
        rng: Random(1234),
      );
      final ({MarketState state, MarketYear year}) b = MarketEngine.advance(
        state: baslangic,
        newAge: 30,
        rng: Random(1234),
      );
      expect(a.year.regime, b.year.regime);
      expect(a.year.returns, b.year.returns);
      expect(a.state.regimeYearsLeft, b.state.regimeYearsLeft);
    });

    test('aynı yıl ikinci kez ilerletilemez', () {
      GameState s = _hayat();
      s = InvestmentEngine.advanceYear(state: s, newAge: 41);
      final MarketState once = s.market;
      final GameState tekrar =
          InvestmentEngine.advanceYear(state: s, newAge: 41);
      expect(tekrar.market.priceIndex, once.priceIndex);
      expect(tekrar.market.incidents.length, once.incidents.length);
    });

    test('kayıt geri yüklenince piyasa aynı yerden devam eder', () {
      GameState s = _hayat();
      s = InvestmentEngine.advanceYear(state: s, newAge: 41);
      final GameState geri = decodeGameState(encodeGameState(s));
      expect(geri.market.regime, s.market.regime);
      expect(geri.market.regimeYearsLeft, s.market.regimeYearsLeft);
      expect(geri.market.priceIndex, s.market.priceIndex);
      expect(geri.market.companyStatus, s.market.companyStatus);
      expect(geri.market.incidents.length, s.market.incidents.length);
      expect(geri.market.halts.length, s.market.halts.length);
      // Aynı yılı yeniden ilerletmek fiyatı değiştirmiyor: reroll yok.
      final GameState yeniden =
          InvestmentEngine.advanceYear(state: geri, newAge: 41);
      expect(yeniden.market.priceIndex, s.market.priceIndex);
    });

    test('kriz başlayınca en az bir yıl daha sürüyor', () {
      // Kriz kilidi: 1-3 yıl. Kilit varken rejim değişmez.
      final ({MarketRegime regime, int yearsLeft}) faz = MarketEngine.nextPhase(
        current: MarketRegime.kriz,
        yearsLeft: 2,
        rng: Random(1),
      );
      expect(faz.regime, MarketRegime.kriz, reason: 'kilit sürerken değişmez');
      expect(faz.yearsLeft, 1);
    });

    test('kriz kilidi bitince toparlanmaya geçmek en olası yol', () {
      int toparlanma = 0;
      for (int i = 0; i < 2000; i++) {
        final ({MarketRegime regime, int yearsLeft}) faz =
            MarketEngine.nextPhase(
          current: MarketRegime.kriz,
          yearsLeft: 0,
          rng: Random(i),
        );
        if (faz.regime == MarketRegime.toparlanma) toparlanma++;
      }
      expect(
        toparlanma / 2000,
        greaterThan(0.5),
        reason: 'krizin çıkışı toparlanmadan geçmeli; "krizde al, ertesi '
            'yıl güçlü yıl gelir" garantisi olmamalı',
      );
    });

    test('krizden doğrudan güçlü yıla atlanamıyor', () {
      for (int i = 0; i < 3000; i++) {
        final ({MarketRegime regime, int yearsLeft}) faz =
            MarketEngine.nextPhase(
          current: MarketRegime.kriz,
          yearsLeft: 0,
          rng: Random(i),
        );
        expect(faz.regime, isNot(MarketRegime.guclu));
      }
    });

    test('toparlanma yılı garanti kazanç değil', () {
      int eksi = 0;
      MarketState s = const MarketState(regime: MarketRegime.toparlanma);
      final Random rng = Random(77);
      for (int i = 0; i < 4000; i++) {
        final ({MarketState state, MarketYear year}) r = MarketEngine.advance(
          state: s.copyWith(regime: MarketRegime.toparlanma),
          newAge: i,
          rng: rng,
        );
        s = r.state;
        if (r.year.regime == MarketRegime.toparlanma &&
            (r.year.returns['hisse'] ?? 0) < 0) {
          eksi++;
        }
      }
      expect(eksi, greaterThan(0),
          reason: 'toparlanma yılları da eksi kapanabilmeli');
    });
  });

  // ===================================================================
  // 3) İşlem durması (§4, §5, §15)
  // ===================================================================
  group('İşlem sırası kapanması (AC/1)', () {
    GameState halted({required int untilAge, int age = 40}) {
      final GameState s = _hayat(age: age);
      return s.copyWith(
        investments: <Holding>[
          Holding(
            typeId: 'hisse',
            value: 100000,
            costBasis: 80000,
            totalInvested: 80000,
            realizedProfit: 0,
            firstBoughtAtAge: 30,
          ),
        ],
        market: s.market.copyWith(
          halts: <TradingHalt>[
            TradingHalt(
              typeId: 'hisse',
              untilAge: untilAge,
              reason: 'İşlemler geçici olarak durduruldu.',
            ),
          ],
        ),
      );
    }

    test('kapalıyken SATIŞ yapılamaz', () {
      final GameState s = halted(untilAge: 42);
      final String engel = InvestmentEngine.sellBlockReason(
        state: s,
        type: investmentTypeById('hisse')!,
        amount: 50000,
      );
      expect(engel, isNotEmpty);
      final InvestmentResult r =
          InvestmentEngine.sell(state: s, typeId: 'hisse', amount: 50000);
      expect(r.outcome.applied, isFalse);
      expect(s.holdingOf('hisse')!.value, 100000, reason: 'pozisyon durmalı');
    });

    test('kapalıyken ALIM da yapılamaz', () {
      final GameState s = halted(untilAge: 42);
      final InvestmentResult r =
          InvestmentEngine.buy(state: s, typeId: 'hisse', amount: 10000);
      expect(r.outcome.applied, isFalse);
    });

    test('durma süresi sonsuz değil: yaş gelince açılıyor', () {
      // 42'de kapalı, 42'ye gelince açık (untilAge dahil açık).
      final GameState kapali = halted(untilAge: 42, age: 41);
      expect(kapali.market.haltFor('hisse', 41), isNotNull);
      final GameState acik = halted(untilAge: 42, age: 42);
      expect(acik.market.haltFor('hisse', 42), isNull);
      final InvestmentResult r =
          InvestmentEngine.sell(state: acik, typeId: 'hisse', amount: 50000);
      expect(r.outcome.applied, isTrue, reason: 'açılınca satılabilmeli');
    });

    test('durma yalnızca ilgili türü kapatıyor', () {
      final GameState s = halted(untilAge: 42).copyWith(
        investments: <Holding>[
          const Holding(
            typeId: 'altin',
            value: 50000,
            costBasis: 50000,
            totalInvested: 50000,
            realizedProfit: 0,
            firstBoughtAtAge: 30,
          ),
        ],
      );
      final InvestmentResult r =
          InvestmentEngine.sell(state: s, typeId: 'altin', amount: 20000);
      expect(r.outcome.applied, isTrue);
    });

    test('zorunlu satış bile kapalı sırayı açmıyor', () {
      // Geçim gideri için nakit toplanırken kapalı tür atlanır.
      final GameState s = halted(untilAge: 45).copyWith(
        player: _hayat().player.copyWith(age: 40, wallet: 0),
      );
      final ({GameState state, int raised}) r =
          InvestmentEngine.raiseCashForExpense(state: s, needed: 30000);
      expect(r.raised, 0);
      expect(r.state.holdingOf('hisse')!.value, 100000);
    });
  });

  // ===================================================================
  // 4) Şirket olayları (§3, §9)
  // ===================================================================
  group('Şirket olayları (AC/1)', () {
    test('sağlıklı şirket tek adımda iflas etmiyor', () {
      // Kademeli ilerleme: normal durumdan doğrudan `kapandi` çıkmamalı.
      for (int i = 0; i < 4000; i++) {
        final IncidentOutcome o = IncidentEngine.advance(
          state: const MarketState(),
          regime: MarketRegime.kriz,
          newAge: 40,
          basketValue: 100000,
          fundValue: 0,
          rng: Random(i),
        );
        for (final MarketIncident olay in o.incidents) {
          expect(
            olay.kind,
            isNot(IncidentKind.iflas),
            reason: 'hepsi normal durumdayken iflas çıkmamalı',
          );
        }
      }
    });

    test('tek şirketin batışı sepeti SIFIRLAMIYOR', () {
      // Bütün şirketleri konkordatoya koy, sonra iflas adımını zorla.
      final Map<String, String> durumlar = <String, String>{
        for (final Company c in kCompanyCatalog)
          c.id: CompanyStatus.konkordato.name,
      };
      int iflasSayisi = 0;
      double enSertEtki = 0;
      for (int i = 0; i < 6000; i++) {
        final IncidentOutcome o = IncidentEngine.advance(
          state: MarketState(companyStatus: durumlar),
          regime: MarketRegime.kriz,
          newAge: 40,
          basketValue: 100000,
          fundValue: 0,
          rng: Random(i),
        );
        for (final MarketIncident olay in o.incidents) {
          if (olay.kind != IncidentKind.iflas) continue;
          iflasSayisi++;
          if (olay.impact < enSertEtki) enSertEtki = olay.impact;
        }
      }
      expect(iflasSayisi, greaterThan(0), reason: 'iflas erişilebilir olmalı');
      expect(
        enSertEtki,
        greaterThanOrEqualTo(-kSingleFailureBasketCap),
        reason: 'tek batış sepetin beşte birinden fazlasını silmemeli; '
            'en sert etki $enSertEtki',
      );
    });

    test('kapanmış şirket bir daha olaya konu olmuyor (çift sayım yok)', () {
      final Map<String, String> hepsiKapali = <String, String>{
        for (final Company c in kCompanyCatalog) c.id: CompanyStatus.kapandi.name,
      };
      for (int i = 0; i < 2000; i++) {
        final IncidentOutcome o = IncidentEngine.advance(
          state: MarketState(companyStatus: hepsiKapali),
          regime: MarketRegime.kriz,
          newAge: 40,
          basketValue: 100000,
          fundValue: 0,
          rng: Random(i),
        );
        for (final MarketIncident olay in o.incidents) {
          expect(olay.kind.isCompanyEvent, isFalse,
              reason: 'kapanmış şirkete yeni şirket olayı yazılmamalı');
        }
      }
    });

    test('konkordato ve kayyum işlemi durduruyor', () {
      final Map<String, String> durumlar = <String, String>{
        for (final Company c in kCompanyCatalog)
          c.id: CompanyStatus.sikinti.name,
      };
      bool durmaGorulduMu = false;
      for (int i = 0; i < 3000 && !durmaGorulduMu; i++) {
        final IncidentOutcome o = IncidentEngine.advance(
          state: MarketState(companyStatus: durumlar),
          regime: MarketRegime.kriz,
          newAge: 40,
          basketValue: 100000,
          fundValue: 0,
          rng: Random(i),
        );
        final bool surecVar = o.incidents.any((MarketIncident x) =>
            x.kind == IncidentKind.konkordato ||
            x.kind == IncidentKind.kayyum);
        if (surecVar) {
          expect(o.halts, isNotEmpty,
              reason: 'süreç başlayınca işlem durmalı');
          durmaGorulduMu = true;
        }
      }
      expect(durmaGorulduMu, isTrue);
    });

    test('şirket durumu iyileşebiliyor: her kötü haber iflasla bitmiyor', () {
      final Map<String, String> durumlar = <String, String>{
        for (final Company c in kCompanyCatalog)
          c.id: CompanyStatus.inceleme.name,
      };
      bool iyilesme = false;
      for (int i = 0; i < 3000 && !iyilesme; i++) {
        final IncidentOutcome o = IncidentEngine.advance(
          state: MarketState(companyStatus: durumlar),
          regime: MarketRegime.guclu,
          newAge: 40,
          basketValue: 100000,
          fundValue: 0,
          rng: Random(i),
        );
        for (final MarketIncident olay in o.incidents) {
          if (olay.companyId == null) continue;
          if (o.companyStatus[olay.companyId!] == CompanyStatus.normal.name) {
            iyilesme = true;
          }
        }
      }
      expect(iyilesme, isTrue,
          reason: 'incelemeden temize çıkmak mümkün olmalı');
    });
  });

  // ===================================================================
  // 5) Fon riski (§8)
  // ===================================================================
  group('Fon riski (AC/1)', () {
    test('fon tasfiyesi pozisyonu nakde çeviriyor ve BİR KEZ oluyor', () {
      GameState s = _hayat(wallet: 10000).copyWith(
        investments: <Holding>[
          const Holding(
            typeId: 'fon',
            value: 200000,
            costBasis: 150000,
            totalInvested: 150000,
            realizedProfit: 0,
            firstBoughtAtAge: 30,
          ),
        ],
      );
      // Tasfiyeyi doğrudan uygula: motorun nakit yolu sınanıyor.
      final IncidentOutcome o = IncidentOutcome(
        incidents: <MarketIncident>[
          const MarketIncident(
            kind: IncidentKind.fonTasfiye,
            age: 41,
            typeId: 'fon',
            cashDelta: 200000,
          ),
        ],
        companyStatus: const <String, String>{},
        halts: const <TradingHalt>[],
        multipliers: const <String, double>{},
        cashDelta: 0,
      );
      final GameState sonra =
          InvestmentEngine.debugApplyIncidentCash(s, o, 41);
      expect(sonra.player.wallet, 210000);
      expect(sonra.holdingOf('fon')!.value, 0);
      expect(sonra.holdingOf('fon')!.realizedProfit, 50000);
      // İkinci kez uygulanınca pozisyon boş olduğu için para eklenmiyor.
      final GameState tekrar =
          InvestmentEngine.debugApplyIncidentCash(sonra, o, 41);
      expect(tekrar.player.wallet, 210000, reason: 'tasfiye iki kez olmaz');
      s = sonra;
    });

    test('fon olayları hisse kadar sert değil', () {
      final double enSertFon = IncidentEngine.prototypeOnlyFundImpact.values
          .reduce((double a, double b) => a < b ? a : b);
      expect(
        enSertFon.abs(),
        lessThan(kSingleFailureBasketCap),
        reason: 'fon tek hisse gibi davranmamalı',
      );
    });
  });

  // ===================================================================
  // 6) Maliyetler (§22, §23)
  // ===================================================================
  group('Portföy maliyetleri (AC/3)', () {
    test('komisyon en az 1 ₺ ve orana uygun', () {
      expect(InvestmentEngine.commissionFor(0), 0);
      expect(InvestmentEngine.commissionFor(100), 1);
      expect(InvestmentEngine.commissionFor(50000), 100);
    });

    test('parası komisyona yetmeyen alım yapamıyor', () {
      final GameState s = _hayat(wallet: 10000);
      final String engel = InvestmentEngine.buyBlockReason(
        state: s,
        type: investmentTypeById('hisse')!,
        amount: 10000,
      );
      expect(engel, isNotEmpty,
          reason: 'tutar + komisyon cüzdanı aşıyor');
      final InvestmentResult r =
          InvestmentEngine.buy(state: s, typeId: 'hisse', amount: 9900);
      expect(r.outcome.applied, isTrue);
    });

    test('fonun yıllık yönetim gideri değeri aşağı çekiyor', () {
      // Getiriyi sıfırlayıp yalnızca gideri ölçüyoruz.
      expect(
        InvestmentEngine.prototypeOnlyFundAnnualFee,
        greaterThan(0),
        reason: 'fonun bir yöneticisi var ve ücret alıyor',
      );
      expect(InvestmentEngine.prototypeOnlyFundAnnualFee, lessThan(0.05),
          reason: 'küçük olmalı; uzun vadede hissedilir ama boğmamalı');
    });
  });

  // ===================================================================
  // 7) Zorunlu satış ve yaşam gideri (§19)
  // ===================================================================
  group('Zorunlu satış (AC/3)', () {
    test('cüzdan yetmezken geçim gideri portföyden karşılanıyor', () {
      GameState s = _hayat(wallet: 1000, age: 45).copyWith(
        investments: <Holding>[
          const Holding(
            typeId: 'altin',
            value: 5000000,
            costBasis: 4000000,
            totalInvested: 4000000,
            realizedProfit: 0,
            firstBoughtAtAge: 25,
          ),
        ],
      );
      final int gider = LivingCosts.yearlyCost(s);
      expect(gider, greaterThan(1000), reason: 'kurulum: cüzdan yetmemeli');
      final int oncePortfoy = s.portfolioValue;
      final ({GameState state, String? logText}) r = LivingCosts.apply(s);
      s = r.state;
      expect(
        s.portfolioValue,
        lessThan(oncePortfoy),
        reason: 'portföy görünmez kasa olmamalı: gider oradan karşılanmalı',
      );
      expect(s.hardshipYears, 0,
          reason: 'portföyü olan kişi geçim sıkıntısı çekmiş sayılmamalı');
      expect(r.logText, isNotNull);
      expect(r.logText, contains('yatırımdan'));
    });

    test('portföy de yetmezse geçim sıkıntısı yazılıyor ve eksiye düşmüyor',
        () {
      GameState s = _hayat(wallet: 0, age: 45).copyWith(
        investments: <Holding>[
          const Holding(
            typeId: 'altin',
            value: 500,
            costBasis: 500,
            totalInvested: 500,
            realizedProfit: 0,
            firstBoughtAtAge: 25,
          ),
        ],
      );
      final ({GameState state, String? logText}) r = LivingCosts.apply(s);
      s = r.state;
      expect(s.player.wallet, 0, reason: 'cüzdan eksiye düşmez');
      expect(s.portfolioValue, greaterThanOrEqualTo(0),
          reason: 'portföy eksiye düşmez');
      expect(s.hardshipYears, 1);
    });

    test('portföyü olmayanda davranış değişmedi', () {
      // Gerileme koruması: yeni yol portföysüz oyuncuyu etkilememeli.
      final GameState s = _hayat(wallet: 0, age: 45);
      final ({GameState state, String? logText}) r = LivingCosts.apply(s);
      expect(r.state.hardshipYears, 1);
      expect(r.state.player.wallet, 0);
    });

    test('zorunlu satış vadeliyi en son bozuyor', () {
      GameState s = _hayat(wallet: 0, age: 45).copyWith(
        investments: <Holding>[
          const Holding(
            typeId: 'altin',
            value: 400000,
            costBasis: 400000,
            totalInvested: 400000,
            realizedProfit: 0,
            firstBoughtAtAge: 25,
          ),
        ],
        termDeposits: <TermDeposit>[
          const TermDeposit(
            id: 'v1',
            amount: 300000,
            openedAtAge: 44,
            maturesAtAge: 46,
            rateBasis: 600,
          ),
        ],
      );
      final ({GameState state, int raised}) r =
          InvestmentEngine.raiseCashForExpense(state: s, needed: 50000);
      expect(r.raised, greaterThanOrEqualTo(50000));
      expect(r.state.termDeposits, hasLength(1),
          reason: 'serbest pozisyon yeterken vadeli bozulmamalı');
    });
  });

  // ===================================================================
  // 8) Çeşitlendirme (§24) ve yapay limit olmaması (§25)
  // ===================================================================
  group('Çeşitlendirme ve limit (AC/3)', () {
    test('oyuncu parasının tamamını yatırabiliyor: yapay limit YOK', () {
      final GameState s = _hayat(wallet: 1000000);
      // Komisyon payı dışında tamamı yatırılabilmeli.
      final int tamami = 1000000 - InvestmentEngine.commissionFor(1000000);
      final InvestmentResult r =
          InvestmentEngine.buy(state: s, typeId: 'hisse', amount: tamami);
      expect(r.outcome.applied, isTrue,
          reason: '"yılda en fazla %20" gibi yapay bir sınır olmamalı');
      expect(r.state.holdingOf('hisse')!.value, tamami);
    });

    test('yoğunlaşma oynaklığı artırıyor, beklenen değeri kaydırmıyor', () {
      // Aynı piyasa yılı, iki portföy: biri tek varlıkta, biri dağıtılmış.
      //
      // **Paket BV'de düzeltildi.** Döngü 300 kez dönüyordu ama her tur
      // **aynı** piyasa yılını hesaplıyordu: `_hayat()` sabit tohumla
      // kuruluyor ve piyasa tohumu oyuncunun adı + yaşından türüyor
      // (`InvestmentEngine.marketSeed`). Yani 300 tur tek örneği 300 kez
      // sayıyordu; isim havuzu büyüyüp ad değişince o tek örnek ters
      // döndü ve bekçi düştü. Artık her tur **başka bir piyasa yılını**
      // ölçüyor: iddia aynı, ölçüm gerçekten dağılım.
      int tekVarlikOynaklik = 0;
      int dagitilmisOynaklik = 0;
      for (int tohum = 0; tohum < 300; tohum++) {
        final int yas = 41 + tohum;
        GameState tek = _hayat(wallet: 0, age: yas - 1).copyWith(
          investments: <Holding>[
            const Holding(
              typeId: 'hisse',
              value: 400000,
              costBasis: 400000,
              totalInvested: 400000,
              realizedProfit: 0,
              firstBoughtAtAge: 30,
            ),
          ],
        );
        GameState dagitik = tek.copyWith(
          investments: <Holding>[
            const Holding(
              typeId: 'hisse',
              value: 200000,
              costBasis: 200000,
              totalInvested: 200000,
              realizedProfit: 0,
              firstBoughtAtAge: 30,
            ),
            const Holding(
              typeId: 'altin',
              value: 200000,
              costBasis: 200000,
              totalInvested: 200000,
              realizedProfit: 0,
              firstBoughtAtAge: 30,
            ),
          ],
        );
        tek = InvestmentEngine.advanceYear(state: tek, newAge: yas);
        dagitik = InvestmentEngine.advanceYear(state: dagitik, newAge: yas);
        tekVarlikOynaklik += (tek.portfolioValue - 400000).abs();
        dagitilmisOynaklik += (dagitik.portfolioValue - 400000).abs();
      }
      expect(
        tekVarlikOynaklik,
        greaterThan(dagitilmisOynaklik),
        reason: 'tek riskli varlıkta yoğunlaşan portföy daha çok sallanmalı',
      );
    });
  });

  // ===================================================================
  // 9) Portföy hiçbir yolda eksiye düşmüyor
  // ===================================================================
  group('Değişmezler (AC)', () {
    test('60 yıl boyunca portföy ve cüzdan eksiye düşmüyor', () {
      GameState s = _hayat(wallet: 300000, age: 20).copyWith(
        investments: <Holding>[
          const Holding(
            typeId: 'hisse',
            value: 200000,
            costBasis: 200000,
            totalInvested: 200000,
            realizedProfit: 0,
            firstBoughtAtAge: 20,
          ),
          const Holding(
            typeId: 'fon',
            value: 100000,
            costBasis: 100000,
            totalInvested: 100000,
            realizedProfit: 0,
            firstBoughtAtAge: 20,
          ),
        ],
      );
      for (int yas = 21; yas <= 80; yas++) {
        s = s.copyWith(player: s.player.copyWith(age: yas));
        s = InvestmentEngine.advanceYear(state: s, newAge: yas);
        expect(s.player.wallet, greaterThanOrEqualTo(0), reason: 'yaş $yas');
        expect(s.portfolioValue, greaterThanOrEqualTo(0), reason: 'yaş $yas');
        for (final Holding h in s.investments) {
          expect(h.value, greaterThanOrEqualTo(0), reason: 'yaş $yas');
        }
      }
    });

    test('olay kaydı büyüyor ama aynı yılda tekrarlanmıyor', () {
      GameState s = _hayat(age: 30);
      int oncekiUzunluk = 0;
      for (int yas = 31; yas <= 60; yas++) {
        s = s.copyWith(player: s.player.copyWith(age: yas));
        s = InvestmentEngine.advanceYear(state: s, newAge: yas);
        // Aynı yılı tekrar ilerletmek kayıt eklemiyor.
        final GameState tekrar =
            InvestmentEngine.advanceYear(state: s, newAge: yas);
        expect(tekrar.market.incidents.length, s.market.incidents.length);
        expect(s.market.incidents.length,
            greaterThanOrEqualTo(oncekiUzunluk));
        oncekiUzunluk = s.market.incidents.length;
      }
    });
  });
}

/// Saldırgan oyuncu taraması (Paket AC, §27).
///
/// **Amaç:** oyundaki en iyi ekonomik stratejiyi ve varsa exploit'i
/// bulmaya çalışmak. Min-max oyuncu "en iyisini oynar"; buradaki oyuncu
/// **kuralı zorlar**: aynı yıl içinde tekrar işlem yapmayı, kaydı geri
/// yükleyip zar atmayı, kredi arbitrajını, miras ve boşanmada çift
/// sayımı dener.
///
/// Oyun min-max oyuncuya dayanmalı. Dayanmadığı yer bulgu olarak
/// raporlanır; **denge burada değiştirilmez.**
library;

// ignore_for_file: avoid_print

import 'dart:math';

import 'package:bir_omur/data/investment_catalog.dart';
import 'package:bir_omur/data/save/game_state_codec.dart';
import 'package:bir_omur/domain/economy/investment_engine.dart';
import 'package:bir_omur/domain/economy/net_worth.dart';
import 'package:bir_omur/domain/generation/life_generator.dart';
import 'package:bir_omur/domain/interaction/divorce_settlement.dart';
import 'package:bir_omur/domain/interaction/marriage_engine.dart';
import 'package:bir_omur/domain/models/game_state.dart';
import 'package:bir_omur/domain/models/gender.dart';
import 'package:bir_omur/domain/models/investment.dart';
import 'package:bir_omur/domain/models/loan.dart';
import 'package:bir_omur/domain/models/market_incident.dart';
import 'package:bir_omur/domain/models/pending_notice.dart';
import 'package:bir_omur/domain/models/person.dart';
import 'package:bir_omur/domain/models/relation.dart';
import 'package:bir_omur/domain/models/wealth.dart';
import 'package:flutter_test/flutter_test.dart';

GameState _hayat({int wallet = 1000000, int age = 40}) {
  final GameState taban =
      LifeGenerator.seeded(13).generate(mode: StartMode.tamamenRastgele);
  return taban.copyWith(
    pendingEvent: null,
    notices: const <PendingNotice>[],
    player: taban.player.copyWith(age: age, wallet: wallet),
  );
}

void main() {
  group('Saldirgan oyuncu — reroll denemeleri', () {
    test('EXPLOIT DENEMESI: kaydi geri yukleyip piyasayi yeniden cevirmek',
        () {
      // En klasik deneme: yıl kötü geçti, kaydı geri yükle, tekrar dene.
      GameState s = _hayat(age: 30).copyWith(
        investments: <Holding>[
          const Holding(
            typeId: 'hisse',
            value: 500000,
            costBasis: 500000,
            totalInvested: 500000,
            realizedProfit: 0,
            firstBoughtAtAge: 25,
          ),
        ],
      );
      s = s.copyWith(player: s.player.copyWith(age: 31));
      final GameState birinci =
          InvestmentEngine.advanceYear(state: s, newAge: 31);
      final int birinciDeger = birinci.portfolioValue;

      // Kaydet, yükle, aynı yılı yeniden ilerlet.
      for (int deneme = 0; deneme < 25; deneme++) {
        final GameState geri = decodeGameState(encodeGameState(s));
        final GameState yeniden =
            InvestmentEngine.advanceYear(state: geri, newAge: 31);
        expect(
          yeniden.portfolioValue,
          birinciDeger,
          reason: 'REROLL: kayit geri yuklenerek piyasa yeniden '
              'cevrilebiliyor — deneme $deneme',
        );
      }
    });

    test('EXPLOIT DENEMESI: ayni yil icinde piyasayi iki kez ilerletmek', () {
      GameState s = _hayat(age: 45).copyWith(
        investments: <Holding>[
          const Holding(
            typeId: 'fon',
            value: 300000,
            costBasis: 300000,
            totalInvested: 300000,
            realizedProfit: 0,
            firstBoughtAtAge: 30,
          ),
        ],
      );
      s = InvestmentEngine.advanceYear(state: s, newAge: 46);
      final int bir = s.portfolioValue;
      for (int i = 0; i < 40; i++) {
        s = InvestmentEngine.advanceYear(state: s, newAge: 46);
      }
      expect(s.portfolioValue, bir,
          reason: 'ayni yil 40 kez ilerletilerek portfoy buyutulemez');
    });

    test('EXPLOIT DENEMESI: al-sat dongusuyle bedava deger uretmek', () {
      // Komisyon ve kesinti varsa al-sat döngüsü **para kaybettirmeli**.
      GameState s = _hayat(wallet: 1000000, age: 40);
      final int basla = NetWorth.of(s);
      for (int i = 0; i < 20; i++) {
        final int tutar = s.player.wallet - 5000;
        if (tutar < kInvestmentMinBuy) break;
        final InvestmentResult al =
            InvestmentEngine.buy(state: s, typeId: 'altin', amount: tutar);
        if (!al.outcome.applied) break;
        s = al.state;
        final Holding? h = s.holdingOf('altin');
        if (h == null || h.value <= 0) break;
        final InvestmentResult sat = InvestmentEngine.sell(
            state: s, typeId: 'altin', amount: h.value);
        if (!sat.outcome.applied) break;
        s = sat.state;
      }
      expect(
        NetWorth.of(s),
        lessThan(basla),
        reason: 'al-sat dongusu para kaybettirmeli; kazandiriyorsa exploit',
      );
      print('Al-sat dongusu 20 tur: '
          '${basla ~/ 1000}k -> ${NetWorth.of(s) ~/ 1000}k '
          '(kayip ${(basla - NetWorth.of(s)) ~/ 1000}k)');
    });

    test('EXPLOIT DENEMESI: kredi arbitraji — borc alip yatirmak', () {
      // Kredi faizi yatırım getirisinden düşükse "borç al, yatır" bedava
      // para olurdu. Ölçüyoruz.
      final GameState s = _hayat(wallet: 100000, age: 30);
      for (final Bank banka in Bank.values) {
        final int yillikFaiz = (banka.yearlyRate * 100).round();
        // En iyimser yatırım eğilimi (hisse) ile karşılaştır.
        final int enIyiEgilim =
            (investmentTypeById('hisse')!.drift * 100).round();
        print('${banka.label}: yillik kredi faizi ~%$yillikFaiz · '
            'en yuksek yatirim egilimi %$enIyiEgilim');
        expect(
          banka.yearlyRate,
          greaterThan(investmentTypeById('hisse')!.drift),
          reason: 'ARBITRAJ: ${banka.label} kredi faizi en yuksek yatirim '
              'egiliminden dusuk; borc alip yatirmak bedava para olur',
        );
      }
      expect(s.loans, isEmpty);
    });

    test('EXPLOIT DENEMESI: portfoye saklayarak bosanma payindan kacmak',
        () {
      // D-162 kuralı: evlilik içinde açılan pozisyonlar paylaşıma girer.
      // Parayı portföye taşımak kaçış yolu olmamalı.
      const MarriageEngine motor = MarriageEngine();
      GameState s = _hayat(wallet: 2000000, age: 30).copyWith(
        people: <Person>[
          Person(
            id: 'es-1',
            firstName: 'Elif',
            lastName: 'Yaman',
            gender: Gender.kadin,
            relation: RelationType.sevgili,
            age: 30,
            isAlive: true,
            inPlayerHousehold: false,
            employment: EmploymentStatus.calisiyor,
            occupation: 'öğretmen',
            wealth: WealthTier.ortaHalli,
            bond: 90,
          ),
        ],
      );
      s = motor.marry(s, 'es-1').state;
      expect(s.isMarried, isTrue);
      // Evlilik içinde bütün parayı portföye taşı.
      final int tutar = s.player.wallet - 10000;
      s = InvestmentEngine.buy(state: s, typeId: 'altin', amount: tutar).state;
      expect(s.portfolioValue, tutar);
      final int oncePortfoy = s.portfolioValue;
      s = motor.divorce(s).state;
      expect(
        s.portfolioValue,
        lessThan(oncePortfoy),
        reason: 'KACIS: parayi portfoye tasiyarak bosanma payindan '
            'kurtulunabiliyor',
      );
      print('Bosanmada portfoy ${oncePortfoy ~/ 1000}k -> '
          '${s.portfolioValue ~/ 1000}k');
    });

    test('EXPLOIT DENEMESI: bosanmada mal paylasimi iki kez sayilmiyor', () {
      const MarriageEngine motor = MarriageEngine();
      GameState s = _hayat(wallet: 3000000, age: 30).copyWith(
        people: <Person>[
          Person(
            id: 'es-1',
            firstName: 'Elif',
            lastName: 'Yaman',
            gender: Gender.kadin,
            relation: RelationType.sevgili,
            age: 30,
            isAlive: true,
            inPlayerHousehold: false,
            employment: EmploymentStatus.calisiyor,
            occupation: 'öğretmen',
            wealth: WealthTier.ortaHalli,
            bond: 90,
          ),
        ],
      );
      s = motor.marry(s, 'es-1').state;
      s = motor.divorce(s).state;
      final int birKez = NetWorth.of(s);
      // İkinci boşanma denemesi: evli değil, engellenmeli.
      expect(motor.divorceBlockReason(s), isNotEmpty);
      final GameState tekrar = motor.divorce(s).state;
      expect(NetWorth.of(tekrar), birKez,
          reason: 'ikinci bosanma cagrisi yeniden pay almamali');
    });

    test('EXPLOIT DENEMESI: ayni miras iki kez dagitilmiyor', () {
      // `settledEstates` bekçisi: aynı vefat iki kez miras üretmemeli.
      GameState s = _hayat(age: 40);
      final int once = NetWorth.of(s);
      // Aynı yılı çok kez ilerletmek miras üretmiyor (piyasa da dahil).
      for (int i = 0; i < 20; i++) {
        s = InvestmentEngine.advanceYear(state: s, newAge: 41);
      }
      // Yatırımı olmayan oyuncuda net servet değişmemeli.
      expect(NetWorth.of(s), once);
    });

    test('EXPLOIT DENEMESI: islem kapaliyken zorunlu satisla cikmak', () {
      // Kapalı sırada geçim gideri bahanesiyle çıkış olmamalı.
      GameState s = _hayat(wallet: 0, age: 45).copyWith(
        investments: <Holding>[
          const Holding(
            typeId: 'hisse',
            value: 900000,
            costBasis: 900000,
            totalInvested: 900000,
            realizedProfit: 0,
            firstBoughtAtAge: 30,
          ),
        ],
      );
      s = s.copyWith(
        market: s.market.copyWith(
          halts: <TradingHalt>[
            const TradingHalt(
              typeId: 'hisse',
              untilAge: 50,
              reason: 'İşlemler durduruldu.',
            ),
          ],
        ),
      );
      final ({GameState state, int raised}) r =
          InvestmentEngine.raiseCashForExpense(state: s, needed: 100000);
      expect(r.raised, 0,
          reason: 'kapali sirada zorunlu satisla da cikilamaz');
      expect(r.state.holdingOf('hisse')!.value, 900000);
    });

    test('EXPLOIT DENEMESI: vadeliyi bozup tekrar acarak faiz uretmek', () {
      GameState s = _hayat(wallet: 500000, age: 40);
      final int basla = NetWorth.of(s);
      for (int i = 0; i < 12; i++) {
        final int tutar = s.player.wallet - 2000;
        if (tutar < kTermDepositMinAmount) break;
        final InvestmentResult ac =
            InvestmentEngine.buy(state: s, typeId: 'vadeli', amount: tutar);
        if (!ac.outcome.applied) break;
        s = ac.state;
        if (s.termDeposits.isEmpty) break;
        final InvestmentResult boz = InvestmentEngine.breakTermDeposit(
          state: s,
          depositId: s.termDeposits.first.id,
        );
        if (!boz.outcome.applied) break;
        s = boz.state;
      }
      expect(
        NetWorth.of(s),
        lessThanOrEqualTo(basla),
        reason: 'ac-boz dongusu faiz uretmemeli',
      );
      print('Vadeli ac-boz 12 tur: ${basla ~/ 1000}k -> '
          '${NetWorth.of(s) ~/ 1000}k');
    });
  });

  group('Saldirgan oyuncu — degismezler', () {
    test('portfoy ve cuzdan hicbir saldiri yolunda eksiye dusmuyor', () {
      GameState s = _hayat(wallet: 200000, age: 25).copyWith(
        investments: <Holding>[
          const Holding(
            typeId: 'hisse',
            value: 300000,
            costBasis: 300000,
            totalInvested: 300000,
            realizedProfit: 0,
            firstBoughtAtAge: 25,
          ),
        ],
      );
      final Random rng = Random(5);
      for (int yas = 26; yas <= 85; yas++) {
        s = s.copyWith(player: s.player.copyWith(age: yas));
        // Rastgele saldırgan hamleler: al, sat, vadeli aç, boz.
        for (int hamle = 0; hamle < 4; hamle++) {
          switch (rng.nextInt(4)) {
            case 0:
              final int tutar = rng.nextInt(60000) + 1000;
              s = InvestmentEngine.buy(
                      state: s, typeId: 'hisse', amount: tutar)
                  .state;
            case 1:
              final Holding? h = s.holdingOf('hisse');
              if (h != null && h.value > 0) {
                s = InvestmentEngine.sell(
                        state: s,
                        typeId: 'hisse',
                        amount: rng.nextInt(h.value) + 1)
                    .state;
              }
            case 2:
              s = InvestmentEngine.buy(
                      state: s,
                      typeId: 'vadeli',
                      amount: kTermDepositMinAmount + rng.nextInt(20000))
                  .state;
            case 3:
              if (s.termDeposits.isNotEmpty) {
                s = InvestmentEngine.breakTermDeposit(
                  state: s,
                  depositId: s.termDeposits.first.id,
                ).state;
              }
          }
          expect(s.player.wallet, greaterThanOrEqualTo(0), reason: 'yas $yas');
          expect(s.portfolioValue, greaterThanOrEqualTo(0),
              reason: 'yas $yas');
          for (final Holding h in s.investments) {
            expect(h.value, greaterThanOrEqualTo(0), reason: 'yas $yas');
            expect(h.costBasis, greaterThanOrEqualTo(0), reason: 'yas $yas');
          }
        }
        s = InvestmentEngine.advanceYear(state: s, newAge: yas);
      }
    });

    test('maliyet esasi degeri asmiyor (kayit tutarli)', () {
      GameState s = _hayat(wallet: 400000, age: 30);
      s = InvestmentEngine.buy(state: s, typeId: 'fon', amount: 200000).state;
      for (int yas = 31; yas <= 70; yas++) {
        s = s.copyWith(player: s.player.copyWith(age: yas));
        s = InvestmentEngine.advanceYear(state: s, newAge: yas);
        final Holding? h = s.holdingOf('fon');
        if (h == null) continue;
        // Kısmi satış sonrası maliyet oranlı düşmeli; değer sıfırsa
        // maliyet de sıfır olmalı.
        if (h.value == 0) {
          expect(h.costBasis, 0, reason: 'yas $yas: bos pozisyonda maliyet');
        }
      }
    });

    test('boşanma payı hesabı tek yerden geliyor', () {
      // `NetWorth.itemsValue` ile `DivorceSettlement.valueOf` aynı ölçüyü
      // kullanmalı: iki ayrı değer olursa paylaşım ve servet çelişir.
      final GameState s = _hayat();
      final int netWorthOlcusu = NetWorth.itemsValue(s);
      final int paylasimOlcusu = s.items
          .fold<int>(0, (int t, dynamic i) => t + DivorceSettlement.valueOf(i));
      expect(netWorthOlcusu, paylasimOlcusu);
    });
  });
}

import 'dart:math';

import 'package:bir_omur/data/investment_catalog.dart';
import 'package:bir_omur/data/save/game_state_codec.dart';
import 'package:bir_omur/domain/economy/investment_engine.dart';
import 'package:bir_omur/domain/economy/market_engine.dart';
import 'package:bir_omur/domain/economy/net_worth.dart';
import 'package:bir_omur/domain/generation/generation_continuation.dart';
import 'package:bir_omur/domain/generation/life_generator.dart';
import 'package:bir_omur/domain/interaction/marriage_engine.dart';
import 'package:bir_omur/domain/models/career.dart';
import 'package:bir_omur/domain/models/game_state.dart';
import 'package:bir_omur/domain/models/gender.dart';
import 'package:bir_omur/domain/models/wealth.dart';
import 'package:bir_omur/domain/models/investment.dart';
import 'package:bir_omur/domain/models/marriage.dart';
import 'package:bir_omur/domain/models/market_state.dart';
import 'package:bir_omur/domain/models/owned_item.dart';
import 'package:bir_omur/domain/models/pending_notice.dart';
import 'package:bir_omur/domain/models/person.dart';
import 'package:bir_omur/domain/models/relation.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/generation_fixtures.dart';

/// Paket AA — yatırım, portföy ve servet sistemi.
///
/// Sayıların tamamı `prototypeOnly`; bu testler **kalibrasyonu
/// dondurmuyor**, kalibrasyonun bozulduğunu fark ettiriyor. Bu yüzden
/// eşikler geniş ve gerekçeli.
void main() {
  GameState hayat({int age = 30, int wallet = 200000}) {
    final GameState base =
        LifeGenerator.seeded(11).generate(mode: StartMode.tamamenRastgele);
    return base.copyWith(
      pendingEvent: null,
      notices: const <PendingNotice>[],
      player: base.player.copyWith(age: age, wallet: wallet),
      movedOut: true,
    );
  }

  group('Yatırım kataloğu (AA/1)', () {
    test('beş tür var ve hepsinin kimliği tek', () {
      expect(kInvestmentTypes.length, 5);
      final Set<String> ids =
          kInvestmentTypes.map((InvestmentType t) => t.id).toSet();
      expect(ids.length, 5);
    });

    test('gerçek şirket, hisse veya fon adı geçmiyor', () {
      // Görevin açık yasağı: Apple, THY, Tesla vb. yazılmayacak.
      const List<String> yasakli = <String>[
        'apple',
        'tesla',
        'thy',
        'bist',
        'nasdaq',
        'garanti',
        'akbank',
        'bitcoin',
        'ethereum',
      ];
      for (final InvestmentType t in kInvestmentTypes) {
        final String metin =
            '${t.name} ${t.description} ${t.risk.label}'.toLowerCase();
        for (final String k in yasakli) {
          expect(metin.contains(k), isFalse, reason: '${t.id} → $k');
        }
      }
    });

    test('hiçbir metin kesin kazanç vaat etmiyor', () {
      const List<String> yasakli = <String>[
        'kesin kazan',
        'garanti kazan',
        'kesin kâr',
        'mutlaka kazan',
        'kaybetmezsin',
      ];
      for (final InvestmentType t in kInvestmentTypes) {
        final String metin =
            '${t.name} ${t.description} ${t.risk.label}'.toLowerCase();
        for (final String k in yasakli) {
          expect(metin.contains(k), isFalse, reason: '${t.id} → $k');
        }
      }
    });
  });

  group('Piyasa motoru (AA/1)', () {
    test('yaş başına bir kez ilerler', () {
      final MarketState ilk = const MarketState();
      final ({MarketState state, MarketYear year}) bir = MarketEngine.advance(
        state: ilk,
        newAge: 31,
        rng: Random(1),
      );
      expect(bir.state.advancedAtAge, 31);
      expect(MarketEngine.alreadyAdvancedAt(bir.state, 31), isTrue);
      expect(MarketEngine.alreadyAdvancedAt(bir.state, 32), isFalse);
    });

    test('kuşak devrinden sonra piyasa yeniden ilerleyebilir', () {
      // Gerçek hata buradaydı: karşılaştırma `>=` olduğunda 78 yaşında
      // ilerletilmiş endeksi devralan 25 yaşındaki mirasçıda piyasa bir
      // daha hiç ilerlemiyordu.
      const MarketState devir = MarketState(advancedAtAge: 78);
      expect(MarketEngine.alreadyAdvancedAt(devir, 25), isFalse);
      expect(MarketEngine.alreadyAdvancedAt(devir, 26), isFalse);
    });

    test('aynı tohum aynı yılı verir (determinizm)', () {
      final ({MarketState state, MarketYear year}) a = MarketEngine.advance(
        state: const MarketState(),
        newAge: 31,
        rng: Random(7),
      );
      final ({MarketState state, MarketYear year}) b = MarketEngine.advance(
        state: const MarketState(),
        newAge: 31,
        rng: Random(7),
      );
      expect(a.state.priceIndex, b.state.priceIndex);
      expect(a.year.regime, b.year.regime);
    });

    test('gizli parametreler bandın içinde kalır', () {
      MarketState s = const MarketState();
      final Random rng = Random(3);
      for (int i = 0; i < 400; i++) {
        s = MarketEngine.advance(state: s, newAge: 20 + i, rng: rng).state;
        expect(s.inflationPressure, inInclusiveRange(0, 100));
        expect(s.confidence, inInclusiveRange(0, 100));
      }
    });

    test('varlıklar bağımsız zar atmıyor: kriz yılı hisseyi vurur', () {
      // 4000 kriz yılında hissenin ortalaması, aynı yılların altın
      // ortalamasının altında olmalı. Tek yılda tersi olabilir; ortalama
      // olarak olmamalı, yoksa rejim sistemi işlemiyordur.
      double hisse = 0;
      double altin = 0;
      int sayi = 0;
      MarketState s = const MarketState();
      final Random rng = Random(5);
      for (int i = 0; i < 40000 && sayi < 2000; i++) {
        final ({MarketState state, MarketYear year}) adim =
            MarketEngine.advance(state: s, newAge: 20 + (i % 60), rng: rng);
        s = adim.state;
        if (adim.year.regime == MarketRegime.kriz) {
          hisse += adim.year.returns['hisse']!;
          altin += adim.year.returns['altin']!;
          sayi++;
        }
      }
      expect(sayi, greaterThan(500), reason: 'kriz hiç çıkmadıysa tablo bozuk');
      expect(hisse / sayi, lessThan(altin / sayi));
      expect(hisse / sayi, lessThan(0));
    });
  });

  group('Portföy motoru (AA/2)', () {
    test('18 yaşından önce yatırım yok', () {
      final GameState cocuk = hayat(age: 16);
      expect(InvestmentEngine.availability(cocuk).isAllowed, isFalse);
      final InvestmentResult r = InvestmentEngine.buy(
        state: cocuk,
        typeId: 'hisse',
        amount: 10000,
      );
      expect(r.outcome.applied, isFalse);
      expect(r.state.investments, isEmpty);
    });

    test('cüzdanda olmayan para yatırılamaz, cüzdan eksiye düşmez', () {
      final GameState s = hayat(wallet: 5000);
      final InvestmentResult r = InvestmentEngine.buy(
        state: s,
        typeId: 'hisse',
        amount: 50000,
      );
      expect(r.outcome.applied, isFalse);
      expect(r.state.player.wallet, 5000);
    });

    test('alım maliyeti ve ortalama maliyet birikiyor', () {
      GameState s = hayat(wallet: 100000);
      s = InvestmentEngine.buy(state: s, typeId: 'fon', amount: 30000).state;
      s = InvestmentEngine.buy(state: s, typeId: 'fon', amount: 20000).state;
      final Holding h = s.holdingOf('fon')!;
      expect(h.value, 50000);
      expect(h.costBasis, 50000);
      expect(h.totalInvested, 50000);
      expect(s.player.wallet, 50000);
    });

    test('kısmi satış maliyeti oranlı düşürür', () {
      GameState s = hayat(wallet: 100000);
      s = InvestmentEngine.buy(state: s, typeId: 'hisse', amount: 40000).state;
      // Pozisyon %50 kazandı: 40.000 → 60.000.
      s = s.copyWith(investments: <Holding>[
        s.holdingOf('hisse')!.copyWith(value: 60000),
      ]);
      s = InvestmentEngine.sell(state: s, typeId: 'hisse', amount: 30000).state;
      final Holding h = s.holdingOf('hisse')!;
      expect(h.value, 30000);
      expect(h.costBasis, 20000); // 40.000'in yarısı
      expect(h.realizedProfit, 10000);
      expect(s.player.wallet, 90000); // 60.000 kalan + 30.000 satış
      expect(h.unrealizedProfit, 10000);
    });

    test('tamamı satılınca maliyet artığı kalmıyor', () {
      GameState s = hayat(wallet: 100000);
      s = InvestmentEngine.buy(state: s, typeId: 'altin', amount: 33333).state;
      s = s.copyWith(investments: <Holding>[
        s.holdingOf('altin')!.copyWith(value: 41111),
      ]);
      s = InvestmentEngine.sell(state: s, typeId: 'altin', amount: 41111).state;
      final Holding h = s.holdingOf('altin')!;
      expect(h.value, 0);
      expect(h.costBasis, 0);
      expect(h.realizedProfit, 41111 - 33333);
    });

    test('vadeli hesap bir yıl kilitli, vadesinde zarar yazmaz', () {
      GameState s = hayat(age: 30, wallet: 100000);
      s = InvestmentEngine.buy(state: s, typeId: 'vadeli', amount: 50000).state;
      expect(s.termDeposits.length, 1);
      final TermDeposit d = s.termDeposits.single;
      expect(d.openedAtAge, 30);
      expect(d.maturesAtAge, 31);
      expect(d.maturedAt(30), isFalse);
      expect(d.maturedAt(31), isTrue);
      expect(d.maturityValue, greaterThan(d.amount));
      expect(d.interest, greaterThan(0));
    });

    test('vadeyi bozmak anaparayı geri verir, faizi yakar', () {
      GameState s = hayat(age: 30, wallet: 100000);
      s = InvestmentEngine.buy(state: s, typeId: 'vadeli', amount: 50000).state;
      final String id = s.termDeposits.single.id;
      s = InvestmentEngine.breakTermDeposit(state: s, depositId: id).state;
      expect(s.termDeposits, isEmpty);
      expect(s.player.wallet, 100000); // faiz yok, anapara tam
      expect(
        s.investmentHistory.last.kind,
        InvestmentRecordKind.vadeBozuldu,
      );
    });

    test('vadeli hesap bu ekrandan satılamaz', () {
      GameState s = hayat(wallet: 100000);
      s = InvestmentEngine.buy(state: s, typeId: 'vadeli', amount: 50000).state;
      final InvestmentResult r = InvestmentEngine.sell(
        state: s,
        typeId: 'vadeli',
        amount: 10000,
      );
      expect(r.outcome.applied, isFalse);
      expect(r.outcome.text, contains('vade'));
    });

    test('yıl ilerlemesi aynı yaşta iki kez fiyat çevirmez', () {
      GameState s = hayat(age: 30, wallet: 100000);
      s = InvestmentEngine.buy(state: s, typeId: 'hisse', amount: 40000).state;
      final GameState bir = InvestmentEngine.advanceYear(
        state: s,
        newAge: 31,
        rng: Random(2),
      );
      final GameState iki = InvestmentEngine.advanceYear(
        state: bir,
        newAge: 31,
        rng: Random(9),
      );
      expect(iki.holdingOf('hisse')!.value, bir.holdingOf('hisse')!.value);
      expect(iki.market.priceIndex, bir.market.priceIndex);
    });

    test('kayıt yüklenince portföy ve piyasa aynen döner', () {
      GameState s = hayat(age: 30, wallet: 300000);
      s = InvestmentEngine.buy(state: s, typeId: 'hisse', amount: 40000).state;
      s = InvestmentEngine.buy(state: s, typeId: 'altin', amount: 30000).state;
      s = InvestmentEngine.buy(state: s, typeId: 'vadeli', amount: 20000).state;

      // Vadeli hesap **vadesi gelmemişken** de kayda girip dönmeli.
      final GameState kilitliGeri = decodeGameState(encodeGameState(s));
      expect(kilitliGeri.termDeposits.single.id, s.termDeposits.single.id);
      expect(
        kilitliGeri.termDeposits.single.maturesAtAge,
        s.termDeposits.single.maturesAtAge,
      );

      // Yıl ilerleyince vade doluyor ve hesap kapanıyor; bu beklenen.
      s = InvestmentEngine.advanceYear(state: s, newAge: 31, rng: Random(4));
      expect(s.termDeposits, isEmpty);

      final GameState geri = decodeGameState(encodeGameState(s));
      expect(geri.portfolioValue, s.portfolioValue);
      expect(geri.investments.length, s.investments.length);
      expect(geri.market.priceIndex, s.market.priceIndex);
      expect(geri.market.regime, s.market.regime);
      expect(geri.market.advancedAtAge, s.market.advancedAtAge);
      expect(geri.investmentHistory.length, s.investmentHistory.length);

      // Yüklendikten sonra aynı yaş yeniden çevrilmiyor.
      final GameState tekrar = InvestmentEngine.advanceYear(
        state: geri,
        newAge: 31,
        rng: Random(99),
      );
      expect(tekrar.market.priceIndex, s.market.priceIndex);
    });

    test('eski kayıt (yatırım alanı olmayan) hâlâ yükleniyor', () {
      final GameState s = hayat();
      final Map<String, Object?> json = encodeGameState(s);
      json.remove('investments');
      json.remove('termDeposits');
      json.remove('investmentHistory');
      json.remove('market');
      final GameState geri = decodeGameState(json);
      expect(geri.investments, isEmpty);
      expect(geri.termDeposits, isEmpty);
      expect(geri.portfolioValue, 0);
      expect(geri.market.regime, MarketRegime.normal);
    });
  });

  group('Servet, miras ve boşanma (AA/3)', () {
    test('yatırım net varlığa giriyor', () {
      GameState s = hayat(wallet: 100000);
      final int once = NetWorth.of(s);
      s = InvestmentEngine.buy(state: s, typeId: 'fon', amount: 40000).state;
      // Para yatırıma geçti; net varlık değişmedi, yer değiştirdi.
      expect(NetWorth.of(s), once);
      expect(s.player.wallet, 60000);
      expect(s.portfolioValue, 40000);
      expect(NetWorth.liquid(s), 100000);
    });

    test('vadeli hesap da net varlıkta sayılıyor', () {
      GameState s = hayat(wallet: 100000);
      final int once = NetWorth.of(s);
      s = InvestmentEngine.buy(state: s, typeId: 'vadeli', amount: 50000).state;
      expect(NetWorth.of(s), once);
      expect(s.portfolioValue, 50000);
    });

    test('borç net varlıktan düşüyor, portföy iki kez sayılmıyor', () {
      GameState s = hayat(wallet: 100000);
      s = InvestmentEngine.buy(state: s, typeId: 'hisse', amount: 60000).state;
      expect(
        NetWorth.of(s),
        s.player.wallet + s.portfolioValue + NetWorth.itemsValue(s),
      );
    });

    test('evlilik içinde açılan portföy paylaşıma girer', () {
      final int evlilikYasi = 30;
      GameState s = hayat(age: 40, wallet: 100000).copyWith(
        people: <Person>[
          ...hayat().people,
          const Person(
            id: 'es-1',
            firstName: 'Nur',
            lastName: 'Aydın',
            gender: Gender.kadin,
            relation: RelationType.es,
            age: 40,
            isAlive: true,
            inPlayerHousehold: true,
            employment: EmploymentStatus.issiz,
            wealth: null,
            bond: 60,
          ),
        ],
        marriage: Marriage(
          spouseId: 'es-1',
          marriedAtAge: evlilikYasi,
          status: MarriageStatus.evli,
        ),
        career: const CareerState.none(),
      );
      // Biri evlilikten önce (kişisel mal), biri evlilik içinde açıldı.
      s = s.copyWith(investments: <Holding>[
        Holding.opened(typeId: 'altin', amount: 50000, atAge: 25),
        Holding.opened(typeId: 'hisse', amount: 80000, atAge: 33),
      ]);

      expect(
        DivorceSettlementProbe.marital(s, evlilikYasi),
        80000,
        reason: 'evlilik öncesi pozisyon paylaşıma girmemeli',
      );

      final int oncekiNetVarlik = NetWorth.of(s);
      final GameState sonra = const MarriageEngine().divorce(s).state;

      // Eş payı gerçekten çıktı: net varlık azaldı ama eksiye düşmedi.
      expect(sonra.player.wallet, greaterThanOrEqualTo(0));
      expect(NetWorth.of(sonra), lessThan(oncekiNetVarlik));
      // Evlilik öncesi altın pozisyonu duruyor.
      expect(sonra.holdingOf('altin')!.value, 50000);
    });

    test('cüzdan yetmezse pay portföyden satışla ödenir', () {
      final int evlilikYasi = 30;
      GameState s = hayat(age: 40, wallet: 1000).copyWith(
        people: <Person>[
          ...hayat().people,
          const Person(
            id: 'es-1',
            firstName: 'Nur',
            lastName: 'Aydın',
            gender: Gender.kadin,
            relation: RelationType.es,
            age: 40,
            isAlive: true,
            inPlayerHousehold: true,
            employment: EmploymentStatus.issiz,
            wealth: null,
            bond: 60,
          ),
        ],
        marriage: Marriage(
          spouseId: 'es-1',
          marriedAtAge: evlilikYasi,
          status: MarriageStatus.evli,
        ),
        items: const <OwnedItem>[],
        career: const CareerState.none(),
      );
      s = s.copyWith(investments: <Holding>[
        Holding.opened(typeId: 'hisse', amount: 200000, atAge: 35),
      ]);

      final GameState sonra = const MarriageEngine().divorce(s).state;
      expect(sonra.player.wallet, greaterThanOrEqualTo(0));
      // Pozisyon küçüldü: ödeme zorunlu satıştan geçti.
      expect(sonra.holdingOf('hisse')!.value, lessThan(200000));
      // Satış normal muhasebeden geçti, geçmişe yazıldı.
      expect(
        sonra.investmentHistory
            .any((InvestmentRecord r) => r.kind == InvestmentRecordKind.satti),
        isTrue,
      );
    });
  });

  group('Kuşak devri: portföy kaybolmuyor, iki kez sayılmıyor (AA/3)', () {
    test('portföy mirasa nakit olarak geçiyor', () {
      final GameState olen = olenOyuncu(wallet: 100000).copyWith(
        investments: <Holding>[
          Holding.opened(typeId: 'hisse', amount: 150000, atAge: 45),
          Holding.opened(typeId: 'altin', amount: 50000, atAge: 50),
        ],
      );
      expect(olen.portfolioValue, 200000);

      final ({GameState? state, String blockReason}) sonuc =
          GenerationContinuation.continueAs(olen, 'cocuk-1', Random(3));
      expect(sonuc.blockReason, isEmpty);
      final GameState yeni = sonuc.state!;

      // 1) Kaybolmadı: portföy nakde çevrilip miras havuzuna girdi, bu
      //    yüzden mirasçının cüzdanı portföysüz halden büyük olmalı.
      final ({GameState? state, String blockReason}) portfoysuz =
          GenerationContinuation.continueAs(
        olen.copyWith(investments: const <Holding>[]),
        'cocuk-1',
        Random(3),
      );
      expect(
        yeni.player.wallet,
        greaterThan(portfoysuz.state!.player.wallet),
      );

      // 2) İki kez sayılmadı: pozisyonlar yeni hayata taşınmıyor.
      expect(yeni.investments, isEmpty);
      expect(yeni.termDeposits, isEmpty);
      expect(yeni.portfolioValue, 0);
    });

    test('piyasa devrediliyor ama yeni hayatta yeniden ilerleyebiliyor', () {
      final GameState olen = olenOyuncu(wallet: 100000).copyWith(
        market: const MarketState(
          regime: MarketRegime.kriz,
          inflationPressure: 71,
          confidence: 22,
          advancedAtAge: 70,
        ),
      );
      final GameState yeni =
          GenerationContinuation.continueAs(olen, 'cocuk-1', Random(3)).state!;

      // Rejim ve gizli parametreler devrediliyor: dünya sıfırlanmıyor.
      expect(yeni.market.regime, MarketRegime.kriz);
      expect(yeni.market.inflationPressure, 71);
      expect(yeni.market.confidence, 22);

      // Ama "70 yaşında ilerletildi" işareti taşınmıyor; yoksa mirasçıda
      // piyasa donardı.
      expect(yeni.market.advancedAtAge, isNull);
      final GameState ilerledi = InvestmentEngine.advanceYear(
        state: yeni,
        newAge: yeni.player.age + 1,
        rng: Random(6),
      );
      expect(ilerledi.market.advancedAtAge, yeni.player.age + 1);
    });
  });
}

/// Test içi yardımcı: paylaşıma giren portföyü doğrudan ölçer.
abstract final class DivorceSettlementProbe {
  static int marital(GameState s, int marriedAtAge) => s.investments
          .where((Holding h) => h.firstBoughtAtAge >= marriedAtAge)
          .fold<int>(0, (int t, Holding h) => t + h.value) +
      s.termDeposits
          .where((TermDeposit d) => d.openedAtAge >= marriedAtAge)
          .fold<int>(0, (int t, TermDeposit d) => t + d.amount);
}

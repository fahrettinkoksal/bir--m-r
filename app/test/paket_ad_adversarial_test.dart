// Paket AD — saldırgan oyuncu taraması (§27).
//
// Paket AC'de on iki saldırı yolu denenmiş ve exploit bulunmamıştı. Paket
// AD dört yeni sistem getirdi (borç yaşam döngüsü, şirket sağlığı, olay
// portföy hamleleri, lüks varlıklar); bu dosya **onlara** saldırıyor.
//
// Kural: bütün saldırılar `GameController`'ın gerçek public yollarından
// geçiyor. `debugSetState` yalnızca saldırının başlangıç koşulunu kurmak
// için kullanılıyor, saldırıyı kolaylaştırmak için değil.
// ignore_for_file: avoid_print
library;

import 'package:bir_omur/data/save/game_state_codec.dart';
import 'package:bir_omur/domain/economy/banking.dart';
import 'package:bir_omur/domain/economy/investment_engine.dart';
import 'package:bir_omur/domain/economy/net_worth.dart';
import 'package:bir_omur/domain/generation/life_generator.dart';
import 'package:bir_omur/domain/models/game_event.dart';
import 'package:bir_omur/domain/models/game_state.dart';
import 'package:bir_omur/domain/models/investment.dart';
import 'package:bir_omur/domain/models/market_incident.dart';
import 'package:bir_omur/domain/models/loan.dart';
import 'package:bir_omur/domain/models/owned_item.dart';
import 'package:flutter_test/flutter_test.dart';

GameState _hayat({int wallet = 0, int age = 35}) {
  final GameState s =
      LifeGenerator.seeded(77).generate(mode: StartMode.tamamenRastgele);
  return s.copyWith(player: s.player.copyWith(wallet: wallet, age: age));
}

Loan _kredi({int outstanding = 300000, int missedStreak = 0}) => Loan(
      id: 'L1',
      bank: Bank.bankavrupa,
      principal: 300000,
      annualPayment: 120000,
      termYears: 3,
      remainingPayments: 3,
      outstanding: outstanding,
      originalDebt: 300000,
      takenAtAge: 30,
      missedStreak: missedStreak,
    );

void main() {
  group('Paket AD — saldırgan oyuncu (§27)', () {
    test('EXPLOIT DENEMESI: yapılandırmayı tekrar tekrar tetiklemek', () {
      // Saldırı: borcu hiç ödemeyip her seferinde yapılandırma alarak
      // taksiti sonsuza kadar düşürmek ve borcu ölümsüzleştirmek.
      GameState s = _hayat().copyWith(
        loans: <Loan>[_kredi()],
        items: const <OwnedItem>[],
      );
      int yapilandirma = 0;
      for (int y = 0; y < 40; y++) {
        final r = Banking.advanceYear(s);
        s = r.state;
        s = s.copyWith(player: s.player.copyWith(age: s.player.age + 1));
        yapilandirma = s.loans.first.restructures;
        if (s.loans.first.isClosed) break;
      }
      print('40 yil hic odemeyen: yapilandirma $yapilandirma · '
          'kapandi ${s.loans.first.isClosed} · '
          'borc ${s.loans.first.outstanding}');
      expect(yapilandirma, lessThanOrEqualTo(Banking.prototypeOnlyMaxRestructures),
          reason: 'Yapilandirma sinirsiz; borc olumsuzlestirilebiliyor');
      expect(s.loans.first.isClosed, isTrue);
    });

    test('EXPLOIT DENEMESI: malı satıp borcu iki kez kapatmak', () {
      // Saldırı: tahsil sırasında satılan malın parası hem borca gitsin
      // hem cüzdanda kalsın.
      GameState s = _hayat(wallet: 0).copyWith(
        loans: <Loan>[_kredi(missedStreak: 1)],
        items: <OwnedItem>[
          const OwnedItem(
            id: 'arac-1',
            typeId: 'otomobil_binek',
            acquiredAtAge: 30,
            purchasePrice: 600000,
          ),
        ],
      );
      final int onceServet = NetWorth.of(s);
      final int onceBorc = NetWorth.debt(s);
      final r = Banking.advanceYear(s);
      final GameState sonra = r.state;
      final int sonraServet = NetWorth.of(sonra);
      print('Tahsil: servet $onceServet -> $sonraServet · '
          'borc $onceBorc -> ${NetWorth.debt(sonra)} · '
          'mal ${s.items.length} -> ${sonra.items.length} · '
          'cuzdan ${sonra.player.wallet}');
      // Mal satıldıysa net servet ARTMAMALI: zorla satış zarar ettirir.
      expect(sonraServet, lessThanOrEqualTo(onceServet),
          reason: 'Zorunlu tahsil net serveti artirdi; para iki kez sayiliyor');
      expect(sonra.player.wallet, greaterThanOrEqualTo(0));
    });

    test('EXPLOIT DENEMESI: kayıt/yükleme ile borç durumunu sıfırlamak', () {
      GameState s = _hayat().copyWith(
        loans: <Loan>[_kredi()],
        items: const <OwnedItem>[],
      );
      for (int y = 0; y < 4; y++) {
        s = Banking.advanceYear(s).state;
        s = s.copyWith(player: s.player.copyWith(age: s.player.age + 1));
      }
      final Loan once = s.loans.first;
      // Saldırı: kaydı yazıp geri yükle, sonra yılı yeniden ilerlet.
      final GameState kayitli = decodeGameState(encodeGameState(s));
      final Loan a = Banking.advanceYear(s).state.loans.first;
      final Loan b = Banking.advanceYear(kayitli).state.loans.first;
      print('Kayit sonrasi: borc ${once.outstanding} · '
          'seri ${once.missedStreak} · yapilandirma ${once.restructures}');
      expect(b.outstanding, a.outstanding);
      expect(b.missedStreak, a.missedStreak);
      expect(b.restructures, a.restructures);
      expect(b.missedPayments, a.missedPayments);
    });

    test('EXPLOIT DENEMESI: olay hamlesiyle işlem durmasını delmek', () {
      // Saldırı: işlem durmuşken olay seçeneğiyle satmak.
      final GameState s = _hayat(wallet: 100000).copyWith(
        investments: <Holding>[
          const Holding.opened(typeId: 'hisse', amount: 500000, atAge: 30),
        ],
        market: _hayat().market.copyWith(
          halts: <TradingHalt>[
            const TradingHalt(typeId: 'hisse', untilAge: 99, reason: 'test'),
          ],
        ),
      );
      final GameState sonra = InvestmentEngine.applyEventAction(
        s,
        action: PortfolioAction.satKismi,
        typeId: 'hisse',
        share: 0.9,
      );
      print('Islem durmusken olay hamlesi: portfoy ${s.portfolioValue} -> '
          '${sonra.portfolioValue}');
      expect(sonra.portfolioValue, s.portfolioValue,
          reason: 'Kapali sira olay hamlesiyle delindi');
      expect(sonra.player.wallet, s.player.wallet);
    });

    test('EXPLOIT DENEMESI: olay hamlesini komisyonsuz al-sat döngüsü yapmak',
        () {
      // Saldırı: aynı yıl içinde olay hamlesiyle alıp satarak bedava
      // işlem yapmak.
      GameState s = _hayat(wallet: 1000000).copyWith(
        investments: <Holding>[
          const Holding.opened(typeId: 'hisse', amount: 500000, atAge: 30),
        ],
      );
      final int basla = NetWorth.of(s);
      for (int i = 0; i < 20; i++) {
        s = InvestmentEngine.applyEventAction(
          s,
          action: PortfolioAction.satKismi,
          typeId: 'hisse',
          share: 0.3,
        );
        s = InvestmentEngine.applyEventAction(
          s,
          action: PortfolioAction.alKismi,
          typeId: 'hisse',
          share: 0.3,
        );
      }
      final int son = NetWorth.of(s);
      print('Olay hamlesi al-sat 20 tur: $basla -> $son '
          '(fark ${son - basla})');
      expect(son, lessThan(basla),
          reason: 'Olay hamlesiyle al-sat dongusu para kazandiriyor');
    });

    test('EXPLOIT DENEMESI: lüks varlığı alıp satarak para üretmek', () {
      // Saldırı: lüks eşyayı katalog değerinden alıp aynı değerden satmak.
      // `DivorceSettlement.valueOf` satın alma fiyatını okuyor; satış
      // yolunun kayıp üretmesi gerekiyor.
      final GameState s = _hayat(wallet: 0).copyWith(
        loans: <Loan>[_kredi(missedStreak: 1)],
        items: <OwnedItem>[
          const OwnedItem(
            id: 'tekne-1',
            typeId: 'tekne_motoryat',
            acquiredAtAge: 30,
            purchasePrice: 38000000,
          ),
        ],
      );
      final int once = NetWorth.of(s);
      final GameState sonra = Banking.advanceYear(s).state;
      print('Luks zorunlu satis: net servet $once -> ${NetWorth.of(sonra)}');
      expect(NetWorth.of(sonra), lessThan(once),
          reason: 'Luks varligi zorla satmak servet kaybettirmiyor; '
              'zorunlu satis bedava cikis yolu olur');
    });

    test('EXPLOIT DENEMESI: kredi notu izini kayıtla temizlemek', () {
      GameState s = _hayat().copyWith(
        loans: <Loan>[_kredi()],
        items: const <OwnedItem>[],
      );
      for (int y = 0; y < 14; y++) {
        s = Banking.advanceYear(s).state;
        s = s.copyWith(player: s.player.copyWith(age: s.player.age + 1));
      }
      expect(s.loans.first.writtenOff, isTrue);
      final int iz = Banking.missedPayments(s);
      final GameState kayitli = decodeGameState(encodeGameState(s));
      print('Zarar yazildiktan sonra kredi notu izi: $iz · '
          'kayittan sonra ${Banking.missedPayments(kayitli)}');
      expect(Banking.missedPayments(kayitli), iz,
          reason: 'Kredi notu izi kayit/yukleme ile siliniyor');
      expect(iz, greaterThan(0));
    });

    test('EXPLOIT DENEMESI: şirket durumunu kayıtla yeniden çevirmek', () {
      // Şirket sağlığı `paket_ad_company_test` içinde de deneniyor; burada
      // tam oyun durumu üzerinden.
      GameState s = _hayat();
      for (int y = 0; y < 30; y++) {
        s = InvestmentEngine.advanceYear(state: s, newAge: s.player.age + y);
      }
      final GameState kayitli = decodeGameState(encodeGameState(s));
      expect(kayitli.market.companyStatus, s.market.companyStatus);
      expect(kayitli.market.riskTide, s.market.riskTide);
      expect(kayitli.market.valuationHeat, s.market.valuationHeat);
      print('30 yil sonra sirket durumu kayittan aynen cikti: '
          '${s.market.companyStatus.length} sirket');
    });
  });
}

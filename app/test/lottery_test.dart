import 'dart:math';

import 'package:bir_omur/data/lottery_catalog.dart';
import 'package:bir_omur/data/save/game_state_codec.dart';
import 'package:bir_omur/domain/casino/lottery.dart';
import 'package:bir_omur/domain/generation/life_generator.dart';
import 'package:bir_omur/domain/models/game_settings.dart';
import 'package:bir_omur/domain/models/game_state.dart';
import 'package:bir_omur/domain/models/lottery_ticket.dart';
import 'package:bir_omur/domain/models/pending_notice.dart';
import 'package:flutter_test/flutter_test.dart';

GameState hayat({int age = 30, int wallet = 100000}) {
  final GameState taban =
      LifeGenerator.seeded(5).generate(mode: StartMode.tamamenRastgele);
  return taban.copyWith(
    pendingEvent: null,
    notices: const <PendingNotice>[],
    player: taban.player.copyWith(age: age, wallet: wallet),
  );
}

void main() {
  group('Katalog', () {
    test('ikramiyeler büyükten küçüğe sıralı ve ihtimaller artıyor', () {
      for (final LotteryDraw draw in LotteryDraw.values) {
        for (int i = 1; i < draw.prizes.length; i++) {
          expect(
            draw.prizes[i].fullTicketAmount,
            lessThan(draw.prizes[i - 1].fullTicketAmount),
            reason: '${draw.label}: ${draw.prizes[i].label}',
          );
          expect(
            draw.prizes[i].oneIn,
            lessThan(draw.prizes[i - 1].oneIn),
            reason: 'Küçük ikramiye daha sık çıkmalı',
          );
        }
      }
    });

    test('kasanın payı bilerek büyük ama biletin tamamını yemiyor', () {
      // Faho\'nun kararı: "kumarda fark kasıtlı olsun, genel kumar kuralı
      // neyse öyle olsun". Gerçek piyangolarda geri dönüş yaklaşık yarıdır.
      for (final LotteryDraw draw in LotteryDraw.values) {
        expect(draw.returnRatio, greaterThan(0.4),
            reason: '${draw.label}: geri dönüş çok düşük');
        expect(draw.returnRatio, lessThan(0.7),
            reason: '${draw.label}: piyango bu kadar cömert olmaz');
        expect(draw.houseEdge, greaterThan(0.3));
      }
    });

    test('piyangonun payı kumarhaneden büyüktür', () {
      // Rulette kasa payı ~%2,7, at yarışında %12; piyango en pahalısıdır.
      for (final LotteryDraw draw in LotteryDraw.values) {
        expect(draw.houseEdge, greaterThan(0.12));
      }
    });

    test('amorti bilet parasını geri verir', () {
      for (final LotteryDraw draw in LotteryDraw.values) {
        final LotteryPrize amorti = draw.prizes.last;
        expect(amorti.label, 'Amorti');
        expect(amorti.fullTicketAmount, draw.fullTicketPrice);
      }
    });

    test('pay oranı fiyata da ikramiyeye de aynı uygulanır', () {
      for (final LotteryDraw draw in LotteryDraw.values) {
        expect(
          draw.priceFor(TicketShare.ceyrek) * 4,
          draw.fullTicketPrice,
        );
        expect(
          draw.priceFor(TicketShare.yarim) * 2,
          draw.fullTicketPrice,
        );
      }
    });

    test('yılbaşı çekilişi olağandan büyük', () {
      expect(
        LotteryDraw.yilbasi.prizes.first.fullTicketAmount,
        greaterThan(LotteryDraw.aylik.prizes.first.fullTicketAmount),
      );
      expect(
        LotteryDraw.yilbasi.fullTicketPrice,
        greaterThan(LotteryDraw.aylik.fullTicketPrice),
      );
    });
  });

  group('Bilet almak', () {
    test('ücret düşer ve bilet listeye girer', () {
      final GameState s = hayat();
      final ({GameState state, bool applied, String text}) r = Lottery.buy(
        state: s,
        draw: LotteryDraw.aylik,
        share: TicketShare.ceyrek,
        rng: Random(1),
      );
      expect(r.applied, isTrue);
      expect(
        r.state.player.wallet,
        s.player.wallet - LotteryDraw.aylik.priceFor(TicketShare.ceyrek),
      );
      expect(r.state.lotteryTickets, hasLength(1));
      expect(r.state.lotteryTickets.first.number, hasLength(6));
      expect(r.state.wagerThisAge, greaterThan(0),
          reason: 'Piyango da yıllık bahis kaydına girmeli');
    });

    test('parası yetmeyen bilet alamaz', () {
      final GameState s = hayat(wallet: 10);
      final ({GameState state, bool applied, String text}) r = Lottery.buy(
        state: s,
        draw: LotteryDraw.yilbasi,
        share: TicketShare.tam,
        rng: Random(1),
      );
      expect(r.applied, isFalse);
      expect(r.state.lotteryTickets, isEmpty);
      expect(r.state.player.wallet, 10);
    });

    test('çocuğa bilet satılmaz', () {
      final GameState s = hayat(age: 12);
      expect(
        Lottery.availability(s, LotteryDraw.aylik, TicketShare.tam).isAllowed,
        isFalse,
      );
    });

    test('kumar ayarı kapalıyken bilet satılmaz', () {
      final GameState s = hayat().copyWith(
        settings: const GameSettings(casinoEnabled: false),
      );
      expect(
        Lottery.availability(s, LotteryDraw.aylik, TicketShare.tam).isAllowed,
        isFalse,
      );
    });

    test('yıllık bilet sınırı vardır', () {
      GameState s = hayat(wallet: 10000000);
      for (int i = 0; i < LotteryDraw.aylik.maxTicketsPerAge; i++) {
        s = Lottery.buy(
          state: s,
          draw: LotteryDraw.aylik,
          share: TicketShare.ceyrek,
          rng: Random(i),
        ).state;
      }
      expect(
        Lottery.availability(s, LotteryDraw.aylik, TicketShare.tam).isAllowed,
        isFalse,
      );
      // Yılbaşı çekilişi ayrı sayılır.
      expect(
        Lottery
            .availability(s, LotteryDraw.yilbasi, TicketShare.tam)
            .isAllowed,
        isTrue,
      );
    });
  });

  group('Çekiliş', () {
    test('biletler tükenir ve bildirim gelir', () {
      GameState s = hayat(wallet: 100000);
      s = Lottery.buy(
        state: s,
        draw: LotteryDraw.aylik,
        share: TicketShare.tam,
        rng: Random(2),
      ).state;

      final GameState sonra = Lottery.drawAll(s, 31, Random(3));
      expect(sonra.lotteryTickets, isEmpty);
      expect(
        sonra.notices.any((PendingNotice n) => n.kind == NoticeKind.piyango),
        isTrue,
      );
      expect(sonra.log.last.text, contains('Piyango'));
    });

    test('bilet yoksa çekiliş hiçbir şey yapmaz', () {
      final GameState s = hayat();
      expect(identical(Lottery.drawAll(s, 31, Random(1)), s), isTrue);
    });

    test('çeyrek bilet ikramiyenin dörtte birini alır', () {
      // Aynı tohumla aynı basamak kazanılır; yalnızca pay farklıdır.
      int kazanc(TicketShare share, int seed) {
        GameState s = hayat(wallet: 10000000);
        s = Lottery.buy(
          state: s,
          draw: LotteryDraw.aylik,
          share: share,
          rng: Random(99),
        ).state;
        final int once = s.player.wallet;
        return Lottery.drawAll(s, 31, Random(seed)).player.wallet - once;
      }

      for (int seed = 0; seed < 40; seed++) {
        final int tam = kazanc(TicketShare.tam, seed);
        if (tam <= 0) continue;
        expect(kazanc(TicketShare.ceyrek, seed), (tam * 0.25).round());
        expect(kazanc(TicketShare.yarim, seed), (tam * 0.5).round());
        return;
      }
      fail('Hiç kazanan bilet çıkmadı');
    });

    test('uzun vadede oyuncu kaybeder', () {
      // Ölçüm: 20.000 tam bilet. Piyango uzun vadede kazandırmaz.
      const LotteryDraw draw = LotteryDraw.aylik;
      final Random rng = Random(7);
      int odenen = 0;
      int kazanilan = 0;
      GameState s = hayat(wallet: 1000000000);
      for (int i = 0; i < 20000; i++) {
        s = s.copyWith(
          lotteryTickets: <LotteryTicket>[
            LotteryTicket(
              drawId: draw.id,
              share: TicketShare.tam,
              number: '000000',
              boughtAtAge: 30,
              price: draw.fullTicketPrice,
            ),
          ],
          notices: const <PendingNotice>[],
        );
        odenen += draw.fullTicketPrice;
        final int once = s.player.wallet;
        s = Lottery.drawAll(s, 30, rng);
        kazanilan += s.player.wallet - once;
      }
      final double oran = kazanilan / odenen;
      // Kuramsal geri dönüş ~%56; 20.000 bilette büyük ikramiyeler
      // (1/500.000) genelde hiç çıkmadığı için ölçülen oran daha düşük
      // kalır. İkisi de 1'in altındadır: piyango kazandırmaz.
      // ignore: avoid_print
      print('Kuramsal: ${(draw.returnRatio * 100).toStringAsFixed(1)}% · '
          'ölçülen (20.000 bilet): ${(oran * 100).toStringAsFixed(1)}%');
      expect(oran, lessThan(1.0));
    });
  });

  test('biletler kayda girer ve geri yüklenir', () {
    GameState s = hayat(wallet: 100000);
    s = Lottery.buy(
      state: s,
      draw: LotteryDraw.yilbasi,
      share: TicketShare.yarim,
      rng: Random(4),
    ).state;

    final GameState geri = decodeGameState(encodeGameState(s));
    expect(geri.lotteryTickets, hasLength(1));
    expect(geri.lotteryTickets.first.number, s.lotteryTickets.first.number);
    expect(geri.lotteryTickets.first.share, TicketShare.yarim);
    expect(geri.lotteryTickets.first.price, s.lotteryTickets.first.price);
  });

  test('eski kayıtta bilet alanı yoksa boş okunur', () {
    final Map<String, Object?> json =
        Map<String, Object?>.from(encodeGameState(hayat()));
    json.remove('lotteryTickets');
    expect(decodeGameState(json).lotteryTickets, isEmpty);
  });
}

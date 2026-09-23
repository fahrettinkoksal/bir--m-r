import 'dart:math';

import '../../data/lottery_catalog.dart';
import '../../text/turkish_text.dart';
import '../models/game_state.dart';
import '../models/interaction.dart';
import '../models/life_log.dart';
import '../models/lottery_ticket.dart';
import '../models/pending_notice.dart';
import '../models/player_character.dart';

/// Milli Piyango (Paket 33).
///
/// Bilet yıl içinde alınır, çekiliş **yaş ilerlerken** yapılır ve sonuç
/// bildirim panelinde gösterilir. Bilet kayda girer; uygulama kapansa da
/// çekiliş kaybolmaz.
///
/// **Gerçek para yoktur**; oyunun sanal cüzdanıyla çalışır.
///
/// Sayısal değerler `prototypeOnly`'dir
/// (`docs/DESIGN_REVIEW_QUEUE.md`, Q-101).
abstract final class Lottery {
  /// Bu yıl bu çekiliş için kaç bilet alındı?
  static int ticketsThisAge(GameState state, LotteryDraw draw) {
    int n = 0;
    for (final LotteryTicket t in state.lotteryTickets) {
      if (t.drawId == draw.id && t.boughtAtAge == state.player.age) n++;
    }
    return n;
  }

  /// Bilet alınabilir mi?
  static InteractionAvailability availability(
    GameState state,
    LotteryDraw draw,
    TicketShare share,
  ) {
    if (!state.settings.casinoEnabled) {
      // Kumar kapalıyken piyango da kapalıdır; iki ayrı kapı olmaz.
      return const InteractionAvailability.blocked(
        'Ayarlardan kumar kapatıldı; bilet satılmıyor.',
      );
    }
    if (state.player.age < kLotteryMinAge) {
      return const InteractionAvailability.blocked(
        '$kLotteryMinAge yaşından küçüklere bilet satılmaz.',
      );
    }
    if (ticketsThisAge(state, draw) >= draw.maxTicketsPerAge) {
      return InteractionAvailability.blocked(
        'Bu yıl ${trLower(draw.label)} için yeterince bilet aldın.',
      );
    }
    final int fiyat = draw.priceFor(share);
    if (state.player.wallet < fiyat) {
      return InteractionAvailability.blocked(
        '${trMoney(fiyat)} gerekiyor; cüzdanında yeterli para yok.',
      );
    }
    return const InteractionAvailability.allowed();
  }

  /// Bilet alır.
  static ({GameState state, bool applied, String text}) buy({
    required GameState state,
    required LotteryDraw draw,
    required TicketShare share,
    required Random rng,
  }) {
    final InteractionAvailability check = availability(state, draw, share);
    if (!check.isAllowed) {
      return (state: state, applied: false, text: check.reason!);
    }

    final int fiyat = draw.priceFor(share);
    final LotteryTicket bilet = LotteryTicket(
      drawId: draw.id,
      share: share,
      number: _numara(rng),
      boughtAtAge: state.player.age,
      price: fiyat,
    );

    final GameState next = state.copyWith(
      player: state.player.copyWith(
        wallet: state.player.wallet - fiyat,
      ),
      lotteryTickets: List<LotteryTicket>.unmodifiable(<LotteryTicket>[
        ...state.lotteryTickets,
        bilet,
      ]),
      // Piyango da kumardır: yıllık bahis kaydına girer.
      wagerThisAge: state.wagerThisAge + fiyat,
    );

    return (
      state: next,
      applied: true,
      text: '${draw.label} için ${trLower(share.label)} aldın. '
          'Numaran ${bilet.number}. Çekiliş yıl sonunda.',
    );
  }

  /// Bekleyen bütün biletlerin çekilişini yapar.
  ///
  /// Yaş ilerlerken çağrılır. Biletler tüketilir; kazanç cüzdana girer ve
  /// sonuç bildirim paneline düşer.
  static GameState drawAll(GameState state, int newAge, Random rng) {
    if (state.lotteryTickets.isEmpty) return state;

    final List<LotteryResult> sonuclar = <LotteryResult>[];
    for (final LotteryTicket bilet in state.lotteryTickets) {
      sonuclar.add(_cek(bilet, rng));
    }

    final int toplam = sonuclar.fold<int>(
      0,
      (int acc, LotteryResult r) => acc + r.amount,
    );

    final PlayerCharacter player = state.player.copyWith(
      wallet: state.player.wallet + toplam,
    );

    GameState next = state.copyWith(
      player: player,
      lotteryTickets: const <LotteryTicket>[],
    );

    next = next.copyWith(
      log: List<LifeLogEntry>.unmodifiable(<LifeLogEntry>[
        ...next.log,
        LifeLogEntry(
          age: newAge,
          text: _gunlukMetni(sonuclar, toplam),
          category: LogCategory.kisisel,
        ),
      ]),
      notices: List<PendingNotice>.unmodifiable(<PendingNotice>[
        ...next.notices,
        _bildirim(sonuclar, toplam, newAge),
      ]),
    );

    return next;
  }

  static LotteryResult _cek(LotteryTicket bilet, Random rng) {
    final LotteryDraw? draw = bilet.draw;
    if (draw == null) {
      return LotteryResult(ticket: bilet, prizeLabel: '', amount: 0);
    }
    final double u = rng.nextDouble();
    double esik = 0;
    // En büyükten en küçüğe: ilk tutan basamak kazanılır.
    for (final LotteryPrize p in draw.prizes) {
      esik += p.chance;
      if (u < esik) {
        return LotteryResult(
          ticket: bilet,
          prizeLabel: p.label,
          amount: (p.fullTicketAmount * bilet.share.ratio).round(),
        );
      }
    }
    return LotteryResult(ticket: bilet, prizeLabel: '', amount: 0);
  }

  static String _gunlukMetni(List<LotteryResult> sonuclar, int toplam) {
    final int adet = sonuclar.length;
    if (toplam <= 0) {
      return 'Piyango çekildi: $adet biletin de tutmadı.';
    }
    final LotteryResult enBuyuk = sonuclar.reduce(
      (LotteryResult a, LotteryResult b) => b.amount > a.amount ? b : a,
    );
    return 'Piyango çekildi: ${enBuyuk.prizeLabel} kazandın. '
        'Toplam ${trMoney(toplam)} aldın.';
  }

  static PendingNotice _bildirim(
    List<LotteryResult> sonuclar,
    int toplam,
    int age,
  ) {
    final List<LotteryResult> kazananlar = sonuclar
        .where((LotteryResult r) => r.won)
        .toList(growable: false);

    final String metin;
    if (kazananlar.isEmpty) {
      metin = sonuclar.length == 1
          ? 'Biletin tutmadı. Numaran ${sonuclar.first.number} idi.'
          : '${sonuclar.length} biletin de tutmadı.';
    } else {
      final StringBuffer sb = StringBuffer();
      for (final LotteryResult r in kazananlar) {
        sb.writeln(
          '${r.ticket.number} · ${r.ticket.share.label}: '
          '${r.prizeLabel} — ${trMoney(r.amount)}',
        );
      }
      metin = sb.toString().trim();
    }

    return PendingNotice(
      id: 'piyango-$age',
      kind: NoticeKind.piyango,
      age: age,
      title: kazananlar.isEmpty ? 'Piyango çekildi' : 'Biletin tuttu!',
      text: metin,
      money: toplam,
    );
  }

  static String _numara(Random rng) {
    final StringBuffer sb = StringBuffer();
    for (int i = 0; i < 6; i++) {
      sb.write(rng.nextInt(10));
    }
    return sb.toString();
  }
}

extension on LotteryResult {
  String get number => ticket.number;
}

import 'dart:math';

import '../models/blackjack_game.dart';
import '../models/game_state.dart';
import '../models/interaction.dart';
import '../models/life_log.dart';
import '../models/playing_card.dart';
import 'casino_rules.dart';

/// Bir kumarhane işleminin sonucu.
class CasinoOutcome {
  const CasinoOutcome({
    required this.applied,
    required this.text,
    this.walletDelta = 0,
  });

  final bool applied;
  final String text;

  /// İşlemin cüzdana net etkisi (eksi olabilir).
  final int walletDelta;
}

class CasinoResult {
  const CasinoResult({required this.state, required this.outcome});

  final GameState state;
  final CasinoOutcome outcome;
}

/// Küçük ama gerçekten oynanabilir blackjack.
///
/// - Standart 52 kartlık deste; deste el boyunca **kaydedilir**, böylece
///   oyun kapatılıp açıldığında aynı el aynı kartlarla sürer.
/// - Bahis el başlarken cüzdandan **bir kez** düşülür.
/// - Ödeme el bitince **bir kez** yapılır ([BlackjackGame.settled]).
/// - Krupiye [CasinoRules.dealerStandsOn] ve üstünde durur.
class Blackjack {
  const Blackjack();

  /// Yeni el açılabilir mi?
  InteractionAvailability dealAvailability(GameState state, int bet) {
    final InteractionAvailability temel = CasinoAccess.check(state);
    if (!temel.isAllowed) return temel;
    if (state.blackjack != null) {
      return const InteractionAvailability.blocked(
        'Masada devam eden bir elin var.',
      );
    }
    return CasinoAccess.checkBet(state, bet);
  }

  /// El açar: bahsi düşer, iki kart oyuncuya, iki kart krupiyeye dağıtır.
  CasinoResult deal(GameState state, int bet, Random rng) {
    final InteractionAvailability check = dealAvailability(state, bet);
    if (!check.isAllowed) return _blocked(state, check.reason!);

    final List<PlayingCard> deste = shuffledDeck(rng);
    final List<PlayingCard> oyuncu = <PlayingCard>[deste[0], deste[2]];
    final List<PlayingCard> krupiye = <PlayingCard>[deste[1], deste[3]];
    final List<PlayingCard> kalan = deste.sublist(4);

    // Bahis burada **bir kez** düşer.
    GameState next = state.copyWith(
      player: state.player.copyWith(wallet: state.player.wallet - bet),
      blackjack: BlackjackGame(
        bet: bet,
        deck: List<PlayingCard>.unmodifiable(kalan),
        playerCards: List<PlayingCard>.unmodifiable(oyuncu),
        dealerCards: List<PlayingCard>.unmodifiable(krupiye),
        phase: BlackjackPhase.oyuncu,
        startedAtAge: state.player.age,
      ),
      wagerThisAge: state.wagerThisAge + bet,
    );
    next = _log(next, 'Blackjack masasında $bet ₺ bahis oynadın.');

    // İlk iki kartta 21 varsa el hemen sonuçlanır.
    final BlackjackGame oyun = next.blackjack!;
    if (oyun.playerHasNatural || oyun.dealerHasNatural) {
      return _settle(next, oyun);
    }

    return CasinoResult(
      state: next,
      outcome: CasinoOutcome(
        applied: true,
        text: 'Kartlar dağıtıldı. Elin: ${oyun.playerTotal}.',
        walletDelta: -bet,
      ),
    );
  }

  /// Kart çeker.
  CasinoResult hit(GameState state) {
    final BlackjackGame? oyun = state.blackjack;
    if (oyun == null) return _blocked(state, 'Masada açık bir el yok.');
    if (oyun.isFinished) return _blocked(state, 'Bu el bitti.');
    if (oyun.deck.isEmpty) return _blocked(state, 'Destede kart kalmadı.');

    final BlackjackGame sonra = oyun.copyWith(
      deck: List<PlayingCard>.unmodifiable(oyun.deck.sublist(1)),
      playerCards: List<PlayingCard>.unmodifiable(
        <PlayingCard>[...oyun.playerCards, oyun.deck.first],
      ),
    );
    final GameState next = state.copyWith(blackjack: sonra);

    if (sonra.playerTotal > 21) return _settle(next, sonra);

    return CasinoResult(
      state: next,
      outcome: CasinoOutcome(
        applied: true,
        text: '${oyun.deck.first.label} geldi. Elin: ${sonra.playerTotal}.',
      ),
    );
  }

  /// Durur: krupiye kuralına göre kart çeker ve el sonuçlanır.
  CasinoResult stand(GameState state) {
    final BlackjackGame? oyun = state.blackjack;
    if (oyun == null) return _blocked(state, 'Masada açık bir el yok.');
    if (oyun.isFinished) return _blocked(state, 'Bu el bitti.');

    List<PlayingCard> deste = <PlayingCard>[...oyun.deck];
    final List<PlayingCard> krupiye = <PlayingCard>[...oyun.dealerCards];
    while (handValue(krupiye).total < CasinoRules.dealerStandsOn &&
        deste.isNotEmpty) {
      krupiye.add(deste.first);
      deste = deste.sublist(1);
    }

    final BlackjackGame sonra = oyun.copyWith(
      deck: List<PlayingCard>.unmodifiable(deste),
      dealerCards: List<PlayingCard>.unmodifiable(krupiye),
    );
    return _settle(state.copyWith(blackjack: sonra), sonra);
  }

  /// Eli kapatır; sonuç ekranından çıkışta çağrılır.
  ///
  /// Ödeme zaten [_settle] içinde yapılmıştır; burada yalnızca masa
  /// temizlenir. Bitmemiş bir el kapatılamaz.
  CasinoResult closeHand(GameState state) {
    final BlackjackGame? oyun = state.blackjack;
    if (oyun == null) return _blocked(state, 'Masada açık bir el yok.');
    if (!oyun.isFinished) {
      return _blocked(state, 'Önce eli bitirmen gerekiyor.');
    }
    return CasinoResult(
      state: state.copyWith(blackjack: null),
      outcome: const CasinoOutcome(applied: true, text: 'Masadan kalktın.'),
    );
  }

  /// Sonucu hesaplar ve ödemeyi **bir kez** uygular.
  CasinoResult _settle(GameState state, BlackjackGame oyun) {
    if (oyun.settled) {
      return _blocked(state, 'Bu elin ödemesi zaten yapıldı.');
    }

    final int oyuncuToplam = oyun.playerTotal;
    final int krupiyeToplam = oyun.dealerTotal;
    final BlackjackResult sonuc;
    final int odeme;

    if (oyuncuToplam > 21) {
      sonuc = BlackjackResult.oyuncuBatti;
      odeme = 0;
    } else if (oyun.playerHasNatural && !oyun.dealerHasNatural) {
      sonuc = BlackjackResult.oyuncuBlackjack;
      odeme = oyun.bet + (oyun.bet * CasinoRules.blackjackPayoutRatio).round();
    } else if (oyun.dealerHasNatural && !oyun.playerHasNatural) {
      sonuc = BlackjackResult.krupiyeKazandi;
      odeme = 0;
    } else if (krupiyeToplam > 21) {
      sonuc = BlackjackResult.krupiyeBatti;
      odeme = oyun.bet * 2;
    } else if (oyuncuToplam > krupiyeToplam) {
      sonuc = BlackjackResult.oyuncuKazandi;
      odeme = oyun.bet * 2;
    } else if (oyuncuToplam < krupiyeToplam) {
      sonuc = BlackjackResult.krupiyeKazandi;
      odeme = 0;
    } else {
      sonuc = BlackjackResult.berabere;
      odeme = oyun.bet;
    }

    final BlackjackGame bitmis = oyun.copyWith(
      phase: BlackjackPhase.bitti,
      result: sonuc,
      payout: odeme,
      settled: true,
    );

    final int net = odeme - oyun.bet;
    final String metin = '${sonuc.label} — sen $oyuncuToplam, '
        'krupiye $krupiyeToplam. '
        '${net > 0 ? '$net ₺ kazandın.' : net < 0 ? '${-net} ₺ kaybettin.' : 'Bahsin geri geldi.'}';

    GameState next = state.copyWith(
      player: state.player.copyWith(wallet: state.player.wallet + odeme),
      blackjack: bitmis,
    );
    next = _log(next, 'Blackjack: $metin');

    return CasinoResult(
      state: next,
      outcome: CasinoOutcome(applied: true, text: metin, walletDelta: odeme),
    );
  }

  CasinoResult _blocked(GameState state, String reason) => CasinoResult(
        state: state,
        outcome: CasinoOutcome(applied: false, text: reason),
      );
}

/// Kumarhaneye giriş ve bahis koşulları.
abstract final class CasinoAccess {
  static InteractionAvailability check(GameState state) {
    if (state.player.age < CasinoRules.prototypeOnlyMinAge) {
      return InteractionAvailability.blocked(
        'Kumarhane ${CasinoRules.prototypeOnlyMinAge} yaşından itibaren '
        'açılır.',
      );
    }
    return const InteractionAvailability.allowed();
  }

  static InteractionAvailability checkBet(GameState state, int bet) {
    if (bet < CasinoRules.prototypeOnlyMinBet) {
      return InteractionAvailability.blocked(
        'En az ${CasinoRules.prototypeOnlyMinBet} ₺ bahis oynanır.',
      );
    }
    if (bet > CasinoRules.prototypeOnlyMaxBet) {
      return InteractionAvailability.blocked(
        'Bu masada en fazla ${CasinoRules.prototypeOnlyMaxBet} ₺ '
        'bahis oynanır.',
      );
    }
    if (state.player.wallet < bet) {
      return const InteractionAvailability.blocked(
        'Cüzdanında bu bahis için yeterli para yok.',
      );
    }
    if (state.wagerThisAge + bet >
        CasinoRules.prototypeOnlyYearlyWagerLimit) {
      return InteractionAvailability.blocked(
        'Bu yıl kumarhanede oynanabilecek '
        '${CasinoRules.prototypeOnlyYearlyWagerLimit} ₺ sınırına ulaştın.',
      );
    }
    return const InteractionAvailability.allowed();
  }
}

GameState _log(GameState state, String text) => state.copyWith(
      log: List<LifeLogEntry>.unmodifiable(<LifeLogEntry>[
        ...state.log,
        LifeLogEntry(
          age: state.player.age,
          text: text,
          category: LogCategory.kisisel,
        ),
      ]),
    );

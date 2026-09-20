import 'package:flutter/foundation.dart';

import 'playing_card.dart';

/// Oynanan elin hangi aşamada olduğu.
enum BlackjackPhase {
  /// Oyuncunun sırası: kart çekebilir veya durabilir.
  oyuncu,

  /// El bitti; sonuç hesaplandı ve ödeme yapıldı.
  bitti,
}

/// Elin sonucu.
enum BlackjackResult {
  oyuncuBlackjack,
  oyuncuKazandi,
  krupiyeKazandi,
  oyuncuBatti,
  krupiyeBatti,
  berabere,
}

extension BlackjackResultLabel on BlackjackResult {
  String get label {
    switch (this) {
      case BlackjackResult.oyuncuBlackjack:
        return 'Blackjack!';
      case BlackjackResult.oyuncuKazandi:
        return 'Kazandın';
      case BlackjackResult.krupiyeKazandi:
        return 'Krupiye kazandı';
      case BlackjackResult.oyuncuBatti:
        return "21'i aştın";
      case BlackjackResult.krupiyeBatti:
        return "Krupiye 21'i aştı";
      case BlackjackResult.berabere:
        return 'Berabere';
    }
  }
}

/// Devam eden ya da yeni bitmiş bir blackjack eli.
///
/// Deste **olduğu gibi** kaydedilir; oyun kapatılıp açıldığında aynı el
/// aynı kartlarla sürer. Yeniden açarak sonucu değiştirmek mümkün değildir.
@immutable
class BlackjackGame {
  const BlackjackGame({
    required this.bet,
    required this.deck,
    required this.playerCards,
    required this.dealerCards,
    required this.phase,
    required this.startedAtAge,
    this.result,
    this.payout = 0,
    this.settled = false,
  });

  /// Oynanan bahis; **cüzdandan el başlarken bir kez** düşülür.
  final int bet;

  /// Destede kalan kartlar; en üstteki sonda değil **başta**dır.
  final List<PlayingCard> deck;

  final List<PlayingCard> playerCards;
  final List<PlayingCard> dealerCards;
  final BlackjackPhase phase;
  final int startedAtAge;

  /// El bittiyse sonucu.
  final BlackjackResult? result;

  /// Elden cüzdana dönen toplam (bahis dâhil). Kayıpta 0'dır.
  final int payout;

  /// Ödeme cüzdana uygulandı mı? İkinci kez ödeme yapılmasını engeller.
  final bool settled;

  bool get isFinished => phase == BlackjackPhase.bitti;

  int get playerTotal => handValue(playerCards).total;
  bool get playerSoft => handValue(playerCards).soft;
  int get dealerTotal => handValue(dealerCards).total;

  /// Oyuncunun sırasındayken krupiyenin yalnızca ilk kartı açıktır.
  List<PlayingCard> get visibleDealerCards =>
      isFinished ? dealerCards : dealerCards.take(1).toList(growable: false);

  /// Krupiyenin açık kartlarının toplamı.
  int get visibleDealerTotal => handValue(visibleDealerCards).total;

  /// İlk iki kartla 21: doğal blackjack.
  bool get playerHasNatural => playerCards.length == 2 && playerTotal == 21;
  bool get dealerHasNatural => dealerCards.length == 2 && dealerTotal == 21;

  /// Elden cüzdana net kazanç (kayıpta eksi).
  int get netGain => payout - bet;

  BlackjackGame copyWith({
    List<PlayingCard>? deck,
    List<PlayingCard>? playerCards,
    List<PlayingCard>? dealerCards,
    BlackjackPhase? phase,
    BlackjackResult? result,
    int? payout,
    bool? settled,
  }) =>
      BlackjackGame(
        bet: bet,
        deck: deck ?? this.deck,
        playerCards: playerCards ?? this.playerCards,
        dealerCards: dealerCards ?? this.dealerCards,
        phase: phase ?? this.phase,
        startedAtAge: startedAtAge,
        result: result ?? this.result,
        payout: payout ?? this.payout,
        settled: settled ?? this.settled,
      );
}

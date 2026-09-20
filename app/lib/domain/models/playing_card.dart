import 'dart:math';

import 'package:flutter/foundation.dart';

/// Kart rengi (takım).
enum CardSuit {
  maca('♠', 'Maça'),
  kupa('♥', 'Kupa'),
  karo('♦', 'Karo'),
  sinek('♣', 'Sinek');

  const CardSuit(this.symbol, this.label);

  final String symbol;
  final String label;

  bool get isRed => this == CardSuit.kupa || this == CardSuit.karo;
}

/// Standart 52 kartlık destenin bir kartı.
///
/// [rank] 1-13 arasıdır: 1 = As, 11 = Vale, 12 = Kız, 13 = Papaz.
@immutable
class PlayingCard {
  const PlayingCard(this.rank, this.suit)
      : assert(rank >= 1 && rank <= 13);

  final int rank;
  final CardSuit suit;

  bool get isAce => rank == 1;

  /// Blackjack'teki temel değer: resimli kartlar 10, As **1** sayılır.
  /// Asın 11 sayılması el toplamında ayrıca değerlendirilir.
  int get blackjackValue => rank >= 10 ? 10 : rank;

  String get rankLabel {
    switch (rank) {
      case 1:
        return 'A';
      case 11:
        return 'J';
      case 12:
        return 'Q';
      case 13:
        return 'K';
      default:
        return '$rank';
    }
  }

  String get label => '$rankLabel${suit.symbol}';

  /// Kayıt için kısa kimlik: `'A-kupa'`, `'10-maca'` gibi.
  String get code => '$rank:${suit.name}';

  static PlayingCard? fromCode(String code) {
    final List<String> parcalar = code.split(':');
    if (parcalar.length != 2) return null;
    final int? rank = int.tryParse(parcalar[0]);
    if (rank == null || rank < 1 || rank > 13) return null;
    for (final CardSuit suit in CardSuit.values) {
      if (suit.name == parcalar[1]) return PlayingCard(rank, suit);
    }
    return null;
  }

  @override
  bool operator ==(Object other) =>
      other is PlayingCard && other.rank == rank && other.suit == suit;

  @override
  int get hashCode => Object.hash(rank, suit);

  @override
  String toString() => label;
}

/// Karılmış standart 52 kartlık deste.
List<PlayingCard> shuffledDeck(Random rng) {
  final List<PlayingCard> deste = <PlayingCard>[
    for (final CardSuit suit in CardSuit.values)
      for (int rank = 1; rank <= 13; rank++) PlayingCard(rank, suit),
  ];
  deste.shuffle(rng);
  return deste;
}

/// Bir elin toplamı ve "yumuşak" olup olmadığı.
///
/// As 11 sayılabiliyorsa (toplam 21'i aşmıyorsa) el yumuşaktır.
({int total, bool soft}) handValue(List<PlayingCard> cards) {
  int toplam = 0;
  int as = 0;
  for (final PlayingCard card in cards) {
    toplam += card.blackjackValue;
    if (card.isAce) as++;
  }
  bool yumusak = false;
  if (as > 0 && toplam + 10 <= 21) {
    toplam += 10;
    yumusak = true;
  }
  return (total: toplam, soft: yumusak);
}

/// Kumarhanenin ortak kuralları ve sınırları.
///
/// **Bu özellik yalnızca oyunun sanal cüzdanıyla çalışır.** Gerçek para
/// yatırma, çekme, ödüle dönüştürme, uygulama içi satın alma veya reklam
/// karşılığı bahis hakkı **yoktur**.
///
/// Sayısal değerler `prototypeOnly`'dir (`docs/DESIGN_REVIEW_QUEUE.md`,
/// Q-054).
abstract final class CasinoRules {
  /// prototypeOnly: kumarhanenin açıldığı yaş.
  static const int prototypeOnlyMinAge = 18;

  /// prototypeOnly: en küçük bahis.
  static const int prototypeOnlyMinBet = 500;

  /// prototypeOnly: en büyük bahis.
  static const int prototypeOnlyMaxBet = 25000;

  /// prototypeOnly: bir yaşta toplam oynanabilecek bahis üst sınırı.
  ///
  /// Oyuncuyu daha fazla oynamaya iten bir mekanik değildir; tam tersine
  /// bir yılda ne kadar oynanabileceğini sınırlar.
  static const int prototypeOnlyYearlyWagerLimit = 150000;

  /// Masada seçilebilen hazır bahis adımları.
  static const List<int> prototypeOnlyBetSteps = <int>[
    500,
    1000,
    2500,
    5000,
    10000,
  ];

  /// Krupiye 17 ve üstünde durur (yumuşak 17 dâhil).
  static const int dealerStandsOn = 17;

  /// Doğal blackjack ödemesi: 3:2.
  static const double blackjackPayoutRatio = 1.5;

  /// Ekranda gösterilen kural özeti.
  static const String blackjackRulesText =
      'Krupiye 17 ve üstünde durur (yumuşak 17 dâhil). Doğal blackjack '
      '3:2 öder, normal kazanç 1:1, beraberlikte bahsin geri gelir. '
      'As 1 veya 11 sayılır.';

  static const String rouletteRulesText =
      'Tek sıfırlı Avrupa ruleti (0-36). Kırmızı/siyah ve tek/çift 1:1 '
      'öder; tek sayıya bahis 35:1 öder. 0 gelirse renk ve tek/çift '
      'bahisleri kaybeder.';

  static const String responsibleText =
      'Bu masa yalnızca oyunun sanal parasıyla oynanır. Gerçek para '
      'yatırma, çekme veya ödül yoktur.';
}

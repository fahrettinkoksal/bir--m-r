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
  ///
  /// Düşük gelirli karakterin de küçük tutarla oynayabilmesi için düşüktür
  /// (D-040).
  static const int prototypeOnlyMinBet = 100;

  /// prototypeOnly: yıllık bahis bütçesinin **gider sonrası** kullanılabilir
  /// gelirden aldığı pay.
  static const double prototypeOnlyIncomeShare = 0.15;

  /// prototypeOnly: yıllık bahis bütçesinin mevcut cüzdandan aldığı pay.
  ///
  /// Maaşı olmayan ama mirasla varlık edinmiş oyuncu tamamen engellenmez.
  static const double prototypeOnlyWalletShare = 0.05;

  /// prototypeOnly: yıllık bahis bütçesinin alt ve üst sınırı.
  static const int prototypeOnlyMinYearlyBudget = 6000;
  static const int prototypeOnlyMaxYearlyBudget = 450000;

  /// prototypeOnly: tek bahsin yıllık bütçeden alabileceği en büyük pay.
  static const double prototypeOnlyMaxBetShare = 0.2;

  /// prototypeOnly: hazır bahis adımlarının en büyük bahse oranı.
  static const List<double> prototypeOnlyBetStepRatios = <double>[
    0.05,
    0.1,
    0.25,
    0.5,
    1.0,
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

  /// Bir yılda oynanabilecek toplam bahis bütçesi (D-040).
  ///
  /// Gider sonrası kullanılabilir gelirin ve mevcut cüzdanın payından
  /// hesaplanır; böylece düşük gelirli karakter büyük bahislere
  /// yönlendirilmez, mirasla varlık edinmiş oyuncu da tamamen engellenmez.
  /// Oyuncunun kendi koyduğu limit daha düşükse **o** geçerlidir.
  static int prototypeOnlyYearlyBudget({
    required int disposableIncome,
    required int wallet,
    int? playerLimit,
  }) {
    final int hesap = (disposableIncome.clamp(0, 1 << 30) *
                prototypeOnlyIncomeShare +
            wallet.clamp(0, 1 << 30) * prototypeOnlyWalletShare)
        .round();
    final int sistem = hesap.clamp(
      prototypeOnlyMinYearlyBudget,
      prototypeOnlyMaxYearlyBudget,
    );
    if (playerLimit == null) return sistem;
    return playerLimit < sistem ? playerLimit : sistem;
  }

  /// Bu bütçeyle oynanabilecek en büyük tek bahis.
  static int prototypeOnlyMaxBet(int yearlyBudget) =>
      (yearlyBudget * prototypeOnlyMaxBetShare)
          .round()
          .clamp(prototypeOnlyMinBet, prototypeOnlyMaxYearlyBudget);

  /// Masada gösterilecek hazır bahis adımları.
  static List<int> prototypeOnlyBetSteps(int maxBet) {
    final Set<int> adimlar = <int>{};
    for (final double oran in prototypeOnlyBetStepRatios) {
      final int tutar = (maxBet * oran).round();
      // Okunaklı olsun diye 100 ₺'nin katlarına yuvarlanır.
      final int yuvarlanmis = (tutar / 100).round() * 100;
      adimlar.add(yuvarlanmis.clamp(prototypeOnlyMinBet, maxBet));
    }
    return adimlar.toList(growable: false)..sort();
  }

  static const String responsibleText =
      'Bu masa yalnızca oyunun sanal parasıyla oynanır. Gerçek para '
      'yatırma, çekme veya ödül yoktur.';
}

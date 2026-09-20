import '../models/game_state.dart';
import '../models/owned_item.dart';
import '../models/person.dart';

/// Oyuncunun yaşam düzeni.
///
/// Gider bu düzene göre değişir (D-033): çocuğa yetişkin gideri yüklenmez,
/// ailesinin yanında yaşayan ile bağımsız yaşayanın gideri aynı değildir,
/// kendi evinde oturan kira ödemez.
enum LivingSituation {
  cocuk('Çocuk'),
  aileYaninda('Ailenin yanında'),
  kirada('Kirada, kendi başına'),
  kendiEvinde('Kendi evinde');

  const LivingSituation(this.label);

  final String label;
}

/// Tek bir gider kalemi.
///
/// Gider **taban tutar + gelire bağlı pay** şeklinde hesaplanır; böylece
/// düşük gelirli karakter sabit bir yük altında ezilmez, yüksek gelirlinin
/// de bütün maaşı otomatik birikmez (D-039). Kalemler ayrı tutulur, böylece
/// ileride ekranda tek tek gösterilebilir.
class CostItem {
  const CostItem({
    required this.label,
    required this.base,
    required this.incomeShare,
  });

  final String label;

  /// prototypeOnly: yıllık taban tutar (₺).
  final int base;

  /// prototypeOnly: yıllık gelirden alınan pay.
  final double incomeShare;

  int amountFor(int income) => base + (income * incomeShare).round();
}

/// Bir yılın gider dökümü.
class CostBreakdown {
  const CostBreakdown({
    required this.situation,
    required this.income,
    required this.items,
  });

  final LivingSituation situation;

  /// Gidere esas alınan yıllık gelir.
  final int income;

  /// Kalem kalem giderler (barınma, beslenme, diğer).
  final List<({String label, int amount})> items;

  int get total =>
      items.fold(0, (int toplam, ({String label, int amount}) e) => toplam + e.amount);
}

/// Yıllık temel yaşam gideri (D-033, D-039).
///
/// Hesap: her kalem için **taban tutar + yıllık gelirin belirli bir payı**.
/// Giderler cüzdanı **sessizce eksiye düşürmez**: para yetmezse cüzdan
/// sıfırda kalır, açık bir sonuç yazılır ve **geçim sıkıntısı** sayacı
/// artar. Bütün tutarlar ve oranlar `prototypeOnly`'dir (Q-055).
abstract final class LivingCosts {
  /// prototypeOnly: giderin başladığı yaş.
  static const int prototypeOnlyAdultAge = 18;

  /// prototypeOnly: yaşam düzenine göre gider kalemleri.
  static const Map<LivingSituation, List<CostItem>> prototypeOnlyItems =
      <LivingSituation, List<CostItem>>{
    LivingSituation.cocuk: <CostItem>[],
    LivingSituation.aileYaninda: <CostItem>[
      CostItem(label: 'Eve katkı', base: 6000, incomeShare: 0.02),
      CostItem(label: 'Beslenme', base: 10000, incomeShare: 0.04),
      CostItem(label: 'Diğer giderler', base: 4000, incomeShare: 0.02),
    ],
    LivingSituation.kirada: <CostItem>[
      CostItem(label: 'Kira', base: 45000, incomeShare: 0.07),
      CostItem(label: 'Beslenme', base: 22000, incomeShare: 0.05),
      CostItem(label: 'Fatura ve diğer', base: 8000, incomeShare: 0.03),
    ],
    LivingSituation.kendiEvinde: <CostItem>[
      CostItem(label: 'Aidat ve bakım', base: 15000, incomeShare: 0.03),
      CostItem(label: 'Beslenme', base: 22000, incomeShare: 0.05),
      CostItem(label: 'Fatura ve diğer', base: 8000, incomeShare: 0.04),
    ],
  };

  /// Oyuncu bu yaşta hane içinde bir yetişkinle mi yaşıyor?
  static bool livesWithFamily(GameState state) => state.people.any(
        (Person p) =>
            p.isAlive && p.inPlayerHousehold && p.age >= prototypeOnlyAdultAge,
      );

  /// Oyuncunun kendi konutu var mı?
  static bool ownsHome(GameState state) =>
      state.items.any((OwnedItem i) => i.isProperty);

  /// Oyuncunun yaşam düzeni.
  static LivingSituation situationOf(GameState state) {
    if (state.player.age < prototypeOnlyAdultAge) return LivingSituation.cocuk;
    if (livesWithFamily(state)) return LivingSituation.aileYaninda;
    return ownsHome(state)
        ? LivingSituation.kendiEvinde
        : LivingSituation.kirada;
  }

  /// Gidere esas alınan yıllık gelir.
  ///
  /// Şimdilik yalnızca maaş; kira geliri gibi kalemler eklendiğinde buraya
  /// katılacak.
  static int yearlyIncome(GameState state) =>
      state.career.job?.yearlySalary ?? 0;

  /// Bu yılın gider dökümü.
  static CostBreakdown breakdownFor(GameState state) {
    final LivingSituation durum = situationOf(state);
    final int gelir = yearlyIncome(state);
    return CostBreakdown(
      situation: durum,
      income: gelir,
      items: <({String label, int amount})>[
        for (final CostItem kalem in prototypeOnlyItems[durum]!)
          (label: kalem.label, amount: kalem.amountFor(gelir)),
      ],
    );
  }

  /// Bu yaş için yıllık toplam gider.
  static int yearlyCost(GameState state) => breakdownFor(state).total;

  /// Giderin ekranda görünen kısa açıklaması.
  static String labelFor(GameState state) {
    switch (situationOf(state)) {
      case LivingSituation.cocuk:
        return 'Bu yaşta geçim giderin yok.';
      case LivingSituation.aileYaninda:
        return 'Ailenin yanında yaşıyorsun.';
      case LivingSituation.kirada:
        return 'Kirada, kendi başına yaşıyorsun.';
      case LivingSituation.kendiEvinde:
        return 'Kendi evinde yaşıyorsun; kira ödemiyorsun.';
    }
  }

  /// Gideri uygular.
  ///
  /// Cüzdan eksiye düşmez; ödenemeyen kısım **geçim sıkıntısı** olarak
  /// kaydedilir ve günlüğe açık bir satır yazılır.
  static ({GameState state, String? logText}) apply(GameState state) {
    final int gider = yearlyCost(state);
    if (gider <= 0) {
      return (
        state: state.hardshipYears == 0
            ? state
            : state.copyWith(hardshipYears: 0),
        logText: null,
      );
    }

    final int cuzdan = state.player.wallet;
    if (cuzdan >= gider) {
      return (
        state: state.copyWith(
          player: state.player.copyWith(wallet: cuzdan - gider),
          hardshipYears: 0,
        ),
        logText: 'Yıllık geçim giderin $gider ₺ cüzdanından çıktı.',
      );
    }

    // Para yetmiyor: cüzdan sıfırlanır, borç oluşmaz, durum açıkça yazılır.
    final int eksik = gider - cuzdan;
    return (
      state: state.copyWith(
        player: state.player.copyWith(wallet: 0),
        hardshipYears: state.hardshipYears + 1,
      ),
      logText: 'Geçim giderin $gider ₺ tuttu, cüzdanında $cuzdan ₺ vardı. '
          '$eksik ₺ açık kaldı; bu yıl geçim sıkıntısı çektin.',
    );
  }
}

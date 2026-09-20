import '../interaction/parenthood.dart';
import '../models/game_state.dart';
import '../models/owned_item.dart';
import '../models/person.dart';
import 'housing.dart';
import '../../text/turkish_text.dart';

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

  /// prototypeOnly: hanede bakılan her çocuğun yıllık gideri.
  ///
  /// Çocuk gideri yaşam düzeninden bağımsızdır ve **çocuk sayısıyla**
  /// çarpılır. Eşin kendi geliri kendi giderini karşılar sayılır; eşin
  /// hane ekonomisine katkısı ve ortak bütçe henüz tasarlanmadı (Q-063).
  static const CostItem prototypeOnlyChildCost =
      CostItem(label: 'Çocuk gideri', base: 24000, incomeShare: 0.03);

  /// Oyuncu **ailesinin** yanında mı yaşıyor?
  ///
  /// Eş ve çocuklar sayılmaz: onlarla kurulan hane oyuncunun kendi
  /// hanesidir (Housing.hasAdultAtFamilyHome ile aynı ölçüt).
  static bool livesWithFamily(GameState state) => state.people.any(
        (Person p) =>
            p.isAlive &&
            p.inPlayerHousehold &&
            !p.relation.haneBagi &&
            p.age >= prototypeOnlyAdultAge,
      );

  /// Oyuncunun kendi konutu var mı?
  static bool ownsHome(GameState state) =>
      state.items.any((OwnedItem i) => i.isProperty);

  /// Oyuncunun yaşam düzeni.
  ///
  /// Nerede **oturulduğu** esastır (D-043): evi olup ailesinin yanında
  /// yaşayan kira ödemez ama ev gideri de yoktur; evini kiraya verip
  /// kirada oturan kira öder.
  static LivingSituation situationOf(GameState state) {
    if (state.player.age < prototypeOnlyAdultAge) return LivingSituation.cocuk;
    switch (Housing.residenceOf(state)) {
      case ResidenceKind.aileYaninda:
        return LivingSituation.aileYaninda;
      case ResidenceKind.kendiEvinde:
        return LivingSituation.kendiEvinde;
      case ResidenceKind.kirada:
        return LivingSituation.kirada;
    }
  }

  /// Gidere esas alınan yıllık gelir.
  ///
  /// Maaş ve **kira geliri** birlikte sayılır (D-033: bütün para akışları
  /// aynı ekonomiye bağlıdır).
  static int yearlyIncome(GameState state) =>
      (state.career.job?.yearlySalary ?? 0) + Housing.yearlyRentIncome(state);

  /// Bu yılın gider dökümü.
  ///
  /// Hanede bakılan çocuk varsa ayrı bir kalem eklenir; gerçek çocuk
  /// kayıtlarından sayılır, uydurma bir sayaç tutulmaz (D-038).
  static CostBreakdown breakdownFor(GameState state) {
    final LivingSituation durum = situationOf(state);
    final int gelir = yearlyIncome(state);
    final int cocukSayisi = Parenthood.dependentChildren(state).length;
    return CostBreakdown(
      situation: durum,
      income: gelir,
      items: <({String label, int amount})>[
        for (final CostItem kalem in prototypeOnlyItems[durum]!)
          (label: kalem.label, amount: kalem.amountFor(gelir)),
        if (cocukSayisi > 0)
          (
            label: cocukSayisi == 1
                ? prototypeOnlyChildCost.label
                : '${prototypeOnlyChildCost.label} ($cocukSayisi çocuk)',
            amount: prototypeOnlyChildCost.amountFor(gelir) * cocukSayisi,
          ),
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
        logText: 'Yıllık geçim giderin ${trMoney(gider)} cüzdanından çıktı.',
      );
    }

    // Para yetmiyor: cüzdan sıfırlanır, borç oluşmaz, durum açıkça yazılır.
    final int eksik = gider - cuzdan;
    return (
      state: state.copyWith(
        player: state.player.copyWith(wallet: 0),
        hardshipYears: state.hardshipYears + 1,
      ),
      logText: 'Geçim giderin ${trMoney(gider)} tuttu, cüzdanında ${trMoney(cuzdan)} vardı. '
          '${trMoney(eksik)} açık kaldı; bu yıl geçim sıkıntısı çektin.',
    );
  }
}

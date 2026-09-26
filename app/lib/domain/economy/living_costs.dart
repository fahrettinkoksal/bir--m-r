import '../../data/item_catalog.dart';
import '../interaction/parenthood.dart';
import '../models/game_state.dart';
import '../models/owned_item.dart';
import '../models/person.dart';
import 'business_engine.dart';
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
    // 2026 kalibrasyonu: taban tutarlar yıllıktır.
    //
    // Kira bilerek gerçek piyasanın **altında** tutuldu. Türkiye'de
    // asgari ücretle tek başına kirada yaşamak pratikte birikim
    // bırakmıyor; oysa D-039 "düşük gelirli bağımsız karakter de birikim
    // yapabilmeli" diyor ve bu onaylanmış bir karar. Gerçekçilik ile
    // onaylı kural çatıştığında onaylı kural kazandı: en düşük maaşlı iş
    // bile gelirinin en az üçte birini elinde tutuyor.
    // Gerekçe: docs/ECONOMY_2026.md.
    LivingSituation.aileYaninda: <CostItem>[
      CostItem(label: 'Eve katkı', base: 24000, incomeShare: 0.02),
      CostItem(label: 'Beslenme', base: 36000, incomeShare: 0.04),
      CostItem(label: 'Diğer giderler', base: 18000, incomeShare: 0.02),
    ],
    LivingSituation.kirada: <CostItem>[
      CostItem(label: 'Kira', base: 88000, incomeShare: 0.07),
      CostItem(label: 'Beslenme', base: 48000, incomeShare: 0.05),
      CostItem(label: 'Fatura ve diğer', base: 26000, incomeShare: 0.03),
    ],
    LivingSituation.kendiEvinde: <CostItem>[
      CostItem(label: 'Aidat ve bakım', base: 40000, incomeShare: 0.03),
      CostItem(label: 'Beslenme', base: 48000, incomeShare: 0.05),
      CostItem(label: 'Fatura ve diğer', base: 26000, incomeShare: 0.04),
    ],
  };

  /// prototypeOnly: **geliri olmayan** ve ailesinin yanında yaşayan
  /// yetişkinin gideri (D-123).
  ///
  /// Faho sordu: "yıllık yaşam gideri çalışmıyorsam neden var ve bu
  /// giderler neye göre belirleniyor?" Cevabın bir kısmı gerçek: işsiz
  /// insan da yiyip içiyor, fatura ödüyor. Ama ailesinin yanında yaşayan
  /// ve hiç geliri olmayan biri için bu yükü tam ödetmek gerçekçi
  /// değildi — Türkiye'de o gideri **aile karşılar**. Geriye yalnızca
  /// kişisel harcama kalır.
  ///
  /// Bu yalnızca **geliri sıfır** olan oyuncu içindir; maaşı ya da kira
  /// geliri olan eve katkısını yapar.
  static const List<CostItem> prototypeOnlySupportedItems = <CostItem>[
    CostItem(label: 'Kişisel harcama', base: 12000, incomeShare: 0.0),
  ];

  /// prototypeOnly: hanede bakılan her çocuğun yıllık gideri.
  ///
  /// Çocuk gideri yaşam düzeninden bağımsızdır ve **çocuk sayısıyla**
  /// çarpılır. Eşin kendi geliri kendi giderini karşılar sayılır; eşin
  /// hane ekonomisine katkısı ve ortak bütçe henüz tasarlanmadı (Q-063).
  static const CostItem prototypeOnlyChildCost =
      CostItem(label: 'Çocuk gideri', base: 72000, incomeShare: 0.03);

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
      (state.career.job?.yearlySalary ?? 0) +
      Housing.yearlyRentIncome(state) +
      // Kendi işinin kârı da aynı ekonomiye girer (D-033, D-132). Zarar
      // eden iş geliri **düşürür**; gider hesabı bunu görür.
      BusinessEngine.yearlyBusinessIncome(state);

  /// Bu yılın gider dökümü.
  ///
  /// Hanede bakılan çocuk varsa ayrı bir kalem eklenir; gerçek çocuk
  /// kayıtlarından sayılır, uydurma bir sayaç tutulmaz (D-038).
  static CostBreakdown breakdownFor(GameState state) {
    final LivingSituation durum = situationOf(state);
    final int gelir = yearlyIncome(state);
    final int cocukSayisi = Parenthood.dependentChildren(state).length;
    // Geliri olmayan ve ailesinin yanında yaşayanın yükünü aile taşır
    // (D-123).
    final List<CostItem> kalemler =
        durum == LivingSituation.aileYaninda && gelir <= 0
            ? prototypeOnlySupportedItems
            : prototypeOnlyItems[durum]!;
    return CostBreakdown(
      situation: durum,
      income: gelir,
      items: <({String label, int amount})>[
        for (final CostItem kalem in kalemler)
          (label: kalem.label, amount: kalem.amountFor(gelir)),
        if (cocukSayisi > 0)
          (
            label: cocukSayisi == 1
                ? prototypeOnlyChildCost.label
                : '${prototypeOnlyChildCost.label} ($cocukSayisi çocuk)',
            amount: prototypeOnlyChildCost.amountFor(gelir) * cocukSayisi,
          ),
        // Araç giderleri (D-148): sahip olunan her motorlu araç için
        // zorunlu trafik sigortası, kasko ve motorlu taşıtlar vergisi.
        ...vehicleItems(state),
      ],
    );
  }

  // =====================================================================
  // Araç giderleri (D-148)
  //
  // Faho'nun isteği: "araç satın aldığımda kasko ve sigorta masrafı da
  // çıksın, her yıl vergisi de çıksın."
  //
  // Üç kalem var ve üçü de Türkiye'deki karşılıklarına dayanıyor:
  //   * **Zorunlu trafik sigortası** — kanunen zorunlu.
  //   * **Kasko** — isteğe bağlıdır; bu sürümde herkes yaptırıyor sayılır
  //     (Q-153'te soruldu).
  //   * **MTV (motorlu taşıtlar vergisi)** — yılda iki taksit; oyun tek
  //     kalem olarak yazar. Gerçekte motor hacmi ve araç yaşına göre
  //     değişir; oyunda **araç değeri ve yaşı** ölçü alınır.
  //
  // Bütün oranlar `prototypeOnly` (Q-153).
  // =====================================================================

  /// prototypeOnly: zorunlu trafik sigortasının araç değerine oranı.
  static const double prototypeOnlyTrafficInsuranceRate = 0.010;

  /// prototypeOnly: kaskonun araç değerine oranı.
  static const double prototypeOnlyKaskoRate = 0.025;

  /// prototypeOnly: MTV'nin araç değerine oranı (sıfır araç için).
  static const double prototypeOnlyVehicleTaxRate = 0.012;

  /// prototypeOnly: MTV'nin her araç yaşı için indiği pay.
  ///
  /// Gerçekte MTV yaş bandına göre kademeli düşer; oyun bunu düz bir
  /// azalışla taklit eder ve bir tabanın altına inmez.
  static const double prototypeOnlyVehicleTaxAgeDrop = 0.05;

  /// prototypeOnly: MTV oranının inebileceği taban.
  static const double prototypeOnlyVehicleTaxFloor = 0.35;

  /// prototypeOnly: bisiklet gider çıkarmaz; yalnızca motorlu araç.
  static bool isMotorVehicle(OwnedItem item) =>
      item.type.kind == ItemKind.otomobil ||
      item.type.kind == ItemKind.motosiklet;

  /// Oyuncunun sahip olduğu motorlu araçlar.
  static List<OwnedItem> motorVehicles(GameState state) =>
      state.items.where(isMotorVehicle).toList(growable: false);

  /// Bir aracın yıllık sigorta + kasko + vergi gideri (₺).
  ///
  /// Değerleme **ödenen fiyata** değil, türün katalog değerine dayanır:
  /// ikinci el alınan lüks araç da lüks araç vergisi öder.
  static int yearlyVehicleCost(GameState state, OwnedItem item) {
    final int deger = item.type.baseValue;
    if (deger <= 0) return 0;
    final int yas = (state.player.age - item.acquiredAtAge).clamp(0, 60);
    final double vergiOrani = (prototypeOnlyVehicleTaxRate *
            (1 - prototypeOnlyVehicleTaxAgeDrop * yas))
        .clamp(
      prototypeOnlyVehicleTaxRate * prototypeOnlyVehicleTaxFloor,
      prototypeOnlyVehicleTaxRate,
    );
    final double toplam = prototypeOnlyTrafficInsuranceRate +
        prototypeOnlyKaskoRate +
        vergiOrani;
    return (deger * toplam).round();
  }

  /// Araç gider kalemleri; aracı olmayanda boştur.
  ///
  /// Her araç **ayrı satır** olur ki oyuncu hangi aracın ne kadar
  /// tuttuğunu görebilsin (D-123'ün "hesap ekranda dursun" kuralı).
  static List<({String label, int amount})> vehicleItems(GameState state) {
    final List<({String label, int amount})> sonuc =
        <({String label, int amount})>[];
    for (final OwnedItem arac in motorVehicles(state)) {
      final int tutar = yearlyVehicleCost(state, arac);
      if (tutar <= 0) continue;
      sonuc.add((
        label: '${arac.name}: sigorta, kasko ve vergi',
        amount: tutar,
      ));
    }
    return sonuc;
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

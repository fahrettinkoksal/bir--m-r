/// Yatırım türleri ve risk kademeleri (D-162).
///
/// **Gerçek şirket, hisse, fon ya da banka adı geçmez.** Hepsi soyut:
/// "Karma Hisse Sepeti", "Dengeli Fon", "Döviz Sepeti". Oyun canlı fiyat
/// çekmez, gerçek tarihsel kur kullanmaz ve hiçbir yerde yatırım tavsiyesi
/// vermez.
///
/// ## Sabit pozitif eğilim KALDIRILDI (Paket AD)
///
/// V1/V2'de her türün `drift` adında **garantili yıllık eğilimi** vardı
/// (hisse %10, fon %8, altın %7, döviz %6,5). Bu matematiksel olarak
/// oyuncuyu kaçınılmaz biçimde zenginleştiriyordu: yılda %9,2 gerçekleşen
/// getiri 60 yılda ~200 kat eder. Ölçümde görüldü — sadece altın
/// stratejisi 60 yılda medyan **18 kat** yapıyordu ve hiçbir 20 yıllık
/// döviz yolu anaparanın altında bitmiyordu.
///
/// Artık **tür başına yazılı bir eğilim yok.** Getiri şuradan doğar:
///
/// 1. **[InvestmentType.carry]** — varlığın kendi ürettiği akış. Hisse ve
///    fon temettü benzeri küçük bir akış üretir; **altın ve döviz hiçbir
///    şey üretmez** (carry = 0). Gerçek dünyada da öyledir: altın bir
///    şirket gibi kâr üretmez, yalnızca fiyatı oynar. Fonda ayrıca
///    [InvestmentType.annualFee] var: yönetim ücreti brüt akışın büyük
///    kısmını yiyor.
/// 2. **Piyasa rejimi** — risk iştahı ve korunma talebi (`MarketEngine`).
///    Riskli tarafın uzun vadede kazanmasının sebebi buradadır ve **tür
///    başına yazılmış bir sayı değildir**: iyi rejimler kriz
///    rejimlerinden daha sık (ölçüm: durgun %25 · normal %45 · güçlü %20 ·
///    kriz %7 · toparlanma %2), risk primi de yalnızca riske duyarlı
///    varlıklara bu sıklık üzerinden geçer
///    (`MarketEngine.prototypeOnlyRiskPremium`). Krizi çok gören bir
///    hayatta o prim hiç gerçekleşmez.
/// 3. **Değerleme ısısı** — bir varlık yıllarca yükselirse ısınır,
///    beklenen getirisi düşer ve sert düzeltme riski artar
///    (`MarketState.valuationHeat`). Ucuzlayan varlıkta tersi olur:
///    dipte sert toparlanma zarı atılır. Isı oyuncuya **gösterilmez**.
/// 4. **Çağ gelgiti** — hayat ölçeğinde yavaş, gizli bir eğilim
///    (`MarketState.riskTide`). Ortalaması sıfır, yani beklenen getiriyi
///    kaydırmaz; yaptığı şey **uzun vadeli sonucun dağılımını
///    genişletmek**. Bir hayat kötü bir çağa denk gelebilir.
/// 5. **Değer saklama payı** — altın/dövizin artı beklentisi buradan
///    gelir (`MarketEngine.prototypeOnlyStoreOfValueDrift`): oyunun kendi
///    parası yıllar içinde alım gücü kaybeder, sert varlıkların nominal
///    fiyatı bunu yansıtır.
///
/// Sonuç: uzun vade **garanti zenginlik değil**. Ölçülen hâli
/// (`app/test/paket_ad_measure_test.dart`): 40 yıl hisse tutup hiç
/// satmayan yolların **%5'i anaparanın altında** bitiyor ve en kötü
/// %10'luk dilim 1,6 kat yapıyor — Paket AD'den önce bu pay %2,9'du ve en
/// kötü %10 bile 2,5 kat yapıyordu. Bazı on yıllık dönemler çok iyi,
/// bazıları yatay, bazıları eksi geçer.
///
/// ## Oyunun kendi ölçeği
///
/// Bütün tutarlar **Bir Ömür'ün kendi ekonomi ölçeğindedir**
/// (`data/economy.dart`). Maaşlar, ev/araç fiyatları, kiralar, krediler ve
/// yatırımlar **birbirine göre** dengelenmiştir. Gerçek dünya rakamları
/// yalnızca ilk tasarım araştırmasında ilham olarak kullanıldı ve o
/// araştırma `docs/ECONOMY_2026.md` içinde **tarihsel not** olarak duruyor;
/// production denge gerekçesi "gerçek dünyada şu orandı" değildir. Oyun
/// takvime bağlı değil: aynı build beş yıl sonra da aynı dengede çalışır.
///
/// Bütün sayılar `prototypeOnly`'dir (Q-169).
library;

import 'package:flutter/material.dart';

/// Yatırımın risk kademesi. Yalnızca etiket; hesaba girmez.
enum InvestmentRisk {
  cokDusuk('Çok düşük risk'),
  dusukOrta('Düşük / orta risk'),
  orta('Orta risk'),
  yuksek('Yüksek risk');

  const InvestmentRisk(this.label);

  final String label;
}

/// Yatırımlar ekranındaki öbek.
enum InvestmentGroup {
  guvenli('Güvenli', 'anaparayı korumaya oynar'),
  koruyucu('Koruyucu', 'sıkışık yıllarda aranır'),
  piyasa('Piyasa', 'iniş çıkışı en sert olan taraf');

  const InvestmentGroup(this.label, this.blurb);

  final String label;

  /// Öbeğin ne olduğunu anlatan kısa not. Tavsiye vermez.
  final String blurb;
}

/// Bir yatırımın piyasa rejimine verdiği tepkinin ağırlıkları.
///
/// İki ortak etken var: **risk iştahı** (hisse ve fonu sürükler) ve
/// **korunma talebi** (altın ve dövizi sürükler). Böylece aynı yılda
/// "hisse -%20, fon +%40" gibi birbiriyle alakasız sonuçlar çıkmaz;
/// varlıklar kaba ama mantıklı biçimde birlikte hareket eder.
@immutable
class MarketSensitivity {
  const MarketSensitivity({
    required this.risk,
    required this.hedge,
    required this.inflation,
    required this.idiosyncratic,
  });

  /// Risk iştahı etkeninin ağırlığı.
  final double risk;

  /// Korunma talebi etkeninin ağırlığı.
  final double hedge;

  /// Enflasyon baskısının ağırlığı.
  final double inflation;

  /// prototypeOnly: varlığın kendine ait gürültüsünün genliği.
  final double idiosyncratic;
}

/// Bir yatırım türü.
@immutable
class InvestmentType {
  const InvestmentType({
    required this.id,
    required this.name,
    required this.description,
    required this.risk,
    required this.group,
    required this.icon,
    required this.carry,
    this.annualFee = 0,
    required this.heatSensitivity,
    required this.sensitivity,
    this.isTermDeposit = false,
  });

  final String id;
  final String name;

  /// Oyuncuya ne olduğunu anlatan tek cümle. Tavsiye vermez.
  final String description;

  final InvestmentRisk risk;
  final InvestmentGroup group;
  final IconData icon;

  /// prototypeOnly: varlığın kendi **ürettiği** yıllık akış (0,02 = %2).
  ///
  /// **Bu bir getiri garantisi değildir.** Hisse ve fonun temettü benzeri
  /// küçük bir akışı vardır; altın ve dövizin **yoktur** (0). Bir varlık
  /// carry üretmiyorsa uzun vadede beklenen büyümesi sıfırdır ve kazancın
  /// tamamı döngüden gelir — döngü de ortalamada sıfırlanır.
  ///
  /// Eski `drift` alanının yerini aldı; fark önemli: `drift` her yıl
  /// eklenen garantili bir eğilimdi, `carry` varlığın gerçekten ürettiği
  /// akıştır.
  final double carry;

  /// prototypeOnly: varlığın her yıl **kestiği** yönetim ücreti (0,02 = %2).
  ///
  /// Yalnızca fonda var: profesyonel yönetimin bedeli. Kârdan değil
  /// **anaparadan** kesilir, yani kötü yılda zararı büyütür.
  final double annualFee;

  /// prototypeOnly: değerleme ısısına duyarlılık (0-1).
  ///
  /// Yüksekse varlık balon yapmaya ve sert düzeltmeye yatkındır. Hisse en
  /// yüksek, vadeli sıfır (fiyatı yok, faizi var).
  final double heatSensitivity;

  final MarketSensitivity sensitivity;

  /// Vadeli hesap mı? Vadeli piyasa endeksiyle hareket etmez.
  final bool isTermDeposit;
}

/// prototypeOnly: vadeli hesabın yıllık getirisi.
///
/// **Paket AD'de düşürüldü: %6 → %3.** §11'in kuralı açık — vadelinin işi
/// nakdi korumak ve oynaklığı düşük tutmak; **servet büyütme makinesi
/// olmamak**. %6 ile 60 yılda 33 kat ediyordu ve "sadece vadeli" stratejisi
/// ölçümde 60 yılda medyan 60M ₺ çıkarıyordu — risksiz bir varlık için çok
/// fazla.
///
/// Gerçek bir mevduat faizi taklit edilmiyor; oran oyunun kendi ölçeğine
/// göre seçildi ve carry üreten varlıkların (hisse, fon) biraz altında
/// duruyor: güvenli olanın getirisi daha az olmalı.
const double kTermDepositRate = 0.03;

/// prototypeOnly: vadeli hesabın vadesi (yıl).
const int kTermDepositYears = 1;

/// prototypeOnly: vadeli hesabın en küçük tutarı (₺).
const int kTermDepositMinAmount = 5000;

/// prototypeOnly: yatırım yapılabilecek en küçük yaş.
///
/// Çocuk adına yatırım hesabı V1'de yok.
const int kInvestmentMinAge = 18;

/// prototypeOnly: bir alımın en küçük tutarı (₺).
const int kInvestmentMinBuy = 1000;

/// Oyundaki yatırım türleri. Ekran sırası bu listeden gelir.
const List<InvestmentType> kInvestmentTypes = <InvestmentType>[
  InvestmentType(
    id: 'vadeli',
    name: 'Vadeli Hesap',
    description:
        'Bir yıl bağlanıyor, sonunda faiziyle geri geliyor. Vade '
        'dolmadan bozarsan faizi yanar.',
    risk: InvestmentRisk.cokDusuk,
    group: InvestmentGroup.guvenli,
    icon: Icons.lock_clock_rounded,
    carry: kTermDepositRate,
    // Vadelinin fiyatı yok, faizi var: ısınmaz.
    heatSensitivity: 0,
    isTermDeposit: true,
    // Vadeli piyasayla hareket etmez; ağırlıklar kullanılmaz.
    sensitivity: MarketSensitivity(
      risk: 0,
      hedge: 0,
      inflation: 0,
      idiosyncratic: 0,
    ),
  ),
  InvestmentType(
    id: 'altin',
    name: 'Altın',
    description:
        'Sakin yıllarda pek kıpırdamaz, ortalık karışınca aranır. '
        'Her yıl artmaz.',
    risk: InvestmentRisk.dusukOrta,
    group: InvestmentGroup.koruyucu,
    icon: Icons.savings_rounded,
    // **Altın hiçbir şey üretmez: carry = 0 (§10).** Eskiden %7 garantili
    // eğilimi vardı ve 60 yılda medyan 18 kat yapıyordu — başka bir
    // garanti para makinesi. Artık kazancın tamamı döngüden gelir:
    // bazı dönemler çok iyi, bazıları yatay, bazıları ciddi düşüş.
    carry: 0.0,
    heatSensitivity: 0.55,
    sensitivity: MarketSensitivity(
      risk: -0.10,
      hedge: 0.85,
      inflation: 0.38,
      idiosyncratic: 0.095,
    ),
  ),
  InvestmentType(
    id: 'doviz',
    name: 'Döviz Sepeti',
    description:
        'Tek bir para birimi değil, karışık bir sepet. Enflasyonun '
        'sıkıştırdığı yıllarda daha çok hareket eder.',
    risk: InvestmentRisk.orta,
    group: InvestmentGroup.koruyucu,
    icon: Icons.currency_exchange_rounded,
    // Döviz sepeti de üretim yapmaz: carry = 0 (§10, §17).
    carry: 0.0,
    heatSensitivity: 0.45,
    sensitivity: MarketSensitivity(
      risk: -0.18,
      hedge: 0.70,
      inflation: 0.39,
      idiosyncratic: 0.085,
    ),
  ),
  InvestmentType(
    id: 'fon',
    name: 'Dengeli Fon',
    description:
        'İçinde biraz her şey var. Hisse kadar sallanmaz, altın kadar '
        'da sakin durmaz.',
    risk: InvestmentRisk.orta,
    group: InvestmentGroup.piyasa,
    icon: Icons.pie_chart_rounded,
    // Fon içindeki şirketlerin ürettiğinin bir kısmını yansıtır; yönetim
    // gideri ayrıca düşülür (`InvestmentEngine`).
    carry: 0.022,
    // Fonun brüt akışının büyük kısmını yönetim ücreti yiyor.
    annualFee: 0.014,
    heatSensitivity: 0.70,
    sensitivity: MarketSensitivity(
      risk: 0.60,
      hedge: 0.25,
      inflation: 0.10,
      idiosyncratic: 0.095,
    ),
  ),
  InvestmentType(
    id: 'hisse',
    name: 'Karma Hisse Sepeti',
    description:
        'İyi yılı çok iyi, kötü yılı çok kötü. Uzun soluklu bakmak '
        'gerekir.',
    risk: InvestmentRisk.yuksek,
    group: InvestmentGroup.piyasa,
    // Şirketler kâr üretir ve bir kısmını dağıtır: sepetin carry'si bu.
    // Garantili değil — şirket sağlığı bozulursa `IncidentEngine` bunu
    // aşağı çeker.
    icon: Icons.show_chart_rounded,
    carry: 0.028,
    heatSensitivity: 1.0,
    sensitivity: MarketSensitivity(
      risk: 1.25,
      hedge: 0.05,
      inflation: -0.05,
      // Paket AD'de düşürüldü (0,170 → 0,130). Sebep ölçüm: hissenin
      // yıllık oynaklığı %24 iken **medyanı** altının medyanının altına
      // düşüyordu (3,82x < 3,97x), yani riskten kaçan oyuncunun hisseye
      // dokunmak için hiçbir sebebi kalmıyordu. Bu tür tek bir şirket
      // değil **sepet**: tek isme özgü gürültünün bir kısmı sepet içinde
      // dağılmalı. Tek şirket riski ayrı modellenmiş durumda
      // (`kSingleFailureBasketCap`, şirket olayları) ve tek varlığa
      // yığılmanın cezası da ayrı (yoğunlaşma zammı).
      idiosyncratic: 0.130,
    ),
  ),
];

InvestmentType? investmentTypeById(String id) {
  for (final InvestmentType t in kInvestmentTypes) {
    if (t.id == id) return t;
  }
  return null;
}

/// Piyasa endeksiyle hareket eden türler (vadeli hariç).
List<InvestmentType> get kMarketInvestmentTypes => kInvestmentTypes
    .where((InvestmentType t) => !t.isTermDeposit)
    .toList(growable: false);

/// Bu öbekteki türler.
List<InvestmentType> investmentTypesIn(InvestmentGroup group) =>
    kInvestmentTypes
        .where((InvestmentType t) => t.group == group)
        .toList(growable: false);

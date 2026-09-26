/// Yatırım türleri ve risk kademeleri (D-162).
///
/// **Gerçek şirket, hisse, fon ya da banka adı geçmez.** Hepsi soyut:
/// "Karma Hisse Sepeti", "Dengeli Fon", "Döviz Sepeti". Oyun canlı fiyat
/// çekmez, gerçek tarihsel kur kullanmaz ve hiçbir yerde yatırım tavsiyesi
/// vermez.
///
/// **Getiriler gerçek Türkiye enflasyonuna göre kalibre edilmedi**, bilerek:
/// oyunun maaş ve ürün fiyatları 2026 TL çıpasına sabit (D-053) ve takvimsel
/// enflasyon simülasyonu yok. Yatırımı yılda %40-60 büyütmek oyunun bütün
/// ekonomisini parçalardı. Oranlar **oyun ekonomisine** göre seçildi.
///
/// Bütün sayılar `prototypeOnly`'dir (Q-165).
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
  guvenli('Güvenli'),
  koruyucu('Koruyucu'),
  piyasa('Piyasa');

  const InvestmentGroup(this.label);

  final String label;
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
    required this.drift,
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

  /// prototypeOnly: uzun vadeli yıllık eğilim (0,09 = %9).
  ///
  /// Beklenen değer budur; tek bir yıl bunu tutmak zorunda değildir.
  final double drift;

  final MarketSensitivity sensitivity;

  /// Vadeli hesap mı? Vadeli piyasa endeksiyle hareket etmez.
  final bool isTermDeposit;
}

/// prototypeOnly: vadeli hesabın yıllık getirisi.
///
/// **Brief'teki çelişki burada karara bağlandı.** Görevin 3. maddesinde
/// "100.000 ₺ → tahmini 132.000 ₺" örneği var (yıllık %32); 24. maddesi ise
/// "yatırımları gerçek Türkiye enflasyonuna göre %40-60 büyütme, bu oyunun
/// ekonomisini parçalar" diyor. 3. madde kendi içinde "mevcut oyun
/// ekonomisini bozmayacak oran kullan" diye devam ettiği için **24. madde
/// esas alındı**: oran oyun ölçeğine göre seçildi, gerçek mevduat faizi
/// taklit edilmedi. Sayı onay bekliyor (Q-165/1).
const double kTermDepositRate = 0.06;

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
    drift: kTermDepositRate,
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
    drift: 0.07, // prototypeOnly
    sensitivity: MarketSensitivity(
      risk: -0.10,
      hedge: 0.85,
      inflation: 0.35,
      idiosyncratic: 0.085,
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
    drift: 0.065, // prototypeOnly
    sensitivity: MarketSensitivity(
      risk: -0.18,
      hedge: 0.70,
      inflation: 0.55,
      idiosyncratic: 0.075,
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
    drift: 0.08, // prototypeOnly
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
    icon: Icons.show_chart_rounded,
    drift: 0.10, // prototypeOnly
    sensitivity: MarketSensitivity(
      risk: 1.25,
      hedge: 0.05,
      inflation: -0.05,
      idiosyncratic: 0.170,
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

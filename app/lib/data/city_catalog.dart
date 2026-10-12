/// Şehirler ve şehre göre fiyat katsayıları.
///
/// Faho'nun kesin kararı: konut fiyatları şehirden şehre aynı olmasın,
/// ama "İstanbul 10x, Amasya 1x" gibi aşırı değerler de olmasın.
///
/// Katsayılar 2026 Türkiye konut piyasasının **göreli** yapısına göre
/// seçildi (TCMB Konut Fiyat Endeksi'nin il kırılımındaki sıralama ölçü
/// alındı, tutarlar değil). Oyun canlı veri çekmez; bu tablo oyunun
/// kendi ölçeğidir ve `docs/ECONOMY_2026.md` içinde gerekçelidir.
///
/// Ölçek bilerek dar tutuldu: en pahalı şehir en ucuzun **2,2 katı**.
/// Böylece şehir farkı hissedilir ama oyuncuyu tek bir şehre hapsetmez.
library;

import 'package:flutter/foundation.dart';

import 'economy.dart';

/// Bir şehrin oyun içi fiyat profili.
@immutable
class CityProfile {
  const CityProfile({
    required this.name,
    required this.housingFactor,
    required this.vehicleFactor,
    this.opportunity = 0.5,
  });

  final String name;

  /// Konut fiyatlarının ülke ortalamasına göre çarpanı.
  final double housingFactor;

  /// Araç fiyatlarının çarpanı.
  ///
  /// Araçta şehir farkı konuttan **çok daha az**: araba taşınabilir bir
  /// maldır, fiyatı ülke genelinde birbirine yakındır.
  final double vehicleFactor;


  /// prototypeOnly: iş piyasasının genişliği (0-1) (D-159).
  ///
  /// Dar iş piyasasında **yalnızca en üst iki bant** bulunmaz: küçük bir
  /// ilde reklam yönetmeni ya da beyin cerrahisi ilanı çıkmaz. Ofis ve
  /// üniversite meslekleri **her ilde** vardır — Kayseri'de ofis işi
  /// olmaması gerçekçi olmazdı.
  ///
  /// Sayı konut fiyatından türetilmedi (kötü bir vekil olurdu); şehrin
  /// nüfusu ve iş merkezi olma rolüne göre elle yazıldı. Bir
  /// "gelişmişlik notu" değildir, oyunun iş çeşitliliği ölçüsüdür.
  final double opportunity;
}

/// Oyundaki şehirler. `name_pool.dart` içindeki [sehirler] listesiyle
/// birebir aynı adları taşır; `test/city_market_test.dart` bunu denetler.
const List<CityProfile> kCityProfiles = <CityProfile>[
  CityProfile(
    name: 'İstanbul',
    housingFactor: 2.20,
    vehicleFactor: 1.06,
    opportunity: 1.0,
  ),
  CityProfile(
    name: 'Ankara',
    housingFactor: 1.55,
    vehicleFactor: 1.03,
    opportunity: 0.95,
  ),
  CityProfile(
    name: 'İzmir',
    housingFactor: 1.72,
    vehicleFactor: 1.04,
    opportunity: 0.9,
  ),
  CityProfile(
    name: 'Antalya',
    housingFactor: 1.78,
    vehicleFactor: 1.04,
    opportunity: 0.76,
  ),
  CityProfile(
    name: 'Bursa',
    housingFactor: 1.38,
    vehicleFactor: 1.02,
    opportunity: 0.78,
  ),
  CityProfile(
    name: 'Kocaeli',
    housingFactor: 1.34,
    vehicleFactor: 1.02,
    opportunity: 0.72,
  ),
  CityProfile(
    name: 'Adana',
    housingFactor: 1.12,
    vehicleFactor: 1.00,
    opportunity: 0.7,
  ),
  CityProfile(
    name: 'Gaziantep',
    housingFactor: 1.08,
    vehicleFactor: 1.00,
    opportunity: 0.64,
  ),
  CityProfile(
    name: 'Konya',
    housingFactor: 1.10,
    vehicleFactor: 1.00,
    opportunity: 0.66,
  ),
  CityProfile(
    name: 'Kayseri',
    housingFactor: 1.06,
    vehicleFactor: 1.00,
    opportunity: 0.62,
  ),
  CityProfile(
    name: 'Eskişehir',
    housingFactor: 1.20,
    vehicleFactor: 1.01,
    opportunity: 0.6,
  ),
  CityProfile(
    name: 'Denizli',
    housingFactor: 1.09,
    vehicleFactor: 1.00,
    opportunity: 0.54,
  ),
  CityProfile(
    name: 'Samsun',
    housingFactor: 1.05,
    vehicleFactor: 1.00,
    opportunity: 0.55,
  ),
  CityProfile(
    name: 'Trabzon',
    housingFactor: 1.14,
    vehicleFactor: 1.01,
    opportunity: 0.5,
  ),
  CityProfile(
    name: 'Aydın',
    housingFactor: 1.16,
    vehicleFactor: 1.00,
    opportunity: 0.48,
  ),
  CityProfile(
    name: 'Malatya',
    housingFactor: 0.94,
    vehicleFactor: 0.99,
    opportunity: 0.45,
  ),
  CityProfile(
    name: 'Sivas',
    housingFactor: 0.90,
    vehicleFactor: 0.99,
    opportunity: 0.4,
  ),
  CityProfile(
    name: 'Zonguldak',
    housingFactor: 0.96,
    vehicleFactor: 0.99,
    opportunity: 0.4,
  ),
  CityProfile(
    name: 'Erzurum',
    housingFactor: 0.92,
    vehicleFactor: 0.99,
    opportunity: 0.44,
  ),
  CityProfile(
    name: 'Diyarbakır',
    housingFactor: 1.00,
    vehicleFactor: 0.99,
    opportunity: 0.56,
  ),
  CityProfile(
    name: 'Van',
    housingFactor: 0.95,
    vehicleFactor: 0.99,
    opportunity: 0.5,
  ),
  CityProfile(
    name: 'Amasya',
    housingFactor: 0.88,
    vehicleFactor: 0.99,
    opportunity: 0.3,
  ),
];

/// Bu şehrin profili; tanınmayan şehir için ülke ortalaması döner.
///
/// Uydurma bir katsayı üretilmez: listede olmayan şehir 1,0 alır.
CityProfile cityProfile(String name) {
  for (final CityProfile c in kCityProfiles) {
    if (c.name == name) return c;
  }
  return CityProfile(name: name, housingFactor: 1.0, vehicleFactor: 1.0);
}

/// prototypeOnly: bir maaş bandının bu şehirde bulunabilmesi için gereken
/// en az fırsat düzeyi (D-159).
///
/// Alt bantlar her şehirde vardır: her ilde market kasiyeri aranır. Üst
/// bantlar yalnızca iş piyasası geniş şehirlerde çıkar. Sayılar
/// `prototypeOnly` (Q-162).
double prototypeOnlyOpportunityNeeded(SalaryBand band) {
  switch (band) {
    // Her ilde vardır: market kasiyeri, garson, tesisatçı, öğretmen.
    case SalaryBand.giris:
    case SalaryBand.yarimZamanli:
    case SalaryBand.nitelikliHizmet:
    case SalaryBand.ustaTeknik:
    case SalaryBand.ofisUzmanlik:
    case SalaryBand.profesyonel:
    // **Yaratıcı meslekler de her ilde açık.** Müzisyenlik ve yazarlık
    // hobiyle açılıyor (Paket 39); şehre bağlamak, yıllarca hobisine
    // emek veren oyuncuyu doğduğu şehir yüzünden cezalandırırdı. Bu
    // sektör oyunda zaten çevrimiçi kitleye dayanıyor (D-027).
    case SalaryBand.yaraticiDegisken:
      return 0;
    // Dar giriş, uzun eğitim: yalnızca büyük şehirlerde ilan çıkar.
    case SalaryBand.yuksekUzmanlik:
      return 0.7;
  }
}

/// Bu maaş bandındaki bir iş bu şehirde bulunur mu? (D-159)
bool bandAvailableIn(String city, SalaryBand band) =>
    cityProfile(city).opportunity >= prototypeOnlyOpportunityNeeded(band);

/// **Geçim gideri ve maaş şehirden şehre değişmiyor** (D-159).
///
/// Denendi ve **bilerek geri alındı.** İkisi birlikte hareket etmek
/// zorunda: yalnızca gideri şehre bağlamak, mevcut denge kuralını
/// ("düşük gelirli de maaşının üçte birini biriktirebilmeli") kırıyordu
/// — ölçüldü, garsonun elinde kalan pay %34'ten %21,5'e iniyordu. İkisi
/// birlikte aynı çarpanla hareket edince de maaşlı çalışan için etki
/// sıfırlanıyor, geriye yalnızca onlarca testi sayı peşinde koşturan bir
/// değişiklik kalıyor.
///
/// Bu yüzden şehrin farkı **konut ve araç fiyatında** (zaten vardı) ve
/// **iş piyasasının genişliğinde** (yeni) tutuldu. Geçim giderinin şehre
/// bağlanıp bağlanmayacağı Q-162'de sorulmuştur.

/// Konut fiyatının bu şehirdeki karşılığı.
int housingPriceIn(String city, int basePrice) =>
    _yuvarla(basePrice * cityProfile(city).housingFactor);

/// Araç fiyatının bu şehirdeki karşılığı.
int vehiclePriceIn(String city, int basePrice) =>
    _yuvarla(basePrice * cityProfile(city).vehicleFactor);

/// Okunaklı olsun diye bin ₺'nin katlarına yuvarlar.
int _yuvarla(double tutar) {
  if (tutar < 1000) return tutar.round();
  return (tutar / 1000).round() * 1000;
}

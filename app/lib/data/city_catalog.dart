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

/// Bir şehrin oyun içi fiyat profili.
@immutable
class CityProfile {
  const CityProfile({
    required this.name,
    required this.housingFactor,
    required this.vehicleFactor,
  });

  final String name;

  /// Konut fiyatlarının ülke ortalamasına göre çarpanı.
  final double housingFactor;

  /// Araç fiyatlarının çarpanı.
  ///
  /// Araçta şehir farkı konuttan **çok daha az**: araba taşınabilir bir
  /// maldır, fiyatı ülke genelinde birbirine yakındır.
  final double vehicleFactor;
}

/// Oyundaki şehirler. `name_pool.dart` içindeki [sehirler] listesiyle
/// birebir aynı adları taşır; `test/city_market_test.dart` bunu denetler.
const List<CityProfile> kCityProfiles = <CityProfile>[
  CityProfile(name: 'İstanbul', housingFactor: 2.20, vehicleFactor: 1.06),
  CityProfile(name: 'Ankara', housingFactor: 1.55, vehicleFactor: 1.03),
  CityProfile(name: 'İzmir', housingFactor: 1.72, vehicleFactor: 1.04),
  CityProfile(name: 'Antalya', housingFactor: 1.78, vehicleFactor: 1.04),
  CityProfile(name: 'Bursa', housingFactor: 1.38, vehicleFactor: 1.02),
  CityProfile(name: 'Kocaeli', housingFactor: 1.34, vehicleFactor: 1.02),
  CityProfile(name: 'Adana', housingFactor: 1.12, vehicleFactor: 1.00),
  CityProfile(name: 'Gaziantep', housingFactor: 1.08, vehicleFactor: 1.00),
  CityProfile(name: 'Konya', housingFactor: 1.10, vehicleFactor: 1.00),
  CityProfile(name: 'Kayseri', housingFactor: 1.06, vehicleFactor: 1.00),
  CityProfile(name: 'Eskişehir', housingFactor: 1.20, vehicleFactor: 1.01),
  CityProfile(name: 'Denizli', housingFactor: 1.09, vehicleFactor: 1.00),
  CityProfile(name: 'Samsun', housingFactor: 1.05, vehicleFactor: 1.00),
  CityProfile(name: 'Trabzon', housingFactor: 1.14, vehicleFactor: 1.01),
  CityProfile(name: 'Aydın', housingFactor: 1.16, vehicleFactor: 1.00),
  CityProfile(name: 'Malatya', housingFactor: 0.94, vehicleFactor: 0.99),
  CityProfile(name: 'Sivas', housingFactor: 0.90, vehicleFactor: 0.99),
  CityProfile(name: 'Zonguldak', housingFactor: 0.96, vehicleFactor: 0.99),
  CityProfile(name: 'Erzurum', housingFactor: 0.92, vehicleFactor: 0.99),
  CityProfile(name: 'Diyarbakır', housingFactor: 1.00, vehicleFactor: 0.99),
  CityProfile(name: 'Van', housingFactor: 0.95, vehicleFactor: 0.99),
  CityProfile(name: 'Amasya', housingFactor: 0.88, vehicleFactor: 0.99),
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

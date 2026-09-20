/// Oyunun **ortak ekonomi ölçeği**.
///
/// Fiyatlar ve maaşlar tek bir tabloya göre belirlenir; böylece aynı para
/// birimi ve aynı dönem (yıl) üzerinden okunur bir denge kurulur. Bu tablo
/// **gerçek piyasa fiyatlarının kopyası değildir**: oyun içi, kendi içinde
/// tutarlı bir ölçektir ve tamamı `prototypeOnly`'dir
/// (`docs/DESIGN_REVIEW_QUEUE.md`, Q-055).
///
/// Ölçek (yıllık, ₺):
///
/// | Kalem                         | Değer aralığı        |
/// |-------------------------------|----------------------|
/// | Aileden istenen küçük para    | 150 - 600            |
/// | Bayram harçlığı (olay)        | 1.500 - 3.000        |
/// | Küçük eşya (oyuncak, kitap)   | 20 - 900             |
/// | Kıyafet, ayakkabı, spor       | 450 - 1.500          |
/// | Kol saati, kulaklık, radyo    | 900 - 2.200          |
/// | Telefon, konsol, bilgisayar   | 18.000 - 32.000      |
/// | Bisiklet                      | 9.000                |
/// | Motosiklet                    | 75.000 - 190.000     |
/// | Otomobil                      | 320.000 - 3.400.000  |
/// | Konut                         | 1.800.000 - 9.500.000|
/// | Yıllık maaşlar                | 165.000 - 720.000    |
///
/// Okunabilirlik ölçütü: tam zamanlı bir işte **bir yıl** çalışmak bir
/// telefon + birkaç küçük eşya demektir; **iki-üç yıl** biriktirmek
/// ikinci el bir otomobile, uzun yıllar biriktirmek küçük bir daireye
/// yaklaştırır. Bu, oyuncunun neyin ne kadar sürdüğünü sezmesi içindir.
library;

abstract final class Economy {
  /// prototypeOnly: aileden istenebilecek küçük para aralığı.
  static const int prototypeOnlyPocketMoneyMin = 150;
  static const int prototypeOnlyPocketMoneyMax = 600;

  /// prototypeOnly: "değerli eşya" sayılan eşik.
  static const int prototypeOnlyValuableThreshold = 2000;

  /// prototypeOnly: araç sayılan eşya eşiği (bilgi amaçlı).
  static const int prototypeOnlyVehicleThreshold = 50000;
}

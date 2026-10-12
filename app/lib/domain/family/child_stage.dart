/// Çocuğun yaş kademesi (Paket BK/4).
///
/// **Eşikler uydurulmadı:** D-180 (Q-200, 6 Ekim 2026) sohbet ve vakit
/// geçirme metinleri için dört kademe kararlaştırdı — **0-3** (konuşmayan
/// ya da yeni konuşan), **4-12** (okul çağı), **13-17** (ergen), **18+**
/// (yetişkin). Ebeveynlik eylemleri de aynı kademeleri kullanır.
///
/// Q-203'te kademe "bebek 0-2" diye önerilmişti; o bir **öneriydi**,
/// D-180 ise onaylanmış kural. Çakışmada kural kazandı: ikinci bir yaş
/// sınırı eklenmedi, çünkü iki ayrı kademeleme bir süre sonra birbirini
/// yalanlar (D-180'in kendisi tam bu yüzden yazıldı: sohbet dalı 12,
/// vakit geçirme dalı 3 diyordu).
///
/// Kademe **listenin şeklini** belirler: hangi eylem o yaşta görünür.
/// Kademe içindeki ince koşullar (harçlık 7 yaşından, kurs 6 yaşından)
/// eylemin kendi uygunluk denetiminde durur; kademe onları ezmez.
library;

enum ChildStage {
  bebek('Bebek', 0, 3),
  cocuk('Çocuk', 4, 12),
  ergen('Ergen', 13, 17),
  yetiskin('Yetişkin', 18, 200);

  const ChildStage(this.label, this.firstAge, this.lastAge);

  /// Ekranda yazılan kademe adı.
  final String label;

  /// Kademenin ilk yaşı (dahil).
  final int firstAge;

  /// Kademenin son yaşı (dahil).
  final int lastAge;

  /// Bu yaşın kademesi.
  static ChildStage of(int age) {
    for (final ChildStage k in values) {
      if (age >= k.firstAge && age <= k.lastAge) return k;
    }
    // 200'den büyük yaş yok; yine de sessiz bir hata bırakılmıyor.
    return yetiskin;
  }

  bool get isMinor => this != yetiskin;
}

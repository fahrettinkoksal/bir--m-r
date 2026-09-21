/// Kayıt dosyasının biçimi ve hata türleri.
library;

/// Kayıt dosyası biçim sürümü.
///
/// Oyun verisi değişip eski kayıtlar okunamaz hâle geldiğinde bu sayı
/// artırılır ve [SaveMigrations] içine bir dönüştürme adımı eklenir.
/// Sürüm bilgisi kayıt dosyasının **en dış** katmanındadır; böylece içerik
/// şeması değişse bile dosyanın hangi sürüme ait olduğu her zaman okunabilir.
const int kSaveFormatVersion = 28;

/// Bu sürümün okuyabildiği **en eski** biçim.
///
/// **Faho'nun kararı (Paket 12):** geriye dönük olarak sınırsız sürüm
/// taşınmaz; "çok büyük güncellemeler olmadığı sürece" son **5 sürüm**
/// yeterlidir. Böylece göç zinciri kısa ve denetlenebilir kalır.
///
/// Bu taban **bilerek** yükseltilir: her sürüm artışında otomatik
/// kaymaz, yoksa eski kayıtlar sessizce açılamaz hâle gelir. Daha eski
/// bir kayıt açılmak istenirse oyuncuya anlaşılır bir mesaj gösterilir
/// ve **kayıt silinmez**.
const int kMinReadableSaveVersion = 23;

/// Kayıt dosyası okunamadığında atılır.
///
/// Uygulama bu hatada **çökmez**: kullanıcıya anlaşılır bir mesaj gösterilir
/// ve kayıt dosyasına dokunulmaz (habersiz silme veya üzerine yazma yok).
class SaveFormatException implements Exception {
  const SaveFormatException(this.message, {this.isUnsupportedVersion = false});

  /// Kullanıcıya gösterilebilecek Türkçe açıklama.
  final String message;

  /// Kayıt bozuk değil, yalnızca bu uygulama sürümünden **yeni** mi?
  final bool isUnsupportedVersion;

  @override
  String toString() => 'SaveFormatException: $message';
}

/// Eski sürümdeki kayıtların güncel şemaya taşınması.
///
/// Şu an tek bir sürüm var, bu yüzden dönüştürme adımı yok. Yeni sürüm
/// eklendiğinde buraya `1 -> 2` gibi adımlar yazılır ve [migrate] onları
/// sırayla uygular; böylece oyuncunun eski hayatı silinmek zorunda kalmaz.
abstract final class SaveMigrations {
  /// [from] sürümündeki gövdeyi güncel sürüme taşır.
  static Map<String, Object?> migrate(
    Map<String, Object?> body,
    int from,
  ) {
    if (from == kSaveFormatVersion) return body;
    if (from > kSaveFormatVersion) {
      throw const SaveFormatException(
        'Bu kayıt, uygulamanın daha yeni bir sürümüyle oluşturulmuş. '
        'Kaydı açabilmek için oyunu güncellemen gerekiyor.',
        isUnsupportedVersion: true,
      );
    }
    if (from < kMinReadableSaveVersion) {
      // Kayıt dosyası **silinmez**; yalnızca açılamadığı söylenir.
      throw const SaveFormatException(
        'Bu kayıt oyunun çok eski bir sürümünden kalma ve artık '
        'açılamıyor. Dosya silinmedi; yeni bir hayat başlatabilirsin.',
        isUnsupportedVersion: true,
      );
    }
    Map<String, Object?> guncel = body;
    if (from <= 23) guncel = _v23ToV24(guncel);
    if (from <= 24) guncel = _v24ToV25(guncel);
    if (from <= 25) guncel = _v25ToV26(guncel);
    if (from <= 26) guncel = _v26ToV27(guncel);
    if (from <= 27) guncel = _v27ToV28(guncel);
    return guncel;
  }

  /// Sürüm 27 → 28: olayların kaç kez çıktığı sayılmaya başlandı
  /// (Paket 20).
  ///
  /// Eski kayıtlarda sayaç yok. Görülmüş her olay **bir kez** görülmüş
  /// sayılır; böylece devam eden hayatlarda tekrar sönümü sıfırdan
  /// başlamaz ama uydurma bir sayı da yazılmaz.
  static Map<String, Object?> _v27ToV28(Map<String, Object?> body) {
    if (body.containsKey('eventSeenCounts')) return body;
    final Object? gorulen = body['seenEventIds'];
    final Map<String, int> sayaclar = <String, int>{};
    if (gorulen is List) {
      for (final Object? id in gorulen) {
        if (id is String) sayaclar[id] = 1;
      }
    }
    return <String, Object?>{...body, 'eventSeenCounts': sayaclar};
  }

  /// Sürüm 26 → 27: okul başarısı eklendi (Paket 13).
  ///
  /// Eski kayıtlarda not ortalaması yoktur; **geriye dönük not
  /// uydurulmaz**. Öğrenci sınıfta kalmış sayılmaz, burs geçmişi boş
  /// başlar ve eğitim durumu olduğu gibi korunur.
  static Map<String, Object?> _v26ToV27(Map<String, Object?> body) => body;

  /// Sürüm 25 → 26: emeklilik ve torunlar eklendi (Paket 12).
  ///
  /// Eski kayıtlarda emeklilik bilgisi yoktur; oyuncu emekli sayılmaz ve
  /// **geriye dönük aylık bağlanmaz**. Torun da geriye dönük üretilmez;
  /// yalnızca doğduğu yıl oluşur.
  static Map<String, Object?> _v25ToV26(Map<String, Object?> body) => body;

  /// Sürüm 24 → 25: kısa seyahat ve yakınlarla gezi eklendi (Paket 11).
  ///
  /// Eski kayıtlarda gezi yoktur; liste boş açılır ve **geriye dönük gezi
  /// uydurulmaz**. Oyuncunun yaşadığı ve doğduğu şehir değişmez.
  static Map<String, Object?> _v24ToV25(Map<String, Object?> body) => body;

  /// Sürüm 23 → 24: sosyal medya geliri ve sponsorluk eklendi (Paket 10).
  ///
  /// Eski kayıtlarda paylaşımların kazancı yoktur; **geriye dönük gelir
  /// üretilmez** (kazanç 0 kalır) ve bekleyen sponsorluk olmaz. Takipçi,
  /// içerik geçmişi ve Ün değerleri olduğu gibi korunur.
  static Map<String, Object?> _v23ToV24(Map<String, Object?> body) => body;

  /// Sürüm 22 → 23: kariyer geçmişi, görev seviyesi ve iş arkadaşları
  /// eklendi (Paket 9).
  ///
  /// Eski kayıtlarda görev seviyesi 0, maaş katalog maaşı ve kariyer
  /// geçmişi boştur. **Geriye dönük iş geçmişi uydurulmaz**: oyuncunun
  /// önceki işleri `pastJobIds` içinde durduğu gibi kalır. İş arkadaşı da
  /// geriye dönük üretilmez; yeni işe girildiğinde tanışılır.
  // ---------------------------------------------------------------
  // Daha eski sürümler
  //
  // **Faho'nun kararı (Paket 12):** geriye dönük olarak yalnızca son beş
  // sürüm taşınır. Sürüm 22 ve öncesine ait dönüştürme adımları bu
  // yüzden kaldırıldı; gerekirse sürüm geçmişinden geri alınabilirler.
  // Taban (`kMinReadableSaveVersion`) düşürülmeden bu adımlar zaten hiç
  // çalışmıyordu.
  // ---------------------------------------------------------------
}

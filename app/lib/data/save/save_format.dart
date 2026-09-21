/// Kayıt dosyasının biçimi ve hata türleri.
library;

/// Kayıt dosyası biçim sürümü.
///
/// Oyun verisi değişip eski kayıtlar okunamaz hâle geldiğinde bu sayı
/// artırılır ve [SaveMigrations] içine bir dönüştürme adımı eklenir.
/// Sürüm bilgisi kayıt dosyasının **en dış** katmanındadır; böylece içerik
/// şeması değişse bile dosyanın hangi sürüme ait olduğu her zaman okunabilir.
const int kSaveFormatVersion = 30;

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
const int kMinReadableSaveVersion = 25;

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
    if (from <= 25) guncel = _v25ToV26(guncel);
    if (from <= 26) guncel = _v26ToV27(guncel);
    if (from <= 27) guncel = _v27ToV28(guncel);
    if (from <= 28) guncel = _v28ToV29(guncel);
    if (from <= 29) guncel = _v29ToV30(guncel);
    return guncel;
  }

  /// Sürüm 29 → 30: hamilelik bir süreç oldu (Paket 26).
  ///
  /// Eski kayıtlarda süren hamilelik yoktur. **Geriye dönük bebek
  /// beklenmez:** alan boş kalır, var olan çocuklar olduğu gibi korunur.
  static Map<String, Object?> _v29ToV30(Map<String, Object?> body) => body;

  /// Sürüm 28 → 29: teklif/düğün ayrımı, korunma ve doğurganlık
  /// (Paket 25).
  ///
  /// Eski kayıtlarda bekleyen düğün, deneme sayacı ve doğurganlık bilgisi
  /// yoktur. **Hiçbiri geriye dönük uydurulmaz:** bekleyen düğün boş
  /// kalır, sayaç sıfırdan başlar, kimse kısır sayılmaz. Kurulmuş
  /// evlilikler olduğu gibi korunur.
  ///
  /// Alanların hepsi eklemeli olduğu için gövdeye dokunulmaz; sürüm
  /// yalnızca kaydın hangi şemayla yazıldığını belgelemek için artar.
  static Map<String, Object?> _v28ToV29(Map<String, Object?> body) => body;

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

  // ---------------------------------------------------------------
  // Daha eski sürümler
  //
  // **Faho'nun kararı (Paket 12):** geriye dönük olarak yalnızca son beş
  // sürüm taşınır ve bunu kalıcı bir test zorunlu kılar. Sürüm 24 ve
  // öncesine ait dönüştürme adımları bu yüzden kaldırıldı; gerekirse
  // sürüm geçmişinden geri alınabilirler.
  // Taban (`kMinReadableSaveVersion`) düşürülmeden bu adımlar zaten hiç
  // çalışmıyordu.
  // ---------------------------------------------------------------
}

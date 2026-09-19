/// Kayıt dosyasının biçimi ve hata türleri.
library;

/// Kayıt dosyası biçim sürümü.
///
/// Oyun verisi değişip eski kayıtlar okunamaz hâle geldiğinde bu sayı
/// artırılır ve [SaveMigrations] içine bir dönüştürme adımı eklenir.
/// Sürüm bilgisi kayıt dosyasının **en dış** katmanındadır; böylece içerik
/// şeması değişse bile dosyanın hangi sürüme ait olduğu her zaman okunabilir.
const int kSaveFormatVersion = 1;

/// Bu sürümün okuyabildiği **en eski** biçim.
const int kMinReadableSaveVersion = 1;

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
      throw const SaveFormatException(
        'Bu kayıt, artık desteklenmeyen eski bir biçimde.',
        isUnsupportedVersion: true,
      );
    }
    // Buraya sürüm adımları eklenecek:
    //   if (from <= 1) body = _v1ToV2(body);
    return body;
  }
}

/// Kayıt dosyasının biçimi ve hata türleri.
library;

/// Kayıt dosyası biçim sürümü.
///
/// Oyun verisi değişip eski kayıtlar okunamaz hâle geldiğinde bu sayı
/// artırılır ve [SaveMigrations] içine bir dönüştürme adımı eklenir.
/// Sürüm bilgisi kayıt dosyasının **en dış** katmanındadır; böylece içerik
/// şeması değişse bile dosyanın hangi sürüme ait olduğu her zaman okunabilir.
const int kSaveFormatVersion = 2;

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
    Map<String, Object?> guncel = body;
    if (from <= 1) guncel = _v1ToV2(guncel);
    return guncel;
  }

  /// Sürüm 1 → 2: okul kişileri kademeye değil **okula ve sınıfa** bağlandı.
  ///
  /// Eski kayıtlarda yalnızca `schoolLevel` vardı. Kimlikler kademeden
  /// türetilerek doldurulur; böylece oyuncunun eski hayatı, sınıf
  /// arkadaşları ve öğretmenleri kaybolmadan açılır.
  static Map<String, Object?> _v1ToV2(Map<String, Object?> body) {
    String? okulKimligi(Object? levelName) =>
        levelName is String ? 'okul-$levelName' : null;
    String? sinifKimligi(Object? levelName) =>
        levelName is String ? 'sinif-$levelName' : null;

    final Object? people = body['people'];
    if (people is List) {
      for (final Object? kisi in people) {
        if (kisi is! Map) continue;
        final Object? level = kisi['schoolLevel'];
        if (kisi['schoolTie'] == null || level == null) continue;
        kisi['schoolId'] ??= okulKimligi(level);
        kisi['classId'] ??= sinifKimligi(level);
      }
    }

    final Object? education = body['education'];
    if (education is Map) {
      final Object? grade = education['grade'];
      final Object? enrolled = education['enrolled'];
      if (enrolled == true && grade is int) {
        final String? levelName = switch (grade) {
          >= 1 && <= 4 => 'ilkokul',
          >= 5 && <= 8 => 'ortaokul',
          >= 9 && <= 12 => 'lise',
          _ => null,
        };
        education['schoolId'] ??= okulKimligi(levelName);
        education['classId'] ??= sinifKimligi(levelName);
      }
    }

    return body;
  }
}

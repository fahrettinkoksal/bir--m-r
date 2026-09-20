/// Kayıt dosyasının biçimi ve hata türleri.
library;

/// Kayıt dosyası biçim sürümü.
///
/// Oyun verisi değişip eski kayıtlar okunamaz hâle geldiğinde bu sayı
/// artırılır ve [SaveMigrations] içine bir dönüştürme adımı eklenir.
/// Sürüm bilgisi kayıt dosyasının **en dış** katmanındadır; böylece içerik
/// şeması değişse bile dosyanın hangi sürüme ait olduğu her zaman okunabilir.
const int kSaveFormatVersion = 7;

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
    if (from <= 2) guncel = _v2ToV3(guncel);
    if (from <= 3) guncel = _v3ToV4(guncel);
    if (from <= 4) guncel = _v4ToV5(guncel);
    if (from <= 5) guncel = _v5ToV6(guncel);
    if (from <= 6) guncel = _v6ToV7(guncel);
    return guncel;
  }

  /// Sürüm 6 → 7: üniversite sınav puanı ve bekleyen mülakat eklendi.
  ///
  /// Eski kayıtlarda bu alanlar yoktur. Sınav puanı boş kalır ve başvuru
  /// ekranı açıldığında **bir kez** hesaplanır; oyuncunun hayatı korunur.
  static Map<String, Object?> _v6ToV7(Map<String, Object?> body) {
    // Yeni alanların ikisi de boş olabilir; okuyucu `null` durumunu zaten
    // ele aldığı için ek bir dönüştürme gerekmez.
    return body;
  }

  /// Sürüm 5 → 6: sosyal medya hesapları eklendi.
  ///
  /// Eski kayıtlarda hesap yoktur; boş listeyle açılır. Hesabı olmayan
  /// oyuncuya o platformdan paylaşım veya olay gelmez.
  static Map<String, Object?> _v5ToV6(Map<String, Object?> body) {
    body['socialAccounts'] ??= <Object?>[];
    return body;
  }

  /// Sürüm 4 → 5: aktiviteler (kitap ilerlemesi ve saç stili) eklendi.
  ///
  /// Eski kayıtlarda bunlar yoktur; boş değerlerle açılır ve oyuncunun
  /// hayatı olduğu gibi korunur.
  static Map<String, Object?> _v4ToV5(Map<String, Object?> body) {
    body['books'] ??= <Object?>[];
    return body;
  }

  /// Sürüm 3 → 4: lise alanı, üniversite ve meslek alanları eklendi.
  ///
  /// Eski kayıtlarda bunlar yoktur; boş değerlerle doldurulur. Oyuncunun
  /// hayatı, cüzdanı, kişileri ve eşyaları aynen korunur.
  static Map<String, Object?> _v3ToV4(Map<String, Object?> body) {
    final Object? education = body['education'];
    if (education is Map) {
      // Eski kayıtta bu alanlar hiç yoktu; boş değerlerle açılır.
      education['universityFinished'] ??= false;
    }
    body['career'] ??= <String, Object?>{
      'jobId': null,
      'startedAtAge': null,
      'lastPaidAge': null,
      'pastJobIds': <String>[],
    };
    return body;
  }

  /// Sürüm 2 → 3: eşyalar tür kümesinden **gerçek eşya örneklerine** geçti.
  ///
  /// Eski kayıtta yalnızca `possessions` (tür kimlikleri kümesi) vardı.
  /// Her tür için **tek** bir eşya örneği oluşturulur — gereksiz kopya
  /// üretilmez. Hediye geçmişi varsa edinilme yolu, veren kişi ve yaş
  /// oradan doldurulur; böylece oyuncunun eşyaları ve geçmişi kaybolmaz.
  static Map<String, Object?> _v2ToV3(Map<String, Object?> body) {
    if (body['items'] != null) return body;

    final Object? possessions = body['possessions'];
    final List<String> turler = <String>[
      if (possessions is List)
        for (final Object? e in possessions)
          if (e is String) e,
    ];

    // Hediye geçmişinden "bu türü kim, kaç yaşında verdi" bilgisini çıkar.
    final Map<String, Map<String, Object?>> hediyeler =
        <String, Map<String, Object?>>{};
    final Object? gifts = body['gifts'];
    if (gifts is List) {
      for (final Object? g in gifts) {
        if (g is! Map) continue;
        if (g['toId'] != 'oyuncu') continue;
        final Object? itemId = g['itemId'];
        if (itemId is String) {
          hediyeler[itemId] = <String, Object?>{
            'fromPersonId': g['fromId'],
            'age': g['age'],
          };
        }
      }
    }

    final Object? player = body['player'];
    final int yas = player is Map && player['age'] is int
        ? player['age']! as int
        : 0;

    final List<Map<String, Object?>> items = <Map<String, Object?>>[];
    int n = 1;
    for (final String tur in turler) {
      final Map<String, Object?>? hediye = hediyeler[tur];
      items.add(<String, Object?>{
        'id': 'esya-${n++}',
        'typeId': tur,
        'acquiredAtAge': hediye?['age'] ?? yas,
        'source': hediye == null ? 'bilinmiyor' : 'hediye',
        'fromPersonId': hediye?['fromPersonId'],
        // Eşyanın geçmişi bilinmediği için makul bir orta kondisyon.
        'condition': 75,
        'attachments': <String>[],
      });
    }

    body['items'] = items;
    body.remove('possessions');
    return body;
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

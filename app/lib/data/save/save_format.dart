/// Kayıt dosyasının biçimi ve hata türleri.
library;

/// Kayıt dosyası biçim sürümü.
///
/// Oyun verisi değişip eski kayıtlar okunamaz hâle geldiğinde bu sayı
/// artırılır ve [SaveMigrations] içine bir dönüştürme adımı eklenir.
/// Sürüm bilgisi kayıt dosyasının **en dış** katmanındadır; böylece içerik
/// şeması değişse bile dosyanın hangi sürüme ait olduğu her zaman okunabilir.
const int kSaveFormatVersion = 23;

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
    if (from <= 7) guncel = _v7ToV8(guncel);
    if (from <= 8) guncel = _v8ToV9(guncel);
    if (from <= 9) guncel = _v9ToV10(guncel);
    if (from <= 10) guncel = _v10ToV11(guncel);
    if (from <= 11) guncel = _v11ToV12(guncel);
    if (from <= 12) guncel = _v12ToV13(guncel);
    if (from <= 13) guncel = _v13ToV14(guncel);
    if (from <= 14) guncel = _v14ToV15(guncel);
    if (from <= 15) guncel = _v15ToV16(guncel);
    if (from <= 16) guncel = _v16ToV17(guncel);
    if (from <= 17) guncel = _v17ToV18(guncel);
    if (from <= 18) guncel = _v18ToV19(guncel);
    if (from <= 19) guncel = _v19ToV20(guncel);
    if (from <= 20) guncel = _v20ToV21(guncel);
    if (from <= 21) guncel = _v21ToV22(guncel);
    if (from <= 22) guncel = _v22ToV23(guncel);
    return guncel;
  }

  /// Sürüm 22 → 23: kariyer geçmişi, görev seviyesi ve iş arkadaşları
  /// eklendi (Paket 9).
  ///
  /// Eski kayıtlarda görev seviyesi 0, maaş katalog maaşı ve kariyer
  /// geçmişi boştur. **Geriye dönük iş geçmişi uydurulmaz**: oyuncunun
  /// önceki işleri `pastJobIds` içinde durduğu gibi kalır. İş arkadaşı da
  /// geriye dönük üretilmez; yeni işe girildiğinde tanışılır.
  static Map<String, Object?> _v22ToV23(Map<String, Object?> body) => body;

  /// Sürüm 21 → 22: vasiyette mirasçı çocuk seçimi eklendi (D-052).
  ///
  /// Eski kayıtlarda seçim yoktur; `null` kalır ve miras eskisi gibi
  /// çocuklar arasında eşit bölünür. Hiçbir kişi veya miras kaydı
  /// değişmez.
  static Map<String, Object?> _v21ToV22(Map<String, Object?> body) => body;

  /// Sürüm 20 → 21: bekleyen bildirim kuyruğu eklendi (D-050).
  ///
  /// Eski kayıtlarda bildirim yoktur; kuyruk boş açılır. Geçmişte
  /// yaşanmış ölümler için **geriye dönük bildirim üretilmez**: o olaylar
  /// zaten hayat günlüğünde durur.
  static Map<String, Object?> _v20ToV21(Map<String, Object?> body) => body;

  /// Sürüm 19 → 20: evlenme teklifi kaydı eklendi (D-048).
  ///
  /// Eski kayıtlarda teklif geçmişi yoktur; boş harita ile açılır. Hiçbir
  /// evlilik kaydı değişmez, kimse silinmez.
  static Map<String, Object?> _v19ToV20(Map<String, Object?> body) => body;

  /// Sürüm 18 → 19: kişilere kendi hayat kaydı eklendi (D-045).
  ///
  /// Eski kayıtlardaki çocuklarda gelişim kaydı yoktur ve **geçmiş
  /// uydurulmaz**: kayıt ilk yaş ilerlemesinde yaşına uygun biçimde açılır,
  /// dönüm noktası listesi boş başlar, birikim sıfırdır. Eski kayıttaki
  /// serbest metin meslek katalogdaki bir işe karşılık geliyorsa bağlanır;
  /// gelmiyorsa iş kaydı açılmaz. Hiçbir kişi silinmez.
  static Map<String, Object?> _v18ToV19(Map<String, Object?> body) => body;

  /// Sürüm 17 → 18: kuşak sayacı eklendi (Paket E3).
  ///
  /// Eski kayıtlar tek kuşaklık hayatlardır: alan yoksa **1. kuşak** kabul
  /// edilir. Arşivdeki geçmiş hayatlarda da kuşak bilgisi yoktur; `null`
  /// kalır ve ekranda hiç gösterilmez. Hiçbir kayıt silinmez, hiçbir alan
  /// yeniden yazılmaz.
  static Map<String, Object?> _v17ToV18(Map<String, Object?> body) => body;

  /// Sürüm 16 → 17: kişilere şehir, işe şehir bağı eklendi.
  ///
  /// Eski kayıtta kişilerin şehri ve işin şehri bilinmez; ikisi de `null`
  /// kalır. Şehir koşulu `null` değerlerde **hiç uygulanmaz**: kimse
  /// listelerden düşmez, hiçbir kayıt silinmez ve okul kimlikleri olduğu
  /// gibi çalışmaya devam eder.
  static Map<String, Object?> _v16ToV17(Map<String, Object?> body) => body;

  /// Sürüm 15 → 16: geçmiş hayat özetine aile satırı eklendi.
  ///
  /// Eski arşiv kayıtlarında bu satır yoktur; `null` kalır ve ekranda hiç
  /// gösterilmez. **Hiçbir arşiv kaydı silinmez veya değiştirilmez.**
  static Map<String, Object?> _v15ToV16(Map<String, Object?> body) => body;

  /// Sürüm 14 → 15: evlilik ve çocuklar eklendi.
  ///
  /// Eski kayıtta evlilik kaydı yoktur: hayat bekâr olarak sürer, sevgili
  /// ve bütün kişiler **aynı kimlikle** korunur, çocuk üretilmez. Miras,
  /// gider ve hane hesapları olduğu gibi çalışmaya devam eder.
  static Map<String, Object?> _v14ToV15(Map<String, Object?> body) {
    // Evlilik kaydı yeni bir alandır; eski kayıtta bulunmaz ve okurken
    // `null` kabul edilir. Taşınacak veri yoktur, hiçbir alan silinmez.
    return body;
  }

  /// Sürüm 13 → 14: sağlık krizleri (hastalık ve kaza) eklendi.
  ///
  /// Eski kayıtta bekleyen kriz yoktur, kriz geçmişi boştur ve düşük
  /// sağlık uyarısı verilmemiş sayılır. Hayat olduğu gibi sürer.
  static Map<String, Object?> _v13ToV14(Map<String, Object?> body) {
    body['healthWarned'] ??= false;
    return body;
  }

  /// Sürüm 12 → 13: taşınma, kiraya verme ve yaşanan şehir eklendi.
  ///
  /// Eski kayıtta oyuncu **ailesinin yanında** sayılır, hiçbir konut
  /// kiraya verilmiş değildir ve yaşanan şehir doğum şehridir. Mülkler,
  /// cüzdan ve hayat olduğu gibi korunur.
  static Map<String, Object?> _v12ToV13(Map<String, Object?> body) {
    body['movedOut'] ??= false;
    return body;
  }

  /// Sürüm 11 → 12: geçmiş hayat arşivi, bakım durumu, yas, geçim sıkıntısı,
  /// oyuncu ayarları ve üç soruluk ehliyet sınavı eklendi.
  ///
  /// Eski kayıtlarda arşiv boştur ve **hiçbir hayat silinmez**. Bakım
  /// durumu "ailesinin yanında", yas ve geçim sıkıntısı sıfır, kumarhane
  /// açık kabul edilir. Sürüm 11'de kalmış **tek soruluk** bir ehliyet
  /// sınavı varsa, ücreti ikinci kez alınmasın diye sınav kapatılır;
  /// oyuncu aynı yıl yeniden başvurabilir.
  static Map<String, Object?> _v11ToV12(Map<String, Object?> body) {
    body['pastLives'] ??= <Object?>[];
    body['grief'] ??= 0;
    body['hardshipYears'] ??= 0;

    final Object? sinav = body['pendingLicenseExam'];
    if (sinav is Map<String, Object?> && sinav['questionIds'] == null) {
      body['pendingLicenseExam'] = null;
    }
    return body;
  }

  /// Sürüm 10 → 11: ölüm, miras ve kişilerin mal varlığı eklendi.
  ///
  /// Eski kayıtta kimse vefat etmiş olarak açılmaz: `deceased` alanı yoksa
  /// hayat sürüyor sayılır, kişilerin `isAlive` değeri olduğu gibi korunur,
  /// mal varlığı listesi boş başlar ve dağıtılmış miras kaydı boştur.
  static Map<String, Object?> _v10ToV11(Map<String, Object?> body) {
    body['settledEstates'] ??= <Object?>[];
    body['deceased'] ??= false;
    return body;
  }

  /// Sürüm 9 → 10: cevap bekleyen ehliyet sınavı eklendi.
  ///
  /// Eski kayıtlarda açık sınav yoktur; alan boş kalır. Sahip olunan
  /// ehliyetler sürüm 9'dan beri korunur.
  static Map<String, Object?> _v9ToV10(Map<String, Object?> body) => body;

  /// Sürüm 8 → 9: eşyalara satın alma fiyatı ve konum, oyuncuya ehliyet
  /// listesi eklendi.
  ///
  /// Eski kayıtlarda bu alanlar yoktur: satın alma fiyatı ve konum boş
  /// kalır (eşyanın değeri katalogdan hesaplanmaya devam eder), ehliyet
  /// listesi boş açılır. **Hiçbir eşya silinmez.**
  static Map<String, Object?> _v8ToV9(Map<String, Object?> body) {
    body['licenses'] ??= <Object?>[];
    return body;
  }

  /// Sürüm 7 → 8: kumarhane masası ve yıllık bahis toplamı eklendi.
  ///
  /// Eski kayıtlarda açık bir el yoktur; masa boş, yıllık bahis toplamı 0
  /// olarak açılır. Oyuncunun cüzdanı, eşyaları ve hayatı korunur.
  static Map<String, Object?> _v7ToV8(Map<String, Object?> body) {
    body['wagerThisAge'] ??= 0;
    // `blackjack` alanı boş bırakılır; okuyucu `null` durumunu ele alır.
    return body;
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

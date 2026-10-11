import '../models/game_state.dart';

/// Dövüş sanatı derslerinin yıllık sayacı — **tek kanonik anahtar**.
///
/// Paket AN, §1. Bu dosya var olduğu için var: anahtar iki motorda elle
/// iki kez yazılmıştı ve sıraları ters düşmüştü.
///
/// `GameState.interactionKey(a, b)` iki parçayı **sırayla** birleştirir
/// (`'$a|$b'`), yani `'dovus|karate'` ile `'karate|dovus'` farklı iki
/// anahtardır. Paket AL'den Paket AM'e kadar:
///
/// * `MartialArtsEngine` ders sayacını `interactionKey('dovus', artId)`
///   olarak **yazıyordu**,
/// * `CombatCareerEngine.advanceYear` ise `interactionCount(artId, 'dovus')`
///   diye **okuyordu**.
///
/// Sonuç: `dersler` her yıl 0 dönüyordu ve "çalışan sporcu formunu daha
/// iyi korur" kuralı hiç işlemiyordu. Hata Paket AL/2'de bulundu, Q-184
/// #1'de raporlandı ve Paket AN'de düzeltildi.
///
/// Kural: bu sayaca dokunan hiçbir yer anahtarı elle kurmaz. Yazan da
/// okuyan da [key] kullanır. Aynı string'i iki yerde tekrar yazmak
/// hatanın kendisiydi.
abstract final class MartialLessonCounter {
  /// Sayacın tür adı. `interactionCounts` içinde **ilk** parça.
  static const String kind = 'dovus';

  /// Bu sanatın bu yıla ait ders sayacının anahtarı.
  ///
  /// Hem yazan (`MartialArtsEngine.takeLesson`) hem okuyan
  /// (`CombatCareerEngine.advanceYear`) taraf **bunu** kullanır.
  static String key(String artId) => GameState.interactionKey(kind, artId);

  /// Bu yıl bu sanattan alınan ders sayısı.
  ///
  /// Eski kayıt uyumu (§2): hatalı olan **okuma** tarafıydı, yazma tarafı
  /// baştan beri [key] biçimini yazıyordu. Dolayısıyla Paket AN öncesi
  /// kayıtlardaki sayaçlar da `'dovus|karate'` biçimindedir ve bu okuma
  /// onları olduğu gibi görür — migrate etmeye gerek yok, çünkü taşınacak
  /// farklı bir biçim hiç oluşmadı.
  ///
  /// Ters sıralı (`'karate|dovus'`) anahtar için bilinçli olarak fallback
  /// **konmadı**: o anahtarı hiçbir kod yolu hiç yazmadı. Yazılmamış bir
  /// biçim için fallback koymak, aynı dersin iki anahtardan iki kez
  /// sayılması riskini bedavaya alırdı (§2: "aynı ders iki kez
  /// sayılmasın").
  static int read(GameState state, String artId) =>
      state.interactionCounts[key(artId)] ?? 0;
}

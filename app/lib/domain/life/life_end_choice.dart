/// Oyuncunun hayatını kendi isteğiyle sonlandırması (D-084).
///
/// **Neden var:** Faho istedi — "en alttaki vasiyet kısmının adını başka
/// bir şey yap, oraya intihar etmeyi de ekleyelim; hayatına dilerse son
/// verip kızının veya oğlunun hayatından devam edebilir".
///
/// **Nasıl ele alındığı — bilerek verilmiş kararlar:**
/// - **Yöntem anlatılmaz.** Ne seçenekte, ne onay ekranında, ne sonuç
///   metninde herhangi bir yöntem, araç ya da ayrıntı geçmez. Metin kısa
///   ve sakindir.
/// - **Özendirilmez.** Seçim hiçbir ödül, puan, başarım ya da avantaj
///   vermez; hayat sonu değerlendirmesinde bir üstünlük sayılmaz.
/// - **Kaza eseri seçilemez.** Ayrı bir onay ister ve onay ekranında
///   gerçek yardım hatları yazar.
/// - **Gerçek destek bilgisi verilir.** Türkiye'de acil durumda **112**,
///   psikososyal destek için Aile ve Sosyal Hizmetler Bakanlığı'nın
///   ücretsiz ve 7/24 hizmet veren **ALO 183** hattı.
/// - Kayıt normal ölüm yolundan tamamlanır (D-044): hayat özeti, Geçmiş
///   Hayatlar arşivi ve miras olağan kurallarıyla işler.
library;

/// Onay ekranında gösterilen gerçek destek bilgisi.
///
/// Numaralar resmîdir ve oyun içi kurgu değildir.
const String kLifeEndSupportText =
    'Bu bir oyun. Gerçek hayatta zorlandığını hissediyorsan yalnız '
    'değilsin: acil durumda 112, psikososyal destek için Aile ve '
    'Sosyal Hizmetler Bakanlığı\'nın ücretsiz ve 7/24 hizmet veren '
    'ALO 183 hattı aranabilir.';

/// Onay ekranında gösterilen kısa açıklama.
const String kLifeEndConfirmText =
    'Karakterinin hayatı burada biter. Bu geri alınamaz. Hayatta bir '
    'çocuğun varsa onun hayatından devam edebilirsin.';

/// Hayat günlüğüne ve ölüm kaydına yazılan ifade.
///
/// Kısa ve yöntemsizdir; ayrıntı içermez.
const String kLifeEndCause = 'kendi kararıyla';

abstract final class LifeEndChoice {
  /// Bu seçenek şu an açık mı? Engel yoksa `null`.
  ///
  /// Yetişkin olmayan karakterde **hiç gösterilmez**.
  static String? blockReason({required int age, required bool deceased}) {
    if (deceased) return 'Bu hayat zaten tamamlandı.';
    if (age < prototypeOnlyMinAge) {
      return 'Bu seçenek yalnızca yetişkin karakterlerde bulunur.';
    }
    return null;
  }

  /// Seçeneğin göründüğü en küçük yaş.
  static const int prototypeOnlyMinAge = 18;

  /// Hayat günlüğüne yazılan satır.
  static String logLine(int age) =>
      '$age yaşında hayatına kendi kararıyla son verdi.';
}

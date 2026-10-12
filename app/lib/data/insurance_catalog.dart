/// Sigorta kataloğu (Paket CA).
///
/// **Neden bu paket.** Para bu oyunda neredeyse tamamen **saldırı**
/// aracıydı: ev al, araba al, işletme kur, portföy büyüt. Oysa gerçek
/// hayatta paranın bir kısmı **savunmaya** gider ve o savunma bir karar:
/// her yıl prim ödeyip hiçbir şey olmamasını mı istersin, yoksa parayı
/// cebinde tutup riski mi üstlenirsin?
///
/// Oyun bu fikri zaten konuşuyordu: `ev_sigorta_teklifi` olayı 9.000 ₺
/// yıllık poliçe teklif ediyor ve `ev_sigorta_ise_yaradi` olayında
/// "cebinden sadece muafiyet tutarı çıktı" diyor. Bu paket o iki olayın
/// tek seferlik anlatısını **sürekli bir sisteme** çeviriyor ve
/// sayılarını aynen koruyor (konut primi 9.000, muafiyet 4.000).
///
/// **Bütün sayılar `prototypeOnly`.** `DECISIONS.md`'ye yazılmadı; soru
/// ve geri alma yolu `docs/DESIGN_REVIEW_QUEUE.md` Q-220'de. Modül
/// anahtarı: `sigorta`.
library;

/// Sigorta türü.
enum InsuranceKind {
  saglik('Sağlık sigortası', 'Tedavi ve ameliyat masrafları'),
  konut('Konut sigortası', 'Su basması, tesisat, çatı hasarı');

  const InsuranceKind(this.label, this.blurb);

  final String label;
  final String blurb;
}

/// Bir sigorta türünün koşulları.
///
/// Oran ve tutarların hepsi `prototypeOnly`. Çıpa: 2026 net yıllık
/// asgari ücret 336.906 ₺ (`lib/data/economy.dart`).
class InsuranceTerms {
  const InsuranceTerms({
    required this.kind,
    required this.prototypeOnlyYearlyPremium,
    required this.prototypeOnlyDeductible,
    required this.prototypeOnlyCoveredShare,
    required this.prototypeOnlyMinAge,
    required this.requiresOwnedResidence,
    required this.requiresVehicle,
  });

  final InsuranceKind kind;

  /// Yıllık prim. Oturulan hayatta her yıl cüzdandan çıkar.
  final int prototypeOnlyYearlyPremium;

  /// Muafiyet: hasarın bu kadarı **her zaman** oyuncunun cebinden çıkar.
  final int prototypeOnlyDeductible;

  /// Muafiyetin üstünde kalan kısmın karşılanan payı (0-1).
  final double prototypeOnlyCoveredShare;

  /// Poliçe alınabilecek en küçük yaş.
  final int prototypeOnlyMinAge;

  /// Poliçe oturulan **kendi** evini gerektiriyor mu?
  final bool requiresOwnedResidence;

  /// Poliçe aracı gerektiriyor mu?
  final bool requiresVehicle;
}

/// Katalog. Primler yıllık asgari ücretin yüzde 2,7-5,3'ü bandında:
/// hissedilir ama hayatı kilitlemez.
///
/// **Kasko (araç) bilerek yok.** Oyunda kaza aracın **kondisyonunu**
/// düşürüyor ve onarım "bakım" kalemiyle ödeniyor; yani kaza onarımı ile
/// rutin bakım aynı yerden geçiyor. Kaskoyu o kaleme bağlamak rutin
/// bakımı da sigortalı yapardı — poliçenin anlamını bozar. Doğru
/// bağlanacağı yer bir tasarım sorusu olarak Q-220'de duruyor; hollow
/// bir poliçe satmamak için v1'de yazılmadı.
const List<InsuranceTerms> kInsuranceCatalog = <InsuranceTerms>[
  InsuranceTerms(
    kind: InsuranceKind.saglik,
    // **Ölçümle kalibre edildi (Paket CA).** İlk yazımda yıllık 18.000
    // ₺ idi ve 200 hayatlık ölçüm poliçenin **hiçbir hayatta** kâra
    // geçmediğini gösterdi: ömür boyu ödenen prim medyanı 1.044.000 ₺,
    // karşılanan medyanı 45.600 ₺. Oyunun sigortalanabilir zararları
    // (kriz tedavisi 22.000-85.000 ₺, ev hasarı 19.000-72.000 ₺) seyrek
    // ve küçük; 50 yıllık prim onların on katını aşıyordu. Yani karar
    // değil tuzaktı.
    //
    // Yeni çıpa **ölçülen hasar dağılımı**: toplam karşılanan p75
    // 109.600 ₺, p90 175.200 ₺. Yirmi yıl tutulan poliçenin primi p75
    // hasara denk gelsin diye yıllık 5.000 ₺ seçildi. Ömür boyu tutan
    // oyuncu yine eksidedir — gerçek sigortada da öyledir — ama şanssız
    // hayat artık kazanıyor. Sayı `prototypeOnly`; yaşa göre artan prim
    // önerisi Q-220'de.
    prototypeOnlyYearlyPremium: 5000,
    prototypeOnlyDeductible: 3000,
    prototypeOnlyCoveredShare: 0.80,
    prototypeOnlyMinAge: 18,
    requiresOwnedResidence: false,
    requiresVehicle: false,
  ),
  InsuranceTerms(
    kind: InsuranceKind.konut,
    // `ev_sigorta_teklifi` olayı yıllık 9.000 ₺ diyor; o olay **tek
    // seferlik** bir poliçeydi, buradaki ise ömür boyu yenilenen bir
    // kalem. Aynı ölçüm sebebiyle (yukarıdaki not) yıllık 2.500 ₺'ye
    // indirildi: yirmi yılda 50.000 ₺, yani bir çatı hasarının
    // karşılığı kadar. Muafiyet 4.000 ₺ olayla aynı kaldı.
    prototypeOnlyYearlyPremium: 2500,
    prototypeOnlyDeductible: 4000,
    prototypeOnlyCoveredShare: 0.85,
    prototypeOnlyMinAge: 18,
    requiresOwnedResidence: true,
    requiresVehicle: false,
  ),
];

/// Türün koşulları.
InsuranceTerms insuranceTermsOf(InsuranceKind kind) =>
    kInsuranceCatalog.firstWhere((InsuranceTerms t) => t.kind == kind);

/// Kayıt anahtarından tür; tanınmazsa `null`.
InsuranceKind? insuranceKindByKey(String key) {
  for (final InsuranceKind k in InsuranceKind.values) {
    if (k.name == key) return k;
  }
  return null;
}

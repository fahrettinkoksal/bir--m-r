import 'package:flutter/foundation.dart';

/// Oyundaki bankalar (D-080).
///
/// İkisi de **kurgusaldır**; gerçek bir bankanın adı, markası ya da
/// koşulları kullanılmaz. Faho'nun istediği ayrım: biri daha ucuz ama
/// zor onaylar, diğeri daha pahalı ama kolay onaylar.
///
/// Oranlar 2026 Türkiye ihtiyaç kredisi piyasasına dayanır: aylık faiz
/// çoğu bankada **%2,89 – %5,50** aralığında seyrediyor. Fakbank bu
/// bandın alt ucunda, Bankavrupa üst ucuna yakın durur.
enum Bank {
  fakbank(
    'Fakbank',
    'Faizi düşük tutar, ama herkese kredi vermez.',
    monthlyRate: 0.0295,
    housingMonthlyRate: 0.0245,
    approvalEase: 0.55,
  ),
  bankavrupa(
    'Bankavrupa',
    'Faizi yüksek, buna karşılık kapısı daha açık.',
    monthlyRate: 0.046,
    housingMonthlyRate: 0.0340,
    approvalEase: 1.0,
  );

  const Bank(
    this.label,
    this.description, {
    required this.monthlyRate,
    required this.housingMonthlyRate,
    required this.approvalEase,
  });

  final String label;
  final String description;

  /// prototypeOnly: ihtiyaç kredisinin aylık faiz oranı.
  final double monthlyRate;

  /// prototypeOnly: konut kredisinin aylık faiz oranı (D-108).
  ///
  /// Konut kredisi ihtiyaç kredisinden **ucuzdur**, çünkü ev teminattır.
  /// 2026 Türkiye'sinde konut kredisi aylık faizi kabaca **%2,2 – %3,5**
  /// bandında seyrediyor; iki banka bu bandın iki ucunda durur.
  final double housingMonthlyRate;

  /// Verilen amaca göre aylık faiz.
  double monthlyRateFor(LoanPurpose purpose) =>
      purpose == LoanPurpose.konut ? housingMonthlyRate : monthlyRate;

  /// Verilen amaca göre yıllık bileşik faiz.
  double yearlyRateFor(LoanPurpose purpose) {
    double carpan = 1.0;
    final double aylik = monthlyRateFor(purpose);
    for (int i = 0; i < 12; i++) {
      carpan *= 1 + aylik;
    }
    return carpan - 1;
  }

  /// prototypeOnly: onay kolaylığı çarpanı (1.0 = en kolay).
  final double approvalEase;

  /// Yıllık bileşik faiz oranı.
  ///
  /// Oyun yıl yıl ilerlediği için aylık oran yıllığa çevrilir; taksitler
  /// yıllık hesaplanır.
  double get yearlyRate {
    double carpan = 1.0;
    for (int i = 0; i < 12; i++) {
      carpan *= 1 + monthlyRate;
    }
    return carpan - 1;
  }
}

/// Kredinin amacı (D-108).
///
/// Faho'nun isteği: "konut kredisi de olsun". Konut kredisi ihtiyaç
/// kredisinden **daha ucuz, daha uzun vadeli ve daha büyük**tür; çünkü
/// ev teminattır. Yeni değerler listenin **sonuna** eklenir.
enum LoanPurpose {
  ihtiyac('İhtiyaç kredisi', 'Serbest kullanım; kısa vadeli ve pahalı.'),
  konut('Konut kredisi', 'Ev almak için; uzun vadeli ve daha ucuz.');

  const LoanPurpose(this.label, this.description);

  final String label;
  final String description;
}

/// Çekilmiş bir kredi (D-080).
@immutable
class Loan {
  const Loan({
    required this.id,
    required this.bank,
    required this.principal,
    required this.annualPayment,
    required this.termYears,
    required this.remainingPayments,
    required this.outstanding,
    required this.takenAtAge,
    this.purpose = LoanPurpose.ihtiyac,
    this.missedPayments = 0,
    this.originalDebt,
    this.missedStreak = 0,
    this.restructures = 0,
    this.writtenOff = false,
    this.closedAtAge,
  });

  final String id;
  final Bank bank;

  /// Çekilen anapara (₺).
  final int principal;

  /// Yıllık taksit (₺). Kredi çekilirken hesaplanır ve **değişmez**.
  final int annualPayment;

  /// Toplam vade (yıl).
  final int termYears;

  /// Kalan taksit sayısı.
  final int remainingPayments;

  /// Kalan borç (₺). Erken kapatmak için bu tutar ödenir.
  final int outstanding;

  final int takenAtAge;

  /// Kredinin amacı (D-108). Eski kayıtlarda ihtiyaç kredisi sayılır.
  final LoanPurpose purpose;

  /// Ödenemeyen taksit sayısı — **ömür boyu** kayıt.
  ///
  /// Kredi notu bu sayıdan okunur. Kapanan kredide de durmaya devam eder,
  /// ama etkisi zamanla siliniyor: bkz. `Banking.missedPayments`.
  final int missedPayments;

  /// Kredi çekildiğinde borçlanılan toplam tutar (₺).
  ///
  /// Gecikme faizinin tavanı buna göre hesaplanıyor (§10). `principal`
  /// **yetmez**: `outstanding` daha başlangıçta anapara değil, vade
  /// boyunca ödenecek toplamdır (₺300.000 anapara, üç yıl vade, kolay
  /// onaylayan banka -> ₺802.974). Tavanı anaparaya bağlamak, borcu
  /// **kendi başlangıç bakiyesinin altına** kırpıyordu ve mevcut bir test
  /// haklı olarak kırıldı. Eski kayıtta yok; o zaman `outstanding` okunur.
  final int? originalDebt;

  /// Gecikme faizinin şişirebileceği tavanın dayandığı tutar.
  int get debtBase => originalDebt ?? outstanding;

  /// **Üst üste** kaçan taksit sayısı (Paket AD, §8).
  ///
  /// `missedPayments`'tan ayrı tutuluyor, çünkü ikisi iki farklı soruya
  /// cevap veriyor: `missedPayments` "bu borçlu geçmişte ne yaptı"
  /// (kredi notu), `missedStreak` "şu an ne kadar kötü durumda"
  /// (yapılandırma ve tahsil eşiği). Ödeme yapılınca ya da
  /// yapılandırmadan sonra sıfırlanır; kredi notu izi ise silinmez.
  final int missedStreak;

  /// Kaç kez yapılandırıldı (Paket AD, §8).
  ///
  /// Sınırlı: sonsuz yapılandırma "hiç ödemem, her seferinde vade uzasın"
  /// exploitine dönerdi.
  final int restructures;

  /// Zarar yazılarak mı kapandı (Paket AD, §10)?
  ///
  /// Normal kapanıştan ayırt etmek için var: borç silinmiş olsa bile
  /// kredi notunda iz bırakır ve ekranda öyle yazılır.
  final bool writtenOff;

  /// Kapandığı yaş. Açık kredide `null`.
  ///
  /// Kredi notu izinin **eskimesi** buna bakıyor (§11: ömür boyu kredi
  /// yasağı olmasın).
  final int? closedAtAge;

  bool get isClosed => remainingPayments <= 0 || outstanding <= 0;

  /// Borcun yaşam döngüsündeki yeri (Paket AD, §8). Yalnızca metin/eşik
  /// için; hesaba girmez.
  LoanStage get stage {
    if (isClosed) {
      return writtenOff ? LoanStage.zararYazildi : LoanStage.kapandi;
    }
    if (missedStreak <= 0) return LoanStage.normal;
    if (missedStreak == 1) return LoanStage.gecikme;
    return LoanStage.ciddiGecikme;
  }

  /// Vade boyunca ödenecek toplam tutar.
  int get totalRepayment => annualPayment * termYears;

  Loan copyWith({
    int? annualPayment,
    int? termYears,
    int? remainingPayments,
    int? outstanding,
    int? missedPayments,
    int? originalDebt,
    int? missedStreak,
    int? restructures,
    bool? writtenOff,
    int? closedAtAge,
  }) =>
      Loan(
        id: id,
        bank: bank,
        principal: principal,
        annualPayment: annualPayment ?? this.annualPayment,
        termYears: termYears ?? this.termYears,
        remainingPayments: remainingPayments ?? this.remainingPayments,
        outstanding: outstanding ?? this.outstanding,
        takenAtAge: takenAtAge,
        purpose: purpose,
        missedPayments: missedPayments ?? this.missedPayments,
        originalDebt: originalDebt ?? this.originalDebt,
        missedStreak: missedStreak ?? this.missedStreak,
        restructures: restructures ?? this.restructures,
        writtenOff: writtenOff ?? this.writtenOff,
        closedAtAge: closedAtAge ?? this.closedAtAge,
      );
}

/// Borcun yaşam döngüsündeki durağı (Paket AD, §8).
///
/// Gerçek bir hukuk süreci taklit edilmiyor; oyunlaştırılmış dört durak.
enum LoanStage {
  normal('Ödemeler düzenli'),
  gecikme('Ödeme aksadı'),
  ciddiGecikme('Ödemeler bir süredir aksıyor'),
  kapandi('Kapandı'),
  zararYazildi('Takibe düştü ve kapatıldı');

  const LoanStage(this.label);

  final String label;
}

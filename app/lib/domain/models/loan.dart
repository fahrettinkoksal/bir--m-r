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

  /// Ödenemeyen taksit sayısı.
  final int missedPayments;

  bool get isClosed => remainingPayments <= 0 || outstanding <= 0;

  /// Vade boyunca ödenecek toplam tutar.
  int get totalRepayment => annualPayment * termYears;

  Loan copyWith({
    int? annualPayment,
    int? remainingPayments,
    int? outstanding,
    int? missedPayments,
  }) =>
      Loan(
        id: id,
        bank: bank,
        principal: principal,
        annualPayment: annualPayment ?? this.annualPayment,
        termYears: termYears,
        remainingPayments: remainingPayments ?? this.remainingPayments,
        outstanding: outstanding ?? this.outstanding,
        takenAtAge: takenAtAge,
        purpose: purpose,
        missedPayments: missedPayments ?? this.missedPayments,
      );
}

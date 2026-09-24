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
    approvalEase: 0.55,
  ),
  bankavrupa(
    'Bankavrupa',
    'Faizi yüksek, buna karşılık kapısı daha açık.',
    monthlyRate: 0.046,
    approvalEase: 1.0,
  );

  const Bank(
    this.label,
    this.description, {
    required this.monthlyRate,
    required this.approvalEase,
  });

  final String label;
  final String description;

  /// prototypeOnly: aylık faiz oranı.
  final double monthlyRate;

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
        missedPayments: missedPayments ?? this.missedPayments,
      );
}

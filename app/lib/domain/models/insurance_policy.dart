import 'package:flutter/foundation.dart';

import '../../data/insurance_catalog.dart';

/// Yürürlükteki bir sigorta poliçesi (Paket CA).
///
/// Poliçe **kayıt**tır: primi ne zaman ödemeye başladığın, bugüne kadar
/// ne kadar prim ödediğin ve sigortanın sana ne kadar ödediği durur.
/// Böylece ekranda "bu poliçe kâra mı geçti" sorusu uydurmadan
/// yanıtlanabilir.
@immutable
class InsurancePolicy {
  const InsurancePolicy({
    required this.kind,
    required this.startedAtAge,
    this.premiumsPaid = 0,
    this.claimsPaid = 0,
    this.claimCount = 0,
    this.lapsedAtAge,
  });

  final InsuranceKind kind;

  /// Poliçenin başladığı yaş.
  final int startedAtAge;

  /// Bugüne kadar ödenen toplam prim.
  final int premiumsPaid;

  /// Sigortanın bugüne kadar **karşıladığı** toplam tutar.
  final int claimsPaid;

  /// Kaç hasarda devreye girdi.
  final int claimCount;

  /// Poliçe düştüyse (ev satıldı, araç gitti, prim ödenemedi) o yaş.
  /// `null` ise poliçe **yürürlükte**.
  final int? lapsedAtAge;

  bool get isActive => lapsedAtAge == null;

  /// Koşulları (prim, muafiyet, karşılama payı).
  InsuranceTerms get terms => insuranceTermsOf(kind);

  InsurancePolicy copyWith({
    int? startedAtAge,
    int? premiumsPaid,
    int? claimsPaid,
    int? claimCount,
    int? lapsedAtAge,
    bool clearLapsed = false,
  }) =>
      InsurancePolicy(
        kind: kind,
        startedAtAge: startedAtAge ?? this.startedAtAge,
        premiumsPaid: premiumsPaid ?? this.premiumsPaid,
        claimsPaid: claimsPaid ?? this.claimsPaid,
        claimCount: claimCount ?? this.claimCount,
        lapsedAtAge: clearLapsed ? null : (lapsedAtAge ?? this.lapsedAtAge),
      );
}

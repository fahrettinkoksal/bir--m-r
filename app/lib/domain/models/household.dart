/// Hane bütçesi, nafaka ve velayet kayıtları (D-160).
///
/// **Bu kayıtlar Q-118'in "şimdilik yazılmasın" kararını değiştirir.**
/// Faho'nun açık isteğiyle eklendi; onay bekleyen ayrıntılar Q-163'te.
library;

import 'package:flutter/foundation.dart';

/// Boşanmadan sonra çocuklar kimde kaldı?
enum Custody {
  /// Çocuklar oyuncunun hanesinde.
  oyuncuda('Sende'),

  /// Çocuklar eski eşin hanesinde.
  eskiEste('Eski eşinde'),

  /// Paylaşılan düzen: çocuklar iki hanede de vakit geçirir.
  ortak('Ortak');

  const Custody(this.label);

  final String label;
}

/// Süren nafaka kaydı.
///
/// Oyun bir hukuk simülasyonu **değildir**: yoksulluk nafakası ile
/// iştirak nafakası ayrı ayrı modellenmez, tek bir yıllık tutar tutulur.
/// Tutar boşanma anında hesaplanır ve **değişmez**; gerçekte gelire göre
/// artırım/indirim davası açılabilir, oyunda yoktur (Q-163).
///
/// Kayıt silinmez: süresi dolan nafaka listede kalır, [endedAtAge] dolar.
@immutable
class Alimony {
  const Alimony({
    required this.otherPersonId,
    required this.yearlyAmount,
    required this.startedAtAge,
    required this.untilAge,
    required this.playerPays,
    this.custody = Custody.oyuncuda,
    this.endedAtAge,
    this.paidYears = 0,
  });

  /// Eski eşin kalıcı kimliği.
  final String otherPersonId;

  /// prototypeOnly: yıllık tutar (₺). Boşanmada bir kez hesaplanır.
  final int yearlyAmount;

  final int startedAtAge;

  /// Oyuncunun kaç yaşına kadar süreceği (en küçük çocuğun 18'i).
  final int untilAge;

  /// Oyuncu **ödeyen** taraf mı? Değilse alan taraftır.
  final bool playerPays;

  /// Boşanmada verilen velayet düzeni.
  final Custody custody;

  /// Kaydın kapandığı yaş; sürüyorsa `null`.
  final int? endedAtAge;

  /// Gerçekten ödenen/alınan yıl sayısı.
  final int paidYears;

  bool get isActive => endedAtAge == null;

  /// [age] yaşında hâlâ işliyor mu?
  bool runsAt(int age) => isActive && age < untilAge;

  Alimony copyWith({
    int? endedAtAge,
    int? paidYears,
  }) =>
      Alimony(
        otherPersonId: otherPersonId,
        yearlyAmount: yearlyAmount,
        startedAtAge: startedAtAge,
        untilAge: untilAge,
        playerPays: playerPays,
        custody: custody,
        endedAtAge: endedAtAge ?? this.endedAtAge,
        paidYears: paidYears ?? this.paidYears,
      );
}

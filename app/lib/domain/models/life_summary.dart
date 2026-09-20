import 'package:flutter/foundation.dart';

/// Tamamlanmış bir hayatın **arşivlenmiş** özeti.
///
/// Oyuncu öldüğünde üretilir ve yeni hayata geçilse bile kayıtta kalır
/// (D-037): "yeni hayat başlatma işlemi geçmiş hayat özetini habersizce
/// silmez". Tam hayat kaydı değil, okunabilir bir özettir.
@immutable
class LifeSummary {
  const LifeSummary({
    required this.fullName,
    required this.birthCity,
    required this.deathAge,
    required this.deathCause,
    required this.educationLabel,
    required this.careerLabel,
    required this.wallet,
    required this.itemCount,
    required this.licenseCount,
    required this.highlights,
    this.familyLine,
    this.generation,
  });

  final String fullName;
  final String birthCity;
  final int deathAge;
  final String deathCause;

  /// Eğitim durumu ve varsa bölüm.
  final String educationLabel;

  /// Son meslek veya çalışmadıysa açıklaması.
  final String careerLabel;

  final int wallet;
  final int itemCount;
  final int licenseCount;

  /// Hayat günlüğünden seçilmiş satırlar ("yaş: metin").
  final List<String> highlights;

  /// Evlilik ve çocuk özeti ("Eşi: Ayşe Demir · 2 çocuk").
  ///
  /// Hiç evlenmemiş ve çocuğu olmamış hayatlarda ve **eski arşiv
  /// kayıtlarında** `null` olur; o zaman ekranda hiç gösterilmez
  /// (uydurma bilgi yazılmaz).
  final String? familyLine;

  /// Bu hayatın kaçıncı kuşak olduğu (Paket E3).
  ///
  /// "Çocuğum olarak devam et" ile oynanan hayatlarda 2 ve üzeridir.
  /// **Eski arşiv kayıtlarında** `null` olur; o zaman ekranda kuşak satırı
  /// hiç gösterilmez (uydurma bilgi yazılmaz).
  final int? generation;
}

import 'package:flutter/foundation.dart';

/// Bildirim türü (D-050).
enum NoticeKind {
  /// Yakın birinin vefatı.
  olum,

  /// Oyuncuya gerçekten kalan miras.
  miras,

  /// Cenaze masrafına katkı seçimi.
  cenaze,

  /// Okul hayatının dönüm noktası: okula başlama, kademe değişimi,
  /// mezuniyet (Paket 17).
  okul,
}

/// Oyuncuya **açıkça gösterilmesi gereken** önemli bir haber (D-050).
///
/// Hayat günlüğüne sessizce satır eklemek her zaman yeterli değildir:
/// ölüm, miras ve cenaze gibi doğrudan oyuncuyu etkileyen olaylar ekranda
/// gösterilir. Bildirimler kayda girer; uygulama kapatılıp açılınca
/// kaybolmaz ve aynı bildirim iki kez açılmaz.
@immutable
class PendingNotice {
  const PendingNotice({
    required this.id,
    required this.kind,
    required this.age,
    required this.title,
    required this.text,
    this.personId,
    this.money = 0,
    this.itemNames = const <String>[],
    this.happinessDelta = 0,
    this.funeralCost = 0,
  });

  /// Bildirimin benzersiz kimliği (ör. `olum-anne-1`).
  ///
  /// Aynı kimlikli bildirim ikinci kez kuyruğa girmez.
  final String id;

  final NoticeKind kind;

  /// Bildirimin oluştuğu yaş.
  final int age;

  final String title;
  final String text;

  /// Bildirimin ilgili olduğu kişi.
  final String? personId;

  /// Mirasta oyuncuya **gerçekten** geçen nakit.
  final int money;

  /// Mirasta oyuncuya geçen eşyaların adları.
  final List<String> itemNames;

  /// Kaybın mutluluğa **gerçekten uygulanan** etkisi (negatif ya da 0).
  ///
  /// Mutluluk zaten 0 ise burada da 0 yazar; sahte "-puan" gösterilmez.
  final int happinessDelta;

  /// Cenaze bildiriminde önerilen katkı tutarı.
  final int funeralCost;
}

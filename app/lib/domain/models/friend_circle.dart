import 'package:flutter/foundation.dart';

/// Arkadaş grubu kaydı (Paket CI).
///
/// **Neden var.** `docs/EKSIKLER.md` §3.1'de arkadaşlığın eksikleri
/// sayılmıştı; D-130 bunların çoğunu kapattı (yakın arkadaş olma
/// teklifi, küslük, barışma, arkadaşın kendi hayatı) ve o bölümün
/// güncellemesinde kalan iki eksik yazıldı: **arkadaş grubu** ve
/// çocukluk arkadaşıyla yıllar sonra karşılaşma. İkincisi D-130'un
/// zincirlerinde kodlanmış durumda; grup ise kodda hiç yoktu.
///
/// **Grup yeni bir etkileşim motoru değildir.** Oyunda birden çok
/// kişiyle aktiviteye gitmek zaten var (Paket X/2, `Outing`): maliyet
/// kişi başına çarpılıyor ve her katılımcıyla bağ artıyor. Eksik olan
/// şey **kalıcı kimlik**ti — kimlerle takıldığın, ne zamandır, kim
/// ayrıldı. Bu kayıt onu tutar; buluşma yine aktivite yolundan geçer.
///
/// **Kayıt silinmez (D-029, D-038).** Grup dağılırsa kaydı kalır,
/// `dispersedAtAge` yazılır ve hayat günlüğünde gerekçesi durur.
@immutable
class FriendCircle {
  const FriendCircle({
    required this.name,
    required this.memberIds,
    required this.formedAtAge,
    this.lastMetAge,
    this.dispersedAtAge,
  });

  /// Grubun adı; oyun kendi koyar (üyelerin ağırlıklı bağından türer).
  final String name;

  /// Üyelerin **kalıcı kimlikleri**. Ad tutulmaz: kişi yeniden
  /// adlandırılabilir, taşınabilir, bağı değişebilir — grup aynı kişiyi
  /// göstermeye devam eder.
  final List<String> memberIds;

  final int formedAtAge;

  /// Son buluşma yaşı; hiç buluşulmadıysa `null`.
  final int? lastMetAge;

  /// Dağıldıysa dağıldığı yaş. `null` ise grup sürüyor.
  final int? dispersedAtAge;

  bool get isActive => dispersedAtAge == null;

  int get size => memberIds.length;

  FriendCircle copyWith({
    String? name,
    List<String>? memberIds,
    int? formedAtAge,
    int? lastMetAge,
    int? dispersedAtAge,
  }) =>
      FriendCircle(
        name: name ?? this.name,
        memberIds: memberIds == null
            ? this.memberIds
            : List<String>.unmodifiable(memberIds),
        formedAtAge: formedAtAge ?? this.formedAtAge,
        lastMetAge: lastMetAge ?? this.lastMetAge,
        dispersedAtAge: dispersedAtAge ?? this.dispersedAtAge,
      );
}

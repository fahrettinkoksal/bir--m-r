import 'package:flutter/foundation.dart';

/// Oyuncunun **kendi** yaşlılığında ailesinden gördüğü desteğin kaydı
/// (Paket CJ).
///
/// **Neden var.** Oyunda yaşlı ebeveyn bakımı vardı ([ElderCare], Paket
/// AO §35-§36): oyuncu annesine babasına bakıyor, parası ve yakınlığı
/// gerçekten değişiyor. Bunun **tersi** hiç yoktu. 250 bot hayatında
/// ölçüldü: oyuncu 70 yaşını 185 hayatta gördü, 1356 yaşlılık yılı
/// yaşandı, bu yılların 585'inde sağlık bandı düşüktü — ve o yılların
/// **hiçbirinde** hiçbir aile üyesi oyuncu için bir şey yapmadı.
/// Günlükte tek satır yoktu. Oyuncunun yaşlılığı, çocuğu olsa da
/// olmasa da birebir aynı geçiyordu.
///
/// **Ne tutar.** Yalnızca okunan şeyler: kaç yıl destek görüldü, kaç
/// yıl kendi başına idare edildi, bu yıl karar verildi mi (aynı yıl
/// iki kez karar vermeyi kapatır), en son kim yanında oldu ve aileden
/// toplam ne kadar maddi destek geldi. Hepsi ekrandaki kartta ya da
/// motorda okunur.
///
/// **Kayıt silinmez (D-029).** Destek alınan yıllar sayacı geri
/// gitmez; oyuncu sonradan yalnız kalsa bile geçmişi durur.
@immutable
class ElderSupportState {
  const ElderSupportState({
    this.yearsSupported = 0,
    this.yearsAlone = 0,
    this.lastDecidedAge,
    this.lastHelperId,
    this.receivedTotal = 0,
    this.paidTotal = 0,
  });

  /// Ailenin yanında olduğu yıl sayısı.
  final int yearsSupported;

  /// Oyuncunun kimseye yüklenmeden geçirdiği yıl sayısı.
  final int yearsAlone;

  /// Bu yıl karar verildi mi? (Aynı yıl ikinci karar alınmaz.)
  final int? lastDecidedAge;

  /// En son yanında olan kişinin **kalıcı kimliği**. Ad tutulmaz: kişi
  /// yeniden adlandırılabilir, bağı değişebilir.
  final String? lastHelperId;

  /// Çocukların bakım faturasından üstlendiği toplam (₺).
  ///
  /// Oyuncunun cebine giren para **değil**: faturanın onların üstlendiği
  /// payı. Para bu yüzden havadan üretilmez (ElderCare §36'nın kuralı).
  final int receivedTotal;

  /// Oyuncunun bakım için kendi cebinden ödediği toplam (₺).
  final int paidTotal;

  /// Hiç karar verilmemiş, bomboş kayıt mı? (Kodek eski kayıtlarda
  /// bunu yazmaz.)
  bool get isEmpty =>
      yearsSupported == 0 &&
      yearsAlone == 0 &&
      lastDecidedAge == null &&
      lastHelperId == null &&
      receivedTotal == 0 &&
      paidTotal == 0;

  ElderSupportState copyWith({
    int? yearsSupported,
    int? yearsAlone,
    int? lastDecidedAge,
    String? lastHelperId,
    int? receivedTotal,
    int? paidTotal,
  }) =>
      ElderSupportState(
        yearsSupported: yearsSupported ?? this.yearsSupported,
        yearsAlone: yearsAlone ?? this.yearsAlone,
        lastDecidedAge: lastDecidedAge ?? this.lastDecidedAge,
        lastHelperId: lastHelperId ?? this.lastHelperId,
        receivedTotal: receivedTotal ?? this.receivedTotal,
        paidTotal: paidTotal ?? this.paidTotal,
      );
}

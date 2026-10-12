/// Oyuncu dışındaki bir kişinin **kendi evlilik kaydı** (Paket AP, §14-§18).
///
/// **Neden gerekti.** Paket AO'ya kadar oyuncunun çocuğu evlendiğinde
/// `PersonDevelopment` içinde yalnızca bir `spouseName` tutuluyordu ve o
/// alanın yorumu açıkça şunu diyordu: *"Bu kişi ayrı bir kayıt olarak
/// tutulmaz; oyuncunun hayatına giren yalnızca adıdır."*
///
/// Paket AP ile bu yetersiz: gelin/damat oyuncunun hayatına **giren bir
/// insan** oldu. Onunla vakit geçirilebiliyor, torunun biyolojik
/// ebeveyni olabiliyor, boşanabiliyor, vefat edebiliyor ve kuşak
/// devamında **yeni oyuncunun eşi** olabiliyor (§62). Bir isim dizesi
/// bunların hiçbirini taşıyamaz.
///
/// **İkinci bir evlilik sistemi kurulmadı.** Oyuncunun kendi evliliği
/// hâlâ [Marriage] ile tutuluyor; bu dosya yalnızca NPC tarafını, en
/// küçük doğru modelle karşılıyor (§18). Ortak nokta: **kayıt silinmez**
/// — boşanma ya da vefat durumu değiştirir, geçmişi ortadan kaldırmaz.
library;

import 'package:flutter/foundation.dart';

/// Bir NPC evliliğinin durumu.
///
/// Oyuncunun kendi evliliğindeki [MarriageStatus] ile bilinçli olarak
/// aynı üç durumu taşır; ayrı bir sözlük öğrenmek gerekmesin.
enum NpcMarriageStatus {
  evli('Evli'),
  bosandi('Boşandı'),
  dul('Eşini kaybetti');

  const NpcMarriageStatus(this.label);

  final String label;
}

/// Bitmiş bir NPC evliliğinin kaydı.
///
/// §18: "geçmiş kaybolmasın". Çocuk ikinci kez evlendiğinde ilk evlilik
/// buraya taşınır; kiminle, kaç yaşında evlendiği ve nasıl bittiği
/// hayat boyu okunabilir kalır.
@immutable
class NpcMarriageRecord {
  const NpcMarriageRecord({
    required this.spouseName,
    required this.marriedAtAge,
    required this.status,
    this.spousePersonId,
    this.endedAtAge,
  });

  /// Eşin adı. Eski kayıtlarda elimizdeki **tek** bilgi bu olabilir
  /// (§17), o yüzden zorunlu alan.
  final String spouseName;

  /// Eşin kalıcı kişi kimliği.
  ///
  /// `null` olabilir: Paket AP öncesinde kurulmuş evliliklerde eş gerçek
  /// bir [Person] değildi. O kayıtlara **geriye dönük NPC uydurulmaz**
  /// (§17); isimle yaşamaya devam ederler.
  final String? spousePersonId;

  final int marriedAtAge;

  /// Evliliğin bittiği yaş; kayıt geçmişe taşınmışsa doludur.
  final int? endedAtAge;

  final NpcMarriageStatus status;
}

/// Tek bir satırda okunabilir özet; ekranda kullanılır.
String npcMarriageSummary(NpcMarriageRecord kayit) {
  final String son = switch (kayit.status) {
    NpcMarriageStatus.evli => 'sürüyor',
    NpcMarriageStatus.bosandi => 'boşandılar',
    NpcMarriageStatus.dul => 'eşini kaybetti',
  };
  return '${kayit.spouseName} · ${kayit.marriedAtAge} yaşında evlendi · '
      '$son';
}

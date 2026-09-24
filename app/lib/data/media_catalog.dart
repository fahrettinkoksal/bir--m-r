/// Ün ve medya fırsatları (D-103).
///
/// Faho'nun isteği: "Ün belli bir düzeye gelince oyuncuya medya
/// fırsatları açılsın." Ün, oyuncunun kitlesinden türeyen bir değerdir
/// (D-027); belli bir düzeye gelince hayatta karşılığı olmalıdır.
///
/// **Markalar kurgusaldır.** Gerçek bir dergi, kanal, program ya da
/// şirket adı kullanılmaz; bütün tutarlar oyun parasıdır ve gerçek para
/// ya da uygulama içi satın alma yoktur.
///
/// Ücretler 2026 ölçeğine (D-053) göre, `Economy` çıpalarıyla yazıldı.
/// Bütün sayılar `prototypeOnly`'dir (Q-125).
library;

import 'package:flutter/foundation.dart';

import 'economy.dart';

/// Ün ve Medya Fırsatları bölümünün açıldığı Ün eşiği.
///
/// Faho'nun kararı: bölüm **Ün 40** olmadan görünmez. Altındaki oyuncuya
/// çalışmayan bir kapı gösterilmez (D-038).
const int kMediaSectionMinFame = 40;

@immutable
class MediaOpportunity {
  const MediaOpportunity({
    required this.id,
    required this.label,
    required this.description,
    required this.minFame,
    required this.fee,
    required this.fameGain,
    this.followerRatio = 0,
    this.happiness = 0,
    this.charisma = 0,
    this.maxPerAge = 1,
  });

  final String id;
  final String label;
  final String description;

  /// prototypeOnly: teklifin gelmesi için gereken en az Ün.
  final int minFame;

  /// prototypeOnly: kabul edilince cüzdana giren tutar (₺, 2026).
  final int fee;

  /// prototypeOnly: işin getirdiği Ün.
  final int fameGain;

  /// prototypeOnly: mevcut kitlenin bu oranı kadar yeni takipçi.
  ///
  /// Sabit sayı yerine oran kullanılır: büyük hesabın kazancı da büyük
  /// olur, küçük hesaba uydurma bir kitle yazılmaz.
  final double followerRatio;

  final int happiness;
  final int charisma;

  /// prototypeOnly: aynı yaşta kaç kez yapılabilir.
  final int maxPerAge;
}

/// Kurgusal medya işleri; Ün eşiğine göre sıralı.
const List<MediaOpportunity> kMediaOpportunities = <MediaOpportunity>[
  MediaOpportunity(
    id: 'dergi_roportaji',
    label: 'Dergi röportajı',
    description:
        'Bir yaşam dergisi seninle uzun bir söyleşi yapmak istiyor. '
        'Fotoğraf çekimi de var.',
    minFame: kMediaSectionMinFame,
    // ~4 aylık asgari ücret.
    fee: Economy.netMonthlyMinimumWage * 4,
    fameGain: 2,
    followerRatio: 0.03,
    happiness: 3,
  ),
  MediaOpportunity(
    id: 'radyo_programi',
    label: 'Radyo programına konuk',
    description:
        'Sabah kuşağında bir saat. Soruları önceden görmüyorsun.',
    minFame: 45,
    fee: Economy.netMonthlyMinimumWage * 6,
    fameGain: 3,
    followerRatio: 0.04,
    charisma: 1,
  ),
  MediaOpportunity(
    id: 'podcast_konugu',
    label: 'Podcast konukluğu',
    description:
        'İki saatlik bir sohbet. Kesintisiz yayımlanıyor; söylediğin '
        'her şey kayıtta kalıyor.',
    minFame: 50,
    fee: Economy.netMonthlyMinimumWage * 8,
    fameGain: 3,
    followerRatio: 0.06,
    happiness: 2,
  ),
  MediaOpportunity(
    id: 'tv_programi',
    label: 'Televizyon programına konuk',
    description:
        'Akşam kuşağı. Stüdyo ışıkları, seyirci ve reklam arası.',
    minFame: 55,
    fee: Economy.netMonthlyMinimumWage * 16,
    fameGain: 5,
    followerRatio: 0.08,
    charisma: 1,
    happiness: 2,
  ),
  MediaOpportunity(
    id: 'belgesel_seslendirme',
    label: 'Belgesel seslendirme',
    description:
        'Doğa belgeseli için dış ses. Stüdyoda üç gün, tek başına.',
    minFame: 60,
    fee: Economy.netMonthlyMinimumWage * 20,
    fameGain: 3,
    followerRatio: 0.03,
    happiness: 3,
  ),
  MediaOpportunity(
    id: 'reklam_yuzu',
    label: 'Bir markanın reklam yüzü ol',
    description:
        'Bir yıl boyunca afişlerde ve ekranlarda sen varsın. '
        'Sözleşme uzun, para büyük.',
    minFame: 65,
    fee: Economy.netMonthlyMinimumWage * 45,
    fameGain: 6,
    followerRatio: 0.10,
    happiness: 2,
  ),
  MediaOpportunity(
    id: 'kitap_teklifi',
    label: 'Kitap teklifi',
    description:
        'Bir yayınevi hayat hikâyeni kitaplaştırmak istiyor. '
        'Yazmak sana kalıyor.',
    minFame: 70,
    fee: Economy.netMonthlyMinimumWage * 30,
    fameGain: 4,
    followerRatio: 0.05,
    happiness: 4,
  ),
];

MediaOpportunity? mediaOpportunityById(String id) {
  for (final MediaOpportunity o in kMediaOpportunities) {
    if (o.id == id) return o;
  }
  return null;
}

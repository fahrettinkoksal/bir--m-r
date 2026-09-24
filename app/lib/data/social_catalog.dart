/// Sosyal medya platformları ve içerik türleri.
///
/// Arayüz ve görseller Bir Ömür'e özgüdür; gerçek platformların logoları,
/// ekran tasarımları veya marka öğeleri kopyalanmaz — yalnızca tanınan
/// adları metin olarak geçer.
///
/// Sayısal değerler `prototypeOnly`'dir (`docs/DESIGN_REVIEW_QUEUE.md`,
/// Q-050).
library;

import 'package:flutter/material.dart';

/// Desteklenen platformlar.
enum SocialPlatform {
  video('YouTube', 'Video', Icons.play_circle_outline),
  foto('Instagram', 'Fotoğraf', Icons.photo_camera_outlined),
  mikroblog('X', 'Kısa yazı', Icons.tag_outlined),

  // Faho'nun isteği. Enum **sonuna** eklendi: eski kayıtlar platformu
  // adıyla sakladığı için (`_enumByName`) yeni değer eski kayıtları
  // bozmaz, kayıt sürümü değişmedi.
  kisaVideo('TikTok', 'Kısa video', Icons.music_note_outlined);

  const SocialPlatform(this.label, this.contentWord, this.icon);

  /// Ekranda görünen ad.
  final String label;

  /// Platformun içerik türünü anlatan kelime.
  final String contentWord;

  final IconData icon;

  /// Takipçi sayısının okunaklı adı.
  ///
  /// Yalnızca video platformunda "abone" denir; kalanında "takipçi".
  String get audienceWord => this == SocialPlatform.video ? 'abone' : 'takipçi';
}

/// Paylaşılabilecek bir içerik türü.
@immutable
class SocialContent {
  const SocialContent({
    required this.id,
    required this.platform,
    required this.label,
    required this.description,
    required this.baseReach,
    this.charismaWeight = 0.4,
    this.intelligenceWeight = 0.0,
    this.appearanceWeight = 0.0,
    this.riskOfLoss = 0.15,
    this.fameWeight = 1.0,
  });

  final String id;
  final SocialPlatform platform;
  final String label;
  final String description;

  /// prototypeOnly: hiç kitlesi olmayan birinin kazanabileceği taban.
  final int baseReach;

  /// prototypeOnly: karakter değerlerinin etkisi.
  final double charismaWeight;
  final double intelligenceWeight;
  final double appearanceWeight;

  /// prototypeOnly: paylaşımın takipçi **kaybettirme** olasılığı.
  final double riskOfLoss;

  /// prototypeOnly: üne katkı ağırlığı.
  final double fameWeight;
}

const List<SocialContent> kSocialContents = <SocialContent>[
  // --- Video platformu ---------------------------------------------------
  SocialContent(
    id: 'eglence_videosu',
    platform: SocialPlatform.video,
    label: 'Eğlenceli video çek',
    description: 'Kısa, hızlı kurgulu, tekrar izlenen türden.',
    baseReach: 40,
    charismaWeight: 0.6,
    riskOfLoss: 0.12,
  ),
  SocialContent(
    id: 'vlog',
    platform: SocialPlatform.video,
    label: 'Vlog çek',
    description: 'Günün nasıl geçtiğini anlatan bir video.',
    baseReach: 25,
    charismaWeight: 0.5,
    appearanceWeight: 0.2,
    riskOfLoss: 0.18,
  ),
  SocialContent(
    id: 'oyun_videosu',
    platform: SocialPlatform.video,
    label: 'Oyun videosu çek',
    description: 'Oynarken konuşmak; sabır ve mikrofon işi.',
    baseReach: 35,
    charismaWeight: 0.45,
    riskOfLoss: 0.15,
  ),
  SocialContent(
    id: 'bilgi_videosu',
    platform: SocialPlatform.video,
    label: 'Bilgilendirici video çek',
    description: 'Bir konuyu açıklayan, hazırlık isteyen video.',
    baseReach: 30,
    charismaWeight: 0.25,
    intelligenceWeight: 0.5,
    riskOfLoss: 0.1,
    fameWeight: 1.2,
  ),

  // --- Fotoğraf platformu -------------------------------------------------
  SocialContent(
    id: 'fotograf',
    platform: SocialPlatform.foto,
    label: 'Fotoğraf paylaş',
    description: 'İyi ışık, doğru an.',
    baseReach: 28,
    charismaWeight: 0.35,
    appearanceWeight: 0.45,
    riskOfLoss: 0.12,
  ),
  SocialContent(
    id: 'hikaye',
    platform: SocialPlatform.foto,
    label: 'Hikâye paylaş',
    description: 'Bir günlük; çabuk görülüp çabuk unutulur.',
    baseReach: 14,
    charismaWeight: 0.3,
    appearanceWeight: 0.3,
    riskOfLoss: 0.08,
    fameWeight: 0.6,
  ),
  SocialContent(
    id: 'kisa_video',
    platform: SocialPlatform.foto,
    label: 'Kısa video paylaş',
    description: 'Birkaç saniye, çok deneme.',
    baseReach: 34,
    charismaWeight: 0.5,
    appearanceWeight: 0.25,
    riskOfLoss: 0.16,
  ),

  // --- Mikroblog ----------------------------------------------------------
  SocialContent(
    id: 'gunluk_dusunce',
    platform: SocialPlatform.mikroblog,
    label: 'Günlük düşünce paylaş',
    description: 'Aklından geçeni birkaç cümleyle yaz.',
    baseReach: 16,
    charismaWeight: 0.35,
    riskOfLoss: 0.12,
    fameWeight: 0.7,
  ),
  SocialContent(
    id: 'mizah',
    platform: SocialPlatform.mikroblog,
    label: 'Mizah paylaş',
    description: 'Tutarsa çok tutar, tutmazsa sessizlik.',
    baseReach: 30,
    charismaWeight: 0.55,
    riskOfLoss: 0.2,
  ),
  SocialContent(
    id: 'bilgi_paylasimi',
    platform: SocialPlatform.mikroblog,
    label: 'Bilgilendirici paylaşım yap',
    description: 'Bir konuyu kısa ve anlaşılır biçimde özetle.',
    baseReach: 22,
    charismaWeight: 0.2,
    intelligenceWeight: 0.5,
    riskOfLoss: 0.08,
    fameWeight: 1.1,
  ),

  // --- Kısa video (TikTok) -----------------------------------------------
  //
  // Bu platformun karakteri şu: erişim tavanı yüksek ama oynak. Tek bir
  // içerik beklenmedik biçimde tutabilir, aynı içerik ertesi gün hiç
  // görülmeyebilir. Bu yüzden taban erişim diğer platformlardan yüksek,
  // takipçi kaybettirme riski de yüksek tutuldu.
  SocialContent(
    id: 'dans_akimi',
    platform: SocialPlatform.kisaVideo,
    label: 'Akımdaki dansı çek',
    description: 'Herkesin yaptığı şeyi sen de yap; tutarsa çok tutar.',
    baseReach: 48,
    charismaWeight: 0.45,
    appearanceWeight: 0.35,
    riskOfLoss: 0.22,
  ),
  SocialContent(
    id: 'sokak_roportaji',
    platform: SocialPlatform.kisaVideo,
    label: 'Sokak röportajı çek',
    description: 'Mikrofonu uzat, gerisi karşındakine kalmış.',
    baseReach: 42,
    charismaWeight: 0.6,
    riskOfLoss: 0.2,
  ),
  SocialContent(
    id: 'yemek_tarifi_videosu',
    platform: SocialPlatform.kisaVideo,
    label: 'Hızlı tarif videosu çek',
    description: 'Kırk saniyede bir yemek; kesme bol, sabır az.',
    baseReach: 38,
    charismaWeight: 0.3,
    intelligenceWeight: 0.2,
    riskOfLoss: 0.14,
  ),
  SocialContent(
    id: 'bilgi_kirintisi',
    platform: SocialPlatform.kisaVideo,
    label: 'Kısa bilgi videosu çek',
    description: 'Tek bir şeyi, tek bir nefeste anlat.',
    baseReach: 33,
    charismaWeight: 0.25,
    intelligenceWeight: 0.45,
    riskOfLoss: 0.12,
    fameWeight: 1.15,
  ),
];

List<SocialContent> contentsFor(SocialPlatform platform) => kSocialContents
    .where((SocialContent c) => c.platform == platform)
    .toList(growable: false);

SocialContent? socialContentById(String id) {
  for (final SocialContent c in kSocialContents) {
    if (c.id == id) return c;
  }
  return null;
}

/// prototypeOnly: hesap açmak için gereken en küçük yaş.
const int kSocialMinAge = 16;

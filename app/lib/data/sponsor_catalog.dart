/// Kurgusal sponsor kategorileri (Paket 10).
///
/// **Gerçek şirket adı, marka logosu veya reklam ağı kullanılmaz.**
/// Buradaki adlar oyuna özgü, uydurma iş kollarıdır. Tutarlar oyun
/// parasıdır; gerçek para veya uygulama içi satın alma yoktur.
///
/// Sayısal değerler `prototypeOnly`'dir (Q-079).
library;

import 'package:flutter/foundation.dart';

import '../domain/models/social_account.dart';
import 'social_catalog.dart';

/// Sponsorluk teklifi için gereken **en az takipçi** (D-104).
///
/// Faho'nun kararı: bir marka, platformda **5.000 takipçisi olmayan**
/// birine sponsorluk teklif etmez. Eşik kategoriye değil, platformun
/// kendisine bakar: iki platformda 3.000'er takipçi, tek platformda
/// 5.000 yerine geçmez.
const int kSponsorMinFollowers = 5000;

@immutable
class SponsorCategory {
  const SponsorCategory({
    required this.id,
    required this.label,
    required this.pitch,
    required this.minFollowers,
    required this.baseFee,
    this.platforms = const <SocialPlatform>{},
  });

  final String id;

  /// Ekranda görünen kurgusal iş kolu.
  final String label;

  /// Teklif metni.
  final String pitch;

  /// prototypeOnly: teklifin gelmesi için gereken en az takipçi.
  final int minFollowers;

  /// prototypeOnly: taban ücret (₺); kitleye göre büyür.
  final int baseFee;

  /// Yalnızca bu platformlarda teklif eder; boşsa hepsinde.
  final Set<SocialPlatform> platforms;

  /// Bu kategori [account] için uygun mu?
  ///
  /// Kategori kendi eşiğini koyabilir ama **hiçbiri** genel alt sınırın
  /// (D-104) altına inemez.
  bool fits(SocialAccount account) =>
      account.followers >= minFollowers &&
      account.followers >= kSponsorMinFollowers &&
      (platforms.isEmpty || platforms.contains(account.platform));
}

const List<SponsorCategory> kSponsorCategories = <SponsorCategory>[
  SponsorCategory(
    id: 'mahalle_kafe',
    label: 'mahalle kafe zinciri',
    pitch: 'Yeni şubelerini duyurmak istiyorlar; bir paylaşım yeterli.',
    minFollowers: 5000,
    baseFee: 3000,
  ),
  SponsorCategory(
    id: 'kirtasiye',
    label: 'kırtasiye markası',
    pitch: 'Okul sezonu için bir paylaşım istiyorlar.',
    minFollowers: 6000,
    baseFee: 4000,
  ),
  SponsorCategory(
    id: 'spor_icecegi',
    label: 'sporcu içeceği üreticisi',
    pitch:
        'Antrenman içeriğinin yanına küçük bir tanıtım koymanı '
        'istiyorlar.',
    minFollowers: 9000,
    baseFee: 7000,
    platforms: <SocialPlatform>{
      SocialPlatform.video,
      SocialPlatform.foto,
      SocialPlatform.kisaVideo,
    },
  ),
  SponsorCategory(
    id: 'mobil_oyun',
    label: 'bağımsız mobil oyun stüdyosu',
    pitch: 'Yeni oyunlarını bir videoda denemeni istiyorlar.',
    minFollowers: 5000,
    baseFee: 11000,
    platforms: <SocialPlatform>{SocialPlatform.video, SocialPlatform.kisaVideo},
  ),
  SponsorCategory(
    id: 'kitap_kulubu',
    label: 'çevrim içi kitap kulübü',
    pitch: 'Okuduğun bir kitaptan söz etmeni istiyorlar.',
    minFollowers: 7500,
    baseFee: 5000,
    platforms: <SocialPlatform>{SocialPlatform.mikroblog, SocialPlatform.video},
  ),
  SponsorCategory(
    id: 'yerel_lezzet',
    label: 'yerel lezzet markası',
    pitch: 'Ürünlerini kısa bir videoda denemeni istiyorlar.',
    minFollowers: 12000,
    baseFee: 8500,
    platforms: <SocialPlatform>{SocialPlatform.kisaVideo, SocialPlatform.foto},
  ),
  SponsorCategory(
    id: 'elektronik',
    label: 'elektronik mağazası',
    pitch: 'Bir ürünlerini tanıtmanı istiyorlar.',
    minFollowers: 20000,
    baseFee: 18000,
  ),
];

SponsorCategory? sponsorCategoryById(String id) {
  for (final SponsorCategory c in kSponsorCategories) {
    if (c.id == id) return c;
  }
  return null;
}

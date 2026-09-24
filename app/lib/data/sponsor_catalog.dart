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
  bool fits(SocialAccount account) =>
      account.followers >= minFollowers &&
      (platforms.isEmpty || platforms.contains(account.platform));
}

const List<SponsorCategory> kSponsorCategories = <SponsorCategory>[
  SponsorCategory(
    id: 'mahalle_kafe',
    label: 'mahalle kafe zinciri',
    pitch: 'Yeni şubelerini duyurmak istiyorlar; bir paylaşım yeterli.',
    minFollowers: 1000,
    baseFee: 28000,
  ),
  SponsorCategory(
    id: 'kirtasiye',
    label: 'kırtasiye markası',
    pitch: 'Okul sezonu için bir paylaşım istiyorlar.',
    minFollowers: 1500,
    baseFee: 38000,
  ),
  SponsorCategory(
    id: 'spor_icecegi',
    label: 'sporcu içeceği üreticisi',
    pitch:
        'Antrenman içeriğinin yanına küçük bir tanıtım koymanı '
        'istiyorlar.',
    minFollowers: 3000,
    baseFee: 70000,
    platforms: <SocialPlatform>{SocialPlatform.video, SocialPlatform.foto},
  ),
  SponsorCategory(
    id: 'mobil_oyun',
    label: 'bağımsız mobil oyun stüdyosu',
    pitch: 'Yeni oyunlarını bir videoda denemeni istiyorlar.',
    minFollowers: 5000,
    baseFee: 110000,
    platforms: <SocialPlatform>{SocialPlatform.video},
  ),
  SponsorCategory(
    id: 'kitap_kulubu',
    label: 'çevrim içi kitap kulübü',
    pitch: 'Okuduğun bir kitaptan söz etmeni istiyorlar.',
    minFollowers: 2500,
    baseFee: 50000,
    platforms: <SocialPlatform>{SocialPlatform.mikroblog, SocialPlatform.video},
  ),
  SponsorCategory(
    id: 'elektronik',
    label: 'elektronik mağazası',
    pitch: 'Bir ürünlerini tanıtmanı istiyorlar.',
    minFollowers: 8000,
    baseFee: 190000,
  ),
];

SponsorCategory? sponsorCategoryById(String id) {
  for (final SponsorCategory c in kSponsorCategories) {
    if (c.id == id) return c;
  }
  return null;
}

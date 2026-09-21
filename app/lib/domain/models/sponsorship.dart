import 'package:flutter/foundation.dart';

import '../../data/social_catalog.dart';
import '../../data/sponsor_catalog.dart';

/// Oyuncuya gelen, henüz yanıtlanmamış sponsorluk teklifi.
///
/// Sponsorlar **kurgusaldır**: gerçek şirket adı, logo veya reklam ağı
/// kullanılmaz (Paket 10). Gerçek para veya uygulama içi satın alma da
/// yoktur; bütün tutarlar oyun parasıdır.
@immutable
class SponsorOffer {
  const SponsorOffer({
    required this.id,
    required this.categoryId,
    required this.platform,
    required this.fee,
    required this.offeredAtAge,
  });

  /// Bu teklifin tekil kimliği (kabul edilirse yükümlülüğe taşınır).
  final String id;

  /// Kurgusal sponsor kategorisi.
  final String categoryId;

  /// Paylaşımın yapılacağı platform.
  final SocialPlatform platform;

  /// prototypeOnly: kabul edilip paylaşım yapılınca ödenecek tutar (₺).
  final int fee;

  final int offeredAtAge;

  SponsorCategory? get category => sponsorCategoryById(categoryId);

  String get label => category?.label ?? categoryId;
}

/// Kabul edilmiş ve henüz tamamlanmamış sponsorluk yükümlülüğü.
///
/// Ödeme **paylaşım gerçekten yapıldığında** işler; yapılmayan paylaşım
/// için gelir üretilmez.
@immutable
class SponsorDeal {
  const SponsorDeal({
    required this.id,
    required this.categoryId,
    required this.platform,
    required this.fee,
    required this.acceptedAtAge,
    this.completedAtAge,
    this.expired = false,
  });

  final String id;
  final String categoryId;
  final SocialPlatform platform;
  final int fee;
  final int acceptedAtAge;

  /// Yükümlülüğün yerine getirildiği yaş; henüz yapılmadıysa `null`.
  final int? completedAtAge;

  /// Süresi dolduğu için ödenmeden kapandı mı?
  final bool expired;

  bool get isOpen => completedAtAge == null && !expired;

  SponsorCategory? get category => sponsorCategoryById(categoryId);

  String get label => category?.label ?? categoryId;

  SponsorDeal copyWith({int? completedAtAge, bool? expired}) => SponsorDeal(
        id: id,
        categoryId: categoryId,
        platform: platform,
        fee: fee,
        acceptedAtAge: acceptedAtAge,
        completedAtAge: completedAtAge ?? this.completedAtAge,
        expired: expired ?? this.expired,
      );
}

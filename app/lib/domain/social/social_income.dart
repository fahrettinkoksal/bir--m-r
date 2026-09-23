import 'dart:math';

import '../../data/social_catalog.dart';
import '../../data/sponsor_catalog.dart';
import '../generation/random_util.dart';
import '../models/game_state.dart';
import '../models/social_account.dart';
import '../models/sponsorship.dart';

/// Sosyal medya geliri ve sponsorluk teklifleri (Paket 10).
///
/// Kurallar:
/// - Gelir **takipçi sayısına körü körüne eşit değildir**: paylaşımın
///   gerçek etkileşimi (kazanılan takipçi) ve içerik türü belirleyicidir.
/// - Her paylaşım para kazandırmaz.
/// - Yeni açılmış, kitlesi olmayan hesap gelir üretmez.
/// - Sponsorluk ücreti **paylaşım gerçekten yapıldığında** ödenir.
///
/// Bütün tutarlar oyun parasıdır; gerçek para veya uygulama içi satın
/// alma yoktur. Sayılar `prototypeOnly`'dir (Q-079).
abstract final class SocialIncome {
  /// prototypeOnly: gelir elde etmek için gereken en az takipçi.
  static const int prototypeOnlyEarningThreshold = 1000;

  /// prototypeOnly: hesabın gelir üretebilmesi için geçmesi gereken yıl.
  ///
  /// Dün açılmış hesap, takipçisi olsa bile hemen ödeme almaz.
  static const int prototypeOnlyMinAccountAge = 1;

  /// prototypeOnly: gelir çıkma ihtimalinin tabanı.
  static const double prototypeOnlyEarningChance = 0.45;

  /// prototypeOnly: kitle büyüdükçe ihtimalin artış payı (üst sınırlı).
  static const double prototypeOnlyChanceBonus = 0.3;

  /// prototypeOnly: her yeni takipçinin getirdiği tutar (₺).
  static const double prototypeOnlyPerNewFollower = 45;

  /// prototypeOnly: mevcut kitlenin taban katkısı (₺ / takipçi).
  static const double prototypeOnlyPerFollower = 0.9;

  /// prototypeOnly: tek paylaşımın üst sınırı (₺).
  ///
  /// Sosyal medya tek başına ekonomiyi bozmasın diye konmuştur.
  static const int prototypeOnlyMaxPerPost = 150000;

  /// prototypeOnly: sponsorluk teklifinin yıllık çıkma ihtimali.
  static const double prototypeOnlyOfferChance = 0.35;

  /// prototypeOnly: kabul edilen sponsorluğun tamamlanması için süre (yıl).
  static const int prototypeOnlyDealDeadline = 2;

  /// prototypeOnly: sponsorluk ücretinin kitleye göre büyüme katsayısı.
  static const double prototypeOnlyFeePerFollower = 1.2;

  // -------------------------------------------------------------------
  // Paylaşım geliri
  // -------------------------------------------------------------------

  /// Bu hesap gelir üretebilir mi?
  static bool canEarn(GameState state, SocialAccount account) =>
      account.followers >= prototypeOnlyEarningThreshold &&
      state.player.age - account.createdAtAge >= prototypeOnlyMinAccountAge;

  /// Bir paylaşımın kazandırdığı tutar; kazanmadıysa 0.
  ///
  /// [followerDelta] paylaşımın **gerçek** sonucudur: takipçi kaybettiren
  /// ya da hiç ilgi görmeyen paylaşım para kazandırmaz.
  static int earningsFor({
    required GameState state,
    required SocialAccount account,
    required SocialContent content,
    required int followerDelta,
    required Random rng,
  }) {
    if (!canEarn(state, account)) return 0;
    if (followerDelta <= 0) return 0;

    // Kitle büyüdükçe gelir ihtimali artar ama hiçbir zaman garanti olmaz.
    final double oran = (account.followers / 50000).clamp(0.0, 1.0);
    final double ihtimal =
        prototypeOnlyEarningChance + oran * prototypeOnlyChanceBonus;
    if (!rng.chance(ihtimal)) return 0;

    final double etkilesim = followerDelta * prototypeOnlyPerNewFollower;
    final double kitle = account.followers * prototypeOnlyPerFollower;
    // İçerik türünün ağırlığı: hazırlık isteyen içerik daha iyi ödenir.
    final double tur = 0.6 + content.fameWeight * 0.4;
    final double dalgalanma = 0.7 + rng.nextDouble() * 0.6;

    final int tutar = ((etkilesim + kitle) * tur * dalgalanma).round();
    return tutar.clamp(0, prototypeOnlyMaxPerPost);
  }

  /// Gelirin hayat günlüğüne yazılacak açıklaması.
  static String earningText({
    required SocialContent content,
    required SocialPlatform platform,
    required int followerDelta,
    required int amount,
  }) =>
      '${platform.label}: "${content.label}" paylaşımın '
      '$followerDelta ${platform.audienceWord} getirdi; '
      'içerik gelirinden kazandın.';

  // -------------------------------------------------------------------
  // Sponsorluk
  // -------------------------------------------------------------------

  /// Bu hesap için uygun sponsor kategorileri.
  static List<SponsorCategory> categoriesFor(SocialAccount account) =>
      kSponsorCategories
          .where((SponsorCategory c) => c.fits(account))
          .toList(growable: false);

  /// Yeni bir sponsorluk teklifi üretir; koşul yoksa `null`.
  ///
  /// Aynı anda yalnızca bir teklif bekler ve açık bir yükümlülük varken
  /// yeni teklif gelmez.
  static SponsorOffer? maybeOffer(GameState state, Random rng) {
    if (state.sponsorOffer != null) return null;
    if (state.openDeals.isNotEmpty) return null;

    final List<({SocialAccount account, SponsorCategory category})> adaylar =
        <({SocialAccount account, SponsorCategory category})>[];
    for (final SocialAccount a in state.socialAccounts) {
      if (!canEarn(state, a)) continue;
      for (final SponsorCategory c in categoriesFor(a)) {
        adaylar.add((account: a, category: c));
      }
    }
    if (adaylar.isEmpty) return null;
    if (!rng.chance(prototypeOnlyOfferChance)) return null;

    final ({SocialAccount account, SponsorCategory category}) secim =
        rng.pick(adaylar);
    final int ucret = feeFor(secim.category, secim.account);
    return SponsorOffer(
      id: 'sponsor-${state.player.age}-${secim.category.id}-'
          '${secim.account.platform.name}',
      categoryId: secim.category.id,
      platform: secim.account.platform,
      fee: ucret,
      offeredAtAge: state.player.age,
    );
  }

  /// prototypeOnly: teklif ücreti — taban + kitleye bağlı pay.
  static int feeFor(SponsorCategory category, SocialAccount account) {
    final int fazla =
        (account.followers - category.minFollowers).clamp(0, 1 << 30);
    return category.baseFee + (fazla * prototypeOnlyFeePerFollower).round();
  }

  /// Teklifin ekranda gösterilecek metni.
  static String offerText(SponsorOffer offer) {
    // Kategori tanıtımı yoksa araya çift boşluk girmesin (Paket 43).
    final String tanitim = offer.category?.pitch ?? '';
    final String arada = tanitim.isEmpty ? '' : '$tanitim ';
    return 'Bir ${offer.label} sana ulaştı. $arada'
        'Karşılığında ${offer.platform.label} üzerinde bir paylaşım '
        'yapman gerekiyor.';
  }
}

import 'dart:math';

import '../../data/social_catalog.dart';
import '../../data/sponsor_catalog.dart';
import '../generation/random_util.dart';
import '../models/game_state.dart';
import '../models/social_account.dart';
import '../models/sponsorship.dart';
import '../../text/turkish_text.dart';

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

  /// prototypeOnly: sponsorluk teklifinin yıllık çıkma ihtimali.
  static const double prototypeOnlyOfferChance = 0.35;

  /// prototypeOnly: kabul edilen sponsorluğun tamamlanması için süre (yıl).
  static const int prototypeOnlyDealDeadline = 2;

  /// prototypeOnly: sponsorluk ücretinin takipçi başına payı (₺).
  ///
  /// Eskiden ücret, kategorinin eşiğini **aşan** takipçi başına 3,2 ₺
  /// üzerinden hesaplanıyordu; eşiği yeni geçen hesapla eşiğin çok
  /// üstündeki hesap arasındaki fark anlamsız biçimde büyüyordu.
  /// Faho'nun kararı: ücret **kitlenin tamamıyla** ölçeklensin.
  /// Türkiye'de 2026'da bir gönderi için kabaca takipçi başına 1 ₺
  /// civarı konuşuluyor; oyunda 0,9 ₺ kullanılıyor (D-104).
  ///
  /// **D-117 ile yeniden ölçüldü.** Faho bildirdi: "sponsorluk ücretleri
  /// hâlâ çok fazla". Araştırıldı: 2026'da Türkiye'de 10K-100K takipçili
  /// bir hesap gönderi başına kabaca **3.000-15.000 ₺** alıyor. Oyun
  /// 100.000 takipçiye **118.000 ₺** ödüyordu — gerçeğin sekiz katı.
  /// Yeni oran ve düşürülen taban ücretlerle 100.000 takipçi **15.000 ₺**
  /// veriyor; bant tutuyor.
  static const double prototypeOnlyFeePerFollower = 0.12;

  /// prototypeOnly: süresi dolan sponsorluğun kitleye maliyeti.
  ///
  /// Kabul edip paylaşmamanın bir bedeli vardır: marka küser, takipçi
  /// güveni sarsılır (D-104).
  static const double prototypeOnlyBrokenDealFollowerLoss = 0.04;

  /// prototypeOnly: süresi dolan sponsorluğun mutluluğa etkisi.
  static const int prototypeOnlyBrokenDealHappiness = -4;

  // -------------------------------------------------------------------
  // Kitle yorgunluğu (D-119)
  // -------------------------------------------------------------------

  /// prototypeOnly: art arda sponsorluğun sayıldığı pencere (yıl).
  static const int prototypeOnlyFatigueWindowYears = 5;

  /// prototypeOnly: bu pencerede bedelsiz sayılan sponsorluk adedi.
  ///
  /// Faho bildirdi: "her sponsorlukta kayıba gerek yok fakat sürekli
  /// sponsor alırsa kayıp yaşansın". Ara sıra reklam yapmak kimseyi
  /// kaçırmaz; hesabı reklam panosuna çeviren takipçi kaybeder.
  static const int prototypeOnlyFatigueFreeDeals = 2;

  /// prototypeOnly: eşiği aşan her sponsorluğun kitleye maliyeti.
  static const double prototypeOnlyFatigueLossPerDeal = 0.025;

  /// prototypeOnly: yorgunluk kaybının üst sınırı.
  static const double prototypeOnlyMaxFatigueLoss = 0.12;

  /// Bu platformda son yıllarda yapılan sponsorlu paylaşımın kitleye
  /// maliyeti (oran). Eşiğin altında 0 döner (D-119).
  static double audienceFatigue({
    required GameState state,
    required SocialPlatform platform,
    required int age,
  }) {
    int yakin = 0;
    for (final SponsorDeal d in state.sponsorDeals) {
      final int? bitis = d.completedAtAge;
      if (bitis == null) continue;
      if (d.platform != platform) continue;
      if (age - bitis >= prototypeOnlyFatigueWindowYears) continue;
      yakin++;
    }
    final int fazla = yakin - prototypeOnlyFatigueFreeDeals;
    if (fazla <= 0) return 0;
    return (fazla * prototypeOnlyFatigueLossPerDeal)
        .clamp(0.0, prototypeOnlyMaxFatigueLoss);
  }

  /// Sözünü tutmamanın kitleye maliyeti; **tekrarladıkça artar** (D-119).
  ///
  /// İlk kez olduğunda taban oran uygulanır; aynı oyuncu sözünü tutmamayı
  /// alışkanlık hâline getirirse marka çevresi ve kitle daha sert tepki
  /// verir.
  static double brokenDealLoss(GameState state) {
    int kirilan = 0;
    for (final SponsorDeal d in state.sponsorDeals) {
      if (d.expired) kirilan++;
    }
    final double oran =
        prototypeOnlyBrokenDealFollowerLoss * (1 + kirilan.clamp(0, 4) * 0.5);
    return oran.clamp(0.0, 0.15);
  }

  // -------------------------------------------------------------------
  // Paylaşım geliri
  // -------------------------------------------------------------------

  /// Bu hesap gelir üretebilir mi?
  static bool canEarn(GameState state, SocialAccount account) =>
      account.followers >= prototypeOnlyEarningThreshold &&
      state.player.age - account.createdAtAge >= prototypeOnlyMinAccountAge;

  /// prototypeOnly: platformun gelir paylaşımına giren en az takipçi
  /// (D-117).
  ///
  /// Faho bildirdi: "sosyal medyada dümdüz yaptığım paylaşımlardan ücret
  /// kazanıyorum, bu olmamalı". Haklı: kimse sıradan bir gönderi için
  /// para almaz. Para iki yerden gelir — **sponsorluk** ve platformun
  /// büyük hesaplara ödediği **gelir payı**. İkincisi gönderi başına
  /// değil, yıllıktır ve ancak ciddi bir kitleden sonra başlar.
  static const int prototypeOnlyRevenueShareThreshold = 100000;

  /// prototypeOnly: gelir payının takipçi başına yıllık tutarı (₺).
  static const double prototypeOnlyYearlyRevenuePerFollower = 0.9;

  /// Platformun bu hesaba ödediği **yıllık** gelir payı (D-117).
  ///
  /// Gönderi başına değil yıllıktır; sıradan paylaşım para kazandırmaz
  /// ama ciddi bir kitlenin kendisi gelir üretir. Eşiğin altındaki hesap
  /// hiçbir şey almaz.
  static int yearlyRevenueShare(SocialAccount account) {
    if (account.followers < prototypeOnlyRevenueShareThreshold) return 0;
    return (account.followers * prototypeOnlyYearlyRevenuePerFollower).round();
  }

  /// Gelirin hayat günlüğüne yazılacak açıklaması.
  static String earningText({
    required SocialContent content,
    required SocialPlatform platform,
    required int followerDelta,
    required int amount,
  }) =>
      '${platform.label}: "${content.label}" paylaşımın '
      '${trNumber(followerDelta)} ${platform.audienceWord} getirdi; '
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

  /// prototypeOnly: teklif ücreti — taban + **o hesabın** kitlesine bağlı
  /// pay (D-104, D-117).
  ///
  /// Kitle **hesap bazındadır**, toplam takipçi değil: Instagram'da 5.000
  /// takipçi varsa teklif Instagram için gelir; başka hesaplarla toplanıp
  /// eşik geçilmiş sayılmaz (Faho'nun isteği).
  ///
  /// Ölçek (en küçük kategori, taban 3.000 ₺):
  /// 5.000 → 3.600 ₺ · 20.000 → 5.400 ₺ · 100.000 → 15.000 ₺ ·
  /// 500.000 → 63.000 ₺.
  static int feeFor(SponsorCategory category, SocialAccount account) {
    final int kitle = account.followers.clamp(0, 1 << 30);
    return category.baseFee + (kitle * prototypeOnlyFeePerFollower).round();
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

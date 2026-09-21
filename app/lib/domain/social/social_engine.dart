import 'dart:math';

import '../../data/social_catalog.dart';
import '../effects/effect_diff.dart';
import '../models/applied_effect.dart';
import '../models/game_state.dart';
import '../models/interaction.dart';
import '../models/life_log.dart';
import '../models/social_account.dart';
import '../models/sponsorship.dart';
import 'social_income.dart';
import '../../text/turkish_text.dart';

/// Bir sosyal medya işleminin sonucu.
class SocialOutcome {
  const SocialOutcome({
    required this.applied,
    required this.text,
    this.effects = const <AppliedEffect>[],
    this.followerDelta = 0,
    this.earned = 0,
  });

  final bool applied;
  final String text;
  final List<AppliedEffect> effects;

  /// Paylaşımın takipçi değişimi; eksi olabilir.
  final int followerDelta;

  /// Bu işlemden cüzdana giren tutar (₺); kazanç yoksa 0.
  final int earned;
}

class SocialResult {
  const SocialResult({required this.state, required this.outcome});

  final GameState state;
  final SocialOutcome outcome;
}

/// Sosyal medya hesapları, paylaşımlar ve Ün.
///
/// Kurallar:
/// - Hesap açmak isteğe bağlıdır; hesabı olmayan platformda paylaşım
///   yapılamaz.
/// - Her paylaşım takipçi kazandırmaz; bazıları az ilgi görür, bazıları
///   takipçi kaybettirir.
/// - Aynı içeriği üst üste paylaşmak kazancı düşürür.
/// - **Ün** yalnızca gerçekten oluştuğunda görünür hâle gelir (D-027).
///
/// Sayısal değerler `prototypeOnly`'dir (`docs/DESIGN_REVIEW_QUEUE.md`,
/// Q-050).
class SocialEngine {
  const SocialEngine();

  /// prototypeOnly: mevcut kitlenin erişime katkı katsayısı.
  static const double prototypeOnlyAudienceFactor = 0.06;

  /// prototypeOnly: aynı içeriğin son paylaşımlarda her tekrarı için
  /// uygulanan azaltma.
  static const double prototypeOnlyRepeatPenalty = 0.25;

  /// prototypeOnly: bir yaşta anlamlı sonuç veren en fazla paylaşım.
  static const int prototypeOnlyMaxPostsPerAge = 6;

  /// prototypeOnly: takipçi kaybının üst sınırı (mevcut kitlenin oranı).
  static const double prototypeOnlyMaxLossRatio = 0.08;

  /// prototypeOnly: Ünün açılması için gereken toplam takipçi.
  static const int prototypeOnlyFameThreshold = 500;

  /// prototypeOnly: Ün hesabında kaç takipçi bir Ün puanına denk gelir.
  static const int prototypeOnlyFollowersPerFame = 900;

  /// prototypeOnly: Ünün üst sınırı.
  static const int prototypeOnlyMaxFame = 100;

  // ===================================================================
  // Hesap
  // ===================================================================

  InteractionAvailability accountAvailability(
    GameState state,
    SocialPlatform platform,
  ) {
    if (state.player.age < kSocialMinAge) {
      return InteractionAvailability.blocked(
        'Sosyal medya hesabı $kSocialMinAge yaşından itibaren açılabilir.',
      );
    }
    if (state.accountFor(platform) != null) {
      return const InteractionAvailability.blocked('Bu hesabın zaten var.');
    }
    return const InteractionAvailability.allowed();
  }

  /// Hesap açar. Zorunlu değildir; oyuncu hiç açmayabilir.
  SocialResult openAccount(GameState state, SocialPlatform platform) {
    final InteractionAvailability check = accountAvailability(state, platform);
    if (!check.isAllowed) return _blocked(state, check.reason!);

    final String metin = '${platform.label} hesabı açtın. '
        'İlk ${platform.audienceWord}lerin tanıdıkların olacak.';
    final GameState next = state.copyWith(
      socialAccounts: List<SocialAccount>.unmodifiable(<SocialAccount>[
        ...state.socialAccounts,
        SocialAccount(platform: platform, createdAtAge: state.player.age),
      ]),
    );
    return SocialResult(
      state: _log(next, metin),
      outcome: SocialOutcome(applied: true, text: metin),
    );
  }

  // ===================================================================
  // Paylaşım
  // ===================================================================

  InteractionAvailability postAvailability(
    GameState state,
    SocialContent content,
  ) {
    final SocialAccount? account = state.accountFor(content.platform);
    if (account == null) {
      return InteractionAvailability.blocked(
        'Önce ${content.platform.label} hesabı açman gerekiyor.',
      );
    }
    if (_postsThisAge(state, account) >= prototypeOnlyMaxPostsPerAge) {
      return InteractionAvailability.blocked(
        'Bu yıl ${content.platform.label} üzerinde yeterince paylaşım '
        'yaptın; seneye devam. Diğer platformlar etkilenmez.',
      );
    }
    return const InteractionAvailability.allowed();
  }

  /// Bu yaşta **bu platformda** yapılan paylaşım sayısı.
  ///
  /// Sayaç platform başına ayrıdır ve hesabın kendi paylaşım geçmişinden
  /// okunur; bir platformun sınırı diğerini kapatmaz, yaş ilerleyince her
  /// platformun sayacı kendiliğinden yenilenir.
  int _postsThisAge(GameState state, SocialAccount account) =>
      account.postsAtAge(state.player.age);

  /// Bu yaşta bu platformda kaç paylaşım hakkı kaldı?
  int remainingPosts(GameState state, SocialPlatform platform) {
    final SocialAccount? account = state.accountFor(platform);
    if (account == null) return 0;
    return (prototypeOnlyMaxPostsPerAge - _postsThisAge(state, account))
        .clamp(0, prototypeOnlyMaxPostsPerAge);
  }

  /// Paylaşım yapar.
  ///
  /// Sonuç içerik türüne, mevcut kitleye, karakter özelliklerine, geçmiş
  /// paylaşımlara ve şansa bağlıdır.
  SocialResult post(GameState state, SocialContent content, Random rng) {
    final InteractionAvailability check = postAvailability(state, content);
    if (!check.isAllowed) return _blocked(state, check.reason!);

    final SocialAccount account = state.accountFor(content.platform)!;
    final int delta = _followerDelta(state, account, content, rng);

    final int yeniTakipci = (account.followers + delta).clamp(0, 1 << 30);
    final int gercekDelta = yeniTakipci - account.followers;

    // İçerik geliri: kitlesi olan hesapta, gerçekten ilgi gören
    // paylaşımda ve garanti olmadan (Paket 10).
    final int kazanc = SocialIncome.earningsFor(
      state: state,
      account: account,
      content: content,
      followerDelta: gercekDelta,
      rng: rng,
    );

    // Açık bir sponsorluk varsa ve paylaşım o platformdaysa yükümlülük
    // **bu paylaşımla** yerine gelir; ücret bir kez ödenir.
    final SponsorDeal? sponsor = _openDealFor(state, content.platform);
    final int sponsorUcreti = sponsor?.fee ?? 0;

    final SocialAccount guncel = account.copyWith(
      followers: yeniTakipci,
      posts: List<SocialPost>.unmodifiable(<SocialPost>[
        ...account.posts,
        SocialPost(
          contentId: content.id,
          age: state.player.age,
          followerDelta: gercekDelta,
          earned: kazanc + sponsorUcreti,
          sponsorId: sponsor?.id,
        ),
      ]),
    );

    GameState next = state.copyWith(
      socialAccounts: List<SocialAccount>.unmodifiable(
        state.socialAccounts
            .map((SocialAccount a) => a.platform == content.platform ? guncel : a)
            .toList(growable: false),
      ),
    );
    next = _updateFame(next, content);

    // Para cüzdana gerçekten işlenir.
    if (kazanc + sponsorUcreti > 0) {
      next = next.copyWith(
        player: next.player.copyWith(
          wallet: next.player.wallet + kazanc + sponsorUcreti,
        ),
      );
    }
    if (sponsor != null) {
      next = next.copyWith(
        sponsorDeals: List<SponsorDeal>.unmodifiable(
          next.sponsorDeals
              .map((SponsorDeal d) => d.id == sponsor.id
                  ? d.copyWith(completedAtAge: next.player.age)
                  : d)
              .toList(growable: false),
        ),
      );
    }

    final String metin = _postText(content, gercekDelta, account.platform);

    // Günlükte paranın **nereden** geldiği ayrı ayrı yazılır.
    GameState kayitli = gercekDelta.abs() >= 1 ? _log(next, metin) : next;
    if (kazanc > 0) {
      kayitli = _log(
        kayitli,
        '${SocialIncome.earningText(
          content: content,
          platform: account.platform,
          followerDelta: gercekDelta,
          amount: kazanc,
        )} ${trMoney(kazanc)} cüzdanına girdi.',
      );
    }
    if (sponsor != null) {
      kayitli = _log(
        kayitli,
        '${sponsor.label} sponsorluğunun paylaşımını yaptın; '
        '${trMoney(sponsor.fee)} ödendi.',
      );
    }

    return SocialResult(
      state: kayitli,
      outcome: SocialOutcome(
        applied: true,
        text: metin,
        effects: diffAppliedEffects(state, kayitli),
        followerDelta: gercekDelta,
        earned: kazanc + sponsorUcreti,
      ),
    );
  }

  /// Bu platformda açık bekleyen sponsorluk.
  SponsorDeal? _openDealFor(GameState state, SocialPlatform platform) {
    for (final SponsorDeal d in state.sponsorDeals) {
      if (d.isOpen && d.platform == platform) return d;
    }
    return null;
  }

  // ===================================================================
  // Sponsorluk
  // ===================================================================

  /// Teklifi kabul eder: yükümlülük açılır, **ödeme henüz yapılmaz**.
  SocialResult acceptSponsor(GameState state) {
    final SponsorOffer? teklif = state.sponsorOffer;
    if (teklif == null) {
      return _blocked(state, 'Bekleyen bir sponsorluk teklifi yok.');
    }
    final String metin = '${teklif.label} ile anlaştın. '
        'Ücret, ${teklif.platform.label} üzerinde paylaşımı yapınca '
        'ödenecek.';
    final GameState next = state.copyWith(
      sponsorOffer: null,
      sponsorDeals: List<SponsorDeal>.unmodifiable(<SponsorDeal>[
        ...state.sponsorDeals,
        SponsorDeal(
          id: teklif.id,
          categoryId: teklif.categoryId,
          platform: teklif.platform,
          fee: teklif.fee,
          acceptedAtAge: state.player.age,
        ),
      ]),
    );
    return SocialResult(
      state: _log(next, metin),
      outcome: SocialOutcome(applied: true, text: metin),
    );
  }

  /// Teklifi reddeder: hiçbir gelir oluşmaz.
  SocialResult declineSponsor(GameState state) {
    final SponsorOffer? teklif = state.sponsorOffer;
    if (teklif == null) {
      return _blocked(state, 'Bekleyen bir sponsorluk teklifi yok.');
    }
    final String metin = '${teklif.label} teklifini kabul etmedin.';
    return SocialResult(
      state: _log(state.copyWith(sponsorOffer: null), metin),
      outcome: SocialOutcome(applied: true, text: metin),
    );
  }

  /// Yıl geçerken süresi dolan sponsorlukları kapatır.
  ///
  /// Yapılmayan paylaşım için **ödeme yapılmaz**; yükümlülük sessizce
  /// silinmez, "süresi doldu" olarak kapanır.
  ({GameState state, List<String> logTexts}) expireDeals(
    GameState state,
    int newAge,
  ) {
    final List<String> satirlar = <String>[];
    final List<SponsorDeal> guncel = state.sponsorDeals.map((SponsorDeal d) {
      if (!d.isOpen) return d;
      if (newAge - d.acceptedAtAge < SocialIncome.prototypeOnlyDealDeadline) {
        return d;
      }
      satirlar.add(
        '${d.label} sponsorluğu için paylaşım yapmadın; anlaşma düştü '
        've ödeme olmadı.',
      );
      return d.copyWith(expired: true);
    }).toList(growable: false);

    if (satirlar.isEmpty) return (state: state, logTexts: satirlar);
    return (
      state: state.copyWith(
        sponsorDeals: List<SponsorDeal>.unmodifiable(guncel),
      ),
      logTexts: satirlar,
    );
  }

  /// Takipçi değişimi.
  int _followerDelta(
    GameState state,
    SocialAccount account,
    SocialContent content,
    Random rng,
  ) {
    // Aynı içeriği üst üste paylaşmak kazancı düşürür.
    final int tekrar = account.recentCountOf(content.id);
    final double tekrarCarpani =
        (1 - tekrar * prototypeOnlyRepeatPenalty).clamp(0.1, 1.0);

    // Takipçi kaybı riski: içerik türüne ve tekrara bağlı.
    final double kayipRiski =
        (content.riskOfLoss + tekrar * 0.05).clamp(0.0, 0.6);
    if (rng.nextDouble() < kayipRiski) {
      final int enFazlaKayip =
          (account.followers * prototypeOnlyMaxLossRatio).round();
      if (enFazlaKayip <= 0) return 0;
      return -(rng.nextInt(enFazlaKayip) + 1);
    }

    final double karakter = content.charismaWeight * state.player.stats.charisma +
        content.intelligenceWeight * state.player.stats.intelligence +
        content.appearanceWeight * state.player.stats.appearance;

    final double kitle = account.followers * prototypeOnlyAudienceFactor;
    final double sans = 0.5 + rng.nextDouble(); // prototypeOnly: 0.5 - 1.5

    final double ham =
        (content.baseReach + karakter * 0.5 + kitle) * tekrarCarpani * sans;
    return ham.round();
  }

  /// Ün, gerçekten bir kitle oluştuğunda açılır (D-027).
  GameState _updateFame(GameState state, SocialContent content) {
    final int toplam = state.totalFollowers;
    if (toplam < prototypeOnlyFameThreshold && !state.player.fameUnlocked) {
      return state;
    }

    final int hesaplanan =
        (toplam / prototypeOnlyFollowersPerFame * content.fameWeight)
            .round()
            .clamp(1, prototypeOnlyMaxFame);
    final int mevcut = state.player.fame ?? 0;
    if (hesaplanan <= mevcut) return state;

    return state.copyWith(
      player: state.player.copyWith(fame: hesaplanan),
    );
  }

  String _postText(SocialContent content, int delta, SocialPlatform platform) {
    if (delta > 0) {
      return '${content.label}: paylaşım ilgi gördü, '
          '$delta ${platform.audienceWord} kazandın.';
    }
    if (delta < 0) {
      return '${content.label}: beklediğin olmadı, '
          '${-delta} ${platform.audienceWord} kaybettin.';
    }
    return '${content.label}: kimse fark etmedi.';
  }

  SocialResult _blocked(GameState state, String reason) => SocialResult(
        state: state,
        outcome: SocialOutcome(applied: false, text: reason),
      );

  GameState _log(GameState state, String text) => state.copyWith(
        log: List<LifeLogEntry>.unmodifiable(<LifeLogEntry>[
          ...state.log,
          LifeLogEntry(
            age: state.player.age,
            text: text,
            category: LogCategory.kisisel,
          ),
        ]),
      );
}

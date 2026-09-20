import 'dart:math';

import '../../data/social_catalog.dart';
import '../effects/effect_diff.dart';
import '../models/applied_effect.dart';
import '../models/game_state.dart';
import '../models/interaction.dart';
import '../models/life_log.dart';
import '../models/social_account.dart';

/// Bir sosyal medya işleminin sonucu.
class SocialOutcome {
  const SocialOutcome({
    required this.applied,
    required this.text,
    this.effects = const <AppliedEffect>[],
    this.followerDelta = 0,
  });

  final bool applied;
  final String text;
  final List<AppliedEffect> effects;

  /// Paylaşımın takipçi değişimi; eksi olabilir.
  final int followerDelta;
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
    final SocialAccount guncel = account.copyWith(
      followers: yeniTakipci,
      posts: List<SocialPost>.unmodifiable(<SocialPost>[
        ...account.posts,
        SocialPost(
          contentId: content.id,
          age: state.player.age,
          followerDelta: yeniTakipci - account.followers,
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

    final int gercekDelta = yeniTakipci - account.followers;
    final String metin = _postText(content, gercekDelta, account.platform);

    return SocialResult(
      state: gercekDelta.abs() >= 1 ? _log(next, metin) : next,
      outcome: SocialOutcome(
        applied: true,
        text: metin,
        effects: diffAppliedEffects(state, next),
        followerDelta: gercekDelta,
      ),
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

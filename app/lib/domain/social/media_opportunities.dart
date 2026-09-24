import '../../data/media_catalog.dart';
import '../../text/turkish_text.dart';
import '../models/applied_effect.dart';
import '../models/game_state.dart';
import '../models/interaction.dart';
import '../models/life_log.dart';
import '../models/social_account.dart';
import '../effects/effect_diff.dart';

/// Bir medya işinin sonucu.
class MediaResult {
  const MediaResult({
    required this.state,
    required this.applied,
    required this.text,
    this.effects = const <AppliedEffect>[],
  });

  final GameState state;
  final bool applied;
  final String text;
  final List<AppliedEffect> effects;
}

/// Ün ve Medya Fırsatları (D-103).
///
/// Ün, kitleden türeyen bir değerdi ama hayatta bir karşılığı yoktu.
/// Faho'nun kararı: **Ün 40**'a gelen oyuncuya medya işleri açılır.
/// Bölüm eşiğin altında **hiç görünmez** (D-038: çalışmayan düğme
/// konmaz).
///
/// Kazançlar uydurulmaz: ücret kataloğun yazdığı tutardır, takipçi
/// kazancı **mevcut** kitlenin oranıdır, Ün kazancı gerçekten uygulanır.
/// Hesabı olmayan oyuncuya takipçi yazılmaz.
abstract final class MediaOpportunities {
  /// Bölüm şu an görünür mü?
  static bool sectionVisible(GameState state) =>
      (state.player.fame ?? 0) >= kMediaSectionMinFame;

  /// Bu iş şu an yapılabilir mi? Yapılamıyorsa **sebebi** yazılır.
  static InteractionAvailability availability(
    GameState state,
    MediaOpportunity job,
  ) {
    final int un = state.player.fame ?? 0;
    if (un < kMediaSectionMinFame) {
      return InteractionAvailability.blocked(
        'Medya fırsatları Ün $kMediaSectionMinFame olunca açılır.',
      );
    }
    if (un < job.minFame) {
      return InteractionAvailability.blocked(
        'Bu iş için Ün ${job.minFame} gerekiyor; senin Ünün $un.',
      );
    }
    if (timesDone(state, job) >= job.maxPerAge) {
      return InteractionAvailability.blocked(
        'Bu işi bu yıl yaptın; gelecek yıl yeniden teklif gelir.',
      );
    }
    return const InteractionAvailability.allowed();
  }

  /// Bu iş bu yaşta kaç kez yapıldı?
  static int timesDone(GameState state, MediaOpportunity job) =>
      state.interactionCount(job.id, 'medya');

  /// İşi kabul eder ve sonucu uygular.
  static MediaResult accept(GameState state, MediaOpportunity job) {
    final InteractionAvailability check = availability(state, job);
    if (!check.isAllowed) {
      return MediaResult(state: state, applied: false, text: check.reason!);
    }

    // Takipçi kazancı **mevcut** kitleden hesaplanır; hesabı olmayana
    // uydurma kitle yazılmaz.
    final int toplamKitle = state.totalFollowers;
    final int kazanilanTakipci = (toplamKitle * job.followerRatio).round();
    final List<SocialAccount> hesaplar = kazanilanTakipci <= 0
        ? state.socialAccounts
        : _spread(state.socialAccounts, kazanilanTakipci);

    final int oncekiUn = state.player.fame ?? 0;

    GameState next = state.copyWith(
      player: state.player.copyWith(
        wallet: state.player.wallet + job.fee,
        fame: (oncekiUn + job.fameGain).clamp(0, 100),
        stats: state.player.stats.gain(
          happiness: job.happiness,
          charisma: job.charisma,
        ),
      ),
      socialAccounts: List<SocialAccount>.unmodifiable(hesaplar),
      interactionCounts: Map<String, int>.unmodifiable(<String, int>{
        ...state.interactionCounts,
        GameState.interactionKey(job.id, 'medya'): timesDone(state, job) + 1,
      }),
    );

    final StringBuffer metin = StringBuffer(
      '${job.label}: iş tamamlandı. ${trMoney(job.fee)} kazandın.',
    );
    if (kazanilanTakipci > 0) {
      metin.write(' ${trNumber(kazanilanTakipci)} yeni takipçi geldi.');
    }

    next = next.copyWith(
      log: List<LifeLogEntry>.unmodifiable(<LifeLogEntry>[
        ...next.log,
        LifeLogEntry(
          age: next.player.age,
          text: metin.toString(),
          category: LogCategory.kisisel,
        ),
      ]),
    );

    return MediaResult(
      state: next,
      applied: true,
      text: metin.toString(),
      effects: diffAppliedEffects(state, next),
    );
  }

  /// Kazanılan takipçiyi açık hesaplara **kitlelerine göre** dağıtır.
  ///
  /// Büyük hesap daha çok pay alır; kalan artık ilk hesaba yazılır ki
  /// toplam tutsun ve tek takipçi kaybolmasın.
  static List<SocialAccount> _spread(
    List<SocialAccount> accounts,
    int total,
  ) {
    if (accounts.isEmpty || total <= 0) return accounts;
    final int toplam = accounts.fold<int>(
      0,
      (int acc, SocialAccount a) => acc + a.followers,
    );
    if (toplam <= 0) {
      // Kitlesi olmayan ama hesabı olan oyuncu: eşit bölüştürülür.
      final int pay = total ~/ accounts.length;
      int kalan = total - pay * accounts.length;
      return <SocialAccount>[
        for (final SocialAccount a in accounts)
          a.copyWith(followers: a.followers + pay + (kalan-- > 0 ? 1 : 0)),
      ];
    }
    final List<SocialAccount> sonuc = <SocialAccount>[];
    int dagitilan = 0;
    for (int i = 0; i < accounts.length; i++) {
      final SocialAccount a = accounts[i];
      final int pay = i == accounts.length - 1
          ? total - dagitilan
          : (total * a.followers / toplam).round();
      dagitilan += pay;
      sonuc.add(a.copyWith(followers: a.followers + pay));
    }
    return sonuc;
  }
}

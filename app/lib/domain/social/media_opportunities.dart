import 'dart:math';

import '../../data/media_catalog.dart';
import '../../text/turkish_text.dart';
import '../models/applied_effect.dart';
import '../models/game_state.dart';
import '../models/interaction.dart';
import '../models/life_log.dart';
import '../generation/random_util.dart';
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
    // Davet gelen işte Ün şartı aranmaz: zaten onlar çağırmıştır (D-120).
    final bool davetli = state.hasMediaInvitation(job.id);
    if (!davetli) {
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
    }
    if (timesDone(state, job) >= job.maxPerAge) {
      return InteractionAvailability.blocked(
        'Bu işi bu yıl denedin; gelecek yıl yeniden bakarsın.',
      );
    }
    // D-147: aynı kapı her yıl çalınmaz. Faho'nun sorusu: "bir fenomen
    // her sene radyo programına vb işlere çağırılıyor mu?"
    final int? sonYapilan = state.mediaJobDoneAt(job.id);
    if (sonYapilan != null &&
        state.player.age - sonYapilan < prototypeOnlyJobCooldownYears) {
      final int kalan =
          prototypeOnlyJobCooldownYears - (state.player.age - sonYapilan);
      return InteractionAvailability.blocked(
        'Bu işi $sonYapilan yaşında yaptın. Aynı kapı her yıl çalınmaz; '
        '$kalan yıl daha beklemen gerekiyor.',
      );
    }
    // D-147: yılda en çok birkaç medya işi. Sekiz iş birden yapılınca
    // hem para hem Ün anlamsız biçimde birikiyordu.
    if (jobsThisAge(state) >= prototypeOnlyMaxJobsPerAge) {
      return InteractionAvailability.blocked(
        'Bu yıl yeterince medya işi yaptın; seneye yeniden açılır.',
      );
    }
    return const InteractionAvailability.allowed();
  }

  /// prototypeOnly: aynı işin tekrarı için beklenmesi gereken yıl (D-147).
  static const int prototypeOnlyJobCooldownYears = 3;

  /// prototypeOnly: bir yılda yapılabilecek **toplam** medya işi (D-147).
  ///
  /// Katalogda sekiz iş var ve her biri yılda bir kez yapılabiliyordu;
  /// yani bir yılda sekiz işin tamamı yapılabiliyor, bu da hem kolay
  /// para hem durmadan yükselen Ün demekti.
  static const int prototypeOnlyMaxJobsPerAge = 2;

  /// Bu yıl toplam kaç medya işine girişildi (kabul + ret)?
  static int jobsThisAge(GameState state) =>
      state.interactionCount(_yearScope, _yearKind);

  static const String _yearScope = 'medya';
  static const String _yearKind = 'yil';

  /// Yıllık sayaca bir giriş ekler.
  static Map<String, int> _countYear(GameState state) =>
      <String, int>{
        ...state.interactionCounts,
        GameState.interactionKey(_yearScope, _yearKind):
            jobsThisAge(state) + 1,
      };

  /// Bu iş bu yaşta kaç kez yapıldı?
  static int timesDone(GameState state, MediaOpportunity job) =>
      state.interactionCount(job.id, 'medya');

  /// prototypeOnly: başvurunun kabul edilme ihtimalinin tabanı (D-120).
  ///
  /// Faho bildirdi: "medya kazançlar gibi tekliflere başvursam bile kabul
  /// edilmeme durumu olsun". Başvurmak almak değildir: eşiği yeni geçen
  /// bir ad için yapım da markası da başka adayları değerlendirir.
  /// **D-147 ile düşürüldü.** Faho bildirdi: "medya fırsatları sürekli
  /// açık olması oradan da çok kolay para spamlanabiliyor... her
  /// seferinde kabul edilmesin". Taban 0,45'ten 0,30'a indi; Ün payı
  /// aynen duruyor, yani tanınmış biri yine de daha kolay kabul edilir.
  static const double prototypeOnlyBaseAcceptChance = 0.30;

  /// prototypeOnly: eşiğin üstündeki her Ün puanının kattığı şans.
  static const double prototypeOnlyAcceptPerFamePoint = 0.02;

  /// prototypeOnly: kabul şansının üst sınırı.
  ///
  /// Hiçbir zaman garanti değildir; çok tanınan biri bile reddedilebilir.
  static const double prototypeOnlyMaxAcceptChance = 0.92;

  /// Başvurunun kabul edilme ihtimali (D-120).
  static double acceptChance(GameState state, MediaOpportunity job) {
    final int un = state.player.fame ?? 0;
    final int fazla = (un - job.minFame).clamp(0, 100);
    return (prototypeOnlyBaseAcceptChance +
            fazla * prototypeOnlyAcceptPerFamePoint)
        .clamp(0.0, prototypeOnlyMaxAcceptChance);
  }

  /// İşe başvurur; kabul edilirse sonucu uygular (D-120).
  ///
  /// Başvuru **reddedilebilir**. Reddedilen başvuru da yıllık hakkı
  /// tüketir: aynı yıl aynı kapıyı tekrar tekrar çalmak mümkün değildir.
  static MediaResult accept(
    GameState state,
    MediaOpportunity job,
    Random rng,
  ) {
    final InteractionAvailability check = availability(state, job);
    if (!check.isAllowed) {
      return MediaResult(state: state, applied: false, text: check.reason!);
    }

    // Davet edilen iş reddedilmez; çağıran taraf zaten karar vermiştir.
    if (!state.hasMediaInvitation(job.id) &&
        !rng.chance(acceptChance(state, job))) {
      final String ret = '${job.label}: başvurun bu kez kabul edilmedi. '
          'Ün arttıkça kabul edilme şansın da artar '
          '(şu an Ün ${state.player.fame ?? 0}).';
      final GameState red = state.copyWith(
        player: state.player.copyWith(
          stats: state.player.stats.gain(happiness: -2),
        ),
        interactionCounts: Map<String, int>.unmodifiable(<String, int>{
          ..._countYear(state),
          GameState.interactionKey(job.id, 'medya'): timesDone(state, job) + 1,
        }),
        log: List<LifeLogEntry>.unmodifiable(<LifeLogEntry>[
          ...state.log,
          LifeLogEntry(
            age: state.player.age,
            text: ret,
            category: LogCategory.kisisel,
          ),
        ]),
      );
      return MediaResult(state: red, applied: true, text: ret);
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
        ..._countYear(state),
        GameState.interactionKey(job.id, 'medya'): timesDone(state, job) + 1,
      }),
      // D-147: aynı işin tekrarı için bekleme süresi buradan ölçülür.
      mediaJobLastAge: <String, int>{
        ...state.mediaJobLastAge,
        job.id: state.player.age,
      },
      // Davet kullanıldı; bir kez geçerlidir.
      mediaInvitationId: null,
      mediaInvitationAge: null,
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

  /// prototypeOnly: bir yılda kendiliğinden davet gelme ihtimali (D-120).
  static const double prototypeOnlyInvitationChance = 0.22;

  /// Kendiliğinden gelen medya daveti üretir; koşul yoksa `null` (D-120).
  ///
  /// Davet, oyuncunun Ününe **yakın** işlerden seçilir: Ünün çok
  /// üstündeki bir program kimseyi durup dururken çağırmaz. Davet edilen
  /// iş için Ün şartı aranmaz ve başvuru reddedilmez.
  static MediaOpportunity? maybeInvitation(GameState state, Random rng) {
    final int un = state.player.fame ?? 0;
    if (un < kMediaSectionMinFame) return null;
    if (state.mediaInvitationId != null) return null;
    if (!rng.chance(prototypeOnlyInvitationChance)) return null;

    // Ünün en çok 15 puan üstündeki işler davet edebilir.
    final List<MediaOpportunity> adaylar = <MediaOpportunity>[
      for (final MediaOpportunity j in kMediaOpportunities)
        if (j.minFame <= un + 15 && timesDone(state, j) < j.maxPerAge) j,
    ];
    if (adaylar.isEmpty) return null;
    return adaylar[rng.nextInt(adaylar.length)];
  }
}

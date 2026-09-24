import 'dart:math';

import '../../data/job_catalog.dart';
import '../life/sick_leave.dart';
import '../../text/turkish_text.dart';
import '../models/career.dart';
import '../models/game_state.dart';
import '../models/interaction.dart';
import '../models/life_log.dart';

/// Bir zam/terfi talebinin sonucu.
class CareerRequestResult {
  const CareerRequestResult({
    required this.state,
    required this.text,
    this.accepted = false,
    this.applied = false,
  });

  final GameState state;
  final String text;

  /// Talep kabul edildi mi?
  final bool accepted;

  /// Talep gerçekten değerlendirildi mi? (Engellendiyse `false`.)
  final bool applied;
}

/// Meslekte ilerleme: zam, terfi ve işten çıkarılma.
///
/// Terfi **otomatik ve garanti değildir**: işte geçirilen süre, oyuncunun
/// değerleri ve iş hayatında verdiği kararlar kabul ihtimalini etkiler.
/// Buradaki sayıların tamamı `prototypeOnly`'dir (Q-078); denge
/// kararlaştırılmadı.
abstract final class CareerProgress {
  /// prototypeOnly: zam istemek için işte geçmesi gereken en az yıl.
  static const int prototypeOnlyMinYearsForRaise = 1;

  /// prototypeOnly: iki zam arasında geçmesi gereken yıl.
  static const int prototypeOnlyRaiseCooldown = 2;

  /// prototypeOnly: terfi için işte geçmesi gereken en az yıl.
  static const int prototypeOnlyMinYearsForPromotion = 3;

  /// prototypeOnly: iki terfi arasında geçmesi gereken yıl.
  static const int prototypeOnlyPromotionCooldown = 4;

  /// prototypeOnly: kabul edilen zammın maaşa eklediği oran.
  static const double prototypeOnlyRaiseRatio = 0.08;

  /// prototypeOnly: terfinin maaşa eklediği oran.
  static const double prototypeOnlyPromotionRatio = 0.22;

  /// prototypeOnly: zam talebinin taban kabul ihtimali.
  static const double prototypeOnlyRaiseBaseChance = 0.35;

  /// prototypeOnly: terfi talebinin taban kabul ihtimali.
  static const double prototypeOnlyPromotionBaseChance = 0.25;

  /// prototypeOnly: işte geçen her yılın eklediği pay.
  static const double prototypeOnlyYearBonus = 0.05;

  /// prototypeOnly: yüksek zekâ/karizmanın eklediği en fazla pay.
  static const double prototypeOnlyStatBonus = 0.25;

  /// prototypeOnly: iş hayatında sorumluluk almanın eklediği pay.
  static const double prototypeOnlyRecordBonus = 0.12;

  /// prototypeOnly: iş hayatında bırakılan kötü izin düşürdüğü pay.
  static const double prototypeOnlyBadRecordPenalty = 0.15;

  /// prototypeOnly: kabul ihtimalinin alt ve üst sınırı.
  ///
  /// Hiçbir talep garanti değildir; hiçbir talep de tamamen imkânsız
  /// olmaz.
  static const double prototypeOnlyMinChance = 0.05;
  static const double prototypeOnlyMaxChance = 0.85;

  /// prototypeOnly: reddedilen talebin mutluluk etkisi.
  static const int prototypeOnlyRejectHappiness = -4;

  /// prototypeOnly: kabul edilen talebin mutluluk etkisi.
  static const int prototypeOnlyAcceptHappiness = 6;

  /// prototypeOnly: bir yılda işten çıkarılma ihtimali.
  static const double prototypeOnlyLayoffChance = 0.035;

  /// prototypeOnly: işten çıkarılma için işte geçmesi gereken en az yıl.
  static const int prototypeOnlyLayoffMinYears = 2;

  /// prototypeOnly: iki işten çıkarılma arasında geçmesi gereken yıl.
  ///
  /// Oyuncuyu her yıl işsiz bırakan bir döngü olmasın diye uzun tutulur.
  static const int prototypeOnlyLayoffCooldown = 8;

  /// İş hayatında bırakılan izler (olaylarla kazanılır).
  static const String flagSorumlulukAldi = 'iste_sorumluluk_aldi';
  static const String flagIsiSavsakladi = 'isi_savsakladi';

  /// Talep sayaçlarının anahtarı (yaş başına bir kez).
  static const String raiseKey = 'zam_talebi';
  static const String promotionKey = 'terfi_talebi';

  // -------------------------------------------------------------------
  // Uygunluk
  // -------------------------------------------------------------------

  /// Zam istenebilir mi?
  static InteractionAvailability raiseAvailability(GameState state) {
    final CareerState career = state.career;
    if (!career.isEmployed) {
      return const InteractionAvailability.blocked('Şu an bir işin yok.');
    }
    if (state.interactionCount(raiseKey, 'kariyer') > 0) {
      return const InteractionAvailability.blocked(
        'Bu yıl zaten konuştun; seneye yeniden isteyebilirsin.',
      );
    }
    final int yil = career.yearsInJob(state.player.age);
    if (yil < prototypeOnlyMinYearsForRaise) {
      return const InteractionAvailability.blocked(
        'Daha yeni başladın; en az bir yıl çalışman gerekiyor.',
      );
    }
    final int? sonZam = career.lastRaiseAge;
    if (sonZam != null &&
        state.player.age - sonZam < prototypeOnlyRaiseCooldown) {
      return InteractionAvailability.blocked(
        'Son zammın üzerinden daha $prototypeOnlyRaiseCooldown yıl geçmedi.',
      );
    }
    return const InteractionAvailability.allowed();
  }

  /// Terfi istenebilir mi?
  static InteractionAvailability promotionAvailability(GameState state) {
    final CareerState career = state.career;
    final JobType? job = career.job;
    if (job == null) {
      return const InteractionAvailability.blocked('Şu an bir işin yok.');
    }
    if (career.level >= job.maxLevel) {
      return const InteractionAvailability.blocked(
        'Bu işte çıkabileceğin en üst görevdesin.',
      );
    }
    if (state.interactionCount(promotionKey, 'kariyer') > 0) {
      return const InteractionAvailability.blocked(
        'Bu yıl zaten konuştun; seneye yeniden isteyebilirsin.',
      );
    }
    final int yil = career.yearsInJob(state.player.age);
    if (yil < prototypeOnlyMinYearsForPromotion) {
      return InteractionAvailability.blocked(
        'Terfi konuşmak için en az $prototypeOnlyMinYearsForPromotion yıl '
        'çalışmış olman bekleniyor.',
      );
    }
    final int? sonTerfi = career.lastPromotionAge;
    if (sonTerfi != null &&
        state.player.age - sonTerfi < prototypeOnlyPromotionCooldown) {
      return InteractionAvailability.blocked(
        'Son terfinin üzerinden daha $prototypeOnlyPromotionCooldown yıl '
        'geçmedi.',
      );
    }
    return const InteractionAvailability.allowed();
  }

  // -------------------------------------------------------------------
  // Kabul ihtimali
  // -------------------------------------------------------------------

  /// prototypeOnly: talebin kabul edilme ihtimali.
  ///
  /// İşte geçen süre, zekâ/karizma ve iş hayatında bırakılan izler etkili
  /// olur. Sonuç asla 0 veya 1 değildir.
  static double prototypeOnlyChance(GameState state, {required bool terfi}) {
    final CareerState career = state.career;
    final int yil = career.yearsInJob(state.player.age);
    double sans =
        terfi ? prototypeOnlyPromotionBaseChance : prototypeOnlyRaiseBaseChance;
    sans += yil * prototypeOnlyYearBonus;

    // Zekâ ve karizmanın ortalaması: iş yerinde hem işini bilmek hem
    // derdini anlatabilmek işe yarar.
    final double ortalama =
        (state.player.stats.intelligence + state.player.stats.charisma) / 2;
    sans += (ortalama / 100) * prototypeOnlyStatBonus;

    // Geçmiş kararlar hatırlanır (D-008).
    if (state.storyFlags.contains(flagSorumlulukAldi)) {
      sans += prototypeOnlyRecordBonus;
    }
    if (state.storyFlags.contains(flagIsiSavsakladi)) {
      sans -= prototypeOnlyBadRecordPenalty;
    }

    // Üst basamaklarda terfi zorlaşır.
    sans -= career.level * 0.08;

    return sans.clamp(prototypeOnlyMinChance, prototypeOnlyMaxChance);
  }

  // -------------------------------------------------------------------
  // Talepler
  // -------------------------------------------------------------------

  /// Zam ister. Aynı yıl ikinci kez istenemez.
  static CareerRequestResult askForRaise(GameState state, Random rng) {
    final InteractionAvailability uygunluk = raiseAvailability(state);
    if (!uygunluk.isAllowed) {
      return CareerRequestResult(state: state, text: uygunluk.reason!);
    }

    final GameState sayilmis = _countRequest(state, raiseKey);
    final bool kabul = rng.nextDouble() < prototypeOnlyChance(
          state,
          terfi: false,
        );
    final int age = state.player.age;
    final String unvan = state.career.title;

    if (!kabul) {
      const String metin = 'Yöneticin bu yıl bütçenin dar olduğunu söyledi. '
          '"Seneye yeniden konuşalım" dedi.';
      return CareerRequestResult(
        state: _log(
          _happiness(sayilmis, prototypeOnlyRejectHappiness).copyWith(
            career: sayilmis.career
                .withMilestone(age, 'Zam istedin; bu yıl olmadı.'),
          ),
          'Zam istedin, olumsuz yanıt aldın.',
        ),
        text: metin,
        applied: true,
      );
    }

    final int eski = state.career.yearlySalary;
    final int yeni = (eski * (1 + prototypeOnlyRaiseRatio)).round();
    final int fark = yeni - eski;
    final String metin = 'Zam isteğin kabul edildi. Yıllık maaşın '
        '${trMoney(yeni)} oldu (+${trMoney(fark)}).';
    return CareerRequestResult(
      state: _log(
        _happiness(sayilmis, prototypeOnlyAcceptHappiness).copyWith(
          career: sayilmis.career
              .copyWith(salary: yeni, lastRaiseAge: age)
              .withMilestone(age, '$unvan olarak zam aldın: ${trMoney(yeni)}.'),
        ),
        metin,
      ),
      text: metin,
      accepted: true,
      applied: true,
    );
  }

  /// Terfi ister. Aynı yıl ikinci kez istenemez.
  static CareerRequestResult askForPromotion(GameState state, Random rng) {
    final InteractionAvailability uygunluk = promotionAvailability(state);
    if (!uygunluk.isAllowed) {
      return CareerRequestResult(state: state, text: uygunluk.reason!);
    }

    final GameState sayilmis = _countRequest(state, promotionKey);
    final bool kabul = rng.nextDouble() < prototypeOnlyChance(
          state,
          terfi: true,
        );
    final int age = state.player.age;

    if (!kabul) {
      const String metin = 'Yöneticin "şu an kadro açmıyoruz" dedi. '
          'Yaptığın işi gördüğünü ama zamanlamanın uygun olmadığını ekledi.';
      return CareerRequestResult(
        state: _log(
          _happiness(sayilmis, prototypeOnlyRejectHappiness).copyWith(
            career: sayilmis.career
                .withMilestone(age, 'Terfi istedin; kadro açılmadı.'),
          ),
          'Terfi istedin, bu yıl olmadı.',
        ),
        text: metin,
        applied: true,
      );
    }

    final JobType job = state.career.job!;
    final int yeniSeviye = (state.career.level + 1).clamp(0, job.maxLevel);
    final int eski = state.career.yearlySalary;
    final int yeni = (eski * (1 + prototypeOnlyPromotionRatio)).round();
    final String unvan = jobTitleFor(job, yeniSeviye);
    final String metin = 'Terfi ettin: artık $unvan olarak çalışıyorsun. '
        'Yıllık maaşın ${trMoney(yeni)}.';

    return CareerRequestResult(
      state: _log(
        _happiness(sayilmis, prototypeOnlyAcceptHappiness).copyWith(
          career: sayilmis.career
              .copyWith(
                level: yeniSeviye,
                salary: yeni,
                lastPromotionAge: age,
                lastRaiseAge: age,
              )
              .withMilestone(age, '$unvan oldun.'),
        ),
        metin,
      ),
      text: metin,
      accepted: true,
      applied: true,
    );
  }

  // -------------------------------------------------------------------
  // İşten çıkarılma
  // -------------------------------------------------------------------

  /// Yeni yaşa geçerken işten çıkarılma denemesi.
  ///
  /// Sürekli tekrarlanan bir çaresizlik döngüsü olmaması için: işe yeni
  /// girmiş biri çıkarılmaz, iki işten çıkarılma arasında uzun bir süre
  /// vardır ve ihtimal düşüktür. Eski iş kaydı **silinmez**.
  static ({GameState state, String? logText}) maybeLayoff(
    GameState state,
    int newAge,
    Random rng,
  ) {
    final CareerState career = state.career;
    final JobType? job = career.job;
    if (job == null) return (state: state, logText: null);
    if (career.yearsInJob(newAge) < prototypeOnlyLayoffMinYears) {
      return (state: state, logText: null);
    }
    final int? sonKayip = career.lastJobLossAge;
    if (sonKayip != null &&
        newAge - sonKayip < prototypeOnlyLayoffCooldown) {
      return (state: state, logText: null);
    }
    // İşveren uyarıları ihtimali artırır ama tek başına kimseyi atmaz
    // (D-078).
    final double sans =
        prototypeOnlyLayoffChance + SickLeaves.layoffBonus(career.employerWarnings);
    if (!(rng.nextDouble() < sans)) {
      return (state: state, logText: null);
    }

    final String unvan = career.title;
    final CareerState kapali = career
        .withMilestone(newAge, 'İşten çıkarıldın.')
        .closeCurrentJob(endedAtAge: newAge, reason: JobEndReason.cikarildi)
        .copyWith(lastJobLossAge: newAge);

    return (
      state: state.copyWith(career: kapali),
      logText: '$unvan olarak çalıştığın iş yerinde küçülmeye gidildi; '
          'işine son verildi. Kariyer geçmişin duruyor.',
    );
  }

  // -------------------------------------------------------------------
  // Yardımcılar
  // -------------------------------------------------------------------

  static GameState _countRequest(GameState state, String key) {
    final Map<String, int> counts = <String, int>{
      ...state.interactionCounts,
      GameState.interactionKey(key, 'kariyer'):
          state.interactionCount(key, 'kariyer') + 1,
    };
    return state.copyWith(
      interactionCounts: Map<String, int>.unmodifiable(counts),
    );
  }

  /// Mutluluğu **gerçekten uygulanabilecek kadar** değiştirir.
  static GameState _happiness(GameState state, int delta) => state.copyWith(
        player: state.player.copyWith(
          stats: state.player.stats.copyWith(
            happiness: state.player.stats.happiness + delta,
          ),
        ),
      );

  static GameState _log(GameState state, String text) => state.copyWith(
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

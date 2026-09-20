import 'dart:math';

import '../../data/job_catalog.dart';
import '../models/career.dart';
import '../models/education.dart';
import '../models/game_state.dart';
import '../models/interaction.dart';
import '../models/life_log.dart';

class JobOutcome {
  const JobOutcome({
    required this.applied,
    required this.text,
    this.accepted = false,
  });

  final bool applied;
  final String text;
  final bool accepted;
}

class JobResult {
  const JobResult({required this.state, required this.outcome});

  final GameState state;
  final JobOutcome outcome;
}

/// İş arama, işe kabul, işten ayrılma ve maaş ödemesi.
///
/// Eğitim tek başına **otomatik kabul garantisi değildir**: koşullar
/// sağlansa bile başvuru reddedilebilir. Sayılar `prototypeOnly`'dir
/// (`docs/DESIGN_REVIEW_QUEUE.md`, Q-048).
class JobMarket {
  const JobMarket();

  /// prototypeOnly: koşulları sağlayan bir başvurunun taban kabul olasılığı.
  static const double prototypeOnlyBaseChance = 0.5;

  /// prototypeOnly: uygun eğitim geçmişinin eklediği pay.
  static const double prototypeOnlyEducationBonus = 0.25;

  /// prototypeOnly: yüksek zekâ/karizmanın eklediği pay.
  static const double prototypeOnlyStatBonus = 0.15;

  /// prototypeOnly: en yüksek kabul olasılığı; iş asla garanti değildir.
  static const double prototypeOnlyMaxChance = 0.9;

  /// prototypeOnly: bir yaşta aynı işe yapılabilecek en fazla başvuru.
  static const int prototypeOnlyMaxApplicationsPerAge = 3;

  /// Oyuncunun **başvurabileceği** işler.
  ///
  /// Koşulu sağlanmayan iş listelenmez; sahte düğme gösterilmez.
  List<JobType> openJobs(GameState state) => kJobCatalog
      .where((JobType job) => meetsRequirements(state, job))
      .toList(growable: false);

  /// Koşulları sağlanmayan işler ve gerekçeleri (bilgilendirme için).
  Map<JobType, String> lockedJobs(GameState state) => <JobType, String>{
        for (final JobType job in kJobCatalog)
          if (!meetsRequirements(state, job)) job: requirementReason(state, job),
      };

  bool meetsRequirements(GameState state, JobType job) =>
      requirementReason(state, job).isEmpty;

  /// İşin neden açık olmadığını açıklar; uygunsa boş metin döner.
  String requirementReason(GameState state, JobType job) {
    final EducationState egitim = state.education;
    if (state.player.age < job.minAge) {
      return '${job.minAge} yaşından itibaren başvurulabilir.';
    }
    if (egitim.isSchoolStudent) {
      return 'Okula devam ederken tam zamanlı işe başvurulmaz.';
    }
    switch (job.education) {
      case JobEducation.yok:
        break;
      case JobEducation.lise:
        if (!egitim.finished) return 'Lise mezuniyeti gerekiyor.';
      case JobEducation.universite:
        if (!egitim.universityFinished) {
          return 'Üniversite mezuniyeti gerekiyor.';
        }
    }
    if (job.tracks.isNotEmpty || job.programs.isNotEmpty) {
      final bool alanUygun =
          egitim.track != null && job.tracks.contains(egitim.track);
      final bool bolumUygun = egitim.universityFinished &&
          egitim.universityProgramId != null &&
          job.programs.contains(egitim.universityProgramId);
      if (!alanUygun && !bolumUygun) {
        return 'Bu iş için uygun bir eğitim geçmişi gerekiyor.';
      }
    }
    if (state.player.stats.intelligence < job.minIntelligence) {
      return 'Bu iş için zekân yeterli görülmüyor.';
    }
    if (state.player.stats.charisma < job.minCharisma) {
      return 'Bu iş için karizman yeterli görülmüyor.';
    }
    return '';
  }

  InteractionAvailability applicationAvailability(
    GameState state,
    JobType job,
  ) {
    if (state.career.isEmployed) {
      return const InteractionAvailability.blocked(
        'Önce mevcut işinden ayrılman gerekiyor.',
      );
    }
    final String reason = requirementReason(state, job);
    if (reason.isNotEmpty) return InteractionAvailability.blocked(reason);
    if (_applicationsThisAge(state, job) >= prototypeOnlyMaxApplicationsPerAge) {
      return const InteractionAvailability.blocked(
        'Bu yıl bu işe yeterince başvurdun; seneye tekrar dene.',
      );
    }
    return const InteractionAvailability.allowed();
  }

  int _applicationsThisAge(GameState state, JobType job) =>
      state.interactionCount(job.id, 'isBasvurusu');

  /// Kabul olasılığı: koşullar sağlansa bile 1.0 değildir.
  double acceptanceChance(GameState state, JobType job) {
    double sans = prototypeOnlyBaseChance;
    final EducationState egitim = state.education;
    if (egitim.track != null && job.tracks.contains(egitim.track)) {
      sans += prototypeOnlyEducationBonus;
    }
    if (egitim.universityFinished &&
        job.programs.contains(egitim.universityProgramId)) {
      sans += prototypeOnlyEducationBonus;
    }
    if (state.player.stats.intelligence >= job.minIntelligence + 15) {
      sans += prototypeOnlyStatBonus;
    }
    if (state.player.stats.charisma >= job.minCharisma + 15) {
      sans += prototypeOnlyStatBonus / 2;
    }
    return sans.clamp(0.05, prototypeOnlyMaxChance);
  }

  /// İşe başvurur.
  JobResult apply(GameState state, JobType job, Random rng) {
    final InteractionAvailability check = applicationAvailability(state, job);
    if (!check.isAllowed) return _blocked(state, check.reason!);

    // Başvuru sayacı her durumda artar: tekrar istismarı engellenir.
    final Map<String, int> counts = <String, int>{
      ...state.interactionCounts,
      GameState.interactionKey(job.id, 'isBasvurusu'):
          _applicationsThisAge(state, job) + 1,
    };
    final GameState basvurulmus = state.copyWith(
      interactionCounts: Map<String, int>.unmodifiable(counts),
    );

    if (rng.nextDouble() >= acceptanceChance(state, job)) {
      final String metin = '${job.name} başvurun olumsuz sonuçlandı. '
          '"Şimdilik uygun bir pozisyonumuz yok" dediler.';
      return JobResult(
        state: _log(basvurulmus, metin),
        outcome: JobOutcome(applied: true, text: metin),
      );
    }

    final String metin = '${job.name} olarak işe alındın. '
        'İlk maaşın bir yıl sonra cebinde olacak.';
    return JobResult(
      state: _log(
        basvurulmus.copyWith(
          career: basvurulmus.career.copyWith(
            jobId: job.id,
            startedAtAge: basvurulmus.player.age,
            // İşe girilen yıl için maaş ödenmez; ilk ödeme sonraki yaşta.
            lastPaidAge: basvurulmus.player.age,
          ),
        ),
        metin,
      ),
      outcome: JobOutcome(applied: true, text: metin, accepted: true),
    );
  }

  /// İşten ayrılır. İş geçmişi silinmez.
  JobResult quit(GameState state) {
    final CareerState career = state.career;
    final JobType? job = career.job;
    if (job == null) return _blocked(state, 'Şu an bir işin yok.');

    final String metin = '${job.name} işinden ayrıldın.';
    return JobResult(
      state: _log(
        state.copyWith(
          career: career.copyWith(
            jobId: null,
            startedAtAge: null,
            pastJobIds: List<String>.unmodifiable(
              <String>[...career.pastJobIds, job.id],
            ),
          ),
        ),
        metin,
      ),
      outcome: JobOutcome(applied: true, text: metin, accepted: true),
    );
  }

  /// Yeni yaşa geçerken maaşı **bir kez** öder.
  ///
  /// [CareerState.lastPaidAge] aynı dönemin ikinci kez ödenmesini engeller.
  ({GameState state, String? logText}) paySalaryFor(
    GameState state,
    int newAge,
  ) {
    final JobType? job = state.career.job;
    if (job == null) return (state: state, logText: null);
    final int? sonOdeme = state.career.lastPaidAge;
    if (sonOdeme != null && sonOdeme >= newAge) {
      return (state: state, logText: null);
    }

    return (
      state: state.copyWith(
        player: state.player.copyWith(
          wallet: state.player.wallet + job.yearlySalary,
        ),
        career: state.career.copyWith(lastPaidAge: newAge),
      ),
      logText: '${job.name} olarak bir yılın doldu; '
          '${job.yearlySalary} ₺ cüzdanına girdi.',
    );
  }

  JobResult _blocked(GameState state, String reason) => JobResult(
        state: state,
        outcome: JobOutcome(applied: false, text: reason),
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

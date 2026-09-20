import 'dart:math';

import '../../data/interview_catalog.dart';
import '../../data/job_catalog.dart';
import '../models/career.dart';
import '../models/education.dart';
import '../models/game_state.dart';
import '../models/interaction.dart';
import '../models/life_log.dart';
import '../models/pending_interview.dart';

class JobOutcome {
  const JobOutcome({
    required this.applied,
    required this.text,
    this.accepted = false,
    this.interviewStarted = false,
    this.correctAnswer,
    this.explanation,
  });

  final bool applied;
  final String text;

  /// İşe kabul edildi mi?
  final bool accepted;

  /// Başvuru bir mülakat açtı mı?
  final bool interviewStarted;

  /// Yanlış cevaptan sonra gösterilen doğru seçenek.
  final String? correctAnswer;

  /// Doğru cevabın kısa açıklaması.
  final String? explanation;
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
  ///
  /// Mülakat sorularının ezberlenip tekrar denenmesini sınırlar.
  static const int prototypeOnlyMaxApplicationsPerAge = 2;

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
    if (state.hasPendingInterview) {
      return const InteractionAvailability.blocked(
        'Devam eden bir mülakatın var.',
      );
    }
    if (questionsForJob(job.id).isEmpty) {
      return const InteractionAvailability.blocked(
        'Bu iş için mülakat soruları henüz yazılmadı.',
      );
    }
    return const InteractionAvailability.allowed();
  }

  int _applicationsThisAge(GameState state, JobType job) =>
      state.interactionCount(job.id, 'isBasvurusu');

  /// Bu yaşta bu soru kaç kez soruldu?
  int _questionAskedThisAge(GameState state, InterviewQuestion q) =>
      state.interactionCount(q.id, 'mulakat');

  /// Mülakat sorusu seçer.
  ///
  /// Aynı yaşta daha önce sorulmamış bir soru varsa o tercih edilir;
  /// böylece tekrar başvuruda aynı soru ezberlenmez.
  InterviewQuestion _pickQuestion(
    GameState state,
    JobType job,
    Random rng,
  ) {
    final List<InterviewQuestion> hepsi = questionsForJob(job.id);
    final List<InterviewQuestion> sorulmamis = hepsi
        .where((InterviewQuestion q) => _questionAskedThisAge(state, q) == 0)
        .toList(growable: false);
    final List<InterviewQuestion> havuz =
        sorulmamis.isEmpty ? hepsi : sorulmamis;
    return havuz[rng.nextInt(havuz.length)];
  }

  /// İşe başvurur ve **mülakatı açar**.
  ///
  /// Başvuru doğrudan kabul/ret ile sonuçlanmaz: önce mesleğe uygun kısa
  /// bir soru sorulur. Başvuru sayacı burada artar, böylece mülakatı yarıda
  /// bırakmak sınırı aşmaya yaramaz.
  JobResult apply(GameState state, JobType job, Random rng) {
    final InteractionAvailability check = applicationAvailability(state, job);
    if (!check.isAllowed) return _blocked(state, check.reason!);

    final InterviewQuestion soru = _pickQuestion(state, job, rng);
    final Map<String, int> counts = <String, int>{
      ...state.interactionCounts,
      GameState.interactionKey(job.id, 'isBasvurusu'):
          _applicationsThisAge(state, job) + 1,
      GameState.interactionKey(soru.id, 'mulakat'):
          _questionAskedThisAge(state, soru) + 1,
    };

    final String metin = '${job.name} için mülakata çağrıldın.';
    return JobResult(
      state: state.copyWith(
        interactionCounts: Map<String, int>.unmodifiable(counts),
        pendingInterview: PendingInterview(
          jobId: job.id,
          questionId: soru.id,
          askedAtAge: state.player.age,
        ),
      ),
      outcome: JobOutcome(
        applied: true,
        text: metin,
        interviewStarted: true,
      ),
    );
  }

  /// Mülakat sorusunu cevaplar.
  ///
  /// Doğru cevap **ve** başvuru koşulları birlikte aranır: mülakatı doğru
  /// cevaplamak, gerekli eğitimi olmayan birini uzman mesleğe sokmaz.
  /// Cevap verildikten sonra mülakat kapanır; ikinci kez uygulanamaz.
  JobResult answerInterview(GameState state, int optionIndex) {
    final PendingInterview? mulakat = state.pendingInterview;
    if (mulakat == null) {
      return _blocked(state, 'Devam eden bir mülakat yok.');
    }
    final JobType? job = mulakat.job;
    final InterviewQuestion? soru = mulakat.question;
    if (job == null || soru == null) {
      // Kayıt bozulmuş olabilir; mülakat kapatılır, iş verilmez.
      return JobResult(
        state: state.copyWith(pendingInterview: null),
        outcome: const JobOutcome(
          applied: true,
          text: 'Mülakat kaydı okunamadı, görüşme iptal edildi.',
        ),
      );
    }
    if (optionIndex < 0 || optionIndex >= soru.options.length) {
      return _blocked(state, 'Geçersiz seçenek.');
    }

    final GameState kapali = state.copyWith(pendingInterview: null);
    final bool dogru = optionIndex == soru.correctIndex;

    // Koşullar cevap anında yeniden denetlenir.
    final String engel = requirementReason(state, job);
    if (engel.isNotEmpty || state.career.isEmployed) {
      final String metin = '${job.name} başvurun sonuçlanmadı: '
          '${state.career.isEmployed ? 'Zaten bir işin var.' : engel}';
      return JobResult(
        state: _log(kapali, metin),
        outcome: JobOutcome(applied: true, text: metin),
      );
    }

    if (!dogru) {
      final String metin = '${job.name} mülakatı olumsuz sonuçlandı. '
          '"Teşekkür ederiz, sizi arayacağız" dediler.';
      return JobResult(
        state: _log(kapali, metin),
        outcome: JobOutcome(
          applied: true,
          text: metin,
          correctAnswer: soru.correctOption,
          explanation: soru.explanation,
        ),
      );
    }

    final String metin = '${job.name} olarak işe alındın. '
        'İlk maaşın bir yıl sonra cebinde olacak.';
    return JobResult(
      state: _log(
        kapali.copyWith(
          career: kapali.career.copyWith(
            jobId: job.id,
            startedAtAge: kapali.player.age,
            // İşe girilen yıl için maaş ödenmez; ilk ödeme sonraki yaşta.
            lastPaidAge: kapali.player.age,
          ),
        ),
        metin,
      ),
      outcome: JobOutcome(applied: true, text: metin, accepted: true),
    );
  }

  /// Mülakatı yarıda bırakır. Başvuru hakkı harcanmış sayılır.
  JobResult cancelInterview(GameState state) {
    if (!state.hasPendingInterview) {
      return _blocked(state, 'Devam eden bir mülakat yok.');
    }
    const String metin = 'Mülakattan vazgeçtin.';
    return JobResult(
      state: _log(state.copyWith(pendingInterview: null), metin),
      outcome: const JobOutcome(applied: true, text: metin),
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

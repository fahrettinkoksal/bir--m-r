import 'dart:math';

import '../../data/license_catalog.dart';
import '../../data/license_questions.dart';
import '../models/game_state.dart';
import '../models/interaction.dart';
import '../models/life_log.dart';
import '../models/pending_license_exam.dart';

/// Ehliyet başvurusunun sonucu.
/// Sınav bittiğinde gösterilen tek soruluk değerlendirme.
class ExamAnswerReview {
  const ExamAnswerReview({required this.question, required this.givenIndex});

  final LicenseQuestion question;

  /// Oyuncunun seçtiği şık.
  final int givenIndex;

  bool get isCorrect => givenIndex == question.correctIndex;

  String get givenOption => question.options[givenIndex];

  String get correctOption => question.correctOption;
}

class LicenseOutcome {
  const LicenseOutcome({
    required this.applied,
    required this.text,
    this.examStarted = false,
    this.granted = false,
    this.correctCount = 0,
    this.questionCount = 0,
    this.answeredCount = 0,
    this.review = const <ExamAnswerReview>[],
  });

  final bool applied;
  final String text;

  /// Başvuru sınavı açtı mı?
  final bool examStarted;

  /// Ehliyet verildi mi?
  final bool granted;

  /// Doğru cevap sayısı (sınav bittiğinde).
  final int correctCount;

  /// Sınavdaki toplam soru sayısı.
  final int questionCount;

  /// Şu ana kadar cevaplanan soru sayısı.
  final int answeredCount;

  /// Sınav bittiğinde bütün soruların doğru cevabı ve açıklaması.
  final List<ExamAnswerReview> review;
}

class LicenseResult {
  const LicenseResult({required this.state, required this.outcome});

  final GameState state;
  final LicenseOutcome outcome;
}

/// Ehliyet işlemleri: başvuru, sınav ve kalıcı ehliyet kaydı.
///
/// İki ehliyet birbirinden bağımsızdır; biri diğerini vermez. Sayısal
/// değerler `prototypeOnly`'dir (`docs/DESIGN_REVIEW_QUEUE.md`, Q-057).
class LicenseOffice {
  const LicenseOffice();

  /// Sınavdaki soru sayısı (D-035).
  static const int questionsPerExam = 3;

  /// Sınavı geçmek için gereken en az doğru sayısı (D-035).
  static const int passingCorrectAnswers = 2;

  /// prototypeOnly: bir yaşta aynı ehliyete yapılabilecek en fazla başvuru.
  ///
  /// Her başvuruda ücret yeniden alınır; soru ezberlenerek sınırsız
  /// denenemez.
  static const int prototypeOnlyMaxAttemptsPerAge = 2;

  static const String _interactionKind = 'ehliyet';
  static const String _questionKind = 'ehliyetSorusu';

  /// Başvuru şu an mümkün mü?
  InteractionAvailability applicationAvailability(
    GameState state,
    LicenseType type,
  ) {
    if (state.hasLicense(type.id)) {
      return InteractionAvailability.blocked(
        '${type.label} zaten sende.',
      );
    }
    if (state.player.age < type.prototypeOnlyMinAge) {
      return InteractionAvailability.blocked(
        '${type.label} için en az ${type.prototypeOnlyMinAge} yaşında '
        'olman gerekiyor.',
      );
    }
    if (state.pendingLicenseExam != null) {
      return const InteractionAvailability.blocked(
        'Devam eden bir ehliyet sınavın var.',
      );
    }
    if (_attemptsThisAge(state, type) >= prototypeOnlyMaxAttemptsPerAge) {
      return const InteractionAvailability.blocked(
        'Bu yıl bu ehliyet için yeterince denedin; seneye tekrar dene.',
      );
    }
    final int ucret = prototypeOnlyExamFee(type);
    if (state.player.wallet < ucret) {
      return InteractionAvailability.blocked(
        'Sınav ücreti $ucret ₺; cüzdanında yeterli para yok.',
      );
    }
    if (questionsForLicense(type.id).length < questionsPerExam) {
      return const InteractionAvailability.blocked(
        'Bu ehliyet için yeterli sınav sorusu henüz yazılmadı.',
      );
    }
    return const InteractionAvailability.allowed();
  }

  int _attemptsThisAge(GameState state, LicenseType type) =>
      state.interactionCount(type.id, _interactionKind);

  int _questionAskedThisAge(GameState state, LicenseQuestion q) =>
      state.interactionCount(q.id, _questionKind);

  /// Sınavın [questionsPerExam] sorusunu seçer.
  ///
  /// Aynı yaşta daha önce sorulmamış sorular tercih edilir; aynı sınavda
  /// bir soru iki kez sorulmaz.
  List<LicenseQuestion> _pickQuestions(
    GameState state,
    LicenseType type,
    Random rng,
  ) {
    final List<LicenseQuestion> hepsi = questionsForLicense(type.id);
    final List<LicenseQuestion> sorulmamis = <LicenseQuestion>[
      for (final LicenseQuestion q in hepsi)
        if (_questionAskedThisAge(state, q) == 0) q,
    ]..shuffle(rng);
    final List<LicenseQuestion> kalan = <LicenseQuestion>[
      for (final LicenseQuestion q in hepsi)
        if (_questionAskedThisAge(state, q) > 0) q,
    ]..shuffle(rng);

    final List<LicenseQuestion> secilen = <LicenseQuestion>[
      ...sorulmamis,
      ...kalan,
    ].take(questionsPerExam).toList(growable: false);
    return secilen;
  }

  /// Başvurur: ücreti **bir kez** alır ve sınav sorusunu açar.
  LicenseResult apply(GameState state, LicenseType type, Random rng) {
    final InteractionAvailability check =
        applicationAvailability(state, type);
    if (!check.isAllowed) return _blocked(state, check.reason!);

    final int ucret = prototypeOnlyExamFee(type);
    final List<LicenseQuestion> sorular = _pickQuestions(state, type, rng);
    final Map<String, int> counts = <String, int>{
      ...state.interactionCounts,
      GameState.interactionKey(type.id, _interactionKind):
          _attemptsThisAge(state, type) + 1,
      for (final LicenseQuestion soru in sorular)
        GameState.interactionKey(soru.id, _questionKind):
            _questionAskedThisAge(state, soru) + 1,
    };

    final String metin = '${type.label} için başvurdun; sınav ücreti '
        '$ucret ₺ ödendi. $questionsPerExam soru soruluyor, '
        'en az $passingCorrectAnswers doğru gerekiyor.';
    final GameState next = state.copyWith(
      player: state.player.copyWith(wallet: state.player.wallet - ucret),
      interactionCounts: Map<String, int>.unmodifiable(counts),
      pendingLicenseExam: PendingLicenseExam(
        licenseId: type.id,
        questionIds: List<String>.unmodifiable(
          sorular.map((LicenseQuestion q) => q.id).toList(growable: false),
        ),
        answers: const <int>[],
        askedAtAge: state.player.age,
        feePaid: ucret,
      ),
    );

    return LicenseResult(
      state: _log(next, metin),
      outcome: LicenseOutcome(applied: true, text: metin, examStarted: true),
    );
  }

  /// Sınav sorusunu cevaplar.
  ///
  /// Cevap verildikten sonra sınav kapanır; **ikinci kez uygulanamaz** ve
  /// ücret yeniden kesilmez.
  LicenseResult answer(GameState state, int optionIndex) {
    final PendingLicenseExam? sinav = state.pendingLicenseExam;
    if (sinav == null) {
      return _blocked(state, 'Devam eden bir ehliyet sınavı yok.');
    }
    final LicenseType? type = sinav.license;
    final LicenseQuestion? soru = sinav.currentQuestion;
    if (type == null || soru == null || sinav.questions.length !=
        sinav.questionIds.length) {
      return LicenseResult(
        state: state.copyWith(pendingLicenseExam: null),
        outcome: const LicenseOutcome(
          applied: true,
          text: 'Sınav kaydı okunamadı, işlem iptal edildi.',
        ),
      );
    }
    if (optionIndex < 0 || optionIndex >= soru.options.length) {
      return _blocked(state, 'Geçersiz seçenek.');
    }

    // Ehliyet zaten alınmışsa sınav kapanır, ikinci kez eklenmez.
    if (state.hasLicense(type.id)) {
      final String metin = '${type.label} zaten sende.';
      return LicenseResult(
        state: state.copyWith(pendingLicenseExam: null),
        outcome: LicenseOutcome(applied: true, text: metin),
      );
    }

    final PendingLicenseExam guncel = sinav.copyWith(
      answers: List<int>.unmodifiable(<int>[...sinav.answers, optionIndex]),
    );

    // Sınav bitmediyse sıradaki soruya geçilir; ehliyet henüz verilmez.
    if (!guncel.isComplete) {
      return LicenseResult(
        state: state.copyWith(pendingLicenseExam: guncel),
        outcome: LicenseOutcome(
          applied: true,
          text: '${guncel.currentIndex}. soru.',
          answeredCount: guncel.answers.length,
          questionCount: guncel.questionCount,
        ),
      );
    }

    // Sınav bitti: en az [passingCorrectAnswers] doğru gerekir.
    final int dogru = guncel.correctCount;
    final bool gecti = dogru >= passingCorrectAnswers;
    final List<ExamAnswerReview> inceleme = <ExamAnswerReview>[
      for (int i = 0; i < guncel.questionIds.length; i++)
        ExamAnswerReview(
          question: guncel.questions[i],
          givenIndex: guncel.answers[i],
        ),
    ];

    final GameState kapali = state.copyWith(pendingLicenseExam: null);

    if (!gecti) {
      final String metin = '${type.label} sınavını geçemedin: '
          '$dogru/${guncel.questionCount} doğru. '
          'En az $passingCorrectAnswers doğru gerekiyordu.';
      return LicenseResult(
        state: _log(kapali, metin),
        outcome: LicenseOutcome(
          applied: true,
          text: metin,
          correctCount: dogru,
          questionCount: guncel.questionCount,
          answeredCount: guncel.answers.length,
          review: inceleme,
        ),
      );
    }

    final String metin = '${type.label} sınavını geçtin '
        '($dogru/${guncel.questionCount} doğru); ehliyetin artık var.';
    return LicenseResult(
      state: _log(
        kapali.copyWith(
          licenses: Set<String>.unmodifiable(
            <String>{...kapali.licenses, type.id},
          ),
        ),
        metin,
      ),
      outcome: LicenseOutcome(
        applied: true,
        text: metin,
        granted: true,
        correctCount: dogru,
        questionCount: guncel.questionCount,
        answeredCount: guncel.answers.length,
        review: inceleme,
      ),
    );
  }

  /// Sınavdan vazgeçer.
  ///
  /// Ücret iade edilmez ve başvuru hakkı harcanmış sayılır; böylece soruyu
  /// görüp kaçmak bedava olmaz.
  LicenseResult cancel(GameState state) {
    final PendingLicenseExam? sinav = state.pendingLicenseExam;
    if (sinav == null) {
      return _blocked(state, 'Devam eden bir ehliyet sınavı yok.');
    }
    const String metin = 'Sınavdan vazgeçtin.';
    return LicenseResult(
      state: _log(state.copyWith(pendingLicenseExam: null), metin),
      outcome: const LicenseOutcome(applied: true, text: metin),
    );
  }

  LicenseResult _blocked(GameState state, String reason) => LicenseResult(
        state: state,
        outcome: LicenseOutcome(applied: false, text: reason),
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

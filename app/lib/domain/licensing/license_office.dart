import 'dart:math';

import '../../data/license_catalog.dart';
import '../../data/license_questions.dart';
import '../models/game_state.dart';
import '../models/interaction.dart';
import '../models/life_log.dart';
import '../models/pending_license_exam.dart';

/// Ehliyet başvurusunun sonucu.
class LicenseOutcome {
  const LicenseOutcome({
    required this.applied,
    required this.text,
    this.examStarted = false,
    this.granted = false,
    this.correctAnswer,
    this.explanation,
  });

  final bool applied;
  final String text;

  /// Başvuru bir sınav sorusu açtı mı?
  final bool examStarted;

  /// Ehliyet verildi mi?
  final bool granted;

  /// Yanlış cevaptan sonra gösterilen doğru seçenek.
  final String? correctAnswer;
  final String? explanation;
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
    if (questionsForLicense(type.id).isEmpty) {
      return const InteractionAvailability.blocked(
        'Bu ehliyet için sınav soruları henüz yazılmadı.',
      );
    }
    return const InteractionAvailability.allowed();
  }

  int _attemptsThisAge(GameState state, LicenseType type) =>
      state.interactionCount(type.id, _interactionKind);

  int _questionAskedThisAge(GameState state, LicenseQuestion q) =>
      state.interactionCount(q.id, _questionKind);

  /// Bu yaşta sorulmamış bir soru varsa onu tercih eder.
  LicenseQuestion _pickQuestion(GameState state, LicenseType type, Random rng) {
    final List<LicenseQuestion> hepsi = questionsForLicense(type.id);
    final List<LicenseQuestion> sorulmamis = hepsi
        .where((LicenseQuestion q) => _questionAskedThisAge(state, q) == 0)
        .toList(growable: false);
    final List<LicenseQuestion> havuz =
        sorulmamis.isEmpty ? hepsi : sorulmamis;
    return havuz[rng.nextInt(havuz.length)];
  }

  /// Başvurur: ücreti **bir kez** alır ve sınav sorusunu açar.
  LicenseResult apply(GameState state, LicenseType type, Random rng) {
    final InteractionAvailability check =
        applicationAvailability(state, type);
    if (!check.isAllowed) return _blocked(state, check.reason!);

    final int ucret = prototypeOnlyExamFee(type);
    final LicenseQuestion soru = _pickQuestion(state, type, rng);
    final Map<String, int> counts = <String, int>{
      ...state.interactionCounts,
      GameState.interactionKey(type.id, _interactionKind):
          _attemptsThisAge(state, type) + 1,
      GameState.interactionKey(soru.id, _questionKind):
          _questionAskedThisAge(state, soru) + 1,
    };

    final String metin = '${type.label} için başvurdun; sınav ücreti '
        '$ucret ₺ ödendi.';
    final GameState next = state.copyWith(
      player: state.player.copyWith(wallet: state.player.wallet - ucret),
      interactionCounts: Map<String, int>.unmodifiable(counts),
      pendingLicenseExam: PendingLicenseExam(
        licenseId: type.id,
        questionId: soru.id,
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
    final LicenseQuestion? soru = sinav.question;
    if (type == null || soru == null) {
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

    final GameState kapali = state.copyWith(pendingLicenseExam: null);

    // Ehliyet zaten alınmışsa ikinci kez eklenmez.
    if (state.hasLicense(type.id)) {
      final String metin = '${type.label} zaten sende.';
      return LicenseResult(
        state: kapali,
        outcome: LicenseOutcome(applied: true, text: metin),
      );
    }

    if (optionIndex != soru.correctIndex) {
      final String metin = '${type.label} sınavını geçemedin. '
          'Bu sefer olmadı; tekrar başvurabilirsin.';
      return LicenseResult(
        state: _log(kapali, metin),
        outcome: LicenseOutcome(
          applied: true,
          text: metin,
          correctAnswer: soru.correctOption,
          explanation: soru.explanation,
        ),
      );
    }

    final String metin = '${type.label} sınavını geçtin; ehliyetin artık var.';
    return LicenseResult(
      state: _log(
        kapali.copyWith(
          licenses: Set<String>.unmodifiable(
            <String>{...kapali.licenses, type.id},
          ),
        ),
        metin,
      ),
      outcome: LicenseOutcome(applied: true, text: metin, granted: true),
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

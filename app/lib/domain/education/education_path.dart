import 'dart:math';

import '../../data/education_tracks.dart';
import '../../data/university_catalog.dart';
import '../models/game_state.dart';
import '../models/life_log.dart';

/// Bir eğitim seçiminin sonucu.
class EducationOutcome {
  const EducationOutcome({
    required this.applied,
    required this.text,
    this.accepted = false,
  });

  /// İşlem gerçekten uygulandı mı?
  final bool applied;

  /// Oyuncuya gösterilecek metin.
  final String text;

  /// Başvuru sonucu kabul mü?
  final bool accepted;
}

class EducationResult {
  const EducationResult({required this.state, required this.outcome});

  final GameState state;
  final EducationOutcome outcome;
}

/// Lise alanı seçimi, üniversite başvurusu ve mezuniyet sonrası yollar.
///
/// Bütün sayısal değerler `prototypeOnly`'dir
/// (`docs/DESIGN_REVIEW_QUEUE.md`, Q-047).
class EducationPath {
  const EducationPath();

  /// prototypeOnly: yerleştirme puanının zekâdan gelen payı.
  static const double prototypeOnlyIntelligenceWeight = 0.7;

  /// prototypeOnly: okul izlerinin (derste söz almak gibi) puana katkısı.
  static const int prototypeOnlyStudyBonus = 8;

  /// prototypeOnly: puana eklenen rastgele aralık.
  static const int prototypeOnlyLuckRange = 20;

  /// prototypeOnly: üniversite başvurusunda tercih edilen alandan gelen ek.
  static const int prototypeOnlyTrackBonus = 12;

  /// 8. sınıf sonunda yerleştirme puanını hesaplar.
  ///
  /// Zekâ ağırlıklıdır ama tek belirleyici değildir: geçmiş kararlar ve biraz
  /// şans da etkiler. Puan ne olursa olsun en az üç alan açık kalır.
  int placementScore(GameState state, Random rng) {
    final int zeka = state.player.stats.intelligence;
    int puan = (zeka * prototypeOnlyIntelligenceWeight).round();
    if (state.storyFlags.contains('derste_soz_aldi')) {
      puan += prototypeOnlyStudyBonus;
    }
    if (state.storyFlags.contains('arkadasa_yardim_etti')) {
      puan += prototypeOnlyStudyBonus ~/ 2;
    }
    puan += rng.nextInt(prototypeOnlyLuckRange + 1);
    return puan.clamp(0, 100);
  }

  /// Puanın yettiği lise alanları.
  List<EducationTrackInfo> availableTracks(GameState state) =>
      tracksFor(state.education.placementScore ?? 0);

  /// Lise alanını seçer. Seçim eğitim geçmişine kalıcı olarak yazılır.
  EducationResult chooseTrack(GameState state, EducationTrack track) {
    if (!state.education.awaitingTrackChoice) {
      return _blocked(state, 'Şu an lise alanı seçemezsin.');
    }
    final EducationTrackInfo info = trackInfo(track);
    if ((state.education.placementScore ?? 0) < info.minScore) {
      return _blocked(
        state,
        '${info.label} için puanın yetmiyor (${info.minScore} gerekiyor).',
      );
    }

    final String metin = '${info.label} alanını seçtin. ${info.description}';
    return EducationResult(
      state: _log(
        state.copyWith(education: state.education.copyWith(track: track)),
        metin,
      ),
      outcome: EducationOutcome(applied: true, text: metin, accepted: true),
    );
  }

  /// Lise bitince **bir kez** hesaplanan üniversite sınav puanı.
  ///
  /// Lise yerleştirme puanından ayrı bir değerdir: lise başarısı ve zekâ
  /// birlikte sayılır, sınav gününün şansı eklenir. Hesaplandıktan sonra
  /// saklanır; her başvuruda yeniden hesaplanmaz, böylece oyuncu kendi
  /// puanını ekranda görebilir.
  int computeUniversityExamScore(GameState state, Random rng) {
    final int taban =
        state.education.placementScore ?? state.player.stats.intelligence;
    int puan = ((taban + state.player.stats.intelligence) / 2).round();
    puan += rng.nextInt(11); // prototypeOnly: sınav günü
    return puan.clamp(0, 100);
  }

  /// Oyuncunun üniversite sınav puanı; henüz hesaplanmadıysa `null`.
  int? universityExamScore(GameState state) =>
      state.education.universityExamScore;

  /// Bir bölüme başvururken geçerli olan **etkin** puan.
  ///
  /// Sınav puanına, bölümün tercih ettiği alandan geliyorsa alan uyumu
  /// eklenir. Rastgelelik içermez: ekranda gösterilen puan ile başvuruda
  /// kullanılan puan aynıdır.
  int effectiveScore(GameState state, UniversityProgram program) {
    final int taban = state.education.universityExamScore ?? 0;
    return (taban + trackBonusFor(state, program)).clamp(0, 100);
  }

  /// Bölümün tercih ettiği alandan geliniyorsa eklenen puan.
  int trackBonusFor(GameState state, UniversityProgram program) {
    final EducationTrack? track = state.education.track;
    if (track == null) return 0;
    return program.preferredTracks.contains(track)
        ? prototypeOnlyTrackBonus
        : 0;
  }

  /// Başvurunun neden mümkün olmadığını açıklar; uygunsa boş metin döner.
  String eligibilityReason(GameState state, UniversityProgram program) {
    if (!state.education.finished) return 'Önce liseyi bitirmen gerekiyor.';
    if (state.education.universityProgramId != null) {
      return 'Zaten bir bölüme kayıtlısın.';
    }
    if (state.education.universityExamScore == null) {
      return 'Üniversite sınav puanın henüz hesaplanmadı.';
    }
    final int puan = effectiveScore(state, program);
    if (puan < program.minScore) {
      return 'Puanın yetmiyor: $puan / ${program.minScore}.';
    }
    return '';
  }

  /// Başvurulabilecek bölümler: lise bitmiş ve kayıt yapılmamış olmalı.
  List<UniversityProgram> availablePrograms(GameState state) {
    if (!state.education.finished) return const <UniversityProgram>[];
    if (state.education.universityProgramId != null) {
      return const <UniversityProgram>[];
    }
    return kUniversityPrograms;
  }

  /// Üniversite sınav puanı yoksa hesaplayıp duruma yazar.
  ///
  /// Eski kayıtlarda (ve liseyi yeni bitirenlerde) puan eksik olabilir;
  /// başvuru ekranı açılmadan önce bir kez hesaplanır.
  GameState ensureUniversityExamScore(GameState state, Random rng) {
    if (!state.education.finished) return state;
    if (state.education.universityExamScore != null) return state;
    return state.copyWith(
      education: state.education.copyWith(
        universityExamScore: computeUniversityExamScore(state, rng),
      ),
    );
  }

  /// Üniversiteye başvurur.
  ///
  /// Sonuç, ekranda gösterilen puanla birebir aynı hesaba dayanır.
  EducationResult applyToUniversity(
    GameState state,
    UniversityProgram program,
    Random rng,
  ) {
    final GameState hazir = ensureUniversityExamScore(state, rng);
    final String engel = eligibilityReason(hazir, program);
    if (engel.isNotEmpty && !engel.startsWith('Puanın yetmiyor')) {
      return _blocked(hazir, engel);
    }

    final int puan = effectiveScore(hazir, program);
    if (puan < program.minScore) {
      final String metin = '${program.name} başvurun kabul edilmedi. '
          'Puanın $puan, gereken ${program.minScore}.';
      return EducationResult(
        state: _log(hazir, metin),
        outcome: EducationOutcome(applied: true, text: metin),
      );
    }

    final String metin = '${program.name} bölümüne yerleştin. Puanın $puan.';
    return EducationResult(
      state: _log(
        hazir.copyWith(
          education: hazir.education.copyWith(
            universityProgramId: program.id,
            universityYear: 1,
            universityFinished: false,
          ),
        ),
        metin,
      ),
      outcome: EducationOutcome(applied: true, text: metin, accepted: true),
    );
  }

  /// Üniversiteye gitmeyip başka bir yol seçmek.
  ///
  /// Kayıt silinmez; yalnızca "üniversiteye gitmedim" durumu netleşir ve
  /// mezuniyet sonrası ekranı kapanır. İş arama Meslek bölümünden sürer.
  EducationResult skipUniversity(GameState state) {
    if (!state.education.awaitingAfterSchoolChoice) {
      return _blocked(state, 'Şu an böyle bir seçim yok.');
    }
    const String metin = 'Üniversiteye gitmemeye karar verdin. '
        'Bundan sonrası iş hayatında.';
    return EducationResult(
      state: _log(
        state.copyWith(
          storyFlags: <String>{...state.storyFlags, universiteyeGitmediFlag},
        ),
        metin,
      ),
      outcome: const EducationOutcome(
        applied: true,
        text: metin,
        accepted: true,
      ),
    );
  }

  /// Üniversiteye gitmeme kararının hikâye izi.
  static const String universiteyeGitmediFlag = 'universiteye_gitmedi';

  EducationResult _blocked(GameState state, String reason) => EducationResult(
        state: state,
        outcome: EducationOutcome(applied: false, text: reason),
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

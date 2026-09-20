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

  /// Bir bölüme başvuru puanı.
  int admissionScore(GameState state, UniversityProgram program, Random rng) {
    final int taban =
        state.education.placementScore ?? state.player.stats.intelligence;
    int puan = ((taban + state.player.stats.intelligence) / 2).round();
    final EducationTrack? track = state.education.track;
    if (track != null && program.preferredTracks.contains(track)) {
      puan += prototypeOnlyTrackBonus;
    }
    puan += rng.nextInt(11); // prototypeOnly: sınav günü şansı
    return puan.clamp(0, 100);
  }

  /// Başvurulabilecek bölümler: lise bitmiş ve kayıt yapılmamış olmalı.
  List<UniversityProgram> availablePrograms(GameState state) {
    if (!state.education.finished) return const <UniversityProgram>[];
    if (state.education.universityProgramId != null) {
      return const <UniversityProgram>[];
    }
    return kUniversityPrograms;
  }

  /// Üniversiteye başvurur. Kabul garanti değildir.
  EducationResult applyToUniversity(
    GameState state,
    UniversityProgram program,
    Random rng,
  ) {
    if (!state.education.finished) {
      return _blocked(state, 'Önce liseyi bitirmen gerekiyor.');
    }
    if (state.education.universityProgramId != null) {
      return _blocked(state, 'Zaten bir bölüme kayıtlısın.');
    }

    final int puan = admissionScore(state, program, rng);
    if (puan < program.minScore) {
      final String metin = '${program.name} başvurun kabul edilmedi. '
          'Puanın $puan, gereken ${program.minScore}.';
      return EducationResult(
        state: _log(state, metin),
        outcome: EducationOutcome(applied: true, text: metin),
      );
    }

    final String metin = '${program.name} bölümüne yerleştin. Puanın $puan.';
    return EducationResult(
      state: _log(
        state.copyWith(
          education: state.education.copyWith(
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

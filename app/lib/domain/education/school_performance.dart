import 'dart:math';

import '../../text/turkish_text.dart';
import '../generation/random_util.dart';
import '../models/education.dart';
import '../models/game_state.dart';
import '../models/interaction.dart';
import '../models/life_log.dart';

/// Bir ders çalışma denemesinin sonucu.
class StudyResult {
  const StudyResult({
    required this.state,
    required this.text,
    this.applied = false,
  });

  final GameState state;
  final String text;
  final bool applied;
}

/// Okul başarısı: not ortalaması, burs ve sınıfta kalma (Paket 13).
///
/// Şimdiye kadar okulda geçen yıllar oyuncunun kararlarından bağımsızdı:
/// ders çalışmak, başarılı olmak ya da kalmak diye bir şey yoktu. Artık
/// okulda geçen her yıl bir sonuç üretiyor.
///
/// Sayılar `prototypeOnly`'dir (Q-082).
abstract final class SchoolPerformance {
  /// prototypeOnly: ilk not ortalamasının zekâdan gelen payı.
  static const double prototypeOnlyStartWeight = 0.8;

  /// prototypeOnly: ilk ortalamaya eklenen rastgele aralık.
  static const int prototypeOnlyStartLuck = 12;

  /// prototypeOnly: bir yılda ortalamanın zekâya doğru kayma payı.
  static const double prototypeOnlyDrift = 0.25;

  /// prototypeOnly: yıllık rastgele dalgalanma.
  static const int prototypeOnlyYearlyLuck = 6;

  /// prototypeOnly: bir yılda yapılabilecek ders çalışma sayısı.
  static const int prototypeOnlyStudyPerYear = 2;

  /// prototypeOnly: ders çalışmanın ortalamaya katkısı.
  static const int prototypeOnlyStudyGain = 6;

  /// prototypeOnly: ders çalışmanın zekâya katkısı.
  static const int prototypeOnlyStudyIntelligence = 1;

  /// prototypeOnly: ders çalışmanın mutluluk bedeli.
  static const int prototypeOnlyStudyHappiness = -2;

  /// prototypeOnly: burs için gereken ortalama.
  static const int prototypeOnlyScholarshipAverage = 80;

  /// prototypeOnly: bursun en erken verildiği sınıf (lise).
  static const int prototypeOnlyScholarshipMinGrade = 9;

  /// prototypeOnly: yıllık burs tutarı (₺).
  static const int prototypeOnlyScholarshipAmount = 150000;

  /// prototypeOnly: sınıfta kalma eşiği.
  static const int prototypeOnlyFailAverage = 35;

  /// prototypeOnly: sınıfta kalmanın mümkün olduğu en küçük sınıf.
  ///
  /// İlkokul ve ortaokulda düşük not yalnızca ortalamayı etkiler; çocuk
  /// sınıfta bırakılmaz. Sınıf tekrarı lisede başlar (Q-082).
  static const int prototypeOnlyFailMinGrade = 9;

  /// prototypeOnly: okuldan ayrılmaya götüren tekrar sayısı.
  static const int prototypeOnlyMaxRepeats = 2;

  /// prototypeOnly: okuldan ayrılmanın mümkün olduğu en küçük yaş.
  ///
  /// Küçük çocuk okuldan atılmaz; sınıfı tekrarlar.
  static const int prototypeOnlyDropOutMinAge = 15;

  /// Ders çalışma sayacının anahtarı.
  static const String studyKey = 'ders_calis';

  /// Okula yeni başlayan öğrencinin ilk ortalaması.
  ///
  /// Zekâ ağırlıklıdır ama tek belirleyici değildir.
  static int prototypeOnlyStartingAverage(GameState state, Random rng) {
    final int taban =
        (state.player.stats.intelligence * prototypeOnlyStartWeight).round();
    return (taban + rng.between(0, prototypeOnlyStartLuck)).clamp(0, 100);
  }

  /// Bir okul yılı sonunda ortalamanın yeni değeri.
  ///
  /// Ortalama zekâya doğru yavaşça kayar: çalışmayan zeki öğrenci de
  /// zamanla ortalamaya döner, çalışan öğrenci kazandığını korur.
  static int prototypeOnlyYearEndAverage({
    required int current,
    required int intelligence,
    required Random rng,
  }) {
    final double kayma = (intelligence - current) * prototypeOnlyDrift;
    final int sans =
        rng.between(-prototypeOnlyYearlyLuck, prototypeOnlyYearlyLuck);
    return (current + kayma.round() + sans).clamp(0, 100);
  }

  // -------------------------------------------------------------------
  // Ders çalışma
  // -------------------------------------------------------------------

  /// Ders çalışmak şu an mümkün mü?
  static InteractionAvailability studyAvailability(GameState state) {
    final EducationState egitim = state.education;
    if (!egitim.isSchoolStudent && !egitim.isUniversityStudent) {
      return const InteractionAvailability.blocked(
        'Şu an okula devam etmiyorsun.',
      );
    }
    if (state.interactionCount(studyKey, 'okul') >=
        prototypeOnlyStudyPerYear) {
      return const InteractionAvailability.blocked(
        'Bu yıl yeterince çalıştın; bundan fazlası bir şey değiştirmiyor.',
      );
    }
    return const InteractionAvailability.allowed();
  }

  /// Ders çalışır: ortalama ve zekâ biraz artar, biraz da yorulursun.
  static StudyResult study(GameState state, Random rng) {
    final InteractionAvailability uygunluk = studyAvailability(state);
    if (!uygunluk.isAllowed) {
      return StudyResult(state: state, text: uygunluk.reason!);
    }

    final EducationState egitim = state.education;
    final int mevcut = egitim.gradeAverage ??
        prototypeOnlyStartingAverage(state, rng);
    // Yüksek ortalamada kazanç azalır: 100'e yaklaşmak zorlaşır.
    final int kazanc = mevcut >= 90
        ? 2
        : mevcut >= 75
            ? 4
            : prototypeOnlyStudyGain;
    final int yeni = (mevcut + kazanc).clamp(0, 100);

    final GameState next = state
        .copyWith(
          education: egitim.copyWith(gradeAverage: yeni),
          player: state.player.copyWith(
            stats: state.player.stats.gain(
              intelligence: prototypeOnlyStudyIntelligence,
              happiness: prototypeOnlyStudyHappiness,
            ),
          ),
          interactionCounts: Map<String, int>.unmodifiable(<String, int>{
            ...state.interactionCounts,
            GameState.interactionKey(studyKey, 'okul'):
                state.interactionCount(studyKey, 'okul') + 1,
          }),
        );

    final String metin = yeni == mevcut
        ? 'Çalıştın ama ortalaman zaten tavanda.'
        : 'Ders çalıştın. Not ortalaman $yeni oldu.';
    return StudyResult(state: _log(next, metin), text: metin, applied: true);
  }

  // -------------------------------------------------------------------
  // Yıl sonu
  // -------------------------------------------------------------------

  /// Bu yıl burs alınır mı?
  static bool deservesScholarship(EducationState egitim) {
    if (egitim.droppedOut) return false;
    final int ortalama = egitim.gradeAverage ?? 0;
    if (ortalama < prototypeOnlyScholarshipAverage) return false;
    if (egitim.isUniversityStudent) return true;
    final int? sinif = egitim.grade;
    return sinif != null && sinif >= prototypeOnlyScholarshipMinGrade;
  }

  /// Burs ödemesi; hak edilmiyorsa `null`.
  static ({GameState state, String logText})? payScholarship(
    GameState state,
    int newAge,
  ) {
    if (!deservesScholarship(state.education)) return null;
    final bool ilkKez = state.education.scholarshipSinceAge == null;
    final String metin = ilkKez
        ? 'Not ortalaman yüksek olduğu için burs almaya başladın: '
            '${trMoney(prototypeOnlyScholarshipAmount)}.'
        : 'Bursun yattı: ${trMoney(prototypeOnlyScholarshipAmount)}.';

    return (
      state: state.copyWith(
        player: state.player.copyWith(
          wallet: state.player.wallet + prototypeOnlyScholarshipAmount,
        ),
        education: state.education.copyWith(
          scholarshipSinceAge: ilkKez ? newAge : null,
        ),
      ),
      logText: metin,
    );
  }

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

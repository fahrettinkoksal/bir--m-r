// Okul + spor çatışması (Paket AL/2, §6-§9, §27).
//
// **Sorun.** Paket AL'de genç sporcunun okulu ile müsabaka takvimi
// hiç karşılaşmıyordu: çocuk hem ulusal turnuvaya gidiyor hem de
// okulda hiçbir bedel ödemiyordu.
//
// **Nadir ve anlamlı.** Her yaşta "okul mu spor mu?" diye soru
// sorulmuyor (§8). Çatışmanın çıkması için hepsi birden gerekiyor:
// oyuncu okula kayıtlı olacak, önünde bekleyen bir müsabaka olacak, o
// müsabaka ciddi bir kademede (ya da unvan maçı) olacak, o yıl daha
// önce çatışma çıkmamış olacak ve zar tutacak.
//
// **Otomatik ceza yok.** Profesyonel spor yolunu seçen çocuk kendi
// başına sınıfta kalmıyor: not ortalamasına ölçülü bir maliyet
// yazılıyor, sınıf tekrarı kararını yine mevcut `SchoolPerformance`
// veriyor. Bu paket okulun kendi eşiklerine dokunmadı.
//
// **İki seçim de gerçek** (§7). "Turnuvaya git" müsabakayı korur ve
// ortalamayı düşürür; "Okula öncelik ver" ortalamayı korur, bekleyen
// müsabakayı iptal eder ve formdan bir miktar götürür. İkisi de
// kayda giren, ölçülebilir durum üretir; hiçbiri süs değil.
library;

import 'dart:math';

import '../models/combat_career.dart';
import '../models/education.dart';
import '../models/game_state.dart';
import '../models/life_log.dart';

/// Okul/spor çatışmasının sonucu.
class SchoolConflictOutcome {
  const SchoolConflictOutcome({
    required this.applied,
    required this.text,
    this.choseSport = false,
  });

  final bool applied;
  final String text;
  final bool choseSport;
}

class SchoolConflictResult {
  const SchoolConflictResult({required this.state, required this.outcome});

  final GameState state;
  final SchoolConflictOutcome outcome;
}

/// Okul ile müsabaka takviminin çakışması.
abstract final class SportSchoolConflict {
  /// prototypeOnly: şartlar tuttuğunda çatışmanın çıkma ihtimali.
  ///
  /// Bilerek 1 değil: takvim her zaman çakışmaz.
  static const double prototypeOnlyChance = 0.35;

  /// prototypeOnly: çatışmanın kademeden gelmesi için gereken en düşük
  /// kademe.
  ///
  /// Kulüp içi ilk maçlar okulu böler diye kimse sınav haftasını
  /// tartışmaz; çatışma ciddi kademede anlamlı olur.
  static const int prototypeOnlyMinTier = 1;

  /// prototypeOnly: kademe düşük olsa bile çatışmayı açan müsabaka
  /// sayısı.
  ///
  /// **Ölçümle bulundu.** İlk yazımda kapı yalnızca kademeye
  /// bakıyordu ve 200 genç sporcu ölçümünde çatışma **1 kez** çıktı:
  /// okul çağındaki sporcuların yalnızca 16/200'ü kademe 1'e
  /// ulaşabiliyor, çünkü kademe atlamak galibiyet + itibar + teknik
  /// basamak istiyor ve bunların hepsi 15-18 yaş aralığına sığmıyor.
  /// Yani özellik yazılmış ama fiilen ölüydü.
  ///
  /// Gerçek hayatta çatışmayı yaratan şey kademe değil **takvim
  /// yoğunluğu**: yılda üç-dört amatör turnuvaya giden çocuk da okulu
  /// kaçırır. Bu yüzden kapı artık bağlılığa da bakıyor. Yeni
  /// başlayan çocuk hâlâ muaf; yılda bir kez sınırı ve zar da
  /// yerinde duruyor (§8).
  static const int prototypeOnlyMinBouts = 4;

  /// prototypeOnly: turnuvayı seçmenin not ortalamasına maliyeti.
  static const int prototypeOnlyGradeCost = 5;

  /// prototypeOnly: kritik okul yılında (son sınıf / üniversite)
  /// turnuvayı seçmenin maliyeti (§9).
  static const int prototypeOnlyCriticalGradeCost = 9;

  /// prototypeOnly: okulu seçmenin forma maliyeti.
  ///
  /// Kamp bölünür, ritim kaçar. Kariyeri bitirmez.
  static const int prototypeOnlyFormCost = 6;

  /// prototypeOnly: okulu seçen öğrencinin ortalamasına katkısı.
  static const int prototypeOnlyStudyGain = 2;

  /// Aynı yıl ikinci kez çatışma çıkmasını engelleyen sayaç.
  static const String counterKind = 'okulSporCatismasi';

  static const String _counterKey = 'okulSpor';

  /// Bu yıl çatışma zaten üretildi mi (§31)?
  static bool firedThisYear(GameState state) =>
      state.interactionCount(_counterKey, counterKind) > 0;

  /// Oyuncu şu an okulda mı (lise ya da üniversite)?
  static bool _inSchool(GameState state) {
    final EducationState e = state.education;
    if (e.droppedOut) return false;
    if (e.enrolled && e.grade != null) return true;
    return e.universityProgramId != null && !e.universityFinished;
  }

  /// Kritik okul yılı mı (son sınıf ya da üniversite)?
  ///
  /// §9'un istediği "nadiren daha ağır karar" burada: aynı mekanik,
  /// daha yüksek bedel. Ayrı bir sınav motoru kurulmadı.
  static bool isCriticalYear(GameState state) {
    final EducationState e = state.education;
    if (e.universityProgramId != null && !e.universityFinished) return true;
    return e.grade == 12;
  }

  /// Bekleyen çatışma var mı?
  static bool isPending(GameState state, CombatCareer career) =>
      career.schoolConflictAge == state.player.age &&
      career.pendingBout != null;

  /// Şartlar tutuyorsa çatışmayı üretir; üretmezse durumu aynen döner.
  ///
  /// Not ortalaması olmayan öğrenciye çatışma çıkarılmaz: seçimin
  /// gerçek bir sonucu olmayacaksa soru da sorulmaz (§7).
  static ({GameState state, String? text}) maybeRaise(
    GameState state,
    CombatCareer career,
    Random rng,
  ) {
    if (career.isRetired) return (state: state, text: null);
    if (career.schoolConflictAge != null) return (state: state, text: null);
    if (firedThisYear(state)) return (state: state, text: null);
    if (!_inSchool(state)) return (state: state, text: null);
    if (state.education.gradeAverage == null) return (state: state, text: null);

    final PendingBout? bout = career.pendingBout;
    if (bout == null) return (state: state, text: null);
    final bool ciddi = bout.isTitle ||
        bout.tier >= prototypeOnlyMinTier ||
        career.totalBouts >= prototypeOnlyMinBouts;
    if (!ciddi) return (state: state, text: null);
    if (rng.nextDouble() >= prototypeOnlyChance) {
      return (state: state, text: null);
    }

    final String metin = isCriticalYear(state)
        ? '${bout.opponent.name} ile yapacağın müsabaka sınav dönemine '
            'denk geldi. Bu yılın okul açısından telafisi zor.'
        : 'Turnuva sınav haftasına denk geldi. '
            '${bout.opponent.name} ile eşleşmen o günlerde.';

    return (
      state: _replace(
        state,
        career.copyWith(schoolConflictAge: state.player.age),
      ),
      text: metin,
    );
  }

  /// "Turnuvaya git" (§7).
  ///
  /// Müsabaka korunur; not ortalamasından gerçek bir kesinti yapılır.
  static SchoolConflictResult chooseSport(GameState state) =>
      _resolve(state, sport: true);

  /// "Okula öncelik ver" (§7).
  ///
  /// Bekleyen müsabaka kaçırılır ve formdan bir miktar gider; okul
  /// korunur, çalışmaya ayrılan zaman ortalamaya biraz yazar.
  static SchoolConflictResult chooseSchool(GameState state) =>
      _resolve(state, sport: false);

  static SchoolConflictResult _resolve(
    GameState state, {
    required bool sport,
  }) {
    final CombatCareer? kariyer = _active(state);
    if (kariyer == null || !isPending(state, kariyer)) {
      // §31: çözülmüş çatışma ikinci kez uygulanamaz.
      return SchoolConflictResult(
        state: state,
        outcome: const SchoolConflictOutcome(
          applied: false,
          text: 'Bekleyen bir okul/spor çatışması yok.',
        ),
      );
    }

    final EducationState egitim = state.education;
    final int ortalama = egitim.gradeAverage!;
    final PendingBout bout = kariyer.pendingBout!;

    if (sport) {
      final int bedel = isCriticalYear(state)
          ? prototypeOnlyCriticalGradeCost
          : prototypeOnlyGradeCost;
      final String metin = 'Turnuvayı seçtin. ${bout.opponent.name} ile '
          'eşleşmen duruyor; okulda bu dönem geri kaldın.';
      final GameState next = _replace(
        _mark(state).copyWith(
          education: egitim.copyWith(
            gradeAverage: (ortalama - bedel).clamp(0, 100),
          ),
        ),
        kariyer
            .copyWith(schoolConflictAge: null)
            .remember(state.player.age, 'Turnuvayı okula tercih ettin.'),
      );
      return SchoolConflictResult(
        state: _log(next, metin),
        outcome: SchoolConflictOutcome(
          applied: true,
          text: metin,
          choseSport: true,
        ),
      );
    }

    final String metin = 'Okulu seçtin. ${bout.opponent.name} ile '
        'eşleşmen iptal oldu; ritmin biraz bozuldu.';
    final GameState next = _replace(
      _mark(state).copyWith(
        education: egitim.copyWith(
          gradeAverage: (ortalama + prototypeOnlyStudyGain).clamp(0, 100),
        ),
      ),
      kariyer
          .copyWith(
            schoolConflictAge: null,
            pendingBout: null,
            form: kariyer.form - prototypeOnlyFormCost,
          )
          .remember(state.player.age, 'Bir turnuvayı okul için kaçırdın.'),
    );
    return SchoolConflictResult(
      state: _log(next, metin),
      outcome: SchoolConflictOutcome(applied: true, text: metin),
    );
  }

  static CombatCareer? _active(GameState state) {
    for (final CombatCareer c in state.combatCareers) {
      if (!c.isRetired) return c;
    }
    return null;
  }

  static GameState _mark(GameState state) => state.copyWith(
        interactionCounts: <String, int>{
          ...state.interactionCounts,
          GameState.interactionKey(_counterKey, counterKind): 1,
        },
      );

  static GameState _replace(GameState state, CombatCareer career) =>
      state.copyWith(
        combatCareers: List<CombatCareer>.unmodifiable(<CombatCareer>[
          for (final CombatCareer c in state.combatCareers)
            if (c.artId == career.artId) career else c,
        ]),
      );

  static GameState _log(GameState state, String text) => state.copyWith(
        log: <LifeLogEntry>[
          ...state.log,
          LifeLogEntry(
            age: state.player.age,
            text: text,
            category: LogCategory.kisisel,
          ),
        ],
      );
}

import 'dart:math';

import '../../data/name_pool.dart';
import '../career/job_market.dart';
import '../education/education_path.dart';
import '../events/event_engine.dart';
import '../../data/education_tracks.dart';
import '../models/education.dart';
import '../models/game_event.dart';
import '../models/game_state.dart';
import '../models/life_log.dart';
import '../models/person.dart';
import '../models/wealth.dart';
import 'random_util.dart';
import 'school_people.dart';

/// **Yaş Al** işleminin durum üzerindeki etkisi (D-018).
///
/// Oyuncu hazır olduğunda kendi isteğiyle bir yaş ilerler; bir yaşın bütün
/// etkinliklerini bitirmesi gerekmez.
///
/// Yeni yaşa girildiğinde oyuncunun karşısına **ilk olarak yalnızca tek**
/// uygun olay çıkar (D-021); art arda bağımsız olay pencereleri açılmaz.
/// Uygun olay yoksa hiç olay çıkmaz. Gerçek dünya dakikası beklenmez (D-024).
///
/// NPC'lerin bağımsız hayat gelişmeleri (D-010) henüz uygulanmadı.
class LifeProgression {
  LifeProgression(this._rng);

  final Random _rng;

  /// Okula başlama yaşı. Türkiye'de zorunlu eğitim bu yaşta başlar; oyunda
  /// başlamama/geç başlama gibi durumlar henüz tasarlanmadı (prototypeOnly).
  static const int prototypeOnlySchoolStartAge = 6;

  /// Son sınıf. 4+4+4 yapısında lise 12. sınıfta biter.
  static const int lastGrade = 12;

  GameState advanceOneYear(GameState state) {
    // Ekranda çözülmemiş bir olay varken yaş ilerlemez: olaylar üst üste
    // binmez.
    if (state.hasPendingEvent) return state;

    final int newAge = state.player.age + 1;

    final List<Person> people = state.people
        .map((Person person) => person.isAlive ? _agePerson(person) : person)
        .toList(growable: false);

    final List<LifeLogEntry> log = <LifeLogEntry>[
      ...state.log,
      LifeLogEntry(
        age: newAge,
        text: '$newAge yaşına girdin.',
        category: LogCategory.yasDegisimi,
      ),
    ];

    // Eğitim durumu yaştan türetilmez; burada açıkça ilerletilir ve
    // anlamlı geçişler hayat günlüğüne yazılır.
    EducationState education = _advanceEducation(state.education, newAge);
    education = _applyUniversityExam(
      state: state,
      before: state.education,
      education: education,
      newAge: newAge,
      log: log,
    );
    education = _applyPlacementExam(
      state: state,
      education: education,
      newAge: newAge,
      log: log,
    );
    _logEducationChange(
      log: log,
      before: state.education,
      after: education,
      age: newAge,
    );

    // Yeni bir okul kademesine geçildiyse o kademenin sınıf arkadaşları ve
    // öğretmeni kalıcı kişi kaydı olarak eklenir. Eski kademenin kişileri
    // silinmez; yalnızca güncel sınıf listesinde görünmezler.
    final ({List<Person> people, EducationState education}) okulSonucu =
        _setUpClassIfNeeded(
      state: state,
      people: people,
      education: education,
      newAge: newAge,
      log: log,
    );
    final List<Person> peopleWithSchool = okulSonucu.people;

    // Maaş yeni yaşa geçerken **bir kez** ödenir.
    final ({GameState state, String? logText}) maas =
        const JobMarket().paySalaryFor(
      state.copyWith(player: state.player.copyWith(age: newAge)),
      newAge,
    );
    if (maas.logText != null) {
      log.add(
        LifeLogEntry(
          age: newAge,
          text: maas.logText!,
          category: LogCategory.kisisel,
        ),
      );
    }

    final GameState advanced = state.copyWith(
      // Maaş ödemesi cüzdanı ve ödeme dönemini günceller.
      player: maas.state.player.copyWith(age: newAge),
      people: List<Person>.unmodifiable(peopleWithSchool),
      log: List<LifeLogEntry>.unmodifiable(log),
      // Tekrar sayaçları yaşa aittir: yeni yaşta aynı etkinlik yeniden
      // anlamlı fayda verebilir. Yenilemenin tam mı kısmi mi olacağı
      // (`docs/CORE_LOOP.md`) henüz kararlaştırılmadı; prototipte tam
      // yenileme uygulanır.
      interactionCounts: const <String, int>{},
      // Kumarhanenin yıllık bahis sınırı da yaşa aittir.
      wagerThisAge: 0,
      extraEventsThisAge: 0,
      progressSinceLastEvent: 0,
      education: okulSonucu.education,
      career: maas.state.career,
    );

    // Lise alanının yıllık küçük kazancı; alan seçimi kozmetik değildir.
    final GameState withTrack = _applyTrackBonus(advanced);

    // Yeni yaşın tek açılış olayı.
    final ActiveEvent? opening =
        const EventEngine().openingEvent(withTrack, _rng);
    return opening == null
        ? withTrack
        : withTrack.copyWith(pendingEvent: opening);
  }

  /// Lise alanının yıllık küçük katkısı.
  GameState _applyTrackBonus(GameState state) {
    final EducationTrackInfo? alan = state.education.trackInfo;
    if (alan == null || !state.education.isSchoolStudent) return state;
    return state.copyWith(
      player: state.player.copyWith(
        stats: state.player.stats.copyWith(
          intelligence:
              state.player.stats.intelligence + alan.intelligenceBonus,
          charisma: state.player.stats.charisma + alan.charismaBonus,
          appearance: state.player.stats.appearance + alan.appearanceBonus,
        ),
      ),
    );
  }

  /// Yeni bir sınıf ortamı gerekiyorsa kurar.
  ///
  /// Sınıf atlamak (ör. 1'den 2'ye) yeni sınıf kurmaz; **kademe değişimi**
  /// kurar. Eski sınıftan bir bölüm arkadaş aynı kimlikle yeni sınıfa
  /// taşınır, kalanlar eski sınıfta kayıtlı kalır ve silinmez.
  ({List<Person> people, EducationState education}) _setUpClassIfNeeded({
    required GameState state,
    required List<Person> people,
    required EducationState education,
    required int newAge,
    required List<LifeLogEntry> log,
  }) {
    final SchoolLevel? level = education.level;
    if (level == null) {
      return (people: people, education: education);
    }

    final String schoolId = SchoolPeople.schoolIdFor(level);
    final String classId = SchoolPeople.classIdFor(level);

    // Sınıf zaten kuruluysa dokunma.
    if (education.classId == classId &&
        people.any((Person p) => p.classId == classId)) {
      return (people: people, education: education);
    }

    const SchoolPeople okul = SchoolPeople();
    final GameState basis = state.copyWith(
      player: state.player.copyWith(age: newAge),
      people: List<Person>.unmodifiable(people),
    );
    final List<Person> oncekiSinif = people
        .where((Person p) =>
            p.schoolTie == SchoolTie.sinifArkadasi &&
            p.classId != null &&
            p.classId == state.education.classId)
        .toList(growable: false);

    final ClassRoster roster = okul.buildClass(
      state: basis,
      level: level,
      rng: _rng,
      previousClassmates: oncekiSinif,
    );

    // Taşınanlar aynı kimlikle yeni sınıfa geçer; kayıt kopyalanmaz.
    final Set<String> tasinan = roster.movedIds.toSet();
    final List<Person> guncel = people
        .map((Person p) =>
            tasinan.contains(p.id) ? okul.moveToClass(p, level) : p)
        .toList(growable: false);

    final Iterable<Person> ogretmenler = roster.newPeople
        .where((Person p) => p.schoolTie == SchoolTie.ogretmen);
    if (ogretmenler.isNotEmpty) {
      final Person ogretmen = ogretmenler.first;
      log.add(
        LifeLogEntry(
          age: newAge,
          text: tasinan.isEmpty
              ? 'Yeni sınıfında öğretmenin ${ogretmen.fullName} oldu; '
                  'bütün yüzler yabancı.'
              : 'Yeni sınıfında öğretmenin ${ogretmen.fullName} oldu; '
                  '${tasinan.length} tanıdık yüz de seninle aynı sınıfta.',
          category: LogCategory.kisisel,
        ),
      );
    }

    return (
      people: <Person>[...guncel, ...roster.newPeople],
      education: education.copyWith(schoolId: schoolId, classId: classId),
    );
  }

  /// Okula başlatır veya bir üst sınıfa geçirir.
  ///
  /// Basit akış: belirlenen yaşta 1. sınıfa başlanır, her yaş bir sınıf
  /// ilerler, son sınıftan sonra okul biter. Sınav, not ve diploma yoktur.
  EducationState _advanceEducation(EducationState current, int newAge) {
    // Üniversite öğrencisi her yıl bir sınıf ilerler ve süre dolunca mezun
    // olur. Lise kaydı burada değişmez.
    if (current.isUniversityStudent) {
      final int yil = (current.universityYear ?? 1) + 1;
      final int sure = current.program?.durationYears ?? 4;
      if (yil > sure) {
        return current.copyWith(universityFinished: true, universityYear: sure);
      }
      return current.copyWith(universityYear: yil);
    }

    if (current.finished) return current;

    if (!current.enrolled) {
      // Yalnızca okula başlama yaşında kayıt olunur; daha ileri yaşta
      // kendiliğinden okula başlatılmaz.
      final bool baslamaZamani = newAge == prototypeOnlySchoolStartAge;
      if (!baslamaZamani) return current;
      return EducationState(
        enrolled: true,
        grade: 1,
        startedAtAge: newAge,
      );
    }

    final int nextGrade = (current.grade ?? 1) + 1;
    if (nextGrade > lastGrade) return current.asFinished();
    return current.copyWith(grade: nextGrade);
  }

  /// Lise bitince üniversite sınav puanını **bir kez** hesaplar.
  ///
  /// Lise yerleştirme puanından ayrı bir değerdir; hesaplanıp saklanır ve
  /// başvuru ekranında oyuncuya olduğu gibi gösterilir.
  EducationState _applyUniversityExam({
    required GameState state,
    required EducationState before,
    required EducationState education,
    required int newAge,
    required List<LifeLogEntry> log,
  }) {
    if (before.finished || !education.finished) return education;
    if (education.universityExamScore != null) return education;

    final int puan = const EducationPath().computeUniversityExamScore(
      state.copyWith(education: education),
      _rng,
    );
    log.add(
      LifeLogEntry(
        age: newAge,
        text: 'Üniversite sınavından $puan puan aldın.',
        category: LogCategory.kisisel,
      ),
    );
    return education.copyWith(universityExamScore: puan);
  }

  /// 8. sınıftan 9. sınıfa geçerken yerleştirme puanını hesaplar.
  ///
  /// Puan bir kez hesaplanır ve eğitim geçmişine yazılır; lise alanı seçimi
  /// bu puana bakar.
  EducationState _applyPlacementExam({
    required GameState state,
    required EducationState education,
    required int newAge,
    required List<LifeLogEntry> log,
  }) {
    if (education.placementScore != null) return education;
    if (!education.enrolled) return education;
    if ((education.grade ?? 0) != 9) return education;

    final int puan = const EducationPath().placementScore(state, _rng);
    log.add(
      LifeLogEntry(
        age: newAge,
        text: 'Ortaokul bitti. Yerleştirme puanın $puan. '
            'Artık lise alanını seçebilirsin.',
        category: LogCategory.kisisel,
      ),
    );
    return education.copyWith(placementScore: puan);
  }

  /// Okula başlama, kademe değişimi ve okulun bitişini günlüğe yazar.
  void _logEducationChange({
    required List<LifeLogEntry> log,
    required EducationState before,
    required EducationState after,
    required int age,
  }) {
    if (before.enrolled == after.enrolled &&
        before.grade == after.grade &&
        before.finished == after.finished) {
      return;
    }

    if (!before.enrolled && after.enrolled) {
      log.add(
        LifeLogEntry(
          age: age,
          text: 'Okula başladın. Çantan sırtında, ilk günün.',
          category: LogCategory.kisisel,
        ),
      );
      return;
    }

    if (after.finished && before.enrolled) {
      log.add(
        LifeLogEntry(
          age: age,
          text: 'Lise bitti. Okul defterlerini bir kutuya kaldırdın.',
          category: LogCategory.kisisel,
        ),
      );
      return;
    }

    // Kademe değiştiyse bildir; aynı kademedeki sınıf artışı günlüğü şişirmez.
    if (before.level != after.level && after.level != null) {
      log.add(
        LifeLogEntry(
          age: age,
          text: '${after.level!.label} sıralarına geçtin.',
          category: LogCategory.kisisel,
        ),
      );
    }
  }

  /// Kişinin yaşını bir artırır ve yalnızca yaşa bağlı **tutarlılık**
  /// düzeltmelerini uygular (okula başlayan çocuk gibi). Meslek ve ekonomik
  /// durum uydurulmaz: çalışmayan kişiye meslek atanmaz.
  Person _agePerson(Person person) {
    final int age = person.age + 1;
    EmploymentStatus employment = person.employment;
    String? occupation = person.occupation;
    WealthTier? wealth = person.wealth;

    if (employment == EmploymentStatus.cocuk && age >= 6) {
      employment = EmploymentStatus.ogrenci;
    } else if (employment == EmploymentStatus.ogrenci && age >= 24) {
      employment = _rng.pickWeighted(
        <EmploymentStatus>[
          EmploymentStatus.calisiyor,
          EmploymentStatus.issiz,
          EmploymentStatus.evIsleri,
        ],
        <double>[0.66, 0.18, 0.16], // prototypeOnly
      );
    } else if (employment == EmploymentStatus.calisiyor && age >= 65) {
      employment = EmploymentStatus.emekli;
    }

    if (employment == EmploymentStatus.calisiyor) {
      occupation ??= _rng.pick(meslekler);
    } else {
      occupation = null;
    }

    if (wealth == null && age >= 18) {
      wealth = _rng.pickWeighted(
        WealthTier.values,
        <double>[0.12, 0.26, 0.38, 0.17, 0.07], // prototypeOnly
      );
    }

    return person.copyWith(
      age: age,
      employment: employment,
      occupation: occupation,
      wealth: wealth,
    );
  }
}

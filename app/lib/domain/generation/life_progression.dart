import 'dart:math';

import '../../data/name_pool.dart';
import '../events/event_engine.dart';
import '../models/education.dart';
import '../models/game_event.dart';
import '../models/game_state.dart';
import '../models/life_log.dart';
import '../models/person.dart';
import '../models/wealth.dart';
import 'random_util.dart';

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
    final EducationState education = _advanceEducation(state.education, newAge);
    _logEducationChange(
      log: log,
      before: state.education,
      after: education,
      age: newAge,
    );

    final GameState advanced = state.copyWith(
      player: state.player.copyWith(age: newAge),
      people: List<Person>.unmodifiable(people),
      log: List<LifeLogEntry>.unmodifiable(log),
      // Tekrar sayaçları yaşa aittir: yeni yaşta aynı etkinlik yeniden
      // anlamlı fayda verebilir. Yenilemenin tam mı kısmi mi olacağı
      // (`docs/CORE_LOOP.md`) henüz kararlaştırılmadı; prototipte tam
      // yenileme uygulanır.
      interactionCounts: const <String, int>{},
      extraEventsThisAge: 0,
      progressSinceLastEvent: 0,
      education: education,
    );

    // Yeni yaşın tek açılış olayı.
    final ActiveEvent? opening = const EventEngine().openingEvent(advanced, _rng);
    return opening == null ? advanced : advanced.copyWith(pendingEvent: opening);
  }

  /// Okula başlatır veya bir üst sınıfa geçirir.
  ///
  /// Basit akış: belirlenen yaşta 1. sınıfa başlanır, her yaş bir sınıf
  /// ilerler, son sınıftan sonra okul biter. Sınav, not ve diploma yoktur.
  EducationState _advanceEducation(EducationState current, int newAge) {
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

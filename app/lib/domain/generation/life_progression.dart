import 'dart:math';

import '../../data/name_pool.dart';
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
/// Bu aşamada yaş alma yalnızca zamanı ilerletir: **olay motoru, aile
/// etkileşimleri ve NPC hayat gelişmeleri (D-010) henüz uygulanmadı**, sonraki
/// aşamalarda eklenecektir. Burada hiçbir olay üretilmez; gerçek dünya
/// dakikası da beklenmez (D-024).
class LifeProgression {
  LifeProgression(this._rng);

  final Random _rng;

  GameState advanceOneYear(GameState state) {
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

    return state.copyWith(
      player: state.player.copyWith(age: newAge),
      people: List<Person>.unmodifiable(people),
      log: List<LifeLogEntry>.unmodifiable(log),
    );
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

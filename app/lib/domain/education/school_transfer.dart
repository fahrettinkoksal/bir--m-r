import 'dart:math';

import '../../data/name_pool.dart';
import '../generation/school_people.dart';
import '../models/education.dart';
import '../models/game_state.dart';
import '../models/life_log.dart';
import '../models/person.dart';

/// Şehir değiştiren öğrencinin okul nakli (Paket 3).
///
/// Kurallar:
/// - Eğitim geçmişi **silinmez**: sınıf, lise alanı, yerleştirme puanı ve
///   üniversite sınav puanı olduğu gibi kalır.
/// - Eski okulun kişileri **silinmez**; yalnızca güncel sınıf/okul
///   listesinden düşerler ve kayıtlarında eski şehir yazılı kalır.
/// - Yeni şehirde yeni sınıf arkadaşları ve öğretmen tanınır; eski
///   şehirden kimse "taşınmaz" (başka şehre gidilmiştir).
/// - Oyuncu aynı anda iki okulda görünmez: okul ve sınıf kimliği tek bir
///   şehre bağlıdır.
class SchoolTransfer {
  const SchoolTransfer();

  /// Oyuncu okul öğrencisiyse ve sınıfı başka bir şehirdeyse nakleder.
  ///
  /// Nakil gerekmiyorsa durum olduğu gibi döner.
  ({GameState state, String? logText}) transferIfNeeded(
    GameState state,
    Random rng,
  ) {
    final EducationState egitim = state.education;
    if (!egitim.isSchoolStudent) return (state: state, logText: null);

    final SchoolLevel? kademe = egitim.level;
    if (kademe == null) return (state: state, logText: null);

    final String sehir = state.player.currentCity;
    final String? sinifSehri = SchoolPeople.cityOfClassId(egitim.classId);
    if (sinifSehri == sehir) return (state: state, logText: null);

    const SchoolPeople okul = SchoolPeople();
    final ClassRoster kadro = okul.buildClass(
      state: state,
      level: kademe,
      rng: rng,
      city: sehir,
    );

    final Iterable<Person> ogretmenler = kadro.newPeople
        .where((Person p) => p.schoolTie == SchoolTie.ogretmen);
    final String ogretmenAdi =
        ogretmenler.isEmpty ? '' : ogretmenler.first.fullName;

    final String metin = ogretmenAdi.isEmpty
        ? '$sehir şehrinde yeni okuluna naklin yapıldı; sınıfında bütün '
            'yüzler yabancı. Eski arkadaşların kaydında duruyor.'
        : '$sehir şehrinde yeni okuluna naklin yapıldı. Yeni öğretmenin '
            '$ogretmenAdi; eski sınıfın kaydında duruyor.';

    final GameState next = state.copyWith(
      people: List<Person>.unmodifiable(<Person>[
        ...state.people,
        ...kadro.newPeople,
      ]),
      education: egitim.copyWith(
        schoolId: SchoolPeople.schoolIdFor(kademe, sehir),
        classId: SchoolPeople.classIdFor(kademe, sehir),
      ),
      log: List<LifeLogEntry>.unmodifiable(<LifeLogEntry>[
        ...state.log,
        LifeLogEntry(
          age: state.player.age,
          text: metin,
          category: LogCategory.kisisel,
        ),
      ]),
    );

    return (state: next, logText: metin);
  }
}

/// `name_pool.dart` içindeki şehirler dışında bir şehir kullanılmaz.
bool isKnownCity(String city) => sehirler.contains(city);

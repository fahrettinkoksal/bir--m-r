import 'package:flutter/foundation.dart';

import 'education.dart';
import 'gender.dart';
import 'relation.dart';
import 'wealth.dart';

/// Oyun dünyasındaki bir kişi (NPC).
///
/// Kişi kimliği ([id]) hayat boyu değişmez. Bağ türü, hane üyeliği ve
/// yaşam durumu ayrı alanlardır; ilerideki aşamalarda ilişki statüsü
/// değişirken kaydın silinmemesi (D-029) bu sabit kimliğe dayanır.
@immutable
class Person {
  const Person({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.gender,
    required this.relation,
    required this.age,
    required this.isAlive,
    required this.inPlayerHousehold,
    required this.employment,
    required this.wealth,
    required this.bond,
    this.occupation,
    this.schoolLevel,
    this.schoolTie,
    this.schoolId,
    this.classId,
    this.city,
    this.estate = const <String>[],
  }) : assert(
          occupation == null || employment == EmploymentStatus.calisiyor,
          'Çalışmayan kişiye meslek atanmaz.',
        );

  /// Hayat boyu değişmeyen kişi kimliği.
  final String id;
  final String firstName;
  final String lastName;
  final Gender gender;

  /// Oyuncuyla olan bağ türü. Hane bilgisinden bağımsızdır.
  final RelationType relation;
  final int age;
  final bool isAlive;

  /// Oyuncuyla **aynı evde** yaşıyor mu? Akraba olmak bunu gerektirmez (D-014).
  final bool inPlayerHousehold;
  final EmploymentStatus employment;

  /// Yalnızca [EmploymentStatus.calisiyor] durumunda doludur.
  final String? occupation;

  /// Kişinin kendine ait ekonomik durumu (D-013).
  ///
  /// Çocuk/öğrenci gibi kendi ekonomik durumu anlamlı olmayan kişilerde
  /// `null` olur ve arayüzde hiç gösterilmez; uydurma bir değer üretilmez.
  final WealthTier? wealth;

  /// Okul kişileri için hangi kademede tanışıldığı.
  ///
  /// Sınıf arkadaşları ve öğretmenler kademe değişince listelerden düşer
  /// ama **kayıtları silinmez**; eski kademeye ait oldukları buradan bilinir.
  final SchoolLevel? schoolLevel;

  /// Tanışıldığı okulun kimliği. Kademeden bağımsızdır.
  final String? schoolId;

  /// Tanışıldığı sınıfın kimliği.
  ///
  /// Güncel sınıf arkadaşlığı bu kimlikle belirlenir; kademe geçişinde
  /// bazı kişiler aynı sınıfa taşınır, bazıları eski sınıfta kalır.
  final String? classId;

  /// Kişinin okul bağı (sınıf arkadaşı / öğretmen).
  ///
  /// [relation] yakınlık derecesini tutar ve değişebilir (sınıf arkadaşı →
  /// arkadaş). Okul bağı ise **değişmez**: aynı sınıfta okumaya devam eden
  /// kişi, yakın arkadaş olsa bile sınıf listesinden düşmez.
  final SchoolTie? schoolTie;

  /// Oyuncunun **şu anki sınıfında** sınıf arkadaşı mı?
  ///
  /// Yakınlık derecesi ([relation]) burada rol oynamaz: yakın arkadaş olan
  /// bir sınıf arkadaşı da sınıfta görünmeye devam eder.
  bool isClassmateIn(String? currentClassId) =>
      isAlive &&
      schoolTie == SchoolTie.sinifArkadasi &&
      currentClassId != null &&
      classId == currentClassId;

  /// Oyuncunun **şu anki okulunda** öğretmeni mi?
  bool isTeacherIn(String? currentSchoolId) =>
      isAlive &&
      schoolTie == SchoolTie.ogretmen &&
      currentSchoolId != null &&
      schoolId == currentSchoolId;

  /// Kişinin oyuncunun hayatındaki **şehri**.
  ///
  /// Oyuncu başka şehre taşındığında kayıt silinmez; yalnızca gündelik
  /// hayatta erişilebilirlik değişir (D-025). Eski kayıtlarda ve şehir
  /// bilgisi anlamlı olmayan kişilerde `null`'dır ve o zaman şehir
  /// koşulu hiç uygulanmaz.
  final String? city;

  /// Kişinin sahip olduğu eşyaların **tür** kimlikleri.
  ///
  /// Yetişkinlerde ekonomik duruma göre başlar, **hayat boyunca değişir**
  /// (alım/satım) ve kişi detayında "Sahip oldukları" satırında görünür.
  /// Vefat edince mirasçılara bu liste paylaştırılır; böylece miras
  /// uydurulmuş değil, kişinin gerçekten sahip olduğu şeylerden gelir
  /// (D-037). Değerler `prototypeOnly` (Q-059).
  final List<String> estate;

  /// Oyuncuyla ilişki puanı (0-100).
  ///
  /// Prototip aralığıdır; onaylanmış bir denge değeri değildir.
  final int bond;

  String get fullName => '$firstName $lastName';

  /// Çalışma durumunun ekranda gösterilecek hâli. Uydurma meslek üretmez.
  ///
  /// Öğrencinin kademesi biliniyorsa yazılır ("İlkokul öğrencisi"); bu
  /// kayıtta gerçekten duran bilgidir, yaştan uydurulmaz.
  String get occupationLabel {
    if (employment == EmploymentStatus.ogrenci && schoolLevel != null) {
      return '${schoolLevel!.label} öğrencisi';
    }
    if (employment != EmploymentStatus.calisiyor) return employment.label;
    final String? job = occupation;
    if (job == null || job.isEmpty) return 'Çalışıyor';
    return job[0].toUpperCase() + job.substring(1);
  }

  String labelFor(int playerAge) => relationLabel(
        relation: relation,
        gender: gender,
        personAge: age,
        playerAge: playerAge,
      );

  /// Cümle içinde kullanılan iyelikli etiket: "Deden", "Annen", "Arkadaşın".
  String possessiveFor(int playerAge) => relationPossessive(
        relation: relation,
        gender: gender,
        personAge: age,
        playerAge: playerAge,
      );

  Person copyWith({
    String? firstName,
    String? lastName,
    RelationType? relation,
    int? age,
    bool? isAlive,
    bool? inPlayerHousehold,
    EmploymentStatus? employment,
    Object? occupation = _unset,
    Object? wealth = _unset,
    int? bond,
    Object? schoolLevel = _unset,
    Object? schoolTie = _unset,
    Object? schoolId = _unset,
    Object? classId = _unset,
    Object? city = _unset,
    List<String>? estate,
  }) {
    return Person(
      id: id,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      gender: gender,
      relation: relation ?? this.relation,
      age: age ?? this.age,
      isAlive: isAlive ?? this.isAlive,
      inPlayerHousehold: inPlayerHousehold ?? this.inPlayerHousehold,
      employment: employment ?? this.employment,
      occupation: occupation == _unset ? this.occupation : occupation as String?,
      wealth: wealth == _unset ? this.wealth : wealth as WealthTier?,
      bond: bond ?? this.bond,
      schoolLevel: schoolLevel == _unset
          ? this.schoolLevel
          : schoolLevel as SchoolLevel?,
      schoolTie:
          schoolTie == _unset ? this.schoolTie : schoolTie as SchoolTie?,
      schoolId: schoolId == _unset ? this.schoolId : schoolId as String?,
      classId: classId == _unset ? this.classId : classId as String?,
      city: city == _unset ? this.city : city as String?,
      estate: estate ?? this.estate,
    );
  }
}

const Object _unset = Object();

/// Evcil hayvan (D-004). Kişi değildir; mesleği veya hane dışı yaşamı yoktur.
@immutable
class Pet {
  const Pet({required this.id, required this.name, required this.species});

  final String id;
  final String name;
  final String species;
}

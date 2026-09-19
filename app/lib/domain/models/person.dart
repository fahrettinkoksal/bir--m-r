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

  /// Oyuncuyla ilişki puanı (0-100).
  ///
  /// Prototip aralığıdır; onaylanmış bir denge değeri değildir.
  final int bond;

  String get fullName => '$firstName $lastName';

  /// Çalışma durumunun ekranda gösterilecek hâli. Uydurma meslek üretmez.
  String get occupationLabel {
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

import 'package:flutter/foundation.dart';

import 'education.dart';
import 'gender.dart';
import 'person_development.dart';
import 'relation.dart';
import 'wealth.dart';
import '../../text/turkish_text.dart';

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
    this.happiness = prototypeOnlyDefaultHappiness,
    this.occupation,
    this.schoolLevel,
    this.schoolTie,
    this.schoolId,
    this.classId,
    this.workplaceId,
    this.city,
    this.estate = const <String>[],
    this.development,
    this.infertile = false,
  }) : assert(
          occupation == null || employment == EmploymentStatus.calisiyor,
          'Çalışmayan kişiye meslek atanmaz.',
        );

  /// Bu kişi kısır mı? (Paket 25)
  ///
  /// Romantik bağ kurulurken **gizlice** belirlenir; oyuncuya söylenmez,
  /// ancak denedikçe anlaşılır. Romantik olmayan kişilerde anlamsızdır
  /// ve hep `false` kalır.
  final bool infertile;

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

  /// Birlikte çalışılan işin kimliği (iş arkadaşları için).
  ///
  /// Oyuncu o işten ayrılınca kişi **silinmez**; yalnızca gündelik
  /// erişilebilirliği biter. Arkadaşlığa dönüşen iş arkadaşında bağ türü
  /// değişir, bu alan geçmişin kaydı olarak kalır.
  final String? workplaceId;

  /// Bu kişi şu an çalışılan iş yerinden mi?
  bool isColleagueAt(String? currentJobId) =>
      relation == RelationType.isArkadasi &&
      currentJobId != null &&
      workplaceId == currentJobId;

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

  /// Kişinin **kendi hayatı**: eğitim, meslek, birikim, özellikler ve
  /// yaşanmış dönüm noktaları (D-045).
  ///
  /// Şimdilik yalnızca oyuncunun çocuklarında doludur; diğer kişilerde
  /// `null`'dır ve hiçbir yerde uydurma bilgi gösterilmez.
  final PersonDevelopment? development;

  /// Oyuncuyla ilişki puanı (0-100).
  ///
  /// Prototip aralığıdır; onaylanmış bir denge değeri değildir.
  final int bond;

  /// Kişinin **kendi** keyfi (D-074).
  ///
  /// Bağdan ayrıdır: yakınlık ilişkinin gücüdür, keyif o kişinin şu anki
  /// hâlidir. Birlikte geçirilen iyi bir gün ikisini de yükseltir; uzun
  /// ilgisizlik ikisini de düşürür. Oyuncu bunu kişi kartında görür ve
  /// keyfi düşük kişi daveti **gerçekten reddedebilir** (D-059).
  ///
  /// Eski kayıtlarda yoktur; nötr başlangıçla okunur.
  final int happiness;

  /// prototypeOnly: yeni kişinin ve eski kayıttan okunan kişinin keyfi.
  static const int prototypeOnlyDefaultHappiness = 60;

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
    return trUpperFirst(job);
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
    int? happiness,
    Object? schoolLevel = _unset,
    Object? schoolTie = _unset,
    Object? schoolId = _unset,
    Object? classId = _unset,
    Object? workplaceId = _unset,
    Object? city = _unset,
    List<String>? estate,
    Object? development = _unset,
    bool? infertile,
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
      happiness: (happiness ?? this.happiness).clamp(0, 100),
      schoolLevel: schoolLevel == _unset
          ? this.schoolLevel
          : schoolLevel as SchoolLevel?,
      schoolTie:
          schoolTie == _unset ? this.schoolTie : schoolTie as SchoolTie?,
      schoolId: schoolId == _unset ? this.schoolId : schoolId as String?,
      classId: classId == _unset ? this.classId : classId as String?,
      workplaceId:
          workplaceId == _unset ? this.workplaceId : workplaceId as String?,
      city: city == _unset ? this.city : city as String?,
      estate: estate ?? this.estate,
      development: development == _unset
          ? this.development
          : development as PersonDevelopment?,
      infertile: infertile ?? this.infertile,
    );
  }
}

const Object _unset = Object();

/// Evcil hayvan (D-004). Kişi değildir; mesleği veya hane dışı yaşamı yoktur.
///
/// Paket 40'ta gerçek bir kimlik kazandı: kendi yaşı, sahiplenildiği yaş,
/// hanede olup olmadığı ve **vefat kaydı**. Kayıt asla silinmez; ölen
/// hayvan `diedAtAge` ile işaretlenir ve geçmişte durur.
@immutable
class Pet {
  const Pet({
    required this.id,
    required this.name,
    required this.species,
    this.age = 0,
    this.adoptedAtPlayerAge,
    this.inPlayerHousehold = true,
    this.diedAtAge,
    this.diedAtPlayerAge,
    this.lastCareChargedPlayerAge,
    this.bond = 50,
  });

  final String id;
  final String name;

  /// Tür kimliği (`pet_catalog.dart` içindeki `PetSpecies.id`).
  final String species;

  /// Hayvanın **kendi** yaşı.
  final int age;

  /// Sahiplenildiğinde oyuncunun yaşı.
  ///
  /// `null` ise hayvan oyuncu doğduğunda evde vardı; uydurma bir
  /// sahiplenme yaşı yazılmaz.
  final int? adoptedAtPlayerAge;

  /// Oyuncunun hanesinde mi yaşıyor?
  ///
  /// Kuşak değişiminde yalnızca **aynı hanede** olan hayvan devam eder;
  /// sahte yeni hayvan üretilmez.
  final bool inPlayerHousehold;

  /// Vefat ettiyse hayvanın kendi yaşı.
  final int? diedAtAge;

  /// Vefat ettiyse oyuncunun o andaki yaşı.
  final int? diedAtPlayerAge;

  /// Yıllık bakım gideri **en son** oyuncunun hangi yaşında alındı?
  ///
  /// Aynı yılın gideri ikinci kez alınmasın diye tutulur.
  final int? lastCareChargedPlayerAge;

  /// prototypeOnly: 0-100 arası bağ.
  final int bond;

  bool get isAlive => diedAtAge == null;

  Pet copyWith({
    String? name,
    int? age,
    Object? adoptedAtPlayerAge = _unset,
    bool? inPlayerHousehold,
    Object? diedAtAge = _unset,
    Object? diedAtPlayerAge = _unset,
    Object? lastCareChargedPlayerAge = _unset,
    int? bond,
  }) =>
      Pet(
        id: id,
        name: name ?? this.name,
        species: species,
        age: age ?? this.age,
        adoptedAtPlayerAge: adoptedAtPlayerAge == _unset
            ? this.adoptedAtPlayerAge
            : adoptedAtPlayerAge as int?,
        inPlayerHousehold: inPlayerHousehold ?? this.inPlayerHousehold,
        diedAtAge: diedAtAge == _unset ? this.diedAtAge : diedAtAge as int?,
        diedAtPlayerAge: diedAtPlayerAge == _unset
            ? this.diedAtPlayerAge
            : diedAtPlayerAge as int?,
        lastCareChargedPlayerAge: lastCareChargedPlayerAge == _unset
            ? this.lastCareChargedPlayerAge
            : lastCareChargedPlayerAge as int?,
        bond: bond ?? this.bond,
      );
}

/// Okul kulüpleri ve takımları (Paket AU).
///
/// **Neden var.** Oyunda okul vardı ama okulun *içinde* yapılacak bir şey
/// yoktu. Bu katalog okul hayatına kalıcı bir uğraş ekler ve aynı zamanda
/// profesyonel futbol yolunun temelini atar: profesyonel futbola 18
/// yaşında bir düğmeyle girilmez, çocuklukta kurulmuş gerçek bir futbol
/// geçmişi ister.
///
/// **Hepsi aynı mekanik değil.** Takım sporu ile satranç kulübü aynı şey
/// değildir: biri seçme ister, bedensel gelişim ister, kadro rolü taşır;
/// diğeri doğrudan katılımla başlar ve zihinsel tarafı besler. Katalog bu
/// farkı alanlarla taşır, her kulübe ayrı motor yazmadan.
///
/// **Mevcut hobileri kopyalamaz.** `associatedHobbyId` ile var olan hobiye
/// bağlanır (müzik kulübü → müzik hobisi, robotik → yazılım hobisi). İkinci
/// bir müzik ilerleme motoru yazılmadı.
library;

import 'package:flutter/material.dart';

/// Kulübün kabaca hangi alana düştüğü. Ekranda gruplama için.
enum SchoolClubCategory {
  spor('Spor'),
  akademi('Zihin & Akademi'),
  sanat('Sanat');

  const SchoolClubCategory(this.label);

  final String label;
}

/// Kulübün hangi yetiyi beslediği.
///
/// Tek bir "stat" alanı yerine yakınlık: kulüp o yetiyi **zamanla ve az**
/// besler, her yıl sabit bonus vermez.
enum ClubStatAffinity {
  fiziksel,
  zihinsel,
  sosyal,
  yaratici,
}

/// Bir okul kulübü / takımı.
@immutable
class SchoolClub {
  const SchoolClub({
    required this.id,
    required this.name,
    required this.category,
    required this.minGrade,
    required this.maxGrade,
    required this.statAffinity,
    this.requiresTryout = false,
    this.physical = false,
    this.competitive = false,
    this.associatedSportId,
    this.associatedHobbyId,
    required this.blurb,
  });

  final String id;
  final String name;
  final SchoolClubCategory category;

  /// Kulübün açık olduğu sınıf aralığı.
  ///
  /// Her kulüp her yaşta anlamlı değil: futbol ilkokulun son yıllarından
  /// başlar, münazara daha ileri sınıfta oturur. Bu bir yönetmelik
  /// simülasyonu değil, oyun tasarımı.
  final int minGrade;
  final int maxGrade;

  final ClubStatAffinity statAffinity;

  /// Girişte seçme var mı? Satranç: yok. Futbol: var.
  final bool requiresTryout;

  /// Bedensel uğraş mı? Sakatlık ve sağlık etkisi buna bağlı.
  final bool physical;

  /// Turnuva/müsabaka taşıyor mu? Kadro rolü ve başarı buna bağlı.
  final bool competitive;

  /// Profesyonel spor yoluna bağlanan spor kimliği (şimdilik yalnızca
  /// futbol gerçekten kullanıyor).
  final String? associatedSportId;

  /// Beslediği mevcut hobi (`hobby_catalog.dart`). Yeni ilerleme motoru
  /// yazılmaz; var olan hobi desteklenir.
  final String? associatedHobbyId;

  /// Kulüp kartındaki kısa tanıtım.
  final String blurb;

  /// Verilen sınıf bu kulübe uygun mu?
  bool openForGrade(int grade) => grade >= minGrade && grade <= maxGrade;
}

/// Futbolun spor kimliği. Profesyonel yol bu kimliğe bakar.
const String kFootballSportId = 'futbol';

const List<SchoolClub> kSchoolClubs = <SchoolClub>[
  // ===================================================================
  // SPOR
  // ===================================================================
  SchoolClub(
    id: 'futbol_takimi',
    name: 'Futbol Takımı',
    category: SchoolClubCategory.spor,
    minGrade: 4,
    maxGrade: 12,
    statAffinity: ClubStatAffinity.fiziksel,
    requiresTryout: true,
    physical: true,
    competitive: true,
    associatedSportId: kFootballSportId,
    associatedHobbyId: 'spor',
    blurb: 'Okulun takımı. Seçme var, yedek kalma var, yıllar içinde '
        'kadroda yükselme var.',
  ),
  SchoolClub(
    id: 'basketbol_takimi',
    name: 'Basketbol Takımı',
    category: SchoolClubCategory.spor,
    minGrade: 5,
    maxGrade: 12,
    statAffinity: ClubStatAffinity.fiziksel,
    requiresTryout: true,
    physical: true,
    competitive: true,
    associatedSportId: 'basketbol',
    associatedHobbyId: 'spor',
    blurb: 'Salon, ayakkabı sesi, uzun antrenmanlar.',
  ),
  SchoolClub(
    id: 'voleybol_takimi',
    name: 'Voleybol Takımı',
    category: SchoolClubCategory.spor,
    minGrade: 5,
    maxGrade: 12,
    statAffinity: ClubStatAffinity.fiziksel,
    requiresTryout: true,
    physical: true,
    competitive: true,
    associatedSportId: 'voleybol',
    associatedHobbyId: 'spor',
    blurb: 'Takım oyunu; bir kişi iyi oynayınca değil, altı kişi uyunca '
        'oluyor.',
  ),
  SchoolClub(
    id: 'atletizm',
    name: 'Atletizm',
    category: SchoolClubCategory.spor,
    minGrade: 4,
    maxGrade: 12,
    statAffinity: ClubStatAffinity.fiziksel,
    physical: true,
    competitive: true,
    associatedSportId: 'atletizm',
    associatedHobbyId: 'spor',
    blurb: 'Seçme yok, ölçüm var: kronometre kimseyi kayırmıyor.',
  ),
  SchoolClub(
    id: 'masa_tenisi',
    name: 'Masa Tenisi',
    category: SchoolClubCategory.spor,
    minGrade: 4,
    maxGrade: 12,
    statAffinity: ClubStatAffinity.fiziksel,
    physical: true,
    competitive: true,
    associatedSportId: 'masa_tenisi',
    associatedHobbyId: 'spor',
    blurb: 'Küçük masa, hızlı refleks. Koridorda da oynanır.',
  ),

  // ===================================================================
  // ZİHİN & AKADEMİ
  // ===================================================================
  SchoolClub(
    id: 'satranc_kulubu',
    name: 'Satranç Kulübü',
    category: SchoolClubCategory.akademi,
    minGrade: 3,
    maxGrade: 12,
    statAffinity: ClubStatAffinity.zihinsel,
    competitive: true,
    associatedHobbyId: 'satranc',
    blurb: 'Doğrudan katılım. Turnuvada kaybetmek de öğretiyor.',
  ),
  SchoolClub(
    id: 'munazara_kulubu',
    name: 'Münazara Kulübü',
    category: SchoolClubCategory.akademi,
    minGrade: 7,
    maxGrade: 12,
    statAffinity: ClubStatAffinity.sosyal,
    competitive: true,
    blurb: 'Haklı olmak yetmiyor; anlatmak da gerekiyor.',
  ),
  SchoolClub(
    id: 'bilim_kulubu',
    name: 'Bilim Kulübü',
    category: SchoolClubCategory.akademi,
    minGrade: 5,
    maxGrade: 12,
    statAffinity: ClubStatAffinity.zihinsel,
    competitive: true,
    blurb: 'Deney, proje, bir de bozulan düzeneği tamir etmek.',
  ),
  SchoolClub(
    id: 'robotik_kulubu',
    name: 'Robotik / Yazılım Kulübü',
    category: SchoolClubCategory.akademi,
    minGrade: 6,
    maxGrade: 12,
    statAffinity: ClubStatAffinity.zihinsel,
    competitive: true,
    associatedHobbyId: 'yazilim',
    blurb: 'Çalışmayan kodla geçen akşamlar ve sonunda yürüyen o şey.',
  ),

  // ===================================================================
  // SANAT
  // ===================================================================
  SchoolClub(
    id: 'muzik_kulubu',
    name: 'Müzik Kulübü',
    category: SchoolClubCategory.sanat,
    minGrade: 3,
    maxGrade: 12,
    statAffinity: ClubStatAffinity.yaratici,
    associatedHobbyId: 'muzik',
    blurb: 'Koro ya da enstrüman. Yıl sonu gösterisi kaçınılmaz.',
  ),
  SchoolClub(
    id: 'tiyatro_kulubu',
    name: 'Tiyatro Kulübü',
    category: SchoolClubCategory.sanat,
    minGrade: 4,
    maxGrade: 12,
    statAffinity: ClubStatAffinity.sosyal,
    requiresTryout: true,
    blurb: 'Seçme var ama herkese bir rol çıkar; başrol başka iş.',
  ),
  SchoolClub(
    id: 'fotograf_kulubu',
    name: 'Fotoğrafçılık Kulübü',
    category: SchoolClubCategory.sanat,
    minGrade: 6,
    maxGrade: 12,
    statAffinity: ClubStatAffinity.yaratici,
    associatedHobbyId: 'fotograf',
    blurb: 'Okulun en bilinen köşesini kimse senin çektiğin gibi '
        'görmemiştir.',
  ),
  SchoolClub(
    id: 'halk_oyunlari',
    name: 'Halk Oyunları',
    category: SchoolClubCategory.sanat,
    minGrade: 3,
    maxGrade: 12,
    statAffinity: ClubStatAffinity.fiziksel,
    physical: true,
    associatedHobbyId: 'dans',
    blurb: 'Ayak uydurmak sanıldığından zor; uyduğunda da bırakılmıyor.',
  ),
];

/// Kimliğe göre kulüp (yoksa `null`).
SchoolClub? schoolClubById(String id) {
  for (final SchoolClub c in kSchoolClubs) {
    if (c.id == id) return c;
  }
  return null;
}

/// Verilen sınıfta açık olan kulüpler.
List<SchoolClub> schoolClubsForGrade(int grade) => <SchoolClub>[
      for (final SchoolClub c in kSchoolClubs)
        if (c.openForGrade(grade)) c,
    ];

/// Futbol takımı kulübü (profesyonel yolun giriş kapısı).
SchoolClub get footballClub => kSchoolClubs.firstWhere(
      (SchoolClub c) => c.associatedSportId == kFootballSportId,
    );

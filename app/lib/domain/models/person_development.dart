import 'package:flutter/foundation.dart';

import '../../data/education_tracks.dart';
import '../../data/job_catalog.dart';
import '../../data/university_catalog.dart';
import 'education.dart';
import 'npc_marriage.dart';
import 'stats.dart';

/// Bir kişinin hayatında **gerçekten yaşanmış** bir dönüm noktası.
///
/// Yaşı ve metni birlikte saklanır: ilerleme sonradan yaştan uydurulmaz,
/// gerçekleştiği yılda kaydedilir (D-045).
@immutable
class LifeMilestone {
  const LifeMilestone({required this.age, required this.text});

  final int age;
  final String text;
}

/// Üniversite durumu (NPC için basitleştirilmiş).
enum UniversityStatus {
  okuyor('Üniversitede'),
  bitirdi('Üniversite mezunu'),
  birakti('Üniversiteyi bırakmış');

  const UniversityStatus(this.label);

  final String label;
}

/// Oyuncu tarafından yönetilmeyen bir kişinin **kendi hayatı** (D-045).
///
/// Şimdilik yalnızca oyuncunun çocukları için tutulur: çocuk, oyuncu onu
/// yönetmiyorken de okula başlar, eğitimini ilerletir, ilgi alanı edinir,
/// iş bulur ve kendi birikimini yapar. Kuşak devamında ("Çocuğum olarak
/// devam et") bu kayıt **olduğu gibi** yeni oyuncuya taşınır; 40 yaşında
/// öğretmen olan çocuk "lise mezunu, işsiz" hâline gelmez.
///
/// Oyuncunun bütün mini oyunları burada tekrarlanmaz: mevcut eğitim ve
/// meslek katalogları kullanılır, işlem yükü yılda birkaç dallanmadır.
/// Bütün sayısal değerler `prototypeOnly`'dir (Q-069).
@immutable
class PersonDevelopment {
  const PersonDevelopment({
    required this.stats,
    this.tracksLife = false,
    this.schoolLevel,
    this.grade,
    this.finishedSchool = false,
    this.university,
    this.universityYear,
    this.universityProgramId,
    this.jobId,
    this.jobStartedAtAge,
    this.pastJobIds = const <String>[],
    this.money = 0,
    this.interests = const <String>[],
    this.milestones = const <LifeMilestone>[],
    this.otherParentId,
    this.track,
    this.adopted = false,
    this.marriedAtAge,
    this.spouseName,
    this.spousePersonId,
    this.marriageStatus,
    this.pastMarriages = const <NpcMarriageRecord>[],
  });

  /// Kişinin kendi karakter değerleri (D-046 ile doğumda oluşturulur).
  final Stats stats;

  /// Bu kişinin **hayatı gerçekten izleniyor mu?**
  ///
  /// Oyuncunun çocuklarında `true`'dur: eğitim, meslek ve birikim yıl yıl
  /// işlenir, miras bu gerçek birikimden dağıtılır. Yalnızca özellik
  /// kaydı açılmış kişilerde (ör. çocuğun diğer ebeveyni, D-046) `false`
  /// kalır; onların ekonomik durumu eskisi gibi tahminle gösterilir ve
  /// **uydurma bir birikim** yazılmaz.
  final bool tracksLife;

  /// Devam edilen okul kademesi; okumuyorsa `null`.
  final SchoolLevel? schoolLevel;

  /// Kaçıncı sınıf (1-12); okumuyorsa `null`.
  final int? grade;

  /// Lise bitirildi mi?
  final bool finishedSchool;

  /// Üniversite durumu; hiç gitmediyse `null`.
  final UniversityStatus? university;

  /// Üniversitede kaçıncı yıl.
  final int? universityYear;

  /// Okuduğu bölümün kimliği ([kUniversityPrograms]).
  ///
  /// Bölüm, üniversiteye başlandığı yıl **gerçekten seçilir**; kuşak
  /// devamında oyuncunun eğitim kaydına aynen taşınır, sonradan
  /// uydurulmaz.
  final String? universityProgramId;

  /// Şu anki işin kimliği ([kJobCatalog]); çalışmıyorsa `null`.
  final String? jobId;
  final int? jobStartedAtAge;

  /// Daha önce çalıştığı işler; kayıt silinmez.
  final List<String> pastJobIds;

  /// Kişinin **kendi** birikimi (₺).
  final int money;

  /// Edindiği ilgi alanları.
  final List<String> interests;

  /// Yaşanmış dönüm noktaları (en eskisi başta).
  final List<LifeMilestone> milestones;

  /// Çocuğun **diğer biyolojik ebeveyninin** kişi kimliği.
  ///
  /// Evlilik dışı doğan çocukta da (D-047) iki ebeveyn kayıtlıdır; bu
  /// bağ evlilik kaydına değil, doğum anındaki gerçek ebeveyne dayanır ve
  /// kuşak geçişinde aile bağlarının doğru kurulmasını sağlar. Evlat
  /// edinilen çocukta `null`'dır (uydurma bir biyolojik ebeveyn
  /// yazılmaz).
  final String? otherParentId;

  /// Lisede seçtiği alan (D-045).
  ///
  /// Alan, 9. sınıfa geçilen yıl **gerçekten seçilir**; üniversite
  /// bölümünü ve kuşak devamında oyuncunun eğitim kaydını etkiler.
  final EducationTrack? track;

  /// Bu kişi **evlat edinildi mi?**
  ///
  /// Evlat edinilen çocuk her bakımdan çocuktur: hanede, giderde,
  /// mirasta ve vasiyette eşittir (D-049). Bu alan yalnızca kaydın
  /// doğru anlatılması içindir; uydurma bir biyolojik ebeveyn yazılmaz.
  final bool adopted;

  /// Bu kişinin **kendi** evlendiği yaş (D-121).
  ///
  /// Faho'nun isteği: "çocuğum evlendiğinde pop-up olarak bildirilsin".
  /// Çocuklar artık kendi hayatlarında evleniyor; kayıt burada durur ve
  /// kuşak devamında olduğu gibi taşınır.
  final int? marriedAtAge;

  /// Evlendiği kişinin adı.
  ///
  /// Paket AP'ye kadar oyuncunun hayatına giren **yalnızca bu ad**dı.
  /// Artık yeni evliliklerde eş gerçek bir [Person] olarak kayda giriyor
  /// ([spousePersonId]) ve bu alan onun adını taşıyor. Alan korundu
  /// çünkü Paket AP öncesinde kurulmuş kayıtlarda elimizdeki tek bilgi
  /// bu (§17) — o kayıtlara geriye dönük NPC uydurulmaz.
  final String? spouseName;

  /// Eşin kalıcı kişi kimliği; eski kayıtlarda `null` (§17).
  final String? spousePersonId;

  /// Bu kişinin **şu anki** evlilik durumu.
  ///
  /// `null` iki şey demek olabilir: hiç evlenmemiş, **ya da** Paket AP
  /// öncesinde kurulmuş bir kayıt. İkisini [marriedAtAge] ayırır ve
  /// [isMarried] bu ayrımı yapar.
  final NpcMarriageStatus? marriageStatus;

  /// Bitmiş evlilikler; en eskisi başta. Kayıt silinmez (§18).
  final List<NpcMarriageRecord> pastMarriages;

  /// Şu anda yürüyen bir evliliği var mı?
  ///
  /// **Paket AP'de düzeltilen kabul:** eskiden `marriedAtAge != null`
  /// yeterliydi, yani bir kez evlenen kişi sonsuza kadar evli sayılıyordu.
  /// Artık çocuk boşanabiliyor ve dul kalabiliyor (§18-§19), o yüzden
  /// ölçü durumun kendisi.
  ///
  /// Eski kayıt uyumu: durumu yazılmamış ama evlilik yaşı olan kayıt
  /// **evli** sayılır — Paket AP öncesinde boşanma yolu hiç yoktu.
  bool get isMarried => marriageStatus == null
      ? marriedAtAge != null
      : marriageStatus == NpcMarriageStatus.evli;

  /// Boşanmış mı? (Yürüyen evliliği yok ve geçmişinde boşanma var.)
  bool get isDivorced => marriageStatus == NpcMarriageStatus.bosandi;

  /// Eşini kaybetmiş mi?
  bool get isWidowed => marriageStatus == NpcMarriageStatus.dul;

  /// Hiç evlenmiş mi? (Yürüyen ya da geçmiş.)
  bool get hasEverMarried =>
      marriedAtAge != null || pastMarriages.isNotEmpty;

  /// Yeniden evlenebilir mi? (§23 — yürüyen evlilik varken olmaz.)
  bool get canRemarry => !isMarried && hasEverMarried;

  bool get isStudent => grade != null;
  bool get isUniversityStudent => university == UniversityStatus.okuyor;
  bool get isEmployed => jobId != null;

  JobType? get job => jobId == null ? null : jobById(jobId!);

  /// Okuduğu bölüm; bilinmiyorsa `null`.
  UniversityProgram? get program => universityProgramId == null
      ? null
      : universityProgramById(universityProgramId!);

  /// Seçtiği alanın bilgisi; seçilmediyse `null`.
  EducationTrackInfo? get trackDetails =>
      track == null ? null : trackInfo(track!);

  /// Ekranda gösterilecek eğitim özeti.
  String get educationLabel {
    if (grade != null) {
      final SchoolLevel? kademe = schoolLevel;
      final String alan =
          trackDetails == null ? '' : ' · ${trackDetails!.label}';
      if (kademe == null) return '$grade. sınıf$alan';
      return '${kademe.label} ${kademe.gradeWithinLevel(grade!)}. sınıf$alan';
    }
    switch (university) {
      case UniversityStatus.okuyor:
        return '${program?.name ?? 'Üniversite'} ${universityYear ?? 1}. sınıf';
      case UniversityStatus.bitirdi:
        return '${program?.name ?? 'Üniversite'} mezunu';
      case UniversityStatus.birakti:
        return '${program?.name ?? 'Üniversite'} yarıda kaldı';
      case null:
        break;
    }
    if (finishedSchool) return 'Liseyi bitirdi';
    return 'Okula başlamadı';
  }

  PersonDevelopment copyWith({
    Stats? stats,
    bool? tracksLife,
    Object? schoolLevel = _unsetDev,
    Object? grade = _unsetDev,
    bool? finishedSchool,
    Object? university = _unsetDev,
    Object? universityYear = _unsetDev,
    Object? universityProgramId = _unsetDev,
    Object? jobId = _unsetDev,
    Object? jobStartedAtAge = _unsetDev,
    List<String>? pastJobIds,
    int? money,
    List<String>? interests,
    List<LifeMilestone>? milestones,
    Object? otherParentId = _unsetDev,
    Object? track = _unsetDev,
    bool? adopted,
    Object? marriedAtAge = _unsetDev,
    Object? spouseName = _unsetDev,
    Object? spousePersonId = _unsetDev,
    Object? marriageStatus = _unsetDev,
    List<NpcMarriageRecord>? pastMarriages,
  }) {
    return PersonDevelopment(
      stats: stats ?? this.stats,
      tracksLife: tracksLife ?? this.tracksLife,
      schoolLevel: schoolLevel == _unsetDev
          ? this.schoolLevel
          : schoolLevel as SchoolLevel?,
      grade: grade == _unsetDev ? this.grade : grade as int?,
      finishedSchool: finishedSchool ?? this.finishedSchool,
      university: university == _unsetDev
          ? this.university
          : university as UniversityStatus?,
      universityYear: universityYear == _unsetDev
          ? this.universityYear
          : universityYear as int?,
      universityProgramId: universityProgramId == _unsetDev
          ? this.universityProgramId
          : universityProgramId as String?,
      jobId: jobId == _unsetDev ? this.jobId : jobId as String?,
      jobStartedAtAge: jobStartedAtAge == _unsetDev
          ? this.jobStartedAtAge
          : jobStartedAtAge as int?,
      pastJobIds: pastJobIds ?? this.pastJobIds,
      money: money ?? this.money,
      interests: interests ?? this.interests,
      milestones: milestones ?? this.milestones,
      otherParentId: otherParentId == _unsetDev
          ? this.otherParentId
          : otherParentId as String?,
      track: track == _unsetDev ? this.track : track as EducationTrack?,
      adopted: adopted ?? this.adopted,
      marriedAtAge: marriedAtAge == _unsetDev
          ? this.marriedAtAge
          : marriedAtAge as int?,
      spouseName:
          spouseName == _unsetDev ? this.spouseName : spouseName as String?,
      spousePersonId: spousePersonId == _unsetDev
          ? this.spousePersonId
          : spousePersonId as String?,
      marriageStatus: marriageStatus == _unsetDev
          ? this.marriageStatus
          : marriageStatus as NpcMarriageStatus?,
      pastMarriages: pastMarriages ?? this.pastMarriages,
    );
  }

  /// Yeni bir dönüm noktası ekler.
  PersonDevelopment withMilestone(int age, String text) => copyWith(
        milestones: List<LifeMilestone>.unmodifiable(<LifeMilestone>[
          ...milestones,
          LifeMilestone(age: age, text: text),
        ]),
      );
}

const Object _unsetDev = Object();

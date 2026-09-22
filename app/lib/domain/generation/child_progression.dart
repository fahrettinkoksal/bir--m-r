import 'dart:math';

import '../../data/education_tracks.dart';
import '../../data/job_catalog.dart';
import '../../data/university_catalog.dart';
import '../life/aging.dart';
import '../models/education.dart';
import '../models/person.dart';
import '../models/person_development.dart';
import '../models/stats.dart';
import '../models/wealth.dart';
import 'random_util.dart';

/// Çocuğun **arka planda gerçekten büyümesi** (D-045).
///
/// Oyuncu çocuğu yönetmiyorken de çocuk kendi hayatını yaşar: yaşı gelince
/// okula başlar, sınıf atlar, liseyi bitirir, koşullar uygunsa üniversiteye
/// gider, ilgi alanı edinir, iş bulur ve kendi birikimini yapar.
///
/// İlkeler:
/// - **Geçmiş uydurulmaz.** Her ilerleme *gerçekleştiği yılda*
///   [PersonDevelopment.milestones] içine yazılır; yaşa bakıp sonradan
///   "demek ki üniversiteyi bitirmiştir" denmez.
/// - Oyuncunun mini oyunları tekrarlanmaz: mevcut [kJobCatalog] ve okul
///   kademeleri kullanılır, yıllık iş yükü birkaç dallanmadır.
/// - Sonuçlar çocuğun özelliklerine, geçmişine ve bir miktar rastgeleliğe
///   bağlıdır; **her çocuk otomatik olarak başarılı veya zengin olmaz**.
/// - Vefat etmiş kişi için hiçbir gelişim işlemi yapılmaz.
///
/// Bütün sayılar `prototypeOnly`'dir (`docs/DESIGN_REVIEW_QUEUE.md`, Q-069).
abstract final class ChildProgression {
  /// prototypeOnly: okula başlama yaşı (oyuncununkiyle aynı).
  static const int prototypeOnlySchoolStartAge = 6;

  /// prototypeOnly: lise bitiş yaşı için güvenlik sınırı.
  static const int prototypeOnlyMaxSchoolAge = 19;

  /// prototypeOnly: üniversite kararının verilebileceği en geç yaş.
  static const int prototypeOnlyUniversityDecisionAge = 21;

  /// prototypeOnly: üniversite kaç yıl sürer.
  static const int prototypeOnlyUniversityYears = 4;

  /// prototypeOnly: emeklilik yaşı.
  static const int prototypeOnlyRetirementAge = 65;

  /// prototypeOnly: çalışan bir NPC'nin yıllık gideri (₺).
  ///
  /// Birikim maaştan bu gider düşülerek oluşur; böylece her çalışan çocuk
  /// otomatik olarak zengin olmaz.
  static const int prototypeOnlyYearlyCost = 140000;

  /// prototypeOnly: iş arayan bir yılda iş bulma olasılığı.
  static const double prototypeOnlyJobChance = 0.45;

  /// prototypeOnly: bir yılda işi kaybetme olasılığı.
  static const double prototypeOnlyJobLossChance = 0.03;

  /// prototypeOnly: bir yılda yeni ilgi alanı edinme olasılığı.
  static const double prototypeOnlyInterestChance = 0.18;

  /// prototypeOnly: en fazla kaç ilgi alanı.
  static const int prototypeOnlyMaxInterests = 3;

  /// prototypeOnly: kayıt şişmesin diye saklanan en fazla dönüm noktası.
  static const int prototypeOnlyMaxMilestones = 40;

  /// prototypeOnly: edinilebilecek ilgi alanları.
  static const List<String> prototypeOnlyInterests = <String>[
    'müzik',
    'futbol',
    'resim',
    'kitap',
    'bilgisayar',
    'yüzme',
    'fotoğraf',
    'satranç',
  ];

  /// Kişinin gelişim kaydı yoksa **yaşına uygun** bir kayıt açar.
  ///
  /// Eski kayıtlardan gelen çocuklar için kullanılır. Geçmiş **uydurulmaz**:
  /// dönüm noktası listesi boş başlar, birikim sıfırdır. Yalnızca bugünkü
  /// durum (hangi sınıfta olduğu, liseyi bitirmiş sayılıp sayılmayacağı)
  /// yaşından kurulur, çünkü bu bilgi zaten ekranda gösteriliyordu.
  static PersonDevelopment ensureRecord(Person person, Random rng) {
    final PersonDevelopment? mevcut = person.development;
    if (mevcut != null && mevcut.tracksLife) return mevcut;

    final int age = person.age;
    SchoolLevel? kademe;
    int? sinif;
    bool liseBitti = false;
    if (age >= prototypeOnlySchoolStartAge && age < prototypeOnlyMaxSchoolAge) {
      sinif = (age - prototypeOnlySchoolStartAge + 1).clamp(1, 12);
      kademe = SchoolLevel.forGrade(sinif);
    } else if (age >= prototypeOnlyMaxSchoolAge) {
      liseBitti = true;
    }

    // Eski kayıtta kişinin mesleği serbest metindi; katalogda karşılığı
    // varsa bağlanır, yoksa iş kaydı açılmaz (uydurma iş yazılmaz).
    String? isKimligi;
    if (person.employment == EmploymentStatus.calisiyor) {
      for (final JobType job in kJobCatalog) {
        if (job.name == person.occupation) {
          isKimligi = job.id;
          break;
        }
      }
    }

    return PersonDevelopment(
      // Eski kayıttan gelen çocuğun hayatı bundan sonra izlenir.
      tracksLife: true,
      stats: mevcut?.stats ?? _prototypeOnlyNeutralStats(rng),
      schoolLevel: kademe,
      grade: sinif,
      finishedSchool: liseBitti,
      jobId: isKimligi,
      jobStartedAtAge: isKimligi == null ? null : age,
    );
  }

  /// prototypeOnly: özellik bilgisi olmayan kişi için nötr değerler.
  ///
  /// Yalnızca eski kayıtlar içindir; yeni doğan çocuğun özellikleri
  /// ebeveynlerinden gelir (D-046, Paket 2).
  static Stats _prototypeOnlyNeutralStats(Random rng) => Stats(
        appearance: rng.between(25, 85),
        happiness: rng.between(45, 85),
        health: rng.between(40, 90),
        intelligence: rng.between(25, 85),
        charisma: rng.between(25, 85),
      );

  /// Kişiyi **bir yıl** ilerletir.
  ///
  /// [person] yaşı **zaten artırılmış** olarak verilir. Dönen `news`
  /// satırları oyuncunun hayat günlüğüne yazılabilecek aile haberleridir;
  /// aynı satırlar kişinin kendi geçmişine de işlenir.
  static ({Person person, List<String> news}) advance(
    Person person,
    Random rng,
  ) {
    if (!person.isAlive) return (person: person, news: const <String>[]);

    final int age = person.age;
    PersonDevelopment dev = ensureRecord(person, rng);
    final List<String> haberler = <String>[];
    final String ad = person.firstName;

    void kaydet(String metin) {
      dev = dev.withMilestone(age, metin);
      haberler.add(metin);
    }

    // --- Okul -----------------------------------------------------------
    if (dev.grade == null &&
        !dev.finishedSchool &&
        dev.university == null &&
        age >= prototypeOnlySchoolStartAge) {
      if (age >= prototypeOnlyMaxSchoolAge) {
        // Okul çağını geçmiş ve kaydı olmayan kişi (eski kayıt) için
        // geçmiş uydurulmaz; yalnızca bugünkü durum kurulur.
        dev = dev.copyWith(finishedSchool: true);
      } else {
        final int sinif =
            (age - prototypeOnlySchoolStartAge + 1).clamp(1, 12);
        dev = dev.copyWith(
          grade: sinif,
          schoolLevel: SchoolLevel.forGrade(sinif),
        );
        // Dönüm noktası yalnızca **gerçekten o yıl** başlandıysa yazılır.
        if (age == prototypeOnlySchoolStartAge) kaydet('$ad okula başladı.');
      }
    } else if (dev.grade != null) {
      final int yeniSinif = dev.grade! + 1;
      if (yeniSinif > 12 || age >= prototypeOnlyMaxSchoolAge) {
        dev = dev.copyWith(
          grade: null,
          schoolLevel: null,
          finishedSchool: true,
        );
        kaydet('$ad liseyi bitirdi.');
      } else {
        final SchoolLevel? eski = dev.schoolLevel;
        final SchoolLevel? yeni = SchoolLevel.forGrade(yeniSinif);
        dev = dev.copyWith(grade: yeniSinif, schoolLevel: yeni);
        if (yeni != null && yeni != eski) {
          kaydet('$ad ${yeni.label.toLowerCase()} sıralarına geçti.');
        }
        // Liseye geçen çocuk alanını **o yıl** seçer; sonradan
        // uydurulmaz (D-045).
        if (yeni == SchoolLevel.lise && dev.track == null) {
          final EducationTrackInfo alan = _pickTrack(dev, rng);
          dev = dev.copyWith(track: alan.track);
          kaydet('$ad lisede ${alan.label.toLowerCase()} alanını seçti.');
        }
      }
    }

    // --- Üniversite ------------------------------------------------------
    if (dev.university == UniversityStatus.okuyor) {
      final int yil = (dev.universityYear ?? 1) + 1;
      if (yil > prototypeOnlyUniversityYears) {
        final double bitirmeSansi =
            (0.45 + dev.stats.intelligence / 200).clamp(0.3, 0.95);
        if (rng.chance(bitirmeSansi)) {
          dev = dev.copyWith(
            university: UniversityStatus.bitirdi,
            universityYear: null,
          );
          kaydet('$ad üniversiteyi bitirdi.');
        } else {
          dev = dev.copyWith(
            university: UniversityStatus.birakti,
            universityYear: null,
          );
          kaydet('$ad üniversiteyi tamamlayamadı.');
        }
      } else {
        dev = dev.copyWith(universityYear: yil);
      }
    } else if (dev.finishedSchool &&
        dev.university == null &&
        !dev.isEmployed &&
        age >= 18 &&
        age <= prototypeOnlyUniversityDecisionAge) {
      // Üniversiteye gitme eğilimi zekâyla artar ama garanti değildir.
      final double sans =
          ((dev.stats.intelligence - 35) / 100).clamp(0.05, 0.7);
      if (rng.chance(sans)) {
        // Bölüm **o yıl gerçekten seçilir**; sonradan uydurulmaz.
        final UniversityProgram bolum = _pickProgram(dev, rng);
        dev = dev.copyWith(
          university: UniversityStatus.okuyor,
          universityYear: 1,
          universityProgramId: bolum.id,
        );
        kaydet('$ad ${bolum.name.toLowerCase()} bölümünde okumaya başladı.');
      }
    }

    // --- İş ---------------------------------------------------------------
    if (dev.isEmployed) {
      final JobType? is_ = dev.job;
      if (age >= prototypeOnlyRetirementAge) {
        dev = dev.copyWith(
          jobId: null,
          jobStartedAtAge: null,
          pastJobIds: List<String>.unmodifiable(<String>[
            ...dev.pastJobIds,
            if (dev.jobId != null) dev.jobId!,
          ]),
        );
        kaydet('$ad emekli oldu.');
      } else if (rng.chance(prototypeOnlyJobLossChance)) {
        dev = dev.copyWith(
          jobId: null,
          jobStartedAtAge: null,
          pastJobIds: List<String>.unmodifiable(<String>[
            ...dev.pastJobIds,
            if (dev.jobId != null) dev.jobId!,
          ]),
        );
        kaydet('$ad işinden ayrılmak zorunda kaldı.');
      } else if (is_ != null) {
        // Birikim: maaştan kendi yaşam gideri düşülür.
        final int kalan = is_.yearlySalary - prototypeOnlyYearlyCost;
        dev = dev.copyWith(money: (dev.money + kalan).clamp(0, 1 << 40));
      }
    } else if (age >= 18 &&
        age < prototypeOnlyRetirementAge &&
        !dev.isStudent &&
        !dev.isUniversityStudent &&
        rng.chance(prototypeOnlyJobChance)) {
      final JobType? bulunan = _findJob(dev, age, rng);
      if (bulunan != null) {
        dev = dev.copyWith(jobId: bulunan.id, jobStartedAtAge: age);
        kaydet('$ad ${bulunan.name.toLowerCase()} olarak işe başladı.');
      }
    }

    // --- İlgi alanları -----------------------------------------------------
    if (age >= 8 &&
        age <= 35 &&
        dev.interests.length < prototypeOnlyMaxInterests &&
        rng.chance(prototypeOnlyInterestChance)) {
      final List<String> bos = prototypeOnlyInterests
          .where((String i) => !dev.interests.contains(i))
          .toList(growable: false);
      if (bos.isNotEmpty) {
        final String yeni = rng.pick(bos);
        dev = dev.copyWith(
          interests: List<String>.unmodifiable(<String>[...dev.interests, yeni]),
        );
        kaydet('$ad $yeni ile ilgilenmeye başladı.');
      }
    }

    // --- Özellikler ---------------------------------------------------------
    dev = dev.copyWith(stats: _driftStats(dev, age, rng));

    // Kayıt şişmesin: en eski dönüm noktaları düşer (sınır cömerttir).
    if (dev.milestones.length > prototypeOnlyMaxMilestones) {
      dev = dev.copyWith(
        milestones: List<LifeMilestone>.unmodifiable(
          dev.milestones
              .sublist(dev.milestones.length - prototypeOnlyMaxMilestones),
        ),
      );
    }

    return (person: _sync(person, dev), news: haberler);
  }

  /// prototypeOnly: NPC'nin lisede seçeceği alan.
  ///
  /// Oyuncunun yerleştirme sınavı burada tekrarlanmaz; alan, kişinin
  /// **kendi değerlerinden** türetilen bir puana göre seçilir.
  static EducationTrackInfo _pickTrack(PersonDevelopment dev, Random rng) {
    final int puan = ((dev.stats.intelligence * 0.7) +
            (dev.stats.charisma * 0.3) +
            rng.between(-10, 10))
        .round()
        .clamp(0, 100);
    final List<EducationTrackInfo> uygun = kEducationTracks
        .where((EducationTrackInfo t) => puan >= t.minScore)
        .toList(growable: false);
    if (uygun.isEmpty) {
      return kEducationTracks.firstWhere(
        (EducationTrackInfo t) => t.track == EducationTrack.genelAkademik,
      );
    }
    return rng.pick(uygun);
  }

  /// prototypeOnly: NPC'nin okuyacağı bölüm.
  ///
  /// Zekâsı yüksek kişi daha yüksek puanlı bölümlere yönelir; lisede
  /// seçtiği alanla uyumlu bölümler öne çıkar. Seçim yine de garanti
  /// değildir.
  static UniversityProgram _pickProgram(PersonDevelopment dev, Random rng) {
    final List<UniversityProgram> uygun = kUniversityPrograms
        .where((UniversityProgram p) => dev.stats.intelligence + 15 >= p.minScore)
        .toList(growable: false);
    if (uygun.isEmpty) return rng.pick(kUniversityPrograms);

    // Lisede seçtiği alan bölüm tercihini etkiler.
    final EducationTrack? alan = dev.track;
    if (alan != null) {
      final List<UniversityProgram> alanla = uygun
          .where((UniversityProgram p) => p.preferredTracks.contains(alan))
          .toList(growable: false);
      if (alanla.isNotEmpty && rng.chance(0.7)) return rng.pick(alanla);
    }
    return rng.pick(uygun);
  }

  /// Eğitim ve yaşa göre küçük özellik değişimi.
  ///
  /// Yaşlanmanın dış görünüşe etkisi **oyuncuyla aynı kuralla** işler
  /// (D-051): kendi hayatı izlenen kişiler de yıllar içinde değişir.
  static Stats _driftStats(PersonDevelopment dev, int age, Random rng) {
    Stats stats = dev.stats;
    if ((dev.isStudent || dev.isUniversityStudent) && rng.chance(0.35)) {
      stats = stats.copyWith(intelligence: stats.intelligence + 1);
    }
    if (age > 50 && rng.chance(0.4)) {
      stats = stats.copyWith(health: stats.health - 1);
    }
    final int gorunus = Aging.yearlyDelta(
      age: age,
      appearance: stats.appearance,
      health: stats.health,
      rng: rng,
    );
    if (gorunus != 0) {
      stats = stats.copyWith(appearance: stats.appearance + gorunus);
    }
    return stats;
  }

  /// Koşullarına uyan işlerden birini seçer; uygun iş yoksa `null`.
  static JobType? _findJob(PersonDevelopment dev, int age, Random rng) {
    final List<JobType> uygun = kJobCatalog.where((JobType job) {
      if (age < job.minAge) return false;
      // Dövüş sanatı eğitmenliği oyuncunun yıllarca çalışmasıyla açılır;
      // yan karakterlere rastgele dağıtılmaz (Paket 32).
      if (job.martialArtId != null) return false;
      if (dev.stats.intelligence < job.minIntelligence) return false;
      if (dev.stats.charisma < job.minCharisma) return false;
      switch (job.education) {
        case JobEducation.yok:
          return true;
        case JobEducation.lise:
          return dev.finishedSchool;
        case JobEducation.universite:
          return dev.university == UniversityStatus.bitirdi;
      }
    }).toList(growable: false);
    if (uygun.isEmpty) return null;

    final List<JobType> sirali = <JobType>[...uygun]
      ..sort((JobType a, JobType b) => b.yearlySalary.compareTo(a.yearlySalary));
    // Zekâsı yüksek kişi daha iyi işe yönelir; yine de garanti değildir.
    if (rng.chance((dev.stats.intelligence / 130).clamp(0.1, 0.8))) {
      return sirali.first;
    }
    return rng.pick(sirali);
  }

  /// Gelişim kaydını kişinin görünen alanlarıyla eşitler.
  ///
  /// Ekranda gösterilen meslek, okul kademesi ve ekonomik durum artık
  /// **gerçek kayıttan** gelir; iki yerde farklı gerçeklik oluşmaz (D-038).
  static Person _sync(Person person, PersonDevelopment dev) {
    final EmploymentStatus durum;
    if (dev.isEmployed) {
      durum = EmploymentStatus.calisiyor;
    } else if (dev.isStudent || dev.isUniversityStudent) {
      durum = EmploymentStatus.ogrenci;
    } else if (person.age < prototypeOnlySchoolStartAge) {
      durum = EmploymentStatus.cocuk;
    } else if (person.age >= prototypeOnlyRetirementAge) {
      durum = EmploymentStatus.emekli;
    } else {
      durum = EmploymentStatus.issiz;
    }

    return person.copyWith(
      development: dev,
      employment: durum,
      occupation: durum == EmploymentStatus.calisiyor ? dev.job?.name : null,
      schoolLevel: dev.schoolLevel,
      wealth: person.age < 18 ? null : prototypeOnlyWealthFor(dev.money),
    );
  }

  /// prototypeOnly: birikimden ekonomik durum etiketi.
  static WealthTier prototypeOnlyWealthFor(int money) {
    if (money >= 3000000) return WealthTier.cokVarlikli;
    if (money >= 900000) return WealthTier.varlikli;
    if (money >= 200000) return WealthTier.ortaHalli;
    if (money >= 30000) return WealthTier.yoksul;
    return WealthTier.cokYoksul;
  }
}

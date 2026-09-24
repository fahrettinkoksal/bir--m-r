/// Meslek kataloğu.
///
/// Maaşlar **2026 Türkiye alım gücüne** göre kalibre edildi (Faho onayı,
/// Q-113 ve ekonomi kararı). Her işin bir [SalaryBand] bandı vardır ve
/// `test/economy_calibration_test.dart` maaşın bandın içinde kaldığını
/// denetler. Çıpa: net yıllık asgari ücret
/// [Economy.netYearlyMinimumWage].
///
/// **Bant bir gelir sınıfıdır, bir prestij sırası değildir.** Üniversite
/// isteyen bir meslek (öğretmen) ofis bandında olabilir; bandı belirleyen
/// eğitim değil, işin getirdiği paradır.
///
/// Ayrıntılı eski/yeni karşılaştırması: `docs/ECONOMY_2026.md`.
library;

import 'package:flutter/foundation.dart';

import 'economy.dart';
import 'education_tracks.dart';

/// İşin gerektirdiği asgari eğitim.
enum JobEducation {
  yok('Eğitim şartı yok'),
  lise('Lise mezunu'),
  universite('Üniversite mezunu');

  const JobEducation(this.label);

  final String label;
}

@immutable
class JobType {
  const JobType({
    required this.id,
    required this.name,
    required this.description,
    required this.minAge,
    required this.yearlySalary,
    required this.band,
    this.education = JobEducation.yok,
    this.tracks = const <EducationTrack>{},
    this.programs = const <String>{},
    this.minIntelligence = 0,
    this.minCharisma = 0,
    this.minAppearance = 0,
    this.levels = const <String>[],
    this.martialArtId,
    this.hobbyId,
    this.minHobbyStage = 0,
    this.requiredLicenses = const <String>{},
  });

  final String id;
  final String name;
  final String description;
  final int minAge;

  /// Bir oyun yılında cüzdana giren giriş seviyesi tutarı
  /// (₺, 2026 alım gücü).
  ///
  /// Terfi ve zamlar bunun üstüne biner; bu, işe **ilk girildiğinde**
  /// geçerli olan tutardır.
  final int yearlySalary;

  /// İşin gelir sınıfı. Maaş bu bandın dışına çıkamaz.
  final SalaryBand band;

  /// Giriş maaşının kabaca aylık karşılığı (₺).
  ///
  /// Motor yıllık hesapla çalışır; bu yalnızca ekranda gösterilir.
  int get monthlySalary => Economy.monthlyOf(yearlySalary);

  final JobEducation education;

  /// Bu lise alanlarından biri işe uygunluk sağlar (boşsa alan aranmaz).
  final Set<EducationTrack> tracks;

  /// Bu üniversite bölümlerinden biri işe uygunluk sağlar.
  final Set<String> programs;

  final int minIntelligence;
  final int minCharisma;

  /// prototypeOnly: işe girmek için gereken en az görünüş.
  ///
  /// Yalnızca görünüşün mesleğin kendisi olduğu işlerde kullanılır.
  final int minAppearance;

  /// Bu meslekteki görev basamakları (giriş seviyesinden yukarı).
  ///
  /// İlk sıra işe girildiğinde geçerli olan unvandır. Boş bırakılırsa
  /// mesleğin adı tek unvan sayılır. Basamaklar `prototypeOnly`'dir
  /// (Q-078); meslek kataloğu büyütülmeden yalnızca unvan eklenir.
  final List<String> levels;

  /// Bu iş bir dövüş sanatı eğitmenliğiyse o sanatın kimliği (Paket 32).
  ///
  /// Doluysa iş yalnızca o sanatta eğitmenlik basamağına gelmiş oyuncuya
  /// açılır; katalogdaki eşik `MartialArt.instructorFromLevel`'dir.
  final String? martialArtId;

  /// Bu iş bir hobinin birikmesiyle açılıyorsa o hobinin kimliği.
  ///
  /// [martialArtId] ile aynı mantık: diplomayla değil, yıllarca
  /// yapılmış bir uğraşla girilen meslekler içindir. Yazarlık okuma,
  /// müzisyenlik müzik hobisine bağlıdır.
  final String? hobbyId;

  /// prototypeOnly: [hobbyId] hobisinde ulaşılmış olması gereken basamak.
  final int minHobbyStage;

  /// İşe girmek için gereken ehliyetler ([LicenseType.id]).
  ///
  /// Kuryelik gibi, aracı kullanmanın işin kendisi olduğu mesleklerde
  /// aranır. Ehliyetsiz oyuncuya iş açılmaz; gerekçesi yazılır.
  final Set<String> requiredLicenses;

  /// Bu meslekte çıkılabilecek en üst basamak.
  int get maxLevel => levels.isEmpty ? 0 : levels.length - 1;
}

/// Bir meslekte [level] basamağındaki görev adı.
///
/// Seviye listesi yoksa ya da aralık dışındaysa mesleğin kendi adı
/// kullanılır; uydurma unvan üretilmez.
String jobTitleFor(JobType job, int level) {
  if (job.levels.isEmpty) return job.name;
  final int i = level.clamp(0, job.levels.length - 1);
  return job.levels[i];
}

const List<JobType> kJobCatalog = <JobType>[
  // ===================================================================
  // Hizmet ve giriş seviyesi
  // ===================================================================
  JobType(
    id: 'magaza_calisani',
    name: 'Mağaza çalışanı',
    description: 'Raf düzeni, kasa ve ayakta geçen uzun saatler.',
    minAge: 16,
    yearlySalary: 352000,
    band: SalaryBand.giris,
    levels: <String>[
      'Mağaza çalışanı',
      'Kıdemli mağaza çalışanı',
      'Mağaza sorumlusu',
    ],
  ),
  JobType(
    id: 'kasiyer',
    name: 'Kasiyer',
    description: 'Bant, barkod ve gün sonu sayımı.',
    minAge: 17,
    yearlySalary: 340000,
    band: SalaryBand.giris,
    levels: <String>['Kasiyer', 'Kıdemli kasiyer', 'Kasa sorumlusu'],
  ),
  JobType(
    id: 'garson',
    name: 'Garson',
    description: 'Tepsi, sipariş, akşam vardiyası.',
    minAge: 16,
    yearlySalary: 344000,
    band: SalaryBand.giris,
    minCharisma: 35,
    levels: <String>['Garson', 'Deneyimli garson', 'Servis şefi'],
  ),
  JobType(
    id: 'kurye',
    name: 'Kurye',
    description: 'Trafik, saat baskısı ve her hava koşulu.',
    minAge: 18,
    yearlySalary: 378000,
    band: SalaryBand.giris,
    requiredLicenses: <String>{'motosiklet_ehliyeti'},
    levels: <String>['Kurye', 'Kıdemli kurye', 'Dağıtım sorumlusu'],
  ),
  JobType(
    id: 'depo_personeli',
    name: 'Depo personeli',
    description: 'Sayım, istif ve sevkiyat.',
    minAge: 18,
    yearlySalary: 358000,
    band: SalaryBand.giris,
    levels: <String>['Depo personeli', 'Depo kıdemlisi', 'Depo şefi'],
  ),
  JobType(
    id: 'guvenlik',
    name: 'Güvenlik görevlisi',
    description: 'Devriye, kamera ve uzun geceler.',
    minAge: 20,
    yearlySalary: 392000,
    band: SalaryBand.giris,
    education: JobEducation.lise,
    levels: <String>['Güvenlik görevlisi', 'Vardiya amiri', 'Güvenlik şefi'],
  ),
  JobType(
    id: 'cagri_merkezi',
    name: 'Çağrı merkezi çalışanı',
    description: 'Kulaklık, sabır ve arka arkaya gelen çağrılar.',
    minAge: 18,
    yearlySalary: 368000,
    band: SalaryBand.giris,
    education: JobEducation.lise,
    minCharisma: 40,
    levels: <String>['Müşteri temsilcisi', 'Kıdemli temsilci', 'Takım lideri'],
  ),
  JobType(
    id: 'satis_danismani',
    name: 'Satış danışmanı',
    description: 'İkna, hedef ve ayın son haftası.',
    minAge: 18,
    yearlySalary: 425000,
    band: SalaryBand.nitelikliHizmet,
    education: JobEducation.lise,
    minCharisma: 50,
    levels: <String>['Satış danışmanı', 'Kıdemli danışman', 'Satış müdürü'],
  ),
  JobType(
    id: 'resepsiyonist',
    name: 'Resepsiyonist',
    description: 'Giriş, çıkış, telefon ve hep güler yüz.',
    minAge: 18,
    yearlySalary: 410000,
    band: SalaryBand.nitelikliHizmet,
    education: JobEducation.lise,
    minCharisma: 45,
    levels: <String>['Resepsiyonist', 'Ön büro görevlisi', 'Ön büro şefi'],
  ),
  JobType(
    id: 'asci',
    name: 'Aşçı',
    description: 'Sıcak mutfak, hızlı tempo ve akşama kadar aynı tabak.',
    minAge: 18,
    yearlySalary: 470000,
    band: SalaryBand.nitelikliHizmet,
    levels: <String>['Aşçı yardımcısı', 'Aşçı', 'Mutfak şefi'],
  ),
  JobType(
    id: 'kuafor',
    name: 'Kuaför',
    description: 'Makas, ayna ve bütün gün ayakta süren sohbetler.',
    minAge: 18,
    yearlySalary: 440000,
    band: SalaryBand.nitelikliHizmet,
    minCharisma: 40,
    levels: <String>['Kuaför çırağı', 'Kuaför', 'Salon sahibi'],
  ),

  // ===================================================================
  // Teknik ve ustalık
  // ===================================================================
  JobType(
    id: 'teknik_servis',
    name: 'Teknik servis çalışanı',
    description: 'Arızalı cihazlar, tornavida ve sabır.',
    minAge: 18,
    yearlySalary: 545000,
    band: SalaryBand.ustaTeknik,
    education: JobEducation.lise,
    tracks: <EducationTrack>{
      EducationTrack.teknikMeslek,
      EducationTrack.bilisim,
      EducationTrack.fenBilim,
    },
    minIntelligence: 45,
    levels: <String>[
      'Teknik servis çalışanı',
      'Kıdemli teknisyen',
      'Servis sorumlusu',
    ],
  ),
  JobType(
    id: 'elektrikci',
    name: 'Elektrik teknisyeni',
    description: 'Pano, kablo ve asla acele edilmeyen bir iş.',
    minAge: 18,
    yearlySalary: 610000,
    band: SalaryBand.ustaTeknik,
    education: JobEducation.lise,
    tracks: <EducationTrack>{
      EducationTrack.teknikMeslek,
      EducationTrack.fenBilim,
    },
    minIntelligence: 45,
    levels: <String>[
      'Elektrik teknisyeni',
      'Usta elektrikçi',
      'Şantiye ustabaşı',
    ],
  ),
  JobType(
    id: 'oto_tamircisi',
    name: 'Oto tamircisi',
    description: 'Kaput altı, yağ kokusu ve kulakla teşhis.',
    minAge: 18,
    yearlySalary: 585000,
    band: SalaryBand.ustaTeknik,
    education: JobEducation.lise,
    tracks: <EducationTrack>{EducationTrack.teknikMeslek},
    levels: <String>['Oto tamircisi', 'Usta tamirci', 'Servis sahibi'],
  ),
  JobType(
    id: 'tesisatci',
    name: 'Tesisatçı',
    description: 'Su, doğalgaz ve gece yarısı gelen telefonlar.',
    minAge: 18,
    yearlySalary: 560000,
    band: SalaryBand.ustaTeknik,
    education: JobEducation.lise,
    tracks: <EducationTrack>{EducationTrack.teknikMeslek},
    levels: <String>['Tesisatçı', 'Usta tesisatçı', 'Taşeron'],
  ),
  JobType(
    id: 'kaynakci',
    name: 'Kaynakçı',
    description: 'Maske, kıvılcım ve milimetrik dikiş.',
    minAge: 18,
    yearlySalary: 640000,
    band: SalaryBand.ustaTeknik,
    education: JobEducation.lise,
    tracks: <EducationTrack>{EducationTrack.teknikMeslek},
    levels: <String>['Kaynakçı', 'Sertifikalı kaynakçı', 'Kaynak ustabaşı'],
  ),
  JobType(
    id: 'cnc_operatoru',
    name: 'CNC operatörü',
    description: 'Tezgâh, program ve mikronluk tolerans.',
    minAge: 19,
    yearlySalary: 675000,
    band: SalaryBand.ustaTeknik,
    education: JobEducation.lise,
    tracks: <EducationTrack>{
      EducationTrack.teknikMeslek,
      EducationTrack.bilisim,
    },
    minIntelligence: 50,
    levels: <String>['CNC operatörü', 'Kıdemli operatör', 'Üretim şefi'],
  ),

  // ===================================================================
  // Ofis ve finans
  // ===================================================================
  JobType(
    id: 'ofis_personeli',
    name: 'Ofis personeli',
    description: 'Evrak, takip ve bitmeyen tablolar.',
    minAge: 19,
    yearlySalary: 640000,
    band: SalaryBand.ofisUzmanlik,
    education: JobEducation.lise,
    levels: <String>['Ofis personeli', 'Kıdemli personel', 'Ofis sorumlusu'],
  ),
  JobType(
    id: 'banka_personeli',
    name: 'Banka personeli',
    description: 'Gişe, hedef ve gün sonu kapanışı.',
    minAge: 22,
    yearlySalary: 760000,
    band: SalaryBand.ofisUzmanlik,
    education: JobEducation.universite,
    programs: <String>{'isletme'},
    minIntelligence: 50,
    minCharisma: 45,
    levels: <String>[
      'Banka personeli',
      'Müşteri ilişkileri yetkilisi',
      'Şube müdür yardımcısı',
    ],
  ),
  JobType(
    id: 'ik_uzmani',
    name: 'İnsan kaynakları uzmanı',
    description: 'Mülakat, bordro ve insanların arasında durmak.',
    minAge: 22,
    yearlySalary: 820000,
    band: SalaryBand.ofisUzmanlik,
    education: JobEducation.universite,
    programs: <String>{'isletme', 'sosyoloji', 'psikoloji'},
    minCharisma: 55,
    levels: <String>['İK uzmanı', 'Kıdemli İK uzmanı', 'İK müdürü'],
  ),
  JobType(
    id: 'muhasebeci',
    name: 'Muhasebeci',
    description: 'Fatura, beyanname ve ayın son günü bitmeyen mesai.',
    minAge: 22,
    yearlySalary: 880000,
    band: SalaryBand.ofisUzmanlik,
    education: JobEducation.universite,
    programs: <String>{'isletme'},
    minIntelligence: 55,
    levels: <String>['Muhasebeci', 'Kıdemli muhasebeci', 'Mali müşavir'],
  ),

  // ===================================================================
  // Sağlık
  // ===================================================================
  JobType(
    id: 'hemsire',
    name: 'Hemşire',
    description: 'Nöbet, serum ve hastanın yanında geçen uzun saatler.',
    minAge: 22,
    yearlySalary: 890000,
    band: SalaryBand.profesyonel,
    education: JobEducation.universite,
    programs: <String>{'hemsirelik'},
    minIntelligence: 55,
    levels: <String>['Hemşire', 'Kıdemli hemşire', 'Sorumlu hemşire'],
  ),
  JobType(
    id: 'doktor',
    name: 'Doktor',
    description: 'Altı yıl okul, sonra nöbet. Kararların geri dönüşü yok.',
    minAge: 25,
    yearlySalary: 2150000,
    band: SalaryBand.yuksekUzmanlik,
    education: JobEducation.universite,
    programs: <String>{'tip'},
    minIntelligence: 75,
    levels: <String>['Pratisyen hekim', 'Uzman hekim', 'Başhekim yardımcısı'],
  ),
  JobType(
    id: 'psikolog',
    name: 'Psikolog',
    description: 'Dinlemek, not almak ve acele etmemek.',
    minAge: 23,
    yearlySalary: 950000,
    band: SalaryBand.profesyonel,
    education: JobEducation.universite,
    programs: <String>{'psikoloji'},
    minIntelligence: 60,
    minCharisma: 50,
    levels: <String>['Psikolog', 'Uzman psikolog', 'Klinik sorumlusu'],
  ),
  JobType(
    id: 'eczaci',
    name: 'Eczacı',
    description: 'Reçete, dozaj ve nöbet gecesi çalan kapı.',
    minAge: 24,
    yearlySalary: 1420000,
    band: SalaryBand.yuksekUzmanlik,
    education: JobEducation.universite,
    programs: <String>{'eczacilik'},
    minIntelligence: 65,
    levels: <String>['Eczacı', 'Eczane sahibi', 'Birden fazla eczane sahibi'],
  ),

  // ===================================================================
  // Mühendislik ve teknoloji
  // ===================================================================
  JobType(
    id: 'yazilim_gelistirici',
    name: 'Yazılım geliştirici',
    description: 'Ekran başında çözülen problemler.',
    minAge: 20,
    yearlySalary: 1320000,
    band: SalaryBand.profesyonel,
    education: JobEducation.lise,
    tracks: <EducationTrack>{EducationTrack.bilisim},
    programs: <String>{'bilgisayar', 'muhendislik'},
    minIntelligence: 60,
    levels: <String>[
      'Yazılım geliştirici',
      'Kıdemli geliştirici',
      'Takım lideri',
    ],
  ),
  JobType(
    id: 'veri_analisti',
    name: 'Veri analisti',
    description: 'Tablolar, sorgular ve "bu sayı neden böyle" soruları.',
    minAge: 22,
    yearlySalary: 1050000,
    band: SalaryBand.profesyonel,
    education: JobEducation.universite,
    programs: <String>{'bilgisayar', 'isletme', 'muhendislik'},
    minIntelligence: 65,
    levels: <String>[
      'Veri analisti',
      'Kıdemli analist',
      'Analitik takım lideri',
    ],
  ),
  JobType(
    id: 'elektrik_muhendisi',
    name: 'Elektrik-elektronik mühendisi',
    description: 'Devre, ölçüm ve sahada geçen günler.',
    minAge: 22,
    yearlySalary: 1180000,
    band: SalaryBand.profesyonel,
    education: JobEducation.universite,
    programs: <String>{'muhendislik'},
    minIntelligence: 65,
    levels: <String>['Mühendis', 'Kıdemli mühendis', 'Proje müdürü'],
  ),
  JobType(
    id: 'insaat_muhendisi',
    name: 'İnşaat mühendisi',
    description: 'Şantiye, hesap ve imza attığın her metrekare.',
    minAge: 22,
    yearlySalary: 1120000,
    band: SalaryBand.profesyonel,
    education: JobEducation.universite,
    programs: <String>{'muhendislik'},
    minIntelligence: 65,
    levels: <String>['Saha mühendisi', 'Şantiye şefi', 'Proje müdürü'],
  ),
  JobType(
    id: 'makine_muhendisi',
    name: 'Makine mühendisi',
    description: 'Tasarım, imalat ve toleransın peşinde koşmak.',
    minAge: 22,
    yearlySalary: 1150000,
    band: SalaryBand.profesyonel,
    education: JobEducation.universite,
    programs: <String>{'muhendislik'},
    minIntelligence: 65,
    levels: <String>['Makine mühendisi', 'Kıdemli mühendis', 'Teknik müdür'],
  ),

  // ===================================================================
  // Kamu ve güvenlik
  // ===================================================================
  JobType(
    id: 'ogretmen',
    name: 'Öğretmen',
    description: 'Sınıfın önünde durmak; bir zamanlar sıradaydın.',
    minAge: 22,
    yearlySalary: 700000,
    band: SalaryBand.ofisUzmanlik,
    education: JobEducation.universite,
    programs: <String>{'egitim'},
    minIntelligence: 50,
    minCharisma: 40,
    levels: <String>['Öğretmen', 'Kıdemli öğretmen', 'Zümre başkanı'],
  ),
  JobType(
    id: 'polis',
    name: 'Polis',
    description: 'Vardiya, tutanak ve her çağrıda bilinmeyen bir kapı.',
    minAge: 21,
    yearlySalary: 720000,
    band: SalaryBand.ofisUzmanlik,
    education: JobEducation.lise,
    minIntelligence: 45,
    levels: <String>['Polis memuru', 'Kıdemli memur', 'Komiser yardımcısı'],
  ),
  JobType(
    id: 'itfaiyeci',
    name: 'İtfaiyeci',
    description: 'Bekleyiş, siren ve geri dönmeyi herkese borçlu olmak.',
    minAge: 21,
    yearlySalary: 660000,
    band: SalaryBand.ofisUzmanlik,
    education: JobEducation.lise,
    levels: <String>['İtfaiye eri', 'Kıdemli er', 'Grup amiri'],
  ),
  JobType(
    id: 'memur',
    name: 'Memur',
    description: 'Evrak, kaşe ve saat sekiz buçuk.',
    minAge: 20,
    yearlySalary: 625000,
    band: SalaryBand.ofisUzmanlik,
    education: JobEducation.lise,
    minIntelligence: 45,
    levels: <String>['Memur', 'Kıdemli memur', 'Şef'],
  ),

  // ===================================================================
  // Yaratıcı ve medya (değişken gelirli bant)
  // ===================================================================
  JobType(
    id: 'ressam_tasarimci',
    name: 'Ressam / tasarımcı',
    description: 'Siparişle çalışan, portföyüyle iş alan bir meslek.',
    minAge: 18,
    yearlySalary: 520000,
    band: SalaryBand.yaraticiDegisken,
    education: JobEducation.lise,
    tracks: <EducationTrack>{
      EducationTrack.guzelSanatlar,
      EducationTrack.tasarim,
      EducationTrack.muzik,
      EducationTrack.elSanatlari,
    },
    programs: <String>{'guzel_sanatlar'},
    levels: <String>[
      'Ressam / tasarımcı',
      'Deneyimli tasarımcı',
      'Sanat yönetmeni',
    ],
  ),
  JobType(
    id: 'grafik_tasarimci',
    name: 'Grafik tasarımcı',
    description: 'Brief, revizyon ve "biraz daha büyük olsun".',
    minAge: 19,
    yearlySalary: 640000,
    band: SalaryBand.yaraticiDegisken,
    education: JobEducation.lise,
    tracks: <EducationTrack>{
      EducationTrack.tasarim,
      EducationTrack.guzelSanatlar,
      EducationTrack.bilisim,
    },
    programs: <String>{'guzel_sanatlar', 'iletisim'},
    levels: <String>[
      'Grafik tasarımcı',
      'Kıdemli tasarımcı',
      'Kreatif direktör',
    ],
  ),
  JobType(
    id: 'gazeteci',
    name: 'Gazeteci',
    description: 'Haber, kaynak ve teyit etmeden yazmamak.',
    minAge: 22,
    yearlySalary: 560000,
    band: SalaryBand.yaraticiDegisken,
    education: JobEducation.universite,
    programs: <String>{'iletisim', 'sosyoloji'},
    minIntelligence: 55,
    minCharisma: 45,
    levels: <String>['Muhabir', 'Kıdemli muhabir', 'Editör'],
  ),
  JobType(
    id: 'fotografci',
    name: 'Fotoğrafçı',
    description: 'Işık, bekleyiş ve binlerce karenin içinden bir tanesi.',
    minAge: 18,
    yearlySalary: 480000,
    band: SalaryBand.yaraticiDegisken,
    tracks: <EducationTrack>{
      EducationTrack.guzelSanatlar,
      EducationTrack.tasarim,
    },
    levels: <String>['Fotoğrafçı', 'Deneyimli fotoğrafçı', 'Stüdyo sahibi'],
  ),
  JobType(
    id: 'manken',
    name: 'Manken',
    description: 'Podyum, ışık ve tek bir kare için geçen uzun saatler.',
    minAge: 18,
    yearlySalary: 820000,
    band: SalaryBand.yaraticiDegisken,
    minCharisma: 45,
    minAppearance: 70,
    levels: <String>['Manken', 'Podyum mankeni', 'Yüzü afişe basılan manken'],
  ),
  JobType(
    id: 'yazar',
    name: 'Yazar',
    description: 'Okuduklarının birikmesiyle başlayan, tek başına yapılan iş.',
    minAge: 20,
    yearlySalary: 460000,
    band: SalaryBand.yaraticiDegisken,
    minIntelligence: 55,
    hobbyId: 'okuma',
    minHobbyStage: 2,
    levels: <String>['Yazar', 'Kitabı basılan yazar', 'Adı bilinen yazar'],
  ),
  JobType(
    id: 'muzisyen',
    name: 'Müzisyen',
    description: 'Prova, sahne ve çalmayı hiç bırakmamış bir hayat.',
    minAge: 18,
    yearlySalary: 440000,
    band: SalaryBand.yaraticiDegisken,
    minCharisma: 40,
    hobbyId: 'muzik',
    minHobbyStage: 2,
    levels: <String>['Müzisyen', 'Sahne müzisyeni', 'Kendi grubunun müzisyeni'],
  ),

  // ===================================================================
  // Dövüş sanatları eğitmenliği (Paket 32)
  //
  // İlan panosunda sürekli durmaz: ancak salonda yıllarca çalışıp
  // basamağı yükselten oyuncuya açılır. Diplomayla değil, kuşakla.
  // ===================================================================
  JobType(
    id: 'karate_egitmeni',
    name: 'Karate eğitmeni',
    description:
        'Kendi kuşağını aldın; şimdi salonun çocuklarını '
        'çalıştırıyorsun.',
    minAge: 18,
    yearlySalary: 455000,
    band: SalaryBand.nitelikliHizmet,
    martialArtId: 'karate',
    levels: <String>['Yardımcı antrenör', 'Karate eğitmeni', 'Baş eğitmen'],
  ),
  JobType(
    id: 'kungfu_egitmeni',
    name: 'Kung fu eğitmeni',
    description: 'Formları sen öğrendin, şimdi sen öğretiyorsun.',
    minAge: 18,
    yearlySalary: 445000,
    band: SalaryBand.nitelikliHizmet,
    martialArtId: 'kung_fu',
    levels: <String>['Yardımcı antrenör', 'Kung fu eğitmeni', 'Salon hocası'],
  ),
  JobType(
    id: 'gures_antrenoru',
    name: 'Güreş antrenörü',
    description: 'Çayırdan sahaya: kıspeti astın, pehlivan yetiştiriyorsun.',
    minAge: 18,
    yearlySalary: 430000,
    band: SalaryBand.nitelikliHizmet,
    martialArtId: 'gures',
    levels: <String>[
      'Çırak antrenör',
      'Güreş antrenörü',
      'Kulüp baş antrenörü',
    ],
  ),
];
JobType? jobById(String id) {
  for (final JobType j in kJobCatalog) {
    if (j.id == id) return j;
  }
  return null;
}

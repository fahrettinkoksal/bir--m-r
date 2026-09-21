import 'package:flutter/foundation.dart';

import '../../data/job_catalog.dart';

/// Bir işten ayrılma nedeni.
enum JobEndReason {
  istifa('Kendi isteğiyle ayrıldı'),
  cikarildi('İşten çıkarıldı'),
  kusakDevami('Kuşak devamında bırakıldı');

  const JobEndReason(this.label);

  final String label;
}

/// Çalışma hayatındaki önemli bir an.
///
/// Zam, terfi ve önemli iş kararları buraya **yaşandığı yıl** yazılır;
/// sonradan uydurulmaz.
@immutable
class CareerMilestone {
  const CareerMilestone({required this.age, required this.text});

  final int age;
  final String text;
}

/// Tamamlanmış ya da süren bir çalışma kaydı.
///
/// İş değiştirince eski kayıt **silinmez**: oyuncu kariyer geçmişinden
/// nerede, kaç yaşında, hangi görevle çalıştığını ve nasıl ayrıldığını
/// görebilir.
@immutable
class JobHistoryEntry {
  const JobHistoryEntry({
    required this.jobId,
    required this.startedAtAge,
    this.endedAtAge,
    this.endReason,
    this.level = 0,
    this.salary,
    this.milestones = const <CareerMilestone>[],
    this.city,
  });

  final String jobId;
  final int startedAtAge;

  /// Ayrılış yaşı; iş sürüyorsa `null`.
  final int? endedAtAge;
  final JobEndReason? endReason;

  /// Ayrılırken ulaşılan görev seviyesi (0 = giriş seviyesi).
  final int level;

  /// Ayrılırken alınan yıllık maaş; bilinmiyorsa `null`.
  final int? salary;

  final List<CareerMilestone> milestones;

  /// İşin şehri; eski kayıtlarda `null`.
  final String? city;

  JobType? get job => jobById(jobId);

  /// Ekranda gösterilecek görev adı.
  String get title => job == null ? jobId : jobTitleFor(job!, level);

  /// Kaç yıl çalışıldı? İş sürüyorsa `null`.
  int? get years => endedAtAge == null ? null : endedAtAge! - startedAtAge;
}

/// Oyuncunun çalışma durumu.
///
/// Maaş, oyun içi bir yıl geçtiğinde **bir kez** ödenir: [lastPaidAge] aynı
/// dönemin iki kez ödenmesini engeller.
@immutable
class CareerState {
  const CareerState({
    this.jobId,
    this.startedAtAge,
    this.lastPaidAge,
    this.pastJobIds = const <String>[],
    this.jobCity,
    this.level = 0,
    this.salary,
    this.milestones = const <CareerMilestone>[],
    this.history = const <JobHistoryEntry>[],
    this.lastRaiseAge,
    this.lastPromotionAge,
    this.lastJobLossAge,
  });

  const CareerState.none() : this();

  /// Şu anki işin kimliği; işsizse `null`.
  final String? jobId;

  /// İşe başlanan yaş.
  final int? startedAtAge;

  /// Maaşın en son ödendiği yaş.
  final int? lastPaidAge;

  /// Daha önce çalışılan işler; kayıt silinmez.
  ///
  /// [history] ayrıntılı kaydı tutar; bu liste eski kayıtlarla uyum için
  /// korunur.
  final List<String> pastJobIds;

  /// İşin bulunduğu şehir (Paket 3).
  ///
  /// Şehir değiştiren çalışanın işine **kendiliğinden son verilmez**: bu
  /// bilgi yalnızca durumu doğru göstermek için tutulur. Şehir değişince
  /// işin ne olacağı kararı kuyrukta (Q-065). Eski kayıtlarda `null`'dır.
  final String? jobCity;

  /// Şu anki işteki görev seviyesi (0 = giriş seviyesi).
  final int level;

  /// Şu anki yıllık maaş.
  ///
  /// Eski kayıtlarda `null`'dır; o zaman meslek kataloğundaki taban maaş
  /// geçerlidir. Zam ve terfi bu değeri değiştirir.
  final int? salary;

  /// Şu anki işteki önemli anlar.
  final List<CareerMilestone> milestones;

  /// Bitmiş çalışma kayıtları; **silinmez**.
  final List<JobHistoryEntry> history;

  /// En son zam alınan yaş (art arda zam istemeyi sınırlar).
  final int? lastRaiseAge;

  /// En son terfi edilen yaş.
  final int? lastPromotionAge;

  /// En son işini kaybettiği yaş; art arda işten çıkarılmayı engeller.
  final int? lastJobLossAge;

  /// İş, oyuncunun yaşadığı şehirden farklı bir şehirde mi?
  bool isInAnotherCity(String currentCity) =>
      isEmployed && jobCity != null && jobCity != currentCity;

  bool get isEmployed => jobId != null;

  JobType? get job => jobId == null ? null : jobById(jobId!);

  String get label => job?.name ?? 'Çalışmıyor';

  /// Şu anki görev adı (seviyeye göre); işsizse "Çalışmıyor".
  String get title => job == null ? 'Çalışmıyor' : jobTitleFor(job!, level);

  /// Gerçekten ödenen yıllık maaş.
  int get yearlySalary => salary ?? job?.yearlySalary ?? 0;

  /// Bu işte kaç yıl geçti?
  int yearsInJob(int currentAge) =>
      startedAtAge == null ? 0 : currentAge - startedAtAge!;

  /// Kariyer geçmişi: biten kayıtlar + süren iş (varsa en sonda).
  List<JobHistoryEntry> allEntries() => <JobHistoryEntry>[
        ...history,
        if (jobId != null && startedAtAge != null)
          JobHistoryEntry(
            jobId: jobId!,
            startedAtAge: startedAtAge!,
            level: level,
            salary: yearlySalary,
            milestones: milestones,
            city: jobCity,
          ),
      ];

  /// Süren işi kapatıp geçmişe yazar.
  ///
  /// Kayıt silinmez; [pastJobIds] de eski davranışla uyumlu kalsın diye
  /// güncellenir.
  CareerState closeCurrentJob({
    required int endedAtAge,
    required JobEndReason reason,
  }) {
    final String? id = jobId;
    final int? basla = startedAtAge;
    if (id == null || basla == null) return this;
    return copyWith(
      jobId: null,
      startedAtAge: null,
      jobCity: null,
      level: 0,
      salary: null,
      milestones: const <CareerMilestone>[],
      lastRaiseAge: null,
      lastPromotionAge: null,
      pastJobIds: List<String>.unmodifiable(<String>[...pastJobIds, id]),
      history: List<JobHistoryEntry>.unmodifiable(<JobHistoryEntry>[
        ...history,
        JobHistoryEntry(
          jobId: id,
          startedAtAge: basla,
          endedAtAge: endedAtAge,
          endReason: reason,
          level: level,
          salary: yearlySalary,
          milestones: milestones,
          city: jobCity,
        ),
      ]),
    );
  }

  /// Süren işe bir dönüm noktası ekler.
  CareerState withMilestone(int age, String text) {
    if (jobId == null) return this;
    return copyWith(
      milestones: List<CareerMilestone>.unmodifiable(<CareerMilestone>[
        ...milestones,
        CareerMilestone(age: age, text: text),
      ]),
    );
  }

  CareerState copyWith({
    Object? jobId = _unsetCareer,
    Object? startedAtAge = _unsetCareer,
    Object? lastPaidAge = _unsetCareer,
    List<String>? pastJobIds,
    Object? jobCity = _unsetCareer,
    int? level,
    Object? salary = _unsetCareer,
    List<CareerMilestone>? milestones,
    List<JobHistoryEntry>? history,
    Object? lastRaiseAge = _unsetCareer,
    Object? lastPromotionAge = _unsetCareer,
    Object? lastJobLossAge = _unsetCareer,
  }) {
    return CareerState(
      jobId: jobId == _unsetCareer ? this.jobId : jobId as String?,
      startedAtAge: startedAtAge == _unsetCareer
          ? this.startedAtAge
          : startedAtAge as int?,
      lastPaidAge:
          lastPaidAge == _unsetCareer ? this.lastPaidAge : lastPaidAge as int?,
      pastJobIds: pastJobIds ?? this.pastJobIds,
      jobCity: jobCity == _unsetCareer ? this.jobCity : jobCity as String?,
      level: level ?? this.level,
      salary: salary == _unsetCareer ? this.salary : salary as int?,
      milestones: milestones ?? this.milestones,
      history: history ?? this.history,
      lastRaiseAge: lastRaiseAge == _unsetCareer
          ? this.lastRaiseAge
          : lastRaiseAge as int?,
      lastPromotionAge: lastPromotionAge == _unsetCareer
          ? this.lastPromotionAge
          : lastPromotionAge as int?,
      lastJobLossAge: lastJobLossAge == _unsetCareer
          ? this.lastJobLossAge
          : lastJobLossAge as int?,
    );
  }
}

const Object _unsetCareer = Object();

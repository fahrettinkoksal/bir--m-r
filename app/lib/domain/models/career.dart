import 'package:flutter/foundation.dart';

import '../../data/job_catalog.dart';

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
  });

  const CareerState.none() : this();

  /// Şu anki işin kimliği; işsizse `null`.
  final String? jobId;

  /// İşe başlanan yaş.
  final int? startedAtAge;

  /// Maaşın en son ödendiği yaş.
  final int? lastPaidAge;

  /// Daha önce çalışılan işler; kayıt silinmez.
  final List<String> pastJobIds;

  /// İşin bulunduğu şehir (Paket 3).
  ///
  /// Şehir değiştiren çalışanın işine **kendiliğinden son verilmez**: bu
  /// bilgi yalnızca durumu doğru göstermek için tutulur. Şehir değişince
  /// işin ne olacağı kararı kuyrukta (Q-065). Eski kayıtlarda `null`'dır.
  final String? jobCity;

  /// İş, oyuncunun yaşadığı şehirden farklı bir şehirde mi?
  bool isInAnotherCity(String currentCity) =>
      isEmployed && jobCity != null && jobCity != currentCity;

  bool get isEmployed => jobId != null;

  JobType? get job => jobId == null ? null : jobById(jobId!);

  String get label => job?.name ?? 'Çalışmıyor';

  CareerState copyWith({
    Object? jobId = _unsetCareer,
    Object? startedAtAge = _unsetCareer,
    Object? lastPaidAge = _unsetCareer,
    List<String>? pastJobIds,
    Object? jobCity = _unsetCareer,
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
    );
  }
}

const Object _unsetCareer = Object();

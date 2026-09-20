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

  bool get isEmployed => jobId != null;

  JobType? get job => jobId == null ? null : jobById(jobId!);

  String get label => job?.name ?? 'Çalışmıyor';

  CareerState copyWith({
    Object? jobId = _unsetCareer,
    Object? startedAtAge = _unsetCareer,
    Object? lastPaidAge = _unsetCareer,
    List<String>? pastJobIds,
  }) {
    return CareerState(
      jobId: jobId == _unsetCareer ? this.jobId : jobId as String?,
      startedAtAge: startedAtAge == _unsetCareer
          ? this.startedAtAge
          : startedAtAge as int?,
      lastPaidAge:
          lastPaidAge == _unsetCareer ? this.lastPaidAge : lastPaidAge as int?,
      pastJobIds: pastJobIds ?? this.pastJobIds,
    );
  }
}

const Object _unsetCareer = Object();

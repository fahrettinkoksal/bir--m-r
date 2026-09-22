import 'package:flutter/foundation.dart';

import '../../data/martial_arts_catalog.dart';

/// Bir dövüş sanatındaki ilerleme.
///
/// Gerçek oyun verisidir: alınan ders sayısı ve ulaşılan basamak kaydedilir,
/// uygulama kapanıp açılınca kaldığı yerden devam eder.
@immutable
class MartialProgress {
  const MartialProgress({
    required this.artId,
    required this.lessons,
    this.startedAtAge,
    this.topRankAtAge,
  });

  final String artId;

  /// Bugüne kadar alınan toplam ders.
  final int lessons;

  final int? startedAtAge;

  /// En üst basamağa çıkılan yaş (çıkıldıysa).
  final int? topRankAtAge;

  MartialArt? get art => martialArtById(artId);

  /// Şu anki basamağın sırası.
  int get level => art?.levelForLessons(lessons) ?? 0;

  /// Şu anki basamağın adı.
  String get rankName => art == null ? '' : art!.ranks[level].name;

  /// En üst basamağa gelindi mi?
  bool get isTopRank => art != null && level >= art!.topLevel;

  /// Eğitmenlik yapılabilecek basamağa gelindi mi?
  bool get canTeach => art != null && level >= art!.instructorFromLevel;

  /// Bir sonraki basamak için kalan ders (yoksa `null`).
  int? get lessonsToNextRank {
    final MartialArt? a = art;
    if (a == null || level >= a.topLevel) return null;
    return a.ranks[level + 1].lessonsNeeded - lessons;
  }

  /// Şu anki basamaktan sonrakine ilerleme (0-1).
  ///
  /// En üst basamakta 1 döner.
  double get ratio {
    final MartialArt? a = art;
    if (a == null || level >= a.topLevel) return 1;
    final int alt = a.ranks[level].lessonsNeeded;
    final int ust = a.ranks[level + 1].lessonsNeeded;
    if (ust <= alt) return 1;
    return ((lessons - alt) / (ust - alt)).clamp(0, 1);
  }

  MartialProgress copyWith({int? lessons, int? topRankAtAge}) =>
      MartialProgress(
        artId: artId,
        lessons: lessons ?? this.lessons,
        startedAtAge: startedAtAge,
        topRankAtAge: topRankAtAge ?? this.topRankAtAge,
      );
}

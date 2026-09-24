/// Bir ünlüyle kurulan temasın kalıcı kaydı.
///
/// Gerçek oyun verisidir: kaç kez denendiği, cevap alınıp alınmadığı ve
/// geri takip edilip edilmediği saklanır. Uygulama kapatılıp açılınca
/// kaybolmaz, ünlü "sıfırdan tanışılmamış" hâle dönmez.
library;

import 'package:flutter/foundation.dart';

import '../../data/celebrity_catalog.dart';

@immutable
class CelebrityContact {
  const CelebrityContact({
    required this.celebrityId,
    this.attempts = 0,
    this.replied = false,
    this.followsBack = false,
    this.collaborated = false,
    this.firstContactAge,
    this.lastContactAge,
  });

  final String celebrityId;

  /// Hayat boyu kaç kez temas denendi.
  final int attempts;

  /// Ünlü en az bir kez gerçekten cevap verdi mi?
  final bool replied;

  /// Geri takip etti mi? Bu, gerçek bir bağın kurulduğu andır.
  final bool followsBack;

  /// Birlikte iş yapıldı mı?
  final bool collaborated;

  final int? firstContactAge;
  final int? lastContactAge;

  Celebrity? get celebrity => celebrityById(celebrityId);

  /// Ekranda gösterilecek kısa durum.
  String get label {
    if (collaborated) return 'Birlikte iş yaptınız';
    if (followsBack) return 'Seni geri takip ediyor';
    if (replied) return 'Bir kez cevap verdi';
    if (attempts > 0) return '$attempts denemede karşılık yok';
    return 'Hiç yazmadın';
  }

  CelebrityContact copyWith({
    int? attempts,
    bool? replied,
    bool? followsBack,
    bool? collaborated,
    int? firstContactAge,
    int? lastContactAge,
  }) => CelebrityContact(
    celebrityId: celebrityId,
    attempts: attempts ?? this.attempts,
    replied: replied ?? this.replied,
    followsBack: followsBack ?? this.followsBack,
    collaborated: collaborated ?? this.collaborated,
    firstContactAge: firstContactAge ?? this.firstContactAge,
    lastContactAge: lastContactAge ?? this.lastContactAge,
  );
}

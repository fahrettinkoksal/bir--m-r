import 'package:flutter/foundation.dart';

import '../../data/finger_catalog.dart';
import 'gender.dart';
import 'wealth.dart';
import '../../text/turkish_text.dart';

/// "Finger" uygulamasındaki bir profil (Paket 34).
///
/// Henüz gerçek bir kişi değildir: eşleşilip **tanışıldığında** oyunun
/// kişi listesine kalıcı kimlikle geçer. Kayda girer; uygulama kapanıp
/// açılınca deste ve eşleşmeler kaybolmaz.
@immutable
class FingerProfile {
  const FingerProfile({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.gender,
    required this.age,
    required this.city,
    required this.bio,
    required this.interests,
    required this.occupation,
    this.intent = FingerIntent.belirsiz,
    this.wealth = WealthTier.ortaHalli,
    this.matchedAtAge,
    this.metPersonId,
  });

  final String id;
  final String firstName;
  final String lastName;
  final Gender gender;
  final int age;
  final String city;
  final String bio;
  final List<String> interests;

  /// Çalışmıyorsa boş kalır; meslek uydurulmaz.
  final String? occupation;

  /// Bu kişinin **ne aradığı** (D-107). Buluşmanın sonucu buna bakar.
  final FingerIntent intent;

  /// Kişinin ekonomik durumu (D-107).
  ///
  /// Oyuncu isterse adayları buna göre süzebilir. Değer profilde
  /// görünür; gizli bir şey değildir.
  final WealthTier wealth;

  /// Eşleşildiyse hangi yaşta eşleşildiği.
  final int? matchedAtAge;

  /// Tanışıldıysa oyunun kişi listesindeki kimliği.
  final String? metPersonId;

  String get fullName => '$firstName $lastName';

  /// Profil resmi yerine kullanılan baş harfler.
  String get initials =>
      trUpper('${firstName.characters.first}${lastName.characters.first}');

  bool get isMet => metPersonId != null;

  FingerProfile copyWith({int? matchedAtAge, String? metPersonId}) =>
      FingerProfile(
        id: id,
        firstName: firstName,
        lastName: lastName,
        gender: gender,
        age: age,
        city: city,
        bio: bio,
        interests: interests,
        occupation: occupation,
        intent: intent,
        wealth: wealth,
        matchedAtAge: matchedAtAge ?? this.matchedAtAge,
        metPersonId: metPersonId ?? this.metPersonId,
      );
}

extension on String {
  Iterable<String> get characters => split('');
}

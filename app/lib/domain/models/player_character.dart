import 'package:flutter/foundation.dart';

import 'gender.dart';
import 'stats.dart';

/// Ana karakter.
@immutable
class PlayerCharacter {
  const PlayerCharacter({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.gender,
    required this.age,
    required this.birthCity,
    required this.stats,
    this.fame,
  });

  final String id;
  final String firstName;
  final String lastName;
  final Gender gender;
  final int age;

  /// Doğum şehri rastgele belirlenir (D-004). Doğum **yılı** yoktur (D-003).
  final String birthCity;
  final Stats stats;

  /// Ün (D-027). `null` ise Ün henüz **açılmamıştır** ve arayüzde gösterilmez.
  final int? fame;

  bool get fameUnlocked => fame != null;

  String get fullName => '$firstName $lastName';

  PlayerCharacter copyWith({
    String? firstName,
    String? lastName,
    int? age,
    Stats? stats,
    int? fame,
  }) {
    return PlayerCharacter(
      id: id,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      gender: gender,
      age: age ?? this.age,
      birthCity: birthCity,
      stats: stats ?? this.stats,
      fame: fame ?? this.fame,
    );
  }
}

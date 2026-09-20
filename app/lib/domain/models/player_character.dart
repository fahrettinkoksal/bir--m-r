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
    String? currentCity,
    required this.stats,
    this.fame,
    this.wallet = 0,
    this.hairStyle,
  }) : currentCity = currentCity ?? birthCity;

  final String id;
  final String firstName;
  final String lastName;
  final Gender gender;
  final int age;

  /// Doğum şehri rastgele belirlenir (D-004). Doğum **yılı** yoktur (D-003).
  final String birthCity;

  /// Oyuncunun **şu an yaşadığı** şehir (D-043).
  ///
  /// Taşınana kadar doğum şehridir.
  final String currentCity;
  final Stats stats;

  /// Ün (D-027). `null` ise Ün henüz **açılmamıştır** ve arayüzde gösterilmez.
  final int? fame;

  /// Oyuncunun **kendi** cüzdanı (ECO-001).
  ///
  /// Ailenin ekonomik durumundan ve ebeveynlerin mal varlığından tamamen
  /// ayrıdır; aile varlığı oyuncunun harcanabilir parası değildir. Bu
  /// sürümde kazanma/harcama akışları yoktur, yalnızca bakiye tutulur ve
  /// olay etkileriyle değişebilir. Para birimi ve başlangıç bakiyesi henüz
  /// kararlaştırılmadı (prototypeOnly: 0 ile başlar).
  final int wallet;

  /// Berberde seçilen saç stili. Görsel karakter sistemi henüz yok;
  /// seçim metin olarak saklanır ve Ben ekranında görünür.
  final String? hairStyle;

  /// Ekranda gösterilecek bakiye metni.
  String get walletLabel => '$wallet ₺';

  bool get fameUnlocked => fame != null;

  String get fullName => '$firstName $lastName';

  PlayerCharacter copyWith({
    String? firstName,
    String? lastName,
    int? age,
    Stats? stats,
    int? fame,
    int? wallet,
    String? hairStyle,
    String? currentCity,
  }) {
    return PlayerCharacter(
      id: id,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      gender: gender,
      age: age ?? this.age,
      birthCity: birthCity,
      currentCity: currentCity ?? this.currentCity,
      stats: stats ?? this.stats,
      fame: fame ?? this.fame,
      wallet: wallet ?? this.wallet,
      hairStyle: hairStyle ?? this.hairStyle,
    );
  }
}

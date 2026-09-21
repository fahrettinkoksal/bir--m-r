/// Burç hesabı ve burçsal dönemler (Paket 27).
///
/// **Doğum yılı yoktur (D-003).** Burç yalnızca doğum ayı ve gününden
/// gelir; tarihsel takvim, dönem motoru ya da doğum yılı seçimi eklenmedi.
///
/// Oyunun tonu: burç yorumları ve fal **oyun içi eğlencedir**, kesin bir
/// iddia değildir. Etkiler küçüktür ve hayatı belirlemez.
library;

import 'dart:math';

import '../models/game_state.dart';
import '../models/person.dart';
import '../models/zodiac.dart';

abstract final class Astrology {
  /// Oyuncunun doğum tarihi.
  ///
  /// Kayıtta varsa o kullanılır. Eski kayıtlarda yoktur; o zaman hayatın
  /// **tohumundan** deterministik olarak türetilir. Böylece aynı hayat
  /// her açılışta aynı burcu gösterir ve eski kayıtlar da bozulmaz.
  static BirthDate birthDateOf(GameState state) =>
      state.player.birthDate ?? fromSeed(state.seed);

  /// Oyuncunun burcu.
  static Zodiac zodiacOf(GameState state) => birthDateOf(state).zodiac;

  /// Bir kişinin doğum tarihi.
  ///
  /// Kişilerin doğum günü ayrıca kayda yazılmaz; **kalıcı kimliğinden**
  /// deterministik olarak türetilir. Kimlik hayat boyu değişmediği için
  /// kişinin burcu da değişmez.
  static BirthDate birthDateOfPerson(Person person) =>
      fromSeed(person.id.hashCode);

  static Zodiac zodiacOfPerson(Person person) =>
      birthDateOfPerson(person).zodiac;

  /// Bir tohumdan doğum ayı ve günü üretir.
  static BirthDate fromSeed(int seed) {
    final Random rng = Random(seed.abs() % 0x7fffffff);
    final int ay = rng.nextInt(12) + 1;
    final int gun = rng.nextInt(BirthDate.daysInMonth(ay)) + 1;
    return BirthDate(month: ay, day: gun);
  }
}

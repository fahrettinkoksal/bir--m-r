import 'dart:math';

import 'package:flutter/foundation.dart';

import '../domain/generation/life_generator.dart';
import '../domain/generation/life_progression.dart';
import '../domain/models/game_state.dart';
import '../domain/models/gender.dart';

/// Uygulamanın tek durum sahibi.
///
/// Harici bir durum yönetimi paketine bağlı değildir; yeni sekmeler ve
/// sistemler eklendiğinde bu sınıfın üzerine modül eklenebilir.
class GameController extends ChangeNotifier {
  GameController({Random? random}) : _random = random ?? Random();

  final Random _random;

  GameState? _state;

  GameState? get state => _state;

  bool get hasLife => _state != null;

  /// Yeni bir hayat başlatır (D-005 iki başlangıç modu).
  ///
  /// [seed] verilirse üretim tekrarlanabilir olur; verilmezse her oyuncu
  /// farklı bir hayat görür.
  void startNewLife({
    required StartMode mode,
    String? firstName,
    Gender? gender,
    int? seed,
  }) {
    final int usedSeed = seed ?? _random.nextInt(1 << 32);
    final LifeGenerator generator = LifeGenerator.seeded(usedSeed);
    _state = generator.generate(
      mode: mode,
      chosenFirstName: mode == StartMode.isimVeCinsiyet ? firstName : null,
      chosenGender: mode == StartMode.isimVeCinsiyet ? gender : null,
    );
    notifyListeners();
  }

  /// **Yaş Al** (D-018).
  void ageUp() {
    final GameState? current = _state;
    if (current == null) return;
    _state = LifeProgression(_random).advanceOneYear(current);
    notifyListeners();
  }

  /// Hayatı bitirip başlangıç ekranına döner.
  void clearLife() {
    _state = null;
    notifyListeners();
  }
}

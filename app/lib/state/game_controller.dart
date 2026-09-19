import 'dart:math';

import 'package:flutter/foundation.dart';

import '../domain/generation/life_generator.dart';
import '../domain/generation/life_progression.dart';
import '../domain/events/event_engine.dart';
import '../domain/interaction/family_interactions.dart';
import '../domain/models/game_event.dart';
import '../domain/models/game_state.dart';
import '../domain/models/gender.dart';
import '../domain/models/interaction.dart';
import '../domain/models/person.dart';

/// Uygulamanın tek durum sahibi.
///
/// Harici bir durum yönetimi paketine bağlı değildir; yeni sekmeler ve
/// sistemler eklendiğinde bu sınıfın üzerine modül eklenebilir.
class GameController extends ChangeNotifier {
  GameController({Random? random}) : _random = random ?? Random();

  final Random _random;
  final FamilyInteractions _interactions = const FamilyInteractions();
  final EventEngine _events = const EventEngine();

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
  ///
  /// Ekranda çözülmemiş bir olay varken çalışmaz; böylece olaylar üst üste
  /// binmez.
  void ageUp() {
    final GameState? current = _state;
    if (current == null || current.hasPendingEvent) return;
    _state = LifeProgression(_random).advanceOneYear(current);
    notifyListeners();
  }

  /// Ekrandaki olayı verilen seçimle çözer (D-021, D-022).
  ///
  /// Seçimin oyuncuya gösterilecek özgün sonuç metnini döndürür.
  String? chooseEventOption(String choiceId) {
    final GameState? current = _state;
    if (current == null || !current.hasPendingEvent) return null;
    final GameState next = _events.resolve(current, choiceId);
    _state = next;
    notifyListeners();
    return next.log.isEmpty ? null : next.log.last.text;
  }

  /// Bir aile bireyiyle etkileşim kurar ve sonucu döndürür (D-016).
  ///
  /// Genel bir etkileşim kotası yoktur; sınır yalnızca aynı kişiyle aynı
  /// etkinliğin aynı yaştaki **getirisinde** işler (D-026).
  InteractionOutcome? interact(String personId, InteractionKind kind) {
    final GameState? current = _state;
    if (current == null || current.hasPendingEvent) return null;
    final InteractionResult result = _interactions.perform(
      state: current,
      personId: personId,
      kind: kind,
      rng: _random,
    );
    // Oyun içi ilerlemeye bağlı olarak aralıklı bir ek olay çıkabilir
    // (D-023, D-024). Gerçek dünya dakikası beklenmez ve bir yaşta en fazla
    // bir ek olay açılır.
    GameState next = result.state;
    final ActiveEvent? extra = _events.progressEvent(next, _random);
    if (extra != null) {
      next = next.copyWith(
        pendingEvent: extra,
        extraEventsThisAge: next.extraEventsThisAge + 1,
      );
    }

    _state = next;
    notifyListeners();
    return result.outcome;
  }

  /// Etkileşimin şu an mümkün olup olmadığı; arayüz bunu kullanarak
  /// yapılamayacak eylemi düğme olarak göstermez.
  InteractionAvailability availabilityFor(Person person) {
    final GameState? current = _state;
    if (current == null) {
      return const InteractionAvailability.blocked('Etkin bir hayat yok.');
    }
    return _interactions.availability(current, person);
  }

  /// Hayatı bitirip başlangıç ekranına döner.
  void clearLife() {
    _state = null;
    notifyListeners();
  }
}

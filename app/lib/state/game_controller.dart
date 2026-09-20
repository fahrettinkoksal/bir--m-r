import 'dart:async';
import 'dart:math';

import 'package:flutter/foundation.dart';

import '../data/item_catalog.dart';
import '../data/save/save_service.dart';
import '../data/shop_catalog.dart';

import '../domain/generation/life_generator.dart';
import '../domain/generation/life_progression.dart';
import '../domain/effects/effect_diff.dart';
import '../domain/events/event_engine.dart';
import '../domain/models/applied_effect.dart';
import '../domain/interaction/family_interactions.dart';
import '../domain/interaction/item_actions.dart';
import '../domain/interaction/romance.dart';
import '../domain/models/game_event.dart';
import '../domain/models/game_state.dart';
import '../domain/models/gender.dart';
import '../domain/models/interaction.dart';
import '../domain/models/owned_item.dart';
import '../domain/models/person.dart';

/// Uygulamanın tek durum sahibi.
///
/// Harici bir durum yönetimi paketine bağlı değildir; yeni sekmeler ve
/// sistemler eklendiğinde bu sınıfın üzerine modül eklenebilir.
class GameController extends ChangeNotifier {
  GameController({Random? random, SaveService? saveService})
      : _random = random ?? Random(),
        _saveService = saveService;

  final Random _random;
  final FamilyInteractions _interactions = const FamilyInteractions();
  final EventEngine _events = const EventEngine();
  final Romance _romance = const Romance();
  final ItemActions _items = const ItemActions();

  /// Kayıt servisi. `null` ise oyun yalnızca bellekte çalışır (testler).
  final SaveService? _saveService;

  GameState? _state;

  /// Yazma işlemleri sıraya alınır: iki kayıt birbirinin üzerine binmez.
  Future<void> _saveChain = Future<void>.value();

  /// Okunamayan bir kayıt bulunduğunda otomatik kayıt durdurulur.
  ///
  /// Böylece bozuk dosyanın üzerine habersizce yazılmaz; kullanıcı yeni bir
  /// hayat başlatmayı onaylayana kadar dosyaya dokunulmaz.
  bool _autoSaveBlocked = false;

  /// Cihazda kayıt var mı? Açılışta [checkForSavedLife] ile doldurulur.
  bool _hasSavedLife = false;

  /// Okunamayan kayıt için kullanıcıya gösterilecek açıklama.
  String? _saveProblem;

  GameState? get state => _state;

  bool get hasLife => _state != null;

  /// Cihazda devam edilebilecek bir kayıt bulundu mu?
  bool get hasSavedLife => _hasSavedLife;

  /// Kayıt okunamadıysa nedeni; sorun yoksa `null`.
  String? get saveProblem => _saveProblem;

  /// Kayıt sistemi etkin mi?
  bool get savingEnabled => _saveService != null;

  /// Açılışta kayıt olup olmadığına bakar.
  Future<void> checkForSavedLife() async {
    final SaveService? service = _saveService;
    if (service == null) return;
    _hasSavedLife = await service.hasSave();
    notifyListeners();
  }

  /// Kayıtlı hayatı yükler ve sonucu bildirir.
  ///
  /// Kayıt bozuksa durum değişmez, dosyaya dokunulmaz ve sebep
  /// [saveProblem] üzerinden okunabilir.
  Future<SaveLoadStatus> restoreSavedLife() async {
    final SaveService? service = _saveService;
    if (service == null) return SaveLoadStatus.yok;

    final SaveLoadResult result = await service.load();
    switch (result.status) {
      case SaveLoadStatus.yuklendi:
        _state = result.state;
        _hasSavedLife = true;
        _saveProblem = null;
        _autoSaveBlocked = false;
      case SaveLoadStatus.bozuk:
        // Bozuk kaydın üzerine yazma: kullanıcı karar verene kadar dokunma.
        _hasSavedLife = true;
        _saveProblem = result.message;
        _autoSaveBlocked = true;
      case SaveLoadStatus.yok:
        _hasSavedLife = false;
        _saveProblem = null;
    }
    notifyListeners();
    return result.status;
  }

  /// Kayıtlı hayatı **açıkça** siler. Yalnızca kullanıcı onayıyla çağrılır.
  Future<void> deleteSavedLife() async {
    final SaveService? service = _saveService;
    if (service == null) return;
    await _saveChain;
    await service.clear();
    _hasSavedLife = false;
    _saveProblem = null;
    _autoSaveBlocked = false;
    notifyListeners();
  }

  /// Oyun durumunu değiştiren her anlamlı işlemden sonra otomatik kayıt.
  ///
  /// Arayüzü bekletmemek için eşzamansız çalışır; testler [flushSaves] ile
  /// yazmanın bitmesini bekleyebilir.
  void _autoSave() {
    final SaveService? service = _saveService;
    final GameState? current = _state;
    if (service == null || current == null || _autoSaveBlocked) return;
    _hasSavedLife = true;
    _saveChain = _saveChain.then((_) => service.save(current)).catchError(
      (Object error) {
        // Kayıt yazılamadıysa oyun durmaz; sorun kullanıcıya bildirilir.
        _saveProblem = 'Oyun kaydedilemedi: $error';
      },
    );
  }

  /// Bekleyen kayıt yazmalarının bitmesini bekler.
  Future<void> flushSaves() => _saveChain;

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
    // Yeni hayat, bozuk kayıt engelini kaldırır: oyuncu bilerek baştan
    // başladı, artık yazmak güvenli.
    _autoSaveBlocked = false;
    _saveProblem = null;
    _autoSave();
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
    _autoSave();
    notifyListeners();
  }

  /// Ekrandaki olayı verilen seçimle çözer (D-021, D-022).
  ///
  /// Sonuç metninin yanında **gerçekten uygulanmış** değişimleri de döndürür;
  /// bunlar niyetten değil, durumun öncesi/sonrası farkından hesaplanır.
  EventChoiceResult? chooseEventOption(String choiceId) {
    final GameState? current = _state;
    if (current == null || !current.hasPendingEvent) return null;
    final GameState next = _events.resolve(current, choiceId, rng: _random);
    _state = next;
    _autoSave();
    notifyListeners();
    return EventChoiceResult(
      text: next.log.isEmpty ? '' : next.log.last.text,
      effects: diffAppliedEffects(current, next),
    );
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
    _autoSave();
    notifyListeners();
    return result.outcome;
  }

  /// Etkileşimin şu an mümkün olup olmadığı; arayüz bunu kullanarak
  /// yapılamayacak eylemi düğme olarak göstermez.
  InteractionAvailability availabilityFor(
    Person person, [
    InteractionKind? kind,
  ]) {
    final GameState? current = _state;
    if (current == null) {
      return const InteractionAvailability.blocked('Etkin bir hayat yok.');
    }
    return _interactions.availability(current, person, kind);
  }

  /// Bir kişi için **şu an gerçekten yapılabilen** etkileşimler.
  ///
  /// Parası olmayan oyuncuya hediye düğmesi, kendi parası olmayan kişiye
  /// para isteme düğmesi açılmaz.
  List<InteractionKind> availableKindsFor(Person person) {
    final GameState? current = _state;
    if (current == null) return const <InteractionKind>[];
    return _interactions.availableKinds(current, person);
  }

  // =====================================================================
  // Eşyalar (Varlıklar)
  // =====================================================================

  /// Bir eşyada şu an gerçekten yapılabilecek eylemler.
  List<ItemActionKind> itemActionsFor(OwnedItem item) {
    final GameState? current = _state;
    if (current == null) return const <ItemActionKind>[];
    return _items.availableActions(current, item);
  }

  /// Eylemin neden kapalı olduğunu açıklar.
  InteractionAvailability itemAvailability(
    OwnedItem item,
    ItemActionKind action,
  ) {
    final GameState? current = _state;
    if (current == null) {
      return const InteractionAvailability.blocked('Etkin bir hayat yok.');
    }
    return _items.availability(current, item, action);
  }

  /// Bu eşyaya takılabilecek, envanterdeki aksesuarlar.
  List<OwnedItem> compatibleAccessoriesFor(OwnedItem item) {
    final GameState? current = _state;
    if (current == null) return const <OwnedItem>[];
    return _items.compatibleAccessories(current, item);
  }

  /// Bakım ücreti.
  int repairCostFor(OwnedItem item) {
    final GameState? current = _state;
    if (current == null) return 0;
    return _items.repairCost(current, item);
  }

  /// Satışta teklif edilecek tutar.
  int estimatedPriceFor(OwnedItem item) => _items.estimatedPrice(item);

  /// Eşya eylemini uygular (kullan / temizle / bakım).
  ItemOutcome? performItemAction(String itemId, ItemActionKind action) =>
      _runItemAction(
        (GameState current) => _items.perform(
          state: current,
          itemId: itemId,
          action: action,
          rng: _random,
        ),
      );

  /// Uyumlu aksesuarı eşyaya takar.
  ItemOutcome? attachAccessory(String itemId, String accessoryItemId) =>
      _runItemAction(
        (GameState current) => _items.attachAccessory(
          state: current,
          itemId: itemId,
          accessoryItemId: accessoryItemId,
        ),
      );

  /// Eşyayı satar. Onay arayüzde alınır; burada tek bir satış uygulanır.
  ItemOutcome? sellItem(String itemId) => _runItemAction(
        (GameState current) => _items.sell(state: current, itemId: itemId),
      );

  /// Mağazadan ürün alır.
  ItemOutcome? buyProduct(ShopProduct product) => _runItemAction(
        (GameState current) => _items.buy(state: current, product: product),
      );

  /// Eşya işlemlerinin ortak akışı: olay varken çalışmaz, yalnızca durum
  /// gerçekten değiştiyse kaydeder.
  ItemOutcome? _runItemAction(ItemActionResult Function(GameState) islem) {
    final GameState? current = _state;
    if (current == null || current.hasPendingEvent) return null;

    final ItemActionResult result = islem(current);
    if (!result.outcome.applied) {
      // İşlem gerçekleşmedi: durum ve kayıt dosyası değişmez.
      return result.outcome;
    }

    _state = result.state;
    _autoSave();
    notifyListeners();
    return result.outcome;
  }

  /// Sevgiliden ayrılır (D-029).
  ///
  /// Kişi kaydı silinmez; **aynı kimlikle** eski sevgili statüsüne geçer.
  /// Yalnızca gerçekten sevgili olan kişi için çalışır.
  String? endRomance(String personId) {
    final GameState? current = _state;
    if (current == null || current.hasPendingEvent) return null;
    final GameState next = _romance.end(current, personId);
    if (identical(next, current)) return null;
    _state = next;
    _autoSave();
    notifyListeners();
    return next.log.last.text;
  }

  /// Yalnızca testler için: durumu doğrudan ayarlar.
  @visibleForTesting
  void debugSetState(GameState state) {
    _state = state;
    notifyListeners();
  }

  /// Hayatı ekrandan kaldırıp başlangıç ekranına döner.
  ///
  /// **Kaydı silmez**: oyuncu başlangıç ekranından "Devam Et" ile aynı
  /// hayata geri dönebilir. Kaydı silmek için [deleteSavedLife] gerekir.
  void clearLife() {
    _state = null;
    notifyListeners();
  }
}

/// Bir olay seçiminin oyuncuya gösterilecek sonucu.
class EventChoiceResult {
  const EventChoiceResult({required this.text, required this.effects});

  final String text;
  final List<AppliedEffect> effects;
}

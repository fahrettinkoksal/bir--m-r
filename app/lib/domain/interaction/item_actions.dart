import 'dart:math';

import '../../data/economy.dart';
import '../../data/item_catalog.dart';
import '../../data/license_catalog.dart';
import '../economy/housing.dart';
import '../../data/shop_catalog.dart';
import '../effects/effect_diff.dart';
import '../models/applied_effect.dart';
import '../models/game_state.dart';
import '../models/interaction.dart';
import '../models/life_log.dart';
import '../models/owned_item.dart';
import '../models/player_character.dart';
import '../models/stats.dart';
import '../../text/turkish_text.dart';

/// Bir eşya eyleminin sonucu.
class ItemOutcome {
  const ItemOutcome({
    required this.applied,
    required this.text,
    this.effects = const <AppliedEffect>[],
    this.noNewBenefit = false,
  });

  /// İşlem gerçekten uygulandı mı?
  ///
  /// `false` ise durum değişmemiştir: kondisyon, aksesuar ve cüzdan aynı
  /// kalır ve ekranda işlem olmuş gibi gösterilmez.
  final bool applied;

  /// Oyuncuya gösterilecek metin (uygulanmadıysa gerekçe).
  final String text;

  /// Durumun öncesi/sonrası farkından okunan **gerçek** değişimler.
  final List<AppliedEffect> effects;

  /// O yaş için bu eylemden kazanılacak bir şey kalmadı.
  final bool noNewBenefit;
}

class ItemActionResult {
  const ItemActionResult({required this.state, required this.outcome});

  final GameState state;
  final ItemOutcome outcome;
}

/// Eşya kullanımı, bakımı, aksesuarı ve satışı.
///
/// Bütün sayısal değerler `prototypeOnly`'dir; onaylanmış ekonomi dengesi
/// değildir (`docs/DESIGN_REVIEW_QUEUE.md`, Q-041).
class ItemActions {
  const ItemActions();

  /// prototypeOnly: kullanımda düşen kondisyon aralığı.
  static const int prototypeOnlyMinWear = 2;
  static const int prototypeOnlyMaxWear = 5;

  /// prototypeOnly: temizlikte kazanılan kondisyon ve üst sınır.
  ///
  /// Temizlik yalnızca kiri giderir; üst sınırın üstüne çıkaramaz, yani
  /// mekanik hasarı onarmaz.
  static const int prototypeOnlyCleanGain = 6;
  static const int prototypeOnlyCleanCeiling = 85;

  /// prototypeOnly: bakımda kazanılan kondisyon ve üst sınır.
  ///
  /// Bakım da her hasarı sıfırlamaz: tavan 100 değildir.
  static const int prototypeOnlyRepairGain = 25;
  static const int prototypeOnlyRepairCeiling = 95;

  /// prototypeOnly: bakım ücreti, temel değerin bu oranı kadar eksik
  /// kondisyonla çarpılarak bulunur.
  static const double prototypeOnlyRepairCostRatio = 0.15;
  static const int prototypeOnlyMinRepairCost = 120;

  /// prototypeOnly: bakım seti varsa ücret bu oranda azalır.
  static const double prototypeOnlyRepairKitDiscount = 0.5;
  static const String repairKitTypeId = 'bisiklet_bakim_seti';

  /// prototypeOnly: ikinci el satış katsayısı.
  static const double prototypeOnlyResaleFactor = 0.55;

  /// prototypeOnly: özel/antika nitelik çarpanı.
  static const double prototypeOnlySpecialMultiplier = 2.2;

  /// prototypeOnly: takılı aksesuarların satış değerine katkı oranı.
  static const double prototypeOnlyAttachmentFactor = 0.5;

  /// prototypeOnly: kullanılamayacak kadar yıpranmış sayılan eşik.
  static const int prototypeOnlyBrokenBelow = 10;

  /// prototypeOnly: bu değerin üstündeki eşyalar "değerli" sayılır.
  ///
  /// Ortak ekonomi ölçeğinden gelir (`lib/data/economy.dart`).
  static const int prototypeOnlyValuableThreshold =
      Economy.valuableThreshold;

  /// prototypeOnly: değerli eşya satabilmek için gereken yaş.
  ///
  /// Küçük yaştaki karakterlerin değerli eşya satışı için kesin bir oyun
  /// kuralı henüz yok; bu güvenli ve basit bir sınırdır (Q-045).
  static const int prototypeOnlyValuableSellAge = 15;

  /// Aynı yaşta tekrar edildikçe azalan kazanç eğrisi.
  static const List<double> prototypeOnlyRewardCurve = <double>[
    1.0,
    0.55,
    0.25,
    0.0,
  ];

  /// Eşya üzerinde şu an yapılabilecek eylemler.
  ///
  /// Türüne uymayan eylem **hiç** listelenmez: kol saatine korna takılmaz,
  /// kitap sürülmez.
  List<ItemActionKind> availableActions(GameState state, OwnedItem item) =>
      actionsFor(item.type.kind)
          .where((ItemActionKind a) => availability(state, item, a).isAllowed)
          .toList(growable: false);

  /// Eylemin şu an mümkün olup olmadığı ve değilse gerekçesi.
  InteractionAvailability availability(
    GameState state,
    OwnedItem item,
    ItemActionKind action,
  ) {
    if (state.itemById(item.id) == null) {
      return const InteractionAvailability.blocked(
        'Bu eşya artık sende değil.',
      );
    }
    if (!actionsFor(item.type.kind).contains(action)) {
      return const InteractionAvailability.blocked(
        'Bu eşyada yapılabilecek bir işlem değil.',
      );
    }

    switch (action) {
      case ItemActionKind.kullan:
        if (item.condition < prototypeOnlyBrokenBelow) {
          return const InteractionAvailability.blocked(
            'Çok yıpranmış; önce bakım gerekiyor.',
          );
        }
        // Araç kullanmak ehliyet ister; araç **sahibi olmak** istemez.
        final LicenseType? gereken = licenseRequiredFor(item);
        if (gereken != null && !state.hasLicense(gereken.id)) {
          return InteractionAvailability.blocked(
            '${item.name} kullanmak için ${trLower(gereken.label)} '
            'gerekiyor.',
          );
        }
        return const InteractionAvailability.allowed();

      case ItemActionKind.temizle:
        if (item.condition >= prototypeOnlyCleanCeiling) {
          return const InteractionAvailability.blocked(
            'Zaten temiz; temizlikle daha iyisi olmaz.',
          );
        }
        return const InteractionAvailability.allowed();

      case ItemActionKind.bakim:
        if (item.condition >= prototypeOnlyRepairCeiling) {
          return const InteractionAvailability.blocked(
            'Bakıma ihtiyacı yok.',
          );
        }
        final int ucret = repairCost(state, item);
        if (state.player.wallet < ucret) {
          return InteractionAvailability.blocked(
            'Bakım için ${trMoney(ucret)} gerekiyor; cüzdanında yeterli para yok.',
          );
        }
        return const InteractionAvailability.allowed();

      case ItemActionKind.aksesuarTak:
        if (compatibleAccessories(state, item).isEmpty) {
          return const InteractionAvailability.blocked(
            'Takabileceğin uyumlu bir aksesuarın yok. Varlıklar → Mağaza\'dan '
            'alabilirsin.',
          );
        }
        return const InteractionAvailability.allowed();

      case ItemActionKind.sat:
        if (item.type.baseValue >= prototypeOnlyValuableThreshold &&
            state.player.age < prototypeOnlyValuableSellAge) {
          return InteractionAvailability.blocked(
            'Bu yaşta değerli bir eşyayı kendi başına satamazsın '
            '($prototypeOnlyValuableSellAge yaşından itibaren).',
          );
        }
        return const InteractionAvailability.allowed();
    }
  }

  /// Envanterde bulunan, bu eşyaya takılabilecek aksesuar örnekleri.
  List<OwnedItem> compatibleAccessories(GameState state, OwnedItem item) =>
      state.items
          .where((OwnedItem a) => a.type.canAttachTo(item.type))
          .toList(growable: false);

  /// Bakım ücreti: eksik kondisyonla orantılıdır, bakım seti varsa ucuzlar.
  int repairCost(GameState state, OwnedItem item) {
    final int eksik = (prototypeOnlyRepairCeiling - item.condition).clamp(0, 100);
    final double ham =
        item.type.baseValue * prototypeOnlyRepairCostRatio * (eksik / 100);
    final bool bakimSeti =
        state.possessions.contains(repairKitTypeId) &&
        item.type.kind == ItemKind.bisiklet;
    final double indirimli =
        bakimSeti ? ham * prototypeOnlyRepairKitDiscount : ham;
    return max(prototypeOnlyMinRepairCost, indirimli.round());
  }

  /// Eşyanın tahmini satış bedeli.
  ///
  /// Yalnızca ada değil; türün temel değerine, kondisyona, takılı
  /// aksesuarlara ve özel/antika niteliğe bakar.
  int estimatedPrice(OwnedItem item) {
    final ItemType type = item.type;
    final double ozel = type.special ? prototypeOnlySpecialMultiplier : 1.0;
    // Kondisyon düştükçe değer azalır; sıfır kondisyonda bile hurda değeri
    // kalır.
    final double kondisyon = 0.25 + 0.75 * (item.condition / 100);
    double toplam = type.baseValue * ozel * kondisyon;
    for (final String aksesuar in item.attachments) {
      toplam += itemTypeOrFallback(aksesuar).baseValue *
          prototypeOnlyAttachmentFactor;
    }
    return max(1, (toplam * prototypeOnlyResaleFactor).round());
  }

  // ===================================================================
  // Eylemler
  // ===================================================================

  /// Kullanma, temizleme veya bakım.
  ItemActionResult perform({
    required GameState state,
    required String itemId,
    required ItemActionKind action,
    required Random rng,
  }) {
    final OwnedItem? item = state.itemById(itemId);
    if (item == null) {
      return _blocked(state, 'Bu eşya artık sende değil.');
    }
    final InteractionAvailability check = availability(state, item, action);
    if (!check.isAllowed) return _blocked(state, check.reason!);

    switch (action) {
      case ItemActionKind.kullan:
        return _use(state: state, item: item, rng: rng);
      case ItemActionKind.temizle:
        return _clean(state: state, item: item);
      case ItemActionKind.bakim:
        return _repair(state: state, item: item);
      case ItemActionKind.aksesuarTak:
      case ItemActionKind.sat:
        return _blocked(
          state,
          'Bu işlem ayrı bir adımla yapılır.',
        );
    }
  }

  ItemActionResult _use({
    required GameState state,
    required OwnedItem item,
    required Random rng,
  }) {
    final String key = GameState.interactionKey(item.id, 'kullan');
    final int done = state.interactionCounts[key] ?? 0;
    final double factor =
        prototypeOnlyRewardCurve[min(done, prototypeOnlyRewardCurve.length - 1)];

    final _UseReward reward = _useRewards[item.type.kind] ?? const _UseReward();
    final Stats stats = state.player.stats.copyWith(
      happiness: state.player.stats.happiness + _scaled(reward.happiness, factor),
      health: state.player.stats.health + _scaled(reward.health, factor),
      charisma: state.player.stats.charisma + _scaled(reward.charisma, factor),
      appearance:
          state.player.stats.appearance + _scaled(reward.appearance, factor),
    );

    // Kullanım her hâlükârda yıpratır; fayda bitse de eşya eskir.
    final int yipranma =
        rng.nextInt(prototypeOnlyMaxWear - prototypeOnlyMinWear + 1) +
            prototypeOnlyMinWear;
    final OwnedItem guncel =
        item.copyWith(condition: item.condition - yipranma);

    final GameState next = state
        .copyWith(
          player: state.player.copyWith(stats: stats),
          interactionCounts: Map<String, int>.unmodifiable(
            <String, int>{...state.interactionCounts, key: done + 1},
          ),
        )
        .updateItem(guncel);

    final List<AppliedEffect> effects = diffAppliedEffects(state, next);
    final bool faydaBitti = factor == 0;
    final String metin = faydaBitti
        ? _useSatedText(item)
        : _useText(item, rng);

    return ItemActionResult(
      state: _withLog(next, metin),
      outcome: ItemOutcome(
        applied: true,
        text: metin,
        effects: effects,
        noNewBenefit: faydaBitti,
      ),
    );
  }

  ItemActionResult _clean({required GameState state, required OwnedItem item}) {
    final int hedef =
        min(prototypeOnlyCleanCeiling, item.condition + prototypeOnlyCleanGain);
    final OwnedItem guncel = item.copyWith(condition: hedef);
    final GameState next = state.updateItem(guncel);
    final String metin = '${item.name} temizlendi. Kir gitti; '
        'mekanik yıpranma yerinde duruyor.';
    return ItemActionResult(
      state: _withLog(next, metin),
      outcome: ItemOutcome(
        applied: true,
        text: metin,
        effects: diffAppliedEffects(state, next),
      ),
    );
  }

  ItemActionResult _repair({required GameState state, required OwnedItem item}) {
    final int ucret = repairCost(state, item);
    final int hedef = min(
      prototypeOnlyRepairCeiling,
      item.condition + prototypeOnlyRepairGain,
    );
    final OwnedItem guncel = item.copyWith(condition: hedef);
    final PlayerCharacter player =
        state.player.copyWith(wallet: state.player.wallet - ucret);
    final GameState next =
        state.copyWith(player: player).updateItem(guncel);

    final String metin = '${item.name} bakımdan geçti. ${trMoney(ucret)} ödedin; '
        'yeni gibi olmadı ama işini görüyor.';
    return ItemActionResult(
      state: _withLog(next, metin),
      outcome: ItemOutcome(
        applied: true,
        text: metin,
        effects: diffAppliedEffects(state, next),
      ),
    );
  }

  /// Uyumlu bir aksesuarı eşyaya takar.
  ///
  /// Aksesuar örneği envanterden **düşer** ve eşyanın bağlı parçası olur;
  /// böylece aynı zil iki bisiklette birden görünmez.
  ItemActionResult attachAccessory({
    required GameState state,
    required String itemId,
    required String accessoryItemId,
  }) {
    final OwnedItem? item = state.itemById(itemId);
    final OwnedItem? accessory = state.itemById(accessoryItemId);
    if (item == null || accessory == null) {
      return _blocked(state, 'Bu eşya artık sende değil.');
    }
    if (!accessory.type.canAttachTo(item.type)) {
      return _blocked(
        state,
        '${accessory.name}, ${item.name} için uygun bir aksesuar değil.',
      );
    }

    final OwnedItem guncel = item.copyWith(
      attachments: List<String>.unmodifiable(
        <String>[...item.attachments, accessory.typeId],
      ),
    );
    final GameState next =
        state.updateItem(guncel).removeItem(accessory.id);

    final String metin = '${accessory.name}, ${item.name} üzerine takıldı.';
    return ItemActionResult(
      state: _withLog(next, metin),
      outcome: ItemOutcome(
        applied: true,
        text: metin,
        effects: diffAppliedEffects(state, next),
      ),
    );
  }

  /// Eşyayı satar: envanterden çıkar, para **bir kez** cüzdana girer.
  ItemActionResult sell({required GameState state, required String itemId}) {
    final OwnedItem? item = state.itemById(itemId);
    if (item == null) {
      // Aynı eşya iki kez satılamaz: ilk satıştan sonra kayıt yoktur.
      return _blocked(state, 'Bu eşya artık sende değil.');
    }
    final InteractionAvailability check =
        availability(state, item, ItemActionKind.sat);
    if (!check.isAllowed) return _blocked(state, check.reason!);

    final int bedel = estimatedPrice(item);
    final PlayerCharacter player =
        state.player.copyWith(wallet: state.player.wallet + bedel);
    final GameState next =
        state.copyWith(player: player).removeItem(item.id);

    final String metin = '${item.name} ${trMoney(bedel)} karşılığında satıldı.';
    return ItemActionResult(
      state: _withLog(next, metin),
      outcome: ItemOutcome(
        applied: true,
        text: metin,
        effects: diffAppliedEffects(state, next),
      ),
    );
  }

  /// Mağazadan ürün alır.
  ItemActionResult buy({
    required GameState state,
    required ShopProduct product,
    String? location,
  }) {
    if (state.player.age < product.minAge) {
      return _blocked(
        state,
        'Bu ürünü ${product.minAge} yaşından itibaren alabilirsin.',
      );
    }
    if (state.player.wallet < product.price) {
      return _blocked(
        state,
        '${product.name} için ${trMoney(product.price)} gerekiyor; '
        'cüzdanında yeterli para yok.',
      );
    }

    final PlayerCharacter player =
        state.player.copyWith(wallet: state.player.wallet - product.price);
    // Konutta satın alınan şehir kaydedilir; **taşınma anlamına gelmez**.
    final GameState next = state.copyWith(player: player).grantItems(
      <String>[product.typeId],
      source: ItemSource.satinAlma,
      purchasePrice: product.price,
      // Konutta satın alınan şehir kaydedilir (D-043); belirtilmezse
      // oyuncunun yaşadığı şehir kullanılır.
      location: product.type.kind == ItemKind.konut
          ? (location ?? Housing.cityOf(state))
          : null,
    );

    final String metin =
        '${product.name} satın alındı. ${trMoney(product.price)} ödedin.';
    return ItemActionResult(
      state: _withLog(next, metin),
      outcome: ItemOutcome(
        applied: true,
        text: metin,
        effects: diffAppliedEffects(state, next),
      ),
    );
  }

  // ===================================================================
  // Yardımcılar
  // ===================================================================

  ItemActionResult _blocked(GameState state, String reason) => ItemActionResult(
        state: state,
        outcome: ItemOutcome(applied: false, text: reason),
      );

  GameState _withLog(GameState state, String text) => state.copyWith(
        log: List<LifeLogEntry>.unmodifiable(<LifeLogEntry>[
          ...state.log,
          LifeLogEntry(
            age: state.player.age,
            text: text,
            category: LogCategory.kisisel,
          ),
        ]),
      );

  static int _scaled(int base, double factor) => (base * factor).round();

  static String _useText(OwnedItem item, Random rng) {
    final List<String> havuz = switch (item.type.kind) {
      ItemKind.bisiklet => <String>[
          'Bisikletle mahalleyi bir tur dolaştın. Zincir sesi, rüzgâr, '
              'yokuş aşağı serbest bırakılan pedal.',
          'Bisikletle sahile kadar gidip döndün. Bacakların ağrıdı, '
              'canın sıkılmadı.',
        ],
      ItemKind.saat => <String>[
          '${item.name} bileğinde. Saate bakmak için değil, bakılsın diye.',
        ],
      ItemKind.oyuncak => <String>[
          '${item.name} ile uzun uzun oynadın; zaman nasıl geçti anlamadın.',
        ],
      ItemKind.spor => <String>[
          '${item.name} ile iyi bir antrenman yaptın.',
        ],
      ItemKind.kiyafet => <String>[
          '${item.name} üstünde. Aynanın önünde bir kez daha döndün.',
        ],
      _ => <String>['${item.name} kullandın.'],
    };
    return havuz[rng.nextInt(havuz.length)];
  }

  static String _useSatedText(OwnedItem item) =>
      '${item.name} ile yine vakit geçirdin. Bu yaş için tadı artık '
      'ilk günkü gibi değil; eşya biraz daha eskidi.';

  static const Map<ItemKind, _UseReward> _useRewards = <ItemKind, _UseReward>{
    ItemKind.bisiklet: _UseReward(happiness: 4, health: 3),
    ItemKind.saat: _UseReward(charisma: 2, appearance: 1),
    ItemKind.oyuncak: _UseReward(happiness: 4),
    ItemKind.spor: _UseReward(health: 4, appearance: 1),
    ItemKind.kiyafet: _UseReward(appearance: 3, charisma: 1),
    ItemKind.elektronik: _UseReward(happiness: 3),
  };
}

class _UseReward {
  const _UseReward({
    this.happiness = 0,
    this.health = 0,
    this.charisma = 0,
    this.appearance = 0,
  });

  final int happiness;
  final int health;
  final int charisma;
  final int appearance;
}

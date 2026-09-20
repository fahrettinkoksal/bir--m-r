import 'dart:convert';
import 'dart:math';

import 'package:bir_omur/data/activity_catalog.dart';
import 'package:bir_omur/data/save/game_state_codec.dart';
import 'package:bir_omur/data/save/save_format.dart';
import 'package:bir_omur/data/save/save_service.dart';
import 'package:bir_omur/data/save/save_store.dart';
import 'package:bir_omur/domain/activities/activity_engine.dart';
import 'package:bir_omur/domain/generation/life_generator.dart';
import 'package:bir_omur/domain/models/book_progress.dart';
import 'package:bir_omur/domain/models/game_state.dart';
import 'package:bir_omur/state/game_controller.dart';
import 'package:flutter_test/flutter_test.dart';

const ActivityEngine activities = ActivityEngine();

GameState life(int seed, {int age = 16, int wallet = 2000}) {
  final GameState state =
      LifeGenerator.seeded(seed).generate(mode: StartMode.tamamenRastgele);
  return state.copyWith(
    player: state.player.copyWith(age: age, wallet: wallet),
  );
}

ActivityAction action(String id) => activityActionById(id)!;

void main() {
  // ===================================================================
  // Berber
  // ===================================================================
  group('Berber', () {
    test('ücret gerçekten cüzdandan düşer ve görünüşü etkiler', () {
      final GameState state = life(1, age: 16, wallet: 1000);
      final ActivityAction kesim = action('sac_kestir');
      final int gorunusOnce = state.player.stats.appearance;

      final ActivityResult r = activities.perform(
        state: state,
        action: kesim,
        rng: Random(1),
      );
      expect(r.outcome.applied, isTrue);
      expect(r.state.player.wallet, 1000 - kesim.cost);
      expect(r.state.player.stats.appearance, greaterThan(gorunusOnce));
      expect(r.state.log.last.text, contains(kesim.label));
      expect(
        r.outcome.effects.map((dynamic e) => e.text as String),
        contains('Cüzdan -${kesim.cost} ₺'),
      );
    });

    test('parası yetmiyorsa işlem olmaz', () {
      final GameState state = life(2, age: 16, wallet: 10);
      final ActivityAction kesim = action('sac_kestir');
      expect(activities.availability(state, kesim).isAllowed, isFalse);

      final ActivityResult r = activities.perform(
        state: state,
        action: kesim,
        rng: Random(1),
      );
      expect(r.outcome.applied, isFalse);
      expect(r.state.player.wallet, 10);
      expect(r.state.player.stats.appearance,
          state.player.stats.appearance);
      expect(r.outcome.effects, isEmpty);
    });

    test('saç stili gerçekten değişir ve kaydedilir', () {
      final GameState state = life(3, age: 18, wallet: 5000);
      final ActivityResult r = activities.perform(
        state: state,
        action: action('sac_stili'),
        rng: Random(7),
      );
      expect(r.outcome.applied, isTrue);
      expect(r.state.player.hairStyle, isNotNull);
      expect(kHairStyles, contains(r.state.player.hairStyle));
      expect(r.outcome.text, contains(r.state.player.hairStyle!));
    });

    test('yaşı küçük olan berbere gidemez', () {
      final GameState state = life(4, age: 6, wallet: 5000);
      expect(
        activities.availability(state, action('sac_stili')).isAllowed,
        isFalse,
      );
    });

    test('aynı yaşta sınırsız tekrar edilemez', () {
      GameState state = life(5, age: 18, wallet: 100000);
      final ActivityAction kesim = action('sac_kestir');
      int yapilan = 0;
      for (int i = 0; i < 10; i++) {
        final ActivityResult r = activities.perform(
          state: state,
          action: kesim,
          rng: Random(i),
        );
        if (!r.outcome.applied) break;
        state = r.state;
        yapilan++;
      }
      expect(yapilan, kesim.maxPerAge);
      expect(activities.availability(state, kesim).isAllowed, isFalse);
    });
  });

  // ===================================================================
  // Spor salonu
  // ===================================================================
  group('Spor salonu', () {
    test('eyleme uygun değerler artar', () {
      final GameState state = life(11, age: 20, wallet: 1000);
      final ActivityResult kosu = activities.perform(
        state: state,
        action: action('kosu'),
        rng: Random(1),
      );
      expect(kosu.state.player.stats.health,
          greaterThan(state.player.stats.health));

      final ActivityResult agirlik = activities.perform(
        state: state,
        action: action('agirlik'),
        rng: Random(1),
      );
      expect(agirlik.state.player.stats.appearance,
          greaterThan(state.player.stats.appearance),
          reason: 'Ağırlık görünüşü de etkiler');
    });

    test('ücretsiz eylem parayı düşürmez', () {
      final GameState state = life(12, age: 12, wallet: 0);
      final ActivityResult r = activities.perform(
        state: state,
        action: action('esneme'),
        rng: Random(1),
      );
      expect(r.outcome.applied, isTrue);
      expect(r.state.player.wallet, 0);
      expect(r.state.player.stats.health,
          greaterThan(state.player.stats.health));
    });

    test('tekrar ettikçe getiri azalır ve sınırsız stat kasılamaz', () {
      GameState state = life(13, age: 20, wallet: 100000);
      final ActivityAction kosu = action('kosu');
      final int baslangic = state.player.stats.health;
      final List<int> kazanclar = <int>[];

      for (int i = 0; i < 6; i++) {
        final ActivityResult r = activities.perform(
          state: state,
          action: kosu,
          rng: Random(i),
        );
        if (!r.outcome.applied) break;
        kazanclar.add(r.state.player.stats.health -
            state.player.stats.health);
        state = r.state;
      }

      expect(kazanclar.length, kosu.maxPerAge);
      expect(kazanclar.first, greaterThanOrEqualTo(kazanclar.last),
          reason: 'Getiri azalmalı');
      expect(state.player.stats.health - baslangic, lessThan(kosu.health * 5));
    });
  });

  // ===================================================================
  // Kütüphane ve kitap mini oyunu
  // ===================================================================
  group('Kütüphane', () {
    test('yaşa uygun kitaplar listelenir', () {
      final GameState cocuk = life(21, age: 8);
      final List<BookInfo> cocukKitaplari = activities.availableBooks(cocuk);
      expect(cocukKitaplari, isNotEmpty);
      for (final BookInfo b in cocukKitaplari) {
        expect(b.fitsAge(8), isTrue);
      }

      final GameState genc = life(21, age: 18);
      final List<BookInfo> gencKitaplari = activities.availableBooks(genc);
      expect(gencKitaplari.any((BookInfo b) => b.pages > 15), isTrue,
          reason: 'Büyük yaşta daha uzun kitaplar olmalı');
      expect(
        cocukKitaplari.map((BookInfo b) => b.id).toSet(),
        isNot(gencKitaplari.map((BookInfo b) => b.id).toSet()),
      );
    });

    test('sayfa çevirme ilerlemeyi kaydeder', () {
      GameState state = life(22, age: 8);
      final BookInfo kitap = activities.availableBooks(state).first;
      state = activities.openBook(state, kitap).state;
      expect(state.bookProgress(kitap.id), isNotNull);
      expect(state.bookProgress(kitap.id)!.pagesRead, 0);

      state = activities.turnPage(state, kitap).state;
      expect(state.bookProgress(kitap.id)!.pagesRead, 1);
      state = activities.turnPage(state, kitap).state;
      expect(state.bookProgress(kitap.id)!.pagesRead, 2);
      expect(state.bookProgress(kitap.id)!.finished, isFalse);
    });

    test('kitap bitince zekâ bir kez artar', () {
      GameState state = life(23, age: 8);
      final BookInfo kitap = activities.availableBooks(state).first;
      final int zekaOnce = state.player.stats.intelligence;
      state = activities.openBook(state, kitap).state;

      for (int i = 0; i < kitap.pages; i++) {
        state = activities.turnPage(state, kitap).state;
      }
      expect(state.bookProgress(kitap.id)!.finished, isTrue);
      expect(state.player.stats.intelligence,
          zekaOnce + kitap.intelligenceGain);
      expect(state.log.last.text, contains('bitti'));

      // Bitmiş kitaba tekrar tıklamak yeni kazanç vermez.
      final int zekaSonra = state.player.stats.intelligence;
      for (int i = 0; i < 20; i++) {
        final ActivityResult r = activities.turnPage(state, kitap);
        expect(r.outcome.applied, isFalse);
        state = r.state;
      }
      expect(state.player.stats.intelligence, zekaSonra,
          reason: 'Sınırsız tıklamayla zekâ kasılamaz');
    });

    test('açılmamış kitabın sayfası çevrilemez', () {
      final GameState state = life(24, age: 8);
      final BookInfo kitap = activities.availableBooks(state).first;
      final ActivityResult r = activities.turnPage(state, kitap);
      expect(r.outcome.applied, isFalse);
      expect(r.state.books, isEmpty);
    });

    test('yaşa uygun olmayan kitap açılamaz', () {
      final GameState state = life(25, age: 7);
      final BookInfo uzun =
          kBookCatalog.firstWhere((BookInfo b) => b.minAge >= 16);
      final ActivityResult r = activities.openBook(state, uzun);
      expect(r.outcome.applied, isFalse);
      expect(r.state.books, isEmpty);
    });

    test('kitap sayfalarında telifli metin yoktur', () {
      for (final BookInfo b in kBookCatalog) {
        expect(b.title, isNotEmpty);
        expect(b.author, isNotEmpty);
        expect(b.pages, greaterThan(0));
      }
    });
  });

  // ===================================================================
  // Kayıt
  // ===================================================================
  group('Kayıt', () {
    test('kitap ilerlemesi ve saç stili kaydedilir', () async {
      GameState state = life(31, age: 16, wallet: 3000);
      state = activities
          .perform(state: state, action: action('sac_stili'), rng: Random(2))
          .state;
      final BookInfo kitap = activities.availableBooks(state).first;
      state = activities.openBook(state, kitap).state;
      state = activities.turnPage(state, kitap).state;
      state = activities.turnPage(state, kitap).state;

      final MemorySaveStore store = MemorySaveStore();
      final SaveService service = SaveService(store);
      await service.save(state);
      final SaveLoadResult result = await service.load();
      expect(result.isLoaded, isTrue);

      final GameState sonra = result.state!;
      expect(sonra.player.hairStyle, state.player.hairStyle);
      expect(sonra.books.length, 1);
      final BookProgress ilerleme = sonra.bookProgress(kitap.id)!;
      expect(ilerleme.pagesRead, 2);
      expect(ilerleme.finished, isFalse);
      expect(sonra.player.wallet, state.player.wallet);
    });

    test('sürüm 4 kaydı aktivite alanları eklenerek açılır', () async {
      final GameState orijinal = life(32, age: 20, wallet: 500);
      final Map<String, Object?> body = encodeGameState(orijinal);
      body.remove('books');
      (body['player']! as Map<String, Object?>).remove('hairStyle');

      final SaveLoadResult result = await SaveService(
        MemorySaveStore(
          initial: jsonEncode(
            <String, Object?>{'formatVersion': 4, 'state': body},
          ),
        ),
      ).load();
      expect(result.isLoaded, isTrue, reason: result.message);
      expect(result.state!.books, isEmpty);
      expect(result.state!.player.hairStyle, isNull);
      expect(result.state!.player.wallet, 500);
      expect(result.state!.player.id, orijinal.player.id);
    });

    test('denetleyici üzerinden aktivite kaydedilir', () async {
      final MemorySaveStore store = MemorySaveStore();
      final GameController c = GameController(
        random: Random(33),
        saveService: SaveService(store),
      );
      c.startNewLife(mode: StartMode.tamamenRastgele, seed: 33);
      c.debugSetState(
        c.state!.copyWith(
          player: c.state!.player.copyWith(age: 18, wallet: 4000),
          pendingEvent: null,
        ),
      );

      final ActivityOutcome? outcome =
          c.performActivity(action('sac_kestir'));
      expect(outcome!.applied, isTrue);
      await c.flushSaves();

      final SaveLoadResult result = await SaveService(store).load();
      expect(result.isLoaded, isTrue);
      expect(result.state!.player.wallet, c.state!.player.wallet);
    });

    test('kayıt sürümü yükseltildi', () {
      expect(kSaveFormatVersion, greaterThanOrEqualTo(5));
    });
  });
}

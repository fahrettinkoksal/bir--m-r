import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:bir_omur/data/save/game_state_codec.dart';
import 'package:bir_omur/data/save/save_format.dart';
import 'package:bir_omur/data/save/save_service.dart';
import 'package:bir_omur/data/save/save_store.dart';
import 'package:bir_omur/domain/events/event_engine.dart';
import 'package:bir_omur/domain/generation/life_generator.dart';
import 'package:bir_omur/domain/generation/life_progression.dart';
import 'package:bir_omur/domain/interaction/friendship.dart';
import 'package:bir_omur/domain/models/education.dart';
import 'package:bir_omur/domain/models/game_event.dart';
import 'package:bir_omur/domain/models/game_state.dart';
import 'package:bir_omur/domain/models/interaction.dart';
import 'package:bir_omur/domain/models/owned_item.dart';
import 'package:bir_omur/domain/models/person.dart';
import 'package:bir_omur/domain/models/relation.dart';
import 'package:bir_omur/state/game_controller.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/test_flow.dart';

/// Kayıt servisiyle çalışan bir denetleyici kurulumu.
class Kurulum {
  Kurulum({int seed = 7, MemorySaveStore? store})
      : store = store ?? MemorySaveStore() {
    service = SaveService(this.store);
    controller = GameController(random: Random(seed), saveService: service);
  }

  final MemorySaveStore store;
  late final SaveService service;
  late final GameController controller;
}

/// Durumu kaydedip geri yükler; kayıt yolunun tamamını kullanır.
Future<GameState> roundTrip(GameState state) async {
  final MemorySaveStore store = MemorySaveStore();
  final SaveService service = SaveService(store);
  await service.save(state);
  final SaveLoadResult result = await service.load();
  expect(result.status, SaveLoadStatus.yuklendi,
      reason: 'Kayıt geri okunabilmeli: ${result.message}');
  return result.state!;
}

void main() {
  // ===================================================================
  // 1) Temel gidiş-dönüş
  // ===================================================================
  group('Yeni hayat kaydedilip yüklenir', () {
    test('temel bilgiler aynı kalır', () async {
      for (int seed = 0; seed < 10; seed++) {
        final GameState once =
            LifeGenerator.seeded(seed).generate(mode: StartMode.tamamenRastgele);
        final GameState sonra = await roundTrip(once);

        expect(sonra.seed, once.seed);
        expect(sonra.player.id, once.player.id);
        expect(sonra.player.fullName, once.player.fullName);
        expect(sonra.player.gender, once.player.gender);
        expect(sonra.player.age, once.player.age);
        expect(sonra.player.birthCity, once.player.birthCity);
        expect(sonra.player.wallet, once.player.wallet);
        expect(sonra.player.fame, once.player.fame);
        expect(sonra.parentalStatus, once.parentalStatus);
        expect(sonra.people.length, once.people.length);
        expect(sonra.pets.length, once.pets.length);
        expect(sonra.log.length, once.log.length);
      }
    });

    test('kişilerin bütün alanları korunur', () async {
      final GameState once =
          LifeGenerator.seeded(3).generate(mode: StartMode.tamamenRastgele);
      final GameState sonra = await roundTrip(once);

      for (final Person beklenen in once.people) {
        final Person? bulunan = sonra.personById(beklenen.id);
        expect(bulunan, isNotNull, reason: '${beklenen.id} kaybolmamalı');
        expect(bulunan!.firstName, beklenen.firstName);
        expect(bulunan.lastName, beklenen.lastName);
        expect(bulunan.gender, beklenen.gender);
        expect(bulunan.relation, beklenen.relation);
        expect(bulunan.age, beklenen.age);
        expect(bulunan.isAlive, beklenen.isAlive);
        expect(bulunan.inPlayerHousehold, beklenen.inPlayerHousehold);
        expect(bulunan.employment, beklenen.employment);
        expect(bulunan.occupation, beklenen.occupation);
        expect(bulunan.wealth, beklenen.wealth);
        expect(bulunan.bond, beklenen.bond);
        expect(bulunan.schoolLevel, beklenen.schoolLevel);
        expect(bulunan.schoolTie, beklenen.schoolTie);
      }
      // Aynı kişi için ikinci bir kayıt oluşmaz.
      expect(
        sonra.people.map((Person p) => p.id).toSet().length,
        sonra.people.length,
      );
    });

    test('evcil hayvanlar ve hayat günlüğü korunur', () async {
      // Evcil hayvanı olan bir hayat bul.
      GameState? evcilli;
      for (int seed = 0; seed < 40 && evcilli == null; seed++) {
        final GameState s =
            LifeGenerator.seeded(seed).generate(mode: StartMode.tamamenRastgele);
        if (s.pets.isNotEmpty) evcilli = s;
      }
      expect(evcilli, isNotNull, reason: 'Evcil hayvanlı hayat üretilebilmeli');

      final GameState sonra = await roundTrip(evcilli!);
      expect(sonra.pets.length, evcilli.pets.length);
      expect(sonra.pets.first.id, evcilli.pets.first.id);
      expect(sonra.pets.first.name, evcilli.pets.first.name);
      expect(sonra.pets.first.species, evcilli.pets.first.species);

      for (int i = 0; i < evcilli.log.length; i++) {
        expect(sonra.log[i].age, evcilli.log[i].age);
        expect(sonra.log[i].text, evcilli.log[i].text);
        expect(sonra.log[i].category, evcilli.log[i].category);
      }
    });

    test('GameState alanlarının hiçbiri kayıttan düşmüyor', () async {
      // Bütün alanları varsayılandan farklı bir duruma getir; kaydet; karşılaştır.
      final GameState temel =
          LifeGenerator.seeded(11).generate(mode: StartMode.tamamenRastgele);
      final GameState dolu = temel.copyWith(
        player: temel.player.copyWith(age: 17, wallet: 1234, fame: 9),
        education: const EducationState(
          enrolled: true,
          grade: 11,
          startedAtAge: 6,
        ),
        interactionCounts: const <String, int>{'anne|vakitGecir': 2},
        lastInteractionAge: const <String, int>{'anne': 16},
        storyFlags: const <String>{'a_izi', 'b_izi'},
        seenEventIds: const <String>{'olay_1', 'olay_2'},
        lastEventAge: const <String, int>{'olay_1': 12},
        storyPeople: const <String, String>{'rol': 'anne'},
        progressSinceLastEvent: 2,
        extraEventsThisAge: 1,
      );

      // Eşyalar artık gerçek örnekler; tür kümesi bundan türetilir.
      final GameState esyali = dolu.grantItems(
        <String>['bisiklet', 'defter'],
        source: ItemSource.hediye,
      );
      final GameState sonra = await roundTrip(esyali);
      expect(sonra.player.age, 17);
      expect(sonra.player.wallet, 1234);
      expect(sonra.player.fame, 9);
      expect(sonra.player.stats.appearance, dolu.player.stats.appearance);
      expect(sonra.player.stats.happiness, dolu.player.stats.happiness);
      expect(sonra.player.stats.health, dolu.player.stats.health);
      expect(sonra.player.stats.intelligence, dolu.player.stats.intelligence);
      expect(sonra.player.stats.charisma, dolu.player.stats.charisma);
      expect(sonra.education.enrolled, isTrue);
      expect(sonra.education.grade, 11);
      expect(sonra.education.startedAtAge, 6);
      expect(sonra.education.finished, isFalse);
      expect(sonra.education.level, SchoolLevel.lise);
      expect(sonra.interactionCounts, dolu.interactionCounts);
      expect(sonra.lastInteractionAge, dolu.lastInteractionAge);
      expect(sonra.storyFlags, dolu.storyFlags);
      expect(sonra.possessions, esyali.possessions);
      expect(sonra.items.length, esyali.items.length);
      for (final OwnedItem beklenen in esyali.items) {
        final OwnedItem bulunan = sonra.itemById(beklenen.id)!;
        expect(bulunan.typeId, beklenen.typeId);
        expect(bulunan.condition, beklenen.condition);
        expect(bulunan.source, beklenen.source);
        expect(bulunan.acquiredAtAge, beklenen.acquiredAtAge);
      }
      expect(sonra.seenEventIds, dolu.seenEventIds);
      expect(sonra.lastEventAge, dolu.lastEventAge);
      expect(sonra.storyPeople, dolu.storyPeople);
      expect(sonra.progressSinceLastEvent, 2);
      expect(sonra.extraEventsThisAge, 1);
    });
  });

  // ===================================================================
  // 2) Okul, arkadaşlık ve ilerleme
  // ===================================================================
  group('Okul ve ilişkiler kayıttan sonra korunur', () {
    test('yakın arkadaş olan sınıf arkadaşı iki listede de kalır', () async {
      final GameController controller =
          GameController(random: Random(21), saveService: null);
      controller.startNewLife(mode: StartMode.tamamenRastgele, seed: 21);
      advanceToAge(controller, LifeProgression.prototypeOnlySchoolStartAge);
      resolvePendingEvents(controller);

      final Person sinifArkadasi = controller.state!.currentClassmates.first;
      final GameState yakinlasmis = const Friendship()
          .promoteToFriend(controller.state!, sinifArkadasi.id)
          .state;

      final GameState sonra = await roundTrip(yakinlasmis);
      expect(
        sonra.currentClassmates.map((Person p) => p.id),
        contains(sinifArkadasi.id),
        reason: 'Okul bağı kayıttan sonra da korunmalı',
      );
      expect(
        sonra.people
            .where((Person p) => p.relation == RelationType.arkadas)
            .map((Person p) => p.id),
        contains(sinifArkadasi.id),
      );
      expect(sonra.personById(sinifArkadasi.id)!.schoolTie,
          SchoolTie.sinifArkadasi);
      expect(sonra.people.length, yakinlasmis.people.length,
          reason: 'İkinci NPC oluşmamalı');
    });

    test('kademe değişiminden sonra eski ve yeni okul kişileri korunur',
        () async {
      final GameController controller =
          GameController(random: Random(22), saveService: null);
      controller.startNewLife(mode: StartMode.tamamenRastgele, seed: 22);
      advanceToAge(controller, LifeProgression.prototypeOnlySchoolStartAge);
      resolvePendingEvents(controller);
      final List<String> ilkokullular = controller.state!.people
          .where((Person p) => p.schoolLevel == SchoolLevel.ilkokul)
          .map((Person p) => p.id)
          .toList(growable: false);

      advanceToAge(controller, LifeProgression.prototypeOnlySchoolStartAge + 4);
      resolvePendingEvents(controller);
      final GameState once = controller.state!;
      expect(once.education.level, SchoolLevel.ortaokul);

      final GameState sonra = await roundTrip(once);
      for (final String id in ilkokullular) {
        expect(sonra.personById(id), isNotNull, reason: 'Eski tanıdık silinmez');
      }
      expect(
        sonra.currentClassmates.map((Person p) => p.id).toSet(),
        once.currentClassmates.map((Person p) => p.id).toSet(),
      );
      expect(
        sonra.pastSchoolPeople.map((Person p) => p.id).toSet(),
        once.pastSchoolPeople.map((Person p) => p.id).toSet(),
      );
      expect(sonra.education.grade, once.education.grade);
    });

    test('yükledikten sonra aynı kademede yeni okul kişisi üretilmez',
        () async {
      final Kurulum k = Kurulum(seed: 24);
      k.controller.startNewLife(mode: StartMode.tamamenRastgele, seed: 24);
      advanceToAge(k.controller, LifeProgression.prototypeOnlySchoolStartAge);
      resolvePendingEvents(k.controller);
      await k.controller.flushSaves();

      final Set<String> okulKisileriOnce = k.controller.state!.people
          .where((Person p) => p.schoolTie != null)
          .map((Person p) => p.id)
          .toSet();
      expect(okulKisileriOnce, isNotEmpty);

      // Uygulama kapanıp açılıyor ve aynı kademede bir yaş ilerliyor.
      final Kurulum ikinci = Kurulum(seed: 55, store: k.store);
      await ikinci.controller.restoreSavedLife();
      resolvePendingEvents(ikinci.controller);
      ikinci.controller.ageUp();
      resolvePendingEvents(ikinci.controller);

      final Set<String> sonra = ikinci.controller.state!.people
          .where((Person p) => p.schoolTie != null)
          .map((Person p) => p.id)
          .toSet();
      expect(sonra, okulKisileriOnce,
          reason: 'Kayıttan dönünce sınıf yeniden üretilmemeli');
    });

    test('para, eşya, yakınlık ve istatistik değişiklikleri kaybolmaz',
        () async {
      final Kurulum kurulum = Kurulum(seed: 23);
      final GameController controller = kurulum.controller;
      controller.startNewLife(mode: StartMode.tamamenRastgele, seed: 23);
      advanceToAge(controller, 12);
      resolvePendingEvents(controller);

      // Bilinen değişiklikler uygula.
      final Person anne = controller.state!.people.firstWhere(
        (Person p) => p.relation == RelationType.anne,
      );
      controller.interact(anne.id, InteractionKind.vakitGecir);
      resolvePendingEvents(controller);

      final GameState once = controller.state!;
      await controller.flushSaves();

      final SaveLoadResult result = await kurulum.service.load();
      expect(result.status, SaveLoadStatus.yuklendi);
      final GameState sonra = result.state!;

      expect(sonra.player.wallet, once.player.wallet);
      expect(sonra.possessions, once.possessions);
      expect(sonra.personById(anne.id)!.bond, once.personById(anne.id)!.bond);
      expect(sonra.player.stats.happiness, once.player.stats.happiness);
      expect(sonra.interactionCounts, once.interactionCounts);
      expect(sonra.lastInteractionAge, once.lastInteractionAge);
    });
  });

  // ===================================================================
  // 3) Bekleyen olay
  // ===================================================================
  group('Bekleyen olay', () {
    /// Bekleyen olayı olan bir durum üretir.
    GameState withPendingEvent(int seed) {
      final GameController controller =
          GameController(random: Random(seed), saveService: null);
      controller.startNewLife(mode: StartMode.tamamenRastgele, seed: seed);
      for (int i = 0; i < 30; i++) {
        if (controller.state!.hasPendingEvent) return controller.state!;
        controller.ageUp();
      }
      fail('Bekleyen olaylı bir duruma ulaşılamadı');
    }

    test('aynı olay, aynı kişi ve aynı seçeneklerle geri gelir', () async {
      for (int seed = 0; seed < 8; seed++) {
        final GameState once = withPendingEvent(seed);
        final ActiveEvent beklenen = once.pendingEvent!;
        final GameState sonra = await roundTrip(once);

        final ActiveEvent bulunan = sonra.pendingEvent!;
        expect(bulunan.eventId, beklenen.eventId);
        expect(bulunan.personId, beklenen.personId,
            reason: 'Olayın kişisi değişmemeli');
        expect(bulunan.text, beklenen.text,
            reason: 'Metin yeniden üretilmemeli');
        expect(bulunan.category, beklenen.category);
        expect(bulunan.choices.length, beklenen.choices.length);
        for (int i = 0; i < beklenen.choices.length; i++) {
          expect(bulunan.choices[i].id, beklenen.choices[i].id);
          expect(bulunan.choices[i].label, beklenen.choices[i].label);
          expect(bulunan.choices[i].resultText, beklenen.choices[i].resultText);
        }
      }
    });

    test('seçim sonrası etkiler bir kez uygulanır', () async {
      final GameState once = withPendingEvent(4);
      final String secim = once.pendingEvent!.choices.first.id;

      const EventEngine engine = EventEngine();
      // Kayıttan yüklenen durumda seçim yapılır.
      final GameState yuklenen = await roundTrip(once);
      final GameState a = engine.resolve(yuklenen, secim, rng: Random(99));
      // Aynı seçim, kayıt yapılmadan doğrudan uygulanır.
      final GameState b = engine.resolve(once, secim, rng: Random(99));

      expect(a.player.stats.happiness, b.player.stats.happiness);
      expect(a.player.wallet, b.player.wallet);
      expect(a.possessions, b.possessions);
      expect(a.storyFlags, b.storyFlags);
      expect(a.log.length, once.log.length + 1,
          reason: 'Sonuç günlüğe tam bir kez yazılmalı');
      expect(a.log.length, b.log.length);
      expect(a.hasPendingEvent, isFalse);
      expect(a.seenEventIds, b.seenEventIds);
      expect(a.lastEventAge, b.lastEventAge);
      if (once.pendingEvent!.personId != null) {
        final String pid = once.pendingEvent!.personId!;
        expect(a.personById(pid)!.bond, b.personById(pid)!.bond,
            reason: 'Yakınlık etkisi bir kez uygulanmalı');
      }
    });
  });

  // ===================================================================
  // 4) Otomatik kayıt ve devam etme
  // ===================================================================
  group('Otomatik kayıt', () {
    test('yeni hayat ve yaş alma kaydedilir', () async {
      final Kurulum k = Kurulum(seed: 31);
      expect(await k.service.hasSave(), isFalse);

      k.controller.startNewLife(mode: StartMode.tamamenRastgele, seed: 31);
      await k.controller.flushSaves();
      expect(await k.service.hasSave(), isTrue);

      final int yazmaOnce = k.store.writeCount;
      resolvePendingEvents(k.controller);
      k.controller.ageUp();
      await k.controller.flushSaves();
      expect(k.store.writeCount, greaterThan(yazmaOnce),
          reason: 'Yaş alma da kaydedilmeli');

      final SaveLoadResult result = await k.service.load();
      expect(result.isLoaded, isTrue);
      expect(result.state!.player.age, k.controller.state!.player.age);
    });

    test('etkileşim ve olay seçimi de kaydedilir', () async {
      final Kurulum k = Kurulum(seed: 32);
      k.controller.startNewLife(mode: StartMode.tamamenRastgele, seed: 32);
      advanceToAge(k.controller, 10);
      await k.controller.flushSaves();

      final int yazmaOnce = k.store.writeCount;
      final Person anne = k.controller.state!.people
          .firstWhere((Person p) => p.relation == RelationType.anne);
      k.controller.interact(anne.id, InteractionKind.vakitGecir);
      await k.controller.flushSaves();
      expect(k.store.writeCount, greaterThan(yazmaOnce));

      final SaveLoadResult result = await k.service.load();
      expect(
        result.state!.personById(anne.id)!.bond,
        k.controller.state!.personById(anne.id)!.bond,
      );
    });

    test('kayıtlı hayata devam edilir', () async {
      final MemorySaveStore store = MemorySaveStore();
      final Kurulum ilk = Kurulum(seed: 33, store: store);
      ilk.controller.startNewLife(mode: StartMode.tamamenRastgele, seed: 33);
      advanceToAge(ilk.controller, 9);
      await ilk.controller.flushSaves();
      final GameState kaydedilen = ilk.controller.state!;

      // Uygulama kapanıp yeniden açılıyor.
      final Kurulum ikinci = Kurulum(seed: 44, store: store);
      await ikinci.controller.checkForSavedLife();
      expect(ikinci.controller.hasSavedLife, isTrue);
      expect(ikinci.controller.hasLife, isFalse);

      final SaveLoadStatus status = await ikinci.controller.restoreSavedLife();
      expect(status, SaveLoadStatus.yuklendi);
      expect(ikinci.controller.hasLife, isTrue);
      expect(ikinci.controller.state!.player.id, kaydedilen.player.id);
      expect(ikinci.controller.state!.player.age, kaydedilen.player.age);
      expect(ikinci.controller.state!.people.length, kaydedilen.people.length);
    });

    test('hayatı ekrandan kaldırmak kaydı silmez', () async {
      final Kurulum k = Kurulum(seed: 34);
      k.controller.startNewLife(mode: StartMode.tamamenRastgele, seed: 34);
      await k.controller.flushSaves();

      k.controller.clearLife();
      expect(k.controller.hasLife, isFalse);
      expect(await k.service.hasSave(), isTrue,
          reason: 'Başlangıç ekranına dönmek kaydı silmemeli');
    });

    test('kayıt yalnızca açıkça silinir', () async {
      final Kurulum k = Kurulum(seed: 35);
      k.controller.startNewLife(mode: StartMode.tamamenRastgele, seed: 35);
      await k.controller.flushSaves();
      expect(await k.service.hasSave(), isTrue);

      await k.controller.deleteSavedLife();
      expect(await k.service.hasSave(), isFalse);
      expect(k.controller.hasSavedLife, isFalse);
    });
  });

  // ===================================================================
  // 5) Bozuk ve desteklenmeyen kayıtlar
  // ===================================================================
  group('Bozuk kayıt', () {
    test('okunamayan dosya uygulamayı çökertmez', () async {
      for (final String bozuk in <String>[
        '',
        'bu json değil',
        '{"formatVersion": 1}',
        '{"formatVersion": 1, "state": {}}',
        '{"state": {"seed": 1}}',
        '[1,2,3]',
      ]) {
        final SaveService service = SaveService(MemorySaveStore(initial: bozuk));
        final SaveLoadResult result = await service.load();
        expect(result.status, SaveLoadStatus.bozuk,
            reason: 'Bozuk kayıt bildirilmeli: $bozuk');
        expect(result.message, isNotEmpty);
        expect(result.state, isNull);
      }
    });

    test('daha yeni sürümden gelen kayıt anlaşılır biçimde reddedilir',
        () async {
      final GameState state =
          LifeGenerator.seeded(2).generate(mode: StartMode.tamamenRastgele);
      final String ileri = jsonEncode(<String, Object?>{
        'formatVersion': kSaveFormatVersion + 1,
        'state': encodeGameState(state),
      });
      final SaveService service = SaveService(MemorySaveStore(initial: ileri));
      final SaveLoadResult result = await service.load();
      expect(result.status, SaveLoadStatus.bozuk);
      expect(result.message, contains('güncelle'));
    });

    test('bozuk kayıt bulununca üzerine otomatik yazılmaz', () async {
      final MemorySaveStore store = MemorySaveStore(initial: 'bozuk içerik');
      final GameController controller = GameController(
        random: Random(5),
        saveService: SaveService(store),
      );

      await controller.checkForSavedLife();
      expect(controller.hasSavedLife, isTrue);

      final SaveLoadStatus status = await controller.restoreSavedLife();
      expect(status, SaveLoadStatus.bozuk);
      expect(controller.saveProblem, isNotNull);
      expect(controller.hasLife, isFalse);
      expect(await store.read(), 'bozuk içerik',
          reason: 'Bozuk dosyaya dokunulmamalı');
      expect(store.writeCount, 0);
    });

    test('kullanıcı yeni hayat başlatınca kayıt yeniden yazılır', () async {
      final MemorySaveStore store = MemorySaveStore(initial: 'bozuk içerik');
      final GameController controller = GameController(
        random: Random(5),
        saveService: SaveService(store),
      );
      await controller.restoreSavedLife();
      expect(controller.saveProblem, isNotNull);

      // Kullanıcı onayladı: yeni hayat başlıyor.
      await controller.deleteSavedLife();
      controller.startNewLife(mode: StartMode.tamamenRastgele, seed: 5);
      await controller.flushSaves();

      expect(controller.saveProblem, isNull);
      final SaveLoadResult result = await SaveService(store).load();
      expect(result.isLoaded, isTrue);
    });

    test('asıl dosya bozulursa yedekten okunur', () async {
      final GameState state =
          LifeGenerator.seeded(8).generate(mode: StartMode.tamamenRastgele);
      final MemorySaveStore store = MemorySaveStore();
      final SaveService service = SaveService(store);
      await service.save(state);
      final String saglam = (await store.read())!;

      // İkinci yazma sırasında kesinti olmuş gibi: asıl dosya yarım kaldı,
      // yedekte sağlam kayıt duruyor.
      final MemorySaveStore bozuk = MemorySaveStore(
        initial: saglam.substring(0, saglam.length ~/ 2),
        initialBackup: saglam,
      );
      final SaveLoadResult result = await SaveService(bozuk).load();
      expect(result.isLoaded, isTrue, reason: 'Yedek kayıt kurtarmalı');
      expect(result.state!.player.id, state.player.id);
    });
  });

  // ===================================================================
  // 6) Gerçek dosya deposu
  // ===================================================================
  group('Dosya deposu', () {
    late Directory temp;

    setUp(() async {
      temp = await Directory.systemTemp.createTemp('bir_omur_kayit_test');
    });

    tearDown(() async {
      if (await temp.exists()) await temp.delete(recursive: true);
    });

    test('kayıt diske yazılır ve geri okunur', () async {
      final FileSaveStore store = FileSaveStore(temp);
      final SaveService service = SaveService(store);
      expect(await service.hasSave(), isFalse);

      final GameState state =
          LifeGenerator.seeded(12).generate(mode: StartMode.tamamenRastgele);
      await service.save(state);
      expect(await service.hasSave(), isTrue);

      final SaveLoadResult result = await service.load();
      expect(result.isLoaded, isTrue);
      expect(result.state!.player.id, state.player.id);
    });

    test('ikinci yazmada bir önceki kayıt yedeklenir', () async {
      final FileSaveStore store = FileSaveStore(temp);
      final SaveService service = SaveService(store);

      final GameState ilk =
          LifeGenerator.seeded(13).generate(mode: StartMode.tamamenRastgele);
      await service.save(ilk);
      final GameState ikinci = ilk.copyWith(
        player: ilk.player.copyWith(age: ilk.player.age + 1),
      );
      await service.save(ikinci);

      expect(await store.readBackup(), isNotNull);
      final SaveLoadResult result = await service.load();
      expect(result.state!.player.age, ikinci.player.age);
    });

    test('silme dosyaları temizler', () async {
      final FileSaveStore store = FileSaveStore(temp);
      final SaveService service = SaveService(store);
      await service.save(
        LifeGenerator.seeded(14).generate(mode: StartMode.tamamenRastgele),
      );
      await service.clear();
      expect(await service.hasSave(), isFalse);
      expect(await store.readBackup(), isNull);
    });
  });
}

import 'dart:convert';
import 'dart:math';

import 'package:bir_omur/data/save/game_state_codec.dart';
import 'package:bir_omur/data/save/save_service.dart';
import 'package:bir_omur/data/save/save_store.dart';
import 'package:bir_omur/domain/generation/life_generator.dart';
import 'package:bir_omur/domain/generation/life_progression.dart';
import 'package:bir_omur/domain/interaction/family_interactions.dart';
import 'package:bir_omur/domain/life/inheritance.dart';
import 'package:bir_omur/domain/life/mortality.dart';
import 'package:bir_omur/domain/models/game_state.dart';
import 'package:bir_omur/domain/models/owned_item.dart';
import 'package:bir_omur/domain/models/person.dart';
import 'package:bir_omur/domain/models/relation.dart';
import 'package:bir_omur/domain/models/wealth.dart';
import 'package:bir_omur/state/game_controller.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/test_flow.dart';

GameState hayat(int seed, {int age = 30}) {
  final GameState state =
      LifeGenerator.seeded(seed).generate(mode: StartMode.tamamenRastgele);
  return state.copyWith(player: state.player.copyWith(age: age));
}

/// Belirli bir kişiyi vefat ettirir (kayıt silinmez).
GameState vefatEttir(GameState state, String personId) {
  final List<Person> people = state.people
      .map((Person p) => p.id == personId
          ? p.copyWith(isAlive: false, inPlayerHousehold: false)
          : p)
      .toList(growable: false);
  return state.copyWith(people: List<Person>.unmodifiable(people));
}

Person? kisiTur(GameState state, RelationType relation) {
  for (final Person p in state.people) {
    if (p.relation == relation) return p;
  }
  return null;
}

void main() {
  // ===================================================================
  // Ölüm eğilimi
  // ===================================================================
  group('Ölüm ihtimali', () {
    test('yaş ilerledikçe artar, çocuklukta çok düşüktür', () {
      double p(int age) => Mortality.prototypeOnlyYearlyChance(age);
      expect(p(8), lessThan(0.002));
      expect(p(8), lessThan(p(45)));
      expect(p(45), lessThan(p(70)));
      expect(p(70), lessThan(p(85)));
      expect(p(85), lessThan(p(100)));
      expect(p(100), lessThanOrEqualTo(0.95));
    });

    test('düşük sağlık riski artırır, yüksek sağlık azaltır', () {
      final double dusuk =
          Mortality.prototypeOnlyYearlyChance(60, health: 10);
      final double yuksek =
          Mortality.prototypeOnlyYearlyChance(60, health: 95);
      expect(dusuk, greaterThan(yuksek));
    });

    test('her yıl kimse ölmek zorunda değil', () {
      // 20 hayatta 5 yıl: ölümsüz bir yıl mutlaka olmalı.
      int olumsuzYil = 0;
      for (int seed = 0; seed < 20; seed++) {
        GameState state = hayat(seed, age: 8);
        for (int i = 0; i < 5; i++) {
          final int onceki =
              state.people.where((Person p) => !p.isAlive).length;
          state = LifeProgression(Random(seed * 10 + i)).advanceOneYear(state);
          if (state.deceased) break;
          final int sonraki =
              state.people.where((Person p) => !p.isAlive).length;
          if (onceki == sonraki) olumsuzYil++;
        }
      }
      expect(olumsuzYil, greaterThan(50),
          reason: 'Ölüm sürekli değil, seyrek olmalı');
    });

    test('küçük yaşta oyuncu ölümü çok seyrektir', () {
      int olen = 0;
      for (int seed = 0; seed < 60; seed++) {
        final GameController c = GameController(random: Random(seed));
        c.startNewLife(mode: StartMode.tamamenRastgele, seed: seed);
        advanceToAge(c, 12);
        if (c.state!.deceased) olen++;
      }
      expect(olen, lessThan(6),
          reason: 'Çocuklukta ölüm üreten aşırı bir sistem olmamalı');
    });
  });

  // ===================================================================
  // Vefat edenin kaydı
  // ===================================================================
  group('Vefat eden kişi', () {
    test('kayıttan silinmez, yaşı sabitlenir ve haneden düşer', () {
      GameState state = hayat(1, age: 40);
      final Person anne = kisiTur(state, RelationType.anne)!;
      final int kisiSayisi = state.people.length;

      state = vefatEttir(state, anne.id);
      final Person vefat =
          state.people.firstWhere((Person p) => p.id == anne.id);

      expect(state.people.length, kisiSayisi, reason: 'Kayıt silinmez');
      expect(vefat.isAlive, isFalse);
      expect(vefat.inPlayerHousehold, isFalse);
      expect(vefat.fullName, anne.fullName, reason: 'Anılar korunur');

      // Bir yıl daha geçse de yaşı artmaz.
      final GameState sonra =
          LifeProgression(Random(3)).advanceOneYear(state);
      final Person hala =
          sonra.people.firstWhere((Person p) => p.id == anne.id);
      expect(hala.age, vefat.age);
      expect(hala.isAlive, isFalse);
    });

    test('vefat eden kişiyle yeni etkileşim açılmaz', () {
      GameState state = hayat(2, age: 20);
      final Person baba = kisiTur(state, RelationType.baba)!;
      const FamilyInteractions etkilesim = FamilyInteractions();

      state = vefatEttir(state, baba.id);
      final Person vefat =
          state.people.firstWhere((Person p) => p.id == baba.id);

      expect(etkilesim.availableKinds(state, vefat), isEmpty,
          reason: 'Vefat edenle sohbet, hediye veya para isteme olmaz');
    });

    test('hane sayısı doğru güncellenir', () {
      GameState state = hayat(3, age: 12);
      final Person haneUyesi = state.people.firstWhere(
        (Person p) => p.isAlive && p.inPlayerHousehold,
        orElse: () => state.people.first,
      );
      final int once = state.householdMembers.length;

      state = vefatEttir(state, haneUyesi.id);
      expect(state.householdMembers.length, once - 1);
      expect(
        state.householdMembers.any((Person p) => p.id == haneUyesi.id),
        isFalse,
        reason: 'Vefat eden hane sakini gibi gösterilmez',
      );
    });

    test('olay motoru vefat edeni canlı gibi kullanmaz', () {
      GameState state = hayat(4, age: 15);
      for (final Person p in state.people) {
        state = vefatEttir(state, p.id);
      }
      // 10 yıl ilerlet: vefat edenlerle olay açılmamalı, çökme olmamalı.
      for (int i = 0; i < 10 && !state.deceased; i++) {
        state = LifeProgression(Random(i)).advanceOneYear(state);
        final GameState anlik = state;
        expect(
          anlik.pendingEvent == null ||
              anlik.pendingEvent!.personId == null ||
              anlik.people
                  .firstWhere((Person p) => p.id == anlik.pendingEvent!.personId)
                  .isAlive,
          isTrue,
          reason: 'Vefat eden kişi yeni olayda kullanılmamalı',
        );
        state = state.copyWith(pendingEvent: null);
      }
    });
  });

  // ===================================================================
  // Miras
  // ===================================================================
  group('Miras', () {
    GameState mirasKurulumu(int seed, {WealthTier wealth = WealthTier.varlikli}) {
      GameState state = hayat(seed, age: 30);
      final Person anne = kisiTur(state, RelationType.anne)!;
      final List<Person> people = state.people
          .map((Person p) => p.id == anne.id
              ? p.copyWith(
                  wealth: wealth,
                  estate: const <String>['kol_saati', 'antika_saat'],
                )
              : p)
          .toList(growable: false);
      state = state.copyWith(people: List<Person>.unmodifiable(people));
      return vefatEttir(state, anne.id);
    }

    test('miras yalnızca bir kez dağıtılır', () {
      final GameState state = mirasKurulumu(10);
      final Person anne = kisiTur(state, RelationType.anne)!;

      final ({GameState state, List<String> logLines}) ilk =
          Inheritance.settle(state, anne);
      expect(ilk.state.settledEstates, contains(anne.id));

      final int cuzdan = ilk.state.player.wallet;
      final int esyaSayisi = ilk.state.items.length;

      final ({GameState state, List<String> logLines}) ikinci =
          Inheritance.settle(ilk.state, anne);
      expect(ikinci.logLines, isEmpty);
      expect(ikinci.state.player.wallet, cuzdan);
      expect(ikinci.state.items.length, esyaSayisi,
          reason: 'Aynı eşya ikinci kez kopyalanmaz');
    });

    test('zengin annenin serveti olduğu gibi oyuncuya geçmez', () {
      final GameState state =
          mirasKurulumu(11, wealth: WealthTier.cokVarlikli);
      final Person anne = kisiTur(state, RelationType.anne)!;
      final int toplam = Inheritance.prototypeOnlyEstateMoney(anne.wealth);
      final InheritanceShare pay = Inheritance.shareFor(state, anne);

      expect(pay.money, lessThan(toplam),
          reason: 'Pay, mirasçı sayısına göre bölünmeli');
      expect(pay.money, greaterThan(0));
    });

    test('aynı eşya iki mirasçıya birden gitmez', () {
      final GameState state = mirasKurulumu(12);
      final Person anne = kisiTur(state, RelationType.anne)!;
      final InheritanceShare pay = Inheritance.shareFor(state, anne);

      // Oyuncuya kalanlar, ölenin sahip olduklarının alt kümesi ve
      // tekrarsızdır.
      for (final String tur in pay.itemTypeIds) {
        expect(anne.estate, contains(tur));
      }
      expect(pay.itemTypeIds.length, lessThanOrEqualTo(anne.estate.length));

      final ({GameState state, List<String> logLines}) sonuc =
          Inheritance.settle(state, anne);
      expect(sonuc.state.items.length, pay.itemTypeIds.length);
      for (final OwnedItem item in sonuc.state.items) {
        expect(item.source, ItemSource.miras);
        expect(item.fromPersonId, anne.id);
        expect(item.id, isNotEmpty, reason: 'Kalıcı varlık kimliği');
      }
      // Kimlikler benzersiz.
      expect(
        sonuc.state.items.map((OwnedItem i) => i.id).toSet().length,
        sonuc.state.items.length,
      );
    });

    test('mirasçı olmayan bağlarda miras kalmaz', () {
      GameState state = hayat(13, age: 25);
      final Person ogretmen = state.people.firstWhere(
        (Person p) => p.relation == RelationType.ogretmen,
        orElse: () => state.people.last,
      );

      state = vefatEttir(state, ogretmen.id);
      final Person vefat =
          state.people.firstWhere((Person p) => p.id == ogretmen.id);
      if (vefat.relation.kanBagi) return;

      final ({GameState state, List<String> logLines}) sonuc =
          Inheritance.settle(state, vefat);
      expect(sonuc.logLines, isEmpty);
      expect(sonuc.state.player.wallet, state.player.wallet);
      expect(sonuc.state.settledEstates, contains(vefat.id),
          reason: 'Varis yoksa da işlem tutarlı kapanmalı');
    });

    test('varlığı olmayan kişiden miras kalmaz ama işlem tutarlı biter', () {
      GameState state = hayat(14, age: 30);
      final Person anne = kisiTur(state, RelationType.anne)!;
      final List<Person> people = state.people
          .map((Person p) => p.id == anne.id
              ? p.copyWith(
                  wealth: WealthTier.cokYoksul,
                  estate: const <String>[],
                )
              : p)
          .toList(growable: false);
      state = vefatEttir(
        state.copyWith(people: List<Person>.unmodifiable(people)),
        anne.id,
      );

      final ({GameState state, List<String> logLines}) sonuc =
          Inheritance.settle(state, state.people.firstWhere((Person p) => p.id == anne.id));
      expect(sonuc.logLines, isEmpty);
      expect(sonuc.state.items, isEmpty);
      expect(sonuc.state.player.wallet, state.player.wallet);
    });

    test('miras hayat günlüğüne yazılır ve varlıklarda görünür', () {
      GameState state = mirasKurulumu(15);
      state = LifeProgression(Random(1)).advanceOneYear(state);

      expect(state.settledEstates, isNotEmpty);
      final bool mirasSatiri = state.log.any((dynamic e) =>
          (e.text as String).contains('miras'));
      expect(mirasSatiri, isTrue);
      expect(
        state.items.any((OwnedItem i) => i.source == ItemSource.miras),
        isTrue,
      );
    });
  });

  // ===================================================================
  // Hane ve bakım
  // ===================================================================
  group('Çocuk yaşta kayıp', () {
    test('hanede yetişkin kalmazsa oyun çökmez, yeni kişi uydurulmaz', () {
      GameState state = hayat(20, age: 9);
      for (final Person p in state.people) {
        if (p.inPlayerHousehold && p.age >= 18) {
          state = vefatEttir(state, p.id);
        }
      }
      final int kisiSayisi = state.people.length;

      final GameState sonra =
          LifeProgression(Random(2)).advanceOneYear(state);

      expect(sonra.people.length, kisiSayisi,
          reason: 'Bakım için yeni NPC üretilmemeli');
      // Ya hayatta olan bir yakın haneye geçti ya da durum günlüğe yazıldı.
      final bool yetiskinVar = sonra.householdMembers
          .any((Person p) => p.age >= LifeProgression.prototypeOnlyAdultAge);
      final bool aciklama = sonra.log.any((dynamic e) =>
          (e.text as String).contains('bakmak için') ||
          (e.text as String).contains('yetişkin kalmadı'));
      expect(yetiskinVar || aciklama, isTrue);
    });
  });

  // ===================================================================
  // Oyuncunun ölümü
  // ===================================================================
  group('Oyuncunun ölümü', () {
    GameState olumuneKadar(int seed) {
      GameState state = hayat(seed, age: 95);
      for (int i = 0; i < 40 && !state.deceased; i++) {
        state = LifeProgression(Random(seed * 7 + i)).advanceOneYear(state);
        state = state.copyWith(pendingEvent: null);
      }
      return state;
    }

    test('ileri yaşta hayat tamamlanır ve özet verisi oluşur', () {
      final GameState state = olumuneKadar(30);
      expect(state.deceased, isTrue);
      expect(state.deathAge, isNotNull);
      expect(state.deathCause, isNotNull);
      expect(state.log.last.text, contains('hayatını kaybettin'));
    });

    test('ölümden sonra yaş ilerlemez', () {
      final GameState state = olumuneKadar(31);
      final int yas = state.player.age;
      final GameState sonra =
          LifeProgression(Random(1)).advanceOneYear(state);
      // Motor ilerletse bile denetleyici engeller.
      final GameController c = GameController(random: Random(1));
      c.debugSetState(state);
      c.ageUp();
      expect(c.state!.player.age, yas);
      expect(c.state!.deceased, isTrue);
      expect(sonra.deceased, isTrue);
    });

    test('ölüm ve hayat özeti kaydedilip geri yüklenir', () async {
      final GameState state = olumuneKadar(32);
      final SaveService service = SaveService(MemorySaveStore());
      await service.save(state);
      final SaveLoadResult result = await service.load();
      expect(result.isLoaded, isTrue, reason: result.message);

      final GameState geri = result.state!;
      expect(geri.deceased, isTrue);
      expect(geri.deathAge, state.deathAge);
      expect(geri.deathCause, state.deathCause);
      expect(geri.player.fullName, state.player.fullName);
      expect(geri.people.length, state.people.length);
      expect(geri.items.length, state.items.length);
    });
  });

  // ===================================================================
  // Kayıt uyumu
  // ===================================================================
  group('Eski kayıtlar', () {
    test('sürüm 10 kaydında kimse sebepsiz ölmüş görünmez', () async {
      final GameState state = hayat(40, age: 30);
      final Map<String, Object?> body = encodeGameState(state);
      body
        ..remove('deceased')
        ..remove('deathAge')
        ..remove('deathCause')
        ..remove('settledEstates');
      for (final Object? e in body['people']! as List<Object?>) {
        (e! as Map<String, Object?>).remove('estate');
      }

      final SaveLoadResult result = await SaveService(
        MemorySaveStore(
          initial: jsonEncode(
            <String, Object?>{'formatVersion': 10, 'state': body},
          ),
        ),
      ).load();
      expect(result.isLoaded, isTrue, reason: result.message);

      final GameState geri = result.state!;
      expect(geri.deceased, isFalse);
      expect(geri.settledEstates, isEmpty);
      expect(geri.people.length, state.people.length);
      for (int i = 0; i < state.people.length; i++) {
        expect(geri.people[i].isAlive, state.people[i].isAlive,
            reason: 'Hayatta olanlar ölmüş görünmemeli');
        expect(geri.people[i].estate, isEmpty);
      }
    });
  });
}

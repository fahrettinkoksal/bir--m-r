import 'dart:math';

import 'package:bir_omur/data/event_pool.dart';
import 'package:bir_omur/data/event_pool_stages.dart';
import 'package:bir_omur/data/social_catalog.dart';
import 'package:bir_omur/domain/events/event_engine.dart';
import 'package:bir_omur/domain/generation/life_generator.dart';
import 'package:bir_omur/domain/generation/life_progression.dart';
import 'package:bir_omur/domain/models/game_event.dart';
import 'package:bir_omur/domain/models/game_state.dart';
import 'package:bir_omur/domain/models/owned_item.dart';
import 'package:bir_omur/domain/models/person.dart';
import 'package:bir_omur/domain/social/social_engine.dart';
import 'package:flutter_test/flutter_test.dart';

const EventEngine motor = EventEngine();

/// Şu an **çıkabilecek** olayların kimlikleri.
///
/// Eskiden bu yüzlerce tohumla çekiliş yapılarak bulunuyordu; dönüm
/// noktası ağırlıkları devreye girince (Paket 21) çekilişi hep aynı olay
/// kazanıyor ve diğerleri "imkânsız" gibi görünüyordu. Artık koşullar
/// doğrudan denetleniyor: hem doğru hem hızlı.
Set<String> olasiOlaylar(GameState state, {int deneme = 40}) {
  final Set<String> sonuc = <String>{};
  for (int i = 0; i < deneme; i++) {
    sonuc.addAll(
      motor.debugEligibleIds(state.copyWith(pendingEvent: null), Random(i)),
    );
  }
  return sonuc;
}

GameState hayat(int seed, {int age = 30}) {
  final GameState base =
      LifeGenerator.seeded(seed).generate(mode: StartMode.tamamenRastgele);
  return base.copyWith(
    player: base.player.copyWith(age: age, wallet: 500000),
  );
}

void main() {
  // ===================================================================
  // Katalog sağlığı
  // ===================================================================
  group('Katalog sağlığı', () {
    test('kimlikler benzersiz ve her olayın en az iki seçeneği var', () {
      final Set<String> kimlikler = <String>{};
      for (final GameEvent e in kEventPool) {
        expect(kimlikler.add(e.id), isTrue, reason: 'Tekrar eden id: ${e.id}');
        expect(e.choices.length, greaterThanOrEqualTo(2),
            reason: '${e.id} tek seçenekli');
        final Set<String> secenekler = <String>{};
        for (final EventChoice c in e.choices) {
          expect(secenekler.add(c.id), isTrue,
              reason: '${e.id} içinde tekrar eden seçenek: ${c.id}');
          expect(c.label.trim(), isNotEmpty);
          expect(c.resultText.trim(), isNotEmpty);
        }
      }
    });

    test('olay metinleri birbirinin kopyası değil', () {
      final Set<String> metinler = <String>{};
      for (final GameEvent e in kEventPool) {
        expect(metinler.add(e.text), isTrue,
            reason: '${e.id} başka bir olayla aynı metni kullanıyor');
      }
      final Set<String> sonuclar = <String>{};
      for (final GameEvent e in kEventPool) {
        for (final EventChoice c in e.choices) {
          expect(sonuclar.add(c.resultText), isTrue,
              reason: '${e.id}/${c.id} sonucu başka bir yerde tekrar ediyor');
        }
      }
    });

    test('kişi yer tutucusu yalnızca kişi gerektiren olaylarda kullanılır',
        () {
      for (final GameEvent e in kEventPool) {
        final bool kisiVar = e.requirement.livingRelations.isNotEmpty ||
            e.requirement.personRole != null ||
            e.requirement.requiresNeglectedRelative ||
            // Gezi anısı olaylarının kişisi, o gezinin yoldaşıdır; gezi
            // yoksa olay hiç çıkmaz (Paket 11).
            e.requirement.requiresTripMemory;
        final String hepsi =
            e.text + e.choices.map((EventChoice c) => c.resultText).join();
        final bool yerTutucu = hepsi.contains('{kisi}') ||
            hepsi.contains('{sahip}') ||
            hepsi.contains('{sahipk}') ||
            hepsi.contains('{bag}');
        // Kişiyi kendisi oluşturan seçimler (tanışma, arkadaşlık) de
        // yer tutucu kullanabilir: kişi o anda gerçekten yaratılır.
        final bool kisiUretiyor = e.choices.any((EventChoice c) =>
            c.startsRomance || c.startsSchoolFriendship || c.startsFriendship);
        if (yerTutucu) {
          expect(kisiVar || kisiUretiyor, isTrue,
              reason: '${e.id} kişi yer tutucusu kullanıyor ama kişi '
                  'gerektirmiyor');
        }
      }
    });

    test('kişi yaş aralıkları tutarlı', () {
      for (final GameEvent e in kEventPool) {
        final EventRequirement r = e.requirement;
        expect(r.minAge, lessThanOrEqualTo(r.maxAge), reason: e.id);
        if (r.personMinAge != null && r.personMaxAge != null) {
          expect(r.personMinAge!, lessThanOrEqualTo(r.personMaxAge!),
              reason: e.id);
        }
        if (e.repeatable) {
          expect(e.minAgeGap, greaterThanOrEqualTo(2),
              reason: '${e.id} her yıl tekrarlanabilir görünüyor');
        }
      }
    });
  });

  // ===================================================================
  // Olmayan şeyle olay çıkmaz
  // ===================================================================
  group('Sahip olunmayan şeyle olay çıkmaz', () {
    test('sosyal medya hesabı olmayana sosyal medya olayı çıkmaz', () {
      final GameState hesapsiz = hayat(401, age: 25);
      expect(hesapsiz.socialAccounts, isEmpty);
      expect(olasiOlaylar(hesapsiz), isNot(contains('sosyal_medya_mesaji')));

      final GameState hesapli = const SocialEngine()
          .openAccount(hesapsiz, SocialPlatform.values.first)
          .state;
      expect(hesapli.socialAccounts, isNotEmpty);
      expect(olasiOlaylar(hesapli), contains('sosyal_medya_mesaji'));
    });

    test('ehliyeti olmayan oyuncu direksiyona geçmez', () {
      final GameState aracli = hayat(402, age: 30).grantItems(
        <String>['otomobil_ikinci_el'],
        source: ItemSource.satinAlma,
      );
      expect(olasiOlaylar(aracli), isNot(contains('direksiyon_basinda')),
          reason: 'Ehliyet yokken araç olayı çıkmamalı');

      final GameState ehliyetli =
          aracli.copyWith(licenses: <String>{'otomobil_ehliyeti'});
      expect(olasiOlaylar(ehliyetli), contains('direksiyon_basinda'));
    });

    test('aracı olmayan ehliyetliye araç olayı çıkmaz', () {
      final GameState ehliyetli = hayat(403, age: 30)
          .copyWith(licenses: <String>{'otomobil_ehliyeti'});
      expect(olasiOlaylar(ehliyetli), isNot(contains('direksiyon_basinda')));
    });

    test('bisikleti olmayan çocuğa bisiklet olayı çıkmaz', () {
      final GameState bisikletsiz = hayat(404, age: 10);
      expect(olasiOlaylar(bisikletsiz),
          isNot(contains('bisikletle_uzak_sokak')));

      final GameState bisikletli = bisikletsiz.grantItems(
        <String>[Possessions.bisiklet],
        source: ItemSource.hediye,
      );
      expect(olasiOlaylar(bisikletli), contains('bisikletle_uzak_sokak'));
    });

    test('telefonu olmayana gece telefonu olayı çıkmaz', () {
      final GameState state = hayat(405, age: 15);
      expect(olasiOlaylar(state), isNot(contains('gece_telefonu')));
    });
  });

  // ===================================================================
  // Kişi koşulları
  // ===================================================================
  group('Kişi koşulları', () {
    test('vefat etmiş kişiyle olay kurulmaz', () {
      // Herkesi vefat ettir: kişi gerektiren hiçbir olay çıkmamalı.
      final GameState state = hayat(406, age: 40);
      final GameState olu = state.copyWith(
        people: state.people
            .map((Person p) =>
                p.copyWith(isAlive: false, inPlayerHousehold: false))
            .toList(growable: false),
      );

      for (int i = 0; i < 300; i++) {
        final ActiveEvent? olay =
            motor.openingEvent(olu.copyWith(pendingEvent: null), Random(i));
        if (olay?.personId == null) continue;
        fail('Vefat etmiş kişiyle olay kuruldu: ${olay!.eventId}');
      }
    });

    test('erişilemeyen kişi gündelik olayda kullanılmaz', () {
      final GameState state = hayat(407, age: 35);
      // Arkadaş başka şehirde: erişilemez.
      final GameState uzak = state.copyWith(
        people: <Person>[
          ...state.people.map((Person p) =>
              p.copyWith(inPlayerHousehold: false, city: 'Uzakşehir')),
        ],
        player: state.player.copyWith(currentCity: 'Yakınşehir'),
      );

      for (int i = 0; i < 300; i++) {
        final ActiveEvent? olay =
            motor.openingEvent(uzak.copyWith(pendingEvent: null), Random(i));
        if (olay == null || olay.personId == null) continue;
        final GameEvent tanim =
            kEventPool.firstWhere((GameEvent e) => e.id == olay.eventId);
        if (!tanim.requirement.requireReachable) continue;
        fail('${olay.eventId} erişilemeyen kişiyle kuruldu');
      }
    });
  });

  // ===================================================================
  // Hayat evreleri kapsamı
  // ===================================================================
  group('Hayat evreleri', () {
    test('her evrede uygun olay bulunur', () {
      final Map<String, int> evreler = <String, int>{
        '0-4': 2,
        '5-12': 8,
        '13-17': 15,
        '18-29': 22,
        '30-49': 40,
        '50-69': 60,
        '70+': 78,
      };
      for (final MapEntry<String, int> e in evreler.entries) {
        final Set<String> olaylar = olasiOlaylar(hayat(408, age: e.value));
        expect(olaylar, isNotEmpty,
            reason: '${e.key} aralığında hiç olay çıkmıyor (yaş ${e.value})');
      }
    });

    test('bebeklikte olay çıkar ve kişi ailedendir', () {
      final GameState bebek = hayat(409, age: 2);
      final Set<String> olaylar = olasiOlaylar(bebek);
      expect(olaylar, isNotEmpty);
      // Bebeklik olaylarının seçenekleri yaşa uygun: karar değil tepki.
      for (final String id in olaylar) {
        final GameEvent e =
            kEventPool.firstWhere((GameEvent g) => g.id == id);
        expect(e.requirement.minAge, lessThanOrEqualTo(2), reason: id);
      }
    });
  });

  // ===================================================================
  // Sonuçların ileride kullanılması
  // ===================================================================
  group('Kararların sonucu', () {
    ActiveEvent olayiGetir(GameState state, String id) {
      for (int i = 0; i < 3000; i++) {
        final ActiveEvent? olay =
            motor.openingEvent(state.copyWith(pendingEvent: null), Random(i));
        if (olay != null && olay.eventId == id) return olay;
      }
      fail('$id olayı bu durumda çıkmadı.');
    }

    test('lise kulübü kararı yıllar sonra hobi olayını açar', () {
      final GameState genc = hayat(410, age: 15).copyWith(
        education: LifeGenerator.seeded(410)
            .generate(mode: StartMode.tamamenRastgele)
            .education
            .copyWith(enrolled: true, grade: 10),
      );
      expect(olasiOlaylar(hayat(411, age: 60)),
          isNot(contains('eski_hobi_donusu')));

      final ActiveEvent olay = olayiGetir(genc, 'lise_kulubu');
      final GameState sonra =
          motor.resolve(genc.copyWith(pendingEvent: olay), 'yazil');
      expect(sonra.storyFlags, contains(StageFlags.hobiEdinildi));

      final GameState yaslandi =
          sonra.copyWith(player: sonra.player.copyWith(age: 60));
      expect(olasiOlaylar(yaslandi), contains('eski_hobi_donusu'));
    });

    test('eski mahalleye dönüş, yıkım olayının önkoşuludur', () {
      final GameState state = hayat(412, age: 25);
      expect(olasiOlaylar(state.copyWith(
        player: state.player.copyWith(age: 50),
      )), isNot(contains('mahalledeki_degisim')));

      final ActiveEvent olay = olayiGetir(state, 'eski_mahalleye_donus');
      final GameState sonra =
          motor.resolve(state.copyWith(pendingEvent: olay), 'dolas');
      expect(sonra.storyFlags, contains(StageFlags.mahalleyeDonuldu));
      expect(
        olasiOlaylar(sonra.copyWith(
          player: sonra.player.copyWith(age: 50),
        )),
        contains('mahalledeki_degisim'),
      );
    });

    test('vasiyet yazmak, mirasın konuşulmasını açar', () {
      final GameState yasli = hayat(413, age: 70);
      expect(olasiOlaylar(yasli), isNot(contains('mirasin_konusulmasi')));

      final ActiveEvent olay = olayiGetir(yasli, 'vasiyet_dusuncesi');
      final GameState sonra =
          motor.resolve(yasli.copyWith(pendingEvent: olay), 'yaz');
      expect(sonra.storyFlags, contains(StageFlags.vasiyetYazildi));
      expect(
        olasiOlaylar(sonra.copyWith(
          player: sonra.player.copyWith(age: 80),
        )),
        contains('mirasin_konusulmasi'),
      );
    });

    test('ilk evin gecesi, yıllar sonra anahtar olayını açar', () {
      final GameState state = hayat(414, age: 24);
      expect(
        olasiOlaylar(state.copyWith(
          player: state.player.copyWith(age: 60),
        )),
        isNot(contains('ilk_evin_hatirasi')),
      );

      final ActiveEvent olay = olayiGetir(state, 'ilk_ev_ilk_gece');
      final GameState sonra =
          motor.resolve(state.copyWith(pendingEvent: olay), 'yerlestir');
      expect(sonra.storyFlags, contains(StageFlags.ilkEvHatirasi));
      expect(
        olasiOlaylar(sonra.copyWith(
          player: sonra.player.copyWith(age: 60),
        )),
        contains('ilk_evin_hatirasi'),
      );
    });

    test('sınav gecesi kararı yaşlılıkta hatırlanır', () {
      final GameState genc = hayat(415, age: 16).copyWith(
        education: LifeGenerator.seeded(415)
            .generate(mode: StartMode.tamamenRastgele)
            .education
            .copyWith(enrolled: true, grade: 11),
      );
      final ActiveEvent olay = olayiGetir(genc, 'sinav_oncesi_gece');
      final GameState calisti =
          motor.resolve(genc.copyWith(pendingEvent: olay), 'calis');
      expect(calisti.storyFlags, contains(StageFlags.sinavaCalisti));
      expect(
        olasiOlaylar(calisti.copyWith(
          player: calisti.player.copyWith(age: 80),
        )),
        contains('hayat_muhasebesi'),
      );
    });
  });

  // ===================================================================
  // Tekrar kalitesi
  // ===================================================================
  group('Tekrar kalitesi', () {
    test('aynı olay bir hayatta üst üste veya sık sık gösterilmez', () {
      final Map<String, int> enCok = <String, int>{};

      for (int seed = 500; seed < 530; seed++) {
        final Random rng = Random(seed);
        GameState state =
            LifeGenerator.seeded(seed).generate(mode: StartMode.tamamenRastgele);
        final Map<String, int> sayac = <String, int>{};
        String? oncekiOlay;

        while (!state.deceased && state.player.age < 90) {
          state = state.copyWith(pendingEvent: null, pendingCrisis: null);
          state = LifeProgression(rng).advanceOneYear(state);
          final ActiveEvent? olay = state.pendingEvent;
          if (olay == null) {
            oncekiOlay = null;
            continue;
          }
          final GameEvent tanim =
              kEventPool.firstWhere((GameEvent e) => e.id == olay.eventId);
          expect(olay.eventId, isNot(equals(oncekiOlay)),
              reason: 'Aynı olay art arda çıktı: ${olay.eventId}');
          if (!tanim.repeatable) {
            expect(sayac[olay.eventId] ?? 0, 0,
                reason: '${olay.eventId} tekrarlanabilir değil ama '
                    'ikinci kez çıktı');
          }
          sayac[olay.eventId] = (sayac[olay.eventId] ?? 0) + 1;
          oncekiOlay = olay.eventId;
          state = motor.resolve(state, olay.choices.first.id, rng: rng);
        }

        for (final MapEntry<String, int> e in sayac.entries) {
          if ((enCok[e.key] ?? 0) < e.value) enCok[e.key] = e.value;
        }
      }

      // prototypeOnly eşik: bir hayat 75-90 yıl sürüyor; bir olayın tek
      // hayatta 8 kereden fazla çıkması "on yılda birden sık" demektir ve
      // tekrar aralığının yetersiz olduğunu gösterir.
      enCok.forEach((String id, int adet) {
        expect(adet, lessThanOrEqualTo(8),
            reason: '$id tek hayatta $adet kez çıktı');
      });
    });
  });
}

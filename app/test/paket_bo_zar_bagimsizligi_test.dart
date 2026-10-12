// Paket BO — motorun **zar sözleşmesi**.
//
// **Ölçülen hata.** `EventEngine._pick` aday taramasında kişi çözümünü
// koşul denetiminden **önce** yapıyordu. Kişi çözümü `rng` tüketir;
// dolayısıyla o yaşta hiç çıkamayacak bir olay bile oyunun zarını
// ilerletiyordu. Sonuç: havuza tek bir olay eklemek bütün tohumlu
// ölçümleri kaydırıyordu. Bir oturumda beş bekçi testi (sınav önceliği,
// ekran dökümü, sınıf arkadaşı kademesi, tekrar evlenme kilidi, olay
// çeşitliliği) yalnızca bu yüzden kırıldı; hiçbiri gerçek bir oyun
// hatası değildi. Bekçinin kırılması normalleşirse bekçi işe yaramaz.
//
// Bu dosya üç şeyi bekçiler:
//   1. Havuza **uygun olmayan** olay eklemek akışı hiç değiştirmiyor.
//   2. Erişilebilirlik artık aday süzgeci: erişilebilir arkadaş varken
//      olay, "erişilemeyen kişi çekildi" diye elenmiyor. D-093 aynı
//      hatayı "ilgilenilmeyen yakın" seçicisinde kapatmıştı; bu dal
//      açık kalmıştı.
//   3. `debugEligibleIds` tohumdan bağımsız: "hangi olaylar mümkün"
//      sorusunun cevabı zara bağlı değil.
//   4. Öğretmeni vefat eden sınıfa yeni öğretmen geliyor. Bu, zar
//      sırası kayınca ortaya çıkan **gerçek** bir boşluktu: bir
//      kademede tanınan öğretmen bir kişi, o kişi ölünce yerine kimse
//      gelmiyordu.
// ignore_for_file: avoid_print
library;

import 'dart:math';

import 'package:bir_omur/data/event_pool.dart';
import 'package:bir_omur/domain/events/event_engine.dart';
import 'package:bir_omur/domain/generation/life_progression.dart';
import 'package:bir_omur/domain/generation/life_generator.dart';
import 'package:bir_omur/domain/models/game_event.dart';
import 'package:bir_omur/domain/models/gender.dart';
import 'package:bir_omur/domain/models/game_state.dart';
import 'package:bir_omur/domain/models/life_log.dart';
import 'package:bir_omur/domain/models/person.dart';
import 'package:bir_omur/domain/models/relation.dart';
import 'package:bir_omur/domain/models/wealth.dart';
import 'package:bir_omur/state/game_controller.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/test_flow.dart';

/// Taramada kullanılan yaşlar: çocukluk, okul, gençlik, yetişkinlik ve
/// yaşlılık ayrı ayrı karşılaştırılır.
const List<int> kYaslar = <int>[0, 3, 7, 12, 18, 25, 40, 60];

/// Hiçbir yaşta çıkamayacak dolgu olayları. **Kişi ister**: eski motor
/// tam da bu yüzden zar tüketiyordu.
List<GameEvent> _dolguHavuzu(int adet) => <GameEvent>[
      for (int i = 0; i < adet; i++)
        GameEvent(
          id: 'bo_dolgu_$i',
          category: EventCategory.kisisel,
          text: 'Bu olay hiç çıkmaz ({kisi}).',
          requirement: const EventRequirement(
            minAge: 200,
            maxAge: 201,
            livingRelations: <RelationType>{RelationType.anne},
          ),
          choices: const <EventChoice>[
            EventChoice(id: 'a', label: 'Bir', resultText: 'Olmadı.'),
            EventChoice(id: 'b', label: 'İki', resultText: 'Olmadı.'),
          ],
        ),
    ];

void main() {
  group('Paket BO — havuz büyümesi zarı kaydırmıyor', () {
    test('uygun olmayan 60 olay eklemek aynı sonucu veriyor', () {
      const EventEngine temiz = EventEngine();
      final EventEngine dolgulu = EventEngine(
        pool: <GameEvent>[...kEventPool, ..._dolguHavuzu(60)],
      );

      int karsilastirilan = 0;
      int olayCikan = 0;
      for (int tohum = 0; tohum < 40; tohum++) {
        final GameState temel = LifeGenerator.seeded(tohum)
            .generate(mode: StartMode.tamamenRastgele);
        for (final int yas in kYaslar) {
          final GameState s =
              temel.copyWith(player: temel.player.copyWith(age: yas));
          final int zar = tohum * 97 + yas;
          final ActiveEvent? a = temiz.openingEvent(s, Random(zar));
          final ActiveEvent? b = dolgulu.openingEvent(s, Random(zar));
          expect(b?.eventId, a?.eventId,
              reason: 'tohum $tohum, yaş $yas: havuz büyümesi olayı '
                  'değiştirdi');
          expect(b?.personId, a?.personId,
              reason: 'tohum $tohum, yaş $yas: havuz büyümesi kişiyi '
                  'değiştirdi');
          karsilastirilan++;
          if (a != null) olayCikan++;
        }
      }
      // Ölçümün kendisi anlamlı olsun: hepsi `null` dönerse test hiçbir
      // şeyi kanıtlamaz.
      expect(olayCikan, greaterThan(karsilastirilan ~/ 2),
          reason: 'karşılaştırılan durumların yarısında bile olay '
              'çıkmadı; ölçüm temsil etmiyor');
      print('Paket BO: $karsilastirilan durum karşılaştırıldı, '
          '$olayCikan tanesinde olay çıktı, hepsi aynı.');
    });
  });

  group('Paket BO — erişilebilirlik aday süzgeci', () {
    /// Biri aynı şehirde, biri başka şehirde iki arkadaş. `isReachable`
    /// arkadaş için şehre bakar: başka şehirdeki arkadaş gündelik olaya
    /// girmez.
    GameState ikiArkadas() {
      final GameState temel =
          LifeGenerator.seeded(5).generate(mode: StartMode.tamamenRastgele);
      Person arkadas(String id, String sehir) => Person(
            id: id,
            firstName: id == 'bo-yakin' ? 'Yakın' : 'Uzak',
            lastName: 'Dost',
            gender: Gender.erkek,
            relation: RelationType.arkadas,
            age: 33,
            isAlive: true,
            inPlayerHousehold: false,
            employment: EmploymentStatus.calisiyor,
            occupation: 'Tezgâhtar',
            wealth: null,
            bond: 60,
            city: sehir,
            becameFriendAtAge: 20,
          );
      return temel.copyWith(
        player: temel.player.copyWith(age: 33),
        people: <Person>[
          ...temel.people,
          arkadas('bo-yakin', temel.player.currentCity),
          // Oyuncunun şehri ne olursa olsun farklı bir değer.
          arkadas('bo-uzak', '${temel.player.currentCity}-uzak'),
        ],
      );
    }

    const GameEvent arkadasOlayi = GameEvent(
      id: 'bo_test_arkadas',
      category: EventCategory.mahalle,
      text: '{kisi} bugün seni aradı.',
      requirement: EventRequirement(
        minAge: 30,
        maxAge: 40,
        livingRelations: <RelationType>{RelationType.arkadas},
        requireReachable: true,
      ),
      repeatable: true,
      choices: <EventChoice>[
        EventChoice(id: 'a', label: 'Konuş', resultText: 'Konuştunuz.'),
        EventChoice(id: 'b', label: 'Sonra', resultText: 'Sonraya kaldı.'),
      ],
    );

    test('erişilebilir arkadaş varken olay her tohumda çıkıyor', () {
      const EventEngine motor =
          EventEngine(pool: <GameEvent>[arkadasOlayi]);
      final GameState s = ikiArkadas();
      for (int tohum = 0; tohum < 30; tohum++) {
        final ActiveEvent? olay = motor.openingEvent(s, Random(tohum * 13));
        expect(olay, isNotNull,
            reason: 'tohum $tohum: erişilebilir arkadaş varken olay elendi');
        expect(olay!.personId, 'bo-yakin',
            reason: 'tohum $tohum: erişilemeyen arkadaş seçildi');
        expect(olay.text.contains('{'), isFalse,
            reason: 'yer tutucu doldurulmadı: ${olay.text}');
      }
      print('Paket BO: 30 tohumda da erişilebilir arkadaş seçildi.');
    });

    test('tek arkadaş erişilemezse olay hiç çıkmıyor', () {
      const EventEngine motor =
          EventEngine(pool: <GameEvent>[arkadasOlayi]);
      final GameState temel = ikiArkadas();
      // Yakın arkadaş listeden çıkarılır: geriye yalnızca başka şehirdeki
      // kalır. Koşul "erişilebilir" diyorsa olay çıkmamalı.
      final GameState s = temel.copyWith(
        people: temel.people
            .where((Person p) => p.id != 'bo-yakin')
            .toList(growable: false),
      );
      for (int tohum = 0; tohum < 10; tohum++) {
        expect(motor.openingEvent(s, Random(tohum)), isNull,
            reason: 'tohum $tohum: erişilemeyen arkadaşla olay çıktı');
      }
    });
  });

  group('Paket BO — uygunluk taraması tohumdan bağımsız', () {
    test('aynı durumda her tohum aynı aday kümesini veriyor', () {
      const EventEngine motor = EventEngine();
      for (int tohum = 0; tohum < 8; tohum++) {
        final GameState temel = LifeGenerator.seeded(tohum)
            .generate(mode: StartMode.tamamenRastgele);
        for (final int yas in <int>[5, 15, 30, 55]) {
          final GameState s =
              temel.copyWith(player: temel.player.copyWith(age: yas));
          final Set<String> ilk = motor.debugEligibleIds(s, Random(1));
          expect(ilk, isNotEmpty,
              reason: 'tohum $tohum, yaş $yas: hiç aday yok');
          for (int i = 2; i < 12; i++) {
            expect(motor.debugEligibleIds(s, Random(i * 7)), ilk,
                reason: 'tohum $tohum, yaş $yas: aday kümesi tohuma '
                    'göre değişti');
          }
        }
      }
    });
  });

  group('Paket BO — okul öğretmensiz kalmıyor', () {
    test('öğretmeni vefat eden sınıfa yeni öğretmen geliyor', () {
      // **Ölçülen boşluk.** Bir kademede tanınan öğretmen sayısı bir.
      // O kişi vefat ettiğinde sınıf öğretmensiz kalıyordu ve yerine
      // kimse gelmiyordu; oyuncu o kademeyi öğretmensiz bitiriyordu.
      // Zar sırası Paket BO'da değişince sekiz tohumla koşan bekçi
      // testi bunu rastgele yakaladı — yani bekçi bir kuralı değil
      // kurayı ölçüyordu. Kural şimdi açık: okul öğretmensiz kalmaz.
      final GameController c = GameController(random: Random(1));
      c.startNewLife(mode: StartMode.tamamenRastgele, seed: 1);
      advanceToAge(c, LifeProgression.prototypeOnlySchoolStartAge);
      resolvePendingEvents(c);

      final List<Person> ogretmenler = c.state!.currentTeachers;
      expect(ogretmenler, isNotEmpty, reason: 'ölçüm kurulamadı');
      final String olenId = ogretmenler.first.id;

      // Öğretmen vefat etmiş gibi işaretlenir: ölüm turunun kendisi
      // tohuma bağlı, kural ise tohuma bağlı olmamalı.
      c.debugSetState(c.state!.copyWith(
        people: c.state!.people
            .map((Person p) =>
                p.id == olenId ? p.copyWith(isAlive: false) : p)
            .toList(growable: false),
      ));
      expect(c.state!.currentTeachers, isEmpty);

      c.ageUp();
      resolvePendingEvents(c);

      final List<Person> sonra = c.state!.currentTeachers;
      expect(sonra, isNotEmpty,
          reason: 'öğretmen vefat etti, yerine kimse gelmedi');
      expect(sonra.first.id, isNot(olenId));
      expect(sonra.first.schoolId, c.state!.education.schoolId);
      // Vefat eden kayıt silinmez; geçmiş korunur.
      expect(
        c.state!.people.any((Person p) => p.id == olenId && !p.isAlive),
        isTrue,
      );
      // Oyuncu bunu ekranda görür: günlükte satırı var.
      expect(
        c.state!.log.any((LifeLogEntry e) =>
            e.text.contains('öğretmen') &&
            e.text.contains(sonra.first.fullName)),
        isTrue,
        reason: 'yeni öğretmen günlüğe yazılmadı',
      );
    });
  });
}

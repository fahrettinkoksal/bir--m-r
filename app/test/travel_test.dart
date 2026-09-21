import 'dart:math';

import 'package:bir_omur/data/event_pool.dart';
import 'package:bir_omur/data/save/game_state_codec.dart';
import 'package:bir_omur/data/save/save_format.dart';
import 'package:bir_omur/domain/activities/travel.dart';
import 'package:bir_omur/domain/events/event_engine.dart';
import 'package:bir_omur/domain/generation/life_generator.dart';
import 'package:bir_omur/domain/generation/life_progression.dart';
import 'package:bir_omur/domain/models/game_event.dart';
import 'package:bir_omur/domain/models/game_state.dart';
import 'package:bir_omur/domain/models/gender.dart';
import 'package:bir_omur/domain/models/owned_item.dart';
import 'package:bir_omur/domain/models/person.dart';
import 'package:bir_omur/domain/models/relation.dart';
import 'package:bir_omur/domain/models/trip.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/generation_fixtures.dart';
import 'support/invariants.dart';

/// Gezi yapabilecek bir yetişkin ve çevresi.
GameState gezgin({
  int seed = 71,
  int age = 30,
  int wallet = 200000,
  List<Person> people = const <Person>[],
}) {
  final GameState base =
      LifeGenerator.seeded(seed).generate(mode: StartMode.tamamenRastgele);
  return base.copyWith(
    pendingEvent: null,
    player: base.player.copyWith(age: age, wallet: wallet),
    people: people.isEmpty ? base.people : people,
  );
}

void main() {
  // ===================================================================
  // Seyahat seçimi
  // ===================================================================
  group('Seyahat seçimi', () {
    test('gidilecek şehirler yaşanan şehri içermez', () {
      final GameState s = gezgin();
      expect(Travel.destinations(s), isNotEmpty);
      expect(Travel.destinations(s), isNot(contains(s.player.currentCity)));
    });

    test('yaşanan şehre gezi yapılamaz', () {
      final GameState s = gezgin();
      expect(
        Travel.availability(
          s,
          mode: TravelMode.otobus,
          city: s.player.currentCity,
        ).isAllowed,
        isFalse,
      );
    });

    test('ücret önceden bellidir ve kişi sayısına göre artar', () {
      final int tek = Travel.costOf(TravelMode.tren, withCompanion: false);
      final int cift = Travel.costOf(TravelMode.tren, withCompanion: true);
      expect(tek, TravelMode.tren.prototypeOnlyCost);
      expect(cift, greaterThan(tek));
    });

    test('cüzdanı yetmeyen yola çıkamaz ve para eksilmez', () {
      final GameState fakir = gezgin(wallet: 100);
      final String sehir = Travel.destinations(fakir).first;
      expect(
        Travel.availability(fakir, mode: TravelMode.ucak, city: sehir)
            .isAllowed,
        isFalse,
      );

      final TripResult r = Travel.take(
        fakir,
        mode: TravelMode.ucak,
        city: sehir,
        rng: Random(1),
      );
      expect(r.outcome.applied, isFalse);
      expect(r.state.player.wallet, fakir.player.wallet);
      expect(r.state.trips, isEmpty);
    });

    test('gezi gerçekten etki uygular ve kayda girer', () {
      final GameState s = gezgin();
      final String sehir = Travel.destinations(s).first;
      final int mutluluk = s.player.stats.happiness;

      final TripResult r = Travel.take(
        s,
        mode: TravelMode.otobus,
        city: sehir,
        rng: Random(2),
      );

      expect(r.outcome.applied, isTrue);
      expect(r.state.trips, hasLength(1));
      expect(r.state.trips.single.city, sehir);
      expect(r.state.trips.single.age, s.player.age);
      expect(r.state.player.stats.happiness, greaterThan(mutluluk));
      expect(
        r.state.player.wallet,
        s.player.wallet - TravelMode.otobus.prototypeOnlyCost,
      );
      expect(checkInvariants(r.state), isEmpty);
    });

    test('gezi yaşanan veya doğulan şehri değiştirmez', () {
      final GameState s = gezgin();
      final String sehir = Travel.destinations(s).first;
      final TripResult r = Travel.take(
        s,
        mode: TravelMode.tren,
        city: sehir,
        rng: Random(3),
      );

      expect(r.state.player.currentCity, s.player.currentCity);
      expect(r.state.player.birthCity, s.player.birthCity);
    });

    test('yılda yapılabilecek gezi sayısı sınırlıdır', () {
      GameState s = gezgin(wallet: 500000);
      final String sehir = Travel.destinations(s).first;
      for (int i = 0; i < Travel.prototypeOnlyMaxTripsPerAge; i++) {
        s = Travel.take(s, mode: TravelMode.otobus, city: sehir, rng: Random(i))
            .state;
      }
      final TripResult fazladan = Travel.take(
        s,
        mode: TravelMode.otobus,
        city: sehir,
        rng: Random(9),
      );
      expect(fazladan.outcome.applied, isFalse);
      expect(s.trips, hasLength(Travel.prototypeOnlyMaxTripsPerAge));
    });

    test('küçük yaşta seyahat açılmaz', () {
      final GameState cocuk = gezgin(age: 10);
      final String sehir = Travel.destinations(cocuk).first;
      expect(
        Travel.availability(cocuk, mode: TravelMode.otobus, city: sehir)
            .isAllowed,
        isFalse,
      );
    });
  });

  // ===================================================================
  // Araçla gitme: sahte düğme yok
  // ===================================================================
  group('Yolculuk türü', () {
    test('arabası olmayana "kendi arabanla" seçeneği açılmaz', () {
      final GameState s = gezgin();
      expect(Travel.usableCar(s), isNull);
      expect(
        Travel.availableModes(s),
        isNot(contains(TravelMode.kendiArabasi)),
      );
    });

    test('ehliyeti olmayan araç sahibine de açılmaz', () {
      final GameState s = gezgin().grantItems(
        <String>['otomobil_ikinci_el'],
        source: ItemSource.satinAlma,
      );
      expect(Travel.usableCar(s), isNull);
    });

    test('ehliyet ve araç birlikteyse seçenek açılır', () {
      final GameState s = gezgin()
          .grantItems(
            <String>['otomobil_ikinci_el'],
            source: ItemSource.satinAlma,
          )
          .copyWith(licenses: <String>{'otomobil_ehliyeti'});
      expect(Travel.usableCar(s), isNotNull);
      expect(Travel.availableModes(s), contains(TravelMode.kendiArabasi));
    });

    test('kondisyonu düşük araçla yola çıkılmaz', () {
      GameState s = gezgin()
          .grantItems(
            <String>['otomobil_ikinci_el'],
            source: ItemSource.satinAlma,
          )
          .copyWith(licenses: <String>{'otomobil_ehliyeti'});
      s = s.copyWith(
        items: s.items
            .map((OwnedItem i) => i.copyWith(condition: 10))
            .toList(growable: false),
      );
      expect(Travel.usableCar(s), isNull);
    });

    test('kendi arabasıyla gidince araç yıpranır', () {
      final GameState s = gezgin()
          .grantItems(
            <String>['otomobil_ikinci_el'],
            source: ItemSource.satinAlma,
          )
          .copyWith(licenses: <String>{'otomobil_ehliyeti'});
      final int eski = Travel.usableCar(s)!.condition;

      final TripResult r = Travel.take(
        s,
        mode: TravelMode.kendiArabasi,
        city: Travel.destinations(s).first,
        rng: Random(4),
      );
      final OwnedItem araba = r.state.items.firstWhere(
        (OwnedItem i) => i.id == Travel.usableCar(s)!.id,
      );
      expect(araba.condition, eski - Travel.prototypeOnlyCarWear);
    });
  });

  // ===================================================================
  // Birlikte gezi
  // ===================================================================
  group('Birlikte gezi', () {
    GameState yakinlarla({int bond = 50, bool anneYasiyor = true}) {
      final GameState base = gezgin();
      return base.copyWith(
        people: <Person>[
          kisi(
            id: 'anne-1',
            relation: RelationType.anne,
            gender: Gender.kadin,
            age: 58,
            firstName: 'Nurten',
            alive: anneYasiyor,
            bond: bond,
            city: base.player.currentCity,
          ),
          kisi(
            id: 'cocuk-bebek',
            relation: RelationType.cocuk,
            gender: Gender.erkek,
            age: 2,
            firstName: 'Deniz',
            hane: true,
            city: base.player.currentCity,
          ),
          kisi(
            id: 'arkadas-uzak',
            relation: RelationType.arkadas,
            gender: Gender.kadin,
            age: 31,
            firstName: 'Seda',
            city: 'Trabzon',
          ),
        ],
      );
    }

    test('vefat etmiş anneyle gezi yapılamaz', () {
      final GameState s = yakinlarla(anneYasiyor: false);
      expect(
        Travel.companions(s).any((Person p) => p.id == 'anne-1'),
        isFalse,
      );
      final TripResult r = Travel.take(
        s,
        mode: TravelMode.otobus,
        city: Travel.destinations(s).first,
        companionId: 'anne-1',
        rng: Random(5),
      );
      expect(r.outcome.applied, isFalse);
      expect(r.state.trips, isEmpty);
    });

    test('bebek çocuk yola çıkarılmaz', () {
      final GameState s = yakinlarla();
      expect(
        Travel.companions(s).any((Person p) => p.id == 'cocuk-bebek'),
        isFalse,
      );
    });

    test('başka şehirdeki arkadaş listede görünmez', () {
      final GameState s = yakinlarla();
      expect(
        Travel.companions(s).any((Person p) => p.id == 'arkadas-uzak'),
        isFalse,
      );
    });

    test('yakınla gezi yakınlığı artırır ve kayda kişiyi yazar', () {
      final GameState s = yakinlarla(bond: 50);
      final TripResult r = Travel.take(
        s,
        mode: TravelMode.tren,
        city: Travel.destinations(s).first,
        companionId: 'anne-1',
        rng: Random(6),
      );

      expect(r.outcome.applied, isTrue);
      expect(r.state.trips.single.companionId, 'anne-1');
      expect(
        r.state.personById('anne-1')!.bond,
        50 + Travel.prototypeOnlyBondGain,
      );
      // İki kişilik ücret düşer.
      expect(
        r.state.player.wallet,
        s.player.wallet -
            Travel.costOf(TravelMode.tren, withCompanion: true),
      );
    });

    test('yakınlık zaten 100 ise sahte puan yazılmaz', () {
      final GameState s = yakinlarla(bond: 100);
      final TripResult r = Travel.take(
        s,
        mode: TravelMode.otobus,
        city: Travel.destinations(s).first,
        companionId: 'anne-1',
        rng: Random(7),
      );
      expect(r.state.personById('anne-1')!.bond, 100);
    });
  });

  // ===================================================================
  // Anılar ve kayıt
  // ===================================================================
  group('Gezi anıları ve kayıt', () {
    GameState geziYapmis({int yasFarki = 10}) {
      GameState s = gezgin(age: 30).copyWith(
        people: <Person>[
          kisi(
            id: 'es-1',
            relation: RelationType.es,
            gender: Gender.kadin,
            age: 30,
            firstName: 'Elif',
            hane: true,
          ),
        ],
      );
      s = Travel.take(
        s,
        mode: TravelMode.tren,
        city: 'Trabzon',
        companionId: 'es-1',
        rng: Random(8),
      ).state;
      return s.copyWith(
        player: s.player.copyWith(age: 30 + yasFarki),
      );
    }

    test('gezi günlüğe şehir, kim ve gerçek harcamayla yazılır', () {
      final GameState s = geziYapmis();
      final String satir = s.log.last.text;
      expect(satir, contains('Trabzon'));
      expect(satir, contains('Elif'));
      expect(satir, contains('₺'));
    });

    test('her gezinin kendine ait bir anısı vardır', () {
      final Set<String> anilar = <String>{};
      for (int i = 0; i < 12; i++) {
        final GameState s = gezgin(seed: 80 + i);
        final TripResult r = Travel.take(
          s,
          mode: TravelMode.otobus,
          city: Travel.destinations(s).first,
          rng: Random(i),
        );
        anilar.add(r.state.trips.single.note!);
      }
      expect(anilar.length, greaterThan(1),
          reason: 'Aynı metin çoğaltılmamalı');
    });

    test('yıllar sonra aynı kişiyle gezi hatırlanır', () {
      final GameState s = geziYapmis();
      final TripRecord? ani = Travel.memorableTrip(s);
      expect(ani, isNotNull);
      expect(ani!.companionId, 'es-1');

      // Anı olayı gerçekten çıkabiliyor ve {sehir} doluyor.
      const EventEngine motor = EventEngine(pool: kEventPool);
      ActiveEvent? bulunan;
      for (int i = 0; i < 600 && bulunan == null; i++) {
        final ActiveEvent? olay = motor.openingEvent(
          s.copyWith(pendingEvent: null),
          Random(i),
        );
        if (olay != null && olay.eventId == 'gezi_anisi') bulunan = olay;
      }
      expect(bulunan, isNotNull, reason: 'Gezi anısı olayı hiç çıkmadı');
      expect(bulunan!.text, contains('Trabzon'));
      expect(bulunan.text, contains('Elif'));
      expect(bulunan.text, isNot(contains('{')));
    });

    test('vefat etmiş yoldaş için anı olayı üretilmez', () {
      GameState s = geziYapmis();
      s = s.copyWith(
        people: s.people
            .map((Person p) =>
                p.id == 'es-1' ? p.copyWith(isAlive: false) : p)
            .toList(growable: false),
      );
      expect(Travel.memorableTrip(s), isNull);
    });

    test('gezi yapmamış oyuncuda anı olayı çıkmaz', () {
      final GameState s = gezgin(age: 40);
      expect(Travel.memorableTrip(s), isNull);
    });

    test('gezi ücreti kapat-aç ile ikinci kez düşmez', () {
      final GameState s = gezgin();
      final TripResult r = Travel.take(
        s,
        mode: TravelMode.tren,
        city: Travel.destinations(s).first,
        rng: Random(11),
      );
      final int cuzdan = r.state.player.wallet;

      final GameState geri = decodeGameState(encodeGameState(r.state));
      expect(geri.player.wallet, cuzdan);
      expect(geri.trips, hasLength(1));
      expect(geri.trips.single.cost, r.state.trips.single.cost);
      expect(geri.trips.single.note, r.state.trips.single.note);

      // Yaş almak da geziyi yeniden ücretlendirmez.
      final GameState sonra = LifeProgression(Random(12)).advanceOneYear(geri);
      expect(sonra.trips, hasLength(1));
      expect(sonra.player.wallet, greaterThanOrEqualTo(cuzdan - 200000));
    });

    test('kayıt sürümü 29 ve eski kayıtta gezi listesi boş açılır', () {
      expect(kSaveFormatVersion, 29);
      final GameState s = gezgin();
      final Map<String, Object?> body =
          Map<String, Object?>.from(encodeGameState(s))..remove('trips');
      final GameState geri =
          decodeGameState(SaveMigrations.migrate(body, 24));
      expect(geri.trips, isEmpty);
      expect(geri.player.currentCity, s.player.currentCity);
    });
  });
}

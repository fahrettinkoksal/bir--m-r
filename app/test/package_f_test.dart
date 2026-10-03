import 'dart:math';

import 'package:bir_omur/data/city_neighbours.dart';
import 'package:bir_omur/data/event_pool.dart';
import 'package:bir_omur/data/finger_catalog.dart';
import 'package:bir_omur/data/name_pool.dart';
import 'package:bir_omur/data/tour_catalog.dart';
import 'package:bir_omur/domain/activities/travel.dart';
import 'package:bir_omur/domain/economy/housing.dart';
import 'package:bir_omur/domain/generation/life_generator.dart';
import 'package:bir_omur/domain/interaction/finger.dart';
import 'package:bir_omur/domain/life/life_end_choice.dart';
import 'package:bir_omur/domain/models/finger_profile.dart';
import 'package:bir_omur/domain/events/event_engine.dart';
import 'package:bir_omur/domain/models/game_event.dart';
import 'package:bir_omur/domain/models/interaction.dart';
import 'package:bir_omur/domain/models/game_state.dart';
import 'package:bir_omur/domain/models/owned_item.dart';
import 'package:flutter_test/flutter_test.dart';

/// Finger yaş bandı ve beğeni kotası, tur paketleri, yakın illere
/// taşınma, hayatın sonu seçeneği (D-081, D-083, D-084, D-085).
void main() {
  GameState hayat(int seed, {int age = 30, int wallet = 3000000}) {
    final GameState base =
        LifeGenerator.seeded(seed).generate(mode: StartMode.tamamenRastgele);
    return base.copyWith(
      player: base.player.copyWith(age: age, wallet: wallet),
    );
  }

  group('Finger yaş bandı (D-081)', () {
    test('47 yaşındaki oyuncuya 17 yaşında biri çıkmaz', () {
      expect(Finger.minCandidateAge(47), greaterThanOrEqualTo(18));
      expect(Finger.minCandidateAge(47), greaterThan(30));
    });

    test('alt sınır hiçbir yaşta 18in altına inmez', () {
      for (int yas = 18; yas <= 90; yas++) {
        expect(Finger.minCandidateAge(yas), greaterThanOrEqualTo(18),
            reason: '$yas yaşında alt sınır düşük');
        expect(Finger.maxCandidateAge(yas),
            greaterThanOrEqualTo(Finger.minCandidateAge(yas)));
      }
    });

    test('üretilen profiller bandın içinde kalır', () {
      for (final int yas in <int>[20, 35, 47, 60, 75]) {
        GameState s = hayat(1, age: yas);
        s = Finger.ensureDeck(s, Random(yas));
        expect(s.fingerDeck, isNotEmpty);
        for (final FingerProfile p in s.fingerDeck) {
          expect(Finger.fitsAge(s, p), isTrue,
              reason: '$yas yaşında ${p.age} yaşında profil çıktı');
        }
      }
    });

    test('yaşlanınca eski profiller desteden düşer', () {
      // Faho\'nun bildirdiği hatanın tam kaynağı: deste bir kez kurulup
      // öylece duruyordu.
      GameState genc = hayat(2, age: 20);
      genc = Finger.ensureDeck(genc, Random(1));
      final List<String> eskiler =
          genc.fingerDeck.map((FingerProfile p) => p.id).toList();
      expect(eskiler, isNotEmpty);

      GameState yasli = genc.copyWith(
        player: genc.player.copyWith(age: 47),
      );
      yasli = Finger.ensureDeck(yasli, Random(2));
      for (final FingerProfile p in yasli.fingerDeck) {
        expect(Finger.fitsAge(yasli, p), isTrue);
      }
    });
  });

  group('Finger beğeni kotası ve premium (D-081)', () {
    test('yılda beş beğeni; premiumda daha çok', () {
      final GameState s = hayat(3, age: 25);
      expect(Finger.likeLimit(s), kFingerMaxLikesPerAge);
      final GameState premium =
          s.copyWith(fingerPremiumUntilAge: s.player.age);
      expect(Finger.likeLimit(premium), kFingerPremiumLikesPerAge);
      expect(kFingerPremiumLikesPerAge, greaterThan(kFingerMaxLikesPerAge));
    });

    test('kota dolunca gerekçe premium seçeneğini söyler', () {
      GameState s = hayat(4, age: 25);
      s = s.copyWith(
        interactionCounts: <String, int>{
          GameState.interactionKey('finger', 'begeni'): kFingerMaxLikesPerAge,
        },
      );
      final InteractionAvailability izin = Finger.likeAvailability(s);
      expect(izin.isAllowed, isFalse);
      expect(izin.reason, contains('Premium'));
    });

    test('geçmek kotadan düşmez', () {
      GameState s = hayat(5, age: 25);
      s = Finger.ensureDeck(s, Random(1));
      final int once = Finger.likesThisAge(s);
      s = Finger.pass(s, s.fingerDeck.first.id, Random(1)).state;
      expect(Finger.likesThisAge(s), once);
    });

    test('premium ücreti bir kez düşer', () {
      final GameState s = hayat(6, age: 25, wallet: 100000);
      final FingerResult r = Finger.buyPremium(s);
      expect(r.outcome.applied, isTrue);
      expect(
        r.state.player.wallet,
        s.player.wallet - kFingerPremiumYearlyCost,
      );
      expect(r.state.hasFingerPremium, isTrue);
      // İkinci kez alınamaz.
      expect(Finger.buyPremium(r.state).outcome.applied, isFalse);
    });

    test('profil doldurulmadan kimse kendiliğinden beğenmez', () {
      GameState s = hayat(7, age: 25);
      s = Finger.ensureDeck(s, Random(1));
      expect(s.hasFingerProfile, isFalse);
      expect(s.fingerIncoming, isEmpty);

      s = Finger.saveProfile(
        s,
        bio: kFingerBios.first,
        interests: <String>[kFingerInterests.first],
      ).state;
      s = Finger.ensureDeck(s, Random(2));
      expect(s.hasFingerProfile, isTrue);
      expect(s.fingerIncoming, isNotEmpty);
    });

    test('profil eşleşme ihtimalini yükseltir', () {
      final GameState bos = hayat(8, age: 25);
      final GameState dolu = Finger.saveProfile(
        bos,
        bio: kFingerBios.first,
        interests: <String>[kFingerInterests.first],
      ).state;
      expect(Finger.matchChance(dolu), greaterThan(Finger.matchChance(bos)));
    });

    test('seni beğenen birini beğenmek kesin eşleşir', () {
      GameState s = hayat(9, age: 25);
      s = Finger.saveProfile(
        s,
        bio: kFingerBios.first,
        interests: <String>[kFingerInterests.first],
      ).state;
      s = Finger.ensureDeck(s, Random(3));
      expect(s.fingerIncoming, isNotEmpty);

      final String id = s.fingerIncoming.first.id;
      final FingerResult r = Finger.like(s, id, Random(999));
      expect(r.outcome.applied, isTrue);
      expect(r.outcome.matched, isTrue,
          reason: 'Karşı taraf zaten beğenmişti');
      expect(
        r.state.fingerIncoming.any((FingerProfile p) => p.id == id),
        isFalse,
      );
    });
  });

  group('Tur paketleri (D-083)', () {
    test('paketlerin gezdiği şehirler oyunun şehir listesinde', () {
      expect(kTourPackages, isNotEmpty);
      for (final TourPackage t in kTourPackages) {
        expect(t.cities, isNotEmpty, reason: t.label);
        for (final String sehir in t.cities) {
          expect(sehirler, contains(sehir),
              reason: '${t.label} turunda olmayan şehir: $sehir');
        }
      }
    });

    test('uzun tur daha pahalı', () {
      final List<TourPackage> sirali = <TourPackage>[...kTourPackages]
        ..sort((TourPackage a, TourPackage b) => a.nights.compareTo(b.nights));
      for (int i = 1; i < sirali.length; i++) {
        expect(
          sirali[i].prototypeOnlyCost,
          greaterThanOrEqualTo(sirali[i - 1].prototypeOnlyCost),
          reason: '${sirali[i].label} kısa turdan ucuz',
        );
      }
    });

    test('tura çıkmak parayı düşürür ve gezi kaydı açar', () {
      final GameState s = hayat(10, age: 30, wallet: 1000000);
      final TourPackage tur = kTourPackages.first;
      final TripResult r = Travel.takeTour(s, tour: tur, rng: Random(1));

      expect(r.outcome.applied, isTrue, reason: r.outcome.text);
      expect(r.state.player.wallet, s.player.wallet - tur.prototypeOnlyCost);
      expect(r.state.trips, hasLength(1));
      expect(r.state.trips.single.city, tur.mainCity);
      // Tatil taşınma değildir.
      expect(r.state.player.currentCity, s.player.currentCity);
    });

    test('parası yetmeyen tura çıkamaz ve hiçbir şey değişmez', () {
      final GameState s = hayat(11, age: 30, wallet: 100);
      final TourPackage tur = kTourPackages.last;
      final TripResult r = Travel.takeTour(s, tour: tur, rng: Random(1));
      expect(r.outcome.applied, isFalse);
      expect(r.state.player.wallet, s.player.wallet);
      expect(r.state.trips, isEmpty);
    });

    test('tur yıllık gezi kotasını kullanır', () {
      GameState s = hayat(12, age: 30, wallet: 5000000);
      for (int i = 0; i < Travel.prototypeOnlyMaxTripsPerAge; i++) {
        final TripResult r =
            Travel.takeTour(s, tour: kTourPackages.first, rng: Random(i));
        expect(r.outcome.applied, isTrue, reason: r.outcome.text);
        s = r.state;
      }
      final TripResult fazla =
          Travel.takeTour(s, tour: kTourPackages.first, rng: Random(9));
      expect(fazla.outcome.applied, isFalse);
    });
  });

  group('Yakın iller ve taşınma (D-083)', () {
    test('komşuluk karşılıklıdır', () {
      kCityNeighbours.forEach((String sehir, List<String> komsular) {
        for (final String k in komsular) {
          expect(
            neighboursOf(k),
            contains(sehir),
            reason: '$sehir → $k var ama $k → $sehir yok',
          );
        }
      });
    });

    test('her şehrin komşusu oyunun şehir listesinde ve kendisi değil', () {
      kCityNeighbours.forEach((String sehir, List<String> komsular) {
        expect(sehirler, contains(sehir));
        expect(komsular, isNot(contains(sehir)));
        for (final String k in komsular) {
          expect(sehirler, contains(k), reason: '$k oyunun listesinde yok');
        }
      });
    });

    test('oyunun bütün şehirlerinin komşusu tanımlı', () {
      for (final String sehir in sehirler) {
        expect(neighboursOf(sehir), isNotEmpty, reason: '$sehir komşusuz');
      }
    });

    test('uzak şehre taşınılamaz, yakın şehre taşınılır', () {
      const Housing housing = Housing();
      GameState s = hayat(13, age: 30, wallet: 5000000);
      s = s.copyWith(player: s.player.copyWith(currentCity: 'Amasya'));

      final String yakin = neighboursOf('Amasya').first;
      final String uzak = sehirler.firstWhere(
        (String c) => c != 'Amasya' && !areNeighbours('Amasya', c),
      );

      final HousingResult red = housing.moveToRental(s, city: uzak);
      expect(red.outcome.applied, isFalse);
      expect(red.state.player.currentCity, 'Amasya');

      final HousingResult kabul = housing.moveToRental(s, city: yakin);
      expect(kabul.outcome.applied, isTrue, reason: kabul.outcome.text);
      expect(kabul.state.player.currentCity, yakin);
    });

    test('taşındıktan sonra liste yeni şehre göre yenilenir', () {
      const Housing housing = Housing();
      GameState s = hayat(14, age: 30, wallet: 5000000);
      s = s.copyWith(player: s.player.copyWith(currentCity: 'Amasya'));
      final List<String> once = housing.relocationTargets(s);

      final String yakin = neighboursOf('Amasya').first;
      s = housing.moveToRental(s, city: yakin).state;
      final List<String> sonra = housing.relocationTargets(s);

      expect(sonra, isNot(once));
      expect(sonra, neighboursOf(yakin));
    });

    test('şehir değiştirmek daha pahalı', () {
      const Housing housing = Housing();
      GameState s = hayat(15, age: 30, wallet: 5000000);
      s = s.copyWith(player: s.player.copyWith(currentCity: 'Amasya'));

      final int ayniIl =
          s.player.wallet - housing.moveToRental(s).state.player.wallet;
      final int baskaIl = s.player.wallet -
          housing
              .moveToRental(s, city: neighboursOf('Amasya').first)
              .state
              .player
              .wallet;
      expect(baskaIl, greaterThan(ayniIl));
    });
  });

  group('Hayatın sonu seçeneği (D-084)', () {
    test('çocuk yaşta hiç açılmaz', () {
      for (int yas = 0; yas < LifeEndChoice.prototypeOnlyMinAge; yas++) {
        expect(
          LifeEndChoice.blockReason(age: yas, deceased: false),
          isNotNull,
          reason: '$yas yaşında açık görünüyor',
        );
      }
    });

    test('tamamlanmış hayatta tekrar seçilemez', () {
      expect(
        LifeEndChoice.blockReason(age: 40, deceased: true),
        isNotNull,
      );
    });

    test('metinlerde yöntem geçmez ve gerçek destek bilgisi vardır', () {
      // Bilerek konmuş kural: hiçbir metinde yöntem, araç ya da ayrıntı
      // bulunmaz.
      final String hepsi = <String>[
        kLifeEndConfirmText,
        kLifeEndSupportText,
        kLifeEndCause,
        LifeEndChoice.logLine(40),
      ].join(' ').toLowerCase();

      for (final String yasak in <String>[
        'ilaç',
        'bıçak',
        'ip',
        'silah',
        'atla',
        'doz',
      ]) {
        expect(hepsi.contains(yasak), isFalse,
            reason: '"$yasak" geçmemeli');
      }

      // Gerçek ve resmî destek bilgisi bulunur.
      expect(kLifeEndSupportText, contains('112'));
      expect(kLifeEndSupportText, contains('183'));
    });

    test('ölüm nedeni kısa ve ayrıntısızdır', () {
      expect(kLifeEndCause.length, lessThan(30));
    });
  });

  group('Eşin beklentileri (D-085)', () {
    GameEvent olay(String id) =>
        kEventPool.firstWhere((GameEvent e) => e.id == id);

    test('ev beklentisi olayı evi olmayana özeldir', () {
      final EventRequirement r = olay('esten_ev_beklentisi').requirement;
      expect(r.forbidsProperty, isTrue);
      expect(r.livingRelations, isNotEmpty);
      expect(r.requireSameHousehold, isTrue);
    });

    test('araba beklentisi olayı aracı olmayana özeldir', () {
      final EventRequirement r = olay('esten_araba_beklentisi').requirement;
      expect(r.forbidsVehicle, isTrue);
      expect(r.livingRelations, isNotEmpty);
    });

    test('evi olan oyuncuya ev beklentisi olayı çıkmaz', () {
      const EventEngine motor = EventEngine();
      GameState evli = hayat(16, age: 35);
      evli = evli.grantItems(
        <String>['standart_daire'],
        source: ItemSource.satinAlma,
      );
      expect(
        motor.debugMatches(evli, olay('esten_ev_beklentisi')),
        isFalse,
      );
    });

    test('söz verme izi hatırlatma olayının koşuludur', () {
      final EventRequirement r =
          olay('esten_ev_sozu_hatirlatma').requirement;
      expect(r.requiredFlags, isNotEmpty);
      expect(r.forbidsProperty, isTrue);
    });

    test('her seçenek gerçek bir etki taşır', () {
      for (final String id in <String>[
        'esten_ev_beklentisi',
        'esten_araba_beklentisi',
        'esten_ev_sozu_hatirlatma',
      ]) {
        for (final EventChoice c in olay(id).choices) {
          final bool etkili = c.happiness != 0 ||
              c.bond != 0 ||
              c.money != 0 ||
              c.charisma != 0 ||
              c.addFlags.isNotEmpty;
          expect(etkili, isTrue, reason: '$id/${c.id} etkisiz');
        }
      }
    });
  });
}

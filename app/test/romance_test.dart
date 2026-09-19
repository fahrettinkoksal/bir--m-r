import 'dart:math';

import 'package:bir_omur/data/event_pool.dart';
import 'package:bir_omur/domain/events/event_engine.dart';
import 'package:bir_omur/domain/generation/life_generator.dart';
import 'package:bir_omur/domain/interaction/family_interactions.dart';
import 'package:bir_omur/domain/interaction/romance.dart';
import 'package:bir_omur/domain/models/game_event.dart';
import 'package:bir_omur/domain/models/game_state.dart';
import 'package:bir_omur/domain/models/gender.dart';
import 'package:bir_omur/domain/models/interaction.dart';
import 'package:bir_omur/domain/models/person.dart';
import 'package:bir_omur/domain/models/relation.dart';
import 'package:flutter_test/flutter_test.dart';

/// Aşama 4 kabulü: sevgili → ayrılık → **aynı kişi** eski sevgili olarak
/// kalır; kimlik değişmez, başka aile üyeleri etkilenmez.
void main() {
  GameEvent eventById(String id) =>
      kEventPool.firstWhere((GameEvent e) => e.id == id);

  EventEngine romanceEngine() => EventEngine(
        pool: <GameEvent>[
          eventById('ilk_goz_agrisi'),
          eventById('cikma_teklifi'),
          eventById('iliski_tartismasi'),
          eventById('eski_sevgili_karsilasma'),
        ],
      );

  GameState lifeAt(int seed, int age) {
    final GameState state =
        LifeGenerator.seeded(seed).generate(mode: StartMode.tamamenRastgele);
    return state.copyWith(player: state.player.copyWith(age: age));
  }

  /// Tanışma → teklif zincirini yürütüp sevgili edinilmiş durumu döndürür.
  ({GameState state, String partnerId}) withPartner(int seed) {
    final EventEngine engine = romanceEngine();
    final Random rng = Random(seed);
    GameState state = lifeAt(seed, 17);

    final ActiveEvent? tanisma = engine.openingEvent(state, rng);
    expect(tanisma!.eventId, 'ilk_goz_agrisi');
    state = engine.resolve(state.copyWith(pendingEvent: tanisma), 'selam',
        rng: rng);

    final ActiveEvent? teklif = engine.openingEvent(state, rng);
    expect(teklif!.eventId, 'cikma_teklifi');
    state =
        engine.resolve(state.copyWith(pendingEvent: teklif), 'teklif', rng: rng);

    final Person partner = state.people
        .firstWhere((Person p) => p.relation == RelationType.sevgili);
    return (state: state, partnerId: partner.id);
  }

  group('İlişkinin başlaması (D-030)', () {
    test('teklif seçimi gerçekten bir sevgili ekler', () {
      final ({GameState state, String partnerId}) sonuc = withPartner(5);
      final Person partner = sonuc.state.personById(sonuc.partnerId)!;

      expect(partner.relation, RelationType.sevgili);
      expect(partner.isAlive, isTrue);
      expect(partner.firstName, isNotEmpty);
      expect(sonuc.state.storyFlags, contains(StoryFlags.romantikIliskide));
    });

    test('sevgili akraba sayılmaz ve otomatik aynı evde yaşamaz', () {
      for (int seed = 0; seed < 25; seed++) {
        final ({GameState state, String partnerId}) sonuc = withPartner(seed);
        final Person partner = sonuc.state.personById(sonuc.partnerId)!;
        expect(partner.relation.kanBagi, isFalse);
        expect(partner.relation.group, RelationGroup.romantik);
        expect(partner.inPlayerHousehold, isFalse,
            reason: 'Sevgili otomatik hanede sayılmaz');
      }
    });

    test('teklif edilmezse sevgili oluşmaz', () {
      final EventEngine engine = romanceEngine();
      final Random rng = Random(3);
      GameState state = lifeAt(3, 17);

      final ActiveEvent? tanisma = engine.openingEvent(state, rng);
      state = engine.resolve(state.copyWith(pendingEvent: tanisma), 'gec',
          rng: rng);
      expect(state.storyFlags, contains(StoryFlags.romantikGecti));

      // Tanışmada geçildiyse teklif olayı hiç açılmaz.
      for (int i = 0; i < 30; i++) {
        final ActiveEvent? sonraki = engine.openingEvent(state, Random(i));
        expect(sonraki?.eventId, isNot('cikma_teklifi'));
      }
      expect(
        state.people.any((Person p) => p.relation == RelationType.sevgili),
        isFalse,
      );
    });

    test('ilişki hikâyesi uygun olmayan yaşa zorla açılmaz', () {
      final EventEngine engine = romanceEngine();
      final GameState cocuk = lifeAt(5, 9);
      expect(engine.openingEvent(cocuk, Random(1)), isNull);
    });

    test('partner cinsiyeti prototipte oyuncunun karşıtıdır', () {
      for (int seed = 0; seed < 20; seed++) {
        final ({GameState state, String partnerId}) sonuc = withPartner(seed);
        final Person partner = sonuc.state.personById(sonuc.partnerId)!;
        final Gender beklenen = sonuc.state.player.gender == Gender.kadin
            ? Gender.erkek
            : Gender.kadin;
        expect(partner.gender, beklenen);
      }
    });

    test('statü etiketi cinsiyete göre doğru yazılır', () {
      final ({GameState state, String partnerId}) sonuc = withPartner(5);
      final Person partner = sonuc.state.personById(sonuc.partnerId)!;
      final String etiket = partner.labelFor(sonuc.state.player.age);
      expect(
        etiket,
        partner.gender == Gender.kadin ? 'Kız arkadaş' : 'Erkek arkadaş',
      );
    });
  });

  group('Ayrılık: aynı kişi, değişen statü (D-029)', () {
    test('doğrudan ayrılma kişiyi silmez, kimliği korur', () {
      final ({GameState state, String partnerId}) once = withPartner(5);
      final Person partnerOnce = once.state.personById(once.partnerId)!;
      final int kisiSayisi = once.state.people.length;

      final GameState sonra =
          const Romance().end(once.state, once.partnerId);
      final Person partnerSonra = sonra.personById(once.partnerId)!;

      expect(sonra.people.length, kisiSayisi, reason: 'Kayıt silinmez');
      expect(partnerSonra.id, partnerOnce.id, reason: 'Kimlik değişmez');
      expect(partnerSonra.firstName, partnerOnce.firstName);
      expect(partnerSonra.lastName, partnerOnce.lastName);
      expect(partnerSonra.bond, partnerOnce.bond,
          reason: 'Yakınlık sıfırlanmaz');
      expect(partnerSonra.relation, RelationType.eskiSevgili);
      expect(
        partnerSonra.labelFor(sonra.player.age),
        partnerSonra.gender == Gender.kadin
            ? 'Eski kız arkadaş'
            : 'Eski erkek arkadaş',
      );
    });

    test('olaydaki ayrılık seçimi de aynı kimliği korur', () {
      final EventEngine engine = romanceEngine();
      final Random rng = Random(9);
      final ({GameState state, String partnerId}) once = withPartner(9);
      GameState state = once.state.copyWith(
        player: once.state.player.copyWith(age: 19),
      );
      final Person partnerOnce = state.personById(once.partnerId)!;

      final ActiveEvent? tartisma = engine.openingEvent(state, rng);
      expect(tartisma!.eventId, 'iliski_tartismasi');
      expect(tartisma.personId, once.partnerId);

      state = engine.resolve(state.copyWith(pendingEvent: tartisma), 'ayril',
          rng: rng);

      final Person partnerSonra = state.personById(once.partnerId)!;
      expect(partnerSonra.id, partnerOnce.id);
      expect(partnerSonra.relation, RelationType.eskiSevgili);
      expect(state.storyFlags, contains(StoryFlags.romantikBitti));
      expect(state.storyFlags, isNot(contains(StoryFlags.romantikIliskide)));
    });

    test('ayrılık başka aile üyelerini eski sevgiliye çevirmez', () {
      for (int seed = 0; seed < 25; seed++) {
        final ({GameState state, String partnerId}) once = withPartner(seed);
        final Map<String, RelationType> oncekiBaglar = <String, RelationType>{
          for (final Person p in once.state.people) p.id: p.relation,
        };

        final GameState sonra =
            const Romance().end(once.state, once.partnerId);

        for (final Person p in sonra.people) {
          if (p.id == once.partnerId) {
            expect(p.relation, RelationType.eskiSevgili);
          } else {
            expect(p.relation, oncekiBaglar[p.id],
                reason: 'Diğer kişilerin bağı değişmemeli');
          }
        }
        expect(
          sonra.people
              .where((Person p) => p.relation == RelationType.eskiSevgili)
              .length,
          1,
        );
      }
    });

    test('olay geçmişi ayrılıktan sonra da durur', () {
      final ({GameState state, String partnerId}) once = withPartner(5);
      final Person partner = once.state.personById(once.partnerId)!;
      final int logOnce = once.state.log.length;
      expect(
        once.state.log.any((dynamic e) =>
            (e.text as String).contains(partner.firstName)),
        isTrue,
        reason: 'Tanışma/teklif günlüğe yazılmış olmalı',
      );

      final GameState sonra = const Romance().end(once.state, once.partnerId);
      expect(sonra.log.length, logOnce + 1);
      expect(
        sonra.log.any((dynamic e) =>
            (e.text as String).contains(partner.firstName)),
        isTrue,
        reason: 'Eski kayıtlar silinmez',
      );
    });

    test('sevgili olmayan biri için ayrılma çalışmaz', () {
      final ({GameState state, String partnerId}) once = withPartner(5);
      final Person anne = once.state.people
          .firstWhere((Person p) => p.relation == RelationType.anne);

      final GameState sonra = const Romance().end(once.state, anne.id);
      expect(sonra.personById(anne.id)!.relation, RelationType.anne);
      expect(sonra.log.length, once.state.log.length);
    });

    test('ayrılık sonrası ilişki olayı çıkmaz, karşılaşma olayı çıkar', () {
      final EventEngine engine = romanceEngine();
      final ({GameState state, String partnerId}) once = withPartner(5);
      GameState state = const Romance().end(once.state, once.partnerId);
      state = state.copyWith(
        player: state.player.copyWith(age: 20),
        storyFlags: <String>{
          ...state.storyFlags,
          StoryFlags.romantikBitti,
        }..remove(StoryFlags.romantikIliskide),
      );

      for (int i = 0; i < 20; i++) {
        final ActiveEvent? olay = engine.openingEvent(state, Random(i));
        expect(olay?.eventId, isNot('iliski_tartismasi'),
            reason: 'Sevgili yokken ilişki olayı çıkmamalı');
      }
      final ActiveEvent? karsilasma = engine.openingEvent(state, Random(1));
      expect(karsilasma!.eventId, 'eski_sevgili_karsilasma');
      expect(karsilasma.personId, once.partnerId);
    });
  });

  group('Eski sevgiliye sevgiliye özel eylemler açılmaz', () {
    test('sevgiliyken etkileşim açık, ayrıldıktan sonra kapalıdır', () {
      const FamilyInteractions interactions = FamilyInteractions();
      final ({GameState state, String partnerId}) iliskide = withPartner(5);
      final Person sevgili = iliskide.state.personById(iliskide.partnerId)!;
      expect(interactions.availability(iliskide.state, sevgili).isAllowed, isTrue);

      final GameState ayrildi =
          const Romance().end(iliskide.state, iliskide.partnerId);
      final Person eski = ayrildi.personById(iliskide.partnerId)!;
      final InteractionAvailability kapali =
          interactions.availability(ayrildi, eski);

      expect(kapali.isAllowed, isFalse);
      expect(kapali.reason, isNotNull);
      expect(kapali.reason, isNotEmpty);
    });
  });

  group('Baştan sona akış', () {
    test('yeni hayat → sevgili → ayrılık → Aile listesinde eski sevgili', () {
      final EventEngine engine = romanceEngine();
      final Random rng = Random(11);
      final ({GameState state, String partnerId}) once = withPartner(11);

      // İlişki sırasında Aile listesinde sevgili olarak görünür.
      final List<Person> romantikler =
          once.state.byGroup(RelationGroup.romantik);
      expect(romantikler.length, 1);
      expect(romantikler.single.relation, RelationType.sevgili);

      GameState state = once.state.copyWith(
        player: once.state.player.copyWith(age: 19),
      );
      final ActiveEvent? tartisma = engine.openingEvent(state, rng);
      state = engine.resolve(state.copyWith(pendingEvent: tartisma!), 'ayril',
          rng: rng);

      // Ayrılıktan sonra aynı kişi eski sevgili olarak listede kalır.
      final List<Person> sonraki = state.byGroup(RelationGroup.romantik);
      expect(sonraki.length, 1);
      expect(sonraki.single.id, romantikler.single.id);
      expect(sonraki.single.relation, RelationType.eskiSevgili);
    });
  });

  group('İki ayrılık yolu aynı hikâye durumunu üretir (regresyon)', () {
    test('kişi detayından ayrılma da hikâye izlerini günceller', () {
      final ({GameState state, String partnerId}) once = withPartner(5);
      expect(once.state.storyFlags, contains(StoryFlags.romantikIliskide));

      final GameState sonra = const Romance().end(once.state, once.partnerId);

      expect(sonra.storyFlags, contains(StoryFlags.romantikBitti));
      expect(sonra.storyFlags, isNot(contains(StoryFlags.romantikIliskide)));
      expect(
        sonra.personById(once.partnerId)!.relation,
        RelationType.eskiSevgili,
      );
    });

    test('düğmeyle ve olayla ayrılmak aynı durumu bırakır', () {
      // Aynı hayattan iki kopya: biri olay seçeneğiyle, biri düğmeyle ayrılır.
      final ({GameState state, String partnerId}) once = withPartner(9);
      final GameState baslangic = once.state.copyWith(
        player: once.state.player.copyWith(age: 19),
      );

      final EventEngine engine = romanceEngine();
      final ActiveEvent? tartisma = engine.openingEvent(baslangic, Random(1));
      expect(tartisma!.eventId, 'iliski_tartismasi');
      final GameState olayla = engine.resolve(
        baslangic.copyWith(pendingEvent: tartisma),
        'ayril',
        rng: Random(1),
      );

      final GameState dugmeyle =
          const Romance().end(baslangic, once.partnerId);

      // İlişkiye dair durum iki yolda da aynı olmalı.
      expect(
        olayla.storyFlags.contains(StoryFlags.romantikBitti),
        dugmeyle.storyFlags.contains(StoryFlags.romantikBitti),
      );
      expect(
        olayla.storyFlags.contains(StoryFlags.romantikIliskide),
        dugmeyle.storyFlags.contains(StoryFlags.romantikIliskide),
      );
      expect(olayla.storyFlags.contains(StoryFlags.romantikBitti), isTrue);
      expect(olayla.storyFlags.contains(StoryFlags.romantikIliskide), isFalse);
      expect(
        olayla.personById(once.partnerId)!.relation,
        dugmeyle.personById(once.partnerId)!.relation,
      );
      expect(
        olayla.personById(once.partnerId)!.id,
        dugmeyle.personById(once.partnerId)!.id,
      );
    });

    test('her iki yoldan sonra da eski sevgili karşılaşma olayı açılabilir', () {
      final EventEngine karsilasmaEngine = EventEngine(
        pool: <GameEvent>[eventById('eski_sevgili_karsilasma')],
      );
      final ({GameState state, String partnerId}) once = withPartner(5);
      final GameState baslangic = once.state.copyWith(
        player: once.state.player.copyWith(age: 20),
      );

      // İlişki sürerken karşılaşma olayı çıkmaz.
      expect(karsilasmaEngine.openingEvent(baslangic, Random(1)), isNull);

      // Düğmeyle ayrıldıktan sonra çıkar.
      final GameState dugmeyle =
          const Romance().end(baslangic, once.partnerId);
      final ActiveEvent? dugmeSonrasi =
          karsilasmaEngine.openingEvent(dugmeyle, Random(1));
      expect(dugmeSonrasi, isNotNull,
          reason: 'Düğmeyle ayrılma da önkoşulu sağlamalı');
      expect(dugmeSonrasi!.personId, once.partnerId);

      // Olay seçeneğiyle ayrıldıktan sonra da çıkar.
      final EventEngine engine = romanceEngine();
      final ActiveEvent? tartisma = engine.openingEvent(baslangic, Random(1));
      final GameState olayla = engine.resolve(
        baslangic.copyWith(pendingEvent: tartisma!),
        'ayril',
        rng: Random(1),
      );
      final ActiveEvent? olaySonrasi =
          karsilasmaEngine.openingEvent(olayla, Random(1));
      expect(olaySonrasi, isNotNull);
      expect(olaySonrasi!.personId, once.partnerId);
    });

    test('ilişki başlarken sürüyor izi düğme yolundan bağımsız kurulur', () {
      final ({GameState state, String partnerId}) once = withPartner(11);
      expect(once.state.storyFlags, contains(StoryFlags.romantikIliskide));
      expect(once.state.storyFlags, isNot(contains(StoryFlags.romantikBitti)));
    });
  });
}

import 'dart:math';

import 'package:bir_omur/data/event_pool.dart';
import 'package:bir_omur/data/gift_catalog.dart';
import 'package:bir_omur/data/possession_names.dart';
import 'package:bir_omur/domain/effects/effect_diff.dart';
import 'package:bir_omur/domain/events/event_engine.dart';
import 'package:bir_omur/domain/generation/life_generator.dart';
import 'package:bir_omur/domain/generation/life_progression.dart';
import 'package:bir_omur/domain/generation/school_people.dart';
import 'package:bir_omur/domain/interaction/family_interactions.dart';
import 'package:bir_omur/domain/models/applied_effect.dart';
import 'package:bir_omur/domain/models/education.dart';
import 'package:bir_omur/domain/models/game_event.dart';
import 'package:bir_omur/domain/models/game_state.dart';
import 'package:bir_omur/domain/models/gender.dart';
import 'package:bir_omur/domain/models/gift_record.dart';
import 'package:bir_omur/domain/models/interaction.dart';
import 'package:bir_omur/domain/models/owned_item.dart';
import 'package:bir_omur/domain/models/person.dart';
import 'package:bir_omur/domain/models/relation.dart';
import 'package:bir_omur/domain/models/wealth.dart';
import 'package:bir_omur/state/game_controller.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/test_flow.dart';

GameEvent eventById(String id) =>
    kEventPool.firstWhere((GameEvent e) => e.id == id);

GameState studentAt({required int seed, required int age, required int grade}) {
  final GameState state =
      LifeGenerator.seeded(seed).generate(mode: StartMode.tamamenRastgele);
  return withSchoolPeople(
    state.copyWith(
      player: state.player.copyWith(age: age),
      education: EducationState(enrolled: true, grade: grade, startedAtAge: 6),
    ),
    seed: seed,
  );
}

Person? firstWhereOrNull(Iterable<Person> people, bool Function(Person) test) {
  for (final Person p in people) {
    if (test(p)) return p;
  }
  return null;
}

void main() {
  // ======================================================================
  // 1) Olaylardaki kişi kimliği ve bağlamı
  // ======================================================================
  group('Olay metinlerinde kişi kimliği', () {
    test('hiçbir olay metninde doldurulmamış yer tutucu kalmaz', () {
      for (int seed = 0; seed < 25; seed++) {
        final GameController controller = GameController(random: Random(seed));
        controller.startNewLife(mode: StartMode.tamamenRastgele, seed: seed);
        for (int i = 0; i < 60; i++) {
          final GameState state = controller.state!;
          if (state.hasPendingEvent) {
            final ActiveEvent event = state.pendingEvent!;
            expect(event.text, isNot(contains('{')),
                reason: '${event.eventId} metninde yer tutucu kaldı');
            final EventChoiceResult? sonuc =
                controller.chooseEventOption(event.choices.first.id);
            expect(sonuc!.text, isNot(contains('{')),
                reason: '${event.eventId} sonucunda yer tutucu kaldı');
          } else {
            controller.ageUp();
          }
        }
      }
    });

    test('iyelik eki ve akrabalık yönü doğru yazılır', () {
      expect(
        relationPossessive(
          relation: RelationType.anneTarafiDede,
          gender: Gender.erkek,
          personAge: 70,
          playerAge: 10,
        ),
        'Anne tarafından deden',
      );
      expect(
        relationPossessive(
          relation: RelationType.babaTarafiDede,
          gender: Gender.erkek,
          personAge: 70,
          playerAge: 10,
        ),
        'Baba tarafından deden',
      );
      expect(
        relationPossessive(
          relation: RelationType.sinifArkadasi,
          gender: Gender.kadin,
          personAge: 10,
          playerAge: 10,
        ),
        'Sınıf arkadaşın',
      );
    });

    test('bisikleti getiren kişi adı ve bağıyla yazılır', () {
      final EventEngine engine =
          EventEngine(pool: <GameEvent>[eventById('bisiklet_hediyesi')]);
      bool gorunduMu = false;
      for (int seed = 0; seed < 25 && !gorunduMu; seed++) {
        final GameState state =
            LifeGenerator.seeded(seed).generate(mode: StartMode.tamamenRastgele);
        final GameState onYas =
            state.copyWith(player: state.player.copyWith(age: 10));
        final ActiveEvent? olay = engine.openingEvent(onYas, Random(seed));
        if (olay == null) continue;
        gorunduMu = true;
        final Person kisi = onYas.personById(olay.personId!)!;
        expect(olay.text, startsWith(kisi.possessiveFor(10)));
        expect(olay.text, contains(kisi.firstName));
      }
      expect(gorunduMu, isTrue, reason: 'Bisiklet olayı hiç çıkmadı');
    });

    test('kişi gerektiren olay, kişi yoksa hiç çıkmaz', () {
      // Sınıf arkadaşı olmayan bir öğrenciye tanışma olayı çıkmaz:
      // olmayan bir çocuk uydurulmaz.
      final EventEngine engine =
          EventEngine(pool: <GameEvent>[eventById('okul_sira_arkadasi')]);
      final GameState state =
          LifeGenerator.seeded(4).generate(mode: StartMode.tamamenRastgele);
      final GameState ogrenci = state.copyWith(
        player: state.player.copyWith(age: 8),
        education: const EducationState(enrolled: true, grade: 3, startedAtAge: 6),
      );
      expect(
        ogrenci.people.any((Person p) => p.relation == RelationType.sinifArkadasi),
        isFalse,
      );
      expect(engine.openingEvent(ogrenci, Random(1)), isNull);
    });

    test('yıllar sonraki devam olayı aynı kişiyi kullanır', () {
      final EventEngine engine = EventEngine(
        pool: <GameEvent>[
          eventById('arkadasi_savunma'),
          eventById('savundugun_arkadas'),
        ],
      );
      GameState state = studentAt(seed: 3, age: 11, grade: 6);
      final ActiveEvent? ilk = engine.openingEvent(state, Random(1));
      expect(ilk!.eventId, 'arkadasi_savunma');
      final String kisiId = ilk.personId!;

      state = engine.resolve(state.copyWith(pendingEvent: ilk), 'savun');
      expect(state.storyPeople[StoryRoles.alayEdilenArkadas], kisiId);

      state = state.copyWith(player: state.player.copyWith(age: 17));
      final ActiveEvent? devam = engine.openingEvent(state, Random(1));
      expect(devam!.eventId, 'savundugun_arkadas');
      expect(devam.personId, kisiId, reason: 'Aynı kişi gelmeli');
      expect(devam.text, contains(state.personById(kisiId)!.firstName));
    });

    test('rolü tutan kişi yoksa devam olayı açılmaz', () {
      final EventEngine engine =
          EventEngine(pool: <GameEvent>[eventById('savundugun_arkadas')]);
      final GameState state =
          LifeGenerator.seeded(2).generate(mode: StartMode.tamamenRastgele);
      final GameState izli = state.copyWith(
        player: state.player.copyWith(age: 17),
        storyFlags: <String>{StoryFlags.arkadasiniSavundu},
      );
      expect(engine.openingEvent(izli, Random(1)), isNull);
    });
  });

  // ======================================================================
  // 2) Seçim sonuçları: gerçekten uygulanan değişimler
  // ======================================================================
  group('Uygulanan etkiler', () {
    test('olay seçimi para ve eşya kazancını rozet olarak bildirir', () {
      EventChoiceResult? bisikletSonucu;
      for (int seed = 0; seed < 40 && bisikletSonucu == null; seed++) {
        final GameController controller = GameController(random: Random(seed));
        controller.startNewLife(mode: StartMode.tamamenRastgele, seed: seed);
        for (int i = 0; i < 60 && bisikletSonucu == null; i++) {
          final GameState state = controller.state!;
          if (state.hasPendingEvent) {
            final ActiveEvent olay = state.pendingEvent!;
            final bool bisiklet = olay.eventId == 'bisiklet_hediyesi';
            if (bisiklet) {
              // Rozet "gerçekten uygulanan" etkiyi gösterir: mutluluk
              // zaten 100'deyse artış yazılmaz (D-035). Bu test artışı
              // sınadığı için tavan altından başlatılır.
              controller.debugSetState(
                state.copyWith(
                  player: state.player.copyWith(
                    stats: state.player.stats.copyWith(happiness: 60),
                  ),
                ),
              );
            }
            final EventChoiceResult? sonuc = controller.chooseEventOption(
              bisiklet ? 'sarilarak' : olay.choices.first.id,
            );
            if (bisiklet) bisikletSonucu = sonuc;
          } else {
            controller.ageUp();
          }
        }
      }

      expect(bisikletSonucu, isNotNull, reason: 'Bisiklet olayı çıkmalı');
      final List<String> metinler =
          bisikletSonucu!.effects.map((AppliedEffect e) => e.text).toList();
      expect(metinler, contains('${possessionName('bisiklet')} kazanıldı'));
      expect(
        metinler.any((String t) => t.startsWith('Mutluluk +')),
        isTrue,
        reason: 'Mutluluk artışı bildirilmeli',
      );
      expect(
        metinler.any((String t) => t.contains('ile yakınlık +')),
        isTrue,
        reason: 'Yakınlık artışı kimle olduğu yazılarak bildirilmeli',
      );
    });

    test('tavana dayanmış değer için sahte kazanç gösterilmez', () {
      final GameState state =
          LifeGenerator.seeded(7).generate(mode: StartMode.tamamenRastgele);
      final GameState tavanda = state.copyWith(
        player: state.player.copyWith(
          stats: state.player.stats.copyWith(happiness: 100),
        ),
      );
      // Mutluluk 100'de: artış uygulanamaz, dolayısıyla listelenmez.
      final GameState sonra = tavanda.copyWith(
        player: tavanda.player.copyWith(
          stats: tavanda.player.stats.copyWith(happiness: 100 + 6),
        ),
      );
      final List<AppliedEffect> etkiler = diffAppliedEffects(tavanda, sonra);
      expect(
        etkiler.any((AppliedEffect e) => e.label == 'Mutluluk'),
        isFalse,
        reason: 'Uygulanmayan kazanç ekrana yazılmaz',
      );
    });

    test('olumsuz etki ve para kaybı eksi işaretiyle bildirilir', () {
      final GameState state =
          LifeGenerator.seeded(9).generate(mode: StartMode.tamamenRastgele);
      final GameState zengin =
          state.copyWith(player: state.player.copyWith(wallet: 500));
      final GameState sonra = zengin.copyWith(
        player: zengin.player.copyWith(
          wallet: 450,
          stats: zengin.player.stats.copyWith(
            happiness: zengin.player.stats.happiness - 3,
          ),
        ),
      );
      final List<String> metinler =
          diffAppliedEffects(zengin, sonra).map((AppliedEffect e) => e.text).toList();
      expect(metinler, contains('Cüzdan -50 ₺'));
      expect(metinler, contains('Mutluluk -3'));
    });
  });

  // ======================================================================
  // 3) Olay tekrarı
  // ======================================================================
  group('Olay tekrar aralığı', () {
    test('tekrarlanabilir olay aralık dolmadan yeniden çıkmaz', () {
      final GameEvent bayram = eventById('bayram_ziyareti');
      expect(bayram.repeatable, isTrue);
      expect(bayram.minAgeGap, greaterThan(1));

      final EventEngine engine = EventEngine(pool: <GameEvent>[bayram]);
      final GameState state =
          LifeGenerator.seeded(1).generate(mode: StartMode.tamamenRastgele);
      GameState oyun = state.copyWith(player: state.player.copyWith(age: 10));

      final ActiveEvent? ilk = engine.openingEvent(oyun, Random(1));
      expect(ilk, isNotNull);
      oyun = engine.resolve(oyun.copyWith(pendingEvent: ilk), 'kal');
      expect(oyun.lastEventAge['bayram_ziyareti'], 10);

      for (int yas = 11; yas < 10 + bayram.minAgeGap; yas++) {
        final GameState ara =
            oyun.copyWith(player: oyun.player.copyWith(age: yas));
        expect(engine.openingEvent(ara, Random(yas)), isNull,
            reason: '$yas yaşında tekrar erken');
      }

      final GameState sonra = oyun.copyWith(
        player: oyun.player.copyWith(age: 10 + bayram.minAgeGap),
      );
      expect(engine.openingEvent(sonra, Random(1)), isNotNull,
          reason: 'Aralık dolunca doğal tekrar yeniden mümkün olmalı');
    });

    test('gerçek oyunda hiçbir olay kendi aralığından erken tekrarlamaz', () {
      for (int seed = 0; seed < 12; seed++) {
        final GameController controller = GameController(random: Random(seed));
        controller.startNewLife(mode: StartMode.tamamenRastgele, seed: seed);
        final Map<String, int> sonGoruldu = <String, int>{};

        for (int i = 0; i < 160; i++) {
          final GameState state = controller.state!;
          if (!state.hasPendingEvent) {
            controller.ageUp();
            continue;
          }
          final String id = state.pendingEvent!.eventId;
          final int yas = state.player.age;
          final int? once = sonGoruldu[id];
          if (once != null) {
            final GameEvent tanim = eventById(id);
            expect(tanim.repeatable, isTrue,
                reason: '$id tekrarlanabilir değilken tekrar çıktı');
            expect(yas - once, greaterThanOrEqualTo(tanim.minAgeGap),
                reason: '$id, $once yaşından sonra $yas yaşında erken '
                    'tekrarladı (aralık ${tanim.minAgeGap})');
          }
          sonGoruldu[id] = yas;
          controller.chooseEventOption(state.pendingEvent!.choices.first.id);
        }
      }
    });
  });

  // ======================================================================
  // 4) Okul kişileri
  // ======================================================================
  group('Okul kişileri', () {
    test('okula başlayınca sınıf arkadaşları ve öğretmen oluşur', () {
      final GameController controller = GameController(random: Random(21));
      controller.startNewLife(mode: StartMode.tamamenRastgele, seed: 21);
      advanceToAge(controller, LifeProgression.prototypeOnlySchoolStartAge);

      final GameState state = controller.state!;
      // Kademeye bağlı kişi sayısı: sınıf arkadaşları + öğretmen. Açılış
      // olayı bir sınıf arkadaşını yakın arkadaşa çevirmiş olabilir; kayıt
      // yine aynı kademeye ait kalır.
      final List<Person> ilkokulKisileri = state.people
          .where((Person p) => p.schoolLevel == SchoolLevel.ilkokul)
          .toList(growable: false);
      expect(
        ilkokulKisileri.length,
        SchoolPeople.prototypeOnlyClassmateCount + 1,
      );
      expect(state.currentTeachers.length, 1);
      expect(state.currentClassmates, isNotEmpty);
      for (final Person p in state.currentClassmates) {
        expect(p.schoolLevel, SchoolLevel.ilkokul);
        // Sınıf listesi okul bağına bakar; yakınlık derecesi değişebilir.
        expect(p.schoolTie, SchoolTie.sinifArkadasi);
        expect(p.relation.kanBagi, isFalse);
        expect(p.inPlayerHousehold, isFalse);
        // Henüz yakınlaşılmamış sınıf arkadaşı tanışıklık düzeyinde kalır:
        // sınıf arkadaşı olmak yakın arkadaşlık değildir.
        if (p.relation == RelationType.sinifArkadasi) {
          expect(p.bond, lessThan(50));
        }
      }
      final Person ogretmen = state.currentTeachers.single;
      expect(ogretmen.occupation, 'öğretmen');
      expect(ogretmen.age, greaterThan(state.player.age));
    });

    test('kademe değişince eski kişiler silinmez, güncel listede görünmez', () {
      final GameController controller = GameController(random: Random(22));
      controller.startNewLife(mode: StartMode.tamamenRastgele, seed: 22);
      advanceToAge(controller, LifeProgression.prototypeOnlySchoolStartAge);
      resolvePendingEvents(controller);

      final List<String> ilkokulKimlikleri = controller.state!.currentClassmates
          .map((Person p) => p.id)
          .toList(growable: false);
      expect(ilkokulKimlikleri, isNotEmpty);

      // 5. sınıf: ortaokul.
      advanceToAge(controller, LifeProgression.prototypeOnlySchoolStartAge + 4);
      final GameState state = controller.state!;
      expect(state.education.level, SchoolLevel.ortaokul);

      // Hiçbir kayıt silinmez.
      for (final String id in ilkokulKimlikleri) {
        expect(state.personById(id), isNotNull, reason: 'Kayıt silinmemeli');
      }

      final Set<String> guncel =
          state.currentClassmates.map((Person p) => p.id).toSet();
      final Set<String> gecmis =
          state.pastSchoolPeople.map((Person p) => p.id).toSet();

      // Bir bölümü aynı kimlikle yeni sınıfa taşınır, geri kalanı eski
      // sınıfta kayıtlı kalır. Her sınıf değişiminde herkes değişmez.
      final Set<String> tasinan = ilkokulKimlikleri.toSet().intersection(guncel);
      final Set<String> kalan = ilkokulKimlikleri.toSet().difference(guncel);
      expect(tasinan, isNotEmpty,
          reason: 'Bazı arkadaşlar yeni sınıfa birlikte geçmeli');
      expect(kalan, isNotEmpty, reason: 'Bazıları eski sınıfta kalmalı');
      expect(gecmis, containsAll(kalan),
          reason: 'Eski sınıfta kalanlar geçmiş tanıdıklar arasında olmalı');
      for (final String id in tasinan) {
        expect(state.personById(id)!.schoolLevel, SchoolLevel.ortaokul,
            reason: 'Taşınan kişi aynı kimlikle yeni sınıfta olmalı');
      }
    });

    test('aynı kademede ikinci kez kişi üretilmez', () {
      final GameController controller = GameController(random: Random(23));
      controller.startNewLife(mode: StartMode.tamamenRastgele, seed: 23);
      advanceToAge(controller, LifeProgression.prototypeOnlySchoolStartAge);
      final int ilk = controller.state!.currentClassmates.length;
      // 2, 3 ve 4. sınıflar aynı kademede.
      advanceToAge(controller, LifeProgression.prototypeOnlySchoolStartAge + 3);
      expect(controller.state!.currentClassmates.length, ilk);
    });

    test('tanışma olayı var olan sınıf arkadaşını aynı kimlikle yakınlaştırır',
        () {
      final EventEngine engine =
          EventEngine(pool: <GameEvent>[eventById('okul_sira_arkadasi')]);
      final GameState state = studentAt(seed: 15, age: 8, grade: 3);
      final ActiveEvent? olay = engine.openingEvent(state, Random(15));
      expect(olay, isNotNull);
      final Person once = state.personById(olay!.personId!)!;
      expect(once.relation, RelationType.sinifArkadasi);

      final int kisiSayisiOnce = state.people.length;
      final GameState sonra = engine.resolve(
        state.copyWith(pendingEvent: olay),
        'tanis',
        rng: Random(15),
      );

      final Person arkadas = sonra.personById(once.id)!;
      expect(sonra.people.length, kisiSayisiOnce,
          reason: 'Yeni NPC üretilmemeli, var olan kişi yakınlaşmalı');
      expect(arkadas.relation, RelationType.arkadas);
      expect(arkadas.firstName, once.firstName);
      expect(arkadas.bond, greaterThan(once.bond));
      expect(arkadas.schoolLevel, once.schoolLevel,
          reason: 'Nerede tanışıldığı unutulmaz');
    });
  });

  // ======================================================================
  // 5) Hediye ve para etkileşimleri
  // ======================================================================
  group('Hediye ve para etkileşimleri', () {
    const FamilyInteractions interactions = FamilyInteractions();

    GameState aileli(int seed, {int age = 12, int wallet = 0}) {
      final GameState state =
          LifeGenerator.seeded(seed).generate(mode: StartMode.tamamenRastgele);
      return state.copyWith(
        player: state.player.copyWith(age: age, wallet: wallet),
      );
    }

    Person yetiskinYakin(GameState state) => state.people.firstWhere(
          (Person p) =>
              p.isAlive &&
              p.age >= 18 &&
              (p.relation == RelationType.anne ||
                  p.relation == RelationType.baba),
        );

    test('parası olmayan oyuncuya hediye verme eylemi açılmaz', () {
      final GameState state = aileli(31);
      final Person anne = yetiskinYakin(state);
      expect(state.player.wallet, 0);

      final InteractionAvailability uygunluk = interactions.availability(
        state,
        anne,
        InteractionKind.hediyeVer,
      );
      expect(uygunluk.isAllowed, isFalse);
      expect(uygunluk.reason, contains('paran yok'));
      expect(
        interactions.availableKinds(state, anne),
        isNot(contains(InteractionKind.hediyeVer)),
      );
    });

    test('hediye bedeli oyuncunun kendi cüzdanından düşer', () {
      final GameState state = aileli(32, wallet: 300);
      final Person anne = yetiskinYakin(state);
      final InteractionResult sonuc = interactions.perform(
        state: state,
        personId: anne.id,
        kind: InteractionKind.hediyeVer,
        rng: Random(1),
      );

      expect(sonuc.outcome.accepted, isTrue);
      // Hediyenin bedeli katalogdan gelir; sabit değildir.
      final String verilen = sonuc.outcome.givenPossession!;
      final GiftItem hediye = giftById(verilen)!;
      expect(sonuc.state.player.wallet, 300 - hediye.value);
      expect(sonuc.state.personById(anne.id)!.bond, greaterThan(anne.bond));
      expect(
        sonuc.outcome.effects.map((AppliedEffect e) => e.text),
        contains('Cüzdan -${hediye.value} ₺'),
      );
      // Hediyenin adı sonuç metninde geçer.
      expect(sonuc.outcome.text.toLowerCase(),
          contains(hediye.name.toLowerCase()));
      // Verilen hediye oyuncunun envanterine girmez; karşı tarafa geçer.
      expect(sonuc.state.possessions, isNot(contains(verilen)));
      expect(
        sonuc.state.gifts.any((GiftRecord g) =>
            g.itemId == verilen &&
            g.fromId == GiftRecord.playerId &&
            g.toId == anne.id),
        isTrue,
        reason: 'Kim kime ne verdi kaydedilmeli',
      );
    });

    test('kendi parası olmayan kişiden para istenemez', () {
      final GameState state = aileli(33);
      final Person kardes = Person(
        id: 'kardes-test',
        firstName: 'Deniz',
        lastName: state.player.lastName,
        gender: Gender.kadin,
        relation: RelationType.kardes,
        age: 10,
        isAlive: true,
        inPlayerHousehold: true,
        employment: EmploymentStatus.ogrenci,
        wealth: null,
        bond: 80,
      );
      final GameState ekli = state.copyWith(
        people: <Person>[...state.people, kardes],
      );
      expect(
        interactions
            .availability(ekli, kardes, InteractionKind.paraIste)
            .isAllowed,
        isFalse,
      );
    });

    test('istenen para cüzdana girer ve kişinin servetini boşaltmaz', () {
      final GameState state = aileli(34);
      final Person anne = yetiskinYakin(state);
      final GameState hazir = state.copyWith(
        people: state.people
            .map((Person p) => p.id == anne.id
                ? p.copyWith(bond: 90, wealth: WealthTier.ortaHalli)
                : p)
            .toList(growable: false),
      );
      final Person hedef = hazir.personById(anne.id)!;

      final InteractionResult sonuc = interactions.perform(
        state: hazir,
        personId: hedef.id,
        kind: InteractionKind.paraIste,
        rng: Random(2),
      );

      if (sonuc.outcome.accepted) {
        final int alinan = sonuc.state.player.wallet;
        expect(alinan, greaterThan(0));
        expect(
          alinan,
          lessThanOrEqualTo(
            FamilyInteractions
                .prototypeOnlyAllowanceByWealth[WealthTier.ortaHalli]!,
          ),
        );
        // Karşı tarafın ekonomik basamağı oyuncunun parası değildir.
        expect(sonuc.state.personById(hedef.id)!.wealth, hedef.wealth);
      } else {
        // Reddedildiyse para hareket etmez.
        expect(sonuc.state.player.wallet, 0);
        expect(
          sonuc.outcome.effects
              .any((AppliedEffect e) => e.label == 'Cüzdan'),
          isFalse,
        );
      }
    });

    test('istenen hediye gerçek bir eşya olarak kaydedilir', () {
      final GameState state = aileli(35);
      final Person anne = yetiskinYakin(state);
      final GameState hazir = state.copyWith(
        people: state.people
            .map((Person p) => p.id == anne.id ? p.copyWith(bond: 95) : p)
            .toList(growable: false),
      );

      GameState oyun = hazir;
      bool alindiMi = false;
      for (int i = 0; i < 6 && !alindiMi; i++) {
        final InteractionResult sonuc = interactions.perform(
          state: oyun,
          personId: anne.id,
          kind: InteractionKind.hediyeIste,
          rng: Random(40 + i),
        );
        oyun = sonuc.state;
        if (sonuc.outcome.gainedPossession != null) {
          alindiMi = true;
          final String id = sonuc.outcome.gainedPossession!;
          expect(oyun.possessions, contains(id));
          expect(
            sonuc.outcome.effects.map((AppliedEffect e) => e.text),
            contains('${possessionName(id)} kazanıldı'),
          );
          // Ne hediye edildiği metinde açıkça yazar.
          expect(sonuc.outcome.text.toLowerCase(),
              contains(giftById(id)!.name.toLowerCase()));
          // Hediye yaşa uygun olmalı.
          expect(giftById(id)!.fitsAge(oyun.player.age), isTrue);
          expect(
            oyun.gifts.any((GiftRecord g) =>
                g.itemId == id &&
                g.fromId == anne.id &&
                g.toId == GiftRecord.playerId),
            isTrue,
          );
        } else {
          // Alınmadıysa eşya listesi büyümez.
          expect(oyun.possessions, hazir.possessions);
        }
      }
      expect(alindiMi, isTrue, reason: 'Yakın bir anneden hediye alınabilmeli');
    });

    test('verilecek hediye kalmadıysa eylem hiç sunulmaz', () {
      final GameState temel = aileli(36);
      final Person anne = yetiskinYakin(temel);
      // Yaşına ve annenin ekonomik durumuna uyan her hediyeye zaten sahip.
      final Set<String> hepsi = giftsFor(
        receiverAge: temel.player.age,
        giverWealth: anne.wealth,
      ).map((GiftItem g) => g.id).toSet();
      expect(hepsi, isNotEmpty);

      final GameState hazir = temel
          .copyWith(
            people: temel.people
                .map((Person p) => p.id == anne.id ? p.copyWith(bond: 95) : p)
                .toList(growable: false),
          )
          .grantItems(hepsi, source: ItemSource.hediye);
      expect(
        interactions
            .availability(hazir, hazir.personById(anne.id)!,
                InteractionKind.hediyeIste)
            .isAllowed,
        isFalse,
      );
    });

    test('aynı yaşta tekrarlanan istek boşuna para harcatmaz', () {
      GameState oyun = aileli(37, wallet: 1000);
      final Person anne = yetiskinYakin(oyun);

      int sonCuzdan = oyun.player.wallet;
      int harcamaSayisi = 0;
      for (int i = 0; i < 8; i++) {
        final InteractionResult sonuc = interactions.perform(
          state: oyun,
          personId: anne.id,
          kind: InteractionKind.hediyeVer,
          rng: Random(50 + i),
        );
        oyun = sonuc.state;
        final int harcanan = sonCuzdan - oyun.player.wallet;
        if (harcanan == 0) {
          // Fayda bittiğinde hiçbir şey gösterilmez ve para gitmez.
          expect(sonuc.outcome.effects, isEmpty);
          expect(sonuc.outcome.givenPossession, isNull);
        } else {
          harcamaSayisi++;
          expect(harcanan, giftById(sonuc.outcome.givenPossession!)!.value,
              reason: 'Harcanan tutar hediyenin bedeli olmalı');
        }
        sonCuzdan = oyun.player.wallet;
      }

      // Sınırsız tekrar cüzdanı boşaltmaz: azalan etki kuralı hediye
      // vermeyi de sınırlar.
      expect(
        harcamaSayisi,
        lessThan(FamilyInteractions.prototypeOnlyRewardCurve.length),
      );
    });

    test('yakınlığı düşük kişiden hediye veya para istenemez', () {
      final GameState state = aileli(38);
      final Person anne = yetiskinYakin(state);
      final GameState uzak = state.copyWith(
        people: state.people
            .map((Person p) => p.id == anne.id ? p.copyWith(bond: 5) : p)
            .toList(growable: false),
      );
      final Person hedef = uzak.personById(anne.id)!;
      expect(
        interactions.availability(uzak, hedef, InteractionKind.hediyeIste).isAllowed,
        isFalse,
      );
      expect(
        interactions.availability(uzak, hedef, InteractionKind.paraIste).isAllowed,
        isFalse,
      );
    });

    test('vakit geçirme ve sohbet eskisi gibi çalışır', () {
      final GameState state = aileli(39);
      final Person anne = yetiskinYakin(state);
      expect(
        interactions.availableKinds(state, anne),
        containsAll(<InteractionKind>[
          InteractionKind.vakitGecir,
          InteractionKind.sohbet,
        ]),
      );
    });
  });
}

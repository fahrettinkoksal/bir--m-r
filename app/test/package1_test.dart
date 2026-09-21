import 'dart:convert';
import 'dart:math';

import 'package:bir_omur/app.dart';
import 'package:bir_omur/data/event_pool.dart';
import 'package:bir_omur/data/gift_catalog.dart';
import 'package:bir_omur/data/save/game_state_codec.dart';
import 'package:bir_omur/data/save/save_format.dart';
import 'package:bir_omur/data/save/save_service.dart';
import 'package:bir_omur/data/save/save_store.dart';
import 'package:bir_omur/domain/generation/life_generator.dart';
import 'package:bir_omur/domain/generation/life_progression.dart';
import 'package:bir_omur/domain/generation/school_people.dart';
import 'package:bir_omur/domain/interaction/family_interactions.dart';
import 'package:bir_omur/domain/interaction/friendship.dart';
import 'package:bir_omur/domain/interaction/interaction_policy.dart';
import 'package:bir_omur/domain/models/education.dart';
import 'package:bir_omur/domain/models/game_event.dart';
import 'package:bir_omur/domain/models/game_state.dart';
import 'package:bir_omur/domain/models/gift_record.dart';
import 'package:bir_omur/domain/models/interaction.dart';
import 'package:bir_omur/domain/models/person.dart';
import 'package:bir_omur/domain/models/relation.dart';
import 'package:bir_omur/domain/models/wealth.dart';
import 'package:bir_omur/state/game_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/test_flow.dart';

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

GameController schoolAged(int seed, {int? untilAge}) {
  final GameController controller = GameController(random: Random(seed));
  controller.startNewLife(mode: StartMode.tamamenRastgele, seed: seed);
  advanceToAge(
    controller,
    untilAge ?? LifeProgression.prototypeOnlySchoolStartAge,
  );
  resolvePendingEvents(controller);
  return controller;
}

void main() {
  // ===================================================================
  // 1) Sınıf mevcudu ve okul geçişleri
  // ===================================================================
  group('Sınıf arkadaşları', () {
    test('oyuncu hariç en az on sınıf arkadaşı bulunur', () {
      expect(SchoolPeople.prototypeOnlyClassmateCount, greaterThanOrEqualTo(10));
      for (int seed = 0; seed < 8; seed++) {
        final GameController c = schoolAged(seed);
        expect(
          c.state!.currentClassmates.length,
          greaterThanOrEqualTo(10),
          reason: 'seed=$seed sınıf mevcudu yetersiz',
        );
        expect(c.state!.currentTeachers, isNotEmpty);
      }
    });

    test('sınıf arkadaşları kalıcı ve benzersiz kimlikli gerçek kayıtlardır',
        () {
      final GameController c = schoolAged(4);
      final List<Person> sinif = c.state!.currentClassmates;
      final Set<String> ids = sinif.map((Person p) => p.id).toSet();
      expect(ids.length, sinif.length);
      for (final Person p in sinif) {
        expect(p.firstName, isNotEmpty);
        expect(p.lastName, isNotEmpty);
        expect(p.schoolTie, SchoolTie.sinifArkadasi);
        expect(p.classId, c.state!.education.classId);
        expect(p.schoolId, c.state!.education.schoolId);
      }
      // Sınıf listesi okul bağına dayanır: yakınlık derecesi değişse bile
      // kişi sınıfta kalır, ama sınıfa alakasız bir bağ (akraba, sevgili)
      // sızmaz.
      expect(
        sinif.every((Person p) =>
            p.relation == RelationType.sinifArkadasi ||
            p.relation == RelationType.arkadas),
        isTrue,
      );
      // Hepsi kendiliğinden yakın arkadaşa dönüşmez.
      expect(
        sinif.where((Person p) => p.relation == RelationType.arkadas).length,
        lessThan(sinif.length),
      );
    });

    test('yakın arkadaş olan kişi sınıf arkadaşlığını korur', () {
      final GameController c = schoolAged(6);
      final Person aday = c.state!.currentClassmates.first;
      final GameState sonra =
          const Friendship().promoteToFriend(c.state!, aday.id).state;

      expect(sonra.currentClassmates.map((Person p) => p.id),
          contains(aday.id));
      expect(sonra.personById(aday.id)!.relation, RelationType.arkadas);
      expect(sonra.personById(aday.id)!.schoolTie, SchoolTie.sinifArkadasi);
      expect(sonra.people.length, c.state!.people.length,
          reason: 'İkinci NPC üretilmemeli');
    });

    test('kademe geçişinde bir bölüm arkadaş taşınır, kalanı silinmez', () {
      final GameController c = schoolAged(9);
      final Set<String> ilkokul = c.state!.currentClassmates
          .map((Person p) => p.id)
          .toSet();
      final String ilkSinif = c.state!.education.classId!;

      advanceToAge(c, LifeProgression.prototypeOnlySchoolStartAge + 4);
      resolvePendingEvents(c);
      final GameState state = c.state!;

      expect(state.education.level, SchoolLevel.ortaokul);
      expect(state.education.classId, isNot(ilkSinif));

      // Yeni sınıf **her zaman** tam mevcuda tamamlanır: taşınanlar +
      // yeni üretilenler. Aralarında o yıl vefat eden biri olabilir;
      // `currentClassmates` yalnızca yaşayanları verdiği için ona bakan
      // bir sayım tohuma göre 9 da çıkabilir (Paket 23'te görüldü).
      final int siniftakiler = state.people
          .where((Person p) =>
              p.schoolTie == SchoolTie.sinifArkadasi &&
              p.classId == state.education.classId)
          .length;
      expect(siniftakiler, SchoolPeople.prototypeOnlyClassmateCount);
      expect(state.currentClassmates, isNotEmpty);
      expect(
        state.currentClassmates.length,
        lessThanOrEqualTo(SchoolPeople.prototypeOnlyClassmateCount),
      );

      final Set<String> guncel =
          state.currentClassmates.map((Person p) => p.id).toSet();
      expect(ilkokul.intersection(guncel), isNotEmpty,
          reason: 'Bazı arkadaşlar birlikte devam etmeli');
      expect(ilkokul.difference(guncel), isNotEmpty,
          reason: 'Herkes zorunlu olarak taşınmamalı');
      for (final String id in ilkokul) {
        expect(state.personById(id), isNotNull, reason: 'Kayıt silinmez');
      }
      // Eski sınıfta kalanlar geçmiş tanıdıklar arasında bulunur.
      expect(
        state.pastSchoolPeople.map((Person p) => p.id).toSet(),
        containsAll(ilkokul.difference(guncel)),
      );
    });

    test('aynı kademede sınıf yeniden kurulmaz', () {
      final GameController c = schoolAged(10);
      final Set<String> once =
          c.state!.currentClassmates.map((Person p) => p.id).toSet();
      advanceToAge(c, LifeProgression.prototypeOnlySchoolStartAge + 3);
      resolvePendingEvents(c);
      expect(c.state!.currentClassmates.map((Person p) => p.id).toSet(), once);
    });

    test('kişi kimlikleri hiçbir zaman çakışmaz', () {
      for (int seed = 0; seed < 10; seed++) {
        final GameController c = GameController(random: Random(seed));
        c.startNewLife(mode: StartMode.tamamenRastgele, seed: seed);
        for (int i = 0; i < 20; i++) {
          resolvePendingEvents(c);
          c.ageUp();
          final List<String> ids =
              c.state!.people.map((Person p) => p.id).toList();
          expect(ids.toSet().length, ids.length, reason: 'seed=$seed');
        }
      }
    });
  });

  // ===================================================================
  // 2) Hane bilgisi
  // ===================================================================
  group('Hane bilgisi', () {
    test('tanışıklık veya arkadaşlık kimseyi haneye eklemez', () {
      for (int seed = 0; seed < 20; seed++) {
        final GameController c = GameController(random: Random(seed));
        c.startNewLife(mode: StartMode.tamamenRastgele, seed: seed);
        for (int i = 0; i < 20; i++) {
          resolvePendingEvents(c);
          c.ageUp();
          for (final Person p in c.state!.people) {
            if (p.schoolTie != null) {
              expect(p.inPlayerHousehold, isFalse,
                  reason: 'Okul kişisi hanede görünmemeli: ${p.id}');
            }
            if (p.relation == RelationType.arkadas ||
                p.relation == RelationType.sevgili ||
                p.relation == RelationType.eskiSevgili ||
                p.relation == RelationType.ogretmen) {
              expect(p.inPlayerHousehold, isFalse,
                  reason: '${p.relation.name} hanede görünmemeli: ${p.id}');
            }
          }
        }
      }
    });

    test('yakın arkadaşlığa yükselme hane bilgisini değiştirmez', () {
      final GameController c = schoolAged(11);
      final Person aday = c.state!.currentClassmates.first;
      expect(aday.inPlayerHousehold, isFalse);
      final GameState sonra =
          const Friendship().promoteToFriend(c.state!, aday.id).state;
      expect(sonra.personById(aday.id)!.inPlayerHousehold, isFalse);
    });

    test('gerçekten aynı evde yaşayan kişiler ayrı eve taşınmaz', () {
      for (int seed = 0; seed < 20; seed++) {
        final GameState state =
            LifeGenerator.seeded(seed).generate(mode: StartMode.tamamenRastgele);
        expect(state.household, isNotEmpty,
            reason: 'Yeni doğan çocuk yalnız yaşamaz');
        // Hanedekilerin tamamı akraba olmalı; okul kişisi haneye girmez.
        for (final Person p in state.household) {
          expect(p.schoolTie, isNull);
        }
      }
    });

    testWidgets('kişi kartında hane bilgisi doğru yazılır',
        (WidgetTester tester) async {
      final GameController controller = GameController(random: Random(12));
      await tester.pumpWidget(BirOmurApp(controller: controller));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Rastgele bir hayat'));
      await tester.pumpAndSettle();
      await answerPendingEvents(tester, controller);
      await ageTo(tester, controller, 8);

      final Person anne = controller.state!.people
          .firstWhere((Person p) => p.relation == RelationType.anne);
      final String beklenen = anne.inPlayerHousehold
          ? 'Seninle aynı evde yaşıyor'
          : 'Ayrı evde yaşıyor';

      await tester.tap(find.byKey(const Key('tab_iliskiler')));
      await tester.pumpAndSettle();
      await tester.tap(find.text(anne.fullName).first);
      await tester.pumpAndSettle();
      expect(find.text(beklenen), findsOneWidget);
    });
  });

  // ===================================================================
  // 3) Kişiye uygun etkileşimler
  // ===================================================================
  group('Etkileşim uygunluğu', () {
    const FamilyInteractions interactions = FamilyInteractions();

    test('okul arkadaşında para/hediye isteme hiç sunulmaz', () {
      final GameController c = schoolAged(13, untilAge: 12);
      final Person sinifArkadasi = c.state!.currentClassmates.first;
      final List<InteractionKind> kinds =
          interactions.availableKinds(c.state!, sinifArkadasi);

      expect(kinds, isNot(contains(InteractionKind.paraIste)));
      expect(kinds, isNot(contains(InteractionKind.hediyeIste)));
      expect(kinds, contains(InteractionKind.vakitGecir));
      expect(kinds, contains(InteractionKind.sohbet));
    });

    test('öğretmenle vakit geçirme sunulmaz', () {
      final GameController c = schoolAged(14, untilAge: 12);
      final Person ogretmen = c.state!.currentTeachers.first;
      final Set<InteractionKind> anlamli =
          meaningfulKindsFor(ogretmen.relation);
      expect(anlamli, isNot(contains(InteractionKind.vakitGecir)));
      expect(anlamli, isNot(contains(InteractionKind.paraIste)));
      expect(anlamli, contains(InteractionKind.sohbet));
    });

    test('anne ve babada aile etkileşimleri anlamlıdır', () {
      for (final RelationType r in <RelationType>[
        RelationType.anne,
        RelationType.baba,
      ]) {
        final Set<InteractionKind> anlamli = meaningfulKindsFor(r);
        expect(
          anlamli,
          containsAll(<InteractionKind>[
            InteractionKind.vakitGecir,
            InteractionKind.sohbet,
            InteractionKind.hediyeVer,
            InteractionKind.hediyeIste,
            InteractionKind.paraIste,
          ]),
        );
      }
    });

    testWidgets('kişi kartında kilitli etkileşim satırı gösterilmez',
        (WidgetTester tester) async {
      final GameController controller = GameController(random: Random(15));
      await tester.pumpWidget(BirOmurApp(controller: controller));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Rastgele bir hayat'));
      await tester.pumpAndSettle();
      await answerPendingEvents(tester, controller);
      await ageTo(tester, controller, 10);

      await tester.tap(find.byKey(const Key('tab_okul_meslek')));
      await tester.pumpAndSettle();
      await tapMenuRow(tester, 'Sınıf Arkadaşları');

      final Person sinifArkadasi = controller.state!.currentClassmates.first;
      await tester.tap(find.text(sinifArkadasi.fullName).first);
      await tester.pumpAndSettle();

      expect(find.textContaining('Para İste:'), findsNothing);
      expect(find.textContaining('isteyebileceğin biri değil'), findsNothing);
      expect(find.text('Vakit Geçir'), findsOneWidget);
    });
  });

  // ===================================================================
  // 4) Erişilebilirlik
  // ===================================================================
  group('Gündelik erişilebilirlik', () {
    test('eski öğretmen gündelik listeye girmez, kaydı silinmez', () {
      final GameController c = schoolAged(16);
      final Person ilkokulOgretmeni = c.state!.currentTeachers.first;
      expect(c.state!.isReachable(ilkokulOgretmeni), isTrue);

      advanceToAge(c, LifeProgression.prototypeOnlySchoolStartAge + 6);
      resolvePendingEvents(c);
      final GameState state = c.state!;
      expect(state.education.level, SchoolLevel.ortaokul);

      expect(state.personById(ilkokulOgretmeni.id), isNotNull,
          reason: 'Kayıt korunur');
      expect(state.isReachable(state.personById(ilkokulOgretmeni.id)!), isFalse,
          reason: 'Eski öğretmen her gün görüşülen biri değildir');
      expect(
        state.reachablePeople.map((Person p) => p.id),
        isNot(contains(ilkokulOgretmeni.id)),
      );
    });

    test('güncel okul çevresi ve hane erişilebilirdir', () {
      final GameController c = schoolAged(17, untilAge: 10);
      final GameState state = c.state!;
      for (final Person p in state.currentClassmates) {
        expect(state.isReachable(p), isTrue);
      }
      for (final Person p in state.currentTeachers) {
        expect(state.isReachable(p), isTrue);
      }
      for (final Person p in state.household) {
        expect(state.isReachable(p), isTrue);
      }
    });

    test('yakın arkadaş okul bitse de erişilebilir kalır', () {
      final GameController c = schoolAged(18);
      final Person aday = c.state!.currentClassmates.first;
      GameState state = const Friendship().promoteToFriend(c.state!, aday.id).state;
      // Okulu bitirmiş gibi davran.
      state = state.copyWith(education: state.education.asFinished());
      expect(state.isReachable(state.personById(aday.id)!), isTrue);
    });
  });

  // ===================================================================
  // 5) Hediye sistemi
  // ===================================================================
  group('Hediye sistemi', () {
    const FamilyInteractions interactions = FamilyInteractions();

    GameState aileli(int seed, {int age = 10, int wallet = 0}) {
      final GameState state =
          LifeGenerator.seeded(seed).generate(mode: StartMode.tamamenRastgele);
      return state.copyWith(
        player: state.player.copyWith(age: age, wallet: wallet),
      );
    }

    Person anneOf(GameState state) => state.people.firstWhere(
          (Person p) => p.relation == RelationType.anne && p.isAlive,
        );

    test('istenen hediye gerçek bir eşyadır ve adı metinde geçer', () {
      final GameState temel = aileli(21, age: 6);
      final Person anne = anneOf(temel);
      final GameState hazir = temel.copyWith(
        people: temel.people
            .map((Person p) => p.id == anne.id
                ? p.copyWith(bond: 95, wealth: WealthTier.ortaHalli)
                : p)
            .toList(growable: false),
      );

      InteractionResult? basarili;
      GameState oyun = hazir;
      for (int i = 0; i < 6 && basarili == null; i++) {
        final InteractionResult r = interactions.perform(
          state: oyun,
          personId: anne.id,
          kind: InteractionKind.hediyeIste,
          rng: Random(60 + i),
        );
        oyun = r.state;
        if (r.outcome.gainedPossession != null) basarili = r;
      }
      expect(basarili, isNotNull);

      final String id = basarili!.outcome.gainedPossession!;
      final GiftItem hediye = giftById(id)!;
      expect(oyun.possessions, contains(id), reason: 'Envantere girmeli');
      expect(hediye.fitsAge(6), isTrue, reason: 'Yaşa uygun olmalı');
      expect(basarili.outcome.text.toLowerCase(),
          contains(hediye.name.toLowerCase()));
      expect(
        oyun.gifts.any((GiftRecord g) =>
            g.itemId == id &&
            g.fromId == anne.id &&
            g.toId == GiftRecord.playerId &&
            g.age == 6),
        isTrue,
        reason: 'Veren, alan ve eşya kaydedilmeli',
      );
    });

    test('reddedilen istekte eşya kazanılmış gösterilmez', () {
      final GameState temel = aileli(22, age: 8);
      final Person anne = anneOf(temel);
      GameState oyun = temel.copyWith(
        people: temel.people
            .map((Person p) => p.id == anne.id
                ? p.copyWith(bond: 95, wealth: WealthTier.ortaHalli)
                : p)
            .toList(growable: false),
      );

      bool redGorulduMu = false;
      for (int i = 0; i < 12; i++) {
        final InteractionResult r = interactions.perform(
          state: oyun,
          personId: anne.id,
          kind: InteractionKind.hediyeIste,
          rng: Random(70 + i),
        );
        if (!r.outcome.accepted) {
          redGorulduMu = true;
          expect(r.outcome.gainedPossession, isNull);
          expect(r.state.possessions, oyun.possessions,
              reason: 'Ret sonrası envanter değişmemeli');
          expect(
            r.outcome.effects.any((dynamic e) =>
                (e.label as String).contains('kazanıldı')),
            isFalse,
          );
        }
        oyun = r.state;
      }
      expect(redGorulduMu, isTrue, reason: 'Sık tekrarda ret görülmeli');
    });

    test('çok yoksul kişi pahalı hediye vermez', () {
      final GameState temel = aileli(23, age: 14);
      final Person anne = anneOf(temel);
      GameState oyun = temel.copyWith(
        people: temel.people
            .map((Person p) => p.id == anne.id
                ? p.copyWith(bond: 95, wealth: WealthTier.cokYoksul)
                : p)
            .toList(growable: false),
      );

      for (int i = 0; i < 8; i++) {
        final InteractionResult r = interactions.perform(
          state: oyun,
          personId: anne.id,
          kind: InteractionKind.hediyeIste,
          rng: Random(80 + i),
        );
        final String? id = r.outcome.gainedPossession;
        if (id != null) {
          expect(giftById(id)!.minGiverWealth, WealthTier.cokYoksul,
              reason: 'Yoksul aile gerekçesiz pahalı hediye vermez');
        }
        oyun = r.state;
      }
    });

    test('verilen hediye cüzdandan düşer, envantere girmez, kaydedilir', () {
      final GameState temel = aileli(24, age: 16, wallet: 1000);
      final Person anne = anneOf(temel);
      final InteractionResult r = interactions.perform(
        state: temel,
        personId: anne.id,
        kind: InteractionKind.hediyeVer,
        rng: Random(3),
      );

      expect(r.outcome.accepted, isTrue);
      final String verilen = r.outcome.givenPossession!;
      final GiftItem hediye = giftById(verilen)!;
      expect(r.state.player.wallet, 1000 - hediye.value);
      expect(r.state.possessions, isNot(contains(verilen)));
      expect(r.outcome.text.toLowerCase(), contains(hediye.name.toLowerCase()));
      expect(
        r.state.gifts.any((GiftRecord g) =>
            g.itemId == verilen &&
            g.fromId == GiftRecord.playerId &&
            g.toId == anne.id),
        isTrue,
      );
    });

    test('hediye kataloğu eşya adları ve simgeleriyle tutarlıdır', () {
      for (final GiftItem item in kGiftCatalog) {
        expect(item.id, isNotEmpty);
        expect(item.name, isNotEmpty);
        expect(item.value, greaterThan(0));
        expect(item.minAge, lessThanOrEqualTo(item.maxAge));
      }
      final Set<String> ids = kGiftCatalog.map((GiftItem g) => g.id).toSet();
      expect(ids.length, kGiftCatalog.length, reason: 'Kimlikler benzersiz');
    });
  });

  // ===================================================================
  // 6) Kayıt uyumu
  // ===================================================================
  group('Kayıt uyumu', () {
    test('desteklenen en eski sürümün kaydı okul bilgisi kaybolmadan açılır', () async {
      final GameController c = schoolAged(31, untilAge: 9);
      final GameState state = c.state!;
      expect(state.currentClassmates, isNotEmpty);

      // Paket 12'den beri geriye dönük yalnızca son beş sürüm taşınır;
      // okul kimliklerinin hiç olmadığı sürümler artık desteklenmiyor.
      // Bu test desteklenen en eski sürümü sınar.
      final String eski = jsonEncode(<String, Object?>{
        'formatVersion': kMinReadableSaveVersion,
        'state': encodeGameState(state),
      });

      final SaveLoadResult result =
          await SaveService(MemorySaveStore(initial: eski)).load();
      expect(result.isLoaded, isTrue, reason: result.message);
      final GameState yuklenen = result.state!;

      expect(yuklenen.education.classId, isNotNull);
      expect(yuklenen.currentClassmates.map((Person p) => p.id).toSet(),
          state.currentClassmates.map((Person p) => p.id).toSet());
      expect(yuklenen.currentTeachers.map((Person p) => p.id).toSet(),
          state.currentTeachers.map((Person p) => p.id).toSet());
      expect(yuklenen.gifts.length, state.gifts.length);
    });

    test('yeni alanlar kaydedilip geri okunur', () async {
      final GameController c = schoolAged(32, untilAge: 9);
      final GameState once = c.state!.copyWith(
        gifts: <GiftRecord>[
          const GiftRecord(
            itemId: 'yoyo',
            fromId: 'anne',
            toId: GiftRecord.playerId,
            age: 7,
          ),
        ],
      );

      final MemorySaveStore store = MemorySaveStore();
      final SaveService service = SaveService(store);
      await service.save(once);
      final SaveLoadResult result = await service.load();
      expect(result.isLoaded, isTrue);

      final GameState sonra = result.state!;
      expect(sonra.education.schoolId, once.education.schoolId);
      expect(sonra.education.classId, once.education.classId);
      expect(sonra.currentClassmates.length, once.currentClassmates.length);
      expect(sonra.gifts.length, 1);
      expect(sonra.gifts.first.itemId, 'yoyo');
      expect(sonra.gifts.first.age, 7);
      for (final Person p in once.people.where((Person p) => p.schoolTie != null)) {
        expect(sonra.personById(p.id)!.classId, p.classId);
        expect(sonra.personById(p.id)!.schoolId, p.schoolId);
      }
    });
  });

  // ===================================================================
  // 7) Olay metinleri
  // ===================================================================
  group('Olay metinleri', () {
    test('bakkal sahnesi gerçekçi hâle getirildi', () {
      final GameEvent bakkal =
          kEventPool.firstWhere((GameEvent e) => e.id == 'bakkal_veresiye');
      expect(bakkal.text, isNot(contains('defteri uzatıyor')));
      expect(bakkal.text, contains('veresiye defterini'));
    });

    test('hiçbir olay metninde doldurulmamış yer tutucu kalmaz', () {
      for (final GameEvent e in kEventPool) {
        for (final String parca in <String>[e.text]) {
          expect(parca, isNot(contains('{esya}')));
        }
        expect(e.choices, isNotEmpty);
      }
    });
  });
}

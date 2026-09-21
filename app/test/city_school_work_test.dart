import 'dart:convert';
import 'dart:math';

import 'package:bir_omur/data/save/game_state_codec.dart';
import 'package:bir_omur/data/save/save_format.dart';
import 'package:bir_omur/data/save/save_service.dart';
import 'package:bir_omur/data/save/save_store.dart';
import 'package:bir_omur/data/shop_catalog.dart';
import 'package:bir_omur/domain/economy/housing.dart';
import 'package:bir_omur/domain/education/school_transfer.dart';
import 'package:bir_omur/domain/generation/life_generator.dart';
import 'package:bir_omur/domain/generation/life_progression.dart';
import 'package:bir_omur/domain/generation/school_people.dart';
import 'package:bir_omur/domain/interaction/item_actions.dart';
import 'package:bir_omur/domain/models/education.dart';
import 'package:bir_omur/domain/models/game_state.dart';
import 'package:bir_omur/domain/models/person.dart';
import 'package:bir_omur/domain/models/relation.dart';
import 'package:bir_omur/state/game_controller.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/invariants.dart';

const ItemActions esyalar = ItemActions();

/// Okula devam eden, taşınabilecek parası olan bir hayat.
GameState ogrenci(int seed, {int age = 15, int wallet = 6000000}) {
  GameState state =
      LifeGenerator.seeded(seed).generate(mode: StartMode.tamamenRastgele);
  final LifeProgression ilerle = LifeProgression(Random(seed));
  while (state.player.age < age && !state.deceased) {
    state = ilerle.advanceOneYear(state.copyWith(pendingEvent: null));
  }
  state = state.copyWith(
    player: state.player.copyWith(wallet: wallet),
    pendingEvent: null,
    pendingCrisis: null,
  );
  return state;
}

/// Oyuncunun yaşadığı şehirden farklı bir şehir.
String baskaSehir(GameState state) =>
    state.player.currentCity == 'İzmir' ? 'Trabzon' : 'İzmir';

/// Öğrenciyi başka şehre taşır.
///
/// Reşit olmayan oyuncu kendi başına taşınamaz (18 yaş kuralı); ailesiyle
/// birlikte taşınma henüz tasarlanmadı (Q-065). Bu yüzden okul nakli
/// motoru burada doğrudan çağrılır: şehir değişimi verilir, nakil
/// kurallarının doğru işlediği sınanır.
({GameState state, String? logText}) ogrenciTasi(GameState state, String sehir) =>
    const SchoolTransfer().transferIfNeeded(
      state.copyWith(player: state.player.copyWith(currentCity: sehir)),
      Random(11),
    );

/// Kontrolcü üzerinden başka şehirdeki eve taşınır (okul nakli dâhil).
GameController tasindir(GameState state, String sehir) {
  final GameController controller = GameController(random: Random(9));
  controller.debugSetState(state);
  final ItemActionResult alim = esyalar.buy(
    state: controller.state!,
    product: shopProductByTypeId('kucuk_daire')!,
    location: sehir,
  );
  expect(alim.outcome.applied, isTrue, reason: alim.outcome.text);
  controller.debugSetState(alim.state);
  final HousingOutcome? sonuc =
      controller.moveInto(controller.state!.items.last);
  expect(sonuc?.applied, isTrue, reason: sonuc?.text);
  return controller;
}

void main() {
  group('Şehir değiştirme', () {
    test('doğum şehri değişmez, yaşanan şehir güncellenir', () {
      final GameState state = ogrenci(301, age: 30);
      final String dogum = state.player.birthCity;
      final String hedef = baskaSehir(state);

      final GameController controller = tasindir(state, hedef);
      addTearDown(controller.dispose);

      expect(controller.state!.player.birthCity, dogum);
      expect(controller.state!.player.currentCity, hedef);
      expect(Housing.cityOf(controller.state!), hedef);
      expect(checkInvariants(controller.state!), isEmpty);
    });

    test('öğrenci nakil olur; eğitim geçmişi ve eski kayıtlar korunur', () {
      GameState state = ogrenci(302);
      // Lise alanı ve puanlar gibi eğitim geçmişi taşınmalı.
      state = state.copyWith(
        education: state.education.copyWith(placementScore: 412),
      );
      expect(state.education.isSchoolStudent, isTrue);

      final String? eskiSinif = state.education.classId;
      final List<String> eskiArkadaslar = state.currentClassmates
          .map((Person p) => p.id)
          .toList(growable: false);
      expect(eskiArkadaslar, isNotEmpty);
      final int eskiKisiSayisi = state.people.length;
      final String hedef = baskaSehir(state);

      final GameState sonra = ogrenciTasi(state, hedef).state;

      // Yeni sınıf yeni şehirde.
      expect(sonra.education.classId, isNot(eskiSinif));
      expect(SchoolPeople.cityOfClassId(sonra.education.classId), hedef);
      // Eğitim geçmişi silinmedi.
      expect(sonra.education.grade, state.education.grade);
      expect(sonra.education.placementScore, 412);
      expect(sonra.education.track, state.education.track);
      // Eski kişiler kayıtta duruyor, üstüne yenileri eklendi.
      expect(sonra.people.length, greaterThan(eskiKisiSayisi));
      for (final String id in eskiArkadaslar) {
        expect(sonra.personById(id), isNotNull,
            reason: 'Eski sınıf arkadaşının kaydı silinmemeli');
      }
    });

    test('aynı anda iki okulda görünülmez', () {
      final GameState state = ogrenci(303);
      final String hedef = baskaSehir(state);
      final GameState sonra = ogrenciTasi(state, hedef).state;

      // Güncel sınıf tek bir sınıf kimliğine bağlı.
      final Set<String?> sinifKimlikleri =
          sonra.currentClassmates.map((Person p) => p.classId).toSet();
      expect(sinifKimlikleri, hasLength(1));
      expect(sinifKimlikleri.single, sonra.education.classId);

      // Güncel öğretmen yalnızca yeni okuldan.
      for (final Person ogretmen in sonra.currentTeachers) {
        expect(ogretmen.schoolId, sonra.education.schoolId);
        expect(ogretmen.city, hedef);
      }
      expect(checkInvariants(sonra), isEmpty);
    });

    test('eski okulun öğretmeni yeni şehirde güncel öğretmen görünmez', () {
      final GameState state = ogrenci(304);
      final List<String> eskiOgretmenler = state.currentTeachers
          .map((Person p) => p.id)
          .toList(growable: false);
      expect(eskiOgretmenler, isNotEmpty);

      final GameState sonra = ogrenciTasi(state, baskaSehir(state)).state;

      for (final String id in eskiOgretmenler) {
        expect(sonra.personById(id), isNotNull, reason: 'Kayıt silinmez');
        expect(
          sonra.currentTeachers.map((Person p) => p.id),
          isNot(contains(id)),
        );
        expect(sonra.isReachable(sonra.personById(id)!), isFalse);
      }
    });

    test('yeni şehirde yeni insanlarla tanışılır', () {
      final GameState state = ogrenci(305);
      final String hedef = baskaSehir(state);
      final GameState sonra = ogrenciTasi(state, hedef).state;

      final List<Person> yeniler = sonra.people
          .where((Person p) => p.city == hedef)
          .toList(growable: false);
      expect(yeniler, isNotEmpty);
      expect(sonra.currentClassmates, isNotEmpty);
    });
  });

  group('Erişilebilirlik ve şehir', () {
    test('başka şehirde kalan arkadaş silinmez ama gündelik listede olmaz',
        () {
      final GameState state = ogrenci(306);
      final Person sinifArkadasi = state.currentClassmates.first;
      // Sınıf arkadaşı yakın arkadaş olmuş olsun.
      final GameState arkadasli = state.copyWith(
        people: state.people
            .map((Person p) => p.id == sinifArkadasi.id
                ? p.copyWith(relation: RelationType.arkadas)
                : p)
            .toList(growable: false),
      );
      expect(arkadasli.isReachable(arkadasli.personById(sinifArkadasi.id)!),
          isTrue);

      final GameState tasindiktanSonra =
          ogrenciTasi(arkadasli, baskaSehir(arkadasli)).state;
      final Person? sonra = tasindiktanSonra.personById(sinifArkadasi.id);

      expect(sonra, isNotNull, reason: 'Arkadaşın kaydı silinmez');
      expect(sonra!.bond, sinifArkadasi.bond, reason: 'Yakınlık sıfırlanmaz');
      expect(tasindiktanSonra.isReachable(sonra), isFalse);
      expect(
        tasindiktanSonra.reachablePeople.map((Person p) => p.id),
        isNot(contains(sonra.id)),
      );
    });

    test('yakın aile başka şehirde de erişilebilir kalır', () {
      final GameState state = ogrenci(307);
      final GameState sonra = ogrenciTasi(state, baskaSehir(state)).state;

      for (final Person p in sonra.people) {
        if (!p.isAlive) continue;
        if (p.relation == RelationType.anne ||
            p.relation == RelationType.baba ||
            p.relation == RelationType.kardes) {
          expect(sonra.isReachable(p), isTrue,
              reason: '${p.relation.name} şehir değişti diye kopmamalı');
        }
      }
    });

    test('gündelik liste tanışılan herkesle dolmaz', () {
      // Kademe değiştirerek eski sınıf arkadaşları biriktirilir.
      GameState state = ogrenci(320, age: 12);
      expect(state.pastSchoolPeople, isNotEmpty,
          reason: 'Eski kademeden kişi kalmalı');

      final Set<String> erisilebilir =
          state.reachablePeople.map((Person p) => p.id).toSet();
      for (final Person eski in state.pastSchoolPeople) {
        if (eski.relation == RelationType.arkadas) continue;
        expect(erisilebilir, isNot(contains(eski.id)),
            reason: 'Eski okul tanışıklığı gündelik listede olmamalı');
      }
      // Güncel sınıf arkadaşları ve hane listede olmalı.
      for (final Person p in state.currentClassmates) {
        expect(erisilebilir, contains(p.id));
      }
      for (final Person p in state.household) {
        expect(erisilebilir, contains(p.id));
      }
    });

    test('sınıf arkadaşı hane üyesi gibi gösterilmez', () {
      final GameState state = ogrenci(308);
      for (final Person p in state.people) {
        if (p.schoolTie == null) continue;
        expect(p.inPlayerHousehold, isFalse,
            reason: 'Okul kişisi hanede görünmemeli: ${p.id}');
      }
      expect(
        state.household.every((Person p) => p.schoolTie == null),
        isTrue,
      );
    });

    test('şehir bilgisi olmayan eski kayıtlarda kimse listeden düşmez', () {
      final GameState state = ogrenci(309);
      final GameState sehirsiz = state.copyWith(
        people: state.people
            .map((Person p) => p.copyWith(city: null))
            .toList(growable: false),
        player: state.player.copyWith(currentCity: 'Trabzon'),
      );
      for (final Person p in sehirsiz.people) {
        if (!p.isAlive) continue;
        expect(
          sehirsiz.isReachable(p),
          state.isReachable(p.copyWith(city: null)),
          reason: 'Şehirsiz kayıtta erişilebilirlik değişmemeli',
        );
      }
    });
  });

  group('İş ve şehir', () {
    test('şehir değişince işe kendiliğinden son verilmez', () {
      GameState state = ogrenci(310, age: 30);
      state = state.copyWith(
        education: const EducationState.notStarted(),
        career: state.career.copyWith(
          jobId: 'garson',
          startedAtAge: 25,
          lastPaidAge: 30,
          jobCity: state.player.currentCity,
        ),
      );
      final String eskiSehir = state.player.currentCity;

      final GameController controller = tasindir(state, baskaSehir(state));
      addTearDown(controller.dispose);
      final GameState sonra = controller.state!;

      expect(sonra.career.isEmployed, isTrue, reason: 'İş bitirilmemeli');
      expect(sonra.career.jobId, 'garson');
      expect(sonra.career.jobCity, eskiSehir);
      expect(sonra.career.isInAnotherCity(sonra.player.currentCity), isTrue);
      expect(
        sonra.log.last.text.toLowerCase(),
        contains(eskiSehir.toLowerCase()),
      );
    });
  });

  group('Kayıt uyumu', () {
    test('şehir bilgileri kaydedilip geri okunur', () async {
      final GameState state = ogrenci(311);
      final GameState tasinmis = ogrenciTasi(state, baskaSehir(state)).state;

      final SaveService service = SaveService(MemorySaveStore());
      await service.save(tasinmis);
      final GameState geri = (await service.load()).state!;

      expect(geri.player.currentCity, tasinmis.player.currentCity);
      expect(geri.player.birthCity, tasinmis.player.birthCity);
      expect(geri.education.classId, tasinmis.education.classId);
      expect(geri.currentClassmates.length, tasinmis.currentClassmates.length);
      expect(
        geri.people.where((Person p) => p.city != null).length,
        tasinmis.people.where((Person p) => p.city != null).length,
      );
      expect(checkInvariants(geri), isEmpty);
    });

    test('desteklenen en eski sürümün kaydı şehirsiz açılır ve okul bozulmaz', () async {
      final GameState state = ogrenci(312);
      final Map<String, Object?> body = encodeGameState(state);
      for (final Object? e in body['people']! as List<Object?>) {
        (e! as Map<String, Object?>).remove('city');
      }
      (body['career']! as Map<String, Object?>).remove('jobCity');

      final SaveLoadResult result = await SaveService(
        MemorySaveStore(
          initial: jsonEncode(
            <String, Object?>{'formatVersion': kMinReadableSaveVersion, 'state': body},
          ),
        ),
      ).load();
      expect(result.isLoaded, isTrue, reason: result.message);

      final GameState geri = result.state!;
      expect(geri.people.every((Person p) => p.city == null), isTrue);
      expect(geri.career.jobCity, isNull);
      expect(geri.currentClassmates.length, state.currentClassmates.length,
          reason: 'Eski kayıtta sınıf olduğu gibi kalmalı');
      expect(geri.education.classId, state.education.classId);
    });

    test('eski kayıttaki şehirsiz sınıf, sebepsiz yere yenilenmez', () {
      final GameState state = ogrenci(313);
      // Eski biçim: şehirsiz okul/sınıf kimliği.
      final SchoolLevel kademe = state.education.level!;
      final GameState eski = state.copyWith(
        education: state.education.copyWith(
          schoolId: SchoolPeople.schoolIdFor(kademe),
          classId: SchoolPeople.classIdFor(kademe),
        ),
        people: state.people
            .map((Person p) => p.classId == state.education.classId
                ? p.copyWith(
                    classId: SchoolPeople.classIdFor(kademe),
                    schoolId: SchoolPeople.schoolIdFor(kademe),
                    city: null,
                  )
                : p)
            .toList(growable: false),
      );
      expect(eski.currentClassmates, isNotEmpty);

      final GameState sonra = LifeProgression(Random(4))
          .advanceOneYear(eski.copyWith(pendingEvent: null));
      if (sonra.education.level != kademe) return; // kademe değiştiyse konu dışı

      expect(sonra.education.classId, SchoolPeople.classIdFor(kademe),
          reason: 'Aynı kademede sınıf yenilenmemeli');
      expect(sonra.currentClassmates.length, eski.currentClassmates.length);
    });
  });

  group('Okul nakli motoru', () {
    test('aynı şehirde nakil yapılmaz', () {
      final GameState state = ogrenci(314);
      final ({GameState state, String? logText}) sonuc =
          const SchoolTransfer().transferIfNeeded(state, Random(1));
      // Sınıf kimliği zaten bu şehre aitse nakil olmaz.
      if (SchoolPeople.cityOfClassId(state.education.classId) ==
          state.player.currentCity) {
        expect(sonuc.logText, isNull);
        expect(sonuc.state.people.length, state.people.length);
      }
    });

    test('öğrenci olmayan karakter nakledilmez', () {
      final GameState state = ogrenci(315, age: 30).copyWith(
        education: const EducationState.notStarted(),
      );
      final ({GameState state, String? logText}) sonuc =
          const SchoolTransfer().transferIfNeeded(state, Random(1));
      expect(sonuc.logText, isNull);
      expect(sonuc.state.people.length, state.people.length);
    });
  });
}

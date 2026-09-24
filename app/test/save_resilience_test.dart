import 'dart:convert';
import 'dart:math';

import 'package:bir_omur/data/activity_catalog.dart';
import 'package:bir_omur/data/job_catalog.dart';
import 'package:bir_omur/data/lottery_catalog.dart';
import 'package:bir_omur/data/pet_catalog.dart';
import 'package:bir_omur/data/save/game_state_codec.dart';
import 'package:bir_omur/data/save/save_format.dart';
import 'package:bir_omur/data/save/save_service.dart';
import 'package:bir_omur/data/save/save_store.dart';
import 'package:bir_omur/domain/generation/life_generator.dart';
import 'package:bir_omur/domain/models/game_state.dart';
import 'package:bir_omur/domain/models/gender.dart';
import 'package:bir_omur/domain/models/hobby_progress.dart';
import 'package:bir_omur/domain/models/marriage.dart';
import 'package:bir_omur/domain/models/owned_item.dart';
import 'package:bir_omur/domain/models/pending_wedding.dart';
import 'package:bir_omur/domain/models/pregnancy.dart';
import 'package:bir_omur/domain/models/pending_notice.dart';
import 'package:bir_omur/domain/models/person.dart';
import 'package:bir_omur/domain/models/relation.dart';
import 'package:bir_omur/domain/models/trip.dart';
import 'package:bir_omur/domain/models/wealth.dart';
import 'package:bir_omur/domain/pets/pet_care.dart';
import 'package:bir_omur/state/game_controller.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/test_flow.dart';

/// Kayıt dayanıklılığı (Paket 44).
///
/// Kayıt oyunun en kritik alanı: bir hata burada oyuncunun bütün hayatını
/// siler. Bu paket üç şey yapar:
/// 1. Gerçek oyun akışlarını kaydedip yükler ve önemli alanları karşılaştırır.
/// 2. Rastgele üretilmiş çok sayıda durumda `encode → decode → encode`
///    döngüsünün **hiçbir bilgi kaybetmediğini** gösterir.
/// 3. Bozuk kayıtlarda oyuncunun kaydının sessizce silinmediğini sınar.

ActivityAction eylem(String id) =>
    kActivityActions.firstWhere((ActivityAction a) => a.id == id);

Person sevgili(String id, String ad, Gender gender, {int age = 28}) => Person(
      id: id,
      firstName: ad,
      lastName: 'Yaman',
      gender: gender,
      relation: RelationType.sevgili,
      age: age,
      isAlive: true,
      inPlayerHousehold: false,
      employment: EmploymentStatus.calisiyor,
      occupation: 'öğretmen',
      wealth: WealthTier.ortaHalli,
      bond: 88,
    );

/// Kayıt servisi üzerinden tam gidiş-dönüş.
Future<GameState> kaydetYukle(GameState state) async {
  final SaveService servis = SaveService(MemorySaveStore());
  await servis.save(state);
  final SaveLoadResult sonuc = await servis.load();
  expect(sonuc.isLoaded, isTrue, reason: sonuc.message);
  return sonuc.state!;
}

/// Kodlama gidiş-dönüşünde bilgi kaybı var mı?
///
/// İki kez kodlanan gövdeler birebir aynıysa, çözme aşamasında hiçbir alan
/// düşmemiş demektir.
void kayipYok(GameState state, {String? reason}) {
  final Map<String, Object?> ilk = encodeGameState(state);
  final Map<String, Object?> ikinci = encodeGameState(decodeGameState(ilk));
  expect(jsonEncode(ikinci), jsonEncode(ilk), reason: reason);
}

/// Aynı kimlik iki farklı nesnede kullanılmış mı?
String? kimlikCakismasi(GameState s) {
  String? tekrar(String tur, Iterable<String> idler) {
    final Set<String> gorulen = <String>{};
    for (final String id in idler) {
      if (!gorulen.add(id)) return '$tur kimliği iki kez: $id';
    }
    return null;
  }

  final List<String?> sonuclar = <String?>[
    tekrar('Kişi', s.people.map((Person p) => p.id)),
    tekrar('Hayvan', s.pets.map((Pet p) => p.id)),
    tekrar('Eşya', s.items.map((OwnedItem i) => i.id)),
    tekrar('Gezi', s.trips.map((TripRecord t) => t.id)),
    tekrar('Hobi', s.hobbies.map((HobbyProgress h) => h.hobbyId)),
    tekrar(
      'Geçmiş evlilik',
      s.pastMarriages.map((Marriage m) => '${m.spouseId}-${m.marriedAtAge}'),
    ),
  ];
  for (final String? hata in sonuclar) {
    if (hata != null) return hata;
  }

  // Çocuk kaydı iki kez olmamalı; çocuklar kişi listesinden okunuyor.
  final List<Person> cocuklar = s.children;
  final Set<String> cocukIdleri = cocuklar.map((Person p) => p.id).toSet();
  if (cocukIdleri.length != cocuklar.length) {
    return 'Aynı çocuk iki kez kayıtlı';
  }

  // Yürüyen evlilik, geçmiş evliliklerden biriyle **aynı** kayıt olmamalı.
  final Marriage? aktif = s.marriage;
  if (aktif != null) {
    final bool ayniKayit = s.pastMarriages.any(
      (Marriage m) =>
          m.spouseId == aktif.spouseId && m.marriedAtAge == aktif.marriedAtAge,
    );
    if (ayniKayit) return 'Yürüyen evlilik geçmişte de duruyor';
  }
  return null;
}

void main() {
  // ===================================================================
  // 1-17) Gerçek akışlar
  // ===================================================================
  group('Senaryolar kaydedilip yüklenir', () {
    test('1. yeni hayat', () async {
      final GameController c = GameController(random: Random(3));
      addTearDown(c.dispose);
      c.startNewLife(mode: StartMode.tamamenRastgele);

      final GameState geri = await kaydetYukle(c.state!);
      expect(geri.player.id, c.state!.player.id);
      expect(geri.people.length, c.state!.people.length);
      expect(geri.log.length, c.state!.log.length);
      expect(kimlikCakismasi(geri), isNull);
      kayipYok(c.state!);
    });

    test('2. yirmi yıl oynanmış hayat', () async {
      final GameController c = GameController(random: Random(4));
      addTearDown(c.dispose);
      c.startNewLife(mode: StartMode.tamamenRastgele);
      advanceToAge(c, 20);

      final GameState once = c.state!;
      final GameState geri = await kaydetYukle(once);
      expect(geri.player.age, once.player.age);
      expect(geri.log.length, once.log.length);
      expect(geri.seenEventIds, once.seenEventIds);
      expect(geri.eventSeenCounts, once.eventSeenCounts);
      expect(geri.education.grade, once.education.grade);
      expect(kimlikCakismasi(geri), isNull);
      kayipYok(once);
    });

    test('3. evlilik + çocuk + evcil hayvan + hobi', () async {
      final GameController c = GameController(random: Random(5));
      addTearDown(c.dispose);
      c.startNewLife(mode: StartMode.tamamenRastgele);
      advanceToAge(c, 28);
      expect(c.state!.deceased, isFalse);

      final Gender karsi = c.state!.player.gender == Gender.erkek
          ? Gender.kadin
          : Gender.erkek;
      c.debugSetState(
        c.state!.copyWith(
          player: c.state!.player.copyWith(wallet: 3000000),
          people: <Person>[
            ...c.state!.people
                .where((Person p) => p.relation != RelationType.sevgili),
            sevgili('es-1', 'Elif', karsi),
          ],
        ),
      );
      c.marry('es-1');
      c.haveChild();
      resolvePendingEvents(c);
      for (int i = 0; i < 4 && c.state!.children.isEmpty; i++) {
        resolvePendingEvents(c);
        // Lise alanı seçilmeden yaş atlanmaz (D-094).
        resolveEducationChoices(c);
        c.ageUp();
      }
      resolvePendingEvents(c);
      c.adoptPet(PetSpecies.kedi, 'Zeytin');
      c.performActivity(eylem('muzik_kursu'));

      final GameState once = c.state!;
      final GameState geri = await kaydetYukle(once);

      expect(geri.marriage!.spouseId, 'es-1');
      expect(geri.marriage!.marriedAtAge, once.marriage!.marriedAtAge);
      expect(geri.children.map((Person p) => p.id),
          once.children.map((Person p) => p.id));
      expect(geri.pets.single.name, 'Zeytin');
      expect(geri.pets.single.adoptedAtPlayerAge,
          once.pets.single.adoptedAtPlayerAge);
      expect(geri.hobbies.single.experience, once.hobbies.single.experience);
      expect(kimlikCakismasi(geri), isNull);
      kayipYok(once);
    });

    test('4. boşanma + ikinci evlilik', () async {
      final GameController c = GameController(random: Random(6));
      addTearDown(c.dispose);
      c.startNewLife(mode: StartMode.tamamenRastgele);
      advanceToAge(c, 30);
      expect(c.state!.deceased, isFalse);
      final Gender karsi = c.state!.player.gender == Gender.erkek
          ? Gender.kadin
          : Gender.erkek;
      c.debugSetState(
        c.state!.copyWith(
          player: c.state!.player.copyWith(wallet: 3000000),
          people: <Person>[
            ...c.state!.people
                .where((Person p) => p.relation != RelationType.sevgili),
            sevgili('es-1', 'Elif', karsi),
          ],
        ),
      );
      c.marry('es-1');
      final int ilkYil = c.state!.marriage!.marriedAtAge;
      c.divorce();
      c.debugSetState(
        c.state!.copyWith(
          people: <Person>[...c.state!.people, sevgili('es-2', 'Derya', karsi)],
        ),
      );
      c.marry('es-2');

      final GameState geri = await kaydetYukle(c.state!);
      expect(geri.marriage!.spouseId, 'es-2');
      expect(geri.pastMarriages, hasLength(1));
      expect(geri.pastMarriages.single.spouseId, 'es-1');
      expect(geri.marriageWith('es-1')!.marriedAtAge, ilkYil);
      expect(kimlikCakismasi(geri), isNull);
      kayipYok(c.state!);
    });

    test('5. kuşak değişimi', () async {
      final GameController c = GameController(random: Random(31));
      addTearDown(c.dispose);
      c.startNewLife(mode: StartMode.tamamenRastgele);
      advanceToAge(c, 28);
      final Gender karsi = c.state!.player.gender == Gender.erkek
          ? Gender.kadin
          : Gender.erkek;
      c.debugSetState(
        c.state!.copyWith(
          player: c.state!.player.copyWith(wallet: 3000000),
          people: <Person>[
            ...c.state!.people
                .where((Person p) => p.relation != RelationType.sevgili),
            sevgili('es-1', 'Elif', karsi),
          ],
        ),
      );
      c.marry('es-1');
      c.haveChild();
      for (int i = 0; i < 5 && c.state!.children.isEmpty; i++) {
        resolvePendingEvents(c);
        // Lise alanı seçilmeden yaş atlanmaz (D-094).
        resolveEducationChoices(c);
        c.ageUp();
      }
      resolvePendingEvents(c);
      expect(c.state!.children, isNotEmpty);

      int guard = 0;
      while (!c.state!.deceased) {
        if (guard++ > 150) fail('Oyuncu hiç ölmedi.');
        resolvePendingEvents(c);
        // Lise alanı seçilmeden yaş atlanmaz (D-094).
        resolveEducationChoices(c);
        c.ageUp();
      }
      resolvePendingEvents(c);
      if (c.generationHeirs.isEmpty) return;

      expect(c.continueAsChild(c.generationHeirs.first.id), isEmpty);
      final GameState once = c.state!;
      final GameState geri = await kaydetYukle(once);

      expect(geri.generation, once.generation);
      expect(geri.pastLives.length, once.pastLives.length);
      expect(geri.settledEstates, once.settledEstates);
      expect(geri.player.id, once.player.id);
      expect(kimlikCakismasi(geri), isNull);
      kayipYok(once);
    });

    test('6. evcil hayvan vefatı', () async {
      GameState s = LifeGenerator.seeded(9)
          .generate(mode: StartMode.tamamenRastgele)
          .copyWith(
            pendingEvent: null,
            notices: const <PendingNotice>[],
            pets: <Pet>[
              Pet(
                id: 'hayvan-1',
                name: 'Zeytin',
                species: 'kedi',
                age: PetSpecies.kedi.maxLifespan,
                adoptedAtPlayerAge: 20,
              ),
            ],
          );
      s = s.copyWith(player: s.player.copyWith(age: 35, wallet: 500000));
      s = PetCare.advanceYear(s, 36, Random(1));
      expect(s.pets.single.isAlive, isFalse);

      final GameState geri = await kaydetYukle(s);
      expect(geri.pets, hasLength(1), reason: 'Vefat kaydı silinmemeli');
      expect(geri.pets.single.diedAtAge, s.pets.single.diedAtAge);
      expect(geri.pets.single.diedAtPlayerAge, 36);
      expect(geri.notices.map((PendingNotice n) => n.id),
          s.notices.map((PendingNotice n) => n.id));
      kayipYok(s);
    });

    test('7. bekleyen olay varken', () async {
      final GameController c = GameController(random: Random(12));
      addTearDown(c.dispose);
      c.startNewLife(mode: StartMode.tamamenRastgele);
      int guard = 0;
      while (!c.state!.hasPendingEvent) {
        if (guard++ > 40) fail('Hiç olay çıkmadı.');
        resolvePendingEvents(c);
        // Lise alanı seçilmeden yaş atlanmaz (D-094).
        resolveEducationChoices(c);
        c.ageUp();
      }
      final GameState once = c.state!;
      final GameState geri = await kaydetYukle(once);
      expect(geri.pendingEvent!.eventId, once.pendingEvent!.eventId);
      expect(geri.pendingEvent!.personId, once.pendingEvent!.personId);
      expect(
        geri.pendingEvent!.choices.map((dynamic ch) => ch.id as String),
        once.pendingEvent!.choices.map((dynamic ch) => ch.id as String),
      );
      expect(geri.pendingEvent!.text, once.pendingEvent!.text);
      kayipYok(once);
    });

    test('8. bekleyen sağlık krizi varken', () async {
      final GameController c = GameController(random: Random(2));
      addTearDown(c.dispose);
      c.startNewLife(mode: StartMode.tamamenRastgele);
      int guard = 0;
      while (!c.state!.hasPendingCrisis && !c.state!.deceased) {
        if (guard++ > 200) break;
        if (c.state!.hasPendingEvent) {
          c.chooseEventOption(c.state!.pendingEvent!.choices.first.id);
          continue;
        }
        if (c.state!.notices.isNotEmpty) {
          c.dismissNotice();
          continue;
        }
        // Lise alanı seçilmeden yaş atlanmaz (D-094).
        resolveEducationChoices(c);
        c.ageUp();
      }
      if (!c.state!.hasPendingCrisis) return; // kriz çıkmadıysa sınanacak şey yok
      final GameState once = c.state!;
      final GameState geri = await kaydetYukle(once);
      expect(geri.pendingCrisis!.crisisId, once.pendingCrisis!.crisisId);
      kayipYok(once);
    });

    test('9. bekleyen düğün ve hamilelik varken', () async {
      final GameController c = GameController(random: Random(8));
      addTearDown(c.dispose);
      c.startNewLife(mode: StartMode.tamamenRastgele);
      advanceToAge(c, 26);
      expect(c.state!.deceased, isFalse);
      final Gender karsi = c.state!.player.gender == Gender.erkek
          ? Gender.kadin
          : Gender.erkek;
      c.debugSetState(
        c.state!.copyWith(
          player: c.state!.player.copyWith(wallet: 3000000),
          people: <Person>[
            ...c.state!.people
                .where((Person p) => p.relation != RelationType.sevgili),
            sevgili('es-1', 'Elif', karsi),
          ],
          pendingWedding: const PendingWedding(
            spouseId: 'es-1',
            acceptedAtAge: 26,
          ),
          pregnancy: const Pregnancy(
            partnerId: 'es-1',
            expecting: ExpectingParty.oyuncu,
            startedAtAge: 26,
          ),
        ),
      );

      final GameState once = c.state!;
      final GameState geri = await kaydetYukle(once);
      expect(geri.pendingWedding!.spouseId, 'es-1');
      expect(geri.pendingWedding!.acceptedAtAge, 26);
      expect(geri.pregnancy!.partnerId, 'es-1');
      expect(geri.pregnancy!.startedAtAge, 26);
      kayipYok(once);
    });

    test('10. miras dağıtıldıktan sonra', () async {
      final GameController c = GameController(random: Random(17));
      addTearDown(c.dispose);
      c.startNewLife(mode: StartMode.tamamenRastgele);
      int guard = 0;
      while (c.state!.settledEstates.isEmpty && !c.state!.deceased) {
        if (guard++ > 200) break;
        resolvePendingEvents(c);
        // Lise alanı seçilmeden yaş atlanmaz (D-094).
        resolveEducationChoices(c);
        c.ageUp();
      }
      if (c.state!.settledEstates.isEmpty) return;

      final GameState once = c.state!;
      final GameState geri = await kaydetYukle(once);
      expect(geri.settledEstates, once.settledEstates);
      expect(geri.player.wallet, once.player.wallet);
      kayipYok(once);
    });

    test('11-17. sosyal medya, piyango, askerlik, dövüş, Finger, hobi ve '
        'birlikte etkinlik kayıtları', () async {
      final GameController c = GameController(random: Random(21));
      addTearDown(c.dispose);
      c.startNewLife(mode: StartMode.tamamenRastgele);
      advanceToAge(c, 30);
      expect(c.state!.deceased, isFalse);

      // Zengin bir durum kur: bütün alt sistemler dolsun.
      c.debugSetState(
        c.state!.copyWith(
          player: c.state!.player.copyWith(wallet: 9000000),
          people: <Person>[
            ...c.state!.people,
            sevgili('es-1', 'Elif',
                c.state!.player.gender == Gender.erkek
                    ? Gender.kadin
                    : Gender.erkek),
          ],
        ),
      );
      c.marry('es-1');

      // Piyango bileti (çekiliş öncesi).
      c.buyLotteryTicket(LotteryDraw.aylik, TicketShare.ceyrek);
      // Hobi ilerlemesi.
      c.performActivity(eylem('muzik_kursu'));
      // Birlikte etkinlik anısı.
      c.performActivity(
        eylem('sinema'),
        companion: c.state!.personById('es-1'),
      );
      // İş kaydı.
      c.applyForJob(kJobCatalog.first);

      final GameState once = c.state!;
      final GameState geri = await kaydetYukle(once);

      expect(geri.lotteryTickets.map((dynamic t) => t.number as String),
          once.lotteryTickets.map((dynamic t) => t.number as String));
      expect(geri.hobbies.single.experience, once.hobbies.single.experience);
      expect(geri.military.status, once.military.status);
      expect(geri.martialArts.length, once.martialArts.length);
      expect(geri.fingerDeck.length, once.fingerDeck.length);
      expect(geri.fingerMatches.length, once.fingerMatches.length);
      expect(geri.socialAccounts.length, once.socialAccounts.length);
      expect(geri.career.jobId, once.career.jobId);

      // Birlikte etkinlik anısı kişiye bağlı olarak duruyor.
      final List<dynamic> anilar = geri.log
          .where((dynamic e) => e.personId == 'es-1')
          .toList(growable: false);
      expect(anilar, isNotEmpty);
      expect(
        anilar.length,
        once.log.where((dynamic e) => e.personId == 'es-1').length,
      );
      expect(kimlikCakismasi(geri), isNull);
      kayipYok(once);
    });
  });

  // ===================================================================
  // Fuzz: rastgele durumlar
  // ===================================================================
  group('Rastgele durumlarda bilgi kaybı yok', () {
    test('50 hayat: encode → decode → encode aynı sonucu verir', () {
      int taranan = 0;
      int toplamKisi = 0;
      int toplamGunluk = 0;

      for (int seed = 0; seed < 50; seed++) {
        final GameController c = GameController(random: Random(seed));
        addTearDown(c.dispose);
        c.startNewLife(mode: StartMode.tamamenRastgele, seed: seed);

        // Her hayat farklı bir noktaya kadar oynanır.
        final int hedef = 5 + (seed * 7) % 70;
        advanceToAge(c, hedef);

        final GameState s = c.state!;
        kayipYok(s, reason: 'tohum $seed');
        expect(kimlikCakismasi(s), isNull, reason: 'tohum $seed');

        // Servis üzerinden de aynı sonucu vermeli.
        final Map<String, Object?> json = encodeGameState(s);
        final GameState geri = decodeGameState(json);
        expect(geri.player.age, s.player.age, reason: 'tohum $seed');
        expect(geri.people.length, s.people.length, reason: 'tohum $seed');
        expect(geri.log.length, s.log.length, reason: 'tohum $seed');

        taranan++;
        toplamKisi += s.people.length;
        toplamGunluk += s.log.length;
      }

      expect(taranan, 50);
      // ignore: avoid_print
      print('Kayıt taraması: $taranan hayat, $toplamKisi kişi kaydı, '
          '$toplamGunluk günlük satırı');
      expect(toplamKisi, greaterThan(200),
          reason: 'Tarama sığ: kişi kaydı neredeyse yok');
      expect(toplamGunluk, greaterThan(500),
          reason: 'Tarama sığ: günlük neredeyse boş');
    });
  });

  // ===================================================================
  // Bozuk kayıtlar
  // ===================================================================
  group('Bozuk kayıtta veri kaybolmaz', () {
    String dosya(GameState s, {int? surum}) => jsonEncode(<String, Object?>{
          'formatVersion': surum ?? kSaveFormatVersion,
          'savedAt': DateTime.now().toIso8601String(),
          'state': encodeGameState(s),
        });

    GameState ornek() => LifeGenerator.seeded(2)
        .generate(mode: StartMode.tamamenRastgele)
        .copyWith(pendingEvent: null);

    test('sonradan eklenen alanlar eksikse varsayılanla okunur', () async {
      // Bunlar kayıt biçimi sürümü artmadan eklenmişti; eski kayıtta
      // bulunmazlar ve boş okunmaları gerekir.
      final Map<String, Object?> json =
          Map<String, Object?>.from(encodeGameState(ornek()))
            ..remove('hobbies')
            ..remove('pastMarriages')
            ..remove('lotteryTickets')
            ..remove('martialArts')
            ..remove('fingerDeck')
            ..remove('fingerMatches')
            ..remove('ivfAttempts');
      final GameState geri = decodeGameState(json);
      expect(geri.hobbies, isEmpty);
      expect(geri.pastMarriages, isEmpty);
      expect(geri.lotteryTickets, isEmpty);
      expect(geri.martialArts, isEmpty);
      expect(geri.fingerDeck, isEmpty);
      expect(geri.fingerMatches, isEmpty);
      expect(geri.ivfAttempts, 0);
    });

    test('herhangi bir alan eksikken çözme ya çalışır ya da anlaşılır '
        'Türkçe hata verir; hiçbir durumda çökmez', () {
      final Map<String, Object?> tam = encodeGameState(ornek());
      int acilan = 0;
      int anlasilirHata = 0;

      for (final String alan in tam.keys.toList(growable: false)) {
        final Map<String, Object?> eksik = Map<String, Object?>.from(tam)
          ..remove(alan);
        try {
          decodeGameState(eksik);
          acilan++;
        } on SaveFormatException catch (e) {
          anlasilirHata++;
          expect(e.message, isNotEmpty, reason: alan);
          expect(
            e.message,
            contains('"$alan"'),
            reason: '$alan: hata mesajı hangi alanın eksik olduğunu '
                'söylemeli',
          );
        } catch (e) {
          fail('"$alan" alanı eksikken beklenmeyen hata: $e');
        }
      }

      // ignore: avoid_print
      print('Eksik alan taraması: ${tam.length} alan, $acilan tanesi '
          'varsayılanla açıldı, $anlasilirHata tanesi anlaşılır hata verdi');
      expect(acilan + anlasilirHata, tam.length);
      expect(acilan, greaterThan(0));
    });

    test('alan yanlış türdeyken de çökme yok', () {
      final Map<String, Object?> tam = encodeGameState(ornek());
      for (final String alan in tam.keys.toList(growable: false)) {
        final Map<String, Object?> bozuk = Map<String, Object?>.from(tam)
          ..[alan] = 'bu beklenen tür değil';
        try {
          decodeGameState(bozuk);
        } on SaveFormatException catch (e) {
          expect(e.message, isNotEmpty, reason: alan);
        } catch (e) {
          fail('"$alan" alanı yanlış türdeyken beklenmeyen hata: $e');
        }
      }
    });

    test('bilinmeyen ek alan kaydı bozmaz', () async {
      final Map<String, Object?> json =
          Map<String, Object?>.from(encodeGameState(ornek()))
            ..['gelecekteBirAlan'] = <String, Object?>{'x': 1}
            ..['baskaBirSey'] = 'deneme';
      final GameState geri = decodeGameState(json);
      expect(geri.player.id, isNotEmpty);
    });

    test('yarım JSON: kayıt silinmez, anlaşılır hata döner', () async {
      final String tam = dosya(ornek());
      final MemorySaveStore depo =
          MemorySaveStore(initial: tam.substring(0, tam.length ~/ 2));
      final SaveService servis = SaveService(depo);

      final SaveLoadResult sonuc = await servis.load();
      expect(sonuc.status, SaveLoadStatus.bozuk);
      expect(sonuc.message, isNotEmpty);
      expect(await depo.exists(), isTrue, reason: 'Kayıt silinmemeli');
      expect(await depo.read(), isNotNull);
    });

    test('geçersiz sürüm: kayıt silinmez', () async {
      for (final int surum in <int>[
        kSaveFormatVersion + 1,
        kMinReadableSaveVersion - 1,
        0,
        -3,
      ]) {
        final MemorySaveStore depo =
            MemorySaveStore(initial: dosya(ornek(), surum: surum));
        final SaveService servis = SaveService(depo);
        final SaveLoadResult sonuc = await servis.load();
        expect(sonuc.status, SaveLoadStatus.bozuk, reason: 'sürüm $surum');
        expect(sonuc.message, isNotEmpty, reason: 'sürüm $surum');
        expect(await depo.exists(), isTrue, reason: 'sürüm $surum');
      }
    });

    test('sürüm alanı yoksa ya da metin ise kayıt silinmez', () async {
      for (final Object? surum in <Object?>[null, 'otuz', 3.5]) {
        final Map<String, Object?> d = <String, Object?>{
          'formatVersion': surum,
          'state': encodeGameState(ornek()),
        };
        final MemorySaveStore depo =
            MemorySaveStore(initial: jsonEncode(d));
        final SaveLoadResult sonuc = await SaveService(depo).load();
        expect(sonuc.status, SaveLoadStatus.bozuk, reason: '$surum');
        expect(await depo.exists(), isTrue);
      }
    });

    test('gövde bozuksa da kayıt silinmez', () async {
      final MemorySaveStore depo = MemorySaveStore(
        initial: jsonEncode(<String, Object?>{
          'formatVersion': kSaveFormatVersion,
          'state': <String, Object?>{'player': 'bu bir kişi değil'},
        }),
      );
      final SaveLoadResult sonuc = await SaveService(depo).load();
      expect(sonuc.status, SaveLoadStatus.bozuk);
      expect(await depo.exists(), isTrue);
    });

    test('asıl kayıt bozuk ama yedek sağlamsa hayat kurtarılır', () async {
      final GameState saglam = ornek().copyWith(
        player: ornek().player.copyWith(age: 44, wallet: 12345),
      );
      final MemorySaveStore depo = MemorySaveStore(
        initial: '{"formatVersion": 30, "state": {bozuk',
        initialBackup: dosya(saglam),
      );
      final SaveLoadResult sonuc = await SaveService(depo).load();
      expect(sonuc.isLoaded, isTrue);
      expect(sonuc.state!.player.age, 44);
      expect(sonuc.state!.player.wallet, 12345);
    });

    test('bozuk kayıt okuma denemesi dosyanın üzerine yazmaz', () async {
      final String bozuk = '{"formatVersion": 30, "state": {yarim';
      final MemorySaveStore depo = MemorySaveStore(initial: bozuk);
      final SaveService servis = SaveService(depo);
      await servis.load();
      await servis.load();
      expect(await depo.read(), bozuk);
      expect(depo.writeCount, 0, reason: 'Okuma sırasında yazılmamalı');
    });
  });

  // ===================================================================
  // Sürüm penceresi
  // ===================================================================
  test('okunabilir sürüm penceresi beş sürümdür', () {
    expect(kSaveFormatVersion - kMinReadableSaveVersion, 5);
  });

  test('pencere içindeki her sürüm gerçekten okunabiliyor', () async {
    final GameState s = LifeGenerator.seeded(7)
        .generate(mode: StartMode.tamamenRastgele)
        .copyWith(pendingEvent: null);
    for (int surum = kMinReadableSaveVersion;
        surum <= kSaveFormatVersion;
        surum++) {
      final MemorySaveStore depo = MemorySaveStore(
        initial: jsonEncode(<String, Object?>{
          'formatVersion': surum,
          'state': encodeGameState(s),
        }),
      );
      final SaveLoadResult sonuc = await SaveService(depo).load();
      expect(sonuc.isLoaded, isTrue,
          reason: 'sürüm $surum okunamadı: ${sonuc.message}');
    }
  });
}

import 'dart:math';

import 'package:bir_omur/data/event_pool.dart';
import 'package:bir_omur/data/event_pool_pet.dart';
import 'package:bir_omur/data/pet_catalog.dart';
import 'package:bir_omur/data/save/game_state_codec.dart';
import 'package:bir_omur/domain/events/event_engine.dart';
import 'package:bir_omur/domain/generation/generation_continuation.dart';
import 'package:bir_omur/domain/generation/life_generator.dart';
import 'package:bir_omur/domain/generation/life_progression.dart';
import 'package:bir_omur/domain/models/game_event.dart';
import 'package:bir_omur/domain/models/game_state.dart';
import 'package:bir_omur/domain/models/life_log.dart';
import 'package:bir_omur/domain/models/pending_notice.dart';
import 'package:bir_omur/domain/models/person.dart';
import 'package:bir_omur/domain/pets/pet_care.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/generation_fixtures.dart';

GameState hayat({int age = 20, int wallet = 500000}) {
  final GameState taban =
      LifeGenerator.seeded(4).generate(mode: StartMode.tamamenRastgele);
  return taban.copyWith(
    pendingEvent: null,
    notices: const <PendingNotice>[],
    // Üretimden gelen hayvan testi bulandırmasın; her test kendi
    // hayvanını kurar.
    pets: const <Pet>[],
    player: taban.player.copyWith(age: age, wallet: wallet),
  );
}

GameState sahiplen(
  GameState state, {
  PetSpecies species = PetSpecies.kedi,
  String name = 'Boncuk',
}) {
  final ({GameState state, bool applied, String text}) sonuc = PetCare.adopt(
    state: state,
    species: species,
    name: name,
    rng: Random(1),
  );
  expect(sonuc.applied, isTrue, reason: sonuc.text);
  return sonuc.state;
}

Pet tek(GameState state) => state.pets.single;

void main() {
  group('Sahiplenme', () {
    test('hayvan gerçek bir kimlikle kayda girer', () {
      final GameState s = sahiplen(hayat());
      final Pet pet = tek(s);
      expect(pet.name, 'Boncuk');
      expect(pet.species, PetSpecies.kedi.id);
      expect(pet.age, 0);
      expect(pet.adoptedAtPlayerAge, 20);
      expect(pet.isAlive, isTrue);
      expect(pet.inPlayerHousehold, isTrue);
    });

    test('sahiplenme ücreti bir kez alınır', () {
      final GameState once = hayat();
      final GameState sonra = sahiplen(once);
      expect(
        sonra.player.wallet,
        once.player.wallet - PetSpecies.kedi.adoptionCost,
      );
    });

    test('adı boş bırakılırsa gerçek bir ad seçilir', () {
      final GameState s = sahiplen(hayat(), name: '   ');
      expect(tek(s).name.trim(), isNotEmpty);
      expect(kPetSuggestedNames, contains(tek(s).name));
    });

    test('parası yetmeyen sahiplenemez ve kayıt oluşmaz', () {
      final GameState fakir = hayat(wallet: 10);
      final ({GameState state, bool applied, String text}) sonuc =
          PetCare.adopt(
        state: fakir,
        species: PetSpecies.kopek,
        name: 'Karabaş',
        rng: Random(1),
      );
      expect(sonuc.applied, isFalse);
      expect(sonuc.state.pets, isEmpty);
      expect(sonuc.state.player.wallet, fakir.player.wallet);
    });

    test('küçük çocuk hayvan sahiplenemez', () {
      expect(
        PetCare.adoptionAvailability(hayat(age: 4), PetSpecies.kedi).isAllowed,
        isFalse,
      );
    });

    test('tür listesi genişledi ama balık gibi türler dışarıda kalmadı',
        () {
      // D-082, D-058'in "yalnızca kedi ve köpek" hükmünü değiştirdi:
      // Faho muhabbet kuşu, papağan, kanarya, timsah gibi türleri
      // istedi. Test artık tam listeyi değil, **kuralı** sabitliyor.
      final Set<String> sahiplenilebilir =
          adoptablePetSpecies.map((PetSpecies s) => s.id).toSet();
      expect(sahiplenilebilir, contains('kedi'));
      expect(sahiplenilebilir, contains('köpek'));
      expect(sahiplenilebilir, contains('muhabbet kuşu'));
      expect(sahiplenilebilir, contains('papağan'));
      expect(sahiplenilebilir, contains('kanarya'));
      expect(sahiplenilebilir.length, greaterThanOrEqualTo(8));
    });

    test('özel izin gerektiren tür açıkça uyarı taşır', () {
      // Timsah gerçek hayatta sıradan bir evcil hayvan değildir; oyun
      // bunu normal bir tercih gibi sunmaz (D-082).
      final Iterable<PetSpecies> izinliler = PetSpecies.values
          .where((PetSpecies s) => s.requiresPermit);
      expect(izinliler, isNotEmpty);
      for (final PetSpecies s in izinliler) {
        expect(s.warning, isNotNull, reason: '${s.label} uyarısız');
        expect(s.warning!.length, greaterThan(30), reason: s.label);
      }
    });

    test('aynı hayvan iki kez oluşturulmaz: her sahiplenme ayrı kimlik', () {
      GameState s = sahiplen(hayat(), name: 'Boncuk');
      s = sahiplen(s, species: PetSpecies.kopek, name: 'Karabaş');
      expect(s.pets, hasLength(2));
      expect(s.pets[0].id, isNot(s.pets[1].id));
    });

    test('evde bakılabilecek hayvan sayısı sınırlı', () {
      GameState s = hayat(wallet: 5000000);
      for (int i = 0; i < PetCare.prototypeOnlyMaxLivingPets; i++) {
        s = sahiplen(s, name: 'Hayvan$i');
      }
      expect(
        PetCare.adoptionAvailability(s, PetSpecies.kedi).isAllowed,
        isFalse,
      );
    });
  });

  group('Etkileşimler', () {
    test('dört etkileşim de gerçekten çalışır', () {
      GameState s = sahiplen(hayat(wallet: 200000));
      for (final PetAction eylem in PetAction.values) {
        final ({GameState state, bool applied, String text}) sonuc =
            PetCare.interact(
          state: s,
          pet: tek(s),
          action: eylem,
          rng: Random(3),
        );
        expect(sonuc.applied, isTrue, reason: '${eylem.id}: ${sonuc.text}');
        expect(sonuc.text, isNotEmpty);
        expect(sonuc.text, isNot(contains('{ad}')));
        s = sonuc.state;
      }
      expect(tek(s).bond, greaterThan(50));
    });

    test('yıllık kota dolunca etkileşim kapanır: sınırsız kasılamaz', () {
      GameState s = sahiplen(hayat(wallet: 200000));
      const PetAction eylem = PetAction.oyunOyna;
      for (int i = 0; i < eylem.maxPerAge; i++) {
        s = PetCare.interact(
          state: s,
          pet: tek(s),
          action: eylem,
          rng: Random(i),
        ).state;
      }
      final int mutluluk = s.player.stats.happiness;
      final ({GameState state, bool applied, String text}) fazla =
          PetCare.interact(
        state: s,
        pet: tek(s),
        action: eylem,
        rng: Random(9),
      );
      expect(fazla.applied, isFalse);
      expect(fazla.state.player.stats.happiness, mutluluk);
    });

    test('aynı yıl tekrar edildikçe kazanç azalır', () {
      GameState s = sahiplen(hayat(wallet: 200000));
      const PetAction eylem = PetAction.vakitGecir;
      final List<int> kazanclar = <int>[];
      for (int i = 0; i < eylem.maxPerAge; i++) {
        final int once = s.player.stats.happiness;
        s = PetCare.interact(
          state: s,
          pet: tek(s),
          action: eylem,
          rng: Random(i),
        ).state;
        kazanclar.add(s.player.stats.happiness - once);
      }
      expect(kazanclar.first, greaterThanOrEqualTo(kazanclar.last));
    });

    test('parası yetmeyen ücretli etkileşimi yapamaz, cüzdan eksiye inmez', () {
      GameState s = sahiplen(hayat(wallet: PetSpecies.kedi.adoptionCost));
      final ({GameState state, bool applied, String text}) sonuc =
          PetCare.interact(
        state: s,
        pet: tek(s),
        action: PetAction.veteriner,
        rng: Random(1),
      );
      expect(sonuc.applied, isFalse);
      expect(sonuc.state.player.wallet, greaterThanOrEqualTo(0));
      s = sonuc.state;
      expect(s.player.wallet, 0);
    });

    test('vefat etmiş hayvanla etkileşim kurulamaz', () {
      final GameState s = sahiplen(hayat());
      final Pet olu = tek(s).copyWith(diedAtAge: 14, diedAtPlayerAge: 34);
      for (final PetAction eylem in PetAction.values) {
        expect(
          PetCare.availability(s, olu, eylem).isAllowed,
          isFalse,
          reason: eylem.id,
        );
      }
    });
  });

  group('Yıllık bakım gideri', () {
    test('yılda yalnızca bir kez alınır', () {
      GameState s = sahiplen(hayat(wallet: 300000));
      // Sahiplenme yılının gideri sahiplenme ücretine dahildir.
      final int cuzdan = s.player.wallet;
      s = PetCare.advanceYear(s, 21, Random(1));
      expect(s.player.wallet, cuzdan - PetSpecies.kedi.yearlyCareCost);

      // Aynı yaş yeniden işlenirse ikinci kez alınmaz.
      final int sonra = s.player.wallet;
      s = PetCare.advanceYear(s, 21, Random(2));
      expect(s.player.wallet, sonra);
    });

    test('sahiplenilen yılda ikinci kez gider alınmaz', () {
      final GameState s = sahiplen(hayat(wallet: 300000));
      final int cuzdan = s.player.wallet;
      final GameState sonra = PetCare.advanceYear(s, 20, Random(1));
      expect(sonra.player.wallet, cuzdan);
    });

    test('parasız oyuncunun cüzdanı eksiye düşmez ve hayvan ölmez', () {
      GameState s = sahiplen(hayat(wallet: PetSpecies.kedi.adoptionCost));
      expect(s.player.wallet, 0);
      for (int yas = 21; yas <= 30; yas++) {
        s = PetCare.advanceYear(s, yas, Random(yas));
        expect(s.player.wallet, greaterThanOrEqualTo(0));
      }
      expect(
        tek(s).isAlive,
        isTrue,
        reason: 'Hayvan parasızlıktan ölmemeli',
      );
      expect(tek(s).age, 10);
    });

    test('hayvan yoksa hiçbir gider yazılmaz', () {
      final GameState s = hayat();
      final GameState sonra = PetCare.advanceYear(s, 21, Random(1));
      expect(sonra.player.wallet, s.player.wallet);
      expect(sonra.log.length, s.log.length);
    });

    test('yıl ilerlerken gider hayat akışında da bir kez alınır', () {
      final GameState s = sahiplen(hayat(age: 30, wallet: 400000));
      final int cuzdan = s.player.wallet;
      final GameState sonra =
          LifeProgression(Random(5)).advanceOneYear(s.copyWith(
        // Maaş ve geçim gideri karışmasın diye yalnızca hayvan gideri
        // kalsın istiyoruz; geçim gideri ayrıca ölçülür.
        pendingEvent: null,
      ));
      expect(
        cuzdan - sonra.player.wallet,
        greaterThanOrEqualTo(PetSpecies.kedi.yearlyCareCost),
      );
      expect(sonra.pets.single.age, 1);
    });
  });

  group('Yaşlanma ve vefat', () {
    test('hayvan her yıl bir yaş alır', () {
      GameState s = sahiplen(hayat(wallet: 5000000));
      for (int yas = 21; yas <= 25; yas++) {
        s = PetCare.advanceYear(s, yas, Random(yas));
      }
      expect(tek(s).age, 5);
      expect(tek(s).isAlive, isTrue);
    });

    test('üst sınırı geçen hayvan mutlaka vefat eder', () {
      GameState s = sahiplen(hayat(wallet: 50000000));
      s = s.copyWith(
        pets: <Pet>[tek(s).copyWith(age: PetSpecies.kedi.maxLifespan)],
      );
      s = PetCare.advanceYear(s, 40, Random(1));
      expect(tek(s).isAlive, isFalse);
    });

    test('vefat kaydı silinmez, işaretlenir', () {
      GameState s = sahiplen(hayat(wallet: 50000000), name: 'Tekir');
      s = s.copyWith(
        pets: <Pet>[tek(s).copyWith(age: PetSpecies.kedi.maxLifespan)],
      );
      s = PetCare.advanceYear(s, 40, Random(1));
      final Pet pet = tek(s);
      expect(s.pets, hasLength(1), reason: 'Kayıt silinmemeli');
      expect(pet.name, 'Tekir');
      expect(pet.diedAtAge, PetSpecies.kedi.maxLifespan + 1);
      expect(pet.diedAtPlayerAge, 40);
    });

    test('vefat bildirimi ve gerçek mutluluk düşüşü olur', () {
      GameState s = sahiplen(hayat(wallet: 50000000), name: 'Duman');
      s = s.copyWith(
        pets: <Pet>[tek(s).copyWith(age: PetSpecies.kedi.maxLifespan)],
      );
      final int mutluluk = s.player.stats.happiness;
      s = PetCare.advanceYear(s, 40, Random(1));

      expect(s.player.stats.happiness, lessThan(mutluluk));
      final PendingNotice bildirim = s.notices.last;
      expect(bildirim.kind, NoticeKind.hayvan);
      expect(bildirim.title, contains('Duman'));
      expect(bildirim.age, 40);
      expect(
        s.log.any((LifeLogEntry e) => e.text.contains('Duman')),
        isTrue,
      );
    });

    test('vefat eden hayvan bir daha gider yazmaz ve yaşlanmaz', () {
      GameState s = sahiplen(hayat(wallet: 50000000));
      s = s.copyWith(
        pets: <Pet>[tek(s).copyWith(age: PetSpecies.kedi.maxLifespan)],
      );
      s = PetCare.advanceYear(s, 40, Random(1));
      final int cuzdan = s.player.wallet;
      final int olumYasi = tek(s).age;

      s = PetCare.advanceYear(s, 41, Random(2));
      expect(s.player.wallet, cuzdan);
      expect(tek(s).age, olumYasi);
    });

    test('genç hayvan yaşlılıktan ölmez', () {
      GameState s = sahiplen(hayat(wallet: 50000000));
      for (int i = 0; i < 200; i++) {
        final GameState deneme = PetCare.advanceYear(
          s.copyWith(pets: <Pet>[tek(s).copyWith(age: 2)]),
          30,
          Random(i),
        );
        expect(deneme.pets.single.isAlive, isTrue);
      }
    });
  });

  group('Kuşak değişimi', () {
    test('aynı hanedeki hayvan kimliğiyle devam eder, yenisi uydurulmaz', () {
      final GameState olen = olenOyuncu().copyWith(
        pets: <Pet>[
          const Pet(
            id: 'hayvan-1',
            name: 'Zeytin',
            species: 'kedi',
            age: 4,
            adoptedAtPlayerAge: 30,
          ),
        ],
      );
      final ({GameState? state, String blockReason}) sonuc =
          GenerationContinuation.continueAs(olen, 'cocuk-1', Random(3));
      expect(sonuc.blockReason, isEmpty);
      final GameState yeni = sonuc.state!;

      expect(yeni.pets, hasLength(1));
      expect(yeni.pets.single.id, 'hayvan-1');
      expect(yeni.pets.single.name, 'Zeytin');
      expect(yeni.pets.single.age, 4, reason: 'Yaş sıfırlanmamalı');
    });

    test('vefat etmiş hayvan yeni kuşağa taşınmaz', () {
      final GameState olen = olenOyuncu().copyWith(
        pets: <Pet>[
          const Pet(
            id: 'hayvan-1',
            name: 'Paşa',
            species: 'köpek',
            age: 15,
            diedAtAge: 15,
            diedAtPlayerAge: 60,
          ),
        ],
      );
      final GameState yeni =
          GenerationContinuation.continueAs(olen, 'cocuk-1', Random(3)).state!;
      expect(yeni.pets, isEmpty);
    });

    test('hanede olmayan hayvan taşınmaz: miras kalemi değildir', () {
      final GameState olen = olenOyuncu().copyWith(
        pets: <Pet>[
          const Pet(
            id: 'hayvan-1',
            name: 'Fındık',
            species: 'kedi',
            age: 3,
            inPlayerHousehold: false,
          ),
        ],
      );
      final GameState yeni =
          GenerationContinuation.continueAs(olen, 'cocuk-1', Random(3)).state!;
      expect(yeni.pets, isEmpty);
    });

    test('devam eden hayvanın gideri yeni kuşakta bir kez alınır', () {
      final GameState olen = olenOyuncu().copyWith(
        pets: <Pet>[
          const Pet(
            id: 'hayvan-1',
            name: 'Zeytin',
            species: 'kedi',
            age: 4,
            adoptedAtPlayerAge: 30,
            lastCareChargedPlayerAge: 60,
          ),
        ],
      );
      GameState yeni =
          GenerationContinuation.continueAs(olen, 'cocuk-1', Random(3)).state!;
      yeni = yeni.copyWith(
        player: yeni.player.copyWith(wallet: 300000),
      );
      final int cuzdan = yeni.player.wallet;
      final int yas = yeni.player.age + 1;

      yeni = PetCare.advanceYear(yeni, yas, Random(1));
      expect(yeni.player.wallet, cuzdan - PetSpecies.kedi.yearlyCareCost);

      final int sonra = yeni.player.wallet;
      yeni = PetCare.advanceYear(yeni, yas, Random(1));
      expect(yeni.player.wallet, sonra, reason: 'İkinci kez alınmamalı');
    });
  });

  group('Kayıt', () {
    test('hayvan kaydı gidip gelince aynen korunur', () {
      GameState s = sahiplen(hayat(wallet: 300000), name: 'Mırmır');
      s = PetCare.advanceYear(s, 21, Random(1));
      final Pet once = tek(s);
      final Pet sonra = tek(decodeGameState(encodeGameState(s)));

      expect(sonra.id, once.id);
      expect(sonra.name, once.name);
      expect(sonra.species, once.species);
      expect(sonra.age, once.age);
      expect(sonra.adoptedAtPlayerAge, once.adoptedAtPlayerAge);
      expect(sonra.lastCareChargedPlayerAge, once.lastCareChargedPlayerAge);
      expect(sonra.bond, once.bond);
      expect(sonra.isAlive, isTrue);
    });

    test('vefat kaydı da gidip gelir', () {
      GameState s = sahiplen(hayat(wallet: 50000000), name: 'Kömür');
      s = s.copyWith(
        pets: <Pet>[tek(s).copyWith(age: PetSpecies.kedi.maxLifespan)],
      );
      s = PetCare.advanceYear(s, 40, Random(1));
      final Pet sonra = tek(decodeGameState(encodeGameState(s)));
      expect(sonra.isAlive, isFalse);
      expect(sonra.diedAtAge, tek(s).diedAtAge);
      expect(sonra.diedAtPlayerAge, 40);
    });

    test('eski kayıttaki hayvan alanları varsayılanla okunur', () {
      final GameState s = sahiplen(hayat());
      final Map<String, Object?> json =
          Map<String, Object?>.from(encodeGameState(s));
      final List<Object?> hayvanlar = json['pets']! as List<Object?>;
      final Map<String, Object?> eski =
          Map<String, Object?>.from(hayvanlar.single! as Map<String, Object?>)
            ..remove('age')
            ..remove('adoptedAtPlayerAge')
            ..remove('inPlayerHousehold')
            ..remove('diedAtAge')
            ..remove('diedAtPlayerAge')
            ..remove('lastCareChargedPlayerAge')
            ..remove('bond');
      json['pets'] = <Object?>[eski];

      final Pet pet = tek(decodeGameState(json));
      expect(pet.age, 0);
      expect(pet.isAlive, isTrue);
      expect(pet.inPlayerHousehold, isTrue);
      expect(pet.adoptedAtPlayerAge, isNull);
    });
  });

  group('Olaylar', () {
    test('en az beş hayvan olayı var ve kimlikleri benzersiz', () {
      expect(kPetEvents.length, greaterThanOrEqualTo(5));
      expect(
        kPetEvents.map((GameEvent e) => e.id).toSet().length,
        kPetEvents.length,
      );
    });

    test('hayvan olayları ana havuza kayıtlı', () {
      for (final GameEvent e in kPetEvents) {
        expect(kEventPool.any((GameEvent x) => x.id == e.id), isTrue,
            reason: e.id);
      }
    });

    test('her olay yaşayan hayvan şartı taşır ve iki seçeneği vardır', () {
      for (final GameEvent e in kPetEvents) {
        expect(e.requirement.requiresLivingPet, isTrue, reason: e.id);
        expect(e.choices.length, greaterThanOrEqualTo(2), reason: e.id);
      }
    });

    test('hayvanı olmayana hiçbir hayvan olayı çıkmaz', () {
      const EventEngine motor = EventEngine();
      final Set<String> hayvanOlaylari =
          kPetEvents.map((GameEvent e) => e.id).toSet();
      for (int yas = 10; yas <= 70; yas += 5) {
        final Set<String> cikabilir =
            motor.debugEligibleIds(hayat(age: yas), Random(yas));
        expect(cikabilir.intersection(hayvanOlaylari), isEmpty,
            reason: '$yas yaşında hayvansız oyuncuya hayvan olayı çıktı');
      }
    });

    test('vefat etmiş hayvan olay için sayılmaz', () {
      const EventEngine motor = EventEngine();
      GameState s = sahiplen(hayat(age: 30));
      s = s.copyWith(
        pets: <Pet>[tek(s).copyWith(diedAtAge: 14, diedAtPlayerAge: 30)],
        seenEventIds: const <String>{},
      );
      final GameEvent kayip = kPetEvents
          .firstWhere((GameEvent e) => e.id == 'hayvan_kayboldu');
      expect(motor.debugMatches(s, kayip), isFalse);
    });

    test('yaşayan hayvanı olana çıkar ve gerçek adla doldurulur', () {
      const EventEngine motor = EventEngine();
      GameState s = sahiplen(hayat(age: 30), name: 'Leblebi');
      s = s.copyWith(seenEventIds: const <String>{});
      final GameEvent kayip = kPetEvents
          .firstWhere((GameEvent e) => e.id == 'hayvan_kayboldu');
      expect(motor.debugMatches(s, kayip), isTrue);

      // Havuzdan gerçekten çıkabildiğinde metinde yer tutucu kalmamalı.
      bool goruldu = false;
      for (int i = 0; i < 600 && !goruldu; i++) {
        final ActiveEvent? olay = motor.openingEvent(s, Random(i));
        if (olay?.eventId == 'hayvan_kayboldu') {
          goruldu = true;
          expect(olay!.text, contains('Leblebi'));
          expect(olay.text, isNot(contains('{hayvan}')));
        }
      }
      expect(goruldu, isTrue, reason: 'Olay hiç çıkmadı');
    });

    test('yaşlı hayvan olayı genç hayvana çıkmaz', () {
      const EventEngine motor = EventEngine();
      final GameEvent yasli =
          kPetEvents.firstWhere((GameEvent e) => e.id == 'hayvan_yaslandi');
      GameState genc = sahiplen(hayat(age: 30));
      genc = genc.copyWith(seenEventIds: const <String>{});
      expect(motor.debugMatches(genc, yasli), isFalse);

      final GameState yaslandi = genc.copyWith(
        pets: <Pet>[tek(genc).copyWith(age: 12)],
      );
      expect(motor.debugMatches(yaslandi, yasli), isTrue);
    });

    test('uzun birliktelik olayı yeni sahiplenene çıkmaz', () {
      const EventEngine motor = EventEngine();
      final GameEvent dost = kPetEvents
          .firstWhere((GameEvent e) => e.id == 'hayvan_yillarin_dostu');
      GameState yeni = sahiplen(hayat(age: 30));
      yeni = yeni.copyWith(seenEventIds: const <String>{});
      expect(motor.debugMatches(yeni, dost), isFalse);

      final GameState eski = yeni.copyWith(
        player: yeni.player.copyWith(age: 40),
        pets: <Pet>[tek(yeni).copyWith(age: 10)],
      );
      expect(motor.debugMatches(eski, dost), isTrue);
    });
  });
}

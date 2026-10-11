// Paket AO — Aile / İlişkiler V2: dinamik aile ağı.
//
// Bu dosya §48'in istediği hedefli testleri taşır. Genel 3000 hayat
// denetimi **yok**; her test tek bir davranışı ürünün kendi API'lerinden
// doğrular.
//
// ignore_for_file: avoid_print
library;

import 'dart:math';

import 'package:bir_omur/data/save/game_state_codec.dart';
import 'package:bir_omur/domain/generation/in_laws.dart';
import 'package:bir_omur/domain/generation/life_generator.dart';
import 'package:bir_omur/domain/generation/parent_divorce.dart';
import 'package:bir_omur/domain/generation/step_parents.dart';
import 'package:bir_omur/domain/generation/step_siblings.dart';
import 'package:bir_omur/domain/interaction/elder_care.dart';
import 'package:bir_omur/domain/interaction/family_interactions.dart';
import 'package:bir_omur/domain/interaction/interaction_policy.dart';
import 'package:bir_omur/domain/life/inheritance.dart';
import 'package:bir_omur/domain/models/game_state.dart';
import 'package:bir_omur/domain/models/gender.dart';
import 'package:bir_omur/domain/models/interaction.dart';
import 'package:bir_omur/domain/models/kinship.dart';
import 'package:bir_omur/domain/models/marriage.dart';
import 'package:bir_omur/domain/models/parental_status.dart';
import 'package:bir_omur/domain/models/person.dart';
import 'package:bir_omur/domain/models/relation.dart';
import 'package:bir_omur/domain/models/wealth.dart';
import 'package:flutter_test/flutter_test.dart';

/// Anne ve babası hayatta, birlikte, oyuncunun hanesinde olan bir hayat.
GameState aileliHayat({int seed = 7, int age = 10}) {
  final GameState s =
      LifeGenerator.seeded(seed).generate(mode: StartMode.tamamenRastgele);
  final List<Person> kisiler = <Person>[];
  bool anneVar = false;
  bool babaVar = false;
  for (final Person p in s.people) {
    if (p.relation == RelationType.anne) {
      anneVar = true;
      kisiler.add(p.copyWith(
        isAlive: true,
        inPlayerHousehold: true,
        age: age + 28,
        bond: 60,
        wealth: WealthTier.ortaHalli,
      ));
    } else if (p.relation == RelationType.baba) {
      babaVar = true;
      kisiler.add(p.copyWith(
        isAlive: true,
        inPlayerHousehold: true,
        age: age + 31,
        bond: 55,
        wealth: WealthTier.ortaHalli,
      ));
    } else {
      kisiler.add(p);
    }
  }
  expect(anneVar && babaVar, isTrue,
      reason: 'Kurulum: bu tohumda anne ve baba yok.');
  return s.copyWith(
    player: s.player.copyWith(age: age),
    pendingEvent: null,
    parentalStatus: ParentalStatus.evli,
    people: List<Person>.unmodifiable(kisiler),
  );
}

Person? kisi(GameState s, RelationType tur) {
  for (final Person p in s.people) {
    if (p.relation == tur) return p;
  }
  return null;
}

/// Boşanma kesin olsun diye: dayanıklılık düşük olsa bile zar tutmayabilir,
/// o yüzden çok sayıda tohum denenir. Hiçbirinde olmuyorsa mekanik ölüdür.
GameState bosandir(GameState taban, {int yas = 12}) {
  for (int seed = 0; seed < 400; seed++) {
    final GameState sonra =
        ParentDivorce.maybeDivorce(taban, yas, Random(seed));
    if (sonra.parentalStatus == ParentalStatus.bosanmis) return sonra;
  }
  fail('400 denemede hiç boşanma olmadı: mekanik ölü.');
}

void main() {
  // =================================================================
  // §1-§6 — PARENT DIVORCE
  // =================================================================
  group('AO parent divorce', () {
    test('anne/baba birlikteyken boşanabiliyor', () {
      final GameState s = bosandir(aileliHayat());
      expect(s.parentalStatus, ParentalStatus.bosanmis);
    });

    test('boşanma düz bir oran değil: aileden aileye değişiyor (§1)', () {
      // Aynı kurulumda yalnızca ebeveyn kimlikleri ve refahı değişince
      // dayanıklılık da değişmeli. Hepsi aynı çıkıyorsa sabit oran
      // uygulanıyor demektir.
      final Set<String> degerler = <String>{};
      for (int seed = 0; seed < 25; seed++) {
        degerler.add(
          ParentDivorce.resilience(aileliHayat(seed: seed))
              .toStringAsFixed(3),
        );
      }
      expect(degerler.length, greaterThan(5),
          reason: '§1: bütün aileler aynı dayanıklılıkta — düz oran.');
    });

    test('her hayat boşanmayla bitmiyor', () {
      int bosanan = 0;
      for (int seed = 0; seed < 60; seed++) {
        GameState s = aileliHayat(seed: seed, age: 5);
        final Random rng = Random(seed);
        for (int yas = 5; yas <= 25; yas++) {
          s = ParentDivorce.maybeDivorce(s, yas, rng);
        }
        if (s.parentalStatus == ParentalStatus.bosanmis) bosanan++;
      }
      print('-- §1: 60 ailede boşanan $bosanan --');
      expect(bosanan, greaterThan(0), reason: 'Hiç boşanma yok: mekanik ölü.');
      expect(bosanan, lessThan(55),
          reason: '§1: neredeyse her aile dağılıyor.');
    });

    test('iki ebeveyn de listede kalıyor, kimse silinmiyor (§2)', () {
      final GameState once = aileliHayat();
      final GameState sonra = bosandir(once);
      expect(kisi(sonra, RelationType.anne), isNotNull);
      expect(kisi(sonra, RelationType.baba), isNotNull);
      expect(kisi(sonra, RelationType.anne)!.isAlive, isTrue);
      expect(kisi(sonra, RelationType.baba)!.isAlive, isTrue);
      expect(sonra.people.length, once.people.length,
          reason: '§2: boşanma kimseyi listeden silmemeli.');
    });

    test('hane ayrılıyor: iki ebeveyn aynı evde kalmıyor (§3)', () {
      final GameState s = bosandir(aileliHayat());
      final bool anneEvde = kisi(s, RelationType.anne)!.inPlayerHousehold;
      final bool babaEvde = kisi(s, RelationType.baba)!.inPlayerHousehold;
      expect(anneEvde && babaEvde, isFalse,
          reason: '§3: boşanma sonrası ikisi de aynı hanede.');
      expect(anneEvde || babaEvde, isTrue,
          reason: '§4: çocuk bir ebeveynle kalmalı.');
    });

    test('küçük çocuğa seçim sorulmuyor, büyüğe soruluyor (§4)', () {
      final GameState kucuk = bosandir(aileliHayat(age: 7), yas: 7);
      expect(ParentDivorce.isPending(kucuk), isFalse,
          reason: '§4: 7 yaşındaki çocuğa bu karar sorulmaz.');

      final GameState buyuk = bosandir(aileliHayat(age: 16), yas: 16);
      expect(ParentDivorce.isPending(buyuk), isTrue,
          reason: '§4: 16 yaşında seçim sorulmalı.');
    });

    test('seçim gerçekten haneyi değiştiriyor (§4)', () {
      final GameState s = bosandir(aileliHayat(age: 16), yas: 16);
      final GameState anneyle =
          ParentDivorce.choose(s, DivorceHouseholdChoice.anne);
      expect(kisi(anneyle, RelationType.anne)!.inPlayerHousehold, isTrue);
      expect(kisi(anneyle, RelationType.baba)!.inPlayerHousehold, isFalse);
      expect(ParentDivorce.isPending(anneyle), isFalse);

      final GameState babayla =
          ParentDivorce.choose(s, DivorceHouseholdChoice.baba);
      expect(kisi(babayla, RelationType.baba)!.inPlayerHousehold, isTrue);
      expect(kisi(babayla, RelationType.anne)!.inPlayerHousehold, isFalse);
    });

    test('mutluluk etkisi yaşa göre değişiyor, sabit değil (§5)', () {
      int etki(int yas) {
        final GameState once = aileliHayat(age: yas);
        final GameState sonra = bosandir(once, yas: yas);
        return once.player.stats.happiness - sonra.player.stats.happiness;
      }

      final int kucuk = etki(6);
      final int ergen = etki(16);
      final int yetiskin = etki(30);
      print('-- §5: mutluluk kaybı — 6 yaş $kucuk / 16 yaş $ergen / '
          '30 yaş $yetiskin --');
      expect(kucuk, greaterThan(yetiskin),
          reason: '§5: etki sabit; yaşa göre değişmiyor.');
      expect(ergen, greaterThan(yetiskin));
      expect(yetiskin, greaterThan(0),
          reason: '§5: yetişkin için de bu bir olaydır.');
    });

    test('popup ve günlük gerçek (§6)', () {
      final GameState s = bosandir(aileliHayat(age: 14), yas: 14);
      expect(
        s.log.any((dynamic e) => e.text.contains('ayrıldı')),
        isTrue,
        reason: '§6: günlüğe gerçek sonuç yazılmalı.',
      );
      expect(s.notices.isNotEmpty, isTrue,
          reason: '§6: aile dönümü popup olarak gelmeli.');
    });

    test('bir kez boşanan aile tekrar boşanmıyor', () {
      GameState s = bosandir(aileliHayat());
      for (int i = 0; i < 50; i++) {
        s = ParentDivorce.maybeDivorce(s, 20 + i % 20, Random(i));
      }
      expect(s.parentalStatus, ParentalStatus.bosanmis);
    });
  });

  // =================================================================
  // §7, §8 — REMARRIAGE
  // =================================================================
  group('AO remarriage', () {
    /// Boşanmış aileyi yeniden evlendirene kadar dener.
    GameState evlendir(GameState taban, {int yas = 20}) {
      for (int seed = 0; seed < 600; seed++) {
        final GameState s = StepParents.maybeRemarry(taban, yas, Random(seed));
        if (kisi(s, RelationType.uveyAnne) != null ||
            kisi(s, RelationType.uveyBaba) != null) {
          return s;
        }
      }
      fail('600 denemede yeniden evlenme olmadı.');
    }

    test('boşanma sonrası yeniden evlenilebiliyor (§7)', () {
      final GameState bosandi = bosandir(aileliHayat(age: 12), yas: 12);
      final GameState s = evlendir(bosandi);
      final bool uveyVar = kisi(s, RelationType.uveyAnne) != null ||
          kisi(s, RelationType.uveyBaba) != null;
      expect(uveyVar, isTrue);
    });

    test('iki tarafta da üvey ebeveyn mümkün (§8)', () {
      // Yeterince denemede hem üvey anne hem üvey baba görülmeli.
      final GameState bosandi = bosandir(aileliHayat(age: 10), yas: 10);
      bool uveyAnneGoruldu = false;
      bool uveyBabaGoruldu = false;
      for (int seed = 0; seed < 600; seed++) {
        final GameState s =
            StepParents.maybeRemarry(bosandi, 20, Random(seed));
        if (kisi(s, RelationType.uveyAnne) != null) uveyAnneGoruldu = true;
        if (kisi(s, RelationType.uveyBaba) != null) uveyBabaGoruldu = true;
        if (uveyAnneGoruldu && uveyBabaGoruldu) break;
      }
      expect(uveyAnneGoruldu, isTrue,
          reason: '§8: baba yeniden evlenemiyor.');
      expect(uveyBabaGoruldu, isTrue,
          reason: '§8: anne yeniden evlenemiyor.');
    });

    test('vefat sonrası eski yol bozulmadı', () {
      // Babası vefat etmiş, anne hayatta: eski (Paket V/7) davranış.
      GameState s = aileliHayat(age: 12);
      s = s.copyWith(
        people: List<Person>.unmodifiable(
          s.people.map((Person p) => p.relation == RelationType.baba
              ? p.copyWith(isAlive: false)
              : p),
        ),
      );
      bool geldi = false;
      for (int seed = 0; seed < 600 && !geldi; seed++) {
        final GameState sonra =
            StepParents.maybeRemarry(s, 20, Random(seed));
        if (kisi(sonra, RelationType.uveyBaba) != null) geldi = true;
      }
      expect(geldi, isTrue, reason: 'Vefat yolu bozulmuş.');
    });
  });

  // =================================================================
  // §9-§11 — STEP SIBLING
  // =================================================================
  group('AO step sibling', () {
    Person uveyEbeveyn({int age = 40, String id = 'uvey-test'}) => Person(
          id: id,
          firstName: 'Kerem',
          lastName: 'Yıldız',
          gender: Gender.erkek,
          relation: RelationType.uveyBaba,
          age: age,
          isAlive: true,
          inPlayerHousehold: true,
          employment: EmploymentStatus.calisiyor,
          occupation: 'Tesisatçı',
          wealth: WealthTier.ortaHalli,
          bond: 20,
        );

    test('0 çocuk en yaygın seçenek (§10)', () {
      final GameState s = aileliHayat();
      int sifir = 0;
      int toplam = 0;
      for (int seed = 0; seed < 300; seed++) {
        final List<Person> c = StepSiblings.childrenOf(
          state: s,
          stepParent: uveyEbeveyn(),
          playerAge: 12,
          rng: Random(seed),
        );
        if (c.isEmpty) sifir++;
        toplam += c.length;
      }
      print('-- §10: 300 üvey ebeveynden $sifir tanesi çocuksuz geldi, '
          'toplam $toplam çocuk --');
      expect(sifir, greaterThan(150),
          reason: '§10: çocuksuz gelmek en yaygın seçenek olmalı.');
      expect(sifir, lessThan(300),
          reason: '§10: hiç üvey kardeş gelmiyorsa mekanik ölü.');
    });

    test('1+ çocukla da gelebiliyor (§10)', () {
      final GameState s = aileliHayat();
      int enCok = 0;
      for (int seed = 0; seed < 300; seed++) {
        final List<Person> c = StepSiblings.childrenOf(
          state: s,
          stepParent: uveyEbeveyn(),
          playerAge: 12,
          rng: Random(seed),
        );
        if (c.length > enCok) enCok = c.length;
      }
      expect(enCok, greaterThanOrEqualTo(1));
      expect(enCok, lessThanOrEqualTo(2),
          reason: '§10: ikiden fazla üvey kardeş gelmemeli.');
    });

    test('genç üvey ebeveyne yetişkin çocuk üretilmiyor (§10, §43)', () {
      final GameState s = aileliHayat();
      for (int seed = 0; seed < 200; seed++) {
        final List<Person> c = StepSiblings.childrenOf(
          state: s,
          stepParent: uveyEbeveyn(age: 25),
          playerAge: 12,
          rng: Random(seed),
        );
        for (final Person k in c) {
          expect(k.age, lessThanOrEqualTo(25 - 18),
              reason: '§43: 25 yaşındaki ebeveyne ${k.age} yaşında çocuk.');
        }
      }
    });

    test('üvey kardeş kan bağı DEĞİL (§9)', () {
      expect(RelationType.uveyKardes.kanBagi, isFalse);
      expect(Kinship.isBloodRelative(RelationType.uveyKardes), isFalse);
    });

    test('üvey kardeşin biyolojik ebeveyni üvey ebeveyndir (§9, §14)', () {
      final GameState s = aileliHayat();
      List<Person> c = const <Person>[];
      for (int seed = 0; seed < 300 && c.isEmpty; seed++) {
        c = StepSiblings.childrenOf(
          state: s,
          stepParent: uveyEbeveyn(),
          playerAge: 12,
          rng: Random(seed),
        );
      }
      expect(c, isNotEmpty, reason: 'Ölçüm kurulamadı.');
      for (final Person k in c) {
        expect(k.fatherId, 'uvey-test');
        expect(k.motherId, isNull);
        // Oyuncunun anne/babasıyla ortak ebeveyni yok.
        expect(k.biologicalParentIds.contains(kisi(s, RelationType.anne)!.id),
            isFalse);
      }
    });

    test('üvey kardeş romantik havuza giremez (§16)', () {
      expect(Kinship.isRomanceForbidden(RelationType.uveyKardes), isTrue);
      expect(Kinship.isRomanceForbidden(RelationType.uveyCocuk), isTrue);
      expect(Kinship.isRomanceForbidden(RelationType.uveyAnne), isTrue);
      expect(Kinship.isRomanceForbidden(RelationType.kayinvalide), isTrue);
      expect(Kinship.isRomanceForbidden(RelationType.kayinpeder), isTrue);
    });

    test('üvey kardeşin yakınlığı otomatik yüksek değil (§11)', () {
      final GameState s = aileliHayat();
      final List<int> baglar = <int>[];
      for (int seed = 0; seed < 300; seed++) {
        for (final Person k in StepSiblings.childrenOf(
          state: s,
          stepParent: uveyEbeveyn(),
          playerAge: 12,
          rng: Random(seed),
        )) {
          baglar.add(k.bond);
        }
      }
      expect(baglar, isNotEmpty);
      for (final int b in baglar) {
        expect(b, lessThan(50),
            reason: '§11: üvey kardeş 80 yakınlıkla başlamamalı.');
      }
      // Hepsi aynı değer değil: hesaplanıyor, sabit yazılmıyor.
      expect(baglar.toSet().length, greaterThan(3));
    });
  });

  // =================================================================
  // §12, §13 — HALF SIBLING
  // =================================================================
  group('AO half sibling', () {
    GameState uveyAnneliHayat() {
      final GameState s = aileliHayat(age: 14);
      final Person baba = kisi(s, RelationType.baba)!;
      return s.copyWith(
        parentalStatus: ParentalStatus.bosanmis,
        people: List<Person>.unmodifiable(<Person>[
          ...s.people,
          Person(
            id: 'uvey-anne-1',
            firstName: 'Nehir',
            lastName: baba.lastName,
            gender: Gender.kadin,
            relation: RelationType.uveyAnne,
            age: 36,
            isAlive: true,
            inPlayerHousehold: true,
            employment: EmploymentStatus.calisiyor,
            occupation: 'Öğretmen',
            wealth: WealthTier.ortaHalli,
            bond: 25,
          ),
        ]),
      );
    }

    GameState dogur(GameState taban) {
      for (int seed = 0; seed < 400; seed++) {
        final GameState s =
            StepSiblings.maybeHalfSibling(taban, 15, Random(seed));
        if (kisi(s, RelationType.yariKardes) != null) return s;
      }
      fail('400 denemede yarım kardeş doğmadı.');
    }

    test('yeni doğum gerçek Person (§13)', () {
      final GameState s = dogur(uveyAnneliHayat());
      final Person bebek = kisi(s, RelationType.yariKardes)!;
      expect(bebek.age, 0);
      expect(bebek.isAlive, isTrue);
      expect(bebek.id, isNotEmpty);
      expect(bebek.firstName, isNotEmpty);
    });

    test('ortak biyolojik ebeveyn belli (§13, §14)', () {
      final GameState taban = uveyAnneliHayat();
      final GameState s = dogur(taban);
      final Person bebek = kisi(s, RelationType.yariKardes)!;
      final Person baba = kisi(s, RelationType.baba)!;
      // Baba ortak: üvey **anne**den doğduğu için.
      expect(bebek.fatherId, baba.id);
      expect(bebek.motherId, 'uvey-anne-1');
      // Annesiyle ortak değil.
      expect(bebek.motherId, isNot(kisi(s, RelationType.anne)!.id));
    });

    test('yarım kardeş kan bağı (§12)', () {
      expect(RelationType.yariKardes.kanBagi, isTrue);
      expect(Kinship.isBloodRelative(RelationType.yariKardes), isTrue);
      expect(Kinship.isRomanceForbidden(RelationType.yariKardes), isTrue);
    });

    test('yarım kardeş ortak ebeveynin mirasına giriyor (§17)', () {
      final GameState s = dogur(uveyAnneliHayat());
      final Person baba = kisi(s, RelationType.baba)!;
      final heirs = Inheritance.heirsFor(s, baba);
      final bool yarimVar = heirs.others
          .any((Person p) => p.relation == RelationType.yariKardes);
      expect(yarimVar, isTrue,
          reason: '§17: yarım kardeş ortak ebeveynin mirasçısı.');
    });

    test('üvey kardeş mirasçı değil (§17)', () {
      final GameState s = aileliHayat();
      final Person uveyKardes = Person(
        id: 'uk-1',
        firstName: 'Deniz',
        lastName: 'Ak',
        gender: Gender.kadin,
        relation: RelationType.uveyKardes,
        age: 15,
        isAlive: true,
        inPlayerHousehold: true,
        employment: EmploymentStatus.ogrenci,
        wealth: null,
        bond: 30,
      );
      final GameState ile = s.copyWith(
        people: List<Person>.unmodifiable(<Person>[...s.people, uveyKardes]),
      );
      final heirs = Inheritance.heirsFor(ile, uveyKardes);
      expect(heirs.playerIsHeir, isFalse,
          reason: '§17: üvey kardeş biyolojik mirasçı değil.');
    });
  });

  // =================================================================
  // §18-§20 — STEPCHILD
  // =================================================================
  group('AO stepchild', () {
    Person es({int age = 34}) => Person(
          id: 'es-1',
          firstName: 'Selin',
          lastName: 'Kaya',
          gender: Gender.kadin,
          relation: RelationType.es,
          age: age,
          isAlive: true,
          inPlayerHousehold: true,
          employment: EmploymentStatus.calisiyor,
          occupation: 'Mimar',
          wealth: WealthTier.ortaHalli,
          bond: 80,
        );

    test('her partnerin otomatik geçmiş çocuğu yok (§18)', () {
      final GameState s = aileliHayat(age: 30);
      int olan = 0;
      for (int seed = 0; seed < 300; seed++) {
        if (InLaws.stepChildOf(state: s, spouse: es(), rng: Random(seed)) !=
            null) {
          olan++;
        }
      }
      print('-- §18: 300 eşten $olan tanesinin önceki çocuğu var --');
      expect(olan, greaterThan(0), reason: 'Mekanik ölü.');
      expect(olan, lessThan(150),
          reason: '§18: her eşin geçmiş çocuğu olmamalı.');
    });

    test('genç eşe yetişkin çocuk üretilmiyor (§43)', () {
      final GameState s = aileliHayat(age: 30);
      for (int seed = 0; seed < 300; seed++) {
        final Person? c =
            InLaws.stepChildOf(state: s, spouse: es(age: 27), rng: Random(seed));
        if (c != null) {
          expect(c.age, lessThanOrEqualTo(27 - 18));
        }
      }
    });

    test('üvey çocuk gerçek Person ve biyolojik çocuk değil (§18, §20)', () {
      final GameState s = aileliHayat(age: 30);
      Person? c;
      for (int seed = 0; seed < 300 && c == null; seed++) {
        c = InLaws.stepChildOf(state: s, spouse: es(), rng: Random(seed));
      }
      expect(c, isNotNull);
      expect(c!.relation, RelationType.uveyCocuk);
      expect(c.motherId, 'es-1',
          reason: '§14: biyolojik ebeveyni eş olmalı.');
      expect(c.fatherId, isNull);
      expect(c.relation.kanBagi, isFalse,
          reason: '§17: üvey çocuk oyuncunun biyolojik çocuğu değil.');
      expect(c.bond, lessThan(40),
          reason: '§20: 90 yakınlıkla başlamamalı.');
    });

    test('aynı eş için ikinci kez üretilmiyor (§37)', () {
      GameState s = aileliHayat(age: 30);
      Person? c;
      for (int seed = 0; seed < 300 && c == null; seed++) {
        c = InLaws.stepChildOf(state: s, spouse: es(), rng: Random(seed));
      }
      s = s.copyWith(
        people: List<Person>.unmodifiable(<Person>[...s.people, c!]),
      );
      for (int seed = 0; seed < 200; seed++) {
        expect(InLaws.stepChildOf(state: s, spouse: es(), rng: Random(seed)),
            isNull,
            reason: '§37: aynı kişi ikinci kez üretilmemeli.');
      }
    });
  });

  // =================================================================
  // §21-§24 — IN-LAWS
  // =================================================================
  group('AO in-laws', () {
    Person es() => Person(
          id: 'es-9',
          firstName: 'Umut',
          lastName: 'Demir',
          gender: Gender.erkek,
          relation: RelationType.es,
          age: 32,
          isAlive: true,
          inPlayerHousehold: true,
          employment: EmploymentStatus.calisiyor,
          occupation: 'Mühendis',
          wealth: WealthTier.ortaHalli,
          bond: 80,
        );

    test('0-2 kayın üretiliyor, hepsi kesin hayatta değil (§21)', () {
      final GameState s = aileliHayat(age: 30);
      final Map<int, int> dagilim = <int, int>{};
      for (int seed = 0; seed < 300; seed++) {
        final int n =
            InLaws.parentsOfSpouse(state: s, spouse: es(), rng: Random(seed))
                .length;
        dagilim[n] = (dagilim[n] ?? 0) + 1;
      }
      print('-- §21: kayın sayısı dağılımı $dagilim --');
      expect(dagilim.keys.every((int k) => k <= 2), isTrue);
      expect(dagilim.containsKey(2), isTrue);
      expect(dagilim.keys.any((int k) => k < 2), isTrue,
          reason: '§21: hepsi kesin hayatta olmamalı.');
    });

    test('yaş eşin yaşıyla tutarlı (§43)', () {
      final GameState s = aileliHayat(age: 30);
      for (int seed = 0; seed < 300; seed++) {
        for (final Person k
            in InLaws.parentsOfSpouse(state: s, spouse: es(), rng: Random(seed))) {
          expect(k.age - 32, greaterThanOrEqualTo(18),
              reason: '§43: 32 yaşındaki eşin ebeveyni ${k.age} yaşında.');
        }
      }
    });

    test('kayın aile gerçek Person (§22)', () {
      final GameState s = aileliHayat(age: 30);
      List<Person> k = const <Person>[];
      for (int seed = 0; seed < 100 && k.isEmpty; seed++) {
        k = InLaws.parentsOfSpouse(state: s, spouse: es(), rng: Random(seed));
      }
      expect(k, isNotEmpty);
      for (final Person p in k) {
        expect(p.id, isNotEmpty);
        expect(p.bond, greaterThan(0));
        expect(p.city, isNotNull);
        expect(p.wealth, isNotNull);
        expect(p.isAlive, isTrue);
      }
    });

    test('aynı kişi iki kere üretilmiyor (§22, §37)', () {
      GameState s = aileliHayat(age: 30);
      List<Person> ilk = const <Person>[];
      for (int seed = 0; seed < 100 && ilk.isEmpty; seed++) {
        ilk = InLaws.parentsOfSpouse(state: s, spouse: es(), rng: Random(seed));
      }
      s = s.copyWith(
        people: List<Person>.unmodifiable(<Person>[...s.people, ...ilk]),
      );
      for (int seed = 0; seed < 100; seed++) {
        expect(
          InLaws.parentsOfSpouse(state: s, spouse: es(), rng: Random(seed)),
          isEmpty,
          reason: '§37: kayın aile her yıl yeniden üretiliyor.',
        );
      }
    });

    test('kayın aileyle etkileşim var, para isteme yok (§23)', () {
      final Set<InteractionKind> k =
          meaningfulKindsFor(RelationType.kayinvalide);
      expect(k.contains(InteractionKind.vakitGecir), isTrue);
      expect(k.contains(InteractionKind.sohbet), isTrue);
      expect(k.contains(InteractionKind.hediyeVer), isTrue);
      expect(k.contains(InteractionKind.paraIste), isFalse,
          reason: '§23: para isteme bu pakette açılmıyor.');
    });

    test('kayın aile kendi başlığında (§38)', () {
      expect(RelationType.kayinvalide.group, RelationGroup.esinAilesi);
      expect(RelationType.kayinpeder.group, RelationGroup.esinAilesi);
    });
  });

  // =================================================================
  // §25-§27 — EX-SPOUSE / CO-PARENTING
  // =================================================================
  group('AO ex-spouse co-parenting', () {
    GameState bosanmisHayat({required bool ortakCocuk}) {
      final GameState s = aileliHayat(age: 40);
      final Person eskiEs = Person(
        id: 'eski-es-1',
        firstName: 'Ayla',
        lastName: 'Tunç',
        gender: Gender.kadin,
        relation: RelationType.eskiEs,
        age: 38,
        isAlive: true,
        inPlayerHousehold: false,
        employment: EmploymentStatus.calisiyor,
        occupation: 'Hemşire',
        wealth: WealthTier.ortaHalli,
        bond: 40,
      );
      final Person cocuk = Person(
        id: 'cocuk-1',
        firstName: 'Ege',
        lastName: 'Tunç',
        gender: Gender.erkek,
        relation: RelationType.cocuk,
        age: 10,
        isAlive: true,
        inPlayerHousehold: false,
        employment: EmploymentStatus.ogrenci,
        wealth: null,
        bond: 70,
        motherId: 'eski-es-1',
        fatherId: s.player.id,
      );
      return s.copyWith(
        people: List<Person>.unmodifiable(<Person>[
          ...s.people,
          eskiEs,
          if (ortakCocuk) cocuk,
        ]),
        marriage: const Marriage(
          spouseId: 'eski-es-1',
          marriedAtAge: 28,
          status: MarriageStatus.bosandi,
          endedAtAge: 36,
        ),
      );
    }

    test('ortak çocuk varsa co-parenting açılıyor (§25)', () {
      final GameState s = bosanmisHayat(ortakCocuk: true);
      final Person eski = kisi(s, RelationType.eskiEs)!;
      const FamilyInteractions fi = FamilyInteractions();
      expect(
        fi.availability(s, eski, InteractionKind.cocukKonus).isAllowed,
        isTrue,
        reason: '§25: ortak çocuk varken iletişim tamamen kapalı olmamalı.',
      );
    });

    test('ortak çocuk yoksa gereksiz kapı açılmıyor (§25)', () {
      final GameState s = bosanmisHayat(ortakCocuk: false);
      final Person eski = kisi(s, RelationType.eskiEs)!;
      const FamilyInteractions fi = FamilyInteractions();
      expect(
        fi.availability(s, eski, InteractionKind.cocukKonus).isAllowed,
        isFalse,
        reason: '§25: ortak çocuk yoksa kapı açılmamalı.',
      );
    });

    test('eski eşle gündelik yakınlık etkileşimleri hâlâ kapalı (§25)', () {
      final GameState s = bosanmisHayat(ortakCocuk: true);
      final Person eski = kisi(s, RelationType.eskiEs)!;
      const FamilyInteractions fi = FamilyInteractions();
      for (final InteractionKind k in <InteractionKind>[
        InteractionKind.vakitGecir,
        InteractionKind.hediyeVer,
        InteractionKind.paraIste,
      ]) {
        expect(fi.availability(s, eski, k).isAllowed, isFalse,
            reason: '§25: boşandınız, $k açılmamalı.');
      }
    });

    test('çocuk eski eşin hanesinde olsa da listeden kaybolmuyor (§27)', () {
      final GameState s = bosanmisHayat(ortakCocuk: true);
      final Person? c = kisi(s, RelationType.cocuk);
      expect(c, isNotNull, reason: '§27: çocuk kaydı silinmemeli.');
      expect(c!.inPlayerHousehold, isFalse);
      expect(c.isAlive, isTrue);
    });
  });

  // =================================================================
  // §35, §36 — ELDER CARE
  // =================================================================
  group('AO elder care', () {
    GameState yasliEbeveynli({int parentAge = 82, int health = 30}) {
      final GameState s = aileliHayat(age: 50);
      return s.copyWith(
        people: List<Person>.unmodifiable(
          s.people.map((Person p) => p.relation == RelationType.anne
              ? p.copyWith(age: parentAge, happiness: health)
              : p),
        ),
        player: s.player.copyWith(wallet: 2000000),
      );
    }

    test('sağlık ve yaş koşulu gerçek (§35)', () {
      final GameState yasli = yasliEbeveynli();
      expect(ElderCare.needingCare(yasli), isNotEmpty);

      final GameState genc = yasliEbeveynli(parentAge: 60, health: 80);
      expect(
        ElderCare.needingCare(genc)
            .where((Person p) => p.relation == RelationType.anne),
        isEmpty,
        reason: '§35: 60 yaşında sağlıklı ebeveyne bakım kararı çıkmaz.',
      );
    });

    test('yardımın para ve bond etkisi gerçek (§35)', () {
      final GameState s = yasliEbeveynli();
      final Person anne = kisi(s, RelationType.anne)!;
      final r = ElderCare.apply(
        state: s,
        parent: anne,
        choice: ElderCareChoice.masrafaYardim,
        rng: Random(1),
      );
      expect(r.paid, greaterThan(0), reason: '§35: para gerçekten çıkmalı.');
      expect(r.state.player.wallet, lessThan(s.player.wallet));
      final Person sonra = r.state.people
          .firstWhere((Person p) => p.id == anne.id);
      expect(sonra.bond, greaterThan(anne.bond));
    });

    test('ilgilenmemek bedelsiz değil (§35)', () {
      final GameState s = yasliEbeveynli();
      final Person anne = kisi(s, RelationType.anne)!;
      final r = ElderCare.apply(
        state: s,
        parent: anne,
        choice: ElderCareChoice.ilgilenme,
        rng: Random(1),
      );
      expect(r.paid, 0);
      final Person sonra =
          r.state.people.firstWhere((Person p) => p.id == anne.id);
      expect(sonra.bond, lessThan(anne.bond));
    });

    test('parası yoksa yardım olmuş gibi gösterilmiyor', () {
      GameState s = yasliEbeveynli();
      s = s.copyWith(player: s.player.copyWith(wallet: 0));
      final Person anne = kisi(s, RelationType.anne)!;
      final r = ElderCare.apply(
        state: s,
        parent: anne,
        choice: ElderCareChoice.masrafaYardim,
        rng: Random(1),
      );
      expect(r.paid, 0);
      expect(r.state.player.wallet, 0, reason: 'Cüzdan eksiye düşmemeli.');
    });

    test('parası olmayan kardeş havadan para üretmiyor (§36)', () {
      GameState s = yasliEbeveynli();
      // Yoksul kardeş.
      s = s.copyWith(
        people: List<Person>.unmodifiable(<Person>[
          ...s.people,
          Person(
            id: 'kardes-yoksul',
            firstName: 'Can',
            lastName: 'Ak',
            gender: Gender.erkek,
            relation: RelationType.kardes,
            age: 48,
            isAlive: true,
            inPlayerHousehold: false,
            employment: EmploymentStatus.issiz,
            wealth: WealthTier.cokYoksul,
            bond: 60,
          ),
        ]),
      );
      final katki = ElderCare.siblingContribution(s, ElderCare.yearlyCost());
      expect(katki.amount, 0,
          reason: '§36: parası olmayan kardeş katkı veremez.');
    });

    test('varlıklı kardeş gerçekten katkı veriyor (§36)', () {
      GameState s = yasliEbeveynli();
      s = s.copyWith(
        people: List<Person>.unmodifiable(<Person>[
          ...s.people,
          Person(
            id: 'kardes-varlikli',
            firstName: 'Mert',
            lastName: 'Ak',
            gender: Gender.erkek,
            relation: RelationType.kardes,
            age: 48,
            isAlive: true,
            inPlayerHousehold: false,
            employment: EmploymentStatus.calisiyor,
            occupation: 'Mimar',
            wealth: WealthTier.varlikli,
            bond: 60,
          ),
        ]),
      );
      final katki = ElderCare.siblingContribution(s, ElderCare.yearlyCost());
      expect(katki.amount, greaterThan(0));
      expect(katki.amount, lessThanOrEqualTo(ElderCare.yearlyCost()),
          reason: 'Kardeşler masrafın tamamından fazlasını ödememeli.');
      expect(katki.names, contains('Mert'));
    });
  });

  // =================================================================
  // §47 — SAVE / LOAD
  // =================================================================
  group('AO save / load', () {
    test('yeni alanlar roundtrip ile korunuyor', () {
      GameState s = aileliHayat(age: 20);
      s = s.copyWith(
        parentalStatus: ParentalStatus.bosanmis,
        people: List<Person>.unmodifiable(<Person>[
          ...s.people,
          Person(
            id: 'yk-1',
            firstName: 'Zeynep',
            lastName: 'Ak',
            gender: Gender.kadin,
            relation: RelationType.yariKardes,
            age: 3,
            isAlive: true,
            inPlayerHousehold: true,
            employment: EmploymentStatus.cocuk,
            wealth: null,
            bond: 25,
            motherId: 'uvey-anne-1',
            fatherId: kisi(s, RelationType.baba)!.id,
          ),
        ]),
      );
      final GameState geri = decodeGameState(encodeGameState(s));
      expect(geri.parentalStatus, ParentalStatus.bosanmis);
      final Person yk =
          geri.people.firstWhere((Person p) => p.id == 'yk-1');
      expect(yk.relation, RelationType.yariKardes);
      expect(yk.motherId, 'uvey-anne-1');
      expect(yk.fatherId, kisi(s, RelationType.baba)!.id);
    });

    test('eski kayıtta soy alanı yok: null açılır, akraba UYDURULMAZ', () {
      final GameState s = aileliHayat(age: 20);
      final Map<String, Object?> json = encodeGameState(s);
      // Eski kayıt taklidi: soy alanlarını sil.
      final List<Object?> kisiler = json['people']! as List<Object?>;
      for (final Object? k in kisiler) {
        (k! as Map<String, Object?>)
          ..remove('motherId')
          ..remove('fatherId');
      }
      final GameState geri = decodeGameState(json);
      expect(geri.people.length, s.people.length,
          reason: '§47: eski kayda yeni akraba eklenmemeli.');
      for (final Person p in geri.people) {
        expect(p.motherId, isNull);
        expect(p.fatherId, isNull);
      }
      // Yeni bağ türlerinden hiçbiri geriye dönük üretilmemiş.
      for (final RelationType tur in <RelationType>[
        RelationType.uveyKardes,
        RelationType.yariKardes,
        RelationType.uveyCocuk,
        RelationType.kayinvalide,
        RelationType.kayinpeder,
      ]) {
        expect(geri.people.any((Person p) => p.relation == tur), isFalse);
      }
    });

    test('duplicate person yok', () {
      final GameState s = aileliHayat(age: 20);
      final Set<String> kimlikler = <String>{};
      for (final Person p in s.people) {
        expect(kimlikler.add(p.id), isTrue,
            reason: '§37: aynı kimlik iki kez: ${p.id}');
      }
    });
  });
}

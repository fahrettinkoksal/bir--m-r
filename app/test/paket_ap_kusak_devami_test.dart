// Paket AP §62-§65, §74 — kuşak devamı: çocuğun evliliği kaybolmasın.
//
// §74 bunu "en kritik test" diye işaretledi ve haklı: Paket AP gelin/
// damadı gerçek bir kişi yaptığı anda, kuşak devamındaki `default:
// return null` dalı onu **sessizce düşürür** hâle geldi. `torun` bir
// zamanlar tam olarak böyle kaybolmuştu.
//
// Bu dosya üç yolu da ürünün kendi API'sinden geçiriyor:
// evli / boşanmış / dul çocukla devam.
library;

import 'dart:math';

import 'package:bir_omur/domain/generation/generation_continuation.dart';
import 'package:bir_omur/domain/models/game_state.dart';
import 'package:bir_omur/domain/models/gender.dart';
import 'package:bir_omur/domain/models/marriage.dart';
import 'package:bir_omur/domain/models/npc_marriage.dart';
import 'package:bir_omur/domain/models/person.dart';
import 'package:bir_omur/domain/models/person_development.dart';
import 'package:bir_omur/domain/models/relation.dart';
import 'package:bir_omur/domain/models/stats.dart';
import 'package:bir_omur/domain/models/wealth.dart';
import 'package:flutter_test/flutter_test.dart';

import 'paket_ao_aile_v2_test.dart' show aileliHayat;

const Stats _notrStats = Stats(
  appearance: 55,
  happiness: 60,
  health: 70,
  intelligence: 60,
  charisma: 55,
);

/// Evli bir çocuk, gerçek eşi ve bir torunla birlikte kurulu bir hayat.
///
/// Oyuncu **vefat etmiş** durumda: kuşak devamı ancak öyle açılır.
GameState devirHayati({
  NpcMarriageStatus durum = NpcMarriageStatus.evli,
  bool esHayatta = true,
}) {
  final GameState taban = aileliHayat(seed: 9, age: 70);
  const String cocukId = 'cocuk-devir';
  const String esId = 'cocugunesi-cocuk-devir-1';

  final bool evli = durum == NpcMarriageStatus.evli;
  final PersonDevelopment gelisim = PersonDevelopment(
    tracksLife: true,
    stats: _notrStats,
    finishedSchool: true,
    money: 500000,
    marriedAtAge: 28,
    spouseName: 'Ahmet',
    spousePersonId: evli ? esId : null,
    marriageStatus: durum,
    pastMarriages: evli
        ? const <NpcMarriageRecord>[]
        : <NpcMarriageRecord>[
            NpcMarriageRecord(
              spouseName: 'Ahmet',
              spousePersonId: esId,
              marriedAtAge: 28,
              endedAtAge: 36,
              status: durum,
            ),
          ],
  );

  return taban.copyWith(
    deceased: true,
    deathAge: 70,
    people: List<Person>.unmodifiable(<Person>[
      ...taban.people,
      // Devam edilecek çocuk.
      Person(
        id: cocukId,
        firstName: 'Elif',
        lastName: taban.player.lastName,
        gender: Gender.kadin,
        relation: RelationType.cocuk,
        age: 40,
        isAlive: true,
        inPlayerHousehold: false,
        employment: EmploymentStatus.calisiyor,
        occupation: 'öğretmen',
        wealth: WealthTier.ortaHalli,
        bond: 70,
        city: taban.player.currentCity,
        motherId: taban.player.id,
        development: gelisim,
      ),
      // Çocuğun eşi: gerçek kişi (Paket AP §16).
      Person(
        id: esId,
        firstName: 'Ahmet',
        lastName: 'Yıldırım',
        gender: Gender.erkek,
        relation: evli
            ? RelationType.cocugunEsi
            : RelationType.eskiCocugunEsi,
        age: 42,
        isAlive: esHayatta,
        inPlayerHousehold: false,
        employment: EmploymentStatus.calisiyor,
        occupation: 'mühendis',
        wealth: WealthTier.ortaHalli,
        bond: 35,
        city: taban.player.currentCity,
      ),
      // Torun: iki gerçek ebeveyni var.
      Person(
        id: 'torun-devir',
        firstName: 'Can',
        lastName: taban.player.lastName,
        gender: Gender.erkek,
        relation: RelationType.torun,
        age: 8,
        isAlive: true,
        inPlayerHousehold: false,
        employment: EmploymentStatus.ogrenci,
        wealth: null,
        bond: 60,
        city: taban.player.currentCity,
        motherId: cocukId,
        fatherId: esId,
        development: PersonDevelopment(
          tracksLife: true,
          stats: _notrStats,
          // Torunun kendi ebeveyni kaydı: devam motoru bunu okuyor.
          otherParentId: cocukId,
        ),
      ),
    ]),
  );
}

void main() {
  group('§62-§63 — evli çocukla devam', () {
    test('çocuğun eşi YENİ OYUNCUNUN EŞİ olur, kayıt kaybolmaz', () {
      final GameState once = devirHayati();
      final ({GameState? state, String blockReason}) r =
          GenerationContinuation.continueAs(once, 'cocuk-devir', Random(3));
      expect(r.blockReason, isEmpty, reason: r.blockReason);
      final GameState s = r.state!;

      // En kritik iddia: eş düşmedi.
      final Person? es = s.personById('cocugunesi-cocuk-devir-1');
      expect(es, isNotNull,
          reason: '§62: gelin/damat kuşak devamında kaybolmamalı.');
      expect(es!.relation, RelationType.es,
          reason: '§62: artık yeni oyuncunun eşidir.');
    });

    test('§63: evlilik yürüyen gerçek bir kayıt olarak taşınıyor', () {
      final GameState s = GenerationContinuation.continueAs(
        devirHayati(),
        'cocuk-devir',
        Random(3),
      ).state!;

      final Marriage? m = s.marriage;
      expect(m, isNotNull,
          reason: '§63: 12 yıldır evli insan "bekar" başlamaz.');
      expect(m!.spouseId, 'cocugunesi-cocuk-devir-1');
      expect(m.status, MarriageStatus.evli);
      expect(m.isActive, isTrue);
      expect(m.marriedAtAge, 28,
          reason: 'Evlilik yaşı çocuğun kendi yaşıdır.');
    });

    test('§49: torunlar yeni oyuncunun çocuğu olur, soy bağı bozulmaz', () {
      final GameState s = GenerationContinuation.continueAs(
        devirHayati(),
        'cocuk-devir',
        Random(3),
      ).state!;

      final Person? torun = s.personById('torun-devir');
      expect(torun, isNotNull);
      expect(torun!.relation, RelationType.cocuk,
          reason: 'Devam edilen çocuğun torunu yeni oyuncunun çocuğudur.');
      // Soy kaydı aynen duruyor: anne devam edilen çocuk (artık oyuncu),
      // baba gelin/damat (artık eş).
      expect(torun.motherId, 'cocuk-devir');
      expect(torun.fatherId, 'cocugunesi-cocuk-devir-1');
    });

    test('mükerrer eş üretilmiyor', () {
      final GameState s = GenerationContinuation.continueAs(
        devirHayati(),
        'cocuk-devir',
        Random(3),
      ).state!;
      final int esSayisi =
          s.people.where((Person p) => p.relation == RelationType.es).length;
      expect(esSayisi, 1);
      // Kimlikler tekil.
      final Set<String> kimlikler = <String>{};
      for (final Person p in s.people) {
        expect(kimlikler.add(p.id), isTrue, reason: '${p.id} iki kez var.');
      }
    });
  });

  group('§64 — boşanmış çocukla devam', () {
    test('eski eş eskiEs olur ve evlilik boşanmış olarak taşınır', () {
      final GameState once =
          devirHayati(durum: NpcMarriageStatus.bosandi);
      final GameState s = GenerationContinuation.continueAs(
        once,
        'cocuk-devir',
        Random(5),
      ).state!;

      final Person? eski = s.personById('cocugunesi-cocuk-devir-1');
      expect(eski, isNotNull, reason: 'Eski eş kayıttan silinmez.');
      expect(eski!.relation, RelationType.eskiEs);

      final Marriage? m = s.marriage;
      expect(m, isNotNull,
          reason: '§64: boşanmış geçmişiyle başlamalı.');
      expect(m!.status, MarriageStatus.bosandi);
      expect(m.isActive, isFalse);
      expect(m.endedAtAge, 36);

      // Ortak çocuk (torun) doğru kalmalı.
      final Person torun = s.personById('torun-devir')!;
      expect(torun.relation, RelationType.cocuk);
      expect(torun.fatherId, 'cocugunesi-cocuk-devir-1');
    });
  });

  group('§65 — dul çocukla devam', () {
    test('vefat etmiş eş kayıtta kalır, durum dul taşınır', () {
      final GameState once = devirHayati(
        durum: NpcMarriageStatus.dul,
        esHayatta: false,
      );
      final GameState s = GenerationContinuation.continueAs(
        once,
        'cocuk-devir',
        Random(7),
      ).state!;

      final Person? olmusEs = s.personById('cocugunesi-cocuk-devir-1');
      expect(olmusEs, isNotNull,
          reason: '§65: ölü eş kayıttan kaybolmaz.');
      expect(olmusEs!.isAlive, isFalse);
      expect(olmusEs.relation, RelationType.eskiEs);

      final Marriage? m = s.marriage;
      expect(m, isNotNull);
      expect(m!.status, MarriageStatus.dul);
    });
  });

  group('§17 — eski kayıt uyumu', () {
    test('eşi Person olmayan eski kayıtta uydurma evlilik kurulmaz', () {
      // Paket AP öncesi kayıt: yalnızca spouseName var.
      final GameState taban = aileliHayat(seed: 9, age: 70);
      final GameState once = taban.copyWith(
        deceased: true,
        deathAge: 70,
        people: List<Person>.unmodifiable(<Person>[
          ...taban.people,
          Person(
            id: 'cocuk-eski',
            firstName: 'Elif',
            lastName: taban.player.lastName,
            gender: Gender.kadin,
            relation: RelationType.cocuk,
            age: 40,
            isAlive: true,
            inPlayerHousehold: false,
            employment: EmploymentStatus.calisiyor,
            occupation: 'öğretmen',
            wealth: WealthTier.ortaHalli,
            bond: 70,
            city: taban.player.currentCity,
            motherId: taban.player.id,
            development: PersonDevelopment(
              tracksLife: true,
              stats: _notrStats,
              finishedSchool: true,
              marriedAtAge: 28,
              spouseName: 'Ahmet',
            ),
          ),
        ]),
      );

      final GameState s = GenerationContinuation.continueAs(
        once,
        'cocuk-eski',
        Random(11),
      ).state!;

      // Var olmayan bir kimliğe evlilik bağlanmadı.
      expect(s.marriage, isNull,
          reason: '§17: sahte eş kimliği yazmaktan iyidir.');
      // Ve hiçbir yerde uydurma bir "eş" kişisi yok.
      expect(
        s.people.where((Person p) => p.relation == RelationType.es),
        isEmpty,
      );
    });
  });
}

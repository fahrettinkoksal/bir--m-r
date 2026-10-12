// Paket AP §24-§27, §47-§49 — gelin/damat, kayın aile ve torun soy bağı.
//
// En önemli iddia bir **yasak**: §26 "kayınvalide = sürekli sorun"
// stereotipini reddediyor. Bu dosya onu sayarak ölçüyor.
library;

import 'dart:math';

import 'package:bir_omur/domain/family/in_law_relations.dart';
import 'package:bir_omur/domain/generation/child_marriage.dart';
import 'package:bir_omur/domain/generation/grandchildren.dart';
import 'package:bir_omur/domain/generation/life_progression.dart';
import 'package:bir_omur/domain/interaction/interaction_policy.dart';
import 'package:bir_omur/domain/models/interaction.dart';
import 'package:bir_omur/domain/models/family_issue.dart';
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

const Stats _ortaStats = Stats(
  appearance: 55,
  happiness: 60,
  health: 75,
  intelligence: 60,
  charisma: 55,
);

/// Evli bir çocuğu ve gerçek bir gelin/damadı olan hayat.
GameState gelinliHayat({int seed = 21, int playerAge = 58}) {
  final GameState taban = aileliHayat(seed: seed, age: playerAge);
  return taban.copyWith(
    people: List<Person>.unmodifiable(<Person>[
      ...taban.people,
      Person(
        id: 'cocuk-evli',
        firstName: 'Elif',
        lastName: taban.player.lastName,
        gender: Gender.kadin,
        relation: RelationType.cocuk,
        age: 30,
        isAlive: true,
        inPlayerHousehold: false,
        employment: EmploymentStatus.calisiyor,
        occupation: 'öğretmen',
        wealth: WealthTier.ortaHalli,
        bond: 70,
        city: taban.player.currentCity,
        motherId: taban.player.id,
        development: const PersonDevelopment(
          tracksLife: true,
          finishedSchool: true,
          money: 300000,
          marriedAtAge: 27,
          spouseName: 'Ahmet',
          spousePersonId: 'cocugunesi-cocuk-evli-1',
          marriageStatus: NpcMarriageStatus.evli,
          stats: _ortaStats,
        ),
      ),
      Person(
        id: 'cocugunesi-cocuk-evli-1',
        firstName: 'Ahmet',
        lastName: 'Yıldırım',
        gender: Gender.erkek,
        relation: RelationType.cocugunEsi,
        age: 32,
        isAlive: true,
        inPlayerHousehold: false,
        employment: EmploymentStatus.calisiyor,
        occupation: 'mühendis',
        wealth: WealthTier.ortaHalli,
        bond: 28,
        city: taban.player.currentCity,
      ),
    ]),
  );
}

void main() {
  group('§24 — gelin/damat otomatik iyi ya da kötü değil', () {
    test('başlangıç yakınlığı ne düşman ne "kendi çocuğun" seviyesinde',
        () {
      // Üretilen gelin/damat bandı: ne 0 ne 90.
      final int taban = ChildMarriage.prototypeOnlySpouseStartBond;
      expect(taban, greaterThan(10),
          reason: 'Gelin/damat düşman olarak gelmiyor.');
      expect(taban, lessThan(50),
          reason: 'Bağ zamanla kurulmalı, hazır gelmemeli.');
    });

    test('gelin/damat ile vakit geçirilebiliyor (§25)', () {
      final Set<InteractionKind> secenekler =
          meaningfulKindsFor(RelationType.cocugunEsi);
      expect(secenekler, isNotEmpty,
          reason: 'Gelin/damat oyuncunun hayatına giren bir insan.');
      expect(secenekler, contains(InteractionKind.sohbet));
    });

    test('eski gelin/damat ile etkileşim yok ama kaydı duruyor', () {
      expect(meaningfulKindsFor(RelationType.eskiCocugunEsi), isEmpty);
    });
  });

  group('§26 — "kayınvalide = sürekli sorun" stereotipi YOK', () {
    test('olay havuzu dengeli: iyi ve kötü olay sayısı eşit', () {
      final int iyi = InLawRelations.prototypeOnlyEvents
          .where((({String text, bool good}) e) => e.good)
          .length;
      final int kotu = InLawRelations.prototypeOnlyEvents.length - iyi;
      expect(iyi, kotu,
          reason: 'Havuz dengeli olmalı: iyi $iyi, kötü $kotu.');
      expect(iyi, greaterThan(2), reason: 'Tek bir iyi olay yetmez.');
    });

    test('ölçüm: çıkan olayların yarısı iyi', () {
      final GameState s = gelinliHayat();
      int iyi = 0;
      int kotu = 0;
      for (int i = 0; i < 1500; i++) {
        final ({GameState state, String? logText, bool? good}) r =
            InLawRelations.maybeEvent(s, s.player.age, Random(i));
        if (r.logText == null) continue;
        if (r.good!) {
          iyi++;
        } else {
          kotu++;
        }
      }
      expect(iyi + kotu, greaterThan(40), reason: 'Ölçüm için örnek az.');
      // Dengeli: hiçbir yön diğerinin iki katı olmasın.
      expect(iyi, greaterThan(kotu ~/ 2),
          reason: 'İyi $iyi, kötü $kotu — stereotip oluşuyor.');
      expect(kotu, greaterThan(iyi ~/ 2),
          reason: 'İyi $iyi, kötü $kotu — her şey güzel de olmamalı.');
    });

    test('iyi olay yakınlığı artırır, kötü olay düşürür', () {
      final GameState s = gelinliHayat();
      final int once = s.personById('cocugunesi-cocuk-evli-1')!.bond;
      bool iyiGorduk = false;
      bool kotuGorduk = false;
      for (int i = 0; i < 1500 && !(iyiGorduk && kotuGorduk); i++) {
        final ({GameState state, String? logText, bool? good}) r =
            InLawRelations.maybeEvent(s, s.player.age, Random(i));
        if (r.logText == null) continue;
        if (!r.logText!.contains('Ahmet')) continue;
        final int sonra =
            r.state.personById('cocugunesi-cocuk-evli-1')!.bond;
        if (r.good!) {
          expect(sonra, greaterThan(once));
          iyiGorduk = true;
        } else {
          expect(sonra, lessThan(once));
          kotuGorduk = true;
        }
      }
      expect(iyiGorduk && kotuGorduk, isTrue,
          reason: 'İki yön de görülmeli.');
    });

    test('soğuma: aynı kişiyle her yıl olay çıkmıyor', () {
      final GameState s = gelinliHayat();
      GameState bulunan = s;
      for (int i = 0; i < 1500; i++) {
        final ({GameState state, String? logText, bool? good}) r =
            InLawRelations.maybeEvent(s, s.player.age, Random(i));
        if (r.logText != null) {
          bulunan = r.state;
          break;
        }
      }
      expect(bulunan, isNot(same(s)));
      // Aynı yaşta 300 deneme daha: soğuma yüzünden aynı kişi tekrar
      // çıkmıyor.
      // Aynı yaşta 300 deneme daha: soğuma yüzünden aynı kişi tekrar
      // çıkmıyor. Kişi, günlük satırının adından okunuyor.
      final String? ilkAd = bulunan.log.last.text.split(' ').length > 1
          ? bulunan.log.last.text.split(' ')[1]
          : null;
      for (int i = 0; i < 300; i++) {
        final ({GameState state, String? logText, bool? good}) r =
            InLawRelations.maybeEvent(bulunan, bulunan.player.age, Random(i));
        if (r.logText == null) continue;
        if (ilkAd == null) continue;
        expect(r.logText!.contains(' $ilkAd '), isFalse,
            reason: 'Aynı kişiyle aynı yıl ikinci olay çıktı.');
      }
    });
  });

  group('§27 — arada kalmak: bedava seçenek yok', () {
    GameState catismali() {
      final GameState s = gelinliHayat();
      // Eş ve oyuncunun bir ebeveyni hayatta olmalı.
      if (InLawRelations.conflictSides(s) != null) return s;
      // Eş kaydı yoksa kur.
      final Person es = Person(
        id: 'es-1',
        firstName: 'Kerem',
        lastName: s.player.lastName,
        gender: Gender.erkek,
        relation: RelationType.es,
        age: s.player.age,
        isAlive: true,
        inPlayerHousehold: true,
        employment: EmploymentStatus.calisiyor,
        occupation: 'teknisyen',
        wealth: WealthTier.ortaHalli,
        bond: 70,
        city: s.player.currentCity,
      );
      return s.copyWith(
        people: List<Person>.unmodifiable(<Person>[...s.people, es]),
        marriage: Marriage(
          spouseId: 'es-1',
          marriedAtAge: 30,
          status: MarriageStatus.evli,
        ),
      );
    }

    GameState catismaAc(GameState s) {
      for (int i = 0; i < 2000; i++) {
        final GameState sonra =
            InLawRelations.maybeConflict(s, s.player.age, Random(i)).state;
        if (InLawRelations.isConflictPending(sonra)) return sonra;
      }
      fail('2000 denemede çatışma hiç çıkmadı.');
    }

    test('eş ya da ebeveyn yoksa "ev kavgası" uydurulmuyor', () {
      final GameState esYok = gelinliHayat().copyWith(marriage: null);
      // Eş kaydı olmayan hayatta çatışma tarafları kurulamaz.
      if (esYok.spouse == null) {
        expect(InLawRelations.conflictSides(esYok), isNull);
        for (int i = 0; i < 200; i++) {
          final GameState sonra = InLawRelations.maybeConflict(
            esYok,
            esYok.player.age,
            Random(i),
          ).state;
          expect(InLawRelations.isConflictPending(sonra), isFalse);
        }
      }
    });

    test('çatışma gerçek iki kişi arasında açılıyor', () {
      final GameState s = catismaAc(catismali());
      final FamilyIssue m = InLawRelations.pendingConflict(s)!;
      expect(m.kind, FamilyIssueKind.kayinGerginlik);
      expect(s.personById(m.personId), isNotNull,
          reason: '§53: gerçek kişi kimliği.');
    });

    test('her üç cevap da bir şeye mal oluyor', () {
      for (final FamilyIssueResponse cevap in <FamilyIssueResponse>[
        FamilyIssueResponse.destekOldu,
        FamilyIssueResponse.reddetti,
        FamilyIssueResponse.karismadi,
      ]) {
        final GameState s = catismaAc(catismali());
        final FamilyIssue m = InLawRelations.pendingConflict(s)!;
        final int esOnce = s.spouse!.bond;
        final int ebeveynOnce = s.personById(m.personId)!.bond;

        final GameState sonra =
            InLawRelations.resolveConflict(s, cevap).state;
        final int esSonra = sonra.spouse!.bond;
        final int ebeveynSonra = sonra.personById(m.personId)!.bond;

        final bool birTarafKaybetti =
            esSonra < esOnce || ebeveynSonra < ebeveynOnce;
        expect(birTarafKaybetti, isTrue,
            reason: '${cevap.name}: hiçbir taraf kaybetmedi, bedava '
                'seçenek olmuş.');
        // Mesele kapanıyor ama kaydı kalıyor.
        expect(sonra.openFamilyIssues, isEmpty);
        expect(sonra.familyIssues.first.response, cevap);
      }
    });

    test('taraf tutmak iki tarafı da memnun etmiyor', () {
      final GameState s = catismaAc(catismali());
      final FamilyIssue m = InLawRelations.pendingConflict(s)!;
      final GameState esTarafi = InLawRelations.resolveConflict(
        s,
        FamilyIssueResponse.destekOldu,
      ).state;
      expect(esTarafi.spouse!.bond, greaterThan(s.spouse!.bond));
      expect(esTarafi.personById(m.personId)!.bond,
          lessThan(s.personById(m.personId)!.bond));
    });
  });

  group('üretim yolu', () {
    test('kayın aile olayı advanceOneYear içinden çıkıyor', () {
      bool cikti = false;
      for (int tohum = 0; tohum < 30 && !cikti; tohum++) {
        GameState s = gelinliHayat(seed: tohum, playerAge: 56);
        final LifeProgression motor = LifeProgression(Random(tohum + 7));
        for (int i = 0; i < 8 && !s.deceased && !cikti; i++) {
          final int oncekiSatir = s.log.length;
          s = s.copyWith(pendingEvent: null, pendingCrisis: null);
          s = motor.advanceOneYear(s);
          final bool kayinIzi = s.lastInteractionAge.keys
              .any((String k) => k.startsWith('kayin-olay:'));
          if (kayinIzi && s.log.length > oncekiSatir) cikti = true;
        }
      }
      expect(cikti, isTrue,
          reason: 'Motor yıllık ilerlemeye bağlı değil.');
    });

    test('torun üretim yolunda da iki ebeveynle doğuyor', () {
      for (int tohum = 0; tohum < 40; tohum++) {
        GameState s = gelinliHayat(seed: tohum, playerAge: 56);
        final LifeProgression motor = LifeProgression(Random(tohum + 11));
        for (int i = 0; i < 10 && !s.deceased; i++) {
          s = s.copyWith(pendingEvent: null, pendingCrisis: null);
          s = motor.advanceOneYear(s);
          final Iterable<Person> torunlar = s.people.where(
            (Person p) => p.relation == RelationType.torun,
          );
          for (final Person t in torunlar) {
            if (t.motherId == 'cocuk-evli' || t.fatherId == 'cocuk-evli') {
              expect(
                <String?>[t.motherId, t.fatherId],
                contains('cocugunesi-cocuk-evli-1'),
                reason: 'Torunun diğer ebeveyni gelin/damat olmalı.',
              );
              return;
            }
          }
        }
      }
      // Torun doğmadıysa test boşa dönmesin.
      fail('40 hayatta hiç torun doğmadı; ölçüm yapılamadı.');
    });
  });

  group('§49 — torunun soy bağı: yeni motor kurulmadı, eksik alan yazıldı',
      () {
    test('torun iki gerçek ebeveynle doğuyor', () {
      final GameState s = gelinliHayat();
      final Person cocuk = s.personById('cocuk-evli')!;
      for (int i = 0; i < 2000; i++) {
        final Person? torun = Grandchildren.maybeBorn(
          state: s,
          child: cocuk,
          rng: Random(i),
        );
        if (torun == null) continue;
        // Çocuk kadın: anne o, baba gelin/damat.
        expect(torun.motherId, 'cocuk-evli');
        expect(torun.fatherId, 'cocugunesi-cocuk-evli-1');
        // AO modelinin kendi alanı da duruyor.
        expect(torun.development?.otherParentId, 'cocuk-evli');
        return;
      }
      fail('2000 denemede torun doğmadı.');
    });

    test('eşi olmayan çocukta uydurma ebeveyn kimliği yazılmıyor', () {
      GameState s = gelinliHayat();
      s = s.copyWith(
        people: List<Person>.unmodifiable(<Person>[
          for (final Person p in s.people)
            if (p.id == 'cocuk-evli')
              p.copyWith(
                development: p.development!.copyWith(
                  spousePersonId: null,
                  marriageStatus: NpcMarriageStatus.bosandi,
                ),
              )
            else
              p,
        ]),
      );
      final Person cocuk = s.personById('cocuk-evli')!;
      for (int i = 0; i < 2000; i++) {
        final Person? torun = Grandchildren.maybeBorn(
          state: s,
          child: cocuk,
          rng: Random(i),
        );
        if (torun == null) continue;
        expect(torun.motherId, 'cocuk-evli');
        expect(torun.fatherId, isNull,
            reason: '§53: olmayan eş için kimlik uydurulmaz.');
        return;
      }
      fail('2000 denemede torun doğmadı.');
    });

    test('erkek çocukta alanlar ters yazılıyor', () {
      final GameState taban = gelinliHayat();
      final Person kadinCocuk = taban.personById('cocuk-evli')!;
      // `Person.copyWith` cinsiyeti değiştirmiyor (bilinçli): kayıt
      // yeniden kuruluyor.
      final Person erkekCocuk = Person(
        id: kadinCocuk.id,
        firstName: 'Ege',
        lastName: kadinCocuk.lastName,
        gender: Gender.erkek,
        relation: kadinCocuk.relation,
        age: kadinCocuk.age,
        isAlive: true,
        inPlayerHousehold: false,
        employment: kadinCocuk.employment,
        occupation: kadinCocuk.occupation,
        wealth: kadinCocuk.wealth,
        bond: kadinCocuk.bond,
        city: kadinCocuk.city,
        motherId: kadinCocuk.motherId,
        development: kadinCocuk.development,
      );
      final GameState s = taban.copyWith(
        people: List<Person>.unmodifiable(<Person>[
          for (final Person p in taban.people)
            if (p.id == 'cocuk-evli') erkekCocuk else p,
        ]),
      );
      final Person cocuk = s.personById('cocuk-evli')!;
      for (int i = 0; i < 2000; i++) {
        final Person? torun = Grandchildren.maybeBorn(
          state: s,
          child: cocuk,
          rng: Random(i),
        );
        if (torun == null) continue;
        expect(torun.fatherId, 'cocuk-evli');
        expect(torun.motherId, 'cocugunesi-cocuk-evli-1');
        return;
      }
      fail('2000 denemede torun doğmadı.');
    });
  });
}

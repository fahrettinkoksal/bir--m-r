// Paket BK/4 — çocuğun yaş kademesi.
//
// **Bu dosyanın asıl işi bir çakışmayı sabitlemek.** Q-203 kademeyi
// "bebek 0-2" diye önerdi; D-180 (Q-200, onaylı) ise 0-3 / 4-12 /
// 13-17 / 18+ dedi. Öneri kurala uyduruldu, ikinci bir yaş sınırı
// eklenmedi — D-180 tam bu yüzden yazılmıştı: sohbet dalı 12, vakit
// geçirme dalı 3 diyordu ve ikisi birbirini yalanlıyordu.
//
// Bekçi hem eksiği hem **fazla düzeltmeyi** tutar: bebeğin kartında
// ödev satırı çıkmamalı, ama 9 yaşındaki çocuğun ödev satırı da
// kaybolmamalı.
library;

import 'dart:math';

import 'package:bir_omur/domain/family/child_stage.dart';
import 'package:bir_omur/domain/generation/life_generator.dart';
import 'package:bir_omur/domain/interaction/family_interactions.dart';
import 'package:bir_omur/domain/interaction/interaction_policy.dart';
import 'package:bir_omur/domain/models/education.dart';
import 'package:bir_omur/domain/models/game_state.dart';
import 'package:bir_omur/domain/models/gender.dart';
import 'package:bir_omur/domain/models/interaction.dart';
import 'package:bir_omur/domain/models/pending_notice.dart';
import 'package:bir_omur/domain/models/person.dart';
import 'package:bir_omur/domain/models/person_development.dart';
import 'package:bir_omur/domain/models/relation.dart';
import 'package:bir_omur/domain/models/stats.dart';
import 'package:bir_omur/domain/models/wealth.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const FamilyInteractions etkilesim = FamilyInteractions();

  GameState hayatCocukla(int yas) {
    final GameState base =
        LifeGenerator.seeded(64).generate(mode: StartMode.tamamenRastgele);
    final GameState s = base.copyWith(
      pendingEvent: null,
      notices: const <PendingNotice>[],
      player: base.player.copyWith(age: 40, wallet: 900000),
      movedOut: true,
    );
    final SchoolLevel? kademe = yas >= 7 && yas <= 10
        ? SchoolLevel.ilkokul
        : yas >= 11 && yas <= 14
            ? SchoolLevel.ortaokul
            : yas >= 15 && yas <= 17
                ? SchoolLevel.lise
                : null;
    final Person cocuk = Person(
      id: 'cocuk-bk4',
      firstName: 'Deniz',
      lastName: s.player.lastName,
      gender: Gender.kadin,
      relation: RelationType.cocuk,
      age: yas,
      isAlive: true,
      inPlayerHousehold: true,
      employment: kademe == null
          ? (yas >= 18 ? EmploymentStatus.issiz : EmploymentStatus.cocuk)
          : EmploymentStatus.ogrenci,
      wealth: null,
      schoolLevel: kademe,
      bond: 60,
      happiness: 60,
      development: PersonDevelopment(
        stats: const Stats(
          appearance: 55,
          happiness: 60,
          health: 70,
          intelligence: 55,
          charisma: 50,
        ),
        tracksLife: true,
        schoolLevel: kademe,
        grade: kademe?.firstGrade,
        money: 0,
      ),
    );
    return s.copyWith(
      people: List<Person>.unmodifiable(<Person>[...s.people, cocuk]),
    );
  }

  group('Kademe eşikleri D-180 ile aynı', () {
    test('dört kademe ve sınırları', () {
      expect(ChildStage.values, hasLength(4));
      expect(ChildStage.bebek.firstAge, 0);
      expect(ChildStage.bebek.lastAge, 3);
      expect(ChildStage.cocuk.firstAge, 4);
      expect(ChildStage.cocuk.lastAge, 12);
      expect(ChildStage.ergen.firstAge, 13);
      expect(ChildStage.ergen.lastAge, 17);
      expect(ChildStage.yetiskin.firstAge, 18);
    });

    test('her yaş tek bir kademeye düşer', () {
      for (int yas = 0; yas <= 120; yas++) {
        final List<ChildStage> uyanlar = ChildStage.values
            .where((ChildStage k) => yas >= k.firstAge && yas <= k.lastAge)
            .toList(growable: false);
        expect(uyanlar, hasLength(1), reason: '$yas yaş');
        expect(ChildStage.of(yas), uyanlar.single, reason: '$yas yaş');
      }
    });

    test('sınır yaşları doğru kademede', () {
      expect(ChildStage.of(0), ChildStage.bebek);
      expect(ChildStage.of(3), ChildStage.bebek);
      expect(ChildStage.of(4), ChildStage.cocuk);
      expect(ChildStage.of(12), ChildStage.cocuk);
      expect(ChildStage.of(13), ChildStage.ergen);
      expect(ChildStage.of(17), ChildStage.ergen);
      expect(ChildStage.of(18), ChildStage.yetiskin);
      expect(ChildStage.of(40), ChildStage.yetiskin);
    });
  });

  group('Liste kademeye göre daralır', () {
    test('bebekte ebeveynlik eylemi hiç görünmez', () {
      final Set<InteractionKind> bebek =
          meaningfulKindsForChildStage(ChildStage.bebek);
      for (final InteractionKind k in InteractionKind.values) {
        if (!k.childOnly) continue;
        expect(bebek, isNot(contains(k)), reason: k.name);
      }
      // Kucağa alınır ve konuşulur: bunlar kalkmaz.
      expect(bebek, contains(InteractionKind.vakitGecir));
      expect(bebek, contains(InteractionKind.sohbet));
    });

    test('çocuk ve ergende dört eylem de açık', () {
      for (final ChildStage k in <ChildStage>[
        ChildStage.cocuk,
        ChildStage.ergen,
      ]) {
        final Set<InteractionKind> liste = meaningfulKindsForChildStage(k);
        for (final InteractionKind tur in InteractionKind.values) {
          if (!tur.childOnly) continue;
          expect(liste, contains(tur), reason: '${k.name} / ${tur.name}');
        }
      }
    });

    test('yetişkin çocukta ebeveynlik eylemi kapanır', () {
      final Set<InteractionKind> yetiskin =
          meaningfulKindsForChildStage(ChildStage.yetiskin);
      for (final InteractionKind k in InteractionKind.values) {
        if (!k.childOnly) continue;
        expect(yetiskin, isNot(contains(k)), reason: k.name);
      }
      expect(yetiskin, contains(InteractionKind.vakitGecir));
    });
  });

  group('Gerçek durumda açılan eylemler', () {
    List<InteractionKind> acikOlanlar(int yas) {
      final GameState s = hayatCocukla(yas);
      return etkilesim.availableKinds(s, s.personById('cocuk-bk4')!);
    }

    test('2 yaşındaki bebekte ödev/harçlık/kurs/kural yok', () {
      final List<InteractionKind> acik = acikOlanlar(2);
      expect(acik.where((InteractionKind k) => k.childOnly), isEmpty);
      expect(acik, contains(InteractionKind.vakitGecir));
    });

    test('9 yaşındaki çocukta ödev ve harçlık var (fazla düzeltme yok)', () {
      final List<InteractionKind> acik = acikOlanlar(9);
      expect(acik, contains(InteractionKind.odevYardim));
      expect(acik, contains(InteractionKind.harclikVer));
      expect(acik, contains(InteractionKind.kuralKoy));
    });

    test('5 yaşında kurs açık ama harçlık henüz değil', () {
      // Kademe içindeki ince koşul: harçlık 7 yaşından, kurs 6'dan.
      // Kademe bu koşulları ezmez.
      final List<InteractionKind> acik = acikOlanlar(5);
      expect(acik, isNot(contains(InteractionKind.harclikVer)));
      expect(acik, isNot(contains(InteractionKind.odevYardim)),
          reason: '5 yaşında okula gitmiyor');
    });

    test('16 yaşındaki ergende dördü de var', () {
      final List<InteractionKind> acik = acikOlanlar(16);
      for (final InteractionKind k in InteractionKind.values) {
        if (!k.childOnly) continue;
        expect(acik, contains(k), reason: k.name);
      }
    });

    test('22 yaşındaki çocukta ebeveynlik eylemi yok', () {
      final List<InteractionKind> acik = acikOlanlar(22);
      expect(acik.where((InteractionKind k) => k.childOnly), isEmpty);
    });

    test('kademe dışı eylem denenirse gerekçe kademeyi söyler', () {
      final GameState bebekli = hayatCocukla(2);
      final InteractionAvailability u = etkilesim.availability(
        bebekli,
        bebekli.personById('cocuk-bk4')!,
        InteractionKind.kuralKoy,
      );
      expect(u.isAllowed, isFalse);
      expect(u.reason, contains('çok küçük'));

      final GameState yetiskinli = hayatCocukla(25);
      final InteractionAvailability u2 = etkilesim.availability(
        yetiskinli,
        yetiskinli.personById('cocuk-bk4')!,
        InteractionKind.harclikVer,
      );
      expect(u2.isAllowed, isFalse);
      expect(u2.reason, contains('kendi kararlarını'));
    });

    test('bebeğe kural koymak denenirse durum değişmez', () {
      final GameState s = hayatCocukla(1);
      final InteractionResult r = etkilesim.perform(
        state: s,
        personId: 'cocuk-bk4',
        kind: InteractionKind.kuralKoy,
        rng: Random(1),
      );
      expect(r.outcome.accepted, isFalse);
      expect(r.state.people, s.people);
      expect(r.state.player.wallet, s.player.wallet);
    });
  });
}

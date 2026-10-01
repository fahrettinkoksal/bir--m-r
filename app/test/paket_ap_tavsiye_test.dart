// Paket AP §1, §40, §41 — tavsiye ihtimali kaydırır, karar vermez.
library;

import 'dart:math';

import 'package:bir_omur/domain/family/child_advice.dart';
import 'package:bir_omur/domain/generation/child_progression.dart';
import 'package:bir_omur/domain/models/game_state.dart';
import 'package:bir_omur/domain/models/gender.dart';
import 'package:bir_omur/domain/models/person.dart';
import 'package:bir_omur/domain/models/person_development.dart';
import 'package:bir_omur/domain/models/relation.dart';
import 'package:bir_omur/domain/models/stats.dart';
import 'package:bir_omur/domain/models/wealth.dart';
import 'package:flutter_test/flutter_test.dart';

import 'paket_ao_aile_v2_test.dart' show aileliHayat;

const Stats _ortaStats = Stats(
  appearance: 55,
  happiness: 65,
  health: 75,
  intelligence: 55,
  charisma: 55,
);

Person liseBitirmis({int age = 18, int bond = 70}) => Person(
      id: 'cocuk-tavsiye',
      firstName: 'Deniz',
      lastName: 'Kaya',
      gender: Gender.kadin,
      relation: RelationType.cocuk,
      age: age,
      isAlive: true,
      inPlayerHousehold: true,
      employment: EmploymentStatus.issiz,
      wealth: null,
      bond: bond,
      development: const PersonDevelopment(
        tracksLife: true,
        finishedSchool: true,
        stats: _ortaStats,
      ),
    );

GameState tavsiyeHayati({int bond = 70, int cocukYasi = 18}) {
  final GameState taban = aileliHayat(seed: 3, age: 45);
  return taban.copyWith(
    people: List<Person>.unmodifiable(<Person>[
      ...taban.people,
      liseBitirmis(age: cocukYasi, bond: bond),
    ]),
  );
}

void main() {
  group('§40 — tavsiye verilebilirlik ve gerekçe', () {
    test('küçük çocuğa bu konuşma yapılmaz, gerekçesi yazılır', () {
      final GameState s = tavsiyeHayati(cocukYasi: 10);
      final String? engel = ChildAdvice.blockReason(s, 'cocuk-tavsiye');
      expect(engel, isNotNull);
      expect(engel, contains('küçük'));
      expect(ChildAdvice.canAdvise(s, 'cocuk-tavsiye'), isFalse);
    });

    test('soğuma süresi: her yıl aynı konuşma yapılmaz (§46)', () {
      GameState s = tavsiyeHayati();
      expect(ChildAdvice.canAdvise(s, 'cocuk-tavsiye'), isTrue);
      s = ChildAdvice.advise(s, 'cocuk-tavsiye').state;
      expect(ChildAdvice.canAdvise(s, 'cocuk-tavsiye'), isFalse);
      final String? engel = ChildAdvice.blockReason(s, 'cocuk-tavsiye');
      expect(engel, contains('yıl daha beklemen'));

      final GameState sonra = s.copyWith(
        player: s.player.copyWith(
          age: s.player.age + ChildAdvice.prototypeOnlyCooldown,
        ),
      );
      expect(ChildAdvice.canAdvise(sonra, 'cocuk-tavsiye'), isTrue);
    });

    test('konuşma yakınlığı biraz artırır, sonuç söylenmez', () {
      final GameState s = tavsiyeHayati();
      final ({GameState state, String text}) r =
          ChildAdvice.advise(s, 'cocuk-tavsiye');
      expect(r.state.personById('cocuk-tavsiye')!.bond,
          s.personById('cocuk-tavsiye')!.bond +
              ChildAdvice.prototypeOnlyBondGain);
      expect(r.text, contains('kararı ona bıraktın'));
      expect(r.text, isNot(contains('ikna')));
    });

    test('olmayan ve vefat etmiş kişide gerekçe yazılır', () {
      final GameState s = tavsiyeHayati();
      expect(ChildAdvice.blockReason(s, 'yok-boyle-biri'), isNotNull);
      final GameState olu = s.copyWith(
        people: List<Person>.unmodifiable(<Person>[
          for (final Person p in s.people)
            if (p.id == 'cocuk-tavsiye') p.copyWith(isAlive: false) else p,
        ]),
      );
      expect(ChildAdvice.blockReason(olu, 'cocuk-tavsiye'), isNotNull);
    });
  });

  group('§41 — etki küçük, sönüyor ve yakınlığa bağlı', () {
    test('tavsiye verilmediyse pay tam olarak sıfır', () {
      final GameState s = tavsiyeHayati();
      expect(ChildAdvice.boostFor(s, s.personById('cocuk-tavsiye')!), 0,
          reason: 'Pay 0 olmazsa oyunun zar sırası kayardı.');
    });

    test('pay tavandan büyük olamaz', () {
      final GameState s =
          ChildAdvice.advise(tavsiyeHayati(bond: 100), 'cocuk-tavsiye').state;
      expect(
        ChildAdvice.boostFor(s, s.personById('cocuk-tavsiye')!),
        lessThanOrEqualTo(ChildAdvice.prototypeOnlyBoost),
      );
    });

    test('yıl geçtikçe sönüyor ve sonunda sıfırlanıyor', () {
      final GameState s =
          ChildAdvice.advise(tavsiyeHayati(), 'cocuk-tavsiye').state;
      double onceki =
          ChildAdvice.boostFor(s, s.personById('cocuk-tavsiye')!);
      expect(onceki, greaterThan(0));
      for (int yil = 1; yil <= ChildAdvice.prototypeOnlyFadeYears; yil++) {
        final GameState sonra = s.copyWith(
          player: s.player.copyWith(age: s.player.age + yil),
        );
        final double simdi =
            ChildAdvice.boostFor(sonra, sonra.personById('cocuk-tavsiye')!);
        expect(simdi, lessThan(onceki), reason: '$yil. yıl sönmedi');
        onceki = simdi;
      }
      expect(onceki, 0, reason: 'Bir konuşma ömür boyu yön vermez.');
    });

    test('arası çok kopuk çocuk dinlemez ama hayatı durmaz (§42)', () {
      final GameState s = ChildAdvice.advise(
        tavsiyeHayati(bond: ChildAdvice.prototypeOnlyDeafBond - 1),
        'cocuk-tavsiye',
      ).state;
      // Konuşma yakınlığı artırdı; yine de eşiğin altındaysa pay 0.
      final Person cocuk = s.personById('cocuk-tavsiye')!;
      if (cocuk.bond < ChildAdvice.prototypeOnlyDeafBond) {
        expect(ChildAdvice.boostFor(s, cocuk), 0);
      }
      // Hayatı yine ilerliyor: beş yılda yaş ve kayıt değişiyor.
      Person ilerleyen = cocuk;
      for (int i = 0; i < 5; i++) {
        ilerleyen = ilerleyen.copyWith(age: ilerleyen.age + 1);
        ilerleyen = ChildProgression.advance(ilerleyen, Random(i)).person;
      }
      expect(ilerleyen.age, cocuk.age + 5);
    });
  });

  group('§1 — tavsiye dikte etmez ama ölçülebilir bir etkisi var', () {
    /// Aynı tohum dizisiyle, yalnızca tavsiye payı farklı: üniversiteye
    /// başlayan çocuk sayısı ölçülüyor.
    int universiteyeBaslayan(double pay) {
      int sayi = 0;
      for (int tohum = 0; tohum < 400; tohum++) {
        Person cocuk = liseBitirmis();
        final ({Person person, List<String> news}) r =
            ChildProgression.advance(cocuk, Random(tohum), adviceBoost: pay);
        cocuk = r.person;
        if (cocuk.development?.university != null) sayi++;
      }
      return sayi;
    }

    test('pay 0 iken ürün bugünkü davranışını aynen koruyor', () {
      // Aynı tohumla, payı geçmeden ve 0 geçerek: sonuç birebir aynı
      // olmalı. Aksi hâlde yeni alan eski hayatları değiştirirdi.
      for (int tohum = 0; tohum < 60; tohum++) {
        final Person a =
            ChildProgression.advance(liseBitirmis(), Random(tohum)).person;
        final Person b = ChildProgression
            .advance(liseBitirmis(), Random(tohum), adviceBoost: 0)
            .person;
        expect(b.development?.university, a.development?.university);
        expect(b.development?.jobId, a.development?.jobId);
        expect(b.employment, a.employment);
      }
    });

    test('tavsiye üniversiteye gitme ihtimalini yukarı kaydırıyor', () {
      final int paysiz = universiteyeBaslayan(0);
      final int payli =
          universiteyeBaslayan(ChildAdvice.prototypeOnlyBoost);
      expect(payli, greaterThan(paysiz),
          reason: 'Tavsiyenin ölçülebilir bir etkisi olmalı '
              '(paysız $paysiz, paylı $payli).');
      // Ama dikte etmiyor: herkes üniversiteye gitmiyor.
      expect(payli, lessThan(400),
          reason: '§1: tavsiye kararı belirlemez.');
      // Ve paysız durumda da bir kısmı gidiyor: pay şart değil.
      expect(paysiz, greaterThan(0));
    });
  });
}

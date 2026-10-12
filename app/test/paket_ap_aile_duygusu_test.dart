// Paket AP §42-§46 — gurur, endişe, yakınlık, mesafe ve soğuma.
library;

import 'dart:math';

import 'package:bir_omur/domain/family/child_school_issue.dart';
import 'package:bir_omur/domain/family/family_mood.dart';
import 'package:bir_omur/domain/generation/child_progression.dart';
import 'package:bir_omur/domain/models/family_issue.dart';
import 'package:bir_omur/domain/models/game_state.dart';
import 'package:bir_omur/domain/models/gender.dart';
import 'package:bir_omur/domain/models/person.dart';
import 'package:bir_omur/domain/models/person_development.dart';
import 'package:bir_omur/domain/models/relation.dart';
import 'package:bir_omur/domain/models/stats.dart';
import 'package:bir_omur/domain/models/wealth.dart';
import 'package:flutter_test/flutter_test.dart';

import 'paket_ao_aile_v2_test.dart' show aileliHayat;

GameState duyguHayati({
  int seed = 6,
  int playerAge = 45,
  int cocukYasi = 12,
  int bag = 70,
  String? sehir,
  int oyuncuMutlulugu = 60,
}) {
  final GameState taban = aileliHayat(seed: seed, age: playerAge);
  return taban.copyWith(
    player: taban.player.copyWith(
      stats: taban.player.stats.copyWith(happiness: oyuncuMutlulugu),
    ),
    people: List<Person>.unmodifiable(<Person>[
      ...taban.people,
      Person(
        id: 'cocuk-duygu',
        firstName: 'Deniz',
        lastName: taban.player.lastName,
        gender: Gender.kadin,
        relation: RelationType.cocuk,
        age: cocukYasi,
        isAlive: true,
        inPlayerHousehold: true,
        employment: EmploymentStatus.ogrenci,
        wealth: null,
        bond: bag,
        city: sehir ?? taban.player.currentCity,
        motherId: taban.player.id,
        development: PersonDevelopment(
          tracksLife: true,
          grade: cocukYasi - 5,
          stats: const Stats(
            appearance: 55,
            happiness: 70,
            health: 75,
            intelligence: 70,
            charisma: 55,
          ),
        ),
      ),
    ]),
  );
}

/// O yıl başarı olmuş gibi işaretler.
GameState basariIsaretle(GameState s, int yas) => s.copyWith(
      lastInteractionAge: <String, int>{
        ...s.lastInteractionAge,
        FamilyMood.achievementKey('cocuk-duygu'): yas,
      },
    );

void main() {
  group('§44 — gurur gerçek bir olaydan doğar', () {
    test('o yıl başarı olmadıysa mutluluk değişmez', () {
      final GameState s = duyguHayati();
      final int once = s.player.stats.happiness;
      final GameState sonra =
          FamilyMood.advanceYear(s, s.player.age).state;
      expect(sonra.player.stats.happiness, once,
          reason: '"Aile var, o yüzden mutlusun" diye bir etki olmamalı.');
    });

    test('o yıl başarı olduysa mutluluk artar', () {
      final GameState s = basariIsaretle(duyguHayati(), 45);
      final ({GameState state, List<String> logTexts}) r =
          FamilyMood.advanceYear(s, 45);
      expect(r.state.player.stats.happiness,
          greaterThan(s.player.stats.happiness));
      expect(r.logTexts, isNotEmpty);
    });

    test('geçen yılın başarısı bu yıl tekrar yazılmaz', () {
      final GameState s = basariIsaretle(duyguHayati(), 44);
      final GameState sonra = FamilyMood.advanceYear(s, 45).state;
      expect(sonra.player.stats.happiness, s.player.stats.happiness);
    });
  });

  group('§45-§46 — endişe ve soğuma', () {
    GameState meseleli({int bag = 70, String? sehir}) {
      GameState s = duyguHayati(bag: bag, sehir: sehir);
      s = s.openFamilyIssue(
        kind: FamilyIssueKind.cocukOkul,
        personId: 'cocuk-duygu',
      );
      return s;
    }

    test('o yıl konuşulan açık mesele mutluluğu düşürür', () {
      final GameState s = meseleli();
      final GameState sonra =
          FamilyMood.advanceYear(s, s.player.age).state;
      expect(sonra.player.stats.happiness,
          lessThan(s.player.stats.happiness));
    });

    test('dört yıl süren mesele dört kez -3 basmaz (§46)', () {
      GameState s = meseleli();
      final int baslangic = s.player.stats.happiness;
      final String id = s.familyIssues.first.id;
      int yas = s.player.age;
      int kayitSayisi = 0;
      for (int i = 0; i < 4; i++) {
        s = s.copyWith(player: s.player.copyWith(age: yas));
        s = s.updateFamilyIssue(id, lastEventAge: yas);
        final ({GameState state, List<String> logTexts}) r =
            FamilyMood.advanceYear(s, yas);
        s = r.state;
        kayitSayisi += r.logTexts.length;
        yas++;
      }
      expect(kayitSayisi, lessThan(4),
          reason: 'Soğuma süresi her yıl yeni bir kayıt yazmayı engellemeli.');
      expect(baslangic - s.player.stats.happiness,
          lessThanOrEqualTo(FamilyMood.prototypeOnlyWorry * 2),
          reason: 'Aynı mesele üst üste mutluluk eritmemeli.');
    });

    test('yıllık tavan: beş sorunlu çocuk mutluluğu dibe vurmaz', () {
      GameState s = duyguHayati();
      // Beş çocuk, beşinin de o yıl konuşulan meselesi var.
      final List<Person> kisiler = <Person>[...s.people];
      for (int k = 0; k < 5; k++) {
        kisiler.add(
          Person(
            id: 'cocuk-c$k',
            firstName: 'Ada$k',
            lastName: s.player.lastName,
            gender: Gender.kadin,
            relation: RelationType.cocuk,
            age: 10 + k,
            isAlive: true,
            inPlayerHousehold: true,
            employment: EmploymentStatus.ogrenci,
            wealth: null,
            bond: 70,
            city: s.player.currentCity,
            motherId: s.player.id,
            development: const PersonDevelopment(
              tracksLife: true,
              grade: 5,
              stats: Stats(
                appearance: 55,
                happiness: 70,
                health: 75,
                intelligence: 70,
                charisma: 55,
              ),
            ),
          ),
        );
      }
      s = s.copyWith(people: List<Person>.unmodifiable(kisiler));
      // §3 yüzünden tek kapıdan beş mesele açılamaz; test duygu tavanını
      // ölçtüğü için meseleler doğrudan kuruluyor.
      final List<FamilyIssue> meseleler = <FamilyIssue>[
        for (int k = 0; k < 5; k++)
          FamilyIssue(
            id: 'm$k',
            kind: FamilyIssueKind.cocukOkul,
            personId: 'cocuk-c$k',
            openedAtAge: s.player.age,
            lastEventAge: s.player.age,
          ),
      ];
      s = s.copyWith(familyIssues: List<FamilyIssue>.unmodifiable(meseleler));

      final int once = s.player.stats.happiness;
      final GameState sonra =
          FamilyMood.advanceYear(s, s.player.age).state;
      expect(once - sonra.player.stats.happiness,
          lessThanOrEqualTo(FamilyMood.prototypeOnlyYearlyCap),
          reason: 'Tek yılda ailenin toplam etkisi tavanı aşmamalı.');
    });
  });

  group('§42-§43 — yakınlık ve mesafe büyüklüğü değiştirir, varlığı değil',
      () {
    test('arası kopuk çocuğun haberi daha az dokunur ama dokunur', () {
      final GameState yakin = basariIsaretle(duyguHayati(bag: 80), 45);
      final GameState uzak = basariIsaretle(duyguHayati(bag: 10), 45);
      final int yakinEtki =
          FamilyMood.advanceYear(yakin, 45).state.player.stats.happiness -
              yakin.player.stats.happiness;
      final int uzakEtki =
          FamilyMood.advanceYear(uzak, 45).state.player.stats.happiness -
              uzak.player.stats.happiness;
      expect(uzakEtki, lessThan(yakinEtki));
      expect(uzakEtki, greaterThan(0),
          reason: 'Kendi çocuğunun haberi hiç dokunmaz diye bir kural yok.');
    });

    test('başka şehirdeki çocuk uzak sayılır, şehri bilinmeyen sayılmaz', () {
      final GameState uzak = duyguHayati(sehir: 'Yokistan');
      expect(
        FamilyMood.livesFarAway(uzak, uzak.personById('cocuk-duygu')!),
        isTrue,
      );
      final GameState bilinmeyen = duyguHayati().copyWith(
        people: List<Person>.unmodifiable(<Person>[
          for (final Person p in duyguHayati().people)
            if (p.id == 'cocuk-duygu') p.copyWith(city: null) else p,
        ]),
      );
      expect(
        FamilyMood.livesFarAway(
          bilinmeyen,
          bilinmeyen.personById('cocuk-duygu')!,
        ),
        isFalse,
        reason: 'Bilinmeyen bilgi olumsuz yorumlanmaz.',
      );
    });

    test('bond düşük diye çocuğun hayatı DURMAZ (§42)', () {
      // Yakınlığı sıfır olan çocuk yine okuyor, yine yaş alıyor, yine
      // kendi hayatını yaşıyor.
      Person cocuk = Person(
        id: 'kopuk',
        firstName: 'Ege',
        lastName: 'Kaya',
        gender: Gender.erkek,
        relation: RelationType.cocuk,
        age: 10,
        isAlive: true,
        inPlayerHousehold: false,
        employment: EmploymentStatus.ogrenci,
        wealth: null,
        bond: 0,
        development: const PersonDevelopment(
          tracksLife: true,
          grade: 5,
          stats: Stats(
            appearance: 55,
            happiness: 70,
            health: 75,
            intelligence: 70,
            charisma: 55,
          ),
        ),
      );
      final int baslangicSinif = cocuk.development!.grade!;
      for (int i = 0; i < 5; i++) {
        cocuk = cocuk.copyWith(age: cocuk.age + 1);
        cocuk = ChildProgression.advance(cocuk, Random(i)).person;
      }
      expect(cocuk.development!.grade ?? 99, greaterThan(baslangicSinif),
          reason: 'Yakınlık sıfır olsa da okul hayatı ilerlemeli.');
    });
  });

  group('üretim yolu', () {
    test('okul başarısı üretim yolunda gurura dönüşüyor', () {
      // Başarı ChildSchoolIssue'dan çıkıyor, gurur FamilyMood'dan: iki
      // sistem aynı anahtarı okuyor mu?
      final GameState s = duyguHayati();
      for (int i = 0; i < 400; i++) {
        final ({GameState state, dynamic notice, String? logText}) r =
            ChildSchoolIssue.maybeAchievement(s, s.player.age, Random(i));
        if (r.notice == null) continue;
        final GameState sonra =
            FamilyMood.advanceYear(r.state, s.player.age).state;
        expect(sonra.player.stats.happiness,
            greaterThan(s.player.stats.happiness),
            reason: 'Başarı gerçekleşti ama oyuncuya hiç dokunmadı.');
        return;
      }
      fail('400 denemede hiç başarı çıkmadı; ölçüm yapılamadı.');
    });
  });
}

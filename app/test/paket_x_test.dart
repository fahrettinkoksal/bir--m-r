import 'dart:math';

import 'package:bir_omur/data/activity_catalog.dart';
import 'package:bir_omur/data/hobby_catalog.dart';
import 'package:bir_omur/data/martial_arts_catalog.dart';
import 'package:bir_omur/data/media_catalog.dart';
import 'package:bir_omur/data/university_catalog.dart';
import 'package:bir_omur/domain/generation/life_generator.dart';
import 'package:bir_omur/domain/generation/life_progression.dart';
import 'package:bir_omur/domain/interaction/parenthood.dart';
import 'package:bir_omur/domain/models/game_state.dart';
import 'package:bir_omur/domain/models/gender.dart';
import 'package:bir_omur/domain/interaction/marriage_engine.dart';
import 'package:bir_omur/domain/models/marriage.dart';
import 'package:bir_omur/domain/models/pending_notice.dart';
import 'package:bir_omur/domain/models/person.dart';
import 'package:bir_omur/domain/models/pregnancy.dart';
import 'package:bir_omur/domain/models/relation.dart';
import 'package:bir_omur/domain/models/wealth.dart';
import 'package:flutter_test/flutter_test.dart';

/// Paket X — A grubu: ikiz gebelik (D-151).
void main() {
  GameState hayat({int seed = 8, int age = 30, int wallet = 900000}) {
    final GameState base =
        LifeGenerator.seeded(seed).generate(mode: StartMode.tamamenRastgele);
    return base.copyWith(
      pendingEvent: null,
      notices: const <PendingNotice>[],
      player: base.player.copyWith(age: age, wallet: wallet),
      movedOut: true,
    );
  }

  /// Doğuma hazır, evli, bebek bekleyen bir hayat.
  GameState bebekBekleyen({int seed = 8, int age = 30}) {
    GameState s = hayat(seed: seed, age: age);
    final Person partner = Person(
      id: 'partner-1',
      firstName: 'Eren',
      lastName: 'Yıldız',
      gender: s.player.gender == Gender.kadin ? Gender.erkek : Gender.kadin,
      relation: RelationType.es,
      age: age,
      isAlive: true,
      inPlayerHousehold: true,
      employment: EmploymentStatus.calisiyor,
      wealth: WealthTier.ortaHalli,
      bond: 80,
    );
    s = s.copyWith(
      people: List<Person>.unmodifiable(<Person>[...s.people, partner]),
      marriage: Marriage(
        spouseId: partner.id,
        marriedAtAge: age - 2,
        status: MarriageStatus.evli,
      ),
      pregnancy: Pregnancy(
        partnerId: partner.id,
        startedAtAge: age,
        expecting: ExpectingParty.oyuncu,
      ),
    );
    return s;
  }

  group('İkiz gebelik (D-151)', () {
    test('ikiz bayrağı aynı yıl ikinci bebeğin önündeki engeli kaldırır', () {
      final GameState s = bebekBekleyen();
      final FamilyResult ilk = const Parenthood()
          .haveChild(s, Random(1), coParentId: 'partner-1');
      expect(ilk.outcome.applied, isTrue);
      expect(ilk.state.children, hasLength(1));

      // İkiz olmadan aynı yıl ikinci bebek **engellenir**.
      final FamilyResult tek = const Parenthood()
          .haveChild(ilk.state, Random(2), coParentId: 'partner-1');
      expect(tek.outcome.applied, isFalse);
      expect(tek.outcome.text, contains('Bu yıl'));

      // İkiz bayrağıyla aynı doğumun ikinci bebeği gelir.
      final FamilyResult ikiz = const Parenthood().haveChild(
        ilk.state,
        Random(2),
        coParentId: 'partner-1',
        twin: true,
      );
      expect(ikiz.outcome.applied, isTrue);
      expect(ikiz.state.children, hasLength(2));
    });

    test('ikizlerin adları ve kimlikleri ayrıdır', () {
      final GameState s = bebekBekleyen();
      final FamilyResult ilk = const Parenthood()
          .haveChild(s, Random(1), coParentId: 'partner-1');
      final FamilyResult ikiz = const Parenthood().haveChild(
        ilk.state,
        Random(2),
        coParentId: 'partner-1',
        twin: true,
      );
      final List<Person> cocuklar = ikiz.state.children;
      expect(cocuklar[0].id, isNot(cocuklar[1].id));
      expect(cocuklar[0].firstName, isNot(cocuklar[1].firstName));
      // İkisi de aynı yıl doğdu.
      expect(cocuklar[0].age, 0);
      expect(cocuklar[1].age, 0);
    });

    test('ikiz aynı diğer ebeveynden olur, uydurma ebeveyn yazılmaz', () {
      final GameState s = bebekBekleyen();
      final FamilyResult ilk = const Parenthood()
          .haveChild(s, Random(1), coParentId: 'partner-1');
      final FamilyResult ikiz = const Parenthood().haveChild(
        ilk.state,
        Random(2),
        coParentId: 'partner-1',
        twin: true,
      );
      for (final Person c in ikiz.state.children) {
        expect(c.development?.otherParentId, 'partner-1');
      }
    });

    test('ikiz üst sınırı aşmaz: 4 çocuk varken ikinci bebek gelmez', () {
      GameState s = bebekBekleyen();
      // Üç çocuk ekle; dördüncü doğumdan sonra sınır dolar.
      for (int i = 1; i <= 3; i++) {
        s = s.copyWith(
          people: List<Person>.unmodifiable(<Person>[
            ...s.people,
            Person(
              id: 'cocuk-$i',
              firstName: 'Çocuk$i',
              lastName: 'Yıldız',
              gender: Gender.erkek,
              relation: RelationType.cocuk,
              age: 5 + i,
              isAlive: true,
              inPlayerHousehold: true,
              employment: EmploymentStatus.cocuk,
              wealth: null,
              bond: 70,
            ),
          ]),
        );
      }
      final FamilyResult ilk = const Parenthood()
          .haveChild(s, Random(1), coParentId: 'partner-1');
      expect(ilk.outcome.applied, isTrue);
      expect(ilk.state.children, hasLength(4));

      final FamilyResult ikiz = const Parenthood().haveChild(
        ilk.state,
        Random(2),
        coParentId: 'partner-1',
        twin: true,
      );
      expect(
        ikiz.outcome.applied,
        isFalse,
        reason: 'İkiz bile en fazla çocuk sınırını aşamaz',
      );
    });

    test('yıl ilerleyince ikiz gerçekten doğuyor ve tek bildirim geliyor', () {
      int ikizDogumu = 0;
      int tekDogum = 0;
      for (int seed = 0; seed < 400; seed++) {
        final GameState s = bebekBekleyen(seed: 8, age: 30);
        final GameState sonra =
            LifeProgression(Random(seed)).advanceOneYear(s);
        final int bebek =
            sonra.children.where((Person p) => p.age == 0).length;
        if (bebek >= 2) {
          ikizDogumu++;
          // İki ayrı doğum penceresi değil, tek ikiz bildirimi açılır.
          final List<PendingNotice> dogum = sonra.notices
              .where((PendingNotice n) => n.id.startsWith('ikiz-'))
              .toList(growable: false);
          expect(dogum, hasLength(1));
          expect(dogum.single.text, contains('aynı gün doğdu'));
        } else if (bebek == 1) {
          tekDogum++;
        }
      }
      expect(tekDogum, greaterThan(0), reason: 'Tek doğum hâlâ olağan yol');
      expect(
        ikizDogumu,
        greaterThan(0),
        reason: '400 doğumda hiç ikiz çıkmadıysa bağlantı kopuk demektir',
      );
      expect(
        ikizDogumu,
        lessThan(tekDogum),
        reason: 'İkiz istisna olmalı, kural değil',
      );
    });
  });

  group('Kataloglar genişletildi (D-152)', () {
    test('her hobiyi gerçek bir aktivite besler; sahte hobi yok', () {
      final Set<String> eylemler = <String>{
        for (final ActivityAction a in kActivityActions) a.id,
      };
      for (final HobbyKind h in HobbyKind.values) {
        if (h == HobbyKind.okuma) {
          // Okuma kütüphanede **bitirilen kitapla** beslenir, aktivite
          // kimliğiyle değil (kataloğun kendi notu).
          expect(h.activityIds, isEmpty);
          continue;
        }
        expect(
          h.activityIds,
          isNotEmpty,
          reason: '${h.label} hobisini besleyen eylem yok',
        );
        for (final String id in h.activityIds) {
          expect(
            eylemler,
            contains(id),
            reason: '${h.label} olmayan bir eylemi ($id) besliyor',
          );
        }
      }
    });

    test('hobi kimlikleri ve etiketleri benzersiz', () {
      final List<String> kimlikler =
          HobbyKind.values.map((HobbyKind h) => h.id).toList();
      expect(kimlikler.toSet(), hasLength(kimlikler.length));
      final List<String> etiketler =
          HobbyKind.values.map((HobbyKind h) => h.label).toList();
      expect(etiketler.toSet(), hasLength(etiketler.length));
    });

    test('her hobinin basamakları artan deneyimle sıralı ve ilki sıfır', () {
      for (final HobbyKind h in HobbyKind.values) {
        expect(h.stages.first.experience, 0, reason: h.label);
        for (int i = 1; i < h.stages.length; i++) {
          expect(
            h.stages[i].experience,
            greaterThan(h.stages[i - 1].experience),
            reason: '${h.label} basamak $i',
          );
        }
      }
    });

    test('hobi, bölüm, medya ve dövüş katalogları daraltılmadı', () {
      // Gerileme koruması: bu sayılar **düşerse** bir şey silinmiş olur.
      expect(HobbyKind.values.length, greaterThanOrEqualTo(12));
      expect(kUniversityPrograms.length, greaterThanOrEqualTo(20));
      expect(kMediaOpportunities.length, greaterThanOrEqualTo(14));
      expect(MartialArt.values.length, greaterThanOrEqualTo(6));
    });

    test('üniversite bölümlerinin kimlikleri ve adları benzersiz', () {
      final List<String> kimlikler =
          kUniversityPrograms.map((UniversityProgram p) => p.id).toList();
      expect(kimlikler.toSet(), hasLength(kimlikler.length));
      final List<String> adlar =
          kUniversityPrograms.map((UniversityProgram p) => p.name).toList();
      expect(adlar.toSet(), hasLength(adlar.length));
    });

    test('her bölümün puanı ve süresi makul aralıkta', () {
      for (final UniversityProgram p in kUniversityPrograms) {
        expect(p.minScore, inInclusiveRange(0, 100), reason: p.name);
        expect(p.durationYears, inInclusiveRange(2, 6), reason: p.name);
        expect(p.description, isNotEmpty, reason: p.name);
      }
    });

    test('medya işleri benzersiz ve ün eşiği bölüm eşiğinin altına inmiyor',
        () {
      final List<String> kimlikler =
          kMediaOpportunities.map((MediaOpportunity o) => o.id).toList();
      expect(kimlikler.toSet(), hasLength(kimlikler.length));
      for (final MediaOpportunity o in kMediaOpportunities) {
        expect(
          o.minFame,
          greaterThanOrEqualTo(kMediaSectionMinFame),
          reason: '${o.label} bölümün açılmadığı ünle görünüyor',
        );
        expect(o.fee, greaterThan(0), reason: o.label);
        expect(o.fameGain, greaterThan(0), reason: o.label);
      }
    });

    test('yeni dövüş dallarının eğitmenlik işi ve eşiği gerçek', () {
      for (final MartialArt a in MartialArt.values) {
        expect(
          a.instructorFromLevel,
          lessThan(a.ranks.length),
          reason: '${a.label} eşiği olmayan bir basamağı gösteriyor',
        );
        expect(a.ranks.first.lessonsNeeded, 0, reason: a.label);
        expect(a.minAge, greaterThan(0), reason: a.label);
      }
      final List<String> isler = MartialArt.values
          .map((MartialArt a) => a.instructorJobId)
          .toList();
      expect(isler.toSet(), hasLength(isler.length),
          reason: 'İki dal aynı eğitmenlik işine bağlanmış');
    });

    test('yeni kurslar Kurslar mekânında ve yaş sınırı var', () {
      const Set<String> yeni = <String>{
        'yemek_kursu',
        'fotograf_kursu',
        'dans_kursu',
        'satranc_kulubu',
        'yazarlik_atolyesi',
        'bahce_atolyesi',
      };
      for (final String id in yeni) {
        final ActivityAction eylem = kActivityActions.firstWhere(
          (ActivityAction a) => a.id == id,
          orElse: () => throw StateError('$id kataloğa girmemiş'),
        );
        expect(eylem.venue, ActivityVenue.kurs, reason: id);
        expect(eylem.minAge, greaterThan(0), reason: id);
        expect(eylem.cost, greaterThan(0), reason: id);
        expect(hobbyForActivity(id), isNotNull,
            reason: '$id hiçbir hobiyi beslemiyor');
      }
    });
  });
}

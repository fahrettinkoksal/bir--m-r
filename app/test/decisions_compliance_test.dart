/// Faho'nun onayladığı kesin kararlara uygunluk denetimi.
///
/// Amaç: D-053…D-066'ya aykırı eski `prototypeOnly` davranışın sessizce
/// geri gelmemesi. Bu testler denge tartışmaz; **kararın kendisini**
/// korur. Bir sayı değişecekse önce karar değişmeli.
library;

import 'dart:convert';
import 'dart:math';

import 'package:bir_omur/data/activity_catalog.dart';
import 'package:bir_omur/data/economy.dart';
import 'package:bir_omur/data/hobby_catalog.dart';
import 'package:bir_omur/data/job_catalog.dart';
import 'package:bir_omur/data/martial_arts_catalog.dart';
import 'package:bir_omur/data/save/game_state_codec.dart';
import 'package:bir_omur/data/save/save_format.dart';
import 'package:bir_omur/domain/activities/activity_engine.dart';
import 'package:bir_omur/domain/activities/martial_arts_engine.dart';
import 'package:bir_omur/domain/generation/life_generator.dart';
import 'package:bir_omur/domain/interaction/fertility_treatment.dart';
import 'package:bir_omur/domain/models/game_state.dart';
import 'package:bir_omur/domain/models/person.dart';
import 'package:bir_omur/data/social_catalog.dart';
import 'package:bir_omur/domain/models/gender.dart';
import 'package:bir_omur/domain/models/wealth.dart';
import 'package:bir_omur/domain/models/relation.dart';
import 'package:bir_omur/domain/models/social_account.dart';
import 'package:bir_omur/domain/pets/pet_care.dart';
import 'package:bir_omur/domain/social/social_engine.dart';
import 'package:flutter_test/flutter_test.dart';

GameState hayat({int age = 30, int wallet = 5000000}) {
  final GameState taban = LifeGenerator.seeded(
    17,
  ).generate(mode: StartMode.tamamenRastgele);
  return taban.copyWith(
    pendingEvent: null,
    player: taban.player.copyWith(age: age, wallet: wallet),
  );
}

void main() {
  group('D-053 — ekonomi kalibrasyonu', () {
    test('çıpalar kararda yazan değerler', () {
      expect(Economy.netMonthlyMinimumWage, 28075);
      expect(Economy.grossMonthlyMinimumWage, 33030);
      expect(Economy.netYearlyMinimumWage, 336900);
    });

    test('eski ölçekten kalan maaş yok', () {
      // Eski ölçekte en düşük maaş 165.000 ₺/yıl idi: asgari ücretin
      // yarısı. Sabit maaşlı hiçbir iş o bölgeye geri dönmemeli.
      for (final JobType j in kJobCatalog) {
        if (!j.band.sabitMaasli) continue;
        expect(j.yearlySalary, greaterThanOrEqualTo(336900), reason: j.id);
      }
    });
  });

  group('D-054 — tüp bebek', () {
    test('hayat boyu en fazla beş deneme', () {
      expect(FertilityTreatment.maxLifetimeTries, 5);
    });

    test('yılda en fazla bir deneme', () {
      expect(FertilityTreatment.prototypeOnlyTriesPerAge, 1);
    });

    test('beş deneme dolunca gerekçesiyle kapanır', () {
      final GameState taban = hayat();
      final Person es = Person(
        id: 'es-1',
        firstName: 'Deniz',
        lastName: 'Kaya',
        gender: taban.player.gender == Gender.erkek
            ? Gender.kadin
            : Gender.erkek,
        relation: RelationType.sevgili,
        isAlive: true,
        inPlayerHousehold: true,
        employment: EmploymentStatus.calisiyor,
        wealth: WealthTier.ortaHalli,
        age: 30,
        bond: 80,
      );
      final GameState dolu = taban.copyWith(
        people: <Person>[es],
        ivfAttempts: 5,
        unprotectedTries: 99,
      );
      final String engel = FertilityTreatment.blockReason(dolu);
      expect(engel, isNotEmpty);
      expect(
        engel,
        contains('5'),
        reason: 'Ömür sınırı gerekçesi yazmalı, gelen: $engel',
      );
    });

    test('kısırlık ihtimali düşürür ama sıfırlamaz', () {
      expect(FertilityTreatment.prototypeOnlyInfertileFactor, greaterThan(0));
      expect(FertilityTreatment.prototypeOnlyInfertileFactor, lessThan(1));
    });

    test('başarısızlık ilişkiyi ağır cezalandırmaz', () {
      // Karar: "yakınlık kaybı küçük veya koşullu olsun".
      expect(
        FertilityTreatment.prototypeOnlyFailBond.abs(),
        lessThanOrEqualTo(5),
      );
    });
  });

  group('D-057 — hobiler', () {
    test('basamak adları kararda yazan adlar', () {
      const List<String> beklenen = <String>[
        'Hevesli',
        'Meraklı',
        'Düzenli',
        'Tutkulu',
        'Usta',
      ];
      for (final HobbyKind h in HobbyKind.values) {
        expect(
          h.stages.map((HobbyStage s) => s.label).toList(),
          beklenen,
          reason: h.id,
        );
      }
    });

    test('üç yıl uğraşılmayan hobi aktif sayılmaz', () {
      expect(kHobbyActiveWithinYears, 3);
    });

    test('en üst basamak makul bir uğraş süresiyle geliyor', () {
      // Karar: "yaklaşık 10-15 yıllık düzenli uğraş". Kırk yıl gibi
      // aşırı eşikler düşürüldü.
      for (final HobbyKind h in HobbyKind.values) {
        expect(
          h.stages.last.experience,
          lessThanOrEqualTo(50),
          reason: '${h.id} en üst basamağı çok uzak',
        );
      }
    });
  });

  group('D-058 — evcil hayvanlar', () {
    test('aynı anda en fazla üç hayvan', () {
      expect(PetCare.prototypeOnlyMaxLivingPets, 3);
    });
  });

  group('D-059 — yakınlarla etkinlik', () {
    test('ücretli aktivitede iki kişilik maliyet', () {
      const ActivityEngine motor = ActivityEngine();
      final Person yoldas = Person(
        id: 'es-1',
        firstName: 'Deniz',
        lastName: 'Kaya',
        gender: Gender.kadin,
        relation: RelationType.es,
        isAlive: true,
        inPlayerHousehold: true,
        employment: EmploymentStatus.calisiyor,
        wealth: WealthTier.ortaHalli,
        age: 30,
        bond: 80,
      );
      final GameState s = hayat().copyWith(people: <Person>[yoldas]);

      // Yoldaşla gerçekten yapılabilen ilk ücretli eylemi bul.
      for (final ActivityAction a in kActivityActions) {
        if (a.cost <= 0) continue;
        final ActivityResult birlikte = motor.perform(
          state: s,
          action: a,
          rng: Random(1),
          companion: yoldas,
        );
        if (!birlikte.outcome.applied) continue;
        final ActivityResult yalniz = motor.perform(
          state: s,
          action: a,
          rng: Random(1),
        );
        expect(s.player.wallet - yalniz.state.player.wallet, a.cost);
        expect(
          s.player.wallet - birlikte.state.player.wallet,
          a.cost * 2,
          reason: '${a.id}: iki kişilik bilet ödenmeli',
        );
        return;
      }
      fail('Yoldaşla yapılabilen ücretli aktivite bulunamadı');
    });
  });

  group('D-062 — dövüş sanatları', () {
    test('dersler ucuz kalıyor', () {
      final int enFazla = (Economy.netMonthlyMinimumWage * 0.03).round();
      for (final MartialArt a in MartialArt.values) {
        expect(a.lessonCost, lessThanOrEqualTo(enFazla), reason: a.id);
      }
    });

    test('yıllık ders sınırı korunuyor', () {
      expect(kMaxMartialLessonsPerAge, 20);
    });
  });

  group('D-063 — sosyal medya', () {
    test('çapraz yansıma %15', () {
      expect(SocialEngine.prototypeOnlyCrossShare, closeTo(0.15, 0.001));
    });

    test('yıllık büyüme eşiği 5.000 takipçi', () {
      expect(SocialEngine.prototypeOnlyOrganicThreshold, 5000);
    });

    test('durgunluk sistemi duruyor', () {
      expect(SocialEngine.prototypeOnlyDormantAfterYears, 4);
      expect(SocialEngine.prototypeOnlyDormantDecay, closeTo(0.05, 0.001));
    });

    test('küçük yıllık değişim günlüğe yazılmıyor', () {
      // Karar: "her yıl 183 takipçi büyüdü" spam'i olmasın.
      const SocialEngine sosyal = SocialEngine();
      GameState s = hayat(age: 20);
      s = sosyal.openAccount(s, SocialPlatform.video).state;
      s = s.copyWith(
        socialAccounts: s.socialAccounts
            .map((SocialAccount a) => a.copyWith(followers: 6000))
            .toList(growable: false),
      );
      final ({GameState state, List<String> logTexts}) r = sosyal.advanceYear(
        s,
        s.player.age + 1,
      );
      // 6.000'in %6'sı 360: anlamlı sayılmaz, günlüğe girmez.
      // D-063 takipçi **spam'ini** yasaklar: "her yıl 183 takipçi
      // büyüdü" satırı yazılmaz. Ün düşüşü (D-118) ayrı bir haberdir ve
      // oyuncunun görmesi gerekir; bu yüzden takipçi satırları aranıyor.
      expect(
        r.logTexts.where((String t) => t.contains('takipçi')),
        isEmpty,
      );
      expect(
        r.state.accountFor(SocialPlatform.video)!.followers,
        greaterThan(6000),
        reason: 'Büyüme yine de olmalı, yalnızca yazılmamalı',
      );
    });
  });

  group('D-064 — meslekler', () {
    test('katalog otuzun üstünde iş taşıyor', () {
      expect(kJobCatalog.length, greaterThanOrEqualTo(30));
    });

    test('yazarlık okumanın ikinci basamağıyla açılıyor', () {
      final JobType yazar = jobById('yazar')!;
      expect(yazar.hobbyId, 'okuma');
      expect(yazar.minHobbyStage, 2);
    });

    test('mankenliğin yaş üst sınırı yok', () {
      final JobType manken = jobById('manken')!;
      expect(manken.minAppearance, 70);
      // Yaş üst sınırı diye bir alan yok; olmadığını burada sabitliyoruz.
      expect(manken.minAge, lessThanOrEqualTo(18));
    });
  });

  group('Para işlemleri cüzdanı iki kez etkilemiyor', () {
    test('aktivite ücreti tek seferde düşer', () {
      const ActivityEngine motor = ActivityEngine();
      final GameState s = hayat();
      // Her ücretli eylem her durumda açık değil; gerçekten uygulanan
      // ilkinde ücretin tek seferde düştüğünü doğruluyoruz.
      ActivityAction? denenen;
      GameState? sonra;
      for (final ActivityAction a in kActivityActions) {
        if (a.cost <= 0) continue;
        final ActivityResult r = motor.perform(
          state: s,
          action: a,
          rng: Random(3),
        );
        if (!r.outcome.applied) continue;
        denenen = a;
        sonra = r.state;
        break;
      }
      expect(denenen, isNotNull, reason: 'Hiç ücretli aktivite açılmadı');
      expect(s.player.wallet - sonra!.player.wallet, denenen!.cost);
    });

    test('dövüş dersi ücreti tek seferde düşer', () {
      const MartialArtsEngine motor = MartialArtsEngine();
      const MartialArt art = MartialArt.karate;
      final GameState s = hayat();
      final GameState sonra = motor.takeLesson(state: s, art: art).state;
      expect(s.player.wallet - sonra.player.wallet, art.lessonCost);
    });

    test('toplu çalışma ders sayısı kadar ücret alır, fazlasını değil', () {
      const MartialArtsEngine motor = MartialArtsEngine();
      const MartialArt art = MartialArt.karate;
      final GameState s = hayat();
      final int plan = motor.plannedSeasonLessons(s, art);
      final GameState sonra = motor.takeSeason(state: s, art: art).state;
      expect(s.player.wallet - sonra.player.wallet, plan * art.lessonCost);
    });

    test('tüp bebek ücreti tek seferde düşer', () {
      // Engel varsa hiç para çıkmamalı.
      final GameState s = hayat(wallet: 0);
      final GameState sonra = FertilityTreatment.attempt(s, Random(1)).state;
      expect(sonra.player.wallet, s.player.wallet);
    });
  });

  group('Kayıt ve göç', () {
    test('kayıt sürümü ve okunabilir en eski sürüm tutarlı', () {
      expect(kMinReadableSaveVersion, lessThanOrEqualTo(kSaveFormatVersion));
      expect(
        kSaveFormatVersion - kMinReadableSaveVersion,
        lessThanOrEqualTo(5),
      );
    });

    test('yeni alanlar kaydı bozmuyor: encode-decode-encode aynı', () {
      final GameState s = hayat();
      final Map<String, Object?> bir = encodeGameState(s);
      final GameState geri = decodeGameState(bir);
      final Map<String, Object?> iki = encodeGameState(geri);
      expect(jsonEncode(iki), jsonEncode(bir));
    });

    test('ivfAttempts kapat-aç ile korunuyor', () {
      final GameState s = hayat().copyWith(ivfAttempts: 3);
      final GameState geri = decodeGameState(encodeGameState(s));
      expect(geri.ivfAttempts, 3);
    });

    test('isteğe bağlı alanı olmayan eski kayıt okunabiliyor', () {
      // Bu turda yeni **kayıt alanı** eklenmedi: son paylaşım yaşı
      // mevcut paylaşım geçmişinden türetiliyor, bant ve şehir
      // katsayısı yalnızca katalogda duruyor. Denetlenen şey, isteğe
      // bağlı bir alanı olmayan eski kaydın varsayılanla açılması.
      final Map<String, Object?> json = encodeGameState(hayat());
      json.remove('ivfAttempts');
      final GameState geri = decodeGameState(json);
      expect(geri.ivfAttempts, 0);
      expect(() => encodeGameState(geri), returnsNormally);
    });

    test('zorunlu alan eksikse sessizce bozulmaz, adıyla hata verir', () {
      // Bozuk kaydı sessizce yutmak, oyuncunun hayatını fark
      // edilmeden budamak demek. Kodek alanı adıyla söylemeli.
      final Map<String, Object?> json = encodeGameState(hayat());
      json.remove('socialAccounts');
      expect(
        () => decodeGameState(json),
        throwsA(
          predicate(
            (Object? e) => e.toString().contains('socialAccounts'),
            'alan adını söyleyen bir hata',
          ),
        ),
      );
    });

    test('şehir kaydı kapat-aç ile korunuyor', () {
      final GameState s = hayat().copyWith(
        player: hayat().player.copyWith(currentCity: 'Amasya'),
      );
      final GameState geri = decodeGameState(encodeGameState(s));
      expect(geri.player.currentCity, 'Amasya');
    });
  });
}

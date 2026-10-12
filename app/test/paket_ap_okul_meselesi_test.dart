// Paket AP §5-§7 — çocuğun okul meselesi, oyuncunun kararı ve başarı.
//
// Üç kuralı ürünün kendi API'sinden geçiriyor:
//
// * sorunun **gerçek** bir sebebi olmalı (§5),
// * oyuncunun kararı sonucu belirlemez, ihtimali kaydırır (§1, §6),
// * tek olayla büyük stat sıçraması olmaz (§6).
library;

import 'dart:math';

import 'package:bir_omur/data/save/game_state_codec.dart';
import 'package:bir_omur/domain/family/child_school_issue.dart';
import 'package:bir_omur/domain/generation/life_progression.dart';
import 'package:bir_omur/domain/models/family_issue.dart';
import 'package:bir_omur/domain/models/game_state.dart';
import 'package:bir_omur/domain/models/gender.dart';
import 'package:bir_omur/domain/models/pending_notice.dart';
import 'package:bir_omur/domain/models/person.dart';
import 'package:bir_omur/domain/models/person_development.dart';
import 'package:bir_omur/domain/models/relation.dart';
import 'package:bir_omur/domain/models/stats.dart';
import 'package:bir_omur/domain/models/wealth.dart';
import 'package:flutter_test/flutter_test.dart';

import 'paket_ao_aile_v2_test.dart' show aileliHayat;

/// Okul çağında, istenen özelliklerle bir çocuk ekler.
GameState okulCocuguyla({
  int seed = 4,
  int playerAge = 40,
  int cocukYasi = 11,
  int zeka = 30,
  int mutluluk = 70,
  int bag = 70,
  int cuzdan = 500000,
  bool ogrenci = true,
}) {
  final GameState taban = aileliHayat(seed: seed, age: playerAge);
  return taban.copyWith(
    player: taban.player.copyWith(wallet: cuzdan),
    people: List<Person>.unmodifiable(<Person>[
      ...taban.people,
      Person(
        id: 'cocuk-okul',
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
        motherId: taban.player.id,
        development: PersonDevelopment(
          tracksLife: true,
          grade: ogrenci ? cocukYasi - 5 : null,
          finishedSchool: !ogrenci,
          stats: Stats(
            appearance: 55,
            happiness: mutluluk,
            health: 75,
            intelligence: zeka,
            charisma: 55,
          ),
        ),
      ),
    ]),
  );
}

Person cocuk(GameState s) => s.personById('cocuk-okul')!;

void main() {
  group('§5 — olmayan problem uydurulmaz', () {
    test('sebebi olmayan çocukta sorun açılmaz', () {
      final GameState s = okulCocuguyla(zeka: 75, mutluluk: 80, bag: 80);
      expect(ChildSchoolIssue.reasonsFor(cocuk(s)), isEmpty);
      expect(ChildSchoolIssue.chanceFor(s, cocuk(s)), 0);
      // Bin denemede bile açılmıyor: ihtimal sıfır, zar değil.
      GameState sonra = s;
      for (int i = 0; i < 200; i++) {
        sonra = ChildSchoolIssue.maybeOpen(sonra, Random(i)).state;
      }
      expect(sonra.familyIssues, isEmpty);
    });

    test('dersleri zorlanan çocukta sebep var', () {
      final GameState s = okulCocuguyla(zeka: 30, mutluluk: 80, bag: 80);
      expect(ChildSchoolIssue.reasonsFor(cocuk(s)), contains('dersler'));
      expect(ChildSchoolIssue.chanceFor(s, cocuk(s)), greaterThan(0));
    });

    test('okula gitmeyen çocukta okul sorunu olmaz', () {
      final GameState s = okulCocuguyla(zeka: 20, ogrenci: false);
      expect(ChildSchoolIssue.reasonsFor(cocuk(s)), isEmpty);
    });

    test('yaş aralığı dışında sorun açılmaz', () {
      for (final int yas in <int>[5, 6, 18, 25]) {
        final GameState s = okulCocuguyla(cocukYasi: yas, zeka: 20);
        expect(ChildSchoolIssue.reasonsFor(cocuk(s)), isEmpty,
            reason: '$yas yaşında okul meselesi açılmamalı');
      }
    });

    test('sebep çoğaldıkça ihtimal artar ama tavanı aşmaz', () {
      final GameState tek = okulCocuguyla(zeka: 30, mutluluk: 80, bag: 80);
      final GameState uc = okulCocuguyla(zeka: 30, mutluluk: 20, bag: 10);
      expect(ChildSchoolIssue.reasonsFor(cocuk(uc)), hasLength(3));
      expect(ChildSchoolIssue.chanceFor(uc, cocuk(uc)),
          greaterThan(ChildSchoolIssue.chanceFor(tek, cocuk(tek))));
      expect(ChildSchoolIssue.chanceFor(uc, cocuk(uc)),
          lessThanOrEqualTo(ChildSchoolIssue.prototypeOnlyMaxChance));
    });
  });

  group('§6 — karar oyuncunun, sonuç değil', () {
    GameState sorunuAc(GameState s) {
      for (int i = 0; i < 400; i++) {
        final GameState sonra = ChildSchoolIssue.maybeOpen(s, Random(i)).state;
        if (sonra.familyIssues.isNotEmpty) return sonra;
      }
      fail('Sebebi olan çocukta 400 denemede sorun hiç açılmadı.');
    }

    test('sorun açılınca oyuncuya sorulacak bir karar oluşur', () {
      final GameState s = sorunuAc(okulCocuguyla(zeka: 25, mutluluk: 25));
      expect(ChildSchoolIssue.isPending(s), isTrue);
      final FamilyIssue m = ChildSchoolIssue.pendingIssue(s)!;
      expect(m.kind, FamilyIssueKind.cocukOkul);
      expect(m.personId, 'cocuk-okul', reason: '§53: gerçek kişi kimliği.');
      expect(m.response, isNull);
    });

    test('özel ders parası gerçekten cüzdandan çıkar', () {
      final GameState s = sorunuAc(okulCocuguyla(zeka: 25, cuzdan: 500000));
      final int once = s.player.wallet;
      final GameState sonra = ChildSchoolIssue.choose(
        s,
        FamilyIssueResponse.paraVerdi,
        Random(1),
      ).state;
      expect(sonra.player.wallet,
          once - ChildSchoolIssue.prototypeOnlyTutorCost);
    });

    test('para yetmezse seçenek sessizce kaybolmaz, gerekçesi yazılır', () {
      final GameState s = sorunuAc(okulCocuguyla(zeka: 25, cuzdan: 1000));
      final String? engel =
          ChildSchoolIssue.blockReason(s, FamilyIssueResponse.paraVerdi);
      expect(engel, isNotNull);
      expect(engel, contains('cüzdanında yok'));
      // Ve karar uygulanmıyor: para eksiye düşmüyor.
      final GameState sonra = ChildSchoolIssue.choose(
        s,
        FamilyIssueResponse.paraVerdi,
        Random(1),
      ).state;
      expect(sonra.player.wallet, s.player.wallet);
      expect(ChildSchoolIssue.pendingIssue(sonra), isNotNull,
          reason: 'Karar verilmediği için mesele hâlâ bekliyor.');
    });

    test('karar verildiği yıl sonuç açıklanmaz', () {
      final GameState s = sorunuAc(okulCocuguyla(zeka: 25));
      final GameState karar = ChildSchoolIssue.choose(
        s,
        FamilyIssueResponse.destekOldu,
        Random(3),
      ).state;
      final FamilyIssue m = karar.familyIssues.first;
      expect(m.isOpen, isTrue, reason: '§1: seçtim-oldu hissi olmamalı.');
      // Aynı yıl ilerletilse bile sonuç çıkmaz.
      final GameState ayniYil = ChildSchoolIssue.advanceYear(
        karar,
        karar.player.age,
        Random(3),
      ).state;
      expect(ayniYil.familyIssues.first.isOpen, isTrue);
    });

    test('hiçbir seçenek sonucu garanti etmiyor (§1)', () {
      for (final FamilyIssueResponse cevap in FamilyIssueResponse.values) {
        final double p = ChildSchoolIssue.recoveryChance(cevap);
        expect(p, greaterThan(0.0),
            reason: '${cevap.name}: hiç toparlanmama garantisi olmamalı');
        expect(p, lessThan(1.0),
            reason: '${cevap.name}: garanti başarı olmamalı');
      }
      // En iyi seçenek, karışmamaktan daha iyi olmalı — yoksa karar
      // anlamsız olurdu.
      expect(
        ChildSchoolIssue.recoveryChance(FamilyIssueResponse.paraVerdi),
        greaterThan(
          ChildSchoolIssue.recoveryChance(FamilyIssueResponse.karismadi),
        ),
      );
    });

    test('tek olayla büyük stat sıçraması olmaz (§6)', () {
      GameState s = sorunuAc(okulCocuguyla(zeka: 25, mutluluk: 25));
      final int zekaOnce = cocuk(s).development!.stats.intelligence;
      final int mutlulukOnce = cocuk(s).development!.stats.happiness;
      s = ChildSchoolIssue.choose(s, FamilyIssueResponse.paraVerdi, Random(5))
          .state;
      // Mesele kapanana kadar ilerlet.
      int yas = s.player.age;
      for (int i = 0; i < 8 && s.openFamilyIssues.isNotEmpty; i++) {
        yas++;
        s = s.copyWith(player: s.player.copyWith(age: yas));
        s = ChildSchoolIssue.advanceYear(s, yas, Random(5 + i)).state;
      }
      final int zekaFark =
          cocuk(s).development!.stats.intelligence - zekaOnce;
      final int mutlulukFark =
          cocuk(s).development!.stats.happiness - mutlulukOnce;
      expect(zekaFark.abs(),
          lessThanOrEqualTo(ChildSchoolIssue.prototypeOnlyMaxStatStep),
          reason: 'Bütün mesele boyunca zekâ sıçraması küçük kalmalı.');
      expect(mutlulukFark.abs(),
          lessThanOrEqualTo(ChildSchoolIssue.prototypeOnlyMaxStatStep));
    });

    test('mesele sonsuza kadar sürmez', () {
      GameState s = sorunuAc(okulCocuguyla(zeka: 25));
      s = ChildSchoolIssue.choose(s, FamilyIssueResponse.karismadi, Random(9))
          .state;
      int yas = s.player.age;
      for (int i = 0; i < 12; i++) {
        yas++;
        s = s.copyWith(player: s.player.copyWith(age: yas));
        s = ChildSchoolIssue.advanceYear(s, yas, Random(1000 + i)).state;
      }
      expect(s.openFamilyIssues, isEmpty,
          reason: 'En fazla ${ChildSchoolIssue.prototypeOnlyMaxYears} yıl.');
      expect(s.familyIssues, hasLength(1), reason: 'Kayıt silinmez.');
    });

    test('çocuk vefat ederse mesele kapanır, hayalet mesele kalmaz', () {
      GameState s = sorunuAc(okulCocuguyla(zeka: 25));
      s = ChildSchoolIssue.choose(s, FamilyIssueResponse.destekOldu, Random(2))
          .state;
      s = s.copyWith(
        player: s.player.copyWith(age: s.player.age + 1),
        people: List<Person>.unmodifiable(<Person>[
          for (final Person p in s.people)
            if (p.id == 'cocuk-okul') p.copyWith(isAlive: false) else p,
        ]),
      );
      s = ChildSchoolIssue.advanceYear(s, s.player.age, Random(2)).state;
      expect(s.openFamilyIssues, isEmpty);
      expect(s.familyIssues.first.status, FamilyIssueStatus.kapandi);
    });

    test('kayıt turu: mesele ve cevap kaybolmuyor', () {
      GameState s = sorunuAc(okulCocuguyla(zeka: 25));
      s = ChildSchoolIssue.choose(s, FamilyIssueResponse.konustu, Random(7))
          .state;
      final GameState donen = decodeGameState(encodeGameState(s));
      expect(donen.familyIssues, hasLength(1));
      expect(donen.familyIssues.first.response, FamilyIssueResponse.konustu);
      expect(donen.familyIssues.first.personId, 'cocuk-okul');
    });

    test('soğuma süresi: aynı çocukta hemen yeni mesele açılmaz (§46)', () {
      GameState s = sorunuAc(okulCocuguyla(zeka: 25));
      final int acilis = s.player.age;
      s = ChildSchoolIssue.choose(s, FamilyIssueResponse.karismadi, Random(4))
          .state;
      // Meseleyi kapat.
      s = s.copyWith(player: s.player.copyWith(age: acilis + 1));
      s = s.updateFamilyIssue(
        s.familyIssues.first.id,
        status: FamilyIssueStatus.kapandi,
        resolvedAtAge: acilis + 1,
      );
      expect(ChildSchoolIssue.offCooldown(s, cocuk(s)), isFalse);

      final GameState cokSonra = s.copyWith(
        player: s.player.copyWith(
          age: acilis + 1 + ChildSchoolIssue.prototypeOnlyCooldown,
        ),
      );
      expect(ChildSchoolIssue.offCooldown(cokSonra, cocuk(cokSonra)), isTrue);
    });
  });

  group('üretim yolu — motor gerçekten çalışıyor', () {
    // Paket AO'da üç motorun hiçbir ekrandan ulaşılamadığı görülmüştü.
    // Bu grup meseleyi **gerçek** yıllık ilerlemeden geçiriyor; tek tek
    // fonksiyon çağırmıyor.
    test('okul meselesi advanceOneYear içinden açılıyor', () {
      bool acildi = false;
      for (int tohum = 0; tohum < 40 && !acildi; tohum++) {
        GameState s = okulCocuguyla(
          seed: tohum,
          playerAge: 38,
          cocukYasi: 9,
          zeka: 25,
          mutluluk: 25,
          bag: 15,
        );
        final LifeProgression motor = LifeProgression(Random(tohum + 1));
        for (int i = 0; i < 8 && !s.deceased && !acildi; i++) {
          s = s.copyWith(pendingEvent: null, pendingCrisis: null);
          s = motor.advanceOneYear(s);
          if (s.familyIssues
              .any((FamilyIssue m) => m.kind == FamilyIssueKind.cocukOkul)) {
            acildi = true;
          }
        }
      }
      expect(acildi, isTrue,
          reason: 'Motor yıllık ilerlemeye bağlı değil; ekrandan '
              'ulaşılamayan bir sistem olurdu.');
    });

    test('§3: üretim yolunda da yılda bir büyük aile kararı', () {
      for (int tohum = 0; tohum < 25; tohum++) {
        GameState s = okulCocuguyla(
          seed: tohum,
          playerAge: 40,
          cocukYasi: 9,
          zeka: 25,
          mutluluk: 25,
          bag: 15,
        );
        // İkinci ve üçüncü bir sorunlu çocuk daha: aynı yıl üç kriz
        // çıkarsa §3 kırılmış olur.
        s = s.copyWith(
          people: List<Person>.unmodifiable(<Person>[
            ...s.people,
            for (int k = 0; k < 2; k++)
              Person(
                id: 'cocuk-okul-$k',
                firstName: k == 0 ? 'Ege' : 'Ada',
                lastName: s.player.lastName,
                gender: Gender.erkek,
                relation: RelationType.cocuk,
                age: 10 + k,
                isAlive: true,
                inPlayerHousehold: true,
                employment: EmploymentStatus.ogrenci,
                wealth: null,
                bond: 15,
                motherId: s.player.id,
                development: PersonDevelopment(
                  tracksLife: true,
                  grade: 5 + k,
                  stats: const Stats(
                    appearance: 55,
                    happiness: 25,
                    health: 75,
                    intelligence: 25,
                    charisma: 55,
                  ),
                ),
              ),
          ]),
        );
        final LifeProgression motor = LifeProgression(Random(tohum + 5));
        for (int i = 0; i < 10 && !s.deceased; i++) {
          final int yasOnce = s.player.age;
          s = s.copyWith(pendingEvent: null, pendingCrisis: null);
          s = motor.advanceOneYear(s);
          if (s.player.age == yasOnce) continue;
          final int oYilAcilan = s.familyIssues
              .where((FamilyIssue m) => m.openedAtAge == s.player.age)
              .length;
          expect(oYilAcilan, lessThanOrEqualTo(1),
              reason: 'tohum $tohum yaş ${s.player.age}: aynı yıl '
                  '$oYilAcilan aile meselesi açıldı');
        }
      }
    });
  });

  group('§7 — başarı da gerçek olmalı', () {
    test('zekâsı düşük çocukta derece çıkmaz', () {
      final GameState s = okulCocuguyla(zeka: 30);
      GameState sonra = s;
      for (int i = 0; i < 200; i++) {
        sonra = ChildSchoolIssue.maybeAchievement(
          sonra,
          sonra.player.age,
          Random(i),
        ).state;
      }
      expect(
        sonra.log.where((dynamic e) => (e.text as String).contains('derece')),
        isEmpty,
      );
    });

    test('iyi öğrencide derece çıkıyor ve bildirime dönüşüyor', () {
      final GameState s = okulCocuguyla(zeka: 85, mutluluk: 80, bag: 70);
      for (int i = 0; i < 400; i++) {
        final ({GameState state, PendingNotice? notice, String? logText}) r =
            ChildSchoolIssue.maybeAchievement(s, s.player.age, Random(i));
        if (r.notice != null) {
          expect(r.notice!.personId, 'cocuk-okul');
          expect(r.logText, contains('derece'));
          // Bağ ve mutluluk küçük artar.
          final Person c = r.state.personById('cocuk-okul')!;
          expect(c.bond, greaterThan(s.personById('cocuk-okul')!.bond));
          expect(
            c.development!.stats.happiness -
                s.personById('cocuk-okul')!.development!.stats.happiness,
            lessThanOrEqualTo(ChildSchoolIssue.prototypeOnlyMaxStatStep),
          );
          return;
        }
      }
      fail('İyi öğrencide 400 denemede hiç başarı çıkmadı.');
    });

    test('açık okul meselesi varken başarı bildirimi çıkmaz', () {
      GameState s = okulCocuguyla(zeka: 85, mutluluk: 80);
      s = s.openFamilyIssue(
        kind: FamilyIssueKind.cocukOkul,
        personId: 'cocuk-okul',
      );
      for (int i = 0; i < 200; i++) {
        final ({GameState state, PendingNotice? notice, String? logText}) r =
            ChildSchoolIssue.maybeAchievement(s, s.player.age, Random(i));
        expect(r.notice, isNull,
            reason: '"Dersleri kötü" ile "derece yaptı" çelişir.');
      }
    });

    test('aynı başarı tekrar tekrar basılmaz (§46)', () {
      final GameState s = okulCocuguyla(zeka: 85, mutluluk: 80);
      GameState bulunan = s;
      bool cikti = false;
      for (int i = 0; i < 400 && !cikti; i++) {
        final ({GameState state, PendingNotice? notice, String? logText}) r =
            ChildSchoolIssue.maybeAchievement(s, s.player.age, Random(i));
        if (r.notice != null) {
          bulunan = r.state;
          cikti = true;
        }
      }
      expect(cikti, isTrue);
      // Hemen ardından 200 deneme: soğuma yüzünden ikinci başarı yok.
      for (int i = 0; i < 200; i++) {
        final ({GameState state, PendingNotice? notice, String? logText}) r =
            ChildSchoolIssue.maybeAchievement(
          bulunan,
          bulunan.player.age,
          Random(i),
        );
        expect(r.notice, isNull);
      }
    });
  });
}

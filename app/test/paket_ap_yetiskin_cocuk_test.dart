// Paket AP §8-§13 — yetişkin çocuğun para sıkıntısı, eve dönüşü ve
// şehir değiştirmesi.
//
// En sıkı iddia para korunumu: verilen para cüzdandan düşüp çocuğun
// kaydına eklenir, toplam değişmez (§9).
library;

import 'dart:math';

import 'package:bir_omur/data/save/game_state_codec.dart';
import 'package:bir_omur/domain/economy/living_costs.dart';
import 'package:bir_omur/domain/family/adult_child_support.dart';
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

const Stats _ortaStats = Stats(
  appearance: 55,
  happiness: 60,
  health: 75,
  intelligence: 60,
  charisma: 55,
);

GameState yetiskinCocukla({
  int seed = 11,
  int playerAge = 55,
  int cocukYasi = 27,
  int cocukBirikimi = 5000,
  bool isiVar = false,
  bool hanede = false,
  int cuzdan = 2000000,
  String? sehir,
  int bag = 65,
}) {
  final GameState taban = aileliHayat(seed: seed, age: playerAge);
  return taban.copyWith(
    player: taban.player.copyWith(wallet: cuzdan),
    people: List<Person>.unmodifiable(<Person>[
      ...taban.people,
      Person(
        id: 'cocuk-yetiskin',
        firstName: 'Deniz',
        lastName: taban.player.lastName,
        gender: Gender.kadin,
        relation: RelationType.cocuk,
        age: cocukYasi,
        isAlive: true,
        inPlayerHousehold: hanede,
        employment:
            isiVar ? EmploymentStatus.calisiyor : EmploymentStatus.issiz,
        occupation: isiVar ? 'öğretmen' : null,
        wealth: WealthTier.yoksul,
        bond: bag,
        city: sehir ?? taban.player.currentCity,
        motherId: taban.player.id,
        development: PersonDevelopment(
          tracksLife: true,
          finishedSchool: true,
          money: cocukBirikimi,
          jobId: isiVar ? 'ogretmen' : null,
          stats: _ortaStats,
        ),
      ),
    ]),
  );
}

Person c(GameState s) => s.personById('cocuk-yetiskin')!;

/// Para isteği açılana kadar dener.
GameState istekAc(GameState s) {
  for (int i = 0; i < 600; i++) {
    final GameState sonra =
        AdultChildSupport.maybeRequest(s, s.player.age, Random(i)).state;
    if (sonra.familyIssues.isNotEmpty) return sonra;
  }
  fail('Sıkıntıdaki çocukta 600 denemede hiç para isteği çıkmadı.');
}

void main() {
  group('§8 — sıkıntı gerçek mi?', () {
    test('işi olan çocuk para istemez', () {
      final GameState s = yetiskinCocukla(isiVar: true, cocukBirikimi: 1000);
      expect(AdultChildSupport.inTrouble(c(s)), isFalse);
      expect(AdultChildSupport.requestChanceFor(s, c(s)), 0);
    });

    test('birikimi olan çocuk para istemez', () {
      final GameState s = yetiskinCocukla(cocukBirikimi: 900000);
      expect(AdultChildSupport.inTrouble(c(s)), isFalse);
    });

    test('işsiz ve parasız çocukta sıkıntı var', () {
      final GameState s = yetiskinCocukla();
      expect(AdultChildSupport.inTrouble(c(s)), isTrue);
      expect(AdultChildSupport.requestChanceFor(s, c(s)), greaterThan(0));
    });

    test('küçük çocuk bu sistemin konusu değil', () {
      final GameState s = yetiskinCocukla(cocukYasi: 15);
      expect(AdultChildSupport.inTrouble(c(s)), isFalse);
    });

    test('istenen tutar açıktan türetiliyor, rastgele değil', () {
      final GameState az = yetiskinCocukla(cocukBirikimi: 35000);
      final GameState hic = yetiskinCocukla(cocukBirikimi: 0);
      expect(AdultChildSupport.askedAmount(c(hic)),
          greaterThanOrEqualTo(AdultChildSupport.askedAmount(c(az))));
      expect(AdultChildSupport.askedAmount(c(hic)),
          lessThanOrEqualTo(AdultChildSupport.prototypeOnlyAskMax));
      // Aynı durumda aynı tutar: zar yok.
      expect(AdultChildSupport.askedAmount(c(hic)),
          AdultChildSupport.askedAmount(c(yetiskinCocukla(cocukBirikimi: 0))));
    });

    test('soğuma: aynı çocuk her yıl para istemez (§10)', () {
      final GameState s = istekAc(yetiskinCocukla());
      expect(AdultChildSupport.offCooldown(s, c(s), s.player.age), isFalse);
      final GameState sonra = s.copyWith(
        player: s.player.copyWith(
          age: s.player.age + AdultChildSupport.prototypeOnlyRequestCooldown,
        ),
      );
      expect(
        AdultChildSupport.offCooldown(sonra, c(sonra), sonra.player.age),
        isTrue,
      );
    });
  });

  group('§9 — para yoktan üretilmiyor', () {
    test('verilen para cüzdandan düşüyor ve çocuğun kaydına ekleniyor', () {
      final GameState s = istekAc(yetiskinCocukla());
      final int cuzdanOnce = s.player.wallet;
      final int cocukOnce = c(s).development!.money;
      final int tutar =
          AdultChildSupport.amountFor(s, FamilyIssueResponse.paraVerdi);
      expect(tutar, greaterThan(0));

      final GameState sonra =
          AdultChildSupport.respond(s, FamilyIssueResponse.paraVerdi).state;
      expect(sonra.player.wallet, cuzdanOnce - tutar);
      expect(c(sonra).development!.money, cocukOnce + tutar);
      // Toplam korundu.
      expect(sonra.player.wallet + c(sonra).development!.money,
          cuzdanOnce + cocukOnce);
    });

    test('yarısını vermek de gerçek para hareketi', () {
      final GameState s = istekAc(yetiskinCocukla());
      final int tam =
          AdultChildSupport.amountFor(s, FamilyIssueResponse.paraVerdi);
      final int yarim =
          AdultChildSupport.amountFor(s, FamilyIssueResponse.destekOldu);
      expect(yarim, lessThan(tam));
      expect(yarim, greaterThan(0));
      final GameState sonra =
          AdultChildSupport.respond(s, FamilyIssueResponse.destekOldu).state;
      expect(sonra.player.wallet, s.player.wallet - yarim);
      expect(c(sonra).development!.money,
          c(s).development!.money + yarim);
    });

    test('reddetmek hiçbir yere para üretmiyor', () {
      final GameState s = istekAc(yetiskinCocukla());
      final GameState sonra =
          AdultChildSupport.respond(s, FamilyIssueResponse.reddetti).state;
      expect(sonra.player.wallet, s.player.wallet);
      expect(c(sonra).development!.money, c(s).development!.money);
      // Ama bağ düşüyor: tutumun bir karşılığı var.
      expect(c(sonra).bond, lessThan(c(s).bond));
    });

    test('para yetmezse gerekçe yazılıyor, cüzdan eksiye düşmüyor', () {
      final GameState s = istekAc(yetiskinCocukla(cuzdan: 1000));
      final String? engel =
          AdultChildSupport.blockReason(s, FamilyIssueResponse.paraVerdi);
      expect(engel, isNotNull);
      expect(engel, contains('cüzdanında o kadar yok'));
      final GameState sonra =
          AdultChildSupport.respond(s, FamilyIssueResponse.paraVerdi).state;
      expect(sonra.player.wallet, s.player.wallet);
      expect(AdultChildSupport.isPending(sonra), isTrue);
    });

    test('para verilince mesele kapanıyor, kaydı kalıyor', () {
      final GameState s = istekAc(yetiskinCocukla());
      final GameState sonra =
          AdultChildSupport.respond(s, FamilyIssueResponse.paraVerdi).state;
      expect(sonra.openFamilyIssues, isEmpty);
      expect(sonra.familyIssues, hasLength(1));
      expect(sonra.familyIssues.first.status, FamilyIssueStatus.cozuldu);
      expect(sonra.familyIssues.first.response,
          FamilyIssueResponse.paraVerdi);
    });

    test('kayıt turu: istek ve cevap kayboluyor mu', () {
      final GameState s = AdultChildSupport.respond(
        istekAc(yetiskinCocukla()),
        FamilyIssueResponse.destekOldu,
      ).state;
      final GameState donen = decodeGameState(encodeGameState(s));
      expect(donen.familyIssues, hasLength(1));
      expect(donen.familyIssues.first.response,
          FamilyIssueResponse.destekOldu);
      expect(donen.personById('cocuk-yetiskin')!.development!.money,
          c(s).development!.money);
    });
  });

  group('§11-§12 — eve dönüş gerçek bir hane kararı', () {
    GameState donmekIsteyen() {
      GameState s = istekAc(yetiskinCocukla());
      s = AdultChildSupport.respond(s, FamilyIssueResponse.reddetti).state;
      // Yıllar geçiyor, sıkıntı sürüyor.
      s = s.copyWith(
        player: s.player.copyWith(
          age: s.player.age + AdultChildSupport.prototypeOnlyMoveBackAfterYears,
        ),
      );
      return s;
    }

    test('sıkıntı sürdüyse eve dönme isteği oluşuyor', () {
      final GameState s = donmekIsteyen();
      expect(AdultChildSupport.pendingMoveBack(s), isNotNull);
    });

    test('kabul edilince çocuk GERÇEKTEN haneye giriyor ve gider artıyor',
        () {
      final GameState s = donmekIsteyen();
      final int giderOnce = LivingCosts.yearlyCost(s);
      final GameState sonra =
          AdultChildSupport.answerMoveBack(s, true).state;
      expect(c(sonra).inPlayerHousehold, isTrue);
      expect(c(sonra).city, sonra.player.currentCity);
      expect(LivingCosts.adultChildrenAtHome(sonra), hasLength(1));
      expect(LivingCosts.yearlyCost(sonra), greaterThan(giderOnce),
          reason: '§12: bedava dekoratif hane değişimi olmamalı.');
    });

    test('reddedilince hane değişmiyor, bağ düşüyor', () {
      final GameState s = donmekIsteyen();
      final GameState sonra =
          AdultChildSupport.answerMoveBack(s, false).state;
      expect(c(sonra).inPlayerHousehold, isFalse);
      expect(c(sonra).bond, lessThan(c(s).bond));
      expect(LivingCosts.adultChildrenAtHome(sonra), isEmpty);
    });

    test('§12: eve dönüş yıllık kuralla hemen geri alınmıyor', () {
      // Bu test gerçek bir çatışmayı koruyor: `_childrenLeaveHome`
      // 25 yaşını geçmiş HER çocuğu her yıl haneden çıkarıyor. Dönüş
      // kaydedilmezse oyuncunun "gelsin" kararı bir yıl sonra
      // kendiliğinden geri alınıyor ve hane değişimi dekoratif kalıyor.
      GameState s = donmekIsteyen();
      s = AdultChildSupport.answerMoveBack(s, true).state;
      expect(c(s).inPlayerHousehold, isTrue);
      expect(AdultChildSupport.recentlyReturned(s, c(s)), isTrue);

      // Üretim yolundan üç yıl: çocuk hâlâ hanede.
      final LifeProgression motor = LifeProgression(Random(5));
      for (int i = 0; i < 3 && !s.deceased; i++) {
        s = s.copyWith(pendingEvent: null, pendingCrisis: null);
        s = motor.advanceOneYear(s);
        final Person? cocuk = s.personById('cocuk-yetiskin');
        if (cocuk == null || !cocuk.isAlive) return;
        // İş bulup kendi isteğiyle çıkmadıysa hanede kalmalı.
        if (cocuk.development?.isEmployed ?? false) return;
        expect(cocuk.inPlayerHousehold, isTrue,
            reason: '${i + 1}. yıl: eve dönüş geri alınmış.');
      }
    });

    test('pencere dolunca normal kural yeniden işliyor', () {
      GameState s = donmekIsteyen();
      s = AdultChildSupport.answerMoveBack(s, true).state;
      final GameState cokSonra = s.copyWith(
        player: s.player.copyWith(
          age: s.player.age + AdultChildSupport.prototypeOnlyStayYears,
        ),
      );
      expect(AdultChildSupport.recentlyReturned(cokSonra, c(cokSonra)),
          isFalse);
    });

    test('çalışan yetişkin çocuk evde olsa da gider kalemi doğurmuyor', () {
      final GameState s =
          yetiskinCocukla(hanede: true, isiVar: true, cocukBirikimi: 300000);
      expect(LivingCosts.adultChildrenAtHome(s), isEmpty,
          reason: 'Kendi kazancıyla katkı verdiği varsayılıyor.');
    });

    test('iş bulan çocuk evden yeniden çıkabiliyor', () {
      final GameState s = yetiskinCocukla(
        hanede: true,
        isiVar: true,
        cocukBirikimi: 150000,
      );
      bool cikti = false;
      for (int i = 0; i < 200 && !cikti; i++) {
        final GameState sonra =
            AdultChildSupport.advanceYear(s, s.player.age, Random(i)).state;
        if (!sonra.personById('cocuk-yetiskin')!.inPlayerHousehold) {
          cikti = true;
        }
      }
      expect(cikti, isTrue);
    });
  });

  group('§13 — şehir değişimi gerçek', () {
    test('çalışan ve birikimi olan çocuk başka şehre taşınabiliyor', () {
      final GameState s = yetiskinCocukla(
        isiVar: true,
        cocukBirikimi: AdultChildSupport.prototypeOnlyRelocateMoney + 50000,
      );
      final String ilkSehir = c(s).city!;
      for (int i = 0; i < 800; i++) {
        final ({GameState state, List<String> logTexts}) r =
            AdultChildSupport.advanceYear(s, s.player.age, Random(i));
        final Person sonra = r.state.personById('cocuk-yetiskin')!;
        if (sonra.city != ilkSehir) {
          expect(r.logTexts, isNotEmpty);
          // Taşınmanın bedeli çocuğun kendi birikiminden çıkıyor.
          expect(sonra.development!.money,
              c(s).development!.money -
                  AdultChildSupport.prototypeOnlyRelocateCost);
          // Oyuncunun cüzdanı kendiliğinden eksilmiyor.
          expect(r.state.player.wallet, s.player.wallet);
          return;
        }
      }
      fail('800 denemede hiç şehir değişimi olmadı.');
    });

    test('parasız çocuk kendiliğinden şehir değiştirmiyor', () {
      final GameState s = yetiskinCocukla(isiVar: true, cocukBirikimi: 1000);
      final String ilkSehir = c(s).city!;
      for (int i = 0; i < 300; i++) {
        final GameState sonra =
            AdultChildSupport.advanceYear(s, s.player.age, Random(i)).state;
        expect(sonra.personById('cocuk-yetiskin')!.city, ilkSehir);
      }
    });
  });

  group('üretim yolu', () {
    test('para isteği advanceOneYear içinden çıkıyor', () {
      bool acildi = false;
      for (int tohum = 0; tohum < 40 && !acildi; tohum++) {
        GameState s = yetiskinCocukla(seed: tohum, playerAge: 52);
        final LifeProgression motor = LifeProgression(Random(tohum + 3));
        for (int i = 0; i < 8 && !s.deceased && !acildi; i++) {
          s = s.copyWith(pendingEvent: null, pendingCrisis: null);
          s = motor.advanceOneYear(s);
          if (s.familyIssues
              .any((FamilyIssue m) => m.kind == FamilyIssueKind.cocukPara)) {
            acildi = true;
          }
        }
      }
      expect(acildi, isTrue,
          reason: 'Motor yıllık ilerlemeye bağlı değil.');
    });

    test('bildirim gerçek kişiyi gösteriyor (§53)', () {
      final GameState s = yetiskinCocukla();
      for (int i = 0; i < 600; i++) {
        final ({GameState state, PendingNotice? notice}) r =
            AdultChildSupport.maybeRequest(s, s.player.age, Random(i));
        if (r.notice == null) continue;
        expect(r.notice!.personId, 'cocuk-yetiskin');
        return;
      }
      fail('600 denemede bildirim çıkmadı.');
    });
  });
}

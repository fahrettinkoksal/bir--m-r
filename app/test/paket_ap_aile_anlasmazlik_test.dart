// Paket AP §28-§39 — kardeşle para, yaşlı bakımı, miras anlaşmazlığı,
// küslük/barışma ve eski eşle ortak ebeveynlik.
//
// En sıkı iki iddia:
//   * para hiçbir yerde doğmuyor, yalnızca el değiştiriyor (§29, §36),
//   * "kan bağı = bedava ATM" değil: kardeş her zaman evet demiyor (§29).
library;

import 'dart:math';

import 'package:bir_omur/domain/family/family_disputes.dart';
import 'package:bir_omur/domain/interaction/friendship_depth.dart';
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
  health: 70,
  intelligence: 60,
  charisma: 55,
);

GameState kardesliHayat({
  int seed = 31,
  int playerAge = 50,
  int kardesYasi = 48,
  int kardesBirikimi = 10000,
  bool kardesCalisiyor = false,
  int bag = 65,
  int cuzdan = 1500000,
  int ebeveynYasi = 60,
}) {
  final GameState taban = aileliHayat(seed: seed, age: playerAge);
  // Var olan anne/babanın yaşını ayarla (bakım meselesi için).
  final List<Person> kisiler = <Person>[
    for (final Person p in taban.people)
      if (p.relation == RelationType.anne || p.relation == RelationType.baba)
        p.copyWith(age: ebeveynYasi)
      else
        p,
    Person(
      id: 'kardes-ap',
      firstName: 'Kerem',
      lastName: taban.player.lastName,
      gender: Gender.erkek,
      relation: RelationType.kardes,
      age: kardesYasi,
      isAlive: true,
      inPlayerHousehold: false,
      employment: kardesCalisiyor
          ? EmploymentStatus.calisiyor
          : EmploymentStatus.issiz,
      occupation: kardesCalisiyor ? 'teknisyen' : null,
      wealth: WealthTier.ortaHalli,
      bond: bag,
      city: taban.player.currentCity,
      development: PersonDevelopment(
        tracksLife: true,
        finishedSchool: true,
        money: kardesBirikimi,
        jobId: kardesCalisiyor ? 'teknisyen' : null,
        stats: _ortaStats,
      ),
    ),
  ];
  return taban.copyWith(
    player: taban.player.copyWith(wallet: cuzdan),
    people: List<Person>.unmodifiable(kisiler),
  );
}

Person k(GameState s) => s.personById('kardes-ap')!;

GameState kardesIstegiAc(GameState s) {
  for (int i = 0; i < 1500; i++) {
    final GameState sonra =
        FamilyDisputes.maybeSiblingAsk(s, s.player.age, Random(i)).state;
    if (FamilyDisputes.pendingSiblingAsk(sonra) != null) return sonra;
  }
  fail('1500 denemede kardeş para isteği çıkmadı.');
}

void main() {
  group('§28-§29 — kardeşle para', () {
    test('işi olan kardeş para istemez', () {
      final GameState s =
          kardesliHayat(kardesCalisiyor: true, kardesBirikimi: 1000);
      expect(FamilyDisputes.siblingInTrouble(k(s)), isFalse);
      for (int i = 0; i < 200; i++) {
        final GameState sonra =
            FamilyDisputes.maybeSiblingAsk(s, s.player.age, Random(i)).state;
        expect(FamilyDisputes.pendingSiblingAsk(sonra), isNull);
      }
    });

    test('verilen para cüzdandan düşüp kardeşin kaydına geçiyor (§36)', () {
      final GameState s = kardesIstegiAc(kardesliHayat());
      final int cuzdan = s.player.wallet;
      final int kardesPara = k(s).development!.money;
      final GameState sonra = FamilyDisputes.respondSiblingAsk(
        s,
        FamilyIssueResponse.paraVerdi,
      ).state;
      expect(sonra.player.wallet,
          cuzdan - FamilyDisputes.prototypeOnlySiblingAsk);
      expect(k(sonra).development!.money,
          kardesPara + FamilyDisputes.prototypeOnlySiblingAsk);
      expect(sonra.player.wallet + k(sonra).development!.money,
          cuzdan + kardesPara,
          reason: 'Toplam değişmemeli: para yoktan üretilmez.');
    });

    test('reddetmek para üretmiyor ama bağ düşürüyor', () {
      final GameState s = kardesIstegiAc(kardesliHayat());
      final GameState sonra = FamilyDisputes.respondSiblingAsk(
        s,
        FamilyIssueResponse.reddetti,
      ).state;
      expect(sonra.player.wallet, s.player.wallet);
      expect(k(sonra).development!.money, k(s).development!.money);
      expect(k(sonra).bond, lessThan(k(s).bond));
      // Küslük otomatik yazılmıyor (§33): o mekanizma ayrı.
      expect(k(sonra).isEstranged, isFalse);
    });

    test('para yetmezse gerekçe yazılıyor', () {
      final GameState s = kardesIstegiAc(kardesliHayat(cuzdan: 1000));
      final String? engel = FamilyDisputes.siblingAskBlockReason(
        s,
        FamilyIssueResponse.paraVerdi,
      );
      expect(engel, isNotNull);
      final GameState sonra = FamilyDisputes.respondSiblingAsk(
        s,
        FamilyIssueResponse.paraVerdi,
      ).state;
      expect(sonra.player.wallet, s.player.wallet);
    });
  });

  group('§29 — "kan bağı = bedava ATM" değil', () {
    test('kardeşin verebileceği para KENDİ kaydındaki paradan', () {
      final GameState zengin = kardesliHayat(kardesBirikimi: 1000000);
      final GameState yoksul = kardesliHayat(kardesBirikimi: 1000);
      expect(FamilyDisputes.siblingLendCapacity(k(zengin)),
          greaterThan(FamilyDisputes.siblingLendCapacity(k(yoksul))));
      // Hepsini vermiyor.
      expect(FamilyDisputes.siblingLendCapacity(k(zengin)),
          lessThan(k(zengin).development!.money));
      // Ve bir üst sınır var: uydurma milyonluk hesap açılmıyor.
      expect(FamilyDisputes.siblingLendCapacity(k(zengin)),
          lessThanOrEqualTo(FamilyDisputes.prototypeOnlyBorrowMax));
    });

    test('kaydı olmayan kardeş para veremez', () {
      final GameState s = kardesliHayat();
      final Person kayitsiz = Person(
        id: 'kardes-kayitsiz',
        firstName: 'Ali',
        lastName: 'Kaya',
        gender: Gender.erkek,
        relation: RelationType.kardes,
        age: 45,
        isAlive: true,
        inPlayerHousehold: false,
        employment: EmploymentStatus.calisiyor,
        occupation: 'teknisyen',
        wealth: WealthTier.cokVarlikli,
        bond: 90,
      );
      expect(FamilyDisputes.siblingLendCapacity(kayitsiz), 0,
          reason: 'Uydurma milyonluk hesap açılmaz.');
      final GameState ile = s.copyWith(
        people: List<Person>.unmodifiable(<Person>[...s.people, kayitsiz]),
      );
      final ({GameState state, String text, bool accepted}) r =
          FamilyDisputes.borrowFromSibling(ile, 'kardes-kayitsiz', Random(1));
      expect(r.accepted, isFalse);
      expect(r.state.player.wallet, ile.player.wallet);
    });

    test('kardeş HER ZAMAN evet demiyor', () {
      int kabul = 0;
      int red = 0;
      for (int i = 0; i < 300; i++) {
        final GameState s = kardesliHayat(
          kardesBirikimi: 400000,
          bag: 55,
          kardesCalisiyor: true,
        );
        final ({GameState state, String text, bool accepted}) r =
            FamilyDisputes.borrowFromSibling(s, 'kardes-ap', Random(i));
        if (r.accepted) {
          kabul++;
        } else {
          red++;
        }
      }
      expect(kabul, greaterThan(0), reason: 'Hiç kabul edilmiyor.');
      expect(red, greaterThan(0),
          reason: '§29: kardeş her zaman evet dememeli (kabul $kabul, '
              'red $red).');
    });

    test('arası kopuk kardeş reddediyor', () {
      final GameState s = kardesliHayat(
        kardesBirikimi: 400000,
        bag: FamilyDisputes.prototypeOnlyBorrowBond - 5,
        kardesCalisiyor: true,
      );
      for (int i = 0; i < 50; i++) {
        final ({GameState state, String text, bool accepted}) r =
            FamilyDisputes.borrowFromSibling(s, 'kardes-ap', Random(i));
        expect(r.accepted, isFalse);
      }
    });

    test('kabul edilen borç kardeşin kaydından çıkıyor', () {
      for (int i = 0; i < 300; i++) {
        final GameState s = kardesliHayat(
          kardesBirikimi: 400000,
          bag: 90,
          kardesCalisiyor: true,
        );
        final ({GameState state, String text, bool accepted}) r =
            FamilyDisputes.borrowFromSibling(s, 'kardes-ap', Random(i));
        if (!r.accepted) continue;
        final int kapasite = FamilyDisputes.siblingLendCapacity(k(s));
        expect(r.state.player.wallet, s.player.wallet + kapasite);
        expect(k(r.state).development!.money,
            k(s).development!.money - kapasite);
        expect(r.state.player.wallet + k(r.state).development!.money,
            s.player.wallet + k(s).development!.money,
            reason: 'Toplam korunmalı.');
        return;
      }
      fail('300 denemede hiç kabul edilmedi.');
    });

    test('üst üste borç istenemiyor', () {
      final GameState s = kardesliHayat(
        kardesBirikimi: 400000,
        bag: 90,
        kardesCalisiyor: true,
      );
      final GameState sonra =
          FamilyDisputes.borrowFromSibling(s, 'kardes-ap', Random(1)).state;
      expect(FamilyDisputes.borrowBlockReason(sonra, 'kardes-ap'), isNotNull);
    });
  });

  group('§30-§32 — yaşlı bakımı: kapasite gerçek', () {
    GameState bakimAc(GameState s) {
      for (int i = 0; i < 1500; i++) {
        final GameState sonra =
            FamilyDisputes.maybeCareDispute(s, s.player.age, Random(i)).state;
        if (FamilyDisputes.pendingCareDispute(sonra) != null) return sonra;
      }
      fail('1500 denemede bakım meselesi çıkmadı.');
    }

    test('ebeveyn yeterince yaşlı değilse mesele açılmıyor', () {
      final GameState s = kardesliHayat(ebeveynYasi: 60);
      expect(FamilyDisputes.parentNeedingCare(s), isNull);
      for (int i = 0; i < 200; i++) {
        final GameState sonra =
            FamilyDisputes.maybeCareDispute(s, s.player.age, Random(i)).state;
        expect(FamilyDisputes.pendingCareDispute(sonra), isNull);
      }
    });

    test('"ben bakarım" kapasite istiyor; yoksa gerekçesi yazılıyor', () {
      final GameState parasiz =
          bakimAc(kardesliHayat(ebeveynYasi: 80, cuzdan: 1000));
      final String? engel = FamilyDisputes.careBlockReason(
        parasiz,
        FamilyIssueResponse.destekOldu,
      );
      expect(engel, isNotNull);
      expect(engel, contains('cüzdanında o kadar yok'));
      // Ve karar uygulanmıyor.
      final GameState sonra = FamilyDisputes.respondCare(
        parasiz,
        FamilyIssueResponse.destekOldu,
      ).state;
      expect(sonra.player.wallet, parasiz.player.wallet);
      expect(FamilyDisputes.pendingCareDispute(sonra), isNotNull);
    });

    test('bakımı üstlenmek gerçekten para götürüyor', () {
      final GameState s = bakimAc(kardesliHayat(ebeveynYasi: 80));
      final GameState sonra = FamilyDisputes.respondCare(
        s,
        FamilyIssueResponse.destekOldu,
      ).state;
      expect(sonra.player.wallet,
          s.player.wallet - FamilyDisputes.prototypeOnlyCareCost);
    });

    test('karışmamak ebeveyni ve kardeşi uzaklaştırıyor', () {
      final GameState s = bakimAc(kardesliHayat(ebeveynYasi: 80));
      final FamilyIssue m = FamilyDisputes.pendingCareDispute(s)!;
      final int ebeveynOnce = s.personById(m.personId)!.bond;
      final int kardesOnce = k(s).bond;
      final GameState sonra = FamilyDisputes.respondCare(
        s,
        FamilyIssueResponse.karismadi,
      ).state;
      expect(sonra.personById(m.personId)!.bond, lessThan(ebeveynOnce));
      expect(k(sonra).bond, lessThan(kardesOnce));
      // Kardeşler otomatik küsmüyor (§33).
      expect(k(sonra).isEstranged, isFalse);
    });

    test('aynı ebeveyn için mesele iki kez açılmıyor', () {
      GameState s = bakimAc(kardesliHayat(ebeveynYasi: 80));
      s = FamilyDisputes.respondCare(s, FamilyIssueResponse.paraVerdi).state;
      s = s.copyWith(player: s.player.copyWith(age: s.player.age + 5));
      for (int i = 0; i < 400; i++) {
        final GameState sonra =
            FamilyDisputes.maybeCareDispute(s, s.player.age, Random(i)).state;
        expect(FamilyDisputes.pendingCareDispute(sonra), isNull);
      }
    });
  });

  group('§35-§36 — miras anlaşmazlığı para üretmiyor', () {
    GameState itirazAc(GameState s, {int miras = 1000000}) {
      for (int i = 0; i < 1500; i++) {
        final ({GameState state, PendingNotice? notice}) r =
            FamilyDisputes.maybeEstateDispute(
          s,
          s.player.age,
          Random(i),
          inheritedThisYear: miras,
        );
        if (FamilyDisputes.pendingEstateDispute(r.state) != null) {
          return r.state;
        }
      }
      fail('1500 denemede miras itirazı çıkmadı.');
    }

    test('o yıl miras gelmediyse itiraz çıkmıyor', () {
      final GameState s = kardesliHayat();
      for (int i = 0; i < 300; i++) {
        final ({GameState state, PendingNotice? notice}) r =
            FamilyDisputes.maybeEstateDispute(
          s,
          s.player.age,
          Random(i),
          inheritedThisYear: 0,
        );
        expect(FamilyDisputes.pendingEstateDispute(r.state), isNull);
      }
    });

    test('itiraz tutarı gelen mirastan türetiliyor', () {
      final GameState az = itirazAc(kardesliHayat(), miras: 100000);
      final GameState cok = itirazAc(kardesliHayat(), miras: 2000000);
      expect(FamilyDisputes.contestedAmount(cok),
          greaterThan(FamilyDisputes.contestedAmount(az)));
    });

    test('kabul edilince para taşınıyor, üretilmiyor', () {
      final GameState s = itirazAc(kardesliHayat());
      final int tutar = FamilyDisputes.contestedAmount(s);
      expect(tutar, greaterThan(0));
      final int cuzdan = s.player.wallet;
      final int kardesPara = k(s).development!.money;
      final GameState sonra = FamilyDisputes.respondEstateDispute(
        s,
        FamilyIssueResponse.paraVerdi,
      ).state;
      expect(sonra.player.wallet, cuzdan - tutar);
      expect(k(sonra).development!.money, kardesPara + tutar);
      expect(sonra.player.wallet + k(sonra).development!.money,
          cuzdan + kardesPara);
    });

    test('reddetmek para üretmiyor, bağı sert düşürüyor', () {
      final GameState s = itirazAc(kardesliHayat());
      final GameState sonra = FamilyDisputes.respondEstateDispute(
        s,
        FamilyIssueResponse.reddetti,
      ).state;
      expect(sonra.player.wallet, s.player.wallet);
      expect(k(sonra).development!.money, k(s).development!.money);
      expect(k(sonra).bond, lessThan(k(s).bond));
    });

    test('cüzdanda tutar yoksa gerekçe yazılıyor', () {
      final GameState s =
          itirazAc(kardesliHayat(cuzdan: 2000), miras: 1000000);
      expect(
        FamilyDisputes.estateBlockReason(s, FamilyIssueResponse.paraVerdi),
        isNotNull,
      );
      final GameState sonra = FamilyDisputes.respondEstateDispute(
        s,
        FamilyIssueResponse.paraVerdi,
      ).state;
      expect(sonra.player.wallet, s.player.wallet);
    });

    test('mirasın kendisi ikinci kez dağıtılmıyor', () {
      // `settledEstates` koruması zaten var; itiraz onu bozmuyor.
      final GameState s = itirazAc(kardesliHayat());
      final GameState sonra = FamilyDisputes.respondEstateDispute(
        s,
        FamilyIssueResponse.paraVerdi,
      ).state;
      expect(sonra.settledEstates, s.settledEstates);
    });
  });

  group('§33-§34 — küslük ve barışma: ikinci kez kurulmadı', () {
    test('barışma garanti değil (Paket AO mekanizması)', () {
      GameState s = kardesliHayat(bag: 60);
      // Kardeşi küs yap.
      s = s.copyWith(
        people: List<Person>.unmodifiable(<Person>[
          for (final Person p in s.people)
            if (p.id == 'kardes-ap')
              p.copyWith(estrangedSinceAge: s.player.age - 2)
            else
              p,
        ]),
      );
      int oldu = 0;
      int olmadi = 0;
      for (int i = 0; i < 300; i++) {
        final bool baristi = FriendshipDepth.makeUp(
              state: s,
              personId: 'kardes-ap',
              rng: Random(i),
            ).state.personById('kardes-ap')!.isEstranged ==
            false;
        if (baristi) {
          oldu++;
        } else {
          olmadi++;
        }
      }
      expect(oldu, greaterThan(0), reason: 'Hiç barışılamıyor.');
      expect(olmadi, greaterThan(0),
          reason: '§34: %100 barış olmamalı (oldu $oldu, olmadı $olmadi).');
    });

    test('küslük kaydı kişiyi silmiyor', () {
      GameState s = kardesliHayat();
      s = s.copyWith(
        people: List<Person>.unmodifiable(<Person>[
          for (final Person p in s.people)
            if (p.id == 'kardes-ap')
              p.copyWith(estrangedSinceAge: s.player.age)
            else
              p,
        ]),
      );
      expect(s.personById('kardes-ap'), isNotNull);
      expect(k(s).isEstranged, isTrue);
    });
  });

  group('§33 — aile içinde küslük: sebebi olmadan olmaz', () {
    /// Reddedilmiş bir meselesi olan ve yakınlığı dibe inmiş kardeş.
    GameState kopmayaYakin({int bag = 5, bool reddedildi = true}) {
      GameState s = kardesliHayat(bag: bag);
      s = s.openFamilyIssue(
        kind: FamilyIssueKind.kardesPara,
        personId: 'kardes-ap',
      );
      s = s.updateFamilyIssue(
        s.familyIssues.first.id,
        response: reddedildi
            ? FamilyIssueResponse.reddetti
            : FamilyIssueResponse.paraVerdi,
        status: FamilyIssueStatus.cozuldu,
        resolvedAtAge: s.player.age,
      );
      return s.copyWith(
        people: List<Person>.unmodifiable(<Person>[
          for (final Person p in s.people)
            if (p.id == 'kardes-ap') p.copyWith(bond: bag) else p,
        ]),
      );
    }

    test('sebebi olmayan kişi küs düşmüyor', () {
      // Yakınlık dibe inmiş ama mesele reddedilmemiş.
      final GameState s = kopmayaYakin(reddedildi: false);
      expect(FamilyDisputes.falloutCandidates(s), isEmpty);
      for (int i = 0; i < 200; i++) {
        final GameState sonra = FamilyDisputes.maybeFamilyFallout(
          s,
          s.player.age,
          Random(i),
        ).state;
        expect(sonra.personById('kardes-ap')!.isEstranged, isFalse);
      }
    });

    test('yakınlığı iyi olan kişi küs düşmüyor', () {
      final GameState s = kopmayaYakin(bag: 70);
      expect(FamilyDisputes.falloutCandidates(s), isEmpty);
    });

    test('yıllarca biriken uzaklaşma küslüğe dönüşebiliyor', () {
      final GameState s = kopmayaYakin();
      expect(FamilyDisputes.falloutCandidates(s), isNotEmpty);
      bool oldu = false;
      bool olmadi = false;
      for (int i = 0; i < 200; i++) {
        final GameState sonra = FamilyDisputes.maybeFamilyFallout(
          s,
          s.player.age,
          Random(i),
        ).state;
        if (sonra.personById('kardes-ap')!.isEstranged) {
          oldu = true;
        } else {
          olmadi = true;
        }
      }
      expect(oldu, isTrue, reason: 'Küslük hiç olmuyor.');
      expect(olmadi, isTrue,
          reason: '§33: eşiğin altına inmek küslük garantisi olmamalı.');
    });

    test('küs düşen kişi kayıttan silinmiyor, bağ türü değişmiyor', () {
      final GameState s = kopmayaYakin();
      for (int i = 0; i < 200; i++) {
        final GameState sonra = FamilyDisputes.maybeFamilyFallout(
          s,
          s.player.age,
          Random(i),
        ).state;
        final Person? kardes = sonra.personById('kardes-ap');
        if (kardes == null || !kardes.isEstranged) continue;
        expect(kardes.relation, RelationType.kardes);
        expect(kardes.estrangedSinceAge, s.player.age);
        // Barış kapısı açık (Paket AO).
        expect(
          FriendshipDepth.makeUpAvailability(sonra, 'kardes-ap').isAllowed,
          isFalse,
          reason: 'Aynı yıl barışılamaz; bir yıl geçmeli.',
        );
        return;
      }
      fail('200 denemede hiç küslük olmadı.');
    });

    test('bir yılda en fazla bir kişiyle küs düşülüyor', () {
      GameState s = kopmayaYakin();
      // İkinci bir sorunlu yakın ekle.
      final Person ikinci = Person(
        id: 'kardes-iki',
        firstName: 'Ece',
        lastName: s.player.lastName,
        gender: Gender.kadin,
        relation: RelationType.kardes,
        age: 46,
        isAlive: true,
        inPlayerHousehold: false,
        employment: EmploymentStatus.issiz,
        wealth: WealthTier.yoksul,
        bond: 4,
        development: const PersonDevelopment(
          tracksLife: true,
          finishedSchool: true,
          money: 1000,
          stats: _ortaStats,
        ),
      );
      s = s.copyWith(
        people: List<Person>.unmodifiable(<Person>[...s.people, ikinci]),
        familyIssues: List<FamilyIssue>.unmodifiable(<FamilyIssue>[
          ...s.familyIssues,
          FamilyIssue(
            id: 'm-iki',
            kind: FamilyIssueKind.kardesPara,
            personId: 'kardes-iki',
            openedAtAge: s.player.age - 1,
            lastEventAge: s.player.age - 1,
            status: FamilyIssueStatus.cozuldu,
            resolvedAtAge: s.player.age - 1,
            response: FamilyIssueResponse.reddetti,
          ),
        ]),
      );
      expect(FamilyDisputes.falloutCandidates(s).length, 2);
      for (int i = 0; i < 200; i++) {
        final GameState sonra = FamilyDisputes.maybeFamilyFallout(
          s,
          s.player.age,
          Random(i),
        ).state;
        final int kusSayisi =
            sonra.people.where((Person p) => p.isEstranged).length;
        expect(kusSayisi, lessThanOrEqualTo(1),
            reason: 'Aile topluca boşalmamalı.');
      }
    });
  });

  group('§37-§39 — eski eşle ortak ebeveynlik otomatik romantizm değil', () {
    test('eski eş romantik havuza geri dönmüyor', () {
      // Ortak çocuk olsa bile eski eş "sevgili adayı" olmuyor: oyunun
      // kendi kuralı (Paket AO §17 / AP §67) bunu yasaklıyor.
      final GameState s = kardesliHayat();
      final Person eskiEs = Person(
        id: 'eski-es-1',
        firstName: 'Selin',
        lastName: 'Demir',
        gender: Gender.kadin,
        relation: RelationType.eskiEs,
        age: s.player.age,
        isAlive: true,
        inPlayerHousehold: false,
        employment: EmploymentStatus.calisiyor,
        occupation: 'muhasebeci',
        wealth: WealthTier.ortaHalli,
        bond: 55,
        city: s.player.currentCity,
      );
      final GameState ile = s.copyWith(
        people: List<Person>.unmodifiable(<Person>[...s.people, eskiEs]),
      );
      // Hiçbir yıl ilerlemesi eski eşi kendiliğinden `es` yapmıyor.
      expect(ile.personById('eski-es-1')!.relation, RelationType.eskiEs);
      expect(ile.marriage, isNull);
    });
  });
}

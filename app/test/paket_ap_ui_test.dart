// Paket AP §56-§60 — ekran tarafı: bekleyen aile kararı, çocuğun eşi,
// aile sorunu satırı ve küslük.
//
// En önemli test `wiredKinds`: Paket AO'da üç motorun hiçbir ekrandan
// ulaşılamadığı görülmüştü. Yeni bir aile meselesi eklenip ekrana
// bağlanmazsa bu dosya kırılır.
library;

import 'dart:math';

import 'package:bir_omur/domain/family/family_decision.dart';
import 'package:bir_omur/domain/family/family_disputes.dart';
import 'package:bir_omur/domain/interaction/shared_history.dart';
import 'package:bir_omur/domain/models/family_issue.dart';
import 'package:bir_omur/domain/models/game_state.dart';
import 'package:bir_omur/domain/models/gender.dart';
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
  health: 70,
  intelligence: 60,
  charisma: 55,
);

GameState okullCocukluHayat({int seed = 41, int playerAge = 42}) {
  final GameState taban = aileliHayat(seed: seed, age: playerAge);
  return taban.copyWith(
    player: taban.player.copyWith(wallet: 2000000),
    people: List<Person>.unmodifiable(<Person>[
      ...taban.people,
      Person(
        id: 'cocuk-ui',
        firstName: 'Deniz',
        lastName: taban.player.lastName,
        gender: Gender.kadin,
        relation: RelationType.cocuk,
        age: 12,
        isAlive: true,
        inPlayerHousehold: true,
        employment: EmploymentStatus.ogrenci,
        wealth: null,
        bond: 60,
        city: taban.player.currentCity,
        motherId: taban.player.id,
        development: const PersonDevelopment(
          tracksLife: true,
          grade: 7,
          stats: Stats(
            appearance: 55,
            happiness: 25,
            health: 70,
            intelligence: 25,
            charisma: 55,
          ),
        ),
      ),
    ]),
  );
}

void main() {
  group('§56 — her aile meselesi ekrana bağlı', () {
    test('ekrana bağlanmayan mesele türü kalmıyor', () {
      expect(
        FamilyDecisions.wiredKinds,
        containsAll(FamilyIssueKind.values),
        reason: 'Yeni bir aile meselesi eklendi ama ekrana bağlanmadı. '
            'Paket AO\'da üç motor tam böyle ulaşılamaz kalmıştı.',
      );
    });

    test('karar sorulan türler ekrana bağlı türlerin alt kümesi', () {
      expect(FamilyDecisions.wiredKinds,
          containsAll(FamilyDecisions.askedKinds));
    });
  });

  group('§56-§58 — bekleyen karar tek kapıdan okunuyor', () {
    test('bekleyen karar yoksa null', () {
      final GameState s = aileliHayat(seed: 3, age: 30);
      expect(FamilyDecisions.pending(s), isNull);
    });

    test('okul meselesi karar olarak çıkıyor ve seçenekleri var', () {
      GameState s = okullCocukluHayat();
      s = s.openFamilyIssue(
        kind: FamilyIssueKind.cocukOkul,
        personId: 'cocuk-ui',
      );
      final FamilyDecision? karar = FamilyDecisions.pending(s);
      expect(karar, isNotNull);
      expect(karar!.kind, FamilyIssueKind.cocukOkul);
      expect(karar.personId, 'cocuk-ui');
      expect(karar.options.length, greaterThanOrEqualTo(3));
      // §58: iç sayı gösterilmiyor.
      expect(karar.text, isNot(contains('0.')));
      expect(karar.text, isNot(contains('aşama')));
      // Metin doğal Türkçe: yasaklı hitaplar yok.
      for (final String yasak in <String>['abi', 'oğlum', 'aga', 'lan']) {
        expect(karar.text.toLowerCase().split(' '), isNot(contains(yasak)));
      }
    });

    test('cevap gerçekten uygulanıyor', () {
      GameState s = okullCocukluHayat();
      s = s.openFamilyIssue(
        kind: FamilyIssueKind.cocukOkul,
        personId: 'cocuk-ui',
      );
      final ({GameState state, String text}) r = FamilyDecisions.answer(
        s,
        FamilyIssueResponse.destekOldu,
        Random(1),
      );
      expect(r.text, isNotEmpty);
      expect(r.state.familyIssues.first.response,
          FamilyIssueResponse.destekOldu);
    });

    test('parası olmayan oyuncuda seçenek görünür ama gerekçeli kapalı',
        () {
      GameState s = okullCocukluHayat();
      s = s.copyWith(player: s.player.copyWith(wallet: 100));
      s = s.openFamilyIssue(
        kind: FamilyIssueKind.cocukOkul,
        personId: 'cocuk-ui',
      );
      final FamilyDecision karar = FamilyDecisions.pending(s)!;
      final FamilyDecisionOption ozelDers = karar.options.firstWhere(
        (FamilyDecisionOption o) =>
            o.response == FamilyIssueResponse.paraVerdi,
      );
      expect(ozelDers.isAllowed, isFalse);
      expect(ozelDers.blockedReason, isNotNull);
      // Seçenek listeden **silinmiyor**: gerekçe görünsün (D-095).
      expect(karar.options.map((FamilyDecisionOption o) => o.response),
          contains(FamilyIssueResponse.paraVerdi));
    });

    test('her kararın her seçeneğinde boş etiket yok', () {
      // Altı mesele türünü tek tek açıp kartın kurulabildiğini sına.
      for (final FamilyIssueKind tur in FamilyDecisions.askedKinds) {
        GameState s = okullCocukluHayat(playerAge: 58);
        // Bakım meselesi için ebeveyni yaşlandır.
        s = s.copyWith(
          people: List<Person>.unmodifiable(<Person>[
            for (final Person p in s.people)
              if (p.relation == RelationType.anne ||
                  p.relation == RelationType.baba)
                p.copyWith(age: 82)
              else
                p,
          ]),
        );
        final String? kisi = switch (tur) {
          FamilyIssueKind.cocukOkul => 'cocuk-ui',
          FamilyIssueKind.cocukPara => 'cocuk-ui',
          FamilyIssueKind.kardesPara => s.people
              .where((Person p) => p.relation == RelationType.kardes)
              .map((Person p) => p.id)
              .firstOrNull,
          FamilyIssueKind.bakim => s.people
              .where((Person p) => p.relation == RelationType.anne)
              .map((Person p) => p.id)
              .firstOrNull,
          FamilyIssueKind.miras => s.people
              .where((Person p) => p.relation == RelationType.kardes)
              .map((Person p) => p.id)
              .firstOrNull,
          FamilyIssueKind.kayinGerginlik => s.people
              .where((Person p) => p.relation == RelationType.anne)
              .map((Person p) => p.id)
              .firstOrNull,
          FamilyIssueKind.cocukEvlilik => null,
        };
        if (kisi == null) continue;
        s = s.openFamilyIssue(kind: tur, personId: kisi);
        final FamilyDecision? karar = FamilyDecisions.pending(s);
        if (karar == null) continue;
        expect(karar.title, isNotEmpty, reason: tur.name);
        expect(karar.text, isNotEmpty, reason: tur.name);
        expect(karar.options, isNotEmpty, reason: tur.name);
        for (final FamilyDecisionOption o in karar.options) {
          expect(o.label, isNotEmpty, reason: '${tur.name}/${o.response}');
        }
      }
    });
  });

  group('§59-§60 — kişi kartındaki satır', () {
    test('meselesi olmayan kişide satır yok', () {
      final GameState s = okullCocukluHayat();
      expect(
        FamilyDecisions.statusLineFor(s, s.personById('cocuk-ui')!),
        isNull,
      );
    });

    test('süren mesele doğal Türkçe tek satır, iç sayı yok', () {
      GameState s = okullCocukluHayat();
      s = s.openFamilyIssue(
        kind: FamilyIssueKind.cocukOkul,
        personId: 'cocuk-ui',
      );
      final String? satir =
          FamilyDecisions.statusLineFor(s, s.personById('cocuk-ui')!);
      expect(satir, isNotNull);
      expect(satir, contains('okul meselesi'));
      expect(satir, contains('bu yıl'));
      expect(satir, isNot(contains('aşama')));
    });

    test('yıllar geçince süre satırda doğru yazıyor', () {
      GameState s = okullCocukluHayat();
      s = s.openFamilyIssue(
        kind: FamilyIssueKind.cocukOkul,
        personId: 'cocuk-ui',
      );
      final GameState birYil =
          s.copyWith(player: s.player.copyWith(age: s.player.age + 1));
      expect(
        FamilyDecisions.statusLineFor(birYil, birYil.personById('cocuk-ui')!),
        contains('bir yıldır'),
      );
      final GameState ucYil =
          s.copyWith(player: s.player.copyWith(age: s.player.age + 3));
      expect(
        FamilyDecisions.statusLineFor(ucYil, ucYil.personById('cocuk-ui')!),
        contains('3 yıldır'),
      );
    });

    test('§60: küslük sebebi UYDURULMUYOR, yalnızca süre yazıyor', () {
      GameState s = okullCocukluHayat();
      s = s.copyWith(
        people: List<Person>.unmodifiable(<Person>[
          for (final Person p in s.people)
            if (p.id == 'cocuk-ui')
              p.copyWith(estrangedSinceAge: s.player.age - 2)
            else
              p,
        ]),
      );
      final String? satir =
          FamilyDecisions.statusLineFor(s, s.personById('cocuk-ui')!);
      expect(satir, '2 yıldır konuşmuyorsunuz');
      // Sebep cümlesi yok.
      expect(satir, isNot(contains('çünkü')));
      expect(satir, isNot(contains('yüzünden')));
    });

    test('mesele küslükten önce gelir: iki satır birden yazılmaz', () {
      GameState s = okullCocukluHayat();
      s = s.copyWith(
        people: List<Person>.unmodifiable(<Person>[
          for (final Person p in s.people)
            if (p.id == 'cocuk-ui')
              p.copyWith(estrangedSinceAge: s.player.age - 2)
            else
              p,
        ]),
      );
      s = s.openFamilyIssue(
        kind: FamilyIssueKind.cocukOkul,
        personId: 'cocuk-ui',
      );
      final String satir =
          FamilyDecisions.statusLineFor(s, s.personById('cocuk-ui')!)!;
      expect(satir, contains('okul meselesi'));
      expect(satir, isNot(contains('konuşmuyorsunuz')));
    });

    test('kapanmış mesele satır yazdırmıyor', () {
      GameState s = okullCocukluHayat();
      s = s.openFamilyIssue(
        kind: FamilyIssueKind.cocukOkul,
        personId: 'cocuk-ui',
      );
      s = s.updateFamilyIssue(
        s.familyIssues.first.id,
        status: FamilyIssueStatus.cozuldu,
        resolvedAtAge: s.player.age,
      );
      expect(
        FamilyDecisions.statusLineFor(s, s.personById('cocuk-ui')!),
        isNull,
      );
    });
  });

  group('§57 — çocuğun eşi kartta görünüyor', () {
    test('evli çocuğun eşi gerçek kayıttan okunuyor', () {
      // Ekran yardımcısı özel olduğu için kurallar `PersonDevelopment`
      // üzerinden sınanıyor: ekranın okuduğu alanlar bunlar.
      const PersonDevelopment evli = PersonDevelopment(
        tracksLife: true,
        stats: _ortaStats,
        marriedAtAge: 27,
        spouseName: 'Ahmet',
        spousePersonId: 'cocugunesi-x-1',
        marriageStatus: NpcMarriageStatus.evli,
      );
      expect(evli.isMarried, isTrue);
      expect(evli.spouseName, 'Ahmet');

      const PersonDevelopment bosandi = PersonDevelopment(
        tracksLife: true,
        stats: _ortaStats,
        marriedAtAge: 27,
        spouseName: 'Ahmet',
        marriageStatus: NpcMarriageStatus.bosandi,
      );
      expect(bosandi.isMarried, isFalse);
      expect(bosandi.isDivorced, isTrue);

      const PersonDevelopment dul = PersonDevelopment(
        tracksLife: true,
        stats: _ortaStats,
        marriedAtAge: 27,
        spouseName: 'Ahmet',
        marriageStatus: NpcMarriageStatus.dul,
      );
      expect(dul.isWidowed, isTrue);
    });

    test('hiç evlenmemiş çocukta eş satırı olmaz', () {
      const PersonDevelopment bekar = PersonDevelopment(
        tracksLife: true,
        stats: _ortaStats,
      );
      expect(bekar.spouseName, isNull);
      expect(bekar.isMarried, isFalse);
    });
  });

  group('§55 — aile meselesi kişinin ortak geçmişine düşüyor', () {
    test('karar günlüğe kişiyle birlikte yazılıyor', () {
      // `SharedHistory` kişinin ortak geçmişini günlükteki `personId`
      // alanından topluyor. İlk yazımda bu alan boş kalıyordu, yani
      // Paket AP'nin bütün aile anları kişinin kartında hiç
      // görünmüyordu.
      GameState s = okullCocukluHayat();
      s = s.openFamilyIssue(
        kind: FamilyIssueKind.cocukOkul,
        personId: 'cocuk-ui',
      );
      s = FamilyDecisions.answer(
        s,
        FamilyIssueResponse.destekOldu,
        Random(1),
      ).state;

      final Person cocuk = s.personById('cocuk-ui')!;
      final List<SharedMoment> anlar = SharedHistory.of(s, cocuk);
      expect(
        anlar.any((SharedMoment m) => m.text.contains('ders çalışmaya')),
        isTrue,
        reason: 'Aile kararı kişinin ortak geçmişinde görünmeli.',
      );
    });

    test('kardeşle para meselesi kardeşin geçmişine düşüyor', () {
      final GameState taban = okullCocukluHayat(playerAge: 50);
      final String? kardesId = taban.people
          .where((Person p) => p.relation == RelationType.kardes)
          .map((Person p) => p.id)
          .firstOrNull;
      if (kardesId == null) return;
      GameState s = taban.openFamilyIssue(
        kind: FamilyIssueKind.kardesPara,
        personId: kardesId,
      );
      s = FamilyDisputes.respondSiblingAsk(
        s,
        FamilyIssueResponse.reddetti,
      ).state;
      final List<SharedMoment> anlar =
          SharedHistory.of(s, s.personById(kardesId)!);
      expect(
        anlar.any((SharedMoment m) => m.text.contains('para')),
        isTrue,
        reason: 'Kardeşle para meselesi onun geçmişinde görünmeli.',
      );
    });
  });

  group('kardeş borcu ekrandan ulaşılabilir', () {
    test('gerekçe yazılıyor, sessiz kaybolma yok', () {
      final GameState s = okullCocukluHayat();
      final String? kardesId = s.people
          .where((Person p) => p.relation == RelationType.kardes)
          .map((Person p) => p.id)
          .firstOrNull;
      if (kardesId == null) return;
      // İlk istek yapılabilir.
      expect(FamilyDisputes.borrowBlockReason(s, kardesId), isNull);
      final GameState sonra =
          FamilyDisputes.borrowFromSibling(s, kardesId, Random(1)).state;
      // Hemen ardından gerekçe var.
      expect(FamilyDisputes.borrowBlockReason(sonra, kardesId), isNotNull);
    });
  });
}

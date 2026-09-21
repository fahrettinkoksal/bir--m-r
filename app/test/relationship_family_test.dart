import 'dart:math';

import 'package:bir_omur/data/save/game_state_codec.dart';
import 'package:bir_omur/domain/interaction/adoption.dart';
import 'package:bir_omur/domain/interaction/marriage_engine.dart';
import 'package:bir_omur/domain/interaction/parenthood.dart';
import 'package:bir_omur/domain/interaction/romance.dart';
import 'package:bir_omur/domain/generation/life_generator.dart';
import 'package:bir_omur/domain/models/game_state.dart';
import 'package:bir_omur/domain/models/person.dart';
import 'package:bir_omur/domain/models/relation.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/invariants.dart';

const MarriageEngine evlilik = MarriageEngine();
const Parenthood ebeveynlik = Parenthood();
const Adoption evlatEdinme = Adoption();

GameState oyuncu(int seed, {int age = 28, int wallet = 500000}) {
  final GameState base =
      LifeGenerator.seeded(seed).generate(mode: StartMode.tamamenRastgele);
  return base.copyWith(
    player: base.player.copyWith(age: age, wallet: wallet),
  );
}

({GameState state, Person partner}) sevgiliyle(
  int seed, {
  int age = 28,
  int bond = 80,
  int wallet = 500000,
}) {
  final ({GameState state, Person partner}) r =
      const Romance().start(oyuncu(seed, age: age, wallet: wallet), Random(seed + 1));
  final GameState state = r.state.copyWith(
    people: r.state.people
        .map((Person p) => p.id == r.partner.id ? p.copyWith(bond: bond) : p)
        .toList(growable: false),
  );
  return (state: state, partner: state.personById(r.partner.id)!);
}

void main() {
  // ===================================================================
  // A) Evlilik dışı çocuk (D-047)
  // ===================================================================
  group('Evlilik dışı çocuk', () {
    test('iki biyolojik ebeveyn de kayıtta kalır, sevgili eş yapılmaz', () {
      final ({GameState state, Person partner}) v = sevgiliyle(41);
      final GameState sonra = ebeveynlik.haveChild(v.state, Random(2)).state;

      expect(sonra.children.length, 1);
      expect(sonra.marriage, isNull, reason: 'Evlilik kaydı uydurulmaz');
      final Person sevgili = sonra.personById(v.partner.id)!;
      expect(sevgili.relation, RelationType.sevgili);
      expect(sevgili.isAlive, isTrue);
      // Çocuk hanede ve gerçek bir kişi kaydı.
      expect(sonra.children.single.inPlayerHousehold, isTrue);
      expect(sonra.children.single.development, isNotNull);
      expect(checkInvariants(sonra), isEmpty);
    });

    test('reşit olmayan oyuncu veya sevgili için akış açılmaz', () {
      final ({GameState state, Person partner}) genc =
          sevgiliyle(42, age: 16);
      expect(ebeveynlik.blockReason(genc.state), isNotEmpty);

      final ({GameState state, Person partner}) v = sevgiliyle(43);
      final GameState kucukSevgili = v.state.copyWith(
        people: v.state.people
            .map((Person p) =>
                p.id == v.partner.id ? p.copyWith(age: 17) : p)
            .toList(growable: false),
      );
      expect(ebeveynlik.blockReason(kucukSevgili), contains('genç'));
    });

    test('masraf ve çocuk iki kez uygulanmaz', () {
      final ({GameState state, Person partner}) v = sevgiliyle(44);
      final int cuzdan = v.state.player.wallet;
      final GameState bir = ebeveynlik.haveChild(v.state, Random(3)).state;
      expect(bir.player.wallet, cuzdan - Parenthood.prototypeOnlyBirthCost);

      // Aynı yıl ikinci bebek olmaz; kayıttan dönünce de tekrarlanmaz.
      expect(ebeveynlik.haveChild(bir, Random(3)).outcome.applied, isFalse);
      final GameState geri = decodeGameState(encodeGameState(bir));
      expect(geri.children.length, 1);
      expect(geri.player.wallet, bir.player.wallet);
    });

    test('evlilik dışı çocuk da mirasta çocuktur', () {
      final ({GameState state, Person partner}) v = sevgiliyle(45);
      final GameState sonra = ebeveynlik.haveChild(v.state, Random(4)).state;
      expect(sonra.children.single.relation, RelationType.cocuk);
      expect(sonra.livingChildren.length, 1);
    });
  });

  // ===================================================================
  // B) Evlenme teklifi (D-048)
  // ===================================================================
  group('Evlenme teklifi', () {
    test('teklif her zaman kabul edilmez', () {
      int kabul = 0;
      int ret = 0;
      for (int seed = 0; seed < 60; seed++) {
        final ({GameState state, Person partner}) v =
            sevgiliyle(100 + seed, bond: 62);
        final FamilyResult r =
            evlilik.propose(v.state, v.partner.id, Random(seed));
        expect(r.outcome.applied, isTrue);
        if (r.state.isMarried) {
          kabul++;
        } else {
          ret++;
        }
      }
      expect(kabul, greaterThan(0), reason: 'Hiç kabul edilmiyor');
      expect(ret, greaterThan(0), reason: 'Her teklif kabul ediliyor');
    });

    test('yakınlık arttıkça kabul ihtimali artar', () {
      final ({GameState state, Person partner}) dusuk =
          sevgiliyle(50, bond: 50);
      final ({GameState state, Person partner}) yuksek =
          sevgiliyle(50, bond: 95);
      expect(
        evlilik.prototypeOnlyAcceptChance(dusuk.state, dusuk.partner),
        lessThan(
          evlilik.prototypeOnlyAcceptChance(yuksek.state, yuksek.partner),
        ),
      );
    });

    test('ret ilişkiyi bitirmez ama iz bırakır', () {
      final ({GameState state, Person partner}) v =
          sevgiliyle(51, bond: 46);
      GameState state = v.state;
      // Kabul edilene kadar değil, reddedilen bir teklif bulana kadar dene.
      FamilyResult? redd;
      for (int seed = 0; seed < 40 && redd == null; seed++) {
        final FamilyResult r = evlilik.propose(state, v.partner.id, Random(seed));
        if (!r.state.isMarried) redd = r;
      }
      expect(redd, isNotNull);
      final GameState sonra = redd!.state;

      // İlişki sürüyor: kişi hâlâ sevgili ve kayıtta.
      final Person sevgili = sonra.personById(v.partner.id)!;
      expect(sevgili.relation, RelationType.sevgili);
      expect(sevgili.bond, lessThan(v.partner.bond));
      expect(
        sonra.player.stats.happiness,
        lessThanOrEqualTo(v.state.player.stats.happiness),
      );
      // Yanıt kayda girdi.
      expect(sonra.lastProposalAge(v.partner.id), sonra.player.age);
    });

    test('aynı kişiye hemen yeniden teklif edilemez', () {
      // Ret yakınlığı düşürür; eşiğin üstünde kalsın diye 65 seçildi.
      final ({GameState state, Person partner}) v = sevgiliyle(52, bond: 65);
      final FamilyResult r = evlilik.propose(v.state, v.partner.id, Random(1));
      final GameState sonra = r.state;
      if (sonra.isMarried) return; // kabul edildiyse bu senaryo geçersiz

      expect(
        evlilik.proposeBlockReason(sonra, sonra.personById(v.partner.id)!),
        contains('yeterli zaman geçmedi'),
      );
      final GameState yillarSonra = sonra.copyWith(
        player: sonra.player.copyWith(
          age: sonra.player.age + MarriageEngine.prototypeOnlyProposalCooldown,
        ),
      );
      expect(
        evlilik.proposeBlockReason(
          yillarSonra,
          yillarSonra.personById(v.partner.id)!,
        ),
        isEmpty,
      );
    });

    test('teklif yanıtı kayda girer ve yeniden yüklemeyle değişmez', () {
      final ({GameState state, Person partner}) v = sevgiliyle(53, bond: 70);
      final GameState sonra =
          evlilik.propose(v.state, v.partner.id, Random(7)).state;
      final GameState geri = decodeGameState(encodeGameState(sonra));

      expect(geri.isMarried, sonra.isMarried);
      expect(geri.lastProposalAge(v.partner.id), sonra.player.age);
      if (sonra.isMarried) {
        expect(geri.marriage!.spouseId, sonra.marriage!.spouseId);
      }
    });

    test('kabul edilen teklif aynı kişiyi eşe dönüştürür, ikinci kişi açmaz',
        () {
      final ({GameState state, Person partner}) v = sevgiliyle(54, bond: 98);
      GameState state = v.state;
      final int kisiSayisi = state.people.length;
      for (int seed = 0; seed < 30 && !state.isMarried; seed++) {
        final GameState deneme =
            evlilik.propose(state, v.partner.id, Random(seed)).state;
        state = deneme.isMarried
            ? deneme
            : deneme.copyWith(
                player: deneme.player.copyWith(
                  age: deneme.player.age +
                      MarriageEngine.prototypeOnlyProposalCooldown,
                ),
              );
      }
      expect(state.isMarried, isTrue);
      expect(state.people.length, kisiSayisi, reason: 'İkinci kişi üretilmez');
      expect(state.spouse!.id, v.partner.id);
      // Aynı evlilik ikinci kez kurulamaz.
      expect(
        evlilik.propose(state, v.partner.id, Random(1)).outcome.applied,
        isFalse,
      );
      expect(checkInvariants(state), isEmpty);
    });
  });

  // ===================================================================
  // C) Evlat edinme (D-049)
  // ===================================================================
  group('Evlat edinme', () {
    test('bekâr oyuncu da başvurabilir', () {
      final GameState bekar = oyuncu(60).copyWith(
        career: oyuncu(60).career.copyWith(jobId: 'ogretmen', startedAtAge: 25),
      );
      expect(evlatEdinme.blockReason(bekar), isEmpty);
      expect(evlatEdinme.economicRejection(bekar), isEmpty);
    });

    test('parası yetmeyen başvuramaz, gerekçe gösterilir', () {
      final GameState fakir = oyuncu(61, wallet: 1000);
      expect(evlatEdinme.blockReason(fakir), contains('yeterli para yok'));
      final AdoptionResult r = evlatEdinme.apply(fakir, Random(1));
      expect(r.adopted, isFalse);
      expect(r.state.children, isEmpty);
      expect(r.state.player.wallet, 1000);
    });

    test('düzenli geliri ve birikimi yetersiz olan gerekçeyle reddedilir', () {
      final GameState dar = oyuncu(62, wallet: Adoption.prototypeOnlyCost + 1000);
      expect(evlatEdinme.blockReason(dar), isEmpty);
      final AdoptionResult r = evlatEdinme.apply(dar, Random(1));
      expect(r.adopted, isFalse);
      expect(r.outcome.text, contains('bakımını'));
      // Ücret düşmez.
      expect(r.state.player.wallet, dar.player.wallet);
    });

    test('zengin olmak otomatik kabul değildir', () {
      int kabul = 0;
      int ret = 0;
      for (int seed = 0; seed < 60; seed++) {
        final GameState zengin = oyuncu(63, wallet: 5000000);
        final AdoptionResult r = evlatEdinme.apply(zengin, Random(seed));
        if (r.adopted) {
          kabul++;
        } else {
          ret++;
        }
      }
      expect(kabul, greaterThan(0));
      expect(ret, greaterThan(0), reason: 'Hep kabul ediliyor');
    });

    test('kabul edilen başvuru gerçek bir çocuk kaydı oluşturur', () {
      final GameState zengin = oyuncu(64, wallet: 3000000);
      AdoptionResult? basarili;
      for (int seed = 0; seed < 40 && basarili == null; seed++) {
        final AdoptionResult r = evlatEdinme.apply(zengin, Random(seed));
        if (r.adopted) basarili = r;
      }
      expect(basarili, isNotNull);
      final GameState sonra = basarili!.state;
      final Person cocuk = sonra.children.single;

      expect(cocuk.relation, RelationType.cocuk);
      expect(cocuk.inPlayerHousehold, isTrue);
      expect(cocuk.development, isNotNull);
      expect(cocuk.development!.tracksLife, isTrue);
      // Kendi kimliği: ailenin soyadını alır, geçmişi uydurulmaz.
      expect(cocuk.lastName, sonra.player.lastName);
      expect(cocuk.development!.milestones.single.age, cocuk.age);
      // Ücret bir kez düşer.
      expect(
        sonra.player.wallet,
        zengin.player.wallet - Adoption.prototypeOnlyCost,
      );
      expect(checkInvariants(sonra), isEmpty);

      // Aynı yıl ikinci başvuru açılmaz: iki çocuk, iki ücret olmaz.
      expect(evlatEdinme.blockReason(sonra), contains('Bu yıl zaten'));
      final AdoptionResult ikinci = evlatEdinme.apply(sonra, Random(1));
      expect(ikinci.adopted, isFalse);
      expect(ikinci.state.children.length, 1);
      expect(ikinci.state.player.wallet, sonra.player.wallet);
    });

    test('evlat edinilen çocuğun özellikleri sonradan yeniden çizilmez', () {
      final GameState zengin = oyuncu(65, wallet: 3000000);
      AdoptionResult? basarili;
      for (int seed = 0; seed < 40 && basarili == null; seed++) {
        final AdoptionResult r = evlatEdinme.apply(zengin, Random(seed));
        if (r.adopted) basarili = r;
      }
      final GameState sonra = basarili!.state;
      final int zeka = sonra.children.single.development!.stats.intelligence;

      final GameState geri = decodeGameState(encodeGameState(sonra));
      expect(geri.children.single.development!.stats.intelligence, zeka);
    });

    test('evlat edinilen çocuk mirasta ve hanede sayılır', () {
      final GameState zengin = oyuncu(66, wallet: 3000000);
      AdoptionResult? basarili;
      for (int seed = 0; seed < 40 && basarili == null; seed++) {
        final AdoptionResult r = evlatEdinme.apply(zengin, Random(seed));
        if (r.adopted) basarili = r;
      }
      final GameState sonra = basarili!.state;
      expect(sonra.livingChildren.length, 1);
      expect(sonra.householdMembers.any((Person p) => p.relation == RelationType.cocuk), isTrue);
    });
  });

  // ===================================================================
  // Kayıt
  // ===================================================================
  test('teklif geçmişi kaydedilip geri okunur', () {
    final ({GameState state, Person partner}) v = sevgiliyle(70, bond: 50);
    final GameState sonra = v.state.copyWith(
      proposalAges: <String, int>{v.partner.id: 28, Adoption.attemptKey: 27},
      marriage: null,
    );
    final GameState geri = decodeGameState(encodeGameState(sonra));
    expect(geri.lastProposalAge(v.partner.id), 28);
    expect(geri.proposalAges[Adoption.attemptKey], 27);
  });
}

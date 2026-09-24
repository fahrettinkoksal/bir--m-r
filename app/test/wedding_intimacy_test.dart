import 'dart:math';

import 'package:bir_omur/data/save/game_state_codec.dart';
import 'package:bir_omur/data/save/save_format.dart';
import 'package:bir_omur/data/wedding_catalog.dart';
import 'package:bir_omur/domain/generation/life_generator.dart';
import 'package:bir_omur/domain/generation/life_progression.dart';
import 'package:bir_omur/domain/interaction/intimacy.dart';
import 'package:bir_omur/domain/interaction/marriage_engine.dart';
import 'package:bir_omur/domain/interaction/romance.dart';
import 'package:bir_omur/domain/models/game_state.dart';
import 'package:bir_omur/domain/models/person.dart';
import 'package:bir_omur/domain/models/relation.dart';
import 'package:flutter_test/flutter_test.dart';

const MarriageEngine evlilik = MarriageEngine();
const IntimacyEngine yakinlasma = IntimacyEngine();

/// Sevgilisi olan, evlenmeye uygun bir hayat.
({GameState state, Person partner}) sevgiliyle({
  int seed = 7,
  int age = 28,
  int wallet = 0,
  int bond = 85,
  bool partnerKisir = false,
  bool oyuncuKisir = false,
}) {
  final GameState base =
      LifeGenerator.seeded(seed).generate(mode: StartMode.tamamenRastgele);
  final ({GameState state, Person partner}) r = const Romance().start(
    base.copyWith(
      player: base.player.copyWith(
        age: age,
        wallet: wallet,
        infertile: oyuncuKisir,
      ),
    ),
    Random(seed),
  );
  final GameState state = r.state.copyWith(
    pendingEvent: null,
    people: r.state.people
        .map((Person p) => p.id == r.partner.id
            ? p.copyWith(bond: bond, age: age, infertile: partnerKisir)
            : p)
        .toList(growable: false),
  );
  return (state: state, partner: state.personById(r.partner.id)!);
}

/// Teklifi kabul ettirene kadar dener.
GameState kabulEttir(GameState state, String partnerId, {String stil = 'sade'}) {
  GameState akan = state;
  for (int seed = 0; seed < 60 && !akan.hasPendingWedding; seed++) {
    final FamilyResult r =
        evlilik.propose(akan, partnerId, Random(seed), styleId: stil);
    akan = r.state.hasPendingWedding
        ? r.state
        : r.state.copyWith(
            player: r.state.player.copyWith(
              age: r.state.player.age +
                  MarriageEngine.prototypeOnlyProposalCooldown,
            ),
          );
  }
  return akan;
}

/// Hamilelik başlayana kadar dener, sonra yaş ilerleterek doğurtur.
GameState dogumaKadar(GameState state, String partnerId) {
  GameState akan = state;
  for (int i = 0; i < 40 && !akan.isExpecting; i++) {
    akan = yakinlasma
        .perform(akan, partnerId, Protection.korunmadan, Random(i))
        .state;
    if (akan.isExpecting) break;
    akan = akan.copyWith(
      player: akan.player.copyWith(age: akan.player.age + 1),
    );
  }
  if (!akan.isExpecting) return akan;
  // Bebek bir sonraki yaş ilerlemesinde doğar.
  return LifeProgression(Random(5)).advanceOneYear(akan);
}

void main() {
  group('Teklif bedelsizdir (Paket 25)', () {
    test('cüzdanı boş oyuncu teklif edebilir', () {
      final ({GameState state, Person partner}) v = sevgiliyle(wallet: 0);
      expect(evlilik.marryBlockReason(v.state, v.partner), isEmpty);
      expect(evlilik.proposeBlockReason(v.state, v.partner), isEmpty);
    });

    test('bedelsiz teklif cüzdana dokunmaz', () {
      final ({GameState state, Person partner}) v = sevgiliyle(wallet: 500);
      final GameState sonra =
          evlilik.propose(v.state, v.partner.id, Random(1)).state;
      expect(sonra.player.wallet, 500);
    });

    test('hazırlıklı teklifin masrafı reddedilse de ödenir', () {
      // Ayrılan masa, alınan bilet "hayır" denince geri gelmez.
      final ({GameState state, Person partner}) v =
          sevgiliyle(wallet: 100000, bond: 62);
      final ProposalStyle stil = proposalStyleById('tatil')!;
      bool retGoruldu = false;
      for (int seed = 0; seed < 60; seed++) {
        final GameState sonra = evlilik
            .propose(v.state, v.partner.id, Random(seed), styleId: 'tatil')
            .state;
        expect(sonra.player.wallet, 100000 - stil.prototypeOnlyCost);
        if (!sonra.hasPendingWedding) retGoruldu = true;
      }
      expect(retGoruldu, isTrue, reason: 'Ret hiç görülmedi');
    });

    test('parası yetmeyen hazırlık seçilemez ama sade teklif açık kalır', () {
      final ({GameState state, Person partner}) v = sevgiliyle(wallet: 100);
      final FamilyResult r = evlilik
          .propose(v.state, v.partner.id, Random(1), styleId: 'tatil');
      expect(r.outcome.applied, isFalse);
      expect(r.outcome.text, contains('yeterli para yok'));
      expect(
        evlilik.propose(v.state, v.partner.id, Random(1)).outcome.applied,
        isTrue,
      );
    });

    test('hazırlık kabul ihtimalini artırır', () {
      final ({GameState state, Person partner}) v = sevgiliyle(bond: 62);
      int sade = 0;
      int tatil = 0;
      for (int seed = 0; seed < 80; seed++) {
        final GameState zengin = v.state.copyWith(
          player: v.state.player.copyWith(wallet: 100000),
        );
        if (evlilik
            .propose(zengin, v.partner.id, Random(seed))
            .state
            .hasPendingWedding) {
          sade++;
        }
        if (evlilik
            .propose(zengin, v.partner.id, Random(seed), styleId: 'tatil')
            .state
            .hasPendingWedding) {
          tatil++;
        }
      }
      expect(tatil, greaterThan(sade));
    });
  });

  group('Düğün cüzdana göre seçilir', () {
    test('katalogda her zaman bedelsiz bir düğün vardır', () {
      // Bu kural **kalıcıdır**: yoksa "evet" almış oyuncu evlenemeden
      // kalır.
      expect(kWeddingStyles.any((WeddingStyle s) => s.isFree), isTrue);
      expect(kProposalStyles.any((ProposalStyle s) => s.isFree), isTrue);
    });

    test('cüzdanı boş oyuncuya da en az bir düğün açıktır', () {
      expect(PendingWeddingOptions.forWallet(0), isNotEmpty);
    });

    test('kabul edilen teklif evliliği hemen kurmaz', () {
      final ({GameState state, Person partner}) v = sevgiliyle();
      final GameState kabul = kabulEttir(v.state, v.partner.id);
      expect(kabul.hasPendingWedding, isTrue);
      expect(kabul.isMarried, isFalse,
          reason: 'Evlilik düğünle kurulur (Paket 25)');
      expect(kabul.pendingWedding!.spouseId, v.partner.id);
    });

    test('bedelsiz düğünle parasız oyuncu evlenir', () {
      final ({GameState state, Person partner}) v = sevgiliyle(wallet: 0);
      final GameState kabul = kabulEttir(v.state, v.partner.id);
      final FamilyResult dugun =
          evlilik.holdWedding(kabul, kFreeWedding.id);
      expect(dugun.outcome.applied, isTrue);
      expect(dugun.state.isMarried, isTrue);
      expect(dugun.state.player.wallet, 0);
      expect(dugun.state.hasPendingWedding, isFalse);
      expect(dugun.state.spouse!.id, v.partner.id,
          reason: 'Aynı kimlik eş olur, yeni kişi üretilmez');
    });

    test('pahalı düğün parası yoksa seçilemez', () {
      final ({GameState state, Person partner}) v = sevgiliyle(wallet: 1000);
      final GameState kabul = kabulEttir(v.state, v.partner.id);
      final FamilyResult r = evlilik.holdWedding(kabul, 'salon');
      expect(r.outcome.applied, isFalse);
      expect(r.state.isMarried, isFalse);
      expect(r.state.hasPendingWedding, isTrue,
          reason: '"Evet" kaybolmaz; başka düğün seçilebilir');
    });

    test('seçilen düğünün masrafı bir kez düşer', () {
      // 2026 kalibrasyonu: salon düğünü 90.000 ₺'den 380.000 ₺'ye çıktı.
      // Cüzdan fixture'ı ölçeğe çekildi; iddia aynen duruyor.
      final ({GameState state, Person partner}) v =
          sevgiliyle(wallet: 600000);
      final GameState kabul = kabulEttir(v.state, v.partner.id);
      final WeddingStyle salon = weddingStyleById('salon')!;
      final GameState evli = evlilik.holdWedding(kabul, 'salon').state;
      expect(
        evli.player.wallet,
        kabul.player.wallet - salon.prototypeOnlyCost,
      );
      expect(evli.movedOut, isTrue);
    });

    test('bekleyen düğün kayda girer ve kapat-aç ile korunur', () {
      final ({GameState state, Person partner}) v = sevgiliyle();
      final GameState kabul = kabulEttir(v.state, v.partner.id);
      final GameState geri = decodeGameState(encodeGameState(kabul));
      expect(geri.hasPendingWedding, isTrue);
      expect(geri.pendingWedding!.spouseId, v.partner.id);
      expect(geri.pendingWedding!.acceptedAtAge,
          kabul.pendingWedding!.acceptedAtAge);
    });
  });

  group('Yakınlaşma ve gebelik', () {
    test('korunulursa çocuk olmaz', () {
      final ({GameState state, Person partner}) v = sevgiliyle();
      GameState akan = v.state;
      for (int i = 0; i < 40; i++) {
        akan = yakinlasma
            .perform(akan, v.partner.id, Protection.korunarak, Random(i))
            .state;
        akan = akan.copyWith(
          player: akan.player.copyWith(age: akan.player.age + 1),
        );
      }
      expect(akan.children, isEmpty);
      expect(akan.isExpecting, isFalse);
    });

    test('korunmazsa hamilelik bir ihtimaldir, garanti değil', () {
      int hamile = 0;
      const int n = 40;
      for (int seed = 0; seed < n; seed++) {
        final ({GameState state, Person partner}) v = sevgiliyle(seed: seed);
        final GameState sonra = yakinlasma
            .perform(v.state, v.partner.id, Protection.korunmadan, Random(seed))
            .state;
        // Bebek **hemen** gelmez; hamilelik başlar (Paket 26).
        expect(sonra.children, isEmpty);
        if (sonra.isExpecting) hamile++;
      }
      expect(hamile, greaterThan(0), reason: 'Hiç hamilelik olmuyor');
      expect(hamile, lessThan(n), reason: 'Her seferinde hamile kalınıyor');
    });

    test('kısır çiftte çocuk hiç olmaz', () {
      final ({GameState state, Person partner}) v =
          sevgiliyle(partnerKisir: true);
      expect(Intimacy.conceptionChance(v.state, v.partner), 0);
      GameState akan = v.state;
      for (int i = 0; i < 40; i++) {
        akan = yakinlasma
            .perform(akan, v.partner.id, Protection.korunmadan, Random(i))
            .state;
        akan = akan.copyWith(
          player: akan.player.copyWith(age: akan.player.age + 1),
        );
      }
      expect(akan.children, isEmpty);
    });

    test('uzun süre olmayınca oyuncuya söylenir', () {
      final ({GameState state, Person partner}) v =
          sevgiliyle(oyuncuKisir: true);
      GameState akan = v.state;
      String son = '';
      for (int i = 0; i < Intimacy.prototypeOnlyWorryAfter; i++) {
        final FamilyResult r = yakinlasma.perform(
          akan,
          v.partner.id,
          Protection.korunmadan,
          Random(i),
        );
        akan = r.state;
        son = r.outcome.text;
        akan = akan.copyWith(
          player: akan.player.copyWith(age: akan.player.age + 1),
        );
      }
      expect(son, contains('hekime'));
      // Kısırlık **açıkça söylenmez**; yalnızca olmadığı söylenir.
      expect(son, isNot(contains('kısır')));
    });

    test('aynı yıl ikinci deneme ihtimali katlamaz', () {
      final ({GameState state, Person partner}) v = sevgiliyle();
      final GameState ilk = yakinlasma
          .perform(v.state, v.partner.id, Protection.korunmadan, Random(0))
          .state;
      expect(ilk.lastConceptionTryAge, v.state.player.age);
      final FamilyResult ikinci = yakinlasma.perform(
        ilk,
        v.partner.id,
        Protection.korunmadan,
        Random(0),
      );
      expect(ikinci.outcome.text, contains('zaten denediniz'));
    });

    test('kadının yaşı ilerledikçe ihtimal düşer', () {
      expect(
        Intimacy.prototypeOnlyAgeFactor(40),
        lessThan(Intimacy.prototypeOnlyAgeFactor(25)),
      );
      expect(Intimacy.prototypeOnlyAgeFactor(50), 0);
    });

    test('yakınlaşma bir temastır; ilgisizlik sayacını sıfırlar', () {
      final ({GameState state, Person partner}) v = sevgiliyle();
      final GameState eski = v.state.copyWith(
        lastInteractionAge: <String, int>{v.partner.id: 5},
      );
      final GameState sonra = yakinlasma
          .perform(eski, v.partner.id, Protection.korunarak, Random(1))
          .state;
      expect(sonra.lastInteractionAge[v.partner.id], sonra.player.age);
    });

    test('çocuk olunca masraf cüzdanda ne varsa o kadar düşer', () {
      // "Paran yok, o yüzden hamile kalmadın" diye bir şey yok.
      final ({GameState state, Person partner}) v = sevgiliyle(wallet: 500);
      final GameState akan = dogumaKadar(v.state, v.partner.id);
      expect(akan.children, isNotEmpty, reason: 'Hiç çocuk olmadı');
      expect(akan.player.wallet, 0, reason: 'Bakiye eksiye inmez');
    });

    test('hamile kalınca deneme sayacı sıfırlanır', () {
      final ({GameState state, Person partner}) v = sevgiliyle();
      GameState akan = v.state.copyWith(unprotectedTries: 3);
      for (int i = 0; i < 40 && !akan.isExpecting; i++) {
        akan = yakinlasma
            .perform(akan, v.partner.id, Protection.korunmadan, Random(i))
            .state;
        if (akan.isExpecting) break;
        akan = akan.copyWith(
          player: akan.player.copyWith(age: akan.player.age + 1),
        );
      }
      expect(akan.isExpecting, isTrue);
      expect(akan.unprotectedTries, 0);
    });

    test('çocuk sahibi olmak için ayrı bir düğme kalmadı', () {
      // Yakınlaşma yalnızca eş ve sevgiliye açıktır.
      final ({GameState state, Person partner}) v = sevgiliyle();
      final Person anne = v.state.people
          .firstWhere((Person p) => p.relation == RelationType.anne);
      expect(Intimacy.blockReason(v.state, anne), isNotEmpty);
    });

    test('çocuk yaşı ve sayısı sınırları korunur', () {
      final ({GameState state, Person partner}) v = sevgiliyle(age: 16);
      expect(Intimacy.blockReason(v.state, v.partner), isNotEmpty);
    });
  });

  group('Doğurganlık gizlidir ve kayda girer', () {
    test('kısırlık bazı hayatlarda çıkar, hepsinde değil', () {
      int kisir = 0;
      const int n = 200;
      for (int seed = 0; seed < n; seed++) {
        final GameState s =
            LifeGenerator.seeded(seed).generate(mode: StartMode.tamamenRastgele);
        if (s.player.infertile) kisir++;
      }
      expect(kisir, greaterThan(0));
      expect(kisir, lessThan(n ~/ 3));
    });

    test('doğurganlık kayda girer ve kapat-aç ile korunur', () {
      final ({GameState state, Person partner}) v =
          sevgiliyle(oyuncuKisir: true, partnerKisir: true);
      final GameState geri = decodeGameState(encodeGameState(v.state));
      expect(geri.player.infertile, isTrue);
      expect(geri.personById(v.partner.id)!.infertile, isTrue);
    });

    test('eski kayıtta kimse kısır sayılmaz', () {
      final ({GameState state, Person partner}) v = sevgiliyle();
      final Map<String, Object?> body =
          Map<String, Object?>.from(encodeGameState(v.state));
      final Map<String, Object?> oyuncu =
          Map<String, Object?>.from(body['player']! as Map<String, Object?>)
            ..remove('infertile');
      body['player'] = oyuncu;
      body['people'] = <Object?>[
        for (final Object? p in body['people']! as List<Object?>)
          Map<String, Object?>.from(p! as Map<String, Object?>)
            ..remove('infertile'),
      ];
      final GameState geri =
          decodeGameState(SaveMigrations.migrate(body, 28));
      expect(geri.player.infertile, isFalse);
      expect(geri.people.every((Person p) => !p.infertile), isTrue);
    });

    test('kayıt sürümü 30 ve beş sürümlük pencere korunur', () {
      expect(kSaveFormatVersion, 30);
      expect(kSaveFormatVersion - kMinReadableSaveVersion, 5);
    });
  });
}

/// Cüzdana göre düğün seçenekleri (testte okunaklı olsun diye).
abstract final class PendingWeddingOptions {
  static List<WeddingStyle> forWallet(int wallet) => kWeddingStyles
      .where((WeddingStyle s) => s.prototypeOnlyCost <= wallet)
      .toList(growable: false);
}

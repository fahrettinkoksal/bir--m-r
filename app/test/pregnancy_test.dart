import 'dart:math';

import 'package:bir_omur/data/save/game_state_codec.dart';
import 'package:bir_omur/data/save/save_format.dart';
import 'package:bir_omur/domain/generation/life_generator.dart';
import 'package:bir_omur/domain/generation/life_progression.dart';
import 'package:bir_omur/domain/interaction/intimacy.dart';
import 'package:bir_omur/domain/interaction/romance.dart';
import 'package:bir_omur/domain/models/game_state.dart';
import 'package:bir_omur/domain/models/gender.dart';
import 'package:bir_omur/domain/models/pending_notice.dart';
import 'package:bir_omur/domain/models/person.dart';
import 'package:bir_omur/domain/models/pregnancy.dart';
import 'package:bir_omur/domain/models/relation.dart';
import 'package:flutter_test/flutter_test.dart';

const IntimacyEngine yakinlasma = IntimacyEngine();

({GameState state, Person partner}) cift({
  int seed = 7,
  int age = 28,
  Gender? oyuncuCinsiyeti,
}) {
  GameState base =
      LifeGenerator.seeded(seed).generate(mode: StartMode.tamamenRastgele);
  if (oyuncuCinsiyeti != null &&
      base.player.gender != oyuncuCinsiyeti) {
    // Cinsiyet kalıcıdır; istenen cinsiyette bir tohum bulunur.
    for (int s2 = 0; s2 < 60; s2++) {
      final GameState aday =
          LifeGenerator.seeded(s2).generate(mode: StartMode.tamamenRastgele);
      if (aday.player.gender == oyuncuCinsiyeti) {
        base = aday;
        break;
      }
    }
  }
  final ({GameState state, Person partner}) r = const Romance().start(
    base.copyWith(player: base.player.copyWith(age: age, wallet: 100000)),
    Random(seed),
  );
  final GameState state = r.state.copyWith(
    pendingEvent: null,
    people: r.state.people
        .map((Person p) =>
            p.id == r.partner.id ? p.copyWith(bond: 85, age: age) : p)
        .toList(growable: false),
  );
  return (state: state, partner: state.personById(r.partner.id)!);
}

/// Hamile kalana kadar korunmadan dener.
GameState hamileKal(GameState state, String partnerId) {
  GameState akan = state;
  for (int i = 0; i < 60 && !akan.isExpecting; i++) {
    akan = yakinlasma
        .perform(akan, partnerId, Protection.korunmadan, Random(i))
        .state;
    if (akan.isExpecting) break;
    akan = akan.copyWith(
      player: akan.player.copyWith(age: akan.player.age + 1),
    );
  }
  return akan;
}

void main() {
  group('Hamilelik bir süreçtir (Paket 26)', () {
    test('korunmadan yakınlaşma bebeği hemen getirmez', () {
      final ({GameState state, Person partner}) v = cift();
      final GameState hamile = hamileKal(v.state, v.partner.id);
      expect(hamile.isExpecting, isTrue, reason: 'Hiç hamile kalınmadı');
      expect(hamile.children, isEmpty,
          reason: 'Bebek hamilelik biter bitmez değil, sonraki yaşta doğar');
      expect(hamile.pregnancy!.partnerId, v.partner.id);
      expect(hamile.pregnancy!.startedAtAge, hamile.player.age);
    });

    test('bebek bir sonraki yaş ilerlemesinde doğar', () {
      final ({GameState state, Person partner}) v = cift();
      final GameState hamile = hamileKal(v.state, v.partner.id);
      final GameState sonra =
          LifeProgression(Random(3)).advanceOneYear(hamile);

      expect(sonra.children, hasLength(1));
      expect(sonra.isExpecting, isFalse, reason: 'Hamilelik kapanır');
      expect(sonra.children.single.age, 0);
    });

    test('doğum ekranda bildirimle duyurulur', () {
      final ({GameState state, Person partner}) v = cift();
      final GameState sonra = LifeProgression(Random(3))
          .advanceOneYear(hamileKal(v.state, v.partner.id));
      final Iterable<PendingNotice> dogum = sonra.notices
          .where((PendingNotice n) => n.kind == NoticeKind.dogum);
      expect(dogum, hasLength(1));
      expect(dogum.single.personId, sonra.children.single.id);
      expect(dogum.single.text, contains(sonra.children.single.firstName));
    });

    test('hamileyken ikinci gebelik başlamaz', () {
      final ({GameState state, Person partner}) v = cift();
      final GameState hamile = hamileKal(v.state, v.partner.id);
      expect(Intimacy.canConceiveThisYear(hamile), isFalse);

      GameState akan = hamile;
      for (int i = 0; i < 5; i++) {
        akan = akan.copyWith(
          player: akan.player.copyWith(age: akan.player.age + 1),
        );
        akan = yakinlasma
            .perform(akan, v.partner.id, Protection.korunmadan, Random(i))
            .state;
      }
      expect(akan.pregnancy!.startedAtAge, hamile.pregnancy!.startedAtAge,
          reason: 'Aynı hamilelik sürer, üstüne yenisi yazılmaz');
    });

    test('bebeğin diğer ebeveyni hamilelik kaydındaki kişidir', () {
      // Bekleme sırasında ayrılık olsa bile bebek başkasının çocuğu
      // olmaz.
      final ({GameState state, Person partner}) v = cift();
      final GameState hamile = hamileKal(v.state, v.partner.id);
      final GameState ayrildi = const Romance().end(hamile, v.partner.id);
      final GameState sonra =
          LifeProgression(Random(3)).advanceOneYear(ayrildi);

      expect(sonra.children, hasLength(1));
      expect(
        sonra.personById(v.partner.id)!.relation,
        RelationType.eskiSevgili,
      );
    });

    test('diğer ebeveyn vefat ederse doğum olmaz ama günlüğe yazılır', () {
      final ({GameState state, Person partner}) v = cift();
      final GameState hamile = hamileKal(v.state, v.partner.id);
      final GameState olu = hamile.copyWith(
        people: hamile.people
            .map((Person p) =>
                p.id == v.partner.id ? p.copyWith(isAlive: false) : p)
            .toList(growable: false),
      );
      final GameState sonra = LifeProgression(Random(3)).advanceOneYear(olu);
      expect(sonra.children, isEmpty);
      expect(sonra.isExpecting, isFalse);
      expect(
        sonra.log.any((dynamic e) =>
            (e.text as String).contains('dünyaya gelemedi')),
        isTrue,
        reason: 'Bekleyen bebek sessizce kaybolmaz',
      );
    });

    test('hamilelik kayda girer ve kapat-aç ile korunur', () {
      final ({GameState state, Person partner}) v = cift();
      final GameState hamile = hamileKal(v.state, v.partner.id);
      final GameState geri = decodeGameState(encodeGameState(hamile));
      expect(geri.isExpecting, isTrue);
      expect(geri.pregnancy!.partnerId, hamile.pregnancy!.partnerId);
      expect(geri.pregnancy!.startedAtAge, hamile.pregnancy!.startedAtAge);
      expect(geri.pregnancy!.expecting, hamile.pregnancy!.expecting);
    });

    test('kadın oyuncuda hamile olan taraf oyuncudur', () {
      final ({GameState state, Person partner}) v =
          cift(oyuncuCinsiyeti: Gender.kadin);
      expect(v.state.player.gender, Gender.kadin);
      expect(Intimacy.expectingSide(v.state), ExpectingParty.oyuncu);
    });

    test('erkek oyuncuda hamile olan taraf partnerdir', () {
      final ({GameState state, Person partner}) v =
          cift(oyuncuCinsiyeti: Gender.erkek);
      expect(v.state.player.gender, Gender.erkek);
      expect(Intimacy.expectingSide(v.state), ExpectingParty.partner);
    });

    test('korunulursa hiç hamilelik olmaz', () {
      final ({GameState state, Person partner}) v = cift();
      GameState akan = v.state;
      for (int i = 0; i < 40; i++) {
        akan = yakinlasma
            .perform(akan, v.partner.id, Protection.korunarak, Random(i))
            .state;
        akan = akan.copyWith(
          player: akan.player.copyWith(age: akan.player.age + 1),
        );
      }
      expect(akan.isExpecting, isFalse);
      expect(akan.children, isEmpty);
    });

    test('eski kayıtta bekleyen bebek yoktur', () {
      final ({GameState state, Person partner}) v = cift();
      final Map<String, Object?> body =
          Map<String, Object?>.from(encodeGameState(v.state))
            ..remove('pregnancy');
      final GameState geri =
          decodeGameState(SaveMigrations.migrate(body, 29));
      expect(geri.isExpecting, isFalse);
    });

    test('kayıt sürümü 30 ve beş sürümlük pencere korunur', () {
      expect(kSaveFormatVersion, 30);
      expect(kSaveFormatVersion - kMinReadableSaveVersion, 5);
    });
  });

  group('Sınırlar hamilelikte de geçerli', () {
    test('en fazla çocuk sayısına ulaşınca hamilelik başlamaz', () {
      final ({GameState state, Person partner}) v = cift();
      GameState akan = v.state;
      // Sınıra kadar doğur.
      for (int tur = 0; tur < 30; tur++) {
        if (akan.children.length >= 4) break;
        akan = hamileKal(akan, v.partner.id);
        if (!akan.isExpecting) break;
        akan = LifeProgression(Random(tur)).advanceOneYear(akan);
        akan = akan.copyWith(pendingEvent: null);
        if (akan.deceased) break;
      }
      if (akan.children.length < 4) return;

      final GameState dolu = akan.copyWith(
        lastConceptionTryAge: null,
        player: akan.player.copyWith(age: akan.player.age + 1),
      );
      final GameState deneme = yakinlasma
          .perform(dolu, v.partner.id, Protection.korunmadan, Random(1))
          .state;
      expect(deneme.isExpecting, isFalse);
    });
  });
}

/// Ünlülerle temas (Faho'nun isteği).
///
/// En önemli iddia: **ret gerçektir**. Karşılık garanti değildir, büyük
/// isme yazmak zordur ve ısrar işe yaramaz.
library;

import 'dart:convert';
import 'dart:math';

import 'package:bir_omur/data/celebrity_catalog.dart';
import 'package:bir_omur/domain/models/gender.dart';
import 'package:bir_omur/data/save/game_state_codec.dart';
import 'package:bir_omur/data/social_catalog.dart';
import 'package:bir_omur/domain/generation/life_generator.dart';
import 'package:bir_omur/domain/models/celebrity_contact.dart';
import 'package:bir_omur/domain/models/game_state.dart';
import 'package:bir_omur/domain/models/person.dart';
import 'package:bir_omur/domain/models/relation.dart';
import 'package:bir_omur/domain/models/social_account.dart';
import 'package:bir_omur/domain/social/celebrity_engine.dart';
import 'package:bir_omur/domain/social/social_engine.dart';
import 'package:flutter_test/flutter_test.dart';

const SocialEngine social = SocialEngine();

GameState hayat({int age = 25, int charisma = 60, int? fame}) {
  final GameState taban = LifeGenerator.seeded(
    21,
  ).generate(mode: StartMode.tamamenRastgele);
  return taban.copyWith(
    pendingEvent: null,
    player: taban.player.copyWith(
      age: age,
      fame: fame,
      stats: taban.player.stats.copyWith(charisma: charisma),
    ),
  );
}

/// Bu platformda belirli takipçili bir hesap açar.
GameState hesapli(GameState s, SocialPlatform platform, int takipci) {
  final GameState acik = social.openAccount(s, platform).state;
  return acik.copyWith(
    socialAccounts: List<SocialAccount>.unmodifiable(
      acik.socialAccounts
          .map(
            (SocialAccount a) =>
                a.platform == platform ? a.copyWith(followers: takipci) : a,
          )
          .toList(growable: false),
    ),
  );
}

Celebrity unlu(String id) => celebrityById(id)!;

void main() {
  group('Katalog', () {
    test('ünlü kimlikleri benzersiz', () {
      final Set<String> gorulen = <String>{};
      for (final Celebrity c in kCelebrities) {
        expect(gorulen.add(c.id), isTrue, reason: 'Tekrar eden: ${c.id}');
      }
    });

    test('her platformda en az bir ünlü var', () {
      // Sessiz hata sınıfı: ünlüsü olmayan platformda bölüm hiç
      // görünmez ve oyuncu neyi kaçırdığını bilmez.
      for (final SocialPlatform p in SocialPlatform.values) {
        expect(
          celebritiesOn(p),
          isNotEmpty,
          reason: '${p.label} için ünlü yazılmamış',
        );
      }
    });

    test('ulaşılabilirlik ve eşikler makul aralıkta', () {
      for (final Celebrity c in kCelebrities) {
        expect(c.prototypeOnlyApproachability, greaterThan(0), reason: c.id);
        expect(c.prototypeOnlyApproachability, lessThan(1), reason: c.id);
        expect(c.prototypeOnlyNoticeThreshold, greaterThan(0), reason: c.id);
        expect(c.followers, greaterThan(0), reason: c.id);
      }
    });

    test('büyük isim küçük isimden daha zor ulaşılır', () {
      final Celebrity kucuk = unlu('tolga_esmer');
      final Celebrity buyuk = unlu('yasemin_korkut');
      expect(buyuk.followers, greaterThan(kucuk.followers));
      expect(
        buyuk.prototypeOnlyApproachability,
        lessThan(kucuk.prototypeOnlyApproachability),
      );
      expect(
        buyuk.prototypeOnlyNoticeThreshold,
        greaterThan(kucuk.prototypeOnlyNoticeThreshold),
      );
    });

    test('her ünlünün cinsiyeti katalogda yazılı', () {
      // Cinsiyet eskiden addan tahmin ediliyordu; ünlü adları genel
      // isim havuzunda olmadığı için **hepsi erkek** üretiliyordu.
      // Artık katalogda yazılı ve iki cinsiyet de temsil ediliyor.
      final Set<Gender> gorulen = kCelebrities
          .map((Celebrity c) => c.gender)
          .toSet();
      expect(gorulen, containsAll(<Gender>[Gender.kadin, Gender.erkek]));
    });

    test('kişi kaydı katalogdaki cinsiyetle açılıyor', () {
      for (final Celebrity c in kCelebrities) {
        GameState s = hesapli(
          hayat(charisma: 95, fame: 90),
          c.platform,
          5000000,
        );
        s = s.copyWith(
          celebrityContacts: <CelebrityContact>[
            CelebrityContact(
              celebrityId: c.id,
              attempts: 1,
              replied: true,
              followsBack: true,
            ),
          ],
        );
        bool bulundu = false;
        for (int seed = 0; seed < 40 && !bulundu; seed++) {
          final CelebrityResult r = CelebrityEngine.contact(
            state: s,
            celebrity: c,
            action: CelebrityAction.mesaj,
            rng: Random(seed),
          );
          for (final Person p in r.state.people) {
            if (p.id != 'unlu-${c.id}') continue;
            expect(p.gender, c.gender, reason: c.id);
            bulundu = true;
            break;
          }
        }
        expect(bulundu, isTrue, reason: '${c.id} kişi kaydı açılmadı');
      }
    });
  });

  group('Uygunluk', () {
    test('hesabı olmayan temas kuramaz, gerekçesi yazılı', () {
      final Celebrity c = unlu('derya_akkoyun');
      final GameState s = hayat();
      final String engel = CelebrityEngine.blockReason(
        s,
        c,
        CelebrityAction.mesaj,
      );
      expect(engel, isNotEmpty);
      expect(engel, contains(c.platform.label));
    });

    test('yılda en fazla iki kez yazılabilir (Q-115 kararı)', () {
      final Celebrity c = unlu('tolga_esmer');
      GameState s = hesapli(hayat(), c.platform, 5000);

      // İlk iki deneme açık.
      for (int i = 0; i < CelebrityEngine.prototypeOnlyTriesPerAge; i++) {
        expect(
          CelebrityEngine.blockReason(s, c, CelebrityAction.mesaj),
          isEmpty,
          reason: '${i + 1}. deneme açık olmalı',
        );
        s = CelebrityEngine.contact(
          state: s,
          celebrity: c,
          action: CelebrityAction.mesaj,
          rng: Random(i + 1),
        ).state;
      }

      final String engel = CelebrityEngine.blockReason(
        s,
        c,
        CelebrityAction.mesaj,
      );
      expect(engel, isNotEmpty);
      expect(engel, contains('yıllık hakkın'));
    });

    test('yaş ilerleyince yeniden yazılabilir', () {
      final Celebrity c = unlu('tolga_esmer');
      GameState s = hesapli(hayat(), c.platform, 5000);
      s = CelebrityEngine.contact(
        state: s,
        celebrity: c,
        action: CelebrityAction.mesaj,
        rng: Random(1),
      ).state;
      // Yaş sayaçları yeni yaşta sıfırlanır (D-023).
      s = s.copyWith(interactionCounts: const <String, int>{});
      expect(CelebrityEngine.blockReason(s, c, CelebrityAction.mesaj), isEmpty);
    });

    test('iş birliği Ün ve önceki cevap ister', () {
      final Celebrity c = unlu('tolga_esmer');
      final GameState unsuz = hesapli(hayat(), c.platform, 5000);
      expect(
        CelebrityEngine.blockReason(unsuz, c, CelebrityAction.isBirligi),
        contains('Ün'),
      );

      final GameState unlu50 = hesapli(hayat(fame: 50), c.platform, 5000);
      expect(
        CelebrityEngine.blockReason(unlu50, c, CelebrityAction.isBirligi),
        contains('tanımıyor'),
      );
    });
  });

  group('Karşılık ihtimali', () {
    test('kitlesi olmayanın ihtimali sıfıra yakın', () {
      final Celebrity c = unlu('yasemin_korkut');
      final GameState s = hesapli(hayat(charisma: 10), c.platform, 0);
      expect(
        CelebrityEngine.replyChance(s, c, CelebrityAction.mesaj),
        lessThan(0.15),
      );
    });

    test('kitle büyüdükçe ihtimal artar', () {
      final Celebrity c = unlu('derya_akkoyun');
      final GameState az = hesapli(hayat(), c.platform, 100);
      final GameState cok = hesapli(hayat(), c.platform, 100000);
      expect(
        CelebrityEngine.replyChance(cok, c, CelebrityAction.mesaj),
        greaterThan(CelebrityEngine.replyChance(az, c, CelebrityAction.mesaj)),
      );
    });

    test('hiçbir zaman garanti değil', () {
      final Celebrity c = unlu('tolga_esmer');
      final GameState s = hesapli(
        hayat(charisma: 100, fame: 100),
        c.platform,
        10000000,
      );
      expect(
        CelebrityEngine.replyChance(s, c, CelebrityAction.mesaj),
        lessThanOrEqualTo(CelebrityEngine.prototypeOnlyMaxChance),
      );
      expect(
        CelebrityEngine.replyChance(s, c, CelebrityAction.mesaj),
        lessThan(1.0),
      );
    });

    test('ısrar ihtimali düşürür', () {
      final Celebrity c = unlu('tolga_esmer');
      final GameState temiz = hesapli(hayat(), c.platform, 5000);
      final double ilk = CelebrityEngine.replyChance(
        temiz,
        c,
        CelebrityAction.mesaj,
      );

      final GameState israrci = temiz.copyWith(
        celebrityContacts: <CelebrityContact>[
          CelebrityContact(celebrityId: c.id, attempts: 4),
        ],
      );
      expect(
        CelebrityEngine.replyChance(israrci, c, CelebrityAction.mesaj),
        lessThan(ilk),
      );
    });

    test('yorum mesajdan zayıf', () {
      final Celebrity c = unlu('bora_yetkin');
      final GameState s = hesapli(hayat(), c.platform, 5000);
      expect(
        CelebrityEngine.replyChance(s, c, CelebrityAction.yorum),
        lessThan(CelebrityEngine.replyChance(s, c, CelebrityAction.mesaj)),
      );
    });
  });

  group('Sonuç gerçekten uygulanıyor', () {
    test('çoğu deneme karşılıksız kalır', () {
      // Ret gerçek: küçük kitleli oyuncu büyük isme yazınca çoğunlukla
      // görülmez.
      final Celebrity c = unlu('yasemin_korkut');
      final GameState s = hesapli(hayat(charisma: 40), c.platform, 500);
      int gorulmedi = 0;
      for (int seed = 0; seed < 50; seed++) {
        final CelebrityResult r = CelebrityEngine.contact(
          state: s,
          celebrity: c,
          action: CelebrityAction.mesaj,
          rng: Random(seed),
        );
        if (r.kind == CelebrityOutcomeKind.gorulmedi) gorulmedi++;
      }
      expect(
        gorulmedi,
        greaterThan(35),
        reason: 'Büyük isme yazmak kolay olmamalı ($gorulmedi/50)',
      );
    });

    test('karşılık gelince takipçi gerçekten artar', () {
      final Celebrity c = unlu('tolga_esmer');
      final GameState s = hesapli(
        hayat(charisma: 95, fame: 60),
        c.platform,
        200000,
      );
      for (int seed = 0; seed < 60; seed++) {
        final CelebrityResult r = CelebrityEngine.contact(
          state: s,
          celebrity: c,
          action: CelebrityAction.mesaj,
          rng: Random(seed),
        );
        if (r.kind == CelebrityOutcomeKind.gorulmedi) continue;
        expect(r.followerDelta, greaterThan(0));
        expect(
          r.state.accountFor(c.platform)!.followers,
          s.accountFor(c.platform)!.followers + r.followerDelta,
        );
        return;
      }
      fail('Hiç karşılık gelmedi');
    });

    test('geri takip edince ünlü kalıcı kişi oluyor', () {
      final Celebrity c = unlu('tolga_esmer');
      final GameState s = hesapli(
        hayat(charisma: 95, fame: 80),
        c.platform,
        500000,
      );
      for (int seed = 0; seed < 80; seed++) {
        final CelebrityResult r = CelebrityEngine.contact(
          state: s,
          celebrity: c,
          action: CelebrityAction.mesaj,
          rng: Random(seed),
        );
        if (r.kind != CelebrityOutcomeKind.geriTakip) continue;
        final Person kisi = r.state.people.firstWhere(
          (Person p) => p.relation == RelationType.unlu,
        );
        expect(kisi.firstName, c.firstName);
        expect(kisi.lastName, c.lastName);
        expect(kisi.isAlive, isTrue);
        expect(kisi.inPlayerHousehold, isFalse);
        return;
      }
      fail('Hiç geri takip gelmedi');
    });

    test('karşılık alınmamışsa kişi kaydı açılmaz', () {
      // Ünlü kataloğu kalabalık; tanışılmamış kimse İlişkiler ekranına
      // girmemeli.
      final Celebrity c = unlu('yasemin_korkut');
      final GameState s = hesapli(hayat(charisma: 30), c.platform, 100);
      final CelebrityResult r = CelebrityEngine.contact(
        state: s,
        celebrity: c,
        action: CelebrityAction.mesaj,
        rng: Random(7),
      );
      if (r.kind == CelebrityOutcomeKind.gorulmedi) {
        expect(
          r.state.people.where((Person p) => p.relation == RelationType.unlu),
          isEmpty,
        );
      }
    });

    test('deneme kaydı tutuluyor', () {
      final Celebrity c = unlu('tolga_esmer');
      GameState s = hesapli(hayat(), c.platform, 5000);
      s = CelebrityEngine.contact(
        state: s,
        celebrity: c,
        action: CelebrityAction.mesaj,
        rng: Random(3),
      ).state;
      final CelebrityContact? temas = s.contactWith(c.id);
      expect(temas, isNotNull);
      expect(temas!.attempts, 1);
      expect(temas.firstContactAge, 25);
      expect(temas.lastContactAge, 25);
    });

    test('engellenen temas hiçbir şeyi değiştirmez', () {
      final Celebrity c = unlu('derya_akkoyun');
      final GameState s = hayat();
      final CelebrityResult r = CelebrityEngine.contact(
        state: s,
        celebrity: c,
        action: CelebrityAction.mesaj,
        rng: Random(1),
      );
      expect(r.applied, isFalse);
      expect(r.state.celebrityContacts, isEmpty);
      expect(r.state.people.length, s.people.length);
    });
  });

  group('Kayıt', () {
    test('ünlü teması kapat-aç ile korunuyor', () {
      final Celebrity c = unlu('tolga_esmer');
      GameState s = hesapli(hayat(), c.platform, 5000);
      s = CelebrityEngine.contact(
        state: s,
        celebrity: c,
        action: CelebrityAction.mesaj,
        rng: Random(3),
      ).state;

      final GameState geri = decodeGameState(encodeGameState(s));
      expect(geri.contactWith(c.id)?.attempts, 1);
      expect(jsonEncode(encodeGameState(geri)), jsonEncode(encodeGameState(s)));
    });

    test('eski kayıtta alan yoksa boş listeyle açılıyor', () {
      // Kayıt sürümü değişmedi; alan isteğe bağlı okunuyor.
      final Map<String, Object?> json = encodeGameState(hayat());
      json.remove('celebrityContacts');
      final GameState geri = decodeGameState(json);
      expect(geri.celebrityContacts, isEmpty);
      expect(() => encodeGameState(geri), returnsNormally);
    });
  });
}

import 'dart:convert';
import 'dart:math';

import 'package:bir_omur/data/save/game_state_codec.dart';
import 'package:bir_omur/data/save/save_format.dart';
import 'package:bir_omur/data/save/save_service.dart';
import 'package:bir_omur/data/save/save_store.dart';
import 'package:bir_omur/data/social_catalog.dart';
import 'package:bir_omur/domain/generation/life_generator.dart';
import 'package:bir_omur/domain/models/applied_effect.dart';
import 'package:bir_omur/domain/models/game_state.dart';
import 'package:bir_omur/domain/models/social_account.dart';
import 'package:bir_omur/domain/social/social_engine.dart';
import 'package:bir_omur/state/game_controller.dart';
import 'package:flutter_test/flutter_test.dart';

const SocialEngine social = SocialEngine();

GameState life(int seed, {int age = 18, int charisma = 60}) {
  final GameState state =
      LifeGenerator.seeded(seed).generate(mode: StartMode.tamamenRastgele);
  return state.copyWith(
    player: state.player.copyWith(
      age: age,
      stats: state.player.stats.copyWith(charisma: charisma),
    ),
  );
}

SocialContent content(String id) => socialContentById(id)!;

/// Hesabı açılmış, belirli takipçisi olan bir durum.
GameState withAccount(
  GameState state,
  SocialPlatform platform, {
  int followers = 0,
}) {
  final GameState acik = social.openAccount(state, platform).state;
  if (followers == 0) return acik;
  return acik.copyWith(
    socialAccounts: List<SocialAccount>.unmodifiable(
      acik.socialAccounts
          .map((SocialAccount a) =>
              a.platform == platform ? a.copyWith(followers: followers) : a)
          .toList(growable: false),
    ),
  );
}

void main() {
  // ===================================================================
  // Hesap
  // ===================================================================
  group('Hesap', () {
    test('16 yaşından önce hesap açılamaz', () {
      final GameState kucuk = life(1, age: 14);
      expect(
        social.accountAvailability(kucuk, SocialPlatform.video).isAllowed,
        isFalse,
      );
      final SocialResult r = social.openAccount(kucuk, SocialPlatform.video);
      expect(r.outcome.applied, isFalse);
      expect(r.state.socialAccounts, isEmpty);
    });

    test('hesap açmak isteğe bağlıdır ve hesapsız paylaşım yapılamaz', () {
      final GameState state = life(2, age: 18);
      expect(state.socialAccounts, isEmpty,
          reason: 'Hiçbir hesap kendiliğinden açılmaz');

      for (final SocialContent c in kSocialContents) {
        expect(social.postAvailability(state, c).isAllowed, isFalse);
        final SocialResult r = social.post(state, c, Random(1));
        expect(r.outcome.applied, isFalse);
        expect(r.state.socialAccounts, isEmpty);
      }
    });

    test('hesap açılınca kayıt oluşur, ikinci kez açılamaz', () {
      final GameState state = life(3, age: 17);
      final SocialResult r = social.openAccount(state, SocialPlatform.foto);
      expect(r.outcome.applied, isTrue);

      final SocialAccount hesap = r.state.accountFor(SocialPlatform.foto)!;
      expect(hesap.followers, 0);
      expect(hesap.postCount, 0);
      expect(hesap.createdAtAge, 17);
      expect(r.state.log.last.text, contains('hesabı açtın'));

      final SocialResult ikinci =
          social.openAccount(r.state, SocialPlatform.foto);
      expect(ikinci.outcome.applied, isFalse);
      expect(ikinci.state.socialAccounts.length, 1);
    });

    test('platformların takipçi sayıları ayrıdır', () {
      GameState state = life(4, age: 20);
      state = withAccount(state, SocialPlatform.video, followers: 300);
      state = withAccount(state, SocialPlatform.mikroblog, followers: 50);

      expect(state.accountFor(SocialPlatform.video)!.followers, 300);
      expect(state.accountFor(SocialPlatform.mikroblog)!.followers, 50);
      expect(state.accountFor(SocialPlatform.foto), isNull);
      expect(state.totalFollowers, 350);

      // Bir platformda paylaşım diğerini etkilemez.
      final SocialResult r =
          social.post(state, content('mizah'), Random(2));
      expect(r.state.accountFor(SocialPlatform.video)!.followers, 300);
    });
  });

  // ===================================================================
  // Paylaşım
  // ===================================================================
  group('Paylaşım', () {
    test('her paylaşım takipçi kazandırmaz', () {
      final GameState state =
          withAccount(life(11, age: 20, charisma: 40), SocialPlatform.video,
              followers: 400);
      int kazanc = 0;
      int kayip = 0;
      for (int i = 0; i < 60; i++) {
        final SocialResult r =
            social.post(state, content('vlog'), Random(i));
        if (r.outcome.followerDelta > 0) kazanc++;
        if (r.outcome.followerDelta < 0) kayip++;
      }
      expect(kazanc, greaterThan(0));
      expect(kayip, greaterThan(0),
          reason: 'Bazı paylaşımlar takipçi kaybettirebilmeli');
    });

    test('içerik geçmişi kaydedilir', () {
      GameState state = withAccount(life(12, age: 20), SocialPlatform.foto);
      state = social.post(state, content('fotograf'), Random(1)).state;
      state = social.post(state, content('hikaye'), Random(2)).state;

      final SocialAccount hesap = state.accountFor(SocialPlatform.foto)!;
      expect(hesap.postCount, 2);
      expect(hesap.posts.first.contentId, 'fotograf');
      expect(hesap.posts.last.contentId, 'hikaye');
      expect(hesap.posts.last.age, 20);
    });

    test('aynı içeriği üst üste paylaşmak kazancı düşürür', () {
      final GameState temel =
          withAccount(life(13, age: 22, charisma: 80), SocialPlatform.video,
              followers: 1000);

      // Tek paylaşım ile aynı içeriği 4 kez paylaşmış hesabı karşılaştır.
      GameState tekrarli = temel;
      for (int i = 0; i < 4; i++) {
        tekrarli = social
            .post(tekrarli, content('eglence_videosu'), Random(100 + i))
            .state;
      }
      // Tekrar sayacı aynı olsun diye yalnızca geçmişi karşılaştırıyoruz.
      expect(
        tekrarli.accountFor(SocialPlatform.video)!.recentCountOf(
              'eglence_videosu',
            ),
        greaterThan(0),
      );

      int toplamTaze = 0;
      int toplamTekrar = 0;
      for (int i = 0; i < 25; i++) {
        toplamTaze += social
            .post(temel, content('eglence_videosu'), Random(i))
            .outcome
            .followerDelta;
        toplamTekrar += social
            .post(tekrarli, content('eglence_videosu'), Random(i))
            .outcome
            .followerDelta;
      }
      expect(toplamTekrar, lessThan(toplamTaze),
          reason: 'Aynı içeriğin tekrarı daha az kazandırmalı');
    });

    test('bir yaşta sınırsız paylaşım yapılamaz', () {
      GameState state =
          withAccount(life(14, age: 20), SocialPlatform.mikroblog);
      int yapilan = 0;
      for (int i = 0; i < 20; i++) {
        final SocialResult r =
            social.post(state, content('mizah'), Random(i));
        if (!r.outcome.applied) break;
        state = r.state;
        yapilan++;
      }
      expect(yapilan, SocialEngine.prototypeOnlyMaxPostsPerAge);
      expect(
        social.postAvailability(state, content('mizah')).isAllowed,
        isFalse,
      );
    });

    test('karakter özellikleri sonucu etkiler', () {
      final GameState karizmatik = withAccount(
        life(15, age: 22, charisma: 95),
        SocialPlatform.video,
        followers: 200,
      );
      final GameState cekingen = withAccount(
        life(15, age: 22, charisma: 10),
        SocialPlatform.video,
        followers: 200,
      );

      int a = 0;
      int b = 0;
      for (int i = 0; i < 30; i++) {
        a += social
            .post(karizmatik, content('eglence_videosu'), Random(i))
            .outcome
            .followerDelta;
        b += social
            .post(cekingen, content('eglence_videosu'), Random(i))
            .outcome
            .followerDelta;
      }
      expect(a, greaterThan(b));
    });

    test('takipçi sayısı eksiye düşmez', () {
      GameState state =
          withAccount(life(16, age: 20), SocialPlatform.mikroblog);
      for (int i = 0; i < 6; i++) {
        state = social.post(state, content('mizah'), Random(i)).state;
        expect(state.accountFor(SocialPlatform.mikroblog)!.followers,
            greaterThanOrEqualTo(0));
      }
    });
  });

  // ===================================================================
  // Ün
  // ===================================================================
  group('Ün', () {
    test('ün kendiliğinden açılmaz', () {
      final GameState state = life(21, age: 20);
      expect(state.player.fame, isNull);
      expect(state.player.fameUnlocked, isFalse);

      // Küçük kitleli paylaşım ünü açmaz.
      final GameState kucuk =
          withAccount(state, SocialPlatform.mikroblog, followers: 20);
      final SocialResult r =
          social.post(kucuk, content('gunluk_dusunce'), Random(1));
      expect(r.state.player.fame, isNull);
    });

    test('yeterli kitle oluşunca ün açılır ve rozet gösterilir', () {
      final GameState state = withAccount(
        life(22, age: 24, charisma: 90),
        SocialPlatform.video,
        followers: SocialEngine.prototypeOnlyFameThreshold + 2000,
      );
      final SocialResult r =
          social.post(state, content('bilgi_videosu'), Random(3));

      expect(r.state.player.fame, isNotNull);
      expect(r.state.player.fameUnlocked, isTrue);
      expect(r.state.player.fame, greaterThan(0));
      expect(r.state.player.fame, lessThanOrEqualTo(100));
      expect(
        r.outcome.effects.map((AppliedEffect e) => e.label),
        contains('Ün'),
      );
    });

    test('ün 100 üstüne çıkmaz', () {
      GameState state = withAccount(
        life(23, age: 30, charisma: 95),
        SocialPlatform.video,
        followers: 5000000,
      );
      for (int i = 0; i < 6; i++) {
        state = social.post(state, content('bilgi_videosu'), Random(i)).state;
      }
      expect(state.player.fame, lessThanOrEqualTo(100));
    });
  });

  // ===================================================================
  // Kayıt
  // ===================================================================
  group('Kayıt', () {
    test('hesaplar ve içerik geçmişi kaydedilip geri okunur', () async {
      GameState state = life(31, age: 20);
      state = withAccount(state, SocialPlatform.video, followers: 120);
      state = social.post(state, content('vlog'), Random(1)).state;
      state = social.post(state, content('oyun_videosu'), Random(2)).state;
      state = withAccount(state, SocialPlatform.mikroblog, followers: 15);

      final MemorySaveStore store = MemorySaveStore();
      final SaveService service = SaveService(store);
      await service.save(state);
      final SaveLoadResult result = await service.load();
      expect(result.isLoaded, isTrue);

      final GameState sonra = result.state!;
      expect(sonra.socialAccounts.length, 2);
      final SocialAccount video = sonra.accountFor(SocialPlatform.video)!;
      expect(video.followers,
          state.accountFor(SocialPlatform.video)!.followers);
      expect(video.postCount, 2);
      expect(video.posts.first.contentId, 'vlog');
      expect(video.posts.last.contentId, 'oyun_videosu');
      expect(sonra.accountFor(SocialPlatform.mikroblog)!.followers, 15);
      expect(sonra.player.fame, state.player.fame);
    });

    test('sürüm 5 kaydı sosyal medya alanı eklenerek açılır', () async {
      final GameState orijinal = life(32, age: 22);
      final Map<String, Object?> body = encodeGameState(orijinal);
      body.remove('socialAccounts');

      final SaveLoadResult result = await SaveService(
        MemorySaveStore(
          initial: jsonEncode(
            <String, Object?>{'formatVersion': 5, 'state': body},
          ),
        ),
      ).load();
      expect(result.isLoaded, isTrue, reason: result.message);
      expect(result.state!.socialAccounts, isEmpty);
      expect(result.state!.player.id, orijinal.player.id);
      expect(result.state!.player.age, 22);
    });

    test('denetleyici üzerinden paylaşım kaydedilir', () async {
      final MemorySaveStore store = MemorySaveStore();
      final GameController c = GameController(
        random: Random(33),
        saveService: SaveService(store),
      );
      c.startNewLife(mode: StartMode.tamamenRastgele, seed: 33);
      c.debugSetState(
        c.state!.copyWith(
          player: c.state!.player.copyWith(age: 20),
          pendingEvent: null,
        ),
      );

      expect(c.openSocialAccount(SocialPlatform.foto)!.applied, isTrue);
      expect(c.postContent(content('fotograf'))!.applied, isTrue);
      await c.flushSaves();

      final SaveLoadResult result = await SaveService(store).load();
      expect(result.isLoaded, isTrue);
      expect(result.state!.accountFor(SocialPlatform.foto)!.postCount, 1);
    });

    test('kayıt sürümü yükseltildi', () {
      expect(kSaveFormatVersion, greaterThanOrEqualTo(6));
    });
  });

  // ===================================================================
  // İçerik kataloğu
  // ===================================================================
  group('İçerik kataloğu', () {
    test('her platformun kendi içerik türleri var', () {
      for (final SocialPlatform p in SocialPlatform.values) {
        final List<SocialContent> icerikler = contentsFor(p);
        expect(icerikler, isNotEmpty);
        for (final SocialContent c in icerikler) {
          expect(c.platform, p);
          expect(c.baseReach, greaterThan(0));
        }
      }
      final Set<String> ids =
          kSocialContents.map((SocialContent c) => c.id).toSet();
      expect(ids.length, kSocialContents.length);
    });

    test('siyasi taraf tutan içerik yok', () {
      for (final SocialContent c in kSocialContents) {
        final String metin = '${c.label} ${c.description}'.toLowerCase();
        for (final String yasak in <String>[
          'parti',
          'seçim',
          'oy ver',
          'iktidar',
          'muhalefet',
        ]) {
          expect(metin, isNot(contains(yasak)));
        }
      }
    });
  });
}

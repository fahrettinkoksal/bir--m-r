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
import 'package:bir_omur/domain/models/interaction.dart';
import 'package:bir_omur/domain/models/social_account.dart';
import 'package:bir_omur/domain/social/social_engine.dart';
import 'package:bir_omur/state/game_controller.dart';
import 'package:flutter_test/flutter_test.dart';

const SocialEngine social = SocialEngine();

GameState life(int seed, {int age = 18, int charisma = 60}) {
  final GameState state = LifeGenerator.seeded(
    seed,
  ).generate(mode: StartMode.tamamenRastgele);
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
          .map(
            (SocialAccount a) =>
                a.platform == platform ? a.copyWith(followers: followers) : a,
          )
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
      expect(
        state.socialAccounts,
        isEmpty,
        reason: 'Hiçbir hesap kendiliğinden açılmaz',
      );

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

      final SocialResult ikinci = social.openAccount(
        r.state,
        SocialPlatform.foto,
      );
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
      final SocialResult r = social.post(state, content('mizah'), Random(2));
      expect(r.state.accountFor(SocialPlatform.video)!.followers, 300);
    });
  });

  // ===================================================================
  // Paylaşım
  // ===================================================================
  group('Paylaşım', () {
    test('her paylaşım takipçi kazandırmaz', () {
      final GameState state = withAccount(
        life(11, age: 20, charisma: 40),
        SocialPlatform.video,
        followers: 400,
      );
      int kazanc = 0;
      int kayip = 0;
      for (int i = 0; i < 60; i++) {
        final SocialResult r = social.post(state, content('vlog'), Random(i));
        if (r.outcome.followerDelta > 0) kazanc++;
        if (r.outcome.followerDelta < 0) kayip++;
      }
      expect(kazanc, greaterThan(0));
      expect(
        kayip,
        greaterThan(0),
        reason: 'Bazı paylaşımlar takipçi kaybettirebilmeli',
      );
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
      final GameState temel = withAccount(
        life(13, age: 22, charisma: 80),
        SocialPlatform.video,
        followers: 1000,
      );

      // Tek paylaşım ile aynı içeriği 4 kez paylaşmış hesabı karşılaştır.
      GameState tekrarli = temel;
      for (int i = 0; i < 4; i++) {
        tekrarli = social
            .post(tekrarli, content('eglence_videosu'), Random(100 + i))
            .state;
      }
      // Tekrar sayacı aynı olsun diye yalnızca geçmişi karşılaştırıyoruz.
      expect(
        tekrarli
            .accountFor(SocialPlatform.video)!
            .recentCountOf('eglence_videosu'),
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
      expect(
        toplamTekrar,
        lessThan(toplamTaze),
        reason: 'Aynı içeriğin tekrarı daha az kazandırmalı',
      );
    });

    test('bir yaşta sınırsız paylaşım yapılamaz', () {
      GameState state = withAccount(
        life(14, age: 20),
        SocialPlatform.mikroblog,
      );
      int yapilan = 0;
      for (int i = 0; i < 20; i++) {
        final SocialResult r = social.post(state, content('mizah'), Random(i));
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

    test('platformun sınırı diğer platformları kapatmaz', () {
      // Her platform çifti için: birinde sınıra ulaş, diğerinde ilk
      // paylaşımını yap.
      const Map<SocialPlatform, String> ornekIcerik = <SocialPlatform, String>{
        SocialPlatform.video: 'eglence_videosu',
        SocialPlatform.foto: 'fotograf',
        SocialPlatform.mikroblog: 'mizah',
      };

      for (final SocialPlatform dolan in SocialPlatform.values) {
        for (final SocialPlatform digeri in SocialPlatform.values) {
          if (dolan == digeri) continue;

          // İki hesap da açık.
          GameState state = withAccount(life(60, age: 20), dolan);
          state = withAccount(state, digeri);

          // Birinci platformda sınıra kadar paylaş.
          int yapilan = 0;
          for (int i = 0; i < 20; i++) {
            final SocialResult r = social.post(
              state,
              content(ornekIcerik[dolan]!),
              Random(i),
            );
            if (!r.outcome.applied) break;
            state = r.state;
            yapilan++;
          }
          expect(
            yapilan,
            SocialEngine.prototypeOnlyMaxPostsPerAge,
            reason: '${dolan.label} sınırına ulaşılmalı',
          );
          expect(
            social
                .postAvailability(state, content(ornekIcerik[dolan]!))
                .isAllowed,
            isFalse,
          );

          // Diğer platformda hiç paylaşım yapılmadı: hâlâ açık olmalı.
          expect(
            social
                .postAvailability(state, content(ornekIcerik[digeri]!))
                .isAllowed,
            isTrue,
            reason: '${dolan.label} dolunca ${digeri.label} kapanmamalı',
          );
          expect(
            social.remainingPosts(state, digeri),
            SocialEngine.prototypeOnlyMaxPostsPerAge,
          );

          final SocialResult ilk = social.post(
            state,
            content(ornekIcerik[digeri]!),
            Random(1),
          );
          expect(
            ilk.outcome.applied,
            isTrue,
            reason: '${digeri.label} üzerindeki ilk paylaşım çalışmalı',
          );
          expect(ilk.state.accountFor(digeri)!.postCount, 1);
          expect(
            ilk.state.accountFor(dolan)!.postCount,
            SocialEngine.prototypeOnlyMaxPostsPerAge,
            reason: 'Diğer platformun geçmişi değişmemeli',
          );
        }
      }
    });

    test('sınır dolunca gerekçe platformu adıyla anlatır', () {
      GameState state = withAccount(life(61, age: 20), SocialPlatform.foto);
      for (int i = 0; i < SocialEngine.prototypeOnlyMaxPostsPerAge; i++) {
        state = social.post(state, content('fotograf'), Random(i)).state;
      }
      final InteractionAvailability durum = social.postAvailability(
        state,
        content('fotograf'),
      );
      expect(durum.isAllowed, isFalse);
      expect(durum.reason, contains(SocialPlatform.foto.label));
      expect(social.remainingPosts(state, SocialPlatform.foto), 0);
    });

    test('içerik geçmişi platformlar arasında karışmaz', () {
      // Bu test eskiden takipçi sayısının da hiç değişmemesini
      // bekliyordu. Faho'nun isteğiyle bir platformdaki **kazanç**
      // artık diğer açık hesaplara belli bir oranda yansıyor; yansıyan
      // miktar aşağıda tam olarak denetleniyor. Paylaşım kaydının
      // platformlar arasında karışmaması kuralı aynen duruyor.
      GameState state = withAccount(
        life(62, age: 20),
        SocialPlatform.video,
        followers: 300,
      );
      state = withAccount(state, SocialPlatform.foto);

      final int videoOnce = state.accountFor(SocialPlatform.video)!.followers;
      final SocialResult r = social.post(state, content('fotograf'), Random(3));

      // Paylaşım yalnızca yapıldığı platformun kaydına yazılır.
      expect(r.state.accountFor(SocialPlatform.video)!.posts, isEmpty);
      expect(r.state.accountFor(SocialPlatform.foto)!.posts.length, 1);

      // Takipçi yansıması belgelenmiş paydan ne fazla ne eksik.
      final int beklenenPay =
          r.outcome.followerDelta >= SocialEngine.prototypeOnlyCrossMinGain
          ? (r.outcome.followerDelta * SocialEngine.prototypeOnlyCrossShare)
                .floor()
          : 0;
      expect(
        r.state.accountFor(SocialPlatform.video)!.followers,
        videoOnce + beklenenPay,
      );
    });

    test('yaş ilerleyince her platformun sayacı yenilenir', () {
      GameState state = withAccount(life(63, age: 20), SocialPlatform.foto);
      state = withAccount(state, SocialPlatform.mikroblog);
      for (int i = 0; i < SocialEngine.prototypeOnlyMaxPostsPerAge; i++) {
        state = social.post(state, content('fotograf'), Random(i)).state;
      }
      expect(social.remainingPosts(state, SocialPlatform.foto), 0);

      // Bir yaş ilerle: sayaç paylaşım geçmişinden okunduğu için yenilenir.
      final GameState seneye = state.copyWith(
        player: state.player.copyWith(age: 21),
      );
      expect(
        social.remainingPosts(seneye, SocialPlatform.foto),
        SocialEngine.prototypeOnlyMaxPostsPerAge,
      );
      expect(
        social.remainingPosts(seneye, SocialPlatform.mikroblog),
        SocialEngine.prototypeOnlyMaxPostsPerAge,
      );
      expect(
        social.postAvailability(seneye, content('fotograf')).isAllowed,
        isTrue,
      );
      expect(
        seneye.accountFor(SocialPlatform.foto)!.postCount,
        SocialEngine.prototypeOnlyMaxPostsPerAge,
        reason: 'Geçmiş paylaşımlar silinmemeli',
      );
    });

    test(
      'kaydedilip yüklenen hayatta sayaçlar platform başına korunur',
      () async {
        GameState state = withAccount(life(64, age: 20), SocialPlatform.foto);
        state = withAccount(state, SocialPlatform.video);
        for (int i = 0; i < SocialEngine.prototypeOnlyMaxPostsPerAge; i++) {
          state = social.post(state, content('fotograf'), Random(i)).state;
        }

        final SaveService service = SaveService(MemorySaveStore());
        await service.save(state);
        final SaveLoadResult result = await service.load();
        expect(result.isLoaded, isTrue, reason: result.message);
        final GameState geri = result.state!;

        expect(social.remainingPosts(geri, SocialPlatform.foto), 0);
        expect(
          social.remainingPosts(geri, SocialPlatform.video),
          SocialEngine.prototypeOnlyMaxPostsPerAge,
        );
        expect(
          social.postAvailability(geri, content('eglence_videosu')).isAllowed,
          isTrue,
        );
      },
    );

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
      GameState state = withAccount(
        life(16, age: 20),
        SocialPlatform.mikroblog,
      );
      for (int i = 0; i < 6; i++) {
        state = social.post(state, content('mizah'), Random(i)).state;
        expect(
          state.accountFor(SocialPlatform.mikroblog)!.followers,
          greaterThanOrEqualTo(0),
        );
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
      final GameState kucuk = withAccount(
        state,
        SocialPlatform.mikroblog,
        followers: 20,
      );
      final SocialResult r = social.post(
        kucuk,
        content('gunluk_dusunce'),
        Random(1),
      );
      expect(r.state.player.fame, isNull);
    });

    test('yeterli kitle oluşunca ün açılır ve rozet gösterilir', () {
      final GameState state = withAccount(
        life(22, age: 24, charisma: 90),
        SocialPlatform.video,
        followers: SocialEngine.prototypeOnlyFameThreshold + 2000,
      );
      final SocialResult r = social.post(
        state,
        content('bilgi_videosu'),
        Random(3),
      );

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
      expect(
        video.followers,
        state.accountFor(SocialPlatform.video)!.followers,
      );
      expect(video.postCount, 2);
      expect(video.posts.first.contentId, 'vlog');
      expect(video.posts.last.contentId, 'oyun_videosu');
      expect(sonra.accountFor(SocialPlatform.mikroblog)!.followers, 15);
      expect(sonra.player.fame, state.player.fame);
    });

    test(
      'desteklenen en eski sürümün kaydı sosyal medya alanı eklenerek açılır',
      () async {
        final GameState orijinal = life(32, age: 22);

        final SaveLoadResult result = await SaveService(
          MemorySaveStore(
            initial: jsonEncode(<String, Object?>{
              'formatVersion': kMinReadableSaveVersion,
              'state': encodeGameState(orijinal),
            }),
          ),
        ).load();
        expect(result.isLoaded, isTrue, reason: result.message);
        expect(result.state!.socialAccounts, isEmpty);
        expect(result.state!.player.id, orijinal.player.id);
        expect(result.state!.player.age, 22);
      },
    );

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
      final Set<String> ids = kSocialContents
          .map((SocialContent c) => c.id)
          .toSet();
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

  // -------------------------------------------------------------------
  // Platformlar arası yayılma ve yıllık büyüme (Faho'nun isteği)
  // -------------------------------------------------------------------
  group('Platformlar arası yayılma', () {
    test('bir platformdaki kazanç diğer açık hesaba yansır', () {
      GameState s = life(4, charisma: 90);
      s = withAccount(s, SocialPlatform.mikroblog, followers: 5000);
      s = withAccount(s, SocialPlatform.foto, followers: 200);
      final int oncekiFoto = s.accountFor(SocialPlatform.foto)!.followers;

      // Kazanç çıkana kadar dene; kayıp turlarında yayılma olmamalı.
      bool yansidi = false;
      for (int seed = 0; seed < 40 && !yansidi; seed++) {
        final SocialResult r = social.post(s, content('mizah'), Random(seed));
        if (r.outcome.followerDelta < SocialEngine.prototypeOnlyCrossMinGain) {
          continue;
        }
        yansidi = true;
        final int sonraFoto = r.state
            .accountFor(SocialPlatform.foto)!
            .followers;
        expect(sonraFoto, greaterThan(oncekiFoto));
        expect(
          sonraFoto - oncekiFoto,
          (r.outcome.followerDelta * SocialEngine.prototypeOnlyCrossShare)
              .floor(),
        );
      }
      expect(yansidi, isTrue, reason: 'Hiç kazançlı paylaşım çıkmadı');
    });

    test('hesabı olmayan platforma takipçi yazılmaz', () {
      GameState s = life(4, charisma: 90);
      s = withAccount(s, SocialPlatform.mikroblog, followers: 5000);
      final SocialResult r = social.post(
        s,
        content(kSocialContents.first.id),
        Random(1),
      );
      // Açılmamış hesap listeye girmez.
      expect(r.state.accountFor(SocialPlatform.foto), isNull);
      expect(r.state.accountFor(SocialPlatform.video), isNull);
    });

    test('takipçi kaybı diğer platformlara yayılmaz', () {
      GameState s = life(9, charisma: 5);
      s = withAccount(s, SocialPlatform.mikroblog, followers: 8000);
      s = withAccount(s, SocialPlatform.foto, followers: 3000);
      final int oncekiFoto = s.accountFor(SocialPlatform.foto)!.followers;

      for (int seed = 0; seed < 60; seed++) {
        final SocialResult r = social.post(
          s,
          content(kSocialContents.first.id),
          Random(seed),
        );
        if (r.outcome.followerDelta >= 0) continue;
        // Kaybeden turda öteki hesap hiç değişmemeli.
        expect(r.state.accountFor(SocialPlatform.foto)!.followers, oncekiFoto);
        return;
      }
    });
  });

  group('Yıllık kendiliğinden büyüme', () {
    test('kitlesi büyük ve hareketli hesap yıl geçtikçe büyür', () {
      GameState s = life(4, age: 20);
      s = withAccount(s, SocialPlatform.video, followers: 50000);
      // Bu yaşta paylaşım yapılmış sayılsın diye tek paylaşım.
      s = social.post(s, content('vlog'), Random(2)).state;
      final int onceki = s.accountFor(SocialPlatform.video)!.followers;

      final ({GameState state, List<String> logTexts}) r = social.advanceYear(
        s,
        s.player.age + 1,
      );
      expect(
        r.state.accountFor(SocialPlatform.video)!.followers,
        greaterThan(onceki),
      );
      expect(r.logTexts, isNotEmpty);
    });

    test('eşiğin altındaki hesap kendiliğinden büyümez', () {
      GameState s = life(4, age: 20);
      s = withAccount(
        s,
        SocialPlatform.video,
        followers: SocialEngine.prototypeOnlyOrganicThreshold - 1,
      );
      s = social.post(s, content('vlog'), Random(2)).state;
      final int onceki = s.accountFor(SocialPlatform.video)!.followers;
      final ({GameState state, List<String> logTexts}) r = social.advanceYear(
        s,
        s.player.age + 1,
      );
      expect(r.state.accountFor(SocialPlatform.video)!.followers, onceki);
    });

    test('yıllardır dokunulmayan hesap erir', () {
      GameState s = life(4, age: 20);
      s = withAccount(s, SocialPlatform.video, followers: 40000);
      final int onceki = s.accountFor(SocialPlatform.video)!.followers;
      // Hiç paylaşım yok; hesabın açıldığı yaştan çok sonrası.
      final int uzakYas =
          s.player.age + SocialEngine.prototypeOnlyDormantAfterYears + 1;
      final ({GameState state, List<String> logTexts}) r = social.advanceYear(
        s,
        uzakYas,
      );
      expect(
        r.state.accountFor(SocialPlatform.video)!.followers,
        lessThan(onceki),
      );
      expect(r.logTexts.first, contains('kaybettin'));
    });

    test('takipçi sayısı eksiye inmez', () {
      GameState s = life(4, age: 20);
      s = withAccount(s, SocialPlatform.video, followers: 3);
      GameState akan = s;
      for (int i = 1; i <= 40; i++) {
        akan = social.advanceYear(akan, s.player.age + i).state;
      }
      expect(
        akan.accountFor(SocialPlatform.video)!.followers,
        greaterThanOrEqualTo(0),
      );
    });

    test('hesabı olmayan oyuncuda yıllık akış hiçbir şey yapmaz', () {
      final GameState s = life(4, age: 20);
      expect(s.socialAccounts, isEmpty);
      final ({GameState state, List<String> logTexts}) r = social.advanceYear(
        s,
        s.player.age + 1,
      );
      expect(r.logTexts, isEmpty);
      expect(r.state, same(s));
    });

    test('büyüme Ünü tazeler ama geçmiş Ünü düşürmez', () {
      GameState s = life(4, age: 20);
      s = withAccount(s, SocialPlatform.video, followers: 200000);
      s = social.post(s, content('vlog'), Random(2)).state;
      final int oncekiUn = s.player.fame ?? 0;
      final GameState buyuk = social.advanceYear(s, s.player.age + 1).state;
      expect(buyuk.player.fame, greaterThanOrEqualTo(oncekiUn));

      // Erimede Ün geri gitmez: yaşanmış tanınmışlık silinmez (D-027).
      final int erimeUn =
          social
              .advanceYear(
                buyuk,
                buyuk.player.age +
                    SocialEngine.prototypeOnlyDormantAfterYears +
                    2,
              )
              .state
              .player
              .fame ??
          0;
      expect(erimeUn, greaterThanOrEqualTo(buyuk.player.fame ?? 0));
    });
  });
}

import 'dart:math';

import 'package:bir_omur/data/save/game_state_codec.dart';
import 'package:bir_omur/data/save/save_format.dart';
import 'package:bir_omur/data/social_catalog.dart';
import 'package:bir_omur/data/sponsor_catalog.dart';
import 'package:bir_omur/domain/generation/life_generator.dart';
import 'package:bir_omur/domain/generation/life_progression.dart';
import 'package:bir_omur/domain/models/game_state.dart';
import 'package:bir_omur/domain/models/social_account.dart';
import 'package:bir_omur/domain/models/sponsorship.dart';
import 'package:bir_omur/domain/social/social_engine.dart';
import 'package:bir_omur/domain/social/social_income.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/invariants.dart';

const SocialEngine sosyal = SocialEngine();

/// Belirli bir kitleye sahip hesabı olan oyuncu.
GameState yayinci({
  int seed = 51,
  int age = 25,
  int followers = 5000,
  int createdAtAge = 20,
  int wallet = 0,
  SocialPlatform platform = SocialPlatform.video,
  List<SocialPost> posts = const <SocialPost>[],
}) {
  final GameState base =
      LifeGenerator.seeded(seed).generate(mode: StartMode.tamamenRastgele);
  return base.copyWith(
    pendingEvent: null,
    player: base.player.copyWith(age: age, wallet: wallet, fame: 6),
    socialAccounts: <SocialAccount>[
      SocialAccount(
        platform: platform,
        createdAtAge: createdAtAge,
        followers: followers,
        posts: posts,
      ),
    ],
  );
}

/// Hesapsız oyuncu.
GameState hesapsiz({int age = 25}) {
  final GameState base =
      LifeGenerator.seeded(52).generate(mode: StartMode.tamamenRastgele);
  return base.copyWith(
    pendingEvent: null,
    player: base.player.copyWith(age: age),
  );
}

/// Kazanç oluşana kadar paylaşım dener.
SocialResult kazancliPaylasim(GameState state, SocialContent icerik) {
  for (int i = 0; i < 200; i++) {
    final SocialResult r = sosyal.post(state, icerik, Random(i));
    if (r.outcome.earned > 0) return r;
  }
  fail('Hiç gelir oluşmadı.');
}

void main() {
  final SocialContent video = contentsFor(SocialPlatform.video).first;

  // ===================================================================
  // Gelir
  // ===================================================================
  group('İçerik geliri', () {
    test('hesabı olmayan oyuncu gelir elde edemez', () {
      final GameState s = hesapsiz();
      expect(s.totalSocialEarnings, 0);
      final SocialResult r = sosyal.post(s, video, Random(1));
      expect(r.outcome.applied, isFalse);
      expect(r.state.player.wallet, s.player.wallet);
    });

    test('yeni açılmış, kitlesi olmayan hesap gelir üretmez', () {
      final GameState yeni = yayinci(
        followers: 10,
        createdAtAge: 25,
        age: 25,
      );
      final SocialAccount hesap = yeni.socialAccounts.single;
      expect(SocialIncome.canEarn(yeni, hesap), isFalse);

      int toplam = 0;
      GameState s = yeni;
      for (int i = 0; i < 5; i++) {
        final SocialResult r = sosyal.post(s, video, Random(i));
        toplam += r.outcome.earned;
        s = r.state;
      }
      expect(toplam, 0);
      expect(s.player.wallet, yeni.player.wallet);
    });

    test('kitlesi olsa bile hesap çok yeniyse gelir çıkmaz', () {
      final GameState s = yayinci(followers: 20000, createdAtAge: 25, age: 25);
      expect(SocialIncome.canEarn(s, s.socialAccounts.single), isFalse);
    });

    test('gelir cüzdana gerçekten işlenir ve günlükte açıklanır', () {
      final GameState s = yayinci(wallet: 1000);
      final SocialResult r = kazancliPaylasim(s, video);

      expect(r.state.player.wallet, s.player.wallet + r.outcome.earned);
      expect(
        r.state.log.any((dynamic e) =>
            (e.text as String).contains('içerik gelirinden kazandın')),
        isTrue,
      );
      expect(checkInvariants(r.state), isEmpty);
    });

    test('her paylaşım para kazandırmaz', () {
      final GameState s = yayinci();
      int kazandiran = 0;
      for (int i = 0; i < 40; i++) {
        final SocialResult r = sosyal.post(s, video, Random(i));
        if (r.outcome.earned > 0) kazandiran++;
      }
      expect(kazandiran, greaterThan(0));
      expect(kazandiran, lessThan(40), reason: 'Gelir garanti olmamalı');
    });

    test('gelir takipçi sayısına körü körüne eşit değildir', () {
      // Aynı tohum, aynı takipçi: sonuç paylaşımın gerçek etkileşimine
      // bağlı olduğu için tek bir sabit sayı çıkmaz.
      final GameState s = yayinci();
      final Set<int> tutarlar = <int>{};
      for (int i = 0; i < 25; i++) {
        final SocialResult r = sosyal.post(s, video, Random(i));
        if (r.outcome.earned > 0) tutarlar.add(r.outcome.earned);
      }
      expect(tutarlar.length, greaterThan(1));
      for (final int t in tutarlar) {
        expect(t, isNot(s.socialAccounts.single.followers));
      }
    });

    test('aynı paylaşımın geliri iki kez ödenmez', () {
      final GameState s = yayinci(wallet: 0);
      final SocialResult r = kazancliPaylasim(s, video);
      final int cuzdan = r.state.player.wallet;
      final int kazanc = r.outcome.earned;

      // Kayıt turu: kazanç paylaşımın kendi kaydında durur, yeniden
      // ödenmez.
      final GameState geri = decodeGameState(encodeGameState(r.state));
      expect(geri.player.wallet, cuzdan);
      expect(geri.totalSocialEarnings, kazanc);

      // Yaş almak da eski paylaşımı yeniden ödemez.
      final GameState sonra =
          LifeProgression(Random(3)).advanceOneYear(geri);
      expect(sonra.totalSocialEarnings, kazanc);
    });

    test('takipçi kaybettiren paylaşım gelir getirmez', () {
      // Aynı içeriği üst üste paylaşmak kayıp riskini artırır.
      GameState s = yayinci(followers: 30000);
      for (int i = 0; i < 6; i++) {
        final SocialResult r = sosyal.post(s, video, Random(i));
        if (r.outcome.followerDelta < 0) {
          expect(r.outcome.earned, 0);
          return;
        }
        s = r.state;
      }
    });
  });

  // ===================================================================
  // Sponsorluk
  // ===================================================================
  group('Sponsorluk', () {
    SponsorOffer teklifUret(GameState state) {
      for (int i = 0; i < 300; i++) {
        final SponsorOffer? o = SocialIncome.maybeOffer(state, Random(i));
        if (o != null) return o;
      }
      fail('Teklif üretilemedi.');
    }

    test('hesabı olmayana sponsorluk teklifi gelmez', () {
      final GameState s = hesapsiz();
      for (int i = 0; i < 50; i++) {
        expect(SocialIncome.maybeOffer(s, Random(i)), isNull);
      }
    });

    test('kitlesi yetmeyen hesaba teklif gelmez', () {
      final GameState s = yayinci(followers: 200, createdAtAge: 18);
      for (int i = 0; i < 50; i++) {
        expect(SocialIncome.maybeOffer(s, Random(i)), isNull);
      }
    });

    test('kabul edilen sponsorluk hemen para ödemez', () {
      GameState s = yayinci(wallet: 0);
      s = s.copyWith(sponsorOffer: teklifUret(s));
      final int cuzdan = s.player.wallet;

      final SocialResult kabul = sosyal.acceptSponsor(s);
      expect(kabul.outcome.applied, isTrue);
      expect(kabul.state.player.wallet, cuzdan,
          reason: 'Ücret paylaşım yapılınca ödenir');
      expect(kabul.state.openDeals, hasLength(1));
      expect(kabul.state.sponsorOffer, isNull);
    });

    test('paylaşım yapılınca ücret bir kez ödenir', () {
      GameState s = yayinci(wallet: 0);
      final SponsorOffer teklif = teklifUret(s);
      s = sosyal.acceptSponsor(s.copyWith(sponsorOffer: teklif)).state;

      final SocialResult ilk = sosyal.post(s, video, Random(4));
      expect(ilk.state.player.wallet, greaterThanOrEqualTo(teklif.fee));
      expect(ilk.state.openDeals, isEmpty);

      // Ücret yalnızca bir paylaşıma işlenir: ikinci paylaşımda
      // sponsorluk kaydı yoktur ve anlaşma kapalı kalır.
      final SocialResult ikinci = sosyal.post(ilk.state, video, Random(5));
      final List<SocialPost> paylasimlar =
          ikinci.state.socialAccounts.single.posts;
      expect(
        paylasimlar.where((SocialPost p) => p.sponsorId == teklif.id),
        hasLength(1),
      );
      expect(ikinci.state.openDeals, isEmpty);
      expect(
        ikinci.state.sponsorDeals.single.completedAtAge,
        ilk.state.player.age,
      );
    });

    test('reddedilen sponsorluk gelir vermez', () {
      GameState s = yayinci(wallet: 0);
      s = s.copyWith(sponsorOffer: teklifUret(s));
      final SocialResult ret = sosyal.declineSponsor(s);

      expect(ret.state.player.wallet, 0);
      expect(ret.state.sponsorOffer, isNull);
      expect(ret.state.sponsorDeals, isEmpty);

      // Reddedilen teklif için paylaşımda da ödeme olmaz.
      final SocialResult paylasim = sosyal.post(ret.state, video, Random(6));
      expect(paylasim.outcome.earned, lessThan(SocialIncome.prototypeOnlyMaxPerPost));
      expect(paylasim.state.sponsorDeals, isEmpty);
    });

    test('yapılmayan paylaşım için anlaşma ödemeden düşer', () {
      GameState s = yayinci(wallet: 0);
      final SponsorOffer teklif = teklifUret(s);
      s = sosyal.acceptSponsor(s.copyWith(sponsorOffer: teklif)).state;

      final int yeniYas =
          s.player.age + SocialIncome.prototypeOnlyDealDeadline;
      final ({GameState state, List<String> logTexts}) sonuc =
          sosyal.expireDeals(s, yeniYas);

      expect(sonuc.logTexts, hasLength(1));
      expect(sonuc.state.openDeals, isEmpty);
      expect(sonuc.state.sponsorDeals.single.expired, isTrue);
      expect(sonuc.state.player.wallet, 0);
    });

    test('sponsorluk kaydı kapat-aç ile korunur', () {
      GameState s = yayinci();
      final SponsorOffer teklif = teklifUret(s);
      s = s.copyWith(sponsorOffer: teklif);

      final GameState geri = decodeGameState(encodeGameState(s));
      expect(geri.sponsorOffer, isNotNull);
      expect(geri.sponsorOffer!.id, teklif.id);
      expect(geri.sponsorOffer!.fee, teklif.fee);

      final GameState kabul = sosyal.acceptSponsor(geri).state;
      final GameState geri2 = decodeGameState(encodeGameState(kabul));
      expect(geri2.openDeals, hasLength(1));
    });

    test('sponsor kategorileri kurgusaldır ve kitle eşiği vardır', () {
      expect(kSponsorCategories, isNotEmpty);
      for (final SponsorCategory c in kSponsorCategories) {
        expect(c.minFollowers, greaterThan(0));
        expect(c.baseFee, greaterThan(0));
        expect(c.label, isNotEmpty);
      }
    });

    test('sponsorluk yıllık paylaşım sınırını aşmanın yolu değildir', () {
      GameState s = yayinci(wallet: 0);
      s = sosyal.acceptSponsor(s.copyWith(sponsorOffer: teklifUret(s))).state;

      // Yıllık sınırı doldur.
      for (int i = 0; i < SocialEngine.prototypeOnlyMaxPostsPerAge; i++) {
        s = sosyal.post(s, video, Random(20 + i)).state;
      }
      final SocialResult fazladan = sosyal.post(s, video, Random(99));
      expect(fazladan.outcome.applied, isFalse);
    });
  });

  // ===================================================================
  // Takipçi, ün ve platform sınırları
  // ===================================================================
  group('Takipçi, ün ve platformlar', () {
    test('ün ile takipçi aynı sayı değildir', () {
      final GameState s = yayinci(followers: 9000);
      final SocialResult r = sosyal.post(s, video, Random(2));
      final int un = r.state.player.fame ?? 0;

      expect(un, isNot(r.state.totalFollowers));
      expect(un, lessThanOrEqualTo(SocialEngine.prototypeOnlyMaxFame));
      expect(r.state.totalFollowers, greaterThan(un));
    });

    test('üç platformun paylaşım sayaçları bağımsızdır', () {
      final GameState base =
          LifeGenerator.seeded(53).generate(mode: StartMode.tamamenRastgele);
      GameState s = base.copyWith(
        pendingEvent: null,
        player: base.player.copyWith(age: 25),
        socialAccounts: <SocialAccount>[
          const SocialAccount(
            platform: SocialPlatform.video,
            createdAtAge: 20,
            followers: 3000,
          ),
          const SocialAccount(
            platform: SocialPlatform.foto,
            createdAtAge: 20,
            followers: 3000,
          ),
          const SocialAccount(
            platform: SocialPlatform.mikroblog,
            createdAtAge: 20,
            followers: 3000,
          ),
        ],
      );

      // Video sınırını doldur.
      for (int i = 0; i < SocialEngine.prototypeOnlyMaxPostsPerAge; i++) {
        s = sosyal.post(s, video, Random(i)).state;
      }
      expect(sosyal.remainingPosts(s, SocialPlatform.video), 0);
      // Diğer platformlar etkilenmez.
      expect(
        sosyal.remainingPosts(s, SocialPlatform.foto),
        SocialEngine.prototypeOnlyMaxPostsPerAge,
      );
      expect(
        sosyal.remainingPosts(s, SocialPlatform.mikroblog),
        SocialEngine.prototypeOnlyMaxPostsPerAge,
      );

      final SocialContent foto = contentsFor(SocialPlatform.foto).first;
      expect(sosyal.post(s, foto, Random(9)).outcome.applied, isTrue);
    });

    test('ün, takipçi ve cüzdan birbirine karışmaz', () {
      final GameState s = yayinci(followers: 4000, wallet: 12345);
      final SocialResult r = kazancliPaylasim(s, video);

      expect(r.state.player.wallet, greaterThan(12345));
      expect(r.state.totalFollowers, greaterThan(4000));
      expect(r.state.player.fame, isNotNull);
      expect(r.state.player.fame, isNot(r.state.player.wallet));
    });

    test('gelir geçmişi yaş alma ve kayıt turunda korunur', () {
      final GameState s = yayinci(wallet: 0);
      final SocialResult r = kazancliPaylasim(s, video);
      final int kazanc = r.state.totalSocialEarnings;
      expect(kazanc, greaterThan(0));

      GameState sonra = LifeProgression(Random(7)).advanceOneYear(r.state);
      sonra = decodeGameState(encodeGameState(sonra));
      expect(sonra.totalSocialEarnings, kazanc);
    });

    test('eski kayıtta gelir alanı yok ama hesap bozulmaz', () {
      final GameState s = yayinci(followers: 2000);
      final SocialResult r = sosyal.post(s, video, Random(8));
      final Map<String, Object?> body =
          Map<String, Object?>.from(encodeGameState(r.state));
      final List<Object?> hesaplar =
          List<Object?>.from(body['socialAccounts']! as List<Object?>);
      final Map<String, Object?> hesap =
          Map<String, Object?>.from(hesaplar.first! as Map<String, Object?>);
      hesap['posts'] = <Object?>[
        for (final Object? p in hesap['posts']! as List<Object?>)
          Map<String, Object?>.from(p! as Map<String, Object?>)
            ..remove('earned')
            ..remove('sponsorId'),
      ];
      hesaplar[0] = hesap;
      body['socialAccounts'] = hesaplar;
      body.remove('sponsorOffer');
      body.remove('sponsorDeals');

      // Okunabilir taban Paket 25'te 24'e yükseldi (beş sürümlük
      // pencere kuralı); Paket 26'da 25 oldu.
      final GameState geri =
          decodeGameState(SaveMigrations.migrate(body, 25));
      expect(geri.socialAccounts.single.followers,
          r.state.socialAccounts.single.followers);
      // Geriye dönük gelir uydurulmaz.
      expect(geri.totalSocialEarnings, 0);
      expect(geri.sponsorOffer, isNull);
      expect(geri.sponsorDeals, isEmpty);
    });
  });
}

import 'dart:math';

import 'package:bir_omur/data/media_catalog.dart';
import 'package:bir_omur/data/social_catalog.dart';
import 'package:bir_omur/data/sponsor_catalog.dart';
import 'package:bir_omur/data/save/game_state_codec.dart';
import 'package:bir_omur/domain/generation/life_generator.dart';
import 'package:bir_omur/domain/models/game_state.dart';
import 'package:bir_omur/domain/models/social_account.dart';
import 'package:bir_omur/domain/models/sponsorship.dart';
import 'package:bir_omur/domain/social/media_opportunities.dart';
import 'package:bir_omur/domain/social/social_engine.dart';
import 'package:bir_omur/domain/social/social_income.dart';
import 'package:flutter_test/flutter_test.dart';

/// Paket Q: sosyal medya dengesi (D-117 … D-120).
void main() {
  GameState taban({int seed = 11, int age = 25, int fame = 50}) {
    final GameState base =
        LifeGenerator.seeded(seed).generate(mode: StartMode.tamamenRastgele);
    return base.copyWith(
      pendingEvent: null,
      player: base.player.copyWith(age: age, wallet: 100000, fame: fame),
    );
  }

  SocialAccount hesap({
    required SocialPlatform platform,
    required int followers,
    int createdAtAge = 18,
    List<SocialPost> posts = const <SocialPost>[],
  }) =>
      SocialAccount(
        platform: platform,
        createdAtAge: createdAtAge,
        followers: followers,
        posts: posts,
      );

  group('Sponsorluk ücretleri gerçek banda çekildi (D-117)', () {
    test('100.000 takipçi için ücret 2026 bandında kalır', () {
      // Araştırıldı: 2026'da Türkiye'de 10K-100K takipçili bir hesap
      // gönderi başına kabaca 3.000-15.000 ₺ alıyor. Oyun 118.000 ₺
      // ödüyordu.
      final SponsorCategory enKucuk = kSponsorCategories.reduce(
        (SponsorCategory a, SponsorCategory b) =>
            a.baseFee <= b.baseFee ? a : b,
      );
      final int ucret = SocialIncome.feeFor(
        enKucuk,
        hesap(platform: SocialPlatform.values.first, followers: 100000),
      );
      expect(ucret, lessThanOrEqualTo(20000));
      expect(ucret, greaterThanOrEqualTo(8000));
    });

    test('ücret hesabın kendi kitlesinden hesaplanır, toplamdan değil', () {
      // Faho: "her sosyal medya hesabı ayrı".
      final SponsorCategory kategori = kSponsorCategories.first;
      final int kucuk = SocialIncome.feeFor(
        kategori,
        hesap(platform: SocialPlatform.values.first, followers: 5000),
      );
      final int buyuk = SocialIncome.feeFor(
        kategori,
        hesap(platform: SocialPlatform.values.first, followers: 100000),
      );
      expect(buyuk, greaterThan(kucuk));
    });

    test('kategori eşiği de hesap bazındadır', () {
      final SponsorCategory kategori = kSponsorCategories.first;
      final SocialAccount az = hesap(
        platform: SocialPlatform.values.first,
        followers: kategori.minFollowers - 1,
      );
      final SocialAccount yeter = hesap(
        platform: SocialPlatform.values.first,
        followers: kategori.minFollowers,
      );
      expect(kategori.fits(az), isFalse);
      expect(kategori.fits(yeter), isTrue);
    });
  });

  group('Sıradan paylaşım para kazandırmaz (D-117)', () {
    test('gelir payı ancak büyük kitleden sonra başlar', () {
      expect(
        SocialIncome.yearlyRevenueShare(
          hesap(
            platform: SocialPlatform.values.first,
            followers: SocialIncome.prototypeOnlyRevenueShareThreshold - 1,
          ),
        ),
        0,
      );
      expect(
        SocialIncome.yearlyRevenueShare(
          hesap(
            platform: SocialPlatform.values.first,
            followers: SocialIncome.prototypeOnlyRevenueShareThreshold,
          ),
        ),
        greaterThan(0),
      );
    });
  });

  group('Ün bakım ister (D-118)', () {
    test('paylaşım yapılmayan yıllarda Ün düşer', () {
      // Faho: "ün neredeyse hiç ama hiç düşmüyor... 1 yıl paylaşım
      // yapmayı unutursam düşmeli". D-027'nin "yalnızca yukarı" kuralı
      // Faho'nun kararıyla değişti.
      GameState s = taban(age: 30, fame: 60).copyWith(
        socialAccounts: <SocialAccount>[
          hesap(
            platform: SocialPlatform.values.first,
            followers: 20000,
            createdAtAge: 20,
            posts: const <SocialPost>[
              SocialPost(contentId: 'x', age: 25, followerDelta: 10),
            ],
          ),
        ],
      );
      final int once = s.player.fame!;
      s = const SocialEngine().advanceYear(s, 31).state;
      expect(s.player.fame, lessThan(once));
    });

    test('Ün bir tabanın altına inmez', () {
      GameState s = taban(age: 40, fame: 6).copyWith(
        socialAccounts: <SocialAccount>[
          hesap(
            platform: SocialPlatform.values.first,
            followers: 2000,
            createdAtAge: 20,
          ),
        ],
      );
      for (int yil = 41; yil < 70; yil++) {
        s = const SocialEngine().advanceYear(s, yil).state;
      }
      expect(
        s.player.fame,
        greaterThanOrEqualTo(SocialEngine.prototypeOnlyFameFloor),
      );
    });

    test('bu yıl paylaşım yapıldıysa Ün düşmez', () {
      final GameState s = taban(age: 30, fame: 60).copyWith(
        socialAccounts: <SocialAccount>[
          hesap(
            platform: SocialPlatform.values.first,
            followers: 20000,
            createdAtAge: 20,
            posts: const <SocialPost>[
              SocialPost(contentId: 'x', age: 31, followerDelta: 10),
            ],
          ),
        ],
      );
      final GameState sonra = const SocialEngine().advanceYear(s, 31).state;
      expect(sonra.player.fame, greaterThanOrEqualTo(60));
    });
  });

  group('Kitle yorgunluğu (D-119)', () {
    GameState ileDeals(int adet, {int age = 30}) {
      final GameState s = taban(age: age);
      return s.copyWith(
        sponsorDeals: <SponsorDeal>[
          for (int i = 0; i < adet; i++)
            SponsorDeal(
              id: 'd$i',
              categoryId: kSponsorCategories.first.id,
              platform: SocialPlatform.values.first,
              fee: 5000,
              acceptedAtAge: age - 1,
              completedAtAge: age - 1,
            ),
        ],
      );
    }

    test('ara sıra sponsorluk bedelsizdir', () {
      // Faho: "her sponsorlukta kayıba gerek yok".
      expect(
        SocialIncome.audienceFatigue(
          state: ileDeals(SocialIncome.prototypeOnlyFatigueFreeDeals),
          platform: SocialPlatform.values.first,
          age: 30,
        ),
        0,
      );
    });

    test('art arda sponsorluk kitleyi yorar', () {
      // Faho: "sürekli sponsor alırsa kayıp yaşansın".
      final double yorgunluk = SocialIncome.audienceFatigue(
        state: ileDeals(SocialIncome.prototypeOnlyFatigueFreeDeals + 3),
        platform: SocialPlatform.values.first,
        age: 30,
      );
      expect(yorgunluk, greaterThan(0));
      expect(yorgunluk, lessThanOrEqualTo(
        SocialIncome.prototypeOnlyMaxFatigueLoss,
      ));
    });

    test('eski sponsorluklar pencereden düşer', () {
      final GameState s = taban(age: 40).copyWith(
        sponsorDeals: <SponsorDeal>[
          for (int i = 0; i < 6; i++)
            SponsorDeal(
              id: 'd$i',
              categoryId: kSponsorCategories.first.id,
              platform: SocialPlatform.values.first,
              fee: 5000,
              acceptedAtAge: 20,
              completedAtAge: 20,
            ),
        ],
      );
      expect(
        SocialIncome.audienceFatigue(
          state: s,
          platform: SocialPlatform.values.first,
          age: 40,
        ),
        0,
      );
    });

    test('sözünü tutmamak tekrarladıkça ağırlaşır', () {
      final GameState temiz = taban();
      final GameState kirikli = taban().copyWith(
        sponsorDeals: <SponsorDeal>[
          for (int i = 0; i < 3; i++)
            SponsorDeal(
              id: 'k$i',
              categoryId: kSponsorCategories.first.id,
              platform: SocialPlatform.values.first,
              fee: 5000,
              acceptedAtAge: 20,
              expired: true,
            ),
        ],
      );
      expect(
        SocialIncome.brokenDealLoss(kirikli),
        greaterThan(SocialIncome.brokenDealLoss(temiz)),
      );
    });
  });

  group('Medya başvurusu reddedilebilir, davet gelebilir (D-120)', () {
    test('başvuru garanti değildir', () {
      final MediaOpportunity is1 = kMediaOpportunities.first;
      final GameState s = taban(fame: is1.minFame);
      final double sans = MediaOpportunities.acceptChance(s, is1);
      expect(sans, lessThan(1.0));
      expect(sans, greaterThan(0.0));
    });

    test('Ün arttıkça kabul şansı artar', () {
      final MediaOpportunity is1 = kMediaOpportunities.first;
      expect(
        MediaOpportunities.acceptChance(taban(fame: is1.minFame + 20), is1),
        greaterThan(
          MediaOpportunities.acceptChance(taban(fame: is1.minFame), is1),
        ),
      );
    });

    test('reddedilen başvuru da yıllık hakkı tüketir', () {
      final MediaOpportunity is1 = kMediaOpportunities.first;
      final GameState s = taban(fame: is1.minFame);
      for (int seed = 0; seed < 60; seed++) {
        final MediaResult r = MediaOpportunities.accept(s, is1, Random(seed));
        if (r.text.contains('kabul edilmedi')) {
          expect(MediaOpportunities.timesDone(r.state, is1), greaterThan(0));
          return;
        }
      }
      fail('Hiç reddedilmedi');
    });

    test('davet edilen işte Ün şartı aranmaz ve başvuru reddedilmez', () {
      final MediaOpportunity is1 = kMediaOpportunities.last;
      // Ünü yetmeyen oyuncu.
      final GameState davetli = taban(fame: 40).copyWith(
        mediaInvitationId: is1.id,
        mediaInvitationAge: 25,
      );
      expect(MediaOpportunities.availability(davetli, is1).isAllowed, isTrue);
      final MediaResult r =
          MediaOpportunities.accept(davetli, is1, Random(1));
      expect(r.applied, isTrue);
      expect(r.text, isNot(contains('kabul edilmedi')));
      // Davet kullanıldı.
      expect(r.state.mediaInvitationId, isNull);
    });

    test('davet kayda girer ve kapat-aç ile kaybolmaz', () {
      final GameState s = taban().copyWith(
        mediaInvitationId: kMediaOpportunities.first.id,
        mediaInvitationAge: 25,
      );
      final GameState geri = decodeGameState(encodeGameState(s));
      expect(geri.mediaInvitationId, kMediaOpportunities.first.id);
      expect(geri.mediaInvitationAge, 25);
    });

    test('davet yalnızca geldiği yıl geçerlidir', () {
      final GameState s = taban(age: 26).copyWith(
        mediaInvitationId: kMediaOpportunities.first.id,
        mediaInvitationAge: 25,
      );
      expect(s.hasMediaInvitation(kMediaOpportunities.first.id), isFalse);
    });
  });
}

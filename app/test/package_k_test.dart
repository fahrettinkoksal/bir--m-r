import 'dart:math';

import 'package:bir_omur/data/media_catalog.dart';
import 'package:bir_omur/data/social_catalog.dart';
import 'package:bir_omur/data/sponsor_catalog.dart';
import 'package:bir_omur/domain/generation/life_generator.dart';
import 'package:bir_omur/domain/models/game_state.dart';
import 'package:bir_omur/domain/models/interaction.dart';
import 'package:bir_omur/domain/models/relation.dart';
import 'package:bir_omur/domain/models/social_account.dart';
import 'package:bir_omur/domain/models/sponsorship.dart';
import 'package:bir_omur/domain/social/media_opportunities.dart';
import 'package:bir_omur/domain/social/social_engine.dart';
import 'package:bir_omur/domain/social/social_income.dart';
import 'package:bir_omur/text/turkish_text.dart';
import 'package:flutter_test/flutter_test.dart';

/// Paket K: sosyal medya, sponsorluk ve Ün (D-103 … D-106).
void main() {
  GameState hayat({int seed = 21, int age = 25}) {
    final GameState base =
        LifeGenerator.seeded(seed).generate(mode: StartMode.tamamenRastgele);
    return base.copyWith(
      pendingEvent: null,
      player: base.player.copyWith(age: age, wallet: 100000),
    );
  }

  GameState hesapli(GameState state, SocialPlatform platform, int takipci) =>
      state.copyWith(
        socialAccounts: List<SocialAccount>.unmodifiable(<SocialAccount>[
          ...state.socialAccounts.where(
            (SocialAccount a) => a.platform != platform,
          ),
          SocialAccount(
            platform: platform,
            createdAtAge: state.player.age - 2,
            followers: takipci,
          ),
        ]),
      );

  group('Sponsorluk eşiği ve ücret ölçeği (D-104)', () {
    test('5.000 takipçinin altında hiçbir sponsor teklif etmez', () {
      final GameState s =
          hesapli(hayat(), SocialPlatform.foto, kSponsorMinFollowers - 1);
      final SocialAccount hesap = s.accountFor(SocialPlatform.foto)!;
      expect(SocialIncome.categoriesFor(hesap), isEmpty);
      expect(SocialIncome.maybeOffer(s, Random(1)), isNull);
    });

    test('kataloğun hiçbir kategorisi genel eşiğin altına inemez', () {
      for (final SponsorCategory c in kSponsorCategories) {
        expect(c.minFollowers, greaterThanOrEqualTo(kSponsorMinFollowers));
      }
    });

    test('ücret kitleyle ölçeklenir', () {
      final SponsorCategory kucuk = kSponsorCategories.reduce(
        (SponsorCategory a, SponsorCategory b) =>
            a.minFollowers <= b.minFollowers ? a : b,
      );
      final Map<int, int> ornekler = <int, int>{};
      for (final int takipci in <int>[5000, 20000, 100000, 500000]) {
        final SocialAccount hesap = SocialAccount(
          platform: SocialPlatform.foto,
          createdAtAge: 20,
          followers: takipci,
        );
        ornekler[takipci] = SocialIncome.feeFor(kucuk, hesap);
      }
      // ignore: avoid_print
      print('SPONSORLUK UCRETI (${kucuk.label}): '
          '${ornekler.entries.map((MapEntry<int, int> e) => '${trNumber(e.key)} -> ${trMoney(e.value)}').join(' · ')}');

      final List<int> degerler = ornekler.values.toList(growable: false);
      for (int i = 1; i < degerler.length; i++) {
        expect(degerler[i], greaterThan(degerler[i - 1]));
      }
      // Kitle 100 katına çıkarken ücret orantısız patlamaz.
      expect(ornekler[500000]! / ornekler[5000]!, lessThan(40));
    });
  });

  group('Sözünü tutmamanın bedeli (D-104)', () {
    test('paylaşım yapılmayan sponsorluk takipçi kaybettirir', () {
      GameState s = hesapli(hayat(), SocialPlatform.foto, 50000);
      const SponsorDeal anlasma = SponsorDeal(
        id: 'deal-1',
        categoryId: 'mahalle_kafe',
        platform: SocialPlatform.foto,
        fee: 50000,
        acceptedAtAge: 25,
      );
      s = s.copyWith(sponsorDeals: const <SponsorDeal>[anlasma]);

      final int oncekiKitle = s.totalFollowers;
      final int oncekiCuzdan = s.player.wallet;
      final ({GameState state, List<String> logTexts}) sonuc =
          const SocialEngine().expireDeals(
        s,
        25 + SocialIncome.prototypeOnlyDealDeadline,
      );

      expect(sonuc.logTexts, isNotEmpty);
      expect(sonuc.state.sponsorDeals.single.expired, isTrue);
      // Ödeme yapılmaz.
      expect(sonuc.state.player.wallet, oncekiCuzdan);
      // Kitle gerçekten düşer.
      expect(sonuc.state.totalFollowers, lessThan(oncekiKitle));
      expect(sonuc.logTexts.single, contains('kaybettin'));
    });

    test('ücret ancak paylaşım yapılınca ödenir', () {
      GameState s = hesapli(hayat(), SocialPlatform.foto, 50000);
      const SponsorDeal anlasma = SponsorDeal(
        id: 'deal-3',
        categoryId: 'mahalle_kafe',
        platform: SocialPlatform.foto,
        fee: 50000,
        acceptedAtAge: 25,
      );
      s = s.copyWith(sponsorDeals: const <SponsorDeal>[anlasma]);
      final int oncekiCuzdan = s.player.wallet;

      // Paylaşım yapılmadan hiçbir şey ödenmez.
      expect(s.player.wallet, oncekiCuzdan);
      expect(s.sponsorDeals.single.isOpen, isTrue);

      // Anlaşmanın platformunda paylaşım yapılınca ödeme işler.
      final SocialContent icerik = kSocialContents.firstWhere(
        (SocialContent c) => c.platform == SocialPlatform.foto,
      );
      final SocialResult r =
          const SocialEngine().post(s, icerik, Random(3));
      expect(r.outcome.applied, isTrue, reason: r.outcome.text);
      expect(r.state.player.wallet, greaterThanOrEqualTo(oncekiCuzdan + 50000));
      expect(r.state.sponsorDeals.single.isOpen, isFalse);
      expect(r.state.sponsorDeals.single.expired, isFalse);
    });

    test('süresi dolmayan anlaşma cezalandırılmaz', () {
      GameState s = hesapli(hayat(), SocialPlatform.foto, 50000);
      s = s.copyWith(
        sponsorDeals: const <SponsorDeal>[
          SponsorDeal(
            id: 'deal-2',
            categoryId: 'mahalle_kafe',
            platform: SocialPlatform.foto,
            fee: 50000,
            acceptedAtAge: 25,
          ),
        ],
      );
      final ({GameState state, List<String> logTexts}) sonuc =
          const SocialEngine().expireDeals(s, 25);
      expect(sonuc.logTexts, isEmpty);
      expect(sonuc.state.totalFollowers, s.totalFollowers);
    });
  });

  group('Tanınan biri sıfırdan başlamaz (D-105)', () {
    test('kitlesi olan oyuncunun yeni hesabı takipçiyle açılır', () {
      final GameState s = hesapli(hayat(), SocialPlatform.foto, 120000);
      final SocialResult r =
          const SocialEngine().openAccount(s, SocialPlatform.video);
      expect(r.outcome.applied, isTrue);
      final SocialAccount yeni = r.state.accountFor(SocialPlatform.video)!;
      expect(yeni.followers, greaterThan(0));
      expect(
        yeni.followers,
        lessThanOrEqualTo(SocialEngine.prototypeOnlyCarryOverCap),
      );
      // ignore: avoid_print
      print('YENI HESAP: 120.000 takipçiden ${trNumber(yeni.followers)} '
          'taşındı');
    });

    test('tanınmayan oyuncu sıfırdan başlar', () {
      final GameState s = hayat();
      final SocialResult r =
          const SocialEngine().openAccount(s, SocialPlatform.foto);
      expect(r.state.accountFor(SocialPlatform.foto)!.followers, 0);
    });
  });

  group('Ün ve Medya Fırsatları (D-103)', () {
    test('Ün eşiğinin altında bölüm görünmez', () {
      final GameState s = hayat().copyWith(
        player: hayat().player.copyWith(fame: kMediaSectionMinFame - 1),
      );
      expect(MediaOpportunities.sectionVisible(s), isFalse);
      final InteractionAvailability a = MediaOpportunities.availability(
        s,
        kMediaOpportunities.first,
      );
      expect(a.isAllowed, isFalse);
      expect(a.reason, contains('$kMediaSectionMinFame'));
    });

    test('eşiği geçen oyuncuda bölüm açılır ve ilk iş yapılabilir', () {
      final GameState s = hayat().copyWith(
        player: hayat().player.copyWith(fame: kMediaSectionMinFame),
      );
      expect(MediaOpportunities.sectionVisible(s), isTrue);
      expect(
        MediaOpportunities.availability(s, kMediaOpportunities.first).isAllowed,
        isTrue,
      );
    });

    test('iş kabul edilince para, Ün ve takipçi gerçekten uygulanır', () {
      GameState s = hesapli(hayat(), SocialPlatform.foto, 50000);
      s = s.copyWith(player: s.player.copyWith(fame: 60));

      final MediaOpportunity is1 = kMediaOpportunities.first;
      final int cuzdan = s.player.wallet;
      final int un = s.player.fame!;
      final int kitle = s.totalFollowers;

      final MediaResult r = MediaOpportunities.accept(s, is1);
      expect(r.applied, isTrue);
      expect(r.state.player.wallet, cuzdan + is1.fee);
      expect(r.state.player.fame, un + is1.fameGain);
      expect(r.state.totalFollowers, greaterThan(kitle));
      expect(r.effects, isNotEmpty);
      // Aynı yıl ikinci kez yapılamaz.
      expect(MediaOpportunities.availability(r.state, is1).isAllowed, isFalse);
    });

    test('Ünü yetmeyen iş gerekçesiyle kapalı kalır', () {
      final GameState s = hayat().copyWith(
        player: hayat().player.copyWith(fame: kMediaSectionMinFame),
      );
      final MediaOpportunity zor = kMediaOpportunities.reduce(
        (MediaOpportunity a, MediaOpportunity b) =>
            a.minFame >= b.minFame ? a : b,
      );
      final InteractionAvailability a = MediaOpportunities.availability(s, zor);
      expect(a.isAllowed, isFalse);
      expect(a.reason, contains('${zor.minFame}'));
    });

    test('hesabı olmayan oyuncuya uydurma takipçi yazılmaz', () {
      final GameState s = hayat().copyWith(
        player: hayat().player.copyWith(fame: 60),
      );
      expect(s.socialAccounts, isEmpty);
      final MediaResult r =
          MediaOpportunities.accept(s, kMediaOpportunities.first);
      expect(r.applied, isTrue);
      expect(r.state.totalFollowers, 0);
      expect(r.text, isNot(contains('takipçi')));
    });
  });

  test('geri takip eden ünlü kendi bölümünde listelenir (D-106)', () {
    expect(RelationType.unlu.group, RelationGroup.tanidiklar);
    expect(RelationType.arkadas.group, RelationGroup.arkadaslar);
    expect(RelationGroup.tanidiklar.title, 'Ünlüler ve tanıdıklar');
  });

  test('takipçi sayıları Türkçe binlik ayracıyla yazılır', () {
    expect(trNumber(2232), '2.232');
    expect(trNumber(500000), '500.000');
  });
}

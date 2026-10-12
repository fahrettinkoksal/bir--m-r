import 'dart:io';
import 'dart:math';

import 'package:bir_omur/data/social_catalog.dart';
import 'package:bir_omur/data/sponsor_catalog.dart';
import 'package:bir_omur/domain/generation/life_generator.dart';
import 'package:bir_omur/domain/models/game_state.dart';
import 'package:bir_omur/domain/models/life_log.dart';
import 'package:bir_omur/domain/models/pending_notice.dart';
import 'package:bir_omur/domain/models/social_account.dart';
import 'package:bir_omur/domain/models/sponsorship.dart';
import 'package:bir_omur/domain/social/social_engine.dart';
import 'package:bir_omur/domain/social/social_income.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/player_bot.dart';

/// **Paket DL — sponsorluğun saati görünmüyor.**
///
/// Neden bu paket. Paket DK'nın dersi şuydu: botun uğramadığı her
/// mekanik aynı zamanda ölçülmemiş bir ekonomidir. Sponsorluk botun
/// uğradığı bir mekanik ama **hunisi** hiç ölçülmemişti. Ölçüm 120
/// sosyal hayatta şunu verdi:
///
/// | kategori | eşik | teklif | kabul |
/// |---|---|---|---|
/// | mahalle_kafe | 5.000 | 82 | 61 |
/// | kirtasiye | 6.000 | 61 | 50 |
/// | spor_icecegi | 9.000 | 59 | 43 |
/// | mobil_oyun | 5.000 | 51 | 37 |
/// | kitap_kulubu | 7.500 | 38 | 28 |
/// | yerel_lezzet | 12.000 | 12 | 11 |
/// | elektronik | 20.000 | 40 | 33 |
///
/// 120 hayatın 113'ü hesap açtı, 59'una teklif geldi (eşiği geçen hayat
/// sayısı 60 — yani 5.000 kapısını geçen hemen her hayat teklif alıyor).
/// Takipçi tavanı: medyan 5.852, en yüksek 7.285.623.
///
/// **Ölü içerik yok:** yedi kategorinin yedisi de teklif edildi. O
/// hipotez ölçümde öldü. `yerel_lezzet`'in seyrekliği (12) oyunun değil
/// **botun** izidir: bot hesabını `SocialPlatform.values` sırasına göre
/// açıyor, ilk sıradaki video platformunda kalıyor; `yerel_lezzet` video
/// dışındaki tek kategoridir. Bu bir BOT bulgusudur, katalog
/// değiştirilmedi.
///
/// **Gerçek bulgu ikisi de görünürlükte:** kabul edilen 263 anlaşmanın
/// **89'u (%34)** süresi dolup kırıldı ve bu yol baştan sona sessizdi:
///
/// 1. Kabul edilen anlaşma kartı süreyi **hiç yazmıyordu**. Motor iki
///    yıl sonra düşürüyor; kart yalnızca "paylaşım yapınca ödenecek"
///    diyordu.
/// 2. Cezanın kendisi (takipçinin %4'ü, tekrarlayınca %15'e kadar, artı
///    4 mutluluk) **yalnızca günlüğe** yazılıyordu. Teklifin kendisi
///    bildirim penceresi açıyor, cezası açmıyordu: oyun para teklif
///    edilince bağırıp cezayı fısıldıyordu.
///
/// İkisi de görünürlük düzeltmesidir; hiçbir sayı, süre ya da ceza
/// oranı değişmedi. Süre artık tek kaynaktan okunuyor
/// (`SocialIncome.deadlineAgeFor` / `lastActiveAgeFor`).
void main() {
  const SocialEngine sosyal = SocialEngine();

  GameState hayat({int seed = 21, int age = 25}) {
    final GameState base = LifeGenerator.seeded(
      seed,
    ).generate(mode: StartMode.tamamenRastgele);
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

  /// Yorum satırları atılmış kaynak (Paket DH dersi: DH'nin ilk tarama
  /// bulgularının üçü de kusuru **anlatan yorum satırlarıydı**).
  String kodu(String yol) => File(yol)
      .readAsLinesSync()
      .where((String l) {
        final String t = l.trimLeft();
        return !t.startsWith('//') && !t.startsWith('///');
      })
      .join('\n');

  group('Paket DL — süre tek kaynaktan gelir', () {
    test('§1 son yıl, sürenin sabitinden türer', () {
      const SponsorDeal anlasma = SponsorDeal(
        id: 'dl-1',
        categoryId: 'mahalle_kafe',
        platform: SocialPlatform.foto,
        fee: 9000,
        acceptedAtAge: 25,
      );
      expect(
        SocialIncome.deadlineAgeFor(anlasma),
        25 + SocialIncome.prototypeOnlyDealDeadline,
      );
      expect(
        SocialIncome.lastActiveAgeFor(anlasma),
        SocialIncome.deadlineAgeFor(anlasma) - 1,
      );
    });

    test('§2 motor ve ekran aynı sayıyı okur', () {
      final String motor = kodu('lib/domain/social/social_engine.dart');
      final String ekran = kodu('lib/ui/screens/sections/social_pages.dart');

      expect(
        motor,
        contains('SocialIncome.deadlineAgeFor'),
        reason: 'Motor süreyi işlevden okumalı.',
      );
      expect(
        motor.contains('newAge - d.acceptedAtAge'),
        isFalse,
        reason: 'Süre motorda ikinci kez türetilmemeli; tek kaynak '
            'deadlineAgeFor.',
      );
      expect(
        ekran,
        contains('SocialIncome.lastActiveAgeFor'),
        reason: 'Kartta yazan yıl sabitin kendisinden gelmeli; elle '
            'yazılan bir sayı sabit değişince ekranda yanlış kalır.',
      );
    });
  });

  group('Paket DL — ekranın sözü motorun davranışına uyar', () {
    test('§3 kartın söylediği son yılda paylaşım hâlâ ödüyor', () {
      GameState s = hesapli(hayat(), SocialPlatform.foto, 50000);
      const SponsorDeal anlasma = SponsorDeal(
        id: 'dl-2',
        categoryId: 'mahalle_kafe',
        platform: SocialPlatform.foto,
        fee: 50000,
        acceptedAtAge: 25,
      );
      s = s.copyWith(sponsorDeals: const <SponsorDeal>[anlasma]);

      final int sonYil = SocialIncome.lastActiveAgeFor(anlasma);
      // Ekranda yazan yıla kadar yıl geçsin; anlaşma düşmemiş olmalı.
      for (int yas = anlasma.acceptedAtAge + 1; yas <= sonYil; yas++) {
        s = sosyal.expireDeals(s, yas).state;
        s = s.copyWith(player: s.player.copyWith(age: yas));
        expect(
          s.openDeals,
          hasLength(1),
          reason: '$yas yaşında anlaşma hâlâ açık olmalı; kart son yılı '
              '$sonYil diyor.',
        );
      }

      // O yılda yapılan paylaşım ücreti **gerçekten** ödüyor.
      final SocialContent icerik = kSocialContents.firstWhere(
        (SocialContent c) => c.platform == SocialPlatform.foto,
      );
      final int cuzdan = s.player.wallet;
      final SocialResult r = sosyal.post(s, icerik, Random(3));
      expect(r.outcome.applied, isTrue, reason: r.outcome.text);
      expect(r.state.player.wallet, greaterThanOrEqualTo(cuzdan + 50000));
      expect(r.state.sponsorDeals.single.completedAtAge, sonYil);
      expect(r.state.sponsorDeals.single.expired, isFalse);
    });

    test('§4 bir yıl sonrası artık yok: ceza pencere açar', () {
      GameState s = hesapli(hayat(), SocialPlatform.foto, 50000);
      const SponsorDeal anlasma = SponsorDeal(
        id: 'dl-3',
        categoryId: 'mahalle_kafe',
        platform: SocialPlatform.foto,
        fee: 50000,
        acceptedAtAge: 25,
      );
      s = s.copyWith(sponsorDeals: const <SponsorDeal>[anlasma]);

      final int kitleOnce = s.totalFollowers;
      final int mutlulukOnce = s.player.stats.happiness;
      final int bildirimOnce = s.notices.length;

      final int dusmeYasi = SocialIncome.deadlineAgeFor(anlasma);
      final ({GameState state, List<String> logTexts}) sonuc = sosyal
          .expireDeals(s, dusmeYasi);

      expect(sonuc.state.sponsorDeals.single.expired, isTrue);
      expect(sonuc.state.totalFollowers, lessThan(kitleOnce));
      expect(
        sonuc.state.player.stats.happiness,
        lessThan(mutlulukOnce),
        reason: 'Ceza gerçekten uygulanıyor.',
      );

      // **Paket DL'nin düzelttiği kusur.** Önceden yalnızca günlük
      // satırı vardı; pencere yoktu.
      expect(
        sonuc.state.notices.length,
        bildirimOnce + 1,
        reason: 'Düşen anlaşma bir bildirim penceresi açmalı.',
      );
      final PendingNotice bildirim = sonuc.state.notices.last;
      expect(bildirim.id, 'sponsor-dusen-$dusmeYasi-${anlasma.id}');
      expect(bildirim.age, dusmeYasi);
      expect(
        bildirim.text,
        sonuc.logTexts.single,
        reason: 'Pencere ile günlük aynı cümleyi söylemeli.',
      );
      expect(
        bildirim.happinessDelta,
        sonuc.state.player.stats.happiness - mutlulukOnce,
        reason: 'Pencere **uygulanan** mutluluk farkını taşımalı, '
            'sabiti değil.',
      );
      expect(bildirim.text, contains('mahalle kafe zinciri'));
    });

    test('§5 mutluluk tabanındaysa pencere olmayan kaybı yazmaz', () {
      // Mutluluk 0'da `gain(-4)` hiçbir şey uygulamaz. Pencere bunu
      // "-4" diye yazarsa ekranda gerçekleşmemiş bir kayıp görünür —
      // Paket D'den beri yasak olan şey.
      GameState s = hesapli(hayat(), SocialPlatform.foto, 50000);
      s = s.copyWith(
        player: s.player.copyWith(
          stats: s.player.stats.copyWith(happiness: 0),
        ),
        sponsorDeals: const <SponsorDeal>[
          SponsorDeal(
            id: 'dl-4',
            categoryId: 'mahalle_kafe',
            platform: SocialPlatform.foto,
            fee: 50000,
            acceptedAtAge: 25,
          ),
        ],
      );

      final GameState sonra = sosyal
          .expireDeals(s, 25 + SocialIncome.prototypeOnlyDealDeadline)
          .state;
      expect(sonra.player.stats.happiness, 0);
      expect(sonra.notices.last.happinessDelta, 0);
    });
  });

  group('Paket DL — gerçek akışta ölçüm', () {
    test('§6 sponsor hunisi: katalog erişilebilir, ceza sessiz değil', () {
      const int adet = 120;
      final Map<String, int> teklif = <String, int>{};
      final Map<String, int> kabul = <String, int>{};
      int hesapAcan = 0;
      int teklifGelen = 0;
      int tamamlanan = 0;
      int sureDolan = 0;
      int takipciTavani = 0;
      int sessizDusme = 0;
      final List<String> sorunlar = <String>[];

      for (int i = 0; i < adet; i++) {
        final Set<String> gorulenTeklif = <String>{};
        final Set<int> pencereYaslari = <int>{};
        bool hesapVar = false;
        GameState? sonDurum;

        void bak(GameState s) {
          sonDurum = s;
          for (final SocialAccount a in s.socialAccounts) {
            hesapVar = true;
            if (a.followers > takipciTavani) takipciTavani = a.followers;
          }
          final SponsorOffer? o = s.sponsorOffer;
          if (o != null && gorulenTeklif.add(o.id)) {
            teklif[o.categoryId] = (teklif[o.categoryId] ?? 0) + 1;
            // Kapının sağlamlığı: teklif gelen hesap gerçekten
            // kategorinin eşiğini geçmiş olmalı.
            final SocialAccount? hesap = s.accountFor(o.platform);
            final SponsorCategory? kategori = sponsorCategoryById(
              o.categoryId,
            );
            if (hesap == null || kategori == null) {
              sorunlar.add('tohum ${51000 + i}: teklifin hesabı/kategorisi '
                  'çözülemedi (${o.id}).');
            } else if (!kategori.fits(hesap)) {
              sorunlar.add('tohum ${51000 + i}: ${kategori.id} eşiği '
                  '${kategori.minFollowers} iken ${hesap.followers} '
                  'takipçili hesaba teklif geldi.');
            }
          }
          for (final PendingNotice n in s.notices) {
            if (n.id.startsWith('sponsor-dusen-')) pencereYaslari.add(n.age);
          }
        }

        playBotLife(
          archetype: PlayerArchetype.social,
          seed: 51000 + i,
          onYear: bak,
          onPending: bak,
          onPreAge: bak,
        );

        if (hesapVar) hesapAcan++;
        if (gorulenTeklif.isNotEmpty) teklifGelen++;

        final GameState? son = sonDurum;
        if (son == null) continue;
        for (final SponsorDeal d in son.sponsorDeals) {
          kabul[d.categoryId] = (kabul[d.categoryId] ?? 0) + 1;
          if (d.completedAtAge != null) tamamlanan++;
          if (d.expired) sureDolan++;
        }
        // Oyunun **kendi kaydını** oku: düşme satırının yazıldığı her
        // yıl için bir pencere görülmüş olmalı. Tek istisna ölüm yılı:
        // o yıl pencere kapatılmadan hayat bitiyor.
        for (final LifeLogEntry e in son.log) {
          if (!e.text.contains('sponsorluğu için paylaşım yapmadın')) {
            continue;
          }
          if (pencereYaslari.contains(e.age)) continue;
          if (e.age >= son.player.age) continue;
          sessizDusme++;
          sorunlar.add('tohum ${51000 + i}: ${e.age} yaşında anlaşma '
              'düştü, pencere açılmadı.');
        }
      }

      // ignore: avoid_print
      print('DL HUNİSİ — $adet sosyal hayat · hesap açan $hesapAcan · '
          'teklif gelen $teklifGelen · takipçi tavanı $takipciTavani');
      // ignore: avoid_print
      print('  anlaşma: kabul ${kabul.values.fold(0, (int a, int b) => a + b)}'
          ' · tamamlanan $tamamlanan · süresi dolan $sureDolan · '
          'sessiz düşme $sessizDusme');
      for (final SponsorCategory c in kSponsorCategories) {
        // ignore: avoid_print
        print('  ${c.id.padRight(14)} eşik '
            '${c.minFollowers.toString().padLeft(6)} · teklif '
            '${(teklif[c.id] ?? 0).toString().padLeft(4)} · kabul '
            '${(kabul[c.id] ?? 0).toString().padLeft(4)}');
      }

      expect(sorunlar, isEmpty, reason: sorunlar.join('\n'));
      expect(
        teklifGelen,
        greaterThan(0),
        reason: 'Sponsorluk hattı hiç açılmıyorsa ölçüm anlamsız; '
            'ölçülen 59/120.',
      );
      expect(
        sureDolan,
        greaterThan(0),
        reason: 'Düşen anlaşma hiç yoksa §6 cezayı hiç sınamamış olur; '
            'ölçülen 89/263.',
      );
      expect(
        tamamlanan,
        greaterThan(0),
        reason: 'Tamamlanan anlaşma hiç yoksa ücret yolu ölçülmemiş '
            'olur; ölçülen 162/263.',
      );

      // **Dekoratif eşik taraması (Paket BA deseni 3).** Hiçbir
      // kategorinin eşiği hayatların gerçekten ulaştığı tavanın
      // üstünde olmamalı; olursa o kategori yazılmış ama ulaşılamaz
      // içeriktir. Tavan ölçümden gelir, elle yazılmaz.
      for (final SponsorCategory c in kSponsorCategories) {
        expect(
          c.minFollowers,
          lessThanOrEqualTo(takipciTavani),
          reason: '${c.id} eşiği ${c.minFollowers}; $adet hayatta '
              'ulaşılan en yüksek takipçi $takipciTavani.',
        );
      }
    });
  });
}

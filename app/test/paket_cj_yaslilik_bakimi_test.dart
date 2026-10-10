// Paket CJ — yaşlılıkta bakım: ailenin oyuncuya dönük tarafı.
//
// **Ölçülen eksik.** `ElderCare` (Paket AO §35-§36) oyuncunun yaşlı
// ebeveynine bakmasını modelliyor: para gerçekten çıkıyor, yakınlık
// gerçekten değişiyor. Tersi yoktu. 250 bot hayatı tarandı: oyuncu 70
// yaşını 185 hayatta gördü, 1356 yaşlılık yılı yaşandı, bu yılların
// 585'inde sağlık bandı düşüktü — ve **hiçbirinde** hiçbir aile üyesi
// oyuncu için bir şey yapmadı. Günlükte tek satır yoktu.
//
// **Durum kurulmuyor, aranıyor.** Bütün kareler bot hayatları
// oynatılarak bulunuyor; tek tarama beş ayrı kareyi birden toplar
// (yardımcısı olan yıl, kimsesi olmayan yıl, çocuk katkısı olan yıl,
// cepten çıkanı ödeyemeyen yıl, bandı iyi olan yıl). 200 hayatta bu
// beşinin hepsi bulundu: sırasıyla 238 / 343 / 193 / 17 / 549 kare.
//
// **Eşikler ölçümden geliyor**, güzel görünsün diye yazılmadı: hepsi
// taban (`greaterThan`) ve ölçülen sayının belirgin altında.
library;

import 'dart:math';

import 'package:bir_omur/data/save/game_state_codec.dart';
import 'package:bir_omur/domain/features/feature_catalog.dart';
import 'package:bir_omur/domain/interaction/elder_support.dart';
import 'package:bir_omur/domain/life/critical_health.dart';
import 'package:bir_omur/domain/models/game_state.dart';
import 'package:bir_omur/domain/models/life_log.dart';
import 'package:bir_omur/domain/models/person.dart';
import 'package:bir_omur/domain/models/wealth.dart';
import 'package:bir_omur/state/game_controller.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/player_bot.dart';

/// Taramada toplanan kareler.
class _Kareler {
  GameState? yardimcisiOlan;

  /// Yardımcısı olan **ve** etkisi ölçülebilen kare.
  ///
  /// Gerekçe: yaşlılıkta en yakın çocuğun bağı çoğu karede **tavanda**
  /// (ölçüm: ortanca 100, Q-205 bunu zaten soruyor). Tavandaki bağ
  /// artamayacağı için "yük bedava değil" testi bağa yer olan kareyi
  /// ister. Kare **aranıyor**, kurulmuyor; 200 hayatta 236 tane var.
  GameState? yardimcisiYeriOlan;
  int yeriOlanYil = 0;
  GameState? kimsesiOlmayan;
  GameState? katkisiOlan;
  GameState? parasiYetmeyen;
  GameState? bandiIyi;
  GameState? hapiste;

  int bakimYili = 0;
  int yardimciliYil = 0;
  int kimsesizYil = 0;
  int katkiliYil = 0;
  int kartGorenHayat = 0;

  /// Çocuk katkısı faturanın tavanını aştı mı? (Aşmamalı.)
  int tavanAsan = 0;

  /// Katkı veren çocuk gücü yetmeyen biri miydi? (Olmamalı.)
  int gucuYetmeyenKatkisi = 0;
}

/// Tek tarama: 200 hayat, bütün kareler burada toplanır.
_Kareler _tara() {
  final _Kareler k = _Kareler();
  for (final PlayerArchetype a in PlayerArchetype.values) {
    for (int seed = 1; seed <= 20; seed++) {
      bool kartGordu = false;
      playBotLife(
        archetype: a,
        seed: seed * 31 + a.index,
        // **Botun kendi kararı kapatıldı.** Bot kararı yılın başında
        // veriyor; `onPreAge` ondan sonra çalıştığı için taranan her
        // kare "bu yılın kararı verilmiş" oluyordu ve kapıların kendi
        // gerekçeleri hiç ölçülemiyordu (ilk koşuda altı test bu
        // yüzden 'Bu yılın kararını verdin.' gördü). Oyunun sayıları
        // değişmez; yalnızca botun tercihi kapanır.
        overrides: const BotOverrides(noElderSupport: true),
        onPreAge: (GameState s) {
          if (s.deceased) return;
          if (s.isImprisoned) k.hapiste ??= s;
          if (!ElderSupport.needsSupport(s)) {
            if (s.player.age >= 70 && !s.isImprisoned) k.bandiIyi ??= s;
            return;
          }
          kartGordu = true;
          k.bakimYili++;

          final List<Person> yardimcilar = ElderSupport.helpers(s);
          if (yardimcilar.isEmpty) {
            k.kimsesizYil++;
            k.kimsesiOlmayan ??= s;
          } else {
            k.yardimciliYil++;
            k.yardimcisiOlan ??= s;
            final bool bagaYer = yardimcilar.first.bond <=
                100 - ElderSupport.prototypeOnlyCompanyBond - 1;
            final bool mutlulugaYer = s.player.stats.happiness <=
                100 - ElderSupport.prototypeOnlyCompanyHappiness;
            if (bagaYer && mutlulugaYer) {
              k.yeriOlanYil++;
              k.yardimcisiYeriOlan ??= s;
            }
          }

          final ({int amount, List<String> names, List<String> ids}) katki =
              ElderSupport.contribution(s);
          if (katki.amount > 0) {
            k.katkiliYil++;
            k.katkisiOlan ??= s;
            final int tavan = (ElderSupport.yearlyCost() *
                    ElderSupport.prototypeOnlyMaxChildShare)
                .round();
            if (katki.amount > tavan) k.tavanAsan++;
            for (final String id in katki.ids) {
              final Person? c = s.personById(id);
              if (c == null ||
                  c.wealth == null ||
                  c.wealth == WealthTier.yoksul ||
                  c.wealth == WealthTier.cokYoksul) {
                k.gucuYetmeyenKatkisi++;
              }
            }
          }
          if (s.player.wallet < ElderSupport.outOfPocket(s)) {
            k.parasiYetmeyen ??= s;
          }
        },
      );
      if (kartGordu) k.kartGorenHayat++;
    }
  }
  return k;
}

/// Bulunan kareyi oynanabilir hâle getirir (kurmaz, bulunanı yükler).
GameController _denetleyici(GameState durum) =>
    GameController(random: Random(7))..debugSetState(durum);

/// 70 yaşından sonra günlüğe düşen bakım satırları.
List<String> _bakimSatirlari(GameState s) => s.log
    .where((LifeLogEntry e) =>
        e.age >= ElderSupport.prototypeOnlyMinAge &&
        (e.text.contains('yanında oldu') ||
            e.text.contains('bakım masraf') ||
            e.text.contains('Bakımın için') ||
            e.text.contains('kimseye yüklenmeden')))
    .map((LifeLogEntry e) => e.text)
    .toList(growable: false);

void main() {
  final _Kareler kareler = _tara();

  group('Paket CJ §1 — karar gerçekten çıkıyor', () {
    test('yaşlılıkta bakım kararı 200 hayatta çok kez doğuyor', () {
      // Ölçüm: 581 bakım yılı, 160 hayat kartı gördü. Taban bunun
      // belirgin altında; amaç sayıyı dondurmak değil, kapının
      // tamamen kapanmasını yakalamak.
      expect(kareler.bakimYili, greaterThan(200),
          reason: 'bakım gerektiren yıl neredeyse hiç doğmuyor');
      expect(kareler.kartGorenHayat, greaterThan(60),
          reason: 'oyuncuların çok azı bu kararı görüyor');
    });

    test('her iki uç da yaşanıyor: yanında olan da var, kimsesi de yok', () {
      // Ölçüm: 238 yıl yardımcısı var, 343 yıl kimse yok. Bu ayrım
      // paketin bütün anlamı: yaşlılık, kurulan ailenin karşılığıdır.
      expect(kareler.yardimciliYil, greaterThan(80),
          reason: 'yanında kimsenin olabildiği yıl yok gibi');
      expect(kareler.kimsesizYil, greaterThan(80),
          reason: 'kimsesiz yaşlılık hiç yaşanmıyor');
    });

    test('modül kapalıyken yaşlılık Paket CJ öncesi gibi geçiyor', () {
      for (final int seed in <int>[31, 62, 93]) {
        final BotLifeResult kapali = playBotLife(
          archetype: PlayerArchetype.family,
          seed: seed,
          features: FeatureSwitches.defaults
              .toggled(FeatureId.yaslilikBakimi, false),
        );
        expect(kapali.elderSupportNeedYears, 0,
            reason: 'tohum $seed: modül kapalı ama karar çıktı');
        expect(
          kapali.elderSupportFamilyYears +
              kapali.elderSupportMoneyYears +
              kapali.elderSupportAloneYears,
          0,
          reason: 'tohum $seed: modül kapalı ama kapı kullanıldı',
        );
      }
      // Açıkken aynı arketip kararı gerçekten görüyor: kapalı ölçümün
      // sıfırları "zaten hiç olmuyor"dan değil, anahtardan geliyor.
      int acikYil = 0;
      for (final int seed in <int>[31, 62, 93]) {
        acikYil += playBotLife(
          archetype: PlayerArchetype.family,
          seed: seed,
        ).elderSupportNeedYears;
      }
      expect(acikYil, greaterThan(0),
          reason: 'modül açıkken de karar çıkmıyor; karşılaştırma boş');
    });
  });

  group('Paket CJ §2 — kapılar ve bedelleri', () {
    test('yanında kimse yokken aile kapısı gerekçesiyle kapalı', () {
      final GameState? kare = kareler.kimsesiOlmayan;
      expect(kare, isNotNull, reason: 'kimsesiz bakım yılı bulunamadı');
      expect(
        ElderSupport.blockReason(kare!, ElderSupportChoice.aileyeYuklen),
        'Yanında olabilecek kimse yok.',
      );
      // Kapalı kapı zorlanınca durum değişmez.
      final ElderSupportResult sonuc = ElderSupport.apply(
        state: kare,
        choice: ElderSupportChoice.aileyeYuklen,
        rng: Random(1),
      );
      expect(identical(sonuc.state, kare), isTrue,
          reason: 'kapalı kapı durumu değiştirdi');
    });

    test('ailene yüklenmek bedava değil: yük omuzlayanın üstünde', () {
      // Bağı tavanda olmayan kare: ölçümde 200 hayatta 236 tane var.
      expect(kareler.yeriOlanYil, greaterThan(20),
          reason: 'etkisi ölçülebilen kare neredeyse kalmamış; bağ '
              'tavanı (Q-205) bütün kareleri yutuyor olabilir');
      final GameState? kare = kareler.yardimcisiYeriOlan;
      expect(kare, isNotNull, reason: 'yardımcısı olan bakım yılı yok');
      final Person yardimci = ElderSupport.helpers(kare!).first;
      final GameController c = _denetleyici(kare);
      addTearDown(c.dispose);

      final int oncekiMutluluk = kare.player.stats.happiness;
      final int oncekiCuzdan = kare.player.wallet;
      c.decideElderSupport(ElderSupportChoice.aileyeYuklen,
          helperId: yardimci.id);
      final GameState sonra = c.state!;
      final Person sonrakiYardimci = sonra.personById(yardimci.id)!;

      expect(sonra.player.stats.happiness, greaterThan(oncekiMutluluk),
          reason: 'yanında olunca oyuncunun mutluluğu değişmedi');
      expect(sonra.player.wallet, oncekiCuzdan,
          reason: 'bu kapı para harcamaz');
      expect(sonrakiYardimci.bond, greaterThan(yardimci.bond),
          reason: 'yanında olan kişinin yakınlığı artmadı');
      expect(sonrakiYardimci.happiness, lessThan(yardimci.happiness),
          reason: 'bakım yükü omuzlayanda bedelsiz kaldı');
      expect(sonra.elderSupport.yearsSupported,
          kare.elderSupport.yearsSupported + 1);
      expect(sonra.elderSupport.lastHelperId, yardimci.id);
      expect(_bakimSatirlari(sonra).length,
          greaterThan(_bakimSatirlari(kare).length),
          reason: 'günlüğe satır düşmedi');
    });

    test('bakım masrafı gerçekten cepten çıkıyor', () {
      final GameState? kare = kareler.katkisiOlan;
      expect(kare, isNotNull, reason: 'çocuk katkısı olan yıl bulunamadı');
      final int cepten = ElderSupport.outOfPocket(kare!);
      final int katki = ElderSupport.contribution(kare).amount;
      expect(cepten, greaterThan(0),
          reason: 'katkı faturanın tamamını kapatmamalı (ECO-001)');
      expect(cepten + katki, ElderSupport.yearlyCost(),
          reason: 'cepten + katkı faturayı vermiyor');

      final GameController c = _denetleyici(kare);
      addTearDown(c.dispose);
      final int oncekiCuzdan = kare.player.wallet;
      c.decideElderSupport(ElderSupportChoice.bakimiOdet);
      final GameState sonra = c.state!;

      expect(sonra.player.wallet, oncekiCuzdan - cepten,
          reason: 'cüzdandan tam olarak cepten çıkan kadar inmedi');
      expect(sonra.elderSupport.paidTotal,
          kare.elderSupport.paidTotal + cepten);
      expect(sonra.elderSupport.receivedTotal,
          kare.elderSupport.receivedTotal + katki);
    });

    test('havadan para yok: gücü yetmeyen çocuk üstlenmez, pay tavanı aşmaz',
        () {
      // Tarama boyunca sayıldı; tek bir ihlal bile testi kırar.
      expect(kareler.katkiliYil, greaterThan(50),
          reason: 'katkı veren çocuk hiç bulunamadı, kural ölçülemiyor');
      expect(kareler.tavanAsan, 0,
          reason: 'çocukların payı faturanın tavanını aştı');
      expect(kareler.gucuYetmeyenKatkisi, 0,
          reason: 'geçimi zor olan çocuk faturaya katıldı');
    });

    test('parası yetmeyene ödeme kapısı açılmıyor', () {
      final GameState? kare = kareler.parasiYetmeyen;
      expect(kare, isNotNull,
          reason: 'cepten çıkanı ödeyemeyen bakım yılı bulunamadı');
      expect(
        ElderSupport.blockReason(kare!, ElderSupportChoice.bakimiOdet),
        'Bu yıl bakım masrafını karşılayacak paran yok.',
      );
      final ElderSupportResult sonuc = ElderSupport.apply(
        state: kare,
        choice: ElderSupportChoice.bakimiOdet,
        rng: Random(2),
      );
      expect(identical(sonuc.state, kare), isTrue,
          reason: 'para yokken ödeme yapılmış gibi davranıldı');
      expect(kare.player.wallet, greaterThanOrEqualTo(0),
          reason: 'cüzdan eksiye düşmüş bir kare taradık');
    });

    test('kendin idare etmek açık kalır ve kimseyi yormaz', () {
      final GameState? kare = kareler.kimsesiOlmayan;
      expect(kare, isNotNull);
      expect(
        ElderSupport.blockReason(kare!, ElderSupportChoice.kendiIdareEt),
        '',
        reason: 'son kapı da kapanırsa oyuncu yılı çeviremez',
      );
      final GameController c = _denetleyici(kare);
      addTearDown(c.dispose);
      c.decideElderSupport(ElderSupportChoice.kendiIdareEt);
      final GameState sonra = c.state!;
      expect(sonra.player.wallet, kare.player.wallet);
      expect(sonra.elderSupport.yearsAlone, kare.elderSupport.yearsAlone + 1);
      expect(sonra.elderSupport.yearsSupported,
          kare.elderSupport.yearsSupported);
    });

    test('aynı yıl ikinci karar yok (D-096 yılın kararı birdir)', () {
      final GameState? kare = kareler.yardimcisiOlan;
      expect(kare, isNotNull);
      final GameController c = _denetleyici(kare!);
      addTearDown(c.dispose);
      c.decideElderSupport(ElderSupportChoice.kendiIdareEt);
      final GameState ilkSonra = c.state!;
      expect(c.elderSupportDecided, isTrue);
      for (final ElderSupportChoice secim in ElderSupportChoice.values) {
        expect(c.elderSupportBlockReason(secim), 'Bu yılın kararını verdin.',
            reason: '$secim aynı yıl ikinci kez açıldı');
      }
      c.decideElderSupport(ElderSupportChoice.aileyeYuklen);
      expect(c.state!.elderSupport.yearsSupported,
          ilkSonra.elderSupport.yearsSupported,
          reason: 'aynı yıl ikinci karar işledi');
      expect(c.state!.player.stats.happiness, ilkSonra.player.stats.happiness);
    });
  });

  group('Paket CJ §3 — kapı hiç açılmayan durumlar', () {
    test('bandı iyi ve 80 altındaki oyuncuya kart çıkmıyor', () {
      final GameState? kare = kareler.bandiIyi;
      expect(kare, isNotNull, reason: 'bandı iyi yaşlılık yılı bulunamadı');
      expect(CriticalHealth.bandFor(kare!).isLow, isFalse);
      expect(kare.player.age, lessThan(ElderSupport.prototypeOnlyFrailAge));
      expect(ElderSupport.needsSupport(kare), isFalse);
      expect(
        ElderSupport.blockReason(kare, ElderSupportChoice.aileyeYuklen),
        'Şimdilik bu yılı kendi başına çevirebiliyorsun.',
      );
    });

    test('cezaevindeyken kapı gerekçesiyle kapalı (Paket CG kuralı)', () {
      // 70 yaşından sonra hapiste geçen yıl 200 hayatta **bir** kez
      // bulundu; kalıcı bekçi o tek kareye yaslanmasın diye kural
      // sık bulunan karede ölçülüyor: içeride oyuncu bu işi çeviremez.
      final GameState? kare = kareler.hapiste;
      expect(kare, isNotNull, reason: 'cezaevinde kare bulunamadı');
      expect(ElderSupport.needsSupport(kare!), isFalse);
      expect(
        ElderSupport.blockReason(kare, ElderSupportChoice.bakimiOdet),
        'Cezaevindesin; bu işi buradan çeviremezsin.',
      );
    });

    test('modül kapalıyken karar hiç doğmaz', () {
      final GameState? kare = kareler.yardimcisiOlan;
      expect(kare, isNotNull);
      final GameState kapali = kare!.copyWith(
        settings: kare.settings.copyWith(
          features: kare.settings.features
              .toggled(FeatureId.yaslilikBakimi, false),
        ),
      );
      expect(ElderSupport.needsSupport(kapali), isFalse);
      expect(ElderSupport.helpers(kapali), isEmpty);
      final ElderSupportResult sonuc = ElderSupport.apply(
        state: kapali,
        choice: ElderSupportChoice.aileyeYuklen,
        rng: Random(3),
      );
      expect(identical(sonuc.state, kapali), isTrue,
          reason: 'modül kapalıyken karar işledi');
    });
  });

  group('Paket CJ §4 — kayıt', () {
    test('sayaçlar kaydedilip geri yükleniyor', () {
      final GameState? kare = kareler.yardimcisiOlan;
      expect(kare, isNotNull);
      final Person yardimci = ElderSupport.helpers(kare!).first;
      final GameController c = _denetleyici(kare);
      addTearDown(c.dispose);
      c.decideElderSupport(ElderSupportChoice.aileyeYuklen,
          helperId: yardimci.id);
      final GameState sonra = c.state!;

      final GameState geri = decodeGameState(encodeGameState(sonra));
      expect(geri.elderSupport.yearsSupported,
          sonra.elderSupport.yearsSupported);
      expect(geri.elderSupport.yearsAlone, sonra.elderSupport.yearsAlone);
      expect(geri.elderSupport.lastDecidedAge,
          sonra.elderSupport.lastDecidedAge);
      expect(geri.elderSupport.lastHelperId, sonra.elderSupport.lastHelperId);
      expect(geri.elderSupport.receivedTotal,
          sonra.elderSupport.receivedTotal);
      expect(geri.elderSupport.paidTotal, sonra.elderSupport.paidTotal);
    });

    test('eski kayıtta alan yoksa sayaçlar sıfırdan başlar', () {
      final GameState? kare = kareler.yardimcisiOlan;
      expect(kare, isNotNull);
      final Map<String, Object?> govde = encodeGameState(kare!);
      govde.remove('elderSupport');
      final GameState geri = decodeGameState(govde);
      expect(geri.elderSupport.isEmpty, isTrue,
          reason: 'eski kayıt geriye dönük bakım geçmişi uydurdu');
    });

    test('kayıtta olmayan kişiye işaret eden yardımcı kimliği düşürülür', () {
      final GameState? kare = kareler.yardimcisiOlan;
      expect(kare, isNotNull);
      final Map<String, Object?> govde = encodeGameState(kare!);
      govde['elderSupport'] = <String, Object?>{
        'yearsSupported': 3,
        'yearsAlone': 1,
        'lastDecidedAge': 72,
        'lastHelperId': 'kayitta-olmayan-kisi',
        'receivedTotal': 1000,
        'paidTotal': 2000,
      };
      final GameState geri = decodeGameState(govde);
      expect(geri.elderSupport.lastHelperId, isNull,
          reason: 'silinmiş kişiye işaret eden kimlik kayda girdi');
      expect(geri.elderSupport.yearsSupported, 3,
          reason: 'sayaç kimlikle birlikte düşürüldü');
    });
  });
}

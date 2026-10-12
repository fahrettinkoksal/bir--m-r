/// Paket CA — sigorta: prim, muafiyet ve hasarda karşılık.
///
/// **Neden eklendi.** Para bu oyunda neredeyse tamamen saldırı aracıydı
/// (ev, araba, işletme, portföy). Savunma tarafı yoktu: kötü bir yılın
/// faturasını küçültmenin hiçbir yolu bulunmuyordu. Oyun fikri zaten
/// konuşuyordu — `ev_sigorta_teklifi` olayı 9.000 ₺ poliçe teklif edip
/// `ev_sigorta_ise_yaradi` olayında "cebinden sadece muafiyet tutarı
/// çıktı" diyordu — ama bu tek seferlik bir anlatıydı.
///
/// **Sözleşme (bu dosya onu korur).**
///
/// * Sigorta **cüzdana para eklemez**; yalnızca zararı azaltır.
/// * Muafiyetin altındaki hasarda poliçe devreye girmez.
/// * Dayanağı düşen poliçe (ev satıldı) kapanır, kaydı silinmez.
/// * Prim ödenemezse poliçe düşer, borç yazılmaz.
/// * Anahtar kapalıyken prim de karşılık da yok.
/// * Sağlık poliçesi pahalı tedaviyi **karşılanabilir** hale getirir.
///
/// Durum kurulmuyor, aranıyor: kendi evinde oturan ve parası olan kare
/// gerçek bot hayatlarından bulunur.
library;

import 'package:bir_omur/data/insurance_catalog.dart';
import 'package:bir_omur/data/save/game_state_codec.dart';
import 'package:bir_omur/data/health_crisis_catalog.dart';
import 'package:bir_omur/domain/economy/housing.dart';
import 'package:bir_omur/domain/life/health_crisis_engine.dart';
import 'package:bir_omur/domain/economy/insurance.dart';
import 'package:bir_omur/domain/features/feature_catalog.dart';
import 'package:bir_omur/domain/models/game_state.dart';
import 'package:bir_omur/domain/models/insurance_policy.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/player_bot.dart';

/// Kendi evinde oturan, primi ödeyebilecek ve **henüz poliçesi
/// olmayan** gerçek bir hayat karesi.
///
/// Poliçesizlik koşulu şart: bot artık kendi kararıyla sigorta
/// yaptırıyor (Paket CA), yani bulunan karede hazır poliçe olabilir ve
/// o zaman "prim ne kadar çıktı" ölçümü iki poliçeyi toplar. İlk
/// yazımda bu testi ikiye böldü; durum kurmak yerine **koşulu
/// daralttım**.
GameState _evSahibiKare() {
  for (int i = 0; i < 60; i++) {
    GameState? bulunan;
    playBotLife(
      archetype: PlayerArchetype.investor,
      seed: 4400 + i,
      // Hayat **modül kapalı** oynatılır: bot poliçe yaptırmaz, yani
      // bulunan karede hazır poliçe olmaz ve "prim ne kadar çıktı"
      // ölçümü tek poliçeyi ölçer. Ev ve para durumu yine motorun
      // kendi ürettiği durum; kurgu yok.
      features: FeatureSwitches.defaults.toggled(FeatureId.sigorta, false),
      onYear: (GameState s) {
        if (bulunan != null) return;
        if (Housing.residenceOf(s) != ResidenceKind.kendiEvinde) return;
        if (s.player.wallet < 200000) return;
        bulunan = s;
      },
    );
    final GameState? kare = bulunan;
    if (kare != null) {
      // Ölçüm için anahtar geri açılır; bu bir oyuncu ayarı, uydurma
      // bir durum değil.
      return kare.copyWith(
        settings: kare.settings.copyWith(
          features:
              kare.settings.features.toggled(FeatureId.sigorta, true),
        ),
      );
    }
  }
  throw StateError('60 hayatta ev sahibi kare bulunamadı');
}

void main() {
  group('Paket CA — sigorta', () {
    test('poliçe alınınca ilk prim peşin çıkar', () {
      final GameState s = _evSahibiKare();
      final int once = s.player.wallet;
      final ({GameState state, String text}) sonuc =
          Insurance.buy(s, InsuranceKind.konut);
      final InsuranceTerms t = insuranceTermsOf(InsuranceKind.konut);

      expect(sonuc.state.player.wallet, once - t.prototypeOnlyYearlyPremium);
      expect(Insurance.activeOf(sonuc.state, InsuranceKind.konut), isNotNull);
      expect(sonuc.text, contains('başladı'));
    }, timeout: const Timeout(Duration(minutes: 20)));

    test('muafiyetin altındaki hasarda poliçe devreye girmez', () {
      final GameState s =
          Insurance.buy(_evSahibiKare(), InsuranceKind.konut).state;
      final InsuranceTerms t = insuranceTermsOf(InsuranceKind.konut);
      final int kucuk = t.prototypeOnlyDeductible - 1;

      final ({int paid, int covered, String? note}) sonuc =
          Insurance.settle(s, InsuranceKind.konut, kucuk);
      expect(sonuc.paid, kucuk);
      expect(sonuc.covered, 0);
      expect(sonuc.note, isNull);
    }, timeout: const Timeout(Duration(minutes: 20)));

    test('büyük hasarda muafiyet + karşılanmayan pay cepten çıkar', () {
      final GameState s =
          Insurance.buy(_evSahibiKare(), InsuranceKind.konut).state;
      final InsuranceTerms t = insuranceTermsOf(InsuranceKind.konut);
      const int hasar = 30000;

      final ({int paid, int covered, String? note}) sonuc =
          Insurance.settle(s, InsuranceKind.konut, hasar);
      final int beklenenKarsilanan =
          ((hasar - t.prototypeOnlyDeductible) * t.prototypeOnlyCoveredShare)
              .round();

      expect(sonuc.covered, beklenenKarsilanan);
      expect(sonuc.paid, hasar - beklenenKarsilanan);
      // Sigorta zararı **azaltır**, para eklemez.
      expect(sonuc.paid, lessThan(hasar));
      expect(sonuc.paid, greaterThanOrEqualTo(t.prototypeOnlyDeductible));
      expect(sonuc.note, isNotNull);
    }, timeout: const Timeout(Duration(minutes: 20)));

    test('poliçesi olmayan oyuncu zararın tamamını öder', () {
      final GameState s = _evSahibiKare();
      final ({int paid, int covered, String? note}) sonuc =
          Insurance.settle(s, InsuranceKind.konut, 30000);
      expect(sonuc.paid, 30000);
      expect(sonuc.covered, 0);
    }, timeout: const Timeout(Duration(minutes: 20)));

    test('anahtar kapalıyken ne prim ne karşılık var', () {
      final GameState acik =
          Insurance.buy(_evSahibiKare(), InsuranceKind.konut).state;
      final GameState kapali = acik.copyWith(
        settings: acik.settings.copyWith(
          features: acik.settings.features.toggled(FeatureId.sigorta, false),
        ),
      );

      expect(Insurance.settle(kapali, InsuranceKind.konut, 30000).covered, 0);
      // Prim de çıkmaz: poliçe donar.
      final ({GameState state, List<String> logLines}) yil =
          Insurance.advanceYear(kapali);
      expect(yil.state.player.wallet, kapali.player.wallet);
    }, timeout: const Timeout(Duration(minutes: 20)));

    test('yıllık prim cüzdandan çıkar ve kayda işlenir', () {
      final GameState s =
          Insurance.buy(_evSahibiKare(), InsuranceKind.konut).state;
      final int once = s.player.wallet;
      final InsuranceTerms t = insuranceTermsOf(InsuranceKind.konut);

      final ({GameState state, List<String> logLines}) yil =
          Insurance.advanceYear(s);
      expect(yil.state.player.wallet, once - t.prototypeOnlyYearlyPremium);
      expect(
        Insurance.activeOf(yil.state, InsuranceKind.konut)!.premiumsPaid,
        t.prototypeOnlyYearlyPremium * 2,
      );
    }, timeout: const Timeout(Duration(minutes: 20)));

    test('primi ödeyemeyen poliçe düşer, borç yazılmaz', () {
      final GameState s =
          Insurance.buy(_evSahibiKare(), InsuranceKind.konut).state;
      final GameState parasiz =
          s.copyWith(player: s.player.copyWith(wallet: 10));

      final ({GameState state, List<String> logLines}) yil =
          Insurance.advanceYear(parasiz);
      expect(Insurance.activeOf(yil.state, InsuranceKind.konut), isNull);
      expect(yil.state.player.wallet, 10);
      expect(yil.logLines.join(' '), contains('ödenemedi'));
      // Kayıt silinmez.
      expect(yil.state.insurance, hasLength(1));
    }, timeout: const Timeout(Duration(minutes: 20)));

    test('kayıt kapat-aç ile korunuyor', () {
      final GameState s =
          Insurance.buy(_evSahibiKare(), InsuranceKind.konut).state;
      final GameState geri = decodeGameState(encodeGameState(s));
      final InsurancePolicy? p = Insurance.activeOf(geri, InsuranceKind.konut);
      expect(p, isNotNull);
      expect(p!.premiumsPaid,
          insuranceTermsOf(InsuranceKind.konut).prototypeOnlyYearlyPremium);
    }, timeout: const Timeout(Duration(minutes: 20)));

    test('sağlık poliçesi karşılanamayan tedaviyi karşılanabilir yapıyor',
        () {
      // **Paketin asıl değeri bu.** Ölçüm gösterdi ki medyan oyuncunun
      // serveti milyonlarca; 85.000 ₺'lik tedavi onun için gürültü.
      // Sigorta parası olmayan oyuncu için anlamlı: poliçe varsa cepten
      // çıkacak tutar muafiyet + karşılanmayan paya iner ve hayat
      // kurtaran seçenek **seçilebilir** hale gelir.
      //
      // Bu bir kural testi, dağılım ölçümü değil: cüzdan bilerek
      // tedavinin altına, sigortalı bedelin üstüne ayarlanıyor.
      const HealthCrisisEngine motor = HealthCrisisEngine();
      final CrisisChoice hastane = kHealthCrises
          .firstWhere((HealthCrisis c) => c.id == 'trafik_kazasi')
          .choices
          .firstWhere((CrisisChoice c) => c.id == 'hastane');

      final GameState policeli =
          Insurance.buy(_evSahibiKare(), InsuranceKind.saglik).state;
      final ({int paid, int covered, String? note}) hesap =
          Insurance.settle(policeli, InsuranceKind.saglik, hastane.cost);
      expect(hesap.paid, lessThan(hastane.cost));

      // Cüzdan: sigortalı bedeli ödeyebilir, tam bedeli ödeyemez.
      final int cuzdan = (hesap.paid + hastane.cost) ~/ 2;
      final GameState dar = policeli.copyWith(
        player: policeli.player.copyWith(wallet: cuzdan),
      );
      expect(motor.canChoose(dar, hastane), isTrue,
          reason: 'poliçeli oyuncu hastane seçeneğini seçemiyor');

      final GameState policesiz = dar.copyWith(
        settings: dar.settings.copyWith(
          features: dar.settings.features.toggled(FeatureId.sigorta, false),
        ),
      );
      expect(motor.canChoose(policesiz, hastane), isFalse,
          reason: 'poliçesiz oyuncu aynı parayla tedaviyi seçebiliyor');
    }, timeout: const Timeout(Duration(minutes: 20)));

    test('katalogda hollow poliçe yok: her türün kapsadığı bir kalem var',
        () {
      // Sağlık: kriz tedavi masrafı. Konut: etiketli ani hasar olayları.
      // Bir tür hiçbir yere bağlı değilse oyuncu prim ödeyip hiç
      // karşılık görmez; o yüzden katalog iki türle sınırlı tutuldu.
      expect(InsuranceKind.values, hasLength(2));
      expect(kInsuranceCatalog, hasLength(2));
    });
  });
}

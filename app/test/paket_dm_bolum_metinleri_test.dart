import 'dart:io';

import 'package:bir_omur/domain/career/military_service.dart';
import 'package:bir_omur/domain/economy/banking.dart';
import 'package:bir_omur/domain/economy/insurance.dart';
import 'package:bir_omur/domain/models/game_state.dart';
import 'package:bir_omur/data/insurance_catalog.dart';
import 'package:bir_omur/domain/models/military.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/player_bot.dart';

/// **Paket DM — bölüm sayfalarının metin kusurları.**
///
/// Üçü de `sections/` dökümü ilk kez açılınca gözle okunarak çıktı;
/// hiçbiri birim testle görünmüyordu çünkü o sayfaların içine kimse
/// girmiyordu.
///
/// 1. Sigorta kartı tutarı ham basıyordu ("5000 ₺"). Paket BE'nin
///    bekçisi sıkıştırıldı ve tarama **ikinci** bir yer buldu; o
///    bekçi `paket_be_para_bicimi_test.dart` içinde.
/// 2. Banka kartı hiç kredi almamış oyuncuya "Ödemelerin düzenli"
///    diyordu.
/// 3. Askerlik sayfasının başlığı "Yapılmadı" yazarken üç satır
///    altındaki Durum alanı "Yükümlü değil" diyordu.
///
/// **Durum kurulmuyor, aranıyor:** aşağıdaki kareler bot hayatlarından
/// bulunuyor.
void main() {
  /// Botla oynanan hayatlardan koşula uyan ilk temiz kareyi bulur.
  GameState? kareBul(
    bool Function(GameState) kosul, {
    List<PlayerArchetype> arketipler = const <PlayerArchetype>[
      PlayerArchetype.casual,
      PlayerArchetype.investor,
      PlayerArchetype.career,
      PlayerArchetype.family,
    ],
    int tohumSayisi = 30,
  }) {
    GameState? bulunan;
    for (final PlayerArchetype a in arketipler) {
      for (int t = 0; t < tohumSayisi; t++) {
        if (bulunan != null) return bulunan;
        void bak(GameState s) {
          if (bulunan != null || s.deceased) return;
          if (kosul(s)) bulunan = s;
        }

        playBotLife(
          archetype: a,
          seed: 71000 + t,
          onYear: bak,
          onPreAge: bak,
        );
      }
    }
    return bulunan;
  }

  /// Yorum satırları atılmış kaynak (Paket DH dersi).
  String kodu(String yol) => File(yol)
      .readAsLinesSync()
      .where((String l) {
        final String t = l.trimLeft();
        return !t.startsWith('//') && !t.startsWith('///');
      })
      .join('\n');

  group('§1 banka: olmayan ödeme geçmişi iddia edilmez', () {
    test('kredisi olmayan oyuncuya "ödemelerin düzenli" denmez', () {
      final GameState? kare = kareBul(
        (GameState s) =>
            s.player.age >= Banking.prototypeOnlyMinAge && s.loans.isEmpty,
      );
      expect(kare, isNotNull, reason: 'Kredisiz yetişkin kare bulunamadı.');
      final GameState s = kare!;

      expect(Banking.hasCreditHistory(s), isFalse);
      expect(Banking.standingOf(s), CreditStanding.iyi,
          reason: 'Yükü olmayanın karnesi "İyi" kalır; değişen yalnızca '
              'gerekçe cümlesidir.');
      final String gerekce = Banking.standingReason(s);
      expect(
        gerekce.contains('Ödemelerin düzenli'),
        isFalse,
        reason: 'Hiç taksit ödememiş oyuncuya ödeme geçmişi atfediliyor: '
            '"$gerekce"',
      );
      expect(gerekce, contains('kredi geçmişin yok'));
    });

    test('kredisi olan ve taksidini kaçırmayan oyuncu eski cümleyi alır',
        () {
      final GameState? kare = kareBul(
        (GameState s) =>
            s.loans.isNotEmpty &&
            Banking.missedPayments(s) == 0 &&
            Banking.standingOf(s) == CreditStanding.iyi,
        arketipler: const <PlayerArchetype>[
          PlayerArchetype.investor,
          PlayerArchetype.entrepreneur,
          PlayerArchetype.career,
        ],
        tohumSayisi: 40,
      );
      if (kare == null) {
        // Bulunamamak ürün hatası değil; ama sessizce geçmesin.
        // ignore: avoid_print
        print('UYARI: kredisi olup taksidini kaçırmayan kare '
            'BULUNAMADI; §1in ikinci yarısı bu koşuda sınanmadı.');
        return;
      }
      expect(Banking.hasCreditHistory(kare), isTrue);
      expect(
        Banking.standingReason(kare),
        CreditStanding.iyi.description,
        reason: 'Geçmişi olan oyuncuda gerekçe değişmemeli.',
      );
    });

    test('banka kartı gerekçeyi duruma göre okur', () {
      // **Neden kaynak taraması da gerekiyor.** Üstteki test
      // `Banking.standingReason`'ı sınıyor; ekran yine ham
      // `karne.description` okursa o test geçmeye devam eder ve kusur
      // geri gelir. Bu, Paket DH'nin tam tersi dersidir: orada tarama
      // yorum satırlarını yakalayıp yanlış alarm vermişti, burada
      // taramasız iddia **eksik** kalıyor.
      final String ekran = kodu('lib/ui/screens/sections/bank_page.dart');
      expect(ekran, contains('Banking.standingReason(state)'));
      expect(
        ekran.contains('karne.description'),
        isFalse,
        reason: 'Ekran gerekçeyi yine ham enum alanından okuyor.',
      );
    });
  });

  group('§2 askerlik: başlık ve durum aynı şeyi söyler', () {
    test('yükümlü olmayan karede iki etiket ayrışıyor', () {
      final GameState? kare = kareBul(
        (GameState s) =>
            s.player.age >= MilitaryService.prototypeOnlyMinAge &&
            !MilitaryService.isObliged(s) &&
            s.military.status == MilitaryStatus.yok,
      );
      expect(kare, isNotNull, reason: 'Yükümlü olmayan kare bulunamadı.');
      final GameState s = kare!;

      // Hatanın **neden** görünmediğini sabitler: ham etiket ile
      // durum etiketi gerçekten farklı şeyler söylüyor.
      expect(s.military.label, 'Yapılmadı');
      expect(MilitaryService.statusLabel(s), 'Yükümlü değil');
    });

    test('sayfa başlığı durum etiketinden gelir', () {
      final String ekran = kodu('lib/ui/screens/sections/military_page.dart');
      expect(
        ekran,
        contains('subtitle: MilitaryService.statusLabel(state)'),
        reason: 'Başlık altı, Durum alanıyla aynı kaynaktan okumalı.',
      );
      expect(
        ekran.contains('subtitle: askerlik.label'),
        isFalse,
        reason: 'Ham etiket geri geldi: yükümlü olmayan oyuncu yine '
            '"Yapılmadı" görür ve aynı sayfadaki "Yükümlü değil" ile '
            'çelişir.',
      );
    });
  });

  group('§3 sigorta: engel metni ayraçlı tutar yazar', () {
    test('primi ödeyemeyen oyuncuya ayraçlı tutar gösterilir', () {
      // Kapı üç koşullu: modül açık, poliçe **yok** ve prim parası
      // yetmiyor. İlk yazımda yalnızca parayı sormuştum ve bulunan
      // karede poliçe zaten vardı; engel metni bu yüzden "zaten var"
      // diyordu. Koşulu daraltmak gerekti — iddia değişmedi.
      final GameState? kare = kareBul(
        (GameState s) =>
            Insurance.isOn(s) &&
            s.player.age >=
                insuranceTermsOf(InsuranceKind.saglik).prototypeOnlyMinAge &&
            Insurance.activeOf(s, InsuranceKind.saglik) == null &&
            s.player.wallet <
                insuranceTermsOf(
                  InsuranceKind.saglik,
                ).prototypeOnlyYearlyPremium,
      );
      expect(kare, isNotNull, reason: 'Primi ödeyemeyen kare bulunamadı.');

      final String? engel = Insurance.blockReason(
        kare!,
        InsuranceKind.saglik,
      );
      expect(engel, isNotNull);
      expect(
        engel,
        contains('5.000 ₺'),
        reason: 'Tutar ayraçsız yazılıyor; ekranda "5000 ₺" görünür.',
      );
    });
  });
}

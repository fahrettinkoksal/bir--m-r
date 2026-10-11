// Paket CY — ünün tavanı ve medya kariyerinin kapısı.
//
// **Nasıl çıktı.** Sessiz hikâye izleri sayılırken `sosyal_etkinlige_gitti`
// izinin 150 hayatta **hiç** yazılmadığı görüldü. Sebep oyunda değil
// **ölçüm aracındaydı**: bot yılda bir paylaşım yapıyordu, oyun ise
// `SocialEngine.prototypeOnlyMaxPostsPerAge` (6) kadarına izin veriyor.
//
// **Ölçüm (200 hayat, tohum 95000+i, bütün arketipler):**
//
// |                              | yılda 1 paylaşım | ilgisi kadar |
// |------------------------------|------------------|--------------|
// | hesaplı karede en yüksek ün  | 3                | 100 (tavan)  |
// | en yüksek takipçi            | 1.994            | 2.353.481    |
// | hesap + ün >= 5              | 0 hayat          | 9 hayat      |
// | hesap + ün >= 40             | **0 hayat**      | **5 hayat**  |
//
// Yani ün 40'ın arkasındaki bütün medya kariyeri (`media_catalog.dart`:
// 12 iş + `kMediaSectionMinFame`) ve iki sosyal olay ölçümde hiç
// açılmıyordu.
//
// **Bu dosya neyi iddia eder, neyi etmez.** İddia: o içerik oyuncunun
// yolunda **ulaşılabilir**. İddia etmez: takipçinin milyonlara çıkması
// doğru dengedir — o soru **Q-235**'te Faho'yu bekliyor, bu yüzden tavan
// yalnızca **yazdırılır**, eşiğe bağlanmaz. Kalibrasyon onaylanırsa bu
// dosya kırmızıya dönmemeli.
import 'dart:math';

import 'package:bir_omur/data/media_catalog.dart';
import 'package:bir_omur/domain/events/event_engine.dart';
import 'package:bir_omur/domain/models/game_state.dart';
import 'package:bir_omur/domain/models/social_account.dart';
import 'package:bir_omur/domain/social/social_engine.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/player_bot.dart';

class _Tarama {
  int hesapliHayat = 0;
  int un5Hayat = 0;
  int un40Hayat = 0;
  int enYuksekUn = 0;
  int enYuksekTakipci = 0;
  int birYildaEnCokPaylasim = 0;
  int ikiHesapliHayat = 0;
  final Set<String> gorulenOlaylar = <String>{};
}

_Tarama? _onbellek;

_Tarama _taramaAl() {
  if (_onbellek != null) return _onbellek!;
  const EventEngine motor = EventEngine();
  final _Tarama t = _Tarama();
  const List<String> izlenenOlaylar = <String>[
    'un_tanisma',
    'un_yorumlar',
    'un_etkinlik_daveti',
    'un_is_daveti',
  ];

  for (int i = 0; i < 200; i++) {
    bool hesap = false;
    bool un5 = false;
    bool un40 = false;
    bool ikiHesap = false;
    playBotLife(
      archetype: PlayerArchetype.values[i % PlayerArchetype.values.length],
      seed: 95000 + i,
      onPreAge: (GameState s) {
        if (s.socialAccounts.isEmpty) return;
        hesap = true;
        if (s.socialAccounts.length >= 2) ikiHesap = true;
        final int un = s.player.fame ?? 0;
        if (un > t.enYuksekUn) t.enYuksekUn = un;
        if (s.totalFollowers > t.enYuksekTakipci) {
          t.enYuksekTakipci = s.totalFollowers;
        }
        if (un >= 5) un5 = true;
        if (un >= kMediaSectionMinFame) un40 = true;

        // Aracın kapasitesi: bir yılda atılan en çok paylaşım.
        for (final SocialAccount hesapKaydi in s.socialAccounts) {
          int buYil = 0;
          for (final SocialPost p in hesapKaydi.posts) {
            if (p.age == s.player.age - 1) buYil++;
          }
          if (buYil > t.birYildaEnCokPaylasim) {
            t.birYildaEnCokPaylasim = buYil;
          }
        }

        final Set<String> adaylar = motor.debugEligibleIds(s, Random(13));
        for (final String id in izlenenOlaylar) {
          if (adaylar.contains(id)) t.gorulenOlaylar.add(id);
        }
      },
    );
    if (hesap) t.hesapliHayat++;
    if (un5) t.un5Hayat++;
    if (un40) t.un40Hayat++;
    if (ikiHesap) t.ikiHesapliHayat++;
  }
  return _onbellek = t;
}

const Timeout _sure = Timeout(Duration(minutes: 30));

void main() {
  group('Paket CY — ünün tavanı', () {
    test(timeout: _sure, '§1 medya kariyerinin kapısı ulaşılabilir', () {
      final _Tarama t = _taramaAl();
      // ignore: avoid_print
      print('200 hayat | sosyal hesabı olan ${t.hesapliHayat}, '
          'iki hesaplı ${t.ikiHesapliHayat}');
      // ignore: avoid_print
      print('ün>=5: ${t.un5Hayat} hayat, '
          'ün>=$kMediaSectionMinFame: ${t.un40Hayat} hayat');
      // ignore: avoid_print
      print('TAVAN (Q-235 bekliyor, eşiğe bağlı değil): '
          'en yüksek ün ${t.enYuksekUn}, '
          'en yüksek takipçi ${t.enYuksekTakipci}');

      expect(t.hesapliHayat, greaterThan(40),
          reason: 'bot sosyal medyayı hiç açmıyor; ölçüm anlamsız');
      // Ölçülen 9 ve 5; tabanlar ölçümün altında (Paket BP dersi).
      expect(t.un5Hayat, greaterThanOrEqualTo(4),
          reason: 'ün 5 kapısı yeniden kapandı: un_etkinlik_daveti '
              'ulaşılamaz demektir');
      expect(t.un40Hayat, greaterThanOrEqualTo(2),
          reason: 'medya bölümünün ün $kMediaSectionMinFame kapısı '
              'yeniden hiç açılmıyor: media_catalog.dart\'ın 12 işi '
              'ölü içerik olur');
    });

    test(timeout: _sure, '§2 ün kapılı dört olay da gerçek karede aday', () {
      final _Tarama t = _taramaAl();
      // ignore: avoid_print
      print('aday olan ün olayları: ${t.gorulenOlaylar.toList()..sort()}');
      for (final String id in <String>[
        'un_tanisma',
        'un_yorumlar',
        'un_etkinlik_daveti',
        'un_is_daveti',
      ]) {
        expect(t.gorulenOlaylar, contains(id),
            reason: '$id hiçbir karede aday olmadı (ölçümde 0'
                ' olan buydu)');
      }
    });

    test(timeout: _sure, '§3 araç oyunun verdiği paylaşım hakkını kullanıyor',
        () {
      final _Tarama t = _taramaAl();
      // ignore: avoid_print
      print('bir yılda en çok paylaşım: ${t.birYildaEnCokPaylasim} '
          '(oyunun izni ${SocialEngine.prototypeOnlyMaxPostsPerAge})');
      // Bot yılda bir paylaşıma dönerse bu patlar; ün kapıları da
      // onunla birlikte kapanır (§1, §2).
      expect(t.birYildaEnCokPaylasim, greaterThanOrEqualTo(3),
          reason: 'ölçüm botu yılda en fazla '
              '${t.birYildaEnCokPaylasim} paylaşım yapıyor; oyun '
              '${SocialEngine.prototypeOnlyMaxPostsPerAge} veriyor. '
              'Araç kapasitenin altında kalırsa ün kapılarının '
              'ulaşılabilirliği ölçülemez.');
      expect(t.ikiHesapliHayat, greaterThan(0),
          reason: 'hiçbir hayatta ikinci platform açılmıyor; çapraz '
              'paylaşım motoru (prototypeOnlyCrossShare) ölçülemiyor');
    });

    test('§4 medya kataloğunun eşikleri ölçülen tavanın altında', () {
      // Katalog kendi kendini kilitlemesin: en yüksek iş eşiği ünün
      // tavanını (prototypeOnlyMaxFame) geçmemeli.
      final int enYuksekEsik = kMediaOpportunities
          .map((MediaOpportunity j) => j.minFame)
          .reduce((int a, int b) => a > b ? a : b);
      // ignore: avoid_print
      print('medya işleri: ${kMediaOpportunities.length}, '
          'en yüksek eşik $enYuksekEsik, '
          'ün tavanı ${SocialEngine.prototypeOnlyMaxFame}');
      expect(enYuksekEsik,
          lessThanOrEqualTo(SocialEngine.prototypeOnlyMaxFame),
          reason: 'ünün tavanının üstünde eşik var: o iş hiç açılamaz');
      expect(kMediaOpportunities.length, greaterThan(5));
    });
  });
}

// Paket DB — içerideyken dışarının kapıları.
//
// **Nasıl çıktı.** `ekran_dokumu_ozel_durum_test.dart`'ın "DENETİM
// DÖNEMİ" karesi gözle okundu (Riskli hayat, tohum 3, yaş 47). 46 yaş
// günlüğünde şu iki satır **aynı yılda** duruyordu:
//
// > Bir yıl daha içeride geçti. Dışarısı kendi hâlinde akıyor.
// > Kayseri gezisi: Yalçın ile gittin (Otobüs), 8.100 ₺ harcadın.
// > Vlog çek: sabaha kadar bildirim yağdı. 54 abone geldi.
//
// **Ölçüm (150 bot hayatı, tohum 80000+i):** 19 cezaevi karesi / 13
// hayat; o karelerde **1 gezi** ve **13 paylaşım** gerçekleşmiş.
//
// **Oyunun kendi duruşu zaten buydu:** aktivite (`activity_engine`),
// işletme (`business_engine`), hayvan bakımı (`pet_care`), iş başvurusu
// (`job_market`) ve olaylar (`event_engine`) içeride kapalı. Seyahat ve
// paylaşım iki delikti; `tourAvailability` ayrıca denetim dönemini de
// (D-161) görmüyordu. Yeni kural yazılmadı — var olan duruş eksik
// kaldığı yerlere uygulandı.
import 'package:bir_omur/data/tour_catalog.dart';
import 'package:bir_omur/domain/activities/travel.dart';
import 'package:bir_omur/domain/models/trip.dart';
import 'package:bir_omur/domain/law/legal_engine.dart';
import 'package:bir_omur/domain/models/game_state.dart';
import 'package:bir_omur/domain/models/social_account.dart';
import 'package:bir_omur/domain/social/social_engine.dart';
import 'package:bir_omur/data/social_catalog.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/player_bot.dart';

class _Tarama {
  int icerdeKare = 0;
  int icerdeHayat = 0;
  int icerdeGezi = 0;
  int icerdePaylasim = 0;

  /// İçeride seyahat/paylaşım kapısı **açık** bulundu mu?
  int acikGeziKapisi = 0;
  int acikPaylasimKapisi = 0;
  int denetimTurKapisiAcik = 0;
  int denetimKare = 0;
}

_Tarama? _onbellek;

_Tarama _taramaAl() {
  if (_onbellek != null) return _onbellek!;
  const SocialEngine sosyal = SocialEngine();
  final _Tarama t = _Tarama();
  for (int i = 0; i < 150; i++) {
    bool ic = false;
    int oncekiGezi = -1;
    int oncekiPaylasim = -1;
    playBotLife(
      archetype: PlayerArchetype.values[i % PlayerArchetype.values.length],
      seed: 80000 + i,
      onYear: (GameState s) {
        final int gezi = s.trips.length;
        int paylasim = 0;
        for (final SocialAccount a in s.socialAccounts) {
          paylasim += a.posts.length;
        }

        if (s.isImprisoned) {
          t.icerdeKare++;
          ic = true;
          if (oncekiGezi >= 0 && gezi > oncekiGezi) {
            t.icerdeGezi += gezi - oncekiGezi;
          }
          if (oncekiPaylasim >= 0 && paylasim > oncekiPaylasim) {
            t.icerdePaylasim += paylasim - oncekiPaylasim;
          }

          // Kapılar: kare bulundu, kurulmadı.
          for (final String sehir in <String>['İstanbul', 'Ankara', 'İzmir']) {
            if (sehir == s.player.currentCity) continue;
            if (Travel.availability(s,
                    mode: TravelMode.otobus, city: sehir)
                .isAllowed) {
              t.acikGeziKapisi++;
            }
          }
          for (final SocialAccount a in s.socialAccounts) {
            final List<SocialContent> icerik = contentsFor(a.platform);
            if (icerik.isEmpty) continue;
            if (sosyal.postAvailability(s, icerik.first).isAllowed) {
              t.acikPaylasimKapisi++;
            }
          }
        }

        // Denetim dönemi: tur kapısı da kapalı olmalı (D-161).
        //
        // **Ölçüt `LegalEngine.onProbation`** — ilk yazışımda
        // `probationUntilAge != null` demiştim ve süresi **geçmiş**
        // kayıtları da saydım: 254 karenin 224'ünde kapı haklı olarak
        // açıktı. Kayıtta bir alanın dolu olması, o dönemin hâlâ
        // sürdüğü anlamına gelmiyor.
        if (LegalEngine.onProbation(s) && !s.isImprisoned) {
          t.denetimKare++;
          if (kTourPackages.isNotEmpty &&
              Travel.tourAvailability(s, tour: kTourPackages.first)
                  .isAllowed) {
            t.denetimTurKapisiAcik++;
          }
        }

        oncekiGezi = gezi;
        oncekiPaylasim = paylasim;
      },
    );
    if (ic) t.icerdeHayat++;
  }
  return _onbellek = t;
}

const Timeout _sure = Timeout(Duration(minutes: 30));

void main() {
  group('Paket DB — içerideyken dışarının kapıları', () {
    test(timeout: _sure, '§1 içeride seyahat ve paylaşım gerçekleşmiyor', () {
      final _Tarama t = _taramaAl();
      // ignore: avoid_print
      print('cezaevi karesi ${t.icerdeKare} / ${t.icerdeHayat} hayat');
      // ignore: avoid_print
      print('içeride gezi ${t.icerdeGezi}, içeride paylaşım '
          '${t.icerdePaylasim}');
      expect(t.icerdeKare, greaterThan(8),
          reason: 'cezaevi karesi bulunamadı; denetim boşa döner');
      // Ölçümde 1 gezi ve 13 paylaşım vardı.
      expect(t.icerdeGezi, 0, reason: 'içerideyken geziye çıkıldı');
      expect(t.icerdePaylasim, 0,
          reason: 'içerideyken sosyal medya paylaşımı yapıldı');
    });

    test(timeout: _sure, '§2 kapılar gerekçeli kapalı', () {
      final _Tarama t = _taramaAl();
      // ignore: avoid_print
      print('içeride açık bulunan gezi kapısı ${t.acikGeziKapisi}, '
          'paylaşım kapısı ${t.acikPaylasimKapisi}');
      expect(t.acikGeziKapisi, 0,
          reason: 'cezaevindeyken seyahat kapısı açık');
      expect(t.acikPaylasimKapisi, 0,
          reason: 'cezaevindeyken paylaşım kapısı açık');
    });

    test(timeout: _sure, '§3 denetim dönemi turu da kapatıyor (D-161)', () {
      final _Tarama t = _taramaAl();
      // ignore: avoid_print
      print('denetim karesi ${t.denetimKare}, açık tur kapısı '
          '${t.denetimTurKapisiAcik}');
      expect(t.denetimKare, greaterThan(5),
          reason: 'denetim dönemi karesi bulunamadı; denetim boşa döner');
      expect(t.denetimTurKapisiAcik, 0,
          reason: 'denetim döneminde tur kapısı açık: D-161 şehir dışına '
              'çıkmayı kapatıyor, tur ikinci yoldu');
    });
  });
}

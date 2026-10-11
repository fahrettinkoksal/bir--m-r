// Paket CR — **bekleyen kareler ölçüme görünmüyordu.**
//
// **Ölçülen hata.** `playBotLife` döngüsünde bekleyen şeyler adım
// 1-6'da yanıtlanıp `continue` ediliyor; teşhis kancası `onPreAge` ise
// adım 7'de, yaş almanın hemen öncesinde çalışıyor. Yani **bekleyen
// bir olay, kriz ya da duruşma varken hiçbir ölçüm o kareyi
// göremiyordu.**
//
// Bu kör nokta üç kez yanlış bulgu üretti:
//
// 1. **Yeni doğan bebek (Paket CG).** `onYear` yaş aldıktan sonra
//    çalıştığı için 0 yaşındaki bebek hiç bulunamadı; `onPreAge`
//    eklendi ve 60 hayatta 77 kare çıktı.
// 2. **Yaşlılıkta bakım kararı (Paket CJ).** Bot kararı yılın başında
//    verdiği için taranan her kare "bu yılın kararı verilmiş" oluyordu;
//    `BotOverrides.noElderSupport` eklendi.
// 3. **Bekleyen duruşma (bu paket).** Suç hunisi 250 hayatta ölçüldü:
//    suç işleyen 119, **duruşma gören 0**, içeriden geçen 21. "Oyun
//    duruşma üretmiyor" gibi görünen sayı tamamen aracın gölgesiydi:
//    botun kendi kaydı (`wentToTrial`) **57** diyor.
//
// Düzeltme: `onPending` kancası, bekleyen kare **yanıtlanmadan önce**
// çağrılıyor. `onPreAge` ve `onYear` olduğu gibi kaldı; mevcut hiçbir
// ölçüm kaymadı (kanca verilmezse hiç çalışmıyor).
//
// **Suç hunisi (250 hayat, doğru araçla):**
//
// | Aşama | Hayat |
// |---|---|
// | Suç işleyen | 119 |
// | Duruşma gören | 57 |
// | İçeriden geçen | 21 |
// | Denetim dönemi gören | 21 |
// | Toplam hapis yılı | 36 |
//
// Arketip kırılımı: `risky` 25 suç / 19 duruşma / 8 içeride; `social`
// 17/5/4; `investor` 4/1/0. Yani suç yolu ulaşılamaz değil —
// Paket CP'nin "çete ve kefalet aksiyonlarına hiç dokunulmuyor"
// bulgusu **kapsam botunun** suçlu planı olmamasından geliyor, oyunun
// kapısından değil.
library;

import 'package:bir_omur/domain/models/game_state.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/player_bot.dart';

/// Ölçüm kohortu: 10 arketip × [adet] tohum.
typedef _Huni = ({
  int sucIsleyen,
  int durusmaGoren,
  int iceride,
  int denetim,
  int bekleyenDurusmaKaresi,
  int bekleyenOlayKaresi,
  int bekleyenKrizKaresi,
  int preAgeDurusmaKaresi,
});

_Huni _olc({int adet = 25}) {
  int suc = 0;
  int durusma = 0;
  int iceride = 0;
  int denetim = 0;
  int bekleyenDurusma = 0;
  int bekleyenOlay = 0;
  int bekleyenKriz = 0;
  int preAgeDurusma = 0;
  for (final PlayerArchetype a in PlayerArchetype.values) {
    for (int seed = 1; seed <= adet; seed++) {
      bool iceridenGecti = false;
      bool denetimGordu = false;
      final BotLifeResult r = playBotLife(
        archetype: a,
        seed: seed * 97 + a.index,
        onPending: (GameState s) {
          if (s.hasPendingTrial) bekleyenDurusma++;
          if (s.hasPendingEvent) bekleyenOlay++;
          if (s.pendingCrisis != null) bekleyenKriz++;
        },
        onPreAge: (GameState s) {
          // Aynı soru eski kancayla: kör noktanın kendisi.
          if (s.hasPendingTrial) preAgeDurusma++;
          if (s.legal.imprisonedSinceAge != null) iceridenGecti = true;
          if (s.legal.probationUntilAge != null) denetimGordu = true;
        },
      );
      if (r.crimeIds.isNotEmpty) suc++;
      if (r.wentToTrial) durusma++;
      if (iceridenGecti) iceride++;
      if (denetimGordu) denetim++;
    }
  }
  return (
    sucIsleyen: suc,
    durusmaGoren: durusma,
    iceride: iceride,
    denetim: denetim,
    bekleyenDurusmaKaresi: bekleyenDurusma,
    bekleyenOlayKaresi: bekleyenOlay,
    bekleyenKrizKaresi: bekleyenKriz,
    preAgeDurusmaKaresi: preAgeDurusma,
  );
}

_Huni? _onbellek;
_Huni get _huni => _onbellek ??= _olc();

void main() {
  test('onPending bekleyen duruşmayı görüyor, onPreAge görmüyor', () {
    final _Huni h = _huni;
    expect(h.bekleyenDurusmaKaresi, greaterThanOrEqualTo(20),
        reason: 'yeni kanca bekleyen duruşmayı görmüyor: '
            '${h.bekleyenDurusmaKaresi} kare');
    // **Kör nokta bilerek sabitlendi.** Bot bekleyen duruşmayı adım
    // 6'da yanıtlıyor, `onPreAge` adım 7'de çalışıyor: bu sayı 0
    // olmalı. Botun bekleyen işleri yanıtlama sırası değişirse bu
    // test kırmızıya döner — o zaman **bilerek** güncellenmeli, çünkü
    // o değişiklik bu dosyadaki üç yanlış bulgunun zeminini değiştirir.
    expect(h.preAgeDurusmaKaresi, 0,
        reason: 'onPreAge bekleyen duruşmayı görmeye başladı '
            '(${h.preAgeDurusmaKaresi} kare): botun bekleyen işleri '
            'yanıtlama sırası değişmiş olabilir');
  });

  test('onPending olay ve kriz karelerini de veriyor', () {
    expect(_huni.bekleyenOlayKaresi, greaterThan(500),
        reason: 'bekleyen olay karesi az: ${_huni.bekleyenOlayKaresi}');
    expect(_huni.bekleyenKrizKaresi, greaterThan(0),
        reason: 'bekleyen kriz karesi hiç görülmedi');
  });

  test('suç hunisi: yol ulaşılabilir ve kademeleri yaşanıyor', () {
    final _Huni h = _huni;
    // Ölçüm (250 hayat): 119 suç · 57 duruşma · 21 içeride · 21
    // denetim. Tabanlar belirgin altında; biri sıfıra düşerse suç
    // içeriği oyuncuya ulaşamıyor demektir.
    expect(h.sucIsleyen, greaterThanOrEqualTo(80),
        reason: 'suç işleyen hayat az: ${h.sucIsleyen}');
    expect(h.durusmaGoren, greaterThanOrEqualTo(30),
        reason: 'duruşma gören hayat az: ${h.durusmaGoren}');
    expect(h.iceride, greaterThanOrEqualTo(10),
        reason: 'içeriden geçen hayat az: ${h.iceride}');
    expect(h.denetim, greaterThanOrEqualTo(10),
        reason: 'denetim dönemi gören hayat az: ${h.denetim}');
    // Huni daralarak ilerler: her aşama öncekinden küçük olmalı.
    expect(h.durusmaGoren, lessThanOrEqualTo(h.sucIsleyen));
    expect(h.iceride, lessThanOrEqualTo(h.durusmaGoren));
  });
}

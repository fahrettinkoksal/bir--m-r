/// Paket CD — olay **dallarını** gezen kapsam modu.
///
/// **Ölçülen sorun.** Bot her olayda en iyi puanlı seçeneği alıyor
/// (artı `slip` payı). Bu, içeriğin yarısını ölçüm dışı bırakıyordu:
/// 150 hayatta çok dallı 595 olayın **117'sinin yalnızca bir dalı**
/// gezilmiş, 22'si hiç görülmemişti. Bir dalın arkasındaki hata
/// görünmez olur — Paket BY/1'de ölü kodun "etki yok" diye görünmesi
/// aynı aileden bir sorundu.
///
/// `choiceCoverage` açıkken bot yarı yarıya **en düşük** puanlı dalı
/// alır. Bu bir oyuncu taklidi değil, kapsam aracıdır: denge
/// ölçümlerinde kullanılmaz.
///
/// Ölçüm (150 hayat, kapalı → açık):
///   bütün dalları gezilen olay   456 → **528** (595 içinde)
///   yalnızca tek dalı gezilen    117 → **54**
///   hiç görülmeyen                22 → **13**
///   görülen tekil olay           573 → **582**
///
/// **Kendi iddiamı düzelttim.** İlk tohum bloğunda `zincir_emanet_2`
/// 17 hayatta görülüp 17'sinde de `bekle` seçilmişti; "bot bu dalı hiç
/// seçmiyor" diye yazdım. İkinci blokta (`9500+`) `iste` iki modda da
/// birer hayatta seçildi. Yani dal engelli değil, **ilk halka nadir**.
/// Tek tohum bloğuna dayanan bulgu bulgudan sayılmaz.
library;

import 'package:bir_omur/data/event_pool.dart';
import 'package:bir_omur/domain/models/game_event.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/player_bot.dart';

/// Çok dallı olayların kimliği → dal sayısı.
Map<String, int> _cokDalliOlaylar() => <String, int>{
      for (final GameEvent e in kEventPool)
        if (e.choices.length >= 2) e.id: e.choices.length,
    };

/// [n] hayat oynatıp olay başına gezilen dalları toplar.
({int tam, int tek, int hicGorulmeyen}) _kapsamOlc({
  required bool kapsam,
  required int n,
  required int tabanTohum,
}) {
  final Map<String, int> dalSayisi = _cokDalliOlaylar();
  final Map<String, Set<String>> toplam = <String, Set<String>>{};
  for (int i = 0; i < n; i++) {
    final BotLifeResult r = playBotLife(
      archetype: PlayerArchetype.values[i % PlayerArchetype.values.length],
      seed: tabanTohum + i,
      choiceCoverage: kapsam,
    );
    r.choicesTaken.forEach((String id, Set<String> dallar) {
      toplam.putIfAbsent(id, () => <String>{}).addAll(dallar);
    });
  }
  int tam = 0;
  int tek = 0;
  int yok = 0;
  for (final MapEntry<String, int> e in dalSayisi.entries) {
    final int gezilen = toplam[e.key]?.length ?? 0;
    if (gezilen == 0) {
      yok++;
    } else if (gezilen >= e.value) {
      tam++;
    } else {
      tek++;
    }
  }
  return (tam: tam, tek: tek, hicGorulmeyen: yok);
}

void main() {
  group('Paket CD — kapsam modu', () {
    test('varsayılan kapalı: aynı tohum aynı hayat', () {
      // Paket BO sözleşmesi: yeni mod zarı yalnızca açıkken tüketir.
      // Kapalı hâl ile varsayılan hâl birebir aynı olmalı, yoksa
      // bütün tohumlu ölçümler kayar.
      for (final int tohum in <int>[41, 97, 203]) {
        final BotLifeResult varsayilan =
            playBotLife(archetype: PlayerArchetype.casual, seed: tohum);
        final BotLifeResult acikcaKapali = playBotLife(
          archetype: PlayerArchetype.casual,
          seed: tohum,
          choiceCoverage: false,
        );
        expect(acikcaKapali.deathAge, varsayilan.deathAge,
            reason: 'tohum $tohum');
        expect(acikcaKapali.seenEvents, varsayilan.seenEvents,
            reason: 'tohum $tohum');
        expect(acikcaKapali.choicesTaken.length, varsayilan.choicesTaken.length,
            reason: 'tohum $tohum');
      }
    }, timeout: const Timeout(Duration(minutes: 5)));

    test('seçilen dallar kaydediliyor', () {
      final BotLifeResult r =
          playBotLife(archetype: PlayerArchetype.casual, seed: 777);
      expect(r.choicesTaken, isNotEmpty,
          reason: 'Bir hayat boyunca hiç dal kaydedilmedi');
      // Kaydedilen her dal gerçekten o olayın bir seçeneği olmalı.
      final Map<String, GameEvent> katalog = <String, GameEvent>{
        for (final GameEvent e in kEventPool) e.id: e,
      };
      r.choicesTaken.forEach((String olayId, Set<String> dallar) {
        final GameEvent? olay = katalog[olayId];
        if (olay == null) return; // havuz dışı (kriz, duruşma) olabilir
        for (final String dal in dallar) {
          expect(
            olay.choices.any((EventChoice c) => c.id == dal),
            isTrue,
            reason: '$olayId olayında olmayan dal kaydedildi: $dal',
          );
        }
      });
    }, timeout: const Timeout(Duration(minutes: 5)));

    test('kapsam modu dal gezmeyi gerçekten artırıyor', () {
      const int n = 60;
      final ({int tam, int tek, int hicGorulmeyen}) kapali =
          _kapsamOlc(kapsam: false, n: n, tabanTohum: 9500);
      final ({int tam, int tek, int hicGorulmeyen}) acik =
          _kapsamOlc(kapsam: true, n: n, tabanTohum: 9500);
      // Ölçüm (150 hayat): 456 → 528, yani 60 hayatta beklenen fark
      // ~29. Eşik ölçülenin çok altında: bu test dağılımı değil
      // **aracın işe yaradığını** korur.
      expect(
        acik.tam,
        greaterThanOrEqualTo(kapali.tam + 10),
        reason: 'Bütün dalları gezilen olay kapalıda ${kapali.tam}, '
            'açıkta ${acik.tam}. Kapsam modu dal gezmiyor demektir.',
      );
      expect(
        acik.tek,
        lessThan(kapali.tek),
        reason: 'Tek dalı gezilen olay kapalıda ${kapali.tek}, '
            'açıkta ${acik.tek}',
      );
    }, timeout: const Timeout(Duration(minutes: 20)));
  });
}

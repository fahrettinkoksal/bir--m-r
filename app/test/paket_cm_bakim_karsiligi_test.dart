// Paket CM — yaşlılıkta bakımın karşılığı: kaydı okuyan altı olay.
//
// **Nereden çıktı.** Paket CJ bakım kaydını tutuyordu (kaç yıl destek
// görüldü, kaç yıl kimseye yüklenmeden çevrildi) ama o kayıt hiçbir
// yerde hikâyeye dönmüyordu; Q-228'in beşinci maddesi bunu kendi
// önerim olarak bırakmıştı.
//
// **Koşul iz değil sayaç.** Olaylar `minElderSupportYears` ve
// `minElderAloneYears` ile kayda bakar: "üç yıldır yanımda" diyen bir
// cümle o üç yıl yaşanmadan çıkmaz. Hikâye izi kullanılsaydı bir kez
// destek görmek ömür boyu yeterdi (Paket CI'nin aynı gerekçesi).
//
// **Ölçüm (250 bot hayatı).** 2+ destekli kare 205, 2+ yalnız kare
// 252; altı olayın **hepsi** görüldü ve 14 hayat en az birini gördü.
// Ulaşılamayan olay yok (Paket CD/CK'nın ölçütü).
//
// Durum kurulmuyor: kareler bot hayatlarında bulunuyor.
library;

import 'dart:math';

import 'package:bir_omur/data/event_pool_elder_support.dart';
import 'package:bir_omur/domain/events/event_engine.dart';
import 'package:bir_omur/domain/features/feature_catalog.dart';
import 'package:bir_omur/domain/features/feature_events.dart';
import 'package:bir_omur/domain/models/game_event.dart';
import 'package:bir_omur/domain/models/game_state.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/player_bot.dart';

Set<String> get _havuzIds =>
    kElderSupportEvents.map((GameEvent e) => e.id).toSet();

/// Taramanın topladıkları.
class _Olcum {
  final Map<String, int> gorulen = <String, int>{};
  int gorenHayat = 0;
  int destekliKare = 0;
  int yalnizKare = 0;

  /// Sayaç eşiği tutmadan aday olan olay sayısı (olmamalı).
  int erkenAday = 0;

  /// Modül kapalıyken aday olan olay sayısı (olmamalı).
  int kapaliAday = 0;
}

_Olcum _tara() {
  const EventEngine motor = EventEngine();
  final _Olcum o = _Olcum();
  final Set<String> havuz = _havuzIds;
  for (final PlayerArchetype a in PlayerArchetype.values) {
    for (int seed = 1; seed <= 25; seed++) {
      final BotLifeResult r = playBotLife(
        archetype: a,
        seed: seed * 97 + a.index,
        onPreAge: (GameState s) {
          final int destek = s.elderSupport.yearsSupported;
          final int yalniz = s.elderSupport.yearsAlone;
          if (destek >= 2) o.destekliKare++;
          if (yalniz >= 2) o.yalnizKare++;
          if (s.player.age < 70) return;

          // Eşik denetimi: aday havuzunda çıkan her olayın istediği
          // sayaç gerçekten tutuyor mu?
          final Set<String> adaylar = motor.debugEligibleIds(s, Random(13));
          for (final GameEvent e in kElderSupportEvents) {
            if (!adaylar.contains(e.id)) continue;
            if (destek < e.requirement.minElderSupportYears ||
                yalniz < e.requirement.minElderAloneYears) {
              o.erkenAday++;
            }
          }

          // Modül kapalıyken hiçbiri aday olmamalı (fail-closed).
          final GameState kapali = s.copyWith(
            settings: s.settings.copyWith(
              features: s.settings.features
                  .toggled(FeatureId.yaslilikBakimi, false),
            ),
          );
          o.kapaliAday += motor
              .debugEligibleIds(kapali, Random(13))
              .intersection(havuz)
              .length;
        },
      );
      final Set<String> kesisim = r.seenEvents.intersection(havuz);
      if (kesisim.isNotEmpty) o.gorenHayat++;
      for (final String id in kesisim) {
        o.gorulen.update(id, (int v) => v + 1, ifAbsent: () => 1);
      }
    }
  }
  return o;
}

void main() {
  final _Olcum olcum = _tara();

  group('Paket CM §1 — içerik gerçekten çıkıyor', () {
    test('altı olayın hepsi görülüyor (ulaşılamayan yok)', () {
      final Set<String> gorulmeyen =
          _havuzIds.difference(olcum.gorulen.keys.toSet());
      expect(gorulmeyen, isEmpty,
          reason: 'bu olaylar 250 hayatta hiç çıkmadı: $gorulmeyen — '
              'yazılmış ama erişilemez içerik bırakmıyoruz (Paket CD)');
      expect(olcum.gorenHayat, greaterThan(4),
          reason: 'içerik neredeyse hiçbir hayatta görünmüyor');
    });

    test('kaydın iki tarafı da yaşanıyor', () {
      // Ölçüm: 205 ve 252 kare. Tabanlar belirgin altında.
      expect(olcum.destekliKare, greaterThan(60),
          reason: 'iki yıl üstü destek gören kare neredeyse yok');
      expect(olcum.yalnizKare, greaterThan(60),
          reason: 'iki yıl üstü tek başına çeviren kare neredeyse yok');
    });
  });

  group('Paket CM §2 — kapı sayaçtan geçiyor', () {
    test('sayaç tutmadan hiçbir olay aday olmuyor', () {
      expect(olcum.erkenAday, 0,
          reason: 'bir olay istediği yıl sayısı dolmadan aday oldu: '
              '"üç yıldır yanımda" diyen cümle yalan olurdu');
    });

    test('modül kapalıyken havuz aday olmuyor (fail-closed)', () {
      expect(olcum.kapaliAday, 0,
          reason: 'modül kapalıyken bakım olayları aday havuzunda');
    });

    test('havuzun hepsi modüle bağlı ve yeni iz bırakmıyor', () {
      final Set<String> modulIds = FeatureEvents.idsOf(FeatureId.yaslilikBakimi);
      expect(modulIds, equals(_havuzIds),
          reason: 'havuz ile modül eşlemesi ayrışmış');
      // Yazılan her iz okunmalı (Paket AR). Bu havuz iz yazmıyor:
      // hikâye burada kapanıyor, üçüncü bir katman yok.
      for (final GameEvent e in kElderSupportEvents) {
        for (final EventChoice c in e.choices) {
          expect(c.addFlags, isEmpty,
              reason: '${e.id}/${c.id} iz bırakıyor ama onu okuyan '
                  'bir olay yok (sessiz iz)');
        }
      }
    });

    test('metinler yasak kalıpları taşımıyor', () {
      const List<String> yasak = <String>[
        'bro', 'kanka', 'moruk', ' aga ', ' lan ', ' aq ',
      ];
      for (final GameEvent e in kElderSupportEvents) {
        final String hepsi = <String>[
          e.text,
          for (final EventChoice c in e.choices) '${c.label} ${c.resultText}',
        ].join(' ').toLowerCase();
        for (final String k in yasak) {
          expect(hepsi.contains(k), isFalse,
              reason: '${e.id} yasak kalıp taşıyor: "$k"');
        }
        expect(e.requirement.minAge, greaterThanOrEqualTo(70),
            reason: '${e.id} yaşlılık dışında çıkabilir');
      }
    });
  });
}

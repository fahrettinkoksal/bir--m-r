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
// 252. Ulaşılamayan olay yok (Paket CD/CK'nın ölçütü).
//
// **Paket CN'den sonra düzeltilen bekçi.** İlk yazımda "altı olayın
// hepsi 250 hayatta görüldü" diye **tek bir koşunun şansına** bakan
// bir test vardı. Paket CN çocuğu hastalandırınca (hastalanan çocuğun
// statları değişiyor, sonraki yılların dalları kayıyor) aynı 250
// hayatta `bakim_karsilik_komsu_farketti` sıfır çekti ve bekçi
// kırmızıya döndü. Ölçüldü:
//
// | Olay | 250 hayat: aday · beklenen · görülen | 500 hayat |
// |---|---|---|
// | `…aliskanlik` | 173 · 2,04 · 5 | 366 · 4,28 · 8 |
// | `…yorgunluk` | 148 · 1,75 · 2 | 295 · 3,47 · 4 |
// | `…torun_gorur` | 108 · 1,26 · 2 | 206 · 2,41 · 6 |
// | `…komsu_farketti` | **261 · 3,53 · 0** | 512 · 6,88 · **7** |
// | `…kimseyi_aramadim` | 180 · 2,33 · 3 | 370 · 4,84 · 9 |
// | `…defter_notu` | 129 · 1,34 · 4 | 275 · 2,80 · 8 |
//
// Yani olay havuzun **en çok aday üreteni**; erişilemez değil, o
// kohortta şans tutmadı (beklenen 3,53 iken sıfır çekme ihtimali
// ~%3). Paket CK'nın dersi buydu: "görülmedi" ulaşılamazlık ölçütü
// değil. Bekçi gevşetilmedi, **ölçütü düzeltildi**: erişilebilirlik
// artık her olay için **aday kare + beklenen çıkış** ile ölçülüyor
// (250 hayat, kararlı sayılar), uçtan uca "gerçekten çıkıyor"
// iddiası ise beklenen çıkışın sıfırı inandırıcı kılmadığı
// **500 hayatlık** kohortta sınanıyor.
//
// Durum kurulmuyor: kareler bot hayatlarında bulunuyor.
library;

import 'dart:math';

import 'package:bir_omur/data/event_pool.dart';
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

/// Olayın havuzdaki ağırlığı (Paket CK kalıbı).
int _agirlik(String id) =>
    kEventPool.firstWhere((GameEvent e) => e.id == id).weight;

/// Bir olayın bir karede seçilme payı: kendi ağırlığı / aday toplamı.
double _pay(String id, Set<String> adaylar) {
  int toplam = 0;
  for (final String aday in adaylar) {
    toplam += _agirlik(aday);
  }
  if (toplam == 0 || !adaylar.contains(id)) return 0;
  return _agirlik(id) / toplam;
}

/// Taramanın topladıkları.
class _Olcum {
  final Map<String, int> gorulen = <String, int>{};

  /// Olay başına aday kare sayısı ve beklenen çıkış (erişilebilirlik
  /// ölçütü: tek koşunun şansına bakmaz).
  final Map<String, int> adayKare = <String, int>{};
  final Map<String, double> beklenen = <String, double>{};

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
            o.adayKare[e.id] = (o.adayKare[e.id] ?? 0) + 1;
            o.beklenen[e.id] =
                (o.beklenen[e.id] ?? 0) + _pay(e.id, adaylar);
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
    test('altı olayın hepsi aday oluyor ve beklenen çıkışı var', () {
      // Erişilebilirlik ölçütü: aday kare + beklenen çıkış. Tabanlar
      // ölçülenin (en düşük: 108 kare / 1,26 beklenen) belirgin
      // altında; sıfır aday ya da sıfıra yakın beklenen = erişilemez
      // içerik (Paket CD/CK).
      for (final String id in _havuzIds) {
        expect(olcum.adayKare[id] ?? 0, greaterThan(50),
            reason: '$id 250 hayatta neredeyse hiç aday olmuyor: '
                '${olcum.adayKare[id] ?? 0} kare');
        expect(olcum.beklenen[id] ?? 0, greaterThan(0.8),
            reason: '$id beklenen çıkışı 250 hayatta 0,8\'in altında: '
                '${olcum.beklenen[id] ?? 0}');
      }
      expect(olcum.gorenHayat, greaterThan(4),
          reason: 'içerik neredeyse hiçbir hayatta görünmüyor');
    });

    test('her olay 500 hayatta gerçekten çıkıyor (uçtan uca)', () {
      // 250 hayat bu iddia için **yetmiyor**: en seyrek olayın
      // beklenen çıkışı 1,26: sıfır çekmesi %28 ihtimalli. 500
      // hayatta ölçülen görülme 8/4/6/7/9/8.
      final Map<String, int> gorulen = <String, int>{};
      for (final PlayerArchetype a in PlayerArchetype.values) {
        for (int seed = 1; seed <= 50; seed++) {
          final BotLifeResult r = playBotLife(
            archetype: a,
            seed: seed * 97 + a.index,
          );
          for (final String id in r.seenEvents.intersection(_havuzIds)) {
            gorulen[id] = (gorulen[id] ?? 0) + 1;
          }
        }
      }
      final Set<String> gorulmeyen =
          _havuzIds.difference(gorulen.keys.toSet());
      expect(gorulmeyen, isEmpty,
          reason: 'bu olaylar 500 hayatta hiç çıkmadı: $gorulmeyen — '
              'yazılmış ama erişilemez içerik bırakmıyoruz (Paket CD)');
      expect(gorulen.values.fold<int>(0, (int t, int v) => t + v),
          greaterThanOrEqualTo(20),
          reason: 'havuzun toplam görülme sayısı beklenenin çok '
              'altında: $gorulen');
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

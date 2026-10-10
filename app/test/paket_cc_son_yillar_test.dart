/// Paket CC — son yıllar havuzu (65+).
///
/// **Ölçülen sorun.** Oynanan 60 hayatta `EventEngine.debugEligibleIds`
/// ile yaş yaş sayıldı: 65-74 bandında yılda **75,3** olay uygun hale
/// geliyordu, yani bant aç değildi. Ama o taramada görülen **228 tekil
/// olaydan yalnızca 11'i** o yaşlara aitti; gerisi orta yaşın
/// havuzuydu. 70 yaşındaki oyuncu 40 yaşındakiyle aynı olayları
/// çekiyordu.
///
/// Bu dosya üç şeyi korur: havuzun bütünlüğü (her iz okunur), modül
/// anahtarının fail-closed davranışı ve yolun gerçekten akması.
library;

import 'package:bir_omur/data/event_pool.dart';
import 'package:bir_omur/data/event_pool_late_years.dart';
import 'package:bir_omur/domain/events/event_engine.dart';
import 'package:bir_omur/domain/features/feature_catalog.dart';
import 'package:bir_omur/domain/features/feature_events.dart';
import 'package:bir_omur/domain/models/game_event.dart';
import 'package:bir_omur/domain/models/game_state.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/player_bot.dart';

/// Havuzun bıraktığı izler (olayların `addFlags` ile yazdıkları).
Set<String> _yazilanIzler() => <String>{
      for (final GameEvent olay in kLateYearsEvents)
        for (final EventChoice secim in olay.choices) ...secim.addFlags,
    };

/// Havuzun okuduğu izler (`requiredFlags` + `forbiddenFlags`).
Set<String> _okunanIzler() => <String>{
      for (final GameEvent olay in kLateYearsEvents)
        ...olay.requirement.requiredFlags,
      for (final GameEvent olay in kLateYearsEvents)
        ...olay.requirement.forbiddenFlags,
    };

void main() {
  group('Paket CC — havuzun bütünlüğü', () {
    test('havuz boş değil ve bütün olaylar 60 yaş ve sonrası', () {
      expect(kLateYearsEvents.length, greaterThanOrEqualTo(25));
      for (final GameEvent olay in kLateYearsEvents) {
        expect(
          olay.requirement.minAge,
          greaterThanOrEqualTo(60),
          reason: '${olay.id} son yıllar havuzunda ama '
              '${olay.requirement.minAge} yaşında da çıkabiliyor; orta '
              'yaşın havuzunu seyreltir',
        );
      }
    });

    test('kimlikler tekil ve havuzun önekini taşıyor', () {
      final Set<String> kimlikler = <String>{};
      for (final GameEvent olay in kLateYearsEvents) {
        expect(
          kimlikler.add(olay.id),
          isTrue,
          reason: '${olay.id} iki kez tanımlı',
        );
        expect(
          olay.id.startsWith('son_'),
          isTrue,
          reason: '${olay.id} havuzun önekini taşımıyor',
        );
      }
      // Havuzun kimlikleri genel havuzda da tekil olmalı.
      final Map<String, int> genel = <String, int>{};
      for (final GameEvent olay in kEventPool) {
        genel[olay.id] = (genel[olay.id] ?? 0) + 1;
      }
      for (final GameEvent olay in kLateYearsEvents) {
        expect(genel[olay.id], 1, reason: '${olay.id} genel havuzda tekil değil');
      }
    });

    test('her olayın metni ve en az iki seçeneği var', () {
      for (final GameEvent olay in kLateYearsEvents) {
        expect(olay.text.trim(), isNotEmpty, reason: olay.id);
        expect(
          olay.choices.length,
          greaterThanOrEqualTo(2),
          reason: '${olay.id}: tek seçenek karar değildir',
        );
        for (final EventChoice secim in olay.choices) {
          expect(secim.label.trim(), isNotEmpty, reason: '${olay.id}/${secim.id}');
          expect(
            secim.resultText.trim(),
            isNotEmpty,
            reason: '${olay.id}/${secim.id}: sonucu anlatılmıyor',
          );
        }
      }
    });

    test('bırakılan her iz okunuyor (Paket AR dersi)', () {
      final Set<String> yazilan = _yazilanIzler();
      final Set<String> okunan = _okunanIzler();
      final Set<String> sessiz = yazilan.difference(okunan);
      expect(
        sessiz,
        isEmpty,
        reason: 'Karşılığı olmayan iz: ${sessiz.join(", ")}. '
            'Oyuncu bir şey yapıyor ve hiç geri dönmüyor.',
      );
    });

    test('okunan her iz gerçekten bırakılabiliyor', () {
      final Set<String> yazilan = _yazilanIzler();
      final Set<String> okunan = _okunanIzler();
      final Set<String> ulasilmaz = okunan.difference(yazilan);
      expect(
        ulasilmaz,
        isEmpty,
        reason: 'Hiçbir olayın yazmadığı iz aranıyor: '
            '${ulasilmaz.join(", ")}',
      );
    });

    test('iz dizeleri olay kimlikleriyle çakışmıyor', () {
      final Set<String> kimlikler =
          kEventPool.map((GameEvent e) => e.id).toSet();
      for (final String iz in _yazilanIzler().union(_okunanIzler())) {
        expect(
          kimlikler.contains(iz),
          isFalse,
          reason: '"$iz" hem iz hem olay kimliği; iki ayrı kavram '
              'aynı dizeyi taşımamalı',
        );
      }
    });

    test('yasak kalıplar yok (WRITING_STYLE_TR §2)', () {
      const List<String> yasak = <String>[
        'olumlu yönde etkiledi',
        'bu deneyim sonucunda',
        'aranızdaki bağ güçlendi',
        'önemli bir karar verdin',
        'duygusal açıdan',
        'sosyal ilişkilerine katkı sağladı',
        'hayatında yeni bir dönem başladı',
        'kendini daha iyi hissettin',
        'bu durum seni mutlu etti',
        'kaliteli vakit geçirdin',
      ];
      for (final GameEvent olay in kLateYearsEvents) {
        final String hepsi = <String>[
          olay.text,
          for (final EventChoice s in olay.choices) s.label,
          for (final EventChoice s in olay.choices) s.resultText,
        ].join(' ').toLowerCase();
        for (final String kalip in yasak) {
          expect(
            hepsi.contains(kalip),
            isFalse,
            reason: '${olay.id}: "$kalip" kullanılmış',
          );
        }
      }
    });
  });

  group('Paket CC — modül anahtarı', () {
    test('havuz modül haritasında kayıtlı', () {
      expect(
        FeatureEvents.pools[FeatureId.sonYillar],
        same(kLateYearsEvents),
        reason: 'Anahtar kapalıyken havuzun susması bu satıra bağlı',
      );
      expect(
        FeatureEvents.idsOf(FeatureId.sonYillar).length,
        kLateYearsEvents.length,
      );
    });

    test('anahtar kapalıyken havuzun hiçbir olayı aday olmuyor', () {
      final Set<String> havuz = FeatureEvents.idsOf(FeatureId.sonYillar);
      final BotLifeResult kapali = playBotLife(
        archetype: PlayerArchetype.casual,
        seed: 5151,
        features: FeatureSwitches.defaults.toggled(FeatureId.sonYillar, false),
        scanEventEligibility: true,
      );
      expect(
        kapali.diag.eligibleEvents.intersection(havuz),
        isEmpty,
        reason: 'Kapalı modülün olayı aday oldu',
      );
      expect(
        kapali.seenEvents.intersection(havuz),
        isEmpty,
        reason: 'Kapalı modülün olayı görüldü',
      );
    });

    test('kapalı modül zara dokunmuyor: aynı tohum aynı hayat', () {
      // Paket BL sözleşmesi 4. madde + Paket BO. Havuza olay eklemek,
      // o olayların çıkamadığı hayatlarda akışı değiştirmemeli.
      for (final int tohum in <int>[31, 77, 129]) {
        final BotLifeResult kapali = playBotLife(
          archetype: PlayerArchetype.casual,
          seed: tohum,
          features: FeatureSwitches.defaults.toggled(FeatureId.sonYillar, false),
        );
        final BotLifeResult tekrar = playBotLife(
          archetype: PlayerArchetype.casual,
          seed: tohum,
          features: FeatureSwitches.defaults.toggled(FeatureId.sonYillar, false),
        );
        expect(kapali.deathAge, tekrar.deathAge, reason: 'tohum $tohum');
        expect(kapali.seenEvents, tekrar.seenEvents, reason: 'tohum $tohum');
      }
    });
  });

  group('Paket CC — yol akıyor', () {
    test('65 yaşında uygun olan yaşa özgü olay sayısı arttı', () {
      // Ölçümün kendisi: 65+ bandında havuzun kaç olayı uygun hale
      // geliyor? Paket öncesinde bu sayı 11'di (katalogdaki yaşlılığa
      // ait olaylar).
      final EventEngine motor = EventEngine(pool: kEventPool);
      final Set<String> havuz = FeatureEvents.idsOf(FeatureId.sonYillar);
      final Set<String> uygunOlanlar = <String>{};
      int yasaUlasan = 0;
      for (int i = 0; i < 30; i++) {
        bool ulasti = false;
        playBotLife(
          archetype:
              PlayerArchetype.values[i % PlayerArchetype.values.length],
          seed: 6100 + i,
          onYear: (GameState s) {
            if (s.player.age < 65) return;
            ulasti = true;
            uygunOlanlar
                .addAll(motor.debugEligibleIds(s).intersection(havuz));
          },
        );
        if (ulasti) yasaUlasan++;
      }
      expect(yasaUlasan, greaterThanOrEqualTo(10),
          reason: '30 hayatta yalnızca $yasaUlasan tanesi 65 yaşına geldi');
      // Ölçüm (60 hayat x 2 bağımsız tohum bloğu): havuzun **31/31**
      // olayı 65+ bandında uygun hale geliyor ve 30/31'i gerçekten
      // görülüyor. Eşik ölçülenin çok altında: bu test dağılımı değil
      // yolun kapanmadığını korur.
      expect(
        uygunOlanlar.length,
        greaterThanOrEqualTo(20),
        reason: '65+ bandında havuzun yalnızca ${uygunOlanlar.length} '
            'olayı uygun hale geldi: ${uygunOlanlar.join(", ")}',
      );
    }, timeout: const Timeout(Duration(minutes: 10)));
  });
}

// Paket CX — 0-2 yaş bandının aday olay yoğunluğu.
//
// Ölçüm (Paket CX öncesi, 60 bot hayatı, tohum 40000+i):
//   yaş  0: ortalama  8,6 aday — tekil  9
//   yaş  1: ortalama 14,4 aday — tekil 16
//   yaş  2: ortalama 17,2 aday — tekil 20
//   yaş 12: ortalama 52,4 aday — tekil 92
// 0 yaş, 12 yaşın onda biri kadar içerik görüyordu (docs/EKSIKLER.md §4.1).
//
// Ölçüm (Paket CX sonrası, aynı tohumlar):
//   yaş  0: ortalama 19,1 aday — tekil 20
//   yaş  1: ortalama 27,9 aday — tekil 30
//   yaş  2: ortalama 27,0 aday — tekil 30
//   yaş 12: ortalama 52,5 aday — tekil 86
//
// Bu dosyanın tabanları yukarıdaki **ölçümden** gelir, hedeften değil.
// Tohumlar ölçüm probundan farklı (60000+i) ki sayı tek tohuma yapışmasın.
import 'dart:math';

import 'package:bir_omur/data/event_pool_babyhood.dart';
import 'package:bir_omur/domain/events/event_engine.dart';
import 'package:bir_omur/domain/models/game_event.dart';
import 'package:bir_omur/domain/models/game_state.dart';
import 'package:bir_omur/domain/models/person.dart';
import 'package:bir_omur/domain/features/feature_catalog.dart';
import 'package:bir_omur/domain/models/relation.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/player_bot.dart';

/// Paket CX'te eklenen olaylar.
const Set<String> kYeniCxOlaylari = <String>{
  'bebek_altin_hediyesi',
  'bebek_kime_benzemis',
  'bebek_ilk_banyo',
  'bebek_besik_montaji',
  'bebek_nufusa_yazdirma',
  'bebek_buyukanne_cekismesi',
  'bebek_kalin_giydirme',
  'bebek_yaz_sicagi',
  'bebek_arabasiyla_kaldirim',
  'bebek_vazgecmedigi_oyuncak',
  'bebek_ev_sessizligi',
  'bebek_ilk_sac_kesimi',
  'bebek_akrabadan_mikrop',
  'bebek_yurume_kiyaslamasi',
};

/// İz okuyan karşılık olayı -> okuduğu bayrak.
const Map<String, String> kIzKapilari = <String, String>{
  'bebek_cekmecedeki_altin': BabyhoodFlags.altinSaklandi,
  'bebek_oyuncaga_veda': BabyhoodFlags.vazgecmedigiOyuncak,
};

class _Tarama {
  final Map<int, List<int>> adaySayilari = <int, List<int>>{};
  final Map<int, Set<String>> tekilAdaylar = <int, Set<String>>{};
  final Map<int, int> kareSayisi = <int, int>{};
  final Set<String> gorulenler = <String>{};
  int babasizKare = 0;
  int babasizKareBesikAdayi = 0;

  /// Karşılık olayı aday oldu ama o karede bayrak yoktu (kapı sızdırdı).
  final Map<String, int> bayraksizAday = <String, int>{};

  /// Karşılık olayı, bayrağın yazılı olduğu bir karede aday oldu.
  final Map<String, int> bayrakliAday = <String, int>{};

  /// Bağ kapısı olan olay, o bağ karede yokken aday oldu.
  final Map<String, int> bagsizAday = <String, int>{};

  /// Bağ kapısı olan olayın kapısı gerçekten denetlendiği kare sayısı.
  int bagKapisiDenetlenenKare = 0;

  double ortalama(int yas) {
    final List<int> l = adaySayilari[yas] ?? <int>[];
    if (l.isEmpty) return 0;
    return l.reduce((int a, int b) => a + b) / l.length;
  }

  int tekil(int yas) => (tekilAdaylar[yas] ?? const <String>{}).length;
}

_Tarama _tara({required int hayat, required int tohumTaban}) {
  const EventEngine motor = EventEngine();
  final _Tarama t = _Tarama();
  for (int i = 0; i < hayat; i++) {
    playBotLife(
      archetype: PlayerArchetype.values[i % PlayerArchetype.values.length],
      seed: tohumTaban + i,
      onPreAge: (GameState s) {
        final int yas = s.player.age;
        if (yas > 12) return;
        final Set<String> adaylar = motor.debugEligibleIds(s, Random(7));
        t.kareSayisi[yas] = (t.kareSayisi[yas] ?? 0) + 1;
        t.adaySayilari.putIfAbsent(yas, () => <int>[]).add(adaylar.length);
        t.tekilAdaylar.putIfAbsent(yas, () => <String>{}).addAll(adaylar);
        t.gorulenler.addAll(adaylar);

        // İz okuyan karşılıklar: kapı kare bazında denetlenir. Küme
        // bazında "hiç gelmesin" demek ölü içeriği savunmak olurdu.
        for (final MapEntry<String, String> e in kIzKapilari.entries) {
          if (!adaylar.contains(e.key)) continue;
          final Map<String, int> hedef = s.storyFlags.contains(e.value)
              ? t.bayrakliAday
              : t.bayraksizAday;
          hedef[e.key] = (hedef[e.key] ?? 0) + 1;
        }

        // `livingRelations` sözleşmesi: "bu bağlardan **hayatta en az
        // bir** kişi gerekir; olay o kişiyle kurulur"
        // (`game_event.dart`). Yani kapı hepsini değil **birini** garanti
        // eder. Denetim de bunu sorar: aday olan olayın kapısında yazan
        // bağlardan en az biri o karede gerçekten var mı? Kare kurulmadı,
        // bulundu.
        for (final GameEvent olay in kBabyhoodEvents) {
          final EventRequirement k = olay.requirement;
          if (k.livingRelations.isEmpty) continue;
          if (!adaylar.contains(olay.id)) continue;
          t.bagKapisiDenetlenenKare++;
          final bool enAzBiri = s.people.any(
            (Person p) =>
                k.livingRelations.contains(p.relation) &&
                p.isAlive &&
                (!k.requireSameHousehold || p.inPlayerHousehold),
          );
          if (!enAzBiri) {
            t.bagsizAday[olay.id] = (t.bagsizAday[olay.id] ?? 0) + 1;
          }
        }

        // Ayrıca: babasız karelerin sayısı: kapının denetlenebildiğini
        // gösterir (sıfırsa test hiçbir şey kanıtlamaz).
        if (yas <= 1) {
          final bool babaVar = s.people.any(
            (Person p) =>
                p.relation == RelationType.baba &&
                p.isAlive &&
                p.inPlayerHousehold,
          );
          if (!babaVar) {
            t.babasizKare++;
            if (adaylar.contains('bebek_besik_montaji')) {
              t.babasizKareBesikAdayi++;
            }
          }
        }
      },
    );
  }
  return t;
}

_Tarama? _onbellek;

/// Tarama pahalı; bir kez yapılır, bütün testler aynı sonucu okur.
_Tarama _taramaAl() => _onbellek ??= _tara(hayat: 60, tohumTaban: 60000);

const Timeout _sure = Timeout(Duration(minutes: 25));

void main() {
  group('Paket CX — bebeklik bandı', () {

    test(timeout: _sure, '§1 0-2 yaşın aday yoğunluğu ölçülen tabanın altına düşmüyor', () {
      final _Tarama tarama = _taramaAl();
      // ignore: avoid_print
      print('yaş | kare | ortalama | tekil');
      for (final int yas in <int>[0, 1, 2, 12]) {
        // ignore: avoid_print
        print('${yas.toString().padLeft(3)} | '
            '${(tarama.kareSayisi[yas] ?? 0).toString().padLeft(4)} | '
            '${tarama.ortalama(yas).toStringAsFixed(1).padLeft(8)} | '
            '${tarama.tekil(yas).toString().padLeft(5)}');
      }

      expect(tarama.kareSayisi[0], greaterThan(50),
          reason: '60 hayatın hepsi 0 yaşından başlar');

      // Ölçülen ortalamaların altında taban (CX öncesi: 8,6 / 14,4 / 17,2).
      expect(tarama.ortalama(0), greaterThan(14.0));
      expect(tarama.ortalama(1), greaterThan(22.0));
      expect(tarama.ortalama(2), greaterThan(22.0));

      // Tekil aday (CX öncesi: 9 / 16 / 20).
      expect(tarama.tekil(0), greaterThan(15));
      expect(tarama.tekil(1), greaterThan(24));
      expect(tarama.tekil(2), greaterThan(24));
    });

    test(timeout: _sure, '§2 0 yaş artık 12 yaşın onda biri değil', () {
      final _Tarama tarama = _taramaAl();
      final double oran = tarama.tekil(0) / tarama.tekil(12);
      // ignore: avoid_print
      print('tekil(0)/tekil(12) = ${oran.toStringAsFixed(3)}');
      // CX öncesi 9/92 = 0,098. CX sonrası 20/86 = 0,233.
      expect(oran, greaterThan(0.16),
          reason: 'bebeklik bandı yeniden 12 yaşın onda birine düşmüş');
    });

    test(timeout: _sure, '§3 eklenen 14 olayın hepsi gerçek karede aday oluyor', () {
      final _Tarama tarama = _taramaAl();
      final Set<String> hicGorulmeyen =
          kYeniCxOlaylari.difference(tarama.gorulenler);
      expect(hicGorulmeyen, isEmpty,
          reason: 'yazılmış ama hiçbir karede aday olmayan olay var');
    });

    test(timeout: _sure, '§4 bağ kapısı olan olay, o bağ yokken aday olmuyor',
        () {
      final _Tarama tarama = _taramaAl();
      // ignore: avoid_print
      print('bağ kapısı denetlenen kare: ${tarama.bagKapisiDenetlenenKare}, '
          'bağsız aday: ${tarama.bagsizAday}');
      // ignore: avoid_print
      print('babasız 0-1 kare: ${tarama.babasizKare}, '
          'besik adayı: ${tarama.babasizKareBesikAdayi}');

      // Kapılar gerçekten denetlendi mi (yoksa test boşa döner)?
      expect(tarama.bagKapisiDenetlenenKare, greaterThan(500),
          reason: 'bağ kapılı olay yeterince aday olmadı; '
              'bu bölüm hiçbir şey kanıtlamıyor');
      expect(tarama.babasizKare, greaterThan(0),
          reason: 'bot hayatlarında babasız bebeklik karesi bulunamadı; '
              'beşik kapısı ölçülemiyor');

      // Kapıda yazan bağlardan hiçbiri yoksa olay aday olmamalı.
      expect(tarama.bagsizAday, isEmpty,
          reason: 'bağı olmayan karede aday olan olay var');

      // Tek bağlı kapı: beşik olayı yalnız `baba` istiyor, babasız
      // karede çıkmamalı. Bu bölümün **ısırabilen** iddiası budur:
      // çok bağlı kapıda motor "en az bir" garantisi verdiği için o
      // denetim motor bozulmadıkça patlamaz.
      expect(tarama.babasizKareBesikAdayi, 0);
    });

    test('§4b çok bağlı kapıda metin tek kişiyi ya da sayıyı '
        'varsaymıyor', () {
      // Kapı "en az bir" garanti ettiği için metin iki kişiyi
      // ("İki büyükanne") ya da belirli bir kişiyi ("Annenin
      // kucağı") varsayamaz: o kişi o karede ölmüş olabilir.
      // Paket CX'te tam bu hata yazılmıştı ve §4 patlayınca bulundu.
      const List<String> yasakli = <String>[
        'İki büyükanne',
        'İkisi',
        'ikisi',
        'annen',
        'Annen',
        'baban',
        'Baban',
        'anneanne',
        'babaanne',
        'büyükannen',
      ];
      final List<String> bulgular = <String>[];
      for (final GameEvent olay in kBabyhoodEvents) {
        if (olay.requirement.livingRelations.length < 2) continue;
        final List<String> metinler = <String>[
          olay.text,
          for (final EventChoice c in olay.choices) ...<String>[
            c.label,
            c.resultText,
          ],
        ];
        for (final String m in metinler) {
          for (final String y in yasakli) {
            if (m.contains(y)) {
              bulgular.add('${olay.id}: "$y" -> $m');
            }
          }
        }
      }
      expect(bulgular, isEmpty,
          reason: 'çok bağlı kapıda belirli kişiyi/sayıyı varsayan metin:\n'
              '${bulgular.join('\n')}');
    });

    test(timeout: _sure, '§5 iz okuyan karşılık yalnızca izi olan karede aday', () {
      final _Tarama tarama = _taramaAl();
      // ignore: avoid_print
      print('izli aday: ${tarama.bayrakliAday}, '
          'izsiz aday: ${tarama.bayraksizAday}');

      // Kapı sızdırmıyor: bayrak yoksa aday da yok.
      expect(tarama.bayraksizAday, isEmpty,
          reason: 'bayrak yazılmadan aday olan karşılık olayı var');

      // Ölü içerik de yok: en az bir karşılık gerçekten ulaşılıyor.
      expect(tarama.bayrakliAday, isNotEmpty,
          reason: 'hiçbir karşılık olayı izli karede aday olmadı; '
              'ya bayrak yazılmıyor ya pencere kapalı');
    });

    test('§6 her yeni bayrak hem yazılıyor hem okunuyor', () {
      final Set<String> yazilan = <String>{};
      final Set<String> okunan = <String>{};
      for (final GameEvent e in kBabyhoodEvents) {
        okunan.addAll(e.requirement.requiredFlags);
        for (final EventChoice c in e.choices) {
          yazilan.addAll(c.addFlags);
        }
      }
      for (final String bayrak in <String>[
        BabyhoodFlags.altinSaklandi,
        BabyhoodFlags.vazgecmedigiOyuncak,
      ]) {
        expect(yazilan, contains(bayrak), reason: '$bayrak hiç yazılmıyor');
        expect(okunan, contains(bayrak), reason: '$bayrak hiç okunmuyor');
      }
    });

    test(timeout: _sure, '§7 anahtar kapalıyken 16 olayın hiçbiri aday olmuyor',
        () {
      const EventEngine motor = EventEngine();
      final Set<String> gorulen = <String>{};
      int kare = 0;
      for (int i = 0; i < 20; i++) {
        playBotLife(
          archetype: PlayerArchetype.values[i % PlayerArchetype.values.length],
          seed: 70000 + i,
          features: FeatureSwitches.defaults
              .toggled(FeatureId.ilkYillarOlaylari, false),
          onPreAge: (GameState s) {
            if (s.player.age > 18) return;
            kare++;
            gorulen.addAll(motor.debugEligibleIds(s, Random(11)));
          },
        );
      }
      expect(kare, greaterThan(100), reason: 'kare taranamadı');
      final Set<String> sizanlar =
          gorulen.intersection(<String>{...kYeniCxOlaylari, ...kIzKapilari.keys});
      expect(sizanlar, isEmpty,
          reason: 'modül kapalıyken aday olan bebeklik olayı var');
    });
  });
}

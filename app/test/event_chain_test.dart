/// Çok adımlı olay zincirlerinin denetimi.
///
/// Bir zincirin ikinci adımı, birinci adımın bırakmadığı bir iz ararsa
/// ya da birinciden daha erken bir yaş aralığında durursa, o adım
/// oyunda **hiç çıkmaz**. Ekranda hiçbir belirti olmaz: olay sessizce
/// yok sayılır. Bu testler o sessiz hatayı yakalar.
library;

import 'dart:math';

import 'package:bir_omur/data/event_pool.dart';
import 'package:bir_omur/data/event_pool_chains.dart';
import 'package:bir_omur/domain/events/event_engine.dart';
import 'package:bir_omur/domain/generation/life_generator.dart';
import 'package:bir_omur/domain/models/game_event.dart';
import 'package:bir_omur/domain/models/game_state.dart';
import 'package:flutter_test/flutter_test.dart';

GameEvent olay(String id) =>
    kChainEvents.firstWhere((GameEvent e) => e.id == id);

/// Bir zincirin adımları, baştan sona.
class Zincir {
  const Zincir(this.ad, this.adimlar);

  final String ad;

  /// Sırayla adım kimlikleri. Dallanma varsa her dal ayrı zincirdir.
  final List<String> adimlar;
}

/// Dosyadaki zincirler, dal dal.
const List<Zincir> kZincirler = <Zincir>[
  Zincir('Öğretmenin defteri — inanan dal', <String>[
    'zincir_ogretmen_1',
    'zincir_ogretmen_2',
    'zincir_ogretmen_3',
    'zincir_ogretmen_4',
  ]),
  Zincir('Öğretmenin defteri — geçiştiren dal', <String>[
    'zincir_ogretmen_1',
    'zincir_ogretmen_gec',
    'zincir_ogretmen_4',
  ]),
  Zincir('Emanet para — bekleyen dal', <String>[
    'zincir_emanet_1',
    'zincir_emanet_2',
    'zincir_emanet_3_bekle',
  ]),
  Zincir('Emanet para — isteyen dal', <String>[
    'zincir_emanet_1',
    'zincir_emanet_2',
    'zincir_emanet_3_iste',
  ]),
  Zincir('Boş arsa — sahip çıkan dal', <String>[
    'zincir_arsa_1',
    'zincir_arsa_2',
    'zincir_arsa_3',
  ]),
  Zincir('Boş arsa — karışmayan dal', <String>[
    'zincir_arsa_1',
    'zincir_arsa_2_gec',
    'zincir_arsa_3',
  ]),
  Zincir('İş yerindeki haksızlık — savunan dal', <String>[
    'zincir_isyeri_1',
    'zincir_isyeri_2',
    'zincir_isyeri_3',
  ]),
  Zincir('İş yerindeki haksızlık — susan dal', <String>[
    'zincir_isyeri_1',
    'zincir_isyeri_2_sus',
    'zincir_isyeri_3',
  ]),
];

void main() {
  group('Zincir yapısı', () {
    test('en az üç adımlı dört zincir var', () {
      expect(kZincirler.length, greaterThanOrEqualTo(8));
      for (final Zincir z in kZincirler) {
        expect(z.adimlar.length, greaterThanOrEqualTo(3), reason: z.ad);
      }
    });

    test('her adım havuzda gerçekten var', () {
      for (final Zincir z in kZincirler) {
        for (final String id in z.adimlar) {
          expect(
            kEventPool.where((GameEvent e) => e.id == id).length,
            1,
            reason: '${z.ad}: $id havuzda yok ya da iki kez var',
          );
        }
      }
    });

    test('olay kimlikleri havuzun tamamında benzersiz', () {
      final Set<String> gorulen = <String>{};
      for (final GameEvent e in kEventPool) {
        expect(gorulen.add(e.id), isTrue, reason: 'Tekrar eden: ${e.id}');
      }
    });

    test('her adımın aradığı iz kendinden önceki bir adımdan geliyor', () {
      // Sessiz hata sınıfı: hiç üretilmeyen bir iz arayan adım oyunda
      // asla çıkmaz ve bunu haber veren hiçbir şey yoktur.
      for (final Zincir z in kZincirler) {
        final Set<String> birikenIzler = <String>{};
        for (int i = 0; i < z.adimlar.length; i++) {
          final GameEvent e = olay(z.adimlar[i]);
          for (final String istenen in e.requirement.requiredFlags) {
            expect(
              birikenIzler,
              contains(istenen),
              reason:
                  '${z.ad}: ${e.id} "$istenen" izini istiyor ama '
                  'önceki adımların hiçbiri bunu bırakmıyor',
            );
          }
          for (final EventChoice c in e.choices) {
            birikenIzler.addAll(c.addFlags);
          }
        }
      }
    });

    test('adımların yaş aralıkları ileri gidiyor', () {
      for (final Zincir z in kZincirler) {
        for (int i = 1; i < z.adimlar.length; i++) {
          final GameEvent onceki = olay(z.adimlar[i - 1]);
          final GameEvent simdiki = olay(z.adimlar[i]);
          expect(
            simdiki.requirement.maxAge,
            greaterThan(onceki.requirement.minAge),
            reason:
                '${z.ad}: ${simdiki.id} (${simdiki.requirement.minAge}-'
                '${simdiki.requirement.maxAge}) ${onceki.id} '
                '(${onceki.requirement.minAge}-'
                '${onceki.requirement.maxAge}) bitmeden kapanıyor',
          );
        }
      }
    });

    test('kişiye bağlı adımın rolü önceki bir adımda kilitleniyor', () {
      // personRole ile aranan rol, önceki bir adımın rememberPersonAs'ı
      // tarafından bırakılmamışsa o adım hiç çıkmaz.
      for (final Zincir z in kZincirler) {
        final Set<String> kilitliRoller = <String>{};
        for (final String id in z.adimlar) {
          final GameEvent e = olay(id);
          final String? rol = e.requirement.personRole;
          if (rol != null) {
            expect(
              kilitliRoller,
              contains(rol),
              reason:
                  '${z.ad}: ${e.id} "$rol" rolünü arıyor ama önceki '
                  'adımların hiçbiri bu rolü kilitlemiyor',
            );
          }
          for (final EventChoice c in e.choices) {
            final String? hatirla = c.rememberPersonAs;
            if (hatirla != null) kilitliRoller.add(hatirla);
          }
        }
      }
    });

    test('ilk adımlar kendi izleriyle kendilerini kapatıyor', () {
      // Zincirin başı bir kez çıkmalı. Tekrar açılmaması, bıraktığı
      // izlerin forbiddenFlags'inde olmasıyla sağlanır.
      for (final String id in <String>[
        'zincir_ogretmen_1',
        'zincir_emanet_1',
        'zincir_arsa_1',
        'zincir_isyeri_1',
      ]) {
        final GameEvent e = olay(id);
        final Set<String> birakilan = <String>{
          for (final EventChoice c in e.choices) ...c.addFlags,
        };
        expect(
          e.requirement.forbiddenFlags,
          containsAll(birakilan),
          reason: '$id bıraktığı izle kendini kapatmıyor',
        );
      }
    });

    test('dallar birbirini dışlıyor', () {
      // İnanan dalın izini taşıyan oyuncu geçiştiren dalın adımını
      // görmemeli; tersi de geçerli.
      expect(
        olay('zincir_ogretmen_2').requirement.requiredFlags,
        contains(ChainFlags.ogretmeneInandi),
      );
      expect(
        olay('zincir_ogretmen_gec').requirement.requiredFlags,
        contains(ChainFlags.ogretmeniGecti),
      );
      expect(
        olay('zincir_emanet_3_bekle').requirement.requiredFlags,
        contains(ChainFlags.borcuBekledi),
      );
      expect(
        olay('zincir_emanet_3_iste').requirement.requiredFlags,
        contains(ChainFlags.borcuIstedi),
      );
    });

    test('her seçeneğin özgün bir sonuç metni var', () {
      final Set<String> metinler = <String>{};
      for (final GameEvent e in kChainEvents) {
        expect(e.choices.length, greaterThanOrEqualTo(2), reason: e.id);
        for (final EventChoice c in e.choices) {
          expect(c.resultText.trim(), isNotEmpty, reason: '${e.id}/${c.id}');
          expect(
            metinler.add(c.resultText),
            isTrue,
            reason: '${e.id}/${c.id}: aynı sonuç metni iki kez kullanılmış',
          );
        }
      }
    });
  });

  group('Zincir gerçekten yürüyor', () {
    /// Zincirin adımlarını sırayla uygular ve izleri biriktirir.
    ///
    /// Amaç oyunun rastgeleliğini taklit etmek değil: her adımın,
    /// kendinden öncekilerin bıraktığı durumda **uygun** sayıldığını
    /// göstermek.
    test('her dal baştan sona uygulanabiliyor', () {
      const EventEngine motor = EventEngine();

      for (final Zincir z in kZincirler) {
        GameState s = LifeGenerator.seeded(5)
            .generate(mode: StartMode.tamamenRastgele)
            .copyWith(pendingEvent: null);

        for (int i = 0; i < z.adimlar.length; i++) {
          final GameEvent e = olay(z.adimlar[i]);

          // Adımın yaşına gel ve koşullarını sağla.
          s = s.copyWith(player: s.player.copyWith(age: e.requirement.minAge));

          // İzler önceki adımlardan geliyor; burada yalnızca yaş ve
          // iz durumu denetleniyor.
          for (final String iz in e.requirement.requiredFlags) {
            expect(
              s.storyFlags,
              contains(iz),
              reason:
                  '${z.ad}: ${e.id} adımına gelindiğinde "$iz" izi '
                  'yok',
            );
          }
          expect(
            e.requirement.forbiddenFlags.any(s.storyFlags.contains),
            isFalse,
            reason: '${z.ad}: ${e.id} kendi yasak izini taşıyor',
          );

          // Bir sonraki adımın istediği izi üreten seçeneği uygula.
          // Dallanmada "ilk seçenek" yanlış dala sapıyordu.
          final GameEvent? sonrakiAdim = i + 1 < z.adimlar.length
              ? olay(z.adimlar[i + 1])
              : null;
          final Set<String> gereken =
              sonrakiAdim?.requirement.requiredFlags ?? const <String>{};
          final EventChoice secim = e.choices.firstWhere(
            (EventChoice c) => gereken.every(
              (String iz) =>
                  s.storyFlags.contains(iz) || c.addFlags.contains(iz),
            ),
            orElse: () => e.choices.first,
          );
          s = s.copyWith(
            storyFlags: <String>{...s.storyFlags, ...secim.addFlags},
          );
        }
      }

      // Motor gerçekten bu havuzu görüyor mu?
      // Dallar ortak adım paylaşıyor; containsAll her beklenen değer
      // için ayrı bir eleman istediğinden küme olarak verilir.
      expect(
        motor.pool.map((GameEvent e) => e.id).toSet(),
        containsAll(<String>{for (final Zincir z in kZincirler) ...z.adimlar}),
      );
    });

    test('zincir başları koşulları sağlayan bir hayatta uygun bulunuyor', () {
      // Kişisiz zincir başı: yalnızca yaşa bağlı, her hayatta çıkabilmeli.
      const EventEngine motor = EventEngine();
      final GameEvent ilk = olay('zincir_arsa_1');
      final GameState s = LifeGenerator.seeded(5)
          .generate(mode: StartMode.tamamenRastgele)
          .copyWith(pendingEvent: null)
          .copyWith(
            player: LifeGenerator.seeded(5)
                .generate(mode: StartMode.tamamenRastgele)
                .player
                .copyWith(age: ilk.requirement.minAge),
          );
      expect(motor.debugMatches(s, ilk), isTrue);
      expect(motor.debugEligibleIds(s, Random(1)), contains(ilk.id));
    });
  });
}

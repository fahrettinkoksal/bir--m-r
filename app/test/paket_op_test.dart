import 'dart:math';

import 'package:bir_omur/data/activity_catalog.dart';
import 'package:bir_omur/data/event_pool.dart';
import 'package:bir_omur/data/event_pool_childhood.dart';
import 'package:bir_omur/domain/activities/activity_engine.dart';
import 'package:bir_omur/domain/generation/life_generator.dart';
import 'package:bir_omur/domain/models/game_event.dart';
import 'package:bir_omur/domain/models/relation.dart';
import 'package:bir_omur/state/game_controller.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/active_player.dart';

/// Paket O + P denetimleri.
///
/// İki iş bir arada sınanır:
/// * **D-125** — oyuncunun eylemleri ilerleme sayılır; ölü sanılan
///   içeriğin büyük bölümü bu yüzden çıkmıyordu.
/// * **D-126** — 0-17 yaş havuzu; çocukluk artık boş geçmiyor.
void main() {
  // ===================================================================
  // D-125: ilerleme sayacı
  // ===================================================================
  group('D-125 ilerleme sayacı', () {
    test('aktivite yapmak ilerleme sayılır', () {
      final GameController c = GameController(random: Random(7));
      c.startNewLife(mode: StartMode.tamamenRastgele, seed: 7);
      c.debugSetState(
        c.state!.copyWith(
          player: c.state!.player.copyWith(age: 24, wallet: 50000),
          pendingEvent: null,
          progressSinceLastEvent: 0,
          extraEventsThisAge: 0,
        ),
      );

      final int once = c.state!.progressSinceLastEvent;
      c.performActivity(activityActionById('sac_kestir')!);
      expect(
        c.state!.progressSinceLastEvent,
        greaterThan(once),
        reason: 'Aktivite ilerleme saymıyor: D-125 geri gelmiş.',
      );
    });

    test('yeterli ilerlemede aynı yaşta ek olay gelir', () {
      // Üç eylem sonrası motor ek olay sunabilmeli (D-023, D-024).
      bool ekGeldi = false;
      for (int seed = 0; seed < 40 && !ekGeldi; seed++) {
        final GameController c = GameController(random: Random(seed));
        c.startNewLife(mode: StartMode.tamamenRastgele, seed: seed);
        c.debugSetState(
          c.state!.copyWith(
            player: c.state!.player.copyWith(age: 30, wallet: 200000),
            pendingEvent: null,
            progressSinceLastEvent: 0,
            extraEventsThisAge: 0,
          ),
        );
        for (int i = 0; i < 4; i++) {
          if (c.state!.hasNotice) c.dismissNotice();
          if (c.state!.hasPendingEvent) {
            ekGeldi = true;
            break;
          }
          c.performActivity(activityActionById('kosu')!);
        }
      }
      expect(
        ekGeldi,
        isTrue,
        reason: 'Aktivite yapan oyuncuya aynı yaşta hiç ek olay çıkmıyor.',
      );
    });
  });

  // ===================================================================
  // Paket O: ölü sanılan on hikâye izi
  // ===================================================================
  test('on hikâye izi aktif oyuncuda gerçekten konuyor', () {
    // Bu izler "ölü" diye raporlanmıştı. Gerçek sebep izlerin kendisi
    // değil, simülasyonun oyuncu gibi oynamamasıydı (D-125).
    const List<String> hedefler = <String>[
      'cocuga_soz_verildi',
      'esle_konusuldu',
      'is_arkadasina_yardim',
      'zor_musteri_sakin',
      'zincir_isyerinde_savundu',
      'zincir_isyerinde_sustu',
      'zincir_kidemli_oldu',
      'emeklilik_rutini',
      'orta_eve_soz_verdi',
      'cocuk_ilk_gun_destek',
    ];

    final Set<String> konan = <String>{};
    for (int seed = 0; seed < 120; seed++) {
      konan.addAll(playActiveLife(seed).storyFlags);
    }
    final List<String> eksik =
        hedefler.where((String f) => !konan.contains(f)).toList();
    expect(
      eksik,
      isEmpty,
      reason: 'Bu izler 120 aktif hayatta hiç konmadı: ${eksik.join(", ")}',
    );
  });

  // ===================================================================
  // Paket P: çocukluk içeriği
  // ===================================================================
  group('D-126 çocukluk havuzu', () {
    test('havuza kayıtlı ve kimlikleri benzersiz', () {
      final Set<String> havuz =
          kEventPool.map((GameEvent e) => e.id).toSet();
      for (final GameEvent e in kChildhoodEvents) {
        expect(havuz.contains(e.id), isTrue, reason: '${e.id} havuzda yok');
      }
      expect(
        kChildhoodEvents.map((GameEvent e) => e.id).toSet().length,
        kChildhoodEvents.length,
      );
    });

    test('her yaş bandı ölçülmüş tabanın altına düşmez', () {
      // Ölçüm: aktif oyuncu simülasyonu (120 hayat). Sayılar bugünkü
      // gerçek çıktının biraz altına konur; içerik silinirse test düşer.
      const Map<String, int> taban = <String, int>{
        '0-5': 20,
        '6-12': 44,
        '13-17': 55,
      };
      String bant(int yas) {
        if (yas <= 5) return '0-5';
        if (yas <= 12) return '6-12';
        if (yas <= 17) return '13-17';
        return 'sonra';
      }

      final Map<String, Set<String>> gorulen = <String, Set<String>>{};
      for (int seed = 0; seed < 120; seed++) {
        playActiveLife(seed, recordAges: true).eventAges.forEach(
          (String id, int yas) {
            gorulen.putIfAbsent(bant(yas), () => <String>{}).add(id);
          },
        );
      }
      taban.forEach((String b, int en) {
        final int sayi = (gorulen[b] ?? <String>{}).length;
        // ignore: avoid_print
        print('PAKET-P bant $b: $sayi farklı olay (taban $en)');
        expect(sayi, greaterThanOrEqualTo(en), reason: '$b bandı zayıfladı');
      });
    });

    test('seçenekler gerçekten farklı sonuç verir', () {
      // "Her seçenek +2 mutluluk" olmayacak: bir olayın seçenekleri
      // birbirinden etki ya da iz olarak ayrılmalı.
      final List<String> tekduze = <String>[];
      for (final GameEvent e in kChildhoodEvents) {
        final Set<String> imza = e.choices
            .map(
              (EventChoice c) => <Object>[
                c.happiness,
                c.health,
                c.intelligence,
                c.charisma,
                c.appearance,
                c.bond,
                c.money,
                c.addFlags.toList()..sort(),
                c.startsFriendship,
                c.startsSchoolFriendship,
                c.rememberPersonAs ?? '',
              ].join('|'),
            )
            .toSet();
        if (imza.length < e.choices.length) tekduze.add(e.id);
      }
      expect(
        tekduze,
        isEmpty,
        reason: 'Seçenekleri aynı sonucu veren olaylar: ${tekduze.join(", ")}',
      );
    });

    test('kardeş anlatan olay kardeş şartı arar', () {
      // WRITING_STYLE_TR §12: metin GameState ile çelişmez.
      final List<String> hatali = <String>[];
      for (final GameEvent e in kChildhoodEvents) {
        final bool kardestenBahsediyor =
            RegExp(r'\bkardeş', caseSensitive: false).hasMatch(e.text);
        if (!kardestenBahsediyor) continue;
        final bool sart = e.requirement.livingRelations
            .any((RelationType r) => r == RelationType.kardes);
        if (!sart) hatali.add(e.id);
      }
      expect(hatali, isEmpty, reason: 'Kardeşsiz çıkabilir: $hatali');
    });

    test('metinler kısa tutulur', () {
      // Mobil oyun: 2-4 kısa cümle (WRITING_STYLE_TR §8).
      final List<String> uzun = <String>[];
      for (final GameEvent e in kChildhoodEvents) {
        if (e.text.length > 320) uzun.add('${e.id} (${e.text.length})');
      }
      expect(uzun, isEmpty, reason: 'Çok uzun olay metni: ${uzun.join(", ")}');
    });

    test('olaylar oyuncunun adıyla başlamaz', () {
      // WRITING_STYLE_TR §10.
      final List<String> hatali = <String>[];
      for (final GameEvent e in kChildhoodEvents) {
        if (e.text.startsWith('{ad}') || e.text.startsWith('{isim}')) {
          hatali.add(e.id);
        }
      }
      expect(hatali, isEmpty);
    });
  });

  // ===================================================================
  // D-127: aktivite sonuç metni
  // ===================================================================
  test('aktivite sonuçları "tamamlandı" demiyor', () {
    final GameController c = GameController(random: Random(11));
    c.startNewLife(mode: StartMode.tamamenRastgele, seed: 11);
    c.debugSetState(
      c.state!.copyWith(
        player: c.state!.player.copyWith(age: 28, wallet: 300000),
        pendingEvent: null,
      ),
    );
    for (final String id in <String>[
      'kosu',
      'esneme',
      'sac_kestir',
    ]) {
      final ActivityAction? eylem = activityActionById(id);
      if (eylem == null) continue;
      final ActivityOutcome? sonuc = c.performActivity(eylem);
      if (sonuc == null || !sonuc.applied) continue;
      expect(
        sonuc.text,
        isNot(contains('tamamlandı')),
        reason: '$id hâlâ mekanik sonuç metni veriyor.',
      );
      if (c.state!.hasNotice) c.dismissNotice();
    }
  });
}

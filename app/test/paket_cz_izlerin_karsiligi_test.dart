// Paket CZ — sessiz hikâye izlerinin karşılığı.
//
// Paket AR, bir seçimin geleceğe bıraktığı 22 işaretin **hiç
// okunmadığını** bulmuştu: oyuncu seçiyor, oyun not alıyor, hiçbir yer
// o notu açmıyor. Bu dosya o 22 ize yazılan karşılıkları denetler.
//
// **Ölçüm (150 bot hayatı, tohum 80000+i).** İzlerin yazılma sıklığı ve
// yaşı `event_pool_traces.dart` başlığındaki tabloda; pencereler oradan
// türetildi. Bu bekçinin tabanları da ölçümden gelir, hedeften değil.
import 'dart:math';

import 'package:bir_omur/data/event_pool_traces.dart';
import 'package:bir_omur/domain/events/event_engine.dart';
import 'package:bir_omur/domain/features/feature_catalog.dart';
import 'package:bir_omur/domain/models/game_event.dart';
import 'package:bir_omur/domain/models/game_state.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/player_bot.dart';

class _Tarama {
  /// Karşılık olayı aday oldu ve o karede izi **vardı**.
  final Map<String, int> izliAday = <String, int>{};

  /// Karşılık olayı aday oldu ama o karede izi **yoktu** (kapı sızdırdı).
  final Map<String, int> izsizAday = <String, int>{};

  /// İz o karede yazılıydı (karşılığın ulaşılabilirlik tabanı).
  final Map<String, int> izliKare = <String, int>{};

  /// Karşılık olayı o hayatta **gerçekten çıktı** (`seenEventIds`).
  ///
  /// Bu alan olmadan ölçüm yanıltıyordu: `debugEligibleIds` görülmüş
  /// tek seferlik olayı dışlar, yani ilk uygun yılında çıkan bir olay
  /// "hiç aday olmadı" gibi görünür. Paket CZ'de tam bu oldu
  /// (`iz_uykusuz_gecelerin_bedeli`: 47 karede aday değil ama 47
  /// karede de **görülmüş** işaretli). Paket CR'ın kör noktasının
  /// aynısı: araç neyi sorduğuna dikkat etmeli.
  final Map<String, int> cikti = <String, int>{};

  int kare = 0;
}

_Tarama? _onbellek;

_Tarama _taramaAl() {
  if (_onbellek != null) return _onbellek!;
  const EventEngine motor = EventEngine();
  final _Tarama t = _Tarama();
  // Olay -> okuduğu iz (tek iz okuyorlar; çoklu olsa hepsi gerekirdi).
  final Map<String, String> kapilar = <String, String>{
    for (final GameEvent e in kTraceEchoEvents)
      e.id: e.requirement.requiredFlags.single,
  };

  for (int i = 0; i < 150; i++) {
    playBotLife(
      archetype: PlayerArchetype.values[i % PlayerArchetype.values.length],
      seed: 80000 + i,
      onPreAge: (GameState s) {
        t.kare++;
        final Set<String> adaylar = motor.debugEligibleIds(s, Random(17));
        for (final MapEntry<String, String> g in kapilar.entries) {
          final bool izVar = s.storyFlags.contains(g.value);
          if (izVar) {
            t.izliKare[g.key] = (t.izliKare[g.key] ?? 0) + 1;
            if (s.seenEventIds.contains(g.key)) {
              t.cikti[g.key] = (t.cikti[g.key] ?? 0) + 1;
            }
          }
          if (!adaylar.contains(g.key)) continue;
          if (izVar) {
            t.izliAday[g.key] = (t.izliAday[g.key] ?? 0) + 1;
          } else {
            t.izsizAday[g.key] = (t.izsizAday[g.key] ?? 0) + 1;
          }
        }
      },
    );
  }
  return _onbellek = t;
}

const Timeout _sure = Timeout(Duration(minutes: 30));

void main() {
  group('Paket CZ — izlerin karşılığı', () {
    test('§1 her karşılık tek bir izi okur ve havuz kayıtlı', () {
      expect(kTraceEchoEvents.length, 22);
      for (final GameEvent e in kTraceEchoEvents) {
        expect(e.requirement.requiredFlags.length, 1,
            reason: '${e.id} tek iz okumuyor; bekçinin kapı eşlemesi '
                'bozulur');
        // Pencere geniş olmalı: iz her yaşta yazılabiliyor.
        expect(e.requirement.maxAge, greaterThanOrEqualTo(100),
            reason: '${e.id} penceresi dar; iz yazıldıktan sonra '
                'ölçümde 21-88 yıl yaşanıyor (Paket CD dersi)');
      }
      // Modül kataloğa ve FeatureEvents'e bağlı olmalı.
      expect(FeatureId.values.map((FeatureId f) => f.saveKey),
          contains('izlerin_karsiligi'));
    });

    test(timeout: _sure, '§2 kapı sızdırmıyor: izi olmayan karede aday yok',
        () {
      final _Tarama t = _taramaAl();
      // ignore: avoid_print
      print('taranan kare ${t.kare}');
      // ignore: avoid_print
      print('izsiz aday: ${t.izsizAday}');
      expect(t.izsizAday, isEmpty,
          reason: 'izi yazılmadan aday olan karşılık olayı var');
    });

    test(timeout: _sure, '§3 yazılan izlerin karşılığı gerçekten ulaşılıyor',
        () {
      final _Tarama t = _taramaAl();
      final List<String> izliAmaUlasilmayan = <String>[];
      for (final GameEvent e in kTraceEchoEvents) {
        final int izli = t.izliKare[e.id] ?? 0;
        final int aday = t.izliAday[e.id] ?? 0;
        final int ciktiKare = t.cikti[e.id] ?? 0;
        // Ulaşılabilirlik: ya aday olmuş ya da gerçekten çıkmış.
        // Yalnız "aday" sorulsa, ilk uygun yılında çıkan tek seferlik
        // olay ulaşılamaz görünürdü.
        if (izli > 0 && aday == 0 && ciktiKare == 0) {
          izliAmaUlasilmayan.add(e.id);
        }
      }
      // ignore: avoid_print
      print('izli kare sayısı: ${t.izliKare}');
      // ignore: avoid_print
      print('izli aday: ${t.izliAday}');
      // ignore: avoid_print
      print('gerçekten çıktı: ${t.cikti}');
      // ignore: avoid_print
      print('izi yazılmış ama karşılığı hiç aday olmayan: '
          '$izliAmaUlasilmayan');

      // Ölçümde izi yazılan her olayın karşılığı en az bir karede aday
      // olmalı: aksi hâlde pencere ya da kapı yanlış demektir.
      expect(izliAmaUlasilmayan, isEmpty,
          reason: 'izi yazıldığı hâlde karşılığı hiç aday olmayan olay '
              'var: pencere dar ya da kapı yanlış');

      // Tarama gerçekten iz görmüş olmalı, yoksa §3 boş geçer.
      expect(t.izliAday.length, greaterThanOrEqualTo(12),
          reason: 'ölçümde 150 hayatta en az 12 izin karşılığı aday '
              'oluyordu; sayı düştüyse iz yazan seçimler ya da '
              'pencereler bozulmuş');
    });

    test(timeout: _sure, '§4 anahtar kapalıyken hiçbiri aday olmuyor', () {
      const EventEngine motor = EventEngine();
      final Set<String> gorulen = <String>{};
      int kare = 0;
      for (int i = 0; i < 25; i++) {
        playBotLife(
          archetype: PlayerArchetype.values[i % PlayerArchetype.values.length],
          seed: 80000 + i,
          features: FeatureSwitches.defaults
              .toggled(FeatureId.izlerinKarsiligi, false),
          onPreAge: (GameState s) {
            kare++;
            gorulen.addAll(motor.debugEligibleIds(s, Random(17)));
          },
        );
      }
      expect(kare, greaterThan(500), reason: 'kare taranamadı');
      final Set<String> sizanlar = gorulen
          .intersection(kTraceEchoEvents.map((GameEvent e) => e.id).toSet());
      expect(sizanlar, isEmpty,
          reason: 'modül kapalıyken aday olan karşılık olayı var');
    });
  });
}

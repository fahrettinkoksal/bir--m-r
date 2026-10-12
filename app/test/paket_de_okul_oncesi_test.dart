// Paket DE — okul öncesi yıllar (3-6 yaş).
//
// **Ölçüm (160 bot hayatı, `BotLifeResult.eventsByAge`).** Paket CX
// 0-2'yi doldurduktan sonra en ince bant 3-6 kaldı:
//
// | bant | yıl başına olay | farklı olay |
// |---|---|---|
// | 0-2 bebeklik | 1,00 | 36 |
// | **3-6 okul öncesi** | **1,04** | **55** |
// | 7-11 ilkokul | 1,47 | 103 |
// | 12-15 ergenlik | 1,57 | 130 |
// | 16-20 eşik | 1,67 | 166 |
// | 30-39 (en zengin) | 1,81 | 259 |
//
// Yani o yaşlarda oyuncu yıl başına bir olay görüyor ve o bir olay hep
// aynı küçük kümeden geliyordu. Yıl başına sayıyı havuz değiştiremez
// (motor ek olay için üç ilerleme adımı istiyor, D-125, ve bu yaşta
// çocuk adım üretmiyor); bu paketin işi **o bir olayın çeşitliliği**.
//
// **CX'in dersleri burada baştan uygulandı:**
// - `livingRelations` **ANY**'dir ("bu bağlardan hayatta en az bir kişi
//   gerekir"). Metin iki kişiyi birlikte varsaymaz; §4 bunu kaynak
//   tarayarak da denetler.
// - Erişilebilirlik "aday **veya** görülmüş" diye sorulur: tek seferlik
//   bir olay ilk uygun yılında çıkarsa `debugEligibleIds` onu bir daha
//   aday göstermez (Paket CR/CZ'nin kör noktası).
// - Yeni iz yazılıyorsa **okuyanı da** yazılır (Paket AR/CZ): altı izin
//   altı karşılık olayı var ve §5 her birini tek tek denetler.
library;

import 'package:bir_omur/data/event_pool_preschool.dart';
import 'package:bir_omur/domain/events/event_engine.dart';
import 'package:bir_omur/domain/features/feature_catalog.dart';
import 'package:bir_omur/domain/models/game_event.dart';
import 'package:bir_omur/domain/models/game_state.dart';
import 'package:bir_omur/domain/models/person.dart';
import 'package:bir_omur/domain/models/relation.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/player_bot.dart';

/// Taranan 3-6 karelerinin özeti.
class _Tarama {
  final Map<int, int> kare = <int, int>{};
  final Map<int, Set<String>> aday = <int, Set<String>>{};
  final Set<String> cikti = <String>{};
  final List<GameState> kareler = <GameState>[];
}

_Tarama? _onbellek;

_Tarama _tara() {
  final _Tarama? hazir = _onbellek;
  if (hazir != null) return hazir;
  final _Tarama t = _Tarama();
  for (final PlayerArchetype a in PlayerArchetype.values) {
    for (int i = 0; i < 24; i++) {
      final BotLifeResult r = playBotLife(
        archetype: a,
        seed: 91000 + a.index * 467 + i * 19,
        onYear: (GameState s) {
          if (s.player.age < 3 || s.player.age > 6) return;
          t.kare[s.player.age] = (t.kare[s.player.age] ?? 0) + 1;
          if (t.kareler.length < 400) t.kareler.add(s);
          (t.aday[s.player.age] ??= <String>{})
              .addAll(const EventEngine().debugEligibleIds(s, null));
        },
      );
      t.cikti.addAll(r.seenEvents);
    }
  }
  _onbellek = t;
  return t;
}

/// Bu havuzun bütün kimlikleri.
Set<String> get _kimlikler =>
    kPreschoolEvents.map((GameEvent e) => e.id).toSet();

/// Yalnızca 3-6 penceresinde yaşayan olaylar (karşılık olayları değil).
List<GameEvent> get _bandOlaylari => kPreschoolEvents
    .where((GameEvent e) => e.requirement.maxAge <= 6)
    .toList();

/// Karşılık olayları (bir iz okuyorlar).
List<GameEvent> get _karsiliklar => kPreschoolEvents
    .where((GameEvent e) => e.requirement.requiredFlags.isNotEmpty)
    .toList();

void main() {
  test('§1 havuz beklenen büyüklükte ve kimlikler tekil', () {
    expect(kPreschoolEvents.length, greaterThanOrEqualTo(20));
    expect(_kimlikler.length, kPreschoolEvents.length,
        reason: 'Aynı olay kimliği iki kez yazılmış.');
    expect(_bandOlaylari.length, greaterThanOrEqualTo(14),
        reason: '3-6 penceresinde yaşayan olay sayısı düştü.');
    expect(_karsiliklar.length, greaterThanOrEqualTo(6),
        reason: 'Her iz okunmalı; karşılık olayı sayısı düştü.');
    // Her olayın en az iki seçeneği var ve seçenek kimlikleri tekil.
    for (final GameEvent e in kPreschoolEvents) {
      expect(e.choices.length, greaterThanOrEqualTo(2),
          reason: '${e.id} tek seçenekli.');
      final Set<String> s =
          e.choices.map((EventChoice c) => c.id).toSet();
      expect(s.length, e.choices.length,
          reason: '${e.id} içinde seçenek kimliği tekrar ediyor.');
    }
  });

  test('§2 bant 3-6 aday sayısı modülle gerçekten artıyor', () {
    final _Tarama t = _tara();
    for (int yas = 3; yas <= 6; yas++) {
      expect(t.kare[yas], isNotNull, reason: '$yas yaşı taranamadı.');
      expect(t.kare[yas]!, greaterThan(20),
          reason: '$yas yaşında yeterli kare yok: ${t.kare[yas]}.');
      final Set<String> havuzdan =
          t.aday[yas]!.where(_kimlikler.contains).toSet();
      expect(havuzdan, isNotEmpty,
          reason: '$yas yaşında bu havuzdan tek aday yok.');
    }
    // Bütün bandın toplamı: ölçümde 14 bant olayının hepsi aday oldu.
    final Set<String> toplam = <String>{};
    for (int yas = 3; yas <= 6; yas++) {
      toplam.addAll(t.aday[yas]!.where(_kimlikler.contains));
    }
    expect(toplam.length, greaterThanOrEqualTo(10),
        reason: 'Bant olaylarının çoğu hiç aday olmuyor: '
            '${toplam.length}/${_bandOlaylari.length}.');
  });

  test('§3 bant olaylarının hepsi erişilebilir (aday veya çıkmış)', () {
    final _Tarama t = _tara();
    final Set<String> adaylar = <String>{};
    for (final Set<String> s in t.aday.values) {
      adaylar.addAll(s);
    }
    final List<String> ulasilamaz = <String>[];
    for (final GameEvent e in _bandOlaylari) {
      if (!adaylar.contains(e.id) && !t.cikti.contains(e.id)) {
        ulasilamaz.add(e.id);
      }
    }
    expect(ulasilamaz, isEmpty,
        reason: 'Bu olaylar ne aday oldu ne çıktı: $ulasilamaz');
  });

  test('§4 kişi kapısı ANY; metin iki kişiyi birlikte varsaymıyor', () {
    final _Tarama t = _tara();
    // (a) Kapısı olan her olay, kapısındaki bağlardan **en az biri**
    //     hayatta olan karede aday olabiliyor; kimsenin olmadığı karede
    //     aday olmuyor.
    for (final GameEvent e in _bandOlaylari) {
      final Set<RelationType> kapi = e.requirement.livingRelations;
      if (kapi.isEmpty) continue;
      for (final GameState s in t.kareler) {
        if (s.player.age < e.requirement.minAge) continue;
        if (s.player.age > e.requirement.maxAge) continue;
        final bool biriVar = s.people
            .any((Person p) => p.isAlive && kapi.contains(p.relation));
        if (biriVar) continue;
        expect(
          const EventEngine().debugMatches(s, e),
          isFalse,
          reason: '${e.id}: kapıdaki bağlardan kimse yok ama aday.',
        );
      }
    }

    // (b) Kaynak taraması: birden fazla bağ isteyen bir olayın metni
    //     "ikisi", "annen", "baban" gibi **tek bir kişiyi** garanti
    //     sayan ifade kullanmaz. CX'te bu gerçek bir hata çıkarmıştı
    //     ("İki büyükanne" diyen olayın kapısı tek büyükanne
    //     garantiliyordu).
    const List<String> yasak = <String>[
      'ikisi',
      'İki büyükanne',
      'annen',
      'baban',
      'anneannen',
      'babaannen',
      'dedesi',
      'dedeniz',
    ];
    for (final GameEvent e in kPreschoolEvents) {
      if (e.requirement.livingRelations.length < 2) continue;
      final List<String> metinler = <String>[
        e.text,
        for (final EventChoice c in e.choices) c.label,
        for (final EventChoice c in e.choices) c.resultText,
      ];
      for (final String m in metinler) {
        for (final String k in yasak) {
          expect(
            m.contains(k),
            isFalse,
            reason: '${e.id}: kapısı birden fazla bağ istiyor ama metin '
                '"$k" diyerek tek kişiyi garanti sayıyor. Yer tutucu '
                '({sahip}/{kisi}) kullan.',
          );
        }
      }
    }
  });

  test('§5 her iz yazılıyor ve her iz okunuyor', () {
    // Yazılan izler
    final Set<String> yazilan = <String>{};
    for (final GameEvent e in kPreschoolEvents) {
      for (final EventChoice c in e.choices) {
        yazilan.addAll(c.addFlags);
      }
    }
    // Okunan izler (bu havuzda)
    final Set<String> okunan = <String>{};
    for (final GameEvent e in kPreschoolEvents) {
      okunan.addAll(e.requirement.requiredFlags);
    }
    expect(yazilan, isNotEmpty);
    expect(
      yazilan.difference(okunan),
      isEmpty,
      reason: 'Bu izleri hiçbir karşılık olayı okumuyor: '
          '${yazilan.difference(okunan)}. Paket AR/CZ kuralı: okunmayan '
          'iz yazılmaz.',
    );
    expect(
      okunan.difference(yazilan),
      isEmpty,
      reason: 'Bu izleri hiçbir olay yazmıyor, yani karşılığı '
          'ulaşılamaz: ${okunan.difference(yazilan)}.',
    );
    // Karşılık olayı izi olmayan karede aday olmamalı.
    final _Tarama t = _tara();
    for (final GameEvent e in _karsiliklar) {
      for (final GameState s in t.kareler) {
        final bool izVar =
            s.storyFlags.containsAll(e.requirement.requiredFlags);
        if (izVar) continue;
        expect(
          const EventEngine().debugMatches(s, e),
          isFalse,
          reason: '${e.id}: iz yok ama aday.',
        );
      }
    }
  });

  test('§6 modül kapalıyken bu havuzdan tek aday çıkmıyor', () {
    int adayKapali = 0;
    int adayAcik = 0;
    for (final PlayerArchetype a in PlayerArchetype.values) {
      for (int i = 0; i < 6; i++) {
        playBotLife(
          archetype: a,
          seed: 93000 + a.index * 331 + i * 17,
          features: FeatureSwitches.defaults
              .toggled(FeatureId.okulOncesiYillar, false),
          onYear: (GameState s) {
            if (s.player.age < 3 || s.player.age > 6) return;
            adayKapali += const EventEngine()
                .debugEligibleIds(s, null)
                .where(_kimlikler.contains)
                .length;
          },
        );
        playBotLife(
          archetype: a,
          seed: 93000 + a.index * 331 + i * 17,
          onYear: (GameState s) {
            if (s.player.age < 3 || s.player.age > 6) return;
            adayAcik += const EventEngine()
                .debugEligibleIds(s, null)
                .where(_kimlikler.contains)
                .length;
          },
        );
      }
    }
    expect(adayKapali, 0,
        reason: 'Anahtar kapalıyken bu havuzdan $adayKapali aday çıktı.');
    expect(adayAcik, greaterThan(0),
        reason: 'Anahtar açıkken de aday çıkmıyor; kapı ters bağlanmış.');
  });
}

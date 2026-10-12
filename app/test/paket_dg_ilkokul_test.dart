// Paket DG — ilkokul yılları (7-11 yaş).
//
// **Neden bu bant.** `docs/EKSIKLER.md` §7'nin 2. maddesi: "Çocukluk ve
// ergenlik olayları — oyunun en fakir ve en duygusal dönemi." Paket CX
// 0-2'yi, Paket DE 3-6'yı doldurdu. Ölçüm (160 bot hayatı) sırayı
// gösteriyor:
//
// | bant | yıl | yıl başına olay | farklı olay | **bant yılı başına farklı** |
// |---|---|---|---|---|
// | **7-11 ilkokul** | 5 | 1,47 | 103 | **20,6** |
// | 21-29 genç yetişkin | 9 | 1,76 | 197 | 21,9 |
// | 30-39 otuzlar | 10 | 1,81 | 259 | 25,9 |
// | 12-15 ergenlik | 4 | 1,57 | 130 | 32,5 |
// | 16-20 eşik | 5 | 1,67 | 166 | 33,2 |
//
// Yani yıl başına olay sayısı ortalamaya yakın ama **çeşitlilik en
// düşük**: oyuncu beş yıl aynı yirmi olayın içinde dönüyor. Hedef yıl
// başına sayıyı değiştirmek değil (motor ek olay için üç ilerleme
// adımı istiyor, D-125), **tekrarı** azaltmak.
//
// **CX ve DE'nin dersleri burada da uygulandı:**
// - `livingRelations` **ANY**'dir; §4 metinleri kaynak tarayarak da
//   denetler.
// - Erişilebilirlik "aday **veya** görülmüş" diye sorulur (Paket CR/CZ).
// - Yazılan her izin okuyanı var (Paket AR/CZ); §5 iki yönlü denetler.
//
// **Bu bandın kendine özgü kapısı:** okul olayları
// `requiresSchoolStudent` ile kapılı. Okula gitmeyen çocuğa okul
// koridoru anlatılmaz; §7 bunu ayrıca denetler.
library;

import 'package:bir_omur/data/event_pool_primary.dart';
import 'package:bir_omur/domain/education/school_performance.dart';
import 'package:bir_omur/domain/events/event_engine.dart';
import 'package:bir_omur/domain/generation/life_progression.dart';
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
        seed: 131000 + a.index * 457 + i * 23,
        onYear: (GameState s) {
          if (s.player.age < 7 || s.player.age > 11) return;
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
    kPrimarySchoolEvents.map((GameEvent e) => e.id).toSet();

/// Yalnızca 3-6 penceresinde yaşayan olaylar (karşılık olayları değil).
List<GameEvent> get _bandOlaylari => kPrimarySchoolEvents
    .where((GameEvent e) => e.requirement.maxAge <= 11)
    .toList();

/// Karşılık olayları (bir iz okuyorlar).
List<GameEvent> get _karsiliklar => kPrimarySchoolEvents
    .where((GameEvent e) => e.requirement.requiredFlags.isNotEmpty)
    .toList();

void main() {
  test('§1 havuz beklenen büyüklükte ve kimlikler tekil', () {
    expect(kPrimarySchoolEvents.length, greaterThanOrEqualTo(20));
    expect(_kimlikler.length, kPrimarySchoolEvents.length,
        reason: 'Aynı olay kimliği iki kez yazılmış.');
    expect(_bandOlaylari.length, greaterThanOrEqualTo(14),
        reason: '3-6 penceresinde yaşayan olay sayısı düştü.');
    expect(_karsiliklar.length, greaterThanOrEqualTo(6),
        reason: 'Her iz okunmalı; karşılık olayı sayısı düştü.');
    // Her olayın en az iki seçeneği var ve seçenek kimlikleri tekil.
    for (final GameEvent e in kPrimarySchoolEvents) {
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
    for (int yas = 7; yas <= 11; yas++) {
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
    for (int yas = 7; yas <= 11; yas++) {
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
    for (final GameEvent e in kPrimarySchoolEvents) {
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
    for (final GameEvent e in kPrimarySchoolEvents) {
      for (final EventChoice c in e.choices) {
        yazilan.addAll(c.addFlags);
      }
    }
    // Okunan izler (bu havuzda)
    final Set<String> okunan = <String>{};
    for (final GameEvent e in kPrimarySchoolEvents) {
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

  test('§7 okul kapısı yazılı ve bandın her zaman okullu olduğu '
      'varsayımı sabit', () {
    // Okul tadındaki olaylar okul kapısını taşıyor mu?
    final List<GameEvent> okulKapili = kPrimarySchoolEvents
        .where((GameEvent e) => e.requirement.requiresSchoolStudent)
        .toList();
    expect(okulKapili.length, greaterThanOrEqualTo(8),
        reason: 'Okul olayları okul kapısı almamış: '
            '${okulKapili.length}.');

    // **Burada bir döngü vardı ve BOŞA ÇALIŞIYORDU.** "Okul öğrencisi
    // olmayan karede aday olmuyor" diye 400 kare taradım; ölçüm
    // **0/400** çıktı, yani gövde hiç yürümedi ve iddia hiçbir şey
    // kanıtlamıyordu. Sebebi tesadüf değil, kuralın kendisi:
    //
    // | kural | değer |
    // |---|---|
    // | `prototypeOnlySchoolStartAge` | 6 |
    // | `prototypeOnlyFailMinGrade` (sınıfta kalma) | 9 |
    // | `prototypeOnlyDropOutMinAge` (okulu bırakma) | 15 |
    //
    // Yani 7-11 bandında oyuncu **kural gereği** her zaman okullu:
    // okul 6'da başlıyor, 9. sınıftan önce kalınmıyor, 15'ten önce
    // bırakılamıyor. Çalışma zamanı dalı bu bantta uyarılamaz.
    //
    // Boş iddianın yerine **varsayımın kendisi** sabitlendi: bu üç
    // sayıdan biri değişirse bu test kırılır ve değiştiren kişi
    // yukarıdaki notu okur — o zaman okul kapısının çalışma zamanı
    // dalı gerçekten denenebilir hâle gelmiş olur.
    expect(LifeProgression.prototypeOnlySchoolStartAge, lessThan(7),
        reason: 'Okula başlama yaşı 7-11 bandının içine girdi; artık '
            'bu bantta okul dışı kare olabilir ve okul kapısının '
            'çalışma zamanı dalı denenmeli.');
    expect(SchoolPerformance.prototypeOnlyFailMinGrade, greaterThan(5),
        reason: 'Sınıfta kalma ilkokul sınıflarına indi; 7-11 bandında '
            'okul dışı kare oluşabilir.');
    expect(SchoolPerformance.prototypeOnlyDropOutMinAge, greaterThan(11),
        reason: 'Okulu bırakma yaşı 7-11 bandına indi; okul kapısının '
            'çalışma zamanı dalı artık denenmeli.');
  });

  test('§6 modül kapalıyken bu havuzdan tek aday çıkmıyor', () {
    int adayKapali = 0;
    int adayAcik = 0;
    for (final PlayerArchetype a in PlayerArchetype.values) {
      for (int i = 0; i < 6; i++) {
        playBotLife(
          archetype: a,
          seed: 133000 + a.index * 311 + i * 19,
          features: FeatureSwitches.defaults
              .toggled(FeatureId.ilkokulYillari, false),
          onYear: (GameState s) {
            if (s.player.age < 7 || s.player.age > 11) return;
            adayKapali += const EventEngine()
                .debugEligibleIds(s, null)
                .where(_kimlikler.contains)
                .length;
          },
        );
        playBotLife(
          archetype: a,
          seed: 133000 + a.index * 311 + i * 19,
          onYear: (GameState s) {
            if (s.player.age < 7 || s.player.age > 11) return;
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

// Paket AN — dövüş dersi form telafisi: anahtar hatası ve korumalar.
//
// Q-184 #1'de doğrulanmış bir production bug vardı: ders sayacı
// `MartialArtsEngine` tarafından 'dovus|<artId>' olarak yazılıyor,
// `CombatCareerEngine.advanceYear` tarafından '<artId>|dovus' olarak
// okunuyordu. İki anahtar farklı olduğu için "çalışan sporcu formunu daha
// iyi korur" kuralı Paket AL'den beri hiç işlemedi.
//
// Bu dosya hatanın düzeldiğini **ürünün kendi yolundan** doğrular ve
// düzeltmenin yanında durması gereken bütün sınırları kilitler (§20):
// telafi sonsuz değil, yaş hâlâ önemli, sakatlık kapısı duruyor, iş yükü
// hâlâ zorlaştırıyor, Paket AM'in 80/70 sağlık kuralları yerinde.
//
// ignore_for_file: avoid_print
library;

import 'dart:math';

import 'package:bir_omur/data/job_catalog.dart';
import 'package:bir_omur/data/martial_arts_catalog.dart';
import 'package:bir_omur/data/save/game_state_codec.dart';
import 'package:bir_omur/domain/activities/martial_arts_engine.dart';
import 'package:bir_omur/domain/combat/combat_career_engine.dart';
import 'package:bir_omur/domain/combat/martial_lesson_counter.dart';
import 'package:bir_omur/domain/combat/sport_workload.dart';
import 'package:bir_omur/domain/generation/life_generator.dart';
import 'package:bir_omur/domain/models/combat_career.dart';
import 'package:bir_omur/domain/models/game_state.dart';
import 'package:bir_omur/domain/models/martial_progress.dart';
import 'package:flutter_test/flutter_test.dart';

const MartialArtsEngine dersMotoru = MartialArtsEngine();

MartialArt sanat(String id) =>
    MartialArt.values.firstWhere((MartialArt a) => a.id == id);

/// Teknik basamağı verilmiş, rekabete başlamış bir sporcu.
///
/// Sağlık varsayılanı 85: Paket AM kariyere başlamak için 80 istiyor.
GameState sporcu({
  String artId = 'karate',
  int level = 3,
  int age = 26,
  int seed = 5150,
  int wallet = 600000,
  int health = 85,
}) {
  final MartialArt a = sanat(artId);
  final GameState s =
      LifeGenerator.seeded(seed).generate(mode: StartMode.tamamenRastgele);
  final GameState hazir = s.copyWith(
    player: s.player.copyWith(
      age: age,
      wallet: wallet,
      stats: s.player.stats.copyWith(health: health),
    ),
    pendingEvent: null,
    martialArts: <MartialProgress>[
      MartialProgress(
        artId: artId,
        lessons: a.ranks[level.clamp(0, a.topLevel)].lessonsNeeded,
        startedAtAge: 8,
      ),
    ],
  );
  final r = CombatCareerEngine.startCompeting(hazir, a);
  expect(r.applied, isTrue, reason: r.text);
  return r.state;
}

CombatCareer kariyer(GameState s) => CombatCareerEngine.activeCareer(s)!;

/// Sayaca elle `n` ders yazar (kanonik anahtar).
GameState ders(GameState s, String artId, int n) => s.copyWith(
      interactionCounts: <String, int>{MartialLessonCounter.key(artId): n},
    );

GameState saglik(GameState s, int v) => s.copyWith(
      player: s.player.copyWith(stats: s.player.stats.copyWith(health: v)),
    );

String isTam() => kJobCatalog.firstWhere((JobType j) => !j.partTime).id;
String isYarim() => kJobCatalog.firstWhere((JobType j) => j.partTime).id;

/// İşe sokar (ürünün kendi `CareerState` alanları).
GameState iste(GameState s, String jobId) => s.copyWith(
      career: s.career.copyWith(
        jobId: jobId,
        startedAtAge: s.player.age,
        salary: 40000,
      ),
    );

/// Bir yılı ilerletip yıl sonu formunu döner.
int formSonra(GameState s, int yeniYas, [int seed = 7]) =>
    kariyer(CombatCareerEngine.advanceYear(s, yeniYas, Random(seed)).state)
        .form;

void main() {
  // =================================================================
  // §1 — tek kanonik anahtar
  // =================================================================
  group('AN kanonik anahtar', () {
    test('anahtar tek yerden kuruluyor ve sırası dovus|artId', () {
      expect(MartialLessonCounter.kind, 'dovus');
      expect(MartialLessonCounter.key('karate'), 'dovus|karate');
      // Hatanın kendisi bu iki string'in karıştırılmasıydı; ikisinin
      // farklı olduğunu test açıkça söylüyor.
      expect(
        MartialLessonCounter.key('karate'),
        isNot(GameState.interactionKey('karate', MartialLessonCounter.kind)),
      );
    });

    test('yazan motor kanonik anahtarı kullanıyor (§1)', () {
      final MartialArt a = sanat('karate');
      GameState s = sporcu(artId: a.id, level: 3, age: 20);
      s = s.copyWith(interactionCounts: const <String, int>{});
      final GameState sonra = dersMotoru.takeLesson(state: s, art: a).state;
      expect(sonra.interactionCounts.containsKey(MartialLessonCounter.key(a.id)),
          isTrue,
          reason: 'Ders alındı ama kanonik anahtar yazılmadı.');
      expect(sonra.interactionCounts[MartialLessonCounter.key(a.id)], 1);
    });

    test('okuyan motor aynı anahtarı görüyor: ders sayısı 0 değil', () {
      final MartialArt a = sanat('karate');
      GameState s = sporcu(artId: a.id, level: 3, age: 20);
      s = s.copyWith(interactionCounts: const <String, int>{});
      s = dersMotoru.takeLesson(state: s, art: a).state;
      // Ürünün okuma yolu — elle anahtar kurmadan.
      expect(MartialLessonCounter.read(s, a.id), 1);
      expect(dersMotoru.lessonsThisAge(s, a), 1);
    });

    test('aynı ders iki kez sayılmıyor (§2)', () {
      final MartialArt a = sanat('karate');
      GameState s = sporcu(artId: a.id, level: 3, age: 20);
      s = s.copyWith(interactionCounts: const <String, int>{});
      for (int i = 0; i < 3; i++) {
        s = dersMotoru.takeLesson(state: s, art: a).state;
      }
      expect(MartialLessonCounter.read(s, a.id), 3,
          reason: 'Üç ders alındı; sayaç üç olmalı.');
      // Sayaçlarda ders için tek anahtar var: ters sıralı ikinci bir
      // kopya yazılmıyor.
      final Iterable<String> dersAnahtarlari = s.interactionCounts.keys.where(
        (String k) => k.contains(a.id) && k.contains(MartialLessonCounter.kind),
      );
      expect(dersAnahtarlari.length, 1,
          reason: 'Ders sayacı için birden çok anahtar yazılıyor: '
              '$dersAnahtarlari');
    });
  });

  // =================================================================
  // §3 — BUG FIX: gerçek production path
  // =================================================================
  group('AN bug fix: production yolu', () {
    test('MartialArtsEngine dersi → advanceYear telafiyi görüyor', () {
      // Debug ile interactionCounts yazılmıyor (§3): ders gerçekten
      // MartialArtsEngine üzerinden alınıyor, parası cüzdandan çıkıyor.
      final MartialArt a = sanat('karate');
      final GameState taban = sporcu(artId: a.id, level: 3, age: 26)
          .copyWith(interactionCounts: const <String, int>{});

      GameState calisan = taban;
      for (int i = 0; i < 4; i++) {
        final r = dersMotoru.takeLesson(state: calisan, art: a);
        expect(r.outcome.applied, isTrue, reason: r.outcome.text);
        calisan = r.state;
      }
      expect(calisan.player.wallet, lessThan(taban.player.wallet),
          reason: 'Ders bedava alınmış; ölçüm gerçek yolu kullanmıyor.');

      final int formCalismayan = formSonra(taban, 27);
      final int formCalisan = formSonra(calisan, 27);
      print('-- §3: yıl sonu form — hiç ders yok $formCalismayan / '
          'motordan 4 ders $formCalisan --');
      expect(formCalisan, greaterThan(formCalismayan),
          reason: 'Q-184 #1 anahtar hatası geri geldi: gerçek ders '
              'telafi üretmiyor.');
    });

    test('takeSeason ile bir sezon çalışmak da telafi üretiyor', () {
      final MartialArt a = sanat('judo');
      final GameState taban = sporcu(artId: a.id, level: 3, age: 26)
          .copyWith(interactionCounts: const <String, int>{});
      final GameState sezon =
          dersMotoru.takeSeason(state: taban, art: a).state;
      expect(MartialLessonCounter.read(sezon, a.id), greaterThan(0));
      expect(formSonra(sezon, 27), greaterThan(formSonra(taban, 27)));
    });
  });

  // =================================================================
  // §2 — eski kayıt uyumu
  // =================================================================
  group('AN eski kayıt uyumu', () {
    test('Paket AN öncesi kayıttaki sayaç okunuyor', () {
      // Paket AN öncesinde de YAZAN taraf 'dovus|<artId>' yazıyordu;
      // hatalı olan okuma tarafıydı. Yani eski kayıtlardaki sayaç
      // biçimi bugünküyle aynı ve migrate gerekmiyor.
      final MartialArt a = sanat('karate');
      final GameState eski = sporcu(artId: a.id, level: 3, age: 26).copyWith(
        interactionCounts: <String, int>{'dovus|${a.id}': 4},
      );
      expect(MartialLessonCounter.read(eski, a.id), 4,
          reason: 'Eski kayıt biçimi okunamıyor.');
      expect(formSonra(eski, 27),
          greaterThan(formSonra(ders(eski, a.id, 0), 27)));
    });

    test('kayıt roundtrip sayacı ve formu bozmuyor (§20)', () {
      final MartialArt a = sanat('karate');
      GameState s = sporcu(artId: a.id, level: 3, age: 26)
          .copyWith(interactionCounts: const <String, int>{});
      s = dersMotoru.takeSeason(state: s, art: a).state;
      final GameState geri = decodeGameState(encodeGameState(s));
      expect(MartialLessonCounter.read(geri, a.id),
          MartialLessonCounter.read(s, a.id));
      expect(formSonra(geri, 27), formSonra(s, 27));
      expect(kariyer(geri).tier, kariyer(s).tier);
      expect(kariyer(geri).form, kariyer(s).form);
    });
  });

  // =================================================================
  // §4, §12 — telafi sınırlı; ders spam formu kilitlemiyor
  // =================================================================
  group('AN telafinin sınırı', () {
    test('4 ders 0 dersten daha iyi koruyor (§20)', () {
      final GameState s = sporcu(age: 26, level: 3);
      final int f0 = formSonra(ders(s, 'karate', 0), 27);
      final int f4 = formSonra(ders(s, 'karate', 4), 27);
      print('-- §4: form — 0 ders $f0 / 4 ders $f4 --');
      expect(f4, greaterThan(f0));
    });

    test('ders sayısı arttıkça getiri azalıyor, form 100\'e kilitlenmiyor', () {
      // §4: yılda birkaç ders alarak form sürekli 100'de kilitlenmesin.
      final GameState s = sporcu(age: 26, level: 3);
      final int f0 = formSonra(ders(s, 'karate', 0), 27);
      final int f8 = formSonra(ders(s, 'karate', 8), 27);
      final int f20 = formSonra(ders(s, 'karate', 20), 27);
      print('-- §12: form — 0 ders $f0 / 8 ders $f8 / 20 ders $f20 --');
      expect(f8, greaterThan(f0));
      expect(f20, greaterThanOrEqualTo(f8));
      expect(f20, lessThan(100),
          reason: '§12: ders spam formu 100\'e kilitliyor.');
      // Azalan getiri: telafinin tavanı var, ders sayısı sonsuz karşılık
      // vermiyor.
      expect(f20 - f8, lessThan(f8 - f0),
          reason: '§4: telafi doğrusal büyüyor; azalan getiri yok.');
    });

    test('yıllık ders tavanı aşılamıyor (§12)', () {
      // Rekabetçi kariyere gerek yok: ölçülen şey ders sayacının tavanı.
      final MartialArt a = sanat('karate');
      final GameState taban = LifeGenerator.seeded(31)
          .generate(mode: StartMode.tamamenRastgele);
      GameState s = taban.copyWith(
        player: taban.player.copyWith(age: 20, wallet: 50000000),
        pendingEvent: null,
        interactionCounts: const <String, int>{},
      );
      // Parası bitmeyen oyuncu doyana kadar ders alıyor.
      for (int i = 0; i < 60; i++) {
        if (!dersMotoru.availability(s, a).isAllowed) break;
        s = dersMotoru.takeLesson(state: s, art: a).state;
      }
      expect(MartialLessonCounter.read(s, a.id),
          lessThanOrEqualTo(kMaxMartialLessonsPerAge),
          reason: '§12: yıllık ders tavanı aşıldı.');
      expect(MartialLessonCounter.read(s, a.id), greaterThan(0),
          reason: 'Hiç ders alınamadı; ölçüm kurulamamış.');
    });

    test('ders spam aynı yıl sınırsız maç üretmiyor (§12)', () {
      // Seed bilerek seçildi: bu kurulumda tavana **gerçekten** dayanıyor,
      // yani test 0 maçla sessizce geçmiyor.
      const int seed = 2;
      final GameState s = ders(sporcu(age: 27, level: 3), 'karate', 20);
      GameState cur = CombatCareerEngine.advanceYear(s, 27, Random(seed)).state;
      int mac = 0;
      // Oyuncu doymadan durmuyor: 20 kez fırsat istiyor.
      for (int i = 0; i < 20; i++) {
        final firsat = CombatCareerEngine.offerBout(cur, Random(seed * 100 + i));
        cur = firsat.state;
        if (firsat.bout == null) break;
        final BoutResult r = CombatCareerEngine.fight(cur, CampChoice.dengeli);
        if (!r.applied) break;
        cur = r.state;
        mac++;
      }
      print('-- §12: 20 ders alan sporcunun aynı yıl maçı: $mac '
          '(tavan ${CombatCareerEngine.prototypeOnlyMaxBoutsPerAge}) --');
      expect(mac, CombatCareerEngine.prototypeOnlyMaxBoutsPerAge,
          reason: '§12: yıllık maç tavanı bu kurulumda tam dolmalıydı. '
              'Daha azsa ölçüm boşa geçiyor, daha fazlaysa tavan aşılmış.');
    });
  });

  // =================================================================
  // §13 — iş + spor
  // =================================================================
  group('AN iş yükü telafiyi azaltıyor', () {
    test('full-time telafiyi azaltıyor ama kariyeri öldürmüyor (§13)', () {
      final GameState calisan = ders(sporcu(age: 26, level: 4), 'karate', 4);
      final GameState tam = iste(calisan, isTam());
      final GameState yarim = iste(calisan, isYarim());
      expect(SportWorkload.of(tam), SportWorkLoad.tamZamanli);
      expect(SportWorkload.of(yarim), SportWorkLoad.yariZamanli);

      final int fIssiz = formSonra(calisan, 27);
      final int fYarim = formSonra(yarim, 27);
      final int fTam = formSonra(tam, 27);
      print('-- §13: form — işsiz $fIssiz / part-time $fYarim / '
          'full-time $fTam --');
      expect(fTam, lessThan(fIssiz));
      expect(fYarim, lessThan(fIssiz));
      expect(fTam, lessThan(fYarim),
          reason: 'part-time ile full-time aynı ceza olmamalı.');
      // Kariyeri öldürmüyor: çalışan sporcu yine müsabakaya çıkabilir.
      expect(fTam, greaterThan(0),
          reason: '§13: full-time iş formu tamamen eritmemeli.');
      expect(kariyer(CombatCareerEngine.advanceYear(tam, 27, Random(7)).state)
          .isRetired, isFalse);
    });
  });

  // =================================================================
  // §14 — yaş
  // =================================================================
  group('AN yaş eğrisi', () {
    test('aynı antrenmanda 55 yaş 27 yaşa eşitlenmiyor (§14)', () {
      // Ölçülen şey kazanma ihtimali: yaş eğrisi orada yaşıyor.
      final Map<int, double> ihtimal = <int, double>{};
      for (final int yas in <int>[27, 35, 45, 55]) {
        GameState s = ders(
          sporcu(age: yas, level: 4, seed: 900 + yas),
          'karate',
          4,
        );
        s = CombatCareerEngine.advanceYear(s, yas, Random(5)).state;
        final firsat = CombatCareerEngine.offerBout(s, Random(5));
        s = firsat.state;
        final CombatCareer k = kariyer(s);
        if (firsat.bout == null) continue;
        ihtimal[yas] = CombatCareerEngine.winChance(
            s, k, k.pendingBout!, CampChoice.dengeli);
      }
      print('-- §14: kazanma ihtimali — $ihtimal --');
      expect(ihtimal.containsKey(27), isTrue);
      expect(ihtimal.containsKey(55), isTrue,
          reason: 'Ölçüm kurulamadı; 55 yaşında fırsat çıkmadı.');
      expect(ihtimal[55]!, lessThan(ihtimal[27]!),
          reason: '§14: antrenman yaş eğrisini siliyor.');
    });
  });

  // =================================================================
  // §15 — sakatlık
  // =================================================================
  group('AN sakatlık kapısı', () {
    test('ciddi sakat sporcu ders yaptı diye maça çıkamıyor (§15)', () {
      GameState s = ders(sporcu(age: 27, level: 4), 'karate', 20);
      final CombatCareer k = kariyer(s);
      s = s.copyWith(
        combatCareers: <CombatCareer>[
          k.copyWith(injury: InjurySeverity.ciddi, injuryYearsLeft: 2),
        ],
      );
      s = CombatCareerEngine.advanceYear(s, 28, Random(4)).state;
      final firsat = CombatCareerEngine.offerBout(s, Random(4));
      s = firsat.state;
      if (firsat.bout != null) {
        final BoutResult r = CombatCareerEngine.fight(s, CampChoice.dengeli);
        expect(r.applied, isFalse,
            reason: '§15: sakat sporcu antrenman yaptı diye maça çıkıyor.');
        expect(r.text, contains(kariyer(s).injury.label));
      } else {
        expect(kariyer(s).isInjured, isTrue);
      }
    });
  });

  // =================================================================
  // §16, §24 — Paket AM'in sağlık kuralları korunuyor
  // =================================================================
  group('AN Paket AM sağlık kuralları korunuyor', () {
    test('80 / 80 / 70 eşikleri yerinde (§16)', () {
      expect(CombatCareerEngine.prototypeOnlyMinHealth, 80);
      expect(CombatCareerEngine.prototypeOnlyMinEliteHealth, 80);
      expect(CombatCareerEngine.prototypeOnlyMinBoutHealth, 70);
    });

    test('sağlık 79 iken antrenman kariyeri açmıyor (§16)', () {
      final GameState s = saglik(
        sporcu(age: 26, level: 3).copyWith(combatCareers: const <CombatCareer>[]),
        79,
      );
      for (final MartialArt a in MartialArt.values) {
        expect(CombatCareerEngine.startAvailability(s, a).isAllowed, isFalse,
            reason: '${a.label}: sağlık 79 ile kariyer açıldı.');
      }
    });

    test('sağlık 69 iken çok ders almak maç kapısını açmıyor (§16)', () {
      final GameState s =
          saglik(ders(sporcu(age: 27, level: 4), 'karate', 20), 69);
      expect(CombatCareerEngine.canFightHealthWise(s), isFalse);
      GameState cur = CombatCareerEngine.advanceYear(s, 28, Random(6)).state;
      final firsat = CombatCareerEngine.offerBout(cur, Random(6));
      cur = firsat.state;
      if (firsat.bout != null) {
        expect(CombatCareerEngine.fight(cur, CampChoice.dengeli).applied,
            isFalse,
            reason: '§16: sağlık 70 altı maç kapısı antrenmanla aşıldı.');
      }
      // Kariyer silinmedi: kademe ve rekor yerinde (Paket AM §5).
      expect(CombatCareerEngine.activeCareer(cur), isNotNull);
    });
  });
}

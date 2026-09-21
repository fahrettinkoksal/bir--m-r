import 'dart:convert';
import 'dart:math';

import 'package:bir_omur/data/health_crisis_catalog.dart';
import 'package:bir_omur/data/save/game_state_codec.dart';
import 'package:bir_omur/data/save/save_service.dart';
import 'package:bir_omur/data/save/save_store.dart';
import 'package:bir_omur/domain/generation/life_generator.dart';
import 'package:bir_omur/domain/generation/life_progression.dart';
import 'package:bir_omur/domain/life/health_crisis_engine.dart';
import 'package:bir_omur/domain/models/game_state.dart';
import 'package:bir_omur/domain/models/pending_crisis.dart';
import 'package:flutter_test/flutter_test.dart';

const HealthCrisisEngine motor = HealthCrisisEngine();

GameState hayat(int seed, {int age = 40, int wallet = 200000, int? health}) {
  final GameState state =
      LifeGenerator.seeded(seed).generate(mode: StartMode.tamamenRastgele);
  return state.copyWith(
    player: state.player.copyWith(
      age: age,
      wallet: wallet,
      stats: health == null
          ? state.player.stats
          : state.player.stats.copyWith(health: health),
    ),
  );
}

/// Belirli bir krizi ekranda bekleyen durum.
GameState krizli(GameState state, String crisisId) =>
    state.copyWith(pendingCrisis: PendingCrisis(
      crisisId: crisisId,
      age: state.player.age,
    ));

void main() {
  // ===================================================================
  // Katalog
  // ===================================================================
  group('Kriz kataloğu (D-044)', () {
    test('her krizin yaş aralığı ve seçenekleri tutarlı', () {
      final Set<String> idler = <String>{};
      for (final HealthCrisis kriz in kHealthCrises) {
        expect(idler.add(kriz.id), isTrue, reason: 'Tekrarlı id: ${kriz.id}');
        expect(kriz.minAge, lessThan(kriz.maxAge));
        expect(kriz.text.trim(), isNotEmpty);
        expect(kriz.baseSurvival, inInclusiveRange(0.5, 0.99));
        expect(kriz.choices.length, greaterThanOrEqualTo(2),
            reason: '${kriz.id}: oyuncunun seçeneği olmalı');
        for (final CrisisChoice secim in kriz.choices) {
          expect(secim.label.trim(), isNotEmpty);
          expect(secim.resultText.trim(), isNotEmpty);
          expect(secim.cost, greaterThanOrEqualTo(0));
          expect(secim.healthChange, lessThanOrEqualTo(0),
              reason: 'Kriz sağlığı iyileştirmez');
        }
        // En az bir seçenek hayatta kalma ihtimalini artırır.
        expect(
          kriz.choices.any((CrisisChoice c) => c.survivalBonus > 0),
          isTrue,
        );
      }
    });

    test('her yaşta uygun kriz bulunur', () {
      for (final int yas in <int>[5, 20, 45, 70, 90]) {
        expect(crisesForAge(yas), isNotEmpty, reason: '$yas yaş');
      }
      // Çocuklukta kaza/hastalık kataloğu yetişkin krizlerini içermez.
      expect(
        crisesForAge(5).every((HealthCrisis c) => c.minAge <= 5),
        isTrue,
      );
    });
  });

  // ===================================================================
  // Sıklık
  // ===================================================================
  group('Kriz sıklığı', () {
    test('krizler seyrektir ve yaşla artar', () {
      double p(int age, int health) =>
          HealthCrisisEngine.prototypeOnlyCrisisChance(age, health);

      expect(p(10, 70), lessThan(0.02));
      expect(p(10, 70), lessThan(p(50, 70)));
      expect(p(50, 70), lessThan(p(80, 70)));
      // Düşük sağlık riski artırır, yüksek sağlık tamamen korumaz.
      expect(p(50, 20), greaterThan(p(50, 90)));
      expect(p(50, 100), greaterThan(0));
    });

    test('art arda kriz çıkmaz', () {
      GameState state = hayat(1, age: 60);
      // Bu yaşta kriz çıktıysa, hemen ertesi yıl yenisi açılmaz.
      state = state.copyWith(lastCrisisAge: 60);
      final HealthCrisis? hemen = motor.rollCrisis(state, 61, Random(1));
      expect(hemen, isNull);

      final HealthCrisis? sonra = motor.rollCrisis(
        state.copyWith(lastCrisisAge: 50),
        61,
        Random(1),
      );
      // Aradan yeterli yaş geçtiyse kriz mümkün (şansa bağlı).
      expect(sonra == null || sonra.minAge <= 61, isTrue);
    });

    test('ekranda kriz varken yenisi açılmaz', () {
      final GameState state = krizli(hayat(2, age: 70), 'zatürre');
      expect(motor.rollCrisis(state, 71, Random(1)), isNull);
    });

    test('bir hayatta kriz sayısı makul kalır', () {
      int toplamKriz = 0;
      int hayatSayisi = 0;
      for (int seed = 0; seed < 40; seed++) {
        GameState state = LifeGenerator.seeded(seed)
            .generate(mode: StartMode.tamamenRastgele);
        hayatSayisi++;
        int kriz = 0;
        for (int i = 0; i < 70 && !state.deceased; i++) {
          state = LifeProgression(Random(seed * 100 + i))
              .advanceOneYear(state.copyWith(pendingEvent: null));
          if (!state.hasPendingCrisis) continue;
          kriz++;
          // Krizi ödenebilir bir seçenekle kapat.
          final HealthCrisis mevcut = state.pendingCrisis!.crisis!;
          final CrisisChoice secim = mevcut.choices.firstWhere(
            (CrisisChoice c) => motor.canChoose(state, c),
            orElse: () => mevcut.choices.last,
          );
          final CrisisResult r = motor.respond(state, secim.id, Random(i));
          // Ödenemeyen seçenekte kriz ekranda kalır; testte temizlenir.
          state = r.outcome.applied
              ? r.state
              : r.state.copyWith(pendingCrisis: null);
        }
        toplamKriz += kriz;
      }
      final double ortalama = toplamKriz / hayatSayisi;
      expect(ortalama, lessThan(5),
          reason: 'Oyuncu sürekli trajediyle cezalandırılmamalı');
    });
  });

  // ===================================================================
  // Yanıt ve sonuç
  // ===================================================================
  group('Krize yanıt', () {
    test('tedavi bedeli bir kez düşer ve kriz kapanır', () {
      final GameState state = krizli(hayat(10, age: 45, wallet: 200000),
          'kalp_uyarisi');
      final CrisisChoice tedavi = state.pendingCrisis!.crisis!.choices.first;

      final CrisisResult r = motor.respond(state, tedavi.id, Random(1));
      expect(r.outcome.applied, isTrue);
      expect(r.state.pendingCrisis, isNull);
      expect(r.state.player.wallet, 200000 - tedavi.cost);

      // İkinci yanıt hiçbir şeyi değiştirmez.
      final CrisisResult ikinci = motor.respond(r.state, tedavi.id, Random(1));
      expect(ikinci.outcome.applied, isFalse);
      expect(ikinci.state.player.wallet, r.state.player.wallet);
    });

    test('parası yetmeyen tedavi seçilemez', () {
      final GameState fakir =
          krizli(hayat(11, age: 45, wallet: 100), 'kalp_uyarisi');
      final CrisisChoice tedavi = fakir.pendingCrisis!.crisis!.choices.first;
      expect(motor.canChoose(fakir, tedavi), isFalse);

      final CrisisResult r = motor.respond(fakir, tedavi.id, Random(1));
      expect(r.outcome.applied, isFalse);
      expect(r.state.player.wallet, 100);
      expect(r.state.pendingCrisis, isNotNull);
    });

    test('atlatılan kriz sağlığı düşürür, günlüğe yazılır', () {
      final GameState state =
          krizli(hayat(12, age: 30, wallet: 200000), 'ates_hastalik');
      final int saglikOnce = state.player.stats.health;

      // Yüksek hayatta kalma ihtimali için tedaviyi seç ve şanslı tohum kullan.
      CrisisResult? atlatan;
      for (int seed = 0; seed < 50 && atlatan == null; seed++) {
        final CrisisResult r = motor.respond(state, 'doktor', Random(seed));
        if (r.outcome.survived) atlatan = r;
      }
      expect(atlatan, isNotNull);
      expect(atlatan!.state.deceased, isFalse);
      expect(atlatan.state.player.stats.health, lessThan(saglikOnce));
      expect(atlatan.state.log.last.text, isNotEmpty);
    });

    test('atlatılamayan kriz hayatı olağan yoldan tamamlar', () {
      final GameState state =
          krizli(hayat(13, age: 80, wallet: 10000), 'zatürre');

      CrisisResult? olum;
      for (int seed = 0; seed < 200 && olum == null; seed++) {
        final CrisisResult r = motor.respond(state, 'evde', Random(seed));
        if (!r.outcome.survived) olum = r;
      }
      expect(olum, isNotNull, reason: 'Kriz ölümle de bitebilmeli');

      expect(olum!.state.deceased, isTrue);
      expect(olum.state.deathAge, 80);
      expect(olum.state.deathCause, isNotNull);
      expect(olum.state.pendingCrisis, isNull);
      // Kayıtlar silinmez: kişiler ve eşyalar durur.
      expect(olum.state.people.length, state.people.length);
      expect(olum.state.log.last.text, contains('hayatını kaybettin'));
    });

    test('tedavi hayatta kalma ihtimalini artırır', () {
      final GameState state =
          krizli(hayat(14, age: 70, wallet: 500000), 'dusme');

      int tedaviliAtlatma = 0;
      int tedavisizAtlatma = 0;
      for (int seed = 0; seed < 300; seed++) {
        if (motor.respond(state, 'ameliyat', Random(seed)).outcome.survived) {
          tedaviliAtlatma++;
        }
        if (motor.respond(state, 'yatak', Random(seed)).outcome.survived) {
          tedavisizAtlatma++;
        }
      }
      expect(tedaviliAtlatma, greaterThan(tedavisizAtlatma));
    });
  });

  // ===================================================================
  // Uyarı ve kayıt
  // ===================================================================
  group('Uyarı ve kayıt', () {
    test('sağlık düşünce bir kez uyarı verilir', () {
      // Düşük sağlıkta ölüm de mümkün; uyarıyı gören bir hayat aranır.
      GameState? uyarilmis;
      for (int seed = 0; seed < 30 && uyarilmis == null; seed++) {
        final GameState temel = hayat(20 + seed, age: 50, health: 15)
            .copyWith(pendingEvent: null);
        final GameState sonra =
            LifeProgression(Random(seed + 1)).advanceOneYear(temel);
        if (!sonra.deceased && sonra.healthWarned) uyarilmis = sonra;
      }
      expect(uyarilmis, isNotNull, reason: 'Uyarı verilebilmeli');
      GameState state = uyarilmis!;

      final int uyari = state.log
          .where((dynamic e) =>
              (e.text as String).contains('Sağlığın belirgin'))
          .length;
      expect(uyari, 1);
      expect(state.healthWarned, isTrue);

      // Ertesi yıl aynı uyarı tekrarlanmaz.
      state = state.copyWith(pendingEvent: null, pendingCrisis: null);
      final GameState seneye =
          LifeProgression(Random(2)).advanceOneYear(state);
      expect(
        seneye.log
            .where((dynamic e) =>
                (e.text as String).contains('Sağlığın belirgin'))
            .length,
        1,
      );
    });

    test('bekleyen kriz kaydedilip aynı şekilde geri gelir', () async {
      final GameState state =
          krizli(hayat(21, age: 55, wallet: 300000), 'kalp_uyarisi');

      final SaveService service = SaveService(MemorySaveStore());
      await service.save(state);
      final SaveLoadResult result = await service.load();
      expect(result.isLoaded, isTrue, reason: result.message);

      final GameState geri = result.state!;
      expect(geri.pendingCrisis, isNotNull);
      expect(geri.pendingCrisis!.crisisId, 'kalp_uyarisi');
      expect(geri.pendingCrisis!.age, state.player.age);
      expect(geri.player.wallet, state.player.wallet,
          reason: 'Yükleme bedeli kesmemeli');

      // Yükleme sonrası verilen yanıt normal işler.
      final CrisisResult r = motor.respond(geri, 'tedavi', Random(1));
      expect(r.outcome.applied, isTrue);
      expect(r.state.pendingCrisis, isNull);
    });

    test('desteklenen en eski sürümün kaydı kriz alanları olmadan açılır', () async {
      final GameState state = hayat(22, age: 40);
      final Map<String, Object?> body = encodeGameState(state);
      body
        ..remove('pendingCrisis')
        ..remove('lastCrisisAge')
        ..remove('healthWarned');

      final SaveLoadResult result = await SaveService(
        MemorySaveStore(
          initial: jsonEncode(
            <String, Object?>{'formatVersion': 21, 'state': body},
          ),
        ),
      ).load();
      expect(result.isLoaded, isTrue, reason: result.message);
      expect(result.state!.pendingCrisis, isNull);
      expect(result.state!.lastCrisisAge, isNull);
      expect(result.state!.healthWarned, isFalse);
      expect(result.state!.player.wallet, state.player.wallet);
    });
  });
}

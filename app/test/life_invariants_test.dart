import 'dart:math';

import 'package:bir_omur/data/health_crisis_catalog.dart';
import 'package:bir_omur/domain/generation/life_generator.dart';
import 'package:bir_omur/domain/life/health_crisis_engine.dart';
import 'package:bir_omur/domain/models/game_event.dart';
import 'package:bir_omur/domain/models/game_state.dart';
import 'package:bir_omur/domain/models/pending_crisis.dart';
import 'package:bir_omur/state/game_controller.dart';
import 'package:flutter_test/flutter_test.dart';

/// Hayat boyu **hiçbir zaman bozulmaması gereken** kurallar (Paket 38).
///
/// Tek tek ekranları sınamak yerine, çok sayıda hayatı doğumdan ölüme
/// oynayıp her adımda aynı değişmezleri kontrol eder. Amaç, en ağır hata
/// türünü — **oyuncunun sıkışıp kaldığı ekran** — tek bir yerde yakalamak.
///
/// Daha önce gerçek bir örneği bulunmuştu: parası olmayan yaşlı bir
/// karakter zatürre krizinde iki seçeneği de karşılayamıyor ve ekranda
/// kilitleniyordu. Bu test o sınıfın tamamını tarar.
void main() {
  // Testin gerçekten ilgili dallara uğradığını doğrulamak için sayaçlar.
  // Hiç krize rastlamayan bir tarama boşuna güven verir.
  int gorulenKriz = 0;
  int gorulenOlay = 0;
  int olenHayat = 0;
  int enBuyukYas = 0;

  setUp(() {
    gorulenKriz = 0;
    gorulenOlay = 0;
    olenHayat = 0;
    enBuyukYas = 0;
  });

  /// Bir durumda kırılan değişmez varsa açıklamasını döner.
  String? ihlal(GameState s) {
    if (s.player.wallet < 0) {
      return 'Cüzdan eksiye indi: ${s.player.wallet}';
    }

    // Bekleyen olayın en az bir seçeneği olmalı; yoksa ekran kapanmaz.
    final ActiveEvent? olay = s.pendingEvent;
    if (olay != null && olay.choices.isEmpty) {
      return 'Bekleyen olayın hiç seçeneği yok: ${olay.eventId}';
    }

    // Bekleyen krizin **karşılanabilir** en az bir seçeneği olmalı.
    final PendingCrisis? kriz = s.pendingCrisis;
    if (kriz != null) {
      const HealthCrisisEngine motor = HealthCrisisEngine();
      final HealthCrisis? katalog = healthCrisisById(kriz.crisisId);
      if (katalog == null) {
        return 'Bilinmeyen kriz: ${kriz.crisisId}';
      }
      if (katalog.choices.isEmpty) {
        return 'Krizin hiç seçeneği yok: ${kriz.crisisId}';
      }
      final bool acikVar = katalog.choices.any(
        (CrisisChoice c) => motor.canChoose(s, c),
      );
      if (!acikVar) {
        return 'Kriz "${kriz.crisisId}" ekranında karşılanabilir seçenek '
            'yok (cüzdan ${s.player.wallet} ₺) — oyuncu kilitlenir';
      }
    }

    final int m = s.player.stats.happiness;
    if (m < 0 || m > 100) return 'Mutluluk aralık dışı: $m';
    final int sg = s.player.stats.health;
    if (sg < 0 || sg > 100) return 'Sağlık aralık dışı: $sg';

    return null;
  }

  /// Bir hayatı ölene kadar oynar; her adımda değişmezleri kontrol eder.
  void hayatOyna(int seed, {int? baslangicCuzdani}) {
    final GameController controller = GameController(random: Random(seed));
    addTearDown(controller.dispose);
    GameState s =
        LifeGenerator.seeded(seed).generate(mode: StartMode.tamamenRastgele);
    if (baslangicCuzdani != null) {
      s = s.copyWith(player: s.player.copyWith(wallet: baslangicCuzdani));
    }
    controller.debugSetState(s);

    final Random secim = Random(seed * 31 + 7);
    int guard = 0;

    while (!controller.state!.deceased) {
      if (guard++ > 400) {
        fail('Hayat ilerlemiyor (tohum $seed, yaş '
            '${controller.state!.player.age})');
      }

      final String? hata = ihlal(controller.state!);
      if (hata != null) {
        fail('Tohum $seed, yaş ${controller.state!.player.age}: $hata');
      }

      if (controller.state!.player.age > enBuyukYas) {
        enBuyukYas = controller.state!.player.age;
      }

      // Bekleyen olay varsa rastgele bir seçenek seçilir.
      final ActiveEvent? olay = controller.state!.pendingEvent;
      if (olay != null) {
        gorulenOlay++;
        final List<EventChoice> secenekler = olay.choices;
        controller.chooseEventOption(
          secenekler[secim.nextInt(secenekler.length)].id,
        );
        continue;
      }

      // Bekleyen kriz varsa karşılanabilir seçeneklerden biri seçilir.
      final PendingCrisis? kriz = controller.state!.pendingCrisis;
      if (kriz != null) {
        gorulenKriz++;
        const HealthCrisisEngine motor = HealthCrisisEngine();
        final HealthCrisis katalog = healthCrisisById(kriz.crisisId)!;
        final List<CrisisChoice> acik = katalog.choices
            .where((CrisisChoice c) => motor.canChoose(controller.state!, c))
            .toList(growable: false);
        controller.respondToCrisis(acik[secim.nextInt(acik.length)].id);
        continue;
      }

      // Bildirimler varsa temizlenir.
      if (controller.state!.notices.isNotEmpty) {
        controller.dismissNotice();
        continue;
      }

      controller.ageUp();
    }

    olenHayat++;
    final String? sonHata = ihlal(controller.state!);
    if (sonHata != null) {
      fail('Tohum $seed, ölümde: $sonHata');
    }
  }

  /// Taramanın boşa dönmediğini doğrular.
  void taramaAnlamliMi(int beklenenHayat) {
    expect(olenHayat, beklenenHayat,
        reason: 'Her hayat ölümle bitmeliydi');
    expect(enBuyukYas, greaterThan(50),
        reason: 'Hayatlar ileri yaşa hiç ulaşmamış; tarama sığ');
    expect(gorulenOlay, greaterThan(100),
        reason: 'Olay ekranına hiç uğranmamış; tarama sığ');
    expect(gorulenKriz, greaterThan(0),
        reason: 'Hiç sağlık krizi çıkmamış; kilitlenme dalı hiç '
            'sınanmamış demektir');
    // ignore: avoid_print
    print('Tarama: $olenHayat hayat, $gorulenOlay olay, $gorulenKriz kriz, '
        'en büyük yaş $enBuyukYas');
  }

  test('40 hayat baştan sona oynanır, değişmezler bozulmaz', () {
    for (int seed = 0; seed < 40; seed++) {
      hayatOyna(seed);
    }
    taramaAnlamliMi(40);
  });

  test('parasız hayatlarda da kimse ekranda sıkışmaz', () {
    // En ağır hata bu koşulda çıkmıştı: cüzdan boş, yaş ilerlemiş,
    // kriz ekranında iki seçenek de karşılanamıyor.
    for (int seed = 0; seed < 25; seed++) {
      hayatOyna(seed, baslangicCuzdani: 0);
    }
    taramaAnlamliMi(25);
  });

  test('her sağlık krizinin boş cüzdanla karşılanabilir seçeneği vardır', () {
    // Katalog düzeyinde doğrudan kontrol: yukarıdaki oynatma bu durumu
    // rastlantıya bırakır, bu test bırakmaz.
    const HealthCrisisEngine motor = HealthCrisisEngine();
    final GameState parasiz =
        LifeGenerator.seeded(1).generate(mode: StartMode.tamamenRastgele);
    final GameState bos =
        parasiz.copyWith(player: parasiz.player.copyWith(wallet: 0));

    for (final HealthCrisis kriz in kHealthCrises) {
      expect(
        kriz.choices.any((CrisisChoice c) => motor.canChoose(bos, c)),
        isTrue,
        reason: '"${kriz.id}" krizinde parasız oyuncuya açık seçenek yok',
      );
    }
  });
}

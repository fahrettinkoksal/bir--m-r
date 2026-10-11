// Toplu ölçüm döngüleri için bir yıllık adım.
library;

import 'dart:math';

import 'package:bir_omur/data/health_crisis_catalog.dart';
import 'package:bir_omur/domain/generation/life_progression.dart';
import 'package:bir_omur/domain/life/critical_health.dart';
import 'package:bir_omur/domain/life/health_crisis_engine.dart';
import 'package:bir_omur/domain/models/game_state.dart';
import 'package:bir_omur/domain/models/pending_crisis.dart';

/// Yüzlerce hayatı baştan sona koşturan ölçüm döngüleri, ölçmedikleri
/// sistemleri bilerek atlar: `pendingEvent` ve sıradan sağlık krizleri
/// silinir, çünkü ölçülen şey başkadır.
///
/// **Kritik sağlık böyle atlanamaz.** Paket AQ'dan sonra sağlık 0 iken
/// krizi silmek, paketin geçersiz saydığı durumu (sağlık 0 + ne ölüm ne
/// bekleyen çözüm) her yıl yeniden kurar. `advanceOneYear` o durumu yıl
/// başında yakalayıp **yaş almadan** döner; krizi tekrar silen bir döngü
/// de sonsuza girer. Bu, CI'ın iki kez süre bütçesinde iptal olmasının
/// kök nedeniydi: `end_to_end_test` ve `event_catalog_test` tam burada
/// takılıyordu.
///
/// Çözüm krizi gizlemek değil, **gerçek motordan cevaplamak**: seçim
/// `HealthCrisisEngine` üzerinden uygulanır, yani ölçüm hayatları da
/// oyuncunun geçtiği yoldan geçer. Test-only kısayol yok.
///
/// **Neden zaman aşımı kurtarmıyor:** `senaryo 8`'in üstünde zaten
/// `Timeout(minutes: 5)` vardı ve hiç tetiklenmedi. Dart'ın test zaman
/// aşımı yalnızca async askı noktalarında işler; senkron bir `while`
/// döngüsü hiç yield etmediği için kesilemez. Yani bu sınıf hatanın tek
/// savunması döngünün kendi ilerleme kontrolüdür — aşağıdaki
/// `StateError` tam bunun için var.
GameState advanceCorpusYear(Random rng, GameState state) {
  GameState s = _settleCrisis(state.copyWith(pendingEvent: null), rng);
  final int yasOnce = s.player.age;
  s = LifeProgression(rng).advanceOneYear(s);

  // Yıl başı kritik sağlık kontrolü yaş almayı durdurduysa (eski kayıt
  // ya da bu döngünün kendi kurduğu durum), çöz ve yılı tamamla.
  if (!s.deceased && s.player.age == yasOnce) {
    s = _settleCrisis(s, rng);
    s = LifeProgression(rng).advanceOneYear(s);
    if (!s.deceased && s.player.age == yasOnce) {
      // Buraya düşmek bir üretim hatasıdır: çözülmüş bir krizden sonra
      // bile yıl ilerlemiyor. Sessizce dönmek yerine yüksek sesle
      // patlasın; sonsuz döngü bir daha CI süresini yemesin.
      throw StateError(
        'advanceOneYear yaş ${s.player.age} içinde ilerlemedi '
        '(sağlık ${s.player.stats.health}, '
        'bekleyen kriz ${s.pendingCrisis?.crisisId ?? "yok"})',
      );
    }
  }
  return s;
}

/// Bekleyen krizi kapatır: sıradan kriz silinir, kritik kriz çözülür.
GameState _settleCrisis(GameState state, Random rng) {
  final PendingCrisis? bekleyen = state.pendingCrisis;
  if (bekleyen == null) return state;
  final HealthCrisis? kriz = bekleyen.crisis;
  if (kriz == null || !kriz.isCritical) {
    return state.copyWith(pendingCrisis: null);
  }
  const HealthCrisisEngine motor = HealthCrisisEngine();
  final CrisisChoice secim = kriz.choices.firstWhere(
    (CrisisChoice c) => motor.canChoose(state, c),
    orElse: () => kriz.choices.last,
  );
  final GameState sonra = motor.respond(state, secim.id, rng).state;
  // Motor seçimi uygulayamadıysa (bedeli karşılanamıyor) kriz hâlâ
  // bekliyor olabilir; o zaman bedelsiz yola düş.
  if (!CriticalHealth.isPending(sonra)) return sonra;
  final CrisisChoice bedelsiz = kriz.choices.firstWhere(
    (CrisisChoice c) => c.cost <= 0 && !c.needsMoney,
    orElse: () => kriz.choices.first,
  );
  return motor.respond(state, bedelsiz.id, rng).state;
}

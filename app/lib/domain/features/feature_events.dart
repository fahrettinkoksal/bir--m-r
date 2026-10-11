/// İçerik modüllerinin olay kapısı (Paket BL + BM).
///
/// Bir modül yeni bir **olay havuzu** getiriyorsa, anahtar kapalıyken o
/// havuzun hiç listelenmemesi gerekir. Havuzlar `const` olduğu için
/// `kEventPool` içinden çıkarılamaz; o yüzden kapı motorun uygunluk
/// kontrolünde, tek bir yerde durur (`EventEngine._matches`).
///
/// Yeni bir içerik modülü eklerken buraya **tek satır** girer. Modülü
/// tamamen silme tarifi: `docs/FEATURE_FLAGS.md`.
library;

import '../../data/event_pool_babyhood.dart';
import '../../data/event_pool_early_years.dart';
import '../../data/event_pool_home.dart';
import '../../data/event_pool_elder_support.dart';
import '../../data/event_pool_friend_circle.dart';
import '../../data/event_pool_late_years.dart';
import '../../data/event_pool_neighbour.dart';
import '../../data/event_pool_preschool.dart';
import '../../data/event_pool_primary.dart';
import '../../data/event_pool_threshold_years.dart';
import '../../data/event_pool_traces.dart';
import '../../data/event_pool_widowhood.dart';
import '../models/game_event.dart';
import '../models/game_state.dart';
import 'feature_catalog.dart';

abstract final class FeatureEvents {
  /// Modül getiren havuzlar. Anahtarı kapalı havuzun olayları hiç
  /// aday olmaz.
  static const Map<FeatureId, List<GameEvent>> pools =
      <FeatureId, List<GameEvent>>{
    // Paket BM'in 31 olayı + Paket CX'in 16 bebeklik olayı: ikisi de
    // ilk yılların içeriği, tek anahtara bağlı.
    FeatureId.ilkYillarOlaylari: <GameEvent>[
      ...kEarlyYearsEvents,
      ...kBabyhoodEvents,
    ],
    FeatureId.esiktekiYillar: kThresholdYearsEvents,
    FeatureId.oturulanEv: kHomeEvents,
    FeatureId.komsular: kNeighbourEvents,
    FeatureId.sonYillar: kLateYearsEvents,
    FeatureId.arkadasGrubu: kFriendCircleEvents,
    FeatureId.yaslilikBakimi: kElderSupportEvents,
    FeatureId.dulluk: kWidowhoodEvents,
    FeatureId.izlerinKarsiligi: kTraceEchoEvents,
    // Paket DE: 3-6 yaşın kendi havuzu. Paket BM/CX'in
    // `ilkYillarOlaylari` anahtarından **ayrı** tutuldu: ikisi aynı
    // pencereyi paylaşıyor ama ayrı paketler ve ayrı ayrı kapatılabilir.
    FeatureId.okulOncesiYillar: kPreschoolEvents,
    // Paket DG: 7-11'in kendi havuzu. Yine ayrı anahtar — ilkokul
    // bandı Paket BM'in 0-7 penceresiyle yalnızca 7'de kesişiyor.
    FeatureId.ilkokulYillari: kPrimarySchoolEvents,
  };

  /// Olay kimliğinden modüle eşleme; bir kez kurulur.
  static final Map<String, FeatureId> _byEventId = <String, FeatureId>{
    for (final MapEntry<FeatureId, List<GameEvent>> girdi in pools.entries)
      for (final GameEvent olay in girdi.value) olay.id: girdi.key,
  };

  /// Bu olay şu an açık bir modüle mi ait? Modülsüz olay her zaman
  /// açıktır.
  static bool allowed(GameState state, String eventId) {
    final FeatureId? modul = _byEventId[eventId];
    return modul == null || state.featureOn(modul);
  }

  /// Bir modülün olay kimlikleri (test ve ölçüm için).
  static Set<String> idsOf(FeatureId id) => <String>{
        for (final GameEvent olay in pools[id] ?? const <GameEvent>[])
          olay.id,
      };
}

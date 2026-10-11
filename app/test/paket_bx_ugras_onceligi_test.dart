/// Paket BX — sürdürülen uğraşa öncelik.
///
/// **Ölçülen sorun.** Okul futbol takımının on iki olayından sekizi
/// 1.000 hayatlık denetimde hiç görülmemişti. Huni (150 spor odaklı
/// hayat) kapının kapalı olmadığını gösterdi: üç olay hayatların
/// 31/150'sinde **uygun hale geliyor** ama 150 hayatta toplam 5 kez
/// çıkıyordu. Yıllık havuzda ortanca 80 aday ve ~268 etkin ağırlık
/// varken ağırlığı 6-7 olan olayın payı %2,5; kulüp üyeliğinin penceresi
/// ise 2-4 yıl.
///
/// **İki düzeltme.** (1) Motor: oyuncunun sürdürdüğü kulüp/hobi olayı
/// çekilişte ×6 alır (`FeatureId.ugrasOnceligi` ile kapatılabilir).
/// (2) Araç: bot okul değişince eski kulübüne yeniden yazılıyor — gerçek
/// oyuncu gibi.
///
/// Bu dosya üçünü korur: katsayının anahtarla kapanması, katsayının
/// gerçekten sürdürülen uğraşa bakması, ve zincirin oynanan hayatlarda
/// görülmesi. Durum kurulmaz; aktif kulüp kaydı **oynanan hayatlardan
/// aranır**.
library;

import 'package:bir_omur/data/event_pool_school_clubs.dart';
import 'package:bir_omur/domain/events/event_engine.dart';
import 'package:bir_omur/domain/features/feature_catalog.dart';
import 'package:bir_omur/domain/models/game_event.dart';
import 'package:bir_omur/domain/models/game_state.dart';
import 'package:bir_omur/domain/models/school_club_progress.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/player_bot.dart';

/// Aktif futbol üyeliği olan **gerçek** bir hayat karesi arar.
GameState _aktifKulupKaresi() {
  for (int i = 0; i < 40; i++) {
    GameState? bulunan;
    playBotLife(
      archetype: PlayerArchetype.sport,
      seed: 3300 + i,
      onYear: (GameState s) {
        if (bulunan != null) return;
        final SchoolClubProgress? uyelik =
            s.schoolClubs.activeFor('futbol_takimi');
        if (uyelik != null) bulunan = s;
      },
    );
    if (bulunan != null) return bulunan!;
  }
  throw StateError('40 hayatta aktif futbol üyeliği bulunamadı');
}

GameEvent _olay(String id) =>
    kSchoolClubEvents.firstWhere((GameEvent e) => e.id == id);

void main() {
  group('Paket BX — sürdürülen uğraşa öncelik', () {
    test('katsayı yalnızca anahtar açıkken uygulanır', () {
      final GameState acik = _aktifKulupKaresi();
      final GameEvent turnuva = _olay('kulup_futbol_turnuva');

      final double acikAgirlik =
          EventEngine.prototypeOnlyEffectiveWeight(acik, turnuva);

      final GameState kapali = acik.copyWith(
        settings: acik.settings.copyWith(
          features: acik.settings.features
              .toggled(FeatureId.ugrasOnceligi, false),
        ),
      );
      final double kapaliAgirlik =
          EventEngine.prototypeOnlyEffectiveWeight(kapali, turnuva);

      expect(kapaliAgirlik, turnuva.weight.toDouble(),
          reason: 'anahtar kapalıyken Paket BX öncesi ağırlık dönmeli');
      expect(acikAgirlik,
          turnuva.weight * EventEngine.prototypeOnlyActivePursuitBoost,
          reason: 'anahtar açıkken sürdürülen kulübün olayı öne geçmeli');
    }, timeout: const Timeout(Duration(minutes: 20)));

    test('katsayı üyelik kapanınca düşer', () {
      final GameState s = _aktifKulupKaresi();
      final GameEvent turnuva = _olay('kulup_futbol_turnuva');
      final SchoolClubProgress uyelik =
          s.schoolClubs.activeFor('futbol_takimi')!;

      // Üyelik kapanmış hâli: aynı kayıt, yalnızca `active` false.
      // Bu bir durum kurgusu değil, oyunun kendi kapanma biçimi
      // (`SchoolClubEngine.leave` birebir bunu yapıyor).
      final GameState ayrilmis = s.copyWith(
        schoolClubs: <SchoolClubProgress>[
          for (final SchoolClubProgress p in s.schoolClubs)
            if (p.clubId == uyelik.clubId &&
                p.schoolId == uyelik.schoolId &&
                p.joinedAtAge == uyelik.joinedAtAge)
              p.copyWith(active: false, leftAtAge: s.player.age)
            else
              p,
        ],
      );

      expect(
        EventEngine.prototypeOnlyEffectiveWeight(ayrilmis, turnuva),
        turnuva.weight.toDouble(),
        reason: 'takımdan ayrılanın olayı öncelik almamalı',
      );
    }, timeout: const Timeout(Duration(minutes: 20)));

    test('kulübe giren oyuncu kulüp olayı görüyor (120 hayat)', () {
      const Set<String> zincir = <String>{
        'kulup_futbol_ilk_antrenman',
        'kulup_futbol_ilk_on_bir',
        'kulup_futbol_kritik_gol',
        'kulup_futbol_penalti',
        'kulup_futbol_penalti_sonrasi',
        'kulup_futbol_antrenor_tartismasi',
        'kulup_futbol_antrenor_barisma',
        'kulup_futbol_takim_arkadasi',
        'kulup_futbol_turnuva',
        'kulup_futbol_sakatlik',
        'kulup_futbol_scout',
        'kulup_futbol_ders_catismasi',
      };

      int futbolaGiren = 0;
      int olayGoren = 0;
      final Set<String> gorulenler = <String>{};

      for (int i = 0; i < 120; i++) {
        bool futbol = false;
        final BotLifeResult r = playBotLife(
          archetype: PlayerArchetype.sport,
          seed: 7700 + i,
          onYear: (GameState s) {
            if (s.schoolClubs.any((SchoolClubProgress p) =>
                p.clubId == 'futbol_takimi')) {
              futbol = true;
            }
          },
        );
        if (!futbol) continue;
        futbolaGiren++;
        final Set<String> kesisim = r.seenEvents.intersection(zincir);
        if (kesisim.isNotEmpty) olayGoren++;
        gorulenler.addAll(kesisim);
      }

      expect(futbolaGiren, greaterThanOrEqualTo(12),
          reason: 'ölçüm kurulumu bozuk: 120 spor hayatında futbol '
              'takımına giren $futbolaGiren hayat');
      // Ölçüm: öncelik öncesi 150 hayatta zincirden toplam 5 görülme
      // vardı ve iki olay hiç çıkmamıştı; öncelikten sonra 21.
      // Taban, futbola giren hayatların **yarısı**: takıma giren oyuncu
      // o takımın hikâyesini görmeli.
      expect(olayGoren * 2, greaterThanOrEqualTo(futbolaGiren),
          reason: 'futbola giren $futbolaGiren hayatın yalnızca '
              '$olayGoren tanesi kulüp olayı gördü; görülenler: '
              '$gorulenler');
      expect(gorulenler.length, greaterThanOrEqualTo(4),
          reason: 'zincirden yalnızca ${gorulenler.length} ayrı olay '
              'görüldü: $gorulenler');
    }, timeout: const Timeout(Duration(minutes: 30)));
  });
}

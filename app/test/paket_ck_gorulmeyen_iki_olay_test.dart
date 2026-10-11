// Paket CK — "hiç görülmeyen" iki olay: kapı mı, seyreklik mi, bot mu?
//
// **Nereden çıktı.** Paket CD'nin ölçümü 150 hayatta iki modda da hiç
// görülmeyen altı olayı "gerçek şüpheli" diye işaretledi. Dördü kulüp/
// futbol zincirinin halkası (Q-224'ün alanı); futbol dışı ikisi
// `ilk_yil_kardes_kiskancligi` ve `suc_ceza_odemesi`. Bu paket o ikisini
// ölçtü ve **"görülmedi" ile "ulaşılamaz" aynı şey değil** sonucuna
// vardı:
//
// | Olay | Aday kare (200 hayat) | Beklenen çıkış | Görülen |
// |---|---|---|---|
// | `ilk_yil_kardes_kiskancligi` (eski kapı) | 54 | 1,47 | 0 |
// | `suc_ceza_odemesi` | 10 | 0,12 | 0 |
//
// Beklenen çıkış 1,47 iken hiç görülmeme olasılığı e^-1,47 ≈ %23;
// 0,12 iken ≈ %89. Yani iki sıfır da **şans dahilinde** — kapının
// kırık olduğunun kanıtı değil. Buna karşılık kardeş olayının kapısı
// ilan ettiği yaş bandını kullanmıyordu ve düzeltildi (aşağıda).
//
// **Ceza ödemesi için sınır botta.** Olay sabıka **ve** dar bütçe
// istiyor; varsayılan botun sabıkalısı 912 sabıkalı yılın 729'unda
// `varlikli`. Yoksullaştırılmış kohortta (yatırım/ev/işletme kapalı)
// olay gerçekten çıkıyor. Oyunun ekonomisine dokunulmadı; bulgu
// Q-229'da.
//
// Durum kurulmuyor: bütün kareler bot hayatlarında bulunuyor.
library;

import 'dart:math';

import 'package:bir_omur/data/event_pool.dart';
import 'package:bir_omur/data/event_pool_early_years.dart';
import 'package:bir_omur/domain/economy/financial_strain.dart';
import 'package:bir_omur/domain/events/event_engine.dart';
import 'package:bir_omur/domain/models/game_event.dart';
import 'package:bir_omur/domain/models/game_state.dart';
import 'package:bir_omur/domain/models/person.dart';
import 'package:bir_omur/domain/models/relation.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/player_bot.dart';

const String kKardesOlay = 'ilk_yil_kardes_kiskancligi';
const String kCezaOlay = 'suc_ceza_odemesi';

/// Olayın havuzdaki ağırlığı.
int _agirlik(String id) =>
    kEventPool.firstWhere((GameEvent e) => e.id == id).weight;

/// Bir olayın bir karede seçilme payı: kendi ağırlığı / aday toplamı.
double _pay(GameState s, String id, Set<String> adaylar) {
  int toplam = 0;
  for (final String aday in adaylar) {
    toplam += _agirlik(aday);
  }
  if (toplam == 0 || !adaylar.contains(id)) return 0;
  return _agirlik(id) / toplam;
}

/// Taramanın topladıkları.
class _Olcum {
  int kardesAdayKare = 0;
  double kardesBeklenen = 0;
  final Set<int> kardesKapiAcilanHayat = <int>{};

  /// Eski kapının (yalnızca `kardes`, yaş ≤ 4) açılacağı kare sayısı.
  int eskiKapiKare = 0;

  int cezaAdayKare = 0;
  double cezaBeklenen = 0;
  int sabikaliYil = 0;
  final Map<String, int> sabikaliRahatlik = <String, int>{};
}

_Olcum _tara() {
  const EventEngine motor = EventEngine();
  final _Olcum o = _Olcum();
  for (final PlayerArchetype a in PlayerArchetype.values) {
    for (int seed = 1; seed <= 20; seed++) {
      final int tohum = seed * 31 + a.index;
      playBotLife(
        archetype: a,
        seed: tohum,
        onPreAge: (GameState s) {
          final int yas = s.player.age;
          final bool kardesBandi = yas >= 3 && yas <= 7;
          final bool sabikali = yas >= 18 && s.legal.hasRecord;
          if (!kardesBandi && !sabikali) return;

          if (kardesBandi) {
            // Eski kapı: yalnızca tam kardeş ve yaş ≤ 4.
            final bool eski = s.people.any((Person p) =>
                p.isAlive &&
                p.inPlayerHousehold &&
                p.relation == RelationType.kardes &&
                p.age <= 4);
            if (eski) o.eskiKapiKare++;
          }
          if (sabikali) {
            o.sabikaliYil++;
            o.sabikaliRahatlik.update(
              FinancialStrain.comfortOf(s).name,
              (int v) => v + 1,
              ifAbsent: () => 1,
            );
          }

          final Set<String> adaylar = motor.debugEligibleIds(s, Random(99));
          if (kardesBandi && adaylar.contains(kKardesOlay)) {
            o.kardesAdayKare++;
            o.kardesBeklenen += _pay(s, kKardesOlay, adaylar);
            o.kardesKapiAcilanHayat.add(tohum);
          }
          if (sabikali && adaylar.contains(kCezaOlay)) {
            o.cezaAdayKare++;
            o.cezaBeklenen += _pay(s, kCezaOlay, adaylar);
          }
        },
      );
    }
  }
  return o;
}

void main() {
  final _Olcum olcum = _tara();

  group('Paket CK §1 — kardeş kıskançlığının kapısı', () {
    test('olay ilan ettiği yaş bandında gerçekten aday oluyor', () {
      // Ölçüm (200 hayat, yeni kapı): 224 aday kare, beklenen 5,84,
      // kapı 89 hayatta açılıyor. Tabanlar bunun belirgin altında.
      expect(olcum.kardesAdayKare, greaterThan(120),
          reason: 'kardeş kıskançlığı aday havuzuna neredeyse hiç '
              'girmiyor; kapı yine daralmış olabilir');
      expect(olcum.kardesBeklenen, greaterThan(3.0),
          reason: 'beklenen çıkış 200 hayatta 3\'ün altına düştü: '
              'olay pratikte görünmez');
      expect(olcum.kardesKapiAcilanHayat.length, greaterThan(50),
          reason: 'kapı çok az hayatta açılıyor');
    });

    test('yeni kapı eski kapıdan belirgin geniş (daralma bekçisi)', () {
      // Eski kapı: yalnızca tam kardeş, yaş ≤ 4 → 81 kare. Yeni kapı
      // 224. Oran 2,7×; taban 1,5× ile korunuyor.
      expect(olcum.eskiKapiKare, greaterThan(20),
          reason: 'eski kapının karesi de kalmamış; ölçüm tabanı yok');
      expect(olcum.kardesAdayKare, greaterThan(olcum.eskiKapiKare * 3 ~/ 2),
          reason: 'yeni kapı eski kapıdan geniş değil; '
              'personMaxAge ya da yariKardes geri alınmış olabilir');
    });

    test('kapı hem tam hem yarım kardeşi kabul ediyor', () {
      final GameEvent olay =
          kEarlyYearsEvents.firstWhere((GameEvent e) => e.id == kKardesOlay);
      expect(olay.requirement.livingRelations,
          containsAll(<RelationType>[
            RelationType.kardes,
            RelationType.yariKardes,
          ]),
          reason: 'oyunda yeni doğan kardeş yalnızca yarım kardeş '
              'olarak geliyor; kapı onu dışarıda bırakmamalı');
      expect(olay.requirement.personMaxAge, greaterThanOrEqualTo(6),
          reason: 'kapı yine tek yıla iner');
      expect(olay.requirement.requireSameHousehold, isTrue,
          reason: 'evin ilgisini anlatan olay aynı haneyi ister');
    });
  });

  group('Paket CK §2 — ceza ödemesi: sınır botta', () {
    test('varsayılan botun sabıkalısı yoksul değil', () {
      // Ölçüm: 912 sabıkalı yılın 729'u `varlikli`. Bu bir oyun hatası
      // değil ama olayın neden görülmediğinin cevabı.
      expect(olcum.sabikaliYil, greaterThan(100),
          reason: 'bot hiç sabıka almıyor; ölçüm tabanı yok');
      final int varlikli = olcum.sabikaliRahatlik['varlikli'] ?? 0;
      expect(varlikli * 2, greaterThan(olcum.sabikaliYil),
          reason: 'sabıkalı yılların yarısından azı varlıklı; bulgu '
              'değişmiş olabilir — Q-229 tazelenmeli');
      expect(olcum.cezaBeklenen, lessThan(1.0),
          reason: 'olay artık seyrek değil; sınıflandırma eskimiş');
    });

    test('yoksullaştırılmış kohortta kapı gerçekten açılıyor', () {
      // Yatırım/ev/işletme kapalı: oyunun sayıları değişmez, yalnızca
      // botun tercihleri kapanır (BotOverrides sözleşmesi).
      const EventEngine motor = EventEngine();
      int adayKare = 0;
      for (final PlayerArchetype a in <PlayerArchetype>[
        PlayerArchetype.risky,
        PlayerArchetype.casual,
      ]) {
        for (int seed = 1; seed <= 25; seed++) {
          playBotLife(
            archetype: a,
            seed: seed * 17 + a.index,
            overrides: const BotOverrides(
              noInvesting: true,
              noProperty: true,
              noBusiness: true,
            ),
            onPreAge: (GameState s) {
              if (s.player.age < 18 || !s.legal.hasRecord) return;
              if (motor.debugEligibleIds(s, Random(7)).contains(kCezaOlay)) {
                adayKare++;
              }
            },
          );
        }
      }
      expect(adayKare, greaterThan(0),
          reason: 'yoksul sabıkalı hiç oluşmuyorsa olay ulaşılamazdır; '
              'o zaman kapı değil ekonominin kendisi konuşulmalı');
    });
  });
}

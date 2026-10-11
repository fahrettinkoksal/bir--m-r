// Paket CU — "kendi başına yaşıyorsun" dediği hayatta evde iki kişi var.
//
// **Nereden çıktı.** Paket CT'nin DUL karesi dökümünde aynı hayatın iki
// ekranı birbirini yalanlıyordu:
//
//     Hayat (künye)  : "Malatya · Kova · Evde seninle 2 kişi yaşıyor"
//     Varlıklar      : "Kirada, kendi başına yaşıyorsun."
//
// **Kök neden.** `LivingSituation.kirada` nerede yaşandığını söyler,
// **kiminle** yaşandığını değil: `Housing.residenceOf` yalnızca ev
// kaydına bakıyor. Metin ise yalnızlığı koşulsuz iddia ediyordu.
// Gider hesabının kendisi haneyi zaten görüyor (bakılan çocuk ve
// evdeki yetişkin çocuk ayrı kalem), yani çelişki yalnızca cümlede.
//
// `docs/WRITING_STYLE_TR.md` §12: metin durumla çelişmez.
//
// **Ölçüm (200 bot hayatı).** Kirada **ve** hanesinde en az bir kişi
// olan kare sayısı aşağıda ölçülüyor; eskiden bu karelerin hepsi
// "kendi başına" yazıyordu.

import 'package:bir_omur/domain/economy/living_costs.dart';
import 'package:bir_omur/domain/models/game_state.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/player_bot.dart';

void main() {
  test('kirada yaşayan oyuncunun hanesi varsa "kendi başına" demez', () {
    const List<PlayerArchetype> ark = <PlayerArchetype>[
      PlayerArchetype.family,
      PlayerArchetype.social,
      PlayerArchetype.career,
      PlayerArchetype.risky,
    ];
    int kiradaKare = 0;
    int kiradaHaneliKare = 0;
    int kiradaYalnizKare = 0;
    int celiski = 0;

    for (int i = 0; i < 200; i++) {
      playBotLife(
        archetype: ark[i % ark.length],
        seed: 70000 + i,
        onPreAge: (GameState s) {
          if (LivingCosts.situationOf(s) != LivingSituation.kirada) return;
          kiradaKare++;
          final String metin = LivingCosts.labelFor(s);
          final int hane = s.household.length;
          if (hane == 0) {
            kiradaYalnizKare++;
            // Gerçekten yalnızsa cümle yalnızlığı söyleyebilir.
            expect(metin, contains('kendi başına'));
            return;
          }
          kiradaHaneliKare++;
          // Hanesi varsa yalnızlık iddiası olmamalı ve sayı yazılmalı.
          if (metin.contains('kendi başına')) celiski++;
          expect(metin, contains('$hane kişi'),
              reason: 'hane $hane iken: $metin');
        },
      );
    }

    // Ölçümün iki tarafı da gerçekten görülmeli; yoksa "sıfır çelişki"
    // boş bir iddia olurdu.
    expect(kiradaKare, greaterThan(500), reason: 'kirada kare: $kiradaKare');
    expect(kiradaHaneliKare, greaterThan(100),
        reason: 'kirada + haneli kare: $kiradaHaneliKare');
    expect(kiradaYalnizKare, greaterThan(100),
        reason: 'kirada + yalnız kare: $kiradaYalnizKare');
    expect(celiski, 0, reason: 'yalnızlık iddiası olan kare: $celiski');
  }, timeout: const Timeout(Duration(minutes: 25)));
}

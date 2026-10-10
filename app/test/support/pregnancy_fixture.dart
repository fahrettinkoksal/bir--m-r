// Gebelik yolunun **açık** olduğu çift: testler için ortak kurulum.
//
// **Neden ayrı dosya.** Gebelik bir ihtimal ve iki yerden sıfırlanır:
// hayatın başında %8 kısırlık (`player.infertile`) ve sevgilinin kendi
// kısırlığı. İlk yazımda "istenen cinsiyette ilk tohumu al" diyen bir
// kurulum yazdım; kadın oyuncu için bulunan ilk tohumun oyuncusu kısır
// çıktı ve gebelik hiç oluşmadı — test oyunu değil kurulumu ölçüyordu.
// Burada kısır olmayan bir çift **aranır**; bulunamazsa test sessizce
// geçmez, kurulum hata verir.
library;

import 'dart:math';

import 'package:bir_omur/domain/generation/life_generator.dart';
import 'package:bir_omur/domain/interaction/intimacy.dart';
import 'package:bir_omur/domain/interaction/romance.dart';
import 'package:bir_omur/domain/models/game_state.dart';
import 'package:bir_omur/domain/models/gender.dart';
import 'package:bir_omur/domain/models/person.dart';

const IntimacyEngine _yakinlasma = IntimacyEngine();

/// İstenen cinsiyette oyuncu + karşı cinsten, kısır olmayan sevgili.
///
/// Yakınlık 85'e çekilir (yakınlaşma kapısı açık olsun) ve bekleyen
/// olay temizlenir; başka hiçbir şey kurulmaz.
({GameState state, Person partner}) gebelikCifti({
  required Gender oyuncuCinsiyeti,
  int age = 28,
}) {
  for (int tohum = 0; tohum < 200; tohum++) {
    final GameState aday =
        LifeGenerator.seeded(tohum).generate(mode: StartMode.tamamenRastgele);
    if (aday.player.gender != oyuncuCinsiyeti) continue;
    if (aday.player.infertile) continue;
    for (final int r in <int>[1, 2, 3, 5, 7, 11, 13, 17]) {
      final ({GameState state, Person partner}) c = const Romance().start(
        aday.copyWith(
          player: aday.player.copyWith(age: age, wallet: 100000),
        ),
        Random(r),
      );
      final Person p = c.state.personById(c.partner.id)!;
      // Aynı cinsiyetteki çiftlerde gebelik yolu zaten kapalı (Q-064).
      if (p.gender == oyuncuCinsiyeti || p.infertile) continue;
      final GameState state = c.state.copyWith(
        pendingEvent: null,
        people: c.state.people
            .map((Person x) =>
                x.id == p.id ? x.copyWith(bond: 85, age: age) : x)
            .toList(growable: false),
      );
      return (state: state, partner: state.personById(p.id)!);
    }
  }
  throw StateError(
    'Gebelik yoluna uygun çift bulunamadı: 200 tohumda '
    '$oyuncuCinsiyeti oyuncu + kısır olmayan sevgili yok. '
    'Kısırlık oranı ya da ilişki kurulumu değişmiş olabilir.',
  );
}

/// Hamile kalana kadar korunmadan dener; her denemesiz yıl bir yaş.
GameState hamileKalinca(GameState state, String partnerId) {
  GameState akan = state;
  for (int i = 0; i < 20 && !akan.isExpecting; i++) {
    akan = _yakinlasma
        .perform(akan, partnerId, Protection.korunmadan, Random(i))
        .state;
    if (akan.isExpecting) break;
    akan = akan.copyWith(
      player: akan.player.copyWith(age: akan.player.age + 1),
    );
  }
  return akan;
}

/// Kişiyi vefat etmiş işaretler (tek müdahale).
GameState vefatEttiIsaretle(GameState state, String personId) =>
    state.copyWith(
      people: state.people
          .map(
              (Person p) => p.id == personId ? p.copyWith(isAlive: false) : p)
          .toList(growable: false),
    );

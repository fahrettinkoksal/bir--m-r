import 'dart:math';

import 'package:bir_omur/data/event_pool.dart';
import 'package:bir_omur/data/event_pool_romance.dart';
import 'package:bir_omur/domain/generation/life_generator.dart';
import 'package:bir_omur/domain/models/game_event.dart';
import 'package:bir_omur/domain/models/person.dart';
import 'package:bir_omur/domain/models/relation.dart';
import 'package:bir_omur/state/game_controller.dart';
import 'package:flutter_test/flutter_test.dart';

/// Romantik ilişki başlatabilen bütün olaylar.
List<GameEvent> get kapilar => kEventPool
    .where((GameEvent e) => e.choices.any((EventChoice c) => c.startsRomance))
    .toList(growable: false);

/// Bir hayatı sonuna kadar oynar; seçimler rastgeledir.
///
/// "Hep evet" diyen oyuncu tavanı ölçer, rastgele seçen oyuncu gerçeğe
/// daha yakındır; bu yüzden ölçüm rastgele seçimle yapılır.
bool sevgiliOldu(int seed) {
  final GameController c = GameController(random: Random(seed));
  final Random secim = Random(seed * 31 + 7);
  c.startNewLife(mode: StartMode.tamamenRastgele, seed: seed);
  bool oldu = false;
  while (!c.state!.deceased && c.state!.player.age < 95) {
    int guard = 0;
    while (c.state!.hasNotice && guard++ < 40) {
      c.dismissNotice();
    }
    while (c.state!.hasPendingEvent && guard++ < 60) {
      final List<EventChoice> secenekler = c.state!.pendingEvent!.choices;
      c.chooseEventOption(secenekler[secim.nextInt(secenekler.length)].id);
      while (c.state!.hasNotice) {
        c.dismissNotice();
      }
    }
    if (c.state!.hasPendingCrisis) {
      c.respondToCrisis(c.state!.pendingCrisis!.crisis!.choices.last.id);
    }
    for (final Person p in c.state!.people) {
      if (p.relation == RelationType.sevgili || p.relation == RelationType.es) {
        oldu = true;
      }
    }
    c.ageUp();
  }
  return oldu;
}

void main() {
  group('Romantik ilişki tek bir kapıya bağlı değildir', () {
    test('birden çok olay ilişki başlatabilir', () {
      // Paket 23 öncesi bu sayı **birdi**: `cikma_teklifi`. O tek kapı
      // 26 yaşında kapanıyordu.
      expect(kapilar.length, greaterThanOrEqualTo(5));
    });

    test('kapılar hayatın farklı dönemlerine yayılır', () {
      final int enGecBaslangic = kapilar
          .map((GameEvent e) => e.requirement.minAge)
          .reduce((int a, int b) => a > b ? a : b);
      final int enGecBitis = kapilar
          .map((GameEvent e) => e.requirement.maxAge)
          .reduce((int a, int b) => a > b ? a : b);
      // Otuzundan sonra da tanışma mümkün olmalı.
      expect(enGecBaslangic, greaterThanOrEqualTo(30));
      // Ve kapı ileri yaşta da açık kalmalı.
      expect(enGecBitis, greaterThanOrEqualTo(70));
    });

    test('yetişkinlik kapıları geçmiş bir ilişkiyi cezalandırmaz', () {
      // Bir kez ayrılmak ya da gençlikte tanışmayı geçmek, ömrün geri
      // kalanını kapatmamalı.
      for (final GameEvent e in kRomanceEvents) {
        if (!e.choices.any((EventChoice c) => c.startsRomance)) continue;
        expect(
          e.requirement.forbiddenFlags,
          isNot(contains(StoryFlags.romantikBitti)),
          reason: '${e.id} eski bir ayrılığı kalıcı engel sayıyor.',
        );
        expect(
          e.requirement.forbiddenFlags,
          isNot(contains(StoryFlags.romantikGecti)),
          reason: '${e.id} gençlikteki bir seçimi kalıcı engel sayıyor.',
        );
      }
    });

    test('kapılar zaten ilişkisi olana veya evliye açılmaz', () {
      // İkinci bir romantik kişi kaydı üretilmemeli.
      for (final GameEvent e in kapilar) {
        expect(
          e.requirement.forbiddenFlags,
          containsAll(<String>[
            StoryFlags.romantikIliskide,
            StoryFlags.evlendi,
          ]),
          reason: '${e.id} ilişkisi olan oyuncuya da çıkabiliyor.',
        );
      }
    });
  });

  group('Bekâr hayat da doludur', () {
    test('evlenmeyen hayata özel olaylar vardır', () {
      final List<GameEvent> bekar = kRomanceEvents
          .where((GameEvent e) =>
              e.id.startsWith('bekar_') &&
              !e.choices.any((EventChoice c) => c.startsRomance))
          .toList(growable: false);
      expect(bekar.length, greaterThanOrEqualTo(4));
      for (final GameEvent e in bekar) {
        expect(
          e.requirement.forbiddenFlags,
          contains(StoryFlags.evlendi),
          reason: '${e.id} evli oyuncuya da çıkıyor.',
        );
      }
    });
  });

  group('Ölçüm: ilişki gerçekten erişilebilir', () {
    test('rastgele seçen oyuncuların çoğunda ilişki kurulabiliyor', () {
      // Paket 23 öncesi aynı ölçüm **60 hayatın 2'sini** veriyordu.
      int oldu = 0;
      const int n = 30;
      for (int seed = 0; seed < n; seed++) {
        if (sevgiliOldu(seed)) oldu++;
      }
      expect(
        oldu,
        greaterThan(n ~/ 3),
        reason: 'İlişki hâlâ erişilmez; $n hayatın yalnızca $oldu\'inde oldu.',
      );
      // Bekâr kalmak da gerçek bir sonuç olarak kalmalı.
      expect(
        oldu,
        lessThan(n),
        reason: 'Her hayatta ilişki kurulması da doğru değil.',
      );
    });
  });
}

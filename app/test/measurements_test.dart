import 'dart:math';

import 'package:bir_omur/domain/generation/life_generator.dart';
import 'package:bir_omur/domain/interaction/bond_decay.dart';
import 'package:bir_omur/domain/models/game_state.dart';
import 'package:bir_omur/domain/models/person.dart';
import 'package:bir_omur/domain/models/relation.dart';
import 'package:bir_omur/domain/models/stats.dart';
import 'package:bir_omur/domain/models/wealth.dart';
import 'package:bir_omur/state/game_controller.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/test_flow.dart';

/// Faho'nun istediği ölçümler (rapor için).
///
/// Bu dosya bir denge testi **değildir**: sayıları ölçer, yazdırır ve
/// yalnızca kabaca makul olduklarını doğrular. Kesin denge değerleri
/// karar kuyruğundadır.
void main() {
  test('100 rastgele hayatta ortalama statlar', () {
    const int hayatSayisi = 100;
    final Map<String, int> toplam = <String, int>{};
    final Map<String, int> enDusuk = <String, int>{};
    final Map<String, int> enYuksek = <String, int>{};
    int olcum = 0;
    int toplamYas = 0;
    int tavanaDeyen = 0;

    for (int seed = 0; seed < hayatSayisi; seed++) {
      final GameController controller = GameController(random: Random(seed));
      controller.startNewLife(mode: StartMode.tamamenRastgele, seed: seed);
      int guard = 0;
      while (!controller.state!.deceased && guard++ < 110) {
        final int onceki = controller.state!.player.age;
        resolveTrackChoice(controller);
        controller.ageUp();
        if (controller.state!.player.age == onceki) break;
        int g = 0;
        while (controller.state!.hasNotice && g++ < 40) {
          controller.dismissNotice();
        }
        resolvePendingEvents(controller);
      }

      final GameState son = controller.state!;
      toplamYas += son.player.age;
      olcum++;
      for (final StatEntry e in son.player.stats.entries) {
        toplam[e.label] = (toplam[e.label] ?? 0) + e.value;
        enDusuk[e.label] = min(enDusuk[e.label] ?? 100, e.value);
        enYuksek[e.label] = max(enYuksek[e.label] ?? 0, e.value);
        if (e.value >= 100) tavanaDeyen++;
      }
    }

    final StringBuffer rapor = StringBuffer(
      'ORTALAMA STATLAR ($olcum hayat, ortalama ömür '
      '${(toplamYas / olcum).toStringAsFixed(1)}):\n',
    );
    for (final MapEntry<String, int> e in toplam.entries) {
      rapor.write('  ${e.key}: ortalama '
          '${(e.value / olcum).toStringAsFixed(1)} '
          '(en düşük ${enDusuk[e.key]}, en yüksek ${enYuksek[e.key]})\n');
    }
    rapor.write('  100e dayanan deger sayisi: $tavanaDeyen');
    // ignore: avoid_print
    print(rapor.toString());

    expect(olcum, hayatSayisi);
    // Azalan getiri ve çaba tavanı (D-099) sonrası hiçbir hayat 100'e
    // yapışmamalı.
    expect(tavanaDeyen, 0);
  });

  test('statlar yaşla gerçekten düşüyor mu (ölçüm)', () {
    const List<int> kilometreTaslari = <int>[20, 40, 60, 80];
    final Map<int, Map<String, int>> toplam = <int, Map<String, int>>{
      for (final int y in kilometreTaslari) y: <String, int>{},
    };
    final Map<int, int> sayac = <int, int>{
      for (final int y in kilometreTaslari) y: 0,
    };

    for (int seed = 0; seed < 60; seed++) {
      final GameController controller = GameController(random: Random(seed));
      controller.startNewLife(mode: StartMode.tamamenRastgele, seed: seed);
      int guard = 0;
      while (!controller.state!.deceased && guard++ < 110) {
        final int onceki = controller.state!.player.age;
        resolveTrackChoice(controller);
        controller.ageUp();
        if (controller.state!.player.age == onceki) break;
        int g = 0;
        while (controller.state!.hasNotice && g++ < 40) {
          controller.dismissNotice();
        }
        resolvePendingEvents(controller);

        final int yas = controller.state!.player.age;
        if (!kilometreTaslari.contains(yas)) continue;
        sayac[yas] = sayac[yas]! + 1;
        for (final StatEntry e in controller.state!.player.stats.entries) {
          toplam[yas]![e.label] = (toplam[yas]![e.label] ?? 0) + e.value;
        }
      }
    }

    final StringBuffer rapor = StringBuffer('STAT YASLANMASI:\n');
    for (final int yas in kilometreTaslari) {
      if (sayac[yas] == 0) continue;
      final List<String> satir = <String>[];
      for (final MapEntry<String, int> e in toplam[yas]!.entries) {
        satir.add('${e.key} ${(e.value / sayac[yas]!).toStringAsFixed(1)}');
      }
      rapor.write('  $yas yaş (${sayac[yas]} hayat): ${satir.join(' · ')}\n');
    }
    // ignore: avoid_print
    print(rapor.toString());

    // 20 ile 80 arasında görünüş gerçekten düşmeli.
    if (sayac[20]! > 0 && sayac[80]! > 0) {
      final double genc = toplam[20]!['Dış görünüş']! / sayac[20]!;
      final double yasli = toplam[80]!['Dış görünüş']! / sayac[80]!;
      expect(yasli, lessThan(genc));
    }
  });

  test('görüşülmeyen çocukla yakınlık: 1, 5, 10, 15 yıl', () {
    // Ölçüm tek bir kişi üzerinde yapılır: 100 yakınlıkla başlayan bir
    // çocukla hiç görüşülmezse yakınlık nasıl gider?
    final List<int> olcumYillari = <int>[1, 5, 10, 15, 20, 30];
    final Map<int, int> sonuc = <int, int>{};

    final GameState taban =
        LifeGenerator.seeded(3).generate(mode: StartMode.tamamenRastgele);
    final Person cocuk = Person(
      id: 'cocuk-olcum',
      firstName: 'Deniz',
      lastName: taban.player.lastName,
      gender: taban.player.gender,
      relation: RelationType.cocuk,
      age: 25,
      isAlive: true,
      inPlayerHousehold: false,
      employment: EmploymentStatus.calisiyor,
      wealth: WealthTier.ortaHalli,
      bond: 100,
    );

    GameState s = taban.copyWith(
      player: taban.player.copyWith(age: 50),
      people: List<Person>.unmodifiable(<Person>[...taban.people, cocuk]),
      lastInteractionAge: <String, int>{cocuk.id: 50},
    );

    for (int yil = 1; yil <= olcumYillari.last; yil++) {
      s = s.copyWith(player: s.player.copyWith(age: 50 + yil));
      final BondDecayResult r = BondDecay.applyYear(s);
      s = s.copyWith(
        people: r.people,
        lastInteractionAge: r.lastInteractionAge,
      );
      if (olcumYillari.contains(yil)) {
        sonuc[yil] = s.personById(cocuk.id)!.bond;
      }
    }

    // ignore: avoid_print
    print('GORUSULMEYEN COCUKLA YAKINLIK: '
        '${sonuc.entries.map((MapEntry<int, int> e) => '${e.key} yıl -> ${e.value}').join(' · ')}');

    expect(sonuc[1]!, greaterThan(sonuc[5]!));
    expect(sonuc[5]!, greaterThan(sonuc[10]!));
    expect(sonuc[10]!, greaterThan(sonuc[15]!));
    // Kan bağı tamamen kopmaz (D-093): bir taban korunur.
    expect(sonuc[30]!, greaterThan(0));
  });
}

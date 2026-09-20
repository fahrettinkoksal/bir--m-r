import 'dart:math';

import 'package:bir_omur/data/event_pool.dart';
import 'package:bir_omur/data/event_pool_extra.dart';
import 'package:bir_omur/data/health_crisis_catalog.dart';
import 'package:bir_omur/domain/events/event_engine.dart';
import 'package:bir_omur/domain/generation/life_generator.dart';
import 'package:bir_omur/domain/generation/life_progression.dart';
import 'package:bir_omur/domain/life/health_crisis_engine.dart';
import 'package:bir_omur/domain/models/game_event.dart';
import 'package:bir_omur/domain/models/game_state.dart';
import 'package:bir_omur/domain/models/owned_item.dart';
import 'package:bir_omur/domain/models/person.dart';
import 'package:flutter_test/flutter_test.dart';

const EventEngine motor = EventEngine();

Set<String> olasiOlaylar(GameState state, {int deneme = 500}) {
  final Set<String> sonuc = <String>{};
  for (int i = 0; i < deneme; i++) {
    final ActiveEvent? olay =
        motor.openingEvent(state.copyWith(pendingEvent: null), Random(i));
    if (olay != null) sonuc.add(olay.eventId);
  }
  return sonuc;
}

GameState hayat(int seed, {int age = 30, int wallet = 500000}) {
  final GameState base =
      LifeGenerator.seeded(seed).generate(mode: StartMode.tamamenRastgele);
  return base.copyWith(
    player: base.player.copyWith(age: age, wallet: wallet),
  );
}

ActiveEvent olayiGetir(GameState state, String id) {
  for (int i = 0; i < 4000; i++) {
    final ActiveEvent? olay =
        motor.openingEvent(state.copyWith(pendingEvent: null), Random(i));
    if (olay != null && olay.eventId == id) return olay;
  }
  fail('$id olayı bu durumda çıkmadı.');
}

void main() {
  // ===================================================================
  // Paket sağlığı
  // ===================================================================
  group('Ek paket sağlığı', () {
    test('bütün olaylar havuza bağlı ve kimlikler benzersiz', () {
      final Set<String> havuz = <String>{
        for (final GameEvent e in kEventPool) e.id,
      };
      expect(havuz.length, kEventPool.length, reason: 'Kimlik çakışması var');
      for (final GameEvent e in kExtraEvents) {
        expect(havuz, contains(e.id));
        expect(e.choices.length, greaterThanOrEqualTo(2));
        expect(e.text.trim(), isNotEmpty);
        for (final EventChoice c in e.choices) {
          expect(c.label.trim(), isNotEmpty);
          expect(c.resultText.trim(), isNotEmpty);
        }
      }
    });

    test('katalog belirgin şekilde büyüdü', () {
      // Paket 4 sonunda 74 olay vardı; ek paket bunu büyüttü.
      expect(kEventPool.length, greaterThanOrEqualTo(105));
      expect(kExtraEvents.length, greaterThanOrEqualTo(30));
    });

    test('kişisiz olaylarda kişi yer tutucusu kullanılmaz', () {
      for (final GameEvent e in kExtraEvents) {
        final bool kisiVar = e.requirement.livingRelations.isNotEmpty ||
            e.requirement.personRole != null ||
            e.requirement.requiresNeglectedRelative;
        if (kisiVar) continue;
        final String hepsi = <String>[
          e.text,
          for (final EventChoice c in e.choices) c.label,
          for (final EventChoice c in e.choices) c.resultText,
        ].join(' ');
        expect(hepsi.contains('{kisi}'), isFalse, reason: e.id);
        expect(hepsi.contains('{sahip'), isFalse, reason: e.id);
      }
    });
  });

  // ===================================================================
  // İleri yaş kapsamı: ölçümdeki asıl boşluk
  // ===================================================================
  group('İleri yaş kapsamı', () {
    test('80 ve 90 yaşlarında çıkabilecek olaylar var', () {
      for (final int yas in <int>[80, 85, 90, 95]) {
        final Set<String> olaylar = olasiOlaylar(hayat(505, age: yas));
        expect(olaylar, isNotEmpty, reason: '$yas yaşında hiç olay yok');
        expect(
          olaylar.length,
          greaterThanOrEqualTo(3),
          reason: '$yas yaşında olay çeşidi çok az: $olaylar',
        );
      }
    });

    test('ileri yaşta olay oranı ölçülebilir düzeyde', () {
      // 40 hayat oynanır; 80 yaş üstü adımların çoğunda olay çıkmalı.
      int adim = 0;
      int olayli = 0;
      for (int seed = 1; seed <= 40; seed++) {
        final Random rng = Random(seed);
        GameState state = LifeGenerator.seeded(seed)
            .generate(mode: StartMode.tamamenRastgele);
        while (!state.deceased && state.player.age < 110) {
          state = LifeProgression(rng)
              .advanceOneYear(state.copyWith(pendingEvent: null));
          if (state.hasPendingCrisis) {
            final HealthCrisis kriz = state.pendingCrisis!.crisis!;
            const HealthCrisisEngine kMotor = HealthCrisisEngine();
            final CrisisChoice secim = kriz.choices.firstWhere(
              (CrisisChoice c) => kMotor.canChoose(state, c),
              orElse: () => kriz.choices.last,
            );
            state = kMotor.respond(state, secim.id, rng).state;
          }
          if (state.deceased) break;
          if (state.player.age >= 80) {
            adim++;
            if (state.hasPendingEvent) olayli++;
          }
          final ActiveEvent? olay = state.pendingEvent;
          if (olay != null) {
            state = motor.resolve(
              state,
              olay.choices[rng.nextInt(olay.choices.length)].id,
              rng: rng,
            );
          }
        }
      }
      expect(adim, greaterThan(0), reason: '80 yaşına ulaşan hayat yok');
      // Paket F1 öncesi bu oran %30-60 arasındaydı.
      expect(olayli / adim, greaterThan(0.7),
          reason: '80+ olay oranı: ${olayli / adim}');
    });
  });

  // ===================================================================
  // Koşullar
  // ===================================================================
  group('Koşullar', () {
    test('arabası olmayan ehliyetliye araba olayı çıkmaz', () {
      final GameState ehliyetli = hayat(512, age: 35).copyWith(
        licenses: <String>{'otomobil_ehliyeti'},
      );
      expect(olasiOlaylar(ehliyetli), isNot(contains('araba_yolda_kaldi')));

      // Farklı model bir araba da olayı açmalı: olay tek ürün kimliğine
      // bağlı değildir.
      final GameState arabali = ehliyetli.grantItems(
        <String>['otomobil_ekonomik'],
        source: ItemSource.satinAlma,
      );
      expect(olasiOlaylar(arabali), contains('araba_yolda_kaldi'));
    });

    test('ehliyeti olmayan araç sahibine o olay çıkmaz', () {
      final GameState arabali = hayat(513, age: 35).grantItems(
        <String>['otomobil_ekonomik'],
        source: ItemSource.miras,
      );
      expect(olasiOlaylar(arabali), isNot(contains('araba_yolda_kaldi')));
    });

    test('radyosu olmayana radyo olayı çıkmaz', () {
      expect(
        olasiOlaylar(hayat(514, age: 80)),
        isNot(contains('radyo_ve_sessizlik')),
      );
      final GameState radyolu = hayat(514, age: 80)
          .grantItems(<String>['radyo'], source: ItemSource.hediye);
      expect(olasiOlaylar(radyolu), contains('radyo_ve_sessizlik'));
    });
  });

  // ===================================================================
  // Sonuç zincirleri: geçmiş karar ileride hatırlanır
  // ===================================================================
  group('Kararların sonucu', () {
    test('dikilen fidan yıllar sonra ağaç olarak karşına çıkar', () {
      final GameState cocuk = hayat(520, age: 10);
      expect(olasiOlaylar(hayat(521, age: 50)),
          isNot(contains('diktigin_agac')));

      final ActiveEvent olay = olayiGetir(cocuk, 'agac_dikimi');
      final GameState sonra =
          motor.resolve(cocuk.copyWith(pendingEvent: olay), 'dik');
      expect(sonra.storyFlags, contains(ExtraFlags.agacDikildi));
      expect(
        olasiOlaylar(sonra.copyWith(
          player: sonra.player.copyWith(age: 50),
        )),
        contains('diktigin_agac'),
      );
    });

    test('emanete dokunmamak ve dokunmak farklı olaylar açar', () {
      final GameState yetiskin = hayat(522, age: 25);
      final ActiveEvent olay = olayiGetir(yetiskin, 'emanet_para');

      final GameState durust =
          motor.resolve(yetiskin.copyWith(pendingEvent: olay), 'dokunma');
      expect(durust.storyFlags, contains(ExtraFlags.emanetTutuldu));
      final Set<String> durustOlaylar = olasiOlaylar(
        durust.copyWith(player: durust.player.copyWith(age: 45)),
      );
      expect(durustOlaylar, contains('emanetin_hatirlatilmasi'));
      expect(durustOlaylar, isNot(contains('emanetin_golgesi')));

      final GameState harcadi =
          motor.resolve(yetiskin.copyWith(pendingEvent: olay), 'kullan');
      expect(harcadi.storyFlags, contains(ExtraFlags.emanetYendi));
      final Set<String> golgeliOlaylar = olasiOlaylar(
        harcadi.copyWith(player: harcadi.player.copyWith(age: 45)),
      );
      expect(golgeliOlaylar, contains('emanetin_golgesi'));
      expect(golgeliOlaylar, isNot(contains('emanetin_hatirlatilmasi')));
    });

    test('komşuyla kurulan ilişki ileride karşılık buluyor', () {
      final GameState yetiskin = hayat(523, age: 30);
      final ActiveEvent olay = olayiGetir(yetiskin, 'komsu_gerginligi');

      final GameState iyi =
          motor.resolve(yetiskin.copyWith(pendingEvent: olay), 'kapi_cal');
      expect(olasiOlaylar(iyi), contains('komsunun_yardimi'));

      final GameState kus =
          motor.resolve(yetiskin.copyWith(pendingEvent: olay), 'sikayet');
      expect(olasiOlaylar(kus), contains('komsunun_soguklugu'));
      expect(olasiOlaylar(kus), isNot(contains('komsunun_yardimi')));
    });

    test('beslenen sokak hayvanı yıllar sonra geri döner', () {
      final GameState cocuk = hayat(524, age: 12);
      final ActiveEvent olay = olayiGetir(cocuk, 'sokak_hayvani');
      final GameState besledi =
          motor.resolve(cocuk.copyWith(pendingEvent: olay), 'besle');
      expect(
        olasiOlaylar(besledi.copyWith(
          player: besledi.player.copyWith(age: 20),
        )),
        contains('hayvanin_donusu'),
      );

      final GameState gecti =
          motor.resolve(cocuk.copyWith(pendingEvent: olay), 'gec');
      expect(
        olasiOlaylar(gecti.copyWith(
          player: gecti.player.copyWith(age: 20),
        )),
        isNot(contains('hayvanin_donusu')),
      );
    });

    test('ergenlikte tutulan defter ileri yaşta bulunur', () {
      final GameState genc = hayat(525, age: 16);
      final ActiveEvent olay = olayiGetir(genc, 'defter_siiri');
      final GameState sakladi =
          motor.resolve(genc.copyWith(pendingEvent: olay), 'sakla');
      expect(
        olasiOlaylar(sakladi.copyWith(
          player: sakladi.player.copyWith(age: 60),
        )),
        contains('eski_defter'),
      );

      final GameState yirtti =
          motor.resolve(genc.copyWith(pendingEvent: olay), 'yirt');
      expect(
        olasiOlaylar(yirtti.copyWith(
          player: yirtti.player.copyWith(age: 60),
        )),
        isNot(contains('eski_defter')),
      );
    });
  });

  // ===================================================================
  // Ekrana giden metin
  // ===================================================================
  test('seçenek etiketlerindeki yer tutucular doldurulur', () {
    // Oyuncu yaşlanınca çevresi de yaşlanır; kardeş artık yetişkin.
    final GameState temel = hayat(530, age: 78);
    final GameState yasli = temel.copyWith(
      people: temel.people
          .map((Person p) => p.copyWith(age: p.age + 70))
          .toList(growable: false),
    );
    // Hanede yetişkin bir çocuk ya da kardeş varsa anahtar olayı çıkar.
    final ActiveEvent olay = olayiGetir(yasli, 'evin_anahtari');
    for (final EventChoice c in olay.choices) {
      expect(c.label.contains('{'), isFalse,
          reason: 'Ekranda yer tutucu kalmamalı: ${c.label}');
    }
    expect(olay.text.contains('{'), isFalse);
  });

  test('vefat eden oyuncuya yanıtlanmamış olay kalmaz', () {
    // Kriz yolundan gelen ölümde de ekrandaki olay temizlenir: hayat
    // tamamlandıktan sonra oyuncuya soru sorulmaz.
    const HealthCrisisEngine kriz = HealthCrisisEngine();
    final GameState temel = hayat(531, age: 75, wallet: 0).copyWith(
      player: hayat(531, age: 75).player.copyWith(
            wallet: 0,
            stats: hayat(531, age: 75).player.stats.copyWith(health: 5),
          ),
    );
    final ActiveEvent olay = olayiGetir(temel, 'sabah_yuruyusu');

    bool oldu = false;
    for (final HealthCrisis secilen in crisesForAge(75)) {
      for (final CrisisChoice secenek in secilen.choices) {
        for (int i = 0; i < 40 && !oldu; i++) {
          final GameState acik = kriz
              .open(temel, secilen, 75)
              .copyWith(pendingEvent: olay);
          if (!kriz.canChoose(acik, secenek)) continue;
          final GameState sonra =
              kriz.respond(acik, secenek.id, Random(i)).state;
          if (!sonra.deceased) continue;
          oldu = true;
          expect(sonra.hasPendingEvent, isFalse,
              reason: 'Vefat eden oyuncuda bekleyen olay kaldı');
        }
      }
    }
    expect(oldu, isTrue, reason: 'Ölümle biten kriz üretilemedi');
  });
}

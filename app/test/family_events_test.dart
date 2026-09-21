import 'dart:math';

import 'package:bir_omur/data/event_pool.dart';
import 'package:bir_omur/data/interaction_texts.dart';
import 'package:bir_omur/domain/events/event_engine.dart';
import 'package:bir_omur/domain/generation/life_generator.dart';
import 'package:bir_omur/domain/generation/life_progression.dart';
import 'package:bir_omur/domain/interaction/family_interactions.dart';
import 'package:bir_omur/domain/interaction/marriage_engine.dart';
import 'package:bir_omur/domain/interaction/parenthood.dart';
import 'package:bir_omur/domain/interaction/romance.dart';
import 'package:bir_omur/domain/models/education.dart';
import 'package:bir_omur/domain/models/game_event.dart';
import 'package:bir_omur/domain/models/game_state.dart';
import 'package:bir_omur/domain/models/applied_effect.dart';
import 'package:bir_omur/domain/models/interaction.dart';
import 'package:bir_omur/domain/models/person.dart';
import 'package:bir_omur/domain/models/relation.dart';
import 'package:flutter_test/flutter_test.dart';

const EventEngine motor = EventEngine();
const MarriageEngine evlilik = MarriageEngine();
const Parenthood ebeveynlik = Parenthood();
const FamilyInteractions etkilesim = FamilyInteractions();

/// Bu durumda **çıkabilecek** olayların kimlikleri.
/// Şu an **çıkabilecek** olayların kimlikleri.
///
/// Eskiden bu yüzlerce tohumla çekiliş yapılarak bulunuyordu; dönüm
/// noktası ağırlıkları devreye girince (Paket 21) çekilişi hep aynı olay
/// kazanıyor ve diğerleri "imkânsız" gibi görünüyordu. Artık koşullar
/// doğrudan denetleniyor: hem doğru hem hızlı.
Set<String> olasiOlaylar(GameState state, {int deneme = 40}) {
  final Set<String> sonuc = <String>{};
  for (int i = 0; i < deneme; i++) {
    sonuc.addAll(
      motor.debugEligibleIds(state.copyWith(pendingEvent: null), Random(i)),
    );
  }
  return sonuc;
}

/// Belirli bir olayı ekrana getirir; çıkmıyorsa testi düşürür.
ActiveEvent olayiGetir(GameState state, String id) {
  for (int i = 0; i < 2000; i++) {
    final ActiveEvent? olay =
        motor.openingEvent(state.copyWith(pendingEvent: null), Random(i));
    if (olay != null && olay.eventId == id) return olay;
  }
  fail('$id olayı bu durumda hiç çıkmadı.');
}

GameState evliOyuncu(int seed, {int age = 30, int wallet = 800000}) {
  final GameState base =
      LifeGenerator.seeded(seed).generate(mode: StartMode.tamamenRastgele);
  final ({GameState state, Person partner}) r = const Romance().start(
    base.copyWith(player: base.player.copyWith(age: age, wallet: wallet)),
    Random(seed + 7),
  );
  final GameState hazir = r.state.copyWith(
    people: r.state.people
        .map((Person p) => p.id == r.partner.id ? p.copyWith(bond: 85) : p)
        .toList(growable: false),
  );
  return evlilik.marry(hazir, r.partner.id).state;
}

/// Çocuk ekler; eklenemezse testi düşürür (sessizce çocuksuz kalmasın).
GameState cocukEkle(GameState state, {int seed = 1}) {
  final FamilyResult r = ebeveynlik.haveChild(state, Random(seed));
  expect(r.outcome.applied, isTrue, reason: r.outcome.text);
  return r.state;
}

/// Çocuğu istenen yaşa getirir (kademe bilgisi de güncellenir).
GameState cocukYasi(GameState state, int yas) => state.copyWith(
      people: state.people
          .map((Person p) => p.relation == RelationType.cocuk
              ? p.copyWith(
                  age: yas,
                  schoolLevel: Parenthood.schoolLevelForAge(yas),
                )
              : p)
          .toList(growable: false),
    );

void main() {
  // ===================================================================
  // Olayların gerçek duruma bağlı olması
  // ===================================================================
  group('Aile olayları gerçek kayda bağlı', () {
    test('çocuğu olmayan oyuncuya çocuk olayı çıkmaz', () {
      final GameState state = evliOyuncu(201);
      final Set<String> olaylar = olasiOlaylar(state);
      expect(olaylar, isNot(contains('bebek_gece_aglamasi')));
      expect(olaylar, isNot(contains('cocuk_ilk_okul_gunu')));
      expect(olaylar, isNot(contains('cocuk_karne_gunu')));
    });

    test('evli olmayan oyuncuya eş olayı çıkmaz', () {
      final GameState base = LifeGenerator.seeded(202)
          .generate(mode: StartMode.tamamenRastgele)
          .copyWith(
            player: LifeGenerator.seeded(202)
                .generate(mode: StartMode.tamamenRastgele)
                .player
                .copyWith(age: 30),
          );
      final Set<String> olaylar = olasiOlaylar(base);
      expect(olaylar, isNot(contains('es_ile_tartisma')));
      expect(olaylar, isNot(contains('es_is_karari')));
    });

    test('boşandıktan sonra eş olayı çıkmaz', () {
      final GameState evli = evliOyuncu(203);
      expect(olasiOlaylar(evli), contains('es_ile_tartisma'));

      final GameState bosandi = evlilik.divorce(evli).state;
      expect(olasiOlaylar(bosandi), isNot(contains('es_ile_tartisma')));
    });

    test('bebeklik olayı yalnızca bebek yaşındaki çocukta çıkar', () {
      GameState state = cocukEkle(evliOyuncu(204));

      expect(olasiOlaylar(cocukYasi(state, 1)),
          contains('bebek_gece_aglamasi'));
      expect(olasiOlaylar(cocukYasi(state, 15)),
          isNot(contains('bebek_gece_aglamasi')));
      // Okul olayı da bebekte çıkmaz.
      expect(olasiOlaylar(cocukYasi(state, 1)),
          isNot(contains('cocuk_karne_gunu')));
    });

    test('evden ayrılma olayı yalnızca hanedeki yetişkin çocukta çıkar', () {
      final GameState state = cocukEkle(evliOyuncu(205, age: 40));
      final GameState hanede = cocukYasi(state, 23);
      expect(olasiOlaylar(hanede), contains('cocuk_evden_ayrilma'));

      final GameState ayri = hanede.copyWith(
        people: hanede.people
            .map((Person p) => p.relation == RelationType.cocuk
                ? p.copyWith(inPlayerHousehold: false)
                : p)
            .toList(growable: false),
      );
      expect(olasiOlaylar(ayri), isNot(contains('cocuk_evden_ayrilma')));
    });

    test('ziyaret olayı yalnızca ayrı evde yaşayan yakınla çıkar', () {
      final GameState base = LifeGenerator.seeded(206)
          .generate(mode: StartMode.tamamenRastgele);
      final GameState hanede = base.copyWith(
        player: base.player.copyWith(age: 30),
        people: base.people
            .map((Person p) => p.relation.kanBagi
                ? p.copyWith(inPlayerHousehold: true)
                : p)
            .toList(growable: false),
      );
      expect(olasiOlaylar(hanede), isNot(contains('aile_ziyareti')));

      final GameState ayri = hanede.copyWith(
        people: hanede.people
            .map((Person p) => p.copyWith(inPlayerHousehold: false))
            .toList(growable: false),
      );
      expect(olasiOlaylar(ayri), contains('aile_ziyareti'));
    });
  });

  // ===================================================================
  // Hafıza: geçmiş karar ileride hatırlanır
  // ===================================================================
  group('Geçmiş kararlar hatırlanır', () {
    test('okulun ilk gününde destek veren ebeveyn ergenlikte hatırlanır', () {
      GameState state =
          cocukEkle(evliOyuncu(210, age: 28));
      state = cocukYasi(state, 6);

      final ActiveEvent olay = olayiGetir(state, 'cocuk_ilk_okul_gunu');
      final String cocukId = olay.personId!;
      state = motor.resolve(
        state.copyWith(pendingEvent: olay),
        'kal',
        rng: Random(1),
      );

      expect(state.storyFlags, contains(StoryFlags.cocukIlkGunDestek));
      expect(state.storyPeople[StoryRoles.ilkOkulCocugu], cocukId);

      // Ergenlikte güven olayı çıkar, sessizlik olayı çıkmaz.
      final GameState ergen = cocukYasi(state, 15);
      final Set<String> olaylar = olasiOlaylar(ergen);
      expect(olaylar, contains('cocuk_ergen_guven'));
      expect(olaylar, isNot(contains('cocuk_ergen_sessizlik')));

      // Devam olayı **aynı çocukla** kurulur.
      final ActiveEvent devam = olayiGetir(ergen, 'cocuk_ergen_guven');
      expect(devam.personId, cocukId);
    });

    test('ilk gün yalnız bırakılan çocukta sessizlik olayı çıkar', () {
      GameState state =
          cocukEkle(evliOyuncu(211, age: 28));
      state = cocukYasi(state, 6);
      final ActiveEvent olay = olayiGetir(state, 'cocuk_ilk_okul_gunu');
      state = motor.resolve(
        state.copyWith(pendingEvent: olay),
        'birak',
        rng: Random(1),
      );

      final Set<String> olaylar = olasiOlaylar(cocukYasi(state, 15));
      expect(olaylar, contains('cocuk_ergen_sessizlik'));
      expect(olaylar, isNot(contains('cocuk_ergen_guven')));
    });

    test('verilen söz yıllar sonra hatırlatılır ve bir kez kapanır', () {
      GameState state =
          cocukEkle(evliOyuncu(212, age: 30));
      state = cocukYasi(state, 8);

      // Söz verilmeden hatırlatma olayı çıkmaz.
      expect(olasiOlaylar(state),
          isNot(contains('cocuk_sozun_hatirlatilmasi')));

      final ActiveEvent olay = olayiGetir(state, 'cocuk_bisiklet_istegi');
      state = motor.resolve(
        state.copyWith(pendingEvent: olay),
        'soz_ver',
        rng: Random(1),
      );
      expect(state.storyFlags, contains(StoryFlags.cocugaSozVerildi));

      final GameState sonraki = cocukYasi(state, 10);
      expect(olasiOlaylar(sonraki), contains('cocuk_sozun_hatirlatilmasi'));

      // Söz tutulunca hatırlatma bir daha çıkmaz.
      final ActiveEvent hatirlatma =
          olayiGetir(sonraki, 'cocuk_sozun_hatirlatilmasi');
      final GameState tutuldu = motor.resolve(
        sonraki.copyWith(pendingEvent: hatirlatma),
        'sozu_tut',
        rng: Random(1),
      );
      expect(tutuldu.storyFlags, contains(StoryFlags.cocugaSozTutuldu));
      expect(olasiOlaylar(cocukYasi(tutuldu, 12)),
          isNot(contains('cocuk_sozun_hatirlatilmasi')));
    });

    test('eşle konuşulan gece yıllar sonra hatırlanır', () {
      final GameState evli = evliOyuncu(213, age: 30);
      expect(olasiOlaylar(evli), isNot(contains('es_ile_eski_konusma')));

      final ActiveEvent olay = olayiGetir(evli, 'es_ile_tartisma');
      final GameState sonra = motor.resolve(
        evli.copyWith(pendingEvent: olay),
        'konus',
        rng: Random(1),
      );
      expect(sonra.storyFlags, contains(StoryFlags.esleKonusuldu));

      final Set<String> olaylar = olasiOlaylar(sonra);
      expect(olaylar, contains('es_ile_eski_konusma'));
      // Aynı tartışma olayı yeniden açılmaz.
      expect(olaylar, isNot(contains('es_ile_tartisma')));
    });

    test('gerçekleşmeyen olayın devamı çıkmaz', () {
      final GameState state =
          cocukEkle(evliOyuncu(214, age: 30));
      // Hiçbir karar verilmeden ergenliğe gelinirse devam olayları yok.
      final Set<String> olaylar = olasiOlaylar(cocukYasi(state, 15));
      expect(olaylar, isNot(contains('cocuk_ergen_guven')));
      expect(olaylar, isNot(contains('cocuk_ergen_sessizlik')));
      expect(olaylar, isNot(contains('cocuk_sozun_hatirlatilmasi')));
    });
  });

  // ===================================================================
  // Çocuğun eğitim evresi
  // ===================================================================
  group('Çocuğun okul evresi', () {
    test('yaşla birlikte kademe ilerler, yetişkinde ilkokul yazmaz', () {
      GameState state =
          cocukEkle(evliOyuncu(220, age: 25));
      final String id = state.children.single.id;
      final Random rng = Random(3);

      final Map<int, SchoolLevel?> beklenen = <int, SchoolLevel?>{
        3: null,
        7: SchoolLevel.ilkokul,
        11: SchoolLevel.ortaokul,
        15: SchoolLevel.lise,
        22: null,
      };

      for (int i = 1; i <= 22 && !state.deceased; i++) {
        state = LifeProgression(rng).advanceOneYear(
          state.copyWith(pendingEvent: null, pendingCrisis: null),
        );
        final Person cocuk = state.personById(id)!;
        if (!cocuk.isAlive) return;
        if (beklenen.containsKey(cocuk.age)) {
          expect(cocuk.schoolLevel, beklenen[cocuk.age],
              reason: '${cocuk.age} yaşındaki çocuğun kademesi');
        }
        if (cocuk.age >= 18) {
          expect(cocuk.occupationLabel, isNot(contains('İlkokul')));
        }
      }
    });

    test('okul arkadaşının kademesi çocuk büyüdü diye değişmez', () {
      final GameState state = LifeGenerator.seeded(221)
          .generate(mode: StartMode.tamamenRastgele);
      final GameState sonra = LifeProgression(Random(1)).advanceOneYear(
        state.copyWith(pendingEvent: null),
      );
      for (final Person p in sonra.people) {
        if (p.schoolTie == null) continue;
        final Person once = state.personById(p.id)!;
        expect(p.schoolLevel, once.schoolLevel,
            reason: 'Okul kişisinin kademesi sabit kalmalı');
      }
    });
  });

  // ===================================================================
  // Etkileşimler
  // ===================================================================
  group('Aile etkileşimleri', () {
    test('eşle ve çocukla anlamlı etkileşimler açılır, olmayanlar açılmaz',
        () {
      final GameState state =
          cocukEkle(evliOyuncu(230, age: 30));
      final Person es = state.spouse!;
      final Person cocuk = state.children.single;

      final List<InteractionKind> esIle =
          etkilesim.availableKinds(state, es);
      expect(esIle, contains(InteractionKind.vakitGecir));
      expect(esIle, contains(InteractionKind.sohbet));
      expect(esIle, isNot(contains(InteractionKind.paraIste)));

      final List<InteractionKind> cocukIle =
          etkilesim.availableKinds(state, cocuk);
      expect(cocukIle, contains(InteractionKind.vakitGecir));
      expect(cocukIle, isNot(contains(InteractionKind.paraIste)),
          reason: 'Çocuktan para istenmez');
      expect(cocukIle, isNot(contains(InteractionKind.hediyeIste)));
    });

    test('çocukla etkinlik metni yaşına göre değişir', () {
      final GameState state =
          cocukEkle(evliOyuncu(231, age: 30));
      final Person cocuk = state.children.single;

      Set<String> metinler(int yas) => <String>{
            for (int i = 0; i < 60; i++)
              interactionText(
                rng: Random(i),
                person: cocuk.copyWith(age: yas),
                kind: InteractionKind.vakitGecir,
                accepted: true,
                noNewBenefit: false,
                playerAge: 30 + yas,
              ),
          };

      final Set<String> bebek = metinler(1);
      final Set<String> okul = metinler(8);
      final Set<String> ergen = metinler(15);

      expect(bebek.intersection(okul), isEmpty,
          reason: 'Bebekle ve okul çağındaki çocukla aynı metin çıkmamalı');
      expect(okul.intersection(ergen), isEmpty);
      expect(bebek.intersection(ergen), isEmpty);
    });

    test('ayrı evde yaşayan yakınla temas ziyaret olarak anlatılır', () {
      final GameState state = LifeGenerator.seeded(232)
          .generate(mode: StartMode.tamamenRastgele);
      final Person anne = state.people
          .firstWhere((Person p) => p.relation == RelationType.anne);

      Set<String> metinler(bool hanede) => <String>{
            for (int i = 0; i < 40; i++)
              interactionText(
                rng: Random(i),
                person: anne.copyWith(inPlayerHousehold: hanede),
                kind: InteractionKind.vakitGecir,
                accepted: true,
                noNewBenefit: false,
                playerAge: 30,
              ),
          };

      expect(metinler(true).intersection(metinler(false)), isEmpty,
          reason: 'Hane içi temas ile ziyaret aynı bağlamda anlatılmamalı');
    });

    test('dolu bir değer için sahte kazanç yazılmaz', () {
      GameState state =
          cocukEkle(evliOyuncu(233, age: 30));
      state = state.copyWith(
        player: state.player.copyWith(
          stats: state.player.stats.copyWith(happiness: 100),
        ),
        people: state.people
            .map((Person p) => p.relation == RelationType.es
                ? p.copyWith(bond: 100)
                : p)
            .toList(growable: false),
      );

      final InteractionResult sonuc = etkilesim.perform(
        state: state,
        personId: state.spouse!.id,
        kind: InteractionKind.vakitGecir,
        rng: Random(1),
      );
      if (!sonuc.outcome.accepted) return;
      for (final AppliedEffect etki in sonuc.outcome.effects) {
        expect(etki.delta, isNot(0),
            reason: 'Gerçekte uygulanmayan değişim listelenmemeli');
        if (etki.label.contains('Mutluluk')) {
          fail('Dolu mutluluk için kazanç yazılmamalı: ${etki.label}');
        }
        if (etki.label.contains('yakınlık')) {
          fail('Dolu yakınlık için kazanç yazılmamalı: ${etki.label}');
        }
      }
      expect(sonuc.state.player.stats.happiness, 100);
    });
  });
}

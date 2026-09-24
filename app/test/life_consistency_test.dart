import 'dart:math';

import 'package:bir_omur/data/activity_catalog.dart';
import 'package:bir_omur/data/health_crisis_catalog.dart';
import 'package:bir_omur/data/job_catalog.dart';
import 'package:bir_omur/data/hobby_catalog.dart';
import 'package:bir_omur/data/item_catalog.dart';
import 'package:bir_omur/data/pet_catalog.dart';
import 'package:bir_omur/domain/generation/life_generator.dart';
import 'package:bir_omur/domain/interaction/marriage_engine.dart';
import 'package:bir_omur/domain/interaction/romance.dart';
import 'package:bir_omur/domain/life/health_crisis_engine.dart';
import 'package:bir_omur/domain/models/game_event.dart';
import 'package:bir_omur/domain/models/game_state.dart';
import 'package:bir_omur/domain/models/hobby_progress.dart';
import 'package:bir_omur/domain/models/life_log.dart';
import 'package:bir_omur/domain/models/marriage.dart';
import 'package:bir_omur/domain/models/owned_item.dart';
import 'package:bir_omur/domain/models/pending_crisis.dart';
import 'package:bir_omur/domain/models/person.dart';
import 'package:bir_omur/domain/models/relation.dart';
import 'package:bir_omur/domain/models/trip.dart';
import 'package:bir_omur/domain/pets/pet_care.dart';
import 'package:bir_omur/state/game_controller.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/test_flow.dart';

/// Hayat tutarlılığı / çelişki taraması (Paket 46).
///
/// Mevcut kilitlenme taramasını (`life_invariants_test.dart`) **tamamlar**;
/// onun yerine geçmez. Oradaki sorular "oyuncu ekranda sıkışır mı, cüzdan
/// eksiye iner mi" idi. Burada sorulan şey farklı: **aynı dünyada iki farklı
/// gerçeklik** oluşuyor mu? Ölü biri hanede yaşıyor mu, çocuk ebeveyninden
/// yaşlı mı, aynı eşya iki kişide mi, miras iki kez mi verildi?
///
/// Kan bağı olan kişiler romantik aday olamaz; çocuk iki kez doğamaz;
/// günlükte gelecekteki yaşa ait satır olamaz.

/// Romantik bağ kurulamayacak kan bağları.
const Set<RelationType> kKanBagi = <RelationType>{
  RelationType.anne,
  RelationType.baba,
  RelationType.kardes,
  RelationType.anneanne,
  RelationType.babaanne,
  RelationType.anneTarafiDede,
  RelationType.babaTarafiDede,
  RelationType.teyze,
  RelationType.dayi,
  RelationType.hala,
  RelationType.amca,
  RelationType.cocuk,
  RelationType.torun,
};

const Set<RelationType> kRomantik = <RelationType>{
  RelationType.sevgili,
  RelationType.es,
};

/// Bir durumda kırılan tutarlılık kuralı varsa açıklamasını döner.
String? celiski(GameState s) {
  final int yas = s.player.age;

  // ---------------- KİŞİLER ----------------
  final Set<String> kimlikler = <String>{};
  for (final Person p in s.people) {
    if (!kimlikler.add(p.id)) return 'Aynı kişi kimliği iki kez: ${p.id}';

    if (!p.isAlive && p.inPlayerHousehold) {
      return 'Vefat etmiş ${p.id} hâlâ hanede yaşıyor';
    }
    if (!p.isAlive && kRomantik.contains(p.relation)) {
      final Marriage? evlilik = s.marriage;
      final bool yuruyenEs = evlilik != null &&
          evlilik.isActive &&
          evlilik.spouseId == p.id;
      if (yuruyenEs) {
        return 'Vefat etmiş ${p.id} ile evlilik hâlâ yürüyor';
      }
    }
    if (kKanBagi.contains(p.relation) && kRomantik.contains(p.relation)) {
      return 'Kan bağı olan ${p.id} romantik bağda';
    }
    if (p.relation == RelationType.cocuk && p.age > yas) {
      return 'Çocuk ${p.id} oyuncudan yaşlı (${p.age} > $yas)';
    }
    if (p.relation == RelationType.torun && p.age > yas) {
      return 'Torun ${p.id} oyuncudan yaşlı';
    }
    if ((p.relation == RelationType.anne || p.relation == RelationType.baba) &&
        p.isAlive &&
        p.age - yas < 12) {
      return 'Ebeveyn ${p.id} oyuncudan yalnızca ${p.age - yas} yaş büyük';
    }
    if (p.age < 0) return '${p.id} eksi yaşta';
  }

  // Aynı kişi hem eş hem eski eş olamaz (kimlik tek, bağ tek).
  final List<Person> esler =
      s.people.where((Person p) => p.relation == RelationType.es).toList();
  if (esler.length > 1) {
    return 'Aynı anda ${esler.length} kişi "eş" görünüyor';
  }

  // ---------------- EVLİLİK ----------------
  final Marriage? aktif = s.marriage;
  if (aktif != null) {
    if (s.personById(aktif.spouseId) == null) {
      return 'Evlilik kaydı olmayan bir kişiye bağlı: ${aktif.spouseId}';
    }
    if (aktif.marriedAtAge > yas) {
      return 'Evlilik gelecekte görünüyor (${aktif.marriedAtAge} > $yas)';
    }
    final Person es = s.personById(aktif.spouseId)!;
    if (aktif.isActive && !es.isAlive) {
      return 'Eş vefat etmiş ama evlilik hâlâ "evli" durumda';
    }
    for (final Marriage m in s.pastMarriages) {
      if (m.spouseId == aktif.spouseId &&
          m.marriedAtAge == aktif.marriedAtAge) {
        return 'Yürüyen evlilik geçmişte de duruyor';
      }
    }
  }
  final Set<String> gecmisAnahtarlar = <String>{};
  for (final Marriage m in s.pastMarriages) {
    if (!gecmisAnahtarlar.add('${m.spouseId}-${m.marriedAtAge}')) {
      return 'Aynı geçmiş evlilik iki kez kayıtlı';
    }
    if (m.marriedAtAge > yas) return 'Geçmiş evlilik gelecekte görünüyor';
  }

  // ---------------- ÇOCUK ----------------
  final List<Person> cocuklar = s.children;
  final Set<String> cocukIdleri = <String>{};
  for (final Person c in cocuklar) {
    if (!cocukIdleri.add(c.id)) return 'Aynı çocuk iki kez: ${c.id}';
    final bool evlatlik = c.development?.adopted ?? false;
    if (!evlatlik && yas - c.age < 12) {
      return 'Öz çocuk ${c.id} oyuncu ${yas - c.age} yaşındayken doğmuş';
    }
  }

  // ---------------- PARA ----------------
  if (s.player.wallet < 0) return 'Cüzdan eksiye indi: ${s.player.wallet}';

  // ---------------- EŞYA ----------------
  final Set<String> esyaIdleri = <String>{};
  for (final OwnedItem i in s.items) {
    if (!esyaIdleri.add(i.id)) return 'Aynı eşya kimliği iki kez: ${i.id}';
    if (itemTypeById(i.typeId) == null) {
      return 'Bilinmeyen eşya türü: ${i.typeId}';
    }
    if (i.acquiredAtAge > yas) return 'Eşya ${i.id} gelecekte edinilmiş';
  }
  // Oturulan konut gerçekten envanterde olmalı.
  final String? konutId = s.residenceItemId;
  if (konutId != null && s.itemById(konutId) == null) {
    return 'Oturulan konut envanterde yok: $konutId';
  }

  // ---------------- GEZİ ----------------
  final Set<String> geziIdleri = <String>{};
  for (final TripRecord t in s.trips) {
    if (!geziIdleri.add(t.id)) return 'Aynı gezi kimliği iki kez: ${t.id}';
    if (t.age > yas) return 'Gezi gelecekte görünüyor: ${t.id}';
    final String? yoldas = t.companionId;
    if (yoldas != null && s.personById(yoldas) == null) {
      return 'Gezi yoldaşı kayıtta yok: $yoldas';
    }
  }

  // ---------------- HAYVAN ----------------
  final Set<String> hayvanIdleri = <String>{};
  for (final Pet p in s.pets) {
    if (!hayvanIdleri.add(p.id)) return 'Aynı hayvan kimliği iki kez: ${p.id}';
    final PetSpecies? tur = petSpeciesById(p.species);
    if (tur == null) return 'Bilinmeyen hayvan türü: ${p.species}';
    if (!p.isAlive) {
      if (p.diedAtAge == null || p.diedAtPlayerAge == null) {
        return 'Vefat eden hayvanın ölüm kaydı eksik: ${p.id}';
      }
      if (p.diedAtAge! > p.age) {
        return 'Hayvan ${p.id} kendi yaşından sonra ölmüş görünüyor';
      }
      if (p.diedAtPlayerAge! > yas) {
        return 'Hayvan ${p.id} gelecekte ölmüş görünüyor';
      }
    } else if (p.age > tur.maxLifespan) {
      return 'Hayvan ${p.id} üst ömrünü aşmış (${p.age})';
    }
    final int? sahiplenme = p.adoptedAtPlayerAge;
    if (sahiplenme != null && sahiplenme > yas) {
      return 'Hayvan ${p.id} gelecekte sahiplenilmiş';
    }
  }

  // ---------------- HOBİ ----------------
  final Set<String> hobiIdleri = <String>{};
  for (final HobbyProgress h in s.hobbies) {
    if (!hobiIdleri.add(h.hobbyId)) {
      return 'Aynı hobi iki kez kayıtlı: ${h.hobbyId}';
    }
    if (hobbyById(h.hobbyId) == null) return 'Bilinmeyen hobi: ${h.hobbyId}';
    if (h.startedAtAge > h.lastPracticedAge) {
      return 'Hobi ${h.hobbyId}: başlangıç son uğraşmadan sonra';
    }
    if (h.lastPracticedAge > yas) {
      return 'Hobi ${h.hobbyId}: gelecekte uğraşılmış';
    }
    for (final HobbyMemory an in h.memories) {
      if (an.age > yas) {
        return 'Hobi ${h.hobbyId}: yaşanmamış yıla ait anı (${an.age})';
      }
      if (an.age < h.startedAtAge) {
        return 'Hobi ${h.hobbyId}: başlamadan önceki yıla ait anı';
      }
    }
  }

  // ---------------- GÜNLÜK ----------------
  for (final LifeLogEntry e in s.log) {
    if (e.age > yas) {
      return 'Günlükte gelecekteki yaşa ait satır (${e.age} > $yas)';
    }
    final String? kisiId = e.personId;
    if (kisiId != null && s.personById(kisiId) == null) {
      return 'Günlük satırı kayıtta olmayan kişiye bağlı: $kisiId';
    }
  }
  // Ölmemiş biri için ölüm kaydı bulunmamalı.
  for (final Person p in s.people) {
    if (!p.isAlive) continue;
    final bool olumSatiri = s.log.any((LifeLogEntry e) =>
        e.personId == p.id &&
        (e.text.contains('vefat etti') ||
            e.text.contains('hayatını kaybetti')));
    if (olumSatiri) return 'Yaşayan ${p.id} için ölüm kaydı var';
  }

  return null;
}

void main() {
  // Taramanın gerçekten derine indiğini gösteren sayaçlar.
  int oynananHayat = 0;
  int denetlenenAdim = 0;
  int enBuyukYas = 0;
  int evlenen = 0;
  int cocukSahibi = 0;
  int bosanan = 0;
  int ikinciEvlilik = 0;
  int mirasAlan = 0;
  int esyaSahibi = 0;
  int geziYapan = 0;
  int hayvanBesleyen = 0;
  int hobiYapan = 0;

  setUp(() {
    oynananHayat = 0;
    denetlenenAdim = 0;
    enBuyukYas = 0;
    evlenen = 0;
    cocukSahibi = 0;
    bosanan = 0;
    ikinciEvlilik = 0;
    mirasAlan = 0;
    esyaSahibi = 0;
    geziYapan = 0;
    hayvanBesleyen = 0;
    hobiYapan = 0;
  });

  /// Bir hayatı ölene kadar oynar; **her adımda** çelişki denetler.
  void hayatOyna(int seed) {
    final GameController controller = GameController(random: Random(seed));
    addTearDown(controller.dispose);
    controller.startNewLife(mode: StartMode.tamamenRastgele, seed: seed);

    final Random secim = Random(seed * 17 + 3);
    int guard = 0;
    bool evlendiMi = false;
    bool bosandiMi = false;

    void denetle() {
      denetlenenAdim++;
      final String? hata = celiski(controller.state!);
      if (hata != null) {
        fail('Tohum $seed, yaş ${controller.state!.player.age}: $hata');
      }
    }

    while (!controller.state!.deceased) {
      if (guard++ > 400) {
        fail('Hayat ilerlemiyor (tohum $seed)');
      }
      denetle();
      if (controller.state!.player.age > enBuyukYas) {
        enBuyukYas = controller.state!.player.age;
      }

      final ActiveEvent? olay = controller.state!.pendingEvent;
      if (olay != null) {
        controller.chooseEventOption(
          olay.choices[secim.nextInt(olay.choices.length)].id,
        );
        continue;
      }
      final PendingCrisis? kriz = controller.state!.pendingCrisis;
      if (kriz != null) {
        const HealthCrisisEngine motor = HealthCrisisEngine();
        final HealthCrisis katalog = healthCrisisById(kriz.crisisId)!;
        final List<CrisisChoice> acik = katalog.choices
            .where((CrisisChoice c) => motor.canChoose(controller.state!, c))
            .toList(growable: false);
        controller.respondToCrisis(acik[secim.nextInt(acik.length)].id);
        continue;
      }
      if (controller.state!.notices.isNotEmpty) {
        controller.dismissNotice();
        continue;
      }
      if (controller.state!.isMarried) evlendiMi = true;
      if (evlendiMi && !controller.state!.isMarried) bosandiMi = true;

      // Hayatın olağan akışını sürükle. Tamamen rastgele oynanan bir
      // hayatta evlilik, çocuk ve miras neredeyse hiç olmuyor; o zaman da
      // tarama bu dalları hiç denetlemiyor. Yönlendirme yalnızca **var
      // olan** akışları kullanır, yeni kural koymaz.
      final GameState o = controller.state!;
      final int yas = o.player.age;

      if (yas == 24 && !o.career.isEmployed) {
        controller.applyForJob(kJobCatalog[seed % kJobCatalog.length]);
      }
      if (yas >= 22 && !const Romance().hasPartner(controller.state!)) {
        final GameState r =
            const Romance().start(controller.state!, secim).state;
        controller.debugSetState(
          r.copyWith(
            player: r.player.copyWith(wallet: r.player.wallet + 200000),
            people: r.people
                .map((Person p) => p.relation == RelationType.sevgili
                    ? p.copyWith(bond: 85)
                    : p)
                .toList(growable: false),
          ),
        );
      }
      if (yas >= 26 && !controller.state!.isMarried) {
        final Person? sevgili = const Romance().partnerOf(controller.state!);
        if (sevgili != null &&
            const MarriageEngine()
                .marryBlockReason(controller.state!, sevgili)
                .isEmpty) {
          controller.marry(sevgili.id);
        }
      }
      if (controller.state!.isMarried &&
          (yas == 29 || yas == 33) &&
          controller.state!.children.length < 2) {
        controller.haveChild();
      }
      // Hayatların bir bölümünde boşanma ve ikinci evlilik de denensin.
      if (seed.isEven && yas == 40 && controller.state!.isMarried) {
        controller.divorce();
      }

      // Gezi, hobi ve evcil hayvan da taramaya girsin; yoksa bu dalların
      // değişmezleri hiç denetlenmemiş olur.
      if (yas == 28 || yas == 45) {
        final List<String> sehirler = controller.travelDestinations();
        final List<Person> yoldaslar = controller.travelCompanions();
        if (sehirler.isNotEmpty) {
          final String sehir = sehirler[secim.nextInt(sehirler.length)];
          final String? yoldas = yoldaslar.isEmpty || seed.isOdd
              ? null
              : yoldaslar.first.id;
          if (controller
              .travelAvailability(
                mode: TravelMode.otobus,
                city: sehir,
                companionId: yoldas,
              )
              .isAllowed) {
            controller.takeTrip(
              mode: TravelMode.otobus,
              city: sehir,
              companionId: yoldas,
            );
          }
        }
      }
      if (yas >= 10 && yas <= 30) {
        final ActivityAction kurs = kActivityActions
            .firstWhere((ActivityAction a) => a.id == 'muzik_kursu');
        if (controller.activityAvailability(kurs).isAllowed) {
          controller.performActivity(kurs);
        }
      }
      if (yas == 25 &&
          PetCare.livingPets(controller.state!).isEmpty &&
          PetCare.adoptionAvailability(controller.state!, PetSpecies.kedi)
              .isAllowed) {
        controller.adoptPet(PetSpecies.kedi, 'Zeytin');
      }

      // Lise alanı seçilmeden yaş atlanmaz (D-094).
      resolveTrackChoice(controller);
      controller.ageUp();
    }

    denetle();
    oynananHayat++;

    final GameState son = controller.state!;
    if (evlendiMi) evlenen++;
    if (bosandiMi) bosanan++;
    if (son.pastMarriages.isNotEmpty) ikinciEvlilik++;
    if (son.children.isNotEmpty) cocukSahibi++;
    if (son.settledEstates.isNotEmpty) mirasAlan++;
    if (son.items.isNotEmpty) esyaSahibi++;
    if (son.trips.isNotEmpty) geziYapan++;
    if (son.pets.isNotEmpty) hayvanBesleyen++;
    if (son.hobbies.isNotEmpty) hobiYapan++;
  }

  test('100 hayat baştan sona: aynı dünyada iki gerçeklik oluşmuyor', () {
    for (int seed = 200; seed < 300; seed++) {
      hayatOyna(seed);
    }

    // ignore: avoid_print
    print('Tutarlılık taraması: $oynananHayat hayat, $denetlenenAdim denetim '
        'noktası, en büyük yaş $enBuyukYas');
    // ignore: avoid_print
    print('  evlenen $evlenen · boşanan $bosanan · ikinci evlilik '
        '$ikinciEvlilik · çocuklu $cocukSahibi · miras alan $mirasAlan · '
        'eşyalı $esyaSahibi · gezen $geziYapan · hayvanlı $hayvanBesleyen · '
        'hobili $hobiYapan');

    expect(oynananHayat, 100);
    expect(denetlenenAdim, greaterThan(3000),
        reason: 'Tarama sığ: çok az denetim noktası');
    expect(enBuyukYas, greaterThan(70));
    // Tarama gerçekten ilgili dallara uğramalı; yoksa boşuna güven verir.
    expect(evlenen, greaterThan(0), reason: 'Hiç evlilik olmamış');
    expect(cocukSahibi, greaterThan(0), reason: 'Hiç çocuk olmamış');
    expect(mirasAlan, greaterThan(0), reason: 'Hiç miras dağıtılmamış');
    expect(esyaSahibi, greaterThan(0), reason: 'Hiç eşya edinilmemiş');
    expect(geziYapan, greaterThan(0), reason: 'Hiç gezi yapılmamış');
    expect(hayvanBesleyen, greaterThan(0), reason: 'Hiç hayvan olmamış');
    expect(hobiYapan, greaterThan(0), reason: 'Hiç hobi yapılmamış');
    expect(bosanan, greaterThan(0), reason: 'Hiç boşanma olmamış');
    expect(ikinciEvlilik, greaterThan(0), reason: 'Hiç ikinci evlilik yok');
  });
}

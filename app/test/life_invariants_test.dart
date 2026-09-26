import 'dart:math';

import 'package:bir_omur/data/activity_catalog.dart';
import 'package:bir_omur/data/health_crisis_catalog.dart';
import 'package:bir_omur/data/hobby_catalog.dart';
import 'package:bir_omur/data/pet_catalog.dart';
import 'package:bir_omur/domain/generation/life_generator.dart';
import 'package:bir_omur/domain/life/health_crisis_engine.dart';
import 'package:bir_omur/domain/models/game_event.dart';
import 'package:bir_omur/domain/models/game_state.dart';
import 'package:bir_omur/domain/models/hobby_progress.dart';
import 'package:bir_omur/domain/models/pending_crisis.dart';
import 'package:bir_omur/domain/models/person.dart';
import 'package:bir_omur/domain/pets/pet_care.dart';
import 'package:bir_omur/state/game_controller.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/test_flow.dart';

/// Hayat boyu **hiçbir zaman bozulmaması gereken** kurallar (Paket 38).
///
/// Tek tek ekranları sınamak yerine, çok sayıda hayatı doğumdan ölüme
/// oynayıp her adımda aynı değişmezleri kontrol eder. Amaç, en ağır hata
/// türünü — **oyuncunun sıkışıp kaldığı ekran** — tek bir yerde yakalamak.
///
/// Daha önce gerçek bir örneği bulunmuştu: parası olmayan yaşlı bir
/// karakter zatürre krizinde iki seçeneği de karşılayamıyor ve ekranda
/// kilitleniyordu. Bu test o sınıfın tamamını tarar.
void main() {
  // Testin gerçekten ilgili dallara uğradığını doğrulamak için sayaçlar.
  // Hiç krize rastlamayan bir tarama boşuna güven verir.
  int gorulenKriz = 0;
  int gorulenOlay = 0;
  int olenHayat = 0;
  int enBuyukYas = 0;
  // Yeni sistemlerin taramada gerçekten çalıştığını gösteren sayaçlar
  // (Paket 42): sıfır kalırlarsa tarama o dallara hiç uğramamış demektir.
  int sahiplenilenHayvan = 0;
  int olenHayvan = 0;
  int hobiUgrasi = 0;
  int birlikteProgram = 0;

  setUp(() {
    gorulenKriz = 0;
    gorulenOlay = 0;
    olenHayat = 0;
    enBuyukYas = 0;
    sahiplenilenHayvan = 0;
    olenHayvan = 0;
    hobiUgrasi = 0;
    birlikteProgram = 0;
  });

  /// Bir durumda kırılan değişmez varsa açıklamasını döner.
  String? ihlal(GameState s) {
    if (s.player.wallet < 0) {
      return 'Cüzdan eksiye indi: ${s.player.wallet}';
    }

    // Bekleyen olayın en az bir seçeneği olmalı; yoksa ekran kapanmaz.
    final ActiveEvent? olay = s.pendingEvent;
    if (olay != null && olay.choices.isEmpty) {
      return 'Bekleyen olayın hiç seçeneği yok: ${olay.eventId}';
    }

    // Bekleyen krizin **karşılanabilir** en az bir seçeneği olmalı.
    final PendingCrisis? kriz = s.pendingCrisis;
    if (kriz != null) {
      const HealthCrisisEngine motor = HealthCrisisEngine();
      final HealthCrisis? katalog = healthCrisisById(kriz.crisisId);
      if (katalog == null) {
        return 'Bilinmeyen kriz: ${kriz.crisisId}';
      }
      if (katalog.choices.isEmpty) {
        return 'Krizin hiç seçeneği yok: ${kriz.crisisId}';
      }
      final bool acikVar = katalog.choices.any(
        (CrisisChoice c) => motor.canChoose(s, c),
      );
      if (!acikVar) {
        return 'Kriz "${kriz.crisisId}" ekranında karşılanabilir seçenek '
            'yok (cüzdan ${s.player.wallet} ₺) — oyuncu kilitlenir';
      }
    }

    final int m = s.player.stats.happiness;
    if (m < 0 || m > 100) return 'Mutluluk aralık dışı: $m';
    final int sg = s.player.stats.health;
    if (sg < 0 || sg > 100) return 'Sağlık aralık dışı: $sg';

    // --- Yeni sistemler (Paket 39-41) --------------------------------
    //
    // Kayıt asla silinmez ve aynı kimlik iki kez üretilmez.
    final Set<String> hayvanKimlikleri = <String>{};
    for (final Pet p in s.pets) {
      if (!hayvanKimlikleri.add(p.id)) {
        return 'Aynı hayvan kimliği iki kez: ${p.id}';
      }
      if (p.age < 0) return 'Hayvan yaşı eksi: ${p.id}';
      if (p.bond < 0 || p.bond > 100) {
        return 'Hayvan bağı aralık dışı: ${p.id} (${p.bond})';
      }
      final PetSpecies? tur = petSpeciesById(p.species);
      if (tur == null) return 'Bilinmeyen hayvan türü: ${p.species}';
      if (p.isAlive && p.age > tur.maxLifespan) {
        return 'Hayvan ${p.id} ${p.age} yaşında hâlâ yaşıyor '
            '(üst sınır ${tur.maxLifespan})';
      }
      if (!p.isAlive && p.diedAtPlayerAge == null) {
        return 'Vefat eden hayvanın ölüm yılı kayıtsız: ${p.id}';
      }
    }

    final Set<String> hobiKimlikleri = <String>{};
    for (final HobbyProgress h in s.hobbies) {
      if (!hobiKimlikleri.add(h.hobbyId)) {
        return 'Aynı hobi iki kez kayıtlı: ${h.hobbyId}';
      }
      if (hobbyById(h.hobbyId) == null) {
        return 'Bilinmeyen hobi: ${h.hobbyId}';
      }
      if (h.startedAtAge > h.lastPracticedAge) {
        return 'Hobi ${h.hobbyId}: başlangıç son uğraşmadan sonra';
      }
      if (h.lastPracticedAge > s.player.age) {
        return 'Hobi ${h.hobbyId}: gelecekte uğraşılmış görünüyor';
      }
      for (final HobbyMemory an in h.memories) {
        if (an.age > s.player.age) {
          return 'Hobi ${h.hobbyId}: yaşanmamış yıla ait anı (${an.age})';
        }
      }
    }

    final Set<String> kisiKimlikleri = <String>{};
    for (final Person p in s.people) {
      if (!kisiKimlikleri.add(p.id)) {
        return 'Aynı kişi kimliği iki kez: ${p.id}';
      }
    }

    return null;
  }

  /// Bir hayatı ölene kadar oynar; her adımda değişmezleri kontrol eder.
  void hayatOyna(
    int seed, {
    int? baslangicCuzdani,
    bool yeniSistemleriKullan = false,
  }) {
    final GameController controller = GameController(random: Random(seed));
    addTearDown(controller.dispose);
    GameState s =
        LifeGenerator.seeded(seed).generate(mode: StartMode.tamamenRastgele);
    if (baslangicCuzdani != null) {
      s = s.copyWith(player: s.player.copyWith(wallet: baslangicCuzdani));
    }
    controller.debugSetState(s);

    final Random secim = Random(seed * 31 + 7);
    int guard = 0;

    while (!controller.state!.deceased) {
      // Sınır, sonsuz döngüyü yakalamak içindir; yıl sayısı değildir.
      // D-114'ten sonra **her aktivite** bir bildirim üretiyor ve döngü
      // bildirimi kapatmak için bir tur daha dönüyor; bir yıl artık tek
      // tur değil birkaç tur sürüyor. Seksen beş yıllık bir hayat eski
      // 400'lük sınıra sığmıyordu.
      if (guard++ > 2000) {
        fail('Hayat ilerlemiyor (tohum $seed, yaş '
            '${controller.state!.player.age})');
      }

      final String? hata = ihlal(controller.state!);
      if (hata != null) {
        fail('Tohum $seed, yaş ${controller.state!.player.age}: $hata');
      }

      if (controller.state!.player.age > enBuyukYas) {
        enBuyukYas = controller.state!.player.age;
      }

      // Bekleyen olay varsa rastgele bir seçenek seçilir.
      final ActiveEvent? olay = controller.state!.pendingEvent;
      if (olay != null) {
        gorulenOlay++;
        final List<EventChoice> secenekler = olay.choices;
        controller.chooseEventOption(
          secenekler[secim.nextInt(secenekler.length)].id,
        );
        continue;
      }

      // Bekleyen kriz varsa karşılanabilir seçeneklerden biri seçilir.
      final PendingCrisis? kriz = controller.state!.pendingCrisis;
      if (kriz != null) {
        gorulenKriz++;
        const HealthCrisisEngine motor = HealthCrisisEngine();
        final HealthCrisis katalog = healthCrisisById(kriz.crisisId)!;
        final List<CrisisChoice> acik = katalog.choices
            .where((CrisisChoice c) => motor.canChoose(controller.state!, c))
            .toList(growable: false);
        controller.respondToCrisis(acik[secim.nextInt(acik.length)].id);
        continue;
      }

      // Bildirimler varsa temizlenir.
      if (controller.state!.notices.isNotEmpty) {
        controller.dismissNotice();
        continue;
      }

      // Yeni sistemler de taramaya girsin (Paket 42): hobi, evcil hayvan
      // ve birlikte çıkılan program gerçekten oynanır.
      if (yeniSistemleriKullan) {
        // Hobi: yaşına uygunsa müzik kursu ya da koşu.
        for (final String id in <String>['muzik_kursu', 'kosu']) {
          final ActivityAction a = kActivityActions
              .firstWhere((ActivityAction x) => x.id == id);
          if (controller.activityAvailability(a).isAllowed) {
            controller.performActivity(a);
            hobiUgrasi++;
            break;
          }
        }
        // Evcil hayvan: yoksa ve gücü yetiyorsa sahiplenilir.
        if (PetCare.livingPets(controller.state!).isEmpty &&
            PetCare.adoptionAvailability(
              controller.state!,
              PetSpecies.kedi,
            ).isAllowed) {
          controller.adoptPet(PetSpecies.kedi, 'Zeytin');
          sahiplenilenHayvan++;
        }
        // Hayvanla vakit geçir.
        final List<Pet> yasayan = PetCare.livingPets(controller.state!);
        if (yasayan.isNotEmpty) {
          controller.petInteract(yasayan.first, PetAction.vakitGecir);
        }
        // Birlikte program: katılabilecek biri varsa sinemaya.
        final ActivityAction sinema = kActivityActions
            .firstWhere((ActivityAction x) => x.id == 'sinema');
        final List<Person> yoldaslar = controller.outingCompanions(sinema);
        if (yoldaslar.isNotEmpty &&
            controller.activityAvailability(sinema).isAllowed) {
          controller.performActivity(sinema, companion: yoldaslar.first);
          birlikteProgram++;
        }
        final String? yeniHata = ihlal(controller.state!);
        if (yeniHata != null) {
          fail('Tohum $seed, yaş ${controller.state!.player.age}: '
              '$yeniHata');
        }
      }

      // Lise alanı seçilmeden yaş atlanmaz (D-094).
      resolveEducationChoices(controller);
      controller.ageUp();
    }

    olenHayat++;
    // Hayat boyunca vefat eden hayvanlar (kayıt silinmediği için ölümde
    // sayılabiliyor).
    olenHayvan +=
        controller.state!.pets.where((Pet p) => !p.isAlive).length;
    final String? sonHata = ihlal(controller.state!);
    if (sonHata != null) {
      fail('Tohum $seed, ölümde: $sonHata');
    }
  }

  /// Taramanın boşa dönmediğini doğrular.
  void taramaAnlamliMi(int beklenenHayat) {
    expect(olenHayat, beklenenHayat,
        reason: 'Her hayat ölümle bitmeliydi');
    expect(enBuyukYas, greaterThan(50),
        reason: 'Hayatlar ileri yaşa hiç ulaşmamış; tarama sığ');
    expect(gorulenOlay, greaterThan(100),
        reason: 'Olay ekranına hiç uğranmamış; tarama sığ');
    expect(gorulenKriz, greaterThan(0),
        reason: 'Hiç sağlık krizi çıkmamış; kilitlenme dalı hiç '
            'sınanmamış demektir');
    // ignore: avoid_print
    print('Tarama: $olenHayat hayat, $gorulenOlay olay, $gorulenKriz kriz, '
        'en büyük yaş $enBuyukYas');
  }

  test('40 hayat baştan sona oynanır, değişmezler bozulmaz', () {
    for (int seed = 0; seed < 40; seed++) {
      hayatOyna(seed);
    }
    taramaAnlamliMi(40);
  });

  test('parasız hayatlarda da kimse ekranda sıkışmaz', () {
    // En ağır hata bu koşulda çıkmıştı: cüzdan boş, yaş ilerlemiş,
    // kriz ekranında iki seçenek de karşılanamıyor.
    for (int seed = 0; seed < 25; seed++) {
      hayatOyna(seed, baslangicCuzdani: 0);
    }
    taramaAnlamliMi(25);
  });

  test('25 hayat yeni sistemler kullanılarak oynanır', () {
    // Hobi, evcil hayvan ve birlikte çıkılan program yalnızca kendi
    // testlerinde değil, **hayatın içinde** de bozulmamalı.
    for (int seed = 100; seed < 125; seed++) {
      hayatOyna(seed, yeniSistemleriKullan: true);
    }
    taramaAnlamliMi(25);
    // ignore: avoid_print
    print('Yeni sistemler: $hobiUgrasi hobi uğraşı, '
        '$sahiplenilenHayvan sahiplenme, $olenHayvan hayvan vefatı, '
        '$birlikteProgram birlikte program');
    expect(hobiUgrasi, greaterThan(100),
        reason: 'Hobi eylemleri taramada hiç yapılmamış');
    expect(sahiplenilenHayvan, greaterThan(0),
        reason: 'Hiç hayvan sahiplenilmemiş; hayvan dalı sınanmamış');
    expect(olenHayvan, greaterThan(0),
        reason: 'Hiç hayvan vefat etmemiş; ölüm dalı sınanmamış');
    expect(birlikteProgram, greaterThan(0),
        reason: 'Hiç birlikte programa çıkılmamış');
  });

  test('her sağlık krizinin boş cüzdanla karşılanabilir seçeneği vardır', () {
    // Katalog düzeyinde doğrudan kontrol: yukarıdaki oynatma bu durumu
    // rastlantıya bırakır, bu test bırakmaz.
    const HealthCrisisEngine motor = HealthCrisisEngine();
    final GameState parasiz =
        LifeGenerator.seeded(1).generate(mode: StartMode.tamamenRastgele);
    final GameState bos =
        parasiz.copyWith(player: parasiz.player.copyWith(wallet: 0));

    for (final HealthCrisis kriz in kHealthCrises) {
      expect(
        kriz.choices.any((CrisisChoice c) => motor.canChoose(bos, c)),
        isTrue,
        reason: '"${kriz.id}" krizinde parasız oyuncuya açık seçenek yok',
      );
    }
  });
}

// Olay kataloğu ölçüm aracı (Paket 4).
//
// Oyuna yeni bir şey eklemez: çok sayıda hayatı gerçek motorlarla oynatır
// ve olay kataloğunun kapsamını ölçer. Hangi yaşlarda olay çıkmıyor,
// hangi olaylar çok tekrarlanıyor, hangileri hiç görünmüyor?
//
// Çalıştırma: app dizininde
//   flutter test tool/event_report.dart
import 'dart:math';

import 'package:flutter_test/flutter_test.dart';

import 'package:bir_omur/data/event_pool.dart';
import 'package:bir_omur/data/health_crisis_catalog.dart';
import 'package:bir_omur/data/shop_catalog.dart';
import 'package:bir_omur/domain/economy/housing.dart';
import 'package:bir_omur/domain/events/event_engine.dart';
import 'package:bir_omur/domain/generation/life_generator.dart';
import 'package:bir_omur/domain/generation/life_progression.dart';
import 'package:bir_omur/domain/interaction/item_actions.dart';
import 'package:bir_omur/domain/interaction/marriage_engine.dart';
import 'package:bir_omur/domain/interaction/parenthood.dart';
import 'package:bir_omur/domain/interaction/romance.dart';
import 'package:bir_omur/domain/life/health_crisis_engine.dart';
import 'package:bir_omur/domain/models/game_event.dart';
import 'package:bir_omur/domain/models/game_state.dart';
import 'package:bir_omur/domain/models/owned_item.dart';
import 'package:bir_omur/domain/models/person.dart';
import 'package:bir_omur/domain/models/relation.dart';
import 'package:bir_omur/domain/social/social_engine.dart';
import 'package:bir_omur/data/social_catalog.dart';
import 'package:bir_omur/state/game_controller.dart';
import 'package:bir_omur/domain/pets/pet_care.dart';
import 'package:bir_omur/domain/models/trip.dart';
import 'package:bir_omur/domain/models/interaction.dart';
import 'package:bir_omur/domain/activities/travel.dart';
import 'package:bir_omur/data/pet_catalog.dart';
import 'package:bir_omur/data/job_catalog.dart';
import 'package:bir_omur/domain/career/colleagues.dart';
import 'package:bir_omur/data/activity_catalog.dart';

const int kHayatSayisi = 500;

void main() {
  test('olay raporu', _rapor, timeout: const Timeout(Duration(minutes: 10)));
}

/// Yaş grupları (Paket 47 raporu için).
const List<({String ad, int alt, int ust})> kYasGruplari =
    <({String ad, int alt, int ust})>[
  (ad: '0-5', alt: 0, ust: 5),
  (ad: '6-12', alt: 6, ust: 12),
  (ad: '13-17', alt: 13, ust: 17),
  (ad: '18-24', alt: 18, ust: 24),
  (ad: '25-39', alt: 25, ust: 39),
  (ad: '40-59', alt: 40, ust: 59),
  (ad: '60-79', alt: 60, ust: 79),
  (ad: '80+', alt: 80, ust: 200),
];

/// Olayın **konu** kümesi; katalogda saklanmaz, koşullarından türetilir.
///
/// `EventCategory` beş değer taşıyor (aile, okul, mahalle, kişisel,
/// yetişkinlik) ve bu, "kariyer olayı mı ilişki olayı mı" sorusunu tek
/// başına yanıtlamıyor. Buradaki kümeler yalnızca **rapor içindir**;
/// oyuna yeni bir alan eklemez.
Set<String> _konular(GameEvent e) {
  final EventRequirement r = e.requirement;
  final Set<String> konu = <String>{};
  if (e.category == EventCategory.aile) konu.add('aile');
  if (e.category == EventCategory.okul || r.requiresSchoolStudent) {
    konu.add('okul');
  }
  if (r.requiresEmployed ||
      r.requiresMinYearsInJob > 0 ||
      r.requiresRetired) {
    konu.add('kariyer');
  }
  if (r.livingRelations.any((RelationType t) =>
      t == RelationType.sevgili ||
      t == RelationType.es ||
      t == RelationType.eskiSevgili ||
      t == RelationType.eskiEs)) {
    konu.add('iliski');
  }
  if (r.livingRelations.isNotEmpty) konu.add('kisili');
  if (r.requiredHobbyId != null) konu.add('hobi');
  if (r.requiresLivingPet) konu.add('hayvan');
  if (konu.isEmpty) konu.add('diger');
  return konu;
}

/// Seçim yapılmadan **yalnızca bilgi veren** olay: tek seçeneği var ya da
/// hiçbir seçeneği ölçülebilir bir şey değiştirmiyor.
bool _sadeceBilgi(GameEvent e) {
  if (e.choices.length <= 1) return true;
  return e.choices.every((EventChoice c) =>
      c.happiness == 0 &&
      c.health == 0 &&
      c.intelligence == 0 &&
      c.charisma == 0 &&
      c.appearance == 0 &&
      c.money == 0 &&
      c.bond == 0 &&
      c.addFlags.isEmpty &&
      c.removeFlags.isEmpty &&
      c.addPossessions.isEmpty &&
      !c.startsRomance &&
      !c.startsFriendship &&
      !c.startsSchoolFriendship &&
      !c.endsRomance);
}

void _rapor() {
  final Map<String, int> olayAdedi = <String, int>{};
  final Map<int, int> yasBasinaOlay = <int, int>{};
  final Map<int, int> yasBasinaAdim = <int, int>{};
  final Map<String, int> ayniHayattaTekrar = <String, int>{};
  final Map<String, int> grupOlay = <String, int>{};
  final Map<String, int> grupAdim = <String, int>{};
  final Map<String, int> konuAdedi = <String, int>{};
  final Map<String, int> kategoriAdedi = <String, int>{};
  final List<Set<String>> hayatlarinOlaylari = <Set<String>>[];
  int bilgiOlayi = 0;
  int toplamAdim = 0;
  int toplamOlay = 0;

  final Map<String, GameEvent> katalog = <String, GameEvent>{
    for (final GameEvent e in kEventPool) e.id: e,
  };

  for (int seed = 1; seed <= kHayatSayisi; seed++) {
    final Random rng = Random(seed);
    final GameController controller = GameController(random: Random(seed));
    controller.startNewLife(mode: StartMode.tamamenRastgele, seed: seed);
    final Map<String, int> buHayatta = <String, int>{};
    bool evlendi = false;
    bool emekliOldu = false;

    void olayiKaydet() {
      final ActiveEvent? olay = controller.state!.pendingEvent;
      if (olay == null) return;
      final int yas = controller.state!.player.age;
      toplamOlay++;
      olayAdedi[olay.eventId] = (olayAdedi[olay.eventId] ?? 0) + 1;
      buHayatta[olay.eventId] = (buHayatta[olay.eventId] ?? 0) + 1;
      yasBasinaOlay[yas] = (yasBasinaOlay[yas] ?? 0) + 1;
      for (final ({String ad, int alt, int ust}) g in kYasGruplari) {
        if (yas >= g.alt && yas <= g.ust) {
          grupOlay[g.ad] = (grupOlay[g.ad] ?? 0) + 1;
          break;
        }
      }
      final GameEvent? kayit = katalog[olay.eventId];
      if (kayit != null) {
        kategoriAdedi[kayit.category.name] =
            (kategoriAdedi[kayit.category.name] ?? 0) + 1;
        for (final String k in _konular(kayit)) {
          konuAdedi[k] = (konuAdedi[k] ?? 0) + 1;
        }
        if (_sadeceBilgi(kayit)) bilgiOlayi++;
      }
      // Seçenek **rastgele** seçilir: hep ilk seçenek işaretlenseydi,
      // sonucu başka seçeneklere bağlı olan devam olayları ölçümde hiç
      // görünmezdi.
      controller.chooseEventOption(
        olay.choices[rng.nextInt(olay.choices.length)].id,
      );
    }

    void ekranlariTemizle() {
      int guard = 0;
      while (guard++ < 30) {
        if (controller.state!.hasPendingCrisis) {
          final HealthCrisis kriz = controller.pendingCrisis!.crisis!;
          const HealthCrisisEngine motor = HealthCrisisEngine();
          final CrisisChoice secim = kriz.choices.firstWhere(
            (CrisisChoice c) => motor.canChoose(controller.state!, c),
            orElse: () => kriz.choices.last,
          );
          controller.respondToCrisis(secim.id);
          continue;
        }
        if (controller.state!.notices.isNotEmpty) {
          controller.dismissNotice();
          continue;
        }
        if (controller.state!.hasPendingEvent) {
          olayiKaydet();
          continue;
        }
        return;
      }
    }

    int guard = 0;
    while (!controller.state!.deceased && controller.state!.player.age < 120) {
      if (guard++ > 400) break;
      ekranlariTemizle();
      if (controller.state!.deceased) break;

      final GameState o = controller.state!;
      final int yas = o.player.age;
      toplamAdim++;
      yasBasinaAdim[yas] = (yasBasinaAdim[yas] ?? 0) + 1;
      for (final ({String ad, int alt, int ust}) g in kYasGruplari) {
        if (yas >= g.alt && yas <= g.ust) {
          grupAdim[g.ad] = (grupAdim[g.ad] ?? 0) + 1;
          break;
        }
      }

      // --- Oyuncunun gerçekten yaptığı şeyler -------------------------
      //
      // Ek olaylar yalnızca **oyun içi ilerleme** biriktiğinde açılır
      // (D-023, D-024). Etkileşim yapmayan bir ölçüm harness'i o yolu hiç
      // denemez ve "hiç çıkmayan olay" listesi yanıltıcı olur.
      final List<Person> yakinlar = controller.state!.reachablePeople
          .where((Person p) => p.isAlive)
          .toList(growable: false);
      for (int i = 0; i < 4 && yakinlar.isNotEmpty; i++) {
        if (controller.state!.hasPendingEvent) {
          ekranlariTemizle();
          continue;
        }
        final Person kisi = yakinlar[rng.nextInt(yakinlar.length)];
        final List<InteractionKind> turler =
            controller.availableKindsFor(kisi);
        if (turler.isEmpty) continue;
        controller.interact(kisi.id, turler[rng.nextInt(turler.length)]);
      }
      ekranlariTemizle();
      if (controller.state!.deceased) break;

      // Hobi: kursa ve spora gerçekten gidilir.
      for (final String id in <String>['muzik_kursu', 'resim_atolyesi', 'kosu']) {
        final ActivityAction a =
            kActivityActions.firstWhere((ActivityAction x) => x.id == id);
        if (controller.activityAvailability(a).isAllowed) {
          controller.performActivity(a);
        }
      }

      // Kütüphanede kitap bitirmek "okumak" hobisini besler. Her hayatta
      // okunur: okuma hobisine bağlı olaylar ölçümde görünsün.
      if (yas >= 7 && yas <= 60) {
        final List<BookInfo> kitaplar = controller.availableBooks();
        if (kitaplar.isNotEmpty) {
          final BookInfo kitap = kitaplar[rng.nextInt(kitaplar.length)];
          for (int i = 0; i < kitap.pages + 1; i++) {
            controller.turnBookPage(kitap);
          }
        }
      }

      // Evcil hayvan: çocuklar küçükken hayatta olsun diye 25 yaşında
      // sahipleniliyor.
      if (yas == 25 &&
          PetCare.livingPets(controller.state!).isEmpty &&
          PetCare.adoptionAvailability(controller.state!, PetSpecies.kedi)
              .isAllowed) {
        controller.adoptPet(PetSpecies.kedi, 'Zeytin');
      }

      // Gezi: bazen yalnız, bazen yoldaşla.
      if ((yas == 20 || yas == 35 || yas == 55) && seed % 2 == 0) {
        final List<String> sehirler = controller.travelDestinations();
        final List<Person> yoldaslar = controller.travelCompanions();
        if (sehirler.isNotEmpty) {
          final String sehir = sehirler[rng.nextInt(sehirler.length)];
          final String? yoldas =
              yoldaslar.isEmpty ? null : yoldaslar.first.id;
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

      // Hayatın olağan akışı: iş, evlilik, çocuk, emeklilik.
      //
      // İş, mülakat akışından geçirilmek yerine **doğrudan** kuruluyor:
      // ölçüm aracının amacı mülakatı sınamak değil, iş hayatı olaylarının
      // havuzda görünüp görünmediğini ölçmek. İş arkadaşları gerçek
      // üreticiyle oluşturuluyor ki iş arkadaşı olayları da ölçüme girsin.
      if (yas == 24 && !controller.state!.career.isEmployed) {
        final JobType is1 = kJobCatalog[seed % kJobCatalog.length];
        final GameState o2 = controller.state!;
        final List<Person> isArkadaslari =
            Colleagues.generate(state: o2, job: is1, rng: rng);
        controller.debugSetState(
          o2.copyWith(
            people: List<Person>.unmodifiable(<Person>[
              ...o2.people,
              ...isArkadaslari,
            ]),
            career: o2.career.copyWith(
              jobId: is1.id,
              startedAtAge: yas,
              lastPaidAge: yas,
              jobCity: o2.player.currentCity,
            ),
            storyFlags: <String>{
              ...o2.storyFlags,
              StoryFlags.calismaHayati,
            },
          ),
        );
      }
      // Hayatların üçte biri bekâr kalsın: yalnız yaşayanlara özel olaylar
      // da ölçüme girsin.
      if (seed % 3 != 0 &&
          yas >= 22 &&
          !const Romance().hasPartner(controller.state!)) {
        final GameState r = const Romance().start(controller.state!, rng).state;
        controller.debugSetState(
          r.copyWith(
            people: r.people
                .map((Person p) => p.relation == RelationType.sevgili
                    ? p.copyWith(bond: 85)
                    : p)
                .toList(growable: false),
          ),
        );
      }
      if (seed % 3 != 0 && yas >= 26 && !evlendi) {
        final Person? sevgili = const Romance().partnerOf(controller.state!);
        if (sevgili != null &&
            const MarriageEngine()
                .marryBlockReason(controller.state!, sevgili)
                .isEmpty) {
          controller.marry(sevgili.id);
          evlendi = true;
        }
      }
      if (controller.state!.isMarried && (yas == 29 || yas == 32)) {
        controller.haveChild();
      }
      if (yas >= 66 && !emekliOldu && controller.state!.career.isEmployed) {
        controller.retire();
        emekliOldu = true;
      }
      if (yas == 42 && controller.state!.items.every((OwnedItem i) => !i.isProperty)) {
        final ItemActionResult alim = const ItemActions().buy(
          state: controller.state!,
          product: shopProductByTypeId('kucuk_daire')!,
        );
        if (alim.outcome.applied) {
          controller.debugSetState(
            const Housing().moveInto(alim.state, alim.state.items.last).state,
          );
        }
      }
      if (yas == 20 && seed.isEven && controller.state!.socialAccounts.isEmpty) {
        controller.openSocialAccount(SocialPlatform.values.first);
      }
      if (yas == 30 && seed % 3 == 0) {
        controller.debugSetState(
          controller.state!
              .copyWith(licenses: <String>{'otomobil_ehliyeti'}).grantItems(
            <String>['otomobil_ikinci_el'],
            source: ItemSource.satinAlma,
          ),
        );
      }

      ekranlariTemizle();
      if (controller.state!.deceased) break;
      controller.ageUp();
    }

    for (final MapEntry<String, int> e in buHayatta.entries) {
      if (e.value > 1) {
        ayniHayattaTekrar[e.key] =
            (ayniHayattaTekrar[e.key] ?? 0) + e.value - 1;
      }
    }
    hayatlarinOlaylari.add(buHayatta.keys.toSet());
    controller.dispose();
  }

  print('=== OLAY KAPSAMI ($kHayatSayisi hayat) ===');
  print('Katalogdaki olay sayısı : ${kEventPool.length}');
  print('Toplam yaş adımı        : $toplamAdim');
  print('Toplam gösterilen olay  : $toplamOlay');
  print('Yaş başına olay oranı   : '
      '%${(toplamOlay * 100 / toplamAdim).toStringAsFixed(1)}');
  print('');

  print('--- Yaş aralığına göre olay çıkma oranı ---');
  for (int start = 0; start <= 95; start += 5) {
    int adim = 0;
    int olay = 0;
    for (int a = start; a < start + 5; a++) {
      adim += yasBasinaAdim[a] ?? 0;
      olay += yasBasinaOlay[a] ?? 0;
    }
    if (adim == 0) continue;
    final double oran = olay * 100 / adim;
    final String bar = '#' * (oran / 4).round();
    print('${start.toString().padLeft(3)}-${(start + 4).toString().padLeft(3)}: '
        '${oran.toStringAsFixed(0).padLeft(3)}%  $bar');
  }
  print('');

  print('--- Yaş grubuna göre olay sayısı ---');
  for (final ({String ad, int alt, int ust}) g in kYasGruplari) {
    final int adim = grupAdim[g.ad] ?? 0;
    final int olay = grupOlay[g.ad] ?? 0;
    if (adim == 0) {
      print('${g.ad.padRight(6)}: (bu yaş aralığı hiç oynanmadı)');
      continue;
    }
    print('${g.ad.padRight(6)}: ${olay.toString().padLeft(6)} olay / '
        '${adim.toString().padLeft(6)} yıl  '
        '(%${(olay * 100 / adim).toStringAsFixed(0)})');
  }
  print('');

  print('--- Konu dağılımı (olay gösterimi başına) ---');
  final List<MapEntry<String, int>> konular = konuAdedi.entries.toList()
    ..sort((MapEntry<String, int> a, MapEntry<String, int> b) =>
        b.value.compareTo(a.value));
  for (final MapEntry<String, int> e in konular) {
    print('${e.key.padRight(10)} ${e.value.toString().padLeft(6)}  '
        '(%${(e.value * 100 / toplamOlay).toStringAsFixed(1)})');
  }
  print('');

  print('--- Katalog kategorisi dağılımı ---');
  final List<MapEntry<String, int>> kategoriler =
      kategoriAdedi.entries.toList()
        ..sort((MapEntry<String, int> a, MapEntry<String, int> b) =>
            b.value.compareTo(a.value));
  for (final MapEntry<String, int> e in kategoriler) {
    print('${e.key.padRight(14)} ${e.value.toString().padLeft(6)}  '
        '(%${(e.value * 100 / toplamOlay).toStringAsFixed(1)})');
  }
  print('');

  print('--- Seçim gerektirmeyen (yalnızca bilgi veren) olaylar ---');
  final int bilgiKatalog =
      kEventPool.where(_sadeceBilgi).length;
  print('Katalogda: $bilgiKatalog / ${kEventPool.length} '
      '(%${(bilgiKatalog * 100 / kEventPool.length).toStringAsFixed(1)})');
  print('Gösterimde: $bilgiOlayi / $toplamOlay '
      '(%${(bilgiOlayi * 100 / toplamOlay).toStringAsFixed(1)})');
  print('');

  print('--- Hayatlar birbirinden farklı mı? ---');
  int ciftSayisi = 0;
  double toplamOrtakOran = 0;
  final Random ornekRng = Random(99);
  for (int i = 0; i < 400; i++) {
    final int a = ornekRng.nextInt(hayatlarinOlaylari.length);
    final int b = ornekRng.nextInt(hayatlarinOlaylari.length);
    if (a == b) continue;
    final Set<String> x = hayatlarinOlaylari[a];
    final Set<String> y = hayatlarinOlaylari[b];
    if (x.isEmpty || y.isEmpty) continue;
    final int ortak = x.intersection(y).length;
    final int birlesim = x.union(y).length;
    toplamOrtakOran += ortak / birlesim;
    ciftSayisi++;
  }
  final double ortalamaOlayTuru = hayatlarinOlaylari.isEmpty
      ? 0
      : hayatlarinOlaylari
              .map((Set<String> s) => s.length)
              .reduce((int a, int b) => a + b) /
          hayatlarinOlaylari.length;
  print('Bir hayatta ortalama farklı olay türü : '
      '${ortalamaOlayTuru.toStringAsFixed(1)}');
  if (ciftSayisi > 0) {
    print('İki rastgele hayatın olay örtüşmesi   : '
        '%${(toplamOrtakOran * 100 / ciftSayisi).toStringAsFixed(1)} '
        '(Jaccard; 100% = birebir aynı hayat)');
  }
  final Map<String, int> kacHayatta = <String, int>{};
  for (final Set<String> h in hayatlarinOlaylari) {
    for (final String id in h) {
      kacHayatta[id] = (kacHayatta[id] ?? 0) + 1;
    }
  }
  final List<MapEntry<String, int>> yaygin = kacHayatta.entries.toList()
    ..sort((MapEntry<String, int> a, MapEntry<String, int> b) =>
        b.value.compareTo(a.value));
  final int yariHayat = (kHayatSayisi / 2).round();
  final int cokYaygin =
      yaygin.where((MapEntry<String, int> e) => e.value >= yariHayat).length;
  print('Hayatların yarısından çoğunda çıkan olay sayısı: $cokYaygin');
  print('');

  print('--- En sık gösterilen olaylar ---');
  final List<MapEntry<String, int>> sirali = olayAdedi.entries.toList()
    ..sort((MapEntry<String, int> a, MapEntry<String, int> b) =>
        b.value.compareTo(a.value));
  for (final MapEntry<String, int> e in sirali.take(20)) {
    print('${e.key.padRight(32)} ${e.value.toString().padLeft(5)} '
        '(hayat başına ${(e.value / kHayatSayisi).toStringAsFixed(2)})');
  }
  print('');

  print('--- Aynı hayatta tekrarlananlar ---');
  final List<MapEntry<String, int>> tekrar = ayniHayattaTekrar.entries.toList()
    ..sort((MapEntry<String, int> a, MapEntry<String, int> b) =>
        b.value.compareTo(a.value));
  if (tekrar.isEmpty) {
    print('(yok)');
  }
  for (final MapEntry<String, int> e in tekrar.take(10)) {
    print('${e.key.padRight(32)} ${e.value} fazladan gösterim');
  }
  print('');

  print('--- Hiç gösterilmeyen olaylar ---');
  final List<String> hic = <String>[
    for (final GameEvent e in kEventPool)
      if (!olayAdedi.containsKey(e.id)) e.id,
  ];
  print(hic.isEmpty ? '(yok)' : hic.join(', '));
}

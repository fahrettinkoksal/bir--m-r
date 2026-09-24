import 'dart:convert';
import 'dart:math';

import 'package:bir_omur/data/save/game_state_codec.dart';
import 'package:bir_omur/data/save/save_format.dart';
import 'package:bir_omur/data/save/save_service.dart';
import 'package:bir_omur/data/save/save_store.dart';
import 'package:bir_omur/data/health_crisis_catalog.dart';
import 'package:bir_omur/data/license_catalog.dart';
import 'package:bir_omur/data/shop_catalog.dart';
import 'package:bir_omur/data/social_catalog.dart';
import 'package:bir_omur/domain/economy/housing.dart';
import 'package:bir_omur/domain/economy/living_costs.dart';
import 'package:bir_omur/domain/generation/life_generator.dart';
import 'package:bir_omur/domain/generation/life_progression.dart';
import 'package:bir_omur/domain/interaction/item_actions.dart';
import 'package:bir_omur/domain/interaction/marriage_engine.dart';
import 'package:bir_omur/domain/interaction/parenthood.dart';
import 'package:bir_omur/domain/interaction/romance.dart';
import 'package:bir_omur/domain/models/education.dart';
import 'package:bir_omur/domain/models/game_event.dart';
import 'package:bir_omur/domain/models/game_state.dart';
import 'package:bir_omur/domain/models/life_summary.dart';
import 'package:bir_omur/domain/models/marriage.dart';
import 'package:bir_omur/domain/models/owned_item.dart';
import 'package:bir_omur/domain/models/person.dart';
import 'package:bir_omur/domain/social/social_engine.dart';
import 'package:bir_omur/state/game_controller.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/invariants.dart';

import 'support/test_flow.dart';

/// Ekrandaki olayı ve krizi kapatarak bir yaş ilerletir.
void yasAl(GameController controller) {
  int guard = 0;
  while (controller.state!.hasPendingCrisis) {
    if (guard++ > 20) fail('Kriz kapanmıyor.');
    final String secim = controller.pendingCrisis!.crisis!.choices
        .firstWhere(
          controller.canChooseCrisis,
          orElse: () => controller.pendingCrisis!.crisis!.choices.last,
        )
        .id;
    controller.respondToCrisis(secim);
  }
  while (controller.state!.hasPendingEvent) {
    if (guard++ > 40) fail('Olay kapanmıyor.');
    controller.chooseEventOption(
      controller.state!.pendingEvent!.choices.first.id,
    );
  }
  // Lise alanı seçilmeden yaş atlanmaz (D-094).
  resolveEducationChoices(controller);
  controller.ageUp();
  while (controller.state!.hasPendingCrisis) {
    if (guard++ > 60) fail('Kriz kapanmıyor.');
    final String secim = controller.pendingCrisis!.crisis!.choices
        .firstWhere(
          controller.canChooseCrisis,
          orElse: () => controller.pendingCrisis!.crisis!.choices.last,
        )
        .id;
    controller.respondToCrisis(secim);
  }
}

void yasaKadar(GameController controller, int hedef) {
  int guard = 0;
  while (controller.state!.player.age < hedef &&
      !controller.state!.deceased) {
    if (guard++ > 200) fail('Yaş ilerlemiyor.');
    yasAl(controller);
  }
}

void main() {
  // ===================================================================
  // 1) Eğitim hattı
  // ===================================================================
  test('senaryo 1: doğum → okul → lise → mezuniyet → yaş alma', () {
    final GameController controller = GameController(random: Random(11));
    addTearDown(controller.dispose);
    controller.startNewLife(mode: StartMode.tamamenRastgele, seed: 11);

    expect(controller.state!.player.age, 0);
    expect(controller.state!.education.enrolled, isFalse);

    yasaKadar(controller, 7);
    if (controller.state!.deceased) return;
    expect(controller.state!.education.enrolled, isTrue,
        reason: 'Okula başlanmalı');
    expect(controller.state!.education.level, SchoolLevel.ilkokul);
    expect(controller.state!.currentClassmates, isNotEmpty);

    yasaKadar(controller, 11);
    if (controller.state!.deceased) return;
    expect(controller.state!.education.level, SchoolLevel.ortaokul);

    yasaKadar(controller, 15);
    if (controller.state!.deceased) return;
    expect(controller.state!.education.level, SchoolLevel.lise);
    expect(controller.state!.education.placementScore, isNotNull,
        reason: 'Yerleştirme puanı hesaplanmalı');

    yasaKadar(controller, 19);
    if (controller.state!.deceased) return;
    expect(controller.state!.education.finished, isTrue);
    expect(controller.state!.education.universityExamScore, isNotNull);
    // Eğitim geçmişi silinmiyor.
    expect(controller.state!.education.placementScore, isNotNull);
    expect(checkInvariants(controller.state!, where: 'eğitim hattı'), isEmpty);
  });

  // ===================================================================
  // 2) Aile hattı
  // ===================================================================
  test('senaryo 2: tanışma → evlilik → çocuk → taşınma → ölüm → arşiv',
      () async {
    final GameController controller = GameController(random: Random(12));
    addTearDown(controller.dispose);
    controller.startNewLife(mode: StartMode.tamamenRastgele, seed: 12);

    // Yetişkin, parası olan bir hayat kur.
    GameState state = controller.state!;
    state = state.copyWith(
      player: state.player.copyWith(age: 28, wallet: 6000000),
    );
    final ({GameState state, Person partner}) romantik =
        const Romance().start(state, Random(3));
    state = romantik.state.copyWith(
      people: romantik.state.people
          .map((Person p) =>
              p.id == romantik.partner.id ? p.copyWith(bond: 90) : p)
          .toList(growable: false),
    );
    controller.debugSetState(state);

    // Evlilik
    expect(controller.marry(romantik.partner.id)?.applied, isTrue);
    expect(controller.state!.isMarried, isTrue);

    // Çocuk
    expect(controller.haveChild()?.applied, isTrue);
    final String cocukId = controller.state!.children.single.id;

    // Ev alıp taşınma
    final ItemActionResult alim = const ItemActions().buy(
      state: controller.state!,
      product: shopProductByTypeId('kucuk_daire')!,
    );
    expect(alim.outcome.applied, isTrue, reason: alim.outcome.text);
    controller.debugSetState(alim.state);
    expect(controller.moveInto(controller.state!.items.last)?.applied, isTrue);
    expect(Housing.residenceOf(controller.state!), ResidenceKind.kendiEvinde);

    // Yıllar geçsin
    yasaKadar(controller, 40);
    if (!controller.state!.deceased) {
      expect(controller.state!.personById(cocukId), isNotNull);
      expect(checkInvariants(controller.state!, where: 'aile hattı'), isEmpty);
    }

    // Oyuncunun ölümü ve arşiv
    controller.debugSetState(
      controller.state!.copyWith(
        deceased: true,
        deathAge: controller.state!.player.age,
        deathCause: 'yaşlılık',
      ),
    );
    final int arsivOnce = controller.pastLives.length;
    controller.clearLife();
    expect(controller.pastLives.length, arsivOnce + 1);
    expect(controller.pastLives.last.familyLine, isNotNull);

    // Yeni hayat arşivi taşır.
    controller.startNewLife(mode: StartMode.tamamenRastgele, seed: 99);
    expect(controller.state!.pastLives.length, arsivOnce + 1,
        reason: 'Yeni hayat eski arşivi silmemeli');
    expect(controller.state!.marriage, isNull);
    expect(controller.state!.children, isEmpty);
  });

  // ===================================================================
  // 3) Ekonomi hattı
  // ===================================================================
  test('senaryo 3: kazanç → alım → kiraya verme → yıllık hesap → kayıt',
      () async {
    final GameController controller = GameController(random: Random(13));
    addTearDown(controller.dispose);
    controller.startNewLife(mode: StartMode.tamamenRastgele, seed: 13);
    controller.debugSetState(
      controller.state!.copyWith(
        player: controller.state!.player.copyWith(age: 30, wallet: 9000000),
        pendingEvent: null,
      ),
    );

    // İki konut: biri oturulacak, biri kiraya verilecek.
    for (final String tur in <String>['kucuk_daire', 'standart_daire']) {
      final ItemActionResult r = const ItemActions().buy(
        state: controller.state!,
        product: shopProductByTypeId(tur)!,
      );
      expect(r.outcome.applied, isTrue, reason: r.outcome.text);
      controller.debugSetState(r.state);
    }
    final OwnedItem oturulan = controller.state!.items.first;
    final OwnedItem kiralik = controller.state!.items.last;

    expect(controller.moveInto(oturulan)?.applied, isTrue);
    expect(controller.rentOutHome(kiralik)?.applied, isTrue);
    // Oturulan ev kiraya verilemez.
    expect(controller.rentOutHome(controller.state!.items.first)?.applied,
        isFalse);

    final int kira = Housing.yearlyRentIncome(controller.state!);
    expect(kira, greaterThan(0));

    final int cuzdanOnce = controller.state!.player.wallet;
    final int gider = LivingCosts.yearlyCost(controller.state!);
    yasAl(controller);
    if (controller.state!.deceased) return;

    // Kira bir kez gelir, gider bir kez çıkar (kiracı bulunduysa).
    final int fark = controller.state!.player.wallet - cuzdanOnce;
    expect(fark, anyOf(<Matcher>[equals(kira - gider), equals(-gider)]),
        reason: 'Kira veya gider iki kez uygulanmamalı');

    final SaveService service = SaveService(MemorySaveStore());
    await service.save(controller.state!);
    final GameState geri = (await service.load()).state!;
    expect(geri.player.wallet, controller.state!.player.wallet);
    expect(geri.items.length, controller.state!.items.length);
    expect(geri.residenceItemId, controller.state!.residenceItemId);
    expect(Housing.yearlyRentIncome(geri), kira);
  });

  // ===================================================================
  // 4) Sosyal medya hattı
  // ===================================================================
  test('senaryo 4: hesap → paylaşım → platform sınırı → yaş → yenilenme',
      () {
    final GameController controller = GameController(random: Random(14));
    addTearDown(controller.dispose);
    controller.startNewLife(mode: StartMode.tamamenRastgele, seed: 14);
    controller.debugSetState(
      controller.state!.copyWith(
        player: controller.state!.player.copyWith(age: 20),
        pendingEvent: null,
      ),
    );

    final SocialPlatform a = SocialPlatform.values.first;
    final SocialPlatform b = SocialPlatform.values[1];
    expect(controller.openSocialAccount(a)?.applied, isTrue);
    expect(controller.openSocialAccount(b)?.applied, isTrue);

    SocialContent icerikFor(SocialPlatform p) => kSocialContents
        .firstWhere((SocialContent c) => c.platform == p);

    // A platformunun sınırını doldur.
    int paylasim = 0;
    while (controller.remainingSocialPosts(a) > 0) {
      final SocialOutcome? sonuc = controller.postContent(icerikFor(a));
      expect(sonuc?.applied, isTrue, reason: sonuc?.text);
      paylasim++;
      if (paylasim > 20) fail('Sınır dolmuyor.');
    }
    expect(paylasim, SocialEngine.prototypeOnlyMaxPostsPerAge);
    expect(controller.postContent(icerikFor(a))?.applied, isFalse);

    // Diğer platform etkilenmez (Paket 1 hatası).
    expect(controller.remainingSocialPosts(b),
        SocialEngine.prototypeOnlyMaxPostsPerAge);
    expect(controller.postContent(icerikFor(b))?.applied, isTrue);

    // Yaş alınca sınır yenilenir.
    yasAl(controller);
    if (controller.state!.deceased) return;
    expect(controller.remainingSocialPosts(a),
        SocialEngine.prototypeOnlyMaxPostsPerAge);
  });

  // ===================================================================
  // 5) Bekleyen durumda kapat / yükle
  // ===================================================================
  group('senaryo 5: bekleyen durumda kapat-yükle', () {
    Future<GameState> kaydetYukle(GameState state) async {
      final SaveService service = SaveService(MemorySaveStore());
      await service.save(state);
      final SaveLoadResult r = await service.load();
      expect(r.isLoaded, isTrue, reason: r.message);
      return r.state!;
    }

    test('bekleyen olay aynı seçeneklerle geri gelir ve bir kez uygulanır',
        () async {
      final GameController controller = GameController(random: Random(15));
      addTearDown(controller.dispose);
      controller.startNewLife(mode: StartMode.tamamenRastgele, seed: 15);
      int guard = 0;
      while (!controller.state!.hasPendingEvent) {
        if (guard++ > 30) fail('Olay çıkmadı.');
        yasAl(controller);
      }

      final GameState once = controller.state!;
      final GameState geri = await kaydetYukle(once);
      expect(geri.pendingEvent!.eventId, once.pendingEvent!.eventId);
      expect(
        geri.pendingEvent!.choices.map((EventChoice c) => c.id).toList(),
        once.pendingEvent!.choices.map((EventChoice c) => c.id).toList(),
      );

      final int mutlulukOnce = geri.player.stats.happiness;
      controller.debugSetState(geri);
      controller.chooseEventOption(geri.pendingEvent!.choices.first.id);
      final int mutlulukSonra = controller.state!.player.stats.happiness;
      // Aynı seçim ikinci kez uygulanamaz: olay ekrandan kalkar.
      expect(controller.state!.hasPendingEvent, isFalse);
      controller.chooseEventOption(geri.pendingEvent!.choices.first.id);
      expect(controller.state!.player.stats.happiness, mutlulukSonra);
      expect(mutlulukSonra, isNot(equals(mutlulukOnce - 1000)));
    });

    test('bekleyen ehliyet sınavı ve ücreti iki kez alınmaz', () async {
      final GameController controller = GameController(random: Random(16));
      addTearDown(controller.dispose);
      controller.startNewLife(mode: StartMode.tamamenRastgele, seed: 16);
      controller.debugSetState(
        controller.state!.copyWith(
          player: controller.state!.player.copyWith(age: 20, wallet: 200000),
          pendingEvent: null,
        ),
      );

      final int cuzdanOnce = controller.state!.player.wallet;
      expect(controller.applyForLicense(LicenseType.values.first)?.applied,
          isTrue);
      expect(controller.state!.hasPendingLicenseExam, isTrue);
      final int ucretSonrasi = controller.state!.player.wallet;
      expect(ucretSonrasi, lessThan(cuzdanOnce));

      final GameState geri = await kaydetYukle(controller.state!);
      expect(geri.hasPendingLicenseExam, isTrue);
      expect(geri.pendingLicenseExam!.questionIds,
          controller.state!.pendingLicenseExam!.questionIds);
      expect(geri.player.wallet, ucretSonrasi,
          reason: 'Yükleme ücreti ikinci kez almamalı');

      // Sınavı bitir: ücret yine alınmaz.
      controller.debugSetState(geri);
      int guard = 0;
      while (controller.state!.hasPendingLicenseExam) {
        if (guard++ > 10) fail('Sınav bitmiyor.');
        controller.answerLicenseExam(0);
      }
      expect(controller.state!.player.wallet, ucretSonrasi);
    });

    test('bekleyen sağlık krizi geri gelir ve bedeli bir kez düşer',
        () async {
      final GameController controller = GameController(random: Random(17));
      addTearDown(controller.dispose);
      controller.startNewLife(mode: StartMode.tamamenRastgele, seed: 17);
      controller.debugSetState(
        controller.state!.copyWith(
          player: controller.state!.player.copyWith(age: 60, wallet: 500000),
          pendingEvent: null,
        ),
      );

      int guard = 0;
      while (!controller.state!.hasPendingCrisis) {
        if (guard++ > 60) return; // bu hayatta kriz çıkmadı
        if (controller.state!.deceased) return;
        controller.debugSetState(
          controller.state!.copyWith(pendingEvent: null),
        );
        // Lise alanı seçilmeden yaş atlanmaz (D-094).
        resolveEducationChoices(controller);
        controller.ageUp();
      }

      final GameState geri = await kaydetYukle(controller.state!);
      expect(geri.hasPendingCrisis, isTrue);
      expect(geri.pendingCrisis!.crisisId,
          controller.state!.pendingCrisis!.crisisId);

      controller.debugSetState(geri);
      final int cuzdanOnce = controller.state!.player.wallet;
      final CrisisChoice secim = controller.pendingCrisis!.crisis!.choices
          .firstWhere(controller.canChooseCrisis,
              orElse: () =>
                  controller.pendingCrisis!.crisis!.choices.last);
      controller.respondToCrisis(secim.id);
      final int cuzdanSonra = controller.state!.player.wallet;
      expect(cuzdanSonra, lessThanOrEqualTo(cuzdanOnce));
      // İkinci kez yanıtlamak bedel almaz.
      controller.respondToCrisis(secim.id);
      expect(controller.state!.player.wallet, cuzdanSonra);
    });
  });

  // ===================================================================
  // 6) Kayıt göç zinciri (sentetik)
  // ===================================================================
  group('senaryo 6: sürüm göç zinciri (sentetik)', () {
    // ÖNEMLİ: elimizde gerçek eski kullanıcı kayıtları yok. Aşağıdaki
    // gövdeler güncel kayıttan, o sürümden **sonra** eklenen alanlar
    // çıkarılarak üretilir. Bu, göç zincirinin çalıştığını gösterir ama
    // gerçek bir oyuncu dosyasıyla yapılmış test değildir.
    Map<String, Object?> surumIcin(GameState state, int surum) {
      final Map<String, Object?> body =
          jsonDecode(jsonEncode(encodeGameState(state)))
              as Map<String, Object?>;

      void kaldir(List<String> anahtarlar) {
        for (final String a in anahtarlar) {
          body.remove(a);
        }
      }

      if (surum < 17) {
        for (final Object? p in body['people']! as List<Object?>) {
          (p! as Map<String, Object?>).remove('city');
        }
        (body['career']! as Map<String, Object?>).remove('jobCity');
      }
      if (surum < 16) {
        for (final Object? l in body['pastLives']! as List<Object?>) {
          (l! as Map<String, Object?>).remove('familyLine');
        }
      }
      if (surum < 15) {
        kaldir(<String>['marriage']);
        // Sürüm 15'ten önce eş ve çocuk bağı **hiç yoktu**; gerçek bir
        // eski kayıtta bu kişiler de bulunmaz.
        final List<Object?> people = body['people']! as List<Object?>;
        people.removeWhere((Object? p) {
          final Object? bag = (p! as Map<String, Object?>)['relation'];
          return bag == 'es' || bag == 'eskiEs' || bag == 'cocuk';
        });
      }
      if (surum < 14) {
        kaldir(<String>['healthWarned', 'pendingCrisis', 'lastCrisisAge']);
      }
      if (surum < 13) {
        kaldir(<String>['movedOut', 'residenceItemId']);
        (body['player']! as Map<String, Object?>).remove('currentCity');
        for (final Object? i in body['items']! as List<Object?>) {
          (i! as Map<String, Object?>).remove('rentedOut');
        }
      }
      if (surum < 12) {
        kaldir(<String>[
          'pastLives',
          'grief',
          'hardshipYears',
          'settings',
          'careStatus',
        ]);
      }
      // Sürüm 22 öncesi: vasiyet seçimi yok.
      if (surum < 22) kaldir(<String>['heirChildId']);
      // Sürüm 21 öncesi: bildirim kuyruğu yok.
      if (surum < 21) kaldir(<String>['notices']);
      // Sürüm 20 öncesi: teklif/başvuru geçmişi yok.
      if (surum < 20) kaldir(<String>['proposalAges']);
      // Sürüm 19 öncesi: kişilerin kendi hayat kaydı yok.
      if (surum < 19) {
        for (final Object? p in body['people']! as List<Object?>) {
          (p! as Map<String, Object?>).remove('development');
        }
      }
      // Sürüm 18 öncesi: kuşak sayacı yok.
      if (surum < 18) kaldir(<String>['generation']);
      if (surum < 11) {
        kaldir(<String>[
          'settledEstates',
          'deceased',
          'deathAge',
          'deathCause',
        ]);
      }
      if (surum < 10) kaldir(<String>['pendingLicenseExam']);
      if (surum < 9) kaldir(<String>['licenses']);
      if (surum < 8) kaldir(<String>['wagerThisAge', 'blackjack']);
      if (surum < 6) kaldir(<String>['socialAccounts']);
      if (surum < 5) {
        kaldir(<String>['books']);
        (body['player']! as Map<String, Object?>).remove('hairStyle');
      }
      if (surum < 4) {
        kaldir(<String>['career']);
        (body['education']! as Map<String, Object?>)
            .remove('universityFinished');
      }
      if (surum < 3) {
        // Eşyalar tür kümesine döner.
        final List<Object?> items = body['items']! as List<Object?>;
        body['possessions'] = <String>[
          for (final Object? i in items)
            (i! as Map<String, Object?>)['typeId']! as String,
        ];
        kaldir(<String>['items']);
      }
      if (surum < 2) {
        for (final Object? p in body['people']! as List<Object?>) {
          (p! as Map<String, Object?>)
            ..remove('schoolId')
            ..remove('classId');
        }
      }
      return body;
    }

    test('desteklenen her sürümden giriş yapılabilir', () async {
      // Zengin bir hayat: kişiler, eşyalar, evlilik, çocuk, arşiv.
      GameState state = LifeGenerator.seeded(18)
          .generate(mode: StartMode.tamamenRastgele)
          .copyWith(
            player: LifeGenerator.seeded(18)
                .generate(mode: StartMode.tamamenRastgele)
                .player
                .copyWith(age: 35, wallet: 5000000),
          );
      final ({GameState state, Person partner}) r =
          const Romance().start(state, Random(2));
      state = r.state.copyWith(
        people: r.state.people
            .map((Person p) =>
                p.id == r.partner.id ? p.copyWith(bond: 90) : p)
            .toList(growable: false),
      );
      state = const MarriageEngine().marry(state, r.partner.id).state;
      state = const Parenthood().haveChild(state, Random(1)).state;
      state = const ItemActions()
          .buy(state: state, product: shopProductByTypeId('bisiklet')!)
          .state;
      state = state.copyWith(
        pastLives: <LifeSummary>[
          const LifeSummary(
            fullName: 'Önceki Hayat',
            birthCity: 'Sivas',
            deathAge: 70,
            deathCause: 'yaşlılık',
            educationLabel: 'Lise',
            careerLabel: 'Çalışmadı',
            wallet: 0,
            itemCount: 0,
            licenseCount: 0,
            highlights: <String>['30: bir şey oldu'],
          ),
        ],
      );

      // Faho'nun kararı (Paket 12): geriye dönük yalnızca son beş sürüm
      // taşınır. Daha eskisi anlaşılır bir mesajla reddedilir.
      for (int surum = kMinReadableSaveVersion;
          surum <= kSaveFormatVersion;
          surum++) {
        final SaveLoadResult sonuc = await SaveService(
          MemorySaveStore(
            initial: jsonEncode(<String, Object?>{
              'formatVersion': surum,
              'state': surumIcin(state, surum),
            }),
          ),
        ).load();

        expect(sonuc.isLoaded, isTrue,
            reason: 'Sürüm $surum açılmadı: ${sonuc.message}');
        final GameState geri = sonuc.state!;
        expect(geri.player.fullName, state.player.fullName,
            reason: 'Sürüm $surum');
        expect(geri.people.length, state.people.length,
            reason: 'Sürüm $surum: kişi kaybı');
        expect(checkInvariants(geri, where: 'sürüm $surum'), isEmpty);
        expect(geri.items.length, state.items.length,
            reason: 'Sürüm $surum: eşya kaybı');
        // Arşiv hiçbir sürümde silinmez.
        expect(geri.pastLives, hasLength(1), reason: 'Sürüm $surum');
      }
    });

    test('tabanın altındaki çok eski kayıt anlaşılır mesajla reddedilir',
        () async {
      final GameState state =
          LifeGenerator.seeded(19).generate(mode: StartMode.tamamenRastgele);
      final SaveLoadResult sonuc = await SaveService(
        MemorySaveStore(
          initial: jsonEncode(<String, Object?>{
            'formatVersion': kMinReadableSaveVersion - 1,
            'state': encodeGameState(state),
          }),
        ),
      ).load();

      expect(sonuc.isLoaded, isFalse);
      expect(sonuc.message, isNotNull);
      // Oyuncuya dosyanın silindiği söylenmez.
      expect(sonuc.message, contains('silinmedi'));
      expect(sonuc.message, isNot(contains('bozuk')));
    });

    test('gelecek sürümlü kayıt bozuk sayılmaz, anlaşılır mesaj verir',
        () async {
      final GameState state =
          LifeGenerator.seeded(19).generate(mode: StartMode.tamamenRastgele);
      final SaveLoadResult sonuc = await SaveService(
        MemorySaveStore(
          initial: jsonEncode(<String, Object?>{
            'formatVersion': kSaveFormatVersion + 5,
            'state': encodeGameState(state),
          }),
        ),
      ).load();
      expect(sonuc.isLoaded, isFalse);
      expect(sonuc.message, contains('güncelle'));
    });
  });

  // ===================================================================
  // 7) Kayıp ve değişim sonrası bütünlük
  // ===================================================================
  test('senaryo 7: ölüm, boşanma ve yeni hayat sonrası bütünlük', () {
    final GameController controller = GameController(random: Random(20));
    addTearDown(controller.dispose);
    controller.startNewLife(mode: StartMode.tamamenRastgele, seed: 20);

    GameState state = controller.state!.copyWith(
      player: controller.state!.player.copyWith(age: 30, wallet: 3000000),
    );
    final ({GameState state, Person partner}) r =
        const Romance().start(state, Random(5));
    state = r.state.copyWith(
      people: r.state.people
          .map((Person p) => p.id == r.partner.id ? p.copyWith(bond: 90) : p)
          .toList(growable: false),
    );
    controller.debugSetState(state);
    controller.marry(r.partner.id);
    controller.haveChild();

    // Çocuğun vefatı
    final String cocukId = controller.state!.children.single.id;
    controller.debugSetState(
      controller.state!.copyWith(
        people: controller.state!.people
            .map((Person p) => p.id == cocukId
                ? p.copyWith(isAlive: false, inPlayerHousehold: false)
                : p)
            .toList(growable: false),
      ),
    );
    expect(checkInvariants(controller.state!, where: 'çocuk kaybı'), isEmpty);

    // Boşanma
    expect(controller.divorce()?.applied, isTrue);
    expect(controller.state!.marriage!.status, MarriageStatus.bosandi);
    expect(checkInvariants(controller.state!, where: 'boşanma'), isEmpty);

    // Yeni hayat: eski hayatın verisi yeni hayata sızmaz.
    controller.startNewLife(mode: StartMode.tamamenRastgele, seed: 21);
    expect(controller.state!.marriage, isNull);
    expect(controller.state!.children, isEmpty);
    expect(controller.state!.people.any((Person p) => p.id == cocukId),
        isFalse);
    expect(checkInvariants(controller.state!, where: 'yeni hayat'), isEmpty);
  });

  test('maaş yılda bir kez ödenir', () {
    GameState state = LifeGenerator.seeded(31)
        .generate(mode: StartMode.tamamenRastgele);
    state = state.copyWith(
      player: state.player.copyWith(age: 30, wallet: 1000000),
      career: state.career.copyWith(
        jobId: 'ogretmen',
        startedAtAge: 28,
        lastPaidAge: 30,
      ),
      pendingEvent: null,
    );

    final int maas = state.career.job!.yearlySalary;
    final int gider = LivingCosts.yearlyCost(state);
    final int cuzdan = state.player.wallet;

    final GameState sonra =
        LifeProgression(Random(2)).advanceOneYear(state);
    expect(sonra.player.wallet, cuzdan + maas - gider,
        reason: 'Maaş bir kez ödenmeli, gider bir kez çıkmalı');

    // Aynı yaş için ikinci ödeme yapılmaz.
    final GameState ayniYas = sonra.copyWith(pendingEvent: null);
    expect(ayniYas.career.lastPaidAge, sonra.player.age);
  });

  // ===================================================================
  // 8) Toplu simülasyon
  // ===================================================================
  test('senaryo 8: 300 hayat çift ödeme ve bozulma üretmez', () {
    final List<String> sorunlar = <String>[];
    int toplamYas = 0;

    for (int seed = 600; seed < 900; seed++) {
      final Random rng = Random(seed);
      GameState state =
          LifeGenerator.seeded(seed).generate(mode: StartMode.tamamenRastgele);
      final Set<String> odenenMiras = <String>{};

      while (!state.deceased && state.player.age < 120) {
        final int cuzdanOnce = state.player.wallet;
        final int maas = state.career.job?.yearlySalary ?? 0;
        final int kira = Housing.yearlyRentIncome(state);
        final int gider = LivingCosts.yearlyCost(state);

        state = state.copyWith(pendingEvent: null, pendingCrisis: null);
        state = LifeProgression(rng).advanceOneYear(state);
        toplamYas++;

        // Tek yılda gelir, maaş+kira+miras toplamını aşamaz.
        final int artis = state.player.wallet - cuzdanOnce + gider;
        if (artis > maas + kira + 5000000) {
          sorunlar.add('tohum $seed yaş ${state.player.age}: '
              'beklenmeyen gelir artışı $artis');
        }

        // Aynı mirasın iki kez dağıtılmadığını doğrula.
        for (final String id in state.settledEstates) {
          if (!odenenMiras.add(id)) continue;
        }

        sorunlar.addAll(
          checkInvariants(state, where: 'tohum $seed'),
        );
        if (sorunlar.length > 10) break;

        // Ekranda kalan olay yaş ilerlemesini kilitlememeli.
        if (state.hasPendingEvent) {
          final GameState kilitli = LifeProgression(rng).advanceOneYear(state);
          if (kilitli.player.age != state.player.age) {
            sorunlar.add('tohum $seed: olay varken yaş ilerledi');
          }
        }
      }
      if (sorunlar.length > 10) break;
    }

    expect(toplamYas, greaterThan(10000),
        reason: 'Simülasyon gerçekten hayat oynamalı');
    expect(sorunlar, isEmpty);
  }, timeout: const Timeout(Duration(minutes: 5)));
}

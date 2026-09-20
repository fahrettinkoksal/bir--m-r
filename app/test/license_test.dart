import 'dart:convert';
import 'dart:math';

import 'package:bir_omur/data/item_catalog.dart';
import 'package:bir_omur/data/license_catalog.dart';
import 'package:bir_omur/data/license_questions.dart';
import 'package:bir_omur/data/save/game_state_codec.dart';
import 'package:bir_omur/data/save/save_service.dart';
import 'package:bir_omur/data/save/save_store.dart';
import 'package:bir_omur/data/shop_catalog.dart';
import 'package:bir_omur/domain/generation/life_generator.dart';
import 'package:bir_omur/domain/generation/life_progression.dart';
import 'package:bir_omur/domain/interaction/item_actions.dart';
import 'package:bir_omur/domain/licensing/license_office.dart';
import 'package:bir_omur/domain/models/game_state.dart';
import 'package:bir_omur/domain/models/interaction.dart';
import 'package:bir_omur/domain/models/owned_item.dart';
import 'package:bir_omur/domain/models/pending_license_exam.dart';
import 'package:flutter_test/flutter_test.dart';

const LicenseOffice office = LicenseOffice();
const ItemActions items = ItemActions();

GameState oyuncu(int seed, {int age = 20, int wallet = 1000000}) {
  final GameState state =
      LifeGenerator.seeded(seed).generate(mode: StartMode.tamamenRastgele);
  return state.copyWith(
    player: state.player.copyWith(age: age, wallet: wallet),
  );
}

/// Sınavı doğru cevaplayarak ehliyeti alır.
GameState ehliyetAl(GameState state, LicenseType type) {
  final LicenseResult basvuru = office.apply(state, type, Random(1));
  expect(basvuru.outcome.examStarted, isTrue, reason: basvuru.outcome.text);
  final LicenseQuestion soru = basvuru.state.pendingLicenseExam!.question!;
  final LicenseResult cevap =
      office.answer(basvuru.state, soru.correctIndex);
  expect(cevap.outcome.granted, isTrue);
  return cevap.state;
}

void main() {
  // ===================================================================
  // Soru havuzları
  // ===================================================================
  group('Ehliyet soruları', () {
    test('her ehliyetin ayrı ve yeterli soru havuzu var', () {
      for (final LicenseType type in LicenseType.values) {
        final List<LicenseQuestion> sorular = questionsForLicense(type.id);
        expect(sorular.length, greaterThanOrEqualTo(4),
            reason: '${type.label} için en az 4 soru olmalı');
        for (final LicenseQuestion q in sorular) {
          expect(q.licenseId, type.id);
        }
      }
      // İki havuz birbirinden bağımsız.
      final Set<String> moto = questionsForLicense(LicenseType.motosiklet.id)
          .map((LicenseQuestion q) => q.id)
          .toSet();
      final Set<String> oto = questionsForLicense(LicenseType.otomobil.id)
          .map((LicenseQuestion q) => q.id)
          .toSet();
      expect(moto.intersection(oto), isEmpty);
    });

    test('sorular tek doğru cevaplı ve açıklamalı', () {
      final Set<String> idler = <String>{};
      final Set<String> metinler = <String>{};
      for (final LicenseQuestion q in kLicenseQuestions) {
        expect(idler.add(q.id), isTrue, reason: 'Tekrarlı id: ${q.id}');
        expect(metinler.add(q.text), isTrue, reason: 'Tekrarlı soru metni');
        expect(q.options.length, greaterThanOrEqualTo(3));
        expect(q.options.toSet().length, q.options.length);
        expect(q.correctIndex, inInclusiveRange(0, q.options.length - 1));
        expect(q.explanation.trim(), isNotEmpty);
      }
    });
  });

  // ===================================================================
  // Başvuru ve sınav
  // ===================================================================
  group('Başvuru akışı', () {
    test('yaşı tutmayan başvuramaz ve ücret kesilmez', () {
      final GameState kucuk = oyuncu(1, age: 12);
      final LicenseResult r =
          office.apply(kucuk, LicenseType.otomobil, Random(1));
      expect(r.outcome.applied, isFalse);
      expect(r.state.player.wallet, kucuk.player.wallet);
      expect(r.state.pendingLicenseExam, isNull);
    });

    test('parası yetmeyen başvuramaz', () {
      final GameState fakir = oyuncu(2, wallet: 100);
      final LicenseResult r =
          office.apply(fakir, LicenseType.motosiklet, Random(1));
      expect(r.outcome.applied, isFalse);
      expect(r.state.player.wallet, 100);
    });

    test('başvuru ücreti bir kez kesilir ve sınav açılır', () {
      final GameState state = oyuncu(3);
      final int ucret = prototypeOnlyExamFee(LicenseType.otomobil);
      final LicenseResult r =
          office.apply(state, LicenseType.otomobil, Random(2));

      expect(r.outcome.examStarted, isTrue);
      expect(r.outcome.granted, isFalse);
      expect(r.state.player.wallet, state.player.wallet - ucret);
      final PendingLicenseExam? sinav = r.state.pendingLicenseExam;
      expect(sinav, isNotNull);
      expect(sinav!.licenseId, LicenseType.otomobil.id);
      expect(sinav.feePaid, ucret);
      expect(sinav.question, isNotNull);
      expect(r.state.licenses, isEmpty, reason: 'Cevapsız ehliyet verilmez');
    });

    test('doğru cevap ehliyeti kalıcı olarak verir ve günlüğe yazar', () {
      final GameState state = oyuncu(4);
      final GameState ehliyetli = ehliyetAl(state, LicenseType.motosiklet);

      expect(ehliyetli.hasLicense(LicenseType.motosiklet.id), isTrue);
      expect(ehliyetli.pendingLicenseExam, isNull);
      expect(ehliyetli.log.last.text, contains('ehliyetin artık var'));
    });

    test('yanlış cevapta ehliyet verilmez, doğru cevap gösterilir', () {
      final GameState state = oyuncu(5);
      final LicenseResult basvuru =
          office.apply(state, LicenseType.otomobil, Random(3));
      final LicenseQuestion soru = basvuru.state.pendingLicenseExam!.question!;
      final int yanlis = (soru.correctIndex + 1) % soru.options.length;
      final LicenseResult cevap = office.answer(basvuru.state, yanlis);

      expect(cevap.outcome.granted, isFalse);
      expect(cevap.state.licenses, isEmpty);
      expect(cevap.outcome.correctAnswer, soru.correctOption);
      expect(cevap.outcome.explanation, soru.explanation);
      expect(cevap.state.pendingLicenseExam, isNull);
    });

    test('cevap iki kez uygulanmaz, ücret tekrar kesilmez', () {
      final GameState state = oyuncu(6);
      final LicenseResult basvuru =
          office.apply(state, LicenseType.motosiklet, Random(1));
      final LicenseQuestion soru = basvuru.state.pendingLicenseExam!.question!;
      final LicenseResult ilk =
          office.answer(basvuru.state, soru.correctIndex);

      final int cuzdan = ilk.state.player.wallet;
      final int gunluk = ilk.state.log.length;
      final LicenseResult ikinci =
          office.answer(ilk.state, soru.correctIndex);

      expect(ikinci.outcome.applied, isFalse);
      expect(ikinci.state.player.wallet, cuzdan);
      expect(ikinci.state.log.length, gunluk);
      expect(ikinci.state.licenses.length, 1);
    });

    test('bir ehliyet diğerini vermez', () {
      final GameState ehliyetli =
          ehliyetAl(oyuncu(7, age: 20), LicenseType.motosiklet);
      expect(ehliyetli.hasLicense(LicenseType.motosiklet.id), isTrue);
      expect(ehliyetli.hasLicense(LicenseType.otomobil.id), isFalse);

      final GameState ikisi = ehliyetAl(ehliyetli, LicenseType.otomobil);
      expect(ikisi.licenses.length, 2);
    });

    test('sahip olunan ehliyete yeniden başvurulamaz', () {
      final GameState ehliyetli =
          ehliyetAl(oyuncu(8), LicenseType.otomobil);
      final InteractionAvailability durum =
          office.applicationAvailability(ehliyetli, LicenseType.otomobil);
      expect(durum.isAllowed, isFalse);
      expect(durum.reason, contains('zaten sende'));

      final int cuzdan = ehliyetli.player.wallet;
      final LicenseResult r =
          office.apply(ehliyetli, LicenseType.otomobil, Random(1));
      expect(r.outcome.applied, isFalse);
      expect(r.state.player.wallet, cuzdan);
    });

    test('sınav sürerken yeni başvuru açılmaz', () {
      final GameState state = oyuncu(9);
      final LicenseResult ilk =
          office.apply(state, LicenseType.motosiklet, Random(1));
      final LicenseResult ikinci =
          office.apply(ilk.state, LicenseType.otomobil, Random(1));
      expect(ikinci.outcome.applied, isFalse);
      expect(ikinci.state.player.wallet, ilk.state.player.wallet);
    });

    test('vazgeçmek ücreti iade etmez ve hak harcanır', () {
      final GameState state = oyuncu(10);
      final LicenseResult basvuru =
          office.apply(state, LicenseType.otomobil, Random(1));
      final LicenseResult iptal = office.cancel(basvuru.state);

      expect(iptal.state.pendingLicenseExam, isNull);
      expect(iptal.state.player.wallet, basvuru.state.player.wallet,
          reason: 'İade yok');
      expect(
        iptal.state.interactionCount(LicenseType.otomobil.id, 'ehliyet'),
        1,
      );
    });
  });

  // ===================================================================
  // Tekrar başvuru
  // ===================================================================
  group('Tekrar başvuru kuralı', () {
    test('aynı yaşta sınırlı deneme, her denemede ücret alınır', () {
      GameState state = oyuncu(20);
      final int ucret = prototypeOnlyExamFee(LicenseType.otomobil);
      final int cuzdanOnce = state.player.wallet;
      final List<String> sorulan = <String>[];

      for (int i = 0; i < 5; i++) {
        final LicenseResult r =
            office.apply(state, LicenseType.otomobil, Random(i));
        if (!r.outcome.applied) break;
        final LicenseQuestion soru = r.state.pendingLicenseExam!.question!;
        sorulan.add(soru.id);
        final int yanlis = (soru.correctIndex + 1) % soru.options.length;
        state = office.answer(r.state, yanlis).state;
      }

      expect(sorulan.length, LicenseOffice.prototypeOnlyMaxAttemptsPerAge);
      expect(sorulan.toSet().length, sorulan.length,
          reason: 'Aynı yaşta aynı soru tekrarlanmamalı');
      expect(state.player.wallet, cuzdanOnce - ucret * sorulan.length,
          reason: 'Her denemede ücret bir kez alınmalı');
      expect(
        office.applicationAvailability(state, LicenseType.otomobil).isAllowed,
        isFalse,
      );
    });

    test('yaş ilerleyince tekrar başvurulabilir', () {
      GameState state = oyuncu(21, age: 20);
      for (int i = 0; i < LicenseOffice.prototypeOnlyMaxAttemptsPerAge; i++) {
        final LicenseResult r =
            office.apply(state, LicenseType.motosiklet, Random(i));
        final LicenseQuestion soru = r.state.pendingLicenseExam!.question!;
        state = office
            .answer(r.state, (soru.correctIndex + 1) % soru.options.length)
            .state;
      }
      expect(
        office.applicationAvailability(state, LicenseType.motosiklet).isAllowed,
        isFalse,
      );

      final GameState seneye = LifeProgression(Random(1)).advanceOneYear(state);
      expect(
        office
            .applicationAvailability(seneye, LicenseType.motosiklet)
            .isAllowed,
        isTrue,
      );
    });
  });

  // ===================================================================
  // Araç sistemiyle bağlantı
  // ===================================================================
  group('Ehliyet ve araç kullanımı', () {
    GameState aracAl(GameState state, String typeId) {
      final ItemActionResult r = items.buy(
        state: state,
        product: shopProductByTypeId(typeId)!,
      );
      expect(r.outcome.applied, isTrue, reason: r.outcome.text);
      return r.state;
    }

    test('ehliyet alınca ilgili araç kullanılabilir olur', () {
      GameState state = aracAl(oyuncu(30, wallet: 2000000), 'otomobil_ekonomik');
      final OwnedItem araba = state.items.last;

      expect(
        items.availability(state, araba, ItemActionKind.kullan).isAllowed,
        isFalse,
        reason: 'Ehliyetsiz sürülemez',
      );

      state = ehliyetAl(state, LicenseType.otomobil);
      expect(
        items
            .availability(state, state.itemById(araba.id)!,
                ItemActionKind.kullan)
            .isAllowed,
        isTrue,
      );
    });

    test('motosiklet ehliyeti otomobil kullandırmaz', () {
      GameState state = aracAl(oyuncu(31, wallet: 2000000), 'otomobil_ikinci_el');
      state = aracAl(state, 'motosiklet_ekonomik');
      state = ehliyetAl(state, LicenseType.motosiklet);

      final OwnedItem araba = state.items
          .firstWhere((OwnedItem i) => i.typeId.startsWith('otomobil'));
      final OwnedItem motor = state.items
          .firstWhere((OwnedItem i) => i.typeId.startsWith('motosiklet'));

      expect(
        items.availability(state, motor, ItemActionKind.kullan).isAllowed,
        isTrue,
      );
      expect(
        items.availability(state, araba, ItemActionKind.kullan).isAllowed,
        isFalse,
      );
    });
  });

  // ===================================================================
  // Kayıt / yükleme
  // ===================================================================
  group('Ehliyet kaydı', () {
    test('yarıda kalan sınav aynı soruyla geri gelir', () async {
      final GameState state = oyuncu(40);
      final LicenseResult basvuru =
          office.apply(state, LicenseType.otomobil, Random(5));
      final PendingLicenseExam once = basvuru.state.pendingLicenseExam!;

      final SaveService service = SaveService(MemorySaveStore());
      await service.save(basvuru.state);
      final SaveLoadResult result = await service.load();
      expect(result.isLoaded, isTrue, reason: result.message);
      final GameState geri = result.state!;

      final PendingLicenseExam sonra = geri.pendingLicenseExam!;
      expect(sonra.licenseId, once.licenseId);
      expect(sonra.questionId, once.questionId);
      expect(sonra.askedAtAge, once.askedAtAge);
      expect(sonra.feePaid, once.feePaid);
      expect(sonra.question!.text, once.question!.text);
      expect(sonra.question!.options, once.question!.options);
      expect(geri.player.wallet, basvuru.state.player.wallet,
          reason: 'Yükleme ücreti ikinci kez kesmemeli');

      // Yükledikten sonra verilen cevap normal sonuçlanır.
      final LicenseResult cevap =
          office.answer(geri, sonra.question!.correctIndex);
      expect(cevap.outcome.granted, isTrue);
      expect(cevap.state.hasLicense(LicenseType.otomobil.id), isTrue);
    });

    test('alınan ehliyet kaydedilip geri okunur', () async {
      final GameState ehliyetli =
          ehliyetAl(oyuncu(41), LicenseType.motosiklet);
      final SaveService service = SaveService(MemorySaveStore());
      await service.save(ehliyetli);
      final GameState geri = (await service.load()).state!;
      expect(geri.licenses, ehliyetli.licenses);
      expect(geri.hasLicense(LicenseType.motosiklet.id), isTrue);
    });

    test('sürüm 9 kaydı açık sınav alanı olmadan açılır', () async {
      final GameState state = oyuncu(42);
      final Map<String, Object?> body = encodeGameState(state);
      body.remove('pendingLicenseExam');

      final SaveLoadResult result = await SaveService(
        MemorySaveStore(
          initial: jsonEncode(
            <String, Object?>{'formatVersion': 9, 'state': body},
          ),
        ),
      ).load();
      expect(result.isLoaded, isTrue, reason: result.message);
      expect(result.state!.pendingLicenseExam, isNull);
      expect(result.state!.player.wallet, state.player.wallet);
    });
  });
}

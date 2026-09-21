import 'dart:math';

import 'package:bir_omur/data/save/game_state_codec.dart';
import 'package:bir_omur/data/save/save_format.dart';
import 'package:bir_omur/domain/generation/generation_continuation.dart';
import 'package:bir_omur/domain/generation/life_progression.dart';
import 'package:bir_omur/domain/life/inheritance.dart';
import 'package:bir_omur/domain/models/game_state.dart';
import 'package:bir_omur/domain/models/gender.dart';
import 'package:bir_omur/domain/models/owned_item.dart';
import 'package:bir_omur/domain/models/person.dart';
import 'package:bir_omur/domain/models/relation.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/generation_fixtures.dart';
import 'support/invariants.dart';

GameState devamEt(GameState state, String childId, [int seed = 3]) {
  final ({GameState? state, String blockReason}) sonuc =
      GenerationContinuation.continueAs(state, childId, Random(seed));
  expect(sonuc.blockReason, isEmpty);
  expect(sonuc.state, isNotNull);
  return sonuc.state!;
}

void main() {
  // ===================================================================
  // Seçeneğin görünürlüğü
  // ===================================================================
  group('devam seçeneği', () {
    test('hayat tamamlanmadıysa seçenek yok', () {
      final GameState state = olenOyuncu().copyWith(deceased: false);
      expect(GenerationContinuation.heirs(state), isEmpty);
      expect(GenerationContinuation.canContinue(state), isFalse);
      expect(
        GenerationContinuation.blockReason(state, 'cocuk-1'),
        isNotEmpty,
      );
    });

    test('hayatta çocuk yoksa seçenek yok', () {
      final GameState state = olenOyuncu(cocuklarHayatta: false);
      expect(GenerationContinuation.canContinue(state), isFalse);
      expect(
        GenerationContinuation.continueAs(state, 'cocuk-1', Random(1)).state,
        isNull,
      );
    });

    test('çocuk olmayan bir kişiyle devam edilemez', () {
      final GameState state = olenOyuncu();
      expect(GenerationContinuation.blockReason(state, 'kardes-1'), isNotEmpty);
      expect(GenerationContinuation.blockReason(state, 'yok-boyle'), isNotEmpty);
      final ({GameState? state, String blockReason}) sonuc =
          GenerationContinuation.continueAs(state, 'kardes-1', Random(1));
      expect(sonuc.state, isNull);
    });

    test('hayatta iki çocuk varsa ikisi de seçilebilir', () {
      final GameState state = olenOyuncu();
      expect(
        GenerationContinuation.heirs(state).map((Person p) => p.id),
        <String>['cocuk-1', 'cocuk-2'],
      );
    });
  });

  // ===================================================================
  // Kimlik ve bağlar
  // ===================================================================
  group('kimlik ve aile bağları', () {
    test('yeni oyuncu seçilen çocuğun kendisidir', () {
      final GameState eski = olenOyuncu();
      final GameState yeni = devamEt(eski, 'cocuk-1');

      expect(yeni.player.firstName, 'Elif');
      expect(yeni.player.gender, Gender.kadin);
      expect(yeni.player.age, 40);
      expect(yeni.generation, 2);
      expect(yeni.isContinuedGeneration, isTrue);
      expect(yeni.deceased, isFalse);
      // Çocuk artık NPC listesinde değil; ikinci bir kayıt oluşmadı.
      expect(yeni.personById('cocuk-1'), isNull);
      expect(checkInvariants(yeni, where: 'kuşak devamı'), isEmpty);
    });

    test('eski oyuncu vefat etmiş ebeveyn olarak kayıtta kalır', () {
      final GameState yeni = devamEt(olenOyuncu(), 'cocuk-1');
      final Person baba = yeni.people.firstWhere(
        (Person p) => p.relation == RelationType.baba,
      );
      expect(baba.firstName, 'Mehmet');
      expect(baba.isAlive, isFalse);
      expect(baba.age, 70);
      expect(baba.inPlayerHousehold, isFalse);
      // Mirası burada kapandı; bir daha dağıtılmaz.
      expect(yeni.settledEstates, contains(baba.id));
    });

    test('kadın oyuncunun çocuğu için eski oyuncu annedir', () {
      final GameState yeni =
          devamEt(olenOyuncu(oyuncuCinsiyeti: Gender.kadin), 'cocuk-2');
      final Person anne = yeni.people.firstWhere(
        (Person p) => p.relation == RelationType.anne && !p.isAlive,
      );
      expect(anne.firstName, 'Mehmet');
      // Oyuncunun annesi artık anneannedir.
      expect(
        yeni.personById('anne-1')!.relation,
        RelationType.anneanne,
      );
      // Oyuncunun kız kardeşi teyze olur.
      expect(yeni.personById('kardes-1')!.relation, RelationType.teyze);
    });

    test('eş anne/baba, diğer çocuk kardeş, büyükler yukarı kayar', () {
      final GameState yeni = devamEt(olenOyuncu(), 'cocuk-1');

      expect(yeni.personById('es-1')!.relation, RelationType.anne);
      expect(yeni.personById('es-1')!.isAlive, isTrue);
      expect(yeni.personById('cocuk-2')!.relation, RelationType.kardes);
      // Erkek oyuncunun annesi babaanne, kız kardeşi hala olur.
      expect(yeni.personById('anne-1')!.relation, RelationType.babaanne);
      expect(yeni.personById('kardes-1')!.relation, RelationType.hala);
      // Evlilik kaydı yeni kuşağa taşınmaz.
      expect(yeni.marriage, isNull);
      expect(yeni.isMarried, isFalse);
    });

    test('boşanılmış eş de çocuğun ebeveynidir ama mirasçı değildir', () {
      final GameState eski = olenOyuncu(bosanmis: true, wallet: 400000);
      final GameState yeni = devamEt(eski, 'cocuk-1');
      expect(yeni.personById('es-1')!.relation, RelationType.anne);
      // Eş payı ayrılmadı: nakit yalnızca iki çocuk arasında bölündü.
      expect(yeni.player.wallet, 200000);
    });

    test('eski oyuncunun arkadaşları yeni kuşağa taşınmaz', () {
      final GameState yeni = devamEt(olenOyuncu(), 'cocuk-1');
      expect(yeni.personById('arkadas-1'), isNull);
      // Kayıp değil: tamamlanan hayat arşivde durur (denetimi controller
      // testinde yapılır).
    });

    test('taşınan kişilerin yakınlığı nötre yaklaşır ama sıfırlanmaz', () {
      final GameState yeni = devamEt(olenOyuncu(), 'cocuk-1');
      final Person anne = yeni.personById('es-1')!;
      // 80 → (80 + 55) / 2
      expect(anne.bond, 68);
      expect(anne.bond, lessThan(80));
      expect(anne.bond, greaterThan(GenerationContinuation.prototypeOnlyNeutralBond - 1));
    });
  });

  // ===================================================================
  // Miras
  // ===================================================================
  group('miras', () {
    test('sağ kalan eş payını alır, kalanı çocuklara bölünür', () {
      final GameState eski = olenOyuncu(wallet: 400000);
      final GameState yeni = devamEt(eski, 'cocuk-1');
      final int esPayi =
          (400000 * Inheritance.prototypeOnlySpouseShare).round();
      expect(yeni.player.wallet, ((400000 - esPayi) / 2).floor());
    });

    test('eş hayatta değilse nakit çocuklara bölünür', () {
      final GameState eski = olenOyuncu(esHayatta: false, wallet: 300000);
      final GameState yeni = devamEt(eski, 'cocuk-1');
      expect(yeni.player.wallet, 150000);
    });

    test('borç miras kalmaz', () {
      final GameState eski = olenOyuncu(wallet: 0).copyWith(
        player: olenOyuncu().player.copyWith(wallet: -50000),
      );
      final GameState yeni = devamEt(eski, 'cocuk-1');
      expect(yeni.player.wallet, 0);
      expect(checkInvariants(yeni, where: 'borç'), isEmpty);
    });

    test('ev ve araç kalıcı varlık kimliğiyle geçer', () {
      final GameState eski = olenOyuncu(
        esHayatta: false,
        items: <OwnedItem>[
          esya('esya-1', 'kucuk_daire'),
          esya('esya-2', 'ikinci_el_otomobil'),
        ],
      );
      final GameState yeni = devamEt(eski, 'cocuk-1');

      // İki mirasçı (iki çocuk) var; eşyalar sırayla bölünür.
      expect(yeni.items.single.id, 'esya-1');
      expect(yeni.items.single.typeId, 'kucuk_daire');
      expect(yeni.items.single.source, ItemSource.miras);
      expect(yeni.items.single.purchasePrice, 100000);
      // Diğer eşya kaybolmadı: kardeşin mal varlığına yazıldı.
      expect(
        yeni.personById('cocuk-2')!.estate,
        contains('ikinci_el_otomobil'),
      );
    });

    test('miras ikinci kez dağıtılmaz', () {
      final GameState eski = olenOyuncu(
        esHayatta: false,
        items: <OwnedItem>[esya('esya-1', 'kucuk_daire')],
      );
      GameState yeni = devamEt(eski, 'cocuk-1');
      final int cuzdan = yeni.player.wallet;
      final int esyaSayisi = yeni.items.length;

      yeni = LifeProgression(Random(5)).advanceOneYear(
        yeni.copyWith(pendingEvent: null),
      );
      // Vefat etmiş ebeveynin mirası yıl ilerleyince yeniden dağıtılmaz.
      expect(yeni.items.length, esyaSayisi);
      expect(yeni.player.wallet, lessThanOrEqualTo(cuzdan));
    });

    test('devralınan evde oturulur, kirada olan ev oturulan ev sayılmaz', () {
      final GameState eski = olenOyuncu(
        esHayatta: false,
        items: <OwnedItem>[esya('esya-1', 'kucuk_daire', rentedOut: true)],
      );
      final GameState yeni = devamEt(eski, 'cocuk-1');
      expect(yeni.residenceItemId, isNull);
      expect(checkInvariants(yeni, where: 'kiradaki ev'), isEmpty);

      final GameState eski2 = olenOyuncu(
        esHayatta: false,
        items: <OwnedItem>[esya('esya-1', 'kucuk_daire')],
      );
      final GameState yeni2 = devamEt(eski2, 'cocuk-1');
      expect(yeni2.residenceItemId, 'esya-1');
      expect(yeni2.movedOut, isTrue);
      expect(checkInvariants(yeni2, where: 'devralınan ev'), isEmpty);
    });
  });

  // ===================================================================
  // Taşınmayanlar
  // ===================================================================
  group('taşınmayanlar', () {
    test('ün, meslek ve eğitim taşınmaz', () {
      final GameState yeni = devamEt(olenOyuncu(), 'cocuk-1');
      expect(yeni.player.fame, isNull);
      expect(yeni.career.isEmployed, isFalse);
      expect(yeni.career.pastJobIds, isEmpty);
      expect(yeni.licenses, isEmpty);
      expect(yeni.socialAccounts, isEmpty);
      expect(yeni.education.universityFinished, isFalse);
      // Yetişkin çocuk lise mezunu sayılır; okula geri dönmez.
      expect(yeni.education.enrolled, isFalse);
      expect(yeni.education.finished, isTrue);
    });

    test('okul çağındaki çocuk yaşına uygun sınıfta devam eder', () {
      final GameState eski = olenOyuncu(buyukCocukYasi: 10, olumYasi: 45);
      final GameState yeni = devamEt(eski, 'cocuk-1');
      expect(yeni.education.enrolled, isTrue);
      expect(yeni.education.grade, 5);
      expect(yeni.player.age, 10);
      expect(checkInvariants(yeni, where: 'okul çağı'), isEmpty);
    });

    test('okul öncesi çocukla devam edilirse okul başlamamış olur', () {
      final GameState eski = olenOyuncu(buyukCocukYasi: 3, olumYasi: 40);
      final GameState yeni = devamEt(eski, 'cocuk-1');
      expect(yeni.education.enrolled, isFalse);
      expect(yeni.education.finished, isFalse);
    });

    test('hikâye izleri ve olay geçmişi yeni kuşağa taşınmaz', () {
      final GameState eski = olenOyuncu().copyWith(
        storyFlags: <String>{'evlendi'},
        seenEventIds: <String>{'bayram_ziyareti'},
        lastEventAge: <String, int>{'bayram_ziyareti': 60},
        storyPeople: <String, String>{'ilkArkadas': 'arkadas-1'},
      );
      final GameState yeni = devamEt(eski, 'cocuk-1');
      expect(yeni.storyFlags, isEmpty);
      expect(yeni.seenEventIds, isEmpty);
      expect(yeni.lastEventAge, isEmpty);
      expect(yeni.storyPeople, isEmpty);
    });
  });

  // ===================================================================
  // Hane ve bakım
  // ===================================================================
  group('hane', () {
    test('küçük çocuk sağ kalan ebeveynin yanında kalır', () {
      final GameState eski = olenOyuncu(buyukCocukYasi: 8, olumYasi: 40);
      final GameState yeni = devamEt(eski, 'cocuk-1');
      final Person anne = yeni.personById('es-1')!;
      expect(anne.inPlayerHousehold, isTrue);
      expect(yeni.movedOut, isFalse);
      expect(checkInvariants(yeni, where: 'küçük çocuk'), isEmpty);
    });

    test('hanede yetişkin kalmayan küçük çocuk açıklamasız bırakılmaz', () {
      final GameState eski =
          olenOyuncu(buyukCocukYasi: 8, olumYasi: 40, esHayatta: false);
      final GameState yeni = devamEt(eski, 'cocuk-1');
      // Ya bir yakın yanına taşınır ya da kurum bakımı devreye girer;
      // hiçbir durumda boş hane bırakılmaz.
      expect(
        yeni.careStatus.name,
        anyOf('yakinAkraba', 'kurumBakimi'),
      );
      expect(yeni.log.length, greaterThan(1));
      expect(checkInvariants(yeni, where: 'bakım'), isEmpty);
    });
  });

  // ===================================================================
  // Devamlılık: yıllar ilerler
  // ===================================================================
  test('yeni kuşak normal şekilde yaşlanır ve tutarlı kalır', () {
    final Random rng = Random(99);
    GameState state = devamEt(olenOyuncu(buyukCocukYasi: 25, olumYasi: 55), 'cocuk-1');
    for (int i = 0; i < 12 && !state.deceased; i++) {
      state = LifeProgression(rng).advanceOneYear(state.copyWith(pendingEvent: null));
      expect(checkInvariants(state, where: '$i. yıl'), isEmpty);
      expect(state.generation, 2);
    }
  });

  // ===================================================================
  // Kayıt
  // ===================================================================
  group('kayıt', () {
    test('kuşak bilgisi kaydedilip geri okunur', () {
      final GameState yeni = devamEt(olenOyuncu(), 'cocuk-1');
      final GameState geri = decodeGameState(encodeGameState(yeni));
      expect(geri.generation, 2);
      expect(geri.player.firstName, 'Elif');
      expect(
        geri.people.map((Person p) => p.relation),
        contains(RelationType.baba),
      );
      expect(checkInvariants(geri, where: 'kayıttan dönüş'), isEmpty);
    });

    test('eski kayıtlar 1. kuşak sayılır', () {
      final Map<String, Object?> body =
          Map<String, Object?>.from(encodeGameState(olenOyuncu()));
      body.remove('generation');
      final GameState geri = decodeGameState(body);
      expect(geri.generation, 1);
      expect(geri.isContinuedGeneration, isFalse);
    });

    test('kayıt sürümü 26 ve göç zinciri kuşak alanını bozmaz', () {
      expect(kSaveFormatVersion, 26);
      final Map<String, Object?> body =
          Map<String, Object?>.from(encodeGameState(devamEt(olenOyuncu(), 'cocuk-1')));
      final Map<String, Object?> gocmus = SaveMigrations.migrate(body, 25);
      expect(decodeGameState(gocmus).generation, 2);
    });
  });
}

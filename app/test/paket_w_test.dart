/// Paket W: Faho'nun bildirdiği gerçek hatalar.
///
/// Her test bildirilen cümleyi sabitler; hiçbiri tahminle yazılmadı.
library;

import 'dart:math';

import 'package:bir_omur/data/activity_catalog.dart';
import 'package:bir_omur/data/item_catalog.dart';
import 'package:bir_omur/data/media_catalog.dart';
import 'package:bir_omur/data/save/game_state_codec.dart';
import 'package:bir_omur/data/finger_catalog.dart';
import 'package:bir_omur/data/pet_catalog.dart';
import 'package:bir_omur/domain/activities/activity_engine.dart';
import 'package:bir_omur/domain/generation/life_generator.dart';
import 'package:bir_omur/domain/economy/living_costs.dart';
import 'package:bir_omur/domain/interaction/finger.dart';
import 'package:bir_omur/domain/models/interaction.dart';
import 'package:bir_omur/domain/models/owned_item.dart';
import 'package:bir_omur/domain/social/media_opportunities.dart';
import 'package:bir_omur/domain/models/finger_profile.dart';
import 'package:bir_omur/domain/models/game_state.dart';
import 'package:bir_omur/domain/models/gender.dart';
import 'package:bir_omur/domain/models/pending_notice.dart';
import 'package:bir_omur/domain/models/person.dart';
import 'package:bir_omur/domain/models/wealth.dart';
import 'package:bir_omur/domain/pets/pet_care.dart';
import 'package:bir_omur/state/game_controller.dart';
import 'package:flutter_test/flutter_test.dart';

GameState hayat(int seed, {int age = 10, int wallet = 5000}) {
  final GameState s =
      LifeGenerator.seeded(seed).generate(mode: StartMode.tamamenRastgele);
  return s.copyWith(
    player: s.player.copyWith(age: age, wallet: wallet),
    pendingEvent: null,
  );
}

void main() {
  _paketW2();
  // ===================================================================
  // Sahiplenmediğin hayvanın bakımı senden çıkmaz (D-144)
  // ===================================================================
  group('Evcil hayvan bakım gideri (D-144)', () {
    final PetSpecies kedi = petSpeciesById('kedi')!;

    Pet aileHayvani() => const Pet(
          id: 'pet-aile',
          name: 'Tekir',
          species: 'kedi',
          age: 3,
          // Oyuncu doğduğunda evdeydi: sahiplenme yaşı YOK.
          adoptedAtPlayerAge: null,
          inPlayerHousehold: true,
          bond: 60,
        );

    Pet benimHayvanim(int sahiplenmeYasi) => Pet(
          id: 'pet-benim',
          name: 'Duman',
          species: 'kedi',
          age: 1,
          adoptedAtPlayerAge: sahiplenmeYasi,
          inPlayerHousehold: true,
          bond: 60,
        );

    test('doğduğunda evde olan hayvanın bakımı harçlıktan çıkmaz', () {
      // Faho: "4-5-6 yaşlarında aileden harçlık alıyorum, sene geçtiğinde
      // harçlığım evde zaten ben doğduğumda var olan hayvanın bakımına
      // gidiyor."
      final GameState s = hayat(1, age: 5, wallet: 5000).copyWith(
        pets: List<Pet>.unmodifiable(<Pet>[aileHayvani()]),
      );
      final GameState sonra = PetCare.advanceYear(s, 6, Random(1));
      expect(sonra.player.wallet, s.player.wallet);
      // Hayvan yine de yaşlanır: kayıt donmuyor.
      expect(sonra.pets.single.age, 4);
    });

    test('kendi sahiplendiğin hayvanın bakımı senden çıkar', () {
      final GameState s = hayat(2, age: 20, wallet: 500000).copyWith(
        pets: List<Pet>.unmodifiable(<Pet>[benimHayvanim(19)]),
      );
      final GameState sonra = PetCare.advanceYear(s, 21, Random(2));
      expect(
        sonra.player.wallet,
        s.player.wallet - kedi.yearlyCareCost,
      );
    });

    test('iki hayvan varken yalnızca sahiplenilen ücretlendirilir', () {
      final GameState s = hayat(3, age: 20, wallet: 500000).copyWith(
        pets: List<Pet>.unmodifiable(<Pet>[aileHayvani(), benimHayvanim(19)]),
      );
      final GameState sonra = PetCare.advanceYear(s, 21, Random(3));
      expect(
        sonra.player.wallet,
        s.player.wallet - kedi.yearlyCareCost,
        reason: 'Yalnızca bir hayvanın bakımı alınmalı',
      );
    });

    test('ücretsiz hayvan için "bakıma para gitti" satırı yazılmaz', () {
      final GameState s = hayat(4, age: 5, wallet: 5000).copyWith(
        pets: List<Pet>.unmodifiable(<Pet>[aileHayvani()]),
      );
      final GameState sonra = PetCare.advanceYear(s, 6, Random(4));
      expect(
        sonra.log.where((dynamic e) =>
            (e.text as String).contains('Hayvan bakımına')),
        isEmpty,
      );
    });
  });

  // ===================================================================
  // Kitap: sayfa başına pop-up yok (D-145)
  // ===================================================================
  group('Kitap okuma bildirimi (D-145)', () {
    test('ara sayfalarda bildirim kuyruğa girmez, bitince girer', () {
      // Faho: "her kitap okumada neden bildirim atıyor! her sayfada
      // bildirim var saçmalık!!! kitabı okumam bittiğinde gelmeli."
      final GameController c = GameController(random: Random(11));
      addTearDown(c.dispose);

      // 20 yaşına uygun ve en kısa kitap: test sayfa sayısına bağlı
      // kalmasın diye katalogdan seçiliyor.
      final BookInfo kitap = kBookCatalog
          .where((BookInfo b) => b.fitsAge(20))
          .reduce((BookInfo a, BookInfo b) => a.pages <= b.pages ? a : b);
      c.debugSetState(
        hayat(5, age: 20, wallet: 100000).copyWith(
          notices: const <PendingNotice>[],
        ),
      );
      c.openBook(kitap);
      // Kitabı açmanın bildirimi işimizi bozmasın.
      c.debugSetState(
        c.state!.copyWith(notices: const <PendingNotice>[]),
      );

      // D-125 ile anlamlı eylemler ek olay açabiliyor; olay beklerken
      // sayfa çevrilemez, bu yüzden her turda kuyruk temizleniyor.
      void olayiTemizle() {
        if (c.state!.hasPendingEvent) {
          c.debugSetState(c.state!.copyWith(pendingEvent: null));
        }
      }

      int tur = 0;
      while (!(c.state!.bookProgress(kitap.id)?.finished ?? false)) {
        olayiTemizle();
        c.turnBookPage(kitap);
        tur++;
        if (c.state!.bookProgress(kitap.id)!.finished) break;
        expect(
          c.state!.notices,
          isEmpty,
          reason: '$tur. sayfada bildirim çıkmamalı',
        );
        if (tur > kitap.pages + 5) fail('Kitap bitmedi: $tur tur');
      }
      expect(c.state!.bookProgress(kitap.id)!.finished, isTrue);
      expect(c.state!.notices.length, 1);
      expect(c.state!.notices.single.title, 'Kitap bitti');
      // Kazanç bildirimde görünür.
      expect(c.state!.notices.single.effects, isNotEmpty);
    });

    test('sayfa çevirmek durumu yine de ilerletir', () {
      const ActivityEngine motor = ActivityEngine();
      final BookInfo kitap =
          kBookCatalog.firstWhere((BookInfo b) => b.fitsAge(20));
      GameState s = motor.openBook(hayat(6, age: 20), kitap).state;
      s = motor.turnPage(s, kitap).state;
      expect(s.bookProgress(kitap.id)!.pagesRead, 1);
    });
  });

  // ===================================================================
  // Finger: tanışılan kişinin ekonomik hâli korunur
  // ===================================================================
  group('Finger ekonomik hâl', () {
    test('çok varlıklı profil kişi kaydında da çok varlıklı kalır', () {
      // Faho: "Finger'de çok varlıklı olarak tanıştığım kişi arkadaşım
      // olduğu an orta halli görünüyor."
            final GameState temel = hayat(7, age: 25, wallet: 200000);
      final FingerProfile profil = FingerProfile(
        id: 'p-zengin',
        firstName: 'Neslihan',
        lastName: 'Aksoy',
        gender: Gender.kadin,
        age: 27,
        city: temel.player.currentCity,
        bio: 'Şehirde büyümüş, sessiz tarafta duruyor.',
        interests: const <String>['mimari', 'yürüyüş'],
        occupation: 'mimar',
        wealth: WealthTier.cokVarlikli,
        intent: FingerIntent.arkadaslik,
      );
      final GameState s = temel.copyWith(
        fingerMatches: List<FingerProfile>.unmodifiable(
          <FingerProfile>[profil],
        ),
      );

      final GameState sonra =
          Finger.meet(s, profil.id, Random(1)).state;
      final Person kisi = sonra.people.last;
      expect(kisi.firstName, 'Neslihan');
      expect(
        kisi.wealth,
        WealthTier.cokVarlikli,
        reason: 'İlanda okunan hâl kişi kaydına geçmeli',
      );
    });

    test('18 yaşından küçük profilde kendi serveti yazılmaz', () {
            final GameState temel = hayat(8, age: 16, wallet: 2000);
      final FingerProfile profil = FingerProfile(
        id: 'p-genc',
        firstName: 'Deniz',
        lastName: 'Kaya',
        gender: Gender.erkek,
        age: 16,
        city: temel.player.currentCity,
        bio: 'Lise son. Müzik ve basketbol.',
        interests: const <String>['müzik'],
        occupation: null,
        wealth: WealthTier.varlikli,
        intent: FingerIntent.arkadaslik,
      );
      final GameState s = temel.copyWith(
        fingerMatches: List<FingerProfile>.unmodifiable(
          <FingerProfile>[profil],
        ),
      );
      final GameState sonra =
          Finger.meet(s, profil.id, Random(2)).state;
      expect(sonra.people.last.wealth, isNull);
    });
  });
}

// =====================================================================
// D-147: medya fırsatları spam olmaktan çıktı
// D-148: araç sigorta/kasko/vergi gideri
// =====================================================================
void _paketW2() {
  group('Medya fırsatları (D-147)', () {
    GameState unlu({int fame = 60, int age = 30}) {
      final GameState s = hayat(20, age: age, wallet: 100000);
      return s.copyWith(
        player: s.player.copyWith(fame: fame),
      );
    }

    test('yılda en çok iki medya işine girişilebilir', () {
      // Faho: "medya fırsatları sürekli açık olması, oradan da çok kolay
      // para spamlanabiliyor." Sekiz işin sekizi de aynı yıl
      // yapılabiliyordu.
      GameState s = unlu();
      int girisim = 0;
      for (final MediaOpportunity is_ in kMediaOpportunities) {
        if (!MediaOpportunities.availability(s, is_).isAllowed) continue;
        s = MediaOpportunities.accept(s, is_, Random(girisim)).state;
        girisim++;
      }
      expect(girisim, MediaOpportunities.prototypeOnlyMaxJobsPerAge);
      expect(MediaOpportunities.jobsThisAge(s),
          MediaOpportunities.prototypeOnlyMaxJobsPerAge);
      for (final MediaOpportunity is_ in kMediaOpportunities) {
        expect(
          MediaOpportunities.availability(s, is_).isAllowed,
          isFalse,
          reason: is_.label,
        );
      }
    });

    test('reddedilen başvuru da yıllık hakkı tüketir', () {
      GameState s = unlu(fame: kMediaSectionMinFame);
      final MediaOpportunity is_ = kMediaOpportunities.reduce(
        (MediaOpportunity a, MediaOpportunity b) =>
            a.minFame <= b.minFame ? a : b,
      );
      // Kabul edilse de edilmese de sayaç artar.
      s = MediaOpportunities.accept(s, is_, Random(0)).state;
      expect(MediaOpportunities.jobsThisAge(s), 1);
    });

    test('aynı iş üç yıl boyunca tekrar yapılamaz', () {
      // Faho: "bir fenomen her sene radyo programına vb işlere
      // çağırılıyor mu gibi düşün."
      GameState s = unlu(fame: 90);
      final MediaOpportunity is_ = kMediaOpportunities
          .firstWhere((MediaOpportunity j) => j.minFame <= 90);
      // Kabul edilene kadar dene (tohum değiştirerek).
      for (int t = 0; t < 30; t++) {
        final GameState deneme =
            MediaOpportunities.accept(unlu(fame: 90), is_, Random(t)).state;
        if (deneme.mediaJobDoneAt(is_.id) != null) {
          s = deneme;
          break;
        }
      }
      expect(s.mediaJobDoneAt(is_.id), isNotNull, reason: 'Hiç kabul çıkmadı');

      final int yapilanYas = s.mediaJobDoneAt(is_.id)!;
      for (int fark = 1;
          fark < MediaOpportunities.prototypeOnlyJobCooldownYears;
          fark++) {
        final GameState ileri = s.copyWith(
          player: s.player.copyWith(age: yapilanYas + fark),
          interactionCounts: const <String, int>{},
        );
        final InteractionAvailability u =
            MediaOpportunities.availability(ileri, is_);
        expect(u.isAllowed, isFalse, reason: '$fark yıl sonra hâlâ kapalı');
        expect(u.reason, contains('Aynı kapı her yıl çalınmaz'));
      }
      // Süre dolunca yeniden açılır.
      final GameState sonra = s.copyWith(
        player: s.player.copyWith(
          age: yapilanYas + MediaOpportunities.prototypeOnlyJobCooldownYears,
        ),
        interactionCounts: const <String, int>{},
      );
      expect(MediaOpportunities.availability(sonra, is_).isAllowed, isTrue);
    });

    test('kabul şansı hiçbir zaman garanti değil', () {
      final GameState s = unlu(fame: 100);
      for (final MediaOpportunity is_ in kMediaOpportunities) {
        expect(
          MediaOpportunities.acceptChance(s, is_),
          lessThanOrEqualTo(MediaOpportunities.prototypeOnlyMaxAcceptChance),
          reason: is_.label,
        );
      }
    });

    test('yeni alanlar kayda girer; eski kayıtta boş açılır', () {
      GameState s = unlu();
      s = s.copyWith(
        mediaJobLastAge: <String, int>{'radyo_programi': 29},
      );
      final GameState geri = decodeGameState(encodeGameState(s));
      expect(geri.mediaJobDoneAt('radyo_programi'), 29);

      final Map<String, Object?> json = encodeGameState(unlu())
        ..remove('mediaJobLastAge');
      expect(decodeGameState(json).mediaJobLastAge, isEmpty);
    });
  });

  group('Araç gideri: sigorta, kasko, vergi (D-148)', () {
    GameState aracli(String typeId, {int yas = 30, int alindigiYas = 30}) {
      final GameState s = hayat(21, age: alindigiYas, wallet: 50000000);
      final GameState sahip = s.grantItems(
        <String>[typeId],
        source: ItemSource.satinAlma,
        purchasePrice: itemTypeOrFallback(typeId).baseValue,
      );
      return sahip.copyWith(player: sahip.player.copyWith(age: yas));
    }

    test('aracı olmayanda araç gideri yok', () {
      final GameState s = hayat(22, age: 30);
      expect(LivingCosts.vehicleItems(s), isEmpty);
    });

    test('araç alınca her yıl sigorta, kasko ve vergi çıkar', () {
      // Faho: "araç satın aldığımda kasko ve sigorta masrafı da çıksın,
      // her yıl vergisi de çıksın."
      final GameState s = aracli('otomobil_ekonomik');
      final List<({String label, int amount})> kalemler =
          LivingCosts.vehicleItems(s);
      expect(kalemler, hasLength(1));
      expect(kalemler.single.amount, greaterThan(0));
      expect(kalemler.single.label, contains('sigorta, kasko ve vergi'));
      // Gider yıllık dökümde de görünür (D-123).
      expect(
        LivingCosts.breakdownFor(s)
            .items
            .any((({String label, int amount}) k) =>
                k.label.contains('sigorta, kasko ve vergi')),
        isTrue,
      );
    });

    test('pahalı araç daha çok gider çıkarır', () {
      final int ucuz = LivingCosts.vehicleItems(aracli('otomobil_ekonomik'))
          .single
          .amount;
      final int pahali =
          LivingCosts.vehicleItems(aracli('otomobil_prestij')).single.amount;
      expect(pahali, greaterThan(ucuz));
    });

    test('araç yaşlandıkça vergi payı düşer ama gider sıfırlanmaz', () {
      final int yeni = LivingCosts.vehicleItems(
        aracli('otomobil_orta', yas: 30, alindigiYas: 30),
      ).single.amount;
      final int eski = LivingCosts.vehicleItems(
        aracli('otomobil_orta', yas: 45, alindigiYas: 30),
      ).single.amount;
      expect(eski, lessThan(yeni));
      expect(eski, greaterThan(0));
    });

    test('bisiklet gider çıkarmaz', () {
      expect(LivingCosts.vehicleItems(aracli('bisiklet')), isEmpty);
    });

    test('iki araç iki ayrı satır olur', () {
      GameState s = aracli('otomobil_ekonomik');
      s = s.grantItems(
        <String>['motosiklet_ekonomik'],
        source: ItemSource.satinAlma,
      );
      expect(LivingCosts.vehicleItems(s), hasLength(2));
    });
  });
}

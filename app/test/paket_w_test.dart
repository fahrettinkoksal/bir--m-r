/// Paket W: Faho'nun bildirdiği gerçek hatalar.
///
/// Her test bildirilen cümleyi sabitler; hiçbiri tahminle yazılmadı.
library;

import 'dart:math';

import 'package:bir_omur/data/activity_catalog.dart';
import 'package:bir_omur/data/finger_catalog.dart';
import 'package:bir_omur/data/pet_catalog.dart';
import 'package:bir_omur/domain/activities/activity_engine.dart';
import 'package:bir_omur/domain/generation/life_generator.dart';
import 'package:bir_omur/domain/interaction/finger.dart';
import 'package:bir_omur/domain/models/book_progress.dart';
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

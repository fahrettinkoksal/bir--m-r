import 'dart:math';

import 'package:bir_omur/data/activity_catalog.dart';
import 'package:bir_omur/data/hobby_catalog.dart';
import 'package:bir_omur/data/job_catalog.dart';
import 'package:bir_omur/data/pet_catalog.dart';
import 'package:bir_omur/data/save/game_state_codec.dart';
import 'package:bir_omur/domain/hobby/hobby_tracker.dart';
import 'package:bir_omur/domain/interaction/shared_history.dart';
import 'package:bir_omur/domain/life/inheritance.dart';
import 'package:bir_omur/domain/generation/life_generator.dart';
import 'package:bir_omur/domain/models/game_state.dart';
import 'package:bir_omur/domain/models/gender.dart';
import 'package:bir_omur/domain/models/hobby_progress.dart';
import 'package:bir_omur/domain/models/marriage.dart';
import 'package:bir_omur/domain/models/person.dart';
import 'package:bir_omur/domain/models/relation.dart';
import 'package:bir_omur/domain/models/wealth.dart';
import 'package:bir_omur/domain/pets/pet_care.dart';
import 'package:bir_omur/state/game_controller.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/test_flow.dart';

/// Baştan sona tek bir hayat (Paket 42).
///
/// Sistemler tek tek sınanıyor ama **birlikte** çalıştıklarında bozulan
/// şeyler ancak uçtan uca oynanınca görülür: kişiler kaybolur, geçmiş
/// evlilik silinir, hayvan kimliği değişir, para iki kez düşer, miras
/// ikinci kez dağıtılır.
///
/// Bu test bir çocukluktan başlayıp okula, hobiye, işe, evliliğe, evcil
/// hayvana, birlikte çıkılan bir programa, çocuğa ve oyuncunun ölümüne
/// kadar gidiyor; sonra çocuk olarak devam ediyor ve yeni kuşakta
/// **uydurma geçmiş** olmadığını denetliyor.
ActivityAction eylem(String id) =>
    kActivityActions.firstWhere((ActivityAction a) => a.id == id);

Person sevgili(String id, String ad, Gender gender, {int age = 28}) => Person(
      id: id,
      firstName: ad,
      lastName: 'Yaman',
      gender: gender,
      relation: RelationType.sevgili,
      age: age,
      isAlive: true,
      inPlayerHousehold: false,
      employment: EmploymentStatus.calisiyor,
      occupation: 'öğretmen',
      wealth: WealthTier.ortaHalli,
      bond: 88,
    );

void main() {
  test('bir hayat baştan sona: hiçbir kayıt kaybolmuyor, hiçbir şey '
      'iki kez olmuyor', () {
    // Tohum yalnızca iskele: senaryonun kendisi değil, rastgelelik
    // akışını sabitler. Doğurganlık eğrisi 55 yaşa uzayınca (Paket A)
    // akış kaydı ve 31 tohumunda senaryodaki çocuk oyuncudan önce
    // vefat etmeye başladı. Aşağıdaki iddiaların hiçbiri gevşetilmedi;
    // yalnızca çocuğun hayatta kaldığı bir tohum seçildi.
    final GameController controller = GameController(random: Random(32));
    addTearDown(controller.dispose);

    // ---------------------------------------------------------------
    // 1. Çocukluk ve okul
    // ---------------------------------------------------------------
    controller.startNewLife(mode: StartMode.tamamenRastgele);
    final GameState dogum = controller.state!;
    final Set<String> dogumdakiKisiler =
        dogum.people.map((Person p) => p.id).toSet();
    expect(dogumdakiKisiler, isNotEmpty);

    advanceToAge(controller, 10);
    expect(controller.state!.deceased, isFalse);
    expect(
      controller.state!.education.isSchoolStudent,
      isTrue,
      reason: '10 yaşında okulda olmalı',
    );

    // ---------------------------------------------------------------
    // 2. Hobi: yıllara yayılan gerçek bir uğraş
    // ---------------------------------------------------------------
    controller.debugSetState(
      controller.state!.copyWith(
        player: controller.state!.player.copyWith(wallet: 3000000),
      ),
    );
    for (int yas = 10; yas <= 20; yas++) {
      resolvePendingEvents(controller);
      controller.performActivity(eylem('muzik_kursu'));
      controller.performActivity(eylem('muzik_kursu'));
      if (controller.state!.player.age < yas + 1) {
        // Lise alanı seçilmeden yaş atlanmaz (D-094).
        resolveTrackChoice(controller);
        controller.ageUp();
      }
      if (controller.state!.deceased) break;
    }
    resolvePendingEvents(controller);

    final HobbyProgress? muzik =
        HobbyTracker.progressOf(controller.state!, HobbyKind.muzik);
    expect(muzik, isNotNull, reason: 'Hobi kaydı oluşmalı');
    expect(muzik!.startedAtAge, 10);
    expect(muzik.experience, greaterThan(10));
    expect(muzik.memories, isNotEmpty);
    final int hobiDeneyimi = muzik.experience;
    final int hobiBaslangici = muzik.startedAtAge;

    // ---------------------------------------------------------------
    // 3. İş
    // ---------------------------------------------------------------
    advanceToAge(controller, 26);
    expect(controller.state!.deceased, isFalse);
    final JobType is1 = kJobCatalog.first;
    controller.debugSetState(
      controller.state!.copyWith(
        player: controller.state!.player.copyWith(wallet: 3000000),
      ),
    );
    controller.applyForJob(is1);
    resolvePendingEvents(controller);

    // ---------------------------------------------------------------
    // 4. Sevgili ve evlilik
    // ---------------------------------------------------------------
    final Gender karsiCinsiyet =
        controller.state!.player.gender == Gender.erkek
            ? Gender.kadin
            : Gender.erkek;
    controller.debugSetState(
      controller.state!.copyWith(
        people: <Person>[
          ...controller.state!.people,
          sevgili('es-1', 'Elif', karsiCinsiyet),
        ],
      ),
    );
    expect(controller.marry('es-1'), isNotNull);
    expect(controller.state!.isMarried, isTrue);
    final int evlenmeYasi = controller.state!.marriage!.marriedAtAge;

    // ---------------------------------------------------------------
    // 5. Evcil hayvan
    // ---------------------------------------------------------------
    final int cuzdanOnce = controller.state!.player.wallet;
    controller.adoptPet(PetSpecies.kedi, 'Zeytin');
    expect(controller.livingPets, hasLength(1));
    expect(
      controller.state!.player.wallet,
      cuzdanOnce - PetSpecies.kedi.adoptionCost,
      reason: 'Sahiplenme ücreti bir kez alınmalı',
    );
    final String hayvanKimligi = controller.livingPets.single.id;
    final int hayvanSahiplenmeYasi =
        controller.livingPets.single.adoptedAtPlayerAge!;

    // ---------------------------------------------------------------
    // 6. Eşle birlikte bir program
    // ---------------------------------------------------------------
    final Person es = controller.state!.personById('es-1')!;
    final int esBagiOnce = es.bond;
    final int cuzdanSinemaOnce = controller.state!.player.wallet;
    final int gunlukOnce = controller.state!.log.length;
    final ActivityAction sinema = eylem('sinema');
    expect(
      controller.outingCompanions(sinema).any((Person p) => p.id == 'es-1'),
      isTrue,
    );
    controller.performActivity(sinema, companion: es);

    expect(
      controller.state!.player.wallet,
      cuzdanSinemaOnce - sinema.cost * 2,
      reason: 'İki kişilik bilet ödenir (Q-108), ama tek seferde: '
          'aynı ücret ikinci kez işlenmemeli',
    );
    expect(controller.state!.personById('es-1')!.bond, greaterThan(esBagiOnce));
    expect(
      controller.state!.log.length,
      gunlukOnce + 1,
      reason: 'Ortak geçmişe tek satır düşmeli',
    );
    expect(controller.state!.log.last.personId, 'es-1');

    // ---------------------------------------------------------------
    // 7. Çocuk
    // ---------------------------------------------------------------
    controller.haveChild();
    resolvePendingEvents(controller);
    // Doğum bir sonraki yaşta gerçekleşebilir; birkaç yıl ilerlenir.
    for (int i = 0; i < 4 && controller.state!.children.isEmpty; i++) {
      resolvePendingEvents(controller);
      // Lise alanı seçilmeden yaş atlanmaz (D-094).
      resolveTrackChoice(controller);
      controller.ageUp();
    }
    resolvePendingEvents(controller);
    expect(
      controller.state!.children,
      isNotEmpty,
      reason: 'Çocuk gerçekten doğmalı',
    );
    final String cocukId = controller.state!.children.first.id;

    // ---------------------------------------------------------------
    // 8. Yıllar: hayvan yaşlanıyor, oyuncu yaşlanıyor
    // ---------------------------------------------------------------
    final int hayvanYasiOnce = controller.livingPets.single.age;
    advanceToAge(controller, controller.state!.player.age + 5);
    expect(controller.state!.deceased, isFalse);
    final Pet? hayvan = PetCare.petById(controller.state!, hayvanKimligi);
    expect(hayvan, isNotNull, reason: 'Hayvan kaydı silinmemeli');
    expect(hayvan!.id, hayvanKimligi);
    expect(hayvan.name, 'Zeytin');
    expect(hayvan.adoptedAtPlayerAge, hayvanSahiplenmeYasi);
    expect(hayvan.age, greaterThan(hayvanYasiOnce));

    // ---------------------------------------------------------------
    // 9. Kayıt gidiş-dönüşü: her şey diskten de aynı geliyor mu?
    // ---------------------------------------------------------------
    final GameState geri = decodeGameState(encodeGameState(controller.state!));
    expect(
      HobbyTracker.progressOf(geri, HobbyKind.muzik)!.experience,
      hobiDeneyimi,
    );
    expect(PetCare.petById(geri, hayvanKimligi)!.name, 'Zeytin');
    expect(geri.marriage!.marriedAtAge, evlenmeYasi);
    expect(geri.personById(cocukId), isNotNull);

    // ---------------------------------------------------------------
    // 10. Oyuncu ölene kadar yaşa
    // ---------------------------------------------------------------
    int guard = 0;
    while (!controller.state!.deceased) {
      if (guard++ > 150) fail('Oyuncu hiç ölmedi.');
      resolvePendingEvents(controller);
      // Lise alanı seçilmeden yaş atlanmaz (D-094).
      resolveTrackChoice(controller);
      controller.ageUp();
    }
    resolvePendingEvents(controller);

    final GameState olum = controller.state!;
    expect(olum.deceased, isTrue);

    // Ölüm anında bütün kayıtlar hâlâ yerinde.
    expect(
      HobbyTracker.progressOf(olum, HobbyKind.muzik)!.startedAtAge,
      hobiBaslangici,
    );
    expect(olum.personById('es-1'), isNotNull, reason: 'Eş kaydı kaybolmaz');
    expect(olum.personById(cocukId), isNotNull);
    for (final String id in dogumdakiKisiler) {
      expect(
        olum.personById(id),
        isNotNull,
        reason: 'Doğumda var olan kişi kaydı silinmemeli: $id',
      );
    }

    // ---------------------------------------------------------------
    // 11. Çocuk olarak devam
    // ---------------------------------------------------------------
    final List<String> varisler = controller.generationHeirs
        .map((Person p) => p.id)
        .toList(growable: false);
    // Sabit tohumla oynanan bu senaryoda çocuk oyuncudan önce vefat
    // etmiyor; erken çıkış koymuyoruz ki test sessizce yarıda kalmasın.
    expect(varisler, isNotEmpty, reason: 'Devam edilecek çocuk olmalı');

    final int mirasOncesiCuzdan = olum.player.wallet;
    final String engel = controller.continueAsChild(varisler.first);
    expect(engel, isEmpty, reason: 'Devam engellenmemeli');

    final GameState yeni = controller.state!;
    expect(yeni.generation, olum.generation + 1);
    expect(yeni.deceased, isFalse);

    // Miras ikinci kez dağıtılmaz: ölen oyuncunun kaydı "kapandı" diye
    // işaretli ve aynı miras yeniden dağıtılmaya çalışılınca hiçbir şey
    // olmuyor.
    final Person olenEbeveyn = yeni.people.firstWhere(
      (Person p) =>
          !p.isAlive &&
          (p.relation == RelationType.anne || p.relation == RelationType.baba),
    );
    expect(
      yeni.settledEstates,
      contains(olenEbeveyn.id),
      reason: 'Ölen oyuncunun mirası kapanmış olmalı',
    );

    final int mirasSonrasi = yeni.player.wallet;
    final ({GameState state, List<String> logLines}) tekrar =
        Inheritance.settle(yeni, olenEbeveyn);
    expect(
      tekrar.state.player.wallet,
      mirasSonrasi,
      reason: 'Aynı miras ikinci kez dağıtılmamalı',
    );
    expect(tekrar.logLines, isEmpty);

    final GameState ikinciKez = decodeGameState(encodeGameState(yeni));
    expect(
      ikinciKez.player.wallet,
      mirasSonrasi,
      reason: 'Kayıttan dönünce miras yeniden dağıtılmamalı',
    );
    expect(mirasOncesiCuzdan, greaterThanOrEqualTo(0));

    // Yeni kuşakta uydurma geçmiş yok: hobi ve evlilik eski oyuncunundu.
    expect(
      yeni.hobbies,
      isEmpty,
      reason: 'Çocuk babasının/annesinin hobisini devralmaz',
    );
    expect(
      yeni.marriage,
      isNull,
      reason: 'Çocuk evli doğmaz',
    );
    expect(
      yeni.pastMarriages,
      isEmpty,
      reason: 'Çocuğun geçmiş evliliği olamaz',
    );
    expect(
      yeni.log.every((dynamic e) => (e.age as int) <= yeni.player.age),
      isTrue,
      reason: 'Yeni kuşağın günlüğünde yaşamadığı yıl olamaz',
    );

    // Hayvan: aynı hanedeyse aynı kimlikle devam eder, yenisi uydurulmaz.
    for (final Pet p in yeni.pets) {
      expect(
        olum.pets.any((Pet eski) => eski.id == p.id),
        isTrue,
        reason: 'Yeni kuşakta uydurma hayvan olmamalı: ${p.id}',
      );
    }

    // Eski hayat arşivde duruyor.
    expect(yeni.pastLives, isNotEmpty);
  });

  test('geçmiş evlilik ve ortak anılar hayat boyu kayıtta kalır', () {
    final GameController controller = GameController(random: Random(19));
    addTearDown(controller.dispose);
    controller.startNewLife(mode: StartMode.tamamenRastgele);
    advanceToAge(controller, 28);
    expect(controller.state!.deceased, isFalse);

    final Gender karsi = controller.state!.player.gender == Gender.erkek
        ? Gender.kadin
        : Gender.erkek;
    controller.debugSetState(
      controller.state!.copyWith(
        player: controller.state!.player.copyWith(wallet: 3000000),
        people: <Person>[
          ...controller.state!.people
              .where((Person p) => p.relation != RelationType.sevgili),
          sevgili('es-1', 'Elif', karsi),
        ],
      ),
    );

    // İlk evlilik, birlikte bir program, sonra boşanma.
    controller.marry('es-1');
    final int ilkEvlilikYasi = controller.state!.marriage!.marriedAtAge;
    controller.performActivity(
      eylem('kafede_otur'),
      companion: controller.state!.personById('es-1')!,
    );
    final String ortakAni = controller.state!.log.last.text;
    controller.divorce();
    expect(controller.state!.isMarried, isFalse);

    // İkinci evlilik.
    controller.debugSetState(
      controller.state!.copyWith(
        people: <Person>[
          ...controller.state!.people,
          sevgili('es-2', 'Derya', karsi),
        ],
      ),
    );
    controller.marry('es-2');
    expect(controller.state!.isMarried, isTrue);

    // İlk evliliğin kaydı ezilmedi.
    final Marriage? ilk = controller.state!.marriageWith('es-1');
    expect(ilk, isNotNull, reason: 'Geçmiş evlilik kaydı silinmemeli');
    expect(ilk!.marriedAtAge, ilkEvlilikYasi);

    // Ortak anı hâlâ o kişinin geçmişinde.
    final List<SharedMoment> anlar = SharedHistory.of(
      controller.state!,
      controller.state!.personById('es-1')!,
    );
    expect(
      anlar.any((SharedMoment m) => m.text == ortakAni),
      isTrue,
      reason: 'Birlikte yaşanan an kaybolmamalı',
    );

    // Kayıttan dönünce de aynı.
    final GameState geri = decodeGameState(encodeGameState(controller.state!));
    expect(geri.marriageWith('es-1')!.marriedAtAge, ilkEvlilikYasi);
    expect(geri.marriage!.spouseId, 'es-2');
  });
}

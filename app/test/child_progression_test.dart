import 'dart:math';

import 'package:bir_omur/data/job_catalog.dart';
import 'package:bir_omur/data/save/game_state_codec.dart';
import 'package:bir_omur/domain/generation/child_progression.dart';
import 'package:bir_omur/domain/generation/generation_continuation.dart';
import 'package:bir_omur/domain/generation/life_progression.dart';
import 'package:bir_omur/domain/interaction/parenthood.dart';
import 'package:bir_omur/domain/life/inheritance.dart';
import 'package:bir_omur/domain/models/education.dart';
import 'package:bir_omur/domain/models/game_state.dart';
import 'package:bir_omur/domain/models/gender.dart';
import 'package:bir_omur/domain/models/life_log.dart';
import 'package:bir_omur/domain/models/person.dart';
import 'package:bir_omur/domain/models/person_development.dart';
import 'package:bir_omur/domain/models/relation.dart';
import 'package:bir_omur/domain/models/stats.dart';
import 'package:bir_omur/domain/models/wealth.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/generation_fixtures.dart';
import 'support/invariants.dart';

const Parenthood ebeveynlik = Parenthood();

/// Belirli özelliklerle bir çocuk kaydı kurar.
Person cocukKisi({
  String id = 'cocuk-1',
  int age = 0,
  int intelligence = 60,
  int charisma = 60,
  PersonDevelopment? development,
}) =>
    kisi(
      id: id,
      relation: RelationType.cocuk,
      gender: Gender.kadin,
      age: age,
      firstName: 'Elif',
    ).copyWith(
      development: development ??
          PersonDevelopment(
            tracksLife: true,
            stats: Stats(
              appearance: 55,
              happiness: 60,
              health: 70,
              intelligence: intelligence,
              charisma: charisma,
            ),
          ),
    );

/// Çocuğu [yil] yıl ilerletir (yalnızca gelişim sistemi).
({Person person, List<String> news}) ilerlet(
  Person cocuk,
  int yil,
  Random rng,
) {
  Person p = cocuk;
  final List<String> haberler = <String>[];
  for (int i = 0; i < yil; i++) {
    p = p.copyWith(age: p.age + 1);
    final ({Person person, List<String> news}) r =
        ChildProgression.advance(p, rng);
    p = r.person;
    haberler.addAll(r.news);
  }
  return (person: p, news: haberler);
}

void main() {
  // ===================================================================
  // Doğum ve kayıt
  // ===================================================================
  group('Kendi hayat kaydı', () {
    test('yeni doğan çocuğun kendi kaydı ve doğum anı vardır', () {
      final GameState state = olenOyuncu(cocuklarHayatta: true).copyWith(
        deceased: false,
        player: olenOyuncu().player.copyWith(age: 30, wallet: 500000),
      );
      // Gerçek akış: evli oyuncu çocuk sahibi olur.
      final GameState evli = state.copyWith(
        people: state.people
            .map((Person p) =>
                p.id == 'es-1' ? p.copyWith(age: 30, isAlive: true) : p)
            .where((Person p) => p.relation != RelationType.cocuk)
            .toList(growable: false),
      );
      final GameState sonra = ebeveynlik.haveChild(evli, Random(1)).state;
      final Person bebek = sonra.children.single;

      expect(bebek.development, isNotNull);
      expect(bebek.development!.milestones.single.age, 0);
      expect(bebek.development!.money, 0);
      expect(bebek.development!.stats.intelligence, inInclusiveRange(0, 100));
    });

    test('eski kayıttan gelen çocuğa geçmiş uydurulmaz', () {
      final Person eski = kisi(
        id: 'cocuk-9',
        relation: RelationType.cocuk,
        gender: Gender.erkek,
        age: 14,
      );
      expect(eski.development, isNull);

      final PersonDevelopment acilan =
          ChildProgression.ensureRecord(eski, Random(2));
      // Yaşına uygun sınıf kurulur ama geçmiş satırı yazılmaz.
      expect(acilan.grade, 9);
      expect(acilan.schoolLevel, SchoolLevel.lise);
      expect(acilan.milestones, isEmpty);
      expect(acilan.money, 0);
    });
  });

  // ===================================================================
  // Okul ve üniversite
  // ===================================================================
  group('Eğitim arka planda ilerler', () {
    test('altı yaşında okula başlar, sınıf atlar, liseyi bitirir', () {
      final Random rng = Random(7);
      final ({Person person, List<String> news}) alti =
          ilerlet(cocukKisi(age: 5), 1, rng);
      expect(alti.person.development!.grade, 1);
      expect(alti.person.development!.schoolLevel, SchoolLevel.ilkokul);
      expect(alti.news.any((String h) => h.contains('okula başladı')), isTrue);
      // Dönüm noktası gerçekleştiği yılda kaydedilir.
      expect(alti.person.development!.milestones.last.age, 6);

      final ({Person person, List<String> news}) ondort =
          ilerlet(alti.person, 8, rng);
      expect(ondort.person.age, 14);
      expect(ondort.person.development!.grade, 9);
      expect(ondort.person.development!.schoolLevel, SchoolLevel.lise);

      final ({Person person, List<String> news}) yetiskin =
          ilerlet(ondort.person, 4, rng);
      expect(yetiskin.person.development!.finishedSchool, isTrue);
      expect(yetiskin.person.development!.grade, isNull);
      expect(
        yetiskin.person.development!.milestones
            .any((LifeMilestone m) => m.text.contains('liseyi bitirdi')),
        isTrue,
      );
    });

    test('yetişkin çocuk ilkokul öğrencisi görünmez', () {
      final ({Person person, List<String> news}) r =
          ilerlet(cocukKisi(age: 5), 25, Random(11));
      expect(r.person.age, 30);
      expect(r.person.schoolLevel, isNull);
      expect(r.person.employment, isNot(EmploymentStatus.cocuk));
    });

    test('üniversiteye giden çocuk gerçek bir bölümde okur', () {
      // Yüksek zekâ üniversite ihtimalini artırır; yine de garanti değil.
      bool universiteGoruldu = false;
      for (int seed = 0; seed < 25 && !universiteGoruldu; seed++) {
        final ({Person person, List<String> news}) r = ilerlet(
          cocukKisi(age: 17, intelligence: 90),
          6,
          Random(seed),
        );
        final PersonDevelopment dev = r.person.development!;
        if (dev.university != null) {
          universiteGoruldu = true;
          expect(dev.universityProgramId, isNotNull);
          expect(dev.program, isNotNull);
        }
      }
      expect(universiteGoruldu, isTrue);
    });

    test('her çocuk üniversiteye gitmez ve zengin olmaz', () {
      final Set<String?> egitimler = <String?>{};
      final Set<bool> calisma = <bool>{};
      final Set<int> paralar = <int>{};
      for (int seed = 0; seed < 40; seed++) {
        final ({Person person, List<String> news}) r = ilerlet(
          cocukKisi(age: 5, intelligence: 50 + seed % 40),
          30,
          Random(seed),
        );
        final PersonDevelopment dev = r.person.development!;
        egitimler.add(dev.university?.name);
        calisma.add(dev.isEmployed);
        paralar.add(dev.money);
      }
      expect(egitimler.contains(null), isTrue, reason: 'Üniversitesiz hayat');
      expect(egitimler.length, greaterThan(1), reason: 'Tek sonuç çıkmamalı');
      expect(calisma.length, 2, reason: 'Çalışan da işsiz de olmalı');
      expect(paralar.length, greaterThan(3), reason: 'Birikim çeşitlenmeli');
    });
  });

  // ===================================================================
  // Meslek
  // ===================================================================
  group('Meslek', () {
    test('üniversite isteyen işe mezun olmayan çocuk girmez', () {
      final JobType ogretmen = kJobCatalog.firstWhere(
        (JobType j) => j.education == JobEducation.universite,
      );
      for (int seed = 0; seed < 30; seed++) {
        final ({Person person, List<String> news}) r = ilerlet(
          cocukKisi(age: 21, intelligence: 95).copyWith(
            development: PersonDevelopment(
              stats: const Stats(
                appearance: 50,
                happiness: 50,
                health: 70,
                intelligence: 95,
                charisma: 70,
              ),
              finishedSchool: true,
            ),
          ),
          10,
          Random(seed),
        );
        final PersonDevelopment dev = r.person.development!;
        if (dev.jobId == ogretmen.id) {
          expect(dev.university, UniversityStatus.bitirdi);
        }
      }
    });

    test('çalışan çocuk birikim yapar ve meslek kaydı görünür', () {
      Person cocuk = cocukKisi(age: 24).copyWith(
        development: PersonDevelopment(
          tracksLife: true,
          stats: const Stats(
            appearance: 50,
            happiness: 50,
            health: 70,
            intelligence: 70,
            charisma: 70,
          ),
          finishedSchool: true,
          jobId: kJobCatalog.first.id,
          jobStartedAtAge: 24,
        ),
      );
      cocuk = ilerlet(cocuk, 3, Random(5)).person;
      final PersonDevelopment dev = cocuk.development!;
      if (dev.isEmployed) {
        expect(cocuk.employment, EmploymentStatus.calisiyor);
        expect(cocuk.occupation, dev.job!.name);
        expect(dev.money, greaterThan(0));
      }
    });

    test('vefat eden çocukta gelişim işlemi yapılmaz', () {
      final Person olen = cocukKisi(age: 20).copyWith(isAlive: false);
      final ({Person person, List<String> news}) r =
          ChildProgression.advance(olen, Random(3));
      expect(identical(r.person, olen), isTrue);
      expect(r.news, isEmpty);
    });
  });

  // ===================================================================
  // Oyunun akışıyla bütünleşme
  // ===================================================================
  group('Oyun akışı', () {
    test('yaş alınca çocuk büyür ve önemli haber günlüğe girer', () {
      GameState state = olenOyuncu().copyWith(
        deceased: false,
        player: olenOyuncu().player.copyWith(age: 30),
        people: <Person>[cocukKisi(age: 5)],
        marriage: null,
        settledEstates: const <String>{},
      );

      final Random rng = Random(4);
      for (int i = 0; i < 3; i++) {
        state = LifeProgression(rng)
            .advanceOneYear(state.copyWith(pendingEvent: null));
      }
      final Person cocuk = state.personById('cocuk-1')!;
      expect(cocuk.age, 8);
      expect(cocuk.development!.grade, 3);
      expect(
        state.log.any((LifeLogEntry e) => e.text.contains('okula başladı')),
        isTrue,
      );
      expect(checkInvariants(state), isEmpty);
    });

    test('miras çocuğun gerçek birikiminden dağıtılır', () {
      final Person zenginCocuk = cocukKisi(age: 40).copyWith(
        isAlive: false,
        wealth: WealthTier.cokVarlikli,
        development: PersonDevelopment(
          tracksLife: true,
          stats: const Stats(
            appearance: 50,
            happiness: 50,
            health: 0,
            intelligence: 60,
            charisma: 60,
          ),
          money: 400000,
        ),
      );
      final GameState state = olenOyuncu().copyWith(
        deceased: false,
        people: <Person>[zenginCocuk],
        marriage: null,
        settledEstates: const <String>{},
      );
      final InheritanceShare pay = Inheritance.shareFor(state, zenginCocuk);
      // Ekonomik durum tahmini (3.500.000) değil, gerçek birikim kullanılır.
      expect(pay.money, 400000);
    });
  });

  // ===================================================================
  // Kuşak devamı
  // ===================================================================
  group('Kuşak devamı çocuğun hayatını korur', () {
    test('40 yaşında öğretmen çocuk lise mezunu işsize dönmez', () {
      final JobType ogretmen = kJobCatalog.firstWhere(
        (JobType j) => j.education == JobEducation.universite,
      );
      final PersonDevelopment dev = PersonDevelopment(
        tracksLife: true,
        stats: const Stats(
          appearance: 62,
          happiness: 71,
          health: 66,
          intelligence: 84,
          charisma: 58,
        ),
        finishedSchool: true,
        university: UniversityStatus.bitirdi,
        universityProgramId: 'egitim',
        jobId: ogretmen.id,
        jobStartedAtAge: 24,
        money: 750000,
        interests: const <String>['kitap'],
        milestones: const <LifeMilestone>[
          LifeMilestone(age: 6, text: 'Elif okula başladı.'),
          LifeMilestone(age: 24, text: 'Elif öğretmen olarak işe başladı.'),
        ],
      );
      final GameState eski = olenOyuncu(buyukCocukYasi: 40).copyWith(
        people: olenOyuncu(buyukCocukYasi: 40)
            .people
            .map((Person p) =>
                p.id == 'cocuk-1' ? p.copyWith(development: dev) : p)
            .toList(growable: false),
      );

      final ({GameState? state, String blockReason}) sonuc =
          GenerationContinuation.continueAs(eski, 'cocuk-1', Random(9));
      final GameState yeni = sonuc.state!;

      // Eğitim, meslek ve birikim korunur.
      expect(yeni.education.universityFinished, isTrue);
      expect(yeni.education.universityProgramId, 'egitim');
      expect(yeni.career.jobId, ogretmen.id);
      expect(yeni.career.startedAtAge, 24);
      expect(yeni.player.wallet, greaterThanOrEqualTo(750000));
      // Kendi özellikleri korunur (mutluluk yas kadar düşebilir).
      expect(yeni.player.stats.intelligence, 84);
      expect(yeni.player.stats.appearance, 62);
      // Geçmişi yeni hayatın günlüğünde durur.
      expect(
        yeni.log.any((LifeLogEntry e) =>
            e.age == 24 && e.text.contains('işe başladı')),
        isTrue,
      );
      expect(checkInvariants(yeni), isEmpty);
    });

    test('eski oyuncunun mesleği ve ehliyetleri çocuğa kopyalanmaz', () {
      final GameState eski = olenOyuncu(buyukCocukYasi: 30).copyWith(
        licenses: <String>{'otomobil_ehliyeti'},
      );
      final GameState yeni =
          GenerationContinuation.continueAs(eski, 'cocuk-1', Random(2)).state!;
      expect(yeni.licenses, isEmpty);
      expect(yeni.socialAccounts, isEmpty);
      expect(yeni.player.fame, isNull);
    });
  });

  // ===================================================================
  // Kayıt
  // ===================================================================
  test('gelişim kaydı kaydedilip geri okunur', () {
    final GameState state = olenOyuncu().copyWith(
      deceased: false,
      settledEstates: const <String>{},
      people: <Person>[
        cocukKisi(age: 20).copyWith(
          development: PersonDevelopment(
            tracksLife: true,
            stats: const Stats(
              appearance: 40,
              happiness: 50,
              health: 60,
              intelligence: 70,
              charisma: 80,
            ),
            finishedSchool: true,
            university: UniversityStatus.okuyor,
            universityYear: 2,
            universityProgramId: 'isletme',
            money: 12345,
            interests: const <String>['müzik'],
            milestones: const <LifeMilestone>[
              LifeMilestone(age: 6, text: 'Elif okula başladı.'),
            ],
          ),
        ),
      ],
      marriage: null,
    );

    final GameState geri = decodeGameState(encodeGameState(state));
    final PersonDevelopment dev = geri.personById('cocuk-1')!.development!;
    expect(dev.stats.charisma, 80);
    expect(dev.university, UniversityStatus.okuyor);
    expect(dev.universityProgramId, 'isletme');
    expect(dev.universityYear, 2);
    expect(dev.money, 12345);
    expect(dev.interests, <String>['müzik']);
    expect(dev.milestones.single.age, 6);
  });

  test('dönüm noktası listesi sınırsız büyümez', () {
    Person cocuk = cocukKisi(age: 0);
    cocuk = ilerlet(cocuk, 90, Random(6)).person;
    expect(
      cocuk.development!.milestones.length,
      lessThanOrEqualTo(ChildProgression.prototypeOnlyMaxMilestones),
    );
  });
}

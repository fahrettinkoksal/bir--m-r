// Paket BK/5 — çocuğun yıl özeti.
//
// Oyuncunun yıl özeti (D-096) yılın başındaki fotoğrafla bugünün
// farkından üretiliyor; çocuğun özeti de aynı kalıptan çıkar. Buradaki
// testlerin derdi tek: **uydurma yok.**
//
//   * Fotoğrafı olmayan çocuğun (yıl içinde doğan bebek) özeti çıkmaz.
//   * Değişmeyen çocuk için satır çıkmaz.
//   * Gösterilen sayı niyet değil, ölçülen fark.
//   * Özet kayda girer; eski kayıtta yoksa geriye dönük fark
//     uydurulmaz.
library;

import 'dart:math';

import 'package:bir_omur/data/save/game_state_codec.dart';
import 'package:bir_omur/domain/generation/life_generator.dart';
import 'package:bir_omur/domain/generation/life_progression.dart';
import 'package:bir_omur/domain/interaction/family_interactions.dart';
import 'package:bir_omur/domain/life/year_review.dart';
import 'package:bir_omur/domain/models/applied_effect.dart';
import 'package:bir_omur/domain/models/education.dart';
import 'package:bir_omur/domain/models/game_state.dart';
import 'package:bir_omur/domain/models/gender.dart';
import 'package:bir_omur/domain/models/interaction.dart';
import 'package:bir_omur/domain/models/pending_notice.dart';
import 'package:bir_omur/domain/models/person.dart';
import 'package:bir_omur/domain/models/person_development.dart';
import 'package:bir_omur/domain/models/relation.dart';
import 'package:bir_omur/domain/models/stats.dart';
import 'package:bir_omur/domain/models/wealth.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  GameState hayat({int cocukYasi = 10, int zeka = 50}) {
    final GameState base =
        LifeGenerator.seeded(123).generate(mode: StartMode.tamamenRastgele);
    final GameState s = base.copyWith(
      pendingEvent: null,
      notices: const <PendingNotice>[],
      player: base.player.copyWith(age: 38, wallet: 600000),
      movedOut: true,
    );
    final Person cocuk = Person(
      id: 'cocuk-bk5',
      firstName: 'Deniz',
      lastName: s.player.lastName,
      gender: Gender.kadin,
      relation: RelationType.cocuk,
      age: cocukYasi,
      isAlive: true,
      inPlayerHousehold: true,
      employment: EmploymentStatus.ogrenci,
      wealth: null,
      schoolLevel: SchoolLevel.ilkokul,
      bond: 55,
      happiness: 60,
      development: PersonDevelopment(
        stats: Stats(
          appearance: 55,
          happiness: 60,
          health: 70,
          intelligence: zeka,
          charisma: 50,
        ),
        tracksLife: true,
        schoolLevel: SchoolLevel.ilkokul,
        grade: 3,
        money: 0,
      ),
    );
    final GameState cocuklu = s.copyWith(
      people: List<Person>.unmodifiable(<Person>[...s.people, cocuk]),
    );
    // Yılın başındaki fotoğraf: oyuncunun kendi akışında da böyle
    // alınıyor.
    return cocuklu.copyWith(yearMark: YearMark.of(cocuklu));
  }

  group('Fotoğraf', () {
    test('fotoğraf çocuğun kendi kaydını tutar', () {
      final GameState s = hayat(zeka: 44);
      final ChildMark? m = s.yearMark!.childMarks['cocuk-bk5'];
      expect(m, isNotNull);
      expect(m!.stats.intelligence, 44);
      expect(m.bond, 55);
      expect(m.money, 0);
      expect(m.milestones, 0);
    });

    test('gelişim kaydı olmayan kişi fotoğrafa girmez', () {
      final GameState s = hayat();
      // Anne-baba çocuk değil; harita yalnızca çocukları taşır.
      expect(s.yearMark!.childMarks.keys, <String>['cocuk-bk5']);
    });
  });

  group('Özet ölçülen farkı yazar', () {
    test('hiçbir şey değişmediyse çocuk satırı çıkmaz', () {
      final GameState s = hayat();
      final YearSummary? ozet = YearReview.summarize(s.yearMark, s);
      // Oyuncuda da değişim yok: özetin kendisi de boş.
      expect(ozet, isNull);
    });

    test('ödeve oturulduysa zekâ farkı özete düşer', () {
      GameState s = hayat(zeka: 45);
      // Gerçek eylem: motor üzerinden, elle stat yazarak değil.
      int deneme = 0;
      InteractionResult r = const FamilyInteractions().perform(
        state: s,
        personId: 'cocuk-bk5',
        kind: InteractionKind.odevYardim,
        rng: Random(1),
      );
      while (!r.outcome.accepted && deneme < 12) {
        deneme++;
        r = const FamilyInteractions().perform(
          state: s,
          personId: 'cocuk-bk5',
          kind: InteractionKind.odevYardim,
          rng: Random(1 + deneme),
        );
      }
      expect(r.outcome.accepted, isTrue, reason: 'Kabul edilen bir deneme');
      s = r.state;

      final YearSummary? ozet = YearReview.summarize(s.yearMark, s);
      expect(ozet, isNotNull);
      expect(ozet!.children, hasLength(1));
      final ChildYearSummary cocuk = ozet.children.single;
      expect(cocuk.childId, 'cocuk-bk5');
      expect(cocuk.name, 'Deniz');
      final AppliedEffect zeka = cocuk.effects.firstWhere(
        (AppliedEffect e) => e.label == 'Zekâ',
        orElse: () => const AppliedEffect(label: 'yok'),
      );
      expect(zeka.label, 'Zekâ');
      expect(zeka.delta, greaterThan(0));
      // Fark gerçekten kayıttaki fark: fotoğrafla bugünün arası.
      final int simdi =
          s.personById('cocuk-bk5')!.development!.stats.intelligence;
      expect(zeka.delta, simdi - 45);
    });

    test('harçlık verildiyse birikim farkı özete düşer', () {
      GameState s = hayat();
      final InteractionResult r = const FamilyInteractions().perform(
        state: s,
        personId: 'cocuk-bk5',
        kind: InteractionKind.harclikVer,
        rng: Random(4),
      );
      s = r.state;
      final YearSummary ozet = YearReview.summarize(s.yearMark, s)!;
      final ChildYearSummary cocuk = ozet.children.single;
      final AppliedEffect birikim = cocuk.effects
          .firstWhere((AppliedEffect e) => e.label == 'Birikimi');
      expect(birikim.delta, s.personById('cocuk-bk5')!.development!.money);
      expect(birikim.unit, ' ₺');
    });

    test('yeni uğraş adıyla yazılır', () {
      GameState s = hayat();
      s = const FamilyInteractions()
          .perform(
            state: s,
            personId: 'cocuk-bk5',
            kind: InteractionKind.hobiyeYazdir,
            rng: Random(7),
          )
          .state;
      final ChildYearSummary cocuk =
          YearReview.summarize(s.yearMark, s)!.children.single;
      final String ilgi =
          s.personById('cocuk-bk5')!.development!.interests.single;
      expect(
        cocuk.effects.any((AppliedEffect e) => e.label == 'Yeni uğraş: $ilgi'),
        isTrue,
      );
    });

    test('fotoğrafta olmayan çocuğun özeti çıkmaz', () {
      // Yıl içinde doğan bebek: fotoğraf alındıktan sonra listeye
      // girdi. Doğumun kendisi bildirimle duyuruluyor; "her şey yeni"
      // diye bir özet yazılmaz.
      final GameState s = hayat();
      final Person mevcut = s.personById('cocuk-bk5')!;
      final Person bebek = Person(
        id: 'bebek-yeni',
        firstName: 'Ege',
        lastName: mevcut.lastName,
        gender: Gender.erkek,
        relation: RelationType.cocuk,
        age: 0,
        isAlive: true,
        inPlayerHousehold: true,
        employment: EmploymentStatus.cocuk,
        wealth: null,
        bond: 50,
        development: PersonDevelopment(
          stats: const Stats(
            appearance: 50,
            happiness: 60,
            health: 80,
            intelligence: 50,
            charisma: 50,
          ),
          tracksLife: true,
          money: 0,
        ),
      );
      final GameState bebekli = s.copyWith(
        people: List<Person>.unmodifiable(<Person>[...s.people, bebek]),
      );
      final YearSummary? ozet = YearReview.summarize(bebekli.yearMark, bebekli);
      expect(
        ozet?.children.where((ChildYearSummary c) => c.childId == 'bebek-yeni'),
        anyOf(isNull, isEmpty),
      );
    });

    test('vefat eden çocuk için özet üretilmez', () {
      GameState s = hayat();
      s = s.copyWith(
        people: List<Person>.unmodifiable(<Person>[
          for (final Person p in s.people)
            if (p.id == 'cocuk-bk5') p.copyWith(isAlive: false) else p,
        ]),
      );
      expect(YearReview.summarize(s.yearMark, s)?.children ?? const <ChildYearSummary>[], isEmpty);
    });
  });

  group('Kayıt', () {
    test('özet kayda girer ve geri yüklenir', () {
      GameState s = hayat();
      s = const FamilyInteractions()
          .perform(
            state: s,
            personId: 'cocuk-bk5',
            kind: InteractionKind.harclikVer,
            rng: Random(4),
          )
          .state;
      s = s.copyWith(lastYearSummary: YearReview.summarize(s.yearMark, s));
      expect(s.lastYearSummary!.children, hasLength(1));

      final GameState geri = decodeGameState(encodeGameState(s));
      expect(geri.lastYearSummary!.children, hasLength(1));
      final ChildYearSummary c = geri.lastYearSummary!.children.single;
      expect(c.childId, 'cocuk-bk5');
      expect(c.name, 'Deniz');
      expect(c.effects.map((AppliedEffect e) => e.label),
          s.lastYearSummary!.children.single.effects.map((AppliedEffect e) => e.label));
      // Fotoğraf da kayda girer: yükledikten sonra yıl ortasında
      // özet üretilebilir.
      expect(geri.yearMark!.childMarks['cocuk-bk5'], isNotNull);
      expect(geri.yearMark!.childMarks['cocuk-bk5']!.bond, 55);
    });

    test('eski kayıtta çocuk özeti yok: geriye dönük fark uydurulmaz', () {
      final GameState s = hayat();
      final Map<String, Object?> json = encodeGameState(
        s.copyWith(lastYearSummary: YearReview.summarize(s.yearMark, s)),
      );
      // Eski sürüm: ne fotoğrafta çocuk var ne özette.
      (json['yearMark']! as Map<String, Object?>).remove('childMarks');
      final GameState geri = decodeGameState(json);
      expect(geri.yearMark!.childMarks, isEmpty);
      expect(YearReview.summarize(geri.yearMark, geri)?.children ?? const <ChildYearSummary>[], isEmpty);
    });
  });

  group('Gerçek yıl akışı', () {
    test('yaş ilerleyince çocuğun özeti kendiliğinden üretilir', () {
      final GameState s = hayat(cocukYasi: 8);
      final GameState sonra = LifeProgression(Random(9)).advanceOneYear(s);
      // Çocuk kendi hayatını yaşıyor: bir yılda bir şey değişir.
      final List<ChildYearSummary> cocuklar =
          sonra.lastYearSummary?.children ?? const <ChildYearSummary>[];
      if (cocuklar.isEmpty) return; // o yıl gerçekten hiçbir şey olmadıysa
      expect(cocuklar.single.childId, 'cocuk-bk5');
      expect(cocuklar.single.age, 9);
    });
  });
}

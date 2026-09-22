import 'package:bir_omur/data/martial_arts_catalog.dart';
import 'package:bir_omur/domain/generation/life_generator.dart';
import 'package:bir_omur/domain/life/life_verdict.dart';
import 'package:bir_omur/domain/models/game_state.dart';
import 'package:bir_omur/domain/models/gender.dart';
import 'package:bir_omur/domain/models/marriage.dart';
import 'package:bir_omur/domain/models/martial_progress.dart';
import 'package:bir_omur/domain/models/military.dart';
import 'package:bir_omur/domain/models/pending_notice.dart';
import 'package:bir_omur/domain/models/person.dart';
import 'package:bir_omur/domain/models/relation.dart';
import 'package:bir_omur/domain/models/wealth.dart';
import 'package:flutter_test/flutter_test.dart';

/// Paket 29-36'da eklenen sistemlerin hayat sonu değerlendirmesine
/// yansıması (Paket 37).
///
/// Önceki hâlinde başpehlivan da olsan, binbaşı olarak terhis de olsan
/// değerlendirme bunu hiç görmüyordu.
GameState hayat({Gender cinsiyet = Gender.erkek, int age = 70}) {
  for (int seed = 0; seed < 200; seed++) {
    final GameState taban =
        LifeGenerator.seeded(seed).generate(mode: StartMode.tamamenRastgele);
    if (taban.player.gender != cinsiyet) continue;
    return taban.copyWith(
      pendingEvent: null,
      notices: const <PendingNotice>[],
      player: taban.player.copyWith(age: age),
    );
  }
  throw StateError('Uygun hayat bulunamadı');
}

VerdictAxis eksen(LifeVerdict v, String id) =>
    v.axes.firstWhere((VerdictAxis a) => a.id == id);

void main() {
  group('Askerlik Emek eksenine yazılır', () {
    test('terhis olmuş yükümlü, hiç gitmeyenden yüksek puan alır', () {
      final GameState gitmedi = hayat();
      final GameState terhis = gitmedi.copyWith(
        military: const MilitaryState(
          status: MilitaryStatus.tamamlandi,
          trackName: 'er',
          startedAtAge: 20,
          finishedAtAge: 21,
        ),
      );

      final int once =
          eksen(LifeVerdictBuilder.build(gitmedi), 'emek').value;
      final int sonra =
          eksen(LifeVerdictBuilder.build(terhis), 'emek').value;
      expect(sonra, greaterThan(once));
    });

    test('rütbeli yol erden daha ağır sayılır', () {
      final GameState taban = hayat();
      int puan(String yol, int yil) => eksen(
            LifeVerdictBuilder.build(
              taban.copyWith(
                military: MilitaryState(
                  status: MilitaryStatus.tamamlandi,
                  trackName: yol,
                  startedAtAge: 22,
                  finishedAtAge: 22 + yil,
                ),
              ),
            ),
            'emek',
          ).value;

      expect(puan('subay', 5), greaterThan(puan('er', 1)));
    });

    test('bedelli ödemek hizmet sayılmaz', () {
      final GameState taban = hayat();
      final int hic = eksen(LifeVerdictBuilder.build(taban), 'emek').value;
      final int bedelli = eksen(
        LifeVerdictBuilder.build(
          taban.copyWith(
            military: const MilitaryState(status: MilitaryStatus.bedelli),
          ),
        ),
        'emek',
      ).value;
      expect(bedelli, hic);
    });

    test('kaçak kalmak da hizmet sayılmaz', () {
      final GameState taban = hayat();
      final int hic = eksen(LifeVerdictBuilder.build(taban), 'emek').value;
      final int kacak = eksen(
        LifeVerdictBuilder.build(
          taban.copyWith(
            military: const MilitaryState(
              status: MilitaryStatus.kacak,
              fugitiveSinceAge: 20,
            ),
          ),
        ),
        'emek',
      ).value;
      expect(kacak, hic);
    });

    test('hiç çalışmamış ama askerliğini yapmış hayatın notu bunu söyler', () {
      final GameState s = hayat().copyWith(
        military: const MilitaryState(
          status: MilitaryStatus.tamamlandi,
          trackName: 'er',
          startedAtAge: 20,
          finishedAtAge: 21,
        ),
      );
      if (s.career.history.isNotEmpty) return; // İş geçmişi varsa konu dışı.
      expect(
        eksen(LifeVerdictBuilder.build(s), 'emek').note,
        contains('askerliğini tamamladın'),
      );
    });
  });

  group('Dövüş sanatları Deneyim eksenine yazılır', () {
    test('en üst basamağa çıkmak puanı yükseltir', () {
      final GameState taban = hayat();
      final int once =
          eksen(LifeVerdictBuilder.build(taban), 'deneyim').value;

      final GameState pehlivan = taban.copyWith(
        martialArts: <MartialProgress>[
          MartialProgress(
            artId: MartialArt.gures.id,
            lessons: MartialArt.gures.totalLessons,
            startedAtAge: 12,
            topRankAtAge: 30,
          ),
        ],
      );
      expect(
        eksen(LifeVerdictBuilder.build(pehlivan), 'deneyim').value,
        greaterThan(once),
      );
    });

    test('bir ders almış ile ustalaşmış aynı sayılmaz', () {
      final GameState taban = hayat();
      int puan(int ders) => eksen(
            LifeVerdictBuilder.build(
              taban.copyWith(
                martialArts: <MartialProgress>[
                  MartialProgress(
                    artId: MartialArt.karate.id,
                    lessons: ders,
                    startedAtAge: 12,
                  ),
                ],
              ),
            ),
            'deneyim',
          ).value;

      expect(puan(MartialArt.karate.totalLessons), greaterThan(puan(1)));
    });

    test('ustalaşan hayatın notu dalı adıyla anar', () {
      final GameState s = hayat().copyWith(
        martialArts: <MartialProgress>[
          MartialProgress(
            artId: MartialArt.karate.id,
            lessons: MartialArt.karate.totalLessons,
            startedAtAge: 10,
            topRankAtAge: 28,
          ),
        ],
      );
      expect(
        eksen(LifeVerdictBuilder.build(s), 'deneyim').note,
        contains('Karate'),
      );
    });

    test('hiç ders almamış hayat etkilenmez', () {
      final GameState taban = hayat();
      final GameState bos = taban.copyWith(
        martialArts: const <MartialProgress>[],
      );
      expect(
        eksen(LifeVerdictBuilder.build(bos), 'deneyim').value,
        eksen(LifeVerdictBuilder.build(taban), 'deneyim').value,
      );
    });
  });

  group('İlkler listesi', () {
    test('terhis rütbesiyle yazılır', () {
      final GameState s = hayat().copyWith(
        military: const MilitaryState(
          status: MilitaryStatus.tamamlandi,
          trackName: 'subay',
          rankId: 'yuzbasi',
          startedAtAge: 23,
          finishedAtAge: 28,
        ),
      );
      final LifeVerdict v = LifeVerdictBuilder.build(s);
      final Iterable<String> metinler =
          v.firsts.map((VerdictFirst f) => f.text);
      expect(metinler.any((String t) => t.contains('terhis')), isTrue);
      final VerdictFirst t =
          v.firsts.firstWhere((VerdictFirst f) => f.text.contains('terhis'));
      expect(t.age, 28);
    });

    test('terhis yaşı kayıtlı değilse yazılmaz', () {
      // "Yaşı bilinmeyen bir an ilkler listesine girmez" kuralı.
      final GameState s = hayat().copyWith(
        military: const MilitaryState(
          status: MilitaryStatus.tamamlandi,
          trackName: 'er',
        ),
      );
      expect(
        LifeVerdictBuilder.build(s)
            .firsts
            .any((VerdictFirst f) => f.text.contains('terhis')),
        isFalse,
      );
    });

    test('en üst basamak yaşıyla birlikte yazılır', () {
      final GameState s = hayat().copyWith(
        martialArts: <MartialProgress>[
          MartialProgress(
            artId: MartialArt.gures.id,
            lessons: MartialArt.gures.totalLessons,
            startedAtAge: 12,
            topRankAtAge: 34,
          ),
        ],
      );
      final LifeVerdict v = LifeVerdictBuilder.build(s);
      final VerdictFirst f = v.firsts
          .firstWhere((VerdictFirst x) => x.text.contains('Başpehlivan'));
      expect(f.age, 34);
    });

    test('zirveye çıkılmadıysa basamak yazılmaz', () {
      final GameState s = hayat().copyWith(
        martialArts: <MartialProgress>[
          MartialProgress(
            artId: MartialArt.gures.id,
            lessons: 10,
            startedAtAge: 12,
          ),
        ],
      );
      expect(
        LifeVerdictBuilder.build(s)
            .firsts
            .any((VerdictFirst f) => f.text.contains('en üst basamağa')),
        isFalse,
      );
    });

    test('ikinci evlilik de listede görünür', () {
      final Person eski = Person(
        id: 'es-1',
        firstName: 'Elif',
        lastName: 'Yaman',
        gender: Gender.kadin,
        relation: RelationType.eskiEs,
        age: 60,
        isAlive: true,
        inPlayerHousehold: false,
        employment: EmploymentStatus.calisiyor,
        occupation: 'öğretmen',
        wealth: WealthTier.ortaHalli,
        bond: 40,
      );
      final Person yeni = eski.copyWith(relation: RelationType.es);

      final GameState taban = hayat();
      final GameState s = taban.copyWith(
        people: <Person>[
          ...taban.people.where((Person p) =>
              p.relation != RelationType.es &&
              p.relation != RelationType.sevgili),
          eski,
          Person(
            id: 'es-2',
            firstName: 'Derya',
            lastName: yeni.lastName,
            gender: Gender.kadin,
            relation: RelationType.es,
            age: 58,
            isAlive: true,
            inPlayerHousehold: true,
            employment: EmploymentStatus.calisiyor,
            occupation: 'mimar',
            wealth: WealthTier.ortaHalli,
            bond: 80,
          ),
        ],
        pastMarriages: const <Marriage>[
          Marriage(
            spouseId: 'es-1',
            marriedAtAge: 26,
            status: MarriageStatus.bosandi,
            endedAtAge: 38,
          ),
        ],
        marriage: const Marriage(
          spouseId: 'es-2',
          marriedAtAge: 42,
          status: MarriageStatus.evli,
        ),
      );

      final List<VerdictFirst> ilkler = LifeVerdictBuilder.build(s).firsts;
      expect(
        ilkler.any((VerdictFirst f) => f.text.contains('Elif ile evlendin')),
        isTrue,
      );
      expect(
        ilkler.any(
            (VerdictFirst f) => f.text.contains('Derya ile yeniden evlendin')),
        isTrue,
      );
    });

    test('ilkler yaşa göre sıralı kalır', () {
      final GameState s = hayat().copyWith(
        military: const MilitaryState(
          status: MilitaryStatus.tamamlandi,
          trackName: 'er',
          startedAtAge: 20,
          finishedAtAge: 21,
        ),
        martialArts: <MartialProgress>[
          MartialProgress(
            artId: MartialArt.karate.id,
            lessons: MartialArt.karate.totalLessons,
            startedAtAge: 10,
            topRankAtAge: 35,
          ),
        ],
      );
      final List<VerdictFirst> ilkler = LifeVerdictBuilder.build(s).firsts;
      for (int i = 1; i < ilkler.length; i++) {
        expect(ilkler[i].age, greaterThanOrEqualTo(ilkler[i - 1].age));
      }
    });
  });

  group('Cinsiyete göre yanlışlanan metin', () {
    test('kadın oyuncuda "Anne oldun" yazar', () {
      final GameState taban = hayat(cinsiyet: Gender.kadin, age: 60);
      final GameState s = taban.copyWith(
        people: <Person>[
          ...taban.people.where((Person p) => p.relation != RelationType.cocuk),
          Person(
            id: 'cocuk-1',
            firstName: 'Kaan',
            lastName: taban.player.lastName,
            gender: Gender.erkek,
            relation: RelationType.cocuk,
            age: 30,
            isAlive: true,
            inPlayerHousehold: false,
            employment: EmploymentStatus.calisiyor,
            occupation: 'mühendis',
            wealth: WealthTier.ortaHalli,
            bond: 80,
          ),
        ],
      );
      final Iterable<String> metinler =
          LifeVerdictBuilder.build(s).firsts.map((VerdictFirst f) => f.text);
      expect(metinler, contains('Anne oldun.'));
      expect(metinler.any((String t) => t.contains('Baba/anne')), isFalse);
    });

    test('erkek oyuncuda "Baba oldun" yazar', () {
      final GameState taban = hayat(cinsiyet: Gender.erkek, age: 60);
      final GameState s = taban.copyWith(
        people: <Person>[
          ...taban.people.where((Person p) => p.relation != RelationType.cocuk),
          Person(
            id: 'cocuk-1',
            firstName: 'Deniz',
            lastName: taban.player.lastName,
            gender: Gender.kadin,
            relation: RelationType.cocuk,
            age: 30,
            isAlive: true,
            inPlayerHousehold: false,
            employment: EmploymentStatus.calisiyor,
            occupation: 'mimar',
            wealth: WealthTier.ortaHalli,
            bond: 80,
          ),
        ],
      );
      expect(
        LifeVerdictBuilder.build(s).firsts.map((VerdictFirst f) => f.text),
        contains('Baba oldun.'),
      );
    });
  });
}

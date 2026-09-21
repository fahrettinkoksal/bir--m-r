import 'dart:math';

import 'package:bir_omur/domain/life/life_verdict.dart';
import 'package:bir_omur/domain/generation/life_generator.dart';
import 'package:bir_omur/domain/models/career.dart';
import 'package:bir_omur/domain/models/education.dart';
import 'package:bir_omur/domain/models/game_state.dart';
import 'package:bir_omur/domain/models/marriage.dart';
import 'package:bir_omur/domain/models/person.dart';
import 'package:bir_omur/domain/models/relation.dart';
import 'package:bir_omur/domain/models/trip.dart';
import 'package:bir_omur/state/game_controller.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/test_flow.dart';

GameState vefatEtmisHayat({int seed = 3, int olumYasi = 70}) {
  final GameState state =
      LifeGenerator.seeded(seed).generate(mode: StartMode.tamamenRastgele);
  return state.copyWith(
    player: state.player.copyWith(age: olumYasi),
    deceased: true,
    deathAge: olumYasi,
    deathCause: 'yaşlılık',
  );
}

void main() {
  group('Hayat değerlendirmesi üretilir', () {
    test('boş bir hayatta bile dört eksen ve bir başlık olur', () {
      final LifeVerdict karar = LifeVerdictBuilder.build(vefatEtmisHayat());
      expect(karar.axes, hasLength(4));
      expect(
        karar.axes.map((VerdictAxis a) => a.id).toSet(),
        <String>{'baglar', 'emek', 'deneyim', 'huzur'},
      );
      expect(karar.title, isNotEmpty);
      expect(karar.sentence, isNotEmpty);
      expect(karar.closing, isNotEmpty);
      for (final VerdictAxis eksen in karar.axes) {
        expect(eksen.value, inInclusiveRange(0, 100));
        expect(eksen.note, isNotEmpty);
      }
    });

    test('hiç yaşanmamış şeyler "hiç olmadı" listesine girer', () {
      final LifeVerdict karar = LifeVerdictBuilder.build(vefatEtmisHayat());
      expect(karar.never, contains('Hiç evlenmedin.'));
      expect(karar.never, contains('Hiç çocuğun olmadı.'));
      expect(karar.never, contains('Hiç çalışmadın.'));
      expect(karar.never, contains('Hiç şehir dışına çıkmadın.'));
    });

    test('yaşanan şey "hiç olmadı" listesine girmez', () {
      final GameState temel = vefatEtmisHayat();
      final GameState state = temel.copyWith(
        trips: <TripRecord>[
          const TripRecord(
            id: 'g1',
            city: 'Trabzon',
            age: 24,
            mode: TravelMode.otobus,
            cost: 4000,
          ),
        ],
      );
      final LifeVerdict karar = LifeVerdictBuilder.build(state);
      expect(karar.never, isNot(contains('Hiç şehir dışına çıkmadın.')));
      expect(
        karar.firsts.any((VerdictFirst f) => f.text.contains('Trabzon')),
        isTrue,
      );
    });

    test('"ilkler" yaşa göre sıralanır', () {
      final GameState temel = vefatEtmisHayat();
      final GameState state = temel.copyWith(
        education: const EducationState(
          finished: true,
          startedAtAge: 6,
        ),
        trips: <TripRecord>[
          const TripRecord(
            id: 'g1',
            city: 'İzmir',
            age: 31,
            mode: TravelMode.otobus,
            cost: 4000,
          ),
        ],
        career: CareerState(
          pastJobIds: const <String>['x'],
          history: <JobHistoryEntry>[
            const JobHistoryEntry(
              jobId: 'garson',
              startedAtAge: 19,
              endedAtAge: 40,
            ),
          ],
          retiredAtAge: 62,
        ),
      );
      final LifeVerdict karar = LifeVerdictBuilder.build(state);
      final List<int> yaslar =
          karar.firsts.map((VerdictFirst f) => f.age).toList();
      expect(yaslar, <int>[6, 19, 31, 62]);
    });

    test('kaydı olmayan an "ilkler" listesine girmez', () {
      // Hiçbir iş, gezi veya evlilik kaydı yokken uydurma satır yazılmaz.
      final GameState state = vefatEtmisHayat().copyWith(
        education: const EducationState(),
      );
      final LifeVerdict karar = LifeVerdictBuilder.build(state);
      expect(karar.firsts, isEmpty);
    });

    test('çalışılan yıl arttıkça emek ekseni yükselir', () {
      final GameState bos = vefatEtmisHayat();
      final GameState calisan = bos.copyWith(
        career: CareerState(
          pastJobIds: const <String>['x'],
          history: <JobHistoryEntry>[
            const JobHistoryEntry(
              jobId: 'ogretmen',
              startedAtAge: 24,
              endedAtAge: 60,
            ),
          ],
        ),
      );
      final int once = eksen(LifeVerdictBuilder.build(bos), 'emek').value;
      final int sonra = eksen(LifeVerdictBuilder.build(calisan), 'emek').value;
      expect(sonra, greaterThan(once));
    });

    test('yakın kişiler bağlar eksenini yükseltir', () {
      final GameState temel = vefatEtmisHayat();
      // Karşılaştırma adil olsun diye iki tarafta da aynı kişiler var;
      // yalnızca yakınlık değişiyor.
      final GameState uzak = temel.copyWith(
        people: <Person>[
          for (final Person p in temel.people) p.copyWith(bond: 0),
        ],
      );
      final GameState yakin = temel.copyWith(
        people: <Person>[
          for (final Person p in temel.people) p.copyWith(bond: 90),
        ],
      );
      expect(
        eksen(LifeVerdictBuilder.build(yakin), 'baglar').value,
        greaterThan(eksen(LifeVerdictBuilder.build(uzak), 'baglar').value),
      );
    });

    test('18 yaşından önce vefat eden hayatın başlığı ayrıdır', () {
      final LifeVerdict karar =
          LifeVerdictBuilder.build(vefatEtmisHayat(olumYasi: 9));
      expect(karar.title, 'Yarıda kalan bir hayat');
    });

    test('evlilik hem ilklere girer hem bağları yükseltir', () {
      final GameState bos = vefatEtmisHayat();
      final Person es = bos.people.first.copyWith(
        relation: RelationType.es,
        bond: 70,
      );
      final GameState evli = bos.copyWith(
        people: <Person>[es, ...bos.people.skip(1)],
        marriage: Marriage(spouseId: es.id, marriedAtAge: 27, status: MarriageStatus.evli),
      );
      final LifeVerdict karar = LifeVerdictBuilder.build(evli);
      expect(karar.never, isNot(contains('Hiç evlenmedin.')));
      expect(
        karar.firsts.any((VerdictFirst f) => f.age == 27),
        isTrue,
      );
    });

    test('huzur, anlatacak başka bir şey varken hayata ad vermez', () {
      // 38 yıl çalışıp emekli olmuş, keyfi de yerinde bir hayat
      // "kendi hâlinde" sayılmamalı: emek somut, huzur bir ruh hâli.
      final GameState temel = vefatEtmisHayat(olumYasi: 79);
      final GameState calisan = temel.copyWith(
        player: temel.player.copyWith(
          wallet: 320000,
          stats: temel.player.stats.copyWith(happiness: 92, health: 70),
        ),
        career: CareerState(
          pastJobIds: const <String>['ogretmen'],
          history: <JobHistoryEntry>[
            const JobHistoryEntry(
              jobId: 'ogretmen',
              startedAtAge: 23,
              endedAtAge: 61,
            ),
          ],
          retiredAtAge: 61,
        ),
      );
      final LifeVerdict karar = LifeVerdictBuilder.build(calisan);
      expect(karar.dominantAxisId, 'emek');
      expect(karar.title, 'Emekle geçen bir hayat');
      // Huzur en yüksek eksen olsa bile başlığı o vermez.
      expect(
        eksen(karar, 'huzur').value,
        greaterThan(eksen(karar, 'emek').value),
      );
    });

    test('anlatacak bir şey yokken huzur hayata ad verir', () {
      final GameState temel = vefatEtmisHayat(olumYasi: 74);
      final GameState sakin = temel.copyWith(
        people: <Person>[
          for (final Person p in temel.people) p.copyWith(bond: 0),
        ],
        player: temel.player.copyWith(
          stats: temel.player.stats.copyWith(happiness: 80, health: 60),
        ),
      );
      final LifeVerdict karar = LifeVerdictBuilder.build(sakin);
      expect(karar.dominantAxisId, 'huzur');
      expect(karar.title, 'Kendi hâlinde bir hayat');
    });

    test('açılış cümlesi eksen notlarını tekrarlamaz', () {
      for (int seed = 0; seed < 12; seed++) {
        final LifeVerdict karar =
            LifeVerdictBuilder.build(vefatEtmisHayat(seed: seed));
        for (final VerdictAxis a in karar.axes) {
          expect(
            karar.sentence.contains(a.note),
            isFalse,
            reason: 'Cümle "${a.note}" notunu tekrar ediyor.',
          );
        }
      }
    });

    test('sayılar 0-100 dışına taşmaz', () {
      // Her eksene aşırı girdi verildiğinde bile çubuk taşmaz.
      for (int seed = 0; seed < 20; seed++) {
        final GameState state = vefatEtmisHayat(seed: seed, olumYasi: 95);
        for (final VerdictAxis a in LifeVerdictBuilder.build(state).axes) {
          expect(a.value, inInclusiveRange(0, 100));
        }
      }
    });
  });

  group('Değerlendirme gerçek hayatlarda çalışır', () {
    test('tam bir hayat oynanıp bittiğinde değerlendirme üretilebilir', () {
      for (int seed = 0; seed < 6; seed++) {
        final GameController controller = GameController(random: Random(seed));
        controller.startNewLife(mode: StartMode.tamamenRastgele, seed: seed);
        int guard = 0;
        while (!controller.state!.deceased && guard++ < 130) {
          resolvePendingEvents(controller);
          controller.ageUp();
        }
        if (!controller.state!.deceased) continue;
        final LifeVerdict karar = LifeVerdictBuilder.build(controller.state!);
        expect(karar.title, isNotEmpty);
        expect(karar.axes, hasLength(4));
        // "İlkler" listesi yaşa göre sıralı kalmalı.
        final List<int> yaslar =
            karar.firsts.map((VerdictFirst f) => f.age).toList();
        final List<int> sirali = <int>[...yaslar]..sort();
        expect(yaslar, sirali);
        // Hiçbir "ilk" ölüm yaşından sonra olamaz.
        for (final int y in yaslar) {
          expect(y, lessThanOrEqualTo(controller.state!.deathAge!));
        }
      }
    });

    test('arşive yazılan hayatın değerlendirme adı kaydedilir', () {
      final GameController controller = GameController(random: Random(4));
      controller.startNewLife(mode: StartMode.tamamenRastgele, seed: 4);
      int guard = 0;
      while (!controller.state!.deceased && guard++ < 130) {
        resolvePendingEvents(controller);
        controller.ageUp();
      }
      expect(controller.state!.deceased, isTrue);
      controller.startNewLife(mode: StartMode.tamamenRastgele, seed: 5);
      expect(controller.state!.pastLives, isNotEmpty);
      expect(controller.state!.pastLives.last.verdictTitle, isNotNull);
      expect(controller.state!.pastLives.last.verdictTitle, isNotEmpty);
    });
  });
}

VerdictAxis eksen(LifeVerdict karar, String id) =>
    karar.axes.firstWhere((VerdictAxis a) => a.id == id);

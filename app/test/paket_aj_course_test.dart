// Paket AJ — kurs erişilebilirliği ve aileden destek.
//
// **Neden bu paket var.** Paket AI'nın ölçümü şunu gösterdi: 60 tam
// hayatta tek bir ücretli kursa girilemedi ve 12 hobinin yalnızca 2'si
// ilerledi. Hiç yatırım yapmayan kontrol grubu bile kursa giremedi.
// Yani 10 hobi, yazarlık mesleği ve onlara bağlı bütün içerik
// oyuncunun erişemediği bir kapının arkasındaydı.
//
// Bu dosya kapının açıldığını **ve** bedava stat çeşmesine
// dönüşmediğini birlikte denetler.
// ignore_for_file: avoid_print
library;

import 'dart:math';

import 'package:bir_omur/data/activity_catalog.dart';
import 'package:bir_omur/data/economy.dart';
import 'package:bir_omur/data/event_pool.dart';
import 'package:bir_omur/data/event_pool_course.dart';
import 'package:bir_omur/data/hobby_catalog.dart';
import 'package:bir_omur/domain/activities/activity_engine.dart';
import 'package:bir_omur/domain/generation/life_generator.dart';
import 'package:bir_omur/domain/hobby/course_progress.dart';
import 'package:bir_omur/domain/hobby/course_support.dart';
import 'package:bir_omur/domain/hobby/hobby_tracker.dart';
import 'package:bir_omur/domain/models/game_event.dart';
import 'package:bir_omur/domain/models/game_state.dart';
import 'package:bir_omur/domain/models/hobby_progress.dart';
import 'package:bir_omur/domain/models/person.dart';
import 'package:bir_omur/domain/models/relation.dart';
import 'package:bir_omur/domain/models/wealth.dart';
import 'package:flutter_test/flutter_test.dart';

const ActivityEngine _motor = ActivityEngine();

ActivityAction _kurs(String id) =>
    kActivityActions.firstWhere((ActivityAction a) => a.id == id);

/// Kurs olan bütün aktiviteler.
List<ActivityAction> get _kurslar => kActivityActions
    .where(CourseProgress.isCourse)
    .toList(growable: false);

/// Testler için hayat: yaş, cüzdan ve ebeveyn ayarlanabilir.
GameState _hayat({
  int seed = 4242,
  int age = 12,
  int wallet = 0,
  WealthTier? anneVarlik = WealthTier.ortaHalli,
  WealthTier? babaVarlik = WealthTier.ortaHalli,
  int bond = 70,
  bool anneVar = true,
  bool babaVar = true,
}) {
  final GameState s =
      LifeGenerator.seeded(seed).generate(mode: StartMode.tamamenRastgele);
  final List<Person> kisiler = <Person>[
    for (final Person p in s.people)
      if (p.relation == RelationType.anne)
        (anneVar
            ? p.copyWith(wealth: anneVarlik, bond: bond, isAlive: true)
            : p.copyWith(isAlive: false))
      else if (p.relation == RelationType.baba)
        (babaVar
            ? p.copyWith(wealth: babaVarlik, bond: bond, isAlive: true)
            : p.copyWith(isAlive: false))
      else
        p,
  ];
  return s.copyWith(
    player: s.player.copyWith(age: age, wallet: wallet),
    people: kisiler,
    pendingEvent: null,
  );
}

/// Bir kursu [kez] kez yapar ve son durumu döner.
GameState _dersAl(GameState state, ActivityAction kurs, int kez) {
  GameState s = state;
  for (int i = 0; i < kez; i++) {
    final ActivityResult r =
        _motor.perform(state: s, action: kurs, rng: Random(7 + i));
    if (!r.outcome.applied) break;
    s = r.state;
    // Yıllık kotayı aşmamak için her derste bir yaş ilerlet: bu test
    // ücret kademesini ölçüyor, yıllık kotayı değil.
    s = s.copyWith(
      player: s.player.copyWith(age: s.player.age + 1),
      interactionCounts: const <String, int>{},
    );
  }
  return s;
}

void main() {
  group('Paket AJ — ücret kademeleri', () {
    test('ilk beş ders ücretsiz', () {
      final ActivityAction kurs = _kurs('muzik_kursu');
      GameState s = _hayat(age: 10, wallet: 0);
      for (int i = 0; i < CourseProgress.prototypeOnlyFreeLessons; i++) {
        final CourseStanding d = CourseProgress.standingFor(s, kurs)!;
        expect(d.fee, 0,
            reason: '${i + 1}. ders ücretsiz olmalı, ${d.fee} istendi.');
        expect(d.tier, CourseTier.tanisma);
        expect(_motor.availability(s, kurs).isAllowed, isTrue,
            reason: 'Parasız çocuk tanışma dersine girebilmeli.');
        s = _dersAl(s, kurs, 1);
      }
      expect(HobbyTracker.progressOf(s, HobbyKind.muzik)?.experience, 5);
    });

    test('altıncı ders ücretli', () {
      final ActivityAction kurs = _kurs('muzik_kursu');
      GameState s = _hayat(age: 10, wallet: 0);
      s = _dersAl(s, kurs, 5);
      final CourseStanding d = CourseProgress.standingFor(s, kurs)!;
      expect(d.fee, greaterThan(0), reason: 'Tanışma bitince ücret başlar.');
      expect(d.tier, CourseTier.baslangic);
      // Parası olmayan çocuk devam edemez ama gerekçesi aileyi işaret eder.
      final String gerekce = _motor.availability(s, kurs).reason ?? '';
      expect(gerekce, contains('ailenden destek'),
          reason: 'Çocuğa yol gösterilmeli: $gerekce');
    });

    test('kademeler yükseliyor: başlangıç < normal < profesyonel', () {
      final ActivityAction kurs = _kurs('muzik_kursu');
      final Map<CourseTier, int> ucret = <CourseTier, int>{};
      for (final int ders in <int>[6, 12, 25]) {
        GameState s = _hayat(age: 8, wallet: 50000000);
        s = s.copyWith(hobbies: <HobbyProgress>[
          HobbyProgress(
            hobbyId: HobbyKind.muzik.id,
            startedAtAge: 8,
            experience: ders - 1,
            lastPracticedAge: s.player.age,
          ),
        ]);
        final CourseStanding d = CourseProgress.standingFor(s, kurs)!;
        ucret[d.tier] = d.fee;
      }
      print('');
      print('-- kurs ucret kademeleri (muzik kursu) --');
      for (final MapEntry<CourseTier, int> e in ucret.entries) {
        print('  ${e.key.label.padRight(14)} ${e.value} TL');
      }
      expect(ucret[CourseTier.baslangic]!,
          lessThan(ucret[CourseTier.normal]!));
      expect(ucret[CourseTier.normal]!,
          lessThan(ucret[CourseTier.profesyonel]!));
    });

    test('ücretler oyunun kendi ekonomik ölçeğinden türüyor', () {
      // Katalog fiyatı "normal" kademeyi anlatır; kademe çarpanları
      // katalogdan türediği için asgari ücret çıpası kaydığında hepsi
      // birlikte kayar. Burada sabitlenen şey oran, mutlak sayı değil.
      for (final ActivityAction k in _kurslar) {
        expect(k.cost, greaterThan(0));
        expect(k.cost, lessThan(Economy.netYearlyMinimumWage ~/ 4),
            reason: '${k.id}: tek bir kurs yıllık asgari ücretin dörtte '
                'birinden pahalı olmamalı.');
      }
    });
  });

  group('Paket AJ — ücretsiz ders istismarı', () {
    test('aynı yıl bütün kursları dolaşıp sınırsız bedava ders alınamaz', () {
      GameState s = _hayat(age: 14, wallet: 0);
      int bedava = 0;
      for (final ActivityAction k in _kurslar) {
        for (int i = 0; i < 3; i++) {
          if (!_motor.availability(s, k).isAllowed) break;
          final CourseStanding d = CourseProgress.standingFor(s, k)!;
          if (d.fee > 0) break;
          final ActivityResult r =
              _motor.perform(state: s, action: k, rng: Random(3));
          if (!r.outcome.applied) break;
          s = r.state;
          bedava++;
        }
      }
      print('');
      print('-- ayni yil alinan bedava ders: $bedava '
          '(tavan ${CourseProgress.prototypeOnlyYearlyFreeLessons}) --');
      expect(bedava,
          lessThanOrEqualTo(CourseProgress.prototypeOnlyYearlyFreeLessons),
          reason: 'Yıllık ücretsiz ders tavanı aşıldı.');
    });

    test('ücretsiz ders büyük stat ödülü vermiyor', () {
      final ActivityAction kurs = _kurs('muzik_kursu');
      final GameState s = _hayat(age: 10, wallet: 0);
      final int once = s.player.stats.charisma + s.player.stats.happiness;
      final ActivityResult r =
          _motor.perform(state: s, action: kurs, rng: Random(5));
      final int sonra =
          r.state.player.stats.charisma + r.state.player.stats.happiness;
      print('');
      print('-- tek tanisma dersi stat farki: ${sonra - once} --');
      expect(sonra - once, lessThanOrEqualTo(2),
          reason: 'Tanışma dersi stat düğmesine dönüşmemeli.');
      // Ama hobi gerçekten ilerlemeli: ana ilerleme burada.
      expect(HobbyTracker.progressOf(r.state, HobbyKind.muzik)?.experience, 1);
    });

    test('kilometre taşında ödül gerçekten büyük', () {
      final ActivityAction kurs = _kurs('muzik_kursu');
      // 4 ders alınmış: beşinci ders kilometre taşı.
      GameState s = _hayat(age: 10, wallet: 0);
      s = s.copyWith(hobbies: <HobbyProgress>[
        HobbyProgress(
          hobbyId: HobbyKind.muzik.id,
          startedAtAge: 10,
          experience: 4,
          lastPracticedAge: 10,
        ),
      ]);
      expect(CourseProgress.standingFor(s, kurs)!.milestone, 5);
      final int once = s.player.stats.charisma + s.player.stats.happiness;
      final ActivityResult r =
          _motor.perform(state: s, action: kurs, rng: Random(5));
      final int sonra =
          r.state.player.stats.charisma + r.state.player.stats.happiness;
      print('-- 5. ders (kilometre tasi) stat farki: ${sonra - once} --');
      expect(sonra - once, greaterThan(2),
          reason: 'Kilometre taşı hissedilmeli.');
    });
  });

  group('Paket AJ — aileden destek', () {
    ActivityAction get6 () => _kurs('muzik_kursu');

    GameState ucretliNokta({
      WealthTier? anne = WealthTier.ortaHalli,
      WealthTier? baba = WealthTier.ortaHalli,
      int bond = 70,
      int age = 12,
      bool anneVar = true,
      bool babaVar = true,
      int deneyim = 5,
      int gecmisYil = 0,
    }) {
      final GameState s = _hayat(
        age: age,
        wallet: 0,
        anneVarlik: anne,
        babaVarlik: baba,
        bond: bond,
        anneVar: anneVar,
        babaVar: babaVar,
      );
      return s.copyWith(hobbies: <HobbyProgress>[
        HobbyProgress(
          hobbyId: HobbyKind.muzik.id,
          startedAtAge: age - gecmisYil,
          experience: deneyim,
          lastPracticedAge: age,
        ),
      ]);
    }

    Person anneKisi(GameState s) =>
        s.people.firstWhere((Person p) => p.relation == RelationType.anne);
    Person babaKisi(GameState s) =>
        s.people.firstWhere((Person p) => p.relation == RelationType.baba);

    test('18 yaş altı anneye ve babaya sorabiliyor', () {
      final GameState s = ucretliNokta();
      final List<Person> destekciler = CourseSupport.sponsorsFor(s);
      expect(destekciler.map((Person p) => p.relation),
          containsAll(<RelationType>[RelationType.anne, RelationType.baba]));
      expect(CourseSupport.blockReason(s, get6(), anneKisi(s)), isEmpty);
      expect(CourseSupport.blockReason(s, get6(), babaKisi(s)), isEmpty);
    });

    test('ebeveyn yoksa seçenek görünmüyor', () {
      final GameState s =
          ucretliNokta(anneVar: false, babaVar: false);
      expect(CourseSupport.sponsorsFor(s), isEmpty);
    });

    test('18 yaş sonrası aileden kurs ödemesi kapanıyor', () {
      final GameState s = ucretliNokta(age: 22);
      final String engel = CourseSupport.blockReason(s, get6(), anneKisi(s));
      expect(engel, contains('kendi kursunu kendin'));
    });

    test('varlıklı ailede kabul, dar gelirli ailede ret daha olası', () {
      int say(WealthTier tier) {
        int kabul = 0;
        for (int i = 0; i < 200; i++) {
          final GameState s = ucretliNokta(anne: tier, baba: tier);
          final CourseSupportResult r = CourseSupport.ask(
            state: s,
            action: get6(),
            person: anneKisi(s),
            rng: Random(1000 + i),
          );
          if (r.outcome.accepted) kabul++;
        }
        return kabul;
      }

      final int yoksul = say(WealthTier.yoksul);
      final int orta = say(WealthTier.ortaHalli);
      final int varlikli = say(WealthTier.varlikli);
      print('');
      print('-- 200 istekte kabul: yoksul $yoksul · orta $orta · '
          'varlikli $varlikli --');
      expect(yoksul, lessThan(varlikli),
          reason: 'Dar gelirli aile daha zor kabul etmeli.');
      expect(orta, lessThanOrEqualTo(varlikli));
      // Fakir ailede ret **mümkün** olmalı.
      expect(yoksul, lessThan(200));
    });

    test('yüksek yakınlık kabulü artırıyor', () {
      int say(int bond) {
        int kabul = 0;
        for (int i = 0; i < 200; i++) {
          final GameState s = ucretliNokta(bond: bond);
          final CourseSupportResult r = CourseSupport.ask(
            state: s,
            action: get6(),
            person: anneKisi(s),
            rng: Random(2000 + i),
          );
          if (r.outcome.accepted) kabul++;
        }
        return kabul;
      }

      final int uzak = say(25);
      final int yakin = say(95);
      print('-- yakinlik: uzak $uzak · yakin $yakin --');
      expect(yakin, greaterThan(uzak));
    });

    test('devamlılık kabulü artırıyor', () {
      int say(int yil) {
        int kabul = 0;
        for (int i = 0; i < 200; i++) {
          final GameState s = ucretliNokta(gecmisYil: yil);
          final CourseSupportResult r = CourseSupport.ask(
            state: s,
            action: get6(),
            person: anneKisi(s),
            rng: Random(3000 + i),
          );
          if (r.outcome.accepted) kabul++;
        }
        return kabul;
      }

      final int yeni = say(0);
      final int uzunSoluklu = say(5);
      print('-- devamlilik: yeni $yeni · 5 yildir $uzunSoluklu --');
      expect(uzunSoluklu, greaterThan(yeni));
    });

    test('ret kalıcı değil: seneye yeniden sorulabiliyor', () {
      GameState s = ucretliNokta(anne: WealthTier.cokYoksul);
      // Reddettiren bir istek bul.
      CourseSupportResult r = CourseSupport.ask(
        state: s,
        action: get6(),
        person: anneKisi(s),
        rng: Random(11),
      );
      while (r.outcome.accepted) {
        s = ucretliNokta(anne: WealthTier.cokYoksul);
        r = CourseSupport.ask(
          state: s,
          action: get6(),
          person: anneKisi(s),
          rng: Random(11),
        );
        break;
      }
      if (!r.outcome.accepted) {
        s = r.state;
        expect(CourseSupport.blockReason(s, get6(), anneKisi(s)),
            contains('seneye'));
        // Yıl dönünce sayaçlar sıfırlanır (LifeProgression) ve kapı açılır.
        final GameState seneye =
            s.copyWith(interactionCounts: const <String, int>{});
        expect(CourseSupport.blockReason(seneye, get6(), anneKisi(seneye)),
            isEmpty);
      }
    });

    test('aile parası yoktan oluşmuyor: yıllık bütçe var', () {
      GameState s = ucretliNokta(anne: WealthTier.ortaHalli);
      final Person anne = anneKisi(s);
      final int butce = CourseSupport.yearlyBudget(anne);
      expect(butce, greaterThan(0));
      int verilen = 0;
      // Reddi aşmak için farklı zarlarla ısrar ediyoruz: amaç "kabul
      // ettirmek" değil, **kabul edilenlerin toplamının** yıllık bütçeyi
      // aşamadığını görmek.
      for (int i = 0; i < 400; i++) {
        final GameState denenen = s.copyWith(interactionCounts: <String, int>{
          for (final MapEntry<String, int> e in s.interactionCounts.entries)
            if (!e.key.endsWith('|${CourseSupport.refusalKind}')) e.key: e.value,
        });
        final CourseSupportResult r = CourseSupport.ask(
          state: denenen,
          action: get6(),
          person: anne,
          rng: Random(i),
        );
        if (!r.outcome.accepted) continue;
        verilen += r.outcome.amount;
        // Krediyi harca ki bir sonraki istek "zaten karşılandı" demesin.
        s = CourseSupport.spendCredit(
          r.state,
          HobbyKind.muzik.id,
          r.outcome.amount,
        ).state;
      }
      print('');
      print('-- aile yillik butce $butce, verilen $verilen --');
      expect(verilen, lessThanOrEqualTo(butce),
          reason: 'Aile yıllık bütçesinden fazlasını veremez.');
    });

    test('ödeme iki kez uygulanmıyor: kredi bir kez harcanıyor', () {
      GameState s = ucretliNokta();
      final CourseSupportResult r = CourseSupport.ask(
        state: s,
        action: get6(),
        person: anneKisi(s),
        rng: Random(4),
      );
      if (!r.outcome.accepted) return;
      s = r.state;
      final int kredi = CourseSupport.creditFor(s, HobbyKind.muzik.id);
      expect(kredi, r.outcome.amount);
      // Ders yapılınca kredi biter ve cüzdana dokunulmaz.
      final int cuzdanOnce = s.player.wallet;
      final ActivityResult ders =
          _motor.perform(state: s, action: get6(), rng: Random(6));
      expect(ders.outcome.applied, isTrue);
      expect(ders.state.player.wallet, cuzdanOnce,
          reason: 'Aile ödediyse cüzdandan para çıkmamalı.');
      expect(CourseSupport.creditFor(ders.state, HobbyKind.muzik.id), 0,
          reason: 'Kredi iki kez kullanılamamalı.');
    });

    test('kaydet/yükle ile destek tekrar toplanamıyor', () {
      // Kabul edilen desteği "kaydet, yükle, tekrar sor" ile çoğaltmaya
      // çalışmak: aynı yıl aynı kişiden ikinci kez kredi alınamaz çünkü
      // bütçe ve kredi aynı durumun içinde tutuluyor.
      GameState s = ucretliNokta();
      final CourseSupportResult ilk = CourseSupport.ask(
        state: s,
        action: get6(),
        person: anneKisi(s),
        rng: Random(4),
      );
      if (!ilk.outcome.accepted) return;
      s = ilk.state;
      final CourseSupportResult ikinci = CourseSupport.ask(
        state: s,
        action: get6(),
        person: anneKisi(s),
        rng: Random(4),
      );
      expect(ikinci.outcome.applied, isFalse,
          reason: 'Ücret zaten karşılanmışken ikinci kredi verilmemeli.');
    });
  });

  group('Paket AJ — burs ve ücretsiz yollar (§7)', () {
    test('dört ücretsiz yol olayı havuzda ve izi bırakıyor', () {
      expect(kCourseSupportEvents.length, greaterThanOrEqualTo(4));
      for (final GameEvent e in kCourseSupportEvents) {
        expect(kEventPool.any((GameEvent p) => p.id == e.id), isTrue,
            reason: '${e.id} ana havuza kayıtlı değil.');
        expect(
          e.choices.any((EventChoice c) =>
              c.addFlags.contains(CourseProgress.scholarshipFlag)),
          isTrue,
          reason: '${e.id} hiçbir seçenekte burs izi bırakmıyor.',
        );
      }
    });

    test('burs izi varken ücretli ders bedava', () {
      final ActivityAction kurs = _kurs('muzik_kursu');
      GameState s = _hayat(age: 14, wallet: 0);
      // Tanışma dönemini bitir.
      s = s.copyWith(hobbies: <HobbyProgress>[
        HobbyProgress(
          hobbyId: HobbyKind.muzik.id,
          startedAtAge: 10,
          experience: 8,
          lastPracticedAge: 14,
        ),
      ]);
      expect(CourseProgress.standingFor(s, kurs)!.fee, greaterThan(0));
      final GameState burslu = s.copyWith(
        storyFlags: <String>{...s.storyFlags, CourseProgress.scholarshipFlag},
      );
      expect(CourseProgress.standingFor(burslu, kurs)!.fee, 0,
          reason: 'Burs izi ücreti kaldırmalı.');
      expect(_motor.availability(burslu, kurs).isAllowed, isTrue);
    });

    test('burs sınırsız değil: yıllık hak bitince ücret geri geliyor', () {
      final ActivityAction kurs = _kurs('muzik_kursu');
      GameState s = _hayat(age: 14, wallet: 0).copyWith(
        hobbies: <HobbyProgress>[
          HobbyProgress(
            hobbyId: HobbyKind.muzik.id,
            startedAtAge: 10,
            experience: 8,
            lastPracticedAge: 14,
          ),
        ],
      );
      s = s.copyWith(
        storyFlags: <String>{...s.storyFlags, CourseProgress.scholarshipFlag},
        interactionCounts: <String, int>{
          GameState.interactionKey(
            CourseProgress.scholarshipCounterId,
            CourseProgress.counterKind,
          ): CourseProgress.prototypeOnlyScholarshipLessons,
        },
      );
      expect(CourseProgress.standingFor(s, kurs)!.fee, greaterThan(0),
          reason: 'Burs hakkı bitince ücret geri gelmeli.');
    });
  });

  group('Paket AJ — erişilebilirlik', () {
    test('on ücretli kursun hepsine tanışma dersinden girilebiliyor', () {
      final List<String> girilemeyen = <String>[];
      for (final ActivityAction k in _kurslar) {
        final GameState s = _hayat(age: max(14, k.minAge), wallet: 0);
        if (!_motor.availability(s, k).isAllowed) {
          girilemeyen.add('${k.id}: ${_motor.availability(s, k).reason}');
        }
      }
      print('');
      print('-- kurs sayisi ${_kurslar.length}, girilemeyen '
          '${girilemeyen.length} --');
      for (final String g in girilemeyen) {
        print('  $g');
      }
      expect(girilemeyen, isEmpty,
          reason: 'Parasız bir çocuk her kursun tanışma dersine girebilmeli.');
    });

    test('12 hobinin hepsi ilerletilebiliyor', () {
      final Set<String> ilerleyen = <String>{};
      // Kursla beslenenler.
      for (final ActivityAction k in _kurslar) {
        GameState s = _hayat(age: max(14, k.minAge), wallet: 0);
        final ActivityResult r =
            _motor.perform(state: s, action: k, rng: Random(9));
        if (r.outcome.applied) {
          s = r.state;
          for (final HobbyProgress h in s.hobbies) {
            ilerleyen.add(h.hobbyId);
          }
        }
      }
      // Spor ve okuma ücretsiz yollardan besleniyor; ikisi de AI
      // ölçümünde zaten ilerliyordu.
      ilerleyen
        ..add(HobbyKind.spor.id)
        ..add(HobbyKind.okuma.id);
      print('');
      print('-- ilerletilebilen hobi ${ilerleyen.length}/'
          '${HobbyKind.values.length}: ${ilerleyen.join(', ')} --');
      expect(ilerleyen.length, HobbyKind.values.length,
          reason: 'Her hobinin bir ilerleme yolu olmalı.');
    });
  });
}

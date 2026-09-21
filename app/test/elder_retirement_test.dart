import 'dart:math';

import 'package:bir_omur/data/job_catalog.dart';
import 'package:bir_omur/data/save/game_state_codec.dart';
import 'package:bir_omur/data/save/save_format.dart';
import 'package:bir_omur/domain/career/retirement.dart';
import 'package:bir_omur/domain/generation/grandchildren.dart';
import 'package:bir_omur/domain/generation/life_generator.dart';
import 'package:bir_omur/domain/generation/life_progression.dart';
import 'package:bir_omur/domain/models/career.dart';
import 'package:bir_omur/domain/models/education.dart';
import 'package:bir_omur/domain/models/game_state.dart';
import 'package:bir_omur/domain/models/gender.dart';
import 'package:bir_omur/domain/models/person.dart';
import 'package:bir_omur/domain/models/person_development.dart';
import 'package:bir_omur/domain/models/relation.dart';
import 'package:bir_omur/domain/models/stats.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/generation_fixtures.dart';
import 'support/invariants.dart';

final JobType magaza = jobById('magaza_calisani')!;

/// Uzun süre çalışmış, emekliliğe yaklaşmış bir oyuncu.
GameState calisan({
  int age = 65,
  int startedAtAge = 25,
  int wallet = 100000,
  int salary = 300000,
  List<JobHistoryEntry> history = const <JobHistoryEntry>[],
  bool calisiyor = true,
}) {
  final GameState base =
      LifeGenerator.seeded(111).generate(mode: StartMode.tamamenRastgele);
  return base.copyWith(
    pendingEvent: null,
    player: base.player.copyWith(age: age, wallet: wallet),
    education: const EducationState(finished: true, startedAtAge: 6),
    career: calisiyor
        ? CareerState(
            jobId: magaza.id,
            startedAtAge: startedAtAge,
            lastPaidAge: age,
            salary: salary,
            jobCity: base.player.currentCity,
            history: history,
          )
        : CareerState(history: history),
  );
}

void main() {
  // ===================================================================
  // Emeklilik
  // ===================================================================
  group('Emeklilik', () {
    test('erken yaşta emeklilik açılmaz', () {
      final GameState genc = calisan(age: 40, startedAtAge: 25);
      expect(Retirement.availability(genc).isAllowed, isFalse);
      final RetirementResult r = Retirement.retire(genc);
      expect(r.applied, isFalse);
      expect(r.state.career.isRetired, isFalse);
    });

    test('emekli olunca iş kaydı kapanır ve aylık bağlanır', () {
      final GameState s = calisan(age: 65, startedAtAge: 25);
      final RetirementResult r = Retirement.retire(s);

      expect(r.applied, isTrue);
      expect(r.state.career.isRetired, isTrue);
      expect(r.state.career.retiredAtAge, 65);
      expect(r.state.career.isEmployed, isFalse);
      expect(r.state.career.pension, greaterThan(0));
      // Süren iş geçmişe "emekli oldu" olarak yazılır.
      expect(r.state.career.history.single.endReason, JobEndReason.emeklilik);
      expect(r.state.career.history.single.endedAtAge, 65);
      expect(checkInvariants(r.state), isEmpty);
    });

    test('aylık son maaşa ve çalışma yılına bağlıdır', () {
      final GameState uzun = calisan(age: 65, startedAtAge: 25);
      final GameState kisa = calisan(age: 65, startedAtAge: 50);

      final int uzunAylik = Retirement.prototypeOnlyPensionFor(uzun);
      final int kisaAylik = Retirement.prototypeOnlyPensionFor(kisa);
      expect(uzunAylik, greaterThan(kisaAylik));
      // Aylık son maaştan yüksek olmaz.
      expect(uzunAylik, lessThan(uzun.career.yearlySalary));
    });

    test('erken emeklilikte aylık daha düşük bağlanır', () {
      final GameState erken = calisan(age: 61, startedAtAge: 25);
      final GameState tam = calisan(age: 65, startedAtAge: 29);
      // İkisinin de çalışma yılı 36; fark yalnızca yaş.
      expect(erken.career.totalWorkYears(61), tam.career.totalWorkYears(65));
      expect(
        Retirement.prototypeOnlyPensionFor(erken),
        lessThan(Retirement.prototypeOnlyPensionFor(tam)),
      );
    });

    test('hiç çalışmamış oyuncuya asgari aylık bağlanır', () {
      final GameState hic = calisan(age: 66, calisiyor: false);
      expect(hic.career.totalWorkYears(66), 0);
      expect(
        Retirement.prototypeOnlyPensionFor(hic),
        Retirement.prototypeOnlyMinimumPension,
      );
    });

    test('aylık yılda bir kez ödenir', () {
      final GameState s = Retirement.retire(calisan(age: 65)).state;
      final int aylik = s.career.pension!;
      final int cuzdan = s.player.wallet;

      final ({GameState state, String? logText}) ilk =
          Retirement.payPension(s, 66);
      expect(ilk.state.player.wallet, cuzdan + aylik);
      expect(ilk.logText, isNotNull);

      // Aynı yaş için ikinci ödeme yok.
      final ({GameState state, String? logText}) ikinci =
          Retirement.payPension(ilk.state, 66);
      expect(ikinci.state.player.wallet, ilk.state.player.wallet);
      expect(ikinci.logText, isNull);
    });

    test('emekli oyuncu maaş ve aylığı birlikte almaz', () {
      final GameState s = Retirement.retire(calisan(age: 65)).state;
      final int aylik = s.career.pension!;
      final GameState sonra =
          LifeProgression(Random(3)).advanceOneYear(s.copyWith(
        pendingEvent: null,
      ));

      // Yalnızca aylık girdi; maaş satırı yok.
      final Iterable<String> satirlar =
          sonra.log.map((dynamic e) => e.text as String);
      expect(satirlar.where((String t) => t.contains('Emekli aylığın')),
          hasLength(1));
      expect(satirlar.where((String t) => t.contains('bir yılın doldu')),
          isEmpty);
      expect(sonra.player.wallet, greaterThan(s.player.wallet - aylik));
    });

    test('ikinci kez emekli olunamaz', () {
      final GameState s = Retirement.retire(calisan(age: 65)).state;
      final RetirementResult tekrar = Retirement.retire(s);
      expect(tekrar.applied, isFalse);
      expect(tekrar.state.career.retiredAtAge, 65);
    });

    test('emeklilik kapat-aç ile korunur ve aylık iki kez yatmaz', () {
      final GameState s = Retirement.retire(calisan(age: 65, wallet: 0)).state;
      final GameState geri = decodeGameState(encodeGameState(s));

      expect(geri.career.isRetired, isTrue);
      expect(geri.career.pension, s.career.pension);
      expect(geri.player.wallet, s.player.wallet);
      // Emekli olunan yıl için ödeme yapılmaz.
      expect(Retirement.payPension(geri, 65).logText, isNull);
    });

    test('kayıt sürümü 26 ve eski kayıtta emeklilik yoktur', () {
      expect(kSaveFormatVersion, 26);
      final GameState s = calisan(age: 65);
      final Map<String, Object?> body =
          Map<String, Object?>.from(encodeGameState(s));
      final Map<String, Object?> career =
          Map<String, Object?>.from(body['career']! as Map<String, Object?>)
            ..remove('retiredAtAge')
            ..remove('pension');
      body['career'] = career;

      final GameState geri =
          decodeGameState(SaveMigrations.migrate(body, 25));
      expect(geri.career.isRetired, isFalse);
      expect(geri.career.pension, isNull);
    });
  });

  // ===================================================================
  // Kayıt penceresi (Faho'nun kararı: son beş sürüm)
  // ===================================================================
  group('Kayıt penceresi', () {
    test('desteklenen taban güncel sürümün beş gerisidir', () {
      expect(kSaveFormatVersion - kMinReadableSaveVersion, 5);
    });

    test('tabanın altındaki kayıt anlaşılır mesajla reddedilir', () {
      final GameState s = calisan(age: 30);
      expect(
        () => SaveMigrations.migrate(
          encodeGameState(s),
          kMinReadableSaveVersion - 1,
        ),
        throwsA(
          isA<SaveFormatException>().having(
            (SaveFormatException e) => e.message,
            'mesaj',
            contains('silinmedi'),
          ),
        ),
      );
    });
  });

  // ===================================================================
  // Torunlar
  // ===================================================================
  group('Torunlar', () {
    /// Yetişkin çocuğu olan oyuncu.
    GameState cocukluOyuncu({int cocukYasi = 30, int oyuncuYasi = 58}) {
      final GameState base = calisan(age: oyuncuYasi);
      return base.copyWith(
        people: <Person>[
          kisi(
            id: 'cocuk-1',
            relation: RelationType.cocuk,
            gender: Gender.kadin,
            age: cocukYasi,
            firstName: 'Elif',
            city: base.player.currentCity,
          ).copyWith(
            development: const PersonDevelopment(
              tracksLife: true,
              stats: Stats(
                appearance: 60,
                happiness: 60,
                health: 70,
                intelligence: 65,
                charisma: 60,
              ),
            ),
          ),
        ],
      );
    }

    Person torunUret(GameState state) {
      for (int i = 0; i < 400; i++) {
        final Person? t = Grandchildren.maybeBorn(
          state: state,
          child: state.personById('cocuk-1')!,
          rng: Random(i),
        );
        if (t != null) return t;
      }
      fail('Torun hiç doğmadı.');
    }

    test('çok genç veya çok yaşlı çocuktan torun doğmaz', () {
      final GameState genc = cocukluOyuncu(cocukYasi: 15);
      final GameState yasli = cocukluOyuncu(cocukYasi: 55);
      for (int i = 0; i < 50; i++) {
        expect(
          Grandchildren.maybeBorn(
            state: genc,
            child: genc.personById('cocuk-1')!,
            rng: Random(i),
          ),
          isNull,
        );
        expect(
          Grandchildren.maybeBorn(
            state: yasli,
            child: yasli.personById('cocuk-1')!,
            rng: Random(i),
          ),
          isNull,
        );
      }
    });

    test('vefat etmiş çocuktan torun doğmaz', () {
      final GameState s = cocukluOyuncu();
      final Person olu = s.personById('cocuk-1')!.copyWith(isAlive: false);
      for (int i = 0; i < 50; i++) {
        expect(
          Grandchildren.maybeBorn(state: s, child: olu, rng: Random(i)),
          isNull,
        );
      }
    });

    test('torun gerçek bir kişi kaydıdır', () {
      final GameState s = cocukluOyuncu();
      final Person torun = torunUret(s);

      expect(torun.relation, RelationType.torun);
      expect(torun.age, 0);
      expect(torun.isAlive, isTrue);
      // Oyuncunun hanesinde yaşamaz.
      expect(torun.inPlayerHousehold, isFalse);
      // Ebeveyni oyuncunun çocuğudur.
      expect(torun.development!.otherParentId, 'cocuk-1');
      expect(torun.lastName, 'Yılmaz');
      // Kendi özellikleri vardır.
      expect(torun.development!.stats.intelligence, inInclusiveRange(0, 100));
    });

    test('bir çocuğun torun sayısı sınırlıdır', () {
      GameState s = cocukluOyuncu();
      for (int i = 0; i < Grandchildren.prototypeOnlyMaxPerChild; i++) {
        final Person t = torunUret(s);
        s = s.copyWith(
          people: List<Person>.unmodifiable(<Person>[...s.people, t]),
        );
      }
      expect(
        Grandchildren.childrenOf(s, 'cocuk-1'),
        hasLength(Grandchildren.prototypeOnlyMaxPerChild),
      );
      for (int i = 0; i < 60; i++) {
        expect(
          Grandchildren.maybeBorn(
            state: s,
            child: s.personById('cocuk-1')!,
            rng: Random(i),
          ),
          isNull,
        );
      }
    });

    test('yaş alma akışında torun doğar ve günlüğe girer', () {
      GameState s = cocukluOyuncu(cocukYasi: 28, oyuncuYasi: 55);
      bool dogdu = false;
      for (int yil = 0; yil < 12 && !dogdu; yil++) {
        s = LifeProgression(Random(yil)).advanceOneYear(
          s.copyWith(pendingEvent: null),
        );
        dogdu = Grandchildren.all(s).isNotEmpty;
      }
      expect(dogdu, isTrue, reason: '12 yılda hiç torun doğmadı');

      final Person torun = Grandchildren.all(s).first;
      expect(
        s.log.any((dynamic e) =>
            (e.text as String).contains('dede/nine oldun')),
        isTrue,
      );
      expect(s.isReachable(torun), isTrue);
      expect(checkInvariants(s), isEmpty);
    });

    test('torun kapat-aç ile korunur ve büyür', () {
      GameState s = cocukluOyuncu(cocukYasi: 28, oyuncuYasi: 55);
      final Person torun = torunUret(s);
      s = s.copyWith(
        people: List<Person>.unmodifiable(<Person>[...s.people, torun]),
      );

      final GameState geri = decodeGameState(encodeGameState(s));
      expect(geri.personById(torun.id), isNotNull);
      expect(geri.personById(torun.id)!.relation, RelationType.torun);

      // Birkaç yıl geçince torun da yaşını yaşar.
      GameState sonra = geri;
      for (int i = 0; i < 7; i++) {
        sonra = LifeProgression(Random(20 + i)).advanceOneYear(
          sonra.copyWith(pendingEvent: null),
        );
      }
      expect(sonra.personById(torun.id)!.age, greaterThanOrEqualTo(7));
    });
  });
}

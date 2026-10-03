import 'dart:math';

import 'package:bir_omur/data/interview_catalog.dart';
import 'package:bir_omur/data/job_catalog.dart';
import 'package:bir_omur/data/save/game_state_codec.dart';
import 'package:bir_omur/data/save/save_format.dart';
import 'package:bir_omur/domain/career/career_progress.dart';
import 'package:bir_omur/domain/career/colleagues.dart';
import 'package:bir_omur/domain/career/job_market.dart';
import 'package:bir_omur/domain/generation/life_generator.dart';
import 'package:bir_omur/domain/generation/life_progression.dart';
import 'package:bir_omur/domain/models/career.dart';
import 'package:bir_omur/domain/models/education.dart';
import 'package:bir_omur/domain/models/game_state.dart';
import 'package:bir_omur/domain/models/life_log.dart';
import 'package:bir_omur/domain/models/person.dart';
import 'package:bir_omur/domain/models/relation.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/invariants.dart';

const JobMarket market = JobMarket();

/// Lise mezunu, işe başvurabilecek bir yetişkin.
GameState mezun({
  int seed = 31,
  int age = 25,
  int wallet = 100000,
  int intelligence = 70,
  int charisma = 70,
}) {
  final GameState base =
      LifeGenerator.seeded(seed).generate(mode: StartMode.tamamenRastgele);
  return base.copyWith(
    pendingEvent: null,
    player: base.player.copyWith(
      age: age,
      wallet: wallet,
      stats: base.player.stats.copyWith(
        intelligence: intelligence,
        charisma: charisma,
      ),
    ),
    education: const EducationState(finished: true, startedAtAge: 6),
  );
}

/// Oyuncuyu gerçekten işe alır (başvuru → mülakat → doğru cevap).
GameState iseGir(GameState state, JobType job, [int seed = 1]) {
  final JobResult basvuru = market.apply(state, job, Random(seed));
  final InterviewQuestion soru = basvuru.state.pendingInterview!.question!;
  final JobResult cevap = market.answerInterview(
    basvuru.state,
    soru.correctIndex,
    Random(seed),
  );
  expect(cevap.outcome.accepted, isTrue, reason: 'İşe alınmalıydı');
  return cevap.state;
}

/// Kabul edilene kadar zam/terfi ister (yıl atlayarak).
GameState kabulEdilenTalep(
  GameState state, {
  required bool terfi,
  int maxDeneme = 40,
}) {
  GameState s = state;
  for (int i = 0; i < maxDeneme; i++) {
    final CareerRequestResult r = terfi
        ? CareerProgress.askForPromotion(s, Random(i))
        : CareerProgress.askForRaise(s, Random(i));
    if (r.accepted) return r.state;
    s = r.applied ? r.state : s;
    // Yeni yıl: sayaç sıfırlanır, işte geçen süre uzar.
    s = s.copyWith(
      player: s.player.copyWith(age: s.player.age + 1),
      interactionCounts: const <String, int>{},
    );
  }
  fail('Talep hiç kabul edilmedi.');
}

void main() {
  final JobType magaza = jobById('magaza_calisani')!;

  // ===================================================================
  // Kariyer geçmişi
  // ===================================================================
  group('Kariyer geçmişi', () {
    test('işe girince kayıt açılır ve unvan giriş seviyesidir', () {
      final GameState calisan = iseGir(mezun(), magaza);
      expect(calisan.career.jobId, magaza.id);
      expect(calisan.career.level, 0);
      expect(calisan.career.yearlySalary, magaza.yearlySalary);
      expect(calisan.career.title, 'Mağaza çalışanı');
      expect(calisan.career.allEntries(), hasLength(1));
      expect(calisan.career.milestones.single.age, calisan.player.age);
    });

    test('istifa eski işi silmez, ayrılış yaşı ve nedeni yazılır', () {
      GameState s = iseGir(mezun(age: 25), magaza);
      s = s.copyWith(player: s.player.copyWith(age: 30));
      s = market.quit(s).state;

      expect(s.career.isEmployed, isFalse);
      expect(s.career.history, hasLength(1));
      final JobHistoryEntry kayit = s.career.history.single;
      expect(kayit.jobId, magaza.id);
      expect(kayit.startedAtAge, 25);
      expect(kayit.endedAtAge, 30);
      expect(kayit.endReason, JobEndReason.istifa);
      expect(kayit.years, 5);
      // Eski davranış da korunur.
      expect(s.career.pastJobIds, contains(magaza.id));
    });

    test('ikinci işe girince birinci iş geçmişte kalır', () {
      GameState s = iseGir(mezun(age: 25), magaza);
      s = s.copyWith(player: s.player.copyWith(age: 28));
      s = market.quit(s).state;
      final JobType garson = jobById('garson')!;
      s = iseGir(s, garson, 7);

      expect(s.career.jobId, garson.id);
      expect(s.career.history, hasLength(1));
      expect(s.career.history.single.jobId, magaza.id);
      expect(s.career.allEntries(), hasLength(2));
    });

    test('eski kayıtta kariyer geçmişi yok ama iş kaydı bozulmaz', () {
      // Desteklenen en eski kayıt (sürüm 23): seviye, maaş ve geçmiş
      // alanları hiç yok. Taban beş sürümlük pencereyle birlikte
      // yükseldiği için sürüm numarası da güncellenir.
      final GameState calisan = iseGir(mezun(), magaza);
      final Map<String, Object?> body =
          Map<String, Object?>.from(encodeGameState(calisan));
      final Map<String, Object?> career =
          Map<String, Object?>.from(body['career']! as Map<String, Object?>)
            ..remove('level')
            ..remove('salary')
            ..remove('milestones')
            ..remove('history')
            ..remove('lastRaiseAge')
            ..remove('lastPromotionAge')
            ..remove('lastJobLossAge');
      body['career'] = career;

      final GameState geri =
          decodeGameState(SaveMigrations.migrate(body, kMinReadableSaveVersion));
      expect(geri.career.jobId, magaza.id);
      expect(geri.career.level, 0);
      expect(geri.career.history, isEmpty);
      // Maaş bilinmiyorsa katalog maaşı geçerlidir; uydurma değer yok.
      expect(geri.career.yearlySalary, magaza.yearlySalary);
    });

    test('kayıt sürümü 30 ve kariyer geçmişi kayda girer', () {
      expect(kSaveFormatVersion, 30);
      GameState s = iseGir(mezun(age: 25), magaza);
      s = kabulEdilenTalep(s, terfi: false);
      s = market.quit(s).state;

      final GameState geri = decodeGameState(encodeGameState(s));
      expect(geri.career.history, hasLength(1));
      expect(geri.career.history.single.endReason, JobEndReason.istifa);
      expect(geri.career.history.single.milestones, isNotEmpty);
    });
  });

  // ===================================================================
  // Zam ve terfi
  // ===================================================================
  group('Zam ve terfi', () {
    test('işe girdiği yıl zam istenemez', () {
      final GameState calisan = iseGir(mezun(age: 25), magaza);
      expect(CareerProgress.raiseAvailability(calisan).isAllowed, isFalse);
    });

    test('aynı yıl ikinci kez zam istenemez', () {
      GameState s = iseGir(mezun(age: 25), magaza);
      s = s.copyWith(player: s.player.copyWith(age: 27));
      final CareerRequestResult ilk = CareerProgress.askForRaise(s, Random(3));
      expect(ilk.applied, isTrue);

      final CareerRequestResult ikinci =
          CareerProgress.askForRaise(ilk.state, Random(4));
      expect(ikinci.applied, isFalse);
      expect(ikinci.state.career.yearlySalary, ilk.state.career.yearlySalary);
    });

    test('zam kabul edilirse maaş gerçekten artar ve kayda geçer', () {
      GameState s = iseGir(mezun(age: 25), magaza);
      s = s.copyWith(player: s.player.copyWith(age: 27));
      final int eski = s.career.yearlySalary;
      s = kabulEdilenTalep(s, terfi: false);

      expect(s.career.yearlySalary, greaterThan(eski));
      expect(s.career.lastRaiseAge, isNotNull);
      expect(
        s.career.milestones.any((CareerMilestone m) => m.text.contains('zam')),
        isTrue,
      );
    });

    test('zam garanti değildir', () {
      GameState s = iseGir(mezun(age: 25, intelligence: 20, charisma: 20),
          magaza);
      s = s.copyWith(player: s.player.copyWith(age: 27));
      int ret = 0;
      for (int i = 0; i < 30; i++) {
        final CareerRequestResult r = CareerProgress.askForRaise(
          s.copyWith(interactionCounts: const <String, int>{}),
          Random(i),
        );
        if (!r.accepted) ret++;
      }
      expect(ret, greaterThan(0), reason: 'Her talep kabul edilmemeli');
    });

    test('terfi unvanı ve maaşı birlikte değiştirir', () {
      GameState s = iseGir(mezun(age: 25), magaza);
      s = s.copyWith(player: s.player.copyWith(age: 29));
      final int eskiMaas = s.career.yearlySalary;
      s = kabulEdilenTalep(s, terfi: true);

      expect(s.career.level, 1);
      expect(s.career.title, 'Kıdemli mağaza çalışanı');
      expect(s.career.yearlySalary, greaterThan(eskiMaas));
      expect(s.career.lastPromotionAge, isNotNull);
    });

    test('en üst görevde terfi istenemez', () {
      GameState s = iseGir(mezun(age: 25), magaza);
      s = s.copyWith(
        player: s.player.copyWith(age: 40),
        career: s.career.copyWith(level: magaza.maxLevel),
      );
      expect(CareerProgress.promotionAvailability(s).isAllowed, isFalse);
    });

    test('iş hayatındaki kararlar kabul ihtimalini etkiler', () {
      GameState s = iseGir(mezun(age: 25), magaza);
      s = s.copyWith(player: s.player.copyWith(age: 30));

      final double notr = CareerProgress.prototypeOnlyChance(s, terfi: false);
      final double iyi = CareerProgress.prototypeOnlyChance(
        s.copyWith(storyFlags: <String>{CareerProgress.flagSorumlulukAldi}),
        terfi: false,
      );
      final double kotu = CareerProgress.prototypeOnlyChance(
        s.copyWith(storyFlags: <String>{CareerProgress.flagIsiSavsakladi}),
        terfi: false,
      );
      expect(iyi, greaterThan(notr));
      expect(kotu, lessThan(notr));
    });

    test('zam kapat-aç ile iki kez uygulanmaz', () {
      GameState s = iseGir(mezun(age: 25), magaza);
      s = s.copyWith(player: s.player.copyWith(age: 27));
      s = kabulEdilenTalep(s, terfi: false);
      final int maas = s.career.yearlySalary;

      final GameState geri = decodeGameState(encodeGameState(s));
      expect(geri.career.yearlySalary, maas);
      // Aynı yıl yeniden istenemez: sayaç da kayda girer.
      expect(CareerProgress.raiseAvailability(geri).isAllowed, isFalse);
    });
  });

  // ===================================================================
  // Maaş ve işsizlik
  // ===================================================================
  group('Maaş ve işsizlik', () {
    test('maaş yılda bir kez ödenir', () {
      final GameState s = iseGir(mezun(age: 25, wallet: 0), magaza);
      final int cuzdan = s.player.wallet;

      final ({GameState state, String? logText}) ilk =
          market.paySalaryFor(s.copyWith(
        player: s.player.copyWith(age: 26),
      ), 26);
      expect(ilk.state.player.wallet, cuzdan + s.career.yearlySalary);

      // Aynı yaş için ikinci ödeme yapılmaz.
      final ({GameState state, String? logText}) ikinci =
          market.paySalaryFor(ilk.state, 26);
      expect(ikinci.state.player.wallet, ilk.state.player.wallet);
      expect(ikinci.logText, isNull);
    });

    test('zamlı maaş ödenir, katalog maaşı değil', () {
      GameState s = iseGir(mezun(age: 25, wallet: 0), magaza);
      s = s.copyWith(player: s.player.copyWith(age: 27));
      s = kabulEdilenTalep(s, terfi: false);
      final int maas = s.career.yearlySalary;
      final int cuzdan = s.player.wallet;
      final int yeniYas = s.player.age + 1;

      final ({GameState state, String? logText}) odeme = market.paySalaryFor(
        s.copyWith(player: s.player.copyWith(age: yeniYas)),
        yeniYas,
      );
      expect(odeme.state.player.wallet, cuzdan + maas);
      expect(maas, isNot(magaza.yearlySalary));
    });

    test('iş değişiminde çift maaş oluşmaz', () {
      GameState s = iseGir(mezun(age: 25, wallet: 0), magaza);
      s = s.copyWith(player: s.player.copyWith(age: 28));
      s = market.quit(s).state;
      final JobType garson = jobById('garson')!;
      s = iseGir(s, garson, 9);

      final int cuzdan = s.player.wallet;
      final ({GameState state, String? logText}) odeme = market.paySalaryFor(
        s.copyWith(player: s.player.copyWith(age: 29)),
        29,
      );
      // Yalnızca yeni işin maaşı girer; eski işten ikinci ödeme gelmez.
      expect(odeme.state.player.wallet, cuzdan + garson.yearlySalary);
    });

    test('işsiz kalınca maaş ödenmez ama geçmiş durur', () {
      GameState s = iseGir(mezun(age: 25, wallet: 0), magaza);
      s = s.copyWith(player: s.player.copyWith(age: 28));
      s = market.quit(s).state;

      final int cuzdan = s.player.wallet;
      final ({GameState state, String? logText}) odeme =
          market.paySalaryFor(s, 29);
      expect(odeme.state.player.wallet, cuzdan);
      expect(odeme.logText, isNull);
      expect(s.career.history, hasLength(1));
      // İş başvurusu yeniden mümkün.
      expect(market.openJobs(s), isNotEmpty);
    });

    test('işten çıkarılma yeni çalışanda ve üst üste olmaz', () {
      final GameState yeni = iseGir(mezun(age: 25), magaza);
      // İşe gireli bir yıl olmuş: çıkarılma denenmez.
      expect(
        CareerProgress.maybeLayoff(yeni, 26, Random(1)).state.career.isEmployed,
        isTrue,
      );

      final GameState yakinda = yeni.copyWith(
        career: yeni.career.copyWith(lastJobLossAge: 30),
        player: yeni.player.copyWith(age: 32),
      );
      // Son kayıptan bu yana bekleme süresi dolmadı.
      expect(
        CareerProgress.maybeLayoff(yakinda, 32, Random(2))
            .state
            .career
            .isEmployed,
        isTrue,
      );
    });

    test('işten çıkarılınca kayıt "çıkarıldı" olarak kapanır', () {
      GameState s = iseGir(mezun(age: 25), magaza);
      s = s.copyWith(player: s.player.copyWith(age: 35));

      ({GameState state, String? logText})? sonuc;
      for (int i = 0; i < 400 && sonuc == null; i++) {
        final ({GameState state, String? logText}) deneme =
            CareerProgress.maybeLayoff(s, 35, Random(i));
        if (deneme.logText != null) sonuc = deneme;
      }
      expect(sonuc, isNotNull, reason: 'İşten çıkarılma hiç gerçekleşmedi');

      final CareerState career = sonuc!.state.career;
      expect(career.isEmployed, isFalse);
      expect(career.history.single.endReason, JobEndReason.cikarildi);
      expect(career.history.single.endedAtAge, 35);
      expect(career.lastJobLossAge, 35);
    });
  });

  // ===================================================================
  // İş arkadaşları
  // ===================================================================
  group('İş arkadaşları', () {
    test('işe girince gerçek kişilerle tanışılır', () {
      final GameState s = iseGir(mezun(age: 25), magaza);
      final List<Person> arkadaslar = Colleagues.atWork(s);

      expect(arkadaslar, hasLength(Colleagues.prototypeOnlyCount));
      for (final Person p in arkadaslar) {
        expect(p.relation, RelationType.isArkadasi);
        expect(p.workplaceId, magaza.id);
        // Aynı evde yaşıyormuş gibi gösterilmez.
        expect(p.inPlayerHousehold, isFalse);
        expect(p.city, s.player.currentCity);
        expect(s.isReachable(p), isTrue);
      }
      expect(checkInvariants(s), isEmpty);
    });

    test('işten ayrılınca kayıt silinmez, gündelik erişim biter', () {
      GameState s = iseGir(mezun(age: 25), magaza);
      final List<String> kimlikler =
          Colleagues.atWork(s).map((Person p) => p.id).toList();
      // Yakınlığı düşük tut: arkadaşlığa dönüşmesin.
      s = s.copyWith(
        people: s.people
            .map((Person p) => kimlikler.contains(p.id)
                ? p.copyWith(bond: 30)
                : p)
            .toList(growable: false),
        player: s.player.copyWith(age: 30),
      );
      s = market.quit(s).state;

      for (final String id in kimlikler) {
        final Person? kisi = s.personById(id);
        expect(kisi, isNotNull, reason: 'İş arkadaşı silinmemeli');
        expect(kisi!.relation, RelationType.isArkadasi);
        expect(s.isReachable(kisi), isFalse);
      }
    });

    test('yakın olunan iş arkadaşı arkadaşlığa dönüşür', () {
      GameState s = iseGir(mezun(age: 25), magaza);
      final String id = Colleagues.atWork(s).first.id;
      s = s.copyWith(
        people: s.people
            .map((Person p) => p.id == id
                ? p.copyWith(bond: Colleagues.prototypeOnlyFriendshipBond + 10)
                : p)
            .toList(growable: false),
        player: s.player.copyWith(age: 30),
      );
      s = market.quit(s).state;

      final Person arkadas = s.personById(id)!;
      expect(arkadas.relation, RelationType.arkadas);
      // Kimlik ve geçmiş korunur.
      expect(arkadas.workplaceId, magaza.id);
      expect(s.isReachable(arkadas), isTrue);
    });

    test('iş arkadaşı kaydı kapat-aç ile korunur', () {
      final GameState s = iseGir(mezun(age: 25), magaza);
      final Person ilk = Colleagues.atWork(s).first;
      final GameState geri = decodeGameState(encodeGameState(s));
      final Person? sonra = geri.personById(ilk.id);

      expect(sonra, isNotNull);
      expect(sonra!.firstName, ilk.firstName);
      expect(sonra.workplaceId, magaza.id);
      expect(sonra.relation, RelationType.isArkadasi);
    });

    test('aynı işe dönünce ikinci kez iş arkadaşı üretilmez', () {
      GameState s = iseGir(mezun(age: 25), magaza);
      final int ilkSayi = s.people.length;
      // D-091 ile aynı işe yılda **bir** başvuru hakkı var. Gerçek
      // oyunda tekrar sayaçları yaş ilerleyince sıfırlanır; burada yaş
      // elle değiştirildiği için sayaç da elle sıfırlanıyor.
      s = s.copyWith(
        player: s.player.copyWith(age: 30),
        interactionCounts: const <String, int>{},
      );
      s = market.quit(s).state;
      s = iseGir(s, magaza, 11);

      expect(s.people.length, ilkSayi);
    });
  });

  // ===================================================================
  // Uçtan uca zincir
  // ===================================================================
  test('işe giriş → çalışma → zam → terfi → istifa → yeni iş', () {
    GameState s = iseGir(mezun(age: 25, wallet: 0), magaza);

    // Birkaç yıl çalış: maaş her yıl bir kez girer.
    int beklenen = 0;
    for (int yas = 26; yas <= 28; yas++) {
      final ({GameState state, String? logText}) odeme = market.paySalaryFor(
        s.copyWith(player: s.player.copyWith(age: yas)),
        yas,
      );
      beklenen += s.career.yearlySalary;
      s = odeme.state;
    }
    expect(s.player.wallet, beklenen);

    // Zam ve terfi.
    s = kabulEdilenTalep(s, terfi: false);
    expect(s.career.yearlySalary, greaterThan(magaza.yearlySalary));
    s = kabulEdilenTalep(s, terfi: true);
    expect(s.career.level, greaterThan(0));

    // İstifa ve yeni iş.
    s = market.quit(s).state;
    final JobType garson = jobById('garson')!;
    s = iseGir(s, garson, 13);

    expect(s.career.jobId, garson.id);
    expect(s.career.level, 0, reason: 'Yeni işte kıdem sıfırdan başlar');
    expect(s.career.history.single.jobId, magaza.id);
    expect(s.career.history.single.level, greaterThan(0));

    // Kayıt turu: hiçbir şey kaybolmaz.
    final GameState geri = decodeGameState(encodeGameState(s));
    expect(geri.career.jobId, garson.id);
    expect(geri.career.history.single.jobId, magaza.id);
    expect(checkInvariants(geri), isEmpty);
  });

  test('yaş alma akışı maaşı bir kez öder', () {
    final GameState calisan = iseGir(mezun(age: 25, wallet: 0), magaza);
    final GameState sonra = LifeProgression(Random(5)).advanceOneYear(
      calisan.copyWith(pendingEvent: null),
    );

    // Maaş günlüğe **bir** satır yazar ve ödeme dönemi ilerler.
    final Iterable<String> maasSatirlari = sonra.log
        .where((LifeLogEntry e) => e.text.contains('cüzdanına girdi'))
        .map((LifeLogEntry e) => e.text);
    expect(maasSatirlari, hasLength(1));
    expect(sonra.career.lastPaidAge, sonra.player.age);

    // Cüzdan gerçekten arttı: geçim gideri düşülse bile işsiz hâlden
    // yüksek kalır.
    final GameState issiz = LifeProgression(Random(5)).advanceOneYear(
      calisan
          .copyWith(career: const CareerState.none(), pendingEvent: null),
    );
    expect(sonra.player.wallet, greaterThan(issiz.player.wallet));
  });
}

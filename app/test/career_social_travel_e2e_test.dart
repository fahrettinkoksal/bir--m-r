import 'dart:math';

import 'package:bir_omur/data/job_catalog.dart';
import 'package:bir_omur/data/save/game_state_codec.dart';
import 'package:bir_omur/data/save/save_format.dart';
import 'package:bir_omur/data/social_catalog.dart';
import 'package:bir_omur/domain/activities/travel.dart';
import 'package:bir_omur/domain/career/career_progress.dart';
import 'package:bir_omur/domain/career/colleagues.dart';
import 'package:bir_omur/domain/career/job_market.dart';
import 'package:bir_omur/domain/generation/life_generator.dart';
import 'package:bir_omur/domain/generation/life_progression.dart';
import 'package:bir_omur/domain/models/career.dart';
import 'package:bir_omur/domain/models/education.dart';
import 'package:bir_omur/domain/models/game_state.dart';
import 'package:bir_omur/domain/models/gender.dart';
import 'package:bir_omur/domain/models/person.dart';
import 'package:bir_omur/domain/models/relation.dart';
import 'package:bir_omur/domain/models/social_account.dart';
import 'package:bir_omur/domain/models/sponsorship.dart';
import 'package:bir_omur/domain/models/trip.dart';
import 'package:bir_omur/domain/social/social_engine.dart';
import 'package:bir_omur/domain/social/social_income.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/generation_fixtures.dart';
import 'support/invariants.dart';

const JobMarket market = JobMarket();
const SocialEngine sosyal = SocialEngine();

GameState iseGir(GameState state, JobType job, [int seed = 1]) {
  final JobResult basvuru = market.apply(state, job, Random(seed));
  final dynamic soru = basvuru.state.pendingInterview!.question!;
  final JobResult cevap = market.answerInterview(
    basvuru.state,
    soru.correctIndex as int,
    Random(seed),
  );
  expect(cevap.outcome.accepted, isTrue);
  return cevap.state;
}

GameState kabulEdilenZam(GameState state) {
  GameState s = state;
  for (int i = 0; i < 60; i++) {
    final CareerRequestResult r = CareerProgress.askForRaise(s, Random(i));
    if (r.accepted) return r.state;
    s = (r.applied ? r.state : s).copyWith(
      player: s.player.copyWith(age: s.player.age + 1),
      interactionCounts: const <String, int>{},
    );
  }
  fail('Zam hiç kabul edilmedi.');
}

void main() {
  test('eğitim → iş → maaş → zam → iş değişimi → sosyal medya → gelir → '
      'gezi → yaş alma → kapat/aç zinciri bütünlüğü korur', () {
    final JobType magaza = jobById('magaza_calisani')!;
    final JobType garson = jobById('garson')!;

    // --- Eğitimini bitirmiş bir yetişkin -----------------------------
    final GameState base =
        LifeGenerator.seeded(101).generate(mode: StartMode.tamamenRastgele);
    GameState s = base.copyWith(
      pendingEvent: null,
      player: base.player.copyWith(age: 24, wallet: 0, fame: 6),
      education: const EducationState(finished: true, startedAtAge: 6),
      people: <Person>[
        // Sevgili: evlilik kaydı gerektirmeden hane ve gezi kurallarını
        // sınamak için yeterli.
        kisi(
          id: 'sevgili-1',
          relation: RelationType.sevgili,
          gender: Gender.kadin,
          age: 25,
          firstName: 'Elif',
          city: base.player.currentCity,
        ),
      ],
    );

    // --- İşe girer ---------------------------------------------------
    s = iseGir(s, magaza);
    final List<String> isArkadaslari =
        Colleagues.atWork(s).map((Person p) => p.id).toList();
    expect(isArkadaslari, hasLength(Colleagues.prototypeOnlyCount));

    // --- Yıllık maaş alır --------------------------------------------
    for (int yas = 25; yas <= 27; yas++) {
      final ({GameState state, String? logText}) odeme = market.paySalaryFor(
        s.copyWith(player: s.player.copyWith(age: yas)),
        yas,
      );
      expect(odeme.logText, isNotNull);
      s = odeme.state;
    }
    expect(s.player.wallet, magaza.yearlySalary * 3);

    // --- Zam ister ---------------------------------------------------
    s = kabulEdilenZam(s);
    final int zamliMaas = s.career.yearlySalary;
    expect(zamliMaas, greaterThan(magaza.yearlySalary));

    // --- İş değiştirir -----------------------------------------------
    s = market.quit(s).state;
    s = iseGir(s, garson, 5);
    expect(s.career.jobId, garson.id);
    expect(s.career.history.single.jobId, magaza.id);
    expect(s.career.history.single.endReason, JobEndReason.istifa);

    // --- Sosyal medya hesabı açar ------------------------------------
    s = sosyal.openAccount(s, SocialPlatform.video).state;
    expect(s.socialAccounts, hasLength(1));

    // Kitle oluşur (hesap bir yıl önce açılmış sayılır).
    s = s.copyWith(
      socialAccounts: <SocialAccount>[
        s.socialAccounts.single.copyWith(followers: 6000),
      ],
      player: s.player.copyWith(age: s.player.age + 1),
    );

    // --- İçerik üretir ve gelir elde eder ----------------------------
    final SocialContent icerik = contentsFor(SocialPlatform.video).first;
    int kazanc = 0;
    for (int i = 0; i < 200 && kazanc == 0; i++) {
      final SocialResult r = sosyal.post(s, icerik, Random(i));
      if (r.outcome.earned > 0) {
        kazanc = r.outcome.earned;
        s = r.state;
      }
    }
    expect(kazanc, greaterThan(0));
    expect(s.totalSocialEarnings, kazanc);

    // --- Sponsorluk kabul eder ve paylaşımını yapar ------------------
    SponsorOffer? teklif;
    for (int i = 0; i < 300 && teklif == null; i++) {
      teklif = SocialIncome.maybeOffer(s, Random(i));
    }
    expect(teklif, isNotNull);
    s = sosyal.acceptSponsor(s.copyWith(sponsorOffer: teklif)).state;
    final int cuzdanOncesi = s.player.wallet;
    s = sosyal.post(s, icerik, Random(7)).state;
    expect(s.player.wallet, greaterThanOrEqualTo(cuzdanOncesi + teklif!.fee));
    expect(s.openDeals, isEmpty);

    // --- Sevgilisiyle geziye gider -----------------------------------
    final String sehir = Travel.destinations(s).first;
    final int cuzdanGeziOncesi = s.player.wallet;
    final TripResult gezi = Travel.take(
      s,
      mode: TravelMode.tren,
      city: sehir,
      companionId: 'sevgili-1',
      rng: Random(8),
    );
    expect(gezi.outcome.applied, isTrue);
    s = gezi.state;
    expect(
      s.player.wallet,
      cuzdanGeziOncesi - Travel.costOf(TravelMode.tren, withCompanion: true),
    );
    expect(s.player.currentCity, isNot(sehir));

    // --- Yaş alır -----------------------------------------------------
    final int oncekiYas = s.player.age;
    s = LifeProgression(Random(9)).advanceOneYear(s.copyWith(
      pendingEvent: null,
    ));
    expect(s.player.age, oncekiYas + 1);

    // --- Oyunu kapatıp açar -------------------------------------------
    final GameState geri = decodeGameState(encodeGameState(s));

    // Kişi kimlikleri ve ilişkiler korunur.
    expect(geri.personById('sevgili-1')!.firstName, 'Elif');
    for (final String id in isArkadaslari) {
      expect(geri.personById(id), isNotNull);
    }
    // İş geçmişi korunur.
    expect(geri.career.jobId, garson.id);
    expect(geri.career.history.single.jobId, magaza.id);
    // Sosyal medya geçmişi ve geliri korunur.
    expect(geri.socialAccounts.single.posts, isNotEmpty);
    expect(geri.totalSocialEarnings, s.totalSocialEarnings);
    expect(geri.sponsorDeals.single.completedAtAge, isNotNull);
    // Gezi anısı korunur.
    expect(geri.trips.single.city, sehir);
    expect(geri.trips.single.companionId, 'sevgili-1');
    expect(geri.trips.single.note, isNotNull);
    // Cüzdan ve tutarlılık.
    expect(geri.player.wallet, s.player.wallet);
    expect(checkInvariants(geri), isEmpty);
  });

  test('desteklenen her sürümden giriş yapılabilir', () {
    // Güncel bir kayıt üretip yeni alanları sürüm sürüm çıkararak eski
    // kayıt taklidi yapılır. **Gerçek eski kullanıcı kaydı yoktur;
    // bu sınama yalnızca sentetiktir.**
    final GameState base =
        LifeGenerator.seeded(102).generate(mode: StartMode.tamamenRastgele);
    final Map<String, Object?> guncel =
        Map<String, Object?>.from(encodeGameState(base));

    // Faho'nun kararı (Paket 12): geriye dönük yalnızca son beş sürüm
    // taşınır; taban `kMinReadableSaveVersion`.
    for (int from = kMinReadableSaveVersion;
        from <= kSaveFormatVersion;
        from++) {
      final Map<String, Object?> govde = Map<String, Object?>.from(guncel);
      if (from <= 24) govde.remove('trips');
      if (from <= 23) {
        govde..remove('sponsorOffer')..remove('sponsorDeals');
      }
      if (from <= 22) {
        final Map<String, Object?> career =
            Map<String, Object?>.from(govde['career']! as Map<String, Object?>)
              ..remove('level')
              ..remove('salary')
              ..remove('milestones')
              ..remove('history')
              ..remove('lastRaiseAge')
              ..remove('lastPromotionAge')
              ..remove('lastJobLossAge');
        govde['career'] = career;
      }
      if (from <= 25) govde['career'] = _emekliliksiz(govde);

      final GameState acilan =
          decodeGameState(SaveMigrations.migrate(govde, from));
      expect(acilan.player.firstName, base.player.firstName,
          reason: 'Sürüm $from açılmadı');
      expect(checkInvariants(acilan), isEmpty, reason: 'Sürüm $from tutarsız');
    }
  });
}


/// Emeklilik alanları olmayan (sürüm 25 ve öncesi) kariyer gövdesi.
Map<String, Object?> _emekliliksiz(Map<String, Object?> govde) {
  final Map<String, Object?> career =
      Map<String, Object?>.from(govde['career']! as Map<String, Object?>)
        ..remove('retiredAtAge')
        ..remove('pension');
  return career;
}

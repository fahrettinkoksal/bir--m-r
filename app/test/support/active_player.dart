import 'dart:math';

import 'package:bir_omur/data/activity_catalog.dart';
import 'package:bir_omur/data/job_catalog.dart';
import 'package:bir_omur/data/health_crisis_catalog.dart';
import 'package:bir_omur/data/social_catalog.dart';
import 'package:bir_omur/data/university_catalog.dart';
import 'package:bir_omur/domain/models/pending_crisis.dart';
import 'package:bir_omur/domain/models/pending_wedding.dart';
import 'package:bir_omur/domain/models/person.dart';
import 'package:bir_omur/domain/models/relation.dart';
import 'package:bir_omur/domain/models/trip.dart';
import 'package:bir_omur/domain/generation/life_generator.dart';
import 'package:bir_omur/domain/models/game_event.dart';
import 'package:bir_omur/domain/models/game_state.dart';
import 'package:bir_omur/state/game_controller.dart';

import 'test_flow.dart';

/// Bir aktif oyuncu hayatının sonucu.
class ActiveLifeResult {
  const ActiveLifeResult({
    required this.seenEvents,
    required this.storyFlags,
    required this.repeats,
    required this.finalAge,
    required this.tookJob,
    required this.hadHobby,
    required this.traveled,
    required this.openedSocial,
    required this.retired,
    required this.married,
    required this.hadChild,
    this.eventAges = const <String, int>{},
  });

  /// Bu hayatta sunulan olayların kimlikleri.
  final Set<String> seenEvents;

  /// Hayat boyunca konan hikâye izleri.
  final Set<String> storyFlags;

  /// Olay kimliği -> bu hayatta kaç kez çıktığı.
  final Map<String, int> repeats;

  final int finalAge;
  final bool tookJob;
  final bool hadHobby;
  final bool traveled;
  final bool openedSocial;
  final bool retired;
  final bool married;
  final bool hadChild;

  /// Olay kimliği -> ilk görüldüğü yaş (ölçüm için).
  final Map<String, int> eventAges;
}

/// **Aktif oyuncu** simülasyonu.
///
/// Eski ölçüm simülasyonu yalnızca yaş alıp olayları cevaplıyordu; işe
/// girmiyor, hobi edinmiyor, geziye çıkmıyor, sosyal medya açmıyordu. Bu
/// yüzden "hiç çıkmayan olay" listesinin büyük bölümü aslında *ulaşılamaz*
/// değil, *uğranılmamış* içerikti (`docs/EKSIKLER.md`).
///
/// Bu yardımcı oyuncunun yaptıklarını yapar: okula devam eder, alan ve
/// bölüm seçer, iş arar, mülakata girer, hobi edinir, geziye çıkar,
/// sosyal medya hesabı açar ve yaşı gelince emekli olur. Böylece koşullu
/// içeriğin **gerçek** erişilebilirliği ölçülebilir.
ActiveLifeResult playActiveLife(int seed, {bool recordAges = false}) {
  final GameController c = GameController(random: Random(seed));
  c.startNewLife(mode: StartMode.tamamenRastgele);
  final Random secim = Random(seed * 31 + 5);

  final Set<String> gorulen = <String>{};
  final Set<String> izler = <String>{};
  final Map<String, int> tekrar = <String, int>{};
  final Map<String, int> olayYasi = <String, int>{};
  bool iseGirdi = false;
  bool evlendi = false;
  bool cocukOldu = false;
  bool hobiYapti = false;
  bool geziYapti = false;
  bool sosyalActi = false;
  bool emekliOldu = false;

  int guard = 0;
  while (!c.state!.deceased && guard++ < 4000) {
    final GameState s = c.state!;

    // 1) Bekleyen olay varsa cevapla.
    final ActiveEvent? olay = s.pendingEvent;
    if (olay != null) {
      gorulen.add(olay.eventId);
      tekrar[olay.eventId] = (tekrar[olay.eventId] ?? 0) + 1;
      if (recordAges) olayYasi.putIfAbsent(olay.eventId, () => s.player.age);
      final List<EventChoice> sec = olay.choices;
      c.chooseEventOption(sec[secim.nextInt(sec.length)].id);
      continue;
    }

    // 2) Kriz varsa karşılanabilir bir seçenekle kapat.
    final PendingCrisis? kriz = s.pendingCrisis;
    if (kriz != null) {
      final HealthCrisis? katalog = healthCrisisById(kriz.crisisId);
      final List<CrisisChoice> acik = katalog == null
          ? const <CrisisChoice>[]
          : katalog.choices
              .where((CrisisChoice ch) => c.canChooseCrisis(ch))
              .toList(growable: false);
      if (acik.isEmpty) break;
      c.respondToCrisis(acik[secim.nextInt(acik.length)].id);
      continue;
    }

    // 3) Bildirimleri kapat.
    if (s.hasNotice) {
      c.dismissNotice();
      continue;
    }

    izler.addAll(s.storyFlags);

    // 4) Eğitim kararı bekliyorsa ver (üniversiteye de gitmeyi dener).
    if (c.needsTrackChoice) {
      resolveTrackChoice(c);
      continue;
    }
    if (c.needsAfterSchoolChoice) {
      final List<UniversityProgram> bolumler = c.availablePrograms();
      final List<UniversityProgram> acik = bolumler
          .where((UniversityProgram p) => c.programBlockReason(p).isEmpty)
          .toList(growable: false);
      if (acik.isNotEmpty && secim.nextBool()) {
        c.applyToUniversity(acik[secim.nextInt(acik.length)]);
      } else {
        c.skipUniversity();
      }
      continue;
    }

    // 5) İş: çalışmıyorsa başvurur, mülakata girerse cevaplar.
    if (s.pendingInterview != null) {
      c.answerInterview(secim.nextInt(2));
      continue;
    }
    if (!s.career.isEmployed && s.player.age >= 18 && !emekliOldu) {
      final List<JobType> isler = c.openJobs();
      if (isler.isNotEmpty) {
        c.applyForJob(isler[secim.nextInt(isler.length)]);
        continue;
      }
    }
    // İşe girmek mülakattan **sonra** gerçekleşir; bayrak burada okunur.
    if (s.career.isEmployed) iseGirdi = true;

    // 6) Emeklilik yaşı geldiyse emekli ol.
    if (!emekliOldu && c.retirementAvailability().isAllowed) {
      c.retire();
      emekliOldu = true;
      continue;
    }

    // 7) Hobi ve aktivite.
    //
    // **Yılda birkaç eylem** yapılır: motor, aynı yaşta ek olay için
    // ilerleme eşiği arıyor (EventEngine.prototypeOnlyProgressPerExtraEvent).
    // Tek eylem yapan simülasyon o eşiği hiç geçmiyor ve aynı okul yılına
    // sığması gereken zincirler (sınav zinciri) hiç açılmıyordu.
    if (s.player.age >= 8) {
      for (final String id in <String>[
        'muzik_kursu', 'kosu', 'kitap_oku', 'sinema', 'berber_sac'
      ]) {
        // Her aktivite artık bildirim üretiyor (D-114); bildirimi
        // kapatmadan sıradakine geçilemez. Bekleyen olay çıktıysa
        // döngüden çıkılır, olay ana döngüde cevaplanır.
        while (c.state!.hasNotice) {
          c.dismissNotice();
        }
        if (c.state!.hasPendingEvent) break;
        final ActivityAction? a = _actionById(id);
        if (a == null) continue;
        if (c.activityAvailability(a).isAllowed) {
          c.performActivity(a);
          hobiYapti = true;
        }
      }
      while (c.state!.hasNotice) {
        c.dismissNotice();
      }
      if (c.state!.hasPendingEvent) continue;
    }

    // 8) Sosyal medya: 16 yaşından sonra bir hesap aç ve paylaş.
    if (s.player.age >= 16 && s.socialAccounts.isEmpty) {
      for (final SocialPlatform p in SocialPlatform.values) {
        if (c.socialAccountAvailability(p).isAllowed) {
          c.openSocialAccount(p);
          sosyalActi = true;
          break;
        }
      }
    }
    if (c.state!.socialAccounts.isNotEmpty) {
      final SocialPlatform p = c.state!.socialAccounts.first.platform;
      final List<SocialContent> icerik = contentsFor(p);
      if (icerik.isNotEmpty && c.remainingSocialPosts(p) > 0) {
        c.postContent(icerik[secim.nextInt(icerik.length)]);
      }
    }

    // 9) İlişki: flörtü sevgiliye, sevgiliyi eşe çevir.
    //
    // Evlilik ve çocuk olmadan aile olaylarının yarısı hiç açılmıyor;
    // gerçek oyuncu bunları yapıyor, simülasyon da yapmalı.
    for (final Person p in c.state!.people) {
      if (!p.isAlive) continue;
      if (p.relation == RelationType.flort) {
        c.makeRelationshipOfficial(p.id);
        break;
      }
      if (p.relation == RelationType.sevgili &&
          c.state!.marriage == null &&
          c.state!.player.age >= 22) {
        c.propose(p.id);
        break;
      }
    }
    // Nişan/teklif kabul edildiyse düğünü tamamla.
    final PendingWedding? dugun = c.state!.pendingWedding;
    if (dugun != null) {
      c.marry(dugun.spouseId);
      evlendi = true;
    }

    // 10) Çocuk: eş varsa ara sıra dene.
    if (c.state!.marriage != null &&
        c.state!.player.age >= 24 &&
        secim.nextInt(4) == 0 &&
        c.childAvailability().isAllowed) {
      c.haveChild();
      cocukOldu = true;
    }

    // 11) Gezi: **yanına birini alarak** — yalnız gezi hatıra saymıyor
    // (Travel.memorableTrip companionId istiyor), o yüzden gezi
    // olayları yalnız gezenlerde hiç açılmıyor.
    if (s.player.age >= 20 &&
        s.player.wallet > 200000 &&
        secim.nextInt(6) == 0) {
      final List<String> sehirler = c.travelDestinations();
      if (sehirler.isNotEmpty) {
        final List<Person> yakinlar = c.state!.people
            .where((Person p) =>
                p.isAlive &&
                (p.relation == RelationType.es ||
                    p.relation == RelationType.arkadas ||
                    p.relation == RelationType.sevgili))
            .toList(growable: false);
        c.takeTrip(
          mode: TravelMode.otobus,
          city: sehirler[secim.nextInt(sehirler.length)],
          companionId:
              yakinlar.isEmpty ? null : yakinlar[secim.nextInt(yakinlar.length)].id,
        );
        geziYapti = true;
      }
    }

    izler.addAll(c.state!.storyFlags);
    resolveEducationChoices(c);
    c.ageUp();
  }

  izler.addAll(c.state!.storyFlags);
  final int yas = c.state!.player.age;
  c.dispose();

  return ActiveLifeResult(
    seenEvents: gorulen,
    storyFlags: izler,
    repeats: tekrar,
    finalAge: yas,
    tookJob: iseGirdi,
    hadHobby: hobiYapti,
    traveled: geziYapti,
    openedSocial: sosyalActi,
    retired: emekliOldu,
    married: evlendi,
    hadChild: cocukOldu,
    eventAges: olayYasi,
  );
}

ActivityAction? _actionById(String id) {
  for (final ActivityAction a in kActivityActions) {
    if (a.id == id) return a;
  }
  return null;
}

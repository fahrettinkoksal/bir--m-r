import 'dart:math';

import '../../data/name_pool.dart';
import '../career/career_progress.dart';
import '../career/retirement.dart';
import '../life/year_review.dart';
import 'grandchildren.dart';
import '../social/social_engine.dart';
import '../../data/media_catalog.dart';
import 'child_marriage.dart';
import '../social/media_opportunities.dart';
import '../social/social_income.dart';
import '../models/sponsorship.dart';
import '../career/job_market.dart';
import '../education/education_path.dart';
import '../education/school_performance.dart';
import '../events/event_engine.dart';
import '../../data/education_tracks.dart';
import '../models/education.dart';
import '../models/game_event.dart';
import '../economy/housing.dart';
import '../economy/living_costs.dart';
import '../../data/health_crisis_catalog.dart';
import '../life/health_crisis_engine.dart';
import '../interaction/marriage_engine.dart';
import '../interaction/parenthood.dart';
import '../life/inheritance.dart';
import '../../data/job_catalog.dart';
import '../economy/business_engine.dart';
import '../interaction/friendship_depth.dart';
import '../law/legal_engine.dart';
import '../life/mortality.dart';
import '../models/game_settings.dart';
import '../models/game_state.dart';
import '../interaction/bond_decay.dart';
import '../interaction/finger.dart';
import '../models/life_log.dart';
import '../models/zodiac.dart';
import '../career/military_service.dart';
import '../casino/lottery.dart';
import '../life/astrology.dart';
import '../../data/fortune_catalog.dart';
import '../models/gender.dart';
import '../models/pregnancy.dart';
import '../models/owned_item.dart';
import '../models/person.dart';
import '../life/aging.dart';
import '../models/stats.dart';
import '../economy/banking.dart';
import '../economy/vehicle_trouble.dart';
import '../effects/effect_diff.dart';
import '../life/hair_loss.dart';
import '../life/sick_leave.dart';
import '../life/upkeep_tracker.dart';
import '../life/notices.dart';
import '../models/pending_notice.dart';
import 'child_progression.dart';
import '../models/relation.dart';
import '../models/wealth.dart';
import 'random_util.dart';
import 'school_people.dart';
import '../../text/turkish_text.dart';
import '../../data/item_catalog.dart';
import '../pets/pet_care.dart';

/// **Yaş Al** işleminin durum üzerindeki etkisi (D-018).
///
/// Oyuncu hazır olduğunda kendi isteğiyle bir yaş ilerler; bir yaşın bütün
/// etkinliklerini bitirmesi gerekmez.
///
/// Yeni yaşa girildiğinde oyuncunun karşısına **ilk olarak yalnızca tek**
/// uygun olay çıkar (D-021); art arda bağımsız olay pencereleri açılmaz.
/// Uygun olay yoksa hiç olay çıkmaz. Gerçek dünya dakikası beklenmez (D-024).
///
/// NPC'lerin bağımsız hayat gelişmeleri (D-010) henüz uygulanmadı.
class LifeProgression {
  LifeProgression(this._rng);

  final Random _rng;

  /// Okula başlama yaşı. Türkiye'de zorunlu eğitim bu yaşta başlar; oyunda
  /// başlamama/geç başlama gibi durumlar henüz tasarlanmadı (prototypeOnly).
  static const int prototypeOnlySchoolStartAge = 6;

  /// Son sınıf. 4+4+4 yapısında lise 12. sınıfta biter.
  static const int lastGrade = 12;

  /// prototypeOnly: hanede bakım verebilecek sayılan yetişkinlik yaşı.
  static const int prototypeOnlyAdultAge = 18;

  /// prototypeOnly: bu sağlık değerinin altında uyarı verilir.
  static const int prototypeOnlyHealthWarningBelow = 25;

  /// prototypeOnly: her yıl mutluluğa geri dönen yas oranı.
  static const double prototypeOnlyGriefRecoveryRatio = 1 / 3;

  GameState advanceOneYear(GameState state) {
    // Ekranda çözülmemiş bir olay varken yaş ilerlemez: olaylar üst üste
    // binmez.
    if (state.hasPendingEvent) return state;

    // Biten yılın özeti yaşlanmadan **önce** hesaplanır: fotoğraf yılın
    // başında alınmıştır, karşılaştırma yılın sonundaki hâlle yapılır
    // (D-096). Özet yoksa (ilk yıl, yeni kayıt) `null` kalır.
    // Hiçbir şey değişmediyse özet üretilmez; eski yılın özeti ekranda
    // bırakılmaz.
    final YearSummary? yilOzeti = YearReview.summarize(state.yearMark, state);

    final int newAge = state.player.age + 1;

    final List<Person> people = state.people
        .map((Person person) => person.isAlive ? _agePerson(person) : person)
        .toList(growable: false);

    // Çocuklar arka planda kendi hayatlarını yaşar (D-045). Önemli
    // ilerleme gerçekleştiği yılda kaydedilir; vefat edenlere dokunulmaz.
    final List<String> cocukHaberleri = <String>[];
    final List<Person> peopleWithChildren = people
        .map((Person person) {
          // Torunlar da kendi hayatlarını yaşar (Paket 12): okula başlar,
          // büyür. Vefat edenlere dokunulmaz.
          final bool kendiHayati =
              person.relation == RelationType.cocuk ||
              person.relation == RelationType.torun;
          if (!person.isAlive || !kendiHayati) {
            return person;
          }
          final ({Person person, List<String> news}) sonuc =
              ChildProgression.advance(person, _rng);
          cocukHaberleri.addAll(sonuc.news);
          return sonuc.person;
        })
        .toList(growable: false);

    // Yetişkin çocuklar kendi hayatlarında evlenir (D-121). Haberin
    // biçimi yakınlığa bağlıdır: yakınsan davet edilirsin, uzaksan
    // sonradan duyarsın.
    final List<PendingNotice> aileBildirimleri = <PendingNotice>[];
    final List<String> aileHaberleri = <String>[];
    final List<Person> evlilikSonrasi = <Person>[];
    for (final Person kisi in peopleWithChildren) {
      final ChildMarriageResult? evlilik = ChildMarriage.maybeMarry(
        child: kisi,
        playerAge: newAge,
        rng: _rng,
      );
      if (evlilik == null) {
        evlilikSonrasi.add(kisi);
        continue;
      }
      evlilikSonrasi.add(evlilik.person);
      aileBildirimleri.add(evlilik.notice);
      aileHaberleri.add(evlilik.logText);
    }
    final List<Person> evlilikliKisiler =
        List<Person>.unmodifiable(evlilikSonrasi);

    // Yetişkin çocukların kendi çocukları olabilir (Paket 12). Torun
    // gerçek bir kişi kaydıdır ve doğduğu yıl oluşturulur.
    final List<Person> yeniTorunlar = <Person>[];
    final List<String> torunHaberleri = <String>[];
    for (final Person cocuk in evlilikliKisiler) {
      final Person? torun = Grandchildren.maybeBorn(
        state: state.copyWith(
          people: List<Person>.unmodifiable(<Person>[
            ...evlilikliKisiler,
            ...yeniTorunlar,
          ]),
        ),
        child: cocuk,
        rng: _rng,
      );
      if (torun == null) continue;
      yeniTorunlar.add(torun);
      final String haber =
          '${cocuk.firstName} bir çocuk sahibi oldu: ${torun.firstName}. '
          'Artık dede/nine oldun.';
      torunHaberleri.add(haber);
      // Torunun doğumu kaçırılmaması gereken bir haberdir (D-121).
      aileBildirimleri.add(
        PendingNotice(
          id: 'torun-${torun.id}-$newAge',
          kind: NoticeKind.aileDonum,
          age: newAge,
          title: 'Torunun oldu',
          text: haber,
          personId: torun.id,
        ),
      );
    }

    final List<LifeLogEntry> log = <LifeLogEntry>[
      ...state.log,
      LifeLogEntry(
        age: newAge,
        text: '$newAge yaşına girdin.',
        category: LogCategory.yasDegisimi,
      ),
      for (final String haber in torunHaberleri)
        LifeLogEntry(age: newAge, text: haber, category: LogCategory.aile),
      for (final String haber in aileHaberleri)
        LifeLogEntry(age: newAge, text: haber, category: LogCategory.aile),
    ];

    // Eğitim durumu yaştan türetilmez; burada açıkça ilerletilir ve
    // anlamlı geçişler hayat günlüğüne yazılır.
    EducationState education = _advanceEducation(
      state.education,
      newAge,
      intelligence: state.player.stats.intelligence,
      log: log,
    );
    education = _applyUniversityExam(
      state: state,
      before: state.education,
      education: education,
      newAge: newAge,
      log: log,
    );
    education = _applyPlacementExam(
      state: state,
      education: education,
      newAge: newAge,
      log: log,
    );
    _logEducationChange(
      log: log,
      before: state.education,
      after: education,
      age: newAge,
    );

    // Okulun dönüm noktaları ekranda açıkça bildirilir (Paket 17).
    // Günlüğe tek satır yazmak yetmiyordu; oyuncu çoğu kez fark etmeden
    // geçiyordu.
    final List<PendingNotice> okulBildirimleri = _schoolNotices(
      before: state.education,
      after: education,
      age: newAge,
    );

    // Yeni bir okul kademesine geçildiyse o kademenin sınıf arkadaşları ve
    // öğretmeni kalıcı kişi kaydı olarak eklenir. Eski kademenin kişileri
    // silinmez; yalnızca güncel sınıf listesinde görünmezler.
    final ({List<Person> people, EducationState education}) okulSonucu =
        _setUpClassIfNeeded(
          state: state,
          people: peopleWithChildren,
          education: education,
          newAge: newAge,
          log: log,
        );
    final List<Person> peopleWithSchool = okulSonucu.people;

    // Çocukların bu yıl yaşadığı önemli gelişmeler aile haberi olarak
    // günlüğe girer; kişinin kendi geçmişinde zaten kayıtlıdır.
    for (final String haber in cocukHaberleri) {
      log.add(
        LifeLogEntry(age: newAge, text: haber, category: LogCategory.aile),
      );
    }

    // Kişilerin mal varlığı yıllar içinde değişir; miras donmuş bir
    // listeye dayanmaz (D-037).
    final List<Person> peopleWithEstates = <Person>[
      ..._driftEstates(peopleWithSchool),
      ...yeniTorunlar,
    ];

    // Ölümler: hayatın sonlu olduğunu hissettiren, yaşa bağlı bir eğilim.
    // Kayıtlar silinmez; kişi vefat etmiş olarak işaretlenir.
    final ({
      List<Person> people,
      int happinessLoss,
      List<({Person person, String cause, int loss})> deaths,
    })
    olumSonucu = _applyDeaths(
      state: state,
      people: peopleWithEstates,
      newAge: newAge,
      log: log,
    );

    // Maaş yeni yaşa geçerken **bir kez** ödenir.
    ({GameState state, String? logText}) maas = const JobMarket().paySalaryFor(
      state.copyWith(player: state.player.copyWith(age: newAge)),
      newAge,
    );
    if (maas.logText != null) {
      log.add(
        LifeLogEntry(
          age: newAge,
          text: maas.logText!,
          category: LogCategory.kisisel,
        ),
      );
    }

    // Emekli aylığı da yeni yaşa geçerken **bir kez** ödenir (Paket 12).
    // Emekli oyuncunun işi olmadığı için maaşla çakışmaz.
    final ({GameState state, String? logText}) aylik = Retirement.payPension(
      maas.state,
      newAge,
    );
    if (aylik.logText != null) {
      log.add(
        LifeLogEntry(
          age: newAge,
          text: aylik.logText!,
          category: LogCategory.kisisel,
        ),
      );
      maas = (state: aylik.state, logText: maas.logText);
    }

    // Hastalık maaştan **sonra**, işten çıkarılmadan **önce** işler
    // (D-078): çalışılan yılın ücreti ödenir, raporun ödenmeyen günleri
    // o ücretten düşer, uyarı birikmişse çıkarılma ihtimaline katılır.
    // Kritik iş haberleri yalnızca günlüğe yazılıp geçilmez; ekranda
    // bildirim olarak da gösterilir (D-097).
    final List<PendingNotice> kariyerBildirimleri = <PendingNotice>[];
    maas = _applySickLeave(maas, newAge, log, kariyerBildirimleri);

    // Maaş ödendikten **sonra** işten çıkarılma denenir: çalışılan yılın
    // ücreti ödenir, yeni yıla işsiz girilir (Paket 9).
    final ({GameState state, String? logText}) isKaybi =
        CareerProgress.maybeLayoff(maas.state, newAge, _rng);
    if (isKaybi.logText != null) {
      log.add(
        LifeLogEntry(
          age: newAge,
          text: isKaybi.logText!,
          category: LogCategory.kisisel,
        ),
      );
      kariyerBildirimleri.add(
        PendingNotice(
          id: 'kariyer-isten-cikarma-$newAge',
          kind: NoticeKind.kariyer,
          age: newAge,
          title: 'İşten çıkarıldın',
          text: isKaybi.logText!,
        ),
      );
      maas = (state: isKaybi.state, logText: maas.logText);
    }

    final GameState advanced = state.copyWith(
      // Maaş ödemesi cüzdanı ve ödeme dönemini günceller.
      player: maas.state.player.copyWith(age: newAge),
      people: List<Person>.unmodifiable(olumSonucu.people),
      log: List<LifeLogEntry>.unmodifiable(log),
      // Tekrar sayaçları yaşa aittir: yeni yaşta aynı etkinlik yeniden
      // anlamlı fayda verebilir. Yenilemenin tam mı kısmi mi olacağı
      // (`docs/CORE_LOOP.md`) henüz kararlaştırılmadı; prototipte tam
      // yenileme uygulanır.
      interactionCounts: const <String, int>{},
      // Kumarhanenin yıllık bahis sınırı da yaşa aittir.
      wagerThisAge: 0,
      extraEventsThisAge: 0,
      progressSinceLastEvent: 0,
      education: okulSonucu.education,
      career: maas.state.career,
    );

    // Kaybın etkisi: mutluluk düşer, ama bu **kalıcı bir ceza değildir**.
    // Düşen miktar yas olarak saklanır ve sonraki yıllarda geri verilir
    // (D-036).
    GameState afterDeaths = advanced;
    // Torun sevinci: gerçekten doğduğu yıl uygulanır.
    if (yeniTorunlar.isNotEmpty) {
      afterDeaths = afterDeaths.copyWith(
        player: afterDeaths.player.copyWith(
          stats: afterDeaths.player.stats.gain(
            happiness: Grandchildren.prototypeOnlyHappiness * yeniTorunlar.length,
          ),
        ),
      );
    }
    if (olumSonucu.happinessLoss > 0) {
      afterDeaths = advanced.copyWith(
        player: advanced.player.copyWith(
          stats: advanced.player.stats.gain(
            happiness: -olumSonucu.happinessLoss,
          ),
        ),
        grief: advanced.grief + olumSonucu.happinessLoss,
      );
    }

    // Önemli kayıplar açıkça bildirilir (D-050). Mutluluğa **gerçekten**
    // uygulanan düşüş yazılır: mutluluk zaten 0 ise sahte "-puan" olmaz.
    if (olumSonucu.deaths.isNotEmpty) {
      int kalanMutluluk = advanced.player.stats.happiness;
      final List<PendingNotice> bildirimler = <PendingNotice>[];
      for (final ({Person person, String cause, int loss}) olum
          in olumSonucu.deaths) {
        final int uygulanan = olum.loss.clamp(0, kalanMutluluk);
        kalanMutluluk -= uygulanan;
        if (!Notices.shouldNotify(olum.person)) continue;
        bildirimler.add(
          Notices.death(
            person: olum.person,
            playerAge: newAge,
            cause: olum.cause,
            happinessDelta: -uygulanan,
          ),
        );
        if (Notices.funeralRelations.contains(olum.person.relation)) {
          bildirimler.add(
            Notices.funeral(person: olum.person, playerAge: newAge),
          );
        }
      }
      afterDeaths = Notices.enqueue(afterDeaths, bildirimler);
    }

    if (okulBildirimleri.isNotEmpty) {
      afterDeaths = Notices.enqueue(afterDeaths, okulBildirimleri);
    }

    // Kritik iş haberleri (D-097).
    if (kariyerBildirimleri.isNotEmpty) {
      afterDeaths = Notices.enqueue(afterDeaths, kariyerBildirimleri);
    }

    // Yas zamanla hafifler: her yıl kalan yasın bir bölümü mutluluğa geri
    // döner.
    afterDeaths = _easeGrief(afterDeaths, olumSonucu.happinessLoss > 0);

    // Yaşlanmanın dış görünüşe etkisi (D-051): yetişkinlikte başlar,
    // kademelidir ve kişiden kişiye değişir. Yalnızca gerçek değer
    // değişir; mutluluk ve zekâ bundan etkilenmez.
    afterDeaths = _applyAging(afterDeaths, newAge);

    // Araç masrafı (D-079): yılda en fazla bir arıza.
    afterDeaths = _applyVehicleTrouble(afterDeaths, newAge);

    // Kredi taksitleri (D-080): ödenebilen düşer, ödenemeyen kaçar ve
    // borç faiziyle büyür. Cüzdan eksiye inmez.
    final ({GameState state, List<String> messages, List<String> missed})
        kredi = Banking.advanceYear(afterDeaths);
    afterDeaths = kredi.state;
    for (final String satir in kredi.messages) {
      afterDeaths = _logLine(afterDeaths, newAge, satir);
    }
    // Kaçan taksit kritik haberdir: borç faiziyle büyüdüğü için oyuncu
    // bunu günlükte aramak zorunda kalmaz (D-097).
    if (kredi.missed.isNotEmpty) {
      afterDeaths = Notices.enqueue(afterDeaths, <PendingNotice>[
        PendingNotice(
          id: 'banka-kacan-taksit-$newAge',
          kind: NoticeKind.banka,
          age: newAge,
          title: 'Taksit ödenemedi',
          text: kredi.missed.join(' '),
        ),
      ]);
    }

    // Eş vefat ettiyse evlilik kaydı **dul** durumuna geçer; kayıt
    // silinmez, miras hâlâ gerçek bir evliliğe dayanır (D-037).
    afterDeaths = const MarriageEngine().settleWidowhood(afterDeaths, newAge);

    // Miras: yalnızca bu yıl vefat edenler için ve **bir kez**.
    afterDeaths = _settleEstates(afterDeaths, newAge);

    // Büyüyen çocuklar kendi hayatlarını kurar: haneden çıkarlar ama
    // kayıtları silinmez, görüşülmeye devam edilir.
    afterDeaths = _childrenLeaveHome(afterDeaths, newAge);

    // Kira geliri: kiraya verilen konutlardan yılda **bir kez** (D-043).
    afterDeaths = _applyRentIncome(afterDeaths, newAge);

    // Sosyal medya: süresi dolan sponsorluklar kapanır, koşullar
    // uygunsa yeni bir teklif gelir (Paket 10).
    afterDeaths = _applySponsorships(afterDeaths, newAge);

    // Burs: not ortalaması yüksek öğrenciye yılda bir kez ödenir
    // (Paket 13).
    final ({GameState state, String logText})? burs =
        SchoolPerformance.payScholarship(afterDeaths, newAge);
    if (burs != null) {
      afterDeaths = _logLine(burs.state, newAge, burs.logText);
    }

    // Yıllık geçim gideri: hane ve yaşam koşuluna göre, **bir kez** (D-033).
    final ({GameState state, String? logText}) gider = LivingCosts.apply(
      afterDeaths,
    );
    afterDeaths = gider.state;
    if (gider.logText != null) {
      afterDeaths = afterDeaths.copyWith(
        log: List<LifeLogEntry>.unmodifiable(<LifeLogEntry>[
          ...afterDeaths.log,
          LifeLogEntry(
            age: newAge,
            text: gider.logText!,
            category: LogCategory.kisisel,
          ),
        ]),
      );
    }

    // Hane bakımı: küçük yaştaki oyuncu haneyi boş bırakmaz.
    afterDeaths = ensureCaregiver(afterDeaths, newAge);

    // Oyuncunun ölümü: hayat tamamlanır, başka işlem yapılmaz.
    if (_playerDies(afterDeaths)) {
      return _endLife(afterDeaths, newAge);
    }

    // Sağlık krizi: hastalık veya kaza (D-044). Seyrektir ve sonucunu
    // oyuncunun seçimi etkiler; bu yüzden ölüm burada uygulanmaz, kriz
    // ekrana gelir.
    afterDeaths = _maybeHealthCrisis(afterDeaths, newAge);

    // Sağlığı belirgin kötüleşen karaktere anlaşılır bir uyarı (D-036).
    afterDeaths = _maybeHealthWarning(afterDeaths, newAge);

    // Bekleyen doğum (Paket 26): hamilelik bu yıl bebekle sonuçlanır.
    afterDeaths = _applyBirth(afterDeaths, newAge);

    // Askerlik (Paket 29): görevdeyse yıl işler ve süresi dolduysa
    // terhis olur; okumayan yükümlü yaşı gelince çağrılır.
    afterDeaths = MilitaryService.advanceYear(afterDeaths, newAge);
    afterDeaths = MilitaryService.advanceFugitive(afterDeaths, newAge, _rng);
    afterDeaths = MilitaryService.applyDeferralEnd(afterDeaths, newAge);
    afterDeaths = MilitaryService.applyCallUp(afterDeaths, newAge);

    // Kendi işi (D-132): kâr/zarar cüzdana yazılır, durum kayar,
    // ilgilenilmeyen iş batar. İşi olmayan oyuncuda etkisi yoktur.
    afterDeaths = BusinessEngine.advanceYear(afterDeaths, newAge, _rng);

    // Arkadaşlıklar (D-130): ilgilenilmeyen arkadaşlık kopabilir ve
    // arkadaşın kendi hayatında bir şey olur. İkisi de seyrektir.
    afterDeaths = FriendshipDepth.advanceYear(afterDeaths, newAge, _rng);

    // Adli süreç (D-128): açık soruşturma ilerler, dosya mahkemeye
    // gidebilir, hapisteki yıl işler ve süresi dolan tahliye olur.
    // Suç işlemeyen oyuncuda bu satırların hiçbir etkisi yoktur.
    afterDeaths = LegalEngine.advanceYear(afterDeaths, newAge, _rng);

    // Evcil hayvanlar (Paket 40): yaşlanır, yıllık bakım gideri **bir
    // kez** alınır ve yaşı gelen hayvan doğal yoldan kaybedilir. Parasızlık
    // hayvanı öldürmez.
    afterDeaths = PetCare.advanceYear(afterDeaths, newAge, _rng);

    // Milli Piyango (Paket 33): yıl içinde alınan biletlerin çekilişi
    // burada yapılır ve sonuç bildirim paneline düşer.
    afterDeaths = Lottery.drawAll(afterDeaths, newAge, _rng);

    // Burçsal dönem (Paket 27): bazı yıllarda oyuncunun burcuna denk
    // gelen bir dönem çıkar ve mutluluğu gerçekten etkiler.
    afterDeaths = _applyZodiacPeriod(afterDeaths, newAge);

    // İlgisizlikten zayıflayan bağlar (Paket 24). Bağ yalnızca
    // yükselmemeli: uzun süre görüşülmeyen kişiyle araya mesafe girer.
    afterDeaths = _applyBondDecay(afterDeaths, newAge);

    // Okurken yarım zamanlı çalışmanın bedeli (D-131).
    afterDeaths = _applyPartTimeStrain(afterDeaths, newAge);

    // Lise alanının yıllık küçük kazancı; alan seçimi kozmetik değildir.
    GameState withTrack = _applyTrackBonus(afterDeaths);

    // Biten yılın özeti (D-096): oyuncu hayat günlüğünü taramadan yılın
    // nasıl geçtiğini görebilsin. Özet yılın **başındaki** fotoğrafla
    // bugünün farkından üretilir; yeni yıl için yeni fotoğraf alınır.
    withTrack = withTrack.copyWith(
      lastYearSummary: yilOzeti,
      yearMark: YearMark.of(withTrack),
    );

    // Yeni yaşın tek açılış olayı.
    final ActiveEvent? opening = const EventEngine().openingEvent(
      withTrack,
      _rng,
    );
    return opening == null
        ? withTrack
        : withTrack.copyWith(pendingEvent: opening);
  }

  /// Lise alanının yıllık küçük katkısı.
  /// Bu yıl vefat edenleri işaretler ve günlüğe yazar.
  ///
  /// Kişi kaydı **silinmez**: yalnızca [Person.isAlive] false olur ve kişi
  /// hane listesinden düşer. Her yıl birinin ölmesi gerekmez.
  ({
    List<Person> people,
    int happinessLoss,
    List<({Person person, String cause, int loss})> deaths,
  })
  _applyDeaths({
    required GameState state,
    required List<Person> people,
    required int newAge,
    required List<LifeLogEntry> log,
  }) {
    int mutlulukKaybi = 0;
    final List<Person> sonuc = <Person>[];
    final List<({Person person, String cause, int loss})> olenler =
        <({Person person, String cause, int loss})>[];

    for (final Person person in people) {
      if (!person.isAlive) {
        sonuc.add(person);
        continue;
      }
      if (!Mortality.diesThisYear(person.age, _rng)) {
        sonuc.add(person);
        continue;
      }

      final String gerekce = Mortality.causeFor(person.age, _rng);
      sonuc.add(person.copyWith(isAlive: false, inPlayerHousehold: false));
      final int kayip = Mortality.prototypeOnlyHappinessLoss(person);
      mutlulukKaybi += kayip;
      olenler.add((person: person, cause: gerekce, loss: kayip));

      final String etiket = person.possessiveFor(newAge);
      log.add(
        LifeLogEntry(
          age: newAge,
          text:
              '${trUpperFirst(etiket)} '
              '${person.fullName} $gerekce nedeniyle vefat etti.',
          category: LogCategory.aile,
          // Kayıt kişiye bağlanır (Paket 43): ortak geçmiş vefatın
          // **gerçek** yılını buradan okur, uydurmaz.
          personId: person.id,
        ),
      );
    }

    return (people: sonuc, happinessLoss: mutlulukKaybi, deaths: olenler);
  }

  /// Kiraya verilen konutların yıllık kira gelirini **bir kez** öder.
  ///
  /// Her yıl kiracı bulunmayabilir; gelir garanti değildir. Gelir gerçek
  /// mülk kaydından hesaplanır, uydurulmaz.
  /// Sponsorluk yükümlülüklerini ve yeni teklifleri işler.
  ///
  /// Yapılmayan paylaşım için ödeme yapılmaz; süresi dolan anlaşma
  /// "düştü" olarak kapanır ve günlüğe yazılır.
  GameState _applySponsorships(GameState state, int newAge) {
    const SocialEngine sosyal = SocialEngine();
    final ({GameState state, List<String> logTexts}) suresiDolan = sosyal
        .expireDeals(state, newAge);
    GameState sonraki = suresiDolan.state;
    for (final String satir in suresiDolan.logTexts) {
      sonraki = _logLine(sonraki, newAge, satir);
    }

    // Hesaplar yıl geçerken kendiliğinden değişir: kitlesi büyük olan
    // büyür, yıllardır dokunulmayan erir (Faho'nun isteği). Eskiden
    // yıllık ilerleme sosyal medyaya hiç dokunmuyordu; takipçi sayısı
    // yalnızca paylaşım yapıldığı an değişiyordu.
    final ({GameState state, List<String> logTexts}) kitle = sosyal.advanceYear(
      sonraki,
      newAge,
    );
    sonraki = kitle.state;
    for (final String satir in kitle.logTexts) {
      sonraki = _logLine(sonraki, newAge, satir);
    }

    // Fırsat her zaman oyuncunun menüye girip aramasıyla gelmez; bazen
    // kapıyı onlar çalar (D-120).
    final MediaOpportunity? davet =
        MediaOpportunities.maybeInvitation(sonraki, _rng);
    if (davet != null) {
      sonraki = sonraki.copyWith(
        mediaInvitationId: davet.id,
        mediaInvitationAge: newAge,
      );
      final String metin = '${davet.label} seni çağırdı. Bu iş için Ün '
          'şartı aranmıyor ve başvurun geri çevrilmeyecek; bu yıl '
          'Aktiviteler → Ün ve Medya Fırsatları bölümünden kabul '
          'edebilirsin.';
      sonraki = _logLine(sonraki, newAge, metin);
      sonraki = Notices.enqueue(sonraki, <PendingNotice>[
        PendingNotice(
          id: 'medya-davet-$newAge-${davet.id}',
          kind: NoticeKind.aktivite,
          age: newAge,
          title: 'Medya daveti',
          text: metin,
        ),
      ]);
    }

    final SponsorOffer? teklif = SocialIncome.maybeOffer(sonraki, _rng);
    if (teklif == null) return sonraki;
    final String sponsorMetni =
        'Sosyal medyada bir ${teklif.label} sponsorluk teklif etti. '
        'Aktiviteler → Sosyal medya bölümünden yanıtlayabilirsin.';
    sonraki = Notices.enqueue(sonraki, <PendingNotice>[
      PendingNotice(
        id: 'sponsor-teklif-$newAge-${teklif.id}',
        kind: NoticeKind.aktivite,
        age: newAge,
        title: 'Sponsorluk teklifi',
        text: sponsorMetni,
      ),
    ]);
    return _logLine(
      sonraki.copyWith(sponsorOffer: teklif),
      newAge,
      sponsorMetni,
    );
  }

  GameState _logLine(GameState state, int age, String text) => state.copyWith(
    log: List<LifeLogEntry>.unmodifiable(<LifeLogEntry>[
      ...state.log,
      LifeLogEntry(age: age, text: text, category: LogCategory.kisisel),
    ]),
  );

  GameState _applyRentIncome(GameState state, int newAge) {
    final List<OwnedItem> kiradakiler = state.items
        .where((OwnedItem i) => i.isProperty && i.rentedOut)
        .toList(growable: false);
    if (kiradakiler.isEmpty) return state;

    int toplam = 0;
    final List<LifeLogEntry> satirlar = <LifeLogEntry>[];
    for (final OwnedItem ev in kiradakiler) {
      if (_rng.nextDouble() < Housing.prototypeOnlyVacancyChance) {
        satirlar.add(
          LifeLogEntry(
            age: newAge,
            text: '${ev.name} bu yıl boş kaldı; kira geliri gelmedi.',
            category: LogCategory.kisisel,
          ),
        );
        continue;
      }
      final int kira = Housing.yearlyRentOf(ev);
      toplam += kira;
      satirlar.add(
        LifeLogEntry(
          age: newAge,
          text: '${ev.name} için yıllık ${trMoney(kira)} kira geliri aldın.',
          category: LogCategory.kisisel,
        ),
      );
    }

    return state.copyWith(
      player: state.player.copyWith(wallet: state.player.wallet + toplam),
      log: List<LifeLogEntry>.unmodifiable(<LifeLogEntry>[
        ...state.log,
        ...satirlar,
      ]),
    );
  }

  /// Yetişkin olan çocukları haneden çıkarır.
  ///
  /// Kişi kaydı **silinmez**; yalnızca hane bilgisi değişir. Böylece çocuk
  /// gideri ömür boyu sürmez, çocuk ilişkiler listesinde kalmaya devam
  /// eder. Yaş sınırı `prototypeOnly`'dir (Q-064).
  GameState _childrenLeaveHome(GameState state, int newAge) {
    final List<Person> people = <Person>[...state.people];
    final List<LifeLogEntry> satirlar = <LifeLogEntry>[];
    bool degisti = false;

    for (int i = 0; i < people.length; i++) {
      final Person p = people[i];
      if (p.relation != RelationType.cocuk) continue;
      if (!p.isAlive || !p.inPlayerHousehold) continue;
      if (p.age < Parenthood.prototypeOnlyLeaveHomeAge) continue;

      people[i] = p.copyWith(inPlayerHousehold: false);
      degisti = true;
      satirlar.add(
        LifeLogEntry(
          age: newAge,
          text:
              '${p.fullName} kendi evine taşındı; artık kendi hayatını '
              'kuruyor.',
          category: LogCategory.aile,
        ),
      );
    }

    if (!degisti) return state;
    return state.copyWith(
      people: List<Person>.unmodifiable(people),
      log: List<LifeLogEntry>.unmodifiable(<LifeLogEntry>[
        ...state.log,
        ...satirlar,
      ]),
    );
  }

  /// Kişilerin mal varlığı hayat boyunca değişir (D-037).
  ///
  /// Miras hesabı doğumda donmuş bir servet listesine dayanmaz: çalışan
  /// yetişkinler ara sıra bir şey alır, dar gelirliler ara sıra elden
  /// çıkarır. Yeni kişi veya sahte kayıt üretilmez; yalnızca mevcut
  /// kişinin listesi değişir. Oranlar `prototypeOnly`.
  List<Person> _driftEstates(List<Person> people) {
    const List<String> alinabilir = <String>[
      'kol_saati',
      'telefon',
      'radyo',
      'cay_takimi',
      'bisiklet',
      'bilgisayar',
    ];

    return people
        .map((Person p) {
          if (!p.isAlive || p.age < prototypeOnlyAdultAge) return p;
          if (p.wealth == null) return p;

          // prototypeOnly: her yıl küçük bir ihtimalle alım ya da satım.
          final double alimSansi = switch (p.wealth!) {
            WealthTier.cokYoksul => 0.01,
            WealthTier.yoksul => 0.03,
            WealthTier.ortaHalli => 0.06,
            WealthTier.varlikli => 0.09,
            WealthTier.cokVarlikli => 0.12,
          };
          final double satisSansi = switch (p.wealth!) {
            WealthTier.cokYoksul => 0.10,
            WealthTier.yoksul => 0.07,
            WealthTier.ortaHalli => 0.04,
            WealthTier.varlikli => 0.02,
            WealthTier.cokVarlikli => 0.01,
          };

          if (p.estate.isNotEmpty && _rng.nextDouble() < satisSansi) {
            final List<String> kalan = <String>[...p.estate]
              ..removeAt(_rng.nextInt(p.estate.length));
            return p.copyWith(estate: List<String>.unmodifiable(kalan));
          }
          if (p.estate.length < 6 && _rng.nextDouble() < alimSansi) {
            // Kişi zaten sahip olduğu türü ikinci kez almaz: aynı eşya
            // listede iki kez görünüyordu ve miras da onu iki kez
            // dağıtıyordu (Paket 14'te bulundu).
            final List<String> eksikler = alinabilir
                .where((String tur) => !p.estate.contains(tur))
                .toList(growable: false);
            if (eksikler.isEmpty) return p;
            return p.copyWith(
              estate: List<String>.unmodifiable(<String>[
                ...p.estate,
                eksikler[_rng.nextInt(eksikler.length)],
              ]),
            );
          }
          return p;
        })
        .toList(growable: false);
  }

  /// Bu yıl vefat edenlerin mirasını **bir kez** dağıtır.
  GameState _settleEstates(GameState state, int newAge) {
    GameState next = state;
    // Aynı yıl gelen miras payları tek bildirimde toplanır (D-097);
    // üst üste açılan pencere sayısı azalır, hiçbir pay kaybolmaz.
    final List<PendingNotice> mirasBildirimleri = <PendingNotice>[];
    for (final Person person in state.people) {
      if (person.isAlive) continue;
      if (next.settledEstates.contains(person.id)) continue;

      // Bildirim için oyuncuya **gerçekten** ne kaldığı okunur; hiçbir
      // şey kalmadıysa miras bildirimi çıkmaz.
      final InheritanceShare pay = Inheritance.shareFor(next, person);
      final ({GameState state, List<String> logLines}) sonuc =
          Inheritance.settle(next, person);
      next = sonuc.state;
      final PendingNotice? mirasBildirimi = Notices.inheritance(
        person: person,
        playerAge: newAge,
        money: pay.money,
        itemNames: <String>[
          for (final String t in pay.itemTypeIds) itemTypeOrFallback(t).name,
        ],
      );
      if (mirasBildirimi != null) {
        mirasBildirimleri.add(mirasBildirimi);
      }
      for (final String satir in sonuc.logLines) {
        next = next.copyWith(
          log: List<LifeLogEntry>.unmodifiable(<LifeLogEntry>[
            ...next.log,
            LifeLogEntry(age: newAge, text: satir, category: LogCategory.aile),
          ]),
        );
      }
    }
    final PendingNotice? toplu = Notices.combinedInheritance(
      playerAge: newAge,
      shares: mirasBildirimleri,
    );
    if (toplu != null) {
      next = Notices.enqueue(next, <PendingNotice>[toplu]);
    }
    return next;
  }

  /// Küçük yaştaki oyuncu hanede yetişkinsiz kalmaz.
  ///
  /// **Yeni kişi üretilmez**: hayatta olan yakın bir yetişkin (büyükanne,
  /// büyükbaba, teyze/dayı/hala/amca ya da yetişkin kardeş) haneye geçer.
  /// Hiç yoksa yalnızca günlüğe açıklayıcı bir satır yazılır; oyuncu
  /// mantıksız bir haneye taşınmaz. Velayetin tam kuralları karar
  /// kuyruğundadır (Q-059).
  /// Hanede yetişkin kalmadığında bakım durumunu düzeltir.
  ///
  /// Kuşak devamında da (Paket E3) aynı kural geçerli olsun diye statiktir:
  /// küçük yaşta devam eden çocuk, açıklamasız bir hanede bırakılmaz.
  static GameState ensureCaregiver(GameState state, int newAge) {
    if (state.player.age >= prototypeOnlyAdultAge) return state;
    final bool yetiskinVar = state.people.any(
      (Person p) =>
          p.isAlive && p.inPlayerHousehold && p.age >= prototypeOnlyAdultAge,
    );
    if (yetiskinVar) return state;

    const Set<RelationType> bakimVerebilir = <RelationType>{
      RelationType.anneanne,
      RelationType.babaanne,
      RelationType.anneTarafiDede,
      RelationType.babaTarafiDede,
      RelationType.teyze,
      RelationType.dayi,
      RelationType.hala,
      RelationType.amca,
      RelationType.kardes,
    };

    final int index = state.people.indexWhere(
      (Person p) =>
          p.isAlive &&
          !p.inPlayerHousehold &&
          p.age >= prototypeOnlyAdultAge &&
          bakimVerebilir.contains(p.relation),
    );

    if (index < 0) {
      // Uygun yakın yoksa **uydurma bir kişi eklenmez**; bunun yerine açık
      // bir bakım durumuna geçilir (D-037). Ayrıntılı velayet sistemi
      // sonraki paketlerde genişletilecek.
      if (state.careStatus == CareStatus.kurumBakimi) return state;
      return state.copyWith(
        careStatus: CareStatus.kurumBakimi,
        log: List<LifeLogEntry>.unmodifiable(<LifeLogEntry>[
          ...state.log,
          LifeLogEntry(
            age: newAge,
            text:
                'Evde sana bakabilecek bir yetişkin kalmadı; '
                'bakımın kurum tarafından üstlenildi.',
            category: LogCategory.aile,
          ),
        ]),
      );
    }

    final List<Person> people = <Person>[...state.people];
    final Person bakan = people[index].copyWith(inPlayerHousehold: true);
    people[index] = bakan;
    final String etiket = bakan.possessiveFor(newAge);

    return state.copyWith(
      people: List<Person>.unmodifiable(people),
      careStatus: CareStatus.yakinAkraba,
      log: List<LifeLogEntry>.unmodifiable(<LifeLogEntry>[
        ...state.log,
        LifeLogEntry(
          age: newAge,
          text:
              '${trUpperFirst(etiket)} '
              '${bakan.fullName} sana bakmak için yanına taşındı.',
          category: LogCategory.aile,
        ),
      ]),
    );
  }

  /// Araç masrafı (D-079).
  ///
  /// Faho'nun isteği: "ucuz araçlar sorun çıkartsın, 'araban masraf
  /// çıkarttı' gibi bildirimler olsun". Yılda **en fazla bir** araç
  /// arızalanır; her aracı ayrı ayrı bozmak yılı masraf yağmuruna
  /// çevirirdi. Masraf gerçekten cüzdandan düşer, ödenemezse araç tamir
  /// edilmeden kalır.
  GameState _applyVehicleTrouble(GameState state, int newAge) {
    final List<OwnedItem> araclar = state.items
        .where(VehicleTroubles.applies)
        .toList(growable: false);
    if (araclar.isEmpty) return state;

    for (final OwnedItem arac in araclar) {
      final VehicleTrouble? sorun = VehicleTroubles.roll(
        item: arac,
        wallet: state.player.wallet,
        rng: _rng,
      );
      if (sorun == null) continue;

      final int odenen = sorun.paid ? sorun.cost : 0;
      GameState next = state.copyWith(
        player: state.player.copyWith(
          wallet: state.player.wallet - odenen,
        ),
        items: List<OwnedItem>.unmodifiable(
          state.items.map((OwnedItem i) => i.id == sorun.itemId
              ? i.copyWith(
                  condition: (i.condition + sorun.conditionDelta).clamp(0, 100),
                )
              : i),
        ),
      );

      next = _logLine(next, newAge, sorun.text);
      next = Notices.enqueue(next, <PendingNotice>[
        PendingNotice(
          id: 'arac-${sorun.itemId}-$newAge',
          kind: NoticeKind.arac,
          age: newAge,
          title: 'Araç masrafı',
          text: sorun.text,
          money: odenen,
          effects: diffAppliedEffects(state, next),
        ),
      ]);
      // Yılda tek arıza: ilk bozulanla yetinilir.
      return next;
    }
    return state;
  }

  /// Hastalık ve işe gidememe (D-078).
  ///
  /// Faho'nun isteği: "hasta olayım, 3-5 gün işe gidemeyeyim, işverenim
  /// sorun etsin". Kayıp **gerçekten uygulanır**: ödenmeyen günler
  /// cüzdandan düşer ve uyarı kariyer kaydına yazılır. İşveren her
  /// hastalığı sorun etmez; kısa rapor geçer.
  ({GameState state, String? logText}) _applySickLeave(
    ({GameState state, String? logText}) girdi,
    int newAge,
    List<LifeLogEntry> log,
    List<PendingNotice> bildirimler,
  ) {
    final GameState state = girdi.state;
    final SickLeave hastalik = SickLeaves.roll(
      age: newAge,
      health: state.player.stats.health,
      yearsSinceSport: state.yearsSinceSport,
      yearlySalary: state.career.isEmployed ? state.career.salary : null,
      previousWarnings: state.career.employerWarnings,
      rng: _rng,
      isStudent: state.education.isSchoolStudent,
    );
    if (!hastalik.happened) {
      // Hastalanılmayan yılda beden toparlanır (D-116).
      //
      // Hastalığın bedeli −10'a çıkınca gerekti: toparlanma olmadan
      // kayıplar birikiyor ve sağlık kırk yaşında sıfıra yapışıyordu
      // (ölçüldü: 100 hayat, 40 yaşta ortalama sağlık 0,8). Toparlanma
      // yaşlanmanın kalıcı kaybını geri vermez; tavanı yaşa göre düşen
      // bir sınırdır, yalnızca hastalığın açtığı çukuru kapatır.
      final int tavan = StatAging.prototypeOnlyHealthCeilingFor(newAge);
      final int pay = SickLeaves.recoveryFor(
        age: newAge,
        health: state.player.stats.health,
        ceiling: tavan,
      );
      if (pay <= 0) return girdi;
      return (
        state: state.copyWith(
          player: state.player.copyWith(
            stats: state.player.stats.gain(health: pay),
          ),
        ),
        logText: girdi.logText,
      );
    }

    final int kayip = hastalik.wageLoss.clamp(0, state.player.wallet);
    GameState next = state.copyWith(
      player: state.player.copyWith(
        wallet: state.player.wallet - kayip,
        stats: state.player.stats.gain(
          happiness: hastalik.happinessDelta,
          health: hastalik.healthDelta,
        ),
      ),
    );
    if (hastalik.employerUpset) {
      next = next.copyWith(
        career: next.career.copyWith(
          employerWarnings: next.career.employerWarnings + 1,
        ),
      );
      // İşveren uyarısı kaçırılmaması gereken bir haberdir: tek başına
      // kimseyi işten atmaz ama çıkarılma ihtimalini artırır (D-078).
      bildirimler.add(
        PendingNotice(
          id: 'kariyer-uyari-$newAge',
          kind: NoticeKind.kariyer,
          age: newAge,
          title: 'İş yerinden uyarı',
          text: '${hastalik.text} İşveren bu kadar rapordan memnun '
              'değil. Uyarı tek başına işten çıkarmaz ama birikirse '
              'riski artırır.',
        ),
      );
    }

    // Günlük her kırgınlıkla dolmaz (D-063'ün spam kuralı): yalnızca
    // hayatta bir karşılığı olan hastalık yazılır — işten kalınan,
    // gelirden götüren ya da uzun süren. Üç gün nezle olan bir çocuğun
    // her yılı günlüğe girmez; etkisi yine uygulanır.
    final bool anlatmayaDeger = hastalik.wageLoss > 0 ||
        hastalik.employerUpset ||
        hastalik.days >= SickLeaves.prototypeOnlyUpsetDays;
    if (anlatmayaDeger) {
      log.add(
        LifeLogEntry(
          age: newAge,
          text: hastalik.text,
          category: LogCategory.kisisel,
        ),
      );
    }

    // Hastalık artık sağlıktan ciddi biçimde götürüyor (D-116); bu
    // kaçırılmaması gereken bir haberdir ve ekranda gösterilir (D-114).
    // İşveren uyarısı ayrı bir bildirim olarak zaten çıktıysa ikinci kez
    // pencere açılmaz.
    if (!hastalik.employerUpset) {
      bildirimler.add(
        PendingNotice(
          id: 'hastalik-$newAge',
          kind: NoticeKind.saglik,
          age: newAge,
          title: 'Hastalandın',
          text: '${hastalik.text} Bu, '
              '${SickLeaves.severityLabel(hastalik.days)} geçen bir '
              'hastalıktı; bedeni yordu.',
          effects: diffAppliedEffects(state, next),
        ),
      );
    }
    return (state: next, logText: girdi.logText);
  }

  /// Yaşlanmanın bütün değerlere etkisini uygular (D-051, D-072, D-073).
  ///
  /// Etki yılda **bir kez**, yaş ilerletmenin içinde uygulanır; oyunu
  /// kapatıp açmak aynı yılın etkisini ikinci kez uygulamaz.
  ///
  /// Üç iş birlikte yapılır ki aynı yılın kayıpları tek bir yerde
  /// toplansın: yaşa bağlı sürüklenme, bakımın koruyucu etkisi ve
  /// erkeklerde saç dökülmesi.
  GameState _applyAging(GameState state, int newAge) {
    final StatDrift drift = StatAging.yearlyDrift(
      age: newAge,
      stats: state.player.stats,
      upkeep: UpkeepTracker.statusOf(state),
      rng: _rng,
    );

    final HairLossStep sac = HairLoss.step(
      gender: state.player.gender,
      age: newAge,
      stage: state.player.hairLossStage,
      groomedRecently: UpkeepTracker.groomedRecently(state),
      rng: _rng,
    );

    if (drift.isEmpty && !sac.changed) return state;

    final Stats stats = state.player.stats;
    GameState next = state.copyWith(
      player: state.player.copyWith(
        hairLossStage: sac.stage,
        stats: stats.gain(
          appearance: drift.appearance + sac.appearance,
          charisma: drift.charisma + sac.charisma,
          health: drift.health,
          intelligence: drift.intelligence,
          happiness: drift.happiness,
        ),
      ),
    );

    // Günlük her yıl dolmaz: yalnızca anlatmaya değer olanlar yazılır.
    final List<String> satirlar = <String>[
      ...drift.notes,
      if (sac.note != null) sac.note!,
    ];
    if (satirlar.isEmpty) return next;

    for (final String satir in satirlar) {
      next = next.copyWith(
        log: List<LifeLogEntry>.unmodifiable(<LifeLogEntry>[
          ...next.log,
          LifeLogEntry(
            age: newAge,
            text: satir,
            category: LogCategory.kisisel,
          ),
        ]),
      );
    }
    return next;
  }

  /// Yası hafifletir (D-036).
  ///
  /// Her yıl kalan yasın bir bölümü mutluluğa geri döner; yas kalıcı ve
  /// geri dönülemez bir ceza değildir. Kaybın yaşandığı yıl geri verme
  /// yapılmaz.
  GameState _easeGrief(GameState state, bool lossThisYear) {
    if (state.grief <= 0 || lossThisYear) return state;

    // prototypeOnly: kalan yasın üçte biri, en az 2 puan geri döner.
    final int geriVerilen = max(
      2,
      (state.grief * prototypeOnlyGriefRecoveryRatio).round(),
    ).clamp(0, state.grief);
    if (geriVerilen <= 0) return state;

    return state.copyWith(
      grief: state.grief - geriVerilen,
      player: state.player.copyWith(
        stats: state.player.stats.gain(
          happiness: geriVerilen,
        ),
      ),
    );
  }

  /// Yeni yaşta sağlık krizi çıkabilir (D-044).
  ///
  /// Kriz seyrektir; çıkarsa ekranda oyuncunun kararını bekler.
  GameState _maybeHealthCrisis(GameState state, int newAge) {
    const HealthCrisisEngine motor = HealthCrisisEngine();
    final HealthCrisis? kriz = motor.rollCrisis(state, newAge, _rng);
    if (kriz == null) return state;
    return motor.open(state, kriz, newAge);
  }

  /// Sağlık belirgin biçimde düştüyse bir kez uyarır.
  ///
  /// Uyarı her ölümü haber vermez; yalnızca durumu görünür kılar.
  GameState _maybeHealthWarning(GameState state, int newAge) {
    if (state.player.stats.health > prototypeOnlyHealthWarningBelow) {
      return state.healthWarned ? state.copyWith(healthWarned: false) : state;
    }
    if (state.healthWarned) return state;
    return state.copyWith(
      healthWarned: true,
      log: List<LifeLogEntry>.unmodifiable(<LifeLogEntry>[
        ...state.log,
        LifeLogEntry(
          age: newAge,
          text:
              'Sağlığın belirgin biçimde kötüleşti; kendine dikkat '
              'etmen gerekiyor.',
          category: LogCategory.kisisel,
        ),
      ]),
    );
  }

  bool _playerDies(GameState state) => Mortality.diesThisYear(
    state.player.age,
    _rng,
    health: state.player.stats.health,
  );

  /// Oyuncunun hayatını tamamlar.
  GameState _endLife(GameState state, int newAge) {
    final String gerekce = Mortality.causeFor(newAge, _rng);
    return state.copyWith(
      deceased: true,
      deathAge: newAge,
      deathCause: gerekce,
      pendingEvent: null,
      log: List<LifeLogEntry>.unmodifiable(<LifeLogEntry>[
        ...state.log,
        LifeLogEntry(
          age: newAge,
          text: '$newAge yaşında $gerekce nedeniyle hayatını kaybettin.',
          category: LogCategory.yasDegisimi,
        ),
      ]),
    );
  }

  /// prototypeOnly: bir yılda burçsal dönem çıkma ihtimali.
  ///
  /// Her yıl çıkmaz: yoksa bildirim sıradanlaşır ve mutluluk sürekli
  /// oynar.
  static const double prototypeOnlyZodiacChance = 0.22;

  /// prototypeOnly: burç yorumlarının başladığı yaş.
  ///
  /// Küçük çocuğun karşısına "Satürn dönüşü" çıkmaz.
  static const int prototypeOnlyZodiacMinAge = 12;

  /// Burçsal dönem uygular (Paket 27).
  ///
  /// Yalnızca oyuncunun burcunu **gerçekten** etkileyen dönemler çıkar;
  /// "seni etkilemiyor" diye bir bildirim gösterilmez. Mutluluk etkisi
  /// bildirimde yazan değerle aynıdır.
  GameState _applyZodiacPeriod(GameState state, int newAge) {
    if (newAge < prototypeOnlyZodiacMinAge) return state;
    if (_rng.nextDouble() >= prototypeOnlyZodiacChance) return state;

    final Zodiac burc = Astrology.zodiacOf(state);
    final List<ZodiacPeriod> uygun = kZodiacPeriods
        .where((ZodiacPeriod p) => p.affects(burc))
        .toList(growable: false);
    if (uygun.isEmpty) return state;

    final ZodiacPeriod donem = uygun[_rng.nextInt(uygun.length)];
    final String id = Notices.zodiacNoticeId(donem.id, newAge);
    if (state.notices.any((PendingNotice n) => n.id == id)) return state;

    final int once = state.player.stats.happiness;
    // Kazanç azalan getiriyle işlenir (D-099); bildirimde yazan değer de
    // **gerçekten uygulanan** değerdir.
    final Stats yeniStats =
        state.player.stats.gain(happiness: donem.prototypeOnlyHappiness);
    final int gercek = yeniStats.happiness - once;

    final GameState etkili = state.copyWith(
      player: state.player.copyWith(stats: yeniStats),
    );

    // Bir yakınını kaybettiği yılda oyuncuya burç penceresi açılmaz
    // (D-097): etki yine uygulanır ve günlüğe yazılır, ama acılı bir
    // yılın üstüne süs bildirimi binmez.
    final bool aciliYil = state.notices.any(
      (PendingNotice n) =>
          n.kind == NoticeKind.olum || n.kind == NoticeKind.cenaze,
    );
    if (aciliYil) {
      return _logLine(
        etkili,
        newAge,
        Notices.zodiacPeriod(
          playerAge: newAge,
          period: donem,
          zodiac: burc,
          happinessDelta: gercek,
        ).text,
      );
    }

    return etkili.copyWith(
      notices: List<PendingNotice>.unmodifiable(<PendingNotice>[
        ...state.notices,
        Notices.zodiacPeriod(
          playerAge: newAge,
          period: donem,
          zodiac: burc,
          happinessDelta: gercek,
        ),
      ]),
    );
  }

  /// Süren hamileliği doğumla sonuçlandırır (Paket 26).
  ///
  /// Bebek **bir sonraki yaşta** doğar. Diğer ebeveyn hamilelik kaydında
  /// tutulan kişidir; uydurma bir ebeveyn yazılmaz. O kişi artık hayatta
  /// değilse ya da kayıttan düşmüşse doğum gerçekleşmez ve hamilelik
  /// sessizce kapanmaz: günlüğe yazılır.
  GameState _applyBirth(GameState state, int newAge) {
    final Pregnancy? bekleyen = state.pregnancy;
    if (bekleyen == null) return state;

    final Person? diger = state.personById(bekleyen.partnerId);
    if (diger == null || !diger.isAlive) {
      return _logLine(
        state.copyWith(pregnancy: null),
        newAge,
        'Bekleyen bebek dünyaya gelemedi.',
      );
    }

    final FamilyResult dogum = const Parenthood().haveChild(
      state.copyWith(pregnancy: null),
      _rng,
      coParentId: bekleyen.partnerId,
    );
    if (!dogum.outcome.applied) {
      // Sınır (ör. en fazla çocuk sayısı) engelledi; hamilelik kapanır
      // ama sebebi günlüğe yazılır, sessizce kaybolmaz.
      return _logLine(
        state.copyWith(pregnancy: null),
        newAge,
        dogum.outcome.text,
      );
    }

    final Person bebek = dogum.state.children.last;
    GameState sonuc = dogum.state.copyWith(
      notices: List<PendingNotice>.unmodifiable(<PendingNotice>[
        ...dogum.state.notices,
        Notices.birth(
          playerAge: newAge,
          childId: bebek.id,
          childName: bebek.firstName,
          isGirl: bebek.gender == Gender.kadin,
          otherParentName: diger.firstName,
        ),
      ]),
    );

    // Çok genç yaşta çocuk sahibi olmak ailede karşılıksız kalmaz
    // (D-110). Tepki **evlilik durumuna** bakar ve gerçekten uygulanır.
    sonuc = _youngParentReaction(sonuc, newAge);
    return sonuc;
  }

  /// prototypeOnly: ailenin tepki verdiği en küçük ve en büyük yaş.
  static const int prototypeOnlyYoungParentMinAge = 18;
  static const int prototypeOnlyYoungParentMaxAge = 20;

  /// prototypeOnly: evli değilken ailenin yakınlık tepkisi.
  static const int prototypeOnlyWorriedBond = -5;
  static const int prototypeOnlyWorriedHappiness = -3;

  /// prototypeOnly: evliyken ailenin yakınlık tepkisi.
  static const int prototypeOnlySupportiveBond = 3;
  static const int prototypeOnlySupportiveHappiness = 2;

  /// 18-20 yaşında çocuk sahibi olan oyuncuya ailenin tepkisi (D-110).
  ///
  /// Faho'nun isteği: "18-20 yaşında çocuk olunca ailenin bir tepkisi
  /// olsun". Tepki **yargı değil, durum**: evliyse aile destekler,
  /// değilse endişelenir. Etki yalnızca **hayatta olan** anne ve babaya
  /// uygulanır; olmayan ebeveyn için satır yazılmaz.
  GameState _youngParentReaction(GameState state, int newAge) {
    if (newAge < prototypeOnlyYoungParentMinAge ||
        newAge > prototypeOnlyYoungParentMaxAge) {
      return state;
    }
    final List<Person> ebeveynler = state.people
        .where((Person p) =>
            p.isAlive &&
            (p.relation == RelationType.anne ||
                p.relation == RelationType.baba))
        .toList(growable: false);
    if (ebeveynler.isEmpty) return state;

    final bool evli = state.marriage != null;
    final int bagFarki =
        evli ? prototypeOnlySupportiveBond : prototypeOnlyWorriedBond;
    final int mutluluk = evli
        ? prototypeOnlySupportiveHappiness
        : prototypeOnlyWorriedHappiness;

    final Set<String> kimlikler =
        ebeveynler.map((Person p) => p.id).toSet();
    final GameState oncesi = state;
    GameState next = state.copyWith(
      people: List<Person>.unmodifiable(
        state.people.map((Person p) => kimlikler.contains(p.id)
            ? p.copyWith(bond: (p.bond + bagFarki).clamp(0, 100))
            : p),
      ),
      player: state.player.copyWith(
        stats: state.player.stats.gain(happiness: mutluluk),
      ),
    );

    final String adlar = ebeveynler.map((Person p) => p.firstName).join(' ve ');
    final String metin = evli
        ? '$adlar haberi duyunca sevindi. "Genç yaşta zor ama yanındayız" '
            'dediler.'
        : '$adlar haberi duyunca uzun bir sessizlik oldu. '
            'Kızgın değiller; endişeliler.';

    next = _logLine(next, newAge, metin);
    return Notices.enqueue(next, <PendingNotice>[
      PendingNotice(
        id: 'aile-genc-ebeveyn-$newAge',
        kind: NoticeKind.dogum,
        age: newAge,
        title: 'Ailenin tepkisi',
        text: metin,
        effects: diffAppliedEffects(oncesi, next),
      ),
    ]);
  }

  /// Bir yıllık ilgisizliği uygular (Paket 24).
  ///
  /// Günlüğe her yıl kişi adı yazılmaz; yalnızca araya belirgin bir
  /// mesafe girdiğinde tek bir satır düşülür.
  GameState _applyBondDecay(GameState state, int newAge) {
    final BondDecayResult sonuc = BondDecay.applyYear(state);
    final GameState next = state.copyWith(
      people: sonuc.people,
      lastInteractionAge: sonuc.lastInteractionAge,
    );
    // İlgilenilmeyen flört biter (D-122); kayıt silinmez, bağ
    // arkadaşlığa döner ve oyuncuya bildirim gider.
    final ({GameState state, List<PendingNotice> notices}) flort =
        Finger.endNeglectedFlirts(next, newAge);
    GameState sonrasi = flort.state;
    if (flort.notices.isNotEmpty) {
      sonrasi = Notices.enqueue(sonrasi, flort.notices);
      for (final PendingNotice n in flort.notices) {
        sonrasi = _logLine(sonrasi, newAge, n.text);
      }
    }

    if (!sonuc.changed) return sonrasi;
    final String? satir = BondDecay.logLineFor(state, sonuc);
    if (satir == null) return sonrasi;
    return _logLine(sonrasi, newAge, satir);
  }

  GameState _applyTrackBonus(GameState state) {
    final EducationTrackInfo? alan = state.education.trackInfo;
    if (alan == null || !state.education.isSchoolStudent) return state;
    // Okurken yarım zamanlı çalışmanın bedeli var (D-131): derse ayrılan
    // zaman azalıyor. Alan katkısının **yarısı** gider; kapı kapanmaz,
    // kazanç yavaşlar.
    final bool okurkenCalisiyor = state.career.job?.partTime ?? false;
    final int zekaKatkisi = okurkenCalisiyor
        ? alan.intelligenceBonus ~/ 2
        : alan.intelligenceBonus;
    return state.copyWith(
      player: state.player.copyWith(
        stats: state.player.stats.gain(
          intelligence: zekaKatkisi,
          charisma: alan.charismaBonus,
          appearance: alan.appearanceBonus,
        ),
      ),
    );
  }

  /// Okurken yarım zamanlı çalışmanın yıllık bedeli (D-131).
  ///
  /// Ayakta geçen vardiyalar bedava değil: sağlık düşer, mutluluk biraz
  /// azalır. Çalışan öğrenci karşılığında **gerçek para** kazanıyor;
  /// bedel para kazancının karşılığıdır.
  GameState _applyPartTimeStrain(GameState state, int newAge) {
    if (!state.education.isSchoolStudent) return state;
    final JobType? is_ = state.career.job;
    if (is_ == null || !is_.partTime) return state;
    return state.copyWith(
      player: state.player.copyWith(
        stats: state.player.stats.gain(health: -2, happiness: -1),
      ),
      log: List<LifeLogEntry>.unmodifiable(<LifeLogEntry>[
        ...state.log,
        LifeLogEntry(
          age: newAge,
          text: 'Okul ve iş bir arada yürüdü. Yoruldun ama '
              'kendi paran oldu.',
          category: LogCategory.kisisel,
        ),
      ]),
    );
  }

  /// Yeni bir sınıf ortamı gerekiyorsa kurar.
  ///
  /// Sınıf atlamak (ör. 1'den 2'ye) yeni sınıf kurmaz; **kademe değişimi**
  /// kurar. Eski sınıftan bir bölüm arkadaş aynı kimlikle yeni sınıfa
  /// taşınır, kalanlar eski sınıfta kayıtlı kalır ve silinmez.
  ({List<Person> people, EducationState education}) _setUpClassIfNeeded({
    required GameState state,
    required List<Person> people,
    required EducationState education,
    required int newAge,
    required List<LifeLogEntry> log,
  }) {
    final SchoolLevel? level = education.level;
    if (level == null) {
      return (people: people, education: education);
    }

    // Okul, oyuncunun **yaşadığı şehre** bağlıdır (Paket 3).
    final String sehir = state.player.currentCity;
    final String schoolId = SchoolPeople.schoolIdFor(level, sehir);
    final String classId = SchoolPeople.classIdFor(level, sehir);

    // Sınıf zaten kuruluysa dokunma. Eski kayıtlardaki şehirsiz sınıf
    // kimliği de "bu kademenin sınıfı" sayılır; oyuncu sebepsiz yere
    // okul değiştirmiş olmaz.
    final String? mevcutSehir = SchoolPeople.cityOfClassId(education.classId);
    final bool ayniKademe = SchoolPeople.isClassOfLevel(
      education.classId,
      level,
    );
    final bool ayniSehir = mevcutSehir == null || mevcutSehir == sehir;
    if (ayniKademe &&
        ayniSehir &&
        people.any((Person p) => p.classId == education.classId)) {
      return (people: people, education: education);
    }

    const SchoolPeople okul = SchoolPeople();
    final GameState basis = state.copyWith(
      player: state.player.copyWith(age: newAge),
      people: List<Person>.unmodifiable(people),
    );
    final List<Person> oncekiSinif = people
        .where(
          (Person p) =>
              p.schoolTie == SchoolTie.sinifArkadasi &&
              p.classId != null &&
              p.classId == state.education.classId,
        )
        .toList(growable: false);

    final ClassRoster roster = okul.buildClass(
      state: basis,
      level: level,
      rng: _rng,
      previousClassmates: oncekiSinif,
      city: sehir,
    );

    // Taşınanlar aynı kimlikle yeni sınıfa geçer; kayıt kopyalanmaz.
    final Set<String> tasinan = roster.movedIds.toSet();
    final List<Person> guncel = people
        .map(
          (Person p) =>
              tasinan.contains(p.id) ? okul.moveToClass(p, level, sehir) : p,
        )
        .toList(growable: false);

    final Iterable<Person> ogretmenler = roster.newPeople.where(
      (Person p) => p.schoolTie == SchoolTie.ogretmen,
    );
    if (ogretmenler.isNotEmpty) {
      final Person ogretmen = ogretmenler.first;
      log.add(
        LifeLogEntry(
          age: newAge,
          text: tasinan.isEmpty
              ? 'Yeni sınıfında öğretmenin ${ogretmen.fullName} oldu; '
                    'bütün yüzler yabancı.'
              : 'Yeni sınıfında öğretmenin ${ogretmen.fullName} oldu; '
                    '${tasinan.length} tanıdık yüz de seninle aynı sınıfta.',
          category: LogCategory.kisisel,
        ),
      );
    }

    return (
      people: <Person>[...guncel, ...roster.newPeople],
      education: education.copyWith(schoolId: schoolId, classId: classId),
    );
  }

  /// Okula başlatır veya bir üst sınıfa geçirir.
  ///
  /// Basit akış: belirlenen yaşta 1. sınıfa başlanır, her yaş bir sınıf
  /// ilerler, son sınıftan sonra okul biter. Sınav, not ve diploma yoktur.
  EducationState _advanceEducation(
    EducationState current,
    int newAge, {
    required int intelligence,
    required List<LifeLogEntry> log,
  }) {
    // Üniversite öğrencisi her yıl bir sınıf ilerler ve süre dolunca mezun
    // olur. Lise kaydı burada değişmez.
    if (current.isUniversityStudent) {
      final int yil = (current.universityYear ?? 1) + 1;
      final int sure = current.program?.durationYears ?? 4;
      if (yil > sure) {
        return current.copyWith(universityFinished: true, universityYear: sure);
      }
      return current.copyWith(universityYear: yil);
    }

    if (current.finished) return current;

    if (!current.enrolled) {
      // Yalnızca okula başlama yaşında kayıt olunur; daha ileri yaşta
      // kendiliğinden okula başlatılmaz.
      final bool baslamaZamani = newAge == prototypeOnlySchoolStartAge;
      if (!baslamaZamani) return current;
      return EducationState(
        enrolled: true,
        grade: 1,
        startedAtAge: newAge,
        // İlk not ortalaması okula başlarken oluşur; öncesinde not yok.
        gradeAverage: (intelligence * 0.8).round().clamp(0, 100),
      );
    }

    // Yıl sonu: not ortalaması güncellenir, gerekirse sınıf tekrarlanır
    // (Paket 13).
    final int ortalama = SchoolPerformance.prototypeOnlyYearEndAverage(
      current: current.gradeAverage ?? 50,
      intelligence: intelligence,
      rng: _rng,
    );

    final int mevcutSinif = current.grade ?? 1;
    if (ortalama < SchoolPerformance.prototypeOnlyFailAverage &&
        mevcutSinif >= SchoolPerformance.prototypeOnlyFailMinGrade) {
      final int tekrar = current.repeatedYears + 1;
      // Küçük çocuk okuldan atılmaz; sınıfı tekrarlar.
      final bool ayrilir =
          tekrar > SchoolPerformance.prototypeOnlyMaxRepeats &&
          newAge >= SchoolPerformance.prototypeOnlyDropOutMinAge;
      if (ayrilir) {
        log.add(
          LifeLogEntry(
            age: newAge,
            text:
                'Notların toparlanmadı ve okulla yolların ayrıldı. '
                'Eğitim geçmişin kayıtlarda duruyor.',
            category: LogCategory.kisisel,
          ),
        );
        return current.copyWith(
          enrolled: false,
          droppedOut: true,
          gradeAverage: ortalama,
          repeatedYears: tekrar,
        );
      }
      log.add(
        LifeLogEntry(
          age: newAge,
          text:
              'Not ortalaman $ortalama; sınıfta kaldın. '
              '${current.grade}. sınıfı tekrar okuyacaksın.',
          category: LogCategory.kisisel,
        ),
      );
      return current.copyWith(gradeAverage: ortalama, repeatedYears: tekrar);
    }

    final int nextGrade = (current.grade ?? 1) + 1;
    if (nextGrade > lastGrade) {
      return current.asFinished().copyWith(gradeAverage: ortalama);
    }
    return current.copyWith(grade: nextGrade, gradeAverage: ortalama);
  }

  /// Lise bitince üniversite sınav puanını **bir kez** hesaplar.
  ///
  /// Lise yerleştirme puanından ayrı bir değerdir; hesaplanıp saklanır ve
  /// başvuru ekranında oyuncuya olduğu gibi gösterilir.
  EducationState _applyUniversityExam({
    required GameState state,
    required EducationState before,
    required EducationState education,
    required int newAge,
    required List<LifeLogEntry> log,
  }) {
    if (before.finished || !education.finished) return education;
    if (education.universityExamScore != null) return education;

    final int puan = const EducationPath().computeUniversityExamScore(
      state.copyWith(education: education),
      _rng,
    );
    log.add(
      LifeLogEntry(
        age: newAge,
        text: 'Üniversite sınavından $puan puan aldın.',
        category: LogCategory.kisisel,
      ),
    );
    return education.copyWith(universityExamScore: puan);
  }

  /// 8. sınıftan 9. sınıfa geçerken yerleştirme puanını hesaplar.
  ///
  /// Puan bir kez hesaplanır ve eğitim geçmişine yazılır; lise alanı seçimi
  /// bu puana bakar.
  EducationState _applyPlacementExam({
    required GameState state,
    required EducationState education,
    required int newAge,
    required List<LifeLogEntry> log,
  }) {
    if (education.placementScore != null) return education;
    if (!education.enrolled) return education;
    if ((education.grade ?? 0) != 9) return education;

    final int puan = const EducationPath().placementScore(state, _rng);
    log.add(
      LifeLogEntry(
        age: newAge,
        text:
            'Ortaokul bitti. Yerleştirme puanın $puan. '
            'Artık lise alanını seçebilirsin.',
        category: LogCategory.kisisel,
      ),
    );
    return education.copyWith(placementScore: puan);
  }

  /// Okulun dönüm noktaları için bildirim üretir (Paket 17).
  ///
  /// Yalnızca **gerçekten olmuş** geçişler bildirilir: okula başlama,
  /// ortaokuldan liseye geçiş, lisenin ve üniversitenin bitişi. Puanlar
  /// hesaplanmışsa metne yazılır, hesaplanmadıysa hiç yazılmaz — uydurma
  /// puan gösterilmez.
  List<PendingNotice> _schoolNotices({
    required EducationState before,
    required EducationState after,
    required int age,
  }) {
    final List<PendingNotice> bildirimler = <PendingNotice>[];

    if (!before.enrolled && after.enrolled && before.startedAtAge == null) {
      bildirimler.add(Notices.schoolStart(playerAge: age));
    }

    // Ortaokuldan liseye geçiş: kademe gerçekten değişmiş olmalı.
    if (before.level == SchoolLevel.ortaokul &&
        after.level == SchoolLevel.lise) {
      bildirimler.add(
        Notices.highSchoolStart(
          playerAge: age,
          placementScore: after.placementScore,
        ),
      );
    }

    if (!before.finished && after.finished && before.enrolled) {
      bildirimler.add(
        Notices.highSchoolEnd(
          playerAge: age,
          examScore: after.universityExamScore,
        ),
      );
    }

    if (!before.universityFinished && after.universityFinished) {
      bildirimler.add(
        Notices.universityEnd(playerAge: age, programName: after.program?.name),
      );
    }

    return bildirimler;
  }

  /// Okula başlama, kademe değişimi ve okulun bitişini günlüğe yazar.
  void _logEducationChange({
    required List<LifeLogEntry> log,
    required EducationState before,
    required EducationState after,
    required int age,
  }) {
    if (before.enrolled == after.enrolled &&
        before.grade == after.grade &&
        before.finished == after.finished) {
      return;
    }

    if (!before.enrolled && after.enrolled) {
      log.add(
        LifeLogEntry(
          age: age,
          text: 'Okula başladın. Çantan sırtında, ilk günün.',
          category: LogCategory.kisisel,
        ),
      );
      return;
    }

    if (after.finished && before.enrolled) {
      log.add(
        LifeLogEntry(
          age: age,
          text: 'Lise bitti. Okul defterlerini bir kutuya kaldırdın.',
          category: LogCategory.kisisel,
        ),
      );
      return;
    }

    // Kademe değiştiyse bildir; aynı kademedeki sınıf artışı günlüğü şişirmez.
    if (before.level != after.level && after.level != null) {
      log.add(
        LifeLogEntry(
          age: age,
          text: '${after.level!.label} sıralarına geçtin.',
          category: LogCategory.kisisel,
        ),
      );
    }
  }

  /// Kişinin yaşını bir artırır ve yalnızca yaşa bağlı **tutarlılık**
  /// düzeltmelerini uygular (okula başlayan çocuk gibi). Meslek ve ekonomik
  /// durum uydurulmaz: çalışmayan kişiye meslek atanmaz.
  Person _agePerson(Person person) {
    final int age = person.age + 1;
    // Oyuncunun çocuğu kendi gelişim sistemiyle ilerler (D-045): okul,
    // meslek ve ekonomik durum burada rastgele atanmaz.
    if (person.relation == RelationType.cocuk) {
      return person.copyWith(age: age);
    }
    EmploymentStatus employment = person.employment;
    String? occupation = person.occupation;
    WealthTier? wealth = person.wealth;

    if (employment == EmploymentStatus.cocuk && age >= 6) {
      employment = EmploymentStatus.ogrenci;
    } else if (employment == EmploymentStatus.ogrenci && age >= 24) {
      employment = _rng.pickWeighted(
        <EmploymentStatus>[
          EmploymentStatus.calisiyor,
          EmploymentStatus.issiz,
          EmploymentStatus.evIsleri,
        ],
        <double>[0.66, 0.18, 0.16], // prototypeOnly
      );
    } else if (employment == EmploymentStatus.calisiyor && age >= 65) {
      employment = EmploymentStatus.emekli;
    }

    if (employment == EmploymentStatus.calisiyor) {
      occupation ??= _rng.pick(meslekler);
    } else {
      occupation = null;
    }

    if (wealth == null && age >= 18) {
      wealth = _rng.pickWeighted(
        WealthTier.values,
        <double>[0.12, 0.26, 0.38, 0.17, 0.07], // prototypeOnly
      );
    }

    // Oyuncunun çocuğu büyürken okul kademesi yaşıyla birlikte ilerler;
    // böylece 22 yaşındaki çocuk "ilkokul öğrencisi" görünmez. Okul
    // arkadaşlarının kademesi **değişmez**: o bilgi "hangi kademede
    // tanışıldığı"dır.
    final SchoolLevel? kademe = person.relation == RelationType.cocuk
        ? Parenthood.schoolLevelForAge(age)
        : person.schoolLevel;

    return person.copyWith(
      age: age,
      employment: employment,
      occupation: occupation,
      wealth: wealth,
      schoolLevel: kademe,
    );
  }
}

import 'dart:math';

import '../../data/name_pool.dart';
import '../career/career_progress.dart';
import '../career/retirement.dart';
import 'grandchildren.dart';
import '../social/social_engine.dart';
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
import '../life/mortality.dart';
import '../models/game_settings.dart';
import '../models/game_state.dart';
import '../interaction/bond_decay.dart';
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

    // Yetişkin çocukların kendi çocukları olabilir (Paket 12). Torun
    // gerçek bir kişi kaydıdır ve doğduğu yıl oluşturulur.
    final List<Person> yeniTorunlar = <Person>[];
    final List<String> torunHaberleri = <String>[];
    for (final Person cocuk in peopleWithChildren) {
      final Person? torun = Grandchildren.maybeBorn(
        state: state.copyWith(
          people: List<Person>.unmodifiable(<Person>[
            ...peopleWithChildren,
            ...yeniTorunlar,
          ]),
        ),
        child: cocuk,
        rng: _rng,
      );
      if (torun == null) continue;
      yeniTorunlar.add(torun);
      torunHaberleri.add(
        '${cocuk.firstName} bir çocuk sahibi oldu: ${torun.firstName}. '
        'Artık dede/nine oldun.',
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
          stats: afterDeaths.player.stats.copyWith(
            happiness:
                afterDeaths.player.stats.happiness +
                Grandchildren.prototypeOnlyHappiness * yeniTorunlar.length,
          ),
        ),
      );
    }
    if (olumSonucu.happinessLoss > 0) {
      afterDeaths = advanced.copyWith(
        player: advanced.player.copyWith(
          stats: advanced.player.stats.copyWith(
            happiness:
                (advanced.player.stats.happiness - olumSonucu.happinessLoss)
                    .clamp(0, 100),
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

    // Yas zamanla hafifler: her yıl kalan yasın bir bölümü mutluluğa geri
    // döner.
    afterDeaths = _easeGrief(afterDeaths, olumSonucu.happinessLoss > 0);

    // Yaşlanmanın dış görünüşe etkisi (D-051): yetişkinlikte başlar,
    // kademelidir ve kişiden kişiye değişir. Yalnızca gerçek değer
    // değişir; mutluluk ve zekâ bundan etkilenmez.
    afterDeaths = _applyAging(afterDeaths, newAge);

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

    // Lise alanının yıllık küçük kazancı; alan seçimi kozmetik değildir.
    final GameState withTrack = _applyTrackBonus(afterDeaths);

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

    final SponsorOffer? teklif = SocialIncome.maybeOffer(sonraki, _rng);
    if (teklif == null) return sonraki;
    return _logLine(
      sonraki.copyWith(sponsorOffer: teklif),
      newAge,
      'Sosyal medyada bir ${teklif.label} sponsorluk teklif etti. '
      'Aktiviteler → Sosyal medya bölümünden yanıtlayabilirsin.',
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
        next = Notices.enqueue(next, <PendingNotice>[mirasBildirimi]);
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

  /// Yaşlanmanın dış görünüşe etkisini uygular (D-051).
  ///
  /// Etki yılda **bir kez**, yaş ilerletmenin içinde uygulanır; oyunu
  /// kapatıp açmak aynı yılın etkisini ikinci kez uygulamaz.
  GameState _applyAging(GameState state, int newAge) {
    final int delta = Aging.yearlyDelta(
      age: newAge,
      appearance: state.player.stats.appearance,
      health: state.player.stats.health,
      rng: _rng,
    );
    if (delta == 0) return state;

    final GameState next = state.copyWith(
      player: state.player.copyWith(
        stats: state.player.stats.copyWith(
          appearance: state.player.stats.appearance + delta,
        ),
      ),
    );
    if (!Aging.worthLogging(delta)) return next;

    return next.copyWith(
      log: List<LifeLogEntry>.unmodifiable(<LifeLogEntry>[
        ...next.log,
        LifeLogEntry(
          age: newAge,
          text:
              'Aynada bu yıl birkaç yeni çizgi gördün; dış görünüşün '
              '${next.player.stats.appearance}.',
          category: LogCategory.kisisel,
        ),
      ]),
    );
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
        stats: state.player.stats.copyWith(
          happiness: (state.player.stats.happiness + geriVerilen).clamp(0, 100),
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
    final int sonra = (once + donem.prototypeOnlyHappiness).clamp(0, 100);
    final int gercek = sonra - once;

    return state.copyWith(
      player: state.player.copyWith(
        stats: state.player.stats.copyWith(happiness: sonra),
      ),
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
    return dogum.state.copyWith(
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
    if (!sonuc.changed) return next;
    final String? satir = BondDecay.logLineFor(state, sonuc);
    if (satir == null) return next;
    return _logLine(next, newAge, satir);
  }

  GameState _applyTrackBonus(GameState state) {
    final EducationTrackInfo? alan = state.education.trackInfo;
    if (alan == null || !state.education.isSchoolStudent) return state;
    return state.copyWith(
      player: state.player.copyWith(
        stats: state.player.stats.copyWith(
          intelligence:
              state.player.stats.intelligence + alan.intelligenceBonus,
          charisma: state.player.stats.charisma + alan.charismaBonus,
          appearance: state.player.stats.appearance + alan.appearanceBonus,
        ),
      ),
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

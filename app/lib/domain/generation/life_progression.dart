import 'dart:math';

import '../../data/name_pool.dart';
import '../career/craft_mastery.dart';
import '../career/career_progress.dart';
import '../combat/combat_career_engine.dart';
import '../combat/sport_school_conflict.dart';
import '../family/adult_child_support.dart';
import '../family/child_advice.dart';
import '../family/child_school_issue.dart';
import '../family/family_disputes.dart';
import '../family/in_law_relations.dart';
import '../family/family_mood.dart';
import '../career/retirement.dart';
import '../life/chronic_engine.dart';
import '../life/critical_health.dart';
import '../life/life_goals.dart';
import '../life/year_review.dart';
import 'grandchildren.dart';
import '../social/social_engine.dart';
import '../../data/media_catalog.dart';
import 'child_marriage.dart';
import 'child_marriage_life.dart';
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
import '../economy/household_budget.dart';
import '../economy/rental_engine.dart';
import '../economy/investment_engine.dart';
import '../economy/vehicle_inspection.dart';
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
import '../models/combat_career.dart';
import '../models/game_state.dart';
import '../interaction/bond_decay.dart';
import '../interaction/finger.dart';
import '../models/life_log.dart';
import '../sports/school_club_engine.dart';
import '../sports/football_pro_engine.dart';
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
import 'spouse_life.dart';
import '../models/relation.dart';
import '../models/wealth.dart';
import 'random_util.dart';
import 'parent_divorce.dart';
import 'step_parents.dart';
import 'step_siblings.dart';
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

    // Çözülmemiş sağlık krizi varken de yaş ilerlemez (Paket AQ).
    //
    // Bu bir hatanın düzeltmesi: `rollCrisis` ekranda kriz varken yeni
    // kriz açmıyordu ama **yaş ilerliyordu**. Yani oyuncu krizi
    // yanıtlamadan yıllarca ileri gidebiliyor, kriz ekranda asılı
    // kalıyordu. Kritik sağlık durumu da aynı kayıt üzerinden
    // çalıştığından zorunlu çözüm bu satırla gerçekten zorunlu oluyor.
    if (state.hasPendingCrisis) return state;

    // Sağlık yıl başında zaten acil banda inmişse (örneğin bir
    // aktivitenin ya da olay seçiminin ardından) yaş **ilerlemeden**
    // zorunlu çözüm açılır. Böylece hiçbir yol "sağlık 0 ama hayat
    // devam ediyor" durumunu bir sonraki yıla taşıyamaz.
    final GameState acilKontrol = CriticalHealth.enforce(
      state: state,
      age: state.player.age,
      cause: CriticalHealth.causeFromState(state),
    );
    if (acilKontrol.hasPendingCrisis) return acilKontrol;

    // Biten yılın özeti yaşlanmadan **önce** hesaplanır: fotoğraf yılın
    // başında alınmıştır, karşılaştırma yılın sonundaki hâlle yapılır
    // (D-096). Özet yoksa (ilk yıl, yeni kayıt) `null` kalır.
    // Hiçbir şey değişmediyse özet üretilmez; eski yılın özeti ekranda
    // bırakılmaz.
    final YearSummary? yilOzeti = YearReview.summarize(state.yearMark, state);

    // Hayat hedefleri (D-156): yıl içinde yapılanlar **o yılın yaşıyla**
    // kaydedilsin diye yaş artmadan **önce** bakılır. Kırk dörtte alınan
    // ev "kırk beşinde aldın" diye yazılmaz.
    state = LifeGoals.advanceYear(state: state, newAge: state.player.age);

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
          // Kardeş de kendi hayatını yaşar (D-158): okur, iş bulur,
          // emekli olur. Kayıt kardeşi doğuştan taşıyordu ama hayatı
          // hiç ilerlemiyordu. Yeğen kaydı da bu yüzden hiç oluşmuyordu.
          // Paket AO §28: üvey kardeş, yarım kardeş ve üvey çocuk da
          // kendi hayatını yaşar. Paket AO/1'de bu kişiler gerçek kayıt
          // olarak doğdu ama listede yalnızca yaşlanıyorlardı: okula
          // başlamıyor, iş bulmuyor, emekli olmuyorlardı. Yarım kardeş
          // 0 yaşında doğduğu için bu en çok onda görünüyordu — kırk
          // yaşına gelene kadar hiçbir şey yaşamamış oluyordu.
          final bool kendiHayati =
              person.relation == RelationType.cocuk ||
              person.relation == RelationType.torun ||
              person.relation == RelationType.yegen ||
              person.relation == RelationType.kardes ||
              person.relation == RelationType.uveyKardes ||
              person.relation == RelationType.yariKardes ||
              person.relation == RelationType.uveyCocuk;
          if (!person.isAlive || !kendiHayati) {
            return person;
          }
          // Paket AP §41: oyuncunun verdiği tavsiye kişinin **kendi**
          // kararlarının ihtimalini kaydırır. Tavsiye yoksa pay 0'dır
          // ve hiçbir şey değişmez; ek zar atılmadığı için zar sırası
          // da kaymaz.
          final ({Person person, List<String> news}) sonuc =
              ChildProgression.advance(
            person,
            _rng,
            adviceBoost: ChildAdvice.boostFor(state, person),
          );
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
    /// Paket AP §16: bu yıl evlenenlerin **gerçek eş kayıtları**.
    final List<Person> yeniEsler = <Person>[];
    for (final Person kisi in peopleWithChildren) {
      // Aynı kural iki bağa da işler: kardeş de evlenir (D-158).
      // Paket AO §28: üvey kardeş, yarım kardeş ve üvey çocuk da yetişkin
      // olunca kendi evliliğini yapar. Bağ kişinin kendi kaydından
      // okunur; `ChildMarriage` zaten bağ başına davranıyor, ikinci bir
      // evlilik sistemi kurulmadı.
      const Set<RelationType> kendiEvliligiOlanlar = <RelationType>{
        RelationType.kardes,
        RelationType.uveyKardes,
        RelationType.yariKardes,
        RelationType.uveyCocuk,
      };
      // Paket AP §16: eş artık gerçek bir kişi olarak üretiliyor. Durum
      // veriliyor ki kimlik çakışması denetlenebilsin ve şehir/soyadı
      // gerçek kayıttan türetilebilsin.
      //
      // `people` listesi döngü içinde büyüdüğü için **o anki** hâli
      // veriliyor: aynı yıl iki çocuk evlenirse ikinci eş, birincinin
      // kimliğini görebilir ve çakışma oluşmaz.
      final ChildMarriageResult? evlilik = ChildMarriage.maybeMarry(
        child: kisi,
        playerAge: newAge,
        rng: _rng,
        relation: kendiEvliligiOlanlar.contains(kisi.relation)
            ? kisi.relation
            : RelationType.cocuk,
        state: state.copyWith(
          people: List<Person>.unmodifiable(<Person>[
            ...peopleWithChildren,
            ...evlilikSonrasi,
            ...yeniEsler,
          ]),
        ),
      );
      if (evlilik == null) {
        evlilikSonrasi.add(kisi);
        continue;
      }
      evlilikSonrasi.add(evlilik.person);
      // Yalnızca metinde kalan eş yok: gerçek kayıt listeye giriyor.
      if (evlilik.spouse != null) yeniEsler.add(evlilik.spouse!);
      aileBildirimleri.add(evlilik.notice);
      aileHaberleri.add(evlilik.logText);
    }
    final List<Person> evlilikliKisiler =
        List<Person>.unmodifiable(<Person>[...evlilikSonrasi, ...yeniEsler]);

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

    // Eş de kendi hayatını yaşar (D-154): iş değiştirir, emekli olur,
    // hastalanır. Kariyer mevcut `ChildProgression` ile ilerler; paralel
    // bir sistem kurulmaz. Yalnızca **yürüyen** evliliğin eşi ilerletilir.
    final List<String> esHaberleri = <String>[];
    int esMutlulukEtkisi = 0;
    final List<Person> esSonrasi = <Person>[];
    final String? yurumekteOlanEsId = state.marriage != null &&
            state.marriage!.isActive
        ? state.marriage!.spouseId
        : null;
    for (final Person kisi in evlilikliKisiler) {
      if (kisi.id != yurumekteOlanEsId ||
          !kisi.isAlive ||
          kisi.relation != RelationType.es) {
        esSonrasi.add(kisi);
        continue;
      }
      final SpouseYear yil = SpouseLife.advance(
        spouse: kisi,
        playerAge: newAge,
        rng: _rng,
      );
      esSonrasi.add(yil.person);
      esHaberleri.addAll(yil.news);
      esMutlulukEtkisi += yil.playerHappiness;
      for (final String metin in yil.noticeTexts) {
        aileBildirimleri.add(
          PendingNotice(
            id: 'es-haber-${kisi.id}-$newAge-${aileBildirimleri.length}',
            kind: NoticeKind.aileDonum,
            age: newAge,
            title: 'Eşinden haber',
            text: metin,
            personId: kisi.id,
          ),
        );
      }
    }
    final List<Person> esliKisiler = List<Person>.unmodifiable(esSonrasi);

    // Kardeşin çocuğu **yeğen** olarak doğar (D-158). Kural torunla aynı
    // yerde durur; yalnızca bağ ve kimlik öneki değişir. Yeğen kaydı
    // `RelationType.yegen` D-087'den beri vardı ama doğal yoldan hiç
    // oluşmuyordu: yalnızca kuşak devrinde ortaya çıkıyordu.
    final List<Person> yeniYegenler = <Person>[];
    final List<String> yegenHaberleri = <String>[];
    for (final Person kardes in esliKisiler) {
      // Paket AO §12-§13: yarım kardeş **kan bağıdır** — onun çocuğu da
      // gerçekten yeğendir. Üvey kardeş bilerek dışarıda bırakıldı: kan
      // bağı yok ve her üvey kardeşe ayrıca çocuk üretmek §46'nın
      // uyardığı kişi kalabalığını doğuruyor. Bu bir V1 sınırı, kesin
      // kural değil; soru `docs/DESIGN_REVIEW_QUEUE.md` Q-187'de.
      if (kardes.relation != RelationType.kardes &&
          kardes.relation != RelationType.yariKardes) {
        continue;
      }
      final Person? yegen = Grandchildren.maybeBornTo(
        state: state.copyWith(
          people: List<Person>.unmodifiable(<Person>[
            ...esliKisiler,
            ...yeniTorunlar,
            ...yeniYegenler,
          ]),
        ),
        parent: kardes,
        rng: _rng,
        // Bağ kişinin kendi kaydından gelir: `maybeBornTo` ebeveynin
        // bağını doğruluyor, sabit `kardes` yazmak yarım kardeşi elerdi.
        parentRelation: kardes.relation,
        childRelation: RelationType.yegen,
        idPrefix: 'yegen',
      );
      if (yegen == null) continue;
      yeniYegenler.add(yegen);
      final String haber =
          '${kardes.firstName} bir çocuk sahibi oldu: ${yegen.firstName}. '
          'Yeğenin oldu.';
      yegenHaberleri.add(haber);
      aileBildirimleri.add(
        PendingNotice(
          id: 'yegen-${yegen.id}-$newAge',
          kind: NoticeKind.aileDonum,
          age: newAge,
          title: 'Yeğenin oldu',
          text: haber,
          personId: yegen.id,
        ),
      );
    }

    // Okul kulüpleri / takımlar: sezon yaş geçişinde işlenir (Paket AU).
    //
    // Yaş **artmadan** çağrılır ki sezon biten yılın yaşıyla kaydedilsin;
    // hayat hedeflerinde (`LifeGoals`) olduğu gibi. Her sezon popup
    // üretmez: `log` günlüğe yazılır, yalnızca kilometre taşı (kaptanlık)
    // bildirim olur.
    final ({
      GameState state,
      List<String> log,
      List<String> milestones,
    }) kulupSezonu = const SchoolClubEngine().advanceSeason(state, _rng);
    state = kulupSezonu.state;

    // Profesyonel futbol sezonu (Paket AY). Okul kulübünden ayrı:
    // kulüp sezonu öğrencilik dönemine, bu yetişkin kariyere bakar.
    final ({GameState state, List<String> log, String? milestone})
        futbolSezonu = const FootballProEngine().advanceSeason(state, _rng);
    state = futbolSezonu.state;

    final List<LifeLogEntry> log = <LifeLogEntry>[
      ...state.log,
      for (final String satir in kulupSezonu.log)
        LifeLogEntry(age: newAge, text: satir, category: LogCategory.kisisel),
      for (final String satir in futbolSezonu.log)
        LifeLogEntry(age: newAge, text: satir, category: LogCategory.kisisel),
      for (final String haber in yegenHaberleri)
        LifeLogEntry(age: newAge, text: haber, category: LogCategory.aile),
      LifeLogEntry(
        age: newAge,
        text: '$newAge yaşına girdin.',
        category: LogCategory.yasDegisimi,
      ),
      for (final String haber in esHaberleri)
        LifeLogEntry(age: newAge, text: haber, category: LogCategory.aile),
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
      happiness: state.player.stats.happiness,
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
          // **Düzeltme (D-154):** burada `peopleWithChildren` kullanılıyordu.
          // Çocuk evliliğinin (D-121) ve eşin kendi hayatının (D-154)
          // güncellediği kayıtlar bu yüzden boru hattına hiç girmiyordu:
          // `dev.marriedAtAge` kalıcı olmadığı için **aynı çocuk her yıl
          // yeniden evleniyordu** (ölçüldü: 12 yılda 4 düğün).
          people: esliKisiler,
          education: education,
          newAge: newAge,
          log: log,
        );
    final List<Person> peopleWithSchool = okulSonucu.people;

    // Okul değişti mi? (Paket AU) Kademe atlayınca ya da şehir değişince
    // yeni okul kimliği gelir. O zaman **aktif** kulüp üyelikleri kapanır
    // ama geçmiş silinmez: yeni okulda yeniden başvurulur, geçmiş deneyim
    // kabul ihtimaline yardım eder.
    if (okulSonucu.education.schoolId != education.schoolId) {
      state = const SchoolClubEngine()
          .onSchoolChanged(state, okulSonucu.education.schoolId);
    }

    // Çocuk, torun, yeğen ve kardeşin bu yıl yaşadığı önemli gelişmeler
    // aile haberi olarak günlüğe girer; kişinin kendi geçmişinde zaten
    // kayıtlıdır (D-158'den sonra liste kardeşi de içeriyor).
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
      ...yeniYegenler,
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

    // Ustalık basamağı (D-155): aynı işte geçen yıl sayısı bir eşiği
    // geçtiyse o yıl kaydedilir. İşten çıkarılmadan **önce** bakılır;
    // çalışılan yılın kazanımı kaybolmaz.
    final MasteryStage? yeniBasamak = maas.state.career.isEmployed
        ? CraftMastery.stageReachedAt(
            maas.state.career.yearsInJob(newAge),
          )
        : null;
    if (yeniBasamak != null) {
      final String unvan = maas.state.career.title;
      final String metin =
          '$unvan olarak ${yeniBasamak.yearsNeeded} yılı doldurdun: '
          'artık ${trLower(yeniBasamak.label)} sayılıyorsun.';
      maas = (
        state: maas.state.copyWith(
          career: maas.state.career.withMilestone(newAge, metin),
        ),
        logText: maas.logText,
      );
      log.add(
        LifeLogEntry(
          age: newAge,
          text: metin,
          category: LogCategory.kisisel,
        ),
      );
      kariyerBildirimleri.add(
        PendingNotice(
          id: 'ustalik-${yeniBasamak.name}-$newAge',
          kind: NoticeKind.kariyer,
          age: newAge,
          title: 'Meslekte ${yeniBasamak.label}',
          text: metin,
        ),
      );
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
      // **Düzeltme (D-154):** aile dönüm noktası bildirimleri
      // (çocuğun düğünü, torunun doğumu, eşten haber) toplanıyor ama
      // hiçbir yere yazılmıyordu; ekrana hiç ulaşmıyorlardı.
      notices: List<PendingNotice>.unmodifiable(<PendingNotice>[
        ...state.notices,
        ...aileBildirimleri,
        // Kulüp kilometre taşları (Paket AU). Yalnızca kaptanlık gibi
        // önemli anlar bildirim olur; normal sezon günlükte kalır, çünkü
        // her yıl beş popup kimseye iyi gelmez.
        for (int i = 0; i < kulupSezonu.milestones.length; i++)
          PendingNotice(
            id: 'kulup-donum-$newAge-$i',
            kind: NoticeKind.okul,
            age: newAge,
            title: 'Takımda bir ilk',
            text: kulupSezonu.milestones[i],
          ),
        // Futbol kariyerinin dönüm noktaları (Paket AY): ilk sezon ve
        // kariyerin bitişi. Sıradan sezon günlükte kalır.
        if (futbolSezonu.milestone != null)
          PendingNotice(
            id: 'futbol-donum-$newAge',
            kind: NoticeKind.kariyer,
            age: newAge,
            title: 'Futbol kariyeri',
            text: futbolSezonu.milestone!,
          ),
      ]),
    );

    // Kaybın etkisi: mutluluk düşer, ama bu **kalıcı bir ceza değildir**.
    // Düşen miktar yas olarak saklanır ve sonraki yıllarda geri verilir
    // (D-036).
    GameState afterDeaths = advanced;
    // Eşin hastalığı oyuncuyu da etkiler (D-154); etki **gerçekten**
    // uygulanır, yalnızca metinde kalmaz.
    if (esMutlulukEtkisi != 0) {
      afterDeaths = afterDeaths.copyWith(
        player: afterDeaths.player.copyWith(
          stats: afterDeaths.player.stats.gain(happiness: esMutlulukEtkisi),
        ),
      );
    }
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

    // Spor kariyeri (Paket AL): form aşınır, sakatlık iyileşir, koç
    // ücreti ödenir, uzun ara sıralamayı düşürür.
    final ({GameState state, List<String> lines}) spor =
        CombatCareerEngine.advanceYear(afterDeaths, newAge, _rng);
    afterDeaths = spor.state;
    for (final String satir in spor.lines) {
      afterDeaths = _logLine(afterDeaths, newAge, satir);
    }
    // Spor sponsorluğu: başarı, kademe, itibar ve kitle birlikte
    // arandığı için her yıl çıkmaz (§15).
    final ({GameState state, int fee, String? text}) sporSponsor =
        CombatCareerEngine.offerSportSponsor(afterDeaths, _rng);
    afterDeaths = sporSponsor.state;
    if (sporSponsor.text != null) {
      afterDeaths = _logLine(afterDeaths, newAge, sporSponsor.text!);
    }
    // Müsabaka fırsatı: her yıl çıkmaz (§43).
    final ({GameState state, PendingBout? bout, String? text}) firsat =
        CombatCareerEngine.offerBout(afterDeaths, _rng);
    afterDeaths = firsat.state;
    if (firsat.text != null) {
      afterDeaths = _logLine(afterDeaths, newAge, firsat.text!);
    }
    // Okul + spor çatışması (Paket AL/2, §6): yalnızca okula kayıtlı
    // genç sporcuda, ciddi kademedeki bekleyen bir müsabaka varken ve
    // yılda en fazla bir kez çıkar. Kararı oyuncu spor ekranında
    // verir; verilene kadar müsabaka bekler.
    final CombatCareer? sporKariyeri =
        CombatCareerEngine.activeCareer(afterDeaths);
    if (sporKariyeri != null) {
      final ({GameState state, String? text}) catisma =
          SportSchoolConflict.maybeRaise(afterDeaths, sporKariyeri, _rng);
      afterDeaths = catisma.state;
      if (catisma.text != null) {
        afterDeaths = _logLine(afterDeaths, newAge, catisma.text!);
      }
    }

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

    // --- Paket AP §19-§23, §50: yetişkin çocuğun evlilik hayatı ------
    //
    // Sıra önemli ve bilinçli:
    //
    // 1. Eşi vefat edenler **dul** yazılır. Ölümün kendisi yukarıdaki
    //    genel ölüm motorundan geldi (gelin/damat sıradan bir kişidir);
    //    eksik olan şey kaydın güncellenmesiydi.
    // 2. Sonra boşanmalar işlenir.
    // 3. En sonda yeniden evlenmeler. Böylece aynı yıl içinde bir kişi
    //    hem boşanıp hem yeniden evlenemez: `maybeRemarry` soğuma
    //    süresi arıyor ve bu yıl boşanan kişide o süre henüz 0.
    for (final ChildMarriageYear tur in <ChildMarriageYear>[
      ChildMarriageLife.applySpouseDeaths(afterDeaths, newAge),
    ]) {
      afterDeaths = tur.state;
      for (final String satir in tur.logTexts) {
        afterDeaths = _logLine(afterDeaths, newAge, satir);
      }
      if (tur.notices.isNotEmpty) {
        afterDeaths = Notices.enqueue(afterDeaths, tur.notices);
      }
    }
    final ChildMarriageYear bosanmalar =
        ChildMarriageLife.maybeDivorce(afterDeaths, newAge, _rng);
    afterDeaths = bosanmalar.state;
    for (final String satir in bosanmalar.logTexts) {
      afterDeaths = _logLine(afterDeaths, newAge, satir);
    }
    if (bosanmalar.notices.isNotEmpty) {
      afterDeaths = Notices.enqueue(afterDeaths, bosanmalar.notices);
    }
    final ChildMarriageYear yenidenEvlilikler =
        ChildMarriageLife.maybeRemarry(afterDeaths, newAge, _rng);
    afterDeaths = yenidenEvlilikler.state;
    for (final String satir in yenidenEvlilikler.logTexts) {
      afterDeaths = _logLine(afterDeaths, newAge, satir);
    }
    if (yenidenEvlilikler.notices.isNotEmpty) {
      afterDeaths = Notices.enqueue(afterDeaths, yenidenEvlilikler.notices);
    }

    // --- Paket AP §5-§7: çocuğun okul hayatı --------------------------
    //
    // Sıra: önce **süren** mesele ilerletilir, sonra yenisi açılabilir.
    // Tersi olsa o yıl açılan mesele aynı yıl içinde sonuçlanabilirdi;
    // karar ile sonuç aynı yıla düşmemeli (§1).
    final ({GameState state, List<String> logTexts}) okulYili =
        ChildSchoolIssue.advanceYear(afterDeaths, newAge, _rng);
    afterDeaths = okulYili.state;
    for (final String satir in okulYili.logTexts) {
      afterDeaths = _logLine(afterDeaths, newAge, satir);
    }

    final ({GameState state, PendingNotice? notice}) yeniOkulSorunu =
        ChildSchoolIssue.maybeOpen(afterDeaths, _rng);
    afterDeaths = yeniOkulSorunu.state;
    if (yeniOkulSorunu.notice != null) {
      afterDeaths =
          Notices.enqueue(afterDeaths, <PendingNotice>[yeniOkulSorunu.notice!]);
    }

    // §7: aile hayatı yalnızca sorun değildir — çocuğun başarısı da
    // oyuncuya ulaşır. Açık bir okul meselesi varken çıkmaz ki
    // "dersleri kötü" ile "derece yaptı" aynı yıl yazılmasın.
    final ({GameState state, PendingNotice? notice, String? logText}) basari =
        ChildSchoolIssue.maybeAchievement(afterDeaths, newAge, _rng);
    afterDeaths = basari.state;
    if (basari.logText != null) {
      afterDeaths = _logLine(afterDeaths, newAge, basari.logText!);
    }
    if (basari.notice != null) {
      afterDeaths = Notices.enqueue(afterDeaths, <PendingNotice>[basari.notice!]);
    }

    // --- Paket AP §8-§13: yetişkin çocuğun kendi ayakları ------------
    //
    // Önce kendiliğinden olan kısım (iş bulup evden çıkma, şehir
    // değiştirme), sonra yeni para isteği. Tersi olsa aynı yıl hem
    // "para istiyor" hem "başka şehre taşındı" çıkabilirdi.
    final ({GameState state, List<String> logTexts}) yetiskinYili =
        AdultChildSupport.advanceYear(afterDeaths, newAge, _rng);
    afterDeaths = yetiskinYili.state;
    for (final String satir in yetiskinYili.logTexts) {
      afterDeaths = _logLine(afterDeaths, newAge, satir);
    }

    final ({GameState state, PendingNotice? notice}) paraIstegi =
        AdultChildSupport.maybeRequest(afterDeaths, newAge, _rng);
    afterDeaths = paraIstegi.state;
    if (paraIstegi.notice != null) {
      afterDeaths =
          Notices.enqueue(afterDeaths, <PendingNotice>[paraIstegi.notice!]);
    }

    // --- Paket AP §28-§32: kardeşle para ve yaşlı bakımı -------------
    //
    // İkisi de §3'ün tek kapısından geçiyor: aynı yıl hem kardeş para
    // isteyip hem bakım meselesi açılmıyor.
    final ({GameState state, PendingNotice? notice}) kardesParasi =
        FamilyDisputes.maybeSiblingAsk(afterDeaths, newAge, _rng);
    afterDeaths = kardesParasi.state;
    if (kardesParasi.notice != null) {
      afterDeaths =
          Notices.enqueue(afterDeaths, <PendingNotice>[kardesParasi.notice!]);
    }

    final ({GameState state, PendingNotice? notice}) bakimMeselesi =
        FamilyDisputes.maybeCareDispute(afterDeaths, newAge, _rng);
    afterDeaths = bakimMeselesi.state;
    if (bakimMeselesi.notice != null) {
      afterDeaths =
          Notices.enqueue(afterDeaths, <PendingNotice>[bakimMeselesi.notice!]);
    }

    // §33: yıllarca biriken uzaklaşma küslüğe dönüşebilir. Sebepsiz
    // küslük yok: yalnızca reddedilmiş ya da karışılmamış bir meselesi
    // olan ve yakınlığı dibe inmiş yakın. Yılda en fazla bir kişi.
    afterDeaths =
        FamilyDisputes.maybeFamilyFallout(afterDeaths, newAge, _rng).state;

    // --- Paket AP §26-§27: kayın aile ve gelin/damat -----------------
    //
    // Olay havuzu bilinçli olarak dengeli: "kayınvalide = sürekli
    // sorun" stereotipi yok (§26). Çatışma ise oyuncuya bir karar
    // bırakır ve üç cevabın hepsi bir şeye mal olur (§27).
    // Kayın aile olayı **günlüğe** yazılıyor, pencere açmıyor (§72):
    // oyuncuya bir şey sormuyor, haber veriyor.
    afterDeaths = InLawRelations.maybeEvent(afterDeaths, newAge, _rng).state;

    final ({GameState state, PendingNotice? notice}) kayinCatismasi =
        InLawRelations.maybeConflict(afterDeaths, newAge, _rng);
    afterDeaths = kayinCatismasi.state;
    if (kayinCatismasi.notice != null) {
      afterDeaths = Notices.enqueue(
        afterDeaths,
        <PendingNotice>[kayinCatismasi.notice!],
      );
    }

    // --- Paket AP §42-§46: ailenin oyuncuya dokunan tarafı -----------
    //
    // Gurur ve endişe **o yıl gerçekten olan** bir şeyden doğar ve
    // soğuma süresine tabidir: dört yıl süren bir mesele dört kez
    // mutluluk düşürmez. Yakınlık ve mesafe etkinin büyüklüğünü
    // değiştirir, varlığını değil.
    //
    // Okul bloğundan **sonra** çalışıyor: o yılın başarısı ve o yıl
    // konuşulan mesele artık kayda geçmiş durumda.
    final ({GameState state, List<String> logTexts}) aileDuygusu =
        FamilyMood.advanceYear(afterDeaths, newAge);
    afterDeaths = aileDuygusu.state;
    for (final String satir in aileDuygusu.logTexts) {
      afterDeaths = _logLine(afterDeaths, newAge, satir);
    }

    // Anne ve baba ayrılabilir (Paket AO §1-§6). Boşanma **önce** işlenir:
    // ayrılan ebeveynin yeniden evlenmesi ancak boşanma durumu yazıldıktan
    // sonra mümkün olur, yani aynı yıl hem ayrılıp hem evlenmez.
    afterDeaths = ParentDivorce.maybeDivorce(afterDeaths, newAge, _rng);

    // Eşi vefat eden **ya da boşanan** ebeveyn yeniden evlenebilir:
    // oyuncuya üvey anne ya da üvey baba gelir (D-141, Paket AO §7-§8).
    // Kimse silinmez; vefat eden ya da ayrılan ebeveyn kayıtta kalır.
    afterDeaths = StepParents.maybeRemarry(afterDeaths, newAge, _rng);

    // Üvey ebeveynden yarım kardeş doğabilir (Paket AO §12, §13).
    // "Bebeği oldu" yalnızca metin değil: yaşı 0 olan gerçek bir kayıt
    // açılır ve ortak biyolojik ebeveyn yazılır.
    afterDeaths = StepSiblings.maybeHalfSibling(afterDeaths, newAge, _rng);

    // Kronik durumlar: takip edilmeyen rahatsızlık her yıl sağlıktan
    // düşürür; ileri yaşta yenisi ortaya çıkabilir (D-153). Kriz gibi
    // ekranı kesmez, çünkü oyuncunun vereceği bir karar yoktur.
    // Taşınan rahatsızlığın yıllık yıpratması bu çağrının içinde;
    // sağlığı acil banda indirirse sebep kesin bilinir (Paket AQ).
    afterDeaths = ChronicEngine.advanceYear(
      state: afterDeaths,
      newAge: newAge,
      rng: _rng,
    );

    // Piyasa ve portföy (D-162): piyasa **yaş başına bir kez** ilerler,
    // pozisyonlar yeniden değerlenir, vadesi dolan hesap cüzdana geçer.
    // Portföyü olmayan oyuncuda da piyasa ilerler — fiyat endeksi kimsenin
    // alım yapmasını beklemez.
    afterDeaths = InvestmentEngine.advanceYear(
      state: afterDeaths,
      newAge: newAge,
    );

    // Hane bütçesi (D-160): çalışan eş yılda bir kez haneye katkı koyar.
    afterDeaths = HouseholdBudget.applySpouseContribution(
      state: afterDeaths,
      newAge: newAge,
    );

    // Nafaka (D-160): süren kayıt bir yıl işler, süresi dolan kapanır.
    afterDeaths = HouseholdBudget.advanceYear(
      state: afterDeaths,
      newAge: newAge,
    );

    // Kiralama (D-163): tahsilat, yıpranma, hasar, boş ev gideri, kiracının
    // çıkması ve evin değer değişimi yılda **bir kez**. Normal tahsilat
    // bildirim açmaz; yalnızca anlatılacak bir şey varsa pencere gelir.
    // Oyuncu kiradaysa ev sahibi kaydı kurulur/korunur (D-163): aynı evde
    // yıllarca oturan oyuncunun ev sahibi her olayda değişmesin.
    afterDeaths = RentalEngine.syncLandlord(
      state: afterDeaths,
      newAge: newAge,
      rng: _rng,
    );

    final ({GameState state, RentalYear year}) kiralama =
        RentalEngine.advanceYear(
      state: afterDeaths,
      newAge: newAge,
      rng: _rng,
    );
    afterDeaths = kiralama.state;
    if (kiralama.year.notable) {
      afterDeaths = Notices.enqueue(afterDeaths, <PendingNotice>[
        PendingNotice(
          id: 'konut-$newAge',
          kind: NoticeKind.konut,
          age: newAge,
          title: 'Evlerinden haber',
          text: kiralama.year.notes.join(' '),
        ),
      ]);
    }

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

    // Sağlık bu yıl acil banda indiyse zorunlu çözüm **aynı yıl** açılır
    // (Paket AQ). Sebep yıl içinde sağlığı düşüren sistemden okunur:
    // taşınan rahatsızlık varsa o, ileri yaşta beden çöküşü, yoksa
    // sebep yazılmaz — uydurulmaz.
    //
    // `_maybeHealthCrisis`ten **sonra** çağrılıyor: o yıl olağan bir
    // kriz açıldıysa kritik çözüm onun üstüne binmez, olağan kriz
    // kapanınca (`HealthCrisisEngine.respond`) devralır.
    afterDeaths = CriticalHealth.enforce(
      state: afterDeaths,
      age: newAge,
      cause: CriticalHealth.causeFromState(afterDeaths),
    );

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

    // Araç muayenesi (D-157): iki yılda bir gelir, kondisyonu düşük araç
    // geçemez, muayenesi geciken araç yıllık bir idari bedel çıkarır.
    // Aracı olmayan oyuncuda etkisi yoktur.
    afterDeaths = VehicleInspection.advanceYear(
      state: afterDeaths,
      newAge: newAge,
    );

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

    // Yılın ilerlemesiyle ulaşılan hedefler (emeklilik, torun, ustalık…)
    // yeni yaşla kaydedilir. Zaten kayıtlı hedefe tekrar bakılmaz.
    afterDeaths = LifeGoals.advanceYear(state: afterDeaths, newAge: newAge);

    // Lise alanının yıllık küçük kazancı; alan seçimi kozmetik değildir.
    GameState withTrack = _applyTrackBonus(afterDeaths);

    // Biten yılın özeti (D-096): oyuncu hayat günlüğünü taramadan yılın
    // nasıl geçtiğini görebilsin. Özet yılın **başındaki** fotoğrafla
    // bugünün farkından üretilir; yeni yıl için yeni fotoğraf alınır.
    withTrack = withTrack.copyWith(
      lastYearSummary: yilOzeti,
      yearMark: YearMark.of(withTrack),
    );

    // Yılın **son** kritik sağlık denetimi (Paket AQ).
    //
    // Yukarıdaki denetim sağlık sistemlerinin (yaşlanma, hastalık,
    // kronik) hemen ardında duruyor ve sebebi oradan okuyor. Ama yılın
    // geri kalanında da sağlığı düşüren yollar var: işletme zararı
    // (D-132), adli süreç (D-128) ve okurken çalışmanın bedeli (D-131).
    // Ölçüm bir kaçak gösterdi: 500 hayatta tohum 56, yaş 73 —
    // sağlık 0, kritik durum yok, hayat devam ediyor. Bu yüzden yıl
    // kapanmadan **son** bir denetim daha var; çağrı etkisizse durumu
    // aynen döndürüyor.
    //
    // Sebep bu noktada kayıttan okunuyor; hangi sistemin indirdiği
    // kesin bilinmediği için **uydurulmuyor**.
    withTrack = CriticalHealth.enforce(
      state: withTrack,
      age: newAge,
      cause: CriticalHealth.causeFromState(withTrack),
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
      // Paket AO: büyüyüp evden çıkanlar yalnızca oyuncunun kendi
      // çocukları değil. Üvey ve yarım kardeşler ile eşin önceki
      // çocuğu da büyüyünce kendi hayatını kurar.
      //
      // DİKKAT — bu yalnızca anlatı değil, **ekonomik** bir kural.
      // `LivingCosts.livesWithFamily` "hanede yetişkin bir akraba var
      // mı?" diye bakıyor. Üvey kardeş/üvey çocuk hanede kalıp
      // yaşlanınca oyuncu ömrü boyunca "ailesinin yanında yaşıyor"
      // sayılıyor ve kira ödemiyordu; `paket_ae_calibration` bunu
      // dominans kaymasıyla yakaladı.
      const Set<RelationType> evdenCikanlar = <RelationType>{
        RelationType.cocuk,
        RelationType.uveyKardes,
        RelationType.yariKardes,
        RelationType.uveyCocuk,
      };
      if (!evdenCikanlar.contains(p.relation)) continue;
      if (!p.isAlive || !p.inPlayerHousehold) continue;
      if (p.age < Parenthood.prototypeOnlyLeaveHomeAge) continue;
      // Paket AP §12: oyuncunun onayıyla eve dönen çocuk bu kuralla
      // hemen geri çıkarılmaz. Yoksa "gelsin" demek bir yıl sonra
      // kendiliğinden geri alınıyordu ve hane kararı dekoratif
      // kalıyordu. Pencere dolunca normal kural yeniden işler.
      if (AdultChildSupport.recentlyReturned(state, p)) continue;

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
    // Paket AP §35: itiraz edilecek tutar **gerçekten** o yıl eline
    // geçen paradan türetiliyor; uydurma bir rakam değil.
    int buYilGelenMiras = 0;
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
      buYilGelenMiras += pay.money;
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

    // Paket AP §35-§36: miras kapandıktan sonra kardeş itiraz edebilir.
    // Mesele burada açılıyor çünkü tutar yalnızca burada biliniyor.
    // İtiraz **para üretmiyor**: kabul edilirse para cüzdandan kardeşin
    // kaydına taşınıyor.
    final ({GameState state, PendingNotice? notice}) itiraz =
        FamilyDisputes.maybeEstateDispute(
      next,
      newAge,
      _rng,
      inheritedThisYear: buYilGelenMiras,
    );
    next = itiraz.state;
    if (itiraz.notice != null) {
      next = Notices.enqueue(next, <PendingNotice>[itiraz.notice!]);
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
    // Bedenin toparlanması (D-116) **her yıl** işler, hastalanılan yılda
    // da.
    //
    // **Paket AQ düzeltmesi.** Toparlanma yalnızca hastalanılmayan
    // yıllarda uygulanıyordu; yani çukuru açan yıl onu hiç kapatmıyordu.
    // Bu D-116'nın kendi gerekçesiyle çelişiyor ("toparlanma hastalığın
    // açtığı çukuru kapatır"): mart ayında gribe yakalanan insan aralık
    // ayında iyileşmiş olur. Sonuç tek yönlü bir dişliydi — beklenen
    // yıllık kayıp (≈0,50 × 17 ≈ 8,6) toparlanmanın yıllık payından
    // büyük olduğu için sağlık 40'ın altına bir kez inince geri
    // dönmüyordu. Ölçüldü: 300 hayatın 265'inde sağlık 0'a indi,
    // 70-79 yaşta ortalama sağlık 17,1.
    //
    // Sıra önemli: hastalığın bedeli **önce** uygulanır, toparlanma
    // kalan açığa göre hesaplanır. Böylece ağır hastalık yine ağır
    // gelir, ama bir ömür boyu kapanmayan bir yara açmaz.
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
    final int tavan = StatAging.prototypeOnlyHealthCeilingFor(newAge);
    final int pay = SickLeaves.recoveryFor(
      age: newAge,
      health: next.player.stats.health,
      ceiling: tavan,
    );
    if (pay > 0) {
      next = next.copyWith(
        player: next.player.copyWith(
          stats: next.player.stats.gain(health: pay),
        ),
      );
    }
    if (!hastalik.happened) {
      // Hastalanılmayan yılda anlatılacak bir şey yok; yalnızca
      // toparlanma uygulanmış olur.
      return (state: next, logText: girdi.logText);
    }
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
    // Hastalık sağlığı acil banda indirdiyse zorunlu çözüm **burada**
    // açılır: sebep kesin biliniyor, uydurmaya gerek yok (Paket AQ).
    next = CriticalHealth.enforce(
      state: next,
      age: newAge,
      cause: CriticalHealthCause.hastalik,
    );
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
  ///
  /// **Bant geçişine** bakar (Paket AQ), değere değil: aynı bant içinde
  /// 22'den 20'ye düşmek yeni bir uyarı doğurmaz. İki ayrı bant iki ayrı
  /// bayrakla tutulur, çünkü tek bayrakla "kritik derecede düşük"ten
  /// "hayati tehlike"ye geçiş hiç haber verilmiyordu. Bant düzelince
  /// bayrak sıfırlanır ve bir dahaki inişte yeniden konuşur.
  GameState _maybeHealthWarning(GameState state, int newAge) {
    final HealthBand bant = CriticalHealth.bandFor(state);

    // Acil bant kendi zorunlu çözüm penceresini açıyor; üstüne ayrıca
    // uyarı konmaz (bildirim yığılmasın).
    if (bant == HealthBand.acil) return state;

    if (bant == HealthBand.normal) {
      if (!state.healthWarned && !state.healthDangerWarned) return state;
      return state.copyWith(
        healthWarned: false,
        healthDangerWarned: false,
      );
    }

    // 1-10: hayati tehlike. Bu bandın ilk kez görülmesi bir pencereyi
    // hak eder; oyuncu "Sağlık: 5" yazısını açıklamasız görmesin.
    if (bant == HealthBand.hayatiTehlike && !state.healthDangerWarned) {
      return Notices.enqueue(
        state.copyWith(
          healthWarned: true,
          healthDangerWarned: true,
          log: List<LifeLogEntry>.unmodifiable(<LifeLogEntry>[
            ...state.log,
            LifeLogEntry(
              age: newAge,
              text: 'Sağlığın hayati tehlike seviyesine indi.',
              category: LogCategory.kisisel,
            ),
          ]),
        ),
        <PendingNotice>[
          PendingNotice(
            id: 'saglik-tehlike-$newAge',
            kind: NoticeKind.saglik,
            age: newAge,
            title: 'Sağlığın hayati tehlike seviyesinde',
            text: 'Bu hâlde ağır bir işe kalkışmak ya da uzun yola '
                'çıkmak mümkün değil. Dinlenmen ve sağlığına bakman '
                'gerekiyor.',
          ),
        ],
      );
    }

    // 11-25: kritik derecede düşük. Günlüğe yazılır, pencere açılmaz;
    // her düşük sağlık yılı için pencere açmak bildirim spamı olurdu.
    if (bant == HealthBand.kritikDusuk && !state.healthWarned) {
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
    return state;
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
      // Hayat tamamlandı: bekleyen kritik sağlık durumu da kapanır.
      // Aksi hâlde vefat eden oyuncuya kriz penceresi açılır ve **ikinci
      // bir ölüm** üretilebilirdi (Paket AQ). Mortality bu yıl zaten
      // sonucu verdi; kişi bir kez ölür.
      pendingCrisis: null,
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

    // İkiz (D-151): aynı doğumun ikinci bebeği. Gebelik kaydı tektir;
    // ikinci bebek burada, **aynı diğer ebeveynle** dünyaya gelir.
    // İkinci doğum engellenirse (ör. en fazla çocuk sayısı dolduysa)
    // doğum tek bebekle kapanır; sessiz bir hata oluşmaz.
    final bool ikizDenendi =
        _rng.nextDouble() < Parenthood.prototypeOnlyTwinChance;
    FamilyResult? ikiz;
    if (ikizDenendi) {
      final FamilyResult deneme = const Parenthood().haveChild(
        dogum.state,
        _rng,
        coParentId: bekleyen.partnerId,
        twin: true,
      );
      if (deneme.outcome.applied) ikiz = deneme;
    }

    final GameState dogumSonrasi = ikiz?.state ?? dogum.state;
    final Person? ikizBebek =
        ikiz == null ? null : dogumSonrasi.children.last;

    GameState sonuc = dogumSonrasi.copyWith(
      notices: List<PendingNotice>.unmodifiable(<PendingNotice>[
        ...dogumSonrasi.notices,
        if (ikizBebek == null)
          Notices.birth(
            playerAge: newAge,
            childId: bebek.id,
            childName: bebek.firstName,
            isGirl: bebek.gender == Gender.kadin,
            otherParentName: diger.firstName,
          )
        else
          Notices.twinBirth(
            playerAge: newAge,
            firstChildId: bebek.id,
            firstName: bebek.firstName,
            firstIsGirl: bebek.gender == Gender.kadin,
            secondName: ikizBebek.firstName,
            secondIsGirl: ikizBebek.gender == Gender.kadin,
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

    // `isMarried`, `marriage != null` değil (Q-167/3): boşanmış oyuncunun
    // ebeveynleri onu hâlâ evli sayıp "destekleyici" tepki veriyordu.
    final bool evli = state.isMarried;
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
    required int happiness,
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
      happiness: happiness,
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

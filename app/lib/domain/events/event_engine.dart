import '../life/critical_health.dart';
import 'dart:math';

import '../economy/net_worth.dart';
import '../../data/company_catalog.dart';
import '../law/legal_engine.dart';
import '../features/feature_catalog.dart';
import '../features/feature_events.dart';
import '../models/criminal_record.dart';

import 'package:flutter/foundation.dart';

import '../../data/event_pool.dart';
import '../../data/insurance_catalog.dart';
import '../../data/item_catalog.dart';
import '../../text/turkish_text.dart';
import '../generation/random_util.dart';
import '../interaction/friend_circles.dart';
import '../interaction/friendship.dart';
import '../interaction/romance.dart';
import '../economy/insurance.dart';
import '../economy/investment_engine.dart';
import '../models/game_event.dart';
import '../models/market_state.dart';
import '../activities/travel.dart';
import '../economy/housing.dart';
import '../economy/living_costs.dart';
import '../models/game_state.dart';
import '../models/school_club_progress.dart';
import '../models/hobby_progress.dart';
import '../hobby/hobby_tracker.dart';
import '../../data/hobby_catalog.dart';
import '../../data/pet_catalog.dart';
import '../models/trip.dart';
import '../models/life_log.dart';
import '../economy/financial_strain.dart';
import '../models/owned_item.dart';
import '../models/person.dart';
import '../models/player_character.dart';
import '../models/stats.dart';

/// Olay motoru (D-009, D-021, D-022, D-023, D-024).
///
/// Kurallar:
/// - Yaş alındığında **ilk olarak yalnızca tek** uygun olay çıkar; aynı anda
///   ikinci bir olay penceresi açılmaz.
/// - Bir olayın çıkabilmesi için yaş **ve** diğer koşullar sağlanmalıdır:
///   olayın kişisi yaşıyor olmalı, gereken hikâye izi bulunmalı, sahip
///   olunmayan varlık için olay üretilmemelidir.
/// - Ek olaylar **gerçek dünya dakikasıyla değil**, oyuncunun oyun içindeki
///   anlamlı ilerlemesiyle gelir. Bu prototipte tempo bilerek dar tutulmuştur
///   (aşağıdaki `prototypeOnly` değerler); kesin tempo algoritması henüz
///   kararlaştırılmadı.
class EventEngine {
  const EventEngine({this.pool = kEventPool});

  final List<GameEvent> pool;

  /// Bir yaş içinde açılış olayından sonra çıkabilecek **en fazla** ek olay.
  static const int prototypeOnlyMaxExtraEventsPerAge = 1;

  /// Ek olayın açılması için gereken anlamlı ilerleme adımı sayısı.
  static const int prototypeOnlyProgressPerExtraEvent = 3;

  /// Bir yakının sitem edebilmesi için geçmesi gereken **oyun içi** yaş farkı.
  static const int prototypeOnlyNeglectAgeGap = 3;

  // -----------------------------------------------------------------
  // Tekrar sönümü (Paket 20)
  // -----------------------------------------------------------------
  //
  // Ölçüm: 12 tam hayatta en sık olay 39 kez çıkıyordu (hayat başına ~3)
  // ve 151 olayın yalnızca 94'ü hiç görülüyordu. Havuz zengindi ama aynı
  // birkaç olay öne çıkıyordu. Çözüm yeni içerik değil, aynı olayın
  // ikinci kez çıkma şansını düşürmek.

  /// Her tekrarda ağırlığın çarpıldığı oran (`prototypeOnly`).
  ///
  /// Bir kez görülen olay %35, iki kez görülen %12 ağırlıkta kalır.
  static const double prototypeOnlyRepeatWeightDecay = 0.30;

  /// Ağırlığın düşebileceği en küçük oran: olay tamamen kaybolmaz.
  static const double prototypeOnlyMinWeightRatio = 0.04;

  /// Her tekrarın tekrar aralığına eklediği yıl (`prototypeOnly`).
  static const int prototypeOnlyGapGrowthPerRepeat = 6;

  /// Tekrar aralığının çıkabileceği en büyük değer.
  static const int prototypeOnlyMaxRepeatGap = 35;

  // -----------------------------------------------------------------
  // Dönüm noktası önceliği (Paket 21)
  // -----------------------------------------------------------------
  //
  // Ölçüm: tek bir yıla bağlı olaylar bütün havuzla yarıştıkları için
  // çoğu hayatta hiç çıkmıyordu; sınav yılı olayları oyuncuların ancak
  // **%38'inde** görülüyordu.
  //
  // İlk denenen çözüm "öncelikli olay varsa yalnızca o yarışsın"dı ama
  // geniş pencereli bir dönüm noktası (ör. 18-32 yaş arası ilk ev) o
  // yılları tamamen boğuyordu. Bunun yerine öncelik, ağırlığı **çok
  // güçlü biçimde artırır**: dönüm noktası neredeyse kesin çıkar ama
  // havuzun kalanı yine mümkün kalır.

  /// Her öncelik kademesinin ağırlığı çarptığı kat (`prototypeOnly`).
  ///
  /// İki kademe kullanılır: **1** geniş pencereli dönüm noktaları için
  /// ("güçlü biçimde tercih edilir"), **2** tek bir yıla kilitli olaylar
  /// için ("o yıl neredeyse kesin çıkar").
  static const double prototypeOnlyPriorityBoost = 120;

  // -----------------------------------------------------------------
  // Zincir devamı önceliği (Paket AS/2, Q-190/Q-191)
  // -----------------------------------------------------------------
  //
  // Ölçüm (AR/3, 21.307 oyun yılı): yıllık aday havuzunda ortanca **80**
  // olay ve **268** toplam etkin ağırlık var. Yani ağırlık 4'lük bir
  // olayın bir yıldaki payı %1,5. Öğretmen zincirinin dört halkası
  // sırayla ~%4,4 → %7,3 → %28,2 ihtimalle çıkıyor ve bunlar her halkada
  // doğru kolu seçme ihtimaliyle **çarpılıyor**: 3. halkaya ulaşma
  // ihtimali kabaca **on binde bir**. Beş olay yazılmıştı; kimse sonunu
  // görmüyordu.
  //
  // Oyuncu bir zincirin ilk halkasını görüp bir kol seçtiğinde ona bir
  // **söz** verilmiş oluyor. Devamını kuraya bırakmak o sözü tutmamaktır.
  // Bu yüzden `requiredFlags`'ı karşılanmış olaylar — yani oyuncunun
  // zaten açtığı devam halkaları — orta güçlü bir katsayı alır.

  /// Oyuncunun **zaten açtığı** devam halkasının ağırlık katsayısı
  /// (`prototypeOnly`).
  ///
  /// Dönüm noktası katsayısının (`prototypeOnlyPriorityBoost` = 120) çok
  /// altında: havuzu boğmaz ama zinciri de kuraya bırakmaz. Ölçülen
  /// tabanla ×8, beş yıllık pencerede %7,3'ü ~%45'e, yirmi iki yıllık
  /// pencerede %28'i ~%90'a çıkarır.
  ///
  /// Katsayı yalnızca **iz arayan** olaya uygulanır; ilk halka normal
  /// ağırlıkta yarışır, yani zincire girme ihtimali değişmez. Tekrar
  /// sönümü (`prototypeOnlyRepeatWeightDecay`) ve `forbiddenFlags` üstüne
  /// çalışmaya devam eder: halka bir kez çıkınca havuzdan düşer.
  static const double prototypeOnlyChainContinuationBoost = 8;

  // -----------------------------------------------------------------
  // Sürdürülen uğraş önceliği (Paket BX)
  // -----------------------------------------------------------------
  //
  // Ölçüm (150 spor odaklı hayat, zincir hunisi): okul futbol takımının
  // on iki olayından **sekizi** 1.000 hayatlık denetimde hiç
  // görülmemişti. Huni şunu gösterdi: üç olay (`antrenor_tartismasi`,
  // `turnuva`, `ders_catismasi`) hayatların 31/150'sinde **uygun hale
  // geliyor** ama 150 hayatta toplam **4 kez** çıkıyor. Yani kapı değil,
  // çekiliş kaybediyor: yıllık havuzda ortanca 80 aday ve ~268 etkin
  // ağırlık varken (AR/3 ölçümü) ağırlığı 6-7 olan bir olayın payı
  // %2,5; kulüp üyeliğinin penceresi ise yalnızca 2-4 yıl.
  //
  // Paket AS/2 aynı sorunu **zincirler** için çözmüştü: oyuncunun açtığı
  // devam halkası ×8 alıyor. Kulüp ve hobi olayları da aynı sözün
  // kapsamındadır — oyuncu takıma girmeyi **seçti** ve o seçimin ömrü
  // kısa. Fark şu: zincir koşulu bir bayrak, buradaki koşul sürmekte
  // olan bir **durum**.

  /// prototypeOnly: oyuncunun **şu an sürdürdüğü** kısa pencereli
  /// uğraşın (okul kulübü, hobi) olaylarına verilen katsayı.
  ///
  /// Zincir katsayısının (8) altında, dönüm noktası katsayısının (120)
  /// çok altında. İki katsayı **çarpılmaz**: en güçlü gerekçe kazanır,
  /// yoksa bayrağı da kulübü de olan olay ×48 ile havuzu boğardı.
  static const double prototypeOnlyActivePursuitBoost = 6;

  /// Olay, oyuncunun şu an sürdürdüğü bir uğraşa mı ait?
  ///
  /// Anahtar kapalıysa katsayı 1'dir: Paket BX öncesi davranış birebir
  /// geri gelir (`FeatureId.ugrasOnceligi`).
  static double _activePursuitBoost(GameState state, GameEvent event) {
    if (!state.featureOn(FeatureId.ugrasOnceligi)) return 1;
    final EventRequirement req = event.requirement;
    final String? kulupId = req.requiresActiveClubId;
    if (kulupId != null && state.schoolClubs.activeFor(kulupId) != null) {
      return prototypeOnlyActivePursuitBoost;
    }
    final String? hobiId = req.requiredHobbyId;
    if (hobiId != null) {
      final HobbyKind? hobi = hobbyById(hobiId);
      if (hobi != null && HobbyTracker.progressOf(state, hobi) != null) {
        return prototypeOnlyActivePursuitBoost;
      }
    }
    return 1;
  }

  /// Olayın **bu hayatta kaç kez çıktığına** göre azalan ağırlığı.
  static double prototypeOnlyEffectiveWeight(GameState state, GameEvent event) {
    // Dönüm noktaları bütün havuzun önüne geçer (Paket 21).
    final double oncelik = event.priority == 0
        ? 1
        : pow(prototypeOnlyPriorityBoost, event.priority).toDouble();

    // Oyuncunun açtığı devam halkası öne geçer (Paket AS/2).
    //
    // Koşul yalnızca "iz arıyor" değil, "istediği izlerin **hepsi**
    // konmuş": motor zaten bunu süzüyor ama katsayı aday dışı bir
    // çağrıda da doğru davransın diye burada bir daha bakılıyor.
    final double zincirKatsayisi =
        event.requirement.requiredFlags.isNotEmpty &&
                state.storyFlags.containsAll(event.requirement.requiredFlags)
            ? prototypeOnlyChainContinuationBoost
            : 1;

    // Sürdürülen uğraş da öne geçer (Paket BX). İki gerekçe çarpılmaz;
    // en güçlüsü kazanır.
    final double zincir =
        max(zincirKatsayisi, _activePursuitBoost(state, event));

    final int gorulme = state.eventSeenCount(event.id);
    if (gorulme == 0) return event.weight * oncelik * zincir;
    final double oran =
        pow(prototypeOnlyRepeatWeightDecay, gorulme).toDouble();
    return event.weight *
        oncelik *
        zincir *
        (oran < prototypeOnlyMinWeightRatio
            ? prototypeOnlyMinWeightRatio
            : oran);
  }

  /// Olayın **bu hayatta kaç kez çıktığına** göre büyüyen tekrar aralığı.
  static int prototypeOnlyEffectiveGap(GameState state, GameEvent event) {
    final int gorulme = state.eventSeenCount(event.id);
    final int aralik =
        event.minAgeGap + gorulme * prototypeOnlyGapGrowthPerRepeat;
    return aralik > prototypeOnlyMaxRepeatGap
        ? prototypeOnlyMaxRepeatGap
        : aralik;
  }

  /// Yeni yaşın tek açılış olayı (D-021). Uygun olay yoksa `null`.
  ActiveEvent? openingEvent(GameState state, Random rng) =>
      _pick(state, rng);

  /// Oyun içi ilerlemeye bağlı ek olay (D-023, D-024).
  ///
  /// Yalnızca yeterli ilerleme biriktiyse, bu yaşın ek olay sınırı dolmadıysa
  /// ve ekranda başka olay yokken çıkar.
  ActiveEvent? progressEvent(GameState state, Random rng) {
    if (state.hasPendingEvent) return null;
    if (state.extraEventsThisAge >= prototypeOnlyMaxExtraEventsPerAge) return null;
    if (state.progressSinceLastEvent < prototypeOnlyProgressPerExtraEvent) {
      return null;
    }
    return _pick(state, rng);
  }

  /// Uygun olaylar arasından ağırlıklı seçim yapar ve kişisini çözer.
  ///
  /// **Zar sözleşmesi (Paket BO).** Bu tarama, havuzda kaç olay olduğundan
  /// bağımsız olarak zar tüketir. Eskiden tersiydi: kişi çözümü koşul
  /// denetiminden **önce** yapıldığı için, o yaşta hiç çıkamayacak bir
  /// olay bile `rng`'yi tüketiyordu. Sonuç: havuza tek bir olay eklemek
  /// bütün tohumlu ölçümleri kaydırıyordu — bir oturumda beş bekçi testi
  /// bu yüzden kırıldı. Artık sıra şu:
  ///
  /// 1. Ucuz kapılar (modül, görülme, tekrar aralığı) — zar tüketmez.
  /// 2. Kişiden bağımsız koşullar (`_matches`, `requirePerson: false`) —
  ///    zar tüketmez.
  /// 3. Kişi **adayları** (`_eligiblePeople`) — zar tüketmez.
  /// 4. Ağırlıklı çekiliş — **bir** zar.
  /// 5. Yalnızca kazanan olayın kişisi (`_pickPerson`) — en çok bir zar.
  ///
  /// Yani uygun olmayan olay eklemek akışa hiç dokunmaz; uygun olan
  /// eklemek yalnızca çekilişi değiştirir.
  ActiveEvent? _pick(GameState state, Random rng) {
    final List<_Candidate> candidates = <_Candidate>[];
    for (final GameEvent event in pool) {
      // Modül kapısı (Paket BM): kapalı bir içerik modülünün olayı hiç
      // aday olmaz ve oyunun zarına dokunmaz.
      if (!FeatureEvents.allowed(state, event.id)) continue;
      if (!event.repeatable && state.seenEventIds.contains(event.id)) continue;
      if (!_repeatGapPassed(state, event)) continue;
      // Koşullar kişiden **önce** denetlenir: 40 yaşın olayı için 7
      // yaşında kişi aranmaz.
      if (!_matches(state, event, null, requirePerson: false)) continue;
      // Kişi adayları zar tüketmeden çıkarılır; **hangisi** olduğu
      // çekilişi kazanan olay için sonradan seçilir.
      final List<Person> adaylar = _eligiblePeople(state, event);
      if (_needsPerson(event.requirement) && adaylar.isEmpty) continue;
      candidates.add(_Candidate(event, adaylar));
    }
    if (candidates.isEmpty) return null;

    final _Candidate chosen = rng.pickWeighted(
      candidates,
      candidates
          .map((_Candidate c) =>
              prototypeOnlyEffectiveWeight(state, c.event))
          .toList(),
    );
    return _toActive(state, chosen.event, _pickPerson(chosen.people, rng));
  }

  /// Yalnızca ölçüm içindir: olayın kişisiz koşullarını denetler.
  @visibleForTesting
  bool debugMatches(GameState state, GameEvent event) {
    if (_needsPerson(event.requirement)) return false;
    if (!event.repeatable && state.seenEventIds.contains(event.id)) {
      return false;
    }
    if (!_repeatGapPassed(state, event)) return false;
    return _matches(state, event, null);
  }

  /// Yalnızca testler içindir: şu an **çıkabilecek** bütün olayların
  /// kimlikleri.
  ///
  /// Testler bunu "hangi olaylar mümkün" sorusu için kullanır. Aynı
  /// soruyu yüzlerce tohumla çekiliş yaparak yanıtlamak yanıltıcıydı:
  /// dönüm noktası ağırlıkları devreye girince (Paket 21) çekilişi hep
  /// aynı olay kazanıyor ve diğerleri "imkânsız" gibi görünüyordu.
  ///
  /// **Paket BO'dan sonra zar gerekmiyor:** kişi seçimi uygunluğu
  /// belirlemiyor, yalnızca aday **varlığı** belirliyor. Bu yüzden sonuç
  /// artık tohumdan bağımsız. `rng` parametresi eski çağrılar bozulmasın
  /// diye duruyor ve yok sayılır. Eskiden tohuma bağlıydı ve bu yanlıştı:
  /// erişilemeyen bir kardeş çekilince, erişilebilir kardeşi olan olay
  /// "imkânsız" görünüyordu.
  @visibleForTesting
  Set<String> debugEligibleIds(GameState state, [Random? rng]) {
    final Set<String> sonuc = <String>{};
    for (final GameEvent event in pool) {
      if (!event.repeatable && state.seenEventIds.contains(event.id)) continue;
      if (!_repeatGapPassed(state, event)) continue;
      if (!_matches(state, event, null, requirePerson: false)) continue;
      if (_needsPerson(event.requirement) &&
          _eligiblePeople(state, event).isEmpty) {
        continue;
      }
      sonuc.add(event.id);
    }
    return sonuc;
  }

  /// Olayın koşullarını denetler. Kişi gerekiyorsa [person] dolu olmalıdır.
  ///
  /// [requirePerson] yalnızca `_pick` ve `debugEligibleIds` içindir: orada
  /// kişi adayları ayrı çıkarıldığı için kişi varlığı burada
  /// denetlenmez (Paket BO). Dışarıdan çağıran her yol varsayılanı
  /// kullanır; yani kişi gerektiren olay kişisiz geçemez.
  bool _matches(GameState state, GameEvent event, Person? person,
      {bool requirePerson = true}) {
    // Modül kapısı (Paket BL): kapalı bir içerik modülünün olayı hiç
    // aday olmaz. Tek yer burasıdır; `_pick`, `canHappen` ve
    // `debugEligibleIds` üçü de buradan geçer.
    if (!FeatureEvents.allowed(state, event.id)) return false;
    final EventRequirement req = event.requirement;
    final int age = state.player.age;

    if (age < req.minAge || age > req.maxAge) return false;
    // Öğrencilik yaştan değil, eğitim durumundan okunur.
    if (req.requiresSchoolStudent && !state.education.isSchoolStudent) {
      return false;
    }
    // Paket BZ: 1-12 **ya da** üniversite. 18-20 yaş olaylarının kapısı
    // budur; `requiresSchoolStudent` üniversiteliyi dışarıda bırakıyor.
    if (req.requiresStudent && !state.education.isStudent) {
      return false;
    }
    final int? grade = state.education.grade;
    if (req.minGrade != null && (grade == null || grade < req.minGrade!)) {
      return false;
    }
    if (req.maxGrade != null && (grade == null || grade > req.maxGrade!)) {
      return false;
    }
    // Kişi gerektiren olay, uygun kişi bulunamadıysa elenir: aksi hâlde
    // metindeki yer tutucular boş kalır ve olmayan kişiyle olay çıkar.
    if (requirePerson && _needsPerson(req) && person == null) return false;
    if (!state.storyFlags.containsAll(req.requiredFlags)) return false;
    if (req.forbiddenFlags.any(state.storyFlags.contains)) return false;
    if (!state.possessions.containsAll(req.requiredPossessions)) return false;
    // "Herhangi bir araba/konut" koşulu: eşyanın çeşidine bakılır, tek bir
    // ürün kimliğine bağlanmaz.
    for (final ItemKind kind in req.requiredPossessionKinds) {
      final bool varMi = state.items.any(
        (OwnedItem i) => itemTypeOrFallback(i.typeId).kind == kind,
      );
      if (!varMi) return false;
    }
    // Ehliyet ve sosyal medya hesabı: olmayan şeyle olay kurulmaz.
    if (!state.licenses.containsAll(req.requiredLicenses)) return false;
    if (req.requiresSocialAccount && state.socialAccounts.isEmpty) {
      return false;
    }
    // Arkadaş grubu (Paket CI): kayıt yürürlükte değilse grup olayı
    // çıkmaz. Modül kapısı zardan önce zaten geçildi (Paket BM/2).
    if (req.requiresFriendCircle && FriendCircles.activeOf(state) == null) {
      return false;
    }
    // Ün gerektiren olaylar: kitle gerçekten oluşmadan çıkmaz.
    if (req.minFame > 0 && (state.player.fame ?? 0) < req.minFame) {
      return false;
    }
    // Kulüp olayları yalnızca o kulüpte **aktif** üyeliği olana çıkar
    // (Paket AU). Kayıttan okunur, uydurulmaz.
    final String? kulupId = req.requiresActiveClubId;
    if (kulupId != null) {
      final SchoolClubProgress? uyelik = state.schoolClubs.activeFor(kulupId);
      if (uyelik == null) return false;
      if (uyelik.yearsActive < req.minClubYears) return false;
      final SquadRole? enAzRol = req.minSquadRole;
      if (enAzRol != null && uyelik.role.index < enAzRol.index) return false;
    }

    // Hobi olayları yalnızca gerçekten o hobiyle uğraşmış oyuncuya
    // çıkar (Paket 39). Geçmiş kayıttan okunur, uydurulmaz.
    final String? hobiId = req.requiredHobbyId;
    if (hobiId != null) {
      final HobbyKind? hobi = hobbyById(hobiId);
      if (hobi == null) return false;
      final HobbyProgress? ilerleme = HobbyTracker.progressOf(state, hobi);
      if (ilerleme == null) return false;
      if (ilerleme.years < req.minHobbyYears) return false;
      if (ilerleme.stage < req.minHobbyStage) return false;
      if (req.requiresActiveHobby && !ilerleme.isActiveAt(state.player.age)) {
        return false;
      }
    }

    // Evcil hayvan olayları yalnızca gerçekten bir hayvanı olan oyuncuya
    // çıkar (Paket 40). Vefat etmiş ya da hanede olmayan hayvan sayılmaz.
    if (req.requiresLivingPet && _eventPet(state, req) == null) return false;

    // Yatırım kapıları (D-162): portföyü olmayana "hisselerin düştü"
    // denmez, portföyü olana "hiç yatırım yapmadın" denmez.
    if (req.requiresPortfolio && state.portfolioValue <= 0) return false;
    if (req.forbidsPortfolio && state.portfolioValue > 0) return false;

    // **Şirket durumu kapıları (Paket AD, §4).** Olay metni şirketi adıyla
    // anlatıyorsa, o şirket gerçekten o durumda olmalı. Yoksa oyuncu
    // sapasağlam bir şirket için konkordato haberi okuyor.
    final CompanyStatus? gerekenDurum = req.requiresCompanyStatus;
    if (gerekenDurum != null) {
      final bool varMi = state.market.activeBasketCompanies
          .any((Company c) => state.market.statusOf(c.id) == gerekenDurum);
      if (!varMi) return false;
    }
    if (req.requiresStrainedCompany) {
      final bool varMi = state.market.activeBasketCompanies
          .any((Company c) => state.market.vitalsOf(c.id).isStrained);
      if (!varMi) return false;
    }
    // **Servet kapısı (Paket AD, §13, §17).** Zenginin hayatı farklı
    // hissettirmeli: bazı olaylar ancak belirli servet seviyesinde çıkar.
    final int? gerekenServet = req.minNetWorth;
    if (gerekenServet != null && NetWorth.of(state) < gerekenServet) {
      return false;
    }

    // **Piyasa hâli kapıları (Paket AD, §6-§7).** Panik olayı sakin bir
    // yılda çıkmasın; FOMO olayı gerçekten ısınmış piyasada çıksın.
    if (req.requiresCrisis &&
        !(state.market.regime == MarketRegime.kriz ||
            state.market.halts.isNotEmpty)) {
      return false;
    }
    final String? sicakTur = req.requiresHotAsset;
    if (sicakTur != null &&
        state.market.heatOf(sicakTur) < req.requiresHotAssetHeat) {
      return false;
    }
    if (req.requiresThrivingCompany) {
      final bool varMi = state.market.activeBasketCompanies
          .any((Company c) => state.market.vitalsOf(c.id).isThriving);
      if (!varMi) return false;
    }

    // Kiralama kapıları (D-163). Kiracısı olmayana "kiracın aradı"
    // denmez; boş evi olmayana "ev boş duruyor" denmez.
    if (req.requiresLetProperty && state.leases.isEmpty) return false;
    if (req.requiresVacantProperty &&
        !state.items.any((OwnedItem i) =>
            i.isProperty &&
            i.id != state.residenceItemId &&
            state.leaseOf(i.id) == null)) {
      return false;
    }

    // Adli kapılar (D-128). Dosyası olmayana "mahkemeyi bekliyorsun",
    // sabıkası olmayana "bir de şu kayıt var" denmez. Cezaevindeyken
    // dışarıdaki hiçbir olay çıkmaz: içerideki hayat ayrıdır.
    if (state.isImprisoned) return false;
    if (req.requiresOpenCase && state.legal.openCase == null) return false;
    if (req.requiresRecord && !state.legal.hasRecord) return false;
    if (req.requiresReleased) {
      final bool hicGirmedi = state.legal.cases.every(
        (CriminalCase c) => c.verdict != Verdict.hapis,
      );
      if (hicGirmedi || state.legal.isImprisoned) return false;
    }

    // Emeklilik olayları yalnızca gerçekten emekli olana çıkar.
    if (req.requiresRetired && !state.career.isRetired) return false;
    // İş hayatı olayları yalnızca gerçekten çalışan oyuncuya çıkar.
    if (req.requiresEmployed && !state.career.isEmployed) return false;
    // Mali durum kapıları (D-092): varlıklı oyuncuya yoksulluk metni,
    // parasız oyuncuya varlık metni çıkmaz. Durum mutlak bir işaretten
    // değil, **gerçek hesaptan** okunur.
    if (req.maxComfort != null || req.minComfort != null) {
      final FinancialComfort durum = FinancialStrain.comfortOf(state);
      if (req.maxComfort != null && durum.index > req.maxComfort!.index) {
        return false;
      }
      if (req.minComfort != null && durum.index < req.minComfort!.index) {
        return false;
      }
    }

    // Evi olan oyuncuya "eşin ev istiyor" olayı çıkmaz (D-085).
    if (req.forbidsProperty &&
        state.items.any((OwnedItem i) => i.isProperty)) {
      return false;
    }
    if (req.forbidsVehicle &&
        state.items.any((OwnedItem i) => i.isVehicle)) {
      return false;
    }
    // Kirada oturmayan oyuncuya ev sahibi olayı çıkmaz.
    if (req.requiresTenant &&
        LivingCosts.situationOf(state) != LivingSituation.kirada) {
      return false;
    }
    // Kendi evinde oturmayana ev sahipliği olayı çıkmaz (Paket BP).
    // Mülk sahipliği yetmiyor: oturulan ev kaydından okunur.
    if (req.requiresOwnedResidence &&
        Housing.residenceOf(state) != ResidenceKind.kendiEvinde) {
      return false;
    }
    if (req.requiresMinYearsInJob > 0 &&
        state.career.yearsInJob(state.player.age) <
            req.requiresMinYearsInJob) {
      return false;
    }
    // Gündelik erişilebilirlik isteyen olaylarda kişi gerçekten
    // ulaşılabilir olmalı. **Bu denetim `_eligiblePeople` içine taşındı**
    // (Paket BO): burada yapılırsa "erişilemeyen kişi çekildi" diye
    // elenen olay, erişilebilir bir kardeşi olsa bile çıkmıyordu.
    // Koşulun yeri seçicidir; eleme değil, aday süzgeci.
    return true;
  }

  /// Tekrarlanabilir olayın yeniden çıkabilmesi için yeterli yaş farkı
  /// geçmiş mi? Böylece aynı olay arka arkaya gelmez ama sonsuza dek de
  /// yasaklanmaz.
  static bool _repeatGapPassed(GameState state, GameEvent event) {
    final int? last = state.lastEventAge[event.id];
    if (last == null) return true;
    // Aralık her tekrarda büyür: üçüncü kez çıkan olay çok daha uzun
    // süre geri gelmez (Paket 20).
    return state.player.age - last >= prototypeOnlyEffectiveGap(state, event);
  }

  static bool _needsPerson(EventRequirement req) =>
      req.livingRelations.isNotEmpty ||
      req.requiresNeglectedRelative ||
      req.requiresTripMemory ||
      req.personRole != null;

  /// Kazanan olayın kişisini seçer.
  ///
  /// Aday yoksa `null`; tek aday varsa zar atılmaz. Zar yalnızca
  /// **gerçekten seçim varken** tüketilir (Paket BO).
  static Person? _pickPerson(List<Person> adaylar, Random rng) {
    if (adaylar.isEmpty) return null;
    if (adaylar.length == 1) return adaylar.first;
    return adaylar[rng.nextInt(adaylar.length)];
  }

  /// Tek kişiyi aday listesine çevirir ve erişilebilirlik süzgecini
  /// uygular. Kilitli kimlik (hikâye kişisi, gezi arkadaşı) için seçim
  /// yoktur: kişi erişilemezse olay çıkmaz.
  static List<Person> _onlyIfUsable(
    GameState state,
    EventRequirement req,
    Person? kisi,
  ) {
    if (kisi == null) return const <Person>[];
    if (req.requireReachable && !state.isReachable(kisi)) {
      return const <Person>[];
    }
    return <Person>[kisi];
  }

  /// Olayın kişi **adayları**. Boş liste, kişi gerektiren olayın
  /// elenmesi demektir.
  ///
  /// **Zar tüketmez** (Paket BO). Eskiden bu iş `_resolvePerson` içinde
  /// `rng` ile yapılıyordu ve havuzdaki her olay için çağrıldığı için
  /// havuz büyüdükçe bütün tohumlu sonuçlar kayıyordu.
  List<Person> _eligiblePeople(GameState state, GameEvent event) {
    final EventRequirement req = event.requirement;

    // Gezi anısı: olayın kişisi, yıllar önce birlikte yola çıktığın
    // kişidir. Gezi yoksa ya da kişi vefat ettiyse olay çıkmaz.
    if (req.requiresTripMemory) {
      final TripRecord? gezi = Travel.memorableTrip(state);
      if (gezi == null) return const <Person>[];
      return _onlyIfUsable(state, req, state.personById(gezi.companionId!));
    }

    // Hikâyede kilitlenmiş kişi: yıllar sonra da aynı kimlik kullanılır.
    final String? role = req.personRole;
    if (role != null) {
      final String? personId = state.storyPeople[role];
      if (personId == null) return const <Person>[];
      final Person? person = state.personById(personId);
      if (person == null || !person.isAlive) return const <Person>[];
      if (req.personMinAge != null && person.age < req.personMinAge!) {
        return const <Person>[];
      }
      if (req.personMaxAge != null && person.age > req.personMaxAge!) {
        return const <Person>[];
      }
      return _onlyIfUsable(state, req, person);
    }

    if (req.requiresNeglectedRelative) {
      final List<Person> neglected = state.people.where((Person p) {
        if (!p.isAlive) return false;
        if (req.requireSameHousehold && !p.inPlayerHousehold) return false;
        // **Gerçek hata (D-093):** bu seçici yalnızca hane koşuluna
        // bakıyordu; `requireOutsideHousehold` ve `requireReachable`
        // koşullarını yok sayıyordu. Yani "uzaktaki yakınla" kurulan bir
        // olay, aynı evde yaşayan ya da hiç erişilemeyen biriyle
        // kurulabiliyordu. Aşağıdaki iki satır o boşluğu kapatır.
        if (req.requireOutsideHousehold && p.inPlayerHousehold) return false;
        if (req.requireReachable && !state.isReachable(p)) return false;
        // Bağ türü belirtilmişse ona da uyulur.
        if (req.livingRelations.isNotEmpty &&
            !req.livingRelations.contains(p.relation)) {
          return false;
        }
        final int? last = state.lastInteractionAge[p.id];
        if (last == null) {
          // Hiç temas kurulmamışsa, oyuncunun etkileşim kurabildiği yaştan
          // itibaren sayılır.
          return state.player.age >= req.minAge + prototypeOnlyNeglectAgeGap;
        }
        return state.player.age - last >= prototypeOnlyNeglectAgeGap;
      }).toList(growable: false);
      return neglected;
    }

    if (req.livingRelations.isEmpty) return const <Person>[];

    final List<Person> uygun = state.people.where((Person p) {
      if (!p.isAlive) return false;
      if (!req.livingRelations.contains(p.relation)) return false;
      if (req.requireSameHousehold && !p.inPlayerHousehold) return false;
      if (req.requireOutsideHousehold && p.inPlayerHousehold) return false;
      // **Erişilebilirlik burada süzülür (Paket BO).** D-093 aynı hatayı
      // "ilgilenilmeyen yakın" seçicisinde kapatmıştı; bu dal açık
      // kalmıştı. Eskiden erişilemeyen bir kardeş çekilince olay
      // elenirdi — erişilebilir kardeşi varken bile.
      if (req.requireReachable && !state.isReachable(p)) return false;
      // Kişinin kendi yaşı: çocuk olayları doğru yaşa bağlanır.
      if (req.personMinAge != null && p.age < req.personMinAge!) return false;
      if (req.personMaxAge != null && p.age > req.personMaxAge!) return false;
      return true;
    }).toList(growable: false);
    return uygun;
  }

  ActiveEvent _toActive(GameState state, GameEvent event, Person? person) {
    return ActiveEvent(
      eventId: event.id,
      category: event.category,
      text: _fillPet(
        _fillTrip(
          _fill(event.text, person, state.player.age),
          state,
          event,
        ),
        state,
        event,
      ),
      // Seçenek etiketlerindeki yer tutucular da doldurulur; ekranda
      // "{kisi}" yazmaz.
      choices: List<EventChoice>.unmodifiable(<EventChoice>[
        for (final EventChoice c in event.choices)
          if (c.label.contains('{'))
            c.withLabel(_fill(c.label, person, state.player.age))
          else
            c,
      ]),
      personId: person?.id,
      // Geçmiş bir seçimin ya da kişinin devamıysa işaretlenir.
      isContinuation: event.requirement.requiredFlags.isNotEmpty ||
          event.requirement.personRole != null,
    );
  }

  /// Havuzdaki olay kaydı; bilinmeyen kimlikte `null`.
  GameEvent? _eventById(String id) {
    for (final GameEvent e in pool) {
      if (e.id == id) return e;
    }
    return null;
  }

  /// Olayın anlattığı evcil hayvan; koşulu sağlayan hayvan yoksa `null`.
  ///
  /// Kayıtta gerçekten duran hayvanlardan seçilir; uydurma hayvan üretilmez.
  static Pet? _eventPet(GameState state, EventRequirement req) {
    for (final Pet pet in state.pets) {
      if (!pet.isAlive || !pet.inPlayerHousehold) continue;
      if (pet.age < req.minPetAge) continue;
      final int? baslangic = pet.adoptedAtPlayerAge;
      if (req.minPetYearsTogether > 0) {
        // Sahiplenme yaşı bilinmeyen hayvan (doğduğunda evde olan) için
        // birliktelik süresi oyuncunun yaşıdır.
        final int birlikte = baslangic == null
            ? state.player.age
            : state.player.age - baslangic;
        if (birlikte < req.minPetYearsTogether) continue;
      }
      return pet;
    }
    return null;
  }

  /// Hayvan olaylarında `{hayvan}` yer tutucusunu **gerçek** hayvanın
  /// adıyla doldurur.
  static String _fillPet(String text, GameState state, GameEvent event) {
    if (!event.requirement.requiresLivingPet) return text;
    final Pet? pet = _eventPet(state, event.requirement);
    if (pet == null) return text;
    return text
        .replaceAll('{hayvan}', pet.name)
        .replaceAll('{tur}', petSpeciesLabel(pet.species));
  }

  /// Gezi anısı olaylarında `{sehir}` yer tutucusunu gerçek gezi
  /// kaydından doldurur; uydurma şehir yazılmaz.
  static String _fillTrip(String text, GameState state, GameEvent event) {
    if (!event.requirement.requiresTripMemory) return text;
    final TripRecord? gezi = Travel.memorableTrip(state);
    if (gezi == null) return text;
    return text.replaceAll('{sehir}', gezi.city);
  }

  /// Metindeki yer tutucuları **gerçekten var olan** kişiyle doldurur.
  ///
  /// - `{kisi}`   : kişinin adı ("Kemal")
  /// - `{sahip}`  : cümle başındaki iyelikli bağ ("Deden")
  /// - `{sahipk}` : cümle içindeki iyelikli bağ ("deden")
  /// - `{bag}`    : yalın bağ etiketi ("dede")
  ///
  /// Kişi yoksa metin olduğu gibi döner; kişi gerektiren olaylar zaten
  /// [_matches] tarafından elendiği için ekrana boş yer tutucu çıkmaz.
  static String _fill(String template, Person? person, int playerAge) {
    if (person == null) return template;
    final String sahip = person.possessiveFor(playerAge);
    return template
        .replaceAll('{kisi}', person.firstName)
        .replaceAll('{sahipk}', trLowerFirst(sahip))
        .replaceAll('{sahip}', sahip)
        .replaceAll('{bag}', trLower(person.labelFor(playerAge)));
  }

  /// Bekleyen olayı verilen seçimle çözer: etkileri uygular, izi bırakır,
  /// hayat günlüğüne yazar ve olayı ekrandan kaldırır.
  ///
  /// Romantik ilişki başlatan veya bitiren seçimler [Romance] üzerinden
  /// işlenir; kişi kimliği hiçbir aşamada değişmez.
  GameState resolve(GameState state, String choiceId, {Random? rng}) {
    final ActiveEvent? active = state.pendingEvent;
    if (active == null) return state;

    final EventChoice choice = active.choices.firstWhere(
      (EventChoice c) => c.id == choiceId,
      orElse: () => active.choices.first,
    );

    // İlişki başlatan seçim önce kişiyi oluşturur ki sonuç metni ve ilişki
    // etkisi doğru kişiye bağlansın.
    const Romance romance = Romance();
    GameState working = state;
    String? newPersonId;
    if (choice.startsRomance) {
      final ({GameState state, Person partner}) started =
          romance.start(working, rng ?? Random());
      working = started.state;
      newPersonId = started.partner.id;
    }
    // Okul arkadaşlığı: olayın kişisi varsa **aynı kimlikle** yakın arkadaşa
    // çevrilir; yoksa kalıcı kimlikli yeni bir arkadaş kaydı açılır.
    // Ün üzerinden tanışma: kişi yalnızca bu seçim yapılırsa üretilir.
    if (choice.startsFriendship) {
      const Friendship friendship = Friendship();
      final ({GameState state, Person friend}) started =
          friendship.startAcquaintance(working, rng ?? Random());
      working = started.state;
      newPersonId = started.friend.id;
    }
    if (choice.startsSchoolFriendship) {
      const Friendship friendship = Friendship();
      final String? adayId = active.personId;
      if (adayId != null && working.personById(adayId) != null) {
        working = friendship.promoteToFriend(working, adayId).state;
      } else {
        final ({GameState state, Person friend}) started =
            friendship.startSchoolFriend(working, rng ?? Random());
        working = started.state;
        newPersonId = started.friend.id;
      }
    }

    final Stats stats = working.player.stats.gain(
      happiness: choice.happiness,
      health: choice.health,
      intelligence: choice.intelligence,
      charisma: choice.charisma,
      appearance: choice.appearance,
    );
    // Sigorta (Paket CA): olay sigortalanabilir bir riske etiketliyse ve
    // oyuncunun o türde poliçesi varsa **zarar** muafiyet + karşılanmayan
    // paya iner. Kazanç tarafına dokunulmaz, sigorta cüzdana para
    // eklemez. Etiketsiz olayda ve poliçesi olmayan oyuncuda satır
    // birebir eskisi gibi çalışır; zar tüketilmez.
    final InsuranceKind? risk = _eventById(active.eventId)?.insuredRisk;
    final ({int paid, int covered, String? note}) sigorta =
        risk == null || choice.money >= 0
            ? (paid: choice.money, covered: 0, note: null)
            : Insurance.settle(working, risk, -choice.money);
    final int paraEtkisi =
        risk == null || choice.money >= 0 ? choice.money : -sigorta.paid;

    final PlayerCharacter player = working.player.copyWith(
      stats: stats,
      // Cüzdan eksiye düşmez; borç/eksi bakiye kuralları kararlaştırılmadı.
      wallet: (working.player.wallet + paraEtkisi).clamp(0, 1 << 31),
    );

    // Etki, olayın kişisine; ilişki başlatan seçimde yeni partnere işlenir.
    final String? bondTargetId = newPersonId ?? active.personId;
    final List<Person> people = bondTargetId == null || choice.bond == 0
        ? working.people
        : working.people
            .map(
              (Person p) => p.id == bondTargetId
                  ? p.copyWith(bond: (p.bond + choice.bond).clamp(0, 100))
                  : p,
            )
            .toList(growable: false);

    final Person? person = bondTargetId == null
        ? null
        : working.people.firstWhere((Person p) => p.id == bondTargetId);
    // Sonuç metni de olay metniyle aynı yer tutucuları destekler
    // (Paket 43): yalnızca `{kisi}` doldurulduğu için `{hayvan}` ya da
    // `{sehir}` içeren bir sonuç metni ekrana ham yer tutucuyla çıkardı.
    final GameEvent? katalog = _eventById(active.eventId);
    String resultText = _fill(choice.resultText, person, working.player.age);
    if (katalog != null) {
      resultText = _fillPet(
        _fillTrip(resultText, state, katalog),
        state,
        katalog,
      );
    }
    // Poliçe devreye girdiyse oyuncu bunu görür ve kayıt sayaca işlenir
    // (Paket CA). Para sessizce azalmaz.
    if (risk != null && sigorta.covered > 0) {
      working = Insurance.recordClaim(working, risk, sigorta.covered);
      resultText = '$resultText\n\n${sigorta.note}';
    }

    working = working.copyWith(
      player: player,
      people: List<Person>.unmodifiable(people),
      storyFlags: <String>{
        ...working.storyFlags.where((String f) => !choice.removeFlags.contains(f)),
        ...choice.addFlags,
      },
      seenEventIds: <String>{...working.seenEventIds, active.eventId},
      // Tekrar aralığı denetimi için olayın çıktığı yaş kaydedilir.
      lastEventAge: <String, int>{
        ...working.lastEventAge,
        active.eventId: working.player.age,
      },
      // Kaçıncı kez çıktığı sayılır; ağırlık ve aralık buna göre değişir.
      eventSeenCounts: <String, int>{
        ...working.eventSeenCounts,
        active.eventId: working.eventSeenCount(active.eventId) + 1,
      },
      // Seçim bir kişiyi hikâye rolüne kilitlediyse kimliği saklanır.
      storyPeople: choice.rememberPersonAs == null || bondTargetId == null
          ? working.storyPeople
          : <String, String>{
              ...working.storyPeople,
              choice.rememberPersonAs!: bondTargetId,
            },
      log: List<LifeLogEntry>.unmodifiable(<LifeLogEntry>[
        ...working.log,
        LifeLogEntry(
          age: working.player.age,
          text: resultText,
          category: LogCategory.kisisel,
          // Olay bir kişiyle kurulduysa günlük satırı o kişiye bağlanır
          // (Paket 14); ortak geçmiş bu bağdan okunur.
          personId: bondTargetId,
        ),
      ]),
      pendingEvent: null,
      // Olay çözüldü: ek olay için ilerleme yeniden birikmeye başlar.
      progressSinceLastEvent: 0,
    );

    // Olayla kazanılan eşyalar gerçek envanter örneği olarak eklenir.
    if (choice.addPossessions.isNotEmpty) {
      working = working.grantItems(
        choice.addPossessions,
        source: ItemSource.olay,
        fromPersonId: bondTargetId,
      );
    }

    // İlişkiyi bitiren seçim: kişi silinmez, aynı kimlikle eski sevgili olur.
    if (choice.endsRomance && active.personId != null) {
      working = romance.end(working, active.personId!, logText: null);
    }

    // Riskli seçimin hukuki tarafı (D-128). Motor kararı kendi verir;
    // seçim yalnızca süreci başlatır.
    final String? sucId = choice.crimeId;
    if (sucId != null) {
      working = LegalEngine.openCase(working, sucId, rng ?? Random());
    }

    // Portföy hamlesi (Paket AD, §AD/3). Suç seçiminde olduğu gibi: karar
    // burada verilmez, ilgili motora devredilir. Hamle başarısız olabilir
    // (işlem durmuş, para yetmiyor, pozisyon yok) ve bu normaldir.
    final PortfolioAction? hamle = choice.portfolioAction;
    if (hamle != null) {
      working = InvestmentEngine.applyEventAction(
        working,
        action: hamle,
        typeId: choice.portfolioTypeId,
        share: choice.portfolioShare,
      );
    }

    // Seçimin sağlık bedeli acil banda indirdiyse zorunlu kritik durum
    // **burada** açılır (Paket AQ).
    //
    // Yalnızca yaş ilerletme yolunda denetlemek yetmiyordu: ölçümde 500
    // hayatın 20'sinde olay seçimi sağlığı 0'a indiriyor ve oyuncu yıl
    // ilerletmeden önce sağlık kazandıran bir aktiviteye gidip durumu
    // sessizce kapatabiliyordu. Sebep biliniyor: kararın kendisi.
    working = CriticalHealth.enforce(
      state: working,
      age: working.player.age,
      cause: CriticalHealthCause.karar,
    );

    return working;
  }
}

class _Candidate {
  const _Candidate(this.event, this.people);

  final GameEvent event;

  /// Olayın kişi adayları. Çekilişi kazanana kadar **hangisi** olduğu
  /// seçilmez (Paket BO).
  final List<Person> people;
}

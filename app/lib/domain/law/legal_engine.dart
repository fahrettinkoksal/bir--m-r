/// Suç ve hukuk motoru (D-128).
///
/// **Ne yapar:** riskli bir seçimin hukuki sonucunu işletir — idari ceza,
/// soruşturma, dava, karar, sabıka, hapis ve tahliye sonrası dönem.
///
/// **Ne yapmaz:** suç işleme, yakalanmama, delil ya da denetimden kaçma
/// gibi hiçbir şeyi anlatmaz ve modellemez. Yakalanma ihtimali soyut
/// etkenlere bağlıdır (olayın ağırlığı, tanık, geçmiş) ve oyuncuya
/// "şöyle yaparsan yakalanmazsın" diyecek hiçbir bilgi verilmez.
///
/// Bütün sayılar `prototypeOnly`'dir (Q-141, Q-142).
library;

import 'dart:math';

import '../../data/crime_catalog.dart';
import '../../data/economy.dart';
import '../../data/lawyer_catalog.dart';
import '../../text/turkish_text.dart';
import '../models/career.dart';
import '../models/criminal_record.dart';
import '../models/game_state.dart';
import '../models/life_log.dart';
import '../models/pending_notice.dart';
import '../models/pending_trial.dart';
import '../models/person.dart';
import '../models/relation.dart';

/// Hukuki sürecin tek kapısı.
abstract final class LegalEngine {
  /// prototypeOnly: soruşturmanın **aynı yıl içinde** karara bağlanma
  /// ihtimali. Kalanı bir sonraki yıla kalır; adalet hızlı değildir.
  static const double prototypeOnlyInvestigationResolveChance = 0.55;

  /// prototypeOnly: soruşturmanın takipsizlikle kapanma ihtimalinin
  /// tabanı. Ağır olaylarda düşer.
  static const double prototypeOnlyDropChance = 0.35;

  /// prototypeOnly: sabıkalı olmanın soruşturmayı ağırlaştırma payı.
  static const double prototypeOnlyPriorRecordWeight = 0.15;

  /// prototypeOnly: hapis cezasının ertelenme tabanı (ilk kez mahkemeye
  /// çıkan biri için).
  static const double prototypeOnlyFirstTimeMercy = 0.30;

  /// prototypeOnly: tahliye sonrası denetim dönemi (yıl).
  static const int prototypeOnlyProbationYears = 2;

  /// prototypeOnly: koşullu salıverilme için gereken iyi hâl.
  static const int prototypeOnlyParoleBehaviour = 60;

  /// prototypeOnly: koşullu salıverilme, içeride gruba bu kadar yakın
  /// duranlara açılmaz (D-140).
  static const int prototypeOnlyParoleCrewLimit = 50;

  // ===================================================================
  // Tutukluluk ve kefalet (D-139)
  //
  // **Önemli ayrım:** kefalet tutukluluğu kaldırır, verilmiş bir hapis
  // cezasını satın almaz. Oyuncu dosya sürerken tutuklanabilir; kefaleti
  // kendi yatırır ya da aileden ister, sonra yargılama dışarıda sürer.
  // Kefalet **teminattır**: duruşmaya çıkılınca geri verilir.
  // ===================================================================

  /// prototypeOnly: ağır bir dosyada tutuklama kararı çıkma ihtimali.
  static const double prototypeOnlyDetentionChance = 0.45;

  /// prototypeOnly: tutukluluk en fazla kaç yıl sürer.
  ///
  /// Süre dolarsa oyuncu **tutuksuz yargılanmak üzere** bırakılır; dosya
  /// kapanmaz, içeride süresiz beklenmez.
  static const int prototypeOnlyMaxDetentionYears = 2;

  /// prototypeOnly: kefalet, olayın para cezası tavanının bu katı.
  static const double prototypeOnlyBailMultiplier = 2.0;

  /// prototypeOnly: aileden kefalet isteği için gereken asgari yakınlık.
  static const int prototypeOnlyBailMinBond = 30;

  /// Bu olay için belirlenen kefalet bedeli (₺).
  ///
  /// Bin ₺'nin katlarına yuvarlanır ki ekranda okunaklı dursun.
  static int bailFor(CrimeType suc) {
    final int taban =
        suc.fineMax > 0 ? suc.fineMax : Economy.netMonthlyMinimumWage * 3;
    final int tutar = (taban * prototypeOnlyBailMultiplier).round();
    return (tutar / 1000).round() * 1000;
  }

  // ===================================================================
  // 1) Dosya açılışı
  // ===================================================================

  /// Riskli bir seçimin hukuki sonucunu başlatır.
  ///
  /// Hafif olaylar **yerinde** kapanır: ceza kesilir, sabıka açılmaz.
  /// Daha ağır olaylarda soruşturma açılabilir; açılıp açılmayacağı
  /// olayın ağırlığına ve geçmişe bakar, oyuncunun bilmediği bir zar
  /// atılır.
  static GameState openCase(
    GameState state,
    String crimeId,
    Random rng,
  ) {
    final CrimeType? suc = crimeTypeById(crimeId);
    if (suc == null) return state;

    final int yas = state.player.age;
    final LegalState hukuk = state.legal;
    final int sayac = hukuk.caseCounter + 1;
    final String dosyaId = 'dosya-$sayac';

    // Olayın soruşturmaya dönüşme ihtimali: ağırlık + geçmiş. Oyuncuya
    // bu hesap gösterilmez ve etkileyecek bir "yöntem" sunulmaz.
    final double sorusturmaSansi = (suc.courtChance +
            (hukuk.hasRecord ? prototypeOnlyPriorRecordWeight : 0))
        .clamp(0.0, 0.95);
    final bool sorusturmaAcildi =
        suc.canLeaveRecord && rng.nextDouble() < sorusturmaSansi;

    if (!sorusturmaAcildi) {
      // İdari ceza ya da olayın kapanması.
      final int ceza = suc.onSpotFine;
      final CriminalCase dosya = CriminalCase(
        id: dosyaId,
        crimeId: crimeId,
        ageAtIncident: yas,
        stage: CaseStage.idariCeza,
        fine: ceza,
        finePaid: ceza > 0,
        closedAtAge: yas,
        note: ceza > 0 ? 'Ceza kesildi, iş orada bitti.' : 'İşlem yapılmadı.',
      );
      GameState next = _withCase(state, dosya, sayac);
      if (ceza > 0) {
        next = _takeMoney(next, ceza);
        next = _log(next, '${suc.label}: ${trMoney(ceza)} ceza kesildi.');
        next = _notice(
          next,
          id: 'adli-$dosyaId',
          title: suc.label,
          text: _idariCezaMetni(suc, ceza),
          money: -ceza,
        );
      }
      return next;
    }

    final CriminalCase dosya = CriminalCase(
      id: dosyaId,
      crimeId: crimeId,
      ageAtIncident: yas,
      stage: CaseStage.sorusturma,
      note: 'Hakkında soruşturma başlatıldı.',
    );
    GameState next = _withCase(state, dosya, sayac);
    next = _log(next, '${suc.label} nedeniyle hakkında soruşturma açıldı.');
    next = _notice(
      next,
      id: 'adli-$dosyaId',
      title: 'Hakkında soruşturma var',
      text: 'İfaden alındı. Memur dosyayı kapattı:\n\n'
          '"Savcılık bakacak, sana haber gelir."\n\n'
          'Konu: ${suc.label}.',
    );
    next = _familyReaction(next, suc);
    next = _maybeDetain(next, suc, rng);
    return next;
  }

  /// Ağır bir dosyada tutuklama kararı çıkabilir (D-139).
  ///
  /// Çocuk tutuklanmaz: bu prototipte tutukluluk yalnızca 18 yaşından
  /// itibaren uygulanır. Karar oyuncunun görmediği bir zara bağlıdır ve
  /// etkileyecek bir "yöntem" sunulmaz.
  static GameState _maybeDetain(GameState state, CrimeType suc, Random rng) {
    if (state.player.age < 18) return state;
    if (state.legal.isImprisoned) return state;
    final bool tutuklanabilir = suc.severity == CrimeSeverity.agir ||
        (suc.severity == CrimeSeverity.orta && state.legal.hasRecord);
    if (!tutuklanabilir) return state;
    if (rng.nextDouble() >= prototypeOnlyDetentionChance) return state;

    final int yas = state.player.age;
    final int kefalet = bailFor(suc);
    GameState next = state.copyWith(
      legal: state.legal.copyWith(
        detainedSinceAge: yas,
        bailAmount: kefalet,
        bailPaidBy: null,
        bailAskedAtAge: null,
      ),
      player: state.player.copyWith(
        stats: state.player.stats.gain(happiness: -8, health: -2),
      ),
    );
    next = _log(
      next,
      '${suc.label} dosyasında tutuklandın. Kefalet '
      '${trMoney(kefalet)} olarak belirlendi.',
    );
    next = _notice(
      next,
      id: 'tutuklama-$yas-${suc.id}',
      title: 'Tutuklandın',
      text: 'Dosya sürerken tutuklama kararı çıktı.\n\n'
          'Kefalet ${trMoney(kefalet)}. Yatırırsan dışarıda '
          'beklersin; yatırmazsan duruşmaya kadar içerideyim demektir.\n\n'
          'Kefalet teminattır: duruşmaya çıkınca geri verilir.',
    );
    return _loosenBonds(next, perYear: false);
  }

  // ===================================================================
  // 2) Yıllık ilerleme
  // ===================================================================

  /// Açık dosyaları ve hapis durumunu bir yıl ilerletir.
  static GameState advanceYear(GameState state, int newAge, Random rng) {
    GameState next = _advancePrison(state, newAge);
    next = _advanceDetention(next, newAge);
    next = _advanceInvestigations(next, newAge, rng);
    return next;
  }

  /// Tutuklulukta geçen yılı işler (D-139).
  ///
  /// Süre dolduysa oyuncu **tutuksuz yargılanmak üzere** bırakılır; dosya
  /// açık kalır, içeride süresiz beklenmez.
  static GameState _advanceDetention(GameState state, int newAge) {
    final LegalState hukuk = state.legal;
    final int? giris = hukuk.detainedSinceAge;
    if (giris == null || hukuk.isSentenced) return state;

    if (newAge - giris < prototypeOnlyMaxDetentionYears) {
      GameState next = _log(
        state,
        'Bir yıl daha tutuklu geçti. Dosya hâlâ açık.',
      );
      next = next.copyWith(
        player: next.player.copyWith(
          stats: next.player.stats.gain(happiness: -5, health: -2),
        ),
        legal: next.legal.copyWith(yearsServed: next.legal.yearsServed + 1),
      );
      return _loosenBonds(next, perYear: true);
    }

    GameState next = state.copyWith(
      legal: hukuk.copyWith(detainedSinceAge: null),
    );
    next = _log(
      next,
      'Tutukluluğun kaldırıldı; yargılama tutuksuz sürecek.',
    );
    return _notice(
      next,
      id: 'tutuksuz-$newAge',
      title: 'Tutukluluk kaldırıldı',
      text: 'Tutukluluğun kaldırıldı. Dosya kapanmadı: yargılama '
          'dışarıda sürecek.\n\n'
          'Duruşmaya gitmen gerekiyor.',
    );
  }

  /// Hapisteki yılı işler; süresi dolduysa tahliye eder.
  static GameState _advancePrison(GameState state, int newAge) {
    final LegalState hukuk = state.legal;
    final int? tahliye = hukuk.releaseAtAge;
    if (tahliye == null) return state;

    // Koşullu salıverilme (D-140): iyi hâl toplandıysa ve cezanın yarısı
    // yatıldıysa tahliye öne çekilir. İçeride gruba yakın durmak bu
    // kapıyı kapatır — ikisi birlikte yürümez.
    final int giris = hukuk.imprisonedSinceAge ?? newAge;
    final int toplamCeza = (tahliye - giris).clamp(1, 60);
    final bool yariniYatti = newAge - giris >= (toplamCeza / 2).ceil();
    final bool kosulluHak = newAge < tahliye &&
        yariniYatti &&
        hukuk.goodBehaviour >= prototypeOnlyParoleBehaviour &&
        hukuk.crewStanding < prototypeOnlyParoleCrewLimit;

    if (newAge < tahliye && !kosulluHak) {
      // İçeride geçen yıl: dışarıdaki hayat yerinde saymaz.
      GameState next = _log(
        state,
        'Bir yıl daha içeride geçti. Dışarısı kendi hâlinde akıyor.',
      );
      next = next.copyWith(
        player: next.player.copyWith(
          stats: next.player.stats.gain(happiness: -6, health: -2),
        ),
        legal: next.legal.copyWith(yearsServed: next.legal.yearsServed + 1),
      );
      return _loosenBonds(next, perYear: true);
    }

    // Tahliye (süre doldu ya da koşullu salıverildi).
    final List<CriminalCase> guncel = hukuk.cases
        .map(
          (CriminalCase c) => c.verdict == Verdict.hapis && c.closedAtAge == null
              ? c.copyWith(closedAtAge: newAge)
              : c,
        )
        .toList(growable: false);

    GameState next = state.copyWith(
      legal: hukuk.copyWith(
        cases: guncel,
        imprisonedSinceAge: null,
        releaseAtAge: null,
        probationUntilAge: newAge + prototypeOnlyProbationYears,
      ),
    );
    next = _log(
      next,
      kosulluHak
          ? 'İyi hâlden koşullu salıverildin. Kapıdan çıkarken hava '
              'soğuktu.'
          : 'Tahliye oldun. Kapıdan çıkarken hava soğuktu.',
    );
    next = _notice(
      next,
      id: 'tahliye-$newAge',
      title: kosulluHak ? 'Koşullu salıverildin' : 'Tahliye oldun',
      text: kosulluHak
          ? 'İyi hâl dosyan tuttu; cezanın kalanını dışarıda '
              'çekeceksin.\n\n'
              'Kapı arkandan kapandı. Cebinde bir poşet, elinde bir '
              'kâğıt.\n\n'
              'Denetim dönemin $prototypeOnlyProbationYears yıl sürecek.'
          : 'Kapı arkandan kapandı. Cebinde bir poşet, elinde bir '
              'kâğıt.\n\n'
              'Denetim dönemin $prototypeOnlyProbationYears yıl sürecek.',
    );
    return next;
  }

  /// Soruşturmaları ilerletir: kapanır ya da mahkemeye gider.
  static GameState _advanceInvestigations(
    GameState state,
    int newAge,
    Random rng,
  ) {
    final LegalState hukuk = state.legal;
    // Hükümlüyken yeni dosya ilerlemez; **tutukluyken ilerler**, yoksa
    // tutuklu oyuncu içeride sonsuza kadar beklerdi (D-139).
    if (hukuk.isSentenced) return state;
    final CriminalCase? acik = hukuk.openCase;
    if (acik == null) return state;

    // Zaten duruşma bekliyorsa yeni bir şey yapılmaz.
    if (acik.stage == CaseStage.dava) {
      return state.pendingTrial == null
          ? _openTrial(state, acik, newAge)
          : state;
    }

    // Soruşturma her yıl sonuçlanmaz.
    if (rng.nextDouble() > prototypeOnlyInvestigationResolveChance) {
      return state;
    }

    final CrimeType? suc = acik.crime;
    if (suc == null) return state;

    // Takipsizlik ihtimali: hafif olayda yüksek, ağırda düşük.
    final double takipsizlik = (prototypeOnlyDropChance -
            suc.severity.index * 0.12 -
            (hukuk.hasRecord ? prototypeOnlyPriorRecordWeight : 0))
        .clamp(0.02, 0.6);

    if (rng.nextDouble() < takipsizlik) {
      GameState next = _replaceCase(
        state,
        acik.copyWith(
          stage: CaseStage.takipsizlik,
          closedAtAge: newAge,
          note: 'Takipsizlik kararı verildi.',
        ),
      );
      // Dosya kapandıysa tutukluluk da biter, kefalet geri verilir.
      next = _releaseDetention(next, attended: true);
      return _notice(
        _log(next, '${suc.label} dosyasında takipsizlik kararı çıktı.'),
        id: 'takipsizlik-${acik.id}',
        title: 'Dosya kapandı',
        text: 'Savcılık takipsizlik kararı vermiş.\n\n'
            'Kâğıdı iki kez okudun. Sonra bir daha.',
      );
    }

    final GameState next = _replaceCase(
      state,
      acik.copyWith(stage: CaseStage.dava, note: 'Dosya mahkemeye gitti.'),
    );
    return _openTrial(next, acik.copyWith(stage: CaseStage.dava), newAge);
  }

  /// Duruşmayı ekrana koyar.
  static GameState _openTrial(
    GameState state,
    CriminalCase dosya,
    int newAge,
  ) {
    final CrimeType? suc = dosya.crime;
    if (suc == null) return state;
    return state.copyWith(
      pendingTrial: PendingTrial(
        caseId: dosya.id,
        age: newAge,
        text: 'Dosyan mahkemeye çıktı. Koridorda beklerken kimse '
            'konuşmuyor.\n\n'
            'Hâkim dosyaya baktı, sonra sana döndü.\n\n'
            'Konu: ${suc.label}.',
      ),
    );
  }

  // ===================================================================
  // 3) Duruşma
  // ===================================================================

  /// Avukat tutmanın şu an mümkün olup olmadığı.
  ///
  /// Parası yetmiyorsa düğme açılmaz ve gerekçesi yazılır (D-063).
  static String lawyerBlockReason(GameState state, LawyerTier tier) {
    if (tier.fee == 0) return '';
    if (state.player.wallet < tier.fee) {
      return 'Ücret ${trMoney(tier.fee)}; cüzdanında '
          '${trMoney(state.player.wallet)} var.';
    }
    return '';
  }

  /// Duruşmayı karara bağlar.
  ///
  /// Avukat **sonucu garanti etmez**; yalnızca yumuşama ihtimalini bir
  /// miktar yükseltir. Aynı dosya iki kez karara bağlanmaz.
  static GameState resolveTrial({
    required GameState state,
    required DefenceStance stance,
    required String lawyerId,
    required Random rng,
  }) {
    final PendingTrial? durusma = state.pendingTrial;
    if (durusma == null) return state;
    final CriminalCase? dosya = state.legal.caseById(durusma.caseId);
    if (dosya == null || dosya.stage != CaseStage.dava) {
      return state.copyWith(pendingTrial: null);
    }
    final CrimeType? suc = dosya.crime;
    if (suc == null) return state.copyWith(pendingTrial: null);

    final LawyerTier avukat = lawyerTierById(lawyerId) ?? kSelfDefenceTier;
    GameState next = state;
    // Ücret peşin ve **bir kez** ödenir.
    if (avukat.fee > 0 && state.player.wallet >= avukat.fee) {
      next = _takeMoney(next, avukat.fee);
    }
    final LawyerTier gecerli =
        avukat.fee > 0 && state.player.wallet < avukat.fee
            ? kSelfDefenceTier
            : avukat;

    // Yumuşama payı: ilk kez mahkemeye çıkmak, avukat ve tutum.
    final bool ilkKez = !state.legal.everTried;
    double merhamet = gecerli.mercyBonus;
    if (ilkKez) merhamet += prototypeOnlyFirstTimeMercy;
    switch (stance) {
      case DefenceStance.pismanlik:
        merhamet += 0.12;
      case DefenceStance.anlat:
        // Dürüstlük her zaman işe yaramaz ama bazen yarar.
        merhamet += rng.nextBool() ? 0.10 : -0.05;
      case DefenceStance.avukat:
        // Avukat yoksa susmak işe yaramaz.
        merhamet += gecerli.fee > 0 ? 0.08 : -0.10;
    }
    // Sabıka ağırlaştırır.
    merhamet -= state.legal.record.length * 0.10;
    merhamet = merhamet.clamp(-0.4, 0.85);

    final double zar = rng.nextDouble();
    final Verdict karar = _decide(suc, merhamet, zar);

    int ceza = 0;
    int hapisYili = 0;
    switch (karar) {
      case Verdict.paraCezasi:
        final int aralik = (suc.fineMax - suc.fineMin).clamp(1, 1 << 30);
        ceza = suc.fineMin + rng.nextInt(aralik);
      case Verdict.hapis:
        final int aralik =
            (suc.prisonYearsMax - suc.prisonYearsMin).clamp(0, 20);
        hapisYili = suc.prisonYearsMin + (aralik == 0 ? 0 : rng.nextInt(aralik + 1));
        if (hapisYili < 1) hapisYili = 1;
      case Verdict.yok:
      case Verdict.beraat:
      case Verdict.uyari:
      case Verdict.erteleme:
        break;
    }

    final int yas = next.player.age;
    CriminalCase kapanan = dosya.copyWith(
      stage: CaseStage.karar,
      verdict: karar,
      fine: ceza,
      prisonYears: hapisYili,
      lawyerId: gecerli.id,
      decidedAtAge: yas,
      note: _kararNotu(karar, ceza, hapisYili),
    );

    // Para cezası **bir kez** tahsil edilir.
    if (ceza > 0) {
      next = _takeMoney(next, ceza);
      kapanan = kapanan.copyWith(finePaid: true, closedAtAge: yas);
    } else if (karar != Verdict.hapis) {
      kapanan = kapanan.copyWith(closedAtAge: yas);
    }

    next = _replaceCase(next, kapanan).copyWith(pendingTrial: null);

    // Tutuklulukta geçen süre cezadan düşülür (D-139): oyuncu aynı yılı
    // iki kez yatmaz. Kefalet yatırılmışsa duruşmaya çıkıldığı için geri
    // verilir.
    final int tutuklulukYili = next.legal.detainedSinceAge == null
        ? 0
        : (yas - next.legal.detainedSinceAge!).clamp(0, 50);
    next = _releaseDetention(next, attended: true);

    // Hapis: iş biter, gelir kesilir, bağlar zayıflar.
    if (karar == Verdict.hapis) {
      final int kalan = hapisYili - tutuklulukYili;
      if (kalan <= 0) {
        // Tutuklulukta yatılan süre cezayı karşıladı: dosya kapanır.
        next = _replaceCase(next, kapanan.copyWith(closedAtAge: yas));
        next = _log(
          next,
          'Ceza, tutuklulukta geçen süreden sayıldı; içeride '
          'kalmayacaksın.',
        );
      } else {
        next = _enterPrison(next, yas, kalan);
      }
    }

    next = _log(next, _kararGunlugu(suc, karar, ceza, hapisYili));
    next = _notice(
      next,
      id: 'karar-${dosya.id}',
      title: 'Mahkeme kararı',
      text: _kararMetni(suc, karar, ceza, hapisYili),
      money: -ceza,
    );
    if (karar.leavesRecord) next = _familyReaction(next, suc);
    return next;
  }

  static Verdict _decide(CrimeType suc, double merhamet, double zar) {
    // Ağırlık arttıkça beraat/uyarı penceresi daralır.
    final double beraatEsigi = (0.12 + merhamet * 0.35 -
            suc.severity.index * 0.05)
        .clamp(0.02, 0.5);
    final double uyariEsigi = beraatEsigi +
        (suc.severity == CrimeSeverity.hafif ? 0.25 : 0.10);
    if (zar < beraatEsigi) return Verdict.beraat;
    if (zar < uyariEsigi) return Verdict.uyari;

    final bool hapisMumkun = suc.prisonYearsMax > 0;
    if (!hapisMumkun) return Verdict.paraCezasi;

    // Hapis penceresi: merhamet yükseldikçe erteleme öne geçer.
    final double ertelemeEsigi = (uyariEsigi + 0.20 + merhamet * 0.30)
        .clamp(uyariEsigi, 0.92);
    if (zar < ertelemeEsigi) {
      // Ağır olayda erteleme yerine para cezası da çıkabilir.
      return suc.severity == CrimeSeverity.agir
          ? Verdict.erteleme
          : Verdict.paraCezasi;
    }
    return Verdict.hapis;
  }

  /// Hapse girişin oyun içindeki gerçek sonuçları.
  static GameState _enterPrison(GameState state, int yas, int yil) {
    GameState next = state.copyWith(
      legal: state.legal.copyWith(
        imprisonedSinceAge: yas,
        releaseAtAge: yas + yil,
      ),
      player: state.player.copyWith(
        stats: state.player.stats.gain(happiness: -12, health: -4),
      ),
    );
    // İş biter: maaş kesilir, kayıt geçmişe yazılır (silinmez).
    if (next.career.isEmployed) {
      final String? isAdi = next.career.job?.name;
      next = next.copyWith(
        career: next.career.closeCurrentJob(
          endedAtAge: yas,
          reason: JobEndReason.hapis,
        ),
      );
      next = _log(
        next,
        isAdi == null
            ? 'İşin bitti.'
            : '$isAdi işin bitti; içerideyken kimse yerini tutmuyor.',
      );
    }
    return _loosenBonds(next, perYear: false);
  }

  /// Tutukluluğu kaldırır ve kefaleti geri verir (D-139).
  ///
  /// Kefalet **teminattır**: duruşmaya çıkıldığında ya da dosya
  /// kapandığında geri verilir. Oyuncu kendi yatırdıysa para cüzdana
  /// döner; aileden biri yatırdıysa para **ona** geri gider, oyuncunun
  /// cüzdanına girmez, ama aradaki bağ güçlenir.
  static GameState _releaseDetention(
    GameState state, {
    required bool attended,
  }) {
    final LegalState hukuk = state.legal;
    if (!hukuk.isDetained && !hukuk.bailPaid) return state;

    final int? kefalet = hukuk.bailAmount;
    final String? odeyen = hukuk.bailPaidBy;
    GameState next = state.copyWith(
      legal: hukuk.copyWith(
        detainedSinceAge: null,
        bailAmount: null,
        bailPaidBy: null,
        bailAskedAtAge: null,
      ),
    );
    if (!attended || kefalet == null || kefalet <= 0 || odeyen == null) {
      return next;
    }

    if (odeyen == LegalState.selfPaidBail) {
      next = next.copyWith(
        player: next.player.copyWith(
          wallet: next.player.wallet + kefalet,
        ),
      );
      next = _log(next, 'Kefalet ${trMoney(kefalet)} geri ödendi.');
      return _notice(
        next,
        id: 'kefalet-geri-${next.player.age}',
        title: 'Kefalet geri verildi',
        text: 'Duruşmaya çıktın; yatırdığın kefalet geri ödendi.\n\n'
            '${trMoney(kefalet)} cüzdanına döndü.',
        money: kefalet,
      );
    }

    final Person? kisi = next.personById(odeyen);
    if (kisi == null) return next;
    next = next.copyWith(
      people: List<Person>.unmodifiable(
        next.people
            .map(
              (Person p) => p.id == odeyen
                  ? p.copyWith(bond: (p.bond + 3).clamp(0, 100))
                  : p,
            )
            .toList(growable: false),
      ),
    );
    next = _log(
      next,
      'Kefalet geri ödendi; parayı ${kisi.firstName}\'a geri verdin.',
    );
    return _notice(
      next,
      id: 'kefalet-geri-${next.player.age}',
      title: 'Kefalet geri verildi',
      text: 'Duruşmaya çıktın, kefalet geri ödendi. Parayı '
          '${kisi.firstName}\'a geri verdin.\n\n'
          'Kimse bir şey demedi ama not edildi.',
      personId: kisi.id,
    );
  }

  /// Uzaklaşan bağlar. **Kimse listeden silinmez** (D-058 ile aynı ilke).
  static GameState _loosenBonds(GameState state, {required bool perYear}) {
    final int dusus = perYear ? 3 : 6;
    final List<Person> kisiler = state.people
        .map(
          (Person p) => p.isAlive
              ? p.copyWith(bond: (p.bond - dusus).clamp(0, 100))
              : p,
        )
        .toList(growable: false);
    return state.copyWith(people: List<Person>.unmodifiable(kisiler));
  }

  // ===================================================================
  // 4) Ailenin tepkisi
  // ===================================================================

  /// Aile ve eş haberi duyar. Kimse otomatik olarak ilişkiyi kesmez.
  static GameState _familyReaction(GameState state, CrimeType suc) {
    if (suc.familyShockPoints <= 0) return state;
    final List<Person> yakinlar = state.people
        .where(
          (Person p) =>
              p.isAlive &&
              (p.relation == RelationType.anne ||
                  p.relation == RelationType.baba ||
                  p.relation == RelationType.es),
        )
        .toList(growable: false);
    if (yakinlar.isEmpty) return state;

    // Tepkinin sertliği olayın ağırlığına ve önceki sabıkaya bakar.
    final int tekrar = state.legal.record.length;
    final int dusus = suc.familyShockPoints + tekrar * 2;

    final Set<String> hedefler =
        yakinlar.map((Person p) => p.id).toSet();
    final List<Person> kisiler = state.people
        .map(
          (Person p) => hedefler.contains(p.id)
              ? p.copyWith(bond: (p.bond - dusus).clamp(0, 100))
              : p,
        )
        .toList(growable: false);

    final Person ilk = yakinlar.first;
    final String metin = _aileMetni(ilk, tekrar);
    GameState next = state.copyWith(
      people: List<Person>.unmodifiable(kisiler),
      player: state.player.copyWith(
        stats: state.player.stats.gain(happiness: -3),
      ),
    );
    next = _log(next, metin);
    return _notice(
      next,
      id: 'aile-adli-${state.player.age}-${suc.id}',
      title: 'Evde duyulmuş',
      text: metin,
      personId: ilk.id,
    );
  }

  static String _aileMetni(Person kisi, int tekrar) {
    final String ad = kisi.firstName;
    if (kisi.relation == RelationType.es) {
      return tekrar == 0
          ? '$ad kapıda seni bekliyordu. Bağırmadı. '
              '"Otur, anlat" dedi.'
          : '$ad bu sefer soru sormadı. Ceketini alıp odaya geçti.';
    }
    if (tekrar == 0) {
      return '$ad haberi senden önce duymuş.\n\n'
          '"Bir de bunu komşudan mı öğrenecektim?"';
    }
    return '$ad telefonu açtı, uzun sustu.\n\n'
        '"Yine mi" dedi. Başka bir şey demedi.';
  }

  // ===================================================================
  // Metinler
  // ===================================================================

  static String _idariCezaMetni(CrimeType suc, int ceza) {
    switch (suc.id) {
      case 'trafik_hiz':
        return 'Radar seni görmüş. Tebligat posta kutusunda seni '
            'bekliyordu.\n\nCeza ${trMoney(ceza)}.';
      case 'trafik_park':
        return 'Dönüşte camda o kâğıdı gördün. Kenarı rüzgârda '
            'kıvrılmış.\n\nCeza ${trMoney(ceza)}.';
      case 'trafik_kaza':
        return 'Tutanak tutuldu. Karşı taraf "sigortadan hallederiz" '
            'dedi ama olmadı.\n\nCebinden ${trMoney(ceza)} çıktı.';
      case 'kamu_duzeni':
        return 'Memur kimliğine baktı, kısa kesti:\n\n'
            '"Şöyle kenara geçelim."\n\nCeza ${trMoney(ceza)}.';
      case 'trafik_alkollu':
        return 'Ehliyetin alındı. Memurun sesi ne sert ne yumuşaktı.\n\n'
            'Ceza ${trMoney(ceza)}.';
      default:
        return '${suc.label}: ${trMoney(ceza)} ceza kesildi.';
    }
  }

  static String _kararNotu(Verdict karar, int ceza, int hapis) {
    switch (karar) {
      case Verdict.beraat:
        return 'Beraat etti.';
      case Verdict.uyari:
        return 'Uyarıyla kapandı.';
      case Verdict.paraCezasi:
        return 'Para cezası: ${trMoney(ceza)}.';
      case Verdict.erteleme:
        return 'Hüküm ertelendi.';
      case Verdict.hapis:
        return '$hapis yıl hapis.';
      case Verdict.yok:
        return '';
    }
  }

  static String _kararGunlugu(
    CrimeType suc,
    Verdict karar,
    int ceza,
    int hapis,
  ) {
    switch (karar) {
      case Verdict.beraat:
        return '${suc.label} dosyasından beraat ettin.';
      case Verdict.uyari:
        return '${suc.label} dosyası uyarıyla kapandı.';
      case Verdict.paraCezasi:
        return '${suc.label}: ${trMoney(ceza)} para cezası aldın.';
      case Verdict.erteleme:
        return '${suc.label}: hüküm ertelendi, kayıtta duruyor.';
      case Verdict.hapis:
        return '${suc.label}: $hapis yıl hapis cezası aldın.';
      case Verdict.yok:
        return '';
    }
  }

  static String _kararMetni(
    CrimeType suc,
    Verdict karar,
    int ceza,
    int hapis,
  ) {
    switch (karar) {
      case Verdict.beraat:
        return 'Hâkim dosyayı kapattı.\n\n'
            '"Beraatine karar verilmiştir."\n\n'
            'Koridora çıkınca bacakların titriyordu.';
      case Verdict.uyari:
        return 'Hâkim gözlüğünü çıkardı:\n\n'
            '"Bu sefer uyarıyla geçiyoruz. Bir daha görmeyelim."';
      case Verdict.paraCezasi:
        return 'Karar okundu: ${trMoney(ceza)} para cezası.\n\n'
            'Sayı kulağında bir süre daha yankılandı.';
      case Verdict.erteleme:
        return 'Hüküm verildi ama infazı ertelendi.\n\n'
            'Kayıtta duruyor. Bir daha aynı kapıya gelmemen şartıyla.';
      case Verdict.hapis:
        return '$hapis yıl.\n\n'
            'Sayıyı duyunca salonda kimsenin kıpırdadığı yok. '
            'Bir tek sen duyuyorsun.';
      case Verdict.yok:
        return suc.label;
    }
  }

  // ===================================================================
  // Yardımcılar
  // ===================================================================

  static GameState _withCase(GameState state, CriminalCase dosya, int sayac) =>
      state.copyWith(
        legal: state.legal.copyWith(
          cases: <CriminalCase>[...state.legal.cases, dosya],
          caseCounter: sayac,
        ),
      );

  static GameState _replaceCase(GameState state, CriminalCase dosya) =>
      state.copyWith(
        legal: state.legal.copyWith(
          cases: state.legal.cases
              .map((CriminalCase c) => c.id == dosya.id ? dosya : c)
              .toList(growable: false),
        ),
      );

  /// Cüzdan **eksiye düşmez** (ECO-001 ile aynı kural).
  static GameState _takeMoney(GameState state, int tutar) => state.copyWith(
        player: state.player.copyWith(
          wallet: (state.player.wallet - tutar).clamp(0, 1 << 31),
        ),
      );

  static GameState _log(GameState state, String metin) => state.copyWith(
        log: List<LifeLogEntry>.unmodifiable(<LifeLogEntry>[
          ...state.log,
          LifeLogEntry(
            age: state.player.age,
            text: metin,
            category: LogCategory.kisisel,
          ),
        ]),
      );

  static GameState _notice(
    GameState state, {
    required String id,
    required String title,
    required String text,
    int money = 0,
    String? personId,
  }) =>
      state.queueNotice(
        PendingNotice(
          id: id,
          kind: NoticeKind.adli,
          age: state.player.age,
          title: title,
          text: text,
          money: money,
          personId: personId,
        ),
      );
}

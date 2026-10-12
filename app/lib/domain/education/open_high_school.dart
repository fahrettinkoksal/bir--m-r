/// Açık lise: okulu bırakanın ikinci şansı (Paket DC).
///
/// **Neden var.** Gebelik karesi okunurken çıktı: 35 yaşında, 18 yıllık,
/// 336.552 ₺ maaşlı bir karakterin ekranı "tam zamanlı iş liseyi
/// bitirdikten sonra açılır" diyordu ve iş arama satırı hiç yoktu.
/// Kayıtta tek sebep vardı: okulu bırakmıştı. Ölçüm (55 işlik katalog):
///
/// | Eğitim koşulu | İş sayısı |
/// |---|---|
/// | `JobEducation.yok` | 25 |
/// | `JobEducation.lise` | **17** |
/// | `JobEducation.universite` | **13** |
///
/// Yani diploması olmayan oyuncuya kataloğun **30 işi** kapanıyordu ve
/// kapanma **ömür boyu** sürüyordu: `açık lise`, `reEnroll`, `okula dön`
/// diye aranan hiçbir yol kodda yoktu. Okulu bırakmak oyunun tek geri
/// dönüşsüz kararıydı.
///
/// Ölçümün ikinci yarısı (236 hayat, 30 yaşında bakıldı): diplomasız
/// yetişkin **4** hayatta çıkıyor (%1,7) ve dördü de üç yıl sınıfta
/// kaldıktan sonra okuldan ayrılmış. Seyrek; ama oyuncu bu kararı
/// bilerek de verebilir ve kapı bir daha açılmıyordu.
///
/// **Neden `enrolled` kullanılmadı.** Açık lisenin bütün anlamı çalışırken
/// okumaktır. `EducationState.enrolled` açılsa oyuncu `isSchoolStudent`
/// sayılır ve `JobMarket.requirementReason` tam zamanlı işi kapatırdı
/// (D-131). Bu yüzden kayıt ayrı bir alanda tutulur:
/// `EducationState.openHighSchoolGrade`.
///
/// **Kapsam sınırı (bilerek).** Bu dosya yalnızca lise kademesini açar.
/// Açık ortaokul yok: 9. sınıftan önce ayrılan oyuncu da 9. sınıftan
/// devam eder. Yetişkin için üniversite yolu (AÖF) da yok — diploma
/// alındıktan sonra üniversite kapısı `EducationPath`'in kendi
/// kuralına (`needsAfterSchoolChoice`, en çok 30 yaş) tabidir. İkisi de
/// tasarım sorusu olarak kuyrukta.
///
/// Bütün sayılar `prototypeOnly`'dir.
library;

import '../../text/turkish_text.dart';
import '../features/feature_catalog.dart';
import '../models/game_state.dart';
import '../models/interaction.dart';
import '../models/life_log.dart';

abstract final class OpenHighSchool {
  /// prototypeOnly: açık liseye kayıt olunabilen en küçük yaş.
  ///
  /// Zorunlu eğitim çağındaki çocuk buraya yönlendirilmez; örgün okulun
  /// kendi akışı sürer.
  static const int prototypeOnlyMinAge = 18;

  /// prototypeOnly: açık lisenin ilk sınıfı.
  static const int prototypeOnlyFirstGrade = 9;

  /// prototypeOnly: diplomanın alındığı sınıf.
  static const int prototypeOnlyLastGrade = 12;

  /// prototypeOnly: yıllık kayıt ücreti.
  ///
  /// Oyunun küçük ücret bandına oturtuldu (ehliyet sınavı 4.000-8.000 ₺);
  /// açık lise devlet okuludur, o bandın altında kalır. Kalibrasyon
  /// sorusu kuyrukta.
  static const int prototypeOnlyYearlyFee = 3500;

  /// prototypeOnly: her tamamlanan yılın mutluluğa katkısı.
  static const int prototypeOnlyYearHappiness = 2;

  /// prototypeOnly: her tamamlanan yılın zekâya katkısı.
  static const int prototypeOnlyYearIntelligence = 1;

  /// prototypeOnly: diploma alındığında gelen mutluluk.
  static const int prototypeOnlyDiplomaHappiness = 8;

  static bool isOn(GameState state) => state.featureOn(FeatureId.acikLise);

  /// Kaç yıl daha okunacak? Kayıtlı değilse `null`.
  static int? remainingYears(GameState state) {
    final int? sinif = state.education.openHighSchoolGrade;
    if (sinif == null) return null;
    return (prototypeOnlyLastGrade - sinif + 1).clamp(0, 4);
  }

  /// Kayıt olunurken başlanacak sınıf.
  ///
  /// Bırakılan sınıftan devam edilir; 9'un altına düşmez (açık ortaokul
  /// kapsam dışı).
  static int startGrade(GameState state) {
    final int birakilan = state.education.grade ?? prototypeOnlyFirstGrade;
    if (birakilan < prototypeOnlyFirstGrade) return prototypeOnlyFirstGrade;
    if (birakilan > prototypeOnlyLastGrade) return prototypeOnlyLastGrade;
    return birakilan;
  }

  /// Kayıt olmak mümkün mü? Değilse gerekçesi yazılır (D-063).
  static InteractionAvailability enrollAvailability(GameState state) {
    final String? kapali = state.featureBlockReason(FeatureId.acikLise);
    if (kapali != null) return InteractionAvailability.blocked(kapali);
    if (state.education.finished) {
      return const InteractionAvailability.blocked(
        'Lise diploman zaten var.',
      );
    }
    if (state.education.isOpenHighSchoolStudent) {
      return const InteractionAvailability.blocked(
        'Açık liseye zaten kayıtlısın.',
      );
    }
    if (state.education.isStudent) {
      return const InteractionAvailability.blocked(
        'Okula devam ediyorsun; açık liseye gerek yok.',
      );
    }
    if (state.player.age < prototypeOnlyMinAge) {
      return InteractionAvailability.blocked(
        'Açık lise $prototypeOnlyMinAge yaşından itibaren açılır.',
      );
    }
    if (state.isImprisoned) {
      return const InteractionAvailability.blocked(
        'Cezaevindesin; kayıt işlemini dışarıda yapabilirsin.',
      );
    }
    if (state.player.wallet < prototypeOnlyYearlyFee) {
      return InteractionAvailability.blocked(
        'Yıllık kayıt ücreti ${trMoney(prototypeOnlyYearlyFee)}; '
        'cüzdanında yeterli para yok.',
      );
    }
    return const InteractionAvailability.allowed();
  }

  /// Açık liseye kaydolur. Ücret o yıl değil, yıl dönerken alınır.
  static ({GameState state, String text})? enroll(GameState state) {
    if (!enrollAvailability(state).isAllowed) return null;
    final int sinif = startGrade(state);
    final int kalan = prototypeOnlyLastGrade - sinif + 1;
    final String metin = 'Açık liseye kaydoldun; $sinif. sınıftan devam '
        'edeceksin. Diploma için $kalan yıl okuyacaksın. '
        'Yıllık ücret ${trMoney(prototypeOnlyYearlyFee)}.';
    return (
      state: _log(
        state.copyWith(
          education: state.education.copyWith(openHighSchoolGrade: sinif),
        ),
        metin,
      ),
      text: metin,
    );
  }

  /// Kaydı bırakmak mümkün mü?
  static InteractionAvailability leaveAvailability(GameState state) {
    if (!state.education.isOpenHighSchoolStudent) {
      return const InteractionAvailability.blocked(
        'Açık lise kaydın yok.',
      );
    }
    return const InteractionAvailability.allowed();
  }

  /// Kaydı bırakır. Ödenen yıllar kayıtta kalır: tekrar kaydolursa
  /// kaldığı sınıftan devam eder.
  static ({GameState state, String text})? leave(GameState state) {
    if (!leaveAvailability(state).isAllowed) return null;
    final int sinif = state.education.openHighSchoolGrade!;
    const String metin = 'Açık lise kaydını bıraktın. Okuduğun sınıflar '
        'kayıtta duruyor; istersen yeniden kaydolabilirsin.';
    return (
      state: _log(
        state.copyWith(
          education: state.education.copyWith(
            grade: sinif,
            openHighSchoolGrade: null,
          ),
        ),
        metin,
      ),
      text: metin,
    );
  }

  /// Yılın açık lise adımı.
  ///
  /// Kayıt yoksa **hiçbir şey yapmaz ve zar tüketmez**. Ücret ödenirse
  /// bir sınıf ilerler; son sınıf tamamlanınca diploma yazılır ve
  /// `JobEducation.lise` isteyen 17 iş açılır. Ücret ödenemezse sınıf
  /// ilerlemez — kayıt düşmez, o yıl boşa gider.
  static ({GameState state, List<String> logLines}) advanceYear(
    GameState state,
  ) {
    final int? sinif = state.education.openHighSchoolGrade;
    if (sinif == null) return (state: state, logLines: const <String>[]);
    // Modül kapandıysa kayıt sessizce donar: ücret çıkmaz, sınıf
    // ilerlemez. Kayıt silinmez; anahtar yeniden açılırsa kaldığı
    // yerden devam eder.
    if (!isOn(state)) return (state: state, logLines: const <String>[]);

    if (state.player.wallet < prototypeOnlyYearlyFee) {
      return (
        state: state,
        logLines: <String>[
          'Açık lise ücretini ödeyemedin; bu yıl $sinif. sınıfta kaldın.',
        ],
      );
    }

    // Statlar `gain` ile artar: azalan getiri kuralı (D-099) burada da
    // geçerli, açık lise zekâyı 100'e yapıştırmaz.
    final GameState odenmis = state.copyWith(
      player: state.player.copyWith(
        wallet: state.player.wallet - prototypeOnlyYearlyFee,
        stats: state.player.stats.gain(
          happiness: prototypeOnlyYearHappiness,
          intelligence: prototypeOnlyYearIntelligence,
        ),
      ),
    );

    if (sinif >= prototypeOnlyLastGrade) {
      return (
        state: odenmis.copyWith(
          player: odenmis.player.copyWith(
            stats: odenmis.player.stats.gain(
              happiness: prototypeOnlyDiplomaHappiness,
            ),
          ),
          // Diploma: `asFinished` açık lise kaydını da kapatır.
          education: odenmis.education.asFinished(),
        ),
        logLines: <String>[
          'Açık liseyi bitirdin; lise diploman artık var. '
          'Yılların gecikmesi kayıtta duruyor, diploma da duruyor.',
        ],
      );
    }

    return (
      state: odenmis.copyWith(
        education: odenmis.education.copyWith(openHighSchoolGrade: sinif + 1),
      ),
      logLines: <String>[
        'Açık lisede $sinif. sınıfı geçtin; '
        '${trMoney(prototypeOnlyYearlyFee)} ödedin.',
      ],
    );
  }

  static GameState _log(GameState state, String text) => state.copyWith(
        log: List<LifeLogEntry>.unmodifiable(<LifeLogEntry>[
          ...state.log,
          LifeLogEntry(
            age: state.player.age,
            text: text,
            category: LogCategory.kisisel,
          ),
        ]),
      );
}

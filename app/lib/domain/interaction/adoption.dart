import 'dart:math';

import '../../data/name_pool.dart';
import '../../text/turkish_text.dart';
import '../generation/child_progression.dart';
import '../models/education.dart';
import '../models/game_state.dart';
import '../models/gender.dart';
import '../models/life_log.dart';
import '../models/person.dart';
import '../models/person_development.dart';
import '../models/relation.dart';
import '../models/stats.dart';
import '../models/wealth.dart';
import '../generation/random_util.dart';
import 'marriage_engine.dart';
import 'parenthood.dart';

/// Evlat edinme başvurusunun sonucu.
class AdoptionResult {
  const AdoptionResult({
    required this.state,
    required this.outcome,
    this.child,
  });

  final GameState state;
  final FamilyOutcome outcome;

  /// Başvuru kabul edildiyse aileye katılan çocuk; aksi hâlde `null`.
  final Person? child;

  bool get adopted => child != null;
}

/// Evlat edinme (D-049).
///
/// Kurallar:
/// - Başvuruda **maddi durum ve hane koşulları** değerlendirilir.
/// - **Yalnızca zengin olmak otomatik kabul anlamına gelmez**; buna karşın
///   çocuğun bakımını karşılayamayacak durumda başvuru **gerekçeli olarak**
///   reddedilir.
/// - **Tek ebeveynli ve farklı aile yapıları** sırf aile yapısı nedeniyle
///   kapatılmaz: evli olmak şart değildir.
/// - Evlat edinilen çocuk **gerçek ve kalıcı bir kişi kaydıdır**; mevcut
///   bir kişi kopyalanmaz, kimliği ve özellikleri sonradan yeniden
///   çizilmez (D-046).
/// - Aynı başvuru **iki kez çocuk veya iki kez ücret** oluşturmaz.
///
/// Ayrıntılı uygunluk koşulları tasarım sorusudur (Q-073) ve burada
/// gerçek hukuk kuralları hakkında bir iddiada bulunulmaz. Bütün sayılar
/// `prototypeOnly`'dir.
class Adoption {
  const Adoption();

  /// prototypeOnly: başvurabilmek için asgari yaş.
  static const int prototypeOnlyMinAge = 21;

  /// prototypeOnly: başvuru ve hazırlık masrafı (₺).
  static const int prototypeOnlyCost = 160000;

  /// prototypeOnly: masraftan sonra çocuğun bakımı için gereken birikim.
  ///
  /// İşi olan başvurucuda bu koşul aranmaz; düzenli geliri olmayan
  /// başvurucunun elinde bir süre yetecek para olması beklenir.
  static const int prototypeOnlyCareReserve = 150000;

  /// prototypeOnly: koşulları sağlayan başvurunun reddedilme ihtimali.
  ///
  /// Zengin olmak otomatik kabul anlamına gelmez.
  static const double prototypeOnlyRejectChance = 0.25;

  /// prototypeOnly: evlat edinilen çocuğun yaş aralığı.
  static const int prototypeOnlyMinChildAge = 2;
  static const int prototypeOnlyMaxChildAge = 12;

  /// prototypeOnly: yeni gelen çocuğun başlangıç yakınlığı.
  static const int prototypeOnlyStartBond = 55;

  /// prototypeOnly: evlat edinmenin mutluluk etkisi.
  static const int prototypeOnlyHappiness = 10;

  /// prototypeOnly: olumsuz sonuçlanan başvurudan sonra beklenecek yıl.
  static const int prototypeOnlyRetryYears = 1;

  /// Başvuru geçmişinin [GameState.proposalAges] içindeki ayrılmış anahtarı.
  static const String attemptKey = 'evlat_edinme_basvurusu';

  /// Başvuruya engel; engel yoksa boş metin.
  String blockReason(GameState state) {
    if (state.player.age < prototypeOnlyMinAge) {
      return '$prototypeOnlyMinAge yaşından itibaren başvurabilirsin.';
    }
    if (state.children.length >= Parenthood.prototypeOnlyMaxChildren) {
      return 'Bu prototipte en fazla '
          '${Parenthood.prototypeOnlyMaxChildren} çocuk olabiliyor.';
    }
    if (state.player.wallet < prototypeOnlyCost) {
      return 'Başvuru ve hazırlık masrafı ${trMoney(prototypeOnlyCost)}; '
          'cüzdanında yeterli para yok.';
    }
    // Aynı yıl içinde başvuru tekrarlanarak sonuç yeniden çekilemez.
    final int? sonBasvuru = state.proposalAges[attemptKey];
    if (sonBasvuru != null &&
        state.player.age - sonBasvuru < prototypeOnlyRetryYears) {
      return 'Bu yıl zaten başvurdun; gelecek yıl yeniden deneyebilirsin.';
    }
    return '';
  }

  /// Başvurunun ekonomik gerekçeyle reddedilip reddedilmediği.
  ///
  /// Aile yapısına (bekâr, evli, boşanmış) bakılmaz; yalnızca çocuğa
  /// bakabilecek koşul aranır.
  String economicRejection(GameState state) {
    final bool duzenliGelir = state.career.isEmployed;
    final int kalan = state.player.wallet - prototypeOnlyCost;
    if (!duzenliGelir && kalan < prototypeOnlyCareReserve) {
      return 'Başvurun, çocuğun bakımını karşılayacak düzenli gelir veya '
          'birikim görülmediği için olumsuz sonuçlandı.';
    }
    return '';
  }

  /// Evlat edinme başvurusu yapar.
  ///
  /// Ücret yalnızca **başvuru kabul edildiğinde bir kez** düşer; olumsuz
  /// sonuçlanan başvuruda cüzdana dokunulmaz.
  AdoptionResult apply(GameState state, Random rng) {
    final String engel = blockReason(state);
    if (engel.isNotEmpty) {
      return AdoptionResult(
        state: state,
        outcome: FamilyOutcome(applied: false, text: engel),
      );
    }

    // Başvuru yapıldı: sonuç ne olursa olsun kayda girer.
    final GameState basvurulmus = state.copyWith(
      proposalAges: Map<String, int>.unmodifiable(<String, int>{
        ...state.proposalAges,
        attemptKey: state.player.age,
      }),
    );

    final String ekonomik = economicRejection(state);
    if (ekonomik.isNotEmpty) {
      return AdoptionResult(
        state: _log(basvurulmus, ekonomik),
        outcome: FamilyOutcome(applied: true, text: ekonomik),
      );
    }

    if (rng.chance(prototypeOnlyRejectChance)) {
      const String metin = 'Başvurun bu dönem olumlu sonuçlanmadı. '
          'Gelecek yıl yeniden başvurabilirsin.';
      return AdoptionResult(
        state: _log(basvurulmus, metin),
        outcome: const FamilyOutcome(applied: true, text: metin),
      );
    }

    final Person cocuk = _newChild(state, rng);
    final String metin = '${cocuk.firstName} artık ailenin bir parçası. '
        'Başvuru ve hazırlık masrafı ${trMoney(prototypeOnlyCost)} tuttu.';

    final GameState next = basvurulmus.copyWith(
      people: List<Person>.unmodifiable(<Person>[...state.people, cocuk]),
      player: state.player.copyWith(
        wallet: state.player.wallet - prototypeOnlyCost,
        stats: state.player.stats.gain(
          happiness: prototypeOnlyHappiness,
        ),
      ),
    );

    return AdoptionResult(
      state: _log(next, metin),
      outcome: FamilyOutcome(applied: true, text: metin),
      child: cocuk,
    );
  }

  /// Evlat edinilen çocuğun **kendi** kaydını oluşturur.
  ///
  /// Kimliği ve özellikleri kendisine aittir: ebeveynlerden özellik
  /// aktarımı uygulanmaz (D-046). Soyadı ailenin soyadı olur; geçmişi
  /// uydurulmaz, kayda yalnızca aileye katıldığı yıl yazılır.
  Person _newChild(GameState state, Random rng) {
    final Gender gender = rng.nextBool() ? Gender.kadin : Gender.erkek;
    final Set<String> kullanilan = <String>{
      state.player.firstName,
      for (final Person p in state.people) p.firstName,
    };
    final List<String> havuz =
        gender == Gender.kadin ? kadinIsimleri : erkekIsimleri;
    final List<String> bos = havuz
        .where((String a) => !kullanilan.contains(a))
        .toList(growable: false);
    final String isim = rng.pick(bos.isEmpty ? havuz : bos);

    final int age = rng.between(
      prototypeOnlyMinChildAge,
      prototypeOnlyMaxChildAge,
    );
    final int? sinif = age >= ChildProgression.prototypeOnlySchoolStartAge
        ? (age - ChildProgression.prototypeOnlySchoolStartAge + 1).clamp(1, 12)
        : null;

    return Person(
      id: Parenthood.nextChildId(state),
      firstName: isim,
      lastName: state.player.lastName,
      gender: gender,
      relation: RelationType.cocuk,
      age: age,
      isAlive: true,
      inPlayerHousehold: true,
      employment: sinif == null
          ? EmploymentStatus.cocuk
          : EmploymentStatus.ogrenci,
      wealth: null,
      bond: prototypeOnlyStartBond,
      city: state.player.currentCity,
      schoolLevel: sinif == null ? null : SchoolLevel.forGrade(sinif),
      development: PersonDevelopment(
        // Hayatı bundan sonra izlenir (D-045).
        tracksLife: true,
        // Kayıt doğru anlatılsın diye işaretlenir; bu çocuk her bakımdan
        // çocuktur (D-049).
        adopted: true,
        // Kendi özellikleri: evlat edinme sırasında yeniden çizilmez.
        stats: Stats(
          appearance: rng.between(25, 85),
          happiness: rng.between(45, 85),
          health: rng.between(40, 90),
          intelligence: rng.between(25, 85),
          charisma: rng.between(25, 85),
        ),
        grade: sinif,
        schoolLevel: sinif == null ? null : SchoolLevel.forGrade(sinif),
        milestones: <LifeMilestone>[
          LifeMilestone(age: age, text: '$isim yeni ailesine katıldı.'),
        ],
      ),
    );
  }

  GameState _log(GameState state, String text) => state.copyWith(
        log: List<LifeLogEntry>.unmodifiable(<LifeLogEntry>[
          ...state.log,
          LifeLogEntry(
            age: state.player.age,
            text: text,
            category: LogCategory.aile,
          ),
        ]),
      );
}

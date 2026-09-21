import 'dart:math';

import '../../data/item_catalog.dart';
import '../life/inheritance.dart';
import '../life/mortality.dart';
import '../models/education.dart';
import '../models/game_settings.dart';
import '../models/game_state.dart';
import '../models/gender.dart';
import '../models/life_log.dart';
import '../models/marriage.dart';
import '../models/career.dart';
import '../models/owned_item.dart';
import '../models/person_development.dart';
import '../models/parental_status.dart';
import '../models/person.dart';
import '../models/player_character.dart';
import '../models/relation.dart';
import '../models/stats.dart';
import '../models/wealth.dart';
import 'life_progression.dart';
import 'random_util.dart';
import '../../text/turkish_text.dart';

/// Kuşak devamı: **"Çocuğum olarak devam et"** (Paket E3,
/// `docs/GENERATION_PROPOSAL.md` §5).
///
/// Kurallar:
/// - Seçenek yalnızca oyuncu vefat ettiğinde ve **hayatta bir çocuğu
///   varsa** açılır; çocuk yoksa hiçbir yerde gösterilmez (sahte düğme
///   olmaz, D-038).
/// - Tamamlanan hayat **Geçmiş Hayatlar arşivine** yazılır (D-037).
/// - Yeni oyuncu, seçilen çocuğun **aynı kaydıdır**: adı, yaşı, cinsiyeti
///   ve aile bağları korunur. Paralel bir "yeni karakter" üretilmez.
/// - Eski oyuncu kayıtta **vefat etmiş ebeveyn** olarak kalır.
/// - Miras D-037 kurallarıyla dağıtılır; çocuğa kalan ev/araç **kalıcı
///   varlık kimliğiyle** (aynı `OwnedItem.id`) geçer ve aynı miras iki kez
///   dağıtılmaz.
/// - Ün, meslek ve eğitim **taşınmaz**; yeni kuşak kendi hayatını yaşar.
///
/// Bu paketteki bütün sayısal değerler ve "dünyanın ne kadarı taşınır"
/// ayrıntısı `prototypeOnly`'dir ve karar bekler
/// (`docs/DESIGN_REVIEW_QUEUE.md`, Q-067).
abstract final class GenerationContinuation {
  /// prototypeOnly: yetişkin sayılma yaşı (mevcut hane kuralıyla aynı).
  static const int prototypeOnlyAdultAge = 18;

  /// prototypeOnly: taşınan kişilerin yakınlığı bu değere doğru çekilir.
  ///
  /// Eski oyuncunun yakınlık puanı yeni kuşağın puanı değildir; kayıt
  /// silinmeden, nötr bir aile yakınlığına yaklaştırılır.
  static const int prototypeOnlyNeutralBond = 55;

  /// prototypeOnly: 18 yaşını doldurmuş çocuk lise mezunu sayılır.
  ///
  /// Çocuk NPC'lerinin kendi eğitim geçmişi tutulmuyor; devam eden oyuncu
  /// boşlukta kalmasın diye yaşına uygun bir eğitim durumu kurulur.
  static const int prototypeOnlyGraduationAge = 18;

  /// Devam edilebilecek çocuklar.
  ///
  /// Hayat tamamlanmadıysa veya hayatta çocuk yoksa liste **boştur**;
  /// arayüz de o zaman hiçbir seçenek göstermez.
  static List<Person> heirs(GameState state) =>
      state.deceased ? state.livingChildren : const <Person>[];

  static bool canContinue(GameState state) => heirs(state).isNotEmpty;

  /// Devam etmeye engel; engel yoksa boş metin.
  static String blockReason(GameState state, String childId) {
    if (!state.deceased) {
      return 'Kuşak devamı ancak bir hayat tamamlandığında açılır.';
    }
    final Person? cocuk = state.personById(childId);
    if (cocuk == null) return 'Böyle bir kayıt bulunamadı.';
    if (cocuk.relation != RelationType.cocuk) {
      return '${cocuk.firstName} senin çocuğun değil.';
    }
    if (!cocuk.isAlive) {
      return '${cocuk.firstName} hayatta değil.';
    }
    return '';
  }

  /// Seçilen çocuğun hayatıyla devam eden yeni durumu üretir.
  ///
  /// Engel varsa `state` `null` döner ve **hiçbir şey değişmez**; çağıran
  /// gerekçeyi oyuncuya gösterir.
  static ({GameState? state, String blockReason}) continueAs(
    GameState state,
    String childId,
    Random rng,
  ) {
    final String engel = blockReason(state, childId);
    if (engel.isNotEmpty) return (state: null, blockReason: engel);

    final Person cocuk = state.personById(childId)!;
    final PlayerCharacter eskiOyuncu = state.player;
    final int olumYasi = state.deathAge ?? eskiOyuncu.age;
    // Eski oyuncu, yeni oyuncunun annesi mi babası mı?
    final bool anneTarafi = eskiOyuncu.gender == Gender.kadin;
    final String ebeveynId = _parentId(state);

    // --- Miras -----------------------------------------------------------
    final List<Person> mirascilar = _heirOrder(state);
    final Person? sagKalanEs = _survivingSpouse(state);
    // Borç miras kalmaz: eksi bakiye yeni kuşağa geçmez (prototypeOnly).
    final int nakit = eskiOyuncu.wallet > 0 ? eskiOyuncu.wallet : 0;
    final int cocukSayisi = state.livingChildren.length;
    final int esPayi = sagKalanEs == null
        ? 0
        : (nakit * Inheritance.prototypeOnlySpouseShare).round();
    final int cocukPayi = ((nakit - esPayi) / cocukSayisi).floor();

    // Eşyalar bölünmez: sırayla mirasçılara dağıtılır. Çocuğa düşenler
    // **aynı kimlikle** geçer; başkasına düşenler o kişinin mal varlığına
    // yazılır, yani oyundan kaybolmaz.
    final List<OwnedItem> cocugaKalan = <OwnedItem>[];
    final Map<String, List<String>> baskasinaKalan = <String, List<String>>{};
    for (int i = 0; i < state.items.length; i++) {
      final OwnedItem esya = state.items[i];
      final Person alan = mirascilar[i % mirascilar.length];
      if (alan.id == childId) {
        cocugaKalan.add(
          OwnedItem(
            id: esya.id,
            typeId: esya.typeId,
            acquiredAtAge: cocuk.age,
            source: ItemSource.miras,
            fromPersonId: ebeveynId,
            condition: esya.condition,
            attachments: esya.attachments,
            purchasePrice: esya.purchasePrice,
            location: esya.location,
            rentedOut: esya.rentedOut,
          ),
        );
      } else {
        (baskasinaKalan[alan.id] ??= <String>[]).add(esya.typeId);
      }
    }

    // --- Kişiler ---------------------------------------------------------
    final List<Person> yeniKisiler = <Person>[];
    for (final Person kisi in state.people) {
      if (kisi.id == childId) continue; // artık oyuncunun kendisi
      final RelationType? yeniBag = _relationForNextGeneration(
        person: kisi,
        marriage: state.marriage,
        motherLine: anneTarafi,
      );
      if (yeniBag == null) continue; // yeni kuşakta bağı yok
      yeniKisiler.add(
        kisi.copyWith(
          relation: yeniBag,
          bond: _carriedBond(kisi.bond),
          inPlayerHousehold: kisi.isAlive && kisi.inPlayerHousehold,
          estate: <String>[...kisi.estate, ...?baskasinaKalan[kisi.id]],
          // Okul bağları eski oyuncuya aitti; yeni kuşağa taşınmaz.
          schoolTie: null,
          schoolLevel: null,
          schoolId: null,
          classId: null,
        ),
      );
    }

    // Eski oyuncu kayıtta kalır: vefat etmiş ebeveyn.
    final bool calisiyordu = state.career.isEmployed;
    final Person ebeveyn = Person(
      id: ebeveynId,
      firstName: eskiOyuncu.firstName,
      lastName: eskiOyuncu.lastName,
      gender: eskiOyuncu.gender,
      relation: anneTarafi ? RelationType.anne : RelationType.baba,
      age: olumYasi,
      isAlive: false,
      inPlayerHousehold: false,
      employment: calisiyordu
          ? EmploymentStatus.calisiyor
          : (olumYasi >= 65 ? EmploymentStatus.emekli : EmploymentStatus.issiz),
      occupation: calisiyordu ? state.career.label : null,
      // Mal varlığı bu ekranda dağıtıldı; uydurma bir değer bırakılmaz.
      wealth: null,
      bond: cocuk.bond,
      city: eskiOyuncu.currentCity,
    );
    yeniKisiler.insert(0, ebeveyn);

    // --- Yeni oyuncu -----------------------------------------------------
    final String sehir = cocuk.city ?? eskiOyuncu.currentCity;
    final int kayipAcisi = Mortality.prototypeOnlyHappinessLoss(ebeveyn);
    // Çocuğun kendi hayatı (D-045): özellikleri, eğitimi, işi ve birikimi
    // arka planda gerçekten yaşandı; kuşak geçişinde sıfırlanmaz.
    final PersonDevelopment? gelisim = cocuk.development;
    final Stats kendiOzellikleri = gelisim?.stats ??
        Stats(
          // Eski kayıtlardan gelen, gelişim kaydı olmayan çocuk için
          // nötr aralık kullanılır; uydurma geçmiş yazılmaz.
          appearance: rng.between(25, 85),
          happiness: rng.between(45, 85),
          health: rng.between(40, 90),
          intelligence: rng.between(25, 85),
          charisma: rng.between(25, 85),
        );
    final PlayerCharacter yeniOyuncu = PlayerCharacter(
      id: 'oyuncu',
      firstName: cocuk.firstName,
      lastName: cocuk.lastName,
      gender: cocuk.gender,
      age: cocuk.age,
      birthCity: sehir,
      currentCity: _currentCity(state, cocuk),
      // Çocuğun kendi özellikleri korunur; yalnızca kaybın acısı işlenir.
      stats: kendiOzellikleri.copyWith(
        happiness: kendiOzellikleri.happiness - kayipAcisi,
      ),
      // Ün taşınmaz (D-027: baştan kapalıdır).
      fame: null,
      // Kendi birikimi + mirastan payına düşen. İki kalem ayrı kaynaktır,
      // aynı para iki kez üretilmez.
      wallet: (gelisim?.money ?? 0) + cocukPayi,
    );

    // --- Hane ve konut ---------------------------------------------------
    final bool haneYetiskini = yeniKisiler.any((Person p) =>
        p.isAlive && p.inPlayerHousehold && p.age >= prototypeOnlyAdultAge);
    OwnedItem? oturulanKonut;
    if (!haneYetiskini && cocuk.age >= prototypeOnlyAdultAge) {
      for (final OwnedItem esya in cocugaKalan) {
        if (itemTypeOrFallback(esya.typeId).kind == ItemKind.konut &&
            !esya.rentedOut) {
          oturulanKonut = esya;
          break;
        }
      }
    }

    // --- Günlük ----------------------------------------------------------
    final String ebeveynEtiketi = anneTarafi ? 'Annen' : 'Baban';
    final List<LifeLogEntry> gunluk = <LifeLogEntry>[
      // Çocuğun arka planda gerçekten yaşadıkları yeni hayatın geçmişidir;
      // yaşandıkları yaşla birlikte günlüğe girer.
      for (final LifeMilestone an in gelisim?.milestones ?? const <LifeMilestone>[])
        LifeLogEntry(
          age: an.age,
          text: an.text,
          category: LogCategory.kisisel,
        ),
      LifeLogEntry(
        age: cocuk.age,
        text: '$ebeveynEtiketi ${ebeveyn.fullName} $olumYasi yaşında '
            'hayatını kaybetti. Hayat artık senin ellerinde.',
        category: LogCategory.aile,
      ),
    ];
    if (cocukPayi > 0) {
      gunluk.add(
        LifeLogEntry(
          age: cocuk.age,
          text: '$ebeveynEtiketi ${ebeveyn.fullName} mirasından payına '
              '${trMoney(cocukPayi)} düştü.',
          category: LogCategory.aile,
        ),
      );
    }
    for (final OwnedItem esya in cocugaKalan) {
      gunluk.add(
        LifeLogEntry(
          age: cocuk.age,
          text: '${itemTypeOrFallback(esya.typeId).name} sana miras kaldı.',
          category: LogCategory.kisisel,
        ),
      );
    }

    // --- Durum -----------------------------------------------------------
    GameState yeni = GameState(
      seed: state.seed,
      player: yeniOyuncu,
      people: List<Person>.unmodifiable(yeniKisiler),
      // Evcil hayvanların yaşı tutulmuyor; kuşaklar arası taşımak ölümsüz
      // hayvan üretirdi (Q-067).
      pets: const <Pet>[],
      parentalStatus: state.marriage?.status == MarriageStatus.bosandi
          ? ParentalStatus.bosanmis
          : ParentalStatus.evli,
      log: List<LifeLogEntry>.unmodifiable(gunluk),
      items: List<OwnedItem>.unmodifiable(cocugaKalan),
      education: _educationFor(gelisim, cocuk.age),
      // Çocuğun kendi işi korunur; eski oyuncunun mesleği kopyalanmaz.
      career: _careerFor(gelisim, cocuk),
      // Eski kuşakta dağıtılmış mirasların ikinci kez dağıtılmaması için
      // işaretler taşınır; eski oyuncunun mirası da burada kapanır. Yeni
      // kayıtta bulunmayan kişilerin işareti taşınmaz (kayıt şişmesin).
      settledEstates: Set<String>.unmodifiable(<String>{
        for (final String id in state.settledEstates)
          if (yeniKisiler.any((Person p) => p.id == id)) id,
        ebeveynId,
      }),
      pastLives: state.pastLives,
      careStatus: CareStatus.aileYaninda,
      grief: kayipAcisi,
      // Oyuncunun kendi ayarları hayata değil oyuncuya aittir.
      settings: state.settings,
      residenceItemId: oturulanKonut?.id,
      movedOut: oturulanKonut != null ||
          (!haneYetiskini && cocuk.age >= prototypeOnlyAdultAge),
      generation: state.generation + 1,
    );

    // Küçük yaşta devam eden çocuk açıklamasız bir hanede bırakılmaz.
    yeni = LifeProgression.ensureCaregiver(yeni, cocuk.age);

    return (state: yeni, blockReason: '');
  }

  // --------------------------------------------------------------------
  // Yardımcılar
  // --------------------------------------------------------------------

  /// Mirasçı sırası: sağ kalan eş ve hayattaki çocuklar (D-037).
  static List<Person> _heirOrder(GameState state) {
    final Person? es = _survivingSpouse(state);
    return <Person>[
      if (es != null) es,
      ...state.livingChildren,
    ];
  }

  /// Mirasçı sayılan sağ kalan eş; boşanılmışsa mirasçı değildir (D-037).
  static Person? _survivingSpouse(GameState state) {
    final Marriage? kayit = state.marriage;
    if (kayit == null || kayit.status == MarriageStatus.bosandi) return null;
    final Person? es = state.spouse;
    if (es == null || !es.isAlive) return null;
    return es;
  }

  /// Eski oyuncunun yeni kayıttaki kimliği; kimseyle çakışmaz.
  static String _parentId(GameState state) {
    final Set<String> mevcut = <String>{for (final Person p in state.people) p.id};
    String id = 'kusak${state.generation}-ebeveyn';
    int n = 2;
    while (mevcut.contains(id)) {
      id = 'kusak${state.generation}-ebeveyn-$n';
      n++;
    }
    return id;
  }

  /// Bir kişinin yeni kuşaktaki bağı; bağı yoksa `null`.
  ///
  /// Eski oyuncunun arkadaşları, öğretmenleri ve romantik geçmişi yeni
  /// kuşağa taşınmaz: o hayat **arşivde** durur, kayıt şişmez.
  static RelationType? _relationForNextGeneration({
    required Person person,
    required Marriage? marriage,
    required bool motherLine,
  }) {
    // Evlilik kaydındaki eş, çocuğun diğer ebeveynidir (boşanmış olsa da).
    if (marriage != null && person.id == marriage.spouseId) {
      return person.gender == Gender.kadin
          ? RelationType.anne
          : RelationType.baba;
    }
    switch (person.relation) {
      case RelationType.cocuk:
        return RelationType.kardes;
      case RelationType.es:
      case RelationType.eskiEs:
        return person.gender == Gender.kadin
            ? RelationType.anne
            : RelationType.baba;
      case RelationType.anne:
        return motherLine ? RelationType.anneanne : RelationType.babaanne;
      case RelationType.baba:
        return motherLine
            ? RelationType.anneTarafiDede
            : RelationType.babaTarafiDede;
      case RelationType.kardes:
        if (motherLine) {
          return person.gender == Gender.kadin
              ? RelationType.teyze
              : RelationType.dayi;
        }
        return person.gender == Gender.kadin
            ? RelationType.hala
            : RelationType.amca;
      default:
        return null;
    }
  }

  /// Taşınan yakınlık: kayıt silinmez, nötre doğru çekilir (prototypeOnly).
  static int _carriedBond(int bond) =>
      ((bond + prototypeOnlyNeutralBond) / 2).round().clamp(0, 100);

  /// Devam eden çocuğun yaşadığı şehir.
  static String _currentCity(GameState state, Person cocuk) {
    if (cocuk.inPlayerHousehold) return state.player.currentCity;
    return cocuk.city ?? state.player.currentCity;
  }

  /// Çocuğun kendi eğitim geçmişinden oyuncunun eğitim kaydını kurar.
  ///
  /// Gelişim kaydı yoksa (eski kayıtlar) yaşa uygun güvenli bir durum
  /// kullanılır.
  static EducationState _educationFor(PersonDevelopment? dev, int age) {
    if (dev == null) return _educationForAge(age);
    if (dev.grade != null) {
      return EducationState(
        enrolled: true,
        grade: dev.grade,
        startedAtAge: 6,
      );
    }
    switch (dev.university) {
      case UniversityStatus.okuyor:
        return EducationState(
          finished: true,
          startedAtAge: 6,
          universityProgramId: dev.universityProgramId,
          universityYear: dev.universityYear ?? 1,
        );
      case UniversityStatus.bitirdi:
        return EducationState(
          finished: true,
          startedAtAge: 6,
          universityProgramId: dev.universityProgramId,
          universityFinished: true,
        );
      case UniversityStatus.birakti:
      case null:
        break;
    }
    if (dev.finishedSchool) {
      return const EducationState(finished: true, startedAtAge: 6);
    }
    return _educationForAge(age);
  }

  /// Çocuğun kendi işinden oyuncunun meslek kaydını kurar.
  static CareerState _careerFor(PersonDevelopment? dev, Person cocuk) {
    if (dev == null || dev.jobId == null) {
      return CareerState(
        pastJobIds: List<String>.unmodifiable(dev?.pastJobIds ?? const <String>[]),
      );
    }
    return CareerState(
      jobId: dev.jobId,
      startedAtAge: dev.jobStartedAtAge,
      // Maaş bu yıl için zaten NPC birikiminde sayıldı; aynı yıl ikinci kez
      // ödenmez.
      lastPaidAge: cocuk.age,
      pastJobIds: List<String>.unmodifiable(dev.pastJobIds),
      jobCity: cocuk.city,
    );
  }

  /// Yaşa uygun eğitim durumu (prototypeOnly, Q-067).
  ///
  /// Çocuk NPC'lerinde sınav, alan ve not geçmişi tutulmaz; devam eden
  /// oyuncu için yalnızca tutarlı bir başlangıç kurulur.
  static EducationState _educationForAge(int age) {
    if (age < 6) return const EducationState.notStarted();
    if (age < prototypeOnlyGraduationAge) {
      return EducationState(
        enrolled: true,
        grade: (age - 5).clamp(1, 12),
        startedAtAge: 6,
      );
    }
    return const EducationState(
      enrolled: false,
      finished: true,
      startedAtAge: 6,
    );
  }
}

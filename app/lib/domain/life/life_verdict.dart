/// Hayat sonu değerlendirmesi: "nasıl bir hayattı?"
library;

import '../models/book_progress.dart';
import '../models/career.dart';
import '../models/game_state.dart';
import '../models/gender.dart';
import '../../data/martial_arts_catalog.dart';
import '../../data/military_catalog.dart';
import '../models/marriage.dart';
import '../models/hobby_progress.dart';
import '../hobby/hobby_tracker.dart';
import '../../data/hobby_catalog.dart';
import '../models/martial_progress.dart';
import '../models/military.dart';
import '../models/owned_item.dart';
import '../models/person.dart';
import '../models/relation.dart';
import '../models/trip.dart';

/// Değerlendirmenin bir ekseni (Bağlar, Emek, Deneyim, Huzur).
class VerdictAxis {
  const VerdictAxis({
    required this.id,
    required this.label,
    required this.value,
    required this.note,
  });

  final String id;
  final String label;

  /// 0-100 arası. **Puan değil, ayna:** oyuncu kazanmaz veya kaybetmez;
  /// hayatın hangi yöne ağır bastığını anlatır.
  final int value;

  /// Bu eksenin kısa açıklaması; sayıdan değil, hayatın kendisinden
  /// üretilir ("üç kişi seni yakından tanıdı" gibi).
  final String note;
}

/// Hayat özetinin üstünde gösterilen değerlendirme.
class LifeVerdict {
  const LifeVerdict({
    required this.title,
    required this.sentence,
    required this.axes,
    required this.firsts,
    required this.never,
    required this.closing,
    required this.dominantAxisId,
  });

  /// Hayatın kısa adı: "Kalabalık bir hayat" gibi.
  final String title;

  /// Bir-iki cümlelik değerlendirme.
  final String sentence;

  final List<VerdictAxis> axes;

  /// "İlkler": hayatta bir kez olan, yaşı bilinen anlar. Yaşa göre sıralı.
  final List<VerdictFirst> firsts;

  /// "Hiç olmadı": yaşanmamış şeyler. Suçlama değil, hayatın şekli.
  final List<String> never;

  /// Kapanış cümlesi.
  final String closing;

  /// Hayata adını veren eksenin kimliği.
  ///
  /// En yüksek puanlı eksen **olmayabilir**: huzur bir ruh hâlini
  /// anlatır, somut eksenlerin belirgin biçimde önünde değilse hayata
  /// adını vermez.
  final String dominantAxisId;

  /// Ekranda en öne çıkacak eksen. Başlığı veren eksenle aynıdır.
  VerdictAxis get strongest =>
      axes.firstWhere((VerdictAxis a) => a.id == dominantAxisId);

  /// En zayıf eksen.
  VerdictAxis get weakest =>
      axes.reduce((VerdictAxis a, VerdictAxis b) => b.value < a.value ? b : a);
}

/// "İlkler" listesinin bir satırı.
class VerdictFirst {
  const VerdictFirst({required this.age, required this.text});

  final int age;
  final String text;
}

/// Hayatın sonunda bir değerlendirme üretir.
///
/// **Hiçbir sayı uydurulmaz:** her eksen yalnızca kayıtta gerçekten
/// olan şeylerden hesaplanır. Yaşı bilinmeyen bir an "ilkler" listesine
/// girmez; olmamış bir şey olmuş gibi yazılmaz.
///
/// Eşikler ve ağırlıklar `prototypeOnly`'dir: Faho onaylamadan kalıcı
/// oyun kuralı sayılmaz (`docs/DESIGN_REVIEW_QUEUE.md`, Q-090).
abstract final class LifeVerdictBuilder {
  /// Bir eksenin "dolu" sayıldığı eşik.
  static const int prototypeOnlyStrongThreshold = 65;

  /// Bir eksenin "boş" sayıldığı eşik.
  static const int prototypeOnlyWeakThreshold = 30;

  static LifeVerdict build(GameState state) {
    final int olumYasi = state.deathAge ?? state.player.age;
    final VerdictAxis baglar = _baglar(state, olumYasi);
    final VerdictAxis emek = _emek(state, olumYasi);
    final VerdictAxis deneyim = _deneyim(state);
    final VerdictAxis huzur = _huzur(state);
    final List<VerdictAxis> eksenler = <VerdictAxis>[
      baglar,
      emek,
      deneyim,
      huzur,
    ];

    final List<VerdictFirst> ilkler = _ilkler(state, olumYasi);
    final List<String> hicler = _hicler(state);

    final VerdictAxis en = _baskin(eksenler);
    final VerdictAxis az = eksenler
        .reduce((VerdictAxis a, VerdictAxis b) => b.value < a.value ? b : a);

    return LifeVerdict(
      title: _baslik(en, az, olumYasi, state),
      sentence: _cumle(state, olumYasi, en, az),
      axes: eksenler,
      firsts: ilkler,
      never: hicler,
      closing: _kapanis(state, olumYasi, ilkler, hicler),
      dominantAxisId: en.id,
    );
  }

  // -----------------------------------------------------------------
  // Eksenler
  // -----------------------------------------------------------------

  /// Bağlar: kaç kişi hayatında kaldı ve ne kadar yakındı.
  static VerdictAxis _baglar(GameState state, int olumYasi) {
    final List<Person> yakinlar = state.people
        .where((Person p) =>
            p.relation != RelationType.sinifArkadasi &&
            p.relation != RelationType.ogretmen &&
            p.bond > 0)
        .toList(growable: false);
    final int guclu = yakinlar.where((Person p) => p.bond >= 60).length;
    final int orta = yakinlar.where((Person p) => p.bond >= 30).length;

    int puan = 0;
    puan += (guclu * 16).clamp(0, 48);
    puan += (orta * 4).clamp(0, 16);
    if (state.isMarried) puan += 14;
    if (state.marriage?.status == MarriageStatus.bosandi) puan += 5;
    puan += (state.children.length * 6).clamp(0, 18);
    if (state.people.any((Person p) => p.relation == RelationType.arkadas)) {
      puan += 8;
    }

    final String not;
    if (guclu == 0 && orta == 0) {
      not = 'Kimse çok yakınına girmedi.';
    } else if (guclu == 0) {
      not = '$orta kişi hayatında kaldı ama arası hep bir adım uzaktı.';
    } else {
      not = '$guclu kişi seni yakından tanıdı.';
    }
    return VerdictAxis(
      id: 'baglar',
      label: 'Bağlar',
      value: puan.clamp(0, 100),
      note: not,
    );
  }

  /// Emek: okul, iş ve biriktirilen.
  static VerdictAxis _emek(GameState state, int olumYasi) {
    int puan = 0;
    if (state.education.finished || state.education.isStudent) puan += 8;
    if (state.education.program != null) puan += 14;

    final List<JobHistoryEntry> gecmis = state.career.history;
    final int calisilanYil = gecmis.fold<int>(0, (int t, JobHistoryEntry e) {
      final int bitis = e.endedAtAge ?? olumYasi;
      return t + (bitis - e.startedAtAge).clamp(0, 80);
    });
    // Ölçümde 38 yıl çalışıp emekli olmuş bir hayat, yalnızca keyfi
    // yerinde olduğu için "kendi hâlinde" sayılıyordu; çalışılan yılın
    // ağırlığı artırıldı.
    puan += (calisilanYil ~/ 2).clamp(0, 34);
    puan += (state.career.level * 5).clamp(0, 18);
    if (state.career.isRetired) puan += 10;
    if (state.player.wallet >= 250000) {
      puan += 16;
    } else if (state.player.wallet >= 50000) {
      puan += 8;
    } else if (state.player.wallet > 0) {
      puan += 3;
    }
    if (state.career.milestones.isNotEmpty) puan += 6;

    // Askerlik de emektir (Paket 37). Paket 29-31'den beri hizmet
    // veriliyordu ama değerlendirme bunu hiç görmüyordu: terhis olmuş
    // bir binbaşı ile hiç askere gitmemiş biri aynı sayılıyordu.
    puan += _askerlikPuani(state);

    final String not;
    if (gecmis.isEmpty && state.military.status == MilitaryStatus.tamamlandi) {
      not = 'Hiçbir işte çalışmadın ama askerliğini tamamladın.';
    } else if (gecmis.isEmpty) {
      not = 'Hiç bir işte çalışmadın.';
    } else if (gecmis.length == 1) {
      not = 'Tek bir işte $calisilanYil yıl geçirdin.';
    } else {
      not = '${gecmis.length} işte toplam $calisilanYil yıl çalıştın.';
    }
    return VerdictAxis(
      id: 'emek',
      label: 'Emek',
      value: puan.clamp(0, 100),
      note: not,
    );
  }

  /// Deneyim: gezdiğin yerler, okuduğun kitaplar, edindiğin şeyler.
  static VerdictAxis _deneyim(GameState state) {
    final Set<String> sehirler = <String>{
      for (final TripRecord t in state.trips) t.city,
    };
    final int bitenKitap =
        state.books.where((BookProgress b) => b.finished).length;
    final int farkliOlay = state.eventSeenCounts.length;

    int puan = 0;
    puan += (sehirler.length * 7).clamp(0, 28);
    puan += (bitenKitap * 6).clamp(0, 24);
    puan += (state.licenses.length * 6).clamp(0, 12);
    puan += (state.items.length * 2).clamp(0, 12);
    puan += (farkliOlay ~/ 4).clamp(0, 18);
    if (state.player.currentCity != state.player.birthCity) puan += 6;

    // Yıllarca salona gidip kuşak yükseltmek de bir deneyimdir
    // (Paket 37). Paket 32'den beri bu emek hiçbir yere yazılmıyordu.
    final int dovus = _dovusPuani(state);
    puan += dovus;

    // Yıllarca sürdürülen hobi (Paket 39): kaç yıl sürdüğü ve nereye
    // kadar gidildiği sayılır. Bir kez denemek sayılmaz.
    puan += _hobiPuani(state);

    final HobbyProgress? anaHobi = HobbyTracker.mainHobby(state);
    final MartialProgress? enIyi = _enIleriDal(state);
    final String not;
    if (anaHobi != null && anaHobi.isSerious && anaHobi.hobby != null) {
      not = '${anaHobi.hobby!.label} ile ${anaHobi.years} yıl uğraştın '
          '(${anaHobi.stageLabel}).';
    } else if (enIyi != null &&
        enIyi.level >= (enIyi.art?.instructorFromLevel ?? 99)) {
      not = '${enIyi.art!.label} yolunda "${enIyi.rankName}" basamağına '
          'çıktın.';
    } else if (sehirler.isEmpty && bitenKitap == 0 && dovus == 0) {
      not = 'Hayatın hep aynı sokaklarda geçti.';
    } else if (sehirler.isEmpty) {
      not = 'Hiç şehir dışına çıkmadın ama $bitenKitap kitap bitirdin.';
    } else {
      not = '${sehirler.length} şehir gördün.';
    }
    return VerdictAxis(
      id: 'deneyim',
      label: 'Deneyim',
      value: puan.clamp(0, 100),
      note: not,
    );
  }

  /// Huzur: son yıllardaki mutluluk, sağlık ve taşınan yük.
  static VerdictAxis _huzur(GameState state) {
    // **Sabit taban yok.** Önce her hayata 25 puan ekleniyordu; bu,
    // huzuru diğer eksenlerin önüne geçirip dolu dolu geçmiş hayatlara
    // "kendi hâlinde" dedirtiyordu.
    int puan = 0;
    puan += (state.player.stats.happiness * 62) ~/ 100;
    puan += (state.player.stats.health * 38) ~/ 100;
    puan -= (state.hardshipYears * 4).clamp(0, 20);
    puan -= (state.grief ~/ 6).clamp(0, 15);

    final String not;
    if (state.hardshipYears >= 5) {
      not = 'Hayatın ${state.hardshipYears} yılı sıkıntıyla geçti.';
    } else if (state.player.stats.happiness >= 70) {
      not = 'Sonuna kadar keyfin yerindeydi.';
    } else if (state.player.stats.happiness <= 35) {
      not = 'Son yılların ağır geçti.';
    } else {
      not = 'İyi günler de vardı, zor günler de.';
    }
    return VerdictAxis(
      id: 'huzur',
      label: 'Huzur',
      value: puan.clamp(0, 100),
      note: not,
    );
  }

  // -----------------------------------------------------------------
  // İlkler ve hiç olmayanlar
  // -----------------------------------------------------------------

  /// prototypeOnly: askerliğin Emek eksenine katkısı.
  ///
  /// Yalnızca **gerçekten olmuş** durumlar sayılır: tamamlanan hizmet ve
  /// ulaşılan rütbe. Bedelli ödemek hizmet sayılmaz; kaçmak hiç sayılmaz.
  static int _askerlikPuani(GameState state) {
    final MilitaryState a = state.military;
    if (a.status != MilitaryStatus.tamamlandi) return 0;

    int puan = 8;
    final int? bas = a.startedAtAge;
    final int? bitis = a.finishedAtAge;
    if (bas != null && bitis != null && bitis > bas) {
      puan += ((bitis - bas) * 2).clamp(0, 10);
    }
    // Rütbeli yollar uzun ve maaşlıdır; karşılığı da büyüktür.
    final MilitaryTrack? yol = a.track;
    if (yol != null && yol != MilitaryTrack.er) puan += 8;
    return puan;
  }

  /// prototypeOnly: dövüş sanatlarının Deneyim eksenine katkısı.
  ///
  /// Basamak sayısı değil, **ne kadar yükselindiği** sayılır: her dalın
  /// kendi basamak sayısına oranla.
  static int _dovusPuani(GameState state) {
    double toplam = 0;
    for (final MartialProgress p in state.martialArts) {
      final MartialArt? dal = p.art;
      if (dal == null || dal.topLevel <= 0) continue;
      toplam += (p.level / dal.topLevel) * 18;
    }
    return toplam.round().clamp(0, 30);
  }

  /// prototypeOnly: hobilerin Deneyim eksenine katkısı.
  ///
  /// Yalnızca **sürdürülmüş** hobiler sayılır: bir kez kursa gitmek
  /// puan getirmez.
  static int _hobiPuani(GameState state) {
    double toplam = 0;
    for (final HobbyProgress h in state.hobbies) {
      final HobbyKind? tur = h.hobby;
      if (tur == null || tur.topStage <= 0) continue;
      toplam += (h.stage / tur.topStage) * 12;
      toplam += (h.years * 0.6).clamp(0, 8);
    }
    return toplam.round().clamp(0, 26);
  }

  /// En ileri gidilen dövüş dalı; hiç ders alınmadıysa `null`.
  static MartialProgress? _enIleriDal(GameState state) {
    MartialProgress? enIyi;
    for (final MartialProgress p in state.martialArts) {
      if (p.art == null || p.lessons == 0) continue;
      if (enIyi == null || p.level > enIyi.level) enIyi = p;
    }
    return enIyi;
  }

  static List<VerdictFirst> _ilkler(GameState state, int olumYasi) {
    final List<VerdictFirst> ilkler = <VerdictFirst>[];

    final int? okul = state.education.startedAtAge;
    if (okul != null) {
      ilkler.add(VerdictFirst(age: okul, text: 'Okula başladın.'));
    }

    final List<JobHistoryEntry> gecmis = state.career.history;
    if (gecmis.isNotEmpty) {
      final JobHistoryEntry ilkIs = gecmis.reduce(
        (JobHistoryEntry a, JobHistoryEntry b) =>
            b.startedAtAge < a.startedAtAge ? b : a,
      );
      ilkler.add(VerdictFirst(
        age: ilkIs.startedAtAge,
        text: 'İlk işine girdin: ${ilkIs.title}.',
      ));
    }

    final TripRecord? ilkGezi = state.trips.isEmpty
        ? null
        : state.trips.reduce(
            (TripRecord a, TripRecord b) => b.age < a.age ? b : a,
          );
    if (ilkGezi != null) {
      ilkler.add(VerdictFirst(
        age: ilkGezi.age,
        text: 'İlk kez şehir dışına çıktın: ${ilkGezi.city}.',
      ));
    }

    // Paket 36'dan beri birden fazla evlilik olabiliyor; hepsi yazılır,
    // yalnızca sonuncusu değil.
    final List<Marriage> evlilikler = <Marriage>[
      ...state.pastMarriages,
      if (state.marriage != null) state.marriage!,
    ];
    for (int i = 0; i < evlilikler.length; i++) {
      final Marriage m = evlilikler[i];
      final Person? es = state.personById(m.spouseId);
      final String kim = es == null ? '' : '${es.firstName} ile ';
      ilkler.add(VerdictFirst(
        age: m.marriedAtAge,
        text: i == 0
            ? '${kim}evlendin.'
            : '${kim}yeniden evlendin.',
      ));
    }

    // Çocuğun doğum yaşı, kişinin yaşından geriye hesaplanır. Yalnızca
    // tutarlı çıkarsa yazılır; uydurma yaş üretilmez.
    final List<Person> cocuklar = state.children;
    if (cocuklar.isNotEmpty) {
      int? enErken;
      for (final Person c in cocuklar) {
        if (!c.isAlive) continue;
        final int dogumda = olumYasi - c.age;
        if (dogumda < 12 || dogumda > olumYasi) continue;
        if (enErken == null || dogumda < enErken) enErken = dogumda;
      }
      if (enErken != null) {
        ilkler.add(VerdictFirst(
          age: enErken,
          // "Baba/anne oldun" iki cinsiyete birden yazılmış bir metindi;
          // oyuncunun cinsiyetine göre düzeltildi (Paket 37).
          text: cocuklar.length == 1
              ? (state.player.gender == Gender.kadin
                  ? 'Anne oldun.'
                  : 'Baba oldun.')
              : 'İlk çocuğun doğdu.',
        ));
      }
    }

    // Uzun sürmüş hobiye başlama anı (Paket 39). Kısa denemeler
    // yazılmaz; yaş gerçek kayıttan gelir.
    for (final HobbyProgress h in state.hobbies) {
      if (!h.isSerious || h.hobby == null) continue;
      ilkler.add(VerdictFirst(
        age: h.startedAtAge,
        text: '${h.hobby!.label} ile uğraşmaya başladın.',
      ));
    }

    // Askerlik (Paket 37): yalnızca terhis yaşı kayıtlıysa yazılır.
    final MilitaryState asker = state.military;
    if (asker.status == MilitaryStatus.tamamlandi &&
        asker.finishedAtAge != null) {
      final MilitaryRank? rutbe = asker.rank;
      ilkler.add(VerdictFirst(
        age: asker.finishedAtAge!,
        text: rutbe == null
            ? 'Askerliğini tamamladın.'
            : '${rutbe.label} olarak terhis oldun.',
      ));
    }

    // Dövüş sanatlarında en üst basamak (Paket 37). Yaş kayıtlı
    // olmayan basamaklar yazılmaz.
    for (final MartialProgress p in state.martialArts) {
      final MartialArt? dal = p.art;
      if (dal == null || p.topRankAtAge == null) continue;
      ilkler.add(VerdictFirst(
        age: p.topRankAtAge!,
        text: '${dal.label} yolunda en üst basamağa çıktın: '
            '${dal.ranks.last.name}.',
      ));
    }

    final int? emeklilik = state.career.retiredAtAge;
    if (emeklilik != null) {
      ilkler.add(VerdictFirst(age: emeklilik, text: 'Emekli oldun.'));
    }

    ilkler.sort((VerdictFirst a, VerdictFirst b) => a.age.compareTo(b.age));
    return List<VerdictFirst>.unmodifiable(ilkler);
  }

  static List<String> _hicler(GameState state) {
    final List<String> hicler = <String>[];
    if (state.marriage == null) hicler.add('Hiç evlenmedin.');
    if (state.children.isEmpty) hicler.add('Hiç çocuğun olmadı.');
    if (state.career.history.isEmpty) hicler.add('Hiç çalışmadın.');
    if (state.education.program == null) {
      hicler.add('Üniversite okumadın.');
    }
    if (state.trips.isEmpty) hicler.add('Hiç şehir dışına çıkmadın.');
    if (state.books.every((BookProgress b) => !b.finished)) {
      hicler.add('Hiç kitap bitirmedin.');
    }
    if (state.licenses.isEmpty) hicler.add('Hiç ehliyet almadın.');
    if (!state.items.any((OwnedItem i) => i.isProperty)) {
      hicler.add('Hiç ev sahibi olmadın.');
    }
    if (!state.people.any((Person p) => p.relation == RelationType.arkadas)) {
      hicler.add('Hiç yakın arkadaşın olmadı.');
    }
    return List<String>.unmodifiable(hicler);
  }

  // -----------------------------------------------------------------
  // Metinler
  // -----------------------------------------------------------------

  /// Hayata adını veren eksen.
  ///
  /// Huzur bir **ruh hâlini** anlatır, diğer üçü **yaşanmış şeyleri**.
  /// Üstelik huzur doğrudan 0-100 arası bir istatistikten gelir, somut
  /// eksenler ise seyrek olaylardan toplanır; ölçümde 38 yıl öğretmenlik
  /// yapıp 53 yıl evli kalmış bir hayat, yalnızca keyfi yerinde öldüğü
  /// için "kendi hâlinde bir hayat" sayılıyordu.
  ///
  /// Bu yüzden kural şu: **hayat başka bir şeyle anılabiliyorsa onunla
  /// anılır.** Huzur ancak somut eksenlerin hepsi zayıfken —yani
  /// anlatacak pek bir şey yokken— hayata adını verir.
  static VerdictAxis _baskin(List<VerdictAxis> eksenler) {
    final List<VerdictAxis> somut = eksenler
        .where((VerdictAxis a) => a.id != 'huzur')
        .toList(growable: false);
    final VerdictAxis enSomut = somut
        .reduce((VerdictAxis a, VerdictAxis b) => b.value > a.value ? b : a);
    if (enSomut.value >= prototypeOnlyWeakThreshold) return enSomut;
    return eksenler.firstWhere((VerdictAxis a) => a.id == 'huzur');
  }

  /// Baskın eksenin cümledeki karşılığı.
  static String _guclu(String axisId) {
    switch (axisId) {
      case 'baglar':
        return 'Bu hayatın ağırlığı sevdiklerindeydi';
      case 'emek':
        return 'Bu hayatın ağırlığı emekteydi';
      case 'deneyim':
        return 'Bu hayatın ağırlığı gezip görmekteydi';
      case 'huzur':
        return 'Sakin bir hayattı';
      default:
        return 'Kendine göre bir hayattı';
    }
  }

  /// Zayıf eksenin cümledeki karşılığı.
  static String _zayif(String axisId) {
    switch (axisId) {
      case 'baglar':
        return 'yanında çok az kişi vardı';
      case 'emek':
        return 'geride biriken pek bir şey olmadı';
      case 'deneyim':
        return 'hep aynı yerde, aynı düzende geçti';
      case 'huzur':
        return 'rahat yüzü pek görmedi';
      default:
        return 'eksik kalan yanları vardı';
    }
  }

  static String _baslik(
    VerdictAxis en,
    VerdictAxis az,
    int olumYasi,
    GameState state,
  ) {
    if (olumYasi < 18) return 'Yarıda kalan bir hayat';
    if (en.value < prototypeOnlyWeakThreshold) return 'Sessiz bir hayat';
    switch (en.id) {
      case 'baglar':
        return state.children.length >= 3
            ? 'Kalabalık bir hayat'
            : 'Sevdikleriyle bir hayat';
      case 'emek':
        return state.career.isRetired
            ? 'Emekle geçen bir hayat'
            : 'Çalışarak geçen bir hayat';
      case 'deneyim':
        return 'Gezip görülen bir hayat';
      case 'huzur':
        return 'Kendi hâlinde bir hayat';
      default:
        return 'Bir hayat';
    }
  }

  /// Açılış cümlesi.
  ///
  /// Eksen notlarını **tekrarlamaz**: notlar hemen altta zaten yazıyor.
  static String _cumle(
    GameState state,
    int olumYasi,
    VerdictAxis en,
    VerdictAxis az,
  ) {
    final String ad = state.player.firstName;
    final StringBuffer b = StringBuffer();
    if (olumYasi < 18) {
      b.write('$ad daha hayatın başındaydı. ');
    } else if (olumYasi >= 85) {
      b.write('$ad uzun bir ömür sürdü. ');
    } else {
      b.write('$ad $olumYasi yıl yaşadı. ');
    }
    b.write(_guclu(en.id));
    if (az.value < prototypeOnlyWeakThreshold && az.id != en.id) {
      b.write('; ${_zayif(az.id)}.');
    } else {
      b.write('.');
    }
    return b.toString();
  }

  static String _kapanis(
    GameState state,
    int olumYasi,
    List<VerdictFirst> ilkler,
    List<String> hicler,
  ) {
    if (ilkler.isEmpty) {
      return 'Bu hayatın anlatacak çok şeyi olmadı; bir sonraki başka '
          'türlü geçebilir.';
    }
    if (hicler.isEmpty) {
      return 'Yapılmadan kalan bir şey yok gibi görünüyor.';
    }
    if (hicler.length > ilkler.length + 2) {
      return 'Geriye çok soru kaldı: yapılmayanlar yapılanlardan fazla.';
    }
    return 'Bazı şeyler oldu, bazıları hiç olmadı. Bir ömür böyle bir şey.';
  }
}

import 'dart:math';

import '../../data/activity_catalog.dart';
import '../models/game_state.dart';
import '../models/interaction.dart';
import '../models/person.dart';
import '../models/relation.dart';

/// Eğlence aktivitelerinin **gerçek kişilerle** yapılması
/// (Paket 41 — Issue #67, 3. kısım).
///
/// **Yeni bir aktivite sistemi değildir.** Oyuncu yine `ActivityEngine`
/// üzerinden aynı eylemi yapar; burası yalnızca "kiminle" sorusunu
/// yanıtlar. Ücret, yaş sınırı ve yıllık kota tek yerde kalır, dolayısıyla
/// çifte ücret ya da çifte kayıt oluşamaz.
///
/// Kimse uydurulmaz: yanına gelen kişi kayıtta **gerçekten duran**,
/// yaşayan, gündelik hayatta erişilebilen ve yaşı uyan biridir. Başka
/// şehirdeki eski bir sınıf arkadaşı bir anda sinemada yanında belirmez —
/// erişilebilirlik kuralı (`GameState.isReachable`) şehir koşulunu da
/// içerir.
///
/// Sayısal değerler `prototypeOnly`'dir
/// (`docs/DESIGN_REVIEW_QUEUE.md`, Q-108).
abstract final class Outing {
  /// Birlikte çıkılabilecek bağ türleri.
  ///
  /// Eş, sevgili, çocuk, anne, baba, kardeş ve **yakın** arkadaş.
  static const Set<RelationType> companionRelations = <RelationType>{
    RelationType.es,
    RelationType.sevgili,
    RelationType.cocuk,
    RelationType.anne,
    RelationType.baba,
    RelationType.kardes,
    RelationType.arkadas,
  };

  /// prototypeOnly: bir arkadaşın "yakın arkadaş" sayılması için gereken bağ.
  static const int prototypeOnlyCloseFriendBond = 45;

  /// prototypeOnly: küçük çocuğun yanına alınabilmesi için en küçük yaş.
  ///
  /// Kendi ayakları üzerinde bir programı takip edemeyecek kadar küçük
  /// çocuk sinemaya ya da maça götürülmez; bu yaşın altında birlikte
  /// yapılabilecek şey ayrı bir etkileşimdir.
  static const int prototypeOnlyMinChildAge = 4;

  /// prototypeOnly: birlikte gitmenin mutluluğa kattığı fazladan pay.
  /// Yoldaşın da bileti ödenir: iki kişilik maliyet.
  ///
  /// Faho'nun Q-108 kararı. Ücretsiz aktivite (park) ücretsiz kalır.
  static int costFor(ActivityAction action, {required bool withCompanion}) {
    if (action.cost <= 0) return 0;
    return withCompanion ? action.cost * 2 : action.cost;
  }

  static const int prototypeOnlyCompanionHappiness = 3;

  /// prototypeOnly: birlikte gitmenin bağa kattığı puan.
  static const int prototypeOnlyCompanionBond = 6;

  /// Yoldaşın bu programdan aldığı keyif (D-074).
  ///
  /// Eylemin kendi mutluluk değerine dayanır: parkta yürümek ile konsere
  /// gitmek aynı keyfi vermez. Tekrar eğrisi oyuncununkiyle **aynıdır**;
  /// aynı kişiyle üst üste çıkarak keyif kasılamaz.
  static int companionHappinessGain(ActivityAction action, double oran) {
    final int taban = action.happiness > 0
        ? action.happiness
        : prototypeOnlyCompanionHappiness;
    final int deger = (taban * oran).round();
    return deger < 0 ? 0 : deger;
  }

  /// prototypeOnly: keyfi bu değerin altındaki kişi daveti reddedebilir.
  static const int prototypeOnlyLowHappiness = 35;

  /// prototypeOnly: keyfi düşük kişinin ret ihtimalinin tabanı.
  static const double prototypeOnlyRefusalBase = 0.5;

  /// prototypeOnly: aynı yıl aynı programa tekrar davet edilmenin ret
  /// ihtimaline kattığı pay.
  static const double prototypeOnlyRepeatRefusal = 0.18;

  /// prototypeOnly: ret ihtimalinin üst sınırı.
  ///
  /// Kapı hiçbir zaman tamamen kapanmaz: küskün biri bile bazen gelir.
  static const double prototypeOnlyMaxRefusal = 0.75;

  /// Bu davetin reddedilme ihtimali (D-059).
  ///
  /// Üç şey birlikte bakılır: **yakınlık** (ilişkinin gücü), **keyif**
  /// (kişinin şu anki hâli) ve **aynı yıl kaç kez çağrıldığı**. Bağı da
  /// keyfi de yerinde olan, bu yıl ilk kez çağrılan kişi reddetmez.
  static double refusalChance(
    GameState state,
    ActivityAction action,
    Person person,
  ) {
    double sans = 0;

    // Yakınlık: 50'nin altında her puan küçük bir tereddüt ekler.
    if (person.bond < 50) sans += (50 - person.bond) * 0.008;

    // Keyif: düşük keyifli kişi programa gelmek istemez.
    if (person.happiness < prototypeOnlyLowHappiness) {
      final double eksik =
          (prototypeOnlyLowHappiness - person.happiness) / prototypeOnlyLowHappiness;
      sans += prototypeOnlyRefusalBase * eksik;
    }

    // Aynı yıl tekrar tekrar aynı programa çağrılmak.
    sans += timesWith(state, action, person) * prototypeOnlyRepeatRefusal;

    return sans.clamp(0.0, prototypeOnlyMaxRefusal);
  }

  /// Ret gerekçesi; davet kabul edilecekse `null`.
  ///
  /// Gerekçe **gerçek sebebi** söyler: uydurma bir mazeret üretilmez.
  ///
  /// **Rastgele sayı kullanılmaz, bilerek.** Kararın tohumu oyuncunun
  /// yaşı, kişinin kimliği ve eylemden türetilir; böylece oyuncu aynı
  /// daveti art arda tıklayıp "evet" çıkana kadar zar atamaz. Karar yıl
  /// içinde sabittir, yeni yaşta yeniden verilir.
  static String? refusalReason(
    GameState state,
    ActivityAction action,
    Person person,
  ) {
    final double sans = refusalChance(state, action, person);
    if (sans <= 0) return null;
    if (_kararTohumu(state, action, person) >= sans) return null;

    if (person.happiness < prototypeOnlyLowHappiness) {
      return '${person.firstName} bugün pek havasında değil; '
          'bu sefer gelmek istemedi.';
    }
    if (timesWith(state, action, person) > 0) {
      return '${person.firstName} bu yıl yeterince gittiğinizi söyledi.';
    }
    return '${person.firstName} bu sefer gelemeyeceğini söyledi.';
  }

  /// Davet kararının 0-1 arası sabit tohumu.
  static double _kararTohumu(
    GameState state,
    ActivityAction action,
    Person person,
  ) {
    final String anahtar =
        '${state.player.id}|${state.player.age}|${person.id}|${action.id}';
    // Basit ve kararlı bir karma; kriptografik olması gerekmiyor.
    int h = 0x811c9dc5;
    for (final int kod in anahtar.codeUnits) {
      h = (h ^ kod) * 0x01000193 & 0x7fffffff;
    }
    return (h % 100000) / 100000.0;
  }

  /// Aynı yıl aynı kişiyle tekrar çıkıldıkça azalan kazanç eğrisi.
  static const List<double> prototypeOnlyRepeatCurve = <double>[1.0, 0.6, 0.3];

  /// Bu eylem birlikte yapılabilir mi?
  ///
  /// Yalnızca Eğlence mekânı: berberde ya da sağlık ocağında "yanına biri"
  /// gelmesi anlamsız olurdu.
  static bool supports(ActivityAction action) =>
      action.venue == ActivityVenue.eglence;

  /// Bu eyleme bu kişi katılabilir mi?
  static InteractionAvailability companionAvailability(
    GameState state,
    ActivityAction action,
    Person person,
  ) {
    if (!supports(action)) {
      return const InteractionAvailability.blocked(
        'Bu eylem birlikte yapılmaz.',
      );
    }
    // Kayıtta gerçekten duran biri olmalı.
    if (state.personById(person.id) == null) {
      return const InteractionAvailability.blocked('Böyle biri yok.');
    }
    if (!person.isAlive) {
      return const InteractionAvailability.blocked('Artık aranızda değil.');
    }
    if (!companionRelations.contains(person.relation)) {
      return const InteractionAvailability.blocked(
        'Bu kişiyle birlikte program yapmıyorsunuz.',
      );
    }
    if (person.relation == RelationType.arkadas &&
        person.bond < prototypeOnlyCloseFriendBond) {
      return const InteractionAvailability.blocked(
        'Bu kadar yakın bir arkadaşlığınız yok.',
      );
    }
    // Şehir kuralı burada: başka şehirdeki kişi bir anda yanında belirmez.
    if (!state.isReachable(person)) {
      return const InteractionAvailability.blocked(
        'Şu an gündelik hayatında görüştüğün biri değil.',
      );
    }
    // Yaş uygunluğu: hem eylemin kendi yaş sınırı hem de çok küçük çocuk.
    if (person.age < action.minAge) {
      return InteractionAvailability.blocked(
        '${person.firstName} bunun için çok küçük.',
      );
    }
    if (person.relation == RelationType.cocuk &&
        person.age < prototypeOnlyMinChildAge) {
      return InteractionAvailability.blocked(
        '${person.firstName} bunun için çok küçük.',
      );
    }
    return const InteractionAvailability.allowed();
  }

  /// Bu eyleme şu an gerçekten katılabilecek kişiler.
  static List<Person> companionsFor(
    GameState state,
    ActivityAction action,
  ) =>
      state.people
          .where((Person p) =>
              companionAvailability(state, action, p).isAllowed)
          .toList(growable: false);

  /// Bu yıl bu kişiyle bu eylem kaç kez yapıldı?
  static int timesWith(GameState state, ActivityAction action, Person person) =>
      state.interactionCount('birlikte-${person.id}', action.id);

  /// Birlikte gidilen bir eylemin sahne metni.
  ///
  /// Sahne hem eyleme hem de bağ türüne göre seçilir: çocukla gidilen maç
  /// ile sevgiliyle gidilen konser aynı cümle değildir.
  static String sceneFor(ActivityAction action, Person person, Random rng) {
    final List<String> sahneler = _scenes(action.id, person.relation);
    final String secim = sahneler[rng.nextInt(sahneler.length)];
    return secim.replaceAll('{kisi}', person.firstName);
  }

  /// Bu sahne ileride hatırlanmaya değer mi?
  ///
  /// Yalnızca gerçekten ayrı duran anlar: ilk kez birlikte gidilen bir
  /// program ya da uzun zaman sonra tekrarlanan bir alışkanlık.
  static bool isMemorable(
    GameState state,
    ActivityAction action,
    Person person,
  ) =>
      timesWith(state, action, person) == 0;

  static List<String> _scenes(String actionId, RelationType relation) {
    final Map<RelationType, List<String>> kisiye = _sceneTable[actionId] ??
        const <RelationType, List<String>>{};
    return kisiye[relation] ?? kisiye[RelationType.arkadas] ?? _genel;
  }

  static const List<String> _genel = <String>[
    '{kisi} ile birlikte gittiniz. İyi bir gündü.',
  ];

  /// Sahneler: eylem → bağ türü → metinler.
  ///
  /// Her sahne özgündür; hiçbiri başka bir oyundan alınmamıştır.
  static const Map<String, Map<RelationType, List<String>>> _sceneTable =
      <String, Map<RelationType, List<String>>>{
    'sinema': <RelationType, List<String>>{
      RelationType.cocuk: <String>[
        '{kisi} ile sinemaya gittiniz. Filmin yarısında patlamış mısır '
            'bitti, kalan yarısını kucağında izledi.',
      ],
      RelationType.es: <String>[
        '{kisi} ile sinemaya gittiniz. Çıkışta filmi baştan sona '
            'tartıştınız; ikiniz de haklıydınız.',
      ],
      RelationType.sevgili: <String>[
        '{kisi} ile sinemaya gittiniz. Işıklar sönünce elini tuttun ve '
            'film bittiğinde hâlâ öyleydiniz.',
      ],
      RelationType.arkadas: <String>[
        '{kisi} ile sinemaya gittiniz. Salonda bir tek siz güldünüz.',
      ],
      RelationType.anne: <String>[
        '{kisi} ile sinemaya gittiniz. "Bu oyuncuyu nereden tanıyorum" '
            'sorusu film boyunca sürdü.',
      ],
      RelationType.baba: <String>[
        '{kisi} ile sinemaya gittiniz. Jenerik akarken yerinden '
            'kalkmadı; sonuna kadar oturuldu.',
      ],
      RelationType.kardes: <String>[
        '{kisi} ile sinemaya gittiniz. Kim hangi koltuğa oturacak diye '
            'çocukluktaki gibi tartıştınız.',
      ],
    },
    'maca_git': <RelationType, List<String>>{
      RelationType.baba: <String>[
        '{kisi} ile maça gittiniz. Aynı anda ayağa kalkıp aynı anda '
            'oturdunuz; kimse tek kelime etmedi.',
      ],
      RelationType.cocuk: <String>[
        '{kisi} ile maça gittiniz. Skoru değil, tribünün sesini '
            'konuştu bütün yol boyunca.',
      ],
      RelationType.kardes: <String>[
        '{kisi} ile maça gittiniz. Hakeme beraber bağırdınız, evde '
            'kimseye anlatmadınız.',
      ],
      RelationType.arkadas: <String>[
        '{kisi} ile maça gittiniz. Dönüşte üç durak yürüdünüz, hava '
            'güzeldi.',
      ],
      RelationType.es: <String>[
        '{kisi} ile maça gittiniz. Maçtan çok yanındakileri seyretti '
            'ama gelmekten memnundu.',
      ],
    },
    'konsere_git': <RelationType, List<String>>{
      RelationType.sevgili: <String>[
        '{kisi} ile konsere gittiniz. Kalabalıkta el ele tutuşup öyle '
            'kaldınız; o şarkı artık sizin.',
      ],
      RelationType.arkadas: <String>[
        '{kisi} ile konsere gittiniz. Sesiniz ertesi gün çıkmadı.',
      ],
      RelationType.kardes: <String>[
        '{kisi} ile konsere gittiniz. Aynı şarkıyı bilmeniz ikinizi de '
            'şaşırttı.',
      ],
      RelationType.es: <String>[
        '{kisi} ile konsere gittiniz. Kalabalıktan çıkarken elini '
            'bırakmadın.',
      ],
      RelationType.cocuk: <String>[
        '{kisi} ile konsere gittiniz. Omzunda uyuyakaldı ama sabah '
            'bütün şarkıları hatırlıyordu.',
      ],
    },
    'kafede_otur': <RelationType, List<String>>{
      RelationType.anne: <String>[
        '{kisi} ile kafede oturdunuz. İki çay içtiniz, bir saat konuştu, '
            'sen de dinledin.',
      ],
      RelationType.arkadas: <String>[
        '{kisi} ile kafede oturdunuz. Çay soğuyana kadar kimse kalkmadı.',
      ],
      RelationType.kardes: <String>[
        '{kisi} ile kafede oturdunuz. Eski bir meseleyi ilk kez '
            'gülerek anlattınız.',
      ],
      RelationType.sevgili: <String>[
        '{kisi} ile kafede oturdunuz. Camdan dışarıyı seyrederken '
            'sessizlik hiç rahatsız etmedi.',
      ],
      RelationType.es: <String>[
        '{kisi} ile kafede oturdunuz. Yıllardır ilk kez telefonlara '
            'bakmadınız.',
      ],
    },
    'parkta_yuruyus': <RelationType, List<String>>{
      RelationType.anne: <String>[
        '{kisi} ile parkta yürüdünüz. Bir bank bulup uzun süre '
            'oturdunuz.',
      ],
      RelationType.baba: <String>[
        '{kisi} ile parkta yürüdünüz. Yolda tanıdığı üç kişiyle '
            'selamlaştı.',
      ],
      RelationType.cocuk: <String>[
        '{kisi} ile parkta yürüdünüz. Salıncaktan inmesi yarım saat '
            'sürdü.',
      ],
      RelationType.es: <String>[
        '{kisi} ile parkta yürüdünüz. Aynı turu üç kez attınız, kimse '
            'fark etmedi.',
      ],
      RelationType.arkadas: <String>[
        '{kisi} ile parkta yürüdünüz. Konu bitince susmak da iyi geldi.',
      ],
      RelationType.kardes: <String>[
        '{kisi} ile parkta yürüdünüz. Çocukken geldiğiniz köşeyi '
            'aradınız, bulamadınız.',
      ],
      RelationType.sevgili: <String>[
        '{kisi} ile parkta yürüdünüz. Eve dönerken yolu uzattınız.',
      ],
    },
  };
}

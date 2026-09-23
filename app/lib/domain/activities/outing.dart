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
  static const int prototypeOnlyCompanionHappiness = 3;

  /// prototypeOnly: birlikte gitmenin bağa kattığı puan.
  static const int prototypeOnlyCompanionBond = 6;

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

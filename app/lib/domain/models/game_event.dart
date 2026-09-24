import 'package:flutter/foundation.dart';

import '../../data/item_catalog.dart';
import 'relation.dart';

/// Olayın hangi yaşam alanından geldiği (D-023).
enum EventCategory {
  aile('Aile'),
  okul('Okul'),
  mahalle('Mahalle'),
  kisisel('Kişisel'),
  yetiskinlik('Yetişkinlik');

  const EventCategory(this.label);

  final String label;
}

/// Bir olayın çıkabilmesi için aranan koşullar (D-009).
///
/// Yaş tek başına yeterli değildir: olayın kişisi gerçekten yaşıyor olmalı,
/// gereken hikâye izi bulunmalı, sahip olunmayan varlık için olay çıkmamalıdır.
@immutable
class EventRequirement {
  const EventRequirement({
    this.minAge = 0,
    this.maxAge = 120,
    this.livingRelations = const <RelationType>{},
    this.requireSameHousehold = false,
    this.requiredFlags = const <String>{},
    this.forbiddenFlags = const <String>{},
    this.requiredPossessions = const <String>{},
    this.requiredPossessionKinds = const <ItemKind>{},
    this.requiresSchoolStudent = false,
    this.minGrade,
    this.maxGrade,
    this.requiresNeglectedRelative = false,
    this.personRole,
    this.personMinAge,
    this.personMaxAge,
    this.requireOutsideHousehold = false,
    this.requireReachable = false,
    this.requiresSocialAccount = false,
    this.requiredLicenses = const <String>{},
    this.requiresEmployed = false,
    this.requiresTenant = false,
    this.forbidsProperty = false,
    this.forbidsVehicle = false,
    this.requiresMinYearsInJob = 0,
    this.minFame = 0,
    this.requiresTripMemory = false,
    this.requiresRetired = false,
    this.requiredHobbyId,
    this.minHobbyYears = 0,
    this.minHobbyStage = 0,
    this.requiresLivingPet = false,
    this.minPetAge = 0,
    this.minPetYearsTogether = 0,
    this.requiresActiveHobby = false,
  });

  /// Paket 39: bu olay yalnızca bu hobiyle uğraşmış oyuncuya çıkar.
  ///
  /// Hobi geçmişi **gerçek kayıttan** okunur; uydurulmaz.
  /// Oyuncunun **hiç konutu olmaması** gerekiyor mu? (D-085)
  ///
  /// Eşin ev istediği olay, zaten evi olan oyuncuya çıkmaz.
  final bool forbidsProperty;

  /// Oyuncunun **hiç aracı olmaması** gerekiyor mu? (D-085)
  final bool forbidsVehicle;

  final String? requiredHobbyId;

  /// prototypeOnly: hobinin kaç yıl sürmüş olması gerektiği.
  final int minHobbyYears;

  /// prototypeOnly: hobide ulaşılmış olması gereken basamak.
  final int minHobbyStage;

  /// Olay yalnızca **yaşayan ve hanede olan** bir evcil hayvanı olan
  /// oyuncuya çıkar (Paket 40). Metindeki `{hayvan}` o hayvanın gerçek
  /// adıyla doldurulur.
  final bool requiresLivingPet;

  /// Hayvanın kendi yaşı en az kaç olmalı?
  final int minPetAge;

  /// Oyuncuyla hayvan en az kaç yıldır birlikte olmalı?
  final int minPetYearsTogether;

  /// Hobi **hâlâ sürüyor** sayılmalı mı? (Uzun süredir bırakılmışsa çıkmaz.)
  final bool requiresActiveHobby;

  final int minAge;
  final int maxAge;

  /// Bu bağlardan **hayatta** en az bir kişi gerekir; olay o kişiyle kurulur.
  /// Boşsa olay kişisizdir.
  final Set<RelationType> livingRelations;

  /// Olayın kişisinin oyuncuyla aynı evde yaşaması gerekir.
  final bool requireSameHousehold;

  /// Geçmişte bırakılmış olması gereken izler (D-008).
  final Set<String> requiredFlags;

  /// Bu izlerden biri varsa olay çıkmaz.
  final Set<String> forbiddenFlags;

  /// Sahip olunması gereken varlıklar; olmayan araç için olay çıkmaz.
  ///
  /// Tam **tür kimliği** arar: yalnızca o eşyaya özgü olaylar içindir.
  final Set<String> requiredPossessions;

  /// Sahip olunması gereken eşya **çeşitleri**.
  ///
  /// "Herhangi bir otomobil" gibi koşullar içindir: tek bir ürün kimliğine
  /// bağlanan olay, oyuncunun başka model araba almasıyla hiç çıkmaz hâle
  /// geliyordu. Listedeki her çeşitten **en az bir** eşya gerekir.
  final Set<ItemKind> requiredPossessionKinds;

  /// Okula devam ediyor olmayı gerektirir (yaş değil, eğitim durumu).
  final bool requiresSchoolStudent;

  /// Sınıf aralığı (1-12). Verilirse oyuncunun o sınıfta olması gerekir.
  final int? minGrade;
  final int? maxGrade;

  /// Uzun süre oyun içinde temas kurulmamış bir yakın gerektirir (D-025).
  final bool requiresNeglectedRelative;

  /// Olayın **kişisinin** yaş aralığı (oyuncunun değil).
  ///
  /// Çocukla ilgili olaylar bununla doğru yaşa bağlanır: bebeklik olayı
  /// 15 yaşındaki çocukta çıkmaz.
  final int? personMinAge;
  final int? personMaxAge;

  /// Olayın kişisinin oyuncuyla **ayrı evde** yaşaması gerekir.
  ///
  /// Ziyaret olayları bunu kullanır: aynı evde yaşanan kişiye "ziyarete
  /// geldi" denmez.
  final bool requireOutsideHousehold;

  /// Olayın kişisi, gündelik hayatta **gerçekten erişilebilir** olmalı.
  ///
  /// Yıllar önce tanışılmış, başka şehirde kalmış biri "her gün görüşülen
  /// kişi" gibi kullanılmaz (D-025, Paket 3). Bayram/ziyaret gibi uzak
  /// yakınları anlatan olaylar bunu **kullanmaz**.
  final bool requireReachable;

  /// En az bir sosyal medya hesabı gerektirir.
  ///
  /// Hesabı olmayan oyuncuya sosyal medya üzerinden mesaj gelmez.
  final bool requiresSocialAccount;

  /// Sahip olunması gereken ehliyetler.
  ///
  /// Aracı olan ama ehliyeti olmayan oyuncuya "direksiyona geçtin" denmez.
  final Set<String> requiredLicenses;

  /// Oyuncunun **emekli olmuş** olmasını gerektirir (Paket 12).
  final bool requiresRetired;

  /// Yıllar önce **birlikte** yapılmış, kişisi hâlâ hayatta olan bir gezi
  /// gerektirir (Paket 11).
  ///
  /// Olayın kişisi o gezinin yoldaşıdır; metindeki `{sehir}` gidilen
  /// şehirle doldurulur. Böyle bir gezi yoksa olay çıkmaz.
  final bool requiresTripMemory;

  /// Gerekli en az Ün değeri.
  ///
  /// Ün açılmamışsa (hiç kitle yoksa) bu olaylar çıkmaz (D-027).
  final int minFame;

  /// Oyuncunun **şu an bir işte çalışıyor** olmasını gerektirir.
  ///
  /// İşsiz oyuncuya iş yerinde geçen olay çıkmaz (Paket 9).
  final bool requiresEmployed;

  /// Oyuncunun **kirada** yaşıyor olmasını gerektirir.
  ///
  /// Ev sahibi, kira zammı ve depozito gibi olaylar içindir. Kendi
  /// evinde oturan ya da ailesinin yanında yaşayan oyuncuya "ev sahibi
  /// aradı" denmez.
  final bool requiresTenant;

  /// Şu anki işte geçmiş olması gereken en az yıl.
  ///
  /// İşe girdiği gün "yıllardır buradasın" denmesin diye kullanılır.
  final int requiresMinYearsInJob;

  /// Olayın kişisi, daha önce bir hikâye rolüne kilitlenmiş kişidir.
  ///
  /// Devam olayları bunu kullanır: yıllar önce savunduğun arkadaş, yıllar
  /// sonra **aynı kişi** olarak karşına çıkar. Kişi artık yoksa olay çıkmaz.
  final String? personRole;
}

/// Bir olay seçeneği ve sonuçları.
@immutable
class EventChoice {
  const EventChoice({
    required this.id,
    required this.label,
    required this.resultText,
    this.happiness = 0,
    this.health = 0,
    this.intelligence = 0,
    this.charisma = 0,
    this.appearance = 0,
    this.bond = 0,
    this.money = 0,
    this.addFlags = const <String>{},
    this.removeFlags = const <String>{},
    this.addPossessions = const <String>{},
    this.startsRomance = false,
    this.endsRomance = false,
    this.startsSchoolFriendship = false,
    this.startsFriendship = false,
    this.rememberPersonAs,
  });

  final String id;
  final String label;

  /// Seçimden sonra gösterilen ve hayat günlüğüne yazılan özgün metin.
  final String resultText;

  final int happiness;
  final int health;
  final int intelligence;
  final int charisma;
  final int appearance;

  /// Olayın kişisiyle ilişki değişimi.
  final int bond;

  /// Oyuncunun **kendi** cüzdanındaki değişim (ECO-001). Aile parasıyla
  /// karışmaz. Miktarlar prototypeOnly'dir.
  final int money;

  /// Geleceğe bırakılan iz (D-008, D-022).
  final Set<String> addFlags;

  /// Artık geçerli olmayan izler (örneğin ilişki bittiğinde).
  final Set<String> removeFlags;
  final Set<String> addPossessions;

  /// Bu seçim yeni bir romantik ilişki başlatır: kişi oluşturulur ve
  /// **sevgili** statüsüyle Aile'de listelenir (D-029, D-030).
  final bool startsRomance;

  /// Bu seçim mevcut ilişkiyi bitirir. Kişi **silinmez**; aynı kimlikle
  /// eski sevgili statüsüne geçer.
  final bool endsRomance;

  /// Bu seçim okuldaki tanışıklığı **yakın arkadaşlığa** çevirir.
  ///
  /// Olayın kişisi varsa o kişi (aynı kimlikle) arkadaş olur; yoksa kalıcı
  /// kimlikli yeni bir arkadaş kaydı oluşturulur. Her sınıf arkadaşı
  /// kendiliğinden yakın arkadaş sayılmaz.
  final bool startsSchoolFriendship;

  /// Bu seçim, okul dışında **yeni bir arkadaş** kaydı açar.
  ///
  /// Kişi yalnızca tanışma gerçekten olduğunda üretilir; reddedilen ya da
  /// gerçekleşmeyen tanışma için kayıt açılmaz. Yeni tanışıklık romantik
  /// ilişki değildir.
  final bool startsFriendship;

  /// Bu seçim, olayın kişisini bir hikâye rolüne kilitler.
  ///
  /// Sonraki olaylar [EventRequirement.personRole] ile aynı kişiyi bulur.
  final String? rememberPersonAs;

  /// Yalnızca etiketi değişmiş bir kopya.
  ///
  /// Seçenek metnindeki `{kisi}` gibi yer tutucular ekrana gelmeden
  /// doldurulsun diye vardır; sonuçlar aynen korunur.
  EventChoice withLabel(String newLabel) => EventChoice(
        id: id,
        label: newLabel,
        resultText: resultText,
        happiness: happiness,
        health: health,
        intelligence: intelligence,
        charisma: charisma,
        appearance: appearance,
        bond: bond,
        money: money,
        addFlags: addFlags,
        removeFlags: removeFlags,
        addPossessions: addPossessions,
        startsRomance: startsRomance,
        endsRomance: endsRomance,
        startsSchoolFriendship: startsSchoolFriendship,
        rememberPersonAs: rememberPersonAs,
      );
}

/// Olay tanımı. Havuz modülerdir; yeni olay eklemek listeye kayıt eklemektir.
@immutable
class GameEvent {
  const GameEvent({
    required this.id,
    required this.category,
    required this.text,
    required this.choices,
    this.requirement = const EventRequirement(),
    this.repeatable = false,
    this.minAgeGap = prototypeOnlyDefaultRepeatGap,
    this.weight = 1,
    this.priority = 0,
  }) : assert(minAgeGap >= 1, 'Tekrar aralığı en az bir yaş olmalıdır.');

  /// prototypeOnly: tekrar aralığı belirtilmeyen tekrarlanabilir olaylar için
  /// varsayılan yaş farkı. Kesin tekrar dengesi henüz kararlaştırılmadı.
  static const int prototypeOnlyDefaultRepeatGap = 3;

  final String id;
  final EventCategory category;

  /// `{kisi}` kişinin adıyla, `{bag}` bağ etiketiyle değiştirilir.
  final String text;
  final List<EventChoice> choices;
  final EventRequirement requirement;

  /// Aynı hayatta birden çok kez çıkabilir mi?
  final bool repeatable;

  /// Tekrarlanabilir bir olayın yeniden çıkabilmesi için geçmesi gereken
  /// **oyun içi** yaş farkı.
  ///
  /// Doğal olarak tekrar eden olaylar (bayram sabahı gibi) tamamen
  /// yasaklanmaz; farklı yaşlarda, uygun koşullarda yeniden gelebilir.
  /// Buradaki sayılar prototypeOnly'dir.
  final int minAgeGap;

  /// Aynı anda uygun olan olaylar arasında görece ağırlık (prototypeOnly).
  final int weight;

  /// Dönüm noktası önceliği (Paket 21).
  ///
  /// Tek bir yıla bağlı olaylar — sınav yılı, okulun ilk günü, işe ilk
  /// gün — bütün havuzla yarıştıkları için çoğu hayatta hiç çıkmıyordu:
  /// ölçümde sınav yılı olayları oyuncuların ancak **%38'inde**
  /// görülüyordu. Önceliği sıfırdan büyük bir olay uygun olduğunda, o yıl
  /// **yalnızca en yüksek öncelikli olaylar** yarışır; sıradan olaylar
  /// o yılı beklemek zorunda kalır.
  ///
  /// Öncelik, olayın çıkacağını **garanti etmez**: koşulları tutmuyorsa
  /// yine elenir ve aynı öncelikte birden çok olay varsa aralarında
  /// ağırlıkla seçim yapılır.
  final int priority;
}

/// Oyuncunun karşısına çıkmış, kişisi ve metni çözülmüş olay.
@immutable
class ActiveEvent {
  const ActiveEvent({
    required this.eventId,
    required this.category,
    required this.text,
    required this.choices,
    this.personId,
    this.isContinuation = false,
  });

  final String eventId;
  final EventCategory category;

  /// Bu olay geçmiş bir seçimin devamı mı?
  ///
  /// Faho'nun Q-114 kararı: oyuncuya büyük bir "QUEST" etiketi
  /// konmayacak ama devam olayında küçük, doğal bir işaret olabilir.
  /// Ekranda "Geçmişten" rozeti olarak görünür.
  final bool isContinuation;

  /// Yer tutucuları doldurulmuş, ekranda gösterilecek metin.
  final String text;
  final List<EventChoice> choices;

  /// Olay bir kişiyle kurulduysa o kişinin kalıcı kimliği.
  final String? personId;
}

/// Bir seçimin uygulanmış hâli; arayüzde sonucu göstermek için.
@immutable
class EventResolution {
  const EventResolution({
    required this.eventId,
    required this.choiceId,
    required this.resultText,
  });

  final String eventId;
  final String choiceId;
  final String resultText;
}

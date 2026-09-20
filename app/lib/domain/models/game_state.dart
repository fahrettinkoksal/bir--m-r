import 'package:flutter/foundation.dart';

import 'education.dart';
import 'game_event.dart';
import 'gift_record.dart';
import 'life_log.dart';
import 'parental_status.dart';
import 'person.dart';
import 'player_character.dart';
import 'relation.dart';

/// Tek bir hayatın tüm durumu.
///
/// Kişiler tek bir listede tutulur; Aile ekranı da ileride eklenecek olay
/// motoru da aynı kayıtları kullanır, böylece iki yerde farklı gerçeklik
/// oluşmaz.
@immutable
class GameState {
  const GameState({
    required this.seed,
    required this.player,
    required this.people,
    required this.pets,
    required this.parentalStatus,
    required this.log,
    this.interactionCounts = const <String, int>{},
    this.lastInteractionAge = const <String, int>{},
    this.storyFlags = const <String>{},
    this.possessions = const <String>{},
    this.seenEventIds = const <String>{},
    this.lastEventAge = const <String, int>{},
    this.storyPeople = const <String, String>{},
    this.gifts = const <GiftRecord>[],
    this.pendingEvent,
    this.progressSinceLastEvent = 0,
    this.extraEventsThisAge = 0,
    this.education = const EducationState.notStarted(),
  });

  /// Üretimde kullanılan tohum. Tekrarlanabilir test senaryosu içindir;
  /// her oyuncuya sabit bir aile verilmez.
  final int seed;
  final PlayerCharacter player;
  final List<Person> people;
  final List<Pet> pets;
  final ParentalStatus parentalStatus;
  final List<LifeLogEntry> log;

  /// **Yalnızca içinde bulunulan yaşa ait** tekrar geçmişi:
  /// `'<kişiKimliği>|<etkileşimTürü>' -> kaç kez gerçekleşti`.
  ///
  /// Sayaç kişi ve etkileşim türü bazındadır; bu yüzden anneyle vakit
  /// geçirmek babayla vakit geçirmeyi ya da aynı kişiyle sohbeti etkilemez
  /// (D-026: genel etkileşim kotası yoktur). Yaş değişince sıfırlanır.
  final Map<String, int> interactionCounts;

  static String interactionKey(String personId, String kindName) =>
      '$personId|$kindName';

  int interactionCount(String personId, String kindName) =>
      interactionCounts[interactionKey(personId, kindName)] ?? 0;

  /// Bir kişiyle **oyun içinde** en son hangi yaşta anlamlı temas kurulduğu.
  /// Gerçek dünya saati değil, oyun ilerleyişi ölçüsüdür (D-024, D-025).
  final Map<String, int> lastInteractionAge;

  /// Geçmiş seçimlerin bıraktığı izler (D-008).
  final Set<String> storyFlags;

  /// Sahip olunan varlıklar; olmayan varlık için olay çıkmaz.
  final Set<String> possessions;

  /// Bu hayatta görülmüş olaylar; tekrarlanabilir olmayanlar bir kez çıkar.
  final Set<String> seenEventIds;

  /// Tekrarlanabilir olayların **en son hangi yaşta** çıktığı:
  /// `'<olayKimliği>' -> yaş`.
  ///
  /// Tekrar aralığı buradan denetlenir; böylece bayram sabahı gibi doğal
  /// olarak tekrar eden olaylar art arda değil, uygun yaş farkıyla gelir
  /// (bkz. [GameEvent.minAgeGap]).
  final Map<String, int> lastEventAge;

  /// Hikâye rolüne kilitlenmiş kişiler: `'<rol>' -> kişiKimliği`.
  ///
  /// Bir olayda kim olduğu belirlenen kişi (ör. teneffüste savunduğun
  /// arkadaş) yıllar sonraki devam olayında **aynı kimlikle** kullanılır;
  /// olmayan bir kişi uydurulmaz.
  final Map<String, String> storyPeople;

  /// Gerçekleşmiş hediyeleşmeler: kim, kime, ne verdi.
  ///
  /// Yalnızca gerçekten el değiştiren hediyeler yazılır; reddedilen istek
  /// buraya girmez.
  final List<GiftRecord> gifts;

  /// Oyuncunun karşısındaki tek olay. Aynı anda ikinci bir olay açılmaz
  /// (D-021): bu alan doluyken yeni olay üretilmez.
  final ActiveEvent? pendingEvent;

  /// Son olaydan bu yana yapılan anlamlı oyun içi ilerleme adımı sayısı.
  final int progressSinceLastEvent;

  /// İçinde bulunulan yaşta açılış olayından **sonra** çıkan ek olay sayısı.
  final int extraEventsThisAge;

  /// Oyuncunun eğitim durumu. Öğrencilik yaştan türetilmez (bkz.
  /// [EducationState]); olay uygunluğu bu veriye bakar.
  final EducationState education;

  bool get hasPendingEvent => pendingEvent != null;

  List<Person> get livingPeople =>
      people.where((Person p) => p.isAlive).toList(growable: false);

  /// Oyuncuyla aynı evde yaşayan, hayattaki kişiler.
  List<Person> get household => people
      .where((Person p) => p.isAlive && p.inPlayerHousehold)
      .toList(growable: false);

  Person? personById(String id) {
    for (final Person person in people) {
      if (person.id == id) return person;
    }
    return null;
  }

  List<Person> byGroup(RelationGroup group) => people
      .where((Person p) => p.relation.group == group)
      .toList(growable: false);

  /// Şu anda devam edilen **sınıftaki** arkadaşlar.
  ///
  /// Liste okul bağına ve **sınıf kimliğine** bakar, yakınlık derecesine
  /// değil: aynı sınıftaki bir kişi yakın arkadaş olsa da burada kalır.
  /// Kademe değişince eski sınıf arkadaşları **silinmez**; yalnızca güncel
  /// listeye girmezler (D-029: kişi kaydı korunur).
  List<Person> get currentClassmates => people
      .where((Person p) => p.isClassmateIn(education.classId))
      .toList(growable: false);

  /// Şu anda devam edilen **okuldaki** öğretmenler.
  List<Person> get currentTeachers => people
      .where((Person p) => p.isTeacherIn(education.schoolId))
      .toList(growable: false);

  /// Geçmişte tanışılmış, artık güncel sınıfta/okulda olmayan okul kişileri.
  ///
  /// Yakın arkadaş olmuş biri de buraya düşebilir; kaydı korunur ve ileride
  /// yeniden karşılaşma mümkündür.
  List<Person> get pastSchoolPeople => people
      .where((Person p) =>
          p.schoolTie != null &&
          !p.isClassmateIn(education.classId) &&
          !p.isTeacherIn(education.schoolId))
      .toList(growable: false);

  /// Oyuncunun **şu anki hayatında gerçekten erişebildiği** kişiler.
  ///
  /// Gündelik etkileşim listeleri bunu kullanır. Yıllar önce tanışılmış bir
  /// ilkokul öğretmeni, hayatta kalmaya devam etse bile her gün görüşülen
  /// biri değildir; kaydı silinmez ama gündelik listeye girmez. Yeniden
  /// karşılaşma ileride özel bir olayla mümkün olacak.
  List<Person> get reachablePeople =>
      people.where(isReachable).toList(growable: false);

  /// Bir kişi şu an gündelik hayatta erişilebilir mi?
  bool isReachable(Person person) {
    if (!person.isAlive) return false;
    // Aynı evde yaşayanlar her zaman erişilebilir.
    if (person.inPlayerHousehold) return true;
    // Güncel okul çevresi.
    if (person.isClassmateIn(education.classId)) return true;
    if (person.isTeacherIn(education.schoolId)) return true;
    // Yakın arkadaşlar ve romantik bağlar görüşmeye devam eder.
    switch (person.relation) {
      case RelationType.arkadas:
      case RelationType.sevgili:
        return true;
      default:
        break;
    }
    // Hane dışındaki yakın akrabalar (anne/baba/kardeş) görüşülmeye devam
    // eder; uzak akrabalar bayram/ziyaret olaylarıyla gelir.
    return person.relation == RelationType.anne ||
        person.relation == RelationType.baba ||
        person.relation == RelationType.kardes;
  }

  GameState copyWith({
    PlayerCharacter? player,
    List<Person>? people,
    List<Pet>? pets,
    ParentalStatus? parentalStatus,
    List<LifeLogEntry>? log,
    Map<String, int>? interactionCounts,
    Map<String, int>? lastInteractionAge,
    Set<String>? storyFlags,
    Set<String>? possessions,
    Set<String>? seenEventIds,
    Map<String, int>? lastEventAge,
    Map<String, String>? storyPeople,
    List<GiftRecord>? gifts,
    Object? pendingEvent = _unsetEvent,
    int? progressSinceLastEvent,
    int? extraEventsThisAge,
    EducationState? education,
  }) {
    return GameState(
      seed: seed,
      player: player ?? this.player,
      people: people ?? this.people,
      pets: pets ?? this.pets,
      parentalStatus: parentalStatus ?? this.parentalStatus,
      log: log ?? this.log,
      interactionCounts: interactionCounts ?? this.interactionCounts,
      lastInteractionAge: lastInteractionAge ?? this.lastInteractionAge,
      storyFlags: storyFlags ?? this.storyFlags,
      possessions: possessions ?? this.possessions,
      seenEventIds: seenEventIds ?? this.seenEventIds,
      lastEventAge: lastEventAge ?? this.lastEventAge,
      storyPeople: storyPeople ?? this.storyPeople,
      gifts: gifts ?? this.gifts,
      pendingEvent: pendingEvent == _unsetEvent
          ? this.pendingEvent
          : pendingEvent as ActiveEvent?,
      progressSinceLastEvent:
          progressSinceLastEvent ?? this.progressSinceLastEvent,
      extraEventsThisAge: extraEventsThisAge ?? this.extraEventsThisAge,
      education: education ?? this.education,
    );
  }
}

const Object _unsetEvent = Object();

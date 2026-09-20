/// Oyun durumunun kayıt dosyası için JSON'a çevrilmesi ve geri okunması.
///
/// Kural: **ekrandaki her şeyin kaynağı olan `GameState` eksiksiz yazılır.**
/// Kişi kimlikleri, okul bağları, hikâye rolleri ve bekleyen olay olduğu
/// gibi saklanır; yüklerken hiçbir şey yeniden rastgele üretilmez.
///
/// Enum değerleri **adlarıyla** yazılır (sıra numarasıyla değil); böylece
/// ileride enum sırası değişse bile eski kayıtlar bozulmaz.
library;

import '../../domain/models/education.dart';
import '../../domain/models/game_event.dart';
import '../../domain/models/game_state.dart';
import '../../domain/models/gender.dart';
import '../../domain/models/gift_record.dart';
import '../../domain/models/life_log.dart';
import '../../domain/models/parental_status.dart';
import '../../domain/models/person.dart';
import '../../domain/models/player_character.dart';
import '../../domain/models/relation.dart';
import '../../domain/models/stats.dart';
import '../../domain/models/wealth.dart';
import 'save_format.dart';

// =====================================================================
// Yazma
// =====================================================================

Map<String, Object?> encodeGameState(GameState state) => <String, Object?>{
      'seed': state.seed,
      'player': _encodePlayer(state.player),
      'people': state.people.map(_encodePerson).toList(growable: false),
      'pets': state.pets.map(_encodePet).toList(growable: false),
      'parentalStatus': state.parentalStatus.name,
      'log': state.log.map(_encodeLogEntry).toList(growable: false),
      'interactionCounts': state.interactionCounts,
      'lastInteractionAge': state.lastInteractionAge,
      'storyFlags': state.storyFlags.toList(growable: false),
      'possessions': state.possessions.toList(growable: false),
      'seenEventIds': state.seenEventIds.toList(growable: false),
      'lastEventAge': state.lastEventAge,
      'storyPeople': state.storyPeople,
      'gifts': state.gifts.map(_encodeGift).toList(growable: false),
      'pendingEvent': state.pendingEvent == null
          ? null
          : _encodeActiveEvent(state.pendingEvent!),
      'progressSinceLastEvent': state.progressSinceLastEvent,
      'extraEventsThisAge': state.extraEventsThisAge,
      'education': _encodeEducation(state.education),
    };

Map<String, Object?> _encodePlayer(PlayerCharacter p) => <String, Object?>{
      'id': p.id,
      'firstName': p.firstName,
      'lastName': p.lastName,
      'gender': p.gender.name,
      'age': p.age,
      'birthCity': p.birthCity,
      'stats': <String, Object?>{
        'appearance': p.stats.appearance,
        'happiness': p.stats.happiness,
        'health': p.stats.health,
        'intelligence': p.stats.intelligence,
        'charisma': p.stats.charisma,
      },
      'fame': p.fame,
      'wallet': p.wallet,
    };

Map<String, Object?> _encodePerson(Person p) => <String, Object?>{
      'id': p.id,
      'firstName': p.firstName,
      'lastName': p.lastName,
      'gender': p.gender.name,
      'relation': p.relation.name,
      'age': p.age,
      'isAlive': p.isAlive,
      'inPlayerHousehold': p.inPlayerHousehold,
      'employment': p.employment.name,
      'occupation': p.occupation,
      'wealth': p.wealth?.name,
      'bond': p.bond,
      'schoolLevel': p.schoolLevel?.name,
      'schoolTie': p.schoolTie?.name,
      'schoolId': p.schoolId,
      'classId': p.classId,
    };

Map<String, Object?> _encodeGift(GiftRecord g) => <String, Object?>{
      'itemId': g.itemId,
      'fromId': g.fromId,
      'toId': g.toId,
      'age': g.age,
    };

Map<String, Object?> _encodePet(Pet pet) => <String, Object?>{
      'id': pet.id,
      'name': pet.name,
      'species': pet.species,
    };

Map<String, Object?> _encodeLogEntry(LifeLogEntry e) => <String, Object?>{
      'age': e.age,
      'text': e.text,
      'category': e.category.name,
    };

Map<String, Object?> _encodeEducation(EducationState e) => <String, Object?>{
      'enrolled': e.enrolled,
      'grade': e.grade,
      'startedAtAge': e.startedAtAge,
      'finished': e.finished,
      'schoolId': e.schoolId,
      'classId': e.classId,
    };

/// Bekleyen olay **tüm seçenekleriyle** yazılır.
///
/// Böylece uygulama yeniden açıldığında olay havuzdan yeniden üretilmez:
/// aynı metin, aynı kişi ve aynı seçenekler geri gelir. Olay havuzu
/// güncellense bile oyuncunun ekranındaki soru değişmez.
Map<String, Object?> _encodeActiveEvent(ActiveEvent e) => <String, Object?>{
      'eventId': e.eventId,
      'category': e.category.name,
      'text': e.text,
      'personId': e.personId,
      'choices': e.choices.map(_encodeChoice).toList(growable: false),
    };

Map<String, Object?> _encodeChoice(EventChoice c) => <String, Object?>{
      'id': c.id,
      'label': c.label,
      'resultText': c.resultText,
      'happiness': c.happiness,
      'health': c.health,
      'intelligence': c.intelligence,
      'charisma': c.charisma,
      'appearance': c.appearance,
      'bond': c.bond,
      'money': c.money,
      'addFlags': c.addFlags.toList(growable: false),
      'removeFlags': c.removeFlags.toList(growable: false),
      'addPossessions': c.addPossessions.toList(growable: false),
      'startsRomance': c.startsRomance,
      'endsRomance': c.endsRomance,
      'startsSchoolFriendship': c.startsSchoolFriendship,
      'rememberPersonAs': c.rememberPersonAs,
    };

// =====================================================================
// Okuma
// =====================================================================

GameState decodeGameState(Map<String, Object?> json) {
  final PlayerCharacter player =
      _decodePlayer(_map(json, 'player'), 'player');

  final List<Person> people = _list(json, 'people')
      .map((Object? e) => _decodePerson(_asMap(e, 'people[]')))
      .toList(growable: false);

  // Aynı kimlikten iki kayıt, aynı kişinin ikiye bölünmesi demektir.
  final Set<String> gorulenKimlikler = <String>{};
  for (final Person p in people) {
    if (!gorulenKimlikler.add(p.id)) {
      throw SaveFormatException(
        'Kayıtta aynı kişi kimliği birden fazla kez geçiyor: ${p.id}',
      );
    }
  }

  final Object? pending = json['pendingEvent'];

  return GameState(
    seed: _int(json, 'seed'),
    player: player,
    people: List<Person>.unmodifiable(people),
    pets: List<Pet>.unmodifiable(
      _list(json, 'pets')
          .map((Object? e) => _decodePet(_asMap(e, 'pets[]')))
          .toList(growable: false),
    ),
    parentalStatus: _enumByName(
      ParentalStatus.values,
      _string(json, 'parentalStatus'),
      'parentalStatus',
    ),
    log: List<LifeLogEntry>.unmodifiable(
      _list(json, 'log')
          .map((Object? e) => _decodeLogEntry(_asMap(e, 'log[]')))
          .toList(growable: false),
    ),
    interactionCounts:
        Map<String, int>.unmodifiable(_intMap(json, 'interactionCounts')),
    lastInteractionAge:
        Map<String, int>.unmodifiable(_intMap(json, 'lastInteractionAge')),
    storyFlags: Set<String>.unmodifiable(_stringSet(json, 'storyFlags')),
    possessions: Set<String>.unmodifiable(_stringSet(json, 'possessions')),
    seenEventIds: Set<String>.unmodifiable(_stringSet(json, 'seenEventIds')),
    lastEventAge: Map<String, int>.unmodifiable(_intMap(json, 'lastEventAge')),
    storyPeople: Map<String, String>.unmodifiable(
      _stringMap(json, 'storyPeople'),
    ),
    // Eski kayıtlarda hediye geçmişi yoktur; boş liste ile açılır.
    gifts: List<GiftRecord>.unmodifiable(
      json['gifts'] == null
          ? const <GiftRecord>[]
          : _list(json, 'gifts')
              .map((Object? e) => _decodeGift(_asMap(e, 'gifts[]')))
              .toList(growable: false),
    ),
    pendingEvent: pending == null
        ? null
        : _decodeActiveEvent(_asMap(pending, 'pendingEvent')),
    progressSinceLastEvent: _int(json, 'progressSinceLastEvent'),
    extraEventsThisAge: _int(json, 'extraEventsThisAge'),
    education: _decodeEducation(_map(json, 'education')),
  );
}

PlayerCharacter _decodePlayer(Map<String, Object?> json, String path) {
  final Map<String, Object?> stats = _map(json, 'stats');
  return PlayerCharacter(
    id: _string(json, 'id'),
    firstName: _string(json, 'firstName'),
    lastName: _string(json, 'lastName'),
    gender: _enumByName(Gender.values, _string(json, 'gender'), '$path.gender'),
    age: _int(json, 'age'),
    birthCity: _string(json, 'birthCity'),
    stats: Stats(
      appearance: _int(stats, 'appearance'),
      happiness: _int(stats, 'happiness'),
      health: _int(stats, 'health'),
      intelligence: _int(stats, 'intelligence'),
      charisma: _int(stats, 'charisma'),
    ),
    fame: _intOrNull(json, 'fame'),
    wallet: _int(json, 'wallet'),
  );
}

Person _decodePerson(Map<String, Object?> json) {
  final EmploymentStatus employment = _enumByName(
    EmploymentStatus.values,
    _string(json, 'employment'),
    'person.employment',
  );
  final String? occupation = _stringOrNull(json, 'occupation');
  if (occupation != null && employment != EmploymentStatus.calisiyor) {
    // Model bu durumu zaten reddeder; hatayı anlaşılır biçimde bildir.
    throw SaveFormatException(
      'Kayıtta tutarsız kişi: çalışmayan birine meslek yazılmış '
      '(${_string(json, 'id')}).',
    );
  }
  return Person(
    id: _string(json, 'id'),
    firstName: _string(json, 'firstName'),
    lastName: _string(json, 'lastName'),
    gender: _enumByName(Gender.values, _string(json, 'gender'), 'person.gender'),
    relation: _enumByName(
      RelationType.values,
      _string(json, 'relation'),
      'person.relation',
    ),
    age: _int(json, 'age'),
    isAlive: _bool(json, 'isAlive'),
    inPlayerHousehold: _bool(json, 'inPlayerHousehold'),
    employment: employment,
    occupation: occupation,
    wealth: _enumByNameOrNull(
      WealthTier.values,
      _stringOrNull(json, 'wealth'),
      'person.wealth',
    ),
    bond: _int(json, 'bond'),
    schoolLevel: _enumByNameOrNull(
      SchoolLevel.values,
      _stringOrNull(json, 'schoolLevel'),
      'person.schoolLevel',
    ),
    schoolTie: _enumByNameOrNull(
      SchoolTie.values,
      _stringOrNull(json, 'schoolTie'),
      'person.schoolTie',
    ),
    schoolId: _stringOrNull(json, 'schoolId'),
    classId: _stringOrNull(json, 'classId'),
  );
}

GiftRecord _decodeGift(Map<String, Object?> json) => GiftRecord(
      itemId: _string(json, 'itemId'),
      fromId: _string(json, 'fromId'),
      toId: _string(json, 'toId'),
      age: _int(json, 'age'),
    );

Pet _decodePet(Map<String, Object?> json) => Pet(
      id: _string(json, 'id'),
      name: _string(json, 'name'),
      species: _string(json, 'species'),
    );

LifeLogEntry _decodeLogEntry(Map<String, Object?> json) => LifeLogEntry(
      age: _int(json, 'age'),
      text: _string(json, 'text'),
      category: _enumByName(
        LogCategory.values,
        _string(json, 'category'),
        'log.category',
      ),
    );

EducationState _decodeEducation(Map<String, Object?> json) {
  final bool enrolled = _bool(json, 'enrolled');
  final int? grade = _intOrNull(json, 'grade');
  if (enrolled && grade == null) {
    throw const SaveFormatException(
      'Kayıttaki eğitim bilgisi tutarsız: okula kayıtlı görünen karakterin '
      'sınıfı yok.',
    );
  }
  return EducationState(
    enrolled: enrolled,
    grade: grade,
    startedAtAge: _intOrNull(json, 'startedAtAge'),
    finished: _bool(json, 'finished'),
    schoolId: _stringOrNull(json, 'schoolId'),
    classId: _stringOrNull(json, 'classId'),
  );
}

ActiveEvent _decodeActiveEvent(Map<String, Object?> json) {
  final List<EventChoice> choices = _list(json, 'choices')
      .map((Object? e) => _decodeChoice(_asMap(e, 'choices[]')))
      .toList(growable: false);
  if (choices.isEmpty) {
    throw const SaveFormatException(
      'Kayıttaki bekleyen olayın hiç seçeneği yok.',
    );
  }
  return ActiveEvent(
    eventId: _string(json, 'eventId'),
    category: _enumByName(
      EventCategory.values,
      _string(json, 'category'),
      'pendingEvent.category',
    ),
    text: _string(json, 'text'),
    choices: List<EventChoice>.unmodifiable(choices),
    personId: _stringOrNull(json, 'personId'),
  );
}

EventChoice _decodeChoice(Map<String, Object?> json) => EventChoice(
      id: _string(json, 'id'),
      label: _string(json, 'label'),
      resultText: _string(json, 'resultText'),
      happiness: _int(json, 'happiness'),
      health: _int(json, 'health'),
      intelligence: _int(json, 'intelligence'),
      charisma: _int(json, 'charisma'),
      appearance: _int(json, 'appearance'),
      bond: _int(json, 'bond'),
      money: _int(json, 'money'),
      addFlags: Set<String>.unmodifiable(_stringSet(json, 'addFlags')),
      removeFlags: Set<String>.unmodifiable(_stringSet(json, 'removeFlags')),
      addPossessions:
          Set<String>.unmodifiable(_stringSet(json, 'addPossessions')),
      startsRomance: _bool(json, 'startsRomance'),
      endsRomance: _bool(json, 'endsRomance'),
      startsSchoolFriendship: _bool(json, 'startsSchoolFriendship'),
      rememberPersonAs: _stringOrNull(json, 'rememberPersonAs'),
    );

// =====================================================================
// Küçük okuma yardımcıları
//
// Her biri eksik/yanlış türde alanı `SaveFormatException` ile bildirir;
// böylece bozuk kayıt uygulamayı çökertmez.
// =====================================================================

Never _eksik(String key, String beklenen) => throw SaveFormatException(
      'Kayıtta "$key" alanı eksik veya beklenen türde değil ($beklenen).',
    );

Map<String, Object?> _asMap(Object? value, String key) {
  if (value is Map) {
    return value.map<String, Object?>(
      (Object? k, Object? v) => MapEntry<String, Object?>('$k', v),
    );
  }
  _eksik(key, 'nesne');
}

Map<String, Object?> _map(Map<String, Object?> json, String key) =>
    _asMap(json[key], key);

List<Object?> _list(Map<String, Object?> json, String key) {
  final Object? value = json[key];
  if (value is List) return value;
  _eksik(key, 'liste');
}

String _string(Map<String, Object?> json, String key) {
  final Object? value = json[key];
  if (value is String) return value;
  _eksik(key, 'metin');
}

String? _stringOrNull(Map<String, Object?> json, String key) {
  final Object? value = json[key];
  if (value == null) return null;
  if (value is String) return value;
  _eksik(key, 'metin veya boş');
}

int _int(Map<String, Object?> json, String key) {
  final Object? value = json[key];
  if (value is int) return value;
  _eksik(key, 'tam sayı');
}

int? _intOrNull(Map<String, Object?> json, String key) {
  final Object? value = json[key];
  if (value == null) return null;
  if (value is int) return value;
  _eksik(key, 'tam sayı veya boş');
}

bool _bool(Map<String, Object?> json, String key) {
  final Object? value = json[key];
  if (value is bool) return value;
  _eksik(key, 'evet/hayır');
}

Set<String> _stringSet(Map<String, Object?> json, String key) {
  final Set<String> sonuc = <String>{};
  for (final Object? e in _list(json, key)) {
    if (e is! String) _eksik(key, 'metin listesi');
    sonuc.add(e);
  }
  return sonuc;
}

Map<String, int> _intMap(Map<String, Object?> json, String key) {
  final Map<String, Object?> ham = _map(json, key);
  final Map<String, int> sonuc = <String, int>{};
  ham.forEach((String k, Object? v) {
    if (v is! int) _eksik('$key.$k', 'tam sayı');
    sonuc[k] = v;
  });
  return sonuc;
}

Map<String, String> _stringMap(Map<String, Object?> json, String key) {
  final Map<String, Object?> ham = _map(json, key);
  final Map<String, String> sonuc = <String, String>{};
  ham.forEach((String k, Object? v) {
    if (v is! String) _eksik('$key.$k', 'metin');
    sonuc[k] = v;
  });
  return sonuc;
}

T _enumByName<T extends Enum>(List<T> values, String name, String key) {
  for (final T value in values) {
    if (value.name == name) return value;
  }
  throw SaveFormatException(
    'Kayıtta tanınmayan değer: "$name" ($key). Kayıt, oyunun daha yeni bir '
    'sürümünden gelmiş olabilir.',
  );
}

T? _enumByNameOrNull<T extends Enum>(
  List<T> values,
  String? name,
  String key,
) =>
    name == null ? null : _enumByName(values, name, key);

import 'dart:math';

import '../../data/event_pool.dart';
import '../../data/item_catalog.dart';
import '../../text/turkish_text.dart';
import '../generation/random_util.dart';
import '../interaction/friendship.dart';
import '../interaction/romance.dart';
import '../models/game_event.dart';
import '../activities/travel.dart';
import '../models/game_state.dart';
import '../models/trip.dart';
import '../models/life_log.dart';
import '../models/owned_item.dart';
import '../models/person.dart';
import '../models/player_character.dart';
import '../models/stats.dart';

/// Olay motoru (D-009, D-021, D-022, D-023, D-024).
///
/// Kurallar:
/// - Yaş alındığında **ilk olarak yalnızca tek** uygun olay çıkar; aynı anda
///   ikinci bir olay penceresi açılmaz.
/// - Bir olayın çıkabilmesi için yaş **ve** diğer koşullar sağlanmalıdır:
///   olayın kişisi yaşıyor olmalı, gereken hikâye izi bulunmalı, sahip
///   olunmayan varlık için olay üretilmemelidir.
/// - Ek olaylar **gerçek dünya dakikasıyla değil**, oyuncunun oyun içindeki
///   anlamlı ilerlemesiyle gelir. Bu prototipte tempo bilerek dar tutulmuştur
///   (aşağıdaki `prototypeOnly` değerler); kesin tempo algoritması henüz
///   kararlaştırılmadı.
class EventEngine {
  const EventEngine({this.pool = kEventPool});

  final List<GameEvent> pool;

  /// Bir yaş içinde açılış olayından sonra çıkabilecek **en fazla** ek olay.
  static const int prototypeOnlyMaxExtraEventsPerAge = 1;

  /// Ek olayın açılması için gereken anlamlı ilerleme adımı sayısı.
  static const int prototypeOnlyProgressPerExtraEvent = 3;

  /// Bir yakının sitem edebilmesi için geçmesi gereken **oyun içi** yaş farkı.
  static const int prototypeOnlyNeglectAgeGap = 3;

  /// Yeni yaşın tek açılış olayı (D-021). Uygun olay yoksa `null`.
  ActiveEvent? openingEvent(GameState state, Random rng) =>
      _pick(state, rng);

  /// Oyun içi ilerlemeye bağlı ek olay (D-023, D-024).
  ///
  /// Yalnızca yeterli ilerleme biriktiyse, bu yaşın ek olay sınırı dolmadıysa
  /// ve ekranda başka olay yokken çıkar.
  ActiveEvent? progressEvent(GameState state, Random rng) {
    if (state.hasPendingEvent) return null;
    if (state.extraEventsThisAge >= prototypeOnlyMaxExtraEventsPerAge) return null;
    if (state.progressSinceLastEvent < prototypeOnlyProgressPerExtraEvent) {
      return null;
    }
    return _pick(state, rng);
  }

  /// Uygun olaylar arasından ağırlıklı seçim yapar ve kişisini çözer.
  ActiveEvent? _pick(GameState state, Random rng) {
    final List<_Candidate> candidates = <_Candidate>[];
    for (final GameEvent event in pool) {
      if (!event.repeatable && state.seenEventIds.contains(event.id)) continue;
      if (!_repeatGapPassed(state, event)) continue;
      final Person? person = _resolvePerson(state, event, rng);
      if (!_matches(state, event, person)) continue;
      candidates.add(_Candidate(event, person));
    }
    if (candidates.isEmpty) return null;

    final _Candidate chosen = rng.pickWeighted(
      candidates,
      candidates.map((_Candidate c) => c.event.weight.toDouble()).toList(),
    );
    return _toActive(state, chosen);
  }

  /// Olayın koşullarını denetler. Kişi gerekiyorsa [person] dolu olmalıdır.
  bool _matches(GameState state, GameEvent event, Person? person) {
    final EventRequirement req = event.requirement;
    final int age = state.player.age;

    if (age < req.minAge || age > req.maxAge) return false;
    // Öğrencilik yaştan değil, eğitim durumundan okunur.
    if (req.requiresSchoolStudent && !state.education.isSchoolStudent) {
      return false;
    }
    final int? grade = state.education.grade;
    if (req.minGrade != null && (grade == null || grade < req.minGrade!)) {
      return false;
    }
    if (req.maxGrade != null && (grade == null || grade > req.maxGrade!)) {
      return false;
    }
    // Kişi gerektiren olay, uygun kişi bulunamadıysa elenir: aksi hâlde
    // metindeki yer tutucular boş kalır ve olmayan kişiyle olay çıkar.
    if (_needsPerson(req) && person == null) return false;
    if (!state.storyFlags.containsAll(req.requiredFlags)) return false;
    if (req.forbiddenFlags.any(state.storyFlags.contains)) return false;
    if (!state.possessions.containsAll(req.requiredPossessions)) return false;
    // "Herhangi bir araba/konut" koşulu: eşyanın çeşidine bakılır, tek bir
    // ürün kimliğine bağlanmaz.
    for (final ItemKind kind in req.requiredPossessionKinds) {
      final bool varMi = state.items.any(
        (OwnedItem i) => itemTypeOrFallback(i.typeId).kind == kind,
      );
      if (!varMi) return false;
    }
    // Ehliyet ve sosyal medya hesabı: olmayan şeyle olay kurulmaz.
    if (!state.licenses.containsAll(req.requiredLicenses)) return false;
    if (req.requiresSocialAccount && state.socialAccounts.isEmpty) {
      return false;
    }
    // Ün gerektiren olaylar: kitle gerçekten oluşmadan çıkmaz.
    if (req.minFame > 0 && (state.player.fame ?? 0) < req.minFame) {
      return false;
    }
    // Emeklilik olayları yalnızca gerçekten emekli olana çıkar.
    if (req.requiresRetired && !state.career.isRetired) return false;
    // İş hayatı olayları yalnızca gerçekten çalışan oyuncuya çıkar.
    if (req.requiresEmployed && !state.career.isEmployed) return false;
    if (req.requiresMinYearsInJob > 0 &&
        state.career.yearsInJob(state.player.age) <
            req.requiresMinYearsInJob) {
      return false;
    }
    // Gündelik erişilebilirlik isteyen olaylarda kişi gerçekten
    // ulaşılabilir olmalı.
    if (req.requireReachable && person != null && !state.isReachable(person)) {
      return false;
    }
    return true;
  }

  /// Tekrarlanabilir olayın yeniden çıkabilmesi için yeterli yaş farkı
  /// geçmiş mi? Böylece aynı olay arka arkaya gelmez ama sonsuza dek de
  /// yasaklanmaz.
  static bool _repeatGapPassed(GameState state, GameEvent event) {
    final int? last = state.lastEventAge[event.id];
    if (last == null) return true;
    return state.player.age - last >= event.minAgeGap;
  }

  static bool _needsPerson(EventRequirement req) =>
      req.livingRelations.isNotEmpty ||
      req.requiresNeglectedRelative ||
      req.requiresTripMemory ||
      req.personRole != null;

  /// Olayın kişisini seçer; uygun kişi yoksa `null` döner ve olay elenir.
  Person? _resolvePerson(GameState state, GameEvent event, Random rng) {
    final EventRequirement req = event.requirement;

    // Gezi anısı: olayın kişisi, yıllar önce birlikte yola çıktığın
    // kişidir. Gezi yoksa ya da kişi vefat ettiyse olay çıkmaz.
    if (req.requiresTripMemory) {
      final TripRecord? gezi = Travel.memorableTrip(state);
      if (gezi == null) return null;
      return state.personById(gezi.companionId!);
    }

    // Hikâyede kilitlenmiş kişi: yıllar sonra da aynı kimlik kullanılır.
    final String? role = req.personRole;
    if (role != null) {
      final String? personId = state.storyPeople[role];
      if (personId == null) return null;
      final Person? person = state.personById(personId);
      if (person == null || !person.isAlive) return null;
      if (req.personMinAge != null && person.age < req.personMinAge!) {
        return null;
      }
      if (req.personMaxAge != null && person.age > req.personMaxAge!) {
        return null;
      }
      return person;
    }

    if (req.requiresNeglectedRelative) {
      final List<Person> neglected = state.people.where((Person p) {
        if (!p.isAlive) return false;
        if (req.requireSameHousehold && !p.inPlayerHousehold) return false;
        final int? last = state.lastInteractionAge[p.id];
        if (last == null) {
          // Hiç temas kurulmamışsa, oyuncunun etkileşim kurabildiği yaştan
          // itibaren sayılır.
          return state.player.age >= req.minAge + prototypeOnlyNeglectAgeGap;
        }
        return state.player.age - last >= prototypeOnlyNeglectAgeGap;
      }).toList(growable: false);
      if (neglected.isEmpty) return null;
      return neglected[rng.nextInt(neglected.length)];
    }

    if (req.livingRelations.isEmpty) return null;

    final List<Person> uygun = state.people.where((Person p) {
      if (!p.isAlive) return false;
      if (!req.livingRelations.contains(p.relation)) return false;
      if (req.requireSameHousehold && !p.inPlayerHousehold) return false;
      if (req.requireOutsideHousehold && p.inPlayerHousehold) return false;
      // Kişinin kendi yaşı: çocuk olayları doğru yaşa bağlanır.
      if (req.personMinAge != null && p.age < req.personMinAge!) return false;
      if (req.personMaxAge != null && p.age > req.personMaxAge!) return false;
      return true;
    }).toList(growable: false);
    if (uygun.isEmpty) return null;
    return uygun[rng.nextInt(uygun.length)];
  }

  ActiveEvent _toActive(GameState state, _Candidate candidate) {
    return ActiveEvent(
      eventId: candidate.event.id,
      category: candidate.event.category,
      text: _fillTrip(
        _fill(candidate.event.text, candidate.person, state.player.age),
        state,
        candidate.event,
      ),
      // Seçenek etiketlerindeki yer tutucular da doldurulur; ekranda
      // "{kisi}" yazmaz.
      choices: List<EventChoice>.unmodifiable(<EventChoice>[
        for (final EventChoice c in candidate.event.choices)
          if (c.label.contains('{'))
            c.withLabel(_fill(c.label, candidate.person, state.player.age))
          else
            c,
      ]),
      personId: candidate.person?.id,
    );
  }

  /// Gezi anısı olaylarında `{sehir}` yer tutucusunu gerçek gezi
  /// kaydından doldurur; uydurma şehir yazılmaz.
  static String _fillTrip(String text, GameState state, GameEvent event) {
    if (!event.requirement.requiresTripMemory) return text;
    final TripRecord? gezi = Travel.memorableTrip(state);
    if (gezi == null) return text;
    return text.replaceAll('{sehir}', gezi.city);
  }

  /// Metindeki yer tutucuları **gerçekten var olan** kişiyle doldurur.
  ///
  /// - `{kisi}`   : kişinin adı ("Kemal")
  /// - `{sahip}`  : cümle başındaki iyelikli bağ ("Deden")
  /// - `{sahipk}` : cümle içindeki iyelikli bağ ("deden")
  /// - `{bag}`    : yalın bağ etiketi ("dede")
  ///
  /// Kişi yoksa metin olduğu gibi döner; kişi gerektiren olaylar zaten
  /// [_matches] tarafından elendiği için ekrana boş yer tutucu çıkmaz.
  static String _fill(String template, Person? person, int playerAge) {
    if (person == null) return template;
    final String sahip = person.possessiveFor(playerAge);
    return template
        .replaceAll('{kisi}', person.firstName)
        .replaceAll('{sahipk}', trLowerFirst(sahip))
        .replaceAll('{sahip}', sahip)
        .replaceAll('{bag}', person.labelFor(playerAge).toLowerCase());
  }

  /// Bekleyen olayı verilen seçimle çözer: etkileri uygular, izi bırakır,
  /// hayat günlüğüne yazar ve olayı ekrandan kaldırır.
  ///
  /// Romantik ilişki başlatan veya bitiren seçimler [Romance] üzerinden
  /// işlenir; kişi kimliği hiçbir aşamada değişmez.
  GameState resolve(GameState state, String choiceId, {Random? rng}) {
    final ActiveEvent? active = state.pendingEvent;
    if (active == null) return state;

    final EventChoice choice = active.choices.firstWhere(
      (EventChoice c) => c.id == choiceId,
      orElse: () => active.choices.first,
    );

    // İlişki başlatan seçim önce kişiyi oluşturur ki sonuç metni ve ilişki
    // etkisi doğru kişiye bağlansın.
    const Romance romance = Romance();
    GameState working = state;
    String? newPersonId;
    if (choice.startsRomance) {
      final ({GameState state, Person partner}) started =
          romance.start(working, rng ?? Random());
      working = started.state;
      newPersonId = started.partner.id;
    }
    // Okul arkadaşlığı: olayın kişisi varsa **aynı kimlikle** yakın arkadaşa
    // çevrilir; yoksa kalıcı kimlikli yeni bir arkadaş kaydı açılır.
    // Ün üzerinden tanışma: kişi yalnızca bu seçim yapılırsa üretilir.
    if (choice.startsFriendship) {
      const Friendship friendship = Friendship();
      final ({GameState state, Person friend}) started =
          friendship.startAcquaintance(working, rng ?? Random());
      working = started.state;
      newPersonId = started.friend.id;
    }
    if (choice.startsSchoolFriendship) {
      const Friendship friendship = Friendship();
      final String? adayId = active.personId;
      if (adayId != null && working.personById(adayId) != null) {
        working = friendship.promoteToFriend(working, adayId).state;
      } else {
        final ({GameState state, Person friend}) started =
            friendship.startSchoolFriend(working, rng ?? Random());
        working = started.state;
        newPersonId = started.friend.id;
      }
    }

    final Stats stats = working.player.stats.copyWith(
      happiness: working.player.stats.happiness + choice.happiness,
      health: working.player.stats.health + choice.health,
      intelligence: working.player.stats.intelligence + choice.intelligence,
      charisma: working.player.stats.charisma + choice.charisma,
      appearance: working.player.stats.appearance + choice.appearance,
    );
    final PlayerCharacter player = working.player.copyWith(
      stats: stats,
      // Cüzdan eksiye düşmez; borç/eksi bakiye kuralları kararlaştırılmadı.
      wallet: (working.player.wallet + choice.money).clamp(0, 1 << 31),
    );

    // Etki, olayın kişisine; ilişki başlatan seçimde yeni partnere işlenir.
    final String? bondTargetId = newPersonId ?? active.personId;
    final List<Person> people = bondTargetId == null || choice.bond == 0
        ? working.people
        : working.people
            .map(
              (Person p) => p.id == bondTargetId
                  ? p.copyWith(bond: (p.bond + choice.bond).clamp(0, 100))
                  : p,
            )
            .toList(growable: false);

    final Person? person = bondTargetId == null
        ? null
        : working.people.firstWhere((Person p) => p.id == bondTargetId);
    final String resultText = _fill(choice.resultText, person, working.player.age);

    working = working.copyWith(
      player: player,
      people: List<Person>.unmodifiable(people),
      storyFlags: <String>{
        ...working.storyFlags.where((String f) => !choice.removeFlags.contains(f)),
        ...choice.addFlags,
      },
      seenEventIds: <String>{...working.seenEventIds, active.eventId},
      // Tekrar aralığı denetimi için olayın çıktığı yaş kaydedilir.
      lastEventAge: <String, int>{
        ...working.lastEventAge,
        active.eventId: working.player.age,
      },
      // Seçim bir kişiyi hikâye rolüne kilitlediyse kimliği saklanır.
      storyPeople: choice.rememberPersonAs == null || bondTargetId == null
          ? working.storyPeople
          : <String, String>{
              ...working.storyPeople,
              choice.rememberPersonAs!: bondTargetId,
            },
      log: List<LifeLogEntry>.unmodifiable(<LifeLogEntry>[
        ...working.log,
        LifeLogEntry(
          age: working.player.age,
          text: resultText,
          category: LogCategory.kisisel,
          // Olay bir kişiyle kurulduysa günlük satırı o kişiye bağlanır
          // (Paket 14); ortak geçmiş bu bağdan okunur.
          personId: bondTargetId,
        ),
      ]),
      pendingEvent: null,
      // Olay çözüldü: ek olay için ilerleme yeniden birikmeye başlar.
      progressSinceLastEvent: 0,
    );

    // Olayla kazanılan eşyalar gerçek envanter örneği olarak eklenir.
    if (choice.addPossessions.isNotEmpty) {
      working = working.grantItems(
        choice.addPossessions,
        source: ItemSource.olay,
        fromPersonId: bondTargetId,
      );
    }

    // İlişkiyi bitiren seçim: kişi silinmez, aynı kimlikle eski sevgili olur.
    if (choice.endsRomance && active.personId != null) {
      working = romance.end(working, active.personId!, logText: null);
    }

    return working;
  }
}

class _Candidate {
  const _Candidate(this.event, this.person);

  final GameEvent event;
  final Person? person;
}

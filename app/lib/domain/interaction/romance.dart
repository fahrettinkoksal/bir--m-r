import 'dart:math';

import '../../data/name_pool.dart';
import '../generation/random_util.dart';
import '../models/game_state.dart';
import '../models/gender.dart';
import '../models/life_log.dart';
import '../models/person.dart';
import '../models/relation.dart';
import '../models/wealth.dart';

/// Romantik ilişkinin başlaması ve bitmesi (D-029, D-030).
///
/// Temel kural: **kişi kimliği hayat boyu değişmez.** İlişki bittiğinde kayıt
/// silinmez ve yeni kimlikle yeniden yaratılmaz; yalnızca bağ statüsü
/// `sevgili` → `eskiSevgili` olur. Geçmiş karşılaşmalar hayat günlüğünde,
/// yakınlık değeri kişinin kaydında kalır.
///
/// Romantik bağ **akrabalık değildir** ve **hane demek değildir**: oluşturulan
/// kişi oyuncunun evine yerleştirilmez.
class Romance {
  const Romance();

  /// İlişkinin bu hayatta kaçıncı kez kurulduğunu kimliğe yazar; böylece
  /// ileride birden fazla romantik kişi olsa da kimlikler çakışmaz.
  static String _nextId(GameState state) {
    final int mevcut = state.people
        .where((Person p) => !p.relation.kanBagi)
        .length;
    return 'romantik-${mevcut + 1}';
  }

  /// Şu an hayatta bir sevgili var mı?
  bool hasPartner(GameState state) => state.people.any(
        (Person p) => p.isAlive && p.relation == RelationType.sevgili,
      );

  Person? partnerOf(GameState state) {
    for (final Person p in state.people) {
      if (p.isAlive && p.relation == RelationType.sevgili) return p;
    }
    return null;
  }

  /// Yeni bir romantik ilişki başlatır ve kişiyi **sevgili** olarak ekler.
  ///
  /// Partnerin cinsiyeti bu prototipte oyuncunun cinsiyetinin karşıtı seçilir
  /// (`docs/PROTOTYPE_UI.md` §4'teki örneğe uygun). **Bu bir oyun tasarımı
  /// kararı değildir**; yönelim ve eşleşme kuralları Faho ile
  /// kararlaştırılacaktır. (prototypeOnly)
  ({GameState state, Person partner}) start(GameState state, Random rng) {
    final Gender gender =
        state.player.gender == Gender.kadin ? Gender.erkek : Gender.kadin;
    final int age = (state.player.age + rng.between(-2, 2)).clamp(15, 120);

    String lastName = rng.pick(soyisimler);
    while (lastName == state.player.lastName) {
      lastName = rng.pick(soyisimler);
    }

    // Meslek uydurulmaz: çalışmıyorsa meslek alanı boş kalır.
    final EmploymentStatus employment =
        age <= 22 ? EmploymentStatus.ogrenci : EmploymentStatus.calisiyor;

    final Person partner = Person(
      id: _nextId(state),
      firstName: rng.pick(gender == Gender.kadin ? kadinIsimleri : erkekIsimleri),
      lastName: lastName,
      gender: gender,
      relation: RelationType.sevgili,
      age: age,
      isAlive: true,
      // Sevgili olmak aynı evde yaşamak demek değildir.
      inPlayerHousehold: false,
      employment: employment,
      occupation: employment == EmploymentStatus.calisiyor
          ? rng.pick(meslekler)
          : null,
      wealth: age >= 18 ? WealthTier.ortaHalli : null,
      bond: rng.between(55, 70), // prototypeOnly
    );

    return (
      state: state.copyWith(
        people: List<Person>.unmodifiable(<Person>[...state.people, partner]),
      ),
      partner: partner,
    );
  }

  /// İlişkiyi bitirir: **aynı kimlik** eski sevgili statüsüne geçer.
  ///
  /// Kişi listeden çıkarılmaz, yakınlık değeri sıfırlanmaz, hayat günlüğü
  /// silinmez. Yalnızca [RelationType.sevgili] olan kişi etkilenir; diğer
  /// aile üyeleri değişmez.
  GameState end(GameState state, String personId, {String? logText}) {
    final Person? partner = state.personById(personId);
    if (partner == null || partner.relation != RelationType.sevgili) {
      return state;
    }

    final List<Person> people = state.people
        .map(
          (Person p) => p.id == personId
              ? p.copyWith(relation: RelationType.eskiSevgili)
              : p,
        )
        .toList(growable: false);

    final String text = logText ??
        '${partner.firstName} ile ayrıldınız. Adı hâlâ hayatında, '
            'statüsü değişti.';

    return state.copyWith(
      people: List<Person>.unmodifiable(people),
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
}

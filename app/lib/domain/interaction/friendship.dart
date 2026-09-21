import 'dart:math';

import '../../data/name_pool.dart';
import '../generation/random_util.dart';
import '../models/game_state.dart';
import '../models/gender.dart';
import '../models/person.dart';
import '../models/relation.dart';
import '../models/wealth.dart';

/// Arkadaşlıkların kurulması.
///
/// Okulda tanışılan kişi **kalıcı kimlikli gerçek bir kişi kaydı** olarak
/// oluşturulur; sonraki okul olayları, aile ekranı ve ileride eklenecek
/// sistemler (ör. sosyal medya) aynı kaydı kullanır
/// (`docs/APPROVED_SCOPE_AND_EVENT_STRATEGY.md`, GEN-001).
///
/// Arkadaşlık **akrabalık değildir** ve hane demek değildir.
class Friendship {
  const Friendship();

  /// Arkadaş kimliklerini çakışmadan üretir.
  static String _nextId(GameState state) {
    final Set<String> kullanilan = <String>{
      for (final Person p in state.people) p.id,
    };
    // Sayaç, arkadaşlığa dönüşen iş arkadaşlarını da sayabildiği için
    // kimliğin gerçekten boş olduğu doğrulanır.
    int sira = state.people
            .where((Person p) => p.relation == RelationType.arkadas)
            .length +
        1;
    while (kullanilan.contains('arkadas-$sira')) {
      sira++;
    }
    return 'arkadas-$sira';
  }

  bool hasSchoolFriend(GameState state) => state.people.any(
        (Person p) => p.isAlive && p.relation == RelationType.arkadas,
      );

  /// prototypeOnly: tanışıklıktan yakın arkadaşlığa geçişte eklenen yakınlık.
  static const int prototypeOnlyPromotionBond = 15;

  /// Var olan bir sınıf arkadaşını **aynı kimlikle** yakın arkadaşa çevirir.
  ///
  /// Kayıt silinip yenisi açılmaz; kişinin adı, geçmişi ve yakınlığı korunur.
  /// Okul kademesi bilgisi de kalır, böylece nerede tanışıldığı unutulmaz.
  ({GameState state, Person friend}) promoteToFriend(
    GameState state,
    String personId,
  ) {
    final Person? mevcut = state.personById(personId);
    if (mevcut == null) {
      throw ArgumentError.value(personId, 'personId', 'Kişi bulunamadı');
    }
    final Person friend = mevcut.copyWith(
      relation: RelationType.arkadas,
      bond: (mevcut.bond + prototypeOnlyPromotionBond).clamp(0, 100),
    );
    return (
      state: state.copyWith(
        people: List<Person>.unmodifiable(
          state.people
              .map((Person p) => p.id == personId ? friend : p)
              .toList(growable: false),
        ),
      ),
      friend: friend,
    );
  }

  /// Okuldan bir sınıf arkadaşı ekler ve oluşturulan kişiyi döndürür.
  ///
  /// Cinsiyet rastgeledir; arkadaşlıkta eşleşme kuralı yoktur. Yaş oyuncuyla
  /// aynı sınıfta olacak biçimde seçilir (prototypeOnly: ±1 yaş).
  ({GameState state, Person friend}) startSchoolFriend(
    GameState state,
    Random rng,
  ) {
    final Gender gender = rng.pick(Gender.values);
    final int age = (state.player.age + rng.between(-1, 1)).clamp(5, 120);

    String lastName = rng.pick(soyisimler);
    while (lastName == state.player.lastName) {
      lastName = rng.pick(soyisimler);
    }

    final Person friend = Person(
      id: _nextId(state),
      firstName: rng.pick(gender == Gender.kadin ? kadinIsimleri : erkekIsimleri),
      lastName: lastName,
      gender: gender,
      relation: RelationType.arkadas,
      age: age,
      isAlive: true,
      // Arkadaş olmak aynı evde yaşamak demek değildir.
      inPlayerHousehold: false,
      employment: EmploymentStatus.ogrenci,
      occupation: null,
      // Reşit olmayan kişiye kendi ekonomik durumu atanmaz.
      wealth: age >= 18 ? WealthTier.ortaHalli : null,
      bond: rng.between(35, 55), // prototypeOnly: yeni tanışıklık
    );

    return (
      state: state.copyWith(
        people: List<Person>.unmodifiable(<Person>[...state.people, friend]),
      ),
      friend: friend,
    );
  }

  /// Okul dışında tanışılan, **her yaşa uygun** yeni bir arkadaş.
  ///
  /// Ün üzerinden gelen tanışma olayları bunu kullanır. Kişi yalnızca
  /// tanışma **gerçekten olduğunda** üretilir; gerçekleşmeyen tanışma için
  /// kayıt açılmaz. Yeni tanışıklık romantik ilişki değildir.
  ({GameState state, Person friend}) startAcquaintance(
    GameState state,
    Random rng,
  ) {
    final Gender gender = rng.pick(Gender.values);
    final int age = (state.player.age + rng.between(-5, 5)).clamp(16, 100);

    String lastName = rng.pick(soyisimler);
    while (lastName == state.player.lastName) {
      lastName = rng.pick(soyisimler);
    }

    final Person friend = Person(
      id: _nextId(state),
      firstName:
          rng.pick(gender == Gender.kadin ? kadinIsimleri : erkekIsimleri),
      lastName: lastName,
      gender: gender,
      relation: RelationType.arkadas,
      age: age,
      isAlive: true,
      inPlayerHousehold: false,
      // Yaşına uygun durum: emekli/çalışan ayrımı uydurulmaz.
      employment: age >= 65
          ? EmploymentStatus.emekli
          : EmploymentStatus.calisiyor,
      occupation: rng.pick(meslekler),
      wealth: WealthTier.ortaHalli,
      bond: rng.between(30, 45), // prototypeOnly: yeni tanışıklık
      // Aynı şehirde tanışılır; şehir kuralları doğru işlesin.
      city: state.player.currentCity,
    );

    return (
      state: state.copyWith(
        people: List<Person>.unmodifiable(<Person>[...state.people, friend]),
      ),
      friend: friend,
    );
  }
}

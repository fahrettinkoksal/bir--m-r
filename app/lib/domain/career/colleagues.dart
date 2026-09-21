import 'dart:math';

import '../../data/job_catalog.dart';
import '../../data/name_pool.dart';
import '../generation/random_util.dart';
import '../models/game_state.dart';
import '../models/gender.dart';
import '../models/person.dart';
import '../models/relation.dart';
import '../models/wealth.dart';

/// İş arkadaşlarını üretir ve işten ayrılışta ne olacaklarını belirler.
///
/// İş arkadaşı, okul arkadaşı gibi **kalıcı kimliği olan** bir kişidir:
/// işten ayrılınca kaydı silinmez, yalnızca gündelik erişilebilirliği
/// biter. Aynı evde yaşıyormuş gibi gösterilmez ve işin şehrinde yaşar.
abstract final class Colleagues {
  /// prototypeOnly: bir işte tanışılan kişi sayısı.
  static const int prototypeOnlyCount = 3;

  /// prototypeOnly: tanışıklığın başlangıç yakınlığı.
  ///
  /// İş arkadaşı olmak yakın arkadaş olmak değildir; yakınlık düşük başlar.
  static const int prototypeOnlyStartBond = 35;

  /// prototypeOnly: işten ayrılırken arkadaşlığa dönmek için gereken
  /// yakınlık.
  static const int prototypeOnlyFriendshipBond = 60;

  /// Şu an çalışılan iş yerindeki iş arkadaşları.
  static List<Person> atWork(GameState state) => state.people
      .where((Person p) => p.isColleagueAt(state.career.jobId))
      .toList(growable: false);

  /// İşe yeni girildiğinde tanışılan kişileri üretir.
  ///
  /// Zaten o iş yerinden kayıtlı kişi varsa (aynı işe geri dönüldüyse)
  /// yeniden üretilmez: eski tanışıklık korunur.
  static List<Person> generate({
    required GameState state,
    required JobType job,
    required Random rng,
  }) {
    final List<Person> mevcut = state.people
        .where((Person p) =>
            p.relation == RelationType.isArkadasi && p.workplaceId == job.id)
        .toList(growable: false);
    final int uretilecek = prototypeOnlyCount - mevcut.length;
    if (uretilecek <= 0) return const <Person>[];

    final Set<String> kullanilanIsimler = <String>{
      for (final Person p in state.people) p.firstName,
      state.player.firstName,
    };
    final Set<String> kullanilanKimlikler = <String>{
      for (final Person p in state.people) p.id,
    };

    String benzersizIsim(Gender gender) {
      final List<String> havuz =
          gender == Gender.kadin ? kadinIsimleri : erkekIsimleri;
      for (int deneme = 0; deneme < 30; deneme++) {
        final String ad = rng.pick(havuz);
        if (!kullanilanIsimler.contains(ad)) {
          kullanilanIsimler.add(ad);
          return ad;
        }
      }
      return rng.pick(havuz);
    }

    String benzersizKimlik(int i) {
      String id = 'is-${job.id}-$i';
      int ek = 0;
      while (kullanilanKimlikler.contains(id)) {
        ek++;
        id = 'is-${job.id}-$i-$ek';
      }
      kullanilanKimlikler.add(id);
      return id;
    }

    final int oyuncuYasi = state.player.age;
    final List<Person> yeniler = <Person>[];
    for (int i = 0; i < uretilecek; i++) {
      final Gender cinsiyet =
          rng.chance(0.5) ? Gender.kadin : Gender.erkek;
      // İş arkadaşları oyuncuyla aynı kuşakta olmak zorunda değil; yaş
      // aralığı işin asgari yaşına saygı duyar.
      final int yas = rng
          .triangular(job.minAge, oyuncuYasi, oyuncuYasi + 18)
          .clamp(job.minAge, 70);
      yeniler.add(
        Person(
          id: benzersizKimlik(mevcut.length + i),
          firstName: benzersizIsim(cinsiyet),
          lastName: rng.pick(soyisimler),
          gender: cinsiyet,
          relation: RelationType.isArkadasi,
          age: yas,
          isAlive: true,
          // İş arkadaşı oyuncunun evinde yaşamaz.
          inPlayerHousehold: false,
          employment: EmploymentStatus.calisiyor,
          occupation: job.name,
          wealth: WealthTier.ortaHalli,
          bond: prototypeOnlyStartBond,
          // İşin şehrinde yaşar; şehir kuralları böylece doğru işler.
          city: state.career.jobCity ?? state.player.currentCity,
          workplaceId: job.id,
        ),
      );
    }
    return List<Person>.unmodifiable(yeniler);
  }

  /// İşten ayrılırken iş arkadaşlarının durumunu günceller.
  ///
  /// Yakınlığı yeterli olanlar **arkadaşa dönüşür** (aynı kimlik, aynı
  /// geçmiş); diğerleri iş arkadaşı olarak kayıtta kalır ama gündelik
  /// listelerde görünmez. Hiç kimse silinmez.
  static ({List<Person> people, List<String> becameFriends}) onLeavingJob(
    GameState state,
    String jobId,
  ) {
    final List<String> arkadasOlanlar = <String>[];
    final List<Person> guncel = state.people.map((Person p) {
      if (p.relation != RelationType.isArkadasi || p.workplaceId != jobId) {
        return p;
      }
      if (!p.isAlive || p.bond < prototypeOnlyFriendshipBond) return p;
      arkadasOlanlar.add(p.id);
      return p.copyWith(relation: RelationType.arkadas);
    }).toList(growable: false);

    return (
      people: List<Person>.unmodifiable(guncel),
      becameFriends: List<String>.unmodifiable(arkadasOlanlar),
    );
  }
}

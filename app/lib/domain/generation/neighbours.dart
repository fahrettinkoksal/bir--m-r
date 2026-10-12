/// **Komşular** (Paket BU): oturulan eve bağlı, kalıcı kimlikli kişiler.
///
/// **Neden var.** Paket BP apartmanı metinde yaşattı — üst kat gece
/// mobilya çekiyor, yandaki daire satılığa çıkıyor, toplantıda aidat
/// oylanıyor — ama komşu bir **isim** değildi: olay metni geçip
/// gidiyordu, ertesi yıl kimse hatırlamıyordu. Yol haritasında bu yüzden
/// "komşuyu gerçek kişi yapmak kendi paketi olmalı" yazıyordu.
///
/// **Komşuluk oturulan eve bağlıdır.** Kişi kaydında [Person.homeTie]
/// hangi evin komşusu olduğunu tutar: kendi evinde `'ev:<konut>'`,
/// kirada `'kira:<şehir>'`. Oyuncu başka bir eve ya da şehre taşınınca
/// o bağ geçersiz olur; kişi **eski komşu** olur ve gündelik listelerden
/// düşer. Yakınlık yeterliyse taşınırken **arkadaşa** dönüşür: gerçek
/// hayatta da bazı komşularla görüşmeye devam edilir.
///
/// Bütün sayılar `prototypeOnly` (Q-217).
library;

import 'dart:math';

import '../../data/name_pool.dart';
import '../features/feature_catalog.dart';
import '../models/game_state.dart';
import '../models/gender.dart';
import '../models/person.dart';
import '../models/relation.dart';
import '../models/wealth.dart';
import 'random_util.dart';

/// Taşınma sonrası komşuluk düzeni.
class NeighbourUpdate {
  const NeighbourUpdate({required this.state, required this.logLines});

  final GameState state;

  /// Günlüğe yazılacak satırlar (boş olabilir).
  final List<String> logLines;
}

class Neighbours {
  const Neighbours._();

  /// prototypeOnly: bir evde tanınan en az ve en çok komşu sayısı.
  static const int prototypeOnlyMinCount = 1;
  static const int prototypeOnlyMaxCount = 3;

  /// prototypeOnly: yeni komşunun başlangıç yakınlığı.
  ///
  /// Tanışıklıktan düşük: komşuluk, sınıf arkadaşlığından da uzak
  /// başlar. Selam verilen biri henüz tanıdık değildir.
  static const int prototypeOnlyStartBondMin = 8;
  static const int prototypeOnlyStartBondMax = 22;

  /// prototypeOnly: taşınırken arkadaşa dönüşme eşiği.
  static const int prototypeOnlyKeepInTouchBond = 55;

  /// prototypeOnly: komşunun en küçük ve en büyük yaşı.
  static const int prototypeOnlyMinAge = 19;
  static const int prototypeOnlyMaxAge = 78;

  /// Modül anahtarı (Paket BL sözleşmesi: tek kapı noktası).
  static bool isOn(GameState state) =>
      state.settings.features.isOn(FeatureId.komsular);

  /// Oturulan evin komşuluk anahtarı; ailesinin yanındaysa `null`.
  ///
  /// Kirada anahtar **şehir** düzeyinde: oyun hangi dairede kiracı
  /// olduğunu tutmuyor, o yüzden aynı şehirde kiradan kiraya geçmek
  /// komşuyu değiştirmez. Bu bilinçli bir sadeleştirme (Q-217).
  static String? keyOf(GameState state) {
    final String? id = state.residenceItemId;
    if (id != null) return 'ev:$id';
    return state.movedOut ? 'kira:${state.player.currentCity}' : null;
  }

  /// Şu anki evin yaşayan komşuları.
  static List<Person> current(GameState state) {
    final String? anahtar = keyOf(state);
    if (anahtar == null) return const <Person>[];
    return state.people
        .where((Person p) =>
            p.isAlive &&
            p.relation == RelationType.komsu &&
            p.homeTie == anahtar)
        .toList(growable: false);
  }

  /// Komşuluk düzenini oturulan evle uyumlu hâle getirir.
  ///
  /// · Ailesinin yanında yaşayan oyuncunun komşusu olmaz: mevcutlar
  ///   devredilir (yakınlık yeterliyse arkadaş, değilse eski komşu).
  /// · Taşındıysa eski evin komşuları devredilir ve yeni evin komşuları
  ///   üretilir.
  /// · Zaten uyumluysa **hiçbir şey yapılmaz ve zar atılmaz**: bu paket
  ///   eski tohumlu ölçümleri kaydırmaz (Paket BO dersi).
  static NeighbourUpdate reconcile(GameState state, Random rng) {
    if (!isOn(state)) return NeighbourUpdate(state: state, logLines: const <String>[]);

    final String? anahtar = keyOf(state);
    final List<Person> gecersizler = state.people
        .where((Person p) =>
            p.relation == RelationType.komsu &&
            (anahtar == null || p.homeTie != anahtar))
        .toList(growable: false);
    final bool yeniGerekiyor = anahtar != null && current(state).isEmpty;

    if (gecersizler.isEmpty && !yeniGerekiyor) {
      return NeighbourUpdate(state: state, logLines: const <String>[]);
    }

    final List<String> satirlar = <String>[];
    GameState sonuc = state;

    // 1) Eski komşuları devret.
    if (gecersizler.isNotEmpty) {
      final List<Person> guncel = sonuc.people.map((Person p) {
        if (!gecersizler.any((Person g) => g.id == p.id)) return p;
        if (p.isAlive && p.bond >= prototypeOnlyKeepInTouchBond) {
          // `homeTie` **silinmez**: nerede tanışıldığı kayıtta kalsın
          // (okul arkadaşının `schoolTie`'ı gibi). Erişilebilirlik
          // artık arkadaşlık kuralından geliyor.
          return p.copyWith(
            relation: RelationType.arkadas,
            becameFriendAtAge: p.becameFriendAtAge ?? sonuc.player.age,
          );
        }
        return p.copyWith(relation: RelationType.eskiKomsu);
      }).toList(growable: false);
      sonuc = sonuc.copyWith(people: List<Person>.unmodifiable(guncel));

      final List<Person> kalanlar = gecersizler
          .where((Person p) =>
              p.isAlive && p.bond >= prototypeOnlyKeepInTouchBond)
          .toList(growable: false);
      if (kalanlar.length == 1) {
        satirlar.add('${kalanlar.first.firstName} ile komşuluk bitti ama '
            'görüşmeye devam ettiniz.');
      } else if (kalanlar.length > 1) {
        satirlar.add('Eski komşularından ${kalanlar.length} kişiyle '
            'görüşmeye devam ettiniz.');
      }
    }

    // 2) Yeni evin komşularını üret.
    if (yeniGerekiyor) {
      final List<Person> yeniler = _generate(sonuc, rng, anakey: anahtar);
      sonuc = sonuc.copyWith(
        people: List<Person>.unmodifiable(<Person>[...sonuc.people, ...yeniler]),
      );
      if (yeniler.length == 1) {
        satirlar.add('Kapı komşun ${yeniler.first.firstName} '
            '${yeniler.first.lastName} ile tanıştın.');
      } else if (yeniler.length > 1) {
        satirlar.add('Yeni komşularınla tanıştın: '
            '${yeniler.map((Person p) => p.firstName).join(", ")}.');
      }
    }

    return NeighbourUpdate(state: sonuc, logLines: satirlar);
  }

  /// Bir ev için komşu üretir.
  static List<Person> _generate(
    GameState state,
    Random rng, {
    required String anakey,
  }) {
    final int adet = prototypeOnlyMinCount +
        rng.nextInt(prototypeOnlyMaxCount - prototypeOnlyMinCount + 1);
    final Set<String> kullanilanIsimler = <String>{
      state.player.firstName,
      for (final Person p in state.people) p.firstName,
    };

    final List<Person> sonuc = <Person>[];
    for (int i = 0; i < adet; i++) {
      final Gender gender = rng.pick(Gender.values);
      final List<String> havuz =
          gender == Gender.kadin ? kadinIsimleri : erkekIsimleri;
      final List<String> bos = havuz
          .where((String a) => !kullanilanIsimler.contains(a))
          .toList(growable: false);
      final String isim = bos.isEmpty ? rng.pick(havuz) : rng.pick(bos);
      kullanilanIsimler.add(isim);

      String soyad = rng.pick(soyisimler);
      while (soyad == state.player.lastName) {
        soyad = rng.pick(soyisimler);
      }

      final int yas = rng.between(prototypeOnlyMinAge, prototypeOnlyMaxAge);
      // Emeklilik yaşı oyunun kendi kuralı değil; komşunun çalışıp
      // çalışmadığı yaşına göre makul biçimde seçilir ve meslek
      // **uydurulmaz**: çalışmıyorsa meslek alanı boş kalır.
      final bool calisiyor = yas < 65;
      sonuc.add(
        Person(
          id: _nextId(state, sonuc.length),
          firstName: isim,
          lastName: soyad,
          gender: gender,
          relation: RelationType.komsu,
          age: yas,
          isAlive: true,
          // Komşu aynı hanede yaşamaz; aynı apartmanda yaşar.
          inPlayerHousehold: false,
          employment:
              calisiyor ? EmploymentStatus.calisiyor : EmploymentStatus.emekli,
          occupation: calisiyor ? rng.pick(meslekler) : null,
          wealth: WealthTier.ortaHalli,
          bond: rng.between(
            prototypeOnlyStartBondMin,
            prototypeOnlyStartBondMax,
          ),
          city: state.player.currentCity,
          homeTie: anakey,
        ),
      );
    }
    return sonuc;
  }

  static String _nextId(GameState state, int offset) {
    int n = state.people.length + offset + 1;
    while (state.people.any((Person p) => p.id == 'komsu-$n')) {
      n++;
    }
    return 'komsu-$n';
  }
}

import 'package:bir_omur/domain/economy/housing.dart';
import 'package:bir_omur/domain/models/game_state.dart';
import 'package:bir_omur/domain/models/marriage.dart';
import 'package:bir_omur/domain/models/owned_item.dart';
import 'package:bir_omur/domain/models/person.dart';
import 'package:bir_omur/domain/models/relation.dart';
import 'package:bir_omur/domain/models/wealth.dart';

/// Oyun durumunun her an sağlaması gereken tutarlılık kuralları.
///
/// Tek tek testlerde de, yüzlerce hayatın simüle edildiği toplu ölçümde de
/// aynı liste kullanılır; böylece "bir yerde doğru, başka yerde bozuk"
/// durumlar gizlenmez. Dönen liste boşsa durum tutarlıdır.
List<String> checkInvariants(GameState state, {String where = ''}) {
  final List<String> sorunlar = <String>[];
  void ekle(String metin) => sorunlar.add(where.isEmpty ? metin : '$where: $metin');

  // --- Kimlikler ------------------------------------------------------
  final Set<String> kisiKimlikleri = <String>{};
  for (final Person p in state.people) {
    if (!kisiKimlikleri.add(p.id)) ekle('aynı kişi kimliği iki kez: ${p.id}');
  }
  final Set<String> esyaKimlikleri = <String>{};
  for (final OwnedItem i in state.items) {
    if (!esyaKimlikleri.add(i.id)) ekle('aynı eşya kimliği iki kez: ${i.id}');
  }

  // --- Hane -----------------------------------------------------------
  for (final Person p in state.people) {
    if (!p.isAlive && p.inPlayerHousehold) {
      ekle('vefat etmiş kişi hâlâ hanede: ${p.id}');
    }
    if (p.age < 0) ekle('kişi yaşı negatif: ${p.id}');
    if (p.employment != EmploymentStatus.calisiyor && p.occupation != null) {
      ekle('çalışmayan kişiye meslek atanmış: ${p.id}');
    }
  }

  // --- Ekonomi --------------------------------------------------------
  if (state.player.wallet < 0) {
    ekle('cüzdan negatif: ${state.player.wallet}');
  }

  // --- Evlilik --------------------------------------------------------
  final List<Person> esler = state.people
      .where((Person p) => p.relation == RelationType.es)
      .toList(growable: false);
  if (esler.length > 1) ekle('birden fazla eş kaydı: ${esler.length}');

  final Marriage? evlilik = state.marriage;
  if (evlilik != null) {
    final Person? es = state.personById(evlilik.spouseId);
    if (es == null) {
      ekle('evlilik kaydı olmayan bir kişiyi gösteriyor: ${evlilik.spouseId}');
    } else {
      switch (evlilik.status) {
        case MarriageStatus.evli:
          if (es.relation != RelationType.es) {
            ekle('evli kayıtta eşin bağı ${es.relation.name}');
          }
          if (!es.isAlive) {
            ekle('eş vefat etmiş ama evlilik kaydı hâlâ "evli"');
          }
        case MarriageStatus.bosandi:
          if (es.relation != RelationType.eskiEs) {
            ekle('boşanmış kayıtta eşin bağı ${es.relation.name}');
          }
          if (es.inPlayerHousehold) ekle('boşanılan eş hâlâ hanede');
        case MarriageStatus.dul:
          if (es.isAlive) ekle('dul kayıtta eş hayatta görünüyor');
      }
      if (evlilik.status != MarriageStatus.evli && evlilik.endedAtAge == null) {
        ekle('biten evlilikte bitiş yaşı yok');
      }
    }
  } else if (esler.isNotEmpty) {
    ekle('evlilik kaydı olmadan eş bağı var');
  }

  // --- Çocuklar -------------------------------------------------------
  for (final Person c in state.children) {
    if (c.age > state.player.age) {
      ekle('çocuk oyuncudan büyük: ${c.id}');
    }
    if (state.player.age - c.age < 15) {
      // Çocuk sahibi olma yaşı en az 18; 15 güvenli alt sınırdır.
      ekle('kuşak farkı tutarsız: oyuncu ${state.player.age}, çocuk ${c.age}');
    }
  }

  // --- Konut ----------------------------------------------------------
  final String? oturulan = state.residenceItemId;
  if (oturulan != null) {
    final OwnedItem? ev = state.itemById(oturulan);
    if (ev == null) {
      ekle('oturulan ev envanterde yok: $oturulan');
    } else {
      if (!ev.isProperty) ekle('oturulan eşya konut değil: $oturulan');
      if (ev.rentedOut) ekle('oturulan ev aynı zamanda kirada');
    }
  }
  if (Housing.residenceOf(state) == ResidenceKind.aileYaninda &&
      state.movedOut) {
    ekle('hem evden çıkmış hem ailesinin yanında görünüyor');
  }

  // --- Miras ----------------------------------------------------------
  for (final String id in state.settledEstates) {
    final Person? kisi = state.personById(id);
    if (kisi == null) {
      ekle('olmayan kişinin mirası dağıtılmış: $id');
    } else if (kisi.isAlive) {
      ekle('hayattaki kişinin mirası dağıtılmış: $id');
    }
  }

  return sorunlar;
}

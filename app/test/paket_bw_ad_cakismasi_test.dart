/// Paket BW/0 — ad çakışmasının gerçek kaynağı ve kalıcı bekçisi.
///
/// Paket BV ad havuzlarını büyüttü ve gelin/damat + torun üretimindeki
/// eksik korumayı kapattı, ama **%14'lük bir çocuk-hane çakışması açık
/// kaldı** ve kaynağı bulunamamıştı. Bu paket kaynağı ölçerek buldu:
/// çakışmaların 52/63'ü **çocuk-çocuk** çakışmasıydı ve sebebi oyun
/// değil **ölçüm aracıydı** — `PlayerBot` her bebeği sekiz adlı sabit
/// bir listeden adlandırıyordu (Ada, Deniz, Ege, Mira, Aras, Nehir,
/// Can, Eylül). İki çocuklu hayatta tekrar kaçınılmazdı.
///
/// Bu dosya iki şeyi birden korur:
///
/// * **Oyun tarafı:** kişi üreten yollar (sevgili, okul arkadaşı,
///   tanışıklık) kayıttaki adları dışlıyor.
/// * **Araç tarafı:** bot artık oyunun üretmediği bir çakışma
///   üretmiyor. Bekçi bunu hayat oynatarak ölçer; durum kurmaz.
library;

import 'dart:math';

import 'package:bir_omur/domain/interaction/friendship.dart';
import 'package:bir_omur/domain/interaction/romance.dart';
import 'package:bir_omur/domain/models/game_state.dart';
import 'package:bir_omur/domain/models/person.dart';
import 'package:bir_omur/domain/models/relation.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/player_bot.dart';

/// Hayattaki (yaşayan) adların çokluğu.
Set<String> _yasayanAdlar(GameState s) => <String>{
      s.player.firstName,
      for (final Person p in s.people)
        if (p.isAlive) p.firstName,
    };

void main() {
  group('Paket BW/0 — ad çakışması', () {
    test('çocuk kayıttaki yaşayan bir adı taşımıyor (60 hayat)', () {
      int cocuguOlan = 0;
      int cakisan = 0;
      final List<String> ornekler = <String>[];

      for (int i = 0; i < 60; i++) {
        final PlayerArchetype a =
            PlayerArchetype.values[i % PlayerArchetype.values.length];
        GameState? son;
        playBotLife(
          archetype: a,
          seed: 4100 + i,
          onYear: (GameState s) => son = s,
        );
        final GameState? s = son;
        if (s == null) continue;
        final List<Person> yasayan =
            s.people.where((Person p) => p.isAlive).toList(growable: false);
        final List<Person> cocuklar = yasayan
            .where((Person p) => p.relation == RelationType.cocuk)
            .toList(growable: false);
        if (cocuklar.isEmpty) continue;
        cocuguOlan++;
        for (final Person c in cocuklar) {
          final bool carpti = yasayan.any((Person d) =>
                  d.id != c.id && d.firstName == c.firstName) ||
              c.firstName == s.player.firstName;
          if (carpti) {
            cakisan++;
            if (ornekler.length < 5) {
              ornekler.add('tohum ${4100 + i}: ${c.firstName}');
            }
            break;
          }
        }
      }

      expect(cocuguOlan, greaterThanOrEqualTo(12),
          reason: 'ölçüm kurulumu bozuk: 60 hayatta çocuk sahibi olan '
              'hayat çok az ($cocuguOlan)');
      // Ölçüm: 300 hayatta 0/99. Tavan 1, çünkü oyunun kendi kuralında
      // belgelenmiş bir kaçış var: ad havuzu tükenirse (çok kalabalık
      // kayıt) filtresiz ad dönebiliyor. Botun eski sekiz adlı listesi
      // bu oranı 28/99'a çıkarıyordu; gerileme buradan görünür.
      expect(cakisan, lessThanOrEqualTo(1),
          reason: 'çocuk hanedeki yaşayan bir adı taşıyor: $cakisan/'
              '$cocuguOlan hayat. Örnekler: $ornekler');
    }, timeout: const Timeout(Duration(minutes: 20)));

    test('aynı adı taşıyan iki yaşayan kişi azınlıkta (60 hayat)', () {
      int cakisan = 0;
      int sayilan = 0;
      for (int i = 0; i < 60; i++) {
        final PlayerArchetype a =
            PlayerArchetype.values[i % PlayerArchetype.values.length];
        GameState? son;
        playBotLife(
          archetype: a,
          seed: 5300 + i,
          onYear: (GameState s) => son = s,
        );
        final GameState? s = son;
        if (s == null) continue;
        sayilan++;
        final List<String> adlar = <String>[
          s.player.firstName,
          for (final Person p in s.people)
            if (p.isAlive) p.firstName,
        ];
        if (adlar.length != _yasayanAdlar(s).length) cakisan++;
      }

      expect(sayilan, greaterThanOrEqualTo(50),
          reason: 'ölçüm kurulumu bozuk: $sayilan hayat sayıldı');
      // Ölçüm: 25/300 (%8). Paket BV öncesi 283/300, BV sonrası
      // 105/300'dü. Tavan dörtte bir: altındaki dalgalanma gürültü,
      // üstüne çıkması korumanın bir yerde koptuğu anlamına gelir.
      expect(cakisan * 4, lessThanOrEqualTo(sayilan),
          reason: 'aynı adı taşıyan iki yaşayan kişi çok sık: '
              '$cakisan/$sayilan hayat');
    }, timeout: const Timeout(Duration(minutes: 20)));

    test('sevgili, okul arkadaşı ve tanışıklık kayıttaki adı seçmiyor', () {
      // **Durum kurulmuyor, aranıyor:** kalabalık bir kayıt gerçek bir
      // bot hayatından alınır, üretim o kaydın üzerinde çalıştırılır.
      GameState? dolu;
      for (int i = 0; i < 12 && dolu == null; i++) {
        GameState? aday;
        playBotLife(
          archetype: PlayerArchetype.family,
          seed: 6100 + i,
          onYear: (GameState s) {
            if (aday == null && s.people.length >= 20 && s.player.age >= 30) {
              aday = s;
            }
          },
        );
        dolu = aday;
      }
      expect(dolu, isNotNull,
          reason: '20 kişilik kayıt bulunamadı; ölçüm kurulumu bozuk');
      final GameState s = dolu!;

      for (int tohum = 0; tohum < 25; tohum++) {
        final Set<String> mevcut = <String>{
          s.player.firstName,
          for (final Person p in s.people) p.firstName,
        };
        final Person sevgili = Romance().start(s, Random(tohum)).partner;
        expect(mevcut.contains(sevgili.firstName), isFalse,
            reason: 'sevgili kayıttaki bir adı aldı: ${sevgili.firstName}');

        final Person okul =
            Friendship().startSchoolFriend(s, Random(tohum + 500)).friend;
        expect(mevcut.contains(okul.firstName), isFalse,
            reason: 'okul arkadaşı kayıttaki bir adı aldı: '
                '${okul.firstName}');

        final Person tanis =
            Friendship().startAcquaintance(s, Random(tohum + 900)).friend;
        expect(mevcut.contains(tanis.firstName), isFalse,
            reason: 'tanışıklık kayıttaki bir adı aldı: ${tanis.firstName}');
      }
    }, timeout: const Timeout(Duration(minutes: 20)));
  });
}

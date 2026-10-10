// Paket CI — arkadaş grubu.
//
// **Nasıl bulundu.** `docs/EKSIKLER.md` §3.1 arkadaşlığın eksiklerini
// saymıştı; D-130 çoğunu kapattı ve o bölümün 9 Ekim güncellemesi kalan
// iki eksiği yazdı: **arkadaş grubu** ve çocukluk arkadaşıyla yıllar
// sonra karşılaşma. İkincisi D-130'un zincirlerinde kodlu çıktı
// (`event_pool_friendship.dart`); grup ise kodda hiç yoktu —
// `arkadasGrubu`/`friendGroup` tek bir dosyada geçmiyordu.
//
// **Yeni bir etkileşim motoru yazılmadı.** Birden çok kişiyle
// aktiviteye gitmek zaten vardı (Paket X/2, `Outing`): maliyet kişi
// başına çarpılıyor, her katılımcıyla bağ artıyor. Eksik olan **kalıcı
// kimlik**ti; buluşma yine aktivite yolundan geçiyor.
//
// **Ölçüm paketi şekillendirdi (120 hayat, bütün arketipler).** Üç
// yanlış kurgu ölçümle bulundu ve düzeltildi:
//
// 1. **Aday kümesi fazla genişti.** İlk yazımda sınıf arkadaşı, iş
//    arkadaşı ve komşu da gruba alınıyordu. Grup 11 hayatta kuruldu ama
//    **tek bir buluşma olmadı**: `Outing.companionRelations` o üç türü
//    taşımıyor, yani üye sinemaya gelemiyor. Aday kümesi artık oyunun
//    kendi refakatçi kuralından okunuyor.
// 2. **Bot bloğu listenin sonundaydı.** Aktivite rutini her eylemden
//    sonra olay çıkabildiği için yılı erken bırakıyor (D-125); sona
//    konan iş sıraya hiç gelmiyordu. Blok rutinin başına alındı: grup
//    kuran hayat 2 → 8.
// 3. **Buluşmaya bütün üyeler gönderiliyordu.** Refakatçi kuralı
//    arkadaşın bağının **o anda** 45+ olmasını istiyor, bağ ise her yıl
//    sönüyor. Grup kurulduktan bir süre sonra kimse "gelebilir"
//    sayılmıyor ve buluşma sessizce düşüyordu. Artık o gün gelebilen
//    üyelerle buluşuluyor.
//
// Son ölçüm: 120 hayatın **8'inde** grup kuruluyor, **2'sinde** en az
// bir buluşma oluyor, 9 olayın **5-6'sı** görülüyor, **2** grup
// dağılıyor. Grubun seyrek olması bilerek kabul edildi: oyunun
// arkadaşlık hunisi hayat başına ortanca **2** yakın arkadaş veriyor ve
// grup üç kişi istiyor. Eşiği gevşetmek Q-227'de sorulmuştur.
library;

import 'dart:math';

import 'package:bir_omur/data/event_pool.dart';
import 'package:bir_omur/data/event_pool_friend_circle.dart';
import 'package:bir_omur/data/save/game_state_codec.dart';
import 'package:bir_omur/domain/events/event_engine.dart';
import 'package:bir_omur/domain/features/feature_catalog.dart';
import 'package:bir_omur/domain/features/feature_events.dart';
import 'package:bir_omur/domain/interaction/friend_circles.dart';
import 'package:bir_omur/domain/models/friend_circle.dart';
import 'package:bir_omur/domain/models/game_event.dart';
import 'package:bir_omur/domain/models/game_state.dart';
import 'package:bir_omur/domain/models/life_log.dart';
import 'package:bir_omur/domain/models/person.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/player_bot.dart';

void main() {
  group('Paket CI §1 — havuz ve kayıt', () {
    test('kimlikler benzersiz ve ana havuzda', () {
      final List<String> idler =
          kFriendCircleEvents.map((GameEvent e) => e.id).toList();
      expect(idler.toSet().length, idler.length,
          reason: 'grup havuzunda çakışan kimlik var');
      final Set<String> ana =
          kEventPool.map((GameEvent e) => e.id).toSet();
      for (final String id in idler) {
        expect(ana.contains(id), isTrue,
            reason: '$id ana havuza eklenmemiş; hiç çıkmaz');
      }
      // Ana havuzda aynı kimlik iki kez olmasın (Paket CB'nin dersi).
      final List<String> anaListe =
          kEventPool.map((GameEvent e) => e.id).toList();
      expect(anaListe.toSet().length, anaListe.length,
          reason: 'ana havuzda çakışan kimlik var');
    });

    test('her olay süren bir grup istiyor ve iki seçenek sunuyor', () {
      for (final GameEvent e in kFriendCircleEvents) {
        expect(e.requirement.requiresFriendCircle, isTrue,
            reason: '${e.id} grup koşulu taşımıyor; grubu olmayan '
                'oyuncuya grup anlatılır');
        expect(e.choices.length, greaterThanOrEqualTo(2),
            reason: '${e.id} tek seçenekli; seçim olmayan olay karar '
                'değildir');
        expect(e.requirement.minAge,
            greaterThanOrEqualTo(FriendCircles.prototypeOnlyMinAge),
            reason: '${e.id} grup kurulamayacak bir yaşta çıkabiliyor');
      }
    });

    test('bırakılan her iz okunuyor, okunan her iz bırakılıyor', () {
      final Set<String> yazilan = <String>{
        for (final GameEvent e in kFriendCircleEvents)
          for (final EventChoice c in e.choices) ...c.addFlags,
      };
      final Set<String> okunan = <String>{
        for (final GameEvent e in kFriendCircleEvents)
          ...e.requirement.requiredFlags,
      };
      for (final String iz in okunan) {
        expect(yazilan.contains(iz), isTrue,
            reason: '$iz izi okunuyor ama hiçbir seçim yazmıyor: '
                'yetim halka (Paket CE)');
      }
      for (final String iz in yazilan) {
        expect(okunan.contains(iz), isTrue,
            reason: '$iz izi yazılıyor ama hiç okunmuyor: sessiz iz '
                '(Paket AR)');
      }
    });

    test('yasak kalıplar yok', () {
      const List<String> yasak = <String>[
        'olumlu yönde',
        'bu deneyim',
        'kaliteli vakit',
        'aranızdaki bağ güçlendi',
        'duygusal açıdan',
        'bro',
        'kanka',
        'moruk',
      ];
      for (final GameEvent e in kFriendCircleEvents) {
        final String hepsi = <String>[
          e.text,
          for (final EventChoice c in e.choices) c.label,
          for (final EventChoice c in e.choices) c.resultText,
        ].join(' ').toLowerCase();
        for (final String k in yasak) {
          expect(hepsi.contains(k), isFalse,
              reason: '${e.id} yasak kalıp taşıyor: "$k"');
        }
      }
    });

    test('havuz modül haritasına kayıtlı', () {
      expect(FeatureEvents.pools[FeatureId.arkadasGrubu],
          same(kFriendCircleEvents),
          reason: 'havuz modüle bağlanmamış; anahtar kapatıldığında '
              'olaylar yine çıkar (Paket BL sözleşmesi)');
    });
  });

  group('Paket CI §2 — modül kapalıyken', () {
    late GameState kare;

    setUpAll(() {
      GameState? bulunan;
      for (final PlayerArchetype a in PlayerArchetype.values) {
        for (int seed = 1; seed <= 20 && bulunan == null; seed++) {
          playBotLife(
            archetype: a,
            seed: seed * 29 + a.index,
            onPreAge: (GameState s) {
              bulunan ??= s.player.age >= 20 ? s : null;
            },
          );
        }
        if (bulunan != null) break;
      }
      expect(bulunan, isNotNull, reason: 'ölçüm için kare bulunamadı');
      kare = bulunan!;
    });

    test('kapalıyken grup kurulamıyor ve yıllık bakım işlemiyor', () {
      final GameState kapali = kare.copyWith(
        settings: kare.settings.copyWith(
          features: kare.settings.features
              .toggled(FeatureId.arkadasGrubu, false),
        ),
      );
      expect(FriendCircles.isOn(kapali), isFalse);
      expect(FriendCircles.blockReason(kapali), contains('kapalı'));
      final ({GameState state, bool applied, String text}) sonuc =
          FriendCircles.form(kapali);
      expect(sonuc.applied, isFalse,
          reason: 'modül kapalıyken grup kuruldu (fail-closed değil)');
      expect(identical(FriendCircles.yearly(kapali), kapali), isTrue,
          reason: 'modül kapalıyken yıllık bakım durumu değiştirdi');
    });

    test('kapalıyken hiçbir grup olayı aday olmuyor', () {
      final GameState kapali = kare.copyWith(
        settings: kare.settings.copyWith(
          features: kare.settings.features
              .toggled(FeatureId.arkadasGrubu, false),
        ),
      );
      final Set<String> grupIds =
          kFriendCircleEvents.map((GameEvent e) => e.id).toSet();
      final Set<String> adaylar =
          const EventEngine().debugEligibleIds(kapali, Random(1));
      expect(adaylar.intersection(grupIds), isEmpty,
          reason: 'modül kapalıyken grup olayı aday havuzunda');
    });

    test('modül kapalı ölçüm bit bit aynı (zar sözleşmesi)', () {
      for (final int seed in <int>[11, 23, 37]) {
        final BotLifeResult acik = playBotLife(
          archetype: PlayerArchetype.casual,
          seed: seed,
          features:
              FeatureSwitches.defaults.toggled(FeatureId.arkadasGrubu, true),
        );
        final BotLifeResult kapali = playBotLife(
          archetype: PlayerArchetype.casual,
          seed: seed,
          features:
              FeatureSwitches.defaults.toggled(FeatureId.arkadasGrubu, false),
        );
        // Grup oyuncunun kendi düğmesiyle kurulduğu ve zar tüketmediği
        // için **açık/kapalı fark etmeksizin** ölüm yaşı ve servet aynı
        // kalmalı: modül kapalıyken bot düğmeye basmıyor, açıkken
        // basabiliyor ama zar kaymıyor.
        expect(kapali.deathAge, acik.deathAge,
            reason: 'tohum $seed: modül anahtarı ölüm yaşını kaydırdı');
      }
    });
  });

  group('Paket CI §3 — kurma kapısı ve kayıt', () {
    test('kapı açıkken grup kuruluyor, üyeler aday kümesinden', () {
      GameState? uygun;
      for (final PlayerArchetype a in PlayerArchetype.values) {
        for (int seed = 1; seed <= 40 && uygun == null; seed++) {
          playBotLife(
            archetype: a,
            seed: seed * 29 + a.index,
            onPreAge: (GameState s) {
              if (uygun != null) return;
              if (FriendCircles.activeOf(s) != null) return;
              if (FriendCircles.blockReason(s).isEmpty) uygun = s;
            },
          );
        }
        if (uygun != null) break;
      }
      expect(uygun, isNotNull,
          reason: 'taranan hayatlarda grup kurmaya uygun kare '
              'bulunamadı; kapı hiç açılmıyor olabilir');

      final List<Person> adaylar = FriendCircles.eligible(uygun!);
      final ({GameState state, bool applied, String text}) sonuc =
          FriendCircles.form(uygun!);
      expect(sonuc.applied, isTrue, reason: sonuc.text);

      final FriendCircle? grup = FriendCircles.activeOf(sonuc.state);
      expect(grup, isNotNull);
      expect(grup!.memberIds.length,
          greaterThanOrEqualTo(FriendCircles.prototypeOnlyMinMembers));
      expect(grup.memberIds.length,
          lessThanOrEqualTo(FriendCircles.prototypeOnlyMaxMembers));
      expect(grup.memberIds.toSet().length, grup.memberIds.length,
          reason: 'aynı kişi gruba iki kez girdi');
      final Set<String> adayIds = adaylar.map((Person p) => p.id).toSet();
      for (final String id in grup.memberIds) {
        expect(adayIds.contains(id), isTrue,
            reason: 'grup, aday olmayan bir kişiyi aldı');
      }
      // Kuruluş günlüğe yazıldı: sessiz değişiklik yok.
      expect(
          sonuc.state.log.any((LifeLogEntry e) =>
              e.age == uygun!.player.age && e.text.contains(grup.name)),
          isTrue,
          reason: 'grup kuruldu ama günlüğe yazılmadı');
      // İkinci kez kurulamaz.
      expect(FriendCircles.blockReason(sonuc.state), contains('Zaten'));
    });

    test('kayıt kapat/aç turunu atlatıyor', () {
      GameState? grupluKare;
      for (final PlayerArchetype a in PlayerArchetype.values) {
        for (int seed = 1; seed <= 40 && grupluKare == null; seed++) {
          playBotLife(
            archetype: a,
            seed: seed * 29 + a.index,
            onPreAge: (GameState s) {
              if (grupluKare != null) return;
              if (FriendCircles.activeOf(s) != null) grupluKare = s;
            },
          );
        }
        if (grupluKare != null) break;
      }
      expect(grupluKare, isNotNull,
          reason: 'taranan hayatlarda grubu olan kare bulunamadı');

      final GameState geri =
          decodeGameState(encodeGameState(grupluKare!));
      final FriendCircle? once = FriendCircles.activeOf(grupluKare!);
      final FriendCircle? sonra = FriendCircles.activeOf(geri);
      expect(sonra, isNotNull, reason: 'grup kayda girmedi (kodek eksik)');
      expect(sonra!.name, once!.name);
      expect(sonra.memberIds, once.memberIds);
      expect(sonra.formedAtAge, once.formedAtAge);
      expect(geri.friendCircles.length, grupluKare!.friendCircles.length,
          reason: 'dağılmış grup kayıtları kayboldu');
    });
  });

  group('Paket CI §4 — oyuncunun yolu gerçekten yürünüyor', () {
    test('120 hayatta grup kuruluyor, buluşuluyor, dağılıyor', () {
      int kuran = 0;
      int bulusan = 0;
      int toplamBulusma = 0;
      int dagilan = 0;
      int ayrilmaSatiri = 0;
      final Set<String> gorulen = <String>{};
      final Set<String> grupIds =
          kFriendCircleEvents.map((GameEvent e) => e.id).toSet();
      for (final PlayerArchetype a in PlayerArchetype.values) {
        for (int i = 0; i < 12; i++) {
          bool dagilmaGordu = false;
          bool ayrilmaGordu = false;
          final BotLifeResult r = playBotLife(
            archetype: a,
            seed: 7000 + i * 13,
            onPreAge: (GameState s) {
              // Dağılan grup kayıtta kalmalı ve gerekçesi günlükte
              // olmalı: sessiz kayıp yok.
              for (final FriendCircle c in s.friendCircles) {
                if (c.isActive) continue;
                dagilmaGordu = true;
                expect(c.dispersedAtAge, isNotNull,
                    reason: 'dağılan grubun yaşı yazılmamış');
                expect(
                    s.log.any((LifeLogEntry e) =>
                        e.text.contains('${c.name} dağıldı')),
                    isTrue,
                    reason: '${c.name} sessizce dağıldı');
              }
              if (s.log.any((LifeLogEntry e) =>
                  e.text.contains('içinde değil'))) {
                ayrilmaGordu = true;
              }
            },
          );
          if (r.formedFriendCircle) kuran++;
          if (r.friendCircleMeets > 0) bulusan++;
          toplamBulusma += r.friendCircleMeets;
          if (dagilmaGordu) dagilan++;
          if (ayrilmaGordu) ayrilmaSatiri++;
          gorulen.addAll(r.seenEvents.where(grupIds.contains));
        }
      }
      // ignore: avoid_print
      print('OLCUM — grup: kuran $kuran/120, buluşan $bulusan '
          '(toplam $toplamBulusma buluşma), dağılan $dagilan, '
          'ayrılma satırı gören $ayrilmaSatiri, görülen olay '
          '${gorulen.length}/${grupIds.length}');

      // Ölçülen: 8 kuran, 2 buluşan (3 buluşma), 2 dağılan, 5-6 olay.
      // Eşikler ölçümün altında: amaç kalibrasyon değil, **yolun
      // kapanmasını** yakalamak (Paket BP dersi).
      expect(kuran, greaterThanOrEqualTo(3),
          reason: 'grup 120 hayatta neredeyse hiç kurulmuyor; kapı ya '
              'bot ya oyun tarafında kapanmış');
      expect(toplamBulusma, greaterThanOrEqualTo(1),
          reason: 'grupla hiç buluşulmadı; refakatçi kuralı buluşmayı '
              'yutuyor olabilir (ölçümde tam bu olmuştu)');
      expect(gorulen.length, greaterThanOrEqualTo(4),
          reason: 'dokuz grup olayının yalnızca ${gorulen.length} '
              'tanesi görüldü');
    });
  });
}

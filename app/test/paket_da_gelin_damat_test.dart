// Paket DA — gelin/damat kaydı yalnızca çocuğun eşi için açılır.
//
// **Nasıl çıktı.** `ekran_dokumu_ozel_durum_test.dart`'ın "YENİ DOĞAN
// BEBEK" karesi gözle okundu ve 21 yaşındaki oyuncunun günlüğünde şu
// satır vardı:
//
// > Gelin Yasemin bu sabah kapıyı çaldı, elinde bir tencere yemek vardı.
//
// 21 yaşında evli çocuk olamaz. Kök neden: `ChildMarriage.maybeMarry`
// kardeş, üvey kardeş, yarım kardeş ve üvey çocuk için de çağrılıyor
// ama `_createSpouse` bağı **sabit** `cocugunEsi` yazıyordu.
//
// **Ölçüm (150 bot hayatı, tohum 80000+i):**
//
// |                                   | önce | sonra |
// |-----------------------------------|------|-------|
// | `cocugunEsi` kaydı olan hayat     | 127  | 47    |
// | ilk görülme yaşı (min/ortanca)    | 6/20 | 43/53 |
// | 35 yaş altı böyle kare            | 119  | **0** |
//
// Niyet zaten yazılıydı: `docs/DESIGN_REVIEW_QUEUE.md` "kardeşin eşi
// kişi kaydı değil, yalnızca bir ad". Kod kendi belgelenmiş niyetini
// ihlal ediyordu; bu bir tasarım kararı değil **hata**.
import 'package:bir_omur/domain/generation/child_marriage.dart';
import 'package:bir_omur/domain/models/game_state.dart';
import 'package:bir_omur/domain/models/person.dart';
import 'package:bir_omur/domain/models/relation.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/player_bot.dart';

class _Tarama {
  int kare = 0;
  int gelinDamatliKare = 0;
  int cocuksuzGelinDamatKare = 0;
  final List<String> ornekler = <String>[];
  int enKucukYas = 999;
  int gelinDamatliHayat = 0;

  /// Kardeş evliliği **ad düzeyinde** kaydedildi mi?
  int kardesEvliligi = 0;
  int kardesEvliligiKisiKaydiyla = 0;
}

_Tarama? _onbellek;

_Tarama _taramaAl() {
  if (_onbellek != null) return _onbellek!;
  final _Tarama t = _Tarama();
  for (int i = 0; i < 150; i++) {
    bool gordu = false;
    playBotLife(
      archetype: PlayerArchetype.values[i % PlayerArchetype.values.length],
      seed: 80000 + i,
      onPreAge: (GameState s) {
        t.kare++;
        final Iterable<Person> gelinDamat = s.people.where((Person p) =>
            p.relation == RelationType.cocugunEsi ||
            p.relation == RelationType.eskiCocugunEsi);
        if (gelinDamat.isNotEmpty) {
          gordu = true;
          t.gelinDamatliKare++;
          if (s.player.age < t.enKucukYas) t.enKucukYas = s.player.age;

          // Gelin/damat varsa, evlenebilecek yaşta bir çocuk (ya da
          // üvey çocuk) kaydı da olmalı. Kare kurulmadı, bulundu.
          final bool evlenebilirCocuk = s.people.any((Person p) =>
              (p.relation == RelationType.cocuk ||
                  p.relation == RelationType.uveyCocuk) &&
              p.age >= ChildMarriage.prototypeOnlyMinAge);
          if (!evlenebilirCocuk) {
            t.cocuksuzGelinDamatKare++;
            if (t.ornekler.length < 6) {
              t.ornekler.add('tohum ${80000 + i} · oyuncu ${s.player.age} · '
                  '${gelinDamat.first.firstName} '
                  '(${gelinDamat.first.relation.name})');
            }
          }
        }

        // Kardeşin evliliği kayıtta duruyor mu (ad düzeyinde)?
        for (final Person p in s.people) {
          final bool kardesTuru = p.relation == RelationType.kardes ||
              p.relation == RelationType.uveyKardes ||
              p.relation == RelationType.yariKardes;
          if (!kardesTuru) continue;
          final String? esAdi = p.development?.spouseName;
          if (esAdi == null || esAdi.isEmpty) continue;
          t.kardesEvliligi++;
          if (p.development?.spousePersonId != null) {
            t.kardesEvliligiKisiKaydiyla++;
          }
        }
      },
    );
    if (gordu) t.gelinDamatliHayat++;
  }
  return _onbellek = t;
}

const Timeout _sure = Timeout(Duration(minutes: 30));

void main() {
  group('Paket DA — gelin/damat kaydı', () {
    test(timeout: _sure, '§1 gelin/damat varsa evlenebilir çocuk da var', () {
      final _Tarama t = _taramaAl();
      // ignore: avoid_print
      print('taranan kare ${t.kare} · gelin/damatlı kare '
          '${t.gelinDamatliKare} · gelin/damatlı hayat '
          '${t.gelinDamatliHayat}/150 · en küçük yaş ${t.enKucukYas}');
      // ignore: avoid_print
      print('çocuksuz gelin/damat karesi: ${t.cocuksuzGelinDamatKare}');
      for (final String o in t.ornekler) {
        // ignore: avoid_print
        print('  $o');
      }
      expect(t.gelinDamatliKare, greaterThan(100),
          reason: 'hiç gelin/damat karesi bulunamadı; denetim boşa döner');
      expect(t.cocuksuzGelinDamatKare, 0,
          reason: 'oyuncunun evlenebilecek yaşta çocuğu yokken gelin/damat '
              'kaydı var: kardeşin eşi yine gelin yazılıyor olabilir');
    });

    test(timeout: _sure, '§2 gelin/damat en erken orta yaşta görünüyor', () {
      final _Tarama t = _taramaAl();
      // Ölçülen en küçük yaş 43 (önce 6). Taban ölçümün altında.
      expect(t.enKucukYas, greaterThanOrEqualTo(40),
          reason: 'gelin/damat ${t.enKucukYas} yaşında görünüyor; oyuncunun '
              'o yaşta ${ChildMarriage.prototypeOnlyMinAge} yaşını '
              'doldurmuş çocuğu olamaz');
    });

    test(timeout: _sure, '§3 kardeşin evliliği kayıtta duruyor, kişi kaydı yok',
        () {
      final _Tarama t = _taramaAl();
      // ignore: avoid_print
      print('kardeş evliliği görülen kare: ${t.kardesEvliligi}, '
          'kişi kaydı açılmış olan: ${t.kardesEvliligiKisiKaydiyla}');
      // Bilgi kaybı yok: kardeşin evliliği ad düzeyinde kaydediliyor.
      expect(t.kardesEvliligi, greaterThan(100),
          reason: 'kardeş hiç evlenmiyor; düzeltme evliliği de kapatmış '
              'olabilir');
      // Ama kişi kaydı açılmıyor (kuyruğun yazdığı niyet).
      expect(t.kardesEvliligiKisiKaydiyla, 0,
          reason: 'kardeşin eşi için kişi kaydı açılmış; kuyruk "yalnızca '
              'bir ad" diyor');
    });
  });
}

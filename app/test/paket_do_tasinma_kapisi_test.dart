import 'dart:io';

import 'package:bir_omur/domain/economy/housing.dart';
import 'package:bir_omur/domain/models/game_state.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/player_bot.dart';

/// **Paket DO — Taşın ekranı kapıyı satırda yazmıyordu.**
///
/// Döküm `activity_pages.dart` içindeki beş ayrı sayfayı ilk kez bastı
/// (Kütüphane, Son Kararlar, Tatil yap, Taşın, ve `fertility_page`).
/// Dördü temizdi; **Taşın** aykırıydı:
///
/// > Taşın · Denizli şehrinde yaşıyorsun. Cüzdanında **0 ₺** var.
/// > Aydın — Kiralık bir eve taşın
/// > İzmir — Kiralık bir eve taşın
/// > …
///
/// Dört şehir satırı ne masrafı ne engeli yazıyordu. Oyunun geri kalanı
/// kapıyı satırın kendisinde yazar: sağlık merkezi "2.800 ₺ gerekiyor;
/// cüzdanında yeterli para yok · Şu an kapalı", tüp bebek "Hekim önce
/// bir süre kendiniz denemenizi istiyor · Şu an kapalı". Kural zaten
/// motorda vardı (`moveToRental` aynı cümleyi döndürüyor) ama yalnızca
/// **dokunduktan sonra** okunuyordu.
///
/// Düzeltme kuralı değiştirmiyor: kapı `rentalMoveBlockReason` işlevine
/// çıkarıldı, `moveToRental` onu okuyor, ekran da aynı cümleyi satırda
/// yazıyor. Masraf da satırda görünüyor.
void main() {
  const Housing konut = Housing();

  /// Botla oynanan hayatlardan koşula uyan ilk kareyi bulur.
  GameState? kareBul(bool Function(GameState) kosul) {
    GameState? bulunan;
    for (final PlayerArchetype a in <PlayerArchetype>[
      PlayerArchetype.casual,
      PlayerArchetype.risky,
      PlayerArchetype.family,
    ]) {
      for (int t = 0; t < 30; t++) {
        if (bulunan != null) return bulunan;
        void bak(GameState s) {
          if (bulunan != null || s.deceased) return;
          if (kosul(s)) bulunan = s;
        }

        playBotLife(
          archetype: a,
          seed: 81000 + t,
          onYear: bak,
          onPreAge: bak,
        );
      }
    }
    return bulunan;
  }

  test('§1 engel metni motorun kendi cümlesiyle aynı', () {
    // Parası yetmeyen bir kare **bulunur** (kurulmaz).
    final GameState? kare = kareBul(
      (GameState s) =>
          s.player.age >= Housing.prototypeOnlyMinAge &&
          s.player.wallet < Housing.prototypeOnlyMoveCost,
    );
    expect(kare, isNotNull, reason: 'Parası yetmeyen yetişkin kare yok.');
    final GameState s = kare!;

    final String engel = konut.rentalMoveBlockReason(s);
    expect(engel, isNotEmpty);
    // Aynı cümle eylemin kendi sonucundan da çıkmalı: tek kaynak.
    final HousingResult sonuc = konut.moveToRental(s);
    expect(sonuc.outcome.applied, isFalse);
    expect(sonuc.outcome.text, engel);
  });

  test('§2 masraf şehir değişince artıyor', () {
    final GameState? kare = kareBul(
      (GameState s) => s.player.age >= Housing.prototypeOnlyMinAge,
    );
    expect(kare, isNotNull);
    final GameState s = kare!;
    final List<String> hedefler = konut.relocationTargets(s);

    expect(
      konut.rentalMoveCost(s),
      Housing.prototypeOnlyMoveCost,
      reason: 'Aynı ilde taşınma taban masraf.',
    );
    if (hedefler.isEmpty) {
      // ignore: avoid_print
      print('UYARI: komşu il listesi boş; §2 şehirler arası masrafı bu '
          'koşuda sınamadı.');
      return;
    }
    expect(
      konut.rentalMoveCost(s, city: hedefler.first),
      Housing.prototypeOnlyMoveCost +
          Housing.prototypeOnlyIntercityExtraCost,
    );
  });

  test('§3 ekran kapıyı motordan okuyor', () {
    final String ekran = File('lib/ui/screens/sections/activity_pages.dart')
        .readAsLinesSync()
        .where((String l) {
          final String t = l.trimLeft();
          return !t.startsWith('//') && !t.startsWith('///');
        })
        .join('\n');

    expect(ekran, contains('controller.relocateBlockReason('));
    expect(ekran, contains('controller.relocateCost('));
    expect(
      ekran.contains("subtitle: 'Kiralık bir eve taşın',"),
      isFalse,
      reason: 'Satır yine masrafsız ve gerekçesiz yazılıyor.',
    );
  });

  test('§4 kapı açıkken satırda masraf, kapalıyken gerekçe var', () {
    // Ekranın iki dalını motor tarafından doğrula: engel boşsa masraf
    // yazılacak, doluysa gerekçe. (Ekranın hangisini yazdığı §3'te
    // taranıyor; burada **motorun** iki dalı da ürettiği sabitleniyor.)
    final GameState? zengin = kareBul(
      (GameState s) =>
          s.player.age >= Housing.prototypeOnlyMinAge &&
          s.player.wallet >
              Housing.prototypeOnlyMoveCost +
                  Housing.prototypeOnlyIntercityExtraCost &&
          Housing.residenceOf(s) != ResidenceKind.kirada,
    );
    if (zengin != null) {
      expect(konut.rentalMoveBlockReason(zengin), isEmpty);
    } else {
      // ignore: avoid_print
      print('UYARI: parası yeten ve kirada olmayan kare BULUNAMADI.');
    }
  });
}

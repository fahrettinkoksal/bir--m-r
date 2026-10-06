// Paket BJ — çocuk sahibi olmanın **oyuncu yolu** ölçülüyor.
//
// **Nasıl bulundu.** Beşinci döküm turunda "GEBELİK" 120 bot hayatında
// BULUNAMADI çıktı. Dördüncü turun dersi gereği önce dürbüne baktım:
// kanca doğruydu (yıl içi `onPreAge`), kusur başka yerdeydi.
//
// `GameController.haveChild()` **arayüzün hiçbir yerinden
// çağrılmıyor** (`lib/ui` altında tek çağrı yok). Oyuncunun çocuk
// sahibi olma yolu tek: eş/sevgiliyle **korunmadan** yakınlaşmak
// (`person_intimacy_button_partner`) → `Pregnancy` kaydı → ertesi yıl
// doğum. Bot ise `haveChild()` çağırıyor ve çocuğu tek hamlede
// yaratıyor; gebelik aşaması hiç oluşmuyor.
//
// Yani bot, aile ölçümlerini oyuncunun **kullanamadığı** bir kapıdan
// yapıyor. Bu bir ürün hatası değil, bir **ölçüm boşluğu** — ama
// ölçümün değerini doğrudan etkiliyor, bu yüzden yazılı duruyor
// (`docs/DESIGN_REVIEW_QUEUE.md`, Q-201).
//
// Bu test boşluğu kapatmıyor, oyuncunun yolunu **sabitliyor**: gebelik
// oluşuyor mu, doğumla kapanıyor mu, çocuk kayda giriyor mu. Durum
// kurulmuyor — bot gerçek hayatlar oynuyor, evli/sevgili olduğu bir yıl
// yakalanıyor, oradan sonrası oyuncunun kendi düğmesiyle sürüyor.
//
// **Neden istatistik.** Gebelik bir ihtimal: yıllık taban %45 ve hayat
// başında %8 kısırlık var (`Intimacy.prototypeOnly…`). Tek çift üstünden
// kurulan bir iddia bu yüzden kararsızdır — ilk yazımda tam bu yüzden
// bir koşuda kırmızı, bir koşuda yeşil oldu (kontrolcünün zarı da
// tohumsuzdu). Test artık tohumlu çiftlerle çalışıyor ve **oranı**
// denetliyor.
library;

import 'dart:math';

import 'package:bir_omur/data/health_crisis_catalog.dart';
import 'package:bir_omur/domain/interaction/intimacy.dart';
import 'package:bir_omur/domain/models/game_state.dart';
import 'package:bir_omur/domain/models/person.dart';
import 'package:bir_omur/domain/models/relation.dart';
import 'package:bir_omur/state/game_controller.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/player_bot.dart';

typedef Kare = ({GameState durum, String partnerId});

/// Bot hayatlarından, oyuncunun yakınlaşabileceği kareler toplar.
List<Kare> _kareler({required int enFazla}) {
  final List<Kare> bulunanlar = <Kare>[];
  for (final PlayerArchetype a in <PlayerArchetype>[
    PlayerArchetype.family,
    PlayerArchetype.career,
    PlayerArchetype.casual,
  ]) {
    for (int seed = 1; seed <= 60 && bulunanlar.length < enFazla; seed++) {
      Kare? buHayat;
      playBotLife(
        archetype: a,
        seed: seed * 31 + a.index,
        onPreAge: (GameState s) {
          if (buHayat != null) return;
          if (s.player.age < 22 || s.player.age > 38) return;
          if (s.isExpecting || s.children.isNotEmpty) return;
          final Person? es = Intimacy.partnerOf(s);
          if (es == null) return;
          if (Intimacy.blockReason(s, es).isNotEmpty) return;
          buHayat = (durum: s, partnerId: es.id);
        },
      );
      if (buHayat != null) bulunanlar.add(buHayat!);
    }
  }
  return bulunanlar;
}

/// Ekranı bekleyenlerden temizler.
///
/// **Bu çağrı denemeden ÖNCE gelmeli.** `GameController._runFamily`
/// bekleyen olay varken `null` dönüyor — ve bu doğru davranış: oyuncu da
/// olay penceresi açıkken menülere dokunamaz. İlk yazımda döngü yaş
/// aldıktan sonra çıkan olayı denemeden önce kapatmıyordu; sonuç olarak
/// ilk yıldan sonraki bütün yakınlaşmalar sessizce düşüyor ve ölçüm
/// "20 çiftin 14'ü sekiz yılda gebe kalmadı" diyordu. Oyunda böyle bir
/// hata yok; kurgum yanlıştı.
void _ekraniTemizle(GameController c) {
  int guard = 0;
  while (guard++ < 60) {
    if (c.state!.deceased) return;
    if (c.state!.hasNotice) {
      c.dismissNotice();
      continue;
    }
    if (c.state!.hasPendingCrisis) {
      final List<CrisisChoice> secenekler = c.pendingCrisis!.crisis!.choices;
      c.respondToCrisis(
        secenekler
            .firstWhere(c.canChooseCrisis, orElse: () => secenekler.last)
            .id,
      );
      continue;
    }
    if (c.state!.hasPendingEvent) {
      c.chooseEventOption(c.state!.pendingEvent!.choices.first.id);
      continue;
    }
    return;
  }
}

/// Bir yıl ilerletir; ilerlemediyse `false`.
bool _yilGec(GameController c) {
  _ekraniTemizle(c);
  final int once = c.state!.player.age;
  c.ageUp();
  return c.state!.player.age > once;
}

void main() {
  test('oyuncunun yolu: korunmadan yakınlaşma gebelik üretir', () {
    final List<Kare> kareler = _kareler(enFazla: 20);
    expect(kareler.length, greaterThanOrEqualTo(10),
        reason: 'taranan hayatlarda yakınlaşmaya uygun yeterli kare '
            'çıkmadı (${kareler.length}); ya tarama bozuk ya oyuncunun '
            'yolu kapalı');

    int gebeKalan = 0;
    final List<int> yillar = <int>[];
    for (int i = 0; i < kareler.length; i++) {
      final Kare kare = kareler[i];
      // Kontrolcünün zarı **tohumlu**: ölçüm koşudan koşuya oynamaz.
      final GameController c = GameController(random: Random(9000 + i))
        ..debugSetState(kare.durum);
      int yil = 0;
      while (!c.state!.isExpecting && yil < 8) {
        _ekraniTemizle(c);
        if (c.state!.deceased) break;
        if (c.intimacyAvailability(kare.partnerId).isAllowed) {
          c.beIntimate(kare.partnerId, Protection.korunmadan);
        }
        if (c.state!.isExpecting) break;
        if (!_yilGec(c)) break;
        yil++;
      }
      if (c.state!.isExpecting) {
        gebeKalan++;
        yillar.add(yil);
      }
      c.dispose();
    }

    final double oran = gebeKalan / kareler.length;
    yillar.sort();
    // ignore: avoid_print
    print('OLCUM — oyuncu yolu: ${kareler.length} çift, gebe kalan '
        '$gebeKalan (%${(oran * 100).round()}), 8 yıl içinde; '
        'ortanca bekleme ${yillar.isEmpty ? "-" : yillar[yillar.length ~/ 2]} '
        'yıl');

    // Taban %45 ve kısırlık %8 ile sekiz yılda beklenen oran çok yüksek.
    // Eşik bilerek gevşek: amaç kalibrasyon değil, **yolun tıkanmasını**
    // yakalamak.
    expect(oran, greaterThan(0.7),
        reason: 'korunmadan yakınlaşan çiftlerin yalnızca '
            '%${(oran * 100).round()}\'i sekiz yılda gebe kaldı; '
            'oyuncunun çocuk sahibi olma yolu tıkanmış olabilir');
  });

  test('gebelik doğumla kapanır, çocuk kayda girer', () {
    final List<Kare> kareler = _kareler(enFazla: 12);
    expect(kareler, isNotEmpty);

    int gebelikGoren = 0;
    int dogumlaKapanan = 0;
    for (int i = 0; i < kareler.length; i++) {
      final Kare kare = kareler[i];
      final GameController c = GameController(random: Random(4100 + i))
        ..debugSetState(kare.durum);
      int yil = 0;
      while (!c.state!.isExpecting && yil < 8) {
        _ekraniTemizle(c);
        if (c.state!.deceased) break;
        if (c.intimacyAvailability(kare.partnerId).isAllowed) {
          c.beIntimate(kare.partnerId, Protection.korunmadan);
        }
        if (c.state!.isExpecting) break;
        if (!_yilGec(c)) break;
        yil++;
      }
      if (!c.state!.isExpecting) {
        c.dispose();
        continue;
      }
      gebelikGoren++;

      // Gebelik kaydı kendi içinde tutarlı olmalı.
      expect(c.state!.pregnancy!.partnerId, kare.partnerId,
          reason: 'gebelik başka birinin üstüne yazılmış');
      expect(c.state!.pregnancy!.startedAtAge,
          lessThanOrEqualTo(c.state!.player.age));

      final int oncekiCocuk = c.state!.children.length;
      int gebelikYili = 0;
      while (c.state!.isExpecting && gebelikYili < 4) {
        if (!_yilGec(c)) break;
        gebelikYili++;
      }
      if (!c.state!.isExpecting && c.state!.children.length > oncekiCocuk) {
        dogumlaKapanan++;
        // Doğan çocuk gerçekten yeni olmalı.
        expect(
            c.state!.people.where((Person p) =>
                p.relation == RelationType.cocuk && p.isAlive && p.age <= 1),
            isNotEmpty,
            reason: 'doğumdan sonra 0-1 yaşında çocuk yok');
      }
      c.dispose();
    }

    // ignore: avoid_print
    print('OLCUM — gebelik: $gebelikGoren gebelik, '
        '$dogumlaKapanan tanesi dört yıl içinde doğumla kapandı');

    expect(gebelikGoren, greaterThan(0), reason: 'hiç gebelik oluşmadı');
    expect(dogumlaKapanan, gebelikGoren,
        reason: 'bazı gebelikler dört yılda kapanmadı ya da çocuk kayda '
            'girmedi: $dogumlaKapanan/$gebelikGoren');
  });
}

// Paket CQ — **kulüpteki yerin adı.**
//
// **Nereden çıktı.** Paket CE "kulüp zincirinin derinliği pencereye
// sığmıyor" diye ölçmüş ve dört futbol olayının ikinci halkalarını
// Q-224'e bırakmıştı. O hunideki asıl soru "ilk 11'e kim çıkıyor"du;
// 150 bot hayatında kulüp üyeliklerinin rol dağılımı ölçüldü:
//
// | Kulüp | Üyelik | İlk 11+ | Puan ortanca (en çok) |
// |---|---|---|---|
// | `satranc_kulubu` | 44 | 16 | 34 (73) |
// | `halk_oyunlari` | 43 | **0** | 30 (64) |
// | `atletizm` | 35 | 15 | 42 (78) |
// | `muzik_kulubu` | 28 | **0** | 33 (55) |
// | `tiyatro_kulubu` | 26 | **0** | 42 (**73**) |
// | `fotograf_kulubu` | 21 | **0** | 39 (**70**) |
// | `futbol_takimi` | 21 | 6 | 32 (73) |
//
// Dört kulüpte **hiç** rol yükselmiyor, çünkü `SchoolClubEngine`
// rolü yalnızca `club.competitive` olan kulüpte atıyor. Ama kart
// `uyelik.role.label` yazıyordu: fotoğraf kulübünde sekiz yıl geçiren
// oyuncu ekranda **"Yedek"** okuyor. Hem yanlış (fotoğraf kulübünde
// yedek diye bir şey yok) hem de yanıltıcı: aynı üyeliğin rol puanı
// 70'e çıkıyor, yani oyuncu gerçekten ilerliyor.
//
// **Düzeltme ekran tarafında.** `SchoolClubEngine.standingLabel` saf
// bir fonksiyon: rekabetçi kulüpte rolün adını döndürür, rekabetçi
// olmayanda aynı rol puanından türeyen bir ad (Yeni üye · Düzenli üye
// · Çekirdek ekip · Kulübün yüzü). Motor, kayıt ve olay kapıları
// **değişmedi** — bu dosyanın dördüncü testi onu bekçiliyor.
//
// **Ölçüm (düzeltmeden sonra, 150 hayat):** rekabetçi olmayan 118
// üyeliğin etiketleri Yeni üye 58 · Düzenli üye 35 · Çekirdek ekip 20
// · Kulübün yüzü 5. Düzeltmeden önce **118'inin hepsi "Yedek"**ti.
//
// **Yapmadığım şey:** Q-224'teki yoğunluk kararına (üyelik sürerken
// yılda bir kulüp olayı garanti edilsin mi) dokunmadım; ne ağırlık
// büyüttüm ne eşik indirdim. Penaltı zincirinin izi hâlâ seyrek ve o
// karar Faho'da.
//
// Durum kurulmuyor: kareler bot hayatlarında bulunuyor.
library;

import 'dart:math';

import 'package:bir_omur/data/event_pool.dart';
import 'package:bir_omur/data/school_club_catalog.dart';
import 'package:bir_omur/domain/models/game_event.dart';
import 'package:bir_omur/domain/models/game_state.dart';
import 'package:bir_omur/domain/models/school_club_progress.dart';
import 'package:bir_omur/domain/sports/school_club_engine.dart';
import 'package:bir_omur/state/game_controller.dart';
import 'package:bir_omur/state/game_scope.dart';
import 'package:bir_omur/ui/screens/sections/school_clubs_page.dart';
import 'package:bir_omur/ui/theme/bir_omur_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/player_bot.dart';

SchoolClub? _kulup(String id) =>
    kSchoolClubs.where((SchoolClub c) => c.id == id).firstOrNull;

/// Bot hayatlarındaki kulüp üyelikleri (zirve puanıyla).
typedef _Uyelik = ({
  SchoolClub kulup,
  SchoolClubProgress ilerleme,
  int karizma,
  GameState kare
});

List<_Uyelik> _tara({int tohum = 191, int adet = 15}) {
  final List<_Uyelik> hepsi = <_Uyelik>[];
  for (final PlayerArchetype a in PlayerArchetype.values) {
    for (int seed = 1; seed <= adet; seed++) {
      final Map<String, _Uyelik> enIyi = <String, _Uyelik>{};
      playBotLife(
        archetype: a,
        seed: seed * tohum + a.index,
        onPreAge: (GameState s) {
          for (final SchoolClubProgress p in s.schoolClubs) {
            final SchoolClub? k = _kulup(p.clubId);
            if (k == null) continue;
            final int puan = SchoolClubEngine.roleScore(
              skill: p.skill,
              years: p.yearsActive,
              performance: p.performance,
              charisma: s.player.stats.charisma,
            );
            final String anahtar = '${p.clubId}/${p.joinedAtAge}';
            final _Uyelik? onceki = enIyi[anahtar];
            final int oncekiPuan = onceki == null
                ? -1
                : SchoolClubEngine.roleScore(
                    skill: onceki.ilerleme.skill,
                    years: onceki.ilerleme.yearsActive,
                    performance: onceki.ilerleme.performance,
                    charisma: onceki.karizma,
                  );
            if (puan > oncekiPuan) {
              enIyi[anahtar] = (
                kulup: k,
                ilerleme: p,
                karizma: s.player.stats.charisma,
                kare: s,
              );
            }
          }
        },
      );
      hepsi.addAll(enIyi.values);
    }
  }
  return hepsi;
}

List<_Uyelik>? _onbellek;
List<_Uyelik> get _uyelikler => _onbellek ??= _tara();

void main() {
  test('rekabetçi olmayan kulüpte "Yedek" yazmıyor', () {
    final List<_Uyelik> rekabetsiz = _uyelikler
        .where((_Uyelik u) => !u.kulup.competitive)
        .toList(growable: false);
    expect(rekabetsiz.length, greaterThan(40),
        reason: 'rekabetçi olmayan üyelik az: ${rekabetsiz.length}');
    for (final _Uyelik u in rekabetsiz) {
      final String etiket = SchoolClubEngine.standingLabel(
        club: u.kulup,
        progress: u.ilerleme,
        charisma: u.karizma,
      );
      expect(etiket, isNot(SquadRole.yedek.label),
          reason: '${u.kulup.id} üyeliğinde ekran yine "Yedek" diyor '
              '(beceri ${u.ilerleme.skill}, '
              'yıl ${u.ilerleme.yearsActive})');
      expect(etiket, isNotEmpty);
    }
  });

  test('rekabetçi kulüpte rolün adı aynen kalıyor', () {
    final List<_Uyelik> rekabetci = _uyelikler
        .where((_Uyelik u) => u.kulup.competitive)
        .toList(growable: false);
    expect(rekabetci.length, greaterThan(80),
        reason: 'rekabetçi üyelik az: ${rekabetci.length}');
    for (final _Uyelik u in rekabetci) {
      expect(
        SchoolClubEngine.standingLabel(
          club: u.kulup,
          progress: u.ilerleme,
          charisma: u.karizma,
        ),
        u.ilerleme.role.label,
        reason: 'spor kulübünde etiket rolden kopmamalı',
      );
    }
  });

  test('etiket dört kademeyi de kullanıyor', () {
    // Ölçüm (150 hayat): Yeni üye 58 · Düzenli üye 35 · Çekirdek ekip
    // 20 · Kulübün yüzü 5. Tabanlar belirgin altında; biri sıfıra
    // düşerse o kademe ölü içerik olur.
    final Map<String, int> say = <String, int>{};
    for (final _Uyelik u in _uyelikler) {
      if (u.kulup.competitive) continue;
      final String e = SchoolClubEngine.standingLabel(
        club: u.kulup,
        progress: u.ilerleme,
        charisma: u.karizma,
      );
      say[e] = (say[e] ?? 0) + 1;
    }
    expect(say['Yeni üye'] ?? 0, greaterThanOrEqualTo(20), reason: '$say');
    expect(say['Düzenli üye'] ?? 0, greaterThanOrEqualTo(10), reason: '$say');
    expect(say['Çekirdek ekip'] ?? 0, greaterThanOrEqualTo(5), reason: '$say');
    expect(say['Kulübün yüzü'] ?? 0, greaterThanOrEqualTo(1), reason: '$say');
  });


  testWidgets('kulüp kartı ekranda türetilmiş etiketi yazıyor',
      (WidgetTester tester) async {
    // Kare **bulunuyor**: rekabetçi olmayan, en az üç yıllık bir
    // üyelik. Ekran dökümünün dersi (Paket CL): anahtar testi değil,
    // çizilen metin okunmalı.
    // Üyelik **o karede sürüyor** olmalı: ekran ayrılınmış kulüpleri
    // "Geçmiş" bölümünde gösteriyor, kartı çizmiyor. İlk yazımda bu
    // koşul yoktu ve test, kartı hiç çizilmeyen bir tiyatro üyeliğiyle
    // kırmızıya düştü.
    final _Uyelik? kare = _uyelikler
        .where((_Uyelik u) =>
            !u.kulup.competitive &&
            u.ilerleme.yearsActive >= 3 &&
            u.ilerleme.active &&
            u.kare.schoolClubs.any((SchoolClubProgress p) =>
                p.clubId == u.kulup.id && p.active))
        .firstOrNull;
    expect(kare, isNotNull,
        reason: 'rekabetçi olmayan, süren, üç yıllık üyelik bulunamadı');

    tester.view.physicalSize = const Size(1080, 5400);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final GameController c = GameController(random: Random(7))
      ..debugSetState(kare!.kare);
    addTearDown(c.dispose);
    await tester.pumpWidget(GameScope(
      controller: c,
      child: MaterialApp(
        theme: BirOmurTheme.light(),
        home: Scaffold(body: SchoolClubsPage(onBack: () {})),
      ),
    ));
    await tester.pumpAndSettle();

    final String beklenen = SchoolClubEngine.standingLabel(
      club: kare.kulup,
      progress: kare.ilerleme,
      charisma: kare.karizma,
    );
    expect(find.text(beklenen), findsWidgets,
        reason: '${kare.kulup.id} kartında "$beklenen" yazmıyor');
    expect(find.text(SquadRole.yedek.label), findsNothing,
        reason: 'rekabetçi olmayan kulüpte ekran yine "Yedek" diyor');
  });

  test('etiket olay kapılarına sızmıyor: minSquadRole hep kulübe bağlı',
      () {
    // Rol alanı yalnızca rekabetçi kulüplerde atanıyor; `minSquadRole`
    // kullanan bir olay kulüp kimliği istemezse, rekabetçi olmayan bir
    // kulüpte takılı kalan `yedek` rolü yüzünden o olay sessizce
    // kapanır (ya da ileride etiket motora taşınırsa yanlışlıkla
    // açılır). Bu yüzden eşleşme zorunlu.
    final List<String> kulupsuz = <String>[
      for (final GameEvent e in kEventPool)
        if (e.requirement.minSquadRole != null &&
            e.requirement.requiresActiveClubId == null)
          e.id,
    ];
    expect(kulupsuz, isEmpty,
        reason: 'bu olaylar rol istiyor ama kulüp belirtmiyor: $kulupsuz');
  });
}

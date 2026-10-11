// Ekran dökümü, üçüncü tur: **özel durumlar**.
//
// **Neden var.** İlk iki döküm (`ekran_dokumu_test.dart` ve
// `ekran_dokumu_bot_test.dart`) sıradan hayatların ekranlarını okudu ve
// yedi gerçek hata buldu. Ama bazı ekranlar hiçbirinde görünmedi,
// çünkü o duruma düşmek şans işi:
//
//   · cezaevi · bekleyen duruşma · kritik sağlık (cevap bekleyen kriz)
//   · yeni doğmuş bebek · emeklilik sonrası
//
// Bunları `copyWith` ile **kurmak** cazip ama tehlikeli: bu dürbünün
// ilk turunda tam o yüzden yanlış bulgu üretmiştim (oyuncuyu
// yaşlandırıp dünyayı yerinde bırakmak, 8 yaşındaki çocuğa 22 yaşında
// anne). Bu yüzden durum **kurulmuyor, aranıyor**: bot yüzlerce hayat
// oynuyor, her yıl kontrol ediliyor ve aranan koşul gerçekten
// oluştuğunda o yılın karesi fotoğraflanıyor.
//
// Bir koşul taranan tohumlarda hiç oluşmazsa test **"BULUNAMADI"**
// yazar ve geçer. Bu bilerek: bulunamamak bir ürün hatası değil, ama
// "okundu" da sayılmaz — çıktıda açıkça görünür.
//
// **ÖLÇÜLEN HATA (dördüncü tur).** İlk yazımda "YENİ DOĞAN BEBEK"
// BULUNAMADI çıkıyordu ve bunu oyunun bir eksiği sanmaya başlamıştım.
// Değildi: tarama kancası `onYear`, yani **yaş aldıktan sonra**
// çalışıyor; doğduğu yıl 0 yaşında olan bebeği `ageUp()` 1 yaşına
// taşıdığı için o kare hiç görünmüyordu. 60 hayatta ölçüm: yıl içinde
// 0 yaşında çocuk **77 kare**, yıl sonunda **0 kare**. Yıl içi durumlar
// bu yüzden `onPreAge` ile aranıyor. Ders yine aynı: aranan şey
// bulunamadığında önce dürbüne bak.
// **BU TUR NE BULDU (Paket CG, 10 Ekim 2026).** Yedi karenin hepsi
// bulundu — "BULUNAMADI" kalmadı — ve çıktı okununca üç yer yanlış
// yazıyordu. Üçü de hükümlü karesinden çıktı ve ikisi metin değil
// **eksik kapı**ydı:
//
//   · Künye "Evde seninle 3 kişi yaşıyor" diyordu; oyuncu içerideydi.
//   · Varlıklar "Yaşadığın yer: Ailesinin yanında" diyor ve "Kiralık
//     eve çık" düğmesi **açık** duruyordu: konut motoru hiçbir yerde
//     `isImprisoned`'a bakmıyordu.
//   · Hasta hayvan bildirimi "Aktiviteler → Evcil Hayvanlar'dan
//     veterinere götürebilirsin" diyordu; o sekmede içerideyken
//     yalnızca "İçeride yapılabilecekler" var.
//
// Bebek karesi de bir hata verdi: doğum satırı oyunun verdiği geçici
// adı tutuyor, ad verme ikinci bir satır ekliyordu; günlükte aynı yılda
// iki ad duruyordu. Bekçi: `paket_cg_icerde_tasinma_ve_bebek_adi_test`.
// **BU TUR NE BULDU (Paket CL, 10 Ekim 2026).** Dökümün kapsamına bu
// oturumun iki yeni kartı eklendi (`YAŞLILIKTA BAKIM`, `ARKADAŞ
// GRUBU`); dokuz karenin hepsi bulundu ve çıktı okununca iki kusur
// çıktı — ikisi de **kendi testlerinin göremediği** türdendi, çünkü o
// testler anahtar ve tek tek metin denetliyor, döküm ise ekranın
// tamamını basıyor:
//
//   · Bakım kartı kapının gerekçesini durum satırında da yazıyordu:
//     "Yanında olabilecek kimse yok." cümlesi üst üste iki kez.
//   · Grubu süren oyuncu İlişkiler ekranının üst düzeyinde grubunun
//     **hiç izini** görmüyordu; grup kartı yalnızca Arkadaşlar alt
//     sayfasında. Aynı ekranda hayvan satırı "Leblebi seninle
//     yaşıyor" diye özet veriyordu, yani kalıp zaten vardı.
//
// Bekçi: `paket_cl_ekran_okumasi_test.dart`.
library;

import 'dart:math';

import 'package:bir_omur/app.dart';
import 'package:bir_omur/domain/interaction/elder_support.dart';
import 'package:bir_omur/domain/interaction/friend_circles.dart';
import 'package:bir_omur/domain/interaction/intimacy.dart';
import 'package:bir_omur/domain/models/game_event.dart';
import 'package:bir_omur/domain/models/game_state.dart';
import 'package:bir_omur/domain/models/marriage.dart';
import 'package:bir_omur/domain/models/person.dart';
import 'package:bir_omur/domain/models/relation.dart';
import 'package:bir_omur/state/game_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/player_bot.dart';
import 'support/test_flow.dart';

/// Alt çubuktaki dört menü (NAV-001); Hayat varsayılan ekran.
const List<(String, String)> kSekmeler = <(String, String)>[
  ('tab_okul_meslek', 'Okul / Meslek'),
  ('tab_varliklar', 'Varlıklar'),
  ('tab_iliskiler', 'İlişkiler'),
  ('tab_aktiviteler', 'Aktiviteler'),
];

/// Mülakat penceresini açar: Okul/Meslek sekmesine gidip satıra basar.
///
/// **Sessizce başarısız olmaz.** İlk yazımda bulamadığı şeyde `return`
/// ediyordu; döküm o yüzden sıradan bir ekran basıyor ve pencerenin
/// açılmadığı anlaşılmıyordu. Araç yalan söylememeli: ne yaptığını
/// yazıyor, dökümün başına basılıyor.
Future<String> _mulakatiAc(WidgetTester tester) async {
  final Finder sekme = find.byKey(const Key('tab_okul_meslek'));
  if (sekme.evaluate().isEmpty) {
    return 'AÇICI: Okul/Meslek sekmesi ekranda yok — pencere açılamadı.';
  }
  await tester.tap(sekme);
  await tester.pumpAndSettle();
  final Finder satir = find.byKey(const Key('career_mulakat_devam'));
  if (satir.evaluate().isEmpty) {
    // **Suçu satıra atmadan önce nerede olduğunu söyle.** İlk yazımda
    // bu dal "Okul/Meslek açıldı ama satır yok" diyordu; oysa sekmeye
    // basıldığını doğrulamış, ekranın gerçekten değiştiğini
    // doğrulamamıştım. Araç gördüğünü yazar, varsaydığını yazmaz.
    final List<String> ekran = <String>[
      for (final Text w in tester.widgetList<Text>(find.byType(Text)))
        if ((w.data ?? w.textSpan?.toPlainText())?.trim().isNotEmpty ?? false)
          (w.data ?? w.textSpan!.toPlainText()).trim(),
    ];
    return 'AÇICI: "Mülakata devam et" satırı bulunamadı. '
        'Ekranda ${ekran.length} metin var; ilk altısı: '
        '${ekran.take(6).join(" · ")}';
  }
  await tester.tap(satir);
  await tester.pumpAndSettle();
  return 'AÇICI: mülakat penceresi satıra basılarak açıldı.';
}

/// Aranan özel durum.
class Durum {
  const Durum(
    this.ad,
    this.kosul, {
    this.ekranTemizlenmesin = false,
    this.yilIci = false,
    this.bekleyen = false,
    this.acici,
  });

  final String ad;
  final bool Function(GameState) kosul;

  /// Kritik sağlık ve duruşma gibi durumlarda bekleyen pencere
  /// **durumun kendisi**; onu kapatmak dökülecek şeyi yok eder.
  final bool ekranTemizlenmesin;

  /// Yalnızca **yıl içinde** var olan durum: yaş alma öncesinde aranır.
  ///
  /// Yeni doğan bebek böyledir; `onYear` ile hiç bulunamaz (dosya
  /// başlığındaki ölçüm).
  final bool yilIci;

  /// Kare **bekleyen bir şey varken** aranıyor (Paket CV).
  ///
  /// `onPreAge` yılın 7. adımında çalışıyor; bot bekleyen mülakatı,
  /// olayı ya da krizi 1-6. adımlarda yanıtlayıp `continue` ettiği için
  /// o kareler eski iki kancaya seyrek görünüyor. Paket CR'nin
  /// `onPending` kancası bekleyen kareyi **yanıtlanmadan önce**
  /// veriyor. Ölçüldü (120 hayat): bekleyen mülakat karesi `onPending`
  /// ile **950** (120/120 hayat), `onPreAge` ile 180 (99/120) — yani
  /// 5,3 kat. Mülakat ekranı bu yüzden hiç dökülmemişti.
  final bool bekleyen;

  /// Kareyi basmadan **önce** pencereyi açan adım (Paket CV).
  ///
  /// Duruşma ve kriz pencereleri yüklenen durumda kendiliğinden
  /// açılıyor; mülakat gibi bir satıra dokunarak açılanlar için bu
  /// gerekiyor. `null` ise ek bir şey yapılmaz.
  final Future<String> Function(WidgetTester tester)? acici;
}

void main() {
  late GameController controller;
  bool acildi = false;
  setUp(() {
    controller = GameController(random: Random(31));
    acildi = false;
  });
  tearDown(() => controller.dispose());

  List<String> metinler(WidgetTester tester) {
    final List<String> out = <String>[];
    for (final Text w in tester.widgetList<Text>(find.byType(Text))) {
      final String? d = w.data ?? w.textSpan?.toPlainText();
      if (d == null) continue;
      final String t = d.trim().replaceAll(RegExp(r'\s+'), ' ');
      if (t.isNotEmpty) out.add(t);
    }
    return out;
  }

  Future<void> ac(WidgetTester tester, GameState durum) async {
    if (!acildi) {
      tester.view.physicalSize = const Size(1200, 14000);
      tester.view.devicePixelRatio = 3;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(BirOmurApp(controller: controller));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Rastgele bir hayat'));
      await tester.pumpAndSettle();
      acildi = true;
    }
    controller.debugSetState(durum);
    await tester.pumpAndSettle();
  }

  Future<void> ekraniTemizle(WidgetTester tester) async {
    for (int tur = 0; tur < 40; tur++) {
      await tester.pumpAndSettle();
      if (controller.state!.deceased) return;
      // **Önceki kareden kalan kriz penceresi.** Kritik sağlık karesi
      // bilerek pencereyi açık bırakıyor; bir sonraki kare açıldığında
      // o pencere hâlâ gezinti yığınında duruyor ve yeni durumda kriz
      // olmadığı için boş sonuçla ("Durum kapandı.") görünüp sekmeleri
      // kilitliyor. Dördüncü turda bebek karesi tam bu yüzden yanlış
      // ekranı basmıştı.
      if (controller.state!.hasPendingCrisis ||
          find.byKey(const Key('crisis_result_title')).evaluate().isNotEmpty) {
        await answerPendingCrisis(tester, controller);
        continue;
      }
      if (controller.state!.hasNotice) {
        await answerPendingNotices(tester, controller);
        continue;
      }
      final ActiveEvent? olay = controller.state!.pendingEvent;
      if (olay != null) {
        final EventChoice secim = olay.choices.first;
        final Finder dugme = find.text(secim.label);
        if (dugme.evaluate().isEmpty) {
          controller.chooseEventOption(secim.id);
          continue;
        }
        await tester.tap(dugme);
        await tester.pumpAndSettle();
        final Finder devam = find.text('Devam');
        if (devam.evaluate().isNotEmpty) {
          await tester.tap(devam);
          await tester.pumpAndSettle();
        }
        continue;
      }
      return;
    }
  }

  /// Taranan arketipler ve tohum aralığı.
  ///
  /// Riskli hayat suç/hukuk için, aile odaklı doğum için, rahat hayat
  /// kritik sağlık ve emeklilik için. Tohum sayısı bilerek ölçülü:
  /// amaç istatistik değil, **bir örnek bulmak**.
  const List<PlayerArchetype> arketipler = <PlayerArchetype>[
    PlayerArchetype.risky,
    PlayerArchetype.family,
    PlayerArchetype.casual,
  ];
  const int tohumSayisi = 40;

  final List<Durum> aranan = <Durum>[
    Durum('CEZAEVİ', (GameState s) => s.isImprisoned),
    Durum('BEKLEYEN DURUŞMA', (GameState s) => s.hasPendingTrial,
        ekranTemizlenmesin: true),
    Durum('KRİTİK SAĞLIK', (GameState s) => s.hasPendingCrisis,
        ekranTemizlenmesin: true),
    Durum(
      'YENİ DOĞAN BEBEK',
      (GameState s) => s.people.any((Person p) =>
          p.relation == RelationType.cocuk && p.isAlive && p.age == 0),
      yilIci: true,
    ),
    Durum('EMEKLİ', (GameState s) => s.career.isRetired),
    // Beşinci tur: kalan iki okunmamış ekran. İkisi de yıl içinde
    // yaşanıp yıl sonunda kaybolabiliyor, bu yüzden yıl içi kancayla
    // aranıyor (gebelik doğumla kapanır, denetim dönemi yaşla biter).
    Durum(
      'DENETİM DÖNEMİ',
      (GameState s) => s.legal.probationUntilAge != null,
      yilIci: true,
    ),
    Durum('GEBELİK', (GameState s) => s.isExpecting, yilIci: true),
    // Altıncı tur (Paket CL): bu oturumda yazılan iki kart hiçbir
    // dökümde **bütün ekran** olarak çizilmemişti. Kendi testleri
    // anahtar ve metin denetliyor; döküm ise ekranın tamamını basıyor
    // ve üç turda sekiz gerçek hata tam bu farktan çıktı.
    //
    // Bakım kararı yıl içinde yaşanıyor ve **botun kendi kararı**
    // kapıları kapattığı için (karar yılın başında veriliyor) bu kare
    // aşağıda ayrı bir turda, `BotOverrides(noElderSupport: true)` ile
    // aranıyor: oyunun sayıları değişmez, yalnızca botun tercihi
    // kapanır ve kapılar açık yakalanır.
    Durum(
      'YAŞLILIKTA BAKIM',
      (GameState s) =>
          ElderSupport.needsSupport(s) && !ElderSupport.decidedThisYear(s),
      yilIci: true,
    ),
    Durum(
      'ARKADAŞ GRUBU',
      (GameState s) => FriendCircles.activeOf(s) != null,
    ),
    // Yedinci tur (Paket CT): **dul** oyuncunun ekranları hiçbir
    // dökümde basılmadı. Paket CS 250 hayatta 502 dul yılı ölçtü ve o
    // yıllara 20 olay yazdı; ekran tarafı ise hiç okunmadı. Hükümlü
    // karesi tam bu okumadan üç hata vermişti ("Evde seninle 3 kişi
    // yaşıyor" diyen künye içerideyken) — dul kare de hane, eş kartı
    // ve aktivite arkadaşı bakımından aynı riski taşıyor.
    Durum(
      'DUL',
      (GameState s) => s.marriage?.status == MarriageStatus.dul,
    ),
    // Sekizinci tur (Paket CV): üç ekran daha hiç dökülmemişti.
    //
    // Mülakat ve bekleyen olay **bekleyen** karelerdir: bot onları
    // yılın başında yanıtlıyor, bu yüzden Paket CR'nin `onPending`
    // kancasıyla aranıyorlar. Geçim sıkıntısı ise yıl içinde oluşup
    // yıl sonuna kalabiliyor; o `yilIci` ile aranıyor.
    // **Mülakat penceresi kendiliğinden açılmıyor.** Duruşma ve kriz
    // pencereleri yüklenen durumda otomatik açılıyor, bu yüzden onlar
    // `ekranTemizlenmesin` ile okunabiliyordu. Mülakat ise bir satıra
    // dokunarak açılıyor (`career_mulakat_devam`). İlk yazımda bu kare
    // de `ekranTemizlenmesin` ile konmuştu ve sonuç en işe yaramaz
    // bileşimdi: pencere açılmadı, dört sekme de basılmadı. Kare artık
    // kendi **açıcısıyla** geliyor: Okul/Meslek sekmesine gidiliyor ve
    // satıra basılıyor.
    // **MÜLAKAT penceresi hâlâ OKUNMADI.** Kare bulunuyor (ölçüldü:
    // `onPending` ile 120 hayatın 120'sinde, 950 kare) ve açıcı
    // çalışıyor ama pencere açılmıyor: alt sekmeye basmak bu koşumda
    // Meslek ekranını getirmiyor, ekranda Aktiviteler kalıyor. Açıcı
    // bunu dökümün başına **yazıyor** — sessizce geçmiyor. Yani bu
    // satır "okundu" değil, "aranıyor ve neden okunamadığı yazılı"
    // demek. Aynı dürüstlük kuralı dosyanın başındaki BULUNAMADI
    // kuralıyla aynı: bulunamamak ürün hatası değil, ama okundu da
    // sayılmaz.
    Durum(
      'MÜLAKAT',
      (GameState s) => s.hasPendingInterview,
      bekleyen: true,
      ekranTemizlenmesin: true,
      acici: _mulakatiAc,
    ),
    // **BEKLEYEN OLAY karesi bilerek yok.** Olay penceresi yalnızca yaş
    // alırken doğuyor; yüklenen bir durumda ne kendiliğinden açılıyor
    // ne de onu açan bir satır var. Dökümün yapabileceği tek şey
    // pencereyi kapatıp sıradan bir hayat basmak olurdu, o da yeni bir
    // şey okumaz. Olay penceresinin kendi testleri var (`event_dialog`,
    // `paket_bd_durusma_penceresi_test`).
    Durum(
      'GEÇİM SIKINTISI',
      (GameState s) => s.hardshipYears > 0,
      yilIci: true,
    ),
  ];

  testWidgets('EKRAN DÖKÜMÜ — özel durumlar (taranarak bulundu)',
      (WidgetTester tester) async {
    // 1) Durumları ara. Her durum için **ilk** bulunan kare saklanır.
    final Map<String, (GameState durum, int seed, PlayerArchetype a)> kareler =
        <String, (GameState, int, PlayerArchetype)>{};
    int taranan = 0;
    for (final PlayerArchetype arketip in arketipler) {
      for (int seed = 1; seed <= tohumSayisi; seed++) {
        if (kareler.length == aranan.length) break;
        taranan++;
        playBotLife(
          archetype: arketip,
          seed: seed * 101 + arketip.index,
          onYear: (GameState s) {
            for (final Durum d in aranan) {
              if (d.yilIci || kareler.containsKey(d.ad)) continue;
              if (d.kosul(s)) {
                kareler[d.ad] = (s, seed, arketip);
              }
            }
          },
          onPending: (GameState s) {
            for (final Durum d in aranan) {
              if (!d.bekleyen || kareler.containsKey(d.ad)) continue;
              if (d.kosul(s)) {
                kareler[d.ad] = (s, seed, arketip);
              }
            }
          },
          onPreAge: (GameState s) {
            for (final Durum d in aranan) {
              if (!d.yilIci || kareler.containsKey(d.ad)) continue;
              if (d.kosul(s)) {
                kareler[d.ad] = (s, seed, arketip);
              }
            }
          },
        );
      }
    }

    // 1b) **Gebelik botun kapısından geçmiyor.** Bot `haveChild()`
    // çağırıyor ve çocuğu tek hamlede yaratıyor; oyuncunun yolu ise
    // korunmadan yakınlaşmak → gebelik → ertesi yıl doğum (Q-201,
    // `paket_bj_oyuncu_yolu_cocuk_test.dart`). Bu yüzden gebelik karesi
    // taramayla değil, **oyuncunun kendi düğmesiyle** üretiliyor:
    // bot gerçek bir hayat oynuyor, evli olduğu bir yıl alınıyor ve
    // oradan sonrası gerçek eylem. Durum elle kurulmuyor.
    if (!kareler.containsKey('GEBELİK')) {
      final GameController kurucu = GameController(random: Random(77));
      for (final PlayerArchetype arketip in arketipler) {
        if (kareler.containsKey('GEBELİK')) break;
        for (int seed = 1; seed <= 20; seed++) {
          if (kareler.containsKey('GEBELİK')) break;
          GameState? evliKare;
          String? partnerId;
          playBotLife(
            archetype: arketip,
            seed: seed * 101 + arketip.index,
            onPreAge: (GameState s) {
              if (evliKare != null) return;
              if (s.player.age < 22 || s.player.age > 38) return;
              if (s.isExpecting || s.player.infertile) return;
              final Person? es = Intimacy.partnerOf(s);
              if (es == null || es.infertile) return;
              if (Intimacy.blockReason(s, es).isNotEmpty) return;
              evliKare = s;
              partnerId = es.id;
            },
          );
          if (evliKare == null) continue;
          kurucu.debugSetState(evliKare!);
          for (int yil = 0; yil < 8 && !kurucu.state!.isExpecting; yil++) {
            int guard = 0;
            while (guard++ < 40) {
              if (kurucu.state!.deceased) break;
              if (kurucu.state!.hasNotice) {
                kurucu.dismissNotice();
                continue;
              }
              if (kurucu.state!.hasPendingEvent) {
                kurucu.chooseEventOption(
                    kurucu.state!.pendingEvent!.choices.first.id);
                continue;
              }
              break;
            }
            if (kurucu.state!.deceased) break;
            if (kurucu.intimacyAvailability(partnerId!).isAllowed) {
              kurucu.beIntimate(partnerId!, Protection.korunmadan);
            }
            if (kurucu.state!.isExpecting) break;
            final int once = kurucu.state!.player.age;
            kurucu.ageUp();
            if (kurucu.state!.player.age == once) break;
          }
          if (kurucu.state!.isExpecting) {
            kareler['GEBELİK'] = (kurucu.state!, seed, arketip);
          }
        }
      }
      kurucu.dispose();
    }

    // 1c) **Bakım kararı botun kendi kapısından geçiyor.** Bot kararı
    // yılın başında veriyor, bu yüzden `onPreAge` ile taranan her kare
    // "bu yılın kararı verilmiş" oluyor ve üç kapı hiç çizilmiyor
    // (Paket CJ'nin bekçisinde ölçülen şeyin aynısı). Kare burada
    // botun o politikası kapatılarak aranıyor; durum yine **bulunuyor**.
    if (!kareler.containsKey('YAŞLILIKTA BAKIM')) {
      for (final PlayerArchetype arketip in arketipler) {
        if (kareler.containsKey('YAŞLILIKTA BAKIM')) break;
        for (int seed = 1; seed <= tohumSayisi; seed++) {
          if (kareler.containsKey('YAŞLILIKTA BAKIM')) break;
          playBotLife(
            archetype: arketip,
            seed: seed * 101 + arketip.index,
            overrides: const BotOverrides(noElderSupport: true),
            onPreAge: (GameState s) {
              if (kareler.containsKey('YAŞLILIKTA BAKIM')) return;
              if (ElderSupport.needsSupport(s) &&
                  !ElderSupport.decidedThisYear(s)) {
                kareler['YAŞLILIKTA BAKIM'] = (s, seed, arketip);
              }
            },
          );
        }
      }
    }

    final StringBuffer rapor = StringBuffer()
      ..writeln('\n${'=' * 68}')
      ..writeln('ÖZEL DURUM TARAMASI — $taranan hayat oynandı')
      ..writeln('=' * 68);
    for (final Durum d in aranan) {
      final kare = kareler[d.ad];
      rapor.writeln(kare == null
          ? '  ${d.ad}: BULUNAMADI (bu tohumlarda oluşmadı)'
          : '  ${d.ad}: bulundu — ${kare.$3.label}, tohum ${kare.$2}, '
              'yaş ${kare.$1.player.age}');
    }
    // ignore: avoid_print
    print(rapor);

    // 2) Bulunan her kareyi dök.
    for (final Durum d in aranan) {
      final kare = kareler[d.ad];
      if (kare == null) continue;
      final GameState baslangic = kare.$1;
      await ac(tester, baslangic);
      if (!d.ekranTemizlenmesin) {
        await ekraniTemizle(tester);
      } else {
        await tester.pumpAndSettle();
      }
      final GameState s = controller.state!;

      final StringBuffer dokum = StringBuffer()
        ..writeln('\n${'=' * 68}')
        ..writeln('ÖZEL DURUM · ${d.ad}')
        ..writeln('${kare.$3.label} · tohum ${kare.$2} · yaş '
            '${s.player.age} · cüzdan ${s.player.wallet} ₺ · '
            'cezaevi ${s.isImprisoned} · duruşma ${s.hasPendingTrial} · '
            'kriz ${s.hasPendingCrisis} · emekli ${s.career.isRetired}')
        ..writeln('=' * 68);

      // Bekleyen pencere varken geri çıkartması modal bariyerin
      // arkasında kalır; o durumlarda ana ekrana dönmek denenmez.
      //
      // **Açıcısı olan kare ana ekrandan başlar (Paket CV).** Ölçülen
      // hata: `ekranTemizlenmesin` kareleri **önceki karenin
      // ekranında** başlıyordu. Mülakat karesi bu yüzden Aktiviteler
      // ekranında açılıyor, alt sekmeye basmak işe yaramıyor ve açıcı
      // "satır yok" diyordu — oysa satır vardı, ekran yanlıştı. Mülakat
      // bir modal bariyer değil (bir satıra dokunarak açılıyor), bu
      // yüzden ana ekrana dönmek güvenli.
      if ((!d.ekranTemizlenmesin || d.acici != null) &&
          !await anaEkrana(tester)) {
        dokum.writeln('\n!!! ANA EKRANA DÖNÜLEMEDİ — aşağıdaki "Hayat" '
            'bölümü başka bir ekran olabilir.');
      }
      // Kendiliğinden açılmayan pencereyi açan adım (Paket CV).
      if (d.acici != null) {
        dokum.writeln('\n${await d.acici!(tester)}');
      }
      final List<String> hayat = metinler(tester);
      dokum.writeln('\n--- Hayat / açık pencere --- (${hayat.length} metin)');
      for (final String x in hayat) {
        dokum.writeln('   $x');
      }

      // Bekleyen pencere varken sekmeler modal bariyerin arkasında
      // kalır; o durumlarda sekme gezilmez (bu bir ürün hatası değil,
      // bilerek konmuş bir kilit).
      if (!d.ekranTemizlenmesin) {
        for (final (String anahtar, String ad) in kSekmeler) {
          final Finder sekme = find.byKey(Key(anahtar));
          if (sekme.evaluate().isEmpty) {
            dokum.writeln('\n--- $ad --- (SEKME YOK)');
            continue;
          }
          await tester.tap(sekme);
          await tester.pumpAndSettle();
          final List<String> satirlar = metinler(tester);
          dokum.writeln('\n--- $ad --- (${satirlar.length} metin)');
          for (final String x in satirlar) {
            dokum.writeln('   $x');
          }
        }
      }
      // ignore: avoid_print
      print(dokum);

      // Kalıcı denetim: ekranda ham `null` görünmez (Paket BF).
      final List<String> kotu =
          metinler(tester).where((String x) => x.contains('null')).toList();
      expect(kotu, isEmpty,
          reason: '${d.ad} ekranında ham null: $kotu');
    }

    // Tarama boşa çalışmasın: en az bir durum bulunmalı.
    expect(kareler, isNotEmpty,
        reason: '$taranan hayatta aranan beş durumdan hiçbiri oluşmadı; '
            'ya tarama bozuk ya koşullar yanlış yazılmış.');
  });
}

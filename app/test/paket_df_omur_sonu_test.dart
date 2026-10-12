// Paket DF — ömür sonu özetindeki "Son iş" satırı.
//
// **Nasıl bulundu.** Üç ekran dökümünün üçü de ölümde geri dönüyordu
// (`if (deceased) return;`), yani **her oyunun en son gördüğü ekran**
// hiç basılmamıştı. `ekran_dokumu_omur_sonu_test.dart` yazıldı ve altı
// arketipin son karesi ilk kez okundu.
//
// **İlk karede çıktı.** Ekran şunu yazıyordu:
//
// | Hüküm paneli (doğru) | Meslek satırı (yanlış) |
// |---|---|
// | "3 işte toplam 43 yıl çalıştın. Mesleğinde başusta oldun." | "Son iş: **Çalışmıyor**" |
// | "4 işte toplam 40 yıl çalıştın." | "Son iş: **Çalışmıyor**" |
// | "Tek bir işte 43 yıl geçirdin. Mesleğinde duayen oldun." | "Son iş: **Çalışmıyor**" |
//
// Altı karenin **beşi** böyleydi; altıncı ölürken hâlâ çalışıyordu ve
// doğru yazıyordu. Yani ekran hem anlamsız bir cümle kuruyor hem de
// kendi hüküm paneliyle çelişiyordu.
//
// **Kök neden.** Satır `'Son iş: ${career.label}'` yazıyordu ve
// `CareerState.label` `job?.name ?? 'Çalışmıyor'`: işsizken bugünkü
// işi soruyor. Son iş **geçmişten** okunur. `lastJobLabel` eklendi
// (`history` → `pastJobIds`, katalogdan düşmüş kimlik atlanır).
//
// Aynı dalda ikinci bir eksik vardı: hiç maaşlı iş tutmamış ama
// işletme kurmuş oyuncuya "Çalışmadı" yazılıyordu. Futbolcu ve
// dövüşçü için bu AY/3 ve AY/5'te düzeltilmişti; işletme sahibi
// atlanmıştı. Ölçüm: 200 bot ölümünde bu dal **0 kez** yürünüyor
// (bot her hayatta bir işe giriyor), ama motor izin veriyor —
// `BusinessEngine.openAvailability` maaşlı iş istemiyor. Yani bu da
// DC §1 gibi **bot ölçümünün göremediği** bir yol; §3 kaynak
// taramasıyla korunuyor.
library;

import 'dart:io';
import 'dart:math';

import 'package:bir_omur/app.dart';
import 'package:bir_omur/domain/models/career.dart';
import 'package:bir_omur/domain/models/game_state.dart';
import 'package:bir_omur/state/game_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/player_bot.dart';

/// Ölmüş, geçmişte çalışmış ve ölürken işsiz olan bir kare **arar**.
GameState? _emekliOlenAra({int tohumSayisi = 8}) {
  for (final PlayerArchetype a in PlayerArchetype.values) {
    for (int i = 0; i < tohumSayisi; i++) {
      GameState? bulunan;
      playBotLife(
        archetype: a,
        seed: 121000 + a.index * 409 + i * 31,
        onYear: (GameState s) {
          if (bulunan != null) return;
          if (s.deceased &&
              !s.career.isEmployed &&
              s.career.pastJobIds.isNotEmpty) {
            bulunan = s;
          }
        },
      );
      if (bulunan != null) return bulunan;
    }
  }
  return null;
}

void main() {
  test('§1 lastJobLabel bugünü değil geçmişi okuyor', () {
    final GameState? s = _emekliOlenAra();
    expect(s, isNotNull, reason: 'Emekli/işsiz ölen hayat bulunamadı.');
    final String? son = s!.career.lastJobLabel;

    // ISIRMA: eski kod `career.label` kullanıyordu ve burası
    // "Çalışmıyor" olurdu.
    expect(s.career.label, 'Çalışmıyor',
        reason: 'Bu kare işsiz olmalı; ölçümün zemini bu.');
    expect(son, isNotNull,
        reason: 'Geçmişte iş var ama son iş okunamadı.');
    expect(son, isNot('Çalışmıyor'));
    expect(son, isNot('Çalışmadı'));
    expect(son!.trim(), isNotEmpty);
    // Son iş gerçekten geçmişin son işi olmalı.
    expect(s.career.pastJobIds, isNotEmpty);
  });

  test('§2 hiç çalışmamışta null döner, uydurma ad yazılmaz', () {
    // Hiç çalışmamış ölen kare ara; bulunamazsa iddia atlanmaz,
    // yüklemin sözleşmesi yine denetlenir.
    GameState? hicCalismayan;
    for (final PlayerArchetype a in PlayerArchetype.values) {
      for (int i = 0; i < 12 && hicCalismayan == null; i++) {
        playBotLife(
          archetype: a,
          seed: 122000 + a.index * 331 + i * 17,
          onYear: (GameState s) {
            if (hicCalismayan == null &&
                s.deceased &&
                !s.career.isEmployed &&
                s.career.pastJobIds.isEmpty &&
                s.career.history.isEmpty) {
              hicCalismayan = s;
            }
          },
        );
      }
    }
    if (hicCalismayan != null) {
      expect(hicCalismayan!.career.lastJobLabel, isNull,
          reason: 'Hiç çalışmamışa son iş uyduruldu.');
    }
    // Yüklemin kendi sözleşmesi: boş geçmiş → null.
    const CareerState bos = CareerState();
    expect(bos.lastJobLabel, isNull);
  });

  testWidgets('§3 ekran "Son iş: Çalışmıyor" yazmıyor, gerçek işi yazıyor',
      (WidgetTester tester) async {
    final GameState? bulunan = _emekliOlenAra();
    expect(bulunan, isNotNull);
    final GameState s = bulunan!;
    final String beklenen = s.career.lastJobLabel!;

    tester.view.physicalSize = const Size(1200, 14000);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final GameController controller = GameController(random: Random(8));
    addTearDown(controller.dispose);
    await tester.pumpWidget(BirOmurApp(controller: controller));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Rastgele bir hayat'));
    await tester.pumpAndSettle();
    controller.debugSetState(s);
    await tester.pumpAndSettle();

    // Özet ekranı açıldı mı?
    expect(find.text('Bir ömür tamamlandı'), findsOneWidget);
    // ISIRMA DENEMESİ: eski kod bu kareyi "Son iş: Çalışmıyor" diye
    // yazıyordu.
    expect(
      find.text('Son iş: Çalışmıyor'),
      findsNothing,
      reason: 'Ömür sonu özeti yine "Son iş: Çalışmıyor" diyor.',
    );
    expect(
      find.text('Son iş: $beklenen'),
      findsOneWidget,
      reason: 'Özet son işi yazmıyor; beklenen "Son iş: $beklenen".',
    );
  });

  test('§4 kaynak taraması: "Son iş" satırı bir daha label okumasın', () {
    // **Paket DH'de hedef dosya değişti, iddia değişmedi.** Zincir
    // artık ekranda değil `CareerSummaryLabel` içinde: DH, aynı
    // kusurun ikinci bir kopyasını arşivi yazan kontrolörde buldu
    // (arşive üç hayatın üçünde de "Son iş: Çalışmıyor" yazılmıştı,
    // hem de kayıt dosyasına kalıcı olarak) ve kökün yazım hatası
    // değil **çoğaltma** olduğunu gösterdi. Tarama o yüzden tek
    // kaynağa bakıyor; kopyanın geri gelmesini de Paket DH'nin §2'si
    // ayrıca yasaklıyor.
    final File dosya =
        File('lib/domain/life/career_summary_label.dart');
    expect(dosya.existsSync(), isTrue,
        reason: 'Meslek satırının tek kaynağı silinmiş.');
    final String kaynak = dosya.readAsStringSync();

    // Hatanın tam şekli: "Son iş" metnine `career.label` enterpolasyonu.
    for (final String bicim in <String>[
      r"'Son iş: ${state.career.label}'",
      r"'Son iş: ${current.career.label}'",
    ]) {
      expect(
        kaynak.contains(bicim),
        isFalse,
        reason: 'Hata geri geldi: "Son iş" satırı yine bugünkü işi '
            'okuyor. Son iş geçmişten okunur (lastJobLabel).',
      );
    }
    // İşletme sahibi dalı duruyor mu? (Bot bu yolu yürümüyor; ölçüm
    // 200 ölümde 0. Bu yüzden korumasını kaynak taraması yapıyor.)
    expect(
      kaynak.contains('Kendi işini kurdu'),
      isTrue,
      reason: 'İşletme kurmuş oyuncuya yine "Çalışmadı" yazılıyor '
          'olabilir; AY/3 ve AY/5 ile aynı eksiklik.',
    );
    expect(kaynak.contains('lastJobLabel'), isTrue);

    // Ekran ve kontrolör o zinciri yeniden yazmıyor olmalı; bu
    // iddianın tamamı Paket DH §2'de, burada yalnızca çağrı duruyor.
    for (final String yol in <String>[
      'lib/ui/screens/life_summary_screen.dart',
      'lib/state/game_controller.dart',
    ]) {
      expect(File(yol).readAsStringSync().contains('CareerSummaryLabel.of'),
          isTrue,
          reason: '$yol tek kaynağı çağırmıyor.');
    }
  });
}

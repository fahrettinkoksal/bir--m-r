import 'dart:io';

import 'package:bir_omur/domain/interaction/family_interactions.dart';
import 'package:bir_omur/domain/interaction/shared_history.dart';
import 'package:bir_omur/domain/models/game_state.dart';
import 'package:bir_omur/domain/models/person.dart';
import 'package:bir_omur/domain/models/wealth.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/player_bot.dart';

/// **Paket DR — modal karelerin metin kusurları.**
///
/// Bölüm sayfalarının hepsi okunduktan sonra (DM-DQ) bir katman aşağı
/// inildi: `lib/ui/widgets/`. Ölçüm, oyuncuya dönük metnin önemli bir
/// kısmının orada olduğunu gösterdi — `person_detail_sheet.dart` tek
/// başına **65 cümle**, okuduğum hiçbir bölüm sayfasından yoğun — ve o
/// karelerin hiçbiri hiç basılmamıştı: modal bir sayfa sekmede
/// görünmüyor, bölüm dökümü oraya giremiyor.
///
/// Modal dökümü (`ekran_dokumu_modal_test.dart`) altı kare açtı. Kişi
/// kartının **43 yaşındaki** karesi (yaşlı anne, 103 metin) iki metin
/// kusuru gösterdi:
///
/// 1. **"Cemile kişisine Kolye verdin."** — "kişisine" sözcüğü Türkçe
///    ad çekiminden (Cemile'ye) kaçmak için konmuş bir dolgu. Paket
///    DN'in kararı aynen uygulandı: tek çağrı yeri için ad çekimi
///    motoru yazmak yerine cümle ek gerektirmeyecek biçimde kuruldu —
///    "Cemile için Kolye aldın."
/// 2. **'Cemile "şey almayacaktın" dedi'** — tırnak içindeki cümle
///    eksik sözcük sanılıyor. Kastedilen konuşma dilindeki duraksama;
///    noktalama onu belli ediyor ("Şey... almayacaktın"). Sözcükler
///    değişmedi.
///
/// Üçüncü bulgu bir **ölçüm** ve kuyruğa gitti (Q-246): aynı karede
/// anne oyuncunun avucuna "Kimseye söyleme." diyerek **25 ₺**
/// sıkıştırıyor. Oyuncunun kendi çocuğuna verdiği harçlığın varsayılanı
/// 2.400 ₺; aynı jest için 96 kat fark var ve sayılar `prototypeOnly`.
void main() {
  /// Yorum satırları atılmış kaynak (Paket DH dersi: yorum gören tarama
  /// yanlış alarm veriyor).
  String kodu(String yol) => File(yol)
      .readAsLinesSync()
      .where((String l) {
        final String t = l.trimLeft();
        return !t.startsWith('//') && !t.startsWith('///');
      })
      .join('\n');

  test('§1 oyuncuya dönük metinde "kişisine" dolgusu yok', () {
    // Tarama bütün `lib/` üzerinde: aynı dolgu başka bir cümleye de
    // konabilir. Yorumlar atılıyor, çünkü düzeltmenin gerekçesi
    // yorumda bu sözcüğü anıyor.
    final List<String> bulgu = <String>[];
    for (final FileSystemEntity e
        in Directory('lib').listSync(recursive: true)) {
      if (e is! File || !e.path.endsWith('.dart')) continue;
      final String kaynak = kodu(e.path);
      if (kaynak.contains('kişisine')) bulgu.add(e.path);
    }
    expect(
      bulgu,
      isEmpty,
      reason: 'Türkçe ad çekiminden kaçmak için "kişisine" dolgusu '
          'konmuş; cümleyi ek gerektirmeyecek biçimde kur:\n'
          '${bulgu.join("\n")}',
    );
  });

  test('§2 hediye kaydı doğru cümleyi üretiyor', () {
    // **Durum kurulmuyor, aranıyor:** hediye kaydı olan bir kare bot
    // hayatlarından bulunuyor.
    //
    // **Bu testin sınırı ölçüldü:** bulunan karede kayıt "gelen"
    // hediye oluyor ("Şerife sana … verdi"), yani giden dalı her
    // koşuda sınamıyor — mutasyon denemesinde §1 ve §3 düştü, §2
    // geçti. Asıl bekçi §1'in bütün `lib/` üzerindeki taraması;
    // burası cümlenin **biçimini** tutuyor.
    GameState? kare;
    Person? kisi;
    for (final PlayerArchetype a in <PlayerArchetype>[
      PlayerArchetype.family,
      PlayerArchetype.casual,
      PlayerArchetype.social,
    ]) {
      for (int tohum = 0; tohum < 40 && kare == null; tohum++) {
        void bak(GameState s) {
          if (kare != null || s.deceased) return;
          for (final Person p in s.people) {
            final List<SharedMoment> anlar = SharedHistory.of(s, p);
            final bool hediyeVar = anlar.any(
              (SharedMoment m) => m.kind == SharedMomentKind.hediye,
            );
            if (hediyeVar) {
              kare = s;
              kisi = p;
              return;
            }
          }
        }

        playBotLife(
          archetype: a,
          seed: 61000 + tohum,
          onYear: bak,
          onPreAge: bak,
        );
      }
    }
    if (kare == null || kisi == null) {
      // ignore: avoid_print
      print('UYARI: hediye kaydı olan kare BULUNAMADI; §2 sınanmadı.');
      return;
    }

    final List<String> hediyeMetinleri = <String>[
      for (final SharedMoment m in SharedHistory.of(kare!, kisi!))
        if (m.kind == SharedMomentKind.hediye) m.text,
    ];
    // ignore: avoid_print
    print('HEDİYE KAYDI: ${kisi!.firstName} · '
        '${hediyeMetinleri.length} satır');
    for (final String metin in hediyeMetinleri) {
      expect(
        metin.contains('kişisine'),
        isFalse,
        reason: 'Dolgu sözcük geri geldi: "$metin"',
      );
      // İki dalın ikisi de ya "sana … verdi" ya "… için … aldın" olur.
      expect(
        metin.contains(' sana ') || metin.contains(' için '),
        isTrue,
        reason: 'Beklenmeyen hediye cümlesi: "$metin"',
      );
    }
  });

  test('§3 hediye tepkisindeki tırnak eksik sözcük gibi okunmuyor', () {
    final String metinler = kodu('lib/data/interaction_texts.dart');
    expect(
      metinler,
      contains('"Şey... almayacaktın" dedi'),
      reason: 'Duraksama noktalamayla belli olmalı.',
    );
    expect(
      metinler.contains('"şey almayacaktın"'),
      isFalse,
      reason: 'Tırnak içindeki cümle yine eksik sözcük gibi okunuyor.',
    );
  });

  test('§4 ÖLÇÜM: aile harçlık tutarları (Q-246)', () {
    // Bu bir **ölçüm**, bekçi değil: sayılar `prototypeOnly` ve
    // kalibrasyonu Faho'nun kararı. Test yalnızca tabloyu basıyor ve
    // kuyruğun dayandığı oranı sabitliyor; eşik koymuyor.
    final Map<WealthTier, int> tablo =
        FamilyInteractions.prototypeOnlyAllowanceByWealth;
    final List<String> satirlar = <String>[
      for (final MapEntry<WealthTier, int> e in tablo.entries)
        '${e.key.name}: ${e.value} ₺',
    ];
    // ignore: avoid_print
    print('KARŞI TARAFIN VEREBİLDİĞİ (prototypeOnly) · '
        '${satirlar.join(" · ")}');
    // ignore: avoid_print
    print('OYUNCUNUN ÇOCUĞUNA VERDİĞİ varsayılan: '
        '${FamilyInteractions.prototypeOnlyAllowanceDefault} ₺');

    // Oranın kuyruğa yazdığım sayı olduğunu sabitler: ölçüm değişirse
    // Q-246 de güncellenmeli.
    final int yoksul = tablo[WealthTier.yoksul] ?? 0;
    expect(yoksul, 25);
    expect(FamilyInteractions.prototypeOnlyAllowanceDefault, 2400);
  });
}

// Paket CT — dul karesinin okunması: iki gerçek hata.
//
// **Nereden çıktı.** Paket CS dulluğa 20 olay yazdı ama **ekran**
// tarafı hiç okunmadı. `ekran_dokumu_ozel_durum_test.dart` üç turda
// sekiz gerçek hata bulmuştu ve kalıbı hep aynıydı: tek tek metin
// denetleyen testlerin göremediği şeyi, ekranın tamamını basan döküm
// görüyor. Dökümün yedinci turuna **DUL** karesi eklendi (120 bot
// hayatı taranarak bulundu: riskli hayat, tohum 15, yaş 53) ve çıktı
// gözle okununca iki hata çıktı.
//
// ---
//
// ## 1. Vefat etmiş kişinin açık meselesi hiç kapanmıyor
//
// Dul karesinin İlişkiler ekranı şunu yazıyordu:
//
//     Tülay için bakım
//     Tülay artık tek başına idare edemiyor. Bu yükü nasıl
//     karşılayacağına karar vermen gerekiyor.
//     [Bakımı ben üstlenirim] [Ücretli bakıma katkı ver]
//     [Kardeşlerinle konuş] [Üstlenemeyeceğini söyle]
//
// Aynı ekranın iki satır aşağısı: **"Tülay Can · Anne · vefat etti"**.
// Günlük de doğruluyor: "Annen Tülay Can uykusunda, sakin bir şekilde
// vefat etti" — **iki yıl önce**, 51 yaşında. Oyun iki yıldır vefat
// etmiş anne için bakım kararı soruyordu.
//
// **Kök neden.** Ölüm kişiyi `people` listesinden silmiyor; kayıt
// kalıyor ve kişi vefat etmiş işaretleniyor (D-037, doğru kural).
// `FamilyDisputes.pendingCareDispute` ve kardeşleri ise yalnızca
// `personById == null` durumunu kapatıyor — o da ancak oyuncu bir
// cevap verdiğinde bakılıyor. Kişi hiç silinmediği için koşul asla
// tutmuyordu ve mesele sonsuza dek açık kalıyordu.
//
// **Ölçüm (200 bot hayatı, 13.908 yıl karesi, `onPreAge`):**
//
// | ölçülen | sayı |
// |---|---|
// | vefat etmiş kişinin açık meselesi olan kare | **3.251 (%23,4)** |
// | bu duruma düşen hayat | **140 / 200** |
// | en uzun açık kalma | **80 yıl** |
//
// Tür kırılımı: bakım 2.774 · kayın gerginliği 1.455 · miras 360 ·
// kardeş parası 282 · çocuk parası 3.
//
// **Çözüm.** `FamilyIssueStatus.kapandi`'nin tanımı bu durumu zaten
// anlatıyordu — *"Çözülmeden kapandı (kişi vefat etti, mesele
// anlamını yitirdi)"* — ama kimse bağlamamıştı. Yıllık ilerlemede,
// ölümler işlendikten hemen sonra `_closeIssuesOfDeceased` çalışıyor.
// Kayıt **silinmiyor**: durum `kapandi`, kapanma yaşı yazılı, geçmiş
// okunur.
//
// ---
//
// ## 2. Türkçe ekler isme göre seçilmiyor
//
// Aynı dökümün günlüğünde: **"Taner artık Malatya'de."** Doğrusu
// "Malatya'da" — son ünlü kalın.
//
// Deseni depo genelinde taradım (`CLAUDE_ROADMAP` ikinci dersi: geniş
// kullanılan bir metin kalıbını tek tek süitten öğrenmek pahalı) ve
// hata tek yerde değildi: ek, kişi ya da şehir adına **sabit**
// yazılmış **19 yer** vardı. Yani metin Türkçe isimlerin yarısında
// doğru, yarısında yanlış çıkıyordu:
//
//     "Malatya'ye taşındı" · "Malatya'e taşındın" · "Elif'a sor"
//     "Murat'e para vermedin" · "Elif'a kaldı" · "Sinop'da"
//
// **Çözüm.** `trDative`, `trLocative`, `trAblative` (`turkish_text.dart`).
// Üçü de büyük/küçük ünlü uyumuna, ünsüz benzeşmesine (FıSTıKÇı
// ŞaHaP → "Sinop'ta") ve yönelme ekinde kaynaştırma y'sine bakıyor
// ("Malatya'ya"). 19 çağrı yeri bu işlevlere bağlandı.

import 'dart:io';

import 'package:bir_omur/domain/models/family_issue.dart';
import 'package:bir_omur/domain/models/game_state.dart';
import 'package:bir_omur/domain/models/person.dart';
import 'package:bir_omur/text/turkish_text.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/player_bot.dart';

void main() {
  group('§1 vefat etmiş kişinin açık meselesi kalmaz', () {
    test('200 hayatta tek bir kare bile kalmıyor', () {
      const List<PlayerArchetype> ark = <PlayerArchetype>[
        PlayerArchetype.family,
        PlayerArchetype.social,
        PlayerArchetype.career,
        PlayerArchetype.risky,
      ];
      int kare = 0;
      // İki ayrı birim ölçülüyor ve karıştırılmamalı: **kare** (o yılda
      // en az bir ölü-konu meselesi var mı) ve **kare×mesele** (kaç
      // mesele). Düzeltmeden önce ölçülen: 3.251 kare / 4.874
      // kare×mesele.
      int oluAcikKare = 0;
      int oluAcikMesele = 0;
      int kapananMesele = 0;
      int acikMesele = 0;
      final Map<String, int> kacak = <String, int>{};

      for (int i = 0; i < 200; i++) {
        playBotLife(
          archetype: ark[i % ark.length],
          seed: 70000 + i,
          onPreAge: (GameState s) {
            kare++;
            bool buKare = false;
            for (final FamilyIssue m in s.familyIssues) {
              if (m.status == FamilyIssueStatus.kapandi) kapananMesele++;
              if (!m.isOpen) continue;
              acikMesele++;
              final Person? k = s.personById(m.personId);
              if (k == null || k.isAlive) continue;
              oluAcikMesele++;
              buKare = true;
              kacak[m.kind.name] = (kacak[m.kind.name] ?? 0) + 1;
            }
            if (buKare) oluAcikKare++;
          },
        );
      }

      // Ölçümün gerçekten iş gördüğünü kanıtla: mesele hiç açılmıyorsa
      // "sıfır kaçak" boş bir iddia olurdu.
      expect(kare, greaterThan(10000), reason: 'taranan kare: $kare');
      expect(acikMesele, greaterThan(500),
          reason: 'açık mesele karesi: $acikMesele');
      // Düzeltmeden önce ölçülen: 3.251 kare / 4.874 kare×mesele,
      // 140/200 hayat, en uzun 80 yıl. Şimdi ikisi de sıfır olmalı.
      //
      // **Isırma denemesi (ölçüldü).** `_closeIssuesOfDeceased` çağrısı
      // devre dışı bırakıldığında bu iddia kırmızıya düştü: 4.874
      // kare×mesele (bakım 2.774 · kayın gerginliği 1.455 · miras 360 ·
      // kardeş parası 282 · çocuk parası 3).
      expect(oluAcikKare, 0,
          reason: 'vefat etmiş kişinin açık meselesi olan kare: '
              '$oluAcikKare (mesele: $oluAcikMesele) — $kacak');
      expect(oluAcikMesele, 0, reason: 'kaçak mesele: $kacak');
      // Ve kapanan meseleler gerçekten kaydediliyor olmalı (kural
      // çalışıyor, mesele silinmiyor).
      expect(kapananMesele, greaterThan(0),
          reason: 'hiç "kapandı" meselesi görülmedi: kural çalışmıyor '
              'ya da mesele siliniyor olabilir');
    });
  });

  group('§2 Türkçe ekler isme göre seçilir', () {
    test('yönelme eki (-e durumu)', () {
      // Ünlüyle bitenlerde kaynaştırma y'si.
      expect(trDative('Malatya'), "Malatya'ya");
      expect(trDative('Bursa'), "Bursa'ya");
      expect(trDative('Antalya'), "Antalya'ya");
      expect(trDative('Rize'), "Rize'ye");
      expect(trDative('Ordu'), "Ordu'ya");
      expect(trDative('Niğde'), "Niğde'ye");
      // Ünsüzle bitenler.
      expect(trDative('İzmir'), "İzmir'e");
      expect(trDative('Murat'), "Murat'a");
      expect(trDative('Elif'), "Elif'e");
      expect(trDative('Sinop'), "Sinop'a");
      expect(trDative('Uşak'), "Uşak'a");
      expect(trDative('Gönül'), "Gönül'e");
      expect(trDative('Nilgün'), "Nilgün'e");
      expect(trDative('Orhan'), "Orhan'a");
      // Dökümdeki gerçek adlar.
      expect(trDative('Taner'), "Taner'e");
      expect(trDative('Tülay'), "Tülay'a");
    });

    test('bulunma eki (-de durumu) ve ünsüz benzeşmesi', () {
      // Dökümün bastığı hata: "Malatya'de" yanlıştı.
      expect(trLocative('Malatya'), "Malatya'da");
      expect(trLocative('İzmir'), "İzmir'de");
      expect(trLocative('Rize'), "Rize'de");
      // Sert ünsüzle bitende d → t (FıSTıKÇı ŞaHaP).
      expect(trLocative('Sinop'), "Sinop'ta");
      expect(trLocative('Uşak'), "Uşak'ta");
      expect(trLocative('Tokat'), "Tokat'ta");
      expect(trLocative('Bilecik'), "Bilecik'te");
      expect(trLocative('Kırkpınar'), "Kırkpınar'da");
      expect(trLocative('Elif'), "Elif'te");
      expect(trLocative('Gönül'), "Gönül'de");
    });

    test('ayrılma eki (-den durumu)', () {
      expect(trAblative('Malatya'), "Malatya'dan");
      expect(trAblative('İzmir'), "İzmir'den");
      expect(trAblative('Uşak'), "Uşak'tan");
      expect(trAblative('Sinop'), "Sinop'tan");
      expect(trAblative('Murat'), "Murat'tan");
      expect(trAblative('Gönül'), "Gönül'den");
    });

    test('ünlüsüz ve boş girdi çökmez', () {
      expect(trDative(''), '');
      expect(trLocative(''), '');
      expect(trAblative(''), '');
      // Ünlüsü olmayan bir dizge kalın sayılır; çökmez.
      expect(trLocative('K'), "K'ta");
    });

    test('kodda ada sabit ek yazılmış yer kalmadı (kaynak taraması)', () {
      // **Kalıcı bekçi.** Yeni bir `${'$'}{kisi.firstName}\'a` yazılırsa
      // bu test kırmızıya döner. Sabit metinlerdeki ekler
      // ("Kırkpınar'da", "17.00'de", "Mağaza'dan") hedef **değil**;
      // yalnızca bir **değişkenin** hemen ardına yapışmış ek aranıyor,
      // çünkü hata orada: ek, adın son ünlüsüne göre değişmeli.
      //
      // Ölçülen: düzeltmeden önce `lib/` altında **19** yer vardı
      // (friendship_depth 3, family_disputes 5, adult_child_support 4,
      // legal_engine 2, prison_life 1, activity_pages 1,
      // divorce_settlement 1, housing 1, child_school_issue 1).
      final RegExp desen = RegExp(
        r'\$\{?[A-Za-z_][A-Za-z0-9_.()]*\}?' // ${ad} ya da $ad
        r"\\'" // kesme işareti (kaynakta kaçışlı)
        r'(de|da|den|dan|te|ta|ten|tan|ye|ya|e|a)'
        r'(?![A-Za-zçğıöşüÇĞİÖŞÜ])',
      );
      final List<String> bulunan = <String>[];
      for (final File f in Directory('lib')
          .listSync(recursive: true)
          .whereType<File>()
          .where((File f) => f.path.endsWith('.dart'))) {
        final List<String> satirlar = f.readAsLinesSync();
        for (int i = 0; i < satirlar.length; i++) {
          final String satir = satirlar[i];
          // Yorum satırı hedef değil; bu paketin gerekçe yazıları
          // hatalı örnekleri bilerek anıyor.
          if (satir.trimLeft().startsWith('//')) continue;
          if (desen.hasMatch(satir)) {
            bulunan.add('${f.path}:${i + 1}  ${satir.trim()}');
          }
        }
      }
      expect(
        bulunan,
        isEmpty,
        reason: 'Ada sabit ek yazılmış ${bulunan.length} yer var; '
            'trDative/trLocative/trAblative kullanılmalı:\n'
            '${bulunan.join('\n')}',
      );
    });
  });
}

// Paket CH — hangi yaşlarda hiçbir şey olmuyor?
//
// **Neden ölçüldü.** Üç pakettir aynı desen çıkıyor: yazılmış içerik
// bir kapı yüzünden hiç görünmüyor (BZ'de dört olay yanlış kapıdaydı,
// CD'de dar pencereli zincir halkaları, CC'de 65+ için içerik yoktu).
// Bu paketler tek tek olaylara baktı. Buradaki soru daha kaba ve daha
// oyuncuya yakın: **bir yıl hiç olaysız geçiyor mu?**
//
// Araca yaş kırılımı eklendi (`BotLifeResult.eventsByAge`): `seenEvents`
// bir kümedir ve yaşı kaybeder, bu yüzden "hangi yıl boş geçti" sorusu
// daha önce yanıtlanamıyordu. Kayıt zar tüketmez, yalnızca görülen
// olayın kimliğini yaşının altına yazar.
//
// **Ölçüm (400 hayat, bütün arketipler).** Boş yıl **yok**: yaş 1'den
// 77'ye kadar her yaşta hayatların %91-100'ünde en az bir olay çıkıyor.
// Yıl başına olay 1,0 ile 1,8 arasında. Yani "o yıl hiçbir şey olmadı"
// diye bir sorun bulunamadı — bu paketin ana bulgusu bir **olumsuz
// sonuç** ve bekçisi bu durumu sabitliyor.
//
// **İki şey yine de ayrıldı:**
//
// 1. **Yaş 0 yapısı gereği olaysız.** Motor yılın olayını yaş alırken
//    çekiyor ve yeni yaşa yazıyor; doğduğu yıl çekiliş hiç olmuyor.
//    Mahsur kalmış içerik **yok**: havuzlarda `maxAge: 0` olan tek bir
//    olay bile yazılmamış, bebeklik olayları 0-2 / 0-3 / 1-3 gibi
//    pencerelerle 1 yaşından itibaren çıkabiliyor. Oyuncu o yıl doğum
//    günlüğünü okuyor (şehir, ebeveynler, kardeş durumu).
// 2. **Yaş 1-3'te oyun hiçbir eylem sunmuyor.** 120 karede ölçüldü:
//    oyunun sunduğu etkileşim sayısı **0** (yaş 4-5'te 32, yaş 6+'da
//    57-77). Bu D-180'in kademesiyle uyumlu (0-3 "konuşmayan ya da yeni
//    konuşan"). Sonucu şu: ilk üç yıl oyuncunun yapabileceği tek şey
//    "Yaş Al" ve yıl başına tam bir olay görüyor. Bunun yeterli olup
//    olmadığı tasarım sorusu, kuyrukta (Q-226).
//
// **Botun kendi kısıtı da ölçüldü ve burada yazılı:** yaş 4-5'te oyun
// 32 etkileşim sunarken bot yılda 1-2 tanesini kullanıyor; ek olay
// eşiği üç ilerleme adımı (D-125). Yani çocukluğun 1,06'lık yoğunluğu
// bir oyuncunun göreceğinin **alt sınırı**. Bu yüzden aşağıdaki
// iddialar hep **taban**; tavan yok.
library;

import 'package:flutter_test/flutter_test.dart';

import 'support/player_bot.dart';

/// Bir yaş bandının ölçümü.
typedef Bant = ({int yil, int olayliYil, int olay, int farkli});

void main() {
  test('hiçbir yaş bandı karanlıkta kalmıyor', () {
    final Map<int, int> yasayan = <int, int>{};
    final Map<int, int> olayliYil = <int, int>{};
    final Map<int, int> olaySayisi = <int, int>{};
    final Map<int, Set<String>> bantKimlik = <int, Set<String>>{};
    int hayat = 0;
    for (final PlayerArchetype a in PlayerArchetype.values) {
      for (int i = 0; i < 20; i++) {
        final BotLifeResult r = playBotLife(archetype: a, seed: 4000 + i * 7);
        // Takılan hayat ölçümü temsil etmez (bot sözleşmesi).
        if (!r.endedByDeath) continue;
        hayat++;
        for (int yas = 0; yas <= r.deathAge; yas++) {
          yasayan[yas] = (yasayan[yas] ?? 0) + 1;
          final List<String>? olaylar = r.eventsByAge[yas];
          if (olaylar == null || olaylar.isEmpty) continue;
          olayliYil[yas] = (olayliYil[yas] ?? 0) + 1;
          olaySayisi[yas] = (olaySayisi[yas] ?? 0) + olaylar.length;
          bantKimlik.putIfAbsent(yas ~/ 10, () => <String>{}).addAll(olaylar);
        }
      }
    }
    expect(hayat, greaterThanOrEqualTo(150),
        reason: 'ölçüm için yeterli hayat ölümle bitmedi ($hayat)');

    Bant bantOlc(int bant) {
      int yil = 0;
      int olayli = 0;
      int olay = 0;
      for (int yas = bant * 10; yas < bant * 10 + 10; yas++) {
        yil += yasayan[yas] ?? 0;
        olayli += olayliYil[yas] ?? 0;
        olay += olaySayisi[yas] ?? 0;
      }
      return (
        yil: yil,
        olayliYil: olayli,
        olay: olay,
        farkli: (bantKimlik[bant] ?? <String>{}).length,
      );
    }

    for (int bant = 0; bant <= 9; bant++) {
      final Bant b = bantOlc(bant);
      if (b.yil == 0) continue;
      // ignore: avoid_print
      print('OLCUM — bant ${bant * 10}-${bant * 10 + 9}: ${b.yil} yıl, '
          '${b.olayliYil} tanesinde olay '
          '(%${(b.olayliYil / b.yil * 100).round()}), yıl başına '
          '${(b.olay / b.yil).toStringAsFixed(2)}, farklı olay '
          '${b.farkli}');
    }

    // --- 1) Hiçbir yaş boş geçmiyor --------------------------------------
    //
    // Ölçülen en kötü yaş 66 (%96). Eşik %85: tek bir yaşın karanlığa
    // düşmesi (bir havuzun kapısının bozulması) hemen görünür.
    int enKotuYas = -1;
    double enKotuOran = 2;
    for (final int yas in yasayan.keys) {
      if (yas < 1 || yas > 70) continue;
      final int y = yasayan[yas] ?? 0;
      if (y < 20) continue; // örneklemi yetmeyen ileri yaşlar
      final double oran = (olayliYil[yas] ?? 0) / y;
      if (oran < enKotuOran) {
        enKotuOran = oran;
        enKotuYas = yas;
      }
    }
    // ignore: avoid_print
    print('OLCUM — en kötü yaş (1-70): $enKotuYas '
        '(%${(enKotuOran * 100).round()})');
    expect(enKotuOran, greaterThan(0.85),
        reason: '$enKotuYas yaşında hayatların yalnızca '
            '%${(enKotuOran * 100).round()}\'inde olay çıktı; o yaşın '
            'havuzu kapanmış olabilir');

    // --- 2) Yetişkin yılların yoğunluğu ---------------------------------
    //
    // Ölçüm: 10-69 bantlarında yıl başına 1,61-1,76. Taban 1,30; ek olay
    // yolu (D-125) bozulursa ya da havuz daralırsa düşer.
    for (int bant = 1; bant <= 6; bant++) {
      final Bant b = bantOlc(bant);
      if (b.yil < 200) continue;
      expect(b.olay / b.yil, greaterThan(1.30),
          reason: '${bant * 10}-${bant * 10 + 9} bandında yıl başına '
              '${(b.olay / b.yil).toStringAsFixed(2)} olay çıkıyor; '
              'yetişkin yılların ölçülen yoğunluğu 1,6-1,8');
    }

    // --- 3) Çocukluk da boş değil ---------------------------------------
    //
    // Ölçüm: 0-9 bandında yıl başına 1,06 ve yılların %90'ında olay var.
    // Yaş 0 yapısı gereği olaysız olduğu için bandın tabanı 1,00'ın
    // altında: on yılın biri zaten boş. Eşik 0,90.
    final Bant cocukluk = bantOlc(0);
    expect(cocukluk.olay / cocukluk.yil, greaterThan(0.90),
        reason: 'çocukluk bandında yıl başına '
            '${(cocukluk.olay / cocukluk.yil).toStringAsFixed(2)} olay '
            'çıkıyor; ölçülen 1,06');

    // --- 4) Her bant kendi içeriğini gösteriyor -------------------------
    //
    // Ölçüm: 0-9 bandında 113 farklı olay, 10-69 bantlarında 203-270.
    // Bir bandın havuzu topluca kapanırsa (BZ'de dört olay, CD'de zincir
    // halkaları) bu sayı düşer. Tabanlar ölçümün yarısının altında
    // tutuldu: amaç kalibrasyon değil, kapanmayı yakalamak.
    expect(cocukluk.farkli, greaterThan(60),
        reason: 'çocukluk bandında yalnızca ${cocukluk.farkli} farklı '
            'olay görüldü; ölçülen 113');
    for (int bant = 1; bant <= 6; bant++) {
      final Bant b = bantOlc(bant);
      if (b.yil < 200) continue;
      expect(b.farkli, greaterThan(120),
          reason: '${bant * 10}-${bant * 10 + 9} bandında yalnızca '
              '${b.farkli} farklı olay görüldü; ölçülen 203-270');
    }
  });
}

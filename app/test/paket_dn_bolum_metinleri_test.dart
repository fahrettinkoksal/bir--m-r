import 'dart:io';

import 'package:bir_omur/data/life_goal_catalog.dart';
import 'package:bir_omur/text/turkish_text.dart';
import 'package:flutter_test/flutter_test.dart';

/// **Paket DN — kalan bölüm sayfalarının metin kusurları.**
///
/// Paket DM sekiz sayfayı açıp üç kusur bulmuştu (oran: sayfa başına
/// 0,38). Kalan sayfaların "başka testle okunuyor" kaydı **başlık
/// düzeyindeydi**: o testler anahtar ve tek tek metin denetliyor,
/// kareyi gözle okumuyor. Döküm on sayfa daha açtı ve üç kusur daha
/// çıktı:
///
/// 1. **Finger** — "Beğenilerinin yaklaşık %46'i karşılık buluyor."
///    Yüzdeye gelen iyelik eki sabit yazılmıştı. Türkçede bu ek sayının
///    okunuşuna bağlıdır: %46'**sı**, %30'**u**, %20'**si**, %3'**ü**.
///    Yani ek 46'da da, 30'da da, 20'de de yanlıştı. Tek çağrı yeri
///    olduğu için sayı eki motoru yazmak yerine cümle eki
///    gerektirmeyecek biçimde kuruldu ("%46 kadarı").
/// 2. **Hayat Hedefleri** — "Sosyal medyada toplam **100000**
///    takipçiye ulaş." Ayraç kuralı (Paket BE) para dışındaki sayılar
///    için de geçerli.
/// 3. **Milli Piyango** — ikramiye oranları "1/**500000**" diye tek
///    blok yazılıyordu.
///
/// 2 ve 3, Paket DM'de sıkıştırdığım para taramasının **göremediği**
/// türdendi: o tarama yalnızca `₺` işaretinin yanındaki ham sayıyı
/// arıyor. Kalıcı bekçi bu yüzden kaynak değil **çizilmiş metin**
/// üzerinde çalışıyor (`ekran_dokumu_bolumler_test.dart`): döküm 18
/// sayfanın metnini zaten basıyor, aynı metinde beş haneden uzun sayı
/// aranıyor.
void main() {
  /// Yorum satırları atılmış kaynak (Paket DH dersi).
  String kodu(String yol) => File(yol)
      .readAsLinesSync()
      .where((String l) {
        final String t = l.trimLeft();
        return !t.startsWith('//') && !t.startsWith('///');
      })
      .join('\n');

  test('§1 yüzdeye sabit iyelik eki getirilmiyor', () {
    // Desen: `%${...}` hemen ardından kesme işareti ve sesli ek.
    // Böyle bir satır sayıya **sabit** ek getiriyor demektir ve
    // Türkçede sayının okunuşu değiştikçe yanlışa düşer.
    final RegExp desen = RegExp(r"%\$\{[^}]*\}\\?'[aeıioöuü]");
    final List<String> bulgu = <String>[];
    for (final FileSystemEntity e
        in Directory('lib').listSync(recursive: true)) {
      if (e is! File || !e.path.endsWith('.dart')) continue;
      final List<String> satirlar = e.readAsLinesSync();
      for (int i = 0; i < satirlar.length; i++) {
        final String satir = satirlar[i];
        if (satir.trimLeft().startsWith('//')) continue;
        if (desen.hasMatch(satir)) {
          bulgu.add('${e.path}:${i + 1} → ${satir.trim()}');
        }
      }
    }
    expect(
      bulgu,
      isEmpty,
      reason: 'Yüzdeye sabit ek getirilmiş; sayının okunuşu değişince '
          'yanlış olur (%46\'sı, %30\'u, %20\'si). Cümleyi ek '
          'gerektirmeyecek biçimde kur:\n${bulgu.join("\n")}',
    );
  });

  test('§2 takipçi hedefi ayraçlı yazılıyor', () {
    final LifeGoal hedef = kLifeGoals.firstWhere(
      (LifeGoal g) => g.id == 'kitlen_olsun',
      orElse: () => kLifeGoals.firstWhere(
        (LifeGoal g) => g.description.contains('takipçiye'),
      ),
    );
    expect(hedef.description, contains(trNumber(kGoalFollowers)));
    expect(
      hedef.description.contains('$kGoalFollowers takipçi'),
      isFalse,
      reason: 'Hedef metni sayıyı ham basıyor: "${hedef.description}"',
    );
  });

  test('§3 piyango oranı ayraçlı yazılıyor', () {
    final String ekran = kodu('lib/ui/screens/sections/lottery_page.dart');
    expect(ekran, contains(r"'1/${trNumber(p.oneIn)}'"));
    expect(
      ekran.contains(r"'1/${p.oneIn}'"),
      isFalse,
      reason: 'Oran yine ham basılıyor.',
    );
  });

  test('§4 trNumber dört haneden itibaren ayraç koyar', () {
    // §2 ve §3'ün dayandığı kural: biçimleyici gerçekten ayraç
    // koyuyor. Bu, kuralın kendisini sabitler.
    expect(trNumber(100000), '100.000');
    expect(trNumber(500000), '500.000');
    expect(trNumber(1000), '1.000');
    expect(trNumber(999), '999');
  });

  test('§5 hedef kataloğunun hiçbir metni ayraçsız uzun sayı taşımıyor',
      () {
    // Katalog genelinde aynı kural: 21 hedefin açıklamasında beş
    // haneden uzun ham sayı olmamalı. Tek yeri düzeltip kataloğun
    // kalanını taramamak, Paket DM'de para biçiminde yaptığım hatanın
    // aynısı olurdu (bir yeri gözle bulup ötekini kaçırmak).
    final RegExp uzunSayi = RegExp(r'\d{5,}');
    final List<String> bulgu = <String>[
      for (final LifeGoal g in kLifeGoals)
        if (uzunSayi.hasMatch(g.description.replaceAll('.', '')) &&
            !g.description.contains('.'))
          '${g.id}: ${g.description}',
    ];
    expect(bulgu, isEmpty, reason: bulgu.join('\n'));
  });
}

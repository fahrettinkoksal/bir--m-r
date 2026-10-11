// Paket BS/0 — arkadaşlık hunisi: ölçüm ve taban bekçisi.
//
// **Neden var.** Paket BP ve BQ'nun 400'er hayatlık ölçümlerinde hayat
// başına ortalama arkadaş 0,70 ve yakın arkadaş 0,04 çıktı. Soru şuydu:
// oyunun kapısı mı kapalı, yoksa ölçüm botu o yolu yürümüyor mu?
// Huni ölçüldü — tanışıklık 80/80 hayatta vardı, teklif eşiği geçildiği
// yıllarda %100 kabul ediliyordu; eksik olan botun kendi davranışıydı:
// yılda bir etkileşim hakkını on kişilik sınıfta **rastgele** birine
// harcıyor, bağ her yıl sönüyordu. Bot birine yoğunlaşmaya çevrildi
// (`test/support/player_bot.dart`), oyun sayıları değişmedi.
//
// **Bu dosya ne bekliyor.** Ölçülen değerler değil, onların çok altında
// bir taban. Amaç: arkadaşlık yolu bir gün yeniden kapanırsa (oyun
// tarafında eşik/sönümleme değişir ya da bot o yolu bırakırsa) süit
// bunu sessizce geçmesin. Tabanlar ölçümün yarısı civarında bilerek
// seçildi; buradaki sayılar denge hedefi değil **bekçi**.
// ignore_for_file: avoid_print
library;

import 'package:bir_omur/domain/models/game_state.dart';
import 'package:bir_omur/domain/models/person.dart';
import 'package:bir_omur/domain/models/relation.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/player_bot.dart';

void main() {
  test('ÖLÇÜM: 80 hayat — arkadaşlık hunisi tabanı', () {
    const List<PlayerArchetype> tipler = <PlayerArchetype>[
      PlayerArchetype.casual,
      PlayerArchetype.social,
      PlayerArchetype.career,
      PlayerArchetype.family,
    ];
    int hicArkadasOlan = 0;
    int tanisiklikGoren = 0;
    int uygunYilOlan = 0;
    int denemeYapan = 0;
    int kabulGoren = 0;
    final List<int> enIyiBag = <int>[];
    final List<int> sonArkadas = <int>[];
    final Map<String, int> engeller = <String, int>{};
    const int kHayat = 80;

    for (int i = 0; i < kHayat; i++) {
      bool arkadasOldu = false;
      final BotLifeResult r = playBotLife(
        archetype: tipler[i % tipler.length],
        seed: 3100 + i * 17,
        onYear: (GameState s) {
          if (s.people.any((Person p) =>
              p.isAlive && p.relation == RelationType.arkadas)) {
            arkadasOldu = true;
          }
        },
      );
      if (arkadasOldu) hicArkadasOlan++;
      if (r.diag.sawAcquaintance) tanisiklikGoren++;
      if (r.diag.closeFriendEligibleYears > 0) uygunYilOlan++;
      if (r.diag.closeFriendAttempts > 0) denemeYapan++;
      if (r.diag.closeFriendAccepted > 0) kabulGoren++;
      enIyiBag.add(r.diag.bestAcquaintanceBond);
      sonArkadas.add(r.friendCount);
      if (r.diag.closeFriendBlockReason.isNotEmpty) {
        engeller.update(r.diag.closeFriendBlockReason, (int v) => v + 1,
            ifAbsent: () => 1);
      }
    }
    enIyiBag.sort();
    double ort(List<int> x) =>
        x.isEmpty ? 0 : x.reduce((int a, int b) => a + b) / x.length;
    final int medyanBag = enIyiBag[enIyiBag.length ~/ 2];
    final double ortArkadas = ort(sonArkadas);

    print('''
BS HUNİ ($kHayat hayat)
hiç arkadaşı olan hayat      : $hicArkadasOlan
tanışıklık (sınıf/iş) gören  : $tanisiklikGoren
teklif uygun yılı olan       : $uygunYilOlan
teklif deneyen               : $denemeYapan
teklifi kabul edilen         : $kabulGoren
en iyi tanışıklık bağı (ort) : ${ort(enIyiBag).toStringAsFixed(1)} · medyan $medyanBag
ölümde arkadaş sayısı (ort)  : ${ortArkadas.toStringAsFixed(2)}
engel gerekçeleri            : $engeller''');

    // Ölçülen: 80/80. Taban: hayatların onda dokuzu okula/işe gidip
    // birileriyle tanışır. Altına düşerse tanışıklık üretimi bozulmuş.
    expect(tanisiklikGoren, greaterThanOrEqualTo(72),
        reason: 'Tanışıklık gören hayat $tanisiklikGoren/$kHayat: sınıf '
            've iş arkadaşı üretimi kapanmış olabilir.');
    // Ölçülen: 61/80. Taban: üçte bir.
    expect(uygunYilOlan, greaterThanOrEqualTo(27),
        reason: 'Yakın arkadaş teklifinin uygun olduğu yılı olan hayat '
            '$uygunYilOlan/$kHayat: bağ eşiğe hiç ulaşamıyor.');
    // Ölçülen: 60/80. Taban: dörtte bir.
    expect(kabulGoren, greaterThanOrEqualTo(20),
        reason: 'Teklifi kabul edilen hayat $kabulGoren/$kHayat: '
            'arkadaşlık yolu fiilen kapanmış.');
    // Ölçülen: 78/80.
    expect(hicArkadasOlan, greaterThanOrEqualTo(40),
        reason: 'Hayatında bir kez bile arkadaşı olan $hicArkadasOlan/'
            '$kHayat: bir hayat simülasyonunda arkadaşsızlık kural '
            'olamaz.');
    // Ölçülen: medyan 60 (eşik 55).
    expect(medyanBag, greaterThanOrEqualTo(45),
        reason: 'En iyi tanışıklık bağının medyanı $medyanBag: bağ '
            'birikmiyor (sönümleme ya da etkileşim etkisi değişmiş).');
    // Ölçülen: 1,48.
    expect(ortArkadas, greaterThanOrEqualTo(0.6),
        reason: 'Ölümde ortalama arkadaş sayısı '
            '${ortArkadas.toStringAsFixed(2)}: arkadaşlıklar hayatta '
            'kalmıyor.');
  });
}

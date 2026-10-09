// Paket BK — çocuk sahibi olmanın **oyuncu yolundan** ölçümü.
//
// Paket BJ şunu yazılı bıraktı: bot `GameController.haveChild()`
// çağırıyor, oyuncu ise o düğmeye hiç ulaşamıyor; oyuncunun tek yolu
// eş/sevgiliyle korunmadan yakınlaşmak → gebelik → ertesi yıl doğum.
// Yani bütün aile ölçümleri oyuncunun **kullanamadığı** bir kapıdan
// geçiyordu (Q-201). BK/2 o kapıyı kapatıyor; bu dosya değişimin
// **önce/sonra** sayısını üretir.
//
// Dosya **rapor** yazar. Eşikler yalnızca bozulmayı yakalar: aile odaklı
// bir dünyada çocuk hiç olmaması ya da herkesin çocuk sahibi olması
// ikisi de hatadır. Oranların kalibrasyonu Faho'nun kararı.
// ignore_for_file: avoid_print
library;

import 'package:bir_omur/domain/models/game_state.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/player_bot.dart';

/// prototypeOnly: ölçülen hayat sayısı (arketip başına).
const int kHayatBasina = 100;

/// Ölçülen arketipler: aile odaklı uç, ortalama ve kariyer ucu.
const List<PlayerArchetype> kArketipler = <PlayerArchetype>[
  PlayerArchetype.family,
  PlayerArchetype.casual,
  PlayerArchetype.career,
];

String _yuzde(int sayi, int toplam) =>
    toplam == 0 ? '-' : '%${(sayi * 100 / toplam).toStringAsFixed(1)}';

double _ortalama(List<int> liste) => liste.isEmpty
    ? 0
    : liste.reduce((int a, int b) => a + b) / liste.length;

int _medyan(List<int> liste) {
  if (liste.isEmpty) return 0;
  final List<int> s = List<int>.of(liste)..sort();
  return s[s.length ~/ 2];
}

/// Tek arketipin ölçümü.
({
  int hayat,
  int esOlan,
  int cocukluHayat,
  int gebelikGoren,
  int kisirOyuncu,
  int kisirAmaCocuklu,
  int tupBebekDeneyen,
  List<int> cocukSayilari,
  List<int> ilkCocukYaslari,
  int ikizGoren,
}) _olc(PlayerArchetype arketip) {
  int esOlan = 0;
  int cocuklu = 0;
  int gebelikGoren = 0;
  int kisir = 0;
  int kisirAmaCocuklu = 0;
  int tupBebek = 0;
  int ikiz = 0;
  final List<int> cocukSayilari = <int>[];
  final List<int> ilkCocukYaslari = <int>[];

  for (int i = 0; i < kHayatBasina; i++) {
    final int seed = 1000 + i * 7 + arketip.index * 101;
    bool gebelik = false;
    bool kisirMi = false;
    int? ilkCocukYasi;
    int enFazlaAyniYil = 0;
    // Tüp bebek: kısır çiftin tek yolu. Denemeden önce belli sayıda
    // başarısız deneme gerekiyor; o yüzden bot bu kapıya ancak gebelik
    // yolunu yürüyorsa ulaşabilir.
    bool tupBebekDenedi = false;

    final BotLifeResult sonuc = playBotLife(
      archetype: arketip,
      seed: seed,
      // Gebelik yıl içinde var olur ve yaş alırken kapanır: `onYear`
      // ile taranan hayatlarda hiç görünmez (Paket BJ'nin dersi).
      onPreAge: (GameState s) {
        if (s.isExpecting) gebelik = true;
        if (s.player.infertile) kisirMi = true;
        if (s.ivfAttempts > 0) tupBebekDenedi = true;
        if (ilkCocukYasi == null && s.children.isNotEmpty) {
          ilkCocukYasi = s.player.age;
        }
        final int sifirYasli =
            s.children.where((dynamic c) => c.age == 0).length;
        if (sifirYasli > enFazlaAyniYil) enFazlaAyniYil = sifirYasli;
      },
    );

    if (sonuc.everPartner || sonuc.married) esOlan++;
    if (gebelik) gebelikGoren++;
    if (kisirMi) {
      kisir++;
      // Kısırlık gerçekten geçerli mi? `haveChild()` bu bayrağı hiç
      // okumuyor; gebelik yolu ise kısırda sıfır ihtimal veriyor.
      if (sonuc.childCount > 0) kisirAmaCocuklu++;
    }
    if (enFazlaAyniYil >= 2) ikiz++;
    if (tupBebekDenedi) tupBebek++;
    cocukSayilari.add(sonuc.childCount);
    if (sonuc.childCount > 0) {
      cocuklu++;
      if (ilkCocukYasi != null) ilkCocukYaslari.add(ilkCocukYasi!);
    }
  }

  return (
    hayat: kHayatBasina,
    esOlan: esOlan,
    cocukluHayat: cocuklu,
    gebelikGoren: gebelikGoren,
    kisirOyuncu: kisir,
    kisirAmaCocuklu: kisirAmaCocuklu,
    tupBebekDeneyen: tupBebek,
    cocukSayilari: cocukSayilari,
    ilkCocukYaslari: ilkCocukYaslari,
    ikizGoren: ikiz,
  );
}

void main() {
  test(
    'ÖLÇÜM: ${kArketipler.length} × $kHayatBasina hayat — çocuk yolu',
    () {
      int toplamCocuklu = 0;
      int toplamGebelik = 0;
      int toplamHayat = 0;

      print('');
      print('=' * 70);
      print('PAKET BK — COCUK YOLU OLCUMU (${kArketipler.length} x '
          '$kHayatBasina hayat)');
      print('=' * 70);

      for (final PlayerArchetype a in kArketipler) {
        final ({
          int hayat,
          int esOlan,
          int cocukluHayat,
          int gebelikGoren,
          int kisirOyuncu,
          int kisirAmaCocuklu,
          int tupBebekDeneyen,
          List<int> cocukSayilari,
          List<int> ilkCocukYaslari,
          int ikizGoren,
        }) r = _olc(a);

        toplamCocuklu += r.cocukluHayat;
        toplamGebelik += r.gebelikGoren;
        toplamHayat += r.hayat;

        print('');
        print('--- ${a.name} ---');
        print('Es/sevgili olan      ${r.esOlan}  '
            '${_yuzde(r.esOlan, r.hayat)}');
        print('Cocuklu hayat        ${r.cocukluHayat}  '
            '${_yuzde(r.cocukluHayat, r.hayat)}');
        print('Gebelik goren        ${r.gebelikGoren}  '
            '${_yuzde(r.gebelikGoren, r.hayat)}');
        print('Kisir oyuncu         ${r.kisirOyuncu}  '
            '${_yuzde(r.kisirOyuncu, r.hayat)}');
        print('Kisir ama cocuklu    ${r.kisirAmaCocuklu}  '
            '${_yuzde(r.kisirAmaCocuklu, r.hayat)}');
        print('Tup bebek deneyen   ${r.tupBebekDeneyen}  '
            '${_yuzde(r.tupBebekDeneyen, r.hayat)}');
        print('Ayni yil iki bebek   ${r.ikizGoren}  '
            '${_yuzde(r.ikizGoren, r.hayat)}');
        print('Cocuk sayisi ort.    '
            '${_ortalama(r.cocukSayilari).toStringAsFixed(2)}  '
            '(medyan ${_medyan(r.cocukSayilari)}, '
            'en fazla ${r.cocukSayilari.reduce((int x, int y) => x > y ? x : y)})');
        print('Ilk cocuk yasi       medyan '
            '${_medyan(r.ilkCocukYaslari)}  '
            '(ort. ${_ortalama(r.ilkCocukYaslari).toStringAsFixed(1)})');
      }

      print('');
      print('TOPLAM  cocuklu ${_yuzde(toplamCocuklu, toplamHayat)}  ·  '
          'gebelik goren ${_yuzde(toplamGebelik, toplamHayat)}');
      print('=' * 70);

      // Bozulma eşikleri: oranı güzelleştirmek için değil, sistemin
      // erişilebilir olduğunu ve açık saçmalık olmadığını görmek için.
      expect(toplamCocuklu, greaterThan(0),
          reason: 'Hiç çocuk olmayan bir dünya hatadır');
      expect(toplamCocuklu, lessThan(toplamHayat),
          reason: 'Herkesin çocuğu olması hatadır');
    },
    timeout: const Timeout(Duration(minutes: 30)),
  );
}

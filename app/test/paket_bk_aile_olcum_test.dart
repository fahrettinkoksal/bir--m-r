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
import 'package:bir_omur/domain/models/interaction.dart';
import 'package:bir_omur/domain/models/person.dart';
import 'package:bir_omur/domain/models/person_development.dart';
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
  Map<String, int> cocukEylemi,
  List<int> cocukZekalari,
  List<int> cocukYakinliklari,
  List<int> cocukBirikimleri,
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
  // Paket BK/3: çocuğa özel eylemler gerçekten kullanılıyor mu?
  // Kullanılmayan bir sistem ölçülmemiş sistemdir (Q-201'in dersi).
  final Map<String, int> cocukEylemi = <String, int>{
    for (final InteractionKind k in InteractionKind.values)
      if (k.childOnly) k.name: 0,
    'akilVer': 0,
  };
  final List<int> cocukZekalari = <int>[];
  final List<int> cocukYakinliklari = <int>[];
  final List<int> cocukBirikimleri = <int>[];
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
    final Set<String> buHayattaEylem = <String>{};
    final Map<String, int> sonZeka = <String, int>{};
    final Map<String, int> sonBag = <String, int>{};
    final Map<String, int> sonBirikim = <String, int>{};

    final BotLifeResult sonuc = playBotLife(
      archetype: arketip,
      seed: seed,
      // Gebelik yıl içinde var olur ve yaş alırken kapanır: `onYear`
      // ile taranan hayatlarda hiç görünmez (Paket BJ'nin dersi).
      onPreAge: (GameState s) {
        if (s.isExpecting) gebelik = true;
        if (s.player.infertile) kisirMi = true;
        if (s.ivfAttempts > 0) tupBebekDenedi = true;
        // Hangi çocuk eylemi kullanıldı? Anahtar "<kişi>|<tür>".
        for (final String anahtar in s.interactionCounts.keys) {
          final String tur = anahtar.split('|').last;
          if (cocukEylemi.containsKey(tur)) buHayattaEylem.add(tur);
        }
        if (s.lastInteractionAge.keys
            .any((String k) => k.startsWith('cocuk-tavsiye:'))) {
          buHayattaEylem.add('akilVer');
        }
        // Çocuğun kendi kaydı: en son görülen değerler yazılır.
        for (final Person cocuk in s.children) {
          final PersonDevelopment? dev = cocuk.development;
          if (dev == null) continue;
          sonZeka[cocuk.id] = dev.stats.intelligence;
          sonBag[cocuk.id] = cocuk.bond;
          // Birikim **18 yaşında** okunur: harçlığın ölçüsü bu.
          // Sonraki yıllarda çocuğun kendi maaşı giriyor ve harçlığın
          // payı görünmez oluyordu (ilk ölçümde medyan 8,75M çıktı —
          // o sayı yetişkin çocuğun kariyeriydi, harçlık değil).
          if (cocuk.age == 18) sonBirikim[cocuk.id] = dev.money;
        }
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
    for (final String tur in buHayattaEylem) {
      cocukEylemi[tur] = (cocukEylemi[tur] ?? 0) + 1;
    }
    cocukZekalari.addAll(sonZeka.values);
    cocukYakinliklari.addAll(sonBag.values);
    cocukBirikimleri.addAll(sonBirikim.values);
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
    cocukEylemi: cocukEylemi,
    cocukZekalari: cocukZekalari,
    cocukYakinliklari: cocukYakinliklari,
    cocukBirikimleri: cocukBirikimleri,
    cocukSayilari: cocukSayilari,
    ilkCocukYaslari: ilkCocukYaslari,
    ikizGoren: ikiz,
  );
}

/// prototypeOnly: BK/6'nın tek arketipli büyük ölçümü.
const int kAileHayati = 500;

void main() {
  test(
    'ÖLÇÜM: $kAileHayati aile hayatı — BK sonrası ebeveynlik tablosu',
    () {
      int esOlan = 0;
      int cocuklu = 0;
      int gebelikGoren = 0;
      int ikiz = 0;
      int tupBebek = 0;
      final List<int> cocukSayilari = <int>[];
      final List<int> cocukZekalari = <int>[];
      final List<int> yakinliklar = <int>[];
      final Map<String, int> eylem = <String, int>{
        for (final InteractionKind k in InteractionKind.values)
          if (k.childOnly) k.name: 0,
        'akilVer': 0,
      };
      int enAzBirEylem = 0;
      int kuralliHayat = 0;

      for (int i = 0; i < kAileHayati; i++) {
        bool gebelik = false;
        bool ikizGordu = false;
        bool tup = false;
        bool kurall = false;
        final Set<String> eylemler = <String>{};
        final Map<String, int> zeka = <String, int>{};
        final Map<String, int> bag = <String, int>{};

        final BotLifeResult sonuc = playBotLife(
          archetype: PlayerArchetype.family,
          seed: 5000 + i * 13,
          onPreAge: (GameState s) {
            if (s.isExpecting) gebelik = true;
            if (s.ivfAttempts > 0) tup = true;
            if (s.children.where((Person c) => c.age == 0).length >= 2) {
              ikizGordu = true;
            }
            for (final String anahtar in s.interactionCounts.keys) {
              final String tur = anahtar.split('|').last;
              if (eylem.containsKey(tur)) eylemler.add(tur);
            }
            for (final String anahtar in s.lastInteractionAge.keys) {
              if (anahtar.startsWith('cocuk-tavsiye:')) {
                eylemler.add('akilVer');
              }
              if (anahtar.startsWith('cocuk-kural:')) kurall = true;
            }
            for (final Person c in s.children) {
              final PersonDevelopment? dev = c.development;
              if (dev == null) continue;
              zeka[c.id] = dev.stats.intelligence;
              bag[c.id] = c.bond;
            }
          },
        );

        if (sonuc.everPartner || sonuc.married) esOlan++;
        if (gebelik) gebelikGoren++;
        if (ikizGordu) ikiz++;
        if (tup) tupBebek++;
        if (kurall) kuralliHayat++;
        cocukSayilari.add(sonuc.childCount);
        if (sonuc.childCount > 0) cocuklu++;
        if (eylemler.isNotEmpty) enAzBirEylem++;
        for (final String t in eylemler) {
          eylem[t] = (eylem[t] ?? 0) + 1;
        }
        cocukZekalari.addAll(zeka.values);
        yakinliklar.addAll(bag.values);
      }

      print('');
      print('=' * 70);
      print('PAKET BK/6 — $kAileHayati AILE HAYATI');
      print('=' * 70);
      print('Es/sevgili olan       $esOlan  ${_yuzde(esOlan, kAileHayati)}');
      print('Cocuklu hayat         $cocuklu  '
          '${_yuzde(cocuklu, kAileHayati)}');
      print('Gebelik goren         $gebelikGoren  '
          '${_yuzde(gebelikGoren, kAileHayati)}');
      print('Ikiz goren            $ikiz  ${_yuzde(ikiz, kAileHayati)}');
      print('Tup bebek deneyen     $tupBebek  '
          '${_yuzde(tupBebek, kAileHayati)}');
      print('Cocuk sayisi ort.     '
          '${_ortalama(cocukSayilari).toStringAsFixed(2)}  '
          '(medyan ${_medyan(cocukSayilari)})');
      print('');
      print('EBEVEYNLIK (BK/3-BK/5)');
      print('En az bir cocuk eylemi $enAzBirEylem  '
          '${_yuzde(enAzBirEylem, kAileHayati)}');
      for (final MapEntry<String, int> e in eylem.entries) {
        print('  ${e.key.padRight(14)} ${e.value}  '
            '${_yuzde(e.value, kAileHayati)}');
      }
      print('Evde kural konulan    $kuralliHayat  '
          '${_yuzde(kuralliHayat, kAileHayati)}');
      print('Cocuk zekasi medyan   ${_medyan(cocukZekalari)}  '
          '(n=${cocukZekalari.length})');
      print('Cocukla yakinlik medyan ${_medyan(yakinliklar)}');
      print('=' * 70);

      // Bozulma eşikleri: sistem erişilebilir mi, açık saçmalık var mı.
      expect(gebelikGoren, greaterThan(0),
          reason: 'Gebelik yolu erişilemez hâle gelmiş');
      expect(cocuklu, greaterThan(0));
      expect(cocuklu, lessThan(kAileHayati));
      expect(enAzBirEylem, greaterThan(0),
          reason: 'Çocuğa özel eylemler erişilemez hâle gelmiş');
      expect(_medyan(cocukZekalari), lessThan(100),
          reason: 'Çocuk statları tavana yapışmış');
    },
    timeout: const Timeout(Duration(minutes: 30)),
  );

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
          Map<String, int> cocukEylemi,
          List<int> cocukZekalari,
          List<int> cocukYakinliklari,
          List<int> cocukBirikimleri,
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
        print('--- cocuga ozel eylemler (BK/3) ---');
        for (final MapEntry<String, int> e in r.cocukEylemi.entries) {
          print('  ${e.key.padRight(18)} ${e.value}  '
              '${_yuzde(e.value, r.hayat)}');
        }
        print('  cocuk zekasi medyan ${_medyan(r.cocukZekalari)}  '
            '(n=${r.cocukZekalari.length})');
        print('  cocukla yakinlik medyan '
            '${_medyan(r.cocukYakinliklari)}  (tavan 100)');
        // Harçlığın ölçüsü **oranla** okunur: bot yılda bir-iki
        // kişiyle ilgileniyor ve türü rastgele seçiyor, bu yüzden
        // çocukların çoğuna hiç harçlık gitmiyor. Medyan 0 çıkması
        // harçlığın işlemediği anlamına gelmez — birikimi olan
        // çocukların payı ve tutarı burada.
        final List<int> birikenler = r.cocukBirikimleri
            .where((int m) => m > 0)
            .toList(growable: false);
        print('  18 yasinda birikimi olan ${birikenler.length}/'
            '${r.cocukBirikimleri.length}  '
            '${_yuzde(birikenler.length, r.cocukBirikimleri.length)}  '
            '(medyan ${_medyan(birikenler)})');
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

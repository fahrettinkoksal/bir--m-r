// Paket AD/4 — borç yaşam döngüsü (§8-§11, §24, §26, §27).
//
// **Bu dosya bir bug düzeltmesinin kanıtı.** Düzeltmeden önce ödenmeyen
// kredi ölümsüzdü: borç her yıl faiziyle büyüyor, `remainingPayments` hiç
// azalmıyor, hiçbir tahsil/yapılandırma/kapanış yolu yok. Ölçülen hâli
// (₺200.000 ihtiyaç kredisi, cüzdan sıfır, 60 yıl):
//
//   yıl 1      343.092        yıl 20   9.741.693.444
//   yıl 5    2.971.196        yıl 40   474.502.763.809.644
//   yıl 10  44.139.999        yıl 60   9.223.372.036.854.775.807  <-- int tavanı
//
// Yani sadece çirkin bir kuyruk değil, **tamsayı taşması**. Aşağıdaki
// bekçiler bunun geri gelmemesini sağlıyor.
// ignore_for_file: avoid_print
library;

import 'dart:math';

import 'package:bir_omur/data/save/game_state_codec.dart';
import 'package:bir_omur/domain/economy/banking.dart';
import 'package:bir_omur/domain/economy/net_worth.dart';
import 'package:bir_omur/domain/generation/life_generator.dart';
import 'package:bir_omur/domain/models/game_state.dart';
import 'package:bir_omur/domain/models/loan.dart';
import 'package:bir_omur/domain/models/owned_item.dart';
import 'package:flutter_test/flutter_test.dart';

GameState _borclu({
  required int tohum,
  int wallet = 0,
  int principal = 200000,
  int annualPayment = 90000,
  Bank bank = Bank.bankavrupa,
  LoanPurpose purpose = LoanPurpose.ihtiyac,
}) {
  final GameState s =
      LifeGenerator.seeded(tohum).generate(mode: StartMode.tamamenRastgele);
  return s.copyWith(
    player: s.player.copyWith(wallet: wallet, age: 30),
    loans: <Loan>[
      Loan(
        id: 'L$tohum',
        bank: bank,
        purpose: purpose,
        principal: principal,
        annualPayment: annualPayment,
        termYears: 5,
        remainingPayments: 5,
        outstanding: principal,
        originalDebt: principal,
        takenAtAge: 25,
      ),
    ],
  );
}

/// Borçluya gerçekten tahsil edilebilir mal verir.
///
/// **Bu yardımcı bir ölçüm hatasından doğdu.** İlk turda tahsil testini
/// doğrudan `LifeGenerator` çıktısıyla yazmıştım ve "oturulan ev satılmadı"
/// diye geçiyordu — oysa taze üretilen hayatın **hiç eşyası yok**, yani
/// test hiçbir şeyi kanıtlamıyordu. 1000 hayatlık ölçümde de "zorunlu
/// tahsil gören %0,0" çıkması aynı sebepten.
GameState _malli(GameState state, {int? oturulanFiyat}) {
  final List<OwnedItem> mallar = <OwnedItem>[
    const OwnedItem(
      id: 'saat-1',
      typeId: 'saat_klasik',
      acquiredAtAge: 28,
      purchasePrice: 40000,
    ),
    const OwnedItem(
      id: 'arac-1',
      typeId: 'otomobil_binek',
      acquiredAtAge: 29,
      purchasePrice: 600000,
    ),
    const OwnedItem(
      id: 'yatirim-evi',
      typeId: 'konut_daire',
      acquiredAtAge: 29,
      purchasePrice: 2500000,
    ),
  ];
  if (oturulanFiyat == null) {
    return state.copyWith(items: mallar);
  }
  return state.copyWith(
    items: <OwnedItem>[
      ...mallar,
      OwnedItem(
        id: 'oturulan-ev',
        typeId: 'konut_daire',
        acquiredAtAge: 27,
        purchasePrice: oturulanFiyat,
      ),
    ],
    residenceItemId: 'oturulan-ev',
  );
}

/// [yil] yıl ilerletir; yaş da ilerler (kredi notu eskimesi yaşa bakıyor).
GameState _yillar(GameState state, int yil) {
  GameState s = state;
  for (int y = 0; y < yil; y++) {
    s = Banking.advanceYear(s).state;
    s = s.copyWith(player: s.player.copyWith(age: s.player.age + 1));
  }
  return s;
}

void main() {
  group('Paket AD/4 — borç yaşam döngüsü', () {
    test('§10: hiçbir şeyi olmayan borçlunun borcu sonsuza gitmiyor', () {
      GameState s = _borclu(tohum: 3);
      // Malı da olmasın: tahsil edilecek hiçbir şey yok, en kötü senaryo.
      s = s.copyWith(items: const <Object>[].cast());
      final GameState son = _yillar(s, 60);
      final Loan l = son.loans.first;
      print('En kotu senaryo (tahsil edilecek hicbir sey yok):');
      print('  60 yil sonra borc: ${l.outstanding} · kapandi: ${l.isClosed} · '
          'zarar yazildi: ${l.writtenOff} · yapilandirma: ${l.restructures}');
      expect(l.isClosed, isTrue,
          reason: 'Kredi 60 yilda kapanmadi; olumsuz borc geri gelmis');
      expect(l.outstanding, 0);
      expect(l.writtenOff, isTrue);
      // Sonsuz kuyruk kesildi: borç hiçbir noktada saçma bir büyüklüğe
      // ulaşmasın. Anaparanın 60 katı bile fazlasıyla geniş bir sınır.
      GameState izle = s;
      int enBuyuk = 0;
      for (int y = 0; y < 60; y++) {
        izle = Banking.advanceYear(izle).state;
        izle = izle.copyWith(player: izle.player.copyWith(age: izle.player.age + 1));
        final int borc = NetWorth.debt(izle);
        if (borc > enBuyuk) enBuyuk = borc;
      }
      print('  yol boyunca gorulen en buyuk borc: $enBuyuk');
      expect(enBuyuk, lessThan(200000 * 60),
          reason: 'Borc anaparanin 60 katini gecti; buyume sinirsiz');
    });

    test('§8: aksama yapılandırmayla sonuçlanıyor, sınırsız değil', () {
      GameState s = _borclu(tohum: 5).copyWith(items: const <Object>[].cast());
      final List<String> izler = <String>[];
      for (int y = 0; y < 20; y++) {
        final r = Banking.advanceYear(s);
        s = r.state;
        s = s.copyWith(player: s.player.copyWith(age: s.player.age + 1));
        for (final String m in r.messages) {
          if (m.contains('yapılandırdı') || m.contains('takibe düştü')) {
            izler.add('yil ${y + 1}: $m');
          }
        }
      }
      for (final String i in izler) {
        print(i);
      }
      final Loan l = s.loans.first;
      expect(l.restructures, Banking.prototypeOnlyMaxRestructures,
          reason: 'Yapilandirma hakki kullanilmadi ya da sinir asildi');
      expect(l.isClosed, isTrue);
    });

    test('§9: tahsil maldan karşılıyor, oturulan evi asla satmıyor', () {
      GameState s = _malli(_borclu(tohum: 7, wallet: 0),
          oturulanFiyat: 3000000);
      expect(s.items.length, 4, reason: 'Olcum icin mal gerekiyor');
      final GameState son = _yillar(s, 8);
      final List<String> kalan =
          son.items.map((OwnedItem i) => i.id).toList(growable: false);
      print('Tahsil: 4 mal -> ${kalan.length} mal · kalanlar: $kalan');
      expect(son.items.any((OwnedItem i) => i.id == 'oturulan-ev'), isTrue,
          reason: 'Oturulan ev satildi; §9 bunu ayrica yasakliyor');
      expect(kalan.length, lessThan(4),
          reason: 'Tahsil hic mal satmadi; mekanizma calismiyor');
      // En küçükten başlanır: saat villadan önce gider.
      expect(kalan.contains('saat-1'), isFalse,
          reason: 'En kucuk mal yerine buyugu satilmis');
      expect(son.player.wallet, greaterThanOrEqualTo(0));
      // Tahsil borcu gerçekten kapattı mı? Malı olan borçlu borcunu
      // ödeyebilmeli — zarar yazma yoluna düşmemeli.
      final Loan l = son.loans.first;
      print('  kredi: kapandi ${l.isClosed} · zarar yazildi ${l.writtenOff}');
      expect(l.writtenOff, isFalse,
          reason: 'Mali olan borclunun borcu silinmis; tahsil calismiyor');
    });

    test('§8: kısmi ödeme yapılıyor — eski all-or-nothing hatası yok', () {
      // Taksitin %90'ı cüzdanda: eskiden hiç ödeme yapılmıyordu.
      GameState s = _borclu(tohum: 11, wallet: 81000)
          .copyWith(items: const <Object>[].cast());
      final int oncekiBorc = s.loans.first.outstanding;
      final r = Banking.advanceYear(s);
      final Loan l = r.state.loans.first;
      print('Kismi odeme: cuzdan 81000, taksit 90000 · '
          'borc $oncekiBorc -> ${l.outstanding} · cuzdan ${r.state.player.wallet}');
      expect(r.state.player.wallet, 0, reason: 'Eldeki para borca gitmedi');
      expect(l.missedPayments, 1);
      // Kısmi ödeme borcu düşürdüğü için büyüme, hiç ödeme yapılmamış
      // duruma göre daha az olmalı.
      final GameState hicYok = _borclu(tohum: 11, wallet: 0)
          .copyWith(items: const <Object>[].cast());
      final Loan hicOdemeyen = Banking.advanceYear(hicYok).state.loans.first;
      expect(l.outstanding, lessThan(hicOdemeyen.outstanding),
          reason: 'Kismi odeme borcu azaltmadi');
    });

    test('konut kredisi kendi faiziyle büyüyor (aynı satırdaki ikinci hata)',
        () {
      GameState konut = _borclu(
        tohum: 13,
        purpose: LoanPurpose.konut,
      ).copyWith(items: const <Object>[].cast());
      GameState ihtiyac = _borclu(
        tohum: 13,
        purpose: LoanPurpose.ihtiyac,
      ).copyWith(items: const <Object>[].cast());
      konut = Banking.advanceYear(konut).state;
      ihtiyac = Banking.advanceYear(ihtiyac).state;
      print('Odenmeyen borc bir yil sonra: '
          'konut ${konut.loans.first.outstanding} · '
          'ihtiyac ${ihtiyac.loans.first.outstanding}');
      expect(konut.loans.first.outstanding,
          lessThan(ihtiyac.loans.first.outstanding),
          reason: 'Konut kredisi ihtiyac kredisi faiziyle buyuyor; '
              'l.bank.yearlyRate purpose\'u yok sayiyor demektir');
    });

    test('§11: kredi notu izi eskiyor ama hemen silinmiyor', () {
      GameState s = _borclu(tohum: 17).copyWith(items: const <Object>[].cast());
      s = _yillar(s, 12);
      final Loan l = s.loans.first;
      expect(l.isClosed, isTrue);
      expect(l.missedPayments, greaterThan(0),
          reason: 'Gecmis silinmis; kayit korunmali');
      final int hemen = Banking.missedPayments(s);
      final GameState sonra = s.copyWith(
        player: s.player.copyWith(
          age: (l.closedAtAge ?? s.player.age) + Banking.prototypeOnlyRecordYears,
        ),
      );
      final int gec = Banking.missedPayments(sonra);
      print('Kredi notunda sayilan kacak: kapanistan hemen sonra $hemen · '
          '${Banking.prototypeOnlyRecordYears} yil sonra $gec');
      expect(hemen, greaterThan(0),
          reason: 'Kapanis izi hemen silinmemeli');
      expect(gec, 0, reason: 'Omur boyu kredi yasagi olmamali (§11)');
    });

    test('§26: borç durumu kayıttan aynen çıkıyor', () {
      GameState s = _borclu(tohum: 19).copyWith(items: const <Object>[].cast());
      s = _yillar(s, 4);
      final Loan once = s.loans.first;
      final Loan geri = decodeGameState(encodeGameState(s)).loans.first;
      expect(geri.outstanding, once.outstanding);
      expect(geri.missedPayments, once.missedPayments);
      expect(geri.missedStreak, once.missedStreak);
      expect(geri.restructures, once.restructures);
      expect(geri.writtenOff, once.writtenOff);
      expect(geri.closedAtAge, once.closedAtAge);
      expect(geri.annualPayment, once.annualPayment);
      expect(geri.remainingPayments, once.remainingPayments);
    });

    test('§27: kayıt/yükleme borç durumunu sıfırlamıyor', () {
      GameState s = _borclu(tohum: 23).copyWith(items: const <Object>[].cast());
      s = _yillar(s, 3);
      // Saldırı: kaydı yazıp geri yükleyerek gecikme serisini sıfırlamak.
      GameState kayitli = decodeGameState(encodeGameState(s));
      final Loan a = Banking.advanceYear(s).state.loans.first;
      final Loan b = Banking.advanceYear(kayitli).state.loans.first;
      expect(b.outstanding, a.outstanding);
      expect(b.missedStreak, a.missedStreak);
      expect(b.restructures, a.restructures);
    });

    test('§24: 1000 borçlu hayat — sonsuz borç yok', () {
      final List<int> enBuyukBorclar = <int>[];
      final List<int> kapanmaSuresi = <int>[];
      int gecikmeGoren = 0;
      int yapilandirmaGoren = 0;
      int zararYazilan = 0;
      int tahsilGoren = 0;
      int eksiServet = 0;
      int hicKapanmayan = 0;
      final Random rng = Random(4242);

      for (int i = 0; i < 1000; i++) {
        final int anapara = 50000 + rng.nextInt(450000);
        final int taksit = (anapara / (2 + rng.nextInt(6))).round();
        GameState s = _borclu(
          tohum: 100000 + i,
          wallet: rng.nextInt(60000),
          principal: anapara,
          annualPayment: taksit,
          bank: rng.nextBool() ? Bank.fakbank : Bank.bankavrupa,
          purpose: rng.nextBool() ? LoanPurpose.konut : LoanPurpose.ihtiyac,
        );
        // Borçluların bir kısmı malı olan, bir kısmı hiçbir şeyi olmayan
        // insanlar. İkisi de gerçek: tahsil yolu da, zarar yazma yolu da
        // ölçülmeli.
        if (i % 3 != 0) {
          s = _malli(s, oturulanFiyat: i % 2 == 0 ? 2800000 : null);
        }
        int enBuyuk = 0;
        int kapanis = -1;
        bool tahsil = false;
        for (int y = 0; y < 60; y++) {
          final r = Banking.advanceYear(s);
          s = r.state;
          s = s.copyWith(player: s.player.copyWith(age: s.player.age + 1));
          for (final String m in r.messages) {
            if (m.contains('elden çıktı') || m.contains('çözüldü')) tahsil = true;
          }
          final int borc = NetWorth.debt(s);
          if (borc > enBuyuk) enBuyuk = borc;
          if (kapanis < 0 && s.loans.first.isClosed) kapanis = y + 1;
        }
        final Loan l = s.loans.first;
        enBuyukBorclar.add(enBuyuk);
        if (kapanis > 0) {
          kapanmaSuresi.add(kapanis);
        } else {
          hicKapanmayan++;
        }
        if (l.missedPayments > 0) gecikmeGoren++;
        if (l.restructures > 0) yapilandirmaGoren++;
        if (l.writtenOff) zararYazilan++;
        if (tahsil) tahsilGoren++;
        if (NetWorth.of(s) < 0) eksiServet++;
      }

      enBuyukBorclar.sort();
      kapanmaSuresi.sort();
      print('');
      print('--- 1000 BORCLU HAYAT (60 yil) ---');
      print('  gecikme goren            %${(gecikmeGoren / 10).toStringAsFixed(1)}');
      print('  yapilandirma goren       %${(yapilandirmaGoren / 10).toStringAsFixed(1)}');
      print('  zorunlu tahsil goren     %${(tahsilGoren / 10).toStringAsFixed(1)}');
      print('  zarar yazilarak kapanan  %${(zararYazilan / 10).toStringAsFixed(1)}');
      print('  hic kapanmayan           $hicKapanmayan');
      print('  eksi net servetle biten  %${(eksiServet / 10).toStringAsFixed(1)}');
      print('  kapanma suresi (yil)     medyan '
          '${kapanmaSuresi.isEmpty ? "-" : kapanmaSuresi[kapanmaSuresi.length ~/ 2]} · '
          'en uzun ${kapanmaSuresi.isEmpty ? "-" : kapanmaSuresi.last}');
      print('  gorulen en buyuk borc    medyan '
          '${enBuyukBorclar[500]} · en buyuk ${enBuyukBorclar.last}');

      // Hiçbir kredi açık kalmasın: 60 yıl sonunda hepsi bir sona ulaşmış.
      expect(hicKapanmayan, 0,
          reason: 'Bazi krediler 60 yilda hic kapanmadi; olumsuz borc var');
      // Sonsuz kuyruk yok: en kötü yolda bile borç makul bir bantta.
      // Gecikme faizi anaparanın katıyla sınırlı, anapara da en fazla
      // ₺500.000: görülebilecek en büyük borç bunun katı kadar olabilir.
      expect(enBuyukBorclar.last,
          lessThan((500000 * Banking.prototypeOnlyMaxDebtMultiple).round() + 1),
          reason: 'Gorulen en buyuk borc gecikme faizi tavanini asti');
      // Mekanizmanın hepsi gerçekten çalışıyor olsun.
      expect(gecikmeGoren, greaterThan(0));
      expect(yapilandirmaGoren, greaterThan(0));
    }, timeout: const Timeout(Duration(minutes: 10)));
  });
}

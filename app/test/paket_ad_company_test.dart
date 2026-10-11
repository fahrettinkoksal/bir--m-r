// Paket AD/2 — şirket sağlık modeli (§AD/2, §1-§5, §23, §26).
//
// **Neden var.** Paket AC'de şirket olayları vardı ama şirketlerin bir
// *hâli* yoktu: kim batacağını yalnızca kataloğa yazılı sabit bir
// `fragility` sayısı ve o yılın rejimi belirliyordu. Oyuncunun gözünden
// bakınca bu "rastgele kötü haber"di — bir şirketin yıllardır borç
// çevirmekte zorlandığını fark etme imkânı yoktu, çünkü öyle bir şey
// gerçekten yoktu.
//
// Artık beş gizli gösterge (mali sağlık, borç baskısı, büyüme, yönetim
// kalitesi, güven) ve sektör gücü her yıl yürüyor, kayda giriyor ve
// olayların ihtimalini belirliyor.
// ignore_for_file: avoid_print
library;

import 'dart:math';

import 'package:bir_omur/data/company_catalog.dart';
import 'package:bir_omur/data/save/game_state_codec.dart';
import 'package:bir_omur/domain/economy/company_engine.dart';
import 'package:bir_omur/domain/economy/incident_engine.dart';
import 'package:bir_omur/domain/economy/market_engine.dart';
import 'package:bir_omur/domain/generation/life_generator.dart';
import 'package:bir_omur/domain/models/company_vitals.dart';
import 'package:bir_omur/domain/models/game_state.dart';
import 'package:bir_omur/domain/models/market_incident.dart';
import 'package:bir_omur/domain/models/market_state.dart';
import 'package:flutter_test/flutter_test.dart';

/// Şirket-yılı yürüten ortak koşu.
({
  Map<CompanyStatus, int> durumYillari,
  int kapanan,
  int toparlanan,
  int kotulesen,
  int yeniSirket,
  List<int> stresYuzde,
  int sirketYili,
  MarketState son,
}) _kos({required int yil, required int tohum}) {
  MarketState st = const MarketState();
  final Random rng = Random(tohum);
  final Map<CompanyStatus, int> sayac = <CompanyStatus, int>{
    for (final CompanyStatus s in CompanyStatus.values) s: 0,
  };
  final List<int> stres = <int>[];
  int kapanan = 0;
  int toparlanan = 0;
  int kotulesen = 0;
  int yeniSirket = 0;
  int sirketYili = 0;

  for (int y = 0; y < yil; y++) {
    final ({MarketState state, MarketYear year}) piyasa =
        MarketEngine.advance(state: st, newAge: y, rng: rng);
    final ({
      Map<String, CompanyVitals> vitals,
      Map<String, int> sectorStrength,
      Map<String, String> statusChanges,
    }) sirketler = CompanyEngine.advance(
      state: st,
      regime: piyasa.state.regime,
      rng: rng,
    );
    st = piyasa.state.copyWith(
      companyVitals: sirketler.vitals,
      sectorStrength: sirketler.sectorStrength,
      companyStatus: <String, String>{
        ...piyasa.state.companyStatus,
        ...sirketler.statusChanges,
      },
    );

    final Map<String, CompanyStatus> oncekiDurum = <String, CompanyStatus>{
      for (final Company c in kAllCompanies) c.id: st.statusOf(c.id),
    };

    final IncidentOutcome olaylar = IncidentEngine.advance(
      state: st,
      regime: st.regime,
      newAge: y,
      basketValue: 1000000,
      fundValue: 500000,
      rng: rng,
    );
    st = st.copyWith(
      companyStatus: olaylar.companyStatus,
      companyClosedAtAge: olaylar.companyClosedAtAge,
      companySuccessors: olaylar.companySuccessors,
      halts: olaylar.halts,
    );

    for (final Company c in st.activeBasketCompanies) {
      sayac[st.statusOf(c.id)] = sayac[st.statusOf(c.id)]! + 1;
      stres.add((st.vitalsOf(c.id).stress * 100).round());
      sirketYili++;
    }
    for (final Company c in kAllCompanies) {
      final CompanyStatus once = oncekiDurum[c.id]!;
      final CompanyStatus simdi = st.statusOf(c.id);
      if (once == simdi) continue;
      if (simdi == CompanyStatus.kapandi) {
        kapanan++;
      } else if (simdi.index < once.index) {
        toparlanan++;
      } else {
        kotulesen++;
      }
    }
    yeniSirket += olaylar.incidents
        .where((MarketIncident i) => i.kind == IncidentKind.yeniSirket)
        .length;
  }
  return (
    durumYillari: sayac,
    kapanan: kapanan,
    toparlanan: toparlanan,
    kotulesen: kotulesen,
    yeniSirket: yeniSirket,
    stresYuzde: stres,
    sirketYili: sirketYili,
    son: st,
  );
}

void main() {
  group('Paket AD/2 — şirket sağlık modeli', () {
    test('taban değerler katalogdaki kırılganlıkla tutarlı', () {
      // `MarketState._tabanFor` ile `CompanyEngine.baselineFor` **aynı**
      // hesabı yapmak zorunda: biri model, biri motor tarafında duruyor ve
      // ayrışırlarsa kayıtta göstergesi olmayan şirket motorun beklediğinden
      // farklı bir yerden başlar. Bu test o ikisini karşılaştırıyor.
      final MarketState bos = const MarketState();
      for (final Company c in kCompanyCatalog) {
        final CompanyVitals model = bos.vitalsOf(c.id);
        final CompanyVitals motor = CompanyEngine.baselineFor(c);
        expect(model.financialHealth, motor.financialHealth, reason: c.id);
        expect(model.debtPressure, motor.debtPressure, reason: c.id);
        expect(model.growth, motor.growth, reason: c.id);
        expect(model.management, motor.management, reason: c.id);
        expect(model.confidence, motor.confidence, reason: c.id);
      }
      // Kırılgan şirketin tabanı gerçekten daha kötü olmalı.
      final Company kirilgan =
          kCompanyCatalog.firstWhere((Company c) => c.id == 'ege_insaat');
      final Company saglam =
          kCompanyCatalog.firstWhere((Company c) => c.id == 'marmara_gida');
      expect(bos.vitalsOf(kirilgan.id).stress,
          greaterThan(bos.vitalsOf(saglam.id).stress),
          reason: 'Kirilgan sirket daha az stresli cikti; taban ters');
    });

    test('§1: sağlıklı şirket tek yılda batmıyor', () {
      // Sağlıklı bir şirketin durumu bir yılda en fazla bir kademe
      // kötüleşebilir ve `normal`den doğrudan `kapandi`ya gidilemez.
      int normaldenKapanan = 0;
      for (int t = 0; t < 200; t++) {
        final r = _kos(yil: 1, tohum: 9000 + t);
        for (final Company c in kCompanyCatalog) {
          if (r.son.statusOf(c.id) == CompanyStatus.kapandi) {
            normaldenKapanan++;
          }
        }
      }
      print('200 tek yillik kosuda normalden dogrudan kapanan: '
          '$normaldenKapanan');
      expect(normaldenKapanan, 0,
          reason: 'Saglikli sirket tek yilda batti; kademeli ilerleme bozuk');
    });

    test('§1: durum her yıl değişmiyor — iyi şirket iyi kalabiliyor', () {
      final r = _kos(yil: 400, tohum: 77);
      final int degisim = r.kapanan + r.toparlanan + r.kotulesen;
      final double degisimOrani = degisim / r.sirketYili;
      print('400 yil · sirket-yili ${r.sirketYili} · durum degisimi $degisim '
          '(%${(degisimOrani * 100).toStringAsFixed(1)})');
      expect(degisimOrani, lessThan(0.10),
          reason: 'Sirketler her yil durum degistiriyor; istikrar yok');
      expect(degisim, greaterThan(0),
          reason: 'Hicbir sirket hic durum degistirmiyor; model olu');
    });

    test('§2: sektör gücü şirketleri etkiliyor ama aynılaştırmıyor', () {
      final r = _kos(yil: 300, tohum: 31);
      // Aynı sektördeki iki şirket aynı göstergeye sahip olmasın.
      final List<Company> insaat = kCompanyCatalog
          .where((Company c) => c.sector == CompanySector.insaat)
          .toList(growable: false);
      expect(insaat.length, greaterThanOrEqualTo(2));
      final CompanyVitals a = r.son.vitalsOf(insaat[0].id);
      final CompanyVitals b = r.son.vitalsOf(insaat[1].id);
      print('Ayni sektor iki sirket: ${insaat[0].id} stres '
          '${(a.stress * 100).round()} · ${insaat[1].id} stres '
          '${(b.stress * 100).round()}');
      expect(a.stress == b.stress, isFalse,
          reason: 'Ayni sektordeki iki sirket birebir ayni hareket ediyor');
      // Sektör gücü nötrde çakılı kalmasın.
      final Set<int> gucler = <int>{
        for (final CompanySector s in CompanySector.values)
          r.son.sectorStrengthOf(s),
      };
      print('Sektor gucleri: $gucler');
      expect(gucler.length, greaterThan(1),
          reason: 'Butun sektorler ayni gucte; sektor modeli olu');
    });

    test('§3: yönetim kalitesi yavaş değişiyor', () {
      final MarketState bos = const MarketState();
      final r = _kos(yil: 60, tohum: 12);
      int enBuyukSapma = 0;
      for (final Company c in kCompanyCatalog) {
        final int fark =
            (r.son.vitalsOf(c.id).management - bos.vitalsOf(c.id).management)
                .abs();
        if (fark > enBuyukSapma) enBuyukSapma = fark;
      }
      print('60 yilda yonetim kalitesinde en buyuk sapma: $enBuyukSapma puan');
      // Yavaş değişiyor: 60 yılda bile göstergenin tamamını dolaşmıyor.
      expect(enBuyukSapma, lessThan(45),
          reason: 'Yonetim kalitesi cok hizli degisiyor; yapisal degil');
      expect(enBuyukSapma, greaterThan(0),
          reason: 'Yonetim kalitesi hic degismiyor');
    });

    test('§5: kapanan şirketin yerine YENİ bir şirket geliyor', () {
      // Kapanmayı elle kuruyoruz: ölçüm değil, mekanizma testi.
      MarketState st = MarketState(
        companyStatus: <String, String>{
          'ege_insaat': CompanyStatus.kapandi.name,
        },
        companyClosedAtAge: const <String, int>{'ege_insaat': 30},
      );
      expect(st.activeBasketCompanies.any((Company c) => c.id == 'ege_insaat'),
          isFalse);
      String? yeni;
      for (int y = 30; y < 30 + kCompanySuccessorYears + 3; y++) {
        final IncidentOutcome o = IncidentEngine.advance(
          state: st,
          regime: MarketRegime.normal,
          newAge: y,
          basketValue: 1000000,
          fundValue: 0,
          rng: Random(500 + y),
        );
        st = st.copyWith(
          companyStatus: o.companyStatus,
          companyClosedAtAge: o.companyClosedAtAge,
          companySuccessors: o.companySuccessors,
        );
        if (st.companySuccessors['ege_insaat'] != null) {
          yeni = st.companySuccessors['ege_insaat'];
          print('yil $y: ege_insaat yerine $yeni geldi');
          break;
        }
      }
      expect(yeni, isNotNull, reason: 'Kapanan sirketin yerine yenisi gelmedi');
      // **Aynı şirket dirilmedi:** yeni kimlik yedek havuzundan.
      expect(yeni, isNot('ege_insaat'));
      expect(kCompanyReserve.any((Company c) => c.id == yeni), isTrue);
      expect(st.statusOf('ege_insaat'), CompanyStatus.kapandi,
          reason: 'Kapanan sirket normale dondu; §5 bunu yasakliyor');
      // Yeni şirket kapananın sepet payını devraldı.
      expect(st.basketWeightOf(yeni!),
          kCompanyCatalog.firstWhere((Company c) => c.id == 'ege_insaat')
              .basketWeight);
      expect(st.activeBasketCompanies.any((Company c) => c.id == yeni), isTrue);
    });

    test('§23: 10.000+ şirket-yılı durum dağılımı', () {
      final r = _kos(yil: 1200, tohum: 4242);
      print('');
      print('--- SIRKET DURUM DAGILIMI (${r.sirketYili} sirket-yili) ---');
      r.durumYillari.forEach((CompanyStatus s, int v) {
        if (v == 0 && s == CompanyStatus.kapandi) return;
        print('  ${s.name.padRight(12)} '
            '%${(100 * v / r.sirketYili).toStringAsFixed(2)}');
      });
      final List<int> stres = List<int>.of(r.stresYuzde)..sort();
      print('  stres: medyan ${stres[stres.length ~/ 2]} · '
          'p10 ${stres[(stres.length * 0.10).floor()]} · '
          'p90 ${stres[(stres.length * 0.90).floor()]}');
      print('  gecis: kotulesen ${r.kotulesen} · toparlanan ${r.toparlanan} · '
          'kapanan ${r.kapanan} · yerine gelen yeni sirket ${r.yeniSirket}');

      expect(r.sirketYili, greaterThan(10000),
          reason: '§23 en az 10.000 sirket-yili istiyor');
      // Şirketlerin çoğu çoğu zaman normal: kriz istisna olmalı.
      final int normal = r.durumYillari[CompanyStatus.normal]!;
      expect(normal / r.sirketYili, greaterThan(0.55),
          reason: 'Sirketlerin cogu surekli sikintida; ekonomi surekli kriz');
      // Ama hiçbir şirket hiç zorlanmıyor da olmasın.
      final int zor = r.durumYillari[CompanyStatus.sikinti]! +
          r.durumYillari[CompanyStatus.konkordato]! +
          r.durumYillari[CompanyStatus.kayyum]!;
      expect(zor, greaterThan(0), reason: 'Hicbir sirket hic zorlanmiyor');
      // Toparlanma gerçekten oluyor (§1: kötü şirket toparlanabilir).
      expect(r.toparlanan, greaterThan(0),
          reason: 'Hicbir sirket toparlanmiyor; surec tek yonlu');
      // Kapanma nadir ama erişilebilir (§8 AC).
      expect(r.kapanan, greaterThan(0), reason: 'Hicbir sirket kapanmiyor');
      // Kapananların yerine yenisi geliyor (§5).
      expect(r.yeniSirket, greaterThan(0),
          reason: 'Kapanan sirketlerin yerine hic yeni sirket gelmedi');
    }, timeout: const Timeout(Duration(minutes: 8)));

    test('§26: şirket sağlık durumu kayıttan aynen çıkıyor', () {
      GameState s =
          LifeGenerator.seeded(5).generate(mode: StartMode.tamamenRastgele);
      final r = _kos(yil: 120, tohum: 88);
      s = s.copyWith(market: r.son);
      final GameState geri = decodeGameState(encodeGameState(s));
      for (final Company c in kAllCompanies) {
        final CompanyVitals a = s.market.vitalsOf(c.id);
        final CompanyVitals b = geri.market.vitalsOf(c.id);
        expect(b.financialHealth, a.financialHealth, reason: c.id);
        expect(b.debtPressure, a.debtPressure, reason: c.id);
        expect(b.growth, a.growth, reason: c.id);
        expect(b.management, a.management, reason: c.id);
        expect(b.confidence, a.confidence, reason: c.id);
        expect(geri.market.statusOf(c.id), s.market.statusOf(c.id),
            reason: c.id);
      }
      for (final CompanySector sec in CompanySector.values) {
        expect(geri.market.sectorStrengthOf(sec), s.market.sectorStrengthOf(sec));
      }
      expect(geri.market.companySuccessors, s.market.companySuccessors);
      expect(geri.market.companyClosedAtAge, s.market.companyClosedAtAge);
      // Ölçüm anlamlı olsun: göstergeler varsayılandan ayrılmış olmalı.
      final MarketState bos = const MarketState();
      final bool kaymis = kCompanyCatalog.any((Company c) =>
          s.market.vitalsOf(c.id).financialHealth !=
          bos.vitalsOf(c.id).financialHealth);
      expect(kaymis, isTrue, reason: '120 yilda hicbir gosterge kaymamis');
    });

    test('§27: kayıt/yükleme şirket kaderini yeniden çevirmiyor', () {
      GameState s =
          LifeGenerator.seeded(6).generate(mode: StartMode.tamamenRastgele);
      final r = _kos(yil: 80, tohum: 99);
      s = s.copyWith(market: r.son);
      final GameState kayitli = decodeGameState(encodeGameState(s));
      // Aynı tohumla bir yıl daha: iki tarafta aynı sonuç çıkmalı.
      final IncidentOutcome a = IncidentEngine.advance(
        state: s.market,
        regime: MarketRegime.normal,
        newAge: 81,
        basketValue: 1000000,
        fundValue: 0,
        rng: Random(1234),
      );
      final IncidentOutcome b = IncidentEngine.advance(
        state: kayitli.market,
        regime: MarketRegime.normal,
        newAge: 81,
        basketValue: 1000000,
        fundValue: 0,
        rng: Random(1234),
      );
      expect(b.companyStatus, a.companyStatus);
      expect(b.incidents.length, a.incidents.length);
    });
  });
}

// Paket AN — spor kariyerinin bug fix sonrası ölçümü ve kalibrasyonu.
//
// Q-184 #1'deki anahtar hatası düzeltilince "çalışan sporcu formunu daha
// iyi korur" kuralı ilk defa gerçekten çalışmaya başladı. Bu dosya
// sonucun ekonomiye ne yaptığını ölçer.
//
// ÜÇ ÖLÇÜM (§17) — genel 3000 hayat YOK:
//   A) 6 sanat × 100 adanmış sporcu = 600
//   B) 150 sporcu: 0 / 2 / 4 / 8 ders/yıl
//   C) 150 sporcu: işsiz / part-time / full-time
//
// BRÜT DEĞİL NET (§7). Kohort sporcunun kasasına giren ödül ve sponsor
// gelirini değil, **spor yüzünden** cebinden çıkan parayı da sayar:
// ders ücreti, koç ücreti, kamp bedeli ve sakatlık tedavisi. Kalibrasyon
// net gelire göre yapıldı; brüt purse yanıltıcı.
//
// ÜÇ AŞAMA (§19). `_Mod`:
//   * `bugluTelafiYok` — anahtar hatasının aynısı: ders alınıyor, parası
//     ödeniyor, teknik basamak kazanılıyor, ama form motoru dersi
//     görmüyor. Hatanın eski davranışını **fixture ile** yeniden üretir;
//     git history'ye dokunmadan karşılaştırma verir.
//   * `duzeltilmis` — bugünkü ürün.
//
// FIXED RAW (bug düzeldi, kalibrasyon yapılmadı) aşaması bu dosyadan
// yeniden üretilemez, çünkü kalibrasyon ürünün `static const`
// sabitlerini değiştirdi. O aşamanın sayıları Paket AN raporunda ve
// Q-184 #1'de kayıt altında.
//
// Sporcu botu hile yapmıyor: ders parası cüzdandan çıkıyor, teknik
// basamak gerçekten ders alarak kazanılıyor, kamp ve koç ücreti
// ödeniyor.
//
// ignore_for_file: avoid_print
library;

import 'dart:math';

import 'package:bir_omur/data/combat_circuit_catalog.dart';
import 'package:bir_omur/data/economy.dart';
import 'package:bir_omur/data/job_catalog.dart';
import 'package:bir_omur/data/martial_arts_catalog.dart';
import 'package:bir_omur/domain/activities/martial_arts_engine.dart';
import 'package:bir_omur/domain/combat/combat_career_engine.dart';
import 'package:bir_omur/domain/combat/martial_lesson_counter.dart';
import 'package:bir_omur/domain/combat/sport_workload.dart';
import 'package:bir_omur/domain/generation/life_generator.dart';
import 'package:bir_omur/domain/models/combat_career.dart';
import 'package:bir_omur/domain/models/game_state.dart';
import 'package:bir_omur/domain/models/martial_progress.dart';
import 'package:flutter_test/flutter_test.dart';

const MartialArtsEngine _dersMotoru = MartialArtsEngine();

/// Ölçüm aşaması (§19).
enum _Mod {
  /// Anahtar hatasının davranışı: ders sayacı form motoruna ulaşmıyor.
  bugluTelafiYok,

  /// Bugünkü ürün.
  duzeltilmis,
}

/// İş yükü senaryosu (§13).
enum _Is { yok, yarim, tam }

/// Koç harcama politikası.
///
/// Koç ücreti **her yıl** yeniden ödenir, o yüzden politika seçimi
/// kariyer net gelirini ciddi biçimde değiştiriyor (§7).
enum _Koc {
  /// Hiç koç tutmaz.
  ///
  /// **Başlık kohortu bu.** Sebep karşılaştırılabilirlik: §5'teki
  /// "bug öncesi 4,04M" referansı Paket AL'in kohortundan geliyor ve o
  /// kohort koç tutmuyordu. Aynı elmayı aynı elmayla karşılaştırmak için
  /// başlık ölçümü de koçsuz. Koçun bedeli ayrı testte (`AN/koç`).
  yok,

  /// Kazancın koçu taşıdığı ölçüde tutar.
  basiretli,

  /// Parası yettiği an en pahalı koçu tutar.
  maksimal,
}

/// Koç seçer.
///
/// `basiretli` politika kararı **kasaya değil kazanca** bakar: koç ücreti
/// her yıl tekrar ödendiği için "cüzdanım şişkin, en pahalısını alayım"
/// davranışı kariyer boyunca kazancın büyük kısmını yiyor. Basiretli
/// sporcu ancak müsabaka geliri ücreti rahat taşıyorsa koç tutar.
GameState _kocSec(GameState s, _Koc politika) {
  final CombatCareer? k = CombatCareerEngine.activeCareer(s);
  if (k == null || k.isRetired) return s;

  int hedef;
  switch (politika) {
    case _Koc.yok:
      hedef = 0;
    case _Koc.maksimal:
      hedef = s.player.wallet > CombatCareerEngine.coachCost(2) * 3
          ? 2
          : s.player.wallet > CombatCareerEngine.coachCost(1) * 3
              ? 1
              : 0;
    case _Koc.basiretli:
      // Bugüne kadarki ortalama yıllık müsabaka geliri.
      final int yil =
          (s.player.age - k.startedCompetitiveAtAge).clamp(1, 60);
      final int yillikKazanc = k.careerEarnings ~/ yil;
      hedef = yillikKazanc > CombatCareerEngine.coachCost(2) * 3
          ? 2
          : yillikKazanc > CombatCareerEngine.coachCost(1) * 3
              ? 1
              : 0;
  }
  if (hedef == k.coachLevel) return s;
  // Elit koç üst kademe istiyor; kabul etmezse motor reddediyor.
  final r = CombatCareerEngine.setCoach(s, hedef);
  return r.applied ? r.state : s;
}

/// Bir sporcu hayatının özeti — brüt ve net ayrı ayrı.
class _Sporcu {
  _Sporcu(this.artId);

  final String artId;
  bool rekabeteBasladi = false;
  bool elitOldu = false;
  bool sampiyonOldu = false;
  bool ciddiSakatlandi = false;
  int sampiyonlukSayisi = 0;
  int galibiyet = 0;
  int maglubiyet = 0;
  int mac = 0;
  int sakatlik = 0;
  int kariyerYili = 0;
  int sonForm = 0;
  int dersSayisi = 0;

  // --- para kalemleri (§7) -----------------------------------------
  /// Müsabaka ödülleri (brüt purse).
  int odul = 0;

  /// Sponsorluk geliri.
  int sponsor = 0;

  /// Ders ücretleri.
  int dersGideri = 0;

  /// Koç ücretleri.
  int kocGideri = 0;

  /// Müsabaka başına cepten çıkan: kamp bedeli + sakatlık tedavisi.
  /// Motor ikisini aynı çağrıda tahsil ettiği için cüzdanda birlikte
  /// ölçülüyor; kampın liste fiyatı [kampNominal] olarak ayrıca tutuluyor.
  int musabakaGideri = 0;

  /// Seçilen kampların liste fiyatı toplamı.
  int kampNominal = 0;

  int get brut => odul + sponsor;
  int get gider => dersGideri + kocGideri + musabakaGideri;
  int get net => brut - gider;
}

MartialArt _sanat(String id) =>
    MartialArt.values.firstWhere((MartialArt a) => a.id == id);

String _tamZamanliIs() =>
    kJobCatalog.firstWhere((JobType j) => !j.partTime).id;
String _yariZamanliIs() =>
    kJobCatalog.firstWhere((JobType j) => j.partTime).id;

/// Bir sporcu hayatı oynar ve brüt/net dökümü döner.
///
/// [dersHedefi] null ise sporcu parası yettiği kadar ders alır (A ve C
/// kohortları). Sayı verilirse o kadar ders alır (B kohortu).
_Sporcu _hayatOyna(
  String artId,
  int seed, {
  _Mod mod = _Mod.duzeltilmis,
  _Is is_ = _Is.yok,
  int? dersHedefi,
  _Koc kocPolitikasi = _Koc.yok,
  bool teknikVerilsin = false,
}) {
  final MartialArt art = _sanat(artId);
  final CombatCircuit yol = combatCircuitFor(artId)!;
  final Random rng = Random(seed);
  final _Sporcu ozet = _Sporcu(artId);

  GameState s =
      LifeGenerator.seeded(seed).generate(mode: StartMode.tamamenRastgele);
  // Bu bir gelir simülasyonu değil, kariyer dağılımı simülasyonu:
  // sporcunun ders parası olmalı. Harçlık gerçekçi bir bantta.
  final int yillikHarclik =
      (Economy.netYearlyMinimumWage * (0.10 + rng.nextDouble() * 0.25)).round();

  s = s.copyWith(
    player: s.player.copyWith(
      age: art.minAge,
      wallet: yillikHarclik,
      // Paket AM: rekabetçi kariyere başlamak için sağlık 80 gerekiyor.
      // Kohortun bir kısmı bu kapıyı geçemiyor ve bu bilinçli.
      stats: s.player.stats.copyWith(health: 74 + rng.nextInt(24)),
    ),
    pendingEvent: null,
    // B kohortu için: rekabete başlamaya yeten teknik basamak baştan
    // verilir. Ölçülen şey **form telafisi**; "hiç ders almayan sporcu
    // rekabete hiç başlayamıyor" ayrı bir gerçek ve o bandı boş
    // bıraktığı için karşılaştırmayı imkânsız kılıyordu.
    martialArts: teknikVerilsin
        ? <MartialProgress>[
            MartialProgress(
              artId: artId,
              lessons: art.ranks[combatCircuitFor(artId)!.minLevelFor(0)]
                  .lessonsNeeded,
              startedAtAge: art.minAge,
            ),
          ]
        : s.martialArts,
  );

  if (is_ != _Is.yok) {
    s = s.copyWith(
      career: s.career.copyWith(
        jobId: is_ == _Is.tam ? _tamZamanliIs() : _yariZamanliIs(),
        startedAtAge: art.minAge,
        salary: 40000,
      ),
    );
  }

  for (int yas = art.minAge; yas <= 46; yas++) {
    s = s.copyWith(
      player:
          s.player.copyWith(age: yas, wallet: s.player.wallet + yillikHarclik),
      // Yıllık sayaçlar yaş başında sıfırlanır (oyunun kendi kuralı).
      interactionCounts: const <String, int>{},
    );

    // --- 1) teknik çalışma ------------------------------------------
    final int cuzdanDersOncesi = s.player.wallet;
    if (dersHedefi == null) {
      if (_dersMotoru.availability(s, art).isAllowed) {
        s = _dersMotoru.takeSeason(state: s, art: art).state;
      }
    } else {
      for (int i = 0; i < dersHedefi; i++) {
        if (!_dersMotoru.availability(s, art).isAllowed) break;
        s = _dersMotoru.takeLesson(state: s, art: art).state;
      }
    }
    ozet.dersGideri += cuzdanDersOncesi - s.player.wallet;
    ozet.dersSayisi += MartialLessonCounter.read(s, artId);

    // §19: hatanın davranışı — ders alındı, parası ödendi, basamak
    // kazanıldı, ama form motoru sayacı görmüyor.
    if (mod == _Mod.bugluTelafiYok) {
      final Map<String, int> kirpik =
          Map<String, int>.from(s.interactionCounts)
            ..remove(MartialLessonCounter.key(artId));
      s = s.copyWith(interactionCounts: kirpik);
    }

    // --- 2) rekabete başla ------------------------------------------
    if (CombatCareerEngine.activeCareer(s) == null &&
        CombatCareerEngine.startAvailability(s, art).isAllowed) {
      s = CombatCareerEngine.startCompeting(s, art).state;
      ozet.rekabeteBasladi = true;
    }

    // --- 3) yıllık akış: form, sakatlık, koç, sıralama --------------
    final int cuzdanKocOncesi = s.player.wallet;
    s = CombatCareerEngine.advanceYear(s, yas, rng).state;
    ozet.kocGideri += cuzdanKocOncesi - s.player.wallet;

    // --- 3b) koç ------------------------------------------------------
    // §7 koç kalemini istiyor; bot bu parayı gerçek API'den
    // (`setCoach`) harcıyor, elle yazmıyor.
    //
    // Politika **basiretli**, maksimal değil: koç ücreti her yıl
    // tekrar ödendiği için "param varsa en pahalısını al" davranışı
    // kariyer boyunca kazancın büyük kısmını yiyor. Maksimal politikanın
    // ölçümü ayrı testte (`AN/koç`) duruyor.
    s = _kocSec(s, kocPolitikasi);

    // --- 4) müsabakalar ---------------------------------------------
    for (int i = 0; i < CombatCareerEngine.prototypeOnlyMaxBoutsPerAge; i++) {
      final CombatCareer? k = CombatCareerEngine.activeCareer(s);
      if (k == null || k.isRetired) break;
      final firsat = CombatCareerEngine.offerBout(s, rng);
      s = firsat.state;
      if (firsat.bout == null) break;

      final CampChoice kamp = s.player.stats.health < 55
          ? CampChoice.dinlen
          : s.player.wallet >
                  CombatCareerEngine.campCost(CampChoice.yogun) * 2
              ? CampChoice.yogun
              : CampChoice.dengeli;

      final int cuzdanOnce = s.player.wallet;
      final int odulOnce = CombatCareerEngine.activeCareer(s)!.careerEarnings;
      final BoutResult r = CombatCareerEngine.fight(s, kamp);
      if (!r.applied) break;
      s = r.state;

      final CombatCareer sonra = CombatCareerEngine.activeCareer(s)!;
      final int buOdul = sonra.careerEarnings - odulOnce;
      ozet.odul += buOdul;
      // Cüzdan farkı = ödül − (kamp + tedavi). Gider oradan çıkarılıyor;
      // test ürünün fiyat formüllerini kopyalamıyor.
      ozet.musabakaGideri += buOdul - (s.player.wallet - cuzdanOnce);
      ozet.kampNominal += CombatCareerEngine.campCost(kamp);
      ozet.mac++;
      if (r.injury != InjurySeverity.yok) ozet.sakatlik++;
      if (r.injury == InjurySeverity.ciddi) ozet.ciddiSakatlandi = true;
    }

    // --- 5) sponsor --------------------------------------------------
    final int sponsorOnce =
        CombatCareerEngine.activeCareer(s)?.sponsorEarnings ?? 0;
    s = CombatCareerEngine.offerSportSponsor(s, rng).state;
    final int sponsorSonra =
        CombatCareerEngine.activeCareer(s)?.sponsorEarnings ?? sponsorOnce;
    ozet.sponsor += sponsorSonra - sponsorOnce;

    // --- 6) emeklilik baskısı ---------------------------------------
    final RetirementReason? baski = CombatCareerEngine.retirementPressure(s);
    if (baski != null) {
      s = CombatCareerEngine.retire(s, baski).state;
      break;
    }
  }

  final CombatCareer? k = CombatCareerEngine.careerFor(s, artId);
  if (k != null) {
    ozet.galibiyet = k.totalWins;
    ozet.maglubiyet = k.totalLosses;
    ozet.elitOldu = k.tier >= yol.turnsProAtTier;
    ozet.sampiyonOldu = k.championships > 0;
    ozet.sampiyonlukSayisi = k.championships;
    ozet.sonForm = k.form;
    ozet.kariyerYili =
        (k.lastBoutAge ?? k.startedCompetitiveAtAge) - k.startedCompetitiveAtAge;
    if (k.seriousInjuryCount > 0) ozet.ciddiSakatlandi = true;
  }
  return ozet;
}

int _medyan(List<int> v) {
  if (v.isEmpty) return 0;
  final List<int> s = List<int>.from(v)..sort();
  return s[s.length ~/ 2];
}

int _yuzdelik(List<int> v, double p) {
  if (v.isEmpty) return 0;
  final List<int> s = List<int>.from(v)..sort();
  return s[((s.length - 1) * p).round().clamp(0, s.length - 1)];
}

double _ort(List<int> v) =>
    v.isEmpty ? 0 : v.reduce((int a, int b) => a + b) / v.length;

String _m(int tl) => '${(tl / 1000000).toStringAsFixed(2)}M';

/// A kohortu: 6 sanat × 100 sporcu.
Map<String, List<_Sporcu>> _kohortA(_Mod mod, {_Koc koc = _Koc.yok}) {
  final Map<String, List<_Sporcu>> hepsi = <String, List<_Sporcu>>{};
  for (final CombatCircuit yol in kCombatCircuits) {
    final List<_Sporcu> liste = <_Sporcu>[];
    for (int i = 0; i < 100; i++) {
      liste.add(_hayatOyna(
        yol.artId,
        70000 + i * 13 + yol.artId.hashCode,
        mod: mod,
        kocPolitikasi: koc,
      ));
    }
    hepsi[yol.artId] = liste;
  }
  return hepsi;
}

void main() {
  // =================================================================
  // §17/A, §18 — 6 sanat × 100 sporcu, sanat tablosu
  // =================================================================
  test('AN/A — 6 sanat x 100 sporcu: brüt/net tablo', () {
    final Map<String, List<_Sporcu>> hepsi = _kohortA(_Mod.duzeltilmis);

    print('');
    print('=' * 96);
    print('PAKET AN /A — 600 SPORCU (bug fix + kalibrasyon sonrası)');
    print('=' * 96);
    print('sanat          elit%  şamp%  ort.maç  medyan  ciddi   brüt    '
        'NET    iyi%10   kötü%10');
    print('                                       yıl   sakat%  medyan  '
        'medyan   net      net');

    final List<int> tumNet = <int>[];
    final List<int> tumBrut = <int>[];
    final Map<String, int> sampiyonSayilari = <String, int>{};
    final Map<String, int> netMedyan = <String, int>{};
    final Map<String, double> ciddiOran = <String, double>{};
    final Map<String, double> ortMac = <String, double>{};

    for (final CombatCircuit yol in kCombatCircuits) {
      final List<_Sporcu> l = hepsi[yol.artId]!;
      final List<_Sporcu> yarisan =
          l.where((_Sporcu k) => k.rekabeteBasladi).toList();
      final List<int> net = yarisan.map((_Sporcu k) => k.net).toList();
      final List<int> brut = yarisan.map((_Sporcu k) => k.brut).toList();
      tumNet.addAll(net);
      tumBrut.addAll(brut);

      final int elit = l.where((_Sporcu k) => k.elitOldu).length;
      final int sampiyon = l.where((_Sporcu k) => k.sampiyonOldu).length;
      final int ciddi = yarisan.where((_Sporcu k) => k.ciddiSakatlandi).length;
      sampiyonSayilari[yol.artId] = sampiyon;
      netMedyan[yol.artId] = _medyan(net);
      ciddiOran[yol.artId] =
          yarisan.isEmpty ? 0 : ciddi * 100 / yarisan.length;
      ortMac[yol.artId] =
          _ort(yarisan.map((_Sporcu k) => k.mac).toList());

      print('${yol.art!.label.padRight(15)}'
          '${elit.toString().padLeft(4)}  '
          '${sampiyon.toString().padLeft(5)}  '
          '${ortMac[yol.artId]!.toStringAsFixed(1).padLeft(7)}  '
          '${_medyan(yarisan.map((_Sporcu k) => k.kariyerYili).toList()).toString().padLeft(5)}  '
          '${ciddiOran[yol.artId]!.toStringAsFixed(0).padLeft(5)}  '
          '${_m(_medyan(brut)).padLeft(7)} '
          '${_m(_medyan(net)).padLeft(7)} '
          '${_m(_yuzdelik(net, 0.90)).padLeft(8)} '
          '${_m(_yuzdelik(net, 0.10)).padLeft(8)}');
    }

    final List<_Sporcu> tum = hepsi.values.expand((l) => l).toList();
    final List<_Sporcu> yarisanlar =
        tum.where((_Sporcu k) => k.rekabeteBasladi).toList();
    final int toplamSampiyon =
        tum.where((_Sporcu k) => k.sampiyonOldu).length;
    final int toplamElit = tum.where((_Sporcu k) => k.elitOldu).length;

    // Gider dökümü (§7).
    int ders = 0, koc = 0, musabaka = 0, kampNominal = 0, odul = 0, sponsor = 0;
    for (final _Sporcu k in yarisanlar) {
      ders += k.dersGideri;
      koc += k.kocGideri;
      musabaka += k.musabakaGideri;
      kampNominal += k.kampNominal;
      odul += k.odul;
      sponsor += k.sponsor;
    }

    print('');
    print('TOPLAM 600 sporcu:');
    print('  rekabete başlayan  ${yarisanlar.length} '
        '(%${(yarisanlar.length / 6).toStringAsFixed(1)})');
    print('  elit/pro seviye    $toplamElit '
        '(%${(toplamElit / 6).toStringAsFixed(1)})');
    print('  şampiyon olan      $toplamSampiyon '
        '(%${(toplamSampiyon / 6).toStringAsFixed(1)})');
    print('  ortalama maç       ${_ort(yarisanlar.map((k) => k.mac).toList()).toStringAsFixed(1)}');
    print('  kariyer sonu form  ${_ort(yarisanlar.map((k) => k.sonForm).toList()).toStringAsFixed(1)}');
    print('');
    print('§7 — GELİR / GİDER DÖKÜMÜ (rekabete başlayanların toplamı, ₺):');
    print('  + müsabaka ödülü   ${_m(odul)}');
    print('  + sponsorluk       ${_m(sponsor)}');
    print('  − ders ücreti      ${_m(ders)}');
    print('  − koç ücreti       ${_m(koc)}');
    print('  − kamp + tedavi    ${_m(musabaka)}  '
        '(kampın liste fiyatı ${_m(kampNominal)})');
    print('  = NET              ${_m(odul + sponsor - ders - koc - musabaka)}');
    print('');
    print('Kişi başı NET spor kariyer geliri (₺):');
    print('  en kötü %10  ${_m(_yuzdelik(tumNet, 0.10))}');
    print('  medyan       ${_m(_medyan(tumNet))}');
    print('  en iyi %10   ${_m(_yuzdelik(tumNet, 0.90))}');
    print('  en iyi       ${_m(tumNet.isEmpty ? 0 : tumNet.reduce(max))}');
    print('Kişi başı BRÜT (karşılaştırma için):');
    print('  medyan       ${_m(_medyan(tumBrut))}');
    print('  (net yıllık asgari ücret ${Economy.netYearlyMinimumWage} ₺)');
    print('');
    print('§11 — boks / taekwondo:');
    for (final String id in <String>['boks', 'taekwondo']) {
      print('  ${id.padRight(10)} şampiyon ${sampiyonSayilari[id]} / 100  '
          'net medyan ${_m(netMedyan[id] ?? 0)}  '
          'ciddi sakat %${ciddiOran[id]!.toStringAsFixed(0)}  '
          'ort.maç ${ortMac[id]!.toStringAsFixed(1)}');
    }
    print('');

    // --- İDDİALAR ---------------------------------------------------

    // §6: spor otomatik para makinesi olmasın, ama iyi sporcu kazansın.
    // Hedef band 3,5M – 5,0M (§6). Test bandı biraz geniş tutuldu:
    // regresyon yakalasın, ince ayarı dayatmasın.
    expect(_medyan(tumNet), greaterThan(2500000),
        reason: '§6: adanmış sporcunun net geliri çökmüş.');
    expect(_medyan(tumNet), lessThan(6000000),
        reason: '§6: spor otomatik zenginlik makinesine dönmüş.');

    // Rekabet gerçekten açılıyor.
    expect(yarisanlar.length, greaterThan(300),
        reason: 'Sporcuların çoğu rekabete hiç başlayamıyor.');

    // §10: şampiyonluk nadir ama imkânsız değil.
    expect(toplamSampiyon, greaterThan(6),
        reason: '§10: şampiyonluk pratikte kapatılmış.');
    expect(toplamSampiyon, lessThan(240),
        reason: '§10: adanmışların %40\'ı şampiyon oluyorsa başarı ucuz.');

    // Dağılım düz değil: iyi sporcu ayrışıyor.
    expect(_yuzdelik(tumNet, 0.90), greaterThan(_medyan(tumNet)),
        reason: 'Gelir dağılımı düz; iyi sporcu ayrışmıyor.');

    // §11: tek sanat baskın olmasın.
    final List<int> sampiyonlar = sampiyonSayilari.values.toList()..sort();
    if (sampiyonlar.last > 0) {
      expect(sampiyonlar.first, greaterThan(0),
          reason: '§11: bir sanatta hiç şampiyon çıkmıyor, yol tıkalı.');
      expect(sampiyonlar.last, lessThan(sampiyonlar.first * 8 + 10),
          reason: '§11: tek sanat şampiyonlukta baskın.');
    }

    // Absürt sonuç yok.
    for (final _Sporcu k in tum) {
      expect(k.galibiyet, greaterThanOrEqualTo(0));
      expect(k.maglubiyet, greaterThanOrEqualTo(0));
      expect(k.brut, greaterThanOrEqualTo(0));
      expect(k.brut, lessThan(Economy.netYearlyMinimumWage * 200),
          reason: 'Absürt brüt kariyer geliri: ${k.artId} ${k.brut}');
    }
  });

  // =================================================================
  // §19 — BUGLU / DÜZELTİLMİŞ karşılaştırma
  // =================================================================
  test('AN/§19 — bug fix öncesi ve sonrası aynı kohortta', () {
    final Map<String, List<_Sporcu>> buglu = _kohortA(_Mod.bugluTelafiYok);
    final Map<String, List<_Sporcu>> son = _kohortA(_Mod.duzeltilmis);

    ({int form, int mac, int net, int brut, int sampiyon, int yil}) topla(
        Map<String, List<_Sporcu>> h) {
      final List<_Sporcu> y =
          h.values.expand((l) => l).where((_Sporcu k) => k.rekabeteBasladi).toList();
      return (
        form: _ort(y.map((_Sporcu k) => k.sonForm).toList()).round(),
        mac: _ort(y.map((_Sporcu k) => k.mac).toList()).round(),
        net: _medyan(y.map((_Sporcu k) => k.net).toList()),
        brut: _medyan(y.map((_Sporcu k) => k.brut).toList()),
        sampiyon: h.values.expand((l) => l).where((_Sporcu k) => k.sampiyonOldu).length,
        yil: _ort(y.map((_Sporcu k) => k.kariyerYili).toList()).round(),
      );
    }

    final b = topla(buglu);
    final d = topla(son);
    print('');
    print('=' * 72);
    print('PAKET AN /§19 — BUGLU vs DÜZELTİLMİŞ+KALİBRE (aynı seed\'ler)');
    print('=' * 72);
    print('ölçüm                     BUGLU      DÜZELTİLMİŞ');
    print('kariyer sonu form        ${b.form.toString().padLeft(6)}   '
        '${d.form.toString().padLeft(11)}');
    print('ortalama maç             ${b.mac.toString().padLeft(6)}   '
        '${d.mac.toString().padLeft(11)}');
    print('medyan kariyer yılı      ${b.yil.toString().padLeft(6)}   '
        '${d.yil.toString().padLeft(11)}');
    print('şampiyon (600 içinde)    ${b.sampiyon.toString().padLeft(6)}   '
        '${d.sampiyon.toString().padLeft(11)}');
    print('medyan BRÜT gelir        ${_m(b.brut).padLeft(6)}   '
        '${_m(d.brut).padLeft(11)}');
    print('medyan NET gelir         ${_m(b.net).padLeft(6)}   '
        '${_m(d.net).padLeft(11)}');
    print('');
    print('NOT: §5\'teki "bug öncesi 4,04M" Paket AL kohortunun BRÜT');
    print('     ölçümüydü. Bu tablonun BUGLU brüt satırı onun karşılığı.');
    print('');

    // Düzeltme gerçekten bir şey yapıyor: form telafisi çalışıyor.
    expect(d.form, greaterThan(b.form),
        reason: 'Bug fix formu iyileştirmiyor: anahtar hatası geri gelmiş.');
    expect(d.mac, greaterThan(b.mac),
        reason: 'Form telafisi maç sayısına yansımıyor.');
    // Kalibrasyon sonrası gelir §6 bandının içinde: karşılaştırmanın
    // kendisi değil, **varış noktası** bağlayıcı.
    expect(d.net, greaterThan(3000000),
        reason: '§6: kalibrasyon spor gelirini çökertmiş.');
    expect(d.net, lessThan(5500000),
        reason: '§6: kalibrasyon sonrası gelir hâlâ çok yüksek.');
  });

  // =================================================================
  // §7 — koç harcaması: basiretli vs maksimal
  // =================================================================
  test('AN/koç — koç politikası net geliri ne kadar yiyor', () {
    // §7 net geliri istiyor; koç ücreti her yıl tekrar ödendiği için
    // net gelirin en büyük tek kalemi olabiliyor. Bu ölçüm bunu
    // görünür kılar. Kalibrasyon kararı değil, **bulgu**: elit koçun
    // parasını hak edip etmediği Q-186 #3'te Faho'da.
    ({int form, int net, int koc, int sampiyon}) topla(
        Map<String, List<_Sporcu>> h) {
      final List<_Sporcu> y = h.values
          .expand((l) => l)
          .where((_Sporcu k) => k.rekabeteBasladi)
          .toList();
      return (
        form: _ort(y.map((_Sporcu k) => k.sonForm).toList()).round(),
        net: _medyan(y.map((_Sporcu k) => k.net).toList()),
        koc: _medyan(y.map((_Sporcu k) => k.kocGideri).toList()),
        sampiyon: h.values.expand((l) => l).where((_Sporcu k) => k.sampiyonOldu).length,
      );
    }

    print('');
    print('=' * 72);
    print('PAKET AN /KOÇ — harcama politikası (600 sporcu, aynı seed\'ler)');
    print('=' * 72);
    print('politika        form   medyan koç gideri   medyan NET   şampiyon');
    final Map<_Koc, ({int form, int net, int koc, int sampiyon})> sonuc =
        <_Koc, ({int form, int net, int koc, int sampiyon})>{};
    for (final _Koc politika in _Koc.values) {
      final r = topla(_kohortA(_Mod.duzeltilmis, koc: politika));
      sonuc[politika] = r;
      print('${politika.name.padRight(13)} ${r.form.toString().padLeft(5)}   '
          '${_m(r.koc).padLeft(16)}   ${_m(r.net).padLeft(10)}   '
          '${r.sampiyon.toString().padLeft(8)}');
    }
    final yok = sonuc[_Koc.yok]!;
    final mak = sonuc[_Koc.maksimal]!;
    print('');
    print('BULGU: koç tutmak başarıyı artırıyor '
        '(şampiyon ${yok.sampiyon} → ${mak.sampiyon})');
    print('       ama net geliri DÜŞÜRÜYOR '
        '(${_m(yok.net)} → ${_m(mak.net)}). Koç kendi parasını '
        'çıkarmıyor — karar Q-186 #3\'te.');
    print('');

    // Koç kalemi gerçekten ölçülüyor (§7): sıfır değil.
    expect(mak.koc, greaterThan(0),
        reason: '§7: koç gideri ölçülemiyor; bot koç tutmuyor.');
    expect(yok.koc, 0, reason: 'Koçsuz politikada koç ücreti çıkmamalı.');
    // Koç başarıyı artırıyor: hazırlık payı ölü değil (§28).
    expect(mak.sampiyon, greaterThan(yok.sampiyon),
        reason: 'Koç hazırlığa katkı vermiyor; §28 mekaniği ölü.');
  });

  // =================================================================
  // §17/B — 150 sporcu: 0 / 2 / 4 / 8 ders
  // =================================================================
  test('AN/B — 150 sporcu: ders sayısı form telafisi', () {
    const List<int> dersler = <int>[0, 2, 4, 8];
    final Map<int, List<_Sporcu>> sonuc = <int, List<_Sporcu>>{};
    for (final int n in dersler) {
      final List<_Sporcu> liste = <_Sporcu>[];
      for (int i = 0; i < 150; i++) {
        liste.add(_hayatOyna(
          kCombatCircuits[i % kCombatCircuits.length].artId,
          310000 + i * 17,
          dersHedefi: n,
          teknikVerilsin: true,
        ));
      }
      sonuc[n] = liste;
    }

    print('');
    print('=' * 72);
    print('PAKET AN /B — DERS SAYISI (her band 150 sporcu)');
    print('=' * 72);
    print('ders/yıl  kariyer sonu form  ort.maç  medyan NET  elit  şampiyon');
    final Map<int, double> form = <int, double>{};
    for (final int n in dersler) {
      final List<_Sporcu> y =
          sonuc[n]!.where((_Sporcu k) => k.rekabeteBasladi).toList();
      form[n] = _ort(y.map((_Sporcu k) => k.sonForm).toList());
      print('${n.toString().padLeft(7)}   '
          '${form[n]!.toStringAsFixed(1).padLeft(16)}  '
          '${_ort(y.map((_Sporcu k) => k.mac).toList()).toStringAsFixed(1).padLeft(7)}  '
          '${_m(_medyan(y.map((_Sporcu k) => k.net).toList())).padLeft(10)}  '
          '${sonuc[n]!.where((_Sporcu k) => k.elitOldu).length.toString().padLeft(4)}  '
          '${sonuc[n]!.where((_Sporcu k) => k.sampiyonOldu).length.toString().padLeft(8)}');
    }
    print('');

    // §4'ün üç cümlesi, sırayla.
    //
    // (1) "aktif biçimde antrenman yapan rekabetçi sporcu formunu daha
    // iyi korusun" — monoton artış.
    expect(form[2]!, greaterThan(form[0]!),
        reason: '§4: az da olsa çalışmak hiçbir şey değiştirmiyor.');
    expect(form[4]!, greaterThan(form[2]!),
        reason: '§4: düzenli çalışan sporcu formunu daha iyi korumuyor.');
    expect(form[8]!, greaterThan(form[4]!));

    // (2) "yılda birkaç ders alarak form sürekli 100'de kilitlenmesin"
    // — telafinin tavanı var.
    expect(form[8]!, lessThan(90),
        reason: '§4: yılda 8 ders formu kilitliyor.');

    // (3) Uçurum değil rampa olsun. Ölçüm Paket AN'de bir eşik etkisi
    // gösterdi (yıllık kayıp 8; telafi onu geçene kadar form çöküyor).
    // Ders katsayısı 1,2 → 1,6 yapılarak yumuşatıldı; yılda 4 ders alan
    // sporcu artık tamamen çökmüyor.
    expect(form[4]!, greaterThan(20),
        reason: '§4: yılda 4 ders alan sporcunun formu yine çöküyor; '
            'telafi yalnızca en üst bantta çalışıyor demektir.');
  });

  // =================================================================
  // §13, §17/C — 150 sporcu: işsiz / part-time / full-time
  // =================================================================
  test('AN/C — 150 sporcu: iş yükü', () {
    final Map<_Is, List<_Sporcu>> sonuc = <_Is, List<_Sporcu>>{};
    for (final _Is is_ in _Is.values) {
      final List<_Sporcu> liste = <_Sporcu>[];
      for (int i = 0; i < 150; i++) {
        liste.add(_hayatOyna(
          kCombatCircuits[i % kCombatCircuits.length].artId,
          520000 + i * 19,
          is_: is_,
        ));
      }
      sonuc[is_] = liste;
    }

    print('');
    print('=' * 72);
    print('PAKET AN /C — İŞ YÜKÜ (her band 150 sporcu)');
    print('=' * 72);
    print('iş            kariyer sonu form  ort.maç  medyan NET  elit  şampiyon');
    final Map<_Is, double> form = <_Is, double>{};
    final Map<_Is, double> mac = <_Is, double>{};
    for (final _Is is_ in _Is.values) {
      final List<_Sporcu> y =
          sonuc[is_]!.where((_Sporcu k) => k.rekabeteBasladi).toList();
      form[is_] = _ort(y.map((_Sporcu k) => k.sonForm).toList());
      mac[is_] = _ort(y.map((_Sporcu k) => k.mac).toList());
      print('${is_.name.padRight(13)} '
          '${form[is_]!.toStringAsFixed(1).padLeft(16)}  '
          '${mac[is_]!.toStringAsFixed(1).padLeft(7)}  '
          '${_m(_medyan(y.map((_Sporcu k) => k.net).toList())).padLeft(10)}  '
          '${sonuc[is_]!.where((_Sporcu k) => k.elitOldu).length.toString().padLeft(4)}  '
          '${sonuc[is_]!.where((_Sporcu k) => k.sampiyonOldu).length.toString().padLeft(8)}');
    }
    print('');

    // §13: full-time anlamlı dezavantajlı olsun.
    expect(form[_Is.tam]!, lessThan(form[_Is.yok]!),
        reason: '§13: full-time iş formu hiç zorlaştırmıyor.');
    // ...ama kariyeri öldürmesin.
    expect(sonuc[_Is.tam]!.where((_Sporcu k) => k.elitOldu).length,
        greaterThan(0),
        reason: '§13: full-time çalışan hiç elit olamıyorsa iş kariyeri '
            'öldürüyor.');
    expect(mac[_Is.tam]!, greaterThan(mac[_Is.yok]! * 0.5),
        reason: '§13: full-time iş maç sayısını yarıdan fazla kesiyor.');
    // SportWorkload gerçekten devrede.
    expect(SportWorkload.prototypeOnlyOpportunityFactor[SportWorkLoad.tamZamanli]!,
        lessThan(1.0));
  });
}

// Paket AP §76 — 500 aile odaklı hayat. ÖLÇÜM; oran güzelleştirmesi yok.
//
// Brief açıkça "GENEL 3000 YOK, 500 family-focused life" ve "ORANLARI
// GÜZELLEŞTİRME. SADECE ÖLÇ." dedi. Bu dosya o yüzden **rapor** yazıyor;
// eşikler yalnızca bozulmayı yakalayacak kadar gevşek:
//
//   * para yoktan üretilmesin,
//   * oyunun kendi değişmezleri kırılmasın,
//   * bir yılda birden fazla büyük aile kararı açılmasın,
//   * kayıt sınırsız büyümesin.
//
// Dağılımın "güzel" olup olmadığına Faho ve ChatGPT karar verir; rapor
// Q-188'e gider.
// ignore_for_file: avoid_print
library;

import 'dart:math';

import 'package:bir_omur/domain/family/family_decision.dart';
import 'package:bir_omur/domain/generation/life_generator.dart';
import 'package:bir_omur/domain/generation/life_progression.dart';
import 'package:bir_omur/domain/models/family_issue.dart';
import 'package:bir_omur/domain/models/game_state.dart';
import 'package:bir_omur/domain/models/gender.dart';
import 'package:bir_omur/domain/models/person.dart';
import 'package:bir_omur/domain/models/person_development.dart';
import 'package:bir_omur/domain/models/relation.dart';
import 'package:bir_omur/domain/models/stats.dart';
import 'package:bir_omur/domain/models/wealth.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/invariants.dart';

const Stats _ortaStats = Stats(
  appearance: 55,
  happiness: 60,
  health: 72,
  intelligence: 60,
  charisma: 55,
);

/// prototypeOnly: ölçülen hayat sayısı (§76).
const int kOlcumHayati = 500;

/// Oyuncunun cüzdanı + kayıtlı herkesin birikimi.
int _toplamPara(GameState s) {
  int toplam = s.player.wallet;
  for (final Person p in s.people) {
    toplam += p.development?.money ?? 0;
  }
  return toplam;
}

/// Aile odaklı bir başlangıç: iki çocuk ve bir kardeş.
///
/// Rastgele hayat çoğu zaman hiç çocuk üretmiyor; aile sistemlerini
/// ölçmek için aile **kurulu** başlıyor. Bu bir ürün kuralı değil,
/// ölçüm düzeneği.
GameState _aileOdakliHayat(int seed) {
  final GameState base =
      LifeGenerator.seeded(seed).generate(mode: StartMode.tamamenRastgele);
  final Random rng = Random(seed);
  final List<Person> kisiler = <Person>[...base.people];

  for (int i = 0; i < 2; i++) {
    kisiler.add(
      Person(
        id: 'olcum-cocuk-$i',
        firstName: i == 0 ? 'Deniz' : 'Ada',
        lastName: base.player.lastName,
        gender: i == 0 ? Gender.kadin : Gender.erkek,
        relation: RelationType.cocuk,
        age: 8 + i * 3,
        isAlive: true,
        inPlayerHousehold: true,
        employment: EmploymentStatus.ogrenci,
        wealth: null,
        bond: 40 + rng.nextInt(50),
        city: base.player.currentCity,
        motherId: base.player.id,
        development: PersonDevelopment(
          tracksLife: true,
          grade: 3 + i * 3,
          stats: Stats(
            appearance: 40 + rng.nextInt(40),
            happiness: 25 + rng.nextInt(60),
            health: 50 + rng.nextInt(40),
            intelligence: 25 + rng.nextInt(60),
            charisma: 40 + rng.nextInt(40),
          ),
        ),
      ),
    );
  }
  kisiler.add(
    Person(
      id: 'olcum-kardes',
      firstName: 'Kerem',
      lastName: base.player.lastName,
      gender: Gender.erkek,
      relation: RelationType.kardes,
      age: base.player.age + 2,
      isAlive: true,
      inPlayerHousehold: false,
      employment: EmploymentStatus.issiz,
      wealth: WealthTier.yoksul,
      bond: 30 + rng.nextInt(60),
      city: base.player.currentCity,
      development: const PersonDevelopment(
        tracksLife: true,
        finishedSchool: true,
        money: 20000,
        stats: _ortaStats,
      ),
    ),
  );

  return base.copyWith(
    player: base.player.copyWith(age: 35, wallet: 800000),
    people: List<Person>.unmodifiable(kisiler),
  );
}

void main() {
  test('ÖLÇÜM: $kOlcumHayati aile odaklı hayat (§76)', () {
    final List<String> sorunlar = <String>[];
    final Map<String, int> turSayaci = <String, int>{};
    final Map<String, int> cevapSayaci = <String, int>{};
    final List<int> hayatBasiKarar = <int>[];
    final List<int> hayatBasiMesele = <int>[];
    int paraUretimi = 0;
    int ikiliKarar = 0;
    int toplamYil = 0;
    int kayitTasmasi = 0;
    int ikiEbeveynliTorun = 0;
    int tekEbeveynliTorun = 0;
    int cocugunEsi = 0;
    int cocukBosanmasi = 0;
    int cocukYenidenEvlilik = 0;
    int cocukDullugu = 0;
    int kuslukSayisi = 0;

    // Üç farklı oyuncu tutumu: hep destek, hep karışmama, dönüşümlü.
    // Böylece ölçüm tek bir oynama tarzına bağlı kalmıyor.
    const List<FamilyIssueResponse> hepDestek = <FamilyIssueResponse>[
      FamilyIssueResponse.destekOldu,
    ];
    const List<FamilyIssueResponse> hepKarisma = <FamilyIssueResponse>[
      FamilyIssueResponse.karismadi,
    ];
    const List<FamilyIssueResponse> donusumlu = <FamilyIssueResponse>[
      FamilyIssueResponse.destekOldu,
      FamilyIssueResponse.paraVerdi,
      FamilyIssueResponse.konustu,
      FamilyIssueResponse.reddetti,
    ];

    for (int seed = 0; seed < kOlcumHayati; seed++) {
      final List<FamilyIssueResponse> tutum = switch (seed % 3) {
        0 => hepDestek,
        1 => hepKarisma,
        _ => donusumlu,
      };
      GameState s = _aileOdakliHayat(seed);
      final LifeProgression motor = LifeProgression(Random(seed + 7));
      int kararSayisi = 0;
      int tutumIndex = 0;

      while (!s.deceased && s.player.age < 92) {
        final int yasOnce = s.player.age;

        s = s.copyWith(pendingEvent: null, pendingCrisis: null);
        s = motor.advanceOneYear(s);
        if (s.player.age == yasOnce) break;
        toplamYil++;

        // §3: bir yılda en fazla bir büyük aile kararı açılmalı.
        final int oYilAcilan = s.familyIssues
            .where((FamilyIssue m) => m.openedAtAge == s.player.age)
            .length;
        if (oYilAcilan > 1) {
          ikiliKarar++;
          if (sorunlar.length < 10) {
            sorunlar.add('tohum $seed yaş ${s.player.age}: '
                '$oYilAcilan aile meselesi aynı yıl açıldı');
          }
        }

        // Bekleyen kararı cevapla.
        final FamilyDecision? karar = FamilyDecisions.pending(s);
        if (karar != null) {
          kararSayisi++;
          turSayaci.update(karar.kind.name, (int v) => v + 1,
              ifAbsent: () => 1);
          // Tutuma uygun ve **izinli** ilk seçeneği seç.
          final FamilyIssueResponse istenen =
              tutum[tutumIndex++ % tutum.length];
          final FamilyDecisionOption secenek = karar.options.firstWhere(
            (FamilyDecisionOption o) => o.response == istenen && o.isAllowed,
            orElse: () => karar.options.firstWhere(
              (FamilyDecisionOption o) => o.isAllowed,
              orElse: () => karar.options.first,
            ),
          );
          if (secenek.isAllowed) {
            cevapSayaci.update(secenek.response.name, (int v) => v + 1,
                ifAbsent: () => 1);
            // §70 — PARA YOKTAN ÜRETİLMESİN.
            //
            // Ölçüm **yalnızca kararın kendisini** sarıyor, bütün yılı
            // değil. İlk yazımda yıl başı/sonu toplamı karşılaştırılıyordu
            // ve 500 hayatta dokuz kez tripliyordu; sebebini ölçtüm:
            // ihlal değil, muhasebe hatasıydı. Miras, vefat eden kişinin
            // kaydındaki parayı **silmiyor** (geçmiş kaybolmasın diye) ve
            // kaydı olmayan kişinin mirası ekonomik durumundan tahmin
            // ediliyor; ayrıca yıllık ilerleme maaş, kira ve işletme
            // geliri işliyor. Yani yıl toplamının artması normal.
            //
            // Aile kararının kendisi için kural kesin: para **taşınır**,
            // üretilmez. Transferde toplam aynı kalır, masraflı
            // kararlarda (özel ders, bakım) azalır — asla artmaz.
            final int kararOncesi = _toplamPara(s);
            s = FamilyDecisions.answer(s, secenek.response, Random(seed + 3))
                .state;
            final int kararSonrasi = _toplamPara(s);
            if (kararSonrasi > kararOncesi) {
              paraUretimi++;
              if (sorunlar.length < 10) {
                sorunlar.add('tohum $seed yaş ${s.player.age}: '
                    '${karar.kind.name}/${secenek.response.name} '
                    'toplam parayı $kararOncesi -> $kararSonrasi yaptı');
              }
            }
          }
        }

        if (s.familyIssues.length > GameState.prototypeOnlyMaxIssues) {
          kayitTasmasi++;
        }

        // Oyunun kendi değişmezleri.
        if (sorunlar.length < 10) {
          sorunlar.addAll(
            checkInvariants(s, where: 'tohum $seed yaş ${s.player.age}'),
          );
        }
      }

      hayatBasiKarar.add(kararSayisi);
      hayatBasiMesele.add(s.familyIssues.length);

      // Hayat sonunda aile tablosu.
      for (final Person p in s.people) {
        if (p.relation == RelationType.cocugunEsi ||
            p.relation == RelationType.eskiCocugunEsi) {
          cocugunEsi++;
        }
        if (p.relation == RelationType.torun) {
          final int ebeveynSayisi =
              (p.motherId == null ? 0 : 1) + (p.fatherId == null ? 0 : 1);
          if (ebeveynSayisi >= 2) {
            ikiEbeveynliTorun++;
          } else {
            tekEbeveynliTorun++;
          }
        }
        if (p.isEstranged) kuslukSayisi++;
        final PersonDevelopment? d = p.development;
        if (d == null) continue;
        if (d.isDivorced) cocukBosanmasi++;
        if (d.isWidowed) cocukDullugu++;
        if (d.pastMarriages.isNotEmpty && d.isMarried) {
          cocukYenidenEvlilik++;
        }
      }
    }

    hayatBasiKarar.sort();
    hayatBasiMesele.sort();
    int yuzde(List<int> liste, int p) =>
        liste.isEmpty ? 0 : liste[(liste.length * p ~/ 100).clamp(0, liste.length - 1)];
    final int sakin = hayatBasiKarar.where((int v) => v == 0).length;
    final int yogun = hayatBasiKarar.where((int v) => v >= 6).length;

    print('');
    print('=== PAKET AP §76 — $kOlcumHayati AILE ODAKLI HAYAT ===');
    print('toplam yil: $toplamYil');
    print('');
    print('-- aile karari / hayat --');
    print('  medyan: ${yuzde(hayatBasiKarar, 50)}  '
        'p25: ${yuzde(hayatBasiKarar, 25)}  '
        'p75: ${yuzde(hayatBasiKarar, 75)}  '
        'p95: ${yuzde(hayatBasiKarar, 95)}  '
        'en yuksek: ${hayatBasiKarar.isEmpty ? 0 : hayatBasiKarar.last}');
    print('  hic karar cikmayan hayat: $sakin / $kOlcumHayati');
    print('  alti ve ustu karar cikan hayat: $yogun / $kOlcumHayati');
    print('');
    print('-- mesele turleri (acilan) --');
    final List<String> turler = turSayaci.keys.toList()..sort();
    for (final String t in turler) {
      print('  $t: ${turSayaci[t]}');
    }
    print('');
    print('-- oyuncunun verdigi cevaplar --');
    final List<String> cevaplar = cevapSayaci.keys.toList()..sort();
    for (final String c in cevaplar) {
      print('  $c: ${cevapSayaci[c]}');
    }
    print('');
    print('-- hayat sonu aile tablosu --');
    print('  kayitta gelin/damat (eski dahil): $cocugunEsi');
    print('  bosanmis cocuk kaydi: $cocukBosanmasi');
    print('  dul cocuk kaydi: $cocukDullugu');
    print('  yeniden evlenmis cocuk kaydi: $cocukYenidenEvlilik');
    print('  kus kisi: $kuslukSayisi');
    print('  iki ebeveynli torun: $ikiEbeveynliTorun');
    print('  tek ebeveynli torun: $tekEbeveynliTorun');
    print('  mesele kaydi / hayat medyan: ${yuzde(hayatBasiMesele, 50)}  '
        'en yuksek: ${hayatBasiMesele.isEmpty ? 0 : hayatBasiMesele.last}');
    print('');
    print('-- bozulma sayaclari (hepsi 0 olmali) --');
    print('  ayni yil birden fazla karar: $ikiliKarar');
    print('  aile karari para uretti: $paraUretimi');
    print('  mesele kaydi tasmasi: $kayitTasmasi');
    print('=== RAPOR SONU ===');
    print('');

    // Ölçüm gerçekten hayat oynamalı: boşa dönen bir rapor olmasın.
    expect(toplamYil, greaterThan(10000),
        reason: 'Simülasyon yeterince hayat oynamadı.');
    expect(turSayaci.keys, isNotEmpty,
        reason: 'Hiç aile meselesi açılmadı; ölçüm anlamsız olurdu.');

    // Gevşek ama gerçek koruma eşikleri.
    expect(ikiliKarar, 0, reason: '§3 kırıldı.');
    expect(paraUretimi, 0, reason: '§70: para yoktan üretildi.');
    expect(kayitTasmasi, 0, reason: 'Kayıt sınırı aşıldı.');
    expect(sorunlar, isEmpty, reason: sorunlar.join('\n'));
  }, timeout: const Timeout(Duration(minutes: 20)));
}

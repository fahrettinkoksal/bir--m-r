// Paket CP — **kapsam botunun dokunmadığı kapılar.**
//
// **Ölçülen eksik.** Paket AI'nın aksiyon envanteri koddan üretiliyor
// (`support/action_inventory.dart`) ve kapsam ölçümü 400 hedefli
// hayatta şunu söylüyordu: 138 oyuncu aksiyonunun **103'ü** çalışıyor,
// 1'i denenip hiç uygulanmıyor, **34'ü hiç denenmiyor** (%74,6).
// Otuz dördün **29'u bu botta hiç bağlı değildi**: aileden gelen bütün
// kararlar (kardeş parası, çocuğun eve dönüşü, kayın çatışması, bakım
// ve miras anlaşmazlığı, çocuğun okul meselesi), yaşlı ebeveyne bakım,
// Paket CJ'nin yaşlılıkta bakım kararı, okul kulübü, arkadaş grubuyla
// buluşma, dövüşte müsabaka yolu, çocuk planı ve Ayarlar'daki modül
// anahtarları. Oyuncunun ekranında kart olarak duran bu kapılara
// hiçbir araç dokunmuyordu — Paket BD'nin "duruşma penceresi çöküyor"
// hatası ve Paket CB'nin ulaşılamayan basamağı tam bu boşlukta
// durmuştu.
//
// **Botu öğretince iki araç hatası çıktı** (ikisi de oyunun değil
// ölçümün hatası, ama ikisi de ölçümü yalan söyletiyordu):
//
// 1. `endLifeByChoice` **ters ölçülüyordu.** Başarıda `''`, engelde
//    gerekçeyi döndürüyor; bot ise "boş değilse oldu" sayıyordu. Yani
//    aksiyonun başarısı "kapsanmadı", başarısızlığı "kapsandı"
//    sayılıyordu. Kapı 95 yaşında olduğu ve kapsam hayatlarında 95'e
//    hiç ulaşılmadığı için hata yıllarca görünmemişti.
// 2. **Grup buluşması olmayacak eylemle deneniyordu.** Buluşma için
//    "açık olan ilk eylem" seçiliyordu; o çoğu zaman tek başına
//    yapılan bir eylemdi ve `Outing.supports` yüzünden her çağrı
//    düşüyordu: **25.038 deneme, sıfır buluşma.** Bu, "oyunda grup
//    buluşması çalışmıyor" gibi görünen yanlış bir bulguydu. Doğru
//    eylem seçilince aynı turda 1.367 buluşma oldu.
//
// Ayrıca iki aksiyon koşulsuz çağrılıyordu ve 50 binden fazla boş
// deneme üretiyordu (`pushThroughCombatInjury` 23.802,
// `resolveSchoolSportConflict` 29.837); ikisi de kendi kapısına
// bağlandı.
//
// **Sonuç (400 hedefli hayat):** kapsam %74,6 → **%89,9**
// (103 → 124 aksiyon). Hafif turda (60 hayat) %87,7.
//
// **Kalan boşluk ve sebebi** (hiçbiri "bot bağlamadı" değil artık):
// çete teklifi ve kefalet yolları (kapsam hayatlarında kimse
// tutuklanmıyor), `retireFromFootball` (profesyonel futbol kariyeri
// oluşmuyor), `askFamilyForCourse` (ücretli kurs + yetersiz cüzdan +
// ödeyecek ebeveyn üçü bir araya gelmiyor), `askFamilyForBedelli`
// (askerlik meselesi kapanmış oluyor), aile anlaşmazlıklarının bir
// kısmı (400 hayatta 1-10 kez çıkan seyrek olaylar; Paket CK'nın
// dersi: "görülmedi" ulaşılamazlık değildir).
library;

import 'dart:math';

import 'package:bir_omur/data/activity_catalog.dart';
import 'package:bir_omur/domain/activities/outing.dart';
import 'package:bir_omur/domain/generation/life_generator.dart';
import 'package:bir_omur/domain/life/life_end_choice.dart';
import 'package:bir_omur/state/game_controller.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/action_inventory.dart';
import 'support/coverage_bot.dart';

/// Paket CP'de bağlanan ve **30 hayatlık turda gerçekten uygulanan**
/// aksiyonlar.
///
/// Ölçülen uygulama sayıları (3 hayat × 10 plan): aile kararı 118 ·
/// boşanmada hane 2 · yaşlılıkta bakım 65 · yaşlı ebeveyne bakım 82 ·
/// çocuğa tavsiye 215 · kardeşten borç 337 · çocuk planı 1219 ·
/// çocuk denemesi 1242 · kulübe giriş 90 · kulüpte çalışma 318 ·
/// kulüpten ayrılma 10 · grup kurma 56 · grupla buluşma 1367 ·
/// müsabakaya başlama 48 · antrenör 4 · dövüşü bırakma 44 · modül
/// anahtarı 1 · anahtarları sıfırlama 1.
const List<String> kPaketCpAksiyonlari = <String>[
  'answerFamilyDecision',
  'chooseDivorceHousehold',
  'decideElderSupport',
  'decideElderCare',
  'adviseChild',
  'borrowFromSibling',
  'setFamilyPlan',
  'tryForChild',
  'joinClub',
  'trainClub',
  'leaveClub',
  'formFriendCircle',
  'meetFriendCircle',
  'startCompeting',
  'setCombatCoach',
  'retireFromCombat',
  'setFeature',
  'resetFeatures',
];

void main() {
  test('bağlanan aksiyonlar 30 hayatlık turda gerçekten uygulanıyor', () {
    final ActionLog toplam = ActionLog();
    for (final CoveragePlan plan in CoveragePlan.values) {
      for (int i = 0; i < 3; i++) {
        toplam.merge(runCoverageLife(
          plan: plan,
          seed: 5100000 + plan.index * 7717 + i * 31,
        ).log);
      }
    }
    final List<String> eksik = <String>[
      for (final String a in kPaketCpAksiyonlari)
        if ((toplam.records[a]?.applied ?? 0) == 0) a,
    ];
    expect(eksik, isEmpty,
        reason: 'Bu aksiyonlar kapsam turunda hiç uygulanmadı: $eksik — '
            'bağlantı kaldırıldıysa oyuncunun o kapısı yine ölçüm '
            'dışında kalır (Paket CP)');
  }, timeout: const Timeout(Duration(minutes: 15)));

  test('endLifeByChoice başarıda boş metin döner, engelde gerekçe', () {
    // Bu sözleşme **ölçüm aracının** dayandığı şey: bot "boş değilse
    // oldu" sayınca aksiyonun başarısı kapsam dışı kalıyordu.
    final GameController c = GameController(random: Random(11));
    addTearDown(c.dispose);
    c.startNewLife(mode: StartMode.tamamenRastgele, seed: 11);
    // Çocukken kapı kapalı: gerekçe döner, hayat **bitmez**.
    expect(c.state!.player.age, lessThan(LifeEndChoice.prototypeOnlyMinAge));
    final String engel = c.endLifeByChoice();
    expect(engel, isNotEmpty,
        reason: 'kapalı kapı gerekçesiz dönemez (D-038)');
    expect(c.state!.deceased, isFalse);

    // Yetişkinde kapı açık: boş metin döner ve hayat tamamlanır.
    while (c.state!.player.age < LifeEndChoice.prototypeOnlyMinAge &&
        !c.state!.deceased) {
      c.ageUp();
      if (c.state!.hasPendingEvent || c.state!.hasPendingCrisis) break;
    }
    if (c.state!.player.age >= LifeEndChoice.prototypeOnlyMinAge &&
        !c.state!.deceased) {
      final String sonuc = c.endLifeByChoice();
      expect(sonuc, isEmpty,
          reason: 'başarı boş metinle bildiriliyor; ölçüm aracı bunu '
              'tersine okuyordu (Paket CP)');
      expect(c.state!.deceased, isTrue);
    }
  });

  test('grup buluşması birlikte yapılabilen eylem ister', () {
    // Botun 25.038 boş denemesinin sebebi: tek başına yapılan bir
    // eylemle buluşmaya çalışmak. Kural oyunun kendi kuralı.
    final ActivityAction? yalniz = kActivityActions
        .where((ActivityAction a) => !Outing.supports(a))
        .firstOrNull;
    expect(yalniz, isNotNull,
        reason: 'katalogda tek başına yapılan eylem kalmadıysa bu '
            'bekçinin dayanağı da kalmaz');

    final GameController c = GameController(random: Random(5));
    addTearDown(c.dispose);
    c.startNewLife(mode: StartMode.tamamenRastgele, seed: 5);
    // Grup olsa bile tek başına yapılan eylemle buluşma olmaz.
    expect(c.meetFriendCircle(yalniz!), isNull,
        reason: 'birlikte yapılmayan eylemle grup buluşması dönmemeli');
  });
}

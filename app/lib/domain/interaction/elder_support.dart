/// Oyuncunun kendi yaşlılığı: **kim yanında?** (Paket CJ)
///
/// **Ölçülen eksik.** `ElderCare` (Paket AO §35-§36) oyuncunun yaşlı
/// ebeveynine bakmasını modelliyor. Tersi yoktu: oyuncu yaşlandığında
/// hiçbir aile üyesi hiçbir şey yapmıyordu. 250 bot hayatı tarandı —
/// 1356 yaşlılık yılı (70+), bunların 585'i düşük sağlık bandında ve
/// günlükte oyuncuya dönük **tek** bakım satırı bile yok.
///
/// **Yeni mekanik kurulmuyor.** Para, yakınlık, mutluluk ve hayat
/// günlüğü zaten var; burada yapılan şey bu yılı kimin omuzladığını
/// kayda geçirmek. Üç kapı var ve üçü de **gerçekten** iş görüyor.
///
/// **Bağ eşiği taşıyıcı değildir.** Ölçümde yaşlılıkta en iyi çocuk
/// bağının ortancası **100** çıktı (min 48): bugünkü oyunda bağ
/// ayırt edici bir ölçü değil (Q-205 bunu zaten soruyor). Bu yüzden
/// kapı bağa göre açılmıyor; ayırt eden şey **kimin var olduğu**
/// (ölçüm: yaşlılık yıllarının %53'ünde ne eş ne yetişkin çocuk var)
/// ve maddi destekte **kimin gücünün yettiği**. Bağ yalnızca çok
/// düşükse (oyuncu gerçekten uzaklaştırmışsa) kapıyı kapatır.
///
/// **Havadan para üretilmez (§36'nın kuralı).** Maddi destek çocuğun
/// kendi [WealthTier] kaydından çıkar; geçimi zor olan çocuk destek
/// vermez ve toplam, o yılın bakım masrafını aşmaz.
///
/// **Şehir kapı değildir.** `GameState.isReachable` eş ve çocuk için
/// şehir koşulu uygulamıyor ("evden ayrılsalar da görüşülmeye devam
/// eder"); burada ondan farklı bir kural yazılmaz.
///
/// Bütün sayılar `prototypeOnly`'dir (Q-228).
library;

import 'dart:math';

import '../../data/economy.dart';
import '../features/feature_catalog.dart';
import '../life/critical_health.dart';
import '../models/elder_support.dart';
import '../models/game_state.dart';
import '../models/life_log.dart';
import '../models/person.dart';
import '../models/relation.dart';
import '../models/wealth.dart';

/// Oyuncunun yaşlılıkta verebileceği karar.
enum ElderSupportChoice {
  /// Ailene yüklen: yanında olurlar, yük onların üstünde.
  aileyeYuklen('Ailene yüklen'),

  /// Bakım masrafını karşıla: para cepten çıkar, gücü yeten çocuklar
  /// faturanın bir kısmını üstlenir.
  bakimiOdet('Bakım masrafını karşıla'),

  /// Kendin idare et: kimseye yüklenmezsin.
  kendiIdareEt('Kendin idare et');

  const ElderSupportChoice(this.label);

  /// Ekranda görünen ad.
  final String label;
}

/// Bir yaşlılık kararının sonucu.
typedef ElderSupportResult = ({GameState state, String text, int received});

abstract final class ElderSupport {
  /// prototypeOnly: bakım ihtiyacının doğduğu en küçük oyuncu yaşı.
  static const int prototypeOnlyMinAge = 70;

  /// prototypeOnly: sağlık iyi olsa da bakım ihtiyacının doğduğu yaş.
  ///
  /// `ElderCare`'in ebeveyn tarafındaki kuralının aynısı: yaş **veya**
  /// sağlık. Sapasağlam bir seksenlik de bu yılı tek başına çevirmek
  /// zorunda olmamalı.
  static const int prototypeOnlyFrailAge = 80;

  /// prototypeOnly: yanında olabilecek çocuğun en küçük yaşı.
  static const int prototypeOnlyMinChildAge = 25;

  /// prototypeOnly: kapıyı kapatan **çok düşük** bağ eşiği.
  ///
  /// Ayırt edici bir ölçü değil, bir taban: oyuncunun gerçekten
  /// uzaklaştırdığı kişi yanında olmaz.
  static const int prototypeOnlyMinBond = 25;

  /// prototypeOnly: bir yıllık bakım masrafının asgari ücrete oranı.
  ///
  /// `ElderCare`'in ebeveyn tarafındaki payı 0,35; oyuncunun kendi
  /// hanesinde yaşadığı için pay biraz düşük tutuldu.
  static const double prototypeOnlyYearlyCostShare = 0.30;

  /// prototypeOnly: ailenin yanında olduğu yılın mutluluk etkisi.
  static const int prototypeOnlyCompanyHappiness = 7;

  /// prototypeOnly: yanında olan kişinin yakınlık kazancı.
  static const int prototypeOnlyCompanyBond = 5;

  /// prototypeOnly: yükü omuzlayan kişinin mutluluk bedeli.
  ///
  /// `ElderCare.yanindaKal` oyuncuya −6 mutluluk yazıyor; bakım
  /// gerçekten yorar. Tersi de bedava değildir.
  static const int prototypeOnlyHelperHappiness = -4;

  /// prototypeOnly: bakımını satın alan oyuncunun mutluluk kazancı.
  ///
  /// Ailenin yanında olmasından küçük: para bakımı alır, yılın
  /// yalnızlığını almaz.
  static const int prototypeOnlyPaidHappiness = 3;

  /// prototypeOnly: faturanın bir kısmını üstlenen çocuğun yakınlık
  /// kazancı.
  static const int prototypeOnlyShareBond = 2;

  /// prototypeOnly: çocukların faturadan üstlenebileceği **en çok** pay.
  ///
  /// Ölçümde iki üç varlıklı çocuk kapağı (faturanın tamamı) hemen
  /// dolduruyordu: 285 yılın ortancası faturanın %100'üydü, yani
  /// oyuncunun cebinden hiç para çıkmıyordu. Bakımı tamamen çocuklara
  /// fatura etmek "para gerçekten cepten çıkar" kuralını (ECO-001)
  /// boşa düşürüyor; pay burada sınırlandı.
  static const double prototypeOnlyMaxChildShare = 0.6;

  /// Modül açık mı? (Paket BL — fail-closed.)
  static bool isOn(GameState state) =>
      state.settings.features.isOn(FeatureId.yaslilikBakimi);

  /// Bu yılın bakım masrafı.
  static int yearlyCost() =>
      (Economy.netYearlyMinimumWage * prototypeOnlyYearlyCostShare).round();

  /// Oyuncunun bu yıl bakıma ihtiyacı var mı?
  ///
  /// Koşul gerçek: yaş **ve** sağlık birlikte bakılır, çok yaşlıda yaş
  /// tek başına yeter. Cezaevinde bu karar verilemez (Paket CG'nin
  /// kuralı: içeriden yürümeyen kapı açık gösterilmez).
  static bool needsSupport(GameState state) {
    if (!isOn(state)) return false;
    if (state.deceased) return false;
    if (state.isImprisoned) return false;
    if (state.player.age < prototypeOnlyMinAge) return false;
    return CriticalHealth.bandFor(state).isLow ||
        state.player.age >= prototypeOnlyFrailAge;
  }

  /// Bu yıl karar verildi mi? (Aynı yıl iki kez karar alınmaz.)
  static bool decidedThisYear(GameState state) =>
      state.elderSupport.lastDecidedAge == state.player.age;

  /// Yanında olabilecek kişiler: eş ve yetişkin çocuklar.
  ///
  /// Sıra rastgele değil: eş ilk sırada, sonra en yakın çocuk. Oyuncu
  /// listeden seçebilir; seçmezse ilk sıradaki omuzlar.
  static List<Person> helpers(GameState state) {
    if (!needsSupport(state)) return const <Person>[];
    final List<Person> es = state.people
        .where((Person p) =>
            p.isAlive &&
            p.relation == RelationType.es &&
            !p.isEstranged &&
            p.bond >= prototypeOnlyMinBond)
        .toList(growable: false);
    final List<Person> cocuklar = state.people
        .where((Person p) =>
            p.isAlive &&
            p.relation == RelationType.cocuk &&
            p.age >= prototypeOnlyMinChildAge &&
            !p.isEstranged &&
            p.bond >= prototypeOnlyMinBond)
        .toList(growable: true)
      ..sort((Person a, Person b) => b.bond.compareTo(a.bond));
    return List<Person>.unmodifiable(<Person>[...es, ...cocuklar]);
  }

  /// §36'nın kuralı: gücü yeten çocukların bu yılki katkısı.
  ///
  /// **Havadan para üretilmez.** Katkı çocuğun kendi ekonomik
  /// kaydından çıkar; kaydı olmayan ya da geçimi zor olan çocuk katkı
  /// vermez. Toplam, faturanın [prototypeOnlyMaxChildShare] payını
  /// aşmaz — kalanı her hâlde oyuncunun cebinden çıkar.
  static ({int amount, List<String> names, List<String> ids}) contribution(
    GameState state,
  ) {
    final int masraf = yearlyCost();
    int toplam = 0;
    final List<String> adlar = <String>[];
    final List<String> idler = <String>[];
    for (final Person c in state.people) {
      if (!c.isAlive ||
          c.relation != RelationType.cocuk ||
          c.age < prototypeOnlyMinChildAge ||
          c.isEstranged ||
          c.wealth == null) {
        continue;
      }
      final double pay = switch (c.wealth!) {
        // Kendi geçimi zor olan çocuk destek veremez; bu bir kusur
        // değil.
        WealthTier.cokYoksul => 0.0,
        WealthTier.yoksul => 0.0,
        WealthTier.ortaHalli => 0.20,
        WealthTier.varlikli => 0.35,
        WealthTier.cokVarlikli => 0.50,
      };
      if (pay <= 0) continue;
      toplam += (masraf * pay).round();
      adlar.add(c.firstName);
      idler.add(c.id);
    }
    final int tavan = (masraf * prototypeOnlyMaxChildShare).round();
    if (toplam > tavan) toplam = tavan;
    return (
      amount: toplam,
      names: List<String>.unmodifiable(adlar),
      ids: List<String>.unmodifiable(idler),
    );
  }

  /// Oyuncunun cebinden çıkacak kısım: masraf eksi çocukların payı.
  static int outOfPocket(GameState state) {
    final int masraf = yearlyCost();
    final int katki = contribution(state).amount;
    return (masraf - katki).clamp(0, masraf);
  }

  /// Bu kapı neden kapalı? Boş metin "açık" demektir (D-038: çalışmayan
  /// kapı gizlenir, gerekçesi yazılı kapı gösterilir).
  static String blockReason(GameState state, ElderSupportChoice choice) {
    if (!needsSupport(state)) {
      if (state.isImprisoned) {
        return 'Cezaevindesin; bu işi buradan çeviremezsin.';
      }
      return 'Şimdilik bu yılı kendi başına çevirebiliyorsun.';
    }
    if (decidedThisYear(state)) {
      return 'Bu yılın kararını verdin.';
    }
    switch (choice) {
      case ElderSupportChoice.aileyeYuklen:
        return helpers(state).isEmpty
            ? 'Yanında olabilecek kimse yok.'
            : '';
      case ElderSupportChoice.bakimiOdet:
        // ElderCare'in cümlesinin aynısı: karşılanamayan kapı "olmuş
        // gibi" gösterilmez, cüzdan eksiye düşmez.
        return state.player.wallet < outOfPocket(state)
            ? 'Bu yıl bakım masrafını karşılayacak paran yok.'
            : '';
      case ElderSupportChoice.kendiIdareEt:
        return '';
    }
  }

  /// Kararı uygular.
  ///
  /// Karşılanamayan bir kapı **olmuş gibi** gösterilmez: engel varsa
  /// durum aynen döner ve gerekçe yazılır.
  static ElderSupportResult apply({
    required GameState state,
    required ElderSupportChoice choice,
    required Random rng,
    String? helperId,
  }) {
    final String engel = blockReason(state, choice);
    if (engel.isNotEmpty) {
      return (state: state, text: engel, received: 0);
    }

    final int yas = state.player.age;
    ElderSupportState kayit = state.elderSupport;
    List<Person> kisiler = state.people;
    int cuzdan = state.player.wallet;
    int mutluluk = 0;
    int gelen = 0;
    String metin;
    String? yardimci;

    switch (choice) {
      case ElderSupportChoice.aileyeYuklen:
        final List<Person> adaylar = helpers(state);
        final Person kisi = adaylar.firstWhere(
          (Person p) => p.id == helperId,
          orElse: () => adaylar.first,
        );
        yardimci = kisi.id;
        // Küçük bir değişkenlik: aynı karar her yıl birebir aynı
        // hissi vermez (ElderCare'in deseni).
        final int bagDelta =
            prototypeOnlyCompanyBond + rng.nextInt(3) - 1;
        mutluluk = prototypeOnlyCompanyHappiness;
        kisiler = state.people
            .map((Person p) => p.id == kisi.id
                ? p.copyWith(
                    bond: (p.bond + bagDelta).clamp(0, 100),
                    happiness: (p.happiness + prototypeOnlyHelperHappiness)
                        .clamp(0, 100),
                  )
                : p)
            .toList(growable: false);
        kayit = kayit.copyWith(
          yearsSupported: kayit.yearsSupported + 1,
          lastHelperId: kisi.id,
        );
        metin = '${kisi.firstName} bu yıl yanında oldu.';

      case ElderSupportChoice.bakimiOdet:
        final ({int amount, List<String> names, List<String> ids}) katki =
            contribution(state);
        gelen = katki.amount;
        final int cepten = outOfPocket(state);
        cuzdan -= cepten;
        mutluluk = prototypeOnlyPaidHappiness;
        kisiler = state.people
            .map((Person p) => katki.ids.contains(p.id)
                ? p.copyWith(
                    bond: (p.bond + prototypeOnlyShareBond).clamp(0, 100),
                  )
                : p)
            .toList(growable: false);
        kayit = kayit.copyWith(
          // Faturayı aile paylaştıysa bu yıl da "destek görülen" yıldır;
          // tek başına ödenen yıl sayaca girmez.
          yearsSupported:
              gelen > 0 ? kayit.yearsSupported + 1 : kayit.yearsSupported,
          receivedTotal: kayit.receivedTotal + gelen,
          paidTotal: kayit.paidTotal + cepten,
          // Kimse üstlenmediyse kayıt **eski** yardımcıyı korur:
          // `copyWith` null ile temizlemez ve temizlemesi de doğru
          // olmazdı — "en son kim yanında oldu" sorusunun cevabı
          // bu yılın faturasını kimsenin paylaşmamasıyla silinmez.
          lastHelperId: katki.ids.isEmpty ? null : katki.ids.first,
        );
        yardimci = katki.ids.isEmpty ? null : katki.ids.first;
        metin = katki.names.isEmpty
            ? 'Bakımın için gereken masrafı kendin karşıladın.'
            : '${katki.names.join(' ve ')} bakım masrafının bir kısmını '
                'üstlendi.';

      case ElderSupportChoice.kendiIdareEt:
        kayit = kayit.copyWith(yearsAlone: kayit.yearsAlone + 1);
        metin = 'Bu yılı kimseye yüklenmeden çevirdin.';
    }

    final GameState next = state.copyWith(
      people: List<Person>.unmodifiable(kisiler),
      player: state.player.copyWith(
        wallet: cuzdan,
        stats: state.player.stats.gain(happiness: mutluluk),
      ),
      elderSupport: kayit.copyWith(lastDecidedAge: yas),
      log: List<LifeLogEntry>.unmodifiable(<LifeLogEntry>[
        ...state.log,
        LifeLogEntry(
          age: yas,
          text: metin,
          category: LogCategory.aile,
          personId: yardimci,
        ),
      ]),
    );
    return (state: next, text: metin, received: gelen);
  }
}

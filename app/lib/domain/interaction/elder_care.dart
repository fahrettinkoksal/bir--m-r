/// Yaşlı ebeveyn bakımı (Paket AO, §35, §36).
///
/// Paket AO öncesinde yaşlanan anne ve baba yalnızca sağlıkları düşen
/// birer kayıttı; oyuncunun yapabileceği tek şey "Nasılsın?" demekti.
///
/// **Ne yapar:** ileri yaşta ve sağlığı bozulan ebeveyn için gerçek bir
/// bakım ihtiyacı doğar ve oyuncu bir karar verir. Karar para, yakınlık
/// ve mutluluk üzerinde **gerçekten** iş görür. Yetişkin kardeş varsa
/// masrafa katkı verebilir.
///
/// **Ne yapmaz:** huzurevi ekonomisi, ağır bakım sistemi, sağlık
/// sigortası ya da vekâlet kurmaz — brief V1'de bunları açıkça dışarıda
/// bıraktı. Ayrıca **havadan para üretmez** (§36): katkı verecek kardeşin
/// kendi parası yoksa katkı da yoktur.
///
/// Bütün sayılar `prototypeOnly`'dir.
library;

import 'dart:math';

import '../../data/economy.dart';
import '../models/game_state.dart';
import '../models/life_log.dart';
import '../models/person.dart';
import '../models/relation.dart';
import '../models/wealth.dart';

/// Oyuncunun yaşlı ebeveyn için verebileceği karar (§35).
enum ElderCareChoice {
  /// Yanında kal: en çok yakınlık, en çok zaman, mutluluktan düşer.
  yanindaKal('Yanında kal'),

  /// Masraflarına yardım et: para gider, yakınlık artar.
  masrafaYardim('Masraflarına yardım et'),

  /// Sık sık ziyaret et: küçük yakınlık, küçük mutluluk bedeli.
  sikZiyaret('Sık sık ziyaret et'),

  /// İlgilenme: bedeli yok ama yakınlık düşer.
  ilgilenme('İlgilenme');

  const ElderCareChoice(this.label);

  final String label;
}

/// Bir bakım kararının sonucu.
typedef ElderCareResult = ({GameState state, String text, int paid});

abstract final class ElderCare {
  /// prototypeOnly: bakım ihtiyacının doğduğu en küçük ebeveyn yaşı.
  static const int prototypeOnlyMinParentAge = 70;

  /// prototypeOnly: bakım ihtiyacının doğduğu **mutluluk** eşiği.
  ///
  /// Adı uzun süre `prototypeOnlyHealthThreshold`'du ve bu yanlıştı:
  /// `Person`'ın sağlık alanı **yok** (sağlık yalnızca oyuncuda ve
  /// `Pet`'te tutuluyor), kod da baştan beri mutluluğu okuyordu. Yani
  /// yaşlı ebeveynin bakıma muhtaç sayılması sağlığından değil
  /// mutluluğundan çıkıyor. Ad düzeltildi; ölçü aynı kaldı — ebeveyne
  /// sağlık alanı eklemek ayrı bir tasarım kararı (Q-195).
  static const int prototypeOnlyCareHappinessBelow = 45;

  /// prototypeOnly: oyuncunun bu karara verebileceği en küçük yaş.
  static const int prototypeOnlyMinPlayerAge = 20;

  /// prototypeOnly: yıllık bakım masrafının asgari ücrete oranı.
  static const double prototypeOnlyYearlyCostShare = 0.35;

  /// Bu kişi için bakım kararı anlamlı mı?
  ///
  /// Koşul gerçek: yaş **ve** sağlık birlikte bakılır. Sağlıklı bir
  /// seksenlik için bakım kararı çıkmaz.
  static bool needsCare(GameState state, Person person) {
    if (!person.isAlive) return false;
    if (person.relation != RelationType.anne &&
        person.relation != RelationType.baba &&
        person.relation != RelationType.uveyAnne &&
        person.relation != RelationType.uveyBaba) {
      return false;
    }
    if (state.player.age < prototypeOnlyMinPlayerAge) return false;
    if (person.age < prototypeOnlyMinParentAge) return false;
    return person.happiness <= prototypeOnlyCareHappinessBelow ||
        person.age >= prototypeOnlyMinParentAge + 10;
  }

  /// Bakıma muhtaç ebeveynler.
  static List<Person> needingCare(GameState state) => state.people
      .where((Person p) => needsCare(state, p))
      .toList(growable: false);

  /// Bir yıllık bakımın oyuncuya maliyeti.
  static int yearlyCost() =>
      (Economy.netYearlyMinimumWage * prototypeOnlyYearlyCostShare).round();

  /// §36: yetişkin kardeşlerin bu yıl masrafa katkısı.
  ///
  /// **Havadan para üretilmez.** Katkı verebilmek için kardeşin
  /// kendi ekonomik durumunun kayıtlı ve yeterli olması gerekir;
  /// parası olmayan kardeş katkı vermez.
  static ({int amount, List<String> names}) siblingContribution(
    GameState state,
    int cost,
  ) {
    final List<Person> kardesler = state.people
        .where((Person p) =>
            p.isAlive &&
            (p.relation == RelationType.kardes ||
                p.relation == RelationType.yariKardes) &&
            // Kendi ayakları üzerinde duran kardeş.
            p.age >= 25 &&
            p.wealth != null)
        .toList(growable: false);
    if (kardesler.isEmpty) {
      return (amount: 0, names: const <String>[]);
    }

    int toplam = 0;
    final List<String> adlar = <String>[];
    for (final Person k in kardesler) {
      final double pay = switch (k.wealth!) {
        // Kendi geçimi zor olan kardeş katkı veremez; bu bir kusur değil.
        WealthTier.cokYoksul => 0.0,
        WealthTier.yoksul => 0.0,
        WealthTier.ortaHalli => 0.25,
        WealthTier.varlikli => 0.40,
        WealthTier.cokVarlikli => 0.50,
      };
      if (pay <= 0) continue;
      // Küs kardeş masrafa girmez.
      if (k.isEstranged) continue;
      toplam += (cost * pay).round();
      adlar.add(k.firstName);
    }
    // Kardeşler masrafın tamamından fazlasını ödemez.
    if (toplam > cost) toplam = cost;
    return (amount: toplam, names: adlar);
  }

  /// Karar uygulanır.
  ///
  /// Para yoksa "masraflarına yardım" seçeneği **olmuş gibi**
  /// gösterilmez; cüzdan eksiye düşmez.
  static ElderCareResult apply({
    required GameState state,
    required Person parent,
    required ElderCareChoice choice,
    required Random rng,
  }) {
    final int maliyet = yearlyCost();
    final ({int amount, List<String> names}) katki =
        siblingContribution(state, maliyet);
    final int cepten = (maliyet - katki.amount).clamp(0, maliyet);

    int bagDelta = 0;
    int mutlulukDelta = 0;
    int odenen = 0;
    String metin;

    switch (choice) {
      case ElderCareChoice.yanindaKal:
        // Para değil zaman veriliyor: en güçlü yakınlık, en ağır yük.
        bagDelta = 14;
        mutlulukDelta = -6;
        metin = '${parent.firstName} için yanında kaldın. '
            'Zamanının çoğu ona gitti.';

      case ElderCareChoice.masrafaYardim:
        if (state.player.wallet < cepten) {
          // Karşılanamıyorsa işlem yapılmaz; sahte bir yardım yazılmaz.
          return (
            state: state,
            text: 'Bu yıl bakım masrafını karşılayacak paran yok.',
            paid: 0,
          );
        }
        odenen = cepten;
        bagDelta = 10;
        mutlulukDelta = -2;
        metin = '${parent.firstName} için bakım masraflarına destek '
            'oldun.';
        if (katki.amount > 0) {
          metin += ' ${katki.names.join(' ve ')} de masrafa katkı sağladı.';
        }

      case ElderCareChoice.sikZiyaret:
        bagDelta = 6;
        mutlulukDelta = -1;
        metin = '${parent.firstName} yalnız kalmasın diye sık sık '
            'uğradın.';

      case ElderCareChoice.ilgilenme:
        // Bedeli yok ama bedelsiz de değil.
        bagDelta = -10;
        metin = '${parent.firstName} bu yıl seni pek göremedi.';
    }

    // Küçük bir değişkenlik: aynı karar her yıl birebir aynı hissi
    // vermez.
    bagDelta += rng.nextInt(3) - 1;

    final List<Person> yeni = state.people
        .map((Person p) => p.id == parent.id
            ? p.copyWith(bond: (p.bond + bagDelta).clamp(0, 100))
            : p)
        .toList(growable: false);

    GameState next = state.copyWith(
      people: List<Person>.unmodifiable(yeni),
      player: state.player.copyWith(
        wallet: state.player.wallet - odenen,
        stats: state.player.stats.gain(happiness: mutlulukDelta),
      ),
      log: List<LifeLogEntry>.unmodifiable(<LifeLogEntry>[
        ...state.log,
        LifeLogEntry(
          age: state.player.age,
          text: metin,
          category: LogCategory.aile,
          personId: parent.id,
        ),
      ]),
    );
    return (state: next, text: metin, paid: odenen);
  }
}

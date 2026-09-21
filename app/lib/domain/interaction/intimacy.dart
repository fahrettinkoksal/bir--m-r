/// Yakınlaşma, korunma ve gebelik (Paket 25).
///
/// **Faho'nun kararı:** "Çocuk yap" düğmesi kaldırıldı. Basınca doğrudan
/// çocuk sahibi olmak doğru değildi; çocuk bir **ihtimal** olmalı.
/// Yerine baş başa kalma eylemi geldi ve orada **korunarak / korunmadan**
/// seçimi yapılıyor.
///
/// Kurallar:
/// - Eylem yalnızca **yetişkin** oyuncuya ve eş ya da sevgiliye açıktır.
/// - Metinler kapalıdır; sahne anlatılmaz. Ne kastedildiği başlıktaki
///   simgeden ve korunma seçeneğinden anlaşılır.
/// - **Korunursa gebelik olmaz** (prototipte kondom başarısızlığı
///   modellenmedi — Q-093).
/// - Korunmazsa gebelik **ihtimallidir**: yaşa bağlıdır ve çiftten biri
///   kısırsa hiç olmaz.
/// - **Gebelik bir süreçtir (Paket 26).** Korunmadan yakınlaşma çocuğu
///   aynı anda getirmez: önce hamilelik başlar, bebek **bir sonraki yaş
///   ilerlemesinde** doğar. Hamilelik kayda girer ve ekranda görünür.
/// - Kısırlık **gizlidir**. Oyuncuya baştan söylenmez; denedikçe
///   anlaşılır. Belli bir denemeden sonra "olmuyor" denir ve hekime
///   gitmek önerilir (sağlık menüsü ve tüp bebek henüz tasarlanmadı).
/// - Aynı yıl üst üste denemekle ihtimal katlanmaz: yıl başına bir kez
///   hesaplanır.
///
/// Bütün sayılar `prototypeOnly`'dir (Q-093).
library;

import 'dart:math';

import '../models/game_state.dart';
import '../models/gender.dart';
import '../models/person.dart';
import '../models/pregnancy.dart';
import '../models/relation.dart';
import 'marriage_engine.dart';
import 'parenthood.dart';

/// Korunma tercihi.
enum Protection {
  korunarak('Korunarak', 'Bu sefer bir şey olmayacak.'),
  korunmadan('Korunmadan', 'Bir bebek ihtimali var.');

  const Protection(this.label, this.hint);

  final String label;
  final String hint;
}

abstract final class Intimacy {
  /// prototypeOnly: yakınlaşmanın mutluluk etkisi.
  static const int prototypeOnlyHappiness = 5;

  /// prototypeOnly: yakınlaşmanın yakınlık etkisi.
  static const int prototypeOnlyBond = 4;

  /// prototypeOnly: korunmadan bir yılda gebelik temel ihtimali.
  static const double prototypeOnlyBaseChance = 0.45;

  /// prototypeOnly: oyuncunun hayat başında kısır olma ihtimali.
  static const double prototypeOnlyInfertileChance = 0.08;

  /// prototypeOnly: kaç başarısız denemeden sonra "olmuyor" denir.
  static const int prototypeOnlyWorryAfter = 4;

  /// Kadının yaşına göre ihtimal çarpanı (`prototypeOnly`).
  static double prototypeOnlyAgeFactor(int womanAge) {
    if (womanAge <= 29) return 1.0;
    if (womanAge <= 34) return 0.8;
    if (womanAge <= 39) return 0.5;
    if (womanAge <= 44) return 0.25;
    return 0;
  }

  /// Yakınlaşılabilecek kişi: eş ya da hayattaki sevgili.
  static Person? partnerOf(GameState state) {
    if (state.isMarried) return state.spouse;
    for (final Person p in state.people) {
      if (p.isAlive && p.relation == RelationType.sevgili) return p;
    }
    return null;
  }

  /// Bu kişiyle yakınlaşmaya engel; engel yoksa boş metin.
  static String blockReason(GameState state, Person person) {
    if (!person.isAlive) return 'Bu kişi hayatta değil.';
    if (person.relation != RelationType.es &&
        person.relation != RelationType.sevgili) {
      return 'Yalnızca eşin ya da sevgilinle.';
    }
    if (state.player.age < MarriageEngine.prototypeOnlyMinAge) {
      return '${MarriageEngine.prototypeOnlyMinAge} yaşından itibaren.';
    }
    if (person.age < MarriageEngine.prototypeOnlyMinAge) {
      return '${person.firstName} bunun için henüz çok genç.';
    }
    return '';
  }

  /// Bu yıl gebelik hesabı yapılabilir mi?
  ///
  /// Aynı yıl ikinci bir deneme ihtimali katlamaz ve süren bir hamilelik
  /// varken yeni gebelik hesaplanmaz.
  static bool canConceiveThisYear(GameState state) =>
      !state.isExpecting && state.lastConceptionTryAge != state.player.age;

  /// Hamile olan taraf: oyuncu mu, partner mi?
  ///
  /// Aynı cinsiyetteki çiftlerde bu yol zaten kapalıdır (Q-064).
  static ExpectingParty expectingSide(GameState state) =>
      state.player.gender == Gender.kadin
          ? ExpectingParty.oyuncu
          : ExpectingParty.partner;

  /// Korunmadan bir denemede gebelik ihtimali.
  ///
  /// Çiftten biri kısırsa **sıfırdır**; oyuncuya bu sayı hiçbir zaman
  /// gösterilmez.
  static double conceptionChance(GameState state, Person partner) {
    if (state.player.infertile || partner.infertile) return 0;
    if (partner.gender == state.player.gender) return 0;
    final bool oyuncuKadin = state.player.gender == Gender.kadin;
    final int kadinYasi = oyuncuKadin ? state.player.age : partner.age;
    final int erkekYasi = oyuncuKadin ? partner.age : state.player.age;
    if (erkekYasi > Parenthood.prototypeOnlyMaxFatherAge) return 0;
    return prototypeOnlyBaseChance * prototypeOnlyAgeFactor(kadinYasi);
  }

  /// Uzun süredir deneyip sonuç alamamış mı?
  ///
  /// Kısırlık burada da **açıkça söylenmez**; yalnızca "olmuyor" denir.
  static bool shouldWorry(GameState state) =>
      state.unprotectedTries >= prototypeOnlyWorryAfter;

  /// Hayat başında oyuncunun doğurganlığı belirlenir.
  static bool rollPlayerInfertility(Random rng) =>
      rng.nextDouble() < prototypeOnlyInfertileChance;

  /// Romantik bağ kurulurken partnerin doğurganlığı belirlenir.
  static bool rollPartnerInfertility(Random rng) =>
      rng.nextDouble() < prototypeOnlyInfertileChance;
}

/// Yakınlaşma eylemini yürütür.
class IntimacyEngine {
  const IntimacyEngine();

  /// Baş başa kalır; korunma tercihine göre gebelik ihtimali işler.
  ///
  /// Sahne **anlatılmaz**: sonuç metni kapalı ve ölçülüdür.
  FamilyResult perform(
    GameState state,
    String personId,
    Protection protection,
    Random rng,
  ) {
    final Person? partner = state.personById(personId);
    if (partner == null) {
      return FamilyResult(
        state: state,
        outcome: const FamilyOutcome(
          applied: false,
          text: 'Bu kişi kayıtlarda yok.',
        ),
      );
    }
    final String engel = Intimacy.blockReason(state, partner);
    if (engel.isNotEmpty) {
      return FamilyResult(
        state: state,
        outcome: FamilyOutcome(applied: false, text: engel),
      );
    }

    // Her hâlükârda uygulanan etki: yakınlık ve mutluluk.
    final List<Person> people = state.people
        .map((Person p) => p.id == personId
            ? p.copyWith(
                bond: (p.bond + Intimacy.prototypeOnlyBond).clamp(0, 100),
              )
            : p)
        .toList(growable: false);
    GameState next = state.copyWith(
      people: List<Person>.unmodifiable(people),
      player: state.player.copyWith(
        stats: state.player.stats.copyWith(
          happiness: (state.player.stats.happiness +
                  Intimacy.prototypeOnlyHappiness)
              .clamp(0, 100),
        ),
      ),
      // Yakınlaşmak da bir temastır; ilgisizlik sayacı sıfırlanır.
      lastInteractionAge: <String, int>{
        ...state.lastInteractionAge,
        personId: state.player.age,
      },
    );

    if (protection == Protection.korunarak) {
      return FamilyResult(
        state: next,
        outcome: const FamilyOutcome(
          applied: true,
          text: 'Baş başa bir akşam geçirdiniz. Korundunuz.',
        ),
      );
    }

    // Korunmadan: gebelik bir **ihtimal**.
    if (!Intimacy.canConceiveThisYear(state)) {
      return FamilyResult(
        state: next,
        outcome: const FamilyOutcome(
          applied: true,
          text: 'Baş başa bir akşam geçirdiniz. Bu yıl için şansınızı '
              'zaten denediniz; bir sonraki yaşta yeniden mümkün.',
        ),
      );
    }

    next = next.copyWith(lastConceptionTryAge: state.player.age);

    // Yaş, çocuk sayısı gibi kesin engeller önce.
    final String cocukEngeli = const Parenthood().blockReason(next);
    if (cocukEngeli.isNotEmpty) {
      return FamilyResult(
        state: next,
        outcome: FamilyOutcome(
          applied: true,
          text: 'Baş başa bir akşam geçirdiniz. ($cocukEngeli)',
        ),
      );
    }

    final double sans = Intimacy.conceptionChance(next, partner);
    if (rng.nextDouble() < sans) {
      // **Bebek hemen gelmez (Paket 26).** Hamilelik başlar; doğum bir
      // sonraki yaş ilerlemesinde olur.
      final ExpectingParty taraf = Intimacy.expectingSide(next);
      final GameState hamile = next.copyWith(
        pregnancy: Pregnancy(
          partnerId: personId,
          startedAtAge: next.player.age,
          expecting: taraf,
        ),
        // Bekleyen bebek var: deneme sayacı sıfırlanır.
        unprotectedTries: 0,
      );
      return FamilyResult(
        state: hamile,
        outcome: FamilyOutcome(
          applied: true,
          text: taraf == ExpectingParty.oyuncu
              ? 'Baş başa bir akşam geçirdiniz. Birkaç hafta sonra '
                  'öğrendin: hamilesin.'
              : 'Baş başa bir akşam geçirdiniz. Birkaç hafta sonra '
                  '${partner.firstName} haberi verdi: bebek yolda.',
        ),
      );
    }

    final int denemeler = next.unprotectedTries + 1;
    next = next.copyWith(unprotectedTries: denemeler);
    final bool endise = denemeler >= Intimacy.prototypeOnlyWorryAfter;
    return FamilyResult(
      state: next,
      outcome: FamilyOutcome(
        applied: true,
        text: endise
            ? 'Baş başa bir akşam geçirdiniz. Bir süredir deniyorsunuz ama '
                'olmuyor; bir hekime görünmek iyi gelebilir.'
            : 'Baş başa bir akşam geçirdiniz. Bu sefer olmadı.',
      ),
    );
  }
}

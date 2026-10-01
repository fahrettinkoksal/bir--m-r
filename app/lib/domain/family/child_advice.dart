import '../models/game_state.dart';
import '../models/life_log.dart';
import '../models/person.dart';
import '../models/relation.dart';

/// Oyuncunun çocuğuna **akıl vermesi** (Paket AP §1, §40, §41).
///
/// Bu dosyanın tek bir derdi var: tavsiyenin gerçekten bir etkisi olsun
/// ama çocuk oyuncunun kuklası olmasın.
///
/// * **Tavsiye karar vermez (§1, §40).** Oyuncu "üniversiteye git"
///   diyemez; yalnızca konuşur. Çocuğun o yıl ne yapacağını kendi
///   kaydı ve kendi zarı belirler. Tavsiye o zarın ihtimalini **biraz**
///   kaydırır.
/// * **Etki kalıcı değil (§41).** Üç yıl içinde söner. Bir kez konuşup
///   ömür boyu yön vermek olmaz.
/// * **Yakınlık dinlenip dinlenmediğini belirler (§42).** Arası çok
///   kopuk bir çocuk tavsiyeyi dinlemez — ama onun hayatı yine devam
///   eder, durmaz.
/// * **Soğuma süresi var (§46).** Her yıl aynı konuşmayı yapıp etkiyi
///   üst üste bindirmek yok.
///
/// Yeni bir kayıt alanı eklenmedi: tavsiyenin yılı `lastInteractionAge`
/// içinde duruyor; o alan zaten "bu kişiyle bu şey en son hangi yıl
/// oldu" sorusunu tutuyor.
///
/// Sayısal değerler `prototypeOnly`'dir (Q-133).
abstract final class ChildAdvice {
  /// prototypeOnly: tavsiyenin anlam kazandığı en küçük yaş.
  ///
  /// Küçük çocuğa yön vermek bu sistemin konusu değil; onun yerine
  /// `ChildSchoolIssue` var.
  static const int prototypeOnlyMinAge = 14;

  /// prototypeOnly: iki tavsiye arasında geçmesi gereken yıl (§46).
  static const int prototypeOnlyCooldown = 3;

  /// prototypeOnly: tavsiyenin ihtimale kattığı en büyük pay.
  ///
  /// Kasten küçük: §1 "tavsiye ihtimali kaydırır, dikte etmez" dedi.
  static const double prototypeOnlyBoost = 0.10;

  /// prototypeOnly: etkinin tamamen söndüğü yıl sayısı.
  static const int prototypeOnlyFadeYears = 3;

  /// prototypeOnly: tavsiyenin yakınlığa katkısı.
  static const int prototypeOnlyBondGain = 2;

  /// prototypeOnly: bu yakınlığın altında çocuk dinlemez.
  static const int prototypeOnlyDeafBond = 12;

  /// Tavsiye kaydının anahtarı.
  static String adviceKey(String personId) => 'cocuk-tavsiye:$personId';

  /// Bu kişiye akıl verilebilir mi; verilemiyorsa gerekçesi.
  ///
  /// Gerekçe **yazılır**, seçenek sessizce kaybolmaz (D-095).
  static String? blockReason(GameState state, String personId) {
    final Person? kisi = state.personById(personId);
    if (kisi == null) return 'Böyle bir kişi yok.';
    if (!kisi.isAlive) return '${kisi.firstName} hayatta değil.';
    if (kisi.relation != RelationType.cocuk) {
      return 'Bu sistem yalnızca kendi çocuğun için.';
    }
    if (kisi.age < prototypeOnlyMinAge) {
      return '${kisi.firstName} henüz bu konuşmalar için küçük.';
    }
    final int? son = state.lastInteractionAge[adviceKey(personId)];
    if (son != null &&
        state.player.age - son < prototypeOnlyCooldown) {
      final int kalan = prototypeOnlyCooldown - (state.player.age - son);
      return '${kisi.firstName} ile bu konuyu yakın zamanda konuştunuz; '
          '$kalan yıl daha beklemen gerekiyor.';
    }
    return null;
  }

  static bool canAdvise(GameState state, String personId) =>
      blockReason(state, personId) == null;

  /// Oyuncu çocuğuna akıl verir.
  ///
  /// Sonuç **söylenmez**: "ikna ettin" diye bir satır yazılmaz, çünkü
  /// kararı oyuncu vermiyor. Yalnızca konuşmanın kendisi kaydedilir.
  static ({GameState state, String text}) advise(
    GameState state,
    String personId,
  ) {
    final String? engel = blockReason(state, personId);
    if (engel != null) return (state: state, text: engel);
    final Person kisi = state.personById(personId)!;

    final String metin = '${kisi.firstName} ile oturup hayatı konuştun; '
        'ne düşündüğünü söyledin, kararı ona bıraktın.';
    GameState next = state.copyWith(
      lastInteractionAge: <String, int>{
        ...state.lastInteractionAge,
        adviceKey(personId): state.player.age,
      },
      people: List<Person>.unmodifiable(<Person>[
        for (final Person p in state.people)
          if (p.id == personId)
            p.copyWith(
              bond: (p.bond + prototypeOnlyBondGain).clamp(0, 100),
            )
          else
            p,
      ]),
    );
    next = next.copyWith(
      log: List<LifeLogEntry>.unmodifiable(<LifeLogEntry>[
        ...next.log,
        LifeLogEntry(
          age: next.player.age,
          text: metin,
          category: LogCategory.aile,
          // §55: ortak geçmiş günlükteki `personId`'den toplanıyor.
          personId: personId,
        ),
      ]),
    );
    return (state: next, text: metin);
  }

  /// Bu kişinin kararlarına eklenecek ihtimal payı.
  ///
  /// Hiç tavsiye verilmediyse **tam olarak 0** döner. Bu önemli: pay 0
  /// olduğunda hiçbir ek zar atılmaz ve oyunun zar sırası kaymaz (aynı
  /// tohum aynı hayatı verir).
  static double boostFor(GameState state, Person person) {
    final int? son = state.lastInteractionAge[adviceKey(person.id)];
    if (son == null) return 0;
    final int gecenYil = state.player.age - son;
    if (gecenYil < 0 || gecenYil >= prototypeOnlyFadeYears) return 0;
    // Arası çok kopuk çocuk dinlemez (§42) — ama hayatı durmaz.
    if (person.bond < prototypeOnlyDeafBond) return 0;

    // Yıl geçtikçe söner.
    final double sonmeOrani =
        (prototypeOnlyFadeYears - gecenYil) / prototypeOnlyFadeYears;
    // Yakınlık dinlenip dinlenmediğini belirler.
    final double dinleme = (person.bond / 100).clamp(0.0, 1.0);
    return prototypeOnlyBoost * sonmeOrani * dinleme;
  }
}

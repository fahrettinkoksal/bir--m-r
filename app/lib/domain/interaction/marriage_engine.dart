import '../models/game_state.dart';
import '../models/life_log.dart';
import '../models/marriage.dart';
import '../models/person.dart';
import '../models/relation.dart';
import '../../data/event_pool.dart';
import '../../text/turkish_text.dart';

/// Aile eylemlerinin (evlilik, boşanma, çocuk) ortak sonucu.
class FamilyOutcome {
  const FamilyOutcome({required this.applied, required this.text});

  /// Eylem gerçekten uygulandı mı? `false` ise [text] gerekçedir.
  final bool applied;
  final String text;
}

class FamilyResult {
  const FamilyResult({required this.state, required this.outcome});

  final GameState state;
  final FamilyOutcome outcome;
}

/// Evlilik ve boşanma (Paket E1, `docs/GENERATION_PROPOSAL.md`).
///
/// Temel kurallar:
/// - **Kişi kimliği değişmez.** Sevgili evlenince aynı kimlikle `es` olur,
///   boşanınca aynı kimlikle `eskiEs` olur; kayıt hiçbir aşamada silinmez
///   ve ikinci kez üretilmez (D-029, D-038).
/// - Evlilik **gerçek bir kayıttır**: [GameState.marriage]. Miras kuralının
///   beklediği "gerçek birliktelik kaydı" budur (D-037); sevgili hiçbir
///   durumda eş sayılmaz.
/// - Evlenmek **kendi haneni kurmaktır**: eş haneye katılır, oyuncu artık
///   ailesinin yanında sayılmaz (D-043 ile uyumlu).
///
/// Bütün yaş, yakınlık ve tutar değerleri `prototypeOnly`'dir; onaylanmış
/// oyun kuralı değildir (`docs/DESIGN_REVIEW_QUEUE.md`, Q-063).
class MarriageEngine {
  const MarriageEngine();

  /// prototypeOnly: evlenmek için asgari yaş (iki taraf için de).
  static const int prototypeOnlyMinAge = 18;

  /// prototypeOnly: evlenmek için gereken asgari yakınlık.
  static const int prototypeOnlyMinBond = 60;

  /// prototypeOnly: nikâh ve düğün masrafı (₺).
  static const int prototypeOnlyWeddingCost = 60000;

  /// prototypeOnly: boşanmada eşe kalan nakit payı.
  ///
  /// Eşya ve mülk paylaşımı **yoktur**; nasıl yapılacağı karar kuyruğunda
  /// (Q-063). Uydurma bir mal paylaşımı uygulanmaz.
  static const double prototypeOnlyDivorceShare = 0.25;

  /// prototypeOnly: evlilik ve boşanmanın mutluluk etkisi.
  static const int prototypeOnlyWeddingHappiness = 12;
  static const int prototypeOnlyDivorceHappiness = -15;

  /// prototypeOnly: nikâhta yakınlığa eklenen değer.
  static const int prototypeOnlyWeddingBond = 10;

  /// Bu kişiyle evlenmeye engel; engel yoksa boş metin.
  String marryBlockReason(GameState state, Person person) {
    if (state.isMarried) return 'Zaten evlisin.';
    // İkinci evlilik henüz tasarlanmadı (Q-063). Yeni bir kayıt açmak eski
    // evlilik kaydının üzerine yazmak olurdu; kayıt asla silinmez.
    if (state.marriage != null) {
      return 'Bu prototipte ikinci evlilik yok; ilk evliliğin kaydı '
          'korunuyor.';
    }
    if (!person.isAlive) return 'Bu kişi hayatta değil.';
    if (person.relation != RelationType.sevgili) {
      return 'Yalnızca sevgilinle evlenebilirsin.';
    }
    if (state.player.age < prototypeOnlyMinAge) {
      return '$prototypeOnlyMinAge yaşından itibaren evlenebilirsin.';
    }
    if (person.age < prototypeOnlyMinAge) {
      return '${person.firstName} evlenmek için henüz çok genç.';
    }
    if (person.bond < prototypeOnlyMinBond) {
      return 'İlişkiniz evlilik için yeterince yakın değil '
          '(yakınlık ${person.bond}, gereken $prototypeOnlyMinBond).';
    }
    if (state.player.wallet < prototypeOnlyWeddingCost) {
      return 'Nikâh ve düğün masrafı ${trMoney(prototypeOnlyWeddingCost)}; '
          'cüzdanında yeterli para yok.';
    }
    return '';
  }

  /// Sevgiliyle evlenir.
  ///
  /// Kişi listeden çıkarılmaz, yeni kişi üretilmez: aynı kimlik `es` olur.
  FamilyResult marry(GameState state, String personId) {
    final Person? partner = state.personById(personId);
    if (partner == null) {
      return _blocked(state, 'Bu kişi kayıtlarda yok.');
    }
    final String engel = marryBlockReason(state, partner);
    if (engel.isNotEmpty) return _blocked(state, engel);

    final List<Person> people = state.people
        .map((Person p) => p.id == personId
            ? p.copyWith(
                relation: RelationType.es,
                inPlayerHousehold: true,
                bond: (p.bond + prototypeOnlyWeddingBond).clamp(0, 100),
              )
            : p)
        .toList(growable: false);

    final String metin = '${partner.fullName} ile evlendin. '
        'Nikâh masrafı ${trMoney(prototypeOnlyWeddingCost)} cüzdanından çıktı.';

    final GameState next = state.copyWith(
      people: List<Person>.unmodifiable(people),
      player: state.player.copyWith(
        wallet: state.player.wallet - prototypeOnlyWeddingCost,
        stats: state.player.stats.copyWith(
          happiness: (state.player.stats.happiness +
                  prototypeOnlyWeddingHappiness)
              .clamp(0, 100),
        ),
      ),
      marriage: Marriage(
        spouseId: personId,
        marriedAtAge: state.player.age,
        status: MarriageStatus.evli,
      ),
      // Evlenmek kendi haneni kurmaktır: artık ailenin yanında sayılmazsın.
      movedOut: true,
      storyFlags: <String>{...state.storyFlags, StoryFlags.evlendi},
    );

    return FamilyResult(
      state: _log(next, metin, LogCategory.aile),
      outcome: FamilyOutcome(applied: true, text: metin),
    );
  }

  /// Boşanmaya engel; engel yoksa boş metin.
  String divorceBlockReason(GameState state) {
    if (!state.isMarried) return 'Şu anda evli değilsin.';
    return '';
  }

  /// Boşanır: eş **aynı kimlikle** eski eş olur.
  ///
  /// Nakdin bir bölümü eşe kalır; eşya ve mülk paylaşımı uygulanmaz
  /// (Q-063). Çocuklar oyuncunun hanesinde kalır — velayet kuralları da
  /// karar kuyruğundadır.
  FamilyResult divorce(GameState state) {
    final String engel = divorceBlockReason(state);
    if (engel.isNotEmpty) return _blocked(state, engel);

    final Person spouse = state.spouse!;
    final int pay =
        (state.player.wallet * prototypeOnlyDivorceShare).round().clamp(
              0,
              state.player.wallet,
            );

    final List<Person> people = state.people
        .map((Person p) => p.id == spouse.id
            ? p.copyWith(
                relation: RelationType.eskiEs,
                inPlayerHousehold: false,
              )
            : p)
        .toList(growable: false);

    final String metin = pay > 0
        ? '${spouse.fullName} ile boşandın. Anlaşma gereği ${trMoney(pay)} '
            'cüzdanından çıktı; kaydı İlişkiler bölümünde eski eş olarak '
            'kalıyor.'
        : '${spouse.fullName} ile boşandın. Kaydı İlişkiler bölümünde '
            'eski eş olarak kalıyor.';

    final GameState next = state.copyWith(
      people: List<Person>.unmodifiable(people),
      player: state.player.copyWith(
        wallet: state.player.wallet - pay,
        stats: state.player.stats.copyWith(
          happiness: (state.player.stats.happiness +
                  prototypeOnlyDivorceHappiness)
              .clamp(0, 100),
        ),
      ),
      marriage: state.marriage!.copyWith(
        status: MarriageStatus.bosandi,
        endedAtAge: state.player.age,
      ),
      storyFlags: <String>{
        ...state.storyFlags.where(
          (String f) => f != StoryFlags.romantikIliskide,
        ),
        StoryFlags.bosandi,
        StoryFlags.romantikBitti,
      },
    );

    return FamilyResult(
      state: _log(next, metin, LogCategory.aile),
      outcome: FamilyOutcome(applied: true, text: metin),
    );
  }

  /// Eş vefat ettiyse evlilik kaydını **dul** durumuna geçirir.
  ///
  /// Kayıt silinmez; miras hesabı hâlâ gerçek bir evliliğe bakar.
  GameState settleWidowhood(GameState state, int age) {
    final Marriage? kayit = state.marriage;
    if (kayit == null || !kayit.isActive) return state;
    final Person? es = state.personById(kayit.spouseId);
    if (es == null || es.isAlive) return state;

    return state.copyWith(
      marriage: kayit.copyWith(
        status: MarriageStatus.dul,
        endedAtAge: age,
      ),
      storyFlags: <String>{
        ...state.storyFlags.where(
          (String f) => f != StoryFlags.romantikIliskide,
        ),
      },
    );
  }

  FamilyResult _blocked(GameState state, String reason) => FamilyResult(
        state: state,
        outcome: FamilyOutcome(applied: false, text: reason),
      );

  GameState _log(GameState state, String text, LogCategory category) =>
      state.copyWith(
        log: List<LifeLogEntry>.unmodifiable(<LifeLogEntry>[
          ...state.log,
          LifeLogEntry(
            age: state.player.age,
            text: text,
            category: category,
          ),
        ]),
      );
}

import 'dart:math';

import '../models/game_state.dart';
import '../models/gender.dart';
import '../models/person.dart';
import '../models/pregnancy.dart';
import '../models/stats.dart';
import '../../text/turkish_text.dart';
import 'marriage_engine.dart';
import 'intimacy.dart';
import 'parenthood.dart';

/// Tüp bebek (IVF) tedavisi — Aktiviteler → Sağlık Merkezi (Paket 35).
///
/// **Neden var:** Paket 25'te kısırlık gerçek bir sonuç oldu; oyuncu ya da
/// eşi kısır olabiliyor ve bunu ancak deneyerek anlıyor. O günden beri
/// kısır bir çiftin tıbbi hiçbir çıkış yolu yoktu — yalnızca evlat edinme
/// (D-049) duruyordu. Faho "aktiviteler menüsünün içerisine sağlık menüsü
/// olacak, tüp bebek tedavisi eklenebilir" dedi; bu paket onu karşılıyor.
///
/// **Başarı oranları gerçeğinden alındı.** Tüp bebekte canlı doğum oranı
/// yaşla birlikte keskin biçimde düşer: 35 altında yaklaşık %45, 40'tan
/// sonra %20'nin altına iner, 43-44'te %5'lere, 44 üstünde %2'ye kadar
/// gerileler. Oyundaki basamaklar bu aralıkları izler.
///
/// **Tedavi bir garanti değildir.** Denemenin başarısız olması olağandır ve
/// oyunda da öyle durur: ücret her hâlükârda ödenir, başarısızlık mutluluğu
/// düşürür. Kısır bir çiftte ihtimal **sıfır değildir** ama düşüktür —
/// tedavinin bütün anlamı budur.
///
/// Sayısal değerler `prototypeOnly`'dir
/// (`docs/DESIGN_REVIEW_QUEUE.md`, Q-103).
abstract final class FertilityTreatment {
  /// prototypeOnly: bir denemenin ücreti (₺).
  static const int prototypeOnlyCost = 250000;

  /// prototypeOnly: tedaviye başvurmadan önce gereken başarısız deneme.
  ///
  /// [Intimacy.prototypeOnlyWorryAfter] ile **aynı eşiktir**: oyuncu zaten
  /// "bir süredir deniyorsunuz ama olmuyor; bir hekime görünmek iyi
  /// gelebilir" cümlesini görüyor. O cümle artık gerçek bir kapıyı
  /// işaret ediyor.
  static int get prototypeOnlyMinTries => Intimacy.prototypeOnlyWorryAfter;

  /// Hayat boyu yapılabilecek en fazla deneme (Faho'nun Q-103 kararı).
  ///
  /// Tedavi hem pahalı hem yıpratıcı; sınırsız denemek hem gerçeğe hem
  /// oyunun dengesine aykırıydı.
  static const int maxLifetimeTries = 5;

  /// prototypeOnly: bir yılda kaç deneme yapılabilir.
  ///
  /// Gerçekte bir tedavi döngüsü aylar sürer; yılda birden fazlası olmaz.
  static const int prototypeOnlyTriesPerAge = 1;

  /// prototypeOnly: çiftten biri kısırsa ihtimale uygulanan çarpan.
  ///
  /// Sıfır **değildir**: tedavinin varlık sebebi budur.
  static const double prototypeOnlyInfertileFactor = 0.6;

  /// prototypeOnly: başarısız denemenin mutluluğa etkisi.
  static const int prototypeOnlyFailHappiness = -8;

  /// prototypeOnly: başarılı denemenin mutluluğa etkisi.
  static const int prototypeOnlySuccessHappiness = 12;

  /// prototypeOnly: başarısız denemenin yakınlığa etkisi.
  ///
  /// Süreç çifti yıpratır; küçük ama gerçek bir etkisi vardır.
  static const int prototypeOnlyFailBond = -2;

  /// prototypeOnly: taşıyacak tarafın yaşına göre bir denemenin
  /// canlı doğumla sonuçlanma ihtimali.
  /// prototypeOnly: taşıyacak tarafın yaşına göre bir denemenin
  /// canlı doğumla sonuçlanma ihtimali.
  ///
  /// Kendi yumurtasıyla tüp bebekte canlı doğum oranı 43-44'ten sonra
  /// %1-2 bandına iner ve 46'dan sonra neredeyse görülmez. Faho'nun
  /// "55'e kadar" isteğine uyarak kapı açık bırakıldı ama üst yaşlarda
  /// oran gerçeğe yakın tutuldu: denemek mümkün, ummak gerçekçi değil.
  static double prototypeOnlySuccessByAge(int womanAge) {
    if (womanAge < 35) return 0.45;
    if (womanAge <= 37) return 0.38;
    if (womanAge <= 39) return 0.30;
    if (womanAge <= 42) return 0.18;
    if (womanAge <= 44) return 0.06;
    if (womanAge <= 46) return 0.02;
    if (womanAge <= 50) return 0.008;
    if (womanAge <= 55) return 0.003;
    return 0;
  }

  /// Bu yıl kaç deneme yapıldı?
  static int triesThisAge(GameState state) =>
      state.interactionCount('tup_bebek', 'deneme');

  /// Tedaviye engel; engel yoksa boş metin.
  ///
  /// Metinler **kısırlığı açıkça söylemez** (Paket 25 kuralı): oyuncuya
  /// "kısırsın" denmez, yalnızca sonuç alınamadığı söylenir.
  static String blockReason(GameState state) {
    final Person? partner = Intimacy.partnerOf(state);
    if (partner == null) {
      return 'Tedavi için bir eşin ya da sevgilinin olması gerekiyor.';
    }
    if (!partner.isAlive) return 'Bu kişi hayatta değil.';
    if (partner.gender == state.player.gender) {
      return 'Bu yol bu prototipte açık değil.';
    }
    if (state.isExpecting) {
      return 'Zaten bir bebek bekliyorsunuz.';
    }
    if (state.player.age < Parenthood.prototypeOnlyMinAge ||
        partner.age < Parenthood.prototypeOnlyMinAge) {
      return '${Parenthood.prototypeOnlyMinAge} yaşından itibaren '
          'başvurulabilir.';
    }
    if (state.unprotectedTries < prototypeOnlyMinTries) {
      return 'Hekim önce bir süre kendiniz denemenizi istiyor. '
          'Sonuç alamazsanız kapı açık.';
    }
    if (state.ivfAttempts >= maxLifetimeTries) {
      return 'Hekim daha fazla deneme önermiyor; $maxLifetimeTries deneme '
          'yaptınız.';
    }
    if (triesThisAge(state) >= prototypeOnlyTriesPerAge) {
      return 'Bu yıl bir deneme yaptınız; tedavi aylar sürüyor, '
          'seneye tekrar denenebilir.';
    }
    if (successChance(state) <= 0) {
      return 'Hekim bu yaşta tedavinin sonuç vermeyeceğini söylüyor.';
    }
    if (state.player.wallet < prototypeOnlyCost) {
      return '${trMoney(prototypeOnlyCost)} gerekiyor; cüzdanında '
          'yeterli para yok.';
    }
    return '';
  }

  /// Bir denemenin başarı ihtimali.
  ///
  /// Oyuncuya **yaklaşık** olarak gösterilir; gizlenmez. Kısırlık çarpanı
  /// sessizce uygulanır ve ayrıca söylenmez.
  static double successChance(GameState state) {
    final Person? partner = Intimacy.partnerOf(state);
    if (partner == null) return 0;
    if (partner.gender == state.player.gender) return 0;

    final bool oyuncuKadin = state.player.gender == Gender.kadin;
    final int kadinYasi = oyuncuKadin ? state.player.age : partner.age;
    final int erkekYasi = oyuncuKadin ? partner.age : state.player.age;
    if (erkekYasi > Parenthood.prototypeOnlyMaxFatherAge) return 0;

    double sans = prototypeOnlySuccessByAge(kadinYasi);
    if (state.player.infertile || partner.infertile) {
      sans *= prototypeOnlyInfertileFactor;
    }
    return sans;
  }

  /// Oyuncuya gösterilen yaklaşık oran ("yaklaşık %38" gibi).
  ///
  /// Kısırlık çarpanı buraya da yansır ama **sebebi söylenmez**.
  static int displayChancePercent(GameState state) =>
      (successChance(state) * 100).round();

  /// Bir tedavi denemesi yapar.
  ///
  /// Ücret **her hâlükârda** ödenir: başarısız deneme de masraflıdır.
  /// Başarılıysa hamilelik başlar ve bebek bir sonraki yaş ilerlemesinde
  /// doğar (Paket 26 akışı).
  static FamilyResult attempt(GameState state, Random rng) {
    final String engel = blockReason(state);
    if (engel.isNotEmpty) {
      return FamilyResult(
        state: state,
        outcome: FamilyOutcome(applied: false, text: engel),
      );
    }
    final Person partner = Intimacy.partnerOf(state)!;
    final bool basarili = rng.nextDouble() < successChance(state);

    final Stats stats = state.player.stats.copyWith(
      happiness: state.player.stats.happiness +
          (basarili
              ? prototypeOnlySuccessHappiness
              : prototypeOnlyFailHappiness),
    );

    final List<Person> people = basarili
        ? state.people
        : state.people
            .map(
              (Person p) => p.id == partner.id
                  ? p.copyWith(bond: p.bond + prototypeOnlyFailBond)
                  : p,
            )
            .toList(growable: false);

    GameState next = state.copyWith(
      player: state.player.copyWith(
        stats: stats,
        wallet: state.player.wallet - prototypeOnlyCost,
      ),
      people: List<Person>.unmodifiable(people),
      ivfAttempts: state.ivfAttempts + 1,
      interactionCounts: Map<String, int>.unmodifiable(<String, int>{
        ...state.interactionCounts,
        GameState.interactionKey('tup_bebek', 'deneme'):
            triesThisAge(state) + 1,
      }),
    );

    if (basarili) {
      next = next.copyWith(
        pregnancy: Pregnancy(
          partnerId: partner.id,
          startedAtAge: state.player.age,
          expecting: Intimacy.expectingSide(state),
        ),
        // Deneme sayacı sıfırlanır: bekleyiş sona erdi.
        unprotectedTries: 0,
      );
    }

    final String metin = basarili
        ? 'Tedavi tuttu. ${partner.firstName} ile uzun bir bekleyişten '
            'sonra bebek yolda. ${trMoney(prototypeOnlyCost)} ödediniz.'
        : 'Bu deneme sonuç vermedi. ${trMoney(prototypeOnlyCost)} ödediniz; '
            'hekim isterseniz seneye yeniden denenebileceğini söyledi.';

    return FamilyResult(
      state: next,
      outcome: FamilyOutcome(applied: true, text: metin),
    );
  }
}

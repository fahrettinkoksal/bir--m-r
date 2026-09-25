import 'dart:math';

import '../../data/event_pool.dart';
import '../../data/finger_catalog.dart';
import '../../data/name_pool.dart';
import '../generation/random_util.dart';
import '../models/finger_profile.dart';
import '../models/game_state.dart';
import '../models/gender.dart';
import '../models/interaction.dart';
import '../models/life_log.dart';
import '../models/pending_notice.dart';
import '../models/person.dart';
import '../models/relation.dart';
import '../models/wealth.dart';
import 'intimacy.dart';
import 'romance.dart';

/// Bir kaydırmanın sonucu.
class FingerOutcome {
  const FingerOutcome({
    required this.applied,
    required this.text,
    this.matched = false,
    this.person,
  });

  final bool applied;
  final String text;

  /// Beğeni karşılık buldu mu?
  final bool matched;

  /// Tanışma sonucunda hayatına giren kişi.
  final Person? person;
}

class FingerResult {
  const FingerResult({required this.state, required this.outcome});

  final GameState state;
  final FingerOutcome outcome;
}

/// "Finger" tanışma uygulaması (Paket 34).
///
/// Kurallar:
/// - Bir yılda bakılabilecek profil sayısı sınırlıdır; sonsuz kaydırma yok.
/// - Beğeni her zaman karşılık bulmaz; ihtimal görünüş ve karizmaya bağlıdır.
/// - Eşleşmek tanışmak değildir. **Tanışıldığında** kişi oyunun kişi
///   listesine kalıcı kimlikle girer ve oradan sonra normal ilişki
///   kurallarıyla işler.
/// - Sevgilisi ya da eşi olan biri eşleşmeyle yeni sevgili edinemez;
///   tanışan kişi arkadaş olur.
///
/// Sayısal değerler `prototypeOnly`'dir
/// (`docs/DESIGN_REVIEW_QUEUE.md`, Q-102).
abstract final class Finger {
  /// Bu yıl kaç profile bakıldı?
  static int swipesThisAge(GameState state) =>
      state.interactionCount('finger', 'kaydirma');

  /// Bu yıl kaç beğeni atıldı? (D-081)
  static int likesThisAge(GameState state) =>
      state.interactionCount('finger', 'begeni');

  /// Bu yıl atılabilecek beğeni sayısı.
  ///
  /// Premium üyelik sınırı yükseltir; sınırsız yapmaz.
  static int likeLimit(GameState state) => state.hasFingerPremium
      ? kFingerPremiumLikesPerAge
      : kFingerMaxLikesPerAge;

  /// Bu yıl kalan beğeni hakkı.
  static int likesLeft(GameState state) =>
      (likeLimit(state) - likesThisAge(state)).clamp(0, 999);

  /// Oyuncunun yaşına uygun **en küçük** aday yaşı (D-081).
  ///
  /// Faho bildirdi: "47 yaşında birisine 17 yaşında birisi çıkmamalı".
  /// Alt sınır iki koşulun **daha yükseği**dir: oyuncunun on yaş altı ve
  /// yaygın olarak kullanılan "yaşının yarısı artı yedi" ölçütü. İkisinin
  /// de altına inilmez ve hiçbir koşulda 18'in altına düşülmez.
  static int minCandidateAge(int playerAge) {
    final int onYasAlt = playerAge - 10;
    final int yarimArtiYedi = playerAge ~/ 2 + 7;
    final int alt = onYasAlt > yarimArtiYedi ? onYasAlt : yarimArtiYedi;
    return alt < kFingerMinAge ? kFingerMinAge : alt;
  }

  /// Oyuncunun yaşına uygun **en büyük** aday yaşı.
  static int maxCandidateAge(int playerAge) {
    final int ust = playerAge + 10;
    return ust > 80 ? 80 : ust;
  }

  /// Bu profil oyuncunun yaşına hâlâ uygun mu?
  /// Profil oyuncunun süzgecinden geçiyor mu? (D-107)
  ///
  /// Süzgeç kapalıysa herkes geçer. Süzgeç gerçek bir kısıttır: dar
  /// tutmak deste üretimini zorlaştırır ama kapıyı kapatmaz, çünkü yeni
  /// adaylar süzgece göre üretilir.
  static bool fitsFilter(GameState state, FingerProfile profile) =>
      state.fingerWealthFilter == null ||
      profile.wealth == state.fingerWealthFilter;

  static bool fitsAge(GameState state, FingerProfile profile) =>
      profile.age >= minCandidateAge(state.player.age) &&
      profile.age <= maxCandidateAge(state.player.age);

  /// Uygulama açılabilir mi?
  static InteractionAvailability availability(GameState state) {
    if (state.player.age < kFingerMinAge) {
      return const InteractionAvailability.blocked(
        '$kFingerMinAge yaşından itibaren kullanılabilir.',
      );
    }
    return const InteractionAvailability.allowed();
  }

  /// Kaydırma yapılabilir mi?
  static InteractionAvailability swipeAvailability(GameState state) {
    final InteractionAvailability temel = availability(state);
    if (!temel.isAllowed) return temel;
    if (swipesThisAge(state) >= kFingerMaxSwipesPerAge) {
      return const InteractionAvailability.blocked(
        'Bu yıl yeterince baktın; seneye yeni profiller gelir.',
      );
    }
    return const InteractionAvailability.allowed();
  }

  /// Beğeni atılabilir mi? (D-081)
  ///
  /// Geçmek sınırsızdır; sınır yalnızca **beğeniye** konur. Sınır
  /// dolduğunda gerekçe premium seçeneğini de söyler, çünkü kapalı
  /// düğmenin sebebi görünür olmalı (D-038).
  static InteractionAvailability likeAvailability(GameState state) {
    final InteractionAvailability temel = swipeAvailability(state);
    if (!temel.isAllowed) return temel;
    if (likesThisAge(state) >= likeLimit(state)) {
      return InteractionAvailability.blocked(
        state.hasFingerPremium
            ? 'Premium beğeni hakkın da bu yıl bitti.'
            : 'Bu yıl $kFingerMaxLikesPerAge beğeni hakkını kullandın. '
                'Premium üyelikle yılda $kFingerPremiumLikesPerAge '
                'beğeni atabilirsin.',
      );
    }
    return const InteractionAvailability.allowed();
  }

  /// Premium üyelik alınabilir mi?
  static InteractionAvailability premiumAvailability(GameState state) {
    final InteractionAvailability temel = availability(state);
    if (!temel.isAllowed) return temel;
    if (state.hasFingerPremium) {
      return const InteractionAvailability.blocked(
        'Premium üyeliğin zaten sürüyor.',
      );
    }
    if (state.player.wallet < kFingerPremiumYearlyCost) {
      return const InteractionAvailability.blocked(
        'Premium üyelik için cüzdanında yeterli para yok.',
      );
    }
    return const InteractionAvailability.allowed();
  }

  /// Premium üyelik satın alır.
  ///
  /// Ücret **bir kez** düşer ve üyelik o yıl dâhil bir yıl sürer.
  static FingerResult buyPremium(GameState state) {
    final InteractionAvailability check = premiumAvailability(state);
    if (!check.isAllowed) {
      return FingerResult(
        state: state,
        outcome: FingerOutcome(applied: false, text: check.reason!),
      );
    }
    return FingerResult(
      state: state.copyWith(
        player: state.player.copyWith(
          wallet: state.player.wallet - kFingerPremiumYearlyCost,
        ),
        fingerPremiumUntilAge: state.player.age,
      ),
      outcome: FingerOutcome(
        applied: true,
        text: 'Premium üyelik alındı. Bu yıl '
            '$kFingerPremiumLikesPerAge beğeni hakkın var.',
      ),
    );
  }

  /// Oyuncunun kendi profilini kaydeder (D-081).
  ///
  /// Faho'nun isteği: "bir finger profili oluşturalım, hobilerimi falan
  /// sorsun, ona göre insanlar da beni beğenebilsin". Profil doldurmak
  /// eşleşme ihtimalini yükseltir ve ortak ilgi alanı ayrıca katkı yapar.
  static FingerResult saveProfile(
    GameState state, {
    required String bio,
    required List<String> interests,
  }) {
    final InteractionAvailability check = availability(state);
    if (!check.isAllowed) {
      return FingerResult(
        state: state,
        outcome: FingerOutcome(applied: false, text: check.reason!),
      );
    }
    return FingerResult(
      state: state.copyWith(
        fingerBio: bio,
        fingerInterests: List<String>.unmodifiable(interests),
      ),
      outcome: const FingerOutcome(
        applied: true,
        text: 'Profilin kaydedildi.',
      ),
    );
  }

  /// Desteyi gerekirse doldurur.
  ///
  /// Zaten profil varsa dokunmaz: ekran her açılışta yeniden karılmaz.
  static GameState ensureDeck(GameState state, Random rng) {
    if (state.player.age < kFingerMinAge) return state;

    // Yaşa uymayan profiller desteden **düşer** (D-081).
    //
    // Eskiden deste bir kez kurulup öylece duruyordu: yirmi yaşında
    // kurulan deste kırk yedi yaşında hâlâ yirmilik profiller
    // gösteriyordu. Faho'nun bildirdiği durum buydu. Artık her açılışta
    // yaşa uymayanlar atılır ve yerlerine uygun profil üretilir.
    final List<FingerProfile> deste = state.fingerDeck
        .where((FingerProfile p) => fitsAge(state, p) && fitsFilter(state, p))
        .toList(growable: true);

    if (deste.length >= kFingerDeckSize &&
        deste.length == state.fingerDeck.length) {
      return _ensureIncoming(state, rng);
    }

    int sayac = _nextIndex(state);
    while (deste.length < kFingerDeckSize) {
      deste.add(_uret(state, rng, sayac++));
    }
    return _ensureIncoming(
      state.copyWith(fingerDeck: List<FingerProfile>.unmodifiable(deste)),
      rng,
    );
  }

  /// "Seni beğenenler" listesini doldurur (D-081).
  ///
  /// Kimlerin oyuncuyu beğendiği **profiline bakar**: profil
  /// doldurulmamışsa kimse kendiliğinden beğenmez. Liste yaşa uymayan
  /// profillerden de temizlenir.
  static GameState _ensureIncoming(GameState state, Random rng) {
    final List<FingerProfile> gelen = state.fingerIncoming
        .where((FingerProfile p) => fitsAge(state, p) && fitsFilter(state, p))
        .toList(growable: true);

    final int hedef = _incomingTarget(state);
    if (gelen.length == state.fingerIncoming.length &&
        gelen.length >= hedef) {
      return state;
    }

    int sayac = _nextIndex(state) + 500;
    while (gelen.length < hedef) {
      gelen.add(_uret(state, rng, sayac++));
    }
    return state.copyWith(
      fingerIncoming: List<FingerProfile>.unmodifiable(gelen),
    );
  }

  /// Kaç kişinin oyuncuyu kendiliğinden beğeneceği.
  ///
  /// Profil yoksa sıfır: kimse boş profili beğenmez. Profil doldukça ve
  /// cazibe yükseldikçe artar.
  static int _incomingTarget(GameState state) {
    if (!state.hasFingerProfile) return 0;
    final double cazibe =
        (state.player.stats.appearance + state.player.stats.charisma) / 200;
    final int taban = state.fingerInterests.isEmpty ? 1 : 2;
    return (taban + (cazibe * kFingerMaxIncoming))
        .round()
        .clamp(1, kFingerMaxIncoming);
  }

  /// Profili geçer: deste yenilenir, eşleşme olmaz.
  static FingerResult pass(GameState state, String profileId, Random rng) {
    final InteractionAvailability check = swipeAvailability(state);
    if (!check.isAllowed) {
      return FingerResult(
        state: state,
        outcome: FingerOutcome(applied: false, text: check.reason!),
      );
    }
    GameState next = _consume(state, profileId);
    next = ensureDeck(next, rng);
    return FingerResult(
      state: next,
      outcome: const FingerOutcome(
        applied: true,
        text: 'Geçtin. Sıradaki profil geldi.',
      ),
    );
  }

  /// Profili beğenir. Karşılık gelirse eşleşme listesine düşer.
  ///
  /// Profil "seni beğenenler" listesindeyse eşleşme **kesindir**: karşı
  /// taraf zaten beğenmiştir, zar atmanın anlamı yok (D-081).
  static FingerResult like(GameState state, String profileId, Random rng) {
    final InteractionAvailability check = likeAvailability(state);
    if (!check.isAllowed) {
      return FingerResult(
        state: state,
        outcome: FingerOutcome(applied: false, text: check.reason!),
      );
    }
    final FingerProfile? gelen = _fromIncoming(state, profileId);
    final FingerProfile? profil = gelen ?? _fromDeck(state, profileId);
    if (profil == null) {
      return FingerResult(
        state: state,
        outcome: const FingerOutcome(
          applied: false,
          text: 'Bu profil destede değil.',
        ),
      );
    }

    final bool eslesti =
        gelen != null || rng.nextDouble() < matchChance(state, profil);
    GameState next = _consumeLike(state, profileId, fromIncoming: gelen != null);

    if (eslesti) {
      next = next.copyWith(
        fingerMatches: List<FingerProfile>.unmodifiable(<FingerProfile>[
          ...next.fingerMatches,
          profil.copyWith(matchedAtAge: state.player.age),
        ]),
      );
    }
    next = ensureDeck(next, rng);

    return FingerResult(
      state: next,
      outcome: FingerOutcome(
        applied: true,
        matched: eslesti,
        text: gelen != null
            ? '${gelen.firstName} seni zaten beğenmişti. Eşleştiniz.'
            : eslesti
                ? rng.pick(kFingerMatchLines)
                : rng.pick(kFingerNoMatchLines),
      ),
    );
  }

  /// "Seni beğenenler" listesindeki profil.
  static FingerProfile? _fromIncoming(GameState state, String id) =>
      state.fingerIncoming.where((FingerProfile p) => p.id == id).firstOrNull;

  /// Beğeniyi harcar ve profili listeden düşürür.
  static GameState _consumeLike(
    GameState state,
    String profileId, {
    required bool fromIncoming,
  }) {
    GameState next = fromIncoming
        ? state.copyWith(
            fingerIncoming: List<FingerProfile>.unmodifiable(
              state.fingerIncoming
                  .where((FingerProfile p) => p.id != profileId),
            ),
          )
        : _consume(state, profileId);
    return next.copyWith(
      interactionCounts: Map<String, int>.unmodifiable(<String, int>{
        ...next.interactionCounts,
        GameState.interactionKey('finger', 'begeni'):
            likesThisAge(next) + 1,
      }),
    );
  }

  /// prototypeOnly: beğeninin karşılık bulma ihtimali.
  ///
  /// Görünüş ve karizma yükseldikçe artar; kimse sıfır ihtimalle kalmaz.
  /// **Doldurulmuş profil** ve **ortak ilgi alanı** ayrıca katkı yapar
  /// (D-081): kendini anlatan profil karşılık bulur.
  static double matchChance(GameState state, [FingerProfile? profile]) {
    final double cazibe =
        (state.player.stats.appearance + state.player.stats.charisma) / 200;
    double sans = kFingerBaseMatchChance + cazibe * kFingerCharmBonus;

    if (state.hasFingerProfile) sans += kFingerProfileBonus;
    if (state.hasFingerPremium) sans += kFingerPremiumMatchBonus;

    if (profile != null && state.fingerInterests.isNotEmpty) {
      final int ortak = profile.interests
          .where((String i) => state.fingerInterests.contains(i))
          .length;
      sans += ortak * kFingerSharedInterestBonus;
    }

    return sans.clamp(0.05, 0.9);
  }

  /// Eşleşilen kişiyle tanışır: kişi artık oyunun kişi listesindedir.
  ///
  /// Sevgilisi ya da eşi olmayan biri için **sevgili** olur; olan biri için
  /// **arkadaş**. Uygulama var olan ilişkiyi kendiliğinden bitirmez.
  static FingerResult meet(GameState state, String profileId, Random rng) {
    final FingerProfile? profil = _fromMatches(state, profileId);
    if (profil == null) {
      return FingerResult(
        state: state,
        outcome: const FingerOutcome(
          applied: false,
          text: 'Böyle bir eşleşmen yok.',
        ),
      );
    }
    if (profil.isMet) {
      return FingerResult(
        state: state,
        outcome: FingerOutcome(
          applied: false,
          text: '${profil.firstName} ile zaten tanıştın.',
        ),
      );
    }

    const Romance romance = Romance();
    final bool bosta = !romance.hasPartner(state) && state.marriage == null;

    // Tanışmak sevgili olmak değildir (D-107). Buluşmanın sonucu iki
    // tarafın da **ne aradığına** bakar; oyun kimseyi kimsenin sevgilisi
    // yapmaz.
    final bool arkadasKalir = !bosta ||
        state.fingerIntent == FingerIntent.arkadaslik ||
        profil.intent == FingerIntent.arkadaslik;
    final RelationType iliski =
        arkadasKalir ? RelationType.arkadas : RelationType.flort;

    final String kimlik = _nextPersonId(state);
    final Person kisi = Person(
      id: kimlik,
      firstName: profil.firstName,
      lastName: profil.lastName,
      gender: profil.gender,
      relation: iliski,
      age: profil.age,
      isAlive: true,
      inPlayerHousehold: false,
      employment: profil.occupation == null
          ? EmploymentStatus.ogrenci
          : EmploymentStatus.calisiyor,
      occupation: profil.occupation,
      wealth: profil.age >= 18 ? WealthTier.ortaHalli : null,
      city: profil.city,
      bond: rng.between(45, 62), // prototypeOnly
      infertile: iliski == RelationType.flort
          ? Intimacy.rollPartnerInfertility(rng)
          : false,
    );

    final List<FingerProfile> eslesmeler = state.fingerMatches
        .map((FingerProfile p) =>
            p.id == profileId ? p.copyWith(metPersonId: kimlik) : p)
        .toList(growable: false);

    final String metin = _meetText(state, profil, iliski);

    GameState next = state.copyWith(
      people: List<Person>.unmodifiable(<Person>[...state.people, kisi]),
      fingerMatches: List<FingerProfile>.unmodifiable(eslesmeler),
      // Flört romantik bir ilişki **değildir**; hikâye işareti yalnızca
      // sevgili olununca konur (D-107).
      storyFlags: state.storyFlags,
      log: List<LifeLogEntry>.unmodifiable(<LifeLogEntry>[
        ...state.log,
        LifeLogEntry(
          age: state.player.age,
          text: 'Finger: $metin',
          category: LogCategory.aile,
        ),
      ]),
    );

    return FingerResult(
      state: next,
      outcome: FingerOutcome(applied: true, text: metin, person: kisi),
    );
  }

  /// Buluşmanın sonucunu **iki tarafın niyetiyle birlikte** anlatır.
  static String _meetText(
    GameState state,
    FingerProfile profil,
    RelationType iliski,
  ) {
    if (iliski == RelationType.flort) {
      return '${profil.firstName} ile buluştunuz. İyi geçti; '
          'görüşmeye devam ediyorsunuz. Henüz "sevgili" demediniz.';
    }
    if (state.fingerIntent == FingerIntent.arkadaslik ||
        profil.intent == FingerIntent.arkadaslik) {
      return '${profil.firstName} ile buluştunuz. İkinizden biri '
          'şimdilik arkadaşlık arıyordu; arkadaş kaldınız.';
    }
    return '${profil.firstName} ile buluştunuz. Hayatında zaten biri '
        'olduğu için arkadaş kaldınız.';
  }

  /// Flörtü sevgiliye çevirir (D-107).
  ///
  /// Kendiliğinden olmaz: oyuncu **isteyecek** ve karşı tarafın yakınlığı
  /// yeterli olacak. Hayatında biri varken flört sevgiliye dönüşmez.
  static FingerResult makeOfficial(GameState state, String personId) {
    final Person? kisi = state.personById(personId);
    if (kisi == null || kisi.relation != RelationType.flort) {
      return FingerResult(
        state: state,
        outcome: const FingerOutcome(
          applied: false,
          text: 'Böyle bir flörtün yok.',
        ),
      );
    }
    if (!kisi.isAlive) {
      return FingerResult(
        state: state,
        outcome: const FingerOutcome(applied: false, text: 'Artık mümkün değil.'),
      );
    }
    const Romance romance = Romance();
    if (romance.hasPartner(state) || state.marriage != null) {
      return FingerResult(
        state: state,
        outcome: const FingerOutcome(
          applied: false,
          text: 'Hayatında zaten biri var.',
        ),
      );
    }
    if (kisi.bond < prototypeOnlyOfficialBond) {
      return FingerResult(
        state: state,
        outcome: FingerOutcome(
          applied: false,
          text: '${kisi.firstName} henüz o kadar yakın hissetmiyor. '
              'Biraz daha vakit geçirmeniz gerekiyor '
              '(yakınlık $prototypeOnlyOfficialBond olmalı, '
              'şu an ${kisi.bond}).',
        ),
      );
    }

    final Person yeni = kisi.copyWith(relation: RelationType.sevgili);
    final String metin = '${kisi.firstName} ile artık sevgilisiniz.';
    final GameState next = state.copyWith(
      people: List<Person>.unmodifiable(
        state.people.map((Person p) => p.id == personId ? yeni : p),
      ),
      storyFlags: <String>{...state.storyFlags, StoryFlags.romantikIliskide},
      log: List<LifeLogEntry>.unmodifiable(<LifeLogEntry>[
        ...state.log,
        LifeLogEntry(
          age: state.player.age,
          text: metin,
          category: LogCategory.aile,
        ),
      ]),
    );
    return FingerResult(
      state: next,
      outcome: FingerOutcome(applied: true, text: metin, person: yeni),
    );
  }

  /// prototypeOnly: flörtün sevgiliye dönmesi için gereken yakınlık.
  static const int prototypeOnlyOfficialBond = 60;

  /// prototypeOnly: ilgilenilmeyen flörtün bittiği yakınlık (D-122).
  ///
  /// Faho bildirdi: "ilgilenilmeyen flört bitsin ve pop-up olarak
  /// bildirilsin". Flört bir söz değildir; ilgilenilmezse karşı taraf
  /// bekleyip durmaz. **Kayıt silinmez**: kişi arkadaş olarak kalır,
  /// geçmişi durur.
  static const int prototypeOnlyFlirtEndBond = 35;

  /// prototypeOnly: flörtün bitmesi için geçmesi gereken en az sessiz yıl.
  static const int prototypeOnlyFlirtEndYears = 2;

  /// İlgilenilmeyen flörtler biter (D-122).
  ///
  /// Bitmesi için **iki koşul birden** gerekir: yakınlığın eşiğin altına
  /// düşmesi ve üstünden en az iki yıl geçmiş olması. Böylece bir yıl
  /// yoğun geçen oyuncunun flörtü aniden kopmaz.
  static ({GameState state, List<PendingNotice> notices}) endNeglectedFlirts(
    GameState state,
    int newAge,
  ) {
    final List<PendingNotice> bildirimler = <PendingNotice>[];
    final List<Person> guncel = <Person>[];
    for (final Person p in state.people) {
      if (p.relation != RelationType.flort || !p.isAlive) {
        guncel.add(p);
        continue;
      }
      final int? sonTemas = state.lastInteractionAge[p.id];
      final int sessizYil = sonTemas == null ? 0 : newAge - sonTemas;
      if (p.bond >= prototypeOnlyFlirtEndBond ||
          sessizYil < prototypeOnlyFlirtEndYears) {
        guncel.add(p);
        continue;
      }
      // Kayıt silinmez; bağ arkadaşlığa döner.
      final Person biten = p.copyWith(relation: RelationType.arkadas);
      guncel.add(biten);
      final String metin = '${p.firstName} ile aranız açıldı. Uzun '
          'süredir görüşmüyordunuz; flörtünüz bitti. Arkadaş olarak '
          'kaldınız.';
      bildirimler.add(
        PendingNotice(
          id: 'flort-bitti-${p.id}-$newAge',
          kind: NoticeKind.aileDonum,
          age: newAge,
          title: 'Flörtün bitti',
          text: metin,
          personId: p.id,
        ),
      );
    }
    if (bildirimler.isEmpty) return (state: state, notices: bildirimler);
    return (
      state: state.copyWith(people: List<Person>.unmodifiable(guncel)),
      notices: bildirimler,
    );
  }

  /// Arkadaşa çıkma teklif etmek için gereken en az yakınlık (D-112).
  ///
  /// Sevgili olmaktan düşüktür: önce flört, sonra sevgili.
  static const int prototypeOnlyAskOutBond = 50;

  /// Flörtü sevgiliye çevirmenin **önceden görünen** koşulu (D-112).
  ///
  /// Faho bildirdi: "nasıl sevgili olacağım... ilerisi yok". Koşul
  /// yalnızca düğmeye basınca yazıyordu; artık kart açıldığında da
  /// okunuyor ve kaç yakınlık gerektiği ile şu anki yakınlık birlikte
  /// görünüyor (D-063: hiçbir seçenek sebepsiz pasif kalmaz).
  static InteractionAvailability officialAvailability(
    GameState state,
    String personId,
  ) {
    final Person? kisi = state.personById(personId);
    if (kisi == null || kisi.relation != RelationType.flort) {
      return const InteractionAvailability.blocked('Böyle bir flörtün yok.');
    }
    if (!kisi.isAlive) {
      return const InteractionAvailability.blocked('Artık mümkün değil.');
    }
    const Romance romance = Romance();
    if (romance.hasPartner(state) || state.marriage != null) {
      return const InteractionAvailability.blocked('Hayatında zaten biri var.');
    }
    if (kisi.bond < prototypeOnlyOfficialBond) {
      return InteractionAvailability.blocked(
        'Yakınlık $prototypeOnlyOfficialBond olmalı, şu an ${kisi.bond}. '
        'Birlikte vakit geçirdikçe artar.',
      );
    }
    return const InteractionAvailability.allowed();
  }

  /// Arkadaşa çıkma teklif edilebilir mi? (D-112)
  ///
  /// Finger'da tanışılan herkes flört olmuyor: iki taraftan biri
  /// arkadaşlık arıyorsa arkadaş kalınıyor (D-107). Bu, ilişkinin
  /// **sonu** değildir; arkadaşlık zamanla başka bir şeye dönüşebilir.
  static InteractionAvailability askOutAvailability(
    GameState state,
    String personId,
  ) {
    final Person? kisi = state.personById(personId);
    if (kisi == null || kisi.relation != RelationType.arkadas) {
      return const InteractionAvailability.blocked(
        'Bu kişiye çıkma teklif edilemez.',
      );
    }
    if (!kisi.isAlive) {
      return const InteractionAvailability.blocked('Artık mümkün değil.');
    }
    const Romance romance = Romance();
    if (romance.hasPartner(state) || state.marriage != null) {
      return const InteractionAvailability.blocked('Hayatında zaten biri var.');
    }
    if (state.player.age < 16 || kisi.age < 16) {
      return const InteractionAvailability.blocked(
        'Bu yaşta böyle bir teklif yapılmaz.',
      );
    }
    if (kisi.bond < prototypeOnlyAskOutBond) {
      return InteractionAvailability.blocked(
        'Yakınlık $prototypeOnlyAskOutBond olmalı, şu an ${kisi.bond}. '
        'Birlikte vakit geçirdikçe artar.',
      );
    }
    return const InteractionAvailability.allowed();
  }

  /// Arkadaşa çıkma teklif eder; kabul edilirse flört başlar (D-112).
  ///
  /// Teklif **garanti değildir**: karşı taraf yakınlığa bağlı bir olasılıkla
  /// kabul eder. Reddedilirse ilişki arkadaşlıkta kalır ve yakınlık bir
  /// miktar düşer — teklif etmek bedelsiz değildir.
  static FingerResult askOut(GameState state, String personId, Random rng) {
    final InteractionAvailability uygun = askOutAvailability(state, personId);
    if (!uygun.isAllowed) {
      return FingerResult(
        state: state,
        outcome: FingerOutcome(applied: false, text: uygun.reason ?? 'Şu an mümkün değil.'),
      );
    }
    final Person kisi = state.personById(personId)!;

    // Kabul şansı yakınlıkla artar: 50 yakınlıkta %40, 100'de %90.
    final int sans = 40 + ((kisi.bond - prototypeOnlyAskOutBond) * 1).round();
    final bool kabul = rng.nextInt(100) < sans.clamp(40, 90);

    if (!kabul) {
      final Person soguk =
          kisi.copyWith(bond: (kisi.bond - 6).clamp(0, 100));
      final String ret = '${kisi.firstName} teklifini kibarca geri çevirdi. '
          'Arkadaş kaldınız.';
      return FingerResult(
        state: _replace(state, soguk, ret),
        outcome: FingerOutcome(applied: true, text: ret, person: soguk),
      );
    }

    final Person yeni = kisi.copyWith(relation: RelationType.flort);
    final String metin = '${kisi.firstName} teklifini kabul etti. '
        'Artık flört ediyorsunuz.';
    return FingerResult(
      state: _replace(state, yeni, metin),
      outcome: FingerOutcome(applied: true, text: metin, person: yeni),
    );
  }

  /// Kişiyi yerine koyar ve hayat günlüğüne satır düşer.
  static GameState _replace(GameState state, Person kisi, String metin) =>
      state.copyWith(
        people: List<Person>.unmodifiable(
          state.people.map((Person p) => p.id == kisi.id ? kisi : p),
        ),
        log: List<LifeLogEntry>.unmodifiable(<LifeLogEntry>[
          ...state.log,
          LifeLogEntry(
            age: state.player.age,
            text: metin,
            category: LogCategory.aile,
          ),
        ]),
      );

  // --- İç işler ---------------------------------------------------------

  static FingerProfile? _fromDeck(GameState state, String id) {
    for (final FingerProfile p in state.fingerDeck) {
      if (p.id == id) return p;
    }
    return null;
  }

  static FingerProfile? _fromMatches(GameState state, String id) {
    for (final FingerProfile p in state.fingerMatches) {
      if (p.id == id) return p;
    }
    return null;
  }

  /// Profili desteden çıkarır ve yıllık sayacı işler.
  static GameState _consume(GameState state, String profileId) =>
      state.copyWith(
        fingerDeck: List<FingerProfile>.unmodifiable(
          state.fingerDeck
              .where((FingerProfile p) => p.id != profileId)
              .toList(growable: false),
        ),
        interactionCounts: Map<String, int>.unmodifiable(<String, int>{
          ...state.interactionCounts,
          GameState.interactionKey('finger', 'kaydirma'):
              swipesThisAge(state) + 1,
        }),
      );

  static int _nextIndex(GameState state) {
    int enBuyuk = 0;
    for (final FingerProfile p in <FingerProfile>[
      ...state.fingerDeck,
      ...state.fingerMatches,
    ]) {
      final int? n = int.tryParse(p.id.split('-').last);
      if (n != null && n > enBuyuk) enBuyuk = n;
    }
    return enBuyuk + 1;
  }

  static String _nextPersonId(GameState state) {
    final Set<String> mevcut = <String>{
      for (final Person p in state.people) p.id,
    };
    int n = 1;
    while (mevcut.contains('finger-$n')) {
      n++;
    }
    return 'finger-$n';
  }

  /// prototypeOnly: profil üretimi.
  ///
  /// Karşı cinsten profil gösterilir. **Bu bir oyun tasarımı kararı
  /// değildir**; yönelim ve eşleşme kuralları Faho ile kararlaştırılacak
  /// (`Romance.start` ile aynı geçici varsayım).
  /// prototypeOnly: aday profillerin varlık dağılımı.
  ///
  /// Gerçek hayatta olduğu gibi orta kademe en kalabalıktır.
  static const Map<WealthTier, double> prototypeOnlyWealthWeights =
      <WealthTier, double>{
    WealthTier.cokYoksul: 0.06,
    WealthTier.yoksul: 0.16,
    WealthTier.ortaHalli: 0.50,
    WealthTier.varlikli: 0.22,
    WealthTier.cokVarlikli: 0.06,
  };

  static FingerIntent _rollIntent(Random rng) =>
      _weightedPick(kFingerIntentWeights, rng);

  static WealthTier _rollWealth(Random rng) =>
      _weightedPick(prototypeOnlyWealthWeights, rng);

  static T _weightedPick<T>(Map<T, double> weights, Random rng) {
    final double toplam = weights.values.fold<double>(0, (double a, double b) => a + b);
    double kalan = rng.nextDouble() * toplam;
    for (final MapEntry<T, double> e in weights.entries) {
      kalan -= e.value;
      if (kalan <= 0) return e.key;
    }
    return weights.keys.last;
  }

  static FingerProfile _uret(GameState state, Random rng, int index) {
    final Gender gender =
        state.player.gender == Gender.kadin ? Gender.erkek : Gender.kadin;
    // Yaş **oyuncunun bandından** seçilir (D-081): 47 yaşındakine 17
    // yaşında biri çıkmaz.
    final int alt = minCandidateAge(state.player.age);
    final int ust = maxCandidateAge(state.player.age);
    final int age = ust <= alt ? alt : alt + rng.nextInt(ust - alt + 1);
    final bool calisiyor = age > 23 || rng.nextDouble() < 0.4;

    final Set<String> ilgiler = <String>{};
    final int kacIlgi = rng.between(2, 4);
    while (ilgiler.length < kacIlgi) {
      ilgiler.add(rng.pick(kFingerInterests));
    }

    return FingerProfile(
      id: 'finger-profil-$index',
      firstName:
          rng.pick(gender == Gender.kadin ? kadinIsimleri : erkekIsimleri),
      lastName: rng.pick(soyisimler),
      gender: gender,
      age: age,
      city: state.player.currentCity,
      bio: rng.pick(kFingerBios),
      interests: List<String>.unmodifiable(ilgiler),
      occupation: calisiyor ? rng.pick(meslekler) : null,
      // Herkes aynı şeyi aramaz (D-107).
      intent: _rollIntent(rng),
      // Süzgeç açıksa üretilen aday da ona uyar; yoksa uygulama
      // oyuncuya hiç uygun profil göstermezdi.
      wealth: state.fingerWealthFilter ?? _rollWealth(rng),
    );
  }
}

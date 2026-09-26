/// Arkadaşlığın derinliği (D-130).
///
/// **Ölçülen sorun:** 60 hayatta 1.141 sınıf arkadaşı kaydı üretiliyor ama
/// yalnızca 30'u arkadaşlığa dönüyordu; hayatların **34/60'ında hiç
/// arkadaş yoktu** ve hiçbir hayat yakın arkadaşla (yakınlık 60+)
/// bitmiyordu. Sebep tek: oyuncunun bir tanıdığı arkadaş yapmak için
/// **hiçbir düğmesi yoktu** — arkadaşlık yalnızca rastgele bir olay
/// çıkarsa kuruluyordu.
///
/// Bu dosya dört şey ekler:
/// 1. **Yakın arkadaş olma teklifi** — oyuncu kendi başlatır, kabul
///    garanti değildir.
/// 2. **Küslük** — arkadaşlık yalnızca yukarı gitmez.
/// 3. **Barışma** — küslük kalıcı değildir; kayıt silinmez.
/// 4. **Arkadaşın kendi hayatı** — taşınır, evlenir, iş değiştirir, zor
///    gün geçirir.
///
/// Bütün sayılar `prototypeOnly`'dir (Q-144).
library;

import 'dart:math';

import '../../data/city_catalog.dart';
import '../models/game_state.dart';
import '../models/interaction.dart';
import '../models/life_log.dart';
import '../models/pending_notice.dart';
import '../models/person.dart';
import '../models/relation.dart';

/// Bir arkadaşlık hamlesinin sonucu.
class FriendshipOutcome {
  const FriendshipOutcome({
    required this.applied,
    required this.text,
    this.accepted = false,
  });

  final bool applied;
  final String text;

  /// Teklif kabul edildi mi? Reddedilen teklif de `applied` sayılır:
  /// gerçekten yaşandı ve bedeli oldu.
  final bool accepted;
}

class FriendshipResult {
  const FriendshipResult({required this.state, required this.outcome});

  final GameState state;
  final FriendshipOutcome outcome;
}

/// Arkadaşlığın derinleşmesi, küslük ve barışma.
abstract final class FriendshipDepth {
  /// prototypeOnly: yakın arkadaşlık teklifi için gereken en az yakınlık.
  static const int prototypeOnlyCloseFriendBond = 55;

  /// prototypeOnly: teklif reddedilirse kaybedilen yakınlık.
  static const int prototypeOnlyRefusalCost = 8;

  /// prototypeOnly: barışma için gereken en az yakınlık.
  static const int prototypeOnlyMakeUpBond = 12;

  /// prototypeOnly: küsmenin eşiği — yakınlık bunun altına inerse
  /// arkadaşlık kopabilir.
  static const int prototypeOnlyFalloutBond = 18;

  /// prototypeOnly: küsme için geçmesi gereken en az ilgisizlik yılı.
  static const int prototypeOnlyNeglectYears = 3;

  /// prototypeOnly: barışmanın kazandırdığı yakınlık.
  static const int prototypeOnlyMakeUpGain = 14;

  // ===================================================================
  // 1) Yakın arkadaş olma teklifi
  // ===================================================================

  /// Bu kişiye yakın arkadaşlık teklif edilebilir mi?
  ///
  /// Gerekçe **her zaman** yazılır; sahte düğme gösterilmez (D-063).
  static InteractionAvailability closeFriendAvailability(
    GameState state,
    String personId,
  ) {
    final Person? kisi = state.personById(personId);
    if (kisi == null) {
      return const InteractionAvailability.blocked('Bu kişi kayıtlarda yok.');
    }
    if (!kisi.isAlive) {
      return const InteractionAvailability.blocked('Artık mümkün değil.');
    }
    if (kisi.isEstranged) {
      return const InteractionAvailability.blocked(
        'Aranız bozuk. Önce barışmanız gerekiyor.',
      );
    }
    // Yalnızca tanışıklık düzeyindeki ilişkiler arkadaşlığa dönüşür.
    const Set<RelationType> uygun = <RelationType>{
      RelationType.sinifArkadasi,
      RelationType.isArkadasi,
    };
    if (!uygun.contains(kisi.relation)) {
      return InteractionAvailability.blocked(
        kisi.relation == RelationType.arkadas
            ? 'Zaten yakın arkadaşsınız.'
            : 'Bu ilişki arkadaşlığa dönüşmez.',
      );
    }
    if (kisi.bond < prototypeOnlyCloseFriendBond) {
      return InteractionAvailability.blocked(
        'Yakınlık $prototypeOnlyCloseFriendBond olmalı, şu an ${kisi.bond}. '
        'Birlikte vakit geçirdikçe artar.',
      );
    }
    return const InteractionAvailability.allowed();
  }

  /// Yakın arkadaşlık teklif eder.
  ///
  /// **Kabul garanti değildir**: şans yakınlıkla artar. Reddedilirse
  /// yakınlık düşer — teklif etmek bedelsiz değildir (D-112 ile aynı
  /// ilke).
  static FriendshipResult proposeCloseFriend({
    required GameState state,
    required String personId,
    required Random rng,
  }) {
    final InteractionAvailability uygun =
        closeFriendAvailability(state, personId);
    if (!uygun.isAllowed) {
      return FriendshipResult(
        state: state,
        outcome: FriendshipOutcome(
          applied: false,
          text: uygun.reason ?? 'Şu an mümkün değil.',
        ),
      );
    }
    final Person kisi = state.personById(personId)!;

    // 55 yakınlıkta %45, 100'de %90.
    final int sans =
        (45 + (kisi.bond - prototypeOnlyCloseFriendBond)).clamp(45, 90);
    final bool kabul = rng.nextInt(100) < sans;

    if (!kabul) {
      final Person soguyan = kisi.copyWith(
        bond: (kisi.bond - prototypeOnlyRefusalCost).clamp(0, 100),
      );
      final String metin = '${kisi.firstName} bir an durdu, sonra konuyu '
          'değiştirdi. Anladın.';
      GameState next = _replace(state, soguyan);
      next = _log(next, metin, personId: kisi.id);
      return FriendshipResult(
        state: next,
        outcome: FriendshipOutcome(applied: true, text: metin),
      );
    }

    final Person arkadas = kisi.copyWith(
      relation: RelationType.arkadas,
      becameFriendAtAge: state.player.age,
      bond: (kisi.bond + 6).clamp(0, 100),
    );
    final String metin = _kabulMetni(kisi);
    GameState next = _replace(state, arkadas);
    next = _log(next, metin, personId: kisi.id);
    next = next.queueNotice(
      PendingNotice(
        id: 'arkadas-${kisi.id}-${state.player.age}',
        kind: NoticeKind.arkadaslik,
        age: state.player.age,
        title: 'Artık arkadaşsınız',
        text: metin,
        personId: kisi.id,
      ),
    );
    return FriendshipResult(
      state: next,
      outcome: FriendshipOutcome(applied: true, text: metin, accepted: true),
    );
  }

  static String _kabulMetni(Person kisi) {
    switch (kisi.relation) {
      case RelationType.sinifArkadasi:
        return 'Okul çıkışı beklemeye başladınız birbirinizi. '
            '${kisi.firstName} artık "biz" diyor.';
      case RelationType.isArkadasi:
        return 'Mesai bitti, ikiniz de çıkmadınız. '
            '${kisi.firstName} ile artık iş dışında da görüşüyorsunuz.';
      default:
        return '${kisi.firstName} ile aranız iş kolaylığından çıktı. '
            'Artık arkadaşsınız.';
    }
  }

  // ===================================================================
  // 2) Barışma
  // ===================================================================

  /// Küs olan biriyle barışılabilir mi?
  static InteractionAvailability makeUpAvailability(
    GameState state,
    String personId,
  ) {
    final Person? kisi = state.personById(personId);
    if (kisi == null) {
      return const InteractionAvailability.blocked('Bu kişi kayıtlarda yok.');
    }
    if (!kisi.isAlive) {
      return const InteractionAvailability.blocked(
        'Barışmak için artık çok geç.',
      );
    }
    if (!kisi.isEstranged) {
      return const InteractionAvailability.blocked('Aranızda bir sorun yok.');
    }
    // Aynı yıl hem kavga hem barış olmaz; üzerinden bir yıl geçmeli.
    if (state.player.age <= kisi.estrangedSinceAge!) {
      return const InteractionAvailability.blocked(
        'Şu an çok taze. Biraz zaman geçmesi gerekiyor.',
      );
    }
    if (kisi.bond < prototypeOnlyMakeUpBond) {
      return InteractionAvailability.blocked(
        'Geriye o kadar da bir şey kalmamış (yakınlık ${kisi.bond}). '
        'Barışmak için en az $prototypeOnlyMakeUpBond gerekiyor.',
      );
    }
    return const InteractionAvailability.allowed();
  }

  /// Barışma denemesi. Kabul garanti değildir.
  static FriendshipResult makeUp({
    required GameState state,
    required String personId,
    required Random rng,
  }) {
    final InteractionAvailability uygun = makeUpAvailability(state, personId);
    if (!uygun.isAllowed) {
      return FriendshipResult(
        state: state,
        outcome: FriendshipOutcome(
          applied: false,
          text: uygun.reason ?? 'Şu an mümkün değil.',
        ),
      );
    }
    final Person kisi = state.personById(personId)!;
    final int gecenYil = state.player.age - kisi.estrangedSinceAge!;

    // Kalan yakınlık ve geçen zaman iyi geliyor; ısrar değil.
    final int sans = (35 + kisi.bond ~/ 2 + gecenYil * 3).clamp(35, 88);
    final bool oldu = rng.nextInt(100) < sans;

    if (!oldu) {
      final String metin = '${kisi.firstName} telefonu açtı ama konuşma '
          'kısa sürdü. "Şimdi olmaz" dedi.';
      GameState next = _log(state, metin, personId: kisi.id);
      return FriendshipResult(
        state: next,
        outcome: FriendshipOutcome(applied: true, text: metin),
      );
    }

    final Person barisan = kisi.copyWith(
      estrangedSinceAge: null,
      bond: (kisi.bond + prototypeOnlyMakeUpGain).clamp(0, 100),
    );
    final String metin = gecenYil >= 5
        ? '${kisi.firstName} ile $gecenYil yıl sonra karşı karşıya '
            'oturdunuz. İlk beş dakika zor geçti, sonrası kolay.'
        : '${kisi.firstName} "boş yapmışız ikimiz de" dedi. '
            'Konuyu bir daha açmadınız.';
    GameState next = _replace(state, barisan);
    next = _log(next, metin, personId: kisi.id);
    next = next.queueNotice(
      PendingNotice(
        id: 'baris-${kisi.id}-${state.player.age}',
        kind: NoticeKind.arkadaslik,
        age: state.player.age,
        title: 'Barıştınız',
        text: metin,
        personId: kisi.id,
      ),
    );
    return FriendshipResult(
      state: next,
      outcome: FriendshipOutcome(applied: true, text: metin, accepted: true),
    );
  }

  // ===================================================================
  // 3) Yıllık ilerleme: küslük ve arkadaşın kendi hayatı
  // ===================================================================

  /// Arkadaşlıkların yılını işler.
  ///
  /// İki şey olur: uzun süre ilgilenilmeyen arkadaşlık **kopabilir**, ve
  /// arkadaşın kendi hayatında bir şey olur. İkisi de seyrektir; her yıl
  /// herkesin başına bir şey gelmez.
  static GameState advanceYear(GameState state, int newAge, Random rng) {
    GameState next = _maybeFallout(state, newAge, rng);
    next = _maybeFriendNews(next, newAge, rng);
    return next;
  }

  /// İlgilenilmeyen arkadaşlık kopar.
  ///
  /// **Kayıt silinmez:** kişi listede kalır, ilişkisi arkadaş kalır;
  /// yalnızca küs işareti konur ve barış kapısı açılır.
  static GameState _maybeFallout(GameState state, int newAge, Random rng) {
    final List<Person> adaylar = state.people
        .where(
          (Person p) =>
              p.isAlive &&
              p.relation == RelationType.arkadas &&
              !p.isEstranged &&
              p.bond <= prototypeOnlyFalloutBond &&
              _ilgisizYil(state, p.id) >= prototypeOnlyNeglectYears,
        )
        .toList(growable: false);
    if (adaylar.isEmpty) return state;
    // Yılda en fazla bir arkadaşlık kopar; hayat topluca boşalmaz.
    if (rng.nextDouble() > 0.45) return state;

    final Person kisi = adaylar[rng.nextInt(adaylar.length)];
    final Person kus = kisi.copyWith(estrangedSinceAge: newAge);
    final String metin = _kopmaMetni(kisi, rng);
    GameState next = _replace(state, kus);
    next = _log(next, metin, personId: kisi.id, age: newAge);
    return next.queueNotice(
      PendingNotice(
        id: 'kusluk-${kisi.id}-$newAge',
        kind: NoticeKind.arkadaslik,
        age: newAge,
        title: 'Araya mesafe girdi',
        text: metin,
        personId: kisi.id,
      ),
    );
  }

  static String _kopmaMetni(Person kisi, Random rng) {
    final List<String> secenekler = <String>[
      '${kisi.firstName} ile en son ne zaman konuştuğunuzu '
          'hatırlamıyorsun. O da aramıyor artık.',
      '${kisi.firstName} bir şeye alındı, sen de üstüne gitmedin. '
          'Öyle kaldı.',
      'Ortak bir tanıdık "${kisi.firstName} seni soruyordu" dedi. '
          'Sormak da aramak değil.',
    ];
    return secenekler[rng.nextInt(secenekler.length)];
  }

  /// Arkadaşın kendi hayatında bir şey olur.
  ///
  /// Haber **gerçekten kayda geçer**: taşınan arkadaşın şehri değişir,
  /// evlenen arkadaşın kaydına yazılır. Uydurma haber üretilmez.
  /// prototypeOnly: aynı kişiden yeniden haber gelmesi için gereken yıl.
  ///
  /// **Faho bildirdi:** "yakın arkadaş ile alakalı aynı bildirimler çok
  /// fazla geliyor! Ahmet her sene iş değiştiriyor ve sesi çok iyi
  /// geliyor mesela." Sebep ikiydi: (1) hiçbir bekleme süresi yoktu,
  /// aynı kişi arka arkaya seçilebiliyordu; (2) her haber türünün tek
  /// bir metni vardı, yani aynı cümle birebir tekrar ediyordu.
  static const int prototypeOnlyAnyNewsCooldown = 3;

  /// prototypeOnly: **aynı türden** haberin tekrarı için gereken yıl.
  ///
  /// Bir arkadaş sekiz yılda bir iş değiştirebilir; her yıl değiştirmez.
  static const int prototypeOnlySameNewsCooldown = 8;

  static GameState _maybeFriendNews(GameState state, int newAge, Random rng) {
    final List<Person> arkadaslar = state.people
        .where(
          (Person p) =>
              p.isAlive &&
              p.relation == RelationType.arkadas &&
              !p.isEstranged &&
              // Bu kişiden yakın zamanda haber geldiyse sırası değil.
              _haberAralikta(
                state,
                newAge,
                state.friendNewsAt(p.id),
                prototypeOnlyAnyNewsCooldown,
              ),
        )
        .toList(growable: false);
    if (arkadaslar.isEmpty) return state;
    // prototypeOnly: yılda %28 ihtimalle bir arkadaştan haber gelir.
    if (rng.nextDouble() > 0.28) return state;

    final Person kisi = arkadaslar[rng.nextInt(arkadaslar.length)];
    final List<_FriendNewsKind> mumkun = <_FriendNewsKind>[
      if (kisi.city != null && kisi.age >= 18) _FriendNewsKind.tasindi,
      if (kisi.age >= 22 && kisi.age <= 45) _FriendNewsKind.evlendi,
      if (kisi.age >= 20 && kisi.age < 65) _FriendNewsKind.isDegisti,
      _FriendNewsKind.zorGun,
    ]
        // Aynı haber aynı kişiden kısa aralıkla gelmez.
        .where(
          (_FriendNewsKind k) => _haberAralikta(
            state,
            newAge,
            state.friendNewsAtKind(kisi.id, k.name),
            prototypeOnlySameNewsCooldown,
          ),
        )
        .toList(growable: false);
    if (mumkun.isEmpty) return state;
    final _FriendNewsKind tur = mumkun[rng.nextInt(mumkun.length)];

    switch (tur) {
      case _FriendNewsKind.tasindi:
        final List<String> sehirler = kCityProfiles
            .map((CityProfile c) => c.name)
            .where((String ad) => ad != kisi.city)
            .toList(growable: false);
        if (sehirler.isEmpty) return state;
        final String yeni = sehirler[rng.nextInt(sehirler.length)];
        final Person tasinan = kisi.copyWith(
          city: yeni,
          // Uzaklık yakınlığı bir miktar zorlar; koparmaz.
          bond: (kisi.bond - 4).clamp(0, 100),
        );
        final String metin = _sec(rng, <String>[
          '${kisi.firstName} $yeni\'ye taşındı. "Gel bir ara" dedi, '
              'ikiniz de bunun kolay olmadığını biliyorsunuz.',
          '${kisi.firstName} işi gereği $yeni\'ye gitti. Eşyaları '
              'kamyonete sığmış, veda telefonda kalmış.',
          '${kisi.firstName} artık $yeni\'de. Haritada bakıp "yakınmış '
              'aslında" dedin, değil.',
        ]);
        return _haber(state, tasinan, metin, newAge, tur.name);

      case _FriendNewsKind.evlendi:
        final Person evlenen = kisi.copyWith(bond: (kisi.bond + 2).clamp(0, 100));
        final String metin = _sec(rng, <String>[
          '${kisi.firstName} evlendi. Düğünde fotoğrafa girerken seni '
              'de çektiler.',
          '${kisi.firstName} evlendi. Salonun kapısında seni görünce '
              'gelinliğin eteğini toplayıp koştu.',
          '${kisi.firstName} evlendi. Davetiye elden geldi, altında '
              '"gelmezsen küserim" yazıyordu.',
        ]);
        return _haber(state, evlenen, metin, newAge, tur.name);

      case _FriendNewsKind.isDegisti:
        final Person calisan = kisi.copyWith(bond: (kisi.bond + 1).clamp(0, 100));
        final String metin = _sec(rng, <String>[
          '${kisi.firstName} iş değiştirdi. Sesi telefonda uzun '
              'zamandır bu kadar iyi değildi.',
          '${kisi.firstName} yeni bir işe girdi. "Bu sefer tutar" '
              'diyor, sen de inanmak istiyorsun.',
          '${kisi.firstName} işten ayrılmış, yenisini bulmuş. '
              'Ayrıntıyı anlatmadı, sen de sormadın.',
        ]);
        return _haber(state, calisan, metin, newAge, tur.name);

      case _FriendNewsKind.zorGun:
        // Zor gün: arkadaş yardım ister. Yardım etmek bir olay değil,
        // burada yalnızca haber verilir; oyuncu isterse gider.
        final Person zorda = kisi.copyWith(
          happiness: (kisi.happiness - 10).clamp(0, 100),
        );
        final String metin = _sec(rng, <String>[
          '${kisi.firstName} aradı. Sesinden belli, işler iyi gitmiyor. '
              '"Bir ara görüşelim mi" dedi.',
          '${kisi.firstName} uzun bir mesaj attı, sonra sildi. Kalanı '
              '"boş ver, geçer" idi.',
          '${kisi.firstName} ile karşılaştınız. Hâl hatır sorarken '
              'gözü başka yerdeydi.',
        ]);
        return _haber(state, zorda, metin, newAge, tur.name);
    }
  }

  /// Bu haber için bekleme süresi doldu mu? Hiç gelmediyse doludur.
  static bool _haberAralikta(
    GameState state,
    int newAge,
    int? sonYas,
    int aralik,
  ) =>
      sonYas == null || newAge - sonYas >= aralik;

  static String _sec(Random rng, List<String> secenekler) =>
      secenekler[rng.nextInt(secenekler.length)];

  static GameState _haber(
    GameState state,
    Person guncel,
    String metin,
    int newAge,
    String etiket,
  ) {
    GameState next = _replace(state, guncel).copyWith(
      // D-149: hem "bu kişiden", hem "bu haber" sayacı işlenir.
      friendNewsLastAge: <String, int>{
        ...state.friendNewsLastAge,
        guncel.id: newAge,
        '${guncel.id}|$etiket': newAge,
      },
    );
    next = _log(next, metin, personId: guncel.id, age: newAge);
    return next.queueNotice(
      PendingNotice(
        id: 'arkadas-haber-$etiket-${guncel.id}-$newAge',
        kind: NoticeKind.arkadaslik,
        age: newAge,
        title: 'Arkadaşından haber',
        text: metin,
        personId: guncel.id,
      ),
    );
  }

  // ===================================================================
  // Yardımcılar
  // ===================================================================

  /// Bu kişiyle en son ne zaman etkileşim kuruldu? Hiç kurulmadıysa
  /// oyuncunun yaşı kadar yıl sayılır.
  static int _ilgisizYil(GameState state, String personId) {
    int? enSon;
    for (final MapEntry<String, int> e in state.lastInteractionAge.entries) {
      if (!e.key.startsWith('$personId|')) continue;
      if (enSon == null || e.value > enSon) enSon = e.value;
    }
    if (enSon == null) return state.player.age;
    return state.player.age - enSon;
  }

  static GameState _replace(GameState state, Person kisi) => state.copyWith(
        people: List<Person>.unmodifiable(
          state.people
              .map((Person p) => p.id == kisi.id ? kisi : p)
              .toList(growable: false),
        ),
      );

  static GameState _log(
    GameState state,
    String metin, {
    String? personId,
    int? age,
  }) =>
      state.copyWith(
        log: List<LifeLogEntry>.unmodifiable(<LifeLogEntry>[
          ...state.log,
          LifeLogEntry(
            age: age ?? state.player.age,
            text: metin,
            category: LogCategory.kisisel,
            personId: personId,
          ),
        ]),
      );
}

enum _FriendNewsKind { tasindi, evlendi, isDegisti, zorGun }

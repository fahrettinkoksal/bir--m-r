/// Yetişkin çocuğun **evlilik hayatı**: boşanma, yeniden evlilik, dulluk
/// (Paket AP, §19-§23, §50).
///
/// **Neyi düzeltiyor.** Paket AP/1'e kadar çocuğun evliliği bir kez
/// kurulup sonsuza kadar sürüyordu: `marriedAtAge != null` ise kişi
/// ömrünün sonuna dek "evli"ydi. Gerçek hayatta öyle değil ve oyunun
/// aile ağacı bundan zarar görüyordu — torunun iki ebeveyni vardı ama o
/// evliliğin bir tarihi yoktu.
///
/// **Neyi yapmıyor.** Oyuncunun kendi evlilik motorunu ([MarriageEngine])
/// ikinci kez yazmıyor; mal paylaşımı, nafaka ve velayet NPC tarafında
/// modellenmiyor. Burada tutulan şey kaydın doğruluğu: kim kiminle, ne
/// zaman, nasıl bitti.
///
/// **Değişmeyen üç şey:**
///
/// 1. Eski eş **silinmez** (§21). Bağı [RelationType.eskiCocugunEsi]
///    olur, kaydı listede kalır.
/// 2. Torunun soy bağı **değişmez** (§22). Boşanma `motherId` /
///    `fatherId` alanlarına dokunmaz; yeni eş otomatik biyolojik
///    ebeveyn **olmaz**.
/// 3. Yeniden evlenme **yeni** bir kişiyle olur (§23, §54). Aynı Person
///    ikinci kez eş yapılmaz.
///
/// Bütün sayılar `prototypeOnly`'dir; karar soruları Q-188'de.
library;

import 'dart:math';

import '../models/game_state.dart';
import '../models/npc_marriage.dart';
import '../models/pending_notice.dart';
import '../models/person.dart';
import '../models/person_development.dart';
import '../models/relation.dart';
import 'child_marriage.dart';
import 'random_util.dart';

/// Bir yılın NPC evlilik hareketleri.
typedef ChildMarriageYear = ({
  GameState state,
  List<PendingNotice> notices,
  List<String> logTexts,
});

abstract final class ChildMarriageLife {
  // =================================================================
  // §19 — boşanma
  // =================================================================

  /// prototypeOnly: evliliğin boşanabilmesi için geçmesi gereken en az
  /// yıl. Düğünün ertesi yılı boşanma olmaz.
  static const int prototypeOnlyMinMarriageYears = 2;

  /// prototypeOnly: yıllık boşanma ihtimalinin tabanı.
  static const double prototypeOnlyBaseDivorceChance = 0.018;

  /// prototypeOnly: ihtimalin üst sınırı.
  ///
  /// Düşük tutuldu: §19'un kuralı "her çocuk boşanmasın".
  static const double prototypeOnlyMaxDivorceChance = 0.055;

  /// prototypeOnly: mutsuzluğun ihtimale kattığı en yüksek pay.
  static const double prototypeOnlyUnhappyWeight = 0.030;

  /// prototypeOnly: ekonomik baskının kattığı pay.
  static const double prototypeOnlyMoneyStressWeight = 0.012;

  /// prototypeOnly: "ekonomik baskı" sayılan birikim eşiği (₺).
  static const int prototypeOnlyMoneyStressBelow = 40000;

  /// prototypeOnly: yeniden evlenmek için boşanmadan sonra geçmesi
  /// gereken en az yıl (§23).
  static const int prototypeOnlyRemarryCooldown = 3;

  /// prototypeOnly: yıllık yeniden evlenme ihtimali.
  static const double prototypeOnlyRemarryChance = 0.10;

  /// prototypeOnly: yeniden evlenmenin en büyük yaşı.
  static const int prototypeOnlyRemarryMaxAge = 72;

  /// Bu kişinin evliliği bu yıl bitebilir mi?
  ///
  /// Yalnızca **gerçek kayda** bakar: yürüyen evlilik, evlilik süresi ve
  /// kişinin kendi durumu. Eski kayıtlar (eşi Person olmayan, §17) de
  /// boşanabilir; kayıt isimle korunur.
  static bool canDivorce(Person person, int currentAge) {
    final PersonDevelopment? d = person.development;
    if (d == null || !person.isAlive) return false;
    if (!d.isMarried) return false;
    final int? evlilikYasi = d.marriedAtAge;
    if (evlilikYasi == null) return false;
    return currentAge - evlilikYasi >= prototypeOnlyMinMarriageYears;
  }

  /// Bu yıl boşanma ihtimali.
  ///
  /// §19'un dört girdisi: evlilik süresi, kişinin mutluluğu, ekonomik
  /// baskı ve küçük bir rastgelelik (ihtimalin kendisi zar olarak
  /// atılıyor).
  static double divorceChance(Person person) {
    final PersonDevelopment d = person.development!;
    double oran = prototypeOnlyBaseDivorceChance;

    // Mutsuz insan daha çok ayrılır; mutlu insan neredeyse hiç.
    final int mutluluk = d.stats.happiness;
    if (mutluluk < 50) {
      oran += prototypeOnlyUnhappyWeight * ((50 - mutluluk) / 50);
    }

    // Ekonomik baskı: kendi birikimi yoksa ev içinde gerilim artar.
    if (d.money < prototypeOnlyMoneyStressBelow) {
      oran += prototypeOnlyMoneyStressWeight;
    }

    // Uzun evlilikler daha dayanıklı: her on yıl küçük bir indirim.
    final int yil = (person.age - (d.marriedAtAge ?? person.age)).clamp(0, 60);
    oran -= 0.0008 * yil;

    return oran.clamp(0.0, prototypeOnlyMaxDivorceChance);
  }

  /// Bu yılın boşanmalarını uygular.
  static ChildMarriageYear maybeDivorce(
    GameState state,
    int newAge,
    Random rng,
  ) {
    final List<PendingNotice> bildirimler = <PendingNotice>[];
    final List<String> satirlar = <String>[];
    List<Person> kisiler = state.people;

    for (final Person kisi in state.people) {
      if (!_hasOwnMarriageLife(kisi.relation)) continue;
      if (!canDivorce(kisi, kisi.age)) continue;
      if (!rng.chance(divorceChance(kisi))) continue;

      final PersonDevelopment d = kisi.development!;
      final String esAdi = d.spouseName ?? 'eşi';

      // --- Kayıt: yürüyen evlilik geçmişe taşınır (§18) ---------------
      final PersonDevelopment yeniGelisim = d
          .copyWith(
            marriageStatus: NpcMarriageStatus.bosandi,
            // Yürüyen eş bağı kopuyor; kimlik geçmiş kayıtta duruyor.
            spousePersonId: null,
            pastMarriages: List<NpcMarriageRecord>.unmodifiable(
              <NpcMarriageRecord>[
                ...d.pastMarriages,
                NpcMarriageRecord(
                  spouseName: esAdi,
                  spousePersonId: d.spousePersonId,
                  marriedAtAge: d.marriedAtAge!,
                  endedAtAge: kisi.age,
                  status: NpcMarriageStatus.bosandi,
                ),
              ],
            ),
          )
          .withMilestone(kisi.age, '$esAdi ile boşandı.');

      kisiler = <Person>[
        for (final Person p in kisiler)
          if (p.id == kisi.id)
            p.copyWith(development: yeniGelisim)
          // §21: eski eş **silinmez**, bağı değişir. Torunun biyolojik
          // ebeveyniyse `motherId`/`fatherId` alanlarına dokunulmaz
          // (§22) — burada yalnızca `relation` değişiyor.
          else if (d.spousePersonId != null && p.id == d.spousePersonId)
            p.copyWith(relation: RelationType.eskiCocugunEsi)
          else
            p,
      ];

      final String iyelik = kisi.possessiveFor(newAge);
      final String metin = '$iyelik ${kisi.firstName} ile $esAdi '
          'ayrılmaya karar verdiler.';
      satirlar.add(metin);
      bildirimler.add(
        PendingNotice(
          id: 'cocuk-bosanma-${kisi.id}-$newAge',
          kind: NoticeKind.aileDonum,
          age: newAge,
          title: 'Ailede bir ayrılık',
          text: metin,
          personId: kisi.id,
        ),
      );
    }

    return (
      state: state.copyWith(people: List<Person>.unmodifiable(kisiler)),
      notices: bildirimler,
      logTexts: satirlar,
    );
  }

  // =================================================================
  // §23 — yeniden evlenme
  // =================================================================

  /// Bu kişi yeniden evlenebilir mi?
  static bool canRemarry(Person person) {
    final PersonDevelopment? d = person.development;
    if (d == null || !person.isAlive) return false;
    if (!d.canRemarry) return false;
    if (person.age > prototypeOnlyRemarryMaxAge) return false;
    // Son evliliğin bitişinden bu yana geçen süre (§23 — soğuma).
    final int? bitis = d.pastMarriages.isEmpty
        ? null
        : d.pastMarriages.last.endedAtAge;
    if (bitis == null) return false;
    return person.age - bitis >= prototypeOnlyRemarryCooldown;
  }

  /// Bu yılın yeniden evliliklerini uygular.
  ///
  /// Yeni eş **yeni bir kişidir** (§54): kimlik `kaçıncı evlilik`
  /// üzerinden türetildiği için eski eşin kaydı yeniden kullanılmaz.
  static ChildMarriageYear maybeRemarry(
    GameState state,
    int newAge,
    Random rng,
  ) {
    final List<PendingNotice> bildirimler = <PendingNotice>[];
    final List<String> satirlar = <String>[];
    List<Person> kisiler = state.people;
    final List<Person> yeniEsler = <Person>[];

    for (final Person kisi in state.people) {
      if (!_hasOwnMarriageLife(kisi.relation)) continue;
      if (!canRemarry(kisi)) continue;
      if (!rng.chance(prototypeOnlyRemarryChance)) continue;

      // `ChildMarriage` kendi `eligible` kapısında "evli olmayan" arar;
      // yeniden evlenme de aynı kapıdan geçer. Durum, o anki kişi
      // listesiyle veriliyor ki kimlik çakışması görülebilsin.
      final ChildMarriageResult? sonuc = ChildMarriage.maybeMarry(
        child: kisi,
        playerAge: newAge,
        rng: rng,
        relation: kisi.relation,
        state: state.copyWith(
          people: List<Person>.unmodifiable(<Person>[
            ...kisiler,
            ...yeniEsler,
          ]),
        ),
        // Yeniden evlenme kararı yukarıda verildi; `maybeMarry`'nin
        // kendi yaş zarını ikinci kez atmasın.
        forceMarriage: true,
      );
      if (sonuc == null) continue;

      kisiler = <Person>[
        for (final Person p in kisiler)
          if (p.id == kisi.id) sonuc.person else p,
      ];
      if (sonuc.spouse != null) yeniEsler.add(sonuc.spouse!);

      final String iyelik = kisi.possessiveFor(newAge);
      final String metin = '$iyelik ${kisi.firstName} yeniden evlendi: '
          '${sonuc.person.development?.spouseName ?? 'yeni eşiyle'}.';
      satirlar.add(metin);
      bildirimler.add(
        PendingNotice(
          id: 'cocuk-yeniden-evlilik-${kisi.id}-$newAge',
          kind: NoticeKind.aileDonum,
          age: newAge,
          title: 'Yeniden evlilik',
          text: metin,
          personId: kisi.id,
        ),
      );
    }

    return (
      state: state.copyWith(
        people: List<Person>.unmodifiable(<Person>[...kisiler, ...yeniEsler]),
      ),
      notices: bildirimler,
      logTexts: satirlar,
    );
  }

  // =================================================================
  // §50 — eşin vefatı
  // =================================================================

  /// Vefat eden gelin/damatların eşlerini **dul** yapar.
  ///
  /// Ölümün kendisi genel ölüm motorundan geliyor (gelin/damat sıradan
  /// bir kişidir ve yaşına göre ölür). Eksik olan şey kaydın
  /// güncellenmesiydi: eşi ölen çocuk "evli" kalıyordu.
  ///
  /// Kişi **silinmez**; yalnızca evlilik durumu değişir ve kayıt
  /// geçmişe taşınır.
  static ChildMarriageYear applySpouseDeaths(
    GameState state,
    int newAge,
  ) {
    // Bu yıl vefat etmiş olabilecek eş kimlikleri: hayatta olmayan
    // gelin/damatlar.
    final Set<String> olenEsler = <String>{
      for (final Person p in state.people)
        if (!p.isAlive &&
            (p.relation == RelationType.cocugunEsi ||
                p.relation == RelationType.eskiCocugunEsi))
          p.id,
    };
    if (olenEsler.isEmpty) {
      return (state: state, notices: const <PendingNotice>[], logTexts: const <String>[]);
    }

    final List<PendingNotice> bildirimler = <PendingNotice>[];
    final List<String> satirlar = <String>[];
    final List<Person> kisiler = <Person>[];

    for (final Person kisi in state.people) {
      final PersonDevelopment? d = kisi.development;
      final bool esiOldu = d != null &&
          d.isMarried &&
          d.spousePersonId != null &&
          olenEsler.contains(d.spousePersonId);
      if (!esiOldu) {
        kisiler.add(kisi);
        continue;
      }

      final String esAdi = d.spouseName ?? 'eşi';
      kisiler.add(
        kisi.copyWith(
          development: d
              .copyWith(
                marriageStatus: NpcMarriageStatus.dul,
                spousePersonId: null,
                pastMarriages: List<NpcMarriageRecord>.unmodifiable(
                  <NpcMarriageRecord>[
                    ...d.pastMarriages,
                    NpcMarriageRecord(
                      spouseName: esAdi,
                      spousePersonId: d.spousePersonId,
                      marriedAtAge: d.marriedAtAge ?? kisi.age,
                      endedAtAge: kisi.age,
                      status: NpcMarriageStatus.dul,
                    ),
                  ],
                ),
              )
              .withMilestone(kisi.age, 'Eşi $esAdi vefat etti.'),
        ),
      );

      final String iyelik = kisi.possessiveFor(newAge);
      final String metin = '$iyelik ${kisi.firstName} eşini kaybetti.';
      satirlar.add(metin);
      bildirimler.add(
        PendingNotice(
          id: 'cocuk-dul-${kisi.id}-$newAge',
          kind: NoticeKind.aileDonum,
          age: newAge,
          title: 'Ailede bir kayıp',
          text: metin,
          personId: kisi.id,
        ),
      );
    }

    return (
      state: state.copyWith(people: List<Person>.unmodifiable(kisiler)),
      notices: bildirimler,
      logTexts: satirlar,
    );
  }

  /// Kendi evlilik hayatı izlenen bağlar.
  ///
  /// `ChildMarriage` ile aynı küme: oyuncunun çocuğu ve aynı evde büyüyen
  /// kardeşler. Gelin/damadın kendi ikinci evliliği bu sürümde
  /// izlenmiyor — kapsamı dar tutmak bilinçli (§51'in V1 sınırı).
  static bool _hasOwnMarriageLife(RelationType relation) =>
      relation == RelationType.cocuk ||
      relation == RelationType.kardes ||
      relation == RelationType.uveyKardes ||
      relation == RelationType.yariKardes ||
      relation == RelationType.uveyCocuk;
}

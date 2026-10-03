import 'dart:math';

import '../generation/random_util.dart';

import '../../data/pet_catalog.dart';
import '../../text/turkish_text.dart';
import '../models/game_state.dart';
import '../models/interaction.dart';
import '../models/life_log.dart';
import '../models/pending_notice.dart';
import '../models/person.dart';
import '../models/stats.dart';

/// Evcil hayvan sahiplenme ve bakımı (Paket 40 — Issue #67, 2. kısım).
///
/// **İkinci bir sistem kurulmaz.** `GameState.pets` zaten vardı; burada o
/// kayda sahiplenme, bakım, yaşlanma ve vefat eklenir.
///
/// Tasarım sınırları:
/// - Bakım gideri **yılda bir kez** alınır (`lastCareChargedPlayerAge`).
/// - Cüzdan **eksiye düşmez**; parası yetmeyen oyuncunun hayvanı
///   **ölmez**, yalnızca zor bir yıl geçirilir.
/// - Etkileşimler yıllık kotalıdır; sınırsız mutluluk kasılamaz.
/// - Vefat eden hayvanın kaydı **silinmez**, işaretlenir ve bir daha
///   etkileşime girmez.
///
/// Sayısal değerler `prototypeOnly`'dir
/// (`docs/DESIGN_REVIEW_QUEUE.md`, Q-107).
abstract final class PetCare {
  /// prototypeOnly: hayvan sahiplenilebilecek en küçük oyuncu yaşı.
  static const int prototypeOnlyMinAge = 7;

  /// prototypeOnly: aynı anda bakılabilecek en çok hayvan.
  static const int prototypeOnlyMaxLivingPets = 3;

  /// prototypeOnly: bakımı karşılanamayan yılın mutluluk bedeli.
  static const int prototypeOnlyUnpaidHappiness = -4;

  /// prototypeOnly: bakımı karşılanamayan yılın bağ bedeli.
  static const int prototypeOnlyUnpaidBond = -3;

  /// prototypeOnly: hayvanın vefatının mutluluğa etkisi (bağa göre artar).
  static const int prototypeOnlyDeathHappinessBase = -8;
  static const int prototypeOnlyDeathHappinessExtra = -10;

  /// prototypeOnly: kayıp hayvanın bir yılda geri dönme ihtimali (D-082).
  ///
  /// Yüksek tutuldu: kaçan hayvan kalıcı olarak yok olmaz (D-058).
  static const double prototypeOnlyReturnChance = 0.6;

  /// prototypeOnly: bir yılda hastalanma ihtimali.
  static const double prototypeOnlyIllnessChance = 0.12;

  /// prototypeOnly: hastalığın sağlığa verdiği zarar.
  static const int prototypeOnlyIllnessDamage = 18;

  /// prototypeOnly: veteriner ziyaretinin sağlığa katkısı.
  static const int prototypeOnlyVetHealthGain = 22;

  /// prototypeOnly: sağlığın vefat ihtimaline etkisinin üst sınırı.
  static const double prototypeOnlyHealthDeathFactor = 1.6;

  // -------------------------------------------------------------------
  // Okuma yardımcıları
  // -------------------------------------------------------------------

  /// Oyuncunun **şu an baktığı** hayvanlar (D-109).
  ///
  /// Vefat edenler ve başka yuvaya verilenler burada yoktur; kayıp olan
  /// hâlâ oyuncunundur, çünkü dönmesi beklenir.
  static List<Pet> livingPets(GameState state) =>
      state.pets.where((Pet p) => p.isActive).toList(growable: false);

  /// Kaydı duran ama artık bakılmayan hayvanlar (D-109).
  static List<Pet> pastPets(GameState state) =>
      state.pets.where((Pet p) => !p.isActive).toList(growable: false);

  /// prototypeOnly: sahiplendirmenin mutluluk bedeli.
  ///
  /// İyi bir yuva bulmak doğru karar olabilir ama yine de bir ayrılıktır.
  static const int prototypeOnlyRehomeHappiness = -5;

  /// prototypeOnly: bir hayvan en çok kaç yıl kayıp kalabilir (D-109).
  ///
  /// Faho bildirdi: "kaçan hayvan mutlaka sonuçlansın". Eskiden dönme
  /// ihtimali her yıl yeniden atılıyordu ve şanssız bir hayvan ömür boyu
  /// kayıp kalabiliyordu. Artık bu sürenin sonunda durum kapanır:
  /// hayvan ya döner ya da başka bir yuva bulmuş sayılır.
  static const int prototypeOnlyMaxMissingYears = 3;

  /// Hayvan başka bir yuvaya verilebilir mi? (D-109)
  static InteractionAvailability rehomeAvailability(
    GameState state,
    Pet pet,
  ) {
    if (!pet.isAlive) {
      return const InteractionAvailability.blocked('Bu hayvan artık yok.');
    }
    if (pet.isRehomed) {
      return const InteractionAvailability.blocked(
        'Bu hayvanı zaten başka bir yuvaya verdin.',
      );
    }
    if (pet.isMissing) {
      return const InteractionAvailability.blocked(
        'Önce kayıp hayvanın dönmesini beklemen gerekiyor.',
      );
    }
    return const InteractionAvailability.allowed();
  }

  /// Hayvanı başka bir yuvaya verir (D-109).
  ///
  /// **Vefat değildir**: hayvan yaşamaya devam eder, kaydı silinmez ve
  /// "Geçmişte bakıp verdiklerin" bölümünde görünür. Bakım gideri
  /// bundan sonra işlemez.
  static ({GameState state, bool applied, String text}) rehome({
    required GameState state,
    required String petId,
  }) {
    final Pet? pet = petById(state, petId);
    if (pet == null) {
      return (state: state, applied: false, text: 'Böyle bir hayvan yok.');
    }
    final InteractionAvailability check = rehomeAvailability(state, pet);
    if (!check.isAllowed) {
      return (state: state, applied: false, text: check.reason!);
    }

    final String metin = '${pet.name} için yeni bir yuva buldun. '
        'Vedalaşmak kolay olmadı.';
    final GameState next = state.copyWith(
      player: state.player.copyWith(
        stats: state.player.stats.gain(
          happiness: prototypeOnlyRehomeHappiness,
        ),
      ),
      pets: List<Pet>.unmodifiable(
        state.pets.map((Pet p) => p.id == petId
            ? p.copyWith(rehomedAtPlayerAge: state.player.age)
            : p),
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
    return (state: next, applied: true, text: metin);
  }

  static Pet? petById(GameState state, String id) {
    for (final Pet p in state.pets) {
      if (p.id == id) return p;
    }
    return null;
  }

  static PetSpecies speciesOf(Pet pet) =>
      petSpeciesById(pet.species) ?? PetSpecies.kedi;

  /// Bu hayvanla bu yıl kaç kez [action] yapıldı?
  static int timesDone(GameState state, Pet pet, PetAction action) =>
      state.interactionCount('hayvan-${pet.id}', action.id);

  // -------------------------------------------------------------------
  // Sahiplenme
  // -------------------------------------------------------------------

  /// Sahiplenmeye engel; engel yoksa `null`.
  static InteractionAvailability adoptionAvailability(
    GameState state,
    PetSpecies species,
  ) {
    if (state.player.age < prototypeOnlyMinAge) {
      return const InteractionAvailability.blocked(
        '$prototypeOnlyMinAge yaşından itibaren bir hayvana '
        'bakabilirsin.',
      );
    }
    if (livingPets(state).length >= prototypeOnlyMaxLivingPets) {
      return const InteractionAvailability.blocked(
        'Evde bakabileceğin kadar hayvan var.',
      );
    }
    // Özel izin gerektiren tür (D-082) artık gerçekten zor (D-109):
    // yaş şartı ağırdır ve iznin ayrıca bir bedeli vardır. Kapı
    // kapanmaz, ama bu bir "tıkla ve al" tercihi değildir.
    if (species.requiresPermit) {
      if (state.player.age < prototypeOnlyPermitMinAge) {
        return InteractionAvailability.blocked(
          '${species.label} için özel izin gerekiyor; izin '
          '$prototypeOnlyPermitMinAge yaşından önce verilmiyor.',
        );
      }
      if (!state.movedOut) {
        return InteractionAvailability.blocked(
          '${species.label} için kendi evinde yaşıyor olman gerekiyor; '
          'izin ailenin evine verilmiyor.',
        );
      }
      final int toplam = species.adoptionCost + permitFeeFor(species);
      if (state.player.wallet < toplam) {
        return InteractionAvailability.blocked(
          '${species.label} için hayvanın bedeli ve izin masrafı '
          'birlikte ${trMoney(toplam)} tutuyor; cüzdanında yeterli para '
          'yok.',
        );
      }
      return const InteractionAvailability.allowed();
    }
    if (state.player.wallet < species.adoptionCost) {
      return InteractionAvailability.blocked(
        '${trMoney(species.adoptionCost)} gerekiyor; cüzdanında yeterli '
        'para yok.',
      );
    }
    return const InteractionAvailability.allowed();
  }

  /// prototypeOnly: özel izin gerektiren hayvan için en küçük yaş.
  static const int prototypeOnlyPermitMinAge = 25;

  /// prototypeOnly: özel iznin masrafı — hayvanın bedelinin yarısı.
  ///
  /// İzin, muayene, kayıt ve uygun barınak: bedelin yanında ayrıca
  /// ödenir. İzin gerektirmeyen türde sıfırdır.
  static int permitFeeFor(PetSpecies species) =>
      species.requiresPermit ? species.adoptionCost ~/ 2 : 0;

  /// Bir hayvan sahiplenir.
  ///
  /// Masraf **bir kez** alınır. Hayvan gerçek bir kimlikle kayda girer:
  /// adı, türü, yaşı ve sahiplenildiği yıl saklanır.
  static ({GameState state, bool applied, String text}) adopt({
    required GameState state,
    required PetSpecies species,
    required String name,
    required Random rng,
  }) {
    final InteractionAvailability check =
        adoptionAvailability(state, species);
    if (!check.isAllowed) {
      return (state: state, applied: false, text: check.reason!);
    }

    final String ad = name.trim().isEmpty
        ? kPetSuggestedNames[rng.nextInt(kPetSuggestedNames.length)]
        : name.trim();
    final int yas = state.player.age;

    // Kimlik sayacı kayıtta duran hayvan sayısından türetilir; ölen
    // hayvanın kaydı silinmediği için kimlik tekrar etmez.
    final Pet yeni = Pet(
      id: 'hayvan-${state.pets.length + 1}-$yas',
      name: ad,
      species: species.id,
      age: 0,
      adoptedAtPlayerAge: yas,
      // Sahiplenildiği yılın gideri sahiplenme masrafına dahildir;
      // aynı yıl ikinci kez bakım gideri alınmaz.
      lastCareChargedPlayerAge: yas,
    );

    final GameState next = state.copyWith(
      player: state.player.copyWith(
        wallet: state.player.wallet -
            species.adoptionCost -
            permitFeeFor(species),
        stats: state.player.stats.gain(
          happiness: 5,
        ),
      ),
      pets: List<Pet>.unmodifiable(<Pet>[...state.pets, yeni]),
      log: List<LifeLogEntry>.unmodifiable(<LifeLogEntry>[
        ...state.log,
        LifeLogEntry(
          age: yas,
          text: '${species.label} $ad artık seninle yaşıyor.',
          category: LogCategory.kisisel,
        ),
      ]),
    );

    return (
      state: next,
      applied: true,
      text: '$ad eve geldi. İlk gün her köşeyi kokladı.',
    );
  }

  // -------------------------------------------------------------------
  // Etkileşimler
  // -------------------------------------------------------------------

  /// Bu etkileşim şu an yapılabilir mi?
  static InteractionAvailability availability(
    GameState state,
    Pet pet,
    PetAction action,
  ) {
    if (!pet.isAlive) {
      return const InteractionAvailability.blocked(
        'Bu kayıt geçmişte kaldı.',
      );
    }
    if (!pet.inPlayerHousehold) {
      return const InteractionAvailability.blocked(
        'Artık seninle aynı evde yaşamıyor.',
      );
    }
    if (timesDone(state, pet, action) >= action.maxPerAge) {
      return const InteractionAvailability.blocked(
        'Bu yıl için yeterince yaptın; seneye yeniden açılır.',
      );
    }
    if (state.player.wallet < action.cost) {
      return InteractionAvailability.blocked(
        '${trMoney(action.cost)} gerekiyor; cüzdanında yeterli para yok.',
      );
    }
    return const InteractionAvailability.allowed();
  }

  /// Bir etkileşimi uygular.
  ///
  /// Kazanç aynı yıl içinde tekrar ettikçe azalır (aktivitelerdeki eğriyle
  /// aynı mantık): hayvan sınırsız mutluluk makinesi değildir.
  static ({GameState state, bool applied, String text}) interact({
    required GameState state,
    required Pet pet,
    required PetAction action,
    required Random rng,
  }) {
    final InteractionAvailability check = availability(state, pet, action);
    if (!check.isAllowed) {
      return (state: state, applied: false, text: check.reason!);
    }

    final int done = timesDone(state, pet, action);
    final double factor = _prototypeOnlyRewardCurve[
        min(done, _prototypeOnlyRewardCurve.length - 1)];

    final int mutluluk = _scaled(action.happiness, factor);
    final int saglik = _scaled(action.health, factor);
    final int bag = _scaled(action.bond, factor);

    final PetSpecies tur = speciesOf(pet);
    final int ucret = action.usesVetCost ? tur.vetCost : action.cost;
    if (state.player.wallet < ucret) {
      return (
        state: state,
        applied: false,
        text: '${trMoney(ucret)} gerekiyor; cüzdanında yeterli para yok.',
      );
    }

    // Veteriner ziyareti hayvanın **kendi sağlığını** yükseltir
    // (D-058): gerçek bir anlamı olsun diye.
    final Pet guncel = pet.copyWith(
      bond: (pet.bond + bag).clamp(0, 100),
      health: action == PetAction.veteriner
          ? pet.health + prototypeOnlyVetHealthGain
          : pet.health,
    );

    final GameState next = state.copyWith(
      player: state.player.copyWith(
        wallet: state.player.wallet - ucret,
        stats: state.player.stats.gain(
          happiness: mutluluk,
          health: saglik,
        ),
      ),
      pets: _replace(state.pets, guncel),
      interactionCounts: Map<String, int>.unmodifiable(<String, int>{
        ...state.interactionCounts,
        GameState.interactionKey('hayvan-${pet.id}', action.id): done + 1,
      }),
    );

    return (
      state: next,
      applied: true,
      text: action.resultTexts[rng.nextInt(action.resultTexts.length)]
          .replaceAll('{ad}', pet.name),
    );
  }

  // -------------------------------------------------------------------
  // Yıl ilerlemesi
  // -------------------------------------------------------------------

  /// Hayvanları yaşlandırır, bakım giderini **bir kez** alır ve yaşı gelen
  /// hayvanı doğal yoldan kaybettirir.
  static GameState advanceYear(GameState state, int newAge, Random rng) {
    if (state.pets.isEmpty) return state;

    final List<Pet> sonuc = <Pet>[];
    final List<LifeLogEntry> gunluk = <LifeLogEntry>[];
    final List<PendingNotice> bildirimler = <PendingNotice>[];

    int cuzdan = state.player.wallet;
    int mutluluk = 0;
    bool karsilanamayan = false;
    int toplamGider = 0;

    for (final Pet pet in state.pets) {
      // Vefat eden, hanede olmayan ve **başka yuvaya verilen** hayvan
      // için yıl işlemez: bakım gideri de alınmaz (D-109).
      if (!pet.isActive || !pet.inPlayerHousehold) {
        sonuc.add(pet);
        continue;
      }

      final PetSpecies tur = speciesOf(pet);
      Pet guncel = pet.copyWith(age: pet.age + 1);

      // --- Bakım gideri: yılda **bir kez** ------------------------------
      //
      // **Sahiplenmediğin hayvanın bakımı senden çıkmaz (D-144).**
      //
      // Faho bildirdi: "4-5-6 yaşlarında aileden harçlık alıyorum, sene
      // geçtiğinde harçlığım evde zaten ben doğduğumda var olan hayvanın
      // bakımına gidiyor! Eğer hayvanı ben sahiplenmediysem bakımına
      // benden ücret çıkmasın."
      //
      // `adoptedAtPlayerAge == null` demek "oyuncu doğduğunda hayvan
      // evdeydi" demektir; o hayvan ailenin hayvanıdır. Yaşlanması,
      // kaçması, hastalanması ve vefatı aynen işler — yalnızca para
      // oyuncunun cüzdanından çıkmaz.
      final bool bakimiSenOdemezsin = guncel.adoptedAtPlayerAge == null;
      if (bakimiSenOdemezsin) {
        guncel = guncel.copyWith(lastCareChargedPlayerAge: newAge);
      } else if (guncel.lastCareChargedPlayerAge != newAge) {
        final int gider = tur.yearlyCareCost;
        if (cuzdan >= gider) {
          cuzdan -= gider;
          toplamGider += gider;
        } else {
          // Cüzdan eksiye düşmez ve hayvan parasızlıktan ölmez: eldeki
          // kadarı harcanır, yıl zor geçer.
          toplamGider += cuzdan;
          cuzdan = 0;
          karsilanamayan = true;
          mutluluk += prototypeOnlyUnpaidHappiness;
          guncel = guncel.copyWith(
            bond: (guncel.bond + prototypeOnlyUnpaidBond).clamp(0, 100),
          );
        }
        guncel = guncel.copyWith(lastCareChargedPlayerAge: newAge);
      }

      // --- Kaçma ve dönüş (D-082) ---------------------------------------
      //
      // Faho'nun isteği: "bazen evden kaçabilir, hastalanabilir".
      // Kaçan hayvan **yok olmaz** (D-058): kayıtta kalır ve büyük
      // ihtimalle döner. Kayıpken bakım gideri işlemez, yaşlanmaya
      // devam eder.
      if (guncel.isMissing) {
        final int kayipYil = newAge - (guncel.missingSinceAge ?? newAge);
        final bool sonYil = kayipYil >= prototypeOnlyMaxMissingYears;
        if (rng.chance(prototypeOnlyReturnChance)) {
          guncel = guncel.copyWith(missingSinceAge: null);
          gunluk.add(
            LifeLogEntry(
              age: newAge,
              text: '${guncel.name} eve döndü.',
              category: LogCategory.aile,
            ),
          );
          bildirimler.add(
            PendingNotice(
              id: 'hayvan-dondu-${guncel.id}-$newAge',
              kind: NoticeKind.hayvan,
              age: newAge,
              title: '${guncel.name} döndü',
              text: '${guncel.name} kapının önünde bekliyordu. '
                  'Sağ salim geri geldi.',
            ),
          );
        } else if (sonYil) {
          // Kayıp sonsuza kadar sürmez (D-109): süre dolunca durum
          // kapanır. Hayvan **ölmez**; başka bir yuva bulmuş sayılır ve
          // kaydı "geçmişte bakıp verdiklerin" arasına geçer.
          guncel = guncel.copyWith(rehomedAtPlayerAge: newAge);
          gunluk.add(
            LifeLogEntry(
              age: newAge,
              text: '${guncel.name} bir daha dönmedi. Komşular başka bir '
                  'mahallede görüldüğünü söyledi.',
              category: LogCategory.aile,
            ),
          );
          bildirimler.add(
            PendingNotice(
              id: 'hayvan-kapandi-${guncel.id}-$newAge',
              kind: NoticeKind.hayvan,
              age: newAge,
              title: '${guncel.name} dönmedi',
              text: '${guncel.name} $prototypeOnlyMaxMissingYears yıldır '
                  'kayıptı. Aramayı bıraktın; başka bir kapıda '
                  'yaşadığını duydun.',
            ),
          );
        }
      } else if (rng.chance(tur.escapeRisk)) {
        guncel = guncel.copyWith(missingSinceAge: newAge);
        gunluk.add(
          LifeLogEntry(
            age: newAge,
            text: '${guncel.name} evden kaçtı.',
            category: LogCategory.aile,
          ),
        );
        bildirimler.add(
          PendingNotice(
            id: 'hayvan-kacti-${guncel.id}-$newAge',
            kind: NoticeKind.hayvan,
            age: newAge,
            title: '${guncel.name} kayıp',
            text: '${guncel.name} evden kaçtı. Mahalleye ilan astın; '
                'dönmesini bekliyorsun.',
          ),
        );
      }

      // --- Hastalık (D-082) ----------------------------------------------
      //
      // Hasta hayvanın sağlığı düşer. Veteriner ziyareti gerçekten işe
      // yarar; bakılmayan hayvanın sağlığı yıllar içinde erir ve doğal
      // vefat ihtimali artar. Parası yetmeyen oyuncu cezalandırılmaz,
      // ama hayvanın durumu iyileşmez.
      if (!guncel.isMissing && rng.chance(prototypeOnlyIllnessChance)) {
        guncel = guncel.copyWith(
          health: guncel.health - prototypeOnlyIllnessDamage,
        );
        gunluk.add(
          LifeLogEntry(
            age: newAge,
            text: '${guncel.name} hastalandı; veterinere görünmesi '
                'gerekiyor.',
            category: LogCategory.aile,
          ),
        );
        bildirimler.add(
          PendingNotice(
            id: 'hayvan-hasta-${guncel.id}-$newAge',
            kind: NoticeKind.hayvan,
            age: newAge,
            title: '${guncel.name} hasta',
            // Sayı cümle sonunda kalınca "Sağlığı 57. Aktiviteler"
            // sıra sayısı gibi okunuyordu (Faho bildirdi). Sayı artık
            // parantez içinde; ardından nokta gelmiyor. Türkçe ek de
            // kullanılmıyor, çünkü ek son hanenin ünlüsüne göre değişir
            // (57'ye ama 60'a) ve sayı değişkendir.
            text: '${guncel.name} bu yıl hastalandı (sağlığı '
                '${guncel.health}). Aktiviteler → Evcil Hayvanlar\'dan '
                'veterinere götürebilirsin '
                '(${trMoney(tur.vetCost)}).',
          ),
        );
      }

      // --- Doğal vefat ---------------------------------------------------
      if (_diesThisYear(guncel, tur, rng)) {
        guncel = guncel.copyWith(
          diedAtAge: guncel.age,
          diedAtPlayerAge: newAge,
        );
        final int kayip = prototypeOnlyDeathHappinessBase +
            (prototypeOnlyDeathHappinessExtra * guncel.bond / 100).round();
        mutluluk += kayip;
        gunluk.add(
          LifeLogEntry(
            age: newAge,
            text: '${tur.label} ${guncel.name} ${guncel.age} yaşında '
                'hayatını kaybetti.',
            category: LogCategory.kisisel,
          ),
        );
        bildirimler.add(
          PendingNotice(
            id: 'hayvan-olum-${guncel.id}',
            kind: NoticeKind.hayvan,
            age: newAge,
            title: '${guncel.name} vefat etti',
            text: '${guncel.name} ${guncel.age} yaşındaydı. '
                '${_birlikteMetni(guncel, newAge)} Ev bugün sessiz.',
          ),
        );
      }

      sonuc.add(guncel);
    }

    if (toplamGider > 0) {
      gunluk.add(
        LifeLogEntry(
          age: newAge,
          text: karsilanamayan
              ? 'Hayvan bakımı için elindeki her şeyi verdin; yine de '
                  'yetmedi.'
              : 'Hayvan bakımına ${trMoney(toplamGider)} gitti.',
          category: LogCategory.kisisel,
        ),
      );
    }

    final Stats stats = state.player.stats.gain(
      happiness: mutluluk,
    );

    return state.copyWith(
      player: state.player.copyWith(wallet: cuzdan, stats: stats),
      pets: List<Pet>.unmodifiable(sonuc),
      log: gunluk.isEmpty
          ? state.log
          : List<LifeLogEntry>.unmodifiable(<LifeLogEntry>[
              ...state.log,
              ...gunluk,
            ]),
      notices: bildirimler.isEmpty
          ? state.notices
          : List<PendingNotice>.unmodifiable(<PendingNotice>[
              ...state.notices,
              ...bildirimler,
            ]),
    );
  }

  /// Kuşak değişiminde devam eden hayvanlar.
  ///
  /// Yalnızca **yaşayan ve aynı hanede** olan hayvan geçer; kimliği, adı ve
  /// yaşı korunur — sahte yeni hayvan üretilmez. Hanede olmayan ya da vefat
  /// etmiş hayvan yeni kuşağa taşınmaz; evcil hayvan miras kalemi değildir.
  static List<Pet> carryOver(List<Pet> pets) => List<Pet>.unmodifiable(
        pets
            .where((Pet p) => p.isAlive && p.inPlayerHousehold)
            // Yeni kuşağın yaşına göre bakım gideri yeniden işlenmeli.
            .map((Pet p) => p.copyWith(lastCareChargedPlayerAge: null))
            .toList(growable: false),
      );

  // -------------------------------------------------------------------
  // İç yardımcılar
  // -------------------------------------------------------------------

  /// prototypeOnly: aynı yıl tekrar edildikçe azalan kazanç eğrisi.
  static const List<double> _prototypeOnlyRewardCurve = <double>[
    1.0,
    0.6,
    0.3,
  ];

  static int _scaled(int value, double factor) =>
      value == 0 ? 0 : max(value.isNegative ? -1 : 1, (value * factor).round());

  static List<Pet> _replace(List<Pet> pets, Pet yeni) =>
      List<Pet>.unmodifiable(<Pet>[
        for (final Pet p in pets)
          if (p.id == yeni.id) yeni else p,
      ]);

  /// Bu yıl doğal yoldan vefat eder mi?
  ///
  /// Olağan ömre yaklaştıkça artan, üst sınırda kesinleşen bir eğri.
  /// Parasızlık burada **hiç** rol oynamaz.
  static bool _diesThisYear(Pet pet, PetSpecies tur, Random rng) {
    if (pet.age >= tur.maxLifespan) return true;
    if (pet.age < tur.typicalLifespan ~/ 2) return false;
    final double oran =
        (pet.age - tur.typicalLifespan / 2) / (tur.maxLifespan - tur.typicalLifespan / 2);
    // Sağlık ölüm eğrisini besler (D-058): bakılan hayvan daha uzun
    // yaşar, bakılmayan daha erken gider. Sağlık 75 nötrdür.
    final double saglikCarpani =
        (1 + (Pet.prototypeOnlyDefaultPetHealth - pet.health) / 100)
            .clamp(0.5, prototypeOnlyHealthDeathFactor);
    // prototypeOnly: olağan ömrün yarısında ~%0, üst sınırda %100.
    return rng.nextDouble() < oran * oran * saglikCarpani;
  }

  static String _birlikteMetni(Pet pet, int playerAge) {
    final int? baslangic = pet.adoptedAtPlayerAge;
    if (baslangic == null) {
      return 'Seni doğduğun günden beri tanıyordu.';
    }
    final int yil = playerAge - baslangic;
    if (yil <= 0) return 'Yeni tanışmıştınız.';
    return '$yil yıl birlikteydiniz.';
  }
}

/// Bir evcil hayvanla yapılabilecek şeyler.
///
/// Hepsi gerçekten çalışır; süs düğme yoktur. Yıllık kota ve azalan kazanç
/// eğrisi sayesinde sınırsız stat kasılamaz.
enum PetAction {
  vakitGecir(
    id: 'vakit',
    label: 'Vakit geçir',
    description: 'Yanına otur, biraz konuş, biraz sus.',
    happiness: 4,
    bond: 5,
    maxPerAge: 3,
    resultTexts: <String>[
      '{ad} yanına kıvrıldı. Bir süre ikiniz de kımıldamadınız.',
      '{ad} ayağının dibine yattı; akşam böyle geçti.',
      'Hiçbir şey yapmadınız. {ad} zaten bunu istiyordu.',
    ],
  ),
  oyunOyna(
    id: 'oyun',
    label: 'Oyun oyna',
    description: 'Koşturmaca, ip, top — kim daha çok yoruluyor belli değil.',
    happiness: 5,
    health: 2,
    bond: 6,
    maxPerAge: 3,
    resultTexts: <String>[
      '{ad} ipin ucunu bırakmadı; sonunda sen pes ettin.',
      'Evin içinde koştunuz. Bir şeyler devrildi, önemli değildi.',
      '{ad} topu getirdi ama vermedi. Oyun buydu zaten.',
    ],
  ),
  bakimYap(
    id: 'bakim',
    label: 'Bakımını yap',
    description: 'Tarak, tırnak, kulak. Sevmiyor ama gerekiyor.',
    cost: 900, // prototypeOnly
    happiness: 2,
    bond: 4,
    maxPerAge: 2,
    resultTexts: <String>[
      '{ad} bütün işlem boyunca sitem etti, sonunda sakinleşti.',
      'Tarağı görünce kaçtı. Yine de yakaladın.',
    ],
  ),
  veteriner(
    id: 'veteriner',
    label: 'Veterinere götür',
    description: 'Kontrol, aşı ve bekleme odasında geçen yarım saat.',
    usesVetCost: true,
    happiness: 1,
    bond: 3,
    maxPerAge: 1,
    resultTexts: <String>[
      'Veteriner "iyi bakılmış" dedi. {ad} kafesten çıkar çıkmaz kaçtı.',
      'Kontrolden temiz çıktınız. {ad} dönüş yolunda küstü.',
    ],
  );

  const PetAction({
    required this.id,
    required this.label,
    required this.description,
    this.cost = 0,
    this.usesVetCost = false,
    this.happiness = 0,
    this.health = 0,
    this.bond = 0,
    required this.maxPerAge,
    this.resultTexts = const <String>[],
  });

  final String id;
  final String label;
  final String description;

  /// prototypeOnly: sabit ücret.
  final int cost;

  /// Ücret türe göre değişiyorsa (veteriner) `PetSpecies.vetCost` kullanılır.
  final bool usesVetCost;

  final int happiness;
  final int health;
  final int bond;

  /// prototypeOnly: bir yaşta en çok kaç kez.
  final int maxPerAge;

  final List<String> resultTexts;
}

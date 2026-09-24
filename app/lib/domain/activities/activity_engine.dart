import 'dart:math';

import '../../data/activity_catalog.dart';
import '../effects/effect_diff.dart';
import '../models/applied_effect.dart';
import '../models/book_progress.dart';
import '../models/game_state.dart';
import '../models/zodiac.dart';
import '../life/astrology.dart';
import '../../data/fortune_catalog.dart';
import '../../data/hobby_catalog.dart';
import '../hobby/hobby_tracker.dart';
import '../life/upkeep_tracker.dart';
import '../models/interaction.dart';
import '../life/hair_loss.dart';
import '../life/health_report.dart';
import '../life/notices.dart';
import '../models/life_log.dart';
import '../models/pending_notice.dart';
import '../models/player_character.dart';
import '../models/stats.dart';
import '../../text/turkish_text.dart';
import 'outing.dart';
import '../models/person.dart';

/// Bir aktivitenin sonucu.
class ActivityOutcome {
  const ActivityOutcome({
    required this.applied,
    required this.text,
    this.effects = const <AppliedEffect>[],
    this.noNewBenefit = false,
  });

  /// İşlem gerçekten uygulandı mı? `false` ise durum değişmemiştir.
  final bool applied;
  final String text;

  /// Durumun öncesi/sonrası farkından okunan **gerçek** değişimler.
  final List<AppliedEffect> effects;

  /// Bu yaş için bu eylemden kazanılacak kalmadı.
  final bool noNewBenefit;
}

class ActivityResult {
  const ActivityResult({required this.state, required this.outcome});

  final GameState state;
  final ActivityOutcome outcome;
}

/// Berber, spor salonu ve kütüphane.
///
/// Ortak kurallar:
/// - Parası yetmeyen işlem **gerçekleşmez**; cüzdan ve değerler değişmez.
/// - Aynı yaşta tekrar eden eylemin getirisi azalır ve sınıra gelince
///   eylem kapanır; sınırsız stat kasma yoktur.
/// - Sonuçlar hayat günlüğüne yazılır.
///
/// Sayısal değerler `prototypeOnly`'dir (`docs/DESIGN_REVIEW_QUEUE.md`,
/// Q-049).
class ActivityEngine {
  const ActivityEngine();

  /// prototypeOnly: aynı yaşta tekrar edildikçe azalan kazanç eğrisi.
  static const List<double> prototypeOnlyRewardCurve = <double>[1.0, 0.6, 0.3];

  /// prototypeOnly: Sağlık Merkezi'nden bir yılda kazanılabilecek en çok
  /// sağlık puanı (D-100).
  ///
  /// Her işlem ayrı ayrı `maxPerAge: 1` ile sınırlıydı ama **toplamı**
  /// sınırlı değildi: kontrol, diş, göz, aşı, tahlil ve terapi üst üste
  /// yapıldığında yılda 17 puan sağlık kazanılabiliyordu — yaşlanmanın
  /// aldığının kat kat üstü. Muayene olmak insanı sağlıklı yapmaz;
  /// erken fark ettirir. Kapı kapanmıyor, yalnızca yıllık toplam
  /// sınırlanıyor.
  static const int prototypeOnlyHealthCentreYearlyCap = 6;

  /// Yıllık sağlık kazancı sayacının anahtarı.
  static const String healthCentreCounterId = 'saglik_merkezi_kazanc';

  /// Bir eylemin bu yaşta kaç kez yapıldığı.
  int timesDone(GameState state, ActivityAction action) =>
      state.interactionCount('aktivite', action.id);

  /// Eylem şu an yapılabilir mi?
  InteractionAvailability availability(GameState state, ActivityAction action) {
    if (state.player.age < action.minAge) {
      return InteractionAvailability.blocked(
        '${action.minAge} yaşından itibaren yapabilirsin.'
        '${action.minAgeNote == null ? '' : ' ${action.minAgeNote}'}',
      );
    }
    // Hekim yönlendirmediyse tahlil düğmesi çalışmaz (D-076).
    if (action.requiresFlag != null &&
        !state.storyFlags.contains(action.requiresFlag)) {
      return const InteractionAvailability.blocked(
        'Şu an bunun için bir yönlendirme yok.',
      );
    }
    // Dökülmemiş saç ektirilmez (D-077).
    if (action.reducesHairLoss && state.player.hairLossStage <= 0) {
      return const InteractionAvailability.blocked(
        'Saçında ektirmeyi gerektiren bir dökülme yok.',
      );
    }
    if (timesDone(state, action) >= action.maxPerAge) {
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

  /// Bu mekânda şu an gerçekten yapılabilen eylemler.
  List<ActivityAction> availableActions(GameState state, ActivityVenue venue) =>
      actionsAt(venue)
          .where((ActivityAction a) => availability(state, a).isAllowed)
          .toList(growable: false);

  /// Bir aktivite eylemini uygular.
  ///
  /// [companion] verilirse eylem **birlikte** yapılır (Paket 41). Ücret,
  /// yaş sınırı ve yıllık kota aynı yerde kaldığı için birlikte gitmek
  /// ikinci kez para götürmez ve ikinci bir kayıt açmaz; yalnızca sonuç
  /// metni, bağ ve ortak geçmiş değişir.
  ActivityResult perform({
    required GameState state,
    required ActivityAction action,
    required Random rng,
    Person? companion,
  }) {
    final InteractionAvailability check = availability(state, action);
    if (!check.isAllowed) return _blocked(state, check.reason!);
    if (companion != null) {
      final InteractionAvailability birlikte =
          Outing.companionAvailability(state, action, companion);
      if (!birlikte.isAllowed) return _blocked(state, birlikte.reason!);
      // Davet edilen kişi reddedebilir (D-059). Ret **para götürmez** ve
      // yıllık kotayı harcamaz: gerçekleşmeyen program ücretlendirilmez.
      final String? ret = Outing.refusalReason(state, action, companion);
      if (ret != null) return _blocked(state, ret);
    }

    // Faho'nun Q-108 kararı: iki kişi gidiyorsa iki kişilik gerçek
    // maliyet hesaba katılır. Park gibi ücretsiz aktivite ücretsiz
    // kalır, çünkü sıfırın iki katı da sıfırdır.
    final int odenecek = Outing.costFor(action, withCompanion: companion != null);
    if (state.player.wallet < odenecek) {
      return _blocked(
        state,
        '${trMoney(odenecek)} gerekiyor; cüzdanında yeterli para yok. '
        'İki kişilik bilet tek kişilikten pahalı.',
      );
    }

    final int done = timesDone(state, action);
    final double factor =
        prototypeOnlyRewardCurve[min(done, prototypeOnlyRewardCurve.length - 1)];

    // Estetik işlemler risksiz değildir (D-077). Kötü sonuçta ücret yine
    // ödenir, kazanç uygulanmaz ve mutluluk düşer.
    final bool kotuSonuc =
        action.riskChance > 0 && rng.nextDouble() < action.riskChance;

    // Sağlık Merkezi'nin yıllık toplam sağlık kazancı sınırlıdır (D-100).
    final int saglikHakki = action.venue == ActivityVenue.saglikMerkezi
        ? (prototypeOnlyHealthCentreYearlyCap -
                state.interactionCount(healthCentreCounterId, 'aktivite'))
            .clamp(0, prototypeOnlyHealthCentreYearlyCap)
        : 1 << 30;
    final int saglikKazanci =
        min(_scaled(action.health, factor), saglikHakki);

    final Stats stats = kotuSonuc
        ? state.player.stats.gain(
            happiness: prototypeOnlyBadOutcomeHappiness,
          )
        : state.player.stats.gain(
            appearance: _scaled(action.appearance, factor),
            charisma: _scaled(action.charisma, factor),
            happiness: _scaled(action.happiness, factor),
            health: saglikKazanci,
            intelligence: _scaled(action.intelligence, factor),
          );

    // Saç stili değişiyorsa mevcut stilden farklı biri seçilir.
    String? yeniStil = state.player.hairStyle;
    if (action.changesHairStyle) {
      final List<String> secenekler = kHairStyles
          .where((String s) => s != state.player.hairStyle)
          .toList(growable: false);
      yeniStil = secenekler[rng.nextInt(secenekler.length)];
    }

    // Saç ekimi basamağı **bir ya da iki** kademe düşürür (Q-117
    // kararı); başarısız işlem hiç düşürmez. İleri basamaktan gelen
    // oyuncu tek seansta daha çok yol alır, çünkü ekilecek alan da
    // büyüktür; ilk basamaktaki zaten bir adım uzaktadır.
    final int kademe = state.player.hairLossStage >= 2 ? 2 : 1;
    final int yeniBasamak = action.reducesHairLoss && !kotuSonuc
        ? (state.player.hairLossStage - kademe).clamp(0, HairLoss.maxStage)
        : state.player.hairLossStage;

    final PlayerCharacter player = state.player.copyWith(
      stats: stats,
      wallet: state.player.wallet - odenecek,
      hairStyle: yeniStil,
      hairLossStage: yeniBasamak,
    );

    GameState next = state.copyWith(
      player: player,
      interactionCounts: Map<String, int>.unmodifiable(<String, int>{
        ...state.interactionCounts,
        GameState.interactionKey('aktivite', action.id): done + 1,
        // Yıllık sağlık kazancı yalnızca **gerçekten uygulanan** kadar
        // sayılır; sayaç yaşa aittir ve yeni yaşta sıfırlanır (D-100).
        if (action.venue == ActivityVenue.saglikMerkezi &&
            !kotuSonuc &&
            saglikKazanci > 0)
          GameState.interactionKey(healthCentreCounterId, 'aktivite'):
              state.interactionCount(healthCentreCounterId, 'aktivite') +
                  saglikKazanci,
      }),
      // Yönlendirme izleri: tahlil yapılınca kapanır, check-up yeni bir
      // yönlendirme açabilir (D-076).
      storyFlags: _flags(state, action, kotuSonuc),
    );

    // Kalıcı hobi geçmişi (Paket 39). Eylemin kendisi değişmez; yalnızca
    // beslediği bir hobi varsa geçmişe iz düşer.
    next = HobbyTracker.creditActivity(next, action.id);

    // Bakım geçmişi (D-072): spor salonu, berber ve kurs yıllık
    // yıpranmayı yavaşlatır. Kayıt tek noktadan yazılır.
    next = UpkeepTracker.credit(next, action);

    // Birlikte gidildiyse sahne, bağ ve ortak geçmiş burada işlenir
    // (Paket 41). Tek çıkış noktası: çifte kayıt oluşamaz.
    if (companion != null) {
      next = _applyCompanion(state, next, action, companion, rng);
      final String sahne = next.log.last.text;
      final List<AppliedEffect> etkiler = diffAppliedEffects(state, next);
      next = _announce(state, next, action, sahne, etkiler, companion);
      return ActivityResult(
        state: next,
        outcome: ActivityOutcome(
          applied: true,
          text: sahne,
          effects: etkiler,
          noNewBenefit: factor == 0,
        ),
      );
    }

    final String ucret =
        odenecek > 0 ? ' ${trMoney(odenecek)} ödedin.' : '';
    final String metin;
    if (kotuSonuc) {
      metin = '${action.label}: sonuç umduğun gibi olmadı. Hekim '
          'zamanla oturacağını söylüyor ama şu an memnun değilsin.'
          '$ucret';
    } else if (action.changesHairStyle) {
      metin = '${action.label}: artık saçın "$yeniStil".$ucret';
    } else {
      // Sağlık işlemleri artık ne olduğunu anlatır (D-076).
      final String? rapor = _healthText(state, action);
      metin = rapor ?? '${action.label} tamamlandı.$ucret';
    }

    GameState sonDurum = _log(next, metin);
    final List<AppliedEffect> etkiler = diffAppliedEffects(state, sonDurum);
    sonDurum = _announce(state, sonDurum, action, metin, etkiler, null);
    sonDurum = _announceHealth(state, sonDurum, action, metin, etkiler);

    return ActivityResult(
      state: sonDurum,
      outcome: ActivityOutcome(
        applied: true,
        text: metin,
        effects: etkiler,
        noNewBenefit: factor == 0,
      ),
    );
  }

  /// prototypeOnly: işlem kötü sonuçlandığında mutluluk etkisi.
  static const int prototypeOnlyBadOutcomeHappiness = -6;

  /// Eylemin hikâye izlerini günceller (D-076).
  ///
  /// Tahlile gidince yönlendirme kapanır; check-up yeni bir yönlendirme
  /// açabilir. Kötü sonuçlanan bir işlem iz bırakmaz.
  Set<String> _flags(GameState state, ActivityAction action, bool kotuSonuc) {
    final Set<String> izler = <String>{...state.storyFlags};
    if (action.clearsFlag != null) izler.remove(action.clearsFlag);
    if (!kotuSonuc && action.setsFlag != null) izler.add(action.setsFlag!);
    // Check-up sonucu tahlil gerektiriyorsa yönlendirme açılır.
    if (action.id == 'genel_kontrol' &&
        HealthChecks.checkup(state).needsLabTest) {
      izler.add(HealthChecks.labTestFlag);
    }
    return izler;
  }

  /// Sağlık işleminin anlatılacak sonucu; sağlık işlemi değilse `null`.
  ///
  /// Sonuç uydurulmaz: oyuncunun gerçek sağlık değerine, yaşına ve bakım
  /// geçmişine bakılarak üretilir.
  String? _healthText(GameState state, ActivityAction action) {
    switch (action.id) {
      case 'genel_kontrol':
        return HealthChecks.checkup(state).noticeText;
      case 'ruh_sagligi':
        return HealthChecks.therapyOutcome(state);
      case 'mevsim_asisi':
        return HealthChecks.vaccineOutcome(state);
      case 'dis_kontrol':
        return HealthChecks.dentalOutcome(state);
      case 'tahlil':
        // Yönlendirilen değerlerin büyük çoğunluğu temiz çıkar; kontrolün
        // amacı da budur. "Temiz mi" kararı yıl içinde sabittir.
        final bool temiz = !HealthChecks.checkup(state).lines.any(
              (HealthLine l) => l.status == OrganStatus.sorunlu,
            );
        return HealthChecks.labResult(state, clean: temiz);
      default:
        return null;
    }
  }

  /// Sağlık ve estetik işlemlerinin sonucunu ekran bildirimi yapar.
  ///
  /// Faho'nun isteği: "aşı olduğumuzda falan da bildirim olarak ekrana
  /// vermeliyiz; kullanıcı ne olduğunu gelen bildirim ile anlamalı".
  /// Göz muayenesi buraya girmez: onun kendi mini oyunu ve kendi
  /// bildirimi var (D-076).
  GameState _announceHealth(
    GameState before,
    GameState after,
    ActivityAction action,
    String metin,
    List<AppliedEffect> effects,
  ) {
    final bool saglik = action.venue == ActivityVenue.saglikMerkezi &&
        action.id != 'goz_muayenesi';
    final bool estetik = action.venue == ActivityVenue.estetik;
    if (!saglik && !estetik) return after;

    final int sira = timesDone(after, action);
    return Notices.enqueue(after, <PendingNotice>[
      PendingNotice(
        id: 'saglik-${action.id}-${after.player.age}-$sira',
        kind: NoticeKind.saglik,
        age: after.player.age,
        title: action.label,
        text: metin,
        effects: List<AppliedEffect>.unmodifiable(effects),
      ),
    ]);
  }

  /// Eğlence programlarının sonucunu **ekran bildirimi** olarak kuyruğa
  /// alır (D-074).
  ///
  /// Faho'nun isteği: "parka git, sinemaya git dediğimde bildirim olarak
  /// karşıma çıksın; bana 5, kızıma 5 mutluluk, onunla aramdaki ilişki
  /// iyileşti gibi". Bildirimde yazan her satır durumun öncesi ile
  /// sonrası karşılaştırılarak üretilir; gerçekleşmemiş bir kazanç
  /// yazamaz.
  ///
  /// Yalnızca **Eğlence** mekânı bildirim üretir: berberde saç kestirmek
  /// ekranı kesmeye değmez, kartındaki sonuç yeterlidir.
  GameState _announce(
    GameState before,
    GameState after,
    ActivityAction action,
    String metin,
    List<AppliedEffect> effects,
    Person? companion,
  ) {
    if (action.venue != ActivityVenue.eglence) return after;
    if (effects.isEmpty) return after;

    // Kimlik tekrar sayısını da içerir: aynı yıl ikinci kez gidildiğinde
    // bildirim "zaten kuyrukta" diye düşmez.
    final int sira = timesDone(after, action);
    final String kimlik = companion == null
        ? 'aktivite-${action.id}-${after.player.age}-$sira'
        : 'aktivite-${action.id}-${companion.id}-${after.player.age}-$sira';

    return Notices.enqueue(after, <PendingNotice>[
      PendingNotice(
        id: kimlik,
        kind: NoticeKind.aktivite,
        age: after.player.age,
        title: action.label,
        text: metin,
        personId: companion?.id,
        effects: List<AppliedEffect>.unmodifiable(effects),
      ),
    ]);
  }

  /// Birlikte gidilen eylemin kişiye bağlı sonuçları.
  ///
  /// Bağ ve fazladan mutluluk aynı yıl aynı kişiyle tekrar çıkıldıkça
  /// azalır: aynı kişiyle üst üste sinemaya giderek bağ kasılamaz.
  /// Ortak geçmişe **tek** bir satır düşer.
  GameState _applyCompanion(
    GameState before,
    GameState after,
    ActivityAction action,
    Person companion,
    Random rng,
  ) {
    final int birlikte = Outing.timesWith(before, action, companion);
    final double oran = Outing.prototypeOnlyRepeatCurve[
        min(birlikte, Outing.prototypeOnlyRepeatCurve.length - 1)];
    final int bagArtisi =
        max(1, (Outing.prototypeOnlyCompanionBond * oran).round());
    final int mutlulukArtisi =
        (Outing.prototypeOnlyCompanionHappiness * oran).round();

    final String sahne = Outing.sceneFor(action, companion, rng);

    GameState next = after.copyWith(
      player: after.player.copyWith(
        stats: after.player.stats.gain(
          happiness: mutlulukArtisi,
        ),
      ),
      people: after.people
          .map((Person p) => p.id == companion.id
              ? p.copyWith(
                  bond: (p.bond + bagArtisi).clamp(0, 100),
                  // Yoldaş da keyif alır (D-074). Oyuncunun aldığı payla
                  // aynı eğriden gelir; kimse tek taraflı eğlenmez.
                  happiness: p.happiness +
                      Outing.companionHappinessGain(action, oran),
                )
              : p)
          .toList(growable: false),
      interactionCounts: Map<String, int>.unmodifiable(<String, int>{
        ...after.interactionCounts,
        GameState.interactionKey('birlikte-${companion.id}', action.id):
            birlikte + 1,
      }),
      // Anlamlı temas: birlikte çıkmak da görüşmektir, bağ sönümlenmesi
      // bunu görmeli (D-024).
      lastInteractionAge: Map<String, int>.unmodifiable(<String, int>{
        ...after.lastInteractionAge,
        companion.id: after.player.age,
      }),
    );

    // Ortak geçmişe düşen tek satır; kişiye bağlıdır.
    next = next.copyWith(
      log: List<LifeLogEntry>.unmodifiable(<LifeLogEntry>[
        ...next.log,
        LifeLogEntry(
          age: next.player.age,
          text: sahne,
          category: LogCategory.kisisel,
          personId: companion.id,
        ),
      ]),
    );
    return next;
  }

  // =====================================================================
  // Fal ve Tarot (Paket 27)
  // =====================================================================

  /// Bu eylem bir fal mı? Sonuç metni rastgele seçilir.
  static bool isFortune(ActivityAction action) =>
      action.venue == ActivityVenue.falTarot;

  /// Fala baktırır.
  ///
  /// **Sonuç rastgeledir ve iyi de kötü de çıkabilir.** Oyunun olaylarını
  /// yönlendirmez, kesin bir gelecek söylemez; yalnızca biraz keyif ya da
  /// biraz hayal kırıklığı getirir. Tekrar edildikçe kazanç azalır
  /// (D-019 ile aynı ilke), ama **kötü sonuç sönümlenmez**: hoşuna
  /// gitmeyen falı tekrar tekrar baktırıp etkisiz hâle getiremezsin.
  ActivityResult tellFortune({
    required GameState state,
    required ActivityAction action,
    required Random rng,
  }) {
    final InteractionAvailability check = availability(state, action);
    if (!check.isAllowed) return _blocked(state, check.reason!);

    final int done = timesDone(state, action);
    final double factor =
        prototypeOnlyRewardCurve[min(done, prototypeOnlyRewardCurve.length - 1)];

    final ({String text, int happiness}) okuma =
        _readingFor(state, action, rng);
    // Olumlu etki tekrar edildikçe azalır; olumsuz etki **tam** uygulanır.
    final int delta = okuma.happiness >= 0
        ? _scaled(okuma.happiness, factor)
        : okuma.happiness;

    final GameState next = state.copyWith(
      player: state.player.copyWith(
        wallet: state.player.wallet - action.cost,
        stats: state.player.stats.gain(
          happiness: delta,
        ),
      ),
      interactionCounts: Map<String, int>.unmodifiable(<String, int>{
        ...state.interactionCounts,
        GameState.interactionKey('aktivite', action.id): done + 1,
      }),
    );

    return ActivityResult(
      state: _log(next, okuma.text),
      outcome: ActivityOutcome(
        applied: true,
        text: okuma.text,
        effects: diffAppliedEffects(state, next),
        // Olumsuz fal "kazanç kalmadı" sayılmaz; sonuç gerçek.
        noNewBenefit: factor == 0 && okuma.happiness >= 0,
      ),
    );
  }

  ({String text, int happiness}) _readingFor(
    GameState state,
    ActivityAction action,
    Random rng,
  ) {
    switch (action.id) {
      case 'kahve_fali':
        final FortuneReading r =
            kCoffeeReadings[rng.nextInt(kCoffeeReadings.length)];
        return (text: r.text, happiness: r.prototypeOnlyHappiness);
      case 'tarot_actir':
        final TarotCard k = kTarotCards[rng.nextInt(kTarotCards.length)];
        return (
          text: '${k.name} kartı çıktı. ${k.text}',
          happiness: k.prototypeOnlyHappiness,
        );
      case 'burc_yorumu':
        final Zodiac burc = Astrology.zodiacOf(state);
        final List<FortuneReading> liste =
            kHoroscopes[burc] ?? const <FortuneReading>[];
        if (liste.isEmpty) {
          return (
            text: '${burc.display} için bu dönem bir şey yazmamışlar.',
            happiness: 0,
          );
        }
        final FortuneReading r = liste[rng.nextInt(liste.length)];
        return (
          text: '${burc.display} yorumu: ${r.text}',
          happiness: r.prototypeOnlyHappiness,
        );
      default:
        return (text: '${action.label} tamamlandı.', happiness: 0);
    }
  }

  // =====================================================================
  // Kütüphane
  // =====================================================================

  /// Yaşa uygun kitaplar.
  List<BookInfo> availableBooks(GameState state) => booksFor(state.player.age);

  /// Kitabı açar (ilerleme kaydı yoksa oluşturur).
  ActivityResult openBook(GameState state, BookInfo book) {
    if (!book.fitsAge(state.player.age)) {
      return _blocked(state, 'Bu kitap şu an sana uygun değil.');
    }
    if (state.bookProgress(book.id) != null) {
      // Zaten açılmış; durum değişmez.
      return ActivityResult(
        state: state,
        outcome: ActivityOutcome(
          applied: true,
          text: '${book.title} kaldığın yerden açıldı.',
        ),
      );
    }

    final GameState next = state.copyWith(
      books: List<BookProgress>.unmodifiable(<BookProgress>[
        ...state.books,
        BookProgress(
          bookId: book.id,
          pagesRead: 0,
          startedAtAge: state.player.age,
        ),
      ]),
    );
    final String metin = '${book.title} kitabını açtın.';
    return ActivityResult(
      state: _log(next, metin),
      outcome: ActivityOutcome(applied: true, text: metin),
    );
  }

  /// Bir sayfa çevirir; son sayfada kitap biter ve kazanç **bir kez**
  /// uygulanır.
  ///
  /// Bitmiş kitabın sayfalarına tekrar tıklamak yeni kazanç vermez.
  ActivityResult turnPage(GameState state, BookInfo book) {
    final BookProgress? mevcut = state.bookProgress(book.id);
    if (mevcut == null) {
      return _blocked(state, 'Önce kitabı açman gerekiyor.');
    }
    if (mevcut.finished) {
      return _blocked(
        state,
        '${book.title} zaten bitti. Yeniden okumak yeni bir kazanç vermez.',
      );
    }

    final int okunan = mevcut.pagesRead + 1;
    final bool bitti = okunan >= book.pages;

    List<BookProgress> books = state.books
        .map((BookProgress b) => b.bookId == book.id
            ? b.copyWith(pagesRead: okunan, finished: bitti)
            : b)
        .toList(growable: false);
    books = List<BookProgress>.unmodifiable(books);

    GameState next = state.copyWith(books: books);
    // Sayfa çevirmek de zihni çalıştırır (D-072): okuyan oyuncunun
    // zekâsı ileri yaşta daha yavaş aşınır. Kitabı bitirmek şart
    // değildir; düzenli okumak yeterlidir.
    next = UpkeepTracker.recordLearning(next);
    if (bitti) {
      next = next.copyWith(
        player: next.player.copyWith(
          stats: next.player.stats.gain(
            intelligence: book.intelligenceGain,
            happiness: book.happinessGain,
            charisma: book.charismaGain,
          ),
        ),
      );
    }

    // Bitirilen her kitap "okumak" hobisini besler (Paket 39).
    if (bitti) next = HobbyTracker.credit(next, HobbyKind.okuma);

    final String metin = bitti
        ? '${book.title} bitti. Son sayfayı kapattığında bir süre '
            'öylece kaldın.'
        : '${book.title}: $okunan / ${book.pages} sayfa.';

    return ActivityResult(
      state: bitti ? _log(next, metin) : next,
      outcome: ActivityOutcome(
        applied: true,
        text: metin,
        effects: diffAppliedEffects(state, next),
      ),
    );
  }

  ActivityResult _blocked(GameState state, String reason) => ActivityResult(
        state: state,
        outcome: ActivityOutcome(applied: false, text: reason),
      );

  GameState _log(GameState state, String text) => state.copyWith(
        log: List<LifeLogEntry>.unmodifiable(<LifeLogEntry>[
          ...state.log,
          LifeLogEntry(
            age: state.player.age,
            text: text,
            category: LogCategory.kisisel,
          ),
        ]),
      );

  static int _scaled(int base, double factor) => (base * factor).round();
}

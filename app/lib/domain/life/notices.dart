import '../../text/turkish_text.dart';
import '../models/game_state.dart';
import '../models/life_log.dart';
import '../models/pending_notice.dart';
import '../models/zodiac.dart';
import '../../data/fortune_catalog.dart';
import '../models/person.dart';
import '../models/relation.dart';

/// Cenazeye katılım seçenekleri (D-050).
///
/// Katılmak ile masrafa katkıda bulunmak **ayrı şeylerdir**: para
/// vermeyen oyuncu cenazeye katılabilir, katılamayan oyuncu da katkıda
/// bulunabilir.
enum FuneralAttendance {
  /// Cenazeye katıldı.
  katildi,

  /// Cenazeye katılamadı.
  katilamadi,
}

/// Cenaze katkısı seçenekleri.
enum FuneralChoice {
  /// Tam katkı.
  tamKatki,

  /// Elden geldiğince (cüzdanın yarısı kadar) katkı.
  kismiKatki,

  /// Bu sefer katkıda bulunmamak.
  katkiYok,
}

/// Ölüm, miras ve cenaze bildirimleri (D-050).
///
/// Kurallar:
/// - Bildirimde kişinin **adı ve gerçek bağı** yazar.
/// - Miras bildirimi yalnızca oyuncuya **gerçekten bir şey kaldıysa**
///   çıkar; kazanılmamış miras kazanılmış gibi gösterilmez.
/// - Cenaze katkısı bir **seçimdir**: zorunlu borç değildir, mirasın ön
///   koşulu değildir ve cüzdanı eksiye düşürmez.
/// - Aynı bildirim iki kez kuyruğa girmez, bekleyen bildirim kayıtla
///   birlikte saklanır.
///
/// Tutarlar `prototypeOnly`'dir (Q-074).
abstract final class Notices {
  /// prototypeOnly: cenaze masrafına önerilen katkı (₺).
  static const int prototypeOnlyFuneralCost = 25000;

  /// prototypeOnly: katkıda bulunmanın mutluluk etkisi.
  static const int prototypeOnlyContributionHappiness = 3;

  /// prototypeOnly: cenazeye katılmanın mutluluk etkisi.
  ///
  /// Vedalaşmak iyi gelir; katılamamak küçük bir burukluk bırakır.
  /// İkisi de kalıcı ceza değildir.
  static const int prototypeOnlyAttendanceHappiness = 2;
  static const int prototypeOnlyAbsenceHappiness = -3;

  /// prototypeOnly: cenazeye katılmanın hayattaki yakınlarla yakınlığa
  /// etkisi.
  static const int prototypeOnlyAttendanceBond = 2;

  /// prototypeOnly: çekirdek aile dışındaki bağlarda bildirim için
  /// gereken yakınlık.
  static const int prototypeOnlyCloseBond = 60;

  /// Yakınlığa bakılmaksızın bildirilen bağlar.
  static const Set<RelationType> noticeRelations = <RelationType>{
    RelationType.es,
    RelationType.anne,
    RelationType.baba,
    RelationType.cocuk,
    RelationType.kardes,
    RelationType.anneanne,
    RelationType.babaanne,
    RelationType.anneTarafiDede,
    RelationType.babaTarafiDede,
  };

  /// Yakınlık yüksekse bildirilen diğer bağlar.
  ///
  /// Hayatındaki sevgili, yakın arkadaş ve yakın akraba da "yakın biri"
  /// sayılır; uzak tanıdık için bildirim çıkmaz.
  static const Set<RelationType> bondBasedRelations = <RelationType>{
    RelationType.sevgili,
    RelationType.arkadas,
    RelationType.eskiEs,
    RelationType.teyze,
    RelationType.dayi,
    RelationType.hala,
    RelationType.amca,
  };

  /// Bu kişinin vefatı bildirilir mi?
  static bool shouldNotify(Person person) {
    if (noticeRelations.contains(person.relation)) return true;
    return bondBasedRelations.contains(person.relation) &&
        person.bond >= prototypeOnlyCloseBond;
  }

  /// Cenaze katkısı sorulan bağlar.
  static const Set<RelationType> funeralRelations = <RelationType>{
    RelationType.es,
    RelationType.anne,
    RelationType.baba,
    RelationType.cocuk,
    RelationType.kardes,
  };

  static String deathNoticeId(String personId) => 'olum-$personId';
  static String funeralNoticeId(String personId) => 'cenaze-$personId';
  static String inheritanceNoticeId(String personId) => 'miras-$personId';

  /// Vefat bildirimi.
  static PendingNotice death({
    required Person person,
    required int playerAge,
    required String cause,
    required int happinessDelta,
  }) {
    final String bag = person.labelFor(playerAge);
    return PendingNotice(
      id: deathNoticeId(person.id),
      kind: NoticeKind.olum,
      age: playerAge,
      personId: person.id,
      title: 'Bir kaybın var',
      text: '$bag ${person.fullName}, ${person.age} yaşında $cause '
          'nedeniyle hayatını kaybetti.',
      happinessDelta: happinessDelta,
    );
  }

  /// Cenaze katkısı bildirimi.
  static PendingNotice funeral({
    required Person person,
    required int playerAge,
  }) {
    final String bag = person.labelFor(playerAge);
    return PendingNotice(
      id: funeralNoticeId(person.id),
      kind: NoticeKind.cenaze,
      age: playerAge,
      personId: person.id,
      title: 'Cenaze masrafları',
      text: '$bag ${person.firstName} için cenaze hazırlıkları yapılıyor. '
          'Cenazeye katılıyorsun; masraflara katkıda bulunmak ister misin?',
      funeralCost: prototypeOnlyFuneralCost,
    );
  }

  /// Miras bildirimi; oyuncuya bir şey kalmadıysa `null`.
  static PendingNotice? inheritance({
    required Person person,
    required int playerAge,
    required int money,
    required List<String> itemNames,
  }) {
    if (money <= 0 && itemNames.isEmpty) return null;
    final String bag = person.labelFor(playerAge);
    final StringBuffer metin = StringBuffer(
      '$bag ${person.fullName} vefatının ardından mirastan payına ',
    );
    if (money > 0 && itemNames.isNotEmpty) {
      metin.write('${trMoney(money)} ve ${itemNames.join(', ')} düştü.');
    } else if (money > 0) {
      metin.write('${trMoney(money)} düştü.');
    } else {
      metin.write('${itemNames.join(', ')} düştü.');
    }
    return PendingNotice(
      id: inheritanceNoticeId(person.id),
      kind: NoticeKind.miras,
      age: playerAge,
      personId: person.id,
      title: 'Miras',
      text: metin.toString(),
      money: money,
      itemNames: List<String>.unmodifiable(itemNames),
    );
  }

  // -----------------------------------------------------------------
  // Okul dönüm noktaları (Paket 17)
  // -----------------------------------------------------------------
  //
  // Bu anlar günlüğe tek satır olarak da yazılıyordu ama oyuncu çoğu kez
  // fark etmeden geçiyordu. Okula başlamak, liseye geçmek ve okulu
  // bitirmek ekranda açıkça bildirilir. Bildirim **bilgilendirmedir**:
  // seçim sormaz, hiçbir değeri değiştirmez.

  /// Doğum bildirimi (Paket 26): her çocuk için bir kez.
  static String birthNoticeId(String childId) => 'dogum-$childId';

  /// Bebek doğdu.
  ///
  /// Metin yalnızca **gerçekten olan** bilgiyi yazar: çocuğun adı ve
  /// diğer ebeveynin adı. Uydurma ayrıntı eklenmez.
  static PendingNotice birth({
    required int playerAge,
    required String childId,
    required String childName,
    required bool isGirl,
    String? otherParentName,
  }) =>
      PendingNotice(
        id: birthNoticeId(childId),
        kind: NoticeKind.dogum,
        age: playerAge,
        title: isGirl ? 'Kızınız oldu' : 'Oğlunuz oldu',
        text: otherParentName == null
            ? '$childName doğdu. Bugünden sonra hayatında bir kişi daha '
                'var.'
            : '$childName doğdu. Sen ve $otherParentName bir yıldır '
                'bunu bekliyordunuz.',
        personId: childId,
      );

  /// Burçsal dönem bildirimi (Paket 27): aynı dönem aynı yaşta bir kez.
  static String zodiacNoticeId(String periodId, int age) =>
      'burc-$periodId-$age';

  /// "Şu dönem geldi, şu burçlar etkileniyor."
  ///
  /// Mutluluk etkisi bildirimde **gerçekten uygulanan** değerdir; sahte
  /// bir puan gösterilmez.
  static PendingNotice zodiacPeriod({
    required int playerAge,
    required ZodiacPeriod period,
    required Zodiac zodiac,
    required int happinessDelta,
  }) =>
      PendingNotice(
        id: zodiacNoticeId(period.id, playerAge),
        kind: NoticeKind.burc,
        age: playerAge,
        title: period.name,
        text: '${period.text}\n\nSen ${zodiac.display} burcusun; bu '
            'dönemden etkilenenlerdensin.',
        happinessDelta: happinessDelta,
      );

  /// Askerlik bildirimleri (Paket 29).
  static const String militaryCallNoticeId = 'askerlik-celp';
  static const String militaryDischargeNoticeId = 'askerlik-terhis';

  /// Celp geldi.
  static PendingNotice militaryCall({required int playerAge}) => PendingNotice(
        id: militaryCallNoticeId,
        kind: NoticeKind.askerlik,
        age: playerAge,
        title: 'Askerlik celbi',
        text: 'Askerlik çağrın geldi. Meslek bölümündeki Askerlik '
            'menüsünden er olarak gidebilir, bedelli ödeyebilir ya da '
            'koşulların uygunsa astsubay veya subay olarak '
            'başvurabilirsin.',
      );

  /// Terhis oldu.
  static PendingNotice militaryDischarge({
    required int playerAge,
    String? rankLabel,
  }) =>
      PendingNotice(
        id: militaryDischargeNoticeId,
        kind: NoticeKind.askerlik,
        age: playerAge,
        title: 'Terhis',
        text: rankLabel == null
            ? 'Askerliğin bitti. Bugünden sonra bu iş kapandı.'
            : '$rankLabel olarak görev süren tamamlandı.',
      );

  static const String schoolStartNoticeId = 'okul-baslangic';
  static const String highSchoolStartNoticeId = 'okul-lise-gecis';
  static const String highSchoolEndNoticeId = 'okul-lise-bitis';
  static const String universityEndNoticeId = 'okul-universite-bitis';

  /// İlkokul birinci sınıf.
  static PendingNotice schoolStart({required int playerAge}) => PendingNotice(
        id: schoolStartNoticeId,
        kind: NoticeKind.okul,
        age: playerAge,
        title: 'Okul başlıyor',
        text: 'Bugün ilkokul birinci sınıfa başlıyorsun. Çantan dünden '
            'hazır, önlüğün ütülü. Sınıfta seni tanımadığın yirmi kişi '
            've hiç duymadığın bir öğretmen adı bekliyor.',
      );

  /// Ortaokul bitti, lise başlıyor.
  ///
  /// [placementScore] gerçekten hesaplanmış yerleştirme puanıdır;
  /// hesaplanmadıysa puan satırı hiç yazılmaz.
  static PendingNotice highSchoolStart({
    required int playerAge,
    int? placementScore,
  }) {
    final StringBuffer metin = StringBuffer(
      'Ortaokul bitti. Sekiz yılın ardından sıra lisede: yeni bir bina, '
      'yeni bir sınıf listesi, daha uzun ders saatleri.',
    );
    if (placementScore != null) {
      metin.write(
        ' Yerleştirme puanın $placementScore. Artık lise alanını '
        'seçebilirsin.',
      );
    }
    return PendingNotice(
      id: highSchoolStartNoticeId,
      kind: NoticeKind.okul,
      age: playerAge,
      title: 'Lise başlıyor',
      text: metin.toString(),
    );
  }

  /// Lise bitti.
  static PendingNotice highSchoolEnd({
    required int playerAge,
    int? examScore,
  }) {
    final StringBuffer metin = StringBuffer(
      'Lise bitti. Defterleri bir kutuya koydun, sıranın üstündeki yazılar '
      'artık başkasının olacak.',
    );
    if (examScore != null) {
      metin.write(
        ' Üniversite sınavından $examScore puan aldın; ne yapacağını '
        'artık sen seçeceksin.',
      );
    } else {
      metin.write(' Bundan sonrasını sen seçeceksin.');
    }
    return PendingNotice(
      id: highSchoolEndNoticeId,
      kind: NoticeKind.okul,
      age: playerAge,
      title: 'Lise bitti',
      text: metin.toString(),
    );
  }

  /// Üniversite bitti.
  static PendingNotice universityEnd({
    required int playerAge,
    String? programName,
  }) {
    final String bolum = programName == null ? '' : ' $programName';
    return PendingNotice(
      id: universityEndNoticeId,
      kind: NoticeKind.okul,
      age: playerAge,
      title: 'Mezun oldun',
      text: 'Üniversite$bolum bölümünden mezun oldun. Diploman elinde; '
          'okul kapısından son kez öğrenci olarak çıktın.',
    );
  }

  /// Bildirimleri kuyruğa ekler.
  ///
  /// Aynı kimlikli bildirim zaten kuyruktaysa **tekrar eklenmez**; mevcut
  /// kuyruk ezilmez, yeni bildirimler sona eklenir.
  static GameState enqueue(GameState state, Iterable<PendingNotice> yeni) {
    final Set<String> mevcut = <String>{
      for (final PendingNotice n in state.notices) n.id,
    };
    final List<PendingNotice> kuyruk = <PendingNotice>[...state.notices];
    for (final PendingNotice n in yeni) {
      if (mevcut.add(n.id)) kuyruk.add(n);
    }
    if (kuyruk.length == state.notices.length) return state;
    return state.copyWith(notices: List<PendingNotice>.unmodifiable(kuyruk));
  }

  /// Kuyruktaki ilk bildirimi kaldırır.
  static GameState dismissFirst(GameState state) {
    if (state.notices.isEmpty) return state;
    return state.copyWith(
      notices: List<PendingNotice>.unmodifiable(state.notices.sublist(1)),
    );
  }

  /// Cenaze katkısı için gerçekten ödenebilecek tutar.
  ///
  /// Cüzdan **eksiye düşmez**: para yetmiyorsa kısmi katkı önerilir,
  /// o da yoksa katkı seçeneği hiç açılmaz.
  static int amountFor(GameState state, PendingNotice notice, FuneralChoice choice) {
    final int cuzdan = state.player.wallet;
    switch (choice) {
      case FuneralChoice.tamKatki:
        return cuzdan >= notice.funeralCost ? notice.funeralCost : 0;
      case FuneralChoice.kismiKatki:
        return cuzdan <= 0 ? 0 : (cuzdan ~/ 2).clamp(0, notice.funeralCost);
      case FuneralChoice.katkiYok:
        return 0;
    }
  }

  /// Bu seçenek şu an sunulabilir mi?
  static bool canChoose(GameState state, PendingNotice notice, FuneralChoice choice) {
    switch (choice) {
      case FuneralChoice.tamKatki:
        return state.player.wallet >= notice.funeralCost;
      case FuneralChoice.kismiKatki:
        return state.player.wallet < notice.funeralCost &&
            amountFor(state, notice, choice) > 0;
      case FuneralChoice.katkiYok:
        return true;
    }
  }

  /// Cenaze katkısı seçimini uygular.
  ///
  /// Ödeme cüzdandan **bir kez** düşer ve günlüğe yazılır. Katkıda
  /// bulunmamak cenazeye katılmayı engellemez ve mirası etkilemez.
  static ({GameState state, String text}) respondToFuneral(
    GameState state,
    FuneralChoice choice, {
    FuneralAttendance attendance = FuneralAttendance.katildi,
  }) {
    if (state.notices.isEmpty ||
        state.notices.first.kind != NoticeKind.cenaze) {
      return (state: state, text: 'Bekleyen bir cenaze bildirimi yok.');
    }
    final PendingNotice notice = state.notices.first;
    final Person? kisi =
        notice.personId == null ? null : state.personById(notice.personId!);
    final String ad = kisi?.firstName ?? 'yakının';

    final int tutar = amountFor(state, notice, choice);
    final bool katildi = attendance == FuneralAttendance.katildi;

    // Katılım ve katkı **ayrı** anlatılır; biri diğerinin yerine geçmez.
    final String katilimMetni = katildi
        ? '$ad için cenazedeydin.'
        : '$ad için cenazeye katılamadın.';
    final String katkiMetni = tutar > 0
        ? ' Masraflara ${trMoney(tutar)} katkıda bulundun.'
        : ' Masraflara katkıda bulunmadın.';
    final String metin = '$katilimMetni$katkiMetni';

    GameState next = dismissFirst(state);

    final int mutlulukEtkisi =
        (katildi ? prototypeOnlyAttendanceHappiness : prototypeOnlyAbsenceHappiness) +
            (tutar > 0 ? prototypeOnlyContributionHappiness : 0);

    next = next.copyWith(
      player: next.player.copyWith(
        wallet: next.player.wallet - tutar,
        stats: next.player.stats.copyWith(
          happiness: next.player.stats.happiness + mutlulukEtkisi,
        ),
      ),
    );

    // Cenazede bulunmak hayattaki yakınlarla araya bir şey katar.
    if (katildi) {
      next = next.copyWith(
        people: next.people
            .map((Person p) => p.isAlive && p.relation.kanBagi
                ? p.copyWith(
                    bond: (p.bond + prototypeOnlyAttendanceBond).clamp(0, 100),
                  )
                : p)
            .toList(growable: false),
      );
    }

    next = next.copyWith(
      log: List<LifeLogEntry>.unmodifiable(<LifeLogEntry>[
        ...next.log,
        LifeLogEntry(
          age: next.player.age,
          text: metin,
          category: LogCategory.aile,
        ),
      ]),
    );
    return (state: next, text: metin);
  }
}

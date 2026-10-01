import 'dart:math';

import '../../data/name_pool.dart';
import '../models/game_state.dart';
import '../models/gender.dart';
import '../models/npc_marriage.dart';
import '../models/pending_notice.dart';
import '../models/person.dart';
import '../models/person_development.dart';
import '../models/relation.dart';
import '../models/wealth.dart';
import 'random_util.dart';

/// Bir çocuğun evlenmesinin sonucu.
class ChildMarriageResult {
  const ChildMarriageResult({
    required this.person,
    required this.notice,
    required this.logText,
    this.spouse,
  });

  final Person person;
  final PendingNotice notice;
  final String logText;

  /// Evlenen kişinin **eşi**, gerçek bir kişi kaydı olarak (Paket AP §16).
  ///
  /// `null` yalnızca eşin üretilemediği durumlarda olur (ör. kişi
  /// listesi verilmediyse); o zaman eski davranış sürer ve yalnızca ad
  /// kaydedilir. Çağıran bu kişiyi `state.people` içine eklemekle
  /// yükümlüdür.
  final Person? spouse;
}

/// Yetişkin çocukların **kendi** evlilikleri (D-121).
///
/// Faho bildirdi: "torunum olduğunda, kızım/çocuğum evlendiğinde pop-up
/// olarak bildirilsin; düğünlerine çağırılabileyim; aram kötü ise sadece
/// düğününün olduğunu, iyi ise direkt davetiye gibi gelsin".
///
/// Bu yüzden haberin **biçimi yakınlığa bağlıdır**: yakınsan davet
/// edilirsin, uzaksan haberi sonradan duyarsın. Oyun kimseyi yargılamaz;
/// yalnızca ilişkinin bugünkü hâlini anlatır.
///
/// Sayısal değerler `prototypeOnly`'dir (Q-133).
abstract final class ChildMarriage {
  /// prototypeOnly: evlenilebilecek en küçük yaş.
  static const int prototypeOnlyMinAge = 22;

  /// prototypeOnly: bir yılda evlenme ihtimalinin tabanı.
  static const double prototypeOnlyBaseChance = 0.10;

  /// prototypeOnly: yaşla artan pay (her yıl için).
  static const double prototypeOnlyPerYearBonus = 0.01;

  /// prototypeOnly: ihtimalin üst sınırı.
  static const double prototypeOnlyMaxChance = 0.28;

  /// prototypeOnly: düğüne davet edilmek için gereken yakınlık.
  ///
  /// Altındaysa haber yine gelir — ama davet olarak değil. Kayıt
  /// silinmez, evlilik yine olur; değişen yalnızca oyuncunun onu nasıl
  /// öğrendiğidir.
  static const int prototypeOnlyInviteBond = 45;

  /// Bu yaşta evlenme ihtimali.
  static double chanceFor(int age) {
    if (age < prototypeOnlyMinAge) return 0;
    final double artis = (age - prototypeOnlyMinAge) * prototypeOnlyPerYearBonus;
    return (prototypeOnlyBaseChance + artis).clamp(0.0, prototypeOnlyMaxChance);
  }

  /// Bu kişi bu yıl evlenebilir mi?
  static bool eligible(
    Person person, {
    RelationType relation = RelationType.cocuk,
  }) =>
      person.isAlive &&
      person.relation == relation &&
      person.age >= prototypeOnlyMinAge &&
      person.development != null &&
      !person.development!.isMarried;

  /// prototypeOnly: eşin yaşının çocuğun yaşından sapma bandı (±).
  static const int prototypeOnlyAgeSpread = 5;

  /// prototypeOnly: gelin/damadın başlangıç yakınlığı.
  ///
  /// Düşük: §24'ün kuralı "gelin/damat otomatik iyi ya da otomatik kötü
  /// karakter olmasın". Bağ zamanla kurulur.
  static const int prototypeOnlySpouseStartBond = 25;

  /// Bu yıl evlenip evlenmediğini belirler; evlenmediyse `null`.
  ///
  /// [state] verilirse eş **gerçek bir kişi kaydı** olarak üretilir
  /// (Paket AP §16) ve sonuçta [ChildMarriageResult.spouse] dolu döner.
  /// Verilmezse yalnızca ad kaydedilir — eski çağıranlar bozulmasın.
  static ChildMarriageResult? maybeMarry({
    required Person child,
    required int playerAge,
    required Random rng,
    RelationType relation = RelationType.cocuk,
    GameState? state,
  }) {
    if (!eligible(child, relation: relation)) return null;
    if (!rng.chance(chanceFor(child.age))) return null;

    // Eşin cinsiyeti çocuğun cinsiyetinin karşıtı seçilir; bu bir
    // prototip basitleştirmesidir, kesin kural değildir (Q-133).
    final Gender esCinsiyeti =
        child.gender == Gender.kadin ? Gender.erkek : Gender.kadin;
    final List<String> havuz =
        esCinsiyeti == Gender.kadin ? kadinIsimleri : erkekIsimleri;
    final String esAdi = havuz[rng.nextInt(havuz.length)];

    // --- Eş gerçek bir kişi olarak kurulur (Paket AP §16) -------------
    //
    // Paket AP'ye kadar buradan yalnızca bir **isim** çıkıyordu ve
    // `PersonDevelopment.spouseName` yorumunda açıkça "bu kişi ayrı bir
    // kayıt olarak tutulmaz" yazıyordu. Artık gelin/damat oyuncunun
    // hayatına giren bir insan: onunla vakit geçirilebiliyor, torunun
    // biyolojik ebeveyni olabiliyor ve kuşak devamında yeni oyuncunun
    // eşi oluyor (§62).
    //
    // Kimlik **evlilikten** türetiliyor, yıl ya da sayaçtan değil:
    // aynı evlilik her yıl yeni bir eş üretemez (§16, §54).
    final Person? es = state == null
        ? null
        : _createSpouse(
            state: state,
            child: child,
            spouseName: esAdi,
            spouseGender: esCinsiyeti,
            rng: rng,
          );

    final PersonDevelopment gelisim = child.development!
        .copyWith(
          marriedAtAge: child.age,
          spouseName: esAdi,
          spousePersonId: es?.id,
          marriageStatus: NpcMarriageStatus.evli,
        )
        .withMilestone(child.age, '$esAdi ile evlendi.');

    final Person guncel = child.copyWith(development: gelisim);
    final bool davetli = child.bond >= prototypeOnlyInviteBond;

    final String metin = davetli
        ? '${child.firstName} evleniyor: $esAdi ile. Düğün davetiyeni '
            'sana elden verdi; aranız iyi olduğu için haberi ilk '
            'duyanlardan biri sendin.'
        : '${child.firstName} evlenmiş: $esAdi ile. Haberi sonradan '
            'duydun; uzun zamandır görüşmüyordunuz.';

    // Bağ değiştiğinde yalnızca bildirimin başlığı ve kimlik öneki
    // değişir; kural tek yerde durur (D-158).
    //
    // Paket AO §28: üvey/yarım kardeş ve üvey çocuk da buraya girer.
    // Başlık ikili bir bayraktan değil bağın **kendi** adından türetilir
    // ki her yeni bağ için ikinci bir sistem yazılmasın. Çocuk ve kardeş
    // için üretilen kimlik öneği ve başlık aynen korunur.
    final String onEk = switch (relation) {
      RelationType.cocuk => 'cocuk',
      RelationType.kardes => 'kardes',
      _ => relation.name,
    };
    final String baslik = switch (relation) {
      RelationType.cocuk => 'Çocuğun evlendi',
      RelationType.kardes => 'Kardeşin evlendi',
      RelationType.uveyKardes => 'Üvey kardeşin evlendi',
      RelationType.yariKardes => 'Yarım kardeşin evlendi',
      RelationType.uveyCocuk => 'Üvey çocuğun evlendi',
      _ => 'Ailenden biri evlendi',
    };
    return ChildMarriageResult(
      spouse: es,
      person: guncel,
      notice: PendingNotice(
        id: '$onEk-evlilik-${child.id}-$playerAge',
        kind: NoticeKind.aileDonum,
        age: playerAge,
        title: davetli ? 'Düğün davetiyesi' : baslik,
        text: metin,
        personId: child.id,
      ),
      logText: metin,
    );
  }

  /// Çocuğun eşini gerçek bir kişi olarak kurar (§16).
  ///
  /// Kimlik, çocuğun kimliğinden ve **kaçıncı evliliği olduğundan**
  /// türetilir. Böylece:
  ///
  /// * aynı evlilik her yıl yeni eş üretmez (§16),
  /// * boşanıp yeniden evlenen çocuğun yeni eşi **farklı** bir kişi olur
  ///   (§23, §54),
  /// * aynı kişi iki kez eklenmez (kimlik çakışırsa üretim yapılmaz).
  static Person? _createSpouse({
    required GameState state,
    required Person child,
    required String spouseName,
    required Gender spouseGender,
    required Random rng,
  }) {
    final int kacinciEvlilik =
        (child.development?.pastMarriages.length ?? 0) + 1;
    final String id = 'cocugunesi-${child.id}-$kacinciEvlilik';
    // Çakışma varsa yeni kişi üretilmez: kayıt iki kez oluşmaz (§54).
    if (state.people.any((Person p) => p.id == id)) return null;

    final int yasFarki =
        rng.nextInt(prototypeOnlyAgeSpread * 2 + 1) - prototypeOnlyAgeSpread;
    // Eş de yetişkin olmalı; yaş bandı çocuğun yaşının etrafında.
    final int yas = (child.age + yasFarki).clamp(prototypeOnlyMinAge, 120);

    // Soyadı: kendi ailesinden gelir, çocuğun soyadı kopyalanmaz.
    final Set<String> kullanilanSoyad = <String>{
      state.player.lastName,
      for (final Person p in state.people) p.lastName,
    };
    String soyad = rng.pick(soyisimler);
    for (int d = 0; d < 20 && kullanilanSoyad.contains(soyad); d++) {
      soyad = rng.pick(soyisimler);
    }

    final bool calisiyor = yas < 65 && rng.chance(0.68);
    return Person(
      id: id,
      firstName: spouseName,
      lastName: soyad,
      gender: spouseGender,
      relation: RelationType.cocugunEsi,
      age: yas,
      isAlive: true,
      // Gelin/damat oyuncunun hanesinde yaşamaz: çocuk kendi evine
      // çıkmıştı, eşi de oraya gelir.
      inPlayerHousehold: false,
      employment:
          calisiyor ? EmploymentStatus.calisiyor : EmploymentStatus.issiz,
      occupation: calisiyor ? rng.pick(meslekler) : null,
      wealth: rng.pick(<WealthTier>[
        WealthTier.yoksul,
        WealthTier.ortaHalli,
        WealthTier.ortaHalli,
        WealthTier.varlikli,
      ]),
      bond: prototypeOnlySpouseStartBond + rng.nextInt(12),
      // Çocuğun yaşadığı şehirde yaşar; bilinmiyorsa oyuncunun şehri.
      city: child.city ?? state.player.currentCity,
    );
  }
}

import 'dart:math';

import '../../data/name_pool.dart';
import '../models/gender.dart';
import '../models/pending_notice.dart';
import '../models/person.dart';
import '../models/person_development.dart';
import '../models/relation.dart';
import 'random_util.dart';

/// Bir çocuğun evlenmesinin sonucu.
class ChildMarriageResult {
  const ChildMarriageResult({
    required this.person,
    required this.notice,
    required this.logText,
  });

  final Person person;
  final PendingNotice notice;
  final String logText;
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
  static bool eligible(Person person) =>
      person.isAlive &&
      person.relation == RelationType.cocuk &&
      person.age >= prototypeOnlyMinAge &&
      person.development != null &&
      !person.development!.isMarried;

  /// Bu yıl evlenip evlenmediğini belirler; evlenmediyse `null`.
  static ChildMarriageResult? maybeMarry({
    required Person child,
    required int playerAge,
    required Random rng,
  }) {
    if (!eligible(child)) return null;
    if (!rng.chance(chanceFor(child.age))) return null;

    // Eşin cinsiyeti çocuğun cinsiyetinin karşıtı seçilir; bu bir
    // prototip basitleştirmesidir, kesin kural değildir (Q-133).
    final Gender esCinsiyeti =
        child.gender == Gender.kadin ? Gender.erkek : Gender.kadin;
    final List<String> havuz =
        esCinsiyeti == Gender.kadin ? kadinIsimleri : erkekIsimleri;
    final String esAdi = havuz[rng.nextInt(havuz.length)];

    final PersonDevelopment gelisim =
        child.development!
            .copyWith(marriedAtAge: child.age, spouseName: esAdi)
            .withMilestone(child.age, '$esAdi ile evlendi.');

    final Person guncel = child.copyWith(development: gelisim);
    final bool davetli = child.bond >= prototypeOnlyInviteBond;

    final String metin = davetli
        ? '${child.firstName} evleniyor: $esAdi ile. Düğün davetiyeni '
            'sana elden verdi; aranız iyi olduğu için haberi ilk '
            'duyanlardan biri sendin.'
        : '${child.firstName} evlenmiş: $esAdi ile. Haberi sonradan '
            'duydun; uzun zamandır görüşmüyordunuz.';

    return ChildMarriageResult(
      person: guncel,
      notice: PendingNotice(
        id: 'cocuk-evlilik-${child.id}-$playerAge',
        kind: NoticeKind.aileDonum,
        age: playerAge,
        title: davetli ? 'Düğün davetiyesi' : 'Çocuğun evlendi',
        text: metin,
        personId: child.id,
      ),
      logText: metin,
    );
  }
}

import '../models/family_issue.dart';
import '../models/game_state.dart';
import '../models/person.dart';
import '../models/relation.dart';

/// Ailenin oyuncu üzerindeki duygusal etkisi: gurur ve endişe
/// (Paket AP §42-§46).
///
/// Dört kural bu dosyanın tamamında geçerli:
///
/// * **Etki gerçek bir olaydan doğar (§44, §45).** Gurur ancak o yıl
///   gerçekten bir başarı olduysa, endişe ancak o yıl gerçekten açık bir
///   aile meselesi konuşulduysa yazılır. "Aile var, o yüzden mutsuzsun"
///   diye bir etki yok.
/// * **Tekrar tekrar aynı rakam basılmaz (§46).** Dört yıl süren bir
///   mesele dört kez endişe yazmaz; soğuma süresi var.
/// * **Yakınlık ve mesafe etkinin büyüklüğünü değiştirir (§42, §43).**
///   Uzaktaki ya da arası kopuk bir çocuğun haberi daha az dokunur. Ama
///   mesafe hiçbir şeyi **durdurmaz**: çocuğun hayatı yine yaşanır,
///   haberi yine gelir.
/// * **Yıllık tavan var.** Beş çocuğu olan oyuncunun mutluluğu tek yılda
///   aileden dolayı dibe vurmaz.
///
/// Sayısal değerler `prototypeOnly`'dir (Q-133).
abstract final class FamilyMood {
  /// prototypeOnly: bir başarının mutluluğa katkısı.
  static const int prototypeOnlyPride = 4;

  /// prototypeOnly: süren bir meselenin mutluluktan düşürdüğü.
  static const int prototypeOnlyWorry = 3;

  /// prototypeOnly: aynı kişi için iki duygu kaydı arasında geçmesi
  /// gereken yıl (§46).
  static const int prototypeOnlyCooldown = 3;

  /// prototypeOnly: bir yılda ailenin mutluluğa toplam etkisinin sınırı.
  static const int prototypeOnlyYearlyCap = 6;

  /// prototypeOnly: etkinin yarıya indiği yakınlık eşiği (§42).
  static const int prototypeOnlyDistantBond = 30;

  /// Başarı bildiriminin soğuma anahtarı — `ChildSchoolIssue` ile aynı
  /// anahtar kullanılıyor ki iki yerde iki gerçeklik olmasın.
  static String achievementKey(String personId) => 'cocuk-basari:$personId';

  /// Duygu kaydının soğuma anahtarı.
  static String moodKey(String personId) => 'aile-duygu:$personId';

  /// Bu kişi oyuncudan uzakta mı yaşıyor? (§43)
  ///
  /// Şehri bilinmiyorsa uzak **sayılmaz**: bilinmeyen bilgi olumsuz
  /// yorumlanmaz.
  static bool livesFarAway(GameState state, Person person) {
    final String? sehir = person.city;
    if (sehir == null) return false;
    return sehir != state.player.currentCity;
  }

  /// Etkinin bu kişi için ölçeklenmiş hâli.
  ///
  /// Yakınlık düşükse ve kişi uzaktaysa etki küçülür; ama **sıfırlanmaz**
  /// — kendi çocuğunun haberi hiç dokunmaz diye bir kural olmaz.
  static int scaleFor(GameState state, Person person, int base) {
    int sonuc = base;
    if (person.bond < prototypeOnlyDistantBond) {
      sonuc = (sonuc / 2).round();
    }
    if (livesFarAway(state, person)) {
      sonuc = (sonuc / 2).round();
    }
    return sonuc.abs() < 1 ? (base.isNegative ? -1 : 1) : sonuc;
  }

  /// Bu kişi için bu yıl duygu kaydı yazılabilir mi? (§46)
  static bool offCooldown(GameState state, String personId, int newAge) {
    final int? son = state.lastInteractionAge[moodKey(personId)];
    if (son == null) return true;
    return newAge - son >= prototypeOnlyCooldown;
  }

  /// Bir yılın aile duygusunu işler.
  ///
  /// Dönen metinler oyuncunun günlüğüne yazılabilir.
  static ({GameState state, List<String> logTexts}) advanceYear(
    GameState state,
    int newAge,
  ) {
    GameState next = state;
    final List<String> satirlar = <String>[];
    int toplam = 0;

    // --- §44 gurur: o yıl gerçekten bir başarı oldu mu? --------------
    for (final Person kisi in state.people) {
      if (toplam.abs() >= prototypeOnlyYearlyCap) break;
      if (!kisi.isAlive) continue;
      if (kisi.relation != RelationType.cocuk) continue;
      if (state.lastInteractionAge[achievementKey(kisi.id)] != newAge) {
        continue;
      }
      if (!offCooldown(next, kisi.id, newAge)) continue;

      final int etki = scaleFor(state, kisi, prototypeOnlyPride);
      toplam += etki;
      next = _applyHappiness(next, etki);
      next = _markMood(next, kisi.id, newAge);
      satirlar.add('${kisi.firstName} için gurur duydun.');
    }

    // --- §45 endişe: o yıl konuşulan **açık** bir mesele var mı? -----
    for (final FamilyIssue mesele in state.familyIssues) {
      if (toplam.abs() >= prototypeOnlyYearlyCap) break;
      if (!mesele.isOpen) continue;
      if (mesele.lastEventAge != newAge) continue;
      final Person? kisi = next.personById(mesele.personId);
      if (kisi == null || !kisi.isAlive) continue;
      if (!offCooldown(next, kisi.id, newAge)) continue;

      final int etki = -scaleFor(state, kisi, prototypeOnlyWorry);
      toplam += etki;
      next = _applyHappiness(next, etki);
      next = _markMood(next, kisi.id, newAge);
      satirlar.add('${kisi.firstName} için için için üzüldün.');
    }

    return (state: next, logTexts: List<String>.unmodifiable(satirlar));
  }

  static GameState _applyHappiness(GameState state, int delta) =>
      state.copyWith(
        player: state.player.copyWith(
          stats: state.player.stats.gain(happiness: delta),
        ),
      );

  static GameState _markMood(GameState state, String personId, int newAge) =>
      state.copyWith(
        lastInteractionAge: <String, int>{
          ...state.lastInteractionAge,
          moodKey(personId): newAge,
        },
      );
}

import '../../data/possession_names.dart';
import '../models/applied_effect.dart';
import '../models/game_state.dart';
import '../models/person.dart';
import '../models/stats.dart';

/// İki oyun durumunu karşılaştırıp **gerçekten uygulanmış** değişimleri
/// listeler.
///
/// Niyet edilen değer değil, durumdaki fark okunur. Bir değer 100'e dayanmışsa
/// ve artış uygulanamamışsa listede yer almaz; böylece ekranda gerçekleşmemiş
/// bir kazanç gösterilmez.
List<AppliedEffect> diffAppliedEffects(GameState before, GameState after) {
  final List<AppliedEffect> effects = <AppliedEffect>[];

  // --- Karakter değerleri ---------------------------------------------
  final List<StatEntry> oncekiler = before.player.stats.entries;
  final List<StatEntry> sonrakiler = after.player.stats.entries;
  for (int i = 0; i < sonrakiler.length; i++) {
    final int fark = sonrakiler[i].value - oncekiler[i].value;
    if (fark != 0) {
      effects.add(AppliedEffect(label: sonrakiler[i].label, delta: fark));
    }
  }

  // --- Cüzdan (yalnızca oyuncunun kendi parası) ------------------------
  final int paraFarki = after.player.wallet - before.player.wallet;
  if (paraFarki != 0) {
    effects.add(
      AppliedEffect(label: 'Cüzdan', delta: paraFarki, unit: ' ₺'),
    );
  }

  // --- Kişilerle yakınlık ---------------------------------------------
  final Map<String, Person> oncekiKisiler = <String, Person>{
    for (final Person p in before.people) p.id: p,
  };
  for (final Person kisi in after.people) {
    final Person? onceki = oncekiKisiler[kisi.id];
    if (onceki == null) continue;
    final int fark = kisi.bond - onceki.bond;
    if (fark == 0) continue;
    effects.add(
      AppliedEffect(
        label: '${kisi.possessiveFor(after.player.age)} '
            '${kisi.firstName} ile yakınlık',
        delta: fark,
      ),
    );
  }

  // --- Hayata yeni giren kişiler ---------------------------------------
  for (final Person kisi in after.people) {
    if (oncekiKisiler.containsKey(kisi.id)) continue;
    effects.add(
      AppliedEffect(
        label: '${kisi.possessiveFor(after.player.age)} '
            '${kisi.fullName} hayatına girdi',
      ),
    );
  }

  // --- Eşyalar ----------------------------------------------------------
  for (final String esya in after.possessions) {
    if (before.possessions.contains(esya)) continue;
    effects.add(AppliedEffect(label: '${possessionName(esya)} kazanıldı'));
  }
  for (final String esya in before.possessions) {
    if (after.possessions.contains(esya)) continue;
    effects.add(AppliedEffect(label: '${possessionName(esya)} elden çıktı'));
  }

  return List<AppliedEffect>.unmodifiable(effects);
}

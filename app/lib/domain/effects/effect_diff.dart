import '../../data/possession_names.dart';
import '../models/applied_effect.dart';
import '../models/game_state.dart';
import '../models/owned_item.dart';
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
  // Karşılaştırma **eşya örneği** bazındadır: iki bisikletten biri satılsa
  // da değişim görünür.
  final Map<String, OwnedItem> oncekiEsyalar = <String, OwnedItem>{
    for (final OwnedItem i in before.items) i.id: i,
  };
  final Map<String, OwnedItem> sonrakiEsyalar = <String, OwnedItem>{
    for (final OwnedItem i in after.items) i.id: i,
  };

  for (final OwnedItem esya in after.items) {
    if (oncekiEsyalar.containsKey(esya.id)) continue;
    effects.add(AppliedEffect(label: '${esya.name} kazanıldı'));
  }
  for (final OwnedItem esya in before.items) {
    if (sonrakiEsyalar.containsKey(esya.id)) continue;
    effects.add(AppliedEffect(label: '${esya.name} elden çıktı'));
  }

  // Kondisyon ve takılan aksesuarlar.
  for (final OwnedItem esya in after.items) {
    final OwnedItem? onceki = oncekiEsyalar[esya.id];
    if (onceki == null) continue;
    final int fark = esya.condition - onceki.condition;
    if (fark != 0) {
      effects.add(
        AppliedEffect(label: '${esya.name} kondisyonu', delta: fark),
      );
    }
    for (final String aksesuar in esya.attachments) {
      final int oncekiSayi =
          onceki.attachments.where((String a) => a == aksesuar).length;
      final int sonrakiSayi =
          esya.attachments.where((String a) => a == aksesuar).length;
      if (sonrakiSayi > oncekiSayi) {
        effects.add(
          AppliedEffect(
            label: '${esya.name}: ${possessionName(aksesuar)} takıldı',
          ),
        );
      }
    }
  }

  return List<AppliedEffect>.unmodifiable(effects);
}

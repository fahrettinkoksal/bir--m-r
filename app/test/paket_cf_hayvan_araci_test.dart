/// Paket CF — hayvan sahiplenme aracının üç eksiği.
///
/// **Ölçülen sorun (120 hayat × 2 tohum bloğu).** Hayvan sahiplenen
/// hayat 89 ve 92, hayvanı ölen 83 ve 85 — ama **birden fazla hayvanı
/// olan hayat 0/240**. Sebep botun koşuluydu: `s.pets.isEmpty`. Ölen
/// hayvan kayıtta kaldığı için (kayıt silinmez, D-109) o koşul bir daha
/// hiç sağlanmıyordu. **Oyun tarafı sağlamdı:**
/// `PetCare.prototypeOnlyMaxLivingPets = 3` ve ölen hayvan "yaşayan"
/// sayılmıyor — yani ikinci hayvan ve ölenin yerine yenisi yolları
/// ölçüm dışı kalıyordu.
///
/// İkinci eksik: bot her hayatta `PetSpecies.values` sırasındaki **ilk**
/// uygun türü alıyordu (kedi 62/89); köpeğin, kuşun, kaplumbağanın
/// farklı masrafı, kaçma riski ve ömrü hiç ölçülmüyordu. Üçüncüsü: adı
/// bot veriyordu ("Zeytin" 66/89), yani oyunun kendi ad havuzu hiç
/// gezilmiyordu.
///
/// Düzeltmeden sonra (aynı iki blok):
///   birden fazla kez sahiplenen     0 → **44 / 40**
///   ölenin yerine yenisini alan     0 → **39 / 37**
///   tür çeşitliliği          kedi %70 → **10 tür** (izin isteyen timsah dahil)
///   adlar                 Zeytin %74 → **14 ad, oyunun havuzundan**
///   hayvan_cocukla (en nadir)   1 / 0 → **4 / 3**
library;

import 'package:bir_omur/data/pet_catalog.dart';
import 'package:bir_omur/domain/models/game_state.dart';
import 'package:bir_omur/domain/models/person.dart';
import 'package:bir_omur/domain/pets/pet_care.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/player_bot.dart';

void main() {
  group('Paket CF — hayvan aracı', () {
    test('ölenin yerine yenisi alınıyor ve tür çeşitleniyor', () {
      const int n = 60;
      int sahiplenen = 0;
      int birdenCok = 0;
      final Set<String> turler = <String>{};
      final Set<String> adlar = <String>{};
      int enFazlaYasayan = 0;
      for (int i = 0; i < n; i++) {
        int enCok = 0;
        final BotLifeResult r = playBotLife(
          archetype:
              PlayerArchetype.values[i % PlayerArchetype.values.length],
          seed: 11000 + i,
          onYear: (GameState s) {
            final int yasayan = PetCare.livingPets(s).length;
            if (yasayan > enCok) enCok = yasayan;
            for (final Pet p in s.pets) {
              adlar.add(p.name);
            }
          },
        );
        if (r.petsAdopted > 0) sahiplenen++;
        if (r.petsAdopted > 1) birdenCok++;
        turler.addAll(r.petSpecies);
        if (enCok > enFazlaYasayan) enFazlaYasayan = enCok;
      }

      expect(sahiplenen, greaterThanOrEqualTo(20),
          reason: '$n hayatta yalnızca $sahiplenen tanesi hayvan aldı');
      // Ölçülen: 120 hayatta 44 ve 40, yani 60 hayatta ~20. Eşik
      // ölçülenin yarısında: bu test dağılımı değil **yolun açık
      // olduğunu** korur.
      expect(
        birdenCok,
        greaterThanOrEqualTo(10),
        reason: 'Birden fazla kez hayvan sahiplenen hayat $birdenCok. '
            'Ölen hayvanın yerine yenisi alınamıyorsa oyunun ikinci '
            'hayvan yolu hiç ölçülmüyor demektir.',
      );
      expect(
        turler.length,
        greaterThanOrEqualTo(5),
        reason: 'Yalnızca ${turler.length} tür sahiplenildi '
            '(${turler.join(", ")}); tür başına masraf, kaçma riski ve '
            'ömür farkları ölçülmüyor',
      );
      // Oyunun kendi kuralı: aynı anda en fazla üç yaşayan hayvan.
      expect(
        enFazlaYasayan,
        lessThanOrEqualTo(PetCare.prototypeOnlyMaxLivingPets),
        reason: 'Aynı anda $enFazlaYasayan hayvan yaşadı; oyun sınırı '
            '${PetCare.prototypeOnlyMaxLivingPets}',
      );
      // Adı artık oyun koyuyor: kayıtlı her ad oyunun havuzunda olmalı.
      for (final String ad in adlar) {
        expect(
          kPetSuggestedNames.contains(ad),
          isTrue,
          reason: '"$ad" oyunun ad havuzunda yok; botun kendi adını '
              'vermesi oyunun adlandırma yolunu ölçüm dışı bırakır',
        );
      }
      expect(adlar.length, greaterThanOrEqualTo(5),
          reason: 'Yalnızca ${adlar.length} farklı ad görüldü');
    }, timeout: const Timeout(Duration(minutes: 20)));
  });
}

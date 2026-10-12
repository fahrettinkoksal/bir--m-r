import 'package:flutter/material.dart';

import '../../data/pet_catalog.dart';
import '../../domain/models/person.dart';
import '../../domain/pets/pet_care.dart';
import '../../state/game_scope.dart';
import '../../text/turkish_text.dart';
import 'kilim_divider.dart';

/// Evcil hayvan detay penceresi (D-133).
///
/// Hayvan kartında yalnızca ad, tür ve yaş görünüyordu; **sağlık,
/// yakınlık, kaç yıldır birlikte olunduğu ve kayıp geçmişi hiçbir yerde
/// yazmıyordu.** Bu pencere kaydın tamamını gösterir ve hiçbir şey
/// uydurmaz.
class PetDetailSheet extends StatelessWidget {
  const PetDetailSheet({super.key, required this.petId});

  final String petId;

  static Future<void> show(BuildContext context, {required String petId}) {
    return showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (BuildContext context) => PetDetailSheet(petId: petId),
    );
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final Pet? pet = GameScope.of(context)
        .state
        ?.pets
        .where((Pet p) => p.id == petId)
        .firstOrNull;
    if (pet == null) {
      return const SafeArea(
        child: Padding(
          padding: EdgeInsets.all(20),
          child: Text('Bu hayvanın kaydı bulunamadı.'),
        ),
      );
    }
    final int yas = GameScope.of(context).state!.player.age;
    final PetSpecies tur = PetCare.speciesOf(pet);

    return SafeArea(
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Row(
                children: <Widget>[
                  Icon(tur.icon, size: 26),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      pet.name,
                      style: theme.textTheme.headlineSmall,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                '${tur.label} · ${pet.age} yaşında',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 14),
              const KilimDivider(),
              const SizedBox(height: 14),

              _satir(theme, 'Sağlık', '${pet.health}/100'),
              _satir(theme, 'Yakınlık', '${pet.bond}/100'),
              if (pet.adoptedAtPlayerAge != null) ...<Widget>[
                _satir(
                  theme,
                  'Sahiplenme',
                  '${pet.adoptedAtPlayerAge} yaşındayken',
                ),
                _satir(
                  theme,
                  'Birlikte',
                  '${(yas - pet.adoptedAtPlayerAge!).clamp(0, 120)} yıl',
                ),
              ],
              _satir(theme, 'Yıllık bakım', trMoney(tur.yearlyCareCost)),
              _satir(
                theme,
                'Olağan ömür',
                '${tur.typicalLifespan} yıl (en çok ${tur.maxLifespan})',
              ),

              // Kayıp, yeni yuva ve vefat kayıtları silinmez (D-058).
              if (pet.missingSinceAge != null)
                _satir(
                  theme,
                  'Kayıp',
                  '${pet.missingSinceAge} yaşından beri aranıyor',
                ),
              if (pet.rehomedAtPlayerAge != null)
                _satir(
                  theme,
                  'Yeni yuva',
                  '${pet.rehomedAtPlayerAge} yaşındayken verildi',
                ),
              if (pet.diedAtPlayerAge != null)
                _satir(
                  theme,
                  'Vefat',
                  'Sen ${pet.diedAtPlayerAge} yaşındayken'
                  '${pet.diedAtAge == null ? '' : ', ${pet.diedAtAge} yaşında'}',
                ),
              if (!pet.inPlayerHousehold && pet.rehomedAtPlayerAge == null)
                _satir(theme, 'Hane', 'Seninle yaşamıyor'),

              const SizedBox(height: 18),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Kapat'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _satir(ThemeData theme, String baslik, String deger) => Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            SizedBox(
              width: 118,
              child: Text(
                baslik,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
            Expanded(
              child: Text(deger, style: theme.textTheme.bodyMedium),
            ),
          ],
        ),
      );
}

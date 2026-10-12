import 'package:flutter/material.dart';

import '../../../data/pet_catalog.dart';
import '../../../domain/models/interaction.dart';
import '../../../domain/models/person.dart';
import '../../../domain/pets/pet_care.dart';
import '../../../state/game_controller.dart';
import '../../../state/game_scope.dart';
import '../../../text/turkish_text.dart';
import '../../theme/bir_omur_theme.dart';
import '../../widgets/pet_detail_sheet.dart';
import '../../widgets/section_scaffold.dart';

/// Evcil hayvanlar sayfası (Paket 40 — Issue #67, 2. kısım).
///
/// D-146 ile **İlişkiler** menüsünün altına taşındı: hayvan bir mülk
/// değil, bir ilişkidir (Faho'nun isteği). Vefat etmiş hayvanlar
/// **listede kalır**, yalnızca etkileşime kapanır.
class PetsPage extends StatefulWidget {
  const PetsPage({
    super.key,
    required this.onBack,
    this.backLabel = 'İlişkiler',
  });

  final VoidCallback onBack;

  /// Geri düğmesinde yazan menü adı. Sayfa D-146 ile İlişkiler altına
  /// taşındı; parametre, ileride başka bir yerden açılırsa diye duruyor.
  final String backLabel;

  @override
  State<PetsPage> createState() => _PetsPageState();
}

class _PetsPageState extends State<PetsPage> {
  String? _sonuc;

  @override
  Widget build(BuildContext context) {
    final GameController controller = GameScope.of(context);
    // Aktif ve geçmiş ayrımı (D-109): şu an bakılanlar, vefat edenler ve
    // başka yuvaya verilenler ayrı başlıklarda durur.
    final List<Pet> yasayan = controller.livingPets;
    final List<Pet> vefat = controller.pets
        .where((Pet p) => !p.isAlive)
        .toList(growable: false);
    final List<Pet> verilen = controller.pets
        .where((Pet p) => p.isAlive && p.isRehomed)
        .toList(growable: false);

    return SectionScaffold(
      icon: Icons.pets_rounded,
      accent: BirOmurAccents.turuncu,
      title: 'Evcil hayvanlar',
      subtitle: 'Cüzdanında ${controller.state!.player.walletLabel} var. '
          'Bakım gideri her yıl bir kez alınır.',
      backLabel: widget.backLabel,
      onBack: widget.onBack,
      children: <Widget>[
        if (yasayan.isEmpty)
          const InfoPanel(
            icon: Icons.pets_outlined,
            text: 'Şu an evinde bir hayvan yok. Sahiplenmek ömür boyu '
                'süren bir karar değil ama uzun sürer.',
          ),
        if (yasayan.isNotEmpty) ...<Widget>[
          const MenuGroupTitle(
            text: 'Evdekiler',
            accent: BirOmurAccents.turuncu,
          ),
          for (final Pet pet in yasayan) ...<Widget>[
            _PetCard(
              pet: pet,
              playerAge: controller.state!.player.age,
              availabilityFor: (PetAction a) =>
                  controller.petActionAvailability(pet, a),
              timesDone: (PetAction a) =>
                  PetCare.timesDone(controller.state!, pet, a),
              onAction: (PetAction a) {
                final String? metin = controller.petInteract(pet, a);
                setState(() => _sonuc = metin);
              },
              rehomeAvailability: controller.petRehomeAvailability(pet),
              onRehome: () async {
                final bool? onay = await _rehomeOnayi(context, pet);
                if (onay != true) return;
                final String? metin = controller.rehomePet(pet);
                setState(() => _sonuc = metin);
              },
            ),
            const SizedBox(height: 12),
          ],
        ],
        const SizedBox(height: 4),
        const MenuGroupTitle(
          text: 'Sahiplen',
          accent: BirOmurAccents.yesil,
        ),
        const SizedBox(height: 4),
        // Sahiplenme menüsü gruplara ayrıldı (D-135). Faho'nun isteği:
        // tek uzun liste yerine kedi/köpek/kuş/egzotik ayrımı. Grup
        // kapalı başlar; oyuncu ilgilendiği grubu açar.
        for (final PetGroup grup in adoptablePetGroups) ...<Widget>[
          _PetGroupTile(
            group: grup,
            species: adoptableIn(grup),
            availabilityFor: controller.petAdoptionAvailability,
            onAdopt: (PetSpecies tur, String ad) {
              final String? metin = controller.adoptPet(tur, ad);
              setState(() => _sonuc = metin);
            },
          ),
          const SizedBox(height: 10),
        ],
        if (verilen.isNotEmpty) ...<Widget>[
          const SizedBox(height: 4),
          const MenuGroupTitle(
            text: 'Yeni yuvasına gidenler',
            accent: BirOmurAccents.yesil,
          ),
          for (final Pet pet in verilen) ...<Widget>[
            _MemorialRow(pet: pet),
            const SizedBox(height: 8),
          ],
        ],
        if (vefat.isNotEmpty) ...<Widget>[
          const SizedBox(height: 4),
          const MenuGroupTitle(
            text: 'Anılarda kalanlar',
            accent: BirOmurAccents.mor,
          ),
          for (final Pet pet in vefat) ...<Widget>[
            _MemorialRow(pet: pet),
            const SizedBox(height: 8),
          ],
        ],
        if (_sonuc != null) ...<Widget>[
          const SizedBox(height: 8),
          InfoPanel(icon: Icons.pets_rounded, text: _sonuc!),
        ],
      ],
    );
  }
}

/// Sahiplendirme kaza eseri seçilmesin diye ayrı onay ister (D-109).
Future<bool?> _rehomeOnayi(BuildContext context, Pet pet) => showDialog<bool>(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        title: Text('${pet.name} için yeni yuva'),
        content: Text(
          '${pet.name} başka bir aileye gidecek. Kaydı silinmez; '
          '"Yeni yuvasına gidenler" başlığında durur. Bu karar geri '
          'alınamaz.',
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Vazgeç'),
          ),
          FilledButton(
            key: const Key('pet_rehome_confirm'),
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Yeni yuvaya ver'),
          ),
        ],
      ),
    );

class _PetCard extends StatelessWidget {
  const _PetCard({
    required this.pet,
    required this.playerAge,
    required this.availabilityFor,
    required this.timesDone,
    required this.onAction,
    required this.rehomeAvailability,
    required this.onRehome,
  });

  final Pet pet;
  final int playerAge;
  final InteractionAvailability Function(PetAction) availabilityFor;
  final int Function(PetAction) timesDone;
  final void Function(PetAction) onAction;

  /// Sahiplendirme şu an mümkün mü? (D-109)
  final InteractionAvailability rehomeAvailability;

  final VoidCallback onRehome;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final PetSpecies tur = PetCare.speciesOf(pet);

    return Container(
      decoration: panelDecoration(context, radius: 20),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                AccentIconTile(
                  icon: tur.icon,
                  accent: BirOmurAccents.turuncu,
                  size: 38,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(pet.name, style: theme.textTheme.titleMedium),
                      Text(
                        '${tur.label} · ${pet.age} yaşında',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                // Kaydın tamamı ayrı pencerede (D-133): sağlık, yakınlık,
                // kaç yıldır birlikte, kayıp ve vefat geçmişi.
                IconButton(
                  key: Key('pet_detail_${pet.id}'),
                  tooltip: 'Kayıt',
                  icon: const Icon(Icons.info_outline),
                  onPressed: () =>
                      PetDetailSheet.show(context, petId: pet.id),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              _birliktelik(pet, playerAge),
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            Text(
              'Yıllık bakım: ${trMoney(tur.yearlyCareCost)}',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 10),
            for (final PetAction eylem in PetAction.values) ...<Widget>[
              _ActionRow(
                pet: pet,
                action: eylem,
                availability: availabilityFor(eylem),
                done: timesDone(eylem),
                onTap: () => onAction(eylem),
              ),
              const SizedBox(height: 8),
            ],
            // Sahiplendirme (D-109): vefat değildir, bir karardır.
            // Kapalıysa gerekçesi yazar (D-038).
            const SizedBox(height: 2),
            if (!rehomeAvailability.isAllowed)
              Text(
                rehomeAvailability.reason!,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              )
            else
              Align(
                alignment: Alignment.centerLeft,
                child: OutlinedButton(
                  key: Key('pet_rehome_${pet.id}'),
                  onPressed: onRehome,
                  child: const Text('Yeni bir yuva bul'),
                ),
              ),
          ],
        ),
      ),
    );
  }

  static String _birliktelik(Pet pet, int playerAge) {
    final int? baslangic = pet.adoptedAtPlayerAge;
    if (baslangic == null) return 'Sen doğduğunda bu evdeydi.';
    final int yil = playerAge - baslangic;
    if (yil <= 0) return 'Bu yıl sahiplendin.';
    return '$baslangic yaşındayken sahiplendin; $yil yıldır birlikte.';
  }
}

class _ActionRow extends StatelessWidget {
  const _ActionRow({
    required this.pet,
    required this.action,
    required this.availability,
    required this.done,
    required this.onTap,
  });

  final Pet pet;
  final PetAction action;
  final InteractionAvailability availability;
  final int done;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final int ucret =
        action.usesVetCost ? PetCare.speciesOf(pet).vetCost : action.cost;

    // Dar ekranda (360 px) düğme ile metin yan yana sıkışmasın diye
    // açıklama kendi satırında durur.
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          action.description,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        if (!availability.isAllowed)
          Text(
            availability.reason!,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        const SizedBox(height: 6),
        Wrap(
          spacing: 8,
          runSpacing: 6,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: <Widget>[
            FilledButton.tonal(
              key: Key('hayvan_${pet.id}_${action.id}'),
              onPressed: availability.isAllowed ? onTap : null,
              child: Text(action.label),
            ),
            Text(
              ucret == 0
                  ? 'Bu yıl $done/${action.maxPerAge}'
                  : '${trMoney(ucret)} · bu yıl $done/${action.maxPerAge}',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _AdoptCard extends StatefulWidget {
  const _AdoptCard({
    required this.species,
    required this.availability,
    required this.onAdopt,
  });

  final PetSpecies species;
  final InteractionAvailability availability;
  final void Function(String) onAdopt;

  @override
  State<_AdoptCard> createState() => _AdoptCardState();
}

class _AdoptCardState extends State<_AdoptCard> {
  late final TextEditingController _ad = TextEditingController();

  @override
  void dispose() {
    _ad.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final PetSpecies tur = widget.species;

    return Container(
      decoration: panelDecoration(context, radius: 20),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                AccentIconTile(
                  icon: tur.icon,
                  accent: BirOmurAccents.yesil,
                  size: 38,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(tur.label, style: theme.textTheme.titleMedium),
                ),
              ],
            ),
            const SizedBox(height: 6),
            // Özel izin gerektiren tür açıkça uyarılır (D-082): oyun
            // bunu sıradan bir tercih gibi sunmaz.
            if (tur.warning != null) ...<Widget>[
              Text(
                tur.warning!,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.error,
                ),
              ),
              const SizedBox(height: 6),
            ],
            Text(
              'Sahiplenme ${trMoney(tur.adoptionCost)} · yıllık bakım '
              '${trMoney(tur.yearlyCareCost)}',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            if (!widget.availability.isAllowed)
              Text(
                widget.availability.reason!,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            const SizedBox(height: 10),
            TextField(
              key: Key('hayvan_ad_${tur.name}'),
              controller: _ad,
              decoration: const InputDecoration(
                labelText: 'Adı',
                hintText: 'Boş bırakırsan bir ad seçilir',
              ),
            ),
            const SizedBox(height: 10),
            Align(
              alignment: Alignment.centerLeft,
              child: FilledButton(
                key: Key('hayvan_sahiplen_${tur.name}'),
                onPressed: widget.availability.isAllowed
                    ? () => widget.onAdopt(_ad.text)
                    : null,
                child: const Text('Sahiplen'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MemorialRow extends StatelessWidget {
  const _MemorialRow({required this.pet});

  final Pet pet;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Container(
      decoration: panelDecoration(context, radius: 16),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
        child: Row(
          children: <Widget>[
            AccentIconTile(
              icon: pet.isRehomed ? Icons.home_outlined : Icons.spa_outlined,
              accent:
                  pet.isRehomed ? BirOmurAccents.yesil : BirOmurAccents.mor,
              size: 34,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(pet.name, style: theme.textTheme.titleMedium),
                  Text(
                    pet.isRehomed
                        ? '${petSpeciesLabel(pet.species)} · '
                            '${pet.rehomedAtPlayerAge} yaşındayken yeni '
                            'bir yuvaya gitti'
                        : '${petSpeciesLabel(pet.species)} · '
                            '${pet.diedAtAge} yaşında vefat etti',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Hayvan grubu satırı (D-135).
///
/// Katlanır bir başlık: grup açılınca içindeki türler gösterilir. Kapalı
/// hâlde kaç tür olduğunu ve grubun kısa tanımını yazar.
class _PetGroupTile extends StatelessWidget {
  const _PetGroupTile({
    required this.group,
    required this.species,
    required this.availabilityFor,
    required this.onAdopt,
  });

  final PetGroup group;
  final List<PetSpecies> species;
  final InteractionAvailability Function(PetSpecies) availabilityFor;
  final void Function(PetSpecies, String) onAdopt;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    // Grupta şu an gerçekten açık olan tür var mı? Varsa rozet gösterilir.
    final int acik = species
        .where((PetSpecies s) => availabilityFor(s).isAllowed)
        .length;
    return Container(
      decoration: panelDecoration(context, radius: 18),
      child: Theme(
        // ExpansionTile'ın kendi çizgilerini kaldırıp panelin içine
        // oturtuyoruz; menü sade kalsın.
        data: theme.copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          key: Key('pet_group_${group.name}'),
          tilePadding: const EdgeInsets.symmetric(horizontal: 14),
          childrenPadding: const EdgeInsets.fromLTRB(14, 0, 14, 12),
          leading: AccentIconTile(
            icon: species.first.icon,
            accent: BirOmurAccents.turuncu,
            size: 36,
          ),
          title: Text(group.label, style: theme.textTheme.titleMedium),
          subtitle: Text(
            group.description,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          trailing: Text(
            acik == 0 ? '${species.length}' : '$acik/${species.length}',
            style: theme.textTheme.labelLarge?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          children: <Widget>[
            for (final PetSpecies tur in species) ...<Widget>[
              _AdoptCard(
                species: tur,
                availability: availabilityFor(tur),
                onAdopt: (String ad) => onAdopt(tur, ad),
              ),
              const SizedBox(height: 10),
            ],
          ],
        ),
      ),
    );
  }
}

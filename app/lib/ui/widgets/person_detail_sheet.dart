import 'package:flutter/material.dart';

import '../../data/item_catalog.dart';

import '../../domain/interaction/marriage_engine.dart';
import '../../domain/models/game_state.dart';
import '../../domain/models/interaction.dart';
import '../../domain/models/marriage.dart';
import '../../domain/models/person.dart';
import '../../domain/models/relation.dart';
import '../../state/game_scope.dart';
import 'effect_chips.dart';
import 'kilim_divider.dart';

/// Kişi ayrıntısı ve aile etkileşimleri.
///
/// Kişi kimliğiyle çalışır; etkileşimden sonra güncel kayıt durumdan yeniden
/// okunur. Yapılamayacak bir etkileşim düğme olarak gösterilmez, gerekçesi
/// yazılır.
class PersonDetailSheet extends StatefulWidget {
  const PersonDetailSheet({super.key, required this.personId});

  final String personId;

  static Future<void> show(BuildContext context, {required String personId}) {
    return showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (BuildContext context) => PersonDetailSheet(personId: personId),
    );
  }

  @override
  State<PersonDetailSheet> createState() => _PersonDetailSheetState();
}

class _PersonDetailSheetState extends State<PersonDetailSheet> {
  InteractionOutcome? _lastOutcome;
  String? _notice;

  void _run(InteractionKind kind) {
    final InteractionOutcome? outcome =
        GameScope.of(context).interact(widget.personId, kind);
    if (outcome == null) return;
    setState(() {
      _lastOutcome = outcome;
      _notice = null;
    });
  }

  /// Ayrılık (D-029): kişi kaydı silinmez, aynı kimlikle eski sevgili olur.
  Future<void> _breakUp(Person person) async {
    final bool? onay = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        title: const Text('Ayrılmak istiyor musun?'),
        content: Text(
          '${person.firstName} ile ilişkini bitireceksin. '
          'Kaydı silinmez; Aile bölümünde eski sevgili olarak kalır.',
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Vazgeç'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Ayrıl'),
          ),
        ],
      ),
    );
    if (onay != true || !mounted) return;
    final String? sonuc = GameScope.of(context).endRomance(widget.personId);
    setState(() {
      _lastOutcome = null;
      _notice = sonuc;
    });
  }

  /// Evlilik (Paket E1): sevgili **aynı kimlikle** eş olur.
  Future<void> _marry(Person person) async {
    final bool? onay = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        title: const Text('Evlenmek istiyor musun?'),
        content: Text(
          '${person.firstName} ile evleneceksin. Nikâh masrafı '
          '${MarriageEngine.prototypeOnlyWeddingCost} \u20BA cüzdanından '
          'çıkacak ve kendi haneni kuracaksın.',
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Vazgeç'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Evlen'),
          ),
        ],
      ),
    );
    if (onay != true || !mounted) return;
    final FamilyOutcome? sonuc = GameScope.of(context).marry(widget.personId);
    if (sonuc == null) return;
    setState(() {
      _lastOutcome = null;
      _notice = sonuc.text;
    });
  }

  /// Boşanma (Paket E1): kişi kaydı silinmez, eski eş olur.
  Future<void> _divorce(Person person) async {
    final bool? onay = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        title: const Text('Boşanmak istiyor musun?'),
        content: Text(
          '${person.firstName} ile evliliğin bitecek. Kaydı silinmez; '
          'İlişkiler bölümünde eski eş olarak kalır.',
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Vazgeç'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Boşan'),
          ),
        ],
      ),
    );
    if (onay != true || !mounted) return;
    final FamilyOutcome? sonuc = GameScope.of(context).divorce();
    if (sonuc == null) return;
    setState(() {
      _lastOutcome = null;
      _notice = sonuc.text;
    });
  }

  /// Çocuk sahibi olmak (Paket E2).
  void _haveChild() {
    final FamilyOutcome? sonuc = GameScope.of(context).haveChild();
    if (sonuc == null) return;
    setState(() {
      _lastOutcome = null;
      _notice = sonuc.text;
    });
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final GameState state = GameScope.of(context).state!;
    final Person? person = state.personById(widget.personId);
    if (person == null) return const SizedBox.shrink();

    final int playerAge = state.player.age;
    final InteractionAvailability availability =
        GameScope.of(context).availabilityFor(person);
    // Yalnızca gerçekten yapılabilen eylemler düğme olur; kalanlar
    // gerekçesiyle birlikte soluk gösterilir.
    final List<InteractionKind> available =
        availability.isAllowed
            ? GameScope.of(context).availableKindsFor(person)
            : const <InteractionKind>[];

    return SafeArea(
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(person.fullName, style: theme.textTheme.headlineSmall),
              const SizedBox(height: 4),
              Text(
                person.labelFor(playerAge),
                style: theme.textTheme.titleSmall?.copyWith(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 14),
              const KilimDivider(),
              const SizedBox(height: 14),
              _Row(
                label: 'Yaş',
                value:
                    person.isAlive ? '${person.age}' : '${person.age} (vefat etti)',
              ),
              _Row(label: 'Cinsiyet', value: person.gender.label),
              // Evlilik kaydı gerçek bir kayıttır; eş ve eski eşte görünür.
              if (state.marriage != null &&
                  state.marriage!.spouseId == person.id)
                _Row(
                  label: 'Evlilik',
                  value: _marriageLabel(state.marriage!),
                ),
              _Row(label: 'Durum', value: person.occupationLabel),
              if (person.wealth != null)
                _Row(label: 'Kendi maddi durumu', value: person.wealth!.label),
              // Kişinin gerçekten sahip olduğu eşyalar; miras bu listeden
              // dağıtılır (D-037, D-038).
              if (person.estate.isNotEmpty)
                _Row(
                  label: 'Sahip oldukları',
                  value: person.estate
                      .map((String t) => itemTypeOrFallback(t).name)
                      .join(', '),
                ),
              // Hane bilgisi bağ türünden bağımsızdır (D-014): tanışıklık,
              // arkadaşlık veya akrabalık kimseyi hanene eklemez.
              _Row(
                label: 'Hane',
                value: person.isAlive
                    ? (person.inPlayerHousehold
                        ? 'Seninle aynı evde yaşıyor'
                        : 'Ayrı evde yaşıyor')
                    : '—',
              ),
              if (person.isAlive) ...<Widget>[
                const SizedBox(height: 16),
                Text('Yakınlık', style: theme.textTheme.labelLarge),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    value: person.bond / 100,
                    minHeight: 8,
                    backgroundColor:
                        theme.colorScheme.outlineVariant.withValues(alpha: 0.4),
                    valueColor: AlwaysStoppedAnimation<Color>(
                      theme.colorScheme.secondary,
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 20),
              if (!availability.isAllowed)
                _Note(text: availability.reason!)
              else if (available.isEmpty)
                const _Note(
                  text: 'Şu an bu kişiyle yapabileceğin bir etkileşim yok.',
                )
              else
                _Actions(available: available, onSelected: _run),
              // Evlilik yalnızca sevgilide sunulur; koşul sağlanmıyorsa
              // düğme yerine gerekçe yazılır (sahte düğme olmaz).
              if (person.isAlive &&
                  person.relation == RelationType.sevgili) ...<Widget>[
                const SizedBox(height: 12),
                if (GameScope.of(context)
                    .marriageAvailability(widget.personId)
                    .isAllowed)
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      key: const Key('person_marry_button'),
                      onPressed: () => _marry(person),
                      icon: const Icon(Icons.favorite),
                      label: const Text('Evlen'),
                    ),
                  )
                else
                  _Note(
                    text: 'Evlenmek için: '
                        '${GameScope.of(context).marriageAvailability(widget.personId).reason}',
                  ),
              ],

              // Eşe özel eylemler: çocuk sahibi olmak ve boşanma.
              if (person.isAlive && person.relation == RelationType.es) ...<Widget>[
                const SizedBox(height: 12),
                if (GameScope.of(context).childAvailability().isAllowed)
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      key: const Key('person_child_button'),
                      onPressed: _haveChild,
                      icon: const Icon(Icons.child_friendly_outlined),
                      label: const Text('Çocuk sahibi olun'),
                    ),
                  )
                else
                  _Note(
                    text: 'Çocuk sahibi olmak için: '
                        '${GameScope.of(context).childAvailability().reason}',
                  ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    key: const Key('person_divorce_button'),
                    onPressed: () => _divorce(person),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: theme.colorScheme.error,
                      side: BorderSide(
                        color: theme.colorScheme.error.withValues(alpha: 0.5),
                      ),
                    ),
                    child: const Text('Boşan'),
                  ),
                ),
              ],
              // Ayrılma yalnızca gerçekten sevgili olan kişide sunulur;
              // eski sevgiliye sevgiliye özel eylem açılmaz.
              if (person.isAlive && person.relation == RelationType.sevgili) ...<Widget>[
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: () => _breakUp(person),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: theme.colorScheme.error,
                      side: BorderSide(
                        color: theme.colorScheme.error.withValues(alpha: 0.5),
                      ),
                    ),
                    child: const Text('Ayrıl'),
                  ),
                ),
              ],
              if (_notice != null) ...<Widget>[
                const SizedBox(height: 16),
                _Note(text: _notice!),
              ],
              if (_lastOutcome != null) ...<Widget>[
                const SizedBox(height: 16),
                _OutcomeCard(outcome: _lastOutcome!),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Evlilik kaydının okunur hâli.
String _marriageLabel(Marriage marriage) {
  switch (marriage.status) {
    case MarriageStatus.evli:
      return '${marriage.marriedAtAge} yaşında evlendiniz';
    case MarriageStatus.bosandi:
      return '${marriage.marriedAtAge} yaşında evlendiniz, '
          '${marriage.endedAtAge} yaşında boşandınız';
    case MarriageStatus.dul:
      return '${marriage.marriedAtAge} yaşında evlendiniz, '
          '${marriage.endedAtAge} yaşında kaybettin';
  }
}

class _Actions extends StatelessWidget {
  const _Actions({required this.available, required this.onSelected});

  /// Yalnızca **gerçekten yapılabilen** etkileşimler.
  ///
  /// Kişiye uygun olmayan tür hiç gösterilmez: okul arkadaşının kartında
  /// kilitli bir "Para İste" satırı çıkmaz.
  final List<InteractionKind> available;
  final void Function(InteractionKind kind) onSelected;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: <Widget>[
        for (final InteractionKind kind in available)
          FilledButton.tonal(
            onPressed: () => onSelected(kind),
            child: Text(kind.label),
          ),
      ],
    );
  }
}

/// Son etkileşimin sonucu: metin ve gerçekten uygulanan değişimler.
class _OutcomeCard extends StatelessWidget {
  const _OutcomeCard({required this.outcome});

  final InteractionOutcome outcome;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final Color accent =
        outcome.accepted ? theme.colorScheme.secondary : theme.colorScheme.primary;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: accent.withValues(alpha: 0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(outcome.text, style: theme.textTheme.bodyMedium),
          if (outcome.effects.isNotEmpty) ...<Widget>[
            const SizedBox(height: 12),
            EffectChips(effects: outcome.effects),
          ],
          if (outcome.accepted && outcome.noNewBenefit) ...<Widget>[
            const SizedBox(height: 10),
            Text(
              'Bu yaş için bu etkinlikten kazanacağın kalmadı. Başka kişiler '
              've başka etkinlikler açık.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _Note extends StatelessWidget {
  const _Note({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.6),
        ),
      ),
      child: Text(
        text,
        style: theme.textTheme.bodySmall?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          SizedBox(
            width: 150,
            child: Text(
              label,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

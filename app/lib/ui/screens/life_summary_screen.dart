import 'package:flutter/material.dart';

import '../../domain/generation/generation_continuation.dart';
import '../../domain/models/game_state.dart';
import '../../domain/models/life_log.dart';
import '../../domain/models/owned_item.dart';
import '../../domain/models/relation.dart';
import '../../domain/models/person.dart';
import '../../state/game_scope.dart';
import '../widgets/kilim_divider.dart';
import '../widgets/section_scaffold.dart';

/// Oyuncu vefat ettiğinde gösterilen hayat özeti.
///
/// Hayat tamamlanmış sayılır; yaş ilerlemez. Kayıt silinmez, özet
/// uygulama kapatılıp açılınca da görünür. Yeni hayat yalnızca oyuncu
/// açıkça isterse başlar.
class LifeSummaryScreen extends StatelessWidget {
  const LifeSummaryScreen({
    super.key,
    required this.onNewLife,
    required this.onShowArchive,
    this.onContinueAsChild,
  });

  final VoidCallback onNewLife;

  /// **Çocuğum olarak devam et** akışı (Paket E3).
  ///
  /// `null` ise ya da hayatta çocuk yoksa düğme **hiç gösterilmez**:
  /// çalışmayan sahte düğme olmaz (D-038).
  final VoidCallback? onContinueAsChild;

  /// Geçmiş Hayatlar arşivini açar.
  final VoidCallback onShowArchive;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final GameState state = GameScope.of(context).state!;

    // Eş kan bağı değildir ama hayatın ailesindedir; çocuklar zaten
    // kan bağıyla listeye girer.
    final List<Person> aile = state.people
        .where((Person p) =>
            p.relation.kanBagi || p.relation == RelationType.es)
        .toList(growable: false);
    final List<Person> devamCocuklari = GenerationContinuation.heirs(state);
    final bool devamVar =
        onContinueAsChild != null && devamCocuklari.isNotEmpty;
    final List<LifeLogEntry> donumNoktalari = state.log
        .where((LifeLogEntry e) => e.category != LogCategory.yasDegisimi)
        .toList(growable: false);
    final List<LifeLogEntry> sonDonumNoktalari = donumNoktalari.length > 8
        ? donumNoktalari.sublist(donumNoktalari.length - 8)
        : donumNoktalari;

    return SectionScaffold(
      title: 'Bir ömür tamamlandı',
      subtitle: state.player.fullName,
      children: <Widget>[
        Card(
          key: const Key('life_summary_card'),
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  '${state.player.fullName}, ${state.deathAge ?? state.player.age} '
                  'yaşında hayatını kaybetti.',
                  style: theme.textTheme.titleMedium,
                ),
                if (state.deathCause != null) ...<Widget>[
                  const SizedBox(height: 6),
                  Text(
                    'Sebep: ${state.deathCause}.',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
                const SizedBox(height: 14),
                const KilimDivider(),
                const SizedBox(height: 14),
                if (state.isContinuedGeneration)
                  _Satir(
                    label: 'Kuşak',
                    value: '${state.generation}. kuşak',
                  ),
                _Satir(label: 'Doğum şehri', value: state.player.birthCity),
                _Satir(label: 'Eğitim', value: state.education.label),
                if (state.education.program != null)
                  _Satir(
                    label: 'Bölüm',
                    value: state.education.program!.name,
                  ),
                _Satir(
                  label: 'Meslek',
                  value: state.career.isEmployed
                      ? state.career.label
                      : state.career.pastJobIds.isEmpty
                          ? 'Çalışmadı'
                          : 'Son iş: ${state.career.label}',
                ),
                _Satir(label: 'Cüzdan', value: state.player.walletLabel),
                _Satir(label: 'Eşya sayısı', value: '${state.items.length}'),
                if (state.licenses.isNotEmpty)
                  _Satir(
                    label: 'Ehliyetler',
                    value: '${state.licenses.length}',
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 14),
        if (aile.isNotEmpty) ...<Widget>[
          Text('Ailesi', style: theme.textTheme.titleMedium),
          const SizedBox(height: 8),
          for (final Person p in aile)
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Text(
                '${p.labelFor(state.deathAge ?? state.player.age)}: '
                '${p.fullName}${p.isAlive ? '' : ' (vefat etti)'}',
                style: theme.textTheme.bodyMedium,
              ),
            ),
          const SizedBox(height: 14),
        ],
        if (state.items.isNotEmpty) ...<Widget>[
          Text('Geride bıraktıkları', style: theme.textTheme.titleMedium),
          const SizedBox(height: 8),
          for (final OwnedItem item in state.items)
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Text(
                '${item.name} (${item.source.label})',
                style: theme.textTheme.bodyMedium,
              ),
            ),
          const SizedBox(height: 14),
        ],
        if (sonDonumNoktalari.isNotEmpty) ...<Widget>[
          Text('Hayatından satırlar', style: theme.textTheme.titleMedium),
          const SizedBox(height: 8),
          for (final LifeLogEntry e in sonDonumNoktalari)
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Text(
                '${e.age}: ${e.text}',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                  height: 1.4,
                ),
              ),
            ),
          const SizedBox(height: 14),
        ],
        if (devamVar) ...<Widget>[
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              key: const Key('life_summary_continue_generation'),
              onPressed: onContinueAsChild,
              icon: const Icon(Icons.child_care_outlined),
              label: Text(
                devamCocuklari.length == 1
                    ? '${devamCocuklari.single.firstName} olarak devam et'
                    : 'Çocuğum olarak devam et',
              ),
            ),
          ),
          const SizedBox(height: 10),
        ],
        SizedBox(
          width: double.infinity,
          // Kuşak devamı varken ana eylem odur; yeni hayat ikincil kalır.
          child: devamVar
              ? OutlinedButton(
                  key: const Key('life_summary_new_life'),
                  onPressed: onNewLife,
                  child: const Text('Yeni bir hayata başla'),
                )
              : FilledButton(
                  key: const Key('life_summary_new_life'),
                  onPressed: onNewLife,
                  child: const Text('Yeni bir hayata başla'),
                ),
        ),
        const SizedBox(height: 10),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton(
            key: const Key('life_summary_archive'),
            onPressed: onShowArchive,
            child: Text(
              state.pastLives.isEmpty
                  ? 'Geçmiş Hayatlar'
                  : 'Geçmiş Hayatlar (${state.pastLives.length})',
            ),
          ),
        ),
        const SizedBox(height: 10),
        const InfoPanel(
          icon: Icons.save_outlined,
          text: 'Bu hayatın özeti, yeni hayata başlasan bile Geçmiş '
              'Hayatlar arşivinde saklanır.',
        ),
      ],
    );
  }
}

class _Satir extends StatelessWidget {
  const _Satir({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          SizedBox(
            width: 130,
            child: Text(
              label,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          Expanded(
            child: Text(value, style: theme.textTheme.bodyMedium),
          ),
        ],
      ),
    );
  }
}

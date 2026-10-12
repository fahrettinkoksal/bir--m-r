import 'package:flutter/material.dart';

import '../../../data/chronic_catalog.dart';
import '../../../domain/life/chronic_engine.dart';
import '../../../domain/models/chronic_condition.dart';
import '../../../domain/models/game_state.dart';
import '../../../domain/models/health_history.dart';
import '../../../state/game_controller.dart';
import '../../../state/game_scope.dart';
import '../../../text/turkish_text.dart';
import '../../theme/bir_omur_theme.dart';
import '../../widgets/section_scaffold.dart';

/// Sağlık Geçmişi sayfası (D-153).
///
/// Sağlık tek bir sayıydı ve krizler birbirinden bağımsızdı; atlatılan
/// kriz hiçbir iz bırakmıyordu. Bu ekran **yalnızca gerçek kayıttan**
/// okur: taşınan kronik durumlar, kaç yıldır sürdükleri, kaç yıl takip
/// edildikleri ve geride kalan krizler.
///
/// **Tıbbi tavsiye vermez.** Durum söyler, tedavi anlatmaz.
class HealthHistoryPage extends StatelessWidget {
  const HealthHistoryPage({super.key, required this.onBack});

  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    final GameController controller = GameScope.of(context);
    final GameState state = controller.state!;
    final int yas = state.player.age;

    final List<ChronicCondition> suren = state.activeChronic;
    final List<ChronicCondition> gecmis = state.chronicConditions
        .where((ChronicCondition c) => !c.isActive)
        .toList(growable: false);
    // En yeni kriz üstte: geçmişe bakan önce son olanı arar.
    final List<HealthHistoryEntry> krizler =
        state.healthHistory.reversed.toList(growable: false);

    return SectionScaffold(
      icon: Icons.monitor_heart_rounded,
      accent: BirOmurAccents.nar,
      title: 'Sağlık Geçmişi',
      subtitle: suren.isEmpty
          ? 'Kayıt silinmez: atlattığın kriz de burada durur.'
          : 'Cüzdanında ${state.player.walletLabel} var.',
      backLabel: 'Sağlık Merkezi',
      onBack: onBack,
      children: <Widget>[
        if (suren.isEmpty && gecmis.isEmpty && krizler.isEmpty)
          const InfoPanel(
            key: Key('saglik_gecmisi_yok'),
            icon: Icons.favorite_outline_rounded,
            text: 'Sağlık geçmişin boş. Bu iyi bir haber.',
          ),
        if (suren.isNotEmpty) ...<Widget>[
          const MenuGroupTitle(
            text: 'Süren durumlar',
            accent: BirOmurAccents.nar,
          ),
          const SizedBox(height: 8),
          for (final ChronicCondition c in suren) ...<Widget>[
            _KronikKarti(condition: c, playerAge: yas),
            const SizedBox(height: 10),
          ],
        ],
        if (gecmis.isNotEmpty) ...<Widget>[
          const MenuGroupTitle(
            text: 'Geçmiş durumlar',
            accent: BirOmurAccents.mor,
          ),
          const SizedBox(height: 8),
          for (final ChronicCondition c in gecmis) ...<Widget>[
            _KronikKarti(condition: c, playerAge: yas),
            const SizedBox(height: 10),
          ],
        ],
        if (krizler.isNotEmpty) ...<Widget>[
          const MenuGroupTitle(
            text: 'Atlattığın krizler',
            accent: BirOmurAccents.yesil,
          ),
          const SizedBox(height: 8),
          for (final HealthHistoryEntry k in krizler) ...<Widget>[
            _KrizSatiri(entry: k),
            const SizedBox(height: 8),
          ],
        ],
      ],
    );
  }
}

class _KronikKarti extends StatelessWidget {
  const _KronikKarti({required this.condition, required this.playerAge});

  final ChronicCondition condition;
  final int playerAge;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final GameController controller = GameScope.of(context);
    final GameState state = controller.state!;
    final ChronicConditionType? tur = condition.type;

    final int yil = (condition.endedAtAge ?? playerAge) -
        condition.startedAtAge;
    final String engel = ChronicEngine.careBlockReason(state, condition);
    final bool acik = condition.isActive && engel.isEmpty;
    final bool buYilTakipli = condition.caredAt(playerAge);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(condition.label, style: theme.textTheme.titleMedium),
          const SizedBox(height: 4),
          Text(
            condition.endedAtAge == null
                ? '${condition.startedAtAge} yaşından beri · $yil yıl'
                : '${condition.startedAtAge}-${condition.endedAtAge} yaş',
            style: theme.textTheme.bodySmall,
          ),
          if (tur != null) ...<Widget>[
            const SizedBox(height: 8),
            Text(tur.description, style: theme.textTheme.bodyMedium),
          ],
          if (condition.careYears > 0) ...<Widget>[
            const SizedBox(height: 6),
            Text(
              '${condition.careYears} yıl takip edildi.',
              style: theme.textTheme.bodySmall,
            ),
          ],
          if (condition.isActive && tur != null) ...<Widget>[
            const SizedBox(height: 10),
            // Takibin bedeli **gerçekten** düşer; sahte bir düğme konmaz.
            FilledButton.tonal(
              key: Key('kronik_takip_${condition.typeId}'),
              onPressed: acik
                  ? () => controller.careForChronic(condition.typeId)
                  : null,
              child: Text(
                buYilTakipli
                    ? 'Bu yılın takibi yapıldı'
                    : 'Bu yılın takibi · ${trMoney(tur.yearlyCareCost)}',
              ),
            ),
            if (!acik && engel.isNotEmpty) ...<Widget>[
              const SizedBox(height: 6),
              Text(engel, style: theme.textTheme.bodySmall),
            ],
          ],
        ],
      ),
    );
  }
}

class _KrizSatiri extends StatelessWidget {
  const _KrizSatiri({required this.entry});

  final HealthHistoryEntry entry;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ChronicConditionType? kalan = entry.chronicTypeId == null
        ? null
        : chronicTypeById(entry.chronicTypeId!);
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            '${entry.age} yaşında · ${entry.label}',
            style: theme.textTheme.labelLarge,
          ),
          const SizedBox(height: 4),
          Text(entry.text, style: theme.textTheme.bodyMedium),
          if (kalan != null) ...<Widget>[
            const SizedBox(height: 4),
            Text(
              'Ardından kaldı: ${kalan.label}',
              style: theme.textTheme.bodySmall,
            ),
          ],
        ],
      ),
    );
  }
}

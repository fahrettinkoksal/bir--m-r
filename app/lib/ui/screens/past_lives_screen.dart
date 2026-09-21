import 'package:flutter/material.dart';

import '../../domain/models/life_summary.dart';
import '../../text/turkish_text.dart';
import '../widgets/comic.dart';
import '../widgets/section_scaffold.dart';

/// Geçmiş Hayatlar arşivi (D-037).
///
/// Tamamlanan her hayatın özeti burada birikir. Yeni hayat başlatmak bu
/// listeyi silmez.
class PastLivesScreen extends StatelessWidget {
  const PastLivesScreen({
    super.key,
    required this.lives,
    required this.onBack,
    this.backLabel = 'Hayat',
  });

  final List<LifeSummary> lives;
  final VoidCallback onBack;
  final String backLabel;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    // En yeni hayat başta görünür.
    final List<LifeSummary> sirali = lives.reversed.toList(growable: false);

    return SectionScaffold(
      icon: Icons.auto_stories_rounded,
      title: 'Geçmiş Hayatlar',
      subtitle: lives.isEmpty
          ? 'Henüz tamamlanmış bir hayat yok.'
          : '${lives.length} tamamlanmış hayat',
      backLabel: backLabel,
      onBack: onBack,
      children: <Widget>[
        if (sirali.isEmpty)
          const InfoPanel(
            icon: Icons.history_outlined,
            text: 'Bir hayat tamamlandığında özeti burada saklanır ve yeni '
                'hayat başlatmak bu kaydı silmez.',
          ),
        for (final LifeSummary hayat in sirali) ...<Widget>[
          Card(
            key: Key('past_life_${hayat.fullName}_${hayat.deathAge}'),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Row(
                    children: <Widget>[
                      Expanded(
                        child: Text(
                          hayat.fullName,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      // Kuşak rozeti yalnızca bilgisi olan kayıtlarda
                      // görünür; eski arşiv kayıtlarında hiç gösterilmez.
                      if ((hayat.generation ?? 1) > 1)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.secondaryContainer,
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            '${hayat.generation}. kuşak',
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: theme.colorScheme.onSecondaryContainer,
                            ),
                          ),
                        ),
                    ],
                  ),
                  // Değerlendirme adı yalnızca gerçekten kaydedildiyse
                  // gösterilir; eski arşiv satırları olduğu gibi kalır.
                  if (hayat.verdictTitle != null) ...<Widget>[
                    const SizedBox(height: 4),
                    HandwrittenText(
                      hayat.verdictTitle!,
                      size: 19,
                      tilt: -0.8,
                    ),
                  ],
                  const SizedBox(height: 4),
                  Text(
                    '${hayat.birthCity} · ${hayat.deathAge} yaşında '
                    'hayatını kaybetti (${hayat.deathCause})',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 10),
                  // Aile satırı yalnızca gerçekten varsa gösterilir.
                  if (hayat.familyLine != null)
                    Text(hayat.familyLine!,
                        style: theme.textTheme.bodySmall),
                  Text('Eğitim: ${hayat.educationLabel}',
                      style: theme.textTheme.bodySmall),
                  Text('Meslek: ${hayat.careerLabel}',
                      style: theme.textTheme.bodySmall),
                  Text(
                    'Cüzdan: ${trMoney(hayat.wallet)} · '
                    'Eşya: ${hayat.itemCount} · '
                    'Ehliyet: ${hayat.licenseCount}',
                    style: theme.textTheme.bodySmall,
                  ),
                  if (hayat.highlights.isNotEmpty) ...<Widget>[
                    const SizedBox(height: 10),
                    Text(
                      'Hayatından satırlar',
                      style: theme.textTheme.titleSmall,
                    ),
                    const SizedBox(height: 4),
                    for (final String satir in hayat.highlights)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Text(
                          satir,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                            height: 1.4,
                          ),
                        ),
                      ),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 10),
        ],
      ],
    );
  }
}

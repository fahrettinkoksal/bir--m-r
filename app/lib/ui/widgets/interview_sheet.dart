import 'package:flutter/material.dart';

import '../../data/interview_catalog.dart';
import '../../domain/career/job_market.dart';
import '../../domain/models/pending_interview.dart';
import '../../state/game_controller.dart';
import '../../state/game_scope.dart';
import 'kilim_divider.dart';

/// İş mülakatı penceresi.
///
/// Bir Ömür'ün mevcut tasarımını kullanır. Soru ve seçenekler oyun
/// durumundan okunur; kaydedilip geri yüklendiğinde aynı soru gelir.
class InterviewSheet extends StatefulWidget {
  const InterviewSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      isDismissible: false,
      enableDrag: false,
      builder: (BuildContext context) => const InterviewSheet(),
    );
  }

  @override
  State<InterviewSheet> createState() => _InterviewSheetState();
}

class _InterviewSheetState extends State<InterviewSheet> {
  JobOutcome? _sonuc;

  void _answer(int index) {
    final JobOutcome? outcome = GameScope.of(context).answerInterview(index);
    setState(() => _sonuc = outcome);
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final GameController controller = GameScope.of(context);
    final PendingInterview? mulakat = controller.pendingInterview;

    // Cevap verildikten sonra sonuç gösterilir.
    if (mulakat == null) {
      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                _sonuc?.accepted == true ? 'İşe alındın' : 'Görüşme bitti',
                style: theme.textTheme.headlineSmall,
              ),
              const SizedBox(height: 12),
              const KilimDivider(),
              const SizedBox(height: 14),
              Text(
                _sonuc?.text ?? 'Mülakat kapandı.',
                style: theme.textTheme.bodyMedium,
              ),
              if (_sonuc?.correctAnswer != null) ...<Widget>[
                const SizedBox(height: 16),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: theme.colorScheme.outlineVariant
                          .withValues(alpha: 0.7),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        'Doğru cevap: ${_sonuc!.correctAnswer}',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      if (_sonuc!.explanation != null) ...<Widget>[
                        const SizedBox(height: 6),
                        Text(
                          _sonuc!.explanation!,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                            height: 1.4,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 20),
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
      );
    }

    final InterviewQuestion? soru = mulakat.question;
    if (soru == null) return const SizedBox.shrink();

    return SafeArea(
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                '${mulakat.job?.name ?? 'İş'} mülakatı',
                style: theme.textTheme.headlineSmall,
              ),
              const SizedBox(height: 4),
              Text(
                'Karşındaki kişi bir soru soruyor.',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 14),
              const KilimDivider(),
              const SizedBox(height: 16),
              Text(soru.text, style: theme.textTheme.titleMedium),
              const SizedBox(height: 16),
              for (int i = 0; i < soru.options.length; i++) ...<Widget>[
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    key: Key('interview_option_$i'),
                    onPressed: () => _answer(i),
                    style: OutlinedButton.styleFrom(
                      alignment: Alignment.centerLeft,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                    ),
                    child: Text(soru.options[i]),
                  ),
                ),
                const SizedBox(height: 10),
              ],
              const SizedBox(height: 6),
              TextButton(
                onPressed: () {
                  GameScope.of(context).cancelInterview();
                  Navigator.of(context).pop();
                },
                child: const Text('Görüşmeden vazgeç'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

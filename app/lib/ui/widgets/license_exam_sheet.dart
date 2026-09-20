import 'package:flutter/material.dart';

import '../../data/license_questions.dart';
import '../../domain/licensing/license_office.dart';
import '../../domain/models/pending_license_exam.dart';
import '../../state/game_controller.dart';
import '../../state/game_scope.dart';
import 'kilim_divider.dart';

/// Ehliyet sınavı penceresi.
///
/// İş mülakatıyla aynı tasarım dilini kullanır. Soru ve seçenekler oyun
/// durumundan okunur; kayıt geri yüklendiğinde aynı soru gelir.
class LicenseExamSheet extends StatefulWidget {
  const LicenseExamSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      isDismissible: false,
      enableDrag: false,
      builder: (BuildContext context) => const LicenseExamSheet(),
    );
  }

  @override
  State<LicenseExamSheet> createState() => _LicenseExamSheetState();
}

class _LicenseExamSheetState extends State<LicenseExamSheet> {
  LicenseOutcome? _sonuc;

  void _answer(int index) {
    final LicenseOutcome? outcome =
        GameScope.of(context).answerLicenseExam(index);
    setState(() => _sonuc = outcome);
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final GameController controller = GameScope.of(context);
    final PendingLicenseExam? sinav = controller.pendingLicenseExam;

    if (sinav == null) {
      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                _sonuc?.granted == true ? 'Ehliyetin hazır' : 'Sınav bitti',
                key: const Key('license_result_title'),
                style: theme.textTheme.headlineSmall,
              ),
              const SizedBox(height: 12),
              const KilimDivider(),
              const SizedBox(height: 14),
              Text(
                _sonuc?.text ?? 'Sınav kapandı.',
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

    final LicenseQuestion? soru = sinav.question;
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
                '${sinav.license?.label ?? 'Ehliyet'} sınavı',
                style: theme.textTheme.headlineSmall,
              ),
              const SizedBox(height: 4),
              Text(
                'Sınav görevlisi bir soru soruyor.',
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
                    key: Key('license_option_$i'),
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
                  GameScope.of(context).cancelLicenseExam();
                  Navigator.of(context).pop();
                },
                child: const Text('Sınavdan vazgeç'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

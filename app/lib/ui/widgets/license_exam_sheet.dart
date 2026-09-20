import 'package:flutter/material.dart';

import '../../data/license_questions.dart';
import '../../domain/licensing/license_office.dart';
import '../../domain/models/pending_license_exam.dart';
import '../../state/game_controller.dart';
import '../../state/game_scope.dart';
import 'kilim_divider.dart';

/// Ehliyet sınavı penceresi.
///
/// Sınav **3 kısa sorudan** oluşur ve **en az 2 doğru** cevapla geçilir
/// (D-035). Sorular oyun durumundan okunur: uygulama sınavın ortasında
/// kapatılıp açılsa bile aynı sorulardan devam edilir. Sonuçta bütün
/// soruların doğru cevabı ve kısa açıklaması gösterilir.
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
    setState(() {
      // Sınav sürerken sonuç paneli gösterilmez; yalnızca bittiğinde.
      _sonuc = outcome != null && outcome.review.isNotEmpty ? outcome : null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final GameController controller = GameScope.of(context);
    final PendingLicenseExam? sinav = controller.pendingLicenseExam;

    if (sinav == null) return _sonucPaneli(context, theme);

    final LicenseQuestion? soru = sinav.currentQuestion;
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
                '${sinav.currentIndex}. soru / ${sinav.questionCount} · '
                'Geçmek için en az '
                '${LicenseOffice.passingCorrectAnswers} doğru gerekiyor.',
                key: const Key('license_progress'),
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

  /// Sınav bitince: sonuç, doğru cevaplar ve açıklamalar.
  Widget _sonucPaneli(BuildContext context, ThemeData theme) {
    final LicenseOutcome? sonuc = _sonuc;
    return SafeArea(
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                sonuc?.granted == true ? 'Ehliyetin hazır' : 'Sınav bitti',
                key: const Key('license_result_title'),
                style: theme.textTheme.headlineSmall,
              ),
              const SizedBox(height: 12),
              const KilimDivider(),
              const SizedBox(height: 14),
              Text(
                sonuc?.text ?? 'Sınav kapandı.',
                style: theme.textTheme.bodyMedium,
              ),
              if (sonuc != null && sonuc.review.isNotEmpty) ...<Widget>[
                const SizedBox(height: 16),
                for (final ExamAnswerReview inceleme in sonuc.review) ...<Widget>[
                  Container(
                    width: double.infinity,
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: inceleme.isCorrect
                            ? theme.colorScheme.primary.withValues(alpha: 0.5)
                            : theme.colorScheme.error.withValues(alpha: 0.4),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Row(
                          children: <Widget>[
                            Icon(
                              inceleme.isCorrect
                                  ? Icons.check_circle_outline
                                  : Icons.cancel_outlined,
                              size: 18,
                              color: inceleme.isCorrect
                                  ? theme.colorScheme.primary
                                  : theme.colorScheme.error,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                inceleme.question.text,
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Senin cevabın: ${inceleme.givenOption}',
                          style: theme.textTheme.bodySmall,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Doğru cevap: ${inceleme.correctOption}',
                          style: theme.textTheme.bodySmall?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          inceleme.question.explanation,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
              const SizedBox(height: 10),
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
}

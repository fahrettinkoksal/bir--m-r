import 'dart:math';

import 'package:flutter/material.dart';

import '../../../data/activity_catalog.dart';
import '../../../domain/activities/activity_engine.dart';
import '../../../domain/life/eye_exam.dart';
import '../../../state/game_scope.dart';
import '../../../state/game_controller.dart';
import '../../widgets/section_scaffold.dart';
import 'activity_pages.dart';

/// Göz muayenesi mini oyunu (D-076).
///
/// Faho'nun isteği: "göz muayenesine tıkladım, direkt altta ufak bir
/// bildirim yerine küçük bir oyun oynatmalıyız, yan yana 5'lerin
/// arasında S'yi bulmak gibi".
///
/// Tablo yukarıdan aşağıya küçülür. Her satırda birbirine benzeyen
/// karakterlerden **farklı olanı** bulmak gerekir. Yanlış seçim satırı
/// kaybettirir; tablo baştan kurulmaz, muayene devam eder.
///
/// **Bu bir görme testi değildir** ve ekranda da böyle anlatılmaz:
/// sonuç ekranında oyuncunun kaç satır okuduğu ile hekimin karakterin
/// gözü hakkında söyledikleri **ayrı ayrı** yazar.
class EyeExamPage extends StatefulWidget {
  const EyeExamPage({super.key, required this.action, required this.onBack});

  final ActivityAction action;
  final VoidCallback onBack;

  @override
  State<EyeExamPage> createState() => _EyeExamPageState();
}

class _EyeExamPageState extends State<EyeExamPage> {
  late final EyeExamPuzzle _tablo = EyeExam.generate(Random());

  /// Cevaplanan satır sayısı.
  int _satir = 0;

  /// Doğru bulunan satır sayısı.
  int _dogru = 0;

  ActivityOutcome? _sonuc;

  void _sec(int satirNo, int index) {
    if (_satir != satirNo || _sonuc != null) return;
    final bool dogru = _tablo.rows[satirNo].oddIndex == index;
    setState(() {
      if (dogru) _dogru++;
      _satir++;
    });
    if (_satir >= _tablo.length) _bitir();
  }

  void _bitir() {
    final GameController controller = GameScope.of(context);
    final ActivityOutcome? sonuc = controller.finishEyeExam(
      widget.action,
      correct: _dogru,
      total: _tablo.length,
    );
    setState(() => _sonuc = sonuc);
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final bool bitti = _sonuc != null;

    return SectionScaffold(
      icon: Icons.remove_red_eye_outlined,
      accent: accentForVenue(ActivityVenue.saglikMerkezi),
      title: widget.action.label,
      subtitle: bitti
          ? 'Muayene bitti.'
          : 'Her satırda diğerlerinden farklı olanı bul. '
              '${_satir + 1}. satır.',
      backLabel: 'Sağlık Merkezi',
      onBack: widget.onBack,
      children: <Widget>[
        for (int i = 0; i < _tablo.length; i++) ...<Widget>[
          Opacity(
            // Sırası gelmemiş satırlar soluk durur; oyuncu nereye
            // bakacağını bilsin.
            opacity: i == _satir ? 1.0 : 0.28,
            child: _SatirWidget(
              key: Key('eye_row_$i'),
              row: _tablo.rows[i],
              enabled: i == _satir && !bitti,
              onTap: (int index) => _sec(i, index),
            ),
          ),
          const SizedBox(height: 14),
        ],
        const SizedBox(height: 8),
        if (!bitti)
          Text(
            'Okuyamadığın satırda da bir seçim yapman gerekiyor; '
            'muayene öyle ilerliyor.',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        if (bitti) ...<Widget>[
          OutcomeCard(outcome: _sonuc!),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: FilledButton.tonal(
              key: const Key('eye_exam_done'),
              onPressed: widget.onBack,
              child: const Text('Sağlık Merkezi\'ne dön'),
            ),
          ),
        ],
      ],
    );
  }
}

class _SatirWidget extends StatelessWidget {
  const _SatirWidget({
    super.key,
    required this.row,
    required this.enabled,
    required this.onTap,
  });

  final EyeExamRow row;
  final bool enabled;
  final void Function(int) onTap;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Center(
      child: Wrap(
        alignment: WrapAlignment.center,
        spacing: 2,
        runSpacing: 2,
        children: <Widget>[
          for (int i = 0; i < row.characters.length; i++)
            InkWell(
              key: Key('eye_char_${row.fontSize.round()}_$i'),
              onTap: enabled ? () => onTap(i) : null,
              borderRadius: BorderRadius.circular(6),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                child: Text(
                  row.characters[i],
                  style: TextStyle(
                    fontSize: row.fontSize,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 1,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

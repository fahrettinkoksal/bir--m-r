import 'package:flutter/material.dart';

import '../../data/save/save_service.dart';
import '../../domain/generation/life_generator.dart';
import '../../state/game_controller.dart';
import '../../state/game_scope.dart';
import '../widgets/kilim_divider.dart';
import 'creation_screen.dart';

/// Açılış ekranı: kayıtlı hayata devam etme ve iki başlangıç modu (D-005).
class StartScreen extends StatefulWidget {
  const StartScreen({super.key});

  @override
  State<StartScreen> createState() => _StartScreenState();
}

class _StartScreenState extends State<StartScreen> {
  bool _busy = false;

  Future<void> _continue() async {
    final GameController controller = GameScope.of(context);
    setState(() => _busy = true);
    final SaveLoadStatus status = await controller.restoreSavedLife();
    if (!mounted) return;
    setState(() => _busy = false);
    if (status != SaveLoadStatus.yuklendi) {
      // Sebep ekranda ayrıca gösteriliyor; kayıt dosyasına dokunulmadı.
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            controller.saveProblem ?? 'Kayıtlı hayat açılamadı.',
          ),
        ),
      );
    }
  }

  /// Yeni hayat mevcut kaydın üzerine yazılacaksa önce açık onay alır.
  Future<bool> _confirmOverwrite() async {
    final GameController controller = GameScope.of(context);
    if (!controller.hasSavedLife) return true;

    final bool? onay = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        title: const Text('Kayıtlı hayatın silinsin mi?'),
        content: const Text(
          'Cihazda devam edebileceğin bir hayat var. Yeni bir hayata '
          'başlarsan o kayıt silinir ve geri alınamaz.',
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Vazgeç'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Sil ve yeni hayat başlat'),
          ),
        ],
      ),
    );
    if (onay != true) return false;

    await controller.deleteSavedLife();
    return true;
  }

  Future<void> _randomLife() async {
    if (!await _confirmOverwrite() || !mounted) return;
    GameScope.of(context).startNewLife(mode: StartMode.tamamenRastgele);
  }

  Future<void> _customLife() async {
    if (!await _confirmOverwrite() || !mounted) return;
    await Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => const CreationScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final GameController controller = GameScope.of(context);
    final String? sorun = controller.saveProblem;
    final bool devamEdilebilir = controller.hasSavedLife && sorun == null;

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              const Spacer(flex: 2),
              Text(
                'Bir Ömür',
                textAlign: TextAlign.center,
                style: theme.textTheme.displaySmall?.copyWith(
                  fontWeight: FontWeight.w800,
                  letterSpacing: -1,
                  color: theme.colorScheme.primary,
                ),
              ),
              const SizedBox(height: 10),
              const KilimDivider(height: 12),
              const SizedBox(height: 10),
              Text(
                'Bir hayat başlıyor. Nerede doğacağın, kimlerle büyüyeceğin '
                've neyle uğraşacağın önceden belli değil.',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const Spacer(),
              // Açılışta ortada büyük bir boşluk kalıyordu; oyunun ne
              // olduğunu üç satırda anlatan küçük bir kart konuldu.
              const _NasilOynanir(),
              const Spacer(flex: 2),
              if (!controller.savingEnabled) ...<Widget>[
                const _SaveProblemNote(
                  text: 'Bu cihazda kayıt klasörü açılamadı, oyun '
                      'kaydedilemiyor.',
                  showUntouchedNote: false,
                ),
                const SizedBox(height: 16),
              ] else if (sorun != null) ...<Widget>[
                _SaveProblemNote(text: sorun),
                const SizedBox(height: 16),
              ],
              if (devamEdilebilir) ...<Widget>[
                FilledButton(
                  key: const Key('continue_button'),
                  onPressed: _busy ? null : _continue,
                  child: const Text('Devam Et'),
                ),
                const SizedBox(height: 12),
                OutlinedButton(
                  onPressed: _busy ? null : _randomLife,
                  child: const Text('Yeni hayat (rastgele)'),
                ),
              ] else
                FilledButton(
                  onPressed: _busy ? null : _randomLife,
                  child: const Text('Rastgele bir hayat'),
                ),
              const SizedBox(height: 12),
              OutlinedButton(
                onPressed: _busy ? null : _customLife,
                child: const Text('İsmimi ve cinsiyetimi seçeyim'),
              ),
              const SizedBox(height: 16),
              Text(
                devamEdilebilir
                    ? 'Kaldığın yerden devam edebilirsin. Yeni bir hayat '
                        'başlatmak kayıtlı hayatını siler.'
                    : 'Her iki modda da doğum şehri, aile ve diğer başlangıç '
                        'koşulları rastgele belirlenir.',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const Spacer(),
            ],
          ),
        ),
      ),
    );
  }
}

/// Açılışta oyunu üç satırda anlatan kart.
class _NasilOynanir extends StatelessWidget {
  const _NasilOynanir();

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    const List<(IconData, String)> satirlar = <(IconData, String)>[
      (Icons.cake_outlined, 'Her yaş bir karar getirir.'),
      (Icons.diversity_3_outlined,
          'Kararların ilişkilerini ve geleceğini değiştirir.'),
      (Icons.menu_book_outlined,
          'Hiçbir kayıt silinmez; hayatın arşivde kalır.'),
    ];

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(
          alpha: 0.65,
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.6),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          for (int i = 0; i < satirlar.length; i++) ...<Widget>[
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Icon(
                  satirlar[i].$1,
                  size: 18,
                  color: theme.colorScheme.secondary,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    satirlar[i].$2,
                    style: theme.textTheme.bodyMedium,
                  ),
                ),
              ],
            ),
            if (i != satirlar.length - 1) const SizedBox(height: 10),
          ],
        ],
      ),
    );
  }
}

/// Okunamayan kayıt için bilgi kutusu.
///
/// Kayıt dosyasına dokunulmadığı açıkça yazılır; oyuncu isterse yeni hayat
/// başlatarak üzerine yazmayı kendisi onaylar.
class _SaveProblemNote extends StatelessWidget {
  const _SaveProblemNote({required this.text, this.showUntouchedNote = true});

  final String text;

  /// Kayıt dosyasına dokunulmadığı notu gösterilsin mi?
  final bool showUntouchedNote;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.errorContainer.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.colorScheme.error.withValues(alpha: 0.4),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Icon(Icons.warning_amber_outlined,
              size: 20, color: theme.colorScheme.error),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              showUntouchedNote
                  ? '$text\n\nKayıt dosyasına dokunulmadı. Yeni bir hayat '
                      'başlatırsan bu kayıt silinir.'
                  : text,
              style: theme.textTheme.bodySmall?.copyWith(height: 1.4),
            ),
          ),
        ],
      ),
    );
  }
}

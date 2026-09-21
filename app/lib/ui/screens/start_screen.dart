import 'package:flutter/material.dart';

import '../../data/save/save_service.dart';
import '../../domain/generation/life_generator.dart';
import '../../state/game_controller.dart';
import '../../state/game_scope.dart';
import '../theme/bir_omur_theme.dart';
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
      // Açılış ekranı oyunun kapağıdır: tüm ekranı kaplayan koyu degrade,
      // beyaz yazı ve açık renkli düğmeler (Paket 16).
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: <Color>[
              BirOmurColors.basligUst,
              BirOmurColors.basligAlt,
            ],
          ),
        ),
        child: SafeArea(
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
                    fontWeight: FontWeight.w900,
                    letterSpacing: -1.5,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 12),
                const KilimDivider(height: 12, onDark: true),
                const SizedBox(height: 12),
                Text(
                  'Bir hayat başlıyor. Nerede doğacağın, kimlerle '
                  'büyüyeceğin ve neyle uğraşacağın önceden belli değil.',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: Colors.white.withValues(alpha: 0.85),
                    height: 1.45,
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
                  _StartButton(
                    itemKey: const Key('continue_button'),
                    label: 'Devam Et',
                    primary: true,
                    onPressed: _busy ? null : _continue,
                  ),
                  const SizedBox(height: 12),
                  _StartButton(
                    label: 'Yeni hayat (rastgele)',
                    onPressed: _busy ? null : _randomLife,
                  ),
                ] else
                  _StartButton(
                    label: 'Rastgele bir hayat',
                    primary: true,
                    onPressed: _busy ? null : _randomLife,
                  ),
                const SizedBox(height: 12),
                _StartButton(
                  label: 'İsmimi ve cinsiyetimi seçeyim',
                  onPressed: _busy ? null : _customLife,
                ),
                const SizedBox(height: 16),
                Text(
                  devamEdilebilir
                      ? 'Kaldığın yerden devam edebilirsin. Yeni bir hayat '
                          'başlatmak kayıtlı hayatını siler.'
                      : 'Her iki modda da doğum şehri, aile ve diğer '
                          'başlangıç koşulları rastgele belirlenir.',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: Colors.white.withValues(alpha: 0.6),
                  ),
                ),
                const Spacer(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Açılış ekranının düğmesi.
///
/// Zemin koyu degrade olduğu için tema düğmeleri okunmuyordu: ana eylem
/// dolu beyaz, ikincil eylem ince beyaz çerçevelidir.
class _StartButton extends StatelessWidget {
  const _StartButton({
    required this.label,
    required this.onPressed,
    this.primary = false,
    this.itemKey,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool primary;
  final Key? itemKey;

  @override
  Widget build(BuildContext context) {
    final bool aktif = onPressed != null;
    return Material(
      key: itemKey,
      color: primary
          ? Colors.white.withValues(alpha: aktif ? 1 : 0.5)
          : Colors.white.withValues(alpha: 0.12),
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: primary
                ? null
                : Border.all(
                    color: Colors.white.withValues(alpha: 0.45),
                    width: 1.4,
                  ),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 17),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: primary ? BirOmurColors.basligUst : Colors.white,
            ),
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
        color: Colors.white.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
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
                  color: BirOmurColors.pirincAcik,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    satirlar[i].$2,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: Colors.white.withValues(alpha: 0.92),
                    ),
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
        color: Colors.black.withValues(alpha: 0.26),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: BirOmurColors.geceUyari.withValues(alpha: 0.55),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const Icon(Icons.warning_amber_rounded,
              size: 20, color: BirOmurColors.geceUyari),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              showUntouchedNote
                  ? '$text\n\nKayıt dosyasına dokunulmadı. Yeni bir hayat '
                      'başlatırsan bu kayıt silinir.'
                  : text,
              style: theme.textTheme.bodySmall?.copyWith(
                height: 1.4,
                color: Colors.white.withValues(alpha: 0.92),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

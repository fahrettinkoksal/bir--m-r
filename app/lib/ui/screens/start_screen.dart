import 'package:flutter/material.dart';

import '../../data/save/save_service.dart';
import '../../domain/generation/life_generator.dart';
import '../../state/game_controller.dart';
import '../../state/game_scope.dart';
import '../theme/bir_omur_theme.dart';
import '../widgets/comic.dart';
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
      // Açılış ekranı oyunun kapağıdır: çizim kâğıdı, el yazısıyla
      // yazılmış bir ad ve basınca çöken kocaman çıkartma düğmeler
      // (Paket 19).
      body: PaperBackground(
        child: SafeArea(
          // Yazı tipi büyük ve düğmeler kalın; küçük ekranlarda içerik
          // sığmıyordu. Ekran kaydırılabilir.
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(22, 6, 22, 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                const SizedBox(height: 4),
                const _Logo(),
                const SizedBox(height: 10),
                Text(
                  'Bir hayat başlıyor. Nerede doğacağın, kimlerle '
                  'büyüyeceğin ve neyle uğraşacağın önceden belli değil.',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 14),
                const _NasilOynanir(),
                const SizedBox(height: 14),
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
                  StickerButton(
                    key: const Key('continue_button'),
                    expand: true,
                    color: BirOmurColors.yesil,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    onPressed: _busy ? null : _continue,
                    child: const Text(
                      'Devam Et',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: BirOmurColors.krem,
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  StickerButton(
                    expand: true,
                    color: theme.colorScheme.surfaceContainerHighest,
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    onPressed: _busy ? null : _randomLife,
                    child: Text(
                      'Yeni hayat (rastgele)',
                      style: theme.textTheme.titleMedium,
                    ),
                  ),
                ] else
                  StickerButton(
                    expand: true,
                    color: BirOmurColors.kirmizi,
                    padding: const EdgeInsets.symmetric(vertical: 13),
                    onPressed: _busy ? null : _randomLife,
                    child: const Text(
                      'Rastgele bir hayat',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: BirOmurColors.krem,
                      ),
                    ),
                  ),
                const SizedBox(height: 10),
                StickerButton(
                  expand: true,
                  color: BirOmurColors.sari,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  onPressed: _busy ? null : _customLife,
                  child: const Text(
                    'İsmimi ve cinsiyetimi seçeyim',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: BirOmurColors.murekkep,
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  devamEdilebilir
                      ? 'Kaldığın yerden devam edebilirsin. Yeni bir hayat '
                          'başlatmak kayıtlı hayatını siler.'
                      : 'Her iki modda da doğum şehri, aile ve diğer '
                          'başlangıç koşulları rastgele belirlenir.',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Oyunun adı: eğik duran, konturlu bir tabela.
class _Logo extends StatelessWidget {
  const _Logo();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ComicCard(
        color: BirOmurColors.kirmizi,
        tilt: -2.5,
        radius: Comic.yaricapBuyuk,
        shadowOffset: 6,
        padding: const EdgeInsets.fromLTRB(22, 7, 22, 9),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            const HandwrittenText(
              'Bir Ömür',
              size: 38,
              color: BirOmurColors.krem,
            ),
            const SizedBox(height: 2),
            Text(
              'bir hayat simülasyonu',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    letterSpacing: 1.6,
                    color: BirOmurColors.krem.withValues(alpha: 0.85),
                  ),
            ),
          ],
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

    return ComicCard(
      tilt: 0.8,
      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 11),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          for (int i = 0; i < satirlar.length; i++) ...<Widget>[
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                ComicIconTile(
                  icon: satirlar[i].$1,
                  accent: <BirOmurAccent>[
                    BirOmurAccents.nar,
                    BirOmurAccents.cini,
                    BirOmurAccents.pirinc,
                  ][i],
                  size: 26,
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
            if (i != satirlar.length - 1) const SizedBox(height: 7),
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
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: BirOmurColors.kirmizi.withValues(alpha: 0.22),
        borderRadius: BorderRadius.circular(Comic.yaricap),
        border: Border.all(
          color: Comic.konturOf(context),
          width: Comic.inceKontur,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const Icon(Icons.warning_amber_rounded,
              size: 20, color: BirOmurColors.kirmiziKoyu),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              showUntouchedNote
                  ? '$text\n\nKayıt dosyasına dokunulmadı. Yeni bir hayat '
                      'başlatırsan bu kayıt silinir.'
                  : text,
              style: theme.textTheme.bodySmall,
            ),
          ),
        ],
      ),
    );
  }
}

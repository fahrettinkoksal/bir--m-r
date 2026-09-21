import 'package:flutter/material.dart';

import 'state/game_controller.dart';
import 'state/game_scope.dart';
import 'ui/screens/home_shell.dart';
import 'ui/screens/start_screen.dart';
import 'ui/sound/sound_scope.dart';
import 'ui/sound/sound_service.dart';
import 'ui/theme/bir_omur_theme.dart';

/// Uygulamanın kökü.
class BirOmurApp extends StatefulWidget {
  const BirOmurApp({
    super.key,
    this.controller,
    this.themeMode = ThemeMode.system,
    this.sound,
  });

  /// Testlerde sabit tohumlu bir denetleyici verilebilir.
  final GameController? controller;

  /// Açık/koyu tema seçimi. Varsayılan olarak **cihazın** ayarı kullanılır;
  /// testlerde koyu tema doğrudan verilebilir.
  final ThemeMode themeMode;

  /// Ses servisi; testlerde sessiz bir servis verilebilir.
  final SoundService? sound;

  @override
  State<BirOmurApp> createState() => _BirOmurAppState();
}

class _BirOmurAppState extends State<BirOmurApp> {
  late final GameController _controller = widget.controller ?? GameController();
  late final bool _ownsController = widget.controller == null;

  /// Ses efektleri servisi. Ayar kapalıyken hiçbir ses çalınmaz.
  late final SoundService _sound = widget.sound ?? SoundService();

  @override
  void initState() {
    super.initState();
    _controller.addListener(_ayarlariUygula);
    _ayarlariUygula();
  }

  /// Kayıttaki ses ayarını servise yansıtır.
  void _ayarlariUygula() {
    _sound.enabled = _controller.state?.settings.soundEnabled ?? true;
  }

  @override
  void dispose() {
    _controller.removeListener(_ayarlariUygula);
    if (_ownsController) _controller.dispose();
    _sound.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GameScope(
      controller: _controller,
      child: SoundScope(
        service: _sound,
        child: MaterialApp(
          title: 'Bir Ömür',
          debugShowCheckedModeBanner: false,
          theme: BirOmurTheme.light(),
          darkTheme: BirOmurTheme.dark(),
          themeMode: widget.themeMode,
          home: const _Root(),
        ),
      ),
    );
  }
}

class _Root extends StatelessWidget {
  const _Root();

  @override
  Widget build(BuildContext context) {
    final GameController controller = GameScope.of(context);
    return controller.hasLife ? const HomeShell() : const StartScreen();
  }
}

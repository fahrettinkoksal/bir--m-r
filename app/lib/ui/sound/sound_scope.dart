import 'package:flutter/widgets.dart';

import 'sound_service.dart';

/// Ses servisini arayüze taşıyan kapsam (Paket 15).
///
/// Testlerde ve ses servisinin olmadığı ortamlarda [maybeOf] `null`
/// döner; çağıran taraf sessizce devam eder.
class SoundScope extends InheritedWidget {
  const SoundScope({
    super.key,
    required this.service,
    required super.child,
  });

  final SoundService service;

  static SoundService? maybeOf(BuildContext context) => context
      .dependOnInheritedWidgetOfExactType<SoundScope>()
      ?.service;

  /// Kısa yol: kapsam yoksa hiçbir şey yapmaz.
  static void play(BuildContext context, GameSound sound) {
    maybeOf(context)?.play(sound);
  }

  @override
  bool updateShouldNotify(SoundScope oldWidget) =>
      oldWidget.service != service;
}

import 'package:flutter/widgets.dart';

import 'game_controller.dart';

/// [GameController]'ı widget ağacına taşır ve değişimlerde dinleyicileri
/// yeniden çizer. Harici bağımlılık kullanmamak için InheritedNotifier yeterli.
class GameScope extends InheritedNotifier<GameController> {
  const GameScope({
    super.key,
    required GameController controller,
    required super.child,
  }) : super(notifier: controller);

  static GameController of(BuildContext context) {
    final GameScope? scope =
        context.dependOnInheritedWidgetOfExactType<GameScope>();
    assert(scope != null, 'GameScope widget ağacında bulunamadı.');
    return scope!.notifier!;
  }
}

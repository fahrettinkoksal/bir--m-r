import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app.dart';
import 'data/save/save_location.dart';
import 'data/save/save_service.dart';
import 'data/save/save_store.dart';
import 'state/game_controller.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Prototip dikey kullanım için tasarlandı (`docs/PROTOTYPE_UI.md` §2).
  SystemChrome.setPreferredOrientations(<DeviceOrientation>[
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Kayıt dosyası cihazın uygulamaya ait yerel veri klasöründe tutulur.
  // Klasör açılamazsa oyun yine başlar; yalnızca kayıt devre dışı kalır ve
  // bu durum başlangıç ekranında bildirilir.
  SaveService? saveService;
  try {
    final SaveStore store = await openDeviceSaveStore();
    saveService = SaveService(store);
  } catch (_) {
    saveService = null;
  }

  final GameController controller = GameController(saveService: saveService);
  await controller.checkForSavedLife();

  runApp(BirOmurApp(controller: controller));
}

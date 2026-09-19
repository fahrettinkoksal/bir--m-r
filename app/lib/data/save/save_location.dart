/// Kayıt dosyasının cihazdaki yeri.
library;

import 'dart:io';

import 'package:path_provider/path_provider.dart';

import 'save_store.dart';

/// Uygulamaya ait yerel veri klasöründe bir kayıt deposu açar.
///
/// `getApplicationSupportDirectory()` her platformda **uygulamaya özel**,
/// kullanıcının belgelerine karışmayan bir klasör verir:
/// - Windows'ta `%APPDATA%\<uygulama>\`
/// - Android'de uygulamanın kendi veri klasörü
///
/// Böylece aynı kayıt altyapısı ileride Android sürümünde de değişiklik
/// gerektirmeden çalışır.
Future<SaveStore> openDeviceSaveStore() async {
  final Directory dir = await getApplicationSupportDirectory();
  return FileSaveStore(dir);
}

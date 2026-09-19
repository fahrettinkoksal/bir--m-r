/// Kayıt metninin cihazda saklanması.
///
/// Depolama, kayıt biçiminden ayrı tutulur: testler bellek üstü bir depo
/// kullanır, uygulama ise cihazın yerel veri klasöründeki dosyayı kullanır.
library;

import 'dart:async';
import 'dart:io';

/// Kayıt metnini okuyup yazan basit depo.
abstract class SaveStore {
  /// Geçerli kayıt metni; kayıt yoksa `null`.
  Future<String?> read();

  /// En son sağlam kaydın yedeği; yoksa `null`.
  Future<String?> readBackup();

  /// Kaydı yazar. Yazma yarıda kesilse bile eski kayıt kaybolmamalıdır.
  Future<void> write(String contents);

  /// Kayıt var mı?
  Future<bool> exists();

  /// Kaydı **açıkça** siler. Yalnızca kullanıcı onayıyla çağrılır.
  Future<void> delete();
}

/// Testler ve hata durumları için bellek üstü depo.
class MemorySaveStore implements SaveStore {
  MemorySaveStore({String? initial, String? initialBackup})
      : _contents = initial,
        _backup = initialBackup;

  String? _contents;
  String? _backup;

  /// Kaç kez yazıldığı; otomatik kayıt testlerinde kullanılır.
  int writeCount = 0;

  @override
  Future<String?> read() async => _contents;

  @override
  Future<String?> readBackup() async => _backup;

  @override
  Future<void> write(String contents) async {
    // Dosya deposundaki davranışın aynısı: yeni kayıt yazılmadan önce
    // eski sağlam kayıt yedeğe alınır.
    if (_contents != null) _backup = _contents;
    _contents = contents;
    writeCount++;
  }

  @override
  Future<bool> exists() async => _contents != null;

  @override
  Future<void> delete() async {
    _contents = null;
    _backup = null;
  }
}

/// Cihazdaki dosyaya yazan depo.
///
/// Yazma üç adımlıdır ve **yarıda kesilmeye karşı dayanıklıdır**:
/// 1. Yeni içerik geçici bir dosyaya (`.tmp`) yazılır ve diske boşaltılır.
/// 2. Var olan sağlam kayıt `.bak` dosyasına kopyalanır.
/// 3. Geçici dosya asıl kaydın üzerine **tek adımda** taşınır.
///
/// Böylece herhangi bir adımda kesinti olsa bile ya eski kayıt ya da yeni
/// kayıt bütün hâlde kalır; yarım yazılmış dosya asıl kaydın yerine geçmez.
class FileSaveStore implements SaveStore {
  FileSaveStore(this.directory, {this.fileName = 'bir_omur_kayit.json'});

  final Directory directory;
  final String fileName;

  File get _file => File('${directory.path}${Platform.pathSeparator}$fileName');
  File get _tempFile => File('${_file.path}.tmp');
  File get _backupFile => File('${_file.path}.bak');

  @override
  Future<String?> read() async {
    if (!await _file.exists()) return null;
    return _file.readAsString();
  }

  @override
  Future<String?> readBackup() async {
    if (!await _backupFile.exists()) return null;
    return _backupFile.readAsString();
  }

  @override
  Future<void> write(String contents) async {
    await directory.create(recursive: true);

    // 1) Önce geçici dosyaya yaz ve diske indir.
    final RandomAccessFile handle =
        await _tempFile.open(mode: FileMode.writeOnly);
    try {
      await handle.truncate(0);
      await handle.writeString(contents);
      await handle.flush();
    } finally {
      await handle.close();
    }

    // 2) Mevcut sağlam kaydı yedekle.
    if (await _file.exists()) {
      await _file.copy(_backupFile.path);
    }

    // 3) Geçici dosyayı asıl kaydın üzerine taşı.
    await _tempFile.rename(_file.path);
  }

  @override
  Future<bool> exists() => _file.exists();

  @override
  Future<void> delete() async {
    if (await _file.exists()) await _file.delete();
    if (await _backupFile.exists()) await _backupFile.delete();
    if (await _tempFile.exists()) await _tempFile.delete();
  }
}

/// Kayıt/yükleme akışı: biçim + depo.
library;

import 'dart:async';
import 'dart:convert';

import '../../domain/models/game_state.dart';
import 'game_state_codec.dart';
import 'save_format.dart';
import 'save_store.dart';

/// Kayıt okuma sonucunun durumu.
enum SaveLoadStatus {
  /// Cihazda kayıt yok.
  yok,

  /// Kayıt okundu.
  yuklendi,

  /// Kayıt var ama okunamıyor (bozuk veya desteklenmeyen sürüm).
  bozuk,
}

/// Kayıt okuma sonucu.
class SaveLoadResult {
  const SaveLoadResult._(this.status, {this.state, this.message});

  const SaveLoadResult.none() : this._(SaveLoadStatus.yok);
  const SaveLoadResult.loaded(GameState state)
      : this._(SaveLoadStatus.yuklendi, state: state);
  const SaveLoadResult.broken(String message)
      : this._(SaveLoadStatus.bozuk, message: message);

  final SaveLoadStatus status;
  final GameState? state;

  /// Bozuk kayıtta kullanıcıya gösterilecek Türkçe açıklama.
  final String? message;

  bool get isLoaded => status == SaveLoadStatus.yuklendi;
}

/// Tek aktif hayat kaydını yöneten servis.
///
/// Çoklu kayıt yuvası **bilinçli olarak** yoktur; bu sürümde tek hayat
/// saklanır (`docs/DESIGN_REVIEW_QUEUE.md`, Q-033).
class SaveService {
  SaveService(this.store);

  final SaveStore store;

  Future<bool> hasSave() => store.exists();

  /// Oyun durumunu yazar.
  Future<void> save(GameState state) async {
    final Map<String, Object?> dosya = <String, Object?>{
      'formatVersion': kSaveFormatVersion,
      'savedAt': DateTime.now().toIso8601String(),
      'state': encodeGameState(state),
    };
    await store.write(jsonEncode(dosya));
  }

  /// Kaydı okur.
  ///
  /// Asıl dosya bozuksa **yedek** denenir. İkisi de okunamazsa kayıt
  /// **silinmez veya üzerine yazılmaz**; durum [SaveLoadStatus.bozuk]
  /// olarak bildirilir ve kararı kullanıcı verir.
  Future<SaveLoadResult> load() async {
    final String? ham = await store.read();
    if (ham == null) return const SaveLoadResult.none();

    final ({GameState? state, String? error}) asil = _parse(ham);
    if (asil.state != null) return SaveLoadResult.loaded(asil.state!);

    // Asıl dosya okunamadı: yazma yarıda kesilmiş olabilir, yedeği dene.
    final String? yedek = await store.readBackup();
    if (yedek != null) {
      final ({GameState? state, String? error}) yedekSonuc = _parse(yedek);
      if (yedekSonuc.state != null) return SaveLoadResult.loaded(yedekSonuc.state!);
    }

    return SaveLoadResult.broken(asil.error!);
  }

  /// Kaydı siler. Yalnızca kullanıcı onayladığında çağrılır.
  Future<void> clear() => store.delete();

  ({GameState? state, String? error}) _parse(String raw) {
    try {
      final Object? decoded = jsonDecode(raw);
      if (decoded is! Map) {
        return (state: null, error: 'Kayıt dosyası okunamadı: beklenen biçimde değil.');
      }
      final Map<String, Object?> dosya = decoded.map<String, Object?>(
        (Object? k, Object? v) => MapEntry<String, Object?>('$k', v),
      );

      final Object? surum = dosya['formatVersion'];
      if (surum is! int) {
        return (
          state: null,
          error: 'Kayıt dosyasında sürüm bilgisi yok.',
        );
      }

      final Object? govde = dosya['state'];
      if (govde is! Map) {
        return (state: null, error: 'Kayıt dosyasında oyun verisi yok.');
      }
      final Map<String, Object?> state = govde.map<String, Object?>(
        (Object? k, Object? v) => MapEntry<String, Object?>('$k', v),
      );

      final Map<String, Object?> guncel = SaveMigrations.migrate(state, surum);
      return (state: decodeGameState(guncel), error: null);
    } on SaveFormatException catch (e) {
      return (state: null, error: e.message);
    } on FormatException {
      return (
        state: null,
        error: 'Kayıt dosyası bozulmuş görünüyor (metin okunamadı).',
      );
    } catch (e) {
      return (state: null, error: 'Kayıt okunamadı: $e');
    }
  }
}

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';

/// Oyundaki kısa ses efektleri (Paket 15).
///
/// Sesler bu proje için üretildi; dışarıdan alınmış ses kullanılmadı.
enum GameSound {
  /// Menü satırına / karta dokunma.
  tap('sounds/tap.wav'),

  /// Bir seçimin onaylanması.
  select('sounds/select.wav'),

  /// Geri dönüş.
  back('sounds/back.wav'),

  /// Yaş alma.
  ageUp('sounds/age_up.wav'),

  /// Olumlu sonuç (zam, burs, kazanç).
  good('sounds/good.wav'),

  /// Olumsuz sonuç. Bilerek yumuşak tutuldu: oyuncuyu cezalandıran bir
  /// ses değil, kısa bir "olmadı" tonu.
  bad('sounds/bad.wav'),

  /// Bildirim penceresi.
  notice('sounds/notice.wav');

  const GameSound(this.asset);

  /// `assets/` altındaki yol.
  final String asset;
}

/// Ses çalmayı tek yerden yöneten küçük servis.
///
/// Kurallar:
/// - Ayarlardan kapatılabilir; kapalıyken hiçbir ses çalınmaz.
/// - Ses çalmak **oyunun akışını hiçbir zaman engellemez**: platformda
///   ses yoksa ya da bir hata olursa sessizce geçilir (testlerde ve
///   eklenti bulunmayan ortamlarda böyle olur).
class SoundService {
  SoundService({AudioPlayer? player, this.enabled = true}) : _player = player;

  /// Hiç ses çalmayan servis.
  ///
  /// Testlerde ve ses eklentisi bulunmayan ortamlarda kullanılır: hiçbir
  /// zaman oynatıcı kurmaz, bu yüzden eklenti yokluğundan kaynaklanan
  /// hatalar da oluşmaz.
  SoundService.silent()
      : _player = null,
        enabled = false,
        _kapali = true;

  /// Oynatıcı **ilk ses çalınana kadar kurulmaz**.
  ///
  /// Eskiden servis kurulur kurulmaz bir `AudioPlayer` yaratılıyordu; ses
  /// eklentisi bulunmayan ortamlarda (testler, kimi masaüstü kurulumları)
  /// bu, oyunun hiç ilgisi olmayan yerlerinde hata veriyordu.
  AudioPlayer? _player;

  /// Oynatıcı kurulamadı mı? Kurulduysa bir daha denenmez.
  bool _kapali = false;

  /// Sesler açık mı? Ayar değişince güncellenir.
  bool enabled;

  /// Aynı sesin üst üste binmesini engellemek için son çalma zamanı.
  DateTime? _sonCalma;

  /// prototypeOnly: iki ses arasındaki en kısa süre.
  static const Duration prototypeOnlyMinGap = Duration(milliseconds: 60);

  Future<void> play(GameSound sound) async {
    if (!enabled) return;
    final DateTime simdi = DateTime.now();
    if (_sonCalma != null &&
        simdi.difference(_sonCalma!) < prototypeOnlyMinGap) {
      return;
    }
    _sonCalma = simdi;
    try {
      final AudioPlayer? player = _oynatici();
      if (player == null) return;
      await player.stop();
      await player.play(AssetSource(sound.asset), volume: 0.6);
    } catch (e) {
      // Ses çalınamadıysa oyun sessizce devam eder.
      _kapali = true;
      if (kDebugMode) {
        debugPrint('Ses çalınamadı (${sound.name}): $e');
      }
    }
  }

  /// Oynatıcıyı gerekirse kurar; kurulamıyorsa `null` döner.
  AudioPlayer? _oynatici() {
    if (_kapali) return null;
    final AudioPlayer? mevcut = _player;
    if (mevcut != null) return mevcut;
    try {
      return _player = AudioPlayer(playerId: 'bir_omur_sfx');
    } catch (_) {
      _kapali = true;
      return null;
    }
  }

  Future<void> dispose() async {
    final AudioPlayer? player = _player;
    _player = null;
    _kapali = true;
    if (player == null) return;
    try {
      await player.dispose();
    } catch (_) {
      // Zaten kapalıysa sorun değil.
    }
  }
}

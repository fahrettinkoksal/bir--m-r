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
  SoundService({AudioPlayer? player, this.enabled = true})
      : _player = player ?? AudioPlayer(playerId: 'bir_omur_sfx');

  final AudioPlayer _player;

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
      await _player.stop();
      await _player.play(AssetSource(sound.asset), volume: 0.6);
    } catch (e) {
      // Ses çalınamadıysa oyun sessizce devam eder.
      if (kDebugMode) {
        debugPrint('Ses çalınamadı (${sound.name}): $e');
      }
    }
  }

  Future<void> dispose() async {
    try {
      await _player.dispose();
    } catch (_) {
      // Zaten kapalıysa sorun değil.
    }
  }
}

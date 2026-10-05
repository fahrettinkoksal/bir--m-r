// Kayda girmeyen alan kalmasın.
//
// **Bu testin varlık sebebi gerçek bir hata:** `GameState.footballCareer`
// Paket AU/1'de eklendi ve `game_state_codec.dart`'a **hiç yazılmadı**.
// PROJECT_STATUS'ta "kayda girdi" diye yazdığım cümle yanlıştı. O sırada
// hiç futbol kariyeri oluşamadığı için eksik **gizli kaldı** ve ancak
// Paket AY'de, kariyer gerçekten oluşmaya başlayınca ortaya çıktı.
// Yani hata haftalarca sessizce durdu: oyuncu kaydı yükleyince kariyeri
// yoktu ve hiçbir test bunu söylemiyordu.
//
// Bu dosya o sınıf hatayı **anında** yakalar: `GameState`'e bir alan
// eklendiği anda kodekte karşılığı yoksa test kırılır.
//
// Yöntem kaynak taramasıdır, çünkü Flutter'da çalışma anı yansıması
// (`dart:mirrors`) yok. Aynı yöntem `stat_gain_test` içinde de
// kullanılıyor (D-099 kaçaklarını aramak için).
library;

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Bilerek kayda **girmeyen** alanlar.
///
/// Boş olması iyidir. Bir alan buraya yalnızca **gerekçesiyle** eklenir:
/// türetilmiş ya da geçici bir değer kayda girmek zorunda değildir, ama
/// bu bir tercih olmalı, unutulmuş bir eksik değil.
const Map<String, String> kKaydaGirmeyenAlanlar = <String, String>{};

void main() {
  test('GameState alanlarının hepsi kodekte geçiyor', () {
    final String model =
        File('lib/domain/models/game_state.dart').readAsStringSync();
    final String kodek =
        File('lib/data/save/game_state_codec.dart').readAsStringSync();

    // `final <tip> <ad>;` kalıbı: GameState'in alanları.
    final RegExp alanKalibi = RegExp(
      r'^\s+final\s+[\w<>?,\s]+\s+(\w+);',
      multiLine: true,
    );
    final Set<String> alanlar = alanKalibi
        .allMatches(model)
        .map((RegExpMatch m) => m.group(1)!)
        .toSet();

    // Model dosyası birkaç küçük sınıf daha barındırıyor; bu yüzden
    // alan sayısının makul bir tabanın üstünde olduğu da denetlenir.
    // Kalıp bozulup sıfır alan bulursa test sessizce geçmesin.
    expect(alanlar.length, greaterThan(50),
        reason: 'Alan kalıbı bozulmuş olabilir: ${alanlar.length} alan '
            'bulundu, oysa GameState çok daha geniş.');

    final List<String> eksik = <String>[];
    for (final String alan in alanlar) {
      if (kKaydaGirmeyenAlanlar.containsKey(alan)) continue;
      // Kodlama tarafı `state.<alan>`, çözme tarafı `'<alan>'` kullanır;
      // ikisinden biri yeterlidir.
      final bool kodlanmis = kodek.contains('state.$alan');
      final bool cozulmus = kodek.contains("'$alan'");
      if (!kodlanmis && !cozulmus) eksik.add(alan);
    }

    expect(
      eksik..sort(),
      isEmpty,
      reason: 'Bu alanlar GameState içinde var ama kodekte hiç '
          'geçmiyor; kaydedilip geri okunmuyor olabilir: '
          '${eksik.join(', ')}.\n'
          'Alan gerçekten kayda girmeyecekse '
          '`kKaydaGirmeyenAlanlar` içine GEREKÇESİYLE ekle.',
    );
  });

  test('bilerek dışarıda bırakılan her alanın gerekçesi yazılı', () {
    for (final MapEntry<String, String> e in kKaydaGirmeyenAlanlar.entries) {
      expect(e.value.trim(), isNotEmpty,
          reason: '${e.key} için gerekçe yazılmamış.');
    }
  });
}

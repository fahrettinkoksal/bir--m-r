/// Paket BZ/1 — metin iş varsayıyorsa koşul da istemeli.
///
/// Paket BZ'nin tarayıcı fikri bütün havuzlara uygulandı: olay metninin
/// varsaydığı şey (eş, çocuk, iş, ev, araç, işletme) koşulda garanti
/// edilmiş mi? 1200'ü aşkın içerik kaydında iki gerçek bulgu çıktı ve
/// ikisi de düzeltildi:
///
/// * `komsu_gurultu` (Paket BU) metni "Sabah işin var." diyordu; olayın
///   koşulunda iş yok, yani emekliye ve öğrenciye de çıkıyordu.
/// * Aile ziyareti olayının bir seçenek etiketi "Kısa kes, işin var"
///   diyordu; aynı sorun.
///
/// Bu dosya **iş varsayımını** kalıcı olarak denetler: dar bir sözcük
/// listesi, muafiyet listesi yok. Aynı sınıf hata (Paket BD'nin
/// "koşulsuz nedeniyle" bulgusu) bir daha sessizce girmesin.
library;

import 'package:bir_omur/data/event_pool.dart';
import 'package:bir_omur/domain/models/game_event.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('iş varsayan metin ve etiketler requiresEmployed istiyor', () {
    // Yalnızca **oyuncunun kendi işini** varsayan kalıplar. "iş buldum",
    // "işe girdim" gibi ifadeler iş olmadığını anlatır; bu yüzden
    // liste dar tutuldu.
    final RegExp desen = RegExp(
      r'işin var|patronun|maaşın\b|maaşını\b|maaşınla|işyerin',
      caseSensitive: false,
    );
    final List<String> hatali = <String>[];

    for (final GameEvent olay in kEventPool) {
      if (olay.requirement.requiresEmployed) continue;
      final List<String> metinler = <String>[
        olay.text,
        for (final EventChoice s in olay.choices) ...<String>[
          s.label,
          s.resultText,
        ],
      ];
      if (metinler.any(desen.hasMatch)) hatali.add(olay.id);
    }

    expect(hatali, isEmpty,
        reason: 'metni/etiketi oyuncunun işini varsayıyor ama koşulda iş '
            'yok: $hatali');
  });
}

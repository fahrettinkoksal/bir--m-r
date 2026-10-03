// Paket AS/2 — yankı olayları gerçekten okunuyor mu?
//
// AS/1 ölçtü: katalogda aranmayan 38 izin 32'si hiçbir yerde
// okunmuyordu. Oyuncu bir seçim yapıyor, oyun izi koyuyor ve sonra onu
// bir daha hiç hatırlamıyordu — boşandın, baba oldun, dört kez yalnız
// kalmayı seçtin: hiçbiri bir daha anılmıyordu.
//
// `event_pool_echo.dart` o izleri okuyan tarafı yazdı. Bu test iki şeyi
// sabitler:
//
//   1. Her yankı olayı **var olan** bir izi arıyor; uydurma iz yok.
//      (Uydurma iz sessizce ölü içerik demektir — AR paketinin bulduğu
//      hata sınıfı.)
//   2. Her yankı olayı tekrarı kendi kapanış izi ve `forbiddenFlags` ile
//      engelliyor; aynı yankı iki kez gelmiyor.
//
// Olayların **gerçekten ekrana geldiği** `paket_ar_zincir_teshis_test`
// tarafından ölçülüyor (ölü halka sayısı 0).
library;

import 'package:bir_omur/data/event_pool.dart';
import 'package:bir_omur/data/event_pool_echo.dart';
import 'package:bir_omur/domain/models/game_event.dart';
import 'package:flutter_test/flutter_test.dart';

/// Katalogda ve motorda konan bütün izler.
Set<String> _konanIzler() {
  final Set<String> out = <String>{};
  for (final GameEvent e in kEventPool) {
    for (final EventChoice c in e.choices) {
      out.addAll(c.addFlags);
    }
  }
  // Motor tarafında konanlar: `bosandi` ve `cocuk_sahibi` gibi izleri
  // hiçbir seçim koymuyor, evlilik ve ebeveynlik motoru koyuyor.
  out.addAll(<String>[
    StoryFlags.bosandi,
    StoryFlags.cocukSahibi,
    StoryFlags.evlilikDisiCocuk,
  ]);
  return out;
}

void main() {
  test('yankı havuzu boş değil', () {
    expect(kEchoEvents, isNotEmpty);
    // ignore: avoid_print
    print('Yankı olayı: ${kEchoEvents.length}');
  });

  test('her yankı olayı var olan bir izi arıyor', () {
    final Set<String> konan = _konanIzler();
    final List<String> uydurma = <String>[];
    for (final GameEvent e in kEchoEvents) {
      expect(e.requirement.requiredFlags, isNotEmpty,
          reason: '${e.id} bir yankı olayı ama hiç iz aramıyor; '
              'o zaman yankı değil, sıradan olaydır.');
      for (final String iz in e.requirement.requiredFlags) {
        if (!konan.contains(iz)) uydurma.add('${e.id} -> $iz');
      }
    }
    expect(
      uydurma,
      isEmpty,
      reason: 'Şu yankı olayları hiç konmayan bir iz arıyor, yani '
          'hiçbir hayatta açılamaz:\n${uydurma.join("\n")}',
    );
  });

  test('her yankı olayı kendi tekrarını engelliyor', () {
    for (final GameEvent e in kEchoEvents) {
      expect(e.requirement.forbiddenFlags, isNotEmpty,
          reason: '${e.id} tekrarı engellemiyor; aynı yankı birden çok '
              'kez gelebilir.');
      // Kapanış izini olayın **bütün** kolları koymalı, yoksa bir kolu
      // seçen oyuncuda olay tekrar çıkar.
      for (final EventChoice c in e.choices) {
        final bool kapatiyor = e.requirement.forbiddenFlags
            .any((String iz) => c.addFlags.contains(iz));
        expect(kapatiyor, isTrue,
            reason: '${e.id}/${c.id} kapanış izini koymuyor; bu kolu '
                'seçen oyuncu aynı yankıyı yeniden görür.');
      }
    }
  });

  test('yankı olaylarının kimlikleri havuzda tekil', () {
    final List<String> hepsi = <String>[
      for (final GameEvent e in kEventPool) e.id,
    ];
    for (final GameEvent e in kEchoEvents) {
      expect(hepsi.where((String id) => id == e.id).length, 1,
          reason: '${e.id} havuzda birden fazla kez var.');
    }
  });

  test('her yankı seçeneğinin sonuç metni var ve kısa', () {
    for (final GameEvent e in kEchoEvents) {
      expect(e.choices.length, greaterThanOrEqualTo(2),
          reason: '${e.id} tek seçenekli; karar değil bildirim olur.');
      for (final EventChoice c in e.choices) {
        expect(c.resultText.trim(), isNotEmpty,
            reason: '${e.id}/${c.id} sonuç metni boş.');
        // docs/WRITING_STYLE_TR.md §8: mobil oyun, 2-4 kısa cümle.
        expect(c.resultText.length, lessThan(260),
            reason: '${e.id}/${c.id} sonuç metni çok uzun '
                '(${c.resultText.length} karakter).');
      }
    }
  });

  test('yankı metinleri yasak kalıpları kullanmıyor', () {
    // docs/WRITING_STYLE_TR.md §2 ve §6.
    const List<String> yasak = <String>[
      'olumlu yönde etkiledi',
      'bu deneyim sonucunda',
      'aranızdaki bağ güçlendi',
      'önemli bir karar verdin',
      'duygusal açıdan',
      'sosyal ilişkilerine katkı',
      'hayatında yeni bir dönem başladı',
      'kendini daha iyi hissettin',
      'bu durum seni mutlu etti',
      'kaliteli vakit geçirdin',
      ' kanka',
      ' moruk',
      ' aga',
      ' lan',
      ' bro',
    ];
    for (final GameEvent e in kEchoEvents) {
      final String hepsi = <String>[
        e.text,
        for (final EventChoice c in e.choices) ...<String>[
          c.label,
          c.resultText,
        ],
      ].join(' ').toLowerCase();
      for (final String k in yasak) {
        expect(hepsi.contains(k), isFalse,
            reason: '${e.id} yasak kalıp içeriyor: "$k"');
      }
    }
  });
}

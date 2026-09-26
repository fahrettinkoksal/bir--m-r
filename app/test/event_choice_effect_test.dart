import 'package:bir_omur/data/event_pool.dart';
import 'package:bir_omur/domain/models/game_event.dart';
import 'package:flutter_test/flutter_test.dart';

/// Her olay seçimi somut bir değişiklik üretir (D-098).
///
/// "Bir şey yapmadın" hissi veren seçim yazılmaz: her seçenek ya bir
/// değeri, ya parayı, ya bir ilişkiyi, ya da hikâyenin gidişatını
/// gerçekten değiştirir.
void main() {
  bool degerDegistirir(EventChoice c) =>
      c.happiness != 0 ||
      c.health != 0 ||
      c.intelligence != 0 ||
      c.charisma != 0 ||
      c.appearance != 0 ||
      c.bond != 0 ||
      c.money != 0;

  bool durumDegistirir(EventChoice c) =>
      c.addFlags.isNotEmpty ||
      c.removeFlags.isNotEmpty ||
      c.addPossessions.isNotEmpty ||
      c.startsRomance ||
      c.endsRomance ||
      c.startsSchoolFriendship ||
      c.startsFriendship ||
      c.rememberPersonAs != null;

  test('hiçbir olay seçimi etkisiz değildir', () {
    final List<String> etkisiz = <String>[
      for (final GameEvent e in kEventPool)
        for (final EventChoice c in e.choices)
          if (!degerDegistirir(c) && !durumDegistirir(c)) '${e.id}/${c.id}',
    ];
    expect(etkisiz, isEmpty, reason: 'Etkisiz seçim: ${etkisiz.join(', ')}');
  });

  test('her seçim ekranda görülebilir bir değişiklik üretir', () {
    // Yalnızca görünmez bir hikâye işareti bırakan seçim, oyuncuya
    // "hiçbir şey olmadı" hissi verir. Böyle bir seçim yoktur.
    final List<String> gorunmez = <String>[
      for (final GameEvent e in kEventPool)
        for (final EventChoice c in e.choices)
          if (!degerDegistirir(c) && durumDegistirir(c)) '${e.id}/${c.id}',
    ];
    expect(
      gorunmez,
      isEmpty,
      reason: 'Yalnızca işaret bırakan seçim: ${gorunmez.join(', ')}',
    );
  });

  test('her olayın en az iki seçeneği vardır', () {
    for (final GameEvent e in kEventPool) {
      expect(
        e.choices.length,
        greaterThanOrEqualTo(2),
        reason: '${e.id} tek seçenekli; seçim değil bildirim olur.',
      );
    }
  });

  test('sonuç metni boş bırakılmaz', () {
    for (final GameEvent e in kEventPool) {
      for (final EventChoice c in e.choices) {
        expect(
          c.resultText.trim(),
          isNotEmpty,
          reason: '${e.id}/${c.id} sonucu anlatmıyor.',
        );
      }
    }
  });
}

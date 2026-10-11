import 'package:flutter_test/flutter_test.dart';
import 'package:bir_omur/domain/models/game_state.dart';
import 'support/player_bot.dart';

void main() {
  test('PROBE mülakat karesi hangi kancaya görünüyor', () {
    const List<PlayerArchetype> ark = <PlayerArchetype>[
      PlayerArchetype.career,
      PlayerArchetype.family,
      PlayerArchetype.casual,
      PlayerArchetype.risky,
    ];
    int pendingKare = 0;
    int preAgeKare = 0;
    int yearKare = 0;
    int pendingHayat = 0;
    int preAgeHayat = 0;

    for (int i = 0; i < 120; i++) {
      bool p = false;
      bool pa = false;
      playBotLife(
        archetype: ark[i % ark.length],
        seed: 60000 + i,
        onPending: (GameState s) {
          if (s.hasPendingInterview) {
            pendingKare++;
            p = true;
          }
        },
        onPreAge: (GameState s) {
          if (s.hasPendingInterview) {
            preAgeKare++;
            pa = true;
          }
        },
        onYear: (GameState s) {
          if (s.hasPendingInterview) yearKare++;
        },
      );
      if (p) pendingHayat++;
      if (pa) preAgeHayat++;
    }

    // ignore: avoid_print
    print('onPending: kare=$pendingKare hayat=$pendingHayat/120');
    // ignore: avoid_print
    print('onPreAge : kare=$preAgeKare hayat=$preAgeHayat/120');
    // ignore: avoid_print
    print('onYear   : kare=$yearKare');
  }, timeout: const Timeout(Duration(minutes: 25)));
}

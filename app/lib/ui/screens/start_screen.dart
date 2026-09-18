import 'package:flutter/material.dart';

import '../../domain/generation/life_generator.dart';
import '../../state/game_scope.dart';
import '../widgets/kilim_divider.dart';
import 'creation_screen.dart';

/// Açılış ekranı: iki başlangıç modu (D-005).
class StartScreen extends StatelessWidget {
  const StartScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              const Spacer(flex: 2),
              Text(
                'Bir Ömür',
                textAlign: TextAlign.center,
                style: theme.textTheme.displaySmall?.copyWith(
                  fontWeight: FontWeight.w800,
                  letterSpacing: -1,
                  color: theme.colorScheme.primary,
                ),
              ),
              const SizedBox(height: 10),
              const KilimDivider(height: 12),
              const SizedBox(height: 10),
              Text(
                'Bir hayat başlıyor. Nerede doğacağın, kimlerle büyüyeceğin '
                've neyle uğraşacağın önceden belli değil.',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const Spacer(flex: 3),
              FilledButton(
                onPressed: () {
                  GameScope.of(context)
                      .startNewLife(mode: StartMode.tamamenRastgele);
                },
                child: const Text('Rastgele bir hayat'),
              ),
              const SizedBox(height: 12),
              OutlinedButton(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => const CreationScreen(),
                    ),
                  );
                },
                child: const Text('İsmimi ve cinsiyetimi seçeyim'),
              ),
              const SizedBox(height: 16),
              Text(
                'Her iki modda da doğum şehri, aile ve diğer başlangıç '
                'koşulları rastgele belirlenir.',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const Spacer(),
            ],
          ),
        ),
      ),
    );
  }
}

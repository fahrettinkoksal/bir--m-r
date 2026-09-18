import 'package:flutter/material.dart';

import '../../domain/generation/life_generator.dart';
import '../../domain/models/gender.dart';
import '../../state/game_scope.dart';

/// İkinci başlangıç modu: oyuncu yalnızca isim ve cinsiyet seçer (D-005).
class CreationScreen extends StatefulWidget {
  const CreationScreen({super.key});

  @override
  State<CreationScreen> createState() => _CreationScreenState();
}

class _CreationScreenState extends State<CreationScreen> {
  final TextEditingController _nameController = TextEditingController();
  Gender _gender = Gender.kadin;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _start() {
    GameScope.of(context).startNewLife(
      mode: StartMode.isimVeCinsiyet,
      firstName: _nameController.text,
      gender: _gender,
    );
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('İsim ve cinsiyet')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              const SizedBox(height: 8),
              Text(
                'Yalnızca bu ikisini sen belirliyorsun. Şehir, aile, kardeşler '
                've geri kalan her şey rastgele oluşacak.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 26),
              TextField(
                controller: _nameController,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(
                  labelText: 'İsim',
                  helperText: 'Boş bırakırsan rastgele bir isim verilir.',
                  border: OutlineInputBorder(),
                ),
                onSubmitted: (_) => _start(),
              ),
              const SizedBox(height: 22),
              Text('Cinsiyet', style: theme.textTheme.labelLarge),
              const SizedBox(height: 8),
              SegmentedButton<Gender>(
                segments: <ButtonSegment<Gender>>[
                  for (final Gender g in Gender.values)
                    ButtonSegment<Gender>(value: g, label: Text(g.label)),
                ],
                selected: <Gender>{_gender},
                onSelectionChanged: (Set<Gender> selection) {
                  setState(() => _gender = selection.first);
                },
              ),
              const Spacer(),
              FilledButton(
                onPressed: _start,
                child: const Text('Hayata başla'),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}

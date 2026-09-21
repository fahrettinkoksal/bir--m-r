import 'package:flutter/material.dart';

import '../sound/sound_scope.dart';
import '../sound/sound_service.dart';

import '../../domain/models/applied_effect.dart';
import '../../domain/models/game_event.dart';
import '../../state/game_controller.dart';
import '../../state/game_scope.dart';
import '../theme/bir_omur_theme.dart';
import 'effect_chips.dart';
import '../../text/turkish_text.dart';

/// Yaş alınca çıkan tek olayı ve oyun içi ilerlemeyle gelen ek olayı gösterir.
///
/// Seçim yapılmadan kapatılamaz; aynı anda birden fazla olay penceresi
/// açılmaz (D-021).
class EventDialog extends StatefulWidget {
  const EventDialog({super.key, required this.event});

  final ActiveEvent event;

  static Future<void> show(BuildContext context, ActiveEvent event) {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      useRootNavigator: true,
      builder: (BuildContext context) => EventDialog(event: event),
    );
  }

  @override
  State<EventDialog> createState() => _EventDialogState();
}

class _EventDialogState extends State<EventDialog> {
  String? _resultText;
  List<AppliedEffect> _effects = const <AppliedEffect>[];

  void _choose(EventChoice choice) {
    SoundScope.play(context, GameSound.select);
    final EventChoiceResult? result = GameScope.of(
      context,
    ).chooseEventOption(choice.id);
    setState(() {
      _resultText = result?.text ?? choice.resultText;
      _effects = result?.effects ?? const <AppliedEffect>[];
    });
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final bool answered = _resultText != null;

    return PopScope(
      canPop: answered,
      child: Dialog(
        insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                // Olayın hangi alandan geldiği renkli bir rozette durur;
                // pencere açılır açılmaz bağlam bellidir.
                Row(
                  children: <Widget>[
                    Container(
                      padding: const EdgeInsets.fromLTRB(10, 6, 14, 6),
                      decoration: BoxDecoration(
                        gradient: _kategoriRengi(widget.event.category)
                            .heroGradient,
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: <Widget>[
                          Icon(
                            _kategoriSimgesi(widget.event.category),
                            size: 15,
                            color: Colors.white,
                          ),
                          const SizedBox(width: 7),
                          Text(
                            trUpper(widget.event.category.label),
                            style: theme.textTheme.labelSmall?.copyWith(
                              fontWeight: FontWeight.w900,
                              letterSpacing: 1,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  widget.event.text,
                  style: theme.textTheme.bodyLarge?.copyWith(height: 1.45),
                ),
                const SizedBox(height: 20),
                // Seçenekten sonuca geçiş yumuşak olsun: pencere birden
                // değişmez.
                AnimatedSize(
                  duration: const Duration(milliseconds: 220),
                  curve: Curves.easeOut,
                  alignment: Alignment.topCenter,
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 220),
                    child: Column(
                      key: ValueKey<bool>(answered),
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        if (!answered)
                          for (final EventChoice choice
                              in widget.event.choices) ...<Widget>[
                            _ChoiceButton(
                              label: choice.label,
                              accent: _kategoriRengi(widget.event.category),
                              onTap: () => _choose(choice),
                            ),
                            const SizedBox(height: 10),
                          ]
                        else ...<Widget>[
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.surfaceContainer,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: <Widget>[
                                Text(
                                  _resultText!,
                                  style: theme.textTheme.bodyMedium,
                                ),
                                if (_effects.isNotEmpty) ...<Widget>[
                                  const SizedBox(height: 12),
                                  EffectChips(effects: _effects),
                                ],
                              ],
                            ),
                          ),
                          const SizedBox(height: 14),
                          SizedBox(
                            width: double.infinity,
                            child: FilledButton(
                              onPressed: () => Navigator.of(context).pop(),
                              child: const Text('Devam'),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Olay alanının rengi.
  static BirOmurAccent _kategoriRengi(EventCategory category) {
    switch (category) {
      case EventCategory.aile:
        return BirOmurAccents.nar;
      case EventCategory.okul:
        return BirOmurAccents.mavi;
      case EventCategory.mahalle:
        return BirOmurAccents.turuncu;
      case EventCategory.kisisel:
        return BirOmurAccents.mor;
      case EventCategory.yetiskinlik:
        return BirOmurAccents.cini;
    }
  }

  static IconData _kategoriSimgesi(EventCategory category) {
    switch (category) {
      case EventCategory.aile:
        return Icons.people_outline;
      case EventCategory.okul:
        return Icons.school_outlined;
      case EventCategory.mahalle:
        return Icons.holiday_village_outlined;
      case EventCategory.kisisel:
        return Icons.self_improvement_outlined;
      case EventCategory.yetiskinlik:
        return Icons.work_outline;
    }
  }
}

/// Olay penceresindeki tek seçenek düğmesi.
///
/// Tonal düğme yerine kendi kartı: geniş dokunma alanı, olayın rengini
/// taşıyan ince çerçeve ve ortalanmış kalın yazı.
class _ChoiceButton extends StatelessWidget {
  const _ChoiceButton({
    required this.label,
    required this.accent,
    required this.onTap,
  });

  final String label;
  final BirOmurAccent accent;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final Color renk = accent.of(context);
    return Material(
      color: accent.softOf(context),
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          width: double.infinity,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: renk.withValues(alpha: 0.45), width: 1.4),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: accent.deepOf(context),
              fontWeight: FontWeight.w800,
              fontSize: 15.5,
              height: 1.25,
            ),
          ),
        ),
      ),
    );
  }
}

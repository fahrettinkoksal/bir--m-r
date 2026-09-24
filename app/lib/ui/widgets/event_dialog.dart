import 'package:flutter/material.dart';

import '../sound/sound_scope.dart';
import '../sound/sound_service.dart';

import '../../domain/models/applied_effect.dart';
import '../../domain/models/game_event.dart';
import '../../state/game_controller.dart';
import '../../state/game_scope.dart';
import '../theme/bir_omur_theme.dart';
import 'comic.dart';
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
        // Eylem düğmeleri **kaydırma alanının dışındadır**: uzun olay
        // metinlerinde düğme ekranın altına kaçıp ulaşılamaz oluyordu.
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Flexible(
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
                        color: _kategoriRengi(widget.event.category).color,
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(
                          color: Comic.konturOf(context),
                          width: Comic.inceKontur,
                        ),
                        boxShadow: comicShadow(context, offset: 2.5),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: <Widget>[
                          Icon(
                            _kategoriSimgesi(widget.event.category),
                            size: 15,
                            color: _kategoriRengi(widget.event.category)
                                .onColor,
                          ),
                          const SizedBox(width: 7),
                          Text(
                            trUpper(widget.event.category.label),
                            style: theme.textTheme.labelSmall?.copyWith(
                              letterSpacing: 1,
                              color: _kategoriRengi(widget.event.category)
                                  .onColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Faho'nun Q-114 kararı: devam olayına büyük bir
                    // "QUEST" etiketi konmaz ama küçük, doğal bir işaret
                    // olabilir. Oyuncu bunun yıllar önceki bir seçimin
                    // devamı olduğunu görebilsin.
                    if (widget.event.isContinuation) ...<Widget>[
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          'Geçmişten…',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.labelSmall?.copyWith(
                            fontStyle: FontStyle.italic,
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                    const SizedBox(height: 16),
                    Text(
                      widget.event.text,
                      style: theme.textTheme.bodyLarge,
                    ),
                    if (answered) ...<Widget>[
                      const SizedBox(height: 16),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.surfaceContainer,
                          borderRadius: BorderRadius.circular(Comic.yaricap),
                          border: Border.all(
                            color: Comic.konturOf(context),
                            width: Comic.inceKontur,
                          ),
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
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
                if (!answered)
                  for (final EventChoice choice
                      in widget.event.choices) ...<Widget>[
                    _ChoiceButton(
                      label: choice.label,
                      accent: _kategoriRengi(widget.event.category),
                      onTap: () => _choose(choice),
                    ),
                    const SizedBox(height: 8),
                  ]
                else
                  StickerButton(
                    expand: true,
                    color: BirOmurColors.kirmizi,
                    sound: GameSound.select,
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text(
                      'Devam',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: BirOmurColors.krem,
                      ),
                    ),
                  ),
            ],
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
/// Olayın rengini taşıyan, basınca çöken bir çıkartma.
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
    return StickerButton(
      expand: true,
      color: accent.softOf(context),
      sound: GameSound.select,
      onPressed: onTap,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Text(
        label,
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w700,
          height: 1.25,
          color: Theme.of(context).colorScheme.onSurface,
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';

import '../sound/sound_scope.dart';
import '../sound/sound_service.dart';

import '../../domain/life/notices.dart';
import '../../domain/models/pending_notice.dart';
import '../../state/game_scope.dart';
import '../../text/turkish_text.dart';
import 'kilim_divider.dart';

/// Önemli haber penceresi (D-050).
///
/// Ölüm, miras ve cenaze bildirimleri burada gösterilir. Metin kısa ve
/// saygılıdır; etki yalnızca **gerçekten uygulandığı kadar** yazılır.
/// Pencere seçim yapılmadan kapanmaz; bekleyen bildirim kayıtta durur.
class NoticeSheet extends StatefulWidget {
  const NoticeSheet({super.key, required this.notice});

  final PendingNotice notice;

  static Future<void> show(BuildContext context, PendingNotice notice) {
    // Bildirim sakin bir çanla açılır (Paket 15).
    SoundScope.play(context, GameSound.notice);
    return showModalBottomSheet<void>(
      context: context,
      isDismissible: false,
      enableDrag: false,
      useRootNavigator: true,
      showDragHandle: false,
      builder: (BuildContext context) => NoticeSheet(notice: notice),
    );
  }

  @override
  State<NoticeSheet> createState() => _NoticeSheetState();
}

class _NoticeSheetState extends State<NoticeSheet> {
  String? _sonuc;

  /// Cenaze akışında önce katılım sorulur (D-050): katılmak ile masrafa
  /// katkıda bulunmak aynı şey değildir.
  FuneralAttendance? _katilim;

  void _kapat() {
    GameScope.of(context).dismissNotice();
    Navigator.of(context).pop();
  }

  void _katilimSec(FuneralAttendance secim) {
    setState(() => _katilim = secim);
  }

  void _cenaze(FuneralChoice secim) {
    final String? metin = GameScope.of(context).respondToFuneral(
      secim,
      attendance: _katilim ?? FuneralAttendance.katildi,
    );
    setState(() => _sonuc = metin);
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final PendingNotice notice = widget.notice;
    final bool cenaze = notice.kind == NoticeKind.cenaze && _sonuc == null;
    final bool katilimSorulacak = cenaze && _katilim == null;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                Icon(
                  _simge(notice.kind),
                  size: 18,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  trUpper(notice.title),
                  key: const Key('notice_title'),
                  style: theme.textTheme.labelMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.1,
                    color: theme.colorScheme.primary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            const KilimDivider(),
            const SizedBox(height: 14),
            Text(
              _sonuc ?? notice.text,
              key: const Key('notice_text'),
              style: theme.textTheme.bodyLarge,
            ),
            // Etki yalnızca gerçekten uygulandıysa yazılır.
            if (_sonuc == null && notice.happinessDelta < 0) ...<Widget>[
              const SizedBox(height: 12),
              Text(
                'Mutluluk ${notice.happinessDelta}',
                style: theme.textTheme.labelLarge?.copyWith(
                  color: theme.colorScheme.error,
                ),
              ),
            ],
            if (_sonuc == null && notice.kind == NoticeKind.miras) ...<Widget>[
              const SizedBox(height: 12),
              if (notice.money > 0)
                Text(
                  'Cüzdanına ${trMoney(notice.money)} geçti.',
                  style: theme.textTheme.bodyMedium,
                ),
              for (final String ad in notice.itemNames)
                Text('$ad sana kaldı.', style: theme.textTheme.bodyMedium),
            ],
            const SizedBox(height: 18),
            if (katilimSorulacak) ...<Widget>[
              SizedBox(
                width: double.infinity,
                child: FilledButton.tonal(
                  key: const Key('funeral_attend_katildi'),
                  onPressed: () => _katilimSec(FuneralAttendance.katildi),
                  child: const Text('Cenazeye katıl'),
                ),
              ),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: FilledButton.tonal(
                  key: const Key('funeral_attend_katilamadi'),
                  onPressed: () => _katilimSec(FuneralAttendance.katilamadi),
                  child: const Text('Katılamıyorum'),
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'Cenazeye katılmak ile masraflara katkıda bulunmak ayrı '
                'şeylerdir; ikisini de ayrı ayrı seçeceksin.',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ] else if (cenaze) ...<Widget>[
              Text(
                _katilim == FuneralAttendance.katildi
                    ? 'Cenazeye katılıyorsun. Masraflara katkıda bulunmak '
                        'ister misin?'
                    : 'Cenazeye katılamıyorsun. Masraflara katkıda bulunmak '
                        'ister misin?',
                style: theme.textTheme.bodyMedium,
              ),
              const SizedBox(height: 12),
              for (final FuneralChoice secim in FuneralChoice.values)
                if (GameScope.of(context).canChooseFuneral(secim)) ...<Widget>[
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.tonal(
                      key: Key('funeral_choice_${secim.name}'),
                      onPressed: () => _cenaze(secim),
                      child: Text(_secenekMetni(context, secim)),
                    ),
                  ),
                  const SizedBox(height: 10),
                ],
              Text(
                'Katkı bir borç değildir ve mirası etkilemez.',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ] else
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  key: const Key('notice_close'),
                  onPressed: _kapat,
                  child: const Text('Tamam'),
                ),
              ),
          ],
        ),
      ),
    );
  }

  String _secenekMetni(BuildContext context, FuneralChoice secim) {
    final int tutar = GameScope.of(context).funeralAmount(secim);
    switch (secim) {
      case FuneralChoice.tamKatki:
        return 'Katkıda bulun (${trMoney(tutar)})';
      case FuneralChoice.kismiKatki:
        return 'Elinden geldiğince katkıda bulun (${trMoney(tutar)})';
      case FuneralChoice.katkiYok:
        return 'Bu sefer katkıda bulunma';
    }
  }

  static IconData _simge(NoticeKind kind) {
    switch (kind) {
      case NoticeKind.olum:
        return Icons.spa_outlined;
      case NoticeKind.miras:
        return Icons.card_giftcard_outlined;
      case NoticeKind.cenaze:
        return Icons.volunteer_activism_outlined;
      case NoticeKind.okul:
        return Icons.school_rounded;
      case NoticeKind.dogum:
        return Icons.child_friendly_rounded;
      case NoticeKind.burc:
        return Icons.auto_awesome_rounded;
    }
  }
}

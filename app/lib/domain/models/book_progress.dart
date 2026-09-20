import 'package:flutter/foundation.dart';

import '../../data/activity_catalog.dart';

/// Bir kitabın okuma ilerlemesi.
///
/// Gerçek oyun verisidir: kaç sayfa okunduğu ve bitirilip bitirilmediği
/// kaydedilir, uygulama kapanıp açılınca kaldığı yerden devam eder.
@immutable
class BookProgress {
  const BookProgress({
    required this.bookId,
    required this.pagesRead,
    this.finished = false,
    this.startedAtAge,
  });

  final String bookId;
  final int pagesRead;

  /// Kitap bitirildi mi? Kazanç yalnızca **ilk** bitirişte uygulanır.
  final bool finished;

  final int? startedAtAge;

  BookInfo? get book => bookById(bookId);

  /// 0-1 arası ilerleme.
  double get ratio {
    final int toplam = book?.pages ?? 0;
    if (toplam <= 0) return 0;
    return (pagesRead / toplam).clamp(0, 1);
  }

  BookProgress copyWith({int? pagesRead, bool? finished}) => BookProgress(
        bookId: bookId,
        pagesRead: pagesRead ?? this.pagesRead,
        finished: finished ?? this.finished,
        startedAtAge: startedAtAge,
      );
}

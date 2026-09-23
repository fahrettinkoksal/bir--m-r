import 'package:flutter/foundation.dart';

import '../../data/hobby_catalog.dart';

/// Hobi geçmişine düşen bir an (Paket 39).
///
/// Yalnızca **gerçekten olmuş** bir basamak yükselişinde yazılır; uydurma
/// anı üretilmez ve yaşı bilinmeyen an kaydedilmez.
@immutable
class HobbyMemory {
  const HobbyMemory({required this.age, required this.text});

  final int age;
  final String text;
}

/// Bir hobideki kalıcı ilerleme.
///
/// Kayda girer: hobi türü, başlama yaşı, deneyim, son uğraşılan yaş ve
/// önemli anlar. Böylece 10 yaşında gitara başlayıp 17'ye kadar devam eden
/// biri ileride gerçekten "müzikle ilgilenen" olarak tanınır.
@immutable
class HobbyProgress {
  const HobbyProgress({
    required this.hobbyId,
    required this.startedAtAge,
    required this.experience,
    required this.lastPracticedAge,
    this.memories = const <HobbyMemory>[],
  });

  final String hobbyId;

  /// Bu hobiye ilk başlanan yaş.
  final int startedAtAge;

  /// Toplam deneyim. Her anlamlı uğraş bir artırır.
  final int experience;

  /// En son hangi yaşta uğraşıldı?
  final int lastPracticedAge;

  /// Basamak yükselişlerinde biriken anılar.
  final List<HobbyMemory> memories;

  HobbyKind? get hobby => hobbyById(hobbyId);

  /// Şu anki basamağın sırası.
  int get stage => hobby?.stageFor(experience) ?? 0;

  /// Şu anki basamağın adı.
  String get stageLabel {
    final HobbyKind? h = hobby;
    if (h == null) return '';
    return h.stages[stage].label;
  }

  /// Kaç yıl sürdü? (Son uğraşma ile başlama arasındaki fark.)
  int get years => (lastPracticedAge - startedAtAge).clamp(0, 120);

  /// [age] yaşında bu hobi hâlâ sürüyor sayılır mı?
  bool isActiveAt(int age) =>
      age - lastPracticedAge <= kHobbyActiveWithinYears;

  /// Olaylarda "ciddi" sayılacak kadar uzun sürdü mü?
  bool get isSerious => years >= kHobbySeriousYears;

  HobbyProgress copyWith({
    int? experience,
    int? lastPracticedAge,
    List<HobbyMemory>? memories,
  }) =>
      HobbyProgress(
        hobbyId: hobbyId,
        startedAtAge: startedAtAge,
        experience: experience ?? this.experience,
        lastPracticedAge: lastPracticedAge ?? this.lastPracticedAge,
        memories: memories ?? this.memories,
      );
}

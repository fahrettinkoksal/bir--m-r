/// Dövüş sanatları: karate, kung fu ve yağlı güreş.
///
/// Basamak adları **gerçek derecelendirmelerden** derlendi:
/// - Karate: öğrenci dereceleri *kyu* (aşağıdan yukarı sayılır), ustalık
///   dereceleri *dan*. Kahverengi kuşak siyaha geçiş olduğu için üçe
///   ayrılır (3., 2., 1. kyu).
/// - Kung fu / wushu: okullarda beyazdan siyaha kuşak (sash) düzeni, üstünde
///   Çin Wushu Federasyonu'nun *duanwei* dereceleri.
/// - Yağlı güreş: Kırkpınar'ın boy sıralaması; minikten başpehlivanlığa.
///
/// Adlar gerçektir, **sayılar değil**: ders ücreti, ders sayıları, etkiler ve
/// eğitmenlik eşiği `prototypeOnly`'dir
/// (`docs/DESIGN_REVIEW_QUEUE.md`, Q-100).
library;

import 'package:flutter/material.dart';

/// Bir dövüş sanatındaki tek basamak.
@immutable
class MartialRank {
  const MartialRank({
    required this.name,
    required this.lessonsNeeded,
    this.note = '',
  });

  /// Basamağın gerçek adı ("Sarı kuşak (8. kyu)", "Başaltı"…).
  final String name;

  /// prototypeOnly: bu basamağa çıkmak için gereken **toplam** ders sayısı.
  final int lessonsNeeded;

  /// Basamağın kısa açıklaması.
  final String note;
}

/// Oyundaki dövüş sanatları.
enum MartialArt {
  karate(
    id: 'karate',
    label: 'Karate',
    icon: Icons.sports_martial_arts_rounded,
    description: 'Duruş, vuruş ve kata. İlerleme kuşakla ölçülür.',
    lessonCost: 180, // prototypeOnly
    minAge: 7,
    instructorFromLevel: 9, // Siyah kuşak (1. Dan)
    instructorJobId: 'karate_egitmeni',
    ranks: <MartialRank>[
      MartialRank(
        name: 'Beyaz kuşak (9. kyu)',
        lessonsNeeded: 0,
        note: 'Başlangıç. Kuşağın rengi henüz hiçbir şey anlatmıyor.',
      ),
      MartialRank(
        name: 'Sarı kuşak (8. kyu)',
        lessonsNeeded: 5,
        note: 'Temel duruşlar oturdu.',
      ),
      MartialRank(
        name: 'Turuncu kuşak (7. kyu)',
        lessonsNeeded: 12,
        note: 'İlk katalar ezberlendi.',
      ),
      MartialRank(
        name: 'Yeşil kuşak (6. kyu)',
        lessonsNeeded: 20,
        note: 'Vuruşlar artık dengeli.',
      ),
      MartialRank(
        name: 'Mavi kuşak (5. kyu)',
        lessonsNeeded: 30,
        note: 'Eşleşmeli çalışmaya geçildi.',
      ),
      MartialRank(
        name: 'Mor kuşak (4. kyu)',
        lessonsNeeded: 42,
        note: 'Kumitede tutunabiliyorsun.',
      ),
      MartialRank(
        name: 'Kahverengi kuşak (3. kyu)',
        lessonsNeeded: 56,
        note: 'Siyaha giden yolun ilk basamağı.',
      ),
      MartialRank(
        name: 'Kahverengi kuşak (2. kyu)',
        lessonsNeeded: 72,
        note: 'Sınavlar artık ağırlaşıyor.',
      ),
      MartialRank(
        name: 'Kahverengi kuşak (1. kyu)',
        lessonsNeeded: 90,
        note: 'Siyah kuşak sınavına bir adım kaldı.',
      ),
      MartialRank(
        name: 'Siyah kuşak (1. Dan)',
        lessonsNeeded: 110,
        note: 'Ustalığın başlangıcı sayılır; bitişi değil.',
      ),
      MartialRank(
        name: 'Siyah kuşak (2. Dan)',
        lessonsNeeded: 150,
        note: 'Artık kendi öğrencilerin olabilir.',
      ),
      MartialRank(
        name: 'Siyah kuşak (3. Dan)',
        lessonsNeeded: 200,
        note: 'Salonda adın anılıyor.',
      ),
    ],
  ),

  kungFu(
    id: 'kung_fu',
    label: 'Kung fu',
    icon: Icons.self_improvement_rounded,
    description: 'Formlar, nefes ve sabır. Kuşaktan duanwei derecesine.',
    lessonCost: 200, // prototypeOnly
    minAge: 8,
    instructorFromLevel: 5, // Siyah kuşak
    instructorJobId: 'kungfu_egitmeni',
    ranks: <MartialRank>[
      MartialRank(
        name: 'Beyaz kuşak',
        lessonsNeeded: 0,
        note: 'Duruş ve nefesle başlanır.',
      ),
      MartialRank(
        name: 'Sarı kuşak',
        lessonsNeeded: 6,
        note: 'Temel hareketler (jibengong).',
      ),
      MartialRank(
        name: 'Yeşil kuşak',
        lessonsNeeded: 15,
        note: 'İlk form baştan sona çıkarılıyor.',
      ),
      MartialRank(
        name: 'Mavi kuşak',
        lessonsNeeded: 26,
        note: 'Denge ve esneklik yerine oturdu.',
      ),
      MartialRank(
        name: 'Kahverengi kuşak',
        lessonsNeeded: 40,
        note: 'Formlar hızlandı, eşleşmeli çalışma başladı.',
      ),
      MartialRank(
        name: 'Siyah kuşak',
        lessonsNeeded: 58,
        note: 'Okulun kıdemlilerindensin.',
      ),
      MartialRank(
        name: '1. Duan',
        lessonsNeeded: 82,
        note: 'Duanwei düzeninin ilk resmî derecesi.',
      ),
      MartialRank(
        name: '2. Duan',
        lessonsNeeded: 110,
        note: 'Yarışma düzeyi.',
      ),
      MartialRank(
        name: '3. Duan',
        lessonsNeeded: 145,
        note: 'Yuduan basamağının sonu.',
      ),
    ],
  ),

  gures(
    id: 'gures',
    label: 'Yağlı güreş',
    icon: Icons.sports_kabaddi_rounded,
    description: 'Kıspet, zeytinyağı ve çayır. Boyun yükseldikçe rakip büyür.',
    lessonCost: 150, // prototypeOnly
    minAge: 9,
    instructorFromLevel: 7, // Başaltı
    instructorJobId: 'gures_antrenoru',
    ranks: <MartialRank>[
      MartialRank(
        name: 'Minik',
        lessonsNeeded: 0,
        note: 'En küçük boy. Çayıra ilk adım.',
      ),
      MartialRank(
        name: 'Teşvik',
        lessonsNeeded: 6,
        note: 'Oyunları öğrenme boyu.',
      ),
      MartialRank(
        name: 'Tozkoparan',
        lessonsNeeded: 14,
        note: 'Adı üstünde: toprağı kaldıran çırpınış.',
      ),
      MartialRank(
        name: 'Ayak',
        lessonsNeeded: 24,
        note: 'Ayakta durabilen pehlivanların boyu.',
      ),
      MartialRank(
        name: 'Deste',
        lessonsNeeded: 36,
        note: 'Küçük, orta, büyük deste; hepsini geçtin.',
      ),
      MartialRank(
        name: 'Küçük orta',
        lessonsNeeded: 52,
        note: 'Artık seyirci adını öğreniyor.',
      ),
      MartialRank(
        name: 'Büyük orta',
        lessonsNeeded: 70,
        note: 'Başaltına bir boy kaldı.',
      ),
      MartialRank(
        name: 'Başaltı',
        lessonsNeeded: 92,
        note: 'Başpehlivanlığın kapısı. Kırkpınar\'da en çetin boylardan.',
      ),
      MartialRank(
        name: 'Başpehlivan',
        lessonsNeeded: 120,
        note: 'Altın kemer. Adın Kırkpınar\'a yazılır.',
      ),
    ],
  );

  const MartialArt({
    required this.id,
    required this.label,
    required this.icon,
    required this.description,
    required this.lessonCost,
    required this.minAge,
    required this.instructorFromLevel,
    required this.instructorJobId,
    required this.ranks,
  });

  final String id;
  final String label;
  final IconData icon;
  final String description;

  /// prototypeOnly: tek ders ücreti (₺). Bilerek düşük tutuldu.
  final int lessonCost;

  /// prototypeOnly: en küçük başlama yaşı.
  final int minAge;

  /// prototypeOnly: eğitmenlik işinin açıldığı basamak sırası.
  final int instructorFromLevel;

  /// Bu basamağa gelindiğinde açılan meslek.
  final String instructorJobId;

  final List<MartialRank> ranks;

  /// En üst basamağın sırası.
  int get topLevel => ranks.length - 1;

  /// Eğitmenliğin açıldığı basamağın adı.
  String get instructorRankName => ranks[instructorFromLevel].name;

  /// En üst basamak için gereken toplam ders.
  int get totalLessons => ranks.last.lessonsNeeded;

  /// [lessons] ders sonunda hangi basamaktasın?
  int levelForLessons(int lessons) {
    int seviye = 0;
    for (int i = 0; i < ranks.length; i++) {
      if (lessons >= ranks[i].lessonsNeeded) seviye = i;
    }
    return seviye;
  }
}

/// prototypeOnly: aynı yaşta alınabilecek en fazla ders sayısı.
///
/// Ayda bir dersten biraz fazlası. Siyah kuşağın yıllarca sürmesi
/// bu sınırdan gelir; para yığarak bir yılda usta olunmaz.
const int kMaxMartialLessonsPerAge = 20;

MartialArt? martialArtById(String id) {
  for (final MartialArt a in MartialArt.values) {
    if (a.id == id) return a;
  }
  return null;
}

/// Bir eğitmenlik işinin hangi sanata bağlı olduğu.
MartialArt? martialArtForJob(String jobId) {
  for (final MartialArt a in MartialArt.values) {
    if (a.instructorJobId == jobId) return a;
  }
  return null;
}

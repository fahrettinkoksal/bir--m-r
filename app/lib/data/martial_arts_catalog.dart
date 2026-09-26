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
    lessonCost: 700, // prototypeOnly
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
    lessonCost: 750, // prototypeOnly
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
      MartialRank(name: '2. Duan', lessonsNeeded: 110, note: 'Yarışma düzeyi.'),
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
    lessonCost: 600, // prototypeOnly
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
  ),

  boks(
    id: 'boks',
    label: 'Boks',
    icon: Icons.sports_mma_rounded,
    description:
        'Kuşak yok; basamak ringde belli oluyor. Önce ip, sonra kum '
        'torbası, sonra karşındaki.',
    lessonCost: 650, // prototypeOnly
    minAge: 10,
    instructorFromLevel: 6,
    instructorJobId: 'boks_antrenoru',
    ranks: <MartialRank>[
      MartialRank(
        name: 'Acemi',
        lessonsNeeded: 0,
        note: 'Duruş ve nefes. Henüz eldiven bile ağır geliyor.',
      ),
      MartialRank(
        name: 'Yıldızlar',
        lessonsNeeded: 6,
        note: 'Kulübün en küçük yaş kategorisi.',
      ),
      MartialRank(
        name: 'Gençler',
        lessonsNeeded: 18,
        note: 'Kategori büyüdü, rakip de büyüdü.',
      ),
      MartialRank(
        name: 'Büyükler (amatör)',
        lessonsNeeded: 34,
        note: 'Amatör kategorinin en üst yaş grubu.',
      ),
      MartialRank(
        name: 'Bölge şampiyonu',
        lessonsNeeded: 52,
        note: 'Bölge elemelerini geçtin.',
      ),
      MartialRank(
        name: 'Türkiye şampiyonu (amatör)',
        lessonsNeeded: 76,
        note: 'Amatör kariyerin zirvesi.',
      ),
      MartialRank(
        name: 'Profesyonel',
        lessonsNeeded: 104,
        note: 'Lisans değişti; artık işin adı bu.',
      ),
      MartialRank(
        name: 'Ulusal sıralama',
        lessonsNeeded: 136,
        note: 'Adın sıralama listesine girdi.',
      ),
      MartialRank(
        name: 'Ulusal şampiyon',
        lessonsNeeded: 172,
        note: 'Kemer senin.',
      ),
    ],
  ),

  judo(
    id: 'judo',
    label: 'Judo',
    icon: Icons.sports_kabaddi_rounded,
    description:
        'Dengeyi bozmak, tutuşu bulmak, yere temiz indirmek. Kuşak '
        'kyu ve dan ile sayılır.',
    lessonCost: 620, // prototypeOnly
    minAge: 7,
    instructorFromLevel: 7,
    instructorJobId: 'judo_egitmeni',
    ranks: <MartialRank>[
      MartialRank(
        name: 'Beyaz kuşak (6. kyu)',
        lessonsNeeded: 0,
        note: 'Başlangıç. Önce düşmeyi öğreniyorsun.',
      ),
      MartialRank(
        name: 'Sarı kuşak (5. kyu)',
        lessonsNeeded: 6,
        note: 'Temel düşüş ve tutuş oturdu.',
      ),
      MartialRank(
        name: 'Turuncu kuşak (4. kyu)',
        lessonsNeeded: 16,
        note: 'İlk atışlar geliyor.',
      ),
      MartialRank(
        name: 'Yeşil kuşak (3. kyu)',
        lessonsNeeded: 30,
        note: 'Yer tekniklerine giriş.',
      ),
      MartialRank(
        name: 'Mavi kuşak (2. kyu)',
        lessonsNeeded: 48,
        note: 'Rakibin dengesini okumaya başladın.',
      ),
      MartialRank(
        name: 'Kahverengi kuşak (1. kyu)',
        lessonsNeeded: 70,
        note: 'Siyahın hemen öncesi.',
      ),
      MartialRank(
        name: 'Siyah kuşak (1. dan)',
        lessonsNeeded: 100,
        note: 'Shodan. Asıl öğrenme şimdi başlıyor.',
      ),
      MartialRank(
        name: 'Siyah kuşak (2. dan)',
        lessonsNeeded: 138,
        note: 'Nidan.',
      ),
      MartialRank(
        name: 'Siyah kuşak (3. dan)',
        lessonsNeeded: 180,
        note: 'Sandan.',
      ),
    ],
  ),

  taekwondo(
    id: 'taekwondo',
    label: 'Taekwondo',
    icon: Icons.sports_martial_arts_outlined,
    description:
        'Tekme yüksekliği, hız ve poomsae. Basamaklar gup ve dan ile '
        'sayılır.',
    lessonCost: 640, // prototypeOnly
    minAge: 7,
    instructorFromLevel: 7,
    instructorJobId: 'taekwondo_egitmeni',
    ranks: <MartialRank>[
      MartialRank(
        name: 'Beyaz kuşak (10. gup)',
        lessonsNeeded: 0,
        note: 'Masumiyet. Hiçbir şey bilmemek de bir yer.',
      ),
      MartialRank(
        name: 'Sarı kuşak (8. gup)',
        lessonsNeeded: 6,
        note: 'Toprak: kök salıyorsun.',
      ),
      MartialRank(
        name: 'Yeşil kuşak (6. gup)',
        lessonsNeeded: 16,
        note: 'Bitki: büyüme başladı.',
      ),
      MartialRank(
        name: 'Mavi kuşak (4. gup)',
        lessonsNeeded: 30,
        note: 'Gökyüzü: yukarı bakıyorsun.',
      ),
      MartialRank(
        name: 'Kırmızı kuşak (2. gup)',
        lessonsNeeded: 50,
        note: 'Tehlike: gücünü denetlemeyi öğreniyorsun.',
      ),
      MartialRank(
        name: 'Kırmızı-siyah (1. gup)',
        lessonsNeeded: 72,
        note: 'Siyaha son adım.',
      ),
      MartialRank(
        name: 'Siyah kuşak (1. dan)',
        lessonsNeeded: 102,
        note: 'İl dan. Olgunluk.',
      ),
      MartialRank(
        name: 'Siyah kuşak (2. dan)',
        lessonsNeeded: 140,
        note: 'İ dan.',
      ),
      MartialRank(
        name: 'Siyah kuşak (3. dan)',
        lessonsNeeded: 182,
        note: 'Sam dan.',
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

/// Kalıcı hobiler (Paket 39 — Issue #67, 1. kısım).
///
/// **İkinci bir aktivite sistemi değildir.** Oyuncu yine mevcut Kurslar,
/// Kütüphane ve Spor salonu eylemlerini yapar; bu katman yalnızca o
/// eylemlerin **kalıcı bir iz** bırakmasını sağlar. Hiçbir yeni düğme
/// eklenmez, hiçbir eylem bu yüzden kapanmaz.
///
/// Yalnızca **gerçekten var olan** eylemlerle beslenen hobiler listelenir;
/// uygulanmayan hobi sahte düğme yapılmaz (Issue #67).
///
/// Eşikler ve seviye adları `prototypeOnly`'dir
/// (`docs/DESIGN_REVIEW_QUEUE.md`, Q-106).
library;

import 'package:flutter/material.dart';

/// Bir hobinin ulaşabileceği basamak.
@immutable
class HobbyStage {
  const HobbyStage({
    required this.label,
    required this.experience,
    required this.memory,
  });

  final String label;

  /// prototypeOnly: bu basamağa çıkmak için gereken **toplam** deneyim.
  final int experience;

  /// Basamağa çıkıldığında hobi geçmişine yazılan anı metni.
  ///
  /// `{yas}` oyuncunun o andaki yaşıyla değiştirilir.
  final String memory;
}

/// Oyundaki kalıcı hobiler.
enum HobbyKind {
  muzik(
    id: 'muzik',
    label: 'Müzik',
    icon: Icons.music_note_rounded,
    // Müzik kursu (Paket 18) bu hobiyi besler.
    activityIds: <String>{'muzik_kursu'},
    stages: <HobbyStage>[
      HobbyStage(
        label: 'Hevesli',
        experience: 0,
        memory: '{yas} yaşında müzikle uğraşmaya başladın.',
      ),
      HobbyStage(
        label: 'Meraklı',
        experience: 4,
        memory: 'Artık kendi başına çalışıyordun.',
      ),
      HobbyStage(
        label: 'Düzenli',
        experience: 10,
        memory: 'Çalmak günlük bir alışkanlık oldu.',
      ),
      HobbyStage(
        label: 'Tutkulu',
        experience: 18,
        memory: 'Eve girer girmez önce enstrümana gidiyordun.',
      ),
      HobbyStage(
        label: 'Usta',
        experience: 28,
        memory: 'Çevrende "o müzikle uğraşır" diye biliniyordun.',
      ),
    ],
  ),

  resim(
    id: 'resim',
    label: 'Resim',
    icon: Icons.palette_rounded,
    activityIds: <String>{'resim_atolyesi'},
    stages: <HobbyStage>[
      HobbyStage(
        label: 'Hevesli',
        experience: 0,
        memory: '{yas} yaşında resim yapmaya başladın.',
      ),
      HobbyStage(
        label: 'Meraklı',
        experience: 4,
        memory: 'Defterin kenarları çizimle doldu.',
      ),
      HobbyStage(
        label: 'Düzenli',
        experience: 10,
        memory: 'Çizmek için ayrı bir köşe ayırdın.',
      ),
      HobbyStage(
        label: 'Tutkulu',
        experience: 18,
        memory: 'Gördüğün her şeyi çizmek istiyordun.',
      ),
      HobbyStage(
        label: 'Usta',
        experience: 28,
        memory: 'İnsanlar senden resim istemeye başladı.',
      ),
    ],
  ),

  okuma(
    id: 'okuma',
    label: 'Okumak',
    icon: Icons.menu_book_rounded,
    // Kütüphanede **bitirilen** her kitap bu hobiyi besler.
    activityIds: <String>{},
    stages: <HobbyStage>[
      HobbyStage(
        label: 'Hevesli',
        experience: 0,
        memory: '{yas} yaşında ilk kitabını bitirdin.',
      ),
      HobbyStage(
        label: 'Meraklı',
        experience: 3,
        memory: 'Kitaplar birikmeye başladı.',
      ),
      HobbyStage(
        label: 'Düzenli',
        experience: 7,
        memory: 'Yanında hep bir kitap taşıyordun.',
      ),
      HobbyStage(
        label: 'Tutkulu',
        experience: 12,
        memory: 'Okumak günün en iyi saatiydi.',
      ),
      HobbyStage(
        label: 'Usta',
        experience: 20,
        memory: 'Sana ne okuyacağını soranlar oldu.',
      ),
    ],
  ),

  spor(
    id: 'spor',
    label: 'Spor',
    icon: Icons.fitness_center_rounded,
    // Spor salonu eylemleri ve dövüş sanatı dersleri (Paket 32).
    activityIds: <String>{'kosu', 'agirlik', 'esneme'},
    stages: <HobbyStage>[
      HobbyStage(
        label: 'Hevesli',
        experience: 0,
        memory: '{yas} yaşında düzenli spora başladın.',
      ),
      HobbyStage(
        label: 'Meraklı',
        experience: 6,
        memory: 'Haftada birkaç gün salona gidiyordun.',
      ),
      HobbyStage(
        label: 'Düzenli',
        experience: 16,
        memory: 'Antrenman günlük düzenin parçası oldu.',
      ),
      HobbyStage(
        label: 'Tutkulu',
        experience: 30,
        memory: 'Spor yapmadığın gün eksik hissediyordun.',
      ),
      HobbyStage(
        label: 'Usta',
        experience: 48,
        memory: 'Çevrende "o sporcu" diye biliniyordun.',
      ),
    ],
  ),

  mutfak(
    id: 'mutfak',
    label: 'Mutfak',
    icon: Icons.restaurant_menu_rounded,
    activityIds: <String>{'yemek_kursu'},
    stages: <HobbyStage>[
      HobbyStage(
        label: 'Hevesli',
        experience: 0,
        memory: '{yas} yaşında mutfağa kendi isteğinle girdin.',
      ),
      HobbyStage(
        label: 'Meraklı',
        experience: 4,
        memory: 'Bir iki yemeği ezbere yapar oldun.',
      ),
      HobbyStage(
        label: 'Düzenli',
        experience: 10,
        memory: 'Evde yemek senden sorulmaya başladı.',
      ),
      HobbyStage(
        label: 'Tutkulu',
        experience: 18,
        memory: 'Tarifi kendin değiştirip daha iyisini buluyordun.',
      ),
      HobbyStage(
        label: 'Usta',
        experience: 28,
        memory: 'Misafir, senin sofran için geliyordu.',
      ),
    ],
  ),

  fotograf(
    id: 'fotograf',
    label: 'Fotoğraf',
    icon: Icons.photo_camera_rounded,
    activityIds: <String>{'fotograf_kursu'},
    stages: <HobbyStage>[
      HobbyStage(
        label: 'Hevesli',
        experience: 0,
        memory: '{yas} yaşında objektifin arkasına geçtin.',
      ),
      HobbyStage(
        label: 'Meraklı',
        experience: 4,
        memory: 'Çektiklerini ayıklamayı öğrendin.',
      ),
      HobbyStage(
        label: 'Düzenli',
        experience: 10,
        memory: 'Işığı beklemeyi huy edindin.',
      ),
      HobbyStage(
        label: 'Tutkulu',
        experience: 18,
        memory: 'Gördüğün her şeyde bir kare arıyordun.',
      ),
      HobbyStage(
        label: 'Usta',
        experience: 28,
        memory: 'İnsanlar önemli günlerini sana çektiriyordu.',
      ),
    ],
  ),

  dans(
    id: 'dans',
    label: 'Dans',
    icon: Icons.music_video_rounded,
    activityIds: <String>{'dans_kursu'},
    stages: <HobbyStage>[
      HobbyStage(
        label: 'Hevesli',
        experience: 0,
        memory: '{yas} yaşında dans etmeyi öğrenmeye başladın.',
      ),
      HobbyStage(
        label: 'Meraklı',
        experience: 4,
        memory: 'Adımları saymadan atar oldun.',
      ),
      HobbyStage(
        label: 'Düzenli',
        experience: 10,
        memory: 'Müzik başlayınca beden kendiliğinden gidiyordu.',
      ),
      HobbyStage(
        label: 'Tutkulu',
        experience: 18,
        memory: 'Düğünde önce seni sahaya çağırıyorlardı.',
      ),
      HobbyStage(
        label: 'Usta',
        experience: 28,
        memory: 'Yeni başlayanlara sen gösteriyordun.',
      ),
    ],
  ),

  satranc(
    id: 'satranc',
    label: 'Satranç',
    icon: Icons.grid_on_rounded,
    activityIds: <String>{'satranc_kulubu'},
    stages: <HobbyStage>[
      HobbyStage(
        label: 'Hevesli',
        experience: 0,
        memory: '{yas} yaşında tahtanın karşısına oturdun.',
      ),
      HobbyStage(
        label: 'Meraklı',
        experience: 4,
        memory: 'Açılışları ezberlemeye başladın.',
      ),
      HobbyStage(
        label: 'Düzenli',
        experience: 10,
        memory: 'İki hamle ötesini görmeyi öğrendin.',
      ),
      HobbyStage(
        label: 'Tutkulu',
        experience: 18,
        memory: 'Kaybettiğin oyunları gece tekrar oynuyordun.',
      ),
      HobbyStage(
        label: 'Usta',
        experience: 28,
        memory: 'Kulüpte yenmesi zor biri olmuştun.',
      ),
    ],
  ),

  yazmak(
    id: 'yazmak',
    label: 'Yazmak',
    icon: Icons.edit_note_rounded,
    activityIds: <String>{'yazarlik_atolyesi'},
    stages: <HobbyStage>[
      HobbyStage(
        label: 'Hevesli',
        experience: 0,
        memory: '{yas} yaşında yazmaya başladın.',
      ),
      HobbyStage(
        label: 'Meraklı',
        experience: 4,
        memory: 'Bir defteri sadece buna ayırdın.',
      ),
      HobbyStage(
        label: 'Düzenli',
        experience: 10,
        memory: 'Düzenli yazmak günlük bir işe dönüştü.',
      ),
      HobbyStage(
        label: 'Tutkulu',
        experience: 18,
        memory: 'Bitmemiş bir metin hep aklının bir köşesindeydi.',
      ),
      HobbyStage(
        label: 'Usta',
        experience: 28,
        memory: 'Yazdıkların okunmaya başladı.',
      ),
    ],
  ),

  bahce(
    id: 'bahce',
    label: 'Bahçe',
    icon: Icons.local_florist_rounded,
    activityIds: <String>{'bahce_atolyesi'},
    stages: <HobbyStage>[
      HobbyStage(
        label: 'Hevesli',
        experience: 0,
        memory: '{yas} yaşında toprakla uğraşmaya başladın.',
      ),
      HobbyStage(
        label: 'Meraklı',
        experience: 4,
        memory: 'İlk saksın tuttu.',
      ),
      HobbyStage(
        label: 'Düzenli',
        experience: 10,
        memory: 'Mevsimi takip etmeyi öğrendin.',
      ),
      HobbyStage(
        label: 'Tutkulu',
        experience: 18,
        memory: 'Sabahları önce onlara bakıyordun.',
      ),
      HobbyStage(
        label: 'Usta',
        experience: 28,
        memory: 'Komşular fidelerini senden alıyordu.',
      ),
    ],
  ),

  dil(
    id: 'dil',
    label: 'Yabancı dil',
    icon: Icons.translate_rounded,
    activityIds: <String>{'dil_kursu'},
    stages: <HobbyStage>[
      HobbyStage(
        label: 'Hevesli',
        experience: 0,
        memory: '{yas} yaşında yeni bir dile başladın.',
      ),
      HobbyStage(
        label: 'Meraklı',
        experience: 4,
        memory: 'İlk cümleni kurdun.',
      ),
      HobbyStage(
        label: 'Düzenli',
        experience: 10,
        memory: 'Altyazısız bir şeyler anlar oldun.',
      ),
      HobbyStage(
        label: 'Tutkulu',
        experience: 18,
        memory: 'O dilde düşündüğünü fark ettin.',
      ),
      HobbyStage(
        label: 'Usta',
        experience: 28,
        memory: 'Rahatça konuşuyordun.',
      ),
    ],
  ),

  yazilim(
    id: 'yazilim',
    label: 'Bilgisayar',
    icon: Icons.terminal_rounded,
    activityIds: <String>{'bilgisayar_kursu'},
    stages: <HobbyStage>[
      HobbyStage(
        label: 'Hevesli',
        experience: 0,
        memory: '{yas} yaşında bilgisayarla ciddi ciddi uğraşmaya başladın.',
      ),
      HobbyStage(
        label: 'Meraklı',
        experience: 4,
        memory: 'Çalışmayan şeyin sebebini bulmayı öğrendin.',
      ),
      HobbyStage(
        label: 'Düzenli',
        experience: 10,
        memory: 'Kendi küçük şeylerini yapar oldun.',
      ),
      HobbyStage(
        label: 'Tutkulu',
        experience: 18,
        memory: 'Bir sorunu çözene kadar kalkmıyordun.',
      ),
      HobbyStage(
        label: 'Usta',
        experience: 28,
        memory: 'Çevrende "ona sor" denen kişi sendin.',
      ),
    ],
  );

  const HobbyKind({
    required this.id,
    required this.label,
    required this.icon,
    required this.activityIds,
    required this.stages,
  });

  final String id;
  final String label;
  final IconData icon;

  /// Bu hobiyi besleyen aktivite kimlikleri.
  final Set<String> activityIds;

  final List<HobbyStage> stages;

  int get topStage => stages.length - 1;

  /// [experience] deneyimle hangi basamaktasın?
  int stageFor(int experience) {
    int basamak = 0;
    for (int i = 0; i < stages.length; i++) {
      if (experience >= stages[i].experience) basamak = i;
    }
    return basamak;
  }
}

HobbyKind? hobbyById(String id) {
  for (final HobbyKind h in HobbyKind.values) {
    if (h.id == id) return h;
  }
  return null;
}

/// Bu aktivite hangi hobiyi besler? Beslemiyorsa `null`.
HobbyKind? hobbyForActivity(String activityId) {
  for (final HobbyKind h in HobbyKind.values) {
    if (h.activityIds.contains(activityId)) return h;
  }
  return null;
}

/// prototypeOnly: bir hobinin "hâlâ sürüyor" sayıldığı en uzun ara.
///
/// Bundan uzun süre hiç uğraşılmayan hobi **silinmez** — geçmişte durur,
/// yalnızca "şu an ilgileniyor" sayılmaz.
const int kHobbyActiveWithinYears = 3;

/// prototypeOnly: bir hobinin olaylarda "ciddi" sayılması için gereken yıl.
const int kHobbySeriousYears = 3;

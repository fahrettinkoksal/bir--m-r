/// Arkadaş grubunun olayları (Paket CI).
///
/// **Neden var.** `docs/EKSIKLER.md` §3.1 arkadaşlığın eksiklerini
/// saymıştı; D-130 çoğunu kapattı ve o bölümün güncellemesi kalan iki
/// eksiği yazdı: **arkadaş grubu** ve çocukluk arkadaşıyla yıllar sonra
/// karşılaşma. İkincisi D-130'un zincirlerinde kodlu; grup kodda hiç
/// yoktu.
///
/// **Kurallar:**
///
/// - Her olay **süren bir grup** ister (`requiresFriendCircle`). Koşul
///   hikâye izi değil yürürlükteki kayıt: grup dağılınca olaylar
///   kesilir. İz kullanılsaydı izler silinmediği için grup dağıldıktan
///   sonra da gelirdi.
/// - Grup yeni bir mekanik getirmez: buluşma aktivite yolundan geçer
///   (Paket X/2). Bu havuz grubun **hikâyesini** anlatır.
/// - Bırakılan her iz okunur: dosyanın sonundaki üç olay kendi izlerinin
///   karşılığıdır (Paket AR'nin "sessiz iz" hatası).
/// - Argo yok, espri ağır konuda yok (`docs/WRITING_STYLE_TR.md`).
///   Gerçek marka, kurum ve kişi adı geçmez.
/// - Para gerçekten cüzdandan çıkar; tutarlar küçüktür (ECO-001).
///
/// Bütün sayılar `prototypeOnly`'dir (Q-227).
library;

import '../domain/models/game_event.dart';

/// Grubun bıraktığı hikâye izleri.
abstract final class FriendCircleFlags {
  /// Grup adına bir şey organize etti (gezi, yemek, kutlama).
  static const String organizeEtti = 'grup_organize_etti';

  /// Grubun masrafını üstlendi.
  static const String hesabiOdedi = 'grup_hesabi_odedi';

  /// Grup içindeki tartışmada taraf tutmadı.
  static const String tarafTutmadi = 'grup_taraf_tutmadi';

  // **Kapanış olaylarının izi yoktur.** İlk yazımda üç karşılık olayı
  // kendi izini de bırakıyordu (`grup_gezi_oldu` vb.) ama o izleri
  // hiçbir olay okumuyordu. Paket CI'nin bekçisi bunu yakaladı: yazılan
  // her iz okunmalı, yoksa Paket AR'nin ölçtüğü "sessiz iz" birikir.
  // Hikâye orada kapandığı için iz kaldırıldı, üçüncü bir katman
  // yazılmadı.
}

/// Arkadaş grubunun olay havuzu (Paket CI).
const List<GameEvent> kFriendCircleEvents = <GameEvent>[
  // --- Grubun gündelik hâli ---------------------------------------------
  GameEvent(
    id: 'grup_bulusma_teklifi',
    category: EventCategory.kisisel,
    text: 'Gruptan biri yazdı: "Bu cumartesi toplanıyor muyuz?" Herkes '
        'seni bekliyor gibi.',
    requirement: EventRequirement(minAge: 12, requiresFriendCircle: true),
    repeatable: true,
    minAgeGap: 4,
    weight: 4,
    choices: <EventChoice>[
      EventChoice(
        id: 'topla',
        label: 'Sen organize et',
        resultText: 'Yeri sen ayarladın, saati sen yazdın. Kalabalık '
            'tam geldi.',
        happiness: 5,
        charisma: 1,
        addFlags: <String>{FriendCircleFlags.organizeEtti},
      ),
      EventChoice(
        id: 'birakti',
        label: 'Bu sefer başkası ayarlasın',
        resultText: 'Kimse ayarlamadı. Cumartesi öyle geçti.',
        happiness: -2,
      ),
    ],
  ),
  GameEvent(
    id: 'grup_hesap_masada',
    category: EventCategory.kisisel,
    text: 'Hesap masaya geldi ve bir an kimse uzanmadı.',
    requirement: EventRequirement(minAge: 18, requiresFriendCircle: true),
    repeatable: true,
    minAgeGap: 5,
    weight: 3,
    choices: <EventChoice>[
      EventChoice(
        id: 'odedi',
        label: 'Sen öde',
        resultText: 'Sen ödedin. Kimse üstelemedi, herkes teşekkür etti.',
        money: -1400,
        happiness: 2,
        addFlags: <String>{FriendCircleFlags.hesabiOdedi},
      ),
      EventChoice(
        id: 'bolustu',
        label: 'Bölüşmeyi söyle',
        resultText: 'Hesabı böldünüz. Birkaç saniye tuhaf oldu, sonra '
            'geçti.',
        money: -350,
      ),
    ],
  ),
  GameEvent(
    id: 'grup_gruptan_biri_uzak',
    category: EventCategory.kisisel,
    text: 'Gruptan biri son aylarda hiç görünmüyor. Mesajlara kısa '
        'cevap veriyor.',
    requirement: EventRequirement(minAge: 14, requiresFriendCircle: true),
    repeatable: true,
    minAgeGap: 6,
    weight: 3,
    choices: <EventChoice>[
      EventChoice(
        id: 'ara',
        label: 'Tek başına ara',
        resultText: 'Aradın. Uzun konuşmadınız ama aradığın belli oldu.',
        happiness: 3,
      ),
      EventChoice(
        id: 'bekle',
        label: 'Kendi bilir',
        resultText: 'Beklediniz. Bir süre sonra adı grupta hiç '
            'anılmamaya başladı.',
        happiness: -2,
      ),
    ],
  ),

  // --- Grubun kırılma noktaları -----------------------------------------
  GameEvent(
    id: 'grup_ikisi_tartisti',
    category: EventCategory.kisisel,
    text: 'Grubun iki üyesi ciddi biçimde tartıştı. İkisi de ayrı ayrı '
        'seninle konuşuyor.',
    requirement: EventRequirement(minAge: 15, requiresFriendCircle: true),
    repeatable: true,
    minAgeGap: 8,
    weight: 3,
    choices: <EventChoice>[
      EventChoice(
        id: 'dinle',
        label: 'İkisini de dinle, taraf tutma',
        resultText: 'İkisini de dinledin, hiçbirine hak vermedin. '
            'Mesele zamanla soğudu.',
        happiness: 1,
        charisma: 1,
        addFlags: <String>{FriendCircleFlags.tarafTutmadi},
      ),
      EventChoice(
        id: 'tarafOl',
        label: 'Haklı bulduğunun yanında dur',
        resultText: 'Tarafını seçtin. Biri sana yakınlaştı, öteki '
            'mesafe koydu.',
        happiness: -1,
      ),
    ],
  ),
  GameEvent(
    id: 'grup_yeni_biri',
    category: EventCategory.kisisel,
    text: 'Gruptan biri yanında yeni bir arkadaş getirdi. Masa biraz '
        'kalabalık, biraz yabancı.',
    requirement: EventRequirement(minAge: 13, requiresFriendCircle: true),
    repeatable: true,
    minAgeGap: 7,
    weight: 3,
    choices: <EventChoice>[
      EventChoice(
        id: 'ac',
        label: 'Masayı aç',
        resultText: 'Yer açtınız. Birkaç buluşma sonra eskiden beri '
            'oradaymış gibi oldu.',
        happiness: 3,
        charisma: 1,
      ),
      EventChoice(
        id: 'kapali',
        label: 'Grup kalabalık olmasın',
        resultText: 'Kimse bir şey demedi ama yeni gelen bir daha '
            'gelmedi.',
        happiness: -1,
      ),
    ],
  ),
  GameEvent(
    id: 'grup_eski_fotograf',
    category: EventCategory.kisisel,
    text: 'Biri eski bir fotoğraf buldu: hepiniz varsınız ve hiçbiriniz '
        'şimdiki hâlinize benzemiyorsunuz.',
    requirement: EventRequirement(minAge: 25, requiresFriendCircle: true),
    repeatable: true,
    minAgeGap: 12,
    weight: 3,
    choices: <EventChoice>[
      EventChoice(
        id: 'konus',
        label: 'O günleri konuş',
        resultText: 'Akşam o fotoğrafla geçti. Kimse telefona bakmadı.',
        happiness: 6,
      ),
      EventChoice(
        id: 'gecti',
        label: 'Geçmişte kalsın',
        resultText: 'Fotoğrafa kısa baktın, konuyu değiştirdin.',
        happiness: 1,
      ),
    ],
  ),

  // --- Karşılıklar: bırakılan izler okunur ------------------------------
  GameEvent(
    id: 'grup_karsilik_gezi',
    category: EventCategory.kisisel,
    text: 'Organize ettiğin buluşmalar bir alışkanlığa döndü; grup bu '
        'yıl birlikte kısa bir yola çıkmayı konuşuyor.',
    requirement: EventRequirement(
      minAge: 20,
      requiresFriendCircle: true,
      requiredFlags: <String>{FriendCircleFlags.organizeEtti},
    ),
    weight: 3,
    choices: <EventChoice>[
      EventChoice(
        id: 'cikti',
        label: 'Yola çıkın',
        resultText: 'İki gün, tek araba, çok fazla fotoğraf. Masrafı '
            'bölüştünüz.',
        money: -4200,
        happiness: 8,
      ),
      EventChoice(
        id: 'ertelendi',
        label: 'Bu yıl olmaz',
        resultText: 'Ertelendi. Herkesin bir işi çıktı ve konu kapandı.',
        happiness: -1,
      ),
    ],
  ),
  GameEvent(
    id: 'grup_karsilik_hesap',
    category: EventCategory.kisisel,
    text: 'Yıllardır hesabı sen ödüyorsun. Bu kez biri seni durdurdu: '
        '"Bugün olmaz."',
    requirement: EventRequirement(
      minAge: 22,
      requiresFriendCircle: true,
      requiredFlags: <String>{FriendCircleFlags.hesabiOdedi},
    ),
    weight: 3,
    choices: <EventChoice>[
      EventChoice(
        id: 'kabul',
        label: 'Bırak ödesin',
        resultText: 'Bıraktın. Masada kimse bunu büyütmedi ama sen '
            'fark ettin.',
        happiness: 5,
      ),
      EventChoice(
        id: 'israr',
        label: 'Yine sen öde',
        resultText: 'Yine sen ödedin. Bu sefer biri hafifçe güldü.',
        money: -1400,
        happiness: 1,
      ),
    ],
  ),
  GameEvent(
    id: 'grup_karsilik_arada',
    category: EventCategory.kisisel,
    text: 'O tartışmadan sonra ikisi de hâlâ seninle konuşuyor, '
        'birbirleriyle konuşmuyor. Arada kalan sensin.',
    requirement: EventRequirement(
      minAge: 18,
      requiresFriendCircle: true,
      requiredFlags: <String>{FriendCircleFlags.tarafTutmadi},
    ),
    weight: 3,
    choices: <EventChoice>[
      EventChoice(
        id: 'masaya',
        label: 'İkisini aynı masaya oturt',
        resultText: 'Aynı masaya oturdular. İlk yarım saat ağır geçti, '
            'sonrası eskisi gibi oldu.',
        happiness: 6,
        charisma: 1,
      ),
      EventChoice(
        id: 'ayri',
        label: 'Ayrı ayrı görüş',
        resultText: 'Herkesi ayrı gördün. Grup iki masaya bölündü ve '
            'öyle kaldı.',
        happiness: -3,
      ),
    ],
  ),
];

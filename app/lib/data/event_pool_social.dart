/// Ün ve sosyal medya olayları (Paket 10).
///
/// Hepsi gerçek bir kitle oluştuktan sonra çıkar: hesabı olmayan ya da
/// Ünü açılmamış oyuncu bu olayları görmez (D-027). Tanışma olaylarında
/// **kişi yalnızca tanışma gerçekten olursa** üretilir; her tanışma
/// romantik teklif değildir.
library;

import '../domain/models/game_event.dart';

/// Sosyal medya hikâye izleri.
abstract final class SocialFlags {
  static const String toplulukKurdu = 'sosyal_topluluk_kurdu';
  static const String etkinligeGitti = 'sosyal_etkinlige_gitti';
  static const String yorumlariKapatti = 'sosyal_yorumlari_kapatti';
}

const List<GameEvent> kSocialFameEvents = <GameEvent>[
  // 1 — Tanışma fırsatı: kişi yalnızca kabul edilirse oluşur.
  GameEvent(
    id: 'un_tanisma',
    category: EventCategory.kisisel,
    text:
        'Paylaşımlarını takip eden biri mesaj attı: aynı şehirdeymişsiniz, '
        'bir kahve içmeyi teklif ediyor.',
    requirement: EventRequirement(
      minAge: 16,
      requiresSocialAccount: true,
      minFame: 3,
    ),
    repeatable: true,
    minAgeGap: 5,
    weight: 4,
    choices: <EventChoice>[
      EventChoice(
        id: 'bulus',
        label: 'Buluş',
        resultText:
            'Kahve uzun sürdü. İnternette tanıdığın biri, artık '
            'gerçekten tanıdığın biri.',
        happiness: 4,
        charisma: 2,
        startsFriendship: true,
      ),
      EventChoice(
        id: 'kibarca_reddet',
        label: 'Kibarca reddet',
        resultText:
            'Teşekkür edip kapattın. Herkesle tanışmak zorunda '
            'değilsin.',
        happiness: 1,
      ),
    ],
  ),

  // 2 — Etkinlik daveti
  GameEvent(
    id: 'un_etkinlik_daveti',
    category: EventCategory.kisisel,
    text:
        'Küçük bir etkinliğe davet edildin: içerik üreten birkaç kişi '
        'bir araya geliyor, senin de gelmeni istiyorlar.',
    requirement: EventRequirement(
      minAge: 16,
      requiresSocialAccount: true,
      minFame: 5,
    ),
    repeatable: true,
    minAgeGap: 6,
    weight: 4,
    choices: <EventChoice>[
      EventChoice(
        id: 'git',
        label: 'Git',
        resultText:
            'Salon küçüktü, kalabalık samimiydi. Birkaç isim '
            'aklında kaldı; onların da senin adın.',
        happiness: 5,
        charisma: 3,
        addFlags: <String>{SocialFlags.etkinligeGitti},
      ),
      EventChoice(
        id: 'gitme',
        label: 'Gitme',
        resultText: 'Evde kaldın. Telefon sessizdi ve bu da iyi geldi.',
        happiness: 2,
      ),
    ],
  ),

  // 3 — İş daveti (ün üzerinden)
  GameEvent(
    id: 'un_is_daveti',
    category: EventCategory.kisisel,
    text:
        'Bir yerden ulaştılar: içerik işinden anladığın için küçük bir '
        'proje teklif ediyorlar. Büyük bir şey değil ama ciddi.',
    requirement: EventRequirement(
      minAge: 18,
      requiresSocialAccount: true,
      minFame: 8,
    ),
    repeatable: true,
    minAgeGap: 8,
    weight: 3,
    choices: <EventChoice>[
      EventChoice(
        id: 'kabul',
        label: 'Kabul et',
        resultText:
            'Birkaç hafta uğraştın, teslim ettin. Ödeme beklediğin '
            'kadar değildi ama zamanında geldi.',
        happiness: 3,
        money: 55000,
        intelligence: 1,
      ),
      EventChoice(
        id: 'vakit_yok',
        label: '"Şu an vaktim yok"',
        resultText: 'Reddettin. Teklifin kendisi bile bir şey anlatıyordu.',
        happiness: 1,
      ),
    ],
  ),

  // 4 — Kitleyle ilişki: yorumlar
  GameEvent(
    id: 'un_yorumlar',
    category: EventCategory.kisisel,
    text:
        'Son paylaşımının altı karıştı. Birkaç kişi ağır konuşuyor, '
        'birkaç kişi seni savunuyor.',
    requirement: EventRequirement(
      minAge: 16,
      requiresSocialAccount: true,
      minFame: 4,
    ),
    repeatable: true,
    minAgeGap: 4,
    weight: 4,
    choices: <EventChoice>[
      EventChoice(
        id: 'cevap_verme',
        label: 'Cevap verme',
        resultText:
            'Telefonu kapattın. Ertesi sabah kimse o tartışmayı '
            'hatırlamıyordu.',
        happiness: 1,
      ),
      EventChoice(
        id: 'kapat',
        label: 'Yorumları kapat',
        resultText:
            'Kapattın. Sessizlik iyi geldi ama bir şeyler de '
            'eksildi.',
        happiness: -1,
        addFlags: <String>{SocialFlags.yorumlariKapatti},
      ),
      EventChoice(
        id: 'acikla',
        label: 'Kısa bir açıklama yaz',
        resultText:
            'Açıkladın. Bir kısmı anladı, bir kısmı anlamadı; '
            'ikisi de olacaktı.',
        happiness: 2,
        charisma: 2,
      ),
    ],
  ),
];

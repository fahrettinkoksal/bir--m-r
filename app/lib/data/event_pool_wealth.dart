/// Servetin hayata dokunduğu olaylar (Paket AD, §12-§17).
///
/// **Neden var.** Denetimde ortaya çıktı: oyundaki en pahalı şey
/// ₺16.000.000'luk villaydı, oysa altmış yıl yatırım yapan oyuncunun
/// portföyü ₺30.000.000'u aşıyor. Paranın harcanacak yeri olmayınca
/// "her şeyi yatır" doğal olarak tek akıllı strateji oluyor. §13 bunu
/// açıkça söyledi: sorunu **getiriyi düşürerek değil, paraya anlam
/// vererek** çöz.
///
/// Buradaki olaylar üç iş yapıyor:
///
/// 1. **Servet hayat kalitesine dönüşüyor** (§13): belirli seviyelerde
///    uzun tatil, özel etkinlik, bağış gibi yollar açılıyor.
/// 2. **Aile para istiyor** (§15): ver/verme kararı ve ilişki sonucu.
/// 3. **Zenginin hayatı farklı hissettiriyor** (§17): aynı yaşta,
///    servete göre farklı olaylar çıkıyor.
///
/// **Yapay zengin vergisi yok** (§14): hiçbir olay "zenginsin diye" para
/// silmiyor. Para yalnızca oyuncunun **seçtiği** yerde gidiyor; tek
/// istisna sağlık (§16) ve o da nadir.
///
/// Metin üslubu `docs/WRITING_STYLE_TR.md`. Tutarlar `prototypeOnly`
/// (Q-173).
library;

import '../domain/models/game_event.dart';
import '../domain/models/relation.dart';

const List<GameEvent> kWealthEvents = <GameEvent>[
  // =====================================================================
  // §15 — Aileye para
  // =====================================================================
  GameEvent(
    id: 'ad_aile_borc_ister',
    category: EventCategory.aile,
    text: '{kisi} aradı. Uzun uzun hâl hatır sordu, sonra asıl konuya '
        'geldi.\n\nAcil bir işi çıkmış. Sen de durumun iyi olduğunu '
        'biliyor.',
    requirement: EventRequirement(
      minAge: 25,
      minNetWorth: 2000000,
      livingRelations: <RelationType>{
        RelationType.kardes,
        RelationType.anne,
        RelationType.baba,
      },
      requireReachable: true,
    ),
    repeatable: true,
    minAgeGap: 6,
    weight: 6,
    choices: <EventChoice>[
      EventChoice(
        id: 'ver',
        label: 'Ver, hesabını sorma',
        resultText: 'Gönderdin. Ne zaman geri geleceğini konuşmadınız; '
            'ikiniz de konuşmamayı seçtiniz.',
        money: -120000,
        bond: 8,
        happiness: 2,
      ),
      EventChoice(
        id: 'kismi',
        label: 'Bir kısmını ver',
        resultText: 'Elinden geleni yaptığını söyledin. Teşekkür etti; '
            'sesinde biraz kırgınlık var mıydı, emin olamadın.',
        money: -40000,
        bond: 2,
      ),
      EventChoice(
        id: 'verme',
        label: 'Bu sefer verme',
        resultText: 'Açıkça hayır dedin. Anlayışla karşıladı — en azından '
            'öyle dedi.',
        bond: -10,
        happiness: -3,
      ),
    ],
  ),
  GameEvent(
    id: 'ad_cocuk_egitim_destek',
    category: EventCategory.aile,
    text: '{kisi} bir programa girmek istiyor. Ücreti ciddi.\n\n'
        '"Zorlarsam kendim de öderim" diyor ama gözü sende.',
    requirement: EventRequirement(
      minAge: 40,
      minNetWorth: 3000000,
      livingRelations: <RelationType>{RelationType.cocuk},
      requireReachable: true,
    ),
    repeatable: true,
    minAgeGap: 8,
    weight: 5,
    choices: <EventChoice>[
      EventChoice(
        id: 'karsila',
        label: 'Tamamını karşıla',
        resultText: 'Ödedin. "Sana bunu ödeyeceğim" dedi; ödemesini '
            'beklemiyorsun.',
        money: -450000,
        bond: 12,
        happiness: 4,
      ),
      EventChoice(
        id: 'yarisi',
        label: 'Yarısını karşıla',
        resultText: 'Yarısını sen, yarısını o. Böylesi daha iyi olur '
            'dedin; belki de haklıydın.',
        money: -225000,
        bond: 5,
        happiness: 1,
      ),
      EventChoice(
        id: 'kendi',
        label: 'Kendi yolunu bulsun',
        resultText: 'Kendi ayakları üstünde dursun istedin. Kırıldı ama '
            'bir şey demedi.',
        bond: -8,
        happiness: -2,
      ),
    ],
  ),

  // =====================================================================
  // §13, §17 — Servet hayat kalitesine dönüşüyor
  // =====================================================================
  GameEvent(
    id: 'ad_uzun_tatil',
    category: EventCategory.kisisel,
    text: 'Takvime baktın: yıllardır üç günden uzun izin yapmamışsın.'
        '\n\nParan var. Vaktin de var mı, orası tartışmalı.',
    requirement: EventRequirement(
      minAge: 30,
      minNetWorth: 5000000,
    ),
    repeatable: true,
    minAgeGap: 7,
    weight: 5,
    choices: <EventChoice>[
      EventChoice(
        id: 'uzun',
        label: 'Bir ay git',
        resultText: 'Bir ay. İlk hafta huzursuzdun, sonra alıştın. '
            'Döndüğünde dünya aynı yerdeydi.',
        money: -380000,
        happiness: 12,
        health: 4,
      ),
      EventChoice(
        id: 'kisa',
        label: 'On gün yeter',
        resultText: 'On gün gittin, dinlendin, döndün. Fena değildi.',
        money: -120000,
        happiness: 6,
        health: 2,
      ),
      EventChoice(
        id: 'gitme',
        label: 'Gitme, iş birikir',
        resultText: 'Gitmedin. İş birikmedi; sen birazcık biriktin.',
        happiness: -3,
      ),
    ],
  ),
  GameEvent(
    id: 'ad_ozel_etkinlik',
    category: EventCategory.yetiskinlik,
    text: 'Bir davet geldi. Kalabalık küçük, liste seçili.\n\n'
        'Katılım ücretsiz değil ve bunu kimse yüksek sesle söylemiyor.',
    requirement: EventRequirement(
      minAge: 30,
      minNetWorth: 20000000,
    ),
    repeatable: true,
    minAgeGap: 9,
    weight: 4,
    choices: <EventChoice>[
      EventChoice(
        id: 'git',
        label: 'Katıl',
        resultText: 'Gittin. Üç kişiyle tanıştın, ikisini bir daha '
            'görmeyeceksin, biri yıllarca hayatında kalacak.',
        money: -250000,
        happiness: 5,
        charisma: 3,
      ),
      EventChoice(
        id: 'gitme',
        label: 'Bu tür şeylere girme',
        resultText: 'Gitmedin. O akşam evde oturdun ve iyi ki dedin — '
            'birkaç kez.',
        happiness: -1,
      ),
    ],
  ),
  GameEvent(
    id: 'ad_bagis',
    category: EventCategory.yetiskinlik,
    text: 'Bir dernek yazmış. Uzun bir mektup, abartısız bir dil.'
        '\n\nParanın bir kısmının nereye gittiğini seçebilirsin.',
    requirement: EventRequirement(
      minAge: 30,
      minNetWorth: 10000000,
    ),
    repeatable: true,
    minAgeGap: 6,
    weight: 5,
    choices: <EventChoice>[
      EventChoice(
        id: 'buyuk',
        label: 'Ciddi bir bağış yap',
        resultText: 'Yaptın. Adını yazdırmak istemedin; kimse bilmeyecek, '
            'sen bileceksin.',
        money: -900000,
        happiness: 9,
      ),
      EventChoice(
        id: 'kucuk',
        label: 'Küçük bir katkı',
        resultText: 'Bir miktar gönderdin. Az da olsa bir şey.',
        money: -60000,
        happiness: 3,
      ),
      EventChoice(
        id: 'yok',
        label: 'Şimdi değil',
        resultText: 'Mektubu bir kenara koydun. Bir daha açmadın. Arada '
            'aklına geliyor.',
        happiness: -2,
      ),
    ],
  ),

  // =====================================================================
  // §16 — Sağlık harcaması: NADİR ve anlamlı
  //
  // "Her yaşlı oyuncu sürekli servet eritmesin" kuralı gereği ağırlık
  // düşük ve tekrar aralığı geniş. Parası olmayan oyuncuda da çıkabilir
  // ama tutar servete göre değil, **sabit**: yapay zengin vergisi yok.
  // =====================================================================
  GameEvent(
    id: 'ad_saglik_masrafi',
    category: EventCategory.kisisel,
    text: 'Doktor, "bu iş bekler ama beklemese daha iyi" dedi.\n\n'
        'Sırada beklemek de var, özelde hemen olmak da. İkisinin arası '
        'para.',
    requirement: EventRequirement(
      minAge: 55,
    ),
    repeatable: true,
    minAgeGap: 12,
    weight: 3,
    choices: <EventChoice>[
      EventChoice(
        id: 'hemen',
        label: 'Hemen hallet',
        resultText: 'Hallettin. Pahalıydı ama uyku düzenin geri geldi.',
        money: -320000,
        health: 8,
        happiness: 3,
      ),
      EventChoice(
        id: 'sirada',
        label: 'Sırada bekle',
        resultText: 'Sıraya yazıldın. Birkaç ay sürecek; o birkaç ay '
            'boyunca aklının bir köşesinde duracak.',
        health: -3,
        happiness: -4,
      ),
    ],
  ),
];

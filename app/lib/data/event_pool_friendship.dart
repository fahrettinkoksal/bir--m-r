/// Arkadaşlık olayları (D-130).
///
/// **Ölçülen sorun:** arkadaşlık oyunda vardı ama yaşanmıyordu —
/// hayatların 34/60'ında hiç arkadaş yoktu ve hiçbir hayat yakın
/// arkadaşla bitmiyordu. Bu havuz arkadaşlığa **kendi olayları** verir:
/// çocukluk arkadaşı yıllar sonra döner, arkadaş zor günde yardım ister,
/// arkadaşlık bozulur ve bazen düzelir.
///
/// Dil: `docs/WRITING_STYLE_TR.md`. Arkadaş dili rahat ve samimi (§5,
/// §14); ciddi konularda espri yok (§7).
library;

import '../domain/economy/financial_strain.dart';
import '../domain/models/game_event.dart';
import '../domain/models/relation.dart';
import 'event_pool_childhood.dart';

/// Bu havuzun bıraktığı izler.
abstract final class FriendFlags {
  static const String cocuklukArkadasiDondu = 'arkadas_cocukluk_dondu';
  static const String arkadasaYardimEtti = 'arkadas_zor_gunde_yaninda';
  static const String arkadasiReddetti = 'arkadas_zor_gunde_yokti';
  static const String kirgin = 'arkadas_kirgin';
  static const String barisildi = 'arkadas_barisildi';
  static const String arkadasSirriniTuttu = 'arkadas_sirri_tuttu';
}

/// Arkadaşlık olayları.
const List<GameEvent> kFriendshipEvents = <GameEvent>[
  // ===================================================================
  // ÇOCUKLUK ARKADAŞI YILLAR SONRA (3 halka)
  //
  // D-126'da çocukluk arkadaşı gerçek bir Person olarak kaydedildi ama
  // hiç geri dönmüyordu. Artık dönüyor.
  // ===================================================================
  GameEvent(
    id: 'arkadas_cocukluk_geri_dondu',
    category: EventCategory.kisisel,
    text: 'Telefonda tanımadığın bir numara. Açtın, ses tanıdık '
        'çıktı.\n\n'
        '"Bilemedin değil mi? Ben ya, {kisi}."',
    requirement: EventRequirement(
      minAge: 22,
      personRole: ChildhoodRoles.cocuklukArkadasi,
      forbiddenFlags: <String>{FriendFlags.cocuklukArkadasiDondu},
    ),
    weight: 8,
    choices: <EventChoice>[
      EventChoice(
        id: 'bulus',
        label: 'Buluşalım',
        resultText: 'Aynı kafede iki saat oturdunuz. Yüzü değişmiş, '
            'gülüşü aynı kalmış.',
        happiness: 5,
        charisma: 2,
        bond: 20,
        addFlags: <String>{FriendFlags.cocuklukArkadasiDondu},
      ),
      EventChoice(
        id: 'sonra',
        label: '"Bir ara görüşürüz"',
        resultText: 'O cümlenin ne demek olduğunu ikiniz de biliyorsunuz. '
            'Bir daha aramadı.',
        happiness: -2,
        bond: -5,
        addFlags: <String>{FriendFlags.cocuklukArkadasiDondu},
      ),
    ],
  ),
  GameEvent(
    id: 'arkadas_cocukluk_mahalle',
    category: EventCategory.mahalle,
    text: '{kisi} ile eski mahalleye gittiniz. Sokak daralmış, '
        'apartman yükselmiş.\n\n'
        'Top oynadığınız yer şimdi otopark.',
    requirement: EventRequirement(
      minAge: 25,
      personRole: ChildhoodRoles.cocuklukArkadasi,
      requiredFlags: <String>{FriendFlags.cocuklukArkadasiDondu},
    ),
    weight: 6,
    choices: <EventChoice>[
      EventChoice(
        id: 'fotograf',
        label: 'Fotoğraf çektir',
        resultText: 'Aynı duvarın önünde durdunuz. Eski fotoğrafla '
            'yan yana koyunca ikiniz de sustunuz.',
        happiness: 6,
        bond: 8,
      ),
      EventChoice(
        id: 'yurudu',
        label: 'Konuşmadan yürü',
        resultText: 'Sokağın sonuna kadar yürüdünüz. Kimse bir şey '
            'söylemedi, gerek de yoktu.',
        happiness: 4,
        bond: 5,
      ),
    ],
  ),
  GameEvent(
    id: 'arkadas_cocukluk_kiyas',
    category: EventCategory.kisisel,
    text: '{kisi} kendi hayatını anlattı. Bazı yerlerde senden '
        'ileride, bazı yerlerde geride.\n\n'
        'İçinden bir kıyas geçti, farkında mısın?',
    requirement: EventRequirement(
      minAge: 30,
      personRole: ChildhoodRoles.cocuklukArkadasi,
      requiredFlags: <String>{FriendFlags.cocuklukArkadasiDondu},
    ),
    weight: 5,
    choices: <EventChoice>[
      EventChoice(
        id: 'sevin',
        label: 'Onun için sevin',
        resultText: '"İyi olmuş sana" dedin, ciddiydin. Söylerken '
            'kendine de iyi geldi.',
        happiness: 4,
        charisma: 2,
        bond: 6,
      ),
      EventChoice(
        id: 'kiyas',
        label: 'Kendini kıyasla',
        resultText: 'Gece yatakta hesap yaptın. Kimse kazanmadı '
            'o hesaptan.',
        happiness: -3,
        intelligence: 1,
      ),
    ],
  ),

  // ===================================================================
  // ZOR GÜN (2 halka)
  // ===================================================================
  GameEvent(
    id: 'arkadas_zor_gun',
    category: EventCategory.kisisel,
    text: '{kisi} aradı, sesi çok değişik. "Müsait misin" dedi.\n\n'
        'Bu soruyu böyle soran biri müsaitlik sormuyor.',
    requirement: EventRequirement(
      minAge: 18,
      livingRelations: <RelationType>{RelationType.arkadas},
      requireReachable: true,
      forbiddenFlags: <String>{
        FriendFlags.arkadasaYardimEtti,
        FriendFlags.arkadasiReddetti,
      },
    ),
    weight: 7,
    choices: <EventChoice>[
      EventChoice(
        id: 'git',
        label: 'Hemen git',
        resultText: 'Gittin. Bir şey çözmedin, yanında durdun. '
            'Bazen yeterli olan o.',
        happiness: 3,
        charisma: 3,
        bond: 18,
        addFlags: <String>{FriendFlags.arkadasaYardimEtti},
      ),
      EventChoice(
        id: 'dinle',
        label: 'Telefonda dinle',
        resultText: 'Bir saat dinledin. Kapatırken "iyi geldi" dedi.',
        happiness: 2,
        bond: 9,
        addFlags: <String>{FriendFlags.arkadasaYardimEtti},
      ),
      EventChoice(
        id: 'sonra_ara',
        label: '"Şimdi olmaz, sonra"',
        resultText: 'Sonra aramadın. O da bir daha aramadı.',
        happiness: -3,
        bond: -20,
        addFlags: <String>{FriendFlags.arkadasiReddetti},
      ),
    ],
  ),
  GameEvent(
    id: 'arkadas_borcunu_odedi',
    category: EventCategory.kisisel,
    text: 'Senin zor günün. Kimseye söylemedin ama {kisi} '
        'bir yerden duymuş.\n\nKapıda.',
    requirement: EventRequirement(
      minAge: 20,
      livingRelations: <RelationType>{RelationType.arkadas},
      requiredFlags: <String>{FriendFlags.arkadasaYardimEtti},
    ),
    weight: 7,
    choices: <EventChoice>[
      EventChoice(
        id: 'ic',
        label: 'İçeri al',
        resultText: 'Konuşmadan oturdunuz. Giderken "ben varım" dedi, '
            'başka bir şey demedi.',
        happiness: 7,
        health: 2,
        bond: 12,
      ),
      EventChoice(
        id: 'idare',
        label: '"Halledeceğim"',
        resultText: 'Kapıda konuştunuz. Gitti ama ertesi gün yine '
            'geldi. Üçüncüsünde içeri aldın.',
        happiness: 3,
        bond: 6,
      ),
    ],
  ),

  // ===================================================================
  // KÜSLÜK VE BARIŞMA (3 halka)
  // ===================================================================
  GameEvent(
    id: 'arkadas_kirginlik',
    category: EventCategory.kisisel,
    text: '{kisi} bir şeye alınmış. Yüz yüze söylemiyor, '
        'ortak tanıdıklardan duyuyorsun.',
    requirement: EventRequirement(
      minAge: 15,
      livingRelations: <RelationType>{RelationType.arkadas},
      forbiddenFlags: <String>{FriendFlags.kirgin},
    ),
    weight: 6,
    choices: <EventChoice>[
      EventChoice(
        id: 'sor',
        label: 'Doğrudan sor',
        resultText: '"Bir şey mi oldu?" dedin. İlk "yok" dedi, '
            'sonra anlattı. Küçük bir şeymiş.',
        happiness: 2,
        charisma: 3,
        bond: 8,
      ),
      EventChoice(
        id: 'bekle',
        label: 'Kendi gelsin',
        resultText: 'Bekledin. O da bekledi. İkiniz de '
            'beklemekte iyisiniz.',
        happiness: -2,
        bond: -12,
        addFlags: <String>{FriendFlags.kirgin},
      ),
    ],
  ),
  GameEvent(
    id: 'arkadas_kavga',
    category: EventCategory.kisisel,
    text: 'Söz söze eklendi, {kisi} ile sesiniz yükseldi. '
        'İkiniz de söylememesi gereken bir şey söylediniz.',
    requirement: EventRequirement(
      minAge: 15,
      livingRelations: <RelationType>{RelationType.arkadas},
      requiredFlags: <String>{FriendFlags.kirgin},
      forbiddenFlags: <String>{FriendFlags.barisildi},
    ),
    weight: 7,
    choices: <EventChoice>[
      EventChoice(
        id: 'ozur',
        label: 'Önce sen özür dile',
        resultText: 'Ertesi gün aradın. "Ben de haddimi aştım" dedi. '
            'Konu kapandı, tam kapanmadı.',
        happiness: 3,
        charisma: 2,
        bond: 14,
        addFlags: <String>{FriendFlags.barisildi},
      ),
      EventChoice(
        id: 'bekle',
        label: 'Bu sefer o arasın',
        resultText: 'Aramadı. Sen de aramadın. Aylar geçti.',
        happiness: -4,
        bond: -22,
      ),
    ],
  ),
  GameEvent(
    id: 'arkadas_yillar_sonra_baris',
    category: EventCategory.kisisel,
    text: 'Bir cenazede karşılaştınız. {kisi} yanına geldi, '
        'omzuna dokundu.\n\nKavganın konusu neydi, ikiniz de '
        'hatırlamıyorsunuz.',
    requirement: EventRequirement(
      minAge: 30,
      livingRelations: <RelationType>{RelationType.arkadas},
      requiredFlags: <String>{FriendFlags.kirgin},
      forbiddenFlags: <String>{FriendFlags.barisildi},
    ),
    weight: 6,
    choices: <EventChoice>[
      EventChoice(
        id: 'baris',
        label: 'Sarıl',
        resultText: 'Sarıldınız. Kaybedilen yıllar geri gelmiyor '
            'ama kalanı var.',
        happiness: 6,
        bond: 25,
        addFlags: <String>{FriendFlags.barisildi},
      ),
      EventChoice(
        id: 'basini_salla',
        label: 'Başını salla, geç',
        resultText: 'Başını sallayıp geçtin. Arabaya binerken '
            'içinden bir şey koptu.',
        happiness: -3,
      ),
    ],
  ),

  // ===================================================================
  // TEKİL OLAYLAR
  // ===================================================================
  GameEvent(
    id: 'arkadas_sir',
    category: EventCategory.kisisel,
    text: '{kisi} sana bir şey anlattı, sonra "kimseye söyleme" '
        'dedi.\n\nErtesi gün biri sana o konuyu sordu.',
    requirement: EventRequirement(
      minAge: 14,
      livingRelations: <RelationType>{RelationType.arkadas},
      forbiddenFlags: <String>{FriendFlags.arkadasSirriniTuttu},
    ),
    weight: 6,
    choices: <EventChoice>[
      EventChoice(
        id: 'tut',
        label: 'Bilmiyorum de',
        resultText: '"Haberim yok" dedin. {kisi} sonradan öğrendi, '
            'hiçbir şey demedi ama gözleri değişti.',
        happiness: 2,
        charisma: 3,
        bond: 12,
        addFlags: <String>{FriendFlags.arkadasSirriniTuttu},
      ),
      EventChoice(
        id: 'anlat',
        label: 'Anlat',
        resultText: 'Anlattın. Üç gün sonra bütün ortam biliyordu. '
            'Kimin söylediği de belliydi.',
        happiness: -3,
        charisma: -2,
        bond: -25,
        addFlags: <String>{FriendFlags.kirgin},
      ),
    ],
  ),
  GameEvent(
    id: 'arkadas_dugun_cagri',
    category: EventCategory.kisisel,
    text: '{kisi} evleniyor. Davetiye elden geldi ve bir şey '
        'daha sordu:\n\n"Sağdıcım olur musun?"',
    requirement: EventRequirement(
      minAge: 20,
      maxAge: 45,
      livingRelations: <RelationType>{RelationType.arkadas},
      personMinAge: 20,
    ),
    weight: 5,
    choices: <EventChoice>[
      EventChoice(
        id: 'olur',
        label: '"Olur"',
        resultText: 'Bütün gün ayaktaydın, takı takarken elin titredi. '
            'İyi bir gündü.',
        happiness: 6,
        charisma: 3,
        bond: 15,
        money: -8000,
      ),
      EventChoice(
        id: 'sadece_git',
        label: 'Sadece düğüne git',
        resultText: 'Gittin, oturdun, takını taktın. '
            'Yeterliydi ama tam da değildi.',
        happiness: 3,
        bond: 4,
        money: -3000,
      ),
    ],
  ),
  GameEvent(
    id: 'arkadas_tanistirma',
    category: EventCategory.kisisel,
    text: '{kisi} kendi arkadaş grubuna çağırdı. Kimseyi '
        'tanımıyorsun.\n\nKapıda bir an durdun.',
    requirement: EventRequirement(
      minAge: 16,
      livingRelations: <RelationType>{RelationType.arkadas},
    ),
    weight: 5,
    choices: <EventChoice>[
      EventChoice(
        id: 'gir',
        label: 'Gir, tanış',
        resultText: 'Yarım saat sonra bir masada gülüyordun. '
            'İçlerinden biriyle numara da değiştirdin.',
        happiness: 4,
        charisma: 4,
        bond: 6,
        startsFriendship: true,
      ),
      EventChoice(
        id: 'kenarda',
        label: 'Kenarda dur',
        resultText: 'Akşam boyunca telefonuna baktın. '
            '{kisi} arada gelip bir şey sordu, o kadar.',
        happiness: -1,
        bond: 1,
      ),
    ],
  ),
  GameEvent(
    id: 'arkadas_uzaktan',
    category: EventCategory.kisisel,
    text: '{kisi} başka şehirde. Aramalar seyrekleşti, '
        'mesajlar kısaldı.\n\nBugün bir fotoğraf attı: eski bir '
        'fotoğraf.',
    requirement: EventRequirement(
      minAge: 20,
      livingRelations: <RelationType>{RelationType.arkadas},
      requireOutsideHousehold: true,
    ),
    weight: 5,
    choices: <EventChoice>[
      EventChoice(
        id: 'ara',
        label: 'Hemen ara',
        resultText: 'İki saat konuştunuz. Kapattıktan sonra '
            'ikiniz de uzun uzun güldüğünüzü fark ettiniz.',
        happiness: 5,
        bond: 12,
      ),
      EventChoice(
        id: 'kalp',
        label: 'Kalp at, geç',
        resultText: 'Kalp attın. Yeter mi? Bazen yeter, '
            'bu sefer yetmedi.',
        happiness: -1,
        bond: -3,
      ),
    ],
  ),
  GameEvent(
    id: 'arkadas_para_istedi',
    category: EventCategory.kisisel,
    text: '{kisi} uzun uzun konuştu, sonunda geldi konuya: '
        'para lazım.\n\nMiktarı söylerken sesi kısıldı.',
    requirement: EventRequirement(
      minAge: 20,
      livingRelations: <RelationType>{RelationType.arkadas},
      minComfort: FinancialComfort.idare,
    ),
    weight: 5,
    choices: <EventChoice>[
      EventChoice(
        id: 'ver',
        label: 'Ver',
        resultText: 'Verdin. Ne zaman ödeyeceğini sormadın, '
            'o da söylemedi.',
        happiness: 1,
        money: -25000,
        bond: 12,
      ),
      EventChoice(
        id: 'yarisini',
        label: 'Yarısını ver',
        resultText: '"Bu kadarı var" dedin. Aldı, teşekkür etti. '
            'İkiniz de rahatladınız.',
        happiness: 2,
        money: -12000,
        charisma: 1,
        bond: 7,
      ),
      EventChoice(
        id: 'veremem',
        label: 'Veremeyeceğini söyle',
        resultText: 'Dürüst oldun. Anladı, ama arada bir şey kaldı.',
        happiness: -2,
        bond: -8,
      ),
    ],
  ),
];

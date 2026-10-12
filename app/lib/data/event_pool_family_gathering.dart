/// Aile buluşmaları ve aile içi haberler (Paket AO, §30, §31, §33).
///
/// Paket AO'nun ana tasarım kuralı şuydu: **aile menüsü bir NPC listesi
/// olmasın, insanların kendi hayatı olsun — ama hiçbir kişi yalnızca
/// hikâye metninde var olmasın.** Bu havuz o kuralın ikinci yarısını
/// korur: buradaki her olay `livingRelations` üzerinden **gerçek bir
/// [Person] kaydına** bağlanır. Metindeki `{kisi}` o kişinin gerçek
/// adıdır, uydurulmuş bir isim değil; kişi yoksa olay hiç çıkmaz.
///
/// Bu yüzden burada "amcan aradı" gibi bir cümle, ancak kayıtta gerçekten
/// bir amca varsa görünür (§45: olmayan akraba uydurulmaz).
///
/// Havuz Paket AO'nun yeni bağlarını da kapsar: üvey kardeş, yarım
/// kardeş, üvey çocuk ve kayın aile. Onlar da aileden; sofrada yerleri
/// var.
///
/// **Ne yapmaz:** yıllık zorunlu bir "aile toplantısı" takvimi kurmaz.
/// Olaylar havuzun geri kalanıyla aynı seyrekleştirme kurallarına
/// tabidir (§46 — olay spamı yok).
///
/// Bütün sayısal değerler `prototypeOnly`'dir.
library;

import '../domain/models/game_event.dart';
import '../domain/models/relation.dart';

/// Aile buluşmalarının bıraktığı izler.
abstract final class FamilyGatheringFlags {
  static const String sofrayaKatildi = 'aile_sofrasina_katildi';
  static const String bulusmayiKacirdi = 'aile_bulusmasini_kacirdi';
  static const String araBulduAile = 'aile_arasi_ara_buldu';
}

/// Sofraya oturabilecek bağlar.
///
/// Tek yerde durur ki yeni bir bağ geldiğinde tek satır değişsin; her
/// olayın içine ayrı ayrı yazılmaz.
const Set<RelationType> _sofradakiler = <RelationType>{
  RelationType.anne,
  RelationType.baba,
  RelationType.kardes,
  RelationType.uveyAnne,
  RelationType.uveyBaba,
  RelationType.uveyKardes,
  RelationType.yariKardes,
  RelationType.teyze,
  RelationType.dayi,
  RelationType.hala,
  RelationType.amca,
  RelationType.anneanne,
  RelationType.babaanne,
  RelationType.anneTarafiDede,
  RelationType.babaTarafiDede,
};

const List<GameEvent> kFamilyGatheringEvents = <GameEvent>[
  // 1 — Kalabalık sofra
  GameEvent(
    id: 'aile_kalabalik_sofra',
    category: EventCategory.aile,
    text: '{sahip} bu hafta sonu herkesi topluyor. Sofra kurulacak, '
        'kim gelirse gelecek.',
    requirement: EventRequirement(
      minAge: 8,
      livingRelations: _sofradakiler,
    ),
    weight: 5,
    choices: <EventChoice>[
      EventChoice(
        id: 'sofraya_git',
        label: 'Git, sofraya otur',
        resultText: 'Masa uzadıkça uzadı. Kimin ne yaptığını, kimin '
            'kiminle küs olduğunu bir çırpıda öğrendin.',
        happiness: 6,
        bond: 7,
        charisma: 1,
        addFlags: <String>{FamilyGatheringFlags.sofrayaKatildi},
      ),
      EventChoice(
        id: 'kisa_ugra',
        label: 'Kısa uğra, erken çık',
        resultText: 'Yemeğe yetiştin, kahveye kalmadın. Yine de '
            'gittiğin görüldü.',
        happiness: 2,
        bond: 3,
      ),
      EventChoice(
        id: 'sofraya_gitme',
        label: 'Bu sefer gitme',
        resultText: 'Ertesi gün "seni sordular" dediler. Sormaları iyi '
            'geldi, gitmemiş olman değil.',
        happiness: -1,
        bond: -4,
        addFlags: <String>{FamilyGatheringFlags.bulusmayiKacirdi},
      ),
    ],
  ),

  // 2 — Bayram sabahı
  GameEvent(
    id: 'aile_bayram_sabahi',
    category: EventCategory.aile,
    text: 'Bayram sabahı. {sahip} kapıda, "hadi elini öp de çıkalım" '
        'diyor.',
    requirement: EventRequirement(
      minAge: 6,
      livingRelations: <RelationType>{
        RelationType.anne,
        RelationType.baba,
        RelationType.uveyAnne,
        RelationType.uveyBaba,
        RelationType.anneanne,
        RelationType.babaanne,
      },
    ),
    weight: 5,
    choices: <EventChoice>[
      EventChoice(
        id: 'ziyarete_cik',
        label: 'Bütün gün ziyarete çık',
        resultText: 'Ev ev dolaştınız. Ayakların şişti ama kimse '
            'atlanmadı.',
        happiness: 5,
        bond: 6,
      ),
      EventChoice(
        id: 'evde_kal',
        label: 'Evde kal, gelen gelsin',
        resultText: 'Gelenleri ağırladın. Gitmediklerin de vardı ama '
            'ev sıcaktı.',
        happiness: 3,
        bond: 2,
      ),
    ],
  ),

  // 3 — Uzaktan gelen haber (§29 — yakınlığa bağlı haber biçimi)
  GameEvent(
    id: 'aile_uzaktan_haber',
    category: EventCategory.aile,
    text: '{sahip} hakkında bir haber geldi ama sana değil, başkasına '
        'gelmiş. Uzun zamandır görüşmüyorsunuz.',
    requirement: EventRequirement(
      minAge: 16,
      requiresNeglectedRelative: true,
      requireOutsideHousehold: true,
      livingRelations: _sofradakiler,
    ),
    weight: 4,
    choices: <EventChoice>[
      EventChoice(
        id: 'hemen_ara',
        label: 'Hemen ara',
        resultText: 'Açtığında sesi şaşkındı. Konuşma uzadı; araya '
            'giren zamanı biraz kapattınız.',
        happiness: 4,
        bond: 9,
        addFlags: <String>{FamilyGatheringFlags.araBulduAile},
      ),
      EventChoice(
        id: 'sonra_ararim',
        label: 'Sonra ararım',
        resultText: 'Sonra hep sonraya kaldı.',
        happiness: -2,
        bond: -3,
      ),
    ],
  ),

  // 4 — Eşinin ailesiyle ilk uzun akşam (§21-§24)
  GameEvent(
    id: 'aile_kayin_aksami',
    category: EventCategory.aile,
    text: '{sahip} bu akşam sizi yemeğe bekliyor. Uzun bir akşam '
        'olacağı belli.',
    requirement: EventRequirement(
      minAge: 20,
      livingRelations: <RelationType>{
        RelationType.kayinvalide,
        RelationType.kayinpeder,
      },
    ),
    weight: 4,
    choices: <EventChoice>[
      EventChoice(
        id: 'kayin_sohbet',
        label: 'Sohbete gir, dinle',
        resultText: 'Anlattıkları uzundu ama dinlediğin belli oldu. '
            'Sonradan eşine "iyi çocuk" demişler.',
        happiness: 3,
        bond: 8,
        charisma: 1,
      ),
      EventChoice(
        id: 'kayin_sessiz',
        label: 'Sessiz kal, saati bekle',
        resultText: 'Akşam geçti. Kimse bir şey demedi, kimse bir şey '
            'de hatırlamadı.',
        bond: 1,
      ),
    ],
  ),

  // 5 — Üvey çocukla ilk gerçek konuşma (§18-§20)
  GameEvent(
    id: 'aile_uvey_cocuk_konusma',
    category: EventCategory.aile,
    text: '{sahip} akşam masada tek kelime etmedi. Sonra mutfakta '
        'yalnız yakaladın.',
    requirement: EventRequirement(
      minAge: 22,
      livingRelations: <RelationType>{RelationType.uveyCocuk},
      personMinAge: 8,
      requireSameHousehold: true,
    ),
    weight: 4,
    choices: <EventChoice>[
      EventChoice(
        id: 'uvey_dinle',
        label: 'Bir şey sorma, dinle',
        resultText: 'Konuşmaya kendi başladı. Babasını mı özlemiş, '
            'okulda mı bir şey olmuş, tam anlamadın — ama konuştu.',
        happiness: 2,
        bond: 9,
      ),
      EventChoice(
        id: 'uvey_zorlama',
        label: 'Zorlama, kendi haline bırak',
        resultText: 'Odasına çıktı. Belki doğrusuydu, belki değil.',
        bond: -1,
      ),
      EventChoice(
        id: 'uvey_otorite',
        label: '"Bu evde kurallar var" de',
        resultText: 'Tartışma çıktı. Senin evin olması, onun evi '
            'olduğu anlamına gelmiyor henüz.',
        happiness: -3,
        bond: -8,
      ),
    ],
  ),

  // 6 — Yarım kardeşle büyümek (§12-§13)
  GameEvent(
    id: 'aile_yarim_kardes_buyuyor',
    category: EventCategory.aile,
    text: '{sahip} artık senin peşinden ayrılmıyor. Aranızda yıllar '
        'var ama aynı evde büyüyorsunuz.',
    requirement: EventRequirement(
      minAge: 12,
      livingRelations: <RelationType>{
        RelationType.yariKardes,
        RelationType.uveyKardes,
      },
      personMinAge: 3,
      personMaxAge: 14,
      requireSameHousehold: true,
    ),
    weight: 4,
    choices: <EventChoice>[
      EventChoice(
        id: 'yarim_ilgilen',
        label: 'Peşinde dolaşmasına izin ver',
        resultText: 'Nereye gitsen arkanda. Yorucu ama senin '
            'kardeşin.',
        happiness: 3,
        bond: 8,
      ),
      EventChoice(
        id: 'yarim_uzak',
        label: 'Kendi alanını koru',
        resultText: 'Anladı ve çekildi. Bir daha da kolay kolay '
            'gelmedi.',
        bond: -6,
      ),
    ],
  ),
];

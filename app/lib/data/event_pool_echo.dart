/// Yankı olayları: yazılmış ama karşılığı olmayan izleri okuyan taraf
/// (Paket AS/2).
///
/// **Neden var.** Paket AR/AS ölçtü ki katalogda aranmayan 38 izin 32'si
/// *hiçbir yerde* okunmuyordu: oyuncu bir seçim yapıyor, oyun izi
/// koyuyor ve sonra onu bir daha hiç hatırlamıyor. Boşandın — hiçbir
/// olay bunu bilmiyordu. Baba/anne oldun — hiçbir olay bunu bilmiyordu.
/// Dört ayrı olayda yalnız kalmayı seçtin — oyun bunu hiç anmıyordu.
///
/// Bu dosya yeni mekanik getirmez. Yalnızca o izleri **okur**: kurulum
/// zaten yazılmıştı, eksik olan sonucuydu.
///
/// Kurallar:
/// - Hiçbir olay yeni bir iz koşulu uydurmaz; yalnızca var olan izleri
///   arar. İz adları kendi kaynak sınıflarından alınır (`StoryFlags`,
///   `MidlifeFlags`, …) — elle yazılan dizge yok, çünkü aynı Dart adını
///   taşıyan ama farklı değere sahip sabitler var (AS/1).
/// - Ağır konularda espri yok: boşanma, çocuktan ayrılık ve yalnızlık
///   sade ve saygılı anlatılır (`docs/WRITING_STYLE_TR.md` §7).
/// - Sonuç satırı sayıyı cümlenin içine gömmez; etkiler ayrı gösterilir.
/// - Her olay bir kez çıkar: `addFlags` ile kendi kapanış izini koyar ve
///   `forbiddenFlags` onu havuzdan düşürür.
library;

import '../domain/models/game_event.dart';
import '../domain/models/relation.dart';
import 'event_pool.dart';
import 'event_pool_elder.dart';
import 'event_pool_extra.dart';
import 'event_pool_midlife.dart';
import 'event_pool_romance.dart';

/// Yankı olaylarının kendi kapanış izleri.
///
/// Yalnızca "bu yankı görüldü" demek için var; başka hiçbir şeyi
/// etkilemezler ve `forbiddenFlags` ile tekrarı engellerler.
abstract final class EchoFlags {
  static const String bosanmaYilDonumu = 'yanki_bosanma_yil_donumu';
  static const String ilkBabalikGunu = 'yanki_ilk_ebeveynlik';
  static const String yalnizlikMuhasebesi = 'yanki_yalnizlik_muhasebesi';
  static const String ertelenenTanismaDondu = 'yanki_ertelenen_tanisma';
  static const String susmaninBedeli = 'yanki_susmanin_bedeli';
  static const String ilkGunHatirlandi = 'yanki_ilk_gun_hatirlandi';
  static const String zamSonucu = 'yanki_zam_sonucu';
  static const String borcGeriDondu = 'yanki_borc_geri_dondu';
  static const String torunBuyudu = 'yanki_torun_buyudu';
  static const String dolandiriciTekrar = 'yanki_dolandirici_tekrar';
}

const List<GameEvent> kEchoEvents = <GameEvent>[
  // ===================================================================
  // Boşanma — `StoryFlags.bosandi` motorda konuyordu, hiçbir olay
  // okumuyordu.
  // ===================================================================
  GameEvent(
    id: 'yanki_bosanma_yil_donumu',
    category: EventCategory.kisisel,
    text: 'Telefonun takvimi eski bir kaydı hatırlattı: bugün evlilik '
        'yıl dönümünüzmüş.\n\n'
        'Kaydı silmeyi hiç akıl etmemişsin.',
    requirement: EventRequirement(
      minAge: 25,
      requiredFlags: <String>{StoryFlags.bosandi},
      forbiddenFlags: <String>{EchoFlags.bosanmaYilDonumu},
    ),
    weight: 6,
    choices: <EventChoice>[
      EventChoice(
        id: 'sil',
        label: 'Kaydı sil',
        resultText: 'Sildin. Telefon bir daha hatırlatmayacak. '
            'Akşam boyunca başka bir şey düşünmedin ama.',
        happiness: 1,
        addFlags: <String>{EchoFlags.bosanmaYilDonumu},
      ),
      EventChoice(
        id: 'birak',
        label: 'Dursun',
        resultText: 'Elini uzattın, vazgeçtin. Olan olmuş; kayıt da '
            'olanın bir parçası.',
        happiness: -1,
        intelligence: 1,
        addFlags: <String>{EchoFlags.bosanmaYilDonumu},
      ),
    ],
  ),

  // ===================================================================
  // Ebeveynlik — `StoryFlags.cocukSahibi` motorda konuyordu, hiçbir olay
  // okumuyordu.
  // ===================================================================
  GameEvent(
    id: 'yanki_ilk_ebeveynlik',
    category: EventCategory.kisisel,
    text: 'Gece yarısı mutfakta su içerken durdun. Evde senden başka '
        'uyanan yok ve artık bu evde senin sorumluluğunda bir insan var.'
        '\n\nTuhaf bir şey: korkuyla gurur aynı anda gelebiliyor.',
    requirement: EventRequirement(
      minAge: 18,
      requiredFlags: <String>{StoryFlags.cocukSahibi},
      livingRelations: <RelationType>{RelationType.cocuk},
      forbiddenFlags: <String>{EchoFlags.ilkBabalikGunu},
    ),
    weight: 7,
    choices: <EventChoice>[
      EventChoice(
        id: 'odaya_bak',
        label: 'Odaya bir bak',
        resultText: 'Kapıyı araladın. Uyuyordu. Nefes alıp verişini '
            'bir süre dinledin, sonra kapıyı aynı sessizlikle kapattın.',
        happiness: 5,
        bond: 4,
        addFlags: <String>{EchoFlags.ilkBabalikGunu},
      ),
      EventChoice(
        id: 'hesap_yap',
        label: 'Masaya oturup hesap yap',
        resultText: 'Bir kâğıda aylık gideri yazdın, altına gelirini. '
            'Sayılar seni çok heveslendirmedi ama ne yapacağını gösterdi.',
        intelligence: 3,
        happiness: -1,
        addFlags: <String>{EchoFlags.ilkBabalikGunu},
      ),
    ],
  ),

  // Çocuğun okulun ilk günü yalnız bırakılmıştı (`cocukIlkGunYalniz`).
  GameEvent(
    id: 'yanki_ilk_gun_hatirlandi',
    category: EventCategory.kisisel,
    text: 'Çocuğun lafın arasında söyledi: "Okulun ilk günü seni '
        'aradım, yoktun."\n\n'
        'Gülerek söyledi. Sen gülemedin.',
    requirement: EventRequirement(
      minAge: 28,
      requiredFlags: <String>{StoryFlags.cocukIlkGunYalniz},
      livingRelations: <RelationType>{RelationType.cocuk},
      personMinAge: 12,
      forbiddenFlags: <String>{EchoFlags.ilkGunHatirlandi},
    ),
    weight: 6,
    choices: <EventChoice>[
      EventChoice(
        id: 'ozur',
        label: 'Özür dile',
        resultText: '"Haklısın, olmam gerekirdi." Bir an sustu, sonra '
            '"tamam baba" dedi. O "tamam" uzun bir cümleydi.',
        happiness: 2,
        bond: 8,
        charisma: 1,
        addFlags: <String>{EchoFlags.ilkGunHatirlandi},
      ),
      EventChoice(
        id: 'aciklama',
        label: 'O gün işte olduğunu anlat',
        resultText: '"Biliyorum" dedi, konuyu değiştirdi. Anlattığın '
            'şey doğruydu; istediği şey o değildi.',
        happiness: -1,
        bond: -2,
        addFlags: <String>{EchoFlags.ilkGunHatirlandi},
      ),
    ],
  ),

  // ===================================================================
  // Yalnızlık — dört ayrı seçim `bekar_yalnizligi_secti` izini koyuyordu,
  // hiçbir olay okumuyordu.
  // ===================================================================
  GameEvent(
    id: 'yanki_yalnizlik_muhasebesi',
    category: EventCategory.kisisel,
    text: 'Uzun bir hafta sonu daha bitti ve kimseye tek kelime '
        'etmedin.\n\n'
        'Bunu seçtin, biliyorsun. Soru şu: hâlâ seçiyor musun?',
    requirement: EventRequirement(
      minAge: 24,
      requiredFlags: <String>{SingleLifeFlags.yalnizligiSecti},
      forbiddenFlags: <String>{EchoFlags.yalnizlikMuhasebesi},
    ),
    weight: 6,
    choices: <EventChoice>[
      EventChoice(
        id: 'kabul',
        label: 'Evet, böyle iyi',
        resultText: 'Kendine bir kahve yaptın, kitabın kaldığı yerden '
            'devam ettin. Kimse kapıyı çalmadı; çalmasını da '
            'istemiyordun.',
        happiness: 3,
        intelligence: 2,
        addFlags: <String>{EchoFlags.yalnizlikMuhasebesi},
      ),
      EventChoice(
        id: 'ara',
        label: 'Birini ara',
        resultText: 'Listede uzun süre aşağı yukarı gezindin, sonunda '
            'bir numaraya bastın. "Hayırdır, kayıplara karışmıştın" '
            'dedi karşı taraf.',
        happiness: 4,
        charisma: 3,
        addFlags: <String>{EchoFlags.yalnizlikMuhasebesi},
      ),
    ],
  ),

  // Tanışma ertelenmişti (`bekar_tanismayi_erteledi`, üç seçim).
  GameEvent(
    id: 'yanki_ertelenen_tanisma',
    category: EventCategory.kisisel,
    text: 'Vaktinde "şimdi olmaz" dediğin tanışmayı hatırlatan bir '
        'mesaj geldi: "Hâlâ o kahve borcun var."',
    requirement: EventRequirement(
      minAge: 24,
      requiredFlags: <String>{SingleLifeFlags.tanismayiErteledi},
      forbiddenFlags: <String>{EchoFlags.ertelenenTanismaDondu},
    ),
    weight: 6,
    choices: <EventChoice>[
      EventChoice(
        id: 'bu_sefer_git',
        label: 'Bu sefer git',
        resultText: 'Gittin. İki saat nasıl geçti anlamadın; bir şey '
            'olmadı ama konuşacak insan bulmak da bir şeymiş.',
        happiness: 4,
        charisma: 2,
        startsFriendship: true,
        addFlags: <String>{EchoFlags.ertelenenTanismaDondu},
      ),
      EventChoice(
        id: 'yine_erteleme',
        label: 'Yine erteleme',
        resultText: '"Bu hafta yoğunum" yazdın. Yazarken bile '
            'inanmadın. Mesaj bir daha gelmedi.',
        happiness: -2,
        addFlags: <String>{EchoFlags.ertelenenTanismaDondu},
      ),
    ],
  ),

  // ===================================================================
  // Eşle susulmuştu (`StoryFlags.esleSusuldu`).
  // ===================================================================
  GameEvent(
    id: 'yanki_susmanin_bedeli',
    category: EventCategory.kisisel,
    text: 'Aynı konu yine masaya geldi. Eşin "geçen de böyle susmuştun" '
        'dedi.\n\n'
        'Doğru söylüyor.',
    requirement: EventRequirement(
      minAge: 22,
      requiredFlags: <String>{StoryFlags.esleSusuldu},
      livingRelations: <RelationType>{RelationType.es},
      forbiddenFlags: <String>{EchoFlags.susmaninBedeli},
    ),
    weight: 7,
    choices: <EventChoice>[
      EventChoice(
        id: 'konus',
        label: 'Bu sefer konuş',
        resultText: 'Uzun sürdü, bir yerde sesin de yükseldi. Ama '
            'bitince ikiniz de aynı şeyi biliyordunuz, bu yeni bir '
            'durumdu.',
        happiness: 3,
        bond: 7,
        charisma: 2,
        addFlags: <String>{
          StoryFlags.esleKonusuldu,
          EchoFlags.susmaninBedeli,
        },
      ),
      EventChoice(
        id: 'yine_sus',
        label: 'Yine sus',
        resultText: 'Omuz silktin. Konu kapandı sayılır; kapanmadığını '
            'ikiniz de biliyorsunuz.',
        happiness: -3,
        bond: -6,
        addFlags: <String>{EchoFlags.susmaninBedeli},
      ),
    ],
  ),

  // ===================================================================
  // Zam istenmişti (`CareerProgress` izi, hiçbir olay okumuyordu).
  // ===================================================================
  GameEvent(
    id: 'yanki_zam_sonucu',
    category: EventCategory.yetiskinlik,
    text: 'Müdür kapıda durdu: "Geçen konuştuğumuz şeyi unutmadım."'
        '\n\nArkasından ne geleceğini bilmiyorsun.',
    requirement: EventRequirement(
      minAge: 20,
      requiresEmployed: true,
      requiredFlags: <String>{ExtraFlags.zamIstendi},
      forbiddenFlags: <String>{EchoFlags.zamSonucu},
    ),
    weight: 7,
    choices: <EventChoice>[
      EventChoice(
        id: 'bekle',
        label: 'Dinle',
        resultText: '"Bu çeyrek olmuyor ama sıradakinde sen varsın." '
            'Yazılı değil; yine de ilk kez bir sıraya girdin.',
        happiness: 2,
        charisma: 1,
        addFlags: <String>{EchoFlags.zamSonucu},
      ),
      EventChoice(
        id: 'tarih_iste',
        label: 'Net bir tarih iste',
        resultText: '"Ne zaman?" diye sordun. Takvimi açtı, bir ay '
            'gösterdi. Soruyu sormak, sorunun cevabını değiştirdi.',
        happiness: 3,
        charisma: 3,
        intelligence: 1,
        addFlags: <String>{EchoFlags.zamSonucu},
      ),
    ],
  ),

  // ===================================================================
  // Orta yaşta borç verilmişti (`MidlifeFlags.borcVerdi` = orta_borc_verdi).
  // ===================================================================
  GameEvent(
    id: 'yanki_borc_geri_dondu',
    category: EventCategory.kisisel,
    text: 'Kapı çaldı. Yıllar önce borç verdiğin tanıdık, elinde bir '
        'zarf.\n\n"Geç oldu, kusura bakma."',
    requirement: EventRequirement(
      minAge: 35,
      requiredFlags: <String>{MidlifeFlags.borcVerdi},
      forbiddenFlags: <String>{EchoFlags.borcGeriDondu},
    ),
    weight: 6,
    choices: <EventChoice>[
      EventChoice(
        id: 'al',
        label: 'Al, teşekkür et',
        resultText: 'Zarfı aldın, saymadın. "Otur bir çay iç" dedin, '
            'oturdu. Para geri geldi, hesap da kapandı.',
        money: 30000,
        happiness: 4,
        charisma: 2,
        addFlags: <String>{EchoFlags.borcGeriDondu},
      ),
      EventChoice(
        id: 'kalsin',
        label: '"Kalsın"',
        resultText: '"Gerek yok" dedin, zarfı geri uzattın. Bir süre '
            'ikiniz de konuşmadınız. Sonra sadece başını sallayıp gitti.',
        happiness: 3,
        charisma: 4,
        addFlags: <String>{EchoFlags.borcGeriDondu},
      ),
    ],
  ),

  // ===================================================================
  // Torunla vakit geçirilmişti (`torunla_vakit`).
  // ===================================================================
  GameEvent(
    id: 'yanki_torun_buyudu',
    category: EventCategory.kisisel,
    text: 'Torunun elinde bir kâğıt geldi: okulda "en sevdiğin gün" '
        'diye yazdırmışlar.\n\nSizin o günü yazmış.',
    requirement: EventRequirement(
      minAge: 55,
      requiredFlags: <String>{ElderFlags.torunlaVakit},
      livingRelations: <RelationType>{RelationType.torun},
      forbiddenFlags: <String>{EchoFlags.torunBuyudu},
    ),
    weight: 7,
    choices: <EventChoice>[
      EventChoice(
        id: 'sakla',
        label: 'Kâğıdı sakla',
        resultText: 'Kâğıdı katlayıp çekmeceye koydun. Orada duran '
            'başka şeyler de var; bu da onların yanına gitti.',
        happiness: 7,
        bond: 6,
        addFlags: <String>{EchoFlags.torunBuyudu},
      ),
      EventChoice(
        id: 'yeni_gun',
        label: '"Hadi bir yenisini yapalım"',
        resultText: 'Ertesi hafta sonu için söz verdin. Sözü de '
            'tuttun; o gün de bir yere yazılır artık.',
        happiness: 6,
        bond: 9,
        health: -1,
        addFlags: <String>{EchoFlags.torunBuyudu},
      ),
    ],
  ),

  // ===================================================================
  // Dolandırıcıya kanılmamıştı (`dolandiriciya_kanmadi`).
  // ===================================================================
  GameEvent(
    id: 'yanki_dolandirici_tekrar',
    category: EventCategory.kisisel,
    text: 'Aynı numara, aynı cümleler. Bu sefer daha hazırlıklı '
        'konuşuyor ve adını biliyor.',
    requirement: EventRequirement(
      minAge: 25,
      requiredFlags: <String>{ExtraFlags.dolandiriciyaKanmadi},
      forbiddenFlags: <String>{EchoFlags.dolandiriciTekrar},
    ),
    weight: 6,
    choices: <EventChoice>[
      EventChoice(
        id: 'kapat_bildir',
        label: 'Kapat ve bildir',
        resultText: 'Telefonu kapattın, numarayı bildirdin. İki gün '
            'sonra aynı numaradan bir daha gelmedi.',
        happiness: 2,
        intelligence: 2,
        addFlags: <String>{EchoFlags.dolandiriciTekrar},
      ),
      EventChoice(
        id: 'oyala',
        label: 'Oyala bakalım',
        resultText: 'On dakika konuşturdun, sonunda karşı taraf '
            'sinirlendi ve kapattı. Kimseye faydası yok ama keyifliydi.',
        happiness: 3,
        charisma: 1,
        addFlags: <String>{EchoFlags.dolandiriciTekrar},
      ),
    ],
  ),
];

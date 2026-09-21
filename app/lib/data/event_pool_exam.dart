/// Sınav dönemi olayları: 8. ve 12. sınıf (Paket 17).
///
/// Türkiye'de okul hayatının iki yılı diğerlerinden ayrılır: ortaokulun
/// son yılı ve lisenin son yılı. Bu dosya o iki yılın **kendi** olaylarını
/// tutar; sıradan sınav gecesi olayı (`sinav_oncesi_gece`)
/// `event_pool_stages.dart` içinde zaten vardır ve tekrar yazılmaz.
///
/// Kurallar:
/// - Seçimler puanı **gerçekten** değiştirir: bıraktıkları izler
///   `EducationPath` içinde yerleştirme ve üniversite sınavı puanına
///   katılır (`prototypeOnly`, Q-085).
/// - Çok çalışmak bedava değildir: mutluluk ve sağlık düşebilir.
/// - Kaygı bir **ceza döngüsü** değildir; tek yıllık bir izdir ve
///   dengede kalan oyuncu bundan hiç etkilenmez.
/// - Hiçbiri gerçek bir sınavın adını taşımaz; kurgusal anlatılır.
library;

import '../domain/models/game_event.dart';
import '../domain/models/relation.dart';

/// Sınav dönemi izleri.
///
/// İki sınav ayrı tutulur: 8. sınıfta bırakılan iz 12. sınıf puanını
/// etkilemez, çünkü aradan dört yıl geçer.
abstract final class ExamFlags {
  // 8. sınıf — lise yerleştirme
  static const String ortaokulOdaklandi = 'sinav8_odaklandi';
  static const String ortaokulDengeli = 'sinav8_dengeli';
  static const String ortaokulSavsakladi = 'sinav8_savsakladi';
  static const String ortaokulKaygi = 'sinav8_kaygi';
  static const String ortaokulDestek = 'sinav8_destek';

  // 12. sınıf — üniversite sınavı
  static const String liseOdaklandi = 'sinav12_odaklandi';
  static const String liseDengeli = 'sinav12_dengeli';
  static const String liseSavsakladi = 'sinav12_savsakladi';
  static const String liseKaygi = 'sinav12_kaygi';
  static const String liseDestek = 'sinav12_destek';
}

/// Sınav yılları.
abstract final class ExamYear {
  /// Ortaokulun son yılı: lise yerleştirme sınavı.
  static const int ortaokulSon = 8;

  /// Lisenin son yılı: üniversite sınavı.
  static const int liseSon = 12;

  /// Verilen sınıf bir sınav yılı mı?
  static bool isExamGrade(int? grade) =>
      grade == ortaokulSon || grade == liseSon;
}

const List<GameEvent> kExamEvents = <GameEvent>[
  // =================================================================
  // 8. sınıf — ortaokulun son yılı
  // =================================================================

  GameEvent(
    id: 'sinav8_takvim',
    category: EventCategory.okul,
    text: 'Koridora büyük bir takvim asıldı. Üstünde kalan gün sayısı '
        'yazıyor ve her sabah bir eksiliyor. Sınıfta kimse artık eskisi '
        'gibi konuşmuyor.',
    requirement: EventRequirement(
      requiresSchoolStudent: true,
      minGrade: 8,
      maxGrade: 8,
      forbiddenFlags: <String>{
        ExamFlags.ortaokulOdaklandi,
        ExamFlags.ortaokulDengeli,
        ExamFlags.ortaokulSavsakladi,
      },
    ),
    weight: 9,
    choices: <EventChoice>[
      EventChoice(
        id: 'kilitlen',
        label: 'Bu yıl her şeyi sınava göre ayarla',
        resultText: 'Masa lambası gece yarısını geçti. Maç, oyun, dışarı '
            'çıkmak — hepsi sınavdan sonraya kaldı. Sayılar ezberden '
            'çözülmeye başladı.',
        happiness: -6,
        health: -3,
        intelligence: 3,
        addFlags: <String>{ExamFlags.ortaokulOdaklandi},
      ),
      EventChoice(
        id: 'dengeli',
        label: 'Programlı çalış ama hayatı durdurma',
        resultText: 'Akşam altıya kadar ders, sonrası serbest. Program '
            'ilk hafta bozuldu, ikinci hafta oturdu.',
        happiness: -1,
        intelligence: 2,
        addFlags: <String>{ExamFlags.ortaokulDengeli},
      ),
      EventChoice(
        id: 'bos_ver',
        label: 'Herkes abartıyor, boş ver',
        resultText: 'Takvime bakmamayı öğrendin. Öğle aralarında saha '
            'boştu, sen doluydun.',
        happiness: 5,
        addFlags: <String>{ExamFlags.ortaokulSavsakladi},
      ),
    ],
  ),

  GameEvent(
    id: 'sinav8_deneme',
    category: EventCategory.okul,
    text: 'Deneme sınavının sonucu geldi. Kâğıdın üstünde beklediğinden '
        'farklı bir sayı var ve yanındaki sıra ne aldığını soruyor.',
    requirement: EventRequirement(
      requiresSchoolStudent: true,
      minGrade: 8,
      maxGrade: 8,
    ),
    repeatable: true,
    minAgeGap: 4,
    weight: 7,
    choices: <EventChoice>[
      EventChoice(
        id: 'yanlislari_cik',
        label: 'Yanlışlarını tek tek çıkar',
        resultText: 'Otuz yanlışın yirmi altısı aynı üç konudandı. '
            'Bunu bilmek, sayının kendisinden daha işe yaradı.',
        intelligence: 2,
        happiness: -1,
        addFlags: <String>{ExamFlags.ortaokulDengeli},
      ),
      EventChoice(
        id: 'katla_cantaya',
        label: 'Kâğıdı katla, çantaya at',
        resultText: 'Kâğıt çantanın dibinde kaldı. Bir daha da çıkmadı.',
        happiness: 2,
        addFlags: <String>{ExamFlags.ortaokulSavsakladi},
      ),
      EventChoice(
        id: 'ogretmene_sor',
        label: 'Öğretmenine sor',
        resultText: 'Teneffüste öğretmenin kâğıda baktı, iki soruyu '
            'tahtaya çizdi ve "burası herkesin takıldığı yer" dedi.',
        intelligence: 1,
        happiness: 1,
        addFlags: <String>{ExamFlags.ortaokulDestek},
      ),
    ],
  ),

  GameEvent(
    id: 'sinav8_gece',
    category: EventCategory.kisisel,
    text: 'Yatakta gözlerin açık. Yarın değil ama bir gün sınav olacak ve '
        'şu an aklında yalnızca o var.',
    requirement: EventRequirement(
      requiresSchoolStudent: true,
      minGrade: 8,
      maxGrade: 8,
    ),
    repeatable: true,
    minAgeGap: 4,
    weight: 6,
    choices: <EventChoice>[
      EventChoice(
        id: 'uyu',
        label: 'Kitabı kapat, uyumaya çalış',
        resultText: 'Işığı kapattın. Uyku hemen gelmedi ama sabah '
            'kalktığında kafan en azından çalışıyordu.',
        health: 2,
        happiness: 1,
      ),
      EventChoice(
        id: 'sabaha_kadar',
        label: 'Sabaha kadar tekrar et',
        resultText: 'Saat dörtte aynı paragrafı beşinci kez okuduğunu '
            'fark ettin. Okula gittiğinde ilk ders zaten geçmişti.',
        health: -4,
        happiness: -3,
        addFlags: <String>{ExamFlags.ortaokulKaygi},
      ),
    ],
  ),

  // Bu olay **önceki kararı hatırlar**: yalnızca yılı sınava adayan
  // oyuncuda çıkar.
  GameEvent(
    id: 'sinav8_son_hafta',
    category: EventCategory.okul,
    text: 'Son hafta. Bütün yılı buna göre kurduğun için artık yapacak '
        'yeni bir şey kalmadı; yalnızca beklemek var.',
    requirement: EventRequirement(
      requiresSchoolStudent: true,
      minGrade: 8,
      maxGrade: 8,
      requiredFlags: <String>{ExamFlags.ortaokulOdaklandi},
    ),
    weight: 8,
    choices: <EventChoice>[
      EventChoice(
        id: 'dinlen',
        label: 'Son haftayı dinlenerek geçir',
        resultText: 'Kitapları rafa kaldırdın. Sınav sabahı uykunu almış '
            'olarak uyandın; bu yıl ilk kez.',
        health: 4,
        happiness: 4,
        addFlags: <String>{ExamFlags.ortaokulDengeli},
      ),
      EventChoice(
        id: 'son_gaz',
        label: 'Son haftada da hız kesme',
        resultText: 'Son güne kadar çalıştın. Sınav salonuna girdiğinde '
            'elinde kalem, gözünde uykusuzluk vardı.',
        health: -3,
        happiness: -2,
        intelligence: 1,
        addFlags: <String>{ExamFlags.ortaokulKaygi},
      ),
    ],
  ),

  // =================================================================
  // 12. sınıf — lisenin son yılı
  // =================================================================

  GameEvent(
    id: 'sinav12_yil_basi',
    category: EventCategory.okul,
    text: 'Lise son başladı. İlk gün öğretmen tahtaya tek bir sayı yazdı: '
        'kalan gün. Sınıf bir anda sustu.',
    requirement: EventRequirement(
      requiresSchoolStudent: true,
      minGrade: 12,
      maxGrade: 12,
      forbiddenFlags: <String>{
        ExamFlags.liseOdaklandi,
        ExamFlags.liseDengeli,
        ExamFlags.liseSavsakladi,
      },
    ),
    weight: 9,
    choices: <EventChoice>[
      EventChoice(
        id: 'kilitlen',
        label: 'Bu yılı tamamen sınava ver',
        resultText: 'Bir yıl boyunca aynı masa, aynı saat, aynı deftergil. '
            'Arkadaşların nereye gittiğini artık sormuyorsun.',
        happiness: -8,
        health: -4,
        intelligence: 4,
        addFlags: <String>{ExamFlags.liseOdaklandi},
      ),
      EventChoice(
        id: 'dengeli',
        label: 'Düzenli çalış ama kendine de yer bırak',
        resultText: 'Haftada bir gün tamamen boş. O gün olmasa diğer altı '
            'gün de olmuyordu.',
        happiness: -1,
        intelligence: 3,
        addFlags: <String>{ExamFlags.liseDengeli},
      ),
      EventChoice(
        id: 'ertele',
        label: 'Daha zaman var, sonra bakarım',
        resultText: '"Yarından itibaren" cümlesini o yıl çok kurdun. '
            'Takvim seni beklemedi.',
        happiness: 4,
        addFlags: <String>{ExamFlags.liseSavsakladi},
      ),
    ],
  ),

  GameEvent(
    id: 'sinav12_aile_baskisi',
    category: EventCategory.aile,
    text: 'Akşam sofrasında {sahip} ne okumak istediğini sordu. Cevabını '
        'söylemeden önce odadaki sessizliği duydun.',
    requirement: EventRequirement(
      requiresSchoolStudent: true,
      minGrade: 12,
      maxGrade: 12,
      livingRelations: <RelationType>{RelationType.anne, RelationType.baba},
      requireSameHousehold: true,
    ),
    weight: 7,
    choices: <EventChoice>[
      EventChoice(
        id: 'kendi_karari',
        label: 'Kendi istediğini söyle',
        resultText: 'Söyledin. Sofrada kısa bir sessizlik oldu, sonra '
            '{sahip} "sen bilirsin" dedi. Tonu tam ikna olmuş değildi.',
        happiness: 3,
        bond: -2,
      ),
      EventChoice(
        id: 'ailenin_istegi',
        label: 'Ailenin istediğini söyle',
        resultText: 'Beklenen cevabı verdin. Sofra rahatladı; sen bir '
            'süre daha tabağa baktın.',
        happiness: -3,
        bond: 5,
      ),
      EventChoice(
        id: 'birlikte_bak',
        label: 'Birlikte bakalım de',
        resultText: 'O akşam masaya bölüm listesi serildi. Kimse kimseyi '
            'ikna edemedi ama ikiniz de aynı sayfaya baktınız.',
        happiness: 1,
        bond: 3,
        addFlags: <String>{ExamFlags.liseDestek},
      ),
    ],
  ),

  GameEvent(
    id: 'sinav12_deneme',
    category: EventCategory.okul,
    text: 'Deneme sonuçları panoya asıldı. Herkes önce kendi sırasını, '
        'sonra başkalarınınkini arıyor.',
    requirement: EventRequirement(
      requiresSchoolStudent: true,
      minGrade: 12,
      maxGrade: 12,
    ),
    repeatable: true,
    minAgeGap: 4,
    weight: 7,
    choices: <EventChoice>[
      EventChoice(
        id: 'analiz',
        label: 'Sonucu soğukkanlı incele',
        resultText: 'Netlerini konu konu ayırdın. Sıralaman düşünce '
            'paniklemek yerine hangi konunun seni yediğini buldun.',
        intelligence: 2,
        addFlags: <String>{ExamFlags.liseDengeli},
      ),
      EventChoice(
        id: 'panoya_bakma',
        label: 'Panoya hiç bakma',
        resultText: 'Panonun önünden geçip gittin. O hafta kimse sana '
            'kaç yaptığını soramadı.',
        happiness: 2,
        addFlags: <String>{ExamFlags.liseSavsakladi},
      ),
      EventChoice(
        id: 'kendini_kotule',
        label: 'Kendine kız',
        resultText: 'Akşam boyunca aynı cümleyi tekrarladın: "bu kadar '
            'çalışıp bu mu?" Cümle hiçbir soruyu çözmedi.',
        happiness: -5,
        addFlags: <String>{ExamFlags.liseKaygi},
      ),
    ],
  ),

  // Bu olay da **önceki kararı hatırlar**: yalnızca yılı sınava adamış
  // oyuncuda çıkar.
  GameEvent(
    id: 'sinav12_son_ay',
    category: EventCategory.kisisel,
    text: 'Son ay. Bir yıldır aynı masadasın ve artık sayfaları çevirmek '
        'bile zor geliyor. Aynada kendine baktın.',
    requirement: EventRequirement(
      requiresSchoolStudent: true,
      minGrade: 12,
      maxGrade: 12,
      requiredFlags: <String>{ExamFlags.liseOdaklandi},
    ),
    weight: 8,
    choices: <EventChoice>[
      EventChoice(
        id: 'ara_ver',
        label: 'Birkaç gün gerçekten ara ver',
        resultText: 'Üç gün kitaba dokunmadın. Dördüncü gün masaya '
            'oturduğunda soruları yeniden görebiliyordun.',
        health: 5,
        happiness: 6,
        addFlags: <String>{ExamFlags.liseDengeli},
      ),
      EventChoice(
        id: 'zorla',
        label: 'Kendini zorlamaya devam et',
        resultText: 'Son aya kadar hız kesmedin. Sınav sabahı ne kadar '
            'yorgun olduğunu ancak salona girince fark ettin.',
        health: -5,
        happiness: -4,
        addFlags: <String>{ExamFlags.liseKaygi},
      ),
    ],
  ),
];

/// Okul kulübü ve takım olayları (Paket AU).
///
/// **Kurallar.**
/// - Her olay `requiresActiveClubId` ile gerçek üyeliğe bağlı: takımda
///   olmayan kimse "ilk 11'e çıktın" olayını görmez.
/// - Takım arkadaşı gerekiyorsa **mevcut** sınıf arkadaşı kaydı
///   kullanılır (`livingRelations`); uydurma isim üretilmez, ikinci bir
///   kişi üretim sistemi yazılmaz. Kişi bulunamıyorsa olay kişisizdir.
/// - İzler bu dosyada hem konur hem **okunur**; dışarıya sessiz iz
///   bırakılmaz (AS/1 ölçütü).
/// - Dil `docs/WRITING_STYLE_TR.md`. Sakatlık ve çatışma sade anlatılır.
/// - Okul futbolu **ün açmaz**, maaş ödemez: para ve `fame` etkisi yok.
library;

import '../domain/models/game_event.dart';
import '../domain/models/relation.dart';
import '../domain/models/school_club_progress.dart';

/// Kulüp olaylarının izleri. Hepsi bu dosyada okunur.
abstract final class ClubFlags {
  /// İlk kez ilk 11'e çıkıldı.
  static const String ilkOnBireCikti = 'kulup_ilk_on_bir';

  /// Antrenörle anlaşmazlık yaşandı.
  static const String antrenorleGerginlik = 'kulup_antrenor_gerginlik';

  /// Antrenörle barışıldı.
  static const String antrenorleDuzeldi = 'kulup_antrenor_duzeldi';

  /// Penaltı kaçırıldı.
  static const String penaltiKacirdi = 'kulup_penalti_kacti';

  /// Sakatlık yaşandı.
  static const String sakatlandi = 'kulup_sakatlik';

  /// Scout izlemeye başladı.
  static const String scoutIzledi = 'kulup_scout';

  /// Okul-spor çatışmasında spor seçildi.
  static const String sporuSecti = 'kulup_sporu_secti';

  /// Okul-spor çatışmasında ders seçildi.
  static const String dersiSecti = 'kulup_dersi_secti';

  /// Satrançta güçlü rakibe karşı oynandı.
  static const String gucluRakip = 'kulup_satranc_guclu_rakip';

  /// Turnuvada derece alındı.
  static const String derecaAldi = 'kulup_derece';
}

const List<GameEvent> kSchoolClubEvents = <GameEvent>[
  // ===================================================================
  // FUTBOL
  // ===================================================================
  GameEvent(
    id: 'kulup_futbol_ilk_antrenman',
    category: EventCategory.okul,
    text: 'İlk antrenman. Kaleye kadar koşu, sonra yine koşu.\n\n'
        'Yanındaki çocuk "ilk hafta hep böyle" dedi.',
    requirement: EventRequirement(
      minAge: 9,
      maxAge: 19,
      requiresActiveClubId: 'futbol_takimi',
    ),
    weight: 7,
    choices: <EventChoice>[
      EventChoice(
        id: 'tempoyu_tut',
        label: 'Tempoyu tutmaya çalış',
        resultText: 'Son turda kustun ama bıraktın da değil. Antrenör '
            'bir şey demedi, sadece baktı.',
        health: -2,
        happiness: 1,
      ),
      EventChoice(
        id: 'kendini_koru',
        label: 'Kendini zorlamadan devam et',
        resultText: 'Yavaş koştun, nefesin kesilmedi. İlk hafta böyle '
            'geçti; ikinci hafta aynısını yapmak zorlaştı.',
        health: 1,
        happiness: 1,
      ),
    ],
  ),

  GameEvent(
    id: 'kulup_futbol_ilk_on_bir',
    category: EventCategory.okul,
    text: 'Maç öncesi kadro okundu ve adın ilk on birde geçti.\n\n'
        'Bir an duydun mu diye tereddüt ettin.',
    requirement: EventRequirement(
      minAge: 10,
      maxAge: 19,
      requiresActiveClubId: 'futbol_takimi',
      minSquadRole: SquadRole.ilkOnBir,
      forbiddenFlags: <String>{ClubFlags.ilkOnBireCikti},
    ),
    weight: 9,
    choices: <EventChoice>[
      EventChoice(
        id: 'sahaya_cik',
        label: 'Sahaya çık',
        resultText: 'İlk dakikalar bulanık geçti, sonra top ayağına '
            'alıştı. Doksan dakika sonunda bacakların titriyordu.',
        happiness: 7,
        charisma: 2,
        health: -1,
        addFlags: <String>{ClubFlags.ilkOnBireCikti},
      ),
      EventChoice(
        id: 'gergin',
        label: 'Gerginliğini belli etme',
        resultText: 'Kimseye söylemedin ama ısınmada elin titredi. '
            'Maçta fena oynamadın; o gece uyuyamadın.',
        happiness: 5,
        intelligence: 1,
        addFlags: <String>{ClubFlags.ilkOnBireCikti},
      ),
    ],
  ),

  GameEvent(
    id: 'kulup_futbol_kritik_gol',
    category: EventCategory.okul,
    text: 'Son dakikalar, skor eşit ve top sana geldi.',
    requirement: EventRequirement(
      minAge: 11,
      maxAge: 19,
      requiresActiveClubId: 'futbol_takimi',
      minSquadRole: SquadRole.ilkOnBir,
      requiredFlags: <String>{ClubFlags.ilkOnBireCikti},
    ),
    repeatable: true,
    minAgeGap: 3,
    weight: 7,
    choices: <EventChoice>[
      EventChoice(
        id: 'kendim_vur',
        label: 'Kendin vur',
        resultText: 'Vurdun. Top direğin dibinden girdi ve tribündeki '
            'otuz kişi aynı anda bağırdı. O sesi uzun süre hatırladın.',
        happiness: 9,
        charisma: 3,
      ),
      EventChoice(
        id: 'pas_ver',
        label: 'Boştaki arkadaşına ver',
        resultText: 'Pasını verdin, o bitirdi. Golü o attı ama '
            'herkes pası konuştu.',
        happiness: 6,
        charisma: 4,
      ),
    ],
  ),

  GameEvent(
    id: 'kulup_futbol_penalti',
    category: EventCategory.okul,
    text: 'Penaltı. Topu alıp noktaya koydun; kaleci gülüyor.',
    requirement: EventRequirement(
      minAge: 11,
      maxAge: 19,
      requiresActiveClubId: 'futbol_takimi',
      minSquadRole: SquadRole.ilkOnBir,
    ),
    weight: 6,
    choices: <EventChoice>[
      EventChoice(
        id: 'kosede',
        label: 'Köşeye sert vur',
        resultText: 'Direğe çarpıp çıktı. Saha bir an sessizleşti, '
            'sonra oyun devam etti. Sen devam edemedin.',
        happiness: -5,
        charisma: -1,
        addFlags: <String>{ClubFlags.penaltiKacirdi},
      ),
      EventChoice(
        id: 'yavas',
        label: 'Kalecinin tersine yavaş yolla',
        resultText: 'Kaleci erken yattı, top boş filede durdu. '
            'Kutlamadın bile, sadece derin bir nefes aldın.',
        happiness: 7,
        charisma: 2,
      ),
      EventChoice(
        id: 'baskasi',
        label: 'Topu başkasına bırak',
        resultText: '"Sen vur" dedin. Attı. Doğru karar mıydı '
            'bilmiyorsun ama sorumluluk da onda kaldı.',
        happiness: 1,
        charisma: -1,
      ),
    ],
  ),

  // Penaltı kaçırmanın karşılığı — iz burada okunuyor.
  GameEvent(
    id: 'kulup_futbol_penalti_sonrasi',
    category: EventCategory.kisisel,
    text: 'Kaçırdığın penaltı iki haftadır aklından çıkmıyor. '
        'Antrenman bitti, saha boş.',
    requirement: EventRequirement(
      minAge: 11,
      maxAge: 19,
      requiresActiveClubId: 'futbol_takimi',
      requiredFlags: <String>{ClubFlags.penaltiKacirdi},
    ),
    weight: 8,
    choices: <EventChoice>[
      EventChoice(
        id: 'tek_basina_cali',
        label: 'Tek başına penaltı çalış',
        resultText: 'Elli top attın. Kırk üçü girdi. Hava karardığında '
            'kaleyi zar zor görüyordun ama korkun gitmişti.',
        happiness: 4,
        health: -1,
        intelligence: 1,
        removeFlags: <String>{ClubFlags.penaltiKacirdi},
      ),
      EventChoice(
        id: 'bir_daha_vurmam',
        label: '"Bir daha penaltıya çıkmam"',
        resultText: 'Kendine söz verdin. Sözü tutmak bazen kaybetmek '
            'oluyor.',
        happiness: -2,
        charisma: -2,
        removeFlags: <String>{ClubFlags.penaltiKacirdi},
      ),
    ],
  ),

  GameEvent(
    id: 'kulup_futbol_antrenor_tartismasi',
    category: EventCategory.okul,
    text: 'Antrenör seni oyundan aldı ve sebebini söylemedi. '
        'Kenarda otururken içinden bir şeyler geçti.',
    requirement: EventRequirement(
      minAge: 12,
      maxAge: 19,
      requiresActiveClubId: 'futbol_takimi',
      minClubYears: 1,
      forbiddenFlags: <String>{ClubFlags.antrenorleGerginlik},
    ),
    weight: 6,
    choices: <EventChoice>[
      EventChoice(
        id: 'sor',
        label: 'Maçtan sonra sebebini sor',
        resultText: '"Dinlenmen gerekiyordu" dedi, sonra bir şey daha '
            'ekledi: "Soruyu sorduğun iyi oldu."',
        charisma: 3,
        happiness: 2,
        intelligence: 1,
      ),
      EventChoice(
        id: 'ses_cikar',
        label: 'Orada tepki göster',
        resultText: 'Kenarda sesin yükseldi. Antrenman kıyafetini '
            'topladın. İki hafta kadroda yoktun.',
        happiness: -4,
        charisma: -2,
        addFlags: <String>{ClubFlags.antrenorleGerginlik},
      ),
      EventChoice(
        id: 'sus',
        label: 'Sus, çalışmaya devam et',
        resultText: 'Hiçbir şey demedin, antrenmana erken gelmeye '
            'başladın. Üçüncü hafta yine ilk on birdeydin.',
        happiness: 1,
        intelligence: 2,
      ),
    ],
  ),

  // Gerginliğin karşılığı.
  GameEvent(
    id: 'kulup_futbol_antrenor_barisma',
    category: EventCategory.okul,
    text: 'Antrenör koridorda durdurdu: "Konuşalım mı?"',
    requirement: EventRequirement(
      minAge: 12,
      maxAge: 19,
      requiresActiveClubId: 'futbol_takimi',
      requiredFlags: <String>{ClubFlags.antrenorleGerginlik},
      forbiddenFlags: <String>{ClubFlags.antrenorleDuzeldi},
    ),
    weight: 8,
    choices: <EventChoice>[
      EventChoice(
        id: 'konus',
        label: 'Konuş',
        resultText: 'İkiniz de biraz haksızdınız, ikiniz de bunu '
            'söylemediniz. Ama ertesi gün kadrodaydın.',
        happiness: 5,
        charisma: 3,
        addFlags: <String>{ClubFlags.antrenorleDuzeldi},
        removeFlags: <String>{ClubFlags.antrenorleGerginlik},
      ),
      EventChoice(
        id: 'gecistir',
        label: '"Gerek yok"',
        resultText: 'Omuz silktin, geçtin. O sezon bir daha ilk on '
            'bire girmedin.',
        happiness: -3,
        addFlags: <String>{ClubFlags.antrenorleDuzeldi},
        removeFlags: <String>{ClubFlags.antrenorleGerginlik},
      ),
    ],
  ),

  GameEvent(
    id: 'kulup_futbol_takim_arkadasi',
    category: EventCategory.okul,
    text: 'Antrenmanda sert bir ikili mücadeleden sonra {kisi} ile '
        'ağız dalaşına girdiniz. Diğerleri araya girdi.',
    requirement: EventRequirement(
      minAge: 11,
      maxAge: 19,
      requiresActiveClubId: 'futbol_takimi',
      // Uydurma isim yok: gerçek sınıf arkadaşı kaydı kullanılır.
      livingRelations: <RelationType>{RelationType.sinifArkadasi},
    ),
    weight: 6,
    choices: <EventChoice>[
      EventChoice(
        id: 'ozur',
        label: 'Önce sen el uzat',
        resultText: 'Elini uzattın. Bir an duraksadı, sonra sıktı. '
            'Maçta yan yana oynadınız.',
        happiness: 3,
        charisma: 3,
        bond: 6,
      ),
      EventChoice(
        id: 'inat',
        label: 'İnat et',
        resultText: 'Kimse özür dilemedi. Aynı takımda oynamaya devam '
            'ettiniz ama pas vermemeye özen gösterdiniz.',
        happiness: -2,
        bond: -7,
      ),
    ],
  ),

  GameEvent(
    id: 'kulup_futbol_turnuva',
    category: EventCategory.okul,
    text: 'Okullar arası turnuvaya katılıyorsunuz. İlk maç ilçenin '
        'iddialı takımıyla.',
    requirement: EventRequirement(
      minAge: 11,
      maxAge: 19,
      requiresActiveClubId: 'futbol_takimi',
      minClubYears: 1,
    ),
    repeatable: true,
    minAgeGap: 3,
    weight: 7,
    choices: <EventChoice>[
      EventChoice(
        id: 'hazirlan',
        label: 'Haftayı hazırlanarak geçir',
        resultText: 'Maça hazır çıktınız. Yarı finale kaldınız; '
            'orada bitti ama okulda bir hafta bunu konuştular.',
        happiness: 6,
        health: -2,
        charisma: 2,
        addFlags: <String>{ClubFlags.derecaAldi},
      ),
      EventChoice(
        id: 'normal',
        label: 'Olağan tempoda git',
        resultText: 'İlk maçta elendiniz. Dönüş otobüsü sessizdi.',
        happiness: -2,
      ),
    ],
  ),

  GameEvent(
    id: 'kulup_futbol_sakatlik',
    category: EventCategory.okul,
    text: 'Topa giderken ayağın takıldı. Bilek şişmeye başladı ve '
        'ağırlık veremiyorsun.',
    requirement: EventRequirement(
      minAge: 11,
      maxAge: 19,
      requiresActiveClubId: 'futbol_takimi',
      minClubYears: 1,
      forbiddenFlags: <String>{ClubFlags.sakatlandi},
    ),
    weight: 5,
    choices: <EventChoice>[
      EventChoice(
        id: 'dinlen',
        label: 'Doktora git, verilen süreyi bekle',
        resultText: 'Üç hafta oynamadın. Döndüğünde ritmin düşüktü ama '
            'bilek sağlamdı.',
        health: 2,
        happiness: -2,
        addFlags: <String>{ClubFlags.sakatlandi},
      ),
      EventChoice(
        id: 'erken_don',
        label: 'Bir hafta sonra sahaya dön',
        resultText: 'Acele ettin. Aynı bilek sezon içinde iki kez daha '
            'şişti.',
        health: -6,
        happiness: -1,
        addFlags: <String>{ClubFlags.sakatlandi},
      ),
    ],
  ),

  GameEvent(
    id: 'kulup_futbol_scout',
    category: EventCategory.okul,
    text: 'Maçtan sonra kenarda duran bir adam antrenörle konuştu ve '
        'senin adını sordu.\n\n'
        'Antrenör "bir kulüpten geldi" dedi, fazlasını söylemedi.',
    requirement: EventRequirement(
      minAge: 15,
      maxAge: 19,
      requiresActiveClubId: 'futbol_takimi',
      minClubYears: 2,
      minSquadRole: SquadRole.ilkOnBir,
      forbiddenFlags: <String>{ClubFlags.scoutIzledi},
    ),
    weight: 6,
    choices: <EventChoice>[
      EventChoice(
        id: 'ayni_sekilde_oyna',
        label: 'Bildiğin gibi oynamaya devam et',
        resultText: 'Sonraki maçta aynı adam yine geldi. Bir şey '
            'söylemedi; gelmesi bir şey söylüyordu.',
        happiness: 6,
        intelligence: 1,
        addFlags: <String>{ClubFlags.scoutIzledi},
      ),
      EventChoice(
        id: 'kendini_gostermeye_calis',
        label: 'Kendini göstermeye çalış',
        resultText: 'Fazla top tuttun, iki kolay pası kaçırdın. '
            'Antrenör devre arasında "sakin" dedi.',
        happiness: 2,
        charisma: -1,
        addFlags: <String>{ClubFlags.scoutIzledi},
      ),
    ],
  ),

  GameEvent(
    id: 'kulup_futbol_ders_catismasi',
    category: EventCategory.okul,
    text: 'Deneme sınavı cumartesi, turnuva maçı da cumartesi.\n\n'
        'İkisi birden olmuyor.',
    requirement: EventRequirement(
      minAge: 13,
      maxAge: 19,
      requiresSchoolStudent: true,
      requiresActiveClubId: 'futbol_takimi',
      minClubYears: 1,
    ),
    weight: 7,
    choices: <EventChoice>[
      EventChoice(
        id: 'maca_git',
        label: 'Maça git',
        resultText: 'Takım seni görünce rahatladı. Pazartesi sınav '
            'sonucu gelince sen rahatlamadın.',
        happiness: 3,
        intelligence: -2,
        charisma: 2,
        addFlags: <String>{ClubFlags.sporuSecti},
      ),
      EventChoice(
        id: 'sinava_git',
        label: 'Sınava gir',
        resultText: 'Salonda otururken aklın sahadaydı. Puanın iyi '
            'geldi; takım o maçı kaybetti.',
        intelligence: 3,
        happiness: -2,
        addFlags: <String>{ClubFlags.dersiSecti},
      ),
    ],
  ),

  // ===================================================================
  // SATRANÇ
  // ===================================================================
  GameEvent(
    id: 'kulup_satranc_okul_turnuvasi',
    category: EventCategory.okul,
    text: 'Okul turnuvasının ilk turu. Karşındaki tahtaya oturdu ve '
        'saate dokunmadan bekliyor.',
    requirement: EventRequirement(
      minAge: 9,
      maxAge: 19,
      requiresActiveClubId: 'satranc_kulubu',
    ),
    repeatable: true,
    minAgeGap: 3,
    weight: 7,
    choices: <EventChoice>[
      EventChoice(
        id: 'sakin_oyna',
        label: 'Sakin oyna',
        resultText: 'Otuz hamlede kazandın. Rakip "nasıl gördün onu" '
            'diye sordu; sen de bilmiyordun.',
        intelligence: 3,
        happiness: 4,
      ),
      EventChoice(
        id: 'hizli_oyna',
        label: 'Hızlı oyna, baskı kur',
        resultText: 'İlk on hamlede öndeydin, yirmincide bir şeyi '
            'gözden kaçırdın. Saatin de suçu vardı.',
        intelligence: 1,
        happiness: -2,
      ),
    ],
  ),

  GameEvent(
    id: 'kulup_satranc_guclu_rakip',
    category: EventCategory.okul,
    text: 'Karşındaki il birincisi. Herkes maçı izlemeye geldi.',
    requirement: EventRequirement(
      minAge: 10,
      maxAge: 19,
      requiresActiveClubId: 'satranc_kulubu',
      minClubYears: 1,
      forbiddenFlags: <String>{ClubFlags.gucluRakip},
    ),
    weight: 7,
    choices: <EventChoice>[
      EventChoice(
        id: 'berabere_kabul',
        label: 'Beraberlik teklifini kabul et',
        resultText: 'Yirmi beşinci hamlede elini uzattı, sıktın. '
            'Kaybetmedin; bu da bir şeydi.',
        intelligence: 2,
        happiness: 3,
        addFlags: <String>{ClubFlags.gucluRakip},
      ),
      EventChoice(
        id: 'devam',
        label: 'Reddet, sonuna kadar oyna',
        resultText: 'Kırkıncı hamlede bir piyon geride kaldın ve '
            'kaybettin. Ama o kırk hamleyi uzun süre düşündün.',
        intelligence: 4,
        happiness: -1,
        addFlags: <String>{ClubFlags.gucluRakip},
      ),
    ],
  ),

  GameEvent(
    id: 'kulup_satranc_il_turnuvasi',
    category: EventCategory.okul,
    text: 'Kulüp seni il turnuvasına yazdırdı. Üç gün, altı tur.',
    requirement: EventRequirement(
      minAge: 11,
      maxAge: 19,
      requiresActiveClubId: 'satranc_kulubu',
      minClubYears: 2,
      requiredFlags: <String>{ClubFlags.gucluRakip},
    ),
    weight: 7,
    choices: <EventChoice>[
      EventChoice(
        id: 'git',
        label: 'Git',
        resultText: 'Altı turda üç buçuk puan topladın. Derece '
            'gelmedi ama dönüşte çantanda bir açılış kitabı vardı.',
        intelligence: 5,
        happiness: 4,
        health: -1,
        addFlags: <String>{ClubFlags.derecaAldi},
      ),
      EventChoice(
        id: 'gitme',
        label: 'Gitmeyeceğini söyle',
        resultText: 'Üç gün ders kaçırmak istemedin. Kulüp başkanı '
            '"sen bilirsin" dedi.',
        intelligence: 1,
        happiness: -1,
      ),
    ],
  ),

  // ===================================================================
  // SANAT VE AKADEMİ
  // ===================================================================
  GameEvent(
    id: 'kulup_muzik_gosteri',
    category: EventCategory.okul,
    text: 'Yıl sonu gösterisinde kulüp sahneye çıkacak. Provada '
        'sesin titredi.',
    requirement: EventRequirement(
      minAge: 9,
      maxAge: 19,
      requiresActiveClubId: 'muzik_kulubu',
    ),
    repeatable: true,
    minAgeGap: 4,
    weight: 7,
    choices: <EventChoice>[
      EventChoice(
        id: 'sahneye_cik',
        label: 'Sahneye çık',
        resultText: 'İlk sıra karanlıktı, o yüzden kolay oldu. '
            'Bitişte alkışı duydun ve ne çaldığını hatırlamadın.',
        happiness: 7,
        charisma: 3,
      ),
      EventChoice(
        id: 'arkada_kal',
        label: 'Arka sırada kal',
        resultText: 'Korodaydın, sesin duyulmadı ama sahnede sen de '
            'vardın.',
        happiness: 3,
        charisma: 1,
      ),
    ],
  ),

  GameEvent(
    id: 'kulup_tiyatro_rol',
    category: EventCategory.okul,
    text: 'Oyunun rolleri dağıtılıyor. Başrol için iki kişi kaldınız.',
    requirement: EventRequirement(
      minAge: 10,
      maxAge: 19,
      requiresActiveClubId: 'tiyatro_kulubu',
    ),
    weight: 7,
    choices: <EventChoice>[
      EventChoice(
        id: 'basrol_iste',
        label: 'Başrolü istediğini söyle',
        resultText: 'Metni iki gün ezberledin, seçmede baştan sona '
            'oynadın. Rol sende kaldı; prova gecelerin uzun oldu.',
        charisma: 5,
        happiness: 5,
        health: -1,
      ),
      EventChoice(
        id: 'yan_rol',
        label: 'Yan role razı ol',
        resultText: 'Üç repliğin vardı, üçünü de iyi söyledin. '
            'Kulisten izlemek de bir şeymiş.',
        charisma: 2,
        happiness: 3,
      ),
    ],
  ),

  GameEvent(
    id: 'kulup_robotik_yarisma',
    category: EventCategory.okul,
    text: 'Proje yarışmasına bir hafta kaldı ve düzenek hâlâ '
        'çalışmıyor.',
    requirement: EventRequirement(
      minAge: 12,
      maxAge: 19,
      requiresActiveClubId: 'robotik_kulubu',
    ),
    weight: 7,
    choices: <EventChoice>[
      EventChoice(
        id: 'gece_calis',
        label: 'Geceyi kulüpte geçir',
        resultText: 'Saat üçte motor döndü. Yarışmada ikinci oldunuz; '
            'birinci olan takımı da tebrik ettiniz.',
        intelligence: 5,
        happiness: 5,
        health: -3,
        addFlags: <String>{ClubFlags.derecaAldi},
      ),
      EventChoice(
        id: 'olani_goster',
        label: 'Olanı götür, idare et',
        resultText: 'Düzenek sahnede yarı yolda durdu. Jüri fikri '
            'beğendi, puanı vermedi.',
        intelligence: 2,
        happiness: -2,
      ),
    ],
  ),

  GameEvent(
    id: 'kulup_bilim_proje',
    category: EventCategory.okul,
    text: 'Bilim kulübü sergide bir deney gösterecek. Seninki '
        'provada iki kez tutmadı.',
    requirement: EventRequirement(
      minAge: 11,
      maxAge: 19,
      requiresActiveClubId: 'bilim_kulubu',
    ),
    weight: 6,
    choices: <EventChoice>[
      EventChoice(
        id: 'basitlestir',
        label: 'Deneyi basitleştir',
        resultText: 'Sadeleştirdin ve sergide kusursuz çalıştı. '
            'Küçük çocuklar en çok onu izledi.',
        intelligence: 3,
        happiness: 4,
      ),
      EventChoice(
        id: 'israr',
        label: 'Aynı deneyde ısrar et',
        resultText: 'Sergide de tutmadı. Yanındaki arkadaşın deneyi '
            'ilgi gördü; sen açıklamayı yaptın.',
        intelligence: 2,
        happiness: -1,
      ),
    ],
  ),

  GameEvent(
    id: 'kulup_munazara_kursu',
    category: EventCategory.okul,
    text: 'Münazarada savunmanı istediğin tarafı seçemedin: '
        'karşı olduğun görüşü savunacaksın.',
    requirement: EventRequirement(
      minAge: 12,
      maxAge: 19,
      requiresActiveClubId: 'munazara_kulubu',
    ),
    weight: 7,
    choices: <EventChoice>[
      EventChoice(
        id: 'savun',
        label: 'Elinden geleni yap',
        resultText: 'Kendi fikrinin en güçlü karşıtını kurmak zorunda '
            'kaldın. Kazandınız; kendi fikrin de biraz değişti.',
        intelligence: 4,
        charisma: 4,
      ),
      EventChoice(
        id: 'istemeyerek',
        label: 'İsteksiz savun',
        resultText: 'Konuşman kısa ve soğuk oldu. Jüri "inandırıcı '
            'değildi" dedi, haklıydı.',
        charisma: -1,
        intelligence: 1,
      ),
    ],
  ),

  GameEvent(
    id: 'kulup_atletizm_olcum',
    category: EventCategory.okul,
    text: 'Antrenör kronometreyi eline aldı: "Yüz metre, bir kez."',
    requirement: EventRequirement(
      minAge: 9,
      maxAge: 19,
      requiresActiveClubId: 'atletizm',
    ),
    repeatable: true,
    minAgeGap: 3,
    weight: 6,
    choices: <EventChoice>[
      EventChoice(
        id: 'sonuna_kadar',
        label: 'Sonuna kadar bas',
        resultText: 'Derecen beklediğinden iyi çıktı. Antrenör '
            'kâğıda bir şey yazdı ve göstermedi.',
        health: -1,
        happiness: 4,
      ),
      EventChoice(
        id: 'idare',
        label: 'İdareten koş',
        resultText: 'Ortalama bir derece. Kimse bir şey demedi, '
            'kimse de bir şey yazmadı.',
        happiness: 1,
      ),
    ],
  ),

  GameEvent(
    id: 'kulup_halk_oyunlari_gosteri',
    category: EventCategory.okul,
    text: '23 Nisan gösterisi için ekip kuruldu. Senin sıran ön '
        'sırada.',
    requirement: EventRequirement(
      minAge: 9,
      maxAge: 19,
      requiresActiveClubId: 'halk_oyunlari',
    ),
    weight: 6,
    choices: <EventChoice>[
      EventChoice(
        id: 'calis',
        label: 'Adımları çalış',
        resultText: 'Haftada üç gün prova. Gösteride ayak uydurdun ve '
            'velilerin arasında bir yerden fotoğraf makinesi sesi '
            'geldi.',
        happiness: 5,
        charisma: 3,
        health: 1,
      ),
      EventChoice(
        id: 'arkaya_gec',
        label: 'Arka sıraya geç',
        resultText: 'Arkada daha rahattı. Kimse yanlış adımını '
            'görmedi, doğru adımını da.',
        happiness: 2,
      ),
    ],
  ),

  GameEvent(
    id: 'kulup_fotograf_sergi',
    category: EventCategory.okul,
    text: 'Kulüp koridorda küçük bir sergi açıyor. Üç kare '
        'seçeceksin.',
    requirement: EventRequirement(
      minAge: 12,
      maxAge: 19,
      requiresActiveClubId: 'fotograf_kulubu',
    ),
    weight: 6,
    choices: <EventChoice>[
      EventChoice(
        id: 'kendi_secimin',
        label: 'Kendi beğendiklerini koy',
        resultText: 'Üçü de okulun sıradan köşeleriydi. En çok '
            'konuşulan kare o sıradan merdiven oldu.',
        happiness: 5,
        intelligence: 2,
      ),
      EventChoice(
        id: 'begenilecek',
        label: 'Beğenilecek olanları koy',
        resultText: 'Gün batımı, çiçek, bir de kedi. Kimse itiraz '
            'etmedi, kimse durup bakmadı da.',
        happiness: 1,
      ),
    ],
  ),

  GameEvent(
    id: 'kulup_basketbol_antrenman',
    category: EventCategory.okul,
    text: 'Salonda çift idman. Ayakkabının tabanı ikinci idmanda '
        'söküldü.',
    requirement: EventRequirement(
      minAge: 10,
      maxAge: 19,
      requiresActiveClubId: 'basketbol_takimi',
    ),
    weight: 6,
    choices: <EventChoice>[
      EventChoice(
        id: 'devam',
        label: 'Söküğü bantla, devam et',
        resultText: 'Bant bir idman dayandı. Antrenör görünce '
            '"yarın yenisini al" dedi, almadın ama sökük de büyümedi.',
        health: -1,
        happiness: 2,
      ),
      EventChoice(
        id: 'cik',
        label: 'İdmanı bırak',
        resultText: 'Kenara oturdun. Takım çift idmanı tamamladı, '
            'sen izledin.',
        happiness: -1,
      ),
    ],
  ),

  GameEvent(
    id: 'kulup_voleybol_servis',
    category: EventCategory.okul,
    text: 'Sayı eşit, servis sende. Salonda tek ses senin ayak '
        'sesin.',
    requirement: EventRequirement(
      minAge: 10,
      maxAge: 19,
      requiresActiveClubId: 'voleybol_takimi',
      minSquadRole: SquadRole.rotasyon,
    ),
    weight: 6,
    choices: <EventChoice>[
      EventChoice(
        id: 'sert',
        label: 'Sert at',
        resultText: 'Topa tam vurdun, karşı taraf karşılayamadı. '
            'Takım üstüne atladı.',
        happiness: 6,
        charisma: 2,
      ),
      EventChoice(
        id: 'guvenli',
        label: 'Güvenli at',
        resultText: 'Top geçti, ralli uzadı, sayıyı yine aldınız. '
            'Kimse servisi konuşmadı.',
        happiness: 3,
      ),
    ],
  ),

  GameEvent(
    id: 'kulup_masa_tenisi_koridor',
    category: EventCategory.okul,
    text: 'Koridordaki masada öğretmenlerden biri "bir el?" dedi.',
    requirement: EventRequirement(
      minAge: 9,
      maxAge: 19,
      requiresActiveClubId: 'masa_tenisi',
    ),
    weight: 6,
    choices: <EventChoice>[
      EventChoice(
        id: 'oyna',
        label: 'Oyna',
        resultText: 'İki set oynadınız, birini aldın. Teneffüs '
            'bitince etrafta on beş kişi vardı.',
        happiness: 5,
        charisma: 3,
      ),
      EventChoice(
        id: 'reddet',
        label: '"Dersim var"',
        resultText: 'Geçtin. Masa teneffüs boyunca doluydu, sen '
            'sınıfta oturdun.',
        happiness: -1,
        intelligence: 1,
      ),
    ],
  ),

  // Derece almanın karşılığı — iz burada okunuyor.
  GameEvent(
    id: 'kulup_derece_pano',
    category: EventCategory.okul,
    text: 'Okulun girişindeki panoya kulübün derecesi asıldı. '
        'Fotoğrafta sen de varsın.',
    requirement: EventRequirement(
      minAge: 10,
      maxAge: 19,
      requiresSchoolStudent: true,
      requiredFlags: <String>{ClubFlags.derecaAldi},
    ),
    weight: 6,
    choices: <EventChoice>[
      EventChoice(
        id: 'dur_bak',
        label: 'Durup bak',
        resultText: 'Birkaç saniye baktın, sonra yürüdün. O pano '
            'yıl sonuna kadar orada kaldı.',
        happiness: 5,
        charisma: 2,
        removeFlags: <String>{ClubFlags.derecaAldi},
      ),
      EventChoice(
        id: 'eve_soyle',
        label: 'Eve haber ver',
        resultText: 'Akşam masada anlattın. Telefonla fotoğrafını '
            'çekip akrabalara gönderdiler; sen utandın, onlar '
            'utanmadı.',
        happiness: 7,
        bond: 4,
        removeFlags: <String>{ClubFlags.derecaAldi},
      ),
    ],
  ),

  // Dersi seçmenin karşılığı. Bu olay olmadan `dersiSecti` sessiz bir iz
  // olarak kalıyordu ve bekçi testi yakaladı (AS/1 ölçütü).
  GameEvent(
    id: 'kulup_dersi_secmenin_sonucu',
    category: EventCategory.okul,
    text: 'Antrenör yoklama alırken durdu: "Sen o maça gelmedin."'
        '\n\nSitem değil, tespit.',
    requirement: EventRequirement(
      minAge: 14,
      maxAge: 19,
      requiredFlags: <String>{ClubFlags.dersiSecti},
    ),
    weight: 7,
    choices: <EventChoice>[
      EventChoice(
        id: 'anlat',
        label: 'Sebebini anlat',
        resultText: '"Sınavım vardı" dedin. Başını sallayıp geçti; '
            'ertesi hafta kadroda yine sen vardın.',
        charisma: 2,
        happiness: 3,
        removeFlags: <String>{ClubFlags.dersiSecti},
      ),
      EventChoice(
        id: 'sus',
        label: 'Bir şey deme',
        resultText: 'Omuz silktin. O sezon yedek kulübesinde biraz '
            'daha fazla oturdun.',
        happiness: -2,
        charisma: -1,
        removeFlags: <String>{ClubFlags.dersiSecti},
      ),
    ],
  ),

  // Okul-spor çatışmasının karşılığı.
  GameEvent(
    id: 'kulup_secimin_sonucu',
    category: EventCategory.kisisel,
    text: 'Karne elinde. O cumartesi verdiğin karar bu kâğıtta bir '
        'yere yazılmış gibi.',
    requirement: EventRequirement(
      minAge: 14,
      maxAge: 19,
      requiredFlags: <String>{ClubFlags.sporuSecti},
    ),
    weight: 7,
    choices: <EventChoice>[
      EventChoice(
        id: 'dengele',
        label: 'Bu yıl dengeyi kur',
        resultText: 'Bir programa oturdun: antrenman akşam, ders '
            'sabah. İkisi de tam olmadı ama ikisi de yürüdü.',
        intelligence: 3,
        happiness: 2,
        removeFlags: <String>{ClubFlags.sporuSecti},
      ),
      EventChoice(
        id: 'sporda_kal',
        label: 'Yine sporu seç',
        resultText: 'Tercihini biliyorsun artık. Ders notların orta '
            'kaldı, sahadaki yerin sağlamlaştı.',
        happiness: 4,
        intelligence: -1,
        removeFlags: <String>{ClubFlags.sporuSecti},
      ),
    ],
  ),
];

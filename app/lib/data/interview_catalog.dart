/// Mülakat soruları.
///
/// Her meslek için birkaç kısa, **tek doğru cevaplı** soru. Sorular işe ve
/// yaşa uygundur; yoruma açık veya iki cevabı da doğru sayılabilecek soru
/// yazılmamıştır.
///
/// Soru sayısı ve zorluk `prototypeOnly`'dir
/// (`docs/DESIGN_REVIEW_QUEUE.md`, Q-051).
library;

import 'package:flutter/foundation.dart';

@immutable
class InterviewQuestion {
  const InterviewQuestion({
    required this.id,
    required this.jobId,
    required this.text,
    required this.options,
    required this.correctIndex,
    required this.explanation,
  }) : assert(correctIndex >= 0);

  final String id;
  final String jobId;

  /// Mülakatçının sorusu.
  final String text;

  /// Seçenekler. Sıra sabittir; kaydedilip geri yüklenince değişmez.
  final List<String> options;

  /// Doğru seçeneğin sırası.
  final int correctIndex;

  /// Yanlış cevaptan sonra gösterilen kısa açıklama.
  final String explanation;

  String get correctOption => options[correctIndex];
}

const List<InterviewQuestion> kInterviewQuestions = <InterviewQuestion>[
  // --- Mağaza çalışanı ---------------------------------------------------
  InterviewQuestion(
    id: 'magaza_1',
    jobId: 'magaza_calisani',
    text: 'Müşteri 180 ₺ tutan alışveriş için 200 ₺ verdi. '
        'Para üstü ne kadar?',
    options: <String>['10 ₺', '20 ₺', '30 ₺', '25 ₺'],
    correctIndex: 1,
    explanation: '200 − 180 = 20 ₺.',
  ),
  InterviewQuestion(
    id: 'magaza_2',
    jobId: 'magaza_calisani',
    text: 'Rafta son kullanma tarihi yakın ürünlerle yeni gelenler var. '
        'Hangisi öne dizilir?',
    options: <String>[
      'Yeni gelenler',
      'Tarihi yakın olanlar',
      'Fiyatı yüksek olanlar',
      'Kutusu büyük olanlar',
    ],
    correctIndex: 1,
    explanation: 'Tarihi yakın ürünler öne alınır ki önce satılsın.',
  ),
  InterviewQuestion(
    id: 'magaza_3',
    jobId: 'magaza_calisani',
    text: 'Stok sayımında raftaki adet kayıttan az çıktı. İlk ne yaparsın?',
    options: <String>[
      'Kaydı raftaki sayıya göre değiştiririm',
      'Farkı yöneticiye bildirip sayımı tekrarlarım',
      'Eksik ürünü kendi cebimden tamamlarım',
      'Hiçbir şey yapmam, ertesi gün düzelir',
    ],
    correctIndex: 1,
    explanation: 'Fark bildirilir ve sayım tekrarlanır; kayıt keyfî '
        'değiştirilmez.',
  ),

  // --- Garson -------------------------------------------------------------
  InterviewQuestion(
    id: 'garson_1',
    jobId: 'garson',
    text: 'Müşteri "bu yemekte fındık var mı?" diye soruyor ama emin '
        'değilsin. Ne yaparsın?',
    options: <String>[
      'Yoktur derim, çoğunda olmuyor',
      'Mutfağa sorup kesin bilgiyle dönerim',
      'Müşteriye kendisi karar versin derim',
      'Başka bir yemek öneririm',
    ],
    correctIndex: 1,
    explanation: 'Alerji sorusunda tahmin yürütülmez; mutfaktan kesin '
        'bilgi alınır.',
  ),
  InterviewQuestion(
    id: 'garson_2',
    jobId: 'garson',
    text: 'Aynı anda üç masa seni çağırdı. Nasıl davranırsın?',
    options: <String>[
      'En yakın masaya gidip diğerlerini görmezden gelirim',
      'Hepsine göz teması kurup sırayla geleceğimi belirtirim',
      'Mutfağa çekilip kalabalık dağılsın diye beklerim',
      'En çok bahşiş bırakan masaya öncelik veririm',
    ],
    correctIndex: 1,
    explanation: 'Bekleyen masaya görüldüğünü hissettirmek şikâyeti '
        'azaltır.',
  ),
  InterviewQuestion(
    id: 'garson_3',
    jobId: 'garson',
    text: 'Siparişi yanlış getirdin, müşteri fark etti. Doğru yaklaşım?',
    options: <String>[
      'Özür dileyip doğrusunu hemen getiririm',
      'Mutfağı suçlarım',
      'Farkı görmezden gelirim',
      'Müşteriden yanlış olanı yemesini isterim',
    ],
    correctIndex: 0,
    explanation: 'Hata sahiplenilir ve hızlıca düzeltilir.',
  ),

  // --- Teknik servis ------------------------------------------------------
  InterviewQuestion(
    id: 'teknik_1',
    jobId: 'teknik_servis',
    text: 'Bir cihaz hiç açılmıyor. İlk kontrolün ne olur?',
    options: <String>[
      'Anakartı değiştiririm',
      'Güç kaynağını ve kabloyu kontrol ederim',
      'Cihazı sıfırlarım',
      'Müşteriye yenisini öneririm',
    ],
    correctIndex: 1,
    explanation: 'Arıza aramaya en basit ve en olası nedenden başlanır: '
        'güç.',
  ),
  InterviewQuestion(
    id: 'teknik_2',
    jobId: 'teknik_servis',
    text: 'Cihaz bazen çalışıp bazen kesiliyor. Bu belirti en çok neyi '
        'düşündürür?',
    options: <String>[
      'Yazılım ayarı',
      'Gevşek bağlantı veya temassızlık',
      'Kullanıcı hatası',
      'Renk ayarı',
    ],
    correctIndex: 1,
    explanation: 'Kesintili arıza genellikle temassızlık veya gevşek '
        'bağlantıdan gelir.',
  ),
  InterviewQuestion(
    id: 'teknik_3',
    jobId: 'teknik_servis',
    text: 'Onarıma başlamadan önce yapılması gereken nedir?',
    options: <String>[
      'Cihazın enerjisini kesmek',
      'Kapağı hızlıca açmak',
      'Müşteriye fatura kesmek',
      'Parçaları internetten sipariş etmek',
    ],
    correctIndex: 0,
    explanation: 'Elektrikli cihazda ilk adım enerjiyi kesmektir.',
  ),

  // --- Ressam / tasarımcı --------------------------------------------------
  InterviewQuestion(
    id: 'tasarim_1',
    jobId: 'ressam_tasarimci',
    text: 'Sarı ile mavi boyayı karıştırırsan hangi renk çıkar?',
    options: <String>['Turuncu', 'Yeşil', 'Mor', 'Kahverengi'],
    correctIndex: 1,
    explanation: 'Sarı + mavi = yeşil.',
  ),
  InterviewQuestion(
    id: 'tasarim_2',
    jobId: 'ressam_tasarimci',
    text: 'Renk çemberinde kırmızının karşısındaki tamamlayıcı renk '
        'hangisidir?',
    options: <String>['Mavi', 'Yeşil', 'Turuncu', 'Sarı'],
    correctIndex: 1,
    explanation: 'Kırmızının tamamlayıcısı yeşildir.',
  ),
  InterviewQuestion(
    id: 'tasarim_3',
    jobId: 'ressam_tasarimci',
    text: 'Bir afişte metnin okunaklı olması için en gerekli olan nedir?',
    options: <String>[
      'Yazı ile arka plan arasında yeterli kontrast',
      'Mümkün olduğunca çok yazı tipi kullanmak',
      'Metni sayfaya tam ortalamak',
      'Her satırı farklı renge boyamak',
    ],
    correctIndex: 0,
    explanation: 'Okunaklılığın temeli kontrasttır.',
  ),

  // --- Yazılım geliştirici -------------------------------------------------
  InterviewQuestion(
    id: 'yazilim_1',
    jobId: 'yazilim_gelistirici',
    text: 'Bir döngü `i = 0` ile başlayıp `i < 5` olduğu sürece çalışıyor '
        've her adımda `i` bir artıyor. Döngü kaç kez çalışır?',
    options: <String>['4', '5', '6', 'Sonsuz'],
    correctIndex: 1,
    explanation: 'i = 0,1,2,3,4 → beş kez çalışır.',
  ),
  InterviewQuestion(
    id: 'yazilim_2',
    jobId: 'yazilim_gelistirici',
    text: 'Bir listenin 3 elemanı var. Sıfırdan başlayan dizinde son '
        'elemanın dizini kaçtır?',
    options: <String>['1', '2', '3', '4'],
    correctIndex: 1,
    explanation: 'Dizinler 0, 1, 2 olur; sonuncusu 2.',
  ),
  InterviewQuestion(
    id: 'yazilim_3',
    jobId: 'yazilim_gelistirici',
    text: 'Program çalışırken beklenmedik bir değerde çöküyor. Hata '
        'ayıklamaya nasıl başlarsın?',
    options: <String>[
      'Hatayı yeniden üreten en küçük durumu bulurum',
      'Bütün kodu baştan yazarım',
      'Hata mesajını gizlerim',
      'Rastgele satırları silerim',
    ],
    correctIndex: 0,
    explanation: 'Önce hata güvenilir biçimde yeniden üretilir.',
  ),
  InterviewQuestion(
    id: 'yazilim_4',
    jobId: 'yazilim_gelistirici',
    text: 'Bir değişkenin değeri hiç değişmeyecekse ne yapılmalı?',
    options: <String>[
      'Sabit olarak tanımlanmalı',
      'Global olarak tanımlanmalı',
      'Her kullanımda yeniden hesaplanmalı',
      'Metne çevrilmeli',
    ],
    correctIndex: 0,
    explanation: 'Değişmeyen değer sabit olarak tanımlanır.',
  ),

  // --- Öğretmen -------------------------------------------------------------
  InterviewQuestion(
    id: 'ogretmen_1',
    jobId: 'ogretmen',
    text: 'Bir öğrenci konuyu anlamadığını söylüyor. İlk yaklaşımın ne '
        'olur?',
    options: <String>[
      'Aynı anlatımı daha yüksek sesle tekrarlarım',
      'Nerede takıldığını sorup oradan başlarım',
      'Sınıfın önünde uyarırım',
      'Konuyu atlayıp devam ederim',
    ],
    correctIndex: 1,
    explanation: 'Anlaşılmayan nokta bulunmadan tekrar etmek işe yaramaz.',
  ),
  InterviewQuestion(
    id: 'ogretmen_2',
    jobId: 'ogretmen',
    text: 'Soyut bir konuyu ilkokul öğrencisine anlatırken en etkili yol?',
    options: <String>[
      'Günlük hayattan somut örnek vermek',
      'Tanımı ezberletmek',
      'Daha uzun anlatmak',
      'Konuyu yazdırmak',
    ],
    correctIndex: 0,
    explanation: 'Somut örnek, soyut kavramı anlaşılır kılar.',
  ),
  InterviewQuestion(
    id: 'ogretmen_3',
    jobId: 'ogretmen',
    text: 'Sınıfta iki öğrenci tartışıyor. Doğru davranış hangisi?',
    options: <String>[
      'Sakin biçimde araya girip ikisini de dinlemek',
      'İkisini de sınıftan çıkarmak',
      'Görmezden gelmek',
      'Sınıfa tartışmayı oylatmak',
    ],
    correctIndex: 0,
    explanation: 'Önce sakinleştirip iki tarafı da dinlemek gerekir.',
  ),

  // --- Dövüş sanatları eğitmenliği (Paket 32) ---------------------------
  InterviewQuestion(
    id: 'karate_egitmeni_1',
    jobId: 'karate_egitmeni',
    text: 'Karatede öğrenci dereceleri hangi adla sayılır?',
    options: <String>['Dan', 'Kyu', 'Duan', 'Boy'],
    correctIndex: 1,
    explanation: 'Öğrenci dereceleri kyu, ustalık dereceleri dandır.',
  ),
  InterviewQuestion(
    id: 'karate_egitmeni_2',
    jobId: 'karate_egitmeni',
    text: 'Yeni başlayan bir çocuk ilk derste kata öğrenmek istiyor. '
        'Ne yaparsın?',
    options: <String>[
      'Hemen ileri bir kata öğretirim',
      'Önce duruş ve nefesle başlarım, katayı sırası gelince veririm',
      'Katayı hiç öğretmem',
      'Kendi başına çalışsın derim',
    ],
    correctIndex: 1,
    explanation: 'Temel oturmadan kata öğretmek sakatlık ve kötü alışkanlık '
        'getirir.',
  ),
  InterviewQuestion(
    id: 'karate_egitmeni_3',
    jobId: 'karate_egitmeni',
    text: 'Eşleşmeli çalışmada bir öğrenci kontrolsüz vuruyor. İlk tepkin?',
    options: <String>[
      'Çalışmayı durdurup kontrolü anlatırım',
      'Karşısındakine de sert vurmasını söylerim',
      'Görmezden gelirim',
      'Öğrenciyi salondan atarım',
    ],
    correctIndex: 0,
    explanation: 'Kontrol öğretilir; salonda amaç zarar vermek değildir.',
  ),

  InterviewQuestion(
    id: 'kungfu_egitmeni_1',
    jobId: 'kungfu_egitmeni',
    text: 'Çin wushu derecelendirmesinde kullanılan düzenin adı nedir?',
    options: <String>['Kyu', 'Duanwei', 'Kıspet', 'Poomsae'],
    correctIndex: 1,
    explanation: 'Duanwei, duan derecelerinden oluşan resmî düzendir.',
  ),
  InterviewQuestion(
    id: 'kungfu_egitmeni_2',
    jobId: 'kungfu_egitmeni',
    text: 'Temel hareket çalışmasına (jibengong) neden vakit ayrılır?',
    options: <String>[
      'Gösteriş olsun diye',
      'Duruş, denge ve dayanıklılık formların temelidir',
      'Dersi uzatmak için',
      'Gerekmez, doğrudan forma geçilir',
    ],
    correctIndex: 1,
    explanation: 'Formlar temel üstüne kurulur; temel zayıfsa form da zayıftır.',
  ),
  InterviewQuestion(
    id: 'kungfu_egitmeni_3',
    jobId: 'kungfu_egitmeni',
    text: 'Yaşlı bir öğrenci esnemekte zorlanıyor. Nasıl ilerletirsin?',
    options: <String>[
      'Zorla bastırıp açarım',
      'Sınıftan çıkarırım',
      'Kendi sınırında, kademeli ve düzenli çalıştırırım',
      'Esnemeyi tamamen bırakmasını söylerim',
    ],
    correctIndex: 2,
    explanation: 'Esneklik kademeyle gelir; zorlama sakatlar.',
  ),

  InterviewQuestion(
    id: 'gures_antrenoru_1',
    jobId: 'gures_antrenoru',
    text: 'Kırkpınar\'da en üst boy hangisidir?',
    options: <String>['Başaltı', 'Büyük orta', 'Baş (başpehlivan)', 'Deste'],
    correctIndex: 2,
    explanation: 'Boyların en üstü baştır; kazanan başpehlivan olur.',
  ),
  InterviewQuestion(
    id: 'gures_antrenoru_2',
    jobId: 'gures_antrenoru',
    text: 'Yağlı güreşte pehlivanın giydiği deri kıyafetin adı nedir?',
    options: <String>['Kıspet', 'Şalvar', 'Kemer', 'Zıbın'],
    correctIndex: 0,
    explanation: 'Kıspet, dana derisinden dikilen güreş kıyafetidir.',
  ),
  InterviewQuestion(
    id: 'gures_antrenoru_3',
    jobId: 'gures_antrenoru',
    text: 'Küçük yaştaki bir güreşçiyi hangi boyda çalıştırmaya başlarsın?',
    options: <String>[
      'Doğrudan başaltında',
      'Yaşına ve gelişimine uygun küçük boylarda',
      'Baş boyunda',
      'Boy fark etmez',
    ],
    correctIndex: 1,
    explanation: 'Boylar yaş ve gelişime göre ayrılır; atlamak sakatlık '
        'getirir.',
  ),
];

/// Bir mesleğin soruları.
List<InterviewQuestion> questionsForJob(String jobId) => kInterviewQuestions
    .where((InterviewQuestion q) => q.jobId == jobId)
    .toList(growable: false);

InterviewQuestion? interviewQuestionById(String id) {
  for (final InterviewQuestion q in kInterviewQuestions) {
    if (q.id == id) return q;
  }
  return null;
}

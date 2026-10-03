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
    text:
        'Müşteri 180 ₺ tutan alışveriş için 200 ₺ verdi. '
        'Para üstü ne kadar?',
    options: <String>['10 ₺', '20 ₺', '30 ₺', '25 ₺'],
    correctIndex: 1,
    explanation: '200 − 180 = 20 ₺.',
  ),
  InterviewQuestion(
    id: 'magaza_2',
    jobId: 'magaza_calisani',
    text:
        'Rafta son kullanma tarihi yakın ürünlerle yeni gelenler var. '
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
    explanation:
        'Fark bildirilir ve sayım tekrarlanır; kayıt keyfî '
        'değiştirilmez.',
  ),

  // --- Garson -------------------------------------------------------------
  InterviewQuestion(
    id: 'garson_1',
    jobId: 'garson',
    text:
        'Müşteri "bu yemekte fındık var mı?" diye soruyor ama emin '
        'değilsin. Ne yaparsın?',
    options: <String>[
      'Yoktur derim, çoğunda olmuyor',
      'Mutfağa sorup kesin bilgiyle dönerim',
      'Müşteriye kendisi karar versin derim',
      'Başka bir yemek öneririm',
    ],
    correctIndex: 1,
    explanation:
        'Alerji sorusunda tahmin yürütülmez; mutfaktan kesin '
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
    explanation:
        'Bekleyen masaya görüldüğünü hissettirmek şikâyeti '
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
    explanation:
        'Arıza aramaya en basit ve en olası nedenden başlanır: '
        'güç.',
  ),
  InterviewQuestion(
    id: 'teknik_2',
    jobId: 'teknik_servis',
    text:
        'Cihaz bazen çalışıp bazen kesiliyor. Bu belirti en çok neyi '
        'düşündürür?',
    options: <String>[
      'Yazılım ayarı',
      'Gevşek bağlantı veya temassızlık',
      'Kullanıcı hatası',
      'Renk ayarı',
    ],
    correctIndex: 1,
    explanation:
        'Kesintili arıza genellikle temassızlık veya gevşek '
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
    text:
        'Renk çemberinde kırmızının karşısındaki tamamlayıcı renk '
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
    text:
        'Bir döngü `i = 0` ile başlayıp `i < 5` olduğu sürece çalışıyor '
        've her adımda `i` bir artıyor. Döngü kaç kez çalışır?',
    options: <String>['4', '5', '6', 'Sonsuz'],
    correctIndex: 1,
    explanation: 'i = 0,1,2,3,4 → beş kez çalışır.',
  ),
  InterviewQuestion(
    id: 'yazilim_2',
    jobId: 'yazilim_gelistirici',
    text:
        'Bir listenin 3 elemanı var. Sıfırdan başlayan dizinde son '
        'elemanın dizini kaçtır?',
    options: <String>['1', '2', '3', '4'],
    correctIndex: 1,
    explanation: 'Dizinler 0, 1, 2 olur; sonuncusu 2.',
  ),
  InterviewQuestion(
    id: 'yazilim_3',
    jobId: 'yazilim_gelistirici',
    text:
        'Program çalışırken beklenmedik bir değerde çöküyor. Hata '
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
    text:
        'Bir öğrenci konuyu anlamadığını söylüyor. İlk yaklaşımın ne '
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

  // --- Aşçı ---------------------------------------------------------------
  InterviewQuestion(
    id: 'asci_1',
    jobId: 'asci',
    text: 'Çiğ tavuğu doğradığın tahtayı sonra ne için kullanırsın?',
    options: <String>[
      'Salata doğramak için, yıkamadan',
      'Hiçbiri; yıkanıp ayrı tahta kullanılır',
      'Ekmek dilimlemek için',
      'Peynir kesmek için',
    ],
    correctIndex: 1,
    explanation:
        'Çiğ et tahtası ayrı tutulur; çapraz bulaşma böyle '
        'önlenir.',
  ),
  InterviewQuestion(
    id: 'asci_2',
    jobId: 'asci',
    text: 'Dört kişilik tarifte 300 g pirinç var. On kişi için ne kadar?',
    options: <String>['600 g', '750 g', '900 g', '1200 g'],
    correctIndex: 1,
    explanation: '300 ÷ 4 = 75 g kişi başı; 75 × 10 = 750 g.',
  ),
  InterviewQuestion(
    id: 'asci_3',
    jobId: 'asci',
    text: 'Servise çıkacak çorbanın tuzu fazla kaçtı. İlk ne yaparsın?',
    options: <String>[
      'Olduğu gibi gönderirim, fark etmezler',
      'Şefe söyleyip miktarı artırarak dengelemeyi denerim',
      'Üstüne bol su ekleyip kapatırım',
      'Müşteriye tuzsuz olduğunu söylerim',
    ],
    correctIndex: 1,
    explanation: 'Hata saklanmaz; mutfakta söylenir ve düzeltilir.',
  ),

  // --- Kuaför -------------------------------------------------------------
  InterviewQuestion(
    id: 'kuafor_1',
    jobId: 'kuafor',
    text:
        'Müşteri "çok kısa istemiyorum" dedi ama tarif ettiği model '
        'kısa. Ne yaparsın?',
    options: <String>[
      'Modeli olduğu gibi uygularım',
      'Kesmeden önce ne kadar kısalacağını gösterip onayını alırım',
      'Kendi bildiğim modeli yaparım',
      'İşi almam',
    ],
    correctIndex: 1,
    explanation: 'Makas değmeden önce beklenti netleştirilir.',
  ),
  InterviewQuestion(
    id: 'kuafor_2',
    jobId: 'kuafor',
    text: 'Boya öncesi küçük bir tutamda deneme yapılmasının sebebi ne?',
    options: <String>[
      'Boyadan tasarruf etmek',
      'Renk tutuşunu ve alerjiyi önceden görmek',
      'Müşteriyi oyalamak',
      'Saçı yumuşatmak',
    ],
    correctIndex: 1,
    explanation:
        'Tutam denemesi hem rengi hem cilt tepkisini önceden '
        'gösterir.',
  ),
  InterviewQuestion(
    id: 'kuafor_3',
    jobId: 'kuafor',
    text:
        'Randevulu müşteri gelmişken sırasız biri "beş dakika sürer" '
        'diyor. Ne yaparsın?',
    options: <String>[
      'Randevusuzu alırım, hızlı olur',
      'Randevuluyu bitirir, sonra bakarım',
      'İkisini aynı anda yaparım',
      'Randevuluya beklemesini söylerim',
    ],
    correctIndex: 1,
    explanation: 'Randevu bir sözdür; sırayı bozmak bekleyene haksızlık.',
  ),

  // --- Muhasebeci ---------------------------------------------------------
  InterviewQuestion(
    id: 'muhasebeci_1',
    jobId: 'muhasebeci',
    text: '10.000 ₺ mal bedeline %20 KDV eklenirse fatura toplamı kaç olur?',
    options: <String>['10.200 ₺', '11.000 ₺', '12.000 ₺', '12.500 ₺'],
    correctIndex: 2,
    explanation: '10.000 × 0,20 = 2.000; toplam 12.000 ₺.',
  ),
  InterviewQuestion(
    id: 'muhasebeci_2',
    jobId: 'muhasebeci',
    text:
        'Çift taraflı kayıtta bir tutar borca yazıldıysa aynı tutar '
        'nereye yazılır?',
    options: <String>[
      'Hiçbir yere',
      'Aynı hesabın borcuna tekrar',
      'Başka bir hesabın alacağına',
      'Ertesi aya',
    ],
    correctIndex: 2,
    explanation:
        'Her borç kaydının karşılığında eşit tutarda alacak '
        'kaydı vardır.',
  ),
  InterviewQuestion(
    id: 'muhasebeci_3',
    jobId: 'muhasebeci',
    text: 'Patron gideri olduğundan yüksek göstermeni istiyor. Ne yaparsın?',
    options: <String>[
      'İsteneni yaparım, sorumluluk onun',
      'Yapmam; kaydı gerçeğe uygun tutarım',
      'Yarısı kadar şişiririm',
      'Belgeyi kaybederim',
    ],
    correctIndex: 1,
    explanation:
        'Kayıt gerçeği gösterir; bu meslekte tartışılmaz olan '
        'budur.',
  ),

  // --- Manken -------------------------------------------------------------
  InterviewQuestion(
    id: 'manken_1',
    jobId: 'manken',
    text: 'Defile provasında sana yürüyüş sırası veriliyor. Neden önemli?',
    options: <String>[
      'Önemli değil, herkes istediği gibi çıkar',
      'Koleksiyonun anlatım sırası ve sahnede çakışmama için',
      'Ücret sıraya göre belirlendiği için',
      'Fotoğrafçılar ilk çıkanı çektiği için',
    ],
    correctIndex: 1,
    explanation:
        'Sıra koleksiyonun anlatımıdır; ayrıca sahnede '
        'çakışmayı önler.',
  ),
  InterviewQuestion(
    id: 'manken_2',
    jobId: 'manken',
    text: 'Çekim sözleşmesinde "kullanım alanı" neyi belirler?',
    options: <String>[
      'Çekimin kaç saat süreceğini',
      'Fotoğrafın nerede ve ne kadar süre yayımlanabileceğini',
      'Kaç kişilik ekip geleceğini',
      'Kıyafeti kimin seçeceğini',
    ],
    correctIndex: 1,
    explanation:
        'Kullanım alanı, görüntünün nerede ve ne kadar süre '
        'yayımlanacağını belirler; ücreti de bu belirler.',
  ),
  InterviewQuestion(
    id: 'manken_3',
    jobId: 'manken',
    text:
        'Çekim günü sana sözleşmede olmayan bir poz isteniyor ve '
        'rahatsız hissediyorsun. Ne yaparsın?',
    options: <String>[
      'Yaparım, iş kaçmasın',
      'Sözleşmede olmadığını söyler, kabul etmem',
      'Sessizce çekimden ayrılırım',
      'Ajansı sonra ararım, o an yaparım',
    ],
    correctIndex: 1,
    explanation:
        'Sözleşme dışı istek reddedilebilir; sınır o an '
        'söylenir.',
  ),

  // --- Yazar --------------------------------------------------------------
  InterviewQuestion(
    id: 'yazar_1',
    jobId: 'yazar',
    text: 'Yayınevine gönderilen dosyada "telif" neyi anlatır?',
    options: <String>[
      'Kitabın kaç sayfa olacağını',
      'Eserin kime ait olduğunu ve satıştan yazara düşen payı',
      'Kapağın rengini',
      'Baskı sayısını',
    ],
    correctIndex: 1,
    explanation: 'Telif hem eserin sahipliği hem yazarın payıdır.',
  ),
  InterviewQuestion(
    id: 'yazar_2',
    jobId: 'yazar',
    text:
        'Başkasının cümlesini kendi kitabına kaynak göstermeden almak '
        'nedir?',
    options: <String>['İlham', 'İntihal', 'Alıntı', 'Derleme'],
    correctIndex: 1,
    explanation:
        'Kaynak gösterilmeden alınan metin intihaldir; '
        'gösterilirse alıntıdır.',
  ),
  InterviewQuestion(
    id: 'yazar_3',
    jobId: 'yazar',
    text:
        'Editör, çok sevdiğin bir bölümün kitaba bir şey katmadığını '
        'söylüyor. Ne yaparsın?',
    options: <String>[
      'Reddederim, benim kitabım',
      'Gerekçesini dinler, bölümü kitaba katkısına göre yeniden '
          'değerlendiririm',
      'Bütün kitabı baştan yazarım',
      'Başka yayınevi ararım',
    ],
    correctIndex: 1,
    explanation:
        'Editörün işi budur; karar yine yazarındır ama '
        'gerekçe dinlenir.',
  ),

  // --- Müzisyen -----------------------------------------------------------
  InterviewQuestion(
    id: 'muzisyen_1',
    jobId: 'muzisyen',
    text: '4/4 ölçüde bir tam nota kaç vuruş sürer?',
    options: <String>['1', '2', '4', '8'],
    correctIndex: 2,
    explanation:
        '4/4 ölçüde tam nota ölçünün tamamını, yani dört '
        'vuruşu doldurur.',
  ),
  InterviewQuestion(
    id: 'muzisyen_2',
    jobId: 'muzisyen',
    text: 'Sahneye çıkmadan önce akort neden yapılır?',
    options: <String>[
      'Alışkanlıktan',
      'Enstrümanın sesi sıcaklık ve taşımayla kaydığı için',
      'Seyirci beklesin diye',
      'Teller yenilensin diye',
    ],
    correctIndex: 1,
    explanation:
        'Sıcaklık, nem ve taşıma akordu kaydırır; sahne '
        'öncesi düzeltilir.',
  ),
  InterviewQuestion(
    id: 'muzisyen_3',
    jobId: 'muzisyen',
    text: 'Konserde bir arkadaşın ölçüyü kaçırdı. Ne yaparsın?',
    options: <String>[
      'Durup baştan başlarım',
      'Tempoyu koruyup onun dönmesini beklerim',
      'Sahnede uyarırım',
      'Ben de kaçırırım, belli olmasın',
    ],
    correctIndex: 1,
    explanation:
        'Tempoyu tutan kalır; kaçıran bir sonraki ölçüde '
        'döner.',
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
    text:
        'Yeni başlayan bir çocuk ilk derste kata öğrenmek istiyor. '
        'Ne yaparsın?',
    options: <String>[
      'Hemen ileri bir kata öğretirim',
      'Önce duruş ve nefesle başlarım, katayı sırası gelince veririm',
      'Katayı hiç öğretmem',
      'Kendi başına çalışsın derim',
    ],
    correctIndex: 1,
    explanation:
        'Temel oturmadan kata öğretmek sakatlık ve kötü alışkanlık '
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
    explanation:
        'Formlar temel üstüne kurulur; temel zayıfsa form da zayıftır.',
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
    explanation:
        'Boylar yaş ve gelişime göre ayrılır; atlamak sakatlık '
        'getirir.',
  ),

  // --- Yeni dövüş dalları (D-152) ---------------------------------------
  InterviewQuestion(
    id: 'boks_antrenoru_1',
    jobId: 'boks_antrenoru',
    text: 'Amatör boksta kategoriler neye göre ayrılır?',
    options: <String>[
      'Kuşak rengine göre',
      'Yaş ve sıklet grubuna göre',
      'Ders sayısına göre',
      'Salonun büyüklüğüne göre',
    ],
    correctIndex: 1,
    explanation: 'Amatör boksta ayrım yaş kategorisi ve sıklettir.',
  ),
  InterviewQuestion(
    id: 'boks_antrenoru_2',
    jobId: 'boks_antrenoru',
    text: 'Yeni başlayan bir sporcunun ilk haftaları neyle geçer?',
    options: <String>[
      'Doğrudan ringde maç yapar',
      'Duruş, ayak çalışması ve nefes',
      'Ağır torba çalışması',
      'Hiçbir şey, sadece seyreder',
    ],
    correctIndex: 1,
    explanation:
        'Duruş ve ayak oturmadan yapılan her şey hem boşa gider hem '
        'sakatlar.',
  ),
  InterviewQuestion(
    id: 'boks_antrenoru_3',
    jobId: 'boks_antrenoru',
    text:
        'Çalışma sırasında sporcu kafasına sert bir darbe aldı ve '
        'sersemledi. Ne yaparsın?',
    options: <String>[
      'Çalışmayı bitirmesini beklerim',
      'Çalışmayı hemen keser, dinlendirir ve hekime yönlendiririm',
      'Bir bardak su verip devam ettiririm',
      'Daha sert çalışmasını söylerim',
    ],
    correctIndex: 1,
    explanation:
        'Kafa darbesinde çalışma durur; karar antrenörün değil hekimin.',
  ),

  InterviewQuestion(
    id: 'judo_egitmeni_1',
    jobId: 'judo_egitmeni',
    text: 'Judoda öğrenci dereceleri hangi adla sayılır?',
    options: <String>['Dan', 'Kyu', 'Gup', 'Boy'],
    correctIndex: 1,
    explanation: 'Öğrenci dereceleri kyu, siyah kuşak sonrası dandır.',
  ),
  InterviewQuestion(
    id: 'judo_egitmeni_2',
    jobId: 'judo_egitmeni',
    text: 'İlk derslerde neden düşme çalışması (ukemi) öğretilir?',
    options: <String>[
      'Sıralama böyle olduğu için',
      'Sporcu güvenle düşmeyi öğrenmeden atılamaz',
      'Isınma sayıldığı için',
      'Gerekmez, doğrudan atışa geçilir',
    ],
    correctIndex: 1,
    explanation: 'Güvenli düşüş judonun ilk ve vazgeçilmez basamağıdır.',
  ),
  InterviewQuestion(
    id: 'judo_egitmeni_3',
    jobId: 'judo_egitmeni',
    text: 'Eşleşmede iki sporcunun kilo farkı çok fazlaysa ne yaparsın?',
    options: <String>[
      'Yine eşleştiririm, fark etmez',
      'Yakın kilodaki sporcularla eşleştiririm',
      'Küçük olanı çalıştırmam',
      'İkisini de gönderirim',
    ],
    correctIndex: 1,
    explanation:
        'Kilo farkı büyük eşleşme hem öğretmez hem sakatlık riski '
        'taşır.',
  ),

  InterviewQuestion(
    id: 'taekwondo_egitmeni_1',
    jobId: 'taekwondo_egitmeni',
    text: 'Taekwondoda öğrenci dereceleri hangi adla sayılır?',
    options: <String>['Kyu', 'Gup', 'Duan', 'Boy'],
    correctIndex: 1,
    explanation: 'Öğrenci dereceleri gup, siyah kuşak sonrası dandır.',
  ),
  InterviewQuestion(
    id: 'taekwondo_egitmeni_2',
    jobId: 'taekwondo_egitmeni',
    text: 'Poomsae nedir?',
    options: <String>[
      'Bir sıklet grubu',
      'Belirli sırayla yapılan hareket dizisi',
      'Kuşak sınavı ücreti',
      'Bir tekme çeşidi',
    ],
    correctIndex: 1,
    explanation:
        'Poomsae, belirli sırayla yapılan ve derecelerde sınanan '
        'hareket dizisidir.',
  ),
  InterviewQuestion(
    id: 'taekwondo_egitmeni_3',
    jobId: 'taekwondo_egitmeni',
    text:
        'Yüksek tekme çalışmasında esnekliği yetmeyen bir öğrenci var. '
        'Nasıl ilerlersin?',
    options: <String>[
      'Zorlayarak bacağını kaldırtırım',
      'Esnekliği kademeli çalıştırıp tekme yüksekliğini sonra artırırım',
      'O hareketi hiç öğretmem',
      'Başka salona gönderirim',
    ],
    correctIndex: 1,
    explanation:
        'Esneklik kademeli kazanılır; zorlamak sakatlıkla sonuçlanır.',
  ),
  InterviewQuestion(
    id: 'kasiyer_1',
    jobId: 'kasiyer',
    text:
        'Kasada 500 ₺ ile ödenen 236 ₺ tutarında alışverişin para üstü ne kadar?',
    options: <String>['164 ₺', '264 ₺', '274 ₺', '364 ₺'],
    correctIndex: 1,
    explanation: '500 − 236 = 264 ₺.',
  ),
  InterviewQuestion(
    id: 'kasiyer_2',
    jobId: 'kasiyer',
    text: 'Gün sonunda kasa 40 ₺ fazla çıktı. Ne yaparsın?',
    options: <String>[
      'Cebime atarım',
      'Tutanakla bildiririm',
      'Eksik çıkarsa denkleşir diye beklerim',
      'Bir müşteriye veririm',
    ],
    correctIndex: 1,
    explanation: 'Fark, eksik de olsa fazla da olsa bildirilir.',
  ),
  InterviewQuestion(
    id: 'kurye_1',
    jobId: 'kurye',
    text: 'Adreste kimse yok ve paket kapıda bırakılamaz. İlk ne yaparsın?',
    options: <String>[
      'Kapının önüne bırakırım',
      'Müşteriyi arar, olmazsa merkeze bildiririm',
      'Komşuya bırakırım',
      'Paketi atarım',
    ],
    correctIndex: 1,
    explanation: 'Önce alıcıya ulaşılır; olmazsa merkez karar verir.',
  ),
  InterviewQuestion(
    id: 'kurye_2',
    jobId: 'kurye',
    text: 'Teslimat sırasında kask takmanın sebebi ne?',
    options: <String>[
      'Şirket logosu görünsün diye',
      'Kazada kafa yaralanmasını azalttığı için',
      'Yağmurdan korunmak için',
      'Sadece şehir içinde kural olduğu için',
    ],
    correctIndex: 1,
    explanation: 'Kask, motosiklette en ölümcül yaralanmayı azaltır.',
  ),
  InterviewQuestion(
    id: 'depo_personeli_1',
    jobId: 'depo_personeli',
    text: 'Bir palette 12 koli, her koli 8 ürün var. Toplam kaç ürün?',
    options: <String>['80', '96', '108', '120'],
    correctIndex: 1,
    explanation: '12 × 8 = 96.',
  ),
  InterviewQuestion(
    id: 'depo_personeli_2',
    jobId: 'depo_personeli',
    text: 'Raf sisteminde ağır koliler nereye konur?',
    options: <String>[
      'En üst rafa',
      'Alt raflara',
      'Rastgele',
      'Kapının önüne',
    ],
    correctIndex: 1,
    explanation: 'Ağırlık altta durur: hem devrilme hem bel riski azalır.',
  ),
  InterviewQuestion(
    id: 'guvenlik_1',
    jobId: 'guvenlik',
    text:
        'Devriyede kilitli olması gereken bir kapıyı açık buldun. Ne yaparsın?',
    options: <String>[
      'Kapatır, geçerim',
      'Kapatır, kayda geçirir ve amire bildiririm',
      'Sabah söylerim',
      'Kamerayı kontrol eder, bir şey demem',
    ],
    correctIndex: 1,
    explanation: 'Kapatmak yetmez: kayıt ve bildirim olmadan iz kalmaz.',
  ),
  InterviewQuestion(
    id: 'guvenlik_2',
    jobId: 'guvenlik',
    text: 'Yangın alarmı çaldığında ilk önceliğin nedir?',
    options: <String>[
      'Eşyaları korumak',
      'İnsanların tahliyesi',
      'Kamera kayıtlarını almak',
      'Alarmı susturmak',
    ],
    correctIndex: 1,
    explanation: 'Önce can güvenliği; mal sonra gelir.',
  ),
  InterviewQuestion(
    id: 'cagri_merkezi_1',
    jobId: 'cagri_merkezi',
    text: 'Çok sinirli bir müşteri bağırıyor. İlk ne yaparsın?',
    options: <String>[
      'Hattı kapatırım',
      'Sözünü kesmeden dinler, sorunu özetleyip teyit ederim',
      'Ben de sesimi yükseltirim',
      'Beklemeye alırım',
    ],
    correctIndex: 1,
    explanation: 'Dinlemek ve özetlemek, çözüme giden ilk adımdır.',
  ),
  InterviewQuestion(
    id: 'cagri_merkezi_2',
    jobId: 'cagri_merkezi',
    text: 'Müşterinin sorusunun cevabını bilmiyorsun. Doğru davranış?',
    options: <String>[
      'Tahmin edip söylerim',
      'Bilmediğimi söyler, doğru birime aktarırım',
      'Konuyu değiştiririm',
      'Hattı düşürürüm',
    ],
    correctIndex: 1,
    explanation: 'Uydurulan cevap, cevapsızlıktan daha çok zarar verir.',
  ),
  InterviewQuestion(
    id: 'satis_danismani_1',
    jobId: 'satis_danismani',
    text: 'Müşterinin ihtiyacına uymayan ama pahalı bir ürün var. Ne yaparsın?',
    options: <String>[
      'Pahalıyı satarım, hedef tutar',
      'İhtiyaca uyanı öneririm',
      'Ailesine sorsun derim',
      'İkisini birden satarım',
    ],
    correctIndex: 1,
    explanation:
        'Yanlış satış bir kez kazandırır, müşteriyi temelli kaybettirir.',
  ),
  InterviewQuestion(
    id: 'satis_danismani_2',
    jobId: 'satis_danismani',
    text: '2.400 ₺ ürüne %25 indirim uygulanırsa fiyat ne olur?',
    options: <String>['1.600 ₺', '1.800 ₺', '2.000 ₺', '2.100 ₺'],
    correctIndex: 1,
    explanation: '2.400 × 0,75 = 1.800 ₺.',
  ),
  InterviewQuestion(
    id: 'resepsiyonist_1',
    jobId: 'resepsiyonist',
    text:
        'Rezervasyonu olan misafir geldi ama sistemde kayıt yok. Ne yaparsın?',
    options: <String>[
      'Kayıt yok deyip gönderirim',
      'Özür diler, belgesini ister ve müdüre danışarak çözüm ararım',
      'Boş odayı ücretsiz veririm',
      'Beklemesini söyler, unuturum',
    ],
    correctIndex: 1,
    explanation: 'Misafir bekletilmez; kayıt aranırken çözüm de aranır.',
  ),
  InterviewQuestion(
    id: 'resepsiyonist_2',
    jobId: 'resepsiyonist',
    text: 'Telefonda misafirin oda numarasını soran birine ne dersin?',
    options: <String>[
      'Söylerim',
      'Oda numarası verilmez; bağlamayı teklif ederim',
      'Adını sorar, sonra söylerim',
      'Resepsiyona gelsin derim',
    ],
    correctIndex: 1,
    explanation: 'Oda numarası güvenlik bilgisidir, telefonla paylaşılmaz.',
  ),
  InterviewQuestion(
    id: 'elektrikci_1',
    jobId: 'elektrikci',
    text: 'Panoda çalışmaya başlamadan önce yapılacak ilk iş nedir?',
    options: <String>[
      'Eldiven takmak',
      'Enerjiyi kesip kesik olduğunu ölçerek doğrulamak',
      'Sigortayı değiştirmek',
      'Fotoğraf çekmek',
    ],
    correctIndex: 1,
    explanation:
        'Şalter indirmek yetmez; gerilim yokluğu ölçülerek doğrulanır.',
  ),
  InterviewQuestion(
    id: 'elektrikci_2',
    jobId: 'elektrikci',
    text: 'Topraklama hattı ne işe yarar?',
    options: <String>[
      'Faturayı düşürür',
      'Kaçak akımı toprağa yönlendirip çarpılmayı önler',
      'Cihazı hızlandırır',
      'Kabloyu soğutur',
    ],
    correctIndex: 1,
    explanation: 'Topraklama kaçak akıma güvenli bir yol açar.',
  ),
  InterviewQuestion(
    id: 'oto_tamircisi_1',
    jobId: 'oto_tamircisi',
    text:
        'Fren balatası aşınmış bir aracın sahibi işi sonraya bırakmak istiyor. Ne yaparsın?',
    options: <String>[
      'Aracı olduğu gibi veririm',
      'Riski yazılı bildirir, aracın güvenli olmadığını söylerim',
      'Balatayı habersiz değiştiririm',
      'Freni sıkarım',
    ],
    correctIndex: 1,
    explanation: 'Karar müşterinin ama risk yazılı olarak bildirilir.',
  ),
  InterviewQuestion(
    id: 'oto_tamircisi_2',
    jobId: 'oto_tamircisi',
    text: 'Motor yağı neden düzenli değiştirilir?',
    options: <String>[
      'Rengi bozulduğu için',
      'Yağ zamanla özelliğini yitirip yağlamayı azalttığı için',
      'Deposu dolduğu için',
      'Yakıtı temizlediği için',
    ],
    correctIndex: 1,
    explanation: 'Eskiyen yağ yağlama ve soğutma görevini yapamaz.',
  ),
  InterviewQuestion(
    id: 'tesisatci_1',
    jobId: 'tesisatci',
    text: 'Doğalgaz kokusu alan bir eve çağrıldın. İlk ne yaparsın?',
    options: <String>[
      'Işığı açıp bakarım',
      'Ateşe ve elektrik düğmesine dokunmadan havalandırır, vanayı kaparım',
      'Çakmakla kaçak ararım',
      'Kombiyi çalıştırırım',
    ],
    correctIndex: 1,
    explanation:
        'Kıvılcım yaratan hiçbir şeye dokunulmaz; havalandırıp vana kapatılır.',
  ),
  InterviewQuestion(
    id: 'tesisatci_2',
    jobId: 'tesisatci',
    text: 'Su tesisatında kaçak en çok nerede aranır?',
    options: <String>[
      'Duvarın ortasında',
      'Ek yerleri ve bağlantılarda',
      'Boru ortasında',
      'Musluğun içinde',
    ],
    correctIndex: 1,
    explanation: 'Kaçak çoğunlukla birleşim noktalarından olur.',
  ),
  InterviewQuestion(
    id: 'kaynakci_1',
    jobId: 'kaynakci',
    text: 'Kaynak maskesi neden kullanılır?',
    options: <String>[
      'Yüz kirlenmesin diye',
      'Ark ışığı gözde kalıcı hasar yaptığı için',
      'Sıcaktan korunmak için',
      'Zorunlu olduğu için',
    ],
    correctIndex: 1,
    explanation: 'Ark ışığı korneayı yakar; maske şart.',
  ),
  InterviewQuestion(
    id: 'kaynakci_2',
    jobId: 'kaynakci',
    text: 'Kaynak yapılacak yüzey neden temizlenir?',
    options: <String>[
      'Güzel görünsün diye',
      'Pas ve yağ dikişi zayıflattığı için',
      'Daha hızlı olsun diye',
      'Elektrot az yansın diye',
    ],
    correctIndex: 1,
    explanation: 'Kirli yüzeyde dikiş tutmaz, gözenek yapar.',
  ),
  InterviewQuestion(
    id: 'cnc_operatoru_1',
    jobId: 'cnc_operatoru',
    text: 'Programı çalıştırmadan önce yapılan kuru çalıştırma neden yapılır?',
    options: <String>[
      'Makineyi ısıtmak için',
      'Takım çarpması olup olmayacağını kesim yapmadan görmek için',
      'Elektrik tasarrufu için',
      'Zorunlu olduğu için',
    ],
    correctIndex: 1,
    explanation:
        'Kuru çalıştırma, çarpışmayı parça ve takım kırılmadan gösterir.',
  ),
  InterviewQuestion(
    id: 'cnc_operatoru_2',
    jobId: 'cnc_operatoru',
    text: 'Ölçüsü toleransı aşan parça ne olur?',
    options: <String>[
      'Müşteriye gönderilir',
      'Hurdaya ya da düzeltmeye ayrılır',
      'Ortalama alınır',
      'Etiketi değiştirilir',
    ],
    correctIndex: 1,
    explanation: 'Tolerans dışı parça teslim edilmez.',
  ),
  InterviewQuestion(
    id: 'ofis_personeli_1',
    jobId: 'ofis_personeli',
    text: 'Aynı belgenin üç farklı sürümü dolaşıyor. Ne yaparsın?',
    options: <String>[
      'En yenisini kullanırım',
      'Tek bir güncel sürüm belirleyip diğerlerini arşivlerim',
      'Hepsini saklarım',
      'Herkese sorarım',
    ],
    correctIndex: 1,
    explanation: 'Tek doğru sürüm belirlenmezse herkes başka belgeye bakar.',
  ),
  InterviewQuestion(
    id: 'ofis_personeli_2',
    jobId: 'ofis_personeli',
    text: 'Gizli bir personel listesi yanlışlıkla sana geldi. Ne yaparsın?',
    options: <String>[
      'Okurum',
      'Göndereni uyarır, belgeyi paylaşmam',
      'Arkadaşıma iletirim',
      'Yazdırırım',
    ],
    correctIndex: 1,
    explanation: 'Yanlış gelen gizli belge okunmaz, paylaşılmaz, bildirilir.',
  ),
  InterviewQuestion(
    id: 'banka_personeli_1',
    jobId: 'banka_personeli',
    text:
        '100.000 ₺ mevduata yıllık %40 basit faiz uygulanırsa bir yılda faiz ne kadar?',
    options: <String>['4.000 ₺', '14.000 ₺', '40.000 ₺', '140.000 ₺'],
    correctIndex: 2,
    explanation: '100.000 × 0,40 = 40.000 ₺.',
  ),
  InterviewQuestion(
    id: 'banka_personeli_2',
    jobId: 'banka_personeli',
    text: 'Müşteri telefonda şifresini söylemek istiyor. Ne yaparsın?',
    options: <String>[
      'Not alırım',
      'Şifrenin kimseyle paylaşılmaması gerektiğini söylerim',
      'Sisteme girerim',
      'Amirime iletirim',
    ],
    correctIndex: 1,
    explanation: 'Şifre personelle bile paylaşılmaz.',
  ),
  InterviewQuestion(
    id: 'ik_uzmani_1',
    jobId: 'ik_uzmani',
    text: 'Mülakatta adaya sorulmaması gereken soru hangisidir?',
    options: <String>[
      'Önceki işinizdeki göreviniz neydi',
      'Evlenmeyi ya da çocuk yapmayı düşünüyor musunuz',
      'Kendinizi nerede görüyorsunuz',
      'Hangi programları kullanıyorsunuz',
    ],
    correctIndex: 1,
    explanation:
        'Özel hayata ve aile planına dair sorular işe alımda ayrımcılık doğurur.',
  ),
  InterviewQuestion(
    id: 'ik_uzmani_2',
    jobId: 'ik_uzmani',
    text: 'İşe alınmayan adaya geri dönüş yapmak neden önemlidir?',
    options: <String>[
      'Zorunlu olduğu için',
      'Adayı belirsizlikte bırakmamak ve kurumun adını korumak için',
      'Dosyayı kapatmak için',
      'Hukuken gerektiği için',
    ],
    correctIndex: 1,
    explanation: 'Cevapsız bırakmak hem adaya haksızlık hem kuruma zarar.',
  ),
  InterviewQuestion(
    id: 'hemsire_1',
    jobId: 'hemsire',
    text: 'İlaç uygulamadan önce doğrulanan temel kontrol nedir?',
    options: <String>[
      'İlacın rengi',
      'Doğru hasta, doğru ilaç, doğru doz, doğru yol, doğru zaman',
      'Kutunun markası',
      'Hastanın mesleği',
    ],
    correctIndex: 1,
    explanation: 'Beş doğru kuralı ilaç hatalarını önlemenin temelidir.',
  ),
  InterviewQuestion(
    id: 'hemsire_2',
    jobId: 'hemsire',
    text: 'Nöbet devrinde hastayı teslim ederken en kritik şey nedir?',
    options: <String>[
      'Odayı toplamak',
      'Değişen durumları ve bekleyen işlemleri eksiksiz aktarmak',
      'Dosyayı imzalamak',
      'Erken çıkmak',
    ],
    correctIndex: 1,
    explanation: 'Devirde eksik aktarılan bilgi doğrudan hastaya zarar verir.',
  ),
  InterviewQuestion(
    id: 'doktor_1',
    jobId: 'doktor',
    text: 'Hastaya kötü bir tanıyı bildirirken doğru yaklaşım nedir?',
    options: <String>[
      'Bildirmemek',
      'Uygun bir ortamda, anlayacağı dille ve sorularına yer bırakarak anlatmak',
      'Yakınına söyleyip geçmek',
      'Raporu uzatmak',
    ],
    correctIndex: 1,
    explanation:
        'Hastanın kendi durumunu bilme hakkı vardır; anlatım biçimi önemlidir.',
  ),
  InterviewQuestion(
    id: 'doktor_2',
    jobId: 'doktor',
    text: 'Hasta mahremiyeti ne zaman ihlal edilmiş olur?',
    options: <String>[
      'Dosyayı meslektaşla tedavi için konuşunca',
      'Tedaviyle ilgisi olmayan birine hastanın durumunu anlatınca',
      'Konsültasyon isteyince',
      'Rapor yazınca',
    ],
    correctIndex: 1,
    explanation: 'Tedaviyle ilgisi olmayan hiç kimseye bilgi verilmez.',
  ),
  InterviewQuestion(
    id: 'psikolog_1',
    jobId: 'psikolog',
    text: 'Danışan kendine zarar verme niyetini açıkça söyledi. Ne yaparsın?',
    options: <String>[
      'Gizlilik gereği hiçbir şey yapmam',
      'Risk değerlendirmesi yapar, gerekirse gizliliği aşıp koruyucu adım atarım',
      'Seansı bitiririm',
      'Ailesine her şeyi anlatırım',
    ],
    correctIndex: 1,
    explanation:
        'Gizlilik mutlak değildir; can güvenliği söz konusuysa korumaya öncelik verilir.',
  ),
  InterviewQuestion(
    id: 'psikolog_2',
    jobId: 'psikolog',
    text: 'Danışanla seans dışında yakın arkadaşlık kurmak neden sakıncalı?',
    options: <String>[
      'Zaman aldığı için',
      'İkili ilişki tarafsızlığı ve danışanın güvenliğini bozduğu için',
      'Ücretlendirmeyi zorlaştırdığı için',
      'Sakıncası yok',
    ],
    correctIndex: 1,
    explanation:
        'Çifte ilişki, terapinin dayandığı sınırları ortadan kaldırır.',
  ),
  InterviewQuestion(
    id: 'eczaci_1',
    jobId: 'eczaci',
    text:
        'Reçetedeki doz, o ilacın bilinen üst sınırının çok üstünde. Ne yaparsın?',
    options: <String>[
      'Aynen veririm',
      'Hekimle teyit etmeden vermem',
      'Yarısını veririm',
      'Muadilini veririm',
    ],
    correctIndex: 1,
    explanation: 'Şüpheli doz hekimle teyit edilmeden karşılanmaz.',
  ),
  InterviewQuestion(
    id: 'eczaci_2',
    jobId: 'eczaci',
    text: 'Antibiyotiğin reçetesiz verilmemesinin sebebi ne?',
    options: <String>[
      'Pahalı olduğu için',
      'Gereksiz kullanım direnç geliştirdiği için',
      'Stok az olduğu için',
      'Saklaması zor olduğu için',
    ],
    correctIndex: 1,
    explanation:
        'Kontrolsüz kullanım, ilacın gerektiğinde işe yaramamasına yol açar.',
  ),
  InterviewQuestion(
    id: 'veri_analisti_1',
    jobId: 'veri_analisti',
    text: 'Bir sütunun ortalaması 50, ortancası 12. Bu ne anlatır?',
    options: <String>[
      'Veri hatasız',
      'Birkaç çok büyük değer ortalamayı yukarı çekiyor',
      'Veri eksik',
      'Ortalama yanlış hesaplanmış',
    ],
    correctIndex: 1,
    explanation: 'Ortalama uç değerlerden etkilenir; ortanca etkilenmez.',
  ),
  InterviewQuestion(
    id: 'veri_analisti_2',
    jobId: 'veri_analisti',
    text: 'İki değişken birlikte artıyor. Bu neyi kanıtlar?',
    options: <String>[
      'Biri diğerine sebep olur',
      'Aralarında ilişki olabilir ama nedensellik kanıtlanmaz',
      'Hiçbir şey',
      'Ölçüm hatalıdır',
    ],
    correctIndex: 1,
    explanation: 'Birliktelik nedensellik değildir.',
  ),
  InterviewQuestion(
    id: 'elektrik_muhendisi_1',
    jobId: 'elektrik_muhendisi',
    text: 'Bir devrede 12 V gerilim ve 4 Ω direnç varsa akım kaç amperdir?',
    options: <String>['0,33 A', '3 A', '16 A', '48 A'],
    correctIndex: 1,
    explanation: 'I = V / R = 12 / 4 = 3 A.',
  ),
  InterviewQuestion(
    id: 'elektrik_muhendisi_2',
    jobId: 'elektrik_muhendisi',
    text: 'Sigortanın görevi nedir?',
    options: <String>[
      'Gerilimi yükseltmek',
      'Aşırı akımda devreyi açarak tesisatı korumak',
      'Akımı düzleştirmek',
      'Enerji biriktirmek',
    ],
    correctIndex: 1,
    explanation: 'Sigorta aşırı akımda devreyi keser.',
  ),
  InterviewQuestion(
    id: 'insaat_muhendisi_1',
    jobId: 'insaat_muhendisi',
    text: 'Betonun kür edilmesi ne demektir?',
    options: <String>[
      'Kalıba dökmek',
      'Priz süresince nemli tutup dayanım kazanmasını sağlamak',
      'Hızla kurutmak',
      'Renklendirmek',
    ],
    correctIndex: 1,
    explanation: 'Beton nemli ortamda dayanım kazanır; erken kuruma çatlatır.',
  ),
  InterviewQuestion(
    id: 'insaat_muhendisi_2',
    jobId: 'insaat_muhendisi',
    text:
        'Projeye aykırı bir imalat gördün ve devam etmen isteniyor. Ne yaparsın?',
    options: <String>[
      'Devam ederim',
      'Yazılı olarak durdurur, proje müellifine bildiririm',
      'Görmezden gelirim',
      'Kendim düzeltirim',
    ],
    correctIndex: 1,
    explanation: 'İmza atan mühendis sorumludur; aykırılık yazılı bildirilir.',
  ),
  InterviewQuestion(
    id: 'makine_muhendisi_1',
    jobId: 'makine_muhendisi',
    text: 'Bir yatakta aşırı ısınma görülüyor. İlk bakılacak şey nedir?',
    options: <String>['Rengi', 'Yağlama ve hizalama', 'Boyası', 'Markası'],
    correctIndex: 1,
    explanation:
        'Isınmanın en sık sebebi yetersiz yağlama ya da hizasızlıktır.',
  ),
  InterviewQuestion(
    id: 'makine_muhendisi_2',
    jobId: 'makine_muhendisi',
    text: 'Emniyet katsayısı neden birden büyük seçilir?',
    options: <String>[
      'Maliyeti artırmak için',
      'Malzeme, yük ve üretimdeki belirsizliklere pay bırakmak için',
      'Ağırlık kazandırmak için',
      'Standart olduğu için',
    ],
    correctIndex: 1,
    explanation: 'Gerçek koşullar hesaptan sapar; pay bırakılır.',
  ),
  InterviewQuestion(
    id: 'polis_1',
    jobId: 'polis',
    text: 'Olay yerinde delil olabilecek bir nesne var. Ne yaparsın?',
    options: <String>[
      'Alıp cebime koyarım',
      'Dokunmadan koruma altına alır, kayıt tutarım',
      'Fotoğraf çekip bırakırım',
      'Sahibine veririm',
    ],
    correctIndex: 1,
    explanation: 'Delil, kayıt zinciri bozulmadan korunur.',
  ),
  InterviewQuestion(
    id: 'polis_2',
    jobId: 'polis',
    text: 'Yakalanan kişiye hakları neden bildirilir?',
    options: <String>[
      'Formalite olduğu için',
      'Bildirilmezse işlem hukuka aykırı hâle geldiği için',
      'Kişi istediği için',
      'Süreyi uzatmak için',
    ],
    correctIndex: 1,
    explanation: 'Hakların bildirilmemesi bütün işlemi sakatlar.',
  ),
  InterviewQuestion(
    id: 'itfaiyeci_1',
    jobId: 'itfaiyeci',
    text: 'Yağ yangınına su dökülmemesinin sebebi nedir?',
    options: <String>[
      'Suyu israf etmemek için',
      'Su yağın üstünde buharlaşıp alevi patlatarak yaydığı için',
      'Yağı soğuttuğu için',
      'Duman yaptığı için',
    ],
    correctIndex: 1,
    explanation: 'Kızgın yağa su, ani buharlaşmayla alevi patlatır.',
  ),
  InterviewQuestion(
    id: 'itfaiyeci_2',
    jobId: 'itfaiyeci',
    text: 'Dumanlı bir koridorda ilerlerken neden alçalırsın?',
    options: <String>[
      'Daha hızlı olduğu için',
      'Sıcak duman yükseldiği için alt katmanda daha temiz hava kaldığından',
      'Görüş açısı geniş olduğu için',
      'Kural olduğu için',
    ],
    correctIndex: 1,
    explanation: 'Duman yükselir; temiz hava tabana yakındır.',
  ),
  InterviewQuestion(
    id: 'memur_1',
    jobId: 'memur',
    text: 'Vatandaş eksik evrakla başvurdu. Doğru davranış?',
    options: <String>[
      'Reddedip gönderirim',
      'Eksiği yazılı bildirip nasıl tamamlanacağını anlatırım',
      'Kendim doldururum',
      'Kabul eder, sonra unuturum',
    ],
    correctIndex: 1,
    explanation:
        'Eksik, ne olduğu ve nasıl tamamlanacağı ile birlikte bildirilir.',
  ),
  InterviewQuestion(
    id: 'memur_2',
    jobId: 'memur',
    text: 'Bir başvuruyu tanıdığın diye sıranın önüne almak nedir?',
    options: <String>[
      'Yardımseverlik',
      'Eşitlik ilkesinin ihlali',
      'Hız kazandırma',
      'Olağan uygulama',
    ],
    correctIndex: 1,
    explanation: 'Sıra, herkes için aynı kurala göre işler.',
  ),
  InterviewQuestion(
    id: 'grafik_tasarimci_1',
    jobId: 'grafik_tasarimci',
    text:
        'Müşteri internetten bulduğu bir görseli tasarımda kullanmanı istiyor. Ne yaparsın?',
    options: <String>[
      'Kullanırım',
      'Kullanım hakkı olmadan koymam, lisanslı ya da özgün görsel öneririm',
      'Biraz değiştirip kullanırım',
      'Küçük basarım',
    ],
    correctIndex: 1,
    explanation: 'Hakkı alınmamış görsel kullanmak telif ihlalidir.',
  ),
  InterviewQuestion(
    id: 'grafik_tasarimci_2',
    jobId: 'grafik_tasarimci',
    text: 'Baskıya gidecek dosyada hangi renk uzayı kullanılır?',
    options: <String>['RGB', 'CMYK', 'HSL', 'Gri ton'],
    correctIndex: 1,
    explanation: 'Baskı dört renk mürekkeple çalışır: CMYK.',
  ),
  InterviewQuestion(
    id: 'gazeteci_1',
    jobId: 'gazeteci',
    text: 'Elinde tek kaynaklı çarpıcı bir iddia var. Ne yaparsın?',
    options: <String>[
      'Hemen yayımlarım',
      'İkinci bağımsız kaynakla teyit etmeden yayımlamam',
      'Kaynağı açıklarım',
      'İddia diye yazarım',
    ],
    correctIndex: 1,
    explanation: 'Teyit edilmemiş iddia haber değildir.',
  ),
  InterviewQuestion(
    id: 'gazeteci_2',
    jobId: 'gazeteci',
    text:
        'Kaynağını gizli tutacağına söz verdin, sonra baskı geldi. Ne yaparsın?',
    options: <String>[
      'Açıklarım',
      'Sözümü tutarım',
      'Yöneticime söylerim',
      'İmalı yazarım',
    ],
    correctIndex: 1,
    explanation: 'Kaynağın korunması, gazeteciliğin çalışabilmesinin şartıdır.',
  ),
  InterviewQuestion(
    id: 'fotografci_1',
    jobId: 'fotografci',
    text:
        'Sokakta çektiğin bir kişinin fotoğrafını reklamda kullanmak için ne gerekir?',
    options: <String>[
      'Hiçbir şey',
      'Kişinin izni',
      'Sadece yüzü bulanıklaştırmak',
      'Fotoğrafı satın almak',
    ],
    correctIndex: 1,
    explanation: 'Ticari kullanım için kişinin rızası gerekir.',
  ),
  InterviewQuestion(
    id: 'fotografci_2',
    jobId: 'fotografci',
    text: 'Düşük ışıkta hangi ayar görüntü gürültüsünü artırır?',
    options: <String>[
      'Diyaframı açmak',
      'ISO değerini yükseltmek',
      'Tripod kullanmak',
      'Objektif değiştirmek',
    ],
    correctIndex: 1,
    explanation: 'ISO yükseldikçe görüntü gürültüsü artar.',
  ),
  InterviewQuestion(
    id: 'kasiyer_3',
    jobId: 'kasiyer',
    text: 'Müşteri fişte olmayan bir indirim olduğunu söylüyor. Ne yaparsın?',
    options: <String>[
      'Tartışırım',
      'Kampanyayı kontrol eder, haklıysa farkı iade ederim',
      'Müdürü beklemesini söylerim',
      'İndirimi kendim uygularım',
    ],
    correctIndex: 1,
    explanation: 'Önce kontrol, sonra düzeltme.',
  ),
  InterviewQuestion(
    id: 'kurye_3',
    jobId: 'kurye',
    text: 'Aynı bölgede beş teslimatın var. Nasıl sıralarsın?',
    options: <String>[
      'Geliş sırasına göre',
      'Güzergâhı en kısa tutacak şekilde',
      'En pahalıdan başlayarak',
      'Rastgele',
    ],
    correctIndex: 1,
    explanation: 'Güzergâh sıralaması hem yakıt hem zaman kazandırır.',
  ),
  InterviewQuestion(
    id: 'depo_personeli_3',
    jobId: 'depo_personeli',
    text: 'Gelen malın irsaliyesi ile sayım tutmuyor. Ne yaparsın?',
    options: <String>[
      'İrsaliyeyi imzalarım',
      'İmzalamadan farkı tutanakla bildiririm',
      'Farkı görmezden gelirim',
      'Kendi cebimden tamamlarım',
    ],
    correctIndex: 1,
    explanation: 'İmza atılan irsaliye sorumluluk doğurur; fark önce yazılır.',
  ),
  InterviewQuestion(
    id: 'guvenlik_3',
    jobId: 'guvenlik',
    text: 'Kimliği olmayan biri içeri girmek istiyor ve acelesi var. Ne yaparsın?',
    options: <String>[
      'Alırım, acelesi var',
      'Kayıt olmadan almam, ilgili kişiye teyit ettiririm',
      'Tanıdıksa alırım',
      'Kapıyı açık bırakırım',
    ],
    correctIndex: 1,
    explanation: 'Acele, giriş kaydının yerine geçmez.',
  ),
  InterviewQuestion(
    id: 'cagri_merkezi_3',
    jobId: 'cagri_merkezi',
    text: 'Görüşme kaydının tutulduğunu müşteriye söylemek neden gerekir?',
    options: <String>[
      'Süreyi uzatmak için',
      'Kişinin kaydedildiğini bilme hakkı olduğu için',
      'Zorunlu olmadığı için',
      'Şikâyeti azalttığı için',
    ],
    correctIndex: 1,
    explanation: 'Kayıt, kişiye bildirilmeden tutulamaz.',
  ),
  InterviewQuestion(
    id: 'satis_danismani_3',
    jobId: 'satis_danismani',
    text: 'Müşteri satın aldıktan üç gün sonra iade istiyor. Ne yaparsın?',
    options: <String>[
      'Reddederim',
      'Cayma hakkı süresini kontrol eder, hakkı varsa iade alırım',
      'Sadece değişim yaparım',
      'Müdüre gönderirim',
    ],
    correctIndex: 1,
    explanation: 'İade hakkı keyfî değil, süreye bağlıdır.',
  ),
  InterviewQuestion(
    id: 'resepsiyonist_3',
    jobId: 'resepsiyonist',
    text: 'Aynı anda telefon çalıyor ve önünde misafir bekliyor. Ne yaparsın?',
    options: <String>[
      'Telefonu açarım',
      'Misafirden izin ister, telefonu kısa tutup ona dönerim',
      'Telefonu açmam',
      'Misafiri beklerim',
    ],
    correctIndex: 1,
    explanation: 'Karşındaki insan önceliklidir ama telefon da kayıtsız bırakılmaz.',
  ),
  InterviewQuestion(
    id: 'elektrikci_3',
    jobId: 'elektrikci',
    text: 'Tek bir prizde sürekli sigorta atıyor. İlk düşünülecek sebep nedir?',
    options: <String>[
      'Priz eski',
      'O hatta aşırı yük ya da kaçak var',
      'Sigorta bozuk',
      'Elektrik kesik',
    ],
    correctIndex: 1,
    explanation: 'Sigorta sebepsiz atmaz; önce yük ve kaçak aranır.',
  ),
  InterviewQuestion(
    id: 'oto_tamircisi_3',
    jobId: 'oto_tamircisi',
    text: 'Müşteriye yapılmayan bir işlem faturalanırsa bu nedir?',
    options: <String>[
      'Ek hizmet',
      'Haksız kazanç',
      'Yuvarlama',
      'Olağan',
    ],
    correctIndex: 1,
    explanation: 'Yapılmayan iş faturalanmaz.',
  ),
  InterviewQuestion(
    id: 'tesisatci_3',
    jobId: 'tesisatci',
    text: 'Petek ısınmıyor ama kombi çalışıyor. İlk kontrol nedir?',
    options: <String>[
      'Kombiyi değiştirmek',
      'Peteğin havasını almak',
      'Boruyu kesmek',
      'Vanayı sökmek',
    ],
    correctIndex: 1,
    explanation: 'Hava yapan petek ısınmaz; en basit ihtimalden başlanır.',
  ),
  InterviewQuestion(
    id: 'kaynakci_3',
    jobId: 'kaynakci',
    text: 'Kapalı bir hacimde kaynak yaparken en büyük risk nedir?',
    options: <String>[
      'Gürültü',
      'Zararlı gaz birikmesi',
      'Işık',
      'Toz',
    ],
    correctIndex: 1,
    explanation: 'Havalandırmasız ortamda kaynak dumanı birikir.',
  ),
  InterviewQuestion(
    id: 'cnc_operatoru_3',
    jobId: 'cnc_operatoru',
    text: 'Tezgâh çalışırken ölçü alınabilir mi?',
    options: <String>[
      'Evet, hızlı olmak yeter',
      'Hayır, tezgâh durdurulur',
      'Sadece küçük parçalarda',
      'Operatör karar verir',
    ],
    correctIndex: 1,
    explanation: 'Dönen tezgâhta ölçü almak ağır yaralanma sebebidir.',
  ),
  InterviewQuestion(
    id: 'ofis_personeli_3',
    jobId: 'ofis_personeli',
    text: 'Toplantı notunu ne zaman paylaşmak en doğrudur?',
    options: <String>[
      'Bir hafta sonra',
      'Toplantıdan kısa süre sonra, kararlar tazeyken',
      'Hiç',
      'Bir sonraki toplantıda',
    ],
    correctIndex: 1,
    explanation: 'Geciken not, kararın kendisini tartışmaya açar.',
  ),
  InterviewQuestion(
    id: 'banka_personeli_3',
    jobId: 'banka_personeli',
    text: 'Müşterinin hesap hareketlerini merak eden bir yakını arıyor. Ne yaparsın?',
    options: <String>[
      'Genel bilgi veririm',
      'Hiçbir bilgi vermem',
      'Bakiyeyi söylerim',
      'Şubeye gelmesini söyleyip söylerim',
    ],
    correctIndex: 1,
    explanation: 'Hesap bilgisi yalnızca hesap sahibinindir.',
  ),
  InterviewQuestion(
    id: 'ik_uzmani_3',
    jobId: 'ik_uzmani',
    text: 'İki aday da uygun; biri yöneticinin akrabası. Ne yaparsın?',
    options: <String>[
      'Akrabayı seçerim',
      'Ölçütlere göre değerlendirir, ilişkiyi karara katmam',
      'Yöneticiye sorarım',
      'İkisini de elerim',
    ],
    correctIndex: 1,
    explanation: 'İşe alım ölçütle yapılır; yakınlık ölçüt değildir.',
  ),
  InterviewQuestion(
    id: 'hemsire_3',
    jobId: 'hemsire',
    text: 'Hastanın dosyasında olmayan bir alerji sözlü olarak söylendi. Ne yaparsın?',
    options: <String>[
      'Aklımda tutarım',
      'Hemen dosyaya işler ve ekibe bildiririm',
      'Doktora sorarım, o yazsın',
      'Önemsemem',
    ],
    correctIndex: 1,
    explanation: 'Kayda geçmeyen bilgi, bir sonraki vardiyada yok sayılır.',
  ),
  InterviewQuestion(
    id: 'doktor_3',
    jobId: 'doktor',
    text: 'Hastanın tedaviyi reddetme hakkı var mıdır?',
    options: <String>[
      'Hayır',
      'Evet, bilgilendirilmiş olması koşuluyla',
      'Sadece yakını onaylarsa',
      'Sadece yazılı verirse',
    ],
    correctIndex: 1,
    explanation: 'Bilgilendirilmiş hasta tedaviyi reddedebilir.',
  ),
  InterviewQuestion(
    id: 'psikolog_3',
    jobId: 'psikolog',
    text: 'İlk görüşmede danışana gizliliğin sınırları neden anlatılır?',
    options: <String>[
      'Formalite',
      'Neyin paylaşılabileceğini baştan bilmesi gerektiği için',
      'Ücret için',
      'Anlatılmaz',
    ],
    correctIndex: 1,
    explanation: 'Gizliliğin sınırı baştan bilinmezse güven sonradan kırılır.',
  ),
  InterviewQuestion(
    id: 'eczaci_3',
    jobId: 'eczaci',
    text: 'Hasta aynı etkiye sahip iki ilacı birlikte kullanıyor. Ne yaparsın?',
    options: <String>[
      'Bir şey demem',
      'Etkileşimi açıklar, hekime yönlendiririm',
      'İkisini de veririm',
      'Birini gizlice çıkarırım',
    ],
    correctIndex: 1,
    explanation: 'Eczacının işi ilacı vermek kadar etkileşimi görmektir.',
  ),
  InterviewQuestion(
    id: 'veri_analisti_3',
    jobId: 'veri_analisti',
    text: 'Raporun sonucu yöneticinin beklediğinin tersi çıktı. Ne yaparsın?',
    options: <String>[
      'Beklentiye uydururum',
      'Sonucu yöntemiyle birlikte olduğu gibi sunarım',
      'Raporu geciktiririm',
      'Veriyi filtrelerim',
    ],
    correctIndex: 1,
    explanation: 'Veriyi beklentiye uydurmak analizi değersizleştirir.',
  ),
  InterviewQuestion(
    id: 'elektrik_muhendisi_3',
    jobId: 'elektrik_muhendisi',
    text: 'Bir devrede dirençler seri bağlıysa toplam direnç ne olur?',
    options: <String>[
      'Azalır',
      'Dirençlerin toplamı kadar olur',
      'Değişmez',
      'İkiye bölünür',
    ],
    correctIndex: 1,
    explanation: 'Seri bağlamada dirençler toplanır.',
  ),
  InterviewQuestion(
    id: 'insaat_muhendisi_3',
    jobId: 'insaat_muhendisi',
    text: 'Zemin etüdü yapılmadan temel atılırsa ne olur?',
    options: <String>[
      'Maliyet düşer',
      'Taşıma gücü bilinmediği için yapı risk altına girer',
      'Hiçbir şey',
      'İnşaat hızlanır',
    ],
    correctIndex: 1,
    explanation: 'Zemin bilinmeden temel hesaplanamaz.',
  ),
  InterviewQuestion(
    id: 'makine_muhendisi_3',
    jobId: 'makine_muhendisi',
    text: 'İki parça arasında geçme sıkı olacaksa hangi ölçü belirleyicidir?',
    options: <String>[
      'Ağırlık',
      'Tolerans',
      'Renk',
      'Malzeme adı',
    ],
    correctIndex: 1,
    explanation: 'Geçme tipini tolerans belirler.',
  ),
  InterviewQuestion(
    id: 'polis_3',
    jobId: 'polis',
    text: 'Tutanakta olayı kendi yorumunla yazmak doğru mudur?',
    options: <String>[
      'Evet',
      'Hayır; görülen ve tespit edilen yazılır',
      'Sadece şüpheliyse',
      'Amir isterse',
    ],
    correctIndex: 1,
    explanation: 'Tutanak tespit yazar, yorum yazmaz.',
  ),
  InterviewQuestion(
    id: 'itfaiyeci_3',
    jobId: 'itfaiyeci',
    text: 'Yangın tüpü kullanılırken nereye sıkılır?',
    options: <String>[
      'Alevin üstüne',
      'Yanan maddenin dibine',
      'Duvara',
      'Havaya',
    ],
    correctIndex: 1,
    explanation: 'Alev değil, yakıtın kaynağı söndürülür.',
  ),
  InterviewQuestion(
    id: 'memur_3',
    jobId: 'memur',
    text: 'Kendi biriminin görev alanı dışında bir talep geldi. Ne yaparsın?',
    options: <String>[
      'Geri çeviririm',
      'Doğru birimi söyler, yönlendiririm',
      'Ben hallederim',
      'Beklemesini söylerim',
    ],
    correctIndex: 1,
    explanation: 'Yetkisiz işlem yapılmaz ama vatandaş da ortada bırakılmaz.',
  ),
  InterviewQuestion(
    id: 'grafik_tasarimci_3',
    jobId: 'grafik_tasarimci',
    text: 'Müşteri sınırsız revizyon istiyor. Ne yaparsın?',
    options: <String>[
      'Hepsini yaparım',
      'Sözleşmede revizyon sayısını baştan belirlerim',
      'İşi bırakırım',
      'Ücreti artırırım',
    ],
    correctIndex: 1,
    explanation: 'Revizyon sayısı baştan konuşulmazsa iş hiç bitmez.',
  ),
  InterviewQuestion(
    id: 'gazeteci_3',
    jobId: 'gazeteci',
    text: 'Haberde adı geçen kişiye yanıt hakkı neden tanınır?',
    options: <String>[
      'Uzasın diye',
      'Hakkında yazılan kişinin kendini savunma hakkı olduğu için',
      'Zorunlu olmadığı için',
      'Editör istediği için',
    ],
    correctIndex: 1,
    explanation: 'Yanıt hakkı, haberin dengesini kuran şeydir.',
  ),
  InterviewQuestion(
    id: 'fotografci_3',
    jobId: 'fotografci',
    text: 'Çekim dosyalarının yedeği neden hemen alınır?',
    options: <String>[
      'Yer açmak için',
      'Tek kopya kaybolursa çekim tekrarlanamayacağı için',
      'Kural olduğu için',
      'Müşteri istediği için',
    ],
    correctIndex: 1,
    explanation: 'Bir anın ikinci çekimi yoktur.',
  ),

  // --- Yarım zamanlı işler (D-131) --------------------------------------
  //
  // Bu işlerin "mülakatı" gerçek hayatta da kısadır: iş sahibi
  // güvenilirlik ve saat uyumu sorar. Sorular ona göre pratik.
  InterviewQuestion(
    id: 'yz_market_1',
    jobId: 'yz_market_reyon',
    text: 'Raf dizerken hangi ürün öne konur?',
    options: <String>[
      'Yeni gelen, tarihi uzun olan',
      'Tarihi yakın olan',
      'Pahalı olan',
      'Rastgele',
    ],
    correctIndex: 1,
    explanation: 'Tarihi yakın ürün öne konur ki önce o satılsın.',
  ),
  InterviewQuestion(
    id: 'yz_market_2',
    jobId: 'yz_market_reyon',
    text: 'Okul çıkışı 16.30, vardiya 17.00\'de başlıyor. Ne dersin?',
    options: <String>[
      '"Yetişirim, ilk gün deneyelim"',
      '"Geç kalırım, olmaz"',
      '"Okulu asarım"',
      '"Vardiyayı 18.00 yapın"',
    ],
    correctIndex: 0,
    explanation: 'Yarım saat yeter; işveren de bunu duymak ister.',
  ),
  InterviewQuestion(
    id: 'yz_kafe_1',
    jobId: 'yz_kafe',
    text: 'Masaya yanlış sipariş gitti. İlk ne yaparsın?',
    options: <String>[
      'Müşteriyi ikna etmeye çalışırım',
      'Özür diler, doğrusunu getiririm',
      'Mutfağı suçlarım',
      'Görmezden gelirim',
    ],
    correctIndex: 1,
    explanation: 'Önce özür, sonra doğrusu. Suçlu aramak müşterinin işi değil.',
  ),
  InterviewQuestion(
    id: 'yz_kafe_2',
    jobId: 'yz_kafe',
    text: 'Tepsiyle giderken bardak devrildi, müşterinin üstüne gitti.',
    options: <String>[
      'Peçete uzatır, özür diler, yardım çağırırım',
      'Hemen mutfağa kaçarım',
      'Gülüp geçerim',
      'Hesaptan düşerim, konuşmam',
    ],
    correctIndex: 0,
    explanation: 'Önce insana yardım edilir; hesap sonra konuşulur.',
  ),
  InterviewQuestion(
    id: 'yz_kurye_1',
    jobId: 'yz_kurye',
    text: 'Yağmur başladı, teslimata on dakika var. Ne yaparsın?',
    options: <String>[
      'Hızı artırırım',
      'Yavaşlar, geç kalacağımı haber veririm',
      'Siparişi iptal ederim',
      'Kaldırımdan giderim',
    ],
    correctIndex: 1,
    explanation: 'Yağmurda hız değil haber vermek doğru olanı.',
  ),
  InterviewQuestion(
    id: 'yz_kurye_2',
    jobId: 'yz_kurye',
    text: 'Adres bulunamıyor, müşteri telefonu açmıyor.',
    options: <String>[
      'Paketi kapıya bırakırım',
      'Merkeze haber verip beklerim',
      'Geri dönerim, kimseye söylemem',
      'Komşuya bırakırım',
    ],
    correctIndex: 1,
    explanation: 'Karar tek başına verilmez; merkez bilmeli.',
  ),
  InterviewQuestion(
    id: 'yz_cagri_1',
    jobId: 'yz_cagri_merkezi',
    text: 'Karşı taraf bağırıyor. İlk hamlen?',
    options: <String>[
      'Sesimi yükseltirim',
      'Sakin kalır, sorunu sorarım',
      'Hattı kapatırım',
      'Beklemeye alırım',
    ],
    correctIndex: 1,
    explanation: 'Bağırana bağırmak aramayı uzatır, çözmez.',
  ),
  InterviewQuestion(
    id: 'yz_cagri_2',
    jobId: 'yz_cagri_merkezi',
    text: 'Cevabını bilmediğin bir şey sordular.',
    options: <String>[
      'Tahmin söylerim',
      'Bilmediğimi söyler, öğrenip dönerim',
      'Konuyu değiştiririm',
      'Başkasına aktarırım, takip etmem',
    ],
    correctIndex: 1,
    explanation: 'Uydurulan cevap sorunu ikiye çıkarır.',
  ),
  InterviewQuestion(
    id: 'yz_etut_1',
    jobId: 'yz_dersane_asistani',
    text: 'Çocuk soruyu üç kez yanlış yaptı. Ne yaparsın?',
    options: <String>[
      'Cevabı söyleyip geçerim',
      'Nerede takıldığını bulurum',
      'Başka soruya geçerim',
      'Yapamıyorsun derim',
    ],
    correctIndex: 1,
    explanation: 'Cevabı vermek öğretmek değil.',
  ),
  InterviewQuestion(
    id: 'yz_etut_2',
    jobId: 'yz_dersane_asistani',
    text: 'İki öğrenci etütte gürültü yapıyor.',
    options: <String>[
      'Bağırırım',
      'Ayrı masalara alırım',
      'Görmezden gelirim',
      'Etüdü bitiririm',
    ],
    correctIndex: 1,
    explanation: 'Sorun çoğu zaman yer değiştirmekle çözülür.',
  ),
  InterviewQuestion(
    id: 'yz_kitapci_1',
    jobId: 'yz_kitapci',
    text: 'Müşteri adını hatırlamadığı bir kitabı arıyor.',
    options: <String>[
      '"Adını bilmeden bulamam"',
      'Konusunu, yazarını, rengini sorarım',
      'Rastgele bir kitap veririm',
      'Yarın gelmesini söylerim',
    ],
    correctIndex: 1,
    explanation: 'Kitapçılıkta iş, soruyu doğru sormaktan geçer.',
  ),
  InterviewQuestion(
    id: 'yz_kitapci_2',
    jobId: 'yz_kitapci',
    text: 'Dükkânda kimse yok, iki saat geçti.',
    options: <String>[
      'Telefonla oynarım',
      'Rafları düzenler, stoğa bakarım',
      'Dükkânı kapatırım',
      'Uyuklarım',
    ],
    correctIndex: 1,
    explanation: 'Boş saat, işin görünmeyen kısmı için vardır.',
  ),
  InterviewQuestion(
    id: 'yz_sahaci_1',
    jobId: 'yz_hali_saha',
    text: 'Saat doldu ama takım oynamaya devam ediyor.',
    options: <String>[
      'Işıkları kapatırım',
      'Kenara gider, süreyi hatırlatırım',
      'Beklerim, bir şey demem',
      'Kavga ederim',
    ],
    correctIndex: 1,
    explanation: 'Önce hatırlatılır; ışık kapatmak son adımdır.',
  ),
  InterviewQuestion(
    id: 'yz_sahaci_2',
    jobId: 'yz_hali_saha',
    text: 'Sahada su birikmiş, maç yarım saat sonra.',
    options: <String>[
      'Haber verir, süpürmeye başlarım',
      'Beklerim, kurur',
      'Maçı iptal ederim',
      'Üstünü kumla kaparım',
    ],
    correctIndex: 0,
    explanation: 'Haber vermek ve işe girişmek birlikte yürür.',
  ),
  InterviewQuestion(
    id: 'yz_cirak_1',
    jobId: 'yz_sanayi_cirak',
    text: 'Usta "şu anahtarı ver" dedi, hangisi olduğunu bilmiyorsun.',
    options: <String>[
      'Rastgele bir tane veririm',
      'Hangisi diye sorarım',
      'Bekler, hiçbir şey vermem',
      'Kendim kullanmaya çalışırım',
    ],
    correctIndex: 1,
    explanation: 'Çıraklıkta sormak ayıp değil; yanlış vermek zaman kaybı.',
  ),
  InterviewQuestion(
    id: 'yz_cirak_2',
    jobId: 'yz_sanayi_cirak',
    text: 'Elin yağlı, telefonun çalıyor.',
    options: <String>[
      'Hemen açarım',
      'Elimi silip sonra bakarım',
      'Telefonu atarım',
      'Ustadan açmasını isterim',
    ],
    correctIndex: 1,
    explanation: 'Atölyede acele, hem işi hem eli bozar.',
  ),
  InterviewQuestion(
    id: 'yz_market_3',
    jobId: 'yz_market_reyon',
    text: 'Kasa fişi ile raftaki etiket farklı. Ne yaparsın?',
    options: <String>[
      'Fişteki fiyatı savunurum',
      'Sorumluya haber veririm',
      'Etiketi söküp atarım',
      'Müşteriye "olur böyle" derim',
    ],
    correctIndex: 1,
    explanation: 'Fiyat farkını çözmek senin yetkinde değil.',
  ),
  InterviewQuestion(
    id: 'yz_kafe_3',
    jobId: 'yz_kafe',
    text: 'Kapanışa yarım saat var, yeni müşteri geldi.',
    options: <String>[
      'Kapalıyız derim',
      'Alırım, kapanış saatini söylerim',
      'Görmezden gelirim',
      'Işıkları kısarım',
    ],
    correctIndex: 1,
    explanation: 'Saat söylenir, müşteri geri çevrilmez.',
  ),
  InterviewQuestion(
    id: 'yz_kurye_3',
    jobId: 'yz_kurye',
    text: 'Paket yolda hasar gördü.',
    options: <String>[
      'Öyle teslim ederim',
      'Merkeze bildirir, müşteriye söylerim',
      'Kendim tamir etmeye çalışırım',
      'Başka bir paketle değiştiririm',
    ],
    correctIndex: 1,
    explanation: 'Hasarı saklamak sorunu büyütür.',
  ),
  InterviewQuestion(
    id: 'yz_cagri_3',
    jobId: 'yz_cagri_merkezi',
    text: 'Aynı müşteri üçüncü kez arıyor, sorun çözülmemiş.',
    options: <String>[
      'Baştan anlatmasını isterim',
      'Geçmiş kaydı okur, kaldığı yerden devam ederim',
      'Başka birine aktarırım',
      'Beklemeye alırım',
    ],
    correctIndex: 1,
    explanation: 'Kayıt okunmadan yapılan her arama baştan başlar.',
  ),
  InterviewQuestion(
    id: 'yz_etut_3',
    jobId: 'yz_dersane_asistani',
    text: 'Veli "çocuğum neden ilerlemiyor" diye sordu.',
    options: <String>[
      'Çocuğu suçlarım',
      'Gördüğüm somut şeyleri anlatırım',
      'Konuyu değiştiririm',
      'Sorumluya yönlendiririm, bir şey söylemem',
    ],
    correctIndex: 1,
    explanation: 'Veli suçlama değil, gözlem duymak ister.',
  ),
  InterviewQuestion(
    id: 'yz_kitapci_3',
    jobId: 'yz_kitapci',
    text: 'Müşteri okuyup beğenmediği kitabı geri getirdi.',
    options: <String>[
      'Alamam derim',
      'Dükkânın kuralını söyler, sorumluya sorarım',
      'Parasını hemen veririm',
      'Tartışırım',
    ],
    correctIndex: 1,
    explanation: 'Kural senin değil, dükkânın; ama söylenmesi senin işin.',
  ),
  InterviewQuestion(
    id: 'yz_sahaci_3',
    jobId: 'yz_hali_saha',
    text: 'İki takım aynı saate rezervasyon yaptığını söylüyor.',
    options: <String>[
      'İlk gelen oynar derim',
      'Deftere bakar, kaydı gösteririm',
      'İkisini birden sahaya alırım',
      'Sahayı kapatırım',
    ],
    correctIndex: 1,
    explanation: 'Tartışmayı kayıt bitirir.',
  ),
  InterviewQuestion(
    id: 'yz_cirak_3',
    jobId: 'yz_sanayi_cirak',
    text: 'Bir parçayı yanlış taktığını sonradan fark ettin.',
    options: <String>[
      'Kimseye söylemem, belki tutar',
      'Ustaya söylerim',
      'Kendim sökmeye çalışırım',
      'İşi bırakıp giderim',
    ],
    correctIndex: 1,
    explanation: 'Atölyede saklanan hata yolda ortaya çıkar.',
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

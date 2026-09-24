/// "Finger" tanışma uygulamasının metin havuzları (Paket 34).
///
/// Bütün profil metinleri **bu proje için yazıldı**; hiçbir uygulamadan
/// alınmadı. Gerçek kişi, gerçek profil ve gerçek fotoğraf yoktur.
///
/// Sayısal değerler `prototypeOnly`'dir
/// (`docs/DESIGN_REVIEW_QUEUE.md`, Q-102).
library;

/// Profillerde görünen kısa tanıtım yazıları.
const List<String> kFingerBios = <String>[
  'Kahveyi sade içerim, sohbeti uzun severim.',
  'Hafta sonu planım yok, teklife açığım.',
  'Köpeğim var, önce o onaylamalı.',
  'Yürüyüş, kitap ve erken kalkmak. Heyecanlı biri arıyorsan yanlış yerdesin.',
  'Yemek yaparım ama bulaşığı sen yıkarsın.',
  'Deniz kenarında büyüdüm, şehirde boğuluyorum.',
  'Konser biletim hep iki kişilik.',
  'Uzun mesaj yazmayı severim, kısa cevaplara alınırım.',
  'Gitar çalıyorum. İyi çaldığımı söylemedim.',
  'Ailem "ne zaman" diye soruyor, ben de bilmiyorum.',
  'Sabah insanı değilim, akşam da pek değilim.',
  'Dağ yürüyüşü, çadır, soğuk su. Yanımda gelir misin?',
  'Film seçmek iki saat sürer, uyarayım.',
  'Şu an iş değiştiriyorum, hayat biraz karışık ama iyiyim.',
  'Bir kediye bakıyorum, o da bana bakıyor.',
  'Ciddi bir şey arıyorum. Vaktini boşa harcamam.',
  'Yeni şehre taşındım, kimseyi tanımıyorum.',
  'Voleybol oynarım, kaybetmeyi sevmem.',
  'Anneme her gün telefon ederim. Kusura bakma.',
  'Gece yarısı yürüyüşü ve simit. Gerisi ayrıntı.',
];

/// Profillerde görünen ilgi alanları.
const List<String> kFingerInterests = <String>[
  'sinema',
  'yürüyüş',
  'kahve',
  'kitap',
  'müzik',
  'yemek',
  'futbol',
  'voleybol',
  'yüzme',
  'kamp',
  'fotoğraf',
  'tiyatro',
  'seyahat',
  'bisiklet',
  'satranç',
  'dans',
  'bahçe',
  'tarih',
  'resim',
  'kedi',
];

/// Eşleşme anında gösterilen metinler.
const List<String> kFingerMatchLines = <String>[
  'O da seni beğendi. Artık yazabilirsin.',
  'Eşleştiniz. İlk mesajı kim yazacak?',
  'Karşılıklı beğeni. Uygulamanın sevdiği an.',
  'Eşleşme oldu. Gerisi sana kalmış.',
];

/// Beğeni karşılık bulmadığında gösterilen metinler.
const List<String> kFingerNoMatchLines = <String>[
  'Beğendin ama karşılık gelmedi. Olur böyle.',
  'Beğenin gitti. Cevap gelmedi.',
  'Sessizlik. Sıradaki profile geç.',
  'Bu sefer olmadı.',
];

/// prototypeOnly: uygulamanın açıldığı yaş.
const int kFingerMinAge = 18;

/// prototypeOnly: bir yılda kaç profile bakılabilir.
const int kFingerMaxSwipesPerAge = 25;

/// prototypeOnly: bir yılda atılabilecek **beğeni** sayısı (D-081).
///
/// Faho'nun isteği: "günde 5 like atabilelim ve fazla like atabilmek için
/// premium satın alalım". Oyun gün gün değil yıl yıl ilerlediği için
/// "günde 5" oyunun ölçeğine **yılda 5 beğeni** olarak taşındı; geçmek
/// sınırsızdır, sınır yalnızca beğeniye konur.
const int kFingerMaxLikesPerAge = 5;

/// prototypeOnly: premium üyelikte bir yıldaki beğeni sayısı.
const int kFingerPremiumLikesPerAge = 30;

/// prototypeOnly: premium üyeliğin yıllık ücreti (2026 ₺).
///
/// Gerçek tanışma uygulamalarının aylık aboneliği bu ölçekte; yıllığa
/// çevrilmiş hâli.
const int kFingerPremiumYearlyCost = 4800;

/// prototypeOnly: premium üyeliğin eşleşme ihtimaline katkısı.
const double kFingerPremiumMatchBonus = 0.08;

/// prototypeOnly: doldurulmuş profilin eşleşme ihtimaline katkısı.
///
/// Boş profil kimseye bir şey söylemez; kendini anlatan profil karşılık
/// bulur.
const double kFingerProfileBonus = 0.12;

/// prototypeOnly: ortak ilgi alanı başına eşleşme katkısı.
const double kFingerSharedInterestBonus = 0.05;

/// prototypeOnly: bir yılda kaç kişinin oyuncuyu kendiliğinden
/// beğenebileceği.
const int kFingerMaxIncoming = 3;

/// prototypeOnly: destede aynı anda kaç profil durur.
const int kFingerDeckSize = 8;

/// prototypeOnly: taban eşleşme ihtimali.
const double kFingerBaseMatchChance = 0.22;

/// prototypeOnly: görünüş ve karizmanın eşleşmeye kattığı en büyük pay.
const double kFingerCharmBonus = 0.45;

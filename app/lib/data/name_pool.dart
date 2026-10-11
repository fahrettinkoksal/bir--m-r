/// Prototip için isim/şehir/meslek havuzları.
///
/// **Havuzlar Paket BV'de büyütüldü (20 → 60).** Gerekçe ölçümdü, tercih
/// değil: 300 hayatta kayıttaki kişi sayısının **medyanı 58**, en çoğu
/// 97. Cinsiyet başına 20 isimle iki yaşayan kişinin aynı adı taşıması
/// **300 hayatın 283'ünde** oluyordu (%94); kardeşle ebeveynin aynı adı
/// taşıması %9, yeni doğan çocuğun hanedeki biriyle çakışması %3.
/// Günlük soyadsız yazdığı için bu çakışmalar okunurluğu bozuyor
/// ("Mehmet ortaokula geçti" — baba mı abi mi?).
///
/// Havuz büyütmek bir **kural değişikliği değil**, içerik: "hanedeki
/// adları dışla" kuralı Q-198 #6'da hâlâ Faho'nun kararını bekliyor.
/// Ama o kural ancak havuz taşıyorsa işe yarar; bu paket onun önünü
/// açtı ve rakamları kuyruğa yazdı.
///
/// İsimler Türkiye'de yaygın, **gerçek bir kişiye işaret etmeyen**
/// adlar; ünlü/gerçek kişi adı konulmaz.
library;

const List<String> kadinIsimleri = <String>[
  'Ayşe', 'Elif', 'Zeynep', 'Fatma', 'Hatice', 'Sevgi', 'Nurten', 'Gülay',
  'Melike', 'Şükran', 'Derya', 'Pınar', 'Esra', 'Nazlı', 'Sema', 'Hülya',
  'Yasemin', 'Belgin', 'Ceren', 'Sultan',
  // Paket BV: havuz 60'a çıkarıldı (ölçüm dosya başında).
  'Meryem', 'Emine', 'Havva', 'Rabia', 'Cemile', 'Hanife', 'Şerife', 'Nuray',
  'Gönül', 'Perihan', 'Münevver', 'Sevim', 'Nesrin', 'Berrin', 'Özlem',
  'Serpil', 'Tülay', 'Filiz', 'Nilgün', 'Aysel',
  'Dilek', 'Burcu', 'Sibel', 'Gamze', 'Tuğba', 'Merve', 'Büşra', 'Damla',
  'Çiğdem', 'Seda', 'Ebru', 'Figen', 'Aslı', 'İpek', 'Selin', 'Ela',
  'Duygu', 'Hazal', 'Nehir', 'Irmak',
];

const List<String> erkekIsimleri = <String>[
  'Mehmet', 'Ahmet', 'Mustafa', 'Hasan', 'Yusuf', 'Kemal', 'Orhan', 'Cengiz',
  'Serkan', 'Emre', 'Barış', 'Tolga', 'Recep', 'İlhan', 'Bülent', 'Selim',
  'Onur', 'Kadir', 'Volkan', 'Hakan',
  // Paket BV: havuz 60'a çıkarıldı (ölçüm dosya başında).
  'İbrahim', 'Ali', 'Osman', 'Hüseyin', 'Ramazan', 'Murat', 'Fikret',
  'Necmi', 'Şaban', 'Turgut', 'Erol', 'Yılmaz', 'Sabri', 'Nuri', 'Cemil',
  'Halil', 'Şükrü', 'Ferit', 'Zeki', 'Rıza',
  'Burak', 'Caner', 'Mert', 'Oğuz', 'Tarık', 'Umut', 'Yiğit', 'Berk',
  'Deniz', 'Eren', 'Furkan', 'Görkem', 'Kaan', 'Levent', 'Sinan', 'Taner',
  'Uğur', 'Vedat', 'Yalçın', 'Doruk',
];

const List<String> soyisimler = <String>[
  'Yıldırım', 'Demir', 'Çelik', 'Aydın', 'Karaca', 'Özkan', 'Şahin', 'Erdoğan',
  'Bozkurt', 'Ekinci', 'Güneş', 'Turan', 'Aksoy', 'Kara', 'Doğan', 'Uçar',
  'Kılıç', 'Tekin', 'Sarıkaya', 'Balcı',
  // Paket BV: havuz 60'a çıkarıldı. Soyadı çakışması aile kurgusunda
  // yanlış akrabalık izlenimi veriyordu.
  'Arslan', 'Koç', 'Kurt', 'Polat', 'Ateş', 'Bulut', 'Çetin', 'Duman',
  'Erdem', 'Gül', 'Işık', 'Kaplan', 'Keskin', 'Köse', 'Mutlu', 'Özdemir',
  'Sezer', 'Taş', 'Yalçın', 'Yüce',
  'Akın', 'Barut', 'Can', 'Dinç', 'Ergin', 'Fidan', 'Güler', 'Hancı',
  'İnan', 'Karakaya', 'Levent', 'Meriç', 'Nalbant', 'Orak', 'Pamuk',
  'Sağlam', 'Şenol', 'Toprak', 'Ülker', 'Varol',
];

/// Doğum şehri havuzu (D-004). Premium şehir seçimi onaylanmış bir özellik
/// değildir; şehir rastgele belirlenir.
const List<String> sehirler = <String>[
  'İstanbul', 'Ankara', 'İzmir', 'Bursa', 'Adana', 'Trabzon', 'Gaziantep',
  'Konya', 'Eskişehir', 'Samsun', 'Diyarbakır', 'Kayseri', 'Antalya',
  'Zonguldak', 'Malatya', 'Erzurum', 'Aydın', 'Sivas', 'Van', 'Denizli',
  'Kocaeli', 'Amasya',
];

const List<String> meslekler = <String>[
  'tekstil işçisi', 'öğretmen', 'terzi', 'şoför', 'muhasebeci', 'hemşire',
  'bakkal', 'kaportacı', 'memur', 'aşçı', 'inşaat ustası', 'kuaför',
  'tezgâhtar', 'elektrikçi', 'çiftçi', 'eczacı kalfası', 'kasap',
  'matbaa işçisi', 'postacı', 'lokantacı', 'mühendis', 'saat tamircisi',
];

const List<String> evcilHayvanTurleri = <String>[
  'kedi', 'köpek', 'muhabbet kuşu', 'kaplumbağa', 'balık',
];

const List<String> evcilHayvanIsimleri = <String>[
  'Pamuk', 'Boncuk', 'Karabaş', 'Tekir', 'Duman', 'Minnoş', 'Zeytin',
  'Fındık', 'Paşa', 'Mırmır',
];

/// Şehirlerin birbirine yakınlığı (D-083).
///
/// **Neden var:** Faho istedi — "taşınmada yaşadığım ilin yakınındaki
/// iller olsun; her taşındığımda yakınındaki iller çıksın". Taşınma
/// listesi ülkenin bütün şehirlerini gösteriyordu; Amasya'da oturan
/// oyuncu bir hamlede İzmir'e taşınabiliyordu.
///
/// Liste oyundaki 22 şehir arasından **coğrafi olarak en yakın**
/// olanları verir. Bu bir il sınırı komşuluğu tablosu değildir: oyunun
/// şehir listesi seyrek olduğu için "aynı bölge ya da hemen yanındaki
/// bölge" ölçütü kullanılır. Örneğin Amasya'nın gerçek komşuları
/// arasında Samsun ve Tokat vardır; Tokat oyunda yok, o yüzden liste
/// Samsun, Sivas ve Trabzon'u verir.
///
/// Komşuluk **karşılıklıdır**: A'nın listesinde B varsa B'nin listesinde
/// de A vardır. Bunu test sabitler.
library;

/// Her şehrin oyundaki en yakın komşuları.
const Map<String, List<String>> kCityNeighbours = <String, List<String>>{
  'İstanbul': <String>['Kocaeli', 'Bursa', 'Zonguldak'],
  'Kocaeli': <String>['İstanbul', 'Bursa', 'Eskişehir', 'Zonguldak'],
  'Bursa': <String>['İstanbul', 'Kocaeli', 'Eskişehir', 'İzmir'],
  'Zonguldak': <String>['İstanbul', 'Kocaeli', 'Ankara', 'Samsun'],
  'Ankara': <String>[
    'Eskişehir',
    'Konya',
    'Kayseri',
    'Zonguldak',
    'Samsun',
    'Sivas',
  ],
  'Eskişehir': <String>['Ankara', 'Bursa', 'Konya', 'Kocaeli'],
  'Konya': <String>['Ankara', 'Eskişehir', 'Antalya', 'Kayseri', 'Denizli', 'Adana'],
  'Kayseri': <String>['Ankara', 'Konya', 'Sivas', 'Adana', 'Malatya'],
  'Sivas': <String>[
    'Kayseri',
    'Ankara',
    'Malatya',
    'Samsun',
    'Amasya',
    'Erzurum',
  ],
  'Amasya': <String>['Samsun', 'Sivas', 'Trabzon'],
  'Samsun': <String>['Amasya', 'Trabzon', 'Ankara', 'Sivas', 'Zonguldak'],
  'Trabzon': <String>['Samsun', 'Amasya', 'Erzurum'],
  'Erzurum': <String>['Trabzon', 'Sivas', 'Van', 'Malatya', 'Diyarbakır'],
  'Van': <String>['Erzurum', 'Diyarbakır'],
  'Diyarbakır': <String>['Malatya', 'Van', 'Erzurum', 'Gaziantep'],
  'Malatya': <String>[
    'Sivas',
    'Kayseri',
    'Diyarbakır',
    'Gaziantep',
    'Erzurum',
  ],
  'Gaziantep': <String>['Adana', 'Malatya', 'Diyarbakır'],
  'Adana': <String>['Gaziantep', 'Kayseri', 'Antalya', 'Konya'],
  'Antalya': <String>['Konya', 'Denizli', 'Adana', 'İzmir'],
  'Denizli': <String>['Aydın', 'İzmir', 'Antalya', 'Konya'],
  // Aydın'ın gerçek komşuları İzmir, Manisa, Denizli ve Muğla'dır;
  // oyunda bulunanlar İzmir ve Denizli. Antalya arada Muğla/Burdur
  // olduğu için komşu sayılmaz.
  'Aydın': <String>['İzmir', 'Denizli'],
  'İzmir': <String>['Aydın', 'Denizli', 'Bursa', 'Antalya'],
};

/// Bu şehrin yakınındaki iller.
///
/// Şehir tabloda yoksa **boş liste** döner; uydurma komşu üretilmez.
List<String> neighboursOf(String city) =>
    kCityNeighbours[city] ?? const <String>[];

/// İki şehir birbirine yakın mı?
bool areNeighbours(String a, String b) => neighboursOf(a).contains(b);

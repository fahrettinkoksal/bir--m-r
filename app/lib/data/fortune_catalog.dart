/// Kahve falı, tarot ve burç yorumu metinleri (Paket 27).
///
/// **Ton:** Bunlar oyun içi eğlencedir. Metinler hiçbir zaman kesin bir
/// gelecek söylemez ("şunu yapacaksın" demez), oyunun olaylarını da
/// yönlendirmez. Etkileri küçüktür: biraz keyif, bazen hayal kırıklığı.
///
/// Metinler özgündür; hiçbir uygulamadan kopyalanmamıştır. Etkiler
/// `prototypeOnly`'dir (Q-095).
library;

import '../domain/models/zodiac.dart';

/// Bir fal sonucu: metin ve mutluluk etkisi.
class FortuneReading {
  const FortuneReading(this.text, this.prototypeOnlyHappiness);

  final String text;

  /// Mutluluğa eklenen (negatif olabilir).
  final int prototypeOnlyHappiness;
}

/// Kahve falı: fincan çevrilir, biri bakar, herkes güler.
const List<FortuneReading> kCoffeeReadings = <FortuneReading>[
  FortuneReading(
    'Fincanın dibinde bir yol görünüyor. "Uzun yol" diyor bakan; '
    '"ama yorucu değil, uzun."',
    3,
  ),
  FortuneReading(
    'Kenarda bir kuş var. "Haber" diyorlar. Ne haberi olduğunu kimse '
    'söylemiyor.',
    2,
  ),
  FortuneReading(
    '"Burada bir kapı var" diyor fincana bakan, "açık mı kapalı mı '
    'belli değil ama var."',
    2,
  ),
  FortuneReading(
    'Telvenin ortasında bir yüzük şekli. Masadakiler gülüşüyor, sen '
    'konuyu değiştiriyorsun.',
    3,
  ),
  FortuneReading(
    '"Sıkıntın var" diyor. Yok diyorsun. "Var" diyor. Bir süre '
    'susuyorsunuz.',
    -2,
  ),
  FortuneReading(
    'Fincan ters duruyor, telve hiç akmamış. "Bugün olmadı" deyip '
    'fincanı kaldırıyorlar.',
    -1,
  ),
  FortuneReading(
    '"Seni çok düşünen biri var" diyor. Kim olduğunu soruyorsun, '
    '"orası bana görünmez" diyor.',
    3,
  ),
  FortuneReading(
    'Bir ev şekli çıkmış. "Taşınma" diyorlar. Kiran aklına geliyor.',
    1,
  ),
  FortuneReading(
    '"Para görünüyor ama elinde durmuyor" diyor. Bunu zaten biliyordun.',
    -1,
  ),
  FortuneReading(
    'Fincanın kenarında bir balık. "Bu iyidir" diyor bakan, sebebini '
    'açıklamıyor.',
    2,
  ),
];

/// Tarot kartı: ad, kısa yorum, etki.
class TarotCard {
  const TarotCard(this.name, this.text, this.prototypeOnlyHappiness);

  final String name;
  final String text;
  final int prototypeOnlyHappiness;
}

/// Tarot destesi.
///
/// Kart adları büyük arkanadan tanıdıktır; yorumlar bu oyuna özgü
/// yazılmıştır.
const List<TarotCard> kTarotCards = <TarotCard>[
  TarotCard(
    'Deli',
    'Başlangıç kartı. "Hazır olmadan başlayacaksın" diyor falcı, '
    '"zaten kimse hazır olmuyor."',
    3,
  ),
  TarotCard(
    'Güneş',
    'Açık ara en iyi kart. Masadaki herkes rahatlıyor, en çok da sen.',
    6,
  ),
  TarotCard(
    'Kule',
    'Yıkım kartı. "Korkma" diyor falcı, "yıkılan şey zaten çürüktü."',
    -4,
  ),
  TarotCard(
    'Ay',
    'Belirsizlik kartı. "Gördüğün şey göründüğü gibi değil" diyor.',
    -1,
  ),
  TarotCard(
    'Yıldız',
    'Umut kartı. "Bu aralar iyi gitmiyor olabilir ama geçiyor" diyor.',
    4,
  ),
  TarotCard(
    'Çark',
    'Dönen çark. "Bir şey değişecek" diyor, yönünü söylemiyor.',
    1,
  ),
  TarotCard(
    'Aşıklar',
    'Seçim kartı. "Aşk değil, karar" diyor falcı, "ikisi de zor ama."',
    3,
  ),
  TarotCard(
    'Ermiş',
    'Yalnızlık kartı. "Bir süre kendinle kalacaksın" diyor.',
    -1,
  ),
  TarotCard(
    'Güç',
    'Sabır kartı. "Zorla değil, sabırla" diyor.',
    2,
  ),
  TarotCard(
    'Asılan Adam',
    'Bekleme kartı. "Şimdi hamle yapma" diyor. Yapmayacaksın zaten.',
    -2,
  ),
];

/// Burç yorumu: her burç için birkaç metin.
///
/// Ücretsizdir; gazete köşesi tonu bilerek korunmuştur.
const Map<Zodiac, List<FortuneReading>> kHoroscopes = <Zodiac, List<FortuneReading>>{
  Zodiac.koc: <FortuneReading>[
    FortuneReading('Bu dönem acele etmen isteniyor ama acele etme.', 1),
    FortuneReading('İçindeki "ben hallederim" sesi bu hafta biraz yüksek.', 2),
  ],
  Zodiac.boga: <FortuneReading>[
    FortuneReading('Alıştığın düzen sarsılabilir. Sarsılsın.', 1),
    FortuneReading('Bu dönem yemek ve huzur aynı cümlede geçiyor.', 3),
  ],
  Zodiac.ikizler: <FortuneReading>[
    FortuneReading('Çok konuşulan bir haftadasın. Bir kısmı seninle ilgili.', 2),
    FortuneReading('İki şey arasında kalmışsın; üçüncüsü de var aslında.', 1),
  ],
  Zodiac.yengec: <FortuneReading>[
    FortuneReading('Ev ve aile konuları öne çıkıyor. Telefonunu aç.', 2),
    FortuneReading('Kabuğuna çekilmek istiyorsun; bu sefer sakıncası yok.', 1),
  ],
  Zodiac.aslan: <FortuneReading>[
    FortuneReading('Görünür olduğun bir dönem. Gölgede kalmaya çalışma.', 3),
    FortuneReading('Övgü bekliyorsun. Gelmezse de kendin söyle.', 1),
  ],
  Zodiac.basak: <FortuneReading>[
    FortuneReading('Ayrıntılar seni yoruyor. Bir kısmını bırak.', 1),
    FortuneReading('Düzen kurma isteğin bu dönem işe yarıyor.', 2),
  ],
  Zodiac.terazi: <FortuneReading>[
    FortuneReading('Karar vermen gereken bir konu var. Erteleme.', 1),
    FortuneReading('Dengeyi kurmaya çalışırken kendini unutma.', 2),
  ],
  Zodiac.akrep: <FortuneReading>[
    FortuneReading('Sakladığın bir şey var. Saklamaya devam edebilirsin.', 1),
    FortuneReading('Bu dönem kimseye açıklama borçlu değilsin.', 2),
  ],
  Zodiac.yay: <FortuneReading>[
    FortuneReading('Gitmek istiyorsun. Uzağa olmasa da git.', 3),
    FortuneReading('Ağzından çıkanı biraz tartmakta fayda var.', 1),
  ],
  Zodiac.oglak: <FortuneReading>[
    FortuneReading('Çalışıyorsun, çalışıyorsun. Bir gün de durmayı dene.', 1),
    FortuneReading('Uzun vadeli bir şey nihayet sonuç veriyor.', 3),
  ],
  Zodiac.kova: <FortuneReading>[
    FortuneReading('Herkesten farklı düşünüyorsun; bu sefer haklısın.', 2),
    FortuneReading('Kalabalıkta yalnız hissedebilirsin. Geçici.', 1),
  ],
  Zodiac.balik: <FortuneReading>[
    FortuneReading('Hayal kurmakla vakit geçiriyorsun. Bazıları tutar.', 2),
    FortuneReading('Duyduğun her şeye inanma, özellikle de kendi içine.', 1),
  ],
};

/// Burçsal dönem: hangi burçları, nasıl etkiliyor.
///
/// "Şu dönem geldi, şu burçlar etkileniyor" biçiminde ekranda bildirilir.
class ZodiacPeriod {
  const ZodiacPeriod({
    required this.id,
    required this.name,
    required this.text,
    required this.elements,
    required this.prototypeOnlyHappiness,
  });

  final String id;
  final String name;

  /// Bildirimde gösterilecek açıklama.
  final String text;

  /// Etkilenen burç elementleri (ateş, toprak, hava, su).
  ///
  /// Element üzerinden yazılır ki her dönem üç burcu birden kapsasın;
  /// böylece dönem hiç kimseye denk gelmeyen bir şey olmaz.
  final List<String> elements;

  /// Etkilenen oyuncunun mutluluğuna eklenen (negatif olabilir).
  final int prototypeOnlyHappiness;

  bool affects(Zodiac zodiac) => elements.contains(zodiac.element);
}

const List<ZodiacPeriod> kZodiacPeriods = <ZodiacPeriod>[
  ZodiacPeriod(
    id: 'merkur_retro',
    name: 'Merkür retrosu',
    text: 'Bu dönem her şey yarım kalıyor: mesajlar gidiyor ama '
        'varmıyor, sözler ağızda kalıyor. Hava burçları en çok '
        'homurdananlar.',
    elements: <String>['hava'],
    prototypeOnlyHappiness: -5,
  ),
  ZodiacPeriod(
    id: 'dolunay',
    name: 'Dolunay',
    text: 'Uyku tutmuyor, eski konular akla geliyor. Su burçları bu '
        'dönemde her şeyi biraz daha derinden hissediyor.',
    elements: <String>['su'],
    prototypeOnlyHappiness: -4,
  ),
  ZodiacPeriod(
    id: 'venus_gecisi',
    name: 'Venüs geçişi',
    text: 'Gönül işleri hareketleniyor, insanın yüzü gülesi geliyor. '
        'Toprak ve su burçları bu geçişten keyif alıyor.',
    elements: <String>['toprak', 'su'],
    prototypeOnlyHappiness: 6,
  ),
  ZodiacPeriod(
    id: 'mars_gucu',
    name: 'Mars etkisi',
    text: 'Enerji yüksek, sabır düşük. Ateş burçları bu dönemde hem '
        'çok iş yapıyor hem çok tartışıyor.',
    elements: <String>['ateş'],
    prototypeOnlyHappiness: 3,
  ),
  ZodiacPeriod(
    id: 'saturn_donusu',
    name: 'Satürn dönüşü',
    text: 'Hesap sorma dönemi: "ben ne yapıyorum" sorusu sık soruluyor. '
        'Toprak burçları bunu en ağır yaşayanlar.',
    elements: <String>['toprak'],
    prototypeOnlyHappiness: -6,
  ),
  ZodiacPeriod(
    id: 'jupiter_bereketi',
    name: 'Jüpiter bolluğu',
    text: 'İşler beklenenden kolay ilerliyor. Ateş ve hava burçları bu '
        'dönemde şanslı sayılıyor.',
    elements: <String>['ateş', 'hava'],
    prototypeOnlyHappiness: 5,
  ),
  ZodiacPeriod(
    id: 'ay_tutulmasi',
    name: 'Ay tutulması',
    text: 'Bitmesi gerekenler bitiyor, ister istemez. Su ve toprak '
        'burçları bu dönemde bir şeyleri geride bırakıyor.',
    elements: <String>['su', 'toprak'],
    prototypeOnlyHappiness: -3,
  ),
];

ZodiacPeriod? zodiacPeriodById(String id) {
  for (final ZodiacPeriod p in kZodiacPeriods) {
    if (p.id == id) return p;
  }
  return null;
}

/// Aktivite sonuç metinleri (D-127).
///
/// Faho bildirdi: oyundaki metinler "yapay zekâ yazmış gibi" duruyor.
/// Aktivitelerin ortak sonucu **"X tamamlandı."** idi; oyuncu en sık
/// yaptığı şeyde en mekanik cümleyi görüyordu.
///
/// Üslup kaynağı: `docs/WRITING_STYLE_TR.md`. Anlatı yaşanmış gibi
/// okunur; sayı ve etki ayrı satırda zaten gösteriliyor, cümlenin içine
/// gömülmez.
///
/// Her mekân için birkaç alternatif vardır; aynı aktiviteyi tekrarlayan
/// oyuncu hep aynı cümleyi görmez.
library;

import '../domain/models/gender.dart';

/// Mekâna göre sonuç cümleleri.
///
/// Anahtar [ActivityVenue] adıdır; karşılığı sırayla denenecek
/// alternatiflerdir.
const Map<String, List<String>> kActivityResultTexts =
    <String, List<String>>{
  'sporSalonu': <String>[
    'Salon kalabalıktı ama sıranı bekledin. Çıkarken bacakların '
        'titriyordu.',
    'Koşu bandında yarım saat. Son beş dakikayı saate bakarak geçirdin.',
    'Ağırlıkları yerine koyarken aynada kendine bir baktın. Fena değil.',
    'Antrenör "form tutuyorsun" dedi. Belki nezaketti, yine de iyi geldi.',
  ],
  'berber': <String>[
    'Koltuğa oturdun, üç dakika sonra herkesin gündeminden haberdardın.',
    'Makas sesi, kolonya, ayna. Çıkarken ensen üşüdü.',
    'Berber "hep aynı mı?" diye sordu. "Hep aynı" dedin.',
    'Sıra beklerken bütün dergiyi bitirdin.',
  ],
  'kutuphane': <String>[
    'Pencere kenarındaki masa boştu. İki saat kimse konuşmadı.',
    'Aradığın kitabı bulamadın, başka bir şey buldun. O da iyi oldu.',
    'Sayfa kenarına bir not düştün. Kimin defteri olduğu belli değildi.',
  ],
  'kurs': <String>[
    'Ders bitti, herkes dağıldı. Sen biraz daha kaldın.',
    'Eğitmen bir yerde durdurdu: "Şunu bir daha yap." Yaptın, oldu.',
    'Bu hafta ilerleme yavaştı ama en azından geriye gitmedin.',
  ],
  'eglence': <String>[
    'Program umduğun kadar değildi ama çıkarken keyfin yerindeydi.',
    'Yanındaki masadakiler yüksek sesle konuştu; yine de iyi vakitti.',
    'Dönüş yolunda hâlâ aklında birkaç sahne vardı.',
  ],
  'saglikMerkezi': <String>[
    'Sıra bekledin, adın okundu, on dakikada bitti.',
    'İşlem tamam. Hemşire "geçmiş olsun" dedi, çıktın.',
  ],
  'estetik': <String>[
    'İşlem bitti, aynada yüzünü bir süre inceledin.',
    'Doktor "şişlik birkaç gün sürer" dedi. Sürdü.',
  ],
  'falTarot': <String>[
    'Söylenenlerin yarısına inandın, yarısını unuttun.',
    'Çıkarken "bakalım" dedin. Herkes öyle diyor.',
  ],
};

/// Mekân için sonuç cümlesi seçer.
///
/// [seed] aynı yıl aynı cümlenin tekrarlanmaması için kullanılır; metin
/// listesi boşsa `null` döner ve çağıran eski davranışa düşer.
String? activityResultText(String venueName, int seed) {
  final List<String>? liste = kActivityResultTexts[venueName];
  if (liste == null || liste.isEmpty) return null;
  return liste[seed.abs() % liste.length];
}

/// Çalıştırmalar arasında aynı sonucu veren basit karma.
///
/// `String.hashCode` Dart'ta **çalıştırmaya göre değişir**; aynı yaşta
/// aynı aktivite her açılışta başka cümle göstermesin diye kendi
/// karmamızı kullanıyoruz.
int stableTextSeed(String value) {
  int h = 0;
  for (final int c in value.codeUnits) {
    h = (h * 31 + c) % 100003;
  }
  return h;
}

/// Saç kesimi sonrası cümle; cinsiyete göre doğal durur.
String hairResultText(Gender gender, String style) =>
    gender == Gender.kadin
        ? 'Aynaya baktın: saçın artık "$style". Çıkarken bir kere daha '
            'baktın.'
        : 'Ense tıraşı bitti, ayna arkaya tutuldu. Saçın artık "$style".';

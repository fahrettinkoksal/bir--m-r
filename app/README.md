# Bir Ömür — prototip uygulaması (Aşama 1-3)

Flutter ile Android öncelikli geliştirilen ilk prototip.
Kapsam `docs/CLAUDE_PROTOTYPE_TASK.md` içindeki **Aşama 1, 2 ve 3** ile
sınırlıdır.

## Gereksinimler

- Flutter **3.35.5** (Dart 3.9.2) veya uyumlu bir stable sürüm
- Android geliştirmesi için Android SDK (platform 36, build-tools 35) ve JDK 17+

## Çalıştırma

```bash
cd app
flutter pub get
flutter run            # bağlı Android cihaz/emülatör üzerinde
```

APK üretmek için:

```bash
flutter build apk --debug
```

## Analiz ve testler

```bash
flutter analyze
flutter test
```

Ekran görüntülerini yenilemek için (yalnızca geliştiricinin isteğiyle çalışır):

```bash
BIR_OMUR_SCREENSHOTS=1 flutter test --update-goldens test/golden_screens_test.dart
```

Üretilen görüntüler `test/goldens/` altındadır. Yazı tipi ve platform farkları
görüntü karşılaştırmasını etkilediği için bu dosya normal test koşusunda atlanır.

## Klasör düzeni

```
lib/
  data/                    isim, şehir, meslek havuzları
  domain/models/           Person, PlayerCharacter, Stats, GameState ...
  domain/generation/       hayat üretimi (LifeGenerator) ve yaş alma (LifeProgression)
  domain/interaction/      aile etkileşimleri, azalan etki ve doğal ret
  domain/events/           olay motoru: uygunluk, seçim, etki ve hafıza
  state/                   GameController + GameScope
  ui/theme/                Bir Ömür teması (modern + ölçülü nostaljik)
  ui/screens/              başlangıç, karakter oluşturma, Hayat / Aile / Ben
  ui/widgets/              ortak parçalar
test/                      üretim, yaş alma ve arayüz testleri
```

## Bu aşamada bilinçli olarak **bulunmayanlar**

Aşağıdakiler sonraki aşamalara aittir; sahte düğme veya boş menü olarak da
konmamıştır:

- Hediye verme ve para gerektiren etkileşimler (ekonomi sistemi henüz yok)
- Sevgili edinme → ayrılma → eski sevgili akışı (Aşama 4)
- NPC'lerin bağımsız hayat gelişmeleri (iş değişikliği, taşınma, ölüm)
- Sosyal sekmesi, Ün sistemi, spor salonu / berber / seyahat, ekonomi
- Oyunun kaydedilmesi (durum yalnızca bellekte tutulur)

## Aile etkileşimleri (Aşama 2)

Aile → kişi → **Vakit Geçir** / **Sohbet Et**. Kurallar:

- **Genel etkileşim kotası yoktur.** Sayaçlar kişi + etkileşim türü bazındadır.
- Aynı yaşta aynı kişiyle aynı etkinliğin getirisi tekrarlarla azalır ve o yaş
  için sıfır ek kazanca iner. Etkinlik kapanmaz, sonuç metni gelmeye devam eder.
- Yakın tekrarda kişi **bazen** doğal bir gerekçeyle reddedebilir; ret hâlinde
  küçük bir mutluluk kaybı **olabilir**, her ret ceza değildir.
- Sayaçlar yaş değişince sıfırlanır. Yenilemenin tam mı kısmi mi olacağı
  `docs/CORE_LOOP.md` içinde açık bir sorudur; prototipte tam yenileme yapılır.
- Hayat günlüğüne yalnızca anlamlı sonuçlar yazılır; sıfır kazançlı tekrar
  günlüğü şişirmez.

## Olaylar (Aşama 3)

- **Yaş Al** basıldığında yeni yaşın **tek** açılış olayı çıkar; uygun olay
  yoksa hiç olay çıkmaz. Ekranda olay varken yaş ilerlemez ve ikinci olay
  açılmaz.
- Olay verisi `lib/data/event_pool.dart` içindedir: kimlik, kategori, metin,
  uygunluk (yaş, hayatta olan kişi, hane, okul çağı, hikâye izi, sahip olunan
  varlık), seçenekler, etkiler ve geleceğe bırakılan iz. **Bu şema onaylanmış
  bir tasarım kararı değildir.**
- **Hafıza:** bir seçim iz bırakır, ileriki uygun yaşta farklı bir devam açar.
  Örnek zincir: `arkadasi_savunma` → `savundugun_arkadas` **veya**
  `sessiz_kaldigin_gun`. Koşul yoksa devam gösterilmez.
- Sahip olunmayan varlık (bisiklet), gerçekleşmemiş yol (üniversite) ve
  hayatta olmayan kişi için olay çıkmaz.
- Ek olaylar **gerçek dünya dakikasıyla değil**, oyun içi ilerlemeyle gelir:
  kazanç sağlayan bir aile etkileşimi ilerleme sayılır; eşiğe ulaşınca bir
  yaşta **en fazla bir** ek olay açılır. Zamanlayıcı yoktur.
- Uzun süre temas kurulmayan hane üyesi sitem edebilir (D-025). Bu ilk kesitte
  yüzeysel bir sürümdür: yalnızca oyuncunun etkileşim geçmişine bakar, kişinin
  kendi ruh hâli veya olay geçmişi modellenmemiştir.

## Geçici prototip değerleri

Kodda `prototypeOnly` yorumuyla işaretlenmiş sayısal ağırlıklar (aile üretim
olasılıkları, başlangıç değer aralıkları, çalışma durumu dağılımları, azalma
eğrisi, ret olasılığı, etkileşimlerin açıldığı asgari yaş, olay ağırlıkları,
ek olay eşiği ve sitem için gereken yaş farkı) yalnızca prototipin
çalışabilmesi içindir. **Onaylanmış oyun dengesi değildir** ve
`DECISIONS.md` içine kural olarak yazılmamıştır.

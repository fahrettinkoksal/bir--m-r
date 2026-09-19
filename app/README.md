# Bir Ömür — prototip uygulaması (Aşama 1-2)

Flutter ile Android öncelikli geliştirilen ilk prototip.
Kapsam `docs/CLAUDE_PROTOTYPE_TASK.md` içindeki **Aşama 1 ve Aşama 2** ile
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
- Olay motoru, yaş alınca çıkan tek açılış olayı ve hikâye hafızası (Aşama 3)
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

## Geçici prototip değerleri

Kodda `prototypeOnly` yorumuyla işaretlenmiş sayısal ağırlıklar (aile üretim
olasılıkları, başlangıç değer aralıkları, çalışma durumu dağılımları, azalma
eğrisi, ret olasılığı, etkileşimlerin açıldığı asgari yaş) yalnızca prototipin
çalışabilmesi içindir. **Onaylanmış oyun dengesi değildir** ve
`DECISIONS.md` içine kural olarak yazılmamıştır.

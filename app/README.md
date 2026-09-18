# Bir Ömür — prototip uygulaması (Aşama 1)

Flutter ile Android öncelikli geliştirilen ilk prototip iskeleti.
Kapsam `docs/CLAUDE_PROTOTYPE_TASK.md` içindeki **Aşama 1** ile sınırlıdır.

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
  state/                   GameController + GameScope
  ui/theme/                Bir Ömür teması (modern + ölçülü nostaljik)
  ui/screens/              başlangıç, karakter oluşturma, Hayat / Aile / Ben
  ui/widgets/              ortak parçalar
test/                      üretim, yaş alma ve arayüz testleri
```

## Bu aşamada bilinçli olarak **bulunmayanlar**

Aşağıdakiler sonraki aşamalara aittir; sahte düğme veya boş menü olarak da
konmamıştır:

- Aile etkileşimleri (vakit geçirme, hediye), azalan etki ve doğal ret (Aşama 2)
- Olay motoru, yaş alınca çıkan tek açılış olayı ve hikâye hafızası (Aşama 3)
- Sevgili edinme → ayrılma → eski sevgili akışı (Aşama 4)
- NPC'lerin bağımsız hayat gelişmeleri (iş değişikliği, taşınma, ölüm)
- Sosyal sekmesi, Ün sistemi, spor salonu / berber / seyahat, ekonomi
- Oyunun kaydedilmesi (durum yalnızca bellekte tutulur)

## Geçici prototip değerleri

Kodda `prototypeOnly` yorumuyla işaretlenmiş sayısal ağırlıklar (aile üretim
olasılıkları, başlangıç değer aralıkları, çalışma durumu dağılımları) yalnızca
prototipin çalışabilmesi içindir. **Onaylanmış oyun dengesi değildir** ve
`DECISIONS.md` içine kural olarak yazılmamıştır.

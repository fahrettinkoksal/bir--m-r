# Bir Ömür — prototip uygulaması (Aşama 1-4 + okul paketi)

Flutter ile Android öncelikli geliştirilen ilk prototip.
Kapsam `docs/CLAUDE_PROTOTYPE_TASK.md` içindeki **Aşama 1, 2, 3 ve 4** ile
**temel okul sistemi + küçük okul olay paketi**dir
(`docs/APPROVED_SCOPE_AND_EVENT_STRATEGY.md`, GEN-001).

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

Telefona kurulabilir hazır APK'yı GitHub Actions üretir. İndirme ve kurulum
adımları: [`docs/ANDROID_TEST_APK.md`](../docs/ANDROID_TEST_APK.md).

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
  domain/interaction/      aile etkileşimleri, azalan etki, doğal ret,
                           romantik ilişki, arkadaşlık
  domain/events/           olay motoru: uygunluk, seçim, etki ve hafıza
  state/                   GameController + GameScope
  ui/theme/                Bir Ömür teması (modern + ölçülü nostaljik)
  ui/screens/              başlangıç, karakter oluşturma, ana kabuk
  ui/screens/sections/     Okul/Meslek, Varlıklar, İlişkiler, Aktiviteler
  ui/widgets/              ortak parçalar
test/                      üretim, yaş alma ve arayüz testleri
```

## Bu aşamada bilinçli olarak **bulunmayanlar**

Aşağıdakiler sonraki aşamalara aittir; sahte düğme veya boş menü olarak da
konmamıştır:

- Hediye verme ve para gerektiren etkileşimler (ekonomi sistemi henüz yok)
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

## Romantik ilişki (Aşama 4)

Durakta tanışma → çıkma teklifi → **sevgili** → ayrılık → **eski sevgili**.

- Sevgili, teklif seçimiyle oluşur ve Aile bölümünde **İlişkiler** başlığı
  altında sevgili statüsüyle listelenir.
- Ayrılık iki yoldan yapılabilir: kişi detayındaki **Ayrıl** düğmesi veya
  ilişki tartışması olayındaki ayrılma seçeneği.
- **Ayrılınca kişi kaydı silinmez ve yeniden yaratılmaz.** Aynı kimlik, aynı
  isim ve aynı yakınlık değeriyle eski sevgili statüsüne geçer; hayat günlüğü
  korunur.
- Sevgili/akraba/hane ayrı kavramlardır: sevgili kan bağı sayılmaz ve
  otomatik olarak oyuncunun hanesine yerleştirilmez.
- Eski sevgiliye sevgiliye özel eylemler **koşulsuz sunulmaz**; bu sürümde
  etkileşimler kapalıdır ve gerekçesi ekranda yazılıdır.
- Hikâye her hayatta zorunlu değildir; uygun yaş ve koşulda ortaya çıkar.

## Gezinme ve ekran düzeni (NAV-001)

- Üstte **sabit karakter özeti**: ad, yaş ve evre, şehir, kısa durum, kişisel
  cüzdan ve beş değerin okunaklı şeridi (şeride dokununca tam adlarıyla
  ayrıntı açılır).
- Ortada **hayat günlüğü / olay akışı** ya da seçilen ana menünün ekranı.
- Altta sabit çubuk, soldan sağa:
  **Okul/Meslek — Varlıklar — [Yaş Al] — İlişkiler — Aktiviteler.**
  `Yaş Al` bir sekme değil, menülerin arasındaki **bağımsız ana eylem**dir.
- Soldaki menü duruma göre değişir: oyuncu öğrenciyken **Okul**, değilken
  **Meslek**.
- Seçili menüye tekrar dokunmak (veya ekrandaki "Hayat" satırı) ana ekrana
  döndürür.
- İlişkiler ve Aktiviteler **iç içe menü** mantığıyla çalışır.

## Okul (temel sistem + küçük olay paketi)

- **Öğrencilik yaştan türetilmez.** `EducationState` oyun verisinde tutulur:
  kayıtlı mı, kaçıncı sınıf, hangi yaşta başladı, bitti mi. Okula başlamamış
  veya okulu bitirmiş karaktere okul olayı çıkmaz.
- Basit akış: 6 yaşında 1. sınıf → her yaş bir sınıf → 4+4+4 kademe
  (ilkokul / ortaokul / lise) → 12. sınıftan sonra okul biter. **Sınav, not,
  diploma, sınıf tekrarı ve okulu bırakma yoktur.**
- Okulda tanışılan arkadaş **kalıcı kimlikli gerçek bir kişi kaydıdır**;
  Aile bölümünde "Arkadaşlar" başlığı altında görünür, akraba sayılmaz ve
  otomatik olarak haneye yerleştirilmez. Sonraki olaylar aynı kişiyi kullanır.
- Olay paketi (5 olay): sıra arkadaşıyla tanışma, teneffüs oyun daveti,
  arkadaşın ödev yardımı isteği, öğretmenin sorusu ve **yardımın karşılığı**.
  Sonuncusu yalnızca daha önce yardım etmiş oyuncuya çıkar — geçmiş seçim
  ileride gerçekten hatırlanır.
- Olaylar `minGrade` / `maxGrade` ile sınıfa da bağlanabilir.

## Cüzdan (ECO-001 — yalnızca temel)

Oyuncunun **kendi** bakiyesi `PlayerCharacter.wallet` içinde tutulur ve üst
özette gösterilir. Ailenin ekonomik durumu ayrıdır; aile varlığı oyuncunun
harcayabileceği para sayılmaz. Bu sürümde kazanma/harcama akışı **yoktur**;
bakiye yalnızca olay etkileriyle değişebilir. Para birimi, başlangıç bakiyesi
ve ekonomi kuralları kararlaştırılmadı.

## Geçici prototip değerleri

Kodda `prototypeOnly` yorumuyla işaretlenmiş sayısal ağırlıklar (aile üretim
olasılıkları, başlangıç değer aralıkları, çalışma durumu dağılımları, azalma
eğrisi, ret olasılığı, etkileşimlerin açıldığı asgari yaş, olay ağırlıkları,
ek olay eşiği, sitem için gereken yaş farkı, romantik olayların yaş aralıkları
ve partnerin cinsiyetinin oyuncunun karşıtı seçilmesi, okula başlama yaşı ve
sınıf akışı) yalnızca prototipin çalışabilmesi içindir. **Onaylanmış oyun dengesi değildir** ve
`DECISIONS.md` içine kural olarak yazılmamıştır.

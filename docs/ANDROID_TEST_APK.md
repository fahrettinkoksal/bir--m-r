# Bir Ömür — Android test APK'sı

Bu belge, prototipi gerçek bir Android telefona kurup denemek içindir.
İki yol var: **GitHub Actions'ın ürettiği hazır APK** (kolay yol) veya
**Windows bilgisayarda yerel derleme** (Actions çalışmazsa).

APK **debug** sürümüdür: imzası geliştirme anahtarıyla atılmıştır, Play
Store'a yüklenemez, sadece test içindir. Oyun durumu **kaydedilmez**;
uygulamayı kapatınca hayat sıfırlanır.

**Ölçülen değerler** (19 Eylül 2026, ilk başarılı koşu):

| | |
| --- | --- |
| APK boyutu | **135 MB** (debug, bütün işlemci mimarileri bir arada) |
| İndirilen zip | **~63 MB** |
| Derleme süresi | ~7,5 dakika (Gradle adımı 295 sn) |
| Artifact ömrü | 30 gün |

Debug APK büyüktür; ileride `--release` ile derlenen sürüm çok daha küçük
olacaktır. Telefonda **en az ~400 MB boş alan** bulundur.

---

## Yol 1 — GitHub Actions'tan APK indirmek

### 1. İş akışını çalıştır

`Android debug APK` iş akışı, `claude/**` dallarına yapılan her gönderimde
ve `main`'de kendiliğinden çalışır. Elle çalıştırmak için:

1. GitHub'da depoyu aç: `fahrettinkoksal/bir--m-r`
2. Üstteki **Actions** sekmesine tıkla.
3. Soldaki listeden **Android debug APK**'yı seç.
4. Sağda **Run workflow** düğmesine bas, dal olarak APK istediğin dalı seç
   (ör. `claude/android-apk-v1`) ve tekrar **Run workflow** de.

### 2. Sonucu bekle

Koşu listede görünür. Yeşil ✅ olunca derleme başarılıdır. Kırmızı ❌ ise
koşuya tıklayıp hangi adımın patladığına bakabilirsin; son adım ortam
bilgisini (`flutter doctor -v`) yazdırır.

### 3. APK'yı indir

1. Başarılı koşuya tıkla.
2. Sayfanın **en altındaki `Artifacts`** bölümüne in.
3. **`bir-omur-debug-apk`** dosyasına tıkla — bir **.zip** iner.
4. Zip'i aç; içinden **`app-debug.apk`** çıkar.

> Artifact'lar 30 gün sonra silinir. Telefondan indiriyorsan zip'i
> telefonun dosya yöneticisiyle açman gerekir.

### 4. Telefona kur

1. APK'yı telefona aktar (USB kablo, Google Drive, WhatsApp "kendine
   gönder", e-posta — hangisi kolaysa).
2. Telefonda **Dosyalar** uygulamasından `app-debug.apk` dosyasına dokun.
3. Android **"Bilinmeyen kaynaklardan uygulama yükleme"** izni isteyecek:
   açılan uyarıda **Ayarlar** → kurulumu yapan uygulamaya (Dosyalar,
   Chrome vb.) **"Bu kaynağa izin ver"** de, sonra geri dönüp **Yükle**ye bas.
4. Kurulum bitince uygulama çekmecesinde **Bir Ömür** görünür.

**Play Protect uyarısı** çıkabilir ("Bilinmeyen uygulama"): imzasız/debug
APK'larda normaldir, **Yine de yükle** diyebilirsin.

---

## Yol 2 — Windows'ta yerel derleme

Actions çalışmazsa veya daha hızlı denemek istersen.

### Bir kerelik kurulum

1. **Git**: <https://git-scm.com/download/win>
2. **Flutter SDK 3.35.5 (stable)**: <https://docs.flutter.dev/get-started/install/windows>
   İndir, `C:\src\flutter` gibi **boşluksuz** bir klasöre aç ve
   `C:\src\flutter\bin` yolunu **Path** ortam değişkenine ekle.
3. **Android Studio**: <https://developer.android.com/studio>
   Kurulumda **Android SDK**, **Android SDK Platform-Tools** ve
   **Android SDK Command-line Tools** bileşenlerini seç.
4. PowerShell aç ve lisansları onayla:

   ```powershell
   flutter doctor
   flutter doctor --android-licenses
   ```

   `flutter doctor` çıktısındaki Android satırı ✓ olana kadar eksikleri tamamla.

### Derleme

```powershell
git clone https://github.com/fahrettinkoksal/bir--m-r.git
cd bir--m-r
git checkout claude/android-apk-v1
cd app
flutter pub get
flutter build apk --debug
```

APK şurada oluşur:

```
app\build\app\outputs\flutter-apk\app-debug.apk
```

### Telefonda doğrudan çalıştırmak (en pratik yol)

1. Telefonda **Ayarlar → Telefon hakkında → Yapı numarası**na 7 kez dokun
   (Geliştirici seçenekleri açılır).
2. **Ayarlar → Geliştirici seçenekleri → USB hata ayıklama**yı aç.
3. Telefonu USB ile bilgisayara bağla, telefondaki izin uyarısını onayla.
4. PowerShell'de `app` klasöründeyken:

   ```powershell
   flutter devices
   flutter run
   ```

   Uygulama doğrudan telefona kurulup açılır.

Kablo yerine APK dosyasını kopyalayıp kurmak istersen Yol 1'deki
**"Telefona kur"** adımları aynen geçerlidir.

---

## Sık karşılaşılan sorunlar

| Belirti | Sebep / çözüm |
| --- | --- |
| `flutter doctor`'da Android toolchain ✗ | Android SDK eksik; Android Studio'dan SDK ve command-line tools kur, `flutter doctor --android-licenses` çalıştır. |
| Gradle indirmede takılma | İlk derleme Gradle ve bağımlılıkları indirir, uzun sürebilir; internet/proxy engeli varsa derleme başarısız olur. |
| `SDK location not found` | `app` klasöründen `flutter build apk` çalıştır; Flutter `local.properties` dosyasını kendisi üretir. |
| Telefon "uygulama yüklenmedi" diyor | Aynı paket adına sahip eski sürümü kaldır, sonra tekrar dene. |
| Play Protect engelliyor | Debug APK'da normaldir; **Yine de yükle**. |

## Bilinen sınırlar

- APK **debug** sürümüdür; performans release sürümünden düşüktür.
- **Oyun kaydı yok**: uygulamayı kapatınca hayat baştan başlar.
- Görsel tasarım hâlâ onay bekliyor (`docs/DESIGN_REVIEW_QUEUE.md` → Q-001).

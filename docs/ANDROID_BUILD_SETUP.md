# Android derleme zinciri — ne eksik, ne yapılmalı

**Durum (6 Ekim 2026): APK bu ortamda derlenemiyor.** Oyun hiç
derlenmedi ve hiçbir cihazda çalıştırılmadı. 3359 test geçiyor, ama bu
"kod kendi içinde tutarlı" demektir; "oyun çalışıyor" demez.

## Ölçülen durum

| Parça | Durum |
|---|---|
| Flutter 3.35.5 / Dart 3.9.2 | **var** (`/opt/flutter`) |
| JDK | **var** (sistem JDK'sı, proxy'ye ayarlı) |
| Android SDK | **yok** (`ANDROID_HOME` ve `ANDROID_SDK_ROOT` tanımsız) |

## Tek engel: `dl.google.com`

Android SDK paketleri `dl.google.com/android/repository/` üzerinden
iniyor ve bu host **ağ politikası tarafından reddediliyor**. Ölçüm:

```
dl.google.com        → 000   (gateway CONNECT'e 403: policy denial)
maven.google.com     → 301   açık
services.gradle.org  → 200   açık
repo1.maven.org      → 200   açık
pub.dev              → 200   açık
```

Yani Gradle ve Maven tarafı zaten açık; eksik olan **tek** host
`dl.google.com`.

## Yapılması gereken (Faho)

1. Ortam ayarlarında **Network access** bölümünü aç (oturum başlığındaki
   bulut ortamı menüsü → Edit). Ya daha geniş bir erişim seviyesi seç,
   ya da **Custom** seçip **Allowed domains** listesine `dl.google.com`
   ekle — paket yöneticilerinin varsayılan listesi kalsın. Adımlar:
   <https://code.claude.com/docs/en/cloud-environments#network-access>
2. Aynı ekranda **Setup script** alanına şunu ekle:
   ```
   bash scripts/setup_android_sdk.sh
   ```
3. Environment variables bölümüne:
   ```
   ANDROID_SDK_ROOT=/opt/android-sdk
   ANDROID_HOME=/opt/android-sdk
   ```

Yeni oturumlar düzeltilmiş script'le başlar.

## Doğrulama

Script `scripts/setup_android_sdk.sh` içinde; sürümleri Flutter'ın kendi
varsayılanlarından okundu (compileSdk 36, targetSdk 36, minSdk 24).
Kurulumdan sonra:

```bash
export PATH=/opt/flutter/bin:$PATH
cd app
flutter doctor -v          # "Android toolchain" satırı ✓ olmalı
flutter build apk --debug  # ilk derleme Gradle'ı indirir, uzun sürer
```

APK yolu: `app/build/app/outputs/flutter-apk/app-debug.apk`

## Derleme açıldıktan sonra sırada ne var

Derlemek **görmek değildir**. Sırası:

1. `flutter build apk --debug` geçsin (derleme hataları).
2. `flutter doctor` temiz olsun.
3. Cihazda/emülatörde açılsın ve ilk ekran görünsün.
4. Bir hayat baştan sona oynanıp ekranlar gözle kontrol edilsin.

Bu dört adım tamamlanana kadar hiçbir belgede "çalışıyor", "oynandı" ya
da "cihazda test edildi" yazılmayacak (CLAUDE.md kuralı).

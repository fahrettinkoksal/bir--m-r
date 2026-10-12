#!/usr/bin/env bash
# Bir Ömür — Android derleme zincirini kuran ortam script'i.
#
# Bu dosya oyunun kodunu değiştirmez. Ortamın **Setup script** alanına
# yapıştırıldığında (ya da oradan `bash scripts/setup_android_sdk.sh`
# diye çağrıldığında) APK derlemek için eksik olan tek parçayı kurar:
# Android SDK komut satırı araçları.
#
# ÖN KOŞUL — AĞ: SDK paketleri **dl.google.com** üzerinden iner. Bu depo
# için ölçülen durum (6 Ekim 2026): gateway `dl.google.com:443` CONNECT
# isteğine **403** veriyor, yani politika reddi. Diğer derleme adresleri
# açık: maven.google.com 301, services.gradle.org 200, repo1.maven.org
# 200, pub.dev 200. Yani ağ politikasına eklenmesi gereken **tek** host
# dl.google.com'dur.
#
# Java ve Flutter hazır: /opt/flutter (Flutter 3.35.5 / Dart 3.9.2) ve
# sistem JDK'sı kurulu. Eksik olan yalnızca SDK.
set -euo pipefail

SDK_DIR="${ANDROID_SDK_ROOT:-/opt/android-sdk}"
CMDLINE_VER="11076708"   # cmdline-tools 13.0
ZIP="commandlinetools-linux-${CMDLINE_VER}_latest.zip"
URL="https://dl.google.com/android/repository/${ZIP}"

echo "==> Android SDK dizini: $SDK_DIR"
mkdir -p "$SDK_DIR/cmdline-tools"

if [ ! -x "$SDK_DIR/cmdline-tools/latest/bin/sdkmanager" ]; then
  echo "==> Komut satırı araçları indiriliyor"
  tmp="$(mktemp -d)"
  # Host kapalıysa burada durur; hata mesajı açık olsun.
  if ! curl -fsSL "$URL" -o "$tmp/$ZIP"; then
    echo "HATA: $URL indirilemedi." >&2
    echo "Ağ politikası dl.google.com'u engelliyor olabilir. Ortam" >&2
    echo "ayarlarındaki Network access bölümüne bu host eklenmeli." >&2
    exit 1
  fi
  unzip -q "$tmp/$ZIP" -d "$tmp"
  rm -rf "$SDK_DIR/cmdline-tools/latest"
  mv "$tmp/cmdline-tools" "$SDK_DIR/cmdline-tools/latest"
  rm -rf "$tmp"
fi

export ANDROID_SDK_ROOT="$SDK_DIR"
export ANDROID_HOME="$SDK_DIR"
export PATH="$SDK_DIR/cmdline-tools/latest/bin:$SDK_DIR/platform-tools:$PATH"

echo "==> Lisanslar kabul ediliyor"
yes | sdkmanager --licenses >/dev/null 2>&1 || true

# Sürümler **Flutter 3.35.5'in kendi varsayılanlarından** okundu
# (FlutterExtension.kt): compileSdk 36, targetSdk 36, minSdk 24,
# ndk 27.0.12077973. app/android/app/build.gradle.kts bu varsayılanları
# kullanıyor (`flutter.compileSdkVersion` vb.), elle sabitlenmiş sürüm
# yok — Flutter yükseltilirse burayı da güncelle.
echo "==> Paketler kuruluyor"
sdkmanager --install \
  "platform-tools" \
  "platforms;android-36" \
  "build-tools;36.0.0" >/dev/null

# NDK yalnızca yerel kod taşıyan bir eklenti varsa gerekir. Şu an
# gerekmiyor; derleme NDK isterse şu satırı aç:
#   sdkmanager --install "ndk;27.0.12077973" >/dev/null

echo "==> Flutter'a SDK yolu bildiriliyor"
/opt/flutter/bin/flutter config --android-sdk "$SDK_DIR" >/dev/null

cat <<'NOT'

Kurulum bitti. Kalıcı olması için ortamın environment variables
bölümüne şunlar eklenmeli:

  ANDROID_SDK_ROOT=/opt/android-sdk
  ANDROID_HOME=/opt/android-sdk

Doğrulama (bu sırayla):

  export PATH=/opt/flutter/bin:$PATH
  cd app
  flutter doctor -v                 # Android toolchain ✓ olmalı
  flutter build apk --debug         # ilk derleme Gradle indirir, uzun sürer

NOT

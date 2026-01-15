#!/bin/sh

# Hata olursa durdur
set -e

# Flutter'ın kurulacağı yer
FLUTTER_ROOT="$CI_WORKSPACE/flutter"

# Flutter'ı indir (Stable sürüm)
git clone https://github.com/flutter/flutter.git -b stable "$FLUTTER_ROOT"

# Flutter'ı PATH'e ekle (Komut olarak çalışması için)
export PATH="$FLUTTER_ROOT/bin:$PATH"

# Flutter dosyalarını indir (pub get)
cd "$CI_WORKSPACE"
flutter pub get

# iOS için gerekli dosyaları kur (Pod install)
cd ios
pod install

echo "Flutter kurulumu ve hazırlığı tamamlandı!"
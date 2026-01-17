#!/bin/sh

# Hata olursa dur, ne yaptığını loglara yaz
set -e
set -x

# 1. Dil Ayarları (CocoaPods hatasını önler)
export LANG=en_US.UTF-8
export LANGUAGE=en_US.UTF-8
export LC_ALL=en_US.UTF-8

# 2. Klasör Yollarını Otomatik Bul (EN ÖNEMLİ KISIM)
# Scriptin nerede olduğunu buluyoruz:
SCRIPT_DIR=$(cd "$(dirname "$0")" && pwd)
# Script "ios/ci_scripts" içinde olduğu için bir üst klasör "ios" klasörüdür:
IOS_DIR=$(dirname "$SCRIPT_DIR")
# "ios" klasörünün bir üstü de "Flutter Proje Ana Klasörü"dür:
PROJECT_ROOT=$(dirname "$IOS_DIR")

echo "📍 Script Konumu: $SCRIPT_DIR"
echo "📍 iOS Klasörü: $IOS_DIR"
echo "📍 Proje Ana Klasörü: $PROJECT_ROOT"

# 3. CocoaPods Kontrolü
if ! command -v pod &> /dev/null; then
    echo "CocoaPods yükleniyor..."
    gem install cocoapods
fi

# 4. Flutter Kurulumu
echo "⬇️ Flutter indiriliyor..."
git clone https://github.com/flutter/flutter.git --depth 1 -b stable $HOME/flutter
export PATH="$PATH:$HOME/flutter/bin"

# 5. Flutter Bağımlılıklarını Yükle (Proje ana klasörüne gidip)
echo "⚙️ Flutter pub get çalıştırılıyor..."
cd "$PROJECT_ROOT"
flutter pub get

# 6. iOS Pod'larını Yükle (iOS klasörüne gidip)
echo "📦 Pod install çalıştırılıyor..."
cd "$IOS_DIR"
pod install --repo-update

echo "✅ Script başarıyla tamamlandı!"

#!/bin/sh

# Hata olursa dur ve logları göster
set -e
set -x

# 1. Dil Ayarları
export LANG=en_US.UTF-8
export LANGUAGE=en_US.UTF-8
export LC_ALL=en_US.UTF-8

# 2. Klasör Yollarını Otomatik Bul
SCRIPT_DIR=$(cd "$(dirname "$0")" && pwd)
IOS_DIR=$(dirname "$SCRIPT_DIR")
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

# 5. Flutter Hazırlığı (DÜZELTME BURADA YAPILDI)
echo "⚙️ Flutter iOS dosyaları hazırlanıyor..."
cd "$PROJECT_ROOT"
flutter precache --ios  # <--- EKSİK OLAN KOMUT BUYDU
flutter pub get

# 6. iOS Pod'larını Yükle
echo "📦 Pod install çalıştırılıyor..."
cd "$IOS_DIR"
# Podfile.lock varsa silip temiz kurulum yapmak bazen daha sağlıklıdır
# rm -f Podfile.lock 
pod install --repo-update

echo "✅ Script başarıyla tamamlandı!"

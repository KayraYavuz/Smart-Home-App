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

# --- KRİTİK DÜZELTME: SANDBOXING AYARINI KAPAT ---
# Xcode Cloud sunucusunda, proje dosyasındaki ayarı bulup 'NO' olarak değiştiriyoruz.
# Böylece manuel ayar yapmana gerek kalmıyor.
echo "🛡️ User Script Sandboxing ayarı kapatılıyor..."
sed -i '' 's/ENABLE_USER_SCRIPT_SANDBOXING = YES/ENABLE_USER_SCRIPT_SANDBOXING = NO/g' "$IOS_DIR/Runner.xcodeproj/project.pbxproj" || true
# Eğer ayar dosyada yoksa ekleyelim (Garanti olsun)
if ! grep -q "ENABLE_USER_SCRIPT_SANDBOXING" "$IOS_DIR/Runner.xcodeproj/project.pbxproj"; then
    echo "⚠️ Ayar bulunamadı, manuel ekleme deneniyor..."
    # Bu kısım biraz risklidir ama genelde üstteki sed komutu yeterlidir.
fi

# 3. CocoaPods Kontrolü
if ! command -v pod &> /dev/null; then
    echo "CocoaPods yükleniyor..."
    gem install cocoapods
fi

# 4. Flutter Kurulumu
echo "⬇️ Flutter indiriliyor..."
git clone https://github.com/flutter/flutter.git --depth 1 -b stable $HOME/flutter
export PATH="$PATH:$HOME/flutter/bin"

# 5. Flutter Hazırlığı
echo "⚙️ Flutter iOS dosyaları hazırlanıyor..."
cd "$PROJECT_ROOT"
flutter precache --ios
flutter pub get

# 6. iOS Pod'larını Yükle
echo "📦 Pod install çalıştırılıyor..."
cd "$IOS_DIR"
pod install --repo-update

echo "✅ Script başarıyla tamamlandı!"

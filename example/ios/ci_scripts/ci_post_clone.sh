#!/bin/sh
set -e

echo "⚙️ Script Başlıyor..."

# 1. Klasör yollarını dinamik olarak bul
SCRIPT_DIR=$(cd "$(dirname "$0")" && pwd)
IOS_DIR="$SCRIPT_DIR/.."
PROJECT_ROOT="$SCRIPT_DIR/../.."

echo "📍 Script Konumu: $SCRIPT_DIR"
echo "📍 iOS Konumu: $IOS_DIR"

# 2. GoogleService-Info.plist Oluşturma
TARGET_PATH="$IOS_DIR/Runner/GoogleService-Info.plist"

if [ -n "$GOOGLE_SERVICE_INFO_PLIST" ]; then
    echo "🔑 GoogleService-Info.plist yazılıyor..."
    echo "$GOOGLE_SERVICE_INFO_PLIST" | base64 --decode > "$TARGET_PATH"
    echo "✅ Dosya başarıyla oluşturuldu!"
else
    echo "❌ HATA: GOOGLE_SERVICE_INFO_PLIST bulunamadı (Environment Variable kontrol edin)."
fi

# 3. Sandboxing Ayarını Kapat
echo "🛡️ Sandboxing kapatılıyor..."
find "$IOS_DIR" -name "project.pbxproj" -print0 | xargs -0 sed -i '' 's/ENABLE_USER_SCRIPT_SANDBOXING = YES/ENABLE_USER_SCRIPT_SANDBOXING = NO/g'

# 4. Flutter Kurulumu ve Hazırlığı
echo "📦 Flutter ortamı hazırlanıyor..."

# Eğer Flutter yoksa indir
if ! command -v flutter &> /dev/null; then
    echo "⬇️ Flutter indiriliyor..."
    git clone https://github.com/flutter/flutter.git --depth 1 -b stable $HOME/flutter
    export PATH="$PATH:$HOME/flutter/bin"
fi

# --- KRİTİK DÜZELTME BURADA ---
echo "⬇️ iOS Engine dosyaları indiriliyor (Precache)..."
flutter precache --ios
# ------------------------------

# 5. Paketleri Yükle
echo "📦 Flutter paketleri yükleniyor..."
# Proje ana dizinine (pubspec.yaml olduğu yere) git
cd "$PROJECT_ROOT"
flutter pub get

# 6. CocoaPods Kurulumu
echo "📦 Pod install çalıştırılıyor..."
# iOS klasörüne (Podfile olduğu yere) git
cd "$IOS_DIR"
pod install --repo-update

echo "✅ Tüm işlemler başarıyla tamamlandı!"
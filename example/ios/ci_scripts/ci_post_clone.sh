#!/bin/sh
set -e

echo "⚙️ Script Başlıyor..."

# 1. Scriptin kendi bulunduğu klasörü bul (Örn: .../ios/ci_scripts)
SCRIPT_DIR=$(cd "$(dirname "$0")" && pwd)

# 2. Hedef dosya yolunu scriptin konumuna göre ayarla
# (ci_scripts klasöründen bir yukarı çık (..) -> Runner klasörüne gir)
TARGET_PATH="$SCRIPT_DIR/../Runner/GoogleService-Info.plist"

echo "📍 Hedef Yol Belirlendi: $TARGET_PATH"

# 3. Dosyayı oluştur
if [ -n "$GOOGLE_SERVICE_INFO_PLIST" ]; then
    echo "🔑 GoogleService-Info.plist yazılıyor..."
    echo "$GOOGLE_SERVICE_INFO_PLIST" | base64 --decode > "$TARGET_PATH"
    echo "✅ Dosya başarıyla oluşturuldu!"
else
    echo "❌ HATA: GOOGLE_SERVICE_INFO_PLIST bulunamadı, ancak script devam edecek."
fi

# 4. Sandboxing Ayarını Kapat (Garanti olsun)
# Proje dosyası da scriptin 2 üstünde veya 1 üstünde olabilir, garanti yöntem:
find "$SCRIPT_DIR/.." -name "project.pbxproj" -print0 | xargs -0 sed -i '' 's/ENABLE_USER_SCRIPT_SANDBOXING = YES/ENABLE_USER_SCRIPT_SANDBOXING = NO/g'
echo "🛡️ Sandboxing kapatıldı."

# 5. Pod Install İşlemleri
echo "📦 Pod install hazırlanıyor..."
# ios klasörüne geç (scriptin bir üstü)
cd "$SCRIPT_DIR/.."

# Flutter ve Pod kurulumu
if command -v flutter &> /dev/null; then
    flutter pub get
else
    # Eğer flutter path'de yoksa, garanti olması için git clone yapalım
    git clone https://github.com/flutter/flutter.git --depth 1 -b stable $HOME/flutter
    export PATH="$PATH:$HOME/flutter/bin"
    cd "$CI_PRIMARY_REPOSITORY_PATH" # Ana dizine dön
    flutter pub get
    cd "$SCRIPT_DIR/.." # Tekrar ios klasörüne dön
fi

pod install --repo-update

echo "✅ Tüm işlemler tamamlandı!"
#!/bin/sh

# Hata olursa durdur ve her komutu ekrana yaz (Debug modu)
set -e
set -x

echo "=== BAŞLANGIÇ: CI Post Clone Script ($(date)) ==="

# 1. GoogleService-Info.plist ve .env dosyalarını oluştur
if [ -n "$GOOGLE_SERVICE_INFO_PLIST_CONTENT_BASE64" ]; then
    echo "GoogleService-Info.plist (Base64) decode ediliyor..."
    echo "$GOOGLE_SERVICE_INFO_PLIST_CONTENT_BASE64" | base64 --decode > ../GoogleService-Info.plist
elif [ -n "$GOOGLE_SERVICE_INFO_PLIST_CONTENT" ]; then
    echo "GoogleService-Info.plist (Düz Metin) dosyası oluşturuluyor..."
    echo "$GOOGLE_SERVICE_INFO_PLIST_CONTENT" > ../GoogleService-Info.plist
else
    echo "⚠️ UYARI: GOOGLE_SERVICE_INFO_PLIST_CONTENT değişkeni bulunamadı. Dummy oluşturuluyor."
    cat <<EOF > ../GoogleService-Info.plist
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
	<key>API_KEY</key>
	<string>AIzaSyFakeKeyForDebuggingOnly12345</string>
	<key>GCM_SENDER_ID</key>
	<string>1234567890</string>
	<key>PLIST_VERSION</key>
	<string>1</string>
	<key>BUNDLE_ID</key>
	<string>com.ahmetkayra.proje.v1</string>
	<key>PROJECT_ID</key>
	<string>test-project-id</string>
	<key>STORAGE_BUCKET</key>
	<string>test-project-id.appspot.com</string>
	<key>IS_ADS_ENABLED</key>
	<false/>
	<key>IS_ANALYTICS_ENABLED</key>
	<false/>
	<key>IS_APPINVITE_ENABLED</key>
	<true/>
	<key>IS_GCM_ENABLED</key>
	<true/>
	<key>IS_SIGNIN_ENABLED</key>
	<true/>
	<key>GOOGLE_APP_ID</key>
	<string>1:1234567890:ios:aaaaaaaaaaaaaaaa</string>
</dict>
</plist>
EOF
fi

# .env oluşturma
if [ -n "$ENV_FILE_CONTENT_BASE64" ]; then
    echo "Creating .env from Base64..."
    echo "$ENV_FILE_CONTENT_BASE64" | base64 --decode > ../../.env
elif [ -n "$ENV_FILE_CONTENT" ]; then
    echo "Creating .env from plain text..."
    echo "$ENV_FILE_CONTENT" > ../../.env
else
    echo "Creating empty .env..."
    touch ../../.env
fi

# 2. Flutter Kurulumu
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

if [ -z "$CI_WORKSPACE" ]; then
    if [ -n "$CI_PRIMARY_REPOSITORY_PATH" ]; then
        CI_WORKSPACE="$CI_PRIMARY_REPOSITORY_PATH"
    else
        CI_WORKSPACE="$(cd "$SCRIPT_DIR/../../.." && pwd)"
    fi
fi

FLUTTER_ROOT="$CI_WORKSPACE/flutter"

if [ ! -d "$FLUTTER_ROOT" ]; then
    echo "Flutter indiriliyor (stable)..."
    START_CLONE=$(date +%s)
    git clone https://github.com/flutter/flutter.git --depth 1 -b stable "$FLUTTER_ROOT"
    END_CLONE=$(date +%s)
    echo "Flutter clone süresi: $((END_CLONE - START_CLONE)) saniye"
fi

export PATH="$FLUTTER_ROOT/bin:$PATH"
echo "Flutter version checking..."
flutter --version

# 3. Proje Bağımlılıkları
if [ -z "$PROJECT_DIR" ]; then
    PROJECT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
fi

cd "$PROJECT_DIR"
echo "Proje dizini: $(pwd)"

echo "Flutter paketleri yükleniyor..."
flutter pub get

echo "Yerelleştirme dosyaları oluşturuluyor..."
flutter gen-l10n

echo "iOS konfigürasyonu hazırlanıyor..."
flutter build ios --config-only --no-codesign

# 4. iOS Pod Kurulumu
cd ios
echo "Pod dosyaları temizleniyor..."
rm -rf Pods
rm -rf Podfile.lock

# Git buffer boyutunu artır (Büyük podlar için)
git config --global http.postBuffer 524288000
git config --global http.lowSpeedLimit 0
git config --global http.lowSpeedTime 999999

echo "Pod install çalıştırılıyor (retry mekanizması ile)..."
START_POD=$(date +%s)

MAX_RETRIES=3
RETRY_COUNT=0
SUCCESS=false

while [ $RETRY_COUNT -lt $MAX_RETRIES ]; do
    if pod install --repo-update; then
        SUCCESS=true
        break
    else
        RETRY_COUNT=$((RETRY_COUNT + 1))
        echo "⚠️ Pod install başarısız oldu (Deneme $RETRY_COUNT/$MAX_RETRIES). 30 saniye sonra tekrar denenecek..."
        sleep 30
    fi
done

if [ "$SUCCESS" = false ]; then
    echo "❌ HATA: $MAX_RETRIES denemeden sonra pod install hala başarısız."
    exit 1
fi

END_POD=$(date +%s)
echo "Pod install süresi: $((END_POD - START_POD)) saniye"

echo "=== BİTİŞ: $(date) ==="
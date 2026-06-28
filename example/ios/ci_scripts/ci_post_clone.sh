#!/bin/sh

# Hata olursa durdur ve her komutu ekrana yaz (Debug modu)
set -e
set -x

SCRIPT_DIR="$( cd "$( dirname "$0" )" && pwd )"

echo "=== BAŞLANGIÇ: CI Post Clone Script ($(date)) ==="

# 1. GoogleService-Info.plist ve .env dosyalarını oluştur
if [ -n "$GOOGLE_SERVICE_INFO_PLIST_CONTENT_BASE64" ]; then
    echo "GoogleService-Info.plist (Base64) decode ediliyor..."
    echo "$GOOGLE_SERVICE_INFO_PLIST_CONTENT_BASE64" | base64 --decode > ../Runner/GoogleService-Info.plist
elif [ -n "$GOOGLE_SERVICE_INFO_PLIST_CONTENT" ]; then
    echo "GoogleService-Info.plist (Düz Metin) dosyası oluşturuluyor..."
    echo "$GOOGLE_SERVICE_INFO_PLIST_CONTENT" > ../Runner/GoogleService-Info.plist
else
    echo "⚠️ UYARI: GOOGLE_SERVICE_INFO_PLIST_CONTENT değişkeni bulunamadı. Dummy oluşturuluyor."
    cat <<EOF > ../Runner/GoogleService-Info.plist
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

# COPY to ios/GoogleService-Info.plist (Duplicate for build requirement)
cp ../Runner/GoogleService-Info.plist ../GoogleService-Info.plist
echo "GoogleService-Info.plist kopyalandı: ../GoogleService-Info.plist"

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

# Flutter'ı Repository içinde klonlayarak Sandbox kısıtlamalarını (PhaseScriptExecution yetki hatasını) önlüyoruz.
if [ -n "$CI_PRIMARY_REPOSITORY_PATH" ]; then
    FLUTTER_ROOT="$CI_PRIMARY_REPOSITORY_PATH/flutter"
else
    FLUTTER_ROOT="$(cd "$SCRIPT_DIR/../../.." && pwd)/flutter"
fi

if [ ! -d "$FLUTTER_ROOT" ]; then
    echo "Flutter indiriliyor (stable)..."
    START_CLONE=$(date +%s)
    git clone https://github.com/flutter/flutter.git --depth 1 -b stable "$FLUTTER_ROOT"
    END_CLONE=$(date +%s)
    echo "Flutter clone süresi: $((END_CLONE - START_CLONE)) saniye"
fi

export PATH="$FLUTTER_ROOT/bin:$PATH"

# CocoaPods güncellemesi ve brew CocoaPods çakışmalarını engelleme
echo "CocoaPods kontrol ediliyor ve güncelleniyor..."
sudo gem install cocoapods --no-document || gem install cocoapods --user-install --no-document || echo "CocoaPods update skipped"

echo "Flutter version checking..."
flutter --version

# 3. Proje Bağımlılıkları
if [ -z "$PROJECT_DIR" ]; then
    PROJECT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
fi

cd "$PROJECT_DIR"
echo "Proje dizini: $(pwd)"

# env.dart dosyasının oluşturulması (Gitignored olduğu için Xcode Cloud'da bulunmaz)
ENV_DART_PATH="lib/env/env.dart"
if [ -n "$ENV_DART_CONTENT_BASE64" ]; then
    echo "env.dart dosyası Base64 içerikten decode ediliyor..."
    mkdir -p lib/env
    echo "$ENV_DART_CONTENT_BASE64" | base64 --decode > "$ENV_DART_PATH"
elif [ -n "$ENV_DART_CONTENT" ]; then
    echo "env.dart dosyası düz metin içerikten oluşturuluyor..."
    mkdir -p lib/env
    echo "$ENV_DART_CONTENT" > "$ENV_DART_PATH"
else
    echo "⚠️ UYARI: ENV_DART_CONTENT_BASE64 veya ENV_DART_CONTENT değişkeni bulunamadı. env.dart.example şablondan kopyalanıyor..."
    mkdir -p lib/env
    cp lib/env/env.dart.example "$ENV_DART_PATH"
fi


echo "Flutter paketleri yükleniyor..."
flutter pub get

echo "Yerelleştirme dosyaları oluşturuluyor..."
flutter gen-l10n

echo "iOS konfigürasyonu hazırlanıyor..."
# --no-swift-package-manager Flutter 3.27+'da kaldırıldı; yeni flag veya eski flag, her ikisini dene
flutter config --no-enable-swift-package-manager 2>/dev/null || flutter config --no-swift-package-manager 2>/dev/null || echo "SPM flag not needed in this Flutter version"
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
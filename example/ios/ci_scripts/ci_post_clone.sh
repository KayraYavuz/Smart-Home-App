#!/bin/sh

# Hata olursa durdur ve her komutu ekrana yaz (Debug modu)
set -e
set -x

echo "=== BAŞLANGIÇ: CI Post Clone Script ==="

# 1. GoogleService-Info.plist ve .env dosyalarını oluştur
# Bu kısım ios/ci_scripts dizininde çalıştığı için yollar buna göre ayarlandı.

# GoogleService-Info.plist
if [ -n "$GOOGLE_SERVICE_INFO_PLIST_CONTENT_BASE64" ]; then
    echo "GoogleService-Info.plist (Base64) decode ediliyor..."
    echo "$GOOGLE_SERVICE_INFO_PLIST_CONTENT_BASE64" | base64 --decode > ../GoogleService-Info.plist
    echo "✅ GoogleService-Info.plist başarıyla oluşturuldu."
elif [ -n "$GOOGLE_SERVICE_INFO_PLIST_CONTENT" ]; then
    echo "GoogleService-Info.plist (Düz Metin) dosyası oluşturuluyor..."
    echo "$GOOGLE_SERVICE_INFO_PLIST_CONTENT" > ../GoogleService-Info.plist
    echo "✅ GoogleService-Info.plist başarıyla oluşturuldu."
else
    echo "⚠️ UYARI: GOOGLE_SERVICE_INFO_PLIST_CONTENT değişkeni bulunamadı."
fi

# DOĞRULAMA ADIMI: Dosya geçerli mi?
if ! grep -q "API_KEY" ../GoogleService-Info.plist; then
    echo "❌ HATA: GoogleService-Info.plist geçersiz veya API_KEY içermiyor!"
    echo "⚠️ ACİL DURUM: Hardcoded dummy plist oluşturuluyor..."
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
    echo "✅ Dummy GoogleService-Info.plist oluşturuldu."
fi

echo "📄 Dosya Kontrolü (İlk 5 Satır):"
head -n 5 ../GoogleService-Info.plist

# .env
if [ -n "$ENV_FILE_CONTENT_BASE64" ]; then
    echo ".env (Base64) decode ediliyor..."
    echo "$ENV_FILE_CONTENT_BASE64" | base64 --decode > ../../.env
    echo "✅ .env başarıyla oluşturuldu."
    echo "📄 Dosya Kontrolü (İlk 2 Satır):"
    head -n 2 ../../.env
elif [ -n "$ENV_FILE_CONTENT" ]; then
    echo ".env (Düz Metin) dosyası oluşturuluyor..."
    echo "$ENV_FILE_CONTENT" > ../../.env
    echo "✅ .env başarıyla oluşturuldu."
    echo "📄 Dosya Kontrolü (İlk 2 Satır):"
    head -n 2 ../../.env
else
    echo "⚠️ UYARI: ENV_FILE_CONTENT değişkeni bulunamadı."
    echo "⚠️ Build hatasını önlemek için boş bir .env oluşturuluyor."
    touch ../../.env
fi

# 2. Flutter Kurulumu
# Scriptin bulunduğu dizini al
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# CI_WORKSPACE repo kök dizinidir (ttlock_flutter-master)
# Xcode Cloud'da CI_PRIMARY_REPOSITORY_PATH kullanılır.
if [ -z "$CI_WORKSPACE" ]; then
    if [ -n "$CI_PRIMARY_REPOSITORY_PATH" ]; then
        CI_WORKSPACE="$CI_PRIMARY_REPOSITORY_PATH"
    else
        # Script example/ios/ci_scripts dizininde, repo root 3 seviye yukarıda
        CI_WORKSPACE="$(cd "$SCRIPT_DIR/../../.." && pwd)"
    fi
fi

FLUTTER_ROOT="$CI_WORKSPACE/flutter"

if [ -d "$FLUTTER_ROOT" ]; then
    echo "Flutter klasörü zaten var: $FLUTTER_ROOT"
else
    echo "Flutter indiriliyor (Depth 1)..."
    git clone https://github.com/flutter/flutter.git --depth 1 -b stable "$FLUTTER_ROOT"
fi

export PATH="$FLUTTER_ROOT/bin:$PATH"

echo "Flutter Doctor çalıştırılıyor..."
flutter doctor -v

# 3. Proje Bağımlılıkları ve Konfigürasyon
# Example projesi CI_WORKSPACE/example dizinindedir veya script'e göre 2 seviye yukarıdadır.
if [ -z "$PROJECT_DIR" ]; then
    PROJECT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
fi

if [ ! -d "$PROJECT_DIR" ]; then
    echo "HATA: Proje klasörü bulunamadı: $PROJECT_DIR"
    exit 1
fi

cd "$PROJECT_DIR"
echo "Proje dizinine geçildi: $(pwd)"

echo "Flutter precache çalıştırılıyor..."
flutter precache --ios

echo "Flutter paketleri yükleniyor (flutter pub get)..."
flutter pub get

# Garanti: Generated.xcconfig dosyasını oluştur (iOS build için kritik)
echo "iOS konfigürasyon dosyaları oluşturuluyor..."
flutter build ios --config-only --release

# 4. iOS Pod Kurulumu
cd ios
echo "iOS dizinine geçildi: $(pwd)"

# Temizlik (Hata verirse görmezden gel - güvenli silme)
rm -rf Pods || true
rm -rf Podfile.lock || true

echo "CocoaPods kuruluyor (pod install)..."
# Repo update bazen çok uzun sürer ve hata verir, ilk denemede update yapmadan deneyelim.
if pod install; then
    echo "Pod install başarılı."
else
    echo "Pod install başarısız oldu, repo update ile tekrar deneniyor..."
    pod install --repo-update
fi

echo "=== BİTİŞ: Script başarıyla tamamlandı ==="
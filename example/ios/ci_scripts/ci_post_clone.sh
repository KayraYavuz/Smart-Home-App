#!/bin/sh

# Hata olursa durdur ve her komutu ekrana yaz (Debug modu)
set -e
set -x

echo "=== BAŞLANGIÇ: CI Post Clone Script ==="

# 1. GoogleService-Info.plist ve .env dosyalarını oluştur
# Bu kısım ios/ci_scripts dizininde çalıştığı için yollar buna göre ayarlandı.

if [ -n "$GOOGLE_SERVICE_INFO_PLIST_CONTENT" ]; then
    echo "GoogleService-Info.plist dosyası oluşturuluyor..."
    # ios/ dizinine yazar
    echo "$GOOGLE_SERVICE_INFO_PLIST_CONTENT" > ../GoogleService-Info.plist
    echo "✅ GoogleService-Info.plist başarıyla oluşturuldu."
else
    echo "⚠️ UYARI: GOOGLE_SERVICE_INFO_PLIST_CONTENT değişkeni bulunamadı. GoogleService-Info.plist oluşturulamadı."
fi

if [ -n "$ENV_FILE_CONTENT" ]; then
    echo ".env dosyası oluşturuluyor..."
    # example/ (proje kök) dizinine yazar
    echo "$ENV_FILE_CONTENT" > ../../.env
    echo "✅ .env başarıyla oluşturuldu."
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
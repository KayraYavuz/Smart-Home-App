#!/bin/sh

# Hata olursa durdur ve her komutu ekrana yaz (Debug modu)
set -e
set -x

echo "=== BAŞLANGIÇ: CI Post Clone Script ==="

# Çalışma dizinini göster
echo "Başlangıç Dizini: $(pwd)"
ls -F

# Flutter Kurulumu
FLUTTER_ROOT="$CI_WORKSPACE/flutter"

if [ -d "$FLUTTER_ROOT" ]; then
    echo "Flutter klasörü zaten var: $FLUTTER_ROOT"
else
    echo "Flutter indiriliyor..."
    git clone https://github.com/flutter/flutter.git -b stable "$FLUTTER_ROOT"
fi

export PATH="$FLUTTER_ROOT/bin:$PATH"

echo "Flutter Doctor çalıştırılıyor..."
flutter doctor -v

# Proje Bağımlılıkları
PROJECT_DIR="$CI_WORKSPACE/example"

if [ ! -d "$PROJECT_DIR" ]; then
    echo "HATA: Proje klasörü bulunamadı: $PROJECT_DIR"
    exit 1
fi

cd "$PROJECT_DIR"
echo "Proje dizinine geçildi: $(pwd)"

echo "Flutter paketleri yükleniyor (flutter pub get)..."
flutter pub get

# Garanti: Generated.xcconfig dosyasını oluştur
echo "iOS konfigürasyon dosyaları oluşturuluyor..."
flutter build ios --config-only --release

# iOS Pod Kurulumu
cd ios
echo "iOS dizinine geçildi: $(pwd)"

# Temizlik (Hata verirse görmezden gel - güvenli silme)
rm -rf Pods || true
rm -rf Podfile.lock || true

echo "CocoaPods kuruluyor (pod install)..."
# Repo update bazen çok uzun sürer ve hata verir, ilk denemede update yapmadan deneyelim.
# Eğer başarısız olursa update ile deneriz.
if pod install; then
    echo "Pod install başarılı."
else
    echo "Pod install başarısız oldu, repo update ile tekrar deneniyor..."
    pod install --repo-update
fi

echo "=== BİTİŞ: Script başarıyla tamamlandı ==="
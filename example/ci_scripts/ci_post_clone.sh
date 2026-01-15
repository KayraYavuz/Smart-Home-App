#!/bin/sh

# Hata olursa durdur
set -e

echo "=== BAŞLANGIÇ: CI Post Clone Script (Root Location) ==="
echo "Şu anki dizin: $(pwd)"
echo "Workspace: $CI_WORKSPACE"

# Dosya yapısını gör (Hata ayıklama için)
echo "--- Dosya Listesi (Root) ---"
ls -F "$CI_WORKSPACE"

# Flutter'ın kurulacağı yer
FLUTTER_ROOT="$CI_WORKSPACE/flutter"

# Flutter zaten varsa tekrar indirme
if [ ! -d "$FLUTTER_ROOT" ]; then
    echo "Flutter indiriliyor..."
    git clone https://github.com/flutter/flutter.git -b stable "$FLUTTER_ROOT"
else
    echo "Flutter zaten var."
fi

# Flutter'ı PATH'e ekle
export PATH="$FLUTTER_ROOT/bin:$PATH"

echo "Flutter versiyonu:"
flutter --version

# Proje 'example' klasörünün içinde
PROJECT_DIR="$CI_WORKSPACE/example"

echo "Proje dizinine gidiliyor: $PROJECT_DIR"
cd "$PROJECT_DIR"

# Flutter paketlerini yükle
echo "Flutter pub get çalıştırılıyor..."
flutter pub get

# iOS Pod'larını yükle
echo "iOS klasörüne geçiliyor..."
cd ios

# Temiz kurulum yap
echo "Eski Pod dosyaları temizleniyor..."
rm -rf Pods
rm -rf Podfile.lock

echo "Pod install çalıştırılıyor..."
pod install --repo-update

echo "=== BİTİŞ: Başarıyla tamamlandı ==="
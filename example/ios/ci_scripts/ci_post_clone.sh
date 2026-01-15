#!/bin/sh

# Hata olursa durdur
set -e

echo "=== BAŞLANGIÇ: CI Post Clone Script ==="
echo "Şu anki dizin: $(pwd)"
echo "Workspace: $CI_WORKSPACE"

# Dosya yapısını gör (Hata ayıklama için)
echo "--- Dosya Listesi ---"
ls -F "$CI_WORKSPACE"
if [ -d "$CI_WORKSPACE/example" ]; then
    echo "--- Example Klasörü İçeriği ---"
    ls -F "$CI_WORKSPACE/example"
fi

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

# DOĞRU KLASÖRÜ BULMA
# Projemiz 'example' içindeyse oraya gitmeliyiz.
# Eğer root'taysa orada kalmalıyız.

if [ -f "$CI_WORKSPACE/example/pubspec.yaml" ]; then
    echo "Proje 'example' klasöründe bulundu. Oraya gidiliyor..."
    cd "$CI_WORKSPACE/example"
elif [ -f "$CI_WORKSPACE/pubspec.yaml" ]; then
    echo "Proje ana dizinde bulundu."
    cd "$CI_WORKSPACE"
else
    echo "HATA: pubspec.yaml bulunamadı! Neredeyiz?"
    exit 1
fi

echo "Aktif dizin: $(pwd)"

# Flutter paketlerini yükle
echo "Flutter pub get çalıştırılıyor..."
flutter pub get

# iOS Pod'larını yükle
echo "iOS klasörüne geçiliyor..."
cd ios

# Temiz kurulum yap (Eski hataları önlemek için)
echo "Eski Pod dosyaları temizleniyor..."
rm -rf Pods
rm -rf Podfile.lock

echo "Pod install çalıştırılıyor..."
pod install --repo-update

echo "=== BİTİŞ: Başarıyla tamamlandı ==="
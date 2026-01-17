#!/bin/sh

# Hataları daha net görmek için
set -e

# 1. CocoaPods'u yükle (Garanti olsun diye)
brew install cocoapods

# 2. Flutter'ı indir ve kur (Stable kanalı)
git clone https://github.com/flutter/flutter.git --depth 1 -b stable $HOME/flutter
export PATH="$PATH:$HOME/flutter/bin"

# 3. Flutter dosyalarını oluştur (Generated.xcconfig burada oluşur)
# Proje yapısı plugin olduğu için example klasörüne giriyoruz
if [ -d "example" ]; then
  cd example
fi

# Generated.xcconfig oluştur
flutter pub get

# 4. iOS bağımlılıklarını kur (Pods klasörünü oluşturur)
cd ios
pod install

# İşlem tamam, Xcode artık derlemeye geçebilir.
echo "Flutter kurulumu ve Pod yüklemesi tamamlandı."

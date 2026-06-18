#!/bin/bash

# macOS Sequoia Çökme Önleyici Güvenli Çalıştırma Betiği
# Bu betik, Android Emulator'ü yazılımsal render modunda başlatır ve uygulamayı çalıştırır.

EMULATOR_ID="Pixel_8"

echo "🚀 Güvenli modda emulator başlatılıyor: $EMULATOR_ID..."
flutter emulators --launch $EMULATOR_ID --args "-gpu swiftshader_indirect"

echo "⏳ Emulator'ün hazır olması bekleniyor..."
sleep 5

echo "📱 Uygulama Android üzerinde başlatılıyor..."
flutter run -d $EMULATOR_ID

#!/bin/sh
set -e

echo "🔍 --- XCODE CLOUD DIAGNOSTIC START ---"

# 1. Ortamda değişken var mı kontrol et
if env | grep -q "^GOOGLE_SERVICE_INFO_PLIST="; then
    echo "✅ Değişken sistemde TANIMLI."
else
    echo "❌ HATA: GOOGLE_SERVICE_INFO_PLIST sistemde HİÇ YOK. (Environment Variable ayarlarına bak)"
fi

# 2. Değişkenin içi dolu mu?
if [ -z "$GOOGLE_SERVICE_INFO_PLIST" ]; then
    echo "❌ HATA: Değişken tanımlı ama İÇİ BOŞ!"
else
    # Karakter sayısını yazdır (Güvenlik için içeriği yazdırmıyoruz)
    echo "✅ Değişken dolu. Karakter Uzunluğu: ${#GOOGLE_SERVICE_INFO_PLIST}"
    
    # Base64 geçerlilik testi
    echo "$GOOGLE_SERVICE_INFO_PLIST" | base64 --decode > /dev/null 2>&1
    if [ $? -eq 0 ]; then
        echo "✅ Base64 formatı GEÇERLİ."
        
        # Dosyayı oluşturmayı dene
        echo "$GOOGLE_SERVICE_INFO_PLIST" | base64 --decode > $CI_PRIMARY_REPOSITORY_PATH/ios/Runner/GoogleService-Info.plist
        echo "✅ GoogleService-Info.plist başarıyla oluşturuldu."
    else
        echo "❌ HATA: Base64 formatı BOZUK! (Kopyalarken eksik alınmış olabilir)"
    fi
fi

echo "🔍 --- DIAGNOSTIC END ---"

# --- Standart İşlemler Devam Ediyor ---

# Sandboxing ayarını kapat (Hata 65'in diğer sebebi)
echo "🛡️ User Script Sandboxing kapatılıyor..."
sed -i '' 's/ENABLE_USER_SCRIPT_SANDBOXING = YES/ENABLE_USER_SCRIPT_SANDBOXING = NO/g' $CI_PRIMARY_REPOSITORY_PATH/ios/Runner.xcodeproj/project.pbxproj || true

# CocoaPods kurulumu
echo "📦 Pod install başlıyor..."
cd $CI_PRIMARY_REPOSITORY_PATH/ios
pod install --repo-update

echo "✅ Script tamamlandı."
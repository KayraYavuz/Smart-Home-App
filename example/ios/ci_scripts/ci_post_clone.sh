#!/bin/sh

# Hata durumunda durdur
set -e

# GoogleService-Info.plist dosyasını oluştur
# Xcode Cloud'da 'GOOGLE_SERVICE_INFO_PLIST_CONTENT' adında bir Environment Variable tanımlanmalıdır.
# Bu değişkenin değeri, GoogleService-Info.plist dosyasının ham metin içeriği olmalıdır.

if [ -n "$GOOGLE_SERVICE_INFO_PLIST_CONTENT" ]; then
    echo "GoogleService-Info.plist dosyası oluşturuluyor..."
    echo "$GOOGLE_SERVICE_INFO_PLIST_CONTENT" > ../GoogleService-Info.plist
    echo "✅ GoogleService-Info.plist başarıyla oluşturuldu."
else
    echo "⚠️ UYARI: GOOGLE_SERVICE_INFO_PLIST_CONTENT değişkeni bulunamadı. GoogleService-Info.plist oluşturulamadı."
fi

# .env dosyasını oluştur (Gerekirse)
# Eğer .env dosyasını da Environment Variable olarak saklıyorsanız (örn: ENV_FILE_CONTENT)
if [ -n "$ENV_FILE_CONTENT" ]; then
    echo ".env dosyası oluşturuluyor..."
    echo "$ENV_FILE_CONTENT" > ../../.env
    echo "✅ .env başarıyla oluşturuldu."
fi

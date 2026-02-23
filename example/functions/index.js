const { onRequest, onCall } = require("firebase-functions/v2/https");
const { setGlobalOptions } = require("firebase-functions/v2");
const admin = require("firebase-admin");
const nodemailer = require('nodemailer');

admin.initializeApp();

setGlobalOptions({ region: "us-central1" });

const recordTypes = {
  1: "Uygulamadan Açıldı",
  4: "Şifre ile Açıldı",
  7: "Kart ile Açıldı",
  8: "Parmak İzi ile Açıldı",
  9: "Uzaktan Açıldı",
  10: "Otomatik Kilitlendi",
  11: "Kilitlendi",
  12: "Kapı Açıldı", // Sensor
  28: "Ağ Geçidi ile Kilitlendi",
  29: "Ağ Geçidi ile Açıldı",
  30: "Kapı Sensörü ile Kilitlendi",
  31: "Kapı Sensörü ile Açıldı",
  46: "Otomatik Kilit Açıldı (Auto Unlock)"
};

exports.ttlockCallback = onRequest(async (req, res) => {
  // Not: Acil freni kaldırdık, artık kod normal çalışacak.

  try {
    console.log("📥 Webhook Verisi Alındı:", JSON.stringify(req.body));

    const data = req.body || req.query;
    const lockId = data.lockId;

    // Eğer kilit ID yoksa TTLock'a başarılı dönüp işlemi sonlandırıyoruz (tekrar denemesin diye)
    if (!lockId) return res.status(200).send("No LockID");

    let eventType = 0;
    let username = "";
    let battery = null; // Başlangıç değerini null yaptık
    let success = 1;
    let messagesToSend = [];

    // 1. Gelen "records" verisini işle
    if (data.records) {
      try {
        const records = JSON.parse(data.records);
        if (records && records.length > 0) {
          const lastRecord = records[0];

          eventType = lastRecord.recordType;
          username = lastRecord.username || lastRecord.keyName || "";
          // Bataryayı güvenli bir şekilde Number'a çevirmeye çalışıyoruz
          battery = parseInt(lastRecord.electricQuantity);
          success = lastRecord.success;

          // Ana Mesajı Oluştur
          let actionText = recordTypes[eventType] || `Kilit İşlemi (${eventType})`;

          if (success !== 1) {
            actionText += " (Başarısız)";
          }

          if (username) {
            actionText += ` - ${username}`;
          }

          messagesToSend.push({
            title: "Yavuz Lock",
            body: actionText
          });

          // PİL KONTROLÜ (GÜVENLİ HALE GETİRİLDİ)
          // Sadece battery gerçekten bir sayıysa ve 0 ile 20 arasındaysa çalışır
          if (!isNaN(battery) && battery !== null && battery > 0 && battery <= 20) {
            messagesToSend.push({
              title: "⚠️ Düşük Pil Uyarısı!",
              body: `Kilit pili kritik seviyede: %${battery}. Lütfen pilleri değiştirin.`
            });
          }
        }
      } catch (e) {
        console.error("JSON parse hatası:", e);
      }
    }

    // Mesajları Gönder
    for (const msg of messagesToSend) {
      try {
        const payload = {
          notification: {
            title: msg.title,
            body: msg.body,
          },
          data: {
            lockId: lockId.toString(),
            eventType: eventType.toString(),
            click_action: "FLUTTER_NOTIFICATION_CLICK",
          },
          apns: {
            payload: {
              aps: {
                alert: { title: msg.title, body: msg.body },
                sound: "default",
                badge: 1,
                "content-available": 1,
              },
            },
            headers: { "apns-priority": "10" },
          },
          android: {
            priority: "high",
            notification: {
              channelId: "high_importance_channel",
              sound: "default",
            },
          },
          topic: `lock_${lockId}`,
        };

        console.log(`🚀 Gönderiliyor: ${msg.body}`);
        await admin.messaging().send(payload);
      } catch (fcmError) {
        // BİLDİRİM GİTMESE BİLE BURADA YAKALIYORUZ
        // Böylece ana fonksiyon çökmüyor ve TTLock'a hata dönmüyoruz.
        console.error("Bildirim gönderme hatası (Önemli Değil, Döngü Engellendi):", fcmError);
      }
    }

    // HER DURUMDA TTLock'a 200 BAŞARILI dönüyoruz ki TEKRAR DENEMESİN!
    return res.status(200).send("Success");

  } catch (error) {
    console.error("❌ Kritik Hata:", error);
    // Eskiden 500 dönüyorduk, artık hata olsa bile 200 dönüyoruz ki TTLock sus-sun.
    return res.status(200).send("Handled with internal error");
  }
});

// E-posta Gönderme Fonksiyonu (Flutter'dan çağrılır)
exports.sendVerificationCode = onCall(async (request) => {
  const email = request.data.email;
  const code = request.data.code;

  if (!email || !code) {
    throw new Error('Email ve kod gerekli.');
  }

  // Gmail Transporter Ayarları
  // GÜVENLİK NOTU: Prodüksiyonda bu şifreleri "Firebase Secrets" ile saklayın.
  // LÜTFEN AŞAĞIDAKİ BİLGİLERİ GÜNCELLEYİN
  const transporter = nodemailer.createTransport({
    service: 'gmail',
    auth: {
      user: 'ahmetkayrayavuz@gmail.com', // Gönderici Gmail Adresi
      pass: 'xxxx xxxx xxxx xxxx'     // 16 Haneli Uygulama Şifresi
    }
  });

  const mailOptions = {
    from: '"Yavuz Lock" <ahmetkayrayavuz@gmail.com>',
    to: email,
    subject: `Doğrulama Kodunuz: ${code}`,
    html: `
      <div style="font-family: Arial, sans-serif; padding: 20px; border: 1px solid #eee; border-radius: 10px;">
        <h2 style="color: #333;">Yavuz Lock Doğrulama</h2>
        <p>Merhaba,</p>
        <p>Hesabınızı doğrulamak için kullanacağınız kod:</p>
        <h1 style="color: #1E90FF; letter-spacing: 5px;">${code}</h1>
        <p style="color: #666; font-size: 12px;">Bu kodu kimseyle paylaşmayın.</p>
      </div>
    `
  };

  try {
    await transporter.sendMail(mailOptions);
    return { success: true, message: 'Mail gönderildi.' };
  } catch (error) {
    console.error('Mail gönderme hatası:', error);
    throw new Error(`Mail gönderilemedi: ${error.message}`);
  }
});
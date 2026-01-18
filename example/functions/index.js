const { onRequest } = require("firebase-functions/v2/https");
const { setGlobalOptions } = require("firebase-functions/v2");
const admin = require("firebase-admin");

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
  try {
    console.log("📥 Webhook Verisi Alındı:", JSON.stringify(req.body));
    
    const data = req.body || req.query;
    const lockId = data.lockId;
    
    // Eğer kilit ID yoksa işlem yapma
    if (!lockId) return res.status(200).send("No LockID");

    let eventType = 0;
    let username = "";
    let battery = -1;
    let success = 1;
    let messagesToSend = [];

    // 1. Gelen "records" verisini işle (Kilit Açma/Kapama Olayları)
    if (data.records) {
      try {
        const records = JSON.parse(data.records);
        if (records && records.length > 0) {
          const lastRecord = records[0];
          
          eventType = lastRecord.recordType;
          username = lastRecord.username || lastRecord.keyName || "";
          battery = lastRecord.electricQuantity;
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

          // PİL KONTROLÜ (%20 Altı)
          if (battery > -1 && battery < 20) {
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
    // 2. Eğer "key" ile ilgili bir olay geldiyse (Kilit Paylaşımı)
    // TTLock bazen farklı formatta veri atar. Örneğin: eKey gönderildiğinde.
    // Ancak standart webhook genellikle record gönderir. 
    // Eğer TTLock'tan "eKey sent" webhook'u gelirse (notifyType farklı olabilir), onu da burada yakalayabiliriz.
    
    // Mesajları Gönder
    for (const msg of messagesToSend) {
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
    }

    return res.status(200).send("Success");
  } catch (error) {
    console.error("❌ Hata:", error);
    return res.status(500).send("Error");
  }
});
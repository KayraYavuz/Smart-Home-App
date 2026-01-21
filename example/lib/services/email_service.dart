import 'dart:math';
import 'package:mailer/mailer.dart';
import 'package:mailer/smtp_server.dart';
import 'package:yavuz_lock/config.dart';

class EmailService {
  // Rastgele 6 haneli kod üretir
  String generateVerificationCode() {
    var rng = Random();
    return (rng.nextInt(900000) + 100000).toString();
  }

  // E-posta gönderir
  Future<bool> sendVerificationEmail(String recipientEmail, String code) async {
    String username = ApiConfig.smtpUser;
    String password = ApiConfig.smtpPassword;

    if (username == 'your_email@gmail.com' || password == 'your_app_password') {
      print('⚠️ UYARI: E-posta ayarları yapılandırılmamış (lib/config.dart). Mail gönderilemedi.');
      return false;
    }

    final smtpServer = gmail(username, password);

    final message = Message()
      ..from = Address(username, 'Yavuz Lock')
      ..recipients.add(recipientEmail)
      ..subject = 'Doğrulama Kodunuz: $code'
      ..text = 'Yavuz Lock uygulaması için doğrulama kodunuz: $code\n\nBu kodu kimseyle paylaşmayın.'
      ..html = '''
        <h1>Yavuz Lock Doğrulama</h1>
        <p>Merhaba,</p>
        <p>Yavuz Lock uygulaması için doğrulama kodunuz:</p>
        <h2 style="color: blue;">$code</h2>
        <p>Bu kodu kimseyle paylaşmayın.</p>
        <br>
        <p>Teşekkürler,</p>
        <p>Yavuz Lock Ekibi</p>
      ''';

    try {
      final sendReport = await send(message, smtpServer);
      print('✅ E-posta gönderildi: $sendReport');
      return true;
    } on MailerException catch (e) {
      print('❌ E-posta gönderme hatası: $e');
      for (var p in e.problems) {
        print('Problem: ${p.code}: ${p.msg}');
      }
      return false;
    } catch (e) {
       print('❌ Bilinmeyen E-posta hatası: $e');
       return false;
    }
  }
}

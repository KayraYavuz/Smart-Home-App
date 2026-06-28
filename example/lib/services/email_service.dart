import "package:flutter/foundation.dart";
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
  Future<bool> sendVerificationEmail(String recipientEmail, String code,
      {String languageCode = 'en'}) async {
    String username = ApiConfig.smtpUser;
    String password = ApiConfig.smtpPassword;

    if (username.isEmpty ||
        password.isEmpty ||
        username == 'your_email@gmail.com' ||
        password == 'your_app_password') {
      debugPrint(
          '⚠️ UYARI: E-posta (SMTP) ayarları yapılandırılmamış (lib/env/env.dart). Mail gönderilemedi.');
      return false;
    }

    final smtpServer = gmail(username, password);

    final _EmailContent content = switch (languageCode) {
      'tr' => _EmailContent(
          subject: 'Doğrulama Kodunuz: $code',
          text:
              'Yavuz Lock uygulaması için doğrulama kodunuz: $code\n\nBu kodu kimseyle paylaşmayın.',
          heading: 'Yavuz Lock Doğrulama',
          body: 'Yavuz Lock uygulaması için doğrulama kodunuz:',
          warning: 'Bu kodu kimseyle paylaşmayın.',
          thanks: 'Teşekkürler,',
          team: 'Yavuz Lock Ekibi',
        ),
      'de' => _EmailContent(
          subject: 'Ihr Bestätigungscode: $code',
          text:
              'Ihr Bestätigungscode für die Yavuz Lock App: $code\n\nTeilen Sie diesen Code mit niemandem.',
          heading: 'Yavuz Lock Bestätigung',
          body: 'Ihr Bestätigungscode für die Yavuz Lock App:',
          warning: 'Teilen Sie diesen Code mit niemandem.',
          thanks: 'Vielen Dank,',
          team: 'Das Yavuz Lock Team',
        ),
      _ => _EmailContent(
          subject: 'Your verification code: $code',
          text:
              'Your Yavuz Lock verification code: $code\n\nDo not share this code with anyone.',
          heading: 'Yavuz Lock Verification',
          body: 'Your verification code for the Yavuz Lock app:',
          warning: 'Do not share this code with anyone.',
          thanks: 'Thank you,',
          team: 'The Yavuz Lock Team',
        ),
    };

    final message = Message()
      ..from = Address(username, 'Yavuz Lock')
      ..recipients.add(recipientEmail)
      ..subject = content.subject
      ..text = content.text
      ..html = '''
        <h1>${content.heading}</h1>
        <p>${content.body}</p>
        <h2 style="color:#1E90FF;letter-spacing:4px;">$code</h2>
        <p>${content.warning}</p>
        <br>
        <p>${content.thanks}</p>
        <p>${content.team}</p>
      ''';

    try {
      final sendReport = await send(message, smtpServer);
      debugPrint('✅ E-posta gönderildi: $sendReport');
      return true;
    } on MailerException catch (e) {
      debugPrint('❌ E-posta gönderme hatası: $e');
      for (var p in e.problems) {
        debugPrint('Problem: ${p.code}: ${p.msg}');
      }
      return false;
    } catch (e) {
      debugPrint('❌ Bilinmeyen E-posta hatası: $e');
      return false;
    }
  }

  Future<bool> sendBookingConfirmation({
    required String recipientEmail,
    required String guestName,
    required String unitName,
    required String startFormatted,
    required String endFormatted,
    String? pinCode,
    String? unlockLink,
  }) async {
    final username = ApiConfig.smtpUser;
    final password = ApiConfig.smtpPassword;
    if (username.isEmpty || password.isEmpty ||
        username == 'your_email@gmail.com' || password == 'your_app_password') {
      return false;
    }
    final smtpServer = gmail(username, password);
    final isPin = pinCode != null;

    final subject = isPin
        ? 'Rezervasyonunuz — $unitName ($startFormatted → $endFormatted)'
        : 'Dijital Anahtarınız Hazır — $unitName';

    final htmlBody = isPin
        ? '''
          <h2 style="color:#1E90FF;">Rezervasyonunuz Oluşturuldu</h2>
          <p>Merhaba <b>$guestName</b>,</p>
          <p><b>$unitName</b> için rezervasyonunuz onaylandı.</p>
          <table cellpadding="8" style="border-collapse:collapse;margin:12px 0;">
            <tr><td><b>Giriş</b></td><td>$startFormatted</td></tr>
            <tr><td><b>Çıkış</b></td><td>$endFormatted</td></tr>
          </table>
          <p style="font-size:14px;">Kapı şifreniz:</p>
          <h1 style="color:#1E90FF;letter-spacing:8px;font-size:42px;">$pinCode</h1>
          <p style="color:#888;font-size:12px;">Bu şifreyi kimseyle paylaşmayın.</p>
          <br><p>İyi günler,<br><b>Yavuz Lock</b></p>
        '''
        : unlockLink != null
        ? '''
          <h2 style="color:#1E90FF;">Dijital Anahtarınız Hazır</h2>
          <p>Merhaba <b>$guestName</b>,</p>
          <p><b>$unitName</b> için dijital anahtarınız hazır.</p>
          <table cellpadding="8" style="border-collapse:collapse;margin:12px 0;">
            <tr><td><b>Giriş</b></td><td>$startFormatted</td></tr>
            <tr><td><b>Çıkış</b></td><td>$endFormatted</td></tr>
          </table>
          <p style="margin-top:16px;">Aşağıdaki bağlantıya tıklayarak kilidi açabilirsiniz:</p>
          <a href="$unlockLink" style="display:inline-block;margin:12px 0;padding:12px 24px;background:#1E90FF;color:#fff;text-decoration:none;border-radius:8px;font-weight:bold;">Kilidi Aç</a>
          <br><p style="color:#888;font-size:12px;">Bu bağlantıyı kimseyle paylaşmayın.</p>
          <br><p>İyi günler,<br><b>Yavuz Lock</b></p>
        '''
        : '''
          <h2 style="color:#1E90FF;">Dijital Anahtarınız Hazır</h2>
          <p>Merhaba <b>$guestName</b>,</p>
          <p><b>$unitName</b> için dijital anahtarınız gönderildi.</p>
          <table cellpadding="8" style="border-collapse:collapse;margin:12px 0;">
            <tr><td><b>Giriş</b></td><td>$startFormatted</td></tr>
            <tr><td><b>Çıkış</b></td><td>$endFormatted</td></tr>
          </table>
          <p style="margin-top:16px;"><b>Anahtarınızı almak için:</b></p>
          <ol>
            <li><b>Yavuz Lock</b> uygulamasını indirin</li>
            <li>Bu e-posta adresiyle (<b>$recipientEmail</b>) kayıt olun</li>
            <li>Anahtarlar bölümünden erişin</li>
          </ol>
          <br><p>İyi günler,<br><b>Yavuz Lock</b></p>
        ''';

    final msg = Message()
      ..from = Address(username, 'Yavuz Lock')
      ..recipients.add(recipientEmail)
      ..subject = subject
      ..html = htmlBody;

    try {
      await send(msg, smtpServer);
      debugPrint('✅ Booking bildirimi gönderildi: $recipientEmail');
      return true;
    } catch (e) {
      debugPrint('❌ Booking bildirimi gönderilemedi: $e');
      return false;
    }
  }

  Future<bool> sendContactForm({
    required String name,
    required String business,
    required String email,
    required String phone,
    required String message,
  }) async {
    final username = ApiConfig.smtpUser;
    final password = ApiConfig.smtpPassword;
    if (username.isEmpty || password.isEmpty ||
        username == 'your_email@gmail.com' || password == 'your_app_password') {
      return false;
    }
    final smtpServer = gmail(username, password);
    final msg = Message()
      ..from = Address(username, 'Yavuz Lock')
      ..recipients.add('ahmetkayrayavuz@gmail.com')
      ..headers = {if (email.isNotEmpty) 'Reply-To': '$name <$email>'}
      ..subject = 'Bookings Erişim Talebi — $name'
      ..text = 'Ad Soyad: $name\nİşletme: $business\nE-posta: $email\nTelefon: $phone\n\nMesaj:\n$message'
      ..html = '''
        <h2 style="color:#1E90FF;">📋 Bookings Erişim Talebi</h2>
        <table cellpadding="8" style="border-collapse:collapse;">
          <tr><td><b>Ad Soyad</b></td><td>$name</td></tr>
          <tr><td><b>İşletme</b></td><td>$business</td></tr>
          <tr><td><b>E-posta</b></td><td>$email</td></tr>
          <tr><td><b>Telefon</b></td><td>$phone</td></tr>
        </table>
        <br>
        <p><b>Mesaj:</b></p>
        <p>$message</p>
      ''';
    try {
      await send(msg, smtpServer);
      return true;
    } catch (e) {
      debugPrint('❌ Contact form gönderilemedi: $e');
      return false;
    }
  }
}

class _EmailContent {
  final String subject, text, heading, body, warning, thanks, team;
  const _EmailContent({
    required this.subject,
    required this.text,
    required this.heading,
    required this.body,
    required this.warning,
    required this.thanks,
    required this.team,
  });
}

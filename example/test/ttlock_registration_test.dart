import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:crypto/crypto.dart';

void main() async {
  Map<String, String> env = {};
  try {
    final file = File('.env');
    if (await file.exists()) {
      final lines = await file.readAsLines();
      for (var line in lines) {
        if (line.trim().isNotEmpty && !line.startsWith('#')) {
          final parts = line.split('=');
          if (parts.length >= 2) {
            env[parts[0].trim()] = parts.sublist(1).join('=').trim();
          }
        }
      }
      // ignore: avoid_print
      print("Environment loaded manually.");
    } else {
      // ignore: avoid_print
      print(".env file not found.");
      return;
    }
  } catch (e) {
    // ignore: avoid_print
    print("Error loading .env: $e");
    return;
  }

  final String clientId = env['TTLOCK_CLIENT_ID'] ?? '';
  final String clientSecret = env['TTLOCK_CLIENT_SECRET'] ?? '';

  if (clientId.isEmpty || clientSecret.isEmpty) {
    // ignore: avoid_print
    print("Error: Client ID or Secret is empty.");
    return;
  }

  // Test username (randomly generated to avoid conflict)
  final String rawEmail = "testuser${DateTime.now().millisecondsSinceEpoch}@gmail.com";
  final String username = rawEmail.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '');
  const String password = "Password123!";
  final String passwordMd5 = md5.convert(utf8.encode(password)).toString().toLowerCase();

  // ignore: avoid_print
  print("Attempting to register user: $username");

  final url = Uri.parse('https://api.ttlock.com/v3/user/register');
  final Map<String, String> body = {
    'clientId': clientId,
    'clientSecret': clientSecret,
    'username': username,
    'password': passwordMd5,
    'date': DateTime.now().millisecondsSinceEpoch.toString(),
  };

  try {
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/x-www-form-urlencoded'},
      body: body,
    );

    // ignore: avoid_print
    print('Response Status: ${response.statusCode}');
    // ignore: avoid_print
    print('Response Body: ${response.body}');
  } catch (e) {
    // ignore: avoid_print
    print("Exception during request: $e");
  }
}
